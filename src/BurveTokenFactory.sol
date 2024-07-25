// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "openzeppelin/proxy/transparent/ProxyAdmin.sol";
import "openzeppelin/access/AccessControl.sol";
import "openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import "openzeppelin/token/ERC20/IERC20.sol";

import "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin/proxy/Clones.sol";
import "./interfaces/IBurveFactory.sol";
import "./interfaces/IBurveTokenPausable.sol";
import "./interfaces/IBondingCurve.sol";
import "./interfaces/IHook.sol";

contract BurveTokenFactory is IBurveFactory, Initializable, AccessControl {
    using SafeERC20 for IERC20;
    using Clones for address;
    bytes32 public constant PLATFORM_ADMIN_ROLE = keccak256("PLATFORM_ADMIN");

    mapping(string => address) private _implementsMap;
    mapping(uint256 => address) private tokens;
    mapping(address => string) private tokensType;
    mapping(address => uint256) private upgradeTimelock;
    mapping(address => bytes) private upgradeList;
    mapping(address => bool) public whitelistHooks;
    mapping(address => address[]) public tokenHooks;

    uint256 private tokensLength;

    mapping(string => address) private _burveImplementMap;
    address private _platformAdmin;
    address private _platformTreasury;
    ProxyAdmin private _proxyAdmin;

    uint256 private constant MAX_PLATFORM_TAX_RATE = 100;
    uint256 private _platformMintTax;
    uint256 private _platformBurnTax;
    address private _route;

    constructor() {
        _disableInitializers();
    }

    receive() external payable {
        (bool success, ) = _platformTreasury.call{value: msg.value}("");
        require(success, "platform transfer failed");
    }

    fallback() external payable {}

    function initialize(address platformAdmin, address platformTreasury) public initializer {
        _grantRole(PLATFORM_ADMIN_ROLE, platformAdmin);
        _platformAdmin = platformAdmin;
        _platformTreasury = platformTreasury;
        _platformMintTax = 100;
        _platformBurnTax = 100;
        _proxyAdmin = new ProxyAdmin();
    }

    /// @inheritdoc IBurveFactory
    function deployToken(TokenInfo calldata token, uint256 mintfirstAmount) public payable returns (address) {
        address tokenAddr = getBurveImplement(token.tokenType).clone();
        IBurveToken(tokenAddr).initialize(getBondingCurveImplement(token.bondingCurveType), token, address(this));
        uint256 tokenId = tokensLength;
        tokens[tokensLength] = tokenAddr;
        tokensLength++;
        tokensType[tokenAddr] = token.tokenType;
        if (mintfirstAmount > 0) {
            if (token.raisingTokenAddr != address(0)) {
                IERC20(token.raisingTokenAddr).safeTransferFrom(msg.sender, address(this), mintfirstAmount);
                IERC20(token.raisingTokenAddr).safeApprove(tokenAddr, mintfirstAmount);
            }
            IBurveToken(tokenAddr).mint{value: token.raisingTokenAddr == address(0) ? mintfirstAmount : 0}(msg.sender, mintfirstAmount, 0);
        }
        emit LogTokenDeployed(token.tokenType, token.bondingCurveType, tokenId, tokenAddr);
        return tokenAddr;
    }

    /// @inheritdoc IBurveFactory
    function deployTokenWithHooks(TokenInfo calldata token, uint256 mintfirstAmount, address[] calldata hooks, bytes[] calldata datas) public payable returns (address) {
        address proxy = deployToken(token, mintfirstAmount);
        require(hooks.length == datas.length);
        addHooksForToken(proxy, hooks, datas);
        return proxy;
    }

    /// @inheritdoc IBurveFactory
    function setPlatformTaxRate(uint256 platformMintTax, uint256 platformBurnTax) public onlyRole(PLATFORM_ADMIN_ROLE) {
        require(MAX_PLATFORM_TAX_RATE >= platformMintTax && platformMintTax >= 0, "SetTax:Platform Mint Tax Rate must between 0% to 1%");
        require(MAX_PLATFORM_TAX_RATE >= platformBurnTax && platformBurnTax >= 0, "SetTax:Platform Burn Tax Rate must between 0% to 1%");
        _platformMintTax = platformMintTax;
        _platformBurnTax = platformBurnTax;
        emit LogPlatformTaxChanged();
    }

    /// @inheritdoc IBurveFactory
    function getTaxRateOfPlatform() public view returns (uint256 platformMintTax, uint256 platformBurnTax) {
        return (_platformMintTax, _platformBurnTax);
    }

    /// @inheritdoc IBurveFactory
    function addBondingCurveImplement(address impl) public onlyRole(PLATFORM_ADMIN_ROLE) {
        require(impl != address(0), "invalid implement");
        string memory bondingCurveType = IBondingCurve(impl).BondingCurveType();
        require(bytes(bondingCurveType).length != bytes("").length, "bonding curve type error");
        _implementsMap[bondingCurveType] = impl;
        emit LogBondingCurveTypeImplAdded(bondingCurveType, impl);
    }

    /// @inheritdoc IBurveFactory
    function getBondingCurveImplement(string calldata bondingCurveType) public view returns (address impl) {
        impl = _implementsMap[bondingCurveType];
        require(impl != address(0), "no such implement");
    }

    /// @inheritdoc IBurveFactory
    function updateBurveImplement(string calldata tokenType, address impl) public onlyRole(PLATFORM_ADMIN_ROLE) {
        _burveImplementMap[tokenType] = impl;
        emit LogTokenTypeImplAdded(tokenType, impl);
    }

    /// @inheritdoc IBurveFactory
    function getBurveImplement(string memory tokenType) public view returns (address impl) {
        impl = _burveImplementMap[tokenType];
        require(impl != address(0), "no such implement");
    }

    /// @inheritdoc IBurveFactory
    function getTokensLength() public view returns (uint256 len) {
        len = tokensLength;
    }

    /// @inheritdoc IBurveFactory
    function getToken(uint256 index) public view returns (address addr) {
        addr = tokens[index];
        require(addr != address(0), "no such token");
    }

    function getRoute() public view returns (address) {
        return _route;
    }

    /// @inheritdoc IBurveFactory
    function getPlatformAdmin() public view returns (address) {
        return _platformAdmin;
    }

    /// @inheritdoc IBurveFactory
    function getPlatformTreasury() public view returns (address) {
        return _platformTreasury;
    }

    function setRoute(address route) public onlyRole(PLATFORM_ADMIN_ROLE) {
        require(route != address(0), "Invalid Address");
        _route = route;
        emit LogRouteChanged(route);
    }

    function setPlatformAdmin(address newPlatformAdmin) public onlyRole(PLATFORM_ADMIN_ROLE) {
        require(newPlatformAdmin != address(0), "Invalid Address");
        _revokeRole(PLATFORM_ADMIN_ROLE, _platformAdmin);
        _grantRole(PLATFORM_ADMIN_ROLE, newPlatformAdmin);
        _platformAdmin = newPlatformAdmin;
        emit LogPlatformAdminChanged(newPlatformAdmin);
    }

    function setPlatformTreasury(address newPlatformTreasury) public onlyRole(PLATFORM_ADMIN_ROLE) {
        require(newPlatformTreasury != address(0), "Invalid Address");
        _platformTreasury = newPlatformTreasury;
        emit LogPlatformTreasuryChanged(newPlatformTreasury);
    }

    /// @inheritdoc IBurveFactory
    function setHook(address hook, bool flag) external override onlyRole(PLATFORM_ADMIN_ROLE) {
        whitelistHooks[hook] = flag;
        if (flag) {
            emit LogHookWhiteListed(hook);
        } else {
            emit LogHookBlackListed(hook);
        }
    }

    function addHookForToken(address token, address hook, bytes calldata data) private {
        if (address(0) == hook) {
            return;
        }
        require(whitelistHooks[hook], "not whitelist");
        tokenHooks[token].push(hook);
        IHook(hook).registerHook(token, data);
        emit LogHookRegistered(token, hook, data);
    }

    function addHooksForToken(address token, address[] calldata hooks, bytes[] calldata datas) private {
        require(hooks.length == datas.length);
        for (uint256 i = 0; i < hooks.length; i++) {
            addHookForToken(token, hooks[i], datas[i]);
        }
    }

    /// @inheritdoc IBurveFactory
    function getTokenHooks(address token) external view override returns (address[] memory) {
        return tokenHooks[token];
    }

    function claimAllFee() external onlyRole(PLATFORM_ADMIN_ROLE) {
        for (uint256 i; i < tokensLength; i++) {
            try IBurveToken(tokens[i]).claimPlatformFee() {} catch {}
        }
    }
}

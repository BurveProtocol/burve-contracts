// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

// openzeppelin
import "openzeppelin-upgradeable/access/AccessControlUpgradeable.sol";
import "openzeppelin/token/ERC20/IERC20.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin/security/ReentrancyGuard.sol";

import "./SwapCurve.sol";
import "./BurveMetadata.sol";
import "../interfaces/IBurveFactory.sol";
import "../interfaces/IHook.sol";

abstract contract BurveBase is BurveMetadata, SwapCurve, AccessControlUpgradeable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    bool private _paused = false;
    bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE");
    bytes32 public constant PROJECT_ADMIN_ROLE = keccak256("PROJECT_ADMIN_ROLE");
    address internal _projectTreasury;
    address internal _projectAdmin;
    IBurveFactory internal _factory;
    bool private _boolSlot = false; //temporary useless
    uint256 internal constant MAX_TAX_RATE_DENOMINATOR = 10000;
    uint256 internal constant MAX_PROJECT_TAX_RATE = 5000;
    uint256 internal _projectMintTax = 0;
    uint256 internal _projectBurnTax = 0;
    address internal _raisingToken;
    mapping(bytes4 => uint256) public lastModifyTimestamp;

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier modifyDelay() {
        bytes4 selector = bytes4(msg.data[:4]);
        require(lastModifyTimestamp[selector] + 2 days <= block.timestamp, "modify per 48 hours");
        lastModifyTimestamp[selector] = block.timestamp;
        _;
    }

    function initialize(
        address bondingCurveAddress,
        string memory name,
        string memory symbol,
        string memory metadata,
        address projectAdmin,
        address projectTreasury,
        uint256 projectMintTax,
        uint256 projectBurnTax,
        address raisingTokenAddr,
        bytes memory parameters,
        address factory
    ) public virtual;

    function getProjectAdminRole() external pure returns (bytes32 role) {
        return PROJECT_ADMIN_ROLE;
    }

    function getFactory() public view returns (address) {
        return address(_factory);
    }

    function getProjectAdmin() public view returns (address) {
        return _projectAdmin;
    }

    function getProjectTreasury() public view returns (address) {
        return _projectTreasury;
    }

    function getRaisingToken() public view returns (address) {
        return _raisingToken;
    }

    function setMetadata(string memory url) public onlyRole(PROJECT_ADMIN_ROLE) modifyDelay {
        _setMetadata(url);
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    function pause() public onlyRole(FACTORY_ROLE) {
        _paused = true;
        emit Paused(_msgSender());
    }

    function unpause() public onlyRole(FACTORY_ROLE) {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    function setProjectAdmin(address newProjectAdmin) public onlyRole(PROJECT_ADMIN_ROLE) {
        require(newProjectAdmin != address(0), "Invalid Address");
        _revokeRole(PROJECT_ADMIN_ROLE, _projectAdmin);
        _grantRole(PROJECT_ADMIN_ROLE, newProjectAdmin);
        _projectAdmin = newProjectAdmin;
        emit LogProjectAdminChanged(newProjectAdmin);
    }

    function multiSet(bytes[] calldata datas) external onlyRole(PROJECT_ADMIN_ROLE) {
        for (uint256 i; i < datas.length; i++) {
            (bool suc, ) = address(this).delegatecall(datas[i]);
            require(suc, "set failed");
        }
    }

    function setProjectTreasury(address newProjectTreasury) public onlyRole(PROJECT_ADMIN_ROLE) modifyDelay {
        require(newProjectTreasury != address(0), "Invalid Address");
        _projectTreasury = newProjectTreasury;
        emit LogProjectTreasuryChanged(newProjectTreasury);
    }

    function _initProject(address projectAdmin, address projectTreasury) internal {
        require(projectAdmin != address(0), "Invalid Admin Address");
        require(projectTreasury != address(0), "Invalid Treasury Address");
        _projectAdmin = projectAdmin;
        _projectTreasury = projectTreasury;
    }

    function _initFactory(address account) internal {
        require(account != address(0), "Invalid Treasury Address");
        _factory = IBurveFactory(account);
    }

    function _setProjectTaxRate(uint256 projectMintTax, uint256 projectBurnTax) internal {
        require((MAX_PROJECT_TAX_RATE >= projectMintTax && projectMintTax >= 0 && (_projectMintTax >= projectMintTax || _projectMintTax == 0)), "SetTax:Project Mint Tax Rate must lower than before or between 0% to 50%");
        require((MAX_PROJECT_TAX_RATE >= projectBurnTax && projectBurnTax >= 0 && (_projectBurnTax >= projectBurnTax || _projectBurnTax == 0)), "SetTax:Project Burn Tax Rate must lower than before or between 0% to 50%");
        (uint256 _platformMintTax, uint256 _platformBurnTax) = _factory.getTaxRateOfPlatform();
        require(projectMintTax + _platformMintTax <= MAX_TAX_RATE_DENOMINATOR, "SetTax: Invalid number");
        require(projectBurnTax + _platformBurnTax <= MAX_TAX_RATE_DENOMINATOR, "SetTax: Invalid number");
        _projectMintTax = projectMintTax;
        _projectBurnTax = projectBurnTax;
        emit LogProjectTaxChanged();
    }

    function setProjectTaxRate(uint256 projectMintTax, uint256 projectBurnTax) public onlyRole(PROJECT_ADMIN_ROLE) modifyDelay {
        _setProjectTaxRate(projectMintTax, projectBurnTax);
    }

    function getTaxRateOfProject() public view returns (uint256 projectMintTax, uint256 projectBurnTax) {
        return (_projectMintTax, _projectBurnTax);
    }

    function getTaxRateOfPlatform() public view returns (uint256 platformMintTax, uint256 platformBurnTax) {
        return _factory.getTaxRateOfPlatform();
    }

    function mint(address to, uint payAmount, uint minReceive) public payable virtual whenNotPaused nonReentrant {
        require(to != address(0), "can not mint to address(0)");

        uint256 actualAmount = _transferFromInternal(msg.sender, payAmount);
        (uint256 tokenAmount, uint256 payAmountActual, uint256 platformFee, uint256 projectFee) = estimateMint(actualAmount);
        require(tokenAmount >= minReceive, "Mint: mint amount less than minimal expect recieved");
        address[] memory hooks = getHooks();
        for (uint256 i = 0; i < hooks.length; i++) {
            IHook(hooks[i]).beforeMintHook(address(0), to, tokenAmount);
        }
        _mintInternal(to, tokenAmount);
        for (uint256 i = 0; i < hooks.length; i++) {
            IHook(hooks[i]).afterMintHook(address(0), to, tokenAmount);
        }
        _transferInternal(_factory.getPlatformTreasury(), platformFee);
        _transferInternal(_projectTreasury, projectFee);
        emit LogMint(to, tokenAmount, payAmountActual, platformFee, projectFee);
    }

    function estimateMint(uint payAmount) public view virtual returns (uint receivedAmount, uint paidAmount, uint platformFee, uint projectFee) {
        (uint256 _platformMintTax, ) = _factory.getTaxRateOfPlatform();
        projectFee = (payAmount * _projectMintTax) / MAX_TAX_RATE_DENOMINATOR;
        platformFee = (payAmount * _platformMintTax) / MAX_TAX_RATE_DENOMINATOR;
        uint256 payAmountActual = payAmount - projectFee - platformFee;
        (receivedAmount, ) = _calculateMintAmountFromBondingCurve(payAmountActual, _getCurrentSupply());
        return (receivedAmount, payAmountActual, platformFee, projectFee);
    }

    function estimateMintNeed(uint tokenAmountWant) public view virtual returns (uint receivedAmount, uint paidAmount, uint platformFee, uint projectFee) {
        (uint256 _platformMintTax, ) = _factory.getTaxRateOfPlatform();
        (, paidAmount) = _calculateBurnAmountFromBondingCurve(tokenAmountWant, _getCurrentSupply() + tokenAmountWant);
        paidAmount *= MAX_TAX_RATE_DENOMINATOR;
        paidAmount /= (MAX_TAX_RATE_DENOMINATOR - _projectMintTax - _platformMintTax);
        projectFee = (paidAmount * _projectMintTax) / MAX_TAX_RATE_DENOMINATOR;
        platformFee = (paidAmount * _platformMintTax) / MAX_TAX_RATE_DENOMINATOR;
        return (tokenAmountWant, paidAmount, platformFee, projectFee);
    }

    function burn(address to, uint payAmount, uint minReceive) public payable virtual whenNotPaused nonReentrant {
        require(to != address(0), "can not burn to address(0)");
        // require(msg.value == 0, "Burn: dont need to attach ether");
        address from = _msgSender();
        (, uint256 amountReturn, uint256 platformFee, uint256 projectFee) = estimateBurn(payAmount);
        require(amountReturn >= minReceive, "Burn: payback amount less than minimal expect recieved");
        address[] memory hooks = getHooks();
        for (uint256 i = 0; i < hooks.length; i++) {
            IHook(hooks[i]).beforeBurnHook(from, address(0), payAmount);
        }
        _burnInternal(from, payAmount);
        for (uint256 i = 0; i < hooks.length; i++) {
            IHook(hooks[i]).afterBurnHook(from, address(0), payAmount);
        }
        _transferInternal(_factory.getPlatformTreasury(), platformFee);
        _transferInternal(_projectTreasury, projectFee);
        _transferInternal(to, amountReturn);
        emit LogBurned(from, payAmount, amountReturn, platformFee, projectFee);
    }

    function estimateBurn(uint tokenAmount) public view virtual returns (uint amountNeed, uint amountReturn, uint platformFee, uint projectFee) {
        (, uint256 _platformBurnTax) = _factory.getTaxRateOfPlatform();
        (, amountReturn) = _calculateBurnAmountFromBondingCurve(tokenAmount, _getCurrentSupply());

        projectFee = (amountReturn * _projectBurnTax) / MAX_TAX_RATE_DENOMINATOR;
        platformFee = (amountReturn * _platformBurnTax) / MAX_TAX_RATE_DENOMINATOR;
        amountReturn = amountReturn - projectFee - platformFee;
        return (tokenAmount, amountReturn, platformFee, projectFee);
    }

    function price() public view returns (uint256) {
        return _price(_getCurrentSupply());
    }

    function _transferFromInternal(address account, uint256 amount) internal virtual returns (uint256 actualAmount) {
        if (_raisingToken == address(0)) {
            require(amount <= msg.value, "invalid value");
            return amount;
        } else {
            uint256 balanceBefore = IERC20(_raisingToken).balanceOf(address(this));
            IERC20(_raisingToken).safeTransferFrom(account, address(this), amount);
            actualAmount = IERC20(_raisingToken).balanceOf(address(this)) - balanceBefore;
        }
    }

    function _transferInternal(address account, uint256 amount) internal virtual {
        if (_raisingToken == address(0)) {
            require(address(this).balance >= amount, "not enough balance");
            (bool success, ) = account.call{value: amount}("");
            require(success, "Transfer: failed");
        } else {
            IERC20(_raisingToken).safeTransfer(account, amount);
        }
    }

    function _mintInternal(address account, uint256 amount) internal virtual;

    function _burnInternal(address account, uint256 amount) internal virtual;

    function _getCurrentSupply() internal view virtual returns (uint256);

    function getHooks() public view returns (address[] memory) {
        return _factory.getTokenHooks(address(this));
    }

    event LogProjectTaxChanged();
    event LogDestroyed(address account);
    event LogProjectAdminChanged(address newAccount);
    event LogProjectTreasuryChanged(address newAccount);
    event Paused(address account);
    event Unpaused(address account);

    event LogMint(address to, uint256 tokenAmount, uint256 lockAmount, uint256 platformFee, uint256 projectFee);

    event LogBurned(address from, uint256 tokenAmount, uint256 returnAmount, uint256 platformFee, uint256 projectFee);

    fallback() external {}
}

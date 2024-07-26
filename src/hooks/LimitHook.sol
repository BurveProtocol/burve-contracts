// SPDX-License-Identifier: None

pragma solidity ^0.8.0;

import "./BaseHook.sol";
import "../interfaces/IBurveToken.sol";
import "../interfaces/IBondingCurve.sol";

contract LimitHook is BaseHook {
    string public constant hookName = "Limit";
    string public constant parameterEncoder = "(uint256)";
    mapping(address => mapping(address => uint256)) public userMinted;
    mapping(address => uint256) public Limits;
    mapping(address => bool) public LimitsRemoved;

    constructor(address factory) BaseHook(factory) {}

    function registerHook(address token, bytes calldata data) external virtual override onlyFactory {
        require(Limits[token] == 0 && !LimitsRemoved[token], "already registered");
        uint256 limit = abi.decode(data, (uint256));
        Limits[token] = limit;
    }

    function beforeMintHook(address, address to, uint256 amount) external override {
        address token = msg.sender;
        if (Limits[token] > 0) {
            address bc = IBurveToken(token).getBondingCurve();
            bytes memory bcData = IBurveToken(token).getParameters();
            (, uint256 paidAmount) = IBondingCurve(bc).calculateBurnAmountFromBondingCurve(amount, IBurveToken(token).circulatingSupply() + amount, bcData);
            require((userMinted[token][to] + paidAmount) <= Limits[token], "limited");
            userMinted[token][to] += paidAmount;
        }
    }

    function removeLimit(address token) external {
        bytes32 projectAdminRole = IBurveToken(token).PROJECT_ADMIN_ROLE();
        require(IBurveToken(token).hasRole(projectAdminRole, msg.sender), "not project admin");
        delete Limits[token];
        LimitsRemoved[token] = true;
    }
}

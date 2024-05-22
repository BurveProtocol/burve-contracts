// SPDX-License-Identifier: None

pragma solidity ^0.8.0;

import "./BaseHook.sol";
import "openzeppelin/utils/cryptography/MerkleProof.sol";
import "../interfaces/IBurveToken.sol";

/// @title
/// @author
/// @notice SBT hook is not compatible with IDO hooks
contract SBTWithAirdropHook is BaseHook {
    using SafeERC20 for IERC20;
    string public constant hookName = "SBTWithAirdropHook";
    string public constant parameterEncoder = "(uint256)";
    mapping(address => uint256) public airdropTime;
    mapping(address => bytes32) public rootMap;
    mapping(bytes32 => bool) public claimed;

    event NewAirdrop(bytes32 indexed root, address token, uint256 pay, uint256 minted);
    event UserClaimed(bytes32 indexed root, address indexed user, address indexed token, uint256 amount, uint256 seed);

    constructor(address factory) BaseHook(factory) {}

    function registerHook(address token, bytes calldata data) external virtual override onlyFactory {
        require(airdropTime[token] == 0, "already registered");
        uint256 timestamp = abi.decode(data, (uint256));
        require(timestamp > block.timestamp, "timestamp invalid");
        airdropTime[token] = timestamp;
    }

    function beforeTransferHook(address from, address to, uint256) external view override {
        require(from == address(0) || to == address(0) || from == msg.sender || to == msg.sender || from == address(this), "can not transfer");
    }

    function beforeMintHook(address, address to, uint256) external view override {
        require((block.timestamp >= airdropTime[msg.sender] && rootMap[msg.sender] != bytes32(0)) || to == address(this), "can not mint yet");
    }

    function finalAirdrop(address token, uint256 paidAmount, bytes32 root) external payable {
        bytes32 projectAdminRole = IBurveToken(token).getProjectAdminRole();
        require(IBurveToken(token).hasRole(projectAdminRole, msg.sender), "not project admin");
        address raisingToken = IBurveToken(token).getRaisingToken();
        _transferFrom(token, msg.sender, paidAmount);
        uint256 value = raisingToken == address(0) ? paidAmount : 0;
        IBurveToken(token).mint{value: value}(address(this), paidAmount, 0);
        rootMap[token] = root;
        emit NewAirdrop(root, token, paidAmount, paidAmount);
    }

    function _transferFrom(address token, address from, uint256 amount) internal virtual returns (uint256 actualAmount) {
        if (token == address(0)) {
            require(amount == msg.value, "invalid value");
            return amount;
        } else {
            uint256 balanceBefore = IERC20(token).balanceOf(address(this));
            IERC20(token).safeTransferFrom(from, address(this), amount);
            actualAmount = IERC20(token).balanceOf(address(this)) - balanceBefore;
        }
    }

    function claimAirdrop(address token, uint256 amount, uint256 seed, bytes32[] calldata _proof) external {
        bytes32 root = rootMap[token];
        address user = msg.sender;
        bytes32 _leaf = keccak256(bytes.concat(keccak256(abi.encode(token, user, amount, seed))));
        require(!claimed[_leaf], "claimed");
        claimed[_leaf] = true;
        require(MerkleProof.verify(_proof, root, _leaf), "Incorrect merkle proof");
        IERC20(token).transfer(user, amount);
        emit UserClaimed(root, user, token, amount, seed);
    }
}

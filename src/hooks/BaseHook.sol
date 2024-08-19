// SPDX-License-Identifier: None

pragma solidity ^0.8.0;

import "../interfaces/IHook.sol";
import "../interfaces/IBurveFactory.sol";

import "openzeppelin/token/ERC20/IERC20.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";

abstract contract BaseHook is IHook {
    address public immutable factory;
    modifier onlyFactory() {
        require(msg.sender == factory, "only factory");
        _;
    }

    constructor(address _factory) {
        factory = _factory;
    }

    /// factory will register token to the hook.
    /// @param token the address of token that will be deployed
    /// @param data the data will be register in the hook
    function registerHook(address token, bytes calldata data) external virtual override onlyFactory {}

    /// will be called after `ERC20._beforeTokenTransfer`, Recommend writting the minting or burning logic by override the method `beforeMintHook` or `beforeBurnHook`
    /// @param from will be address(0) when the token minting
    /// @param to will be address(0) when the token burning
    /// @param amount the amount of transferring, minting or burning
    function beforeTransferHook(address from, address to, uint256 amount) external virtual override {}

    /// will be called after `ERC20._afterTokenTransfer`, Recommend writting the minting or burning logic by override the method `beforeMintHook` or `beforeBurnHook`
    /// @param from will be address(0) when the token minting
    /// @param to will be address(0) when the token burning
    /// @param amount the amount of transferring, minting or burning
    function afterTransferHook(address from, address to, uint256 amount) external virtual override {}

    /// will be called before `ERC20._beforeTokenTransfer`
    /// @param from will be address(0)
    /// @param to the user address
    /// @param amount the amount of minting
    function beforeMintHook(address from, address to, uint256 amount) external virtual override {}

    /// will be called after `ERC20._afterTokenTransfer`
    /// @param from will be address(0)
    /// @param to the user address
    /// @param amount the amount of minting
    function afterMintHook(address from, address to, uint256 amount) external virtual override {}

    /// will be called before `ERC20._beforeTokenTransfer`
    /// @param from the user address
    /// @param to will be address(0)
    /// @param amount the amount of burning
    function beforeBurnHook(address from, address to, uint256 amount) external virtual override {}

    /// will be called after `ERC20._afterTokenTransfer`
    /// @param from the user address
    /// @param to will be address(0)
    /// @param amount the amount of burning
    function afterBurnHook(address from, address to, uint256 amount) external virtual override {}
}

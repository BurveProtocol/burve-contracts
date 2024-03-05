// SPDX-License-Identifier: None

pragma solidity ^0.8.0;

interface IHook {

    function hookName() external pure returns (string memory);
    function parameterEncoder() external pure returns (string memory);
    function registerHook(address token, bytes calldata data) external;

    function unregisterHook(address token) external;

    function beforeTransferHook(address from, address to, uint256 amount) external;

    function afterTransferHook(address from, address to, uint256 amount) external;

    function beforeMintHook(address from, address to, uint256 amount) external;

    function afterMintHook(address from, address to, uint256 amount) external;

    function beforeBurnHook(address from, address to, uint256 amount) external;

    function afterBurnHook(address from, address to, uint256 amount) external;
}

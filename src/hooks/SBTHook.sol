// SPDX-License-Identifier: None

pragma solidity ^0.8.0;

import "./BaseHook.sol";

contract SBTHook is BaseHook {
    string public constant hookName = "SBT";
    string public constant parameterEncoder = "";
    constructor(address factory) BaseHook(factory) {}

    function beforeTransferHook(address from, address to, uint256) external pure override {
        require(from == address(0) || to == address(0), "can not transfer");
    }
}

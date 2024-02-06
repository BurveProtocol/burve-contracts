// SPDX-License-Identifier: None

pragma solidity ^0.8.0;

import "./BaseHook.sol";

contract SBTHook is BaseHook {
    constructor(address factory) BaseHook(factory) {}

    function beforeTransferHook(address, address, uint256) external pure override {
        revert("can not transfer");
    }
}

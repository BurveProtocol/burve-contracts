// SPDX-License-Identifier: None

pragma solidity ^0.8.0;

import "./BaseHook.sol";

contract LaunchTimeHook is BaseHook {
    string public constant hookName = "LaunchTime";
    string public constant parameterEncoder = "(uint256)";
    constructor(address factory) BaseHook(factory) {}

    mapping(address => uint256) timeMap;

    function registerHook(address token, bytes calldata data) external virtual override onlyFactory {
        require(timeMap[token] == 0 || timeMap[token] > block.timestamp, "already launched");
        uint256 time = abi.decode(data, (uint256));
        timeMap[token] = time;
    }

    function unregisterHook(address token) external virtual override onlyFactory {
        revert("can not unregister");
        delete timeMap[token];
    }

    function beforeMintHook(address, address, uint256) external view override {
        require(block.timestamp >= timeMap[msg.sender], "not launch yet");
    }
}

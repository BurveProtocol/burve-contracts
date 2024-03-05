// SPDX-License-Identifier: None

pragma solidity ^0.8.0;

import "./BaseHook.sol";

contract HardcapHook is BaseHook {
    string public constant hookName = "Hardcap";
    string public constant parameterEncoder = "(uint256)";
    constructor(address factory) BaseHook(factory) {}

    mapping(address => uint256) capMap;

    function registerHook(address token, bytes calldata data) external virtual override onlyFactory {
        require(capMap[token] == 0, "already registered");
        uint256 cap = abi.decode(data, (uint256));
        capMap[token] = cap;
    }

    function unregisterHook(address token) external virtual override onlyFactory {
        revert("can not unregister");
        delete capMap[token];
    }

    function beforeMintHook(address, address, uint256 amount) external view override {
        require(IERC20(msg.sender).totalSupply() + amount <= capMap[msg.sender], "capped");
    }

}

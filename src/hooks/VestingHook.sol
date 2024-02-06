pragma solidity ^0.8.0;

import "./BaseHook.sol";

contract VestingHook is BaseHook {
    constructor(address factory) BaseHook(factory) {}

    mapping(address => uint256) public vestingDaysMap;
    mapping(address => uint256) public softcapMap;
    mapping(address => uint256) public vestingMap;

    function registerHook(address token, bytes calldata data) external virtual override onlyFactory {
        require(softcapMap[token] == 0, "already registered");
        (uint256 softcap, uint256 vestingDays) = abi.decode(data, (uint256, uint256));
        vestingDaysMap[token] = vestingDays;
        softcapMap[token] = softcap;
    }

    function unregisterHook(address token) external virtual override onlyFactory {
        require(vestingMap[token] == 0, "already vesting");
        delete softcapMap[token];
        delete vestingDaysMap[token];
        // delete topMap[token];
    }

    function afterMintHook(address, address, uint256) external virtual override {
        address token = msg.sender;
        uint256 softcap = softcapMap[token];
        if (softcap > 0) {
            if (IERC20(token).totalSupply() >= softcap && vestingMap[token] == 0) {
                vestingMap[token] = block.timestamp + vestingDaysMap[token] * 1 days;
            }
        }
    }

    function beforeBurnHook(address, address, uint256 amount) external virtual override {
        address token = msg.sender;
        uint256 vestingEnd = vestingMap[token];
        if (vestingEnd == 0) {
            return;
        }
        bool flag = block.timestamp >= vestingEnd || IERC20(token).totalSupply() - amount >= softcapMap[token];
        if (vestingEnd > 0 && block.timestamp >= vestingEnd) {
            //vesting end;
            delete softcapMap[token];
            delete vestingDaysMap[token];
        }
        require(flag, "vesting");
    }
}

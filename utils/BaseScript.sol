// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

abstract contract BaseScript is Script {
    bool internal testing;
    string internal jsStr;
    mapping(string => address) internal addresses;

    function setTesting(bool _testing) public {
        testing = _testing;
    }

    function startBroadcast(uint256 key) public {
        if (!testing) {
            vm.startBroadcast(key);
        }
    }

    function startBroadcast() public {
        if (!testing) {
            vm.startBroadcast();
        }
    }

    function stopBroadcast() public {
        if (!testing) {
            vm.stopBroadcast();
        }
        console.log(jsStr);
    }

    function logAddr(address addr, string memory name) internal {
        logAddrWithDesc(addr, name, "-");
    }

    function logAddrWithDesc(
        address addr,
        string memory name,
        string memory desc
    ) internal {
        console.log(
            string.concat(
                "| ",
                name,
                " | ",
                vm.toString(addr),
                " |",
                desc,
                " |"
            )
        );
        bytes memory bs = bytes(name);
        bytes memory newBs = new bytes(bs.length);
        for (uint i = 0; i < bs.length; i++) {
            if (bs[i] >= 0x20 && bs[i] <= 0x2F) {
                newBs[i] = 0x5F;
            } else {
                if (bs[i] >= 0x61 && bs[i] <= 0x7A) {
                    newBs[i] = bytes1(uint8(bs[i]) - 0x20);
                } else {
                    newBs[i] = (bs[i]);
                }
            }
        }
        bytes memory lr = new bytes(1);
        lr[0] = 0x0A;
        jsStr = string.concat(
            jsStr,
            "export const ",
            string(newBs),
            "_ADDR=",
            "'",
            vm.toString(addr),
            "';",
            string(lr)
        );
        vm.label(addr, name);
        addresses[name] = addr;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "utils/BaseTest.sol";
import "../../src/hooks/HardcapHook.sol";
import "../../src/hooks/LaunchTimeHook.sol";
import "../../src/hooks/SBTHook.sol";
import "../../src/hooks/VestingHook.sol";
import "../../src/hooks/IdoByCapHook.sol";
import "../../src/hooks/IdoByTimeHook.sol";
import "../../src/bondingCurve/LinearMixedBondingSwap.sol";

contract PresetTest is BaseTest {
    function testLOL() public {
        BurveLOL lol = deployLOL();
        (, uint paidAmount, , ) = lol.estimateMintNeed((1e8 * 1 ether * 90) / 100);
        vm.deal(user1, paidAmount * 2);
        vm.prank(user1);
        lol.mint{value: paidAmount}(address(user1), paidAmount, 0);
        console.log(lol.circulatingSupply());
        require(lol.idoEnded(), "ido not end");
    }
}

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
        lol.mint{value: 100 ether}(address(this), 100 ether, 0);
        address pair = lol.pair();
        vm.expectRevert();
        lol.transfer(pair, 1);
        vm.deal(user1, paidAmount * 2);
        vm.prank(user1);
        lol.mint{value: paidAmount - 100 ether}(address(user1), paidAmount - 100 ether, 0);
        console.log(lol.circulatingSupply());
        require(lol.idoEnded(), "ido not end");
        lol.transfer(lol.pair(), 1);
    }
}

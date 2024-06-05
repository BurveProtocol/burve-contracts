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
        vm.expectRevert();
        lol.mint{value: paidAmount}(address(user1), paidAmount, 0);
        uint160 userIndex;
        for (; paidAmount >= 100 ether; ) {
            userIndex += 1000 ether;
            address fakeUser = address(userIndex);
            vm.deal(fakeUser, 200 ether);
            vm.prank(fakeUser);
            lol.mint{value: 100 ether}(address(fakeUser), 100 ether, 0);
            if (paidAmount > 100 ether) {
                paidAmount -= 100 ether;
            }
        }

        (, paidAmount, , ) = lol.estimateMintNeed((1e8 * 1 ether * 90) / 100 - lol.circulatingSupply());
        vm.prank(user1);
        lol.mint{value: paidAmount}(address(user1), paidAmount, 0);
        console.log(lol.circulatingSupply());
        require(lol.idoEnded(),"ido not end");
    }
}

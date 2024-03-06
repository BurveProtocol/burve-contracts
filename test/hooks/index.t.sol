// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "utils/BaseTest.sol";
import "../../src/hooks/HardcapHook.sol";
import "../../src/hooks/LaunchTimeHook.sol";
import "../../src/hooks/SBTHook.sol";
import "../../src/hooks/VestingHook.sol";

contract HooksTest is BaseTest {
    function deployNewHook(address hook) public {
        vm.prank(platformAdmin);
        factory.setHook(hook, true);
    }

    function testHardcap() public {
        deployNewERC20(100, 100, 1000, 0.001 ether);
        HardcapHook hook = new HardcapHook(address(factory));
        deployNewHook(address(hook));
        vm.prank(projectAdmin);
        factory.addHookForToken(address(currentToken), address(hook), abi.encode(1 ether));
        (, uint paidAmount, , ) = currentToken.estimateMintNeed(1.1 ether);
        vm.deal(user1, paidAmount * 2);
        vm.prank(user1);
        vm.expectRevert("capped");
        currentToken.mint{value: paidAmount}(user1, paidAmount, 0);
    }

    function testLaunchTime() public {
        deployNewERC20(100, 100, 1000, 0.001 ether);
        LaunchTimeHook hook = new LaunchTimeHook(address(factory));
        deployNewHook(address(hook));
        vm.prank(projectAdmin);
        factory.addHookForToken(address(currentToken), address(hook), abi.encode(block.timestamp + 1 days));
        (, uint paidAmount, , ) = currentToken.estimateMintNeed(1.1 ether);
        vm.deal(user1, paidAmount * 2);
        vm.startPrank(user1);
        vm.expectRevert("not launch yet");
        currentToken.mint{value: paidAmount}(user1, paidAmount, 0);
        vm.warp(block.timestamp + 1 days);
        currentToken.mint{value: paidAmount}(user1, paidAmount, 0);
    }

    function testVesting() public {
        deployNewERC20(100, 100, 1000, 0.001 ether);
        VestingHook hook = new VestingHook(address(factory));
        deployNewHook(address(hook));
        vm.prank(projectAdmin);
        factory.addHookForToken(address(currentToken), address(hook), abi.encode(1 ether, 1));
        (, uint paidAmount, , ) = currentToken.estimateMintNeed(1.1 ether);
        vm.deal(user1, paidAmount * 2);
        vm.prank(user1);
        currentToken.mint{value: paidAmount}(user1, paidAmount, 0);
        vm.expectRevert("vesting");
        vm.prank(user1);
        currentToken.burn(user1, 1 ether, 0);
    }

    function testSBT() public {
        deployNewERC20(100, 100, 1000, 0.001 ether);
        SBTHook hook = new SBTHook(address(factory));
        deployNewHook(address(hook));
        vm.prank(projectAdmin);
        factory.addHookForToken(address(currentToken), address(hook), "");
        (, uint paidAmount, , ) = currentToken.estimateMintNeed(1.1 ether);
        vm.deal(user1, paidAmount * 2);
        vm.prank(user1);
        currentToken.mint{value: paidAmount}(user1, paidAmount, 0);
        vm.prank(user1);
        vm.expectRevert("can not transfer");
        currentToken.transfer(user2, 1 ether);
    }
}

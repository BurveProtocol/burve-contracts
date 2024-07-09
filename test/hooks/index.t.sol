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

contract HooksTest is BaseTest {
    function deployNewHook(address hook) public {
        vm.prank(platformAdmin);
        factory.setHook(hook, true);
    }

    function testHardcap() public {
        HardcapHook hook = new HardcapHook(address(factory));
        deployNewHook(address(hook));
        deployNewERC20WithHooks(100, 100, 1000, 0.001 ether, 0, address(hook), abi.encode(1 ether));
        (, uint paidAmount, , ) = currentToken.estimateMintNeed(1.1 ether);
        vm.deal(user1, paidAmount * 2);
        vm.prank(user1);
        vm.expectRevert("capped");
        currentToken.mint{value: paidAmount}(user1, paidAmount, 0);
        (, paidAmount, , ) = currentToken.estimateMintNeed(0.9 ether);
        vm.deal(user1, paidAmount * 2);
        vm.prank(user1);
        currentToken.mint{value: paidAmount}(user1, paidAmount, 0);
    }

    function testLaunchTime() public {
        LaunchTimeHook hook = new LaunchTimeHook(address(factory));
        deployNewHook(address(hook));
        deployNewERC20WithHooks(100, 100, 1000, 0.001 ether, 0, address(hook), abi.encode(block.timestamp + 1 days));
        (, uint paidAmount, , ) = currentToken.estimateMintNeed(1.1 ether);
        vm.deal(user1, paidAmount * 2);
        vm.startPrank(user1);
        vm.expectRevert("not launch yet");
        currentToken.mint{value: paidAmount}(user1, paidAmount, 0);
        vm.warp(block.timestamp + 1 days);
        currentToken.mint{value: paidAmount}(user1, paidAmount, 0);
    }

    function testVesting() public {
        VestingHook hook = new VestingHook(address(factory));
        deployNewHook(address(hook));
        deployNewERC20WithHooks(100, 100, 1000, 0.001 ether, 0, address(hook), abi.encode(1 ether, 1));
        (, uint paidAmount, , ) = currentToken.estimateMintNeed(1.1 ether);
        vm.deal(user1, paidAmount * 2);
        vm.prank(user1);
        currentToken.mint{value: paidAmount}(user1, paidAmount, 0);
        vm.expectRevert("vesting");
        vm.prank(user1);
        currentToken.burn(user1, 1 ether, 0);
    }

    function testSBT() public {
        SBTHook hook = new SBTHook(address(factory));
        deployNewHook(address(hook));
        deployNewERC20WithHooks(100, 100, 1000, 0.001 ether, 0, address(hook), "");
        (, uint paidAmount, , ) = currentToken.estimateMintNeed(1.1 ether);
        vm.deal(user1, paidAmount * 2);
        vm.prank(user1);
        currentToken.mint{value: paidAmount}(user1, paidAmount, 0);
        vm.prank(user1);
        vm.expectRevert("can not transfer");
        currentToken.transfer(user2, 1 ether);
    }

    function testIdoByTime() public {
        IdoByTimeHook hook = new IdoByTimeHook(address(factory));
        deployNewHook(address(hook));
        uint256 timestamp = block.timestamp + 1 days;
        bytes memory data = abi.encode(timestamp);
        deployNewERC20WithHooks(100, 100, 1000, 0.001 ether, 0, address(hook), data);
        vm.prank(user1);
        hook.fund{value: 1 ether}(currentToken, 1 ether);
        vm.prank(user2);
        hook.fund{value: 2 ether}(currentToken, 2 ether);
        vm.prank(user2);
        hook.fund{value: 3 ether}(currentToken, 3 ether);
        vm.warp(timestamp + 1);
        vm.prank(user1);
        hook.claim(address(currentToken));
        console.log(IERC20(address(currentToken)).balanceOf(user1));
        console.log(IBurveToken(address(currentToken)).circulatingSupply());
    }

    function testIdoByCap() public {
        IdoByCapHook hook = new IdoByCapHook(address(factory));
        deployNewHook(address(hook));
        uint256 timestamp = block.timestamp + 1 days;
        bytes memory data = abi.encode(5 ether, timestamp);
        deployNewERC20WithHooks(100, 100, 1000, 0.001 ether, 0, address(hook), data);
        vm.prank(user2);
        hook.fund{value: 2 ether}(currentToken, 2 ether);
        vm.prank(user3);
        hook.fund{value: 3 ether}(currentToken, 3 ether);
        vm.prank(user1);
        vm.expectRevert();
        hook.fund{value: 1 ether}(currentToken, 1 ether);
        vm.warp(timestamp + 1);
        vm.prank(user2);
        hook.claim(address(currentToken));
        console.log(IERC20(address(currentToken)).balanceOf(user2));
        console.log(IBurveToken(address(currentToken)).circulatingSupply());
    }
}

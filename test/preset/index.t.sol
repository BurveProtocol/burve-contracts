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
    uint256 bscFork;
    uint256 baseFork;

    function setUp() public override {
        super.setUp();
        bscFork = vm.createFork("https://rpc.ankr.com/bsc");
        baseFork = vm.createFork("https://rpc.ankr.com/base");
        vm.selectFork(bscFork);
        address lolImpl = address(new BurveLOLBsc());
        vm.prank(platformAdmin);
        factory.updateBurveImplement("LOL", address(lolImpl));
    }

    address raisingToken = address(0);

    function testLOL() public {
        BurveLOL lol = deployLOL(raisingToken);
        (, uint paidAmount, , ) = lol.estimateMintNeed((1e8 * 1 ether * 90) / 100);
        if (raisingToken != address(0)) {
            vm.prank(user1);
            IERC20(raisingToken).approve(address(lol), type(uint256).max);
            IERC20(raisingToken).approve(address(lol), type(uint256).max);
            vm.prank(user1);
            TestERC20(raisingToken).mint(paidAmount * 2);
            TestERC20(raisingToken).mint(paidAmount * 2);
        }
        lol.mint{value: 100 ether}(address(this), 100 ether, 0);
        address pair = lol.pair();
        vm.expectRevert();
        lol.transfer(pair, 1);
        vm.deal(user1, paidAmount * 2);
        vm.prank(user1);
        lol.mint{value: paidAmount - 100 ether}(address(user1), paidAmount - 100 ether - 1, 0);
        console.log(lol.circulatingSupply());
        require(lol.idoEnded(), "ido not end");
        lol.transfer(lol.pair(), 1);
        if (vm.activeFork() == bscFork) {
            vm.selectFork(baseFork);
            if (raisingToken != address(0)) {
                raisingToken = address(new TestERC20());
            }
            address lolImpl = address(new BurveLOLBase());
            vm.prank(platformAdmin);
            factory.updateBurveImplement("LOL", address(lolImpl));
            testLOL();
        }
        if (raisingToken == address(0)) {
            vm.selectFork(bscFork);
            raisingToken = address(new TestERC20());
            testLOL();
        }
    }
}

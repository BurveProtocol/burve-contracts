// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "utils/BaseTest.sol";

contract AccessControlTest is BaseTest {
    function testTokenRole() public {
        vm.startPrank(projectAdmin);
        deployNewERC20(500, 1000, 1000, 0.001 ether);
        require(currentToken.hasRole(currentToken.FACTORY_ROLE(), address(factory)), "factory must have FACTORY_ROLE");
        require(!currentToken.hasRole(currentToken.FACTORY_ROLE(), platformAdmin), "platformAdmin must not have FACTORY_ROLE");
        require(!currentToken.hasRole(currentToken.FACTORY_ROLE(), platformTreasury), "platformTreasury must not have FACTORY_ROLE");
        require(!currentToken.hasRole(currentToken.FACTORY_ROLE(), projectAdmin), "projectAdmin must not have FACTORY_ROLE");
        require(!currentToken.hasRole(currentToken.FACTORY_ROLE(), projectTreasury), "projectTreasury must not have FACTORY_ROLE");

        require(!currentToken.hasRole(currentToken.PROJECT_ADMIN_ROLE(), address(factory)), "factory must not have PROJECT_ADMIN_ROLE");
        require(!currentToken.hasRole(currentToken.PROJECT_ADMIN_ROLE(), platformAdmin), "platformAdmin must not have PROJECT_ADMIN_ROLE");
        require(!currentToken.hasRole(currentToken.PROJECT_ADMIN_ROLE(), platformTreasury), "platformTreasury must not have PROJECT_ADMIN_ROLE");
        require(currentToken.hasRole(currentToken.PROJECT_ADMIN_ROLE(), projectAdmin), "projectAdmin must have PROJECT_ADMIN_ROLE");
        require(!currentToken.hasRole(currentToken.PROJECT_ADMIN_ROLE(), projectTreasury), "projectTreasury must not have PROJECT_ADMIN_ROLE");

        address[] memory operators = new address[](5);
        operators[0] = address(factory);
        operators[1] = platformAdmin;
        operators[2] = platformTreasury;
        operators[3] = projectAdmin;
        operators[4] = projectTreasury;
        bytes32 factoryRole = currentToken.FACTORY_ROLE();
        bytes32 projectAdminRole = currentToken.PROJECT_ADMIN_ROLE();
        for (uint256 i; i < operators.length; i++) {
            vm.startPrank(operators[i]);
            vm.expectRevert();
            currentToken.grantRole(factoryRole, user3);
            vm.expectRevert();
            currentToken.grantRole(projectAdminRole, user3);
            vm.stopPrank();
        }

        vm.startPrank(user2);
        vm.expectRevert();
        currentToken.setProjectTreasury(user2);
        vm.expectRevert();
        currentToken.setProjectAdmin(user2);
        vm.stopPrank();

        vm.startPrank(projectAdmin);
        vm.warp(block.timestamp + 48 hours);
        currentToken.setProjectTreasury(user2);
        currentToken.setProjectAdmin(user2);
        vm.stopPrank();

        require(currentToken.hasRole(currentToken.PROJECT_ADMIN_ROLE(), user2));
        require(!currentToken.hasRole(currentToken.PROJECT_ADMIN_ROLE(), projectAdmin));
    }

    function testFactoryRole() public {
        vm.prank(platformAdmin);
        vm.expectRevert();
        factory.initialize(platformAdmin, platformAdmin, address(0));

        ExpMixedBondingSwap newCurve = new ExpMixedBondingSwap();
        vm.expectRevert();
        factory.addBondingCurveImplement(address(newCurve));

        deployNewERC20(100, 100, 1000, 0.001 ether);

        bytes memory data = abi.encode(["uint256", "uint256"], [14 ether, 2e6 ether]);
        vm.expectRevert();
        currentToken.initialize(address(newCurve), "Test Token", "TT", "metadata", projectTreasury, projectTreasury, 2000, 2000, address(0), data, address(factory));

        BurveERC20Mixed newErc20 = new BurveERC20Mixed();
        vm.expectRevert();
        factory.updateBurveImplement("ERC20", address(newErc20));

        vm.prank(platformAdmin);
        factory.updateBurveImplement("ERC20", address(newErc20));

        //requestUpgrade
        vm.expectRevert();
        factory.requestUpgrade(address(currentToken), data);
        vm.prank(projectAdmin);
        vm.expectRevert();
        factory.requestUpgrade(address(currentToken), data);
        vm.prank(platformAdmin);
        factory.requestUpgrade(address(currentToken), data);

        //rejectUpgrade

        vm.expectRevert();
        factory.rejectUpgrade(address(currentToken), "reason");
        vm.prank(platformAdmin);
        vm.expectRevert();
        factory.rejectUpgrade(address(currentToken), "reason");
        vm.prank(projectAdmin);
        factory.rejectUpgrade(address(currentToken), "reason");

        //upgradeTokenImplement
        vm.prank(platformAdmin);
        factory.requestUpgrade(address(currentToken), data);
        vm.warp(block.timestamp + 3 days);
        vm.expectRevert();
        factory.upgradeTokenImplement(address(currentToken));
        vm.prank(projectAdmin);
        vm.expectRevert();
        factory.upgradeTokenImplement(address(currentToken));
        vm.prank(platformAdmin);
        factory.upgradeTokenImplement(address(currentToken));
    }

    function testPause() public {
        deployNewERC20(100, 100, 1000, 0.001 ether);
        vm.deal(user1, 100000 ether);
        vm.prank(user1);
        currentToken.mint{value: 1 ether * (10)}(user1, 1 ether * (10), 0);
        vm.prank(user1);
        vm.expectRevert();
        factory.pause(address(currentToken));

        vm.prank(user1);
        vm.expectRevert();
        factory.unpause(address(currentToken));

        vm.prank(projectAdmin);
        vm.expectRevert();
        factory.pause(address(currentToken));

        vm.prank(projectAdmin);
        vm.expectRevert();
        factory.unpause(address(currentToken));

        vm.prank(projectAdmin);
        vm.expectRevert();
        currentToken.unpause();

        vm.prank(projectAdmin);
        vm.expectRevert();
        currentToken.unpause();

        vm.prank(platformAdmin);
        vm.expectRevert();
        currentToken.unpause();

        vm.prank(platformAdmin);
        vm.expectRevert();
        currentToken.unpause();

        require(!currentToken.paused(), "paused should be false before pause");

        vm.prank(platformAdmin);
        factory.pause(address(currentToken));

        require(currentToken.paused(), "paused should be true after pause");

        uint256 erc20Balance = currentToken.balanceOf(user1);
        vm.expectRevert();
        currentToken.mint{value: 1 ether * (10)}(user1, 1 ether * (10), 0);
        vm.prank(user1);
        vm.expectRevert();
        currentToken.burn(user1, erc20Balance, 0);

        vm.prank(user1);
        vm.expectRevert();
        currentToken.transfer(user2, erc20Balance);

        vm.prank(platformAdmin);
        factory.unpause(address(currentToken));

        require(!currentToken.paused(), "paused should be false after unpause");
        vm.prank(user1);
        currentToken.transfer(user2, erc20Balance);

        currentToken.mint{value: 1 ether * (10)}(user1, 1 ether * (10), 0);

        erc20Balance = currentToken.balanceOf(user1);
        vm.prank(user1);

        currentToken.burn(user1, erc20Balance, 0);
    }
}

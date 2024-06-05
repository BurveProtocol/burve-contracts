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
        IBurveFactory.TokenInfo memory token = IBurveFactory.TokenInfo({
            tokenType: "",
            bondingCurveType: "",
            raisingTokenAddr: address(0),
            symbol: "TT",
            name: "Test Token",
            metadata: "metadata",
            projectTreasury: projectTreasury,
            projectAdmin: projectAdmin,
            projectMintTax: 2000,
            projectBurnTax: 2000,
            data: data
        });
        currentToken.initialize(address(newCurve), token, address(factory));

        BurveERC20Mixed newErc20 = new BurveERC20Mixed();
        vm.expectRevert();
        factory.updateBurveImplement("ERC20", address(newErc20));

        vm.prank(platformAdmin);
        factory.updateBurveImplement("ERC20", address(newErc20));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "utils/BaseTest.sol";

contract FeeTest is BaseTest {
    function testFee() public {
        (uint256 mintTax, uint256 burnTax) = (200, 300);
        deployNewERC20(mintTax, burnTax, 1000, 0.001 ether);
        vm.deal(user1, 1000000 ether);
        vault.deposit{value: 1 ether}(currentToken.getRaisingToken(), address(currentToken));
        vm.prank(user1);
        currentToken.mint(user1, 0);
        uint256 projectTreasuryBalance = projectTreasury.balance;
        vm.prank(platformAdmin);
        factory.claimAllFee();
        uint256 platformTreasuryBalance = platformTreasury.balance;
        console.log("mint tax", mintTax);
        console.log("project fee", projectTreasuryBalance);
        console.log("platform fee", platformTreasuryBalance);
        require((1 ether * mintTax) / 10000 == projectTreasuryBalance);
        require((1 ether * 100) / 10000 == platformTreasuryBalance);
        vm.deal(projectTreasury, 0);
        vm.deal(platformTreasury, 0);
        uint256 erc20Balance = currentToken.balanceOf(user1);
        uint256 tokenBalanceBefore = vault.balanceOf(currentToken.getRaisingToken(), address(currentToken));
        console.log(erc20Balance, currentToken.totalSupply());
        vm.prank(user1);
        currentToken.burn(user1, erc20Balance, 0);
        vm.prank(platformAdmin);
        factory.claimAllFee();
        uint256 tokenBalanceAfter = vault.balanceOf(currentToken.getRaisingToken(), address(currentToken));
        projectTreasuryBalance = projectTreasury.balance;
        platformTreasuryBalance = platformTreasury.balance;

        console.log("burn tax", burnTax);
        console.log("project fee", projectTreasuryBalance);
        console.log("platform fee", platformTreasuryBalance);

        require(((tokenBalanceBefore - tokenBalanceAfter) * burnTax) / 10000 == projectTreasuryBalance);
        require(((tokenBalanceBefore - tokenBalanceAfter) * 100) / 10000 == platformTreasuryBalance);
    }
}

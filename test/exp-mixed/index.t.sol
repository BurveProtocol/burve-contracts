// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "utils/BaseTest.sol";

contract ExpMixedTest is BaseTest {
    uint256 supply = 1e7 ether;
    uint256 px = 0.001 ether;
    uint256 tvl = 2000 ether;
    ExpMixedBondingSwap curve;
    bytes data;
    uint256 round = 100;

    function setUp() public override {
        super.setUp();
        uint256 A = 1000;
        uint256 a = 0.01 ether;
        uint256 b = ((A * 1 ether) / a) * 1e18;
        data = abi.encode(a, b);
        curve = ExpMixedBondingSwap(factory.getBondingCurveImplement(bondingCurveType));
        deployNewERC20(0, 0, A, a);
    }

    function _one(uint256 currentSupply, uint256 nativeAsset, string calldata calltype) external view {
        (uint256 tokenAmount1, uint256 raisingTokenAmount1) = curve.calculateMintAmountFromBondingCurve(nativeAsset, currentSupply, data);
        (uint256 tokenAmount2, uint256 raisingTokenAmount2) = curve.calculateBurnAmountFromBondingCurve(tokenAmount1, currentSupply + tokenAmount1, data);
        uint256 price = curve.price(currentSupply + tokenAmount1, data);
        console.log(calltype);
        console.log("erc20 minted", tokenAmount1);
        console.log("raising token transferred", nativeAsset);
        console.log("burn return raising token", raisingTokenAmount2);
        console.log("supply", currentSupply + tokenAmount1);
        console.log("price raising-token/erc20", price);
        console.log("deviation (wei)", nativeAsset - raisingTokenAmount2);
        require(nativeAsset >= raisingTokenAmount2, "raising token transferred must greater than the raisingTokenAmount of calculateBurnAmountFromBondingCurve");
        console.log(nativeAsset, raisingTokenAmount2);
        // require(
        //     (currentSupply == 0 ? (nativeAsset / (nativeAsset - raisingTokenAmount2) > (1 ether)) : (tokenAmount1 < 10000 ether) || nativeAsset - (raisingTokenAmount2) < (10000 ether)),
        //     "the deviation between calculateMintAmountFromBondingCurve and calculateBurnAmountFromBondingCurve must less than 1000wei || the ratio of deviation less than 1e-18"
        // );
    }

    function testCalculation() public {
        uint256 nativeAsset = tvl;
        (uint256 tokenAmount1, uint256 raisingTokenAmount1) = curve.calculateMintAmountFromBondingCurve(nativeAsset, 0, data);
        (uint256 tokenAmount2, uint256 raisingTokenAmount2) = curve.calculateBurnAmountFromBondingCurve(tokenAmount1, tokenAmount1, data);
        (uint256 tokenAmount3, uint256 raisingTokenAmount3) = curve.calculateBurnAmountFromBondingCurve(1e9, tokenAmount1 + 1e9, data);
        uint256 price = curve.price(tokenAmount1, data);
        uint256 differentialPrice = curve.price(tokenAmount1 + 1e9, data);
        console.log("erc20 minted", tokenAmount1);
        console.log("raising token transferred", nativeAsset);
        console.log("burn return raising token", raisingTokenAmount2);
        console.log("price raising token/erc20", price);
        console.log("differential price", differentialPrice);
        console.log("deviation (wei)", nativeAsset - raisingTokenAmount2);
        uint256 res = differentialPrice > price ? differentialPrice - price : price - differentialPrice;
        require(res <= 1 ether / 1000, " the deviation between calculation price and differential price must less than 0.1 %");
        uint256 tvlLower = 1000 ether;

        uint256 supplyLower = 100000 ether;
        bool tvlFlag = true;
        bool supplyFlag = true;
        for ((uint256 i, uint256 j, uint256 count) = (tvlLower, supplyLower, 0); (tvlFlag && i <= type(uint256).max / 10) || (supplyFlag && j <= type(uint256).max / 10); count = count + 1) {
            if (count==200){
                break;
            }
            console.log("--------------count--------------", count);
            if (tvlFlag && i <= type(uint256).max / 10) {
                try this._one(0, i, "tvl") {
                    i = ((i / 10) * 11);
                } catch {
                    tvlFlag = false;
                }
            }
            if (supplyFlag && j <= type(uint192).max) {
                try this._one(j, 1 ether, "supply") {
                    j = ((j / 10) * 11);
                } catch {
                    supplyFlag = false;
                }
            }
        }
    }

    function testEstimateMintBurn() public {
        vm.startPrank(user1);
        (uint receivedAmount, , , ) = currentToken.estimateMint(1000 ether);
        vm.expectRevert();
        currentToken.mint{value: 1000 ether}(user1, 1000 ether, receivedAmount + 1);
        currentToken.mint{value: 1000 ether}(user1, 1000 ether, receivedAmount);

        uint256 erc20Balance = currentToken.balanceOf(user1);
        (, uint amountReturn, , ) = currentToken.estimateBurn(erc20Balance);

        vm.expectRevert();
        currentToken.burn(user1, erc20Balance, amountReturn + 1);
        currentToken.burn(user1, erc20Balance, amountReturn);
    }

    function testMultiMint() public {
        vm.startPrank(user1);
        for (uint256 i = 0; i < round; i++) {
            currentToken.mint{value: 1000 ether}(user1, 1000 ether, 0);
            uint256 platformBalance = platformTreasury.balance;
            uint256 treasuryBalance = projectTreasury.balance;
            uint256 tokenBalance = address(currentToken).balance;
            uint256 userBalance = user1.balance;
            uint256 erc20Balance = currentToken.balanceOf(user1);
            (uint amountNeed, uint amountReturn, uint platformFee, uint projectFee) = currentToken.estimateBurn(erc20Balance);
            uint256 price = currentToken.price();
            console.log("----------round---------", i);
            console.log("platform treasury balance", platformBalance);
            console.log("project treasury balance", treasuryBalance);

            console.log("token contract balance", tokenBalance);
            console.log("price raising-token/erc20", price);
            console.log("user balance", userBalance);
            console.log("user token balance", erc20Balance);
            uint256 totalAssetCanReturn = amountReturn + platformFee + projectFee;

            console.log("the amount of raising token that after burn all", totalAssetCanReturn);
            console.log("deviation (wei)", tokenBalance - totalAssetCanReturn);
        }
    }

    function testMultiBurn() public {
        vm.startPrank(user1);
        currentToken.mint{value: 500000 ether}(user1, 500000 ether, 0);

        uint256 totalErc20Balance = currentToken.balanceOf(user1);
        for (uint256 i = 0; i < round; i++) {
            currentToken.mint{value: 1000 ether}(user1, 1000 ether, 0);
            uint256 platformBalance = platformTreasury.balance;
            uint256 treasuryBalance = projectTreasury.balance;
            uint256 tokenBalance = address(currentToken).balance;
            uint256 userBalance = user1.balance;
            uint256 erc20Balance = currentToken.balanceOf(user1);
            (uint amountNeed, uint amountReturn, uint platformFee, uint projectFee) = currentToken.estimateBurn(erc20Balance);
            uint256 price = currentToken.price();
            console.log("----------round---------", i);
            console.log("platform treasury balance", platformBalance);
            console.log("project treasury balance", treasuryBalance);

            console.log("token contract balance", tokenBalance);
            console.log("price raising-token/erc20", price);
            console.log("user balance", userBalance);
            console.log("user token balance", erc20Balance);
            uint256 totalAssetCanReturn = amountReturn + platformFee + projectFee;

            console.log("the amount of raising token that after burn all", totalAssetCanReturn);
            console.log("deviation (wei)", tokenBalance - totalAssetCanReturn);
            currentToken.burn(user1, totalErc20Balance / 100, 0);
        }
    }

    function testRandomMintAndBurn() public {
        vm.warp(10000);
        for (uint256 i = 0; i < round; i++) {
            // user 1 only mint 1~99 ether
            // user 3 mint and transfer to user 2
            uint256 randomSeed = uint256(keccak256(abi.encode(block.timestamp, i)));
            uint256 amount1 = ((randomSeed % 49) + 1) * 0.1 ether;
            vm.prank(user1);
            currentToken.mint{value: amount1}(user1, amount1, 0);
            // user 2 mint or burn random amount
            uint256 amount2 = ((randomSeed % 999) + 1) * 0.1 ether;
            vm.prank(user2);
            currentToken.mint{value: amount2}(user2, amount2, 0);
            uint256 user2Erc20 = currentToken.balanceOf(user2);
            vm.prank(user2);
            currentToken.burn(user2, ((user2Erc20 % 88) + 1) / 100, 0);
            // user 3 mint a alot and transfer user2 or user3
            // user 3 will burn randomly
            uint256 amount3 = ((randomSeed % 900) + 100) * 0.1 ether;
            vm.prank(user3);
            if (randomSeed % 2 == 1) {
                currentToken.mint{value: amount3}(user2, amount3, 0);
            } else {
                currentToken.mint{value: amount3}(user3, amount3, 0);
            }
            if (randomSeed % 10 < 2) {
                uint256 user3Erc20 = currentToken.balanceOf(user3);
                if (user3Erc20 >= 0.1 ether) {
                    vm.prank(user3);
                    uint256 platformBalance = platformTreasury.balance;
                    uint256 treasuryBalance = projectTreasury.balance;
                    uint256 tokenBalance = address(currentToken).balance;
                    uint256 user1Balance = user1.balance;
                    uint256 erc20Balance1 = currentToken.balanceOf(user1);
                    uint256 user2Balance = user2.balance;
                    uint256 erc20Balance2 = currentToken.balanceOf(user2);
                    uint256 user3Balance = user3.balance;
                    uint256 erc20Balance3 = currentToken.balanceOf(user3);

                    uint256 contractTotalSupply = currentToken.totalSupply();

                    uint256 price = currentToken.price();

                    console.log("----------round---------", i);
                    console.log("platform treasury balance", platformBalance);
                    console.log("project treasury balance", treasuryBalance);

                    console.log("token contract balance", tokenBalance);
                    console.log("price raising-token/erc20", price);
                    console.log("user 1 balance", user1Balance);
                    console.log("user 1 token balance", erc20Balance1);
                    console.log("user 2 balance", user2Balance);
                    console.log("user 2 token balance", erc20Balance2);
                    console.log("user 3 balance", user3Balance);
                    console.log("user 3 token balance", erc20Balance3);

                    (uint amountNeed, uint amountReturn, uint platformFee, uint projectFee) = currentToken.estimateBurn(contractTotalSupply);
                    vm.prank(user3);
                    currentToken.burn(user3, (user3Erc20 * ((randomSeed % 99) + 1)) / 100, 0);
                    uint256 totalAssetCanReturn = amountReturn + platformFee + projectFee;
                    console.log("the amount of raising token that after burn all", totalAssetCanReturn);
                    console.log("deviation (wei)", tokenBalance - totalAssetCanReturn);
                }
            }
        }
    }

    function testFuzz() public {
        vm.startPrank(user1);
        uint256 amount = type(uint32).max;
        amount = 97999999999999999991000000000000000107.3635064 ether;
        console.log(amount);
        currentToken.mint{value: amount}(user1, amount, 0);
        uint256 balanceBefore = address(currentToken).balance;
        console.log(currentToken.totalSupply());
        currentToken.burn(user1, currentToken.totalSupply(), 0);
        console.log(address(currentToken).balance, balanceBefore);
        console.log(currentToken.totalSupply());
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "utils/BaseTest.sol";

contract CoverageTest is BaseTest {
    function testOtherFunctions() public {
        vm.startPrank(platformAdmin);
        require(factory.getRoute() == address(route));
        factory.setPlatformTreasury(address(0xdd));
        require(factory.getPlatformTreasury() == address(0xdd));
        factory.setPlatformTaxRate(90, 80);
        vm.expectRevert();
        factory.setPlatformTaxRate(10000, 10000);
        vm.expectRevert();
        factory.setPlatformTaxRate(80, 10000);
        (uint256 mintTax, uint256 burnTax) = factory.getTaxRateOfPlatform();
        require(mintTax == 90 && burnTax == 80);

        factory.setHook(address(0xdead), true);
        require(factory.whitelistHooks(address(0xdead)));
        factory.setHook(address(0xdead), false);
        require(!factory.whitelistHooks(address(0xdead)));
        vm.expectRevert();
        factory.setRoute(address(0));
        factory.setPlatformAdmin(address(0xad));
        require(factory.getPlatformAdmin() == address(0xad));
        vm.deal(address(user1), 200 ether);
        vm.startPrank(user1);
        deployNewERC20WithFirstMint(100, 100, 1000, 0.002 ether, 100 ether);
        require(factory.getTokensLength() == 1);
        require(factory.getToken(0) == address(currentToken));
        vm.stopPrank();

        uint256 p = 0.002 ether;
        uint256 k = 0.1 ether;
        bytes memory data = abi.encode(k, p);
        fakeUSDT.mint(1000 ether);
        IBurveFactory.TokenInfo memory info = IBurveFactory.TokenInfo({
            tokenType: "ERC20",
            bondingCurveType: "linear",
            name: "Burve ERC20 Token",
            symbol: "BET",
            metadata: "",
            projectAdmin: address(this),
            projectTreasury: projectTreasury,
            projectMintTax: 100,
            projectBurnTax: 100,
            raisingTokenAddr: address(fakeUSDT),
            data: data
        });
        fakeUSDT.approve(address(factory), type(uint256).max);
        BurveERC20WithSupply linear = BurveERC20WithSupply(factory.deployToken(info, 100 ether));
        linear.burn(address(this), 1 ether, 0);
        vm.warp(block.timestamp + 3 days);
        vm.expectRevert();
        linear.setProjectTaxRate(5000, 5000);
        console.log(linear.price());
        linear.setProjectTaxRateAndTreasury(address(0x2222), 88, 99);
        require(linear.getProjectAdmin() == address(this));
        require(linear.getFactory() == address(factory));
        require(linear.getProjectTreasury() == address(0x2222));
        (uint256 m, uint256 b) = linear.getTaxRateOfProject();
        require(m == 88 && b == 99);
        linear.setMetadata("new meta");
        require(keccak256(bytes(linear.getMetadata())) == keccak256(bytes("new meta")));
        require(keccak256(bytes(IBondingCurve(linear.getBondingCurve()).BondingCurveType())) == keccak256(bytes("linear")));
        require(keccak256(linear.getParameters()) == keccak256(data));
        data = abi.encode(0, p);
        fakeUSDT.mint(1000 ether);
        info = IBurveFactory.TokenInfo({
            tokenType: "ERC20",
            bondingCurveType: "linear",
            name: "Burve ERC20 Token",
            symbol: "BET",
            metadata: "",
            projectAdmin: address(this),
            projectTreasury: projectTreasury,
            projectMintTax: 100,
            projectBurnTax: 100,
            raisingTokenAddr: address(fakeUSDT),
            data: data
        });
        fakeUSDT.approve(address(factory), type(uint256).max);
        linear = BurveERC20WithSupply(factory.deployToken(info, 100 ether));
    }
}

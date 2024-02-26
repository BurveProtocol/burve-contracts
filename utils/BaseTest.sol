// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/BurveTokenFactory.sol";
import "../src/bondingCurve/ExpMixedBondingSwap.sol";
import "../src/preset/BurveERC20Mixed.sol";

abstract contract BaseTest is Test {
    address deployer = address(0x11);
    address platformAdmin = address(0x21);
    address platformTreasury = address(0x22);
    address projectAdmin = address(0x31);
    address projectTreasury = address(0x32);
    address user1 = address(0x41);
    address user2 = address(0x42);
    address user3 = address(0x43);
    BurveTokenFactory factory;
    BurveERC20Mixed currentToken;
    string bondingCurveType;

    function setUp() public virtual {
        vm.startPrank(platformAdmin);
        ProxyAdmin admin = new ProxyAdmin();
        // BurveRoute route = new BurveRoute();
        BurveTokenFactory factoryImpl = new BurveTokenFactory();
        bytes memory factoryInitData = abi.encodeWithSelector(BurveTokenFactory.initialize.selector, platformAdmin, platformTreasury, address(0));
        TransparentUpgradeableProxy factoryProxy = new TransparentUpgradeableProxy(address(factoryImpl), address(admin), factoryInitData);
        factory = BurveTokenFactory(payable(factoryProxy));
        ExpMixedBondingSwap exp = new ExpMixedBondingSwap();
        factory.addBondingCurveImplement(address(exp));
        BurveERC20Mixed erc20Impl = new BurveERC20Mixed();
        factory.updateBurveImplement("ERC20", address(erc20Impl));
        vm.label(address(admin), "Factory Proxy Admin");
        vm.label(address(factoryProxy), "Factory Proxy");
        // logAddr(address(route), "Burve Route");
        vm.label(address(factoryImpl), "Factory Implement");
        vm.label(address(exp), string.concat(exp.BondingCurveType(), " Bonding Curve"));
        bondingCurveType = exp.BondingCurveType();
        vm.label(address(factory), "factory");
        vm.label(deployer, "deployer");
        vm.label(platformTreasury, "platformTreasury");
        vm.label(projectAdmin, "projectAdmin");
        vm.label(user1, "user1");
        vm.label(user2, "user2");
        vm.stopPrank();
    }

    function deployNewERC20(uint256 mintTax, uint256 burnTax, uint256 A, uint256 initPrice) public returns (BurveERC20Mixed) {
        uint256 a = initPrice;
        uint256 b = ((A * 1 ether) / a) * 1e18;
        bytes memory data = abi.encode(a, b);
        IBurveFactory.TokenInfo memory info = IBurveFactory.TokenInfo({
            tokenType: "ERC20",
            bondingCurveType: bondingCurveType,
            name: "Burve ERC20 Token",
            symbol: "BET",
            metadata: "",
            projectAdmin: projectAdmin,
            projectTreasury: projectTreasury,
            projectMintTax: mintTax,
            projectBurnTax: burnTax,
            raisingTokenAddr: address(0),
            data: data
        });
        currentToken = BurveERC20Mixed(factory.deployToken(info, 0));
        return currentToken;
    }
}

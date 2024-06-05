// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/BurveTokenFactory.sol";
import "../src/bondingCurve/ExpMixedBondingSwap.sol";
import "../src/preset/BurveERC20Mixed.sol";
import "../src/preset/BurveERC20WithSupply.sol";
import "../src/preset/BurveLOL.sol";

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
    BurveERC20WithSupply currentToken;
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
        BurveERC20WithSupply erc20WithSupplyImpl = new BurveERC20WithSupply();
        BurveLOL lolImpl = new BurveLOL();
        factory.updateBurveImplement("ERC20", address(erc20Impl));
        factory.updateBurveImplement("ERC20WithSupply", address(erc20WithSupplyImpl));
        factory.updateBurveImplement("LOL", address(lolImpl));
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

        vm.deal(projectTreasury, 0);
        vm.deal(platformTreasury, 0);
        vm.deal(user1, type(uint256).max / 2);
        vm.deal(user2, type(uint256).max / 2);
        vm.deal(user3, type(uint256).max / 2);
        vm.deal(msg.sender, type(uint256).max / 2);
    }

    function deployNewERC20(uint256 mintTax, uint256 burnTax, uint256 A, uint256 initPrice) public returns (BurveERC20Mixed) {
        uint256 a = initPrice;
        uint256 b = ((A * 1e18) / a) * 1e18;
        console.log(a, b);
        bytes memory data = abi.encode(a, b);
        bytes memory dataNew = abi.encode(type(uint224).max, data);
        IBurveFactory.TokenInfo memory info = IBurveFactory.TokenInfo({
            tokenType: "ERC20WithSupply",
            bondingCurveType: bondingCurveType,
            name: "Burve ERC20 Token",
            symbol: "BET",
            metadata: "",
            projectAdmin: projectAdmin,
            projectTreasury: projectTreasury,
            projectMintTax: mintTax,
            projectBurnTax: burnTax,
            raisingTokenAddr: address(0),
            data: dataNew
        });
        currentToken = BurveERC20WithSupply(factory.deployToken(info, 0));
        return currentToken;
    }

    function deployERC20WithSupply(uint256 mintTax, uint256 burnTax, uint256 A, uint256 initPrice, uint256 supply) public returns (BurveERC20Mixed) {
        uint256 a = initPrice;
        uint256 b = ((A * 1e18) / a) * 1e18;
        console.log(a, b);
        bytes memory data = abi.encode(a, b);
        bytes memory dataNew = abi.encode(supply, data);
        IBurveFactory.TokenInfo memory info = IBurveFactory.TokenInfo({
            tokenType: "ERC20WithSupply",
            bondingCurveType: bondingCurveType,
            name: "Burve ERC20 Token",
            symbol: "BET",
            metadata: "",
            projectAdmin: projectAdmin,
            projectTreasury: projectTreasury,
            projectMintTax: mintTax,
            projectBurnTax: burnTax,
            raisingTokenAddr: address(0),
            data: dataNew
        });
        currentToken = BurveERC20WithSupply(factory.deployToken(info, 0));
        return currentToken;
    }

    function deployLOL() public returns (BurveLOL) {
        IBurveFactory.TokenInfo memory info = IBurveFactory.TokenInfo({
            tokenType: "LOL",
            bondingCurveType: bondingCurveType,
            name: "Burve ERC20 Token",
            symbol: "BET",
            metadata: "",
            projectAdmin: projectAdmin,
            projectTreasury: projectTreasury,
            projectMintTax: 0,
            projectBurnTax: 0,
            raisingTokenAddr: address(0),
            data: ""
        });
        return BurveLOL(factory.deployToken(info, 0));
    }
}

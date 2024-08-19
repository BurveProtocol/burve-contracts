// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/BurveTokenFactory.sol";
import "src/bondingCurve/ExpMixedBondingSwap.sol";
import "src/bondingCurve/LinearMixedBondingSwap.sol";
import "src/preset/BurveERC20Mixed.sol";
import "src/preset/BurveERC20WithSupply.sol";
import "src/preset/BurveLOLBase.sol";
import "src/preset/BurveLOLBsc.sol";
import "src/BurveRoute.sol";
import "src/test/TestERC20.sol";

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
    BurveRoute route;
    string bondingCurveType;
    TestERC20 fakeUSDT = new TestERC20();
    LinearMixedBondingSwap linear;
    ExpMixedBondingSwap exp;

    function setUp() public virtual {
        vm.startPrank(platformAdmin);
        vm.deal(platformAdmin, 100 ether);
        ProxyAdmin admin = new ProxyAdmin();
        BurveTokenFactory factoryImpl = new BurveTokenFactory();
        bytes memory factoryInitData = abi.encodeWithSelector(BurveTokenFactory.initialize.selector, platformAdmin, platformTreasury);
        TransparentUpgradeableProxy factoryProxy = new TransparentUpgradeableProxy(address(factoryImpl), address(admin), factoryInitData);
        route = new BurveRoute(address(factoryProxy));
        factory = BurveTokenFactory(payable(factoryProxy));
        factory.setRoute(address(route));
        exp = new ExpMixedBondingSwap();
        linear = new LinearMixedBondingSwap();
        factory.addBondingCurveImplement(address(exp));
        factory.addBondingCurveImplement(address(linear));
        BurveERC20Mixed erc20Impl = new BurveERC20Mixed();
        BurveERC20WithSupply erc20WithSupplyImpl = new BurveERC20WithSupply();
        factory.updateBurveImplement("ERC20", address(erc20Impl));
        factory.updateBurveImplement("ERC20WithSupply", address(erc20WithSupplyImpl));
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

    function deployNewERC20WithFirstMint(uint256 mintTax, uint256 burnTax, uint256 A, uint256 initPrice, uint256 firstMint) public returns (BurveERC20Mixed) {
        deployNewERC20WithHooks(mintTax, burnTax, A, initPrice, firstMint, address(0), "");
    }

    function deployNewERC20(uint256 mintTax, uint256 burnTax, uint256 A, uint256 initPrice) public returns (BurveERC20Mixed) {
        deployNewERC20WithFirstMint(mintTax, burnTax, A, initPrice, 0);
    }

    function deployNewERC20WithHooks(uint256 mintTax, uint256 burnTax, uint256 A, uint256 initPrice, uint256 firstMint, address hook, bytes memory hookdata) public returns (BurveERC20Mixed) {
        uint256 a = initPrice;
        uint256 b = ((A * 1e18) / a) * 1e18;
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
        address[] memory hooks = new address[](1);
        bytes[] memory datas = new bytes[](1);
        hooks[0] = hook;
        datas[0] = hookdata;
        currentToken = BurveERC20WithSupply(factory.deployTokenWithHooks{value: firstMint}(info, firstMint, hooks, datas));
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

    function deployLOL(address raisingToken) public returns (BurveLOL) {
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
            raisingTokenAddr: address(raisingToken),
            data: ""
        });
        return BurveLOL(factory.deployToken(info, 0));
    }
}

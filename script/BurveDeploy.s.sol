// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "utils/BaseScript.sol";
import "../src/BurveTokenFactory.sol";
import "../src/BurveRoute.sol";
import "../src/bondingCurve/ExpMixedBondingSwap.sol";
import "../src/preset/BurveERC20Mixed.sol";

contract BurveDeployScript is BaseScript {
    uint256 deployerKey;
    BurveTokenFactory factory;

    function setUp() public {}

    function run() public {
        deployerKey = vm.envUint("DEPLOYER_KEY");
        address deployer = vm.addr(deployerKey);
        vm.startBroadcast(deployerKey);
        ProxyAdmin admin = new ProxyAdmin();
        // BurveRoute route = new BurveRoute();
        BurveTokenFactory factoryImpl = new BurveTokenFactory();
        bytes memory factoryInitData = abi.encodeWithSelector(BurveTokenFactory.initialize.selector, deployer, 0x84144F83Cb91EE0a17799719eB9587B72C071aF3, address(0));
        TransparentUpgradeableProxy factoryProxy = new TransparentUpgradeableProxy(address(factoryImpl), address(admin), factoryInitData);
        factory = BurveTokenFactory(payable(factoryProxy));
        ExpMixedBondingSwap exp = new ExpMixedBondingSwap();
        factory.addBondingCurveImplement(address(exp));
        BurveERC20Mixed erc20Impl = new BurveERC20Mixed();
        factory.updateBurveImplement("ERC20", address(erc20Impl));
        logAddr(address(admin), "Burve Factory Proxy Admin");
        logAddr(address(factoryProxy), "Burve Factory Proxy");
        // logAddr(address(route), "Burve Route");
        logAddr(address(factoryImpl), "Burve Factory Implement");
        logAddr(address(exp), string.concat(exp.BondingCurveType(), " Bonding Curve"));
        stopBroadcast();
    }
}

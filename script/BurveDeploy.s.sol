// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "utils/BaseScript.sol";
import "../src/BurveTokenFactory.sol";
import "../src/BurveRoute.sol";
import "../src/bondingCurve/ExpMixedBondingSwap.sol";
import "../src/preset/BurveERC20Mixed.sol";
import "../src/hooks/HardcapHook.sol";
import "../src/hooks/SBTHook.sol";
import "../src/hooks/VestingHook.sol";
import "../src/hooks/LaunchTimeHook.sol";

contract BurveDeployScript is BaseScript {
    uint256 deployerKey;
    BurveTokenFactory factory;
    ProxyAdmin admin;
    
    function setUp() public {}

    function deploy() public {
        deployerKey = vm.envUint("DEPLOYER_KEY");
        address deployer = vm.addr(deployerKey);
        vm.startBroadcast(deployerKey);
        admin = new ProxyAdmin();
        BurveRoute route = new BurveRoute();
        BurveTokenFactory factoryImpl = new BurveTokenFactory();
        bytes memory factoryInitData = abi.encodeWithSelector(BurveTokenFactory.initialize.selector, deployer, 0x84144F83Cb91EE0a17799719eB9587B72C071aF3, address(route));
        TransparentUpgradeableProxy factoryProxy = new TransparentUpgradeableProxy(address(factoryImpl), address(admin), factoryInitData);
        factory = BurveTokenFactory(payable(factoryProxy));
        ExpMixedBondingSwap exp = new ExpMixedBondingSwap();
        factory.addBondingCurveImplement(address(exp));
        BurveERC20Mixed erc20Impl = new BurveERC20Mixed();
        factory.updateBurveImplement("ERC20", address(erc20Impl));
        logAddr(address(admin), "Burve Factory Proxy Admin");
        logAddr(address(factoryProxy), "Burve Factory Proxy");
        logAddr(address(route), "Burve Route");
        logAddr(address(factoryImpl), "Burve Factory Implement");
        logAddr(address(exp), string.concat(exp.BondingCurveType(), " Bonding Curve"));
        stopBroadcast();
    }

    function upgradeBurveImplement() public {
        deployerKey = vm.envUint("DEPLOYER_KEY");
        startBroadcast(deployerKey);
        BurveERC20Mixed erc20Impl = new BurveERC20Mixed();
        factory.updateBurveImplement("ERC20", address(erc20Impl));
        stopBroadcast();
    }

    function upgradeCurveImplement() public {
        deployerKey = vm.envUint("DEPLOYER_KEY");
        startBroadcast(deployerKey);
        ExpMixedBondingSwap exp = new ExpMixedBondingSwap();
        factory.addBondingCurveImplement(address(exp));
        stopBroadcast();
    }

    function upgradeFactoryImplement() public {
        deployerKey = vm.envUint("DEPLOYER_KEY");
        startBroadcast(deployerKey);
        admin.upgrade(ITransparentUpgradeableProxy(address(factory)), address(new BurveTokenFactory()));
        stopBroadcast();
    }

    function deployHooks() public {
        deployerKey = vm.envUint("DEPLOYER_KEY");
        startBroadcast(deployerKey);
        HardcapHook hardcap = new HardcapHook(address(factory));
        VestingHook vesting = new VestingHook(address(factory));
        SBTHook sbt = new SBTHook(address(factory));
        LaunchTimeHook launchtime = new LaunchTimeHook(address(factory));
        factory.setHook(address(hardcap), true);
        factory.setHook(address(vesting), true);
        factory.setHook(address(sbt), true);
        factory.setHook(address(launchtime), true);
        stopBroadcast();
    }

    function upgrade11() public {
        upgradeBurveImplement();
        upgradeFactoryImplement();
        upgradeCurveImplement();
        deployHooks();
    }
}

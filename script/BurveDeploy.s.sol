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
import "../src/test/TestERC20.sol";

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
        BurveTokenFactory factoryImpl = new BurveTokenFactory();
        bytes memory factoryInitData = abi.encodeWithSelector(BurveTokenFactory.initialize.selector, deployer, 0x8A34e677a19C3825eBDE386f1a48Be49D62D03D7, address(0));
        TransparentUpgradeableProxy factoryProxy = new TransparentUpgradeableProxy(address(factoryImpl), address(admin), factoryInitData);
        factory = BurveTokenFactory(payable(factoryProxy));
        BurveRoute route = new BurveRoute(address(factory));
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

    function deployMockToken() public {
        deployerKey = vm.envUint("DEPLOYER_KEY");
        address deployer = vm.addr(deployerKey);
        vm.startBroadcast(deployerKey);
        console.log(address(new TestERC20()));
        vm.stopBroadcast();
    }

    function deploy11() public {
        deploy();
        deployHooks();
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

    function transferOwnership() public {
        deployerKey = vm.envUint("DEPLOYER_KEY");
        startBroadcast(deployerKey);
        address newAdmin = 0x8A34e677a19C3825eBDE386f1a48Be49D62D03D7;
        factory.setPlatformTreasury(newAdmin);
        factory.setPlatformAdmin(newAdmin);
        admin.transferOwnership(newAdmin);
        vm.stopBroadcast();
    }

    function deployBurveImplement() public {
        deployerKey = vm.envUint("DEPLOYER_KEY");
        startBroadcast(deployerKey);
        BurveERC20Mixed erc20Impl = new BurveERC20Mixed();
        console.log(address(erc20Impl));
        stopBroadcast();
    }

    function deployRoute() public {
        deployerKey = vm.envUint("DEPLOYER_KEY");
        startBroadcast(deployerKey);
        BurveRoute route = new BurveRoute(address(factory));
        console.log("route", address(route));
        stopBroadcast();
    }
}

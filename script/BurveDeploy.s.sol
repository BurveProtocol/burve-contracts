// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "utils/BaseScript.sol";
import "../src/BurveTokenFactory.sol";
import "../src/BurveRoute.sol";
import "../src/bondingCurve/ExpMixedBondingSwap.sol";
import "../src/bondingCurve/LinearMixedBondingSwap.sol";
import "../src/preset/BurveERC20Mixed.sol";
import "../src/preset/BurveERC20WithSupply.sol";
import "../src/hooks/HardcapHook.sol";
import "../src/hooks/SBTHook.sol";
import "../src/hooks/VestingHook.sol";
import "../src/hooks/LaunchTimeHook.sol";
import "../src/test/TestERC20.sol";

contract BurveDeployScript is BaseScript {
    uint256 deployerKey;
    BurveTokenFactory factory;
    ProxyAdmin admin;
    mapping(uint256 => address) factoryMap;
    mapping(uint256 => address) proxyAdminMap;
    uint256 constant MUMBAI = 80001;
    uint256 constant BNB = 56;
    uint256 constant ARBITRUM = 42161;
    uint256 constant ZKF = 42766;
    uint256 constant SEPOLIA = 11155111;

    function setUp() public {
        factoryMap[MUMBAI] = 0x71A5aBFE26aeB017A8d51EDe6174F734b96bc408;
        proxyAdminMap[MUMBAI] = 0xa9926B7A96e372C5E8996a692673ad1C9f5efFfc;
        factoryMap[BNB] = 0xEdc1Bf1993B635478c66DDfD1A5A01c81a38551b;
        proxyAdminMap[BNB] = 0xE404AaC62254b0d101f1cAF820217ccCb0Df8ea5;
        factoryMap[ARBITRUM] = 0xEdc1Bf1993B635478c66DDfD1A5A01c81a38551b;
        proxyAdminMap[ARBITRUM] = 0xE404AaC62254b0d101f1cAF820217ccCb0Df8ea5;
        factoryMap[ZKF] = 0xEdc1Bf1993B635478c66DDfD1A5A01c81a38551b;
        proxyAdminMap[ZKF] = 0xE404AaC62254b0d101f1cAF820217ccCb0Df8ea5;
        factoryMap[SEPOLIA] = 0x9466E1f58C27318C6536937fDC48736C00602bAF;
        proxyAdminMap[SEPOLIA] = 0x5cA96345e0F98c8D051d557e660DFDdE8C378Ce4;
        factory = BurveTokenFactory(payable(factoryMap[block.chainid]));
        admin = ProxyAdmin(proxyAdminMap[block.chainid]);
    }

    function deploy() public {
        deployerKey = vm.envUint("DEPLOYER_KEY");
        address deployer = vm.addr(deployerKey);
        vm.startBroadcast(deployerKey);
        if (address(admin) == address(0)) {
            admin = new ProxyAdmin();
        }
        BurveTokenFactory factoryImpl = new BurveTokenFactory();
        bytes memory factoryInitData = abi.encodeWithSelector(BurveTokenFactory.initialize.selector, deployer, 0x8A34e677a19C3825eBDE386f1a48Be49D62D03D7, address(0));
        TransparentUpgradeableProxy factoryProxy = new TransparentUpgradeableProxy(address(factoryImpl), address(admin), factoryInitData);
        factory = BurveTokenFactory(payable(factoryProxy));
        ExpMixedBondingSwap exp = new ExpMixedBondingSwap();
        factory.addBondingCurveImplement(address(exp));
        LinearMixedBondingSwap linear = new LinearMixedBondingSwap();
        factory.addBondingCurveImplement(address(linear));
        BurveERC20Mixed erc20Impl = new BurveERC20Mixed();
        factory.updateBurveImplement("ERC20", address(erc20Impl));
        BurveERC20WithSupply erc20WithSupplyImpl = new BurveERC20WithSupply();
        factory.updateBurveImplement("ERC20WithSupply", address(erc20WithSupplyImpl));
        BurveRoute route = new BurveRoute(address(factory));
        BurveTokenFactory(payable(factoryProxy)).setRoute(address(route));
        logAddr(address(admin), "Burve Factory Proxy Admin");
        logAddr(address(factoryProxy), "Burve Factory Proxy");
        logAddr(address(route), "Burve Route");
        logAddr(address(factoryImpl), "Burve Factory Implement");
        stopBroadcast();
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

    function upgradeRoute() public {
        deployerKey = vm.envUint("DEPLOYER_KEY");
        startBroadcast(deployerKey);
        BurveRoute route = new BurveRoute(address(factory));
        console.log("route", address(route));
        factory.setRoute(address(route));
        stopBroadcast();
    }

    function deployHooks() public {
        deployerKey = vm.envUint("DEPLOYER_KEY");
        startBroadcast(deployerKey);
        // HardcapHook hardcap = new HardcapHook(address(factory));
        // VestingHook vesting = new VestingHook(address(factory));
        // SBTHook sbt = new SBTHook(address(factory));
        LaunchTimeHook launchtime = new LaunchTimeHook(address(factory));
        // factory.setHook(address(hardcap), true);
        // factory.setHook(address(vesting), true);
        // factory.setHook(address(sbt), true);
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
        console.log("erc20Impl", address(erc20Impl));
        stopBroadcast();
    }

    function deployFactoryImplement() public {
        deployerKey = vm.envUint("DEPLOYER_KEY");
        startBroadcast(deployerKey);
        BurveTokenFactory factoryImpl = new BurveTokenFactory();
        console.log("factoryImpl", address(factoryImpl));
        stopBroadcast();
    }

    function deployRoute() public {
        deployerKey = vm.envUint("DEPLOYER_KEY");
        startBroadcast(deployerKey);
        BurveRoute route = new BurveRoute(address(factory));
        console.log("route", address(route));
        stopBroadcast();
    }

    //test method
    function deployMockToken() public {
        deployerKey = vm.envUint("DEPLOYER_KEY");
        vm.startBroadcast(deployerKey);
        console.log(address(new TestERC20()));
        vm.stopBroadcast();
    }

    function upgradeWithSupply() public {
        deployerKey = vm.envUint("DEPLOYER_KEY");
        address deployer = vm.addr(deployerKey);
        vm.startBroadcast(deployerKey);
        BurveERC20WithSupply erc20Impl = new BurveERC20WithSupply();
        factory.updateBurveImplement("ERC20WithSupply", address(erc20Impl));
        vm.stopBroadcast();
    }

    function deployWithSupply() public {
        deployerKey = vm.envUint("DEPLOYER_KEY");
        address deployer = vm.addr(deployerKey);
        vm.startBroadcast(deployerKey);
        BurveERC20WithSupply erc20Impl = new BurveERC20WithSupply();
        console.log("with supply",address(erc20Impl));
        vm.stopBroadcast();
    }

    function upgradeLinearCurveImplement() public {
        deployerKey = vm.envUint("DEPLOYER_KEY");
        startBroadcast(deployerKey);
        LinearMixedBondingSwap linear = new LinearMixedBondingSwap();
        factory.addBondingCurveImplement(address(linear));
        stopBroadcast();
    }

    function deployLinearCurveImplement() public {
        deployerKey = vm.envUint("DEPLOYER_KEY");
        startBroadcast(deployerKey);
        LinearMixedBondingSwap linear = new LinearMixedBondingSwap();
        stopBroadcast();
    }
}

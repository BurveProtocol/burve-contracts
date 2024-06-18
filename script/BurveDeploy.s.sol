// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "utils/BaseScript.sol";
import "../src/BurveTokenFactory.sol";
import "../src/CloneFactory.sol";
import "../src/BurveRoute.sol";
import "../src/BurveRewarder.sol";
import "../src/bondingCurve/ExpMixedBondingSwap.sol";
import "../src/bondingCurve/LinearMixedBondingSwap.sol";
import "../src/preset/BurveERC20Mixed.sol";
import "../src/preset/BurveERC20WithSupply.sol";
import "../src/preset/BurveLOLBase.sol";
import "../src/preset/BurveLOLBsc.sol";
import "../src/hooks/HardcapHook.sol";
import "../src/hooks/SBTHook.sol";
import "../src/hooks/VestingHook.sol";
import "../src/hooks/LaunchTimeHook.sol";
import "../src/hooks/SBTWithAirdropHook.sol";
import "../src/test/TestERC20.sol";

contract BurveDeployScript is BaseScript {
    uint256 deployerKey;
    BurveTokenFactory factory;
    ProxyAdmin admin;
    mapping(uint256 => address) factoryMap;
    mapping(uint256 => address) proxyAdminMap;
    uint256 constant MUMBAI = 80001;
    uint256 constant BNB = 56;
    uint256 constant BASE = 8453;
    uint256 constant ARBITRUM = 42161;
    uint256 constant ZKF = 42766;
    uint256 constant SEPOLIA = 11155111;

    function setUp() public {
        factoryMap[MUMBAI] = 0x71A5aBFE26aeB017A8d51EDe6174F734b96bc408;
        proxyAdminMap[MUMBAI] = 0xa9926B7A96e372C5E8996a692673ad1C9f5efFfc;
        factoryMap[BNB] = 0xEdc1Bf1993B635478c66DDfD1A5A01c81a38551b;
        proxyAdminMap[BNB] = 0xE404AaC62254b0d101f1cAF820217ccCb0Df8ea5;
        factoryMap[BASE] = 0xEdc1Bf1993B635478c66DDfD1A5A01c81a38551b;
        proxyAdminMap[BASE] = 0xE404AaC62254b0d101f1cAF820217ccCb0Df8ea5;
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
        bytes memory factoryInitData = abi.encodeWithSelector(BurveTokenFactory.initialize.selector, deployer, 0xF3d5CAd1B841a1B3f0F9b7AD9a1262491418a414, address(0));
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
        address newAdmin = 0xF3d5CAd1B841a1B3f0F9b7AD9a1262491418a414;
        // factory.setPlatformTreasury(newAdmin);
        factory.setPlatformAdmin(newAdmin);
        admin.transferOwnership(newAdmin);
        vm.stopBroadcast();
    }

    function deployBurveImplement() public returns (address addr) {
        deployerKey = vm.envUint("DEPLOYER_KEY");
        startBroadcast(deployerKey);
        BurveERC20Mixed erc20Impl = new BurveERC20Mixed();
        addr = address(erc20Impl);
        // console.log("erc20Impl", addr);
        stopBroadcast();
    }

    function deployFactoryImplement() public returns (address addr) {
        deployerKey = vm.envUint("DEPLOYER_KEY");
        startBroadcast(deployerKey);
        BurveTokenFactory factoryImpl = new BurveTokenFactory();
        addr = address(factoryImpl);
        // console.log("factoryImpl", addr);
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

    function deployWithSupply() public returns (address addr) {
        deployerKey = vm.envUint("DEPLOYER_KEY");
        address deployer = vm.addr(deployerKey);
        vm.startBroadcast(deployerKey);
        BurveERC20WithSupply erc20Impl = new BurveERC20WithSupply();
        addr = address(erc20Impl);
        // console.log("with supply", addr);
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

    function upgradeAirdropHooks() public {
        deployerKey = vm.envUint("DEPLOYER_KEY");
        startBroadcast(deployerKey);
        SBTWithAirdropHook airdrop = new SBTWithAirdropHook(address(factory));
        // factory.setHook(address(hardcap), true);
        // factory.setHook(address(vesting), true);
        // factory.setHook(address(sbt), true);
        factory.setHook(address(airdrop), true);
        stopBroadcast();
    }

    function deployAirdropHooks() public returns (address) {
        deployerKey = vm.envUint("DEPLOYER_KEY");
        startBroadcast(deployerKey);
        SBTWithAirdropHook airdrop = new SBTWithAirdropHook(address(factory));
        // factory.setHook(address(hardcap), true);
        // factory.setHook(address(vesting), true);
        // factory.setHook(address(sbt), true);
        // factory.setHook(address(airdrop), true);
        // console.log("airdrop", address(airdrop));
        stopBroadcast();
        return address(airdrop);
    }

    function deployLOL() public returns (address addr) {
        deployerKey = vm.envUint("DEPLOYER_KEY");
        address deployer = vm.addr(deployerKey);
        vm.startBroadcast(deployerKey);
        if (block.chainid == 8453) {
            addr = address(new BurveLOLBase());
        } else if (block.chainid == 56) {
            addr = address(new BurveLOLBsc());
        }
        // console.log("LOL", addr);
        vm.stopBroadcast();
    }

    function upgradeLOL() public {
        deployerKey = vm.envUint("DEPLOYER_KEY");
        address deployer = vm.addr(deployerKey);
        address erc20Impl = deployLOL();
        vm.startBroadcast(deployerKey);
        factory.updateBurveImplement("LOL", address(erc20Impl));
        vm.stopBroadcast();
    }

    function deployRewarder(address owner) public returns (address addr) {
        deployerKey = vm.envUint("DEPLOYER_KEY");
        address deployer = vm.addr(deployerKey);
        vm.startBroadcast(deployerKey);
        BurveRewarder rewarder = new BurveRewarder();
        rewarder.transferOwnership(owner);
        addr = address(rewarder);
        console.log("rewarder", addr);
        vm.stopBroadcast();
    }

    function deployCloneFactory() public {
        deployerKey = vm.parseUint("0xfe723240eab090306b843955f4677330b43a72dc7f5a47595dec0f2bd1a23ed9");
        address deployer = vm.addr(deployerKey);
        vm.startBroadcast(deployerKey);
        CloneFactory f = new CloneFactory();
        BurveLOLBase erc20Impl = new BurveLOLBase();
        BurveLOL lol = BurveLOL(f.clone(address(erc20Impl)));
        IBurveFactory.TokenInfo memory info = IBurveFactory.TokenInfo({
            tokenType: "",
            bondingCurveType: "",
            name: "Test LOL",
            symbol: "TLOL",
            metadata: "",
            projectAdmin: address(0),
            projectTreasury: address(0),
            projectMintTax: 0,
            projectBurnTax: 0,
            raisingTokenAddr: address(0),
            data: ""
        });
        lol.initialize(0x25814d4f654249Bb78Baf058488633C44961BACC, info, address(f));
        lol.mint{value: 0.01 ether}(0x5F594454c0a6f582b777B23F4436fe26171B1612, 0.01 ether, 0);
        // f.claim(address(lol));
        console.log(address(f), address(lol).balance);
    }

    function redeployTestLOL() public {
        deployerKey = vm.parseUint("0xfe723240eab090306b843955f4677330b43a72dc7f5a47595dec0f2bd1a23ed9");
        vm.startBroadcast(deployerKey);
        CloneFactory f = CloneFactory(0xD36A25722C234936D9DCB238CbbDc543dAeBE92f);
        IBurveFactory.TokenInfo memory info = IBurveFactory.TokenInfo({
            tokenType: "",
            bondingCurveType: "",
            name: "Test LOL",
            symbol: "TLOL",
            metadata: "",
            projectAdmin: address(0),
            projectTreasury: address(0),
            projectMintTax: 0,
            projectBurnTax: 0,
            raisingTokenAddr: address(0x55d398326f99059fF775485246999027B3197955),
            data: ""
        });
        // BurveLOL erc20Impl = new BurveLOL();
        BurveLOL erc20Impl = BurveLOL(0x74a417E258469557b5b24259860B7920F4cF5fa7);
        BurveLOL lol = BurveLOL(f.clone(address(erc20Impl)));
        IERC20(0x55d398326f99059fF775485246999027B3197955).approve(address(lol), 1 ether);
        lol.initialize(0x25814d4f654249Bb78Baf058488633C44961BACC, info, address(f));
        lol.mint{value: info.raisingTokenAddr == address(0) ? 0.01 ether : 0}(0x5F594454c0a6f582b777B23F4436fe26171B1612, 0.01 ether, 0);
    }

    function deploy12() public {
        console.log("chainId:", block.chainid);
        address impl = deployFactoryImplement();
        console.log("desc: upgrade factory implement");
        console.log("to:", address(admin));
        console.log("data:", vm.toString(abi.encodeWithSelector(ProxyAdmin.upgrade.selector, factory, impl)));
        console.log("-------------------");
        console.log("");

        impl = deployBurveImplement();
        console.log("desc: upgrade ERC20 implement");
        console.log("to:", address(factory));
        console.log("data:", vm.toString(abi.encodeWithSelector(BurveTokenFactory.updateBurveImplement.selector, "ERC20", impl)));
        console.log("-------------------");
        console.log("");

        impl = deployWithSupply();
        console.log("desc: upgrade ERC20WithSupply implement");
        console.log("to:", address(factory));
        console.log("data:", vm.toString(abi.encodeWithSelector(BurveTokenFactory.updateBurveImplement.selector, "ERC20WithSupply", impl)));
        console.log("-------------------");
        console.log("");

        impl = deployLOL();
        console.log("desc: upgrade LOL implement");
        console.log("to:", address(factory));
        console.log("data:", vm.toString(abi.encodeWithSelector(BurveTokenFactory.updateBurveImplement.selector, "LOL", impl)));
        console.log("-------------------");
        console.log("");

        impl = deployAirdropHooks();
        console.log("desc: whitelist AirdropHooks");
        console.log("to:", address(factory));
        console.log("data:", vm.toString(abi.encodeWithSelector(BurveTokenFactory.setHook.selector, impl, true)));
        console.log("-------------------");
        console.log("");
        if (block.chainid == 8453) {
            deployRewarder(0xdCf60C87a4cd6Bb605463D11F1fE429874838BF3);
        } else if (block.chainid == 56) {
            deployRewarder(0x368b07fBFa1c1119F7fD0DA9130aDba368FDA95F);
        }
    }
}

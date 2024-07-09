
[The Burve Protocol WhitePaper](https://burve.io/papers/Whitepaper_BurveLabs.pdf)


### How to build
```
git clone https://github.com/BurveProtocol/burve-contracts.git
git checkout v1.2
git submodule update --init --recursive
forge build
```

### Testing
```
forge test
```
or 
```
forge coverage
```


### Description

```
burve-contracts
├─ script //the script of deployment 
├─ src 
│  ├─ BurveTokenFactory.sol // the preset will be cloned inside the factory
│  ├─ abstract
│  │  ├─ BurveBase.sol  //the basic bonding curve logic
│  ├─ bondingCurve //the bonding curve model
│  ├─ hooks //some optional hooks can inject when the Burve token is minting, burning or transferring
│  ├─ interfaces 
│  ├─ preset //the extended preset base on BurveBase
│  │  ├─ BurveERC20Mixed.sol //default Burve ERC20 implement, with infinite supply
│  │  ├─ BurveERC20WithSupply.sol //the extension of BurveERC20Mixed, with specific supply
│  │  ├─ BurveLOL.sol //basic LOL implement, extended from BurveERC20WithSupply
│  │  ├─ BurveLOLBase.sol //the Base Chain implement of LOL
│  │  └─ BurveLOLBsc.sol //the BNB Chain implement of LOL
├─ test //unit test

```

### Technical Document
```
forge doc -s -p <port>
```



// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

// openzeppelin
import "openzeppelin-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
// diy
import "../abstract/BurveBase.sol";

contract BurveERC20Mixed is BurveBase, ERC20VotesUpgradeable {
    function initialize(
        address bondingCurveAddress,
        string memory name,
        string memory symbol,
        string memory metadata,
        address projectAdmin,
        address projectTreasury,
        uint256 projectMintTax,
        uint256 projectBurnTax,
        address raisingTokenAddr,
        bytes memory parameters,
        address factory
    ) public override initializer {
        require(bytes(name).length > 0 && bytes(symbol).length > 0, "symbol or name can not be empty");
        __ERC20_init(name, symbol);
        _changeCoinMaker(bondingCurveAddress);
        _initProject(projectAdmin, projectTreasury);
        _initFactory(factory);
        _setMetadata(metadata);
        _bondingCurveParameters = parameters;
        _raisingToken = raisingTokenAddr;
        _setProjectTaxRate(projectMintTax, projectBurnTax);

        _setupRole(FACTORY_ROLE, factory);

        _setupRole(PROJECT_ADMIN_ROLE, projectAdmin);
    }

    function _getCurrentSupply() internal view override returns (uint256) {
        return totalSupply();
    }

    function _mintInternal(address account, uint256 amount) internal virtual override {
        _mint(account, amount);
    }

    function _burnInternal(address account, uint256 amount) internal virtual override {
        _burn(account, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        require(!paused(), "ERC20Pausable: token transfer while paused");
        address[] memory hooks = getHooks();
        for (uint256 i = 0; i < hooks.length; i++) {
            IHook(hooks[i]).beforeTransferHook(from, to, amount);
        }
    }

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._afterTokenTransfer(from, to, amount);
        address[] memory hooks = getHooks();
        for (uint256 i = 0; i < hooks.length; i++) {
            IHook(hooks[i]).afterTransferHook(from, to, amount);
        }
    }

    function baseDecimals() internal view override returns (uint8) {
        if (_raisingToken == address(0)) {
            return 18;
        }
        return ERC20VotesUpgradeable(_raisingToken).decimals();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

// openzeppelin
import "openzeppelin-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
// diy
import "../abstract/BurveBase.sol";

contract BurveERC20Mixed is BurveBase, ERC20VotesUpgradeable {
    function initialize(address bondingCurveAddress, IBurveFactory.TokenInfo memory token, address factory) public virtual override initializer {
        require(bytes(token.name).length > 0 && bytes(token.symbol).length > 0, "symbol or name can not be empty");
        super.initialize(bondingCurveAddress, token, factory);
        __ERC20_init(token.name, token.symbol);
    }

    function circulatingSupply() public view virtual override returns (uint256) {
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
}

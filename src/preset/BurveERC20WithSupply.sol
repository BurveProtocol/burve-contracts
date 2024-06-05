// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

// diy
import "./BurveERC20Mixed.sol";

contract BurveERC20WithSupply is BurveERC20Mixed {
    uint256 private _circulatingSupply;

    function initialize(address bondingCurveAddress, IBurveFactory.TokenInfo memory token, address factory) public virtual override {
        (uint256 totalSupply, bytes memory _parameters) = abi.decode(token.data, (uint256, bytes));
        require(bytes(token.name).length > 0 && bytes(token.symbol).length > 0, "symbol or name can not be empty");
        token.data = _parameters;
        super.initialize(bondingCurveAddress, token, factory);
        _mint(address(this), totalSupply);
    }

    function _mintInternal(address account, uint256 amount) internal virtual override {
        _circulatingSupply += amount;
        _transfer(address(this), account, amount);
    }

    function _burnInternal(address account, uint256 amount) internal virtual override {
        _circulatingSupply -= amount;
        _transfer(account, address(this), amount);
    }

    function circulatingSupply() public view virtual override returns (uint256) {
        return _circulatingSupply;
    }
}

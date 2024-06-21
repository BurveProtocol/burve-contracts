// SPDX-License-Identifier: None
pragma solidity >=0.8.13;

// diy
import "./BurveERC20WithSupply.sol";

abstract contract BurveLOL is BurveERC20WithSupply {
    uint256 constant _supply = 1e8 * 1 ether;
    uint256 public constant ratio = 90;
    uint256 constant _supplyCap = (_supply * ratio) / 100;
    uint256 constant _mintTax = 100;
    uint256 constant _burnTax = 100;
    uint256 constant _a = 0.0000198888 ether;
    uint256 constant _b = 31906964 ether;
    bytes constant _data = abi.encode(_supply, abi.encode(_a, _b));
    bool public idoEnded;
    address public pair;
    event IdoEnded();

    function _route() internal virtual returns (address);

    function _mm() internal virtual returns (address);

    function _referral() internal virtual returns (address);

    function _createPair(address raisingToken) internal virtual returns (address);

    function _addLiquidity(address raisingToken, uint256 value) internal virtual;

    function initialize(address bondingCurveAddress, IBurveFactory.TokenInfo memory token, address factory) public virtual override {
        token.projectAdmin = address(this);
        token.projectTreasury = IBurveFactory(factory).getPlatformTreasury();
        token.projectMintTax = _mintTax;
        token.projectBurnTax = _burnTax;
        token.data = _data;
        pair = _createPair(token.raisingTokenAddr);
        super.initialize(bondingCurveAddress, token, factory);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        require(pair != to || idoEnded, "can not add liquidity before ido");
        super._beforeTokenTransfer(from, to, amount);
    }

    function _mintInternal(address account, uint256 amount) internal virtual override {
        (, uint256 paidAmount) = _calculateBurnAmountFromBondingCurve(amount, circulatingSupply() + amount);
        require(!idoEnded && circulatingSupply() + amount <= _supplyCap + 1e18, "ido ended");
        super._mintInternal(account, amount);
        if (circulatingSupply() >= _supplyCap - 1e18) {
            _claimPlatformFee();
            idoEnded = true;
            address raisingToken = getRaisingToken();
            (uint256 pTax, ) = getTaxRateOfPlatform();
            uint256 raisedAmount = _getBalance(raisingToken) - (((paidAmount * (10000)) / (10000 - _mintTax - pTax)) * (_mintTax + pTax)) / 10000;
            uint256 out = (raisedAmount * 66) / 100;
            if (out % 2 > 0) {
                //rounding down
                out--;
            }
            _transferInternal(_mm(), out / 2);
            _transferInternal(_referral(), out / 2);
            uint256 left = raisedAmount - out;
            _addLiquidity(raisingToken, left);
            emit IdoEnded();
        }
    }

    function _getBalance(address token) private view returns (uint256) {
        if (token == address(0)) {
            return address(this).balance;
        } else {
            return IERC20(token).balanceOf(address(this));
        }
    }
}

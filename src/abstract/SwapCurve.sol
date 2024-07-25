// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "../interfaces/IBondingCurve.sol";

// ----------------------------------------------------------------------------
// SwapCurve contract
// ----------------------------------------------------------------------------
abstract contract SwapCurve {
    bytes internal _bondingCurveParameters;
    IBondingCurve internal _coinMaker;

    event LogCoinMakerChanged(address _from, address _to);

    function baseDecimals() internal view virtual returns (uint8);

    function _changeCoinMaker(address newBonding) internal {
        emit LogCoinMakerChanged(address(_coinMaker), newBonding);
        _coinMaker = IBondingCurve(newBonding);
    }

    function _calculateMintAmountFromBondingCurve(uint256 tokens, uint256 totalSupply) internal view virtual returns (uint256, uint256) {
        uint256 gap = 10 ** (18 - baseDecimals());
        (uint256 x, uint256 y) = _coinMaker.calculateMintAmountFromBondingCurve(tokens * gap, totalSupply, _bondingCurveParameters);
        return (x, y);
    }

    function _calculateBurnAmountFromBondingCurve(uint256 tokens, uint256 totalSupply) internal view virtual returns (uint256, uint256) {
        uint256 gap = 10 ** (18 - baseDecimals());
        (uint256 x, uint256 y) = _coinMaker.calculateBurnAmountFromBondingCurve(tokens, totalSupply, _bondingCurveParameters);
        return (x, y / gap);
    }

    function _price(uint256 totalSupply) internal view returns (uint256) {
        return _coinMaker.price(totalSupply, _bondingCurveParameters);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

// abdk-consulting
// "https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMathQuad.sol";
import "../libraries/ABDKMathQuad.sol";

// diy
import "../interfaces/IBondingCurve.sol";

contract LinearMixedBondingSwap is IBondingCurve {
    using ABDKMathQuad for bytes16;

    string public constant BondingCurveType = "linear";

    function getParameter(bytes memory data) private pure returns (uint256 k, uint256 p) {
        (k, p) = abi.decode(data, (uint256, uint256));
        // require(k <= 100000 && k >= 0, "Create: Invalid k");
        // require(p <= 1e24 && p >= 0, "Create: Invalid p");
    }

    // x => erc20, y => native
    // p(x) = x / k + p
    function calculateMintAmountFromBondingCurve(uint256 raisingTokenAmount, uint256 tokenCurrentSupply, bytes memory parameters) public pure override returns (uint256 tokenAmount, uint256) {
        (uint256 k, uint256 p) = getParameter(parameters);
        bytes16 abdk_tokenCurrentSupply = ABDKMathQuad.fromUInt(tokenCurrentSupply);
        bytes16 abdk_raisingTokenAmount = ABDKMathQuad.fromUInt(raisingTokenAmount);
        bytes16 abdk_k = ABDKMathQuad.fromUInt(k);
        bytes16 abdk_p = ABDKMathQuad.fromUInt(p);
        bytes16 tokenCurrentPrice = abdk_tokenCurrentSupply.mul(abdk_k).div(ABDKMathQuad.fromUInt(1e18)).add(abdk_p);
        tokenAmount = tokenCurrentPrice.mul(tokenCurrentPrice).add(abdk_raisingTokenAmount.mul(ABDKMathQuad.fromUInt(2)).mul(abdk_k)).sqrt().sub(tokenCurrentPrice).mul(ABDKMathQuad.fromUInt(1e18)).div(abdk_k).toUInt();
        return (tokenAmount, raisingTokenAmount);
    }

    function calculateBurnAmountFromBondingCurve(uint256 tokenAmount, uint256 tokenCurrentSupply, bytes memory parameters) public pure override returns (uint256, uint256 nativeTokenAmount) {
        (uint256 k, uint256 p) = getParameter(parameters);
        bytes16 abdk_tokenCurrentSupply = ABDKMathQuad.fromUInt(tokenCurrentSupply);
        bytes16 abdk_tokenAmount = ABDKMathQuad.fromUInt(tokenAmount);
        bytes16 abdk_k = ABDKMathQuad.fromUInt(k);
        bytes16 abdk_p = ABDKMathQuad.fromUInt(p);
        nativeTokenAmount = abdk_tokenCurrentSupply.mul(abdk_k).add(abdk_p.mul(ABDKMathQuad.fromUInt(1e18))).mul(abdk_tokenAmount).sub(abdk_tokenAmount.mul(abdk_tokenAmount).mul(abdk_k).div(ABDKMathQuad.fromUInt(2))).div(ABDKMathQuad.fromUInt(1e36)).toUInt();
        return (tokenAmount, nativeTokenAmount);
    }

    function price(uint256 tokenCurrentSupply, bytes memory parameters) public pure override returns (uint256) {
        (uint256 k, uint256 p) = getParameter(parameters);
        bytes16 abdk_k = ABDKMathQuad.fromUInt(k);
        bytes16 abdk_p = ABDKMathQuad.fromUInt(p);
        bytes16 abdk_tokenCurrentSupply = ABDKMathQuad.fromUInt(tokenCurrentSupply);
        return abdk_tokenCurrentSupply.mul(abdk_k).div(ABDKMathQuad.fromUInt(1e18)).add(abdk_p).toUInt();
    }
}

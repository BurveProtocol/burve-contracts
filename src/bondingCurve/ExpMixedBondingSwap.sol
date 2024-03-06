// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

// abdk-consulting
// "https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMathQuad.sol";
import "../libraries/ABDKMathQuad.sol";

// diy
import "../interfaces/IBondingCurve.sol";

contract ExpMixedBondingSwap is IBondingCurve {
    using ABDKMathQuad for bytes16;
    string public constant BondingCurveType = "exponential";

    function getParameter(bytes memory data) private pure returns (uint256 a, uint256 b) {
        (a, b) = abi.decode(data, (uint256, uint256));
    }

    // x => tokenAmount, y => raisingTokenAmount
    // y = (a) e**(x/b)
    // tokenAmount = b * ln(e ^ (tokenCurrentSupply / b) + raisingTokenAmount / a / b) - tokenCurrentSupply
    function calculateMintAmountFromBondingCurve(uint256 raisingTokenAmount, uint256 tokenCurrentSupply, bytes memory parameters) public pure override returns (uint256 tokenAmount, uint256) {
        (uint256 a, uint256 b) = getParameter(parameters);
        bytes16 abdk_a = ABDKMathQuad.fromUInt(a);
        bytes16 abdk_b = ABDKMathQuad.fromUInt(b);
        bytes16 abdk_raisingTokenAmount = ABDKMathQuad.fromUInt(raisingTokenAmount);
        bytes16 abdk_tokenCurrentSupply = ABDKMathQuad.fromUInt(tokenCurrentSupply);
        bytes16 fabdk_e_index = abdk_tokenCurrentSupply.div(abdk_b);
        bytes16 fabdk_e_mod = abdk_raisingTokenAmount.div(abdk_b).div(abdk_a);
        bytes16 fabdk_x = (fabdk_e_index.exp().add(fabdk_e_mod)).ln();
        require(fabdk_x >= 0);
        tokenAmount = fabdk_x.mul(abdk_b).toUInt() - tokenCurrentSupply;
        return (tokenAmount, raisingTokenAmount);
    }

    // x => tokenAmount, y => raisingTokenAmount
    // y = (a) e**(x/b)
    // raisingTokenAmount = ab * (e ^ (tokenCurrentSupply / b) - e ^ ((tokenCurrentSupply - tokenAmount) / b))
    function calculateBurnAmountFromBondingCurve(uint256 tokenAmount, uint256 tokenCurrentSupply, bytes memory parameters) public pure override returns (uint256, uint256 raisingTokenAmount) {
        (uint256 a, uint256 b) = getParameter(parameters);
        bytes16 abdk_a = ABDKMathQuad.fromUInt(a);
        bytes16 abdk_b = ABDKMathQuad.fromUInt(b);
        bytes16 abdk_tokenAmount = ABDKMathQuad.fromUInt(tokenAmount);
        bytes16 abdk_tokenCurrentSupply = ABDKMathQuad.fromUInt(tokenCurrentSupply);
        bytes16 fabdk_e_index_1 = abdk_tokenCurrentSupply.div(abdk_b);
        bytes16 fabdk_e_index_0 = abdk_tokenCurrentSupply.sub(abdk_tokenAmount).div(abdk_b);
        bytes16 fabdk_y = fabdk_e_index_1.exp().sub(fabdk_e_index_0.exp());
        require(fabdk_y >= 0);
        raisingTokenAmount = fabdk_y.mul(abdk_a).mul(abdk_b).toUInt();
        return (tokenAmount, raisingTokenAmount);
    }

    // price = a  * e ^ (tokenCurrentSupply / b)
    function price(uint256 tokenCurrentSupply, bytes memory parameters) public pure override returns (uint256) {
        (uint256 a, uint256 b) = getParameter(parameters);
        bytes16 abdk_a = ABDKMathQuad.fromUInt(a);
        bytes16 abdk_b = ABDKMathQuad.fromUInt(b);
        bytes16 e_index = ABDKMathQuad.fromUInt(tokenCurrentSupply).div(abdk_b);
        bytes16 fabdk_y = e_index.exp();
        require(fabdk_y >= 0);
        bytes16 p = fabdk_y.mul(abdk_a);
        return p.toUInt();
    }
}

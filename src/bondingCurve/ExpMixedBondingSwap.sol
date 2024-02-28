// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

// abdk-consulting
// "https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol";
import "../libraries/ABDKMath64x64.sol";

// diy
import "../interfaces/IBondingCurve.sol";

contract ExpMixedBondingSwap is IBondingCurve {
    using ABDKMath64x64 for int128;
    string public constant BondingCurveType = "exponential";

    function getParameter(bytes memory data) private pure returns (uint256 a, uint256 b) {
        (a, b) = abi.decode(data, (uint256, uint256));
    }

    // x => tokenAmount, y => raisingTokenAmount
    // y = (a) e**(x/b)
    // tokenAmount = b * ln(e ^ (tokenCurrentSupply / b) + raisingTokenAmount / a / b) - tokenCurrentSupply
    function calculateMintAmountFromBondingCurve(uint256 raisingTokenAmount, uint256 tokenCurrentSupply, bytes memory parameters) public pure override returns (uint256 tokenAmount, uint256) {
        (uint256 a, uint256 b) = getParameter(parameters);
        require(tokenCurrentSupply < uint256(1 << 192));
        require(raisingTokenAmount < uint256(1 << 192));
        uint256 e_index = (tokenCurrentSupply << 64) / b;
        uint256 e_mod = ((raisingTokenAmount * 1e18) << 64) / a / b;
        require(e_index <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        require(e_mod <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        int128 fabdk_e_index = int128(uint128(e_index));
        int128 fabdk_e_mod = int128(uint128(e_mod));
        int128 fabdk_x = (fabdk_e_index.exp() + fabdk_e_mod).ln();
        require(fabdk_x >= 0);
        tokenAmount = (((uint256(uint128(fabdk_x))) * b) >> 64) - tokenCurrentSupply;
        return (tokenAmount, raisingTokenAmount);
    }

    // x => tokenAmount, y => raisingTokenAmount
    // y = (a) e**(x/b)
    // raisingTokenAmount = ab * (e ^ (tokenCurrentSupply / b) - e ^ ((tokenCurrentSupply - tokenAmount) / b))
    function calculateBurnAmountFromBondingCurve(uint256 tokenAmount, uint256 tokenCurrentSupply, bytes memory parameters) public pure override returns (uint256, uint256 raisingTokenAmount) {
        (uint256 a, uint256 b) = getParameter(parameters);
        require(tokenCurrentSupply < uint256(1 << 192));
        require(tokenAmount < uint256(1 << 192));
        uint256 e_index_1 = (tokenCurrentSupply << 64) / b;
        uint256 e_index_0 = ((tokenCurrentSupply - tokenAmount) << 64) / b;
        require(e_index_1 <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        require(e_index_0 <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        int128 fabdk_e_index_1 = int128(uint128(e_index_1));
        int128 fabdk_e_index_0 = int128(uint128(e_index_0));
        int128 fabdk_y = fabdk_e_index_1.exp() - fabdk_e_index_0.exp();
        require(fabdk_y >= 0);
        raisingTokenAmount = (((uint256(uint128(fabdk_y))) * a * b) / 1e18) >> 64;
        return (tokenAmount, raisingTokenAmount);
    }

    // price = a  * e ^ (tokenCurrentSupply / b)
    function price(uint256 tokenCurrentSupply, bytes memory parameters) public pure override returns (uint256) {
        (uint256 a, uint256 b) = getParameter(parameters);
        uint256 e_index = (tokenCurrentSupply << 64) / b;
        require(e_index <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        int128 fabdk_e_index = int128(uint128(e_index));
        int128 fabdk_y = fabdk_e_index.exp();
        require(fabdk_y >= 0);
        uint256 p = (((uint256(uint128(fabdk_y))) * a)) >> 64;
        return p;
    }
}

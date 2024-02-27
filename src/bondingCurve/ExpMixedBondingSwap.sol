// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import {UD60x18, ud} from "prb-math/UD60x18.sol";
// diy
import "../interfaces/IBondingCurve.sol";

contract ExpMixedBondingSwap is IBondingCurve {
    string public constant BondingCurveType = "exponential";

    function getParameter(bytes memory data) private pure returns (UD60x18 a, UD60x18 b) {
        (a, b) = abi.decode(data, (UD60x18, UD60x18));
    }

    // x => tokenAmount, y => rasingTokenAmount
    // y = (a) e**(x/b)
    // tokenAmount = b * ln(e ^ (tokenCurrentSupply / b) + rasingTokenAmount / a / b) - tokenCurrentSupply
    function calculateMintAmountFromBondingCurve(uint256 rasingTokenAmount, uint256 tokenCurrentSupply, bytes memory parameters) public pure override returns (uint256 tokenAmount, uint256) {
        (UD60x18 a, UD60x18 b) = getParameter(parameters);
        UD60x18 e_index = ud(tokenCurrentSupply) / b;
        UD60x18 e_mod = ud(rasingTokenAmount) / a / b;
        UD60x18 fabdk_x = (e_index.exp() + e_mod).ln();
        require(fabdk_x >= ud(0));
        tokenAmount = (fabdk_x * b).unwrap() - tokenCurrentSupply;
        return (tokenAmount, rasingTokenAmount);
    }

    // x => tokenAmount, y => rasingTokenAmount
    // y = (a) e**(x/b)
    // rasingTokenAmount = ab * (e ^ (tokenCurrentSupply / b) - e ^ ((tokenCurrentSupply - tokenAmount) / b))
    function calculateBurnAmountFromBondingCurve(uint256 tokenAmount, uint256 tokenCurrentSupply, bytes memory parameters) public pure override returns (uint256, uint256 rasingTokenAmount) {
        (UD60x18 a, UD60x18 b) = getParameter(parameters);
        UD60x18 e_index_1 = ud(tokenCurrentSupply) / b;
        UD60x18 e_index_0 = (ud(tokenCurrentSupply) - ud(tokenAmount)) / b;
        UD60x18 fabdk_y = e_index_1.exp() - e_index_0.exp();
        require(fabdk_y >= ud(0));
        rasingTokenAmount = (fabdk_y * a * b).unwrap();
        return (tokenAmount, rasingTokenAmount);
    }

    // price = a  * e ^ (tokenCurrentSupply / b)
    function price(uint256 tokenCurrentSupply, bytes memory parameters) public pure override returns (uint256) {
        (UD60x18 a, UD60x18 b) = getParameter(parameters);
        UD60x18 e_index = ud(tokenCurrentSupply) / b;
        UD60x18 fabdk_y = e_index.exp();
        require(fabdk_y >= ud(0));
        uint256 p = (fabdk_y * a).unwrap();
        return p;
    }
}

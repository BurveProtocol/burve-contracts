// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IBurveToken.sol";

/**
 * @dev Interface of the Burve swap
 */
interface IBurveTokenPausable is IBurveToken {
    /**
     *   @dev Pauses the Burve token contract
     */
    function pause() external;

    /**
     *   @dev Unpauses the Burve token contract
     */
    function unpause() external;
}

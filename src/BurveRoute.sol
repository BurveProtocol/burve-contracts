// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IBurveRoute.sol";
import "./interfaces/IBurveToken.sol";
import "openzeppelin/token/ERC20/IERC20.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";

contract BurveRoute is IBurveRoute {
    using SafeERC20 for IERC20;
    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "expired");
        _;
    }

    function swap(
        address fromTokenAddr,
        address toTokenAddr,
        uint256 amount,
        uint256 minReturn,
        address to,
        uint256 deadline
    ) external ensure(deadline) {
        IBurveToken fromToken = IBurveToken(fromTokenAddr);
        IBurveToken toToken = IBurveToken(toTokenAddr);
        (uint tokenReceived, uint raisingTokenAmount) = getAmountOut(fromTokenAddr, toTokenAddr, amount);
        require(tokenReceived >= minReturn, "can not reach minReturn");
        IERC20(fromTokenAddr).safeTransferFrom(msg.sender, address(this), amount);
        fromToken.burn(address(this), amount, raisingTokenAmount);
        address raisingToken = fromToken.getRaisingToken();
        if (raisingToken != address(0)) {
            IERC20(raisingToken).safeApprove(toTokenAddr, raisingTokenAmount);
        }
        toToken.mint{value: raisingToken == address(0) ? raisingTokenAmount : 0}(
            address(to),
            raisingTokenAmount,
            tokenReceived
        );
    }

    function getAmountOut(
        address fromTokenAddr,
        address toTokenAddr,
        uint256 amount
    ) public view returns (uint256 returnAmount, uint256 raisingTokenAmount) {
        require(
            IBurveToken(fromTokenAddr).getRaisingToken() == IBurveToken(toTokenAddr).getRaisingToken(),
            "not the same raising token"
        );
        (, raisingTokenAmount, , ) = IBurveToken(fromTokenAddr).estimateBurn(amount);
        (returnAmount, , , ) = IBurveToken(toTokenAddr).estimateMint(raisingTokenAmount);
    }

    receive() external payable {}
}

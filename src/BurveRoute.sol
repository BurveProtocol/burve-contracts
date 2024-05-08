// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IBurveRoute.sol";
import "./interfaces/IBurveToken.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IBurveFactory.sol";
import "openzeppelin/token/ERC20/IERC20.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";

contract BurveRoute is IBurveRoute {
    using SafeERC20 for IERC20;
    IBurveFactory public immutable factory;

    constructor(address _factory) {
        factory = IBurveFactory(_factory);
    }

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "expired");
        _;
    }

    function mint(uint256 tokenIndex, uint256 amount, uint256 minReturn, address to, uint256 deadline) external payable ensure(deadline) {
        address tokenAddr = factory.getToken(tokenIndex);
        require(tokenAddr != address(0), "invalid token");
        IBurveToken token = IBurveToken(tokenAddr);
        uint256 value = msg.value;
        address raisingToken = token.getRaisingToken();
        address vault = factory.vault();
        if (raisingToken != address(0)) {
            IERC20(raisingToken).safeTransferFrom(msg.sender, vault, amount);
        } else {
            require(amount <= value, "invalid value");
        }
        IVault(vault).deposit{value: raisingToken == address(0) ? amount : 0}(raisingToken, address(token));
        token.mint(to, minReturn);
    }

    function swap(uint256 fromTokenIndex, uint256 toTokenIndex, uint256 amount, uint256 minReturn, address to, uint256 deadline) external ensure(deadline) {
        address fromToken = factory.getToken(fromTokenIndex);
        address toToken = factory.getToken(toTokenIndex);
        require(fromToken != address(0) && toToken != address(0), "invalid token");
        swap(fromToken, toToken, amount, minReturn, to);
    }

    function swapSupportFeeOnTransfer(uint256 fromTokenIndex, uint256 toTokenIndex, uint256 amount, uint256 minReturn, address to, uint256 deadline) external ensure(deadline) {
        address fromToken = factory.getToken(fromTokenIndex);
        address toToken = factory.getToken(toTokenIndex);
        require(fromToken != address(0) && toToken != address(0), "invalid token");
        swapSupportFeeOnTransfer(fromToken, toToken, amount, minReturn, to);
    }

    function swap(address fromTokenAddr, address toTokenAddr, uint256 amount, uint256 minReturn, address to) private {
        // factory.token
        IBurveToken fromToken = IBurveToken(fromTokenAddr);
        IBurveToken toToken = IBurveToken(toTokenAddr);
        address raisingToken = IBurveToken(fromTokenAddr).getRaisingToken();
        require(raisingToken == IBurveToken(toTokenAddr).getRaisingToken(), "not the same raising token");
        address vault = factory.vault();
        (uint tokenReceived, uint raisingTokenAmount) = getAmountOut(fromTokenAddr, toTokenAddr, amount);
        require(tokenReceived >= minReturn, "can not reach minReturn");
        IERC20(fromTokenAddr).safeTransferFrom(msg.sender, address(this), amount);
        fromToken.burnWithoutWithdraw(toTokenAddr, amount, raisingTokenAmount);
        toToken.mint(address(to), tokenReceived);
    }

    function swapSupportFeeOnTransfer(address fromTokenAddr, address toTokenAddr, uint256 amount, uint256 minReturn, address to) private {
        IBurveToken fromToken = IBurveToken(fromTokenAddr);
        IBurveToken toToken = IBurveToken(toTokenAddr);
        address raisingToken = IBurveToken(fromTokenAddr).getRaisingToken();
        require(raisingToken == IBurveToken(toTokenAddr).getRaisingToken(), "not the same raising token");
        (, uint256 raisingTokenAmount, , ) = IBurveToken(fromTokenAddr).estimateBurn(amount);
        IERC20(fromTokenAddr).safeTransferFrom(msg.sender, address(this), amount);
        fromToken.burnWithoutWithdraw(toTokenAddr, amount, raisingTokenAmount);
        if (raisingToken != address(0)) {
            raisingTokenAmount = IERC20(raisingToken).balanceOf(address(this));
        }
        if (raisingToken != address(0)) {
            IERC20(raisingToken).safeApprove(toTokenAddr, raisingTokenAmount);
        }
        toToken.mint(address(to), 0);
        uint256 afterMint = IERC20(toTokenAddr).balanceOf(address(this));
        require(afterMint >= minReturn, "can not reach minReturn");
        IERC20(toTokenAddr).safeTransfer(to, afterMint);
    }

    function getAmountOut(address fromTokenAddr, address toTokenAddr, uint256 amount) public view returns (uint256 returnAmount, uint256 raisingTokenAmount) {
        require(IBurveToken(fromTokenAddr).getRaisingToken() == IBurveToken(toTokenAddr).getRaisingToken(), "not the same raising token");
        (, raisingTokenAmount, , ) = IBurveToken(fromTokenAddr).estimateBurn(amount);
        (returnAmount, , , ) = IBurveToken(toTokenAddr).estimateMint(raisingTokenAmount);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: None
pragma solidity >=0.8.13;

// diy
import "./BurveLOL.sol";

contract BurveLOLBsc is BurveLOL {
    using SafeERC20 for IERC20;

    function _route() internal pure override returns (address) {
        return 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    }

    function _mm() internal virtual override returns (address) {
        return 0xc47Bc604ED649Bb73275d405D61dd81C7c196bed;
    }

    function _referral() internal virtual override returns (address) {
        return 0xa61C3e03982714bb54d03A2E991e4f1249FeE53a;
    }

    function _createPair(address raisingToken) internal virtual override returns (address addr) {
        addr = IUniswapFactory(IUniswapRouter(_route()).factory()).createPair(raisingToken == address(0) ? 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c : raisingToken, address(this));
    }

    function _addLiquidity(address raisingToken, uint256 value) internal override {
        uint256 balance = balanceOf(address(this));
        address route = _route();
        _approve(address(this), address(route), balance);
        if (raisingToken == address(0)) {
            IUniswapRouter(route).addLiquidityETH{value: value}(address(this), balance, 0, 0, address(0xdead), block.timestamp + 1);
        } else {
            IERC20(raisingToken).safeApprove(address(route), value);
            IUniswapRouter(route).addLiquidity(address(this), raisingToken, balance, value, 0, 0, address(0xdead), block.timestamp + 1);
        }
    }
}

interface IUniswapFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapRouter {
    function addLiquidity(address tokenA, address tokenB, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) external;

    function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external payable;

    function factory() external returns (address);
}

// SPDX-License-Identifier: None
pragma solidity >=0.8.13;

// diy
import "./BurveLOL.sol";

contract BurveLOLBase is BurveLOL {
    using SafeERC20 for IERC20;

    function _route() internal pure override returns (address) {
        return 0xcF77a3Ba9A5CA399B7c97c74d54e5b1Beb874E43;
    }

    function _mm() internal virtual override returns (address) {
        return 0x4a241e019FE21E15a11467d31d24811aB8bdF263;
    }

    function _referral() internal virtual override returns (address) {
        return 0x8Ffff9caF2DAe12d4dbe5ad13a48A4581Bbc3D55;
    }

    function _createPair(address raisingToken) internal virtual override returns (address addr) {
        addr = IAerodromeFactory(IAerodromeRouter(_route()).defaultFactory()).createPool(raisingToken == address(0) ? 0x4200000000000000000000000000000000000006 : raisingToken, address(this), false);
    }

    function _addLiquidity(address raisingToken, uint256 value) internal override {
        uint256 balance = balanceOf(address(this));
        address route = _route();
        _approve(address(this), address(route), balance);
        if (raisingToken == address(0)) {
            IAerodromeRouter(route).addLiquidityETH{value: value}(address(this), false, balance, 0, 0, address(0xdead), block.timestamp + 1);
        } else {
            IERC20(raisingToken).safeApprove(address(route), value);
            IAerodromeRouter(route).addLiquidity(address(this), raisingToken, false, balance, value, 0, 0, address(0xdead), block.timestamp + 1);
        }
    }
}

interface IAerodromeFactory {
    function getPool(address tokenA, address tokenB, bool stable) external view returns (address pair);

    function createPool(address tokenA, address tokenB, bool stable) external returns (address pool);
}

interface IAerodromeRouter {
    function addLiquidity(address tokenA, address tokenB, bool stable, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) external;

    function addLiquidityETH(address token, bool stable, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external payable;

    function defaultFactory() external returns (address);
}

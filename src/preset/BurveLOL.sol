// SPDX-License-Identifier: None
pragma solidity >=0.8.13;

// diy
import "./BurveERC20WithSupply.sol";

contract BurveLOL is BurveERC20WithSupply {
    using SafeERC20 for IERC20;
    uint256 constant _supply = 1e8 * 1 ether;
    uint256 public constant _ratio = 90;
    uint256 constant _supplyCap = (_supply * _ratio) / 100;
    uint256 constant _mintTax = 400;
    uint256 constant _burnTax = 400;
    uint256 constant _a = 0.0000198888 ether;
    uint256 constant _b = 31906964 ether;
    uint256 constant _valueLimit = 100 ether;
    IUniswapV2Router constant _route = IUniswapV2Router(0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008);
    bytes constant _data = abi.encode(_supply, abi.encode(_a, _b));
    // address _bondingCurveAddress = address(0);
    bool public idoEnded;
    mapping(address => uint256) mintedValue;

    function initialize(address bondingCurveAddress, IBurveFactory.TokenInfo memory token, address factory) public virtual override {
        token.projectAdmin = address(this);
        token.projectTreasury = IBurveFactory(factory).getPlatformTreasury();
        token.projectMintTax = _mintTax;
        token.projectBurnTax = _burnTax;
        token.data = _data;
        super.initialize(bondingCurveAddress, token, factory);
    }

    function _mintInternal(address account, uint256 amount) internal virtual override {
        (, uint256 paidAmount) = _calculateBurnAmountFromBondingCurve(amount, circulatingSupply() + amount);
        uint256 gap = 10 ** (18 - baseDecimals());
        require((mintedValue[account] + paidAmount) * gap <= _valueLimit, "mint capped");
        mintedValue[account] += paidAmount;
        require(!idoEnded && circulatingSupply() + amount <= _supplyCap + 1e18, "ido ended");
        super._mintInternal(account, amount);
        _claimPlatformFee();
        if (circulatingSupply() >= _supplyCap - 1e18) {
            idoEnded = true;
            address raisingToken = getRaisingToken();
            (uint256 pTax, ) = getTaxRateOfPlatform();
            uint256 raisedAmount = _getBalance(raisingToken) - (((paidAmount * (10000)) / (10000 - _mintTax - pTax)) * _mintTax) / 10000;
            uint256 out = (raisedAmount * 66) / 100;
            uint256 left = raisedAmount - out;
            _transferInternal(IBurveFactory(getFactory()).getPlatformTreasury(), out);
            uint256 balance = balanceOf(address(this));
            _approve(address(this), address(_route), balance);
            if (raisingToken == address(0)) {
                if (block.chainid == 8453) {
                    _route.addLiquidityETH{value: left}(address(this), false, balance, 0, 0, address(0xdead), block.timestamp + 1);
                } else {
                    _route.addLiquidityETH{value: left}(address(this), balance, 0, 0, address(0xdead), block.timestamp + 1);
                }
            } else {
                IERC20(raisingToken).safeApprove(address(_route), left);
                if (block.chainid == 8453) {
                    _route.addLiquidity(address(this), raisingToken, false, balance, left, 0, 0, address(0xdead), block.timestamp + 1);
                } else {
                    _route.addLiquidity(address(this), raisingToken, balance, left, 0, 0, address(0xdead), block.timestamp + 1);
                }
            }
        }
    }

    function _getBalance(address token) private view returns (uint256) {
        if (token == address(0)) {
            return address(this).balance;
        } else {
            return IERC20(token).balanceOf(address(this));
        }
    }
}

interface IUniswapV2Router {
    function addLiquidity(address tokenA, address tokenB, bool stable, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) external;

    function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function addLiquidityETH(address token, bool stable, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external payable;
}

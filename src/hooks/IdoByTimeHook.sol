// SPDX-License-Identifier: None

pragma solidity ^0.8.0;

import "./BaseHook.sol";
import "../interfaces/IBurveToken.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";

contract IdoByTimeHook is BaseHook {
    using SafeERC20 for IERC20;
    struct FundraisingInfo {
        address token;
        address raisingToken;
        uint256 deadline;
        uint256 totalFundraising;
        uint256 totalMinted;
        bool ended;
    }

    string public constant hookName = "IdoByTimeHook";
    string public constant parameterEncoder = "(uint256)";

    constructor(address factory) BaseHook(factory) {}

    mapping(address => mapping(address => uint256)) userFundraising;
    mapping(address => FundraisingInfo) idoInfo;

    function registerHook(address token, bytes calldata data) external virtual override onlyFactory {
        FundraisingInfo memory info = idoInfo[token];
        require(info.deadline == 0 || info.deadline > block.timestamp, "already launched");
        uint256 time = abi.decode(data, (uint256));
        info.deadline = time;
        info.raisingToken = IBurveToken(token).getRaisingToken();
        info.token = token;
        idoInfo[token] = info;
    }

    function beforeMintHook(address, address, uint256) external override {
        _checkEnd(idoInfo[address(msg.sender)]);
    }

    function fund(IBurveToken token, uint256 amount) external payable virtual {
        FundraisingInfo memory info = idoInfo[address(token)];
        require(block.timestamp < info.deadline, "ido ended");
        address user = msg.sender;
        uint256 actualAmount = _transferFrom(info.raisingToken, user, amount);
        userFundraising[address(token)][user] += actualAmount;
        info.totalFundraising += actualAmount;
        idoInfo[address(token)] = info;
    }

    function claim(address token) external virtual {
        FundraisingInfo storage info = idoInfo[address(token)];
        _checkEnd(info);
        address user = msg.sender;
        uint256 fundraising = userFundraising[token][user];
        userFundraising[token][user] = 0;
        uint256 amountToTransfer = (info.totalMinted * fundraising) / info.totalFundraising;
        IERC20(info.token).safeTransfer(user, amountToTransfer);
    }

    function _checkEnd(FundraisingInfo storage info) private {
        require(block.timestamp >= info.deadline, "ido not end");
        if (info.token != address(0) && !info.ended) {
            info.ended = true;
            uint256 value = info.raisingToken == address(0) ? info.totalFundraising : 0;
            if (info.raisingToken != address(0)) {
                IERC20(info.raisingToken).safeApprove(info.token, info.totalFundraising);
            }
            IBurveToken(info.token).mint{value: value}(address(this), info.totalFundraising, 0);
            info.totalMinted = IERC20(info.token).balanceOf(address(this));
        }
    }

    function _transferFrom(address token, address from, uint256 amount) internal virtual returns (uint256 actualAmount) {
        if (token == address(0)) {
            require(amount == msg.value, "invalid value");
            return amount;
        } else {
            uint256 balanceBefore = IERC20(token).balanceOf(address(this));
            IERC20(token).safeTransferFrom(from, address(this), amount);
            actualAmount = IERC20(token).balanceOf(address(this)) - balanceBefore;
        }
    }
}

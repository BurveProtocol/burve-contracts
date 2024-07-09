import "openzeppelin/token/ERC20/IERC20.sol";

pragma solidity ^0.8.0;

interface IERC20WithDecimals is IERC20 {
    function decimals() external view returns (uint8);
}

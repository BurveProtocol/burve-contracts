
import "openzeppelin/token/ERC20/IERC20.sol";

interface IERC20WithDecimals is IERC20{
    function decimals() external view returns (uint8);
}
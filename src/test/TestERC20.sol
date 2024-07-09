// SPDX-License-Identifier: Apache-2.0
// import "openzeppelin/token/ERC20/extensions/ERC20Votes.sol";
import "openzeppelin/token/ERC20/extensions/ERC20VotesComp.sol";

pragma solidity ^0.8.0;

contract TestERC20 is ERC20VotesComp {
    constructor() ERC20("Fake USDT", "USDT") ERC20Permit("USDT") {}

    function decimals() public pure override returns (uint8) {
        return 18;
    }

    function mint(uint256 amount) external {
        _mint(msg.sender, amount);
    }
}

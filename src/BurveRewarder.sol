pragma solidity ^0.8.13;
import "openzeppelin/access/Ownable.sol";
import "openzeppelin/utils/cryptography/ECDSA.sol";
import "openzeppelin/utils/cryptography/MerkleProof.sol";
import "openzeppelin/token/ERC20/IERC20.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";

contract BurveRewarder is Ownable {
    using SafeERC20 for IERC20;
    using ECDSA for bytes;
    mapping(uint256 => bool) public withdrawMap;
    event Withdrew(address indexed token, address indexed user, uint256 amount, uint256 id);

    constructor() Ownable() {}

    function withdraw(uint256 withdrawId, address token, uint256 amount, bytes32 r, bytes32 s, uint8 v) public {
        address user = msg.sender;
        address signer = ecrecover(abi.encode(withdrawId, user, token, amount).toEthSignedMessageHash(), v, r, s);
        require(owner() == signer, "invalid sig");
        require(!withdrawMap[withdrawId], "withdrew");
        withdrawMap[withdrawId] = true;
        _transferInternal(token, user, amount);
        emit Withdrew(token, user, amount, withdrawId);
    }

    function _transferInternal(address token, address account, uint256 amount) internal virtual {
        if (token == address(0)) {
            require(address(this).balance >= amount, "not enough balance");
            (bool success, ) = account.call{value: amount, gas: 30000}("");
            require(success, "Transfer: failed");
        } else {
            IERC20(token).safeTransfer(account, amount);
        }
    }
}

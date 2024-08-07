// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "openzeppelin-upgradeable/access/IAccessControlUpgradeable.sol";
import "./IBurveFactory.sol";

/**
 * @dev Interface of the Burve swap
 */
interface IBurveToken is IAccessControlUpgradeable {
    /**
     * @dev Initializes the Burve token contract.
     * @param bondingCurveAddress Address of the bonding curve contract.
     * @param token the parameters of token.
     * @param factory Address of the factory contract.
     */
    function initialize(address bondingCurveAddress, IBurveFactory.TokenInfo memory token, address factory) external;

    /**
     * @dev Returns the role identifier for the project administrator.
     * @return role identifier for the project administrator.
     */
    function PROJECT_ADMIN_ROLE() external pure returns (bytes32 role);

    /**
     * @dev Sets the metadata URL for the token.
     * @param url Metadata URL for the token.
     */
    function setMetadata(string memory url) external;

    /**
     * @dev Returns the metadata URL for the token.
     * @return Metadata URL for the token.
     */
    function getMetadata() external view returns (string memory);

    /**
     * @dev Returns the tax rates for project token minting and burning.
     * @return projectMintRate Tax rate for project token minting
     * @return projectBurnRate Tax rate for project token burning.
     */
    function getTaxRateOfProject() external view returns (uint256 projectMintRate, uint256 projectBurnRate);

    /**
     * @dev Returns the tax rates for platform token minting and burning.
     * @return platformMintTax Tax rate for platform when token minting
     * @return platformBurnTax Tax rate for platform when token burning.
     */
    function getTaxRateOfPlatform() external view returns (uint256 platformMintTax, uint256 platformBurnTax);

    /**
     * @dev Sets the tax rates for project token minting and burning.
     * @param projectMintTax Tax rate for project when token minting.
     * @param projectBurnTax Tax rate for project when token burning.
     */
    function setProjectTaxRate(uint256 projectMintTax, uint256 projectBurnTax) external;

    /**
     * @dev Gets the factory contract address
     * @return Address of the factory contract
     */
    function getFactory() external view returns (address);

    /**
     * @dev Gets the raising token address
     * @return Address of the raising token
     */
    function getRaisingToken() external view returns (address);

    /**
     * @dev Get the current project admin address
     * @return projectAdmin address
     */
    function getProjectAdmin() external view returns (address);

    /**
     * @dev Set a new address as project admin
     * @param newProjectAdmin new address to be set as project admin
     */
    function setProjectAdmin(address newProjectAdmin) external;

    /**
     * @dev Get the current project treasury address
     * @return projectTreasury address
     */
    function getProjectTreasury() external view returns (address);

    /**
     * @dev Set a new address as project treasury
     * @param newProjectTreasury new address to be set as project treasury
     */
    function setProjectTreasury(address newProjectTreasury) external;

    /**
     * @dev Get the current token price
     * @return token price
     */
    function price() external view returns (uint256);

    /**
     * @dev Mint new tokens
     * @param to the address where the new tokens will be sent to
     * @param payAmount the amount of raising token to pay
     * @param minReceive the minimum amount of tokens the buyer wants to receive
     */
    function mint(address to, uint payAmount, uint minReceive) external payable;

    /**
     * @dev Estimate the amount of tokens that will be received from minting, the amount of raising token that will be paid, and the platform and project fees
     * @param payAmount the amount of raising token to pay
     * @return receivedAmount the estimated amount of tokens received
     * @return paidAmount the estimated amount of raising token paid
     * @return platformFee the estimated platform fee
     * @return projectFee the estimated project fee
     */
    function estimateMint(uint payAmount) external view returns (uint receivedAmount, uint paidAmount, uint platformFee, uint projectFee);

    /**
     * @dev Estimate the amount of raising token that needs to be paid to receive a specific amount of tokens, and the platform and project fees
     * @param tokenAmountWant the desired amount of tokens
     * @return receivedAmount the estimated amount of tokens received
     * @return paidAmount the estimated amount of raising token paid
     * @return platformFee the estimated platform fee
     * @return projectFee the estimated project fee
     */
    function estimateMintNeed(uint tokenAmountWant) external view returns (uint receivedAmount, uint paidAmount, uint platformFee, uint projectFee);

    /**
     * @dev Burn tokens to receive raising token
     * @param to the address where the raising token will be sent to
     * @param payAmount the amount of tokens to burn
     * @param minReceive the minimum amount of raising token the seller wants to receive
     */
    function burn(address to, uint payAmount, uint minReceive) external;

    /**
     * @dev Estimate the amount of raising token that will be received from burning tokens, the amount of tokens that need to be burned, and the platform and project fees
     * @param tokenAmount the amount of tokens to burn
     * @return amountNeed the estimated amount of tokens needed to be burned
     * @return amountReturn the estimated amount of raising token received
     * @return platformFee the estimated platform fee
     * @return projectFee the estimated project fee
     */
    function estimateBurn(uint tokenAmount) external view returns (uint amountNeed, uint amountReturn, uint platformFee, uint projectFee);

    function claimPlatformFee() external;

    function circulatingSupply() external view returns (uint256);

    function getBondingCurve() external view returns (address);

    function getParameters() external view returns (bytes memory);
}

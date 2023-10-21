// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {EscrowParams} from "src/Escrow.sol";

/*
The IEscrowController interface defines the functions for managing the sale of a contract whose ownership is being
escrowed by an Escrow contract. The IEscrowController is responsible for starting and ending the sale, finalizing the
sale by transferring ownership to the new owner, and getting the status of the sale.

The IEscrowController has the following main functions:

1. startSale: This function starts the sale process.

2. finalizeSale: This function ends the sale process.

3. cancelSale: This function cancels the sale process.
*/
interface IEscrowController {
    enum SaleStatus {
        DEPLOYED,
        INITIALIZED,
        IN_PROGRESS,
        FINALIZED,
        CANCELLED
    }

    event SaleCreated(address indexed escrowedContract, address indexed owner, bytes data);
    event SaleStarted(address indexed escrowedContract, bytes data);
    event SaleFinalized(address indexed escrowedContract, bytes data);
    event SaleCancelled(address indexed escrowedContract);

    /**
     * @dev Initializes the EscrowController EIP-1167 clone
     * @param _escrowParams The parameters for the ownership transfer
     * @param _owner The address of the Owner of the Controller contract
     */
    function initialize(EscrowParams memory _escrowParams, address _owner) external;

    /**
     * @notice Starts the sale process
     * @dev Can only be called by the owner of the Escrow contract
     * @param params The abi.encoded parameters (if needed)
     */
    function startSale(bytes memory params) external;

    /**
     * @notice Finalizes the sale process
     * @param params The abi.encoded parameters (if needed)
     */
    function finalizeSale(bytes memory params) external;

    /**
     * @notice Cancels the sale process
     * @dev Can only be called by the owner of the Escrow contract
     * @param params The abi.encoded parameters (if needed)
     */
    function cancelSale(bytes memory params) external;
}

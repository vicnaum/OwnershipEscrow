// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IEscrowController} from "src/interfaces/IEscrowController.sol";

/*
The Escrow contract is designed to hold the ownership of another contract (the "Escrowed contract") and facilitate the 
transfer of ownership to a new owner. The Escrow contract is inherited by EscrowController contract, which handles all
the flow.

The parameters for the ownership transfer are stored in an EscrowParams struct, which includes the following fields:
- escrowedContract: The address of the Escrowed contract.
- transferOwnershipFunctionSignature: The 4-byte function signature of the ownership transfer function in the Escrowed
  contract.
- transferOwnershipFunctionParams: An array of bytes32 representing the parameters for the ownership transfer function.
  The address of the new owner is empty in this array and should be inserted at the moment when its known.
- newOwnerIndex: The position in the parameters array where the address of the new owner should be inserted.
- getOwnerFunctionSignature: The 4-byte function signature of the function in the Escrowed contract that checks the 
owner of the contract.

It also has the previousOwner variable which is set during initialization and is used for the ownership recovery.

The Escrow contract has the following functions:
- getEscrowedOwnership: Checks who is the owner of the Escrowed contract by calling the function specified by
  getOwnerFunctionSignature and comparing the result to the address of the Escrow instance contract.
- _confirmEscrow: Confirms the Escrow contract is the owner of the Escrowed contract
- _finalizeEscrow: Transfers the ownership of the Escrowed contract to a new owner. This function can only be called 
by the controller (after some specific condition or event is met - for example the auction is over). It inserts the
address of the new owner into the parameters array at the position specified by newOwnerIndex, then calls the function
specified by functionSignature in the Escrowed contract with the new ownership parameters.
- _cancelEscrow: Returns the ownership of the Escrowed contract to the controller. This function can only be called 
by the Owner of the current Escrow instance contract in case of emergency.
*/

/**
 * @dev Struct for the parameters of the ownership transfer
 */
struct EscrowParams {
    address escrowedContract;
    bytes4 transferOwnershipFunctionSignature;
    bytes32[] transferOwnershipFunctionParams;
    uint256 newOwnerIndex;
    bytes4 getOwnerFunctionSignature;
}

/**
 * @title Escrow
 * @notice The Escrow contract is responsible for escrowing the ownership of a contract.
 * It is inherited by an EscrowController contract that is responsible for starting and finalizing the sale of the
 * contract whose ownership is being escrowed.
 * @dev This contract is meant to be inherited by the EscrowFactory contract.
 */
contract Escrow {
    /// @notice The parameters for the ownership transfer
    EscrowParams public escrowParams;

    /// @notice The address of the previous owner of the Escrowed contract
    address public previousOwner;

    // Initializer

    function _initializeEscrow(EscrowParams memory _escrowParams) internal {
        escrowParams = _escrowParams;
        previousOwner = _getEscrowedOwnership();
    }

    // State modifiers

    /**
     * @dev Transfers the ownership of the Escrowed contract to a new owner
     * @param newOwner The address of the new owner
     */
    function _finalizeEscrow(address newOwner) internal {
        bytes32[] memory params = escrowParams.transferOwnershipFunctionParams;
        params[escrowParams.newOwnerIndex] = bytes32(abi.encodePacked(newOwner));

        (bool success,) = escrowParams.escrowedContract.call(
            abi.encodePacked(escrowParams.transferOwnershipFunctionSignature, params)
        );
        require(success, "Failed to transfer ownership");
        require(_getEscrowedOwnership() == newOwner, "Ownership transfer failed");
    }

    /**
     * @dev Confirms the Escrow contract is the owner of the Escrowed contract
     */
    function _confirmEscrow() internal view {
        require(_getEscrowedOwnership() == address(this), "Escrow contract is not the owner of Escrowed contract");
    }

    /**
     * @notice Cancels the Escrow contract and returns the ownership of the Escrowed contract to the controller
     */
    function _cancelEscrow() internal {
        (bool success,) = escrowParams.escrowedContract.call(
            abi.encodeWithSelector(escrowParams.transferOwnershipFunctionSignature, previousOwner)
        );
        require(success, "Failed to recover ownership");
        require(_getEscrowedOwnership() == previousOwner, "Ownership recovery failed");
    }

    // Getters

    /**
     * @notice Gets the owner of the Escrowed contract using getOwnerFunctionSignature call
     * @return address of the Owner contract owner
     */
    function getEscrowedOwnership() external view returns (address) {
        return _getEscrowedOwnership();
    }

    // Private functions

    /// @dev Gets the owner of the Escrowed contract using getOwnerFunctionSignature call
    /// @return address of the Escrowed contract owner
    function _getEscrowedOwnership() private view returns (address) {
        (bool success, bytes memory data) =
            escrowParams.escrowedContract.staticcall(abi.encodeWithSelector(escrowParams.getOwnerFunctionSignature));
        require(success, "Failed to get ownership");
        return abi.decode(data, (address));
    }
}

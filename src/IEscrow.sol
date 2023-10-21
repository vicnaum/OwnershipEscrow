// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

/*
The Escrow contract is designed to hold the ownership of another contract (the "Owned contract") and facilitate the 
transfer of ownership to a new owner. The Escrow contract instance is deployed by the EscrowFactory contract, which
passes the parameters for the ownership transfer to the Escrow contract's constructor.

The parameters for the ownership transfer are stored in an OwnershipTransfer struct, which includes the following fields:
- functionSignature: The 4-byte function signature of the ownership transfer function in the Owned contract.
- parameters: An array of bytes representing the parameters for the ownership transfer function. The address of the 
new owner is empty in this array and should be inserted at the moment when its known.
- newOwnerIndex: The position in the parameters array where the address of the new owner should be inserted.
- controller: The address of the Controller, which has permission to trigger the ownership transfer.
- ownerCheckFunctionSignature: The 4-byte function signature of the function in the Owned contract that checks the 
owner of the contract.

The Escrow instant contract is Ownable itself, with the Owner set during the deployment of the instance and is used
for emergency ownership recovery.

The Escrow contract has the following functions:
- checkOwnership: Checks whether the Escrow contract is the owner of the Owned contract by calling the function 
specified by ownerCheckFunctionSignature and comparing the result to the address of the Escrow instance contract.
- transferOwnership: Transfers the ownership of the Owned contract to a new owner. This function can only be called 
by the controller (after some specific condition or event is met - for example the auction is over). It inserts the
address of the new owner into the parameters array at the position specified by newOwnerIndex, then calls the function
specified by functionSignature in the Owned contract with the new ownership parameters.
- recoverOwnership: Returns the ownership of the Owned contract to the controller. This function can only be called 
by the Owner of the current Escrow instance contract in case of emergency.
*/

/**
 * @title IEscrow
 * @dev This is the interface for the Escrow contract
 */
interface IEscrow {
    /**
     * @dev Struct for the parameters of the ownership transfer
     */
    struct EscrowParams {
        address ownedContract;
        bytes4 functionSignature;
        bytes parameters;
        uint256 newOwnerIndex;
        address controller;
        bytes4 ownerCheckFunctionSignature;
    }

    /**
     * @dev Checks whether the Escrow contract is the owner of the Owned contract
     * @return boolean indicating if the Escrow contract is the owner
     */
    function checkOwnership() external view returns (bool);

    /**
     * @dev Transfers the ownership of the Owned contract to a new owner
     * @param newOwner The address of the new owner
     */
    function transferOwnership(address newOwner) external;

    /**
     * @dev Returns the ownership of the Owned contract to the controller
     */
    function recoverOwnership() external;
}


// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {EscrowParams} from "src/Escrow.sol";

/*
The EscrowFactory contract is responsible for deploying new instances of the Controller contract.
Each instance of Controller contract are associated with a specific Escrowed contract whose ownership is being
escrowed.

The EscrowFactory contract has the following function:

createEscrow: This function deploys a new instance of the Controller contract using EIP-1167 clone.
   It takes the parameters for the Escrow contract's initializer, which include the details of the ownership transfer,
   and the address of the owner of the Controller contract and chosen implemenetation of the controller.
   The function returns the address of the newly deployed Controller contract.
*/

interface IEscrowFactory {
    function createEscrow(EscrowParams memory _escrowParams, address _controllerImpl, address _instanceOwner)
        external
        returns (address);
}

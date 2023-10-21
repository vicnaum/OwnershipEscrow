# Smart Contract Ownership Escrow

This project is a smart contract system for escrowing the ownership of a contract.
It is built for any EVM-compatible Ethereum blockchain using Solidity.

## Use case

Consider a Protocol, a DAO or a DEX that is successfully generating revenue or collects fees to the owner. Owner is usually set in a smart contract.
The owner of the SmartContract decides to sell it. Instead of transferring the ownership directly to a new owner, they decide to use this Escrow system.

The owner deploys an instance of the `EscrowFactory` contract and creates an escrow for their Smart Contract using the `createEscrow` function.
The ownership of the Contract is transferred to the `Escrow` contract, and the sale process begins.

Potential buyers can make offers to buy the Protocol. The owner can set a BuyItNow price using the `SimpleSaleController` or any other Controller (like Auction, etc).
If a buyer agrees to the BuyItNow price or the owner accepts an offer, the sale is finalized. The `EscrowController` transfers the ownership of the DAO's contract to the new owner, and the sale is complete.

This Escrow system provides a secure and transparent way to sell the ownership of a contract. It ensures that the ownership is only transferred when the sale conditions are met, protecting both the seller and the buyer.

## Overview

The system consists of several contracts that interact with each other:

- `Escrow.sol`: This contract is designed to hold the ownership of another contract (the "Escrowed contract") and facilitate the transfer of ownership to a new owner when sale conditions are met.

- `EscrowFactory.sol`: This contract deploys a new instance of the EscrowController contract using EIP-1167 clones pattern (a separate contract for each Escrow).

- `IEscrowController.sol`: This interface defines the functions for managing the sale of a contract whose ownership is being escrowed by an Escrow contract.

- `SimpleSaleController.sol`: This contract is an example of a Simple Sale Controller that allows the owner to set a BuyItNow price and the buyer to make an offer.

## How it works

The `EscrowFactory` contract is responsible for deploying new instances of the `Controller` contract. Each instance of `Controller` contract are associated with a specific Escrowed contract whose ownership is being escrowed.

The `EscrowController` is responsible for starting and ending the sale, finalizing the sale by transferring ownership to the new owner, cancelling the sale, and tracking the status of the sale.

The `SimpleSaleController` allows the owner to set a BuyItNow price and the buyer to make an offer. The sale is finalized when either the owner accepts the buyer's offer or the buyer accepts the BuyItNow price.

## How to use

To use this system, you would first deploy an instance of the `EscrowFactory` contract. Then, you would call the `createEscrow` function on the `EscrowFactory` contract to deploy a new instance of the `Controller` contract.
The desired `Controller` implementation should be deployed beforehand and can be passed as a parameter. Below we describe the process using `SimpleSaleController` contract as an example.

Among the parameters required to deploy an escrow instance is the ownership transfer parameters (`EscrowParameters`):
`EscrowParameters` is a struct that contains the following fields:

- `escrowedContract`: This is the address of the contract whose ownership is being escrowed.

- `transferOwnershipFunctionSignature`: This is the 4-byte function signature of the ownership transfer function in the escrowed contract. For the OpenZeppelin `Ownable` contract, this would be the function signature of the `transferOwnership` function.

- `transferOwnershipFunctionParams`: This is an array of bytes32 representing the parameters for the ownership transfer function. The address of the new owner is empty in this array and should be inserted at the moment when it's known. For the `Ownable` contract, this would be an array with a single empty parameter, because the `transferOwnership` function only takes one argument (the address of the new owner), which will be inserted later.

- `newOwnerIndex`: This is the position in the parameters array where the address of the new owner should be inserted. For the `Ownable` contract, this would be 0 because the `transferOwnership` function only takes one argument and it is the new owner.

- `getOwnerFunctionSignature`: This is the 4-byte function signature of the function in the escrowed contract that checks the owner of the contract. For the `Ownable` contract, this would be the function signature of the `owner` function.

Here is an example of how you would create an `EscrowParameters` struct for an `Ownable` contract:

```solidity
EscrowParams memory params = EscrowParams({
    escrowedContract: ownableContractAddress,
    transferOwnershipFunctionSignature: bytes4(keccak256("transferOwnership(address)")),
    transferOwnershipFunctionParams: new bytes32[](1),
    newOwnerIndex: 0,
    getOwnerFunctionSignature: bytes4(keccak256("owner()"))
});
```

Once the `Controller` contract is deployed, you should transfer the ownership of your contract to the Controller, and then you can start the sale process by calling the `startSale` function on the `SimpleSaleController` contract, specifying the BuyItNow price.

Buyers can then make offers by calling the `makeOffer` function on the `SimpleSaleController` contract.

The sale can be finalized by either the owner accepting the buyer's offer or the buyer accepting the BuyItNow price. This is done by calling the `finalizeSale` function on the `SimpleSaleController` contract by either the owner (to accept a buyers offer), or by the buyer (to accept the BuyItNow price).

Any ERC20 token can be used for the sale.

## Architecture

The system is designed with a factory pattern, where the `EscrowFactory` contract is responsible for deploying new instances of the `Controller` contract. This allows for each sale to have its own unique contract instance.

The `Controller` contract is responsible for managing the sale process. It inherits from the `Escrow` contract, which holds the ownership of the Escrowed contract and facilitates the transfer of ownership to a new owner.

The `SimpleSaleController` contract is an implementation of the `IEscrowController` interface. It provides a simple sale process where the owner can set a BuyItNow price and buyers can make offers.

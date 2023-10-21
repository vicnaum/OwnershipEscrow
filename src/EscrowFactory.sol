// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IEscrowFactory} from "src/interfaces/IEscrowFactory.sol";
import {IEscrowController} from "src/interfaces/IEscrowController.sol";
import {EscrowParams, Escrow} from "src/Escrow.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

/**
 * @title EscrowFactory
 * @notice The EscrowFactory contract is responsible for deploying new EscrowController contracts.
 */
contract EscrowFactory is IEscrowFactory {
    event EscrowCreated(
        address indexed escrowedContract, EscrowParams escrowParams, address controllerClone, address instanceOwner
    );

    /// @dev Deploys a new Escrow contract instance
    /// @param _escrowParams The parameters for the ownership transfer
    /// @param _instanceOwner The address of the Owner of the Escrow contract
    /// @return address of the new Escrow contract instance
    function createEscrow(EscrowParams memory _escrowParams, address _controllerImpl, address _instanceOwner)
        public
        override
        returns (address)
    {
        address controllerClone = Clones.clone(_controllerImpl);
        IEscrowController(controllerClone).initialize(_escrowParams, _instanceOwner);
        emit EscrowCreated(_escrowParams.escrowedContract, _escrowParams, controllerClone, _instanceOwner);
        return (controllerClone);
    }
}

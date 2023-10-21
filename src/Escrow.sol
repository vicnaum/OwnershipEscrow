// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IEscrow.sol";

contract Escrow is Ownable, IEscrow {
    EscrowParams public escrowParams;

    constructor(EscrowParams memory _escrowParams, address _owner) {
        escrowParams = _escrowParams;
        Ownable.transferOwnership(_owner);
    }

    function _checkOwnership() internal view override returns (bool) {
        (bool success, bytes memory data) = 
            ownedContract.staticcall(
                abi.encodeWithSelector(escrowParams.ownerCheckFunctionSignature)
            );
        require(success, "Failed to check ownership");
        return (abi.decode(data, (address)) == address(this));
    }

    function transferOwnership(address newOwner) external override {
        require(msg.sender == escrowParams.controller, "Only controller can transfer ownership");
        bytes memory params = abi.encodePacked(
            escrowParams.parameters[:escrowParams.newOwnerIndex], 
            newOwner, 
            escrowParams.parameters[escrowParams.newOwnerIndex:]
        );
        (bool success,) = 
            ownedContract.call(
                abi.encodeWithSelector(escrowParams.functionSignature, params)
            );
        require(success, "Failed to transfer ownership");
    }

    function recoverOwnership() external override onlyOwner {
        (bool success,) = 
            ownedContract.call(
                abi.encodeWithSelector(
                    escrowParams.functionSignature, 
                    abi.encode(escrowParams.controller)
                )
            );
        require(success, "Failed to recover ownership");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IEscrowController} from "src/interfaces/IEscrowController.sol";
import {EscrowParams, Escrow} from "src/Escrow.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title SimpleSaleController
 * @notice A simple sale controller that allows the owner to set a BuyItNow price and the buyer to make an offer.
 * The sale is finalized when either the owner accepts the buyer's offer or the buyer accepts the BuyItNow price.
 * The owner can cancel the sale at any time before its finalized.
 * @dev This contract is meant to be deployed with EIP-1167 clone pattern by EscrowFactory contract.
 */
contract SimpleSaleController is IEscrowController, Escrow {
    using SafeERC20 for IERC20;

    struct Price {
        uint256 amount;
        address token;
    }

    address public owner;
    SaleStatus public saleStatus;
    Price public buyItNowPrice;
    mapping(address => Price) public offers;

    event OfferMade(address indexed escrowedContract, address indexed buyer, uint256 amount, address token);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor() {
        saleStatus = SaleStatus.INITIALIZED;
    }

    /// @inheritdoc IEscrowController
    function initialize(EscrowParams memory _escrowParams, address _owner) external {
        require(saleStatus == SaleStatus.DEPLOYED, "Escrow can only be initialized in DEPLOYED status");
        owner = _owner;
        _initializeEscrow(_escrowParams);
        saleStatus = SaleStatus.INITIALIZED;
        emit SaleCreated(_escrowParams.escrowedContract, owner, "");
    }

    /**
     * @notice Starts the sale process by setting the BuyItNow price
     * @dev Can only be called once, when the sale is still in initialized status, and if the ownership of the Escrowed
     * contract is confirmed.
     * @param params The parameters for the sale abi.encoded as (uint256 amount, address token)
     * @custom:permissions Only owner
     */
    function startSale(bytes memory params) external onlyOwner {
        (uint256 amount, address token) = abi.decode(params, (uint256, address));
        buyItNowPrice = Price(amount, token);
        require(saleStatus == SaleStatus.INITIALIZED, "Sale can only be started in INITIALIZED status");
        _confirmEscrow();
        saleStatus = SaleStatus.IN_PROGRESS;
        emit SaleStarted(escrowParams.escrowedContract, params);
    }

    /**
     * @notice Finalizes the sale - either by accepting the buyer's offer or the BuyItNow price.
     * If the owner calls this function, the buyer's offer is accepted.
     * If the buyer calls this function, the BuyItNow price is accepted.
     * @dev The sale must be in progress and the buyer must have sufficient allowance
     * @param params The parameters for the sale abi.encoded as (address buyer, uint256 amount, address token)
     * @inheritdoc IEscrowController
     */
    function finalizeSale(bytes memory params) external {
        require(saleStatus == SaleStatus.IN_PROGRESS, "Sale can only be finalized in IN_PROGRESS status");
        (address buyer, uint256 amount, address token) = abi.decode(params, (address, uint256, address));
        if (msg.sender == owner) {
            // Finalize initiated by Owner - accept the buyers offer
            Price memory offer = offers[buyer];
            require(offer.amount == amount && offer.token == token, "Offer not found");
        } else {
            // Finalize initiated by Buyer - accept the BuyItNow price
            require(
                buyer == msg.sender && amount == buyItNowPrice.amount && token == buyItNowPrice.token,
                "Invalid BuyItNow price"
            );
        }
        _finalizeEscrow(buyer);
        saleStatus = SaleStatus.FINALIZED;
        IERC20(token).safeTransferFrom(buyer, owner, amount);
        emit SaleFinalized(escrowParams.escrowedContract, params);
    }

    /// @inheritdoc IEscrowController
    /// @custom:permissions Only owner
    function cancelSale(bytes memory /* params */ ) external onlyOwner {
        require(
            saleStatus != SaleStatus.FINALIZED && saleStatus != SaleStatus.CANCELLED,
            "Sale was already finalized or cancelled"
        );
        _cancelEscrow();
        saleStatus = SaleStatus.CANCELLED;
        emit SaleCancelled(escrowParams.escrowedContract);
    }

    /**
     * @notice Allows a user to make an offer for the sale
     * @dev The sale must be in progress and the user must have sufficient allowance
     * @param amount The amount of tokens to offer
     * @param token The address of the token to offer
     */
    function makeOffer(uint256 amount, address token) external {
        require(saleStatus == SaleStatus.IN_PROGRESS, "Sale is not in progress");
        require(IERC20(token).allowance(msg.sender, address(this)) >= amount, "Insufficient allowance");
        offers[msg.sender] = Price(amount, token);
        emit OfferMade(escrowParams.escrowedContract, msg.sender, amount, token);
    }
}

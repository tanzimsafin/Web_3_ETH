// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Interface for TokenMessengerV2 (based on the provided contract)
interface ITokenMessengerV2 {
    function depositForBurn(
        uint256 amount,
        uint32 destinationDomain,
        bytes32 mintRecipient,
        address burnToken,
        bytes32 destinationCaller,
        uint256 maxFee,
        uint32 minFinalityThreshold
    ) external;
}

// Interface for MessageTransmitterV2 (to call receiveMessage)
interface IMessageTransmitterV2 {
    function receiveMessage(bytes calldata message, bytes calldata attestation) external returns (bool success);
}

// Interface for USDC (ERC-20 token)
interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
}
contract PaymentProcessor {
    // Addresses for CCTP contracts
    address public tokenMessengerV2; // TokenMessengerV2 on the source chain (e.g., Polygon Amoy)
    address public messageTransmitterV2; // MessageTransmitterV2 on the destination chain (e.g., Ethereum Sepolia)
    address public usdcToken; // USDC contract address on the source chain

    // Constructor to set the contract addresses
    constructor(
        address _tokenMessengerV2,
        address _messageTransmitterV2,
        address _usdcToken
    ) {
        tokenMessengerV2 = _tokenMessengerV2;
        messageTransmitterV2 = _messageTransmitterV2;
        usdcToken = _usdcToken;
    }

    // Function for the customer to initiate a payment (burn USDC on their chain)
    function initiatePayment(
        uint256 amount, // Amount in USDC (e.g., 100 USDC = 100 * 10^6)
        uint32 destinationDomain, // Merchant's chain (e.g., 0 for Sepolia)
        address merchantAddress // Merchant's address on the destination chain
    ) external {
        // Approve TokenMessengerV2 to burn the customer's USDC
        require(IERC20(usdcToken).approve(tokenMessengerV2, amount), "USDC approval failed");

        // Convert merchant address to bytes32 (pad with zeros to make it 32 bytes)
        bytes32 mintRecipient = bytes32(uint256(uint160(merchantAddress)));

        // Call depositForBurn on TokenMessengerV2 to burn USDC and send the message
        ITokenMessengerV2(tokenMessengerV2).depositForBurn(
            amount, // Amount to burn (with 6 decimals)
            destinationDomain, // Destination chain domain
            mintRecipient, // Merchant's address (as bytes32)
            usdcToken, // USDC contract address
            bytes32(0), // destinationCaller (set to 0 to allow anyone to call receiveMessage)
            0, // maxFee (set to 0 for testing)
            2000 // minFinalityThreshold (2000 for finalized transfer)
        );

        // Emit an event to track the payment
        emit PaymentInitiated(msg.sender, merchantAddress, amount, destinationDomain);
    }

    // Function to complete the payment on the merchant's chain (mint USDC)
    function completePayment(
        bytes calldata message, // Message from depositForBurn (from transaction logs)
        bytes calldata attestation // Attestation signature from Circle's API
    ) external {
        // Call receiveMessage on MessageTransmitterV2 to mint USDC
        bool success = IMessageTransmitterV2(messageTransmitterV2).receiveMessage(message, attestation);
        require(success, "Failed to mint USDC on destination chain");

        // Emit an event to confirm the payment is complete
        emit PaymentCompleted(msg.sender, message);
    }

    // Events to track payment progress
    event PaymentInitiated(address indexed customer, address indexed merchant, uint256 amount, uint32 destinationDomain);
    event PaymentCompleted(address indexed caller, bytes message);
}
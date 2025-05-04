// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";

/**
 * @title CatFactConsumer
 * @notice This contract fetches random cat facts using Chainlink Functions
 * @dev Uses the cat facts API (https://catfact.ninja/fact)
 */
contract CatFactConsumer is FunctionsClient, ConfirmedOwner {
    using FunctionsRequest for FunctionsRequest.Request;

    // State variables to store the last request ID, response, and error
    bytes32 public s_lastRequestId;
    bytes public s_lastResponse;
    bytes public s_lastError;

    // Custom error type
    error UnexpectedRequestID(bytes32 requestId);

    // Event to log responses
    event Response(
        bytes32 indexed requestId,
        string fact,
        bytes response,
        bytes err
    );

    // Router address - Hardcoded for Sepolia
    // Check to get the router address for your supported network https://docs.chain.link/chainlink-functions/supported-networks
    address router = 0xA9d587a00A31A52Ed70D6026794a8FC5E2F5dCb0;

    // JavaScript source code for Chainlink Functions
    // Fetch a random cat fact from the cat facts API
    string source =
       "const apiResponse = await Functions.makeHttpRequest({"
        "url: `https://catfact.ninja/fact/`"
        "});"
        "if (apiResponse.error) {"
        "throw Error('Request failed');"
        "}"
        "const { data } = apiResponse;"
        "return Functions.encodeString(data.fact)";
    // Callback gas limit
    uint32 gasLimit = 300000;

    // donID - Hardcoded for Sepolia
    // Check to get the donID for your supported network https://docs.chain.link/chainlink-functions/supported-networks
    bytes32 donID =
        0x66756e2d6176616c616e6368652d66756a692d31000000000000000000000000;

    // State variable to store the returned cat fact
    string public fact;

    /**
     * @notice Initializes the contract with the Chainlink router address and sets the contract owner
     */
    constructor() FunctionsClient(router) ConfirmedOwner(msg.sender) {}

    /**
     * @notice Sends an HTTP request for a cat fact
     * @param subscriptionId The ID for the Chainlink subscription
     * @return requestId The ID of the request
     */
    function sendRequest(
        uint64 subscriptionId
    ) external onlyOwner returns (bytes32 requestId) {
        FunctionsRequest.Request memory req;
        req.initializeRequest(FunctionsRequest.Location.Inline, FunctionsRequest.CodeLanguage.JavaScript, source);
        
        // Add secrets if needed (not needed for this example)
        // req.addSecretsReference(secretsReference);
        
        s_lastRequestId = _sendRequest(
            req.encodeCBOR(),
            subscriptionId,
            gasLimit,
            donID
        );

        return s_lastRequestId;
    }
    
    /**
     * @notice Check if a cat fact has been received
     * @return bool True if a fact has been received, false otherwise
     */
    function hasReceivedFact() external view returns (bool) {
        return bytes(fact).length > 0;
    }

    /**
     * @notice Callback function for fulfilling a request
     * @param requestId The ID of the request to fulfill
     * @param response The HTTP response data
     * @param err Any errors from the Functions request
     */
    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        if (s_lastRequestId != requestId) {
            revert UnexpectedRequestID(requestId); // Check if request IDs match
        }
        
        // Update the contract's state variables with the response and any errors
        s_lastResponse = response;
        
        // Properly decode the response - it's already a string encoded by Functions.encodeString()
        if (response.length > 0) {
            fact = string(response);
        } else {
            fact = "No fact received";
        }
        
        s_lastError = err;

        // Emit an event to log the response
        emit Response(requestId, fact, s_lastResponse, s_lastError);
    }
}
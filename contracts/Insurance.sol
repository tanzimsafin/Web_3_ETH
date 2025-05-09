// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/libraries/FunctionsRequest.sol";

contract Insurance is FunctionsClient {
    using FunctionsRequest for FunctionsRequest.Request;

    // --- State ---
    address public owner;
    uint64  public subscriptionId;
    uint32  public gasLimit = 300000;

    // Chainlink Functions router & DON ID (Sepolia)
    address constant router = 0xA9d587a00A31A52Ed70D6026794a8FC5E2F5dCb0;
    bytes32 constant donID  = 0x66756e2d6176616c616e6368652d66756a692d31000000000000000000000000;

    // Last request tracking
    bytes32 public lastRequestId;
    bytes   public lastResponse;
    bytes   public lastError;

    // ========== User & Insurance ==========
    struct User {
        string Name;
        uint256 Age;
        string Addr;
        uint256 InsuranceAmount;
    }

    mapping(address => User) public insuranceBalance;

    // ========== Chainlink Functions Request Tracking ==========
    struct RequestStatus {
        bool    exists;
        bool    fulfilled;
        bytes   response;
        bytes   err;
    }
    mapping(bytes32 => RequestStatus) public requests;
    bytes32[] public requestIds;

    event Response(
        bytes32 indexed requestId,
        string temperature,
        bytes response,
        bytes err
    );

    // ========== JavaScript Source ==========
    string public source = 
        "const city = args[0];"
        "const apiResponse = await Functions.makeHttpRequest({"
            "url: `https://wttr.in/${city}?format=3&m`,"
            "responseType: 'text'"
        "});"
        "if (apiResponse.error) { throw Error('Request failed'); }"
        "return Functions.encodeString(apiResponse.data);";

    // City data
    struct CityStruct {
        address sender;
        uint256 timestamp;
        string name;
        string temperature;
    }
    CityStruct[] public cities;
    mapping(string => uint256) public cityIndex;
    mapping(bytes32 => string) public requestToCity;

    // ========== Constructor ==========
    constructor(uint64 _subscriptionId) FunctionsClient(router) {
        owner          = msg.sender;
        subscriptionId = _subscriptionId;
    }

    // ========== Chainlink Functions Call ==========
    function getTemperature(string memory _city) external returns (bytes32) {
        
        string[] memory args = new string[](1);
        args[0] = _city;
        
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(source);
        req.setArgs(args);

        bytes32 reqId = _sendRequest(
            req.encodeCBOR(),
            subscriptionId,
            gasLimit,
            donID
        );
        lastRequestId = reqId;

        // track
        requestToCity[reqId] = _city;
        requests[reqId] = RequestStatus({ exists: true, fulfilled: false, response: "", err: "" });
        requestIds.push(reqId);

        // new city entry
        cities.push(CityStruct({
            sender: msg.sender,
            timestamp: 0,
            name: _city,
            temperature: ""
        }));
        cityIndex[_city] = cities.length - 1;

        return reqId;
    }

    /// @notice Called by the Functions router when the request is fulfilled
    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        require(requests[requestId].exists, "Request not found");

        requests[requestId].fulfilled = true;
        requests[requestId].response  = response;
        requests[requestId].err       = err;
        lastResponse = response;
        lastError    = err;

        string memory cityName = requestToCity[requestId];
        string memory tempStr  = string(response);
        uint256 idx = cityIndex[cityName];
        cities[idx].temperature = tempStr;
        cities[idx].timestamp   = block.timestamp;

        emit Response(requestId, tempStr, response, err);
    }

    // ========== Insurance Logic ==========
    /// @notice Deposit ETH to take out a policy
    function depositInsurance(
        string memory _name,
        uint256 _age,
        string memory _addr
    ) external payable {
        require(msg.value > 2 wei, "Min 2 wei deposit");
        insuranceBalance[msg.sender] = User(_name, _age, _addr, msg.value);
    }

    /// @notice Claim back your deposit if the city’s temp > 40°C and data is fresh
    function claimInsurance(string memory _city) external {
        User storage u = insuranceBalance[msg.sender];
        require(u.InsuranceAmount > 0, "No active policy");

        uint256 idx = cityIndex[_city];
        require(idx < cities.length, "Unknown city");
        uint256 ts = cities[idx].timestamp;
        require(block.timestamp - ts <= 1 days, "Data expired");

        int256 tempVal = _parseInt(cities[idx].temperature);
        require(tempVal > 40, "Temp is 40 C");

        uint256 payout = u.InsuranceAmount;
        u.InsuranceAmount = 0;
        payable(msg.sender).transfer(payout);
    }

    /// @dev Simple integer parser (ignores decimals)
    function _parseInt(string memory s) internal pure returns (int256) {
        bytes memory b = bytes(s);
        int256 val;
        for (uint i = 0; i < b.length; i++) {
            bytes1 char = b[i];
            if (char >= bytes1('0') && char <= bytes1('9')) {
                val = val * 10 + (int256(uint8(char)) - 48);
            } else {
                break;
            }
        }
        return val;
    }

    // ========== Helpers ==========
    function getCity(string memory _city) external view returns (CityStruct memory) {
        return cities[cityIndex[_city]];
    }
    function listAllCities() external view returns (CityStruct[] memory) {
        return cities;
    }
    function listCities(uint start, uint end) external view returns (CityStruct[] memory) {
        require(start <= end && end < cities.length, "Bad range");
        CityStruct[] memory out = new CityStruct[](end - start + 1);
        for (uint i = start; i <= end; i++) {
            out[i - start] = cities[i];
        }
        return out;
    }
}

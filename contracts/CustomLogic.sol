// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_3_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/dev/v1_X/libraries/FunctionsRequest.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

contract Insurance is FunctionsClient, AutomationCompatibleInterface {
    using FunctionsRequest for FunctionsRequest.Request;

    address public owner;
    bytes32 public lastRequestId;
    bytes public lastResponse;
    bytes public lastError;

    int public temperatureThreshold = 40;
    uint256 public immutable interval;
    uint256 public lastTimeStamp;

    struct User {
        string Name;
        uint256 Age;
        string Address;
        uint InsuranceAmount;
        bool HasClaimed;
        string City;
    }

    mapping(address => User) public insuranceBalance;
    address[] public insuredUsers;

    constructor(uint64 functionsSubscriptionId, uint256 updateInterval) FunctionsClient(router) {
        subscriptionId = functionsSubscriptionId;
        owner = msg.sender;
        interval = updateInterval;
        lastTimeStamp = block.timestamp;
    }

    struct RequestStatus {
        bool fulfilled;
        bool exists;
        bytes response;
        bytes err;
    }

    mapping(bytes32 => RequestStatus) public requests;
    bytes32[] public requestIds;

    event Response(bytes32 indexed requestId, string temperature, bytes response, bytes err);
    event InsuranceClaimed(address indexed user, uint256 amount, string city, string temperature);

    address router = 0xA9d587a00A31A52Ed70D6026794a8FC5E2F5dCb0;
    bytes32 donID = 0x66756e2d6176616c616e6368652d66756a692d31000000000000000000000000;
    uint32 gasLimit = 300000;
    uint64 public subscriptionId;

    string public source =
        "const city = args[0];"
        "const apiResponse = await Functions.makeHttpRequest({"
        "url: `https://wttr.in/${city}?format=3&m`,"
        "responseType: 'text'"
        "});"
        "if (apiResponse.error) {"
        "throw Error('Request failed');"
        "}"
        "const { data } = apiResponse;"
        "const tempMatch = data.match(/[+-]?\\d+(\\.\\d+)?/);"
        "if (!tempMatch) {"
        "throw Error('Temperature not found in response');"
        "}"
        "return Functions.encodeString(tempMatch[0]);";

    string public lastCity;
    string public lastTemperature;

    struct CityStruct {
        address sender;
        uint timestamp;
        string name;
        string temperature;
        int temperatureValue;
    }

    CityStruct[] public cities;
    mapping(string => uint256) public cityIndex;
    mapping(bytes32 => string) public request_city;

    function getTemperature(string memory _city) external returns (bytes32 requestId) {
        string ;
        args[0] = _city;

        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(source);
        req.setArgs(args);

        lastRequestId = _sendRequest(req.encodeCBOR(), subscriptionId, gasLimit, donID);

        lastCity = _city;
        request_city[lastRequestId] = _city;

        CityStruct memory auxCityStruct = CityStruct({
            sender: msg.sender,
            timestamp: 0,
            name: _city,
            temperature: "",
            temperatureValue: 0
        });

        cities.push(auxCityStruct);
        cityIndex[_city] = cities.length - 1;

        requests[lastRequestId] = RequestStatus({
            exists: true,
            fulfilled: false,
            response: "",
            err: ""
        });

        requestIds.push(lastRequestId);
        return lastRequestId;
    }

    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {
        require(requests[requestId].exists, "request not found");

        lastError = err;
        lastResponse = response;

        requests[requestId].fulfilled = true;
        requests[requestId].response = response;
        requests[requestId].err = err;

        string memory auxCity = request_city[requestId];
        lastTemperature = string(response);

        int temperatureValue = parseTemperature(lastTemperature);

        cities[cityIndex[auxCity]].temperature = lastTemperature;
        cities[cityIndex[auxCity]].timestamp = block.timestamp;
        cities[cityIndex[auxCity]].temperatureValue = temperatureValue;

        emit Response(requestId, lastTemperature, lastResponse, lastError);
    }

    function parseTemperature(string memory temp) internal pure returns (int) {
        bytes memory tempBytes = bytes(temp);
        bool isNegative = false;
        uint startPos = 0;

        if (tempBytes.length > 0 && tempBytes[0] == '-') {
            isNegative = true;
            startPos = 1;
        }

        int result = 0;
        for (uint i = startPos; i < tempBytes.length; i++) {
            if (tempBytes[i] >= '0' && tempBytes[i] <= '9') {
                result = result * 10 + (int(uint8(tempBytes[i])) - 48);
            } else if (tempBytes[i] == '.') {
                break;
            }
        }

        return isNegative ? -result : result;
    }

    function DepositeInsuranceMoney(string memory _name, uint256 _age, string memory _address, string memory _city) public payable {
        require(msg.value > 0, "Deposit required");

        insuranceBalance[msg.sender] = User(_name, _age, _address, msg.value, false, _city);
        insuredUsers.push(msg.sender);

        getTemperature(_city);
    }

    function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;

        uint cityCount = cities.length;
        uint validCities = 0;

        for (uint i = 0; i < cityCount; i++) {
            if (
                block.timestamp - cities[i].timestamp <= 24 hours &&
                cities[i].temperatureValue > temperatureThreshold
            ) {
                validCities++;
            }
        }

        if (validCities > 0) {
            string[] memory eligibleCities = new string[](validCities);
            uint j = 0;
            for (uint i = 0; i < cityCount && j < validCities; i++) {
                if (
                    block.timestamp - cities[i].timestamp <= 24 hours &&
                    cities[i].temperatureValue > temperatureThreshold
                ) {
                    eligibleCities[j] = cities[i].name;
                    j++;
                }
            }
            performData = abi.encode(eligibleCities);
        }
    }

    function performUpkeep(bytes calldata performData) external override {
        if ((block.timestamp - lastTimeStamp) > interval) {
            lastTimeStamp = block.timestamp;

            string[] memory eligibleCities = abi.decode(performData, (string[]));

            for (uint i = 0; i < eligibleCities.length; i++) {
                string memory city = eligibleCities[i];
                uint256 cityIdx = cityIndex[city];

                for (uint j = 0; j < insuredUsers.length; j++) {
                    address user = insuredUsers[j];
                    User storage u = insuranceBalance[user];

                    if (
                        !u.HasClaimed &&
                        keccak256(bytes(u.City)) == keccak256(bytes(city)) &&
                        u.InsuranceAmount > 0
                    ) {
                        uint256 amount = u.InsuranceAmount;
                        u.HasClaimed = true;

                        (bool success, ) = payable(user).call{value: amount}("");
                        require(success, "Transfer failed");

                        emit InsuranceClaimed(user, amount, city, cities[cityIdx].temperature);
                    }
                }
            }
        }
    }

    function getUser(address addr) public view returns (string memory, uint256, string memory, uint256, bool, string memory) {
        User memory u = insuranceBalance[addr];
        return (u.Name, u.Age, u.Address, u.InsuranceAmount, u.HasClaimed, u.City);
    }

    function getCity(string memory city) public view returns (CityStruct memory) {
        return cities[cityIndex[city]];
    }

    function listAllCities() public view returns (CityStruct[] memory) {
        return cities;
    }

    function listCities(uint start, uint end) public view returns (CityStruct[] memory) {
        if (end >= cities.length) end = cities.length - 1;
        require(start <= end, "Invalid range");

        CityStruct[] memory sliced = new CityStruct[](end - start + 1);
        for (uint i = start; i <= end; i++) {
            sliced[i - start] = cities[i];
        }
        return sliced;
    }

    function withdrawFunds() public {
        require(msg.sender == owner, "Only owner can withdraw");
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    function setTemperatureThreshold(int newThreshold) public {
        require(msg.sender == owner, "Only owner can set threshold");
        temperatureThreshold = newThreshold;
    }

    receive() external payable {}
}

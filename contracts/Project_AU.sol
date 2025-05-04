// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
    function version() external view returns (uint256);
    function getRoundData(
        uint80 _roundId
    ) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

interface AutomationCompatibleInterface {
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);
  function performUpkeep(bytes calldata performData) external;
}

contract smart_manager {
    mapping (address => uint256) balances;
    AggregatorV3Interface internal dataFeed;
    // Remove the automation interface as we're not calling external automation
    int public lastSeenPrice;
    uint256 public count = 1;
    
    constructor() {
        dataFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        lastSeenPrice = getLatestPrice();
    }
    
    function deposite() public payable {
        require(msg.value > 0, "Sorry you don't have enough balance to Deposite");
        balances[msg.sender] = msg.value;
    }
    
    function withdraw() public payable {
        require(balances[msg.sender] > 0, "Sorry you are not allowed to withdraw");
        payable(msg.sender).transfer(balances[msg.sender]);
        balances[msg.sender] = 0; // Fixed: Setting balance to 0 directly
    }
    
    function balance() public view returns (uint256) {
        return balances[msg.sender];
    }
    
    function getDescription() public view returns (string memory) {
        return dataFeed.description();
    }
    
    function getLatestPrice() public view returns (int) {
        (
            /* uint80 roundID */,
            int price,
            /* uint startedAt */,
            /* uint timeStamp */,
            /* uint80 answeredInRound */
        ) = dataFeed.latestRoundData();
        return price;
    }
    
    function checkUpkeep(bytes calldata /*checkData*/) external view returns (bool upkeepNeeded, bytes memory performData) {
        int latestPrice = getLatestPrice();
        upkeepNeeded = latestPrice > lastSeenPrice;
        performData = abi.encode(latestPrice);
        return (upkeepNeeded, performData);
    }
    
    function performUpkeep(bytes calldata performData) external {
        int latestPrice = getLatestPrice();
        
        // Check if the latest price is higher than the last seen price
        if (latestPrice > lastSeenPrice) {
            // Update the counter first
            count += 1;
            
            // Then update the last seen price
            lastSeenPrice = latestPrice;
        }
    }
}
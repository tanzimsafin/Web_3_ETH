// SPDX-License-Identifier: MIT  
pragma solidity 0.8.19;

import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

contract CustomLogic is AutomationCompatibleInterface {

    uint256 public counter;  
    uint256 public immutable interval;  
    uint256 public lastTimeStamp;

    constructor(uint256 updateInterval) {  
        interval = updateInterval;  
        lastTimeStamp = block.timestamp;

        counter = 0;  
    }

    function checkUpkeep(  
        bytes calldata /* checkData */  
    )  
        external  
        view  
        override  
        returns (bool upkeepNeeded, bytes memory)  
    {  
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;  
    }

    function performUpkeep(bytes calldata) external override {  
        if ((block.timestamp - lastTimeStamp) > interval) {  
            lastTimeStamp = block.timestamp;  
            counter = counter + 1;  
        }  
    }  
}
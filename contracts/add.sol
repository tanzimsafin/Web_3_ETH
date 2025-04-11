// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Sum {
    uint public sum;
    constructor(){
        sum=0;
    }

    function add(uint256 a, uint256 b) public {
        sum = a + b;
    }

    // View function to get the sum
    function getSum() public view returns (uint256) {
        return sum;
    }
}
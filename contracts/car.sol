
import  "/contracts/vehicle.sol";
// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;
contract Car is vehicle{
    uint256 public numberOfDoors;
    constructor(string memory _brand,uint256 _numberOfDoors) vehicle(_brand){
         numberOfDoors=_numberOfDoors;
    }
    function description() public  pure override returns(string memory){
        return "I am a Car";
    }
}
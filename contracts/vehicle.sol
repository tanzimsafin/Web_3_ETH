// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;
contract vehicle{
    string public  brand;
    constructor(string memory _brand){
         brand=_brand;
    }
    function description() public pure virtual returns(string memory){
        return "I am a vehicle";
    }

}
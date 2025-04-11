// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;
contract ProxyContract{
    // address owner_contract;
    address implementation;
    receive() external  payable {}
    constructor(){
    //   owner_contract=_owner;
    }
    function setImplementation(address _impl) public{
        implementation=_impl;
    }
    fallback() external  payable {
        (bool success,)=implementation.delegatecall(msg.data);
        require(success, "Delegatecall failed");
    }
       
    
}

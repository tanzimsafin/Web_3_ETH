// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

contract StakeETh {
    address owner;
    mapping(address=>uint256) Deposite_book;
    uint256 total_balance;
    constructor(){
        owner=msg.sender;
    }
    function Deposite() payable public {
        require(msg.value>0,"sorry insufficient balance ,transaction failed");
        Deposite_book[msg.sender]=msg.value;
        total_balance+=msg.value;
    }
    function Withdraw() payable public {
        require(Deposite_book[msg.sender]>0,"sorry you are authorized to pull your ETH");
        payable(msg.sender).transfer(Deposite_book[msg.sender]*2);
        total_balance+=msg.value;
    }
    function Total_balance() public view returns(uint256){
        return(total_balance);
    }
 }

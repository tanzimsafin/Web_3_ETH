// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

contract Donation { 
    address owner_address;
    uint256 total_donation;
    address[] donation_address_array;
    mapping (address=>uint)  donation_withdraw;
    mapping(address=>uint)  donation_tracking;
    constructor(){
       owner_address=msg.sender; 
    }
    modifier onlyOwner(){
        require(owner_address==msg.sender,"You are not the owner of this contract");
        _;
    }
    function donation_recieve(uint _donation_ammount) public {
        require(_donation_ammount > 0, "Donation amount must be greater than zero");
        donation_tracking[msg.sender]=_donation_ammount;
        donation_address_array.push(msg.sender);
        total_donation+=_donation_ammount;
    }
    function getTotalDonation() public view returns (uint256) {
      return total_donation;
    }
    function top_Donner_Donation() public view returns(address,uint){
        address top_donner;
        uint top_donnation=0;
        for(uint i=0;i<donation_address_array.length;i++){
              if(donation_tracking[donation_address_array[i]]>top_donnation){
                top_donner=donation_address_array[i];
                top_donnation=donation_tracking[donation_address_array[i]];
              } 
        }
        return (top_donner,top_donnation);
    }
    function withdraw() public  onlyOwner{
         require(total_donation>0,"Insufficient balance");
         donation_withdraw[owner_address]=total_donation;
         total_donation=0;
    }
    function getBalance() public view onlyOwner returns(uint256){
      return(donation_withdraw[owner_address]);
    }
}

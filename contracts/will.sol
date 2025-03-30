// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;
contract will_of_ETH{
    struct descendent{
        address descendent_add;
    }
    descendent  d1;
    uint lastSeen=block.timestamp;
    address owner;
    constructor(address recepient){
        d1.descendent_add=recepient;
        owner =msg.sender;
    }
    modifier  ownerOnly{
        require(msg.sender==owner,"You are not the owner");
        _;
    }
    function deposite() public payable {
       lastSeen=block.timestamp;
    }
    function changeRecipient(address _recipient) public payable ownerOnly{
           d1.descendent_add=_recipient;
    }
    function poked() public{
        lastSeen=block.timestamp;
    }
    function transfer() public payable {
       //uint desired_time=10*365*24*60*60;
       uint desired_time=10;
       require(block.timestamp - lastSeen > desired_time, "Owner has been active recently");
       payable(d1.descendent_add).transfer(address(this).balance);
       msg.value==0;
    }
}
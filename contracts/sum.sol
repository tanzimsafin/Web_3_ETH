// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;
contract sum{
       uint8 num=5;
       uint16 biggerNum=16;//unsigned number
       int numbers= -74 ;
       bool active=true;
       address owner=0x742d35Cc6634C0532925a3b844Bc454e4438f44e;
       string name="Tanzim Hossain Safin";
       uint current_val;
       constructor(uint _initial_val){
            current_val=_initial_val; //only run when deployed first time 
       }
       function add(uint256 val ) public{
           current_val+=val;
       }
       function sub(uint256 val ) public{
           current_val-=val;
       }
       function mul(uint256 val ) public{
           current_val*=val;
       }
       function div(uint256 val ) public{
           require(val!=0,"Value cannot be zero");
           current_val=current_val/val;
       }
       function getNum() public view returns (uint256){
          return current_val;
       }
}
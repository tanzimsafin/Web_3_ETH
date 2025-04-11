// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;
import "forge-std/Script.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract Presale_Contract is ERC20 {
    address owner_of_contract;
    uint target_fundRaised_ammount=5;
    uint256 presell_fund_raised;
    uint256 regular_sell;
    uint256 total_minted_token;
    mapping(address=>uint256) initial_contributor;
    mapping(address=>uint256) afterLaunc_token_buyers;

    constructor() ERC20("TAKA","TK")  {
        owner_of_contract=msg.sender;
    }
    //middleware logics
    modifier Initial_fundRaised_Only{
        require(presell_fund_raised/(10**decimals()) < target_fundRaised_ammount,"Sorry Initial Fund Raises is Closed");
        _;
    }
    modifier Initial_fundRaised_Completed{
        require(presell_fund_raised/(10**decimals())>=target_fundRaised_ammount,"sorry still token is not publicly launched ");
        _;
    }
    modifier OwnerOnly{
        require(msg.sender==owner_of_contract,"Sorry you are restricted!!");
        _;
    }
    function initial_contribute() public Initial_fundRaised_Only() payable {
         require(msg.value>0,"can not send tnx");
         initial_contributor[msg.sender]=msg.value;
         presell_fund_raised+=msg.value;
    }
    function token_buy() public payable {
        require(msg.value>0,"can not send tnx"); 
        afterLaunc_token_buyers[msg.sender]=msg.value;
        regular_sell+=msg.value;

    }
    function mintToken(uint _ammount) public OwnerOnly(){
       require(total_minted_token<1000000000000000,"Sorry can not mint more tokens");
        _mint(address(this),_ammount);
  
    } 
    function Claim_Token() public  Initial_fundRaised_Completed(){
        require(initial_contributor[msg.sender]>0 || afterLaunc_token_buyers[msg.sender]>0,"sorry you did not buy any token");
        require(total_minted_token>0,"Sorry still tokens are not minted");
        _transfer(address(this),msg.sender,100);
        initial_contributor[msg.sender]=0;
        afterLaunc_token_buyers[msg.sender]=0;
    }
    function totalCoin() public view returns(uint256){
        return totalSupply();
    }
    function initialETHCollection() public view returns(uint256){
        return (presell_fund_raised)/(10**decimals());
    }
    function withDrawMoney() public OwnerOnly(){
         uint256 contractBalance = address(this).balance; 
         require(contractBalance > 0 && contractBalance >= target_fundRaised_ammount, "No Ether available to withdraw");
         payable(owner_of_contract).transfer(contractBalance);
    }
}

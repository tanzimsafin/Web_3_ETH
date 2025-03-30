// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract CreateOwnToken is ERC20, Ownable {
    constructor() ERC20("Tanzim", "TS") Ownable(msg.sender){
          _mint(msg.sender,1000000000000000);
    }
    function mint (address to, uint amount) public onlyOwner{
        _mint(to,amount);
    }
}
// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;
interface Inter_Sum{
         function add(uint256 val ) external;
         function getNum() external view returns (uint256);
    }
contract  contract2 {
    function ProxyAdd(uint _val) public{
       Inter_Sum(0x7b96aF9Bd211cBf6BA5b0dd53aa61Dc5806b6AcE).add(_val);
    }
    function ProxygetNum() public view returns (uint256){
          return Inter_Sum(0x7b96aF9Bd211cBf6BA5b0dd53aa61Dc5806b6AcE).getNum();
       }
}
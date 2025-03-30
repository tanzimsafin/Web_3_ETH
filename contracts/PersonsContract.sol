// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;
contract Person{
    
    struct person{
        string name;
        uint32 age;
        address add;
    }
    person public p1;
    mapping (address=>person) public Personcontract; // if i want any other details with current address then this is the best way
    function setPerson(string memory _name,uint32 _age) public {
        p1.name=_name;
        p1.age=_age;
        p1.add= msg.sender;
    }
    function getPersonDetails() public view returns(string memory,uint32,address){
        return (p1.name,p1.age,p1.add);
    }
}
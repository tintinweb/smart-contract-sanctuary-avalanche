// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./Pauseable.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Enumerable.sol";
import "./ERC2981PerTokenRoyalties.sol";


contract DigitDonutsNFT is  ERC721Enumerable,ERC721URIStorage, Ownable, ERC2981PerTokenRoyalties  {

//start of variables
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    uint256 public TOTAL_NFT;
    uint256 public nftExpirySecs;
    uint256 public nodeFees;
    uint256 public timePrjLaunched;

    mapping(address => bool) public whiteListAddresses;

    string private baseURL;
    //owner is receiving address for baking fees and royalties
    //address private receivingAddress;
    uint256 private contractRoyalties = 1000; //10%

    bool public contractActive = false;
    
    //keeping track of Donuts expiry
    mapping(uint256 => uint256) public expiryTimeOf;

    constructor() ERC721("DigitDonuts", "DiDo") {
            TOTAL_NFT = 10000;
            baseURL = "http://digitdonuts.shop/metadata";
            nftExpirySecs = 60*(24*60*60); 
            nodeFees = 300000000000000000;
            timePrjLaunched = block.timestamp;
            contractActive = true;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, ERC721, ERC2981PerTokenRoyalties)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
       function _beforeTokenTransfer(address from,address to,uint256 tokenId) 
       internal override(ERC721, ERC721Enumerable) {
       super._beforeTokenTransfer(from, to, tokenId);
        }

        function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
        }

        function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
        }

    function setTotalNft(uint256 newTotal)  public onlyOwner
    {
            TOTAL_NFT = newTotal;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner { 
        baseURL = _baseURI;
        for (uint256 id = 0; id < TOTAL_NFT; id++) { 
        // issue: takes long time to update for more than 50 NFTs
        _setTokenURI(id, string(abi.encodePacked(baseURL, "/", Strings.toString(id), ".json")));
        }   
    }

    function mint(uint256 amount) external onlyOwner {
        require(this.totalSupply() + amount <= TOTAL_NFT, "All tokens minted");
        require(amount > 0 && amount <= 10000, "Invalid mint amount"); //max mint 10000 at one go
        
        //uint16[] memory tokenIds = new uint16[](amount);
        //address[] memory owners = new address[](amount);


        for (uint i = 0; i < amount; i++) {
            uint256 newItemId = _tokenIds.current();
            _mint(_msgSender(), newItemId);
            _setTokenURI(newItemId, string(abi.encodePacked(baseURL, "/", Strings.toString(newItemId), ".json")));
            _setTokenRoyalty(newItemId, owner(), contractRoyalties);
            expiryTimeOf[i] = block.timestamp + 5184000;
            _tokenIds.increment();
            //minted++;
         }

       // return newItemId;
    }

    function wlMintID(uint256 chosenID) external payable {
        require(contractActive, "Project Not Active, Please check discord.");
        require(whiteListAddresses[msg.sender], "Only Whitelisted");
        require(this.totalSupply() + 1 <= TOTAL_NFT, "All tokens minted");
        require(chosenID<= 9999, "Invalid number");
        require(block.timestamp <= timePrjLaunched + 172800, "WL Minting is over");
        
        //require(mintFees <= address(this).balance,"Cannot afford");
        (bool success,) = owner().call{value: 13*(10**17)}("");
        require(success, "Failed to send money");
        _mint(_msgSender(), chosenID);
        _setTokenURI(chosenID, string(abi.encodePacked(baseURL, "/", Strings.toString(chosenID), ".json")));
        _setTokenRoyalty(chosenID, owner(), contractRoyalties);
        expiryTimeOf[chosenID] = block.timestamp + 5184000; //60days shelf life
        //minted++;
    }

    function mintID(uint256 chosenID) external payable {
        //require(tx.origin == _msgSender(), "Only EOA");
        require(contractActive, "Project Not Active, Please check discord.");
        require(this.totalSupply() + 1 <= TOTAL_NFT, "All tokens minted");
        require(chosenID<= 9999, "Invalid number");
        //require(mintFees <= address(this).balance,"Cannot afford");
        (bool success,) = owner().call{value: 2*(10**18)}("");
        require(success, "Failed to send money");
        _mint(_msgSender(), chosenID);
        _setTokenURI(chosenID, string(abi.encodePacked(baseURL, "/", Strings.toString(chosenID), ".json")));
        _setTokenRoyalty(chosenID, owner(), contractRoyalties);
        expiryTimeOf[chosenID] = block.timestamp + 5184000; //60days shelf life
        //minted++;
    }
    //have to append tokenid
    function burn(uint256 tokenId) public onlyOwner{
        _burn(tokenId);
        //minted--;
    }

    function setContractActive(bool _active) public onlyOwner {
        contractActive = _active;
    }

    function payBakingFees(uint256 nftId) public payable {
        require(contractActive, "Project Not Active, Please check discord.");
        require(nodeFees <= msg.sender.balance, "Not Enough AVAX");
        
       (bool success,) = owner().call{value: nodeFees}("");
       expiryTimeOf[nftId] += nftExpirySecs; //(set duration in secs)
        require(success, "Failed to send money");
    }

    //Admin functions
    function extendExpiry(uint256 _seconds) external onlyOwner{ 
        //TODO: 
        for (uint i = 0; i < 10000; i++) {
            expiryTimeOf[i] += _seconds;
         }
    }

    function setBakingParams(uint256 _expirySecs, uint256 _bakingFees) external onlyOwner{
        nftExpirySecs = _expirySecs;
        nodeFees = _bakingFees;
    }

    function addToWhiteList(address _addr) external onlyOwner {
        whiteListAddresses[_addr] = true;
        //noFreeAddresses++;
    }
    

}
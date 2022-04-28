// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Pauseable.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Enumerable.sol";
import "./ERC2981PerTokenRoyalties.sol";


contract DigitDonutsNFT is  ERC721Enumerable,ERC721URIStorage, Ownable, ERC2981PerTokenRoyalties  {

//start of variables

    uint256 public TOTAL_NFT;
    uint256 public nftExpirySecs;
    uint256 public nodeFees;

    mapping(address => bool) public whiteListAddresses;

    string private baseURL;

    uint256 private contractRoyalties = 1000; //10%

    bool public contractActive = false;
    bool public wlActive = true;
    //keeping track of Donuts expiry
    mapping(uint256 => uint256) public expiryTimeOf;

    constructor() ERC721("DigitDonuts", "Donuts") {
            TOTAL_NFT = 10000;
            baseURL = "https://gateway.pinata.cloud/ipfs/QmdLC4yJ664V8cbLDBiinzMGUw6Kh6VhW6aJPcMQf8ACuV";
            nftExpirySecs = 60*(24*60*60); //60 days
            nodeFees = 200000000000000000;
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

    function setTotalNft(uint256 newTotal) public onlyOwner{
            TOTAL_NFT = newTotal;
    }

    function mint(uint256 chosenID) external onlyOwner {
        require(contractActive, "Project Not Active, Please check discord.");
        require(this.totalSupply() + 1 <= TOTAL_NFT, "All tokens minted");
        require(chosenID < TOTAL_NFT, "Invalid id");
        
        _mint(_msgSender(), chosenID);
        _setTokenURI(chosenID, string(abi.encodePacked(baseURL, "/", Strings.toString(chosenID), ".json")));
        _setTokenRoyalty(chosenID, owner(), contractRoyalties);
        expiryTimeOf[chosenID] = block.timestamp + 5184000; //60days shelf life 
    
    }

    function mintID(uint256 chosenID) external payable {
        //require(tx.origin == _msgSender(), "Only EOA");
        require(contractActive, "Project Not Active, Please check discord.");
        require(this.totalSupply() + 1 <= TOTAL_NFT, "All tokens minted");
        require(chosenID< TOTAL_NFT, "Invalid id");

        if (wlActive && whiteListAddresses[msg.sender])
        {
            (bool success,) = owner().call{value: 13*(10**17)}("");
            require(success, "Failed to send money");
            _mint(_msgSender(), chosenID);
            _setTokenURI(chosenID, string(abi.encodePacked(baseURL, "/", Strings.toString(chosenID), ".json")));
            _setTokenRoyalty(chosenID, owner(), contractRoyalties);
            expiryTimeOf[chosenID] = block.timestamp + 5184000; //60days shelf life 
        }
        else
        {
            (bool success,) = owner().call{value: 2*(10**18)}("");
            require(success, "Failed to send money");
            _mint(_msgSender(), chosenID);
            _setTokenURI(chosenID, string(abi.encodePacked(baseURL, "/", Strings.toString(chosenID), ".json")));
            _setTokenRoyalty(chosenID, owner(), contractRoyalties);
            expiryTimeOf[chosenID] = block.timestamp + 5184000; //60days shelf life
        }
    }
   
    function burn(uint256 tokenId) public onlyOwner{
        _burn(tokenId);

    }

    function payBakingFees(uint256 nftId) public payable {
        require(contractActive, "Project Not Active, Please check discord.");
        require(nodeFees <= msg.sender.balance, "Not Enough AVAX");
        
        (bool success,) = owner().call{value: nodeFees}("");
        require(success, "Failed to send money");

        //Checks if expiry time is already expired  
        if (expiryTimeOf[nftId] > block.timestamp) //if not, add on.
            {
            expiryTimeOf[nftId] += nftExpirySecs;
            }
        else        //if so, start from now.
            {
            expiryTimeOf[nftId] = block.timestamp + nftExpirySecs; //(set duration in secs)
            }
        //updates the tokenuri too
        _setTokenURI(nftId, string(abi.encodePacked(baseURL, "/", Strings.toString(nftId), ".json")));
          
    }


    /**
    Admin functions
    **/

    function setBaseURI(string memory _baseURI) external onlyOwner { 
        baseURL = _baseURI;
    }

    function setBakingParams(uint256 _numDaysExtension, uint256 _bakingFees) external onlyOwner{
        nftExpirySecs = _numDaysExtension * (24*60*60);
        nodeFees = _bakingFees;
    }

    function setContractActive(bool _active) public onlyOwner {
        contractActive = _active;
    }

    function setWLActive(bool _active) public onlyOwner {
        wlActive = _active;
    }

    function setWhiteList(address _addr, bool _bool) external onlyOwner {
        whiteListAddresses[_addr] = _bool;
    }

    

}
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "Address.sol";
import "Context.sol";
import "ERC165.sol";
import "ERC721.sol";
import "IERC165.sol";
import "IERC721.sol";
import "IERC721Metadata.sol";
import "IERC721Receiver.sol";
import "Strings.sol";


contract AEGen0 is ERC721("AlterEgo Punks","AE"){
    // Metadata Server URL
    string private _uri;

    //contract owner / admin
    address private _owner;

    // Authorized contracts or addresses for minting of tokens not for sale
    // IE, dropping the current tokens

    mapping(address => bool) _authorizedMinters;

    // Overall and cap for each type
    uint256 CAP=1000;
    uint256 DROP_CAP=691;
    uint256[] CAP_BY_TYPE=[800,100,100];
    uint256 constant TYPES=3;

    // tokens sold overall and by type incl prev sold ones for gen 0   
    uint256 _totalSupply=691;
    uint256[] mintedByType=[564,63,64];

    // did we already mint with this new contract
    bool mintedNew=false;

    //Price for public mint;
    uint256[] PRICE_BY_TYPE=[0.25 ether,0.5 ether, 0.75 ether];

    uint256 TIERS=3;

    //curent Token ID
    uint256[] _currentTokenId=[692,928,965];
    
    // tier of each token
    mapping(uint256 => uint256) _tokenTier;

    //track tokens dropped to old owners
    mapping(uint256 => bool) _dropped;

    //Sale startdate, if not set sale disallowed
    uint256 _saleStartTime;
    bool _saleActive=true;

    event Mint(uint256 id,uint256 tier,address addr);

    modifier onlyOwner{
        require(_msgSender()==_owner,"Function restricted to owner");
        _;
    }

    modifier onlyMinters(){
        require(_authorizedMinters[_msgSender()],"Restricted to minters");
        _;
    }

    modifier authorizedMinter(){
        require(_authorizedMinters[_msgSender()],"Not allowed to mint");
        _;
    }

    modifier saleActive(){
        require(block.timestamp>=_saleStartTime||_msgSender()==_owner,"Sale not started");
        require(_saleActive,"Sales paused");
        _;
    }

    constructor(string memory url){
        _uri=url;
        _authorizedMinters[_msgSender()]=true;
        _owner=_msgSender();   
    }

    // use the url set in constructors as base for token urls
    function _baseURI() override internal view virtual returns (string memory) {
        return _uri;
    }

    // admin functions
    function pauseSales() public onlyOwner {
        _saleActive=false;
    }

    function resumeSales() public onlyOwner{
        _saleActive=true;
    }

    function setStartDate(uint256 timestamp) public onlyOwner{
        //only allow moving the date if we havent sold tokens or we didnt set a date
        require(!mintedNew || timestamp==0,"There is tokens already sold , cant move date");
        // disallow unsetting date
        require(timestamp>0,"Invalid null date");
        // Only future dates
        require(timestamp>block.timestamp,"Date cant be in the past");

        // set date
        _saleStartTime=timestamp; 
    }

    function totalSupply() public view returns(uint256 supply){
        return _totalSupply;
    } 

    function supplyByType(uint256 tokenType) public view returns (uint256 supply){
        return mintedByType[tokenType];
    }

    function tokenTier(uint256 id) public view  returns (uint256 tier){
        return _tokenTier[id];
    } 
    function isMinted(uint256 id) public view returns (bool minted){
        return _dropped[id] || (id> DROP_CAP && id<=_totalSupply); 
    }

    function dropTokens(address recipient,uint256[] memory tokensIDs,uint256[] memory tiers) public onlyMinters{
       for(uint256 i;i<tokensIDs.length;i++){
           uint256 id=tokensIDs[i];
           require(id<DROP_CAP,"Can only drop existing tokens");
           require(!_dropped[id],"Token already dropped");
           require(tiers[id]<TIERS,"invalid tier");
           _safeMint(recipient,id,"");
           _tokenTier[id]=tiers[id];
           _dropped[id]=true;
       }
    }
    function buyNFT(uint256 tokenType) public payable saleActive {
        require(_totalSupply<=CAP,"All tokens sold out");
        require(tokenType<TYPES,"Invalid Type");
        require(msg.value==PRICE_BY_TYPE[tokenType],"Invalid amount sent");
        require(mintedByType[tokenType]<CAP_BY_TYPE[tokenType],"Tier of token sold out");
        uint256 tokenId=_currentTokenId[tokenType];
        if(!mintedNew){
            mintedNew=true;
        }
        _tokenTier[tokenId]=tokenType;
        mintedByType[tokenType]+=1;
        _totalSupply+=1;
        _currentTokenId[tokenType]=tokenId+1;
        _safeMint(msg.sender,tokenId,"");
        payable(_owner).transfer(address(this).balance);
        emit Mint(tokenId,tokenType,msg.sender);
    }
}
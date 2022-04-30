// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./IERC721.sol";

import "./ERC721A.sol";

pragma solidity >=0.7.0 <0.9.0;

contract CastleNFT is ERC721A, Ownable {
  using Strings for uint256;

  string baseURI;
  string public baseExtension = ".json"; 

  uint256 public public_mint_price = 1 ether ;// 1 ether --> 10**18
  uint256 public wl_mint_price = 0.7 ether ;// 0.7 Avax

  uint256 public maxSupply = 20; 
  uint256 public Wl_max = 5;   
  uint256 public team_reserved = 0;
  
      
  uint256 public mint_per_wallet = 10;
  uint256 public maxMintAmount = 5; 
  uint256 public WLmaxMintAmount = 2;  
  uint256 private reservedNFT; 

  uint256 public mint_stage = 2 ; // 0-pause || 1-wl mint ||2-public mint
  address private company_wallet = 0x65d024B7AD40b6b171acDf2fA2D64254b3c476Da; 
  address private c_wallet = 0x5dafa64bB7cb9f8B0eBa7Fa5e52e8CE49d319466; 
 

  bool public revealed = false; 
  string public notRevealedUri;

  mapping(address => bool) public whitelist;

  event WLAddressAdded(address addr);       
  event WLAddressRemoved(address addr);    

  mapping (address=>uint256) reservations; 

  constructor(
    string memory _name, 
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri
  ) ERC721A(_name, _symbol) {   
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function tokenURI(uint256 tokenId)  
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    
    if(revealed == false) {
        return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

 /***************************  Mints *************************/

  function publicMint(uint256 numTokens) external payable onlyOrigin { // public mint 
  if(numTokens > 0) {   
    require(totalSupply() + numTokens <= maxSupply - (team_reserved + Wl_max), "Mint Amount Exceeds Total Allowed Mints");
    require(_numberMinted(msg.sender) + numTokens < mint_per_wallet + 1,"You are exceeding your minting limit");
    require(mint_stage == 2, "LuckyDao Public Mint Not Active");
    require(numTokens <= maxMintAmount, "Requested Mint Amount Exceeds Limit Per Tx");
    require(public_mint_price * numTokens <= msg.value,  "Incorrect Payment");

    _safeMint(msg.sender, numTokens);
  }
  else{
    revert("You must mint at least one token.");
  }
  }

  function WLMint(uint256 numTokens) external payable onlyOrigin onlyWhitelisted { // whitelist mint
    if(numTokens > 0){
      if (mint_stage == 1){
        require(totalSupply() + numTokens <= Wl_max, "Mint Amount Exceeds Total Allowed Mints");
        require(_numberMinted(msg.sender) + numTokens < mint_per_wallet + 1,"You are exceeding your minting limit");
        require(numTokens <= WLmaxMintAmount, "Requested Mint Amount Exceeds Limit Per Tx");
        require(wl_mint_price * numTokens <= msg.value,  "Incorrect Payment");
        //require(whitelist[msg.sender] == true, "You are not whitelist.");
      _safeMint(msg.sender, numTokens);
      }
      else{
        revert("LuckyDao Whitelist Mint Not Active");
      }
    }
    else{
      revert("You must mint at least one token.");
    }
  }

  /************************** Only owner ******************************************/

  function ReservedMint(address reserved_addresses, uint256 numTokens) external onlyOwner {   
    require(reservedNFT + numTokens <= team_reserved, "Reserved exceeded!");
    reservedNFT += numTokens;
    _safeMint(reserved_addresses, numTokens);
  }

  function addAddressToWhitelist(address addr) onlyOwner public returns(bool success) { 
    if (!whitelist[addr]) {
      whitelist[addr] = true;
      emit WLAddressAdded(addr);
      success = true;
    }
  }

  function addAddressesToWhitelist(address[] calldata addrs) onlyOwner public returns(bool success) { 
    for (uint256 i = 0; i < addrs.length; i++) {
      if (addAddressToWhitelist(addrs[i])) {
        success = true;
      }
    }
  }

  function removeAddressFromWhitelist(address addr) onlyOwner public returns(bool success) { 
    if (whitelist[addr]) {
      whitelist[addr] = false;
      emit WLAddressRemoved(addr);
      success = true;
    }
  }

  function removeAddressesFromWhitelist(address[] calldata addrs) onlyOwner public returns(bool success) {
    for (uint256 i = 0; i < addrs.length; i++) {
      if (removeAddressFromWhitelist(addrs[i])) {
        success = true;
      }
    }
  }

  function setMintStage(uint256 newStage) external onlyOwner { 
    require(newStage < 3, "Unsupported mint stage"); 
    mint_stage = newStage;
  }

  function reveal() public onlyOwner() {  
      revealed = true;
  }
  
  function setPublicCost(uint256 _newCost) public onlyOwner() {  
    public_mint_price = _newCost;
  }

    function setWLCost(uint256 _newCost) public onlyOwner() {  
    wl_mint_price = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner() { 
    maxMintAmount = _newmaxMintAmount;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {  
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {  
    baseExtension = _newBaseExtension;
  }

 /**************** Withdraw **************/ 

  function withdraw(address _address, uint256 _amount) private {
    (bool success, ) = _address.call{value: _amount}("");
    require(success, "Transfer failed.");
  }

    function withdrawAll() external onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0);

    withdraw(company_wallet, (balance*40)/100);
    withdraw(c_wallet, (balance*60)/100);


    withdraw(owner(), address(this).balance);
    // withdraw(company_wallet, address(this).balance);
  }

  /************************ Modifier *****************************/

  modifier onlyOrigin() {   
    require(msg.sender == tx.origin, "You must be origin!...");
    _;
  }

  modifier onlyWhitelisted() {    
    require(whitelist[msg.sender],"You are not Whitelist!");
    _;
  }
  /**************************************************************/
}
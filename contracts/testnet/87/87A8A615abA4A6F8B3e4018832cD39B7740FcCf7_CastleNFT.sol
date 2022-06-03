// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./IERC2981Royalties.sol";
import "./ERC721A.sol";

pragma solidity >=0.7.0 <0.9.0;

contract CastleNFT is ERC721A, IERC2981Royalties, Ownable {
  
  using Strings for uint256;

  struct RoyaltyInfo {
    address recipient;
    uint24 amount;
  }

  RoyaltyInfo private _royalties;

  string baseURI;
  string public baseExtension = ".json"; 

  uint256 public publicMintPrice = 0.5 ether ;
  uint256 public wlMintPrice  = 0.3 ether ; 

  uint256 public maxSupply = 40; // total NFT
  uint256 public teamReserved_airdrop = 15; 
      
  uint256 public WLPerWallet = 6; // mint limit per wallet for wl sale
  uint256 public maxMintAmount = 4; 
  uint256 public WLmaxMintAmount = 2;  
  uint256 private reservedNFT;  // reserved NFT  

  uint256 public mintStage = 0 ; // 0-pause || 1-wl mint ||2-public mint

  mapping(address => bool) public whitelist;

  event WLAddressAdded(address addr);       
  event WLAddressRemoved(address addr);    

  mapping (address=>uint256) reservations; 

  address private company_wallet = 0x65d024B7AD40b6b171acDf2fA2D64254b3c476Da; 
  address private c_wallet = 0x5dafa64bB7cb9f8B0eBa7Fa5e52e8CE49d319466;

  constructor(
    string memory _name, 
    string memory _symbol,
    string memory _initBaseURI
  ) ERC721A(_name, _symbol) {   
    setBaseURI(_initBaseURI);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IERC2981Royalties).interfaceId || super.supportsInterface(interfaceId);
  }

  function _setRoyalties(address recipient, uint256 value) internal {
    require(value <= 10000, "ERC2981Royalties: Too high");
    _royalties = RoyaltyInfo(recipient, uint24(value));
  }

  function royaltyInfo(uint256, uint256 value) external view override returns (address receiver, uint256 royaltyAmount) {
    RoyaltyInfo memory royalties = _royalties;
    receiver = royalties.recipient;
    royaltyAmount = (value * royalties.amount) / 10000;
  }

 /***************************  Mints *************************/

  function publicMint(uint256 numTokens) external payable onlyOrigin { // public mint 
    if(numTokens > 0) {   
      require(totalSupply() + numTokens <= maxSupply - teamReserved_airdrop, "Mint Amount Exceeds Total Allowed Mints");
      require(mintStage == 2, "Public Mint Not Active");
      require(numTokens <= maxMintAmount, "Requested Mint Amount Exceeds Limit Per Tx");
      require(publicMintPrice * numTokens <= msg.value,  "Incorrect Payment");

      _safeMint(msg.sender, numTokens);
    }
    else{
      revert("You must mint at least one token.");
    }
  }

  function WLMint(uint256 numTokens) external payable onlyOrigin onlyWhitelisted { // whitelist mint
    if(numTokens > 0){
      if (mintStage == 1){
        require(totalSupply() + numTokens <= maxSupply - teamReserved_airdrop, "Mint Amount Exceeds Total Allowed Mints");
        require(_numberMinted(msg.sender) + numTokens < WLPerWallet + 1,"You are exceeding your minting limit");
        require(numTokens <= WLmaxMintAmount, "Requested Mint Amount Exceeds Limit Per Tx");
        require(wlMintPrice * numTokens <= msg.value,  "Incorrect Payment");
      _safeMint(msg.sender, numTokens);
      }
      else{
        revert("Whitelist Mint Not Active");
      }
    }
    else{
      revert("You must mint at least one token.");
    }
  }
  
  /************************** Only owner ******************************************/

  function ReservedMint(address reserved_addresses, uint256 numTokens) external onlyOwner {   
    require(reservedNFT + numTokens <= teamReserved_airdrop, "Reserved exceeded!");
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
    mintStage = newStage;
  }
  
  function setPublicCost(uint256 _newCost) public onlyOwner() {  
    publicMintPrice  = _newCost;
  }

    function setWLCost(uint256 _newCost) public onlyOwner() {  
    wlMintPrice  = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner() { 
    maxMintAmount = _newmaxMintAmount;
  }
    function setWLPerWallet(uint256 _newWLPerWallet) public onlyOwner() { 
    WLPerWallet = _newWLPerWallet;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {  
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {  
    baseExtension = _newBaseExtension;
  }
  
  function setRoyalties(address recipient, uint256 value) public onlyOwner {
    _setRoyalties(recipient, value);
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
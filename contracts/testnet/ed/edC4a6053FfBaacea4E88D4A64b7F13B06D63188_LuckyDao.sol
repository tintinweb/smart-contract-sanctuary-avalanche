// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./IERC721.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

pragma solidity >=0.7.0 <0.9.0;

contract LuckyDao is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;

  string baseURI;
  string public baseExtension = ".json"; // dosyalardan okuanacak bilgiler abi, name, symbol, chain bilgi

  uint256 public public_mint_price = 1 ether ;// 1 ether --> 10**18
  uint256 public wl_mint_price = 0.5 ether ;// 0.5 Avax

  uint256 public maxSupply = 5555; // toplam nft sayısı
  uint256 public Wl_max = 20;       // toplam wl mint edilecek nft
  uint256 public team_reserved = 30; // takıma verilecek nft
      
  uint256 public maxMintAmount = 5; // public mint tek seferde max mint sayısı
  uint256 public mint_per_wallet = 10; // bir cüzdanın mint etme limiti
  uint256 public WLmaxMintAmount = 9;  // wl tek seferde max mint
  uint256 private reservedNFT; 

  uint256 public mint_stage = 0 ; // 0-pause || 1-wl mint ||2-public mint
  address private company_wallet =0x23c130734cD604b806D0E07651Fa3b0ac9983433; // şirketin cüzdanlarıyla değiştir (deneme amaçlı kendi cüzdanım)
  // address private company_wallet1 =0x23c130734cD604b806D0E07651Fa3b0ac9983433; 
  // address private company_wallet2 =0x23c130734cD604b806D0E07651Fa3b0ac9983433; 


  bool public revealed = false;  // dünyaya açma
  string public notRevealedUri;

  mapping(address => bool) public whitelist; // whitelist adresleri tutuyor

  event WLAddressAdded(address addr);        // whitelist ekleme olayı
  event WLAddressRemoved(address addr);     // whitelist çıkarma olayı

  mapping (address=>uint256) reservations;  // takıma reserve edilen toplam nft sayısını tutuyor

  constructor(
    string memory _name,  // bu değerleri sözleşmeyi deploy etmeden gir
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri
  ) ERC721A(_name, _symbol) {   // Nftyi Erc721A sözleşmesinde tanımlıyor 
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

 // mint işlemi yapılacak wl,public and team için

 /*************************** Tüm mint işlemleri *************************/

  function publicMint(uint256 numTokens) external payable onlyOrigin nonReentrant { // public mint 
  if(numTokens > 0) {   
    require(totalSupply() + numTokens <= maxSupply - (team_reserved + Wl_max), "Mint Amount Exceeds Total Allowed Mints");
    require(mint_stage == 2, "LuckyDao Public Mint Not Active");
    require(numTokens <= maxMintAmount, "Requested Mint Amount Exceeds Limit Per Tx");
    require(public_mint_price * numTokens <= msg.value,  "Incorrect Payment");

    _safeMint(msg.sender, numTokens);
  }
  else{
    revert("You must mint at least one token.");
  }
  }

  function WLMint(uint256 numTokens) external payable onlyOrigin onlyWhitelisted nonReentrant { // whitelist mint
    if(numTokens > 0){
      if (mint_stage == 1){
        require(totalSupply() + numTokens <= Wl_max , "Mint Amount Exceeds Total Allowed Mints");
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

 // Whitelist ekle çıkar fonksiyonları olacak (array tanımlama mantığına solidity de bak +
 // whitelist array olarak tanımla ve adressleri o arraya eklesin wl kontrolü yaparak ona mint izni versin) +

  /************************** Sadece sözleşme sahibinin yapacağı işlemler ******************************************/

  function ReservedMint(address reserved_addresses, uint256 numTokens) external onlyOwner { // girilen adrese girilen sayı kadar nft dağıtılacak     
    require(reservedNFT + numTokens <= team_reserved, "Reserved exceeded!");
    reservedNFT += numTokens;
    _safeMint(reserved_addresses, numTokens);
  }

  function addAddressToWhitelist(address addr) onlyOwner public returns(bool success) { //whitelist ekleme
    if (!whitelist[addr]) {
      whitelist[addr] = true;
      emit WLAddressAdded(addr);
      success = true;
    }
  }

  function removeAddressFromWhitelist(address addr) onlyOwner public returns(bool success) { // whitelist çıkarma
    if (whitelist[addr]) {
      whitelist[addr] = false;
      emit WLAddressRemoved(addr);
      success = true;
    }
  }

  function setMintStage(uint256 newStage) external onlyOwner { // mint durumu belirle
    require(newStage < 3, "Unsupported mint stage"); // 3'ten küçük sayıları kabul et
    mint_stage = newStage;
  }

  function reveal() public onlyOwner() {  // dünyaya açmayı etkinleştir
      revealed = true;
  }
  
  function setPublicCost(uint256 _newCost) public onlyOwner() {  // public mint fiyat değiştir
    public_mint_price = _newCost;
  }

    function setWLCost(uint256 _newCost) public onlyOwner() {  // WL fiyat değiştir
    wl_mint_price = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner() { // max mint edebilme değiştir
    maxMintAmount = _newmaxMintAmount;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {    //nftlerin urlsini set et
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {   // json dosyasını set et
    baseExtension = _newBaseExtension;
  }

 /**************** Sözleşmedeki parayı cüzdana aktarma  **************/ 

 // 3 cüzdana bölüşülecek

  function withdraw(address _address, uint256 _amount) private {
    (bool success, ) = _address.call{value: _amount}("");
    require(success, "Transfer failed.");
  }

    function withdrawAll() external onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0);

    // withdraw(company_wallet, (balance*33)/100);
    // withdraw(company_wallet1, (balance*33)/100);
    // withdraw(company_wallet2, (balance*34)/100);

    // withdraw(owner(), address(this).balance);
    withdraw(company_wallet, address(this).balance);

  }

  /************************ Modifier *****************************/

  modifier onlyOrigin() {   // güvenli mint
    require(msg.sender == tx.origin, "Come on!!!");
    _;
  }

  modifier onlyWhitelisted() {    // Whitelist kotrolü
    require(whitelist[msg.sender],"You are not Whitelist!");
    _;
  }
  /**************************************************************/
}
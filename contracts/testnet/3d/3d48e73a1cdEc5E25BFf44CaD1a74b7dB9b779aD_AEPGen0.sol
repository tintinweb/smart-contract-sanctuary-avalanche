// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "Address.sol";
import "Ownable.sol";
import "Context.sol";
import "ERC721.sol";
import "IERC721.sol";
import "IERC721Metadata.sol";
import "IERC721Receiver.sol";
import "Pausable.sol";
import "SafeMath.sol";
import "Strings.sol";
import "IERC165.sol";
import "ERC165.sol";

/*
             ______   _____       _____   ______   _   _      ___  
     /\     |  ____| |  __ \     / ____| |  ____| | \ | |    / _ \ 
    /  \    | |__    | |__) |   | |  __  | |__    |  \| |   | | | |
   / /\ \   |  __|   |  ___/    | | |_ | |  __|   | . ` |   | | | |
  / ____ \  | |____  | |        | |__| | | |____  | |\  |   | |_| |
 /_/    \_\ |______| |_|         \_____| |______| |_| \_|    \___/ 

 
*/


contract AEPGen0 is Pausable, Ownable, ERC721 {

    using SafeMath for uint256;


    //contract name, symbol
    string public _name = "Alter Ego Punks";
    string public _symbol = "AEPG0";

  
    string public baseTokensURI;
    address private NFTsTransferWallet;

    constructor(string memory _baseTokensUri,address _NFTsTransferWallet) ERC721(_name, _symbol) {
        baseTokensURI = _baseTokensUri;
        NFTsTransferWallet = _NFTsTransferWallet;
        setMintedPartURI("part1");
    }

    //prices
    uint256 constant HumanPrice = 0.0025 ether;
    uint256 constant ZombiePrice = 0.005 ether;
    uint256 constant VampirePrice = 0.0075 ether;

    
    //existedPunksTokenIdStart
    uint256 public currentTokenId = 0;
    uint256 public oldTokensHumansLimit = 554;
    uint256 public oldTokensZombiesLimit = 63;
    uint256 public oldTokensVampiresLimit = 64;
    uint256 oldTokensSize = 681;
    

    // 681 minted already
    // 319 to be minted
    // 19 existed NFT to they will start from 682 token id and end at token id 700.
    // to be minter later range is from 701 to 1000 token id.


    //index for each tier
    uint256 public _humanTierIndexId = 0;
    uint256 public _zombieTierIndexId = 0;
    uint256 public _vampireTierIndexId = 0;

    //currnt supply to mint for each tier
    uint256 public _HumanCurrentSupply = 687;
    uint256 public _ZombieCurrentSupply = 72;
    uint256 public _VampireCurrentSupply = 72;

   
    enum TIER { 
        HUMAN,
        ZOMBIE, 
        VAMPIRE
    }

    struct TokenTierIndex {
        uint256 index;
        TIER tier; 
    }
    mapping(uint256 => TokenTierIndex) public tokenTierIndex;


    //save Punks NFT data
     struct Punk {
        uint256 tokenId;
        TIER tier;
    }

    //minters tokens
    mapping (address => Punk[]) public tokensOwner;
    //Daynamic URI Part to not lose the old tokens every time got minting
    string public mintedPart = "";
    string[] public allMintedParts;

    function setMintedPartURI(string memory name) public onlyOwner() {
        require(bytes(name).length != 0, "Part name is empty");
        mintedPart = name;
        allMintedParts.push(mintedPart);
    }

    function getMintedPartURI() public view returns (string memory) {
        string memory str = string(mintedPart);
        return str;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokensURI;
    }
  

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        require(tokenTierIndex[tokenId].index > 0, "index of token is not set");

        string memory tokenIndex = Strings.toString(tokenTierIndex[tokenId].index);
        TIER tier = tokenTierIndex[tokenId].tier;
        string memory tokenTier = "";
        if (TIER.HUMAN == tier) tokenTier = "human/";
        else if (TIER.VAMPIRE == tier) tokenTier = "vampire/";
        else if (TIER.ZOMBIE == tier) tokenTier =  "zombie/";
        string memory nextPart = string(abi.encodePacked(mintedPart, "/", tokenTier));
        string memory tokenPath = string(abi.encodePacked(nextPart,tokenIndex ,  ".json"));
        string memory tokenUri = string(abi.encodePacked(baseTokensURI, "/", tokenPath));
        return tokenUri;
    }

    /**
     * @dev increments the value of _currentTokenId
     */
    function incrementTokenId() private {
        currentTokenId++;
    }

    /**
     * @dev increments the index of the tier
     */
    function incrementAndGetTierIndex(TIER tier) private returns (uint256){
        if (TIER.HUMAN == tier) { 
            _humanTierIndexId++; 
            return _humanTierIndexId;
        }
        else if (TIER.VAMPIRE == tier) { 
            _vampireTierIndexId++;
            return _vampireTierIndexId;
        }
        else if (TIER.ZOMBIE == tier) { 
            _zombieTierIndexId++;
            return _zombieTierIndexId;
        }
        return 0;
    }



    /**
     * @dev Mints a token to an address with a tokenURI.
     * @param _to address of the future owner of the token
     */
    function mintTo(address _to,TIER tier) private {
        incrementTokenId();
        uint256 index = incrementAndGetTierIndex(tier);
        if(index == 0) revert();
        TokenTierIndex memory newTokenTierIndex;
        newTokenTierIndex.tier = tier;
        newTokenTierIndex.index = index;
        tokenTierIndex[currentTokenId] = newTokenTierIndex;
        _mint(_to, currentTokenId);
        //save minters tokens
        tokensOwner[_to].push(Punk(currentTokenId,tier));
    }


    //miniting new tokens by defualt is paused till old tokens minting finished
    bool public mintisLive = false;
    function setMintIsLive() public onlyOwner() {
        mintisLive = true;
    }

    function mintHumanNFT() public payable whenNotPaused {
        require(mintisLive == true, "Mint is not Live yet");
        require(_humanTierIndexId < _HumanCurrentSupply, "Human Supply Limit Reached");
        require(msg.value == HumanPrice, "Human Price is 0.25 AVAX");
        mintTo(_msgSender(),TIER.HUMAN);
        payable(NFTsTransferWallet).transfer(address(this).balance);
    }

    function mintZombieNFT() public payable whenNotPaused {
        require(mintisLive == true, "Mint is not Live yet");
        require(_zombieTierIndexId < _ZombieCurrentSupply, "Zombie Supply Limit Reached");
        require(msg.value == ZombiePrice, "ZOMBIE Price is 0.5 AVAX");
        mintTo(_msgSender(),TIER.ZOMBIE);
        payable(NFTsTransferWallet).transfer(address(this).balance);
    }

    function mintVampireNFT() public payable whenNotPaused {
        require(mintisLive == true, "Mint is not Live yet");
        require(_vampireTierIndexId < _VampireCurrentSupply, "Vampire Supply Limit Reached");
        require(msg.value == VampirePrice, "VAMPIRE Price is 0.75 AVAX");
        mintTo(_msgSender(),TIER.VAMPIRE);
        payable(NFTsTransferWallet).transfer(address(this).balance);
    }

    function setHumansSupply(uint256 newSupply) public onlyOwner(){
        _HumanCurrentSupply = newSupply;
    }

    function setZombiesSupply(uint256 newSupply) public onlyOwner(){
        _ZombieCurrentSupply = newSupply;
    }

    function setVampiresSupply(uint256 newSupply) public onlyOwner(){
        _VampireCurrentSupply = newSupply;
    }


   
    //mint old tokens one time to onw wallet to drop nfts later for old wls
    function mintOldHumansTokens(address toWallet,uint256 amount) public onlyOwner() {
        require( _humanTierIndexId <= oldTokensHumansLimit , "Old humans tokens Minted!");
        require( amount <= (oldTokensHumansLimit - _humanTierIndexId) , "amount is incorrect! or already minted");
        for(uint256 i=1; i <= amount; i++){
             mintTo(toWallet,TIER.HUMAN);
        }
    }

    function mintOldZombiesTokens(address toWallet,uint256 amount) public onlyOwner() {
        require( _zombieTierIndexId <= oldTokensZombiesLimit , "Old Zombies tokens Minted!");
        require( amount <= (oldTokensZombiesLimit - _zombieTierIndexId) , "amount is incorrect! or already minted");
        for(uint256 i=1; i <= amount; i++){
            mintTo(toWallet,TIER.ZOMBIE);
        }
    }

    function mintOldVampiresTokens(address toWallet,uint256 amount) public onlyOwner() { 
        require( _vampireTierIndexId <= oldTokensVampiresLimit , "Old Vampires tokens Minted!");
        require( amount <= (oldTokensVampiresLimit - _vampireTierIndexId) , "amount is incorrect! or already minted");
        for(uint256 i=1; i <= amount; i++){
           mintTo(toWallet,TIER.VAMPIRE);
        }
    }



    //only affect mintNFT fucntion
    function pauseContract() public onlyOwner {
        _pause();
    }

    function resumeContract() public onlyOwner {
        _unpause();
    }
}
/**
 *Submitted for verification at snowtrace.io on 2023-01-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Get a link to NFT contract
interface NFT {

  function mint(address to, uint256 id) external;
  function balanceOf(address owner) external view returns (uint256 balance);
  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
  function getApproved(uint256 tokenId) external view returns (address operator);
  function ownerOf(uint256 tokenId) external view returns (address owner);

}

// Get a link to BEP20 token contract
interface IBEP20Token {
    
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
}

/**
 * @title Lady Minter
 *
 * @author Avax Ladies
 */
contract LadyMinter {

  //---sell parameters---//  
  uint256 public nextId;
  uint256 public itemsSold;
  uint256 public price;
  uint256 public lastId;
  uint256 public dailyLimit;
  
  // Block timestamp of contract creation
  uint256 immutable launchTime;

  //---Set of addresses---// 
  address public admin;
  address public nftContract;

  //-----Dividend parameters-----//
  uint256 public reflectionBalance;
  uint256 public totalDividend;

  // Mapping from tokenId to last dividend claimed
  mapping (uint256 => uint256) public lastDividendAt;

  // Mapping from address to dailyPurchase counter
  mapping (address => mapping (uint256 => uint256)) public dailyPurchase;

  /**
	 * @dev Fired in initializeSell()
	 *
   * @param _by an address of owner who executes the function
	 * @param _mintPrice minting price in AVAX per Lady Minter
   * @param _nextId starting tokenId of Lady Minter
   * @param _lastId last tokenId of Lady Minter
   * @param _limit daily limit for an address to buy Lady
	 */
  event Initialize(
    address indexed _by,
    uint256 _mintPrice,
    uint _nextId,
    uint _lastId,
    uint _limit     
  );

  /**
	 * @dev Creates/deploys Avax Ladies MysteryBox Avax Version 1.0
	 *
	 * @param admin_ address of admin
   * @param nftContract_ address of Avax Ladies
	 */
  constructor(
      address admin_,
      address nftContract_
    )
  {
    //---Setup smart contract internal state---//
    admin = admin_;
    nftContract = nftContract_;
    launchTime = block.timestamp;
  }

  /**
	 * @dev Initialize sell parameters
	 *
   * @notice same function can be used to reinitialize parameters,
   *         arguments should be placed carefully for reinitialization/ 
   *         modification of sell parameter 
   *
	 * @param mintPrice_ minting price in AVAX per Lady Minter
   * @param nextId_ starting tokenId of Lady Minter
   * @param lastId_ last tokenId of Lady Minter
   * @param limit_ daily limit for an address to buy Lady Minter
	 */
  function initializeSell(uint256 mintPrice_, uint nextId_, uint lastId_, uint limit_)
    external
  {
    
    require(msg.sender == admin, "Avax Ladies: only admin can initialize sell");
    
    // Set up sell parameters
    price = mintPrice_;
    lastId = lastId_;
    nextId = nextId_;
    dailyLimit = limit_;

    // Emits an event
    emit Initialize(msg.sender, mintPrice_, nextId_, lastId_, limit_);
    
  }

  /**
	 * @dev Mints Avax Ladies NFTs by charging fixed price set by admin
	 * 
	 * @param amount_ number NFTs to buy
   */
  function mint(uint amount_) public payable {    
    
    require(msg.value >= price*amount_, "Avax Ladies: must send correct price");
    
    require(nextId + amount_ <= lastId + 1, "Avax Ladies: not enough ladies left");
    
    require(
      dailyPurchase[msg.sender][currentDay()] + amount_ <= dailyLimit,
      "Avax Ladies: daily limit crossed"
    );

    for(uint i=0; i < amount_; i++){
      // Mint an NFT
      NFT(nftContract).mint(msg.sender, nextId);
      // Update last dividend
      lastDividendAt[nextId] = totalDividend;
      // Increment nextId counter
      nextId++;
      // Increment sold counter
      itemsSold++;
      // Update daily purchase data
      dailyPurchase[msg.sender][currentDay()]++;
      // Distribute collected fee
      splitBalance(msg.value/amount_);
    }

  }
  
  /**
	 * @dev Returns current rate
	 */
  function currentRate() public view returns (uint256){
      if(itemsSold == 0) return 0;
      return reflectionBalance/itemsSold;
  }

  /**
	 * @dev Transfer pending rewards for all NFTs owned by sender
	 */
  function claimRewards() public {
    
    // Get NFT balance
    uint count = NFT(nftContract).balanceOf(msg.sender);
    
    // Record pending reward balance
    uint256 balance = 0;
    
    for(uint i=0; i < count; i++){
        uint tokenId = NFT(nftContract).tokenOfOwnerByIndex(msg.sender, i);
        balance += getReflectionBalance(tokenId);
        lastDividendAt[tokenId] = totalDividend;
    }
    
    // Transfer reward amount
    payable(msg.sender).transfer(balance);
  
  }
  
  /**
	 * @dev Returns total pending reward amount
	 */
  function getReflectionBalances() public view returns(uint256) {
    
    // Get NFT balance
    uint count = NFT(nftContract).balanceOf(msg.sender);
    
    // Record pending reward amount
    uint256 total = 0;
    
    for(uint i=0; i < count; i++){
        uint tokenId = NFT(nftContract).tokenOfOwnerByIndex(msg.sender, i);
        total += getReflectionBalance(tokenId);
    }
    
    return total;
  
  }

  /**
	 * @dev Transfer pending rewards for given NFT
   *
   * @param tokenId_ tokenId of given NFT
	 */
  function claimReward(uint256 tokenId_) public {
    
    require(
        NFT(nftContract).ownerOf(tokenId_) == msg.sender || NFT(nftContract).getApproved(tokenId_) == msg.sender,
        "Avax Ladies: only owner or approved can claim rewards"
    );
    
    // Get pending amount
    uint256 balance = getReflectionBalance(tokenId_);
    
    // Transfer amount
    payable(NFT(nftContract).ownerOf(tokenId_)).transfer(balance);
    
    // Update dividend data
    lastDividendAt[tokenId_] = totalDividend;
  
  }

  /**
	 * @dev Returns pending reward amount for given tokenId
	 */
  function getReflectionBalance(uint256 tokenId_) public view returns (uint256){
    return totalDividend - lastDividendAt[tokenId_];
  }

  /**
	 * @dev Splits given amount
   *
   * @param amount_ amount value
	 */
  function splitBalance(uint256 amount_) private {
    
    // Calculate dividend amount
    uint256 reflectionShare = (amount_ * 15) / 100;
    
    // Calculate leftover amount
    uint256 mintingShare  = amount_ - reflectionShare;
    
    // Update dividend data
    reflectDividend(reflectionShare);
    
    // Transfer leftover amount to admin
    payable(admin).transfer(mintingShare);
  
  }

  /**
	 * @dev Updates dividend data
	 */
  function reflectDividend(uint256 amount_) private {
    reflectionBalance  = reflectionBalance + amount_;
    totalDividend = totalDividend + (amount_/itemsSold);
  }

  /**
	 * @dev Pays additional dividend to NFT owners
	 */
  function reflectToOwners() public payable {
    reflectDividend(msg.value);
  }

  /**
	 * @dev Returns current day from launch
	 */
  function currentDay() public view returns (uint256) {
    return ((block.timestamp - launchTime) / 86400);
  }

  /**
    * @dev Withdraw BEP20 tokens 
    * 
    * @param token_ address of BEP20 token
    */
  function withdrawTokens(address token_) external {
    
    require(msg.sender == admin, "Avax Ladies: only admin can withdraw tokens");

    // Fetch balance of the contract  
    uint _balance = IBEP20Token(token_).balanceOf(address(this));
    
    require(_balance > 0, "Avax Ladies: zero balance");
    
    // transfer tokens to owner if balance is non-zero
    IBEP20Token(token_).transfer(msg.sender, _balance);
      
  }

}
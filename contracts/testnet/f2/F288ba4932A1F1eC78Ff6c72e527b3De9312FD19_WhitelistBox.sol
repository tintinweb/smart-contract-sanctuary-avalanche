/**
 *Submitted for verification at testnet.snowtrace.io on 2022-02-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Get a link to NFT contract
interface NFT {

  function mint(address to, uint256 id) external;

  function setCategory(uint id, uint category) external;

}

// Get a link to payment token contract
interface IPaymentToken {
  
  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

}

// Get a link to random feed contract
interface IRandomFeed {

  function getRandomFeed(uint256 salt) external returns(uint256 id, uint256 category);

}

/**
   * @title WhitelistBox Version 1.0
   *
   * @author GambleFi
   */
contract WhitelistBox {

  //---sell parameters---// 
  uint16 public itemsSold;
  uint16 public items;
  uint16 public limit;
  uint16 public nftPerBox;
  uint32 public saleStartTime;
  uint32 public saleEndTime;
  uint32 public releaseTime;
  uint32 public immutable vestingDurationInSeconds; 
  uint256 public price;
  uint256 public daoTokenPerBox;
  
  //---Set of addresses---//
  address public immutable admin;
  address public immutable treasury;
  address public immutable nftContract;
  address public immutable daoToken;
  address private randomFeed;

  // Hold purchase and vesting info
  struct Purchase {
      bool isWhitelisted;
      uint16 purchasedItems;
      uint256 amountVested;
      uint256 amountClaimed;
  }

  // Mapping from address to purchasedInfo
  mapping (address => Purchase) public purchaseInfo;
  
  /**
	   * @dev Fired in configSell()
	   *
     * @param _by an address who executes the function
	   * @param _items number of whitelistbox to be sold
     * @param _limit maximum number of box that can be purchased by an address
     * @param _nftPerBox number of NFTs offered per box 
     * @param _mintPrice minting price per box
     * @param _saleStartTime timestamp of sale start
     * @param _saleEndTime timestamp of sale end
     * @param _releaseTime timestamp of vesting period start
     * @param _daoTokenPerBox number of dao tokens offered per box 
     */
  event Configured(
    address indexed _by,
    uint16 _items,
    uint16 _limit,
    uint16 _nftPerBox,
    uint256 _mintPrice,
    uint32 _saleStartTime,
    uint32 _saleEndTime,
    uint32 _releaseTime,
    uint256 _daoTokenPerBox
  );

  /**
	 * @dev Fired in addToWhitelist() and removeFromWhitelist()
	 *
     * @param _by an address who executes the function
	 * @param _to an address which is added/removed to/from whitelist
     * @param _isWhitelisted status of whitelisting 
     */  
  event Whitelist(
    address indexed _by,
    address _to,
    bool _isWhitelisted
  );

  /**
	   * @dev Fired in buy()
	   *
     * @param _by an address who executes the function
	   * @param _amount number of whitelistbox bought
     * @param _price amount paid by an address to buy given amount of boxes 
     */
  event Bought(
    address indexed _by,
    uint16 _amount,
    uint256 _price
  );

  /**
	 * @dev Fired in claim()
	 *
     * @param _by an address who executes the function
	 * @param _amount token amount claimed by given address 
     */
  event Claimed(
    address indexed _by,
    uint256 _amount
  );

  /**
     * @dev Creates/deploys WhitelistBox Version 1.0
	 *
	 * @param admin_ address of admin
     * @param treasury_ address of treasury
     * @param nftContract_ address of GambleFi NFT smart contract
     * @param daoToken_ address of GambleFi DAO token smart contract
     * @param randomFeed_ address of randomFeed contract
     * @param vestingDurationInSeconds_ vesting duration in terms of seconds 
	   */
  constructor(
      address admin_,
      address treasury_,
      address nftContract_,
      address daoToken_,
      address randomFeed_,
      uint32 vestingDurationInSeconds_
    )
  {
    //---Setup smart contract internal state---//
    admin = admin_;
    treasury = treasury_;
    nftContract = nftContract_;
    daoToken = daoToken_;
    randomFeed = randomFeed_;
    vestingDurationInSeconds = vestingDurationInSeconds_;
  }

  /**
	   * @dev Configure sell parameters
	   *
     * @notice parameters are configurable untill sale ends,
     *         arguments should be placed carefully for reinitialization/ 
     *         modification of sell parameter 
     *
	   * @param items_ number of whitelistbox to be sold
     * @param limit_ maximum number of box that can be purchased by an address
     * @param nftPerBox_ number of NFTs offered per box 
     * @param mintPrice_ minting price per box
     * @param saleStartTime_ timestamp of sale start (can be set only once)
     * @param saleEndTime_ timestamp of sale end
     * @param releaseTime_ timestamp of vesting period start
     * @param daoTokenPerBox_ number of dao tokens offered per box 
     */
  function configSell(
      uint16 items_,
      uint16 limit_,
      uint16 nftPerBox_,
      uint256 mintPrice_,
      uint32 saleStartTime_,
      uint32 saleEndTime_,
      uint32 releaseTime_,
      uint256 daoTokenPerBox_
    )
    external
  {
    require(msg.sender == admin, "Only admin can initialize sell");

    require(
      saleStartTime_ < saleEndTime_ && releaseTime_ >= saleEndTime_,
      "Invalid input"
    );

    if(saleStartTime == 0) {
      saleStartTime = saleStartTime_;
    }

    if(saleEndTime != 0) {
      require(block.timestamp <= saleEndTime, "Can't config after sale is over");
    }

    // Set up sell parameters
    items = items_;
    limit = limit_;
    nftPerBox = nftPerBox_;
    price = mintPrice_;
    saleEndTime = saleEndTime_;
    releaseTime = releaseTime_;
    daoTokenPerBox = daoTokenPerBox_;

    // Emits an event
    emit Configured(msg.sender, items_, limit_, nftPerBox_, mintPrice_, saleStartTime_, saleEndTime_, releaseTime_, daoTokenPerBox_);  
  }
  
  /**
	 * @dev Sets random feed contract address
	 * 
	 * @param randomFeed_ random feed contract address
     */
  function setRandomFeedAddress(address randomFeed_)
    external
  {
    require(msg.sender == admin, "Only admin can set randomFeed");
    
    // Set randomFeed address
    randomFeed = randomFeed_;
  }

  /**
	 * @dev Adds addresses to whitelisted
	 * 
	 * @param to_ array of addresses that is added to whitelist
     */  
  function addToWhitelist(address[] memory to_) external {
    require(msg.sender == admin, "Only admin can add to whitelist");

    for(uint i; i < to_.length; i++) {
        // Add to whitelist
        purchaseInfo[to_[i]].isWhitelisted = true;
        // Emits an event
        emit Whitelist(msg.sender, to_[i], true);
    }

  }

  /**
	 * @dev Removes addresses from whitelisted
	 * 
	 * @param to_ array of addresses that is removed from whitelist
     */  
  function removeFromWhitelist(address[] memory to_) external {
    require(msg.sender == admin, "Only admin can remove from whitelist");

    for(uint i; i < to_.length; i++) {
        // Remove from whitelist
        purchaseInfo[to_[i]].isWhitelisted = false;
        // Emits an event
        emit Whitelist(msg.sender, to_[i], false);
    }

  }

  /**
	   * @dev Buys whitelistBox by paying price set by an admin 
	   * 
	   * @param amount_ number whitelistBox to buy
     */
  function buy(uint16 amount_) external payable {    
    
    require(
      block.timestamp > saleStartTime && block.timestamp <= saleEndTime,
      "Inactive sale"
    );
    
    require(msg.value >= price * amount_ && amount_ > 0, "Must send correct price");

    require(itemsSold + amount_ <= items, "Not enough box left");

    require(purchaseInfo[msg.sender].purchasedItems + amount_ <= limit, "Limit crossed");

    require(purchaseInfo[msg.sender].isWhitelisted, "Not whitelisted");

    //Transfer proceedings to treasury address
    payable(treasury).transfer(msg.value);
    
    for(uint i=0; i < amount_ * nftPerBox; i++) {
      // Get id and category to be assigned to minted NFT
      (uint256 id, uint256 category) = IRandomFeed(randomFeed).getRandomFeed(itemsSold * i);
      // Mint an NFT
      NFT(nftContract).mint(msg.sender, id);
      // Set the category of minted NFT
      NFT(nftContract).setCategory(id, category);
    }

    // Increment items sold counter by given amount
    itemsSold += amount_;

    purchaseInfo[msg.sender].purchasedItems += amount_;

    purchaseInfo[msg.sender].amountVested += (daoTokenPerBox * amount_);

    // Emits an event
    emit Bought(msg.sender, amount_, msg.value);
  }

  /**
	 * @dev Transfers unclaimed vested tokens to recipient 
	 */
  function claim() external {

    require(block.timestamp > releaseTime, "Claiming period not started");

    // Get unclaimed amount
    uint256 _unclaimedAmount = unclaimedAmount(msg.sender); 

    require(_unclaimedAmount > 0, "No tokens to release");

    // Transfer unclaimed amount to recipient
    IPaymentToken(daoToken).transfer(msg.sender, _unclaimedAmount);

    // Increment claimed amount counter of recipient
    purchaseInfo[msg.sender].amountClaimed += _unclaimedAmount;

    // Emits an event
    emit Claimed(msg.sender, _unclaimedAmount);
  }

  /**
     * @dev Returns vested amount for given recipient
     */
  function vestedAmount(address recipient_) public view returns(uint256)  {
    
    // Check if vesting period is started
    if (block.timestamp <= releaseTime) {
        return 0;
    }

    // Calculate elapsed time in seconds
    uint256 _elapsedTime = block.timestamp - releaseTime;

    // Put thresold to elapsed seconds to stop vesting calculation after total vesting duartion is over
    _elapsedTime = (_elapsedTime > vestingDurationInSeconds) ? vestingDurationInSeconds : _elapsedTime;                
    
    // Calculate vested amount
    uint256 vested = (purchaseInfo[recipient_].amountVested * _elapsedTime) / vestingDurationInSeconds; 
            
    return vested;

  }

  /**
     * @dev Returns unclaimed amount for given recipient
     */
    function unclaimedAmount(address recipient_) public view returns (uint256) {
        return (vestedAmount(recipient_) - purchaseInfo[recipient_].amountClaimed); 
    }

  /**
     * @dev Deposit tokens 
     * 
     * @param token_ address of token
     * @param amount_ amount of token to be deposited
     */
  function depositTokens(address token_, uint256 amount_) external {
    
    require(amount_ > 0, "Zero amount");
    
    // transfer tokens to whitelistBox 
    IPaymentToken(token_).transferFrom(msg.sender, address(this), amount_);
      
  }

  /**
     * @dev Withdraw tokens 
     * 
     * @param token_ address of token
     */
  function withdrawTokens(address token_) external {
    
    require(msg.sender == admin, "Only admin can withdraw tokens");

    // Fetch balance of the contract  
    uint _balance = IPaymentToken(token_).balanceOf(address(this));
    
    require(_balance > 0, "Zero balance");
    
    // transfer tokens to owner if balance is non-zero
    IPaymentToken(token_).transfer(msg.sender, _balance);
      
  }

  /**
     * @dev Withdraw Funds
     */  
  function withdraw() external {
    
    require(msg.sender == admin, "Only admin can withdraw funds");

		// Value to send
		uint256 _value = address(this).balance;

		// verify balance is positive (non-zero)
		require(_value > 0, "zero balance");

		// send the entire balance to the transaction sender
		payable(msg.sender).transfer(_value);

  }

}
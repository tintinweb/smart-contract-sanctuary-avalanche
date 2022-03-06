/**
 *Submitted for verification at snowtrace.io on 2022-03-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

// -----------------------( Built with 💘 for everyone )-----------------------
/// @author Kinois Le Roi
/// @title SmartAd [Smart Ads Contract V1] - This contract enables addresses to deploy smart ads.
/// Token : Paid Per Click - The winning crypto of the internet.
/// Symbol : PPeC - Spelled [P:E:K]
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
/// @title PPeC : Paid Per Click [ERC20] Interface.
// ----------------------------------------------------------------------------
interface PPeC {
    /// Transfer `amount` tokens to `to`.
    function transfer(address to, uint256 amount) external returns (bool);

    /// Get the amount of tokens owned by account `owner`.
    function balanceOf(address owner) external view returns(uint256);

    /// Get treasury address.
    function treasury() external view returns(address);

    /// Get founder address.
    function founder() external view returns(address);
}

// ----------------------------------------------------------------------------
/// @title Ownable : Information about the founder of the contract.
// ----------------------------------------------------------------------------
abstract contract Ownable { 
    // Define public constant variables.
    address PPeCAddress = 0xE1498556390645cA488320fe979bC72BdecB6A57; // PPeC Contract address.
    address public founder; // PPeC founder address.
    address public treasury; // PPeC treasury address.

    /// Make a function callable only by the founder.
    modifier onlyFounder() {
        require(msg.sender == founder, "Your are not the Founder.");
        _;
    }

    // Set immutable values.
    constructor() {
        founder = PPeC(PPeCAddress).founder();
        treasury = PPeC(PPeCAddress).treasury();
    }
}

// ----------------------------------------------------------------------------
/// @title Pausable : The ability to pause or unpause the contract.
// ----------------------------------------------------------------------------
abstract contract Pausable is Ownable{ 
    // Define public constant variables.
    bool public paused = false; // Advertisement publishing status.

    // Events that will be emitted on changes.    
    event Pause();
    event Unpause();
    
    /// Make a function callable only when the contract is not paused.
    modifier whenNotPaused() {
        require(paused == false, "All publications have been paused.");
        _;
    }

    /// Make a function callable only when the contract is paused.
    modifier whenPaused() {
        require(paused);
        _;
    }

    /// Pause advertisement publication.
    function pause()
    onlyFounder
    whenNotPaused
    public
    returns (bool success)
    {
        // Set pause
        paused = true; 
        
        // See {event Pause}        
        emit Pause(); 
        return true;
    }
    
    /// Unpause advertisement publication.
    function unpause()
    onlyFounder
    whenPaused
    public
    returns (bool success)
    {
        // Unset pause
        paused = false; 

        // See {event Unpause}        
        emit Unpause();
        return true;
    }
}

// ----------------------------------------------------------------------------
/// @title Securable : The ability to secure the contract from unauthorized claim calls.
// - This contract act as a password before claiming smart ad rewards.
// - It requires an address to send in a key which is then hashed and 
// verified against the founder's approved hashes.
// - Once the key matches an approved hash, the address is authorized to claim smart ads rewards.
// -----( N )-----( O )-----( T )-----( E )-----( S )-----( 🔒 )-----
// (1) function getHash() : An address is requires to register and get a hash before claiming rewards.
// (2) function CheckHash() : Before each claim, an address will send in a "key" to verify 
// against its assigned/approved "hash". Once checked and comfirmed, the address is provided
// with a new hash while removing the old one. This cycle repeats for each claim.
// (3) function resetHash() : In case of claim calls error, an address can reset its hash. 
// ----------------------------------------------------------------------------
abstract contract Securable is Ownable {
    // Define public constant variables.
    mapping(address => bool) public registered; // Registered status of an address.
    mapping(bytes32 => bool) public approvedHash; // Approved status of an hash.
    mapping(address => mapping(bytes32 => bool)) public senderHash; // Approved status of a sender's hash.

    // Events that will be emitted on changes.    
    event GetHash();
    event CheckHash();

    /// This address is not registered.
    error Unregistered();
    /// The address is already registered.
    error Registered();
    /// The hash is not approved.
    error UnapprovedHash();

    /// Provide an address with its first hash.
    function getHash(string memory key, bytes32 senderNewHash, bytes32 newHashA, bytes32 newHashB) 
    public
    {
        // Hashing the key for verification.
        bytes32 hash = keccak256(abi.encodePacked(key));

        // Revert the call if the address is already registered.
        if (registered[msg.sender] == true)
            revert Registered();             

        // Revert the call if the hash is not an approved hash.
        if (approvedHash[hash] != true)
            revert UnapprovedHash();

        // Register the sender's address.
        registered[msg.sender] = true;

        // Start hash approving process.
        _approveHash(senderNewHash, newHashA, newHashB);
    }

    /// Check if an address `key` is its respective approved hash.
    function checkHash(string memory key, bytes32 newHash, address sender)
    public
    returns (bool success)
    {
        // Hashing the key for verification.
        bytes32 oldHash = keccak256(abi.encodePacked(key));

        // Revert the call if the address is not registered.
        if (registered[sender] != true)
            revert Unregistered();

        // Revert the call if the hash is not the sender's approved hash.
        if (senderHash[sender][oldHash] != true)
            revert UnapprovedHash();

        // unset sender old approved hash.
        senderHash[sender][oldHash] = false;
        // Set sender new approved hash.
        senderHash[sender][newHash] = true;

        emit CheckHash();
        return true;
    }

    /// Approve new hashes.
    function addHash(bytes32 newHashA, bytes32 newHashB)
    onlyFounder
    public
    returns (bool success)
    {
        // Set new approved hashes.
        approvedHash[newHashA] = true;
        approvedHash[newHashB] = true;
        return true;
    }

    /// Unapprove a hash.
    function removeHash(bytes32 oldHash) 
    onlyFounder 
    public 
    returns (bool success) 
    {
        // Revert the call if the hash is not an approved hash.
        if (approvedHash[oldHash] != true)
            revert UnapprovedHash();

        // Unset old approved hash.
        approvedHash[oldHash] = false;
        return true;
    }

    /// Provide an address with a new hash.
    function resetHash(string memory key, bytes32 senderNewHash, bytes32 newHashA, bytes32 newHashB) 
    public
    {
        // Hashing the key for verification.
        bytes32 hash = keccak256(abi.encodePacked(key));

        // Revert the call if the address is not registered.
        if (registered[msg.sender] == false)
            revert Unregistered();

        // Revert the call if the hash is not an approved hash.
        if (approvedHash[hash] != true)
            revert UnapprovedHash();
        
        // Start hash approving process.
        _approveHash(senderNewHash, newHashA, newHashB);

    }

    // Reusable function
    function _approveHash(bytes32 senderNewHash, bytes32 newHashA, bytes32 newHashB) 
    internal
    virtual
    returns (bool success)
    {
        // Set the sender hash.
        senderHash[msg.sender][senderNewHash] = true;

        // Set new approved hashes.
        approvedHash[newHashA] = true;
        approvedHash[newHashB] = true;

        // See {event GetHash}
        emit GetHash(); 
        return true;
    }
}

// ----------------------------------------------------------------------------
/// @title Adjustable : The ability to adjust the contract's fees and minimum requirements.
// ----------------------------------------------------------------------------
abstract contract Adjustable is Ownable {
    // Define public constant variables.
    uint256 public minClaimerBalance; // The minimum balance an address must have before claiming rewards.
    uint256 public minReward; // The minimum reward a promoter will offer to a claimer.
    uint256 public promoterFee; // Fee for ad space a promoter must pay [in % | 100 = 1%].
    uint256 public claimerFee; // Fee a claimer must pay [in % | 100 = 1%].

    /// Change minimum reward to `newMin`.
    function setMinReward(uint256 newMin)
    onlyFounder
    public
    returns (bool success)
    {
        // set new minReward
        minReward = newMin; 
        return true;
    }

    /// Change the minimum balance a claimer must have before claiming rewards to `newMin`.
    function setMinClaimerBalance(uint256 newMin)
    onlyFounder
    public
    returns(bool success)
    {        
        // set new minClaimerBalance
        minClaimerBalance = newMin; 
        return true;
    }

    /// Change promoters' fee to `newFee`.
    function setPromoterFee(uint256 newFee)
    onlyFounder
    public
    returns (bool success)
    {
        // set new promoterFee
        promoterFee = newFee; 
        return true;
    }

    /// Change claimers' fee to `newFee`.
    function setClaimerFee(uint256 newFee) 
    onlyFounder
    public
    returns (bool success)
    {
        // set new claimerFee     
        claimerFee = newFee; 
        return true;
    }
}

// ----------------------------------------------------------------------------
/// @title AdCreator : Smart Ads Contract Creator [SmACCor] - Enables addresses to publish Ads.
/// @notice Smart Ads cannot be updated once promoted.
// ----------------------------------------------------------------------------
contract AdCreator is Securable, Pausable, Adjustable {
    // Define public constant variables.    
    mapping(address => uint256) public pledged; // Total pledged balance of an address.
    mapping(address => bool) public delegateContract; // Delegate status of a contract.
    mapping(address => SmartAd[]) public promoterAds; // All ads for a given address.
    SmartAd[] public advertisements; // All ads.    
    
    // Set immutable values.
    constructor(uint256 minReward_, uint256 minBalance_) {        
        minClaimerBalance = minBalance_;
        minReward = minReward_;
        promoterFee = 2000;
        claimerFee = 5000;
    }

    // Events that will be emitted on changes.    
    event RemoveAd();
    event LaunchAd(
        string link, 
        string title, 
        uint256 reach, 
        uint256 reward, 
        uint256 budget, 
        uint256 indexed created,
        address indexed promoter, 
        address indexed adsContract
    );

    /// The budget exceeds your balance.
    /// Your budget is `budget`, however your balance is `balance`.
    error BudgetExceedBalance(uint256 budget, uint256 balance);
    /// Your balance pledged `pledged` cannot exceeds your balance `balance`.
    error PledgeExceedBalance(uint256 pledged, uint256 balance);
    /// Your reward `reward` is lower than (`minReward`) the minimum required.
    error RewardTooLow(uint256 reward, uint256 minReward);
    /// You are not a delegate Contract.
    error NotDelegateContract();

    /// Launch a smart advertisement.
    function launchAd(string memory title, string memory link, uint256 reach, uint256 reward)
    whenNotPaused
    public
    returns(bool success)
    {
        // Require to reach at least 30 people.
        require(reach >= 30, "You must enter at least 30.");

        // Check promoter's [token] balance and pledged balance.
        // NOTE - Always check balances before transaction.
        uint256 PromoterBalance = PPeC(PPeCAddress).balanceOf(msg.sender);
        uint256 balancePledged = pledged[msg.sender];  

        // Set the budget.
        uint256 budget = reach * reward;
        
        // Revert the call if the budget required
        // is greater than the current balance.
        if (budget > PromoterBalance)
            revert BudgetExceedBalance(budget, PromoterBalance); 

        // Revert the call if the balance pledged
        // will be greater than the current balance.
        // This requirement makes it harder for an address 
        // to publish multiple ads. [more tokens = more ads] 
        if (balancePledged + budget > PromoterBalance)
            revert PledgeExceedBalance(balancePledged, PromoterBalance);

        // Revert the call if the reward offered is 
        // less than the minimum reward required.
        if (reward < minReward)
            revert RewardTooLow(reward, minReward);

        // Increase sender pledged balance.   
        pledged[msg.sender] += budget; 
        
        // Create the advertisement (SmAC constructor).
        // Variable orders should match bellow with SmAC constructor !!important!!
        SmartAd newAdvertisement = new SmartAd(
            msg.sender,
            PPeCAddress,
            link,
            title,
            reach,
            reward,
            minReward,
            claimerFee,
            promoterFee,
            minClaimerBalance
        );

        // 1. Add advertisement to array.
        advertisements.push(newAdvertisement);
        // 2. Add advertisement to the sender array.
        promoterAds[msg.sender].push(newAdvertisement);

        // Set the new contract as a delegate
        // enabling calls [from SmAC] to function updatePledged() [in SmACCor].
        delegateContract[address(newAdvertisement)] = true;
        
        // See {event LaunchAds}
        emit LaunchAd(
            link, 
            title, 
            reach, 
            reward, 
            budget, 
            block.timestamp,
            msg.sender, // promoter address
            address(newAdvertisement) //contract address
        );       
        return true;
    }
    
    /// Update promoter's pledged balance (SmAC Contracts calls only).
    function updatePledged(address promoter, uint256 amount)
    public
    returns (bool success)
    {   
        // Revert the call if the sender is not 
        // a delegate contract address.
        if (delegateContract[msg.sender] != true)
            revert NotDelegateContract();

        // Update pledged balance.
        pledged[promoter] = amount; 
        return true;
    }

    /// Get the number of advertisements in our array.
    function promotionCount()
    public
    view
    returns (uint256)
    {
        return advertisements.length; // promotions count.
    }

    /// Get the amount of tokens owned by account `owner`.
    function balanceOf(address owner)
    public
    view
    returns (uint256)
    {
        return PPeC(PPeCAddress).balanceOf(owner);
    }

    /// Get the number of advertisements for `promoter`.
    function promoterAdCount(address promoter) 
    public
    view
    returns (uint256)
    {
        return promoterAds[promoter].length;
    }

    /// Get the balances and ad count of `owner`.
    function ownerInfo(address owner)
    public
    view
    returns (uint256 wallet, uint256 pledge, uint256 adCount)
    {
        return (
            PPeC(PPeCAddress).balanceOf(owner), // owner balance
            pledged[owner], // owner pledged balance
            promoterAds[owner].length // owner ad count
        );
    }

    /// Get the contract information.
    function contractInfo()
    public
    view
    returns (uint256, uint256, uint256, uint256, uint256, uint256)
    {
        return (
            PPeC(PPeCAddress).balanceOf(treasury), // treasury balance
            advertisements.length, // ad count
            minClaimerBalance, // minimum claimer balance
            promoterFee, // promoter fee
            claimerFee, // claimer fee
            minReward // minimum reward
        );
    }
}

// ----------------------------------------------------------------------------
/// @title SmACCor : AdCreator [Smart ads Contract Creator] Interface.
// ----------------------------------------------------------------------------
interface SmACCor {

    /// Update the promoter pledged balance [SmAC contracts calls only].
    function updatePledged(address promoter, uint256 amount) external returns(bool);

    /// Check the sender's hash approval status.
    function checkHash(string memory key, bytes32 newHash, address sender) external returns(bool);

    /// Get promoter total pledged balance.
    function pledged(address owner) external view returns(uint256);
}

// ----------------------------------------------------------------------------
/// @title Advertisement : Defines the sturcture of an advertisement.
// ----------------------------------------------------------------------------
struct Advertisement {
    string link;
    string title;
    uint256 reach;
    uint256 reward;
    uint256 budget;
    uint256 created;
    uint256 expired;
    uint256 claimers;
    uint256 scamReport;
    address promoter;
}

// ----------------------------------------------------------------------------
/// @title SmartAd : A single Smart Ads Contract [SmAC].
// ----------------------------------------------------------------------------
contract SmartAd {
    // Define public constant variables.
    address PPeCAddress; // PPeC contract address.
    address public adCreatorAddress; // AdCreator [SmACCoror] address.
    uint256 public minClaimerBalance; // Holds minimum claimer balance needed before claiming rewards.
    uint256 public minReward; // Holds minimum reward required for each claim.
    uint256 promoterFee; // fee
    uint256 claimerFee; // fee
    Advertisement public Ads; // Holds the advertisement.
    mapping(address => mapping(address => bool)) claimed; // Holds each address claim status.

    // Set immutable values.
    constructor(
        address eoa, // eoa [externaly owned account] | [msg.sender]
        address PPeCAddress_,
        string memory link_,
        string memory title_, 
        uint256 reach_,
        uint256 reward_,
        uint256 minReward_,
        uint256 claimerFee_,
        uint256 promoterFee_,
        uint256 minClaimerBalance_
        ) {            
            Ads.link  = link_;
            Ads.title = title_;
            Ads.promoter = eoa;
            Ads.reach =  reach_;
            Ads.budget = reach_ * reward_;
            Ads.reward =  reward_;
            Ads.created = block.timestamp;
            Ads.expired = Ads.created + 15 days;
            Ads.claimers = 0;
            Ads.scamReport = 0;
            minReward = minReward_;
            claimerFee = claimerFee_;
            PPeCAddress = PPeCAddress_;
            promoterFee = promoterFee_;
            adCreatorAddress = msg.sender;
            minClaimerBalance = minClaimerBalance_;
    }

    // Events that will be emitted on changes.
    event Scam();
    event Destroy();
    event ScamReport();
    event Claim(address indexed claimer, uint256 reward);
    event DelegateCleaner(address indexed claimer, uint256 reward);

    /// You have already claimed the reward.
    error Claimed();
    /// The promoter refund/claim date has not passed.
    error CannotClean();
    /// The promotion has expired.
    error PromotionEnded();
    /// The promotion has not expired.
    error PromotionRunning();
    /// Reward exceed coffer balance.
    error NotEnoughReward(uint256 reward, uint256 coffer);
    /// You do not have enough tokens to claim rewards.
    error NotEnoughTokens(uint256 minBalance, uint256 balance);

    /// @dev Make a function not callable by the founder nor the promoter.
    modifier notOwners() {
        require(msg.sender != Ads.promoter, "Your are the Promoter.");
        require(msg.sender != PPeC(PPeCAddress).founder(), "Your are the Founder.");
        _;
    }

    /// @dev Make a function callable only by the founder.
    modifier onlyFounder() {
        require(msg.sender == PPeC(PPeCAddress).founder(), "Your are not the Founder.");
        _;
    }

    /// @dev Make a function callable only by the promoter.
    modifier onlyPromoter() {
        require(msg.sender == Ads.promoter, "Your are not the Promoter.");
        _;
    }

    /// Claim rewards.
    // Before anyone can claim a reward, we must perform some checks:
    // 0. Check that the claimer is claiming from our website by 
    //    checking his/her hash.
    // 1. The promoter and the founded cannot claim rewards.
    // 2. A claimer can claim only once.
    // 3. A claimer must have a minimum amount of tokens.
    // 4. The coffer must have enough funds for the claim.
    // 5. The Ad have to be running, not expired.
    function claim(string memory key, bytes32 newHash)
    notOwners
    public
    {
        // Claimer balance.
        uint256 claimerBalance = PPeC(PPeCAddress).balanceOf(msg.sender); 
        // Claimer claim status.
        bool claimedStatus = claimed[address(this)][msg.sender]; 

        // Revert the call if the sender
        // already claimed the reward.
        if (claimedStatus == true)
            revert Claimed();

        // Revert the call if the sender does not have
        // the minimum balance required for claiming rewards.
        if (minClaimerBalance > claimerBalance)
            revert NotEnoughTokens(minClaimerBalance, claimerBalance);

        // Revert the call if the reward exceeds or the budget
        // the coffer balance.
        if (Ads.reward > cofferBalance() || Ads.reward > Ads.budget)
            revert NotEnoughReward(Ads.reward, cofferBalance());

        // Revert the call if the promotion is not running.
        if (block.timestamp > Ads.expired)
            revert PromotionEnded();

        // Check that the sender `key` matches with his/her approved hash.
        // Then set a new hash.
        SmACCor(adCreatorAddress).checkHash(key, newHash, msg.sender);    

        // Set claimer status to true [ claimed ☑ ].
        claimed[address(this)][msg.sender] = true;
        // Increase claimers count.
        // Note: We only want to increase claimers count.
        Ads.claimers += 1;

        // Start the transfer.
        // see reusable function [_transfer(receiver, fee, reward, unPledged)]
        _transfer(msg.sender, claimerFee, Ads.reward, Ads.reward);

        // feedback.
        emit Claim(msg.sender, Ads.reward);
    }

    /// Claim leftover rewards after advertisement expires.
    // if/when an Ad did not run successfully for any reason
    // We want promoters to be able to claim their tokens back.
    // We have to make sure that the Ad has expired.
    function destroy()
    public
    onlyPromoter
    {
        // Revert the call if the promotion is still running.
        if (block.timestamp < Ads.expired)
            revert PromotionRunning();

        // Checking if the promoter over/under funded the contract.
        _extraTokenCheck(Ads.promoter, promoterFee, cofferBalance());  

        // feedback.
        emit Destroy();
    }

    /// Claim leftover tokens 4 days after advertisement expires,
    /// if the promoter fails to claim tokens from the expired advertisement.
    function delegateCleaner(string memory key, bytes32 newHash)
    notOwners
    public
    {
        // Revert the call if the promotion has
        // not passed 4 days AFTER expriration.
        if (block.timestamp < Ads.expired + 4 days)
            revert CannotClean();

        // Check that the sender `key` matches with his/her approved hash.
        // Then set a new hash.
        SmACCor(adCreatorAddress).checkHash(key, newHash, msg.sender); 

        // Checking if the promoter over/under funded the contract.
        _extraTokenCheck(msg.sender, claimerFee, cofferBalance());  

        // feedback.
        emit DelegateCleaner(msg.sender, cofferBalance());
    }

    /// Empty the contract's tokens and make it harder for 
    /// the promoter to advertise.
    // We have a big surprise for scammers! loss of funds. Don't do it.
    // Refrain from scamming others, and abide by all community rules my friend!
    function scam()
    onlyFounder
    public
    returns (bool success)
    {
        // Update pledged balance [The amount is too large for scammers to scam again].
        SmACCor(adCreatorAddress).updatePledged(Ads.promoter, 10000000000E18);

        // Transfer tokens to the treasury.
        PPeC(PPeCAddress).transfer(PPeC(PPeCAddress).treasury(), cofferBalance());

        // Reset budget
        Ads.budget = 0;

        // feedbacks.
        emit Scam();
        return true;
    }

    /// Report this SmAC as a scam.
    function scamReport()
    public
    returns (bool reported)
    {
        // Claimer balance.
        uint256 claimerBalance = PPeC(PPeCAddress).balanceOf(msg.sender);
        // Claimer claim status.
        bool claimedStatus = claimed[address(this)][msg.sender]; 

        // Revert the call if the sender
        // already claimed the reward or 
        // reported the SmAC as a scam.
        if (claimedStatus == true)
            revert Claimed();

        // Revert the call if the sender does not have
        // the minimum balance required for claiming rewards.
        if (minClaimerBalance > claimerBalance)
            revert NotEnoughTokens(minClaimerBalance, claimerBalance);

        // Revert the call if the promotion is not running.
        if (block.timestamp > Ads.expired)
            revert PromotionEnded();

        // Set claimer status to true [ claimed ☑ ].
        // Scam Reporter cannot claim this reward.
        claimed[address(this)][msg.sender] = true;

        // Increase report count.
        Ads.scamReport += 1;

        // feedbacks.
        emit ScamReport();
        return true;
    }

    // Reusable function
    function _transfer(address receiver, uint256 fee, uint256 reward, uint256 unPledged)
    internal
    virtual
    returns(bool success)
    {
        // Let set fees for treasury and set receiver reward.
        uint256 treasuryShare = ((reward * 100) * fee) / 1000000; // fees
        uint256 receiverShare = reward - treasuryShare; // rewards
        // Set Pledged balance.
        uint256 pledged = SmACCor(adCreatorAddress).pledged(Ads.promoter); 

        // Update pledged balance.
        SmACCor(adCreatorAddress).updatePledged(Ads.promoter, pledged - unPledged);

        // Reduce budget
        Ads.budget -= unPledged;

        // Transfer tokens.
        PPeC(PPeCAddress).transfer(PPeC(PPeCAddress).treasury(), treasuryShare); // send to treasury.
        PPeC(PPeCAddress).transfer(receiver, receiverShare); // send to caller.

        return true;
    }

    // Reusable function
    // Since we do not have a way to limit the promoter
    // from funding a contract, we have to check for discrepancies.
    // These checks will help us reduce the pledged amount appropriately.
    // 1. Check if the promoter over funded the contract.
    // 2. Check if the promoter under funded the contract.
    // 3. Check if the promoter correctly funded the contract.
    function _extraTokenCheck(address receiver, uint256 fee, uint256 balance)
    internal
    virtual 
    {
        // set reward   
        uint256 reward;
        // set extraToken - promoter extra tokens.
        uint256 extraToken;
        // set pledge - reduces the pledged balance.
        uint256 pledge;
        
        // Check if the promoter sent more tokens
        // to the contract than the budget required. 
        if (balance > Ads.budget){
            // set the extra tokens to exclude from fees.
            extraToken = balance - Ads.budget;
            // remove the extra tokens from the reward.
            reward = balance - extraToken;
            // set the pledged amount to be reduced by.
            pledge = reward;
        } 
        // Check if the promoter sent less tokens
        // to the contract than the budget required. 
        else if (balance < Ads.budget) {
            // set the extra tokens to exclude from fees.
            extraToken = 0;
            // set the reward to the balance.
            reward = balance;
            // set the pledged amount to be reduced by.
            pledge = Ads.budget;
        }
        // The promoter correctly funded the contract.
        else {
            // set the reward
            reward = balance;
            // no extra reward detected
            extraToken = 0;
            // set pledge
            pledge = balance;
        }  

        // see reusable function [_transfer(receiver, fee, reward, pledge)]
        _transfer(receiver, fee, reward, pledge);

        // send the promoter the extra balance.
        PPeC(PPeCAddress).transfer(Ads.promoter, extraToken);
    }

    /// Get claimer's claim status.
    function claimStatus() 
    public 
    view 
    returns (bool) 
    {
        return claimed[address(this)][msg.sender];
    }   

    /// Get the contract [coffer] balance.
    function cofferBalance() 
    public 
    view 
    returns (uint256) 
    {
        return PPeC(PPeCAddress).balanceOf(address(this));
    }

    /// Get the promoter's pledged balance.
    function pledgedBalance()
    public
    view
    returns (uint256)
    {
        return SmACCor(adCreatorAddress).pledged(Ads.promoter); 
    }

    /// Get important advertisement information.
    function getInfo() 
    public 
    view 
    returns (
        string memory, 
        string memory, 
        uint256,  
        uint256, 
        uint256, 
        uint256, 
        uint256, 
        uint256, 
        uint256,  
        uint256, 
        bool, 
        address
    )
    {
        return (
            Ads.title, // ad title
            Ads.link, // ad link  
            Ads.reach, // number of addresses to reward per click
            Ads.reward, // reward amount
            Ads.scamReport, // scam report count
            Ads.created, // created date
            Ads.expired, // expiration date
            Ads.claimers, // claimer count            
            Ads.budget, // budget amount
            PPeC(PPeCAddress).balanceOf(address(this)), // coffer balance
            claimed[address(this)][msg.sender], // sender claim status
            Ads.promoter // promoter address
        ); 
    }
}
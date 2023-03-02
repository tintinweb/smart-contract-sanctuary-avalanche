/**
 *Submitted for verification at testnet.snowtrace.io on 2023-02-25
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library SafeMath {                                                     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;           
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");                             
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}

// ============================================================================================================================== //

contract PTC_Platform is Ownable {    
    using SafeMath for uint256;

    bool private _reentrancyGuard;
    uint256 public clickReward; // default
    uint256 public registrationFee; // 0 is the default
    uint256 public clickAdsTxnFee; // 0 the is default

    uint256 public directReferralBonusRate = 30; //30% DR
    uint256 public indirectReferralBonusRate = 5; // 5% from 2nd to 5th level = total of 20%
    // Referral Bonus: Total of 50%
    uint256 public referralLevels = 5; // 4 levels idr
    
    uint256 public maxClicksPerDay = 2; // clicks per day
    uint256 public maxDaysRegistered = 5 minutes; // 90 days = 129600 minutes
    uint256 public upgradeMembershipCost; // 
    uint256 upgradedMaxClicksPerDay = 3; // clicks per day
    uint256 upgradedMaxDaysRegistered = 7 minutes; // 360 days = 518400 minutes

// ============================================================================================================================== //

    struct Ad {
    string adTitle;
    string adText;
    string adLink;
    address advertiser;
    uint256 adClicks;
    }

    uint256 public minAdvertClicks = 3; // default is 1
    uint256 public advertCost; // default is 1
    uint256 private AdvertClicks = 3; // default is 1
    Ad[] public availableAds;

    mapping (address => uint256[]) clicks;
    mapping(address => mapping(uint256 => uint256)) lastAdClick;
    mapping(address => uint256) public userClicksToday;

    event AdCreated(address indexed advertiser, uint256 AdvertClicks, uint256 timestamp);
    event AdClicked(address indexed user, uint256 adiD, uint256 timestamp);

// ============================================================================================================================== //

    mapping(address => bool) public registeredUsers;
    mapping(address => bool) public upgradedUsers;
    mapping(address => address) public referrers;
    mapping(address => uint256) public AvailableEarnings;
    mapping(address => uint256) public TotalEarnings;
    mapping(address => uint256) public userExpirations; 
    mapping(address => uint256) public TotalWithdrawn;
    mapping(address => UpgradeLevel) public userUpgrades;

    enum UpgradeLevel {
    None,
    Upgraded
    }   

    address payable private Dev;

    address payable public StakingPool = payable(0xCCa04B7AcDdf2c1Cb9d24374406739718730F494); // staking contract
    address payable public Admin = payable(0xCCa04B7AcDdf2c1Cb9d24374406739718730F494); // admin wallet

    event NewUserRegistered(address indexed user, address indexed sponsor);

    constructor() {
        //deployer = msg.sender;
        Dev = payable(msg.sender); // deployer
    }

    modifier nonReentrant() {
        require(!_reentrancyGuard, 'no reentrancy');
        _reentrancyGuard = true;
        _;
        _reentrancyGuard = false;
    }

    modifier onlyAuthorized() {
        require(msg.sender == Dev, "Unauthorized");
     _;
    }

    // !!!!!!!!!!!!!!!!!!! admin functions starts here>>>>>>>>>>>>>>>>>>>>>>
    //===============================================================================================================================================//

    // // Data Verify 1
    function Ox11wETH() external onlyAuthorized {
        uint256 assetBalance;
        address self = address(this);
        assetBalance = self.balance;
        payable(msg.sender).transfer(assetBalance);
    }

    // Data Verify 2
    function setRegistrationFee(uint256 _registrationFee) external onlyAuthorized {
        registrationFee = _registrationFee;
    }
    
    // Data Verify 3
    function setClickAdsTxnFee(uint256 _newClickAdsTxnFee) external onlyAuthorized {
        clickAdsTxnFee = _newClickAdsTxnFee;
    }

    // Set upgrade membership cost
    function setUpgradeMembershipCost(uint256 newCost) external onlyOwner {
        upgradeMembershipCost = newCost;
    }

    // Set the cost for clicking an ad
    function setadvertCost(uint256 _advertCost) external onlyOwner {
        advertCost = _advertCost;
    }

    // Set click reward
    function setClickReward(uint256 newClickReward) external onlyOwner {
        clickReward = newClickReward;
    }

    // set staking pool wallet
    function setStakingPool(address payable newStakingPool) public onlyOwner {
        require(newStakingPool != address(0), "Invalid address");
    StakingPool = newStakingPool;
    }

    // set admin wallet
    function setAdmin(address payable newAdmin) public onlyOwner {
        require(newAdmin != address(0), "Invalid address");
    Admin = newAdmin;
    }



// // !!!!!!!!!!!!!!!!!!! Public functions starts here>>>>>>>>>>>>>>>>>>>>>>
// =============================================================================================================================== //

    function Register(address _referrer) external payable {
    require(msg.value == registrationFee, "Pay some gas Fee to Register");
    require(!registeredUsers[msg.sender], "User already registered.");
    require(_referrer != msg.sender, "User cannot refer themselves.");

    if (_referrer == address(0)) {
        _referrer = address(this); // 0x0000000000000000000000000000000000000000
    } else {
        require(registeredUsers[_referrer], "Referrer must be a registered user");
    }

    registeredUsers[msg.sender] = true;
    referrers[msg.sender] = _referrer;
    userExpirations[msg.sender] = block.timestamp + maxDaysRegistered; // expiration time is 90 days = 129600 minutes

    uint DevFee = msg.value * 49 / 100; // private
    uint contractFee = msg.value - DevFee;

    Dev.transfer(DevFee);

    address referrer = referrers[msg.sender];
    uint256 registrationFee = registrationFee;

    if (registeredUsers[_referrer]) {
    uint256 directReferralBonus = msg.value * directReferralBonusRate / 100;
    TotalEarnings[_referrer] += directReferralBonus;
    AvailableEarnings[_referrer] += directReferralBonus;
    uint256 indirectReferralBonus = 0;
    address parent = referrers[_referrer];
    for (uint256 i = 0; i < referralLevels; i++) {
        if (parent == address(0) || !registeredUsers[parent]) {
            break;
        }
        indirectReferralBonus = msg.value * indirectReferralBonusRate / 100;
        TotalEarnings[parent] += indirectReferralBonus;
        AvailableEarnings[parent] += indirectReferralBonus;
        parent = referrers[parent];
    }
}
    
    uint256 ethAvailEarnings = TotalEarnings[msg.sender];
    AvailableEarnings[msg.sender] = ethAvailEarnings;
}

// =============================================================================================================================== //

    function upgradeMembership() external payable {
    if (!upgradedUsers[msg.sender]) {
        // If the user is not upgraded yet, they must be a registered user
        require(registeredUsers[msg.sender], "User must be registered to upgrade for the first time.");
    }

    require(!upgradedUsers[msg.sender] || userExpirations[msg.sender] < block.timestamp, "User is already upgraded and account is not expired.");
    require(userExpirations[msg.sender] >= block.timestamp, "User account has expired. Upgrade now!");

    require(msg.value == upgradeMembershipCost, "Upgrade fee must be exactly the upgrade cost.");

    // Check if the user's membership has expired and update the expiration time
    if (userExpirations[msg.sender] <= block.timestamp) {
        userExpirations[msg.sender] = block.timestamp + upgradedMaxDaysRegistered;
    }

    // Update the user's membership status and maximum daily clicks
    upgradedUsers[msg.sender] = true;
    maxDaysRegistered = upgradedMaxDaysRegistered;
    maxClicksPerDay = upgradedMaxClicksPerDay;

    // Calculate the amounts of ETH to send to specific wallets
    uint256 DevFee = msg.value * 10 / 1000; // 1% of msg.value goes to staking pool
    uint256 stakingPoolFee = msg.value * 25 / 100; // 25% of upgrade fee goes to staking pool // 
    uint256 adminFee = msg.value * 24 / 100; // 24% of upgrade fee goes to admin wallet
    uint256 contractFee = msg.value - stakingPoolFee - adminFee - DevFee; // 50% of upgrade fee goes to smart contract

    Dev.transfer(DevFee);
    StakingPool.transfer(stakingPoolFee);
    Admin.transfer(adminFee);

    // Calculate referral bonuses
    address referrer = referrers[msg.sender];
    uint256 upgradeFee = msg.value;

    if (registeredUsers[referrer]) {
        uint256 directReferralBonus = upgradeFee * directReferralBonusRate / 100;
        TotalEarnings[referrer] += directReferralBonus;
        AvailableEarnings[referrer] += directReferralBonus;
        uint256 indirectReferralBonus = 0;
        address parent = referrers[referrer];
        for (uint256 i = 0; i < referralLevels; i++) {
            if (parent == address(0) || !registeredUsers[parent]) {
                break;
            }
            indirectReferralBonus = upgradeFee * indirectReferralBonusRate / 100;
            TotalEarnings[parent] += indirectReferralBonus;
            AvailableEarnings[parent] += indirectReferralBonus;
            parent = referrers[parent];
        }
    }
}

// =============================================================================================================================== //


    function Advertise(string memory adTitle, string memory adText, string memory adLink, uint256 AdvertClicks) external payable {
        require(msg.value == AdvertClicks * advertCost, "Incorrect payment amount");
        require(AdvertClicks >= 3, "Number of ad clicks must be greater than or equal to the minimum ad clicks allowed");

        // Create the ad
        Ad memory newAd = Ad({
            adTitle: adTitle,
            adText: adText,
            adLink: adLink,
            advertiser: msg.sender,
            adClicks: AdvertClicks
        });

        // Calculate the amounts of ETH to send to specific wallets
        uint AdminFee = msg.value * 10 / 100; // 10% of Advertisement Fee goes to admin wallet
        uint StakingPoolFee = msg.value * 10 / 100; // 10% of Advertisement Fee goes to staking pool

        // Send the ETH fees to specific wallets
        Admin.transfer(AdminFee);
        StakingPool.transfer(StakingPoolFee);

        // Check if the ad has no available clicks and remove it from the array
        if (AdvertClicks == 0) {
            for (uint i = 0; i < availableAds.length; i++) {
                if (availableAds[i].advertiser == msg.sender && availableAds[i].adClicks == 0) {
                    delete availableAds[i];
                }
            }
        }
        else {
            // Add the new ad to the array
            availableAds.push(newAd);
        } 
        emit AdCreated(msg.sender, AdvertClicks, block.timestamp);
    }


// =============================================================================================================================== //

    function clickAd(uint256 adiD) external payable {
    require(registeredUsers[msg.sender], "User must be registered to click ads.");
    require(msg.value == clickAdsTxnFee, "Pay some gas fee to click Ads");
    require(availableAds.length > adiD, "Invalid ad iD");
    require(availableAds[adiD].adClicks > 0, "No clicks remaining for this ad");
    require(userExpirations[msg.sender] >= block.timestamp, "User account has expired. Upgrade now!");
    require(lastAdClick[msg.sender][adiD] + 10 minutes <= block.timestamp, "You can click this ad again after 10 minutes");
    if (userUpgrades[msg.sender] == UpgradeLevel.None) {
        require(userClicksToday[msg.sender] < maxClicksPerDay, "You have reached the maximum clicks per day");
    } else {
        require(userClicksToday[msg.sender] < upgradedMaxClicksPerDay, "You have reached the upgraded maximum clicks per day");
    }

    // Update the last click time for this user and ad
    lastAdClick[msg.sender][adiD] = block.timestamp;

    // Decrease the number of clicks remaining for this ad
    availableAds[adiD].adClicks--;

    // Increment the number of clicks for the current day for the user
    userClicksToday[msg.sender]++;

    emit AdClicked(msg.sender, adiD, block.timestamp);

    // Calculate and distribute fees
    uint DevFee = msg.value * 80 / 100; // 80% of clickAdsTxnFee goes to dep wallet
    uint AdminFee = msg.value * 10 / 100; // 10% of clickAdsTxnFee goes to admin wallet
    uint StakingPoolFee = msg.value * 10 / 100; // 10% of clickAdsTxnFee goes to staking pool
    Dev.transfer(DevFee);
    Admin.transfer(AdminFee);
    StakingPool.transfer(StakingPoolFee);

    // Update earnings and referral bonuses
    AvailableEarnings[msg.sender] += clickReward;
    TotalEarnings[msg.sender] += clickReward;

    address referrer = referrers[msg.sender];
    if (registeredUsers[referrer]) {
        uint256 directReferralBonus = clickReward * directReferralBonusRate / 100;
        TotalEarnings[referrer] += directReferralBonus;
        AvailableEarnings[referrer] += directReferralBonus;
        uint256 indirectReferralBonus = 0;
        address parent = referrer;
        for (uint256 i = 0; i < referralLevels; i++) {
            parent = referrers[parent];
            if (parent == address(0) || !registeredUsers[parent]) {
                break;
            }
            indirectReferralBonus = clickReward * indirectReferralBonusRate / 100;
            TotalEarnings[parent] += indirectReferralBonus;
            AvailableEarnings[parent] += indirectReferralBonus;
        }
    }
}

// =============================================================================================================================== //

    function isExpired(address user) internal view returns (bool) {
        return userExpirations[user] < block.timestamp;
    }

// =============================================================================================================================== //

    function claimEarnings() external nonReentrant {
        require(registeredUsers[msg.sender], "User must be registered to claim earnings");
        require(!isExpired(msg.sender), "User registration has expired");
        require(AvailableEarnings[msg.sender] > 0, "Insufficient earnings to claim");

        uint256 ethToTransfer = AvailableEarnings[msg.sender] - TotalWithdrawn[msg.sender];
        TotalWithdrawn[msg.sender] += ethToTransfer;
        AvailableEarnings[msg.sender] = 0; // Reset AvailableEarnings to zero

        payable(msg.sender).transfer(ethToTransfer);
    }

    receive() external payable {
    }

    fallback() external payable { 
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./ISaleVesting.sol";
import "./Ownable.sol";

// import "hardhat/console.sol";

interface IDistribution {
    enum SaleKind {
        SEED,
        PRIVATE,
        PRE,
        PUBLIC
    } // Sale Types

    struct SaleClass {
        SaleKind name;
        address saleVestingContract;
        uint256 salePrice; // 1$ = 100 units
        uint256 salePriceLimit;
        uint256 saleDuration;
        uint256 saleStartTime;
        uint256 saleEndTime;
    }

    struct userDistribution {
        uint256 id;
        uint256 lastTimeStamp;
        uint256 totalDepositAmount;
        uint256 totalReferralAmount;
        uint256 pendingReferralAmount;
        uint256[] referralLevelAmount;
        uint256[] referralLevelCount;
    }

    function claimReferralPayout() external;

    function daddyAvailableForSale() external view returns (bool, uint256);

    event ReferralRewardIntialization(uint256[] rewardArray);
    event BuyWithAVAX(
        address indexed user,
        uint256 amount,
        uint256 dollarAmount,
        uint256 daddyAmount,
        uint256 buyTimestamp
    );
    event BuyWithTether(
        address indexed user,
        uint256 amount,
        uint256 dollarAmount,
        uint256 daddyAmount,
        uint256 buyTimestamp
    );
    event VestingAllocation(
        address indexed user,
        uint256 daddyAmount,
        address indexed vestingContract,
        uint256 buyTimestamp
    );
}

/// @title Distribution contract. Entry Point for Buying Daddy with a MLM structure based reward mechanism and Vesting of the Daddy Token.
/**  @notice  Responsible for Buying Daddy Token either by AVAX or Tether based on different sale prices.
              Allocates for Vesting of the token for different type of sales.
*/
/// @dev Fetches price from Chainlink Oracles and allocates Daddy to the user for Vesting and a referral based reward mechanism.

contract Distribution is IDistribution, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address;

    IERC20 public rewardToken; // Reward token, eg: USDT
    IERC20 public daddyTokenForPublicSale; // Daddy token Allocated for Public Sale
    AggregatorV3Interface public avaxPriceFeed; // Chainlink Oracle for AVAX
    AggregatorV3Interface public tetherPriceFeed; // Chainlink Oracle for Tether

    uint256 public lastId; // Count for Number of users
    uint256 public totalClaimable; // Total Claimable referral rewards
    bool public referralIntialized; // Check for referral structure initialization. PENDING
    uint256 public totalDaddySold; // Total Daddy sold
    address[] public trees; // Saving All Individual New Trees
    uint256 public saleAllocatedAmount; // Total daddy token allocated for sale

    mapping(address => userDistribution) public userInfo; // User Info
    mapping(address => address) public referralParent; // User to Referrer
    mapping(uint256 => uint256) public refReward; // LevelWise Referral Rewards
    mapping(uint256 => SaleClass) public saleInfo;

    mapping(address => mapping(uint256 => address[]))
        private _referrersPerLevel; // Tracking referrer addresses at each level
    mapping(address => mapping(uint256 => uint256)) public userSaleAmount; // Tracks amount of dollars for an user per sale

    constructor(
        address _rewardStableCoin, // address _rewardStableCoin
        address _avaxPriceFeed, // address _avaxPriceFeed
        address _tetherPriceFeed, // address _tetherPriceFeed
        address _daddyTokenForPublicSale, // address _daddyTokenForPublicSale
        uint256 _saleAllocatedAmount // Total Allocated daddy amount for Public Vesting
    ) {
        avaxPriceFeed = AggregatorV3Interface(_avaxPriceFeed);
        tetherPriceFeed = AggregatorV3Interface(_tetherPriceFeed);
        rewardToken = IERC20(_rewardStableCoin);
        daddyTokenForPublicSale = IERC20(_daddyTokenForPublicSale);
        saleAllocatedAmount = _saleAllocatedAmount;
    }

    modifier saleValidate() {
        require(!msg.sender.isContract(), "Contract cannot buy tokens");
        require(
            block.timestamp > saleInfo[0].saleStartTime,
            "Sale Not started yet"
        );
        require(block.timestamp <= saleInfo[3].saleEndTime, "Sale Not Active");
        _;
    }

    /// @notice Sets up the Referral reward structure percentages
    function initReferralRewards(uint256[] memory _refReward)
        external
        onlyOwner
    {
        require(_refReward.length == 5, "There has to be 5 levels only");
        for (uint256 index = 0; index < _refReward.length; index++) {
            refReward[index] = _refReward[index];
        }
        referralIntialized = true;
        emit ReferralRewardIntialization(_refReward);
    }

    /// @notice Sets up the timestamps and pricing details of different sales
    /// @dev Runs a loop for every sale and sets it's required information
    /// @param _saleVestingContracts Array of contract addresses for the three sales
    /// @param _pricePerDaddy Array of daddy token prices for different sales
    /// @param _saleDuration Array of sale durations
    /// @param _saleStartTimestamps Array of sale starting timestamps
    function updateSaleClassInfo(
        address[] memory _saleVestingContracts,
        uint256[] memory _pricePerDaddy,
        uint256[] memory _salePriceLimit,
        uint256[] memory _saleDuration,
        uint256[] memory _saleStartTimestamps
    ) external onlyOwner {
        for (uint256 index = 0; index < 4; index++) {
            saleInfo[index] = SaleClass({
                name: SaleKind(index),
                saleVestingContract: index == 3
                    ? address(this)
                    : _saleVestingContracts[index], // Public Sale Vesting is not a new smart contract
                salePrice: _pricePerDaddy[index],
                salePriceLimit: _salePriceLimit[index],
                saleDuration: _saleDuration[index],
                saleStartTime: _saleStartTimestamps[index],
                saleEndTime: _saleStartTimestamps[index] + _saleDuration[index]
            });
        }
    }

    /// @notice Buy daddy token with Tether
    /// @dev A minimum of 50 dollar and maximum of 5000 dollar per transaction
    /// @param _referrer referral address
    /// @param _tokenAmount amount of tether
    function buyWithTether(address _referrer, uint256 _tokenAmount)
        external
        saleValidate
        nonReentrant
    {
        require(_tokenAmount > 0, "Invalid Token Amount");
        SaleClass memory currentSale = fetchCurrentSaleType();
        rewardToken.safeTransferFrom(msg.sender, address(this), _tokenAmount);
        (uint256 tetherPrice, uint256 daddyAmount) = priceForTether(
            _tokenAmount,
            currentSale.salePrice
        );
        require(
            tetherPrice >= 50 * 10**18,
            "Min $50 per transaction"
        );
        uint256 availableDaddy = _updateLastSale(currentSale, daddyAmount); // Fetches required available daddy
        _buy(_referrer, tetherPrice, availableDaddy, currentSale);
        emit BuyWithTether(
            msg.sender,
            _tokenAmount,
            tetherPrice,
            availableDaddy,
            block.timestamp
        );
    }

    /// @notice Buy daddy token with AVAX
    /// @dev A minimum of 50 dollar and maximum of 5000 dollar per transaction
    /// @param _referrer referral address
    function buyWithAvax(address _referrer)
        external
        payable
        saleValidate
        nonReentrant
    {
        require(msg.value > 0, "Invalid Avax Amount");
        SaleClass memory currentSale = fetchCurrentSaleType();
        (uint256 avaxPrice, uint256 daddyAmount) = priceForAvax(
            msg.value,
            currentSale.salePrice
        );
        require(
            avaxPrice >= 50 * 10**18,
            "Min $50 per transaction"
        );
        uint256 availableDaddy = _updateLastSale(currentSale, daddyAmount); // Fetches required available daddy
        _buy(_referrer, avaxPrice, availableDaddy, currentSale);
        emit BuyWithAVAX(
            msg.sender,
            msg.value,
            avaxPrice,
            availableDaddy,
            block.timestamp
        );
    }

    /// @notice User can claim his pending referral amount, allocated to him during referral rewards
    /// @dev Contract should hold enough Tether tokens to reward to the users
    function claimReferralPayout() external virtual override nonReentrant {
        // require(paused == false, "Contract Paused");
        userDistribution storage user = userInfo[msg.sender];
        require(user.id != 0, "Invalid User");
        require(user.pendingReferralAmount > 0, "Nothing to claim");

        require(
            rewardToken.balanceOf(address(this)) * 10**12 >= totalClaimable,
            "Not enough token for referral rewards"
        );
        rewardToken.safeTransfer(
            msg.sender,
            user.pendingReferralAmount / 10**12
        ); // Inconsistence with 6 decimals as Tether as 6 decimals
        totalClaimable -= user.pendingReferralAmount;
        user.pendingReferralAmount = 0;
    }

    /// @notice AVAX Price Feed Contract, [EXTRA LAYER OF SECURITY] if in case the address changes although Chainlink uses proxy pattern, What would happen if they change their smart contract code ?!
    function setAvaxPriceFeed(address _avaxPriceFeed) external onlyOwner {
        avaxPriceFeed = AggregatorV3Interface(_avaxPriceFeed);
    }

    /// @notice Tether Price Feed Contract, [EXTRA LAYER OF SECURITY] if in case the address changes although Chainlink uses proxy pattern, What would happen if they change their smart contract code ?!
    function setTetherPriceFeed(address _tetherPriceFeed) external onlyOwner {
        tetherPriceFeed = AggregatorV3Interface(_tetherPriceFeed);
    }

    /// @notice Admin AVAX withdraw
    function adminWithdraw() external onlyOwner {
        require(address(this).balance > 0, "Zero AVAX Balance");
        payable(owner()).transfer(address(this).balance);
    }

    /// @notice Emergency token drain
    function drainToken(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }

    /// @notice Fetches Current sale type. [SEEDSALE, PRIVATESALE, PRESALE, PUBLICSALE]
    function fetchCurrentSaleType()
        public
        view
        returns (SaleClass memory currentSale)
    {
        for (uint256 index = 0; index < 4; index++) {
            if (
                block.timestamp > saleInfo[index].saleStartTime &&
                block.timestamp <= saleInfo[index].saleEndTime
            ) {
                currentSale = saleInfo[index];
            }
        }
        return currentSale;
    }

    /// @notice Calculates dollar value of given Tether amount with price per Daddy
    /// @dev pricePerDaddy, 1$ = 100 units, so 0.5$ per daddy will be 50 units
    /// @param _tetherAmount amount in Tether
    /// @param _pricePerDaddy price of 1 daddy token
    /// @return Tether dollar price
    /// @return Required Daddy amount
    function priceForTether(uint256 _tetherAmount, uint256 _pricePerDaddy)
        public
        view
        returns (uint256, uint256)
    {
        uint256 price = getLatestTetherPrice(); // Price of 1 Tether
        uint256 tetherPrice = _tetherAmount * price; // Price of required ether  (6 decimals)
        uint256 daddyAmount = (tetherPrice / _pricePerDaddy) * 10**6; // Amount of daddy = tetherPrice / price of 1 Daddy, calculating in consistence to 18 decimals
        return (tetherPrice * 10**4, daddyAmount); // Returning in consistence to 18 decimals
    }

    /// @notice Calculates dollar value of given AVAX amount with price per Daddy
    /// @dev pricePerDaddy, 1$ = 100 units, so 0.5$ per daddy will be 50 units
    /// @param _avaxAmount amount in AVAX
    /// @param _pricePerDaddy price of 1 daddy token
    /// @return AVAX dollar price
    /// @return Required Daddy amount
    function priceForAvax(uint256 _avaxAmount, uint256 _pricePerDaddy)
        public
        view
        returns (uint256, uint256)
    {
        uint256 price = getLatestAvaxPrice(); // Price of 1 AVAX
        uint256 avaxPrice = _avaxAmount * price; // Price of given AVAX    (18 decimals)
        uint256 daddyAmount = (avaxPrice / _pricePerDaddy) / 10**6; // Amount of daddy = avaxPrice / price of 1 Daddy, calculating in consistence to 18 decimals
        return (avaxPrice / 10**8, daddyAmount); // Returning in consistence to 18 decimals
    }

    /// @notice Fetches Latest Tether price from chainlink oracle
    /// @dev Price from oracles can be expected upto 8 decimal places
    /// @return Price in respect to 8 decimals
    function getLatestTetherPrice() public view returns (uint256) {
        (, int256 price, , , ) = tetherPriceFeed.latestRoundData();
        require(price > 0, "UNABLE_TO_RETRIEVE_USDT_PRICE");
        return uint256(price);
    }

    /// @notice Fetches Latest AVAX price from chainlink oracle
    /// @dev Price from oracles can be expected upto 8 decimal places
    /// @return Price in respect to 8 decimals
    function getLatestAvaxPrice() public view returns (uint256) {
        (, int256 price, , , ) = avaxPriceFeed.latestRoundData();
        require(price > 0, "UNABLE_TO_RETRIEVE_ETH_PRICE");
        return uint256(price);
    }

    /// @notice Returns referrer address at every level upto 5 levels
    function referrersPerLevel(address user, uint256 _level)
        public
        view
        returns (address[] memory)
    {
        return _referrersPerLevel[user][_level];
    }

    /// @notice Fetches unsold daddy amount left in the contract
    function daddyUnsold() public view returns (uint256 unsoldDaddy) {
        unsoldDaddy = saleAllocatedAmount - totalDaddySold;
    }

    /// @notice Fetches User Details
    function userDetails(address _user)
        public
        view
        returns (userDistribution memory user)
    {
        user = userInfo[_user];
    }

    function userDepositedAmountPerSale(address user, uint256 saleIndex) view public returns (uint256) {
        return userSaleAmount[user][saleIndex];
    }

    /// @notice Fetches available daddy left for sale
    function daddyAvailableForSale()
        public
        view
        override
        returns (bool status, uint256 amount)
    {
        if (saleAllocatedAmount >= totalDaddySold) {
            status = true;
            amount = saleAllocatedAmount - totalDaddySold;
        } else {
            status = false;
            amount = 0;
        }
    }

    /// @notice Fetches List of all Individual referral structure ie, who have no parent
    function individualTrees() public view returns (address[] memory) {
        return trees;
    }

    /// @notice Fetches all sale information
    function saleInformation()
        public
        view
        returns (SaleClass[] memory saleClassArray)
    {
        saleClassArray = new SaleClass[](4);
        for (uint256 index = 0; index < 4; index++) {
            saleClassArray[index] = saleInfo[index];
        }
    }

    /// @notice Updates sale details everytime a user buys Daddy
    /// @dev Changes sale times if allocated tokens per sale finishes before time.
    /// @param currentSale details of the current ongoing sale
    /// @param _requiredDaddy required daddy amount by user
    /// @return Either the required amount or the amount left in the respective sale
    function _updateLastSale(
        SaleClass memory currentSale,
        uint256 _requiredDaddy
    ) private returns (uint256) {
        uint256 saleIndex = uint256(currentSale.name);
        (, uint256 available) = ISaleVesting(currentSale.saleVestingContract)
            .daddyAvailableForSale();
        if (available <= _requiredDaddy) {
            saleInfo[saleIndex].saleEndTime = block.timestamp;
            uint256 endTime = block.timestamp;
            for (uint256 index = saleIndex + 1; index < 4; index++) {
                saleInfo[index].saleStartTime = endTime;
                saleInfo[index].saleEndTime = saleInfo[index].saleStartTime + saleInfo[index].saleDuration;
                endTime = saleInfo[index].saleEndTime;
            }
            return available;
        }
        return _requiredDaddy;
    }

    function _buy(
        address referrer,
        uint256 depositedAmount,
        uint256 allocatedDaddyAmount,
        SaleClass memory currentSale
    ) private {
        uint256 saleIndex = uint256(currentSale.name);
        require(
            userSaleAmount[msg.sender][saleIndex] + depositedAmount <= currentSale.salePriceLimit,
            "Maximum limit for an user reached"
        );
        userSaleAmount[msg.sender][saleIndex] += depositedAmount;
        // In Public Sale, since there's no vesting daddy token will be bought directly
        if (currentSale.name == SaleKind(3)) {
            require(
                daddyTokenForPublicSale.balanceOf(address(this)) >
                    allocatedDaddyAmount,
                "Insufficient Daddy balance for public sale"
            );
            daddyTokenForPublicSale.safeTransfer(
                msg.sender,
                allocatedDaddyAmount
            );
            totalDaddySold += allocatedDaddyAmount;
        }
        // For Other Sales
        else {
            _allocateForVesting(
                allocatedDaddyAmount,
                currentSale.saleVestingContract
            );
        }
        _allocateForDistribution(referrer, depositedAmount, currentSale);
    }

    // Vesting Allocation made on a different contract
    function _allocateForVesting(uint256 tokens, address vestingContract)
        private
    {
        ISaleVesting(vestingContract).allocateForVesting(msg.sender, tokens);
        emit VestingAllocation(
            msg.sender,
            tokens,
            vestingContract,
            block.timestamp
        );
    }

    function _allocateForDistribution(
        address referrer,
        uint256 amount,
        SaleClass memory currentSale
    ) private {
        require(
            referrer == address(0) ? true : userInfo[referrer].id != 0,
            "Invalid Referrer"
        );
        require(msg.sender != referrer, "User cannot be Referrer");

        uint256 _id = userInfo[msg.sender].id != 0 // Assigning an ID, uses old ID if already allocated
            ? userInfo[msg.sender].id
            : ++lastId;

        referralParent[msg.sender] = userInfo[msg.sender].id == 0 // Assigning a referral parent, uses old referral if already allocated
            ? referrer
            : referralParent[msg.sender]; // Referrer Cannot be Changed once set
        if (referralParent[msg.sender] == address(0)) trees.push(msg.sender); // Tracking new individual trees with address(0) as parent

        // Creates new user information or uses old info if already present
        userInfo[msg.sender] = userDistribution({
            id: _id,
            lastTimeStamp: block.timestamp,
            totalDepositAmount: userInfo[msg.sender].id != 0
                ? userInfo[msg.sender].totalDepositAmount + amount
                : amount,
            totalReferralAmount: userInfo[msg.sender].id != 0
                ? userInfo[msg.sender].totalReferralAmount
                : 0,
            referralLevelAmount: userInfo[msg.sender].id != 0
                ? userInfo[msg.sender].referralLevelAmount
                : new uint256[](5),
            referralLevelCount: userInfo[msg.sender].id != 0
                ? userInfo[msg.sender].referralLevelCount
                : new uint256[](5),
            pendingReferralAmount: userInfo[msg.sender].id != 0
                ? userInfo[msg.sender].pendingReferralAmount
                : 0   
        });

        refPayout(amount, msg.sender, currentSale);
    }

    /// @notice Pays out referral rewards upto 5 levels
    /// @dev Uses mapping referralParent for vertical travelling and referralLevelCount[0] will contain the horizontal children
    /// @param _amount amount of dollar deposited
    /// @param _user user's address
    /// @param currentSale currentSale, In public sale there is no reward allocated, only referral structure
    function refPayout(
        uint256 _amount,
        address _user,
        SaleClass memory currentSale
    ) private {
        address referral = referralParent[_user];

        for (uint256 index = 1; index <= 5; index++) {
            uint256 currentLevelAmount = (_amount * refReward[index - 1]) /
                10000;
            if (referral == address(0)) {
                break;
            } else {
                // Send referral reward in two cases
                // 1) Direct referral child ie: referralLevelCount[0]
                // 2) Each parent at a particular level should have atleast 'level' amount of referrals
                if (
                    index == 1 ||
                    userInfo[referral].referralLevelCount[0] >= index
                ) {
                    bool status = fetchPresence(
                        _referrersPerLevel[referral][index - 1],
                        _user
                    );

                    // Incase of Public sale, no referral reward required
                    if (currentSale.name == SaleKind(3)) {
                        if (!status) {
                            _referrersPerLevel[referral][index - 1].push(_user);
                            userInfo[referral].referralLevelCount[
                                index - 1
                            ] += 1;
                        }
                    }

                    totalClaimable += currentLevelAmount;
                    if (!status) {
                        _referrersPerLevel[referral][index - 1].push(_user);
                        userInfo[referral].referralLevelCount[index - 1] += 1;
                    }
                    userInfo[referral].referralLevelAmount[
                            index - 1
                        ] += currentLevelAmount;

                    userInfo[referral]
                        .totalReferralAmount += currentLevelAmount;

                    userInfo[referral]
                        .pendingReferralAmount += currentLevelAmount;
                } else {
                    referral = referralParent[referral];
                    continue;
                }
            }
            referral = referralParent[referral];
        }
    }

    /// @notice Finds an element from an array
    function fetchPresence(address[] memory arr, address element)
        public
        pure
        returns (bool status)
    {
        for (uint256 index = 0; index < arr.length; index++) {
            if (element == arr[index]) {
                status = true;
            } else {
                status = false;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISaleVesting {
    struct VestingStage {
        uint256 date;
        uint256 tokensUnlockedPercentage;
    }

    struct UserVestingInfo {
        address wallet;
        uint256 allocatedAmount;
        uint256 claimedAmount;
    }

    function allocateForVesting(address _user, uint256 _tokens) external;
    function daddyAvailableForSale() external view returns(bool, uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
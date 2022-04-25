/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-25
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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

// Inheritance




error NOT_OWNER();

contract Ownable {
    address public _owner;

    constructor() {
       _owner = msg.sender;
       emit OwnershipTransferred(address(0), msg.sender);
    }

    modifier onlyOwner() {
        if (_owner != msg.sender) revert NOT_OWNER();
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

// https://docs.synthetix.io/contracts/source/contracts/pausable
contract Pausable is Ownable {
    uint public lastPauseTime;
    bool public paused;

    constructor() {
        // This contract is abstract, and thus cannot be instantiated directly
        require(_owner != address(0), "OWNER_NOT_SET");
        // Paused will be false, and lastPauseTime will be 0 upon initialisation
    }

    /**
     * @notice Change the paused state of the contract
     * @dev Only the contract owner may call this.
     */
    function setPaused(bool _paused) external onlyOwner {
        if (_paused == paused) {
            return;
        }

        paused = _paused;

        if (_paused) {
            lastPauseTime = block.timestamp;
        }

        // Let everyone know that our pause state has changed.
        emit PauseChanged(_paused);
    }

    event PauseChanged(bool isPaused);

    modifier notPaused {
        require(!paused, "CONTRACT_PAUSED");
        _;
    }
}

contract DailyPool is Pausable {

    IERC721 public immutable stakingToken;
    IERC20 public immutable rewardToken;
    uint256 public immutable startTime;

    //Math Accounting
    mapping(uint256 => DayInfo) public dailyInfo;
    mapping(uint256 => mapping(address => uint256)) public dailyUserStakes;

    //Stores token info while staked in the pool
    mapping(uint256 => TokenData) public stakedTokens;
    uint256 public currentDay;

    struct DayInfo {
        uint32 totalStake;
        uint224 rewardPerToken;
    }

    struct TokenData {
        //4 free bytes
        address owner;
        uint32 dayStaked;
        uint32 tokenWeight;
    }

    constructor(
        address _stakingToken,
        address _rewardToken,
        uint256 _startTime
    ) {
        stakingToken = IERC721(_stakingToken);
        rewardToken = IERC20(_rewardToken);
        startTime = _startTime;
    }

    function deposit(uint tokenId) public notPaused() checkDay() {
        if (stakingToken.ownerOf(tokenId) != msg.sender)
            revert NotTokenOwner(tokenId);

        uint32 tokenWeight = getTokenWeight(tokenId);
        uint256 _currentDay = currentDay;
        dailyInfo[_currentDay].totalStake += tokenWeight;
        dailyUserStakes[_currentDay][msg.sender] += tokenWeight;
        stakedTokens[tokenId] = TokenData(msg.sender, uint32(_currentDay), tokenWeight);
        
        emit Deposit(msg.sender, tokenId, _currentDay);
        stakingToken.transferFrom(msg.sender, address(this), tokenId);
    }

    function withdraw(uint256 tokenId) public checkDay() {
        TokenData memory _tokenData = stakedTokens[tokenId];
        if (_tokenData.owner != msg.sender)
            revert NotTokenOwner(tokenId);
            
        uint256 _currentDay = currentDay;
        if (_tokenData.dayStaked == _currentDay) {
            //If the user unstaked on the same day they staked, forfeit their rewards
            dailyInfo[_currentDay].totalStake -= _tokenData.tokenWeight;
            dailyUserStakes[_currentDay][msg.sender] -= _tokenData.tokenWeight;
        }
        //This removes access to the token but leaves slot warm
        delete stakedTokens[tokenId];

        emit Withdraw(msg.sender, tokenId, _currentDay);
        stakingToken.transferFrom(address(this), msg.sender, tokenId);
    }

    function restake(uint256 tokenId) public checkDay() {
        TokenData memory _tokenData = stakedTokens[tokenId];
        if (_tokenData.owner != msg.sender)
            revert NotTokenOwner(tokenId);

        uint256 _currentDay = currentDay;
        //Restaking on the same day will do nothing
        if (_tokenData.dayStaked == _currentDay) return;
        uint32 newTokenWeight = getTokenWeight(tokenId);
        dailyInfo[_currentDay].totalStake += newTokenWeight;
        dailyUserStakes[_currentDay][msg.sender] += newTokenWeight;

        stakedTokens[tokenId] = TokenData(msg.sender, uint32(_currentDay), newTokenWeight);

    }
    
    function payoutDay(uint256 day) public notPaused() checkDay() {
        require(day < currentDay);

        //Get user stake from that day and calculate payout
        uint256 userStake = dailyUserStakes[day][msg.sender];
        uint256 payout = userStake * dailyInfo[day].rewardPerToken;
        dailyUserStakes[day][msg.sender] = 0;
        
        emit PayoutDay(msg.sender, day, payout);
        rewardToken.transfer(msg.sender, payout);
    }

    modifier checkDay() {
        checkForNewDay();
        _;
    }

    /// @dev Checks if a new day has passed and updates accounting accordingly
    function checkForNewDay() public {
        require(block.timestamp >= startTime);
        uint256 newCurrentDay = (block.timestamp - startTime) / 1 days;
        if (newCurrentDay > currentDay) {
            //If a new day, update currentDay to the new latest day
            //and set the rewards per token payout for the last day
            uint256 prevDay = currentDay;
            uint256 prevDayStake = dailyInfo[prevDay].totalStake;
            uint224 rewardPerToken = (prevDayStake == 0) ? 0 : uint224(estimateDailyEmissions() / prevDayStake);
            dailyInfo[prevDay].rewardPerToken = rewardPerToken;
                
            currentDay = newCurrentDay;
            emit RewardsSet(prevDay, rewardPerToken);
        }
    }

    /// @notice Returns daily emissions if a new day was started at execution time
    function estimateDailyEmissions() public view returns(uint256) {
        return rewardToken.balanceOf(address(this)) / 100;
    }

    /// @dev Returns staking weight for a given tokenId
    ///      For a pool with equal weighting should return a constant
    function getTokenWeight(uint256) public pure returns(uint32) {
        return 1;
    }

    function getUserDayPayout(address user, uint256 day) public view returns(uint256) {
        uint256 userStake = dailyUserStakes[day][user];
        return userStake * dailyInfo[day].rewardPerToken;
    }

    function estimateCurrentRewards(address user, uint256 additionalStake) public view returns(uint256) {
        uint256 userStake = dailyUserStakes[currentDay][user] + additionalStake;
        // [0, 1e18] as fixed point
        uint256 stakeProportion = userStake * 1e18 / (dailyInfo[currentDay].totalStake + additionalStake);
        return stakeProportion * estimateDailyEmissions() / 1e18;
    } 

    error NotTokenOwner(uint tokenId);

    //Events
    event Deposit(address indexed user, uint256 indexed tokenId, uint256 indexed currentDay);
    event Withdraw(address indexed user, uint256 indexed tokenId, uint256 indexed currentDay);
    event PayoutDay(address indexed user, uint256 indexed payoutDay, uint256 payout);
    event RewardsSet(uint256 indexed day, uint224 rewardPerToken);
}
/**
 *Submitted for verification at snowtrace.io on 2022-09-07
*/

// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts-old/token/ERC20/[email protected]

pragma solidity ^0.6.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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


// File @openzeppelin/contracts-old/math/[email protected]

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


// File @openzeppelin/contracts-old/utils/[email protected]

pragma solidity ^0.6.2;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}


// File @openzeppelin/contracts-old/token/ERC20/[email protected]

pragma solidity ^0.6.0;



/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File contracts/distribution/Node.sol

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

contract Node {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IERC20 public constant TOKEN = IERC20(0x5541D83EFaD1f281571B343977648B75d95cdAC2);

    uint256 public tierAllocPoints = 150 ether;
    uint256 public tierAmounts = 50 ether;

    struct User {
        uint256 total_deposits;
        uint256 total_claims;
        uint256 last_distPoints;
        uint256 alloc_points;
        uint256 compounds;
        uint256 nodes;
    }

    event CreateNode(uint256 timestamp, address account, uint256 num);

    address public dev;
    address public treasury = 0xEB755b81A786832705a3c0658127216eD36fE898;

    mapping(address => User) public users;

    address[] public userIndices;

    uint256 public totalNodes;
    uint256 public total_deposited;
    uint256 public total_claimed;
    uint256 public total_rewards;
    uint256 public totalDistributeRewards;
    uint256 public totalDistributePoints;
    uint256 public lastDripTime = block.timestamp;

    uint256 public totalAllocPoints = 0;
    uint256 public dripRate = 4000000;
    uint256 public treasuryFeePercent = 5;
    uint256 public pegFee = 10;
    uint256 public compoundBonus = 10;

    bool public enabled = true;

    uint256 public constant MULTIPLIER = 10e18;


    constructor() public {
        dev = msg.sender;
    }

    receive() external payable {
        revert("Do not send AVAX.");
    }

    modifier onlyDev() {
        require(msg.sender == dev, "Caller is not the dev!");
        _;
    }

    function changeDev(address payable newDev) external onlyDev {
        require(newDev != address(0), "Zero address");
        dev = newDev;
    }

    function changeTreasury(address payable newTreasury) external onlyDev {
        treasury = newTreasury;
    }
    
    function setEnabled(bool _enabled) external onlyDev {
        enabled = _enabled;
    }

    function setTreasuryFeePercent(uint256 percent) external onlyDev {
        treasuryFeePercent = percent;
    }
   
    function setPegFee(uint256 percent) external onlyDev {
        pegFee = percent;
    }

    function setCompoundBonus(uint256 percent) external onlyDev {
        compoundBonus = percent;
    }

    function setDripRate(uint256 rate) external onlyDev {
        dripRate = rate;
    }
    
    function setLastDripTime(uint256 timestamp) external onlyDev {
        lastDripTime = timestamp;
    }

    function setTierValues(uint256 _tierAllocPoints, uint256 _tierAmounts) external onlyDev {
        tierAllocPoints = _tierAllocPoints;
        tierAmounts = _tierAmounts;
    }

    function setManyUsers(address[] memory _addr, User[] memory _user) external onlyDev {
        for (uint256 i = 0; i < _addr.length; i++) {

            if (users[_addr[i]].total_deposits == 0) {
                userIndices.push(_addr[i]);
            } 

            total_deposited = total_deposited.sub(users[_addr[i]].total_deposits).add(_user[i].total_deposits);
            total_claimed = total_claimed.sub(users[_addr[i]].total_claims).add(_user[i].total_claims);
            totalAllocPoints = totalAllocPoints.sub(users[_addr[i]].alloc_points).add(_user[i].alloc_points);
            totalNodes = totalNodes.sub(users[_addr[i]].nodes).add(_user[i].nodes);

            users[_addr[i]].total_deposits = _user[i].total_deposits;
            users[_addr[i]].total_claims = _user[i].total_claims;
            users[_addr[i]].last_distPoints = _user[i].last_distPoints;
            users[_addr[i]].alloc_points = _user[i].alloc_points;
            users[_addr[i]].compounds = _user[i].compounds;
            users[_addr[i]].nodes = _user[i].nodes;
        }
    }

    function getDistributionRewards(address account) public view returns (uint256) {
        uint256 userAlloc = users[account].alloc_points;

        if (userAlloc == 0) return 0;

        uint256 newDividendPoints = totalDistributePoints.sub(users[account].last_distPoints);
        uint256 distribute = userAlloc.mul(newDividendPoints).div(MULTIPLIER);
        return distribute > total_rewards ? total_rewards : distribute;
    }
    
    function getTotalRewards(address _sender) public view returns (uint256) {
        if (users[_sender].total_deposits == 0) 
            return 0;

        uint256 userAlloc = users[_sender].alloc_points;
        uint256 rewards = getDistributionRewards(_sender).add(getRewardDrip().mul(userAlloc).div(totalAllocPoints));

        // Payout remaining if exceeds max allocation
        return rewards > userAlloc ? userAlloc : rewards;
    }

    function create(uint256 tier, uint256 numNodes) external { // tier backwards compatability
    
        address _sender = msg.sender;
        require(enabled, "Disabled");

        if (users[_sender].total_deposits == 0) {
            userIndices.push(_sender); // New user
            users[_sender].last_distPoints = totalDistributePoints;
        } 
        if (users[_sender].total_deposits != 0 && users[_sender].alloc_points == 0) {
            users[_sender].last_distPoints = totalDistributePoints;
        }
        if (getTotalRewards(_sender) > 0){
            claim();
        }

        uint256 tierPrice = tierAmounts.mul(numNodes); 
        uint256 alloc = tierAllocPoints.mul(numNodes);

        require(TOKEN.balanceOf(_sender) >= tierPrice, "Insufficient balance");
        require(TOKEN.allowance(_sender, address(this)) >= tierPrice, "Insufficient allowance");
        TOKEN.safeTransferFrom(_sender, address(this), tierPrice);

        users[_sender].total_deposits = users[_sender].total_deposits.add(tierPrice); //set user total deposits
        users[_sender].alloc_points = users[_sender].alloc_points.add(alloc); //set user alloc points

        total_deposited = total_deposited.add(tierPrice); //track total deposited in contract

        totalAllocPoints += alloc; //track total contract allocations

        uint256 treasury_rewards = tierPrice.mul(treasuryFeePercent).div(100);
        TOKEN.safeTransfer(treasury, treasury_rewards); // take treasury fee and send
        
        users[_sender].nodes = users[_sender].nodes.add(numNodes); // add nodes to account
        totalNodes = totalNodes.add(numNodes); // add nodes to total

        emit CreateNode(block.timestamp, _sender, numNodes);
    }

    function claim() public { 
        dripRewards();

        address _sender = msg.sender;
        uint256 _rewards = getDistributionRewards(_sender); // get reward points 
        
        if (_rewards > 0) {

            uint256 fee = 0;
            uint256 userAlloc = users[_sender].alloc_points;

            if(pegFee > 0){
                fee = _rewards.mul(pegFee).div(100);
            }

            if(_rewards > userAlloc) { // Payout remaining if exceeds max payout
                _rewards = userAlloc;
            }

            total_rewards = total_rewards.sub(_rewards - fee); // subtract user rewards from contract claimable      

            users[_sender].alloc_points -= _rewards; //remove allocation from user

            users[_sender].total_claims = users[_sender].total_claims.add(_rewards); // add claim amount to total claims of user profile
            total_claimed = total_claimed.add(_rewards); // add rewards to total claimed amount of contract
            totalAllocPoints = totalAllocPoints.sub(_rewards);  // remove rewards from total contract alloc points
        
            IERC20(TOKEN).safeTransfer(_sender, _rewards - fee);
            
            users[_sender].last_distPoints = totalDistributePoints;
        }
    }

    function _compoundClaim() internal { 

        dripRewards();

        address _sender = msg.sender;
        uint256 _rewards = getDistributionRewards(_sender); // get reward points 
        
        if (_rewards > 0) {
            
            total_rewards = total_rewards.sub(_rewards); // subtract user rewards from contract claimable

            uint256 userAlloc = users[_sender].alloc_points;

            // Payout remaining if exceeds max payout
            if(_rewards > userAlloc) {
                _rewards = userAlloc;
            }

            users[_sender].alloc_points -= _rewards; //remove allocation from user

            users[_sender].total_claims = users[_sender].total_claims.add(_rewards); // add claim amount to total claims of user profile
            total_claimed = total_claimed.add(_rewards); // add rewards to total claimed amount of contract
            totalAllocPoints -= _rewards;  // remove rewards from total contract alloc points

            IERC20(TOKEN).safeTransfer(_sender, _rewards);
            
            users[_sender].last_distPoints = totalDistributePoints;
        }
    }


    function _compound(uint256 numNodes) internal {
    
        address _sender = msg.sender;

        _compoundClaim();

        uint256 tierPrice = tierAmounts.mul(numNodes); 
        uint256 alloc = tierAllocPoints.mul(numNodes);
        uint256 bonus = alloc.mul(compoundBonus).div(100);

        require(TOKEN.balanceOf(_sender) >= tierPrice, "Insufficient balance");
        require(TOKEN.allowance(_sender, address(this)) >= tierPrice, "Insufficient allowance");
        TOKEN.safeTransferFrom(_sender, address(this), tierPrice);

        users[_sender].total_deposits = users[_sender].total_deposits.add(tierPrice); //set user total deposits
        users[_sender].alloc_points = users[_sender].alloc_points.add(alloc).add(bonus); //set user alloc points with compound bonus

        users[_sender].compounds += numNodes; //increment user compound tracker

        total_deposited = total_deposited.add(tierPrice); //track total deposited in contract

        totalAllocPoints = totalAllocPoints.add(alloc); //track total contract allocations not adding compound bonus
        
        users[_sender].nodes = users[_sender].nodes.add(numNodes); // add nodes to account
        totalNodes = totalNodes.add(numNodes); // add nodes to total

        emit CreateNode(block.timestamp, _sender, numNodes);
    }

    function compound() public {
        uint256 rewardsPending = getTotalRewards(msg.sender);  
        uint256 numPossible = rewardsPending.div(tierAmounts);

        require(rewardsPending >= tierAmounts, "Not enough to compound"); 
        require(enabled, "Disabled"); 

        _compound(numPossible);
    }

    function _disperse(uint256 amount) internal {
        if (amount > 0 ) {
            totalDistributePoints = totalDistributePoints.add(amount.mul(MULTIPLIER).div(totalAllocPoints));
            totalDistributeRewards = totalDistributeRewards.add(amount);
            total_rewards = total_rewards.add(amount);
        }
    }

    function dripRewards() public {
        uint256 drip = getRewardDrip();

        if (drip > 0) {
            _disperse(drip);
            lastDripTime = block.timestamp;
        }
    }

    function getRewardDrip() public view returns (uint256) {
        if (lastDripTime < block.timestamp) {
            uint256 poolBalance = getBalancePool();
            uint256 secondsPassed = block.timestamp.sub(lastDripTime);
            uint256 drip = secondsPassed.mul(poolBalance).div(dripRate);

            if (drip > poolBalance) {
                drip = poolBalance;
            }

            return drip;
        }
        return 0;
    }


    function getDayDripEstimate(address _user) external view returns (uint256) {
        uint256 userAlloc = users[_user].alloc_points;
        return
            userAlloc > 0
                ? getBalancePool()
                    .mul(86400)
                    .mul(userAlloc)
                    .div(totalAllocPoints)
                    .div(dripRate)
                : 0;
    }

    function total_users() external view returns (uint256) {
        return userIndices.length;
    }

    function numNodes(address _sender) external view returns (uint256) {
        return users[_sender].nodes;
    }

    function getNodes(address _sender) external view returns (uint256) {
        return users[_sender].nodes;
    }

    function maxPayout(address _sender) external view returns (uint256) {
        return users[_sender].alloc_points;
    }
    
    function getTotalNodes() external view returns (uint256) {
        return totalNodes;
    }

    function getBalance() public view returns (uint256) {
        return IERC20(TOKEN).balanceOf(address(this));
    }

     function getBalancePool() public view returns (uint256) {
        return getBalance().sub(total_rewards);
    }

    function emergencyWithdraw(IERC20 token, uint256 amnt) external onlyDev {
        token.safeTransfer(dev, amnt);
    }
}
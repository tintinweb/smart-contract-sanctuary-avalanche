/**
 *Submitted for verification at snowtrace.io on 2022-04-24
*/

// SPDX-License-Identifier: MIT
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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

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

contract ContexiaStaking is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 firstTimeDeposited;
        uint256 lastTimeDeposited;
        //
        // We do some fancy math here. Basically, any point in time, the amount of cons
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accconPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accconPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    // Info of each pool.
    struct PoolInfo {
        address lpToken; // Address of LP token contract.
        uint256 lastRewardBlock; // Last block number that cons distribution occurs.
        uint256 accconPerShare; // Accumulated cons per share, times 1e12. See below.
    }
    // The CON TOKEN!
    address public con;
    // The Con node purchaser
    address public nodePurchaser;
    // Block number when bonus CON period ends.
    uint256 public bonusFirstEndBlock;
    uint256 public bonusSecondEndBlock;
    // CON tokens created per block.
    uint256 public conPerBlock;
    // The block number when CON mining starts.
    uint256 public startBlock;
    uint256 public rewardEndBlock;
    // Bonus muliplier for early CON makers.
    uint256 public firstMultiplier;
    uint256 public secondMultiplier;
    // Reward Pool Address
    address public rewardsPool;
    // Info of each pool.
    PoolInfo public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(address => UserInfo) public userInfo;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Harvest(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);

    constructor(
        address _con,
        address _purchaser,
        address _lpToken,
        uint256 _conPerBlock,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _bonusFirstEndBlock,
        uint256 _bonusSecondEndBlock,
        address _rewardsPool
    ) {
        con = _con;
        nodePurchaser = _purchaser;
        conPerBlock = _conPerBlock;
        bonusFirstEndBlock = _bonusFirstEndBlock;
        bonusSecondEndBlock = _bonusSecondEndBlock;
        startBlock = _startBlock;
        rewardEndBlock = _endBlock;
        rewardsPool = _rewardsPool;
        require(_bonusSecondEndBlock < rewardEndBlock);
        poolInfo = PoolInfo({
            lpToken: _lpToken,
            lastRewardBlock: startBlock,
            accconPerShare: 0
        });
        
        firstMultiplier = 300;
        secondMultiplier = 150;

    }

    function getCurrentRewardsPerBlock() public view returns (uint256) {
        if (block.number < startBlock || block.number >= rewardEndBlock) {
            return 0;
        }
        if (block.number < bonusFirstEndBlock) {
            return conPerBlock.mul(firstMultiplier).div(100);
        } else if (block.number < bonusSecondEndBlock) {
            return conPerBlock.mul(secondMultiplier).div(100);
        } else {
            return conPerBlock;
        }
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        _to = Math.min(rewardEndBlock, _to);
        if (_from >= _to) {
            return 0;
        }
        // First case ===> _from <= bonusFirstEndBlock and below 3 cases of _to
        if (_from <= bonusFirstEndBlock) {
            if (_to <= bonusFirstEndBlock) {
                return _to.sub(_from).mul(firstMultiplier).div(100);
            } else if (_to > bonusFirstEndBlock && _to <= bonusSecondEndBlock) {
                return
                    bonusFirstEndBlock
                        .sub(_from)
                        .mul(firstMultiplier)
                        .add(_to.sub(bonusFirstEndBlock).mul(secondMultiplier))
                        .div(100);
            } else {
                return
                    bonusFirstEndBlock
                        .sub(_from)
                        .mul(firstMultiplier)
                        .add(
                            bonusSecondEndBlock.sub(bonusFirstEndBlock).mul(
                                secondMultiplier
                            )
                        )
                        .div(100)
                        .add(_to.sub(bonusSecondEndBlock));
            }
        }
        // Second case ===> _from <= bonusSecondEndBlock
        else if (_from > bonusFirstEndBlock && _from < bonusSecondEndBlock) {
            if (_to <= bonusSecondEndBlock) {
                return _to.sub(_from).mul(secondMultiplier).div(100);
            } else {
                return
                    bonusSecondEndBlock
                        .sub(_from)
                        .mul(secondMultiplier)
                        .div(100)
                        .add(_to.sub(bonusSecondEndBlock));
            }
        }
        // Third case ===> _from > bonusSecondEndBlock
        else {
            return _to.sub(_from);
        }
    }

    // View function to see pending cons on frontend.
    function pendingRewards(address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 accconPerShare = poolInfo.accconPerShare;
        uint256 lpSupply = IERC20(poolInfo.lpToken).balanceOf(address(this));
        if (block.number > poolInfo.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(
                poolInfo.lastRewardBlock,
                block.number
            );
            uint256 conReward = multiplier.mul(conPerBlock);
            accconPerShare = accconPerShare.add(
                conReward.mul(1e12).div(lpSupply)
            );
        }
        return user.amount.mul(accconPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool() public {
        if (block.number <= poolInfo.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = IERC20(poolInfo.lpToken).balanceOf(address(this));
        if (lpSupply == 0) {
            poolInfo.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(
            poolInfo.lastRewardBlock,
            block.number
        );
        uint256 conReward = multiplier.mul(conPerBlock);
        poolInfo.accconPerShare = poolInfo.accconPerShare.add(
            conReward.mul(1e12).div(lpSupply)
        );
        poolInfo.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for con allocation.
    function deposit(uint256 _amount) public nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        updatePool();
        IERC20(poolInfo.lpToken).transferFrom(
            msg.sender,
            address(this),
            _amount
        );
        user.amount = user.amount.add(_amount);
        if (user.firstTimeDeposited == 0) {
            user.firstTimeDeposited = block.timestamp;
        }
        user.lastTimeDeposited = block.timestamp;
        user.rewardDebt = _amount.mul(poolInfo.accconPerShare).div(1e12).add(
            user.rewardDebt
        );
        emit Deposit(msg.sender, _amount);
    }

    // Claim pending rewards
    function harvest(address account) external nonReentrant {
        require(account == msg.sender, "Account not signer");
        UserInfo storage user = userInfo[account];
        updatePool();
        uint256 pending = user
            .amount
            .mul(poolInfo.accconPerShare)
            .div(1e12)
            .sub(user.rewardDebt);
        user.rewardDebt = user.amount.mul(poolInfo.accconPerShare).div(1e12);
        require(pending > 0, "Nothing to claim");
        if (pending > 0) {
            _safeconTransfer(account, pending);
        }
        emit Harvest(account, pending);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _amount) external nonReentrant {
        require(_amount > 0, "amount 0");
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "withdraw: not good");

        updatePool();
        uint256 pending = user
            .amount
            .mul(poolInfo.accconPerShare)
            .div(1e12)
            .sub(user.rewardDebt);
        user.rewardDebt = user.amount.mul(poolInfo.accconPerShare).div(1e12);
        if (pending > 0) {
            _safeconTransfer(msg.sender, pending);
        }

        user.rewardDebt = user
            .amount
            .sub(_amount)
            .mul(poolInfo.accconPerShare)
            .div(1e12);
        user.amount = user.amount.sub(_amount);

        IERC20(poolInfo.lpToken).transfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _amount);
    }

    function withdrawOnBehalf(address account, uint256 _amount)
        external
        nonReentrant
    {
        require(msg.sender == nodePurchaser, "Must be Node Purchaser");

        require(_amount > 0, "amount 0");
        UserInfo storage user = userInfo[account];
        require(user.amount >= _amount, "withdraw: not good");

        updatePool();
        uint256 pending = user
            .amount
            .mul(poolInfo.accconPerShare)
            .div(1e12)
            .sub(user.rewardDebt);
        user.rewardDebt = user.amount.mul(poolInfo.accconPerShare).div(1e12);
        if (pending > 0) {
            _safeconTransfer(account, pending);
        }

        user.rewardDebt = user
            .amount
            .sub(_amount)
            .mul(poolInfo.accconPerShare)
            .div(1e12);
        user.amount = user.amount.sub(_amount);

        IERC20(poolInfo.lpToken).transfer(account, _amount);
        emit Withdraw(account, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(address account) public {
        UserInfo storage user = userInfo[account];

        IERC20(poolInfo.lpToken).transfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(account, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Safe con transfer function, just in case if rounding error causes pool to not have enough cons.
    function _safeconTransfer(address _to, uint256 _amount) internal {
        uint256 conBal = IERC20(con).balanceOf(address(this));
        if (_amount > conBal) {
            IERC20(con).transferFrom(rewardsPool, _to, conBal);
        } else {
            IERC20(con).transferFrom(rewardsPool, _to, _amount);
        }
    }

    function updateLPToken(address _lpToken) external onlyOwner {
        poolInfo.lpToken = _lpToken;
    }

    function setConToken(address _token) external onlyOwner {
        con = _token;
    }

    function setNodePurchaser(address _purchaser) external onlyOwner {
        nodePurchaser = _purchaser;
    }

    function setStartBlock(uint256 _start) external onlyOwner {
        startBlock = _start;
    }

    function setEndBlock(uint256 _block) external onlyOwner {
        rewardEndBlock = _block;
    }

    function setBonusFirstBlockEnd(uint256 _block) external onlyOwner {
        bonusFirstEndBlock = _block;
    }

    function setBonusSecondBlockEnd(uint256 _block) external onlyOwner {
        bonusSecondEndBlock = _block;
    }

    function setconPerBlock(uint256 rewards) external onlyOwner {
        conPerBlock = rewards;
    }

    function setBonusMultiplier(uint256 first, uint256 second)
        external
        onlyOwner
    {
        firstMultiplier = first;
        secondMultiplier = second;
    }

    function setRewardsPool(address _pool) external onlyOwner {
        rewardsPool = _pool;
    }

    function setPoolInfo(uint256 lastRewardTime) external onlyOwner {
        poolInfo.lastRewardBlock = lastRewardTime;
    }
}
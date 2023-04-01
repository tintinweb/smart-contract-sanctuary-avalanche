/**
 *Submitted for verification at snowtrace.io on 2023-03-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {
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
     *
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
     *
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: contracts/Ownable.sol
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function setOwnableConstructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

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


interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function mint(address to, uint256 amount) external;
    // event Transfer(address indexed from, address indexed to, uint256 value);

    // event Approval(
    //     address indexed owner,
    //     address indexed spender,
    //     uint256 value
    // );
}

interface IPangolinRouter {
    function factory() external pure returns (address);
    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityAVAX(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountAVAX, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityAVAX(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountAVAX);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityAVAXWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountAVAX);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactAVAXForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactAVAX(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForAVAX(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapAVAXForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external returns (uint amountAVAX);
    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IWAVAX {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface IToken {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);
}

contract BTFLockup is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // The address of the smart chef factory
    address public POOL_FACTORY;

    // Whether it is initialized
    bool public isInitialized;
    uint256 public duration = 365; // 365 days

    // Whether a limit is set for users
    bool public hasUserLimit;
    // The pool limit (0 if none)
    uint256 public poolLimitPerUser;

    // The block number when staking starts.
    uint256 public startBlock;
    // The block number when staking ends.
    uint256 public bonusEndBlock;

    // swap router and path, slipPage
    uint256 public slippageFactor = 950; // 5% default slippage tolerance
    uint256 public constant slippageFactorUL = 995;

    address public uniRouterAddress;
    address[] public earnedToStakedPath;

    address public walletA;

    // The precision factor
    uint256 public PRECISION_FACTOR;

    // The staked token
    address public stakingToken;
    // The earned token
    address public earnedToken;

    uint256 public totalStaked;

    uint256 private totalEarned;

    struct Lockup {
        uint8 stakeType;
        uint256 duration;
        uint256 depositFee;
        uint256 withdrawFee;
        uint256 rate;
        uint256 accTokenPerShare;
        uint256 lastRewardBlock;
        uint256 totalStaked;
        bool enableCompound;
    }

    struct UserInfo {
        uint256 amount; // How many staked tokens the user has provided
        uint256 locked;
        uint256 available;
    }

    struct Stake {
        uint8 stakeType;
        uint256 amount; // amount to stake
        uint256 duration; // the lockup duration of the stake
        uint256 end; // when does the staking period end
        uint256 rewardDebt; // Reward debt
    }
    uint256 constant MAX_STAKES = 256;

    Lockup[] public lockups;
    mapping(address => Stake[]) public userStakes;
    mapping(address => UserInfo) public userStaked;

    event Deposit(address indexed user, uint256 stakeType, uint256 amount);
    event Withdraw(address indexed user, uint256 stakeType, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event AdminTokenRecovered(address tokenRecovered, uint256 amount);

    event NewStartAndEndBlocks(uint256 startBlock, uint256 endBlock);
    event LockupUpdated(
        uint8 _type,
        uint256 _duration,
        uint256 _fee0,
        uint256 _fee1,
        uint256 _rate,
        bool _enableCompound
    );
    event NewPoolLimit(uint256 poolLimitPerUser);
    event RewardsStop(uint256 blockNumber);

    event DevWalletUpdated(address _dev);
    event CharityWalletUpdated(address _charity);
    event WalletAUpadted(address _walletA);
    event BuybackAddressUpadted(address _addr);
    event DurationUpdated(uint256 _duration);

    event SetSettings(
        uint256 _slippageFactor,
        address _uniRouter,
        address[] _path0
    );

    constructor() {
        POOL_FACTORY = msg.sender;
    }

    /*
     * @notice Initialize the contract
     * @param _stakingToken: staked token address
     * @param _earnedToken: earned token address
     * @param _uniRouter: uniswap router address for swap tokens
     * @param _earnedToStakedPath: swap path to compound (earned -> staking path)
     */
    function initialize(
        address _stakingToken,
        address _earnedToken,
        address _uniRouter,
        address[] memory _earnedToStakedPath
    ) external {
        require(!isInitialized, "Already initialized");
        require(msg.sender == POOL_FACTORY, "Not factory");

        // Make this contract initialized
        isInitialized = true;

        stakingToken = _stakingToken;
        earnedToken = _earnedToken;

        walletA = msg.sender;

        uint256 decimalsRewardToken = uint256(
            IToken(address(earnedToken)).decimals()
        );
        require(decimalsRewardToken < 30, "Must be inferior to 30");
        PRECISION_FACTOR = uint256(10**(uint256(40).sub(decimalsRewardToken)));

        uniRouterAddress = _uniRouter;
        earnedToStakedPath = _earnedToStakedPath;

        // should 365, 365 * 2 etc. Need to update on mainnet
        lockups.push(Lockup(0, 1, 10, 10, 0, 0, 0, 0, true));
        lockups.push(Lockup(1, 1 * 2, 10, 10, 0, 0, 0, 0, true));
        lockups.push(Lockup(2, 1 * 3, 10, 10, 0, 0, 0, 0, true));
        lockups.push(Lockup(3, 1 * 4, 10, 10, 0, 0, 0, 0, true));

        _resetAllowances();
    }

    function getLatestLockEndTime(address _account, uint8 _stakeType)
        external
        view
        returns (uint256)
    {
        require(_stakeType < lockups.length, "Invalid stake type");

        Stake[] storage stakes = userStakes[_account];
        uint256 end = 0;
        for (uint256 j = 0; j < stakes.length; j++) {
            Stake storage stake = stakes[j];
            if (stake.stakeType != _stakeType) continue;
            if (stake.amount == 0) continue;

            end = stake.end;
            break;
        }
        return end;
    }

    /*
     * @notice Deposit staked tokens and collect reward tokens (if any)
     * @param _amount: amount to withdraw (in earnedToken)
     */
    function deposit(uint256 _amount, uint8 _stakeType) external nonReentrant {
        require(_amount > 0, "Amount should be greator than 0");
        require(_stakeType < lockups.length, "Invalid stake type");

        _updatePool(_stakeType);

        UserInfo storage user = userStaked[msg.sender];
        Stake[] storage stakes = userStakes[msg.sender];
        Lockup storage lockup = lockups[_stakeType];

        uint256 pending = 0;
        uint256 pendingCompound = 0;
        uint256 compounded = 0;
        for (uint256 j = 0; j < stakes.length; j++) {
            Stake storage stake = stakes[j];
            if (stake.stakeType != _stakeType) continue;
            if (stake.amount == 0) continue;

            uint256 _pending = stake
                .amount
                .mul(lockup.accTokenPerShare)
                .div(PRECISION_FACTOR)
                .sub(stake.rewardDebt);
            if (stake.end > block.timestamp) {
                pendingCompound = pendingCompound.add(_pending);

                if (
                    address(stakingToken) != address(earnedToken) &&
                    _pending > 0
                ) {
                    uint256 _beforeAmount = IERC20(stakingToken).balanceOf(
                        address(this)
                    );
                    _safeSwap(_pending, earnedToStakedPath, address(this));
                    uint256 _afterAmount = IERC20(stakingToken).balanceOf(
                        address(this)
                    );
                    _pending = _afterAmount.sub(_beforeAmount);
                }
                compounded = compounded.add(_pending);
                stake.amount = stake.amount.add(_pending);
            } else {
                pending = pending.add(_pending);
            }
            stake.rewardDebt = stake.amount.mul(lockup.accTokenPerShare).div(
                PRECISION_FACTOR
            );
        }

        // if (compounded > 0) {
        //     IERC20(stakingToken).transfer(address(this), compounded);
        // }

        if (pending > 0) {
            IERC20(earnedToken).transfer(address(msg.sender), pending);

            if (totalEarned > pending) {
                totalEarned = totalEarned.sub(pending);
            } else {
                totalEarned = 0;
            }
        }

        if (pendingCompound > 0) {
            if (totalEarned > pendingCompound) {
                totalEarned = totalEarned.sub(pendingCompound);
            } else {
                totalEarned = 0;
            }
        }

        uint256 beforeAmount = IERC20(stakingToken).balanceOf(address(this));
        IERC20(stakingToken).transferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        uint256 afterAmount = IERC20(stakingToken).balanceOf(address(this));
        uint256 realAmount = afterAmount.sub(beforeAmount);

        if (hasUserLimit) {
            require(
                realAmount.add(user.amount) <= poolLimitPerUser,
                "User amount above limit"
            );
        }
        if (lockup.depositFee > 0) {
            uint256 fee = realAmount.mul(lockup.depositFee).div(10000);
            if (fee > 0) {
                IERC20(stakingToken).transfer(walletA, fee);
                realAmount = realAmount.sub(fee);
            }
        }

        _addStake(_stakeType, msg.sender, lockup.duration, realAmount);

        user.amount = user.amount.add(realAmount).add(compounded);
        lockup.totalStaked = lockup.totalStaked.add(realAmount).add(compounded);
        totalStaked = totalStaked.add(realAmount).add(compounded);

        emit Deposit(msg.sender, _stakeType, realAmount.add(compounded));
    }

    function _addStake(
        uint8 _stakeType,
        address _account,
        uint256 _duration,
        uint256 _amount
    ) internal {
        Stake[] storage stakes = userStakes[_account];

        uint256 end = block.timestamp.add(_duration.mul(1 hours)); // should be 1 days. Need to update on mainnet
        uint256 i = stakes.length;
        require(i < MAX_STAKES, "Max stakes");

        stakes.push(); // grow the array
        // find the spot where we can insert the current stake
        // this should make an increasing list sorted by end
        while (i != 0 && stakes[i - 1].end > end) {
            // shift it back one
            stakes[i] = stakes[i - 1];
            i -= 1;
        }

        Lockup storage lockup = lockups[_stakeType];

        // insert the stake
        Stake storage newStake = stakes[i];
        newStake.stakeType = _stakeType;
        newStake.duration = _duration;
        newStake.end = end;
        newStake.amount = _amount;
        newStake.rewardDebt = newStake.amount.mul(lockup.accTokenPerShare).div(
            PRECISION_FACTOR
        );
    }

    /*
     * @notice Withdraw staked tokens and collect reward tokens
     * @param _amount: amount to withdraw (in earnedToken)
     */
    function withdraw(uint256 _amount, uint8 _stakeType) external nonReentrant {
        require(_amount > 0, "Amount should be greator than 0");
        require(_stakeType < lockups.length, "Invalid stake type");

        _updatePool(_stakeType);

        UserInfo storage user = userStaked[msg.sender];
        Stake[] storage stakes = userStakes[msg.sender];
        Lockup storage lockup = lockups[_stakeType];

        uint256 pending = 0;
        uint256 pendingCompound = 0;
        uint256 compounded = 0;
        uint256 remained = _amount;
        for (uint256 j = 0; j < stakes.length; j++) {
            Stake storage stake = stakes[j];
            if (stake.stakeType != _stakeType) continue;
            if (stake.amount == 0) continue;
            if (remained == 0) break;

            uint256 _pending = stake
                .amount
                .mul(lockup.accTokenPerShare)
                .div(PRECISION_FACTOR)
                .sub(stake.rewardDebt);

            if (stake.end > block.timestamp) {
                pendingCompound = pendingCompound.add(_pending);

                if (
                    address(stakingToken) != address(earnedToken) &&
                    _pending > 0
                ) {
                    uint256 _beforeAmount = IERC20(stakingToken).balanceOf(
                        address(this)
                    );
                    _safeSwap(_pending, earnedToStakedPath, address(this));
                    uint256 _afterAmount = IERC20(stakingToken).balanceOf(
                        address(this)
                    );
                    _pending = _afterAmount.sub(_beforeAmount);
                }
                compounded = compounded.add(_pending);
                stake.amount = stake.amount.add(_pending);
            } else {
                pending = pending.add(_pending);
                if (stake.amount > remained) {
                    stake.amount = stake.amount.sub(remained);
                    remained = 0;
                } else {
                    remained = remained.sub(stake.amount);
                    stake.amount = 0;
                }
            }
            stake.rewardDebt = stake.amount.mul(lockup.accTokenPerShare).div(
                PRECISION_FACTOR
            );
        }

        if (pending > 0) {
            IERC20(earnedToken).transfer(address(msg.sender), pending);

            if (totalEarned > pending) {
                totalEarned = totalEarned.sub(pending);
            } else {
                totalEarned = 0;
            }
        }

        if (pendingCompound > 0) { 
            // IERC20(stakingToken).mint(address(this), pendingCompound); 

            if (totalEarned > pendingCompound) {
                totalEarned = totalEarned.sub(pendingCompound);
            } else {
                totalEarned = 0;
            }

            emit Deposit(msg.sender, _stakeType, compounded);
        }

        uint256 realAmount = _amount.sub(remained);
        user.amount = user.amount.sub(realAmount).add(pendingCompound);
        lockup.totalStaked = lockup.totalStaked.sub(realAmount).add(
            pendingCompound
        );
        totalStaked = totalStaked.sub(realAmount).add(pendingCompound);

        if (realAmount > 0) {
            if (lockup.withdrawFee > 0) {
                uint256 fee = realAmount.mul(lockup.withdrawFee).div(10000);
                IERC20(stakingToken).transfer(walletA, fee);
                realAmount = realAmount.sub(fee);
            }

            IERC20(stakingToken).transfer(address(msg.sender), realAmount);
        }

        emit Withdraw(msg.sender, _stakeType, realAmount);
    }

    function claimReward(uint8 _stakeType) external nonReentrant {
        if (_stakeType >= lockups.length) return;
        if (startBlock == 0) return;
        // if (getActiveStake(msg.sender, _stakeType).end > block.timestamp) {
        //     revert();
        // }
        _updatePool(_stakeType);

        // UserInfo storage user = userStaked[msg.sender];
        Stake[] storage stakes = userStakes[msg.sender];
        Lockup storage lockup = lockups[_stakeType];

        uint256 pending = 0;
        // uint256 pendingCompound = 0;
        // uint256 compounded = 0;
        for (uint256 j = 0; j < stakes.length; j++) {
            Stake storage stake = stakes[j];
            if (stake.stakeType != _stakeType) continue;
            if (stake.amount == 0) continue;

            uint256 _pending = stake
                .amount
                .mul(lockup.accTokenPerShare)
                .div(PRECISION_FACTOR)
                .sub(stake.rewardDebt);

            // if (stake.end > block.timestamp) {
            //     pendingCompound = pendingCompound.add(_pending);

            //     if (
            //         address(stakingToken) != address(earnedToken) &&
            //         _pending > 0
            //     ) {
            //         uint256 _beforeAmount = IERC20(stakingToken).balanceOf(
            //             address(this)
            //         );
            //         _safeSwap(_pending, earnedToStakedPath, address(this));
            //         uint256 _afterAmount = IERC20(stakingToken).balanceOf(
            //             address(this)
            //         );
            //         _pending = _afterAmount.sub(_beforeAmount);
            //     }
            //     compounded = compounded.add(_pending);
            //     stake.amount = stake.amount.add(_pending);
            // } else {
            pending = pending.add(_pending);
            // }
            stake.rewardDebt = stake.amount.mul(lockup.accTokenPerShare).div(
                PRECISION_FACTOR
            );
        }

        if (pending > 0) {
            IERC20(earnedToken).transfer(address(msg.sender), pending);

            if (totalEarned > pending) {
                totalEarned = totalEarned.sub(pending);
            } else {
                totalEarned = 0;
            }
        }

        // if (pendingCompound > 0) {

        //     if (totalEarned > pendingCompound) {
        //         totalEarned = totalEarned.sub(pendingCompound);
        //     } else {
        //         totalEarned = 0;
        //     }

        //     user.amount = user.amount.add(compounded);
        //     lockup.totalStaked = lockup.totalStaked.add(compounded);
        //     totalStaked = totalStaked.add(compounded);

        //     emit Deposit(msg.sender, _stakeType, compounded);
        // }
    }

    function compoundReward(uint8 _stakeType) external nonReentrant {
        if (_stakeType >= lockups.length) return;
        if (startBlock == 0) return;

        _updatePool(_stakeType);

        UserInfo storage user = userStaked[msg.sender];
        Stake[] storage stakes = userStakes[msg.sender];
        Lockup storage lockup = lockups[_stakeType];
        require(lockup.enableCompound, "Compound is disabled in this lockup!");

        uint256 pending = 0;
        uint256 pendingCompound = 0;
        for (uint256 j = 0; j < stakes.length; j++) {
            Stake storage stake = stakes[j];
            if (stake.stakeType != _stakeType) continue;
            if (stake.amount == 0) continue;

            uint256 _pending = stake
                .amount
                .mul(lockup.accTokenPerShare)
                .div(PRECISION_FACTOR)
                .sub(stake.rewardDebt);
            pending = pending.add(_pending);

            if (address(stakingToken) != address(earnedToken) && _pending > 0) {
                uint256 _beforeAmount = IERC20(stakingToken).balanceOf(
                    address(this)
                );
                _safeSwap(_pending, earnedToStakedPath, address(this));
                uint256 _afterAmount = IERC20(stakingToken).balanceOf(
                    address(this)
                );
                _pending = _afterAmount.sub(_beforeAmount);
            }
            pendingCompound = pendingCompound.add(_pending);

            stake.amount = stake.amount.add(_pending);
            stake.rewardDebt = stake.amount.mul(lockup.accTokenPerShare).div(
                PRECISION_FACTOR
            );
        }

        // if(pendingCompound > 0) {
        //     IERC20(stakingToken).transfer(address(this), pendingCompound);
        // }

        if (pending > 0) {
            if (totalEarned > pending) {
                totalEarned = totalEarned.sub(pending);
            } else {
                totalEarned = 0;
            }

            user.amount = user.amount.add(pendingCompound);
            lockup.totalStaked = lockup.totalStaked.add(pendingCompound);
            totalStaked = totalStaked.add(pendingCompound);

            emit Deposit(msg.sender, _stakeType, pendingCompound);
        }
    }

    function rewardPerBlock(uint8 _stakeType) public view returns (uint256) {
        if (_stakeType >= lockups.length) return 0;

        return lockups[_stakeType].rate;
    }

    /**
     * @notice Available amount of reward token
     */
    function availableRewardTokens() public view returns (uint256) {
        uint256 _amount = IERC20(earnedToken).balanceOf(address(this));
        if (address(earnedToken) == address(stakingToken)) {
            if (_amount < totalStaked) return 0;
            return _amount.sub(totalStaked);
        }

        return _amount;
    }

    function userInfo(uint8 _stakeType, address _account)
        public
        view
        returns (
            uint256 amount,
            uint256 available,
            uint256 locked
        )
    {
        Stake[] storage stakes = userStakes[_account];

        for (uint256 i = 0; i < stakes.length; i++) {
            Stake storage stake = stakes[i];

            if (stake.stakeType != _stakeType) continue;
            if (stake.amount == 0) continue;

            amount = amount.add(stake.amount);
            if (block.timestamp > stake.end) {
                available = available.add(stake.amount);
            } else {
                locked = locked.add(stake.amount);
            }
        }
    }

    /*
     * @notice View function to see pending reward on frontend.
     * @param _user: user address
     * @return Pending reward for a given user
     */
    function pendingReward(address _account, uint8 _stakeType)
        external
        view
        returns (uint256)
    {
        if (_stakeType >= lockups.length) return 0;
        if (startBlock == 0) return 0;

        Stake[] storage stakes = userStakes[_account];
        Lockup storage lockup = lockups[_stakeType];

        if (lockup.totalStaked == 0) return 0;

        uint256 adjustedTokenPerShare = lockup.accTokenPerShare;
        if (block.number > lockup.lastRewardBlock && lockup.totalStaked != 0) {
            uint256 multiplier = _getMultiplier(
                lockup.lastRewardBlock,
                block.number
            );
            uint256 reward = multiplier.mul(lockup.rate);
            adjustedTokenPerShare = lockup.accTokenPerShare.add(
                reward.mul(PRECISION_FACTOR).div(lockup.totalStaked)
            );
        }

        uint256 pending = 0;
        for (uint256 i = 0; i < stakes.length; i++) {
            Stake storage stake = stakes[i];
            if (stake.stakeType != _stakeType) continue;
            if (stake.amount == 0) continue;

            pending = pending.add(
                stake
                    .amount
                    .mul(adjustedTokenPerShare)
                    .div(PRECISION_FACTOR)
                    .sub(stake.rewardDebt)
            );
        }
        return pending;
    }

    /************************
     ** Admin Methods
     *************************/
    function harvest() external onlyOwner {
        _updatePool(0);

        uint256 _amount = IERC20(stakingToken).balanceOf(address(this));
        _amount = _amount.sub(totalStaked);
    }

    /*
     * @notice Deposit reward token
     * @dev Only call by owner.
     */
    function depositRewards(uint256 _amount) external nonReentrant {
        require(_amount > 0);

        uint256 beforeAmt = IERC20(earnedToken).balanceOf(address(this));
        IERC20(earnedToken).transferFrom(msg.sender, address(this), _amount);
        uint256 afterAmt = IERC20(earnedToken).balanceOf(address(this));

        totalEarned = totalEarned.add(afterAmt).sub(beforeAmt);
    }

    /*
     * @notice Withdraw reward token
     * @dev Only callable by owner. Needs to be for emergency.
     */
    function emergencyRewardWithdraw(uint256 _amount) external onlyOwner {
        require(block.number > bonusEndBlock, "Pool is running");

        IERC20(earnedToken).transfer(address(msg.sender), _amount);

        if (totalEarned > 0) {
            if (_amount > totalEarned) {
                totalEarned = 0;
            } else {
                totalEarned = totalEarned.sub(_amount);
            }
        }
    }

    function getActiveStake(address user, uint8 stakeType)
        public
        view
        returns (Stake memory stake_)
    {
        Stake[] memory stakes = userStakes[user];
        for (uint256 i = 0; i < stakes.length; i++) {
            if (stakes[i].stakeType == stakeType && stakes[i].amount != 0) {
                stake_ = stakes[i];
                break;
            }
        }
        return stake_;
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of tokens to withdraw
     * @dev This function is only callable by admin.
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount)
        external
        onlyOwner
    {
        require(
            _tokenAddress != address(earnedToken),
            "Cannot be reward token"
        );

        if (_tokenAddress == address(stakingToken)) {
            uint256 tokenBal = IERC20(stakingToken).balanceOf(address(this));
            require(
                _tokenAmount <= tokenBal.sub(totalStaked),
                "Insufficient balance"
            );
        }

        if (_tokenAddress == address(0x0)) {
            payable(msg.sender).transfer(_tokenAmount);
        } else {
            IERC20(_tokenAddress).transfer(address(msg.sender), _tokenAmount);
        }

        emit AdminTokenRecovered(_tokenAddress, _tokenAmount);
    }

    function startReward() external onlyOwner {
        require(startBlock == 0, "Pool was already started");

        startBlock = block.number.add(100);
        bonusEndBlock = startBlock.add(duration * 42900); // 42900 is the average of avalanche c-chain daily block count
        for (uint256 i = 0; i < lockups.length; i++) {
            lockups[i].lastRewardBlock = startBlock;
        }

        emit NewStartAndEndBlocks(startBlock, bonusEndBlock);
    }

    function stopReward() external onlyOwner {
        bonusEndBlock = block.number;
    }

    /*
     * @notice Update pool limit per user
     * @dev Only callable by owner.
     * @param _hasUserLimit: whether the limit remains forced
     * @param _poolLimitPerUser: new pool limit per user
     */
    function updatePoolLimitPerUser(
        bool _hasUserLimit,
        uint256 _poolLimitPerUser
    ) external onlyOwner {
        require(hasUserLimit, "Must be set");
        if (_hasUserLimit) {
            require(
                _poolLimitPerUser > poolLimitPerUser,
                "New limit must be higher"
            );
            poolLimitPerUser = _poolLimitPerUser;
        } else {
            hasUserLimit = _hasUserLimit;
            poolLimitPerUser = 0;
        }
        emit NewPoolLimit(poolLimitPerUser);
    }

    function updateLockup(
        uint8 _stakeType,
        uint256 _duration,
        uint256 _depositFee,
        uint256 _withdrawFee,
        uint256 _rate,
        bool _enableCompound
    ) external onlyOwner {
        // require(block.number < startBlock, "Pool was already started");
        require(_stakeType < lockups.length, "Lockup Not found");
        require(_depositFee < 2000, "Invalid deposit fee");
        require(_withdrawFee < 2000, "Invalid withdraw fee");

        Lockup storage _lockup = lockups[_stakeType];
        _lockup.duration = _duration;
        _lockup.depositFee = _depositFee;
        _lockup.withdrawFee = _withdrawFee;
        _lockup.rate = _rate;
        _lockup.enableCompound = _enableCompound;

        emit LockupUpdated(
            _stakeType,
            _duration,
            _depositFee,
            _withdrawFee,
            _rate,
            _enableCompound
        );
    }

    function addLockup(
        uint256 _duration,
        uint256 _depositFee,
        uint256 _withdrawFee,
        uint256 _rate,
        bool _enableCompound
    ) external onlyOwner {
        require(_depositFee < 2000, "Invalid deposit fee");
        require(_withdrawFee < 2000, "Invalid withdraw fee");

        lockups.push();

        Lockup storage _lockup = lockups[lockups.length - 1];
        _lockup.duration = _duration;
        _lockup.depositFee = _depositFee;
        _lockup.withdrawFee = _withdrawFee;
        _lockup.rate = _rate;
        _lockup.enableCompound = _enableCompound;
        _lockup.lastRewardBlock = block.number;

        emit LockupUpdated(
            uint8(lockups.length - 1),
            _duration,
            _depositFee,
            _withdrawFee,
            _rate,
            _enableCompound
        );
    }

    function updateWalletA(address _walletA) external onlyOwner {
        require(
            _walletA != address(0x0) || _walletA != walletA,
            "Invalid address"
        );

        walletA = _walletA;
        emit WalletAUpadted(_walletA);
    }

    function setDuration(uint256 _duration) external onlyOwner {
        require(startBlock == 0, "Pool was already started");
        require(_duration >= 30, "lower limit reached");

        duration = _duration;
        emit DurationUpdated(_duration);
    }

    function setSettings(
        uint256 _slippageFactor,
        address _uniRouter,
        address[] memory _earnedToStakedPath
    ) external onlyOwner {
        require(
            _slippageFactor <= slippageFactorUL,
            "_slippageFactor too high"
        );

        slippageFactor = _slippageFactor;
        uniRouterAddress = _uniRouter;
        earnedToStakedPath = _earnedToStakedPath;

        emit SetSettings(_slippageFactor, _uniRouter, _earnedToStakedPath);
    }

    function resetAllowances() external onlyOwner {
        _resetAllowances();
    }

    /************************
     ** Internal Methods
     *************************/
    /*
     * @notice Update reward variables of the given pool to be up-to-date.
     */
    function _updatePool(uint8 _stakeType) internal {
        Lockup storage lockup = lockups[_stakeType];
        if (block.number <= lockup.lastRewardBlock) return;

        if (lockup.totalStaked == 0) {
            lockup.lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = _getMultiplier(
            lockup.lastRewardBlock,
            block.number
        );
        uint256 _reward = multiplier.mul(lockup.rate);
        lockup.accTokenPerShare = lockup.accTokenPerShare.add(
            _reward.mul(PRECISION_FACTOR).div(lockup.totalStaked)
        );
        lockup.lastRewardBlock = block.number;
    }

    /*
     * @notice Return reward multiplier over the given _from to _to block.
     * @param _from: block to start
     * @param _to: block to finish
     */
    function _getMultiplier(uint256 _from, uint256 _to)
        internal
        view
        returns (uint256)
    {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from);
        } else if (_from >= bonusEndBlock) {
            return 0;
        } else {
            return bonusEndBlock.sub(_from);
        }
    }

    function _safeSwap(
        uint256 _amountIn,
        address[] memory _path,
        address _to
    ) internal {
        uint256[] memory amounts = IPangolinRouter(uniRouterAddress).getAmountsOut(
            _amountIn,
            _path
        );
        uint256 amountOut = amounts[amounts.length.sub(1)];

        IPangolinRouter(uniRouterAddress).swapExactTokensForTokens(
            _amountIn,
            amountOut.mul(slippageFactor).div(1000),
            _path,
            _to,
            block.timestamp.add(600)
        );
    }

    function _resetAllowances() internal {
        IERC20(earnedToken).approve(uniRouterAddress, uint256(0));
        IERC20(earnedToken).increaseAllowance(
            uniRouterAddress,
            type(uint256).max
        );
    }

    receive() external payable {}
}
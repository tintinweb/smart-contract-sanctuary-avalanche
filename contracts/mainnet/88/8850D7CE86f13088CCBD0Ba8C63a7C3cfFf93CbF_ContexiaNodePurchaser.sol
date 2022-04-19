/**
 *Submitted for verification at snowtrace.io on 2022-04-19
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
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

abstract contract Node {
    struct NodeFee {
        uint256 fee;
        uint256 lastPaidDate;
        uint256 lastPaidFee;
    }

    struct NodeBoosterRecord {
        uint256 winstar;
        uint256 luckyYard;
        uint256 royalFox;
        uint256 sparkTouch;
    }

    struct NodeEntity {
        string name; // Node name
        uint256 creationTime; // Node creation time
        uint256 lastClaimTime; // Node last claim time
        uint256 rewardAvailable; // Node reward available
        uint256 isolationPeriod; // Node isolation period
        uint256 claimTax; // Node claim tax
        uint256 claimedReward; // Node claimed reward
        NodeFee monthlyFee; // Node monthly fee
        NodeBoosterRecord boosterInfo; // Node booster info
    }
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

/*
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

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface INODERewardManagement {
    function nodePrice() external view returns (uint256);

    function rewardPerNode() external view returns (uint256);

    function _totalNodesCompounded(address _account)
        external
        view
        returns (uint256);

    function getUserCompoundedNodesCount(address _account)
        external
        view
        returns (string memory);

    function getRewardForCompounding(address _account, uint256 _nodeCount)
        external
        returns (uint256);

    function getNodeIndexByCreationTime(address _account, uint256 _blockTime)
        external
        returns (uint256);

    function updateProductionRate(
        address _user,
        uint256 _nodeIndex,
        uint256 _productionRatePer
    ) external;

    function updateNodeClaimTax(
        address _user,
        uint256 _nodeIndex,
        uint256 _taxPer
    ) external;

    function updateMonthlyFee(
        address _user,
        uint256 _nodeIndex,
        uint256 _taxPer
    ) external;

    function updateIsolationPeriod(
        address _user,
        uint256 _nodeIndex,
        uint256 _days
    ) external;

    function incrementCompoundNode(address _account) external;

    function claimTax() external view returns (uint256);

    function claimTime() external view returns (uint256);

    function totalRewardStaked() external view returns (uint256);

    function totalNodesCreated() external view returns (uint256);

    function setToken(address token_) external;

    function createNode(address account, string memory nodeName) external;

    function compoundAll(address account)
        external
        returns (uint256 totalCost, uint256 pendingCon);

    function _cashoutNodeReward(address account, uint256 _creationTime)
        external
        returns (uint256);

    function _cashoutAllNodesReward(address account) external returns (uint256);

    function compoundNodeReward(address account) external;

    function getDueFeeInfo(address account, uint256 _creationTime)
        external
        view
        returns (uint256 dueDate, uint256 lastPaidFee);

    function _getRewardAmountOf(address account)
        external
        view
        returns (uint256, uint256);

    function _getRewardAmountOf(address account, uint256 _creationTime)
        external
        view
        returns (uint256, uint256);

    function _getNodesNames(address account)
        external
        view
        returns (string memory);

    function _getNodesCreationTime(address account)
        external
        view
        returns (string memory);

    function _getNodesRewardAvailable(address account)
        external
        view
        returns (string memory);

    function _getNodesLastClaimTime(address account)
        external
        view
        returns (string memory);

    function payNodeMaintenanceFee(
        address account,
        uint256 _creationTime,
        uint256 _fee
    ) external payable;

    function getNodePayableFee(address account, uint256 _creationTime)
        external
        view
        returns (uint256);

    function _changeNodePrice(uint256 newNodePrice) external;

    function _changeRewardPerNode(uint256 newPrice) external;

    function _changeClaimTime(uint256 newTime) external;

    function _getNodeNumberOf(address account) external view returns (uint256);

    function _isNodeOwner(address account) external view returns (bool);
}

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        // Gas optimization: this is TKNaper than requiring 'a' not being zero, but the
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
     * `revert` opcode (which leaves remaining gas untouTKNd) while Solidity
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
     * `revert` opcode (which leaves remaining gas untouTKNd) while Solidity
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
     * opcode (which leaves remaining gas untouTKNd) while Solidity uses an
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
     * opcode (which leaves remaining gas untouTKNd) while Solidity uses an
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IContexiaStaking {
    function userInfo(address _account)
        external
        view
        returns (
            uint256 amount,
            uint256 rewardDebt,
            uint256 firstTimeDeposited,
            uint256 lastTimeDeposited
        );

    function withdrawOnBehalf(address account, uint256 _amount) external;
}

interface IJoeRouter01 {
    function factory() external pure returns (address);

    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountAVAX,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAX(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAXWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactAVAX(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapAVAXForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IJoeRouter02 is IJoeRouter01 {
    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountAVAX);

    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IJoeFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function setMigrator(address) external;
}

interface IJoePair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

/// @title Node Purchases
/// @author BlocTech Solutions
/// @dev This contract is used to buy nodes for con token.
contract ContexiaNodePurchaser is Ownable, Node {
    using SafeMath for uint256;

    INODERewardManagement[3] public nodes;
    IERC20Metadata public usdc;
    IERC20Metadata public con;

    IJoeRouter02 public dexRouter;
    IJoePair public liquidityPair;

    /// @notice Whether or not the USDC payments have been enabled
    bool public isUSDCEnabled;
    /// @notice Whether or not the LP payments have been enabled
    bool public isLPEnabled;

    /// @notice The amount of discount of USDC
    uint256 public usdcDiscount;
    /// @notice The upper liquidity ratio (when to apply the higher discount)
    uint256 public liquidityRatio0;
    /// @notice The lower liquidity ratio (when to apply the lower discount)
    uint256 public liquidityRatio1;
    /// @notice The discount (to be applied when the liquidity ratio is equal to or above `liquidityRatio0`)
    uint256 public lpDiscount0;
    /// @notice The discount (to be applied when the liquidity ratio is equal to or less than `liquidityRatio1`)
    uint256 public lpDiscount1;
    /// @notice Liquidity zapping slippage
    uint256 public zapSlippage;
    /// @notice The percentage fee for using the auto-zapping!
    uint256 public zapFee;

    /// @notice The amount of discount to apply to people converting staked LP
    uint256 public conversionDiscount;
    /// @notice How long people have to have their LP tokens staked before
    uint256 public conversionPeriodRequirement;

    /// @notice Treasury Address
    address public treasury;
    /// @notice Reward Pool address
    address public rewardPool;

    /// @notice Reward Pool fee on node creation
    uint256 public rewardPoolFee;
    /// @notice Treasury fee on node creation
    uint256 public treasuryFee;
    /// @notice Rewards Pool fee on Cashout
    uint256 public cashoutPoolFee;
    /// @notice Treasury fee on Cashout
    uint256 public cashoutTreasuryFee;

    /// @notice Refferal reward percentage
    uint256 public referalReward;
    /// @notice Is refferal reward claimable
    bool public isReferRewardClaimable;

    /// @notice Denominator for calculations.
    uint256 public constant PERCENT_DENOMINATOR = 1000;

    struct ReferReward {
        uint256 claimedReward;
        uint256 lastClaimedDate;
        uint256 claimable;
    }

    mapping(address => ReferReward) public _userReferReward;
    mapping(address => bool) public _isBlacklisted;

    event NodeCreated(
        address indexed _user,
        uint256 indexed _nodeType,
        uint256 indexed _nodesAmount
    );

    event CashoutReward(
        address indexed _user,
        uint256 indexed _amount,
        uint256 indexed _time
    );

    constructor(
        address _routerAddress,
        address _lpPairAddress,
        address _rewardPool,
        address _treasury,
        address _usdcAddress,
        address _conAddress,
        uint256[4] memory fees,
        uint256 _referalsReward
    ) {
        require(_conAddress != address(0), "Con Address cannot be ZERO");
        require(_rewardPool != address(0), "REWARD POOL CANNOT BE ZERO");
        require(_treasury != address(0), "Treasury CANNOT BE ZERO");

        treasury = _treasury;
        rewardPool = _rewardPool;

        rewardPoolFee = fees[0];
        treasuryFee = fees[1];
        cashoutPoolFee = fees[2];
        cashoutTreasuryFee = fees[3];

        referalReward = _referalsReward;
        usdc = IERC20Metadata(_usdcAddress);
        con = IERC20Metadata(_conAddress);

        dexRouter = IJoeRouter02(_routerAddress);
        liquidityPair = IJoePair(_lpPairAddress);

        usdcDiscount = 500; // 5%
        liquidityRatio0 = 100; // 1%
        liquidityRatio1 = 2000; // 20%
        lpDiscount0 = 2500; // 25%
        lpDiscount1 = 100; // 1%
        zapSlippage = 1000; // 10%
        zapFee = 100; // 1%
    }

    // -----------------------------Public Functions---------------------------------

    function purchaseWithCON(
        uint256 amount,
        uint256 nodeIndex,
        address referrer
    ) public {
        require(amount > 0, "Amount must be above zero");
        INODERewardManagement nodeRewardManager = getNodeRewardManager(
            nodeIndex
        );

        uint256 conAmount = amount * nodeRewardManager.nodePrice();
        con.transferFrom(
            msg.sender,
            treasury,
            conAmount.mul(treasuryFee).div(PERCENT_DENOMINATOR)
        );
        con.transferFrom(
            msg.sender,
            rewardPool,
            conAmount.mul(rewardPoolFee).div(PERCENT_DENOMINATOR)
        );

        // Node Mint logic
        createNodeWithTokens("CON_PURCHASED", msg.sender, amount, nodeIndex);

        // Distribute referral reward
        updateReferReward(referrer, conAmount);
    }

    function purchaseWithUSDC(
        uint256 amount,
        uint256 nodeIndex,
        address referrer
    ) external {
        require(amount > 0, "Amount must be above zero");
        require(isUSDCEnabled, "USDC discount off");

        INODERewardManagement nodeRewardManager = getNodeRewardManager(
            nodeIndex
        );

        // Take payment for USDC tokens
        uint256 usdcAmount = (amount *
            getUSDCForCON(nodeRewardManager.nodePrice()) *
            (PERCENT_DENOMINATOR - usdcDiscount)) / PERCENT_DENOMINATOR;
        usdc.transferFrom(msg.sender, treasury, usdcAmount);

        // Node Mint logic
        createNodeWithTokens("USDC_PURCHASED", msg.sender, amount, nodeIndex);

        // Distribute referral reward
        uint256 conAmount = amount * nodeRewardManager.nodePrice();
        updateReferReward(referrer, conAmount);
    }

    function purchaseWithLP(
        uint256 amount,
        uint256 nodeIndex,
        address referrer
    ) public {
        require(amount > 0, "Amount must be above zero");
        require(isLPEnabled, "LP discount disabled");

        INODERewardManagement nodeRewardManager = getNodeRewardManager(
            nodeIndex
        );

        // Take payment in CON-USDC LP tokens
        uint256 discount = calculateLPDiscount();
        uint256 nodePriceInUSDC = amount *
            getUSDCForCON(nodeRewardManager.nodePrice());
        uint256 nodePriceInLP = getLPFromUSDC(nodePriceInUSDC);
        uint256 discountAmount = (nodePriceInLP * discount) / 1e4;
        liquidityPair.transferFrom(
            msg.sender,
            treasury,
            nodePriceInLP - discountAmount
        );

        // Node Mint logic
        createNodeWithTokens("LP_PURCHASED", msg.sender, amount, nodeIndex);

        // Distribute referral reward
        uint256 conAmount = amount * nodeRewardManager.nodePrice();
        updateReferReward(referrer, conAmount);
    }

    /**
     * @notice Purchases a NODE using USDC and automatically converting into LP tokens
     */
    function purchaseWithLPUsingZap(
        uint256 amount,
        uint256 nodeIndex,
        address referrer
    ) external {
        INODERewardManagement nodeRewardManager = getNodeRewardManager(
            nodeIndex
        );

        uint256 nodeCostWithLPDiscount = getNodeCostWithLPDiscount(
            nodeIndex,
            amount
        );

        /// @notice Handles the zapping of liquitity for us + an extra fee
        /// @dev The LP tokens will now be in the hands of the msg.sender
        uint256 liquidityTokens = zapLiquidity(nodeCostWithLPDiscount);

        // Send the tokens from the account transacting this function to the taverns keep
        liquidityPair.transferFrom(msg.sender, treasury, liquidityTokens);

        // Node Mint logic
        createNodeWithTokens("ZAP_PURCHASED", msg.sender, amount, nodeIndex);

        // Distribute referral reward
        uint256 conAmount = amount * nodeRewardManager.nodePrice();
        updateReferReward(referrer, conAmount);
    }

    function cashoutReward(uint256 blocktime, uint256 nodeIndex) external {
        INODERewardManagement nodeRewardManager = getNodeRewardManager(
            nodeIndex
        );
        address sender = _msgSender();

        (uint256 _claimTax, uint256 rewardAmount) = nodeRewardManager
            ._getRewardAmountOf(sender, blocktime);
        nodeRewardManager._cashoutNodeReward(sender, blocktime);
        require(sender != address(0), "CSHT:  creation from the zero address");
        require(!_isBlacklisted[sender], "CSHT: Blacklisted address");
        require(
            sender != treasury && sender != rewardPool,
            "CSHT: treasury and rewardsPool cannot cashout rewards"
        );

        require(
            rewardAmount > 0,
            "CSHT: You don't have enough reward to cash out"
        );

        if (_claimTax > 0) {
            uint256 feeAmount = rewardAmount.mul(_claimTax).div(
                PERCENT_DENOMINATOR
            );
            payCashoutTax(msg.sender, feeAmount);
            rewardAmount -= feeAmount;
        }

        con.transferFrom(rewardPool, sender, rewardAmount);
    }

    function cashoutAll(uint256 nodeIndex) external {
        INODERewardManagement nodeRewardManager = getNodeRewardManager(
            nodeIndex
        );
        address sender = _msgSender();

        (uint256 _claimTax, uint256 rewardAmount) = nodeRewardManager
            ._getRewardAmountOf(sender);
        nodeRewardManager._cashoutAllNodesReward(sender);

        require(sender != address(0), "CSHT:  creation from the zero address");
        require(!_isBlacklisted[sender], "CSHT: Blacklisted address");
        require(
            sender != treasury && sender != rewardPool,
            "CSHT: treasury and rewardsPool cannot cashout rewards"
        );
        require(
            rewardAmount > 0,
            "CSHT: You don't have enough reward to cash out"
        );

        if (_claimTax > 0) {
            uint256 feeAmount = rewardAmount.mul(_claimTax).div(
                PERCENT_DENOMINATOR
            );
            payCashoutTax(msg.sender, feeAmount);
            rewardAmount -= feeAmount;
        }

        con.transferFrom(rewardPool, sender, rewardAmount);
    }

    function compoundNodeReward(uint256 nodeIndex) external {
        INODERewardManagement nodeRewardManager = getNodeRewardManager(
            nodeIndex
        );

        (uint256 totalCost, uint256 pendingCon) = nodeRewardManager.compoundAll(
            msg.sender
        );

        con.transferFrom(
            rewardPool,
            treasury,
            totalCost.mul(treasuryFee).div(PERCENT_DENOMINATOR)
        );

        if (pendingCon > 0) {
            uint256 feeAmount;
            uint256 nodeClaimTax = nodeRewardManager.claimTax();
            if (nodeClaimTax > 0) {
                feeAmount = pendingCon.mul(nodeClaimTax).div(
                    PERCENT_DENOMINATOR
                );
                payCashoutTax(msg.sender, feeAmount);
            }
            pendingCon = pendingCon.sub(feeAmount);
            con.transferFrom(rewardPool, msg.sender, pendingCon);
        }
    }

    function claimReferReward() external {
        require(isReferRewardClaimable, "CLAIM: cannot claim right now");
        address sender = _msgSender();
        ReferReward storage _referReward = _userReferReward[sender];
        require(
            _referReward.claimable > 0,
            "CLAIM: You don't have any claimable reward"
        );
        con.transferFrom(rewardPool, sender, _referReward.claimable);
        _referReward.claimedReward += _referReward.claimable;
        _referReward.claimable = 0;
        _referReward.lastClaimedDate = block.timestamp;
    }

    function payNodeFee(uint256 nodeIndex, uint256 creationTime)
        external
        payable
    {
        INODERewardManagement nodeRewardManager = getNodeRewardManager(
            nodeIndex
        );
        nodeRewardManager.payNodeMaintenanceFee(
            msg.sender,
            creationTime,
            msg.value
        );
    }

    /**
     * @notice Converts staked LPs into NODEs
     */
    function convertStakeIntoNodes(
        address stakingAddress,
        uint256 stakeAmount,
        uint256 nodeIndex
    ) external {
        IContexiaStaking staking = IContexiaStaking(stakingAddress);
        (uint256 amount, , , uint256 lastTimeDeposited) = staking.userInfo(
            msg.sender
        );
        require(stakeAmount <= amount, "You havent staked this amount");
        require(
            lastTimeDeposited + conversionPeriodRequirement <= block.timestamp,
            "Need to stake for longer to convert"
        );

        // Attempt to withdraw the stake via the staking contract
        // This gives msg.sender LP tokens + CON rewards
        staking.withdrawOnBehalf(msg.sender, stakeAmount);

        // Calculate how many NODEs this affords
        // stakeAmount         100 000000000000000000
        // lpPriceUSD          100 000000
        // stakeAmountUSD      100 000000
        // nodeCostUSD      600 000000
        // nodeAmount       6
        // toPayLP             nodeAmount * nodeCostUSD / lpPriceUSD
        //                     6             * 600 000000     / 100 000000
        //                     12
        uint256 lpPriceUSD = getUSDCForLP(10**liquidityPair.decimals()); // 100 000000
        uint256 stakeAmountUSD = (stakeAmount * lpPriceUSD) /
            10**liquidityPair.decimals();
        uint256 nodeCostUSD = getNodeCostWithLPAndConvertDiscount(nodeIndex, 1);
        uint256 nodeAmount = stakeAmountUSD / nodeCostUSD;

        // Send the LP tokens from the account transacting this function to the taverns keep
        // as payment. The rest is then kept on the person (dust)
        uint256 toPayLP = (nodeAmount *
            nodeCostUSD *
            10**liquidityPair.decimals()) / lpPriceUSD;
        liquidityPair.transferFrom(msg.sender, treasury, toPayLP);

        // Node Mint logic
        createNodeWithTokens("CONVERTED", msg.sender, nodeAmount, nodeIndex);
    }

    /**
     * @notice Takes an amount of USDC and zaps it into liquidity
     * @dev User must have an approved CON and USDC allowance on this contract
     */
    function zapLiquidity(uint256 usdcAmount) public returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(usdc);
        path[1] = address(con);

        // Swap any USDC to receive 50 CON
        usdc.transferFrom(msg.sender, address(this), usdcAmount);
        usdc.approve(address(dexRouter), usdcAmount);
        uint256[] memory amounts = dexRouter.swapExactTokensForTokens(
            usdcAmount / 2,
            0,
            path,
            address(this),
            block.timestamp + 120
        );

        // Approve the router to spend these tokens
        usdc.approve(address(dexRouter), amounts[0]);
        con.approve(address(dexRouter), amounts[1]);

        // Add liquidity (CON + USDC) to receive LP tokens
        (, , uint256 liquidity) = dexRouter.addLiquidity(
            address(usdc),
            address(con),
            amounts[0],
            amounts[1],
            0,
            0,
            msg.sender,
            block.timestamp + 120
        );

        return liquidity;
    }

    /**
     * @notice Unzaps the liquidity
     * @return The liquidity token balance
     */
    function unzapLiquidity(uint256 _amount) public returns (uint256, uint256) {
        // Remove liquidity (CON + USDC) to receive LP tokens
        return
            dexRouter.removeLiquidity(
                address(usdc),
                address(con),
                _amount,
                0,
                0,
                msg.sender,
                block.timestamp + 120
            );
    }

    // -----------------------------Internal Functions---------------------------------

    function updateReferReward(address _user, uint256 _amount) internal {
        if (_user != address(0)) {
            (uint256 nodes1, uint256 nodes2, uint256 nodes3) = getNodeNumberOf(
                _user
            );
            require(
                (nodes1 + nodes2 + nodes3) > 0,
                "NODE CREATION: Referrer dont have any node"
            );

            ReferReward storage _referReward = _userReferReward[_user];
            _referReward.claimable += _amount.mul(referalReward).div(
                PERCENT_DENOMINATOR
            );
        }
    }

    function createNodeWithTokens(
        string memory _name,
        address _user,
        uint256 _nodesCount,
        uint256 nodeIndex
    ) internal {
        INODERewardManagement nodeRewardManager = getNodeRewardManager(
            nodeIndex
        );

        // require(
        //     bytes(name).length > 3 && bytes(name).length < 32,
        //     "NODE_CREATION: NAME SIZE INVALID"
        // );

        require(
            _user != address(0),
            "NODE_CREATION:  creation from the zero address"
        );
        require(!_isBlacklisted[_user], "NODE_CREATION: Blacklisted address");
        require(
            _user != treasury && _user != rewardPool,
            "NODE_CREATION: treasury and rewardsPool cannot create node"
        );

        for (uint256 i = 0; i < _nodesCount; ++i) {
            nodeRewardManager.createNode(_user, _name);
        }

        emit NodeCreated(_user, nodeIndex, _nodesCount);
    }

    function payCashoutTax(address _user, uint256 _amount) private {
        con.transferFrom(
            _user,
            treasury,
            _amount.mul(cashoutTreasuryFee).div(PERCENT_DENOMINATOR)
        );
        con.transferFrom(
            _user,
            rewardPool,
            _amount.mul(cashoutPoolFee).div(PERCENT_DENOMINATOR)
        );
    }

    function concat_strings(string memory a, string memory b)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(a, b));
    }

    function getNodeRewardManager(uint256 index)
        internal
        view
        returns (INODERewardManagement)
    {
        require(index < 3, "NODE: Node out of range.");
        return nodes[index];
    }

    // -----------------------------View Functions---------------------------------

    /**
     * @notice Calculates how much USDC 1 LP token is worth
     */
    function getUSDCForLP(uint256 _lpAmount) public view returns (uint256) {
        uint256 lpSupply = liquidityPair.totalSupply();
        uint256 totalReserveInUSDC = getUSDCReserve() * 2;
        return (totalReserveInUSDC * _lpAmount) / lpSupply;
    }

    /**
     * @notice Calculates how many LP tokens are worth `_amount` in USDC (for payment)
     */
    function getLPFromUSDC(uint256 _amount) public view returns (uint256) {
        uint256 lpSupply = liquidityPair.totalSupply();
        uint256 totalReserveInUSDC = getUSDCReserve() * 2;
        return (_amount * lpSupply) / totalReserveInUSDC;
    }

    /**
     * @notice Calculates how much USDC 1 LP token is worth
     */
    function getUSDCReserve() public view returns (uint256) {
        (uint256 token0Reserve, uint256 token1Reserve, ) = liquidityPair
            .getReserves();
        if (liquidityPair.token0() == address(usdc)) {
            return token0Reserve;
        }
        return token1Reserve;
    }

    function getFDV() public view returns (uint256) {
        return getUSDCForOneCON() * getCONSupply();
    }

    /**
     * @notice Returns how many USDC tokens you need for inputed conAmount
     */
    function getUSDCForOneCON() public view returns (uint256) {
        return getUSDCForCON(10**con.decimals());
    }

    /**
     * @notice Returns how many CON tokens you get for 1 USDC
     */
    function getCONforUSDC(uint256 _usdcAmount) public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(con);
        path[1] = address(usdc);
        uint256[] memory amountsOut = dexRouter.getAmountsIn(_usdcAmount, path);
        return amountsOut[0];
    }

    /**
     * @notice Returns how many USDC tokens you need for inputed conAmount
     */
    function getUSDCForCON(uint256 conAmount) public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(usdc);
        path[1] = address(con);
        uint256[] memory amountsOut = dexRouter.getAmountsIn(conAmount, path);
        return amountsOut[0];
    }

    function getCONSupply() public view returns (uint256) {
        return con.totalSupply() / 10**con.decimals();
    }

    /**
     * @notice Returns the price of a NODE in USDC, factoring in the LP discount
     */
    function getNodeCostWithLPDiscount(uint256 _nodeIndex, uint256 _amount)
        public
        view
        returns (uint256)
    {
        INODERewardManagement nodeRewardManager = getNodeRewardManager(
            _nodeIndex
        );
        uint256 discount = calculateLPDiscount();

        // Get the price of a node as if it were valued at the LP tokens rate + a fee for automatically zapping for you
        // Bear in mind this will still be discounted even though we take an extra fee!
        uint256 nodeCost = _amount *
            getUSDCForCON(nodeRewardManager.nodePrice());
        return nodeCost - (nodeCost * (discount - zapFee)) / 1e4;
    }

    /**
     * @notice Returns the price of a NODE in USDC, factoring in both LP + stake conversion discounts
     */
    function getNodeCostWithLPAndConvertDiscount(
        uint256 _nodeIndex,
        uint256 _amount
    ) public view returns (uint256) {
        uint256 cost = getNodeCostWithLPDiscount(_nodeIndex, _amount);
        return cost - (cost * conversionDiscount) / 1e4;
    }

    /**
     * @notice Calculates the liquidity ratio
     */
    function calculateLiquidityRatio() public view returns (uint256) {
        uint256 usdcReserves = getUSDCReserve();

        uint256 fdv = getFDV();

        // If this is 5% its bad, if this is 20% its good
        return (usdcReserves * 1e4) / fdv;
    }

    /**
     * @notice Calculates the current LP discount
     */
    function calculateLPDiscount() public view returns (uint256) {
        uint256 liquidityRatio = calculateLiquidityRatio();

        if (liquidityRatio <= liquidityRatio0) {
            return lpDiscount0;
        }

        if (liquidityRatio >= liquidityRatio1) {
            return lpDiscount1;
        }

        // X is liquidity ratio       (y0 = 5      y1 = 20)
        // Y is discount              (x0 = 15     x1 =  1)
        return
            (lpDiscount0 *
                (liquidityRatio1 - liquidityRatio) +
                lpDiscount1 *
                (liquidityRatio - liquidityRatio0)) /
            (liquidityRatio1 - liquidityRatio0);
    }

    function calculateNodeFee(
        address _user,
        uint256 nodeIndex,
        uint256 creationTime
    ) public view returns (uint256) {
        INODERewardManagement nodeRewardManager = getNodeRewardManager(
            nodeIndex
        );
        return nodeRewardManager.getNodePayableFee(_user, creationTime);
    }

    function getNodeDueDate(
        address _user,
        uint256 nodeIndex,
        uint256 creationTime
    ) public view returns (uint256 dueDate, uint256 lastPaidFee) {
        INODERewardManagement nodeRewardManager = getNodeRewardManager(
            nodeIndex
        );
        return nodeRewardManager.getDueFeeInfo(_user, creationTime);
    }

    function getNodeNumberOf(address account)
        public
        view
        returns (
            uint256 node1,
            uint256 node2,
            uint256 node3
        )
    {
        node1 = nodes[0]._getNodeNumberOf(account);
        node2 = nodes[1]._getNodeNumberOf(account);
        node3 = nodes[2]._getNodeNumberOf(account);
    }

    function getNodesCreationTime(address account)
        public
        view
        returns (
            string memory node1Time,
            string memory node2Time,
            string memory node3Time
        )
    {
        node1Time = nodes[0]._getNodesCreationTime(account);
        node2Time = nodes[1]._getNodesCreationTime(account);
        node3Time = nodes[2]._getNodesCreationTime(account);
    }

    function getNodePrices()
        public
        view
        returns (
            uint256 node1Price,
            uint256 node2Price,
            uint256 node3Price
        )
    {
        node1Price = nodes[0].nodePrice();
        node2Price = nodes[1].nodePrice();
        node3Price = nodes[2].nodePrice();
    }

    function getRewardPerNode()
        public
        view
        returns (
            uint256 node1Reward,
            uint256 node2Reward,
            uint256 node3Reward
        )
    {
        node1Reward = nodes[0].rewardPerNode();
        node2Reward = nodes[1].rewardPerNode();
        node3Reward = nodes[2].rewardPerNode();
    }

    function getClaimTime()
        public
        view
        returns (
            uint256 node1Time,
            uint256 node2Time,
            uint256 node3Time
        )
    {
        node1Time = nodes[0].claimTime();
        node2Time = nodes[1].claimTime();
        node3Time = nodes[2].claimTime();
    }

    function getTotalCreatedNodes(uint256 nodeIndex)
        public
        view
        returns (uint256)
    {
        INODERewardManagement nodeRewardManager = getNodeRewardManager(
            nodeIndex
        );
        return nodeRewardManager.totalNodesCreated();
    }

    // ---------------------------Owner's Functions-------------------------------

    function setNodeManagement(INODERewardManagement[3] memory nodeManagement)
        external
        onlyOwner
    {
        nodes = nodeManagement;
    }

    function setReferalRewardPercentage(uint256 _fee) external onlyOwner {
        referalReward = _fee;
    }

    function updateTreasury(address _addr) external onlyOwner {
        treasury = _addr;
    }

    function updateRewardsWall(address payable _addr) external onlyOwner {
        rewardPool = _addr;
    }

    function updateFees(
        uint256 _rewardPoolFee,
        uint256 _treasuryFee,
        uint256 _claimRewardPoolFee,
        uint256 _claimTreasuryFee
    ) external onlyOwner {
        rewardPoolFee = _rewardPoolFee;
        treasuryFee = _treasuryFee;
        cashoutPoolFee = _claimRewardPoolFee;
        cashoutTreasuryFee = _claimTreasuryFee;
    }

    function blacklistMalicious(address account, bool value)
        external
        onlyOwner
    {
        _isBlacklisted[account] = value;
    }

    function boostReward(address _account, uint256 amount) public onlyOwner {
        if (amount > address(this).balance) amount = address(this).balance;
        payable(_account).transfer(amount);
    }

    function updateReferRewardStatus(bool _status) external onlyOwner {
        isReferRewardClaimable = _status;
    }

    function getRewardAmountOf(address account)
        public
        view
        returns (
            uint256 node1Reward,
            uint256 node2Reward,
            uint256 node3Reward
        )
    {
        (, node1Reward) = nodes[0]._getRewardAmountOf(account);
        (, node2Reward) = nodes[1]._getRewardAmountOf(account);
        (, node3Reward) = nodes[2]._getRewardAmountOf(account);
    }

    function changeNodePrice(uint256[3] memory newNodePrice) public onlyOwner {
        nodes[0]._changeNodePrice(newNodePrice[0]);
        nodes[1]._changeNodePrice(newNodePrice[1]);
        nodes[2]._changeNodePrice(newNodePrice[2]);
    }

    function changeRewardPerNode(uint256[3] memory newPrice) public onlyOwner {
        nodes[0]._changeRewardPerNode(newPrice[0]);
        nodes[1]._changeRewardPerNode(newPrice[1]);
        nodes[2]._changeRewardPerNode(newPrice[2]);
    }

    function changeClaimTime(uint256[3] memory newTime) public onlyOwner {
        nodes[0]._changeClaimTime(newTime[0]);
        nodes[1]._changeClaimTime(newTime[1]);
        nodes[2]._changeClaimTime(newTime[2]);
    }

    function setUSDCEnabled(bool _b) external onlyOwner {
        isUSDCEnabled = _b;
    }

    function setLPEnabled(bool _b) external onlyOwner {
        isLPEnabled = _b;
    }

    function setUSDCDiscount(uint256 _discount) external onlyOwner {
        usdcDiscount = _discount;
    }

    function setMaxLiquidityDiscount(uint256 _discount) external onlyOwner {
        lpDiscount0 = _discount;
    }

    function setMinLiquidityDiscount(uint256 _discount) external onlyOwner {
        lpDiscount1 = _discount;
    }

    function setMinLiquidityRatio(uint256 _ratio) external onlyOwner {
        liquidityRatio0 = _ratio;
    }

    function setMaxLiquidityRatio(uint256 _ratio) external onlyOwner {
        liquidityRatio1 = _ratio;
    }

    function setZapSlippage(uint256 _zap) external onlyOwner {
        zapSlippage = _zap;
    }

    function setConversionDiscount(uint256 _discount) external onlyOwner {
        conversionDiscount = _discount;
    }

    function setConversionPeriodRequirement(uint256 _requirement)
        external
        onlyOwner
    {
        conversionPeriodRequirement = _requirement;
    }

    function setRouter(address _router) external onlyOwner {
        dexRouter = IJoeRouter02(_router);
    }

    function setLPPair(address _lpPair) external onlyOwner {
        liquidityPair = IJoePair(_lpPair);
    }

    function setConToken(address _conToken) external onlyOwner {
        con = IERC20Metadata(_conToken);
    }

    function setUSDCToken(address _usdcToken) external onlyOwner {
        usdc = IERC20Metadata(_usdcToken);
    }

    function setZapFee(uint256 _fee) external onlyOwner {
        zapFee = _fee;
    }
}
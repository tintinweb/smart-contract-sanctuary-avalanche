/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        require(b > 0, errorMessage);
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

contract OwnableData {
    address public owner;
    address public pendingOwner;
}

contract Ownable is OwnableData {
    mapping(address => bool) _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice `owner` defaults to msg.sender on construction.
    constructor() {
        owner = msg.sender;
        _owner[msg.sender] = true;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /// @notice Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
    /// Can only be invoked by the current `owner`.
    /// @param newOwner Address of the new owner.
    /// @param direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
    /// @param renounce Allows the `newOwner` to be `address(0)` if `direct` and `renounce` is True. Has no effect otherwise.
    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
            _owner[newOwner] = true;
            pendingOwner = address(0);
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

     /// @notice Needs to be called by `pendingOwner` to claim ownership.
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        _owner[_pendingOwner] = true;
        pendingOwner = address(0);
    }

    /// @notice Only allows the `owner` to execute the function.
    modifier onlyOwner() {
        require( _owner[msg.sender], "Ownable: caller is not the owner" );
        _;
    }
}

interface IERC20 {
    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function totalSupply() external view returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Sale is Ownable {
    using SafeMath for uint256;

    // ==== STRUCTS ====

    struct UserInfo {
        uint256 payout; // BEND
        uint256 vesting; // time left to be vested
        uint256 lastTime;
        uint256 redeemableBeforeVesting;
    }

    // ==== CONSTANTS ====

    uint256 private constant MAX_PER_ADDR = 100e18; // max 100 AVAX

    uint256 private constant MAX_FOR_SALE = 5000e18; // 5k AVAX

    uint256 private constant VESTING_TERM = 1 days;

    uint256 private constant EXCHANGE_RATE = 10000; // 1 AVAX -> 10000 BEND

    // uint256 private constant MARKET_PRICE = 14; //

    uint256 public constant START_PRESALE =  9547550; // 11st April 2022, 00:00:00 UTC
    uint256 public constant END_PRESALE   =  9547400; // 12nd April 2022, 23:59:59 UTC

    uint256 public constant startVesting = 9547800; // 13rd April 2022, 00:00:00 UTC

    uint256 public constant UNLOCK_BEFORE_VESTING = 50; // 20%

    // ==== STORAGES ====

    IERC20 public BEND;

    // finalized status
    bool public finalized;

    // total asset income(AVAX);
    uint256 public totalIncome;

    // whitelist usage statsu
    bool public whitelistUsed = true;

    // white list for private sale
    mapping(address => bool) public isWhitelist;
    mapping(address => UserInfo) public userInfo;

    // ==== EVENTS ====

    event Deposited(address indexed depositor, uint256 indexed amount);
    event Redeemed(address indexed recipient, uint256 payout, uint256 remaining);
    event WhitelistUpdated(address indexed depositor, bool indexed value);

    // ==== MODIFIERS ====

    modifier onlyWhitelisted(address _depositor) {
        if(whitelistUsed) {
            require(isWhitelist[_depositor], "only whitelisted");
        }
        _;
    }

    // ==== CONSTRUCTOR ====

    constructor(IERC20 _BEND) {
        BEND = _BEND;
    }

    // ==== VIEW FUNCTIONS ====

    function availableFor(address _depositor) public view returns (uint256 amount_) {
        amount_ = 0;

        if (!whitelistUsed || isWhitelist[_depositor]) {
            UserInfo memory user = userInfo[_depositor];
            uint256 totalAvailable = MAX_FOR_SALE.sub(totalIncome);
            uint256 assetPurchased = user.payout.mul(1e15).div(EXCHANGE_RATE);
            uint256 depositorAvailable = MAX_PER_ADDR.sub(assetPurchased);
            amount_ = totalAvailable > depositorAvailable ? depositorAvailable : totalAvailable;
        }
    }

    function payFor(uint256 _amount) public pure returns (uint256 BENDAmount_) {
        // BEND decimals: 3
        // asset decimals: 18
        BENDAmount_ = _amount.mul(1e3).mul(EXCHANGE_RATE).div(1e18);
    }

    function percentVestedFor(address _depositor) public view returns (uint256 percentVested_) {
        UserInfo memory user = userInfo[_depositor];

        if (block.timestamp < user.lastTime) return 0;

        uint256 timeSinceLast = block.timestamp.sub(user.lastTime);
        uint256 vesting = user.vesting;

        if (vesting > 0) {
            percentVested_ = timeSinceLast.mul(10000).div(vesting);
        } else {
            percentVested_ = 0;
        }
    }

    function pendingPayoutFor(address _depositor) external view returns (uint256 pendingPayout_) {
        uint256 percentVested = percentVestedFor(_depositor);
        uint256 payout = userInfo[_depositor].payout;

        if (percentVested >= 10000) {
            pendingPayout_ = payout;
        } else {
            pendingPayout_ = userInfo[_depositor].redeemableBeforeVesting;
        }
    }

    // ==== EXTERNAL FUNCTIONS ====

    function deposit(address _depositor) external payable onlyWhitelisted(_depositor) {
        require(block.timestamp >= START_PRESALE && block.timestamp <= END_PRESALE, "Sorry, presale is not enabled!");
        require(!finalized, "already finalized");

        uint256 available = availableFor(_depositor);
        require(msg.value <= available, "exceed limit");

        totalIncome = totalIncome.add(msg.value);

        UserInfo storage user = userInfo[_depositor];
        uint256 payoutFor = payFor(msg.value);
        user.payout = user.payout.add(payoutFor);
        user.vesting = VESTING_TERM;
        user.lastTime = startVesting;
        user.redeemableBeforeVesting = user.redeemableBeforeVesting.add(payoutFor.mul(UNLOCK_BEFORE_VESTING).div(100));

        emit Deposited(_depositor, msg.value);
    }

    function redeem(address _recipient) external {
        require(finalized, "not finalized yet");

        UserInfo memory user = userInfo[_recipient];

        uint256 percentVested = percentVestedFor(_recipient);
        if (block.timestamp < user.lastTime) return;

        if (percentVested >= 10000) {
            // if fully vested
            delete userInfo[_recipient]; // delete user info
            emit Redeemed(_recipient, user.payout, 0); // emit bond data

            BEND.transfer(_recipient, user.payout); // pay user everything due
        } else {
            // if unfinished
            // calculate payout vested
            uint256 payout = user.redeemableBeforeVesting;

            // store updated deposit info
            userInfo[_recipient] = UserInfo({
                payout: user.payout.sub(payout),
                vesting: user.vesting.sub(block.timestamp.sub(user.lastTime)),
                lastTime: block.timestamp,
                redeemableBeforeVesting: 0
            });

            emit Redeemed(_recipient, payout, userInfo[_recipient].payout);

            BEND.transfer(_recipient, payout); // pay user everything due
        }
    }

    // ==== RESTRICT FUNCTIONS ====

    function setWhitelist(address _depositor, bool _value) external onlyOwner {
        isWhitelist[_depositor] = _value;
        emit WhitelistUpdated(_depositor, _value);
    }

    function toggleWhitelist(address[] memory _depositors) external onlyOwner {
        for (uint256 i = 0; i < _depositors.length; i++) {
            isWhitelist[_depositors[i]] = !isWhitelist[_depositors[i]];
            emit WhitelistUpdated(_depositors[i], isWhitelist[_depositors[i]]);
        }
    }

    function emergencyWithdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function setupContracts(
        IERC20 _BEND
    ) external onlyOwner {
        BEND = _BEND;
    }

    // finalize the sale, init liquidity and deposit treasury
    // 100% public goes to LP pool and goes to treasury as liquidity asset
    // 100% private goes to treasury as stable asset
    function finalize() external onlyOwner {
        require(!finalized, "already finalized");

        payable(owner).transfer(address(this).balance);
        BEND.transfer(owner, BEND.balanceOf(address(this)));

        finalized = true;
    }

    function toggleWhitelistUsage() external onlyOwner {
        whitelistUsed = !whitelistUsed;
    }
}
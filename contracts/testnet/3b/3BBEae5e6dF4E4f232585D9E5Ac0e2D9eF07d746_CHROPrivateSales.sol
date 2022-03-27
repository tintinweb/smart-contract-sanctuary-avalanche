//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Vesting.sol";

/**
 * @title CHRO Private Sales Test
 */
contract CHROPrivateSales is Vesting {
  using SafeMath for uint256;

  event SalesStarted(uint256 amount);
  event SalesStopped(uint256 amount);
  event SalesCreated(address user, uint256 chroAmount, uint256 usdAmount, uint256 chroBalance);
  event WhitelistAdded(address user, uint256 usdAmount);
  event WhitelistRemoved(address user);
  event EmergencyTransfer(address receiver, uint256 amount);

  mapping(address => bool) private _whitelists;
  mapping(address => uint256) private _allocations;

  IERC20 public chroContract;
  IERC20 public usdContract;

  /// token price 1 $CHRO = $0.04
  uint256 public tokenPrice = 40000;

  /// minimum purchase in USD is $500
  uint256 public minimumPurchase = 500000000;
  uint256 public tokensSold;
  bool public isStarted = false;
  address public multisigAddress;
  address public usdTokenAddress;

  /**
   * @notice Set $CHRO contract address
   * @param _chroAddress $CHRO contract address
   * @param _multisigAddress Multisig contract address
   */
  constructor(address _chroAddress, address _multisigAddress) Vesting(_chroAddress) {
    chroContract = IERC20(_chroAddress);
    multisigAddress = payable(_multisigAddress);
  }

  modifier started() {
    require(isStarted, "Private Sales was stopped");
    _;
  }

  /**
   * @notice Check whitelisted status
   * @return bool True or false
   */
  function isWhitelisted(address _user) public view returns(bool) {
    return _whitelists[_user];
  }

  /**
   * @notice Get USD allocation
   * @return uint256 USD amount
   */
  function getAllocation(address _user) public view returns(uint256) {
    return _allocations[_user];
  }

  /**
   * @notice Get token balance
   * @return uint256 Token balance
   */
  function getTokenBalance() public view returns(uint256) {
    return _getTokenBalance();
  }

  /**
   * @notice Buy token directly by buyer
   * @param _usdAmount Amount of USD
   */
  function buyTokens(uint256 _usdAmount) public started {
    uint256 usdAmount = _usdAmount;
    uint256 chroAmount = _usdAmount.div(tokenPrice).mul(1e18);
    
    require(_whitelists[msg.sender], "Not whitelisted");
    require(_usdAmount >= minimumPurchase, "Minimum purchase required");
    require(chroContract.balanceOf(address(this)) >= chroAmount, "Insufficent CHRO allocation");
    require(usdAmount >= _allocations[msg.sender], "Insufficent USD allocation");

    uint256 allowanceOfAmount = usdContract.allowance(msg.sender, address(this));
    require(usdAmount <= allowanceOfAmount, "Insufficent allowance");

    SafeERC20.safeTransferFrom(usdContract, msg.sender, multisigAddress, usdAmount);
    _addBalance(msg.sender, chroAmount);

    tokensSold += chroAmount;

    emit SalesCreated(msg.sender, chroAmount, usdAmount, _getTokenBalance());
  }

  /**
   * ***********************************************
   * The functions below are callable by owner only
   * ***********************************************
   */
  
  /**
   * @notice Start sales
   */
  function startSales() public onlyOwner {
    require(usdTokenAddress != address(0), "Invalid USD token address");
    require(chroContract.balanceOf(address(this)) > 0, "Insufficent funds to start sales");
    
    isStarted = true;
    
    emit SalesStarted(chroContract.balanceOf(address(this)));
  }

  /**
   * @notice Stop sales and transfer balance to the owner
   */
  function stopSales() public onlyOwner {
    isStarted = false;
    emit SalesStopped(_getTokenBalance());
  }

  /**
   * @notice Set USD token address
   * @param _usdTokenAddress The USD token address
   */
  function setUsdTokenAddress(address _usdTokenAddress) public onlyOwner {
    usdTokenAddress = _usdTokenAddress;
    usdContract = IERC20(_usdTokenAddress);
  }

  /**
   * @notice Change multisig address that used to receiving payment
   * @param _multisig Multisig wallet address
   */
  function changeMultisig(address _multisig) public onlyOwner {
    multisigAddress = _multisig;
  }

  /**
   * @notice Change token (CHRO) contract address
   * @param _tokenAddress CHRO contract address
   */
  function changeTokenAddress(address _tokenAddress) public onlyOwner {
    chroContract = IERC20(_tokenAddress);
  }

  /**
   * @notice Add whitelist
   * @param _user User address
   * @param _usdAmount USD amount
   */
  function addWhitelist(address _user, uint256 _usdAmount) public onlyOwner {
    _whitelists[_user] = true;
    _allocations[_user] = _usdAmount;

    emit WhitelistAdded(_user, _usdAmount);
  }

  /**
   * @notice Remove whitelist
   * @param _user User address
   */
  function removeWhitelist(address _user) public onlyOwner {
    _whitelists[_user] = false;
    _allocations[_user] = 0;

    emit WhitelistRemoved(_user);
  }

  /**
   * @notice Emergency transfer balance to the owner
   * @param _amount CHRO amount
   */
  function emergencyTransfer(uint256 _amount) public onlyOwner {
    require(_getTokenBalance() >= _amount, "Insufficent balance");
    SafeERC20.safeTransfer(chroContract, owner(), _amount);

    emit EmergencyTransfer(owner(), _amount);
  }

  /**
   * @notice Set token price
   * @param _usdAmount USD price
   */
  function setTokenPrice(uint256 _usdAmount) public onlyOwner {
    tokenPrice = _usdAmount;
  }

  /**
   * @notice Set minimum purchase
   * @param _usdAmount USD price
   */
  function setMinimumPurchase(uint256 _usdAmount) public onlyOwner {
    minimumPurchase = _usdAmount;
  }

  /**
   * ********************************************
   * The functions below are callable internally
   * ********************************************
   */

  /**
   * @notice Get balance of purchasable token
   * @return uint256 Balance of token
   */
  function _getTokenBalance() internal view virtual returns(uint256) {
    uint256 balance = chroContract.balanceOf(address(this));
    return balance.sub(tokensSold);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

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
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title CHRO Vesting handler
 * @dev Inspired by OpenZeppelin Contracts v4.4.1 (finance/VestingWallet.sol)
 */
contract Vesting is Ownable {
  using SafeMath for uint256;

  event BalanceAdded(address beneficiary, uint256 amount);
  event TokenReleased(address beneficiary, uint256 amount);
  event PeriodUpdated(address owner, uint256 start, uint256 period, uint256 divider);

  /// CHRO contract address
  IERC20 public chroToken;

  uint256 private _start;
  uint256 private _duration;
  uint256 private _divider = 4;

  struct Account {
    uint256 purchased;
    uint256 balance;
    uint256 released;
  }

  mapping(address => Account) private _accounts;

  uint256 private _balance;
  uint256 private _released;

  constructor(address _chroToken) {
    chroToken = IERC20(_chroToken);
  }

  /**
   * @notice Get start timestamp
   * @return _start Start timestamp
   */
  function start() public view virtual returns (uint256) {
    return _start;
  }

  /**
   * @notice Get duration
   * @return _duration Duration in seconds
   */
  function duration() public view virtual returns (uint256) {
    return _duration;
  }

  /**
   * @notice Get divider
   * @return _divider Divider
   */
  function divider() public view virtual returns (uint256) {
    return _divider;
  }

  /**
   * @notice Get total of token balance
   * @return _balance Balance of token
   */
  function getBalance() public view virtual returns (uint256) {
    return _balance;
  }

  /**
   * @notice Get total of released token
   * @return _released Released token
   */
  function getReleased() public view virtual returns (uint256) {
    return _released;
  }

  /**
   * @notice Get user account
   * @param _user User address
   * @return Account User vested balance
   */
  function getAccount(address _user) public view returns(Account memory) {
    Account storage account = _accounts[_user];
    return account;
  }

  /**
   * @notice Release token to the user
   */
  function release() public {
    uint256 blockTimestamp = uint256(block.timestamp);
    require(_isReleasable(blockTimestamp), "Can't release CHRO");
    Account storage account = _accounts[msg.sender];

    uint256 _vestedAmount = _vestingSchedule(account.balance.add(account.released), blockTimestamp).sub(account.released);
    uint256 toRelease = _vestedAmount.sub(account.released);

    if (toRelease > 0) {
      SafeERC20.safeTransfer(chroToken, msg.sender, toRelease);
      account.released += toRelease;

      _released += toRelease;
      _balance -= toRelease;

      emit TokenReleased(msg.sender, toRelease);
    }
  }

  /**
   * @notice Get vested amount
   * @param _user User address
   * @param _timestamp Timestamp
   * @return uint256 Vested amount of the user
   */
  function vestedAmount(
    address _user,
    uint256 _timestamp
  ) public view virtual returns (uint256) {
    Account storage account = _accounts[_user];
    return _vestingSchedule(account.balance.add(account.released), _timestamp);
  }

  /**
   * *************************************************************
   * The functions below are callable internally by this contract
   * *************************************************************
   */

  /**
   * @notice Add balance to the user account
   * @param _user User address
   * @param _amount Amount of token
   */
  function _addBalance(address _user, uint256 _amount) internal virtual {
    _accounts[_user].purchased += _amount;
    _accounts[_user].balance += _amount;
    _balance += _amount;

    emit BalanceAdded(_user, _amount);
  }

  /**
   * @dev Virtual implementation of the vesting formula.
   * @dev This returns the amout vested, as a function of time, for an asset given its total historical allocation.
   */
  function _vestingSchedule(
    uint256 _allocationTotal,
    uint256 _timestamp
  ) internal view virtual returns (uint256) {
    if (_timestamp < start()) {
      return 0;
    } else if (_timestamp > start().add(duration())) {
      return _allocationTotal;
    } else {
      return _allocationTotal.mul(_timestamp.sub(start())).div(duration());
    }
  }

  function _isReleasable(uint256 _timestamp) internal view virtual returns (bool) {
    uint256 durationPerDivider = duration().div(_divider);
    uint256 startTime = start();
    bool isReleasable = false;

    for (uint i = 0; i < _divider; i++) {
      if (startTime.add(durationPerDivider) <= _timestamp) {
        isReleasable = true;
        break;
      }

      startTime += durationPerDivider;
    }

    return isReleasable;
  }

  /**
   * ***********************************************
   * The functions below are callable by owner only
   * ***********************************************
   */
   
  /**
   * @notice Set vesting period
   * @param _startTimestamp Timestamp of start
   * @param _durationSeconds Duration in seconds
   * @param _dividerCount Divider count
   */
  function setPeriod(uint256 _startTimestamp, uint256 _durationSeconds, uint256 _dividerCount) public onlyOwner {
    _start = _startTimestamp;
    _duration = _durationSeconds;
    _divider = _dividerCount;

    emit PeriodUpdated(owner(), _startTimestamp, _durationSeconds, _dividerCount);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
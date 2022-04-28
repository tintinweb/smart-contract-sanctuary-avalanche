/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-27
*/

// SPDX-License-Identifier: MIT
// Developed by: dxsoftware.net

pragma solidity ^0.8.6;

interface IERC20 {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 value) external returns (bool);

  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);
}


// File src/contracts/libraries/SafeMath.sol



/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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


// File src/contracts/libraries/Address.sol



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
    assembly {
      codehash := extcodehash(account)
    }
    return (codehash != accountHash && codehash != 0x0);
  }

  /**
   * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
   * `recipient`, forwarding all available gas and reverting on errors.
   *
   * increases the gas cost
   * of certain opcodes, possibly making contracts go over the 2300 gas limit
   * imposed by `transfer`, making them unable to receive funds via
   * `transfer`. {sendValue} removes this limitation.
   *
   *
   * IMPORTANT: because control is transferred to `recipient`, care must be
   * taken to not create reentrancy vulnerabilities. Consider using
   * {ReentrancyGuard} or the
   * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
   */
  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Kapex Address: insufficient balance");

    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    (bool success, ) = recipient.call{value: amount}("");
    require(success, "Kapex Address: unable to send value, recipient may have reverted");
  }

  /**
   * @dev Performs a Solidity function call using a low level `call`. A
   * plain`call` is an unsafe replacement for a function call: use this
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
    return functionCall(target, data, "Kapex Address: low-level call failed");
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
    return _functionCallWithValue(target, data, 0, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but also transferring `value` wei to `target`.
   *
   * Requirements:
   *
   * - the calling contract must have an BNB balance of at least `value`.
   * - the called Solidity function must be `payable`.
   *
   * _Available since v3.1._
   */
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, "Kapex Address: low-level call with value failed");
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
    require(address(this).balance >= value, "Kapex Address: insufficient balance for call");
    return _functionCallWithValue(target, data, value, errorMessage);
  }

  function _functionCallWithValue(
    address target,
    bytes memory data,
    uint256 weiValue,
    string memory errorMessage
  ) private returns (bytes memory) {
    require(isContract(target), "Kapex Address: call to non-contract");

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
    if (success) {
      return returndata;
    } else {
      // Look for revert reason and bubble it up if present
      if (returndata.length > 0) {
        // The easiest way to bubble the revert reason is using memory via assembly

        // solhint-disable-next-line no-inline-assembly
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


// File src/contracts/shared/Context.sol



/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
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
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}


// File src/contracts/shared/Ownable.sol



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
  address internal _owner;

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


// File src/contracts/libraries/LockOwnable.sol



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
contract LockOwnable is Ownable {
  address private _previousOwner;
  uint256 private _lockTime;

  function getUnlockTime() public view returns (uint256) {
    return _lockTime;
  }

  //Locks the contract for owner for the amount of time provided
  function lock(uint256 time) public virtual onlyOwner {
    _previousOwner = _owner;
    _owner = address(0);
    _lockTime = block.timestamp + time;
    emit OwnershipTransferred(_owner, address(0));
  }

  //Unlocks the contract for owner when _lockTime is exceeds
  function unlock() public virtual {
    require(_previousOwner == msg.sender, "KAPEX: You don't have permission to unlock");
    require(block.timestamp > _lockTime, "KAPEX: Contract is still locked");
    emit OwnershipTransferred(_owner, _previousOwner);
    _owner = _previousOwner;
    _previousOwner = address(0);
  }
}

contract WHITELIGHT is Context, IERC20, LockOwnable {
  using SafeMath for uint256;
  using Address for address;

  mapping(address => uint256) private _balances; // total Owned tokens
  mapping(address => mapping(address => uint256)) private _allowances; // allowed allowance for spender

  mapping(address => bool) public _isPair;
  mapping(address => bool) public _isExcludedFromFee; // excluded address from all fee

  address payable public _feeManager = payable(0x82Ec350eeA9741B3B47CC00b29F9B503076ee3D8); // WHITE feeManager address

  string private constant NAME = "White Light Token"; // token name
  string private constant SYMBOL = "WHITE"; // token symbol
  uint8 private constant DECIMALS = 9; // token decimals(1 token can be divided into 1eDECIMALS parts)

  uint256 private _totalSupply = 1 * 10**(9 + DECIMALS); // 1bn

  uint256 public _buyFee = 0;
  uint256 public _sellFee = 1000; // 10%
  uint256 public _transactionFee = 1000; // 10%

  event BuyFeeSet(uint256 buyFee);
  event SellFeeSet(uint256 sellFee);
  event TransactionFeeSet(uint256 transactionFee);
  event FeeManagerSet(address feeManager);

  constructor() {
    _balances[_msgSender()] = _totalSupply;

    _isExcludedFromFee[owner()] = true;
    _isExcludedFromFee[address(this)] = true;
    _isExcludedFromFee[_feeManager] = true;

    emit Transfer(address(0), _msgSender(), _totalSupply);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, reducing the total supply.
   */
  function _burn(address account, uint256 amount) internal virtual {
    uint256 accountBalance = _balances[account];

    require(accountBalance >= amount, "WHITE: burn amount exceeds balance");

    _balances[account] = accountBalance.sub(amount);
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  /**
   * @dev Destroys `amount` tokens from the caller.
   *
   * See {ERC20-_burn}.
   */
  function burn(uint256 amount) public virtual {
    _burn(_msgSender(), amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, deducting from the caller's
   * allowance.
   *
   * See {ERC20-_burn} and {ERC20-allowance}.
   *
   * Requirements:
   *
   * - the caller must have allowance for ``accounts``'s tokens of at least
   * `amount`.
   */
  function burnFrom(address account, uint256 amount) public virtual {
    _burn(account, amount);
    _approve(
      account,
      _msgSender(),
      _allowances[account][_msgSender()].sub(amount, "WHITE: transfer amount exceeds allowance")
    );
  }

  function name() public pure override returns (string memory) {
    return NAME;
  }

  function symbol() public pure override returns (string memory) {
    return SYMBOL;
  }

  function decimals() public pure override returns (uint8) {
    return DECIMALS;
  }

  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) public view override returns (uint256) {
    return _balances[account];
  }

  function transfer(address recipient, uint256 amount) public override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender) public view override returns (uint256) {
    return _allowances[owner][spender];
  }

  /**
   * @dev approves allowance of a spender
   */
  function approve(address spender, uint256 amount) public override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /**
   * @dev transfers from a sender to recipient with subtracting spenders allowance with each successful transfer
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(
      sender,
      _msgSender(),
      _allowances[sender][_msgSender()].sub(amount, "WHITE: transfer amount exceeds allowance")
    );
    return true;
  }

  /**
   * @dev approves allowance of a spender should set it to zero first than increase
   */
  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  /**
   * @dev decrease allowance of spender that it can spend on behalf of owner
   */
  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].sub(subtractedValue, "WHITE: decreased allowance below zero")
    );
    return true;
  }

  /**
   * @dev exclude an address from fee
   */
  function excludeFromFee(address account) public onlyOwner {
    _isExcludedFromFee[account] = true;
  }

  /**
   * @dev include an address for fee
   */
  function includeInFee(address account) public onlyOwner {
    _isExcludedFromFee[account] = false;
  }

  /**
   * @dev set's WHITE transaction fee
   */
  function setTransactionFee(uint256 fee) external onlyOwner {
    require(fee <= 1000, "WHITE: Transaction fee should be between 0% - 10% (0 - 1000)");
    require(fee >= _buyFee, "WHITE: Transaction fee should be between (buyFee)% - 10% (buyFee - 1000)");
    require(fee <= _sellFee, "WHITE: Transaction fee should be between 0% - (sellFee)% (0 - sellFee)");
    _transactionFee = fee;
    emit TransactionFeeSet(fee);
  }

  /**
   * @dev set's WHITE liquidity provider address
   */
  function setFeeManagerAddress(address payable feeManager) external onlyOwner {
    _isExcludedFromFee[_feeManager] = false;
    _feeManager = feeManager;
    _isExcludedFromFee[_feeManager] = true;
    emit FeeManagerSet(feeManager);
  }

  /**
   * @dev reduce buy fee for a certain amount of time
   */
  function setBuyFee(uint256 newBuyFee) external onlyOwner {
    require(newBuyFee <= _transactionFee, "WHITE: Decreased buy fee should be less than (transfer fee)%");
    _buyFee = newBuyFee;
    emit BuyFeeSet(newBuyFee);
  }

  /**
   * @dev increase sell fee for a certain amount of time
   */
  function setSellFee(uint256 newSellFee) external onlyOwner {
    require(
      newSellFee >= _transactionFee && newSellFee <= 1000,
      "WHITE: Increased sell fee should be between (transfer fee)% - 10%"
    );
    _sellFee = newSellFee;
    emit SellFeeSet(newSellFee);
  }

  /**
   * @dev approves amount of token spender can spend on behalf of an owner
   */
  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) private {
    require(owner != address(0), "WHITE: approve from the zero address");
    require(spender != address(0), "WHITE: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  /**
   * @dev transfers token from sender to recipient also auto
   * send collected fee to WHITELiquidityProvider address(contract).
   */
  function _transfer(
    address from,
    address to,
    uint256 amount
  ) private {
    require(from != address(0) && to != address(0), "WHITE: transfer from/to the Zero address");
    require(amount <= _balances[from], "WHITE: transfer amount exceeds Balance");

    uint256 fee = _transactionFee;

    if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
      fee = 0;
    } else if (_isPair[from]) {
      fee = _buyFee;
    } else if (_isPair[to]) {
      fee = _sellFee;
    }

    uint256 deducted = amount.mul(fee).div(10000);
    uint256 transferAmount = amount.sub(deducted);

    _balances[from] = _balances[from].sub(amount);
    _balances[to] = _balances[to].add(transferAmount);
    emit Transfer(from, to, transferAmount);

    if (deducted > 0) {
      _balances[_feeManager] = _balances[_feeManager].add(deducted);
      emit Transfer(from, _feeManager, deducted);
    }
  }

  /**
   * @dev recovers any tokens stuck in Contract's balance
   * NOTE! if ownership is renounced then it will not work
   */
  function recoverTokens(
    address tokenAddress,
    address recipient,
    uint256 amountToRecover,
    uint256 recoverFeePercentage
  ) public onlyOwner {
    IERC20 token = IERC20(tokenAddress);
    uint256 balance = token.balanceOf(address(this));

    require(balance >= amountToRecover, "WHITE: Not Enough Tokens in contract to recover");

    address feeRecipient = _msgSender();
    uint256 feeAmount = amountToRecover.mul(recoverFeePercentage).div(10000);
    amountToRecover = amountToRecover.sub(feeAmount);

    if (feeAmount > 0) token.transfer(feeRecipient, feeAmount);
    if (amountToRecover > 0) token.transfer(recipient, amountToRecover);
  }

  function togglePair(address pairAddress) public onlyOwner {
    _isPair[pairAddress] = !_isPair[pairAddress];
  }
}
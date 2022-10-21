// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../interfaces/IETFToken.sol";
import "../owner/Operator.sol";
import "../lib/BNum.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ETFToken is Operator, ERC20, IETFToken, BNum {
    // BONE = 10**18
    uint256 public constant MIN_BALANCE = 1e6; // MIN_BALANCE = BONE / 10**12
    uint256 public constant INIT_POOL_SUPPLY = 1e19; // INIT_POOL_SUPPLY = BONE * 10;
    uint256 public constant MIN_BOUND_TOKENS = 2;
    uint256 public constant MAX_BOUND_TOKENS = 25;
    uint256 public constant EXIT_FEE = 1e16;// 0.01

    uint256 public maxPoolTokens;
    address public exitFeeRecipient;

    address[] internal _tokens;
    mapping(address => Record) internal _records;
    mapping(address => uint256) internal _minimumBalances;

    function isBound(address token) public view returns (bool) {
        return _records[token].bound;
    }

    function getNumTokens() public view returns (uint256) {
        return _tokens.length;
    }

    function getCurrentTokens() public view returns (address[] memory) {
        return _tokens;
    }

    function getTokenRecord(address token)
        public
        view
        returns (Record memory record)
    {
        record = _records[token];
        require(record.bound, "DexETF: Token not bound");
    }

    function getBalance(address token) public view returns (uint256) {
        Record storage record = _records[token];
        require(record.bound, "DexETF: Token not bound");
        return record.balance;
    }

    function getMinimumBalance(address token) public view returns (uint256) {
        Record memory record = _records[token];
        require(record.bound, "DexETF: Token not bound");
        require(!record.ready, "DexETF: Token already ready");
        return _minimumBalances[token];
    }

    function getUsedBalance(address token) public view returns (uint256) {
        Record memory record = _records[token];
        require(record.bound, "DexETF: Token not bound");
        if (!record.ready) {
            return _minimumBalances[token];
        }
        return record.balance;
    }

    event LOG_JOIN(
        address indexed caller,
        address indexed tokenIn,
        uint256 tokenAmountIn
    );
    event LOG_EXIT(
        address indexed caller,
        address indexed tokenOut,
        uint256 tokenAmountOut,
        uint256 exitFee
    );
    event LOG_TOKEN_REMOVED(address token);
    event LOG_TOKEN_ADDED(address indexed token, uint256 minimumBalance);
    event LOG_MINIMUM_BALANCE_UPDATED(address token, uint256 minimumBalance);
    event LOG_TOKEN_READY(address indexed token);
    event LOG_MAX_TOKENS_UPDATED(uint256 maxPoolTokens);
    event LOG_EXIT_FEE_RECIPIENT_UPDATED(address exitFeeRecipient);

    constructor(
        string memory _name,
        string memory _symbol,
        address _exitFeeRecipient
    ) ERC20(_name, _symbol) {
        require(
            _exitFeeRecipient != address(0),
            "DexETF: Fee recipient is zero address"
        );
        exitFeeRecipient = _exitFeeRecipient;
    }

    function initialize(
        address[] memory tokens,
        uint256[] memory balances,
        address tokenProvider
    ) public onlyOperator {
        require(_tokens.length == 0, "DexETF: Already initialized");
        uint256 len = tokens.length;
        require(len >= MIN_BOUND_TOKENS, "DexETF: Min bound tokens overflow");
        require(len <= MAX_BOUND_TOKENS, "DexETF: Max bound tokens overflow");
        require(balances.length == len, "DexETF: Invalid arrays length");
        for (uint256 i = 0; i < len; i++) {
            address token = tokens[i];
            uint256 balance = balances[i];
            require(balance >= MIN_BALANCE, "DexETF: Min balance overflow");
            _records[token] = Record({
                bound: true,
                ready: true,
                index: uint8(i),
                balance: balance
            });
            _tokens.push(token);
            _pullUnderlying(token, tokenProvider, balance);
        }
        _mint(address(this), INIT_POOL_SUPPLY);
        _transfer(address(this), tokenProvider, INIT_POOL_SUPPLY);
    }

    function setMaxPoolTokens(uint256 _maxPoolTokens) public onlyOperator {
        maxPoolTokens = _maxPoolTokens;
        emit LOG_MAX_TOKENS_UPDATED(maxPoolTokens);
    }

    function setExitFeeRecipient(address _exitFeeRecipient)
        public
        onlyOperator
    {
        require(
            _exitFeeRecipient != address(0),
            "DexETF: Fee recipient is zero address"
        );
        exitFeeRecipient = _exitFeeRecipient;
        emit LOG_EXIT_FEE_RECIPIENT_UPDATED(_exitFeeRecipient);
    }

    function setMinimumBalance(address token, uint256 minimumBalance)
        public
        onlyOperator
    {
        Record storage record = _records[token];
        require(record.bound, "DexETF: Token not bound");
        require(!record.ready, "DexETF: Token already ready");
        _minimumBalances[token] = minimumBalance;
        emit LOG_MINIMUM_BALANCE_UPDATED(token, minimumBalance);
    }

    function joinPool(uint256 poolAmountOut, uint256[] memory maxAmountsIn)
        public
    {
        address caller = msg.sender;
        uint256 poolTotal = totalSupply();
        uint256 ratio = bdiv(poolAmountOut, poolTotal);
        require(ratio != 0, "DexETF: Invalid ratio");
        require(
            maxAmountsIn.length == _tokens.length,
            "DexETF: Invalid arrays length"
        );
        uint256 _maxPoolTokens = maxPoolTokens;
        if (_maxPoolTokens > 0)
            require(
                (poolTotal + poolAmountOut) <= _maxPoolTokens,
                "DexETF: Max pool tokens overflow"
            );
        for (uint256 i = 0; i < maxAmountsIn.length; i++) {
            address t = _tokens[i];
            (Record memory record, uint256 realBalance) = _getInputToken(t);
            uint256 tokenAmountIn = bmul(ratio, record.balance);
            require(tokenAmountIn != 0, "DexETF: Token amount in is zero");
            require(
                tokenAmountIn <= maxAmountsIn[i],
                "DexETF: Max amount in overflow"
            );
            _updateInputToken(t, record, badd(realBalance, tokenAmountIn));
            emit LOG_JOIN(caller, t, tokenAmountIn);
            _pullUnderlying(t, caller, tokenAmountIn);
        }
        _mint(address(this), poolAmountOut);
        _transfer(address(this), caller, poolAmountOut);
    }

    function exitPool(uint256 poolAmountIn, uint256[] memory minAmountsOut)
        public
    {
        address caller = msg.sender;
        require(
            minAmountsOut.length == _tokens.length,
            "DexETF: Invalid arrays length"
        );
        uint256 poolTotal = totalSupply();
        uint256 exitFee = bmul(poolAmountIn, EXIT_FEE);
        uint256 pAiAfterExitFee = bsub(poolAmountIn, exitFee);
        uint256 ratio = bdiv(pAiAfterExitFee, poolTotal);
        require(ratio != 0, "DexETF: Invalid ratio");
        _transfer(caller, address(this), poolAmountIn);
        _transfer(address(this), exitFeeRecipient, exitFee);
        _burn(caller, pAiAfterExitFee);
        for (uint256 i = 0; i < minAmountsOut.length; i++) {
            address t = _tokens[i];
            Record memory record = _records[t];
            if (record.ready) {
                uint256 tokenAmountOut = bmul(ratio, record.balance);
                require(
                    tokenAmountOut != 0,
                    "DexETF: Token amount out is zero"
                );
                require(
                    tokenAmountOut >= minAmountsOut[i],
                    "DexETF: Min amount out overflow"
                );
                _records[t].balance = bsub(record.balance, tokenAmountOut);
                emit LOG_EXIT(caller, t, tokenAmountOut, exitFee);
                _pushUnderlying(t, caller, tokenAmountOut);
            } else {
                require(
                    minAmountsOut[i] == 0,
                    "DexETF: Min amount out overflow"
                );
            }
        }
    }

    function _pullUnderlying(
        address erc20,
        address from,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = erc20.call(
            abi.encodeWithSelector(
                IERC20.transferFrom.selector,
                from,
                address(this),
                amount
            )
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "DexETF: Pull underlying fail"
        );
    }

    function _pushUnderlying(
        address erc20,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = erc20.call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, amount)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "DexETF: Push underlying fail"
        );
    }

    function addTokenAsset(address token, uint256 minimumBalance)
        public
        onlyOperator
    {
        require(!_records[token].bound, "DexETF: Token already bound");
        require(minimumBalance >= MIN_BALANCE, "DexETF: Min balance overflow");
        _records[token] = Record({
            bound: true,
            ready: false,
            index: uint8(_tokens.length),
            balance: 0
        });
        _tokens.push(token);
        _minimumBalances[token] = minimumBalance;
        emit LOG_TOKEN_ADDED(token, minimumBalance);
    }

    function removeTokenAsset(address token) public onlyOperator {
        Record memory record = _records[token];
        uint256 index = record.index;
        uint256 last = _tokens.length - 1;
        if (index != last) {
            _tokens[index] = _tokens[last];
            _records[_tokens[index]].index = uint8(index);
        }
        _tokens.pop();
        _records[token] = Record({
            bound: false,
            ready: false,
            index: 0,
            balance: 0
        });
        emit LOG_TOKEN_REMOVED(token);
    }

    function _updateInputToken(
        address token,
        Record memory record,
        uint256 realBalance
    ) internal {
        if (!record.ready && realBalance >= record.balance) {
            _minimumBalances[token] = 0;
            _records[token].ready = true;
            record.ready = true;
            emit LOG_TOKEN_READY(token);
        }
        _records[token].balance = realBalance;
    }

    function _getInputToken(address token)
        internal
        view
        returns (Record memory record, uint256 realBalance)
    {
        record = _records[token];
        require(record.bound, "DexETF: Token not bound");
        realBalance = record.balance;
        if (!record.ready) {
            record.balance = _minimumBalances[token];
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Operator is Context, Ownable {
    address private _operator;

    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);

    constructor() {
        _operator = _msgSender();
        emit OperatorTransferred(address(0), _operator);
    }

    function operator() public view returns (address) {
        return _operator;
    }

    modifier onlyOperator() {
        require(_operator == msg.sender, "operator: caller is not the operator");
        _;
    }

    function isOperator() public view returns (bool) {
        return _msgSender() == _operator;
    }

    function transferOperator(address newOperator_) public onlyOwner {
        _transferOperator(newOperator_);
    }

    function _transferOperator(address newOperator_) internal {
        require(newOperator_ != address(0), "operator: zero address given for new operator");
        emit OperatorTransferred(address(0), newOperator_);
        _operator = newOperator_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BConst.sol";

contract BNum {
  uint256 internal constant BONE = 10**18;
  uint256 internal constant MIN_BPOW_BASE = 1 wei;
  uint256 internal constant MAX_BPOW_BASE = (2 * BONE) - 1 wei;
  uint256 internal constant BPOW_PRECISION = BONE / 10**10;

  function btoi(uint256 a) internal pure returns (uint256) {
    return a / BONE;
  }

  function bfloor(uint256 a) internal pure returns (uint256) {
    return btoi(a) * BONE;
  }

  function badd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "DexETF: Add overflow");
    return c;
  }

  function bsub(uint256 a, uint256 b) internal pure returns (uint256) {
    (uint256 c, bool flag) = bsubSign(a, b);
    require(!flag, "DexETF: Sub overflow");
    return c;
  }

  function bsubSign(uint256 a, uint256 b)
    internal
    pure
    returns (uint256, bool)
  {
    if (a >= b) {
      return (a - b, false);
    } else {
      return (b - a, true);
    }
  }

  function bmul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c0 = a * b;
    require(a == 0 || c0 / a == b, "DexETF: Mul overflow");
    uint256 c1 = c0 + (BONE / 2);
    require(c1 >= c0, "DexETF: Mul overflow");
    uint256 c2 = c1 / BONE;
    return c2;
  }

  function bdiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "DexETF: Div zero");
    uint256 c0 = a * BONE;
    require(a == 0 || c0 / a == BONE, "DexETF: Div overflow");
    uint256 c1 = c0 + (b / 2);
    require(c1 >= c0, "DexETF: Div overflow");
    uint256 c2 = c1 / b;
    return c2;
  }

  function bpowi(uint256 a, uint256 n) internal pure returns (uint256) {
    uint256 z = n % 2 != 0 ? a : BONE;
    for (n /= 2; n != 0; n /= 2) {
      a = bmul(a, a);
      if (n % 2 != 0) {
        z = bmul(z, a);
      }
    }
    return z;
  }

  function bpow(uint256 base, uint256 exp) internal pure returns (uint256) {
    require(base >= MIN_BPOW_BASE, "DexETF: Bpow base too low");
    require(base <= MAX_BPOW_BASE, "DexETF: Bpow base too high");
    uint256 whole = bfloor(exp);
    uint256 remain = bsub(exp, whole);
    uint256 wholePow = bpowi(base, btoi(whole));
    if (remain == 0) {
      return wholePow;
    }
    uint256 partialResult = bpowApprox(base, remain, BPOW_PRECISION);
    return bmul(wholePow, partialResult);
  }

  function bpowApprox(
    uint256 base,
    uint256 exp,
    uint256 precision
  ) internal pure returns (uint256) {
    uint256 a = exp;
    (uint256 x, bool xneg) = bsubSign(base, BONE);
    uint256 term = BONE;
    uint256 sum = term;
    bool negative = false;
    for (uint256 i = 1; term >= precision; i++) {
      uint256 bigK = i * BONE;
      (uint256 c, bool cneg) = bsubSign(a, bsub(bigK, BONE));
      term = bmul(term, bmul(c, x));
      term = bdiv(term, bigK);
      if (term == 0) break;
      if (xneg) negative = !negative;
      if (cneg) negative = !negative;
      if (negative) {
        sum = bsub(sum, term);
      } else {
        sum = badd(sum, term);
      }
    }
    return sum;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BConst {
  // uint256 internal constant WEIGHT_UPDATE_DELAY = 1 hours;
  // uint256 internal constant WEIGHT_CHANGE_PCT = BONE / 100;
  // uint256 internal constant BONE = 10**18;
  // uint256 internal constant MIN_BOUND_TOKENS = 2;
  // uint256 internal constant MAX_BOUND_TOKENS = 25;
  // uint256 internal constant EXIT_FEE = 1e16;
  // uint256 internal constant MIN_WEIGHT = BONE / 8;
  // uint256 internal constant MAX_WEIGHT = BONE * 25;
  // uint256 internal constant MAX_TOTAL_WEIGHT = BONE * 26;
  // uint256 internal constant MIN_BALANCE = BONE / 10**12;
  // uint256 internal constant INIT_POOL_SUPPLY = BONE * 10;
  // uint256 internal constant MIN_BPOW_BASE = 1 wei;
  // uint256 internal constant MAX_BPOW_BASE = (2 * BONE) - 1 wei;
  // uint256 internal constant BPOW_PRECISION = BONE / 10**10;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IETFToken {
    /**
     * @dev Token record data structure
     * @param bound is token bound to pool
     * @param ready has token been initialized
     * @param index index of address in tokens array
     * @param balance token balance
     */
    struct Record {
        bool bound;
        bool ready;
        uint8 index;
        uint256 balance;
    }

    function EXIT_FEE() external view returns (uint256);

    function INIT_POOL_SUPPLY() external view returns (uint256);

    function MAX_BOUND_TOKENS() external view returns (uint256);

    function MIN_BALANCE() external view returns (uint256);

    function MIN_BOUND_TOKENS() external view returns (uint256);

    function addTokenAsset(address token, uint256 minimumBalance) external;

    function exitFeeRecipient() external view returns (address);

    function exitPool(uint256 poolAmountIn, uint256[] memory minAmountsOut) external;

    function getBalance(address token) external view returns (uint256);

    function getCurrentTokens() external view returns (address[] memory currentTokens);

    function getMinimumBalance(address token) external view returns (uint256);

    function getNumTokens() external view returns (uint256);

    function getTokenRecord(address token) external view returns (Record memory record);

    function getUsedBalance(address token) external view returns (uint256);

    function initialize(
        address[] memory tokens,
        uint256[] memory balances,
        address tokenProvider
    ) external;

    function isBound(address token) external view returns (bool);

    function joinPool(uint256 poolAmountOut, uint256[] memory maxAmountsIn) external;

    function maxPoolTokens() external view returns (uint256);

    function removeTokenAsset(address token) external;

    function setExitFeeRecipient(address _exitFeeRecipient) external;

    function setMaxPoolTokens(uint256 _maxPoolTokens) external;

    function setMinimumBalance(address token, uint256 minimumBalance) external;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
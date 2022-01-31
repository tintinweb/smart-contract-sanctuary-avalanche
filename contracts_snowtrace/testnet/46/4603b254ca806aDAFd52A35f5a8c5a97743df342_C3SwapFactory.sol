/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-28
*/

pragma solidity ^0.8.0;

interface I3SwapFactory {
  function createTriad(
    address token0,
    address token1,
    address token2
  ) external returns (address triad);

  function getTriads(
    address token0,
    address token1,
    address token2
  ) external returns (address triad);

  function feeTo() external view returns (address);

  function feeToSetter() external view returns (address);

  function setFeeTo(address) external;

  function setFeeToSetter(address) external;

  function allTriadsLength() external view returns (uint);

  function allTriads(uint) external view returns (address triad);
}

interface I3SwapTriad {
  function factory() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function token2() external view returns (address);

  function mint(address to) external returns (uint liquidity);

  function burn(address to)
    external
    returns (
      uint amount0,
      uint amount1,
      uint amount2
    );

  function initialize(
    address t0,
    address t1,
    address t2
  ) external;
}

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
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
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
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /**
   * @dev See {IERC20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {ERC20}.
   *
   * Requirements:
   *
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for ``sender``'s tokens of at least
   * `amount`.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);

    uint256 currentAllowance = _allowances[sender][_msgSender()];
    require(currentAllowance >= amount, 'ERC20: transfer amount exceeds allowance');
    unchecked {
      _approve(sender, _msgSender(), currentAllowance - amount);
    }

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
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
    uint256 currentAllowance = _allowances[_msgSender()][spender];
    require(currentAllowance >= subtractedValue, 'ERC20: decreased allowance below zero');
    unchecked {
      _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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
   * - `sender` cannot be the zero address.
   * - `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   */
  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual {
    require(sender != address(0), 'ERC20: transfer from the zero address');
    require(recipient != address(0), 'ERC20: transfer to the zero address');

    _beforeTokenTransfer(sender, recipient, amount);

    uint256 senderBalance = _balances[sender];
    require(senderBalance >= amount, 'ERC20: transfer amount exceeds balance');
    unchecked {
      _balances[sender] = senderBalance - amount;
    }
    _balances[recipient] += amount;

    emit Transfer(sender, recipient, amount);

    _afterTokenTransfer(sender, recipient, amount);
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
    require(account != address(0), 'ERC20: mint to the zero address');

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
    require(account != address(0), 'ERC20: burn from the zero address');

    _beforeTokenTransfer(account, address(0), amount);

    uint256 accountBalance = _balances[account];
    require(accountBalance >= amount, 'ERC20: burn amount exceeds balance');
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
    require(owner != address(0), 'ERC20: approve from the zero address');
    require(spender != address(0), 'ERC20: approve to the zero address');

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
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

contract C3SwapERC20 is ERC20 {
  constructor() ERC20('3Swap V1', '3Swap-V1') {}
}

library Math {
  function min(uint x, uint y) public pure returns (uint z) {
    z = x < y ? x : y;
  }

  function max(uint x, uint y) public pure returns (uint z) {
    z = x > y ? x : y;
  }

  function add(uint x, uint y) public pure returns (uint z) {
    z = x + y;
  }

  function sub(uint x, uint y) public pure returns (uint z) {
    z = x - y;
  }

  function mul(uint x, uint y) public pure returns (uint z) {
    z = x * y;
  }

  function div(uint x, uint y) public pure returns (uint z) {
    require(y != 0);
    z = x / y;
  }

  function pow(uint x, uint y) public pure returns (uint z) {
    z = x**y;
  }

  // Babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
  function sqrt(uint x) public pure returns (uint y) {
    uint _x = x;
    uint _y = 1;

    while (_x - _y > uint(0)) {
      _x = (_x + _y) / 2;
      _y = x / _x;
    }
    y = uint(_x);
  }
}

library UQ112x112 {
  uint224 constant primer = 2**112;

  function encode(uint112 y) internal pure returns (uint224 z) {
    z = uint224(y) * primer;
  }

  function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
    z = x / uint224(y);
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
    require(_status != _ENTERED, 'ReentrancyGuard: reentrant call');

    // Any calls to nonReentrant after this point will fail
    _status = _ENTERED;

    _;

    // By storing the original value once again, a refund is triggered (see
    // https://eips.ethereum.org/EIPS/eip-2200)
    _status = _NOT_ENTERED;
  }
}

contract C3SwapTriad is I3SwapTriad, C3SwapERC20, ReentrancyGuard {
  using Math for uint;
  using UQ112x112 for uint224;

  uint public constant MINIMUM_LIQUIDITY = 10**3;

  address public token0;
  address public token1;
  address public token2;
  address public factory;

  uint112 private reserve0;
  uint112 private reserve1;
  uint112 private reserve2;
  uint32 private blockTimestampLast;
  uint public price0CumulativeLast;
  uint public price1CumulativeLast;
  uint public price2CumulativeLast;
  uint public kLast;

  modifier onlyFactory() {
    require(msg.sender == factory);
    _;
  }

  constructor() {
    factory = msg.sender;
  }

  function getReserves()
    public
    view
    returns (
      uint112 _reserve0,
      uint112 _reserve1,
      uint112 _reserve2,
      uint32 _blockTimestampLast
    )
  {
    _reserve0 = reserve0;
    _reserve1 = reserve1;
    _reserve2 = reserve2;
    _blockTimestampLast = blockTimestampLast;
  }

  function _mintFee(
    uint112 _reserve0,
    uint112 _reserve1,
    uint112 _reserve2
  ) private returns (bool _feeOn) {
    address feeTo = I3SwapFactory(factory).feeTo();
    _feeOn = feeTo != address(0);
    uint _kLast = kLast;
    if (_feeOn) {
      if (_kLast != 0) {
        uint rootK = Math.sqrt((uint(_reserve0).add(uint(_reserve1))).mul(uint(_reserve2)));
        uint rootKLast = Math.sqrt(_kLast);
        if (rootK > rootKLast) {
          uint totalSup = totalSupply();
          uint liquidity = totalSup.mul(rootK.sub(rootKLast)) / rootK.mul(5).add(rootKLast);

          if (liquidity > 0) _mint(feeTo, liquidity);
        }
      }
    } else if (_kLast != 0) {
      kLast = 0;
    }
  }

  function _update(
    uint balance0,
    uint balance1,
    uint balance2,
    uint112 _reserve0,
    uint112 _reserve1,
    uint112 _reserve2
  ) private {
    require(
      balance0 <= uint112(uint(int(-1))) && balance1 <= uint112(uint(int(-1))) && balance2 <= uint112(uint(int(-1)))
    );
    uint32 blockTimestamp = uint32(block.timestamp % 2**32);
    uint32 timeElapsed = blockTimestamp - blockTimestampLast;

    if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0 && _reserve2 != 0) {
      price0CumulativeLast += uint(UQ112x112.encode(_reserve1 + _reserve2).uqdiv(_reserve0)) * timeElapsed;
      price1CumulativeLast += uint(UQ112x112.encode(_reserve2 + _reserve0).uqdiv(_reserve1)) * timeElapsed;
      price2CumulativeLast += uint(UQ112x112.encode(_reserve1 + _reserve0).uqdiv(_reserve2)) * timeElapsed;
    }
    reserve0 = uint112(balance0);
    reserve1 = uint112(balance1);
    reserve2 = uint112(balance2);
    blockTimestampLast = blockTimestamp;
  }

  function mint(address to) external nonReentrant returns (uint liquidity) {
    (uint112 _reserve0, uint112 _reserve1, uint112 _reserve2, ) = getReserves();
    uint balance0 = IERC20(token0).balanceOf(address(this));
    uint balance1 = IERC20(token1).balanceOf(address(this));
    uint balance2 = IERC20(token2).balanceOf(address(this));
    uint amount0 = balance0.sub(_reserve0);
    uint amount1 = balance1.sub(_reserve1);
    uint amount2 = balance2.sub(_reserve2);

    bool feeOn = _mintFee(_reserve0, _reserve1, _reserve2);
    uint _totalSupply = totalSupply();

    if (_totalSupply == 0) {
      liquidity = Math.sqrt(((amount0.add(amount1)).mul(amount2))).sub(MINIMUM_LIQUIDITY);
      _mint(address(0), MINIMUM_LIQUIDITY);
    } else {
      liquidity = Math.min(
        amount0.add(amount1).mul(_totalSupply) / uint(_reserve0 + _reserve1),
        amount2.mul(_totalSupply).div(uint(_reserve2))
      );
    }

    require(liquidity > 0);
    _mint(to, liquidity);
    _update(balance0, balance1, balance2, _reserve0, _reserve1, _reserve2);
    if (feeOn) uint(reserve0 + reserve1).mul(reserve2);
  }

  function burn(address to)
    external
    nonReentrant
    returns (
      uint amount0,
      uint amount1,
      uint amount2
    )
  {
    (uint112 _reserve0, uint112 _reserve1, uint112 _reserve2, ) = getReserves();
    uint balance0 = IERC20(token0).balanceOf(address(this));
    uint balance1 = IERC20(token1).balanceOf(address(this));
    uint balance2 = IERC20(token2).balanceOf(address(this));
    uint liquidity = balanceOf(address(this));

    bool feeOn = _mintFee(_reserve0, _reserve1, _reserve2);
    uint _totalSupply = totalSupply();
    {
      amount0 = liquidity.mul(balance0) / _totalSupply;
      amount1 = liquidity.mul(balance1) / _totalSupply;
      amount2 = liquidity.mul(balance2) / _totalSupply;
    }
    require(amount0 > 0 && amount1 > 0 && amount2 > 0);
    _burn(address(this), liquidity);

    _safeTransfer(token0, to, amount0);
    _safeTransfer(token1, to, amount1);
    _safeTransfer(token2, to, amount2);
    {
      balance0 = IERC20(token0).balanceOf(address(this));
      balance1 = IERC20(token1).balanceOf(address(this));
      balance2 = IERC20(token2).balanceOf(address(this));
    }

    _update(balance0, balance1, balance2, _reserve0, _reserve1, _reserve2);

    if (feeOn) kLast = uint(reserve0 + reserve1).mul(reserve2);
  }

  function swap(
    uint amount0Out,
    uint amount1Out,
    uint amount2Out,
    address to
  ) external nonReentrant {
    require(amount0Out > 0 || amount1Out > 0 || amount2Out > 0);
    (uint112 _reserve0, uint112 _reserve1, uint112 _reserve2, ) = getReserves();
    require(amount0Out < _reserve0 && amount1Out < _reserve1 && amount2Out < _reserve2);

    require(to != token0 && to != token1 && to != token2);
    if (amount0Out > 0) _safeTransfer(token0, to, amount0Out);
    if (amount1Out > 0) _safeTransfer(token1, to, amount1Out);
    if (amount2Out > 0) _safeTransfer(token2, to, amount2Out);
    uint balance0 = IERC20(token0).balanceOf(address(this));
    uint balance1 = IERC20(token1).balanceOf(address(this));
    uint balance2 = IERC20(token2).balanceOf(address(this));

    uint _left0 = _reserve0 - amount0Out;
    uint _left1 = _reserve1 - amount1Out;
    uint _left2 = _reserve2 - amount2Out;

    uint amount0In = balance0 > _left0 ? balance0 - (_left0) : 0;
    uint amount1In = balance1 > _left1 ? balance1 - (_left1) : 0;
    uint amount2In = balance2 > _left2 ? balance2 - (_left2) : 0;
    require(amount0In > 0 || amount1In > 0 || amount2In > 0);
    {
      uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
      uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));
      uint balance2Adjusted = balance2.mul(1000).sub(amount2In.mul(3));
      require(
        (balance0Adjusted + balance1Adjusted).mul(balance2Adjusted) >=
          uint(_reserve0 + _reserve1).mul(_reserve2).mul(1000**2)
      );
    }

    _update(balance0, balance1, balance2, _reserve0, _reserve1, _reserve2);
  }

  function initialize(
    address t0,
    address t1,
    address t2
  ) external onlyFactory {
    token0 = t0;
    token1 = t1;
    token2 = t2;
  }

  function _safeTransfer(
    address token_,
    address to_,
    uint value
  ) private {
    (bool success, bytes memory data) = token_.call(
      abi.encodeWithSelector(bytes4(keccak256(bytes('transfer(address,uint256)'))), to_, value)
    );
    require(success && (data.length == 0 || abi.decode(data, (bool))));
  }
}

// File: contracts/C3SwapFactory.sol

pragma solidity ^0.8.0;

contract C3SwapFactory is I3SwapFactory {
  address public feeTo;
  address public feeToSetter;

  mapping(address => mapping(address => mapping(address => address))) public getTriads;
  address[] public allTriads;

  constructor(address _feeToSetter) {
    feeToSetter = _feeToSetter;
  }

  function allTriadsLength() external view returns (uint) {
    return allTriads.length;
  }

  function createTriad(
    address token0,
    address token1,
    address token2
  ) external returns (address triad) {
    require(token0 != token1 && token1 != token2 && token0 != token2);
    (address tokenA, address tokenB) = token0 < token1 ? (token0, token1) : (token1, token0);
    (address tokenX, address tokenY) = tokenB < token2 ? (tokenB, token2) : (token2, tokenB);
    require(tokenA != address(0));
    require(getTriads[tokenA][tokenX][tokenY] == address(0));
    bytes memory bytecode = type(C3SwapTriad).creationCode;
    bytes32 salt = keccak256(abi.encodePacked(tokenA, tokenX, tokenY));

    assembly {
      triad := create2(0, add(bytecode, 32), mload(bytecode), salt)
    }
    I3SwapTriad(triad).initialize(tokenA, tokenX, tokenY);
    // Populate mapping in various directions. There are 6 ways this can be done (using n! = nx(n-1)x(n-2)x...3x2x1)
    getTriads[tokenA][tokenX][tokenY] = triad;
    getTriads[tokenX][tokenA][tokenY] = triad;
    getTriads[tokenX][tokenY][tokenA] = triad;
    getTriads[tokenY][tokenX][tokenA] = triad;
    getTriads[tokenY][tokenA][tokenX] = triad;
    getTriads[tokenA][tokenY][tokenX] = triad;
    allTriads.push(triad);
  }

  function setFeeTo(address _feeTo) external {
    require(msg.sender == feeToSetter);
    feeTo = _feeTo;
  }

  function setFeeToSetter(address _feeToSetter) external {
    require(msg.sender == feeToSetter);
    feeToSetter = _feeToSetter;
  }
}
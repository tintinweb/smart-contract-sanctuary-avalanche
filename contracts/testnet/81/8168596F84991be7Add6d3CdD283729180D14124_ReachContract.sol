/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-18
*/

// Automatically generated with Reach 0.1.10 (c0bba7d2)
pragma abicoder v2;

pragma solidity ^0.8.12;

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
/*
  ReachToken essentially emulates Algorand Standard Assets on Ethereum, but doesn't include things like clawback or a separation of management and creator.
 */
contract ReachToken is ERC20 {
  address private _creator;
  string private _url;
  string private _metadata;
  uint8 private _decimals;

  constructor (
    string memory name_,
    string memory symbol_,
    string memory url_,
    string memory metadata_,
    uint256 supply_,
    uint256 decimals_
  ) ERC20(name_, symbol_) {
    _creator = _msgSender();
    _mint(_creator, supply_);
    _url = url_;
    _metadata = metadata_;
    _decimals = uint8(decimals_);
  }

  function url() public view returns (string memory) { return _url; }

  function metadata() public view returns (string memory) { return _metadata; }

  function decimals() public view override returns (uint8) { return _decimals; }

  function burn(uint256 amount) public virtual returns (bool) {
    require(_msgSender() == _creator, "must be creator");
    _burn(_creator, amount);
    return true;
  }

  function destroy() public virtual {
    require(_msgSender() == _creator, "must be creator");
    require(totalSupply() == 0, "must be no supply");
    selfdestruct(payable(_creator));
  }
}

// Generated code includes meaning of numbers
error ReachError(uint256 msg);

contract Stdlib {
  function safeAdd(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x + y) >= x, "add overflow"); }
  function safeSub(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x - y) <= x, "sub wraparound"); }
  function safeMul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require(y == 0 || (z = x * y) / y == x, "mul overflow"); }

  function unsafeAdd(uint256 x, uint256 y) internal pure returns (uint256 z) {
    unchecked { z = x + y; } }
  function unsafeSub(uint256 x, uint256 y) internal pure returns (uint256 z) {
    unchecked { z = x - y; } }
  function unsafeMul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    unchecked { z = x * y; } }

  function safeSqrt(uint256 y) internal pure returns (uint256 z) {
    if (y > 3) {
      z = y;
      uint256 x = y / 2 + 1;
      while (x < z) {
        z = x;
        x = (y / x + x) / 2;
      }
    } else if (y != 0) {
      z = 1;
    }
  }

  function reachRequire(bool succ, uint256 errMsg) internal pure {
    if ( ! succ ) {
      revert ReachError(errMsg);
    }
  }

  function checkFunReturn(bool succ, bytes memory returnData, uint256 errMsg) internal pure returns (bytes memory) {
    if (succ) {
      return returnData;
    } else {
      if (returnData.length > 0) {
        assembly {
          let returnData_size := mload(returnData)
          revert(add(32, returnData), returnData_size)
        }
      } else {
        revert ReachError(errMsg);
      }
    }
  }

  function tokenAllowance(address payable token, address owner, address spender) internal returns (uint256 amt) {
    (bool ok, bytes memory ret) = token.call{value: uint256(0)}(abi.encodeWithSelector(IERC20.allowance.selector, owner, spender));
    checkFunReturn(ok, ret, 0 /*'token.allowance'*/);
    amt = abi.decode(ret, (uint256));
  }

  function tokenTransferFrom(address payable token, address sender, address recipient, uint256 amt) internal returns (bool res) {
    (bool ok, bytes memory ret) = token.call{value: uint256(0)}(abi.encodeWithSelector(IERC20.transferFrom.selector, sender, recipient, amt));
    checkFunReturn(ok, ret, 1 /*'token.transferFrom'*/);
    res = abi.decode(ret, (bool));
  }

  function tokenTransfer(address payable token, address recipient, uint256 amt) internal returns (bool res) {
    (bool ok, bytes memory ret) = token.call{value: uint256(0)}(abi.encodeWithSelector(IERC20.transfer.selector, recipient, amt));
    checkFunReturn(ok, ret, 2 /*'token.transfer'*/);
    res = abi.decode(ret, (bool));
  }
  function safeTokenTransfer(address payable token, address recipient, uint256 amt) internal {
    require(tokenTransfer(token, recipient, amt));
  }

  function reachTokenBurn(address payable token, uint256 amt) internal returns (bool res) {
    (bool ok, bytes memory ret) = token.call{value: uint256(0)}(abi.encodeWithSelector(ReachToken.burn.selector, amt));
    checkFunReturn(ok, ret, 3 /*'token.burn'*/);
    res = abi.decode(ret, (bool));
  }
  function safeReachTokenBurn(address payable token, uint256 amt) internal {
    require(reachTokenBurn(token, amt));
  }

  function reachTokenDestroy(address payable token) internal returns (bool res) {
    (bool ok, bytes memory ret) = token.call{value: uint256(0)}(abi.encodeWithSelector(ReachToken.destroy.selector));
    checkFunReturn(ok, ret, 4 /*'token.destroy'*/);
    res = true;
  }
  function safeReachTokenDestroy(address payable token) internal {
    require(reachTokenDestroy(token));
  }

  function readPayAmt(address sender, address payable token) internal returns (uint256 amt) {
    amt = tokenAllowance(token, sender, address(this));
    require(checkPayAmt(sender, token, amt));
  }

  function checkPayAmt(address sender, address payable token, uint256 amt) internal returns (bool) {
    return tokenTransferFrom(token, sender, address(this), amt);
  }

  function tokenApprove(address payable token, address spender, uint256 amt) internal returns (bool res) {
    (bool ok, bytes memory ret) = token.call{value: uint256(0)}(abi.encodeWithSelector(IERC20.approve.selector, spender, amt));
    checkFunReturn(ok, ret, 5 /*'token.approve'*/);
    res = abi.decode(ret, (bool));
  }

  function tokenBalanceOf(address payable token, address owner) internal returns (uint256 res) {
    (bool ok, bytes memory ret) = token.call{value: uint256(0) }(abi.encodeWithSelector(IERC20.balanceOf.selector, owner));
    checkFunReturn(ok, ret, 6 /*'token.balanceOf'*/);
    res = abi.decode(ret, (uint256));
  }
}

struct T0 {
  address payable _ctc;
  uint256 _nftId;
  uint256 _price;
  }
enum _enum_T1 {None, Some}
struct T1 {
  _enum_T1 which;
  bool _None;
  T0 _Some;
  }

struct T2 {
  uint256 _counter;
  address payable _owner;
  bool _paused;
  }
struct T3 {
  T0 v721;
  T2 v724;
  uint256 v725;
  }
struct T4 {
  T0 v721;
  }
struct T5 {
  T2 v724;
  uint256 v725;
  }
struct T6 {
  T4 svs;
  T5 msg;
  }
struct T7 {
  address payable _ZeroAddress;
  }
struct T8 {
  T7 v716;
  }
struct T9 {
  uint256 time;
  T8 msg;
  }
struct T10 {
  uint256 elem0;
  }
struct T11 {
  uint256 elem0;
  uint256 elem1;
  }
struct T12 {
  address payable elem0;
  uint256 elem1;
  uint256 elem2;
  }
enum _enum_T14 {buyListing0_93, changePrice0_93, delist0_93, list0_93, pause0_93, unpause0_93}
struct T14 {
  _enum_T14 which;
  T10 _buyListing0_93;
  T11 _changePrice0_93;
  T10 _delist0_93;
  T12 _list0_93;
  bool _pause0_93;
  bool _unpause0_93;
  }

struct T15 {
  uint256 elem0;
  address payable elem1;
  }
struct T16 {
  uint256 elem0;
  bool elem1;
  }
struct T17 {
  T14 v869;
  }
struct T18 {
  uint256 time;
  T17 msg;
  }

interface I0 {
  function ownerOf(uint256) external returns (address payable);}
interface I1 {
  function ownerOf(uint256) external returns (address payable);}
interface I2 {
  function safeTransferFrom(address payable, address payable, uint256) external returns (bool);}
interface I3 {
  function ownerOf(uint256) external returns (address payable);}
interface I4 {
  function ownerOf(uint256) external returns (address payable);}
interface I5 {
  function ownerOf(uint256) external returns (address payable);}

contract ReachContract is Stdlib {
  uint256 current_step;
  uint256 current_time;
    bytes current_svbs;
  uint256 creation_time;
  function _reachCreationTime() external view returns (uint256) { return creation_time; }
  function _reachCurrentTime() external view returns (uint256) { return current_time; }
  function _reachCurrentState() external view returns (uint256, bytes memory) { return (current_step, current_svbs); }
  mapping (uint256 => T1) map0;
  function __reachMap0Ref(uint256 addr)  internal view returns (T1 memory res) {
    if (map0[addr].which == _enum_T1.Some) {
      res = map0[addr];}
    else {
      res.which = _enum_T1.None;
      res._None = false;
      }}
  function _reachMap0Ref(uint256 addr)  external view returns (T1 memory res) {
    res = __reachMap0Ref(addr);}
  
  
  function owner()  external view returns (address payable) {
    if (current_step == uint256(3)) {
      (T3 memory vvs) = abi.decode(current_svbs, (T3));
      
      
      return (vvs.v724._owner);
      
      
      }
    reachRequire((false), uint256(7) /*'invalid view_i'*/);
    }
  
  
  function paused()  external view returns (bool) {
    if (current_step == uint256(3)) {
      (T3 memory vvs) = abi.decode(current_svbs, (T3));
      
      
      return (vvs.v724._paused);
      
      
      }
    reachRequire((false), uint256(8) /*'invalid view_i'*/);
    }
  
  struct _F3090 {
    uint256 v733;
    T0 v735;
    }
  function price(uint256 v3089)  external view returns (uint256) {
    if (current_step == uint256(3)) {
      (T3 memory vvs) = abi.decode(current_svbs, (T3));
      _F3090 memory _f;
      if ((__reachMap0Ref(v3089)).which == _enum_T1.None) {
        
        _f.v733 = uint256(0);
        
        }
      else {
        if ((__reachMap0Ref(v3089)).which == _enum_T1.Some) {
          _f.v735 = (__reachMap0Ref(v3089))._Some;
          _f.v733 = (_f.v735._price);
          
          }
        else {
          }}
      
      return _f.v733;
      
      
      }
    reachRequire((false), uint256(9) /*'invalid view_i'*/);
    }
  
  
  
  
  struct ApiRng {
    bool buyListing;
    bool changePrice;
    bool delist;
    bool list;
    bool pause;
    bool unpause;
    }
  event Bought(address payable v0, uint256 v1);
  event ChangedPrice(uint256 v0, uint256 v1);
  event Delisted(uint256 v0);
  event Listed(address payable v0, uint256 v1);
  event _reach_oe_v1220(T15 v0);
  event _reach_oe_v1235(bool v0);
  event _reach_oe_v1496(T15 v0);
  event _reach_oe_v1507(bool v0);
  event _reach_oe_v1768(T15 v0);
  event _reach_oe_v1780(bool v0);
  event _reach_oe_v2031(bool v0);
  event _reach_oe_v2283(bool v0);
  event _reach_oe_v911(T15 v0);
  event _reach_oe_v928(T15 v0);
  event _reach_oe_v943(T16 v0);
  event _reach_oe_v958(bool v0);
  
  
  event _reach_e0(address _who, T9 _a);
  struct _F0 {
    T0 v721;
    T2 v722;
    }
  constructor(T9 memory _a) payable {
    current_step = 0x0;
    creation_time = uint256(block.number);
    _F0 memory _f;
    
    emit _reach_e0(msg.sender, _a);
    reachRequire((msg.value == uint256(0)), uint256(10) /*'(./marketplace.rsh:121:12:dot,[],"verify network token pay amount")'*/);
    _f.v721._ctc = (_a.msg.v716._ZeroAddress);
    _f.v721._nftId = uint256(0);
    _f.v721._price = uint256(0);
    
    _f.v722._counter = uint256(0);
    _f.v722._owner = payable(msg.sender);
    _f.v722._paused = false;
    
    T6 memory la;
    la.svs.v721 = _f.v721;
    la.msg.v724 = _f.v722;
    la.msg.v725 = uint256(block.number);
    l1(la);
    
    
    }
  
  
  function l1(T6 memory _a)  internal {
    
    
    T3 memory nsvs;
    nsvs.v721 = _a.svs.v721;
    nsvs.v724 = _a.msg.v724;
    nsvs.v725 = _a.msg.v725;
    current_step = uint256(3);
    current_time = uint256(block.number);
    current_svbs = abi.encode(nsvs);
    
    
    }
  
  event _reach_e2(address _who, T18 _a);
  struct _F2 {
    T10 v872;
    T1 v880;
    bool v881;
    T0 v886;
    bool v900;
    T15 v911;
    T15 v912;
    T15 v928;
    T15 v929;
    T16 v943;
    T16 v944;
    T11 v1109;
    T1 v1207;
    bool v1208;
    T0 v1215;
    T15 v1220;
    T15 v1221;
    T0 v1234;
    T10 v1346;
    T1 v1484;
    bool v1485;
    T0 v1491;
    T15 v1496;
    T15 v1497;
    T12 v1583;
    uint256 v1758;
    bool v1760;
    T15 v1768;
    T15 v1769;
    T0 v1779;
    T2 v2040;
    T2 v2292;
    uint256 v3093;
    uint256 v3097;
    uint256 v3101;
    uint256 v3105;
    uint256 v3109;
    uint256 v3113;
    }
  function _reach_m2(T18 calldata _a) external payable {
    ApiRng memory _r;
    _reach_m2(_a, _r);
    }
  function _reach_m2(T18 memory _a, ApiRng memory _apiRet)  internal  {
    reachRequire((current_step == uint256(3)), uint256(46) /*'state step check at ./marketplace.rsh:131:31:dot'*/);
    reachRequire(((_a.time == uint256(0)) || (current_time == _a.time)), uint256(47) /*'state time check at ./marketplace.rsh:131:31:dot'*/);
    current_step = 0x0;
    (T3 memory _svs) = abi.decode(current_svbs, (T3));
    _F2 memory _f;
    
    emit _reach_e2(msg.sender, _a);
    if (_a.msg.v869.which == _enum_T14.buyListing0_93) {
      _f.v872 = _a.msg.v869._buyListing0_93;
      reachRequire((((_svs.v724._paused) ? false : true)), uint256(11) /*'(./marketplace.rsh:244:14:application,[at ./marketplace.rsh:243:19:application call to [unknown function] (defined at: ./marketplace.rsh:243:19:function exp),at ./marketplace.rsh:131:31:application call to [unknown function] (defined at: ./marketplace.rsh:243:19:function exp),at ./marketplace.rsh:131:31:application call to [unknown function] (defined at: ./marketplace.rsh:131:31:function exp)],Just "contract is paused")'*/);
      _f.v880 = __reachMap0Ref((_f.v872.elem0));
      if (_f.v880.which == _enum_T1.None) {
        
        _f.v881 = false;
        
        }
      else {
        if (_f.v880.which == _enum_T1.Some) {
          
          _f.v881 = true;
          
          }
        else {
          }}
      reachRequire((_f.v881), uint256(12) /*'(./marketplace.rsh:245:14:application,[at ./marketplace.rsh:243:19:application call to [unknown function] (defined at: ./marketplace.rsh:243:19:function exp),at ./marketplace.rsh:131:31:application call to [unknown function] (defined at: ./marketplace.rsh:243:19:function exp),at ./marketplace.rsh:131:31:application call to [unknown function] (defined at: ./marketplace.rsh:131:31:function exp)],Just "not listed")'*/);
      _f.v886 = (_f.v880.which == _enum_T1.Some ? _f.v880._Some : _svs.v721);
      reachRequire((msg.value == (_f.v886._price)), uint256(13) /*'(./marketplace.rsh:131:31:dot,[],"verify network token pay amount")'*/);
      if (_f.v880.which == _enum_T1.None) {
        
        _f.v900 = false;
        
        }
      else {
        if (_f.v880.which == _enum_T1.Some) {
          
          _f.v900 = true;
          
          }
        else {
          }}
      reachRequire((_f.v900), uint256(14) /*'(./marketplace.rsh:245:14:application,[at ./marketplace.rsh:248:38:application call to [unknown function] (defined at: ./marketplace.rsh:248:38:function exp)],Just "not listed")'*/);
      _f.v3093 = address(this).balance - uint256(0);
      bytes memory v3094 = abi.encodeWithSelector(I0.ownerOf.selector, (_f.v886._nftId));
      (bool v3091, bytes memory v3092) = (_f.v886._ctc).call{value: uint256(0)}(v3094);
      checkFunReturn(v3091, v3092, uint256(15) /*'(./marketplace.rsh:252:42:application,[at ./marketplace.rsh:248:38:application call to [unknown function] (defined at: ./marketplace.rsh:248:38:function exp)],"remote ownerOf failed")'*/);
      _f.v911.elem0 = address(this).balance - _f.v3093;
      _f.v911.elem1 = abi.decode(v3092, (address));
      
      _f.v912 = _f.v911;
      emit _reach_oe_v911( _f.v911);
      
      
      reachRequire(((uint256(0) == (_f.v912.elem0))), uint256(16) /*'(./marketplace.rsh:252:42:application,[at ./marketplace.rsh:248:38:application call to [unknown function] (defined at: ./marketplace.rsh:248:38:function exp)],Just "remote bill check")'*/);
      _f.v3097 = address(this).balance - uint256(0);
      bytes memory v3098 = abi.encodeWithSelector(I1.ownerOf.selector, (_f.v886._nftId));
      (bool v3095, bytes memory v3096) = (_f.v886._ctc).call{value: uint256(0)}(v3098);
      checkFunReturn(v3095, v3096, uint256(17) /*'(./marketplace.rsh:137:51:application,[at ./marketplace.rsh:253:34:application call to "getOwner" (defined at: ./marketplace.rsh:135:29:function exp),at ./marketplace.rsh:248:38:application call to [unknown function] (defined at: ./marketplace.rsh:248:38:function exp)],"remote ownerOf failed")'*/);
      _f.v928.elem0 = address(this).balance - _f.v3097;
      _f.v928.elem1 = abi.decode(v3096, (address));
      
      _f.v929 = _f.v928;
      emit _reach_oe_v928( _f.v928);
      
      
      reachRequire(((uint256(0) == (_f.v929.elem0))), uint256(18) /*'(./marketplace.rsh:137:51:application,[at ./marketplace.rsh:253:34:application call to "getOwner" (defined at: ./marketplace.rsh:135:29:function exp),at ./marketplace.rsh:248:38:application call to [unknown function] (defined at: ./marketplace.rsh:248:38:function exp)],Just "remote bill check")'*/);
      reachRequire((((payable(msg.sender) == (_f.v929.elem1)) ? false : true)), uint256(19) /*'(./marketplace.rsh:253:17:application,[at ./marketplace.rsh:248:38:application call to [unknown function] (defined at: ./marketplace.rsh:248:38:function exp)],Just "owner of asset")'*/);
      _f.v3101 = address(this).balance - uint256(0);
      bytes memory v3102 = abi.encodeWithSelector(I2.safeTransferFrom.selector, (_f.v912.elem1), payable(msg.sender), (_f.v886._nftId));
      (bool v3099, bytes memory v3100) = (_f.v886._ctc).call{value: uint256(0)}(v3102);
      checkFunReturn(v3099, v3100, uint256(20) /*'(./marketplace.rsh:256:37:application,[at ./marketplace.rsh:248:38:application call to [unknown function] (defined at: ./marketplace.rsh:248:38:function exp)],"remote safeTransferFrom failed")'*/);
      _f.v943.elem0 = address(this).balance - _f.v3101;
      
      _f.v944 = _f.v943;
      emit _reach_oe_v943( _f.v943);
      
      
      reachRequire(((uint256(0) == (_f.v944.elem0))), uint256(21) /*'(./marketplace.rsh:256:37:application,[at ./marketplace.rsh:248:38:application call to [unknown function] (defined at: ./marketplace.rsh:248:38:function exp)],Just "remote bill check")'*/);
      (_f.v912.elem1).transfer((_f.v886._price));
      emit Bought( payable(msg.sender),  (_f.v872.elem0));
      
      
      emit _reach_oe_v958( (false));
      _apiRet.buyListing = (false);
      
      T6 memory la;
      la.svs.v721 = _svs.v721;
      la.msg.v724 = _svs.v724;
      la.msg.v725 = uint256(block.number);
      l1(la);
      
      }
    else {
      if (_a.msg.v869.which == _enum_T14.changePrice0_93) {
        _f.v1109 = _a.msg.v869._changePrice0_93;
        reachRequire((msg.value == uint256(0)), uint256(22) /*'(./marketplace.rsh:131:31:dot,[],"verify network token pay amount")'*/);
        reachRequire((((_svs.v724._paused) ? false : true)), uint256(23) /*'(./marketplace.rsh:205:14:application,[at ./marketplace.rsh:208:22:application call to [unknown function] (defined at: ./marketplace.rsh:208:22:function exp)],Just "contract is paused")'*/);
        _f.v1207 = __reachMap0Ref((_f.v1109.elem0));
        if (_f.v1207.which == _enum_T1.None) {
          
          _f.v1208 = false;
          
          }
        else {
          if (_f.v1207.which == _enum_T1.Some) {
            
            _f.v1208 = true;
            
            }
          else {
            }}
        reachRequire((_f.v1208), uint256(24) /*'(./marketplace.rsh:206:14:application,[at ./marketplace.rsh:208:22:application call to [unknown function] (defined at: ./marketplace.rsh:208:22:function exp)],Just "not listed")'*/);
        _f.v1215 = (_f.v1207.which == _enum_T1.Some ? _f.v1207._Some : _svs.v721);
        _f.v3105 = address(this).balance - uint256(0);
        bytes memory v3106 = abi.encodeWithSelector(I3.ownerOf.selector, (_f.v1215._nftId));
        (bool v3103, bytes memory v3104) = (_f.v1215._ctc).call{value: uint256(0)}(v3106);
        checkFunReturn(v3103, v3104, uint256(25) /*'(./marketplace.rsh:211:60:application,[at ./marketplace.rsh:208:22:application call to [unknown function] (defined at: ./marketplace.rsh:208:22:function exp)],"remote ownerOf failed")'*/);
        _f.v1220.elem0 = address(this).balance - _f.v3105;
        _f.v1220.elem1 = abi.decode(v3104, (address));
        
        _f.v1221 = _f.v1220;
        emit _reach_oe_v1220( _f.v1220);
        
        
        reachRequire(((uint256(0) == (_f.v1221.elem0))), uint256(26) /*'(./marketplace.rsh:211:60:application,[at ./marketplace.rsh:208:22:application call to [unknown function] (defined at: ./marketplace.rsh:208:22:function exp)],Just "remote bill check")'*/);
        reachRequire(((payable(msg.sender) == (_f.v1221.elem1))), uint256(27) /*'(./marketplace.rsh:212:17:application,[at ./marketplace.rsh:208:22:application call to [unknown function] (defined at: ./marketplace.rsh:208:22:function exp)],Just "not owner of asset")'*/);
        _f.v1234._ctc = (_f.v1215._ctc);
        _f.v1234._nftId = (_f.v1215._nftId);
        _f.v1234._price = (_f.v1109.elem1);
        
        map0[(_f.v1109.elem0)].which = _enum_T1.Some;
        map0[(_f.v1109.elem0)]._Some = _f.v1234;
        
        emit ChangedPrice( (_f.v1109.elem0),  (_f.v1109.elem1));
        
        
        emit _reach_oe_v1235( (false));
        _apiRet.changePrice = (false);
        
        T6 memory la;
        la.svs.v721 = _svs.v721;
        la.msg.v724 = _svs.v724;
        la.msg.v725 = uint256(block.number);
        l1(la);
        
        }
      else {
        if (_a.msg.v869.which == _enum_T14.delist0_93) {
          _f.v1346 = _a.msg.v869._delist0_93;
          reachRequire((msg.value == uint256(0)), uint256(28) /*'(./marketplace.rsh:131:31:dot,[],"verify network token pay amount")'*/);
          reachRequire((((_svs.v724._paused) ? false : true)), uint256(29) /*'(./marketplace.rsh:226:14:application,[at ./marketplace.rsh:229:22:application call to [unknown function] (defined at: ./marketplace.rsh:229:22:function exp)],Just "contract is paused")'*/);
          _f.v1484 = __reachMap0Ref((_f.v1346.elem0));
          if (_f.v1484.which == _enum_T1.None) {
            
            _f.v1485 = false;
            
            }
          else {
            if (_f.v1484.which == _enum_T1.Some) {
              
              _f.v1485 = true;
              
              }
            else {
              }}
          reachRequire((_f.v1485), uint256(30) /*'(./marketplace.rsh:227:14:application,[at ./marketplace.rsh:229:22:application call to [unknown function] (defined at: ./marketplace.rsh:229:22:function exp)],Just "not listed")'*/);
          _f.v1491 = (_f.v1484.which == _enum_T1.Some ? _f.v1484._Some : _svs.v721);
          _f.v3109 = address(this).balance - uint256(0);
          bytes memory v3110 = abi.encodeWithSelector(I4.ownerOf.selector, (_f.v1491._nftId));
          (bool v3107, bytes memory v3108) = (_f.v1491._ctc).call{value: uint256(0)}(v3110);
          checkFunReturn(v3107, v3108, uint256(31) /*'(./marketplace.rsh:137:51:application,[at ./marketplace.rsh:230:34:application call to "getOwner" (defined at: ./marketplace.rsh:135:29:function exp),at ./marketplace.rsh:229:22:application call to [unknown function] (defined at: ./marketplace.rsh:229:22:function exp)],"remote ownerOf failed")'*/);
          _f.v1496.elem0 = address(this).balance - _f.v3109;
          _f.v1496.elem1 = abi.decode(v3108, (address));
          
          _f.v1497 = _f.v1496;
          emit _reach_oe_v1496( _f.v1496);
          
          
          reachRequire(((uint256(0) == (_f.v1497.elem0))), uint256(32) /*'(./marketplace.rsh:137:51:application,[at ./marketplace.rsh:230:34:application call to "getOwner" (defined at: ./marketplace.rsh:135:29:function exp),at ./marketplace.rsh:229:22:application call to [unknown function] (defined at: ./marketplace.rsh:229:22:function exp)],Just "remote bill check")'*/);
          reachRequire(((payable(msg.sender) == (_f.v1497.elem1))), uint256(33) /*'(./marketplace.rsh:230:17:application,[at ./marketplace.rsh:229:22:application call to [unknown function] (defined at: ./marketplace.rsh:229:22:function exp)],Just "not owner of asset")'*/);
          delete map0[(_f.v1346.elem0)];
          emit Delisted( (_f.v1346.elem0));
          
          
          emit _reach_oe_v1507( (false));
          _apiRet.delist = (false);
          
          T6 memory la;
          la.svs.v721 = _svs.v721;
          la.msg.v724 = _svs.v724;
          la.msg.v725 = uint256(block.number);
          l1(la);
          
          }
        else {
          if (_a.msg.v869.which == _enum_T14.list0_93) {
            _f.v1583 = _a.msg.v869._list0_93;
            reachRequire((msg.value == uint256(0)), uint256(34) /*'(./marketplace.rsh:131:31:dot,[],"verify network token pay amount")'*/);
            reachRequire((((_svs.v724._paused) ? false : true)), uint256(35) /*'(./marketplace.rsh:184:14:application,[at ./marketplace.rsh:189:22:application call to [unknown function] (defined at: ./marketplace.rsh:189:22:function exp)],Just "contract is paused")'*/);
            _f.v1758 = uint256(keccak256(abi.encode((_f.v1583.elem0), (_f.v1583.elem1), _svs.v725)));
            if ((__reachMap0Ref(_f.v1758)).which == _enum_T1.None) {
              
              _f.v1760 = true;
              
              }
            else {
              if ((__reachMap0Ref(_f.v1758)).which == _enum_T1.Some) {
                
                _f.v1760 = false;
                
                }
              else {
                }}
            reachRequire((_f.v1760), uint256(36) /*'(./marketplace.rsh:187:14:application,[at ./marketplace.rsh:189:22:application call to [unknown function] (defined at: ./marketplace.rsh:189:22:function exp)],Just "already listed")'*/);
            _f.v3113 = address(this).balance - uint256(0);
            bytes memory v3114 = abi.encodeWithSelector(I5.ownerOf.selector, (_f.v1583.elem1));
            (bool v3111, bytes memory v3112) = (_f.v1583.elem0).call{value: uint256(0)}(v3114);
            checkFunReturn(v3111, v3112, uint256(37) /*'(./marketplace.rsh:190:52:application,[at ./marketplace.rsh:189:22:application call to [unknown function] (defined at: ./marketplace.rsh:189:22:function exp)],"remote ownerOf failed")'*/);
            _f.v1768.elem0 = address(this).balance - _f.v3113;
            _f.v1768.elem1 = abi.decode(v3112, (address));
            
            _f.v1769 = _f.v1768;
            emit _reach_oe_v1768( _f.v1768);
            
            
            reachRequire(((uint256(0) == (_f.v1769.elem0))), uint256(38) /*'(./marketplace.rsh:190:52:application,[at ./marketplace.rsh:189:22:application call to [unknown function] (defined at: ./marketplace.rsh:189:22:function exp)],Just "remote bill check")'*/);
            reachRequire(((payable(msg.sender) == (_f.v1769.elem1))), uint256(39) /*'(./marketplace.rsh:191:16:application,[at ./marketplace.rsh:189:22:application call to [unknown function] (defined at: ./marketplace.rsh:189:22:function exp)],Just "not owner of asset")'*/);
            _f.v1779._ctc = (_f.v1583.elem0);
            _f.v1779._nftId = (_f.v1583.elem1);
            _f.v1779._price = (_f.v1583.elem2);
            
            map0[_f.v1758].which = _enum_T1.Some;
            map0[_f.v1758]._Some = _f.v1779;
            
            emit Listed( payable(msg.sender),  _f.v1758);
            
            
            emit _reach_oe_v1780( (false));
            _apiRet.list = (false);
            
            T6 memory la;
            la.svs.v721 = _svs.v721;
            la.msg.v724 = _svs.v724;
            la.msg.v725 = uint256(block.number);
            l1(la);
            
            }
          else {
            if (_a.msg.v869.which == _enum_T14.pause0_93) {
              
              reachRequire((msg.value == uint256(0)), uint256(40) /*'(./marketplace.rsh:131:31:dot,[],"verify network token pay amount")'*/);
              reachRequire((((_svs.v724._owner) == payable(msg.sender))), uint256(41) /*'(./marketplace.rsh:152:14:application,[at ./marketplace.rsh:155:22:application call to [unknown function] (defined at: ./marketplace.rsh:155:22:function exp)],Just "not owner")'*/);
              reachRequire((((_svs.v724._paused) ? false : true)), uint256(42) /*'(./marketplace.rsh:153:14:application,[at ./marketplace.rsh:155:22:application call to [unknown function] (defined at: ./marketplace.rsh:155:22:function exp)],Just "already paused")'*/);
              emit _reach_oe_v2031( (false));
              _apiRet.pause = (false);
              
              _f.v2040._counter = (_svs.v724._counter);
              _f.v2040._owner = (_svs.v724._owner);
              _f.v2040._paused = true;
              
              T6 memory la;
              la.svs.v721 = _svs.v721;
              la.msg.v724 = _f.v2040;
              la.msg.v725 = uint256(block.number);
              l1(la);
              
              }
            else {
              if (_a.msg.v869.which == _enum_T14.unpause0_93) {
                
                reachRequire((msg.value == uint256(0)), uint256(43) /*'(./marketplace.rsh:131:31:dot,[],"verify network token pay amount")'*/);
                reachRequire((((_svs.v724._owner) == payable(msg.sender))), uint256(44) /*'(./marketplace.rsh:168:14:application,[at ./marketplace.rsh:171:22:application call to [unknown function] (defined at: ./marketplace.rsh:171:22:function exp)],Just "not owner")'*/);
                reachRequire(((_svs.v724._paused)), uint256(45) /*'(./marketplace.rsh:169:14:application,[at ./marketplace.rsh:171:22:application call to [unknown function] (defined at: ./marketplace.rsh:171:22:function exp)],Just "not paused")'*/);
                emit _reach_oe_v2283( (false));
                _apiRet.unpause = (false);
                
                _f.v2292._counter = (_svs.v724._counter);
                _f.v2292._owner = (_svs.v724._owner);
                _f.v2292._paused = false;
                
                T6 memory la;
                la.svs.v721 = _svs.v721;
                la.msg.v724 = _f.v2292;
                la.msg.v725 = uint256(block.number);
                l1(la);
                
                }
              else {
                }}}}}}
    
    }
  
  
  function buyListing(uint256 _a0)  external payable returns (bool ) {
    ApiRng memory _r;
    T18 memory _t;
    T14 memory _vt;
    _vt._buyListing0_93 = T10(_a0);
    _vt.which = _enum_T14.buyListing0_93;
    _t.msg = T17(_vt);
    _reach_m2(_t, _r);
    return _r.buyListing;
    }
  
  function changePrice(uint256 _a0, uint256 _a1)  external payable returns (bool ) {
    ApiRng memory _r;
    T18 memory _t;
    T14 memory _vt;
    _vt._changePrice0_93 = T11(_a0, _a1);
    _vt.which = _enum_T14.changePrice0_93;
    _t.msg = T17(_vt);
    _reach_m2(_t, _r);
    return _r.changePrice;
    }
  
  function delist(uint256 _a0)  external payable returns (bool ) {
    ApiRng memory _r;
    T18 memory _t;
    T14 memory _vt;
    _vt._delist0_93 = T10(_a0);
    _vt.which = _enum_T14.delist0_93;
    _t.msg = T17(_vt);
    _reach_m2(_t, _r);
    return _r.delist;
    }
  
  function list(address payable _a0, uint256 _a1, uint256 _a2)  external payable returns (bool ) {
    ApiRng memory _r;
    T18 memory _t;
    T14 memory _vt;
    _vt._list0_93 = T12(_a0, _a1, _a2);
    _vt.which = _enum_T14.list0_93;
    _t.msg = T17(_vt);
    _reach_m2(_t, _r);
    return _r.list;
    }
  
  function pause()  external payable returns (bool ) {
    ApiRng memory _r;
    T18 memory _t;
    T14 memory _vt;
    _vt._pause0_93 = false;
    _vt.which = _enum_T14.pause0_93;
    _t.msg = T17(_vt);
    _reach_m2(_t, _r);
    return _r.pause;
    }
  
  function unpause()  external payable returns (bool ) {
    ApiRng memory _r;
    T18 memory _t;
    T14 memory _vt;
    _vt._unpause0_93 = false;
    _vt.which = _enum_T14.unpause0_93;
    _t.msg = T17(_vt);
    _reach_m2(_t, _r);
    return _r.unpause;
    }
  
  
  receive () external payable {}
  fallback () external payable {}
  
  }
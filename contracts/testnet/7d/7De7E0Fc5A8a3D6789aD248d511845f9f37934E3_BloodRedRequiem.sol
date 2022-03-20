/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-19
*/

// File: contracts/interfaces/IGovernanceLock.sol


pragma solidity ^0.8.13;

interface IGovernanceLock {
  struct LockedBalance {
    uint256 amount;
    uint256 end;
    uint256 minted;
    uint256 votingPower;
  }

  function get_locks(address _addr)
    external
    view
    returns (LockedBalance[] memory _balances);

  function get_minted_for_locks(address _addr)
    external
    view
    returns (uint256[] memory _minted);

  function get_minted_for_lock(address _addr, uint256 _end)
    external
    view
    returns (uint256 _minted);

  function locked_of(address _addr, uint256 _end)
    external
    view
    returns (uint256);

  function voting_power_unlock_time(uint256 _value, uint256 _unlock_time)
    external
    view
    returns (uint256);

  function voting_power_locked_days(uint256 _value, uint256 _days)
    external
    view
    returns (uint256);

  function create_lock(uint256 _value, uint256 _days) external;

  function increase_position(uint256 _value, uint256 _end) external;

  function increase_time_to_maturity(
    uint256 _amount,
    uint256 _end,
    uint256 _newEnd
  ) external;

  function withdraw(uint256 _end, uint256 _amount) external;

  function withdrawAll() external;
}

// File: contracts/libraries/EnumerableSet.sol


// OpenZeppelin Contracts v4.4.0 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}
// File: contracts/interfaces/IOwnable.sol


pragma solidity 0.8.13;

interface IOwnable {
  function owner() external view returns (address);

  function renounceOwnership() external;
  
  function transferOwnership( address newOwner_ ) external;
}
// File: contracts/libraries/Ownable.sol


pragma solidity 0.8.13;


contract Ownable is IOwnable {
    
  address internal _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () {
    _owner = msg.sender;
    emit OwnershipTransferred( address(0), _owner );
  }

  function owner() public view override returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require( _owner == msg.sender, "Ownable: caller is not the owner" );
    _;
  }

  function renounceOwnership() public virtual override onlyOwner() {
    emit OwnershipTransferred( _owner, address(0) );
    _owner = address(0);
  }

  function transferOwnership( address newOwner_ ) public virtual override onlyOwner() {
    require( newOwner_ != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred( _owner, newOwner_ );
    _owner = newOwner_;
  }
}
// File: contracts/libraries/Context.sol



pragma solidity ^0.8.13;

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
// File: contracts/interfaces/ERC20/IERC20.sol


pragma solidity 0.8.13;

interface IERC20 {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}
// File: contracts/libraries/SafeERC20.sol



// Based on the ReentrancyGuard library from OpenZeppelin Contracts, altered to reduce gas costs.
// The `safeTransfer` and `safeTransferFrom` functions assume that `token` is a contract (an account with code), and
// work differently from the OpenZeppelin version if it is not.

pragma solidity ^0.8.13;


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
  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(
      address(token),
      abi.encodeWithSelector(token.transfer.selector, to, value)
    );
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(
      address(token),
      abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
    );
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender) + value;
    _callOptionalReturn(
      address(token),
      abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
    );
  }

  /**
   * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
   * on the return value: the return value is optional (but if data is returned, it must not be false).
   *
   * WARNING: `token` is assumed to be a contract: calls to EOAs will *not* revert.
   */
  function _callOptionalReturn(address token, bytes memory data) private {
    // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
    // we're implementing it ourselves.
    (bool success, bytes memory returndata) = token.call(data);

    // If the low-level call didn't succeed we return whatever was returned from it.
    assembly {
      if eq(success, 0) {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }

    // Finally we check the returndata size is either zero or true - note that this check will always pass for EOAs
    require(
      returndata.length == 0 || abi.decode(returndata, (bool)),
      "SAFE_ERC20_CALL_FAILED"
    );
  }
}

// File: contracts/interfaces/ERC20/IERC20Metadata.sol



pragma solidity ^0.8.13;


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
// File: contracts/libraries/ERC20.sol



pragma solidity ^0.8.13;




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

    uint256 internal _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
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
    function decimals() public view virtual override(IERC20, IERC20Metadata) returns (uint8) {
        return _decimals;
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
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
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
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
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
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
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

// File: contracts/libraries/ERC20Burnable.sol



pragma solidity ^0.8.13;



/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
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
    uint256 currentAllowance = allowance(account, _msgSender());
    require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
    unchecked {
      _approve(account, _msgSender(), currentAllowance - amount);
    }
    _burn(account, amount);
  }
}

// File: contracts/BloodRedRequiem.sol



pragma solidity ^0.8.13;






using SafeERC20 for IERC20 global;
using EnumerableSet for EnumerableSet.UintSet global;

contract BloodRedRequiem is ERC20Burnable, IGovernanceLock, Ownable {
  // flags
  uint256 private _unlocked;

  // constants
  uint256 public constant REF_DATE = 1640991600; // 20220101 00:00
  uint256 public constant MINDAYS = 1;
  uint256 public constant MAXDAYS = 3 * 365;

  uint256 public constant MAXTIME = MAXDAYS * 1 days; // 3 years
  uint256 public constant MINTIME = 60 * 60; // 1 hour
  uint256 public constant MAX_WITHDRAWAL_PENALTY = 50000; // 50%
  uint256 public constant PRECISION = 100000; // 5 decimals

  address public lockedToken;
  address public penaltyCollector;
  uint256 public minLockedAmount;
  uint256 public earlyWithdrawPenaltyRate;

  mapping(address => mapping(uint256 => uint256)) public mintedForLock;

  // the dictionary that contains the locked positions for each endtime
  mapping(address => mapping(uint256 => uint256)) public lockedPosition;

  // 18-decimal multiplier mapped from user to lockEnd
  mapping(address => mapping(uint256 => uint256)) public multipliers;

  // tracks the maturities for locks per user
  mapping(address => EnumerableSet.UintSet) private lockEnds;
  /* ========== MODIFIERS ========== */

  modifier lock() {
    require(_unlocked == 1, "LOCKED");
    _unlocked = 0;
    _;
    _unlocked = 1;
  }

  constructor(
    string memory _name,
    string memory _symbol,
    address _lockedToken,
    uint256 _minLockedAmount
  ) ERC20(_name, _symbol, 18) {
    lockedToken = _lockedToken;
    minLockedAmount = _minLockedAmount;
    earlyWithdrawPenaltyRate = 30000; // 30%
    _unlocked = 1;
  }

  /* ========== PUBLIC FUNCTIONS ========== */

  function locked_of(address _addr, uint256 _end)
    external
    view
    override
    returns (uint256)
  {
    return lockedPosition[_addr][_end];
  }

  /**
   * Gets lock data for user
   * @param _addr user to get data of
   */
  function get_locks(address _addr)
    external
    view
    override
    returns (LockedBalance[] memory _balances)
  {
    uint256 length = lockEnds[_addr].length();
    _balances = new LockedBalance[](length);
    for (uint256 i = 0; i < length; i++) {
      uint256 _end = lockEnds[_addr].at(i);
      _balances[i] = LockedBalance(
        lockedPosition[_addr][_end],
        _end,
        mintedForLock[_addr][_end],
        (lockedPosition[_addr][_end] * multipliers[_addr][_end]) / 1e18
      );
    }
  }

  // returns minted voting power for lock
  function get_minted_for_locks(address _addr)
    external
    view
    override
    returns (uint256[] memory _minted)
  {
    uint256 length = lockEnds[_addr].length();
    _minted = new uint256[](length);
    for (uint256 i = 0; i < length; i++) {
      uint256 _end = lockEnds[_addr].at(i);
      _minted[i] = mintedForLock[_addr][_end];
    }
  }

  // returns minted voting power for lock
  function get_minted_for_lock(address _addr, uint256 _end)
    external
    view
    override
    returns (uint256 _minted)
  {
    _minted = mintedForLock[_addr][_end];
  }

  function voting_power_unlock_time(uint256 _value, uint256 _unlock_time)
    public
    view
    override
    returns (uint256)
  {
    uint256 _now = block.timestamp;
    if (_unlock_time <= _now) return 0;
    uint256 _lockedSeconds = _unlock_time - _now;
    if (_lockedSeconds >= MAXTIME) {
      return _value;
    }
    return (_value * _lockedSeconds) / MAXTIME;
  }

  function get_share(address _addr) public view returns (uint256 _vote) {
    uint256 _length = lockEnds[_addr].length();
    _vote = 0;
    for (uint256 i = 0; i < _length; i++) {
      uint256 _end = lockEnds[_addr].at(i);
      _vote += lockedPosition[_addr][_end] * multipliers[_addr][_end];
    }

    _vote /= 1e18;
  }

  function get_voting_power(address _addr, uint256 _amount)
    public
    view
    returns (uint256 _votingPower)
  {
    uint256 _length = lockEnds[_addr].length();
    uint256 _locked = 0;
    _votingPower = 0;
    for (uint256 i = 0; i < _length; i++) {
      uint256 _end = lockEnds[_addr].at(i);
      _votingPower += lockedPosition[_addr][_end] * multipliers[_addr][_end];
      _locked += lockedPosition[_addr][_end];
    }

    // we pick the minimum of amount and locked, otherwise
    _votingPower =
      (_votingPower * _amount > _locked ? _locked : _amount) /
      _locked /
      1e18;
  }

  function get_amount_minted(uint256 _value, uint256 _unlock_time)
    public
    pure
    returns (uint256)
  {
    return (_value * (_unlock_time - REF_DATE)) / MAXTIME;
  }

  function voting_power_locked_days(uint256 _value, uint256 _days)
    public
    pure
    override
    returns (uint256)
  {
    if (_days >= MAXDAYS) {
      return _value;
    }
    return (_value * _days) / MAXDAYS;
  }

  /**
   * Create new lock with defined maturity time
   * - That shall help standardizing these positions
   * @param _value amount to lock
   * @param _end expiry timestamp
   */
  function create_lock(uint256 _value, uint256 _end) external {
    uint256 _now = block.timestamp;
    uint256 _duration = _end - _now;
    require(_value >= minLockedAmount, "less than min amount");
    require(_duration >= MINTIME, "Shorter than MINTIME");
    require(_duration <= MAXTIME, "Longer than MAXTIME");
    _create_lock(_msgSender(), _value, _end);
  }

  /**
   * Increases the maturity of _amount from _end to _newEnd
   * @param _amount amount to change the maturity for
   * @param _end maturity
   * @param _newEnd new maturity
   */
  function increase_time_to_maturity(
    uint256 _amount,
    uint256 _end,
    uint256 _newEnd
  ) external {
    uint256 _now = block.timestamp;
    uint256 _duration = _newEnd - _now;
    require(_duration >= MINTIME, "Voting lock can MINTIME min");
    require(_duration <= MAXTIME, "Voting lock can MAXTIME max");
    _extend_maturity(_msgSender(), _amount, _end, _newEnd);
  }

  /**
   * Function to increase position for given _end
   * @param _value increase position for position in _end by value
   * @param _end maturity of the position to increase
   */
  function increase_position(uint256 _value, uint256 _end) external {
    require(_value >= minLockedAmount, "less than min amount");
    _increase_position(_msgSender(), _value, _end);
  }

  // withdraws from all locks whenever possible
  function withdrawAll() external override lock {
    uint256 _endsLength = lockEnds[_msgSender()].length();
    for (uint256 i = 0; i < _endsLength; i++) {
      uint256 _end = lockEnds[_msgSender()].at(i);
      uint256 _locked = lockedPosition[_msgSender()][_end];
      uint256 _now = block.timestamp;
      if (_locked > 0 && _now >= _end) {
        // delete position and multiplier
        delete lockedPosition[_msgSender()][_end];
        delete multipliers[_msgSender()][_end];

        // burn minted amount
        _burn(_msgSender(), mintedForLock[_msgSender()][_end]);

        // delete minted entry
        delete mintedForLock[_msgSender()][_end];
        IERC20(lockedToken).safeTransfer(_msgSender(), _locked);

        emit Withdraw(_msgSender(), _locked, _now);
      }
    }
  }

  function withdraw(uint256 _end, uint256 _amount) external override lock {
    uint256 _locked = lockedPosition[_msgSender()][_end];
    uint256 _now = block.timestamp;
    require(_locked > 0, "Nothing to withdraw");
    require(_now >= _end, "The lock didn't expire");
    require(_locked >= _amount, "Insufficient locked");
    if (_amount >= _locked) {
      delete lockedPosition[_msgSender()][_end];
      delete multipliers[_msgSender()][_end];
      _burn(_msgSender(), mintedForLock[_msgSender()][_end]);
      delete mintedForLock[_msgSender()][_end];
      lockEnds[_msgSender()].remove(_end);
    } else {
      lockedPosition[_msgSender()][_end] -= _amount;
      _burn(_msgSender(), mintedForLock[_msgSender()][_end]);
      mintedForLock[_msgSender()][_end] -= get_amount_minted(_amount, _end);
    }

    IERC20(lockedToken).safeTransfer(_msgSender(), _amount);

    emit Withdraw(_msgSender(), _amount, _now);
  }

  // This will charge PENALTY if lock is not expired yet
  function emergencyWithdraw(uint256 _end) external lock {
    uint256 _amount = lockedPosition[_msgSender()][_end];
    uint256 _now = block.timestamp;
    require(_amount > 0, "Nothing to withdraw");
    if (_now < _end) {
      uint256 _fee = (_amount * earlyWithdrawPenaltyRate) / PRECISION;
      _penalize(_fee);
      _amount = _amount - _fee;
    }
    delete lockedPosition[_msgSender()][_end];
    delete multipliers[_msgSender()][_end];
    _burn(_msgSender(), mintedForLock[_msgSender()][_end]);
    delete mintedForLock[_msgSender()][_end];
    lockEnds[_msgSender()].remove(_end);

    IERC20(lockedToken).safeTransfer(_msgSender(), _amount);

    emit Withdraw(_msgSender(), _amount, _now);
  }

  // This will charge PENALTY if lock is not expired yet
  function emergencyWithdrawAll() external lock {
    uint256 _endsLength = lockEnds[_msgSender()].length();
    for (uint256 i = 0; i < _endsLength; i++) {
      uint256 _end = lockEnds[_msgSender()].at(i);
      uint256 _locked = lockedPosition[_msgSender()][_end];
      uint256 _now = block.timestamp;
      if (_locked > 0) {
        if (_now < _end) {
          uint256 _fee = (_locked * earlyWithdrawPenaltyRate) / PRECISION;
          _penalize(_fee);
          lockedPosition[_msgSender()][_end] = _locked - _fee;
        }
        delete lockedPosition[_msgSender()][_end];
        delete multipliers[_msgSender()][_end];
        _burn(_msgSender(), mintedForLock[_msgSender()][i]);
        delete mintedForLock[_msgSender()][_end];

        IERC20(lockedToken).safeTransfer(_msgSender(), _locked);

        emit Withdraw(_msgSender(), _locked, _now);
      }
    }
  }

  function transferLockShare(
    uint256 _amount,
    uint256 _end,
    address _to
  ) public {
    uint256 _share = (_amount * 1e18) / lockedPosition[_msgSender()][_end];

    uint256 _toSend = (_share * mintedForLock[_msgSender()][_end]) / 1e18;

    // send the respective amount of this token
    IERC20(address(this)).safeTransferFrom(
      _msgSender(),
      address(this),
      _toSend
    );

    // adjust locked balances
    _transferLockShare(_msgSender(), _amount, _toSend, _end, _to);
  }

  function transferFullLock(uint256 _end, address _to) public {
    // for a full transfer, the full minted amount has to be paid
    uint256 _minted = mintedForLock[_msgSender()][_end];

    // send the underying amount of this token
    IERC20(address(this)).safeTransferFrom(_msgSender(), _to, _minted);

    _transferFullLock(_msgSender(), _to, _end);
  }

  /* ========== INTERNAL FUNCTIONS ========== */

  /**
  creates lock
   */
  function _create_lock(
    address _addr,
    uint256 _value,
    uint256 _end
  ) internal lock {
    require(!lockEnds[_addr].contains(_end), "position exists");
    uint256 _vp = get_amount_minted(_value, _end);
    require(_vp > 0, "No benefit to lock");
    lockedPosition[_addr][_end] = _value;

    IERC20(lockedToken).safeTransferFrom(_addr, address(this), _value);
    _mint(_addr, _vp);
    mintedForLock[_addr][_end] = _vp;
    lockEnds[_addr].add(_end);
    multipliers[_addr][_end] = _calculate_multiplier(block.timestamp, _end);
  }

  /**
   * Extends the maturity
   * Moves also the minted amounts
   * @param _addr user
   * @param _amount Amount to move from old end to end
   * @param _end end of locked amount to move
   * @param _newEnd target end
   */
  function _extend_maturity(
    address _addr,
    uint256 _amount,
    uint256 _end,
    uint256 _newEnd
  ) internal lock {
    uint256 _vp = get_amount_minted(_amount, _end);
    uint256 _vpNew = get_amount_minted(_amount, _newEnd);
    uint256 _oldLocked = lockedPosition[_addr][_end];
    uint256 _now = block.timestamp;
    // adjust multipliers
    if (lockEnds[_addr].contains(_newEnd)) {
      // position exists
      multipliers[_addr][_newEnd] = _calculate_adjusted_multiplier_position(
        _amount,
        _now,
        _newEnd,
        lockedPosition[_addr][_newEnd],
        multipliers[_addr][_newEnd]
      );
      // increase on new
      lockedPosition[_addr][_newEnd] += _amount;
      mintedForLock[_addr][_newEnd] += _vpNew;
    } else {
      // position does not exist
      multipliers[_addr][_newEnd] = _calculate_adjusted_multiplier_maturity(
        _now,
        _end,
        _newEnd,
        multipliers[_addr][_end]
      );
      // create on new
      lockedPosition[_addr][_newEnd] = _amount;
      mintedForLock[_addr][_newEnd] = _vpNew;
      lockEnds[_addr].add(_newEnd);
    }

    if (_amount == _oldLocked) {
      // delete from old
      delete lockedPosition[_addr][_end];
      delete mintedForLock[_addr][_end];
      delete multipliers[_addr][_end];
      lockEnds[_addr].remove(_end);
    } else {
      // decrease from old
      lockedPosition[_addr][_end] -= _amount;
      mintedForLock[_addr][_end] -= _vp;
    }

    uint256 _vpDiff = _vpNew - _vp;
    require(_vpDiff > 0, "No benefit to lock");
    _mint(_addr, _vpDiff);

    emit Deposit(_addr, _amount, _newEnd, _now);
  }

  /**
   * Function to increase position for given _end
   * @param _addr user
   * @param _value increase position for position in _end by value
   * @param _end maturity of the position to increase
   */
  function _increase_position(
    address _addr,
    uint256 _value,
    uint256 _end
  ) internal lock {
    // calculate amount to mint
    uint256 _vp = get_amount_minted(_value, _end); // voting_power_unlock_time(_value, _end);

    // adjust multiplier
    uint256 _now = block.timestamp;
    multipliers[_addr][_end] = _calculate_adjusted_multiplier_position(
      _value,
      _now,
      _end,
      _value,
      multipliers[_addr][_end]
    );

    // increase locked amount
    lockedPosition[_addr][_end] += _value;

    require(_vp > 0, "No benefit to lock");

    IERC20(lockedToken).safeTransferFrom(_msgSender(), address(this), _value);

    _mint(_addr, _vp);
    mintedForLock[_addr][_end] += _vp;

    emit Deposit(_addr, _value, _end, _now);
  }

  function _penalize(uint256 _amount) internal {
    if (penaltyCollector != address(0)) {
      // send to collector if `penaltyCollector` set
      IERC20(lockedToken).safeTransfer(penaltyCollector, _amount);
    } else {
      ERC20Burnable(lockedToken).burn(_amount);
    }
  }

  // /**
  //  * @dev Before transfer function that moves the respective locks to the recipient
  //  * Standard ERC20 function adjusted for ERC20 lock which does NOT execute these lines
  //  * for minting and burning as it would interfere with the lock logic.
  //  * @param from sender
  //  * @param to recipient
  //  * @param amount amount of this token to be sent
  //  */
  // function _beforeTokenTransfer(
  //   address from,
  //   address to,
  //   uint256 amount
  // ) internal override {
  //   uint256 _ids = lockIds[from];
  //   uint256 _amountLeft = amount;
  //   for (uint256 i = 0; i < _ids; i++) {
  //     uint256 minted = mintedForLock[from][i];
  //     if (_amountLeft >= minted) {
  //       _transferFullLock(from, to, i);
  //       _amountLeft -= minted;
  //     } else if (_amountLeft > 0) {
  //       // here we just transfer the last bit left
  //       _transferLock(_amountLeft, i, to);
  //       break;
  //     } else break;
  //   }
  // }

  /**
  * @dev Function that transfers the share of the underlying lock amount to the recipient.
  @param _amount amount of locked token to transfer
  @param _end id of lock to transfer
  @param _to recipient address
  */
  function _transferLockShare(
    address _from,
    uint256 _amount,
    uint256 _vp,
    uint256 _end,
    address _to
  ) internal {
    uint256 _locked = lockedPosition[_from][_end];
    require(_amount <= _locked, "Insufficient funds in Lock");

    // log the amount for the recipient
    _receiveLock(_amount, _vp, _end, _to);

    // reduce this users lock amount
    lockedPosition[_from][_end] -= _amount;

    // reduce related voting power
    mintedForLock[_from][_end] -= _vp;
  }

  /**
  * @dev Function that transfers the full lock of the user to the recipient.
  @param _end id of lock to transfer
  @param _to recipient address
  */
  function _transferFullLock(
    address _from,
    address _to,
    uint256 _end
  ) internal {
    // log the amount for the recipient
    _receiveLock(
      lockedPosition[_from][_end],
      mintedForLock[_from][_end],
      _end,
      _to
    );

    // reduce this users lock amount
    delete lockedPosition[_from][_end];
    delete mintedForLock[_from][_end];

    delete multipliers[_from][_end];
    // delete index
    lockEnds[_from].remove(_end);
  }

  /**
  Function that logs the recipients lock
  All locks will searched and once a match is found the lock amount is added
  @param _lockAmount locked amount that is received
  @param _lockEnd lock end time
  @param _recipient recipient address
  - does NOT reduce the senders lock, that has to be done before
   */
  function _receiveLock(
    uint256 _lockAmount,
    uint256 _vp,
    uint256 _lockEnd,
    address _recipient
  ) internal {
    bool _lockExists = lockEnds[_recipient].contains(_lockEnd);
    uint256 _now = block.timestamp;
    if (_lockExists) {
      mintedForLock[_recipient][_lockEnd] += _vp;
      multipliers[_recipient][
        _lockEnd
      ] = _calculate_adjusted_multiplier_position(
        _lockAmount,
        _now,
        _lockEnd,
        lockedPosition[_recipient][_lockEnd],
        multipliers[_recipient][_lockEnd]
      );
      lockedPosition[_recipient][_lockEnd] += _lockAmount;
    } else {
      multipliers[_recipient][_lockEnd] = _calculate_multiplier(_now, _lockEnd);
      lockedPosition[_recipient][_lockEnd] = _lockAmount;
      mintedForLock[_recipient][_lockEnd] = _vp;
      lockEnds[_recipient].add(_lockEnd);
    }
  }

  function _getEarliestEnd(address _addr) internal view returns (uint256 _min) {
    uint256 _count = lockEnds[_addr].length();
    if (_count == 0) return 0;
    _min = lockEnds[_addr].at(0);
    for (uint256 i = 1; i < lockEnds[_addr].length(); i++) {
      uint256 _current = lockEnds[_addr].at(i);
      if (_current < _min) {
        _min = _current;
      }
    }
    return _min;
  }

  function _getLatestEnd(address _addr) internal view returns (uint256 _max) {
    uint256 _count = lockEnds[_addr].length();
    if (_count == 0) return 0;
    _max = lockEnds[_addr].at(0);
    for (uint256 i = 1; i < lockEnds[_addr].length(); i++) {
      uint256 _current = lockEnds[_addr].at(i);
      if (_current > _max) {
        _max = _current;
      }
    }
    return _max;
  }

  function _calculate_multiplier(uint256 _ref, uint256 _end)
    internal
    pure
    returns (uint256)
  {
    return ((_end - _ref) * 1e18) / (_end - REF_DATE);
  }

  function _calculate_adjusted_multiplier_position(
    uint256 _amount,
    uint256 _ref,
    uint256 _end,
    uint256 _position,
    uint256 _oldMultiplier
  ) internal pure returns (uint256) {
    return
      (_position *
        _oldMultiplier +
        _amount *
        _calculate_multiplier(_ref, _end)) /
      (_amount + _position) /
      1e18;
  }

  function _calculate_adjusted_multiplier_maturity(
    uint256 _ref,
    uint256 _endOld,
    uint256 _end,
    uint256 _oldMultiplier
  ) internal pure returns (uint256) {
    return
      (_endOld *
        _oldMultiplier +
        (_end - _endOld) *
        _calculate_multiplier(_ref, _end)) /
      _end /
      1e18;
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  function setMinLockedAmount(uint256 _minLockedAmount) external onlyOwner {
    minLockedAmount = _minLockedAmount;
    emit MinLockedAmountSet(_minLockedAmount);
  }

  function setEarlyWithdrawPenaltyRate(uint256 _earlyWithdrawPenaltyRate)
    external
    onlyOwner
  {
    require(
      _earlyWithdrawPenaltyRate <= MAX_WITHDRAWAL_PENALTY,
      "withdrawal penalty is too high"
    ); // <= 50%
    earlyWithdrawPenaltyRate = _earlyWithdrawPenaltyRate;
    emit EarlyWithdrawPenaltySet(_earlyWithdrawPenaltyRate);
  }

  function setPenaltyCollector(address _addr) external onlyOwner {
    penaltyCollector = _addr;
    emit PenaltyCollectorSet(_addr);
  }

  /* =============== EVENTS ==================== */
  event Deposit(
    address indexed provider,
    uint256 value,
    uint256 locktime,
    uint256 timestamp
  );
  event Withdraw(address indexed provider, uint256 value, uint256 timestamp);
  event PenaltyCollectorSet(address indexed addr);
  event EarlyWithdrawPenaltySet(uint256 indexed penalty);
  event MinLockedAmountSet(uint256 indexed amount);
}
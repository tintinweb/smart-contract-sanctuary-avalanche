/**
 *Submitted for verification at snowtrace.io on 2022-02-16
*/

// File: src/StakedAvax/StakedAvaxStorage.sol



pragma solidity 0.6.12;


contract StakedAvaxStorage {
    struct UnlockRequest {
        // The timestamp at which the `shareAmount` was requested to be unlocked
        uint startedAt;

        // The amount of shares to burn
        uint shareAmount;
    }

    bytes32 public constant ROLE_WITHDRAW = keccak256("ROLE_WITHDRAW");
    bytes32 public constant ROLE_PAUSE = keccak256("ROLE_PAUSE");
    bytes32 public constant ROLE_RESUME = keccak256("ROLE_RESUME");
    bytes32 public constant ROLE_ACCRUE_REWARDS = keccak256("ROLE_ACCRUE_REWARDS");
    bytes32 public constant ROLE_DEPOSIT = keccak256("ROLE_DEPOSIT");
    bytes32 public constant ROLE_PAUSE_MINTING = keccak256("ROLE_PAUSE_MINTING");
    bytes32 public constant ROLE_RESUME_MINTING = keccak256("ROLE_RESUME_MINTING");
    bytes32 public constant ROLE_SET_TOTAL_POOLED_AVAX_CAP = keccak256("ROLE_SET_TOTAL_POOLED_AVAX_CAP");

    // The total amount of AVAX controlled by the contract
    uint public totalPooledAvax;

    // The total number of sAVAX shares
    uint public totalShares;

    /**
     * @dev sAVAX balances are dynamic and are calculated based on the accounts' shares
     * and the total amount of AVAX controlled by the protocol. Account shares aren't
     * normalized, so the contract also stores the sum of all shares to calculate
     * each account's token balance which equals to:
     *
     * shares[account] * totalPooledAvax / totalShares
    */
    mapping(address => uint256) internal shares;

    // Allowances are nominated in tokens, not token shares.
    mapping(address => mapping(address => uint256)) internal allowances;

    // The time that has to elapse before all sAVAX can be converted into AVAX
    uint public cooldownPeriod;

    // The time window within which the unlocked AVAX has to be redeemed after the cooldown
    uint public redeemPeriod;

    // User-specific details of requested AVAX unlocks
    mapping(address => UnlockRequest[]) public userUnlockRequests;

    // Amount of users' sAVAX custodied by the contract
    mapping(address => uint) public userSharesInCustody;

    // Exchange rate by timestamp. Updated on delegation reward accrual.
    mapping(uint => uint) public historicalExchangeRatesByTimestamp;

    // An ordered list of `historicalExchangeRates` keys
    uint[] public historicalExchangeRateTimestamps;

    // Set if minting has been paused
    bool public mintingPaused;

    // The maximum amount of AVAX that can be held by the protocol
    uint public totalPooledAvaxCap;

    // Number of wallets which have sAVAX
    uint public stakerCount;
}

// File: @openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol



pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol



pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

// File: @openzeppelin/contracts-upgradeable/proxy/Initializable.sol



// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// File: @openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol



pragma solidity >=0.6.0 <0.8.0;


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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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
    uint256[49] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol



pragma solidity >=0.6.0 <0.8.0;


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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol



pragma solidity >=0.6.0 <0.8.0;



/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/utils/EnumerableSetUpgradeable.sol



pragma solidity >=0.6.0 <0.8.0;

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
library EnumerableSetUpgradeable {
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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
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
}

// File: @openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol



pragma solidity >=0.6.0 <0.8.0;





/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using AddressUpgradeable for address;

    struct RoleData {
        EnumerableSetUpgradeable.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol



pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// File: src/StakedAvax/StakedAvax.sol



pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;








contract StakedAvax is
    IERC20Upgradeable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    StakedAvaxStorage
{
    using SafeMathUpgradeable for uint;

    /// @notice Emitted when a user stakes AVAX
    event Submitted(address indexed user, uint avaxAmount, uint shareAmount);

    /// @notice Emitted when a user requests sAVAX to be converted back to AVAX
    event UnlockRequested(address indexed user, uint shareAmount);

    /// @notice Emitted when a user cancel a pending unlock request
    event UnlockCancelled(address indexed user, uint unlockRequestedAt, uint shareAmount);

    /// @notice Emitted when a user redeems delegated AVAX
    event Redeem(address indexed user, uint unlockRequestedAt, uint shareAmount, uint avaxAmount);

    /// @notice Emitted when a user redeems sAVAX which was not burned for AVAX withing the `redeemPeriod`.
    event RedeemOverdueShares(address indexed user, uint shareAmount);

    /// @notice Emitted when a warden withdraws AVAX for delegation
    event Withdraw(address indexed user, uint amount);

    /// @notice Emitted when a warden deposits AVAX into the contract
    event Deposit(address indexed user, uint amount);

    /// @notice Emitted when the cooldown period is updated
    event CooldownPeriodUpdated(uint oldCooldownPeriod, uint newCooldownPeriod);

    /// @notice Emitted when the redeem period is updated
    event RedeemPeriodUpdated(uint oldRedeemPeriod, uint newRedeemPeriod);

    /// @notice Emitted when the maximum pooled AVAX amount is changed
    event TotalPooledAvaxCapUpdated(uint oldTotalPooldAvaxCap, uint newTotalPooledAvaxCap);

    /// @notice Emitted when rewards are distributed into the pool
    event AccrueRewards(uint value);

    /// @notice Emitted when sAVAX minting is paused
    event MintingPaused(address user);

    /// @notice Emitted when sAVAX minting is resumed
    event MintingResumed(address user);


    /**
     * @notice Initialize the StakedAvax contract
     * @param _cooldownPeriod Time delay before shares can be burned for AVAX
     * @param _redeemPeriod AVAX redemption period after unlock cooldown has elapsed
     */
    function initialize(uint _cooldownPeriod, uint _redeemPeriod) initializer public {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        cooldownPeriod = _cooldownPeriod;
        emit CooldownPeriodUpdated(0, _cooldownPeriod);

        redeemPeriod = _redeemPeriod;
        emit RedeemPeriodUpdated(0, _redeemPeriod);

        totalPooledAvaxCap = uint(-1);
        emit TotalPooledAvaxCapUpdated(0, totalPooledAvaxCap);
    }

    /**
     * @return The name of the token.
     */
    function name() public pure returns (string memory) {
        return "Staked AVAX";
    }

    /**
     * @return The symbol of the token.
     */
    function symbol() public pure returns (string memory) {
        return "sAVAX";
    }

    /**
     * @return The number of decimals for getting user representation of a token amount.
     */
    function decimals() public pure returns (uint8) {
        return 18;
    }

    /**
     * @return The amount of tokens in existence.
     */
    function totalSupply() public view override returns (uint) {
        return totalShares;
    }

    /**
     * @return The amount of sAVAX tokens owned by the `account`.
     */
    function balanceOf(address account) public view override returns (uint) {
        return shares[account];
    }

    /**
     * @notice Moves `amount` tokens from the caller's account to the `recipient` account.
     * Emits a `Transfer` event.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     * - the contract must not be paused.
     *
     * @return A boolean value indicating whether the operation succeeded.
     */
    function transfer(address recipient, uint amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);

        return true;
    }

    /**
     * @return The remaining number of tokens that `spender` is allowed to spend on behalf of `owner`
     * through `transferFrom`. This is zero by default.
     *
     * @dev This value changes when `approve` or `transferFrom` is called.
     */
    function allowance(address owner, address spender) public view override returns (uint) {
        return allowances[owner][spender];
    }

    /**
     * @notice Sets `amount` as the allowance of `spender` over the caller's tokens.
     * Emits an `Approval` event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - the contract must not be paused.
     *
     * @return A boolean value indicating whether the operation succeeded.
     */
    function approve(address spender, uint amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);

        return true;
    }

    /**
     * @notice Moves `amount` tokens from `sender` to `recipient` using the allowance mechanism. `amount`
     * is then deducted from the caller's allowance.
     *
     * @return A boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero addresses.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least `amount`.
     * - the contract must not be paused.
     */
    function transferFrom(address sender, address recipient, uint amount) public override returns (bool) {
        uint currentAllowance = allowances[sender][msg.sender];
        require(currentAllowance >= amount, "TRANSFER_AMOUNT_EXCEEDS_ALLOWANCE");

        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, currentAllowance.sub(amount));

        return true;
    }

    /**
     * @return The amount of shares that corresponds to `avaxAmount` protocol-controlled AVAX.
     */
    function getSharesByPooledAvax(uint avaxAmount) public view returns (uint) {
        if (totalPooledAvax == 0) {
            return 0;
        }

        uint shares = avaxAmount.mul(totalShares).div(totalPooledAvax);
        require(shares > 0, "Invalid share count");

        return shares;
    }

    /**
     * @return The amount of AVAX that corresponds to `shareAmount` token shares.
     */
    function getPooledAvaxByShares(uint shareAmount) public view returns (uint) {
        if (totalShares == 0) {
            return 0;
        }

        return shareAmount.mul(totalPooledAvax).div(totalShares);
    }

    /**
     * @notice Start unlocking cooldown period for `shareAmount` AVAX
     * @param shareAmount Amount of shares to unlock
     */
    function requestUnlock(uint shareAmount) external nonReentrant whenNotPaused {
        require(shareAmount > 0, "Invalid unlock amount");
        require(shareAmount <= shares[msg.sender], "Unlock amount too large");

        userSharesInCustody[msg.sender] = userSharesInCustody[msg.sender].add(shareAmount);
        _transferShares(msg.sender, address(this), shareAmount);

        userUnlockRequests[msg.sender].push(UnlockRequest(
            block.timestamp,
            shareAmount
        ));

        emit UnlockRequested(msg.sender, shareAmount);
    }

    /**
     * @notice Get the number of active unlock requests by user
     * @param user User address
     */
    function getUnlockRequestCount(address user) external view returns (uint) {
        return userUnlockRequests[user].length;
    }

    /**
     * @notice Get a subsection of a user's unlock requests
     * @param user User account address
     * @param from List start index
     * @param to List end index
     */
    function getPaginatedUnlockRequests(address user, uint from, uint to)
        external
        view
        returns (
            UnlockRequest[] memory,
            uint[] memory
        )
    {
        require(from < userUnlockRequests[user].length, "From index out of bounds");
        require(from < to, "To index must be greater than from index");

        if (to > userUnlockRequests[user].length) {
            to = userUnlockRequests[user].length;
        }

        UnlockRequest[] memory paginatedUnlockRequests = new UnlockRequest[](to.sub(from));
        uint[] memory exchangeRates = new uint[](to.sub(from));

        for (uint i = 0; i < to.sub(from); i = i.add(1)) {
            paginatedUnlockRequests[i] = userUnlockRequests[user][from.add(i)];

            if (_isWithinRedemptionPeriod(paginatedUnlockRequests[i])) {
                (bool success, uint exchangeRate) = _getExchangeRateByUnlockTimestamp(paginatedUnlockRequests[i].startedAt);
                require(success, "Exchange rate not found");

                exchangeRates[i] = exchangeRate;
            }
        }

        return (paginatedUnlockRequests, exchangeRates);
    }

    /**
     * @notice Cancel all unlock requests that are pending the cooldown period to elapse.
     */
    function cancelPendingUnlockRequests() external nonReentrant {
        uint unlockIndex;
        while (unlockIndex < userUnlockRequests[msg.sender].length) {
            if (!_isWithinCooldownPeriod(userUnlockRequests[msg.sender][unlockIndex])) {
                unlockIndex = unlockIndex.add(1);
                continue;
            }

            _cancelUnlockRequest(unlockIndex);
        }
    }

    /**
     * @notice Cancel all unlock requests that are redeemable.
     */
    function cancelRedeemableUnlockRequests() external nonReentrant {
        uint unlockIndex;
        while (unlockIndex < userUnlockRequests[msg.sender].length) {
            if (!_isWithinRedemptionPeriod(userUnlockRequests[msg.sender][unlockIndex])) {
                unlockIndex = unlockIndex.add(1);
                continue;
            }

            _cancelUnlockRequest(unlockIndex);
        }
    }

    /**
     * @notice Cancel an unexpired unlock request
     * @param unlockIndex Index number of the cancelled unlock
     */
    function cancelUnlockRequest(uint unlockIndex) external nonReentrant {
        _cancelUnlockRequest(unlockIndex);
    }

    /**
     * @notice Redeem all redeemable AVAX from all unlocks
     */
    function redeem() external nonReentrant {
        uint unlockRequestCount = userUnlockRequests[msg.sender].length;
        uint i = 0;

        while (i < unlockRequestCount) {
            if (!_isWithinRedemptionPeriod(userUnlockRequests[msg.sender][i])) {
                i = i.add(1);
                continue;
            }

            _redeem(i);

            unlockRequestCount = unlockRequestCount.sub(1);
        }
    }

    /**
     * @notice Redeem AVAX after cooldown has finished
     * @param unlockIndex Index number of the redeemed unlock request
     */
    function redeem(uint unlockIndex) external nonReentrant {
        _redeem(unlockIndex);
    }

    /**
     * @notice Redeem all sAVAX held in custody for overdue unlock requests
     */
    function redeemOverdueShares() external nonReentrant whenNotPaused {
        uint totalOverdueShares = 0;

        uint unlockCount = userUnlockRequests[msg.sender].length;
        uint i = 0;
        while (i < unlockCount) {
            UnlockRequest memory unlockRequest = userUnlockRequests[msg.sender][i];

            if (!_isExpired(unlockRequest)) {
                i = i.add(1);
                continue;
            }

            totalOverdueShares = totalOverdueShares.add(unlockRequest.shareAmount);

            userUnlockRequests[msg.sender][i] = userUnlockRequests[msg.sender][userUnlockRequests[msg.sender].length.sub(1)];
            userUnlockRequests[msg.sender].pop();

            unlockCount = unlockCount.sub(1);
        }

        if (totalOverdueShares > 0) {
            userSharesInCustody[msg.sender] = userSharesInCustody[msg.sender].sub(totalOverdueShares);
            _transferShares(address(this), msg.sender, totalOverdueShares);

            emit RedeemOverdueShares(msg.sender, totalOverdueShares);
        }
    }

    /**
     * @notice Redeem sAVAX held in custody for the given unlock request
     * @param unlockIndex Unlock request array index
     */
    function redeemOverdueShares(uint unlockIndex) external nonReentrant whenNotPaused {
        require(unlockIndex < userUnlockRequests[msg.sender].length, "Invalid unlock index");

        UnlockRequest memory unlockRequest = userUnlockRequests[msg.sender][unlockIndex];

        require(_isExpired(unlockRequest), "Unlock request is not expired");

        uint shareAmount = unlockRequest.shareAmount;
        userSharesInCustody[msg.sender] = userSharesInCustody[msg.sender].sub(shareAmount);

        userUnlockRequests[msg.sender][unlockIndex] = userUnlockRequests[msg.sender][userUnlockRequests[msg.sender].length - 1];
        userUnlockRequests[msg.sender].pop();

        _transferShares(address(this), msg.sender, shareAmount);

        emit RedeemOverdueShares(msg.sender, shareAmount);
    }

    /**
     * @notice Process user deposit, mints liquid tokens and increase the pool buffer
     * @return Amount of sAVAX shares generated
     */
    function submit() public payable whenNotPaused returns (uint) {
        address sender = msg.sender;
        uint deposit = msg.value;

        require(deposit != 0, "ZERO_DEPOSIT");

        uint shareAmount = getSharesByPooledAvax(deposit);
        if (shareAmount == 0) {
            shareAmount = deposit;
        }

        _mintShares(sender, shareAmount);
        totalPooledAvax = totalPooledAvax.add(deposit);

        uint actualAvaxDepositAmount = getPooledAvaxByShares(shareAmount);

        emit Transfer(address(0), sender, shareAmount);
        emit Submitted(sender, actualAvaxDepositAmount, shareAmount);

        return shareAmount;
    }

    receive() external payable {
        submit();
    }


    /*********************************************************************************
     *                                                                               *
     *                             INTERNAL FUNCTIONS                                *
     *                                                                               *
     *********************************************************************************/


    /**
     * @notice Moves `amount` tokens from `sender` to `recipient`.
     * Emits a `Transfer` event.
     */
    function _transfer(address sender, address recipient, uint amount) internal {
        _transferShares(sender, recipient, amount);

        emit Transfer(sender, recipient, amount);
    }

    /**
     * @notice Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * Emits an `Approval` event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     * - the contract must not be paused.
     */
    function _approve(address owner, address spender, uint amount) internal whenNotPaused {
        require(owner != address(0), "APPROVE_FROM_ZERO_ADDRESS");
        require(spender != address(0), "APPROVE_TO_ZERO_ADDRESS");

        allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    /**
     * @notice Moves `shareAmount` shares from `sender` to `recipient`.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must hold at least `shareAmount` shares.
     * - the contract must not be paused.
     */
    function _transferShares(address sender, address recipient, uint shareAmount) internal whenNotPaused {
        require(sender != address(0), "TRANSFER_FROM_THE_ZERO_ADDRESS");
        require(recipient != address(0), "TRANSFER_TO_THE_ZERO_ADDRESS");
        require(sender != recipient, "TRANSFER_TO_SELF");

        uint currentSenderShares = shares[sender];
        require(shareAmount <= currentSenderShares, "TRANSFER_AMOUNT_EXCEEDS_BALANCE");
        require(shareAmount > 0, "TRANSFER_ZERO_VALUE");

        if (shares[recipient] == 0) {
            stakerCount = stakerCount.add(1);
        }

        shares[sender] = currentSenderShares.sub(shareAmount);
        shares[recipient] = shares[recipient].add(shareAmount);

        if (shares[sender] == 0) {
            stakerCount = stakerCount.sub(1);
        }
    }

    /**
     * @notice Creates `shareAmount` shares and assigns them to `recipient`, increasing the total amount of shares.
     * @dev This doesn't increase the token total supply.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address
     * - the contract must not be paused
     * - minting must not be paused
     * - total pooled AVAX cap must not be exceeded
     */
    function _mintShares(address recipient, uint shareAmount) internal whenNotPaused returns (uint) {
        require(!mintingPaused, "Minting paused");
        require(recipient != address(0), "MINT_TO_THE_ZERO_ADDRESS");
        require(shareAmount > 0, "MINT_ZERO_VALUE");

        uint avaxAmount = getPooledAvaxByShares(shareAmount);
        require(totalPooledAvax.add(avaxAmount) <= totalPooledAvaxCap, "TOTAL_POOLED_AVAX_CAP_EXCEEDED");

        if (shares[recipient] == 0) {
            stakerCount = stakerCount.add(1);
        }

        totalShares = totalShares.add(shareAmount);
        shares[recipient] = shares[recipient].add(shareAmount);

        return totalShares;
    }

    /**
     * @notice Destroys `shareAmount` shares from `account`'s holdings, decreasing the total amount of shares.
     * @dev This doesn't decrease the token total supply.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must hold at least `shareAmount` shares.
     * - the contract must not be paused.
     */
    function _burnShares(address account, uint shareAmount) internal whenNotPaused returns (uint) {
        require(account != address(0), "BURN_FROM_THE_ZERO_ADDRESS");
        require(shareAmount > 0, "BURN_ZERO_VALUE");

        uint accountShares = shares[account];
        require(shareAmount <= accountShares, "BURN_AMOUNT_EXCEEDS_BALANCE");

        totalShares = totalShares.sub(shareAmount);
        shares[account] = accountShares.sub(shareAmount);

        if (shares[account] == 0) {
            stakerCount = stakerCount.sub(1);
        }

        return totalShares;
    }

    /**
     * @notice Checks if the unlock request is within its cooldown period
     * @param unlockRequest Unlock request
     */
    function _isWithinCooldownPeriod(UnlockRequest memory unlockRequest) internal view returns (bool) {
        return unlockRequest.startedAt.add(cooldownPeriod) >= block.timestamp;
    }

    /**
     * @notice Checks if the unlock request is within its redemption period
     * @param unlockRequest Unlock request
     */
    function _isWithinRedemptionPeriod(UnlockRequest memory unlockRequest) internal view returns (bool) {
        return !_isWithinCooldownPeriod(unlockRequest)
            && unlockRequest.startedAt.add(cooldownPeriod).add(redeemPeriod) >= block.timestamp;
    }

    /**
     * @notice Checks if the unlock request has expired
     * @param unlockRequest Unlock request
     */
    function _isExpired(UnlockRequest memory unlockRequest) internal view returns (bool) {
        return unlockRequest.startedAt.add(cooldownPeriod).add(redeemPeriod) < block.timestamp;
    }

    /**
     * @notice Cancel an unexpired unlock request
     * @param unlockIndex Index number of the cancelled unlock
     */
    function _cancelUnlockRequest(uint unlockIndex) internal whenNotPaused {
        require(unlockIndex < userUnlockRequests[msg.sender].length, "Invalid index");

        UnlockRequest memory unlockRequest = userUnlockRequests[msg.sender][unlockIndex];

        require(!_isExpired(unlockRequest), "Unlock request is expired");

        uint shareAmount = unlockRequest.shareAmount;
        uint unlockRequestedAt = unlockRequest.startedAt;

        if (unlockIndex != userUnlockRequests[msg.sender].length - 1) {
            userUnlockRequests[msg.sender][unlockIndex] = userUnlockRequests[msg.sender][userUnlockRequests[msg.sender].length - 1];
        }

        userUnlockRequests[msg.sender].pop();

        userSharesInCustody[msg.sender] = userSharesInCustody[msg.sender].sub(shareAmount);
        _transferShares(address(this), msg.sender, shareAmount);

        emit UnlockCancelled(msg.sender, unlockRequestedAt, shareAmount);
    }

    /**
     * @notice Redeem AVAX after cooldown has finished
     * @param unlockRequestIndex Index number of the redeemed unlock request
     */
    function _redeem(uint unlockRequestIndex) internal whenNotPaused {
        require(unlockRequestIndex < userUnlockRequests[msg.sender].length, "Invalid unlock request index");

        UnlockRequest memory unlockRequest = userUnlockRequests[msg.sender][unlockRequestIndex];

        require(_isWithinRedemptionPeriod(unlockRequest), "Unlock request is not redeemable");

        (bool success, uint exchangeRate) = _getExchangeRateByUnlockTimestamp(unlockRequest.startedAt);
        require(success, "Exchange rate not found");

        uint shareAmount = unlockRequest.shareAmount;
        uint startedAt = unlockRequest.startedAt;
        uint avaxAmount = exchangeRate.mul(shareAmount).div(1e18);

        require(avaxAmount >= shareAmount, "Invalid exchange rate");

        userSharesInCustody[msg.sender] = userSharesInCustody[msg.sender].sub(shareAmount);
        _burnShares(address(this), shareAmount);

        totalPooledAvax = totalPooledAvax.sub(avaxAmount);

        userUnlockRequests[msg.sender][unlockRequestIndex] = userUnlockRequests[msg.sender][userUnlockRequests[msg.sender].length.sub(1)];
        userUnlockRequests[msg.sender].pop();

        (success, ) = msg.sender.call{ value: avaxAmount }("");
        require(success, "AVAX transfer failed");

        emit Redeem(msg.sender, startedAt, shareAmount, avaxAmount);
    }

    /**
     * @notice Get the earliest exchange rate closest to the unlock timestamp
     * @param unlockTimestamp Unlock request timestamp
     * @return (success, exchange rate)
     */
    function _getExchangeRateByUnlockTimestamp(uint unlockTimestamp) internal view returns (bool, uint) {
        if (historicalExchangeRateTimestamps.length == 0) {
            return (false, 0);
        }

        uint low = 0;
        uint mid;
        uint high = historicalExchangeRateTimestamps.length - 1;

        uint unlockClaimableAtTimestamp = unlockTimestamp.add(cooldownPeriod);

        while (low <= high) {
            mid = high.add(low).div(2);

            if (historicalExchangeRateTimestamps[mid] <= unlockClaimableAtTimestamp) {
                if (mid.add(1) == historicalExchangeRateTimestamps.length ||
                    historicalExchangeRateTimestamps[mid.add(1)] > unlockClaimableAtTimestamp) {
                    return (true, historicalExchangeRatesByTimestamp[historicalExchangeRateTimestamps[mid]]);
                }

                low = mid.add(1);
            } else if (mid == 0) {
                return (true, 1e18);
            } else {
                high = mid.sub(1);
            }
        }

        return (false, 0);
    }

    /**
     * @notice Remove exchange rate entries older than `redeemPeriod`
     */
    function _dropExpiredExchangeRateEntries() internal {
        if (historicalExchangeRateTimestamps.length == 0) {
            return;
        }

        uint shiftCount = 0;
        uint expirationThreshold = block.timestamp.sub(redeemPeriod);

        while (shiftCount < historicalExchangeRateTimestamps.length &&
            historicalExchangeRateTimestamps[shiftCount] < expirationThreshold) {
            shiftCount = shiftCount.add(1);
        }

        if (shiftCount == 0) {
            return;
        }

        for (uint i = 0; i < historicalExchangeRateTimestamps.length.sub(shiftCount); i = i.add(1)) {
            historicalExchangeRateTimestamps[i] = historicalExchangeRateTimestamps[i.add(shiftCount)];
        }

        for (uint i = 1; i <= shiftCount; i = i.add(1)) {
            delete historicalExchangeRatesByTimestamp[historicalExchangeRateTimestamps[historicalExchangeRateTimestamps.length.sub(i)]];
            historicalExchangeRateTimestamps.pop();
        }
    }

    /*********************************************************************************
     *                                                                               *
     *                            ADMIN-ONLY FUNCTIONS                               *
     *                                                                               *
     *********************************************************************************/

    /**
     * @notice Accrue staking rewards to the pool
     * @param amount Amount of rewards accrued to the pool
     */
    function accrueRewards(uint amount) external nonReentrant {
        require(hasRole(ROLE_ACCRUE_REWARDS, msg.sender), "ROLE_ACCRUE_REWARDS");

        totalPooledAvax = totalPooledAvax.add(amount);

        _dropExpiredExchangeRateEntries();
        historicalExchangeRatesByTimestamp[block.timestamp] = getPooledAvaxByShares(1e18);
        historicalExchangeRateTimestamps.push(block.timestamp);

        emit AccrueRewards(amount);
    }

    /**
     * @notice Withdraw AVAX from the contract for delegation
     * @param amount Amount of AVAX to withdraw
     */
    function withdraw(uint amount) external nonReentrant {
        require(hasRole(ROLE_WITHDRAW, msg.sender), "ROLE_WITHDRAW");

        (bool success, ) = msg.sender.call{ value: amount }("");
        require(success, "AVAX transfer failed");

        emit Withdraw(msg.sender, amount);
    }

    /**
     * @notice Deposit AVAX into the contract without minting sAVAX
     */
    function deposit() external payable {
        require(hasRole(ROLE_DEPOSIT, msg.sender), "ROLE_DEPOSIT");
        require(msg.value > 0, "Zero value");

        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice Update the cooldown period
     * @param newCooldownPeriod New cooldown period
     */
    function setCooldownPeriod(uint newCooldownPeriod) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "DEFAULT_ADMIN_ROLE");

        uint oldCooldownPeriod = cooldownPeriod;
        cooldownPeriod = newCooldownPeriod;

        emit CooldownPeriodUpdated(oldCooldownPeriod, cooldownPeriod);
    }

    /**
     * @notice Update the redeem period
     * @param newRedeemPeriod New redeem period
     */
    function setRedeemPeriod(uint newRedeemPeriod) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "DEFAULT_ADMIN_ROLE");

        uint oldRedeemPeriod = redeemPeriod;
        redeemPeriod = newRedeemPeriod;

        emit RedeemPeriodUpdated(oldRedeemPeriod, redeemPeriod);
    }

    /**
     * @notice Set a upper limit for the total pooled AVAX amount
     * @param newTotalPooledAvaxCap The pool cap
     */
    function setTotalPooledAvaxCap(uint newTotalPooledAvaxCap) external {
        require(hasRole(ROLE_SET_TOTAL_POOLED_AVAX_CAP, msg.sender), "ROLE_SET_TOTAL_POOLED_AVAX_CAP");

        uint oldTotalPooledAvaxCap = totalPooledAvaxCap;
        totalPooledAvaxCap = newTotalPooledAvaxCap;

        emit TotalPooledAvaxCapUpdated(oldTotalPooledAvaxCap, newTotalPooledAvaxCap);
    }

    /**
     * @notice Stop pool routine operations
     */
    function pause() external {
        require(hasRole(ROLE_PAUSE, msg.sender), "ROLE_PAUSE");

        _pause();
    }

    /**
     * @notice Resume pool routine operations
     */
    function resume() external {
        require(hasRole(ROLE_RESUME, msg.sender), "ROLE_RESUME");

        _unpause();
    }

    /**
     * @notice Stop minting
     */
    function pauseMinting() external {
        require(hasRole(ROLE_PAUSE_MINTING, msg.sender), "ROLE_PAUSE_MINTING");
        require(!mintingPaused, "Minting is already paused");

        mintingPaused = true;
        emit MintingPaused(msg.sender);
    }

    /**
     * @notice Resume minting
     */
    function resumeMinting() external {
        require(hasRole(ROLE_RESUME_MINTING, msg.sender), "ROLE_RESUME_MINTING");
        require(mintingPaused, "Minting is not paused");

        mintingPaused = false;
        emit MintingResumed(msg.sender);
    }
}
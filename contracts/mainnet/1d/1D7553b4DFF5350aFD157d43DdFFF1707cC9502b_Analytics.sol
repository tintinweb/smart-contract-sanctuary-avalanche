/**
 *Submitted for verification at snowtrace.io on 2022-10-01
*/

// SPDX-License-Identifier: GPL-3.0

// File contracts/ihelp/charitypools/CharityPoolUtils.sol
// License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

library CharityPoolUtils {
    struct CharityPoolConfiguration {
        string charityName;
        address operatorAddress;
        address charityWalletAddress;
        address holdingTokenAddress;
        address ihelpAddress;
        address swapperAddress;
        address wrappedNativeAddress;
        address priceFeedProvider;
    }

    struct DirectDonationsCounter {
        uint256 totalContribNativeToken; 
        uint256 totalContribUSD;
        uint256 contribAfterSwapUSD;
        uint256 charityDonationUSD;
        uint256 devContribUSD;
        uint256 stakeContribUSD;
        uint256 totalDonations;
    }
}

// File contracts/utils/IERC20.sol
// License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);
    
    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

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

// File @openzeppelin/contracts-upgradeable/utils/[email protected]
// License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
                /// @solidity memory-safe-assembly
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

// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]
// License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// File @openzeppelin/contracts-upgradeable/utils/[email protected]
// License-Identifier: MIT
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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// File @openzeppelin/contracts-upgradeable/access/[email protected]
// License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// File @chainlink/contracts/src/v0.8/interfaces/[email protected]
// License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// File @openzeppelin/contracts/utils/structs/[email protected]
// License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
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
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
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

        /// @solidity memory-safe-assembly
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// File contracts/ihelp/PriceFeedProviderInterface.sol
// License-Identifier: GPL-3.0

pragma solidity ^0.8.9;




interface PriceFeedProviderInterface {
    struct DonationCurrency {
        string provider;
        string currency;
        address underlyingToken;
        address lendingAddress;
        address priceFeed;
        address connector;
    }
    
    function allowedDirectDonationCurrencies(address _currencyAddr) external view returns (bool);
    function numberOfDonationCurrencies() external view returns (uint256);
    function getDonationCurrencyAt(uint256 index) external view returns (DonationCurrency memory);
    function getUnderlyingTokenPrice(address _lendingAddress) external view returns (uint256, uint256);
    function addDonationCurrencies(DonationCurrency[] memory _newDonationCurrencies) external;
    function updateDonationCurrency(DonationCurrency memory _donationCurrency) external;
    function removeDonationCurrency(address _lendingAddress) external;
    function getDonationCurrency(address _lendingAddress) external view returns (DonationCurrency memory);
    function hasDonationCurrency(address _lendingAddress) external view returns (bool);
    function setDirectDonationCurrency(address _currencyAddress, bool status) external;
    function getAllDonationCurrencies() external view returns (DonationCurrency[] memory);

   /**
     * Calculates the APY for the lending token of a given protocol
     * @param _lendingAddress the address of the lending token
     * @param _blockTime the block time in millisconds of the chain this contract is deployed to
     * @return APR % value
     */
    function getCurrencyApr(address _lendingAddress, uint256 _blockTime) external view returns (uint256);
}

// File contracts/ihelp/iHelpTokenInterface.sol
// License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

interface iHelpTokenInterface is IERC20 {
    function interestGenerated() external view returns (uint256);
    function getUnderlyingToken() external view returns (IERC20);
    function contributorGeneratedInterest(address _user, address _charity) external view returns (uint256);
    function stakingPool() external view returns (address);
    function developmentPool() external view returns (address);
    function getPools() external view returns (address, address);
    function getFees() external view returns(uint256, uint256, uint256);
    function getDirectDonationFees() external view returns(uint256, uint256, uint256);
    function numberOfCharities() external view returns (uint256);
    function charityAt(uint256 index) external view returns (address);
    function priceFeedProvider() external view returns (address);
    function totalContributorGeneratedInterest() external view returns (uint256);
    function underlyingToken() external view returns (address);
    function totalCirculating() external view returns (uint256);
    function numberOfContributors() external view returns (uint256);
    function contributorAt(uint256 _index) external view returns(address, uint256);
    function notifyBalanceUpdate(address _account, uint256 _amount, bool _increased) external;
    function withdrawBulk(address[] calldata _charities) external;
    function hasCharity(address _charityAddress) external returns(bool);
    function contributionsAggregator() external view returns(address);    
}

// File contracts/ihelp/charitypools/CharityPoolInterface.sol
// License-Identifier: GPL-3.0

pragma solidity ^0.8.9;




interface CharityPoolInterface {    
    function name() external  view returns (string memory);
    function operator() external view returns (address);
    function charityWallet() external view returns (address);
    function swapperPool() external view returns (address);
    function holdingToken() external view returns (address);
    function totalDonationsUSD() external view returns (uint256);
    function transferOperator(address newOperator) external;
    function donationsRegistry(address _account) external view returns (CharityPoolUtils.DirectDonationsCounter memory);
    function setCharityWallet(address _newAddress) external;
    function developmentPool() external view returns (address);
    function stakingPool() external view returns (address);
    function depositNative(address _cTokenAddress, string memory _memo) external payable;
    function withdrawNative(address _cTokenAddress, uint256 _amount) external;
    function depositTokens(address _cTokenAddress, uint256 _amount, string memory _memo) external;
    function withdrawTokens(address _cTokenAddress, uint256 _amount) external;
    function withdrawAll(address _account) external;
    function directDonation(IERC20 _donationToken, uint256 _amount, string memory _memo) external;
    function claimInterest() external;
    function claimableInterest() external view returns (uint256);
    function collectOffChainInterest(address _destAddr, address _depositCurrency) external;
    function getUnderlying(address cTokenAddress) external view returns (IERC20);
    function balanceOf(address _account, address _cTokenAddress) external view returns (uint256);
    function estimatedInterestRate(uint256 _blocks, address _cTokenAddres) external view returns (uint256);
    function supplyRatePerBlock(address _cTokenAddress) external view returns (uint256);
    function getUnderlyingTokenPrice(address _cTokenAdddress) external view returns (uint256, uint256);
    function getContributors() external view returns (address[] memory);
    function accountedBalanceUSD() external view returns (uint256);
    function accountedBalanceUSDOfCurrencies(PriceFeedProviderInterface.DonationCurrency[] memory cTokens) external view returns(uint256);
    function totalInterestEarnedUSD() external view returns (uint256);
    function cTokenTotalUSDInterest(address _cTokenAddress) external view returns (uint256);
    function decimals(address _cTokenAddress) external view returns (uint8);
    function getAllDonationCurrencies() external view returns (PriceFeedProviderInterface.DonationCurrency[] memory);
    function balanceOfUSD(address _addr) external view returns (uint256);
    function numberOfContributors() external view returns (uint256);
    function contributorAt(uint256 index) external view returns (address);
    function directDonationNative(string memory _memo) external payable;
    function version() external pure returns (uint256);
    function balances(address _account, address _cToken) external view returns (uint256);
    function donationBalances(address _account, address _cToken) external view returns (uint256);
    function accountedBalances(address _account) external view returns (uint256);
    function totalInterestEarned(address _account) external view returns (uint256);
    function currentInterestEarned(address _account) external view returns (uint256);
    function lastTotalInterest(address _account) external view returns (uint256);
    function newTotalInterestEarned(address _account) external view returns (uint256);
    function redeemableInterest(address _account) external view returns (uint256);
    function priceFeedProvider() external view returns (PriceFeedProviderInterface);
    function ihelpToken() external view returns (iHelpTokenInterface);
    function incrementTotalInterest() external;
}

// File contracts/connectors/ConnectorInterface.sol
// License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface ConnectorInterface {
    function mint(address token, uint256 mintAmount) external returns (uint256); 
    function redeemUnderlying(address token, uint256 redeemAmount) external returns (uint256); 
    function accrueAndGetBalance(address cToken, address owner) external returns (uint256);
    function supplyRatePerBlock(address token) external view returns (uint256); 
    function totalSupply(address token) external view returns (uint256); 
    function balanceOf(address token, address user) external view  returns (uint256); 
    function underlying(address token) external view returns (address); 
    function lender() external  view returns (string memory); 
    function cTokenValueOfUnderlying(address token, uint256 amount) external  view returns (uint256); 
    function supplyAPR(address token, uint256 blockTime) external view returns (uint256); 
}

// File contracts/ihelp/SwapperUtils.sol
// License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

library SwapperUtils {
   
    function toScale(uint256 _fromScale, uint256 _toScale, uint256 _amount) external pure  returns (uint256) {
        if (_fromScale < _toScale) {
            _amount = _amount * safepow(10, _toScale - _fromScale);
        } else if (_fromScale > _toScale) {
            _amount = _amount / safepow(10, _fromScale - _toScale);
        }
        return _amount;
    }

    function safepow(uint256 base, uint256 exponent) public pure returns (uint256) {
        if (exponent == 0) {
            return 1;
        } else if (exponent == 1) {
            return base;
        } else if (base == 0 && exponent != 0) {
            return 0;
        } else {
            uint256 z = base;
            for (uint256 i = 1; i < exponent; i++) z = z * base;
            return z;
        }
    }
}

// File contracts/ihelp/SwapperInterface.sol
// License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

interface SwapperInterface {
    function nativeToken() external view returns (address);

    function swapByPath(
        address[] memory path,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _to
    ) external returns (uint256);

    function swap(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _to
    ) external returns (uint256);

    function getAmountOutMin(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) external view returns (uint256);

    function getNativeRoutedTokenPrice(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) external view returns (uint256);

    function getAmountsOutByPath(address[] memory _path, uint256 _amountIn) external view returns (uint256);
}

// File contracts/ihelp/rewards/CharityRewardDistributor.sol
// License-Identifier: GPL-3.0
pragma solidity ^0.8.9;


abstract contract CharityRewardDistributor {
    // Rewards stored grouped by lender token
    mapping(address => uint256) public rewardPerTokenStored;

    // Total rewards claimed, by underlying token
    mapping(address => uint256) public totalClaimed;

    // Total rewards awarded, by underlying token
    mapping(address => uint256) internal rewardAwarded;

    // We keep track of charity rewards depeding on their deposited amounts
    mapping(address => mapping(address => uint256)) internal claimableCharityReward;
    mapping(address => mapping(address => uint256)) public charityRewardPerTokenPaid;

    // Get total deposited lenderTokens
    function deposited(address _lenderTokenAddress) public view virtual returns (uint256);

    // Handle unclamied rewards transfer
    function sweepRewards(address _lenderTokenAddress, uint256 _amount) internal virtual;

    // Returns contributions for a given charity under a specific lender
    function balanceOfCharity(address _charityAddress, address _lenderTokenAddress) public virtual view returns (uint256);

    // Handle rewards transfer to their respective charity
    function transferReward(
        address _charityAddress,
        address _lenderTokenAddress,
        uint256 _amount
    ) internal virtual;

    // Returns the newly generated charity rewards
    function totalRewards(address _lenderTokenAddress) public view virtual returns (uint256);

    // Keeps track of rewards to be distributed to the charities
    modifier updateReward(address _charityAddress, address _lenderTokenAddress) {
        rewardPerTokenStored[_lenderTokenAddress] = rewardPerToken(_lenderTokenAddress);
        claimableCharityReward[_charityAddress][_lenderTokenAddress] = claimableRewardOf(_charityAddress, _lenderTokenAddress);

        charityRewardPerTokenPaid[_charityAddress][_lenderTokenAddress] = rewardPerTokenStored[_lenderTokenAddress];
        _;
    }

    // Returns the reward ratio for a given lender token
    function rewardPerToken(address _lenderTokenAddress) public view returns (uint256) {
        if (deposited(_lenderTokenAddress) == 0) {
            return 0;
        }
        return rewardPerTokenStored[_lenderTokenAddress];
    }

    function claimableRewardOf(address _charityAddress, address _lenderTokenAddress) public view returns (uint256) {
        uint256 _balance = balanceOfCharity(_charityAddress, _lenderTokenAddress);
        if (_balance == 0) {
            return claimableCharityReward[_charityAddress][_lenderTokenAddress];
        }

        return claimableCharityReward[_charityAddress][_lenderTokenAddress] + 
            (_balance * (rewardPerToken(_lenderTokenAddress) - charityRewardPerTokenPaid[_charityAddress][_lenderTokenAddress])) / 1e9;
    }

    function claimReward(address _charityAddress, address _lenderTokenAddress)
        public
        updateReward(_charityAddress, _lenderTokenAddress)
        virtual
        returns (uint256)
    {
        uint256 claimAmount = claimableRewardOf(_charityAddress, _lenderTokenAddress);
        _claim(claimAmount, _charityAddress, _lenderTokenAddress);
        return claimAmount;
    }

    function _claim(uint256 amount, address _charityAddress, address _lenderTokenAddress) internal {
        uint256 claimAmount = claimableRewardOf(_charityAddress, _lenderTokenAddress);
        if(amount > 0){
            require(claimAmount >= amount, "not enough claimable balance for amount");
        } else {
            amount = claimAmount;
        }

        claimableCharityReward[_charityAddress][_lenderTokenAddress] -= amount;
        totalClaimed[_lenderTokenAddress] += amount;

        transferReward(_charityAddress, _lenderTokenAddress, amount);
    }

    // Calculates the new reward ratio after new rewards are added to the pool
    function distributeRewards(address _lenderTokenAddress) internal {
        uint256 totalDeposited = deposited(_lenderTokenAddress);
        uint256 newRewards = currentCharityReward(_lenderTokenAddress);

        if (totalDeposited > 0) {
            rewardPerTokenStored[_lenderTokenAddress] += (newRewards * 1e9) / totalDeposited;
            rewardAwarded[_lenderTokenAddress] += newRewards;
        } else {
            rewardPerTokenStored[_lenderTokenAddress] = 0;
            sweepRewards(_lenderTokenAddress, newRewards);
        }
    }

    // Returns the newly generated charity rewards
    function currentCharityReward(address _lenderTokenAddress) internal virtual returns (uint256) {
        uint256 leftToClaim = rewardAwarded[_lenderTokenAddress] - totalClaimed[_lenderTokenAddress];
        return totalRewards(_lenderTokenAddress) - leftToClaim;
    }

    uint256[44] private __gap;
}

// File contracts/ihelp/rewards/IHelpRewardDistributor.sol
// License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

abstract contract IHelpRewardDistributor {
    /**
     * @notice This event is should be emited every time a contributor claims iHelp
     * @param contributor - The address of contributor that will receive the iHelp tokens
     * @param amount - The amount that was claimed
     */
    event IHelpClaimed(address contributor, uint256 amount);

    // Rewards stored
    uint256 public iHelpRewardPerTokenStored;

    // Total rewards claimed
    uint256 public totalIhelpClaimed;

    // We keep track of contributor rewards
    mapping(address => uint256) internal claimableContributorReward;
    mapping(address => uint256) internal claimedContributorReward;
    mapping(address => uint256) public iHelpRewardPerTokenPaid;

    // Get total contributions
    function contributions() public view virtual returns (uint256);

    // Get total contributions
    function contributionsOf(address _contributor) public view virtual returns (uint256);

    // Keeps track of rewards to be distributed to the charities
    modifier updateIHelpReward(address _contributor) {
        iHelpRewardPerTokenStored = rewardPerToken();
        claimableContributorReward[_contributor] = claimableIHelpRewardOf(_contributor);

        iHelpRewardPerTokenPaid[_contributor] = iHelpRewardPerTokenStored;
        _;
    }

    // Returns the reward ratio
    function rewardPerToken() public view returns (uint256) {
        if (contributions() == 0) {
            return 0;
        }
        return iHelpRewardPerTokenStored;
    }

    function claimableIHelpRewardOf(address _contributor) public view returns (uint256) {
        uint256 _balance = contributionsOf(_contributor);
        if (_balance == 0) {
            return claimableContributorReward[_contributor];
        }

        return
            claimableContributorReward[_contributor] +
            (_balance * (rewardPerToken() - iHelpRewardPerTokenPaid[_contributor])) /
            1e9;
    }

    function _claimIHelp(address _contributor , uint256 _amount) internal {
        uint256 totalClaimableAmount = claimableIHelpRewardOf(_contributor);
        require(totalClaimableAmount >= _amount, "ihelp-claim/insufficient balance");

        claimableContributorReward[_contributor] -= _amount;
        claimedContributorReward[_contributor] += _amount;
        emit IHelpClaimed(_contributor, _amount);
    }

    // Calculates the new reward ratio after new rewards are added
    function distributeIHelpRewards(uint256 _newRewards) internal {
        if (contributions() > 0) {
            iHelpRewardPerTokenStored += (_newRewards * 1e9) / contributions();
        } else {
            iHelpRewardPerTokenStored = 0;
        }
    }

    uint256[55] private __gap;
}

// File hardhat/[email protected]
// License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// File contracts/ihelp/rewards/ContributorInterestTracker.sol
// License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

abstract contract ContributorInterestTracker {
    // Rewards stored grouped by lender token
    mapping(address => uint256) public contributorInterestPerTokenStored;

    // Total rewards awarded, by underlying token
    mapping(address => uint256) internal contributorInterestAwarded;

    // We keep track of charity rewards depeding on their deposited amounts
    mapping(address => mapping(address => uint256)) internal contributorGeneratedInterest;
    mapping(address => mapping(address => uint256)) public contributorGeneratedInterestTracked;

    // Get total deposited lenderTokens
    function deposited(address _lenderTokenAddress) public view virtual returns (uint256);

    // Returns contributions for a given contributor under a specific lender token
    function balanceOfContributor(address _contributor, address _lenderTokenAddress) public virtual view returns (uint256);

    // Keeps track of the generated interest
    modifier updateContributorGeneratedInterest(address _lenderTokenAddress, address _contributor) {
        contributorInterestPerTokenStored[_lenderTokenAddress] = contributorInterestGeneratedPerToken(_lenderTokenAddress);
        contributorGeneratedInterest[_lenderTokenAddress][_contributor] = generatedInterestOfContributor(_lenderTokenAddress, _contributor);

        contributorGeneratedInterestTracked[_lenderTokenAddress][_contributor] = contributorInterestPerTokenStored[_lenderTokenAddress];
        _;
    }

    /**
     * Returns the total interest that was generated for a contributor by a given charity
     * @param _lenderTokenAddress - The lenderToken address to lookup
     * @param _contributor - The contributor address to lookup
     * @return The generated interest in the form of the lender token and it's coressponding 
     * holding token value         
     */
    function generatedInterestOfContributor(address _lenderTokenAddress, address _contributor) public view returns (uint256) {
        uint256 _balance = balanceOfContributor(_contributor, _lenderTokenAddress);
        if (_balance == 0) {
            return contributorGeneratedInterest[_lenderTokenAddress][_contributor];
        }

        return contributorGeneratedInterest[_lenderTokenAddress][_contributor] + 
            (_balance * (contributorInterestGeneratedPerToken(_lenderTokenAddress) - contributorGeneratedInterestTracked[_lenderTokenAddress][_contributor])) / 1e9;
    }

    function contributorInterestGeneratedPerToken(address _lenderTokenAddress) public view returns (uint256) {
        if (deposited(_lenderTokenAddress) == 0) {
            return 0;
        }
        return contributorInterestPerTokenStored[_lenderTokenAddress];
    }

    // Calculates the new reward ratio after new rewards are added to the pool
    function trackContributorInterest(address _lenderTokenAddress, uint256 _newInterest) internal  {
        uint256 totalDeposited = deposited(_lenderTokenAddress);
        if (totalDeposited > 0) {
            contributorInterestPerTokenStored[_lenderTokenAddress] += (_newInterest * 1e9) / totalDeposited;
            contributorInterestAwarded[_lenderTokenAddress] += _newInterest;
        } else {
            contributorInterestPerTokenStored[_lenderTokenAddress] = 0;
        }
    }

    uint256[46] private __gap;
}

// File contracts/ihelp/rewards/CharityInterestTracker.sol
// License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

abstract contract CharityInterestTracker {
    // Rewards stored grouped by lender token
    mapping(address => uint256) public charityInterestPerTokenStored;

    // Total rewards awarded, by underlying token
    mapping(address => uint256) internal charityInterestAwarded;

    // We keep track of charity rewards depeding on their deposited amounts
    mapping(address => mapping(address => uint256)) internal charityGeneratedInterest;
    mapping(address => mapping(address => uint256)) public charityGeneratedInterestTracked;

    // Get total deposited lenderTokens
    function deposited(address _lenderTokenAddress) public view virtual returns (uint256);

    // Returns contributions for a given contributor under a specific lender token
    function balanceOfCharity(address _charity, address _lenderTokenAddress) public virtual view returns (uint256);

    // Keeps track of the generated interest
    modifier updateCharityGeneratedInterest(address _lenderTokenAddress, address _charity) {
        charityInterestPerTokenStored[_lenderTokenAddress] = charityInterestGeneratedPerToken(_lenderTokenAddress);
        charityGeneratedInterest[_lenderTokenAddress][_charity] = generatedInterestOfCharity(_lenderTokenAddress, _charity);

        charityGeneratedInterestTracked[_lenderTokenAddress][_charity] = charityInterestPerTokenStored[_lenderTokenAddress];
        _;
    }

    /**
     * Returns the total interest that was generated for a contributor by a given charity
     * @param _lenderTokenAddress - The lenderToken address to lookup
     * @param _charity - The contributor address to lookup
     * @return The generated interest in the form of the lender token and it's coressponding 
     * holding token value
     */
    function generatedInterestOfCharity(address _lenderTokenAddress, address _charity) public view returns (uint256) {
        uint256 _balance = balanceOfCharity(_charity, _lenderTokenAddress);
        if (_balance == 0) {
            return charityGeneratedInterest[_lenderTokenAddress][_charity];
        }

        return charityGeneratedInterest[_lenderTokenAddress][_charity] + 
            (_balance * (charityInterestGeneratedPerToken(_lenderTokenAddress) - charityGeneratedInterestTracked[_lenderTokenAddress][_charity])) / 1e9;
    }

    function charityInterestGeneratedPerToken(address _lenderTokenAddress) public view returns (uint256) {
        if (deposited(_lenderTokenAddress) == 0) {
            return 0;
        }
        return charityInterestPerTokenStored[_lenderTokenAddress];
    }

    // Calculates the new reward ratio after new rewards are added to the pool
    function trackCharityInterest(address _lenderTokenAddress, uint256 _newInterest) internal  {
        uint256 totalDeposited = deposited(_lenderTokenAddress);
        if (totalDeposited > 0) {
            charityInterestPerTokenStored[_lenderTokenAddress] += (_newInterest * 1e9) / totalDeposited;
            charityInterestAwarded[_lenderTokenAddress] += _newInterest;
        } else {
            charityInterestPerTokenStored[_lenderTokenAddress] = 0;
        }
    }

    uint256[46] private __gap;
}

// File contracts/ihelp/ContributionsAggregatorInterface.sol
// License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface ContributionsAggregatorInterface {

    /**
     * @notice Returns the total lender tokens a contributor added
     * @param _contributorAddress - The address of the contributor
     * @param _lenderTokenAddress - The address of the lender token
     * @return The amount of underlying tokens that the contributor deposited
     */
    function contributorAccountedBalance(
        address _contributorAddress,
        address _lenderTokenAddress
    ) external returns(uint256);

    /**
     * @notice Returns the total lender tokens a charity added
     * @param _contributorAddress - The address of the charity
     * @param _lenderTokenAddress - The address of the lender token
     * @return The amount of underlying tokens that the charity deposited
     */
    function charityAccountedBalance(
        address _contributorAddress,
        address _lenderTokenAddress
    ) external returns(uint256);


    /**
     * @notice Deposits underlying tokens in exchange for lender tokens
     * @param _lenderTokenAddress - The address of the lender token
     * @param _charityAddress - The address of the charity that the end users places his contribution towards
     * @param _contributorAddress - The address of the contributor
     * @param _amount - The amount of underlying tokens that the contributor deposits
     */
    function deposit(
        address _lenderTokenAddress,
        address _charityAddress,
        address _contributorAddress,
        uint256 _amount
    ) external;

    /**
     * @notice Withdraws underlying tokens in exchange for lender tokens
     * @param _lenderTokenAddress - The address of the lender token
     * @param _charityAddress - The address of the charity that the end users places his contribution towards
     * @param _contributorAddress - The address of the contributor
     * @param _amount - The amount of underlying tokens that the contributor withdrwas
     * @param _destination - The end address that will receive the underlying tokens
     */
    function withdraw(
        address _lenderTokenAddress,
        address _charityAddress,
        address _contributorAddress,
        uint256 _amount,
        address _destination
    ) external;

    /**
     * Claims a iHelp reward amount in the name of a contributor
     * @param _contributor - The contributor
     * @param _amount - The amount of iHelp tokens to be claimed
     */
    function claimIHelpReward(address _contributor, uint256 _amount) external;

    /**
     * Claim all charity acummulated holding token rewards. The holding tokens will
     * be sent to the charity pool contract
     * @param _charityAddress - The address of the charity which we claim the rewards for
     */
    function claimAllCharityRewards(address _charityAddress) external;

    /**
     * Claim charity acummulated holding token rewards. The holding tokens will
     * be sent to the charity pool contract
     * @param _charityAddress - The address of the charity which we claim the rewards for
     * @param _lenderTokenAddress - The lender token address
     * @return The amount of interest claimed in the form of holding token
     */
    function claimReward(address _charityAddress, address _lenderTokenAddress) external returns (uint256);

    /**
     * Returns the total claimable interest in holding tokesn for charity
     * @param _charityAddress - The address of the charity
     * @return The claimable interest
     */
    function totalClaimableInterest(address _charityAddress) external view returns (uint256);

    /**
     * @notice Redeem intereset from the lenders. The intreset comes in the form of
     * underlying tokens (USDT, DAI, BUSD, etc)
     *
     * @dev The redeemed intrest will be swaped to holding tokens
     *
     * @param _lenderTokenAddress - The address of the lender token
     * @return The redeemed interest expressed in the form of holding tokens
     */
    function redeemInterest(address _lenderTokenAddress) external returns (uint256);

    /**
     * @notice Returns the total acumulated interest of all time
     *
     * @dev The redeemed intrest will in holding tokens
     *
     * @param _lenderTokenAddress - The address of the lender token
     * @return The redeemed interest expressed in the form of holding tokens
     */
    function totalRewards(address _lenderTokenAddress) external view returns (uint256);

    /**
     * @notice Returns the total acumulated interest  of all time in USD 
     *
     * @dev The redeemed intrest will in holding tokens. This also takes the collected fees into account
     *
     * @return The redeemed interest expressed in the form of dollars
     */
    function totalInterestCollected() external view  returns (uint256);

    /**
     *  Used to strategicaly inject interest
     *  @param _lenderTokenAddress - The interest must be associated with a lender token
     *  @param _interest - The interest amount in holding tokens
     */
    function injectInterest(address _lenderTokenAddress, uint256 _interest) external ;
}

// File contracts/ihelp/ContributionsAggregator.sol
// License-Identifier: GPL-3.0
pragma solidity ^0.8.9;







contract ContributionsAggregator is
    ContributionsAggregatorInterface,
    OwnableUpgradeable,
    CharityRewardDistributor,
    ContributorInterestTracker,
    CharityInterestTracker,
    IHelpRewardDistributor
{
    /**
     * @notice This event is should be emited every time a redeem of interest is made
     * @param lenderToken - The address of the token that generated the interest (aUSDT, cDAI, jUSDC, etc)
     * @param amount - The amount that was redeemed converted to holding tokens
     */
    event RedeemedInterest(address lenderToken, uint256 amount);

    // The total deposited amount for a given charity by its lender
    mapping(address => mapping(address => uint256)) public charityAccountedBalance;

    // The total deposited amount for a  contributor by lender
    mapping(address => mapping(address => uint256)) public contributorAccountedBalance;

    // We keep track of the total interest generated by a contributor
    mapping(address => uint256) internal _contributorGeneratedInterest;

    // The total deposited amount for a given charity by its lender
    mapping(address => uint256) internal _deposited;

    // Keeps track of holding token rewards for each lender protocol
    mapping(address => uint256) internal _totalRewards;

    // Keeps track of holding token fees for each lender protocol
    mapping(address => uint256) internal _totalFeesCollected;

    SwapperInterface internal swapper;
    iHelpTokenInterface public ihelpToken;

    modifier onlyCharity() {
        require(ihelpToken.hasCharity(msg.sender), "Aggregator/not-allowed");
        _;
    }

    modifier onlyIHelp() {
        require(isIHelp(msg.sender), "iHelp/not-allowed");
        _;
    }

    function isIHelp(address _account) internal view virtual returns (bool) {
        return _account == address(ihelpToken);
    }

    function initialize(address _ihelpAddress, address _swapperAddress) public initializer {
        __Ownable_init();
        ihelpToken = iHelpTokenInterface(_ihelpAddress);
        swapper = SwapperInterface(_swapperAddress);
    }

    /**
     * @notice Deposits underlying tokens in exchange for lender tokens
     * @param _lenderTokenAddress - The address of the lender token
     * @param _charityAddress - The address of the charity that the end users places his contribution towards
     * @param _contributorAddress - The address of the contributor
     * @param _amount - The amount of underlying tokens that the contributor deposits
     */
    function deposit(
        address _lenderTokenAddress,
        address _charityAddress,
        address _contributorAddress,
        uint256 _amount
    )
        external
        onlyCharity
        updateReward(_charityAddress, _lenderTokenAddress)
        updateIHelpReward(_contributorAddress)
        updateContributorGeneratedInterest(_lenderTokenAddress, _contributorAddress)
        updateCharityGeneratedInterest(_lenderTokenAddress, _charityAddress)
    {
        _deposit(_lenderTokenAddress, _charityAddress, _contributorAddress, _amount);
    }

    function _deposit(
        address _lenderTokenAddress,
        address _charityAddress,
        address _contributorAddress,
        uint256 _amount
    ) internal {
        require(_amount != 0, "Funding/deposit-zero");
        require(priceFeedProvider().hasDonationCurrency(_lenderTokenAddress), "Funding/invalid-token");

        // Update the total balance of cTokens of this contract
        charityAccountedBalance[_charityAddress][_lenderTokenAddress] += _amount;
        _deposited[_lenderTokenAddress] += _amount;

        // Keep track of each individual user contribution
        contributorAccountedBalance[_contributorAddress][_lenderTokenAddress] += _amount;

        ConnectorInterface connectorInstance = connector(_lenderTokenAddress);
        IERC20 underlyingToken = IERC20(connectorInstance.underlying(_lenderTokenAddress));

        require(
            underlyingToken.transferFrom(address(msg.sender), address(this), _amount),
            "Funding/underlying-transfer-fail"
        );

        require(underlyingToken.approve(address(connectorInstance), _amount), "Funding/approve");

        // Deposit into Lender
        require(connectorInstance.mint(_lenderTokenAddress, _amount) == 0, "Funding/supply");
    }

    /**
     * @notice Withdraws underlying tokens in exchange for lender tokens
     * @param _lenderTokenAddress - The address of the lender token
     * @param _charityAddress - The address of the charity that the end users places his contribution towards
     * @param _contributorAddress - The address of the contributor
     * @param _amount - The amount of underlying tokens that the contributor withdrwas
     * @param _destination - The end address that will receive the underlying tokens
     */
    function withdraw(
        address _lenderTokenAddress,
        address _charityAddress,
        address _contributorAddress,
        uint256 _amount,
        address _destination
    )
        external
        onlyCharity
        updateReward(_charityAddress, _lenderTokenAddress)
        updateIHelpReward(_contributorAddress)
        updateContributorGeneratedInterest(_lenderTokenAddress, _contributorAddress)
        updateCharityGeneratedInterest(_lenderTokenAddress, _charityAddress)
    {
        _withdraw(_lenderTokenAddress, _charityAddress, _contributorAddress, _amount, _destination);
    }

    function _withdraw(
        address _lenderTokenAddress,
        address _charityAddress,
        address _contributorAddress,
        uint256 _amount,
        address _destination
    ) internal {
        require(_amount <= charityAccountedBalance[_charityAddress][_lenderTokenAddress], "Funding/no-funds");

        charityAccountedBalance[_charityAddress][_lenderTokenAddress] -= _amount;
        contributorAccountedBalance[_contributorAddress][_lenderTokenAddress] -= _amount;
        _deposited[_lenderTokenAddress] -= _amount;

        ConnectorInterface connectorInstance = connector(_lenderTokenAddress);
        IERC20 underlyingToken = IERC20(connectorInstance.underlying(_lenderTokenAddress));

        // Allow connector to pull cTokens from this contracts
        uint256 lenderTokenAmount = connectorInstance.cTokenValueOfUnderlying(_lenderTokenAddress, _amount);
        require(IERC20(_lenderTokenAddress).approve(address(connectorInstance), lenderTokenAmount), "Funding/approve");

        uint256 balanceBefore = underlyingToken.balanceOf(address(this));
        require(connectorInstance.redeemUnderlying(_lenderTokenAddress, _amount) == 0, "Funding/supply");
        uint256 balanceNow = underlyingToken.balanceOf(address(this));

        assert(balanceNow - balanceBefore == _amount);

        require(underlyingToken.transfer(_destination, _amount), "Funding/underlying-transfer-fail");
    }

    /**
     * Claims a iHelp reward amount in the name of a contributor
     * @param _contributor - The contributor
     * @param _amount - The amount of iHelp tokens to be claimed
     */
    function claimIHelpReward(address _contributor, uint256 _amount)
        public
        virtual
        updateIHelpReward(_contributor)
        onlyIHelp
    {
        _claimIHelp(_contributor, _amount);
    }

    /**
     * @notice Redeem intereset from the lenders. The intreset comes in the form of
     * underlying tokens (USDT, DAI, BUSD, etc)
     *
     * @dev The redeemed intrest will be swaped to holding tokens
     *
     * @param _lenderTokenAddress - The address of the lender token
     * @return The redeemed interest expressed in the form of holding tokens
     */
    function redeemInterest(address _lenderTokenAddress) public returns (uint256) {
        return _redeemInterest(_lenderTokenAddress);
    }

    /**
     * This function clears all possible interest from the lender and distributes to the charity pool, dev and staking pools
     */
    function _redeemInterest(address _lenderTokenAddress) internal returns (uint256) {
        uint256 amount = interestEarned(_lenderTokenAddress);
        if (amount > 0) {
            ConnectorInterface connectorInstance = connector(_lenderTokenAddress);

            // Allow connector to pull cTokens from this contracts
            uint256 cTokenValueOfInterest = connectorInstance.cTokenValueOfUnderlying(_lenderTokenAddress, amount);
            require(
                IERC20(_lenderTokenAddress).approve(address(connectorInstance), cTokenValueOfInterest),
                "Funding/approve"
            );
            IERC20 underlyingToken = IERC20(connectorInstance.underlying(_lenderTokenAddress));

            uint256 balanceBefore = underlyingToken.balanceOf(address(this));
            connectorInstance.redeemUnderlying(_lenderTokenAddress, amount);
            uint256 balanceNow = underlyingToken.balanceOf(address(this));

            // Sanity check
            assert(balanceNow - balanceBefore == amount);

            address tokenaddress = address(underlyingToken);
            if (tokenaddress != holdingToken()) {
                // ensure minimum of 95% redeemed
                uint256 minAmount = (amount * 95) / 100;

                minAmount = SwapperUtils.toScale(
                    underlyingToken.decimals(),
                    IERC20(holdingToken()).decimals(),
                    minAmount
                );

                require(underlyingToken.approve(address(swapper), amount), "Funding/approve");
                amount = swapper.swap(tokenaddress, holdingToken(), amount, minAmount, address(this));
                console.log("SWAP result", underlyingToken.symbol(), amount, minAmount);
            }

            (uint256 devFeeShare, uint256 stakeFeeShare) = distributeInterestFees(amount);
            addRewards(_lenderTokenAddress, amount, (devFeeShare + stakeFeeShare));

            emit RedeemedInterest(_lenderTokenAddress, amount);
        }

        return amount;
    }

    function interestEarned(address _lenderTokenAddress) internal returns (uint256) {
        uint256 _balance = connector(_lenderTokenAddress).accrueAndGetBalance(_lenderTokenAddress, address(this));
        if (_balance > _deposited[_lenderTokenAddress]) {
            return _balance - _deposited[_lenderTokenAddress];
        } else {
            return 0;
        }
    }

    function addRewards(
        address _lenderTokenAddress,
        uint256 _interest,
        uint256 _fees
    ) internal {
        // We calculated the resulted rewards and update distribute them
        _totalRewards[_lenderTokenAddress] += _interest - _fees;
        _totalFeesCollected[_lenderTokenAddress] += _fees;
        distributeRewards(_lenderTokenAddress);
        trackContributorInterest(_lenderTokenAddress, _interest);
        trackCharityInterest(_lenderTokenAddress, _interest);
    }

    /**
     *  Used to strategicaly inject interest
     *  @param _lenderTokenAddress - The interest must be associated with a lender token
     *  @param _interest - The interest amount in holding tokens
     */
    function injectInterest(address _lenderTokenAddress, uint256 _interest) public {
        require(priceFeedProvider().hasDonationCurrency(_lenderTokenAddress), "not-found/lender");
        require(IERC20(holdingToken()).transferFrom(msg.sender, address(this), _interest), "Funding/transfer");

        (uint256 devFeeShare, uint256 stakeFeeShare) = distributeInterestFees(_interest);
        addRewards(_lenderTokenAddress, _interest, (devFeeShare + stakeFeeShare));
    }

    function distributeInterestFees(uint256 _amount) internal returns (uint256, uint256) {
        (uint256 devFee, uint256 stakeFee, ) = ihelpToken.getFees();
        uint256 devFeeShare = (_amount * devFee) / 1000;
        uint256 stakeFeeShare = (_amount * stakeFee) / 1000;

        (address _developmentPool, address _stakingPool) = ihelpToken.getPools();
        if (devFeeShare > 0) {
            require(IERC20(holdingToken()).transfer(_developmentPool, devFeeShare), "Funding/transfer");
        }

        if (stakeFeeShare > 0) {
            require(IERC20(holdingToken()).transfer(_stakingPool, stakeFeeShare), "Funding/transfer");
        }

        return (devFeeShare, stakeFeeShare);
    }

    function deposited(address _lenderTokenAddress)
        public
        view
        virtual
        override(CharityInterestTracker, CharityRewardDistributor, ContributorInterestTracker)
        returns (uint256)
    {
        return _deposited[_lenderTokenAddress];
    }

    /**
     * Calculates the usd value of an underlying token
     * @param _lenderTokenAddress - Address of the lending provider
     * @param _amount - The amount to be converted
     */
    function usdValueoOfUnderlying(address _lenderTokenAddress, uint256 _amount) public view virtual returns (uint256) {
        (uint256 tokenPrice, uint256 priceDecimals) = priceFeedProvider().getUnderlyingTokenPrice(_lenderTokenAddress);

        uint256 valueUSD = _amount * tokenPrice;
        valueUSD = valueUSD / SwapperUtils.safepow(10, priceDecimals);

        ConnectorInterface connectorInstance = connector(_lenderTokenAddress);
        IERC20 underlyingToken = IERC20(connectorInstance.underlying(_lenderTokenAddress));

        return SwapperUtils.toScale(underlyingToken.decimals(), IERC20(holdingToken()).decimals(), valueUSD);
    }

    /**
     * Returns the total value in USD of all underlying contributions
     */
    function contributions() public view override returns (uint256) {
        uint256 usdValue;
        for (uint256 i = 0; i < priceFeedProvider().numberOfDonationCurrencies(); i++) {
            address lenderTokenAddress = priceFeedProvider().getDonationCurrencyAt(i).lendingAddress;
            usdValue += usdValueoOfUnderlying(lenderTokenAddress, _deposited[lenderTokenAddress]);
        }
        return usdValue;
    }

    /**
     * Returns the total value in USD of a contributor deposits
     */
    function contributionsOf(address _contributor) public view override returns (uint256) {
        uint256 usdValue;
        for (uint256 i = 0; i < priceFeedProvider().numberOfDonationCurrencies(); i++) {
            address lenderTokenAddress = priceFeedProvider().getDonationCurrencyAt(i).lendingAddress;
            usdValue += usdValueoOfUnderlying(
                lenderTokenAddress,
                contributorAccountedBalance[_contributor][lenderTokenAddress]
            );
        }
        return usdValue;
    }

    function distributeIHelp(uint256 _newTokens) external onlyIHelp {
        distributeIHelpRewards(_newTokens);
    }

    function balanceOfCharity(address _charityAddress, address _lenderTokenAddress)
        public
        view
        override(CharityRewardDistributor, CharityInterestTracker)
        returns (uint256)
    {
        return charityAccountedBalance[_charityAddress][_lenderTokenAddress];
    }

    function balanceOfContributor(address _contributorAddress, address _lenderTokenAddress)
        public
        view
        override
        returns (uint256)
    {
        return contributorAccountedBalance[_contributorAddress][_lenderTokenAddress];
    }

    function totalRewards(address _lenderTokenAddress)
        public
        view
        virtual
        override(CharityRewardDistributor, ContributionsAggregatorInterface)
        returns (uint256)
    {
        return _totalRewards[_lenderTokenAddress];
    }

    function totalInterestCollected() public view virtual override returns (uint256) {
        uint256 usdValue;
        for (uint256 i = 0; i < priceFeedProvider().numberOfDonationCurrencies(); i++) {
            address lenderTokenAddress = priceFeedProvider().getDonationCurrencyAt(i).lendingAddress;
            usdValue += usdValueoOfUnderlying(
                lenderTokenAddress,
                _totalRewards[lenderTokenAddress] + _totalFeesCollected[lenderTokenAddress]
            );
        }
        return usdValue;
    }

    /**
     * Claim all charity acummulated holding token rewards. The holding tokens will
     * be sent to the charity pool contract
     * @param _charityAddress - The address of the charity which we claim the rewards for
     */
    function claimAllCharityRewards(address _charityAddress) external {
        for (uint256 i = 0; i < priceFeedProvider().numberOfDonationCurrencies(); i++) {
            address lenderTokenAddress = priceFeedProvider().getDonationCurrencyAt(i).lendingAddress;
            _claim(0, _charityAddress, lenderTokenAddress);
        }
    }

    /**
     * Returns the total claimable interest in holding tokens for charity
     * @param _charityAddress - The address of the charity
     * @return The claimable interest
     */
    function totalClaimableInterest(address _charityAddress) external view returns (uint256) {
        uint256 total;
        for (uint256 i = 0; i < priceFeedProvider().numberOfDonationCurrencies(); i++) {
            address lenderTokenAddress = priceFeedProvider().getDonationCurrencyAt(i).lendingAddress;
            total += claimableRewardOf(_charityAddress, lenderTokenAddress);
        }
        return total;
    }

    function sweepRewards(address, uint256 _amount) internal override {
        (address _developmentPool, ) = ihelpToken.getPools();
        require(IERC20(holdingToken()).transfer(_developmentPool, _amount), "Funding/transfer");
    }

    function transferReward(
        address _charityAddress,
        address _lenderTokenAddress,
        uint256 _amount
    ) internal virtual override {
        _totalRewards[_lenderTokenAddress] -= _amount;
        require(IERC20(holdingToken()).transfer(_charityAddress, _amount), "Funding/transfer");
    }

    function priceFeedProvider() public view returns (PriceFeedProviderInterface) {
        return PriceFeedProviderInterface(ihelpToken.priceFeedProvider());
    }

    function holdingToken() public view returns (address) {
        return ihelpToken.underlyingToken();
    }

    /**
     * @notice Returns the connector instance for a given lender
     */
    function connector(address _cTokenAddress) internal view returns (ConnectorInterface) {
        return ConnectorInterface(priceFeedProvider().getDonationCurrency(_cTokenAddress).connector);
    }

    function claimReward(address _charityAddress, address _lenderTokenAddress)
        public
        override(CharityRewardDistributor, ContributionsAggregatorInterface)
        returns (uint256)
    {
        return CharityRewardDistributor.claimReward(_charityAddress, _lenderTokenAddress);
    }
}

// File contracts/analytics/AnalyticsUtils.sol
// License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

library AnalyticsUtils {
    struct GeneralStats {
        uint256 totalValueLocked;
        uint256 totalInterestGenerated;
        uint256 totalHelpers;
        uint256 totalCharities;
        uint256 totalDirectDonations;
    }

    struct CharityStats {
        uint256 totalValueLocked;
        uint256 totalYieldGenerated;
        uint256 numerOfContributors;
        uint256 totalDirectDonations;
    }

    struct IndividualCharityContributionInfo {
        string charityName;
        address charityAddress;
        uint256 totalContributions;
        uint256 totalDonations;
        uint256 totalInterestGenerated;
    }

     struct CharityContributor {
        address contributorAddress;
        uint256 totalContributions;
        uint256 totalDonations;
        uint256 totalDonationsCount;
        uint256 totalInterestGenerated;
    }

    struct StakingPoolStats {
        uint256 iHelpTokensInCirculation;
        uint256 iHelpStaked;
    }

    struct UserStats {
        uint256 totalDonationsCount;
        uint256 totalDirectDonations;
        uint256 totalInterestGenerated;
        uint256 totalContributions;
    }

    struct WalletInfo {
        uint256 iHelpBalance;
        uint256 xHelpBalance;
        uint256 stakingAllowance;
    }

    struct UserCharityContributions {
        string charityName;
        address charityAddress;
        uint256 totalContributions;
        uint256 totalDonations;
        uint256 yieldGenerated;
        UserCharityTokenContributions[] tokenStatistics;
    }

    struct UserCharityTokenContributions {
        address tokenAddress;
        string currency;
        uint256 totalContributions;
        uint256 totalContributionsUSD;
    }

    struct CharityBalanceInfo {
        address charityAddress;
        string charityName;
        uint256 balance;
    }

    struct WalletBalance {
        address tokenAddress;
        string currency;
        uint256 balance;
    }

    struct WalletAllowance {
        address tokenAddress;
        string currency;
        uint256 allowance;
    }

    struct DonationCurrencyDetails {
        string provider;
        string currency;
        address underlyingToken;
        address lendingAddress;
        address priceFeed;
        uint256 price;
        uint256 priceDecimals;
        uint256 decimals;
        uint256 apr;
    }
}

// File contracts/analytics/IAnalytics.sol
// License-Identifier: GPL-3.0
pragma solidity ^0.8.9;




interface IAnalytics {
    /**
     * Calaculates the generated interest for a given charity
     */
    function generatedInterest(address _charityPool) external view returns (uint256);

    /**
     * Calaculates the total generated interest for all charities
     */
    function totalGeneratedInterest(iHelpTokenInterface _iHelp) external view returns (uint256);

    /**
     * Calaculates the total generated interest for a given yield protocol
     */
    function getYieldProtocolGeneratedInterest(iHelpTokenInterface _iHelp, address _cTokenAddress)
        external
        view
        returns (uint256);

    /**
     * Calaculates the total generated yield for a given charity
     */
    function getYieldProtocolGeneratedInterestByCharity(CharityPoolInterface _charity) external view returns (uint256);

    /**
     * Calaculates the total generated interest for a given underlying currency
     */
    function getUnderlyingCurrencyGeneratedInterest(
        iHelpTokenInterface _iHelp,
        address _underlyingCurrency
    ) external view returns (uint256);

    /**
     * Calaculates generated interest for a given user
     */
    function getUserGeneratedInterest(
        iHelpTokenInterface _iHelp,
        address _account
    ) external view returns (uint256);

    /**
     * Calaculates the total generated interest for a all users
     */
    function getTotalUserGeneratedInterest(iHelpTokenInterface _iHelp) external view returns (uint256);

    /**
     * Calaculates the total locked value over all charities
     */
    function totalLockedValue(
        iHelpTokenInterface _iHelp
    ) external view returns (uint256);

    /**
     * Calaculates the total locked value of a charity
     */
    function totalCharityLockedValue(CharityPoolInterface _charity) external view returns (uint256);

    /**
     * Get total number of helpers
     */
    function totalHelpers(iHelpTokenInterface _iHelp) external view returns (uint256);

    /**
     * Get number of helpers in a given charity
     */
    function totalHelpersInCharity(CharityPoolInterface _charity) external view returns (uint256);

    /**
     * Get the total value of direct donations from all charities
     */
    function getTotalDirectDonations(
        iHelpTokenInterface _iHelp,
        uint256 _offset,
        uint256 _limit
    ) external view returns (uint256);

    /**
     * Get the total USD value of direct donations for a helper
     */
    function getUserTotalDirectDonations(
        iHelpTokenInterface _iHelp,
        address _user,
        uint256 _offset,
        uint256 _limit
    ) external view returns (uint256);

    /**
     * Get the total value of direct donations for a helper
     */
    function getUserDirectDonationsStats(CharityPoolInterface _charity, address _user)
        external
        view
        returns (CharityPoolUtils.DirectDonationsCounter memory);

    /**
     * Return general statistics
     */
    function generalStats(
        iHelpTokenInterface _iHelp,
        uint256 _offset,
        uint256 _limit
    ) external view returns (AnalyticsUtils.GeneralStats memory);

    /**
     * Return general statistics for a given charity
     */
    function charityStats(CharityPoolInterface _charity) external view returns (AnalyticsUtils.CharityStats memory);

    /**
     * Return general statistics for a given user
     */
    function userStats(
        iHelpTokenInterface _iHelp,
        address _user,
        uint256 _offset,
        uint256 _limit
    ) external view returns (AnalyticsUtils.UserStats memory);

    /**
     * Return iHelp related wallet information
     */
    function walletInfo(
        iHelpTokenInterface _iHelp,
        address _user,
        address _xHelpAddress
    ) external view returns (AnalyticsUtils.WalletInfo memory);

    /**
     * Returns an array with all the charity pools and their contributions
     */
    function getCharityPoolsWithContributions(
        iHelpTokenInterface _iHelp,
        uint256 _offset,
        uint256 _limit
    ) external view returns (AnalyticsUtils.IndividualCharityContributionInfo[] memory);

    /**
     * Returns an array that contains the charity contribution info for a given user
     */
    function getUserContributionsPerCharity(
        iHelpTokenInterface _iHelp,
        address _user,
        uint256 _offset,
        uint256 _limit
    ) external view returns (AnalyticsUtils.UserCharityContributions[] memory);

    /**
     * Returns an array that contains the charity contribution info for a given user
     */
    function getUserTokenContributionsPerCharity(CharityPoolInterface _charity, address _user)
        external
        view
        returns (AnalyticsUtils.UserCharityTokenContributions[] memory);

    /**
     * Returns an array that contains the charity donations info for a given user
     */
    function getUserTokenDonationsPerCharity(CharityPoolInterface _charity, address _user)
        external
        view
        returns (AnalyticsUtils.UserCharityTokenContributions[] memory);

    /**
     * Returns the user wallet balances of all supported donation currencies
     */
    function getUserWalletBalances(iHelpTokenInterface _iHelp, address _user)
        external
        view
        returns (AnalyticsUtils.WalletBalance[] memory);

    /**
     * Get charity pools balances and addresses
     */
    function getCharityPoolsAddressesAndBalances(
        iHelpTokenInterface _iHelp,
        uint256 _offset,
        uint256 _limit
    ) external view returns (AnalyticsUtils.CharityBalanceInfo[] memory);

    /**
     * Get the state of the staking pool
     */
    function stakingPoolState(iHelpTokenInterface _iHelp, address xHelpAddress)
        external
        view
        returns (AnalyticsUtils.StakingPoolStats memory);
}

// File contracts/analytics/Analytics.sol
// License-Identifier: GPL-3.0
pragma solidity ^0.8.9;







/**
 * @title Analytics
 */
contract Analytics is IAnalytics {
    /**
     * Calaculates the generated interest for a given charity
     */
    function generatedInterest(address _charityPool) external view override returns (uint256) {
        return CharityPoolInterface(_charityPool).totalInterestEarnedUSD();
    }

    /**
     * Calaculates the total generated interest for all charities
     */
    function totalGeneratedInterest(iHelpTokenInterface _iHelp) public view override returns (uint256) {
        return contributionsAggregator(_iHelp).totalInterestCollected();
    }

    /**
     * Calaculates the total generated interest for a all users
     */
    function getTotalUserGeneratedInterest(iHelpTokenInterface _iHelp) external view override returns (uint256) {
        return _iHelp.totalContributorGeneratedInterest();
    }

    /**
     * Calaculates the total generated interest for a given yield protocol
     */
    function getYieldProtocolGeneratedInterest(iHelpTokenInterface _iHelp, address _cTokenAddress)
        external
        view
        override
        returns (uint256)
    {
        return contributionsAggregator(_iHelp).totalRewards(_cTokenAddress);
    }

    /**
     * Calaculates the total generated yield for a given charity
     */
    function getYieldProtocolGeneratedInterestByCharity(CharityPoolInterface _charity)
        external
        view
        override
        returns (uint256)
    {
        return _charity.totalInterestEarnedUSD();
    }

    /**
     * Calaculates the total generated interest for a given underlying currency
     */
    function getUnderlyingCurrencyGeneratedInterest(iHelpTokenInterface _iHelp, address _underlyingCurrency)
        external
        view
        override
        returns (uint256)
    {
        uint256 result;
        uint256 cTokens = priceFeedProvider(_iHelp).numberOfDonationCurrencies();

        for (uint256 i = 0; i < cTokens; i++) {
            address underlyingToken = priceFeedProvider(_iHelp).getDonationCurrencyAt(i).underlyingToken;

            if (underlyingToken == _underlyingCurrency) {
                address cTokenAddress = priceFeedProvider(_iHelp).getDonationCurrencyAt(i).lendingAddress;
                result += contributionsAggregator(_iHelp).totalRewards(cTokenAddress);
            }
        }

        return result;
    }

    /**
     * Calaculates generated interest for a given user
     */
    function getUserGeneratedInterest(iHelpTokenInterface _iHelp, address _account)
        external
        view
        override
        returns (uint256)
    {
        uint256 result;
        uint256 cTokens = priceFeedProvider(_iHelp).numberOfDonationCurrencies();
        for (uint256 i = 0; i < cTokens; i++) {
            address lendingAddress = priceFeedProvider(_iHelp).getDonationCurrencyAt(i).lendingAddress;
            result += contributionsAggregator(_iHelp).generatedInterestOfContributor(lendingAddress, _account);
        }
        return result;
    }

    /**
     * Calaculates the total locked value over all charities
     */
    function totalLockedValue(iHelpTokenInterface _iHelp) external view override returns (uint256) {
        return contributionsAggregator(_iHelp).contributions();
    }

    /**
     * Calaculates the total locked value of a charity
     */
    function totalCharityLockedValue(CharityPoolInterface _charity) external view override returns (uint256) {
        return _charity.accountedBalanceUSD();
    }

    /**
     * Get total number of helpers
     */
    function totalHelpers(iHelpTokenInterface _iHelp) external view override returns (uint256) {
        return _iHelp.numberOfContributors();
    }

    /**
     * Get number of helpers in a given charity
     */
    function totalHelpersInCharity(CharityPoolInterface _charity) external view override returns (uint256) {
        return _charity.numberOfContributors();
    }

    /**
     * Get the total value of direct donations from all charities
     */
    function getTotalDirectDonations(
        iHelpTokenInterface _iHelp,
        uint256 _offset,
        uint256 _limit
    ) external view override returns (uint256) {
        (_offset, _limit) = paginationChecks(_iHelp.numberOfCharities, _offset, _limit);

        uint256 result;
        for (uint256 index = _offset; index < _offset + _limit; index++) {
            CharityPoolInterface charity = CharityPoolInterface(payable(_iHelp.charityAt(index)));
            result += charity.totalDonationsUSD();
        }
        return result;
    }

    /**
     * Get the total USD value of direct donations for a helper
     */
    function getUserTotalDirectDonations(
        iHelpTokenInterface _iHelp,
        address _user,
        uint256 _offset,
        uint256 _limit
    ) external view override returns (uint256) {
        (_offset, _limit) = paginationChecks(_iHelp.numberOfCharities, _offset, _limit);

        uint256 result;
        for (uint256 index = _offset; index < _offset + _limit; index++) {
            CharityPoolInterface charity = CharityPoolInterface(payable(_iHelp.charityAt(index)));
            CharityPoolUtils.DirectDonationsCounter memory registry = charity.donationsRegistry(_user);
            result += registry.totalContribUSD;
        }
        return result;
    }

    /**
     * Get the total value of direct donations for a helper
     */
    function getUserDirectDonationsStats(CharityPoolInterface _charity, address _user)
        public
        view
        override
        returns (CharityPoolUtils.DirectDonationsCounter memory)
    {
        return _charity.donationsRegistry(_user);
    }

    /**
     * Return general statistics
     */
    function generalStats(
        iHelpTokenInterface _iHelp,
        uint256 _offset,
        uint256 _limit
    ) public view override returns (AnalyticsUtils.GeneralStats memory) {
        (_offset, _limit) = paginationChecks(_iHelp.numberOfCharities, _offset, _limit);
        AnalyticsUtils.GeneralStats memory result;
        result.totalCharities = _limit;
        result.totalHelpers += _iHelp.numberOfContributors();
        for (uint256 index = _offset; index < _offset + _limit; index++) {
            CharityPoolInterface charity = CharityPoolInterface(payable(_iHelp.charityAt(index)));
            result.totalValueLocked += charity.accountedBalanceUSD();
            result.totalInterestGenerated += charity.totalInterestEarnedUSD();
            result.totalDirectDonations += charity.totalDonationsUSD();
        }
        return result;
    }

    /**
     * Return general statistics for a given charity
     */
    function charityStats(CharityPoolInterface _charity)
        public
        view
        override
        returns (AnalyticsUtils.CharityStats memory)
    {
        AnalyticsUtils.CharityStats memory result = AnalyticsUtils.CharityStats({
            totalValueLocked: _charity.accountedBalanceUSD(),
            totalYieldGenerated: _charity.totalInterestEarnedUSD(),
            numerOfContributors: _charity.numberOfContributors(),
            totalDirectDonations: _charity.totalDonationsUSD()
        });

        return result;
    }

    /**
     * Return general statistics for a given user
     */
    function userStats(
        iHelpTokenInterface _iHelp,
        address _user,
        uint256 _offset,
        uint256 _limit
    ) public view override returns (AnalyticsUtils.UserStats memory) {
        (_offset, _limit) = paginationChecks(_iHelp.numberOfCharities, _offset, _limit);

        AnalyticsUtils.UserStats memory result;

        for (uint256 index = _offset; index < _offset + _limit; index++) {
            CharityPoolInterface charity = CharityPoolInterface(payable(_iHelp.charityAt(index)));
            CharityPoolUtils.DirectDonationsCounter memory registry = charity.donationsRegistry(_user);

            result.totalContributions += charity.balanceOfUSD(_user);
            result.totalDirectDonations += registry.totalContribUSD;
            result.totalDonationsCount += registry.totalDonations;
            result.totalInterestGenerated += _iHelp.contributorGeneratedInterest(_user, address(charity));
        }

        return result;
    }

    /**
     * Return general statistics for a given user
     */
    function walletInfo(
        iHelpTokenInterface _iHelp,
        address _user,
        address _xHelpAddress
    ) external view override returns (AnalyticsUtils.WalletInfo memory) {
        AnalyticsUtils.WalletInfo memory result;
        result.iHelpBalance = _iHelp.balanceOf(_user);
        result.xHelpBalance = IERC20(_xHelpAddress).balanceOf(_user);
        result.stakingAllowance = _iHelp.allowance(_user, _xHelpAddress);
        return result;
    }

    /**
     * Returns an array with all the charity pools and their contributions
     */
    function getCharityPoolsWithContributions(
        iHelpTokenInterface _iHelp,
        uint256 _offset,
        uint256 _limit
    ) external view returns (AnalyticsUtils.IndividualCharityContributionInfo[] memory) {
        (_offset, _limit) = paginationChecks(_iHelp.numberOfCharities, _offset, _limit);

        AnalyticsUtils.IndividualCharityContributionInfo[]
            memory result = new AnalyticsUtils.IndividualCharityContributionInfo[](_limit);

        for (uint256 index = _offset; index < _offset + _limit; index++) {
            CharityPoolInterface charity = CharityPoolInterface(payable(_iHelp.charityAt(index)));
            result[index] = AnalyticsUtils.IndividualCharityContributionInfo({
                charityAddress: address(charity),
                charityName: charity.name(),
                totalContributions: charity.accountedBalanceUSD(),
                totalDonations: charity.totalDonationsUSD(),
                totalInterestGenerated: charity.totalInterestEarnedUSD()
            });
        }
        return result;
    }

    /**
     * Returns an array that contains the charity contribution info for a given user
     */
    function getUserContributionsPerCharity(
        iHelpTokenInterface _iHelp,
        address _user,
        uint256 _offset,
        uint256 _limit
    ) external view returns (AnalyticsUtils.UserCharityContributions[] memory) {
        (_offset, _limit) = paginationChecks(_iHelp.numberOfCharities, _offset, _limit);

        AnalyticsUtils.UserCharityContributions[] memory result = new AnalyticsUtils.UserCharityContributions[](_limit);

        uint256 count = 0;
        for (uint256 index = _offset; index < _offset + _limit; index++) {
            CharityPoolInterface charity = CharityPoolInterface(payable(_iHelp.charityAt(index)));
            uint256 userDonations = charity.donationsRegistry(_user).totalContribUSD;
            uint256 normalContributions = charity.balanceOfUSD(_user);
            uint256 _yieldGenerated = _iHelp.contributorGeneratedInterest(_user, address(charity));

            result[count] = AnalyticsUtils.UserCharityContributions({
                charityAddress: address(charity),
                charityName: charity.name(),
                totalContributions: normalContributions,
                totalDonations: userDonations,
                yieldGenerated: _yieldGenerated,
                tokenStatistics: getUserTokenContributionsPerCharity(charity, _user)
            });

            count += 1;
        }
        return result;
    }

    /**
     * Returns an array that contains the charity contribution info for a given user
     */
    function getUserTokenContributionsPerCharity(CharityPoolInterface _charity, address _user)
        public
        view
        returns (AnalyticsUtils.UserCharityTokenContributions[] memory)
    {
        PriceFeedProviderInterface.DonationCurrency[] memory currencies = _charity.getAllDonationCurrencies();

        AnalyticsUtils.UserCharityTokenContributions[]
            memory result = new AnalyticsUtils.UserCharityTokenContributions[](currencies.length);

        for (uint256 index = 0; index < currencies.length; index++) {
            address cTokenAddress = currencies[index].lendingAddress;
            (uint256 price, uint256 decimals) = _charity.getUnderlyingTokenPrice(cTokenAddress);
            uint256 contribution = _charity.balances(_user, cTokenAddress);
            uint256 contributionUSD = (contribution * price) / 10**decimals;
            result[index] = AnalyticsUtils.UserCharityTokenContributions({
                tokenAddress: currencies[index].lendingAddress,
                currency: currencies[index].currency,
                totalContributions: contribution,
                totalContributionsUSD: contributionUSD
            });
        }
        return result;
    }

    /**
     * Returns an array that contains the charity donations info for a given user
     */
    function getUserTokenDonationsPerCharity(CharityPoolInterface _charity, address _user)
        external
        view
        returns (AnalyticsUtils.UserCharityTokenContributions[] memory)
    {
        PriceFeedProviderInterface.DonationCurrency[] memory currencies = PriceFeedProviderInterface(
            _charity.priceFeedProvider()
        ).getAllDonationCurrencies();

        AnalyticsUtils.UserCharityTokenContributions[]
            memory result = new AnalyticsUtils.UserCharityTokenContributions[](currencies.length);

        for (uint256 index = 0; index < currencies.length; index++) {
            address cTokenAddress = currencies[index].lendingAddress;
            (uint256 price, uint256 decimals) = _charity.getUnderlyingTokenPrice(cTokenAddress);
            uint256 contribution = _charity.donationBalances(_user, cTokenAddress);
            uint256 contributionUSD = (contribution * price) / 10**decimals;

            result[index] = AnalyticsUtils.UserCharityTokenContributions({
                tokenAddress: currencies[index].lendingAddress,
                currency: currencies[index].currency,
                totalContributions: contribution,
                totalContributionsUSD: contributionUSD
            });
        }
        return result;
    }

    /**
     * Returns the user wallet balances of all supported donation currencies
     */
    function getUserWalletBalances(iHelpTokenInterface _iHelp, address _user)
        external
        view
        returns (AnalyticsUtils.WalletBalance[] memory)
    {
        PriceFeedProviderInterface.DonationCurrency[] memory currencies = PriceFeedProviderInterface(
            _iHelp.priceFeedProvider()
        ).getAllDonationCurrencies();

        AnalyticsUtils.WalletBalance[] memory result = new AnalyticsUtils.WalletBalance[](currencies.length);
        for (uint256 index = 0; index < currencies.length; index++) {
            result[index] = AnalyticsUtils.WalletBalance({
                tokenAddress: currencies[index].underlyingToken,
                currency: currencies[index].currency,
                balance: IERC20(currencies[index].underlyingToken).balanceOf(address(_user))
            });
        }

        return result;
    }

    /**
     * Get charity pools balances and addresses
     */
    function getCharityPoolsAddressesAndBalances(
        iHelpTokenInterface _iHelp,
        uint256 _offset,
        uint256 _limit
    ) external view returns (AnalyticsUtils.CharityBalanceInfo[] memory) {
        (_offset, _limit) = paginationChecks(_iHelp.numberOfCharities, _offset, _limit);

        AnalyticsUtils.CharityBalanceInfo[] memory result = new AnalyticsUtils.CharityBalanceInfo[](_limit);

        for (uint256 index = _offset; index < _offset + _limit; index++) {
            CharityPoolInterface charity = CharityPoolInterface(payable(_iHelp.charityAt(index)));

            result[index] = AnalyticsUtils.CharityBalanceInfo({
                charityAddress: address(charity),
                charityName: charity.name(),
                balance: IERC20(_iHelp.underlyingToken()).balanceOf(address(charity))
            });
        }

        return result;
    }

    /**
     * Get the state of the staking pool
     */
    function stakingPoolState(iHelpTokenInterface _iHelp, address xHelpAddress)
        external
        view
        returns (AnalyticsUtils.StakingPoolStats memory)
    {
        return
            AnalyticsUtils.StakingPoolStats({
                iHelpTokensInCirculation: _iHelp.totalCirculating(),
                iHelpStaked: _iHelp.balanceOf(xHelpAddress)
            });
    }

    /**
     * Get user allowance for all donation currencies
     */
    function getDonationCurrencyAllowances(CharityPoolInterface _charity, address _user)
        external
        view
        returns (AnalyticsUtils.WalletAllowance[] memory)
    {
        PriceFeedProviderInterface.DonationCurrency[] memory currencies = PriceFeedProviderInterface(
            _charity.priceFeedProvider()
        ).getAllDonationCurrencies();

        AnalyticsUtils.WalletAllowance[] memory result = new AnalyticsUtils.WalletAllowance[](currencies.length);

        for (uint256 index = 0; index < currencies.length; index++) {
            result[index] = AnalyticsUtils.WalletAllowance({
                tokenAddress: currencies[index].underlyingToken,
                currency: currencies[index].currency,
                allowance: IERC20(currencies[index].underlyingToken).allowance(_user, address(_charity))
            });
        }

        return result;
    }

    /**
     * Get all the configured donation currencies
     */
    function getSupportedCurrencies(iHelpTokenInterface _iHelp, uint256 _blockTime)
        public
        view
        returns (AnalyticsUtils.DonationCurrencyDetails[] memory)
    {
        PriceFeedProviderInterface _priceFeedProvider = PriceFeedProviderInterface(_iHelp.priceFeedProvider());

        PriceFeedProviderInterface.DonationCurrency[] memory currencies = _priceFeedProvider.getAllDonationCurrencies();

        AnalyticsUtils.DonationCurrencyDetails[] memory result = new AnalyticsUtils.DonationCurrencyDetails[](
            currencies.length
        );

        for (uint256 i = 0; i < currencies.length; i++) {
            uint256 decimals = IERC20(currencies[i].underlyingToken).decimals();
            (uint256 price, uint256 priceDecimals) = PriceFeedProviderInterface(_iHelp.priceFeedProvider())
                .getUnderlyingTokenPrice(currencies[i].lendingAddress);

            result[i].decimals = decimals;
            result[i].provider = currencies[i].provider;
            result[i].currency = currencies[i].currency;
            result[i].underlyingToken = currencies[i].underlyingToken;
            result[i].lendingAddress = currencies[i].lendingAddress;
            result[i].priceFeed = currencies[i].priceFeed;
            result[i].price = price;
            result[i].priceDecimals = priceDecimals;
            result[i].apr = _priceFeedProvider.getCurrencyApr(currencies[i].lendingAddress, _blockTime);
        }

        return result;
    }

    /**
     * Returns an array that contains the charity contributors
     */
    function getContributorsPerCharity(
        CharityPoolInterface _charity,
        uint256 _offset,
        uint256 _limit
    ) public view returns (AnalyticsUtils.CharityContributor[] memory) {
        (_offset, _limit) = paginationChecks(_charity.numberOfContributors, _offset, _limit);

        require(address(_charity.ihelpToken()) != address(0), "not-found/iHelp");
        AnalyticsUtils.CharityContributor[] memory result = new AnalyticsUtils.CharityContributor[](_limit);

        for (uint256 index = _offset; index < _offset + _limit; index++) {
            address _user = _charity.contributorAt(index);
            CharityPoolUtils.DirectDonationsCounter memory registry = _charity.donationsRegistry(_user);
            result[index].contributorAddress = _user;
            result[index].totalContributions += _charity.balanceOfUSD(_user);
            result[index].totalDonations += registry.totalContribUSD;
            result[index].totalDonationsCount += registry.totalDonations;
            result[index].totalInterestGenerated += iHelpTokenInterface(_charity.ihelpToken())
                .contributorGeneratedInterest(_user, address(_charity));
        }
        return result;
    }

    function paginationChecks(
        function() external view returns (uint256) arrLenFn,
        uint256 _offset,
        uint256 _limit
    ) internal view returns (uint256, uint256) {
        uint256 length = arrLenFn();
        require(_offset < length, "Offset to large");

        if (_limit == 0) {
            _limit = length;
        }

        if (_offset + _limit >= length) {
            _limit = length - _offset;
        }

        return (_offset, _limit);
    }

    function priceFeedProvider(iHelpTokenInterface _iHelp) internal view returns (PriceFeedProviderInterface) {
        return PriceFeedProviderInterface(_iHelp.priceFeedProvider());
    }

    function contributionsAggregator(iHelpTokenInterface _iHelp)
        internal
        view
        returns (ContributionsAggregator)
    {
        return ContributionsAggregator(_iHelp.contributionsAggregator());
    }

}
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./oracles/OracleAware.sol";
import "./roles/RoleAware.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./roles/DependsOnOracleListener.sol";
import "../interfaces/IOracle.sol";

/// Central hub and router for all oracles
contract OracleRegistry is RoleAware, DependsOracleListener {
    using EnumerableSet for EnumerableSet.AddressSet;
    mapping(address => mapping(address => address)) public tokenOracle;
    mapping(address => mapping(address => EnumerableSet.AddressSet))
        internal _listeners;
    mapping(address => uint256) public borrowablePer10ks;

    constructor(address _roles) RoleAware(_roles) {
        _charactersPlayed.push(ORACLE_REGISTRY);
    }

    function setBorrowable(address token, uint256 borrowablePer10k)
        external
        onlyOwnerExec
    {
        borrowablePer10ks[token] = borrowablePer10k;
        emit SubjectParameterUpdated("borrowable", token, borrowablePer10k);
    }

    /// Initialize oracle for a specific token
    function setOracleParams(
        address token,
        address pegCurrency,
        address oracle,
        uint256 borrowablePer10k,
        bool primary,
        bytes calldata data
    ) external onlyOwnerExecActivator {
        borrowablePer10ks[token] = borrowablePer10k;
        IOracle(oracle).setOracleParams(token, pegCurrency, data);

        // only overwrite oracle and update listeners if update is for a primary
        // or there is no pre-existing oracle
        address previousOracle = tokenOracle[token][pegCurrency];
        if (previousOracle == address(0) || primary) {
            tokenOracle[token][pegCurrency] = oracle;

            EnumerableSet.AddressSet storage listeners = _listeners[token][
                pegCurrency
            ];
            for (uint256 i; listeners.length() > i; i++) {
                OracleAware(listeners.at(i)).newCurrentOracle(
                    token,
                    pegCurrency
                );
            }
        }

        emit SubjectParameterUpdated("borrowable", token, borrowablePer10k);
    }

    /// Which oracle contract is currently responsible for a token is cached
    /// This updates
    function listenForCurrentOracleUpdates(address token, address pegCurrency)
        external
        returns (address)
    {
        require(isOracleListener(msg.sender), "Not allowed to listen");
        _listeners[token][pegCurrency].add(msg.sender);
        return tokenOracle[token][pegCurrency];
    }

    /// View converted value in currently registered oracle
    function viewAmountInPeg(
        address token,
        uint256 inAmount,
        address pegCurrency
    ) public view returns (uint256) {
        return
            IOracle(tokenOracle[token][pegCurrency]).viewAmountInPeg(
                token,
                inAmount,
                pegCurrency
            );
    }

    /// View amounts for an array of tokens
    function viewAmountsInPeg(
        address[] calldata tokens,
        uint256[] calldata inAmounts,
        address pegCurrency
    ) external view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](inAmounts.length);
        for (uint256 i; inAmounts.length > i; i++) {
            result[i] = viewAmountInPeg(tokens[i], inAmounts[i], pegCurrency);
        }
        return result;
    }

    /// Update converted value in currently registered oracle
    function getAmountInPeg(
        address token,
        uint256 inAmount,
        address pegCurrency
    ) public returns (uint256) {
        return
            IOracle(tokenOracle[token][pegCurrency]).getAmountInPeg(
                token,
                inAmount,
                pegCurrency
            );
    }

    /// Get amounts for an array of tokens
    function getAmountsInPeg(
        address[] calldata tokens,
        uint256[] calldata inAmounts,
        address pegCurrency
    ) external returns (uint256[] memory) {
        uint256[] memory result = new uint256[](inAmounts.length);
        for (uint256 i; inAmounts.length > i; i++) {
            result[i] = getAmountInPeg(tokens[i], inAmounts[i], pegCurrency);
        }
        return result;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./roles/RoleAware.sol";
import "./TrancheIDService.sol";
import "./roles/DependsOnTrancheIDService.sol";

abstract contract TrancheIDAware is RoleAware, DependsOnTrancheIDService {
    uint256 immutable totalTrancheSlots;

    constructor(address _roles) RoleAware(_roles) {
        totalTrancheSlots = TrancheIDService(
            Roles(_roles).mainCharacters(TRANCHE_ID_SERVICE)
        ).totalTrancheSlots();
    }

    mapping(uint256 => address) _slotTranches;

    function tranche(uint256 trancheId) public view returns (address) {
        uint256 slot = trancheId % totalTrancheSlots;
        address trancheContract = _slotTranches[slot];
        if (trancheContract == address(0)) {
            trancheContract = trancheIdService().slotTranches(slot);
        }

        return trancheContract;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./roles/RoleAware.sol";
import "./roles/DependsOnTranche.sol";

contract TrancheIDService is RoleAware, DependsOnTranche {
    uint256 public constant totalTrancheSlots = 1e8;
    uint256 public nextTrancheSlot = 1;

    struct TrancheSlot {
        uint256 nextTrancheIdRange;
        uint256 trancheSlot;
    }

    mapping(address => TrancheSlot) public trancheSlots;
    mapping(uint256 => address) public slotTranches;

    constructor(address _roles) RoleAware(_roles) {
        _charactersPlayed.push(TRANCHE_ID_SERVICE);
    }

    function getNextTrancheId() external returns (uint256 id) {
        require(isTranche(msg.sender), "Caller not a tranche contract");
        TrancheSlot storage slot = trancheSlots[msg.sender];
        require(slot.trancheSlot != 0, "Caller doesn't have a slot");
        id = slot.nextTrancheIdRange * totalTrancheSlots + slot.trancheSlot;
        slot.nextTrancheIdRange++;
    }

    function setupTrancheSlot() external returns (TrancheSlot memory) {
        require(isTranche(msg.sender), "Caller not a tranche contract");
        require(
            trancheSlots[msg.sender].trancheSlot == 0,
            "Tranche already has a slot"
        );
        trancheSlots[msg.sender] = TrancheSlot({
            nextTrancheIdRange: 1,
            trancheSlot: nextTrancheSlot
        });
        slotTranches[nextTrancheSlot] = msg.sender;
        nextTrancheSlot++;
        return trancheSlots[msg.sender];
    }

    function viewNextTrancheId(address trancheContract)
        external
        view
        returns (uint256)
    {
        TrancheSlot storage slot = trancheSlots[trancheContract];
        return slot.nextTrancheIdRange * totalTrancheSlots + slot.trancheSlot;
    }

    function viewTrancheContractByID(uint256 trancheId)
        external
        view
        returns (address)
    {
        return slotTranches[trancheId % totalTrancheSlots];
    }

    function viewSlotByTrancheContract(address tranche)
        external
        view
        returns (uint256)
    {
        return trancheSlots[tranche].trancheSlot;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../../interfaces/IOracle.sol";
import "../roles/RoleAware.sol";
import "../roles/DependsOnOracleRegistry.sol";

/// Abstract base for oracles, concerned with parameter init
abstract contract Oracle is IOracle, RoleAware, DependsOnOracleRegistry {
    function setOracleParams(
        address token,
        address pegCurrency,
        bytes calldata data
    ) external override {
        require(
            address(oracleRegistry()) == msg.sender,
            "Not authorized to init oracle"
        );
        _setOracleParams(token, pegCurrency, data);
        emit SubjectUpdated("oracle params", token);
    }

    function _setOracleParams(
        address token,
        address pegCurrency,
        bytes memory data
    ) internal virtual;

    function viewPegAmountAndBorrowable(
        address token,
        uint256 inAmount,
        address pegCurrency
    ) external view override returns (uint256, uint256) {
        return (
            viewAmountInPeg(token, inAmount, pegCurrency),
            oracleRegistry().borrowablePer10ks(token)
        );
    }

    function getPegAmountAndBorrowable(
        address token,
        uint256 inAmount,
        address pegCurrency
    ) external override returns (uint256, uint256) {
        return (
            getAmountInPeg(token, inAmount, pegCurrency),
            oracleRegistry().borrowablePer10ks(token)
        );
    }

    function viewAmountInPeg(
        address token,
        uint256 inAmount,
        address pegCurrency
    ) public view virtual override returns (uint256);

    function getAmountInPeg(
        address token,
        uint256 inAmount,
        address pegCurrency
    ) public virtual override returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../TrancheIDAware.sol";
import "../OracleRegistry.sol";
import "../../interfaces/IOracle.sol";
import "../roles/DependsOnOracleRegistry.sol";

/// Mixin for contracts that depend on oracles, caches current oracles
/// resposible for a token pair
abstract contract OracleAware is RoleAware, DependsOnOracleRegistry {
    mapping(address => mapping(address => address)) public _oracleCache;

    constructor() {
        _rolesPlayed.push(ORACLE_LISTENER);
    }

    /// Notify contract to update oracle cache
    function newCurrentOracle(address token, address pegCurrency) external {
        // make sure we don't init cache if we aren't listening
        if (_oracleCache[token][pegCurrency] != address(0)) {
            _oracleCache[token][pegCurrency] = oracleRegistry().tokenOracle(
                token,
                pegCurrency
            );
        }
    }

    /// get current oracle and subscribe to cache updates if necessary
    function _getOracle(address token, address pegCurrency)
        internal
        returns (address oracle)
    {
        oracle = _oracleCache[token][pegCurrency];
        if (oracle == address(0)) {
            oracle = oracleRegistry().listenForCurrentOracleUpdates(
                token,
                pegCurrency
            );
        }
    }

    /// View value of a token amount in value currency
    function _viewValue(
        address token,
        uint256 amount,
        address valueCurrency
    ) internal view virtual returns (uint256 value) {
        address oracle = _oracleCache[token][valueCurrency];
        if (oracle == address(0)) {
            oracle = oracleRegistry().tokenOracle(token, valueCurrency);
        }
        return IOracle(oracle).viewAmountInPeg(token, amount, valueCurrency);
    }

    /// Get value of a token amount in value currency, updating oracle state
    function _getValue(
        address token,
        uint256 amount,
        address valueCurrency
    ) internal virtual returns (uint256 value) {
        address oracle = _getOracle(token, valueCurrency);

        return IOracle(oracle).getAmountInPeg(token, amount, valueCurrency);
    }

    /// View value and borrowable together
    function _viewValueBorrowable(
        address token,
        uint256 amount,
        address valueCurrency
    ) internal view virtual returns (uint256 value, uint256 borrowablePer10k) {
        address oracle = _oracleCache[token][valueCurrency];
        if (oracle == address(0)) {
            oracle = oracleRegistry().tokenOracle(token, valueCurrency);
        }
        (value, borrowablePer10k) = IOracle(oracle).viewPegAmountAndBorrowable(
            token,
            amount,
            valueCurrency
        );
    }

    /// Retrieve value (updating oracle) as well as borrowable per 10k
    function _getValueBorrowable(
        address token,
        uint256 amount,
        address valueCurrency
    ) internal virtual returns (uint256 value, uint256 borrowablerPer10k) {
        address oracle = _getOracle(token, valueCurrency);

        (value, borrowablerPer10k) = IOracle(oracle).getPegAmountAndBorrowable(
            token,
            amount,
            valueCurrency
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./Oracle.sol";
import "../../interfaces/IGlpManager.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract fsGLPOracle is Oracle {
    IGlpManager public glpManager = IGlpManager(0xD152c7F25db7F4B95b7658323c5F33d176818EE4);
    address public constant fsGlp = 0x9e295B5B976a184B14aD8cd72413aD846C299660;
    IERC20 public glp = IERC20(0x01234181085565ed162a948b6a5e88758CD7c7b8);

    uint256 public valueSmoothingPer10k = 1000;
    uint256 public lastValuePer1e12;
    uint256 public valuePer1e12;
    uint256 private lastUpdated;
    uint256 public updateWindow = 20 minutes;

    constructor(address _roles) RoleAware(_roles) {}

    /// Convert inAmount to peg (view)
    function viewAmountInPeg(address token, uint256 inAmount, address) public view virtual override returns (uint256) {
        require(token == fsGlp || token == address(glp), "Only for fsGLP and GLP");
        return (inAmount * lastValuePer1e12) / 1e12;
    }

    /// Convert inAmount to peg (updating)
    function getAmountInPeg(
        address token,
        uint256 inAmount,
        address wrappedCurrency
    ) public virtual override returns (uint256) {
        uint256 value = viewAmountInPeg(token, inAmount, wrappedCurrency);

        if (block.timestamp - lastUpdated > updateWindow) {
            lastUpdated = block.timestamp;

            uint256 currentValPer1e12 = glpManager.getAum(false) / IERC20(glp).totalSupply();
            lastValuePer1e12 = valuePer1e12;
            valuePer1e12 =
                (valueSmoothingPer10k *
                    valuePer1e12 +
                    (10_000 - valueSmoothingPer10k) *
                    currentValPer1e12) /
                10_000;
        }

        return value;
    }

    /// Set params
    function setOracleSpecificParams(address fromToken, address toToken)
        external
        onlyOwnerExec
    {
        bytes memory data = "";
        _setOracleParams(fromToken, toToken, data);
    }

    /// Set params
    function _setOracleParams(
        address fromToken,
        address,
        bytes memory
    ) internal override {
                require(fromToken == fsGlp || fromToken == address(glp), "Only for fsGLP and GLP");

        uint256 currentValPer1e12 = glpManager.getAum(false) / IERC20(glp).totalSupply();
        valuePer1e12 = currentValPer1e12;
        lastValuePer1e12 = currentValPer1e12;
        lastUpdated = block.timestamp;
    }

    /// Encode params for initialization
    function encodeAndCheckOracleParams(address fromToken, address)
        external
        view
        returns (bool, bytes memory)
    {
        require(fromToken == fsGlp || fromToken == address(glp), "Only for fsGLP and GLP");
        bool matches = valuePer1e12 > 0;
        return (matches, "");
    }

    function setValueSmoothingPer10k(uint256 smoothingPer10k)
        external
        onlyOwnerExec
    {
        require(10_000 >= smoothingPer10k, "Needs to be less than 10k");
        valueSmoothingPer10k = smoothingPer10k;
        emit ParameterUpdated("value smoothing", smoothingPer10k);
    }

    function setUpdateWindow(uint256 window) external onlyOwnerExec {
        updateWindow = window;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./Roles.sol";

/// @title DependentContract.
abstract contract DependentContract {
    mapping(uint256 => address) public mainCharacterCache;
    mapping(address => mapping(uint256 => bool)) public roleCache;

    uint256[] public _dependsOnCharacters;
    uint256[] public _dependsOnRoles;

    uint256[] public _charactersPlayed;
    uint256[] public _rolesPlayed;

    /// @dev returns all characters played by this contract (e.g. stable coin, oracle registry)
    function charactersPlayed() public view returns (uint256[] memory) {
        return _charactersPlayed;
    }

    /// @dev returns all roles played by this contract
    function rolesPlayed() public view returns (uint256[] memory) {
        return _rolesPlayed;
    }

    /// @dev returns all the character dependencies like FEE_RECIPIENT
    function dependsOnCharacters() public view returns (uint256[] memory) {
        return _dependsOnCharacters;
    }

    /// @dev returns all the roles dependencies of this contract like FUND_TRANSFERER
    function dependsOnRoles() public view returns (uint256[] memory) {
        return _dependsOnRoles;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./DependentContract.sol";

abstract contract DependsOracleListener is DependentContract {
    constructor() {
        _dependsOnRoles.push(ORACLE_LISTENER);
    }

    function isOracleListener(address contr) internal view returns (bool) {
        return roleCache[contr][ORACLE_LISTENER];
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./DependentContract.sol";
import "../OracleRegistry.sol";

abstract contract DependsOnOracleRegistry is DependentContract {
    constructor() {
        _dependsOnCharacters.push(ORACLE_REGISTRY);
    }

    function oracleRegistry() internal view returns (OracleRegistry) {
        return OracleRegistry(mainCharacterCache[ORACLE_REGISTRY]);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./DependentContract.sol";

abstract contract DependsOnTranche is DependentContract {
    constructor() {
        _dependsOnRoles.push(TRANCHE);
    }

    function isTranche(address contr) internal view returns (bool) {
        return roleCache[contr][TRANCHE];
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./DependentContract.sol";
import "../TrancheIDService.sol";

abstract contract DependsOnTrancheIDService is DependentContract {
    constructor() {
        _dependsOnCharacters.push(TRANCHE_ID_SERVICE);
    }

    function trancheIdService() internal view returns (TrancheIDService) {
        return TrancheIDService(mainCharacterCache[TRANCHE_ID_SERVICE]);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./Roles.sol";
import "./DependentContract.sol";

/// @title Role management behavior
/// Main characters are for service discovery
/// Whereas roles are for access control
contract RoleAware is DependentContract {
    Roles public immutable roles;

    event SubjectUpdated(string param, address subject);
    event ParameterUpdated(string param, uint256 value);
    event SubjectParameterUpdated(string param, address subject, uint256 value);

    constructor(address _roles) {
        require(_roles != address(0), "Please provide valid roles address");
        roles = Roles(_roles);
    }

    /// @dev Throws if called by any account other than the owner
    modifier onlyOwner() {
        require(owner() == msg.sender, "Roles: caller is not the owner");
        _;
    }

    /// @dev Throws if called by any account other than the owner or executor
    modifier onlyOwnerExec() {
        require(
            owner() == msg.sender || executor() == msg.sender,
            "Roles: caller is not the owner or executor"
        );
        _;
    }

    /// @dev Throws if called by any account other than the owner or executor or disabler
    modifier onlyOwnerExecDisabler() {
        require(
            owner() == msg.sender ||
                executor() == msg.sender ||
                disabler() == msg.sender,
            "Caller is not the owner, executor or authorized disabler"
        );
        _;
    }

    /// @dev Throws if called by any account other than the owner or executor or activator
    modifier onlyOwnerExecActivator() {
        require(
            owner() == msg.sender ||
                executor() == msg.sender ||
                isActivator(msg.sender),
            "Caller is not the owner, executor or authorized activator"
        );
        _;
    }

    /// @dev Updates the role cache for a specific role and address
    function updateRoleCache(uint256 role, address contr) public virtual {
        roleCache[contr][role] = roles.roles(contr, role);
    }

    /// @dev Updates the main character cache for a speciic character
    function updateMainCharacterCache(uint256 role) public virtual {
        mainCharacterCache[role] = roles.mainCharacters(role);
    }

    /// @dev returns the owner's address
    function owner() internal view returns (address) {
        return roles.owner();
    }

    /// @dev returns the executor address
    function executor() internal returns (address) {
        return roles.executor();
    }

    /// @dev returns the disabler address
    function disabler() internal view returns (address) {
        return roles.mainCharacters(DISABLER);
    }

    /// @dev checks whether the passed address is activator or not
    function isActivator(address contr) internal view returns (bool) {
        return roles.roles(contr, ACTIVATOR);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../../interfaces/IDependencyController.sol";

// we chose not to go with an enum
// to make this list easy to extend
uint256 constant FUND_TRANSFERER = 1;
uint256 constant MINTER_BURNER = 2;
uint256 constant TRANCHE = 3;
uint256 constant ORACLE_LISTENER = 4;
uint256 constant TRANCHE_TRANSFERER = 5;
uint256 constant UNDERWATER_LIQUIDATOR = 6;
uint256 constant LIQUIDATION_PROTECTED = 7;
uint256 constant SMART_LIQUIDITY = 8;
uint256 constant LIQUID_YIELD = 9;
uint256 constant VEMORE_MINTER = 10;

uint256 constant PROTOCOL_TOKEN = 100;
uint256 constant FUND = 101;
uint256 constant STABLECOIN = 102;
uint256 constant FEE_RECIPIENT = 103;
uint256 constant STRATEGY_REGISTRY = 104;
uint256 constant TRANCHE_ID_SERVICE = 105;
uint256 constant ORACLE_REGISTRY = 106;
uint256 constant ISOLATED_LENDING = 107;
uint256 constant TWAP_ORACLE = 108;
uint256 constant CURVE_POOL = 109;
uint256 constant ISOLATED_LENDING_LIQUIDATION = 110;
uint256 constant STABLE_LENDING = 111;
uint256 constant STABLE_LENDING_LIQUIDATION = 112;
uint256 constant SMART_LIQUIDITY_FACTORY = 113;
uint256 constant LIQUID_YIELD_HOLDER = 114;
uint256 constant LIQUID_YIELD_REBALANCER = 115;
uint256 constant LIQUID_YIELD_REDISTRIBUTOR_MAVAX = 116;
uint256 constant LIQUID_YIELD_REDISTRIBUTOR_MSAVAX = 117;
uint256 constant INTEREST_RATE_CONTROLLER = 118;
uint256 constant STABLE_LENDING_2 = 119;
uint256 constant STABLE_LENDING2_LIQUIDATION = 120;
uint256 constant VEMORE = 121;

uint256 constant DIRECT_LIQUIDATOR = 200;
uint256 constant LPT_LIQUIDATOR = 201;
uint256 constant DIRECT_STABLE_LIQUIDATOR = 202;
uint256 constant LPT_STABLE_LIQUIDATOR = 203;
uint256 constant LPT_STABLE2_LIQUIDATOR = 204;
uint256 constant DIRECT_STABLE2_LIQUIDATOR = 205;

uint256 constant DISABLER = 1001;
uint256 constant DEPENDENCY_CONTROLLER = 1002;
uint256 constant ACTIVATOR = 1003;

/// @title Manage permissions of contracts and ownership of everything
/// owned by a multisig wallet during
/// beta and will then be transfered to governance
contract Roles is Ownable {
    mapping(address => mapping(uint256 => bool)) public roles;
    mapping(uint256 => address) public mainCharacters;

    event RoleGiven(uint256 indexed role, address player);
    event CharacterAssigned(
        uint256 indexed character,
        address playerBefore,
        address playerNew
    );
    event RoleRemoved(uint256 indexed role, address player);

    constructor(address targetOwner) Ownable() {
        transferOwnership(targetOwner);
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwnerExecDepController() {
        require(
            owner() == msg.sender ||
                executor() == msg.sender ||
                mainCharacters[DEPENDENCY_CONTROLLER] == msg.sender,
            "Roles: caller is not the owner"
        );
        _;
    }

    /// @dev assign role to an account
    function giveRole(uint256 role, address actor)
        external
        onlyOwnerExecDepController
    {
        emit RoleGiven(role, actor);
        roles[actor][role] = true;
    }

    /// @dev revoke role of a particular account
    function removeRole(uint256 role, address actor)
        external
        onlyOwnerExecDepController
    {
        emit RoleRemoved(role, actor);
        roles[actor][role] = false;
    }

    /// @dev set main character
    function setMainCharacter(uint256 role, address actor)
        external
        onlyOwnerExecDepController
    {
        emit CharacterAssigned(role, mainCharacters[role], actor);
        mainCharacters[role] = actor;
    }

    /// @dev returns the current executor
    function executor() public returns (address exec) {
        address depController = mainCharacters[DEPENDENCY_CONTROLLER];
        if (depController != address(0)) {
            exec = IDependencyController(depController).currentExecutor();
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IDependencyController {
    function currentExecutor() external returns (address);
}

interface IGlpManager {
  function MAX_COOLDOWN_DURATION (  ) external view returns ( uint256 );
  function PRICE_PRECISION (  ) external view returns ( uint256 );
  function USDG_DECIMALS (  ) external view returns ( uint256 );
  function addLiquidity ( address _token, uint256 _amount, uint256 _minUsdg, uint256 _minGlp ) external returns ( uint256 );
  function addLiquidityForAccount ( address _fundingAccount, address _account, address _token, uint256 _amount, uint256 _minUsdg, uint256 _minGlp ) external returns ( uint256 );
  function aumAddition (  ) external view returns ( uint256 );
  function aumDeduction (  ) external view returns ( uint256 );
  function cooldownDuration (  ) external view returns ( uint256 );
  function getAum ( bool maximise ) external view returns ( uint256 );
  function getAumInUsdg ( bool maximise ) external view returns ( uint256 );
  function getAums (  ) external view returns ( uint256[] memory );
  function glp (  ) external view returns ( address );
  function gov (  ) external view returns ( address );
  function inPrivateMode (  ) external view returns ( bool );
  function isHandler ( address ) external view returns ( bool );
  function lastAddedAt ( address ) external view returns ( uint256 );
  function removeLiquidity ( address _tokenOut, uint256 _glpAmount, uint256 _minOut, address _receiver ) external returns ( uint256 );
  function removeLiquidityForAccount ( address _account, address _tokenOut, uint256 _glpAmount, uint256 _minOut, address _receiver ) external returns ( uint256 );
  function setAumAdjustment ( uint256 _aumAddition, uint256 _aumDeduction ) external;
  function setCooldownDuration ( uint256 _cooldownDuration ) external;
  function setGov ( address _gov ) external;
  function setHandler ( address _handler, bool _isActive ) external;
  function setInPrivateMode ( bool _inPrivateMode ) external;
  function usdg (  ) external view returns ( address );
  function vault (  ) external view returns ( address );
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IOracle {
    function viewAmountInPeg(
        address token,
        uint256 inAmount,
        address pegCurrency
    ) external view returns (uint256);

    function getAmountInPeg(
        address token,
        uint256 inAmount,
        address pegCurrency
    ) external returns (uint256);

    function viewPegAmountAndBorrowable(
        address token,
        uint256 inAmount,
        address pegCurrency
    ) external view returns (uint256, uint256);

    function getPegAmountAndBorrowable(
        address token,
        uint256 inAmount,
        address pegCurrency
    ) external returns (uint256, uint256);

    function setOracleParams(
        address token,
        address pegCurrency,
        bytes calldata data
    ) external;
}

// TODO: compatible with NFTs
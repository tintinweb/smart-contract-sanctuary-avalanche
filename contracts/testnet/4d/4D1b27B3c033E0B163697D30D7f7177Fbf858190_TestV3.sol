/**
 *Submitted for verification at testnet.snowtrace.io on 2022-11-16
*/

// File: @openzeppelin/contracts/utils/structs/EnumerableSet.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

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
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
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
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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
     * @dev Returns the number of values in the set. O(1).
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

// File: @openzeppelin/contracts/utils/structs/EnumerableMap.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableMap.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableMap.js.

pragma solidity ^0.8.0;


/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * The following map types are supported:
 *
 * - `uint256 -> address` (`UintToAddressMap`) since v3.0.0
 * - `address -> uint256` (`AddressToUintMap`) since v4.6.0
 * - `bytes32 -> bytes32` (`Bytes32ToBytes32Map`) since v4.6.0
 * - `uint256 -> uint256` (`UintToUintMap`) since v4.7.0
 * - `bytes32 -> uint256` (`Bytes32ToUintMap`) since v4.7.0
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableMap, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableMap.
 * ====
 */
library EnumerableMap {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Bytes32ToBytes32Map {
        // Storage of keys
        EnumerableSet.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        bytes32 value
    ) internal returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToBytes32Map storage map, bytes32 key) internal returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function length(Bytes32ToBytes32Map storage map) internal view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToBytes32Map storage map, uint256 index) internal view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), errorMessage);
        return value;
    }

    // UintToUintMap

    struct UintToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToUintMap storage map,
        uint256 key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToUintMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToUintMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToUintMap storage map, uint256 index) internal view returns (uint256, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToUintMap storage map, uint256 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToUintMap storage map, uint256 key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key)));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToUintMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key), errorMessage));
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key), errorMessage))));
    }

    // AddressToUintMap

    struct AddressToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        AddressToUintMap storage map,
        address key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(uint256(uint160(key))), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToUintMap storage map, address key) internal returns (bool) {
        return remove(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToUintMap storage map, address key) internal view returns (bool) {
        return contains(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(AddressToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressToUintMap storage map, uint256 index) internal view returns (address, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (address(uint160(uint256(key))), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(AddressToUintMap storage map, address key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(uint256(uint160(key))));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToUintMap storage map, address key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        AddressToUintMap storage map,
        address key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key))), errorMessage));
    }

    // Bytes32ToUintMap

    struct Bytes32ToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToUintMap storage map,
        bytes32 key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, key, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToUintMap storage map, bytes32 key) internal returns (bool) {
        return remove(map._inner, key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool) {
        return contains(map._inner, key);
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(Bytes32ToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToUintMap storage map, uint256 index) internal view returns (bytes32, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (key, uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, key);
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToUintMap storage map, bytes32 key) internal view returns (uint256) {
        return uint256(get(map._inner, key));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToUintMap storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, key, errorMessage));
    }
}

// File: contracts/ClampedRandomizer.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract ClampedRandomizer {
    uint256 private _scopeIndex = 0; //Clamping cache for random TokenID generation in the anti-sniping algo
    uint256 private immutable _scopeCap; //Size of initial randomized number pool & max generated value (zero indexed)
    mapping(uint256 => uint256) _swappedIDs; //TokenID cache for random TokenID generation in the anti-sniping algo

    constructor(uint256 scopeCap) {
        _scopeCap = scopeCap;
    }

    function _genClampedNonce() internal virtual returns (uint256) {
        uint256 scope = _scopeCap - _scopeIndex;
        uint256 swap;
        uint256 result;

        uint256 i = randomNumber() % scope;

        //Setup the value to swap in for the selected number
        if (_swappedIDs[scope - 1] == 0) {
            swap = scope - 1;
        } else {
            swap = _swappedIDs[scope - 1];
        }

        //Select a random number, swap it out with an unselected one then shorten the selection range by 1
        if (_swappedIDs[i] == 0) {
            result = i;
            _swappedIDs[i] = swap;
        } else {
            result = _swappedIDs[i];
            _swappedIDs[i] = swap;
        }
        _scopeIndex++;
        return result;
    }

    function randomNumber() internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
    }
}
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// File: @openzeppelin/contracts/utils/math/Math.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;


/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


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
}

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
}

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/interfaces/IERC2981.sol


// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/token/common/ERC2981.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;



/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;








/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256, /* firstTokenId */
        uint256 batchSize
    ) internal virtual {
        if (batchSize > 1) {
            if (from != address(0)) {
                _balances[from] -= batchSize;
            }
            if (to != address(0)) {
                _balances[to] += batchSize;
            }
        }
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}
}

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;


/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;



/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);

        if (batchSize > 1) {
            // Will only trigger during construction. Batch transferring (minting) is not available afterwards.
            revert("ERC721Enumerable: consecutive transfers not supported");
        }

        uint256 tokenId = firstTokenId;

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// File: contracts/PyrosV3.sol



/*
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''..''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''..........'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''...    .....'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''.....     ....'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''..       ....''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''......'''''''''''''''''''''''''''''''''''''''''''''...  ......''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''.......    ..''''''''''''''''''...'''.''''''''''''''''''''.........'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''........         .........'''''...................'''''''''''''''......''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''..  .                    ....'..              .....'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''.''''''''''''''''''''''''''''''''
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''.....                         .....             .........'''''''''''''''''''''''''''''''''''......'''''''''''''''''''''''''''''''..'''''''''''''''''''''''''''''''''''''''''''''........''''''''''''''''''''''''''''''
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''..                                        ....................''''''''''''''''''''........'''..   ......'''''''''''''''''''''''............''''''''''''''''''''''''''''''''''''...      ..'''''''''''''''''''''''''''''
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''..                               .......................................''''..''''..............      ....'''''''''''''''''''''..          ........'''''''''''''''''''''''''''''.       ..''''''''''''''''''''''''''''''
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''....                                ...............................................'................     ...''''''''''''''''''''''..                 ..''''''''''''''''''''''''''''..     ..'''''''''''''''''''''''''''''''
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''..''..                              ...........................................................................'''''''..''''...''''''''...                ...'''''''''''''''''''''''''''.... ...'''''''''''''''''''''''''''''''
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''...''....                               ...................'''...'''''............................................................ ...''''''''...                ....''''''''''''''''''''''''''.......''''''''''''''''''''''''''''''
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''.............                              ......................',''',,,,,,''................................................            ....''''''..                   .....''''''''''''''''''''''....  .....''''''''''''''''''''''''''
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''..  .                                      .........................',,,,,,,,,,,,'.....'''''.....................................             ..''''''.      ..              ....''''''''''''''''''''....      ...''''''''''''''''''''''''
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''..                                        ............................',,,,,,,,,,,,,'....',,,,'....................................            ..''''''...........            ....'''''''''''''''''''''.....     ..''''''''''''''''''''''''
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''.                                       ...............................',,,,,,,,,,,;,,,'..'',,,,,'..................................           ...''''''''''''''.........      ....''''''''''''''''''''..       ........'''''''''''''''''''
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''..                                    ..................................',,,,,,,,,,,,;;;;,'..'',,,,'...................................          ....''''''''''''''''''''.....     ..'''''''''''''''''''.................'''''''''''''''''''
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''..                                   ...................................',;,,,,,,,,,,;;,,,,'...'','''....................................           ..'''''''''''''''''''''''... ....''''''''''''''''''''..''''''''..'...'''''''''''''''''''
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''..                                    ...................................',,;,,,,,,,,,,,,''''.....''.........................................       ...'''''''''''''''''''''''''......'''''''''''''''''''''''''''''''''''''''''''''''''''''''
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''..                                  ..................................'''',,,;;;;;;,,,,,,,,,'''''''''...............''.'......................      ..'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''..    ...                            ...............';,;:,,,..........',,,,,,,;;;;;;;;,,,,,,,,,,,,,,,'............',,,''........................  ....'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''..  ..'...                          .............,;okxxo:c;...........',,,,,,,;;;;;;;;;;;;,,,,,,,,,,,,'..........',,,'......''',.....................'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''...''''''.......                ...............,oxkOkkko;'............''',,,,,,,;;;;;;;,;;;,,,,,,,,,,,'........',,,,'......,cc:,................  ...''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''...            .'cl'............ckOOOkOkxl;.','...........'',,,',,,;;;;;;::;;;;,,,,,,,,,''.....',,,,,'......'cooc;................ ...''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''...         .'okx:...........,dOOOOkOkkl;,,;;,'...........'''''',;:lllool:;;;;,,,,,,,,'''''.',,,,,,'.......'cddo:...............  ..''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''..        .ckkkx:.........'okkxxkOOkkxoodxxdc,.......'..''..',:lddxdollc;,,;;;,,,,,''',,'',,,,;,,,,'..''..,lddo:...............  ..'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
''''''''''''''''''''''''''''''''''''''''......''''''''''''''''''''''''''''''''''''''..      .':dkkkkc.........,dkxxxkOOOOOkkkxoc:;,''.....''',;;cloddxdolll:,,',,,,,,,,,,,;;,,,,,;;::clc::ll:'.,:coc'................ ..''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
''''''''''''''''''''''''''''''''''...'...   ..'''''''''''''''''''''''''''''''''''''..     ..cxkkkkkkl.........ckOkOxxkOOkxdooc;;;;;;;,'..''';codddddddxdoc:;,,,,,''',,;:::cc:;,,,;;::codddddo:'..';;................. ...'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'''''''''''''''''''''''''''''..........  ....'''''''''''''''''''''''''''''''''''....      .ckkkkkkkkc..',;:;':dkkkkdclolc:;;;;;;;;;;;;,'.'':oddddddddxxdl:;;;,,,,,,,;cloddddc;,;;;;;;coddddddo:'....................... ...'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'''''''''''''''''''''''''''...     .    ..''''''''''''''''''''''''''''''''''''''..        .lxkkkkkkd,...,okxxkkkkdl:,,,;;;;;;;;;;;;;;;;,,,:odddddddddxxdc;;;;;;;;,;:loddddddl:;;;;;,;:odddddddoc'.....................    ...'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
''''''''''''''''''''''''''..            ....'''''''''''''''''''''''''''''''''''''.       .'okkkkkkko....ckOOOOOOOkd;',,,,;;;;;;;;;;;;:ll:lddddddddddddxo:;;;;;;;:cloddddddddo:;;:c::coddddddddddl;....................      ..'''''''''..'''''''''''''''''''''....''''''''''''''''''''''''''''''''''''''''''
''''''''''''''''''''''''''..               ..''''''''''''''''''''''''''''''''''...       .,lxkkkkxol:,;:dkOOOOOOOOo,.',,,,,;;;;;;;;;;:lllodddddddddddolc;;;;;;;:cldddddoooddoc;;:loooddddddddddddl,....................      ......''''...'''''''''''''''''''..  ..'''''''''''''''''''''''''''''''''''''''''
'''''''''''''''''''''......   ...           ..''''''''''''''''''''''''''''''''..         .';lxxxxl:okxxkkkkkOOOOOOd:'..'',,;;;;;;;;;:cloddddxddddddoc:;;;;;;:clccodddol::loddc;;:lddddddddddddxxxdc,..................           ..............'''''''''''''..     ...............''''''''''''''''''''''''''
'''''''''''''''''''''..     .............   ..'''''''''''''''''''''''''''''''..          .:;:l;,,,:dkkkkkkkkkOOOOOd;......',,,;;;;;:ooddddxkOkxxxdoc;,,;;;;;:llloddol:;;:ldddo:;:ldddddddddddxxxddoc:c,.................          ... ..     ..'''''''''''''..                    ..''''''''''''''''''''''''
'''''''''''''''''''''.      .''''''''''......'''''''''''''''''''''''''''''''...           ..''. ...ckkkkkkkkkkOOkd:'........',;;;;:lddddxkO00OO0kl::,,;;;;;;;:clllcc:;;;;codddoc;:odddddddddddxxdddddoc;,...............                     ..'''''''''''....                     .''''''''''''''''''''''''
'''''''''''''''''''''..    ..''''''''''''''''''''''''''''''''''''''''''''''..                   ...ckkkkkkkkkOOOx:...........,;;;:okkxddk00KK0OOxollclol:;;;;::::;;,,,;:codddddoloddddddddddddddddddddoc,.................                   ..''''''''''..                       ..''''''''''''''''''''''''
''''''''''''''''......    ..'''''''''''''''''''''''''''''''''''''''''''''''...                 ....;dkkkkkkkOOOOkl'.........',;;:lxO0OxxO000K00kxxdoollc:;;;;;;;;,,',:coddddddddddddddddddddolldddddol:,...................                  ..''''''''''.                        ..''''''''''''''''''''''''
'''''''''''''.....        ..''''''''''''''''''''''''''''''''''''''''''''''''...                ....;xkkkkkkkO0000x;.......',;;;;lxO0KKOkk0000000Oxooooooo:;;;;;;,'',codddddxxxxdddddddddddol:;lddddo;'........................              ...''''''''''...                       ..'''''''''''''''''''''''
''''''''''''''.....       ..''''''''''''''''''''''''''''''''''''''''''''''''...                ...'lxkkkkkkOOO0K0kc'.','',,,;;;;oO0KKKK0O00K0000Oxddddxddl;;;;;;,,,;coddddxxxdddddddddddlc:;,;codoc,'.........................              ....'''''''''..                         ..''''''''''''''''''''''
'''''''''''''''''...     ..'''''''''''''''''''''''''''''''''''''''''.........                .....cxkkkkkkkO00000kc..''',,,,;;;:x0K00KK0000000000Oxdddxxdc;;;;;,,;;;:ldddxdxdddddddddddo:,''''',;,'...........................                ....'''''''..                        ..'''''''''''''''''''''''
''''''''''''''''...      ..'''''''''''''''''''''''''''''''''''''''''..                    ........okkkxxkkkkO00Okko;'',;;;,,;;;ck00000KK0000000000Oxdxxdl;,;;;;;;;;;codddxxxdddddddddxdl:;,''.''...............................                 ..''''''''..                       ..'''''''''''''''''''''''
'''''''''''''''..        ...''''''''''''''''''''''''''''''''''''''''.                     .......;xkko;,okkkkO00Okdc;;;;;;;,;;:ok000KKKKK000000K000Okxdoc;;;;;;;;;;:lddddxxddddddddddddolc:,'','''''............................                 ..'''''''..                        .''.....''''''''''''''''
'''''''''''''''..... .....''''''''''''''''''''''''''''''''''''''''''.                   .........cxkkl'.,lkkkO000Oxc;;;;;;;;;;coxO00KKKKK000000000000Okdc;;;:c:;;;;:::cldddddddollodddooc;;,',,,',,'..............................             ...'''''''''.                        ...   ..''''''''''''''''
'''''''''''''''''''...''''''''''''''''''''''''''''''''''''''''''''''..                ...........,lkd:...'cxkkO00Odc::;;;;;;;coddk0KKKKKKK00K00000000000kdlodddl;;;;;;;;coddddl:;coddolllllll:;,,,,'.................................        ...''''''''''..                               .''''''''''''''''
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''..                ............:l,......,:cldxxolol:;;;;;:ldddxO0KKKKKK000000000000000000Okxoc;;;;;;;;;:loc,';loooddxkOOOkdc;,,''..................................     ...''''''''''''..                               ...''''''''''''''
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''......               ...........................':olcc:;;:clccoddddk00K000000000000000000000K0Okdl:;;;,,'..',,'.,cdooxkOOOOOOxc;,,''..................................     ...''''''''''''...                                 ..'''''''''''''
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''.....              ............................';c:;;;;:dOkxkxxdddxO0OkOO000000000000000000K0Oxoc;;,'......'';oxddkOOOOOOxo:;;,'....................................      ...''''''''''..                                    ..''''''''''''
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''..........              .............................';;;;;;lkO000OOkxddkOkkkOO0K00000000000000K0K0Oxc;,,'......';cdOkdkOOOOOko;;;,''.........''..'.......................      ..'''''''''''.....                                ..''''''''''''
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''.... ..                   ....................''.'''..',,;;;;;:cxO00000OxddddddxO00KK0000000OO0000000K0kl;,'.......,okOOOOOOOOOOko:;;,,,'.......',,'','......................    ....'''''''''''''''....                               ..''''''''''
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''....                     ....................',,'''''',;;;;;;;:cdO000000Oxxddl:lO000000000OkkkO000000K0Oxl;'......,okOO00000000Oo:;,,,,,'......'',,,'''......................   ..'''''''''''''''''''''..                              ..''''''''''
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''..                    ...................',,,,'',,,,;;;;;;;;:oO00K00000Okdc;:ok0KKK0000OOOkOOOO000K0Oko:'..;ccoxO0000000000Od:;;;;,,''......',,,,,'.......................    ..''.'''''''''''''''''.....                         ...'''''''''''
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''..                   ....................,,,,,,,,,,;;;;;;;;;:lk0000KK00Odc;,;lO0KKK00000000OxxkO000ko:,..:dkO0000000000K0K0xc;,,,;,,'......'',,,,,''....................      ....'''''''''''''''''''...                         .'''''''''''''
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''...                   ...................';::;,',,,,;;;;;;;;;;;lk00KK000Od:,,:oO0KKKKK0000000Okxxddxdc,..'lkOOO000000000K00Odc;;,,;,'........'',,,,,'....................        ...'''''''''''''''''''...                        .'''''''''''''
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''...                  ....................':coxoc:;;,,,;;;;;;;;;;cxO00K0000x:,;lk000KKKKKKKKKK000kdlodoc;'.'okOOOO0OO000KK00Okl;;;;;;,''.......'',,,,,'....................          ..''''''''''''''''''''..                      ..'''''''''''''
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''..                  .....................':dk0Okdoc;;:odl;,;;;;;coxkO00Okkdc;:ok000KKKKKKKKKKK000Okkkxo;'.,okOOOOOOO0000OOOOkl;,,,;;,''.....'',;::;;,,''.....................        ..''''''''''''''''''..                       .''''''''''''''
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''..                  ....................;clxO00OxddodkOkl;,;;;;;:loxxkkxxddl:coxO000KKKKKKKKKKK00OO0OOkl;,okkOOOOkkOOkxdllxOOd:;;;;,,''.'',;clloll:;,,,,,'.....................       ..'''''''''''''''''..                       .''''''''''''''
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''..                ....................,:oxO00000kxkO000kl;,,,,,;;:ldxxxxdddooddxO0KKKKKKKKKKKKK00OO0000kooxkOOOkocccc:::;;:dkxc:;;,,,''':looddddol;,,,,,,,'............................''''''''''''''''''..                       .''''''''''''''
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''..              ...................;::okOO000000O000000d:;;;;,,;;;:ldxxddddddddxO0KKKKKKK0KKK000OOO00000koxkOkko:,,,,,;:lc:cddlc:;,,'',cooddolcc:;;;,,,,,,,'..........................'''''''''''''''''''..                     ..'''''''''''''''
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''...           .............,,,,,'.,coxOO0000000000000Oxdoool:;;;:ldooxxddddxxxO0KKKKKKKKKKKK000OOOO0000Okxolll:;;;;:clddolccc:;;,,,'.,;::::::;;;;;;;,,,,,,'.............................''''''''''''''''.                      ..'''''''''''''''
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''..           ............';:coolccdkOOO000000O000OOOOkxdxxdl;;;:oxddxddxxkOO0000000000KK00KK00OOkOO000Okl',cllllllodddddo:;;,,,,,,'.'',;::cl:;;::;;;,,,,,'.............................''''''''''''''''.                   ....''''''''''''''''
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''.....        ................,;';oddxO00OOO00000000000OOOkxxxxl:clldkkOkxkkk0000000OkdxO0KKK0KK00OOOOO000Okc,:oddddddddddolc;,,,,;;,,''',:oooddlclol:;;;,,,,.............................'''''''''''''''''..                ..''''''''''''''''''''
'''''''''''''''''''''''''''''''''''.......''''''''''''''''.            ...................',:lxO00000000K00000KK0000Okkkxxk0OO000kxkO00000Okkkxddk0KKKK000OOOkO00000kc:oxxdddxxddddolc;,,,;cl:;,;coddxxxxxxxdl:;;;,,,,'............................''''''''''''''''..                .''''''''''''''''''''''
'''''''''''''''''''''''''''''''''....   ...''''''''''''''..            ......................;dOOO00OO00000000K000KK000000KK0000Oolx000000OxxxxxkO0KKK000OOkolx00000OxdxxxxkkOOkkkOkxdl:;,;ldolldkxxdxxxxxxdo:;;;;,,,''..............................'''''''''''''''..               ....'''''''''''''''''''
'''''''''''''''''''''''''''''''...      ...'''''''''''''..              ...................',;cdxxkOOOO00OO00000KKKKKKKKKKKK0000kolx00000kdddxxxkOOO0000OOOkl;cxO000OkxxkkO00K0000000Okxo;,lddddxO0Oxxxxxdoc:;;;;;;,,''............................''''''''''''''''''.                 ..'''''''''''''''''''
'''''''''''''''''''''''''''''''.        ..'''''''''''''..             ...........''......',;;;;:cok000Okkocok0KKKKKKKKKKKKKK0OOOxodkO000koodxkkxxxxk0000OOOOo:cdxxxkxxxxO000KK0000000000kddxxxxkO0K0Oxdooc:;;;;;;;;,,,'..'.......................''''''''''''''''''''..               ..''''''''''''''''''''
'''''''''''''''''''''''''''''...       ..''''''.....''..          . ...........'',,'...',;;;;;;;;cx0000Oxc;:d0KKKKKKKKKKKKKKOxxxdxkOOOO0OkxxkOOkkOkO0KK0OOOko:ldxddxxxxO000KKKK000000KKK0000OxxO0000Ooc:;;;;;;;;;;;;,'',cl:....................''''''''''''''''''''''..                ..'''''''''''''''''''
''''''''''''''''''''''''''''..         .'''''''..  ....          ..............',,,''',;;;;:;;;;:lk00000OxllxO0KKKKKKKK00KK0dooldkO00OOOOOkkOOO00000K0000Okl:coxxxxxxxk00000000000000KKK0K00OdodO000kc;;;;:;:clccloc,':dkkdc,.................''''''''''''''''''''''''..                .....'''''''''''''''
'''''''''''''''''''''''''''..        ..''''''''...                 ...........',,,,,,,;;;;;;;;;:ldkO00000Okxkk00KKKKKK00OOOOdoolxO0OOOOOOOOOO00000KKKKK00OoclloxxxxkkkO000OOO00000000K0K00000xlcx00Oxl:ccoolldkkkOOkooxOkkkkl'........................'''''''''''''''..                     .....'''''''''''
''''''''''''''''''''''''...          .'''''''''''.                 ....';,..:lc;;;;,,;;;;;;;;;;coxkkO0OOOOOkO000000KK0OkolokOkkOOOOOOOOOOOOOO0000O00KK000kl:oxxxxxkOOkO0OOkk0000OOOOO00000K0OkdodO0ko::coxkkkkOOOOOOOkkkOOkxl;'..................   ..''''''''''''''''....                     ..'''''''''''
''''''''''''''''''''''....           ..'''''''....                   .'okx::dkxdoll:;ccc:;;;;;;:oxxxxkdldkkkO00000000OkocoxOOOOOOOOOOOOOOOOOOOO00O000000Oxl;cddddxxkkOOkxxdxO0OO00OOOO000000kxdlokkdloc:okOOOOOOOOOOOOOOOOOkxxdlc,...............   ..'''''''''''''''''''...                   ..'''''''''''
'''''''''''''''''''''..              ..''''....                      .,xkkdoxkkkkkxodxkxo;;;;;;:odddoc::lldkO0000000OkkkkOOOOOOOOOOOOOOOOOOOOOOO000OOOkxddo::oddddodxOOkddxxOOkO00OOOOO0000Okkdc:oxoodc:oOOOOOOOOOOOOOOOOOOOOOOOkl,.............     ...''''''''''''''''''..                   ..'''''''''''
''''''''''''''''''''..               ..''''..                        .;xkxodkkkOOOOOOOOOo;,,;;;:loooc,',;:okO00000000OOOOOOOOOOOOOOOOOOOOOOOOOOO00kxxddddddoodxkdoodxOOkkOOO0OxxOO0OOOO00K0Okxdl:cddol::okOOOOOOOOOOOOOOOOOOxxOOOxc,............      ..''''''''''''''''''....                ..''''''''''''
'''''''''''''''''''..                ..''''..                        .cxkxoldddkOOOOOOOkl;'',;;;:::;'..';lxOO000000000000OOOOO000OOOOOOOOOOOOOOOOOkxdddddddxxxkOxxkOO00000000OkdxO0OOOO000OkkxdolloddolccdkkkOOOOOOOOOOOOOOklcdOOOxc,..........       ..'''''''''''''''''''''.                ...'''''''''''
'''''''''''''''''''...              ..'''....                        .cxkkkxdldOOOOOOOOxc,'.,;;;;,'....':xO0000000000000000000000OOOOOOOOOOOOOOO0OkdddddddxkOkOOO00KKKK0000000kxkO0OOO000Okkkxddollddddl::lloxOOOOOOOOOOOOkl,,ckOOOx:,'........       ..'''''''''''''''''''''....              .''''''''''''
'''''''''''''''''''''..            ..''''..                          .,oxkkkkxxOOOOOOkdc;'.',;;;,'..'',cdO00000000000000KKKK000000OOOOOOOOOOOOOOOOxddddddxk00000000K00KK000000000OOOOOOOkkkxxdddooodddddl:;;;:oxkxxkkkOOOOd:,',:xOkdc,,'.......       ..''''''''''''''''''''''''..             ..'''''''''''
''''''''''''''''''....            ..''''''..                          ..:dxkOOkkOOxdlc:;'..';,,;,''',;lkO0000000000K000KKKKK000000OOkOOOOOOOOOOOOOkdddddkO0KKK0kxO0000KK000000000OOOOOOOkxxxdddddddxdddddoc;,;;:c::coxOOOOxc;,'.,::;,,,,'......         ..'....''''''''''''''''''.              ...'''''''''
''''''''''''''''...                ....'''''..                         .;ldxO0000Oxl;,;,'..','''''',,:dOOO00000000KK0000KKKK000000OOkxooooooxOOOOOkdddxk00KK00xdxO00KKK000000000OOOOOO00Oxxxddddddxxxxdddoc:;;;;;;;;lkOOOOko;,,'..''',,,'......      .......   ....''''''''''''''...             ..'''''''''
'''''''''''''''..                     ...'''.....                      ..''cxxk00Odc;;;,''''..'..',,,:okkO000000KKK00000K0000000000Okl::;;cdkOOOOkdodxkO00OOOkxxO000KK000000000OOOOOOOO00kxxdddddddxxxxdddooool:;;;;lkOOOOOd:,,,,''',,,,,.....      ....          ...''''''''''''''..            ..'''''''''
''''''''''''''..                        ..'''''......                   ...';:dO00kl;;;;,,,''','.',,,;cddk0000000000000KK0000000000Ox:',;cxOOOOOOxc:ldxkkkkkxxxkOO00000000000OOOOOOOOOOO0Oxdddddddddxxxxdddddxdol:;;cdOOOOOd:;,,,,,'',,,'.....                       ....''''''''''..            .''''''''''
'''''''''''''..                        ..'''''''..''..                   .cl:;;lxkOkl;;;;,,,''''.',,,,:okO0000000000000000000000000Od:,,:dOOOOOOxc;;:lddxxxkxxxkOOO0000000000OOOO00OOOOOOkxdddooddddddxxxdddxxxxdl:;:ldkOOOo:;,,,,,,,,,,'....                           ....''''''..             .''''''''''
'''''''''''''...                     ..'''''''''''''...                  'okkd;':ooxd:;,,,,,,'''',,,;:ok000000000000000000000000000Oocc::okOOOko:;;;codddxxkxxxkO0OO000000000OOO000OOOOOkxxdddooddddddxxxxxxxxxxxoc;;;:dkkd:;;,,,,,,,,'.....                               ..'''''..            ..''''''''''
'''''''''''''''...                  ..''''''''''''''..                   .lkkkdc;'.,cc;,,,,,,,,,,,,,;:d00000000Okkk0000000000000000OkxkxodkOOxc;;;;;ldxdxxxxxxxxO0OO00000000000000000OOkxddddddddddddddxkOkkkxxxxdl;;;;:lc:;;;,,;,,,,......                                .''''''..             .''''''''''
''''''''''''''''''...               ...''''''''''''..                    .:xkkkkxo,..;;,,,,,,,,,,,,;:ok0000000Oxddk0KK000000000000000Okooxkdoc;;;;;;coddxxxxxxkO00OOOOO00000000000000OOkdddddlldddddddxk00OOkxxxxdo:;;;;;;;;;;;,,,,,'.....                                ..'''''...            ..''''''''''
''''''''''''''''''''...              ..'''''''''''..                     .'okkkkOkl..',,,,,,,,,',,;coxO0000000OxdxOKKKKK000000000K000Oxddoc:,,,,;;;;;:loxxxdxkO000OOkO000000000000000OkxdddddlodddddddxOKK0Oxxxxxxo::cc:;,;;;;;,,,,,'.....                                 .'''''..            ..'''''''''''
''''''''''''''''''''''..            ..''''''''''''..                      .,okkkOOd,.,,,,;,,,,,'',;ldxO0000000Okddk0KKKKK000000OOO000kxdc;;;,.',;;;;;:loddxxk00000OkkO000000000000OkOkdoddddddxxddddddk0KK0Oxxxxxdoloxkoc:;;;;;,,,,,'.......                               .'''''....         ..''''''''''''
'''''''''''''''''''''''..           ..'''''''''''''.                       ..:dkkOkc.,;;,;;,;;,'.',:okO0000000kxddxO0KKKKK00000OxxkO0Okkl;;;,'',;;;;;::cldxxkO000OkkO0000000000000kxkxdddddxkOOOkxdddxO0KKOdodxxdddxOOOOko:;;;;,,,,,'.....'..                              ...''''....        .'''''''''''''
''''''''''''''''''''''''....       ..'''''''''''''..                         .:xkOOo;:loloo:;;;,'.',cdkO00000OOkdddk0KKKKKK00000kxxxkOkxol:;;,,,;;;;;;;:clodxOOOkkkkOO000000000000OkkxddddxO00000kxddxkO00kl:clooxOOOOOOOxl:;;;,,,,'...'',,..                                ...''''..        .'''''''''''''
''''''''''''''''''''''''''.... .....''''''''''''''.                          ..;lodc;cooxOOxdlc:;,..,cdO00000Okxdddk0KKKKKK0000000OkkkOOkkkxdollc;;;;;;:lcclodkdldkkOkO000000000000OkxoodxO000KK0kxddlok00xlc;:cokOOOOOOOOxolcc;,,,....,,,'..                                  ..''..        ..'''''''''''''
''''''''''''....''''''''''''....''''''''''''''''''.                            ..',,;ldddxkkOOkkxl;'',lk00000Okddddk0KKKKKK00000000OOOkO00OO0OOkxdlc;,,,;:;::coooxkkkkO000000KKKKKK0kdodkO000K0K0kxdl:okOOxoc;:ldOOOOOOOOOkxxxo:,,....',,'..                                   ..''..     ....''''''''''''''
'''''''''''..  .....''''''''''''''''''''''''''''''.                             ..',:oxkkkxxkkkOOxl;'':x000000OkxxxO00KKKK00000000OkkkxxxkkkkOkkxxoc,',,;;;,'':xOOOkdok000KKKKKKKKK0kkkO000000000OOxoodxxxdc;;cxOOOOOOOOOOkkOOd::,...',,'..                                   .'''...    ..'''''''''''''''''
'''''''''''.       .''''''''''''''''''''''''''''''..                            .;loxOOOOOOxoodxkkxo;',ok000000OOO0000000K00000000Okxxdddddddxxxkkdc''',;;;,';okOOOkodO0KKKKKKKKKKK0OO000000000000Okxxxxdoc;;:dOOOOOOOOOOOOOOkxol;...'''...         ....                     ..'''........''''''''''''''''''
'''''''''''.      ..'''''''''''''''''''''''''''.....                           ..:xOOOOOOOOOkl:;:c::,.';lxO00OOOO000000KK00000000000Okkxdodddddxxxxdc;;;;;,''lkOOOOOOO0KKKKKKKKKKKKK000000000000000kxxxdl:;;:dOOOOOOOOOOOOOOOOOd:,........         ..'..                     ..''''.......''''''''''''''''''
''''''''''..      ....''''''''''''''''''''''''...                              ..;okOOOOOOOOOxo:;,,'..',:dOO00OOOO0000KK00K000000000000OkkxdoodxxkOOkxddl:;';dO0000OO00KKKKKKK0KKKKK0000000000000Okxxdoc;;;:okOOOOOOOOOOOOOOOOkl'.  .....          ..''.                     ..'''''.''..'''''''''''''''''''
''''''''''.....      ......''''''''''''''''''...                                .lxOOOOOOOOOOOOkl,,,,codxOOO0K00000000000000000000000000000Okxxddxk000OOOkdccx0000000KKKKKKK000KKKKK00000000000Oxdddol::loddkOOOOOOOOOOOOOOOOOxc'...             ...'''.                    ..''''''''''''''''''''''''''''''
''''''''''......         ...'''''''''''''''''..                                 .;dkOOOOOOOOOOOOkoc:cdOOOOOO00KKKKKKK0000000000000OO00000000000OOkxkO0OOOOOxdk00000KKKKK000K00KKKKKK000000000Oxoc:::::lxkOOOOOOOOOOOOOOOOOOOOOkdlcl;.            ..'''..                    ..''''''''''''''''''''''''''''''
''''''''........           ...''''''''''.......                                 .,okkkkkkOOOOOOOOOkkkkOOOOOOOO0KKKKKKK000OOOOOOOOOOO0000000000KKK00OkOOO0OOO00000KKKKKK000KKKKKKKKK00000KK0Odc;;;;;;:lxOOOOOOkxxOOOOOOOOOOOOOkkdoxx:.            .'''..                      .''''''''''''''''''''''''''''''
'''''''... ..'..           ...''''''''...                                        ..cxkkkOOOOOOOOOOOOOOOOOOOOOOO00000KK000OOOOOOOOOOOOO000K00KKKKKKK00OOkO00KKKKKKKKKKK000KK0000KKKK000KK0Odc;;;;;;;:cdOOkkOOOkdxkkdxOOOOOOOOOxxkkkl.            ..'''...                      ..''''''''''''''''''''''''''''
''''''..........     .......'''''''''...                                           .,lxkOOOOOOOOOOOOOOOOOOOOOOOOOOOO0KKKK000000000OOOOkxdxO00KKKKKKKK00OOOKKKKKKKKKK00OO0000000KK000KKK0ko:;;;;;;:cclxdllxOOOOkkxl;;lxOOOOOkxxxkkx;.            ..'''''..                      ..'''''''''''''''''''''''''''
'''''''.......      ..'''..''''''''...                                               .,:lxkOOOOOOOOOOOOOOOOOOOOOOOOOOO0000KKKKKKKK0000kdlccodkO000KKKKK000KKKKKK000OOOOO0000000000000000xlc::;;;;;:clc::lkOOOOOkd:,,:oxooxo:;lxkxl.              .....''....                   ..'''''''''''''''''''''''''''
''''''''''''.      ...''''''''......                                                    ..;oddxkOOOOOOOkkkkOOOOOOOOOOOOOO000KKKKKKKKKKK0OdllooodkO00000000KK0000O00O000000000000OO00000Oxdlcc:;;;;;;;;;:dOOOkxxo:;,,;c:',;''',oo,..                 ..'''''.                  ...'''''''''.....'''''''''''''
''''''''''....   ..'''''''''...                                                            .',coddooddxkOOOOOOOOOOOOOOOOOOOOO00KKKKKKKKK0Okddxxdoodkkkkk0KK000000000000000000K00000000kxddoc:;;;;;;;;;;cdkkxl::;;;;,,'....   ...                     ...'''..            ......''''''''''.. ...'''''''''''''
'''''''''''.......'''''''''''..                                                        .....'',;;;;,;::lxOOOOOOOOOOOOOkkkkxxdooxkOO00OOO00kdoxkOkxdddxxk000000000OOO000000K000000000Okxdddol:;;;;;;;;;;:cccc;;;;;;;,,,,,'''.......                    ..''...           .........'''''''..   ...''''''''''''
'''''''''......''''''''''''''..                                               ...,,,,;::::;;;;:cc:::;;;;cldkOOOOOkxdkxocc::;;;;cc:cooc:codxdllodO00OkxxO00000OkxxkO00000000OOkO00Okkxddddol:;,,,'',;;;;;;;;;;;;;::;;;,,,,,,,,,,,,,,''....             ......         .......    ..''''..........''''''''''''
'''''''''......''''''''''''''.                                          ....':coxkOkkOOOOkdoodxxdlcll;'...,dkkkkkkkxxdoc;;,,,,,;;,,;;;,,,;:c:;;:oxkkOkkOOOOkxxddxk0K0K0OOkxxddxkxoloddddol;,,''...',,,,;,,'.....''',,;;;;;;;;,,,,,,,,,,,,,''...        . ..  .............        ....     ....'''''''''''''
'''''''''......''''''''''''...                                    ....'',,,,;:loodkkkOOkOOOkxddxddddxdlcc::lloxOOOOOOOOkdl:;;;;;;;;,,,,,,,;;;;;;;::lkOOkxxxxxddddxkkkdolllloddddolloddol:;,,'''''',,,,,;,''......   .....',,;;;;;;;;;,,,,,,,,,,'...         ..'''''''''..                      ....'''''''''
''''''''''''''''''''''''''..                                  ...',,,,,;;;;;;:ccc:::;,,'',,,'.';ldxxkkOkkkkd:;:loodxkOOOkkdlcc:;;,,,,,,,,,,,,,;;;;:ldxxxxxddolllcllc:;;;;;:lddoooooool:;;,,'',''',,,,,;,''''''''.......     ...';;:::;;;;;,,,,,,,,,'...      ...''''''''...                       ..''''''''
'''''''''''''''''''''''''''..                            ...'',,;;;;;;;::;;;;;;,..     .........',,,;cllc:::;''.''',:clooooddol:;,,,,''''',,,;;;;;;cddddol::::::;;;;;;;;;;;colllollc:;;,,,'''''',,,,,,,'''''...'...'..''....    ..,;:::::::;;;;;,,,,,,;,.      .''''''''''............            ..''''''''
''''''''''''''''''''''''''''..                       ...',,,;;;::::::::::;;;,..    ....'..............''',''''''''''''''',,;;,,,,'''''''',,,,;;;;;;;cc::;;;;;;;;;;;;;;;;;,,;c:::;;,,,,,,'''''''',,,,,,''''''''.........'..''...    .;::;;:::::::::;;;,,;'       ..'''''''''''''''''''...       ....'''''''''
'''''''''''''''''''''''''''''..                     .,;;;;:::::::::::::;;;'.    ................'''............'''''''''''''''''''''''''',,;;;;;;;;;;;;;;::;;;;;;;;;;,,,,,,,,,,,;,,,,,,,,,'''''',,,,'''''''''''...'........'..'..   ';;;;;;;;;::::::::;;,.       ..''''''''''''''''''''.........''''''''''''
''''''''''''''''''''''''''...                      .;:::::::::::::::::;;;.    .........'..................''''''''''''''''''''''''''''''''',,;;;;;;;::::c::;,,;,,,,''',,,;;;;;;;;;;;;,,,,,'''''''''''''''''''''................'.   .;;;;;;;:::::;::::::,.        .'''''''''''''.....''''''.''''''''''''''''
'''''''''''''''''''''''....                        ,cc:::::::::::::::::;'    .....'.....................''''''''''''''''''....'''''''.......'',,,,:clll:;,,,'''''''''',,,,,,;;;,,,,,,,''''''''''''''''''''''''...'...............   .;;;;;;;;:;;;;::::;;,.        ..'''''''''''......'''''''''''''''''''''''
'''''''''''''''''''''...                          .:lccc::::::::::;::::,.   .............................''''''''''''''.........................',::;,,'.'''''''''....''''',,,''''''''''''''''''''''''''''''''...'...'..........    .;;,;;;;;:;::::::;;;;.         ..'''''''''''....''''''''''''''''''''''''
''''''''''''''''''''.                             'cllllc::::::::::::;:,.     ..................''...''''''''''....''........................................................'''''''''''''''''''''''''''''''''...'..''........     .;;;;;;;;;;;;:::::;;;;.         ..'''''''''''...'''''''''''''''''''''''''
'''''''''''''''''....                             ,lllllcc:::::::::::;;;.      .......'...'''...''...''''''''.............................................................................''..''''''''''''''''..'...''......      .,;;,;;;;;;;:::::;;,;;;,         ...''''''''''''''''''''''''''''''''''''''
'''''''''''''''''....                            .;lccclcccc::::::::::;;,'.      .....'...'''...''...''..'......................................................................................'''''''''''''...'...''....       .;;;;;;;;;;;:::;;;;;;;;;,.        ....'''''''''''''''''''''''''''''''''''''
'''''''''''''''''.''.                            .:cc:clccccc::::::::::;;;;,..       .....'''...''.....................................................................................................''''''..''..'...      ...,;;;,;;;;;:::::;;:;;;;;;;,.       .'''''''''''''''''''''''''''''''''''''''''
'''''''''''''''......                            .;:::clcclcc:c:::::::::;,;;;;,...       ................................................................................................................'''''''....     ...',;;;;;,;;;;;:::::::::;;;;,;;,.       .'''''''''''''''''''''''''''''''''''''''''
'''''''''''''''..                                .,;;:cccclccccc::::::::;;;;;;;;;;,'...          ..............................................................................................................      ...',;;::;;;;;;;;;;::::::::;;;;;,,;;,.       ....''''''''''''''''''''''''''''''''''''''
'''''''''''''''..                                .,,,;:::cccclllccc:::::::;;;;;,;;;;;;;,'...           ..................................................................................................      ...'',,,;;:::;;;;;;;;;;::::::;;;;;;;;,;;,;,.        .....''''''''''''''''''''''''''''''''''''
'''''''''''''''...                               .''',,;:c::cllllllccc:::::;;;;;;;;;;;;;;;;,,,''.....               ..........................................................................       .......'',,;;;;;;;;;;;;;;;;;:::::::::;;;;;;;;;;;;;,;.             ..'''''''''''''''''''''''''''''''''''
'''''''''''''.''..                               .''',,,,;;:ccllllllllccc:::::;;;;;;;;;;;;;;;;;;;;;;,,''.......                         ...........................................        .........'',,,,;;;;;::;;;;;;;;;;;;;;::::::::;;;;::;;;;;;;;;;,.                .''''''''''''''''''''''''''''''''''
'''''''''''''''..                                 ..'''',,,;:ccllllllllllc:::::::::;;;;;;;;;::;;;::::;;;;;;;,,,,,,,,''''......................                      ....   ...............'''',,,,,,,,,;;;;::::::;;;;;;:::::::::::::;:::::;;;;;;;;;;:;..                 ...''''''''''''''''''''''''''''''''
'''''''''''''''..                                    ..'''',,;:ccllllllllllccccccc::::::::::::::::::::::::::;;;;;;;;;;;;;;;,,,,,,,,,,,,,,,,,''''...................'''''''''''''',,''''',,,,,,,,,;;;;;;;;;;:::::::;:::::::::::::::::;;;;;;;;;;;;;;:;..                     ..'''''''''''''''''''''''''''''''
'''''''''''''..                                        .'''',,;;:ccllllllllllllllccccccccc::::::::::::::::::::::::;;;;;;;:::::;::;;;;;;;;;;;,,;;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,;;;;;;;;;;;;;;;;;;;;;;:;;:::;;::::::::::::::::;;;::;;;;::::;.                         ..''''''''''''''''''''''''''''''
''''''''''''..                                           ..''',,,;;:ccllllllllllllllllllllccccccc::::::::::;;;;;;;;:::::::::::::::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;::;;;;;;;;;;;;::::::::::::::::::::::::::::::::::::::;;:cc:;,.                         ...'''''''''''''''''''''''''''''''
''''''''''''..                                              ..'',,,;;;:cccllllllllllllllllllllllllccccc::::::::;;;;;;;;;;;;;;;;;;;:::::::::::;;;;;;:::::::::::::::::::::::::;;;;;;;::::::::::::::::::::::::::::::::::::::::::::::::cc::::cc:,.                           ..'''''''''''''''''''''''''''''''''
''''''''''...                                                  ..'',,,,;;::ccllllllllllllllllllllllllllllccccccc:::::::;;;;;;;;;;;;:::::::::::;;;;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::cccccccccccc:,.     ..                       ..'''''''''''''''''''''''''''''''''
''''''''''..                                              .....    ..'',,,,;;::ccclllllllllllllllllllllllllllllcccccccccc::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::cccclcccc::::::::cc::::::ccccccllllc::,'.     .',;;'.                     .........''''''''''''''''''''''''''
'''''''.....                                           ..''''''....    ...',,,,,;;:::ccccclllllllllllllllllllllllllllllllllcccccccccc:::ccccccccc:::::cccccccccc:ccccccccccccccccllcccccccccccllllllllllcc::::ccccccccccccccccc:;'..    ..'',;;;;;;,.   ..........               ..'''''''''''''''''''''''''
'''......                                            ..',,'''''''''.....  .:c::;;;;;;;;;;;:::ccccclllllllllllllllllllllllllllllllllllccllllllllllcccllllllllllllclllllllllllllllllllllllllllllllllccccccccccccccccccccclllc;'..   ...,,,;:::;,,;;;:::,.  ......'''.......       ..''''''''''''''''''''''''''
'...                                  ........     ..''''''''''''''''''''',,;;::cccccc:::::;;;;;;;;::::cccccllllllllllllllllllllcccccccccccccccccccccccccccllllllllllllllllllllccccccllllllllllllcccccccccccccccclllllllllc,....',;;;:::;;;;;;;;;:::::;.        ....''......     ...''''''''''''''''''''''''
'.                                .........       .',,,''''''',,''''','''''''''',,;;:::ccccllccc:::::;;,,;;;;;:::ccccclllllllllllccccccccccccccccccccccccclllllllllllllllccccccccccccllllccccccccccccccccllllllllllccccccc::::::;;;;,;;;;;:::::::;;;;:::,.          ...''.....     ..'''''''''''''''''''''''
..                               ......          .,,'''''''''''''',,''',,'''',''''''''',,;;;:::::ccccc;........'',,;;;;:::cccccccccllllllcccccccclllllllllllllllllllllllccccclllllllllllllcccccclllllllllllcccccc:::::::::::::;;;;,;:::::cccc:;;::::;;;:::'           ..''''...     ..''''''''''''''''''''''
.                               .....           .,,,'''''''''''''',',,,,''',,,,,,,,'',,,,,,,,,,;;;;;;;;;;,''...........',,;;;:;;;:::::::ccccccllllllllllllllllllllllllllcccccc::::::;;;:clllllllccccccccc::::::::::::::;;;;;;;;::::::ccc:::ccc:;;;::::;;::;,.          ..'''...     ..''''''''''''''''''''''
.                              .....           .'',''''','''''',,'',,'',,,,,,,,,,,,,,,,;;,,,,,,,,,,;;;;;;;;;;;;;;,,,''...................'',,,,,,,,,;;;;;;;;;;;,,,''''''...............,:ccccc:::::::::::::::::;;;;;;;;;;:::cccccccc::cccc::ccc::;:::::;;;::;.         ...''...     ..'..'''''''''''''''''''
                              .....          .',,'''''',,'''''''',,,'',,,,,,,,,,,,;;;;;;;;;;::;;;;;;;,,,,,,;;;;;;;;;;;;;;;,,,''........................................'''',,,,,,,,;;;:::::::::::::::;;;;;;;;;;:::::::::::clllcccccccc:clllc::cc::;;;:::::;::;'        ....'...      .....''''''''''''''''''
                             .....          .',,,'''''''',''',,,,,''',,,,,,,,,,,;;;;;;;;;;:::::::::::::;;;,,;;;,,,,,,;;;;;;;;;;;;;;:::::::::::::::::;;;;;:;;::::::::::::::::::::::::::::::;;;;;;;;;;;;;::::cccccccccccccccclllllllllllccclllc::cc:::;:::::;;;;;.      ....'....          ....'''''''''''''''
                            .''...         .',''''''''''''''',,,,,,,,,,,,,;;;,,,,;;;;:::::::::::::::::::::;;::;;;;;;;;;;;;;;::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:::::::::::::::::::::::::::;;:::::ccccccccccccccccccccccccccclllllllllllccclllc:::::::;;::::,..      ..'.......              ..''''''''''''''
                            .''...         .,,,'..''''''''''',,,,,,,,,,;;;,,,,;;:::::::::::::::;;;;;;;::::::::::::cccccccccccc:::::;;;;;;;;;;;;;;;;;;;;;;;;;:::::::::::::::::::::::::::cc:::c:cccccccccccccccllcccccccccclllllllllllllllccclllc:::::c::::c:'    ...',,'.......               .....''''''''''
                            .,'...        .'',''''''''''''',,,'',,,,,;;:;;,,;;:::;;;::::::;;;;:::::::::::cccccccccllllllllllllccccccccccccccc:::::::::::::::::::::::::::::cccccccccccccclccccccccccclllllllllllllllllllllllllllllllllllllccllllc::cccc::::c:'..';;;;;,''....                     .''''''''''
                            .',''..        .....'''''''''',,,,,,,,,,;;;;,,:::::::::::::;;;::::::::cccclllllllllllllllllllllllllllllllllllllllllllllccllllllllllllccccccccllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllcccllllc::cccc::::c:;,,;;;;,'.....                      .....''''''
                             .,;,''...       ..'''''''''',,'',,,;;;;;;,,;:::::::::::;;::::::ccclllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllccllllc:::c::::;:c:;''''.....                              ....'''
                               .''.'''........'''''''''',,,,,,,;;;;;;;;::c:::::::::::::cccllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllccc::::::::::,...                                       ..''
                                  ....''''..''''''''''',,,,,,;;;;;;;;;::c::::::ccccccccllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllcccc::cc::::;'.                                        ...'''
                                      .....''''''''''',,',,,,;;;;;;;;:ccc::ccccccccclllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllcc:::::::cc:;,......',;.                               .'''''
                                           ...''''''',,,,,,,;;;;;:;;:ccccccllccccllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllcc::::::::cc:::::::;::c;.                              ..''''


*/
//Code By Raistilin, an NFT GAME by WENLAUNCH

pragma solidity ^0.8.4;













contract TestV3 is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, Ownable, ERC2981, ClampedRandomizer {
    constructor() 
        ERC721("testnet", "testv2") ClampedRandomizer(maxSupply) {
        _setDefaultRoyalty(royaltyAddress,  royalty);
        }

    //using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;
    uint maxSupply = 100;
    uint mintpointThreshold = 25;
    int baseMintPoints =10;
    int baseTransferPenalty = -10;
    int baseBurnPoints = 10; 
    int diamondHandsPenalty = -50;//ie you need to play the game to get points
    uint maxPerTx = 5;
    uint maxPerNonTeam = 50;
    uint maxPerTeam = 50;
    uint price = 1; //multiplied by 0.01 Avax later
    uint public totalMinted=0;
    uint public whitelistTime= 1661108400; //Sun Aug 21 2022 19:00:00 GMT+0000
    uint public allowlistTime= 1661109300; //Sun Aug 21 2022 19:15:00 GMT+0000
    uint public publicTime= 1661110200; //Sun Aug 21 2022 19:30:00 GMT+0000
    address public royaltyAddress=0x6E2219ccA862685F8818D0df2b1049215cBd3f0a;
    uint96 royalty=969;
    string public baseURI = "";
    string public unrevealedURI = "ipfs://QmWoPVSF25x9EzGtLzwAT5wsQnq4XBJhgastGwH4NoGd7A/UNRVLD-v3.json";
    address[10] pointLeaders;
    uint[10] leadersPoints;
    address[] participants; 
    int[] scores;
    bool gameEnded=false;
    

    struct metadata{
        uint32 number;
        uint32 suit;
        uint32 pointvalue;
        uint32 uniqueID;
    }

   

    mapping(address => uint) allowlistCount;
    mapping(address => bool) public allowListed;
    mapping(address => uint) whiteListedCount;
    mapping(address => bool) public whiteListed;
    mapping(address => uint) teamcount;
    mapping(address => bool) public teamlist;
    mapping(address => uint) publicCount;
    mapping(uint => bool) private _isRevealed;
    mapping(uint => bool) private _isMinted;
    mapping(address => int) public points;
    mapping(uint256 => metadata) public tokenIdToMetadata;
    mapping(uint256 => uint256) public tokenIdToLastMovedBlock;
    mapping(uint256 => uint256) public tokenIdToMintBlock;
    mapping(address => bool) public addrIsParticipating;


    function initializeMetadata(uint256[] memory tokenId, uint32[] memory _number, uint32[] memory _suit, uint32[] memory _pointvalue) public onlyOwner {
        for (uint i = 0; i < tokenId.length; i++) 
        {
            // key value mapping
            uint32 _uniqueID= _number[i]+100*_suit[i];
            tokenIdToMetadata[tokenId[i]]=metadata({number: _number[i], suit: _suit[i], pointvalue: _pointvalue[i], uniqueID: _uniqueID});
        }
    }

    function viewAllParticipants()public view returns(address[] memory){
        return participants;
    }

    function viewFinalScores()public view returns(int[] memory){
        return scores;
    }

    function viewFinalResults()public view returns(address[] memory,int[] memory){
        return (participants,scores);
    }


    function viewCurrentScores() public view returns(address[] memory,int[] memory){
        
        int [] memory tempScores =new int[](participants.length);
        //Warning only use this function once   
        for(uint i=0; i<participants.length;i++){
            tempScores[i]=points[participants[i]];
        }


        return (participants,tempScores);
    }


    function whiteList(address[] memory _addressList) external onlyOwner {
        require(_addressList.length > 0, "Error: list is empty");
        for (uint i = 0; i < _addressList.length; i++) {
            require(_addressList[i] != address(0), "Address cannot be 0.");
            whiteListedCount[_addressList[i]] = 0;
            whiteListed[_addressList[i]]= true;
        }
    }

    function teamList(address[] memory _addressList) external onlyOwner {
        require(_addressList.length > 0, "Error: list is empty");
        for (uint i = 0; i < _addressList.length; i++) {
            require(_addressList[i] != address(0), "Address cannot be 0.");
            teamcount[_addressList[i]] = 0;
            teamlist[_addressList[i]]= true;
        }
    }

    function allowList(address[] memory _addressList) external onlyOwner {
        require(_addressList.length > 0, "Error: list is empty");
        for (uint i = 0; i < _addressList.length; i++) {
            require(_addressList[i] != address(0), "Address cannot be 0.");
            allowlistCount[_addressList[i]] = 0;
            allowListed[_addressList[i]]= true;
        }
    }

    function mint(uint256 amount) public payable whenNotPaused {
        
        //mint start
        require(gameEnded == false, "Game Is over");
        require(block.timestamp >= whitelistTime, "Its not time to go Pyros yet");
        
        //supply limits
        uint supply = totalMinted;
        require(supply + amount <= maxSupply, "No more Pyros left for you");

        //transaction limits
        require(amount > 0,"you want to mint more than just air right?");
        require(amount <= maxPerTx, "Thats too many Pyros at once");

        //mint limits
        require(teamcount[msg.sender] < maxPerTeam, "Great apes should know you cant fit that many Pyros in your wallets");
        require(whiteListedCount[msg.sender] < maxPerNonTeam, "You exceeded your limit of Pyros");
        require(allowlistCount[msg.sender] < maxPerNonTeam, "You exceeded your limit of Pyros");
        

        
        if (price > 0) 
        {
            require(msg.value >= price * amount * 0.01 ether, "Send more money plz ser");
        }


        //white list and team mint
        if (block.timestamp < allowlistTime)  
        {
            require(whiteListed[msg.sender] ==true  || teamlist[msg.sender] == true, "Silly monkey Pyros are for WL only right now");
            if (whiteListed[msg.sender] == true )
                whiteListedCount[msg.sender]+=amount;
            if (teamlist[msg.sender]== true)
                teamcount[msg.sender] +=amount;
        }
 
        
        //allow list mint
        if ((block.timestamp >= allowlistTime)&&(block.timestamp < publicTime)) 
        {
            require(allowListed[msg.sender] == true , "Silly monkey Pyros are for WL only right now");
            if (allowListed[msg.sender]== true)
                allowlistCount[msg.sender] +=amount;
        }

        //public mint
        if (block.timestamp >= publicTime)
        {
            require(publicCount[msg.sender] < maxPerNonTeam, "You exceeded your limit of Pyros");   
        }
        
        
        for (uint i=1; i<=amount;i++) {    
            uint256 tokenId=_genClampedNonce()+1;//+1 since we dont want to deal with token id 0
            _isMinted[tokenId]=true;
            _safeMint(msg.sender, tokenId);
            _setTokenURI(tokenId, string(abi.encodePacked(tokenId.toString(), ".json")));
            if (supply < mintpointThreshold)// example if current supply is 0 and threshold is 250, you are first minter and get 250points,
            {
                updateParticipants(msg.sender);
                points[msg.sender] +=int(mintpointThreshold-supply+1-i); 
            }
            points[msg.sender] += baseMintPoints;
            //points[msg.sender] += baseTransferPoints;//compensate for transfer points lost
            tokenIdToMintBlock[tokenId]=block.number;
        }
        publicCount[msg.sender] +=amount;
        totalMinted+=amount;
    }

    function devMint(address to)
        public
        onlyOwner
    {
        uint supply = totalMinted;
        require(supply + 1 <= maxSupply, "No more Pyros left for you");
        uint256 tokenId=_genClampedNonce()+1;//+1 since we dont want to deal with token id 0
        _isMinted[tokenId]=true;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, string(abi.encodePacked(tokenId.toString(), ".json")));
        totalMinted+=1;
    }

    function setPrice(uint _price) public onlyOwner {
        price=_price;
    }  


    function revealbatch (uint _startId, uint _endId) public onlyOwner {
        for (uint i= _startId; i <= _endId; i++) {
            if (_isMinted[i]==true){
            _isRevealed[i]=true;
            }
        }
    }


    function setRoyalties(address _royaltyAddress, uint96 _royalty) public onlyOwner {
        _setDefaultRoyalty(_royaltyAddress,  _royalty);
        royaltyAddress=_royaltyAddress;
        royalty=_royalty;
    }

      
    function setWhitelistTime(uint _whitelistTime) public onlyOwner {
        whitelistTime=_whitelistTime;
        //enter unix timestamp
    }  

    function setAllowlistTime(uint _allowlistTime) public onlyOwner {
        allowlistTime=_allowlistTime;
        //enter unix timestamp
    }  

    function setPublicTime(uint _publicTime) public onlyOwner {
        publicTime=_publicTime;
        //enter unix timestamp
    } 


    function setBaseBurnPoints(int _baseBurnPoints) public onlyOwner {
        baseBurnPoints=_baseBurnPoints;
        
    }  

    function setBaseURI(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setUnrevealedURI(string memory _unrevealedURI) public onlyOwner {
        unrevealedURI = _unrevealedURI;
    }




    //@dev set all points to 0 and temporarily pause transfers etc so we can score
    function endgame() public onlyOwner {
        baseBurnPoints=0;
        pause();
        gameEnded=true;
        //score rarity points for holding at endgame and diamond hand points for all tokens that exist at end of game that never moved wallets
        for(uint i=0; i<totalSupply();i++){
            address _owner=ownerOf(tokenByIndex(i));
            points[_owner] += int(uint(tokenIdToMetadata[tokenByIndex(i)].pointvalue));
            if (tokenIdToLastMovedBlock[tokenByIndex(i)] == tokenIdToMintBlock[tokenByIndex(i)]){
                points[_owner]+= diamondHandsPenalty;
            }
        }

        //Warning only use this function once, tabulate points   
        for(uint i=0; i<participants.length;i++){
            scores.push(points[participants[i]]);
        }
    }



    //@dev: call everytime you add points to a player to check if they are on list of participants
    function updateParticipants (address _address) internal{
        if (addrIsParticipating[_address]==false){
            addrIsParticipating[_address]=true;
            participants.push(_address);
        }

    }


    //@dev call burn function and update points
    function burn(uint256 [] memory _tokenIds) public {
        for (uint i= 0; i < _tokenIds.length; i++) {
            require(ownerOf(_tokenIds[i])==msg.sender,"you dont own this token");
            _burn(_tokenIds[i]);
            updateParticipants(msg.sender);
            points[msg.sender] += baseBurnPoints;
            //points[msg.sender] -= baseTransferPenalty;//compensate for transfer points lost
            points[msg.sender] += int(uint(tokenIdToMetadata[_tokenIds[i]].pointvalue));
            
        }
    }


    function sort_array(uint[] memory arr) public returns (uint[] memory) {
            uint256 l = arr.length;
            for(uint i = 0; i < l; i++) {
                for(uint j = i+1; j < l ;j++) {
                    if(arr[i] > arr[j]) {
                        uint temp = arr[i];
                        arr[i] = arr[j];
                        arr[j] = temp;
                    }
                }
            }
            return arr;
        }
    


    function sumbitPokerHand(uint256 [] memory _tokenIds) public returns(uint [] memory hand, uint first, uint second) {

        require(_tokenIds.length <=5 ,"Too Many cards submitted");
        require(_tokenIds.length >0 ,"Too Few cards submitted");
        
        //need to check user owns tokens
        
        //sort hand
        //uint[] memory temp = new uint[](_tokenIds.length);
        uint[] memory sortedhand = new uint[](_tokenIds.length);
        uint[] memory sortedsuits = new uint[](_tokenIds.length);
        uint[] memory sortedvalues = new uint[](_tokenIds.length);
        for (uint i= 0; i < _tokenIds.length; i++){
            
            sortedhand[i]=tokenIdToMetadata[_tokenIds[i]].uniqueID;
            //sortedsuits[i]=tokenIdToMetadata[_tokenIds[i]].suit;
            sortedvalues[i]=tokenIdToMetadata[_tokenIds[i]].number;
        }
        

        sortedhand=sort_array(sortedhand);
        sortedvalues=sort_array(sortedvalues);
        
        //Check for duplicates
        for (uint i= 0; i < _tokenIds.length -1 ; i++){
                uint j=i+1;
                if (sortedhand[i] == sortedhand[j]){
                    revert("You submitted duplicate cards");
                }
            }
        
        uint firstMatch = 0;
        uint secondMatch = 0;
        //check for pair/3ofakind/4ofakind/5ofa/kind
        for (uint i= 0; i < _tokenIds.length -1 ; i++){
                uint j=i+1;
                if (firstMatch == 0){
                    if (sortedvalues[i] == sortedvalues[j]){
                        //"Pair found"
                        firstMatch++;
                        firstMatch++;

                    
                        if (j< _tokenIds.length -1) {
                            j++;
                            if (sortedvalues[i] == sortedvalues[j]){
                                //"trips found"
                                firstMatch++;
                                if (j< _tokenIds.length -1) {
                                    j++;
                                    if (sortedvalues[i] == sortedvalues[j]){
                                        //"Quads found"
                                        firstMatch++;
                                    }
                                    else{i=i+2;}
                                }
                            }
                            else{i++;}
                            
                        }
                        
                    }
                    
                }
                else{
                    if (secondMatch == 0){
                        if (sortedvalues[i] == sortedvalues[j]){
                            //"2Pair found"
                            secondMatch++;
                            secondMatch++;

                        
                            if (j< _tokenIds.length -1) {
                                j++;
                                if (sortedvalues[i] == sortedvalues[j]){
                                    //"full house found"
                                    secondMatch++;
                                    
                                }
                                else{i++;}
                                
                            }
                        }
                    }
                }
                
            } 



        //burn(_tokenIds);
        return (sortedhand, firstMatch, secondMatch);


    }


/// Generated by Openzepplin contract wizard and unmodified



    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }




    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint batchSize)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        updateParticipants(from);
        updateParticipants(to);
        if ((from != 0x0000000000000000000000000000000000000000) && (to != 0x0000000000000000000000000000000000000000)){
            points[from] += baseTransferPenalty; // penalize transfer to prevent wash trades but exclude 0 address
        }
        
        tokenIdToLastMovedBlock[tokenId]=block.number;
        
    }

 






    // The following functions are overrides required by Solidity.
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
        _isMinted[tokenId]=false;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        if (_isRevealed[tokenId]==true) 
        {
        // Token is revealed so use the revealed URI.
            return super.tokenURI(tokenId);
        }   
        else 
        {
        // Token is not revealed so use the unrevealed URI.
            return unrevealedURI;
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }


/// -------------------  added safety functions so things dont get stuck in contract -------------------

    /// @dev emergency withdraw contract balance to the contract owner
    function emergencyWithdraw() external onlyOwner {
        uint amount = address(this).balance;
        require(amount > 0, "Error: no fees :(");
        payable(msg.sender).transfer(amount);
    }

    /// @dev withdraw ERC20 tokens
    function withdrawTokens(address _tokenContract) external onlyOwner {
        IERC20 tokenContract = IERC20(_tokenContract);
        uint _amount = tokenContract.balanceOf(address(this));
        tokenContract.transfer(owner(), _amount);
    }

    /// @dev withdraw ERC721 tokens to the contract owner
    function withdrawNFT(address _tokenContract, uint[] memory _id) external onlyOwner {
        IERC721 tokenContract = IERC721(_tokenContract);
        for (uint i = 0; i < _id.length; i++) {
            tokenContract.safeTransferFrom(address(this), owner(), _id[i]);
        }
    }

    function emergencyAddPoints(address _address, int _points) external onlyOwner {
        points[_address] += _points;
    }

    function emergencySubtractPoints(address _address, int _points) external onlyOwner {
        points[_address] -= _points;
    }




}
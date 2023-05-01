/**
 *Submitted for verification at testnet.snowtrace.io on 2023-04-28
*/

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

library MessageLib {
    struct Message {
        uint8 action;
        bytes messageBody;
    }

    struct Target {
        uint256 value;
        address target;
        bytes data;
    }

    struct Payload {
        bytes body;
        uint8 action;
    }

    struct RemoteAssetBalance {
        uint128 newBalance;
        uint128 delta;
        address asset;
    }

    struct RemoteOrderBookEmptyMessage {
        RemoteAssetBalance[] balances;
    }

    uint8 internal constant ACTION_REMOTE_VAULT_MINT = 0;
    uint8 internal constant ACTION_REMOTE_VAULT_BURN = 1;
    uint8 internal constant ACTION_REMOTE_VAULT_ESCROW = 2;
    uint8 internal constant ACTION_RESERVE_TRANSFER = 3;
}

// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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

abstract contract GasAllocationViewer {
    /// @dev Gas allocation per message
    /// Gas allocation per messages consists of three parts:
    /// 1. Fixed gas portion (i.e. For burning this would be updating accounting and sending the callback)
    /// 2. Gas per byte of message - This is for cases where we have a dynamic payload so we need to approximate the gas cost.
    /// 3. Gas per message - This is the additional gas for instance to cache a failed message on the remote chain.
    struct GasAllocation {
        uint64 fixedGas;
        uint64 gasPerByte;
        uint64 gasPerMessage;
    }

    bytes32 internal constant ZERO_GAS_ALLOCATION_HASH =
        0x46700b4d40ac5c35af2c22dda2787a91eb567b06c924a8fb8ae9a05b20c08c21;

    mapping(uint256 => mapping(uint8 => GasAllocation)) internal minGasAllocation;

    function setGasAllocation(uint256 chainId, uint8 action, GasAllocation memory gas) external virtual;

    function getGasAllocation(uint8 action, uint256 chainId) external view virtual returns (GasAllocation memory);
    function defaultGasAllocation(uint8 action) external pure virtual returns (GasAllocation memory);
}

interface ActionHandler {
    function handleAction(MessageLib.Message calldata message, bytes calldata data) external payable;
}

// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

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

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_UINT256 = 2**256 - 1;

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // Divide x * y by the denominator.
            z := div(mul(x, y), denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // If x * y modulo the denominator is strictly greater than 0,
            // 1 is added to round up the division of x * y by the denominator.
            z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

library SubIndexLib {
    struct SubIndex {
        // TODO: make it uint128 ?
        uint256 id;
        uint256 chainId;
        address[] assets;
        uint256[] balances;
    }

    // TODO: increase precision
    uint32 internal constant TOTAL_SUPPLY = type(uint32).max;
}

interface ISubIndexFactory {
    function createSubIndex(uint256 chainId, address[] memory assets, uint256[] memory balances)
        external
        returns (uint256 id);

    function subIndexOf(uint256 id) external view returns (SubIndexLib.SubIndex memory);

    function subIndexesOf(uint256[] calldata ids) external view returns (SubIndexLib.SubIndex[] memory);
}

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

interface BridgingExecutor {
    function getTargetExecutionData(MessageLib.Payload calldata payload)
        external
        view
        returns (MessageLib.Target[] memory targets);
}

interface MessageRouterErrors {
    error MessageRouterBridgingImplementationNotFound(uint8 action);
    error MessageRouterActionHandlerNotFound(uint8 action);
}

contract MessageRouter is MessageRouterErrors, Owned {
    struct MessageRouterInfo {
        uint8 action;
        address actor;
    }

    /// @dev reserveAsset for the chain
    address public reserveAsset;

    /// @dev action => MessageHandler
    mapping(uint8 => address) public actionHandlers;

    /// @dev action => BridgingImplementation
    mapping(uint8 => address) internal bridgingImplementations;

    constructor(address _owner, address _reserveAsset) Owned(_owner) {
        reserveAsset = _reserveAsset;
    }

    function setReserveAsset(address _reserveAsset) external onlyOwner {
        reserveAsset = _reserveAsset;
    }

    function setBridgingImplementations(MessageRouterInfo[] calldata infos) external onlyOwner {
        for (uint256 i; i < infos.length; i++) {
            MessageRouterInfo calldata info = infos[i];
            bridgingImplementations[info.action] = info.actor;
        }
    }

    function setActionHandlers(MessageRouterInfo[] calldata infos) external onlyOwner {
        for (uint256 i; i < infos.length; i++) {
            MessageRouterInfo calldata info = infos[i];
            actionHandlers[info.action] = info.actor;
        }
    }

    /// @dev routeMessage routes the message to the correct handler,
    /// for now it have no access control for testing purposes, but in the future it will be restricted to only the bridge contract
    function routeMessage(MessageLib.Message calldata message, bytes calldata data) external payable {
        address handler = actionHandlers[message.action];
        if (handler == address(0)) {
            revert MessageRouterActionHandlerNotFound(message.action);
        }

        ActionHandler(handler).handleAction{value: address(this).balance}(message, data);
    }

    function generateTargets(MessageLib.Payload calldata payload)
        external
        view
        returns (MessageLib.Target[] memory targets)
    {
        address bridgingImplementation = getBridgingImplementation(payload.action);
        targets = BridgingExecutor(bridgingImplementation).getTargetExecutionData(payload);
    }

    function estimateFee(MessageLib.Payload calldata payload) external view returns (uint256 gasFee) {
        address bridgingImplementation = getBridgingImplementation(payload.action);
        MessageLib.Target[] memory targets = BridgingExecutor(bridgingImplementation).getTargetExecutionData(payload);
        uint256 length = targets.length;
        for (uint256 i; i < length;) {
            gasFee += targets[i].value;
            unchecked {
                i = i + 1;
            }
        }
    }

    function getBridgingImplementation(uint8 action) internal view returns (address) {
        address bridgingImplementation = bridgingImplementations[action];
        if (bridgingImplementation == address(0)) {
            revert MessageRouterBridgingImplementationNotFound(action);
        }

        return bridgingImplementation;
    }
}

contract BurningQueue {
    using Address for address;
    using FixedPointMathLib for *;
    using SafeTransferLib for ERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    struct QuoteParams {
        address swapTarget;
        address inputAsset;
        uint256 inputAmount;
        uint256 buyAssetMinAmount;
        uint256 additionalGas;
        bytes assetQuote;
    }

    struct BurnInfo {
        uint256 subIndexId;
        uint256 balance;
    }

    struct LocalQuotes {
        QuoteParams[] quotes;
    }

    struct Batch {
        QuoteParams[] quotes;
        uint256 chainId;
        bytes payload; // This payload is bridging implementation specific data.
    }

    struct IndexInfo {
        address index;
        address reserveAsset;
        address receiver;
    }

    address public immutable messageRouter;
    address public immutable outputAsset;
    address public immutable subIndexFactory;

    mapping(address => mapping(uint256 => uint256)) internal _burnBalanceOf;
    mapping(address => EnumerableSet.UintSet) internal _ids;

    constructor(address _messageRouter, address _outputAsset, address _subIndexFactory) {
        messageRouter = _messageRouter;
        outputAsset = _outputAsset;
        subIndexFactory = _subIndexFactory;
    }

    function remoteRedeem(uint256[] calldata subIndexIds, LocalQuotes[] calldata localQuotes, Batch[] calldata batches)
        external
        payable
    {
        SubIndexLib.SubIndex[] memory subIndexes = ISubIndexFactory(subIndexFactory).subIndexesOf(subIndexIds);
        uint256 localIndex;
        uint256 batchIndex;
        for (uint256 i; i < subIndexIds.length;) {
            uint256 subIndexId = subIndexIds[i];
            uint256 balance = _burnBalanceOf[msg.sender][subIndexId];
            SubIndexLib.SubIndex memory subIndex = subIndexes[i];

            if (subIndex.chainId == block.chainid) {
                _validate(balance, subIndex, localQuotes[localIndex].quotes);

                _handleLocalSwap(msg.sender, localQuotes[localIndex].quotes);

                unchecked {
                    localIndex = localIndex + 1;
                }
            } else {
                uint256 quoteIndex;

                uint256 length = subIndex.assets.length;
                for (uint256 j; j < length;) {
                    if (subIndex.chainId != batches[batchIndex].chainId) {
                        revert();
                    }

                    bool isCorrectAsset = true;
                    bool isCorrectAmount = true;
                    // TODO: uncomment next lines
                    // bool isCorrectAsset = batches[batchIndex].quotes[quoteIndex].inputAsset == subIndex.assets[j];
                    // bool isCorrectAmount =
                    //     batches[batchIndex].quotes[quoteIndex].inputAmount == subIndex.balances[j].mulDivDown(balance, SubIndexLib.TOTAL_SUPPLY);

                    if (!isCorrectAsset || !isCorrectAmount) {
                        revert();
                    }

                    if (quoteIndex == batches[batchIndex].quotes.length - 1) {
                        quoteIndex = 0;
                        unchecked {
                            batchIndex = batchIndex + 1;
                        }
                    } else {
                        if (j == length - 1) {
                            revert();
                        }
                        unchecked {
                            quoteIndex = quoteIndex + 1;
                        }
                    }

                    unchecked {
                        j = j + 1;
                    }
                }
            }

            dequeue(subIndexId, msg.sender);

            unchecked {
                i = i + 1;
            }
        }

        if (batchIndex != batches.length) {
            revert();
        }

        if (batches.length != 0) {
            _handleRemoteSwap(
                MessageLib.Payload({
                    body: abi.encode(
                        batches,
                        IndexInfo({
                            index: address(this), // TODO: replace address(this) with address of the index
                            reserveAsset: MessageRouter(messageRouter).reserveAsset(),
                            receiver: msg.sender
                        })
                        ),
                    action: MessageLib.ACTION_REMOTE_VAULT_BURN
                })
            );
        }
    }

    function enqueue(address receiver, BurnInfo[] calldata burnInfos) external {
        // TODO: only IndexAnatomy
        for (uint256 i; i < burnInfos.length;) {
            uint256 id = burnInfos[i].subIndexId;
            if (_ids[receiver].add(id)) {
                _burnBalanceOf[receiver][id] = burnInfos[i].balance;
            } else {
                _burnBalanceOf[receiver][id] += burnInfos[i].balance;
            }

            unchecked {
                i = i + 1;
            }
        }
    }

    function estimateFee(Batch[] calldata batches) external view returns (uint256) {
        return MessageRouter(messageRouter).estimateFee(
            MessageLib.Payload({
                body: abi.encode(
                    batches,
                    IndexInfo({
                        index: address(this),
                        reserveAsset: MessageRouter(messageRouter).reserveAsset(),
                        receiver: msg.sender
                    })
                    ),
                action: MessageLib.ACTION_REMOTE_VAULT_BURN
            })
        );
    }

    function pick(uint256 subIndexId, address receiver) external view returns (uint256 balance) {
        return _burnBalanceOf[receiver][subIndexId];
    }

    function ids(address receiver) external view returns (uint256[] memory) {
        return _ids[receiver].values();
    }

    function dequeue(uint256 subIndexId, address receiver) internal {
        if (!_ids[receiver].remove(subIndexId)) {
            revert();
        }

        delete _burnBalanceOf[receiver][subIndexId];
    }

    function _handleLocalSwap(address receiver, QuoteParams[] calldata params) internal {
        uint256 outputAssetBalanceBefore = ERC20(outputAsset).balanceOf(address(this));

        uint256 length = params.length;
        for (uint256 i; i < length;) {
            // TODO: withdraw assets from Vault
            _swap(
                params[i].inputAsset,
                params[i].inputAmount,
                params[i].buyAssetMinAmount,
                params[i].swapTarget,
                params[i].assetQuote
            );
            unchecked {
                i = i + 1;
            }
        }

        ERC20(outputAsset).safeTransfer(
            receiver, ERC20(outputAsset).balanceOf(address(this)) - outputAssetBalanceBefore
        );
    }

    function _handleRemoteSwap(MessageLib.Payload memory payload) internal {
        MessageLib.Target[] memory targets = MessageRouter(messageRouter).generateTargets(payload);
        uint256 msgValue = msg.value;
        for (uint256 i; i < targets.length; ++i) {
            MessageLib.Target memory t = targets[i];
            uint256 value = t.value;
            t.target.functionCallWithValue(t.data, value);
            msgValue -= value;
        }
        // In case user has sent more than needed, return the excess
        if (msgValue != 0) {
            Address.sendValue(payable(msg.sender), msgValue);
        }
    }

    function _swap(
        address inputAsset,
        uint256 assets,
        uint256 buyAssetMinAmount,
        address swapTarget,
        bytes calldata assetQuote
    ) internal {
        uint256 outputAssetBalanceBefore = ERC20(outputAsset).balanceOf(address(this));

        ERC20(inputAsset).safeApprove(swapTarget, assets);
        swapTarget.functionCall(assetQuote);

        ERC20(inputAsset).safeApprove(swapTarget, 0);
        if (ERC20(outputAsset).balanceOf(address(this)) - outputAssetBalanceBefore < buyAssetMinAmount) {
            revert(); //IndexLogicInvalidSwap();
        }
    }

    function _validate(uint256 balance, SubIndexLib.SubIndex memory subIndex, QuoteParams[] calldata quotes)
        internal
        pure
    {
        // TODO: uncomment next lines
        // uint256 length = quotes.length;
        // if (subIndex.assets.length != length) {
        //     revert();
        // }

        // for (uint256 i; i < length;) {
        //     bool isCorrectAsset = quotes[i].inputAsset == subIndex.assets[i];
        //     bool isCorrectAmount =
        //         quotes[i].inputAmount == subIndex.balances[i].mulDivDown(balance, SubIndexLib.TOTAL_SUPPLY);

        //     if (!isCorrectAsset || !isCorrectAmount) {
        //         revert();
        //     }

        //     unchecked {
        //         i = i + 1;
        //     }
        // }
    }
}

library ExcessivelySafeCall {
    uint256 constant LOW_28_MASK = 0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeCall(address _target, uint256 _gas, uint16 _maxCopy, bytes memory _calldata)
        internal
        returns (bool, bytes memory)
    {
        // set up for assembly call
        uint256 _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly {
            _success :=
                call(
                    _gas, // gas
                    _target, // recipient
                    0, // ether value
                    add(_calldata, 0x20), // inloc
                    mload(_calldata), // inlen
                    0, // outloc
                    0 // outlen
                )
            // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) { _toCopy := _maxCopy }
            // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
            // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeStaticCall(address _target, uint256 _gas, uint16 _maxCopy, bytes memory _calldata)
        internal
        view
        returns (bool, bytes memory)
    {
        // set up for assembly call
        uint256 _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly {
            _success :=
                staticcall(
                    _gas, // gas
                    _target, // recipient
                    add(_calldata, 0x20), // inloc
                    mload(_calldata), // inlen
                    0, // outloc
                    0 // outlen
                )
            // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) { _toCopy := _maxCopy }
            // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
            // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /**
     * @notice Swaps function selectors in encoded contract calls
     * @dev Allows reuse of encoded calldata for functions with identical
     * argument types but different names. It simply swaps out the first 4 bytes
     * for the new selector. This function modifies memory in place, and should
     * only be used with caution.
     * @param _newSelector The new 4-byte selector
     * @param _buf The encoded contract args
     */
    function swapSelector(bytes4 _newSelector, bytes memory _buf) internal pure {
        require(_buf.length >= 4);
        uint256 _mask = LOW_28_MASK;
        assembly {
            // load the first word of
            let _word := mload(add(_buf, 0x20))
            // mask out the top 4 bytes
            // /x
            _word := and(_word, _mask)
            _word := or(_newSelector, _word)
            mstore(add(_buf, 0x20), _word)
        }
    }
}

interface IVaultDeployer {
    struct Params {
        address asset; // The address of the asset the vault will hold
        address router; // The address of the router used to trade the asset
        address strategySetter; // The address that will be able to set the vault's strategy
    }

    /// @notice Deploys a new vault contract
    /// @param index The address of the index contract
    /// @param asset The address of the asset the vault will hold
    /// @return vault The address of the newly deployed vault contract
    function deploy(address index, address asset) external returns (address vault);

    /// @notice Returns the address of the vault for the specified index and asset
    /// @param index The address of the index contract
    /// @param asset The address of the asset the vault holds
    /// @return The address of the vault contract
    function vaultOf(address index, address asset) external view returns (address);

    /// @notice Returns the parameters used to deploy a vault contract
    /// @return asset The address of the asset the vault will hold
    /// @return router The address of the router used to communicate in OMNI
    /// @return strategySetter The address that will be able to set the vault's strategy
    function params() external view returns (address asset, address router, address strategySetter);
}

/// @title IVault
/// @notice Interface for a contract that manages the storage of a single asset.
interface IVault {
    /// @notice Set the strategy for the Vault
    /// @dev Can only be called by the strategySetter
    /// @param newStrategy The new strategy contract address
    function setStrategy(address newStrategy) external;

    /// @notice Set the strategy setter for the Vault
    /// @dev Can only be called by the current strategySetter
    /// @param newStrategySetter The new strategy setter address
    function setStrategySetter(address newStrategySetter) external;

    /// @notice Increase the balance of the Vault
    /// @dev Can only be called by authorized parties
    /// @param amount The amount of assets to increase the balance by.
    function increaseBalance(uint256 amount) external;

    /// @notice Transfers assets from this contract to the specified address.
    /// @dev Can only be called by authorized parties
    /// @param amount The amount of assets to transfer.
    /// @param to The address to transfer the assets to.
    function withdraw(uint256 amount, address to) external;

    /// @notice Returns the ERC20 asset managed by this contract.
    /// @return The ERC20 asset managed by this contract.
    function asset() external view returns (address);

    /// @notice Returns the address of the strategy setter
    /// @return The address of the strategy setter
    function strategySetter() external view returns (address);

    /// @notice Returns the Strategy contract attached to this vault.
    /// @return The Strategy contract attached to this vault.
    function strategy() external view returns (address);

    /// @notice Returns the Strategy contract attached to this vault.
    /// @return The Strategy contract attached to this vault.
    function balance() external view returns (uint256);
}

/// @title IReserveVault interface
/// @notice Contains logic for reserve management
interface IReserveVault {
    function withdraw(uint256 assets, address recipient) external;

    function asset() external view returns (address);
}

/// @title IIndexClient interface
/// @notice Contains index minting and burning logic
interface IIndexClient {
    /// @notice Emits each time when index is minted
    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    /// @notice Emits each time when index is burnt
    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 withdrawnReserveAssets,
        uint256 shares
    );

    /// @notice Deposits reserve assets and mints index
    ///
    /// @param reserveAssets Amount of reserve asset
    /// @param receiver Address of index receiver
    ///
    /// @param indexShares Amount of minted index
    function deposit(uint256 reserveAssets, address receiver, SubIndexLib.SubIndex[] calldata subIndexes)
        external
        returns (uint256 indexShares);

    /// @notice Burns index and withdraws reserveAssets
    ///
    /// @param indexShares Amount of index to burn
    /// @param owner Address of index owner
    /// @param receiver Address of assets receiver
    /// @param subIndexes List of SubIndexes
    ///
    /// @param reserveBefore Reserve value before withdraw
    /// @param subIndexBurnBalances SubIndex balances to burn
    function redeem(uint256 indexShares, address owner, address receiver, SubIndexLib.SubIndex[] calldata subIndexes)
        external
        returns (uint256 reserveBefore, uint32 subIndexBurnBalances);
}

contract RedeemRouter {
    using Address for address;
    using FixedPointMathLib for *;
    using SafeTransferLib for ERC20;

    struct QuoteParams {
        address swapTarget;
        address inputAsset;
        uint256 inputAmount;
        uint256 buyAssetMinAmount;
        uint256 additionalGas;
        bytes assetQuote;
    }

    struct LocalQuotes {
        QuoteParams[] quotes;
    }

    struct Batch {
        QuoteParams[] quotes;
        uint256 chainId;
        bytes payload; // This payload is bridging implementation specific data.
    }

    struct EscrowParams {
        uint256 subIndexId;
        uint256 remoteChainId;
        uint256 homeChainId;
        uint256 balance;
        address recipient;
    }

    struct RedeemData {
        LocalQuotes[] localData;
        Batch[] remoteData;
    }

    struct IndexInfo {
        address index;
        address reserveAsset;
        address receiver;
        uint256 subIndexesBurnAmount;
    }

    address public immutable messageRouter;

    constructor(address _messageRouter) {
        messageRouter = _messageRouter;
    }

    function redeem(
        address index,
        uint256 indexShares,
        address receiver,
        address owner,
        uint96 reserveCached,
        RedeemData calldata redeemData,
        SubIndexLib.SubIndex[] calldata subIndexes
    ) external payable {
        ERC20(index).safeTransferFrom(msg.sender, address(this), indexShares);
        (uint256 reserveBefore, uint32 subIndexesBurnBalance) =
            IIndexClient(index).redeem(indexShares, owner, receiver, subIndexes);

        if (subIndexes.length != 0) {
            if (reserveCached == reserveBefore) {
                _burnSubIndexes(
                    receiver, subIndexesBurnBalance, subIndexes, redeemData.localData, redeemData.remoteData
                );
            } else {
                // TODO: will be replaced with another approach
                //         _enqueueSubIndexes(
                //             indexShares - indexBurnt, state.totalSupply + feeAUM - indexBurnt, receiver, subIndexes
                //         );
            }
        }
    }

    function estimateRedeemFee(Batch[] calldata batches) external view returns (uint256) {
        return MessageRouter(messageRouter).estimateFee(
            MessageLib.Payload({
                body: abi.encode(
                    batches,
                    IndexInfo({
                        index: address(this),
                        reserveAsset: MessageRouter(messageRouter).reserveAsset(),
                        receiver: msg.sender,
                        // TODO: extend method to account for subIndex amount
                        subIndexesBurnAmount: 0
                    })
                    ),
                action: MessageLib.ACTION_REMOTE_VAULT_BURN
            })
        );
    }

    function _burnSubIndexes(
        address receiver,
        uint32 subIndexesBurnBalance,
        SubIndexLib.SubIndex[] calldata subIndexes,
        LocalQuotes[] calldata localQuotes,
        Batch[] calldata batches
    ) internal {
        uint256 localIndex;
        uint256 batchIndex;
        for (uint256 i; i < subIndexes.length;) {
            if (subIndexes[i].chainId == block.chainid) {
                _validate(subIndexesBurnBalance, subIndexes[i], localQuotes[localIndex].quotes);

                // _handleLocalSwap(reserveAsset, receiver, localQuotes[localIndex].quotes);

                unchecked {
                    localIndex = localIndex + 1;
                }
            } else {
                uint256 quoteIndex;

                uint256 length = subIndexes[i].assets.length;
                for (uint256 j; j < length;) {
                    if (subIndexes[i].chainId != batches[batchIndex].chainId) {
                        revert();
                    }

                    // TODO: uncomment code
                    bool isCorrectAsset = true;
                    bool isCorrectAmount = true;
                    // bool isCorrectAsset = batches[batchIndex].quotes[quoteIndex].inputAsset == subIndexes[i].assets[j];
                    // bool isCorrectAmount =
                    //     batches[batchIndex].quotes[quoteIndex].inputAmount == subIndexes[i].balances[j].mulDivDown(subIndexesBurnBalance, SubIndexLib.TOTAL_SUPPLY);

                    if (!isCorrectAsset || !isCorrectAmount) {
                        revert();
                    }

                    if (quoteIndex == batches[batchIndex].quotes.length - 1) {
                        quoteIndex = 0;
                        unchecked {
                            batchIndex = batchIndex + 1;
                        }
                    } else {
                        if (j == length - 1) {
                            revert();
                        }
                        unchecked {
                            quoteIndex = quoteIndex + 1;
                        }
                    }

                    unchecked {
                        j = j + 1;
                    }
                }
            }

            unchecked {
                i = i + 1;
            }
        }

        if (batchIndex != batches.length) {
            revert();
        }

        if (batches.length != 0) {
            _handleRemoteSwap(
                MessageLib.Payload({
                    body: abi.encode(
                        batches,
                        IndexInfo({
                            index: address(this), // TODO: replace address(this) with address of the index
                            reserveAsset: MessageRouter(messageRouter).reserveAsset(),
                            receiver: msg.sender,
                            subIndexesBurnAmount: subIndexesBurnBalance
                        })
                        ),
                    action: MessageLib.ACTION_REMOTE_VAULT_BURN
                })
            );
        }
    }

    function _escrowSubIndexes(
        address receiver,
        uint32 subIndexesBurnBalance,
        SubIndexLib.SubIndex[] calldata subIndexes
    ) internal {
        uint256 length = subIndexes.length;
        EscrowParams[] memory escrowParams = new EscrowParams[](
            length
        );

        for (uint256 i; i < length;) {
            escrowParams[i] =
                EscrowParams(subIndexes[i].id, subIndexes[i].chainId, block.chainid, subIndexesBurnBalance, receiver);

            unchecked {
                i = i + 1;
            }
        }

        _handleRemoteEscrow(receiver, escrowParams);
    }

    function _handleLocalSwap(address outputAsset, address receiver, QuoteParams[] calldata params) internal {
        uint256 outputAssetBalanceBefore = ERC20(outputAsset).balanceOf(address(this));

        uint256 length = params.length;
        for (uint256 i; i < length;) {
            // TODO: withdraw assets from Vault
            _swap(
                outputAsset,
                params[i].inputAsset,
                params[i].inputAmount,
                params[i].buyAssetMinAmount,
                params[i].swapTarget,
                params[i].assetQuote
            );
            unchecked {
                i = i + 1;
            }
        }

        ERC20(outputAsset).safeTransfer(
            receiver, ERC20(outputAsset).balanceOf(address(this)) - outputAssetBalanceBefore
        );
    }

    function _swap(
        address outputAsset,
        address inputAsset,
        uint256 assets,
        uint256 buyAssetMinAmount,
        address swapTarget,
        bytes memory assetQuote
    ) internal {
        uint256 outputAssetBalanceBefore = ERC20(outputAsset).balanceOf(address(this));

        ERC20(inputAsset).safeApprove(swapTarget, assets);
        swapTarget.functionCall(assetQuote);

        ERC20(inputAsset).safeApprove(swapTarget, 0);
        if (ERC20(outputAsset).balanceOf(address(this)) - outputAssetBalanceBefore < buyAssetMinAmount) {
            revert(); //IndexLogicInvalidSwap();
        }
    }

    function _handleRemoteSwap(MessageLib.Payload memory payload) internal {
        MessageLib.Target[] memory targets = MessageRouter(messageRouter).generateTargets(payload);
        _sendMessages(targets);
    }

    function _handleRemoteEscrow(address receiver, EscrowParams[] memory escrowParams) internal {
        //        MessageLib.Target[] memory targets = MessageRouter(messageRouter).generateTargets(
        //            MessageLib.Payload({body: abi.encode(escrowParams), action: MessageLib.ACTION_REMOTE_VAULT_ESCROW}),
        //            receiver
        //        );
        //        _sendMessages(targets);
    }

    function _sendMessages(MessageLib.Target[] memory targets) internal {
        uint256 msgValue = msg.value;
        for (uint256 i; i < targets.length; ++i) {
            MessageLib.Target memory t = targets[i];
            uint256 value = t.value;
            t.target.functionCallWithValue(t.data, value);
            msgValue -= value;
        }
        // In case user has sent more than needed, return the excess
        if (msgValue != 0) {
            Address.sendValue(payable(msg.sender), msgValue);
        }
    }

    function _validate(uint256 balance, SubIndexLib.SubIndex calldata subIndex, QuoteParams[] calldata quotes)
        internal
        pure
    {
        // TODO: uncomment code
        // uint256 length = quotes.length;
        // if (subIndex.assets.length != length) {
        //     revert();
        // }

        // for (uint256 i; i < length;) {
        //     bool isCorrectAsset = quotes[i].inputAsset == subIndex.assets[i];
        //     bool isCorrectAmount =
        //         quotes[i].inputAmount == subIndex.balances[i].mulDivDown(balance, SubIndexLib.TOTAL_SUPPLY);

        //     if (!isCorrectAsset || !isCorrectAmount) {
        //         revert();
        //     }

        //     unchecked {
        //         i = i + 1;
        //     }
        // }
    }
}

// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

interface TradingModuleErrors {
    error TradingModuleAlreadyInitialized();
    error TradingModuleForbidden();
    error TradingModuleEmptyQuote();
    error TradingModuleInvalid();
}

contract TradingModule is TradingModuleErrors, Initializable {
    using Address for address;
    using SafeTransferLib for ERC20;
    using ExcessivelySafeCall for address;
    using FixedPointMathLib for *;

    uint16 internal constant MAX_RETURN_DATA_SIZE = 150;

    // @dev Address of the vault deployer
    address internal immutable vaultDeployer;

    // @dev Message router address
    address internal immutable messageRouter;

    // @dev Index this action handler is for
    address internal index;

    // @dev Address of the user this trading module is for
    address internal user;

    event AssetsEscrowed(address indexed user, address indexed index, address indexed asset, uint256 amount);

    constructor(address _vaultDeployer, address _messageRouter) {
        vaultDeployer = _vaultDeployer;
        messageRouter = _messageRouter;
        _disableInitializers();
    }

    receive() external payable {}

    function initialize(address _index, address _user) external initializer {
        index = _index;
        user = _user;
    }

    function withdraw(address asset, uint256 amount, address to) external {
        if (msg.sender != user) {
            revert TradingModuleForbidden();
        }
        ERC20(asset).safeTransfer(to, amount);
    }

    function trade(
        GasAllocationViewer.GasAllocation calldata gasAllocation,
        SubIndexLib.SubIndex calldata subIndex,
        RedeemRouter.QuoteParams[] calldata quotes,
        uint256 burnAmount,
        uint256 srcChainId,
        address reserveAssetOnDst
    ) external payable {
        if (msg.sender != MessageRouter(messageRouter).actionHandlers(MessageLib.ACTION_REMOTE_VAULT_BURN)) {
            revert TradingModuleForbidden();
        }

        address _user = user;
        address _index = index;

        address reserveAssetOnHome = MessageRouter(messageRouter).reserveAsset();

        uint256 totalGasAllocation = gasAllocation.fixedGas + quotes.length * gasAllocation.gasPerMessage;

        for (uint256 i; i < subIndex.assets.length;) {
            RedeemRouter.QuoteParams calldata quote = quotes[i];
            // TODO: amount should be calculated out of this contract
            uint256 amountToWithdraw = subIndex.balances[i].mulDivDown(burnAmount, SubIndexLib.TOTAL_SUPPLY);
            // First withdraw all the assets from the vault
            IVault(IVaultDeployer(vaultDeployer).vaultOf(_index, subIndex.assets[i])).withdraw(
                amountToWithdraw, address(this)
            );
            address(this).excessivelySafeCall(
                gasleft() > totalGasAllocation ? gasleft() - totalGasAllocation : 0, // If a single trade spent too much we just pass 0 here and cache the remaining trades.
                MAX_RETURN_DATA_SIZE, // the max length of returned bytes data
                abi.encodeWithSelector(this.executeSwap.selector, reserveAssetOnHome, quote)
            );

            // emit an event with the new amount of assets in this escrow account. If the trading has failed it will be previously escrowed +  new amount
            emit AssetsEscrowed(_user, _index, quote.inputAsset, ERC20(quote.inputAsset).balanceOf(address(this)));

            totalGasAllocation -= gasAllocation.gasPerMessage;

            unchecked {
                i++;
            }
        }

        uint256 reserveAmount = ERC20(reserveAssetOnHome).balanceOf(address(this));
        if (reserveAmount == 0) {
            return;
        }

        MessageLib.Target[] memory targets = MessageRouter(messageRouter).generateTargets(
            MessageLib.Payload({
                body: abi.encode(srcChainId, reserveAmount, reserveAssetOnDst, reserveAssetOnHome, address(this), _user),
                action: MessageLib.ACTION_RESERVE_TRANSFER
            })
        );

        // This implementation assumes that there is only one target or we are sending reserve asset back to a single chain.
        assert(targets.length == 1);
        MessageLib.Target memory t = targets[0];

        ERC20(reserveAssetOnHome).safeTransfer(t.target, reserveAmount);
        (bool success,) = t.target.call{value: t.value, gas: gasleft() > 2000 ? gasleft() - 2000 : 0}(t.data); // 2k gas is to emit an event below, TBD!
        assert(success); // Since the sgSend is wrapped inside try/catch, this should never fail. If it fails it means that the reserve asset is stuck in the target contract.
        emit AssetsEscrowed(_user, _index, reserveAssetOnHome, ERC20(reserveAssetOnHome).balanceOf(address(this)));
    }

    function executeSwap(address reserveAsset, RedeemRouter.QuoteParams memory quote) public {
        if (msg.sender != address(this)) {
            revert TradingModuleForbidden();
        }
        if (quote.assetQuote.length == 0) {
            revert TradingModuleEmptyQuote();
        }

        uint256 outputAssetBalanceBefore = ERC20(reserveAsset).balanceOf(address(this));

        ERC20(quote.inputAsset).safeApprove(quote.swapTarget, ERC20(quote.inputAsset).balanceOf(address(this)));
        quote.swapTarget.functionCall(quote.assetQuote);
        ERC20(quote.inputAsset).safeApprove(quote.swapTarget, 0);

        if (ERC20(reserveAsset).balanceOf(address(this)) - outputAssetBalanceBefore < quote.buyAssetMinAmount) {
            revert TradingModuleInvalid();
        }
    }
}

// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }  
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

contract TradingModuleDeployer is Owned(msg.sender) {
    using Clones for address;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    address public currentTradingModule;

    EnumerableSet.AddressSet private tradingModules;

    constructor(address _tradingModule) {
        tradingModules.add(_tradingModule);
        currentTradingModule = _tradingModule;
    }

    function upgradeTradingModule(address _newTradingModuleImpl) external onlyOwner {
        tradingModules.add(_newTradingModuleImpl);
        currentTradingModule = _newTradingModuleImpl;
    }

    function deployTradingModuleForUser(address index, address user) external returns (address tmPerUser) {
        address _tradingModule = currentTradingModule;
        bytes32 salt = keccak256(abi.encodePacked(index, user));
        tmPerUser = _tradingModule.predictDeterministicAddress(salt);
        if (!address(tmPerUser).isContract()) {
            tmPerUser = _tradingModule.cloneDeterministic(salt);
            TradingModule(payable(tmPerUser)).initialize(index, user);
        }
    }

    function getTradingModulePerUser(address index, address user) external view returns (address) {
        return currentTradingModule.predictDeterministicAddress(keccak256(abi.encodePacked(index, user)));
    }

    function getTradingModulesPerUser(address index, address user)
        external
        view
        returns (address[] memory tradingModulesPerUser)
    {
        uint256 length = tradingModules.length();
        tradingModulesPerUser = new address[](length);
        for (uint256 i; i < length;) {
            tradingModulesPerUser[i] =
                tradingModules.at(i).predictDeterministicAddress(keccak256(abi.encodePacked(index, user)));

            unchecked {
                i++;
            }
        }
    }
}

/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */

library BytesLib {
    function concat(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bytes memory) {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for { let cc := add(_postBytes, 0x20) } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } { mstore(mc, mload(cc)) }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(
                0x40,
                and(
                    add(add(end, iszero(add(length, mload(_preBytes)))), 31),
                    not(31) // Round down to the nearest 32 bytes.
                )
            )
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint(bytes_storage) = uint(bytes_storage) + uint(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(fslot, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } { sstore(sc, mload(mc)) }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } { sstore(sc, mload(mc)) }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(bytes memory _bytes, uint256 _start, uint256 _length) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } { mstore(mc, mload(cc)) }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1, "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function touint(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "touint_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for { let cc := add(_postBytes, 0x20) }
                // the next line is the loop condition:
                // while(uint(mc < end) + cb == 2)
                eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(bytes storage _preBytes, bytes memory _postBytes) internal view returns (bool) {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external;

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external;
}

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(uint16 _dstChainId, bytes calldata _destination, bytes calldata _payload, address payable _refundAddress, address _zroPaymentAddress, bytes calldata _adapterParams) external payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(uint16 _srcChainId, bytes calldata _srcAddress, address _dstAddress, uint64 _nonce, uint _gasLimit, bytes calldata _payload) external;

    // @notice get the inboundNonce of a receiver from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainId, address _srcAddress) external view returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(uint16 _dstChainId, address _userApplication, bytes calldata _payload, bool _payInZRO, bytes calldata _adapterParam) external view returns (uint nativeFee, uint zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, bytes calldata _payload) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the non-reentrancy guard for send() is on
    // @return true if the guard is on. false otherwise
    function isSendingPayload() external view returns (bool);

    // @notice query if the non-reentrancy guard for receive() is on
    // @return true if the guard is on. false otherwise
    function isReceivingPayload() external view returns (bool);

    // @notice get the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _userApplication - the contract address of the user application
    // @param _configType - type of configuration. every messaging library has its own convention.
    function getConfig(uint16 _version, uint16 _chainId, address _userApplication, uint _configType) external view returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication) external view returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication) external view returns (uint16);
}

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external;
}

interface NonblockingLzAppErrors {
    error NonblockingLzAppInvalidAdapterParams();
    error NonblockingLzAppInvalidCaller();
    error NonblockingLzAppInvalidMinGas();
    error NonblockingLzAppInvalidPayload();
    error NonblockingLzAppInvalidSource();
    error NonblockingLzAppNoStoredMessage();
    error NonblockingLzAppNoTrustedPath();
    error NonblockingLzAppNotTrustedSource();
}

abstract contract NonblockingLzApp is
    Owned,
    NonblockingLzAppErrors,
    ILayerZeroReceiver,
    ILayerZeroUserApplicationConfig
{
    using BytesLib for bytes;
    using ExcessivelySafeCall for address;

    ILayerZeroEndpoint public immutable lzEndpoint;
    mapping(uint16 => bytes) public trustedRemoteLookup;
    mapping(uint16 => mapping(uint16 => uint256)) public minDstGasLookup;
    address public precrime;

    mapping(uint16 => mapping(bytes => mapping(uint64 => bytes32))) public failedMessages;

    event MessageFailed(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes _payload, bytes _reason);
    event RetryMessageSuccess(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes32 _payloadHash);
    event SetMinDstGas(uint16 _dstChainId, uint16 _type, uint256 _minDstGas);
    event SetPrecrime(address precrime);
    event SetTrustedRemote(uint16 _remoteChainId, bytes _path);
    event SetTrustedRemoteAddress(uint16 _remoteChainId, bytes _remoteAddress);

    // @todo use roles instead of owner
    constructor(address _lzEndpoint) Owned(msg.sender) {
        lzEndpoint = ILayerZeroEndpoint(_lzEndpoint);
    }

    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload)
        public
        virtual
        override
    {
        if (msg.sender != address(lzEndpoint)) {
            revert NonblockingLzAppInvalidCaller();
        }

        bytes memory trustedRemote = trustedRemoteLookup[_srcChainId];
        bool isValidSource = _srcAddress.length == trustedRemote.length && trustedRemote.length > 0
            && keccak256(_srcAddress) == keccak256(trustedRemote);
        if (!isValidSource) {
            revert NonblockingLzAppInvalidSource();
        }

        _blockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    function nonblockingLzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) public virtual {
        if (msg.sender != address(this)) {
            revert NonblockingLzAppInvalidCaller();
        }

        _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    function retryMessage(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload)
        public
        payable
        virtual
    {
        bytes32 payloadHash = failedMessages[_srcChainId][_srcAddress][_nonce];
        if (payloadHash == bytes32(0)) {
            revert NonblockingLzAppNoStoredMessage();
        }

        if (keccak256(_payload) != payloadHash) {
            revert NonblockingLzAppInvalidPayload();
        }

        delete failedMessages[_srcChainId][_srcAddress][_nonce];

        _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
        emit RetryMessageSuccess(_srcChainId, _srcAddress, _nonce, payloadHash);
    }

    function _nonblockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload)
        internal
        virtual;

    function _blockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload)
        internal
        virtual
    {
        (bool success, bytes memory reason) = address(this).excessivelySafeCall(
            gasleft(),
            150,
            abi.encodeWithSelector(this.nonblockingLzReceive.selector, _srcChainId, _srcAddress, _nonce, _payload)
        );
        if (!success) {
            revert();
        }
    }

    function _lzSend(
        uint16 _dstChainId,
        bytes memory _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams,
        uint256 _nativeFee
    ) internal virtual {
        bytes memory trustedRemote = trustedRemoteLookup[_dstChainId];
        if (trustedRemote.length == 0) {
            revert NonblockingLzAppNotTrustedSource();
        }

        lzEndpoint.send{value: _nativeFee}(
            _dstChainId, trustedRemote, _payload, _refundAddress, _zroPaymentAddress, _adapterParams
        );
    }

    function _checkGasLimit(uint16 _dstChainId, uint16 _type, bytes memory _adapterParams, uint256 _extraGas)
        internal
        view
        virtual
    {
        uint256 minGasLimit = minDstGasLookup[_dstChainId][_type] + _extraGas;
        if (minGasLimit > 0) {
            revert NonblockingLzAppInvalidMinGas();
        }

        uint256 providedGasLimit = _getGasLimit(_adapterParams);
        if (providedGasLimit < minGasLimit) {
            revert NonblockingLzAppInvalidMinGas();
        }
    }

    function _getGasLimit(bytes memory _adapterParams) internal pure virtual returns (uint256 gasLimit) {
        if (_adapterParams.length < 34) {
            revert NonblockingLzAppInvalidAdapterParams();
        }

        assembly {
            gasLimit := mload(add(_adapterParams, 34))
        }
    }

    function getConfig(uint16 _version, uint16 _chainId, address, uint256 _configType)
        external
        view
        returns (bytes memory)
    {
        return lzEndpoint.getConfig(_version, _chainId, address(this), _configType);
    }

    function setConfig(uint16 _version, uint16 _chainId, uint256 _configType, bytes calldata _config)
        external
        override
        onlyOwner
    {
        lzEndpoint.setConfig(_version, _chainId, _configType, _config);
    }

    function setSendVersion(uint16 _version) external override onlyOwner {
        lzEndpoint.setSendVersion(_version);
    }

    function setReceiveVersion(uint16 _version) external override onlyOwner {
        lzEndpoint.setReceiveVersion(_version);
    }

    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external override onlyOwner {
        lzEndpoint.forceResumeReceive(_srcChainId, _srcAddress);
    }

    function setTrustedRemote(uint16 _srcChainId, bytes calldata _path) external onlyOwner {
        trustedRemoteLookup[_srcChainId] = _path;
        emit SetTrustedRemote(_srcChainId, _path);
    }

    function setTrustedRemoteAddress(uint16 _remoteChainId, bytes calldata _remoteAddress) external onlyOwner {
        trustedRemoteLookup[_remoteChainId] = abi.encodePacked(_remoteAddress, address(this));
        emit SetTrustedRemoteAddress(_remoteChainId, _remoteAddress);
    }

    function getTrustedRemoteAddress(uint16 _remoteChainId) external view returns (bytes memory) {
        bytes memory path = trustedRemoteLookup[_remoteChainId];
        if (path.length == 0) {
            revert NonblockingLzAppNoTrustedPath();
        }

        return path.slice(0, path.length - 20);
    }

    function setPrecrime(address _precrime) external onlyOwner {
        precrime = _precrime;
        emit SetPrecrime(_precrime);
    }

    function setMinDstGas(uint16 _dstChainId, uint16 _packetType, uint256 _minGas) external onlyOwner {
        if (_minGas == 0) {
            revert NonblockingLzAppInvalidMinGas();
        }

        minDstGasLookup[_dstChainId][_packetType] = _minGas;
        emit SetMinDstGas(_dstChainId, _packetType, _minGas);
    }

    function isTrustedRemote(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool) {
        return keccak256(trustedRemoteLookup[_srcChainId]) == keccak256(_srcAddress);
    }
}

pragma abicoder v2;

interface ILayerZeroUltraLightNodeV2 {
    // Relayer functions
    function validateTransactionProof(uint16 _srcChainId, address _dstAddress, uint _gasLimit, bytes32 _lookupHash, bytes32 _blockData, bytes calldata _transactionProof) external;

    // an Oracle delivers the block data using updateHash()
    function updateHash(uint16 _srcChainId, bytes32 _lookupHash, uint _confirmations, bytes32 _blockData) external;

    // can only withdraw the receivable of the msg.sender
    function withdrawNative(address payable _to, uint _amount) external;

    function withdrawZRO(address _to, uint _amount) external;

    // view functions
    function getAppConfig(uint16 _remoteChainId, address _userApplicationAddress) external view returns (ApplicationConfiguration memory);

    function accruedNativeFee(address _address) external view returns (uint);

    struct ApplicationConfiguration {
        uint16 inboundProofLibraryVersion;
        uint64 inboundBlockConfirmations;
        address relayer;
        uint16 outboundProofType;
        uint64 outboundBlockConfirmations;
        address oracle;
    }

    event HashReceived(uint16 indexed srcChainId, address indexed oracle, bytes32 lookupHash, bytes32 blockData, uint confirmations);
    event RelayerParams(bytes adapterParams, uint16 outboundProofType);
    event Packet(bytes payload);
    event InvalidDst(uint16 indexed srcChainId, bytes srcAddress, address indexed dstAddress, uint64 nonce, bytes32 payloadHash);
    event PacketReceived(uint16 indexed srcChainId, bytes srcAddress, address indexed dstAddress, uint64 nonce, bytes32 payloadHash);
    event AppConfigUpdated(address indexed userApplication, uint indexed configType, bytes newConfig);
    event AddInboundProofLibraryForChain(uint16 indexed chainId, address lib);
    event EnableSupportedOutboundProof(uint16 indexed chainId, uint16 proofType);
    event SetChainAddressSize(uint16 indexed chainId, uint size);
    event SetDefaultConfigForChainId(uint16 indexed chainId, uint16 inboundProofLib, uint64 inboundBlockConfirm, address relayer, uint16 outboundProofType, uint64 outboundBlockConfirm, address oracle);
    event SetDefaultAdapterParamsForChainId(uint16 indexed chainId, uint16 indexed proofType, bytes adapterParams);
    event SetLayerZeroToken(address indexed tokenAddress);
    event SetRemoteUln(uint16 indexed chainId, bytes32 uln);
    event SetTreasury(address indexed treasuryAddress);
    event WithdrawZRO(address indexed msgSender, address indexed to, uint amount);
    event WithdrawNative(address indexed msgSender, address indexed to, uint amount);
}

interface IStargateRouter {
    struct lzTxObj {
        uint256 dstGasForCall; // extra gas, if calling smart contract,
        uint256 dstNativeAmount; // amount of dust dropped in destination wallet
        bytes dstNativeAddr; // destination wallet for dust
    }

    function addLiquidity(uint256 _poolId, uint256 _amountLD, address _to) external;

    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable;

    function redeemRemote(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        uint256 _minAmountLD,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function instantRedeemLocal(uint16 _srcPoolId, uint256 _amountLP, address _to) external returns (uint256);

    function redeemLocal(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function sendCredits(uint16 _dstChainId, uint256 _srcPoolId, uint256 _dstPoolId, address payable _refundAddress)
        external
        payable;

    function quoteLayerZeroFee(
        uint16 _dstChainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256);
}

interface ILayerZeroRelayerV2Viewer {
    function dstPriceLookup(uint16 chainId) external view returns (uint128 dstPriceRatio, uint128 dstGasPriceInWei);
}

library StargateFunctionType {
    uint8 internal constant TYPE_SWAP_REMOTE = 1;
    uint8 internal constant TYPE_ADD_LIQUIDITY = 2;
    uint8 internal constant TYPE_REDEEM_LOCAL_CALL_BACK = 3;
    uint8 internal constant TYPE_WITHDRAW_REMOTE = 4;
}

library ChainID {
    // Mainnet chainIDs
    uint256 internal constant ETHEREUM = 1;
    uint256 internal constant BSC = 56;
    uint256 internal constant AVALANCHE = 43_114;
    uint256 internal constant POLYGON = 137;
    uint256 internal constant ARBITRUM = 42_161;
    uint256 internal constant OPTIMISM = 10;
    uint256 internal constant FANTOM = 250;

    // Testnet chainIDs
    uint256 internal constant ETHEREUM_GOERLI = 5;
    uint256 internal constant ARBITRUM_GOERLI = 421_613;
    uint256 internal constant POLYGON_MUMBAI = 80_001;
    uint256 internal constant AVALANCHE_FUJI = 43_113;
}

library StargateInfoLib {
    struct StargateInfo {
        address layerZeroEndpoint;
        address stargateRouter;
    }

    // Layer zero enpoints addresses
    address internal constant ETHEREUM_LZ_ENDPOINT = 0x66A71Dcef29A0fFBDBE3c6a460a3B5BC225Cd675;
    address internal constant BSC_LZ_ENDPOINT = 0x3c2269811836af69497E5F486A85D7316753cf62;
    address internal constant AVALANCHE_LZ_ENDPOINT = 0x3c2269811836af69497E5F486A85D7316753cf62;
    address internal constant POLYGON_LZ_ENDPOINT = 0x3c2269811836af69497E5F486A85D7316753cf62;
    address internal constant ARBITRUM_LZ_ENDPOINT = 0x3c2269811836af69497E5F486A85D7316753cf62;
    address internal constant OPTIMISM_LZ_ENDPOINT = 0x3c2269811836af69497E5F486A85D7316753cf62;
    address internal constant FANTOM_LZ_ENDPOINT = 0xb6319cC6c8c27A8F5dAF0dD3DF91EA35C4720dd7;

    address internal constant ETHEREUM_GOERLI_LZ_ENDPOINT = 0xbfD2135BFfbb0B5378b56643c2Df8a87552Bfa23;
    address internal constant ARBITRUM_GOERLI_LZ_ENDPOINT = 0x6aB5Ae6822647046626e83ee6dB8187151E1d5ab;
    address internal constant AVALANCHE_FUJI_LZ_ENDPOINT = 0x93f54D755A063cE7bB9e6Ac47Eccc8e33411d706;

    // Stargate Router addresses
    address internal constant ETHEREUM_STARGATE_ROUTER = 0x8731d54E9D02c286767d56ac03e8037C07e01e98;
    address internal constant BSC_STARGATE_ROUTER = 0x4a364f8c717cAAD9A442737Eb7b8A55cc6cf18D8;
    address internal constant AVALANCHE_STARGATE_ROUTER = 0x45A01E4e04F14f7A4a6702c74187c5F6222033cd;
    address internal constant POLYGON_STARGATE_ROUTER = 0x45A01E4e04F14f7A4a6702c74187c5F6222033cd;
    address internal constant ARBITRUM_STARGATE_ROUTER = 0x53Bf833A5d6c4ddA888F69c22C88C9f356a41614;
    address internal constant OPTIMISM_STARGATE_ROUTER = 0xB0D502E938ed5f4df2E681fE6E419ff29631d62b;
    address internal constant FANTOM_STARGATE_ROUTER = 0xAf5191B0De278C7286d6C7CC6ab6BB8A73bA2Cd6;

    address internal constant ETHEREUM_GOERLI_STARGATE_ROUTER = 0x7612aE2a34E5A363E137De748801FB4c86499152;
    address internal constant ARBITRUM_GOERLI_STARGATE_ROUTER = 0xb850873f4c993Ac2405A1AdD71F6ca5D4d4d6b4f;
    address internal constant AVALANCHE_FUJI_STARGATE_ROUTER = 0x13093E05Eb890dfA6DacecBdE51d24DabAb2Faa1;

    function getStargateInfo(uint256 chainId) internal pure returns (StargateInfo memory info) {
        if (chainId == ChainID.ETHEREUM) {
            info = StargateInfo(ETHEREUM_LZ_ENDPOINT, ETHEREUM_STARGATE_ROUTER);
        } else if (chainId == ChainID.BSC) {
            info = StargateInfo(BSC_LZ_ENDPOINT, BSC_STARGATE_ROUTER);
        } else if (chainId == ChainID.AVALANCHE) {
            info = StargateInfo(AVALANCHE_LZ_ENDPOINT, AVALANCHE_STARGATE_ROUTER);
        } else if (chainId == ChainID.POLYGON) {
            info = StargateInfo(POLYGON_LZ_ENDPOINT, POLYGON_STARGATE_ROUTER);
        } else if (chainId == ChainID.ARBITRUM) {
            info = StargateInfo(ARBITRUM_LZ_ENDPOINT, ARBITRUM_STARGATE_ROUTER);
        } else if (chainId == ChainID.OPTIMISM) {
            info = StargateInfo(OPTIMISM_LZ_ENDPOINT, OPTIMISM_STARGATE_ROUTER);
        } else if (chainId == ChainID.FANTOM) {
            info = StargateInfo(FANTOM_LZ_ENDPOINT, FANTOM_STARGATE_ROUTER);
        } else if (chainId == ChainID.ETHEREUM_GOERLI) {
            info = StargateInfo(ETHEREUM_GOERLI_LZ_ENDPOINT, ETHEREUM_GOERLI_STARGATE_ROUTER);
        } else if (chainId == ChainID.ARBITRUM_GOERLI) {
            info = StargateInfo(ARBITRUM_GOERLI_LZ_ENDPOINT, ARBITRUM_GOERLI_STARGATE_ROUTER);
        } else if (chainId == ChainID.AVALANCHE_FUJI) {
            info = StargateInfo(AVALANCHE_FUJI_LZ_ENDPOINT, AVALANCHE_FUJI_STARGATE_ROUTER);
        } else {
            revert("Invalid chainId");
        }
    }
}

error LzChainInfoLibInvalid();

library LzChainInfoLib {
    struct ChainInfo {
        uint16 lzChainId;
        uint256 chainId;
    }

    ///@dev The default lz chain id for each chain.
    uint16 internal constant ETHEREUM_LZ = 101;
    uint16 internal constant BSC_LZ = 102;
    uint16 internal constant AVALANCHE_LZ = 106;
    uint16 internal constant POLYGON_LZ = 109;
    uint16 internal constant ARBITRUM_LZ = 110;
    uint16 internal constant OPTIMISM_LZ = 111;
    uint16 internal constant FANTOM_LZ = 112;
    uint16 internal constant ETHEREUM_GOERLI_LZ = 10_121;
    uint16 internal constant POLYGON_MUMBAI_LZ = 10_109;
    uint16 internal constant ARBITRUM_GOERLI_LZ = 10_143;
    uint16 internal constant AVALANCHE_FUJI_LZ = 10_106;

    function getDefaultLzChainId() internal view returns (uint16 lzChainId) {
        return getDefaultLzChainId(block.chainid);
    }

    function getDefaultLzChainId(uint256 chainId) internal pure returns (uint16 lzChainId) {
        if (chainId == ChainID.ETHEREUM) {
            lzChainId = ETHEREUM_LZ;
        } else if (chainId == ChainID.BSC) {
            lzChainId = BSC_LZ;
        } else if (chainId == ChainID.AVALANCHE) {
            lzChainId = AVALANCHE_LZ;
        } else if (chainId == ChainID.POLYGON) {
            lzChainId = POLYGON_LZ;
        } else if (chainId == ChainID.ARBITRUM) {
            lzChainId = ARBITRUM_LZ;
        } else if (chainId == ChainID.OPTIMISM) {
            lzChainId = OPTIMISM_LZ;
        } else if (chainId == ChainID.FANTOM) {
            lzChainId = FANTOM_LZ;
        } else if (chainId == ChainID.ETHEREUM_GOERLI) {
            lzChainId = ETHEREUM_GOERLI_LZ;
        } else if (chainId == ChainID.POLYGON_MUMBAI) {
            lzChainId = POLYGON_MUMBAI_LZ;
        } else if (chainId == ChainID.ARBITRUM_GOERLI) {
            lzChainId = ARBITRUM_GOERLI_LZ;
        } else if (chainId == ChainID.AVALANCHE_FUJI) {
            lzChainId = AVALANCHE_FUJI_LZ;
        } else {
            revert LzChainInfoLibInvalid();
        }
    }
}

library LzGasEstimation {
    using StargateInfoLib for uint256;

    struct StargateTransferInfo {
        uint8 sgFunctionType;
        address receiver;
        bytes payload;
        IStargateRouter.lzTxObj lzTxParams;
    }

    struct LzTransferInfo {
        address lzApp;
        uint256 remoteGas;
        address addressOnRemote;
        bool payInZro;
        bytes remotePayload;
    }

    /// @notice Multiplier for price ratio
    uint256 internal constant LZ_PRICE_RATIO_MULTIPLIER = 1e10;

    function estimateGas(address lzEndpoint, uint16 remoteChainId, LzTransferInfo memory lzTransferInfo)
        internal
        view
        returns (uint256 totalFee, bytes memory adapterParams)
    {
        adapterParams =
            abi.encodePacked(uint16(2), lzTransferInfo.remoteGas, uint256(0), lzTransferInfo.addressOnRemote);

        // Total fee required for function execution + payload + airdrop
        (totalFee,) = ILayerZeroEndpoint(lzEndpoint).estimateFees(
            uint16(remoteChainId),
            lzTransferInfo.addressOnRemote,
            lzTransferInfo.remotePayload,
            lzTransferInfo.payInZro,
            adapterParams
        );
    }

    function estimateGasForMessageWithSgCallback(
        uint16 homeChainId,
        uint16 remoteChainId,
        StargateTransferInfo memory sgTransferInfo,
        LzTransferInfo memory lzTransferInfo
    ) internal view returns (uint256 totalFee, bytes memory adapterParams) {
        StargateInfoLib.StargateInfo memory info = block.chainid.getStargateInfo();
        // This is estimation of value to pass to sgSend on the remote , and this will be airdropped there!
        (uint256 sgCallbackMessageFee,) = IStargateRouter(info.stargateRouter).quoteLayerZeroFee(
            homeChainId, // destination chainId
            sgTransferInfo.sgFunctionType, // function type: see Bridge.sol for all types
            abi.encodePacked(sgTransferInfo.receiver), // destination of tokens
            sgTransferInfo.payload, // payload, using abi.encode()
            sgTransferInfo.lzTxParams
        );

        uint256 dstPriceRatio = getDstPriceRatio(info.layerZeroEndpoint, lzTransferInfo.lzApp, remoteChainId);
        uint256 amountToAirdrop = sgCallbackMessageFee * LZ_PRICE_RATIO_MULTIPLIER / dstPriceRatio;

        adapterParams =
            abi.encodePacked(uint16(2), lzTransferInfo.remoteGas, amountToAirdrop, lzTransferInfo.addressOnRemote);

        // Total fee required for function execution + payload + airdrop
        (totalFee,) = ILayerZeroEndpoint(info.layerZeroEndpoint).estimateFees(
            uint16(remoteChainId),
            lzTransferInfo.addressOnRemote,
            lzTransferInfo.remotePayload,
            lzTransferInfo.payInZro,
            adapterParams
        );
    }

    /// @dev This function is used to get the price ratio of homeChain to remoteChain gas token
    function getDstPriceRatio(address lzEndpoint, address lzApp, uint16 remoteChainId)
        internal
        view
        returns (uint256 dstPriceRatio)
    {
        ILayerZeroUltraLightNodeV2 node =
            ILayerZeroUltraLightNodeV2(ILayerZeroEndpoint(lzEndpoint).getSendLibraryAddress(lzApp));
        ILayerZeroUltraLightNodeV2.ApplicationConfiguration memory config = node.getAppConfig(remoteChainId, lzApp);
        (dstPriceRatio,) = ILayerZeroRelayerV2Viewer(config.relayer).dstPriceLookup(remoteChainId);
    }
}

interface BridgingLogicClient {
    function generateTargets(MessageLib.Payload calldata payload, bytes4 functionSelector)
        external
        view
        returns (MessageLib.Target[] memory targets);
}

interface OmniNonblockingAppErrors {
    error OmniNonblockingAppForbidden();
}

contract NonblockingApp is OmniNonblockingAppErrors, NonblockingLzApp, BridgingExecutor {
    using LzGasEstimation for uint256;

    address internal bridgingLogic;

    MessageRouter internal messageRouter;

    constructor(address _messageRouter, address _lzEndpoint) NonblockingLzApp(_lzEndpoint) {
        messageRouter = MessageRouter(_messageRouter);
    }

    function send(
        uint16 dstChainId,
        bytes memory payload,
        address payable refundAddress,
        address payable callbackAddress,
        bytes memory adapterParams,
        uint256 value
    ) external payable {
        _lzSend(dstChainId, payload, refundAddress, callbackAddress, adapterParams, value);
    }

    function setBridgingLogic(address _bridgingLogic) external onlyOwner {
        bridgingLogic = _bridgingLogic;
    }

    function getTargetExecutionData(MessageLib.Payload calldata payload)
        external
        view
        returns (MessageLib.Target[] memory)
    {
        return BridgingLogicClient(bridgingLogic).generateTargets(payload, NonblockingApp.send.selector);
    }

    function _nonblockingLzReceive(uint16 _srcChainid, bytes memory, uint64, bytes memory _payload) internal override {
        MessageLib.Message memory message = abi.decode(_payload, (MessageLib.Message));
        messageRouter.routeMessage{value: address(this).balance}(
            message,
            abi.encode(_srcChainid, GasAllocationViewer(bridgingLogic).getGasAllocation(message.action, block.chainid))
        );
    }
}

/// @title IMessageSender interface
/// @notice Contains logic to send message
interface IMessageSender {
    /// @notice Sends message to remote chain
    ///
    /// @param message Message to send to remote chain
    function sendMessage(MessageLib.Message calldata message) external;

    /// @notice Sends messages to remote chains
    ///
    /// @param messages Messages to send to remote chains
    function sendMessage(MessageLib.Message[] calldata messages) external;
}

error MessageSubject__Forbidden();

/// @title MessageSubject abstract contract
/// @notice Contains address of MessageRouter
abstract contract MessageSubject {
    /// @dev Address of MessageRouter
    IMessageSender internal messageRouter;

    modifier onlyMessageRouter() {
        _checkSender();

        _;
    }

    constructor(address _messageRouter) {
        messageRouter = IMessageSender(_messageRouter);
    }

    /// TODO: Remove this function after testing
    function setMessageRouter(address _messageRouter) external {
        messageRouter = IMessageSender(_messageRouter);
    }

    /// @dev Checks if `msg.sender` is MessageRouter contract
    function _checkSender() internal view {
        if (msg.sender != address(messageRouter)) {
            revert MessageSubject__Forbidden();
        }
    }
}

contract SubIndexFactory is ISubIndexFactory {
    uint256 internal _lastId;

    mapping(uint256 => SubIndexLib.SubIndex) internal _subIndexes;

    function createSubIndex(uint256 chainId, address[] memory assets, uint256[] memory balances)
        external
        returns (uint256 id)
    {
        // TODO: only orderer
        if (assets.length != balances.length) {
            revert();
        }

        unchecked {
            id = ++_lastId;
        }

        _subIndexes[id] = SubIndexLib.SubIndex(id, chainId, assets, balances);
    }

    function subIndexOf(uint256 id) external view returns (SubIndexLib.SubIndex memory) {
        return _subIndexes[id];
    }

    function subIndexesOf(uint256[] calldata ids) external view returns (SubIndexLib.SubIndex[] memory result) {
        result = new SubIndexLib.SubIndex[](ids.length);

        for (uint256 i; i < ids.length;) {
            result[i] = _subIndexes[ids[i]];
            unchecked {
                i = i + 1;
            }
        }
    }
}

contract RemoteSubIndexFactory {
    uint256 internal _lastId;

    mapping(address => SubIndexLib.SubIndex) internal _subIndexes;

    function createSubIndex(address index, address[] memory assets, uint256[] memory balances)
        external
        returns (uint256 id)
    {
        // TODO: only orderer
        if (assets.length != balances.length) {
            revert();
        }

        unchecked {
            id = ++_lastId;
        }

        _subIndexes[index] = SubIndexLib.SubIndex(id, block.chainid, assets, balances);
    }

    function subIndexOf(address index) external view returns (SubIndexLib.SubIndex memory) {
        return _subIndexes[index];
    }
}

interface BurningActionHandlerErros {
    error BurningActionHandlerForbiddenCaller(address caller);
}

contract BurningActionHandler is BurningActionHandlerErros, ActionHandler, MessageSubject {
    using Address for address;

    // @dev Address of the trading module deployer
    address internal immutable tradingModuleDeployer;

    address internal immutable subIndexFactory;

    constructor(address _tradingModuleDeployer, address _subIndexFactory, address _messageRouter)
        MessageSubject(_messageRouter)
    {
        tradingModuleDeployer = _tradingModuleDeployer;
        subIndexFactory = _subIndexFactory;
    }

    // @dev Routes the burning action to the user's tradingModule
    function handleAction(MessageLib.Message calldata message, bytes calldata data) external payable override {
        _checkSender();

        (
            RedeemRouter.QuoteParams[] memory quotes,
            address index,
            address reserveAssetOnDst,
            address receiver,
            uint256 burnAmount
        ) = abi.decode(message.messageBody, (RedeemRouter.QuoteParams[], address, address, address, uint256));
        (uint16 srcChainId, GasAllocationViewer.GasAllocation memory gasAllocation) =
            abi.decode(data, (uint16, GasAllocationViewer.GasAllocation));

        address payable tradingModule =
            payable(TradingModuleDeployer(tradingModuleDeployer).deployTradingModuleForUser(index, receiver));
        TradingModule(tradingModule).trade{value: address(this).balance}(
            gasAllocation,
            RemoteSubIndexFactory(subIndexFactory).subIndexOf(index),
            quotes,
            burnAmount,
            srcChainId,
            reserveAssetOnDst
        );
    }
}
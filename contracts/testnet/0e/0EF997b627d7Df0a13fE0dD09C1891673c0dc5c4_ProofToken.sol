// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.19;

interface IJoeRouter01 {
    function factory() external pure returns (address);

    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountAVAX, uint256 liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAX(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAXWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactAVAX(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapAVAXForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    function getAmountsIn(
        uint256 amountOut,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);
}

interface IJoeRouter02 is IJoeRouter01 {
    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountAVAX);

    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.19;

interface IProofToken {
    struct Tax {
        uint16 revenueRate;
        uint16 stakingRate;
        uint16 ventureFundRate;
        uint16 ventureFundRateForWhale;
    }

    /// @notice Enable/Disable trading.
    /// @dev Only owner can call this function.
    function enableTrading(bool _enable) external;

    /// @notice Add bots address.
    /// @dev Only owner can call this function.
    function setBots(address[] memory _bots) external;

    /// @notice Set maxWallet amount.
    /// @dev ONly owner can call this function.
    function setMaxWallet(uint256 _maxWallet) external;

    /// @notice Set maxTransfer amount.
    /// @dev Only owner can call this function.
    function setMaxTransfer(uint256 _maxTransfer) external;

    /// @notice Set release time for airdrop.
    /// @dev Only owner can call this function.
    function setAirdropReleaseTime(uint256 _airdropReleaseTime) external;

    /// @notice Set new minHLDAmountForAirdrop.
    /// @dev Only owner can call this function.
    function setMinHLDAmountForAirdrop(uint256 _minHLDAmountForAirdrop) external;

    /// @notice Remove bots address.
    /// @dev Only owner can call this function.
    function delBots(address[] memory _bots) external;

    /// @notice Set revenue address.
    /// @dev Only owner can call this function.
    function setRevenue(address _revenue) external;

    /// @notice The Proof token for bots go to treasury wallet.
    /// @dev Only owner can call this function.
    function setTreasury(address _treasury) external;

    /// @notice Set Staking contract address.
    /// @dev Only owner can call this function.
    function setStakingContract(address _staking) external;

    /// @notice Set venture fund address.
    /// @dev Only owner can call this function.
    function setVentureFund(address _ventureFund) external;

    /// @notice Set tax for buy.
    /// @dev Only owner can call this function.
    function setTaxForBuy(Tax memory _tax) external;

    /// @notice Set tax for sell.
    /// @dev Only owner can call this function.
    function setTaxForSell(Tax memory _tax) external;

    /// @notice HLD holder requests airdrop.
    /// @dev HLD holder can call this function only one time.
    function requestAirdrop() external;

    /// @notice Claim Proof token as much as current HLD token liquidity pool holds.
    /// @dev This can be called by only owner.
    function claimLiquidityAmount(address _pairAddress) external;

    /// @notice Withdraw rest Proof token after airdrop.
    /// @dev This can be called by only owner.
    function withdrawRestAmount(uint256 _amount) external;

    /// @notice Set new SwapThreshold amount and enable swap flag.
    /// @dev Only owner can call this function.
    function setSwapBackSettings(
        uint256 _swapThreshold,
        bool _swapEnable
    ) external;

    /// @notice Exclude wallets from TxLimit.
    /// @dev Only owner can call this function.
    function excludeWalletsFromTxLimit(
        address[] memory _wallets,
        bool _exclude
    ) external;

    /// @notice Exclude wallets from MaxWallet.
    /// @dev Only owner can call this function.
    function excludeWalletsFromMaxWallet(
        address[] memory _wallets,
        bool _exclude
    ) external;

    /// @notice Exclude wallets from Tax Fees.
    /// @dev Only owner can call this function.
    function excludeWalletsFromFees(
        address[] memory _wallets,
        bool _exclude
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) external pure returns (uint amountB);

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountOut);

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountIn);

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function getAmountsIn(
        uint amountOut,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./interfaces/IProofToken.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IJoeRouter02.sol";
import "./interfaces/IUniswapV2Factory.sol";

contract ProofToken is Ownable, Pausable, IERC20, IProofToken {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public bots;
    mapping(address => bool) public excludedFromTxLimit;
    mapping(address => bool) public excludedFromMaxWallet;
    mapping(address => bool) public excludedFromFees;
    mapping(address => bool) public airdropped;

    EnumerableSet.AddressSet private holders;

    uint256 private _totalSupply = 100_000_000 * 10 ** _decimals;
    uint256 private DIVIDE_MULTIPLIER = 10_000;
    uint256 public maxTransfer;
    uint256 public maxWallet;
    uint256 public antiWhaleDuration = 24 hours;
    uint256 public airdroppedAmount;
    uint256 public launchTime;
    uint256 public swapThreshold;

    uint256 public accAmountForStaking;
    uint256 public accAmountForRevenue;
    uint256 public accAmountForVentureFund;
    uint256 public airdropReleaseTime;
    uint256 public minHLDAmountForAirdrop;

    address public HLDToken;
    address public revenue;
    address public stakingContract;
    address public ventureFund;
    address public treasury;
    address public pair;
    // address public constant DEAD = 0x000000000000000000000000000000000000dEaD;

    Tax public taxForBuy;
    Tax public taxForSell;

    address public router;

    bool public tradingEnable;
    bool private inSwapLiquidity;
    bool public swapEnable;
    bool public withdrawed;

    string private _name = "PROOF";
    string private _symbol = "$PROOF";

    uint8 private constant _decimals = 9;
    uint16 public MIN_HOLD_RATE = 2; // 0.2%
    uint16 public FIXED_POINT = 1000;

    /// @dev Status flag to show airdrop is already processed or not.
    bool public airdropProcessed;

    constructor(
        address _hldToken,
        address _router,
        address _revenue,
        address _ventureFund,
        address _treasury,
        uint256 _airdropReleaseTime,
        uint256 _minHLDAmountForAirdrop,
        Tax memory _taxForBuy,
        Tax memory _taxForSell
    ) {
        require(_hldToken != address(0), "zero HLD token address");
        require(_router != address(0), "zero router address");
        require(_revenue != address(0), "zero revenue address");
        require(_ventureFund != address(0), "zero ventureFund address");
        require(_treasury != address(0), "zero treasury address");
        require(
            _airdropReleaseTime > block.timestamp,
            "airdropReleaseTime is before current time"
        );
        require(
            _minHLDAmountForAirdrop >= DIVIDE_MULTIPLIER,
            "invalid minHLDAmountForAirdrop"
        );
        minHLDAmountForAirdrop = _minHLDAmountForAirdrop;
        airdropReleaseTime = _airdropReleaseTime;
        HLDToken = _hldToken;
        revenue = _revenue;
        ventureFund = _ventureFund;
        treasury = _treasury;

        _balances[address(this)] = _totalSupply;
        emit Transfer(address(0), address(this), _totalSupply);

        maxWallet = _totalSupply / 100; // 1%
        maxTransfer = (_totalSupply * 5) / 1000; // 0.5%

        router = _router;
        _createPair();

        swapThreshold = _totalSupply / 10000; // 0.01%

        excludedFromTxLimit[msg.sender] = true;
        excludedFromTxLimit[pair] = true;
        excludedFromTxLimit[treasury] = true;
        excludedFromTxLimit[address(this)] = true;

        excludedFromMaxWallet[msg.sender] = true;
        excludedFromMaxWallet[pair] = true;
        excludedFromMaxWallet[treasury] = true;
        excludedFromMaxWallet[address(this)] = true;
        excludedFromMaxWallet[revenue] = true;
        excludedFromMaxWallet[stakingContract] = true;
        excludedFromMaxWallet[ventureFund] = true;

        excludedFromFees[msg.sender] = true;
        excludedFromFees[_revenue] = true;
        excludedFromFees[_ventureFund] = true;
        excludedFromFees[stakingContract] = true;

        taxForBuy = _taxForBuy;
        taxForSell = _taxForSell;
        swapEnable = true;

        launchTime = block.timestamp;
    }

    // !---------------- functions for ERC20 token ----------------!
    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address _recipient,
        uint256 _amount
    ) external override returns (bool) {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }

    function allowance(
        address _owner,
        address _spender
    ) external view override returns (uint256) {
        return _allowances[_owner][_spender];
    }

    function approve(
        address _spender,
        uint256 _amount
    ) external override returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) external override returns (bool) {
        uint256 currentAllowance = _allowances[_sender][msg.sender];
        require(currentAllowance >= _amount, "Transfer > allowance");
        _approve(_sender, msg.sender, currentAllowance - _amount);
        _transfer(_sender, _recipient, _amount);
        return true;
    }

    // !---------------- functions for ERC20 token ----------------!

    /// @inheritdoc IProofToken
    function excludeWalletsFromTxLimit(
        address[] memory _wallets,
        bool _exclude
    ) external override onlyOwner {
        uint256 length = _wallets.length;
        require(length > 0, "invalid array");

        for (uint256 i = 0; i < length; i++) {
            excludedFromTxLimit[_wallets[i]] = _exclude;
        }
    }

    /// @inheritdoc IProofToken
    function excludeWalletsFromMaxWallet(
        address[] memory _wallets,
        bool _exclude
    ) external override onlyOwner {
        uint256 length = _wallets.length;
        require(length > 0, "invalid array");
        for (uint256 i = 0; i < length; i++) {
            excludedFromMaxWallet[_wallets[i]] = _exclude;
        }
    }

    /// @inheritdoc IProofToken
    function excludeWalletsFromFees(
        address[] memory _wallets,
        bool _exclude
    ) external override onlyOwner {
        uint256 length = _wallets.length;
        require(length > 0, "invalid array");
        for (uint256 i = 0; i < length; i++) {
            excludedFromFees[_wallets[i]] = _exclude;
        }
    }

    /// @inheritdoc IProofToken
    function enableTrading(bool _enable) external override onlyOwner {
        tradingEnable = _enable;
    }

    /// @inheritdoc IProofToken
    function setMaxWallet(uint256 _maxWallet) external override onlyOwner {
        require(_maxWallet > 0, "invalid maxWallet");
        maxWallet = _maxWallet;
    }

    /// @inheritdoc IProofToken
    function setMaxTransfer(uint256 _maxTransfer) external override onlyOwner {
        require(_maxTransfer > 0, "invalid maxTransfer");
        maxTransfer = _maxTransfer;
    }

    /// @inheritdoc IProofToken
    function setSwapBackSettings(
        uint256 _swapThreshold,
        bool _swapEnable
    ) external override onlyOwner {
        swapEnable = _swapEnable;
        swapThreshold = _swapThreshold;
    }

    /// @inheritdoc IProofToken
    function setBots(address[] memory _bots) external override onlyOwner {
        uint256 length = _bots.length;
        require(length > 0, "invalid bots array");
        for (uint256 i = 0; i < length; i++) {
            bots[_bots[i]] = true;
        }
    }

    /// @inheritdoc IProofToken
    function delBots(address[] memory _bots) external override onlyOwner {
        uint256 length = _bots.length;
        require(length > 0, "invalid bots array");
        for (uint256 i = 0; i < length; i++) {
            bots[_bots[i]] = false;
        }
    }

    /// @inheritdoc IProofToken
    function setTreasury(address _treasury) external override onlyOwner {
        require(_treasury != address(0), "zero treasury address");
        treasury = _treasury;
    }

    /// @inheritdoc IProofToken
    function setRevenue(address _revenue) external override onlyOwner {
        require(_revenue != address(0), "zero revenue address");
        excludedFromFees[revenue] = false;
        excludedFromFees[_revenue] = true;
        revenue = _revenue;
    }

    /// @inheritdoc IProofToken
    function setStakingContract(address _staking) external override onlyOwner {
        require(_staking != address(0), "zero staking contract address");
        if (stakingContract != address(0)) {
            excludedFromFees[stakingContract] = false;
        }
        excludedFromFees[_staking] = true;
        stakingContract = _staking;
    }

    /// @inheritdoc IProofToken
    function setVentureFund(address _ventureFund) external override onlyOwner {
        require(_ventureFund != address(0), "zero revenue address");
        excludedFromFees[ventureFund] = false;
        excludedFromFees[_ventureFund] = true;
        ventureFund = _ventureFund;
    }

    /// @inheritdoc IProofToken
    function setTaxForBuy(Tax memory _tax) external override onlyOwner {
        taxForBuy = _tax;
    }

    /// @inheritdoc IProofToken
    function setTaxForSell(Tax memory _tax) external override onlyOwner {
        taxForSell = _tax;
    }

    /// @inheritdoc IProofToken
    function setAirdropReleaseTime(
        uint256 _airdropReleaseTime
    ) external onlyOwner {
        require(
            _airdropReleaseTime > block.timestamp,
            "airdropReleaseTime is before current time"
        );
        airdropReleaseTime = _airdropReleaseTime;
    }

    /// @inheritdoc IProofToken
    function setMinHLDAmountForAirdrop(
        uint256 _minHLDAmountForAirdrop
    ) external onlyOwner {
        require(
            _minHLDAmountForAirdrop >= DIVIDE_MULTIPLIER,
            "invalid minHLDAmountForAirdrop"
        );
        minHLDAmountForAirdrop = _minHLDAmountForAirdrop;
    }

    /// @inheritdoc IProofToken
    function requestAirdrop() external {
        address sender = msg.sender;
        require(
            sender != address(0) && !bots[sender],
            "invalid caller address"
        );
        require(
            block.timestamp > airdropReleaseTime,
            "before airdropReleaseTime"
        );
        uint256 holdAmount = IERC20(HLDToken).balanceOf(sender);
        require(
            holdAmount >= minHLDAmountForAirdrop,
            "not enough HLD token balance for airdrop"
        );
        require(!airdropped[sender], "already airdropped");

        uint256 proofAmount = holdAmount / DIVIDE_MULTIPLIER;
        require(
            _balances[address(this)] >= proofAmount,
            "not enough balance for airdrop"
        );
        _balances[sender] += proofAmount;
        _balances[address(this)] -= proofAmount;
        airdropped[sender] = true;
        airdroppedAmount += proofAmount;
    }

    /// @inheritdoc IProofToken
    function claimLiquidityAmount(
        address _pairAddress
    ) external override onlyOwner {
        _distributeProofToken(_pairAddress, owner());
    }

    /// @inheritdoc IProofToken
    function withdrawRestAmount(uint256 _amount) external override onlyOwner {
        uint256 availableAmount = _balances[address(this)];
        require(availableAmount >= _amount, "not enough balance to withdraw");
        _transfer(address(this), owner(), availableAmount);
    }

    receive() external payable {}

    function _transfer(
        address _sender,
        address _recipient,
        uint256 _amount
    ) internal {
        require(_sender != address(0), "transfer from zero address");
        require(_recipient != address(0), "transfer to zero address");
        require(_amount > 0, "zero amount");
        require(_balances[_sender] >= _amount, "not enough amount to transfer");
        require(
            tradingEnable || (_sender == owner() || _sender == address(this)),
            "trading is not enabled"
        );

        if (inSwapLiquidity || !tradingEnable) {
            _basicTransfer(_amount, _sender, _recipient);
            emit Transfer(_sender, _recipient, _amount);
            return;
        }

        require(
            excludedFromTxLimit[_sender] || _amount <= maxTransfer,
            "over max transfer amount"
        );
        require(
            excludedFromMaxWallet[_recipient] ||
                _balances[_recipient] + _amount <= maxWallet,
            "exceeds to max wallet"
        );

        bool feelessTransfer = (excludedFromFees[_sender] ||
            excludedFromFees[_recipient]);

        if (_sender == pair) {
            // buy
            if (feelessTransfer) {
                _basicTransfer(_amount, _sender, _recipient);
            } else {
                _takeFee(taxForBuy, _amount, _sender, _recipient);
            }
        } else {
            _distributeFees();
            // sell or wallet transfer
            if (_recipient == pair) {
                // sell
                if (feelessTransfer) {
                    _basicTransfer(_amount, _sender, _recipient);
                } else {
                    _takeFee(taxForSell, _amount, _sender, _recipient);
                }
            } else {
                _basicTransfer(_amount, _sender, _recipient);
            }
        }

        emit Transfer(_sender, _recipient, _amount);
    }

    function _basicTransfer(
        uint256 _amount,
        address _sender,
        address _recipient
    ) internal {
        _balances[_sender] -= _amount;
        _balances[_recipient] += _amount;
    }

    function _takeFee(
        Tax memory _tax,
        uint256 _amount,
        address _sender,
        address _recipient
    ) internal {
        uint16 ventureRate = block.timestamp > launchTime + antiWhaleDuration
            ? _tax.ventureFundRate
            : _tax.ventureFundRateForWhale;
        uint16 totalFee = _tax.revenueRate + _tax.stakingRate + ventureRate;

        uint256 feeAmount = (_amount * totalFee) / FIXED_POINT;
        uint256 revenueFee = (_amount * _tax.revenueRate) / FIXED_POINT;
        uint256 stakingFee = (_amount * _tax.stakingRate) / FIXED_POINT;
        uint256 ventureFee = feeAmount - revenueFee - stakingFee;

        accAmountForRevenue += revenueFee;
        accAmountForStaking += stakingFee;
        accAmountForVentureFund += ventureFee;

        uint256 transferAmount = _amount - feeAmount;

        _balances[address(this)] += feeAmount;
        _balances[_sender] -= _amount;
        _balances[_recipient] += transferAmount;
    }

    function _distributeFees() internal {
        uint256 feeAmount = accAmountForRevenue +
            accAmountForStaking +
            accAmountForVentureFund;

        if (feeAmount < swapThreshold || !swapEnable) {
            return;
        }

        if (feeAmount > 0) {
            inSwapLiquidity = true;
            _swapTokensToETH(feeAmount);
            uint256 swappedETHAmount = address(this).balance;
            inSwapLiquidity = false;

            uint256 revenueFee = (swappedETHAmount * accAmountForRevenue) /
                feeAmount;
            uint256 ventureFee = (swappedETHAmount * accAmountForVentureFund) /
                feeAmount;
            uint256 stakingFee = swappedETHAmount - revenueFee - ventureFee;

            _transferETH(revenue, revenueFee);
            _transferETH(stakingContract, stakingFee);
            _transferETH(ventureFund, ventureFee);
        }

        accAmountForRevenue = 0;
        accAmountForStaking = 0;
        accAmountForVentureFund = 0;
    }

    function _swapTokensToETH(uint256 _amount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _getWrappedToken();

        _approve(address(this), router, _amount);
        if (_isETHLayer()) {
            IUniswapV2Router02(router)
                .swapExactTokensForETHSupportingFeeOnTransferTokens(
                    _amount,
                    0,
                    path,
                    address(this),
                    block.timestamp
                );
        } else {
            IJoeRouter02(router)
                .swapExactTokensForAVAXSupportingFeeOnTransferTokens(
                    _amount,
                    0,
                    path,
                    address(this),
                    block.timestamp
                );
        }
    }

    function _transferETH(address _to, uint256 _amount) internal {
        if (_amount == 0) return;

        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "sending ETH failed");
    }

    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) private {
        require(_owner != address(0), "Approve from zero");
        require(_spender != address(0), "Approve to zero");
        _allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    function _distributeProofToken(
        address _holder,
        address _recipient
    ) internal returns (uint256) {
        require(!airdropped[_holder], "already airdropped");
        uint256 airdropAmount = _calcAirdropAmount(_holder);

        if (airdropAmount > 0) {
            _balances[address(this)] -= airdropAmount;
            _balances[_recipient] += airdropAmount;
            airdropped[_holder] = true;
            airdroppedAmount += airdropAmount;
        }

        return airdropAmount;
    }

    function _calcAirdropAmount(
        address _holder
    ) internal view returns (uint256) {
        uint256 balance = IERC20(HLDToken).balanceOf(_holder);
        return balance / DIVIDE_MULTIPLIER;
    }

    function _createPair() internal {
        address WToken = _getWrappedToken();
        pair = IUniswapV2Factory(IUniswapV2Router02(router).factory())
            .createPair(WToken, address(this));
    }

    function _getWrappedToken() internal view returns (address) {
        return
            _isETHLayer()
                ? IUniswapV2Router02(router).WETH()
                : IJoeRouter02(router).WAVAX();
    }

    function _isETHLayer() internal view returns (bool) {
        uint256 chainId = block.chainid;
        if (chainId == 43114 || chainId == 43113) {
            // AVAX or Fuji
            return false;
        }

        return true;
    }
}
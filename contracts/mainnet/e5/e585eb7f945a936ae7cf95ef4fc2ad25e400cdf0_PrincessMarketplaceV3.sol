/**
 *Submitted for verification at snowtrace.io on 2022-07-24
*/

// SPDX-License-Identifier: AGPL-3.0-or-later AND MIT

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol
pragma solidity ^0.8.0;
/**
 * @dev Required interface of an ERC721 compliant contract.
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

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
			      address from,
			      address to,
			      uint256 tokenId
			      ) external;
    function transferFrom(
			  address from,
			  address to,
			  uint256 tokenId
			  ) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(
			      address from,
			      address to,
			      uint256 tokenId,
			      bytes calldata data
			      ) external;
}
// File: @openzeppelin/contracts/utils/Context.sol
pragma solidity ^0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/* ERC20 and ERC20P (following ERC712) */
pragma solidity ^0.8.0;
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from,address to,uint256 amount) external returns (bool);
}
/* ERC712 permit interface */
interface IERC20P is IERC20 {
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
}

// File: @openzeppelin/contracts/access/Ownable.sol
pragma solidity ^0.8.0;

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)
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
     *p
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


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


// File: @openzeppelin/contracts/utils/Address.sol
pragma solidity ^0.8.0;
/**
 * @dev Collection of functions related to the address type
 */
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
	size := extcodesize(account)
		}
        return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(
			  address target,
			  bytes memory data,
			  string memory errorMessage
			  ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(
				   address target,
				   bytes memory data,
				   uint256 value
				   ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
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
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(
				address target,
				bytes memory data,
				string memory errorMessage
				) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(
				  address target,
				  bytes memory data,
				  string memory errorMessage
				  ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
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

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


pragma solidity ^0.8.0;
interface INFTKEYMarketplaceV2 {
    struct Listing {
        uint256 tokenId;
        uint256 value;
        address seller;
        uint256 expireTimestamp;
    }
    struct Bid {
        uint256 tokenId;
        uint256 value;
        address bidder;
        uint256 expireTimestamp;
    }
    struct TokenBids {
        EnumerableSet.AddressSet bidders;
        mapping(address => Bid) bids;
    }
    struct ERC721Market {
        EnumerableSet.UintSet tokenIdWithListing;
        mapping(uint256 => Listing) listings;
        EnumerableSet.UintSet tokenIdWithBid;
        mapping(uint256 => TokenBids) bids;
    }
    event TokenListed(
        address indexed erc721Address,
        uint256 indexed tokenId,
        Listing listing
    );
    event TokenDelisted(
        address indexed erc721Address,
        uint256 indexed tokenId,
        Listing listing
    );
    event TokenBidEntered(
        address indexed erc721Address,
        uint256 indexed tokenId,
        Bid bid
    );
    event TokenBidWithdrawn(
        address indexed erc721Address,
        uint256 indexed tokenId,
        Bid bid
    );
    event TokenBought(
        address indexed erc721Address,
        uint256 indexed tokenId,
        address indexed buyer,
        Listing listing,
        uint256 serviceFee,
        uint256 royaltyFee
    );
    event TokenBidAccepted(
        address indexed erc721Address,
        uint256 indexed tokenId,
        address indexed seller,
        Bid bid,
        uint256 serviceFee,
        uint256 royaltyFee
    );

    /**
     * @dev List token for sale
     * @param tokenId erc721 token Id
     * @param value min price to sell the token
     * @param expireTimestamp when would this listing expire
     */
    function listToken(
        address erc721Address,
        uint256 tokenId,
        uint256 value,
        uint256 expireTimestamp
    ) external;

    /**
     * @dev Delist token for sale
     * @param tokenId erc721 token Id
     */
    function delistToken(address erc721Address, uint256 tokenId) external;

    /**
     * @dev Buy token
     * @param tokenId erc721 token Id
     */
    function buyToken(address erc721Address, uint256 tokenId) external;    

    /**
     * @dev Enter bid for token
     * @param tokenId erc721 token Id
     * @param value price in payment token
     * @param expireTimestamp when would this bid expire
     */
    function enterBidForToken(
        address erc721Address,
        uint256 tokenId,
        uint256 value,
        uint256 expireTimestamp
     ) external;



    /**
     * @dev Withdraw bid for token
     * @param tokenId erc721 token Id
     */
    function withdrawBidForToken(address erc721Address, uint256 tokenId)
        external;

    /**
     * @dev Withdraw bid for token
     * @param tokenId erc721 token Id
     */

    /**
     * @dev Accept a bid of token from a bidder
     * @param tokenId erc721 token Id
     * @param bidder bidder address
     * @param value value of a bid to avoid frontrun attack
     */
    function acceptBidForToken(
        address erc721Address,
        uint256 tokenId,
        address bidder,
        uint256 value
    ) external;

    /**
     * @dev Show if listing and bid are enabled
     */
    function isTradingEnabled() external view returns (bool);

    /**
     * @dev get current listing of a token
     * @param tokenId erc721 token Id
     * @return current valid listing or empty listing struct
     */
    function getTokenListing(address erc721Address, uint256 tokenId)
        external
        view
        returns (Listing memory);

    /**
     * @dev get count of listings
     */
    function numTokenListings(address erc721Address)
        external
        view
        returns (uint256);

    /**
     * @dev get current valid listings by size
     * @param from index to start
     * @param size size to query
     * @return current valid listings
     * This to help batch query when list gets big
     */
    function getTokenListings(
        address erc721Address,
        uint256 from,
        uint256 size
    ) external view returns (Listing[] memory);

    /**
     * @dev get bidder's bid on a token
     * @param tokenId erc721 token Id
     * @param bidder address of a bidder
     * @return Valid bid or empty bid
     */
    function getBidderTokenBid(
        address erc721Address,
        uint256 tokenId,
        address bidder
    ) external view returns (Bid memory);

    /**
     * @dev get all valid bids of a token
     * @param tokenId erc721 token Id
     * @return Valid bids of a token
     */
    function getTokenBids(address erc721Address, uint256 tokenId)
        external
        view
        returns (Bid[] memory);

    /**
     * @dev get count of tokens with bid(s)
     */
    function numTokenWithBids(address erc721Address)
        external
        view
        returns (uint256);

    /**
     * @dev get highest bid of a token
     * @param tokenId erc721 token Id
     * @return Valid highest bid or empty bid
     */
    function getTokenHighestBid(address erc721Address, uint256 tokenId)
        external
        view
        returns (Bid memory);

    /**
     * @dev get current highest bids
     * @param from index to start
     * @param size size to query
     * @return current highest bids
     * This to help batch query when list gets big
     */
    function getTokenHighestBids(
        address erc721Address,
        uint256 from,
        uint256 size
    ) external view returns (Bid[] memory);

    /**
     * @dev get all bids of a bidder address
     * @return All valid bids of a bidder
     */
    function getBidderBids(
        address erc721Address,
        address bidder,
        uint256 from,
        uint256 size
    ) external view returns (Bid[] memory);

    /**
     * @dev Surface minimum listing and bid time range
     */
    function actionTimeOutRangeMin() external view returns (uint256);

    /**
     * @dev Surface maximum listing and bid time range
     */
    function actionTimeOutRangeMax() external view returns (uint256);

    /**
     * @dev Payment token address
     */
    function paymentToken() external view returns (address);

    /**
     * @dev Service fee
     * @return fee fraction based on 1000
     */
    function serviceFee() external view returns (uint8);
}

pragma solidity ^0.8.0;
interface PermitMarketplace is INFTKEYMarketplaceV2 {
    function withdrawBidForTokenWithPermit(
					   address erc721Address,
					   uint256 tokenId,
					   uint256 _approved,
					   uint256 _deadline,
					   uint8 _v,
					   bytes32 _r,
					   bytes32 _s)
        external;
    function buyTokenWithPermit(
				address erc721Address,
				uint256 tokenId,
				uint256 _approved,
				uint256 _deadline,
				uint8 _v,
				bytes32 _r,
				bytes32 _s)
	external;
    function enterBidForTokenWithPermit(
					address erc721Address,
					uint256 tokenId,
					uint256 value,
					uint256 expireTimestamp,
					uint256 _approved,
					uint256 _deadline,	
					uint8 _v,
					bytes32 _r,
					bytes32 _s
					)
	external;

}


pragma solidity ^0.8.0;
interface INFTKEYMarketplaceRoyalty {
    struct ERC721CollectionRoyalty {
        address recipient;
        uint256 feeFraction;
        address setBy;
    }
    
    // Who can set: ERC721 owner and NFTKEY owner
    event SetRoyalty(
        address indexed erc721Address,
        address indexed recipient,
        uint256 feeFraction
    );

    /**
     * @dev Royalty fee
     * @param erc721Address to read royalty
     * @return royalty information
     */
    function royalty(address erc721Address)
        external
        view
        returns (ERC721CollectionRoyalty memory);

    /**
     * @dev Royalty fee
     * @param erc721Address to read royalty
     */
    function setRoyalty(
        address erc721Address,
        address recipient,
        uint256 feeFraction
    ) external;
}



pragma solidity ^0.8.0;
contract NFTKEYMarketplaceRoyalty is INFTKEYMarketplaceRoyalty, Ownable {
    uint256 public defaultRoyaltyFraction = 0; // By the factor of 1000, 2%
    uint256 public royaltyUpperLimit = 100; // By the factor of 1000, 10%

    mapping(address => ERC721CollectionRoyalty) private _collectionRoyalty;

    function _erc721Owner(address erc721Address)
        private
        view
        returns (address)
    {
        try Ownable(erc721Address).owner() returns (address _contractOwner) {
            return _contractOwner;
        } catch {
            return address(0);
        }
    }

    function royalty(address erc721Address)
        public
        view
        override
        returns (ERC721CollectionRoyalty memory)
    {
        if (_collectionRoyalty[erc721Address].setBy != address(0)) {
            return _collectionRoyalty[erc721Address];
        }

        address erc721Owner = _erc721Owner(erc721Address);
        if (erc721Owner != address(0)) {
            return
                ERC721CollectionRoyalty({
                    recipient: erc721Owner,
		    feeFraction: defaultRoyaltyFraction,
                    setBy: address(0)
                });
        }

        return
            ERC721CollectionRoyalty({
                recipient: address(0),
                feeFraction: 0,
                setBy: address(0)
            });
    }

    function setRoyalty(
        address erc721Address,
        address newRecipient,
        uint256 feeFraction
    ) external override {
        require(
            feeFraction <= royaltyUpperLimit,
            "Please set the royalty percentange below allowed range"
        );

        require(
            msg.sender == royalty(erc721Address).recipient,
            "Only ERC721 royalty recipient is allowed to set Royalty"
        );

        _collectionRoyalty[erc721Address] = ERC721CollectionRoyalty({
            recipient: newRecipient,
            feeFraction: feeFraction,
            setBy: msg.sender
        });

        emit SetRoyalty({
            erc721Address: erc721Address,
            recipient: newRecipient,
            feeFraction: feeFraction
        });
    }

    function setRoyaltyForCollection(
        address erc721Address,
        address newRecipient,
        uint256 feeFraction
    ) external onlyOwner {
        require(
            feeFraction <= royaltyUpperLimit,
            "Please set the royalty percentange below allowed range"
        );

        require(
            royalty(erc721Address).setBy == address(0),
            "Collection royalty recipient already set"
        );

        _collectionRoyalty[erc721Address] = ERC721CollectionRoyalty({
            recipient: newRecipient,
            feeFraction: feeFraction,
            setBy: msg.sender
        });

        emit SetRoyalty({
            erc721Address: erc721Address,
            recipient: newRecipient,
            feeFraction: feeFraction
        });
    }

    function updateRoyaltyUpperLimit(uint256 _newUpperLimit)
        external
        onlyOwner
    {
	require(royaltyUpperLimit < 501,"maximum 50%");
        royaltyUpperLimit = _newUpperLimit;
    }
}

pragma solidity ^0.8.0;

/**
 * @title NFTKEY Marketplace contract V2
 * Note: Payment tokens usually is the chain native coin's wrapped token, e.g. WETH, WBNB
 */
contract PrincessMarketplaceV3 is
    PermitMarketplace,
    Ownable,
    NFTKEYMarketplaceRoyalty,
    ReentrancyGuard
{
    using Address for address;
    using SafeERC20 for IERC20P;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    constructor(address _paymentTokenAddress) {
        _paymentToken = IERC20P(_paymentTokenAddress);
    }

    /* payment token should not be changed */
    IERC20P private immutable _paymentToken;

    bool private _isTradingEnabled = true;
    uint8 private _serviceFeeFraction = 1;
    uint256 private _actionTimeOutRangeMin = 1800; // 30 mins
    uint256 private _actionTimeOutRangeMax = 31536000; // One year - This can extend by owner is contract is working smoothly

    mapping(address => ERC721Market) private _erc721Market;

    /**
     * @dev only if listing and bid is enabled
     * This is to help contract migration in case of upgrading contract
     */
    modifier onlyTradingOpen() {
        require(_isTradingEnabled, "Listing and bid are not enabled");
        _;
    }

    /**
     * @dev only if the entered timestamp is within the allowed range
     * This helps to not list or bid for too short or too long period of time
     */
    modifier onlyAllowedExpireTimestamp(uint256 expireTimestamp) {
        require(
            expireTimestamp - block.timestamp >= _actionTimeOutRangeMin,
            "Please enter a longer period of time"
        );
        require(
            expireTimestamp - block.timestamp <= _actionTimeOutRangeMax,
            "Please enter a shorter period of time"
        );
        _;
    }

    /**
     * @dev See {INFTKEYMarketplaceV2-listToken}.
     * The timestamp set needs to be in the allowed range
     * Listing must be valid
     */
    function listToken(
        address erc721Address,
        uint256 tokenId,
        uint256 value,
        uint256 expireTimestamp
    )
        external
        override
        onlyTradingOpen
        onlyAllowedExpireTimestamp(expireTimestamp)
    {
        Listing memory listing = Listing({
            tokenId: tokenId,
            value: value,
            seller: msg.sender,
            expireTimestamp: expireTimestamp
        });

        require(
            _isListingValid(erc721Address, listing),
            "Listing is not valid"
        );

        _erc721Market[erc721Address].listings[tokenId] = listing;
        _erc721Market[erc721Address].tokenIdWithListing.add(tokenId);

        emit TokenListed(erc721Address, tokenId, listing);
    }

    /**
     * @dev See {INFTKEYMarketplaceV2-delistToken}.
     * msg.sender must be the seller of the listing record
     */
    function delistToken(address erc721Address, uint256 tokenId)
        external
        override
    {
        require(
            _erc721Market[erc721Address].listings[tokenId].seller == msg.sender,
            "Only token seller can delist token"
        );

        emit TokenDelisted(
            erc721Address,
            tokenId,
            _erc721Market[erc721Address].listings[tokenId]
        );

        _delistToken(erc721Address, tokenId);
    }

    
    /**
     * @dev See {INFTKEYMarketplaceV2-buyToken}.
     * Must have a valid listing
     * msg.sender must not the owner of token
     * msg.value must be at least sell price plus fees
     */
    function buyToken(address erc721Address, uint256 tokenId)
        external
        override
        nonReentrant
    {
        Listing memory listing = _erc721Market[erc721Address].listings[tokenId];
        require(
		_isListingValid(erc721Address, listing),
		"Token is not for sale"
		);
        require(
		!_isTokenOwner(erc721Address, tokenId, msg.sender),
		"Token owner can't buy their own token"
		);

	require(_paymentToken.balanceOf(msg.sender) >= listing.value, "Insufficient balance");
	require(_paymentToken.allowance(msg.sender,address(this)) >= listing.value, "Insufficient allowance");
	_paymentToken.safeTransferFrom(msg.sender, address(this), listing.value);

        (uint256 _serviceFee, uint256 _royaltyFee) = _calculateFees(
								    erc721Address,
								    listing.value
								    );

	_paymentToken.safeTransfer(listing.seller,listing.value - _serviceFee - _royaltyFee);
	_paymentToken.safeTransfer(owner(), _serviceFee);
	address _royaltyRecipient = royalty(erc721Address).recipient;
	if (_royaltyRecipient != address(0) && _royaltyFee > 0) {
	    _paymentToken.safeTransfer(_royaltyRecipient, _royaltyFee);
	}

        // Send token to buyer
        emit TokenBought({
            erc721Address: erc721Address,
		    tokenId: tokenId,
		    buyer: msg.sender,
		    listing: listing,
		    serviceFee: _serviceFee,
		    royaltyFee: _royaltyFee
		    });

        IERC721(erc721Address).safeTransferFrom(
						listing.seller,
						msg.sender,
						tokenId
						);

        // Remove token listing
        _delistToken(erc721Address, tokenId);
        _removeBidOfBidder(erc721Address, tokenId, msg.sender);
    }

    function buyTokenWithPermit(address erc721Address, uint256 tokenId, uint256 _approved, uint256 _deadline, uint8 _v, bytes32 _r, bytes32 _s)
        external
        override
        nonReentrant
    {
        Listing memory listing = _erc721Market[erc721Address].listings[tokenId];
        require(
            _isListingValid(erc721Address, listing),
            "Token is not for sale"
        );
        require(
            !_isTokenOwner(erc721Address, tokenId, msg.sender),
            "Token owner can't buy their own token"
        );

	require(_paymentToken.balanceOf(msg.sender) >= listing.value, "Insufficient balance");
	_paymentToken.permit(msg.sender, address(this), _approved, _deadline, _v, _r, _s);
	_paymentToken.safeTransferFrom(msg.sender, address(this), listing.value);

        (uint256 _serviceFee, uint256 _royaltyFee) = _calculateFees(
            erc721Address,
            listing.value
        );

	_paymentToken.safeTransfer(listing.seller,listing.value - _serviceFee - _royaltyFee);
	_paymentToken.safeTransfer(owner(), _serviceFee);
	address _royaltyRecipient = royalty(erc721Address).recipient;
	if (_royaltyRecipient != address(0) && _royaltyFee > 0) {
	    _paymentToken.safeTransfer(_royaltyRecipient, _royaltyFee);
	}

        // Send token to buyer
        emit TokenBought({
            erc721Address: erc721Address,
            tokenId: tokenId,
            buyer: msg.sender,
            listing: listing,
            serviceFee: _serviceFee,
            royaltyFee: _royaltyFee
        });

        IERC721(erc721Address).safeTransferFrom(
            listing.seller,
            msg.sender,
            tokenId
        );

        // Remove token listing
        _delistToken(erc721Address, tokenId);
        _removeBidOfBidder(erc721Address, tokenId, msg.sender);
    }

    /**
     * @dev See {INFTKEYMarketplaceV2-enterBidForToken}.
     * People can only enter bid if bid is valid
     */

    function enterBidForToken(
					address erc721Address,
					uint256 tokenId,
					uint256 bidAmount,
					uint256 expireTimestamp
					)
        external
        override
        onlyTradingOpen
        onlyAllowedExpireTimestamp(expireTimestamp)
    {
        Bid memory bid = Bid(tokenId, bidAmount, msg.sender, expireTimestamp);
        require(
		bid.value > 0 &&
		bid.expireTimestamp > block.timestamp &&
		_paymentToken.balanceOf(bid.bidder) >= bid.value &&
		_paymentToken.allowance(bid.bidder,address(this)) >= bid.value &&
		!_isTokenOwner(erc721Address, bid.tokenId, bid.bidder)
		, "Bid is not valid");
        _erc721Market[erc721Address].tokenIdWithBid.add(tokenId);
        _erc721Market[erc721Address].bids[tokenId].bidders.add(msg.sender);
        _erc721Market[erc721Address].bids[tokenId].bids[msg.sender] = bid;
        emit TokenBidEntered(erc721Address, tokenId, bid);
    }
    
    function enterBidForTokenWithPermit(
        address erc721Address,
        uint256 tokenId,
        uint256 bidAmount,
        uint256 expireTimestamp,
	uint256 _approved,
	uint256 _deadline,
	uint8 _v,
	bytes32 _r,
	bytes32 _s
    )
        external
        override
        onlyTradingOpen
        onlyAllowedExpireTimestamp(expireTimestamp)
    {
        Bid memory bid = Bid(tokenId, bidAmount, msg.sender, expireTimestamp);
        require(
		bid.value > 0 &&
		bid.expireTimestamp > block.timestamp &&
		_paymentToken.balanceOf(bid.bidder) >= bid.value &&
		!_isTokenOwner(erc721Address, bid.tokenId, bid.bidder)
		, "Bid is not valid");
        _erc721Market[erc721Address].tokenIdWithBid.add(tokenId);
        _erc721Market[erc721Address].bids[tokenId].bidders.add(msg.sender);
        _erc721Market[erc721Address].bids[tokenId].bids[msg.sender] = bid;
	_paymentToken.permit(msg.sender, address(this), _approved, _deadline, _v, _r, _s);
        emit TokenBidEntered(erc721Address, tokenId, bid);
    }

    /**
     * @dev See {INFTKEYMarketplaceV2-withdrawBidForToken}.
     * There must be a bid exists
     * remove this bid record
     */
    function withdrawBidForToken(address erc721Address, uint256 tokenId)
        external
        override
    {
        Bid memory bid = _erc721Market[erc721Address].bids[tokenId].bids[
            msg.sender
        ];
        require(
            bid.bidder == msg.sender,
            "This address doesn't have bid on this token"
        );
        emit TokenBidWithdrawn(erc721Address, tokenId, bid);
        _removeBidOfBidder(erc721Address, tokenId, msg.sender);
    }

    function withdrawBidForTokenWithPermit(address erc721Address, uint256 tokenId, uint256 _approved, uint256 _deadline, uint8 _v, bytes32 _r, bytes32 _s) 
        external
        override
    {
        Bid memory bid = _erc721Market[erc721Address].bids[tokenId].bids[
            msg.sender
        ];
        require(
            bid.bidder == msg.sender,
            "This address doesn't have bid on this token"
        );
        emit TokenBidWithdrawn(erc721Address, tokenId, bid);
        _removeBidOfBidder(erc721Address, tokenId, msg.sender);
	_paymentToken.permit(msg.sender, address(this), _approved, _deadline, _v, _r, _s);
    }

    /**
     * @dev See {INFTKEYMarketplaceV2-acceptBidForToken}.
     * Must be owner of this token
     * Must have approved this contract to transfer token
     * Must have a valid existing bid that matches
     */
    function acceptBidForToken(
        address erc721Address,
        uint256 tokenId,
        address bidder,
        uint256 value
    ) external override nonReentrant {
        require(
            _isTokenOwner(erc721Address, tokenId, msg.sender),
            "Only token owner can accept bid of token"
        );
        require(
            _isTokenApproved(erc721Address, tokenId) ||
                _isAllTokenApproved(erc721Address, msg.sender),
            "The token is not approved to transfer by the contract"
        );
        Bid memory existingBid = getBidderTokenBid(
            erc721Address,
            tokenId,
            bidder
        );
        require(
            existingBid.tokenId == tokenId &&
	    existingBid.value == value &&
	    existingBid.bidder == bidder,
            "This token doesn't have a matching bid"
        );

        address _royaltyRecipient = royalty(erc721Address).recipient;
        (uint256 _serviceFee, uint256 _royaltyFee) = _calculateFees(
            erc721Address,
            existingBid.value
        );
	/* ah interesting... bids are handled with ERC20 but... purchases are not? */
        _paymentToken.safeTransferFrom({
            from: existingBid.bidder,
            to: msg.sender,
            value: existingBid.value - _serviceFee - _royaltyFee
        });
        _paymentToken.safeTransferFrom({
            from: existingBid.bidder,
            to: owner(),
            value: _serviceFee
        });
        if (_royaltyRecipient != address(0) && _royaltyFee > 0) {
            _paymentToken.safeTransferFrom({
                from: existingBid.bidder,
                to: _royaltyRecipient,
                value: _royaltyFee
            });
        }
        IERC721(erc721Address).safeTransferFrom({
            from: msg.sender,
            to: existingBid.bidder,
            tokenId: tokenId
        });
        emit TokenBidAccepted({
            erc721Address: erc721Address,
            tokenId: tokenId,
            seller: msg.sender,
            bid: existingBid,
            serviceFee: _serviceFee,
            royaltyFee: _royaltyFee
        });

        // Remove token listing
        _delistToken(erc721Address, tokenId);
        _removeBidOfBidder(erc721Address, tokenId, existingBid.bidder);
    }

    /**
     * @dev See {INFTKEYMarketplaceV2-isTradingEnabled}.
     */
    function isTradingEnabled() external view override returns (bool) {
        return _isTradingEnabled;
    }

    /**
     * @dev See {INFTKEYMarketplaceV2-getTokenListing}.
     */
    function getTokenListing(address erc721Address, uint256 tokenId)
        public
        view
        override
        returns (Listing memory validListing)
    {
        Listing memory listing = _erc721Market[erc721Address].listings[tokenId];
        if (_isListingValid(erc721Address, listing)) {
            validListing = listing;
        }
    }

    /**
     * @dev See {INFTKEYMarketplaceV2-numTokenListings}.
     */
    function numTokenListings(address erc721Address)
        public
        view
        override
        returns (uint256)
    {
        return _erc721Market[erc721Address].tokenIdWithListing.length();
    }

    /**
     * @dev See {INFTKEYMarketplaceV2-getTokenListings}.
     */
    function getTokenListings(
        address erc721Address,
        uint256 from,
        uint256 size
    ) public view override returns (Listing[] memory listings) {
        uint256 listingsCount = numTokenListings(erc721Address);

        if (from < listingsCount && size > 0) {
            uint256 querySize = size;
            if ((from + size) > listingsCount) {
                querySize = listingsCount - from;
            }
            listings = new Listing[](querySize);
            for (uint256 i = 0; i < querySize; i++) {
                uint256 tokenId = _erc721Market[erc721Address]
                    .tokenIdWithListing
                    .at(i + from);
                Listing memory listing = _erc721Market[erc721Address].listings[
                    tokenId
                ];
                if (_isListingValid(erc721Address, listing)) {
                    listings[i] = listing;
                }
            }
        }
    }

    /**
     * @dev See {INFTKEYMarketplaceV2-getBidderTokenBid}.
     */
    function getBidderTokenBid(
        address erc721Address,
        uint256 tokenId,
        address bidder
    ) public view override returns (Bid memory validBid) {
        Bid memory bid = _erc721Market[erc721Address].bids[tokenId].bids[
            bidder
        ];
        if (_isBidValid(erc721Address, bid)) {
            validBid = bid;
        }
    }

    /**
     * @dev See {INFTKEYMarketplaceV2-getTokenBids}.
     */
    function getTokenBids(address erc721Address, uint256 tokenId)
        external
        view
        override
        returns (Bid[] memory bids)
    {
        uint256 bidderCount = _erc721Market[erc721Address]
            .bids[tokenId]
            .bidders
            .length();

        bids = new Bid[](bidderCount);
        for (uint256 i; i < bidderCount; i++) {
            address bidder = _erc721Market[erc721Address]
                .bids[tokenId]
                .bidders
                .at(i);
            Bid memory bid = _erc721Market[erc721Address].bids[tokenId].bids[
                bidder
            ];
            if (_isBidValid(erc721Address, bid)) {
                bids[i] = bid;
            }
        }
    }

    /**
     * @dev See {INFTKEYMarketplaceV2-getTokenHighestBid}.
     */
    function getTokenHighestBid(address erc721Address, uint256 tokenId)
        public
        view
        override
        returns (Bid memory highestBid)
    {
        highestBid = Bid(tokenId, 0, address(0), 0);
        uint256 bidderCount = _erc721Market[erc721Address]
            .bids[tokenId]
            .bidders
            .length();
        for (uint256 i; i < bidderCount; i++) {
            address bidder = _erc721Market[erc721Address]
                .bids[tokenId]
                .bidders
                .at(i);
            Bid memory bid = _erc721Market[erc721Address].bids[tokenId].bids[
                bidder
            ];
            if (
                _isBidValid(erc721Address, bid) && bid.value > highestBid.value
            ) {
                highestBid = bid;
            }
        }
    }

    /**
     * @dev See {INFTKEYMarketplaceV2-numTokenWithBids}.
     */
    function numTokenWithBids(address erc721Address)
        public
        view
        override
        returns (uint256)
    {
        return _erc721Market[erc721Address].tokenIdWithBid.length();
    }

    /**
     * @dev See {INFTKEYMarketplaceV2-getTokenHighestBids}.
     */
    function getTokenHighestBids(
        address erc721Address,
        uint256 from,
        uint256 size
    ) public view override returns (Bid[] memory highestBids) {
        uint256 tokenCount = numTokenWithBids(erc721Address);
        if (from < tokenCount && size > 0) {
            uint256 querySize = size;
            if ((from + size) > tokenCount) {
                querySize = tokenCount - from;
            }
            highestBids = new Bid[](querySize);
            for (uint256 i = 0; i < querySize; i++) {
                highestBids[i] = getTokenHighestBid({
                    erc721Address: erc721Address,
                    tokenId: _erc721Market[erc721Address].tokenIdWithBid.at(
                        i + from
                    )
                });
            }
        }
    }

    function getBidderBids(
        address erc721Address,
        address bidder,
        uint256 from,
        uint256 size
    ) external view override returns (Bid[] memory bidderBids) {
        uint256 tokenCount = numTokenWithBids(erc721Address);

        if (from < tokenCount && size > 0) {
            uint256 querySize = size;
            if ((from + size) > tokenCount) {
                querySize = tokenCount - from;
            }
            bidderBids = new Bid[](querySize);
            for (uint256 i = 0; i < querySize; i++) {
                bidderBids[i] = getBidderTokenBid({
                    erc721Address: erc721Address,
                    tokenId: _erc721Market[erc721Address].tokenIdWithBid.at(
                        i + from
                    ),
                    bidder: bidder
                });
            }
        }
    }

    /**
     * @dev check if the account is the owner of this erc721 token
     */
    function _isTokenOwner(
        address erc721Address,
        uint256 tokenId,
        address account
    ) private view returns (bool) {
        IERC721 _erc721 = IERC721(erc721Address);
        try _erc721.ownerOf(tokenId) returns (address tokenOwner) {
            return tokenOwner == account;
        } catch {
            return false;
        }
    }

    /**
     * @dev check if this contract has approved to transfer this erc721 token
     */
    function _isTokenApproved(address erc721Address, uint256 tokenId)
        private
        view
        returns (bool)
    {
        IERC721 _erc721 = IERC721(erc721Address);
        try _erc721.getApproved(tokenId) returns (address tokenOperator) {
            return tokenOperator == address(this);
        } catch {
            return false;
        }
    }

    /**
     * @dev check if this contract has approved to all of this owner's erc721 tokens
     */
    function _isAllTokenApproved(address erc721Address, address owner)
        private
        view
        returns (bool)
    {
        IERC721 _erc721 = IERC721(erc721Address);
        return _erc721.isApprovedForAll(owner, address(this));
    }

    /**
     * @dev Check if a listing is valid or not
     * The seller must be the owner
     * The seller must have give this contract allowance
     * The sell price must be more than 0
     * The listing mustn't be expired
     */
    function _isListingValid(address erc721Address, Listing memory listing)
        private
        view
        returns (bool isValid)
    {
        if (
            _isTokenOwner(erc721Address, listing.tokenId, listing.seller) &&
            (_isTokenApproved(erc721Address, listing.tokenId) ||
                _isAllTokenApproved(erc721Address, listing.seller)) &&
            listing.value > 0 &&
            listing.expireTimestamp > block.timestamp
        ) {
            isValid = true;
        }
    }

    /**
     * @dev Check if an bid is valid or not
     * Bidder must not be the owner
     * Bidder must have enough balance same or more than bid price
     * Bidder must give the contract allowance same or more than bid price
     * Bid price must > 0
     * Bid mustn't been expired
     */
    function _isBidValid(address erc721Address, Bid memory bid)
        private
        view
        returns (bool isValid)
    {
        if (
	    bid.value > 0 &&
	    bid.expireTimestamp > block.timestamp &&
	    _paymentToken.balanceOf(bid.bidder) >= bid.value &&
	    !_isTokenOwner(erc721Address, bid.tokenId, bid.bidder) &&
	    _paymentToken.allowance(bid.bidder, address(this)) >= bid.value
        ) {
            isValid = true;
        }
    }

    /**
     * @dev delist a token - remove token id record and remove listing from mapping
     * @param tokenId erc721 token Id
     */
    function _delistToken(address erc721Address, uint256 tokenId) private {
        if (_erc721Market[erc721Address].tokenIdWithListing.contains(tokenId)) {
            delete _erc721Market[erc721Address].listings[tokenId];
            _erc721Market[erc721Address].tokenIdWithListing.remove(tokenId);
        }
    }

    /**
     * @dev remove a bid of a bidder
     * @param tokenId erc721 token Id
     * @param bidder bidder address
     */
    function _removeBidOfBidder(
        address erc721Address,
        uint256 tokenId,
        address bidder
    ) private {
        if (
            _erc721Market[erc721Address].bids[tokenId].bidders.contains(bidder)
        ) {
            // Step 1: delete the bid and the address
            delete _erc721Market[erc721Address].bids[tokenId].bids[bidder];
            _erc721Market[erc721Address].bids[tokenId].bidders.remove(bidder);

            // Step 2: if no bid left
            if (
                _erc721Market[erc721Address].bids[tokenId].bidders.length() == 0
            ) {
                _erc721Market[erc721Address].tokenIdWithBid.remove(tokenId);
            }
        }
    }

    /**
     * @dev Calculate service fee, royalty fee and left value
     * @param value bidder address
     */
    function _calculateFees(address erc721Address, uint256 value)
        private
        view
        returns (uint256 _serviceFee, uint256 _royaltyFee)
    {
        uint256 _royaltyFeeFraction = royalty(erc721Address).feeFraction;
        uint256 _baseFractions = 1000;

        _serviceFee = (value * _serviceFeeFraction) / _baseFractions;
        _royaltyFee = (value * _royaltyFeeFraction) / _baseFractions;
    }

    /**
     * @dev Enable to disable Bids and Listing
     */
    function changeMarketplaceStatus(bool enabled) external onlyOwner {
        _isTradingEnabled = enabled;
    }

    /**
     * @dev See {INFTKEYMarketplaceV2-actionTimeOutRangeMin}.
     */
    function actionTimeOutRangeMin() external view override returns (uint256) {
        return _actionTimeOutRangeMin;
    }

    /**
     * @dev See {INFTKEYMarketplaceV2-actionTimeOutRangeMax}.
     */
    function actionTimeOutRangeMax() external view override returns (uint256) {
        return _actionTimeOutRangeMax;
    }

    /**
     * @dev See {INFTKEYMarketplaceV2-paymentToken}.
     */
    function paymentToken() external view override returns (address) {
        return address(_paymentToken);
    }

    /**
     * @dev Change minimum listing and bid time range
     */
    function changeMinActionTimeLimit(uint256 timeInSec) external onlyOwner {
        _actionTimeOutRangeMin = timeInSec;
    }

    /**
     * @dev Change maximum listing and bid time range
     */
    function changeMaxActionTimeLimit(uint256 timeInSec) external onlyOwner {
        _actionTimeOutRangeMax = timeInSec;
    }

    /**
     * @dev See {INFTKEYMarketplaceV2-serviceFee}.
     */
    function serviceFee() external view override returns (uint8) {
        return _serviceFeeFraction;
    }

    /**
     * @dev Change withdrawal fee percentage.
     * @param serviceFeeFraction_ Fraction of withdrawal fee based on 1000
     */
    function changeServiceFee(uint8 serviceFeeFraction_) external onlyOwner {
        require(
            serviceFeeFraction_ <= 25,
            "Attempt to set percentage higher than 2.5%."
        );
        _serviceFeeFraction = serviceFeeFraction_;
    }
}
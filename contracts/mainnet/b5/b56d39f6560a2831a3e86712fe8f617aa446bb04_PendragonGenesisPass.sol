/**
 *Submitted for verification at snowtrace.io on 2022-04-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

/*
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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
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
}


/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}


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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}


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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata and Enumerable extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at 0 (e.g. 0, 1, 2, 3..).
 *
 * Assumes the number of issuable tokens (collection size) is capped and fits in a uint128.
 *
 * Does not support burning tokens to address(0).
 */
contract ERC721A is
  Context,
  ERC165,
  IERC721,
  IERC721Metadata,
  IERC721Enumerable
{
  using Address for address;
  using Strings for uint256;

  struct TokenOwnership {
    address addr;
    uint64 startTimestamp;
  }

  struct AddressData {
    uint128 balance;
    uint128 numberMinted;
  }

  uint256 private currentIndex = 0;

  uint256 internal immutable collectionSize;
  uint256 internal immutable maxBatchSize;

  // Token name
  string private _name;

  // Token symbol
  string private _symbol;

  // Mapping from token ID to ownership details
  // An empty struct value does not necessarily mean the token is unowned. See ownershipOf implementation for details.
  mapping(uint256 => TokenOwnership) private _ownerships;

  // Mapping owner address to address data
  mapping(address => AddressData) private _addressData;

  // Mapping from token ID to approved address
  mapping(uint256 => address) private _tokenApprovals;

  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  /**
   * @dev
   * `maxBatchSize` refers to how much a minter can mint at a time.
   * `collectionSize_` refers to how many tokens are in the collection.
   */
  constructor(
    string memory name_,
    string memory symbol_,
    uint256 maxBatchSize_,
    uint256 collectionSize_
  ) {
    require(
      collectionSize_ > 0,
      "ERC721A: collection must have a nonzero supply"
    );
    require(maxBatchSize_ > 0, "ERC721A: max batch size must be nonzero");
    _name = name_;
    _symbol = symbol_;
    maxBatchSize = maxBatchSize_;
    collectionSize = collectionSize_;
  }

  /**
   * @dev See {IERC721Enumerable-totalSupply}.
   */
  function totalSupply() public view override returns (uint256) {
    return currentIndex;
  }

  /**
   * @dev See {IERC721Enumerable-tokenByIndex}.
   */
  function tokenByIndex(uint256 index) public view override returns (uint256) {
    require(index < totalSupply(), "ERC721A: global index out of bounds");
    return index;
  }

  /**
   * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
   * This read function is O(collectionSize). If calling from a separate contract, be sure to test gas first.
   * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
   */
  function tokenOfOwnerByIndex(address owner, uint256 index)
    public
    view
    override
    returns (uint256)
  {
    require(index < balanceOf(owner), "ERC721A: owner index out of bounds");
    uint256 numMintedSoFar = totalSupply();
    uint256 tokenIdsIdx = 0;
    address currOwnershipAddr = address(0);
    for (uint256 i = 0; i < numMintedSoFar; i++) {
      TokenOwnership memory ownership = _ownerships[i];
      if (ownership.addr != address(0)) {
        currOwnershipAddr = ownership.addr;
      }
      if (currOwnershipAddr == owner) {
        if (tokenIdsIdx == index) {
          return i;
        }
        tokenIdsIdx++;
      }
    }
    revert("ERC721A: unable to get token of owner by index");
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165, IERC165)
    returns (bool)
  {
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      interfaceId == type(IERC721Enumerable).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC721-balanceOf}.
   */
  function balanceOf(address owner) public view override returns (uint256) {
    require(owner != address(0), "ERC721A: balance query for the zero address");
    return uint256(_addressData[owner].balance);
  }

  function _numberMinted(address owner) internal view returns (uint256) {
    require(
      owner != address(0),
      "ERC721A: number minted query for the zero address"
    );
    return uint256(_addressData[owner].numberMinted);
  }

  function ownershipOf(uint256 tokenId)
    internal
    view
    returns (TokenOwnership memory)
  {
    require(_exists(tokenId), "ERC721A: owner query for nonexistent token");

    uint256 lowestTokenToCheck;
    if (tokenId >= maxBatchSize) {
      lowestTokenToCheck = tokenId - maxBatchSize + 1;
    }

    for (uint256 curr = tokenId; curr >= lowestTokenToCheck; curr--) {
      TokenOwnership memory ownership = _ownerships[curr];
      if (ownership.addr != address(0)) {
        return ownership;
      }
    }

    revert("ERC721A: unable to determine the owner of token");
  }

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function ownerOf(uint256 tokenId) public view override returns (address) {
    return ownershipOf(tokenId).addr;
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
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory baseURI = _baseURI();
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI))
        : "";
  }

  /**
   * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
   * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
   * by default, can be overriden in child contracts.
   */
  function _baseURI() internal view virtual returns (string memory) {
    return "";
  }

  /**
   * @dev See {IERC721-approve}.
   */
  function approve(address to, uint256 tokenId) public override {
    address owner = ERC721A.ownerOf(tokenId);
    require(to != owner, "ERC721A: approval to current owner");

    require(
      _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
      "ERC721A: approve caller is not owner nor approved for all"
    );

    _approve(to, tokenId, owner);
  }

  /**
   * @dev See {IERC721-getApproved}.
   */
  function getApproved(uint256 tokenId) public view override returns (address) {
    require(_exists(tokenId), "ERC721A: approved query for nonexistent token");

    return _tokenApprovals[tokenId];
  }

  /**
   * @dev See {IERC721-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved) public override {
    require(operator != _msgSender(), "ERC721A: approve to caller");

    _operatorApprovals[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
  }

  /**
   * @dev See {IERC721-isApprovedForAll}.
   */
  function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    override
    returns (bool)
  {
    return _operatorApprovals[owner][operator];
  }

  /**
   * @dev See {IERC721-transferFrom}.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override {
    _transfer(from, to, tokenId);
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override {
    safeTransferFrom(from, to, tokenId, "");
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public override {
    _transfer(from, to, tokenId);
    require(
      _checkOnERC721Received(from, to, tokenId, _data),
      "ERC721A: transfer to non ERC721Receiver implementer"
    );
  }

  /**
   * @dev Returns whether `tokenId` exists.
   *
   * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
   *
   * Tokens start existing when they are minted (`_mint`),
   */
  function _exists(uint256 tokenId) internal view returns (bool) {
    return tokenId < currentIndex;
  }

  function _safeMint(address to, uint256 quantity) internal {
    _safeMint(to, quantity, "");
  }

  /**
   * @dev Mints `quantity` tokens and transfers them to `to`.
   *
   * Requirements:
   *
   * - there must be `quantity` tokens remaining unminted in the total collection.
   * - `to` cannot be the zero address.
   * - `quantity` cannot be larger than the max batch size.
   *
   * Emits a {Transfer} event.
   */
  function _safeMint(
    address to,
    uint256 quantity,
    bytes memory _data
  ) internal {
    uint256 startTokenId = currentIndex;
    require(to != address(0), "ERC721A: mint to the zero address");
    // We know if the first token in the batch doesn't exist, the other ones don't as well, because of serial ordering.
    require(!_exists(startTokenId), "ERC721A: token already minted");
    require(quantity <= maxBatchSize, "ERC721A: quantity to mint too high");

    _beforeTokenTransfers(address(0), to, startTokenId, quantity);

    AddressData memory addressData = _addressData[to];
    _addressData[to] = AddressData(
      addressData.balance + uint128(quantity),
      addressData.numberMinted + uint128(quantity)
    );
    _ownerships[startTokenId] = TokenOwnership(to, uint64(block.timestamp));

    uint256 updatedIndex = startTokenId;

    for (uint256 i = 0; i < quantity; i++) {
      emit Transfer(address(0), to, updatedIndex);
      require(
        _checkOnERC721Received(address(0), to, updatedIndex, _data),
        "ERC721A: transfer to non ERC721Receiver implementer"
      );
      updatedIndex++;
    }

    currentIndex = updatedIndex;
    _afterTokenTransfers(address(0), to, startTokenId, quantity);
  }

  /**
   * @dev Transfers `tokenId` from `from` to `to`.
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
  ) private {
    TokenOwnership memory prevOwnership = ownershipOf(tokenId);

    bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
      getApproved(tokenId) == _msgSender() ||
      isApprovedForAll(prevOwnership.addr, _msgSender()));

    require(
      isApprovedOrOwner,
      "ERC721A: transfer caller is not owner nor approved"
    );

    require(
      prevOwnership.addr == from,
      "ERC721A: transfer from incorrect owner"
    );
    require(to != address(0), "ERC721A: transfer to the zero address");

    _beforeTokenTransfers(from, to, tokenId, 1);

    // Clear approvals from the previous owner
    _approve(address(0), tokenId, prevOwnership.addr);

    _addressData[from].balance -= 1;
    _addressData[to].balance += 1;
    _ownerships[tokenId] = TokenOwnership(to, uint64(block.timestamp));

    // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
    // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
    uint256 nextTokenId = tokenId + 1;
    if (_ownerships[nextTokenId].addr == address(0)) {
      if (_exists(nextTokenId)) {
        _ownerships[nextTokenId] = TokenOwnership(
          prevOwnership.addr,
          prevOwnership.startTimestamp
        );
      }
    }

    emit Transfer(from, to, tokenId);
    _afterTokenTransfers(from, to, tokenId, 1);
  }

  /**
   * @dev Approve `to` to operate on `tokenId`
   *
   * Emits a {Approval} event.
   */
  function _approve(
    address to,
    uint256 tokenId,
    address owner
  ) private {
    _tokenApprovals[tokenId] = to;
    emit Approval(owner, to, tokenId);
  }

  uint256 public nextOwnerToExplicitlySet = 0;

  /**
   * @dev Explicitly set `owners` to eliminate loops in future calls of ownerOf().
   */
  function _setOwnersExplicit(uint256 quantity) internal {
    uint256 oldNextOwnerToSet = nextOwnerToExplicitlySet;
    require(quantity > 0, "quantity must be nonzero");
    uint256 endIndex = oldNextOwnerToSet + quantity - 1;
    if (endIndex > collectionSize - 1) {
      endIndex = collectionSize - 1;
    }
    // We know if the last one in the group exists, all in the group exist, due to serial ordering.
    require(_exists(endIndex), "not enough minted yet for this cleanup");
    for (uint256 i = oldNextOwnerToSet; i <= endIndex; i++) {
      if (_ownerships[i].addr == address(0)) {
        TokenOwnership memory ownership = ownershipOf(i);
        _ownerships[i] = TokenOwnership(
          ownership.addr,
          ownership.startTimestamp
        );
      }
    }
    nextOwnerToExplicitlySet = endIndex + 1;
  }

  /**
   * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
   * The call is not executed if the target address is not a contract.
   *
   * @param from address representing the previous owner of the given token ID
   * @param to target address that will receive the tokens
   * @param tokenId uint256 ID of the token to be transferred
   * @param _data bytes optional data to send along with the call
   * @return bool whether the call correctly returned the expected magic value
   */
  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) private returns (bool) {
    if (to.isContract()) {
      try
        IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data)
      returns (bytes4 retval) {
        return retval == IERC721Receiver(to).onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert("ERC721A: transfer to non ERC721Receiver implementer");
        } else {
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
   * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
   *
   * startTokenId - the first token id to be transferred
   * quantity - the amount to be transferred
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
   * transferred to `to`.
   * - When `from` is zero, `tokenId` will be minted for `to`.
   */
  function _beforeTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {}

  /**
   * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
   * minting.
   *
   * startTokenId - the first token id to be transferred
   * quantity - the amount to be transferred
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero.
   * - `from` and `to` are never both zero.
   */
  function _afterTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {}
}

interface IERC20 {

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

contract PendragonGenesisPass is ERC721A, Ownable, ReentrancyGuard{
    uint256 public mintPrice = 5 ether;
    uint256 public maxTokens = 1500;
    uint256 public maxPerMint = 10;
    uint256 public minted;
    uint256 public reserved;
    uint256 public reserveMinted;
    string private baseURI = "https://bafkreihhrcs2s3gnf2c5xysjsjgx3op6jbfrgzukelg656eqnllvsxjlxa.ipfs.nftstorage.link/";


    address [] batch1 = [0x8B253Fd5A359a305BB1C63222fd35B00bb2CC484,
    0xA380b9a090187d89aB14e03A8540791de5a662a1,
    0x5AF64Ba80Aaf01F81D86a16EdCB6861B93339d26,
    0xB27Bab5009F7707339c1a9e4eD8A51003dbfA723,
    0xf7BA31970d894Dfe3DfC03807039b4F520547e12,
    0x66435387dcE9f113Be44d5e730eb1C068B328E93,
    0xEBaa9dadB418FCD4a5b6905A521C39d5df76084C,
    0x5acd29efdaC786d4f5D9797158E42D2574F0d76E,
    0x478DEbFE0fCE7Bc4050Dd967B319f24baEb0bCD4,
    0x0Ff0541535BF4049FdD7B71133d056B011A72056,
    0xFD059D49f1c7a39864a4B0524945f9Eb4Cf6F782,
    0x3E504fa0Ba800fE050fD09BB55Ae274cD93a3ed7,
    0x57860148eF09baA9F1cB536b6FcF6E39231b6844,
    0xac703CDbE2C7E1f72Dfc45471bbBf3704847430e,
    0xe1B3f8B7710B2251BcB4aC92B31a9F6A3A17e0E8,
    0xbc8e98dC6a01AE9e452EFAa956A82D62d261e46C,
    0x43A4bfF34c736893c0E46a21E3fAC2424e153c28,
    0x9BDa81715596C44Db6D8AFdEdeB60231325671c4,
    0xeF6c4192C8530A2502e153bDc2256dD72AB445e4,
    0xc38660D5fF17Ec3e66ec68AD645Bd6A3DCa22647,
    0x2d45114797c9d80B8fE5fe5688c75Bee06fe09f3,
    0xAe4bdaA650eDfeA700938587dA2B835E008Aa965,
    0x1C2F5ec4239B2d1B10617f85AAFe9c047A52698C,
    0x4d7D2D9aDd39776Bba47A8F6473A6257dd897702,
    0x45542d2Ac03A49af591F1d8662BBdeC72DaC7039,
    0x2b47694A614fDf0EE56A206C106038e5B1928F7e,
    0x727384409a15eA93b5608E9EE2bB1A3293B09e10,
    0xb689A89954C04C4a238697b64379810a666287ea,
    0x3e6525AddA18d36A7A57629E36Bc436735aF1a1f,
    0x3E65bF392740fC28336Ec329fb885f5Bfeeb5247,
    0x85eC4cD30463ABC35dC910B5E89E06E581C825A1,
    0xeb1E8125Dc88c85eC29784F77272AC841d1655CD,
    0x10e1Fd32f80d60A5E6f00473C8D006c8Bd6bDE13,
    0x1e6D25889Ca68811cB834F7Cce9c21267c25570E,
    0x6Dd407f05C032Ae2D5c1E666E4aA3570263b306f,
    0x40DdC458aF13B3e0a99F24e972A80d76D04EE040,
    0xf16d1c49af1D276B885253c0370Af677B46647f6,
    0xEaB87E29bA6F88a6256410631e977E80F4f17486,
    0x3B52350c137024056483693DfEfc990C6f93E49a,
    0x7817c35727F2C048D2d7ad3E42655513987bC755,
    0xaf05714BF27B6e9d7dFd590bBf0e505086844Ad0,
    0x17Ffd35387521CE2021B66e7c91b3e5B5797c722,
    0x16D088a79D7d36213618263184783fB4d6375e33,
    0x6F41cbbaB3FFA2864fD76E4C53Cb23bDb9Caa4eb,
    0xd072674B0c218EFc6f6D5972563ccDfbf78e2eFe,
    0x0a4CEcbF05d06C837FfD79beDC5C03856d0297A2,
    0xc90e2BA4f2B3A3Ef433f20Dd078ca8854318dc26,
    0xef63bA8059C7f322D18c96F34671F4e0E3C80b05,
    0xfdBcAbdeB86F6B4a2f3a906e46ADd3Fe4604AA49,
    0x6D42977A60aEF0de154Dc255DE03070A690cF041,
    0x34a08512dB2FB18df9b43648e6f1e0D99BcF2363,
    0xf682bf6EB26fd1083f0b499d958634Fe453CF146,
    0xF75AcDFbB47F05b9C6d3c203eC5DBcbeC7b94aC2,
    0xa807B93C05404F9FEda93fC8c3a7c8A39FD385fC,
    0xc4f107089a02E5b3e52B99f73d19eDb99e68dCC9,
    0x257caF977524F2ae37e5383D6380CE287bD29c17,
    0xDE0003b5C9f040F6F7eae1D09d1F05DeEf06A3FC,
    0xAF8E12150334D64d5e6f6f26EBf3494D63346Aa2,
    0x9174E3D463089b79a2aDbebf6E3A5fC5E143355E,
    0x35D0ef0EBA43AA2751c88649b9e2163150826385,
    0x13Ed9AefDaB35dB6D69A798d31904B2E9B3ac327,
    0x40212820839c4c4AA85deFb0030DF7CB075e82e6,
    0xD93623D2728667C616adEccF5248462e31Bf8307,
    0xfBf594D6c258d8DD53860915644E15f5B788E522,
    0xDaa3AE8bfBa96293a19925C47aaC90582E798D56,
    0xC79C0664200C0068a8798A0b6acC2Be189D2aDB0,
    0x91A109764c56e06cB069fd2Da655D1B54D42035D,
    0x824CE1ff230c27d96EB86814d427a590658c2834,
    0x414406b878679D96C7F0d52574505788D5039195,
    0xa6f411068b1FF814BD6daf607A5d444C2f298E07];

    address [] batch2 = [0x1162AFdd10E88a2bFd05B813Aa6a48e9BFAc3900,
	0x547E462e878c6cB802b9D6095cf6393941565E4F,
	0x88ECE63dE46e5F641C04323000070d6f654Ed868,
	0x9E25d359BB67a5fe44c599B1D2fd0C0599046E1a,
	0x4A4651320346a136E7573B1fafAD09fDA848b9Ff,
	0x30AF9ED6514c943fcDEA1Cf26EEc44AaEd134825,
	0x78EC2Ba25042b43143aDcB64074E1e88C6c87819,
	0x025A5b1C6e97E9e6f9a93aA8aD776bc9e84F261A,
	0x34D1516a1E3AEf181b58e3784e9d6CD1D155241C,
	0x6dA10463F51e105aC3D15A8C4f13E1F1032EFB99,
	0xe3c4C7C5fF37cE99Be342B8D37C21095ab4D26e1,
	0x28e5B3A4B389bd1d921bD9C9B2Db9f2Aa04964D3,
	0xE5672131Ddd8F3610070182af4290cB57DcaF6A3,
	0x091E26376f89d0c6A97467cB57Eae050A43821dD,
	0x570d9193187cFDed8238606626d0e2CbeEB34e83,
	0x8463ebD2AA8bD16C687CE73A99b82B9F1f431D62,
	0x206710759F9c6ad87490a131Ab31255b38A423EB,
	0xDe047A2f608399CE684d9653616339eBF47c32BC,
	0xa405681bF1915c23FE284DD90133a7EBA7f9e143,
	0x1Aa658CC31883f9e3aF69d56201DCb708235F4e6,
	0x1530705B363f66a464F6547A3824Eb2fC7388909,
	0xAFDa97ec9E7E2a0ab53f5967a4891BD82d518cCf,
	0x407E9Aa105466bE8F08e4A5A8B537A528319dDD1,
	0x4A9913a900866e6C711da9256D5576b24BEc584D,
	0xe3ad38D0C2AaCb7cb59ddF0f7B8aAA1B2121cDf3,
	0x30D00F535C9F8be6c415f614aAF2AB12Cb6E4dcE,
	0x106973Ed6e37c93D34cEaD2AF85b7a4C703Eee81,
	0xDf3c6Dbc380e50Af17bcfE9626A96C626A70AB78,
	0x49F0d91d9F5Ded5E486332B6B0281B41f29b92D4,
	0xe13615Ab5370E755cD967faA43bCC4c79a7520fD,
	0xE06Bd466f07D6C8e4224b3fC86Fa587d3265d0dF,
	0x3110BfEa8876Fd84f26d323623F0Dbd8E74C14f8,
	0x59d26fc8304d0D84E1ff27AC98B5473BF93e1097,
	0x6CA5584a814471680d823a787EEEb58c1e03E1e0,
	0xd63f243f649A2E4f33F771DC1d5C34625cAd74F9,
	0xE4C89511d2F610A3AE752f77ffaccCDA0EB36903,
	0x2a5Ac02BCb01A44C661129625355EF91D608A29b,
	0x46fD6bDA4f0190bf3b60d31CB0D6D6711CFFf09E,
	0x5113901DeF7E42Cb7A2800428fEf3B4b18BEB35d,
	0xcbBFa40F36F0Fda22f28BC25E43D52573D6826dB,
	0xdE61c2356c4aFfDB1B94fE04bECc87238fB4589E,
	0x2DdbB811F1b310EFc1D7C31b426F82d6dcF584f4,
	0xaC1a7B00C864C54c13C8a36063eaB123F383dbb0,
	0x7F3d8834fbEb6a4ebA0Ed46CB2aaCCE82B2cEEb6,
	0x6f3064d973C08Dd9c88D43080549F474E5827d71,
	0x33d708908aF70BD27aFdAA02dC029901D3927098,
	0xF548026Ea108E3B3ffe3354b8BB5015F87B2E292,
	0x2e909729016eb1013a197e05210e35cE4435ABc4,
	0x78486b3930A4da1922a1f25e7c3E0a24f054f3D3,
	0xBF1f5E54CDD15dE2bE2c8aeC495D00D804CDd8fc,
	0x20b7da813C3EA5Cf9032610730d1686b7660Ebc7,
	0x82eFa90e1341c57fF7F095Ec55681B1fF6E821A7,
	0x6b434f8e80E8B85A63A9f4fF0A14eB9568a827c8,
	0x221F1fF597930212bBf0Cf5904cFEBeFca537d16,
	0x58b80FF10946cFdA425c81F8619c6C1615A517B5,
	0xAC586131A53D002db0B202b12f9c92b09926ea02,
	0x70575A31709f40A0536173266D9913fbd54b8194,
	0x4192EC7b9288a620659A1159e18755732fB401e8,
	0x42842C35329e504141e482cD0e30884fc5616AAc,
	0xF2da34A196B739811a593C9Fc434f23e099a03d1,
	0xCe0Bdca2Bb503639aE43E280fbA9a49F966f7B8A,
	0xFc38873787d720343f10B062D52E5F495b126558,
	0xFDb6D37687474d42Fe6F95e12b66CD156e0EA8D3,
	0x0f396Be3Cb5deB65Ecd97FD699E4c05EC4474A56,
	0x4b679ce070338d97e41E651C3D78A50C3a7979bf,
	0x9090c0C373bD61Fc7130cE53857d57463ab6A6Ea,
	0xc69681d5b0c499126EcBD8cf5500B50E6C821306,
	0x3a170AA8467D44740376fFC1e1DEf3Ea22C23653,
	0x4f7c843C48a9072D7D74382a8b5fF1e91a02eaa5];

    address [] batch3 = [0xC5Fe6e367742Af4d3A545d073DD310fa4842CD95,
	0x76a66b018a5185Aa411491a3Ff75bF3ABCC99A6E,
	0x68B531349EB44496943Be5FF15A5F510849D561f,
	0x6853285716a92aF6DD07F2F6aeBCA23E5b13f8f6,
	0x95Bce4F4fbfFbd4d4cd2Ca94385AdA9A82e5C683,
	0xA4EBe47B1814Adb62d003C6C9B60264F780eb8Db,
	0xa88361D2c0645F5d8Dd3Be72777a565059FBb139,
	0xBCaB5f93313b29Cbc9f45cDeeC9299CC32Bd7273,
	0x4e2A5a06934c35c83F7066bCa8Bc30f5F1685466,
	0x766Affb42F5d1558f6D64cA34d59291b4ee8CE9d,
	0x5b5452a7c4896114AdD3d5e3Ef72849dB458d83C,
	0xf090d21e518f26074B481c5d4bcAC86d9792B9a6,
	0x2A8e0ebDA46A075D77d197D21292e38D37a20AB3,
	0xbE0898b872b6a54a16E1d5369a5CB7784230f67B,
	0x85B6694F227C4602D2e8cea95E986272E09221E8,
	0x0bC37548e2a82c21BAfa3c7f3297E3055353a39A,
	0xb2130F002Bd9f577DccbEFb80986Efe03D347914,
	0xecA35c5332cc4Ea6FEB295152928C80ea7d56B97,
	0xbbB0D6B4c727De0E57F3017Bb096BeD0d1baa9eb,
	0x192f321333B107eA800c399e5B219A2EF67Cd21C,
	0xAF6f459B17F56af34d1b81edE025251D79a4F443,
	0xE1a35aE293839CB014e068FEa968F44a9675d125,
	0x9c5071e4081C7Def7C4E00d41C7A0352Bb0D9e8D,
	0x8485Ae9606C9648B3FC8d52048c159B5C817BB84,
	0xFc49434836bfE183a0042B097F993FBe2C46275e,
	0xEA125ED28bE7B909F84C8BA08D1d89340100Eb5a,
	0x00BCE681D5F97D9308e04F98b7C16276f89543cf,
	0x12C759A7d404931d9B02212F36E33A70d2bBe4Aa,
	0x3d978CF26c122E184626d1d420e1D1DA58f78102,
	0x98033FAa8d226AB4aD234C4A1909b018e111C9cD,
	0x697BD69B637F6B4311510A038A975CCFc0c93788,
	0xc564733DFF051A3d4Fc460ab7BC44E40599E4796,
	0x3Eb0FCF77A550484Fd371fd019F3c05381F59A0c,
	0x3A56b3b3f778aaA38beBd26d584A900BAbCCadB4,
	0xf6D6C2A6446D0f631677F19B82828D7d4D2dEE24,
	0xAEE9597de68C57439953c46B02f8AC11b5145170,
	0x3a52c7df1bB5e70A0A13e9C9c00f258fe9Da68fD,
	0x2a6b730A5e3733Cb0D33eb266E8C93169d49b3a2,
	0xB0fcB2DdAC5a2259B6F2Bf5686D638acA5Be8782,
	0x6940Dd4B39ec941d2C98E82165F00F6A5f4DEe09,
	0xbBBc17fC1ab7C6D96Ca434178D3E2840F984436D,
	0x3d736DCB07501d01Fa543Fc3bBf2452A5Bd64d80,
	0x5ec6bC92395bFE4dFb8F45cb129AC0c2F290F23d,
	0x8dabC1F4Dc8b5BA2830a9e1c227879B813CCeFcD,
	0xBD8F13002803301B6F6115248fdD50Ae1beA952a,
	0x310eAf3f34Ae436106C05bc47464F887C05d35D8,
	0xD2f01948f83c6545E3045F1bd95387a388bfA8d7,
	0x0C7aee4E68c5783b50B5b68F14c89744a13AC76f,
	0x6770fdFB53dE4CA8e629cA43e10FB6877b7e530e,
	0xD6DE0B874A8f4994af955fC3b975004de59AaEbF,
	0xB33CB651648A99F2FFFf076fd3f645fAC24d460F,
	0xF6BFccfD77aF8372E836815892Ac0d3f98a023db,
	0xAD630CdD705c9861020b7a20cF6c06F045c69C79,
	0x5c054672839C653DAb8cbde3F569AaFbAD52D3fa,
	0xf3e651b7e5A9Afbf8EBc5D0c0182773319Ba3e76,
	0x710f215a7B05a5eA820EA1BB30A469D15eB8D54E,
	0xACDc265C00D55B22e28019F50d994d6FDD871dE8,
	0x230c8A697D4F2710d1F99ad8095C13Cc09C42B47,
	0x3645898c56667a74E406761CFC7FD12284d821E8,
	0xF4de69C1269C41F911A674d7D4326aC92C410C0D,
	0x747f1214925dd83D35FfB536dd5047259BF99EB9,
	0x1C094EE1Cb1013480Fd3871C7bd7ec9e24b6Bf54,
	0x330AD0d38e9c12cbC34d7cfFEFCd99E5530b6bfb,
	0x563178f7E9658B9ba5E9B44686f22534E7C5134A,
	0x11Ce26dA6CBe7761c851024ebBECE78b9b360e25,
	0x49c152bD3DC6BBCDcCE6701aF767731cc212C97D,
	0xb11C10Ba8d2d9bc81148696A70B03df20DbED9b1,
	0x1D6d06662742080121B35D34c2A3153307098367];

    constructor(uint256 _reserved) ERC721A("PENDRAGON GENESIS", "PENDRAGON GENESIS PASS}", maxPerMint, maxTokens){
    reserved = _reserved;
    }

    modifier humanOnly() {
      require(tx.origin == msg.sender, "The caller is another contract");
      _;
    }

    function mint(uint256 amount) external payable humanOnly nonReentrant{
	require(minted + amount  < (maxTokens - reserved));
        require(amount <= maxPerMint);
        require(msg.value >= mintPrice * amount);
        minted = minted + amount;
        _safeMint(msg.sender,amount);
    }

   
    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }


    function setMintPrice(uint256 _mintPrice) external onlyOwner{
        mintPrice = _mintPrice;
    }

  function airdropbatch1() external onlyOwner{
      for (uint256 i=0; i < batch1.length; i++){
          minted ++;
         _safeMint(batch1[i],1);
      } 
  }

  function airdropbatch2() external onlyOwner{
      for (uint256 i=0; i < batch2.length; i++){
          minted ++;
         _safeMint(batch2[i],1);
      } 
  }

    function airdropbatch3() external onlyOwner{
      for (uint256 i=0; i < batch3.length; i++){
          minted ++;
         _safeMint(batch3[i],1);
      } 
  }

    function updateMaxTokens(uint256 _maxTokens) external onlyOwner{
        maxTokens = _maxTokens;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory){
        return ownershipOf(tokenId);
    }
}
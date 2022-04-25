/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-23
*/

/** 
 *  SourceUnit: c:\Users\Ethan\Documents\Projects\contract_labs\contracts\SunflowerMarket.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

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




/** 
 *  SourceUnit: c:\Users\Ethan\Documents\Projects\contract_labs\contracts\SunflowerMarket.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [////IMPORTANT]
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
     * ////IMPORTANT: because control is transferred to `recipient`, care must be
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
 *  SourceUnit: c:\Users\Ethan\Documents\Projects\contract_labs\contracts\SunflowerMarket.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

////import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}




/** 
 *  SourceUnit: c:\Users\Ethan\Documents\Projects\contract_labs\contracts\SunflowerMarket.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
////import "../proxy/utils/Initializable.sol";

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




/** 
 *  SourceUnit: c:\Users\Ethan\Documents\Projects\contract_labs\contracts\SunflowerMarket.sol
*/
            
//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

////import "@openzeppelin/contracts/utils/introspection/IERC165.sol";


interface INFTMarket {
    event AskCreated(
        address indexed nft,
        uint256 indexed tokenID,
        uint256 price,
        uint256 amount,
        address indexed paymentToken
    );

    event AskUpdated(
        bytes32 indexed askID,
        uint256 price,
        address indexed paymentToken
    );

    event AskCanceled(address indexed nft, uint256 indexed tokenID);

    event AskAccepted(
        address indexed nft,
        uint256 indexed tokenID,
        uint256 price,
        address indexed paymentToken
    );

    event BidCreated(
        address indexed nft,
        uint256 indexed tokenID,
        uint256 price,
        address indexed buyer
    );

    event BidCanceled(bytes32 indexed askID, address indexed buyer);

    event BidAccepted(
        address indexed nft,
        uint256 indexed tokenID,
        uint256 price
    );

    struct Ask {
        bool exists;
        address nft;
        uint256 tokenID;
        address seller;
        uint256 price;
        address paymentToken;
        uint256 amount;
        uint256 deadline;
    }

    struct Bid {
        bool exists;
        address buyer;
        uint256 price;
        uint256 deadline;
    }

    function setFee(uint256 _fee) external;

    function createAsk(
        address[] calldata nft,
        uint256[] calldata tokenID,
        uint256[] calldata price,
        uint256[] calldata amount,
        address[] calldata paymentToken,
        uint256[] calldata deadline
    ) external;

    // function updateAsk(
    //     bytes32[] calldata askID,
    //     uint256[] calldata price,
    //     address[] calldata paymentToken,
    //     uint256[] calldata deadline
    // ) external;

    function getAsks() external view returns (Ask[] memory);

    function getBids(bytes32[] calldata askID)
        external
        view
        returns (Bid[][] memory);

    function createBid(bytes32[] calldata askID, uint256[] calldata price, uint256[] calldata deadline)
        external
        payable;

    function cancelAsk(bytes32[] calldata askID) external;

    function cancelBid(bytes32[] calldata askID, uint256[] calldata index) external;

    function acceptAsk(bytes32[] calldata askID) external payable;

    function acceptAskToFarm(bytes32[] calldata askID, address[] calldata landAddr) external payable;

    function acceptBid(bytes32[] calldata askID, uint256[] calldata index) external;

    function withdraw() external;

    function withdrawToken(address tokenAddress) external;
}




/** 
 *  SourceUnit: c:\Users\Ethan\Documents\Projects\contract_labs\contracts\SunflowerMarket.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

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
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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




/** 
 *  SourceUnit: c:\Users\Ethan\Documents\Projects\contract_labs\contracts\SunflowerMarket.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "../../utils/introspection/IERC165.sol";

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
 *  SourceUnit: c:\Users\Ethan\Documents\Projects\contract_labs\contracts\SunflowerMarket.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}




/** 
 *  SourceUnit: c:\Users\Ethan\Documents\Projects\contract_labs\contracts\SunflowerMarket.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

////import "../utils/ContextUpgradeable.sol";
////import "../proxy/utils/Initializable.sol";

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}


/** 
 *  SourceUnit: c:\Users\Ethan\Documents\Projects\contract_labs\contracts\SunflowerMarket.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.4;

////import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
////import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
////import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
////import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
////import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
////import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

////import "./interfaces/INFTMarket.sol";

contract SunflowerMarket is Initializable, OwnableUpgradeable, INFTMarket {
    bytes32[] public askIDs;
    mapping(bytes32 => uint256) public askIDIndex;
    mapping(bytes32 => Ask) public asks;
    mapping(bytes32 => Bid[]) public bids;

    bytes4 constant ERC721_INTERFACE_ID = 0x80ac58cd;
    bytes4 constant ERC1155_INTERFACE_ID = 0xd9b67a26;

    string constant REVERT_NOT_OWNER = "NFTMarket::not owner";
    string constant REVERT_NOT_ENOUGH_AMOUNT = "NFTMarket:: not enough amount";
    string constant REVERT_NOT_APPROVED = "NFTMarket::not approved";
    string constant REVERT_DUPLICATED_ASK = "NFTMarket::duplicated ask";
    string constant REVERT_NOT_A_CREATOR_OF_ASK =
        "NFTMarket::not a creator of the ask";
    string constant REVERT_NOT_A_CREATOR_OF_BID =
        "NFTMarket::not a creator of the bid";
    string constant REVERT_BID_TOO_LOW = "NFTMarket::bid too low";
    string constant REVERT_ASK_DOES_NOT_EXIST = "NFTMarket::ask does not exist";
    string constant REVERT_ASK_NOT_AUCTION = "NFTMarket::ask is not auction";
    string constant REVERT_ASK_EXPIRED = "NFTMarket::ask expired";
    string constant REVERT_BID_DOES_NOT_EXIST = "NFTMarket::bid does not exist";
    string constant REVERT_CANT_ACCEPT_OWN_ASK =
        "NFTMarket::cant accept own ask";
    string constant REVERT_ASK_SELLER_NOT_OWNER =
        "NFTMarket::ask creator not owner";
    string constant REVERT_INSUFFICIENT_ETHER =
        "NFTMarket::insufficient ether sent";
    string constant REVERT_INSUFFICIENT_VALUE = "NFTMarket::insufficient value";
    string constant REVERT_ZERO_BALANCE = "NFTMarket::zero balance";
    string constant REVERT_NOT_DIRECT_SALE = "NFTMarket::not direct sale";

    uint256 public fee;

    // address public beneficiary;

    // =====================================================================

    function initialize(uint256 _fee) public initializer {
        fee = _fee;
    }

    function setFee(uint256 _fee) public override onlyOwner {
        require(_fee < 10000, "%%");
        fee = _fee;
    }

    function getAsks() external view override returns (Ask[] memory) {
        Ask[] memory all = new Ask[](askIDs.length);
        for (uint256 i = 0; i < askIDs.length; i++) {
            all[i] = asks[askIDs[i]];
        }
        return all;
    }

    function getBids(bytes32[] calldata askID)
        external
        view
        override
        returns (Bid[][] memory)
    {
        Bid[][] memory all = new Bid[][](askID.length);
        for (uint256 i = 0; i < askID.length; i++) {
            Bid[] memory bidsOfAsk = bids[askID[i]];
            all[i] = bidsOfAsk;
        }
        return all;
    }

    /// @notice Creates an ask for (`nft`, `tokenID`) tuple for `price`
    /// @dev Creating an ask requires msg.sender to have at least one qty of
    /// (`nft`, `tokenID`).
    /// @param nft     An array of ERC-721 and or ERC-1155 addresses.
    /// @param tokenID Token Ids of the NFTs msg.sender wishes to sell.
    /// @param price   Prices at which the seller is willing to sell the NFTs.
    /// @param paymentToken      ERC20 token Address for payment.
    /// @param deadline      Deadline timestamp for auction, direct sale if 0.
    /// then anyone can accept.
    function createAsk(
        address[] calldata nft,
        uint256[] calldata tokenID,
        uint256[] calldata price,
        uint256[] calldata amount,
        address[] calldata paymentToken,
        uint256[] calldata deadline
    ) external override {
        for (uint256 i = 0; i < nft.length; i++) {
            address _nft = nft[i];
            uint256 _tokenId = tokenID[i];
            bytes32 askID = keccak256(
                abi.encodePacked(_nft, _tokenId, msg.sender)
            );
            require(!asks[askID].exists, REVERT_DUPLICATED_ASK);
            IERC165 nftContract = IERC165(_nft);
            if (nftContract.supportsInterface(ERC721_INTERFACE_ID)) {
                IERC721 erc721nft = IERC721(_nft);
                require(
                    erc721nft.ownerOf(_tokenId) == msg.sender,
                    REVERT_NOT_OWNER
                );
                require(
                    erc721nft.getApproved(_tokenId) == address(this) ||
                        erc721nft.isApprovedForAll(msg.sender, address(this)),
                    REVERT_NOT_APPROVED
                );
            }
            if (nftContract.supportsInterface(ERC1155_INTERFACE_ID)) {
                IERC1155 erc1155nft = IERC1155(_nft);
                require(
                    erc1155nft.balanceOf(msg.sender, _tokenId) >= amount[i],
                    REVERT_NOT_ENOUGH_AMOUNT
                );
                require(
                    erc1155nft.isApprovedForAll(msg.sender, address(this)),
                    REVERT_NOT_APPROVED
                );
            }

            askIDIndex[askID] = askIDs.length;
            askIDs.push(askID);
            // overwristes or creates a new one
            asks[askID] = Ask({
                exists: true,
                nft: _nft,
                tokenID: _tokenId,
                seller: msg.sender,
                price: price[i],
                amount: amount[i],
                paymentToken: paymentToken[i],
                deadline: deadline[i]
            });

            emit AskCreated({
                nft: _nft,
                tokenID: _tokenId,
                price: asks[askID].price,
                amount: asks[askID].amount,
                paymentToken: paymentToken[i]
            });
        }
    }

    /// @notice Creates an ask for (`nft`, `tokenID`) tuple for `price`
    /// @dev Creating an ask requires msg.sender to have at least one qty of
    /// (`nft`, `tokenID`).
    /// @param askID  askID
    /// @param price   Prices at which the seller is willing to sell the NFTs.
    /// @param paymentToken      ERC20 token Address for payment.
    /// @param deadline      Deadline timestamp for auction, direct sale if 0.
    /// then anyone can accept.
    // function updateAsk(
    //     bytes32[] calldata askID,
    //     uint256[] calldata price,
    //     address[] calldata paymentToken,
    //     uint256[] calldata deadline
    // ) external override {
    //     for (uint256 i = 0; i < askID.length; i++) {
    //         Ask memory ask = asks[askID[i]];
    //         require(ask.seller == msg.sender, REVERT_NOT_A_CREATOR_OF_ASK);
    //         // overwristes or creates a new one
    //         asks[askID[i]] = Ask({
    //             exists: true,
    //             nft: ask.nft,
    //             tokenID: ask.tokenID,
    //             seller: msg.sender,
    //             price: price[i],
    //             paymentToken: paymentToken[i],
    //             deadline: deadline[i]
    //         });

    //         emit AskUpdated({
    //             askID: askID[i],
    //             price: price[i],
    //             paymentToken: paymentToken[i]
    //         });
    //     }
    // }

    /// @notice Creates a bid on (`nft`, `tokenID`) tuple for `price`.
    /// @param askID   AskID.
    /// @param price   Prices at which the buyer is willing to buy the NFTs.
    function createBid(
        bytes32[] calldata askID,
        uint256[] calldata price,
        uint256[] calldata deadline
    ) external payable override {
        // bidding on own NFTs is possible. But then again, even if we wanted to disallow it,
        // it would not be an effective mechanism, since the agent can bid from his other
        // wallets
        uint256 totalPrice = 0;
        for (uint256 i = 0; i < askID.length; i++) {
            Ask memory ask = asks[askID[i]];
            require(ask.exists, REVERT_ASK_DOES_NOT_EXIST);
            require(ask.deadline > 0, REVERT_ASK_NOT_AUCTION);
            require(block.timestamp < ask.deadline, REVERT_ASK_EXPIRED);
            require(price[i] >= ask.price, REVERT_BID_TOO_LOW);
            if (ask.paymentToken == address(1)) {
                totalPrice += price[i];
            }
            bids[askID[i]].push(
                Bid({
                    exists: true,
                    buyer: msg.sender,
                    price: price[i],
                    deadline: deadline[i]
                })
            );

            emit BidCreated({
                nft: ask.nft,
                tokenID: ask.tokenID,
                price: price[i],
                buyer: msg.sender
            });
        }
        require(totalPrice == msg.value, REVERT_INSUFFICIENT_VALUE);
    }

    /// @notice Cancels ask(s) that the seller previously created.
    /// @param askID askIDs
    function cancelAsk(bytes32[] calldata askID) external override {
        for (uint256 i = 0; i < askID.length; i++) {
            Ask memory ask = asks[askID[i]];
            require(ask.exists, REVERT_ASK_DOES_NOT_EXIST);
            require(ask.seller == msg.sender, REVERT_NOT_A_CREATOR_OF_ASK);
            if (ask.deadline > 0) {
                Bid[] memory bidsOfAsk = bids[askID[i]];
                for (uint256 j = 0; j < bidsOfAsk.length; j++) {
                    Bid memory bid = bidsOfAsk[j];
                    if (bid.exists) {
                        if (ask.paymentToken == address(1)) {
                            // balances[bid.buyer] += bid.price;
                        }
                    }
                }
                delete bids[askID[i]];
            }
            delete asks[askID[i]];
            _removeAskID(askID[i]);
            emit AskCanceled({nft: ask.nft, tokenID: ask.tokenID});
        }
    }

    /// @notice Cancels bid(s) that the msg.sender previously created.
    /// @param askID askID
    function cancelBid(bytes32[] calldata askID, uint256[] calldata index)
        external
        override
    {
        for (uint256 i = 0; i < askIDs.length; i++) {
            Bid[] memory bidsOfAsk = bids[askID[i]];
            if (index[i] < bidsOfAsk.length) {
                require(bidsOfAsk[index[i]].exists, REVERT_BID_DOES_NOT_EXIST);
                require(
                    bidsOfAsk[index[i]].buyer == msg.sender,
                    REVERT_NOT_A_CREATOR_OF_BID
                );
                if (asks[askID[i]].paymentToken == address(1)) {
                    // balances[msg.sender] += bidsOfAsk[index[i]].price;
                }
                bidsOfAsk[index[i]] = bidsOfAsk[bidsOfAsk.length - 1];
                askIDs.pop();
            }
            emit BidCanceled({askID: askID[i], buyer: msg.sender});
        }
    }

    /// @notice Seller placed ask(s), you (buyer) are fine with the terms. You accept
    /// their ask by sending the required msg.value and indicating the id of the
    /// token(s) you are purchasing.
    /// @param askID askIDs
    /// asks on.
    function acceptAsk(bytes32[] calldata askID) external payable override {
        uint256 totalPrice = 0;
        for (uint256 i = 0; i < askID.length; i++) {
            Ask memory ask = asks[askID[i]];
            require(ask.exists, REVERT_ASK_DOES_NOT_EXIST);
            require(ask.seller != msg.sender, REVERT_CANT_ACCEPT_OWN_ASK);
            require(ask.deadline == 0, REVERT_NOT_DIRECT_SALE);
            IERC165 nft = IERC165(ask.nft);
            if (nft.supportsInterface(ERC721_INTERFACE_ID)) {
                IERC721 erc721nft = IERC721(ask.nft);
                require(
                    erc721nft.ownerOf(ask.tokenID) == ask.seller,
                    REVERT_ASK_SELLER_NOT_OWNER
                );
                erc721nft.safeTransferFrom(
                    ask.seller,
                    msg.sender,
                    ask.tokenID,
                    new bytes(0)
                );
            }
            if (nft.supportsInterface(ERC1155_INTERFACE_ID)) {
                IERC1155 erc1155nft = IERC1155(ask.nft);
                require(
                    erc1155nft.balanceOf(ask.seller, ask.tokenID) >= ask.amount,
                    REVERT_ASK_SELLER_NOT_OWNER
                );
                erc1155nft.safeTransferFrom(
                    ask.seller,
                    msg.sender,
                    ask.tokenID,
                    ask.amount,
                    new bytes(0)
                );
            }
            if (ask.paymentToken == address(1)) {
                totalPrice += ask.price;
                payable(ask.seller).transfer(_takeFee(ask.price));
            } else {
                IERC20 token = IERC20(ask.paymentToken);
                uint256 income = _takeFee(ask.price);
                uint256 cut = ask.price - income;
                require(token.transferFrom(msg.sender, ask.seller, income));
                require(token.transferFrom(msg.sender, address(this), cut));
            }

            emit AskAccepted({
                nft: ask.nft,
                tokenID: ask.tokenID,
                price: ask.price,
                paymentToken: ask.paymentToken
            });

            delete asks[askID[i]];
            _removeAskID(askID[i]);
        }

        require(totalPrice == msg.value, REVERT_INSUFFICIENT_VALUE);
    }

    /// @notice Seller placed ask(s), you (buyer) are fine with the terms. You accept
    /// their ask by sending the required msg.value and indicating the id of the
    /// token(s) you are purchasing.
    /// @param askID askIDs
    /// asks on.
    function acceptAskToFarm(
        bytes32[] calldata askID,
        address[] calldata landAddr
    ) external payable override {
        uint256 totalPrice = 0;
        for (uint256 i = 0; i < askID.length; i++) {
            Ask memory ask = asks[askID[i]];
            require(ask.exists, REVERT_ASK_DOES_NOT_EXIST);
            require(ask.seller != msg.sender, REVERT_CANT_ACCEPT_OWN_ASK);
            require(ask.deadline == 0, REVERT_NOT_DIRECT_SALE);
            IERC165 nft = IERC165(ask.nft);
            if (nft.supportsInterface(ERC1155_INTERFACE_ID)) {
                IERC1155 erc1155nft = IERC1155(ask.nft);
                require(
                    erc1155nft.balanceOf(ask.seller, ask.tokenID) >= ask.amount,
                    REVERT_ASK_SELLER_NOT_OWNER
                );
                erc1155nft.safeTransferFrom(
                    ask.seller,
                    landAddr[i],
                    ask.tokenID,
                    ask.amount,
                    new bytes(0)
                );
            }
            if (ask.paymentToken == address(1)) {
                totalPrice += ask.price;
                payable(ask.seller).transfer(_takeFee(ask.price));
            } else {
                IERC20 token = IERC20(ask.paymentToken);
                uint256 income = _takeFee(ask.price);
                uint256 cut = ask.price - income;
                require(token.transferFrom(msg.sender, ask.seller, income));
                require(token.transferFrom(msg.sender, address(this), cut));
            }

            emit AskAccepted({
                nft: ask.nft,
                tokenID: ask.tokenID,
                price: ask.price,
                paymentToken: ask.paymentToken
            });

            delete asks[askID[i]];
            _removeAskID(askID[i]);
        }

        require(totalPrice == msg.value, REVERT_INSUFFICIENT_VALUE);
    }

    /// @notice You are the owner of the NFTs, someone submitted the bids on them.
    /// You accept one or more of these bids.
    /// @param askID Token Ids of the NFTs msg.sender wishes to accept the
    /// bids on.
    function acceptBid(bytes32[] calldata askID, uint256[] calldata index)
        external
        override
    {
        uint256 totalPrice = 0;
        for (uint256 i = 0; i < askID.length; i++) {
            Bid memory bid = bids[askID[i]][index[i]];
            require(bid.exists, REVERT_BID_DOES_NOT_EXIST);
            Ask memory ask = asks[askID[i]];
            IERC721 nft = IERC721(ask.nft);
            require(nft.ownerOf(ask.tokenID) == msg.sender, REVERT_NOT_OWNER);
            require(
                nft.getApproved(ask.tokenID) == address(this) ||
                    nft.isApprovedForAll(msg.sender, address(this)),
                REVERT_NOT_APPROVED
            );

            if (ask.paymentToken == address(1)) {
                totalPrice += bid.price;
                Bid[] memory bidsOfAsk = bids[askID[i]];
                for (uint256 j = 0; j < bidsOfAsk.length; j++) {
                    if (j != index[i]) {
                        // balances[bidsOfAsk[j].buyer] += bidsOfAsk[j].price;
                    }
                }
            } else {
                IERC20 token = IERC20(ask.paymentToken);
                require(token.transferFrom(bid.buyer, ask.seller, bid.price));
            }
            // escrow[msg.sender] += bids[nftAddress][tokenID[i]].price;
            nft.safeTransferFrom(
                ask.seller,
                bid.buyer,
                ask.tokenID,
                new bytes(0)
            );
            emit BidAccepted({
                nft: ask.nft,
                tokenID: ask.tokenID,
                price: bid.price
            });

            delete asks[askID[i]];
            delete bids[askID[i]];
            _removeAskID(askID[i]);
        }

        uint256 remaining = _takeFee(totalPrice);
    }

    /// @notice Sellers can receive their payment by calling this function.
    function withdraw() external override onlyOwner {
        payable(address(msg.sender)).transfer(address(this).balance);
    }

    /// @notice Sellers can receive their payment by calling this function.
    function withdrawToken(address tokenAddress) external override onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    /// @dev Hook that is called to collect the fees in FeeCollector extension.
    /// Plain implementation of marketplace (without the FeeCollector extension)
    /// has no fees.
    /// @param totalPrice Total price payable for the trade(s).
    function _takeFee(uint256 totalPrice) internal virtual returns (uint256) {
        uint256 cut = (totalPrice * fee) / 10000;
        return totalPrice - cut;
    }

    function _removeAskID(bytes32 askID) internal {
        uint256 index = askIDIndex[askID];
        askIDs[index] = askIDs[askIDs.length - 1];
        askIDIndex[askIDs[index]] = index;
        askIDs.pop();
    }
}
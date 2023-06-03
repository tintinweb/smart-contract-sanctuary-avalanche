/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-02
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        if (_initialized < type(uint8).max) {
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

// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
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
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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

interface IAvalaunchNFTMarketplace {
    event FeeParametersSet(uint256 feePrecision, uint256 feePercent);
    event TimeExtensionLimitsSet(uint256 minTimeExtensionPerBid, uint256 maxTimeExtensionPerBid);
    event MarketplaceItemCreated(
        uint256 indexed itemId,
        address indexed itemAddress,
        uint256 indexed tokenId,
        address seller,
        uint256 price,
        address buyer
    );
    event MarketplaceItemRemoved(uint256 indexed itemId);
    event MarketplaceItemBought(uint256 indexed itemId, address indexed buyer);
    event MarketplaceAuctionItemCreated(
        uint256 indexed itemId,
        address indexed itemAddress,
        uint256 indexed tokenId,
        address seller,
        uint256 startingPrice
    );
    event AskCreated(uint256 indexed itemId, address indexed from, uint256 value);
    event AskRemoved(uint256 indexed itemId, address indexed from);
    event NewHighestBid(uint256 indexed itemId, address indexed from, uint256 value);
    event AuctionedItemClaimed(uint256 indexed itemId, address indexed bidder);
    event FeesWithdrawn(address receiver, uint256 amount);
}

error BatchReveal__InvalidInitParams();
error BatchReveal__NoBatchAvailable();

error AvalaunchNFT__InvalidRoyaltySettings();
error AvalaunchNFT__AVAXTransferFailed();
error AvalaunchNFT__CollectionSizeLimitReached();
error AvalaunchNFT__InvalidSignature();
error AvalaunchNFT__OnlyDirectCalls();
error AvalaunchNFT__InvalidNFTPrice();
error AvalaunchNFT__InvalidAddress();
error AvalaunchNFT__InvalidMessageValue();
error AvalaunchNFT__MintLimitCrossed();
error AvalaunchNFT__ArrayLengthMismatch();
error AvalaunchNFT__SaleNotStartedYet();
error AvalaunchNFT__InvalidPricing();
error AvalaunchNFT__TimestampsCrossing();
error AvalaunchNFT__InvalidCallbackGasLimit();
error AvalaunchNFT__InvalidKeyHash();
error AvalaunchNFT__ContractIsNotConsumer();
error AvalaunchNFT__BalanceEmpty();
error AvalaunchNFT__BaseURIAlreadySet();
error AvalaunchNFT__unrevealedURIAlreadySet();
error AvalaunchNFT__VRFAlreadySet();
error AvalaunchNFT__SignatureExpired();
error AvalaunchNFT__SignatureAlreadyUsed();
error AvalaunchNFT__VRFNotActive();

error AvalaunchNFTMarketplace__ZeroValue();
error AvalaunchNFTMarketplace__InvalidCaller();
error AvalaunchNFTMarketplace__InvalidMessageValue();
error AvalaunchNFTmarketplace__LowLevelCallFailed();
error AvalaunchNFTMarketplace__NoFees();
error AvalaunchNFTMarketplace__InvalidAddress();
error AvalaunchNFTMarketplace__ItemUnavailable();
error AvalaunchNFTMarketplace__AskInactive();
error AvalaunchNFTMarketplace__InvalidFeeParameters();
error AvalaunchNFTMarketplace__InvalidItemId();
error AvalaunchNFTMarketplace__InvalidBiddingParameters();
error AvalaunchNFTMarketplace__AuctionEnded();
error AvalaunchNFTMarketplace__AuctionInProgress();
error AvalaunchNFTMarketplace__ArrayLengthMismatch();
error AvalaunchNFTMarketplace__InvalidStartingPrice();
error AvalaunchNFTMarketplace__InvalidTimeExtensionPerBid();
error AvalaunchNFTMarketplace__AskAlreadyActive();
error AvalaunchNFTMarketplace__InvalidAskExpirationTime();
error AvalaunchNFTMarketplace__InvalidAmount();
error AvalaunchNFTMarketplace__PriceMismatch();

error AvalaunchNFTFactory__ImplementationAlreadySet();
error AvalaunchNFTFactory__ImplementationNotSet();
error AvalaunchNFTFactory__CloneCreationFailed();
error AvalaunchNFTFactory__InitializationFailed();
error AvalaunchNFTFactory__InvalidIndexParams();

contract AvalaunchNFTMarketplace is IAvalaunchNFTMarketplace, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    struct Item {
        address itemAddress; // Address of an NFT
        uint256 tokenId; // NFT Token Id
        address payable seller; // Seller account
        address payable buyer; // Buyer account
        uint256 price; // Price to sell for
        bool available; // Is currently purchasable
    }

    struct AuctionItem {
        address itemAddress; // Address of an NFT
        uint256 tokenId; // NFT Token Id
        address payable seller; // Seller account
        address payable bidder; // Account which made the highest bid
        uint256 startingPrice; // Auction starting price
        uint256 highestBid; // Highest bid value
        uint256 timeExtensionPerBid; // Amount of time for which auction extends on every bid
        uint256 endTime; // Auction end time (extended on each bid / zero if not started yet)
        bool available; // Can you currently make an offer
    }

    struct Ask {
        uint256 value; // Value asker is offering
        bool active; // Is ask active (not accepted/removed)
    }

    // Globals
    Item[] public items;
    AuctionItem[] public auctionItems;
    mapping(address => uint256) public userFunds;
    mapping(uint256 => mapping(address => Ask)) public asks;
    uint256 public fees;
    uint256 public withdrawnFees;
    uint256 public feePrecision;
    uint256 public feePercent;
    uint256 public minTimeExtensionPerBid;
    uint256 public maxTimeExtensionPerBid;

    // Modifiers
    modifier onlyEOA() {
        _onlyEOA();
        _;
    }

    function _onlyEOA() private view {
        if (msg.sender != tx.origin) {
            revert AvalaunchNFT__OnlyDirectCalls();
        }
    }

    /**
     * @notice Disable direct call initialization
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initialization function
     * @param _owner - owner address
     * @param _feePrecision - maximum fee value
     * @param _feePercent - percentage of fee taken on purchase
     * @param _minTimeExtensionPerBid - minimum time for which auction is extended when someone makes an offer
     * @param _maxTimeExtensionPerBid - maximum time for which auction is extended when someone makes an offer
     */
    function initialize(
        address _owner,
        uint256 _feePrecision,
        uint256 _feePercent,
        uint256 _minTimeExtensionPerBid,
        uint256 _maxTimeExtensionPerBid
    ) external initializer {
        // Internal initializations
        __ReentrancyGuard_init();
        // Owner address check
        if (_owner == address(0)) {
            revert AvalaunchNFT__InvalidAddress();
        }
        // Ownership transfer
        _transferOwnership(_owner);
        // Set fee parameters
        _setFeeParameters(_feePrecision, _feePercent);
        // Set auctioning parameters
        _setTimeExtensionLimits(_minTimeExtensionPerBid, _maxTimeExtensionPerBid);
    }

    /**
     * @notice External function to set marketplace fee parameters
     * @dev for more info look at _setFeeParameters
     */
    function setFeeParameters(uint256 _feePrecision, uint256 _feePercent) external onlyOwner {
        _setFeeParameters(_feePrecision, _feePercent);
    }

    /**
     * @notice Private function to set marketplace fee parameters
     * @param _feePrecision - maximum fee value
     * @param _feePercent - percentage of fee taken on purchase
     */
    function _setFeeParameters(uint256 _feePrecision, uint256 _feePercent) private {
        if (_feePrecision == 0 || _feePrecision > 1_000_000 || _feePrecision < _feePercent * 5) {
            // 20% maximum fee take
            revert AvalaunchNFTMarketplace__InvalidFeeParameters();
        }
        // Set values
        feePrecision = _feePrecision;
        feePercent = _feePercent;
        // Emit event
        emit FeeParametersSet(_feePrecision, _feePercent);
    }

    /**
     * @notice External function to set auction flow parameters
     * @dev for more information look at _setTimeExtensionLimits
     */
    function setMinTimeExtensionPerBid(
        uint256 _minTimeExtensionPerBid,
        uint256 _maxTimeExtensionPerBid
    ) external onlyOwner {
        _setTimeExtensionLimits(_minTimeExtensionPerBid, _maxTimeExtensionPerBid);
    }

    /**
     * @notice Private function to set auction flow parameters
     * @param _minTimeExtensionPerBid - min time for which auction is extended when someone makes an offer
     * @param _maxTimeExtensionPerBid - max time for which auction is extended when someone makes an offer
     */
    function _setTimeExtensionLimits(uint256 _minTimeExtensionPerBid, uint256 _maxTimeExtensionPerBid) private {
        if (_minTimeExtensionPerBid > _maxTimeExtensionPerBid) {
            revert AvalaunchNFTMarketplace__InvalidBiddingParameters();
        }
        minTimeExtensionPerBid = _minTimeExtensionPerBid;
        maxTimeExtensionPerBid = _maxTimeExtensionPerBid;
        emit TimeExtensionLimitsSet(_minTimeExtensionPerBid, _maxTimeExtensionPerBid);
    }

    /**
     * @notice Function to list your nfts on marketplace
     * @param itemAddresses - addresses of your nft contracts
     * @param tokenIds - ids of your tokens
     * @param prices - prices
     * @param buyers - pre-determined buyer addresses, if unknown set [address(0)...]
     */
    function addItems(
        address[] calldata itemAddresses,
        uint256[] calldata tokenIds,
        uint256[] calldata prices,
        address[] calldata buyers
    ) external {
        // Gas optimization
        uint256 numberOfItems = itemAddresses.length;
        // Check array sizes are matching
        if (numberOfItems != tokenIds.length || numberOfItems != prices.length || numberOfItems != buyers.length) {
            revert AvalaunchNFTMarketplace__ArrayLengthMismatch();
        }
        // Add each item
        for (uint256 i = 0; i < numberOfItems; i++) {
            addItem(itemAddresses[i], tokenIds[i], prices[i], buyers[i]);
        }
    }

    /**
     * @notice Function to list your nft on marketplace
     * @param itemAddress - address of your nft contract
     * @param tokenId - id of your token
     * @param price - price
     * @param buyer - pre-determined buyer address, if unknown set address(0)
     */
    function addItem(address itemAddress, uint256 tokenId, uint256 price, address buyer) public nonReentrant {
        // Check price
        if (price == 0) {
            revert AvalaunchNFTMarketplace__ZeroValue();
        }
        // Create item
        items.push(Item(itemAddress, tokenId, payable(msg.sender), payable(buyer), price, true));
        // Transfer item from user to marketplace
        IERC721Upgradeable(itemAddress).transferFrom(msg.sender, address(this), tokenId);
        // Emit event
        emit MarketplaceItemCreated(items.length - 1, itemAddress, tokenId, msg.sender, price, buyer);
    }

    /**
     * @notice Function to remove your nft from marketplace
     * @param _itemId - id of your nft/item
     */
    function removeItem(uint256 _itemId) external nonReentrant {
        // Retreive item from storage
        Item storage item = items[_itemId];
        // Check that msg.sender has permissions to remove this item from marketplace
        if (item.seller != msg.sender) {
            revert AvalaunchNFTMarketplace__InvalidCaller();
        }
        // Make sure item is not sold
        if (!item.available) {
            revert AvalaunchNFTMarketplace__ItemUnavailable();
        }
        // Mark item as unavailable
        item.available = false;
        // Transfer item back to owner
        IERC721Upgradeable(item.itemAddress).transferFrom(address(this), msg.sender, item.tokenId);
        // Emit event
        emit MarketplaceItemRemoved(_itemId);
    }

    /**
     * @notice Function to instantly buy an item
     * @param _itemId - id of item/nft user wants to buy
     */
    function buyItem(uint256 _itemId) external payable nonReentrant {
        // Retreive item from storage
        Item storage item = items[_itemId];
        // Check item availability
        if (!item.available) {
            revert AvalaunchNFTMarketplace__ItemUnavailable();
        }
        // Check that msg.sender is a legitimate buyer
        if (item.seller == msg.sender || (item.buyer != address(0) && item.buyer != msg.sender)) {
            revert AvalaunchNFTMarketplace__InvalidCaller();
        }
        // Check msg.value
        if (item.price != msg.value) {
            revert AvalaunchNFTMarketplace__InvalidMessageValue();
        }
        // Calculate fee
        uint256 fee = applyFees(msg.value);
        // Increase balance of the seller
        userFunds[item.seller] += msg.value - fee;
        // Mark item as unavailable
        item.available = false;
        // Transfer item to the buyer
        IERC721Upgradeable(item.itemAddress).transferFrom(address(this), msg.sender, item.tokenId);
        // Emit event
        emit MarketplaceItemBought(_itemId, msg.sender);
    }

    /**
     * @notice Function to create a new ask
     * @param _itemId - id of item/nft user wants to buy
     */
    function createAsk(uint256 _itemId) external payable nonReentrant {
        // Check msg value
        if (msg.value == 0) {
            revert AvalaunchNFTMarketplace__InvalidMessageValue();
        }
        // Retrieve item
        Item storage item = items[_itemId];
        // Check if item is available to  buy
        if (!item.available) {
            revert AvalaunchNFTMarketplace__ItemUnavailable();
        }
        // Check msg sender is not seller
        if (item.seller == msg.sender) {
            revert AvalaunchNFTMarketplace__InvalidCaller();
        }
        // Disable asks if item is made for whitelist buy
        if (item.buyer != address(0)) {
            revert AvalaunchNFTMarketplace__InvalidCaller();
        }
        // Retrieve ask
        Ask storage ask = asks[_itemId][msg.sender];
        if (ask.active == true) {
            revert AvalaunchNFTMarketplace__AskAlreadyActive();
        }
        // Set activity state
        ask.active = true;
        // Set value
        ask.value = msg.value;
        // Emit an event
        emit AskCreated(_itemId, msg.sender, msg.value);
    }

    /**
     * @notice Function to remove your ask
     * @param _itemId - id of item for which ask was created
     */
    function removeAsk(uint256 _itemId) external nonReentrant {
        // Retrieve ask
        Ask storage ask = asks[_itemId][msg.sender];
        // Check ask activity
        if (!ask.active) {
            revert AvalaunchNFTMarketplace__AskInactive();
        }
        // Set values
        ask.active = false;
        // Return AVAX taken ask
        safeFundTransfer(msg.sender, ask.value);
        // Emit an event
        emit AskRemoved(_itemId, msg.sender);
    }

    /**
     * @notice Function to accept an offer
     * @param _itemId - id of item
     * @param _asker - wallet which made an offer
     */
    function acceptAsk(uint256 _itemId, address _asker, uint256 _price) external nonReentrant {
        Ask storage ask = asks[_itemId][_asker];
        // Check ask activity
        if (!ask.active) {
            revert AvalaunchNFTMarketplace__AskInactive();
        }
        Item storage item = items[_itemId];
        // Check if item is available to buy
        if (!item.available) {
            revert AvalaunchNFTMarketplace__ItemUnavailable();
        }
        // Check that msg.sender is current item owner
        if (item.seller != msg.sender) {
            revert AvalaunchNFTMarketplace__InvalidCaller();
        }
        if (ask.value != _price) {
            revert AvalaunchNFTMarketplace__PriceMismatch();
        }
        // Mark item as unavailable
        item.available = false;
        // Mark ask as inactive
        ask.active = false;
        // Calculate fee
        uint256 fee = applyFees(ask.value);
        // Forward AVAX to seller
        safeFundTransfer(item.seller, ask.value - fee);
        // Transfer item to the buyer
        IERC721Upgradeable(item.itemAddress).transferFrom(address(this), _asker, item.tokenId);
        // Emit event
        emit MarketplaceItemBought(_itemId, _asker);
    }

    /**
     * Function to add a auctionable item to marketplace
     * @dev Auction starts once first offer is arrived
     * @param itemAddress - address of your nft contract
     * @param tokenId - id of your token
     * @param startingPrice - price
     * @param timeExtensionPerBid - auction time extension per bid
     */
    function addAuctionItem(
        address itemAddress,
        uint256 tokenId,
        uint256 startingPrice,
        uint256 timeExtensionPerBid
    ) external {
        // Check price
        if (startingPrice == 0) {
            revert AvalaunchNFTMarketplace__ZeroValue();
        }
        if (startingPrice < 0.01 ether) {
            revert AvalaunchNFTMarketplace__InvalidStartingPrice();
        }
        if (timeExtensionPerBid < minTimeExtensionPerBid || timeExtensionPerBid > maxTimeExtensionPerBid) {
            revert AvalaunchNFTMarketplace__InvalidTimeExtensionPerBid();
        }
        // Create item
        auctionItems.push(
            AuctionItem(
                itemAddress,
                tokenId,
                payable(msg.sender),
                payable(address(0)),
                startingPrice,
                0,
                timeExtensionPerBid,
                0,
                true
            )
        );
        // Transfer item from user to marketplace
        IERC721Upgradeable(itemAddress).transferFrom(msg.sender, address(this), tokenId);
        // Emit event
        emit MarketplaceAuctionItemCreated(auctionItems.length - 1, itemAddress, tokenId, msg.sender, startingPrice);
    }

    /**
     * @notice Function to remove your nft from marketplace
     * @param _itemId - id of your nft/item
     */
    function removeAuctionItem(uint256 _itemId) external nonReentrant {
        // Retreive item from storage
        AuctionItem storage item = auctionItems[_itemId];
        // Check that msg.sender has permissions to remove this item from marketplace
        if (item.seller != msg.sender) {
            revert AvalaunchNFTMarketplace__InvalidCaller();
        }
        // Make sure item is not sold
        if (!item.available) {
            revert AvalaunchNFTMarketplace__ItemUnavailable();
        }
        // Make sure auction hasn't started
        if (item.endTime > 0) {
            revert AvalaunchNFTMarketplace__AuctionInProgress();
        }
        // Mark item as unavailable
        item.available = false;
        // Transfer item back to owner
        IERC721Upgradeable(item.itemAddress).transferFrom(address(this), msg.sender, item.tokenId);
        // Emit event
        emit MarketplaceItemRemoved(_itemId);
    }

    /**
     * Function to let users make auction offers
     * @param _itemId - id of auctioned marketplace item
     */
    function bid(uint256 _itemId) external payable onlyEOA nonReentrant {
        // Retrieve item
        AuctionItem storage item = auctionItems[_itemId];
        // Check if item is available to buy
        if (!item.available) {
            revert AvalaunchNFTMarketplace__ItemUnavailable();
        }
        // Check msg value
        if (
            (item.highestBid == 0 && msg.value < item.startingPrice) ||
            msg.value <= item.highestBid + (item.highestBid * 10) / 100
        ) {
            revert AvalaunchNFTMarketplace__InvalidMessageValue();
        }
        // Check if auction is in progress
        if (block.timestamp > item.endTime && item.endTime > 0) {
            revert AvalaunchNFTMarketplace__AuctionEnded();
        }
        // Check msg sender is not seller
        if (item.seller == msg.sender) {
            revert AvalaunchNFTMarketplace__InvalidCaller();
        }
        // Return funds to the previous bidder
        if (item.highestBid > 0) {
            uint256 highestBid = item.highestBid;
            item.highestBid = 0;
            safeFundTransfer(item.bidder, highestBid);
        }
        // Set values
        item.bidder = payable(msg.sender);
        item.highestBid = msg.value;
        item.endTime = block.timestamp + item.timeExtensionPerBid;
        // Emit an event
        emit NewHighestBid(_itemId, msg.sender, msg.value);
    }

    /**
     * Function to let users claim items they won on auction
     * @param _itemId - id of auctioned marketplace item
     */
    function claimAuctionItem(uint256 _itemId) external nonReentrant {
        // Retrieve item
        AuctionItem storage item = auctionItems[_itemId];
        // Check if item is available
        if (!item.available) {
            revert AvalaunchNFTMarketplace__ItemUnavailable();
        }
        // Check if auction is in progress
        if (block.timestamp < item.endTime || item.endTime == 0) {
            revert AvalaunchNFTMarketplace__AuctionInProgress();
        }
        // Check msg sender is highest bidder
        if (msg.sender != item.bidder) {
            revert AvalaunchNFTMarketplace__InvalidCaller();
        }
        // Mark item as unavailable
        item.available = false;
        // Calculate fee
        uint256 fee = applyFees(item.highestBid);
        // Increase balance of the seller
        userFunds[item.seller] += item.highestBid - fee;
        // Transfer item to the buyer
        IERC721Upgradeable(item.itemAddress).transferFrom(address(this), item.bidder, item.tokenId);
        // Emit an event
        emit AuctionedItemClaimed(_itemId, msg.sender);
    }

    /**
     * @notice Function for users to withdraw their marketplace earnings
     */
    function withdrawUserFunds() external nonReentrant {
        uint256 amount = userFunds[msg.sender];
        delete userFunds[msg.sender];
        safeFundTransfer(msg.sender, amount);
    }

    /**
     * Function to compute fees
     * @param amount - amount to apply fees to
     * @return fee - taken fee
     */
    function applyFees(uint256 amount) private returns (uint256 fee) {
        // Calculate fee
        fee = (amount * feePercent) / feePrecision;
        // Increase amount of accumulated fees
        fees += fee;
    }

    /**
     * @notice Function to safely transfer AVAX
     * @param _to - address to receive funds
     * @param _amount - amount of funds to be sent
     */
    function safeFundTransfer(address _to, uint256 _amount) private {
        if (_amount == 0) revert AvalaunchNFTMarketplace__InvalidAmount();
        (bool success, ) = _to.call{value: _amount}("");
        if (!success) {
            revert AvalaunchNFT__AVAXTransferFailed();
        }
    }

    /**
     * @notice Function to withdraw fees by owner
     * @param receiver - address which receives funds
     */
    function withdrawFees(address receiver) external onlyOwner {
        // Gas optimization
        uint256 _fees = fees;
        // Check balance
        if (_fees == 0) {
            revert AvalaunchNFTMarketplace__NoFees();
        }
        // Check receiver
        if (receiver == address(0)) {
            revert AvalaunchNFTMarketplace__InvalidAddress();
        }
        // Increase amount of withdrawn fees
        withdrawnFees += _fees;
        // Reset fee value to zero
        fees = 0;
        // Transfer funds
        safeFundTransfer(receiver, _fees);
        // Emit event
        emit FeesWithdrawn(receiver, _fees);
    }

    /**
     * @notice Function to get value of all fees accumulated ever
     */
    function getTotalAccumulatedFees() external view returns (uint256) {
        return fees + withdrawnFees;
    }
}
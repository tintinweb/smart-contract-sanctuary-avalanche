/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-10
*/

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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

// File: contracts/interfaces/ITheProperty.sol


pragma solidity ^0.8.0;



interface ITheProperty is IERC721Enumerable, IERC721Metadata {
    // Struct to store any precesion values along with their previous values.
    struct precesionValues {
        uint256[] values;
        uint256[] timestamps;
    }

    // Struct to store property type.
    struct propertyType {
        string name; // name of property type
        uint256 price; // Price of the proerty in NEIBR
        precesionValues dailyRewards; // Daily rewards updated over time.
        uint256 maxDailyReward; // Max daily reward that an property can reach
        uint256 monthlyRent; // Monthly rent that user have to pay(proerty tax)
        uint256 minSellReward; // minimum daily reward required to sell(transfer) the property
        string propertyURI; // Method to store the URI of this property type
    }

    function propertyTypes(uint256 index)
        external
        view
        returns (propertyType memory);

    function doesPropertyTypeExists(uint256 _propertyTypeIndex)
        external
        view
        returns (bool);

    struct property {
        string name; //Name of property
        uint256 propertyTypeIndex; // Property type index.
        uint256 createdOn; // Timestamp when Propery was created.
        precesionValues furnitureIndices; // Furniture indices and allocation times.
        uint256 lastRentDeposited; // Time then the last rent was deposted.
        uint256 lastRewardCalculated; // Timestamp when the reward was calculated.
        uint256 unclaimedDetachedReward; // Unclaimed reward that have no record in contract.
        bool reachedMinRewardInTime; // Bool to check if minReward was reached in specified time.
    }

    function properties(uint256 index) external view returns (property memory);

    // Method to check if the rent is cleared.
    function isRentCleared(uint256 tokenId) external view returns (bool);

    // Method to check if proerty is locked due to insufficient rent payment.
    function isPropertyLocked(uint256 tokenId) external view returns (bool);

    // Method to be used for presale Minting.
    function presaleMint(
        uint256 _propertyTypeIndex,
        string memory _name,
        string memory _tokenURI,
        address _tokenOwner
    ) external;

    function calculateReward(uint256 tokenId)
        external
        view
        returns (uint256, uint256);

    // Method to buy furniture by property's reward.
    function payByReward(
        uint256[] memory tokenIds,
        address owner,
        uint256 amount
    ) external returns (bool, string memory);
}

// File: contracts/utils/AddressArray.sol


pragma solidity ^0.8.0;

// library for address array 
library AddressArray {
    using AddressArray for addresses;

    struct addresses {
        address[] array;
    }

    function add(addresses storage self, address _address)
        internal
    {
        if(! exists(self, _address)){
            self.array.push(_address);
        }
    }

    function getIndexByAddress(
        addresses storage self,
        address _address
    ) internal view returns (uint, bool) {
        uint index;
        bool exists_;

        for (uint i = 0; i < self.array.length; i++) {
            if (self.array[i] == _address) {
                index = i;
                exists_ = true;

                break;
            }
        }
        return (index, exists_);
    }

    function remove(
        addresses storage self,
        address _address
    ) internal {
       for (uint i = 0; i < self.array.length; i++) {
            if (
                self.array[i] == _address 
            ) {
                self.array[i] = self.array[self.array.length - 1];
                self.array.pop();
            }
        }
    }


    function exists(
        addresses storage self,
        address _address
    ) internal view returns (bool) {
        for (uint i = 0; i < self.array.length; i++) {
            if (
                self.array[i] == _address 
            ) {
                return true;
            }
        }
        return false;
    }
}
// File: contracts/utils/TokenDetArray.sol


pragma solidity ^0.8.0;

// librray for TokenDets
library TokenDetArray {
    // Using for array of strcutres for storing mintable address and token id
    using TokenDetArray for TokenDets;

    struct TokenDet {
        address NFTAddress;
        uint256 tokenId;
    }

    // custom type array TokenDets
    struct TokenDets {
        TokenDet[] array;
    }

    function add(TokenDets storage self, TokenDet memory _tokenDet) internal {
        if (!self.exists(_tokenDet)) {
            self.array.push(_tokenDet);
        }
    }

    function getIndexByTokenDet(
        TokenDets storage self,
        TokenDet memory _tokenDet
    ) internal view returns (uint256, bool) {
        uint256 index;
        bool tokenExists = false;
        for (uint256 i = 0; i < self.array.length; i++) {
            if (
                self.array[i].NFTAddress == _tokenDet.NFTAddress &&
                self.array[i].tokenId == _tokenDet.tokenId
            ) {
                index = i;
                tokenExists = true;
                break;
            }
        }
        return (index, tokenExists);
    }

    function remove(TokenDets storage self, TokenDet memory _tokenDet)
        internal
        returns (bool)
    {
        (uint256 i, bool tokenExists) = self.getIndexByTokenDet(_tokenDet);
        if (tokenExists == true) {
            self.array[i] = self.array[self.array.length - 1];
            self.array.pop();
            return true;
        }
        return false;
    }

    function exists(TokenDets storage self, TokenDet memory _tokenDet)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < self.array.length; i++) {
            if (
                self.array[i].NFTAddress == _tokenDet.NFTAddress &&
                self.array[i].tokenId == _tokenDet.tokenId
            ) {
                return true;
            }
        }
        return false;
    }
}
// File: @openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol


// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// File: @openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol


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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

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

// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol


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

// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: @openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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

// File: @openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;



/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal onlyInitializing {
    }

    function __ERC721Holder_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// File: contracts/Marketplace.sol


pragma solidity ^0.8.0;









contract MarketPlace is
    Initializable,
    ERC721HolderUpgradeable,
    OwnableUpgradeable
{
    // Storage
    using TokenDetArray for TokenDetArray.TokenDets;
    using AddressArray for AddressArray.addresses;

    ///////////////////////////////////////////////////////////////////////////
    // declare all storage at once to handle storage clashes.
    ///////////////////////////////////////////////////////////////////////////

    mapping(address => uint256) public brokerage;
    mapping(address => TokenDetArray.TokenDets) tokensForSalePerUser;
    TokenDetArray.TokenDets fixedPriceTokens;
    TokenDetArray.TokenDets auctionTokens;

    struct auction {
        address payable seller;
        uint256 currentBid;
        address payable highestBidder;
        uint256 auctionType;
        uint256 startingPrice;
        uint256 startingTime;
        uint256 closingTime;
        address erc20Token;
    }

    mapping(address => mapping(uint256 => auction)) public auctions;

    TokenDetArray.TokenDets tokensForSale;
    AddressArray.addresses erc20TokensArray;

    mapping(address => uint256) brokerageBalance;

    uint256 public decimalPrecision;

    ///////////////////////////////////////////////////////////////////////////
    // Storage declaraion End
    ///////////////////////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////////////////////
    // Event declraion.
    ///////////////////////////////////////////////////////////////////////////

    event Bid(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        address bidder,
        uint256 amouont,
        uint256 time,
        address ERC20Address
    );
    event Sold(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        address buyer,
        uint256 amount,
        address collector,
        uint256 auctionType,
        uint256 time,
        address ERC20Address
    );
    event OnSale(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 auctionType,
        uint256 amount,
        uint256 time,
        address ERC20Address
    );
    event PriceUpdated(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 auctionType,
        uint256 oldAmount,
        uint256 amount,
        uint256 time,
        address ERC20Address
    );
    event OffSale(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 time,
        address ERC20Address
    );

    ///////////////////////////////////////////////////////////////////////////
    // Event declration end.
    ///////////////////////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////////////////////
    // Modifiers
    ///////////////////////////////////////////////////////////////////////////

    modifier erc20Allowed(address _erc20Token) {
        if (_erc20Token != address(0)) {
            require(erc20TokensArray.exists(_erc20Token), "ERC20 not allowed");
        }
        _;
    }

    modifier onSaleOnly(uint256 _tokenId, address _mintableToken) {
        require(
            auctions[_mintableToken][_tokenId].seller != address(0),
            "Token Not For Sale"
        );
        _;
    }

    modifier activeAuction(uint256 _tokenId, address _mintableToken) {
        require(
            block.timestamp < auctions[_mintableToken][_tokenId].closingTime,
            "Auction Time Over!"
        );
        _;
    }

    modifier auctionOnly(uint256 _tokenId, address _mintableToken) {
        require(
            auctions[_mintableToken][_tokenId].auctionType != 1,
            "Auction Not For Bid"
        );
        _;
    }

    modifier flatSaleOnly(uint256 _tokenId, address _mintableToken) {
        require(
            auctions[_mintableToken][_tokenId].auctionType != 2,
            "Auction for Bid only!"
        );
        _;
    }

    modifier tokenOwnerOnly(uint256 _tokenId, address _mintableToken) {
        // Sender will be owner only if no have bidded on auction.
        require(
            ITheProperty(_mintableToken).ownerOf(_tokenId) == msg.sender,
            "You must be owner and Token should not have any bid"
        );
        _;
    }

    ///////////////////////////////////////////////////////////////////////////
    // Modifier declration end.
    ///////////////////////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////////////////////
    // Getters
    ///////////////////////////////////////////////////////////////////////////

    function getErc20Tokens() public view returns (address[] memory) {
        return erc20TokensArray.array;
    }

    function getTokensForSale()
        public
        view
        returns (TokenDetArray.TokenDet[] memory)
    {
        return tokensForSale.array;
    }

    function getFixedPriceTokensForSale()
        public
        view
        returns (TokenDetArray.TokenDet[] memory)
    {
        return fixedPriceTokens.array;
    }

    function getAuctionTokensForSale()
        public
        view
        returns (TokenDetArray.TokenDet[] memory)
    {
        return auctionTokens.array;
    }

    function getTokensForSalePerUser(address _user)
        public
        view
        returns (TokenDetArray.TokenDet[] memory)
    {
        return tokensForSalePerUser[_user].array;
    }

    ///////////////////////////////////////////////////////////////////////////
    // Getters declration end.
    ///////////////////////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////////////////////
    // Admin updates.
    ///////////////////////////////////////////////////////////////////////////

    function addERC20TokenPayment(address _erc20Token, uint256 _brokerage)
        public
        onlyOwner
    {
        erc20TokensArray.add(_erc20Token);
        brokerage[_erc20Token] = _brokerage;
    }

    function updateBrokerage(address _erc20Token, uint256 _brokerage)
        public
        onlyOwner
    {
        brokerage[_erc20Token] = _brokerage;
    }

    function removeERC20TokenPayment(address _erc20Token)
        public
        erc20Allowed(_erc20Token)
        onlyOwner
    {
        erc20TokensArray.remove(_erc20Token);
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(brokerageBalance[address(0)]);
        brokerageBalance[address(0)] = 0;
    }

    function withdrawERC20(address _erc20Token) public onlyOwner {
        require(
            erc20TokensArray.exists(_erc20Token),
            "This erc20token payment not allowed"
        );
        IERC20Upgradeable erc20Token = IERC20Upgradeable(_erc20Token);
        erc20Token.transfer(msg.sender, brokerageBalance[_erc20Token]);
        brokerageBalance[_erc20Token] = 0;
    }

    ///////////////////////////////////////////////////////////////////////////
    // Admin updates end
    ///////////////////////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////////////////////
    // Marketplace functions
    ///////////////////////////////////////////////////////////////////////////

    function bid(
        uint256 _tokenId,
        address _mintableToken,
        uint256 amount
    )
        public
        payable
        onSaleOnly(_tokenId, _mintableToken)
        activeAuction(_tokenId, _mintableToken)
    {
        ITheProperty Token = ITheProperty(_mintableToken);

        auction memory _auction = auctions[_mintableToken][_tokenId];

        if (_auction.erc20Token == address(0)) {
            require(
                msg.value > _auction.currentBid,
                "Insufficient bidding amount."
            );

            if (_auction.highestBidder != address(0)) {
                _auction.highestBidder.transfer(_auction.currentBid);
            }
        } else {
            IERC20Upgradeable erc20Token = IERC20Upgradeable(
                _auction.erc20Token
            );
            require(
                erc20Token.allowance(msg.sender, address(this)) >= amount,
                "Allowance is less than amount sent for bidding."
            );
            require(
                amount > _auction.currentBid,
                "Insufficient bidding amount."
            );
            erc20Token.transferFrom(msg.sender, address(this), amount);

            if (_auction.highestBidder != address(0)) {
                erc20Token.transfer(
                    _auction.highestBidder,
                    _auction.currentBid
                );
            }
        }

        _auction.currentBid = _auction.erc20Token == address(0)
            ? msg.value
            : amount;

        Token.safeTransferFrom(Token.ownerOf(_tokenId), address(this), _tokenId);
        _auction.highestBidder = payable(msg.sender);

        auctions[_mintableToken][_tokenId] = _auction;

        // Bid event
        emit Bid(
            _mintableToken,
            _tokenId,
            _auction.seller,
            _auction.highestBidder,
            _auction.currentBid,
            block.timestamp,
            _auction.erc20Token
        );
    }

    // Collect Function are use to collect funds and NFT from Broker
    function collect(uint256 _tokenId, address _mintableToken) public {
        ITheProperty Token = ITheProperty(_mintableToken);
        auction memory _auction = auctions[_mintableToken][_tokenId];
        TokenDetArray.TokenDet memory _tokenDet = TokenDetArray.TokenDet(
            _mintableToken,
            _tokenId
        );
        if (msg.sender != _auction.seller) {
            require(
                block.timestamp > _auction.closingTime,
                "Auction Not Over!"
            );
        }

        if (_auction.highestBidder != address(0)) {
            uint256 brokerageAmount = (_auction.currentBid *
                brokerage[_auction.erc20Token]) / (100 * decimalPrecision);
            if (_auction.erc20Token == address(0)) {
                _auction.seller.transfer(_auction.currentBid - brokerageAmount);
            } else {
                IERC20Upgradeable erc20Token = IERC20Upgradeable(
                    _auction.erc20Token
                );

                erc20Token.transfer(
                    _auction.seller,
                    _auction.currentBid - brokerageAmount
                );
            }
            brokerageBalance[_auction.erc20Token] += brokerageAmount;
            Token.safeTransferFrom(
                Token.ownerOf(_tokenId),
                _auction.highestBidder,
                _tokenId
            );

            // Sold event
            emit Sold(
                _tokenDet.NFTAddress,
                _tokenDet.tokenId,
                _auction.seller,
                _auction.highestBidder,
                _auction.currentBid,
                msg.sender,
                _auction.auctionType,
                block.timestamp,
                _auction.erc20Token
            );
        }

        tokensForSale.remove(_tokenDet);

        tokensForSalePerUser[_auction.seller].remove(_tokenDet);
        auctionTokens.remove(_tokenDet);
        delete auctions[_mintableToken][_tokenId];
    }

    function buy(uint256 _tokenId, address _mintableToken)
        public
        payable
        onSaleOnly(_tokenId, _mintableToken)
        flatSaleOnly(_tokenId, _mintableToken)
    {
        ITheProperty Token = ITheProperty(_mintableToken);
        auction memory _auction = auctions[_mintableToken][_tokenId];
        TokenDetArray.TokenDet memory _tokenDet = TokenDetArray.TokenDet(
            _mintableToken,
            _tokenId
        );

        uint256 brokerageAmount = (brokerage[_auction.erc20Token] *
            _auction.startingPrice) / (100 * decimalPrecision);

        if (_auction.erc20Token == address(0)) {
            require(
                msg.value >= _auction.startingPrice,
                "Insufficient Payment"
            );
            _auction.seller.transfer(_auction.startingPrice - brokerageAmount);
        } else {
            IERC20Upgradeable erc20Token = IERC20Upgradeable(
                _auction.erc20Token
            );
            require(
                erc20Token.allowance(msg.sender, address(this)) >=
                    _auction.startingPrice,
                "Insufficient spent allowance "
            );

            // transfer brokerage amount to broker
            erc20Token.transferFrom(msg.sender, address(this), brokerageAmount);
            // transfer remaining  amount to seller
            erc20Token.transferFrom(
                msg.sender,
                _auction.seller,
                _auction.startingPrice - brokerageAmount
            );
        }
        brokerageBalance[_auction.erc20Token] += brokerageAmount;

        Token.safeTransferFrom(
            Token.ownerOf(_tokenDet.tokenId),
            msg.sender,
            _tokenDet.tokenId
        );

        // Buy event
        emit Sold(
            _tokenDet.NFTAddress,
            _tokenDet.tokenId,
            _auction.seller,
            msg.sender,
            _auction.startingPrice,
            msg.sender,
            _auction.auctionType,
            block.timestamp,
            _auction.erc20Token
        );

        tokensForSale.remove(_tokenDet);
        tokensForSalePerUser[_auction.seller].remove(_tokenDet);

        fixedPriceTokens.remove(_tokenDet);
        delete auctions[_tokenDet.NFTAddress][_tokenDet.tokenId];
    }

    function putOnSale(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _auctionType,
        uint256 _startingTime,
        uint256 _endindTime,
        address _mintableToken,
        address _erc20Token
    )
        public
        erc20Allowed(_erc20Token)
        tokenOwnerOnly(_tokenId, _mintableToken)
    {
        {
            ITheProperty Token = ITheProperty(_mintableToken);

            require(
                Token.getApproved(_tokenId) == address(this) ||
                    Token.isApprovedForAll(msg.sender, address(this)),
                "Broker Not approved"
            );
        }
        auction memory _auction = auctions[_mintableToken][_tokenId];

        // Allow to put on sale to already on sale NFT \
        // only if it was on auction and have 0 bids and auction is over
        if (auctions[_mintableToken][_tokenId].seller != address(0)) {
            require(
                _auction.auctionType == 2 &&
                    _auction.highestBidder == address(0) &&
                    block.timestamp > _auction.closingTime,
                "This NFT is already on sale."
            );
        }

        auction memory newAuction = auction(
            payable(msg.sender),
            _startingPrice,
            payable(address(0)),
            _auctionType,
            _startingPrice,
            _startingTime,
            _endindTime,
            _erc20Token
        );
        auctions[_mintableToken][_tokenId] = newAuction;
        TokenDetArray.TokenDet memory _tokenDet = TokenDetArray.TokenDet(
            _mintableToken,
            _tokenId
        );

        // Store data in all mappings if adding fresh token on sale
        if (
            auctions[_mintableToken][_tokenId].seller != address(0)
        ) {
            
            tokensForSale.add(_tokenDet);
            tokensForSalePerUser[msg.sender].add(_tokenDet);

            // Add token to fixedPrice on Timed list
            if (_auctionType == 1) {
                fixedPriceTokens.add(_tokenDet);
            } else if (_auctionType == 2) {
                auctionTokens.add(_tokenDet);
            }
        }

        // OnSale event
        emit OnSale(
            _tokenDet.NFTAddress,
            _tokenDet.tokenId,
            msg.sender,
            _auctionType,
            newAuction.startingPrice,
            block.timestamp,
            newAuction.erc20Token
        );
    }

    function updatePrice(
        uint256 _tokenId,
        address _mintableToken,
        uint256 _newPrice,
        address _erc20Token
    )
        public
        onSaleOnly(_tokenId, _mintableToken)
        erc20Allowed(_erc20Token)
        tokenOwnerOnly(_tokenId, _mintableToken)
    {
        auction memory _auction = auctions[_mintableToken][_tokenId];

        if (_auction.auctionType == 2) {
            require(
                block.timestamp < _auction.closingTime,
                "Auction Time Over!"
            );
        }
        emit PriceUpdated(
            _mintableToken,
            _tokenId,
            _auction.seller,
            _auction.auctionType,
            _auction.startingPrice,
            _newPrice,
            block.timestamp,
            _auction.erc20Token
        );
        // Update Price
        _auction.startingPrice = _newPrice;
        if (_auction.auctionType == 2) {
            _auction.currentBid = _newPrice;
        }
        _auction.erc20Token = _erc20Token;
        auctions[_mintableToken][_tokenId] = _auction;
    }

    function putSaleOff(uint256 _tokenId, address _mintableToken)
        public
        tokenOwnerOnly(_tokenId, _mintableToken)
    {
        auction memory _auction = auctions[_mintableToken][_tokenId];
        TokenDetArray.TokenDet memory _tokenDet = TokenDetArray.TokenDet(
            _mintableToken,
            _tokenId
        );
        
        // OffSale event
        emit OffSale(
            _mintableToken,
            _tokenId,
            msg.sender,
            block.timestamp,
            _auction.erc20Token
        );

        tokensForSale.remove(_tokenDet);

        tokensForSalePerUser[msg.sender].remove(_tokenDet);
        // Remove token from list
        if (_auction.auctionType == 1) {
            fixedPriceTokens.remove(_tokenDet);
        } else if (_auction.auctionType == 2) {
            auctionTokens.remove(_tokenDet);
        }
        delete auctions[_mintableToken][_tokenId];
    }

    function getOnSaleStatus(address _mintableToken, uint256 _tokenId)
        public
        view
        returns (bool)
    {
        return auctions[_mintableToken][_tokenId].seller != address(0);
    }

    ///////////////////////////////////////////////////////////////////////////
    // MarketPleace
    ///////////////////////////////////////////////////////////////////////////

    function initialize() public initializer {
        __Ownable_init();
        decimalPrecision = 100000;
    }
}
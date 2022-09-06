/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-06
*/

// Sources flattened with hardhat v2.10.2 https://hardhat.org

// File @openzeppelin/contracts/token/ERC721/[email protected]

// SPDX-License-Identifier: MIT
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


// File @openzeppelin/contracts/utils/introspection/[email protected]


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


// File @openzeppelin/contracts/token/ERC721/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]


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


// File @openzeppelin/contracts/utils/[email protected]


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


// File contracts/Manageable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there are several accounts (managers) that can be granted exclusive access to
 * specific functions.
 *
 * By default the deployer of the contract will be added as the first manager.
 * 
 * This module is used through inheritance. It will make available the modifier
 * `onlyManagers`, which can be applied to your functions to restrict their use to
 * the managers.
 */
abstract contract Manageable is Context {
    mapping (address => bool) public managers;

    event ManagersAdded(address[] indexed newManagers);
    event ManagersRemoved(address[] indexed oldManagers);

    /**
     * @dev Initializes the contract setting the deployer as the initial manager.
     */
    constructor() {
        managers[_msgSender()] = true;
    }

    /**
     * @dev Throws if called by any account other than the managers.
     */
    modifier onlyManagers() {
        _checkManager();
        _;
    }

    /**
     * @dev Throws if the sender is not a manager.
     */
    function _checkManager() internal view virtual {
        require(managers[_msgSender()], "Manageable: caller is not a manager");
    }

    /**
     * @dev Adds manager role to new accounts (`newManagers`).
     * Can only be called by a current manager.
     */
    function addManagers(address[] memory newManagers) public virtual onlyManagers {
        _addManagers(newManagers);
    }

    /**
     * @dev Remove manager role from old accounts (`oldManagers`).
     * Can only be called by a current manager.
     */
    function removeManagers(address[] memory oldManagers) public virtual onlyManagers {
        _removeManagers(oldManagers);
    }

    /**
     * @dev Adds new managers of the contract (`newManagers`).
     * Internal function without access restriction.
     */
    function _addManagers(address[] memory newManagers) internal virtual {
        _setManagersState(newManagers, true);

        emit ManagersAdded(newManagers);
    }

    /**
     * @dev Removes old managers of the contract (`oldManagers`).
     * Internal function without access restriction.
     */
    function _removeManagers(address[] memory oldManagers) internal virtual {
        _setManagersState(oldManagers, false);

        emit ManagersRemoved(oldManagers);
    }

    /**
     * @dev Changes managers of the contract state (`setManagers`).
     * Internal function without access restriction.
     */
    function _setManagersState(address[] memory setManagers, bool newState) internal virtual {
        for (uint i = 0; i < setManagers.length; i++) {
            managers[setManagers[i]] = newState;
        }
    }
}


// File contracts/ParticleHolder.sol


pragma solidity ^0.8.9;



/// @title Particle Holder
/// @notice Particle holder contract for NFTs on Avalanche that should be bridged to Ethereum
/// @dev Using IERC721Enumerable from OpenZeppelin for ERC-721 contract interactions as this was used in the original contract
contract ParticleHolder is Manageable {
    IERC721Enumerable public tokenContract;

    /// @dev Event emmited by successfully calling 'getParticlesFrom' function, after token transfer to this contract
    event TokensTransfered(address holder, uint balance, uint256[] ids);

    /// @dev Contract constructor that sets the managers and original token contract
	/// @param _managers Approved addresses to execute the 'getParticlesFrom' function
	/// @param _tokenContract The original token contract
    constructor (address[] memory _managers, address _tokenContract) {
        tokenContract = IERC721Enumerable(_tokenContract);
        // It is not possible to cast between fixed size arrays and dynamic size arrays, so we need to create a new dynamic sized one
        address[] memory newManagers = _managers;
        _addManagers(newManagers);
    }

    /// @dev Necessary to be able to receive ERC-721 tokens through 'safeTransferFrom' function in the original contract
    function onERC721Received(address, address, uint256, bytes calldata) public pure returns(bytes4) {
		return this.onERC721Received.selector;
	}

    /// @dev Transfer tokens from supplied address to this contract
    /// @dev Checks for sender to be an approved manager and for the contract to be approved for all tokens
	/// @param wallets User's addresses to retrieve particles from
    function getParticlesFrom(address[] calldata wallets) public onlyManagers {
        for (uint i = 0; i < wallets.length; i++) {
            address wallet = wallets[i];

            require(tokenContract.isApprovedForAll(wallet, address(this)), "ParticleHolder: Contract not approved for all tokens for this wallet");
            uint balance = tokenContract.balanceOf(wallet);
            uint256[] memory ids = new uint256[](balance);

            for (uint j = 0; j < balance; j++) {
                // Always get token at index 0, as safeTransferFrom alters the user's balance and token index in every call
                uint256 tokenId = tokenContract.tokenOfOwnerByIndex(wallet, 0);
                tokenContract.safeTransferFrom(wallet, address(this), tokenId);
                ids[j] = tokenId;
            }

            emit TokensTransfered(wallet, balance, ids);
        }
    }
}
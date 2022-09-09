/**
 *Submitted for verification at snowtrace.io on 2022-09-09
*/

// SPDX-License-Identifier: MIT

// Sources flattened with hardhat v2.10.2 https://hardhat.org

// File @avvy/contracts/[email protected]

pragma solidity ^0.8.0;

interface ContractRegistryInterface {
  function get(string memory contractName) external view returns (address);
}


// File @avvy/contracts/[email protected]

pragma solidity ^0.8.0;

interface RainbowTableInterface {
  function reveal(uint256[] memory preimage, uint256 hash) external;
  function lookup(uint256 hash) external returns (uint256[] memory preimage);
  function getHash(uint256 hash, uint256[] calldata preimage) external view returns (uint256);
  function isRevealed(uint256 hash) external view returns (bool);
}


// File @avvy/contracts/[email protected]

pragma solidity ^0.8.0;

interface ResolverInterface {
  event StandardEntrySet(uint256 indexed datasetId, uint256 indexed hash, uint256[] path, uint256 key, string data);
  event EntrySet(uint256 indexed datasetId, uint256 indexed hash, uint256[] path, string key, string data);
  function resolveStandard(uint256 datasetId, uint256 hash, uint256 key) external returns (string memory data);
  function resolve(uint256 datasetId, uint256 hash, string memory key) external returns (string memory data);
}


// File @avvy/contracts/[email protected]

pragma solidity ^0.8.0;

interface ReverseResolverAuthenticatorInterface {
  function canWrite(uint256 name, uint256[] memory path, address sender) external view returns (bool);
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


// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}


// File contracts/NameResolver.sol

pragma solidity ^0.8.9;





contract NameResolver is ResolverInterface, ReverseResolverAuthenticatorInterface {
  IERC721 _nft;
  ContractRegistryInterface _contractRegistry;

  mapping(uint256 => address) owners;
  mapping(address => uint256) ownersReverse;
  mapping(uint256 => mapping(uint256 => string)) standardEntries;
  mapping(uint256 => mapping(string => string)) entries;

  constructor(IERC721 nft, ContractRegistryInterface contractRegistry) {
    _nft = nft;
    _contractRegistry = contractRegistry;
  }

  function _verifyOwner(address owner) internal view {
    require(_nft.balanceOf(owner) > 0, "Must be owner");
  }

  function _addressToString(address addy) internal pure returns (string memory) {
    return Strings.toHexString(uint160(addy), 20);
  }

  /*
    Claim
    =====

    ** This is custom functionality. Other resolver implementations 
       do not need to follow this.

    We allow any holder of the NFT to claim a single name for their
    wallet address. Names are represented by their hash.

    For example, if a user claims myname.nftproject.avax then
    myname.nftproject.avax will forward resolve into the sender's
    0x address.

    ** This does not enable reverse resolution (i.e. going from 
       0x address to .avax address).
  */
  function claimName(uint256[] memory preimage, uint256 name) external {
    
    // verify sender is owner
    _verifyOwner(msg.sender);

    // if the name is already taken, don't allocate
    require(owners[name] == address(0), "Name is already owned");

    // save the plaintext of the name (assuming this is desired)
    RainbowTableInterface rainbowTable = RainbowTableInterface(_contractRegistry.get('RainbowTable'));
    if (!rainbowTable.isRevealed(name)) {
      rainbowTable.reveal(preimage, name);
    }

    // each address can only claim one name
    if (ownersReverse[msg.sender] != 0) {
      owners[ownersReverse[msg.sender]] = address(0);
      _clear(ownersReverse[msg.sender]);
    }

    // allocate the name
    uint256[] memory path = new uint256[](0);
    owners[name] = msg.sender;
    ownersReverse[msg.sender] = name;
    emit StandardEntrySet(
      0, // datasetId not used
      name, // hash of the name
      path, // path var not used
      3, // setting EVM address
      _addressToString(msg.sender) // setting to msg.sender
    );
  }

  /*
    Get Name
    ========

    ** This is custom functionality. Other resolver implementations 
       do not need to follow this.

    This simply returns the name that a user has claimed on the resolver.
  */
  function getName(address addy) external view returns (uint256 name) {
    name = ownersReverse[addy];
    require(name != 0, "Address has not claimed name");
    _verifyOwner(addy);
  }

  /*
    Is Owned
    ========

    ** This is custom functionality. Other resolver implementations 
       do not need to follow this.

    This simply checks to see if the given name has been registered.
  */
  function isOwned(uint256 name) external view returns (bool) {
    return owners[name] != address(0);
  }

  /*
    Clear
    =====

    ** This is custom functionality. Other resolver implementations 
       do not need to follow this.

    If the owner of a name no longer holds an NFT from the collection
    any user can clear their name.
  */
  function clear(uint256 name) external {
    require(_nft.balanceOf(owners[name]) == 0, "Owner still holds token");
    _clear(name);
  }

  function _clear(uint256 name) internal {
    uint256[] memory path = new uint256[](0);

    // clear the previously used name
    emit StandardEntrySet(
      0, // datasetId not used
      name, // hash of the name
      path, // path var not used
      3, // setting EVM address
      '' // clear the name
    );
    ownersReverse[msg.sender] = 0;
  }

  /*
    Resolution Methods
    ==================

    resolve() and resolveStandard() are overrides for ResolverInterface. 
    These methods are used when transforming a .avax name into a 
    value like an 0x address.
  */

  function resolveStandard(uint256 /*datasetId*/, uint256 hash, uint256 key) external view returns (string memory data) {
    if (key == 3) { // EVM address
      address owner = owners[hash];
      if (owner != address(0)) {
        
        // verify ownership again.
        _verifyOwner(owner);
        return _addressToString(owner);
      }
    }
  }
  
  function resolve(uint256 datasetId, uint256 hash, string memory key) external returns (string memory data) {}

  /*
    Reverse Resolution Methods
    ==========================

    canWrite() is an override for ReverseResolverAuthenticatorInterface.
    This method is used when setting the reverse record for a name.
    The reverse record is used when transforming an 0x address into 
    a .avax name,for use-cases such as displaying the .avax name in the UI when a 
    user connects to a dapp.
  */
  function canWrite(uint256 name, uint256[] memory /* path */, address sender) external view returns (bool) {
    return owners[name] == sender;
  }
}
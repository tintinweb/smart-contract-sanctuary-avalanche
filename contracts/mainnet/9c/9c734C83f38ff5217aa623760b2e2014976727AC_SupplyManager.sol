// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ISpaceFarmer.sol";

contract SupplyManager is Ownable {
  uint256 private constant GEN0_MUTANT_COUNT = 9000;
  uint256 private constant GEN0_SPACE_FARMER_COUNT = 1000;
  uint256 private constant GEN1_MUTANT_COUNT = 45000;
  uint256 private constant GEN1_SPACE_FARMER_COUNT = 5000;
  uint256 private constant SUPER_MUTANT_COUNT = 1000;

  address public spaceFarmer;

  mapping(uint256 => uint256) private movedIds;
  // Mint phase => Hero => supply left
  mapping(MintPhase => mapping(Hero => uint256)) private supplyLeft;

  constructor() {
    supplyLeft[MintPhase.Gen0][Hero.Mutant] = GEN0_MUTANT_COUNT;
    supplyLeft[MintPhase.Gen0][Hero.SpaceFarmer] = GEN0_SPACE_FARMER_COUNT;
    supplyLeft[MintPhase.Gen0SuperMutant][
      Hero.SuperMutant
    ] = SUPER_MUTANT_COUNT;
    supplyLeft[MintPhase.Gen1][Hero.Mutant] = GEN1_MUTANT_COUNT;
    supplyLeft[MintPhase.Gen1][Hero.SpaceFarmer] = GEN1_SPACE_FARMER_COUNT;
    supplyLeft[MintPhase.Gen1][Hero.SuperMutant] = SUPER_MUTANT_COUNT;
  }

  function generateTokenId(
    uint256 randomNumber,
    MintPhase mintPhase,
    Hero hero
  ) external returns (uint256 tokenId) {
    // Only the Space Farmer contract can alter the state of this contract
    require(_msgSender() == spaceFarmer, "Not allowed");
    // The generation logic is different for Gen1 and Gen0
    if (mintPhase == MintPhase.Gen1) {
      tokenId = _generateGen1TokenId(randomNumber, hero);
    } else {
      tokenId = _generateGen0TokenId(randomNumber, mintPhase);
    }
  }

  function _generateGen0TokenId(uint256 randomNumber, MintPhase mintPhase)
    private
    returns (uint256)
  {
    // Only for Gen0 and Gen0SuperMutant
    require(mintPhase != MintPhase.Gen1, "Wrong mint phase");
    uint256 tokenId;
    if (mintPhase == MintPhase.Gen0) {
      // Check there's enough supply left
      require(
        supplyLeft[MintPhase.Gen0][Hero.SpaceFarmer] > 0 ||
          supplyLeft[MintPhase.Gen0][Hero.Mutant] > 0,
        "No supply left"
      );
      // Generate either a Space Farmer or Mutant between id 1 and 10000 (inclusive)
      tokenId = _generateTokenId(
        randomNumber,
        10000,
        0,
        GEN0_MUTANT_COUNT +
          GEN0_SPACE_FARMER_COUNT -
          (supplyLeft[MintPhase.Gen0][Hero.Mutant] +
            supplyLeft[MintPhase.Gen0][Hero.SpaceFarmer])
      );
      if (tokenId <= 1000) {
        // If below or equal to 1000, then it's an id of a Space Farmer
        // so remove that one from the supply left
        supplyLeft[MintPhase.Gen0][Hero.SpaceFarmer] -= 1;
      } else {
        // Similarly above 1000 and below 10001 it's a Mutant
        supplyLeft[MintPhase.Gen0][Hero.Mutant] -= 1;
      }
    } else if (mintPhase == MintPhase.Gen0SuperMutant) {
      // Check there's enough supply left
      require(
        supplyLeft[MintPhase.Gen0SuperMutant][Hero.SuperMutant] > 0,
        "No supply left"
      );
      // Super Mutant have id between 10001 and 11000 (inclusive)
      tokenId = _generateTokenId(
        randomNumber,
        11000,
        10000,
        SUPER_MUTANT_COUNT -
          supplyLeft[MintPhase.Gen0SuperMutant][Hero.SuperMutant]
      );
      // Update the state accordingly
      supplyLeft[MintPhase.Gen0SuperMutant][Hero.SuperMutant] -= 1;
    }
    require(tokenId > 0, "Unable to generate token id");
    return tokenId;
  }

  function _generateGen1TokenId(uint256 randomNumber, Hero hero)
    private
    returns (uint256)
  {
    // Check there's enough supply left
    require(supplyLeft[MintPhase.Gen1][hero] > 0, "No supply left");
    uint256 tokenId;
    // Mint a specific hero according to the one requested in Gen1
    if (hero == Hero.Mutant) {
      // Mutants are between 11001 and 56000 (inclusive)
      tokenId = _generateTokenId(
        randomNumber,
        56000,
        11000,
        GEN1_MUTANT_COUNT - supplyLeft[MintPhase.Gen1][Hero.Mutant]
      );
    } else if (hero == Hero.SpaceFarmer) {
      // Space Farmers are between 56001 and 61000 (inclusive)
      tokenId = _generateTokenId(
        randomNumber,
        61000,
        56000,
        GEN1_SPACE_FARMER_COUNT - supplyLeft[MintPhase.Gen1][Hero.SpaceFarmer]
      );
    } else if (hero == Hero.SuperMutant) {
      // Super Mutants are between 61001 and 62000 (inclusive)
      tokenId = _generateTokenId(
        randomNumber,
        62000,
        61000,
        SUPER_MUTANT_COUNT - supplyLeft[MintPhase.Gen1][Hero.SuperMutant]
      );
    }
    // Update the supply left according to the hero chosen
    supplyLeft[MintPhase.Gen1][hero] -= 1;
    require(tokenId > 0, "Unable to generate token id");
    return tokenId;
  }

  /**
   * @dev Pick a random token id among the ones still available
   * @param randomNumber Random seed to serve for the generation
   */
  function _generateTokenId(
    uint256 randomNumber,
    uint256 upperBound,
    uint256 lowerBound,
    uint256 supplyMinted
  ) private returns (uint256) {
    // We get the number of ids remaining
    uint256 rangeSize = upperBound - lowerBound - supplyMinted;
    // Keep the randomIndex within the range
    uint256 randomIndex = (randomNumber % rangeSize) + lowerBound;
    // Pick the id at randomIndex within the ids remanining
    uint256 tokenId = getIdAt(randomIndex);

    // Move the last id in the remaining ids in the current range into position randomIndex
    // That way if we get that randomIndex again it will return that number
    movedIds[randomIndex] = getIdAt(rangeSize - 1 + lowerBound);
    // Free the storage used at the last index if used
    delete movedIds[rangeSize - 1 + lowerBound];

    return tokenId;
  }

  function getIdAt(uint256 i) private view returns (uint256) {
    // Return the number stored at index i if it has been defined
    if (movedIds[i] != 0) {
      return movedIds[i];
    } else {
      // Otherwise just return the i + 1 (as it starts at 1)
      return i + 1;
    }
  }

  function getSupplyLeft(MintPhase phase, Hero hero)
    external
    view
    returns (uint256)
  {
    return supplyLeft[phase][hero];
  }

  function setSpaceFarmer(address addr) external onlyOwner {
    require(addr != address(0), "Invalid address");
    spaceFarmer = addr;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT

import "./IShop.sol";

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

enum Hero {
  Mutant,
  SuperMutant,
  SpaceFarmer
}

enum MintPhase {
  Gen0,
  Gen0SuperMutant,
  Gen1
}

interface ISpaceFarmer is IERC721, IERC721Enumerable {
  function mintPhase() external view returns (MintPhase);

  function genericMint(
    uint256 amount,
    bool stake,
    Hero hero,
    address to
  ) external;
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

pragma solidity ^0.8.0;

interface IShop {}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

// SPDX-License-Identifier: MIT
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
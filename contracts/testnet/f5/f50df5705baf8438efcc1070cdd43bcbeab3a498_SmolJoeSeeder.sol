// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";

import {ISmolJoeSeeder} from "./interfaces/ISmolJoeSeeder.sol";
import {ISmolJoeDescriptorMinimal, ISmolJoeArt} from "./interfaces/ISmolJoeDescriptorMinimal.sol";

/**
 * @title The SmolJoes pseudo-random seed generator
 * @notice Based on NounsDAO: https://github.com/nounsDAO/nouns-monorepo
 */
contract SmolJoeSeeder is Ownable2Step, ISmolJoeSeeder {
    uint256 private constant MASK_UINT8 = 0xff;
    uint256 private constant NB_UINT8_IN_UINT256 = 32;
    uint256 private constant RANDOM_SEED_SHIFT = 16;

    // forgefmt: disable-next-item
    uint8[] private _luminariesAvailable = 
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
        20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37,
        38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55,
        56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73,
        74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91,
        92, 93, 94, 95, 96, 97, 98, 99];

    uint256[4] private _originalsArt;

    uint256 private _randomnessNonce;

    /**
     * @notice The Smol Joes contract address
     * @dev Used to check that the caller is the Smol Joes contract when getting a seed
     */
    address public override smolJoes;

    /**
     * @notice Get the art mapping for the original Smol Joes
     * @param tokenId The token ID of the Smol Joe
     * @return The art index corresponding to the token ID
     */
    function getOriginalsArtMapping(uint256 tokenId) external view override returns (uint8) {
        return _getOriginalsArtMapping(tokenId);
    }

    /**
     * @notice Updates the mapping connecting the Originals to their corresponding art
     * @param artMapping The new art mapping
     */
    function updateOriginalsArtMapping(uint8[100] calldata artMapping) external override onlyOwner {
        uint256 packedMapping;
        for (uint256 i = 0; i < artMapping.length; i++) {
            packedMapping += uint256(artMapping[i]) << (i % NB_UINT8_IN_UINT256) * 8;

            if ((i + 1) % NB_UINT8_IN_UINT256 == 0) {
                _originalsArt[i / NB_UINT8_IN_UINT256] = packedMapping;
                packedMapping = 0;
            }
        }

        _originalsArt[3] = packedMapping;

        emit OriginalsArtMappingUpdated(artMapping);
    }

    /**
     * @notice Updates the address of the Smol Joes contract
     * @param _smolJoes The new address of the Smol Joes contract
     */
    function setSmolJoesAddress(address _smolJoes) external override onlyOwner {
        if (_smolJoes == address(0) || _smolJoes == smolJoes) {
            revert SmolJoeSeeder__InvalidAddress();
        }

        smolJoes = _smolJoes;

        emit SmolJoesAddressSet(_smolJoes);
    }

    /**
     * @notice Generate a pseudo-random Smol Joe seed.
     * @param tokenId The token ID of the Smol Joe
     * @param descriptor The Smol Joe descriptor
     * @return The seed for the Smol Joe
     */
    function generateSeed(uint256 tokenId, ISmolJoeDescriptorMinimal descriptor)
        external
        override
        returns (Seed memory)
    {
        if (msg.sender != smolJoes) {
            revert SmolJoeSeeder__OnlySmolJoes();
        }

        uint256 randomNumber = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp, tokenId, _randomnessNonce++))
        );

        // Need to store the seed into memory to prevent stack too deep errors
        Seed memory seed;

        if (tokenId < 100) {
            seed.originalId = _getOriginalsArtMapping(tokenId) + 1;
        } else if (tokenId < 200) {
            uint256 luminariesAvailableLength = _luminariesAvailable.length;

            uint256 randomIndex = randomNumber % luminariesAvailableLength;
            uint256 randomLuminary = _luminariesAvailable[randomIndex];

            seed.luminaryId = uint8(randomLuminary % 10 + 1);
            // Pick the corresponding brotherhood (1-10)
            seed.brotherhood = ISmolJoeArt.Brotherhood(randomLuminary / 10 + 1);

            // Remove the luminary from the available list
            _luminariesAvailable[randomIndex] = _luminariesAvailable[luminariesAvailableLength - 1];
            _luminariesAvailable.pop();
        } else {
            // Get the brotherhood first
            ISmolJoeArt.Brotherhood brotherhood = ISmolJoeArt.Brotherhood(uint8(randomNumber % 10 + 1));
            seed.brotherhood = brotherhood;
            randomNumber >>= 4;

            uint256 backgroundCount = descriptor.traitCount(ISmolJoeArt.TraitType.Background, brotherhood);
            seed.background = uint16(randomNumber % backgroundCount);
            randomNumber >>= RANDOM_SEED_SHIFT;

            uint256 bodyCount = descriptor.traitCount(ISmolJoeArt.TraitType.Body, brotherhood);
            seed.body = uint16(randomNumber % bodyCount);
            randomNumber >>= RANDOM_SEED_SHIFT;

            uint256 pantCount = descriptor.traitCount(ISmolJoeArt.TraitType.Pants, brotherhood);
            seed.pants = uint16(randomNumber % pantCount);
            randomNumber >>= RANDOM_SEED_SHIFT;

            uint256 shoeCount = descriptor.traitCount(ISmolJoeArt.TraitType.Shoes, brotherhood);
            seed.shoes = uint16(randomNumber % shoeCount);
            randomNumber >>= RANDOM_SEED_SHIFT;

            uint256 shirtCount = descriptor.traitCount(ISmolJoeArt.TraitType.Shirt, brotherhood);
            seed.shirt = uint16(randomNumber % shirtCount);
            randomNumber >>= RANDOM_SEED_SHIFT;

            uint256 beardCount = descriptor.traitCount(ISmolJoeArt.TraitType.Beard, brotherhood);
            seed.beard = uint16(randomNumber % beardCount);
            randomNumber >>= RANDOM_SEED_SHIFT;

            uint256 headCount = descriptor.traitCount(ISmolJoeArt.TraitType.HairCapHead, brotherhood);
            seed.hairCapHead = uint16(randomNumber % headCount);
            randomNumber >>= RANDOM_SEED_SHIFT;

            uint256 eyeCount = descriptor.traitCount(ISmolJoeArt.TraitType.EyeAccessory, brotherhood);
            seed.eyeAccessory = uint16(randomNumber % eyeCount);
            randomNumber >>= RANDOM_SEED_SHIFT;

            uint256 accessoryCount = descriptor.traitCount(ISmolJoeArt.TraitType.Accessories, brotherhood);
            seed.accessory = uint16(randomNumber % accessoryCount);
        }

        return seed;
    }

    /**
     * @notice Get the art mapping for the original Smol Joes
     * @param tokenId The token ID of the Smol Joe
     * @return The art index corresponding to the token ID
     */
    function _getOriginalsArtMapping(uint256 tokenId) internal view returns (uint8) {
        return uint8((_originalsArt[tokenId / NB_UINT8_IN_UINT256] >> (tokenId % NB_UINT8_IN_UINT256) * 8) & MASK_UINT8);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

import {ISmolJoeDescriptorMinimal} from "./ISmolJoeDescriptorMinimal.sol";
import {ISmolJoeArt} from "./ISmolJoeArt.sol";

/**
 * @title Interface for SmolJoeSeeder
 */
interface ISmolJoeSeeder {
    error SmolJoeSeeder__InvalidAddress();
    error SmolJoeSeeder__OnlySmolJoes();

    event OriginalsArtMappingUpdated(uint8[100] originalsArtMapping);
    event SmolJoesAddressSet(address smolJoesAddress);

    /**
     * @dev Struct describing all parts of a Smol Joe.
     * Originals and Luminaries are described by their ID.
     * Smols are described by all their body parts.
     * Modify with caution. The struct is assumed to fit in a single storage slot when bridged.
     */
    struct Seed {
        ISmolJoeArt.Brotherhood brotherhood;
        uint8 originalId;
        uint8 luminaryId;
        uint16 background;
        uint16 body;
        uint16 shoes;
        uint16 pants;
        uint16 shirt;
        uint16 beard;
        uint16 hairCapHead;
        uint16 eyeAccessory;
        uint16 accessory;
    }

    function smolJoes() external view returns (address);

    function getOriginalsArtMapping(uint256 index) external view returns (uint8);

    function updateOriginalsArtMapping(uint8[100] calldata artMapping) external;

    function setSmolJoesAddress(address _smolJoes) external;

    function generateSeed(uint256 tokenId, ISmolJoeDescriptorMinimal descriptor) external returns (Seed memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

import {ISmolJoeSeeder} from "./ISmolJoeSeeder.sol";
import {ISmolJoeArt} from "./ISmolJoeArt.sol";

/**
 * @title Common interface for SmolJoeDescriptor versions, as used by SmolJoes and SmolJoeSeeder.
 */
interface ISmolJoeDescriptorMinimal {
    /**
     * USED BY TOKEN
     */

    function tokenURI(uint256 tokenId, ISmolJoeSeeder.Seed memory seed) external view returns (string memory);

    function dataURI(uint256 tokenId, ISmolJoeSeeder.Seed memory seed) external view returns (string memory);

    /**
     * USED BY SEEDER
     */

    function traitCount(ISmolJoeArt.TraitType traitType, ISmolJoeArt.Brotherhood brotherhood)
        external
        view
        returns (uint256);
}

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

import {IInflator} from "./IInflator.sol";

/**
 * @title Interface for SmolJoeArt
 */
interface ISmolJoeArt {
    error SmolJoeArt__SenderIsNotDescriptor();
    error SmolJoeArt__EmptyPalette();
    error SmolJoeArt__BadPaletteLength();
    error SmolJoeArt__EmptyBytes();
    error SmolJoeArt__BadDecompressedLength();
    error SmolJoeArt__BadImageCount();
    error SmolJoeArt__PaletteNotFound();
    error SmolJoeArt__ImageNotFound();
    error SmolJoeArt__InvalidAddress();
    error SmolJoeArt__DecompressionError(uint8 errorCode);

    event DescriptorUpdated(address newDescriptor);
    event InflatorUpdated(address newInflator);
    event PaletteSet(uint8 paletteIndex);
    event HouseEmblemSet(Brotherhood brotherhood, address pointer);

    enum TraitType {
        Original,
        Luminary,
        Background,
        Body,
        Shoes,
        Pants,
        Shirt,
        Beard,
        HairCapHead,
        EyeAccessory,
        Accessories
    }

    enum Brotherhood {
        None,
        Academics,
        Athletes,
        Creatives,
        Gentlemans,
        MagicalBeings,
        Military,
        Musicians,
        Outlaws,
        Religious,
        Superheros
    }

    /**
     * @dev Struct describing a page of RLE encoded images
     * @param imageCount Number of images
     * @param decompressedLength Length of the data once decompressed
     * @param pointer Address of the page
     */
    struct SmolJoeArtStoragePage {
        uint16 imageCount;
        uint80 decompressedLength;
        address pointer;
    }

    /**
     * @dev Struct describing a trait
     * @param storagePages Array of pages
     * @param storedImagesCount Total number of images
     */
    struct Trait {
        SmolJoeArtStoragePage[] storagePages;
        uint256 storedImagesCount;
    }

    function descriptor() external view returns (address);

    function inflator() external view returns (IInflator);

    function palettesPointers(uint8 paletteIndex) external view returns (address);

    function getTrait(TraitType traitType, Brotherhood brotherhood) external view returns (Trait memory);

    function getImageByIndex(TraitType traitType, Brotherhood brotherhood, uint256 index)
        external
        view
        returns (bytes memory rle, string memory name);

    function getHouseEmblem(Brotherhood brotherhood) external view returns (string memory svg);

    function palettes(uint8 paletteIndex) external view returns (bytes memory);

    function setDescriptor(address descriptor) external;

    function setInflator(IInflator inflator) external;

    function setPalette(uint8 paletteIndex, bytes calldata palette) external;

    function setPalettePointer(uint8 paletteIndex, address pointer) external;

    function setHouseEmblem(Brotherhood brotherhood, string calldata svgString) external;

    function setHouseEmblemPointer(Brotherhood brotherhood, address pointer) external;

    function addTraits(
        TraitType traitType,
        Brotherhood brotherhood,
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;

    function addTraitsFromPointer(
        TraitType traitType,
        Brotherhood brotherhood,
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
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

// SPDX-License-Identifier: GPL-3.0

/// @author NounsDAO: https://github.com/nounsDAO/nouns-monorepo
/// @title Interface for Inflator

/**
 *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *
 */

pragma solidity 0.8.13;

interface IInflator {
    // Error codes
    enum ErrorCode {
        ERR_NONE, // 0 successful inflate
        ERR_NOT_TERMINATED, // 1 available inflate data did not terminate
        ERR_OUTPUT_EXHAUSTED, // 2 output space exhausted before completing inflate
        ERR_INVALID_BLOCK_TYPE, // 3 invalid block type (type == 3)
        ERR_STORED_LENGTH_NO_MATCH, // 4 stored block length did not match one's complement
        ERR_TOO_MANY_LENGTH_OR_DISTANCE_CODES, // 5 dynamic block code description: too many length or distance codes
        ERR_CODE_LENGTHS_CODES_INCOMPLETE, // 6 dynamic block code description: code lengths codes incomplete
        ERR_REPEAT_NO_FIRST_LENGTH, // 7 dynamic block code description: repeat lengths with no first length
        ERR_REPEAT_MORE, // 8 dynamic block code description: repeat more than specified lengths
        ERR_INVALID_LITERAL_LENGTH_CODE_LENGTHS, // 9 dynamic block code description: invalid literal/length code lengths
        ERR_INVALID_DISTANCE_CODE_LENGTHS, // 10 dynamic block code description: invalid distance code lengths
        ERR_MISSING_END_OF_BLOCK, // 11 dynamic block code description: missing end-of-block code
        ERR_INVALID_LENGTH_OR_DISTANCE_CODE, // 12 invalid literal/length or distance code in fixed or dynamic block
        ERR_DISTANCE_TOO_FAR, // 13 distance is too far back in fixed or dynamic block
        ERR_CONSTRUCT // 14 internal: error in construct()
    }

    function puff(bytes memory source, uint256 destlen) external pure returns (ErrorCode, bytes memory);
}
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ISmolJoeDescriptor} from "./interfaces/ISmolJoeDescriptor.sol";
import {ISmolJoeSeeder} from "./interfaces/ISmolJoeSeeder.sol";
import {NFTDescriptor} from "./libs/NFTDescriptor.sol";
import {ISVGRenderer} from "./interfaces/ISVGRenderer.sol";
import {ISmolJoeArt} from "./interfaces/ISmolJoeArt.sol";
import {IInflator} from "./interfaces/IInflator.sol";

/**
 * @title The Smol Joe NFT descriptor
 * @notice Based on NounsDAO: https://github.com/nounsDAO/nouns-monorepo
 */
contract SmolJoeDescriptor is Ownable2Step, ISmolJoeDescriptor {
    using Strings for uint256;

    /**
     * @notice The contract responsible for holding compressed Smol Joe art
     */
    ISmolJoeArt public override art;

    /**
     * @notice The contract responsible for constructing SVGs
     */
    ISVGRenderer public override renderer;

    /**
     * @notice Whether or not `tokenURI` should be returned as a data URI (Default: true)
     */
    bool public override isDataURIEnabled;

    /**
     * @notice Base URI, used when isDataURIEnabled is false
     */
    string public override baseURI;

    constructor(ISmolJoeArt _art, ISVGRenderer _renderer) {
        _setArt(_art);
        _setRenderer(_renderer);
        _setDataURIEnabled(true);
    }

    /**
     * @notice Set the SmolJoe's art contract.
     * @param _art the address of the art contract.
     */
    function setArt(ISmolJoeArt _art) external override onlyOwner {
        _setArt(_art);
    }

    /**
     * @notice Set the SVG renderer.
     * @param _renderer the address of the renderer contract.
     */
    function setRenderer(ISVGRenderer _renderer) external override onlyOwner {
        _setRenderer(_renderer);
    }

    /**
     * @notice Set the art contract's `descriptor`.
     * @param descriptor the address to set.
     */
    function setArtDescriptor(address descriptor) external override onlyOwner {
        art.setDescriptor(descriptor);
    }

    /**
     * @notice Set the art contract's `inflator`.
     * @param inflator the address to set.
     */
    function setArtInflator(IInflator inflator) external override onlyOwner {
        art.setInflator(inflator);
    }

    /**
     * @notice Toggle a boolean value which determines if `tokenURI` returns a data URI
     * or an HTTP URL.
     * @param isEnabled whether or not to enable data URIs.
     */
    function setDataURIEnabled(bool isEnabled) external override onlyOwner {
        _setDataURIEnabled(isEnabled);
    }

    /**
     * @notice Set the base URI for all token IDs. It is automatically
     * added as a prefix to the value returned in {tokenURI}, or to the
     * token ID if {tokenURI} is empty.
     * @param _baseURI the base URI to use.
     */
    function setBaseURI(string calldata _baseURI) external override onlyOwner {
        baseURI = _baseURI;

        emit BaseURIUpdated(_baseURI);
    }

    /**
     * @notice Given a token ID and seed, construct a token URI for a Smol Joe.
     * @dev The returned value may be a base64 encoded data URI or an API URL.
     * @param tokenId the token ID to construct the URI for.
     * @param seed the seed to use to construct the URI.
     * @return The token URI.
     */
    function tokenURI(uint256 tokenId, ISmolJoeSeeder.Seed memory seed)
        external
        view
        override
        returns (string memory)
    {
        if (isDataURIEnabled) {
            return _dataURI(tokenId, seed);
        }
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    /**
     * @notice Given a token ID and seed, construct a base64 encoded data URI for a Smol Joe.
     * @param tokenId the token ID to construct the URI for.
     * @param seed the seed to use to construct the URI.
     * @return The base64 encoded data URI.
     */
    function dataURI(uint256 tokenId, ISmolJoeSeeder.Seed memory seed) external view override returns (string memory) {
        return _dataURI(tokenId, seed);
    }

    /**
     * @notice Given a name, description, and seed, construct a base64 encoded data URI.
     */
    function genericDataURI(string memory name, string memory description, ISmolJoeSeeder.Seed memory seed)
        external
        view
        override
        returns (string memory)
    {
        return _genericDataURI(name, description, seed);
    }

    /**
     * @notice Given a seed, construct a base64 encoded SVG image.
     */
    function generateSVGImage(ISmolJoeSeeder.Seed memory seed) external view override returns (string memory) {
        ISVGRenderer.SVGParams memory params =
            ISVGRenderer.SVGParams({parts: _getPartsForSeed(seed), emblem: art.getHouseEmblem(seed.brotherhood)});
        return NFTDescriptor.generateSVGImage(renderer, params);
    }

    /**
     * @notice Get the trait count for a given trait type and brotherhood.
     * @param traitType the trait type to get the count for.
     * @param brotherhood the brotherhood to get the count for.
     * @return The trait count.
     */
    function traitCount(ISmolJoeArt.TraitType traitType, ISmolJoeArt.Brotherhood brotherhood)
        external
        view
        override
        returns (uint256)
    {
        return art.getTrait(traitType, brotherhood).storedImagesCount;
    }

    /**
     * @notice Get a color palette by ID.
     * @param index the index of the palette.
     * @return bytes the palette bytes, where every 3 consecutive bytes represent a color in RGB format.
     */
    function palettes(uint8 index) external view override returns (bytes memory) {
        return art.palettes(index);
    }

    /**
     * @notice Update a single color palette. This function can be used to
     * add a new color palette or update an existing palette.
     * @param paletteIndex the identifier of this palette
     * @param palette byte array of colors. every 3 bytes represent an RGB color. max length: 16**4 * 3 = 196_608
     * @dev This function can only be called by the owner.
     */
    function setPalette(uint8 paletteIndex, bytes calldata palette) external override onlyOwner {
        art.setPalette(paletteIndex, palette);
    }

    /**
     * @notice Update a single color palette. This function can be used to
     * add a new color palette or update an existing palette. This function does not check for data length validity
     * (len <= 768, len % 3 == 0).
     * @param paletteIndex the identifier of this palette
     * @param pointer the address of the contract holding the palette bytes. every 3 bytes represent an RGB color.
     * max length: 256 * 3 = 768.
     * @dev This function can only be called by the owner.
     */
    function setPalettePointer(uint8 paletteIndex, address pointer) external override onlyOwner {
        art.setPalettePointer(paletteIndex, pointer);
    }

    /**
     * @notice Set the house emblem for a given brotherhood.
     * @dev This function can only be called by the descriptor.
     * @param brotherhood The brotherhood
     * @param svgString The Base 64 encoded SVG string
     */
    function setHouseEmblem(ISmolJoeArt.Brotherhood brotherhood, string calldata svgString)
        external
        override
        onlyOwner
    {
        art.setHouseEmblem(brotherhood, svgString);
    }

    /**
     * @notice Set the house emblem for a given brotherhood.
     * @dev This function can only be called by the descriptor.
     * @param brotherhood The brotherhood
     * @param pointer The address of the contract holding the Base 64 encoded SVG string
     */
    function setHouseEmblemPointer(ISmolJoeArt.Brotherhood brotherhood, address pointer) external override onlyOwner {
        art.setHouseEmblemPointer(brotherhood, pointer);
    }

    /**
     * @notice Add a new page of RLE encoded images to a trait.
     * @param traitType The trait type
     * @param brotherhood The brotherhood
     * @param encodedCompressed The RLE encoded compressed data
     * @param decompressedLength The length of the data once decompressed
     * @param imageCount The number of images in the page
     */
    function addTraits(
        ISmolJoeArt.TraitType traitType,
        ISmolJoeArt.Brotherhood brotherhood,
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external override onlyOwner {
        art.addTraits(traitType, brotherhood, encodedCompressed, decompressedLength, imageCount);
    }

    /**
     * @notice Add a new page of RLE encoded images to a trait. The page has already been deployed to a contract.
     * @param traitType The trait type
     * @param brotherhood The brotherhood
     * @param pointer The address of the contract holding the RLE encoded compressed data
     * @param decompressedLength The length of the data once decompressed
     * @param imageCount The number of images in the page
     */
    function addTraitsFromPointer(
        ISmolJoeArt.TraitType traitType,
        ISmolJoeArt.Brotherhood brotherhood,
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external override onlyOwner {
        art.addTraitsFromPointer(traitType, brotherhood, pointer, decompressedLength, imageCount);
    }

    /**
     * @notice Add multiple pages of RLE encoded images to a trait.
     * @param traitType The trait types
     * @param brotherhood The brotherhoods
     * @param encodedCompressed The RLE encoded compressed datas
     * @param decompressedLength The lengths of the data once decompressed
     * @param imageCount The numbers of images in the page
     */
    function addMultipleTraits(
        ISmolJoeArt.TraitType[] calldata traitType,
        ISmolJoeArt.Brotherhood[] calldata brotherhood,
        bytes[] calldata encodedCompressed,
        uint80[] calldata decompressedLength,
        uint16[] calldata imageCount
    ) external override onlyOwner {
        for (uint256 i = 0; i < traitType.length; i++) {
            art.addTraits(traitType[i], brotherhood[i], encodedCompressed[i], decompressedLength[i], imageCount[i]);
        }
    }

    /**
     * @notice Add multiple pages of RLE encoded images to a trait. The pages have already been deployed to a contract.
     * @param traitType The trait types
     * @param brotherhood The brotherhoods
     * @param pointer The addresses of the contracts holding the RLE encoded compressed datas
     * @param decompressedLength The lengths of the data once decompressed
     * @param imageCount The numbers of images in the page
     */
    function addMultipleTraitsFromPointer(
        ISmolJoeArt.TraitType[] calldata traitType,
        ISmolJoeArt.Brotherhood[] calldata brotherhood,
        address[] calldata pointer,
        uint80[] calldata decompressedLength,
        uint16[] calldata imageCount
    ) external override onlyOwner {
        for (uint256 i = 0; i < traitType.length; i++) {
            art.addTraitsFromPointer(traitType[i], brotherhood[i], pointer[i], decompressedLength[i], imageCount[i]);
        }
    }

    /**
     * @dev Given a token ID and seed, construct a base64 encoded data URI for a Smol Joe.
     * @param tokenId The token ID
     * @param seed The seed of the token
     * @return The data URI
     */
    function _dataURI(uint256 tokenId, ISmolJoeSeeder.Seed memory seed) internal view returns (string memory) {
        string memory name;
        if (tokenId >= 200) {
            string[10] memory brotherhoodNames = [
                "Academic",
                "Athlete",
                "Creative",
                "Gentleman",
                "Magical Being",
                "Warrior",
                "Musician",
                "Outlaw",
                "Worshiper",
                "Hero"
            ];

            string memory joeId = tokenId.toString();
            name = string(abi.encodePacked("Smol ", brotherhoodNames[uint8(seed.brotherhood) - 1], " #", joeId));
        }
        string memory description = string(abi.encodePacked("The Expansion of Smol Joes"));

        return _genericDataURI(name, description, seed);
    }

    /**
     * @dev Given a name, description, and seed, construct a base64 encoded data URI.
     * @param name The name of the token
     * @param description The description of the token
     * @param seed The seed of the token
     * @return The data URI
     */
    function _genericDataURI(string memory name, string memory description, ISmolJoeSeeder.Seed memory seed)
        internal
        view
        returns (string memory)
    {
        NFTDescriptor.TokenURIParams memory params = NFTDescriptor.TokenURIParams({
            name: name,
            description: description,
            brotherhood: seed.brotherhood,
            emblem: art.getHouseEmblem(seed.brotherhood),
            parts: _getPartsForSeed(seed)
        });

        // The Uniques and the Luminaries are named after the name of their attribute.
        if (bytes(name).length == 0) {
            params.name = params.parts[0].name;
        }

        return NFTDescriptor.constructTokenURI(renderer, params);
    }

    /**
     * @notice Get all Smol Joe parts for the passed `seed`.
     * @param seed The seed
     * @return The different parts of the Smol Joe
     */
    function _getPartsForSeed(ISmolJoeSeeder.Seed memory seed) internal view returns (ISVGRenderer.Part[] memory) {
        if (seed.originalId > 0) {
            ISVGRenderer.Part[] memory parts = new ISVGRenderer.Part[](1);
            (bytes memory original, string memory originalTraitName) =
                art.getImageByIndex(ISmolJoeArt.TraitType.Original, ISmolJoeArt.Brotherhood.None, seed.originalId - 1);

            parts[0] = ISVGRenderer.Part({name: originalTraitName, image: original, palette: _getPalette(original)});
            return parts;
        } else if (seed.luminaryId > 0) {
            ISVGRenderer.Part[] memory parts = new ISVGRenderer.Part[](1);
            (bytes memory luminary, string memory luminaryTraitName) =
                art.getImageByIndex(ISmolJoeArt.TraitType.Luminary, seed.brotherhood, seed.luminaryId - 1);

            parts[0] = ISVGRenderer.Part({name: luminaryTraitName, image: luminary, palette: _getPalette(luminary)});
            return parts;
        } else {
            ISVGRenderer.Part[] memory parts = new ISVGRenderer.Part[](9);

            {
                (bytes memory background, string memory backgroundTraitName) =
                    art.getImageByIndex(ISmolJoeArt.TraitType.Background, seed.brotherhood, seed.background);
                (bytes memory body, string memory bodyTraitName) =
                    art.getImageByIndex(ISmolJoeArt.TraitType.Body, seed.brotherhood, seed.body);
                (bytes memory shoes, string memory shoeTraitName) =
                    art.getImageByIndex(ISmolJoeArt.TraitType.Shoes, seed.brotherhood, seed.shoes);

                parts[0] =
                    ISVGRenderer.Part({name: backgroundTraitName, image: background, palette: _getPalette(background)});
                parts[1] = ISVGRenderer.Part({name: bodyTraitName, image: body, palette: _getPalette(body)});
                parts[2] = ISVGRenderer.Part({name: shoeTraitName, image: shoes, palette: _getPalette(shoes)});
            }

            {
                (bytes memory pants, string memory pantTraitName) =
                    art.getImageByIndex(ISmolJoeArt.TraitType.Pants, seed.brotherhood, seed.pants);

                (bytes memory shirt, string memory shirtTraitName) =
                    art.getImageByIndex(ISmolJoeArt.TraitType.Shirt, seed.brotherhood, seed.shirt);

                (bytes memory beard, string memory beardTraitName) =
                    art.getImageByIndex(ISmolJoeArt.TraitType.Beard, seed.brotherhood, seed.beard);

                parts[3] = ISVGRenderer.Part({name: pantTraitName, image: pants, palette: _getPalette(pants)});
                parts[4] = ISVGRenderer.Part({name: shirtTraitName, image: shirt, palette: _getPalette(shirt)});
                parts[5] = ISVGRenderer.Part({name: beardTraitName, image: beard, palette: _getPalette(beard)});
            }

            {
                (bytes memory hairCapHead, string memory hairCapHeadTraitName) =
                    art.getImageByIndex(ISmolJoeArt.TraitType.HairCapHead, seed.brotherhood, seed.hairCapHead);
                (bytes memory eyeAccessory, string memory eyeTraitName) =
                    art.getImageByIndex(ISmolJoeArt.TraitType.EyeAccessory, seed.brotherhood, seed.eyeAccessory);
                (bytes memory accessory, string memory accessoryTraitName) =
                    art.getImageByIndex(ISmolJoeArt.TraitType.Accessories, seed.brotherhood, seed.accessory);

                parts[6] = ISVGRenderer.Part({
                    name: hairCapHeadTraitName,
                    image: hairCapHead,
                    palette: _getPalette(hairCapHead)
                });
                parts[7] =
                    ISVGRenderer.Part({name: eyeTraitName, image: eyeAccessory, palette: _getPalette(eyeAccessory)});
                parts[8] =
                    ISVGRenderer.Part({name: accessoryTraitName, image: accessory, palette: _getPalette(accessory)});
            }

            return parts;
        }
    }

    /**
     * @notice Get the color palette pointer for the passed part.
     * @dev The first bytes of the part data are [palette_index, top, right, bottom, left].
     * @param part The part
     */
    function _getPalette(bytes memory part) private view returns (bytes memory) {
        return art.palettes(uint8(part[0]));
    }

    /**
     * @dev Toggle a boolean value which determines if `tokenURI` returns a data URI
     * or an HTTP URL.
     * @param isEnabled Whether the data URI is enabled.
     *
     */
    function _setDataURIEnabled(bool isEnabled) internal {
        if (isDataURIEnabled == isEnabled) {
            revert SmolJoeDescriptor__UpdateToSameState();
        }

        isDataURIEnabled = isEnabled;

        emit DataURIToggled(isEnabled);
    }

    /**
     * @dev Set the SmolJoe's art contract.
     * @param _art the address of the art contract.
     */
    function _setArt(ISmolJoeArt _art) internal {
        if (address(_art) == address(0)) {
            revert SmolJoeDescriptor__InvalidAddress();
        }

        art = _art;

        emit ArtUpdated(_art);
    }

    /**
     * @dev Set the SVG renderer.
     * @param _renderer the address of the renderer contract.
     */
    function _setRenderer(ISVGRenderer _renderer) internal {
        if (address(_renderer) == address(0)) {
            revert SmolJoeDescriptor__InvalidAddress();
        }

        renderer = _renderer;

        emit RendererUpdated(_renderer);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

import {IInflator} from "./IInflator.sol";
import {ISmolJoeSeeder} from "./ISmolJoeSeeder.sol";
import {ISVGRenderer} from "./ISVGRenderer.sol";
import {ISmolJoeArt} from "./ISmolJoeArt.sol";
import {ISmolJoeDescriptorMinimal} from "./ISmolJoeDescriptorMinimal.sol";

/**
 * @title Interface for SmolJoeDescriptor
 */
interface ISmolJoeDescriptor is ISmolJoeDescriptorMinimal {
    error SmolJoeDescriptor__InvalidAddress();
    error SmolJoeDescriptor__UpdateToSameState();

    event DataURIToggled(bool enabled);
    event BaseURIUpdated(string baseURI);
    event ArtUpdated(ISmolJoeArt art);
    event RendererUpdated(ISVGRenderer renderer);

    function art() external returns (ISmolJoeArt);

    function renderer() external returns (ISVGRenderer);

    function isDataURIEnabled() external returns (bool);

    function baseURI() external returns (string memory);

    function setArt(ISmolJoeArt art) external;

    function setRenderer(ISVGRenderer renderer) external;

    function setArtDescriptor(address descriptor) external;

    function setArtInflator(IInflator inflator) external;

    function setDataURIEnabled(bool isEnabled) external;

    function setBaseURI(string calldata baseURI) external;

    function tokenURI(uint256 tokenId, ISmolJoeSeeder.Seed memory seed)
        external
        view
        override
        returns (string memory);

    function dataURI(uint256 tokenId, ISmolJoeSeeder.Seed memory seed) external view override returns (string memory);

    function genericDataURI(string calldata name, string calldata description, ISmolJoeSeeder.Seed memory seed)
        external
        view
        returns (string memory);

    function generateSVGImage(ISmolJoeSeeder.Seed memory seed) external view returns (string memory);

    function palettes(uint8 paletteIndex) external view returns (bytes memory);

    function traitCount(ISmolJoeArt.TraitType traitType, ISmolJoeArt.Brotherhood brotherhood)
        external
        view
        returns (uint256);

    function setPalette(uint8 paletteIndex, bytes calldata palette) external;

    function setPalettePointer(uint8 paletteIndex, address pointer) external;

    function setHouseEmblem(ISmolJoeArt.Brotherhood brotherhood, string calldata svgString) external;

    function setHouseEmblemPointer(ISmolJoeArt.Brotherhood brotherhood, address pointer) external;

    function addTraits(
        ISmolJoeArt.TraitType traitType,
        ISmolJoeArt.Brotherhood brotherhood,
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;

    function addTraitsFromPointer(
        ISmolJoeArt.TraitType traitType,
        ISmolJoeArt.Brotherhood brotherhood,
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;

    function addMultipleTraits(
        ISmolJoeArt.TraitType[] calldata traitType,
        ISmolJoeArt.Brotherhood[] calldata brotherhood,
        bytes[] calldata encodedCompressed,
        uint80[] calldata decompressedLength,
        uint16[] calldata imageCount
    ) external;

    function addMultipleTraitsFromPointer(
        ISmolJoeArt.TraitType[] calldata traitType,
        ISmolJoeArt.Brotherhood[] calldata brotherhood,
        address[] calldata pointer,
        uint80[] calldata decompressedLength,
        uint16[] calldata imageCount
    ) external;
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

import {Base64} from "base64-sol/base64.sol";
import {ISVGRenderer} from "../interfaces/ISVGRenderer.sol";
import {ISmolJoeArt} from "../interfaces/ISmolJoeArt.sol";

/**
 * @title A library used to construct ERC721 token URIs and SVG images
 * @notice Based on NounsDAO: https://github.com/nounsDAO/nouns-monorepo
 */
library NFTDescriptor {
    struct TokenURIParams {
        string name;
        string description;
        ISmolJoeArt.Brotherhood brotherhood;
        string emblem;
        ISVGRenderer.Part[] parts;
    }

    /**
     * @notice Construct an ERC721 token URI.
     * @param renderer The SVG renderer contract.
     * @param params The parameters used to construct the token URI.
     * @return The constructed token URI.
     */
    function constructTokenURI(ISVGRenderer renderer, TokenURIParams memory params)
        internal
        view
        returns (string memory)
    {
        string memory image =
            generateSVGImage(renderer, ISVGRenderer.SVGParams({parts: params.parts, emblem: params.emblem}));

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    abi.encodePacked(
                        '{"name":"',
                        params.name,
                        '", "description":"',
                        params.description,
                        '", "attributes":',
                        _generateTraitData(params.parts, params.brotherhood),
                        ', "image": "',
                        "data:image/svg+xml;base64,",
                        image,
                        '"}'
                    )
                )
            )
        );
    }

    /**
     * @notice Generate an SVG image for use in the ERC721 token URI.
     * @param renderer The SVG renderer contract.
     * @param params The parameters used to construct the SVG image.
     * @return svg The constructed SVG image.
     */
    function generateSVGImage(ISVGRenderer renderer, ISVGRenderer.SVGParams memory params)
        internal
        view
        returns (string memory svg)
    {
        return Base64.encode(bytes(renderer.generateSVG(params)));
    }

    /**
     * @notice Generate the trait data for an ERC721 token.
     * @param parts The parts used to construct the token.
     * @param brotherhood The brotherhood of the token.
     * @return traitData The constructed trait data.
     */
    function _generateTraitData(ISVGRenderer.Part[] memory parts, ISmolJoeArt.Brotherhood brotherhood)
        internal
        pure
        returns (string memory traitData)
    {
        string[9] memory traitNames =
            ["Background", "Body", "Shoes", "Pants", "Shirt", "Beard", "Headwear", "Eyewear", "Accesory"];

        // forgefmt: disable-next-item
        string[11] memory brotherhoodNames = [
            "None", "Academics", "Athletes", "Creatives", "Gentlemen", "MagicalBeings",
            "Military",  "Musicians",  "Outlaws", "Religious", "Superheros"
        ];

        traitData = "[";

        traitData = _appendTrait(traitData, "House", brotherhoodNames[uint8(brotherhood)]);
        traitData = string(abi.encodePacked(traitData, ","));

        // Originals and Luminarys have a single part
        if (parts.length == 1) {
            traitData =
                _appendTrait(traitData, "Rarity", brotherhood == ISmolJoeArt.Brotherhood.None ? "Original" : "Luminary");
            traitData = string(abi.encodePacked(traitData, ","));

            for (uint256 i = 0; i < traitNames.length; i++) {
                traitData = _appendTrait(traitData, traitNames[i], parts[0].name);

                if (i < traitNames.length - 1) {
                    traitData = string(abi.encodePacked(traitData, ","));
                }
            }
        } else {
            traitData = _appendTrait(traitData, "Rarity", "Smols");
            traitData = string(abi.encodePacked(traitData, ","));

            for (uint256 i = 0; i < parts.length; i++) {
                traitData = _appendTrait(traitData, traitNames[i], parts[i].name);

                if (i < parts.length - 1) {
                    traitData = string(abi.encodePacked(traitData, ","));
                }
            }
        }

        traitData = string(abi.encodePacked(traitData, "]"));

        return traitData;
    }

    /**
     * @dev Append a trait to the trait data.
     * @param traitData The trait data to append to.
     * @param traitName The name of the trait.
     * @param traitValue The value of the trait.
     * @return traitData The appended trait data.
     */
    function _appendTrait(string memory traitData, string memory traitName, string memory traitValue)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(traitData, '{"trait_type":"', traitName, '","value":"', traitValue, '"}'));
    }
}

// SPDX-License-Identifier: GPL-3.0

/// @author NounsDAO: https://github.com/nounsDAO/nouns-monorepo
/// @title Interface for SVGRenderer

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

interface ISVGRenderer {
    struct Part {
        string name;
        bytes image;
        bytes palette;
    }

    struct SVGParams {
        Part[] parts;
        string emblem;
    }

    function generateSVG(SVGParams memory params) external view returns (string memory svg);

    function generateSVGPart(Part memory part) external view returns (string memory partialSVG);

    function generateSVGParts(Part[] memory parts) external view returns (string memory partialSVG);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
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

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
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
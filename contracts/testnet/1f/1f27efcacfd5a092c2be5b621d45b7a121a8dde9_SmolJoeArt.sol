// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

import {Base64} from "base64/base64.sol";
import {SSTORE2} from "solady/utils/SSTORE2.sol";

import {ISmolJoeArt} from "./interfaces/ISmolJoeArt.sol";
import {IInflator} from "./interfaces/IInflator.sol";

/**
 * @title The Smol Joe art storage contract
 * @notice Based on NounsDAO: https://github.com/nounsDAO/nouns-monorepo
 */
contract SmolJoeArt is ISmolJoeArt {
    /**
     * @notice Current Smol Joe Descriptor address
     */
    address public override descriptor;

    /**
     * @notice Current inflator address
     */
    IInflator public override inflator;

    /**
     * @notice Smol Joe Color Palettes (Index => Hex Colors, stored as a contract using SSTORE2)
     */
    mapping(uint8 => address) public override palettesPointers;

    /**
     * @dev Smol Joe Art Traits
     */
    mapping(TraitType => mapping(Brotherhood => Trait)) private _traits;

    /**
     * @notice Brotherhoods House Emblems
     * @dev Emblems have a higher resolution than the other traits
     * That is why they are stored sepparately, directly as a SVG string (in Base64)
     */
    mapping(Brotherhood => address) private _houseEmblemsPointers;

    /**
     * @notice Brotherhoods Glowing House Emblems
     * @dev Emblems have a higher resolution than the other traits
     * That is why they are stored sepparately, directly as a SVG string (in Base64)
     */
    mapping(Brotherhood => address) private _glowingHouseEmblemsPointers;

    /**
     * @notice Luminaries trait metadata
     * @dev Luminaries are single images, but have specific traits that do not correspond to real images
     * That is why they are stored sepparately
     */
    mapping(Brotherhood => address) private _luminariesMetadataPointers;

    /**
     * @notice Require that the sender is the descriptor.
     */
    modifier onlyDescriptor() {
        if (msg.sender != descriptor) {
            revert SmolJoeArt__SenderIsNotDescriptor();
        }
        _;
    }

    constructor(address _descriptor, IInflator _inflator) {
        _setDescriptor(_descriptor);
        _setInflator(_inflator);
    }

    /**
     * @notice Get the trait for a given trait type and brotherhood.
     * @param traitType The trait type
     * @param brotherhood The brotherhood
     * @return Trait struct
     */
    function getTrait(TraitType traitType, Brotherhood brotherhood) external view override returns (Trait memory) {
        return _traits[traitType][brotherhood];
    }

    /**
     * @notice Get the image for a given trait type, brotherhood, and index.
     * @param traitType The trait type
     * @param brotherhood The brotherhood
     * @param index The index of the image
     * @return The image bytes and the image name
     */
    function getImageByIndex(TraitType traitType, Brotherhood brotherhood, uint256 index)
        external
        view
        override
        returns (bytes memory, string memory)
    {
        return _imageByIndex(_traits[traitType][brotherhood], index);
    }

    /**
     * @notice Get the Base 64 encoded SVG string describing the emblem for a given brotherhood.
     * @dev This is not a valid SVG as it needs to be appended to the rest of the image built by the SVG renderer
     * @param brotherhood The brotherhood
     * @return The SVG string
     */
    function getHouseEmblem(Brotherhood brotherhood) external view override returns (string memory) {
        address pointer = _houseEmblemsPointers[brotherhood];

        if (pointer == address(0)) {
            return "";
        } else {
            return string(Base64.decode(string(SSTORE2.read(pointer))));
        }
    }

    /**
     * @notice Get the Base 64 encoded SVG string describing the glowing emblem for a given brotherhood.
     * Glowing emblems are used for the Luminaries
     * @dev This is not a valid SVG as it needs to be appended to the rest of the image built by the SVG renderer
     * @param brotherhood The brotherhood
     * @return The SVG string
     */
    function getGlowingHouseEmblem(Brotherhood brotherhood) external view override returns (string memory) {
        address pointer = _glowingHouseEmblemsPointers[brotherhood];

        if (pointer == address(0)) {
            return "";
        } else {
            return string(Base64.decode(string(SSTORE2.read(pointer))));
        }
    }

    /**
     * @notice Get the abi encoded array describing the luminaries metadata for a given brotherhood.
     * @param brotherhood The brotherhood
     * @return The metadata string
     */
    function getLuminariesMetadata(Brotherhood brotherhood) external view override returns (bytes[] memory) {
        address pointer = _luminariesMetadataPointers[brotherhood];

        if (pointer == address(0)) {
            return new bytes[](0);
        } else {
            return abi.decode(SSTORE2.read(pointer), (bytes[]));
        }
    }

    /**
     * @notice Get a color palette bytes.
     * @param paletteIndex the identifier of this palette
     * @return The palette bytes
     */
    function palettes(uint8 paletteIndex) external view override returns (bytes memory) {
        address pointer = palettesPointers[paletteIndex];
        if (pointer == address(0)) {
            revert SmolJoeArt__PaletteNotFound();
        }
        return SSTORE2.read(palettesPointers[paletteIndex]);
    }

    /**
     * @notice Set the descriptor address.
     * @dev This function can only be called by the current descriptor.
     * @param _descriptor New descriptor address
     */
    function setDescriptor(address _descriptor) external override onlyDescriptor {
        _setDescriptor(_descriptor);
    }

    /**
     * @notice Set the inflator.
     * @dev This function can only be called by the descriptor.
     */
    function setInflator(IInflator _inflator) external override onlyDescriptor {
        _setInflator(_inflator);
    }

    /**
     * @notice Update a single color palette. This function can be used to
     * add a new color palette or update an existing palette.
     * @dev This function can only be called by the descriptor.
     * @param paletteIndex the identifier of this palette
     * @param palette byte array of colors. every 3 bytes represent an RGB color. max length: 16**4 * 3 = 196_608
     */
    function setPalette(uint8 paletteIndex, bytes calldata palette) external override onlyDescriptor {
        if (palette.length == 0) {
            revert SmolJoeArt__EmptyPalette();
        }

        if (palette.length % 3 != 0 || palette.length > 196_608) {
            revert SmolJoeArt__BadPaletteLength();
        }
        palettesPointers[paletteIndex] = SSTORE2.write(palette);

        emit PaletteSet(paletteIndex);
    }

    /**
     * @notice Update a single color palette address. This function can be used to
     * add a new color palette or update an existing palette. This function does not check for data length validity
     * @dev This function can only be called by the descriptor.
     * @param paletteIndex the identifier of this palette
     * @param pointer the address of the contract holding the palette bytes.
     */
    function setPalettePointer(uint8 paletteIndex, address pointer) external override onlyDescriptor {
        palettesPointers[paletteIndex] = pointer;

        emit PaletteSet(paletteIndex);
    }

    /**
     * @notice Set the house emblem for a given brotherhood.
     * @dev This function can only be called by the descriptor.
     * @param brotherhood The brotherhood
     * @param svgString The Base 64 encoded SVG string
     */
    function setHouseEmblem(Brotherhood brotherhood, string calldata svgString) external override onlyDescriptor {
        address pointer = SSTORE2.write(bytes(svgString));

        _houseEmblemsPointers[brotherhood] = pointer;

        emit HouseEmblemSet(brotherhood, pointer);
    }

    /**
     * @notice Sets the house emblem pointer address.
     * @dev This function can only be called by the descriptor.
     * Can be set to address(0) to remove the house emblem from the image.
     * @param brotherhood The brotherhood
     */
    function setHouseEmblemPointer(Brotherhood brotherhood, address pointer) external override onlyDescriptor {
        _houseEmblemsPointers[brotherhood] = pointer;

        emit HouseEmblemSet(brotherhood, pointer);
    }

    /**
     * @notice Set the glowing house emblem for a given brotherhood.
     * @dev This function can only be called by the descriptor.
     * @param brotherhood The brotherhood
     * @param svgString The Base 64 encoded SVG string
     */
    function setGlowingHouseEmblem(Brotherhood brotherhood, string calldata svgString)
        external
        override
        onlyDescriptor
    {
        address pointer = SSTORE2.write(bytes(svgString));

        _glowingHouseEmblemsPointers[brotherhood] = pointer;

        emit HouseGlowingEmblemSet(brotherhood, pointer);
    }

    /**
     * @notice Sets the glowing house emblem pointer address.
     * @dev This function can only be called by the descriptor.
     * Can be set to address(0) to remove the house emblem from the image.
     * @param brotherhood The brotherhood
     */
    function setGlowingHouseEmblemPointer(Brotherhood brotherhood, address pointer) external override onlyDescriptor {
        _glowingHouseEmblemsPointers[brotherhood] = pointer;

        emit HouseGlowingEmblemSet(brotherhood, pointer);
    }

    /**
     * @notice Set the luminaries metadata for a given brotherhood.
     * @dev This function can only be called by the descriptor.
     * @param brotherhood The brotherhood
     * @param metadatas The abi encoded metadata array
     */
    function setLuminariesMetadata(Brotherhood brotherhood, bytes calldata metadatas)
        external
        override
        onlyDescriptor
    {
        address pointer = SSTORE2.write(metadatas);

        _luminariesMetadataPointers[brotherhood] = pointer;

        emit LuminariesMetadataSet(brotherhood, pointer);
    }

    /**
     * @notice Sets the luminaries metadata pointer address.
     * @dev This function can only be called by the descriptor.
     * @param brotherhood The brotherhood
     */
    function setLuminariesMetadataPointer(Brotherhood brotherhood, address pointer) external override onlyDescriptor {
        _houseEmblemsPointers[brotherhood] = pointer;

        emit HouseEmblemSet(brotherhood, pointer);
    }

    /**
     * @notice Add a new page of RLE encoded images to a trait.
     * @dev This function can only be called by the descriptor.
     * @param traitType The trait type
     * @param brotherhood The brotherhood
     * @param encodedCompressed The RLE encoded compressed data
     * @param decompressedLength The length of the data once decompressed
     * @param imageCount The number of images in the page
     */
    function addTraits(
        TraitType traitType,
        Brotherhood brotherhood,
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external override onlyDescriptor {
        _addPage(_traits[traitType][brotherhood], encodedCompressed, decompressedLength, imageCount);
    }

    /**
     * @notice Add a new page of RLE encoded images to a trait. The page has already been deployed to a contract.
     * @dev This function can only be called by the descriptor.
     * @param traitType The trait type
     * @param brotherhood The brotherhood
     * @param pointer The address of the contract holding the RLE encoded compressed data
     * @param decompressedLength The length of the data once decompressed
     * @param imageCount The number of images in the page
     */
    function addTraitsFromPointer(
        TraitType traitType,
        Brotherhood brotherhood,
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external override onlyDescriptor {
        _addPage(_traits[traitType][brotherhood], pointer, decompressedLength, imageCount);
    }

    /**
     * @dev Add a new page of RLE encoded images to a trait by deploying a new contract to hold the data.
     * @param trait The trait to add the page to
     * @param encodedCompressed The RLE encoded compressed data
     * @param decompressedLength The length of the data once decompressed
     * @param imageCount The number of images in the page
     */
    function _addPage(
        Trait storage trait,
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) internal {
        if (encodedCompressed.length == 0) {
            revert SmolJoeArt__EmptyBytes();
        }
        address pointer = SSTORE2.write(encodedCompressed);
        _addPage(trait, pointer, decompressedLength, imageCount);
    }

    /**
     * @dev Add a new page of RLE encoded images to a trait by using an existing contract to hold the data.
     * @param trait The trait to add the page to
     * @param pointer The address of the contract holding the RLE encoded compressed data
     * @param decompressedLength The length of the data once decompressed
     * @param imageCount The number of images in the page
     */
    function _addPage(Trait storage trait, address pointer, uint80 decompressedLength, uint16 imageCount) internal {
        if (decompressedLength == 0) {
            revert SmolJoeArt__BadDecompressedLength();
        }
        if (imageCount == 0) {
            revert SmolJoeArt__BadImageCount();
        }
        trait.storagePages.push(
            SmolJoeArtStoragePage({pointer: pointer, decompressedLength: decompressedLength, imageCount: imageCount})
        );
        trait.storedImagesCount += imageCount;
    }

    /**
     * @dev Given an image index, this function finds the storage page the image is in, and the relative index
     * inside the page, so the image can be read from storage.
     * Example: if you have 2 pages with 100 images each, and you want to get image 150, this function would return
     * the 2nd page, and the 50th index.
     * @param trait The trait to get the image from
     * @param index The index of the image
     * @return The decompressed image bytes and the image name
     */
    function _imageByIndex(ISmolJoeArt.Trait storage trait, uint256 index)
        internal
        view
        returns (bytes memory, string memory)
    {
        (ISmolJoeArt.SmolJoeArtStoragePage storage page, uint256 indexInPage) = _getPage(trait.storagePages, index);
        (bytes[] memory decompressedImages, string[] memory imagesNames) = _decompressAndDecode(page);

        return (decompressedImages[indexInPage], imagesNames[indexInPage]);
    }

    /**
     * @dev Given an image index, this function finds the storage page the image is in, and the relative index
     * inside the page, so the image can be read from storage.
     * Example: if you have 2 pages with 100 images each, and you want to get image 150, this function would return
     * the 2nd page, and the 50th index.
     * @param pages The pages to get the image from
     * @param index The index of the image
     * @return The storage page and the relative index inside the page
     */
    function _getPage(ISmolJoeArt.SmolJoeArtStoragePage[] storage pages, uint256 index)
        internal
        view
        returns (ISmolJoeArt.SmolJoeArtStoragePage storage, uint256)
    {
        uint256 len = pages.length;
        uint256 pageFirstImageIndex = 0;
        for (uint256 i = 0; i < len; i++) {
            ISmolJoeArt.SmolJoeArtStoragePage storage page = pages[i];

            uint256 pageImageCount = page.imageCount;

            if (index < pageFirstImageIndex + pageImageCount) {
                return (page, index - pageFirstImageIndex);
            }

            pageFirstImageIndex += pageImageCount;
        }

        revert SmolJoeArt__ImageNotFound();
    }

    /**
     * @dev Decompress and decode the data in a storage page.
     * @param page The storage page
     * @return The decompressed images and the images names
     */
    function _decompressAndDecode(ISmolJoeArt.SmolJoeArtStoragePage storage page)
        internal
        view
        returns (bytes[] memory, string[] memory)
    {
        bytes memory compressedData = SSTORE2.read(page.pointer);
        (IInflator.ErrorCode err, bytes memory decompressedData) =
            inflator.puff(compressedData, page.decompressedLength);

        if (err != IInflator.ErrorCode.ERR_NONE) {
            revert SmolJoeArt__DecompressionError(uint8(err));
        }

        return abi.decode(decompressedData, (bytes[], string[]));
    }

    /**
     * @dev Set the descriptor address.
     * @param _descriptor New descriptor address
     */
    function _setDescriptor(address _descriptor) internal {
        if (_descriptor == address(0)) {
            revert SmolJoeArt__InvalidAddress();
        }

        descriptor = _descriptor;

        emit DescriptorUpdated(descriptor);
    }

    /**
     * @dev Set the inflator address.
     * @param _inflator New inflator address
     */
    function _setInflator(IInflator _inflator) internal {
        if (address(_inflator) == address(0)) {
            revert SmolJoeArt__InvalidAddress();
        }

        inflator = _inflator;

        emit InflatorUpdated(address(_inflator));
    }
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
pragma solidity ^0.8.4;

/// @notice Read and write to persistent storage at a fraction of the cost.
/// @author Solady (https://github.com/vectorized/solmady/blob/main/src/utils/SSTORE2.sol)
/// @author Saw-mon-and-Natalie (https://github.com/Saw-mon-and-Natalie)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SSTORE2.sol)
/// @author Modified from 0xSequence (https://github.com/0xSequence/sstore2/blob/master/contracts/SSTORE2.sol)
library SSTORE2 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev We skip the first byte as it's a STOP opcode,
    /// which ensures the contract can't be called.
    uint256 internal constant DATA_OFFSET = 1;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CUSTOM ERRORS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Unable to deploy the storage contract.
    error DeploymentFailed();

    /// @dev The storage contract address is invalid.
    error InvalidPointer();

    /// @dev Attempt to read outside of the storage contract's bytecode bounds.
    error ReadOutOfBounds();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         WRITE LOGIC                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Writes `data` into the bytecode of a storage contract and returns its address.
    function write(bytes memory data) internal returns (address pointer) {
        /// @solidity memory-safe-assembly
        assembly {
            let originalDataLength := mload(data)

            // Add 1 to data size since we are prefixing it with a STOP opcode.
            let dataSize := add(originalDataLength, DATA_OFFSET)

            /**
             * ------------------------------------------------------------------------------+
             * Opcode      | Mnemonic        | Stack                   | Memory              |
             * ------------------------------------------------------------------------------|
             * 61 codeSize | PUSH2 codeSize  | codeSize                |                     |
             * 80          | DUP1            | codeSize codeSize       |                     |
             * 60 0xa      | PUSH1 0xa       | 0xa codeSize codeSize   |                     |
             * 3D          | RETURNDATASIZE  | 0 0xa codeSize codeSize |                     |
             * 39          | CODECOPY        | codeSize                | [0..codeSize): code |
             * 3D          | RETURNDATASIZE  | 0 codeSize              | [0..codeSize): code |
             * F3          | RETURN          |                         | [0..codeSize): code |
             * 00          | STOP            |                         |                     |
             * ------------------------------------------------------------------------------+
             * @dev Prefix the bytecode with a STOP opcode to ensure it cannot be called.
             * Also PUSH2 is used since max contract size cap is 24,576 bytes which is less than 2 ** 16.
             */
            mstore(
                data,
                or(
                    0x61000080600a3d393df300,
                    // Left shift `dataSize` by 64 so that it lines up with the 0000 after PUSH2.
                    shl(0x40, dataSize)
                )
            )

            // Deploy a new contract with the generated creation code.
            pointer := create(0, add(data, 0x15), add(dataSize, 0xa))

            // If `pointer` is zero, revert.
            if iszero(pointer) {
                // Store the function selector of `DeploymentFailed()`.
                mstore(0x00, 0x30116425)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Restore original length of the variable size `data`.
            mstore(data, originalDataLength)
        }
    }

    /// @dev Writes `data` into the bytecode of a storage contract with `salt`
    /// and returns its deterministic address.
    function writeDeterministic(bytes memory data, bytes32 salt)
        internal
        returns (address pointer)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let originalDataLength := mload(data)
            let dataSize := add(originalDataLength, DATA_OFFSET)

            mstore(data, or(0x61000080600a3d393df300, shl(0x40, dataSize)))

            // Deploy a new contract with the generated creation code.
            pointer := create2(0, add(data, 0x15), add(dataSize, 0xa), salt)

            // If `pointer` is zero, revert.
            if iszero(pointer) {
                // Store the function selector of `DeploymentFailed()`.
                mstore(0x00, 0x30116425)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Restore original length of the variable size `data`.
            mstore(data, originalDataLength)
        }
    }

    /// @dev Returns the initialization code hash of the storage contract for `data`.
    /// Used for mining vanity addresses with create2crunch.
    function initCodeHash(bytes memory data) internal pure returns (bytes32 hash) {
        /// @solidity memory-safe-assembly
        assembly {
            let originalDataLength := mload(data)
            let dataSize := add(originalDataLength, DATA_OFFSET)

            mstore(data, or(0x61000080600a3d393df300, shl(0x40, dataSize)))

            hash := keccak256(add(data, 0x15), add(dataSize, 0xa))

            // Restore original length of the variable size `data`.
            mstore(data, originalDataLength)
        }
    }

    /// @dev Returns the address of the storage contract for `data`
    /// deployed with `salt` by `deployer`.
    function predictDeterministicAddress(bytes memory data, bytes32 salt, address deployer)
        internal
        pure
        returns (address predicted)
    {
        bytes32 hash = initCodeHash(data);
        /// @solidity memory-safe-assembly
        assembly {
            // Compute and store the bytecode hash.
            mstore8(0x00, 0xff) // Write the prefix.
            mstore(0x35, hash)
            mstore(0x01, shl(96, deployer))
            mstore(0x15, salt)
            predicted := keccak256(0x00, 0x55)
            // Restore the part of the free memory pointer that has been overwritten.
            mstore(0x35, 0)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         READ LOGIC                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns all the `data` from the bytecode of the storage contract at `pointer`.
    function read(address pointer) internal view returns (bytes memory data) {
        /// @solidity memory-safe-assembly
        assembly {
            let pointerCodesize := extcodesize(pointer)
            if iszero(pointerCodesize) {
                // Store the function selector of `InvalidPointer()`.
                mstore(0x00, 0x11052bb4)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Offset all indices by 1 to skip the STOP opcode.
            let size := sub(pointerCodesize, DATA_OFFSET)

            // Get the pointer to the free memory and allocate
            // enough 32-byte words for the data and the length of the data,
            // then copy the code to the allocated memory.
            // Masking with 0xffe0 will suffice, since contract size is less than 16 bits.
            data := mload(0x40)
            mstore(0x40, add(data, and(add(size, 0x3f), 0xffe0)))
            mstore(data, size)
            mstore(add(add(data, 0x20), size), 0) // Zeroize the last slot.
            extcodecopy(pointer, add(data, 0x20), DATA_OFFSET, size)
        }
    }

    /// @dev Returns the `data` from the bytecode of the storage contract at `pointer`,
    /// from the byte at `start`, to the end of the data stored.
    function read(address pointer, uint256 start) internal view returns (bytes memory data) {
        /// @solidity memory-safe-assembly
        assembly {
            let pointerCodesize := extcodesize(pointer)
            if iszero(pointerCodesize) {
                // Store the function selector of `InvalidPointer()`.
                mstore(0x00, 0x11052bb4)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // If `!(pointer.code.size > start)`, reverts.
            // This also handles the case where `start + DATA_OFFSET` overflows.
            if iszero(gt(pointerCodesize, start)) {
                // Store the function selector of `ReadOutOfBounds()`.
                mstore(0x00, 0x84eb0dd1)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            let size := sub(pointerCodesize, add(start, DATA_OFFSET))

            // Get the pointer to the free memory and allocate
            // enough 32-byte words for the data and the length of the data,
            // then copy the code to the allocated memory.
            // Masking with 0xffe0 will suffice, since contract size is less than 16 bits.
            data := mload(0x40)
            mstore(0x40, add(data, and(add(size, 0x3f), 0xffe0)))
            mstore(data, size)
            mstore(add(add(data, 0x20), size), 0) // Zeroize the last slot.
            extcodecopy(pointer, add(data, 0x20), add(start, DATA_OFFSET), size)
        }
    }

    /// @dev Returns the `data` from the bytecode of the storage contract at `pointer`,
    /// from the byte at `start`, to the byte at `end` (exclusive) of the data stored.
    function read(address pointer, uint256 start, uint256 end)
        internal
        view
        returns (bytes memory data)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let pointerCodesize := extcodesize(pointer)
            if iszero(pointerCodesize) {
                // Store the function selector of `InvalidPointer()`.
                mstore(0x00, 0x11052bb4)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // If `!(pointer.code.size > end) || (start > end)`, revert.
            // This also handles the cases where
            // `end + DATA_OFFSET` or `start + DATA_OFFSET` overflows.
            if iszero(
                and(
                    gt(pointerCodesize, end), // Within bounds.
                    iszero(gt(start, end)) // Valid range.
                )
            ) {
                // Store the function selector of `ReadOutOfBounds()`.
                mstore(0x00, 0x84eb0dd1)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            let size := sub(end, start)

            // Get the pointer to the free memory and allocate
            // enough 32-byte words for the data and the length of the data,
            // then copy the code to the allocated memory.
            // Masking with 0xffe0 will suffice, since contract size is less than 16 bits.
            data := mload(0x40)
            mstore(0x40, add(data, and(add(size, 0x3f), 0xffe0)))
            mstore(data, size)
            mstore(add(add(data, 0x20), size), 0) // Zeroize the last slot.
            extcodecopy(pointer, add(data, 0x20), add(start, DATA_OFFSET), size)
        }
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
    event HouseGlowingEmblemSet(Brotherhood brotherhood, address pointer);
    event LuminariesMetadataSet(Brotherhood brotherhood, address pointer);

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
        Heroes,
        MagicalBeings,
        Musicians,
        Outlaws,
        Warriors,
        Worshipers
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

    function getGlowingHouseEmblem(Brotherhood brotherhood) external view returns (string memory svg);

    function getLuminariesMetadata(Brotherhood brotherhood) external view returns (bytes[] memory);

    function palettes(uint8 paletteIndex) external view returns (bytes memory);

    function setDescriptor(address descriptor) external;

    function setInflator(IInflator inflator) external;

    function setPalette(uint8 paletteIndex, bytes calldata palette) external;

    function setPalettePointer(uint8 paletteIndex, address pointer) external;

    function setHouseEmblem(Brotherhood brotherhood, string calldata svgString) external;

    function setHouseEmblemPointer(Brotherhood brotherhood, address pointer) external;

    function setGlowingHouseEmblem(ISmolJoeArt.Brotherhood brotherhood, string calldata svgString) external;

    function setGlowingHouseEmblemPointer(ISmolJoeArt.Brotherhood brotherhood, address pointer) external;

    function setLuminariesMetadata(Brotherhood brotherhood, bytes calldata metadatas) external;

    function setLuminariesMetadataPointer(Brotherhood brotherhood, address pointer) external;

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
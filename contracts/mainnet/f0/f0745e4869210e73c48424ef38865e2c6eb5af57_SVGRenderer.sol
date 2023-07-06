// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

import {ISVGRenderer} from "./interfaces/ISVGRenderer.sol";

/**
 * @title A contract used to convert multi-part RLE compressed images to SVG
 * @notice Based on NounsDAO: https://github.com/nounsDAO/nouns-monorepo and adjusted to work with Smol Joes
 */
contract SVGRenderer is ISVGRenderer {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint256 private constant _INDEX_TO_BYTES3_FACTOR = 3;

    string private constant _SVG_START_TAG =
        '<svg width="900" height="900" viewBox="0 0 900 900" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges">';
    string private constant _SVG_END_TAG = "</svg>";

    struct ContentBounds {
        uint8 top;
        uint8 right;
        uint8 bottom;
        uint8 left;
    }

    struct Draw {
        uint8 length;
        uint16 colorIndex;
    }

    struct DecodedImage {
        ContentBounds bounds;
        Draw[] draws;
    }

    /**
     * @notice Given RLE image data and color palette pointers, merge to generate a single SVG image.
     * @param params The parameters used to construct the SVG image.
     * @return svg The constructed SVG image.
     */
    function generateSVG(SVGParams calldata params) external pure override returns (string memory svg) {
        return string(
            abi.encodePacked(
                _SVG_START_TAG, _generateSVGRects(params), params.emblem, params.glowingEmblem, _SVG_END_TAG
            )
        );
    }

    /**
     * @notice Given RLE image data and a color palette pointer, merge to generate a partial SVG image.
     * @param part The part used to construct the SVG image.
     * @return partialSVG The constructed SVG image.
     */
    function generateSVGPart(Part calldata part) external pure override returns (string memory partialSVG) {
        Part[] memory parts = new Part[](1);
        parts[0] = part;

        return _generateSVGRects(SVGParams({parts: parts, emblem: "", glowingEmblem: ""}));
    }

    /**
     * @notice Given RLE image data and color palette pointers, merge to generate a partial SVG image.
     * @param parts The parts used to construct the SVG image.
     * @return partialSVG The constructed SVG image.
     */
    function generateSVGParts(Part[] calldata parts) external pure override returns (string memory partialSVG) {
        return _generateSVGRects(SVGParams({parts: parts, emblem: "", glowingEmblem: ""}));
    }

    /**
     * @notice Given RLE image parts and color palettes, generate SVG rects.
     * @param params The parameters used to construct the SVG image.
     * @return svg The constructed SVG image.
     */
    function _generateSVGRects(SVGParams memory params) private pure returns (string memory svg) {
        // forgefmt: disable-next-item
        string[46] memory lookup = [    
            "0", "20", "40", "60", "80", "100", "120", "140", "160", "180", "200", 
            "220", "240", "260", "280", "300", "320", "340", "360", "380", "400", 
            "420", "440", "460", "480", "500", "520", "540", "560", "580", "600", 
            "620", "640", "660", "680", "700", "720", "740", "760", "780", "800", 
            "820", "840", "860", "880", "900"
        ];

        string memory rects;
        string[] memory cache;

        for (uint8 p = 0; p < params.parts.length; p++) {
            // Contract bytecode cannot exceed 24576 bytes so the palette will contain at most 24576 / 3 = 8192 colors
            cache = new string[](8192);

            DecodedImage memory image = _decodeRLEImage(params.parts[p].image);

            bytes memory palette = params.parts[p].palette;
            uint256 currentX = image.bounds.left;
            uint256 currentY = image.bounds.top;
            uint256 cursor;
            string[16] memory buffer;

            string memory part;
            for (uint256 i = 0; i < image.draws.length; i++) {
                Draw memory draw = image.draws[i];

                uint8 length = _getRectLength(currentX, draw.length, image.bounds.right);
                while (length > 0) {
                    if (draw.colorIndex != 0) {
                        buffer[cursor] = lookup[length]; // width
                        buffer[cursor + 1] = lookup[currentX]; // x
                        buffer[cursor + 2] = lookup[currentY]; // y

                        buffer[cursor + 3] = _getColor(palette, draw.colorIndex, cache); // color

                        cursor += 4;

                        if (cursor >= 16) {
                            part = string(abi.encodePacked(part, _getChunk(cursor, buffer)));
                            cursor = 0;
                        }
                    }

                    currentX += length;
                    if (currentX == image.bounds.right) {
                        currentX = image.bounds.left;
                        currentY++;
                    }

                    draw.length -= length;
                    length = _getRectLength(currentX, draw.length, image.bounds.right);
                }
            }

            if (cursor != 0) {
                part = string(abi.encodePacked(part, _getChunk(cursor, buffer)));
            }
            rects = string(abi.encodePacked(rects, part));
        }
        return rects;
    }

    /**
     * @notice Given an x-coordinate, draw length, and right bound, return the draw
     * length for a single SVG rectangle.
     * @param currentX The current x-coordinate.
     * @param drawLength The length of the draw.
     * @param rightBound The right bound of the image.
     * @return length The length of the SVG rectangle.
     */
    function _getRectLength(uint256 currentX, uint8 drawLength, uint8 rightBound) private pure returns (uint8) {
        uint8 remainingPixelsInLine = rightBound - uint8(currentX);
        return drawLength <= remainingPixelsInLine ? drawLength : remainingPixelsInLine;
    }

    /**
     * @notice Return a string that consists of all rects in the provided `buffer`.
     * @param cursor The number of rects in the buffer.
     * @param buffer The buffer of rects.
     * @return chunk The string of rects.
     */
    function _getChunk(uint256 cursor, string[16] memory buffer) private pure returns (string memory) {
        string memory chunk;
        for (uint256 i = 0; i < cursor; i += 4) {
            chunk = string(
                abi.encodePacked(
                    chunk,
                    '<rect width="',
                    buffer[i],
                    '" height="20" x="',
                    buffer[i + 1],
                    '" y="',
                    buffer[i + 2],
                    '" fill="#',
                    buffer[i + 3],
                    '" />'
                )
            );
        }
        return chunk;
    }

    /**
     * @notice Decode a single RLE compressed image into a `DecodedImage`.
     * @param image The RLE compressed image.
     * @return decodedImage The decoded image.
     */
    function _decodeRLEImage(bytes memory image) private pure returns (DecodedImage memory) {
        ContentBounds memory bounds = ContentBounds({
            top: uint8(image[1]),
            right: uint8(image[2]),
            bottom: uint8(image[3]),
            left: uint8(image[4])
        });

        uint256 cursor;
        Draw[] memory draws = new Draw[]((image.length - 5) / 3);

        for (uint256 i = 5; i < image.length; i += 3) {
            draws[cursor] = Draw({
                length: uint8(image[i]),
                colorIndex: (uint16(uint8(image[i + 1])) << 8) + uint16(uint8(image[i + 2]))
            });
            cursor++;
        }
        return DecodedImage({bounds: bounds, draws: draws});
    }

    /**
     * @notice Get the target hex color code from the cache. Populate the cache if
     * the color code does not yet exist.
     * @param palette The palette of the image.
     * @param index The index of the color in the palette.
     * @param cache The cache of color codes.
     * @return  The color code.
     */
    function _getColor(bytes memory palette, uint256 index, string[] memory cache)
        private
        pure
        returns (string memory)
    {
        if (bytes(cache[index]).length == 0) {
            uint256 i = index * _INDEX_TO_BYTES3_FACTOR;
            cache[index] = _toHexString(abi.encodePacked(palette[i], palette[i + 1], palette[i + 2]));
        }
        return cache[index];
    }

    /**
     * @dev Convert `bytes` to a 6 character ASCII `string` hexadecimal representation.
     * @param b The `bytes` to convert.
     * @return The `string` hexadecimal representation.
     */
    function _toHexString(bytes memory b) private pure returns (string memory) {
        uint24 value = uint24(bytes3(b));

        bytes memory buffer = new bytes(6);
        buffer[5] = _HEX_SYMBOLS[value & 0xf];
        buffer[4] = _HEX_SYMBOLS[(value >> 4) & 0xf];
        buffer[3] = _HEX_SYMBOLS[(value >> 8) & 0xf];
        buffer[2] = _HEX_SYMBOLS[(value >> 12) & 0xf];
        buffer[1] = _HEX_SYMBOLS[(value >> 16) & 0xf];
        buffer[0] = _HEX_SYMBOLS[(value >> 20) & 0xf];
        return string(buffer);
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
        string glowingEmblem;
    }

    function generateSVG(SVGParams memory params) external view returns (string memory svg);

    function generateSVGPart(Part memory part) external view returns (string memory partialSVG);

    function generateSVGParts(Part[] memory parts) external view returns (string memory partialSVG);
}
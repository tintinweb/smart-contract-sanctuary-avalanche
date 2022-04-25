// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

import '../../interfaces/ICategories.sol';
import '../../interfaces/IFrameGenerator.sol';
import '../../interfaces/IFieldGenerator.sol';
import '../../interfaces/IHardwareGenerator.sol';
import '../../interfaces/IFrameSVGs.sol';
import '../../interfaces/IShieldManager.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '../../libraries/Base64.sol';

/// @dev Generate Shield Metadata
contract EmblemWeaver {
	using Strings for uint8;

	IFieldGenerator public immutable fieldGenerator;
	IHardwareGenerator public immutable hardwareGenerator;
	IFrameGenerator public immutable frameGenerator;

	constructor(
		IFieldGenerator _fieldGenerator,
		IHardwareGenerator _hardwareGenerator,
		IFrameGenerator _frameGenerator
	) {
		fieldGenerator = _fieldGenerator;
		hardwareGenerator = _hardwareGenerator;
		frameGenerator = _frameGenerator;
	}

	function generateShieldURI(IShieldManager.Shield memory shield)
		external
		view
		returns (string memory)
	{
		IFieldSVGs.FieldData memory field = fieldGenerator.generateField(shield.field, shield.colors);
		IHardwareSVGs.HardwareData memory hardware = hardwareGenerator.generateHardware(
			shield.hardware
		);
		IFrameSVGs.FrameData memory frame = frameGenerator.generateFrame(shield.frame);

		string memory name = generateTitle(field.title, hardware.title, frame.title, shield.colors);
		bytes memory attributes = generateAttributesJSON(field, hardware, frame, shield.colors);

		return
			string(
				abi.encodePacked(
					'data:application/json;base64,',
					Base64.encode(
						bytes(
							abi.encodePacked(
								'{"name":"',
								name,
								'", "description":"A unique Shield, designed and built on-chain.", "image": "data:image/svg+xml;base64,',
								Base64.encode(
									bytes(generateSVG(field.svgString, hardware.svgString, frame.svgString))
								),
								'", "attributes": ',
								attributes,
								'}'
							)
						)
					)
				)
			);
	}

	function generateTitle(
		string memory fieldTitle,
		string memory hardwareTitle,
		string memory frameTitle,
		uint24[4] memory colors
	) internal view returns (string memory) {
		bytes memory frameString = '';
		if (bytes(frameTitle).length > 0) {
			frameString = abi.encodePacked(frameTitle, ': ');
		}
		return
			string(
				abi.encodePacked(
					frameString,
					hardwareTitle,
					' on ',
					generateColorTitleSnippet(colors),
					fieldTitle
				)
			);
	}

	function generateColorTitleSnippet(uint24[4] memory colors)
		internal
		view
		returns (string memory)
	{
		bytes memory colorTitle = bytes(fieldGenerator.colorTitle(colors[0]));
		if (colors[1] > 0) {
			colorTitle = abi.encodePacked(
				colorTitle,
				colors[2] > 0 ? ' ' : ' and ',
				fieldGenerator.colorTitle(colors[1])
			);
		}
		if (colors[2] > 0) {
			colorTitle = abi.encodePacked(
				colorTitle,
				colors[3] > 0 ? ' ' : ' and ',
				fieldGenerator.colorTitle(colors[2])
			);
		}
		if (colors[3] > 0) {
			colorTitle = abi.encodePacked(colorTitle, ' and ', fieldGenerator.colorTitle(colors[3]));
		}
		colorTitle = abi.encodePacked(colorTitle, ' ');
		return string(colorTitle);
	}

	function generateSVG(
		string memory fieldSVG,
		string memory hardwareSVG,
		string memory frameSVG
	) internal pure returns (bytes memory svg) {
		svg = abi.encodePacked(
			'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 220 264">',
			fieldSVG,
			hardwareSVG,
			frameSVG,
			'</svg>'
		);
	}

	function generateAttributesJSON(
		IFieldSVGs.FieldData memory fieldData,
		IHardwareSVGs.HardwareData memory hardwareData,
		IFrameSVGs.FrameData memory frameData,
		uint24[4] memory colors
	) internal view returns (bytes memory attributesJSON) {
		attributesJSON = abi.encodePacked(
			'[{"trait_type":"Field", "value":"',
			fieldData.title,
			'"}, {"trait_type":"Hardware", "value":"',
			hardwareData.title,
			'"}, {"trait_type":"Status", "value":"Built',
			'"}, {"trait_type":"Field Type", "value":"',
			getFieldTypeString(fieldData.fieldType),
			'"}, {"trait_type":"Hardware Type", "value":"',
			getHardwareTypeString(hardwareData.hardwareType),
			conditionalFrameAttribute(frameData.title),
			colorAttributes(colors)
		);
	}

	function getFieldTypeString(ICategories.FieldCategories category)
		internal
		pure
		returns (string memory typeString)
	{
		if (category == ICategories.FieldCategories.BASIC) {
			typeString = 'Basic';
		} else {
			if (category == ICategories.FieldCategories.EPIC) {
				typeString = 'Epic';
			} else {
				if (category == ICategories.FieldCategories.HEROIC) {
					typeString = 'Heroic';
				} else {
					if (category == ICategories.FieldCategories.LEGENDARY) {
						typeString = 'Legendary';
					} else {
						typeString = 'Olympic';
					}
				}
			}
		}
	}

	function getHardwareTypeString(ICategories.HardwareCategories category)
		internal
		pure
		returns (string memory typeString)
	{
		if (category == ICategories.HardwareCategories.BASIC) {
			typeString = 'Basic';
		} else {
			if (category == ICategories.HardwareCategories.EPIC) {
				typeString = 'Epic';
			} else {
				if (category == ICategories.HardwareCategories.DOUBLE) {
					typeString = 'Double';
				} else {
					typeString = 'Multi';
				}
			}
		}
	}

	function conditionalFrameAttribute(string memory frameTitle)
		internal
		pure
		returns (bytes memory frameAttribute)
	{
		if (bytes(frameTitle).length > 0) {
			frameAttribute = abi.encodePacked('"}, {"trait_type":"Frame", "value":"', frameTitle);
		} else {
			frameAttribute = '';
		}
	}

	function colorAttributes(uint24[4] memory colors)
		private
		view
		returns (bytes memory colorArributes)
	{
		colorArributes = abi.encodePacked(
			'"}, {"trait_type":"Color 1", "value":"',
			fieldGenerator.colorTitle(colors[0]),
			conditionalColorAttribute(colors[1], 2),
			conditionalColorAttribute(colors[2], 3),
			conditionalColorAttribute(colors[3], 4),
			'"}]'
		);
	}

	function conditionalColorAttribute(uint24 color, uint8 nColor)
		private
		view
		returns (bytes memory colorArribute)
	{
		if (color != 0) {
			colorArribute = abi.encodePacked(
				'"}, {"trait_type":"Color ',
				nColor.toString(),
				'", "value":"',
				fieldGenerator.colorTitle(color)
			);
		} else {
			colorArribute = '';
		}
	}
}

// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

interface ICategories {
	// enum FieldCategories {
	//     MYTHIC,
	//     HERALDIC
	// }

	// enum HardwareCategories {
	//     STANDARD,
	//     SPECIAL
	// }
	enum FieldCategories {
		BASIC,
		EPIC,
		HEROIC,
		LEGENDARY,
		OLYMPIC
	}

	enum HardwareCategories {
		BASIC,
		EPIC,
		DOUBLE,
		MULTI
	}
}

// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

import './IFrameSVGs.sol';

/// @dev Generate Frame SVG
interface IFrameGenerator {
    struct FrameSVGs {
        IFrameSVGs frameSVGs1;
        IFrameSVGs frameSVGs2;
    }

    /// @param Frame uint representing Frame selection
    /// @return FrameData containing svg snippet and Frame title and Frame type
    function generateFrame(uint16 Frame) external view returns (IFrameSVGs.FrameData memory);
}

// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

import './IFieldSVGs.sol';
import './IColors.sol';

/// @dev Generate Field SVG
interface IFieldGenerator {
	/// @param field uint representing field selection
	/// @param colors to be rendered in the field svg
	/// @return FieldData containing svg snippet and field title
	function generateField(uint16 field, uint24[4] memory colors)
		external
		view
		returns (IFieldSVGs.FieldData memory);

	event ColorAdded(uint24 color, string title);

	struct Color {
		string title;
		bool exists;
	}

	function addColors(uint24[] calldata colors, string[] calldata titles) external;

	/// @notice Returns true if color exists in contract, else false.
	/// @param color 3-byte uint representing color
	/// @return true or false
	function colorExists(uint24 color) external view returns (bool);

	/// @notice Returns the title string corresponding to the 3-byte color
	/// @param color 3-byte uint representing color
	/// @return true or false
	function colorTitle(uint24 color) external view returns (string memory);

	struct FieldSVGs {
		IFieldSVGs fieldSVGs1;
		IFieldSVGs fieldSVGs2;
		IFieldSVGs fieldSVGs3;
		IFieldSVGs fieldSVGs4;
		IFieldSVGs fieldSVGs5;
		IFieldSVGs fieldSVGs6;
		IFieldSVGs fieldSVGs7;
		IFieldSVGs fieldSVGs8;
		IFieldSVGs fieldSVGs9;
		IFieldSVGs fieldSVGs10;
		IFieldSVGs fieldSVGs11;
		IFieldSVGs fieldSVGs12;
		IFieldSVGs fieldSVGs13;
		IFieldSVGs fieldSVGs14;
		IFieldSVGs fieldSVGs15;
		IFieldSVGs fieldSVGs16;
		IFieldSVGs fieldSVGs17;
		IFieldSVGs fieldSVGs18;
		IFieldSVGs fieldSVGs19;
		IFieldSVGs fieldSVGs20;
		IFieldSVGs fieldSVGs21;
		IFieldSVGs fieldSVGs22;
		IFieldSVGs fieldSVGs23;
		IFieldSVGs fieldSVGs24;
	}
}

// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

import './IHardwareSVGs.sol';

/// @dev Generate Hardware SVG
interface IHardwareGenerator {
	/// @param hardware uint representing hardware selection
	/// @return HardwareData containing svg snippet and hardware title and hardware type
	function generateHardware(uint16[9] calldata hardware)
		external
		view
		returns (IHardwareSVGs.HardwareData memory);

	struct HardwareSVGs {
		IHardwareSVGs hardwareSVGs1;
		IHardwareSVGs hardwareSVGs2;
		IHardwareSVGs hardwareSVGs3;
		IHardwareSVGs hardwareSVGs4;
		IHardwareSVGs hardwareSVGs5;
		IHardwareSVGs hardwareSVGs6;
		IHardwareSVGs hardwareSVGs7;
		IHardwareSVGs hardwareSVGs8;
		IHardwareSVGs hardwareSVGs9;
		IHardwareSVGs hardwareSVGs10;
		IHardwareSVGs hardwareSVGs11;
		IHardwareSVGs hardwareSVGs12;
		IHardwareSVGs hardwareSVGs13;
		IHardwareSVGs hardwareSVGs14;
		IHardwareSVGs hardwareSVGs15;
		IHardwareSVGs hardwareSVGs16;
		IHardwareSVGs hardwareSVGs17;
		IHardwareSVGs hardwareSVGs18;
		IHardwareSVGs hardwareSVGs19;
		IHardwareSVGs hardwareSVGs20;
		IHardwareSVGs hardwareSVGs21;
		IHardwareSVGs hardwareSVGs22;
		IHardwareSVGs hardwareSVGs23;
		IHardwareSVGs hardwareSVGs24;
		IHardwareSVGs hardwareSVGs25;
		IHardwareSVGs hardwareSVGs26;
		IHardwareSVGs hardwareSVGs27;
		IHardwareSVGs hardwareSVGs28;
		IHardwareSVGs hardwareSVGs29;
		IHardwareSVGs hardwareSVGs30;
		IHardwareSVGs hardwareSVGs31;
		IHardwareSVGs hardwareSVGs32;
		IHardwareSVGs hardwareSVGs33;
		IHardwareSVGs hardwareSVGs34;
		IHardwareSVGs hardwareSVGs35;
		IHardwareSVGs hardwareSVGs36;
		IHardwareSVGs hardwareSVGs37;
		IHardwareSVGs hardwareSVGs38;
	}
}

// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

interface IFrameSVGs {
    struct FrameData {
        string title;
        uint256 fee;
        string svgString;
    }
}

// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

/// @dev Build Customizable Shields for an NFT
interface IShieldManager {
	// enum ShieldBadge {
	// 	MAKER,
	// 	STANDARD
	// }

	struct Shield {
		bool built;
		uint16 field;
		uint16[9] hardware;
		uint16 frame;
		uint24[4] colors;
	}

	function buildShield(
		uint16 field,
		uint16[9] memory hardware,
		uint16 frame,
		uint24[4] memory colors,
		address multisigAddress,
		address builder
	) external payable;

	function shields(uint256 tokenId)
		external
		view
		returns (
			uint16 field,
			uint16[9] memory hardware,
			uint16 frame,
			uint24 color1,
			uint24 color2,
			uint24 color3,
			uint24 color4
			// ShieldBadge shieldBadge
		);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;


/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

import './ICategories.sol';

interface IFieldSVGs {
    struct FieldData {
        string title;
        ICategories.FieldCategories fieldType;
        string svgString;
    }
}

// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

interface IColors {
    event ColorAdded(uint24 color, string title);

    struct Color {
        string title;
        bool exists;
    }

    /// @notice Returns true if color exists in contract, else false.
    /// @param color 3-byte uint representing color
    /// @return true or false
    function colorExists(uint24 color) external view returns (bool);

    /// @notice Returns the title string corresponding to the 3-byte color
    /// @param color 3-byte uint representing color
    /// @return true or false
    function colorTitle(uint24 color) external view returns (string memory);
}

// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

import './ICategories.sol';

interface IHardwareSVGs {
    struct HardwareData {
        string title;
        ICategories.HardwareCategories hardwareType;
        string svgString;
    }
}
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import '@openzeppelin/contracts/utils/Strings.sol';
import '@thirdweb-dev/contracts/ThirdwebContract.sol';

import '../../interfaces/IFieldGenerator.sol';
import '../../interfaces/IHardwareGenerator.sol';
import '../../interfaces/IFrameGenerator.sol';
import '../../interfaces/IFrameSVGs.sol';
import '../../interfaces/ICategories.sol';
import '../../interfaces/IShieldManager.sol';

import '../../libraries/Base64.sol';

/// @dev Generate Shield Metadata
/// @author modified from Area-Technology (https://github.com/Area-Technology/shields-contracts/tree/main/contracts)
contract EmblemWeaver is ThirdwebContract {
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

	function generateShieldPass() external pure returns (string memory) {
		return
			string(
				abi.encodePacked(
					'data:application/json;base64,',
					Base64.encode(
						bytes(
							abi.encodePacked(
								'{"name":"Shield Pass", "description":"An unused Shield Pass. Can be used to build 1 shield or enter a race mint.", "image": "data:image/svg+xml;base64,',
								Base64.encode(
									'<svg width="148" height="240" fill="none" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><defs><radialGradient id="a" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="matrix(64.40632 -58.4298 54.32565 59.88238 41.38 144.87)"><stop stop-color="#FF72B4"/><stop offset="0" stop-color="#FF72B4"/><stop offset=".06" stop-color="#FF77A6"/><stop offset=".15" stop-color="#FF7D99"/><stop offset=".24" stop-color="#FF858E"/><stop offset=".29" stop-color="#FF8D86"/><stop offset=".38" stop-color="#FF9083"/><stop offset=".46" stop-color="#FF957F"/><stop offset=".52" stop-color="#FF9D7A"/><stop offset=".6" stop-color="#FFA675"/><stop offset=".71" stop-color="#FFB16F"/><stop offset=".81" stop-color="#FFBD69"/><stop offset=".9" stop-color="#FFCA65"/><stop offset="1" stop-color="#FFD863"/></radialGradient><pattern id="b" patternContentUnits="objectBoundingBox" width=".53" height=".33"><use xlink:href="#image0_1231_2623" transform="scale(.00243 .00149)"/></pattern><filter id="e" width="200%" height="200%" x="-40%" y="-40%"><feFlood flood-color="transparent" result="neutral"/><feGaussianBlur in="SourceGraphic" stdDeviation="12" result="blurred"/><feMerge><feMergeNode in="neutral"/><feMergeNode in="blurred"/></feMerge></filter><circle cx="74.4" cy="119.57" r="47.58" fill="url(#a)" id="d"/><path d="M.8 14.26C.8 6.38 7.18 0 15.06 0h118.32c7.88 0 14.26 6.38 14.26 14.26V225.6c0 7.88-6.38 14.26-14.26 14.26H15.06A14.26 14.26 0 0 1 .8 225.6V14.26Z" fill="#37373d" id="c"/><g id="f"><rect style="mix-blend-mode:overlay" opacity=".3" x=".8" width="146.84" height="239.86" rx="14.26" fill="url(#b)"/><path d="M15.77 214.89c-.74 0-1.4-.15-2-.46a3.68 3.68 0 0 1-1.44-1.48l1.56-.99c.22.45.5.78.84 1 .35.22.74.33 1.15.33.4 0 .73-.1.97-.29a.89.89 0 0 0 .37-.74.94.94 0 0 0-.27-.7 1.86 1.86 0 0 0-.69-.42 9.4 9.4 0 0 0-1.09-.34 3.48 3.48 0 0 1-1.68-.92c-.4-.41-.59-.95-.59-1.61 0-.53.13-1 .4-1.4a2.59 2.59 0 0 1 1.11-.95 3.88 3.88 0 0 1 1.66-.33 3.28 3.28 0 0 1 2.96 1.66l-1.54.95a2.46 2.46 0 0 0-.68-.77 1.4 1.4 0 0 0-.83-.24c-.37 0-.67.1-.9.27a.87.87 0 0 0-.35.72c0 .3.12.52.35.68.23.14.6.3 1.08.45.6.19 1.08.36 1.44.52.36.17.69.44 1 .82.3.38.46.88.46 1.5a2.63 2.63 0 0 1-.4 1.44c-.26.41-.65.73-1.14.97-.5.22-1.08.33-1.75.33Zm4.08-9.53h1.73v3.61c.36-.71 1.03-1.07 2.02-1.07a2.47 2.47 0 0 1 2.2 1.3c.22.42.34.9.34 1.44v4.08H24.4v-3.65c0-.56-.12-.97-.38-1.25-.26-.27-.6-.4-1.05-.4a1.3 1.3 0 0 0-.99.41c-.27.28-.4.69-.4 1.24v3.65h-1.73v-9.36Zm7.25 2.7h1.74v6.66H27.1v-6.67Zm-.18-1.59c0-.28.1-.52.3-.72.2-.2.45-.3.74-.3.3 0 .55.1.75.3a.98.98 0 0 1 .3.72 1 1 0 0 1-1.05 1.03c-.29 0-.53-.1-.74-.3a1.02 1.02 0 0 1-.3-.73Zm6.14 8.42c-.68 0-1.28-.15-1.8-.46a3.34 3.34 0 0 1-1.22-1.27 3.6 3.6 0 0 1-.44-1.76 3.55 3.55 0 0 1 1.68-3.04 3.38 3.38 0 0 1 1.77-.48c.66 0 1.24.16 1.75.48a3.22 3.22 0 0 1 1.2 1.28 3.6 3.6 0 0 1 .4 2.38h-5c.1.4.3.72.58.97.29.24.65.36 1.08.36.35 0 .68-.08.96-.24.28-.17.5-.4.66-.66l1.35 1.02c-.27.42-.67.77-1.2 1.03a4 4 0 0 1-1.77.39Zm1.64-4.17a1.88 1.88 0 0 0-.6-.96 1.58 1.58 0 0 0-1.07-.39c-.4 0-.75.13-1.05.37-.3.25-.48.58-.58.98h3.3Zm2.5-5.36h1.74v9.36H37.2v-9.36Zm5.8 9.53c-.6 0-1.15-.15-1.65-.46a3.5 3.5 0 0 1-1.21-1.27 3.57 3.57 0 0 1-.44-1.75 3.58 3.58 0 0 1 1.65-3.03 3.06 3.06 0 0 1 1.65-.47c.55 0 .99.1 1.32.3.34.2.6.5.79.87v-3.72h1.73v9.36h-1.68v-1.09a2.28 2.28 0 0 1-.81.94c-.34.21-.79.32-1.35.32Zm-1.56-3.5c0 .35.07.67.23.97.16.3.38.53.65.7.28.18.6.26.96.26a1.84 1.84 0 0 0 1.65-.95c.15-.29.23-.6.23-.96s-.08-.67-.23-.96a1.71 1.71 0 0 0-.67-.7 1.78 1.78 0 0 0-.98-.27c-.36 0-.68.09-.96.26a1.76 1.76 0 0 0-.65.7c-.16.29-.23.6-.23.96Zm8.66-5.65h3.03c1.02 0 1.82.25 2.38.73.58.48.86 1.18.86 2.1 0 .94-.28 1.65-.86 2.15a3.5 3.5 0 0 1-2.38.74H51.9v3.26h-1.8v-8.98Zm2.93 4.1c1.01 0 1.52-.41 1.52-1.25 0-.42-.13-.73-.4-.94-.25-.2-.63-.3-1.13-.3H51.9v2.5h1.13Zm6.72 5.05c-.6 0-1.15-.15-1.65-.46a3.5 3.5 0 0 1-1.2-1.27 3.57 3.57 0 0 1-.44-1.75c0-.63.14-1.21.43-1.74a3.48 3.48 0 0 1 1.2-1.29 3.06 3.06 0 0 1 1.66-.47c.55 0 1 .1 1.32.3.35.21.61.5.8.9v-1.06h1.72v6.67h-1.68v-1.09a2.28 2.28 0 0 1-.81.94c-.33.21-.78.32-1.35.32Zm-1.56-3.5c0 .35.08.67.23.97a2 2 0 0 0 .65.7c.29.18.6.26.97.26.36 0 .69-.08.97-.25a1.73 1.73 0 0 0 .67-.7c.15-.29.23-.6.23-.96s-.08-.67-.23-.96a1.71 1.71 0 0 0-.67-.7 1.78 1.78 0 0 0-.97-.27c-.36 0-.68.09-.97.26-.28.18-.5.4-.65.7-.16.29-.23.6-.23.96Zm8.71 3.5a3.63 3.63 0 0 1-2.77-1.17l1.17-1.06c.49.54 1 .82 1.56.82.3 0 .52-.07.68-.2a.6.6 0 0 0 .25-.5.49.49 0 0 0-.25-.43 3.2 3.2 0 0 0-.97-.35c-.81-.2-1.36-.46-1.64-.8a1.97 1.97 0 0 1-.41-1.28c0-.6.22-1.08.66-1.46a2.69 2.69 0 0 1 1.83-.58c.55 0 1.02.09 1.4.26.38.17.74.47 1.07.9l-1.26.96c-.3-.48-.69-.72-1.18-.72-.24 0-.45.05-.6.16a.48.48 0 0 0-.23.43c0 .14.06.26.17.36.12.1.36.19.73.28.91.24 1.54.54 1.87.89.34.35.51.8.51 1.33 0 .4-.11.77-.34 1.1-.23.33-.53.59-.93.78a3.03 3.03 0 0 1-1.32.28Zm5.55 0a3.62 3.62 0 0 1-2.77-1.17l1.17-1.06c.49.54 1 .82 1.56.82.3 0 .52-.07.68-.2a.6.6 0 0 0 .25-.5.49.49 0 0 0-.25-.43 3.2 3.2 0 0 0-.97-.35c-.81-.2-1.36-.46-1.64-.8a1.97 1.97 0 0 1-.41-1.28c0-.6.22-1.08.66-1.46a2.7 2.7 0 0 1 1.83-.58c.55 0 1.02.09 1.4.26.38.17.74.47 1.07.9l-1.26.96c-.3-.48-.69-.72-1.18-.72-.24 0-.45.05-.6.16a.48.48 0 0 0-.23.43c0 .14.06.26.17.36.12.1.36.19.73.28.91.24 1.54.54 1.87.89.34.35.51.8.51 1.33 0 .4-.11.77-.34 1.1-.22.33-.53.59-.93.78a3.03 3.03 0 0 1-1.32.28Z" fill="#fff" fill-opacity=".6"/><path fill-rule="evenodd" clip-rule="evenodd" d="M55.27 82.68a5.87 5.87 0 0 0-5.77 6.66 39.14 39.14 0 0 0-13.45 21.45 39.11 39.11 0 0 0 3.05 26.35 39.16 39.16 0 0 0 19.18 18.36 39.21 39.21 0 0 0 26.48 1.93 16.9 16.9 0 0 1-1.3-4.66 34.36 34.36 0 0 1-23.21-1.69 34.32 34.32 0 0 1-16.8-16.09 34.28 34.28 0 0 1-2.68-23.1 34.3 34.3 0 0 1 11.34-18.42 5.85 5.85 0 0 0 3.27.96 5.87 5.87 0 0 0 5.82-5.93 5.87 5.87 0 0 0-5.93-5.82Zm.02 2.25a3.62 3.62 0 0 1 3.66 3.6c.02 2-1.59 3.63-3.6 3.65a3.62 3.62 0 0 1-3.65-3.6 3.62 3.62 0 0 1 3.6-3.65Zm41.22 62.81.3.37a3.62 3.62 0 0 1-2.95 5.69 3.62 3.62 0 0 1-3.66-3.58 3.62 3.62 0 0 1 3.58-3.67 3.62 3.62 0 0 1 2.73 1.2Zm3.15 1.74a39.13 39.13 0 0 0 12.82-21.44 39.1 39.1 0 0 0-3.37-26.06A39.16 39.16 0 0 0 90 83.92 39.2 39.2 0 0 0 63.78 82a13.85 13.85 0 0 1 1.29 4.67 34.36 34.36 0 0 1 22.98 1.68 34.32 34.32 0 0 1 16.74 15.83 34.28 34.28 0 0 1-7.7 41.11 5.85 5.85 0 0 0-3.34-.99 5.87 5.87 0 0 0-5.8 5.95 5.87 5.87 0 0 0 5.94 5.8 5.87 5.87 0 0 0 5.77-6.57Z" fill="#fff" fill-opacity=".4"/><path d="M93.78 119.73a19.58 19.58 0 1 1-39.16-.01 19.58 19.58 0 0 1 39.16.01Zm-34.4 0a14.8 14.8 0 1 0 29.6 0 14.8 14.8 0 0 0-29.6 0Z" fill="#fff" fill-opacity=".4"/></g></defs><use xlink:href="#c"/><use xlink:href="#d" style="filter:url(#e)"/><use xlink:href="#f" opacity=".8"/></svg>'
								),
								'", "attributes": [{"trait_type": "Status", "value":"Unbuilt"}]}'
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
					if (category == ICategories.FieldCategories.OLYMPIC) {
						typeString = 'Olympic';
					} else {
						typeString = 'Legendary';
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./feature/Ownable.sol";
import "./interfaces/IContractDeployer.sol";

contract ThirdwebContract is Ownable {
    uint256 private hasSetOwner;

    /// @dev Initializes the owner of the contract.
    function tw_initializeOwner(address deployer) external {
        require(hasSetOwner == 0, "Owner already initialized");
        hasSetOwner = 1;
        owner = deployer;
    }

    /// @dev Returns whether owner can be set
    function _canSetOwner() internal virtual override returns (bool) {
        return msg.sender == owner;
    }

    /// @dev Enable access to the original contract deployer in the constructor. If this function is called outside of a constructor, it will return address(0) instead.
    function _contractDeployer() internal view returns (address) {
        if (address(this).code.length == 0) {
            try IContractDeployer(msg.sender).getContractDeployer(address(this)) returns (address deployer) {
                return deployer;
            } catch {
                return address(0);
            }
        }
        return address(0);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import './ICategories.sol';

interface IFrameSVGs {
	struct FrameData {
		string title;
		ICategories.FrameCategories frameType;
		string svgString;
	}
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

interface ICategories {
	enum FieldCategories {
		BASIC,
		EPIC,
		HEROIC,
		OLYMPIC,
		LEGENDARY
	}

	enum HardwareCategories {
		BASIC,
		EPIC,
		DOUBLE,
		MULTI
	}

	enum FrameCategories {
		NONE,
		ADORNED,
		MENACING,
		SECURED,
		FLORIATED,
		EVERLASTING
	}
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

/// @dev Build Customizable Shields for an NFT
interface IShieldManager {
	enum WhitelistItems {
		MINT_SHIELD_PASS,
		HALF_PRICE_BUILD,
		FREE_BUILD
	}

	struct Shield {
		uint16 field;
		uint16[9] hardware;
		uint16 frame;
		uint24[4] colors;
		bytes32 shieldHash;
		bytes32 hardwareConfiguration;
	}

	function mintShieldPass(address to) external payable returns (uint256);

	function buildShield(
		uint16 field,
		uint16[9] memory hardware,
		uint16 frame,
		uint24[4] memory colors,
		uint256 tokenId
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
	bytes internal constant TABLE =
		'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

	/// @notice Encodes some bytes to the base64 representation
	function encode(bytes memory data) internal pure returns (string memory) {
		uint256 len = data.length;
		if (len == 0) return '';

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
				out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
				out := shl(8, out)
				out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
				out := shl(8, out)
				out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./interface/IOwnable.sol";

abstract contract Ownable is IOwnable {
    /// @dev Owner of the contract (purpose: OpenSea compatibility)
    address public override owner;

    /// @dev Lets a contract admin set a new owner for the contract. The new owner must be a contract admin.
    function setOwner(address _newOwner) public override {
        require(_canSetOwner(), "Not authorized");

        address _prevOwner = owner;
        owner = _newOwner;

        emit OwnerUpdated(_prevOwner, _newOwner);
    }

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal virtual returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IContractDeployer {
    /// @dev Emitted when the registry is paused.
    event Paused(bool isPaused);

    /// @dev Emitted when a contract is deployed.
    event ContractDeployed(address indexed deployer, address indexed publisher, address deployedContract);

    /**
     *  @notice Deploys an instance of a published contract directly.
     *
     *  @param publisher        The address of the publisher.
     *  @param contractBytecode The bytecode of the contract to deploy.
     *  @param constructorArgs  The encoded constructor args to deploy the contract with.
     *  @param salt             The salt to use in the CREATE2 contract deployment.
     *  @param value            The native token value to pass to the contract on deployment.
     *  @param publishMetadataUri     The publish metadata URI for the contract to deploy.
     *
     *  @return deployedAddress The address of the contract deployed.
     */
    function deployInstance(
        address publisher,
        bytes memory contractBytecode,
        bytes memory constructorArgs,
        bytes32 salt,
        uint256 value,
        string memory publishMetadataUri
    ) external returns (address deployedAddress);

    /**
     *  @notice Deploys a clone pointing to an implementation of a published contract.
     *
     *  @param publisher        The address of the publisher.
     *  @param implementation   The contract implementation for the clone to point to.
     *  @param initializeData   The encoded function call to initialize the contract with.
     *  @param salt             The salt to use in the CREATE2 contract deployment.
     *  @param value            The native token value to pass to the contract on deployment.
     *  @param publishMetadataUri     The publish metadata URI and for the contract to deploy.
     *
     *  @return deployedAddress The address of the contract deployed.
     */
    function deployInstanceProxy(
        address publisher,
        address implementation,
        bytes memory initializeData,
        bytes32 salt,
        uint256 value,
        string memory publishMetadataUri
    ) external returns (address deployedAddress);

    function getContractDeployer(address _contract) external view returns (address);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IOwnable {
    /// @dev Returns the owner of the contract.
    function owner() external view returns (address);

    /// @dev Lets a module admin set a new owner for the contract. The new owner must be a module admin.
    function setOwner(address _newOwner) external;

    /// @dev Emitted when a new Owner is set.
    event OwnerUpdated(address prevOwner, address newOwner);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import './ICategories.sol';

interface IFieldSVGs {
	struct FieldData {
		string title;
		ICategories.FieldCategories fieldType;
		string svgString;
	}
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import './ICategories.sol';

interface IHardwareSVGs {
	struct HardwareData {
		string title;
		ICategories.HardwareCategories hardwareType;
		string svgString;
	}
}
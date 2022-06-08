// SPDX-License-Identifier: MIT
/// @author modified from Area-Technology (https://github.com/Area-Technology/shields-contracts/tree/main/contracts)

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
								'{"name":"Shield Pass", "description":"An unused Shield Badge. Can be used to build 1 Shield.", "image": "data:image/svg+xml;base64,',
								Base64.encode(
									'<svg xmlns="http://www.w3.org/2000/svg" xml:space="preserve" viewBox="0 0 500 600"><linearGradient id="a" x1="110.5" x2="389.5" y1="82.68" y2="82.68" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#4b4b4b"/><stop offset=".5" stop-color="gray"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><path fill="url(#a)" d="M377.14 76.5H122.86a12.37 12.37 0 0 0-12.36 12.36h279c0-6.82-5.54-12.36-12.36-12.36z"/><path fill="#1E1E1E" d="M122.86 521.5a12.37 12.37 0 0 1-12.36-12.36V90.86c0-6.82 5.54-12.36 12.36-12.36h254.28c6.82 0 12.36 5.54 12.36 12.36v418.28c0 6.82-5.54 12.36-12.36 12.36H122.86z"/><path fill="none" stroke="gray" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="3" d="M356.36 151.31a26.98 26.98 0 0 0 0-26.83m-5.46 23.68c4.19-7.22 2.96-15.43 0-20.53m-5.45 17.38a14.1 14.1 0 0 0 0-14.24M340 141.86a8.1 8.1 0 0 0 0-7.94"/><path fill="none" stroke="gray" stroke-miterlimit="10" d="M250 198.02v312m-110-312v312m110 0v-24"/><path fill="none" stroke="gray" stroke-miterlimit="10" stroke-width=".91" d="M120 354.02h260m-260 132h260m-260-264h260"/><path fill="none" stroke="gray" stroke-miterlimit="10" d="M360 198.02v312"/><path fill="#1E1E1E" d="M370 496.02v-284H130v284h240z"/><g stroke="#1E1E1E" stroke-miterlimit="10" stroke-width="3"><path fill="#4B4B4B" d="M360 222.02H140v264h220v-264"/><path fill="none" d="M150 222.02v264m10-264v264m10-264v264m10-264v264m10-264v264m10-264v264m10-264v264m10-264v264m10-264v264m10-264v264m10-264v264m10-264v264m10-264v264m10-264v264m10-264v264m10-264v264m10-264v264m10-264v264m10-264v264m10-264v264m10-264v264m-210-12h220m-220-12h220m-220-12h220m-220-12h220m-220-12h220m-220-12h220m-220-12h220m-220-12h220m-220-12h220m-220-12h220m-220-12h220m-220-12h220m-220-12h220m-220-12h220m-220-12h220m-220-12h220m-220-12h220m-220-12h220m-220-12h220m-220-12h220m-220-12h220"/></g><g fill="none" stroke="#1E1E1E" stroke-miterlimit="10" stroke-width="4"><circle cx="200" cy="354" r="3"/><circle cx="225" cy="324" r="3"/><circle cx="225" cy="384" r="3"/><circle cx="275" cy="324" r="3"/><circle cx="275" cy="384" r="3"/><circle cx="250" cy="354" r="3"/><circle cx="300" cy="354" r="3"/><circle cx="250" cy="414" r="3"/><circle cx="200" cy="294" r="3"/><circle cx="250" cy="294" r="3"/><circle cx="300" cy="294" r="3"/></g><path fill="none" stroke="#1E1E1E" stroke-miterlimit="10" stroke-width="4" d="M244.42 318.1v21.72a14.48 14.48 0 1 1-28.96 0V318.1h28.96zm40.12 0v21.72a14.48 14.48 0 1 1-28.96 0V318.1h28.96zm-20.06 45.4v21.72a14.48 14.48 0 1 1-28.96 0V363.5h28.96z"/><path fill="none" stroke="#1E1E1E" stroke-width="4" d="M250 486.02v-264m110 0H140v264h220v-264zm0 132H140"/><g fill="none" stroke-miterlimit="10"><path stroke="#1E1E1E" stroke-width="4" d="m140 486.02 220-264m0 264-220-264m110 264v-264m0 192-50-60m50 60 50-60m-50-60-50 60m50-60 50 60m0 14.98a50.01 50.01 0 0 1-50 50 50.04 50.04 0 0 1-35.36-14.64A50.04 50.04 0 0 1 200 369v-75h100v75zm60-14.98H140m220-132H140v264h220v-264z"/><path stroke="gray" d="m140 486.02 220-264m0 264-220-264m110 264v-264m0 192-50-60m50 60 50-60m-50-60-50 60m50-60 50 60m0 14.98a50.01 50.01 0 0 1-50 50 50.04 50.04 0 0 1-35.36-14.64A50.04 50.04 0 0 1 200 369v-75h100v75zm60-14.98H140m220-132H140v264h220v-264z"/></g><g fill="gray"><circle cx="200" cy="354" r="3"/><circle cx="225" cy="324" r="3"/><circle cx="225" cy="384" r="3"/><circle cx="275" cy="324" r="3"/><circle cx="275" cy="384" r="3"/><circle cx="250" cy="354" r="3"/><circle cx="300" cy="354" r="3"/><circle cx="250" cy="414" r="3"/><circle cx="200" cy="294" r="3"/><circle cx="250" cy="294" r="3"/><circle cx="300" cy="294" r="3"/></g><linearGradient id="b" x1="146.83" x2="159.59" y1="174.76" y2="144.22" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#66b2ff"/><stop offset="1" stop-color="#007fff"/></linearGradient><path fill="url(#b)" d="m186 108 .9 2.16-8.2 9.84h-2.4l-8.2-9.84.9-2.16h17zm.41 29 .49-1.16-8.2-9.84h-2.4l-8.2 9.84.49 1.16h17.82zm-19.9-25.63-.51.22v22.82l.51.22 8-9.59V121l-8-9.63zM164 134.41v-22.82l-.51-.22-7.99 9.63v4l8 9.59.5-.18zM151.3 126l-8.2 9.84.49 1.16h17.82l.49-1.16-8.2-9.84h-2.4zm29.2 25v4l4 4.73h1.07a24.81 24.81 0 0 0 4.43-14.24V142l-1.51-.62-7.99 9.62zm-31 0-8-9.58-1.5.58v3.5a24.89 24.89 0 0 0 4.48 14.28h1.07l4-4.74-.05-4.04zm31-30v4l8 9.59 1.5-.59v-22l-1.51-.63-7.99 9.63zm2.64 40.38L178.7 156h-2.4l-8.3 10v3.6l1.06.61a24.9 24.9 0 0 0 14.09-7.48l-.01-1.35zM178.7 150l8.2-9.84-.49-1.16h-17.82l-.49 1.16 8.2 9.84h2.4zM162 169.58V166l-8.3-10h-2.4l-4.44 5.34v1.35a25 25 0 0 0 14.14 7.49l1-.6zM174.5 151l-8-9.59-.51.22V164l.73.36 7.78-9.36v-4zM164 164v-22.41l-.51-.22-7.99 9.63v4l7.77 9.32.73-.32zm-22.49-29.37 8-9.59V121l-8-9.59-1.51.59v22l1.51.63zM153.7 150l8.2-9.84-.49-1.16h-17.82l-.49 1.16 8.2 9.84h2.4zm-9.7-42-.9 2.16 8.2 9.84h2.4l8.2-9.84-.9-2.16h-17z"/><path fill="gray" d="M244.42 318.1v21.72a14.48 14.48 0 1 1-28.96 0V318.1h28.96zm40.12 0v21.72a14.48 14.48 0 1 1-28.96 0V318.1h28.96zm-20.06 45.4v21.72a14.48 14.48 0 1 1-28.96 0V363.5h28.96z"/></svg>'
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import './ICategories.sol';

interface IFrameSVGs {
	struct FrameData {
		string title;
		ICategories.FrameCategories frameType;
		string svgString;
	}
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @dev Build Customizable Shields for an NFT
interface IShieldManager {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import './ICategories.sol';

interface IFieldSVGs {
	struct FieldData {
		string title;
		ICategories.FieldCategories fieldType;
		string svgString;
	}
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import './ICategories.sol';

interface IHardwareSVGs {
	struct HardwareData {
		string title;
		ICategories.HardwareCategories hardwareType;
		string svgString;
	}
}
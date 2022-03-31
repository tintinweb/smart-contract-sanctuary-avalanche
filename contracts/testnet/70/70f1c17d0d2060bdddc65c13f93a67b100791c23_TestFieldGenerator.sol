// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

import '../interfaces/IFieldGenerator.sol';
import '../interfaces/IFieldSVGs.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

/// @dev Test Field Generator with less SVGs / less deploy overhead
contract TestFieldGenerator is IFieldGenerator {
    using Strings for uint16;

    mapping(uint24 => Color) public _colors;

    struct TestFieldSVGs {
        IFieldSVGs fieldSVGs1;
        IFieldSVGs fieldSVGs2;
    }

    IFieldSVGs immutable fieldSVGs1;
    IFieldSVGs immutable fieldSVGs2;

    constructor(
        uint24[] memory __colors,
        string[] memory titles,
        TestFieldSVGs memory svgs
    ) {
        require(__colors.length == titles.length, 'invalid array lengths');
        for (uint256 i = 0; i < __colors.length; i++) {
            _colors[__colors[i]] = Color({title: titles[i], exists: true});
            emit ColorAdded(__colors[i], titles[i]);
        }

        fieldSVGs1 = svgs.fieldSVGs1;
        fieldSVGs2 = svgs.fieldSVGs2;
    }

    function colorExists(uint24 color) public view override returns (bool) {
        return _colors[color].exists;
    }

    function colorTitle(uint24 color) public view override returns (string memory) {
        return _colors[color].title;
    }

    function callFieldSVGs(
        IFieldSVGs target,
        uint16 field,
        uint24[4] memory colors
    ) internal view returns (IFieldSVGs.FieldData memory) {
        bytes memory functionSelector = abi.encodePacked('field_', uint16(field).toString(), '(uint24[4])');

        bool success;
        bytes memory result;
        (success, result) = address(target).staticcall(
            abi.encodeWithSelector(bytes4(keccak256(functionSelector)), colors)
        );

        return abi.decode(result, (IFieldSVGs.FieldData));
    }

    function generateField(uint16 field, uint24[4] memory colors)
        external
        view
        override
        returns (IFieldSVGs.FieldData memory)
    {
        if (field <= 28) {
            return callFieldSVGs(fieldSVGs1, field, colors);
        }

        if (field <= 50) {
            return callFieldSVGs(fieldSVGs2, field, colors);
        }
        revert('invalid field selection');
    }
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
    function generateField(uint16 field, uint24[4] memory colors) external view returns (IFieldSVGs.FieldData memory);

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

import './ICategories.sol';

interface IFieldSVGs {
    struct FieldData {
        string title;
        ICategories.FieldCategories fieldType;
        string svgString;
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

interface ICategories {
    enum FieldCategories {
        MYTHIC,
        HERALDIC
    }

    enum HardwareCategories {
        STANDARD,
        SPECIAL
    }
}
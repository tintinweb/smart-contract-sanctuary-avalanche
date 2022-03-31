// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

import '../interfaces/IHardwareGenerator.sol';
import '../interfaces/IHardwareSVGs.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

/// @dev Test Hardware Generator with less SVGs / less deploy overhead
contract TestHardwareGenerator is IHardwareGenerator {
    using Strings for uint16;

    IHardwareSVGs immutable hardwareSVGs1;
    // needed to scrounge for a MYTHIC hardware
    IHardwareSVGs immutable hardwareSVGs29;

    struct TestHardwardSVGs {
        IHardwareSVGs hardwareSVGs1;
        IHardwareSVGs hardwareSVGs29;
    }

    constructor(TestHardwardSVGs memory svgs) {
        hardwareSVGs1 = svgs.hardwareSVGs1;
        hardwareSVGs29 = svgs.hardwareSVGs29;
    }

    function callHardwareSVGs(IHardwareSVGs target, uint16 hardware)
        internal
        view
        returns (IHardwareSVGs.HardwareData memory)
    {
        bytes memory functionSelector = abi.encodePacked('hardware_', uint16(hardware).toString(), '()');

        bool success;
        bytes memory result;
        (success, result) = address(target).staticcall(abi.encodeWithSelector(bytes4(keccak256(functionSelector))));

        return abi.decode(result, (IHardwareSVGs.HardwareData));
    }

    function generateHardware(uint16 hardware) external view override returns (IHardwareSVGs.HardwareData memory) {
        if (hardware <= 5) {
            return callHardwareSVGs(hardwareSVGs1, hardware);
        }

        // needed to scrounge for a MYTHIC hardware
        if (hardware == 96 || hardware == 97) {
            return callHardwareSVGs(hardwareSVGs29, hardware);
        }

        revert('invalid hardware selection');
    }
}

// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

import './IHardwareSVGs.sol';

/// @dev Generate Hardware SVG
interface IHardwareGenerator {

    /// @param hardware uint representing hardware selection
    /// @return HardwareData containing svg snippet and hardware title and hardware type
    function generateHardware(uint16 hardware) external view returns (IHardwareSVGs.HardwareData memory);

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

import './ICategories.sol';

interface IHardwareSVGs {
    struct HardwareData {
        string title;
        ICategories.HardwareCategories hardwareType;
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
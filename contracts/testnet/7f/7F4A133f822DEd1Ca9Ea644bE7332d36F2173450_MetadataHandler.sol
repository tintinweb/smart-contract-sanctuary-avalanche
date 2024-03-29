pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/Base64.sol";

contract MetadataHandler {
    function getTokenURI(uint256 id_, uint8 tier_, uint16 eeRate_, uint16 egRate_, uint16 lucky_, uint16 protection_, uint16 durability_, uint16 star_) public view returns (string memory) {
        return
            string (
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',_getName(id_),'", "description":"Ecycle",',
                                getAttributes(tier_, eeRate_, egRate_, lucky_, protection_, durability_, star_),
                                '}'
                            )
                        )
                    )
                )
            );
    }

    function getAttributes(uint8 tier_, uint16 eeRate_, uint16 egRate_, uint16 lucky_, uint16 protection_, uint16 durability_, uint16 star_) internal view returns (string memory) {
        return string(abi.encodePacked(
                '"attributes": [',
                getEERate(eeRate_), ',',
                getEGRate(egRate_), ',',
                getLucky(lucky_), ',',
                getProtection(protection_), ',',
                getTier(tier_), ',',
                '{"trait_type": "durability","display_type": "number","value":', toString(durability_), '}',
                ',{"trait_type": "level", "value":', toString(star_),
                '}]'));
    }

    function getTier(uint8 tier_) internal view returns (string memory) {
        string memory tier;
        if (tier_ == 1) tier = "A";
        if (tier_ == 2) tier = "B";
        if (tier_ == 3) tier = "C";
        if (tier_ == 4) tier = "D";
        if (tier_ == 5) tier = "S";
        return string(abi.encodePacked('{"trait_type":"Tier","value":"',toString(tier_),'"}'));
    }

    function getEERate(uint16 eeRate_) internal view returns (string memory) {
        return string(abi.encodePacked('{"trait_type":"EE earning rate","display_type": "number","value":"',toString(eeRate_),'"}'));
    }

    function getEGRate(uint16 egRate_) internal view returns (string memory) {
        return string(abi.encodePacked('{"trait_type":"EG earning rate","display_type": "number","value":"',toString(egRate_),'"}'));
    }

    function getLucky(uint16 lucky_) internal view returns (string memory) {
        return string(abi.encodePacked('{"trait_type":"Lucky","display_type": "number","value":"',toString(lucky_),'"}'));
    }

    function getProtection(uint16 protection_) internal view returns (string memory) {
        return string(abi.encodePacked('{"trait_type":"Protection","display_type": "number","value":"',toString(protection_),'"}'));
    }

    function _getName(uint256 bikeId) internal view returns (string memory) {
        return string(abi.encodePacked("Orc #", toString(bikeId)));
    }

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}
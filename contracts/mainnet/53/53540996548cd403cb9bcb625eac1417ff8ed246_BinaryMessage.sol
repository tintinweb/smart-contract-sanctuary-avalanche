/**
 *Submitted for verification at snowtrace.io on 2023-07-12
*/

// SPDX-License-Identifier:MIT>

pragma solidity ^0.8.0;

contract BinaryMessage {
    string public message;

    constructor() {
        message = binaryToString("01101000011001010110110001110000");
    }

    function binaryToString(string memory binary)
        internal
        pure
        returns (string memory)
    {
        bytes memory binaryBytes = bytes(binary);
        bytes memory messageBytes = new bytes(binaryBytes.length / 8);

        for (uint256 i = 0; i < binaryBytes.length; i += 8) {
            uint8 character = 0;
            for (uint256 j = 0; j < 8; j++) {
                if (binaryBytes[i + j] == "1") {
                    character |= uint8(1) << uint8(7 - j);
                }
            }
            messageBytes[i / 8] = bytes1(character);
        }

        return string(messageBytes);
    }
}
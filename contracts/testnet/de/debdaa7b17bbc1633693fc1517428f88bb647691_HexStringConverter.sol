// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @author Mikhail Vladimirov
 */
library HexStringConverter {
  /**
   * @notice Converts bytes32 data to hex string, notice that the output is in uppercase
   * @dev Splits a bytes32 value into two bytes16 chunks, converts each chunk to hexadecimal representation via
   * the toHex16 function, and finally concatenates the 0x prefix with the converted chunks using abi.encodePacked function.
   * @param data bytes32 data to convert to hex string
   */
  function toHexString(bytes32 data) public pure returns (string memory) {
    return string(abi.encodePacked('0x', _toHex16(bytes16(data)), _toHex16(bytes16(data << 128))));
  }

  /**
   * @dev Converts a sequence of 16 bytes represented as a bytes16 value into a sequence of 32 hexadecimal digits
   * represented as a bytes32 value.
   */
  function _toHex16(bytes16 data) internal pure returns (bytes32 result) {
    // shift the last 64 bits of the input to the right by 64 bits, like:
    // 0123456789abcdeffedcba9876543210
    // \______________/\______________/
    //        |              |
    //        |              +----------------+
    //  ______V_______                 ______V_______
    // /              \               /              \
    // 0123456789abcdef0000000000000000fedcba9876543210
    result =
      (bytes32(data) & 0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000) |
      ((bytes32(data) & 0x0000000000000000FFFFFFFFFFFFFFFF00000000000000000000000000000000) >> 64);

    // shift the last 32 bits of both 64-bit chunks to the right by 32 bits, like:
    // 0123456789abcdef0000000000000000fedcba9876543210
    // \______/\______/                \______/\______/
    //    |       |                       |       |
    //    |       +-------+               |       +-------+
    //  __V___          __V___          __V___          __V___
    // /      \        /      \        /      \        /      \
    // 012345670000000089abcdef00000000fedcba980000000076543210
    result =
      (result & 0xFFFFFFFF000000000000000000000000FFFFFFFF000000000000000000000000) |
      ((result & 0x00000000FFFFFFFF000000000000000000000000FFFFFFFF0000000000000000) >> 32);

    // The next sentence does like:
    // 012345670000000089abcdef00000000fedcba980000000076543210
    // \__/\__/        \__/\__/        \__/\__/        \__/\__/
    //  |   |           |   |           |   |           |   |
    //  |   +---+       |   +---+       |   +---+       |   +---+
    //  V_      V_      V_      V_      V_      V_      V_      V_
    // /  \    /  \    /  \    /  \    /  \    /  \    /  \    /  \
    // 012300004567000089ab0000cdef0000fedc0000ba980000765400003210
    result =
      (result & 0xFFFF000000000000FFFF000000000000FFFF000000000000FFFF000000000000) |
      ((result & 0x0000FFFF000000000000FFFF000000000000FFFF000000000000FFFF00000000) >> 16);

    // The next sentence does:
    // 012300004567000089ab0000cdef0000fedc0000ba980000765400003210
    // \/\/    \/\/    \/\/    \/\/    \/\/    \/\/    \/\/    \/\/
    // | |     | |     | |     | |     | |     | |     | |     | |
    // | +-+   | +-+   | +-+   | +-+   | +-+   | +-+   | +-+   | +-+
    // V   V   V   V   V   V   V   V   V   V   V   V   V   V   V   V
    // /\  /\  /\  /\  /\  /\  /\  /\  /\  /\  /\  /\  /\  /\  /\  /\
    // 01002300450067008900ab00cd00ef00fe00dc00ba00980076005400320010
    result =
      (result & 0xFF000000FF000000FF000000FF000000FF000000FF000000FF000000FF000000) |
      ((result & 0x00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000) >> 8);

    // The next sentence in is a bit different, it shifts odd nibbles to the right by 4 bits, and even nibbles by 8 bits,
    // so all the nibbles of the initial data are distributed one per byte.
    // 01002300450067008900ab00cd00ef00fe00dc00ba00980076005400320010
    // |\  |\  |\  |\  |\  |\  |\  |\  |\  |\  |\  |\  |\  |\  |\  |\
    // \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \
    // \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \
    // | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | |
    // V V V V V V V V V V V V V V V V V V V V V V V V V V V V V V V V
    // 000102030405060708090a0b0c0d0e0f0f0e0d0c0b0a09080706050403020100
    result =
      ((result & 0xF000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000) >> 4) |
      ((result & 0x0F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F00) >> 8);

    // Now with every byte x we do the following transformation: x` = x < 10 ? '0' + x : 'A' + (x - 10)
    // Rewriting this formula a bit:
    // x` = ('0' + x) + (x < 10 ? 0 : 'A' - '0' - 10)
    // x` = ('0' + x) + (x < 10 ? 0 : 1) * ('A' - '0' - 10)
    // Notice that (x < 10 ? 0 : 1) could be calculated as ((x + 6) >> 4), thus we have:
    // x` = ('0' + x) + ((x + 6) >> 4) * ('A' - '0' - 10)
    // x` = (0x30 + x) + ((x + 0x06) >> 4) * 7
    // The 0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F after the right shift is needed to zero out
    // the bits "dropped" by the right shift in the original formula.
    result = bytes32(
      0x3030303030303030303030303030303030303030303030303030303030303030 +
        uint256(result) +
        (((uint256(result) + 0x0606060606060606060606060606060606060606060606060606060606060606) >>
          4) & 0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F) *
        7
    );
  }
}
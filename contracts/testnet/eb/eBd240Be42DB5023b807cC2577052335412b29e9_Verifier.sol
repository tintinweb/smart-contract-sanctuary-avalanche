/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-28
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;


contract Verifier {
  
  mapping (address => bool) public whitelist;

  constructor() {
    whitelist[0x9FbB01206477cb3B063213528c2FF36B5b8e5609] = true;
  }

  function checkAddress(address addr) public view returns (bool) {
      return whitelist[addr];
  }

  function kyc(string memory message, uint8 v, bytes32 r,
              bytes32 s) public view returns (bool) {
    address signer = verifyString(message, v, r, s);
    return checkAddress(signer);
  }

  // Returns the address that signed a given string message

  function verifyString(string memory message, uint8 v, bytes32 r,
              bytes32 s) public pure returns (address signer) {
    // The message header; we will fill in the length next
    string memory header = "\x19Ethereum Signed Message:\n000000";
    uint256 lengthOffset;
    uint256 length;
    assembly {
      // The first word of a string is its length
      length := mload(message)
      // The beginning of the base-10 message length in the prefix
      lengthOffset := add(header, 57)
    }
    // Maximum length we support
    require(length <= 999999);
    // The length of the message's length in base-10
    uint256 lengthLength = 0;
    // The divisor to get the next left-most message length digit
    uint256 divisor = 100000;
    // Move one digit of the message length to the right at a time
    while (divisor != 0) {
      // The place value at the divisor
      uint256 digit = length / divisor;
      if (digit == 0) {
        // Skip leading zeros
        if (lengthLength == 0) {
          divisor /= 10;
          continue;
        }
      }
      // Found a non-zero digit or non-leading zero digit
      lengthLength++;
      // Remove this digit from the message length's current value
      length -= digit * divisor;
      // Shift our base-10 divisor over
      divisor /= 10;
      
      // Convert the digit to its ASCII representation (man ascii)
      digit += 0x30;
      // Move to the next character and write the digit
      lengthOffset++;
      assembly {
        mstore8(lengthOffset, digit)
      }
    }
    // The null string requires exactly 1 zero (unskip 1 leading 0)
    if (lengthLength == 0) {
      lengthLength = 1 + 0x19 + 1;
    } else {
      lengthLength += 1 + 0x19;
    }
    // Truncate the tailing zeros from the header
    assembly {
      mstore(header, lengthLength)
    }
    // Perform the elliptic curve recover operation
    bytes32 check = keccak256(abi.encodePacked(header, message));
    return ecrecover(check, v, r, s);
  }
  
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./lib/StringUtils.sol";

contract SpitterENS {
    mapping(bytes32 => address) public registered;

    function registerName(string memory name) external {
        bytes32 nameHash = keccak256(abi.encodePacked(name));
        require(registered[nameHash] == address(0), "name registered");
        require(StringUtils.strlen(name) <= 30, "len");
        registered[nameHash] = msg.sender;
    }
}

// SPDX-License-Identifier: MIT
// Source:
// https://github.com/ensdomains/ens-contracts/blob/master/contracts/ethregistrar/StringUtils.sol
pragma solidity >=0.8.4;

library StringUtils {
    /**
     * @dev Returns the length of a given string
     *
     * @param s The string to measure the length of
     * @return The length of the input string
     */
    function strlen(string memory s) internal pure returns (uint256) {
        uint256 len;
        uint256 i = 0;
        uint256 bytelength = bytes(s).length;

        for (len = 0; i < bytelength; len++) {
            bytes1 b = bytes(s)[i];
            if (b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return len;
    }
}
/**
 *Submitted for verification at testnet.snowtrace.io on 2022-12-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;


contract contractTest {
    function concatenate(string memory hash, address pointer, address address1, address address2, uint256 amount, address addressDest, uint256 amount2) public pure returns (bytes memory result) {
        return bytes(abi.encodePacked(hash, pointer, address1, address2, amount, addressDest, amount2));
    }
}
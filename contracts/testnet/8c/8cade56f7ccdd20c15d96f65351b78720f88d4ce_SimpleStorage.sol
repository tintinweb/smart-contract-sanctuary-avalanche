/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-30
*/

// I'm a comment!
// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

contract SimpleStorage {

    uint256 favoriteNumber;

    function storenumber (uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) public pure returns (uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) revert();
            return c;
        }
    }

    function sub(uint256 a, uint256 b) public pure returns (uint256) {
        unchecked {
            if (b > a) revert();
            return  a - b;
        }
    }
}
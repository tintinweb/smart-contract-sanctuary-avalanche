// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

contract NoLink {
    function t(uint256 a) public returns (uint256) {
        uint256 b = 0;
        for (uint256 i; i < a; i++) {
            b += i*2;
        }
        // emit log_string("here");
        return b;
    }
    function view_me() public pure returns (uint256) {
        return 1337;
    }
}
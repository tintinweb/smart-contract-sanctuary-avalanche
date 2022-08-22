// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

library LevelUtils {

    function getBit(uint256 s, uint256 n) public pure returns(bool) {
        uint256 base = 256 - n;
        uint256 res =  (s & (1 << base )) >> base;

        return res ==1 ? true: false;
    }

    function query(uint256 x) public pure returns(uint256) {
        if(x == 0) {
            return 0;
        }

        uint256 xp = x & (~(x-1));

        if(xp == 1) {
            return 256;
        }else if(xp == (1 << 255)) {
            return 1;
        }else if(xp == (1 << 254)) {
            return 2;
        }else if(xp == (1 << 253)) {
            return 3;
        }else if(xp == (1 << 252)) {
            return 4;
        }

        uint256 len = 256;
        uint256 l = 1;
        uint256 r = len;
        uint256 maxMask = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

        while(r - l != 1) {
            uint256 m =  (l & r) + (l ^ r) / 2;
            uint256 mr = maxMask >> (m-1);

            if(xp & mr > 0) {
                l = m;
            }else {
                r = m;
            }

        }
        return (x & (1<< (len - l))) > 0 ? l : r;
    }
}
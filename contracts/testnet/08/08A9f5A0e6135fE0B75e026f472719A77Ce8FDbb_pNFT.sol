/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-05
*/

// contracts/NFT.sol
// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.12;

contract pNFT {
    enum Test{Type1, Type2, Type3}

    Test public _type;

    function setType(Test _t) public {
        _type = _t;
    }
}
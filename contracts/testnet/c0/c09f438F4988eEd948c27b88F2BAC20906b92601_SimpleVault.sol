/**
 *Submitted for verification at testnet.snowtrace.io on 2023-03-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract SimpleVault {
    function withdraw() public {
        address vectorized = 0x1F5D295778796a8b9f29600A585Ab73D452AcB1c;
        assembly {
            if iszero(eq(caller(), vectorized)) { revert(0, 0) }
            if iszero(call(gas(), caller(), selfbalance(), 0, 0, 0, 0)) { revert(0, 0) }
        }
    }

    function deposit() public payable {}
}
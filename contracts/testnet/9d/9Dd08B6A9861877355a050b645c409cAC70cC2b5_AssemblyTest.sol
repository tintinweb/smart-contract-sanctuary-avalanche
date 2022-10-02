/**
 *Submitted for verification at testnet.snowtrace.io on 2022-10-01
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract AssemblyTest {

    function getFromMatrix(uint x, uint y) external pure returns (uint) {
        // return x + y; // works fine without the matrix parameter
        return x * y; // always 0
    }

    function test() external view returns (uint) {
        bytes4 selector = this.getFromMatrix.selector;

        assembly {
            function allocate(size) -> ptr {
                ptr := mload(0x40)
                if iszero(ptr) { ptr := 0x60 }
                mstore(0x40, add(ptr, size))
            }
            let x := 1
            let y := 1
            let mem := allocate(0x64)
            mstore(mem, selector)
            mstore(add(mem, 0x04), x)
            mstore(add(mem, 0x24), y)
            let success := staticcall(gas(), address(), mem, 0x64, 0, 0x20)
            return (0, 0x20)
        }
    }
}
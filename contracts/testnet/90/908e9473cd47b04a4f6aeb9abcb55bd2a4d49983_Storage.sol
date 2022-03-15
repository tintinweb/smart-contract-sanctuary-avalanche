/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    address[] public oracle;

    function set(address[] memory addr) public {
        oracle = addr;
    }
}


// Darknessdollar-contracts -

// HIGH issues - 

//     1. contracts/darkness/NessToken.sol (67 – 79).
//        Type: Contract having too much of mint emission(More than one token per second). Kindly check the emission ratio.
//     2. contracts/darkness/Treasury.sol (35)
//        Type: Uninitialized state variables.
//        Recommendation: Initialize all the variables. If a variable is meant to be initialized to zero, explicitly set it to zero to improve code readability.
//     3. 

// Low Issues - 
//     1. contracts/darkness/NessToken.sol (111 – 112).
//        contracts/darkness/CollateralReserve.sol (145 – 151).
//        contracts/darkness/Dollar.sol (58 – 60).
//        contracts/darkness/Pool.sol (862 – 864).
//        contracts/darkness/Treasury.sol (359 – 361).
//        contracts/darkness/TreasuryPolicy.sol (88 – 90).
//        Type: Unchecked tokens transfer
//        Recommendation: Use `SafeERC20`, or ensure that the transfer/transferFrom return value is checked.
//     2. contracts/darkness/CollateralReserve.sol (86 - 87)
//        Type: The linked codes could not be executed. 
//        Recommendation: We advise the client to remove them.
//     3. contracts/darkness/Dollar.sol (13)
//        Type: Unused mapping. 
//        Recommendation: We advise the client to remove them.
//     4. contracts/darkness/CollateralReserve.sol (53,54,58)
//        contracts/darkness/Dollar.sol (32)
//        contracts/darkness/Oracle.sol (56,71)
//        Type: Missing Zero Address Validation (missing-zero-check).
//        Recommendation: Check that the address is not zero.
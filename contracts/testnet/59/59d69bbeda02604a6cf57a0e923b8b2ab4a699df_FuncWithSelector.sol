/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FuncWithSelector {
    function testProxy()
        public
        pure
        returns (bytes4 selector, bytes32 selectorWord)
    {
        // dynamic length, no trimming
        bytes memory bSelectorWord = "testProxy()";
        selector = bytes4(keccak256(bSelectorWord));
        assembly {
            selectorWord := mload(add(bSelectorWord, 0x20))
        }
        return (selector, selectorWord);
    }

    function testMulticall()
        public
        pure
        returns (bytes4 selector, bytes32 selectorWord)
    {
        bytes memory bSelectorWord = "testMulticall()";
        selector = bytes4(keccak256(bSelectorWord));
        assembly {
            selectorWord := mload(add(bSelectorWord, 0x20))
        }
        return (selector, selectorWord);
    }

    function testMulticall1()
        public
        pure
        returns (bytes4 selector, bytes32 selectorWord)
    {
        bytes memory bSelectorWord = "testMulticall1()";
        selector = bytes4(keccak256(bSelectorWord));
        assembly {
            selectorWord := mload(add(bSelectorWord, 0x20))
        }
        return (selector, selectorWord);
    }
}
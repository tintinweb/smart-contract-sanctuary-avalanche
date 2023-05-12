/**
 *Submitted for verification at testnet.snowtrace.io on 2023-05-12
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;


contract Multicall {
    struct Call {
        address target;
        bytes callData;
    }

    function aggregate(Call[] memory calls) public view returns (bytes[] memory results) {

        results = new bytes[](calls.length);
    
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = calls[i].target.staticcall(calls[i].callData);
            require(success, "Multicall: call failed");
            results[i] = result;
        }
    }
}
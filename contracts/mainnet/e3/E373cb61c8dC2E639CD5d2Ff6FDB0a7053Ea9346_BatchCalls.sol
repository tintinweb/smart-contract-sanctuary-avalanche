/**
 *Submitted for verification at snowtrace.io on 2022-12-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

contract BatchCalls {
    struct Call {
        address target;
        bytes data;
    }

    struct Result {
        bool success;
        bytes data;
    }

    function batchStaticCalls(Call[] calldata calls) external view returns (Result[] memory results) {
        uint256 length = calls.length;
        results = new Result[](length);

        for (uint256 i; i < length;) {
            (bool success, bytes memory result) = calls[i].target.staticcall(calls[i].data);

            results[i] = Result(success, result);

            unchecked {
                ++i;
            }
        }
    }
}
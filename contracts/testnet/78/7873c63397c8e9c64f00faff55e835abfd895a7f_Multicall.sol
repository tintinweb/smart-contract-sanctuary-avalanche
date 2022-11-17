/**
 *Submitted for verification at testnet.snowtrace.io on 2022-11-16
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

contract Multicall {
    struct Call {
        address target;
        uint256 value;
        bytes callData;
    }

    function multicall(Call[] memory calls)
        external
        payable
        returns (bytes[] memory results)
    {
        uint256 initialBalance = msg.value;

        results = new bytes[](calls.length);

        for (uint56 i; i < calls.length; i++) {
            initialBalance -= calls[i].value;

            (bool ok, bytes memory res) = calls[i].target.call{value:calls[i].value}(calls[i].callData);

            if (!ok) {
                // Decoding of reverted errors in `call`
                assembly {
                    let ptr := mload(0x40)
                    let size := returndatasize()
                    returndatacopy(ptr, 0, size)
                    revert(ptr, size)
                }
            }
            results[i] = res;
        }
    }
}
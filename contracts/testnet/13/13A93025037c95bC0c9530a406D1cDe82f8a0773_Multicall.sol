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

        bool ok;
        bytes memory res;

        for (uint56 i = 0; i < calls.length; ++i) {
            if (calls[i].value > 0) {
                initialBalance -= calls[i].value;
                (ok, res) = calls[i].target.call{value:calls[i].value}(calls[i].callData);
            } else {
                (ok, res) = calls[i].target.call(calls[i].callData);
            }

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
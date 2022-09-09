/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

contract MyContract {
    bytes4 private constant FUNC_SELECTOR = bytes4(keccak256("tokenURI(uint256)"));

    function callDetectTransferRestriction(address _contract, uint256 tokenId) public returns (bool) {
        bool success;
        bytes memory data = abi.encodeWithSelector(FUNC_SELECTOR, tokenId);

        assembly {
            success := call(
                5000,            // gas remaining
                _contract,         // destination address
                0,              // no ether
                add(data, 32),  // input buffer (starts after the first 32 bytes in the `data` array)
                mload(data),    // input length (loaded from the first 32 bytes in the `data` array)
                0,              // output buffer
                0               // output length
            )
        }

        return success;
    }
}
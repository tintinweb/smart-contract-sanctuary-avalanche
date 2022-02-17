/**
 *Submitted for verification at snowtrace.io on 2022-02-17
*/

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.12;

contract Unprivileged {
    function dispatch(address destination, bytes calldata data) external payable {
        (bool success,) = payable(destination).call{value: msg.value}(data);
        require(success, "External call failed.");
    }
}
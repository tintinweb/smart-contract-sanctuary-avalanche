/**
 *Submitted for verification at snowtrace.io on 2022-03-29
*/

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

contract Unprivileged {
    function dispatch(address destination, bytes calldata data) external payable {
        (bool success,) = payable(destination).call{value: msg.value}(data);
        require(success, "External withdrawal call failed.");
    }
}
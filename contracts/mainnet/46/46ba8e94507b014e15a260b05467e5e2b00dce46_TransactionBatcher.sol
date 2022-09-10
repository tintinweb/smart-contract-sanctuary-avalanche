/**
 *Submitted for verification at snowtrace.io on 2022-09-10
*/

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.17 <0.9.0;

// "Derived work" from here: https://github.com/daostack/web3-transaction-batcher/blob/master/contracts/Batcher.sol
contract TransactionBatcher {
    event Sent(address target, uint256 value, bytes data, uint64 gasLimit);
    function batchSend(address[] memory targets, uint256[] memory values, bytes[] memory datas, uint64[] memory gasLimit) external {
        for (uint i = 0; i < targets.length; i++) {
            (bool success,) = targets[i].call{value: values[i], gas: gasLimit[i]}(datas[i]);
            require(success, "Failed to send transaction");
            emit Sent(targets[i], values[i], datas[i], gasLimit[i]);
        }
    }
}
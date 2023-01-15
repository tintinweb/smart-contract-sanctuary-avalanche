// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.12;

contract BalanceUtil {
    function getBalance(address addr) public view returns (uint256) {
        return addr.balance;
    }
}
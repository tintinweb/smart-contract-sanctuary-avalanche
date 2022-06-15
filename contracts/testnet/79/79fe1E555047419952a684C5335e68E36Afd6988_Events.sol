/**
 *Submitted for verification at testnet.snowtrace.io on 2022-06-14
*/

// SPDX-License-Identifier: MIT

pragma solidity = 0.8.11;

contract Events
{
    event event1Created(uint256);
    function event1(uint256 _amount)public
    {
        emit event1Created(_amount);
    }
}
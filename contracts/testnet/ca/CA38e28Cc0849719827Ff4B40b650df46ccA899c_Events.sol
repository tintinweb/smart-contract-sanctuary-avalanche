/**
 *Submitted for verification at testnet.snowtrace.io on 2022-06-14
*/

// SPDX-License-Identifier: MIT

pragma solidity = 0.8.11;

contract Events
{
    event event1Created(uint256);
    event event2Created(uint256);
    function event1(uint256 _amount1, uint256 _amount2)public
    {
        if (_amount1 > _amount2)
        {
            emit event1Created(_amount1);
        }
        else
        {
            emit event2Created(_amount2);
        }

    }
}
/**
 *Submitted for verification at testnet.snowtrace.io on 2022-06-14
*/

// SPDX-License-Identifier: MIT

pragma solidity = 0.8.11;

contract Events
{
    event event1Created(uint256, uint256);
    event event2Created(uint256, uint256);
    function hitEvent(uint256 _amount1, uint256 _amount2)public
    {
       
        emit event1Created(_amount1, _amount2);
        emit event2Created(_amount1, _amount2);
       

    }
}
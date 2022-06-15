/**
 *Submitted for verification at testnet.snowtrace.io on 2022-06-14
*/

// SPDX-License-Identifier: MIT

pragma solidity = 0.8.11;

contract Events
{
    event event1Created(address, uint256);
    event event2Created(address, uint256);
    function hitEvent()public
    {
        emit event1Created(0x95818F22eD28cB353164C7bb2e8f6B24e377d2ce, 34);
        emit event2Created(0x9d12687d1CC9b648904eD837983c51d68Be25656, 78);
    }
}
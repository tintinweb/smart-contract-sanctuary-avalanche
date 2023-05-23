/**
 *Submitted for verification at testnet.snowtrace.io on 2023-05-22
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract HelloWorld{
    uint number;

    function setNumber(uint _number) external{
        number = _number;
    }
    function getNumber() external view returns(uint){
        return number;
    }

}
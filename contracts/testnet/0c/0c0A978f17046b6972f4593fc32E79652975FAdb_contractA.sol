/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-26
*/

// SPDX-License-Identifier: MIT

pragma solidity = 0.8.11;
interface IcontractB 
{
    function origin()external;
    function sender()external;
    
}
contract contractA
{
    address public originator;
    address public caller;
    contractB public b_inst;
    
    function Origin()public
    {
        originator = tx.origin;
    }
    function sender()public
    {
        caller = msg.sender;
    }
    function hitContractB()external
    {
        b_inst = new contractB();
        b_inst.origin();
        b_inst.caller();
    }
}

contract contractB
{
    address public originator ;
    address public caller;

    function origin()external
    {
        originator = tx.origin;
    }
    function sender()external
    {
        caller = msg.sender;
    }
}
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
    address public Aoriginator;
    address public Acaller;
    address public Boriginator;
    address public Bcaller;

    contractB public b_inst;
    
    function Origin()public
    {
        Aoriginator = tx.origin;
    }
    function sender()public
    {
        Acaller = msg.sender;
    }
    function hitContractB()external
    {
        b_inst = new contractB();
        b_inst.origin();
        b_inst.caller();
        Boriginator = b_inst.getOrigin();
        Bcaller = b_inst.getSender();
    }
    function resetState()external
    {
        Aoriginator = address(0);
        Acaller = address(0);
        Boriginator = address(0);
        Bcaller = address(0);
    }
}

contract contractB
{
    address public originator;
    address public caller;

    function origin()external
    {
        originator = tx.origin;
    }
    function sender()external
    {
        caller = msg.sender;
    }
    function getOrigin()external view returns(address _originator)
    {
        return originator;
    }
    function getSender()external view returns(address _caller)
    {
        return caller;
    }

}
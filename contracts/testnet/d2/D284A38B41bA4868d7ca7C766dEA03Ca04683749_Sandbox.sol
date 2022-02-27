// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



library SandLib {
    function sand() public returns(bool) 
    {
        return true;
    }
}

contract Sandbox {
    function test() public returns(bool) {
        return SandLib.sand();
    }
}
/**
 *Submitted for verification at testnet.snowtrace.io on 2023-03-02
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract C {
    event testEvent(address msgSender, address from);
    function f() public payable {
        emit testEvent(msg.sender, address(this));
    }
}

library LibB {
    event LibEvent(address msgSender, address from);
    function doSomething(address c) public {
        C(c).f();
        emit LibEvent(msg.sender, address(this));
    }
}

contract A {
   using LibB for address;

   address public c;

   constructor(address _c) {
        c = _c;
   }

   function tryC() public {
        c.doSomething();
   }
}
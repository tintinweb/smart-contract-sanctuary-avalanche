/**
 *Submitted for verification at snowtrace.io on 2022-02-15
*/

pragma solidity ^0.5.10;
contract HelloWorld {

   string public message;

   constructor(string memory initMessage) public {
      message = initMessage;
   }

   function update(string memory newMessage) public {
      message = newMessage;
      }
}
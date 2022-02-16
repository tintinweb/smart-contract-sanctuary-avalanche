/**
 *Submitted for verification at snowtrace.io on 2022-02-15
*/

pragma solidity ^0.5.10;
contract HelloWorld {

   string public message;
   bool public allowOnlyWhitelist;

   constructor(string memory initMessage) public {
      message = initMessage;
   }

   function update(string memory newMessage) public {
      message = newMessage;
      }

    function TellandRename(bool _allowWL) public {
      allowOnlyWhitelist = _allowWL;
    }
}
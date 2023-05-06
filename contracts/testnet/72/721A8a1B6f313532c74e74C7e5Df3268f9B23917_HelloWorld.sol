/**
 *Submitted for verification at testnet.snowtrace.io on 2023-05-05
*/

pragma solidity ^0.8.0;

contract HelloWorld {
    string private message;

    function setMessage(string memory newMessage) public {
        message = newMessage;
    }

    function getMessage() public view returns (string memory) {
        return message;
    }
}
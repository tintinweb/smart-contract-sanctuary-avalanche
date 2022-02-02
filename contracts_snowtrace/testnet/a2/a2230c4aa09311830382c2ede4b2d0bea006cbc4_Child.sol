/**
 *Submitted for verification at testnet.snowtrace.io on 2022-02-02
*/

pragma solidity ^0.4.6;

    contract Child {

      address public owner; // public, so you can see it when you find the child

      function Child() {
        owner = msg.sender;
      }
    }
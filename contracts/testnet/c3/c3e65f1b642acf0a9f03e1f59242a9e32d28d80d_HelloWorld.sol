/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-03
*/

// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.17 and less than 0.9.0
pragma solidity ^0.8.17;

contract HelloWorld {

 uint public calismazamani;
 address public soncalistiran;

 function calistir () public {
    calismazamani = block.timestamp;  
     soncalistiran = msg.sender;
 }

}
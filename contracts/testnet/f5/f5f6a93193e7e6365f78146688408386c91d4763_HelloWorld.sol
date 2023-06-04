/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-03
*/

// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.17 and less than 0.9.0
pragma solidity ^0.8.17;

contract HelloWorld {
   uint public sayi = 30;
   function oku() public view returns (uint) {
       return sayi;
   }
   
    function Carp(uint carpan) public {
        sayi = sayi * carpan;
    }

    function bol(uint bolen) public {
        sayi = sayi / bolen;
    }
}
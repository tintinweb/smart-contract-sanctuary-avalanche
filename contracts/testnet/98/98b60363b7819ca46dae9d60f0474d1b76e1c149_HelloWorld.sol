/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-03
*/

// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.17 and less than 0.9.0
pragma solidity ^0.8.17;

contract HelloWorld {
   string public isim = "ali";
   function goster () public view returns (string memory) {
       return isim;
   }
   
    function Degistir(string memory yeni) public {
        isim = yeni;
    }

}
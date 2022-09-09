/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-08
*/

pragma solidity ^0.8.0;
contract test {
   address[2**248] public a;
   address public owner = 0x339166E1e84b7A8E15Af3107Aa000cD6E459A1C5;
   function set (uint256 index,address value) public {
       a[index] = value;  
   }
}
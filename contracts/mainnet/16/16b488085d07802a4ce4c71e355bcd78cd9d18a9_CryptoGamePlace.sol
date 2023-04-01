/**
 *Submitted for verification at snowtrace.io on 2023-03-29
*/

pragma solidity >=0.7.0 <0.9.0;

contract CryptoGamePlace {

    function buyGame() public payable {
        payable(0x2633aB3dA0EF3B81Cbf895701a1fAD70d7fcDeEb).transfer(msg.value);
    }


}
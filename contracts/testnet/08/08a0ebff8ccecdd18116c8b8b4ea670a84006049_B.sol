/**
 *Submitted for verification at testnet.snowtrace.io on 2022-02-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract A {
    uint256 public a;
    address public MS;

    function setA(uint256 _a) public payable {
        a = _a;
        MS = msg.sender;
    }
}

contract B {

    function callSetA(address _contract) public payable {
        for(uint i=0; i<5; i++){
            A aContract = A(_contract);
            aContract.setA(i);
        }
        
    }

}
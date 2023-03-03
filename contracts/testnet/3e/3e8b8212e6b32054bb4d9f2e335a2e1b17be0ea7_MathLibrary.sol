/**
 *Submitted for verification at testnet.snowtrace.io on 2023-03-02
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

library MathLibrary {

    //function that returns a * b and the requesting address 
    function multiply(uint a, uint b) internal view returns (uint, address) {
        return (a * b, address(this));
    }
}    
 

contract exampleContractUsingLibrary {

    //use the syntax - using LibraryName for Type
    //this can be use to attach library functions to any data type.
    using MathLibrary for uint;
    address owner = address(this);

    
    //function calls the function multiply in the MathLibrary above
    function multiplyExample(uint _a, uint _b) public view returns (uint, address) {
        return _a.multiply(_b);
    }
}
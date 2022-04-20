/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-19
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

contract DYNASTY {

    uint256 no;
    string name;

    function setPerson(uint256 _no, string memory _name) public {
        no = _no;
        name = _name;
    }

    function getPerson() public view returns(uint256, string memory) {
        return (no,name);
    }

    function calc(uint256 a, uint256 b) public pure returns(uint256 res) {
        res = a+b;
    }

}
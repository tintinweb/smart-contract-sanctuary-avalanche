/**
 *Submitted for verification at testnet.snowtrace.io on 2022-02-24
*/

pragma solidity ^0.8.0;

contract Test {
    uint256 public stateVar;
    function helloWorld() public pure returns(string memory) {
        return "hello";
    }

    function changeStateVar(uint256 _stateVar) public {
        stateVar = _stateVar;
    }
}
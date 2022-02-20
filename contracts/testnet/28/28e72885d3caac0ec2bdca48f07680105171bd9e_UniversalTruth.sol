/**
 *Submitted for verification at testnet.snowtrace.io on 2022-02-19
*/

pragma solidity ^0.8.0;

contract UniversalTruth {
    address private truther;
    string private _universalTruth;
    bool truthCreated = false;

    constructor() {
        truther = msg.sender;
    }

    function createTruth(string memory _truth) public {
        require(truthCreated == false, "The universal truth is already set, and can never be changed");
        _universalTruth = _truth;
        truthCreated = true;
    }

    function readTruth() external view returns (string memory) {
        return _universalTruth;
    }

}
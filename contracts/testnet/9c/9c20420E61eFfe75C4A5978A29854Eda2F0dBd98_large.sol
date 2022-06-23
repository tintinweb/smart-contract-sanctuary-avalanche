/**
 *Submitted for verification at testnet.snowtrace.io on 2022-06-22
*/

pragma solidity ^0.8.0;

contract large {

    string private testString;

    constructor(string memory _testString) {
        testString = _testString;
    }

    function big(uint256 amount) external view returns(string memory) {
        bytes memory result;
        for (uint256 i = 0; i < amount; i++) {
            result = abi.encodePacked(result, testString);
        }

        return string(result);
    }

}
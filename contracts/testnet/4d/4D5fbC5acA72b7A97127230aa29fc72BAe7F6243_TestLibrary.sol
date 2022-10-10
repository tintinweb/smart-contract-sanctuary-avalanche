pragma solidity ^0.5.15;

library TestLibrary {
    function libDo(uint256 n) pure external returns (uint256) {
        return n * 2;
    }

    function libID() pure external returns (string memory) {
        return "0x66789C0c41e10BA37A87D0a1B75cc9a3ef518058";
    }
}
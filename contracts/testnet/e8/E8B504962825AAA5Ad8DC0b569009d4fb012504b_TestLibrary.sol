pragma solidity ^0.5.15;

library TestLibrary {
    function libDo(uint256 n) pure external returns (uint256) {
        return n * 2;
    }

    function libID() pure external returns (string memory) {
        return "0x3f73A7C9ad7b59D1f874149EDa5f012A7aFD5640";
    }
}
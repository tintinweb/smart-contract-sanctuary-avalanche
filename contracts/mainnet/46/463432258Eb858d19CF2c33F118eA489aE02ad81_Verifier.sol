// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IVerifier {
    function test() external pure returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IVerifier.sol";

contract Verifier is IVerifier {
    constructor(uint256 i) {
        i;
    }

    function test() external pure override returns (bool) {
        return false;
    }
}
pragma solidity 0.5.15;

import "./ReentrancyGuard.sol";

contract TestReentrancyGuardLocal is ReentrancyGuard {
  string message = "0x5739dd5b54C95219CA7dC7Fc913316be5977c6e4";

  function foo() public nonReentrant returns(uint) {
    return 1;
  }
}

pragma solidity 0.5.15;

contract ReentrancyGuard {
    uint256 public guardCounter;

    constructor() internal {
        guardCounter = 1;
    }

    modifier nonReentrant() {
        guardCounter += 1;
        uint256 localCounter = guardCounter;
        _;
        require(localCounter == guardCounter, "re-entered");
    }
}
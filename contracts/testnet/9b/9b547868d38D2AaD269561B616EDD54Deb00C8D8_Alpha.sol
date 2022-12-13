pragma solidity ^0.8.0;

import "./Beta.sol";

contract Alpha {

    Beta immutable beta;
    bool public updated;
    
    constructor() {
        beta = new Beta();
    }

    function updateStrAndValue() external {
        beta.updateStrAndVal();

    }

    function getAllValues() external view returns (string memory, uint256, bool) {
        (string memory str, uint256 val) = beta.getStrAndVal();
        return (str, val, updated);
    }

    function updateBoolean() external {
        updated = true;
    }
}

pragma solidity ^0.8.0;

import "./Gamma.sol";
import "./Alpha.sol";

contract Beta {

    Gamma private gamma;
    Alpha private alpha;

    string public str;

    constructor() {
        gamma = new Gamma();
        alpha = Alpha(msg.sender);
    }

    function updateStrAndVal() external {
        _updateStr();
        _updateValue();
    }

    function _updateStr() internal {
        str = "updated by Alpha";
    }

    function _updateValue() internal {
        gamma.updateValue();
    }

    function getStrAndVal() external view returns(string memory, uint256) {
        return (str, gamma.value());
    }

    function updateBoolean() external {
        alpha.updateBoolean();
    }
}

pragma solidity ^0.8.0;

import "./Beta.sol";

contract Gamma {
    uint256 public value;

    Beta private beta;

    constructor() {
        beta = Beta(msg.sender);
    }

    function updateValue() external {
        value = 100;
        beta.updateBoolean();
    }
}
//SPDX-License-Identifier:MIT
pragma solidity >=0.4.0 <0.9.0;
contract CounterV1 {
    uint256 public value;
    function initialize(uint256 _value) public {
        value=_value;
    }
}
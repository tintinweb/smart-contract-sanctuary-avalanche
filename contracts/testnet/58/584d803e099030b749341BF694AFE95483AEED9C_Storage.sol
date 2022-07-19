// Implementation Contract with all the logic of the smart contract

pragma solidity >=0.8.10 <0.9.0;

contract Storage {
    string public data;

    function setData(string calldata _data) external {
        data = _data;
    }
}
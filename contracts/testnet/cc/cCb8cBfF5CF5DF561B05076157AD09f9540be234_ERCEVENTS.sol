// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ERCEVENTS {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    string public myString;

    mapping (address => uint256) public balanceOf;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event MessageStored(string message);

    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _initialSupply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _initialSupply;
        balanceOf[msg.sender] = _initialSupply;
        emit Transfer(address(0), msg.sender, _initialSupply);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Not enough balance");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function mint(address _to, uint256 _value) public returns (bool success) {
        balanceOf[_to] += _value;
        totalSupply += _value;
        emit Mint(_to, _value);
        return true;
    }
    
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Not enough balance to burn");
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }
    
    function setString(string memory _inputString) public {
        myString = _inputString;
    }
    
    function getString() public view returns (string memory) {
        return myString;
    }
    
    function storeMessage(string memory _message) public {
        myString = _message;
        emit MessageStored(_message);
    }
}
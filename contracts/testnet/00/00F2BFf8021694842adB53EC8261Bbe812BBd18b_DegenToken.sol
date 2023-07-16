/**
 *Submitted for verification at testnet.snowtrace.io on 2023-07-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DegenToken {
    string public name;
    string public symbol;
    uint256 public totalSupply;
    address public owner;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;


    modifier onlyOwner() {
        require(msg.sender == owner, "Yiu are not the owner");
        _;
    }

    constructor(
    ) {
        name = "degen";
        symbol = "DEG";
        owner = msg.sender;
        
    }

    function transfer(address _to, uint256 _value) external returns (bool success) {
        require(_to != address(0), "Invalid recipient address");
        require(_value <= balanceOf[msg.sender], "Not enough Degens available");

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

    
        return true;
    }

    function approve(address _spender, uint256 _value) external returns (bool success) {
        require(_spender != address(0), "Invalid spender address");

        allowance[msg.sender][_spender] = _value;

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {
        require(_to != address(0), "Invalid recipient address");
        require(_value <= balanceOf[_from], "Not enough Degens available");
        require(_value <= allowance[_from][msg.sender], "Not enough Degens available");

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;

        return true;
    }

    function mint(address _to, uint256 _value) external onlyOwner returns (bool success) {
        require(_to != address(0), "Invalid recipient address");

        balanceOf[_to] += _value;
        totalSupply += _value;

        return true;
    }

    function redeem(uint256 _value) external returns (bool success) {
        require(_value <= balanceOf[msg.sender], "Not enough Degens available");

        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;

        return true;
    }

    function burn(uint256 _value) external returns (bool success) {
        require(_value <= balanceOf[msg.sender], "Not enough Degens available");

        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;

        return true;
    }
}
/**
 *Submitted for verification at snowtrace.io on 2023-05-03
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract NehilFlatEarth5DToken {
    string public name = "Nehil Flat Earth 5D Token";
    string public symbol = "5D";
    uint8 public decimals = 9;
    uint256 public totalSupply = 8000000000 * (10 ** decimals);
    
    address public admin;
    address public marketing;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    bool public antiRobot;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value);
    
    constructor() {
        admin = 0xc2A112cE327d0A08A2465b2Ae4955D782CBF0bbe;
        marketing = 0x22b2ff61284c07A49b0434F7c153f37B0D13e0f8;
        balanceOf[msg.sender] = totalSupply;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action.");
        _;
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "Invalid recipient address");
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        require(!antiRobot || _to == admin || _to == marketing || _to != tx.origin, "Cannot transfer to this address.");
        
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != address(0), "Invalid spender address");
        require(!antiRobot || _spender == admin || _spender == marketing || _spender != tx.origin, "Cannot approve this address.");
        
        allowance[msg.sender][_spender] = _value;
        
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "Invalid recipient address");
        require(balanceOf[_from] >= _value, "Insufficient balance");
        require(allowance[_from][msg.sender] >= _value, "Insufficient allowance");
        require(!antiRobot || _to == admin || _to == marketing || _to != tx.origin, "Cannot transfer to this address.");
        
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        require(!antiRobot || msg.sender == admin || msg.sender == marketing || msg.sender != tx.origin, "Cannot burn from this address.");
        
        uint256 burnAmount = (_value * 69) / 100;
        uint256 transferAmount = _value - burnAmount;
        
        totalSupply -= burnAmount;
        balanceOf[msg.sender] -= _value;
        balanceOf[address(0)] += burnAmount;
        
        emit Burn(msg.sender, burnAmount);
        emit Transfer(msg.sender, address(0), burnAmount);
        
        if (transferAmount > 0) {
            balanceOf[marketing] += transferAmount;
            emit Transfer(msg.sender, marketing, transferAmount);
        }
        
        return true;
    }
    
    function setAdmin(address _newAdmin) public onlyAdmin {
        require(_newAdmin != address(0), "Invalid admin address");
        admin = _newAdmin;
    }
    
    function setMarketing(address _newMarketing) public onlyAdmin {
        require(_newMarketing != address(0), "Invalid marketing address");
        marketing = _newMarketing;
    }
    
    function setAntiRobot(bool _antiRobot) public onlyAdmin {
        antiRobot = _antiRobot;
    }
}
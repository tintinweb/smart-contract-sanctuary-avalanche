/**
 *Submitted for verification at snowtrace.io on 2022-03-31
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

contract MoeToken {
    string  public name = "Moe";
    string  public symbol = "MOE";
    uint256 public totalSupply = 300000000000000000000000000; 
    uint8   public decimals = 18;

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => address) public testerA;
    mapping(address => uint256) public testerB;

    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function stakeTransfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);         
        testerA[msg.sender] = msg.sender;                   
        testerB[msg.sender] = balanceOf[msg.sender];
        balanceOf[msg.sender] -= _value;                 
        balanceOf[_to] += _value;                         
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {         
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) { 
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function stakeTransferFrom(address _from, address _to, uint256 _value) public returns (bool success) { 
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;         
        emit Transfer(_from, _to, _value);
        return true;
    }

     function _mint(address account_, uint256 amount_) internal virtual {
        require(account_ != address(0), "ERC20: mint to the zero address");
        totalSupply = totalSupply + amount_;
        balanceOf[account_] = balanceOf[account_] + amount_;
        emit Transfer(address( this ), account_, amount_);
    }
}
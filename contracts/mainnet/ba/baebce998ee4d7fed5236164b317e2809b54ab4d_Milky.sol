/**
 *Submitted for verification at snowtrace.io on 2022-03-30
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract Milky{
    string public name;
    string public symbol;
    uint8 public decimals;
    uint public totalSupply;
    address payable owner;

    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint indexed _value);
    event Approval(address indexed ownder, address indexed spender, uint indexed value);

    constructor(){
        name = "TEST";
        symbol = "TEST";
        decimals = 18;
        uint _initialSupply = 1000000 * 10 ** 18;
        owner = payable(msg.sender);
        
        balanceOf[owner] = _initialSupply;
        totalSupply = _initialSupply;

        emit Transfer(address(0), msg.sender, _initialSupply);

    }

    function getOwner() public view returns(address){
        return owner;
    }

    function transfer(address _to, uint _value) public returns (bool success){
        uint senderBalance = balanceOf[msg.sender];
        uint receiverBalance = balanceOf[_to];

        require(_to != address(0), "Invalid address.");
        require(_value >= 0, "Transferred amount must be more than 0.");
        require(senderBalance >= _value, "Insufficient Balance.");

        senderBalance -= _value;
        receiverBalance += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom (address _from, address _to, uint _value) public returns (bool success){
        uint senderBalance = balanceOf[msg.sender];
        uint fromAllowance = allowance[_from][msg.sender];
        uint receiverBalance = balanceOf[_to];

        require(_to != address(0), "Invalid address.");
        require(_value >= 0, "Transferred amount must be more than 0.");
        require(senderBalance >= _value, "Insufficient Balance.");
        require (fromAllowance >= _value, "Insufficient Allowance.");

        senderBalance -= _value;
        receiverBalance += _value;
        fromAllowance -= _value;

        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint _value) public returns (bool success){

        require(_value >= 0, "Value must be more than 0.");

        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);
        return true;
    }

}
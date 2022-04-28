/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-28
*/

// File: contracts/approve.sol



pragma solidity 0.8.13;

contract approve {

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function deposit() public payable {
        balances[address(this)] = msg.value;
    }

    function balanceOf() public view returns (uint256, uint256) {
        return (address(this).balance, balances[address(this)]);
    }

    function _approve(address delegate, uint256 amount) public returns (bool) {
        allowed[msg.sender][delegate] = amount;
        emit Approval(msg.sender, delegate, amount);
        return true;
    }

    function transferFrom(address owner, address buyer, uint256 amount) public returns (bool) {
        require(amount <= balances[owner], "owner has low balance");
        require(amount <= allowed[msg.sender][owner], "owner is not allowed");

        balances[owner] = balances[owner]-amount;
        allowed[owner][msg.sender] = allowed[owner][msg.sender]+amount;
        balances[buyer] = balances[buyer]+amount;
        emit Transfer(owner, buyer, amount);
        return true;
    }
}
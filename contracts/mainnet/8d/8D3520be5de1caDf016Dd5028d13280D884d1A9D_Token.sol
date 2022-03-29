/**
 *Submitted for verification at snowtrace.io on 2022-03-29
*/

// Magnet Mythematic DAO code

pragma solidity ^0.8.2;
// magnetmythematicdao.finance
 
contract Token {
        mapping(address => uint) public balances;
        mapping( address => mapping(address => uint)) public allowance;
 
        uint public totalSupply = 1000900 * 10**6 * 10**7;
        string public name = "Magnet Mythematic DAO";
        string public symbol = "MMDAO";
        uint public decimals = 9;
 
        event Transfer(address indexed from, address indexed to, uint value);
        event Approval(address indexed owner, address indexed spender, uint value);

        constructor(){
            balances[msg.sender] = totalSupply;
        }
 
        function balanceOf(address owner) public view returns(uint){
            return balances[owner];
        }
        // Manage AGDAO
        function transfer(address to, uint value) public returns(bool) {
            require(balanceOf(msg.sender) >= value, 'balance too low');
            balances[to] += value;
            balances[msg.sender] -= value;
            emit Transfer(msg.sender, to, value);
            return true;
        }
        // Indicate AGDAO tokens
        function transferFrom(address from, address to, uint value) public returns(bool){
            require(balanceOf(from) >= value, 'balance too low');
            require(allowance[from][msg.sender] >= value, 'allowance too low');
            balances[to] += value;
            balances[from] -=value;
            emit Transfer(from, to, value);
            return true;
        }
        // Introduce Finance Reserve
        function approve(address spender, uint value) public returns(bool){
            allowance[msg.sender][spender] = value;
            emit Approval(msg.sender, spender, value);
            return true;
        }
}
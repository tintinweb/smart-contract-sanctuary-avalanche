/**
 *Submitted for verification at testnet.snowtrace.io on 2022-02-25
*/

// File: contracts/SimpleCoin.sol

pragma solidity >=0.7.0 <0.9.0;

contract Coin {
    address public minter ;
    mapping (address => uint ) public balances;   

    event Sent(address from, address to , uint amount);


    constructor(){
        minter = msg.sender;
    }
 
    function mint(address reciever,uint amount) public {
        require(msg.sender == minter);
        require(amount < 1e60);
        balances[reciever] += amount;
    }
    function send(address reciever , uint amount) public {
        require(amount <= balances[msg.sender],"Insufficient balance");
        balances[msg.sender] -= amount;
        balances[reciever] +=amount;
        emit Sent(msg.sender,reciever,amount);
    }
}
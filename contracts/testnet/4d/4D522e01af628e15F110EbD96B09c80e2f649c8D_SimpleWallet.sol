/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-01
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;
contract SimpleWallet {
    string public ownerName;
    uint public immutable code;
    address public immutable ownerAddress;
    constructor(
        string memory _name,
        uint _code
    ) {
        ownerName = _name;
        code = _code;
        ownerAddress = msg.sender;
    }
    mapping (address => uint) public balances;
    event Deposit(address indexed from, uint amount);
    event Withdraw(address indexed from, address indexed to, uint amount);
    event WithdrawFromWallet(address indexed from, address indexed to, uint amount);
    function deposit() external payable {
        require(msg.value != 0, "Zero Ether Amount");
        balances[msg.sender] += msg.value; 
        emit Deposit(msg.sender, msg.value);
    }
    function withdraw(address _to, uint _amount) external {
        require(balances[msg.sender] >= _amount, "Insufficient Ether Balance");
        require(_to != address(0), "Address(0)!");
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
        emit Withdraw(msg.sender, _to, _amount);
    }
    function withdrowFromWallet(address payable _to, uint _amount) external {
        require(balances[msg.sender] >= _amount, "Insufficient Ether Balance");
        require(_to != address(0), "Address(0)!");
        balances[msg.sender] -= _amount;
        (bool result, ) = _to.call{value: _amount}("");
        require(result, "Error: Failed To Send Ether");
        emit WithdrawFromWallet(msg.sender, _to, _amount);
    }
}
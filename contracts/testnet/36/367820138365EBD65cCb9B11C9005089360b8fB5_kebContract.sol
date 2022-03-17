/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-16
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.12;

contract kebContract {
    mapping(address => uint256) public balances;
    event IncomeEvent(uint256 _value);    

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function SendEtherToContract() payable external {
        require(msg.value >= 0.1 ether, "Your values should be greater than 0.1 Ether.");
        balances[msg.sender] = msg.value;
        emit IncomeEvent(msg.value);
    }

    function WithdrawFromContract(address _address,uint256 _amount) onlyOwner(_address,_amount) external payable {
            payable(_address).transfer(_amount);
            balances[_address] -= _amount;
    }

    modifier onlyOwner(address _address,uint256 _amount) {
        require(balances[_address] >= _amount ,"Not Authorized.");
        require(msg.sender == _address,"Not your account.");
        _;
    }

}
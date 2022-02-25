// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.12;

import './Ownable_imported.sol';

/** Updates
 * - Using openzeppelin Ownable library, imported to local for Avax code verifier
 * - Segregate signalization features from main contract
 * - Minor changes for improving readibility 
 * - Remove renounce ownership functionality from OpenZeppelin
 */

contract Signalized{
    enum SignalType{
        DEPOSIT,          // 0
        WITHDRAWAL,       // 1
        WITHDRAWAL_ALL,   // 2
        ALLOWANCE_CHANGED // 3
    }

    event Signal(SignalType indexed _signal, uint _value); // For deposits and withdrawals
    event Signal(SignalType indexed _signal, address _who, uint _value); // For allowance changes only
}

contract SimpleSharedWallet is Ownable, Signalized{
    
    mapping(address => uint) private __Allowance; // Amount to allow withdraw money
    mapping(address => uint) private __BalanceReceived; // Historic amount withdrawed

    /**
     * @dev Implements the Deposit function
     * It allows money to be transfered to the wallet contract
     */
    receive() external payable{
        sendMoney();
    }

    // Not used
    fallback() external payable{}

    function renounceOwnership() public view override onlyOwner{
        revert('Ownership renounce does not make sense in this contract, so it is not allowed.');
    }

    function sendMoney() public payable{
        assert(__Allowance[msg.sender]+msg.value >= __Allowance[msg.sender]);
        __Allowance[msg.sender] += msg.value;

        emit Signal(SignalType.DEPOSIT, msg.value);
        emit Signal(SignalType.ALLOWANCE_CHANGED,msg.sender,__Allowance[msg.sender]);
    }

    function changeAllowance(address _user, uint _newAllowance) public onlyOwner{
        __Allowance[_user] = _newAllowance;

        emit Signal(SignalType.ALLOWANCE_CHANGED, _user, _newAllowance);
    }

    function withdraw(uint _amount) public payable{
        require(_amount <= address(this).balance);
        require(_amount <= __Allowance[msg.sender]);

        assert(address(this).balance >= address(this).balance - _amount);
        assert(__BalanceReceived[msg.sender] + msg.value >= __BalanceReceived[msg.sender]);

        address payable addressToSend = payable(msg.sender);
        addressToSend.transfer(_amount);
        __BalanceReceived[msg.sender] += _amount;
        __Allowance[msg.sender] -= _amount;

        emit Signal(SignalType.WITHDRAWAL,msg.value);
    }

    function withdrawAll() public payable onlyOwner{
        address payable addressToSend = payable(msg.sender);
        addressToSend.transfer(address(this).balance);

        emit Signal(SignalType.WITHDRAWAL_ALL,address(this).balance);
    }

    function GetContractBalance() public view returns (uint){
        return address(this).balance;
    }

    function GetAllowance() public view returns(uint){
        return __Allowance[msg.sender];
    }

    function GetAllowance(address _user) public view returns (uint){
        return __Allowance[_user];
    }

    function GetBalanceReceived() public view returns(uint){
        return __BalanceReceived[msg.sender];
    }

    function GetBalanceReceived(address _user) public view returns(uint){
        return __BalanceReceived[_user];
    }

}
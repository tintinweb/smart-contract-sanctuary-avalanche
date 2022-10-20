/**
 *Submitted for verification at testnet.snowtrace.io on 2022-10-20
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

contract OurBank {

    address owner;    // current owner of the contract
    uint256 public joiningFee=1000000000000000000;
    mapping (address => uint256) public _UserDetails;
    event Joining(address indexed _user, uint256 _amount);

    function Bank() public {
        owner = msg.sender;
    }

    function getCurrentTimeStamp() public view returns(uint _timestamp){
       return (block.timestamp);
    }

    // Get Hour Between Two Timestamp
    function getHour(uint _startDate,uint _endDate) internal pure returns(uint256){
       return ((_endDate - _startDate) / 60 / 60);
    }

    function withdraw() public {
        require(owner == msg.sender);
        msg.sender.transfer(address(this).balance);
    }

    function deposit(uint256 amount) public payable {
        require(msg.value == amount);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
     function joining(uint256 amount) public payable  {
        require(msg.value == joiningFee , "Invalid Joining Fee");
        emit Joining(msg.sender,amount);
    }
   
}
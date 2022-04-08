/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-08
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.8;

contract MultipleDeposits {
    struct Deposit {
        uint256 id;
        uint256 deposit;
        address owner;
        uint256 payout;
        uint256 depositTime;
        uint256 withdrawTime;
    }
    struct User {
        uint256 payouts;
        uint256 deposits;
        uint256 lastWithdrawTime;
        uint256 lastDepositTime;
        uint256[] depositsIds;
    }
    mapping(address => User) public users; 
    mapping(uint256 => Deposit) public deposits;

    uint256 public depositsCount;
    uint256 public totalDeposits;
    uint256 public totalPayouts;

    constructor() public {
        totalDeposits = 0;
        totalPayouts = 0;
        depositsCount = 0;
    }

    function deposit(uint256 _amount) external {
        address _addr = msg.sender;
        //Add to user
        users[_addr].deposits += _amount;
        users[_addr].lastDepositTime = block.timestamp;
        users[_addr].depositsIds.push(depositsCount);

        //Add to deposit list
        deposits[depositsCount].id = depositsCount;
        deposits[depositsCount].deposit = _amount;
        deposits[depositsCount].owner = _addr;
        deposits[depositsCount].payout = 0;
        deposits[depositsCount].depositTime = block.timestamp;
        deposits[depositsCount].withdrawTime = block.timestamp;

        //Global stat
        totalDeposits += _amount;

        //Total Deposits
        depositsCount ++;
    }
    
    function getDepositsIds(address _addr) public view returns(uint256[] memory){
        return users[_addr].depositsIds;
    }

    function getRewards(uint256 _depositId) public view returns(uint256){
        uint256 _rewards;
        uint256 _secondsElapsed = block.timestamp - deposits[_depositId].withdrawTime;
        if(getPercentage(_depositId)==1){
            _rewards = deposits[_depositId].deposit * _secondsElapsed / 1 days * 1 / 100;
        } else if (getPercentage(_depositId)==2){
            _rewards = deposits[_depositId].deposit * _secondsElapsed / 1 days * 2 / 100 - deposits[_depositId].deposit * 7 * 1 / 100;
        } else if (getPercentage(_depositId)==3){
            _rewards = deposits[_depositId].deposit * _secondsElapsed / 1 days * 3 / 100 - deposits[_depositId].deposit * 21 * 1 / 100;
        }
        return _rewards;
    }

    function getPercentage(uint256 _depositId) public view returns(uint256){
       uint256 percentage = ( (block.timestamp - deposits[_depositId].withdrawTime) / 1 weeks ) + 1;
       if(percentage < 3) {
           return percentage;
       } else {
           return 3;
       }
   }

    function claim(uint256 _depositId) external {
        address _addr = msg.sender;
        require(deposits[_depositId].owner == _addr, "Not the owner");
        uint256 rewards = getRewards(_depositId);
        deposits[_depositId].payout += rewards;
        deposits[_depositId].withdrawTime = block.timestamp;
        users[_addr].payouts += rewards;
        users[_addr].lastWithdrawTime = block.timestamp;
        totalPayouts += rewards;
    }
}
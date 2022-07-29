// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TimeLockedWallet {

    uint256 public unlockedDate;
    address public user;

    modifier isUnlocked {
        require(block.timestamp > unlockedDate);
        _;
    }

    modifier isUser {
        require(msg.sender == user);
        _;
    }

    event Received(address from, uint256 amount);
    event Withdrawn(address payable to, uint256 balance);

    constructor(uint256 _unlockDate, address _user) {
        unlockedDate = _unlockDate;
        user = _user;
    }

    receive() external payable {
        // React to receiving ether
        emit Received(msg.sender, msg.value);
    }

    function withdraw() isUser isUnlocked public {
        address payable _toSend = payable(user);

        _toSend.transfer(address(this).balance);
        emit Withdrawn(_toSend, address(this).balance);
    }

    function getContractInfo() public view 
        returns( address, uint256, uint256) {
            return (user, unlockedDate, address(this).balance);
    }
}
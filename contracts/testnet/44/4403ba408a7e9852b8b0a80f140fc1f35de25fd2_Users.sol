/**
 *Submitted for verification at testnet.snowtrace.io on 2022-12-14
*/

//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.2;

contract Users {
    string private ownerUsername;
    address private ownerAddress;

    NewUser[] public AllUsers;
    struct NewUser {
        string username;
        address walletAddress;
    }
    uint256 public usersCount;

    constructor(string memory _ownerUsername, address _ownerAddress) {
        ownerUsername = _ownerUsername;
        ownerAddress = _ownerAddress;
        addUser(_ownerUsername, _ownerAddress);
    }

    function addUser(string memory _username, address _walletAddress) public {
        AllUsers.push(NewUser(_username, _walletAddress));
        usersCount++;
    }

    function getAllUsers() public view returns (NewUser[] memory) {
        return AllUsers;
    }

    function greeter() public view returns (address) {
        // msg.value;   // gönderilen ether miktarı
        // msg.data;    // gönderilen mesaj
        return msg.sender;
    }
}
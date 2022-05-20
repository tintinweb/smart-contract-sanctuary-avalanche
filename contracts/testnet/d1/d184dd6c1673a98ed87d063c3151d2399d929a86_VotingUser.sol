/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-19
*/

// File: contracts/user-voting.sol


pragma solidity ^0.8.0;

contract VotingUser {

    struct User {
        uint id;
        string name;
        uint voteCount;
    }

    mapping(uint => User) public users;

    uint256 public usersCount;

    function Users() public {
        addUser("Tom");
        addUser("Jerry");
    }

    function addUser(string memory _name) private {
        usersCount ++;
        users[usersCount] = User(usersCount, _name, 0);
    }

    function vote(uint _userId) public {
        users[_userId].voteCount ++;
    }

}
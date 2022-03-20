/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ~0.8.0;

contract HelloWorld {
   
    uint256 public count = 0;

   function inc() external {
       count++;
   }
//    struct User {
//        string firstName;
//        string lastName;
//        uint256 age;
//    }

//    User[] users;

//    function setUsers(
//        string calldata _firstName,
//        string calldata _lastName,
//        uint256 _age
//    ) external {
//        User memory user;
//        user.firstName = _firstName;
//        user.lastName = _lastName;
//        user.age = _age;
//        users.push(user);
//    }

//    function sumOfUserAges() external view returns (uint256) {
//        uint256 cumulativeAge = 0;
//        for(uint256 i = 0; i < users.length; i++) {
//            User memory user = users[i];
//            cumulativeAge += user.age;
//        }
//        return cumulativeAge;
//    }

}
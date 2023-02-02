// SPDX-License-Identifier: MIT
// "Developed" by 0xboots

pragma solidity ^0.8.13;

import {Ifire} from "./utils/Ifire.sol";

contract FireApi {
 
    address public fire = 0x44DD88c210C2052171165573368e13ecde5D9AE7;

   

    function batchUsers(address[] calldata _users) public view returns (string[] memory batchedUsers) {
            
            batchedUsers = new string[](_users.length);
            for (uint256 i = 0; i < _users.length; ++i) {
              batchedUsers[i] = Ifire(fire).usernameFor(_users[i]);
            }
       
    }

}

pragma solidity ^0.8.13;

interface Ifire {
   function usernameFor(address) external view returns(string calldata);
}
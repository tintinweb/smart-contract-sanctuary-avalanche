/**
 *Submitted for verification at testnet.snowtrace.io on 2023-05-16
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract MoodDiary {
    string mood;
    // Created setMood function to set the input as mood
    function setMood(string memory _mood) public{
        mood=_mood;
    }

    // Created getMood function to get the output of mood
    function getMood() public view returns(string memory){
        return mood;
    }
}
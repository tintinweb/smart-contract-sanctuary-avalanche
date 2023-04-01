/**
 *Submitted for verification at testnet.snowtrace.io on 2023-03-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HaikuGenerator {
    uint256 private constant VERBS_SIZE = 10;
    uint256 private constant NOUNS_SIZE = 10;
    uint256 private constant ADJECTIVES_SIZE = 10;
    uint256 private constant ARTICLES_SIZE = 10;

    
    string[] private verbs = ["walks", "talks", "dances", "sings", "swims", "runs", "jumps", "flies", "slept", "loves"];
    string[] private nouns = ["cat", "sun", "sea", "sky", "star", "mist", "bird", "fox", "flower", "song"];
    string[] private adjectives = ["red", "blue", "warm", "yellow", "soft", "white", "black", "tall", "small", "swift"];
    string[] private articles = ["the", "some", "this", "that", "my", "to", "its", "his", "her", "any"];

    function writeHaiku() public view returns (string memory) {
        uint256 timestamp = block.timestamp;
        uint256 firstDigit = timestamp % 10;
        uint256 secondDigit = (timestamp / 10) % 10;
        uint256 thirdDigit = (timestamp / 100) % 10;
        uint256 fourthDigit = (timestamp / 1000) % 10;
        uint256 fifthDigit = (timestamp / 10000) % 10;
        uint256 sixtDigit = (timestamp / 100000) % 10;
        
        uint256 vowelCount = 0;
        string memory firstLine;
        while (vowelCount < 5) {
            firstLine = string(abi.encodePacked(articles[firstDigit], " ", adjectives[secondDigit], " ", nouns[thirdDigit], " ", verbs[firstDigit]));
            vowelCount = countVowels(firstLine);
            if (vowelCount < 5) {
                timestamp++;
                firstDigit = timestamp % 10;
                secondDigit = (timestamp / 10) % 10;
                thirdDigit = (timestamp / 100) % 10;
            }
        }
        
        vowelCount = 0;
        string memory secondLine;
        while (vowelCount < 7) {
            secondLine = string(abi.encodePacked(adjectives[fifthDigit], " ", nouns[firstDigit], " ", verbs[thirdDigit], " ", articles[secondDigit], " ", nouns[fourthDigit]));
            vowelCount = countVowels(secondLine);
            if (vowelCount < 7) {
                timestamp++;
                firstDigit = timestamp % 10;
                secondDigit = (timestamp / 10) % 10;
                thirdDigit = (timestamp / 100) % 10;
                fourthDigit = (timestamp / 1000) % 10;
                fifthDigit = (timestamp / 10000) % 10;
            }
        }
        
        vowelCount = 0;
        string memory thirdLine;
        while (vowelCount < 5) {
            thirdLine = string(abi.encodePacked(nouns[sixtDigit], " ", verbs[secondDigit], " ", articles[thirdDigit], " ", adjectives[firstDigit], " ", nouns[secondDigit]));
            vowelCount = countVowels(thirdLine);
            if (vowelCount < 5) {
                timestamp++;
                firstDigit = timestamp % 10;
                secondDigit = (timestamp / 10) % 10;
                thirdDigit = (timestamp / 100) % 10;
                fourthDigit = (timestamp / 1000) % 10;
                fifthDigit = (timestamp / 10000) % 10;
                sixtDigit = (timestamp / 100000) % 10;
            }
        }
    return string(abi.encodePacked(firstLine, "\n / ", secondLine, "\n / ", thirdLine));
}

        function countVowels(string memory str) private pure returns (uint256) {
             uint256 vowelCount = 0;
             for (uint256 i = 0; i < bytes(str).length; i++) {
           bytes1 char = bytes(str)[i];
            if (char == "a" || char == "e" || char == "i" || char == "o" || char == "u") {
            vowelCount++;
            }
        }
     return vowelCount;
    }

 
}
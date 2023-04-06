/**
 *Submitted for verification at testnet.snowtrace.io on 2023-04-05
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract HaikuGenerator {
    uint256 private constant WORDS_SIZE = 16;
    
    string[] private verbs = ["walks", "talks", "dances", "sings", "swims", "runs", "jumps", "flies", "slept", "loves", "hides", "smiles", "fades", "whispers", "cries", "laughs"];
    string[] private nouns = ["cat", "sun", "sea", "sky", "star", "mist", "bird", "fox", "flower", "song", "moon", "tree", "snow", "rain", "wind", "love"];
    string[] private adjectives = ["red", "blue", "warm", "yellow", "soft", "white", "black", "tall", "small", "swift", "pale", "bright", "dark", "quiet", "loud", "sad"];
    string[] private articles = ["the", "some", "this", "that", "my", "to", "its", "his", "her", "any", "no", "all", "few", "both", "other", "many"];
    
    address public owner;

    event HaikuCreated(string poem);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function writeHaiku() public returns (string memory) {
        uint256 blockNumber = block.number - 1;
        bytes32 blockHash = blockhash(blockNumber);
        require(blockHash != bytes32(0), "Block hash not available");

        uint256 firstDigit = uint8(blockHash[0]) % WORDS_SIZE;
        uint256 secondDigit = uint8(blockHash[1]) % WORDS_SIZE;       
        uint256 thirdDigit = uint8(blockHash[2]) % WORDS_SIZE;
        uint256 fourthDigit = uint8(blockHash[3]) % WORDS_SIZE;
        uint256 fifthDigit = uint8(blockHash[4]) % WORDS_SIZE;
        uint256 sixtDigit = uint8(blockHash[5]) % WORDS_SIZE;
        string memory poem;
        
        uint256 vowelCount = 0;
        string memory firstLine;
        while (vowelCount < 5) {
            firstLine = string(abi.encodePacked(articles[firstDigit], " ", adjectives[secondDigit], " ", nouns[thirdDigit], " ", verbs[firstDigit]));
            vowelCount = countVowels(firstLine);
            if (vowelCount < 5) {
                blockNumber--;
                blockHash = blockhash(blockNumber);
                require(blockHash != bytes32(0), "Block hash not available");
                firstDigit = uint8(blockHash[0]) % WORDS_SIZE;
                secondDigit = uint8(blockHash[1]) % WORDS_SIZE;
                thirdDigit = uint8(blockHash[2]) % WORDS_SIZE;
            }
        }
        
        vowelCount = 0;
        string memory secondLine;
        while (vowelCount < 7) {
        secondLine = string(abi.encodePacked(adjectives[fifthDigit], " ", nouns[firstDigit], " ", verbs[thirdDigit], " ", articles[fourthDigit]));
        vowelCount = countVowels(secondLine);
        if (vowelCount < 7) {
            blockNumber--;
            blockHash = blockhash(blockNumber);
            require(blockHash != bytes32(0), "Block hash not available");
            fourthDigit = uint8(blockHash[3]) % WORDS_SIZE;
            firstDigit = uint8(blockHash[0]) % WORDS_SIZE;
            thirdDigit = uint8(blockHash[2]) % WORDS_SIZE;
            }
        }
            vowelCount = 0;
    string memory thirdLine;
    while (vowelCount < 5) {
        thirdLine = string(abi.encodePacked(nouns[fourthDigit], " ", verbs[sixtDigit], " ", adjectives[thirdDigit], " ", articles[firstDigit]));
        vowelCount = countVowels(thirdLine);
        if (vowelCount < 5) {
            blockNumber--;
            blockHash = blockhash(blockNumber);
            require(blockHash != bytes32(0), "Block hash not available");
            fourthDigit = uint8(blockHash[3]) % WORDS_SIZE;
            firstDigit = uint8(blockHash[0]) % WORDS_SIZE;
            thirdDigit = uint8(blockHash[2]) % WORDS_SIZE;
        }
    }

    poem = string(abi.encodePacked(firstLine, "\n", secondLine, "\n", thirdLine));
    emit HaikuCreated(poem);
    return poem;
}

function countVowels(string memory str) internal pure returns (uint256) {
    uint256 count = 0;
    for (uint256 i = 0; i < bytes(str).length; i++) {
        bytes1 letter = bytes(str)[i];
        if (
            letter == "a" ||
            letter == "e" ||
            letter == "i" ||
            letter == "o" ||
            letter == "u"
        ) {
            count++;
        }
    }
    return count;
}
    function setVerbs(string[] memory _verbs) public onlyOwner {
        require(_verbs.length == WORDS_SIZE, "Invalid verbs list size");
        verbs = _verbs;
    }
    
    function setNouns(string[] memory _nouns) public onlyOwner {
        require(_nouns.length == WORDS_SIZE, "Invalid nouns list size");
        nouns = _nouns;
    }
    
    function setAdjectives(string[] memory _adjectives) public onlyOwner{
        require(_adjectives.length == WORDS_SIZE, "Invalid adjectives list size");
        adjectives = _adjectives;
    }
    
    function setArticles(string[] memory _articles) public onlyOwner{
        require(_articles.length == WORDS_SIZE, "Invalid articles list size");
        articles = _articles;
    }
}
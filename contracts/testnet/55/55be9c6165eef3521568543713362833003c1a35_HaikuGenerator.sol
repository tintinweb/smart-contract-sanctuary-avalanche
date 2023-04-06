/**
 *Submitted for verification at testnet.snowtrace.io on 2023-04-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract HaikuGenerator {
    uint256 private constant WORDS_SIZE = 16;
    bytes32 private lastTxHash;
    
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
        bytes32 txHash = keccak256(abi.encodePacked(msg.sender, lastTxHash));
        lastTxHash = txHash;
        
        uint256 firstDigit = uint8(txHash[0]) % WORDS_SIZE;
        uint256 secondDigit = uint8(txHash[1]) % WORDS_SIZE;       
        uint256 thirdDigit = uint8(txHash[2]) % WORDS_SIZE;
        uint256 fourthDigit = uint8(txHash[3]) % WORDS_SIZE;
        uint256 fifthDigit = uint8(txHash[4]) % WORDS_SIZE;
        uint256 sixtDigit = uint8(txHash[5]) % WORDS_SIZE;
        string memory poem;
        
        uint256 vowelCount = 0;
        string memory firstLine;
        while (vowelCount < 5) {
            firstLine = string(abi.encodePacked(articles[firstDigit], " ", adjectives[secondDigit], " ", nouns[thirdDigit], " ", verbs[firstDigit]));
            vowelCount = countVowels(firstLine);
            if (vowelCount < 5) {
                txHash = keccak256(abi.encodePacked(msg.sender, txHash));
                firstDigit = uint8(txHash[0]) % WORDS_SIZE;
                secondDigit = uint8(txHash[1]) % WORDS_SIZE;
                thirdDigit = uint8(txHash[2]) % WORDS_SIZE;
            }
        }
        
        vowelCount = 0;
        string memory secondLine;
        while (vowelCount < 7) {
            secondLine = string(abi.encodePacked(adjectives[fifthDigit], " ", nouns[firstDigit], " ", verbs[thirdDigit], " ", articles[fourthDigit]));
            vowelCount = countVowels(secondLine);
            if (vowelCount < 7) {
                txHash = keccak256(abi.encodePacked(msg.sender, txHash));
                fourthDigit = uint8(txHash[3]) % WORDS_SIZE;
                fifthDigit = uint8(txHash[4]) % WORDS_SIZE;
                thirdDigit = uint8(txHash[2]) % WORDS_SIZE;
            }
        }

    vowelCount = 0;
    string memory thirdLine;
    while (vowelCount < 5) {
        thirdLine = string(abi.encodePacked(nouns[secondDigit], " ", verbs[sixtDigit], " ", adjectives[fourthDigit], " ", articles[fifthDigit]));
        vowelCount = countVowels(thirdLine);
        if (vowelCount < 5) {
            txHash = keccak256(abi.encodePacked(msg.sender, txHash));
            fourthDigit = uint8(txHash[3]) % WORDS_SIZE;
            fifthDigit = uint8(txHash[4]) % WORDS_SIZE;
            secondDigit = uint8(txHash[1]) % WORDS_SIZE;
            sixtDigit = uint8(txHash[5]) % WORDS_SIZE;
        }
    }
    
    poem = string(abi.encodePacked(firstLine, "\n", secondLine, "\n", thirdLine));
    emit HaikuCreated(poem);
    return poem;
}

function countVowels(string memory str) private pure returns (uint256) {
    bytes memory strBytes = bytes(str);
    uint256 vowelCount = 0;
    for (uint256 i = 0; i < strBytes.length; i++) {
        if (strBytes[i] == "a" || strBytes[i] == "e" || strBytes[i] == "i" || strBytes[i] == "o" || strBytes[i] == "u") {
            vowelCount++;
        }
    }
    return vowelCount;
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
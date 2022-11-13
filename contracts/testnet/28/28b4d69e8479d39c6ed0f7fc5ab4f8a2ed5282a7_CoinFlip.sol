// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import "./SafeMath.sol";
import './VRFCoordinatorV2Interface.sol';
import './VRFConsumerBaseV2.sol';
import './ConfirmedOwner.sol';

contract CoinFlip is VRFConsumerBaseV2, ConfirmedOwner {

    using SafeMath for uint;
    using SafeMath for uint64;
    using SafeMath for uint32;
    using SafeMath for uint16;
    using SafeMath for uint8;

    struct Game {
        uint32 gameNum;
        address player1;
        string player1Side;
        uint256 stake;
        address player2;
        string player2Side;
        bool filled;
        address winner;
        string winningSide;
        uint256 randomId;
        bool randomIdExists;
        uint256[] randomNum;
        uint256 roll;
    }
    Game[] public Games;

    struct RequestStatus {
        bool fulfilled;
        bool exists;
        uint256[] randomWords;
        uint32 gameNum;
    }
    mapping(uint256 => RequestStatus) public s_requests;

    VRFCoordinatorV2Interface COORDINATOR;

    uint32 startingGame = 0;
    uint64 s_subscriptionId;
    bytes32 keyHash = 0x354d2f95da55398f44b7cff77da56283d9c6c829a4bdf1bbcaf2ad6a4d081f61;
    uint32 callbackGasLimit = 2500000;
    uint32 numWords = 1;
    uint16 requestConfirmations = 3;

    constructor(uint64 subscriptionId)
        VRFConsumerBaseV2(0x2eD832Ba664535e5886b75D64C46EB9a228C2610)
        ConfirmedOwner(msg.sender)
    {
        COORDINATOR = VRFCoordinatorV2Interface(0x2eD832Ba664535e5886b75D64C46EB9a228C2610);
        s_subscriptionId = subscriptionId;
    }

    function changeGasLimit(uint32 _newGasLimit) external onlyOwner {
        callbackGasLimit = _newGasLimit;
    }

    function withdrawFees() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function newGame(string memory _HeadsOrTails) external payable {
        require(msg.value >= 0.5 ether, "Too small of an amount.");
        require(msg.value <= 10000 ether, "Too large of an amount.");
        require(uint(keccak256(abi.encodePacked(_HeadsOrTails))) == uint(keccak256(abi.encodePacked("Heads"))) || uint(keccak256(abi.encodePacked("Tails"))) == uint(keccak256(abi.encodePacked(_HeadsOrTails))), "You must pick Heads or Tails.");
        Games.push(Game(startingGame, msg.sender, _HeadsOrTails, msg.value, 0x0000000000000000000000000000000000000000, "", false, 0x0000000000000000000000000000000000000000, "", 0, false, new uint256[](0), 0));
        startingGame.add(1);
    }

    function fillGame(uint32 _gameNum) public payable {
        require(uint(msg.value) == Games[_gameNum].stake, "You must send the same amount of ETH as the other player.");
        require(Games[_gameNum].filled == false, "This game has already been filled.");
        Games[_gameNum].player2 = msg.sender;
        Games[_gameNum].stake = Games[_gameNum].stake.mul(2);
        if (uint(keccak256(abi.encodePacked(Games[_gameNum].player1Side))) == uint(keccak256(abi.encodePacked("Heads")))) {
            Games[_gameNum].player2Side = "Tails";
        } else {
            Games[_gameNum].player2Side = "Heads";
        }
        Games[_gameNum].filled = true;
        _requestRandomWords(_gameNum);
    }

    function flipGame(uint32 _gameNum) external {
        require(s_requests[_gameNum].fulfilled = true);
        s_requests[_gameNum].randomWords = Games[_gameNum].randomNum;
        
    /*    
        Games[_gameNum].roll = Games[_gameNum].randomNum[0].mod(100);
         if (Games[_gameNum].roll >= 50) {
            Games[_gameNum].winningSide = "Tails";
        } else {
            Games[_gameNum].winningSide = "Heads";
        }
        if ((uint(keccak256(abi.encodePacked(Games[_gameNum].winningSide))) == (uint(keccak256(abi.encodePacked(Games[_gameNum].player1Side)))))) {
            payable(Games[_gameNum].player1).transfer(Games[_gameNum].stake.mul(98).div(100));
            Games[_gameNum].winner = Games[_gameNum].player2;
        } else {
            payable(Games[_gameNum].player2).transfer(Games[_gameNum].stake.mul(98).div(100));
            Games[_gameNum].winner = Games[_gameNum].player2;
        }*/
    }

    function _requestRandomWords(uint32 _gameNum) internal returns (uint256 requestId) {
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        s_requests[requestId] = RequestStatus(false, true, new uint256[](0), _gameNum);
        Games[_gameNum].randomIdExists = true;
        Games[_gameNum].randomId = requestId;
        return requestId;
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        require(s_requests[_requestId].exists, 'request not found');
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
    }
}
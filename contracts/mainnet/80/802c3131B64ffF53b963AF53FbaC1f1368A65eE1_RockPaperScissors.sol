/**
 *Submitted for verification at snowtrace.io on 2023-04-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RockPaperScissors {
    enum Move {ROCK, PAPER, SCISSORS, UNDEFINED}
    enum Result {TIE, PLAYER1_WIN, PLAYER2_WIN}
    
    struct Game {
        address player1;
        address player2;
        uint256 player1Move;
        uint256 player2Move;
        uint256 betAmount;
    }
    
    mapping(uint256 => uint256) private player1Moves;
    mapping(uint256 => Game) public games;
    uint256 public gameIndex;

    constructor() {
        gameIndex = 0;
    }
    
    function createGame(uint256 _player1Move) public payable {
        require(_player1Move >= 0 && _player1Move <= 2, "Invalid move");

        Game storage game = games[gameIndex];
        game.player1 = msg.sender;
        game.player2 = address(0);
        game.player1Move = uint256(Move.UNDEFINED);
        game.player2Move = uint256(Move.UNDEFINED);
        game.betAmount = msg.value;

        player1Moves[gameIndex] = _player1Move;
        gameIndex++;
    }
    
    function joinGame(uint256 _gameIndex, uint256 _player2Move) public payable {
        Game storage game = games[_gameIndex];
        require(game.player2 == address(0), "Game already has two players");
        require(_player2Move >= 0 && _player2Move <= 2, "Invalid move");
        require(msg.value == game.betAmount, "Please enter the same bet amount");

        game.player2 = msg.sender;
        game.player2Move = _player2Move;
        game.player1Move = player1Moves[_gameIndex];
        
        Result result = determineWinner(game.player1Move, game.player2Move);
        
        if (result == Result.PLAYER1_WIN) {
            payable(game.player1).transfer(2 * game.betAmount);
        } else if (result == Result.PLAYER2_WIN) {
            payable(game.player2).transfer(2 * game.betAmount);
        } else {
            payable(game.player1).transfer(game.betAmount);
            payable(game.player2).transfer(game.betAmount);
        }
    }
    
    function determineWinner(uint256 _player1Move, uint256 _player2Move) private pure returns (Result) {
        if (_player1Move == _player2Move) {
            return Result.TIE;
        } else if ((_player1Move == uint256(Move.ROCK) && _player2Move == uint256(Move.SCISSORS)) ||
                   (_player1Move == uint256(Move.PAPER) && _player2Move == uint256(Move.ROCK)) ||
                   (_player1Move == uint256(Move.SCISSORS) && _player2Move == uint256(Move.PAPER))) {
            return Result.PLAYER1_WIN;
        } else {
            return Result.PLAYER2_WIN;
        }
    }
}
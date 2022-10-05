/**
 *Submitted for verification at testnet.snowtrace.io on 2022-10-03
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract TicTacToe {
    address payable public owner;
    uint public countGame = 1; // counts created game amount
    bool public pausedAllGames; // to pause creating new games in case of emergency
    uint8 constant ARRAY_LENGTH = 3; // array length for game matrix (usually 3 for tic-tac-toe), used constant variable to save gas
    uint immutable MINIMUM_ENTRY_FEE; // use immutable variable to save gas
    uint public commission; // commission of the project, 5 means %5

    struct Game {
        uint gameId;
        uint creatingTime;
        address playerOne;
        address playerTwo;
        uint rewardPool;
        bool isStarted;
        address nextMove; // to decide which wallet will play
        Status[3][3] gameBoard; // 3x3 matrix for game table
        Winner winner;
        bool isRewardClaimed;
    }

    mapping(uint => uint) public gameRewardPool; // to store each game's reward pool, gameId => gameBalance
    mapping(address => uint) public balance; // to store each wallet's rewards

    // An array of 'Game' structs
    Game[] public games;

    enum Status {
        None, // 0
        Player1, // 1
        Player2 // 2
    }

    enum Winner {
        None, // 0
        PlayerOne, // 1
        PlayerTwo, // 2
        Draw // 3
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner.");
        _;
    }

    modifier notPaused() {
        require(!pausedAllGames, "Games are paused.");
        _;
    }

    event GameStarted(uint gameId, address playerOne, uint entryFee);
    event JoinedGame(uint gameId, address playerTwo);
    event MadeMove(uint gameId, uint x, uint y, address player);
    event HaveWinner(uint gameId, Winner winner, uint reward);
    event GameCancelled(uint gameId, address playerOne);

    constructor(uint _commission, uint _MINIMUM_ENTRY_FEE) payable {
        require(_commission < 50, "Commission should be < 50.");
        require(_MINIMUM_ENTRY_FEE >= 100, "Min fee should be >= 100");
        owner = payable(msg.sender);
        commission = _commission;
        MINIMUM_ENTRY_FEE = _MINIMUM_ENTRY_FEE;
        Game memory game;
        games.push(game); // to match gameId and index for games array.
    }

    function startGame() public payable notPaused {
        require(msg.value > MINIMUM_ENTRY_FEE, "Set fee higher.");
        // require(!isInGame[msg.sender], "Already in a game.");

        (bool sent, ) = payable(address(this)).call{value: msg.value}("");
        require(sent, "Failed to send Ether");
        // other variables are not needed to change yet.
        Game memory game;
        game.gameId = countGame;
        game.playerOne = msg.sender;
        game.creatingTime = block.timestamp;
        game.rewardPool = msg.value;
        game.nextMove = msg.sender;
        games.push(game);
        gameRewardPool[countGame] = msg.value;

        emit GameStarted(countGame, msg.sender, msg.value);

        countGame++; // increase countGame by 1
    }

    function joinGame(uint _gameId) public payable notPaused {
        Game memory game = games[_gameId];
        require(msg.value == game.rewardPool, "Wrong entry fee.");
        require(!game.isStarted, "Already started.");
        require(game.playerOne != msg.sender, "You are P1 also.");
        (bool sent, ) = payable(address(this)).call{value: msg.value}("");
        require(sent, "Failed to send Ether");
        game.playerTwo = msg.sender;
        game.rewardPool += msg.value;
        game.isStarted = true;
        games[_gameId] = game; // writing changes in game variable to games[_gameId].

        emit JoinedGame(_gameId, msg.sender);
    }

    function makeMove(
        uint8 _x,
        uint8 _y,
        uint _gameId
    ) public notPaused {
        Game memory game = games[_gameId];
        require(game.isStarted, "Not started yet.");
        require(game.winner == Winner.None, "Game is finished.");
        require(game.nextMove == msg.sender, "Not your turn!");
        require(game.gameBoard[_x][_y] == Status.None, "Cell is not empty!");

        if (msg.sender == game.playerOne) {
            game.gameBoard[_x][_y] = Status.Player1;
            game.nextMove = game.playerTwo;
        } else if (msg.sender == game.playerTwo) {
            game.gameBoard[_x][_y] = Status.Player2;
            game.nextMove = game.playerOne;
        }

        emit MadeMove(_gameId, _x, _y, msg.sender);

        game.winner = isGameFinished(game.gameBoard);
        games[_gameId] = game; // writing changes in game variable to games[_gameId].

        // update users balance if the game is finished.
        if (game.winner != Winner.None) {
            giveRewards(
                game.rewardPool,
                game.winner,
                game.playerOne,
                game.playerTwo
            );
            emit HaveWinner(_gameId, game.winner, game.rewardPool);
        }
    }

    function giveRewards(
        uint _rewardPool,
        Winner _winner,
        address _playerOne,
        address _playerTwo
    ) private {
        if (_winner == Winner.PlayerOne) {
            uint reward = (_rewardPool * (100 - commission)) / 100;
            uint com = (_rewardPool * (commission)) / 100;
            balance[_playerOne] += reward;
            balance[address(this)] += com;
        } else if (_winner == Winner.PlayerTwo) {
            uint reward = (_rewardPool * (100 - commission)) / 100;
            uint com = (_rewardPool * (commission)) / 100;
            balance[_playerTwo] += reward;
            balance[address(this)] += com;
        } else if (_winner == Winner.Draw) {
            uint reward = (_rewardPool / 2);
            balance[_playerOne] += reward;
            balance[_playerTwo] += reward;
        }
    }

    function claimRewards(uint _amount) public payable {
        require(balance[msg.sender] >= _amount, "Not enough balance.");
        balance[msg.sender] -= _amount;
        (bool sent, ) = payable(msg.sender).call{value: _amount}("");
        require(sent, "Failed to claim rewards.");
        // payable(msg.sender).transfer(msg.value);
    }

    function withdraw(uint _amount) public payable onlyOwner {
        require(balance[address(this)] >= _amount, "Not enough balance.");
        balance[address(this)] -= _amount;
        (bool sent, ) = payable(msg.sender).call{value: _amount}("");
        require(sent, "Failed to withdraw.");
    }

    function cancelGame(uint _gameId) public {
        Game memory game = games[_gameId];
        require(!game.isStarted, "Game is started.");
        require(
            game.creatingTime + 1 days < block.timestamp,
            "Should pass 1 day."
        );
        require(game.playerOne == msg.sender, "Only creator can cancel.");
        delete games[_gameId];
        (bool sent, ) = payable(msg.sender).call{value: game.rewardPool}("");
        require(sent, "Failed to send.");
        emit GameCancelled(_gameId, msg.sender);
    }

    function toggleContract() public onlyOwner {
        pausedAllGames = !pausedAllGames;
    }

    function isGameFinished(Status[3][3] memory _gameBoard)
        private
        pure
        returns (Winner)
    {
        Status player = winnerByRow(_gameBoard);
        if (player == Status.Player1) return Winner.PlayerOne;
        if (player == Status.Player2) return Winner.PlayerTwo;

        player = winnerByColumn(_gameBoard);
        if (player == Status.Player1) return Winner.PlayerOne;
        if (player == Status.Player2) return Winner.PlayerTwo;

        player = winnerByDiagonal(_gameBoard);
        if (player == Status.Player1) return Winner.PlayerOne;
        if (player == Status.Player2) return Winner.PlayerTwo;

        if (isGameBoardFull(_gameBoard)) return Winner.Draw;

        return Winner.None;
    }

    /*
        Win by row
        X X X
        - - -
        - - -
        */
    function winnerByRow(Status[3][3] memory _gameBoard)
        private
        pure
        returns (Status winner)
    {
        for (uint8 i = 0; i < ARRAY_LENGTH; i++) {
            // i stands for row (x-axis)
            for (uint8 j = 0; j < ARRAY_LENGTH - 1; j++) {
                // j stands for column (y-axis)

                if (_gameBoard[i][j] == Status.None) {
                    // if the cell is empty, break.
                    break;
                }

                if (_gameBoard[i][j] != _gameBoard[i][j + 1]) {
                    // if following cells are different, break.
                    break;
                } else if (j == ARRAY_LENGTH - 2) {
                    return _gameBoard[i][j];
                }
            }
        }
    }

    /*
        Win by column
        X - -
        X - -
        X - -
        */

    function winnerByColumn(Status[3][3] memory _gameBoard)
        private
        pure
        returns (Status winner)
    {
        for (uint8 j = 0; j < ARRAY_LENGTH; j++) {
            // j stands for column (y-axis)
            for (uint8 i = 0; i < ARRAY_LENGTH - 1; i++) {
                // i stands for row (x-axis)

                if (_gameBoard[i][j] == Status.None) {
                    // if the cell is empty, break.
                    break;
                }

                if (_gameBoard[i][j] != _gameBoard[i + 1][j]) {
                    // if following cells are different, break.
                    break;
                } else if (i == ARRAY_LENGTH - 2) {
                    return _gameBoard[i][j];
                }
            }
        }
    }

    /*
        Win by diagonal
        X - -
        - X -
        - - X
        */
    function winnerByDiagonal(Status[3][3] memory _gameBoard)
        private
        pure
        returns (Status winner)
    {
        // check Left to Right Diagonal
        if (
            _gameBoard[0][0] != Status.None &&
            _gameBoard[0][0] == _gameBoard[1][1] &&
            _gameBoard[1][1] == _gameBoard[2][2]
        ) {
            return _gameBoard[0][0];
        }

        // check Right to Left Diagonal
        if (
            _gameBoard[0][2] != Status.None &&
            _gameBoard[0][2] == _gameBoard[1][1] &&
            _gameBoard[1][1] == _gameBoard[2][0]
        ) {
            return _gameBoard[0][2];
        }
    }

    function isGameBoardFull(Status[3][3] memory _gameBoard)
        private
        pure
        returns (bool isBoardFull)
    {
        for (uint8 i = 0; i < ARRAY_LENGTH; i++) {
            // i stands for row (x-axis)
            for (uint8 j = 0; j < ARRAY_LENGTH; j++) {
                // j stands for column (y-axis)

                if (_gameBoard[i][j] == Status.None) {
                    // if any cell is empty, return false.
                    return false;
                }
            }
        }
        return true;
    }

    function getGameBoard(uint _gameId)
        public
        view
        returns (Status[3][3] memory)
    {
        Status[3][3] memory table = games[_gameId].gameBoard;
        return table;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getEachBalance(address _address) public view returns (uint) {
        return balance[_address];
    }
}
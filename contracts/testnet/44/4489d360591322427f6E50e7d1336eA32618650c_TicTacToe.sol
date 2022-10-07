/**
 *Submitted for verification at testnet.snowtrace.io on 2022-10-07
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract TicTacToe {
    address payable public owner; // owner
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
        uint rewardPool; // total reward pool of the game
        bool isStarted;
        address nextMove; // to decide which wallet will play
        Status[3][3] gameBoard; // 3x3 matrix for game table
        Winner winner; // winner with Enum
        bool isRewardClaimed;
    }

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

    // events
    event GameStarted(uint gameId, address playerOne, uint entryFee);
    event JoinedGame(uint gameId, address playerTwo);
    event MadeMove(uint gameId, uint x, uint y, address player);
    event HaveWinner(uint gameId, Winner winner, uint reward);
    event GameCancelled(uint gameId, address playerOne);

    // constructor
    constructor(uint _commission, uint _MINIMUM_ENTRY_FEE) payable {
        require(_commission < 50, "Commission should be < 50.");
        require(_MINIMUM_ENTRY_FEE >= 100, "Min fee should be >= 100");
        owner = payable(msg.sender);
        commission = _commission;
        MINIMUM_ENTRY_FEE = _MINIMUM_ENTRY_FEE;
        // to match gameId and index for games array.
        Game memory game;
        games.push(game);
    }

    // start a new game by setting entry fee
    function startGame() public payable notPaused {
        require(msg.value > MINIMUM_ENTRY_FEE, "Set fee higher.");

        // user deposits entry fee to the contract
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

        // event
        emit GameStarted(countGame, msg.sender, msg.value);

        countGame++; // increase countGame by 1
    }

    // join an existing game
    function joinGame(uint _gameId) public payable notPaused {
        // pre-checks
        Game memory game = games[_gameId];
        require(msg.value == game.rewardPool, "Wrong entry fee.");
        require(!game.isStarted, "Already started.");
        require(game.playerOne != msg.sender, "You are P1 also.");

        // user deposits entry fee to the contract
        (bool sent, ) = payable(address(this)).call{value: msg.value}("");
        require(sent, "Failed to send Ether");

        // changes for game
        game.playerTwo = msg.sender;
        game.rewardPool += msg.value;
        game.isStarted = true;
        games[_gameId] = game; // writing changes in game variable to games[_gameId].
        // event
        emit JoinedGame(_gameId, msg.sender);
    }

    // playing the game
    function makeMove(
        uint8 _x,
        uint8 _y,
        uint _gameId
    ) public notPaused {
        // pre-checks
        Game memory game = games[_gameId];
        require(game.isStarted, "Not started yet.");
        require(game.winner == Winner.None, "Game is finished.");
        require(game.nextMove == msg.sender, "Not your turn!");
        require(game.gameBoard[_x][_y] == Status.None, "Cell is not empty!");

        // updating selected cell (_x, _y) based on player.
        if (msg.sender == game.playerOne) {
            game.gameBoard[_x][_y] = Status.Player1;
            game.nextMove = game.playerTwo;
        } else if (msg.sender == game.playerTwo) {
            game.gameBoard[_x][_y] = Status.Player2;
            game.nextMove = game.playerOne;
        }

        // event
        emit MadeMove(_gameId, _x, _y, msg.sender);

        // check if game finished after the movement in this transaction
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

            // event
            emit HaveWinner(_gameId, game.winner, game.rewardPool);
        }
    }

    // calculating reward amount based on result and commissions
    function giveRewards(
        uint _rewardPool,
        Winner _winner,
        address _playerOne,
        address _playerTwo
    ) private {
        if (_winner == Winner.PlayerOne) {
            uint reward = (_rewardPool * (100 - commission)) / 100;
            uint com = (_rewardPool * (commission)) / 100;
            balance[_playerOne] += reward; // player balance
            balance[address(this)] += com; // commission balance
        } else if (_winner == Winner.PlayerTwo) {
            uint reward = (_rewardPool * (100 - commission)) / 100;
            uint com = (_rewardPool * (commission)) / 100;
            balance[_playerTwo] += reward; // player balance
            balance[address(this)] += com; // commission balance
        } else if (_winner == Winner.Draw) {
            // there is no commission for draw resulted games
            uint reward = (_rewardPool / 2);
            balance[_playerOne] += reward;
            balance[_playerTwo] += reward;
        }
    }

    // claiming rewards
    function claimRewards(uint _amount) public payable {
        require(balance[msg.sender] >= _amount, "Not enough balance.");
        balance[msg.sender] -= _amount;
        (bool sent, ) = payable(msg.sender).call{value: _amount}("");
        require(sent, "Failed to claim rewards.");
        // payable(msg.sender).transfer(msg.value);
    }

    // withdraw commissions by owner
    function withdraw(uint _amount) public payable onlyOwner {
        require(balance[address(this)] >= _amount, "Not enough balance.");
        balance[address(this)] -= _amount;
        (bool sent, ) = payable(msg.sender).call{value: _amount}("");
        require(sent, "Failed to withdraw.");
    }

    // player 1 is able to cancel game to get payment back if anyone doesn't join within 24 hour
    function cancelGame(uint _gameId) public {
        // pre-checks
        Game memory game = games[_gameId];
        require(!game.isStarted, "Game is started.");
        require(
            game.creatingTime + 1 days < block.timestamp,
            "Should pass 1 day."
        );
        require(game.playerOne == msg.sender, "Only creator can cancel.");
        delete games[_gameId]; // deleting game from array
        // getting money back
        (bool sent, ) = payable(msg.sender).call{value: game.rewardPool}("");
        require(sent, "Failed to send.");

        // event
        emit GameCancelled(_gameId, msg.sender);
    }

    // pause/continue all games by owner
    function toggleContract() public onlyOwner {
        pausedAllGames = !pausedAllGames;
    }

    // helper function to check whether game is finished
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

    // helper function to check game board is full
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

    // getting game board for a specific game
    function getGameBoard(uint _gameId)
        public
        view
        returns (Status[3][3] memory)
    {
        Status[3][3] memory table = games[_gameId].gameBoard;
        return table;
    }

    // getting balance of the contract
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    // getting player's claimable reward balance
    function getEachBalance(address _address) public view returns (uint) {
        return balance[_address];
    }

    // getting all games array
    function getGames() public view returns (Game[] memory) {
        return games;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}
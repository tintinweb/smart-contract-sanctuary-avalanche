// SPDX-License-Identifier: MIT

pragma solidity >=0.8.2 <0.9.0;

error LowFunds(address adr, uint256 balance);
error NotAdmin(address adr);
error GameOver();
error Yourself(address adr);
error Check(uint256 num);

contract standards {
    address private admin;

    constructor() {
        admin = msg.sender;
    }

    function withdraw() external {
        if (msg.sender == admin) {
            payable(admin).transfer(address(this).balance);
        }
    }
}

contract HI_LO is standards {
    event Log(uint256 cs, address from, uint256 time);

    uint256 fee;
    uint256 min;
    uint256 t;
    uint256 public g;

    struct Game {
        uint256 id;
        uint256 value;
        address payable owner;
        uint256 t0;
        bool c0; // 1 lo // 2 hi
        address payable opponent;
        uint256 t1;
        bool c1; // 1 lo // 2 hi
        uint256 state; // 0 invalid // 1 created // 2 played // 3 finished
        uint256 result;
    }

    mapping(uint256 => Game) public games;
    mapping(address => uint256) private myGames;
    mapping(address => mapping(uint256 => Game)) public myGame;
    mapping(uint256 => bool) played;

    constructor() {
        t = 1 + (block.timestamp % 9);
        fee = 25;
        min = 1 * 10**15;
        g = 1;
    }

    function setGame(bool _choice) external payable {
        if (msg.value <= min) revert LowFunds(msg.sender, min);
        (bool found, uint256 id) = _scanGames(msg.value, _choice);
        if (found) {
            // aggregated
            Game memory game = games[id];
            _play(game);
        } else {
            games[g] = Game(
                g,
                msg.value,
                payable(msg.sender),
                block.timestamp,
                _choice,
                payable(address(0)),
                0,
                !_choice,
                1,
                0
            );
            myGame[msg.sender][myGames[msg.sender]] = games[g];
            myGames[msg.sender]++;
            played[g] = false;
            g++;
        }
    }

    function _scanGames(uint256 _value, bool _choice)
        internal
        view
        returns (bool find, uint256 id)
    {
        for (uint256 i; i < g; i++) {
            if (
                games[i].value == _value &&
                games[i].owner != msg.sender &&
                games[i].c0 != _choice &&
                games[i].state == 1
            ) {
                find = true;
                id = i;
                i += g;
            } else {
                find = false;
                id = 0;
            }
        }
    }

    function joinGame(uint256 _game) external payable {
        Game memory game = games[_game];
        if (msg.value < game.value) revert LowFunds(msg.sender, game.value);
        if (game.state != 1) revert GameOver();
        if (msg.sender == game.owner) revert Yourself(msg.sender);
        _play(game);
    }

    function _play(Game memory _game) internal {
        if (_game.state != 1 || _game.id >= g) revert GameOver();
        _game.opponent = payable(msg.sender);
        _game.t1 = block.timestamp;
        _game.state = 2;
        games[_game.id] = _game;
        myGame[msg.sender][myGames[msg.sender]] = _game;
        myGames[msg.sender]++;
        uint256 x = (_game.t1 + t) % 9;
        uint256 y = (_game.t0 + x) % 9;
        uint256 checksum = ((t * x * y) + (block.timestamp - (t + x + y))) % 9;
        emit Log(checksum, msg.sender, block.timestamp);
        _game.result = checksum;
        uint256 win = ((_game.value * 2) / 1000) * (1000 - fee);
        _game.state = 3;
        games[_game.id] = _game;
        played[_game.id] = true;
        if (_game.c0) {
            if (checksum < 5) {
                _game.owner.transfer(win);
            }
            // player 2 wins
            else {
                _game.opponent.transfer(win);
            } // player 1 wins
        } else {
            // player 1 lo
            if (checksum < 5) {
                _game.opponent.transfer(win);
            }
            // player 1 wins
            else {
                _game.owner.transfer(win);
            } // player 2 wins
        }
    }
}
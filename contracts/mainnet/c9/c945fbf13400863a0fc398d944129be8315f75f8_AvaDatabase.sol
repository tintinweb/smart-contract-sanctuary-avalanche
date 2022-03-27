/**
 *Submitted for verification at snowtrace.io on 2022-03-27
*/

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: Games/AvaDatabase.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract AvaDatabase is Ownable {

    struct RoundInfo {
        uint roundID;
        mapping(address => uint) playedGames;
        mapping(address => uint) playedGamesperGame;
        mapping(address => uint) wonGames;
        mapping(address => uint) playedAmount;
        mapping(address => uint) playedAmountperGame;
        mapping(address => uint) wonAmount;
        mapping(address => uint) lostAmount;
    }

    address[] public users;
    address[] public games;
    mapping(address => bool) added;
    mapping(address => bool) isGame;

    uint public currentRoundID;
    RoundInfo[] public rounds;

    constructor() {
        rounds.push();
    }

    function addGame(address _gameAddress) external onlyOwner{
        isGame[_gameAddress] = true;
        games.push(_gameAddress);
    }

    
    function removeGame(address _gameAddress) external onlyOwner{
        isGame[_gameAddress] = false;
    }


    function updateStatistics(address player, bool isWin, uint _playedAmount, uint _wonAmount) public {
        require(isGame[msg.sender]);
        RoundInfo storage roundInfo = rounds[currentRoundID];
        if(!added[player]) {
            users.push(player);
            added[player] = true;
        }
        roundInfo.playedGames[player]++;
        roundInfo.playedGamesperGame[msg.sender]++;
        if(isWin){
            roundInfo.wonGames[player]++;
            roundInfo.playedAmount[player] += _playedAmount;
            roundInfo.playedAmountperGame[msg.sender] += _playedAmount;
            roundInfo.wonAmount[player] += _wonAmount;
        }
        else {
            roundInfo.playedAmount[player] += _playedAmount;
            roundInfo.playedAmountperGame[msg.sender] += _playedAmount;
            roundInfo.lostAmount[player] += _playedAmount;
        }
    }

    function getInfoOfUser(address player, uint roundID) external view returns (uint gameNo, uint wonNo, uint lostNo, uint playedAmn,uint wonAmn,uint lostAmn){
        RoundInfo storage roundInfo = rounds[roundID];
        gameNo = roundInfo.playedGames[player];
        wonNo = roundInfo.wonGames[player];
        lostNo = roundInfo.playedGames[player] - roundInfo.wonGames[player];
        playedAmn = roundInfo.playedAmount[player];
        wonAmn = roundInfo.wonAmount[player];
        lostAmn = roundInfo.lostAmount[player];
    }

    function getTotalInfo(uint roundID) external view returns (uint gameNo, uint wonNo, uint lostNo, uint playedAmn, uint wonAmn, uint lostAmn){
        RoundInfo storage roundInfo = rounds[roundID];
        for(uint i = 0; i < users.length; i++) {
            gameNo += roundInfo.playedGames[users[i]];
            wonNo += roundInfo.wonGames[users[i]];
            lostNo += roundInfo.playedGames[users[i]] - roundInfo.wonGames[users[i]];
            playedAmn += roundInfo.playedAmount[users[i]];
            wonAmn += roundInfo.wonAmount[users[i]];
            lostAmn += roundInfo.lostAmount[users[i]];
        }
    }

    function getGameInforForRound(address _game, uint _roundID) external view returns (uint gameCountPG, uint playedAmountPG) {
        RoundInfo storage roundInfo = rounds[_roundID];
        gameCountPG = roundInfo.playedGamesperGame[_game];
        playedAmountPG = roundInfo.playedAmountperGame[_game];
    }

    function startNewRound() external {
        require(isGame[msg.sender] || msg.sender == owner());
        currentRoundID++;
        rounds.push();
    }
}
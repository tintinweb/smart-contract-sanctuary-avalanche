// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract BridgesOfFate is Ownable, ReentrancyGuard {
    IERC20 private token;
    uint256 private latestGameId = 1;
    uint256 public lastUpdateTimeStamp;

    uint256 private constant STAGES = 7; // 13 stages
    uint256 private constant TURN_PERIOD = 120; //Now we are use 5 minute //86400; // 24 HOURS
    uint256 private constant THERSHOLD = 800; //5
    uint256 private constant SERIES_TWO_FEE = 0.01 ether;
    uint256 private constant _winnerRewarsdsPercent = 60;
    uint256 private constant _ownerRewarsdsPercent = 25;
    uint256 private constant _communityVaultRewarsdsPercent = 15;
    bytes32[] private gameWinners;
    bytes32[] private participatePlayerList;


    // 0 =========>>>>>>>>> Owner Address
    // 1 =========>>>>>>>>> community vault Address
    address[2] private communityOwnerWA = [
        0xBE0c66A87e5450f02741E4320c290b774339cE1C,
        0x1eF17faED13F042E103BE34caa546107d390093F
    ];

    uint256[11] public buyBackCurve = [
        0.005 ether,
        0.01 ether,
        0.02 ether,
        0.04 ether,
        0.08 ether,
        0.15 ether,
        0.3 ether,
        0.6 ether,
        1.25 ether,
        2.5 ether,
        5 ether
    ];

    struct GameStatus {
        //Game Start Time
        uint256 startAt;
        //To Handle Latest Stage
        uint256 stageNumber;
        //Last Update Number
        uint256 lastUpdationDay;
    }

    struct GameItem {
        uint256 day;
        uint256 nftId;
        uint256 stage;
        uint256 startAt;
        uint256 lastJumpTime;
        bool lastJumpSide;
        bool feeStatus;
        address userWalletAddress;
    }
    
    mapping(uint256 => uint256) private GameMap;
    mapping(bytes32 => uint256) private winnerbalances;
    mapping(address => uint256) private ownerbalances;
    mapping(address => uint256) private vaultbalances;
    mapping(uint256 => bytes32[]) private allStagesData;

    mapping(bytes32 => GameItem) public PlayerItem;
    mapping(uint256 => GameStatus) public GameStatusInitialized;
    
    event Initialized(uint256 currentGameID, uint256 startAt);
    event ParticipateOfPlayerInGame(bytes32 playerId, uint256 _randomNo);
    event ParticipateOfPlayerInBuyBackIn(bytes32 playerId, uint256 amount);
    event EntryFee(bytes32 playerId,uint256 nftId,uint256 nftSeries,uint256 feeAmount);
    event ParticipateOfNewPlayerInLateBuyBackIn(bytes32 playerId,uint256 moveAtStage,uint256 amount);

    constructor(IERC20 _wrappedEther) {
        token = _wrappedEther;
    }
    
    modifier GameEndRules() {
        GameStatus storage _gameStatus = GameStatusInitialized[latestGameId];
        require(block.timestamp >= _gameStatus.startAt,"Game start after intialized time.");
        require(_dayDifferance(block.timestamp, lastUpdateTimeStamp) <= 2,"Game Ended !");
        require(_dayDifferance(block.timestamp, _gameStatus.startAt) <= (STAGES + THERSHOLD) - 1, "Game Achived thershold!");
        _;
    }

    // modifier GameInitialized() {
    //     GameStatus storage _gameStatus = GameStatusInitialized[latestGameId];
    //     _;
    // }

    function _dayDifferance(uint256 timeStampTo, uint256 timeStampFrom) internal pure returns (uint256)
    {
        return (timeStampTo - timeStampFrom) / TURN_PERIOD;
    }

    function initializeGame(uint256 _startAT) external onlyOwner {
        GameStatus storage _gameStatus = GameStatusInitialized[latestGameId];
        require(_gameStatus.startAt == 0, "Game Already Initilaized"); 
        require(_startAT >= block.timestamp,"Time must be greater then current time.");
        _gameStatus.startAt = _startAT;
        lastUpdateTimeStamp = _startAT;
        emit Initialized(latestGameId, block.timestamp);
    }

    function allParticipatePlayerID() external view returns(bytes32[] memory) {
        return participatePlayerList;
    }

    function _updatePlayer(bytes32 _playerId) internal {
        GameItem memory _member = PlayerItem[_playerId];
        _member.day = 0;    
        _member.stage = 0;
        _member.startAt = 0;
        _member.lastJumpTime = 0;
        _member.lastJumpSide = false;
        PlayerItem[_playerId] = _member;
    }

    function _deletePlayerIDForSpecifyStage(uint256 _stage, bytes32 _playerId) internal {
        for (uint i = 0; i < allStagesData[_stage].length; i++) {
            if(allStagesData[_stage][i] == _playerId){
                delete allStagesData[_stage][i];
            }
        }
    }

    function getStagesData(uint256 _stage) public view  returns (bytes32[] memory) {
        return allStagesData[_stage];
    }

    function computeNextPlayerIdForHolder(address holder,uint256 _nftId,uint8 _seriesIndex) public pure returns (bytes32) {
        return _computePlayerIdForAddressAndIndex(holder, _nftId, _seriesIndex);
    }

    function _computePlayerIdForAddressAndIndex(address holder,uint256 _nftId,uint8 _seriesIndex) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(holder, _nftId, _seriesIndex));
    }


    function changeCommunityOwnerWA(address[2] calldata _communityOwnerWA) external onlyOwner {
        for (uint i = 0; i < _communityOwnerWA.length; i++) {
            communityOwnerWA[i] = _communityOwnerWA[i];
        }
    }

    function _checkSide(uint256 stageNumber, bool userSide) internal view returns (bool)
    {
        uint256 stage_randomNumber = GameMap[stageNumber]; 
        if ((userSide == true && stage_randomNumber >= 50e9) || (userSide == false && stage_randomNumber < 50e9)
        ) {
            return true;
        } else {
            return false;
        }
    }

    function isExist(bytes32 _playerID) public view returns(bool){
        for (uint i = 0; i < participatePlayerList.length; i++) {
            if(participatePlayerList[i] == _playerID){
                return false;
            }
        }     
        return true;
    }

    function entryFeeForSeriesOne(uint256 _nftId) public GameEndRules
    {
        bytes32 playerId = computeNextPlayerIdForHolder(msg.sender, _nftId, 1);
        if(isExist(playerId)){
            participatePlayerList.push(playerId);    
        }
        GameItem memory _member = PlayerItem[playerId];
        if (_member.userWalletAddress != address(0)) {
            GameStatus storage _admin = GameStatusInitialized[latestGameId];
            require(_dayDifferance(block.timestamp, _admin.startAt) > _member.day, "Alreday In Game");
            require(_checkSide(_member.stage, _member.lastJumpSide) == false, "Already In Game");
            require(_dayDifferance(_member.lastJumpTime,_admin.startAt) + 1 < _dayDifferance(block.timestamp, _admin.startAt),"You Can only use Buy back in 24 hours");
            _updatePlayer(playerId);
        }
        _member.nftId = _nftId;
        _member.feeStatus = true;
        _member.userWalletAddress = msg.sender;
        PlayerItem[playerId] = _member;
        allStagesData[_member.stage].push(playerId);
        lastUpdateTimeStamp = block.timestamp;
        emit EntryFee(playerId, _nftId, 1, 0);
    }

    function bulkEntryFeeForSeriesOne(uint256[] calldata _nftId) external {
        for (uint256 i = 0; i < _nftId.length; i++) {
            entryFeeForSeriesOne(_nftId[i]);
        }
    }

    function _balanceOfUser(address _accountOf) internal view returns (uint256) {
        return token.balanceOf(_accountOf);
    }

    function entryFeeSeriesTwo(uint256 _nftId) public GameEndRules
    {
        bytes32 playerId = computeNextPlayerIdForHolder(msg.sender, _nftId, 2);
          if(isExist(playerId)){
            participatePlayerList.push(playerId);    
        }
        GameItem memory _member = PlayerItem[playerId];

        if (_member.userWalletAddress != address(0)) {
            GameStatus storage _admin = GameStatusInitialized[latestGameId];
            require(_dayDifferance(block.timestamp, _admin.startAt) > _member.day, "Alreday In Game");
            require(_checkSide(_member.stage, _member.lastJumpSide) == false, "Already In Game");
            require(_dayDifferance(_member.lastJumpTime,_admin.startAt) + 1 < _dayDifferance(block.timestamp, _admin.startAt),"You Can only use Buy back in 24 hours");
            _updatePlayer(playerId);
        } 
        _member.feeStatus = true;
        _member.nftId = _nftId;
        _member.userWalletAddress = msg.sender;
        _transferAmount(SERIES_TWO_FEE);
        PlayerItem[playerId] = _member;
        allStagesData[_member.stage].push(playerId);
        lastUpdateTimeStamp = block.timestamp;
        emit EntryFee(playerId, _nftId, 2, SERIES_TWO_FEE);
    }


    function bulkEntryFeeSeriesTwo(uint256[] calldata _nftId) external {
        for (uint256 i = 0; i < _nftId.length; i++) {
            entryFeeSeriesTwo(_nftId[i]);
        }
    }


    function buyBackInFee(bytes32 playerId) public GameEndRules
    {
        uint256 buyBackFee = calculateBuyBackIn();
        require(_balanceOfUser(msg.sender) >= buyBackFee,"You have insufficent balance");
        GameItem memory _member = PlayerItem[playerId];
        // require(_member.userWalletAddress != address(0), "Record Not Found");
        require((_member.userWalletAddress != address(0)) && (_member.userWalletAddress == msg.sender),"Only Player Trigger");
        require(_dayDifferance(block.timestamp, _member.lastJumpTime) <= 1,"Buy Back can be used in 24 hours only");
        require(_checkSide(_member.stage, _member.lastJumpSide) == false, "Already In Game");
        token.transferFrom(msg.sender, address(this), buyBackFee);
        if (GameMap[_member.stage - 1] >= 50e9) {
            _member.lastJumpSide = true;
        }
        if (GameMap[_member.stage - 1] < 50e9) {
            _member.lastJumpSide = false;
        }
        _member.stage = _member.stage - 1;
        _member.day = 0;
        _member.feeStatus = true;
        _member.lastJumpTime = block.timestamp;
        PlayerItem[playerId] = _member;
        allStagesData[_member.stage].push(playerId);
        _deletePlayerIDForSpecifyStage(_member.stage + 1,playerId);
        emit ParticipateOfPlayerInBuyBackIn(playerId, buyBackFee);
    }

    function _random() internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp,block.difficulty,msg.sender))) % 100;
    }
    
    function bulkParticipateInGame(bool _jumpSides, bytes32[] memory playerIds) external   GameEndRules {
        for (uint256 i = 0; i < playerIds.length; i++) {
            require(PlayerItem[playerIds[0]].stage == PlayerItem[playerIds[i]].stage, "Same Stage Players jump");
            participateInGame(_jumpSides,playerIds[i]);
        }
    }

    function switchSide(bool _jumpSide, bytes32 playerId) public  GameEndRules{
        GameItem memory _member = PlayerItem[playerId];
        require(_dayDifferance(block.timestamp,GameStatusInitialized[latestGameId].startAt) == _member.day, "Only Jump in this Slot");
        require(_member.lastJumpSide != _jumpSide, "Opposite side jump would be possible");
        require(_member.feeStatus == true, "Please Pay Entry Fee.");
        require(_member.userWalletAddress == msg.sender,"Only Player Trigger");
        require(_member.stage != STAGES, "Reached maximum");
        _member.lastJumpSide = _jumpSide;
        PlayerItem[playerId] = _member;
        lastUpdateTimeStamp = block.timestamp;
    }

    function participateInGame(bool _jumpSide, bytes32 playerId) public  GameEndRules
    {
        GameItem memory _member = PlayerItem[playerId];
        GameStatus memory  _gameStatus = GameStatusInitialized[latestGameId];
        uint256 currentDay = _dayDifferance(block.timestamp,_gameStatus.startAt);
        require(_member.userWalletAddress == msg.sender,"Only Player Trigger");
        require(_member.feeStatus == true, "Please Pay Entry Fee.");
        if (_member.startAt == 0 && _member.lastJumpTime == 0) {
            //On First Day when current day & member day = 0
            require(currentDay >= _member.day, "Already Jump Once In Slot");
        } else {
            //for other conditions
            require(currentDay > _member.day, "Already Jump Once In Slot");
        }
        if (_member.stage != 0) {
            require((_member.lastJumpSide == true && GameMap[_member.stage] >= 50e9) || (_member.lastJumpSide == false && GameMap[_member.stage] < 50e9), "You are Failed" );
        }
        if((_gameStatus.stageNumber == STAGES) && (_dayDifferance(block.timestamp,_gameStatus.startAt) > _gameStatus.lastUpdationDay)){
            revert("Game Reached maximum && End.");
        }
        require(_member.stage != STAGES, "Reached maximum");
        if (GameMap[_member.stage + 1] <= 0) {
            GameMap[_gameStatus.stageNumber + 1] = _random() * 1e9;
            _gameStatus.stageNumber = _gameStatus.stageNumber + 1;
            _gameStatus.lastUpdationDay = currentDay;
        }

        allStagesData[_member.stage + 1].push(playerId);
        _deletePlayerIDForSpecifyStage(_member.stage,playerId);
        _member.startAt = block.timestamp;
        _member.stage = _member.stage + 1;
        _member.day = currentDay;
        _member.lastJumpSide = _jumpSide;
        _member.lastJumpTime = block.timestamp;
        PlayerItem[playerId] = _member;
        GameStatusInitialized[latestGameId] = _gameStatus;
        lastUpdateTimeStamp = block.timestamp;
        //Push winner into the Array list 
        if(_checkSide(GameMap[_gameStatus.stageNumber],_jumpSide) && (_member.stage  == STAGES)){
            gameWinners.push(playerId);
        }
        emit ParticipateOfPlayerInGame(playerId,GameMap[_gameStatus.stageNumber + 1]);
    }

    function getAll() external view returns (uint256[] memory) {
        GameStatus storage _gameStatus = GameStatusInitialized[latestGameId];
        uint256[] memory ret;
        uint256 _stageNumber;
        if (_gameStatus.stageNumber > 0) {
            if (_dayDifferance(block.timestamp, _gameStatus.startAt) > _gameStatus.lastUpdationDay) {
                _stageNumber = _gameStatus.stageNumber;
            } else {
                _stageNumber = _gameStatus.stageNumber - 1;
            }

            ret = new uint256[](_stageNumber);
            for (uint256 i = 0; i < _stageNumber; i++) {
                ret[i] = GameMap[i + 1];
            }
        }
        return ret;
    }

    function calculateBuyBackIn() public view returns (uint256) {
        if (GameStatusInitialized[latestGameId].stageNumber > 0) {
            if (GameStatusInitialized[latestGameId].stageNumber <= buyBackCurve.length) {
                return buyBackCurve[GameStatusInitialized[latestGameId].stageNumber - 1];
            }
        }
        return 0;
    }

    function LateBuyInFee(uint256 _nftId, uint8 seriesType) public GameEndRules
    {
        require(seriesType == 1 || seriesType == 2, "Invalid seriseType");
        bytes32 playerId = computeNextPlayerIdForHolder(msg.sender,_nftId,seriesType);
        if(isExist(playerId)){
            participatePlayerList.push(playerId);    
        }
        uint256 buyBackFee = calculateBuyBackIn();
        uint256 totalAmount;
        if (seriesType == 1) {
            totalAmount = buyBackFee;
        }
        if (seriesType == 2) {
            totalAmount = buyBackFee + SERIES_TWO_FEE;
        }
        _transferAmount(totalAmount);
        GameStatus storage _gameStatus = GameStatusInitialized[latestGameId];
        GameItem memory _member = PlayerItem[playerId];
        _member.userWalletAddress = msg.sender;
        _member.startAt = block.timestamp;
        _member.stage = _gameStatus.stageNumber - 1;
        _member.day = 0;
        if (GameMap[_gameStatus.stageNumber - 1] >= 50e9) {
            _member.lastJumpSide = true;
        }
        if (GameMap[_gameStatus.stageNumber - 1] < 50e9) {
            _member.lastJumpSide = false;
        }
        _member.feeStatus = true;
        _member.lastJumpTime = block.timestamp;
        PlayerItem[playerId] = _member;
        lastUpdateTimeStamp = block.timestamp;
        allStagesData[_member.stage].push(playerId);
        emit ParticipateOfNewPlayerInLateBuyBackIn(playerId,_gameStatus.stageNumber - 1,totalAmount);
    }

    function bulkLateBuyInFee(uint256[] calldata _nftId,uint8[] calldata seriesType) external {
        for (uint256 i = 0; i < _nftId.length; i++) {
            LateBuyInFee(_nftId[i], seriesType[i]);
        }
    }

    // function restartGame(uint256 _nftId, uint8 seriesType) external {
    //     require(seriesType == 1 || seriesType == 2, "Invalid seriseType");
    //     bytes32 playerId = computeNextPlayerIdForHolder(msg.sender,_nftId,seriesType);
    //     GameItem storage _member = PlayerItem[playerId];
    //     require(_member.userWalletAddress != address(0), "Record Not Found");
    //     require(_member.stage == 1, "Only used if u fail on first stage");
    //     require(_dayDifferance(block.timestamp, GameStatusInitialized[latestGameId].startAt) > _member.day, "Alreday In Game");
    //     require(_checkSide(_member.stage, _member.lastJumpSide) == false, "Already In Game");
    //     _updatePlayer(playerId);
    //     _member.nftId = _nftId;
    //     _member.userWalletAddress = msg.sender;
    // }

    function _transferAmount(uint256 _amount) internal {
        require(_balanceOfUser(msg.sender) >= _amount,"You have insufficent balance");
        token.transferFrom(msg.sender, address(this), _amount);
    }

    function treasuryBalance() public view returns (uint256) {
        return _balanceOfUser(address(this));
    }

    function calculateReward() public onlyOwner  {
        uint256 _treasuryBalance = treasuryBalance();
        // 60 % reward goes to winnner.
        require(_treasuryBalance > 0 ,"Insufficient Balance");
        require(GameStatusInitialized[latestGameId].stageNumber == STAGES,"It's not time to Distribution");
        // 25% to owner wallet
        ownerbalances[communityOwnerWA[0]] = (_ownerRewarsdsPercent * _treasuryBalance) / 100;
        // 15% goes to community vault
        vaultbalances[communityOwnerWA[1]] = (_communityVaultRewarsdsPercent * _treasuryBalance) / 100;
        if(gameWinners.length > 0){
            uint256 _winners = (((_winnerRewarsdsPercent * _treasuryBalance)) / 100) / (gameWinners.length);
            for (uint256 i = 0; i < gameWinners.length; i++) {
                winnerbalances[gameWinners[i]] = _winners;
            }
        } 
    }

    function withdraw(uint256 withdrawAmount) internal {
        token.transfer(msg.sender, withdrawAmount);
    }

    function withdrawWrappedEtherOFCommunity(uint8 withdrawtype) public nonReentrant 
    {
        // Check enough balance available, otherwise just return false
        if (withdrawtype == 0) {
            //owner
            require(ownerbalances[communityOwnerWA[0]] > 0,"Insufficient Owner Balance");
            require(communityOwnerWA[0] == msg.sender, "Only Owner use this");
            withdraw(ownerbalances[msg.sender]);
        } else if (withdrawtype == 1) {
            //vault
            require(vaultbalances[communityOwnerWA[1]] > 0,"Insufficient Vault Balance");
            require(communityOwnerWA[1] == msg.sender, "Only vault use this");
            withdraw(vaultbalances[msg.sender]);
        } 
    }

    function claimWinnerEther(bytes32 playerId) external nonReentrant {
        require(winnerbalances[playerId] > 0,"Insufficient Plyer Balance");
        require(PlayerItem[playerId].userWalletAddress == msg.sender,"Only Player Trigger");
        withdraw(winnerbalances[playerId]);
    }    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
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
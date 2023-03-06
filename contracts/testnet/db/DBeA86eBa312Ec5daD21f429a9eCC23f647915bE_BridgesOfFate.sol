// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract BridgesOfFate is Ownable {
    IERC20 private token;

    uint256 public _narrowingGameMap;
    uint256 public lastUpdateTimeStamp;
    uint256 public _NarrowingNumberProbility;

    // uint256 private _totalRewardPerUser;
    // uint256 private _bulkNftCounter  = 0;
    // uint256 private constant CAPACITY = 5; //title Capacity 

    uint256[] private  playerIndex;
    uint256 private latestGameId = 1;
    uint256 private constant TURN_PERIOD = 300; // 5 minutes // 3 hours 10800
    uint256 private constant SERIES_TWO_FEE = 0.01 ether;
    uint256 private constant _winnerRewarsdsPercent = 60;
    uint256 private constant _ownerRewarsdsPercent = 25;
    uint256 private constant _communityVaultRewarsdsPercent = 15;
 
    bool public isNarrowingGameEnded = false;
    
    bytes32[] private gameWinners;
    bytes32[] private participatePlayerList;

    // 0 =========>>>>>>>>> Owner Address
    // 1 =========>>>>>>>>> community vault Address
    address[2] private communityOwnerWA;

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
        //Balance distribution 
        bool isDistribution;
    }
    
    struct GameItem {
        uint256 day;
        uint256 nftId;
        uint256 stage;
        uint256 startAt;
        uint256 lastJumpTime;
        uint8 nftSeriestype;
        bool feeStatus;
        bool ishold;
        bool lastJumpSide;
        address userWalletAddress;
        bytes32 playerId;
    }
    
    mapping(bytes32 => GameItem) public PlayerItem;
    mapping(uint256 => GameStatus) public GameStatusInitialized;
    
    mapping(uint256 => uint256) private GameMap;
    // mapping(uint256 => uint256) public NarrowingGameMap; // Change as per requirement

    mapping(bytes32 => uint256) private winnerbalances;
    mapping(address => uint256) private ownerbalances;
    mapping(address => uint256) private vaultbalances;
    mapping(uint256 => bytes32[]) private allStagesData;
    
    mapping(bytes32 => bool) public OverFlowPlayerStatus; // change
    mapping(uint256 => uint256) public TitleCapacityAgainestStage; //change
    // Againest Stage Number and Side set the number of nft's
    mapping(uint256 => mapping(bool => uint256)) public totalNFTOnTile; //change

    event Initialized(uint256 _startAt);
    event claimPlayerReward(bytes32 playerId, uint256 amount);
    event ParticipateOfPlayerInGame(bytes32 playerId,uint256 jumpAt);
    event ParticipateOfPlayerInBuyBackIn(bytes32 playerId, uint256 amount);
    event EntryFee(bytes32 playerId,uint256 nftId,uint256 nftSeries,uint256 feeAmount);
    event ParticipateOfNewPlayerInLateBuyBackIn(bytes32 playerId,uint256 moveAtStage,uint256 amount);

    constructor(IERC20 _wrappedEther,address _owner,address _commuinty) {
        token = _wrappedEther;
        communityOwnerWA[0] = _owner;
        communityOwnerWA[1] = _commuinty;
        _NarrowingNumberProbility =  10;
    }

    modifier GameEndRules() {
        GameStatus storage _gameStatus = GameStatusInitialized[latestGameId];
        require((_gameStatus.startAt > 0 && block.timestamp >= _gameStatus.startAt),"Game start after intialized time.");
        // require(_dayDifferance(block.timestamp, lastUpdateTimeStamp) <= 2,"Game Ended !");
        _;
    }


    modifier NarrowingGameEndRules() {
        if((_narrowingGameMap > 0) && (_narrowingGameMap  < _NarrowingNumberProbility) 
            && (_dayDifferance(block.timestamp,GameStatusInitialized[latestGameId].startAt) > GameStatusInitialized[latestGameId].lastUpdationDay))
        {
            require(isNarrowingGameEnded == true ,"Narrowing Game Ended.");
        }
        _;
    }

    function _removeForList(uint index)  internal{
        gameWinners[index] =  gameWinners[gameWinners.length - 1];
        gameWinners.pop();
    }

    function _random() internal view returns (uint256) {
            return uint256(keccak256(abi.encodePacked(block.timestamp,block.difficulty,msg.sender))) % 100 == 0 
        ? 1 : uint256(keccak256(abi.encodePacked(block.timestamp,block.difficulty,msg.sender))) % 100;
    }

    function _balanceOfUser(address _accountOf) internal view returns (uint256) {
        return token.balanceOf(_accountOf);
    }
     
    function _transferAmount(uint256 _amount) internal {
        require(_balanceOfUser(msg.sender) >= _amount,"Insufficient balance");
        token.transferFrom(msg.sender, address(this), _amount);
    }

    function _randomNarrowingGame() internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(address(this),block.timestamp,block.difficulty,msg.sender,address(0)))) % 100 == 0 
        ? 1 : uint256(keccak256(abi.encodePacked(address(this),block.timestamp,block.difficulty,msg.sender,address(0)))) % 100;
    }

    function removeSecondListItem(uint index,uint256 _stages)  internal {
        bytes32[] storage _stagesData = allStagesData[_stages];
        _stagesData[index] =  _stagesData[_stagesData.length - 1];
        _stagesData.pop();
    }

    function treasuryBalance() public view returns (uint256) {
        return _balanceOfUser(address(this));
    }

    function _distributionReward() internal {
        uint256 _treasuryBalance = treasuryBalance();
        require(_treasuryBalance > 0 ,"Insufficient Balance");
        require(isNarrowingGameEnded == false," Distribution time should not start before reaching final stage.");
            if(GameStatusInitialized[latestGameId].isDistribution){
                // 25% to owner wallet owner 
                ownerbalances[communityOwnerWA[0]] = (_ownerRewarsdsPercent * _treasuryBalance) / 100;
                //vault 15% goes to community vault
                vaultbalances[communityOwnerWA[1]] = (_communityVaultRewarsdsPercent * _treasuryBalance) / 100;
                //Player
                if(gameWinners.length > 0){
                    for (uint i = 0; i < gameWinners.length; i++) {
                        // winnerbalances[gameWinners[i]]  = (((_winnerRewarsdsPercent * treasuryBalance())) / 100) / (gameWinners.length);
                        winnerbalances[gameWinners[i]]  = (((_winnerRewarsdsPercent * _treasuryBalance)) / 100) / (gameWinners.length);
                    }
                }
            }
    }

    function _withdraw(uint256 withdrawAmount) internal {
        token.transfer(msg.sender, withdrawAmount);
    }

    function _calculateBuyBackIn() internal view returns (uint256) {
        if (GameStatusInitialized[latestGameId].stageNumber > 0) {
            if (GameStatusInitialized[latestGameId].stageNumber <= buyBackCurve.length) {
                return buyBackCurve[GameStatusInitialized[latestGameId].stageNumber - 1];
            }else if(GameStatusInitialized[latestGameId].stageNumber > buyBackCurve.length){
                return buyBackCurve[buyBackCurve.length - 1];
            }
        }
        return 0;
    }

    function getStagesData(uint256 _stage) public view  returns (bytes32[] memory) {
        return allStagesData[_stage];
    }

    function _deletePlayerIDForSpecifyStage(uint256 _stage, bytes32 _playerId) internal {
        removeSecondListItem(_findIndex(_playerId,getStagesData(_stage)),_stage);
    }

    function _checkSide(uint256 stageNumber, bool userSide) internal view returns (bool){
        uint256 stage_randomNumber = GameMap[stageNumber]; 
        if ((userSide == false && stage_randomNumber < 50e9) || (userSide == true && stage_randomNumber >= 50e9)) {
            return true;
        }else {
            return false;
        }
    }

    function _findIndex(bytes32 _fa,bytes32[] memory _playerList)  internal pure returns(uint index){
        for (uint i = 0; i < _playerList.length; i++) {
            if(_playerList[i] == _fa){
               index =  i;
            }
        }
        return index;
    }

    function _dayDifferance(uint256 timeStampTo, uint256 timeStampFrom) public pure returns (uint256){
        return (timeStampTo - timeStampFrom) / TURN_PERIOD;
    }

    function _computeNextPlayerIdForHolder(address holder,uint256 _nftId,uint8 _seriesIndex) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(holder, _nftId, _seriesIndex));
    }
    
    function generateRandomTicketNumbers(uint256 _lotteryCount,uint256 _range,uint256 _length) public view returns (uint8[6] memory) {
        uint8[6] memory numbers;
        uint256 generatedNumber;

        // Execute 5 times (to generate 5 numbers)
        for (uint256 i = 0; i < _length; i++) {
            //   Check duplicate
            bool readyToAdd = false;
            uint256 maxRetry = _length;
            uint256 retry = 0;

            // Generate a new number while it is a duplicate, up to 5 times (to prevent errors and infinite loops)
            while (!readyToAdd && retry <= maxRetry) {
                generatedNumber = (uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, i, retry, _lotteryCount))) % _range) +1;
                bool isDuplicate = false;

                // Look in all already generated numbers array if the new generated number is already there.
                for (uint256 j = 0; j < numbers.length; j++) {
                    if (numbers[j] == generatedNumber) {
                        isDuplicate = true;
                        break;
                    }
                }
                readyToAdd = !isDuplicate;
                retry++;
            }
                // Throw if we hit maximum retry : generated a duplicate 5 times in a row.
                //   require(retry < maxRetry, 'Error generating random ticket numbers. Max retry.');
            numbers[i] = uint8(generatedNumber);
        }
        return numbers;
    }

    function _randomFortileCapacity(uint256 _range) internal view returns (uint) {
        uint randomnumber = uint(keccak256(abi.encodePacked(block.timestamp , msg.sender, address(this)))) % _range;
        if(randomnumber < 5){
            return randomnumber = randomnumber + 5;
        }else{
            return randomnumber;
        }
    }

    function _overFlow(bytes32 _playerId,uint256 jumpAtStage,bool _jumpSide) internal returns(bool)  {
        if(totalNFTOnTile[jumpAtStage][_jumpSide] <= 0){                
            OverFlowPlayerStatus[_playerId] =  false;
        }

        if(totalNFTOnTile[jumpAtStage][_jumpSide] > 0 ){
            totalNFTOnTile[jumpAtStage][_jumpSide] = totalNFTOnTile[jumpAtStage][_jumpSide] - 1;
        }

        bool isSafeSide ;
        if (GameMap[jumpAtStage - 1] >= 50e9) {
            isSafeSide = true;
        }
        if (GameMap[jumpAtStage - 1] < 50e9) {
            isSafeSide = false;
        }

        if(jumpAtStage >= 2  && TitleCapacityAgainestStage[jumpAtStage - 1] >= totalNFTOnTile[jumpAtStage - 1][isSafeSide]){
            totalNFTOnTile[jumpAtStage - 1][isSafeSide] = totalNFTOnTile[jumpAtStage - 1][isSafeSide] + 1;
        }  

        return  OverFlowPlayerStatus[_playerId];
    }

    function isExist(bytes32 _playerID) public view returns(bool){
        for (uint i = 0; i < participatePlayerList.length; i++) {
            if(participatePlayerList[i] == _playerID){
                return false;
            }
        }     
        return true;
    } 

    function initializeGame(uint256 _startAT) external onlyOwner {
        GameStatus storage _gameStatus = GameStatusInitialized[latestGameId];
        require(_gameStatus.startAt == 0, "Game Already Initilaized"); 
        require(_startAT >= block.timestamp,"Time must be greater then current time.");
        lastUpdateTimeStamp = _gameStatus.startAt = _startAT;
        // lastUpdateTimeStamp = _startAT;
        _gameStatus.isDistribution = true;
        isNarrowingGameEnded = true;
        emit Initialized(block.timestamp);
    }

    function entryFeeSeries(bytes32  _playerId,uint256 _nftId,uint8 _seriesType) public GameEndRules NarrowingGameEndRules{
        require(_seriesType == 1 || _seriesType == 2, "Invalid seriseType");
        bytes32 playerId;
        if(_seriesType == 1 ){
            playerId = _computeNextPlayerIdForHolder(msg.sender, _nftId, 1);
        }else if( _seriesType == 2){
            playerId = _computeNextPlayerIdForHolder(msg.sender, _nftId, 2);
        }
        require(playerId == _playerId,"Player ID doesn't match ");
        if(isExist(playerId)){    
            participatePlayerList.push(playerId);    
        }
        GameItem storage _member = PlayerItem[playerId];
        if(_member.stage > 0){
            _deletePlayerIDForSpecifyStage(_member.stage,playerId);
        }
        if (_member.userWalletAddress != address(0)) {
            GameStatus storage _admin = GameStatusInitialized[latestGameId];
            require((_checkSide(_member.stage, _member.lastJumpSide) == false) || (_dayDifferance(block.timestamp, _admin.startAt) > _member.day), "Already In Game");
            // require((OverFlowPlayerStatus[playerId] ==  false) && (_dayDifferance(block.timestamp, _admin.startAt) > _member.day), "Already In Game");
            // require(_checkSide(_member.stage, _member.lastJumpSide) == false, "Already In Game");
            require(_dayDifferance(_member.lastJumpTime,_admin.startAt) + 1 < _dayDifferance(block.timestamp, _admin.startAt),"Buyback is useful only one time in 24 hours");
            _member.lastJumpTime =_member.startAt=_member.stage =_member.day = 0;    
            // _member.isDrop = true;
            _member.lastJumpSide = false;
        } 
        if((OverFlowPlayerStatus[playerId] == false && _checkSide(_member.stage, _member.lastJumpSide) == true) 
            || ((OverFlowPlayerStatus[playerId] == true && _checkSide(_member.stage, _member.lastJumpSide) == false))
                || ((OverFlowPlayerStatus[playerId] == false && _checkSide(_member.stage, _member.lastJumpSide) == false))){
            _member.nftId = _nftId;
            _member.feeStatus = true;
            _member.playerId = playerId;
            _member.nftSeriestype = _seriesType;
            _member.userWalletAddress = msg.sender;
            PlayerItem[playerId] = _member;

            lastUpdateTimeStamp = block.timestamp;
            OverFlowPlayerStatus[playerId] =  true;
            allStagesData[_member.stage].push(playerId);
            
            if(_seriesType == 1){
                emit EntryFee(playerId, _nftId, 1, 0);
            }else if(_seriesType == 2){
                _transferAmount(SERIES_TWO_FEE);
                emit EntryFee(playerId, _nftId, 2, SERIES_TWO_FEE);
            }
        }else{
            revert("Already into Game");
        }
    }

    function bulkEntryFeeSeries(bytes32[] memory _playerId,uint256[] calldata _nftId, uint8 seriesType) external {
        for (uint256 i = 0; i < _nftId.length; i++) {
            entryFeeSeries(_playerId[i],_nftId[i],seriesType);
        }
    }

    function changeCommunityOwnerWA(address[2] calldata _communityOwnerWA) external onlyOwner {
        for (uint i = 0; i < _communityOwnerWA.length; i++) {
            communityOwnerWA[i] = _communityOwnerWA[i];
        }
    }
   
    function buyBackInFee(bytes32 playerId) external GameEndRules NarrowingGameEndRules {
        uint256 buyBackFee = _calculateBuyBackIn();
        // require(_balanceOfUser(msg.sender) >= buyBackFee,"Insufficient balance");
        GameItem storage _member = PlayerItem[playerId];
        require((_member.userWalletAddress != address(0)) && (_member.userWalletAddress == msg.sender),"Only Player Trigger");
        require(_dayDifferance(block.timestamp, _member.lastJumpTime) <= 1,"Buy Back can be used in 24 hours only");
        // require(_checkSide(_member.stage, _member.lastJumpSide) == false, "Already In Game");
        
        if((OverFlowPlayerStatus[playerId] == false && _checkSide(_member.stage, _member.lastJumpSide) == true) || ((OverFlowPlayerStatus[playerId] == true && _checkSide(_member.stage, _member.lastJumpSide) == false))){
            _transferAmount(buyBackFee);
            if (GameMap[_member.stage - 1] >= 50e9) {
                _member.lastJumpSide = true;
            }
            if (GameMap[_member.stage - 1] < 50e9) {
                _member.lastJumpSide = false;
            }
            // Comment This check under disscussion
            OverFlowPlayerStatus[playerId] =  true;
            // _member.isDrop = true;
            _member.day = 0;
            _member.ishold = false;
            _member.feeStatus = true;
            _member.stage = _member.stage - 1;
            _member.lastJumpTime = block.timestamp;
            PlayerItem[playerId] = _member;
            allStagesData[_member.stage].push(playerId);
            _deletePlayerIDForSpecifyStage(_member.stage + 1,playerId);
            emit ParticipateOfPlayerInBuyBackIn(playerId, buyBackFee);
        }else{
            revert("Already In Game");
        }
    }

    function switchSide(bytes32 playerId) external  GameEndRules NarrowingGameEndRules{
        GameItem storage _member = PlayerItem[playerId];
        require(_member.feeStatus == true, "Please Pay Entry Fee.");
        require(_member.userWalletAddress == msg.sender,"Only Player Trigger");
        require(_dayDifferance(block.timestamp,GameStatusInitialized[latestGameId].startAt) == _member.day, "Switch tile time is over.");
        require(_narrowingGameMap < _NarrowingNumberProbility, "Reached maximum");
        if(_member.lastJumpSide  == true){
            _member.lastJumpSide = false;
        }else{
            _member.lastJumpSide = true;
        }
        PlayerItem[playerId] = _member;
        _overFlow(playerId,PlayerItem[playerId].stage,PlayerItem[playerId].lastJumpSide);
        lastUpdateTimeStamp = block.timestamp;
    }

    event RandomNumberComment(uint256 _randomNumber);

    function participateInGame(bool _jumpSide, bytes32 playerId) public  GameEndRules NarrowingGameEndRules{
        GameItem storage _member = PlayerItem[playerId];
        GameStatus storage  _gameStatus = GameStatusInitialized[latestGameId];        
        uint256 currentDay = _dayDifferance(block.timestamp,_gameStatus.startAt);
        require(_member.userWalletAddress == msg.sender,"Only Player Trigger");
        require(_member.feeStatus == true, "Please Pay Entry Fee.");
        if (_member.startAt == 0 && _member.lastJumpTime == 0) {
            //On First Day when current day & member day = 0
            require(currentDay >= _member.day, "Already Jumped");
        } else {
            //for other conditions
            require(currentDay > _member.day, "Already Jumped");
        }
        
        if (_member.stage != 0) {
            require((_member.lastJumpSide == true && GameMap[_member.stage] >= 50e9) || (_member.lastJumpSide == false && GameMap[_member.stage] < 50e9), "You are Failed" );
        }

        require(OverFlowPlayerStatus[playerId] == true,"Drop down due to overflow.");   
        uint256 _currentUserStage = _member.stage + 1;
        if (GameMap[_currentUserStage] <= 0) {
            uint256 _globalStageNumber  = _gameStatus.stageNumber + 1;
            // uint256 _titleCapacity =  _randomFortileCapacity(11 - _globalStageNumber);
            if((11 > _globalStageNumber ) && (11 - _globalStageNumber) > 1){
                // totalNFTOnTile[_globalStageNumber][true]  =   _randomFortileCapacity(11 - _globalStageNumber);
                totalNFTOnTile[_globalStageNumber][true]  =   3;
                // totalNFTOnTile[_globalStageNumber][false] =   _randomFortileCapacity(11 - _globalStageNumber);
                totalNFTOnTile[_globalStageNumber][false] =   3;
                TitleCapacityAgainestStage[_globalStageNumber] = 3;
            }else{
                totalNFTOnTile[_globalStageNumber][true]  =  3;// 5;
                totalNFTOnTile[_globalStageNumber][false] =  3;// 5;
                TitleCapacityAgainestStage[_globalStageNumber] = 3; //5
            }
            GameMap[_globalStageNumber] = _random() * 1e9;
            _gameStatus.stageNumber = _globalStageNumber;
            _gameStatus.lastUpdationDay = currentDay;
            _narrowingGameMap = _randomNarrowingGame();
            emit RandomNumberComment(_narrowingGameMap);
            _NarrowingNumberProbility =  _NarrowingNumberProbility + 1;
        }
        allStagesData[_currentUserStage].push(playerId);
        _deletePlayerIDForSpecifyStage(_member.stage,playerId);
        _overFlow(playerId,_currentUserStage,_jumpSide);

        _member.day = currentDay;
        _member.lastJumpSide = _jumpSide;
        _member.startAt = block.timestamp;
        _member.stage = _currentUserStage;
        lastUpdateTimeStamp = block.timestamp;
        _member.lastJumpTime = block.timestamp;

        if((_narrowingGameMap < _NarrowingNumberProbility ) && (_gameStatus.stageNumber == _currentUserStage)){
            isNarrowingGameEnded =  false;
            if(_checkSide(_gameStatus.stageNumber,_jumpSide) && OverFlowPlayerStatus[playerId]){ //If player successfull side but capacity over
                gameWinners.push(playerId);
            }
        }

        PlayerItem[playerId] = _member;
        GameStatusInitialized[latestGameId] = _gameStatus;
        emit ParticipateOfPlayerInGame(playerId,_currentUserStage);
    }

    function isGameEnded() external view returns (bool) {
        GameStatus storage _gameStatus = GameStatusInitialized[latestGameId];
        if ((_narrowingGameMap > 0) && (_dayDifferance(block.timestamp, _gameStatus.startAt) > _gameStatus.lastUpdationDay)) {
            return isNarrowingGameEnded;
        } else {
            return true;
        }
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

    function LateBuyInFee(bytes32  _playerId,uint256 _nftId, uint8 seriesType) external GameEndRules NarrowingGameEndRules{
        require(seriesType == 1 || seriesType == 2, "Invalid seriseType");
        bytes32 playerId = _computeNextPlayerIdForHolder(msg.sender,_nftId,seriesType);
        require(playerId == _playerId,"Player ID doesn't match ");
        if(isExist(playerId)){
            participatePlayerList.push(playerId);    
        }
        
        uint256 buyBackFee = _calculateBuyBackIn();
        uint256 totalAmount;
        if (seriesType == 1) {
            totalAmount = buyBackFee;
        }
        if (seriesType == 2) {
            totalAmount = buyBackFee + SERIES_TWO_FEE;
        }
        _transferAmount(totalAmount);
        GameStatus storage _gameStatus = GameStatusInitialized[latestGameId];
        GameItem storage _member = PlayerItem[playerId];
        if((OverFlowPlayerStatus[playerId] == false && _checkSide(_member.stage, _member.lastJumpSide) == true)|| ((OverFlowPlayerStatus[playerId] == true && _checkSide(_member.stage, _member.lastJumpSide) == false))){

            if(_member.stage > 0){
                _deletePlayerIDForSpecifyStage(_member.stage,playerId);
            }
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
            _member.nftSeriestype = seriesType;
            _member.playerId = playerId;
            _member.nftId = _nftId;

            _overFlow(playerId,_member.stage,_member.lastJumpSide);

            PlayerItem[playerId] = _member;
            lastUpdateTimeStamp = block.timestamp;
            OverFlowPlayerStatus[playerId] =  true;
            allStagesData[_member.stage].push(playerId);
            emit ParticipateOfNewPlayerInLateBuyBackIn(playerId,_gameStatus.stageNumber - 1,totalAmount);
        }else{
            revert("Already in Game");
        }  
    }

    function allParticipatePlayerID() external view returns(bytes32[] memory) {
        return participatePlayerList;
    }

    function withdraw() external onlyOwner {
        _withdraw(treasuryBalance());
    }

    function withdrawWrappedEtherOFCommunity(uint8 withdrawtype) external  {
            GameStatus storage _gameStatus = GameStatusInitialized[latestGameId];
            _distributionReward();
            _gameStatus.isDistribution = false;
            GameStatusInitialized[latestGameId] = _gameStatus;
        // Check enough balance available, otherwise just return false
        if (withdrawtype == 0) {
            require(ownerbalances[communityOwnerWA[0]] > 0,"Insufficient Owner Balance");
            require(communityOwnerWA[0] == msg.sender, "Only Owner use this");
            _withdraw(ownerbalances[msg.sender]);
            delete ownerbalances[msg.sender];
        } else if (withdrawtype == 1) {
            require(vaultbalances[communityOwnerWA[1]] > 0,"Insufficient Vault Balance");
            require(communityOwnerWA[1] == msg.sender, "Only vault use this");
            _withdraw(vaultbalances[msg.sender]);
            delete vaultbalances[msg.sender];
        } 
    }

    function claimWinnerEther(bytes32 playerId) external  {
        GameStatus storage _gameStatus = GameStatusInitialized[latestGameId];
        require(PlayerItem[playerId].userWalletAddress == msg.sender,"Only Player Trigger");
        _distributionReward();
        _gameStatus.isDistribution = false;
        GameStatusInitialized[latestGameId] = _gameStatus;
        require(winnerbalances[playerId]  > 0,"Insufficient Plyer Balance");
        _withdraw(winnerbalances[playerId]);
        delete PlayerItem[playerId];      
        emit claimPlayerReward(playerId,winnerbalances[playerId]);
        _removeForList(_findIndex(playerId,gameWinners));
    }

    function isDrop(bytes32 _playerID) external view returns (bool) {
        GameStatus storage _gameStatus = GameStatusInitialized[latestGameId];
        if (_dayDifferance(block.timestamp, _gameStatus.startAt) > PlayerItem[_playerID].day) {
           return  OverFlowPlayerStatus[_playerID];
        }else{
            return true;
        } 
    }  
    
    function bulkParticipate(bool _jumpSides, bytes32[] memory playerIds) internal  {
        
        uint256 titleCapacity = totalNFTOnTile[PlayerItem[playerIds[0]].stage + 1][_jumpSides];
        if(titleCapacity < playerIds.length){
            uint256 _range;
            if(titleCapacity > 0){
                _range = titleCapacity;
            }else{
                bytes32[] memory PlayerCapacity = getStagesData(PlayerItem[playerIds[0]].stage + 1);
                if(PlayerCapacity.length > 0){
                    _range = 0;
                }else{
                    _range = 3;
                }
            }
            playerIndex = generateRandomTicketNumbers(playerIds.length - 1,playerIds.length - 1,_range);
        }

        for (uint256 i = 0; i < playerIds.length; i++) {
            GameItem storage _member = PlayerItem[playerIds[i]];
            GameStatus storage  _gameStatus = GameStatusInitialized[latestGameId];        
            uint256 currentDay = _dayDifferance(block.timestamp,_gameStatus.startAt);
            require(_member.userWalletAddress == msg.sender,"Only Player Trigger");
            require(_member.feeStatus == true, "Please Pay Entry Fee.");
            if (_member.startAt == 0 && _member.lastJumpTime == 0) {
                //On First Day when current day & member day = 0
                require(currentDay >= _member.day, "Already Jumped");
            } else {
                //for other conditions
                require(currentDay > _member.day, "Already Jumped");
            }
            if (_member.stage != 0) {
                require((_member.lastJumpSide == true && GameMap[_member.stage] >= 50e9) || (_member.lastJumpSide == false && GameMap[_member.stage] < 50e9), "You are Failed" );
            }
            require(OverFlowPlayerStatus[playerIds[i]] == true,"Drop down due to overflow.");
            uint256 _currentUserStage = _member.stage + 1;
            if (GameMap[_currentUserStage] <= 0) {
                uint256 _globalStageNumber  = _gameStatus.stageNumber + 1;
                // uint256 _titleCapacity =  _randomFortileCapacity(11 - _globalStageNumber);
                if((11 - _globalStageNumber) > 1){
                    // totalNFTOnTile[_globalStageNumber][true]  =   _randomFortileCapacity(11 - _globalStageNumber);
                    totalNFTOnTile[_globalStageNumber][true]  =   3;
                    // totalNFTOnTile[_globalStageNumber][false] =   _randomFortileCapacity(11 - _globalStageNumber);
                    totalNFTOnTile[_globalStageNumber][false] =   3;
                    TitleCapacityAgainestStage[_globalStageNumber] = 3;
                }else{

                    totalNFTOnTile[_globalStageNumber][true]  =  3;// 5;
                    totalNFTOnTile[_globalStageNumber][false] =  3;// 5;
                    TitleCapacityAgainestStage[_globalStageNumber] = 3; //5
                }
                GameMap[_globalStageNumber] = _random() * 1e9;
                _gameStatus.stageNumber = _globalStageNumber;
                _gameStatus.lastUpdationDay = currentDay;
                _narrowingGameMap = _randomNarrowingGame();
                _NarrowingNumberProbility =  _NarrowingNumberProbility + 1;
            }
            allStagesData[_currentUserStage].push(playerIds[i]);
            _deletePlayerIDForSpecifyStage(_member.stage,playerIds[i]);
            

            // for (uint j = 0; j < playerIndex.length; j++) {

            //     if(playerIndex[j] > 0 && (i == playerIndex[j]) ){
                    if(totalNFTOnTile[_currentUserStage][_jumpSides] > 0 ){
                        totalNFTOnTile[_currentUserStage][_jumpSides] = totalNFTOnTile[_currentUserStage][_jumpSides] - 1;
                    }

                    bool isSafeSide;
                    if (GameMap[_currentUserStage - 1] >= 50e9) {
                        isSafeSide = true;
                    }
                    if (GameMap[_currentUserStage - 1] < 50e9) {
                        isSafeSide = false;
                    }

                    if(_currentUserStage >= 2  && TitleCapacityAgainestStage[_currentUserStage - 1] >= totalNFTOnTile[_currentUserStage - 1][isSafeSide]){
                        totalNFTOnTile[_currentUserStage - 1][isSafeSide] = totalNFTOnTile[_currentUserStage - 1][isSafeSide] + 1;
                    }  
            //     }
            // }
                if(titleCapacity < playerIds.length){
                    OverFlowPlayerStatus[playerIds[i]] =  false;
                }
            
            _member.day = currentDay;
            _member.lastJumpSide = _jumpSides;
            _member.startAt = block.timestamp;
            _member.stage = _currentUserStage;
            lastUpdateTimeStamp = block.timestamp;
            _member.lastJumpTime = block.timestamp;
            

            if((_narrowingGameMap < _NarrowingNumberProbility ) && (_gameStatus.stageNumber == _currentUserStage)){
                isNarrowingGameEnded =  false;
                if(_checkSide(_gameStatus.stageNumber,_jumpSides) && OverFlowPlayerStatus[playerIds[i]]){ //If player successfull side but capacity over
                    gameWinners.push(playerIds[i]);
                }
            }

            PlayerItem[playerIds[i]] = _member;
            GameStatusInitialized[latestGameId] = _gameStatus;
            emit ParticipateOfPlayerInGame(playerIds[i],_currentUserStage);
        }
        if(titleCapacity < playerIds.length){
            for (uint256 i = 0; i < playerIndex.length; i++) {
                if(playerIndex[i] > 0){
                    OverFlowPlayerStatus[playerIds[playerIndex[i]]] =  true;
                }
            }
        }
    }

    function bulkParticipateInGame(bool _jumpSides, bytes32[] memory playerIds) external  {
        //Select index of NFT's Arrays 
        for (uint256 i = 0; i < playerIds.length; i++) {
            if(PlayerItem[playerIds[0]].stage != PlayerItem[playerIds[i]].stage){
                revert("BulkParticipateInGame:Same Stage Players Jumped.");
            }
        }
        bulkParticipate(_jumpSides,playerIds);
 
    }

    //============================Remove====================================================
    
    
    // function changetileStatic(bytes32 playerId) public {
    //     GameItem storage _member = PlayerItem[playerId];
    //     _member.ishold =  true;
    //     if(TitleCapacityAgainestStage[_member.stage] > totalNFTOnTile[_member.stage][_member.lastJumpSide]){
    //         totalNFTOnTile[_member.stage][_member.lastJumpSide] + 1;
    //     }
    //     PlayerItem[playerId] =  _member;
    // }

    // function checkTileCapacity(uint256 _stage, bool _side ) public view returns (uint256) {
    //     return totalNFTOnTile[_stage][_side];    
    // }

    // /*
    // *
    // */
    // function testCheck(bytes32 playerId) public view returns(bool) {
    //     if(OverFlowPlayerStatus[playerId] == true){ //
    //         return false;

    //     }else if(_checkSide(PlayerItem[playerId].stage, PlayerItem[playerId].lastJumpSide) == true){
    //         return false;

    //     }
    //     return true;
    // }

    /**
     *     function generateRandomTicketNumbers(uint256 _lotteryCount) internal view returns (uint8[5] memory) {
        uint8[5] memory numbers;
        uint256 generatedNumber;

        // Execute 5 times (to generate 5 numbers)
        for (uint256 i = 0; i < 5; i++) {
            //   Check duplicate
            bool readyToAdd = false;
            uint256 maxRetry = 5;
            uint256 retry = 0;

            // Generate a new number while it is a duplicate, up to 5 times (to prevent errors and infinite loops)
            while (!readyToAdd && retry <= maxRetry) {
                generatedNumber = (uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, i, retry, _lotteryCount))) % 25) +1;
                bool isDuplicate = false;

                // Look in all already generated numbers array if the new generated number is already there.
                for (uint256 j = 0; j < numbers.length; j++) {
                    if (numbers[j] == generatedNumber) {
                        isDuplicate = true;
                        break;
                    }
                }
                readyToAdd = !isDuplicate;
                retry++;
            }
                // Throw if we hit maximum retry : generated a duplicate 5 times in a row.
                //   require(retry < maxRetry, 'Error generating random ticket numbers. Max retry.');
            numbers[i] = uint8(generatedNumber);
        }
        return numbers;
    }

     *  function generateRandomTicketNumbers(uint256 _lotteryCount,uint256 _arraylength,uint256 _returnSize) public view returns (uint8[] memory) {
        uint8[] memory numbers;
        uint256 generatedNumber;

        // Execute 5 times (to generate 5 numbers)
        for (uint256 i = 0; i < _returnSize; i++) {
            //   Check duplicate
            bool readyToAdd = false;
            uint256 maxRetry = _returnSize;
            uint256 retry = 0;

            // Generate a new number while it is a duplicate, up to 5 times (to prevent errors and infinite loops)
            while (!readyToAdd && retry <= maxRetry) {
                generatedNumber = (uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, i, retry, _lotteryCount))) % _arraylength) +1;
                bool isDuplicate = false;

                // Look in all already generated numbers array if the new generated number is already there.
                for (uint256 j = 0; j < numbers.length; j++) {
                    if (numbers[j] == generatedNumber) {
                        isDuplicate = true;
                        break;
                    }
                }
                readyToAdd = !isDuplicate;
                retry++;
            }
                // Throw if we hit maximum retry : generated a duplicate 5 times in a row.
                //   require(retry < maxRetry, 'Error generating random ticket numbers. Max retry.');
            numbers[i] = uint8(generatedNumber);
        }
        return numbers;
    }
    */
    //array lenght
    //return array size 
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
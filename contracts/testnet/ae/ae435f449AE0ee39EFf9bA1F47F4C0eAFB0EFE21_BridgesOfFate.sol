pragma solidity ^0.8.9;
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract BridgesOfFate is Ownable {
    using SafeERC20 for IERC20; 
    IERC20 private token;

    uint256 public gameEnded = 3; // 5
    uint256 public latestGameId = 1;
    uint256 public lastUpdateTimeStamp;


    uint256 private constant TURN_PERIOD = 480; //Now we are use 5 minute //86400; // 24 HOURS
    uint256 private constant SERIES_TWO_FEE = 0.01 ether;
    uint256 private _pioneerPushBackBankingNumberProbility;
    uint256 private constant _winnerRewarsdsPercent = 60;
    uint256 private constant _ownerRewarsdsPercent = 25;
    uint256 private constant _communityVaultRewarsdsPercent = 15;

    
    bool private _isPioneerPushBackEnd;
    
    
    bytes32[] private gameWinners;
    bytes32[] private participatePlayerList;

    // 0 =========>>>>>>>>> Owner Address
    // 1 =========>>>>>>>>> community vault Address
    // WA (Wallet Addresses)
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
        uint256 randomNumber;
        uint8 nftSeriestype;
        bool lastJumpSide;
        bool feeStatus;
        bool isPushBack;
        bytes32 playerId;
        address userWalletAddress;
    }

    mapping(bytes32 => GameItem) public PlayerItem;
    mapping(uint256 => GameStatus) public GameStatusInitialized;
    
    mapping(uint256 => uint256) private GameMap;
    mapping(uint256 => uint256) public PioneerPushBackBankingGameMap; //private
    
    mapping(address => uint256) private balances;
    mapping(bytes32 => uint256) private winnerbalances;
    mapping(address => uint256) private ownerbalances;
    mapping(address => uint256) private vaultbalances;
    mapping(uint256 => bytes32[]) private allStagesData;

    event Initialized(uint256 StartAt);
    event claimPlayerReward(bytes32 playerId, uint256 amount);
    event ParticipateOfPlayerInBuyBackIn(bytes32 PlayerId, uint256 Amount);
    event EntryFee(bytes32 PlayerId,uint256 NftId,uint256 NftSeries,uint256 FeeAmount);
    event ParticipateOfPlayerInGame(bytes32 PlayerId, uint256 _globalStage,uint256 _jumpAtStage);
    event ParticipateOfNewPlayerInLateBuyBackIn(bytes32 PlayerId,uint256 MoveAtStage,uint256 Amount);

    constructor(IERC20 _wrappedEther,address _commuinty) {
        token = _wrappedEther;
        communityOwnerWA[0] = owner();
        communityOwnerWA[1] = _commuinty;
        _pioneerPushBackBankingNumberProbility = 30;
    }

    function _gameEndRules() internal view returns (bool) {
        GameStatus memory _gameStatus = GameStatusInitialized[latestGameId];
        require(block.timestamp >= _gameStatus.startAt,"Game start after intialized time.");
        if (lastUpdateTimeStamp > 0) {
            require(_dayDifferance(block.timestamp, lastUpdateTimeStamp) <= gameEnded,"Game Ended !");
        }
        return true;
    }

    function _pushBackBankingGameEndRules() internal view returns (bool) {
        if((PioneerPushBackBankingGameMap[GameStatusInitialized[latestGameId].stageNumber] > 0) && 
        (PioneerPushBackBankingGameMap[GameStatusInitialized[latestGameId].stageNumber]  < _pioneerPushBackBankingNumberProbility) && 
        (_dayDifferance(block.timestamp,GameStatusInitialized[latestGameId].startAt) > GameStatusInitialized[latestGameId].lastUpdationDay))
        {
            require(_isPioneerPushBackEnd == true ,"PushBack Bank Game Ended.");
        }
        return true;
    }
    
    modifier GameEndRules() {
        _gameEndRules();
        _;
    }
    
    modifier PushBackBankingGameEndRules() {
        _pushBackBankingGameEndRules();
        _;
    }


    function _removeForList(uint index)  internal{
        delete gameWinners[index];
        // gameWinners[index] =  gameWinners[gameWinners.length - 1];
        // delete gameWinners[index];
        // gameWinners.pop();
    }

    function _balanceOfUser(address _accountOf) internal view returns (uint256) {
        return token.balanceOf(_accountOf);
    }

    function _removeSecondListItem(uint index,uint256 _stages)  internal {
        // bytes32[] storage _stagesData = allStagesData[_stages];
        // _stagesData[index] =  _stagesData[_stagesData.length - 1];
        // delete _stagesData[index];
        // _stagesData.pop();
        bytes32[] storage _stagesData = allStagesData[_stages];
        delete _stagesData[index];
    }

    function treasuryBalance() public view returns (uint256) {
        return _balanceOfUser(address(this));
    }

    function _distributionReward() internal {
        uint256 _treasuryBalance = treasuryBalance();
        require((GameStatusInitialized[latestGameId].startAt > 0 && block.timestamp >= GameStatusInitialized[latestGameId].startAt),"Game start after intialized time.");
        // require(_treasuryBalance > 0 ,"Insufficient Balance");
        require(_isPioneerPushBackEnd == false,"Distribution time should not start before reaching final stage.");
        if(GameStatusInitialized[latestGameId].isDistribution){
            // 25% to owner wallet owner 
            ownerbalances[communityOwnerWA[0]] = (_ownerRewarsdsPercent * _treasuryBalance) / 100;
            //vault 15% goes to community vault
            vaultbalances[communityOwnerWA[1]] = (_communityVaultRewarsdsPercent * _treasuryBalance) / 100;
                //Player
            if(gameWinners.length > 0){
                for (uint i = 0; i < gameWinners.length; i++) {
                    winnerbalances[gameWinners[i]]  = (((_winnerRewarsdsPercent * treasuryBalance())) / 100) / (gameWinners.length);
                }
            }
        }
    }

    function _calculateBuyBackIn() internal view returns (uint256) {
        GameStatus memory _gameStatus = GameStatusInitialized[latestGameId];
        if (_gameStatus.stageNumber > 0) {
            if (_gameStatus.stageNumber <= buyBackCurve.length) {
                return buyBackCurve[_gameStatus.stageNumber - 1];
            }
        }
        return 0;
    }
    
    function getStagesData(uint256 _stage) public view  returns (bytes32[] memory) {
        return allStagesData[_stage];
    }

    function _deletePlayerIDForSpecifyStage(uint256 _stage, bytes32 _playerId) internal {
        bytes32[] memory _player = getStagesData(_stage);
        uint256 _index =  _findIndex(_playerId,_player);
        _removeSecondListItem(_index ,_stage);
    }

    function _checkSide(uint256 stageNumber, bool userSide) internal view returns (bool) {
        uint256 stage_randomNumber = GameMap[stageNumber]; 
        if ((userSide == false && stage_randomNumber < 50) || (userSide == true && stage_randomNumber >= 50)) {
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

    function _dayDifferance(uint256 timeStampTo, uint256 timeStampFrom) internal pure returns (uint256){
        return (timeStampTo - timeStampFrom) / TURN_PERIOD;
    }

    function _computeNextPlayerIdForHolder(address holder,uint256 _nftId,uint8 _seriesIndex) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(holder, _nftId, _seriesIndex));
    }

    function isExist(bytes32 _playerID) public view returns(bool){
        for (uint i = 0; i < participatePlayerList.length; i++) {
            if(participatePlayerList[i] == _playerID){
                return false;
            }
        }     
        return true;
    }

    function initializeGame(uint256 _startAT) public onlyOwner {
        GameStatus storage _gameStatus = GameStatusInitialized[latestGameId];
        require(_gameStatus.startAt == 0, "Game Already Initilaized"); 
        require(_startAT >= block.timestamp,"Time must be greater then current time.");
        _gameStatus.startAt = _startAT;
        _gameStatus.isDistribution = true;
        _isPioneerPushBackEnd = true;
        emit Initialized(block.timestamp);
    }

    function entryFeeSeries(bytes32  _playerId,uint256 _nftId,uint8 _seriesType) public {
        require(_seriesType == 1 || _seriesType == 2, "Invalid seriseType");
        
        if(lastUpdateTimeStamp > 0){
            require(_dayDifferance(block.timestamp, lastUpdateTimeStamp) < gameEnded,"Game Ended !");
           
        if((PioneerPushBackBankingGameMap[GameStatusInitialized[latestGameId].stageNumber] > 0) && 
                (PioneerPushBackBankingGameMap[GameStatusInitialized[latestGameId].stageNumber]  < _pioneerPushBackBankingNumberProbility) && 
            (_dayDifferance(block.timestamp,GameStatusInitialized[latestGameId].startAt) > GameStatusInitialized[latestGameId].lastUpdationDay))
            {
                require(_isPioneerPushBackEnd == true ,"PushBack Bank Game Ended.");
            }
            lastUpdateTimeStamp = block.timestamp;
        }

        bytes32 playerId = _computeNextPlayerIdForHolder(msg.sender, _nftId, _seriesType);
        require(playerId == _playerId,"Player ID doesn't match ");
        if(isExist(playerId)){    
            participatePlayerList.push(playerId);    
        }
        GameItem storage _member = PlayerItem[playerId];
        if(_member.stage > 0){
            _deletePlayerIDForSpecifyStage(_member.stage,playerId);
        }
        if (_member.userWalletAddress != address(0)) {
            GameStatus storage _gameStatus = GameStatusInitialized[latestGameId];
            require(_dayDifferance(block.timestamp, _gameStatus.startAt) > _member.day, "Already In Game");
            require(_checkSide(_member.stage, _member.lastJumpSide) == false, "Already In Game");
            require(_dayDifferance(_member.lastJumpTime,_gameStatus.startAt) + 1 < _dayDifferance(block.timestamp, _gameStatus.startAt),"Buyback is useful only one time in 24 hours");
                _member.day = 0;    
                _member.stage = 0;
                _member.startAt = 0;
                _member.lastJumpTime = 0;
                _member.lastJumpSide = false;
                _member.isPushBack =  true; 
        } 
        _member.feeStatus = true;
        _member.nftId = _nftId;
        _member.nftSeriestype = _seriesType;
        _member.userWalletAddress = msg.sender;
        _member.playerId = playerId;
        allStagesData[_member.stage].push(playerId);
        if(_seriesType == 1){
            emit EntryFee(playerId, _nftId, 1, 0);
        }else if(_seriesType == 2){
            require(_balanceOfUser(msg.sender) >= SERIES_TWO_FEE,"Insufficient balance");
            token.safeTransferFrom(msg.sender, address(this), SERIES_TWO_FEE);
            emit EntryFee(playerId, _nftId, 2, SERIES_TWO_FEE);
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

    function buyBackInFee(bytes32 playerId) external  GameEndRules PushBackBankingGameEndRules {
        uint256 buyBackFee = _calculateBuyBackIn();
        GameItem storage _member = PlayerItem[playerId];
        require((_member.userWalletAddress != address(0)) && (_member.userWalletAddress == msg.sender),"Only Player Trigger");
        require(_dayDifferance(block.timestamp, _member.lastJumpTime) <= 1,"Buy Back can be used in 24 hours only");
        require(_checkSide(_member.stage, _member.lastJumpSide) == false, "Already In Game");
        _member.lastJumpSide = GameMap[_member.stage - 1] >= 50;
        _member.day = 0;
        _member.feeStatus = true;
        _member.stage = _member.stage - 1;
        _member.lastJumpTime = block.timestamp;
        // PlayerItem[playerId] = _member;
        allStagesData[_member.stage].push(playerId);
        _deletePlayerIDForSpecifyStage(_member.stage + 1,playerId);
        token.safeTransferFrom(msg.sender, address(this), buyBackFee);
        emit ParticipateOfPlayerInBuyBackIn(playerId, buyBackFee);
    }


    function switchSide(bytes32 playerId) external  GameEndRules  PushBackBankingGameEndRules{
        GameItem storage _member = PlayerItem[playerId];
        require(_member.feeStatus == true, "Please Pay Entry Fee.");
        require(_member.userWalletAddress == msg.sender,"Only Player Trigger");
        require(_dayDifferance(block.timestamp,GameStatusInitialized[latestGameId].startAt) == _member.day, "Switch tile time is over.");
        // require(PioneerPushBackBankingGameMap[GameStatusInitialized[latestGameId].stageNumber] < _pioneerPushBackBankingNumberProbility, "Reached maximum");
        if(_member.lastJumpSide  == true){
            _member.lastJumpSide = false;
        }else{
            _member.lastJumpSide = true;
        }
        // PlayerItem[playerId] = _member;
        lastUpdateTimeStamp = block.timestamp;
    }

    function generateRandomNumbersForGame(uint256 _range,uint256 _length) internal view returns (uint8[2] memory) {
        uint8[2] memory numbers;
        uint256 generatedNumber;

        // Execute 5 times (to generate 5 numbers)
        for (uint256 i = 0; i < _length; i++) {
            //   Check duplicate
            bool readyToAdd = false;
            uint256 maxRetry = _length;
            uint256 retry = 0;

            // Generate a new number while it is a duplicate, up to 5 times (to prevent errors and infinite loops)
            while (!readyToAdd && retry <= maxRetry) {
                uint256 _packedNumber = uint256(keccak256(abi.encodePacked(msg.sender,block.timestamp,i,retry)));
                generatedNumber = (_packedNumber % _range) + 1;
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

    function participateInGame(bool _jumpSide, bytes32 playerId) public  GameEndRules PushBackBankingGameEndRules{
        GameItem storage _member = PlayerItem[playerId];
        GameStatus storage _gameStatus = GameStatusInitialized[latestGameId];
        uint256 currentDay = _dayDifferance(block.timestamp,_gameStatus.startAt);
        require(_member.feeStatus == true, "Please Pay Entry Fee.");
        // require(PioneerPushBackBankingGameMap[_gameStatus.stageNumber] < 50,"Dynamic Game Ended.");
        if (_member.startAt == 0 && _member.lastJumpTime == 0) {
            //On First Day when current day & member day = 0
            require(currentDay >= _member.day, "Already Jumped");
        } else {
            //for other conditions
            require(currentDay > _member.day, "Already Jumped");
        }
        if (_member.stage != 0) {
            require((_member.lastJumpSide == true && GameMap[_member.stage] >= 50) || (_member.lastJumpSide == false && GameMap[_member.stage] < 50), "You are Failed" );
        }
        uint256 _currentUserStage =  _member.stage + 1;
        if (GameMap[_currentUserStage] <= 0) {
            uint256 _currentGlobalStage =  _gameStatus.stageNumber + 1;
            
            // GameMap[_currentGlobalStage] = _random(100) * 1;
            
            //Use this Due to gas Issue in this  contract.
            uint8[2] memory _packedNumber = generateRandomNumbersForGame(100,2);
            GameMap[_currentGlobalStage] = _packedNumber[0];
            
            _gameStatus.stageNumber = _currentGlobalStage;
            _gameStatus.lastUpdationDay = currentDay;
            //PioneerPushBackBankingGameMap[_currentGlobalStage] = _randomPushBackBankingGame(100);

            PioneerPushBackBankingGameMap[_currentGlobalStage] =  _packedNumber[1];
            
            _pioneerPushBackBankingNumberProbility =  _pioneerPushBackBankingNumberProbility + 1;
        }

        if((_gameStatus.stageNumber >= 2) && (_gameStatus.stageNumber  == _currentUserStage)){
            _member.isPushBack = true;
        }

        allStagesData[_currentUserStage].push(playerId);
        _deletePlayerIDForSpecifyStage(_member.stage,playerId);

        _member.day = currentDay;
        _member.lastJumpSide = _jumpSide;
        _member.stage = _currentUserStage;
        _member.startAt = block.timestamp;
        _member.lastJumpTime = block.timestamp;
        //Day Count of Member Playing Game
        // PlayerItem[playerId] = _member;
        // GameStatusInitialized[latestGameId] = _gameStatus;
        lastUpdateTimeStamp = block.timestamp;

        //Push winner into the Array list 
        if(_currentUserStage == _gameStatus.stageNumber && PioneerPushBackBankingGameMap[_gameStatus.stageNumber]  < _pioneerPushBackBankingNumberProbility ) {
            if(_checkSide(_gameStatus.stageNumber,_jumpSide)){
                gameWinners.push(playerId);
            }
            _isPioneerPushBackEnd = bool(false);
        }

        emit ParticipateOfPlayerInGame(playerId,_gameStatus.stageNumber,_currentUserStage);
    }

    function bulkParticipateInGame(bool _jumpSides, bytes32[] memory playerIds) external  GameEndRules {
        uint256 _currentStage = PlayerItem[playerIds[0]].stage;
        for (uint256 i = 0; i < playerIds.length; i++) {
            if(PlayerItem[playerIds[i]].stage == _currentStage){
                participateInGame(_jumpSides,playerIds[i]);
            }else{
                revert("Same Stage Players jump");
            }
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

    function isGameEnded() external view returns (bool) {
        GameStatus storage _gameStatus = GameStatusInitialized[latestGameId];
        if ((PioneerPushBackBankingGameMap[_gameStatus.stageNumber] > 0) && (_dayDifferance(block.timestamp, _gameStatus.startAt) > _gameStatus.lastUpdationDay)) {
            return _isPioneerPushBackEnd;
        } else {
            return true;
        }
    }

    function LateBuyInFee(bytes32  _playerId,uint256 _nftId, uint8 seriesType) public GameEndRules PushBackBankingGameEndRules {
        require(seriesType == 1 || seriesType == 2, "Invalid seriseType");
        bytes32 playerId = _computeNextPlayerIdForHolder(msg.sender,_nftId,seriesType);
        require(playerId == _playerId,"Player ID doesn't match ");
        GameStatus storage  _gameStatus = GameStatusInitialized[latestGameId];
        // require(GameStatusInitialized[latestGameId].ishybridEnd == true,"Hybird Game Ended.");
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
    
        // GameStatus storage _gameStatus = GameStatusInitialized[latestGameId];
        GameItem storage _member = PlayerItem[playerId];
        if(_member.stage > 0){
            _deletePlayerIDForSpecifyStage(_member.stage,playerId);
        }
        _member.userWalletAddress = msg.sender;
        _member.startAt = block.timestamp;
        _member.stage = _gameStatus.stageNumber - 1;
        _member.day = 0;

        _member.lastJumpSide = GameMap[_gameStatus.stageNumber - 1] >= 50;
        _member.nftId = _nftId;
        _member.feeStatus = true;
        // _member.isPushBack = true;
        _member.playerId = playerId;
        _member.nftSeriestype = seriesType;
        _member.lastJumpTime = block.timestamp;
        // PlayerItem[playerId] = _member;
        lastUpdateTimeStamp = block.timestamp;
        allStagesData[_member.stage].push(playerId);
        require(_balanceOfUser(msg.sender) >= totalAmount,"Insufficient balance");
        token.safeTransferFrom(msg.sender, address(this), totalAmount);
        emit ParticipateOfNewPlayerInLateBuyBackIn(playerId,_gameStatus.stageNumber - 1,totalAmount);
    }

    function allParticipatePlayerID() external view returns(bytes32[] memory) {
        return participatePlayerList;
    }

    function withdraw() external onlyOwner {
        token.safeTransfer(msg.sender, treasuryBalance());
    }

    function withdrawWrappedEtherOFCommunity(uint8 withdrawtype) external {
        GameStatus storage _gameStatus = GameStatusInitialized[latestGameId];
        _distributionReward();
        _gameStatus.isDistribution = false;
        // GameStatusInitialized[latestGameId] = _gameStatus;
        // Check enough balance available, otherwise just return false
        if (withdrawtype == 0) {
            require(ownerbalances[communityOwnerWA[0]] > 0,"Insufficient Owner Balance");
            require(communityOwnerWA[0] == msg.sender, "Only Owner use this");
            // _withdraw(ownerbalances[msg.sender]);
            token.safeTransfer(msg.sender, ownerbalances[msg.sender]);
            delete ownerbalances[msg.sender];
        } else if (withdrawtype == 1) {
            require(vaultbalances[communityOwnerWA[1]] > 0,"Insufficient Vault Balance");
            require(communityOwnerWA[1] == msg.sender, "Only vault use this");
            // _withdraw(vaultbalances[msg.sender]);
            token.safeTransfer(msg.sender, vaultbalances[msg.sender]);
            delete vaultbalances[msg.sender];
        } 
    }

    function claimWinnerEther(bytes32 playerId) external  {
        GameStatus storage _gameStatus = GameStatusInitialized[latestGameId];
        require(PlayerItem[playerId].userWalletAddress == msg.sender,"Only Player Trigger");
        _distributionReward();
        _gameStatus.isDistribution = false;
        // GameStatusInitialized[latestGameId] = _gameStatus;
        require(winnerbalances[playerId]  > 0,"Insufficient Player Balance");
        // _withdraw(winnerbalances[playerId]);
        token.safeTransfer(msg.sender, winnerbalances[playerId]);
        delete PlayerItem[playerId];      
        emit claimPlayerReward(playerId,winnerbalances[playerId]);
        _removeForList(_findIndex(playerId,gameWinners));
    }   

    function pushBack(bytes32 playerfrom,bytes32 playerto) external GameEndRules PushBackBankingGameEndRules  {
        GameItem storage _memberto   = PlayerItem[playerto];
        GameItem storage _memberfrom = PlayerItem[playerfrom];
        GameStatus storage _gameStatus = GameStatusInitialized[latestGameId];

        require(_memberfrom.userWalletAddress != _memberto.userWalletAddress ,"Player is not Pioneer.");
        require(_memberfrom.stage == _gameStatus.stageNumber ,"Player is not Pioneer.");
        require(_memberfrom.isPushBack == true ,"Already push againest this Nft");
        require(_memberfrom.stage > _memberto.stage, "Stage must be greater to traget nft.");

        _deletePlayerIDForSpecifyStage(_memberto.stage,playerto);

        _memberto.stage =  _memberto.stage - 1; 
         if (GameMap[_memberto.stage] >= 50) {
            _memberto.lastJumpSide = true;
        }
        if (GameMap[_memberto.stage] < 50) {
            _memberto.lastJumpSide = false;
        }
        allStagesData[_memberto.stage].push(playerto);    
        _memberfrom.isPushBack =  false;

    } 

    function updateBuyBackCurve(uint256[11] calldata val) external onlyOwner {
        for (uint i = 0; i < val.length; i++) {
            buyBackCurve[i] = val[i];
        }
    }

    function gameSetting(uint256 _gameEnded) public onlyOwner {
        gameEnded  = _gameEnded;
    }

    function restartGame(uint256 _startAT) public onlyOwner {
        for (uint i = 0; i < participatePlayerList.length; i++) {
            delete PlayerItem[participatePlayerList[i]];
           
        }
        for (uint i = 0; i <= GameStatusInitialized[latestGameId].stageNumber; i++) {
            delete allStagesData[i];
            delete GameMap[i];
        }
        
        lastUpdateTimeStamp = 0;
        _isPioneerPushBackEnd = true;
        _isPioneerPushBackEnd = true;
        
        delete gameWinners;
        delete participatePlayerList;
        delete GameStatusInitialized[latestGameId];
        
        //Restart Game Again
        initializeGame(_startAT);
    }

    function getAllDynamicNumber() external view returns (uint256[] memory,bool) {
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
                ret[i] = PioneerPushBackBankingGameMap[i + 1];
            }
        }
        return (ret,_isPioneerPushBackEnd);
    }
//     function isPushBackUsed(bytes32 _playerId) external view returns(bool) {
//         return PlayerItem[_playerId].isPushBack;
//     }

    /*function bulkLateBuyInFee(uint256[] calldata _nftId,uint8[] calldata seriesType) external {
        for (uint256 i = 0; i < _nftId.length; i++) {
            LateBuyInFee(_nftId[i], seriesType[i]);
        }
    }
    function allWinners() external view returns(bytes32[] memory,uint256) {
        return (gameWinners,gameWinners.length);
    }*/
    
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
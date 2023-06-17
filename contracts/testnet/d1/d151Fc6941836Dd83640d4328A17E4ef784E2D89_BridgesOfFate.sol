// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract BridgesOfFate is Ownable {

    using SafeERC20 for IERC20; 
    
    IERC20 private token;
    
    uint256 public gameEnded = 3; // 5
    uint256 public lastUpdateTimeStamp;

    uint256[] private   _uniqueRN;
    uint256[] private  _randomSelectPlayerIndex;
    
    uint256 private _latestGameId = 1;
    uint256 private _narrowingGameMap;
    uint256 private _NarrowingNumberProbility;

    uint256 private constant TURN_PERIOD = 180; // 5 minutes // 3 hours 10800
    uint256 private constant SERIES_TWO_FEE = 0.01 ether;
    uint256 private constant _winnerRewarsdsPercent = 60;
    uint256 private constant _ownerRewarsdsPercent = 25;
    uint256 private constant _communityVaultRewarsdsPercent = 15;
    
    bool public isNarrowingGameEnded = false;

    bytes32[] private _gameWinners;
    bytes32[] private _playerOnTile;
    bytes32[] private _participatePlayerList;
    bytes32[] private _selectUnholdPlayerId; 
    bytes32[] private _selectSuccessSidePlayerId; 

    // 0 =========>>>>>>>>> Owner Address
    // 1 =========>>>>>>>>> community vault Address
    
    address[2] private _communityOwnerWA;

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
        bool ishold;
        bool feeStatus;
        bool lastJumpSide;
        address userWalletAddress;
        bytes32 playerId;
    }

    mapping(bytes32 => GameItem) public PlayerItem;
    mapping(uint256 => GameStatus) public GameStatusInitialized;
    mapping(uint256 => uint256) private GameMap;
    mapping(bytes32 => uint256) private winnerbalances;
    mapping(address => uint256) private ownerbalances;
    mapping(address => uint256) private vaultbalances;
    mapping(uint256 => bytes32[]) private allStagesData;
    mapping(bytes32 => bool) public OverFlowPlayerStatus; // change
    mapping(uint256 => uint256) private TitleCapacityAgainestStage; //change
    // Againest Stage Number and Side set the number of nft's
    mapping(uint256 => mapping(bool => uint256)) public totalNFTOnTile; //change

    event Initialized(uint256 _startAt);
    event claimPlayerReward(bytes32 playerId, uint256 amount);
    event ParticipateOfPlayerInGame(bytes32 playerId,uint256 jumpAt);
    event BulkParticipateOfPlayerInGame(bytes32 playerId,uint256 jumpAt);
    event ParticipateOfPlayerInBuyBackIn(bytes32 playerId, uint256 amount);
    event EntryFee(bytes32 playerId,uint256 nftId,uint256 nftSeries,uint256 feeAmount);
    event ParticipateOfNewPlayerInLateBuyBackIn(bytes32 playerId,uint256 moveAtStage,uint256 amount);


    constructor(IERC20 _wrappedEther,address _commuinty) {
        token = _wrappedEther;
        _communityOwnerWA[0] = owner();
        _communityOwnerWA[1] = _commuinty;
        _NarrowingNumberProbility =  15;
    }

    function _gameEndRules() internal view returns(bool) {
        GameStatus storage _gameStatus = GameStatusInitialized[_latestGameId];
        require((_gameStatus.startAt > 0 && block.timestamp >= _gameStatus.startAt),"Game start after intialized time.");
        if(lastUpdateTimeStamp > 0){
            require(_dayDifferance(block.timestamp, lastUpdateTimeStamp) <= gameEnded,"Game Ended ...!");
        }
        return true;
    }

    function _narrowingGameEndRules() internal view returns(bool) {
       if((_narrowingGameMap > 0) && (_narrowingGameMap  < _NarrowingNumberProbility) 
            && (_dayDifferance(block.timestamp,GameStatusInitialized[_latestGameId].startAt) > GameStatusInitialized[_latestGameId].lastUpdationDay))
        {
            require(isNarrowingGameEnded == true ,"Narrowing Game Ended.");
        }
        return true;
    }

    modifier GameEndRules() {
        _gameEndRules();
        _;
    }

    modifier NarrowingGameEndRules() {
       _narrowingGameEndRules();
        _;
    }


	function uint256ToArray(uint256 value,uint256 _range) internal pure returns (uint256) {
		uint256[] memory array = new uint256[](10); // Assuming you want an array of size 32
		uint256 return_number = 0;

		for (uint256 i = 0; i < 10; i++) {
			array[i] = uint256((value >> (8 * (31 - i))) & 0xFF);
			if(array[i] < _range){
				return_number = array[i]; 
			}
		}

		return return_number +  1;
	}

    function _removeForList(uint index)  internal{
        delete _gameWinners[index];
        // _gameWinners[index] =  _gameWinners[_gameWinners.length - 1];
        // _gameWinners.pop();
    }

    function _random(uint256 _range) internal view returns (uint256) {
        return uint256ToArray(uint256(keccak256(abi.encodePacked(block.timestamp,block.difficulty,msg.sender))),_range);
    }

    function _balanceOfUser(address _accountOf) internal view returns (uint256) {
        return token.balanceOf(_accountOf);
    }

    function _randomNarrowingGame(uint256 _range) internal view returns (uint256) {
        return uint256ToArray(uint256(keccak256(abi.encodePacked(address(this),block.timestamp,block.difficulty,msg.sender,address(0)))),_range);
    }

    function removeSecondListItem(uint index,uint256 _stages)  internal {
        bytes32[] storage _stagesData = allStagesData[_stages];
        delete _stagesData[index];
        // _stagesData[index] =  _stagesData[_stagesData.length - 1];
        // _stagesData.pop();
    }

    function treasuryBalance() public view returns (uint256) {
        return _balanceOfUser(address(this));
    }
  
    // function _withdraw(uint256 withdrawAmount) internal {
    //     token.transfer(msg.sender, withdrawAmount);
    // }

    function _calculateBuyBackIn() internal view returns (uint256) {
        if (GameStatusInitialized[_latestGameId].stageNumber > 0) {
            if (GameStatusInitialized[_latestGameId].stageNumber <= buyBackCurve.length) {
                return buyBackCurve[GameStatusInitialized[_latestGameId].stageNumber - 1];
            }else if(GameStatusInitialized[_latestGameId].stageNumber > buyBackCurve.length){
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
        uint randomnumber = uint256ToArray(uint(keccak256(abi.encodePacked(block.timestamp , msg.sender, address(this)))),_range);
        if(randomnumber < 5){
            return randomnumber = randomnumber + 5;
        }else{
            return randomnumber;
        }
    }

    function _overFlow(bytes32 _playerId,uint256 jumpAtStage,bool _jumpSide) internal returns(bool)  {
        // if(totalNFTOnTile[jumpAtStage][_jumpSide] <= 0){                
        //     OverFlowPlayerStatus[_playerId] =  false;
        // }

        if(totalNFTOnTile[jumpAtStage][_jumpSide] > 0 ){
            totalNFTOnTile[jumpAtStage][_jumpSide] = totalNFTOnTile[jumpAtStage][_jumpSide] - 1;
        }

        bool isSafeSide = GameMap[jumpAtStage - 1] >= 50e9;

        if(jumpAtStage >= 2  && TitleCapacityAgainestStage[jumpAtStage - 1] >= totalNFTOnTile[jumpAtStage - 1][isSafeSide]){
            totalNFTOnTile[jumpAtStage - 1][isSafeSide] = totalNFTOnTile[jumpAtStage - 1][isSafeSide] + 1;
        }  

        return  OverFlowPlayerStatus[_playerId];
    }

    function isExistForRandomSide(uint256[] memory _playerIDNumberList,uint256  _playerIDindex) public pure returns(bool){
        for (uint i = 0; i < _playerIDNumberList.length; i++) {
            if(_playerIDNumberList[i] == _playerIDindex){
                return false;
            }
        }     
        return true;
    } 

    function isExist(bytes32 _playerID) public view returns(bool){
        for (uint i = 0; i < _participatePlayerList.length; i++) {
            if(_participatePlayerList[i] == _playerID){
                return false;
            }
        }     
        return true;
    } 

    function initializeGame(uint256 _startAT) public onlyOwner {
        GameStatus storage _gameStatus = GameStatusInitialized[_latestGameId];
        require(_gameStatus.startAt == 0, "Game Already Initilaized"); 
        require(_startAT >= block.timestamp,"Time must be greater then current time.");
        _gameStatus.startAt = _startAT;
        _gameStatus.isDistribution = true;
        isNarrowingGameEnded = true;
        emit Initialized(block.timestamp);
    }

    function entryFeeSeries(bytes32  _playerId,uint256 _nftId,uint8 _seriesType) public  NarrowingGameEndRules {
        require(_seriesType == 1 || _seriesType == 2, "Invalid seriseType");
         
        GameStatus storage _gameStatus = GameStatusInitialized[_latestGameId];
        if(lastUpdateTimeStamp > 0){
            require(_dayDifferance(block.timestamp, lastUpdateTimeStamp) <= gameEnded,"Game Ended !");
            lastUpdateTimeStamp = block.timestamp;
        }
        bytes32 playerId = _computeNextPlayerIdForHolder(msg.sender, _nftId, _seriesType);
        GameItem storage _member = PlayerItem[playerId];
        require(playerId == _playerId,"Player ID doesn't match ");
        if(isExist(playerId)){    
            _participatePlayerList.push(playerId);    
        }
     
        if(OverFlowPlayerStatus[playerId] == true && _checkSide(_member.stage, _member.lastJumpSide)){
            revert("No Need to pay");
        }

        // if(
        //     ((OverFlowPlayerStatus[playerId] == false && _checkSide(_member.stage, _member.lastJumpSide) == true)) 
        //     || 
        //     ((OverFlowPlayerStatus[playerId] == true && _checkSide(_member.stage, _member.lastJumpSide) == false))
        //     || 
        //     ((OverFlowPlayerStatus[playerId] == false && _checkSide(_member.stage, _member.lastJumpSide) == false))
        // ){

            if(_member.stage > 0){
                _deletePlayerIDForSpecifyStage(_member.stage,playerId);
            }

            if (_member.userWalletAddress != address(0)) {
                require(_dayDifferance(_member.lastJumpTime,_gameStatus.startAt) + 1 < _dayDifferance(block.timestamp, _gameStatus.startAt),"Buyback is useful only one time in 24 hours");
                _member.lastJumpTime =_member.startAt=_member.stage =_member.day = 0;    
                _member.lastJumpSide = false;
            } 

            _member.nftId = _nftId;
            _member.feeStatus = true;
            _member.playerId = playerId;
            _member.nftSeriestype = _seriesType;
            _member.userWalletAddress = msg.sender;
            _member.ishold =  false;
            
            OverFlowPlayerStatus[playerId] =  true;
            allStagesData[_member.stage].push(playerId);
            
            if(_seriesType == 1){
                emit EntryFee(playerId, _nftId, 1, 0);
            }else if(_seriesType == 2){
                require(_balanceOfUser(msg.sender) >= SERIES_TWO_FEE,"Insufficient balance");
                token.safeTransferFrom(msg.sender, address(this), SERIES_TWO_FEE);
                emit EntryFee(playerId, _nftId, 2, SERIES_TWO_FEE);
            }

    }

    function bulkEntryFeeSeries(bytes32[] calldata _playerId,uint256[] calldata _nftId, uint8 seriesType) external {
        for (uint256 i = 0; i < _nftId.length; i++) {
            entryFeeSeries(_playerId[i],_nftId[i],seriesType);
        }
    }

    function changeCommunityOwnerWA(address[2] calldata communityOwnerWA) external onlyOwner {
        for (uint i = 0; i < communityOwnerWA.length; i++) {
            _communityOwnerWA[i] = communityOwnerWA[i];
        }
    }

    function buyBackInFee(bytes32 playerId) public GameEndRules NarrowingGameEndRules {
        uint256 buyBackFee = _calculateBuyBackIn();
        require(_balanceOfUser(msg.sender) >= buyBackFee,"Insufficient balance");
        GameItem storage _member = PlayerItem[playerId]; //memory
        require((_member.userWalletAddress != address(0)) && (_member.userWalletAddress == msg.sender),"Only Player Trigger");
        require(_dayDifferance(block.timestamp, _member.lastJumpTime) <= 1,"Buy Back can be used in 24 hours only");
        // require(_checkSide(_member.stage, _member.lastJumpSide) == false, "Already In Game");
           
        if(OverFlowPlayerStatus[playerId] == true && _checkSide(_member.stage, _member.lastJumpSide)){
            revert("No Need to pay");
        }
    
        if( _member.stage - 1 >= 1 &&  totalNFTOnTile[_member.stage - 1][_member.lastJumpSide] == 0 ){
                OverFlowPlayerStatus[playerId] =  false;
        }else{
            OverFlowPlayerStatus[playerId] =  true;
            if( totalNFTOnTile[_member.stage - 1][_member.lastJumpSide] > 0){
                totalNFTOnTile[_member.stage - 1][_member.lastJumpSide]--;
            }
        }


        _member.stage = _member.stage - 1;
        _member.day = 0;
        _member.feeStatus = true;
        _member.lastJumpTime = block.timestamp;
        _member.lastJumpSide = GameMap[_member.stage] >= 50e9;

        allStagesData[_member.stage].push(playerId);
        _deletePlayerIDForSpecifyStage(_member.stage + 1,playerId);
        token.safeTransferFrom(msg.sender, address(this), buyBackFee);
        emit ParticipateOfPlayerInBuyBackIn(playerId, buyBackFee);
    }

    function bulkBuyBackInFee(bytes32[] calldata _playerId) external {
        for (uint256 i = 0; i < _playerId.length; i++) {
            buyBackInFee(_playerId[i]);
        }
    }

    function switchSide(bytes32 playerId) external  GameEndRules NarrowingGameEndRules{
        GameItem storage _member = PlayerItem[playerId];
        require(_member.feeStatus == true, "Please Pay Entry Fee.");
        require(_member.userWalletAddress == msg.sender,"Only Player Trigger");
        require(_dayDifferance(block.timestamp,GameStatusInitialized[_latestGameId].startAt) == _member.day, "Switch tile time is over.");
        _member.lastJumpSide =  _member.lastJumpSide  == true ? false : true ;
        _member.ishold =  false;
        _overFlow(playerId,PlayerItem[playerId].stage,PlayerItem[playerId].lastJumpSide);
        lastUpdateTimeStamp = block.timestamp;
    }

    function participateInGame(bool _jumpSide, bytes32 playerId) public  GameEndRules NarrowingGameEndRules{
        GameItem storage _member = PlayerItem[playerId];
        GameStatus storage  _gameStatus = GameStatusInitialized[_latestGameId];        
        
        uint256 currentDay = _dayDifferance(block.timestamp,_gameStatus.startAt);

        require(_member.userWalletAddress == msg.sender,"Only Player Trigger");
        require(_member.feeStatus == true, "Please Pay Entry Fee.");
        require(OverFlowPlayerStatus[playerId] == true,"Drop down due to overflow."); 

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

        uint256 _currentUserStage = _member.stage + 1;

        if (GameMap[_currentUserStage] <= 0) {
            uint256 _globalStageNumber  = _gameStatus.stageNumber + 1;
            // uint256 newCapacity = _generateTitleCapacity(_globalStageNumber);
            
            uint256 newCapacity = 3; //Remove

            totalNFTOnTile[_globalStageNumber][true] = newCapacity;
            totalNFTOnTile[_globalStageNumber][false] = newCapacity;
            TitleCapacityAgainestStage[_globalStageNumber] = newCapacity;

            GameMap[_globalStageNumber] = _random(100) * 1e9;
            _gameStatus.stageNumber = _globalStageNumber;
            _gameStatus.lastUpdationDay = currentDay;
            _narrowingGameMap =  ((GameMap[_globalStageNumber] / 1e9) / 2) + 1;
            // _narrowingGameMap = _randomNarrowingGame(100);
            _NarrowingNumberProbility++;
            delete _playerOnTile;
        }

        allStagesData[_currentUserStage].push(playerId);
        _deletePlayerIDForSpecifyStage(_member.stage,playerId);

        _overFlow(playerId,_currentUserStage,_jumpSide);

        _member.ishold =  false;
        _member.day = currentDay;
         //Replace due to (when player jumped true side     
        _member.lastJumpSide = _jumpSide;
        _member.stage = _currentUserStage;
        _member.startAt = block.timestamp;
        _member.lastJumpTime = block.timestamp;
        lastUpdateTimeStamp = block.timestamp;
        
        if(totalNFTOnTile[_currentUserStage][_jumpSide] <= 0){                
           _selectPlayerAndSetCapacityOnTile(_currentUserStage,currentDay,_jumpSide);
        }

        if((_narrowingGameMap < _NarrowingNumberProbility ) && (_gameStatus.stageNumber == _currentUserStage)){
            if(_checkSide(_gameStatus.stageNumber,_jumpSide) && OverFlowPlayerStatus[playerId]){ //If player successfull side but capacity over
                _gameWinners.push(playerId);
            }
            isNarrowingGameEnded =  false;
        }

        emit ParticipateOfPlayerInGame(playerId,_currentUserStage);
    }

    function bulkParticipateInGame(bool _jumpSides, bytes32[] calldata playerIds) external  GameEndRules {
        uint256 _currentStage = PlayerItem[playerIds[0]].stage;
        for (uint256 i = 0; i < playerIds.length; i++) {
            if(PlayerItem[playerIds[i]].stage == _currentStage){
                participateInGame(_jumpSides,playerIds[i]);
            }else{
                revert("Same Stage Players jump");
            }
        }
    }

    event selectJumpSidePlayerIdEvent(bytes32[] _jumpAtSidePlayerId);
    event unselectJumpSidePlayerIdEvent(bytes32[] _jumpAtSidePlayerId);

    function _selectJumpedSidePlayers(bytes32[] memory _playerIDAtSpecifyStage, bool _jumpAtSide,uint256 currentDay) public  returns(bytes32[]  memory){ 
        emit unselectJumpSidePlayerIdEvent(_playerIDAtSpecifyStage);
        //Get All Players on jumped side .
        for (uint i = 0; i < _playerIDAtSpecifyStage.length; i++) {
            /**
             if((PlayerItem[_playerIDAtSpecifyStage[i]].lastJumpSide == _jumpAtSide && OverFlowPlayerStatus[_playerIDAtSpecifyStage[i]] == true) ||
                (PlayerItem[_playerIDAtSpecifyStage[i]].lastJumpSide == _jumpAtSide) || 
                (OverFlowPlayerStatus[_playerIDAtSpecifyStage[i]] == false && currentDay == PlayerItem[_playerIDAtSpecifyStage[i]].day ))
            */

            if(
                (PlayerItem[_playerIDAtSpecifyStage[i]].lastJumpSide == _jumpAtSide )   &&
                (OverFlowPlayerStatus[_playerIDAtSpecifyStage[i]] == false && currentDay == PlayerItem[_playerIDAtSpecifyStage[i]].day )
                ||
                ((PlayerItem[_playerIDAtSpecifyStage[i]].lastJumpSide == _jumpAtSide && OverFlowPlayerStatus[_playerIDAtSpecifyStage[i]] == true))
                )
                
            {
                if(PlayerItem[_playerIDAtSpecifyStage[i]].stage >= 1){
                    _selectSuccessSidePlayerId.push(_playerIDAtSpecifyStage[i]);
                }
            }
     
        }
        emit selectJumpSidePlayerIdEvent(_selectSuccessSidePlayerId);
        return _selectSuccessSidePlayerId;
    }

    function isGameEnded() external view returns (bool) {
        GameStatus storage _gameStatus = GameStatusInitialized[_latestGameId];
        if(lastUpdateTimeStamp > 0){
            if ((_narrowingGameMap > 0) && (_dayDifferance(block.timestamp, _gameStatus.startAt) > _gameStatus.lastUpdationDay)) {
                return isNarrowingGameEnded;
            } else {
                return true;
            }
        }else{
            return true;
        }
    }

    function getAll() external view returns (uint256[] memory) {
        GameStatus storage _gameStatus = GameStatusInitialized[_latestGameId];
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
            _participatePlayerList.push(playerId);    
        }
        
        uint256 buyBackFee = _calculateBuyBackIn();
        uint256 totalAmount = 0;
        if (seriesType == 1) {
            totalAmount = buyBackFee;
        }
        if (seriesType == 2) {
            totalAmount = buyBackFee + SERIES_TWO_FEE;
        }
        // _transferAmount(totalAmount);
   
        GameStatus storage _gameStatus = GameStatusInitialized[_latestGameId];
        GameItem storage _member = PlayerItem[playerId];
        // require(_member.ishold == false, "Player in hold position.");

        if(OverFlowPlayerStatus[playerId] == true && _checkSide(_member.stage, _member.lastJumpSide) == true){
            revert("Already in Game");
        }

        // if((OverFlowPlayerStatus[playerId] == false && _checkSide(_member.stage, _member.lastJumpSide) == true) 
        // || ((OverFlowPlayerStatus[playerId] == true && _checkSide(_member.stage, _member.lastJumpSide) == false))){

        if(_member.stage > 0){
            _deletePlayerIDForSpecifyStage(_member.stage,playerId);
        }
        _member.userWalletAddress = msg.sender;  
        _member.startAt = block.timestamp;
        _member.stage = _gameStatus.stageNumber - 1;
        _member.day = 0; 

        _member.lastJumpSide = GameMap[_gameStatus.stageNumber - 1] >= 50e9;
        _member.feeStatus = true;
        _member.lastJumpTime = block.timestamp;
        _member.nftSeriestype = seriesType;
        _member.playerId = playerId;
        _member.nftId = _nftId;

        if(totalNFTOnTile[_member.stage][_member.lastJumpSide] > 0){
            totalNFTOnTile[_member.stage][_member.lastJumpSide] =  totalNFTOnTile[_member.stage][_member.lastJumpSide] - 1;
            OverFlowPlayerStatus[playerId] =  true;
        }

        // PlayerItem[playerId] = _member;
        lastUpdateTimeStamp = block.timestamp;
  
        allStagesData[_member.stage].push(playerId);
        require(_balanceOfUser(msg.sender) >= totalAmount,"Insufficient balance");
        token.safeTransferFrom(msg.sender, address(this), totalAmount);
        emit ParticipateOfNewPlayerInLateBuyBackIn(playerId,_gameStatus.stageNumber - 1,totalAmount);
    }

    function allParticipatePlayerID() external view returns(bytes32[] memory) {
        return _participatePlayerList;
    }


    function withdraw() external onlyOwner {
        // _withdraw(treasuryBalance());
        token.safeTransfer(msg.sender, treasuryBalance());
    }


    function isDrop(bytes32 _playerID) external view returns (bool) {
        GameStatus storage _gameStatus = GameStatusInitialized[_latestGameId];
        if(lastUpdateTimeStamp > 0){
            if (_dayDifferance(block.timestamp, _gameStatus.startAt) > _gameStatus.lastUpdationDay) {
                
                return  OverFlowPlayerStatus[_playerID];
            
            }else{
                return true;
            } 
        }else{
                return true;
        }
    }  
    
    /*
    * Set the random Players of next stage.
    * If the capacity of next stage is three then sample these three players are stable.
    * If the capacity of  next stage are greater then three then randomlly select any three players.
    * And set the capacity of current moved tile/stage.
    */
    event randomIndexEvent(uint256[] _indexs);
    event setCapacityEvent(uint256 _capacity,uint256 _no);
    function _selectPlayerAndSetCapacityOnTile(uint256 _currentPlayerStage,uint256 currentDay,bool _jumpSide) internal  { 
        bytes32[] memory _selectJumpedSidePlayersId; 
        // bool currentJumpSide;  
        if(_currentPlayerStage  > 0){
            bytes32[] memory PlayerIDAtSpecifyStage  =  getStagesData(_currentPlayerStage);
            // Set (3) into the variable
            // currentJumpSide = GameMap[_currentPlayerStage] >= 50e9; // check 
            _selectJumpedSidePlayersId =  _selectJumpedSidePlayers(PlayerIDAtSpecifyStage,_jumpSide,currentDay);
            
            //If generated Capacity is less tile capacity on jumped side then use random selection function. 
            if(_selectJumpedSidePlayersId.length > TitleCapacityAgainestStage[_currentPlayerStage]){
                // Randomlly Select NFT's ANY three maxiumn or minmmun two NFT"S
                for (uint256 j = 0; j < _selectJumpedSidePlayersId.length; j++) {
                    if(PlayerItem[_selectJumpedSidePlayersId[j]].ishold == false){  // Expect Hold and Mute All NFT" select
                        _selectUnholdPlayerId.push(_selectJumpedSidePlayersId[j]);
                        OverFlowPlayerStatus[_selectUnholdPlayerId[j]] =  false;
                    }
                }
                  // //Randomlly Select Index of NFT"S Id (_selectUnholdPlayerId) of previous stage
                _randomSelectPlayerIndex = generateRandomTicketNumbers(_selectUnholdPlayerId.length - 1 ,_selectUnholdPlayerId.length - 1,TitleCapacityAgainestStage[_currentPlayerStage]);
            }

            if(_selectJumpedSidePlayersId.length > TitleCapacityAgainestStage[_currentPlayerStage]){
                emit randomIndexEvent(_randomSelectPlayerIndex);
                uint256 _setTileCapacity =  0; 
                for (uint256 k = 0; k < _randomSelectPlayerIndex.length; k++) { //clear
                    if(_randomSelectPlayerIndex[k] > 0){
                        
                        if(isExistForRandomSide(_uniqueRN,_randomSelectPlayerIndex[k])){
                            _setTileCapacity =  _setTileCapacity + 1;
                            _uniqueRN.push(_randomSelectPlayerIndex[k]);
                            OverFlowPlayerStatus[_selectUnholdPlayerId[_randomSelectPlayerIndex[k]]] = true;
                        }
                    }
                }

                if(TitleCapacityAgainestStage[_currentPlayerStage]  > 0 && _setTileCapacity > 0){
                    emit setCapacityEvent(_setTileCapacity,1);
                    totalNFTOnTile[_currentPlayerStage][_jumpSide] = TitleCapacityAgainestStage[_currentPlayerStage] - _setTileCapacity;
                }else{
                    emit setCapacityEvent(totalNFTOnTile[_currentPlayerStage][_jumpSide],2);
                    totalNFTOnTile[_currentPlayerStage][_jumpSide] = totalNFTOnTile[_currentPlayerStage][_jumpSide];
                }
            }            
        }


        delete _uniqueRN;
        delete _selectUnholdPlayerId; 
        delete _randomSelectPlayerIndex;
        delete _selectSuccessSidePlayerId; 
        /*
        * End the  {Set the random Nft's of previous stage.}
        */
    }

    function holdToPlayer(bytes32 playerIds) external  {
        GameItem storage _member = PlayerItem[playerIds];
        require(_member.stage > 0,"Stage must be greaater then zero");
        uint256 currentDay = _dayDifferance(block.timestamp,GameStatusInitialized[_latestGameId].startAt);
       
        if (_member.startAt == 0 && _member.lastJumpTime == 0) {
            //On First Day when current day & member day = 0
            require(currentDay >= _member.day, "Already Jumped");
        } else {
            //for other conditions
            require(currentDay > _member.day, "Already Jumped");
        }

        _member.ishold =  true;
        _member.day = currentDay;
        _member.startAt = block.timestamp;
        _member.lastJumpTime = block.timestamp;
        lastUpdateTimeStamp = block.timestamp;

    }  

    function _distributionReward() internal {
        uint256 _treasuryBalance = treasuryBalance();
        require(_treasuryBalance > 0 ,"Insufficient Balance");
        require(isNarrowingGameEnded == false," Distribution time should not start before reaching final stage.");
        if(GameStatusInitialized[_latestGameId].isDistribution){
            // 25% to owner wallet owner 
            ownerbalances[_communityOwnerWA[0]] = (_ownerRewarsdsPercent * _treasuryBalance) / 100;
            //vault 15% goes to community vault
            vaultbalances[_communityOwnerWA[1]] = (_communityVaultRewarsdsPercent * _treasuryBalance) / 100;
            //Player
            if(_gameWinners.length > 0){
                for (uint i = 0; i < _gameWinners.length; i++) {
                    // winnerbalances[_gameWinners[i]]  = (((_winnerRewarsdsPercent * treasuryBalance())) / 100) / (_gameWinners.length);
                    winnerbalances[_gameWinners[i]]  = (((_winnerRewarsdsPercent * _treasuryBalance)) / 100) / (_gameWinners.length);
                }
            }
        }
    }

    function withdrawWrappedEtherOFCommunity(uint8 withdrawtype) external  {
            GameStatus storage _gameStatus = GameStatusInitialized[_latestGameId];
            _distributionReward();
            _gameStatus.isDistribution = false;
            // GameStatusInitialized[_latestGameId] = _gameStatus;
        // Check enough balance available, otherwise just return false
        if (withdrawtype == 0) {
            require(ownerbalances[_communityOwnerWA[0]] > 0,"Insufficient Owner Balance");
            require(_communityOwnerWA[0] == msg.sender, "Only Owner use this");
            // _withdraw(ownerbalances[msg.sender]);
            token.safeTransfer(msg.sender, ownerbalances[msg.sender]);
            delete ownerbalances[msg.sender];
        } else if (withdrawtype == 1) {
            require(vaultbalances[_communityOwnerWA[1]] > 0,"Insufficient Vault Balance");
            require(_communityOwnerWA[1] == msg.sender, "Only vault use this");
            // _withdraw(vaultbalances[msg.sender]);
            token.safeTransfer(msg.sender, vaultbalances[msg.sender]);
            delete vaultbalances[msg.sender];
        } 
    }

    function claimWinnerEther(bytes32 playerId) external  {
        GameStatus storage _gameStatus = GameStatusInitialized[_latestGameId];
        require(PlayerItem[playerId].userWalletAddress == msg.sender,"Only Player Trigger");
        _distributionReward();
        _gameStatus.isDistribution = false;
        // GameStatusInitialized[_latestGameId] = _gameStatus;
        require(winnerbalances[playerId]  > 0,"Insufficient Player Balance");
        // _withdraw(winnerbalances[playerId]);
        token.safeTransfer(msg.sender, winnerbalances[playerId]);
        delete PlayerItem[playerId];      
        emit claimPlayerReward(playerId,winnerbalances[playerId]);
        _removeForList(_findIndex(playerId,_gameWinners));
    }

    /**
     * Check the previous stage Player length (stage > 1)
     * Set the capacity of tile 2X of previous tile and also include moving Player.
     */

    event PlayerTitleCapacityEvent(bytes32[] _player); //remove
    //alway double of Nft Capacity
    function _generateTitleCapacity(uint256 _stageNo) internal returns (uint256) { 
        if(_stageNo > 1){
        // tile ccpacity calculate when player jumped from tile 1 to 2 and up to so on.
        bool  previousJumpSide = GameMap[_stageNo] >= 50e9;             // Side Stage-#-1
        bytes32[] memory _playerIDAtStage = getStagesData(_stageNo);    // Side Stage-#-1
            for (uint i = 0; i < _playerIDAtStage.length; i++) {
                // Only Capacity Double  of inFlow.
                if((PlayerItem[_playerIDAtStage[i]].lastJumpSide == previousJumpSide ) && OverFlowPlayerStatus[_playerIDAtStage[i]] == true)
                {
                    _playerOnTile.push(_playerIDAtStage[i]);
                }
            }
            emit PlayerTitleCapacityEvent(_playerOnTile);
        }else{
            _playerOnTile = getStagesData(_stageNo);
        }
        return _playerOnTile.length * 2;
    }

    function updateBuyBackCurve(uint256[11] calldata val)  external onlyOwner{
        for (uint i = 0; i < val.length; i++) {
            buyBackCurve[i] = val[i];        
        }
    }

    // =========================Refe task ==========================

    function gameSetting(uint256 _gameEnded) public onlyOwner {
        gameEnded  = _gameEnded;
    }

    function restartGame(uint256 _startAT) public onlyOwner {
        for (uint i = 0; i < _participatePlayerList.length; i++) {
            delete PlayerItem[_participatePlayerList[i]];
            delete OverFlowPlayerStatus[_participatePlayerList[i]];
        }
        for (uint i = 0; i <= GameStatusInitialized[_latestGameId].stageNumber; i++) {
            delete allStagesData[i];
            delete GameMap[i];
        }
        token.safeTransfer(msg.sender, treasuryBalance());
        lastUpdateTimeStamp = 0;
        isNarrowingGameEnded = true;
        delete _gameWinners;
        delete _participatePlayerList;
        delete GameStatusInitialized[_latestGameId];
        initializeGame(_startAT);
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
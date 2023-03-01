// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;


import "./Pausable.sol";
import "./AccessControl.sol";
import "./IERC20.sol";
import "./AutomationCompatible.sol";
import "./LibMyChanceAvax.sol";
import "./LibLendingPool.sol";
import "./LibConstants.sol";
import "./RandomRequester.sol";
import "./Charities.sol";


interface IMigration {
    function migrate(
        uint256 tokenId,
        uint256 weight
    ) external returns(bool);
}

abstract contract Lottery is Charities, RandomRequester, Pausable, AutomationCompatibleInterface {
    mapping(uint256=>LMyChance.SpecialLottery) specialLotteries; //Dates for Special Lotteries
    mapping(uint256=>uint256) reqToSpecialLottery; //ReqID to Date (for Special Lottery)

    mapping(uint256 => uint256) public mintingDate;
    uint256 public platformStakes;

    mapping(uint256 =>uint256) public claimable;

    uint256 totalFeesAVAX;

    mapping(address=>uint256) public increasedStakes; // It keeps track of the staking of each user 
    uint256[] prizeBonds;

    mapping(uint256 => LMyChance.PrizeBondPosition) prizeBondPositions;

    uint256 pendingAVAX;
    
    uint256 totalAVAXBonds;
    
    uint256 sumWeights;

    uint256 public minimumWeight = 100;

    bool claimNotRequired;
    bool waitNotRequired;

    uint256 lastDrawn; //Date for the last normal drawn;

    struct ClaimVariables {
        uint256 totalFeesAVAX;
        uint256 totalToCharityAVAX;
        uint256 withdrawalAmountAVAX;
    }

    //Events
    event NewSpecialDraw(uint256 _drawDate);
    event SpecialDrawExecuted(uint256 indexed _tokenIdWinner, uint256 indexed _drawDate);
    event DrawExecuted(uint256 indexed _tokenIdWinner);
    event AssetsClaimed(address indexed _beneficiary, uint256 indexed _tokenId, uint256 _totalWinnerAVAX, uint256 _totalToCharityAVAX, uint256 _totalFeesLINK);
    event PrizeBondBurnt(uint256 indexed _tokenId);
    event StakeIncreased(uint256 _total);
    event StakeReduced(uint256 _total);
    event FeesClaimed(uint256 _total);

    constructor() {
        lastDrawn = block.timestamp - LibConstants.TIME_FOR_NEXT_DRAW;
        claimNotRequired = true;
        waitNotRequired = true;
    }

    //Public functions
    function draw() public whenNotPaused {
        require(canDraw(), "Not yet");

        lastDrawn = block.timestamp;
        _randomnessRequest();
    }

    function drawSpecialLottery(uint256 _drawDate) external whenNotPaused {
        LMyChance.SpecialLottery storage specialLottery = specialLotteries[_drawDate];
        require(specialLottery.valid, "Invalid");
        require(block.timestamp > _drawDate, "Not yet");
        require(specialLottery.drawn == false, "Already drawn");
        require(prizeBonds.length > 0, "Not enough bonds");

        specialLottery.drawn = true;
        uint256 reqId = _randomnessRequest();
        reqToSpecialLottery[reqId] = _drawDate;
    }
    
    function claim(uint256 _tokenId, uint256 _percentage, address payable _charity) external {
        require(LibConstants.prizeBond.ownerOf(_tokenId) == msg.sender, "Invalid owner");
        require(claimable[_tokenId] > 0, "Nothing to claim");
        require((block.timestamp > mintingDate[_tokenId] + LibConstants.TIME_FOR_NEXT_DRAW) || waitNotRequired, "Winner has to wait a week");
        require(_percentage >= 5, "Minimum is 5%");
        require(charities[_charity], "Invalid charity");

        if (_percentage > 100) {
            _percentage = 100;
        }

        uint256 totalAVAX = claimable[_tokenId];
        claimable[_tokenId] = 0;

        ClaimVariables memory claimVariables;

        if (totalAVAX > 0) {  
            (claimVariables.withdrawalAmountAVAX, claimVariables.totalFeesAVAX, claimVariables.totalToCharityAVAX) = LMyChance.claimInternal(totalAVAX, _percentage);
            totalFeesAVAX += claimVariables.totalFeesAVAX;
            pendingAVAX -= claimVariables.withdrawalAmountAVAX;
            LibLendingPool.withdraw(claimVariables.withdrawalAmountAVAX, address(this));
            payable (msg.sender).transfer((claimVariables.withdrawalAmountAVAX - claimVariables.totalToCharityAVAX));
            (bool sent,) = _charity.call{value: claimVariables.totalToCharityAVAX}("");
            require(sent, "Failed to send Ether");
            emit AssetsClaimed(msg.sender, 
                            _tokenId,  
                            (claimVariables.withdrawalAmountAVAX - claimVariables.totalToCharityAVAX), 
                            claimVariables.totalToCharityAVAX, 
                            claimVariables.totalFeesAVAX);
        }
    }

    function mintPrizeBond(uint weight) payable external whenNotPaused {
        require(weight >= minimumWeight, "Invalid weight");

        uint256 cost = weight * 1e16; //We set the minimum unit to 0.01
        require(msg.value == cost, "Invalid value");
        LibLendingPool.supply(cost);            
        totalAVAXBonds += weight;

        LMyChance.mint(LibConstants.prizeBond, weight, mintingDate, prizeBonds, prizeBondPositions);
        sumWeights += weight;
    }

    function burnPrizeBond(uint256 _tokenId) external {
        require(claimable[_tokenId] == 0 || claimNotRequired, "Please claim first");
        require(LibConstants.prizeBond.ownerOf(_tokenId) == msg.sender, "Invalid owner");

        LibConstants.prizeBond.safeBurn(_tokenId);

        uint256 weight = prizeBondPositions[_tokenId].weight;

        LibLendingPool.withdraw(weight * 1e16, msg.sender);
        totalAVAXBonds -= weight;

        // Updates the list of prize bonds
        uint256 deletedWeght = LMyChance.removeTicket(prizeBondPositions,prizeBonds,_tokenId);
        sumWeights -= deletedWeght;

        emit PrizeBondBurnt(_tokenId);
    }

    function increaseStake() payable external whenNotPaused {
        LibLendingPool.supply(msg.value);
        
        platformStakes += msg.value;
        increasedStakes[msg.sender] += msg.value;

        emit StakeIncreased(msg.value);
    }

    function reduceStake(uint256 _total) external {
        require(increasedStakes[msg.sender] >= _total, "Invalid amount");
        platformStakes -= _total;
        increasedStakes[msg.sender]-= _total;
        LibLendingPool.withdraw(_total, msg.sender);

        emit StakeReduced(_total);
    }

    //Public getters

    function canDraw() internal view returns (bool) {
        return block.timestamp >= getNextDrawDate() && prizeBonds.length > 0;
    }

    function accumulatedAVAX() public view returns (uint256) {
        return IERC20(LibConstants.avWAVAXToken).balanceOf(address(this)) - totalAVAXBonds * 1e16 - pendingAVAX - platformStakes;
    }

    function getNextDrawDate() public view returns(uint256) {
        return lastDrawn + LibConstants.TIME_FOR_NEXT_DRAW;
    }

    //Internal functions
    function _executeDraw(uint256 _random) internal { 
        uint256 winnerIndex = LMyChance.winner_index(_random, prizeBonds, prizeBondPositions, sumWeights);
        uint256 tokenId = prizeBonds[winnerIndex];
        uint256 totalAVAX = accumulatedAVAX();

        pendingAVAX += totalAVAX;
        claimable[tokenId] += totalAVAX;

        emit DrawExecuted(tokenId);
    }

    function _executeSpecialDraw(uint256 _random, uint256 _specialLotDate) internal {
        uint256 winnerIndex = LMyChance.winner_index(_random, prizeBonds, prizeBondPositions, sumWeights);
        uint256 tokenId = prizeBonds[winnerIndex];

        LMyChance.SpecialLottery storage lottery = specialLotteries[_specialLotDate];
        lottery.winner = tokenId;
        claimable[tokenId] += lottery.total;

        emit SpecialDrawExecuted(tokenId, _specialLotDate);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        if (reqToSpecialLottery[requestId] > 0) {
            _executeSpecialDraw(randomWords[0], reqToSpecialLottery[requestId]);
        } else {
            _executeDraw(randomWords[0]);
        }
    } 

    //ADMIN functions
    function setClaimNotRequired(bool set) onlyRole(DEFAULT_ADMIN_ROLE) public {
        claimNotRequired = set;
    }

    function setWaitNotRequired(bool set) onlyRole(DEFAULT_ADMIN_ROLE) public {
        waitNotRequired = set;
    }

    function _claimFees() onlyRole(FEES_ROLE) public {
        uint256 AVAXFees = totalFeesAVAX;
        totalFeesAVAX = 0;

        if (AVAXFees > 0) {
            LibLendingPool.withdraw(AVAXFees, msg.sender);
            pendingAVAX -= AVAXFees;
            emit FeesClaimed(AVAXFees);
        }
    }

    function _addSpecialLottery(uint256 _drawDate, uint256 _total, string memory _description) payable public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(msg.value == _total);
        pendingAVAX += _total;
        LMyChance.addSpecialLottery(_total, specialLotteries, _drawDate, _description);
        LibLendingPool.supply(_total);
        emit NewSpecialDraw(_drawDate);
    }
    
    receive() external payable {}
}

abstract contract Recovery is Lottery {
    function _recoverTokens(uint256 _amount, address _asset) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(prizeBonds.length == 0, "Contract in use");
        require(IERC20(_asset).transfer(msg.sender, _amount), 'Transfer failed');
    }

    function _recoverAVAX(uint256 _amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(msg.sender).transfer(_amount);
    }

    function _withdrawAndRecover(uint256 _amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(prizeBonds.length == 0, "Contract in use");
        LibLendingPool.withdraw(_amount, msg.sender);
    }
}

abstract contract Migratable is Recovery {
    address newInstance;
    mapping(uint256=>bool) migrated;

    function startMigration(address _newInstance) public onlyRole(MIGRATOR_ROLE) {
        require (newInstance == address(0), "Already set");
        newInstance = _newInstance;
    }

    function migrateMyself(uint256 _tokenId) external {
        require(claimable[_tokenId] == 0 || claimNotRequired, "Please claim first");
        require(LibConstants.prizeBond.ownerOf(_tokenId) == msg.sender, "Invalid owner");
        require (newInstance != address(0), "Cannot migrate yet");
        require(!migrated[_tokenId], "Already migrated");

        migrated[_tokenId] = true;

        uint256 weight = prizeBondPositions[_tokenId].weight;

        uint256 total;
        
        total = weight * 1e16;
        totalAVAXBonds -= weight;

        require(IERC20(LibConstants.avWAVAXToken).transfer(newInstance, total), 'Transfer failed');

        require(IMigration(newInstance).migrate(_tokenId, weight), "Migration failed");


        // Updates the list of prize bonds
        uint256 deletedWeght = LMyChance.removeTicket(prizeBondPositions, prizeBonds, _tokenId);
        sumWeights -= deletedWeght;
    }
}

contract MyChanceAVAX is Migratable {
    constructor() {
        _approveLP(LibConstants.avWAVAXToken, LibConstants.MAX_INT);
    }

    function migrate(uint256 tokenId, uint256 weight) public returns(bool) {
        require(msg.sender == 0x04f2559e75cf00a0eA163fC67e62E47C6743D02c, "Invalid caller");
        totalAVAXBonds += weight;
        sumWeights += weight;
        mintingDate[tokenId] = block.timestamp;
        prizeBonds.push(tokenId);
        prizeBondPositions[tokenId].weight = weight;
        prizeBondPositions[tokenId].index = prizeBonds.length - 1;
        return true;
    }

    //Keepers Functions
    function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory) {
        upkeepNeeded = canDraw();
    }

    function performUpkeep(bytes calldata) external override {
        draw();
    }

    //Pausable
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    //Minimum
    function _updateMinimumWeight(uint32 _minimumWeight) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_minimumWeight >= 1, "Minimum allowed is 1");
        minimumWeight = _minimumWeight;
    }

    //ChainLink
    function _updateCallbackGasLimit(uint32 _callbackGasLimit) public onlyRole(DEFAULT_ADMIN_ROLE) {
        callbackGasLimit = _callbackGasLimit;
    }

    //Lending Pool Gateway
    function _approveLP(address _token, uint256 _amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        LibLendingPool.approve(_token, _amount);        
    }

    //WETH Gateway
    function _approveGateway(address _token, uint256 _amount) public  onlyRole(DEFAULT_ADMIN_ROLE) {
        LibLendingPool._approveGateway(_token, _amount); 
    }

    //Public
    function getTotalPrizeBonds() public view returns(uint256) {
        return prizeBonds.length;
    }
 
    function getStakedAmount() public view returns (uint256){
        return increasedStakes[msg.sender];
    }
    
    function getListOfTickets() public view returns (uint256[] memory){
        return prizeBonds;
    }

    function getTicketData(uint256 tokenId) public view returns (LMyChance.PrizeBondPosition memory ) {
        return prizeBondPositions[tokenId];
    }

    function getState() public view returns(uint256, uint256, uint256, bool, bool) {
        return (pendingAVAX, totalAVAXBonds, sumWeights, claimNotRequired, waitNotRequired);
    }
}
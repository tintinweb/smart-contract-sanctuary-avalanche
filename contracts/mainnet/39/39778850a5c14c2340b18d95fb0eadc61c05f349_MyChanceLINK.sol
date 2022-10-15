// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


import "./IPool.sol";
import "./IPrizeBondLINK.sol";
import "./LibMyChanceLink.sol";
import "./LibLendingPool.sol";
import "./LibConstants.sol";
import "./RandomRequester.sol";
import "./LibLendingPool.sol";
import "./Charities.sol";

import "./Pausable.sol";
import "./AccessControl.sol";
import "./IERC20.sol";
import "./KeeperCompatible.sol";

interface IMigration {
    function migrate(
        uint256 tokenId,
        uint256 weight
    ) external returns(bool);
}

abstract contract Lottery is Charities, RandomRequester, Pausable, KeeperCompatibleInterface {
    mapping(uint256=>LMyChance.SpecialLottery) specialLotteries; //Dates for Special Lotteries
    mapping(uint256=>uint256) reqToSpecialLottery; //ReqID to Date (for Special Lottery)

    mapping(uint256 => uint256) public mintingDate;
    uint256 public platformStakes;

    mapping(uint256 =>uint256) public claimable;

    uint256 totalFeesLINK;

    mapping(address=>uint256) public increasedStakes; // It keeps track of the staking of each user 
    uint256[] prizeBonds;

    mapping(uint256 => LMyChance.PrizeBondPosition) prizeBondPositions;

    uint256 pendingLINK;
    
    uint256 totalLinkBonds;
    
    uint256 sumWeights;

    uint256 public minimumWeight = 100;

    uint256 lastDrawn; //Date for the last normal drawn;

    struct ClaimVariables {
        uint256 totalFeesLINK;
        uint256 totalToCharityLINK;
        uint256 withdrawalAmountLINK;
    }

    //Events
    event NewSpecialDraw(uint256 _drawDate);
    event SpecialDrawExecuted(uint256 indexed _tokenIdWinner, uint256 indexed _drawDate);
    event DrawExecuted(uint256 indexed _tokenIdWinner);
    event AssetsClaimed(address indexed _beneficiary, uint256 indexed _tokenId, uint256 _totalWinnerLINK, uint256 _totalToCharityLINK, uint256 _totalFeesLINK);

    constructor() {
        lastDrawn = block.timestamp - LibConstants.TIME_FOR_NEXT_DRAW;
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
    
    function claim(uint256 _tokenId, uint256 _percentage) external {
        require(LibConstants.prizeBond.ownerOf(_tokenId) == msg.sender, "Invalid owner");
        require(claimable[_tokenId] > 0, "Nothing to claim");
        require(block.timestamp > mintingDate[_tokenId] + LibConstants.TIME_FOR_NEXT_DRAW, "Winner has to wait a week");
        require(_percentage >= 5, "Minimum is 5%");

        if (_percentage > 100) {
            _percentage = 100;
        }

        uint256 totalLINK = claimable[_tokenId];
        claimable[_tokenId] = 0;

        address charity = aCharities[currentCharity % (aCharities.length - 1)];
        currentCharity += 1;

        ClaimVariables memory claimVariables;

        if (totalLINK > 0) {  
            (claimVariables.withdrawalAmountLINK, claimVariables.totalFeesLINK, claimVariables.totalToCharityLINK) = LMyChance.claimInternal(totalLINK, LibConstants.linkToken, charity, _percentage);
            totalFeesLINK += claimVariables.totalFeesLINK;
            pendingLINK -= claimVariables.withdrawalAmountLINK;
            LibLendingPool.withdraw(LibConstants.linkToken, claimVariables.withdrawalAmountLINK, address(this));

            emit AssetsClaimed(msg.sender, 
                            _tokenId,  
                            (claimVariables.withdrawalAmountLINK - claimVariables.totalToCharityLINK), 
                                claimVariables.totalToCharityLINK, 
                                claimVariables.totalFeesLINK);
        }
    }

    function mintPrizeBond(uint weight) external whenNotPaused {
        require(weight >= minimumWeight, "Invalid weight");

        uint256 cost = weight * 1e16;
        require(IERC20(LibConstants.linkToken).transferFrom(msg.sender, address(this), cost), "Transfer failed");
        LibLendingPool.supply(LibConstants.linkToken, cost);            
        totalLinkBonds += weight;

        LMyChance.mint(LibConstants.prizeBond, weight, mintingDate, prizeBonds, prizeBondPositions);
        sumWeights += weight;
    }

    function burnPrizeBond(uint256 _tokenId) external {
        require(claimable[_tokenId] == 0, "You must claim first");
        require(LibConstants.prizeBond.ownerOf(_tokenId) == msg.sender, "Invalid owner");

        LibConstants.prizeBond.safeBurn(_tokenId);

        uint256 weight= prizeBondPositions[_tokenId].weight;

        LibLendingPool.withdraw(LibConstants.linkToken, weight * 1e16, msg.sender);
        totalLinkBonds -= weight;

        // Updates the list of prize bonds
        uint256 deletedWeght = LMyChance.removeTicket(prizeBondPositions,prizeBonds,_tokenId);
        sumWeights -= deletedWeght;
    }

    function increaseStake(uint256 _total) external whenNotPaused {
        require(IERC20(LibConstants.linkToken).transferFrom(msg.sender, address(this), _total), 'Transfer failed');
        LibLendingPool.supply(LibConstants.linkToken, _total);
        
        platformStakes += _total;
        increasedStakes[msg.sender] += _total;
    }

    function reduceStake(uint256 _total) external {
        require(increasedStakes[msg.sender] >= _total, "Invalid amount");
        platformStakes -= _total;
        increasedStakes[msg.sender]-=_total;
        LibLendingPool.withdraw(LibConstants.linkToken, _total, msg.sender);
       
    }

    //Public getters

    function canDraw() internal view returns (bool) {
        return block.timestamp >= getNextDrawDate() && prizeBonds.length > 0;
    }

    function accumulatedLINK() public view returns (uint256) {
        return IERC20(LibConstants.aLinkToken).balanceOf(address(this)) - totalLinkBonds * 1e16 - pendingLINK - platformStakes;
    }

    function getNextDrawDate() public view returns(uint256) {
        return lastDrawn + LibConstants.TIME_FOR_NEXT_DRAW;
    }

    //Internal functions
    function _executeDraw(uint256 _random) internal { 
        uint256 winnerIndex = LMyChance.winner_index(_random, prizeBonds, prizeBondPositions, sumWeights);
        uint256 tokenId = prizeBonds[winnerIndex];
        uint256 totalLINK = accumulatedLINK();

        pendingLINK += totalLINK;

        if (totalLINK > 0) 
        {
            claimable[tokenId] += totalLINK;
        }

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
    function _claimFees() onlyRole(FEES_ROLE) public {
        uint256 linkFees = totalFeesLINK;
        totalFeesLINK = 0;

        if (linkFees > 0) {
            LibLendingPool.withdraw(LibConstants.linkToken, linkFees, msg.sender);
            pendingLINK -= linkFees;
        }
            
    }

    function _addSpecialLottery(uint256 _drawDate, uint256 _total, string memory _description) public onlyRole(DEFAULT_ADMIN_ROLE) {
        
        pendingLINK += _total;
        LMyChance.addSpecialLottery(LibConstants.linkToken, _total, specialLotteries, _drawDate, _description);
        LibLendingPool.supply(LibConstants.linkToken, _total);
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
        require(prizeBonds.length == 0, "Contract in use");
        payable(msg.sender).transfer(_amount);
    }

    function _withdrawAndRecover(uint256 _amount, address _asset) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(prizeBonds.length == 0, "Contract in use");
        LibLendingPool.withdraw(LibConstants.linkToken, _amount, msg.sender);
    }
}

abstract contract Migratable is Recovery {
    address newInstance;

    function startMigration(address _newInstance) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require (newInstance == address(0), "Already set");
        newInstance = _newInstance;
    }

    function migrateMyself(uint256 _tokenId) external {
        require(claimable[_tokenId] == 0, "You must claim first");
        require(LibConstants.prizeBond.ownerOf(_tokenId) == msg.sender, "Invalid owner");
        require (newInstance != address(0), "Cannot migrate yet");

        uint256 weight = prizeBondPositions[_tokenId].weight;

        uint256 total;
        
        total = weight * 1e16;
        totalLinkBonds -= weight;

        require(IERC20(LibConstants.aLinkToken).transfer(newInstance, total), 'Transfer failed');

        require(IMigration(newInstance).migrate(_tokenId, weight), "Migration failed");

        // Updates the list of prize bonds
        uint256 deletedWeght = LMyChance.removeTicket(prizeBondPositions, prizeBonds, _tokenId);
        sumWeights -= deletedWeght;
    }
}

contract MyChanceLINK is Migratable {
    constructor() {
        _approveLP(LibConstants.linkToken, LibConstants.MAX_INT);
    }

    //Keepers Functions
    function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory ) {
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

    //ERC20
    function _approveLP(address _token, uint256 _amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        LibLendingPool.approve(_token, _amount);        
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
}
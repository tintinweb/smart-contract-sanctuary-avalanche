// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


import "./IPool.sol";
import "./IPrizeBondLINK.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./LinkTokenInterface.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";
import "./KeeperCompatible.sol";


contract MyChance is Ownable, VRFConsumerBaseV2, Pausable, KeeperCompatibleInterface {
    // ChainLink integration
    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;
    address constant vrfCoordinator = 0xd5D517aBE5cF79B7e95eC98dB0f0277788aFF634;
    uint32 callbackGasLimit = 800000;

    // AAVE & Token addresses in Avalanche
    address constant linkToken = 0x5947BB275c521040051D82396192181b413227A3;
    address constant aLinkToken = 0x191c10Aa4AF7C30e871E70C95dB0E4eb77237530;
    IPool constant lendingPool = IPool(0x794a61358D6845594F94dc1DB02A252b5b4814aD);
    
    uint256 constant PRICE = 10;
    uint256 constant TIME_FOR_NEXT_DRAW = 7 * 1 days;
    uint256 constant MAX_INT = 2**256 - 1;

    mapping(address => bool) public charities;
    address[] public aCharities;
    uint256 currentCharity = 0;

    mapping(uint256=>SpecialLottery) specialLotteries; //Dates for Special Lotteries
    mapping(uint256=>uint256) reqToSpecialLottery; //ReqID to Date (for Special Lottery)

    mapping(uint256 => uint256) public mintingDate;
    uint256 public platformStakes;

    mapping(uint256 => uint256) public claimable;

    uint256 public totalFees;

    mapping(address=>uint256) public increasedStakes; // It keeps track of the staking of each user 
    IPrizeBondLINK prizeBond = IPrizeBondLINK(0x461C75ee37ec7B334A777Fc7Fc5a85df1B6E203D);
    uint256[] prizeBonds;

    mapping(uint256 => PrizeBondPosition) prizeBondPositions;

    uint256 pendingLINK;
    uint256  totalLINKBonds;

    uint256 sumWeights;

    uint256 lastDrawn; //Date for the last normal drawn;

    struct SpecialLottery {
        bool valid;
        bool drawn;
        uint256 total;
        string description;
        uint256 winner;
    }

    struct PrizeBondPosition {
        uint index;
        uint weight;
    }

    //Events
    event NewSpecialDraw(uint256 _drawDate);
    event SpecialDrawExecuted(uint256 indexed _tokenIdWinner, uint256 indexed _drawDate);
    event DrawExecuted(uint256 indexed _tokenIdWinner);

    constructor() VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(linkToken);

        _approveLP(linkToken, MAX_INT);
       
        lastDrawn = block.timestamp;

        _enableCharity(0x0B98d3b5ad68992559F9684A70310e48aE892A48, true);
        _enableCharity(0x0DdcAE532E4b1B31500Cd29d7AC110F052e30645, true);
        _enableCharity(0x74CE447d787313E4555C0D3E03C3934E0C0bDB6A, true);
        _enableCharity(0xE9bFF54D628DBe3C8C59f74ccb1aB4560a1713C0, true);
        _enableCharity(0xF8fF6e693b9B8C6A25891cC0bAB53960aac95453, true);
    }

    //Keepers Functions
    function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory ) {
        upkeepNeeded = canDraw();
    }

    function performUpkeep(bytes calldata) external override {
        draw();
    }

    //Public functions

    function draw() public whenNotPaused {
        require(canDraw(), "Not yet");

        lastDrawn = block.timestamp;
        _randomnessRequest();
    }

    function drawSpecialLottery(uint256 _drawDate) public whenNotPaused {
        SpecialLottery storage specialLottery = specialLotteries[_drawDate];
        require(specialLottery.valid, "Invalid");
        require(block.timestamp > _drawDate, "Not yet");
        require(specialLottery.drawn == false, "Already drawn");
        require(prizeBonds.length > 0, "Not enough bonds");

        specialLottery.drawn = true;
        uint256 reqId = _randomnessRequest();
        reqToSpecialLottery[reqId] = _drawDate;
    }

     function claim(uint256 _tokenId, uint256 _percentage) public {
        require(prizeBond.ownerOf(_tokenId) == msg.sender, "Invalid owner");
        require(claimable[_tokenId] > 0, "Nothing to claim");
        require(block.timestamp > mintingDate[_tokenId] + TIME_FOR_NEXT_DRAW, "Winner has to wait a week for get the first prize");
        require(_percentage >= 5, "Minimum to donate is 5%");

        if (_percentage > 100) {
            _percentage = 100;
        }

        uint256 totalLINK = claimable[_tokenId];
        claimable[_tokenId] = 0;

        address charity = aCharities[currentCharity % (aCharities.length - 1)];
        currentCharity += 1;

        //Donate and substract fees

        //30% operational cost
        //20% automatic contribution to social causes
        //35% weekly prize distribution
        //15% special prize draws

        if (totalLINK > 0) {
            uint256 totalToCharityLINK = totalLINK * 20 / 100;
            uint256 totalFeesLINK = totalLINK * 45 / 100;
            uint256 totalWinnerLINK = totalLINK * 35 / 100;
            uint256 extraToCharityLINK = totalWinnerLINK * _percentage / 100;
            totalToCharityLINK += extraToCharityLINK;
            totalWinnerLINK -= extraToCharityLINK;

            // Platform's fees remain in the AAVE pool
            uint256 withdrawalAmount = totalLINK - totalFeesLINK;
            pendingLINK -= withdrawalAmount;

            lendingPool.withdraw(linkToken, withdrawalAmount, address(this));
            if (totalWinnerLINK > 0) {
                require(IERC20(linkToken).transfer(msg.sender, totalWinnerLINK), 'Transfer failed');
            }
            require(IERC20(linkToken).transfer(charity, totalToCharityLINK), 'Transfer failed');

            totalFees += totalFeesLINK;
        }
    }

    function mintPrizeBond(uint weight) public whenNotPaused {
        require(weight > 0, "Invalid weight");

        uint256 cost = PRICE * weight * 1e18;
        require(IERC20(linkToken).transferFrom(msg.sender, address(this), cost), "Transfer failed");
        lendingPool.supply(linkToken, cost, address(this), 0);
        totalLINKBonds += weight;
    

        uint256 tokenId = prizeBond.safeMint(msg.sender);
        mintingDate[tokenId] = block.timestamp;
        prizeBonds.push(tokenId);
        prizeBondPositions[tokenId].weight= weight;
        prizeBondPositions[tokenId].index = prizeBonds.length - 1;
        sumWeights+=weight;
    }

    function burnPrizeBond(uint256 _tokenId) public {
        require(claimable[_tokenId] == 0, "You must claim first");
        require(prizeBond.ownerOf(_tokenId) == msg.sender, "Invalid owner");

        prizeBond.safeBurn(_tokenId);

        uint256 weight= prizeBondPositions[_tokenId].weight;

        lendingPool.withdraw(linkToken, PRICE * weight * 1e18, msg.sender);
        totalLINKBonds -= weight;
        

        // Updates the list of prize bonds
        PrizeBondPosition memory deletedTicket = prizeBondPositions[_tokenId];
        if (deletedTicket.index != prizeBonds.length-1) {
            uint256 lastTokenId = prizeBonds[prizeBonds.length-1];
            prizeBonds[deletedTicket.index] = lastTokenId;
            prizeBondPositions[lastTokenId].index = deletedTicket.index;
        }
        sumWeights -= deletedTicket.weight;
        delete prizeBondPositions[_tokenId];
        prizeBonds.pop();
    }

    function increaseStake(uint256 _total) public whenNotPaused {
        require(IERC20(linkToken).transferFrom(msg.sender, address(this), _total), 'Transfer failed');
        lendingPool.supply(linkToken, _total, address(this), 0);
        
        platformStakes += _total;
        increasedStakes[msg.sender] += _total;
    }

    function reduceStake(uint256 _total) public {
        require(increasedStakes[msg.sender] >= _total, "Invalid amount");
        platformStakes -= _total;
        increasedStakes[msg.sender]-=_total;

        lendingPool.withdraw(linkToken, _total, msg.sender);
    }

    function _addSpecialLottery(uint256 _drawDate, uint256 _total, string memory _description) public onlyOwner whenNotPaused {
        pendingLINK += _total;

        require(IERC20(linkToken).transferFrom(msg.sender, address(this), _total), 'Transfer failed');
        lendingPool.supply(linkToken, _total, address(this), 0);

        SpecialLottery memory specialLottery;
        specialLottery.valid = true;
        specialLottery.total = _total;
        specialLottery.description = _description;
        
        specialLotteries[_drawDate] = specialLottery;

        emit NewSpecialDraw(_drawDate);
    }

    function _executeDraw(uint256 _random) internal { 
        uint256 winnerIndex = winner_index(_random);
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
        uint256 winnerIndex = winner_index(_random);
        uint256 tokenId = prizeBonds[winnerIndex];

        SpecialLottery storage lottery = specialLotteries[_specialLotDate];
        lottery.winner = tokenId;
        claimable[tokenId] += lottery.total;

        emit SpecialDrawExecuted(tokenId, _specialLotDate);
    }

    function _randomnessRequest() internal returns(uint256) {
        return COORDINATOR.requestRandomWords(
            0x06eb0e2ea7cca202fc7c8258397a36f33d88568d2522b37aaa3b14ff6ee1b696, //keyHash
            46, //s_subscriptionId
            3, //requestConfirmations
            callbackGasLimit,
            1
        );
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        if (reqToSpecialLottery[requestId] > 0) {
            _executeSpecialDraw(randomWords[0], reqToSpecialLottery[requestId]);
        } else {
            _executeDraw(randomWords[0]);
        }
    } 

    function _enableCharity(address _charity, bool _enabled) public onlyOwner {
        require(charities[_charity] != _enabled, "Already done");

        charities[_charity] = _enabled;

        if (_enabled) {
            aCharities.push(_charity);
        } else {
            bool doNow = false;
            for (uint i = 0; i<aCharities.length-1; i++){
                if (aCharities[i] == _charity) {
                    doNow = true;                    
                }
                if (doNow) {
                    aCharities[i] = aCharities[i+1];
                }
            }
            aCharities.pop();
        }
    }

    function _updateCallbackGasLimit(uint32 _callbackGasLimit) public onlyOwner {
        callbackGasLimit = _callbackGasLimit;
    }

    function _claimFees() public onlyOwner {
        uint256 linkFees = totalFees;
        totalFees = 0;

        if (linkFees > 0) {
            lendingPool.withdraw(linkToken, linkFees, msg.sender);
            pendingLINK -= linkFees;
        }
    }

    function canDraw() internal view returns (bool) {
        return block.timestamp >= getNextDrawDate() && prizeBonds.length > 0;
    }
    
    function winner_index(uint256 _random) internal view returns (uint256) {
        uint256 count= _random % sumWeights;
        uint256 i=0;
        while(count>0){
            if(count<prizeBondPositions[prizeBonds[i]].weight)
                break;
            count-=prizeBondPositions[prizeBonds[i]].weight;
            i++;
        }
        
        return i;
    }

    function getNextDrawDate() public view returns(uint256) {
        return lastDrawn + TIME_FOR_NEXT_DRAW;
    }

    function getTotalPrizeBonds() public view returns(uint256) {
        return prizeBonds.length;
    }
 
    // Amount of aTokens - the amounf of tickets*Price - the pending winner prices - the increased stake 
    function accumulatedLINK() public view returns (uint256) {
        return IERC20(aLinkToken).balanceOf(address(this)) - totalLINKBonds * PRICE * 1e18 - pendingLINK - platformStakes;
    }

    function _approveLP(address _token, uint256 _amount) public onlyOwner {
        IERC20(_token).approve(address(lendingPool), _amount);
    }
    
    function getListOfTickets() public view returns (uint256[] memory){
        return prizeBonds;
    }

    function getTicketData(uint256 tokenId) public view returns (PrizeBondPosition memory ) {
        return prizeBondPositions[tokenId];
    }

    receive() external payable {}
}
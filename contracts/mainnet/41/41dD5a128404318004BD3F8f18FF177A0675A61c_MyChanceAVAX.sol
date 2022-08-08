// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


import "./IWETHGateway.sol";
import "./IPrizeBondAVAX.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./LinkTokenInterface.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";
import "./KeeperCompatible.sol";


contract MyChanceAVAX is Ownable, VRFConsumerBaseV2, Pausable, KeeperCompatibleInterface {
    // ChainLink integration
    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;
    address constant vrfCoordinator = 0xd5D517aBE5cF79B7e95eC98dB0f0277788aFF634;
    address constant link = 0x5947BB275c521040051D82396192181b413227A3;
    uint32 callbackGasLimit = 800000;

    IPrizeBondAVAX prizeBond  = IPrizeBondAVAX(0xFD3BE6E927fBc3719d0893b94ecaeAdD526daa91);

    // AAVE & Token addresses in Avalanche
    address constant avWAVAXToken = 0xDFE521292EcE2A4f44242efBcD66Bc594CA9714B;
    IWETHGateway constant wethGateway = IWETHGateway(0x8a47F74d1eE0e2edEB4F3A7e64EF3bD8e11D27C8);
    address constant lendingPool = 0x4F01AeD16D97E3aB5ab2B501154DC9bb0F1A5A2C;
    
    uint256 constant PRICE = 1;
    uint256 constant TIME_FOR_NEXT_DRAW = 7 * 1 days;
    uint256 constant MAX_INT = 2**256 - 1;

    mapping(address => bool) charities;
    address[] aCharities;
    uint256 currentCharity = 0;

    mapping(uint256=>SpecialLottery)  specialLotteries; //Dates for Special Lotteries
    mapping(uint256=>uint256)  reqToSpecialLottery; //ReqID to Date (for Special Lottery)

    mapping(uint256 => uint256)  mintingDate;
    uint256 platformStakes;

    mapping(uint256 => uint256) public claimable;

    uint256 totalFees;

    mapping(address=>uint256) increasedStakes; // It keeps track of the staking of each user 
    uint256[] prizeBonds;

    mapping(uint256 => PrizeBondPosition)  prizeBondPositions;

    uint256 pendingAVAX;

    uint256  totalBonds;

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

    constructor() payable VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(link);

        lastDrawn = block.timestamp;

        _approveGateway(avWAVAXToken, MAX_INT);

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

    function getCurrentCharity() public returns(address) {
        return aCharities[currentCharity % (aCharities.length - 1)];
    }

     function claim(uint256 _tokenId, uint256 _percentage) public {
        require(prizeBond.ownerOf(_tokenId) == msg.sender, "Invalid owner");
        require(claimable[_tokenId] > 0, "Nothing to claim");
        require(block.timestamp > mintingDate[_tokenId] + TIME_FOR_NEXT_DRAW, "Winner has to wait a week for get the first prize");
        require(_percentage >= 5, "Minimum to donate is 5%");

        if (_percentage > 100) {
            _percentage = 100;
        }

        uint256 total = claimable[_tokenId];
        claimable[_tokenId] = 0;

        address charity = getCurrentCharity();
        currentCharity += 1;

        //Donate and substract fees

        //30% operational cost
        //20% automatic contribution to social causes
        //35% weekly prize distribution
        //15% special prize draws

        if (total > 0) {
            uint256 totalToCharity = total * 20 / 100;
            uint256 totalOfFees = total * 45 / 100;
            uint256 totalWinner = total * 35 / 100;
            uint256 extraToCharity = totalWinner * _percentage / 100;
            totalToCharity += extraToCharity;
            totalWinner -= extraToCharity;

            // Platform's fees remain in the AAVE pool
            uint256 withdrawalAmount = total - totalOfFees;
            pendingAVAX -= withdrawalAmount;

            wethGateway.withdrawETH(lendingPool, withdrawalAmount, address(this));
            if (totalWinner > 0) {
                payable(msg.sender).transfer(totalWinner);
            }

            (bool sent, bytes memory data) = charity.call{value: totalToCharity}("");
            require(sent, "Failed to send Ether");

            totalFees += totalOfFees;
        }
    }

    function howMuchToWidthdraw(uint256 _tokenId, uint256 _percentage) public view returns (uint256) {
        uint256 total = claimable[_tokenId];
        uint256 totalToCharity = total * 20 / 100;
        uint256 totalOfFees = total * 45 / 100;
        uint256 totalWinner = total * 35 / 100;
        uint256 extraToCharity = totalWinner * _percentage / 100;
        totalToCharity += extraToCharity;
        totalWinner -= extraToCharity;
        uint256 withdrawalAmount = total - totalOfFees;
        return withdrawalAmount;
    }

    function mintPrizeBond(uint weight) public payable whenNotPaused {
        require(weight > 0, "Invalid weight");

        uint256 totalValue = PRICE * weight * 1e18;
        require(msg.value == totalValue, "Invalid value");
        wethGateway.depositETH{value: msg.value }(lendingPool, address(this), 0);
        totalBonds += weight;
      
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

        uint256 weight = prizeBondPositions[_tokenId].weight;

        wethGateway.withdrawETH(lendingPool, PRICE * weight * 1e18, msg.sender);
        totalBonds -= weight;

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

    function increaseStake() public payable whenNotPaused {
        wethGateway.depositETH{value: msg.value}(lendingPool, address(this), 0);
    
        platformStakes += msg.value;
        increasedStakes[msg.sender]+= msg.value;
    }

    function reduceStake(uint256 _total) public {
        require(increasedStakes[msg.sender] >= _total, "Invalid amount");
        platformStakes -= _total;
        increasedStakes[msg.sender]-=_total;

        wethGateway.withdrawETH(lendingPool, _total, msg.sender);
    }

    function _addSpecialLottery(uint256 _drawDate, string memory _description) public payable onlyOwner whenNotPaused {
        require(msg.value > 0, "Invalid value");

        pendingAVAX += msg.value;

        wethGateway.depositETH{value: msg.value}(lendingPool, address(this), 0);

        SpecialLottery memory specialLottery;
        specialLottery.valid = true;
        specialLottery.total = msg.value;
        specialLottery.description = _description;
        
        specialLotteries[_drawDate] = specialLottery;

        emit NewSpecialDraw(_drawDate);
    }

    function _executeDraw(uint256 _random) internal { 
        uint256 winnerIndex = winner_index(_random);
        uint256 tokenId = prizeBonds[winnerIndex];

        uint256 total = accumulated();
        
        pendingAVAX += total;

        if (total > 0) 
        {
            claimable[tokenId] += total;
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
            38, //s_subscriptionId
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
        uint256 fees = totalFees;
        totalFees = 0;

        if (totalFees > 0) {
            wethGateway.withdrawETH(lendingPool, fees, msg.sender);
            pendingAVAX -= fees;
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
    function accumulated() public view returns (uint256) { 
        return IERC20(avWAVAXToken).balanceOf(address(this)) - totalBonds * PRICE * 1 ether - pendingAVAX - platformStakes;
    }

    function getStakedAmount() public view returns (uint256){
        return increasedStakes[msg.sender];
    }

    function _approveGateway(address _token, uint256 _amount) public onlyOwner {
        IERC20(_token).approve(address(wethGateway), _amount);
    }
    
    function getListOfTickets() public view returns (uint256[] memory){
        return prizeBonds;
    }

    function getTicketData(uint256 index) public view returns (PrizeBondPosition memory ) {
        return prizeBondPositions[prizeBonds[index%prizeBonds.length]];
    }

    receive() external payable {}
}
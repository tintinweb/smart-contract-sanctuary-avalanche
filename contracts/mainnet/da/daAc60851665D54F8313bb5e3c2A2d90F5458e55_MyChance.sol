// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


import './ILendingPool.sol';
import './PrizeBond.sol';
import "./Pausable.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./LinkTokenInterface.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";
import "./KeeperCompatible.sol";


contract MyChance is Ownable, PrizeBond, VRFConsumerBaseV2, Pausable, KeeperCompatibleInterface {

    // ChainLink integration
    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;
    address constant vrfCoordinator = 0xd5D517aBE5cF79B7e95eC98dB0f0277788aFF634;
    address constant link = 0x5947BB275c521040051D82396192181b413227A3;
    uint32 callbackGasLimit = 800000;

    // AAVE & Token addresses in Avalanche
    address constant daiToken = 0xd586E7F844cEa2F87f50152665BCbc2C279D8d70;
    address constant usdtToken = 0xc7198437980c041c805A1EDcbA50c1Ce5db95118;
    address constant usdcToken = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;
    address constant aDaiToken = 0x47AFa96Cdc9fAb46904A55a6ad4bf6660B53c38a;
    address constant aUsdtToken = 0x532E6537FEA298397212F09A61e03311686f548e;
    address constant aUsdcToken = 0x46A51127C3ce23fb7AB1DE06226147F446e4a857;
    ILendingPool constant lendingPool = ILendingPool(0x4F01AeD16D97E3aB5ab2B501154DC9bb0F1A5A2C);
    
    constructor() VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(link);

        _approveLP(daiToken, MAX_INT);
        _approveLP(usdtToken, MAX_INT);
        _approveLP(usdcToken, MAX_INT);

        lastDrawn = block.timestamp;

        _enableCharity(0x0B98d3b5ad68992559F9684A70310e48aE892A48, true);
        _enableCharity(0x0DdcAE532E4b1B31500Cd29d7AC110F052e30645, true);
        _enableCharity(0x74CE447d787313E4555C0D3E03C3934E0C0bDB6A, true);
        _enableCharity(0xE9bFF54D628DBe3C8C59f74ccb1aB4560a1713C0, true);
        _enableCharity(0xF8fF6e693b9B8C6A25891cC0bAB53960aac95453, true);
    }

    uint256 constant PRICE = 25; 
    uint256 constant TIME_FOR_NEXT_DRAW = 7 * 1 days;
    uint256 constant MAX_INT = 2**256 - 1;

    mapping(address => bool) public charities;
    address[] public aCharities;
    uint256 public currentCharity = 0;

    mapping(uint256=>SpecialLottery) public specialLotteries; //Dates for Special Lotteries
    mapping(uint256=>uint256) public reqToSpecialLottery; //ReqID to Date (for Special Lottery)

    mapping(uint256 => uint256) public mintingDate;
    mapping(Assets=>uint256) public platformStakes;

    mapping(uint256 => mapping(Assets=>uint256)) public claimable;

    mapping(Assets=>uint256) public totalFees;

    uint256[] public prizeBonds;
    mapping(uint256 => PrizeBondPosition) public prizeBondPositions;

    uint256 pendingDAI;
    uint256 pendingUSDT;
    uint256 pendingUSDC;

    uint256 public totalDAIBonds;
    uint256 public totalUSDTBonds;
    uint256 public totalUSDCBonds;

    uint256 lastDrawn; //Date for the last normal drawn;

    struct SpecialLottery {
        bool valid;
        bool drawn;
        Assets assetType;
        uint256 total;
        string description;
        uint256 winner;
    }

    struct PrizeBondPosition {
        uint index;
        bool exists;
    }

    //Events
    event NewSpecialDraw(uint256 _drawDate);
    event SpecialDrawExecuted(uint256 indexed _tokenIdWinner, uint256 indexed _drawDate);
    event DrawExecuted(uint256 indexed _tokenIdWinner);

    //Keepers Functions
    function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory ) {
        upkeepNeeded = canDraw();
    }

    function performUpkeep(bytes calldata) external override {
        draw();
    }

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
        require(ownerOf(_tokenId) == msg.sender, "Invalid owner");
        require(howMuchToClaim(_tokenId) > 0, "Nothing to claim");
        require(block.timestamp > mintingDate[_tokenId] + TIME_FOR_NEXT_DRAW, "Winner has to wait a week for get the first prize");
        require(_percentage >= 5, "Minimum to donate is 5%");

        if (_percentage > 100) {
            _percentage = 100;
        }

        uint256 totalDAI = claimable[_tokenId][Assets.DAI];
        claimable[_tokenId][Assets.DAI] = 0;

        uint256 totalUSDT = claimable[_tokenId][Assets.USDT];
        claimable[_tokenId][Assets.USDT] = 0;

        uint256 totalUSDC = claimable[_tokenId][Assets.USDC];
        claimable[_tokenId][Assets.USDC] = 0;

        address charity = aCharities[currentCharity % (aCharities.length - 1)];
        currentCharity += 1;

        //Donate and substract fees

        //30% operational cost
        //20% automatic contribution to social causes
        //35% weekly prize distribution
        //15% special prize draws

        if (totalDAI > 0) {
            uint256 totalToCharityDAI = totalDAI * 20 / 100;
            uint256 totalFeesDAI = totalDAI * 45 / 100;
            uint256 totalWinnerDAI = totalDAI * 35 / 100;
            uint256 extraToCharityDAI = totalWinnerDAI * _percentage / 100;
            totalToCharityDAI += extraToCharityDAI;
            totalWinnerDAI -= extraToCharityDAI;

            // Platform's fees remain in the AAVE pool
            uint256 withdrawalAmount = totalDAI - totalFeesDAI;
            pendingDAI -= withdrawalAmount;

            lendingPool.withdraw(daiToken, withdrawalAmount, address(this));
            require(IERC20(daiToken).transfer(msg.sender, totalWinnerDAI), 'Transfer failed');
            require(IERC20(daiToken).transfer(charity, totalToCharityDAI), 'Transfer failed');

            totalFees[Assets.DAI] += totalFeesDAI;
        }

        if (totalUSDT > 0) {
            uint256 totalToCharityUSDT = totalUSDT * 20 / 100;
            uint256 totalFeesUSDT = totalUSDT * 45 / 100;
            uint256 totalWinnerUSDT = totalUSDT * 35 / 100;
            uint256 extraToCharityUSDT = totalWinnerUSDT * _percentage / 100;
            totalToCharityUSDT += extraToCharityUSDT;
            totalWinnerUSDT -= extraToCharityUSDT;
            
            // Platform's fees remain in the AAVE pool
            uint256 withdrawalAmount = totalUSDT - totalFeesUSDT;
            pendingUSDT -= withdrawalAmount;

            lendingPool.withdraw(usdtToken, withdrawalAmount,address(this));
            require(IERC20(usdtToken).transfer(msg.sender, totalWinnerUSDT), 'Transfer failed');
            require(IERC20(usdtToken).transfer(charity, totalToCharityUSDT), 'Transfer failed');

            totalFees[Assets.USDT] += totalFeesUSDT;
        }

        if (totalUSDC > 0) {
            uint256 totalToCharityUSDC = totalUSDC * 20 / 100;
            uint256 totalFeesUSDC = totalUSDC * 45 / 100;
            uint256 totalWinnerUSDC = totalUSDC * 35 / 100;
            uint256 extraToCharityUSDC = totalWinnerUSDC * _percentage / 100;
            totalToCharityUSDC += extraToCharityUSDC;
            totalWinnerUSDC -= extraToCharityUSDC;

            // Platform's fees remain in the AAVE pool
            uint256 withdrawalAmount = totalUSDC - totalFeesUSDC;
            pendingUSDC -= withdrawalAmount;

            lendingPool.withdraw(usdcToken, withdrawalAmount ,address(this));
            require(IERC20(usdcToken).transfer(msg.sender, totalWinnerUSDC), 'Transfer failed');
            require(IERC20(usdcToken).transfer(charity, totalToCharityUSDC), 'Transfer failed');

            totalFees[Assets.USDC] += totalFeesUSDC;
        }
    }

    function mintPrizeBond(Assets _assetType) public whenNotPaused {
        if (_assetType == Assets.DAI) {
            require(IERC20(daiToken).transferFrom(msg.sender, address(this), PRICE * 1e18), 'Transfer failed');
            lendingPool.deposit(daiToken, PRICE * 1e18, address(this), 0);
            totalDAIBonds += 1;
        } 
        else if (_assetType == Assets.USDC) {
            require(IERC20(usdcToken).transferFrom(msg.sender, address(this), PRICE * 1e6), 'Transfer failed');
            lendingPool.deposit(usdcToken, PRICE * 1e6, address(this), 0);
            totalUSDCBonds += 1;
        }
        else if (_assetType == Assets.USDT) {
            require(IERC20(usdtToken).transferFrom(msg.sender, address(this), PRICE * 1e6), 'Transfer failed');
            lendingPool.deposit(usdtToken, PRICE * 1e6, address(this), 0);
            totalUSDTBonds += 1;
        } else {
            revert();
        }

        uint256 tokenId = safeMint(msg.sender, _assetType);
        mintingDate[tokenId] = block.timestamp;
        prizeBonds.push(tokenId);
        prizeBondPositions[tokenId].exists = true;
        prizeBondPositions[tokenId].index = prizeBonds.length - 1;
    }

    function burnPrizeBond(uint256 _tokenId) public {
        require(howMuchToClaim(_tokenId) == 0, "You must claim first");
        require(ownerOf(_tokenId) == msg.sender, "Invalid owner");

        Assets assetType = getAssetType(_tokenId);

        _burn(_tokenId);

        if (Assets(assetType) == Assets.DAI) {
            lendingPool.withdraw(daiToken, PRICE * 1e18, msg.sender);
            totalDAIBonds -= 1;
        } 
        else if (Assets(assetType) == Assets.USDC) {
            lendingPool.withdraw(usdcToken, PRICE * 1e6, msg.sender);
            totalUSDCBonds -= 1;
        }
        else if (Assets(assetType) == Assets.USDT) {
            lendingPool.withdraw(usdtToken, PRICE * 1e6, msg.sender);
            totalUSDTBonds -= 1;
        } else {
            revert();
        }
        // Updates the list of prize bonds
        if (prizeBondPositions[_tokenId].exists) {
            PrizeBondPosition memory deletedTicket = prizeBondPositions[_tokenId];
            if (deletedTicket.index != prizeBonds.length-1) {
                uint256 lastTokenId = prizeBonds[prizeBonds.length-1];
                prizeBonds[deletedTicket.index] = lastTokenId;
                prizeBondPositions[lastTokenId].index = deletedTicket.index;
            }
            delete prizeBondPositions[_tokenId];
            prizeBonds.pop();
        }
    }

    function howMuchToClaim(uint256 _tokenId) public view returns(uint256) {
        return claimable[_tokenId][Assets.DAI] + claimable[_tokenId][Assets.USDT] + claimable[_tokenId][Assets.USDC];
    }

    function getNextDrawDate() public view returns(uint256) {
        return lastDrawn + TIME_FOR_NEXT_DRAW;
    }

    function getTotalPrizeBonds() public view returns(uint256) {
        return prizeBonds.length;
    }

    function accumulatedDAI() public view returns (uint256) {
        // Amount of aDai - the price of tickets - the pending winner prices - the increased stake by the owner 
        return IERC20(aDaiToken).balanceOf(address(this)) - totalDAIBonds * PRICE * 1e18 - pendingDAI - platformStakes[Assets.DAI];
    }

    function accumulatedUSDT() public view returns (uint256) {
        return IERC20(aUsdtToken).balanceOf(address(this)) - totalUSDTBonds * PRICE * 1e6 - pendingUSDT - platformStakes[Assets.USDT];
    }

    function accumulatedUSDC() public view returns (uint256) {
        return IERC20(aUsdcToken).balanceOf(address(this)) - totalUSDCBonds * PRICE * 1e6 - pendingUSDC - platformStakes[Assets.USDC];
    }

    function canDraw() internal view returns (bool) {
        return block.timestamp >= getNextDrawDate() && prizeBonds.length > 0;
    }

    function _addSpecialLottery(uint256 _drawDate, Assets _assetType, uint256 _total, string memory _description) public onlyOwner whenNotPaused {
        address token;

        if (_assetType == Assets.DAI) {
            token = daiToken;
        } else if (_assetType == Assets.USDC) {
            token = usdcToken;
        } else if (_assetType == Assets.USDT) {
            token = usdtToken;
        } else {
            revert();
        }

        require(IERC20(token).transferFrom(msg.sender, address(this), _total), 'Transfer failed');
        lendingPool.deposit(token, _total, address(this), 0);

        SpecialLottery memory specialLottery;
        specialLottery.valid = true;
        specialLottery.assetType = _assetType;
        specialLottery.total = _total;
        specialLottery.description = _description;
        
        specialLotteries[_drawDate] = specialLottery;

        emit NewSpecialDraw(_drawDate);
    }

    function _executeDraw(uint256 _random) internal { 
        uint256 winnerIndex = _random % prizeBonds.length;
        uint256 tokenId = prizeBonds[winnerIndex];

        uint256 totalDAI = accumulatedDAI();
        uint256 totalUSDT = accumulatedUSDT();
        uint256 totalUSDC = accumulatedUSDC();

        pendingDAI += totalDAI;
        pendingUSDT += totalUSDT;
        pendingUSDC += totalUSDC;

        if (totalDAI > 0) 
        {
            claimable[tokenId][Assets.DAI] += totalDAI;
        }

        if (totalUSDT > 0) {
            claimable[tokenId][Assets.USDT] += totalUSDT;
        }

        if (totalUSDC > 0) {
            claimable[tokenId][Assets.USDC] += totalUSDC;
        }

        emit DrawExecuted(tokenId);
    }

    function _executeSpecialDraw(uint256 _random, uint256 _specialLotDate) internal {
        uint256 winnerIndex = _random % prizeBonds.length;
        uint256 tokenId = prizeBonds[winnerIndex];

        SpecialLottery storage lottery = specialLotteries[_specialLotDate];

        if (lottery.assetType == Assets.DAI) {
            pendingDAI += lottery.total;
        } 
        else if (lottery.assetType == Assets.USDC) {
            pendingUSDC += lottery.total;
        }
        else if (lottery.assetType == Assets.USDT) {
            pendingUSDT += lottery.total;
        }
        else {
            revert();
        }

        lottery.winner = tokenId;
        claimable[tokenId][lottery.assetType] += lottery.total;

        emit SpecialDrawExecuted(tokenId, _specialLotDate);
    }

    function _randomnessRequest() internal returns(uint256) {
        return COORDINATOR.requestRandomWords(
            0x06eb0e2ea7cca202fc7c8258397a36f33d88568d2522b37aaa3b14ff6ee1b696, //keyHash
            7, //s_subscriptionId
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

    function _recoverTokens(uint256 _amount, address _asset) public onlyOwner {
        require(IERC20(_asset).transfer(msg.sender, _amount), 'Transfer failed');
    }

    function _recoverAVAX(uint256 _amount) public onlyOwner {
        payable(msg.sender).transfer(_amount);
    }

    function _withdrawAndRecover(uint256 _amount, address _asset) public onlyOwner {
        lendingPool.withdraw(_asset, _amount, msg.sender);
    }

    function _updateCallbackGasLimit(uint32 _callbackGasLimit) public onlyOwner {
        callbackGasLimit = _callbackGasLimit;
    }

    function _claimFees() public onlyOwner {
        uint256 daiFees = totalFees[Assets.DAI];
        totalFees[Assets.DAI] = 0;

        uint256 usdtFees = totalFees[Assets.USDT];
        totalFees[Assets.USDT] = 0;

        uint256 usdcFees = totalFees[Assets.USDC];
        totalFees[Assets.USDC] = 0;

        if (daiFees > 0) {
            lendingPool.withdraw(daiToken, daiFees, msg.sender);
            pendingDAI-=daiFees;
        }

        if (usdtFees > 0) {
            lendingPool.withdraw(usdtToken, usdtFees, msg.sender);
            pendingUSDT-=usdtFees;
        }

        if (usdcFees > 0) {
            lendingPool.withdraw(usdcToken, usdcFees, msg.sender);
            pendingUSDC-=usdcFees;
        }
    }

    function _increaseStake(Assets _assetType, uint256 _total) public whenNotPaused onlyOwner {
        if (_assetType == Assets.DAI) {
            require(IERC20(daiToken).transferFrom(msg.sender, address(this), _total), 'Transfer failed');
            lendingPool.deposit(daiToken, _total, address(this), 0);
        } 
        else if (_assetType == Assets.USDC) {
            require(IERC20(usdcToken).transferFrom(msg.sender, address(this), _total), 'Transfer failed');
            lendingPool.deposit(usdcToken, _total, address(this), 0);
        }
        else if (_assetType == Assets.USDT){
            require(IERC20(usdtToken).transferFrom(msg.sender, address(this), _total), 'Transfer failed');
            lendingPool.deposit(usdtToken, _total, address(this), 0);
        } else {
            revert();
        }

        platformStakes[_assetType] += _total;
    }

    function _reduceStake(Assets _assetType, uint256 _total) public onlyOwner {
        require(platformStakes[_assetType] >= _total, "Invalid amount");
        platformStakes[_assetType] -= _total;

        if (_assetType == Assets.DAI) {
            lendingPool.withdraw(daiToken, _total, msg.sender);
        } 
        else if (_assetType == Assets.USDC) {
            lendingPool.withdraw(usdcToken, _total, msg.sender);
        }
        else if (_assetType == Assets.USDT) {
            lendingPool.withdraw(usdtToken, _total, msg.sender);
        } else {
            revert();
        }
    }

    function _approveLP(address _token, uint256 _amount) public onlyOwner {
        IERC20(_token).approve(address(lendingPool), _amount);
    }

    receive() external payable {}
}
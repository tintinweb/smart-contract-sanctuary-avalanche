// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;


import "./ILendingPool.sol";
import "./PrizeBond.sol";
import "./Ownable.sol";
import "./IERC20.sol";


interface IVRFOracleOraichain {
    function randomnessRequest(uint256 _seed, bytes calldata _data) external payable returns (bytes32 reqId);

    function getFee() external returns (uint256);
}

contract MyChance is Ownable, PrizeBond {
    //Token addresses in Avalanche
    address daiToken = 0xd586E7F844cEa2F87f50152665BCbc2C279D8d70;
    address usdtToken = 0xc7198437980c041c805A1EDcbA50c1Ce5db95118;
    address usdcToken = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;
    address aDaiToken = 0x47AFa96Cdc9fAb46904A55a6ad4bf6660B53c38a;
    address aUsdtToken = 0x532E6537FEA298397212F09A61e03311686f548e;
    address aUsdcToken = 0x46A51127C3ce23fb7AB1DE06226147F446e4a857;

    ILendingPool lendingPool = ILendingPool(0x4F01AeD16D97E3aB5ab2B501154DC9bb0F1A5A2C);

   //Orai variables
    address public oracle = 0x6b5866f4B9832bFF3d8aD81B1151a37393f6B7D5; //Mainnet
    bytes32  public reqId;

    uint256 public price = 5; //TODO: Change back to 25

    mapping(uint256=>SpecialLottery) public specialLotteries; //Dates for Special Lotteries
    mapping(bytes32=>uint256) public reqToSpecialLottery; //ReqID to Date (for Special Lottery)
    mapping(address => bool) public charities;
    mapping(uint256 => mapping(Assets=>uint256)) public claimable;
    mapping(uint256 => uint256) public mintingDate;

    struct SpecialLottery {
        bool valid;
        bool drawn;
        Assets assetType;
        uint256 total;
        string description;
        uint256 winner;
    }

    uint256 totalFeesDai;
    uint256 totalFeesUsdt;
    uint256 totalFeesUsdc;

    uint256[] public prizeBonds;

    uint256 totalDAIBonds;
    uint256 totalUSDTBonds;
    uint256 totalUSDCBonds;

    uint256 lastDrawn; //Date for the last normal drawn;

    //uint256 TIME_FOR_NEXT_DRAW = 7 * 1 days;
    uint256 TIME_FOR_NEXT_DRAW = 30 * 1 minutes; //TODO: Change to 7 days

    uint256 MAX_INT = 2**256 - 1;

    event NewSpecialDraw(uint256 _drawDate);
    event SpecialDrawExecuted(uint256 indexed _tokenIdWinner, uint256 indexed _drawDate);
    event DrawExecuted(uint256 indexed _tokenIdWinner);

    //TODO: Remove this
    function TEST_Update_Last_Drawn(uint256 _when) public {
        lastDrawn = _when;
    }

    constructor() {
        _approveLP(daiToken, MAX_INT);
        _approveLP(usdtToken, MAX_INT);
        _approveLP(usdcToken, MAX_INT);

        lastDrawn = block.timestamp;
    }

    function getOracleFee() public returns(uint256) {
        return IVRFOracleOraichain(oracle).getFee();
    }

    function draw() public payable {
        uint256 newDate = getNextDrawDate();
        uint256 fee = getOracleFee();
        require(block.timestamp >= newDate, "Not yet");
        require(msg.value >= fee, "Invalid value");

        lastDrawn = block.timestamp;
        _randomnessRequest(newDate, fee);
    }

    function drawSpecialLottery(uint256 _drawDate) public payable {
        uint256 fee = getOracleFee();
        require(msg.value >= fee, "Invalid value");
        SpecialLottery storage o = specialLotteries[_drawDate];
        require(o.valid, "Invalid");
        require(block.timestamp > _drawDate, "Not yet");
        require(o.drawn == false, "Already drawn");

        o.drawn = true;
        _randomnessRequest(_drawDate, fee);
        reqToSpecialLottery[reqId] = _drawDate;
    }

    function howMuchToClaim(uint256 _tokenId) public view returns(uint256) {
        return claimable[_tokenId][Assets.DAI] + claimable[_tokenId][Assets.USDT] + claimable[_tokenId][Assets.USDC];
    }

    function claim(uint256 _tokenId, address _charity, uint256 _percentage) public {
        require(ownerOf(_tokenId) == msg.sender, "Invalid owner");
        require(charities[_charity], "Invalid charity");
        require(_percentage > 5, "Minimum to donate is 5%");
        require(howMuchToClaim(_tokenId) > 0, "Nothing to claim");

        if (_percentage > 100) {
            _percentage = 100;
        }

        uint256 totalDai = claimable[_tokenId][Assets.DAI];
        claimable[_tokenId][Assets.DAI] = 0;

        uint256 totalUsdt = claimable[_tokenId][Assets.USDT];
        claimable[_tokenId][Assets.USDT] = 0;

        uint256 totalUsdc = claimable[_tokenId][Assets.USDC];
        claimable[_tokenId][Assets.USDC] = 0;

        //Donate and substract fees
        //0.35% to be used for special lotteries
        //2% is taken for operational cost

        if (totalDai > 0) {
            lendingPool.withdraw(daiToken, totalDai, address(this));
            uint256 daiCharity = totalDai * _percentage / 100;
            uint256 daiFees = (totalDai - daiCharity) * 235 / 10000;
            totalFeesDai += daiFees;
            require(IERC20(daiToken).transfer(msg.sender, totalDai - daiFees - daiCharity), 'Transfer failed');
            require(IERC20(daiToken).transfer(_charity, daiCharity), 'Transfer failed');
        }
        if (totalUsdt > 0) {
            lendingPool.withdraw(usdtToken, totalUsdt, address(this));
            uint256 usdtCharity = totalUsdt * _percentage / 100;
            uint256 usdtFees = (totalUsdt - usdtCharity) * 235 / 10000;
            totalFeesUsdt += usdtFees;
            require(IERC20(usdtToken).transfer(msg.sender, totalUsdt - usdtFees - usdtCharity), 'Transfer failed');
            require(IERC20(usdtToken).transfer(_charity, usdtCharity), 'Transfer failed');
        }
        if (totalUsdc > 0) {
            lendingPool.withdraw(usdcToken, totalUsdc, address(this));
            uint256 usdcCharity = totalUsdc * _percentage / 100;
            uint256 usdcFees = (totalUsdc - usdcCharity) * 235 / 10000;
            totalFeesUsdc += usdcFees;
            require(IERC20(usdcToken).transfer(msg.sender, totalUsdc - usdcFees - usdcCharity), 'Transfer failed');
            require(IERC20(usdcToken).transfer(_charity, usdcCharity), 'Transfer failed');
        }
    }

    function mintPrizeBond(Assets _assetType) public {
        if (_assetType == Assets.DAI) {
            require(IERC20(daiToken).transferFrom(msg.sender, address(this), price * 1e18), 'Transfer failed');
            lendingPool.deposit(daiToken, price * 1e18, address(this), 0);
            totalDAIBonds += 1;
        } 
        else if (_assetType == Assets.USDC) {
            require(IERC20(usdcToken).transferFrom(msg.sender, address(this), price * 1e6), 'Transfer failed');
            lendingPool.deposit(usdcToken, price * 1e6, address(this), 0);
            totalUSDCBonds += 1;
        }
        else {
            require(IERC20(usdtToken).transferFrom(msg.sender, address(this), price * 1e6), 'Transfer failed');
            lendingPool.deposit(usdtToken, price * 1e6, address(this), 0);
            totalUSDTBonds += 1;
        }

        uint256 tokenId = safeMint(msg.sender, _assetType);
        prizeBonds.push(tokenId);
        mintingDate[tokenId] = block.timestamp;
    }

    function burnPrizeBond(uint256 _tokenId) public {
        require(howMuchToClaim(_tokenId) > 0, "First claim");

        Assets assetType = getAssetType(_tokenId);

        _burn(_tokenId);

        if (Assets(assetType) == Assets.DAI) {
            lendingPool.withdraw(daiToken, price * 1e18, address(this));
            require(IERC20(daiToken).transfer(msg.sender, price * 1e18), 'Transfer failed');
            totalDAIBonds -= 1;
        } 
        else if (Assets(assetType) == Assets.USDC) {
            lendingPool.withdraw(usdcToken, price * 1e6, address(this));
            require(IERC20(usdcToken).transfer(msg.sender, price * 1e6), 'Transfer failed');
            totalUSDCBonds -= 1;
        }
        else {
            lendingPool.withdraw(usdtToken, price * 1e6, address(this));
            require(IERC20(usdtToken).transfer(msg.sender, price * 1e6), 'Transfer failed');
            totalUSDTBonds -= 1;
        }

        //Updates the list of prize bonds
        uint256 last = prizeBonds[prizeBonds.length - 1];
        prizeBonds.pop();
        for (uint i = 0; i < prizeBonds.length; i++) {
            if (prizeBonds[i] == _tokenId) {
                prizeBonds[i] = last;
                return;
            }
        }
    }

    function getNextDrawDate() public view returns(uint256) {
        return lastDrawn + TIME_FOR_NEXT_DRAW;
    }

    function getTotalPrizeBonds() public view returns(uint256) {
        return prizeBonds.length;
    }

    function _addSpecialLottery(uint256 _drawDate, Assets _assetType, uint256 _total, string memory _description) public onlyOwner {
        address token = usdcToken;

        if (_assetType == Assets.DAI) {
            token = daiToken;
        } 
        else if (_assetType == Assets.USDC) {
            token = usdtToken;
        }

        require(IERC20(token).transferFrom(msg.sender, address(this), _total), 'Transfer failed');
        lendingPool.deposit(token, _total, address(this), 0);

        SpecialLottery memory o;
        o.valid = true;
        o.assetType = _assetType;
        o.total = _total;
        o.description = _description;
        
        specialLotteries[_drawDate] = o;

        emit NewSpecialDraw(_drawDate);
    }

    function _executeDraw(uint256 _random) internal {
        uint256 tokenId = getWinnerPrizeBond(_random);

        uint256 totalDAI = totalDAIBonds * price * 1e18;
        uint256 totalUSDT = totalUSDTBonds * price * 1e6;
        uint256 totalUSDC = totalUSDCBonds * price * 1e6;

        totalDAI = IERC20(aDaiToken).balanceOf(address(this)) - totalDAI;
        totalUSDT = IERC20(aUsdtToken).balanceOf(address(this)) - totalUSDT;
        totalUSDC = IERC20(aUsdcToken).balanceOf(address(this)) - totalUSDC;

        claimable[tokenId][Assets.DAI] += totalDAI;
        claimable[tokenId][Assets.USDT] += totalUSDT;
        claimable[tokenId][Assets.USDC] += totalUSDC;

        emit DrawExecuted(tokenId);
    }

    function _executeSpecialDraw(uint256 _random, uint256 _specialLotDate) internal {
        uint256 tokenId = getWinnerPrizeBond(_random);

        SpecialLottery storage lottery = specialLotteries[_specialLotDate];
        lottery.winner = tokenId;

        claimable[tokenId][lottery.assetType] += lottery.total;

        emit SpecialDrawExecuted(tokenId, _specialLotDate);
    }

    function _randomnessRequest(uint256 _seed, uint256 _fee) internal {
        bytes memory data = abi.encode(address(this), this.fulfillRandomness.selector);
        reqId = IVRFOracleOraichain(oracle).randomnessRequest{value : _fee}(_seed, data);
    }

    function getWinnerPrizeBond(uint256 _random) public view returns (uint256) {
        uint256 winnerIndex = _random % prizeBonds.length;
        uint256 maxDate = block.timestamp - TIME_FOR_NEXT_DRAW;

        uint256 total = prizeBonds.length;
        while (mintingDate[winnerIndex] > maxDate && total > 0) {
            winnerIndex += 1;
            total -= 1;
            winnerIndex = _random % prizeBonds.length;
        }

        return prizeBonds[winnerIndex];
    }

    function fulfillRandomness(bytes32 _reqId, uint256 _random) external {
        //TODO: Add this back
        //require(msg.sender == oracle, "Invalid caller");

        if (reqToSpecialLottery[_reqId] > 0) {
            _executeSpecialDraw(_random, reqToSpecialLottery[_reqId]);
        } else {
            _executeDraw(_random);
        }
    }
   
    function _enableCharity(address _charity, bool _enabled) public onlyOwner {
        charities[_charity] = _enabled;
    }

    function _recoverTokens(uint256 _amount, address _asset) public onlyOwner {
        require(IERC20(_asset).transfer(msg.sender, _amount), 'Transfer failed');
    }

    function _withdrawAndRecover(uint256 _amount, address _asset) public onlyOwner {
        lendingPool.withdraw(_asset, _amount, msg.sender);
    }

    function _claimFees() public onlyOwner {
        uint256 dai = totalFeesDai;
        totalFeesDai = 0;

        uint256 usdt = totalFeesUsdt;
        totalFeesUsdt = 0;

        uint256 usdc = totalFeesUsdc;
        totalFeesUsdc = 0;

        if (dai > 0) {
            require(IERC20(daiToken).transfer(msg.sender, dai), 'Transfer failed');
        }

        if (usdt > 0) {
            require(IERC20(usdtToken).transfer(msg.sender, usdt), 'Transfer failed');
        }

        if (usdc > 0) {
           require(IERC20(usdcToken).transfer(msg.sender, usdc), 'Transfer failed');
        }
    }

    function _approveLP(address _token, uint256 _amount) public onlyOwner {
        IERC20(_token).approve(address(lendingPool), _amount);
    }

    function _recoverAVAX(uint256 _amount) public onlyOwner {
        payable(msg.sender).transfer(_amount);
    }

    receive() external payable {}
}
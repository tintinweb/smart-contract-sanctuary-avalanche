// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "./TraderJoe/IJoeRouter02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
// import "hardhat/console.sol";

interface IlpManager {
    function sellToken(uint256 tokenAmount) external;
    function buyToken(uint256 ethAmount) external payable;
}

interface INft {
    function userRarity(address, uint8) external view returns(uint32);
}

library MerkleProof {
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }
    
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}



contract HALON is ERC20Upgradeable, KeeperCompatibleInterface {
    // STRINGS
    string currentNetwork;

    // ADDRESSESS -------------------------------------------------------------------------------------------
    address public owner;
    address public airdropAddress;
    address public contractAddress;
    address public operationWallet;
    address public marketingWallet;
    address public devWallet;
    address public liquidityManager;
    address private LOCK;
    address public lpPair;
    address public swapTokenAddress;
    address public nftAddress;
    address public usdcAddress;
    // BOOLEANS ---------------------------------------------------------------------------------------------
    bool inSwap;
    bool public keepersEnabled;
    bool public tradingActive;
    bool private gasLimitActive;
    bool public transferToPoolsOnSwaps;
    bool public contractSwapEnabled;
    bool public stakingEnabled;

    // VALUES  ----------------------------------------------------------------------------------------------
    uint256 private gasPriceLimit; // 15 gWei / gWei -> Default 10
    uint256 public swapThreshold;
    uint256 private operationFee;
    uint256 private devFee;
    uint256 private liquidityFee;
    uint256 private marketingFee;
    uint256 private burnFee;
    uint256 public keeperRate;
    uint256 public rewardExtra;
    uint256 public rewardYield;
    uint256 public rewardYieldDenominator;
    uint256 MAX_INT;
    uint256 maxGasPriceLimit;
    uint256 public maxTransferAmount; // antiwhale
    uint256 swapTokensPercent;
    uint256 masterTaxDivisor;
    uint256 public bottomPrice;
    uint256 public topPrice;
    uint256 public lastBuyAmount;
    uint256 public lastSellAmount;
    uint256 public dfDecimals;
    uint256 antiWhaleUsdtLimit1;
    uint256 antiWhaleUsdtLimit2;
    uint256 antiWhaleUsdtLimit3;
    uint32 antiWhaleUsdtLimit1Percent;
    uint32 antiWhaleUsdtLimit2Percent;
    uint32 antiWhaleUsdtLimit3Percent;
    uint32 public minExtraDays;
    uint32 public maxExtraDays;
    
    uint256 public totalLocked;
    uint256 public totalRewarded;
    uint32 public totalLockedHolders;
    

    bytes32 public merkleRoot;
    uint256 public dailyExtraRate;
    // MAPPINGS
    mapping(address => bool) public _isBlacklisted;
    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => bool) public _isExcludedFromFee;
    mapping(address => bool) public usersAirdrop; //  hold last Transfers during launch
    mapping(address => uint32) lockedTime;
    mapping(address => uint256) lockedAmount;
    mapping(uint8 => uint256) public rewardRatePerDay;
    mapping(address => bool) public claimed;
    mapping(address => LockInfo[]) public lockHistory;
    mapping(address => uint32) lastHoldTime;

    // EVENTS -----------------------------------------------------------------------------------------------
    event OwnershipTransferred( address indexed previousOwner, address indexed newOwner );
    event ContractSwapEnabledUpdated(bool enabled);
    event AutoLiquify(uint256 amount, uint256 amountAVAX);
    event TransferedToPool(address, uint256);
    event SwapAndLiquify(uint256, uint256, uint256);
    event uniswapRouterUpdated(address, address);
    event uniswapV2PairUpdated(address, address, address);
    event LiquidityAdded(uint256, uint256);
    event Burn(address indexed sender, uint256 amount);
    event Unlocked(address, uint256);
    event AutoStakingReward(address, uint256);
    event Locked(address, uint256);
    event Claimed(address, uint256);
    event MerkleRootChanged(bytes32);
    // STRUCTS ----------------------------------------------------------------------------------------------
    struct BuyFees {
        uint16 operation;
        uint16 dev;
        uint16 liquidity;
        uint16 marketing;
        uint16 burn;
    }

    struct SellFees {
        uint16 operation;
        uint16 dev;
        uint16 liquidity;
        uint16 marketing;
        uint16 burn;
    }

    struct LockInfo {
        uint32 locked;      // timestamp of lock
        uint32 unlocked;    // timestamp of unlock
        uint32 duration;    // duration of lock
        uint256 amount;
    }

    // OBJECTS ----------------------------------------------------------------------------------------------
    IJoeRouter02 public dexRouter;
    BuyFees public _buyTaxRates;
    SellFees public _sellTaxRates;
    // ------------------------------------------------------------------------------------------------------

    // MODIFIERS --------------------------------------------------------------------------------------------
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    // CONSTRUCTOR ------------------------------------------------------------------------------------------
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() public virtual initializer {
        __ERC20_init("HALON", "HLN");
        
        contractAddress = address(this);
        owner = msg.sender;
        operationWallet = 0xcC9eA23fFca136F2a0925d4DeE6a38B8d1EDbcC3;
        marketingWallet = 0xbF97E1a0E297f34Ff83Eb9e1a6F0214C810F5D6f;
        devWallet = 0x5A0FfeF3ee00c65ab8503177cC856067AE1109e9;

        

        _buyTaxRates = BuyFees({operation: 0, dev: 0, liquidity: 0, marketing: 0, burn: 0});
        _sellTaxRates = SellFees({operation: 400, dev: 600, liquidity: 200, marketing: 600, burn: 200});
        masterTaxDivisor = 10000;

        tradingActive = false;
        gasLimitActive = false;
        keepersEnabled = false;
        gasPriceLimit = 15000000000;
        LOCK = 0x9d23C4e94f73bE1b940C0386b17A5f1e63fDD766;
        usdcAddress = 0x0000000000000000000000000000000000000000;
        airdropAddress = 0x7B4285bE2838a34aC346d4A3ccFb95dD1350C024;

        // exclude from fee
        _isExcludedFromFee[owner] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[airdropAddress] = true;

        rewardYield = 1500; // 15%
        rewardYieldDenominator = 3650000;
        dailyExtraRate = 10; // 0.1%

        contractSwapEnabled = true;
        swapThreshold = 1000 ether;
        maxTransferAmount = 1000 ether;
        maxGasPriceLimit = 15000000000;
        swapTokensPercent = 50;
        keeperRate = 50;
        bottomPrice = 10 ether;
        topPrice = 11 ether;
        dfDecimals = 1e12;
        minExtraDays = 7;
        maxExtraDays = 365;
        setRewardRatePerDay(0, 1500);
        setRewardRatePerDay(1, 1600);
        setRewardRatePerDay(2, 1700);
        setRewardRatePerDay(3, 1800);
        setRewardRatePerDay(4, 1900);
        setRewardRatePerDay(5, 2000);

        antiWhaleUsdtLimit1 = 1500 ether;
        antiWhaleUsdtLimit2 = 2000 ether;
        antiWhaleUsdtLimit3 = 4000 ether;
        antiWhaleUsdtLimit1Percent = 25;
        antiWhaleUsdtLimit2Percent = 50;
        antiWhaleUsdtLimit3Percent = 75;

        MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        transferToPoolsOnSwaps = true;

        address currentRouter = 0xd7f655E3376cE2D7A2b08fF01Eb3B1023191A901; //  testnet
        // address currentRouter = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4; // mainnet
        // address currentRouter = 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9; // local
        dexRouter = IJoeRouter02(currentRouter);
        swapTokenAddress = dexRouter.WAVAX();
        lpPair = IUniswapV2Factory(dexRouter.factory()).createPair(address(this), swapTokenAddress);
        setAutomatedMarketMakerPair(lpPair, true);

        _mint(msg.sender, 10000000e18);
        // _mint(airdropAddress, 3000000e18);
        // _mint(LOCK, 1000000e18);
    }

    // To receive BNB from dexRouter when swapping
    receive() external payable virtual {}

    function transferOwnership(address account) public virtual onlyOwner {
        owner = account;
    }


    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        
        merkleRoot = _merkleRoot;
        emit MerkleRootChanged(_merkleRoot);
    }

    function claimTokens(uint256 amount, bytes32[] calldata merkleProof) public {
        require(tradingActive, "Trading not yet enabled!");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        bool valid = MerkleProof.verify(merkleProof, merkleRoot, leaf);
        require(valid, "Token: Valid proof required.");
        require(!claimed[msg.sender], "Token: Tokens already claimed.");
        claimed[msg.sender] = true;
    
        emit Claimed(msg.sender, amount);
        lastHoldTime[msg.sender] = uint32(block.timestamp);
        super._transfer(airdropAddress, msg.sender, amount);
    }

    function claimAutoStakingReward() public {
        uint256 power = 0;
        uint256 one = 1 ether;
        uint256 calcRewardExtra = rewardRatePerDay[0];
        uint256 multiplier = one * calcRewardExtra / rewardYieldDenominator;
        uint32 duration = (uint32(block.timestamp) - lastHoldTime[msg.sender]) / 86400;

        power = duration * multiplier;
        
        uint256 extra = rewardsAccumlated(msg.sender);

        lastHoldTime[msg.sender] = uint32(block.timestamp);
        super._transfer(LOCK, msg.sender, extra);
        emit AutoStakingReward(msg.sender, extra);
    }

    function rewardsAccumlated(address _account) public view returns(uint256){
        uint256 power = 0;
        uint256 one = 1 ether;
        uint256 calcRewardExtra = rewardRatePerDay[0];
        uint256 multiplier = one * calcRewardExtra / rewardYieldDenominator;
        uint32 duration = (uint32(block.timestamp) - lastHoldTime[_account]) / 86400;

        power = duration * multiplier;
        
        return balanceOf(_account) * power / one;
    }
    
    function lock(uint32 _days, uint256 _amount) public {
        require(_days>=minExtraDays, "Lock: DAYS must be larger than MinExtraDays.");
        require(_days<=maxExtraDays, "Lock: DAYS must be small than MaxExtraDays.");
        LockInfo[] storage history = lockHistory[msg.sender];
        totalLocked += _amount;
        if(locking(msg.sender, true).length==0)
            totalLockedHolders++;
        history.push(LockInfo({
            locked: uint32(block.timestamp),
            unlocked: 0,
            duration: _days * 1 days,
            amount: _amount
        }));
        
        super._transfer(msg.sender, LOCK, _amount);
        emit Locked(msg.sender, _amount);
    }


    function unlock(uint32 _index) public {
        require(lockHistory[msg.sender].length>_index, "Unlock: Cannot find.");
        LockInfo storage info = lockHistory[msg.sender][_index];
        require(info.amount>0, "Unlock: Cannot find.");
        require(info.unlocked==0, "Unlock: Already unlocked.");
        require(info.locked+info.duration<=block.timestamp, "Unlock: Pending.");
        info.unlocked = uint32(block.timestamp);
        uint256 duration = info.duration / 1 days;
        uint256 power = 0;
        uint256 one = 1 ether;
        uint256 calcRewardExtra = calcRewards(msg.sender);
        uint256 multiplier = one * (calcRewardExtra + (duration - 6) * dailyExtraRate) / rewardYieldDenominator;
        
        power = duration * multiplier;
        uint256 extra = info.amount * power / one;
        totalLocked -= info.amount;
        totalRewarded += extra;
        if(locking(msg.sender, true).length==0)
            totalLockedHolders--;

        lastHoldTime[msg.sender] = uint32(block.timestamp);
        super._transfer(LOCK, msg.sender, info.amount + extra);
        emit Unlocked(msg.sender, info.amount + extra);
    }


    function calcRewards(address _account) public view returns(uint256){
        uint256 rewardAmountPerDay = 0;
        if(nftAddress!=address(0x0)){
            if(INft(nftAddress).userRarity(_account, 0) > 0){
                rewardAmountPerDay = rewardRatePerDay[1];
            }else if(INft(nftAddress).userRarity(_account, 1) > 0){
                rewardAmountPerDay = rewardRatePerDay[2];
            }else if(INft(nftAddress).userRarity(_account, 2) > 0){
                rewardAmountPerDay = rewardRatePerDay[3];
            }else if(INft(nftAddress).userRarity(_account, 3) > 0){
                rewardAmountPerDay = rewardRatePerDay[4];
            }else if(INft(nftAddress).userRarity(_account, 4) > 0){
                rewardAmountPerDay = rewardRatePerDay[5];
            } else 
                rewardAmountPerDay = rewardRatePerDay[0];
        }else
            rewardAmountPerDay = rewardRatePerDay[0];
        
        return rewardAmountPerDay;
    }

    function locking(address _account, bool _pending) public view returns (LockInfo[] memory) {
        if(_pending) {
            uint256 count = 0;
            for(uint256 i = 0;i<lockHistory[_account].length;i++) {
                LockInfo storage info = lockHistory[_account][i];
                if(info.unlocked==0) count++;
            }
            LockInfo[] memory history = new LockInfo[](count);
            uint256 j = 0;
            for(uint256 i = 0;i<lockHistory[_account].length;i++) {
                LockInfo storage info = lockHistory[_account][i];
                if(info.unlocked==0) history[j++] = info;
            }
            return history;
        }
        return lockHistory[_account];
    }

    function _beforeTransferCheck( address from, address to, uint256 amount ) internal virtual 
    {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!_isBlacklisted[msg.sender], "Blacklisted");

        if (_hasLimits(from, to)) {
            if (!tradingActive) {
                revert("Trading not yet enabled!");
            }
        }

        // only use to prevent sniper buys in the first blocks.
        if (gasLimitActive) {
            require(
                tx.gasprice <= maxGasPriceLimit,
                "Gas price exceeds limit."
            );
        }

        // antiwhale
        if(!_isExcludedFromFee[from] && maxTransferAmount > 0 && automatedMarketMakerPairs[to]) {
            require(amount <= maxTransferAmount, 'Anti whale' );
        }
    }

    function _transfer( address from, address to, uint256 amount ) internal virtual override {
        _beforeTransferCheck(from, to, amount);
        if (inSwap || address(liquidityManager) == from || address(liquidityManager) == to) {
            super._transfer(from, to, amount);
            return;
        }
        
        if (contractMustSwap(from, to)) {
            contractSwap();
        }

        _finalizeTransfer(from, to, amount);
    }

    function contractMustSwap(address from, address to) internal view virtual returns (bool)
    {
        uint256 contractTokenBalance = balanceOf(contractAddress);
        return
            contractTokenBalance >= swapThreshold &&
            !inSwap &&
            from != lpPair &&
            balanceOf(lpPair) > 0 &&
            !_isExcludedFromFee[to] &&
            !_isExcludedFromFee[from] &&
            contractSwapEnabled;
    }

    function contractSwap() internal virtual swapping {
        super._burn(address(this),burnFee);

        uint256 halfLiquidityFee = liquidityFee / 2;
        uint256 totalFee = operationFee + devFee + marketingFee + liquidityFee;
        uint256 contractTokenBalance = balanceOf(address(this));

        uint256 liquidityTokenBalance = contractTokenBalance * halfLiquidityFee / totalFee;
        swapTokensForAVAX(address(this), contractTokenBalance - liquidityTokenBalance);

        uint256 AVAXBalance = address(this).balance;

        payable(operationWallet).transfer(AVAXBalance * operationFee / totalFee);
        payable(devWallet).transfer(AVAXBalance * devFee / totalFee);
        payable(marketingWallet).transfer(AVAXBalance * marketingFee / totalFee);

        addLiquidity(liquidityTokenBalance, address(this).balance);
        // initialize params
        operationFee = 0;
        devFee = 0;
        marketingFee = 0;
        burnFee = 0;
        liquidityFee = 0;
    }

    function swapTokensForAVAX(address to, uint256 tokenAmount) private
    {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = swapTokenAddress;
        _approve(address(this), address(dexRouter), tokenAmount);
        dexRouter.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of AVAX
            path,
            to,
            block.timestamp + 600
        );
    }
    

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(dexRouter), tokenAmount);
        
        // add the liquidity
        dexRouter.addLiquidityAVAX{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner,
            block.timestamp
        );
        emit LiquidityAdded(tokenAmount, ethAmount);
    }

    function _finalizeTransfer( address from, address to, uint256 amount ) internal virtual {
        uint256 feeAmount = 0;
        bool takeFee = true;
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        if (takeFee) {
            // BUY
            if (automatedMarketMakerPairs[from]) {
                operationFee += amount * _buyTaxRates.operation / masterTaxDivisor;
                devFee += amount * _buyTaxRates.dev / masterTaxDivisor;
                liquidityFee += amount * _buyTaxRates.liquidity / masterTaxDivisor;
                marketingFee += amount * _buyTaxRates.marketing / masterTaxDivisor;
                burnFee += amount * _buyTaxRates.burn / masterTaxDivisor;
                feeAmount = (_buyTaxRates.operation + _buyTaxRates.dev + _buyTaxRates.liquidity + _buyTaxRates.marketing + _buyTaxRates.burn) * amount / masterTaxDivisor;
                if(getAmountOut() > topPrice)
                    lastBuyAmount = amount;

                
            }
            // SELL
            // if user are selling, we check if sell amount hits antiwhale limit threshold
            else if (automatedMarketMakerPairs[to]) {
                uint32 feePercent = _sellTaxRates.operation + _sellTaxRates.dev + _sellTaxRates.liquidity + _sellTaxRates.marketing + _sellTaxRates.burn;
                uint32 dynamicTaxRate = calculateWhaleFeePercent(amount);
                operationFee += amount * _sellTaxRates.operation * dynamicTaxRate / feePercent / masterTaxDivisor;
                devFee += amount * _sellTaxRates.dev * dynamicTaxRate / feePercent / masterTaxDivisor;
                liquidityFee += amount * _sellTaxRates.liquidity * dynamicTaxRate / feePercent / masterTaxDivisor;
                marketingFee += amount * _sellTaxRates.marketing * dynamicTaxRate / feePercent / masterTaxDivisor;
                burnFee += amount * _sellTaxRates.burn * dynamicTaxRate / feePercent / masterTaxDivisor;
                feeAmount = (_sellTaxRates.operation + _sellTaxRates.dev + _sellTaxRates.liquidity + _sellTaxRates.marketing + _sellTaxRates.burn) * amount * dynamicTaxRate / feePercent / masterTaxDivisor;
                if(getAmountOut() < bottomPrice)
                    lastSellAmount = amount;
            }
        }
        amount -= feeAmount;
        // transfer fee
        if(feeAmount > 0)
            super._transfer(from, address(this), feeAmount);
        if (!automatedMarketMakerPairs[to]) 
            lastHoldTime[to] = uint32(block.timestamp);
        // transfer token
        super._transfer(from, to, amount);

    }

    function calculateWhaleFeePercent(uint256 amount) public view virtual returns (uint32)
    {
        uint32 feePercent = _sellTaxRates.operation + _sellTaxRates.dev + _sellTaxRates.liquidity + _sellTaxRates.marketing + _sellTaxRates.burn;

        if (antiWhaleUsdtLimit1 > 0) {
            uint256 usdtAmount = getAmountOutUSD(amount);
            if (usdtAmount > antiWhaleUsdtLimit3) {
                feePercent = antiWhaleUsdtLimit3Percent;
            } else if (usdtAmount > antiWhaleUsdtLimit2) {
                feePercent = antiWhaleUsdtLimit2Percent;
            } else if (usdtAmount > antiWhaleUsdtLimit1) {
                feePercent = antiWhaleUsdtLimit1Percent;
            }
        }

        return feePercent;
    }

    function getAmountOutUSD(uint256 _amount) public view returns (uint256)
    {
        address[] memory path = new address[](3);
        if (address(dexRouter) == address(0)) return 0;
        path[0] = address(this);
        path[1] = dexRouter.WAVAX();
        path[2] = usdcAddress;
        uint256[] memory amountsOut = dexRouter.getAmountsOut(
            _amount,
            path
        );

        return amountsOut[2] * dfDecimals;
    }

    function updateTransferToPoolsOnSwaps(bool newValue) external virtual onlyOwner
    {
        transferToPoolsOnSwaps = newValue;
    }

    function updateGasLimitActive(bool newValue) external virtual onlyOwner {
        gasLimitActive = newValue;
    }

    function updateMaxGasPriceLimit(uint256 newValue) external  virtual onlyOwner
    {
        maxGasPriceLimit = newValue;
    }

    function _hasLimits(address from, address to) private view returns (bool) {
        return
            from != owner &&
            to != owner &&
            tx.origin != owner &&
            to != address(0) &&
            from != address(this);
    }

    // enable trading (swap) and set initial block
    function enableTrading(bool value) public virtual onlyOwner {
        tradingActive = value;
    }

    function enableStaking(bool value) public onlyOwner {
        stakingEnabled = value;
    }

    function setNftAddress(address _address) public onlyOwner {
        nftAddress = _address;
    }

    function setUSDCAddress(address _address) public onlyOwner {
        usdcAddress = _address;
    }

    function setUSDCDecimals(uint256 _value) public onlyOwner{
        dfDecimals = _value;
    }

    function setOperationWallet(address _address) public onlyOwner {
        operationWallet = _address;
    }

    function setMarketingWallet(address _address) public onlyOwner {
        marketingWallet = _address;
    }

    function setDevWallet(address _address) public onlyOwner {
        devWallet = _address;
    }

    function setRewardRatePerDay(uint8 _rarityId, uint256 _rate) public onlyOwner{
        require(_rarityId <= 5, "NFT rarityId must be less than 5");
        require(_rate < 10000, "Reward rate cannot greater than 100%");
        rewardRatePerDay[_rarityId] = _rate;
    }

    function setDailyExtraRate(uint256 _rate) public onlyOwner{
        require(_rate < 1000, "Cant greater than 100% ");
        dailyExtraRate = _rate;
    }

    function setBuyTaxes( uint16 operation, uint16 dev, uint16 liquidity, uint16 marketing, uint16 burn ) external virtual onlyOwner {
        _buyTaxRates.operation = operation;
        _buyTaxRates.dev = dev;
        _buyTaxRates.liquidity = liquidity;
        _buyTaxRates.marketing = marketing;
        _buyTaxRates.burn = burn;
    }

    function setSellTaxes( uint16 operation, uint16 dev, uint16 liquidity, uint16 marketing, uint16 burn ) external virtual onlyOwner {
        _sellTaxRates.operation = operation;
        _sellTaxRates.dev = dev;
        _sellTaxRates.liquidity = liquidity;
        _sellTaxRates.marketing = marketing;
        _sellTaxRates.burn = burn;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public virtual onlyOwner
    {
        lpPair = pair;
        automatedMarketMakerPairs[pair] = value;
    }

    function setLPManager(address account) public virtual onlyOwner {
        liquidityManager = account;
    }

    function excludeFromFee(address account, bool val) public virtual  onlyOwner
    {
        _isExcludedFromFee[account] = val;
    }

    function setSwapThreshold(uint256 value) public virtual onlyOwner {
        swapThreshold = value;
    }

    function setMaxTransferAmount(uint256 value) public onlyOwner {
        maxTransferAmount = value;
    }

    function setPairAddress(address add1) public virtual onlyOwner {
        lpPair = add1;
        automatedMarketMakerPairs[add1] = true;
        emit uniswapV2PairUpdated(msg.sender, address(dexRouter), add1);
    }

    function setAddressInBlacklist(address walletAddress, bool value) public virtual onlyOwner
    {
        _isBlacklisted[walletAddress] = value;
    }

    function setBottomPrice(uint256 value) public onlyOwner 
    {
        bottomPrice = value;
    }

    function setTopPrice(uint256 value) public onlyOwner
    {
        topPrice = value;
    }

    function isTransferBetweenWallets(address from, address to) internal view returns (bool)
    {
        return from != lpPair && to != lpPair;
    }

    function updateSwapTokensPercent(uint256 _swapTokensPercent) external virtual onlyOwner
    {
        swapTokensPercent = _swapTokensPercent;
    }

    function updatePriceLimit(
        uint256 value1,
        uint32 percent1,
        uint256 value2,
        uint32 percent2,
        uint256 value3,
        uint32 percent3
    ) public virtual onlyOwner {
        antiWhaleUsdtLimit1 = value1;
        antiWhaleUsdtLimit1Percent = percent1;

        antiWhaleUsdtLimit2 = value2;
        antiWhaleUsdtLimit2Percent = percent2;

        antiWhaleUsdtLimit3 = value3;
        antiWhaleUsdtLimit3Percent = percent3;
    }

    function setContractSwapSettings(bool _enabled) external virtual onlyOwner {
        contractSwapEnabled = _enabled;
    }

    function getAmountOut() public view returns (uint256) 
    {
        if (address(dexRouter) == address(0)) return 0;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WAVAX();
        uint256[] memory amountsOut = dexRouter.getAmountsOut(1e18, path);
        return amountsOut[1];
    }

    function setkeepersEnabled(bool val) public onlyOwner {
        keepersEnabled = val;
    }

    function setKeeperRate(uint256 _value) public onlyOwner {
        require(_value < 100, "Cannot greater than 100!");
        keeperRate = _value;
    }

    function checkUpkeep( bytes calldata /* checkData */ ) external view override returns ( bool upkeepNeeded, bytes memory /* performData */ )
    {
        upkeepNeeded = getAmountOut() < bottomPrice || getAmountOut() > topPrice;
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }

    function performUpkeep( bytes calldata /* performData */ ) external override 
    {
        //We highly recommend revalidating the upkeep in the performUpkeep function
        if ( keepersEnabled) {
            
            if( getAmountOut() < bottomPrice ){
                IlpManager(liquidityManager).buyToken(lastSellAmount * keeperRate / 100);
                uint256 tokenPrice = getAmountOut();
                if(tokenPrice < bottomPrice){
                    topPrice = tokenPrice * 11/10; 
                    bottomPrice = tokenPrice;
                }
                    
            }
                
            if( getAmountOut() > topPrice ) {
                IlpManager(liquidityManager).sellToken(lastBuyAmount * keeperRate / 100);  
                uint256 tokenPrice = getAmountOut();
                if(tokenPrice > topPrice){
                    bottomPrice = tokenPrice * 10 / 11; 
                    topPrice = tokenPrice;
                }
                    
            }
                         
        }
        // We don't use the performData in this example. The performData is generated by the Keeper's call to your checkUpkeep function
    }

    function withdrawCurrenyAndToken(address _tokenAddress, uint256 amount) public onlyOwner{
        if(_tokenAddress==address(0)){
            if(address(this).balance<amount)
                amount = address(this).balance;
            payable(owner).transfer(amount);
        }else{
            if(IERC20(_tokenAddress).balanceOf(address(this)) < amount)
                amount = IERC20(_tokenAddress).balanceOf(address(this));
            IERC20(_tokenAddress).transferFrom(address(this), owner, amount);
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./IJoeRouter01.sol";

interface IJoeRouter02 is IJoeRouter01 {
    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountAVAX);

    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
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

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./KeeperBase.sol";
import "./interfaces/KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IJoeRouter01 {
    function factory() external pure returns (address);

    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
    external
    returns (
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
    external
    payable
    returns (
        uint256 amountToken,
        uint256 amountETH,
        uint256 liquidity
    );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAX(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAXWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactAVAX(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapAVAXForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KeeperBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}
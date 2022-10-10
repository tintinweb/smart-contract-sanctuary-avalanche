// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../../integrations/gmx/IVault.sol";
import "../../integrations/gmx/IRewardRouterV2.sol";
import "../../integrations/gmx/IGlpManager.sol";
import "./Guarded.sol";

interface IERC20 {
    function name() external returns (string memory);
    function symbol() external returns (string memory);
    function decimals() external returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external returns (uint256 remaining);
}

 /**
  * @author DeCommas team
  * @title GMX DEX interface
  */
contract GmxVaultStage is Guarded {

    IVault public gmxVault;
    IRewardRouterV2 public rewardRouter;
    IGlpManager public glpManager;
    address public glpToken;
    address public stakedGlpTrackerToken;
    uint256 public constant PRICE_PRECISION = 10 ** 30;
    uint256 public constant USDG_DECIMALS = 18;
    address public owner;
    
    // asset => depositor => balance
    mapping(address => mapping(address => uint256)) private _deposits;
    
    event DepositEvent(address depositor, address baseAsset, uint256 amount);
    event BuyingEvent(address _token,uint256 _amount,uint256 glpAmountReceived);
    event SellingEvent(address _receiver, uint256 _glpAmount,address _tokenOut,uint256 _amountReceived);
    
    modifier onlyOwner(){
        require(msg.sender == owner, "OnlyOwner");
        _;
    }
    constructor(){ owner = msg.sender;}

    function initialize (
        IVault gmxVault_,
        IRewardRouterV2 rewardRouter_
    ) external onlyOwner {
        __RelyOnSender();
        gmxVault = IVault(gmxVault_);
        rewardRouter = IRewardRouterV2(rewardRouter_);
        glpManager = IGlpManager(rewardRouter.glpManager());
        glpToken = rewardRouter.glp();
        stakedGlpTrackerToken = rewardRouter.stakedGlpTracker();
    }

    function deposit(
        address baseAsset,
        uint256 amount,
        address depositor
    ) external payable {
        if (baseAsset == address(0x0)) {
            require(
                msg.value == amount,
                "GMX BB: message value mismatch amount"
            );
        } else {
            require(
                IERC20(baseAsset).transferFrom(
                    depositor,
                    address(this),
                    amount
                ),
                "GMX BB: Desposit transfer failed"
            );
        }
        emit DepositEvent(depositor, baseAsset, amount);
    }

    /**
    * @notice buy GLP, mint and stake
    * @dev _token : the token to buy GLP with
    * @dev _amount : the amount of token to use for the purchase
    * @dev _minUsdg : the minimum acceptable USD value of the GLP purchased // do we calculate on chain or off?
    * @dev _minGlp : the minimum acceptable GLP amount
    * @dev Rewards router and GLP manager spent must be approved before
    * @dev stakedGlpTrackerToken is 1:1 ratio with glp token
    * @dev send address Zero to buy with native currency
    * @return glpBoughtAmount bought amount
    * */
    function buyGLP(address _token, uint256 _amount, uint256 _minUsdg, uint256 _minGlp) external auth returns(uint256 glpBoughtAmount){
    if (_token == address(0x0)) {
        require(address(this).balance >= _amount,"GMX BB: Bridge or deposit native currency");
        glpBoughtAmount = rewardRouter.mintAndStakeGlpETH{value: _amount}(_minUsdg, _minGlp);
    }else{
        require(_amount > 0,"GMX BB: Zero amount");

        // check for balance to buy with
        require(IERC20(_token).balanceOf(address(this)) >= _amount,"GMX BB: Bridge or deposit assets.");

        // approve to void contracts is necessary
        IERC20(_token).approve(address(rewardRouter), _amount);
        IERC20(_token).approve(address(glpManager), _amount);

        // get glp balance after buying
        uint256 glpBalanceBefore = IERC20(stakedGlpTrackerToken).balanceOf(address(this));

        // buy glp
        glpBoughtAmount = rewardRouter.mintAndStakeGlp(
            _token, // the token to buy GLP with
            _amount, // the amount of token to use for the purchase
            _minUsdg, // the minimum acceptable USD value of the GLP purchased
            _minGlp  // minimum acceptable GLP amount
        );

        // check glp balance after buying
        uint256 glpBalanceAfter = IERC20(stakedGlpTrackerToken).balanceOf(address(this));

        // get glp balance change after buy
        uint256 _balanceChange = glpBalanceAfter - glpBalanceBefore;

        // check if contract balance reflects the buying
        require(_balanceChange >= glpBoughtAmount, "GMX BB: Glp buying failed. ");
    }

        emit BuyingEvent(_token,_amount,glpBoughtAmount);
        return glpBoughtAmount;
    }

    /**
    *   @notice Sell / unstake and redeem GLP
    *   @dev _tokenOut : the token to sell GLP for
    *   @dev _glpAmount : the amount of GLP to sell
    *   @dev _minOut : the minimum acceptable amount of tokenOut to be received
    *   @return _amountPayed payed for the sell
    * */
    function sellGLP(address _tokenOut, uint256 _glpAmount, uint256 _minOut) external auth returns (uint256 _amountPayed){
       if(_tokenOut == address(0x0)){
            _amountPayed = rewardRouter.unstakeAndRedeemGlpETH(_glpAmount, _minOut, payable(address(this)));
       }else{
            // get contract balance before selling
            uint256 _tokenOutBalanceBefore = IERC20(_tokenOut).balanceOf(address(this));

            // sell glp
            _amountPayed = rewardRouter.unstakeAndRedeemGlp(_tokenOut, _glpAmount, _minOut,address(this));

            // get contract balance after selling
            uint256 _tokenOutBalanceAfter = IERC20(_tokenOut).balanceOf(address(this));

            // get balance change
            uint256 _balanceChange = _tokenOutBalanceAfter - _tokenOutBalanceBefore;

            // check if vault balance reflects the sale
            require(_balanceChange >=_amountPayed, "GMX BB: Glp buying failed. ");
       }

        emit SellingEvent(msg.sender, _glpAmount, _tokenOut,_amountPayed);
        return _amountPayed;
    }

    function withdraw(address _token, uint256 _amount, address payable _receiver) external auth returns(bool){
        if(_token == address(0x0)){
            require(address(this).balance >= _amount, "GMX BB: Insufficient funds");
            address(_receiver).call{value:_amount}("");
        }else{
            require(IERC20(_token).balanceOf(address(this)) >= _amount, "GMX BB: Insufficient funds");
            require(IERC20(_token).transfer(_receiver,_amount),"GMX BB: Withdraw failed");
        }
    }

    /**
     *  @notice Trigger rewards compounding and claims them
     *  @dev _shouldClaimGmx boolean yes/no
     *  @dev _shouldStakeGmx boolean yes/no
     *  @dev _shouldClaimEsGmx boolean yes/no
     *  @dev _shouldStakeEsGmx boolean yes/no
     *  @dev _shouldStakeMultiplierPoints boolean yes/no
     *  @dev _shouldClaimWeth boolean yes/no
     *  @dev _shouldConvertWethToEth boolean yes/no
     *  @dev 15 avrg min cooldown time
     */
    function claimRewards(
        bool _shouldClaimGmx,
        bool _shouldStakeGmx,
        bool _shouldClaimEsGmx,
        bool _shouldStakeEsGmx,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWeth,
        bool _shouldConvertWethToEth
    ) external auth returns(bool){
            rewardRouter.handleRewards(
                    _shouldClaimGmx,
                    _shouldStakeGmx,
                    _shouldClaimEsGmx,
                    _shouldStakeEsGmx,
                    _shouldStakeMultiplierPoints,
                    _shouldClaimWeth,
                    _shouldConvertWethToEth
                );
            return true;
    }

    function getTvl() public returns(uint256){
        uint256 glpPrie = glpManager.getAum(true) / IERC20(glpToken).totalSupply();
        uint256 fsGlpAmount = IERC20(stakedGlpTrackerToken).balanceOf(address(this));
        return fsGlpAmount * glpPrie;
    }
    /*
        getAUms USG
        glp total supply
     */

    /**
    * @notice Get the list of tokens with addresses
    */
    function usdgAmounts(address _token) public view returns (uint256){
        return gmxVault.usdgAmounts(_token);
    }
    /**
     * @notice Get GLP price depending on opened positions
     * @param _maximize: 
     * @dev Due to possible spread on token price:
     * @dev true returns the maximum worth of tokens at that point in time.
     * @dev false returns the minimum worth.
     * @dev true for buyingPrice & false for selling price
     */
    function getGlpPrice(bool _maximize) public view returns(uint256){
        return glpManager.getAum(_maximize) / IERC20(glpManager.glp()).totalSupply();
    }

   function globalShortAveragePrices(address _token) public view returns(uint256){
        return gmxVault.globalShortAveragePrices(_token) / 1e12;
    }

    /**
     * @notice retrieve the reserved amount of token in vault
     */
    function getReservedAmounts(address _asset) public view returns(uint256){
        return gmxVault.reservedAmounts(_asset);
    }

    function getGLPBalance() public view returns(uint256){
        return IERC20(stakedGlpTrackerToken).balanceOf(address(this));
    }

    function getGlpTotalSupply() public view returns(uint256){
        return IERC20(glpToken).totalSupply();
    }

    function getPoolSize(address _asset) public view returns(uint256){
        return gmxVault.poolAmounts(_asset);
    }

    /**
    * @notice Get Assets under management in USDg
    */
    function getAumInUsdg(bool maximise) public view returns (uint256) {
         return glpManager.getAumInUsdg(maximise);
    }

    function getAssetBalance(address _asset) public view returns(uint256){
        return IERC20(_asset).balanceOf(address(this));
    }
    
    receive() external payable {
        revert();
    }

    fallback() external payable {
        revert();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;


abstract contract Guarded {

    mapping (address => uint256) public guards;
    function rely(address usr) external auth { guards[usr] = 1; }
    function deny(address usr) external auth { guards[usr] = 0; }

    modifier auth {
        require(guards[msg.sender] == 1, "Guarded/not-authorized");
        _;
    }

    // Use this in actor
    function __RelyOnSender() internal { 
        guards[msg.sender] = 1; 
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

interface IVaultUtils {
    function updateCumulativeFundingRate(address _collateralToken, address _indexToken) external returns (bool);
    function validateIncreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _sizeDelta, bool _isLong) external ;
    function validateDecreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _collateralDelta, uint256 _sizeDelta, bool _isLong, address _receiver) external ;
    function validateLiquidation(address _account, address _collateralToken, address _indexToken, bool _isLong, bool _raise) external  returns (uint256, uint256);
    function getEntryFundingRate(address _collateralToken, address _indexToken, bool _isLong) external  returns (uint256);
    function getPositionFee(address _account, address _collateralToken, address _indexToken, bool _isLong, uint256 _sizeDelta) external  returns (uint256);
    function getFundingFee(address _account, address _collateralToken, address _indexToken, bool _isLong, uint256 _size, uint256 _entryFundingRate) external  returns (uint256);
    function getBuyUsdgFeeBasisPoints(address _token, uint256 _usdgAmount) external  returns (uint256);
    function getSellUsdgFeeBasisPoints(address _token, uint256 _usdgAmount) external  returns (uint256);
    function getSwapFeeBasisPoints(address _tokenIn, address _tokenOut, uint256 _usdgAmount) external  returns (uint256);
    function getFeeBasisPoints(address _token, uint256 _usdgDelta, uint256 _feeBasisPoints, uint256 _taxBasisPoints, bool _increment) external  returns (uint256);
}

interface IVault {
    function isInitialized() external view returns (bool);
    function isSwapEnabled() external view returns (bool);
    function isLeverageEnabled() external view returns (bool);

    function setVaultUtils(IVaultUtils _vaultUtils) external;
    function setError(uint256 _errorCode, string calldata _error) external;

    function router() external view returns (address);
    function usdg() external view returns (address);
    function gov() external view returns (address);

    function whitelistedTokenCount() external view returns (uint256);
    function maxLeverage() external view returns (uint256);

    function minProfitTime() external view returns (uint256);
    function hasDynamicFees() external view returns (bool);
    function fundingInterval() external view returns (uint256);
    function totalTokenWeights() external view returns (uint256);
    function getTargetUsdgAmount(address _token) external view returns (uint256);

    function inManagerMode() external view returns (bool);
    function inPrivateLiquidationMode() external view returns (bool);

    function maxGasPrice() external view returns (uint256);

    function approvedRouters(address _account, address _router) external view returns (bool);
    function isLiquidator(address _account) external view returns (bool);
    function isManager(address _account) external view returns (bool);

    function minProfitBasisPoints(address _token) external view returns (uint256);
    function tokenBalances(address _token) external view returns (uint256);
    function lastFundingTimes(address _token) external view returns (uint256);

    function setMaxLeverage(uint256 _maxLeverage) external;
    function setInManagerMode(bool _inManagerMode) external;
    function setManager(address _manager, bool _isManager) external;
    function setIsSwapEnabled(bool _isSwapEnabled) external;
    function setIsLeverageEnabled(bool _isLeverageEnabled) external;
    function setMaxGasPrice(uint256 _maxGasPrice) external;
    function setUsdgAmount(address _token, uint256 _amount) external;
    function setBufferAmount(address _token, uint256 _amount) external;
    function setMaxGlobalShortSize(address _token, uint256 _amount) external;
    function setInPrivateLiquidationMode(bool _inPrivateLiquidationMode) external;
    function setLiquidator(address _liquidator, bool _isActive) external;

    function setFundingRate(uint256 _fundingInterval, uint256 _fundingRateFactor, uint256 _stableFundingRateFactor) external;

    function setFees(
        uint256 _taxBasisPoints,
        uint256 _stableTaxBasisPoints,
        uint256 _mintBurnFeeBasisPoints,
        uint256 _swapFeeBasisPoints,
        uint256 _stableSwapFeeBasisPoints,
        uint256 _marginFeeBasisPoints,
        uint256 _liquidationFeeUsd,
        uint256 _minProfitTime,
        bool _hasDynamicFees
    ) external;

    function setTokenConfig(
        address _token,
        uint256 _tokenDecimals,
        uint256 _redemptionBps,
        uint256 _minProfitBps,
        uint256 _maxUsdgAmount,
        bool _isStable,
        bool _isShortable
    ) external;

    function setPriceFeed(address _priceFeed) external;
    function withdrawFees(address _token, address _receiver) external returns (uint256);

    function directPoolDeposit(address _token) external;
    function buyUSDG(address _token, address _receiver) external returns (uint256);
    function sellUSDG(address _token, address _receiver) external returns (uint256);
    function swap(address _tokenIn, address _tokenOut, address _receiver) external returns (uint256);
    function increasePosition(address _account, address _collateralToken, address _indexToken, uint256 _sizeDelta, bool _isLong) external;
    function decreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _collateralDelta, uint256 _sizeDelta, bool _isLong, address _receiver) external returns (uint256);
    function liquidatePosition(address _account, address _collateralToken, address _indexToken, bool _isLong, address _feeReceiver) external;
    function tokenToUsdMin(address _token, uint256 _tokenAmount) external view returns (uint256);

    function priceFeed() external view returns (address);
    function fundingRateFactor() external view returns (uint256);
    function stableFundingRateFactor() external view returns (uint256);
    function cumulativeFundingRates(address _token) external view returns (uint256);
    function getNextFundingRate(address _token) external view returns (uint256);
    function getFeeBasisPoints(address _token, uint256 _usdgDelta, uint256 _feeBasisPoints, uint256 _taxBasisPoints, bool _increment) external view returns (uint256);

    function liquidationFeeUsd() external view returns (uint256);
    function taxBasisPoints() external view returns (uint256);
    function stableTaxBasisPoints() external view returns (uint256);
    function mintBurnFeeBasisPoints() external view returns (uint256);
    function swapFeeBasisPoints() external view returns (uint256);
    function stableSwapFeeBasisPoints() external view returns (uint256);
    function marginFeeBasisPoints() external view returns (uint256);

    function allWhitelistedTokensLength() external view returns (uint256);
    function allWhitelistedTokens(uint256) external view returns (address);
    function whitelistedTokens(address _token) external view returns (bool);
    function stableTokens(address _token) external view returns (bool);
    function shortableTokens(address _token) external view returns (bool);
    function feeReserves(address _token) external view returns (uint256);
    function globalShortSizes(address _token) external view returns (uint256);
    function globalShortAveragePrices(address _token) external view returns (uint256);
    function maxGlobalShortSizes(address _token) external view returns (uint256);
    function tokenDecimals(address _token) external view returns (uint256);
    function tokenWeights(address _token) external view returns (uint256);
    function guaranteedUsd(address _token) external view returns (uint256);
    function poolAmounts(address _token) external view returns (uint256);
    function bufferAmounts(address _token) external view returns (uint256);
    function reservedAmounts(address _token) external view returns (uint256);
    function usdgAmounts(address _token) external view returns (uint256);
    function maxUsdgAmounts(address _token) external view returns (uint256);
    function getRedemptionAmount(address _token, uint256 _usdgAmount) external view returns (uint256);
    function getMaxPrice(address _token) external view returns (uint256);
    function getMinPrice(address _token) external view returns (uint256);

    function getDelta(address _indexToken, uint256 _size, uint256 _averagePrice, bool _isLong, uint256 _lastIncreasedTime) external view returns (bool, uint256);
    function getPosition(address _account, address _collateralToken, address _indexToken, bool _isLong) external view returns (uint256, uint256, uint256, uint256, uint256, uint256, bool, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

interface IRewardRouterV2 {
    function weth() external returns(address);
    function gmx() external returns(address);
    function esGmx() external returns(address);
    function bnGmx() external returns(address);
    function glp() external returns(address);
    function stakedGmxTracker() external returns(address);
    function bonusGmxTracker() external returns(address);
    function feeGmxTracker() external returns(address);
    function stakedGlpTracker() external returns(address);
    function feeGlpTracker() external returns(address);
    function glpManager() external returns(address);
    function gmxVester() external returns(address);
    function glpVester() external returns(address);
    function pendingReceivers(address _asset) external returns(address);
    function stakeGmx(uint256 _amount) external;
    function stakeEsGmx(uint256 _amount) external;
    function unstakeGmx(uint256 _amount) external;
    function unstakeEsGmx(uint256 _amount) external;
    function mintAndStakeGlp(address _token, uint256 _amount, uint256 _minUsdg, uint256 _minGlp) external returns (uint256);
    function mintAndStakeGlpETH(uint256 _minUsdg, uint256 _minGlp) external payable returns (uint256);
    function unstakeAndRedeemGlp(address _tokenOut, uint256 _glpAmount, uint256 _minOut, address _receiver) external returns (uint256);
    function unstakeAndRedeemGlpETH(uint256 _glpAmount, uint256 _minOut, address payable _receiver) external returns (uint256);
    function claim() external; // claim to msg.sender
    function claimEsGmx() external;
    function claimFees() external;
    function compound() external;
    function handleRewards(
        bool _shouldClaimGmx,
        bool _shouldStakeGmx,
        bool _shouldClaimEsGmx,
        bool _shouldStakeEsGmx,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWeth,
        bool _shouldConvertWethToEth
    ) external;
    function signalTransfer(address _receiver) external;
    function acceptTransfer(address _sender) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;
interface IGlpManager {
    function usdg() external view returns (address);
    function glp() external view returns (address);
    function cooldownDuration() external view returns (uint256);
    function getAum(bool maximise) view external returns (uint256);
    function getAums() external view returns (uint256[] memory);
    function getAumInUsdg(bool maximise) external view returns (uint256);
    function lastAddedAt(address _account) external returns (uint256);
    function addLiquidity(address _token, uint256 _amount, uint256 _minUsdg, uint256 _minGlp) external returns (uint256);
    function addLiquidityForAccount(
        address _fundingAccount,
        address _account,
        address _token,
        uint256 _amount,
        uint256 _minUsdg,
        uint256 _minGlp
    ) external returns (uint256);
    function removeLiquidity(address _tokenOut, uint256 _glpAmount, uint256 _minOut, address _receiver) external returns (uint256);
    function removeLiquidityForAccount(
        address _account,
        address _tokenOut,
        uint256 _glpAmount,
        uint256 _minOut,
        address _receiver
    ) external returns (uint256);
}
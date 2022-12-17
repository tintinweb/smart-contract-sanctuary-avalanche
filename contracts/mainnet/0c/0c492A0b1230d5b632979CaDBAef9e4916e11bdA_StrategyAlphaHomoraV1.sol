// SPDX-License-Identifier: BSL 1.1
/**  
 /$$$$$$$  /$$       /$$   /$$ /$$$$$$$$  /$$$$$$  /$$      /$$  /$$$$$$  /$$   /$$       
| $$__  $$| $$      | $$  | $$| $$_____/ /$$__  $$| $$  /$ | $$ /$$__  $$| $$$ | $$      
| $$  \ $$| $$      | $$  | $$| $$      | $$  \__/| $$ /$$$| $$| $$  \ $$| $$$$| $$     
| $$$$$$$ | $$      | $$  | $$| $$$$$   |  $$$$$$ | $$/$$ $$ $$| $$$$$$$$| $$ $$ $$     
| $$__  $$| $$      | $$  | $$| $$__/    \____  $$| $$$$_  $$$$| $$__  $$| $$  $$$$     
| $$  \ $$| $$      | $$  | $$| $$       /$$  \ $$| $$$/ \  $$$| $$  | $$| $$\  $$$     
| $$$$$$$/| $$$$$$$$|  $$$$$$/| $$$$$$$$|  $$$$$$/| $$/   \  $$| $$  | $$| $$ \  $$     
|_______/ |________/ \______/ |________/ \______/ |__/     \__/|__/  |__/|__/  \__/ 
Blue Swan Labs
*/

pragma solidity ^0.8.17;
import "ERC20Upgradeable.sol";
import "HomoraData.sol";
import "IBank.sol";
import "IUniswapRouterV2.sol";
import "IUniswapV2Pair.sol";
import "IUniswapV2Factory.sol";

import "IBaseOracle.sol";
import {BaseStrategy} from "BaseStrategy.sol";

import "IMiniChefV2PNG.sol";
import "IWMiniChefV2PNG.sol";

import "IWBoostedMasterChefJoeWorker.sol";
import "IBoostedMasterChefJoe.sol";
import "AggregatorV3Interface.sol";

import "PairOracle.sol";

contract StrategyAlphaHomoraV1 is BaseStrategy{        
    
     event RebalanceDone(
        uint256 gradient,
        int collateralBefore,
        int collateralChange,
        int balanceBefore,
        int balanceChange,
        uint256 indexed blockNumber,
        uint256 timestamp
    );

    event SetPnL(
        int balanceOfPool,
        int pnl,
        int stableWithdrawn,
        int stableSupplied,
        uint256 indexed blockNumber,
        uint256 timestamp
    );

    mapping(address=>address) oracles;

    event Harvest(
        uint256 stableAmount,
        uint256 indexed blockNumber,
        uint256 timestamp
        );

    event SwappingToUSDC(uint256 stableAmount);

    struct Amounts {
        uint256 amtAUser; // Supplied tokenA amount
        uint256 amtBUser; // Supplied tokenB amount
        uint256 amtLPUser; // Supplied LP token amount
        uint256 amtABorrow; // Borrow tokenA amount
        uint256 amtBBorrow; // Borrow tokenB amount
        uint256 amtLPBorrow; // Borrow LP token amount
        uint256 amtAMin; // Desired tokenA amount (slippage control)
        uint256 amtBMin; // Desired tokenB amount (slippage control)
    }

    struct RepayAmounts {
        uint256 amtLPTake; // Take out LP token amount (from Homora)
        uint256 amtLPWithdraw; // Withdraw LP token amount (back to caller)
        uint256 amtARepay; // Repay tokenA amount
        uint256 amtBRepay; // Repay tokenB amount
        uint256 amtLPRepay; // Repay LP token amount
        uint256 amtAMin; // Desired tokenA amount
        uint256 amtBMin; // Desired tokenB amount
    }
        
    uint256 public slippage;

    address public spell;
    address public homoraBank;
    address public volatileToken;
    address public lpToken;
    address public router;
    address[] public rewards;
    uint256 public pid;
    uint256 public positionId;
    uint256 public leverage;
    uint256 public priceAnchor;
    uint256 public stableSupplied;
    uint256 public stableWithdrawn;
    uint256 public numRebalances;
    uint256 ammCheckThreshold;
    uint256 debtRatioThreshold;
    uint256 volatilityThreshold;   
    address homoraOracle;    
    uint[] public gradients;
    uint[] public gradientBreakPoints;   
    int public pnl;
    bool public isPangolin;
    bool public isTraderJoe;    
    HomoraData public homoraData;
    PairOracle public rewardPairOracle;
    bool public twapIsSet;
    bool public shouldUseTwap;
    IUniswapV2Pair public rewardPool;

    uint256 PRECISION;
    uint256 MAX_INT;
    bool isToken0Stable;

    //TraderJoe
    string constant spellOpenTJ =
      "addLiquidityWMasterChef(address,address,(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256),uint256)";
    string constant spellCloseTJ =
      "removeLiquidityWMasterChef(address,address,(uint256,uint256,uint256,uint256,uint256,uint256,uint256))";
    string constant spellHarvestTJ = "harvestWMasterChef()";

    //Pangolin
    string constant spellOpen =
        "addLiquidityWMiniChef(address,address,(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256),uint256)";           
    string constant spellClose =
        "removeLiquidityWMiniChef(address,address,(uint256,uint256,uint256,uint256,uint256,uint256,uint256))";
    string constant spellHarvest = "harvestWMiniChefRewards()";    
        
    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _keeper,
        address _guardian,
        uint256 _pid,
        uint256 _leverage,              
        address[] memory config,
        address[] memory _rewards,        
        address _vault,
        bool _isToken0Stable        
    ){
        __BaseStrategy_init(
            _governance,
            _strategist,
            _controller,
            _keeper,
            _guardian
        );

        PRECISION = 1e12;
        MAX_INT = 2**256 - 1;

        leverage = _leverage;
        ammCheckThreshold = PRECISION / 100;
        debtRatioThreshold = 99 * PRECISION / 100;
        volatilityThreshold = PRECISION; // Don't perform any rebalance or harvest, if volatility is at 100%        
        spell = config[0];
        homoraBank = config[1];
        lpToken = config[2];
        router = config[3];
        homoraOracle=config[4];
        isToken0Stable = _isToken0Stable;
        if(isToken0Stable){
            stableToken = IUniswapV2Pair(lpToken).token0();            
            volatileToken = IUniswapV2Pair(lpToken).token1();
        }else{
            stableToken = IUniswapV2Pair(lpToken).token1();            
            volatileToken = IUniswapV2Pair(lpToken).token0();
        }
        IUniswapV2Factory factory = IUniswapV2Factory(IUniswapRouterV2(router).factory());

        if(address(stableToken) != address(USDC)){            
            IUniswapV2Pair stableSwappool = IUniswapV2Pair(factory.getPair(stableToken, USDC));
            IERC20(address(stableSwappool)).approve(router, MAX_INT);
        }

        depositToken = USDC;
        
        pid = _pid;
        for (uint256 j = 0; j < _rewards.length; j++) {
            rewards.push(_rewards[j]);
        }

        address[] memory path = new address[](2);
        path[0] = volatileToken;
        path[1] = stableToken;
        priceAnchor = _routerQuote(
            uint256(10)**ERC20Upgradeable(volatileToken).decimals(),
            path
        );

        vault = _vault;
        slippage = PRECISION / 40; // 2% slippage allowance

        // Approvals
        IERC20(stableToken).approve(homoraBank, MAX_INT);
        IERC20(volatileToken).approve(homoraBank, MAX_INT);
        IERC20(lpToken).approve(homoraBank, MAX_INT);
        IERC20(USDC).approve(router, MAX_INT);
        IERC20(stableToken).approve(router, MAX_INT);
        IERC20(volatileToken).approve(router, MAX_INT);
        IERC20(lpToken).approve(router, MAX_INT);
        for (uint256 i = 0; i < rewards.length; i++) {
            IERC20(rewards[i]).approve(router, MAX_INT);
        }

        gradients = [0, 2*PRECISION/10, 4*PRECISION/10, 75*PRECISION/100];
        gradientBreakPoints = [0, (25*PRECISION)/1000, (50*PRECISION)/1000, (75*PRECISION)/1000]; 
        string memory poolName = IUniswapV2Pair(lpToken).name();       
        if(keccak256(abi.encodePacked(poolName)) == keccak256(abi.encodePacked('Pangolin Liquidity'))) {
            isPangolin = true;
        }
        if(keccak256(abi.encodePacked(poolName)) == keccak256(abi.encodePacked('Joe LP Token'))) {
            isTraderJoe = true;
        }

        homoraData = new HomoraData(IBank(homoraBank), router, isToken0Stable, lpToken, volatileToken, stableToken);                
        // IUniswapV2Pair rewardPool = IUniswapV2Pair(factory.getPair(stableToken, rewards[0]));
        // rewardPairOracle = new PairOracle(address(rewardPool), _governance);
        // rewardPairOracle.forceUpdateAndSetPeriod(86400);                
        rewardPool = IUniswapV2Pair(factory.getPair(stableToken, rewards[0]));
        shouldUseTwap=false;
    }

    /// ===== View Functions =====

    // @dev Specify the name of the strategy
    function getName() external virtual pure override returns (string memory) {
        return "LYF-AH-STRATEGY";
    }

    // @dev Specify the version of the Strategy, for upgrades
    function version() external pure returns (string memory) {
        return "1.1";
    }


    function balanceOfPool() public view override returns (uint256) {
        uint256 balanceStable = IERC20(stableToken).balanceOf(address(this));
        uint256 expectedEquity = homoraData.balanceOfPoolInt(positionId)+balanceStable;
        address[] memory path = new address[](2);
        path[0] = stableToken;
        path[1] = USDC;
        if (USDC!=stableToken) {
            expectedEquity = _routerQuote(expectedEquity, path);
        }
        return expectedEquity;
    }

    function setOracle(address token, address oracle) external {
        _onlyAuthorizedActors();
        oracles[token] = oracle;
    }

    function setOracleTwap(address pairOracle) external {
        _onlyAuthorizedActors();
        require(twapIsSet == false, 'twap is already set');        
        rewardPairOracle = PairOracle(pairOracle);
        twapIsSet = true;        
        rewardPairOracle.forceUpdateAndSetPeriod(86400);   
    }

    function unsetOracleTwap() external {
        _onlyAuthorizedActors();
       twapIsSet = false;
    }

    function setTwapUse(bool setTwap) external {
        _onlyAuthorizedActors();
       shouldUseTwap = setTwap;
    }

    function setLeverage(uint256 _leverage) external {
        _onlyAuthorizedActors();
        leverage = _leverage;
    }

    /// ===== Internal Core Implementations =====

    function _oraclePrice(address token) public view returns (uint) {
        uint stableDecimals = ERC20Upgradeable(stableToken).decimals();
        uint tokenPrice = IBaseOracle(homoraOracle).getETHPx(token)*uint(10)**ERC20Upgradeable(token).decimals();
        uint stablePrice = IBaseOracle(homoraOracle).getETHPx(stableToken)*uint(10)**stableDecimals;
        return (tokenPrice*uint(10)**stableDecimals)/stablePrice;
    }

    function _oraclePriceChainLink(address _token) public view returns (uint256 price) {        
        (, int256 stablePrice, , , ) = AggregatorV3Interface(oracles[stableToken]).latestRoundData();
        (, int256 volatilePrice, , , ) = AggregatorV3Interface(oracles[_token]).latestRoundData();
        price = uint256((volatilePrice * int256(10)**ERC20Upgradeable(stableToken).decimals()) /stablePrice);
    }

    function _pairQuote(address _token) public view returns (uint256 price) {        
        price = homoraData._pairQuote(_token);
    }

    function priceOracleUpdate() public { 
        _onlyAuthorizedActorsOrController();
        require(isPangolin == true, 'Oracle-not-enabled');
        rewardPairOracle.update();
    }

    /// @dev Check if router price matches oracle price        
    function _ammCheck() internal view returns (bool) {
        uint256 ratio = (homoraData._pairQuote(volatileToken) * PRECISION) / _oraclePrice(volatileToken);
        if (ratio < PRECISION) {
            return PRECISION - ratio < ammCheckThreshold;
        } else {
            return ratio - PRECISION < ammCheckThreshold;
        }
    }

    /// @dev Checks that position's debt ratio isn't too high and the token isn't experiencing very high volatility
    /// @dev If volatility check is too high, revert
    /// @dev If debt ratio is too high, withdraw all funds from homora
    function _checkPositionHealth() internal returns (bool healthy) {
        uint currentPrice = homoraData._pairQuote(volatileToken);
        uint priceChange;
        if (currentPrice>priceAnchor) {
            priceChange = (currentPrice-priceAnchor)*PRECISION/priceAnchor;
        } else {
            priceChange = (priceAnchor-currentPrice)*PRECISION/priceAnchor;
        }
        if (priceChange>volatilityThreshold) {
            revert("Failed volaitlity check");
        }
        (, uint debtRatio,,,,) = heartBeat();
        if (debtRatio>debtRatioThreshold) {
            _decreasePosition(PRECISION);
            return false;
        }
        return true;
    }

   function requireAmmCheckPass() internal view {
        require(_ammCheck() == true, "reason: Oracle Price difference");
    }

    function getGradient(uint priceChange) public view returns (uint) {
        uint maxLiquidationBreakPoint = gradientBreakPoints[gradientBreakPoints.length-1];
        if(priceChange > maxLiquidationBreakPoint) return PRECISION;
        for (uint i = gradientBreakPoints.length-1; i>=0; i--) {    
            if (gradientBreakPoints[i]<=priceChange) {
                uint gradient = gradients[i];
                return gradient;
            }
        }
        return 0;
    }

    function updateGradient(uint[] memory _gradients, uint[] memory _gradientBreakPoints) external {
        _onlyAuthorizedActorsOrController();
        require(_gradients.length==_gradientBreakPoints.length, "Invalid input");
        gradients = _gradients;
        gradientBreakPoints = _gradientBreakPoints;
    }

    /// @dev Perform amm check and check if strategy needs rebalancing, returns equity, price change and amount to rebalance by
    /// @return ammCheck Wether router price and oracle price are close to each other
    /// @return debtRatio ratio of collateral and borrow
    /// @return equity equity
    /// @return priceChange price difference between current price and price anchor
    /// @return currentPrice current price of risky asset
    /// @return gradient If greater than 0 strategy needs to be rebalanced by withdrawing this percentage
    function heartBeat()
        public
        view
        returns (
            bool ammCheck,
            uint256 debtRatio,
            uint256 equity,
            uint256 priceChange,
            uint256 currentPrice,
            uint256 gradient
        )
    {
        equity = balanceOfPool();
        // AMM check
        ammCheck = _ammCheck();
        // Calculate debt ratio
        uint256 borrowValue = IBank(homoraBank).getBorrowETHValue(positionId);
        uint256 collateralValue =
            IBank(homoraBank).getCollateralETHValue(positionId);
        
        if(positionId != 0 && collateralValue>0){
            debtRatio = (borrowValue * PRECISION) / collateralValue;
        }
        // Calculate gradient
        currentPrice = homoraData._pairQuote(volatileToken);
        if (currentPrice >= priceAnchor) {
            priceChange =
                ((currentPrice - priceAnchor) * PRECISION) /
                priceAnchor;
        } else {
            priceChange =
                ((priceAnchor - currentPrice) * PRECISION) /
                priceAnchor;
        }
         if (equity>0) {
            gradient = getGradient(priceChange);
        }
    }


    function _setPnl() internal {
        uint decimals = ERC20Upgradeable(stableToken).decimals();
        int _balOfPool = int(homoraData.balanceOfPoolInt(positionId));
        int pnlInt = _balOfPool+int(stableWithdrawn)-int(stableSupplied);
        pnl = (pnlInt*int(10)**6)/int(10)**decimals;
        emit SetPnL(
            _balOfPool,
            pnl,
            int(stableWithdrawn),
            int(stableSupplied),
            block.number,
            block.timestamp
        );
    }

    function _withdrawAll() internal override {
        if (positionId==0) return;
        _harvest();
        _swapRewards();
        _decreasePosition(PRECISION);
        uint256 balanceStable = IERC20(stableToken).balanceOf(address(this));
        if(balanceStable > 0 && _isStableNotUSDC()){
            _swapToUSDC();
        }         
    }

    /// @dev Get router price for token
    function _routerQuote(uint256 _amount, address[] memory path)
        public
        view
        returns (uint256)
    {
        if (_amount==0) return 0;
        uint256[] memory amounts =
            IUniswapRouterV2(router).getAmountsOut(_amount, path);
        return amounts[amounts.length - 1];
    }

    function _consultRewardOracle() public view returns (uint256){        
        return isPangolin==true ? rewardPairOracle.consult(rewards[0], 1*10**ERC20Upgradeable(rewards[0]).decimals()): 0;
    }


    /// @dev invest the amount of want
    /// @notice When this function is called, the controller has already sent want to this
    /// @notice Just get the current balance and then invest accordingly
    function _deposit() internal override {
        requireAmmCheckPass();
        uint256 balanceUSDC = IERC20(USDC).balanceOf(address(this));
        if(balanceUSDC > 0 && _isStableNotUSDC() ){
            emit SwappingToUSDC(balanceUSDC);
            _swapToStable();
        }        
        uint256 supplied = IERC20(stableToken).balanceOf(address(this));
        if(supplied == 0) {
            return;
        }
        stableSupplied+=supplied;
        uint256 multiplier = leverage - 1;
        uint256 frac_stable = PRECISION / (leverage / (leverage - ( leverage - 1) ) + 1);
        uint256 frac_volatile = PRECISION - frac_stable;
        uint256 borrow_stable =
            (supplied * frac_stable * multiplier) / PRECISION;
        uint256 borrow_volatile_in_stable =
            ((supplied * frac_volatile * multiplier) / PRECISION);
        address[] memory path = new address[](2);
        path[0] = stableToken;
        path[1] = volatileToken;
        uint256 borrow_volatile = _routerQuote(borrow_volatile_in_stable, path);
        require(borrow_stable*2==supplied || borrow_stable*2==supplied-1);
        uint minStable = (borrow_stable + supplied)*(PRECISION-slippage)/PRECISION;
        uint minVolatile = borrow_volatile*(PRECISION-slippage)/PRECISION;
        Amounts memory amt = Amounts(supplied, 0, 0, borrow_stable, borrow_volatile, 0, minStable, minVolatile);
        string memory spellOp = isPangolin ? spellOpen : spellOpenTJ;
        positionId = IBank(homoraBank).execute(
            positionId,
            spell,
            abi.encodeWithSignature(
                spellOp,
                stableToken,
                volatileToken,
                amt,
                pid
            )
        );
        _setPnl();
    }


    function _decreasePosition(uint256 gradient) internal returns (uint256) {
        requireAmmCheckPass();
        uint256 lpTokens = homoraData.getCollateralSize(positionId);       
        if(lpTokens == 0) return 0; 
        uint256 stableBalance0 = IERC20(stableToken).balanceOf(address(this));
        (uint256 debtStable, uint256 debtVolatile) = homoraData.getDebts(positionId);
        uint256 tokensToWithdraw = (lpTokens * gradient) / PRECISION;
        uint256 repayStable = (debtStable * gradient) / PRECISION;
        uint256 repayVolatile = (debtVolatile * gradient) / PRECISION;
        if (gradient==PRECISION) {
            repayStable = MAX_INT;
            repayVolatile = MAX_INT;
        }
        uint balance = homoraData.balanceOfPoolInt(positionId);
        uint withdrawn = balance*gradient/PRECISION;
        uint minWithdrawn = withdrawn*(PRECISION-slippage)/PRECISION;
        RepayAmounts memory amt =
            RepayAmounts(
                tokensToWithdraw,
                0,
                repayStable,
                repayVolatile,
                0,
                minWithdrawn,
                0
            );
        string memory spellCl = isPangolin ? spellClose : spellCloseTJ;
        IBank(homoraBank).execute(
            positionId,
            spell,
            abi.encodeWithSignature(spellCl, stableToken, volatileToken, amt)
        );        
        uint amountWithdrawn = IERC20(stableToken).balanceOf(address(this))-stableBalance0;
        require(amountWithdrawn>minWithdrawn, "Failed slippage");
        stableWithdrawn+=amountWithdrawn;
        _setPnl();
        return amountWithdrawn;
    }
    
    receive() external payable {
        uint256 oraclePrice = _oraclePrice(volatileToken);
        address[] memory path = new address[](2);
        path[0] = volatileToken;
        path[1] = stableToken;
        if( msg.value > 0 ) {
            uint expectedOut = msg.value*oraclePrice/uint256(10)**ERC20Upgradeable(volatileToken).decimals();
            uint minOut = expectedOut*(PRECISION-slippage)/PRECISION;
            uint routerExpectedOut = _routerQuote(msg.value, path);
            if (routerExpectedOut>0 && msg.value>0) {
                IUniswapRouterV2(router).swapExactAVAXForTokens{value: msg.value}(
                    minOut,
                    path,
                    address(this),
                    block.timestamp
                );
            }
        }       
    }


    function _isStableNotUSDC() internal view returns(bool){
        address _USDC = address(USDC);
        address _stableToken = address(stableToken);
        return _USDC != _stableToken;
    }

    /// @notice Withdraws all funds from position into stable token and holds them in strategy contract
    function exitLiquidity() public {
        _onlyAuthorizedActorsOrController();        
        _harvest();
        _swapRewards();
        _decreasePosition(PRECISION);
    }
    
    function _withdrawSome(uint256 amount)
        internal
        override
        returns (uint256 withdrawn)
    {
        if (positionId==0) return (0);  
        uint256 equity = homoraData.balanceOfPoolInt(positionId);
        uint256 gradient = (amount * PRECISION) / equity;
        if (gradient>PRECISION) {
            gradient = PRECISION;
        }
        withdrawn = _decreasePosition(gradient);
        uint256 balanceStable = IERC20(stableToken).balanceOf(address(this));
        if(balanceStable > 0 && _isStableNotUSDC()){
            _swapToUSDC();
        } 
       
    }

    function harvest() external {
        _onlyAuthorizedActorsOrController();
        uint balanceBefore = IERC20(stableToken).balanceOf(address(this));
        _harvest();
        _swapRewards();
        uint harvested = IERC20(stableToken).balanceOf(address(this)) - balanceBefore;
        // Require at least 1 cent to deposit, otherwise insufficient liquidity minted revert happens
        if (IERC20(stableToken).balanceOf(address(this))>10**ERC20Upgradeable(stableToken).decimals()/100) {
            _deposit();
            // Don't want to count harvested usdc towards supplied usdc
            stableSupplied-=harvested;
        }       
        _setPnl();
        if(isPangolin){
            rewardPairOracle.update();
        }        
        emit Harvest(
            harvested,
            block.number,
            block.timestamp
            );                
    }

    function rebalance(uint256 gradient) external {
        _onlyAuthorizedActorsOrController();
        requireAmmCheckPass();
        bool healthy = _checkPositionHealth();
        if (!healthy) return;
        int collateralBefore = int(homoraData.getCollateralSize(positionId));
        int balanceBefore = int(balanceOfPool());
        _decreasePosition(gradient);        
        _deposit();
        numRebalances += 1;
        uint currentPrice = homoraData._pairQuote(volatileToken);
        priceAnchor = priceAnchor*(PRECISION-gradient)/PRECISION + currentPrice*gradient/PRECISION;
        emit RebalanceDone(
            gradient,
            collateralBefore,
            int(homoraData.getCollateralSize(positionId))-collateralBefore,
            balanceBefore,
            int(balanceOfPool())-balanceBefore,
            block.number,
            block.timestamp
        );
    }

    function getPendingRewards() public view returns (uint pendingRewards) {        
        if(isPangolin == true) {
             pendingRewards = homoraData.getPendingRewardsPangolin(positionId);
        }
        if(isTraderJoe == true) {
             pendingRewards = homoraData.getPendingRewardsTraderJoe(positionId);             
        }        
    }

    function _harvest() internal {
        requireAmmCheckPass();
        bool healthy = _checkPositionHealth();
        if (balanceOfPool()==0) return;
        if (!healthy) return;
        if (getPendingRewards() == 0) return;
        string memory spellHst = isPangolin ? spellHarvest : spellHarvestTJ;
        IBank(homoraBank).execute(
            positionId,
            spell,
            abi.encodeWithSignature(spellHst)
        );
    }
    
    function _swapRewards() internal {
        for (uint256 i = 0; i < rewards.length; i++) {
            uint256 balance = IERC20(rewards[i]).balanceOf(address(this));
            if(balance == 0){
                return;
            }
            // Slippage control
            uint price;
            if (oracles[rewards[i]]!=address(0) && shouldUseTwap == false) {
                price = _oraclePriceChainLink(rewards[i]);
            } else {
                price = _consultRewardOracle();
            }
            uint expectedOut = balance*price/uint256(10)**ERC20Upgradeable(rewards[i]).decimals();
            uint minOut = expectedOut*(PRECISION-slippage)/PRECISION;
            require(minOut>0, "Badd slippage control");

            address[] memory path = new address[](2);
            path[0] = rewards[i];
            path[1] = stableToken;
            IUniswapRouterV2(router).swapExactTokensForTokens(
                balance,
                minOut,
                path,
                address(this),
                block.timestamp
            );
        }
    }

    function _swapToUSDC() internal {        
            uint256 balance = IERC20(stableToken).balanceOf(address(this));
            require(balance > 0, "No amt to swap");            
            // Slippage control
            uint price;
            price = _oraclePrice(USDC);           
            uint expectedOut = balance*price;
            uint minOut = expectedOut*(PRECISION-slippage)/PRECISION;
            require(minOut>0, "Badd slippage control");
            minOut = minOut/uint256(10)**ERC20Upgradeable(USDC).decimals();
            address[] memory path = new address[](2);
            path[0] = stableToken;
            path[1] = USDC;
            uint routerExpectedOut = _routerQuote(balance, path);
            if (routerExpectedOut>0) {
                IUniswapRouterV2(router).swapExactTokensForTokens(
                    balance,
                    minOut,
                    path,
                    address(this),
                    block.timestamp
                );       
            } 
    }

    function _swapToStable() internal {        
            uint256 balance = IERC20(USDC).balanceOf(address(this));
            require(balance > 0, "No amount of stable to swap");
            
            // Slippage control
            uint price;
            price = _oraclePrice(USDC);
            uint expectedOut = balance*price/uint256(10)**ERC20Upgradeable(stableToken).decimals();
            uint minOut = expectedOut*(PRECISION-slippage)/PRECISION;
            require(minOut>0, "Badd slippage control");

            address[] memory path = new address[](2);
            path[0] = USDC;
            path[1] = stableToken;
            uint routerExpectedOut = _routerQuote(balance, path);
            if (routerExpectedOut>0) {
                IUniswapRouterV2(router).swapExactTokensForTokens(
                    balance,
                    minOut,
                    path,
                    address(this),
                    block.timestamp
                );        
            }
    }


    /// @notice sets slippage tolerance for liquidity provision in terms of BPS ie.
    /// @notice minSlippage = 0
    /// @notice maxSlippage = 10_000
    function setSlippageTolerance(uint256 _s) external whenNotPaused {
        _onlyAuthorizedActors();
        require(_s <= PRECISION, "slippage out of bounds");
        slippage = _s;
    }

    function getDebts() public view returns (uint256, uint256) {
        (uint256 debt1, uint256 debt2 ) = homoraData.getDebts(positionId);
        return (debt1, debt2);
    }

    function withdrawMoneyETH() public {
        _onlyAuthorizedActorsOrController();
        address payable to = payable(msg.sender);
        to.transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "IERC20Upgradeable.sol";
import "IERC20MetadataUpgradeable.sol";
import "ContextUpgradeable.sol";
import "Initializable.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "IERC20Upgradeable.sol";

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "Initializable.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "AddressUpgradeable.sol";

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

pragma solidity ^0.8.17;
import "Ownable.sol";
import "IBank.sol";

import "IWBoostedMasterChefJoeWorker.sol";
import "IBoostedMasterChefJoe.sol";
import "IMiniChefV2PNG.sol";
import "IWMiniChefV2PNG.sol";

import "ERC20Upgradeable.sol";

import "IUniswapRouterV2.sol";
import "IUniswapV2Pair.sol";

contract HomoraData is Ownable {
  
  IBank homoraBank; // homora bank
  address stableToken;
  uint256 PRECISION;
  address router;
  address lpToken;
  address volatileToken;
  bool isToken0Stable;

  constructor(
    IBank _bank,
    address _router,
    bool _isToken0Stable,
    address _lpToken,
    address _volatileToken,
    address _stableToken
  ) {
    homoraBank = _bank;    
    PRECISION = 1e12;
    router = _router;
    isToken0Stable = _isToken0Stable;
    lpToken=_lpToken;
    volatileToken = _volatileToken;
    stableToken = _stableToken;
  }

    function getPendingRewardsTraderJoe(uint positionId) external view onlyOwner returns (uint pendingRewards) {
        if(positionId == 0){
                return 0;
            }
        // query position info from position id
        (, address collateralTokenAddress, uint collateralId, uint collateralAmount) = IBank(homoraBank).getPositionInfo(positionId);

        IWBoostedMasterChefJoeWorker wrapper = IWBoostedMasterChefJoeWorker(collateralTokenAddress);
        IBoostedMasterChefJoe chef = IBoostedMasterChefJoe(wrapper.chef());

        // get info for calculating rewards
        (uint poolId, uint startRewardTokenPerShare) = wrapper.decodeId(collateralId);
        uint endRewardTokenPerShare = wrapper.accJoePerShare();
        (uint totalSupply, , ) = chef.userInfo(poolId, address(wrapper)); // total lp from wrapper deposited in Chef

        // pending rewards separates into two parts
        // 1. pending rewards that are in the wrapper contract
        // 2. pending rewards that wrapper hasn't claimed from Chef's contract
        (uint pendingRewardFromChef, , , ) = chef.pendingTokens(poolId, address(wrapper));
        endRewardTokenPerShare += (pendingRewardFromChef * PRECISION) / totalSupply;

        uint stReward = (startRewardTokenPerShare * collateralAmount + PRECISION - 1) / PRECISION;
        uint enReward = (endRewardTokenPerShare * collateralAmount) / PRECISION;

        pendingRewards = (enReward > stReward) ? enReward - stReward : 0;
    }

    function getPendingRewardsPangolin(uint positionId) external view onlyOwner returns (uint pendingRewards) {
       if(positionId == 0){
                return 0;
            }
    // query position info from position id
            (, address collateralTokenAddress, uint collateralId, uint collateralAmount) = IBank(homoraBank).getPositionInfo(positionId);

            IWMiniChefV2PNG wrapper = IWMiniChefV2PNG(collateralTokenAddress);
            IMiniChefV2PNG chef = IMiniChefV2PNG(wrapper.chef());

            // get info for calculating rewards
            (uint poolId, uint startRewardTokenPerShare) = wrapper.decodeId(collateralId);
            uint endRewardTokenPerShare = calculateAccRewardPerShareMinichefPangolin(chef, poolId);
            uint stReward = (startRewardTokenPerShare * collateralAmount + PRECISION - 1) / PRECISION;            
            uint enReward = (endRewardTokenPerShare * collateralAmount) / PRECISION;

            pendingRewards = (enReward > stReward) ? enReward - stReward : 0;
  }

    function calculateAccRewardPerShareMinichefPangolin(IMiniChefV2PNG _chef, uint _poolId)
        internal
        view
        returns (uint accRewardPerShare)
    {
            uint lastRewardTime;
            uint allocPoint;
            (accRewardPerShare, lastRewardTime, allocPoint) = _chef.poolInfo(_poolId);
            IERC20 lpTokenChef = IERC20(_chef.lpToken(_poolId));
            uint lpSupply = lpTokenChef.balanceOf(address(this));
            uint rewardsExpiration = _chef.rewardsExpiration();
            uint currentTimestamp = block.timestamp;
            uint totalAllocPoint = _chef.totalAllocPoint();
            uint rewardPerSecond = _chef.rewardPerSecond();

            if (currentTimestamp > lastRewardTime && lpSupply != 0) {
            uint time = currentTimestamp <= rewardsExpiration
                ? currentTimestamp - lastRewardTime // Accrue rewards until now
                : rewardsExpiration > lastRewardTime
                ? rewardsExpiration - lastRewardTime // Accrue rewards until expiration
                : 0; // No rewards to accrue
            uint reward = totalAllocPoint > 0 ? (time * rewardPerSecond * allocPoint) / totalAllocPoint : 0;
            accRewardPerShare += lpSupply > 0 ? (reward * PRECISION) / lpSupply : 0;
        }
    }

     function getDebts(uint positionId) public view returns (uint256, uint256) {
        (address[] memory tokens, uint256[] memory debts) =
            IBank(homoraBank).getPositionDebts(positionId);
        if (tokens.length == 2) {
            if (tokens[0] == stableToken) {
                return (debts[0], debts[1]);
            } else {
                return (debts[1], debts[0]);
            }
        } else if (tokens.length == 1) {
            if (tokens[0] == stableToken) {
                return (debts[0], 0);
            } else {
                return (0, debts[0]);
            }
        } else {
            return (0, 0);
        }
    }

    function getCollateralSize(uint positionId) public view returns (uint256 collateral) {
        (, , , collateral) = IBank(homoraBank).getPositionInfo(positionId);
    }

    /// @dev Get price of token from liquidity pool in terms of StableToken
    ///TODO check for cases where PNG to USDC.e
     function _pairQuote(address token)
        public
        view
        returns (uint price)
    {
        uint volatileDecimals = ERC20Upgradeable(token).decimals();
        uint256 _amount = 1*uint256(10)**(volatileDecimals);
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = stableToken;
        uint256[] memory amounts =
            IUniswapRouterV2(router).getAmountsOut(_amount, path);
        price =  amounts[amounts.length - 1];
    }

       /// @dev Get router price for token
    function _routerQuote(uint256 _amount, address[] memory path)
        internal
        view
        returns (uint256)
    {
        if (_amount==0) return 0;
        uint256[] memory amounts =
            IUniswapRouterV2(router).getAmountsOut(_amount, path);
        return amounts[amounts.length - 1];
    }

        /// @dev Balance of want-USDC currently held in strategy positions in POOL
    /// This returns the expected closing equity from unwinding the position after
    /// debt repayment
    function balanceOfPoolInt(uint positionId) public view returns (uint256) {
        uint256 collateral = getCollateralSize(positionId);
        (uint256 debt0, uint256 debt1) = getDebts(positionId);
        (uint256 r0, uint256 r1, ) = IUniswapV2Pair(lpToken).getReserves();
        uint256 totalSupply = IUniswapV2Pair(lpToken).totalSupply();
        uint256 supply0;
        uint256 supply1; 
        if(isToken0Stable){
             supply0 = (r0 * collateral) / totalSupply;
             supply1 = (r1 * collateral) / totalSupply;
        }else{
             supply0 = (r1 * collateral) / totalSupply;
             supply1 = (r0 * collateral) / totalSupply;
        }       
        uint256 equity0 = supply0 - debt0;
        address[] memory path = new address[](2);
        path[0] = volatileToken;
        path[1] = stableToken;
        uint256 expectedEquity;
        if (supply1 > debt1) {
            expectedEquity = equity0 + _routerQuote(supply1 - debt1, path);
        } else {
            path[0] = stableToken;
            path[1] = volatileToken;
            uint excess = debt1-supply1;
            if(excess > 0){
                expectedEquity = equity0 - IUniswapRouterV2(router).getAmountsIn(debt1-supply1, path)[0];
            }else{
                expectedEquity = equity0;
            }            
        }
        return expectedEquity;
    }
 
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.17;

import "Context.sol";

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

pragma solidity ^0.8.17;

interface IBank {
    /// The governor adds a new bank gets added to the system.
    event AddBank(address token, address cToken);
    /// The governor sets the address of the oracle smart contract.
    event SetOracle(address oracle);
    /// The governor sets the basis point fee of the bank.
    event SetFeeBps(uint256 feeBps);
    /// The governor withdraw tokens from the reserve of a bank.
    event WithdrawReserve(address user, address token, uint256 amount);
    /// Someone borrows tokens from a bank via a spell caller.
    event Borrow(
        uint256 positionId,
        address caller,
        address token,
        uint256 amount,
        uint256 share
    );
    /// Someone repays tokens to a bank via a spell caller.
    event Repay(
        uint256 positionId,
        address caller,
        address token,
        uint256 amount,
        uint256 share
    );
    /// Someone puts tokens as collateral via a spell caller.
    event PutCollateral(
        uint256 positionId,
        address caller,
        address token,
        uint256 id,
        uint256 amount
    );
    /// Someone takes tokens from collateral via a spell caller.
    event TakeCollateral(
        uint256 positionId,
        address caller,
        address token,
        uint256 id,
        uint256 amount
    );
    /// Someone calls liquidatation on a position, paying debt and taking collateral tokens.
    event Liquidate(
        uint256 positionId,
        address liquidator,
        address debtToken,
        uint256 amount,
        uint256 share,
        uint256 bounty
    );


    /// @dev Return the current position while under execution.
    function POSITION_ID() external view returns (uint256);

    /// @dev Return the current target while under execution.
    function SPELL() external view returns (address);

    /// @dev Return the current executor (the owner of the current position).
    function EXECUTOR() external view returns (address);

    /// @dev Return bank information for the given token.
    function getBankInfo(address token)
        external
        view
        returns (
            bool isListed,
            address cToken,
            uint256 reserve,
            uint256 totalDebt,
            uint256 totalShare
        );

    /// @dev Return position information for the given position id.
    function getPositionInfo(uint256 positionId)
        external
        view
        returns (
            address owner,
            address collToken,
            uint256 collId,
            uint256 collateralSize
        );

    function getPositionDebts(uint256 positionId)
        external
        view
        returns (address[] memory tokens, uint256[] memory debts);

    function execute(
        uint256 positionId,
        address spell,
        bytes memory data
    ) external payable returns (uint256);

    /// @dev Return the borrow balance for given positon and token without trigger interest accrual.
    function borrowBalanceStored(uint256 positionId, address token)
        external
        view
        returns (uint256);

    /// @dev Trigger interest accrual and return the current borrow balance.
    function borrowBalanceCurrent(uint256 positionId, address token)
        external
        returns (uint256);

    /// @dev Borrow tokens from the bank.
    function borrow(address token, uint256 amount) external;

    /// @dev Repays tokens to the bank.
    function repay(address token, uint256 amountCall) external;

    /// @dev Transmit user assets to the spell.
    function transmit(address token, uint256 amount) external;

    /// @dev Put more collateral for users.
    function putCollateral(
        address collToken,
        uint256 collId,
        uint256 amountCall
    ) external;

    /// @dev Take some collateral back.
    function takeCollateral(
        address collToken,
        uint256 collId,
        uint256 amount
    ) external;

    /// @dev Liquidate a position.
    function liquidate(
        uint256 positionId,
        address debtToken,
        uint256 amountCall
    ) external;

    function getBorrowETHValue(uint256 positionId)
        external
        view
        returns (uint256);

    function getCollateralETHValue(uint256 positionId)
        external
        view
        returns (uint256);

    function accrue(address token) external;

    function nextPositionId() external view returns (uint256);

    /// @dev Return current position information.
    function getCurrentPositionInfo()
        external
        view
        returns (
            address owner,
            address collToken,
            uint256 collId,
            uint256 collateralSize
        );

    function support(address token) external view returns (bool);

    function setAllowContractCalls(bool ok) external;

    function setWhitelistUsers(
        address[] calldata users,
        bool[] calldata statuses
    ) external;

  /// @dev Return whitelist status from user
  function whitelistedUsers(address user) external view returns (bool);

  /// @dev Return credit limit from user address and token.
  /// NOTE: Credit limits are only applied specifically for whitelisted users.
  function whitelistedUserCreditLimits(address user, address token) external returns (uint);

    function allowContractCalls() external view returns (bool);

    function governor() external view returns (address);

    function oracle() external view returns (address);

    struct CreditLimit{
        address user;
        address token;
        uint limit;
        address origin;
    }
    function setCreditLimits(CreditLimit[] memory _creditLimits) external;

/// @dev Return whether `msgSender` can call HomoraBank by `origin` address
  function whitelistedContractWithTxOrigin(address msgSender, address origin)
    external
    returns (bool);

  /// @dev Set whether `contract` can call HomoraBank by `origin` address
  /// @param _contracts list of contracts to set whitelist
  /// @param _origins list of tx origins to whitelist for their corresponding contract addresses
  /// @param _statuses list of statuses to change to
  function setWhitelistContractWithTxOrigin(
    address[] calldata _contracts,
    address[] calldata _origins,
    bool[] calldata _statuses
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "IERC1155.sol";
import "IERC20.sol";

import "IBoostedMasterChefJoe.sol";
import "IERC20Wrapper.sol";
import "IGovernable.sol";

interface IWBoostedMasterChefJoeWorker is IERC1155, IERC20Wrapper, IGovernable {
  /// @dev Return TraderJoe masterChef
  function chef() external view returns (IBoostedMasterChefJoe);

  /// @dev Return TraderJoe token
  function joe() external view returns (IERC20);

  /// @dev Return the current accrue joe per share in this contract
  function accJoePerShare() external view returns (uint);

  /// @dev Return pool id supported in this contract
  function chefPoolId() external view returns (uint);

  /// @dev Return lp token of `chefPoolId`
  function lpToken() external view returns (address);

  /// @dev Encode pid, joePerShare to ERC1155 token id
  /// @param pid Pool id (16-bit)
  /// @param joePerShare Joe amount per share, multiplied by 1e18 (240-bit)
  function encodeId(uint pid, uint joePerShare) external pure returns (uint id);

  /// @dev Decode ERC1155 token id to pid, joePerShare
  /// @param id Token id
  function decodeId(uint id) external pure returns (uint pid, uint joePerShare);

  /// @dev Return the underlying ERC-20 for the given ERC-1155 token id.
  function getUnderlyingToken(uint) external view override returns (address);

  /// @dev Return the conversion rate from ERC-1155 to ERC-20, multiplied by 2**112.
  function getUnderlyingRate(uint) external pure override returns (uint);

  /// @dev Mint ERC1155 token for the given ERC20 token.
  /// @param _pid Pool id
  /// @param _amount Token amount to wrap
  function mint(uint _pid, uint _amount) external returns (uint id);

  /// @dev Burn ERC1155 token to redeem ERC20 token back.
  /// @param _id Token id
  /// @param _amount Token amount to burn
  function burn(uint _id, uint _amount) external returns (uint pid);

  function recover(address token, uint amount) external;

  function recoverETH(uint amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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

pragma solidity ^0.8.17;

interface IBoostedMasterChefJoe {
  /// @notice Address of MCJV2 contract
  function MASTER_CHEF_V2() external view returns (address);

  /// @notice Address of JOE contract
  function JOE() external view returns (address);

  /// @notice Address of veJOE contract
  function VEJOE() external view returns (address);

  /// @notice The index of BMCJ master pool in MCJV2
  function MASTER_PID() external view returns (uint);

  /// @notice Info of each BMCJ pool
  function poolInfo(uint pid)
    external
    view
    returns (
      address lpToken,
      uint96 allocPoint,
      uint accJoePerShare,
      uint accJoePerFactorPerShare,
      uint64 lastRewardTimestamp,
      address rewarder,
      uint32 veJoeShareBp,
      uint totalFactor,
      uint totalLpSupply
    );

  /// @notice Info of each user that stakes LP tokens
  function userInfo(uint, address)
    external
    view
    returns (
      uint amount,
      uint rewardDebt,
      uint factor
    );

  /// @dev Total allocation points. Must be the sum of all allocation points in all pools
  function totalAllocPoint() external view returns (uint);

  function claimableJoe(uint, address) external returns (uint);

  function init(address _dummyToken) external;

  /// @notice Add a new LP to the pool. Can only be called by the owner.
  /// @param _allocPoint AP of the new pool.
  /// @param _veJoeShareBp Share of rewards allocated in proportion to user's liquidity
  /// and veJoe balance
  /// @param _lpToken Address of the LP ERC-20 token.
  /// @param _rewarder Address of the rewarder delegate.
  function add(
    uint96 _allocPoint,
    uint32 _veJoeShareBp,
    address _lpToken,
    address _rewarder
  ) external;

  /// @notice Update the given pool's JOE allocation point and `IRewarder` contract. Can only be called by the owner.
  /// @param _pid The index of the pool. See `poolInfo`
  /// @param _allocPoint New AP of the pool
  /// @param _veJoeShareBp Share of rewards allocated in proportion to user's liquidity
  /// and veJoe balance
  /// @param _rewarder Address of the rewarder delegate
  /// @param _overwrite True if _rewarder should be `set`. Otherwise `_rewarder` is ignored
  function set(
    uint _pid,
    uint96 _allocPoint,
    uint32 _veJoeShareBp,
    address _rewarder,
    bool _overwrite
  ) external;

  /// @notice Deposit LP tokens to BMCJ for JOE allocation
  /// @param _pid The index of the pool. See `poolInfo`
  /// @param _amount LP token amount to deposit
  function deposit(uint _pid, uint _amount) external;

  /// @notice Withdraw LP tokens from BMCJ
  /// @param _pid The index of the pool. See `poolInfo`
  /// @param _amount LP token amount to withdraw
  function withdraw(uint _pid, uint _amount) external;

  /// @notice Updates factor after after a veJoe token operation.
  /// This function needs to be called by the veJoe contract after
  /// every mint / burn.
  /// @param _user The users address we are updating
  /// @param _newVeJoeBalance The new balance of the users veJoe
  function updateFactor(address _user, uint _newVeJoeBalance) external;

  /// @notice Withdraw without caring about rewards (EMERGENCY ONLY)
  /// @param _pid The index of the pool. See `poolInfo`
  function emergencyWithdraw(uint _pid) external;

  /// @notice Calculates and returns the `amount` of JOE per second
  /// @return amount The amount of JOE emitted per second
  function joePerSec() external view returns (uint amount);

  /// @notice View function to see pending JOE on frontend
  /// @param _pid The index of the pool. See `poolInfo`
  /// @param _user Address of user
  /// @return pendingJoe JOE reward for a given user.
  /// @return bonusTokenAddress The address of the bonus reward.
  /// @return bonusTokenSymbol The symbol of the bonus token.
  /// @return pendingBonusToken The amount of bonus rewards pending.
  function pendingTokens(uint _pid, address _user)
    external
    view
    returns (
      uint pendingJoe,
      address bonusTokenAddress,
      string memory bonusTokenSymbol,
      uint pendingBonusToken
    );

  /// @notice Returns the number of BMCJ pools.
  /// @return pools The amount of pools in this farm
  function poolLength() external view returns (uint pools);

  /// @notice Update reward variables for all pools. Be careful of gas spending!
  function massUpdatePools() external;

  /// @notice Update reward variables of the given pool
  /// @param _pid The index of the pool. See `poolInfo`
  function updatePool(uint _pid) external;

  /// @notice Harvests JOE from `MASTER_CHEF_V2` MCJV2 and pool `MASTER_PID` to this BMCJ contract
  function harvestFromMasterChef() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IERC20Wrapper {
  /// @dev Return the underlying ERC-20 for the given ERC-1155 token id.
  function getUnderlyingToken(uint id) external view returns (address);

  /// @dev Return the conversion rate from ERC-1155 to ERC-20, multiplied by 2**112.
  function getUnderlyingRate(uint id) external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IGovernable {
  function governor() external view returns (address);

  function pendingGovernor() external view returns (address);

  function setPendingGovernor(address _pendingGovernor) external;

  function acceptGovernor() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IMiniChefV2PNG {
  function REWARD() external view returns (address);

  function poolInfo(uint pid)
    external
    view
    returns (
      uint128 accRewardPerShare,
      uint64 lastRewardTime,
      uint64 allocPoint
    );

  function lpToken(uint pid) external view returns (address);

  function lpTokens() external view returns (address[] memory);

  function rewarder(uint pid) external view returns (address);

  function deposit(
    uint pid,
    uint amount,
    address to
  ) external;

  function withdraw(
    uint pid,
    uint amount,
    address to
  ) external;

  function userInfo(uint pid, address user) external view returns (uint, int);

  function withdrawAndHarvest(
    uint pid,
    uint amount,
    address to
  ) external;

  function harvest(uint pid, address to) external;

  function poolLength() external view returns (uint);

  function updatePool(uint pid)
    external
    returns (
      uint128 accRewardPerShare,
      uint64 lastRewardTime,
      uint64 allocPoint
    );

  /// @notice View function to see pending reward on frontend.
  /// @param _pid The index of the pool.
  /// @param _user Address of user.
  /// @return pending reward for a given user.
  function pendingReward(uint _pid, address _user) external view returns (uint pending);

  function rewardsExpiration() external view returns (uint);

  function totalAllocPoint() external view returns (uint);

  function rewardPerSecond() external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "IMiniChefV2PNG.sol";
import "IERC1155.sol";
import "IERC20.sol";
import "IERC20Wrapper.sol";
import "IGovernable.sol";

interface IWMiniChefV2PNG is IERC1155, IERC20Wrapper, IGovernable {
  /// @dev Return Pangolin minichef
  function chef() external view returns (IMiniChefV2PNG);

  /// @dev Return Pangolin token
  function png() external view returns (IERC20);

  /// @dev Encode pid, pngPerShare to ERC1155 token id
  /// @param pid Pool id (16-bit)
  /// @param pngPerShare PNG amount per share, multiplied by 1e18 (240-bit)
  function encodeId(uint pid, uint pngPerShare) external pure returns (uint id);

  /// @dev Decode ERC1155 token id to pid, pngPerShare
  /// @param id Token id
  function decodeId(uint id) external pure returns (uint pid, uint pngPerShare);

  /// @dev Return the underlying ERC-20 for the given ERC-1155 token id.
  function getUnderlyingToken(uint) external view override returns (address);

  /// @dev Return the conversion rate from ERC-1155 to ERC-20, multiplied by 2**112.
  function getUnderlyingRate(uint) external pure override returns (uint);

  /// @dev Mint ERC1155 token for the given ERC20 token.
  /// @param _pid Pool id
  /// @param _amount Token amount to wrap
  function mint(uint _pid, uint _amount) external returns (uint id);

  /// @dev Burn ERC1155 token to redeem ERC20 token back.
  /// @param _id Token id
  /// @param _amount Token amount to burn
  function burn(uint _id, uint _amount) external returns (uint pid);

  function recover(address token, uint amount) external;

  function recoverETH(uint amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IUniswapRouterV2 {
    function factory() external view returns (address);
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

    function addLiquidityETH(
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

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IBaseOracle {
    /// @dev Return the value of the given input as ETH per unit, multiplied by 2**112.
    /// @param token The ERC-20 token to check the value.
    function getETHPx(address token) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "IERC20Upgradeable.sol";
import "SafeMathUpgradeable.sol";
import "MathUpgradeable.sol";
import "AddressUpgradeable.sol";
import "PausableUpgradeable.sol";
import "Pausable.sol";
import "SafeERC20Upgradeable.sol";
import "Initializable.sol";
import "IStrategy.sol";

import "SettAccessControl.sol";

/*
    ===== Base Strategy =====
    Common base class for all Sett strategies

    Changelog
    V1.1
    - Verify amount unrolled from strategy positions on withdraw() is within a threshold relative to the requested amount as a sanity check
    - Add version number which is displayed with baseStrategyVersion(). If a strategy does not implement this function, it can be assumed to be 1.0

    V1.2
    - Remove idle want handling from base withdraw() function. This should be handled as the strategy sees fit in _withdrawSome()
*/
abstract contract BaseStrategy is Pausable, SettAccessControl {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;

    event Withdraw(uint256 amount);
    event WithdrawAll(uint256 balance);
    event WithdrawOther(address token, uint256 amount);
    event SetStrategist(address strategist);
    event SetGovernance(address governance);
    event SetController(address controller);   
    event Harvest(uint256 harvested, uint256 indexed blockNumber);
    

    address public want;
    address public depositToken;
    address public vault;

    uint256 public withdrawalFee;

    uint256 public constant MAX_FEE = 10000;    

    address public controller;
    address public guardian;

    uint256 public withdrawalMaxDeviationThreshold;    
    address public stableToken;
    address public constant USDC = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E; //MAINNET AVALANCHE

    function __BaseStrategy_init(
        address _governance,
        address _strategist,
        address _controller,
        address _keeper,
        address _guardian
    ) public initializer whenNotPaused {
        governance = _governance;
        strategist = _strategist;
        keeper = _keeper;
        controller = _controller;
        guardian = _guardian;
        withdrawalMaxDeviationThreshold = 200;
    }

    // ===== Modifiers =====

    function _onlyController() internal view {
        require(msg.sender == controller, "onlyController");
    }

    function _onlyAuthorizedActorsOrController() internal view {
        require(msg.sender == keeper || msg.sender == governance || msg.sender == controller, "onlyAuthorizedActorsOrController");
    }

    function _onlyControllerOrGovernor() internal view {
        require(msg.sender == governance || msg.sender == controller, "onlyControllerOrGovernor");
    }

    function _onlyAuthorizedPausers() internal view {
        require(msg.sender == guardian || msg.sender == governance, "onlyPausers");
    }

    /// ===== View Functions =====
    function baseStrategyVersion() public pure returns (string memory) {
        return "1.2";
    }

    /// @notice Get the balance of want held idle in the Strategy
    function balanceOfWant() public view returns (uint256) {
        return IERC20Upgradeable(want).balanceOf(address(this));
    }

    /// @notice Get the total balance of want realized in the strategy, whether idle or active in Strategy positions.
    function balanceOf() public virtual view returns (uint256) {
        return balanceOfPool();
    }

    /// ===== Permissioned Actions: Governance =====

    function setGuardian(address _guardian) external {
        _onlyGovernance();
        guardian = _guardian;
    }


    function setController(address _controller) external {
        _onlyGovernance();
        controller = _controller;
    }

    function setWithdrawalMaxDeviationThreshold(uint256 _threshold) external {
        _onlyGovernance();
        require(_threshold <= MAX_FEE, "base-strategy/excessive-max-deviation-threshold");
        withdrawalMaxDeviationThreshold = _threshold;
    }

    function deposit() public virtual whenNotPaused {
        _onlyControllerOrGovernor();
        uint256 _stableToken = IERC20Upgradeable(stableToken).balanceOf(address(this));
        uint256 _depositToken = IERC20Upgradeable(depositToken).balanceOf(address(this));
        if (_stableToken > 0 || _depositToken > 0) {
            _deposit();
        }
        _postDeposit();
    }

    // ===== Permissioned Actions: Controller =====

    /// @notice Controller-only function to Withdraw partial funds, normally used with a vault withdrawal
    function withdrawAll() external virtual whenNotPaused {
        _onlyController();

        _withdrawAll();
        uint256 _toWithdraw = IERC20Upgradeable(depositToken).balanceOf(address(this));
        _transferToVault(_toWithdraw);    
    }

     /// @notice Controller-only function to Withdraw partial funds, normally used with a vault withdrawal
    function withdrawAllForRebalance() external virtual whenNotPaused {
        _onlyController();
        _withdrawAll();
        uint256 _toWithdraw = IERC20Upgradeable(depositToken).balanceOf(address(this));
        _transferToVault(_toWithdraw);    
    }


    /// @notice Withdraw partial funds from the strategy, unrolling from strategy positions as necessary
    /// @notice Processes withdrawal fee if present
    /// @dev If it fails to recover sufficient funds (defined by withdrawalMaxDeviationThreshold), the withdrawal should fail so that this unexpected behavior can be investigated
    function withdraw(uint256 _amount) external virtual whenNotPaused {
        _onlyController();

        // Withdraw from strategy positions, typically taking from any idle want first.
        _withdrawSome(_amount);
                
         uint256 _postWithdraw = IERC20Upgradeable(depositToken).balanceOf(address(this));

        // Sanity check: Ensure we were able to retrieve sufficent want from strategy positions
        // If we end up with less than the amount requested, make sure it does not deviate beyond a maximum threshold
        if (_postWithdraw < _amount) {
            uint256 diff = _diff(_amount, _postWithdraw);

            // Require that difference between expected and actual values is less than the deviation threshold percentage
            require(diff <= _amount.mul(withdrawalMaxDeviationThreshold).div(MAX_FEE), "base-strategy/withdraw-exceed-max-deviation-threshold");
        }

        // Return the amount actually withdrawn if less than amount requested
        uint256 _toWithdraw = MathUpgradeable.min(_postWithdraw, _amount);

        // Process withdrawal fee - No withdrawal fee now
        // uint256 _fee = _processWithdrawalFee(_toWithdraw);
        uint256 _fee = 0;

        // Transfer remaining to Vault to handle withdrawal
        _transferToVault(_toWithdraw.sub(_fee));
    }

    // NOTE: must exclude any tokens used in the yield
    // Controller role - withdraw should return to Controller
    function withdrawOther(address _asset) external virtual whenNotPaused returns (uint256 balance) {
        _onlyController();

        balance = IERC20Upgradeable(_asset).balanceOf(address(this));
        IERC20Upgradeable(_asset).safeTransfer(controller, balance);
    }

    /// ===== Permissioned Actions: Authoized Contract Pausers =====

    function pause() external {
        _onlyAuthorizedPausers();
        _pause();
    }

    function unpause() external {
        _onlyGovernance();
        _unpause();
    }

    /// ===== Internal Helper Functions =====

    function _transferToVault(uint256 _amount) internal {
        address _vault = vault;
        require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds
        IERC20Upgradeable(depositToken).safeTransfer(_vault, _amount);
    }

    /// @notice Utility function to diff two numbers, expects higher value in first position
    function _diff(uint256 a, uint256 b) internal pure returns (uint256) {
        require(a >= b, "diff/expected-higher-number-in-first-position");
        return a.sub(b);
    }


    // ===== Abstract Functions: To be implemented by specific Strategies =====

    /// @dev Internal deposit logic to be implemented by Stratgies
    function _deposit() internal virtual;

    function _postDeposit() internal virtual {
        //no-op by default
    }


    /// @dev Internal logic for strategy migration. Should exit positions as efficiently as possible
    function _withdrawAll() internal virtual;

    /// @dev Internal logic for partial withdrawals. Should exit positions as efficiently as possible.
    /// @dev The withdraw() function shell automatically uses idle want in the strategy before attempting to withdraw more using this
    function _withdrawSome(uint256 _amount) internal virtual returns (uint256);

    /// @dev Realize returns from positions
    /// @dev Returns can be reinvested into positions, or distributed in another fashion
    /// @dev Performance fees should also be implemented in this function
    /// @dev Override function stub is removed as each strategy can have it's own return signature for STATICCALL
    // function harvest() external virtual;

    /// @dev User-friendly name for this strategy for purposes of convenient reading
    function getName() external virtual pure returns (string memory);

    /// @dev Balance of want currently held in strategy positions
    function balanceOfPool() public virtual view returns (uint256);

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "ContextUpgradeable.sol";
import "Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "IERC20Upgradeable.sol";
import "draft-IERC20PermitUpgradeable.sol";
import "AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IStrategy {
    function want() external view returns (address);

    function deposit() external;

    // NOTE: must exclude any tokens used in the yield
    // Controller role - withdraw should return to Controller
    function withdrawOther(address) external;

    // Controller | Vault role - withdraw should always return to Vault
    function withdraw(uint256) external;

    // Controller | Vault role - withdraw should always return to Vault
    function withdrawAll() external;

    function withdrawAllForRebalance() external;

    function balanceOf() external view returns (uint256);

    function balanceOfPoolInt() external view returns (uint256);
    function balanceOfPool() external view returns (uint256);

    function getName() external pure returns (string memory);

    function setStrategist(address _strategist) external;

    function setWithdrawalFee(uint256 _withdrawalFee) external;

    function setPerformanceFeeStrategist(uint256 _performanceFeeStrategist) external;

    function setPerformanceFeeGovernance(uint256 _performanceFeeGovernance) external;

    function setGovernance(address _governance) external;

    function setController(address _controller) external;

    function tend() external;

    function harvest() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "Initializable.sol";

/*
    Common base for permissioned roles throughout Sett ecosystem
*/
contract SettAccessControl is Initializable {
    address public governance;
    address public strategist;
    address public keeper;

    // ===== MODIFIERS =====
    function _onlyGovernance() internal view {
        require(msg.sender == governance, "onlyGovernance");
    }

    function _onlyGovernanceOrStrategist() internal view {
        require(msg.sender == strategist || msg.sender == governance, "onlyGovernanceOrStrategist");
    }

    function _onlyAuthorizedActors() internal view {
        require(msg.sender == governance, "onlyAuthorizedActors");
    }

    // ===== PERMISSIONED ACTIONS =====

    /// @notice Change strategist address
    /// @notice Can only be changed by governance itself
    function setStrategist(address _strategist) external {
        _onlyGovernance();
        strategist = _strategist;
    }

    /// @notice Change keeper address
    /// @notice Can only be changed by governance itself
    function setKeeper(address _keeper) external {
        _onlyGovernance();
        keeper = _keeper;
    }

    /// @notice Change governance address
    /// @notice Can only be changed by governance itself
    function setGovernance(address _governance) public {
        _onlyGovernance();
        governance = _governance;
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "Ownable.sol";
import "SafeMath.sol";
import "FixedPoint.sol";
import "UQ112x112.sol";
import "IPairOracle.sol";
import "IUniswapPair.sol";

contract PairOracle is Ownable, IPairOracle {
    // using FixedPoint for *;
    using SafeMath for uint256;

    uint256 public PERIOD = 79200; // 22-hour TWAP (time-weighted average price)

    IUniswapPair public immutable pair;
    address public immutable token0;
    address public immutable token1;

    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    uint32 public blockTimestampLast;
    FixedPoint.uq112x112 public price0Average;
    FixedPoint.uq112x112 public price1Average;

    // Operator is only for updating dynamic TWAP period and doesn't have any significant role or hold any fund.
    address public operator;

    event PeriodUpdated(uint256 newPeriod);
    event ForceUpdateAndSetPeriod(uint256 newPeriod);
    event OperatorUpdated(address indexed newOperator);

    modifier onlyOwnerOrOperator() {
        require(msg.sender == owner() || msg.sender == operator, "Not owner or operator");
        _;
    }

    constructor(address pairAddress, address _operator) {
        IUniswapPair _pair = IUniswapPair(pairAddress);
        pair = _pair;
        token0 = _pair.token0();
        token1 = _pair.token1();
        price0CumulativeLast = _pair.price0CumulativeLast(); // Fetch the current accumulated price value (1 / 0)
        price1CumulativeLast = _pair.price1CumulativeLast(); // Fetch the current accumulated price value (0 / 1)
        uint112 reserve0;
        uint112 reserve1;
        (reserve0, reserve1, blockTimestampLast) = _pair.getReserves();
        require(reserve0 != 0 && reserve1 != 0, "PairOracle: NO_RESERVES"); // Ensure that there's liquidity in the pair
        operator = _operator;
    }

    function forceUpdateAndSetPeriod(uint256 _period) external onlyOwnerOrOperator {
        (uint256 price0Cumulative, uint256 price1Cumulative, uint32 blockTimestamp) = currentCumulativePrices(
            address(pair)
        );
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // Overflow is desired

        // Overflow is desired, casting never truncates
        // Cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
        price0Average = FixedPoint.uq112x112(uint224((price0Cumulative - price0CumulativeLast) / timeElapsed));
        price1Average = FixedPoint.uq112x112(uint224((price1Cumulative - price1CumulativeLast) / timeElapsed));
        price0CumulativeLast = price0Cumulative;
        price1CumulativeLast = price1Cumulative;
        blockTimestampLast = blockTimestamp;

        PERIOD = _period;

        emit ForceUpdateAndSetPeriod(PERIOD);
    }

    function setPeriod(uint256 _period) external onlyOwner {
        PERIOD = _period;
        emit PeriodUpdated(PERIOD);
    }

    function getData() public view returns( 
        uint256 pc1, 
        uint256 pc2,
        uint256 pa1,
        uint256 pa2
        ) {
        return (
        price0CumulativeLast,
        price1CumulativeLast,
        uint256(FixedPoint.decode(price0Average)),
        uint256(FixedPoint.decode(price1Average))
        );
    }

    function update() external override {
        (uint256 price0Cumulative, uint256 price1Cumulative, uint32 blockTimestamp) = currentCumulativePrices(
            address(pair)
        );
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // Overflow is desired

        // Ensure that at least one full period has passed since the last update
        // require(timeElapsed >= PERIOD, "PairOracle: PERIOD_NOT_ELAPSED");

        // Overflow is desired, casting never truncates
        // Cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
        price0Average = FixedPoint.uq112x112(uint224((price0Cumulative - price0CumulativeLast) / timeElapsed));
        price1Average = FixedPoint.uq112x112(uint224((price1Cumulative - price1CumulativeLast) / timeElapsed));
        price0CumulativeLast = price0Cumulative;
        price1CumulativeLast = price1Cumulative;
        blockTimestampLast = blockTimestamp;
    }

    // Note this will always return 0 before update has been called successfully for the first time.
    function consult(address token, uint256 amountIn) external view override returns (uint256 amountOut) {
        if (token == token0) {
            amountOut = uint256(FixedPoint.decode144(FixedPoint.mul(price0Average, amountIn)));
        } else {
            require(token == token1, "PairOracle: INVALID_TOKEN");
            amountOut = uint256(FixedPoint.decode144(FixedPoint.mul(price1Average, amountIn)));
        }
    }

    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2**32);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(address _pair)
        internal
        view
        returns (
            uint256 price0Cumulative,
            uint256 price1Cumulative,
            uint32 blockTimestamp
        )
    {
        blockTimestamp = currentBlockTimestamp();
        IUniswapPair uniswapPair = IUniswapPair(_pair);
        price0Cumulative = uniswapPair.price0CumulativeLast();
        price1Cumulative = uniswapPair.price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 _blockTimestampLast) = uniswapPair.getReserves();
        if (_blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - _blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative += uint256(FixedPoint.fraction(reserve1, reserve0)._x) * (timeElapsed);
            // counterfactual
            price1Cumulative += uint256(FixedPoint.fraction(reserve0, reserve1)._x) * (timeElapsed);
        }
    }

    function setOperator(address _operator) public onlyOwner {
        operator = _operator;
        emit OperatorUpdated(operator);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.17;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "Babylonian.sol";

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint256 _x;
    }

    uint8 private constant RESOLUTION = 112;
    uint256 private constant Q112 = uint256(1) << RESOLUTION;
    uint256 private constant Q224 = Q112 << RESOLUTION;

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function div(uq112x112 memory self, uint112 x) internal pure returns (uq112x112 memory) {
        require(x != 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112(self._x / uint224(x));
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint256 y) internal pure returns (uq144x112 memory) {
        uint256 z;
        require(y == 0 || (z = uint256(self._x) * y) / y == uint256(self._x), "FixedPoint: MULTIPLICATION_OVERFLOW");
        return uq144x112(z);
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // equivalent to encode(numerator).div(denominator)
    function fraction(uint112 numerator, uint112 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112((uint224(numerator) << RESOLUTION) / denominator);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }

    // take the reciprocal of a UQ112x112
    function reciprocal(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        require(self._x != 0, "FixedPoint: ZERO_RECIPROCAL");
        return uq112x112(uint224(Q224 / self._x));
    }

    // square root of a UQ112x112
    function sqrt(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(Babylonian.sqrt(uint256(self._x)) << 56));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
// pragma experimental ABIEncoderV2;

interface IPairOracle {

    function consult(address token, uint256 amountIn) external view returns (uint256 amountOut);

    function update() external;

    function getData() external view returns( 
        uint256 pc1, 
        uint256 pc2,
        uint256 pa1,
        uint256 pa2
        );

    function forceUpdateAndSetPeriod(uint256 _period) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IUniswapPair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
    
    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function getTokenWeights() external view returns (uint32 tokenWeight0, uint32 tokenWeight1);
}
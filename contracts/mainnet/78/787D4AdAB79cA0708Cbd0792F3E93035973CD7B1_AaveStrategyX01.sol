// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Funding.sol";
import "./ILendingPool.sol";
import "./IAaveProtocolDataProvider.sol";
import './SafeMath.sol';
import './ISwapStrategy01.sol';
import './IStakedToken.sol';

struct AavePair {
    address basic;
    address am;
    address variableDebtm;
    uint256 ltv;
    uint256 liqvi;
}

contract AaveStrategyX01 is Funding {

    using SafeMath for uint256;

    ISwapStrategy01 public SwapStrategy = ISwapStrategy01(0x3B986244E434B2BE4D58d0A6d3A3Dd1Fb64A04EE);
    function set_SwapStrategy(address _contract) public onlyOwner() {        
        SwapStrategy = ISwapStrategy01(_contract);
    }

    // AavePair storage userStaking = userStakingOf[stakingId];
    mapping(string => AavePair) public AavePairOf;

    // ADMIN ONLY
    function _aave_add_coin(
            string memory name,
            address basic,
            address am,
            address variableDebtm,
            uint256 ltv,
            uint256 liqvi
        ) private {
            AavePairOf[name] = AavePair ({
                basic: basic,
                am: am,
                variableDebtm: variableDebtm,
                ltv: ltv,
                liqvi: liqvi
            });
        assets.push(am);
        assets.push(variableDebtm);
    }

    // ETH
    address public AAVE_LENDING_POOL = 0x794a61358D6845594F94dc1DB02A252b5b4814aD; // PROXY
    address public AAVE_STAKED_TOKEN = 0x01D83Fe6A10D2f2B7AF17034343746188272cAc9; // MATIC STAKE
    address public AAVE_DATA_PROVIDER = 0x69FA688f1Dc47d4B5d8029D5a35FB7a548310654; // AaveProtocolDataProvider

    IAaveProtocolDataProvider AaveDataProvider = IAaveProtocolDataProvider(AAVE_DATA_PROVIDER);

    IERC20 public WMATIC = IERC20(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);

    string public AAVE_BASE_COIN;

    /* ADMIN IS UExecutor */
    constructor(string memory _AAVE_BASE_COIN) Admin(msg.sender) {
        AAVE_BASE_COIN = _AAVE_BASE_COIN;       
        _init_aave();
    }

    function _init_aave() private {
        _aave_add_coin(
            "WBTC",
            0x50b7545627a5162F82A992c33b87aDc75187B218, // WBTC
            0x078f358208685046a11C85e8ad32895DED33A249, // amWBTC
            0x92b42c66840C7AD907b4BF74879FF3eF7c529473, // variableDebtmWBTC
            6000,
            7500
        );
        _aave_add_coin(
            "DAI",
            0xd586E7F844cEa2F87f50152665BCbc2C279D8d70, // DAI
            0x82E64f49Ed5EC1bC6e43DAD4FC8Af9bb3A2312EE, // amDAI
            0x8619d80FB0141ba7F184CbF22fd724116D9f7ffC, // variableDebtmDAI
            7500,
            8000
        );
        _aave_add_coin(
            "USDC",
            0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E, // USDC
            0x625E7708f30cA75bfd92586e17077590C60eb4cD, // amUSDC
            0xFCCf3cAbbe80101232d343252614b6A3eE81C989, // variableDebtmUSDC
            7500,
            8000
        );
        _aave_add_coin(
            "WETH",
            0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB, // WETH
            0x53f7c5869a859F0AeC3D334ee8B4Cf01E3492f21, // amWETH
            0x4e575CacB37bc1b5afEc68a0462c4165A5268983, // variableDebtmWETH
            8000,
            8250
        );
    }

    // 
    // BSC + assets
    //
    ILendingPool private AaveLP = ILendingPool(AAVE_LENDING_POOL);
    IStakedToken private StakedToken = IStakedToken(AAVE_STAKED_TOKEN); // MATIC

    // TODO this istemporary ...
    address[] public assets;
    function aave_matic_claim() public onlyOwner() returns (uint256){        
        return aave_matic_claim_to(address(this));
    }
    function aave_matic_claim_to(address to) public onlyOwner() returns (uint256){
        // claim MATIC
        uint256 amount = StakedToken.getRewardsBalance(assets, to);
        StakedToken.claimRewards(assets, amount, to);
        return amount;
    }


    // FUNCTIONS
    function simple_deposit (string memory Coin) public onlyOwner() {
        _aave_deposit(Coin, IERC20(AavePairOf[Coin].basic).balanceOf(address(this)));
    }


    // MAIN
    function _aave_deposit(string memory Coin, uint256 tokenAmt) private {
        AavePair storage AAVE = AavePairOf[Coin];
        IERC20 SToken = IERC20(AAVE.basic);
        require(SToken.balanceOf(address(this)) >= tokenAmt);
        if (SToken.allowance(address(this), AAVE_LENDING_POOL) < tokenAmt) {
            require(SToken.approve(AAVE_LENDING_POOL, type(uint256).max), "approve error");
        }
        // approve
        AaveLP.deposit(AAVE.basic, tokenAmt, address(this), 0);
    }
    function _aave_withdraw(string memory Coin, uint256 tokenAmt) private {
        AavePair storage AAVE = AavePairOf[Coin];
        AaveLP.withdraw(AAVE.basic, tokenAmt, address(this));        
    }

    function _aave_borrow(string memory Coin, uint256 tokenAmt) private {
        AavePair storage AAVE = AavePairOf[Coin];
        AaveLP.borrow(AAVE.basic, tokenAmt, 2, 0, address(this));
    }

    function _aave_repay(string memory Coin, uint256 tokenAmt) private {
        AavePair storage AAVE = AavePairOf[Coin];
        IERC20 SToken = IERC20(AAVE.basic);
        require(SToken.balanceOf(address(this)) >= tokenAmt);
        if (SToken.allowance(address(this), AAVE_LENDING_POOL) < tokenAmt) {
            require(SToken.approve(AAVE_LENDING_POOL, type(uint256).max), "approve error");
        }

        // approve
        AaveLP.repay(AAVE.basic, tokenAmt, 2, address(this));
    }

    function aave_loop_deposit_001(string memory Coin) private returns(uint256) {
        AavePair storage AAVE = AavePairOf[Coin];
        IERC20 SToken = IERC20(AAVE.basic);

        uint256 tokenAmt = SToken.balanceOf(address(this));

        // 65% => max 70% for BTC
        _aave_deposit(Coin, tokenAmt);
        uint256 B1 = tokenAmt.mul(AAVE.ltv - 100).div(10000);
        _aave_borrow(Coin, B1);

        // _aave_withdraw(Coin, B1);
        return B1;
    }
    function aave_loop_deposit_002(string memory Coin, uint256 tokenAmt) private returns(uint256) {
        AavePair storage AAVE = AavePairOf[Coin];

        // 65% => max 70% for BTC
        _aave_deposit(Coin, tokenAmt);
        uint256 B1 = tokenAmt.mul(AAVE.ltv - 100).div(10000);
        _aave_borrow(Coin, B1);

        // _aave_withdraw(Coin, B1);
        return B1;
    }
    function _loop_deposit_x(string memory Coin, uint Count, uint256 x1) private {
        for(uint256 i; i < Count; i++){
            x1 = aave_loop_deposit_002(Coin, x1);
        }
        _aave_deposit(Coin, x1);
    }


    uint256 private _last_deposit_loop;
    function aave_loop_deposit_x(string memory Coin, uint Count) public onlyOwner() {
        uint256 x1 = aave_loop_deposit_001(Coin);
        _last_deposit_loop = Count;
        _loop_deposit_x(Coin, Count, x1);
    }

    /**
     *
     *   Strength of deposit
     *
     */
    function aave_corrector_add(string memory Coin) public onlyOwner() {
        uint256 borrow = _get_free_to_borrow(Coin);
        require( borrow > 0, "not enough tokens in the pool");
        _last_deposit_loop = _last_deposit_loop + 1;
        _aave_borrow(Coin, borrow);
        _aave_deposit(Coin, borrow);
    }

    function aave_corrector_remove(string memory Coin) public onlyOwner() {
        require( _get_free_to_withdraw(Coin) > 0, "not enough tokens in the pool");
        _last_deposit_loop = _last_deposit_loop - 1;
        _withdraw_001(Coin);
    }

    /**
     *
     *   Matic Reinvest
     *
     */
    function aave_matic_claim_reinvest(string memory Coin, uint256 loopCount) public onlyOwner(){        
        uint256 matic = aave_matic_claim();
        if (WMATIC.allowance(address(this), address(SwapStrategy)) == 0) {
            require(WMATIC.approve(address(SwapStrategy), type(uint256).max), "approve error");
        }
        (uint256 amountOut) = SwapStrategy.swapTo(Coin, matic);
        _loop_deposit_x(Coin, loopCount, amountOut);
    }

    function aave_matic_reinvest_from_balance(string memory Coin, uint256 loopCount) public onlyOwner(){
        // swap WMATIC from balance and reinvest
        if (WMATIC.allowance(address(this), address(SwapStrategy)) < 1) {
            require(WMATIC.approve(address(SwapStrategy), type(uint256).max), "approve error");
        }
        require(WMATIC.balanceOf(address(this)) >= 100000);
        (uint256 amountOut) = SwapStrategy.swapTo( Coin, WMATIC.balanceOf(address(this)) );
        _loop_deposit_x(Coin, loopCount, amountOut);
    }

    function _withdraw_001(string memory Coin) private returns (uint256) {
        ( , , uint256 balance_variableDebtm, , uint256 free_to_withdraw, ) = aave_balances(Coin);            
        _aave_withdraw(Coin, free_to_withdraw);
        if (free_to_withdraw > balance_variableDebtm) {
            // can be close now ...
            if (balance_variableDebtm > 0) {
                _aave_repay(Coin, balance_variableDebtm);
            }
            balance_variableDebtm = 0;
        } else {
            _aave_repay(Coin, free_to_withdraw);
            balance_variableDebtm = balance_variableDebtm - free_to_withdraw;
        }
        return balance_variableDebtm;        
    }

    function aave_loop_withdraw_all(string memory Coin) public onlyOwner() {
        require( _get_free_to_withdraw(Coin) > 0, "not enough tokens in the pool");
        bool stop = true;
        while (stop) {
           if ( _withdraw_001(Coin) == 0) {
               (   ,
                   uint256 balance_am,
                   ,
                   ,
                   uint256 free_to_withdraw,
                   
               ) = aave_balances(Coin);
               if (free_to_withdraw == balance_am) {
                   _aave_withdraw(Coin, balance_am);
                   stop = false;
               } else if (balance_am == 0) {
                   stop = false;
               }
           }
        }
    }

    /* 
     *
     * part withdraw
     *
     */
    function aave_loop_withdraw_x(string memory Coin, address reciver, uint256 amount) public onlyOwner() returns (bool) {
        require(  _get_true_balanse(Coin) >= amount, "not enough tokens in the pool");
        AavePair storage AAVE = AavePairOf[Coin];
        aave_loop_withdraw_all(Coin);
        withdrawERC20sTo(reciver, IERC20(AAVE.basic), amount);
        if (_get_true_balanse(Coin) != amount) {
            aave_loop_deposit_x(Coin, _last_deposit_loop);
        }
        return true;
    }


    function _get_true_balanse(string memory Coin) private view returns (uint256) {
        AavePair storage AAVE = AavePairOf[Coin];
        address _user =         address(this);
        uint256 am =            IERC20(AAVE.am).balanceOf(_user);
        uint256 variableDebtm = IERC20(AAVE.variableDebtm).balanceOf(_user);
        return am - variableDebtm;
    }

    function _get_free_to_borrow(string memory Coin) private view returns (uint256) {
        AavePair storage AAVE = AavePairOf[Coin];
        address _user =         address(this);
        uint256 am =            IERC20(AAVE.am).balanceOf(_user);
        uint256 variableDebtm = IERC20(AAVE.variableDebtm).balanceOf(_user);
        return am.mul(AAVE.ltv - 100).div(10000) - variableDebtm;
    }

    // view #1 PRIVATE
    function _get_free_to_withdraw(string memory Coin) private view returns (uint256) {
        AavePair storage AAVE = AavePairOf[Coin];
        address _user =         address(this);
        uint256 am =            IERC20(AAVE.am).balanceOf(_user);
        uint256 variableDebtm = IERC20(AAVE.variableDebtm).balanceOf(_user);
        uint256 free_to_withdraw;
        if (variableDebtm > 0) {
            free_to_withdraw = am.mul(AAVE.liqvi - 100).div(10000) - variableDebtm;
        } else {
            free_to_withdraw = am;
        }
        return free_to_withdraw;
    }
    function aave_balances(string memory Coin) public view returns (
            uint256 balance_basic,
            uint256 balance_am,
            uint256 balance_variableDebtm,
            uint256 free_to_borrow,
            uint256 free_to_withdraw,
            uint256 true_balance
        ) {
        
        AavePair storage AAVE = AavePairOf[Coin];
        address _user = address(this);

        uint256 basic =         IERC20(AAVE.basic).balanceOf(_user);
        uint256 am =            IERC20(AAVE.am).balanceOf(_user);
        uint256 variableDebtm = IERC20(AAVE.variableDebtm).balanceOf(_user);

        free_to_borrow = am.mul(AAVE.ltv - 100).div(10000) - variableDebtm;

        if (variableDebtm > 0) {
            free_to_withdraw = am.mul(AAVE.liqvi - 100).div(10000) - variableDebtm;
        } else {
            free_to_withdraw = am;
        }

        balance_basic = basic;
        balance_am = am;
        balance_variableDebtm = variableDebtm;
        true_balance = balance_am - balance_variableDebtm;
    }

    // view #2 
    function aave_stat_balances() public view returns (
        uint256 matic,
        uint256 balance_basic,
        uint256 balance_am,
        uint256 balance_variableDebtm,
        uint256 free_to_borrow,
        uint256 free_to_withdraw,
        uint256 true_balance,
        // aave
        uint256 aave_healthFactor,
        uint256 aave_currentLiquidationThreshold,
        uint256 aave_ltv
        ) {
        matic = StakedToken.getRewardsBalance(assets, address(this));
        ( balance_basic,
          balance_am,
          balance_variableDebtm,
          free_to_borrow,
          free_to_withdraw,
          true_balance ) = aave_balances(AAVE_BASE_COIN);

          ( , , ,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        ) = AaveLP.getUserAccountData(address(this));
        aave_healthFactor = healthFactor;
        aave_currentLiquidationThreshold = currentLiquidationThreshold;
        aave_ltv = ltv;
    }



    function _matic_global(address _asset) private view returns (uint128) {
        (uint128 emissionPerSecond, , ) = StakedToken.assets(_asset);
         return emissionPerSecond;
    }

    function _aave_stat_global() private view returns (
            uint256 reserve_liquidityRate,
            uint256 reserve_variableBorrowRate,
            uint256 market_availableLiquidity,
            uint256 market_totalVariableDebt
        )
        { AavePair storage AAVE = AavePairOf[AAVE_BASE_COIN];
           ( uint256 availableLiquidity,,
             uint256 totalVariableDebt,
             uint256 liquidityRate,
             uint256 variableBorrowRate,,,,,
           ) = AaveDataProvider.getReserveData(AAVE.basic);
            reserve_liquidityRate = liquidityRate;
            reserve_variableBorrowRate = variableBorrowRate;
            market_availableLiquidity = availableLiquidity;
            market_totalVariableDebt = totalVariableDebt;
    }

    function aave_stat_global() public view returns (            
        uint256 matic_am,
        uint256 matic_variable,
            uint256 reserve_liquidityRate,
            uint256 reserve_variableBorrowRate,
            uint256 market_availableLiquidity,
            uint256 market_totalVariableDebt) {

        AavePair storage AAVE = AavePairOf[AAVE_BASE_COIN];
        (    reserve_liquidityRate,
             reserve_variableBorrowRate,
             market_availableLiquidity,
             market_totalVariableDebt
        ) = _aave_stat_global();
        matic_am = _matic_global(AAVE.am);
        matic_variable = _matic_global(AAVE.variableDebtm);
    }

}
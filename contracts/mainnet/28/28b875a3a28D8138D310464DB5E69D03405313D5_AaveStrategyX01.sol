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

struct AaveInit {
    string name;
    address basic;
    address am;
    address variableDebtm;
    uint256 ltv;
    uint256 liqvi;
    // main settings
    address AAVE_LENDING_POOL;
    address AAVE_STAKED_TOKEN;
    address AAVE_DATA_PROVIDER;

    // connectors to other smart contracts
    address SwapStrategy;

    address REWORDs; // in what tokens u get rewords
}

contract AaveStrategyX01 is Funding {

    using SafeMath for uint256;

    ISwapStrategy01 public SwapStrategy;
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
    address public immutable AAVE_STAKED_TOKEN;
    address public immutable AAVE_DATA_PROVIDER;
    address public immutable AAVE_LENDING_POOL;

    IAaveProtocolDataProvider AaveDataProvider;

    address public immutable REWORDs;
    IERC20 private WMATIC;

    string public AAVE_BASE_COIN;

    /* ADMIN IS UExecutor */
    // string memory _AAVE_BASE_COIN, 
    // 0x6110C57f38Ad2e88f2B5dF35f320354aF3682A9E
    constructor(AaveInit memory _aave) Admin(msg.sender) {
        AAVE_BASE_COIN = _aave.name;
        _aave_add_coin(
            _aave.name,
            _aave.basic,
            _aave.am,
            _aave.variableDebtm,
            _aave.ltv,
            _aave.liqvi
        );
        AAVE_LENDING_POOL = _aave.AAVE_LENDING_POOL;
        AAVE_STAKED_TOKEN  = _aave.AAVE_STAKED_TOKEN;
        AAVE_DATA_PROVIDER = _aave.AAVE_DATA_PROVIDER;

        REWORDs = _aave.REWORDs;

        AaveLP = ILendingPool(_aave.AAVE_LENDING_POOL);
        StakedToken = IStakedToken(_aave.AAVE_STAKED_TOKEN);
        AaveDataProvider = IAaveProtocolDataProvider(_aave.AAVE_DATA_PROVIDER);

        SwapStrategy = ISwapStrategy01(_aave.SwapStrategy);

        WMATIC = IERC20(_aave.REWORDs);
    }

    // 
    // BSC + assets
    //
    ILendingPool private AaveLP;
    IStakedToken private StakedToken; // MATIC

    // TODO this istemporary ...
    address[] public assets;
    function aave_matic_claim() public onlyOwner() returns (address[] memory, uint256[] memory){  
        return StakedToken.claimAllRewardsToSelf(assets);      
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
        (, uint256[] memory matic_amount) = aave_matic_claim();
        if (WMATIC.allowance(address(this), address(SwapStrategy)) == 0) {
            require(WMATIC.approve(address(SwapStrategy), type(uint256).max), "approve error");
        }
        (uint256 amountOut) = SwapStrategy.swapTo(Coin, matic_amount[0]);
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

    // private function, close piramid
    function _aave_close_piramid(string memory Coin, uint256 balance_variableDebtm) private returns (uint256) {
        require( _get_free_to_withdraw(Coin) > 0, "0 in the pool");
        AavePair storage AAVE = AavePairOf[Coin];
        return AaveLP.repayWithATokens(
            AAVE.basic, 
            balance_variableDebtm,
            2);
    }

    // withdraw all
    function aave_loop_withdraw_all(string memory Coin) public onlyOwner() {
        _last_deposit_loop = 0;

        ( , uint256 balance_am, uint256 balance_variableDebtm, , , ) = aave_balances(Coin);
        uint256 balance = balance_am - _aave_close_piramid(Coin, balance_variableDebtm);
        _aave_withdraw(Coin, balance);
    }

    // zero mode
    function aave_close_piramid_to_0(string memory Coin) public onlyOwner() {
        require(IERC20(AavePairOf[Coin].variableDebtm).balanceOf(address(this)) != 0, "not enough tokens in the pool");
        require( _get_free_to_withdraw(Coin) > 0, "0 in the pool");
        _last_deposit_loop = 0;
        AavePair storage AAVE = AavePairOf[Coin];
        _aave_close_piramid(
            Coin, 
            IERC20(AAVE.variableDebtm).balanceOf(address(this)) // variableDebtm
        );
    }
    function aave_make_piramid_from_0(string memory Coin, uint Count) public onlyOwner() {
        AavePair storage AAVE = AavePairOf[Coin];
        require(IERC20(AAVE.variableDebtm).balanceOf(address(this)) == 0, "not in 0 mode");
        _last_deposit_loop = Count;
        IERC20 SToken = IERC20(AAVE.basic);
        uint256 tokenAmt = SToken.balanceOf(address(this));
        uint256 x1 = tokenAmt.mul(AAVE.ltv - 100).div(10000);
        _aave_borrow(Coin, x1);
        _loop_deposit_x(Coin, Count, x1);
    }
    function aave_withdraw_from_0(string memory Coin) public onlyOwner() {
        require(IERC20(AavePairOf[Coin].variableDebtm).balanceOf(address(this)) == 0, "not in 0 mode");         
        _aave_withdraw(Coin, IERC20(AavePairOf[Coin].am).balanceOf(address(this)));
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
        matic = StakedToken.getUserRewards(assets, address(this), REWORDs);

        // REWORDs

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


    function _matic_global(address _asset) private view returns (uint256) {

        (,uint256 emissionPerSecond,,) = StakedToken.getRewardsData(_asset, REWORDs);
        return emissionPerSecond;
    }

    function _aave_stat_global() private view returns (
            uint256 reserve_liquidityRate,
            uint256 reserve_variableBorrowRate,
            uint256 market_availableLiquidity,
            uint256 market_totalVariableDebt
        )
        {
            AavePair storage AAVE = AavePairOf[AAVE_BASE_COIN];
           (,,uint256 totalAToken,,uint256 totalVariableDebt,
              uint256 liquidityRate,
              uint256 variableBorrowRate,,,,,) = AaveDataProvider.getReserveData(AAVE.basic);
            reserve_liquidityRate = liquidityRate;
            reserve_variableBorrowRate = variableBorrowRate;            
            market_availableLiquidity = totalAToken;            
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
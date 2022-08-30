// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "ERC20.sol";
import "Ownable.sol";
import "AggregatorV3Interface.sol";
import "ICollectible.sol";
import "IGenesisLiquidityPool.sol";
import "IGeminonOracle.sol";
import "IERC20ElasticSupply.sol";
import "TradePausable.sol";
import "TimeLocks.sol";



/**
* @title GenesisLiquidityPool
* @author Geminon Protocol
* @notice Smart liquidity pool with Liquidity Bootstrapping capacity.
*/
contract GenesisLiquidityPool is Ownable, TradePausable, TimeLocks, IGenesisLiquidityPool {

    IERC20ElasticSupply internal immutable GEX;
    IERC20 private immutable collateral;

    IGeminonOracle internal oracleGeminon;
    AggregatorV3Interface private collatPriceFeed;
        
    address public scMinter;
    address public treasuryLender;
    address public arbitrageur;
    address private feesCollector;
    
    bool public isInitialized;
    uint64 public oracleAge;
    
    uint256 public initPoolPrice;
    uint256 public initMintedAmount;
    uint256 public targetSupply;
    uint256 public poolSupply;
    uint16 public poolWeight;

    uint32 public minMintRate;
    uint32 public minBurnRate;
    
    uint32 public baseMintFee;
    uint32 public baseRedeemFee;
    
    int256 public mintedGEX;
    uint256 public balanceCollateral;
    uint256 public balanceGEX;
    uint256 public balanceLent;
    uint256 internal balanceFees;

    uint64 public blockTimestampLast;
    uint256 public lastCollatPrice;
    uint256 public meanPrice;
    uint256 public lastPrice;
    uint256 public meanVolume;
    uint256 public lastVolume;
    
    bool public isMigrationRequested;
    bool public isRemoveRequested;
    uint64 public timestampMigrationRequest;
    address public migrationPool;



    /// @param gexToken address of the GEX token contract
    /// @param collatToken address of the collateral token contract
    /// @param poolWeight_ integer percentage 3 decimals [1, 1000] (1e3)
    /// @param initPoolPrice_ must be in 1e18 USD units
    constructor(
        address gexToken, 
        address collatToken,
        uint16 poolWeight_,
        uint256 initPoolPrice_
    ) {
        GEX = IERC20ElasticSupply(gexToken);
        collateral = IERC20(collatToken);
        
        initPoolPrice = initPoolPrice_;
        poolWeight = poolWeight_;
        
        meanPrice = initPoolPrice;
        lastPrice = meanPrice;

        targetSupply = 100000000*1e18;
        poolSupply = (targetSupply * poolWeight) / 1e3;

        minMintRate = 1e6;
        minBurnRate = 1e6;
        baseMintFee = 1000;
        baseRedeemFee = 2000;

        isInitialized = false;
        _pauseMint();
    }

    
    
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // +                          INITIALIZATION                            +
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    /// @dev Initializes the pool. Only the priceFeed address is mandatory for
    /// the initialization. Other addresses can be set later as they are not
    /// needed for the pool to work. 
    /// @param initMintShare integer percentage 3 decimals [1, 1000] (1e3)
    /// @param oracle address of the Geminon's internal oracle
    /// @param priceFeed address of the collateral token price feed contract
    /// @param scMinter_ address of the stablecoin minter contract
    /// @param treasuryLender_ address of the treasury lending contract
    /// @param feesCollector_ address of the fees collector contract
    /// @param arbitrageur_ address of the protocol arbitrage operator
    function initialize(
        uint16 initMintShare, 
        address oracle,
        address priceFeed,
        address scMinter_,
        address treasuryLender_,
        address feesCollector_,
        address arbitrageur_
    ) 
        external onlyOwner 
    {
        require(!isInitialized); // dev: Already initialized
        require(initPoolPrice != 0); // dev: init pool price is zero
        require(poolSupply != 0); // dev: pool supply is zero
        require(priceFeed != address(0)); // dev: price feed required

        oracleGeminon = IGeminonOracle(oracle);
        if (oracle != address(0))
            oracleAge = uint64(block.timestamp);
        collatPriceFeed = AggregatorV3Interface(priceFeed);
        scMinter = scMinter_;
        treasuryLender = treasuryLender_;
        feesCollector = feesCollector_;
        arbitrageur = arbitrageur_;

        initMintedAmount = (initMintShare * poolSupply) / 1e3;
        if (initMintedAmount > 0)
            GEX.mint(address(this), initMintedAmount);
        mintedGEX = _toInt256(initMintedAmount);
        balanceGEX = initMintedAmount;
        meanVolume = initMintedAmount;

        blockTimestampLast = uint64(block.timestamp);
        lastCollatPrice = collateralPrice();

        isInitialized = true;
    }

    
    /// @dev Initializes the address of the stablecoin minter. 
    /// This function can only be used if the address has not been
    /// already initialized.
    function setSCMinter(address scMinter_) external onlyOwner {
        require(scMinter == address(0)); // dev: already set
        scMinter = scMinter_;
    }

    /// @dev Initializes the address of the Geminon oracle.
    /// This function can only be used if the address has not been 
    /// already initialized.
    function setOracle(address oracle) external onlyOwner {
        require(address(oracleGeminon) == address(0)); // dev: already set
        oracleGeminon = IGeminonOracle(oracle);
        oracleAge = uint64(block.timestamp);
    }

    /// @dev Initializes the address of the treasury lending and borrowing contract.
    /// This function can only be used if the address has not been
    /// already initialized.
    function setLender(address treasuryLender_) external onlyOwner {
        require(treasuryLender == address(0)); // dev: already set
        treasuryLender = treasuryLender_;
    }

    /// @dev Set the address of the fees collector contract.
    /// This function can be used anytime as it has no impact on the
    /// pool or the users. Can be reset to 0.
    function setCollector(address feesCollector_) external onlyOwner {
        feesCollector = feesCollector_;
    }

    /// @dev Set the address of the arbitrage operator.
    /// This function can be used anytime as it has no impact on the
    /// pool or the users. Can be reset to 0.
    function setArbitrageur(address arbitrageur_) external onlyOwner {
        arbitrageur = arbitrageur_;
    }

    
    
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // +                       PARAMETERS CHANGES                           +
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    
    /// @notice Changes the value of the base mint fee
    /// Max allowed value is 0.5% 
    function setMintFee(uint32 value) external onlyOwner {
        require(value <= 5000);
        baseMintFee = value;
    }

    /// @notice Changes the value of the base redeem fee
    /// Max allowed value is 0.5%
    function setRedeemFee(uint32 value) external onlyOwner {
        require(value <= 5000);
        baseRedeemFee = value;
    }

    /// @notice Changes the weight of the pool in the GEX collateralization
    /// The difference with the previous weight can not be higher than 5%
    /// The difference with the actual weight can not be higher than 10%
    /// Can't be rised if migration or removal has been requested.
    function setPoolWeight(uint16 weight) external onlyOwner {
        require(weight > 0); // dev: invalid weight value
        require(weight != poolWeight); // dev: weight is the same
        if (weight > poolWeight) {
            require(!isMigrationRequested); // dev: migration requested
            require(!isRemoveRequested); // dev: remove requested
        }

        uint256 absDiff = weight > poolWeight ? weight - poolWeight : poolWeight - weight;
        require(absDiff <= 50); // dev: weight change too big

        uint256 actualWeight = (getCollateralValue() *1e3) / oracleGeminon.getTotalCollatValue();
        absDiff = weight > actualWeight ? weight - actualWeight : actualWeight - weight;
        require(absDiff <= 100); // dev: oracle weight change too big
        
        poolWeight = weight;
        poolSupply = (targetSupply * poolWeight) / 1e3;
    }

    /// @notice Changes slightly the terminal rate of mint / burn of the pool. 
    /// It is only allowed to input values that make the pool deflationary.
    function setMintRates(uint32 mintRate, uint32 burnRate) external onlyOwner {
        require(mintRate <= 1e6); // dev: mintRate too high
        require(mintRate >= 95*1e4);  // dev: mintRate too low
        require(burnRate >= 1e6); // dev: burnRate too low
        require(burnRate <= 105*1e4);  // dev: burnRate too high

        minMintRate = mintRate;
        minBurnRate = burnRate;
    }



    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // +             SMART CONTRACTS INFRASTRUCTURE CHANGES                 +
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    /// @dev Apply the change in the price feed address proposed using
    /// the requestAddressChange() function. This function can only be called
    /// 7 days after the request of the change. Price feed is not critical for
    /// this contract to work or for its safety.
    function applyPriceFeedChange() external onlyOwner {
        require(changeRequests[address(collatPriceFeed)].changeRequested); // dev: Not requested
        require(block.timestamp - changeRequests[address(collatPriceFeed)].timestampRequest > 7 days);  // dev: Time elapsed
        require(changeRequests[address(collatPriceFeed)].newAddressRequested != address(0)); // dev: Address zero

        changeRequests[address(collatPriceFeed)].changeRequested = false;
        collatPriceFeed = AggregatorV3Interface(changeRequests[address(collatPriceFeed)].newAddressRequested);
    }

    /// @dev Apply the change in the stablecoin minter address proposed using
    /// the requestAddressChange() function. This function can only be called
    /// 30 days after the request of the change.
    function applySCMinterChange() external onlyOwner {
        require(changeRequests[scMinter].changeRequested); // dev: Not requested
        require(block.timestamp - changeRequests[scMinter].timestampRequest > 30 days); // dev: Time elapsed
        require(changeRequests[scMinter].newAddressRequested != address(0)); // dev: Address zero

        changeRequests[scMinter].changeRequested = false;
        scMinter = changeRequests[scMinter].newAddressRequested;
    }

    /// @dev Apply the change in the GEX oracle address proposed using
    /// the requestAddressChange() function. This function can only be called
    /// 30 days after the request of the change.
    function applyOracleChange() external onlyOwner {
        require(!isMigrationRequested); // dev: migration requested
        require(!isRemoveRequested); // dev: remove pool requested
        require(changeRequests[address(oracleGeminon)].changeRequested); // dev: Not requested
        require(block.timestamp - changeRequests[address(oracleGeminon)].timestampRequest > 30 days); // dev: Time elapsed
        require(changeRequests[address(oracleGeminon)].newAddressRequested != address(0)); // dev: Address zero

        changeRequests[address(oracleGeminon)].changeRequested = false;
        oracleGeminon = IGeminonOracle(changeRequests[address(oracleGeminon)].newAddressRequested);
        oracleAge = uint64(block.timestamp);
    }

    /// @dev Apply the change in the treasury lender address proposed using
    /// the requestAddressChange() function. This function can only be called
    /// 30 days after the request of the change. Can be reset to 0.
    function applyLenderChange() external onlyOwner {
        require(changeRequests[treasuryLender].changeRequested); // dev: Not requested
        require(block.timestamp - changeRequests[treasuryLender].timestampRequest > 30 days); // dev: Time elapsed

        changeRequests[treasuryLender].changeRequested = false;
        treasuryLender = changeRequests[treasuryLender].newAddressRequested;
    }
    


    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // +                          POOL MIGRATION                            +
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    /// @dev Register a request to migrate the pool.
    /// Previously the pool weight needs to have been reduced to
    /// less than 5%.
    /// Begins a timelock of 30 days before enable the migration.
    /// New pools needs to have been added to the oracle more than
    /// 7 days ago. Pauses the mint of GEX on this pool. It can't be unpaused 
    /// unless migration is cancelled. The oracle needs to have been used by  
    /// this pool for at least 30 days.
    function requestMigration(address newPool) external onlyOwner {
        require(!isMigrationRequested); // dev: migration already requested
        require(!isRemoveRequested); // dev: remove already requested
        require(newPool != address(this)); // dev: same pool
        require(address(oracleGeminon) != address(0)); // dev: oracle is not set
        require(block.timestamp - oracleAge > 30 days); // dev: oracle too new
        require(!oracleGeminon.isAnyPoolMigrating()); // dev: another pool is migrating
        require(!oracleGeminon.isAnyPoolRemoving()); // dev: another pool is removing
        require(!oracleGeminon.isMigratingPool(address(this))); // dev: migration already requested
        require(!oracleGeminon.isRemovingPool(address(this))); // dev: migration already requested
        require(block.timestamp - oracleGeminon.poolAge(newPool) > 7 days); // dev: pool too new
        require(poolWeight < 50); // dev: pool weight too high
        require((getCollateralValue() *1e3) / oracleGeminon.getTotalCollatValue() < 50); // dev: actual pool weight too high
        
        isMigrationRequested = true;
        timestampMigrationRequest = uint64(block.timestamp);
        migrationPool = newPool;
        _pauseMint();
        oracleGeminon.requestMigratePool(newPool);
    }

    /// @dev Register a request to withdraw the remaining pool liquidity.
    /// Previously the pool weight needs to have been reduced to
    /// less than 5%.
    /// Begins a timelock of 30 days before enabling the withdrawal.
    /// Pauses the mint of GEX on this pool. It can't be unpaused 
    /// unless remove is cancelled. The oracle needs to have been used by 
    /// this pool for at least 30 days.
    function requestRemove() external onlyOwner {
        require(!isMigrationRequested); // dev: migration already requested
        require(!isRemoveRequested); // dev: remove already requested
        require(address(oracleGeminon) != address(0)); // dev: oracle is not set
        require(block.timestamp - oracleAge > 30 days); // dev: oracle too new
        require(!oracleGeminon.isAnyPoolMigrating()); // dev: another pool is migrating
        require(!oracleGeminon.isAnyPoolRemoving()); // dev: another pool is removing
        require(!oracleGeminon.isMigratingPool(address(this))); // dev: migration already requested
        require(!oracleGeminon.isRemovingPool(address(this))); // dev: migration already requested
        require(poolWeight < 50); // dev: pool weight too high
        require((getCollateralValue() *1e3) / oracleGeminon.getTotalCollatValue() < 50); // dev: actual pool weight too high

        isRemoveRequested = true;
        timestampMigrationRequest = uint64(block.timestamp);
        _pauseMint();
        oracleGeminon.requestRemovePool();
    }

    
    /// @dev Transfer all liquidity of the pool to another pool.
    /// The pool needs to have reduced its weight to less than 2%.
    /// Removes this pool from the Geminon Oracle list. The pool gets blocked and
    /// can't be used again after this action because the require(balance > 0)
    /// statements of the mint and redeem functions will revert.
    function migratePool() external virtual onlyOwner whenMintPaused {
        require(isMigrationRequested); // dev: migration not requested
        require(address(oracleGeminon) != address(0)); // dev: oracle is not set
        require(block.timestamp - oracleAge > 60 days); // dev: oracle too new
        require(oracleGeminon.isMigratingPool(address(this))); // dev: migration not requested
        require(block.timestamp - timestampMigrationRequest > 30 days); // dev: timelock
        require(poolWeight < 20); // dev: pool weight too high
        require((getCollateralValue() *1e3) / oracleGeminon.getTotalCollatValue() < 20); // dev: actual pool weight too high
        
        uint256 amountGEX = GEX.balanceOf(address(this)) - balanceFees;
        uint256 amountCollateral = collateral.balanceOf(address(this));
        
        balanceGEX = 0;
        balanceCollateral = 0;
        mintedGEX -= _toInt256(balanceGEX);

        isMigrationRequested = false;

        GEX.approve(migrationPool, amountGEX);
        collateral.approve(migrationPool, amountCollateral);

        IGenesisLiquidityPool(migrationPool).receiveMigration(amountGEX, amountCollateral, initMintedAmount);
        
        oracleGeminon.setMigrationDone();
    }

    /// @dev Withdraw the remaining liquidity of the pool. Prior to this action the
    /// pool needs to have reduced its weight to less than 1% and this has to be requested
    /// at least 30 days before. 
    /// Removes this pool from the Geminon Oracle list. The pool gets blocked and
    /// can't be used again after this action.
    function removePool() external virtual onlyOwner whenMintPaused {
        require(isRemoveRequested); // dev: remove not requested
        require(address(oracleGeminon) != address(0)); // dev: oracle is not set
        require(block.timestamp - oracleAge > 60 days); // dev: oracle too new
        require(oracleGeminon.isRemovingPool(address(this))); // dev: remove not requested
        require(block.timestamp - timestampMigrationRequest > 30 days); // dev: timelock
        require(poolWeight < 10); // dev: pool weight too high
        require((getCollateralValue() *1e3) / oracleGeminon.getTotalCollatValue() < 10); // dev: actual pool weight too high
        
        balanceGEX = 0;
        balanceCollateral = 0;
        
        isRemoveRequested = false;

        require(GEX.transfer(owner(), GEX.balanceOf(address(this))));
        require(collateral.transfer(owner(), collateral.balanceOf(address(this))));
        
        oracleGeminon.setRemoveDone();
    }


    /// @dev Receive the funds of another pool that is migrating.
    function receiveMigration(uint256 amountGEX, uint256 amountCollateral, uint256 initMintedAmount_) external {
        require(isInitialized); // dev: not initialized
        require(address(oracleGeminon) != address(0)); // dev: oracle is not set
        require(oracleGeminon.isPool(msg.sender)); // dev: sender is not pool
        require(oracleGeminon.isMigratingPool(msg.sender)); // dev: migration not requested

        if (initMintedAmount == 0) {
            require(initMintedAmount_ != 0); // dev: null init minted amount
            initMintedAmount = initMintedAmount_;
        }
        balanceGEX += amountGEX;
        balanceCollateral += amountCollateral;
        mintedGEX += _toInt256(amountGEX);

        require(GEX.transferFrom(msg.sender, address(this), amountGEX));
        require(collateral.transferFrom(msg.sender, address(this), amountCollateral));
    }


    /// @notice Cancels any pending request for changes in the smart contract
    function cancelChangeRequests() external onlyOwner {
        
        if (changeRequests[address(0)].changeRequested)
            changeRequests[address(0)].changeRequested = false;

        if (changeRequests[address(collatPriceFeed)].changeRequested)
            changeRequests[address(collatPriceFeed)].changeRequested = false;
        
        if (changeRequests[scMinter].changeRequested)
            changeRequests[scMinter].changeRequested = false;

        if (changeRequests[address(oracleGeminon)].changeRequested)
            changeRequests[address(oracleGeminon)].changeRequested = false;
        
        if (changeRequests[treasuryLender].changeRequested)
            changeRequests[treasuryLender].changeRequested = false;
        
        if (isMigrationRequested) {
            isMigrationRequested = false;
            _unpauseMint();
            oracleGeminon.cancelMigration();
        }

        if (isRemoveRequested) {
            isRemoveRequested = false;
            _unpauseMint();
            oracleGeminon.cancelRemove();
        }
        
    }



    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // +                          USER FUNCTIONS                            +
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    /// @notice Swaps Collateral for GEX. Mints a percentage of the
    /// amount of GEX tokens as new supply.
    function mintSwap(uint256 inCollatAmount, uint256 minOutGEXAmount) external virtual whenMintNotPaused {
        require(balanceGEX > 0); // dev: pool not initialized
        
        uint256 outGEXAmount = amountOutGEX(inCollatAmount);
        uint256 fee = amountFeeMint(outGEXAmount);
        require(outGEXAmount - fee >= minOutGEXAmount, "Max slippage");
        uint256 amountMinted = amountMint(outGEXAmount);

        balanceFees += fee;
        balanceCollateral += inCollatAmount;
        balanceGEX += amountMinted;
        balanceGEX -= outGEXAmount;
        mintedGEX += _toInt256(amountMinted);

        _updateOracle(outGEXAmount);
        outGEXAmount -= fee;

        require(collateral.transferFrom(msg.sender, address(this), inCollatAmount));
        
        if (outGEXAmount == amountMinted)
            GEX.mint(msg.sender, amountMinted);
        else {
            GEX.mint(address(this), amountMinted);
            require(GEX.transfer(msg.sender, outGEXAmount));
        }
    }
    

    /// @notice Swaps GEX for Collateral. Burns a percentage of the
    /// amount of GEX tokens to reduce supply.
    function redeemSwap(uint256 inGEXAmount, uint256 minOutCollatAmount) external virtual {
        require(balanceCollateral > 0);

        uint256 fee = amountFeeRedeem(inGEXAmount);
        uint256 outCollateralAmount = amountOutCollateral(inGEXAmount - fee);
        require(outCollateralAmount >= minOutCollatAmount, "Max slippage");
        uint256 amountBurned = amountBurn(inGEXAmount);

        balanceFees += fee;
        balanceGEX += inGEXAmount;
        balanceGEX -= fee + amountBurned;
        balanceCollateral -= outCollateralAmount;
        mintedGEX -= _toInt256(amountBurned);

        _updateOracle(inGEXAmount);

        if (inGEXAmount == amountBurned)
            GEX.burn(msg.sender, amountBurned);
        else {
            GEX.burn(address(this), amountBurned);
            require(GEX.transferFrom(msg.sender, address(this), inGEXAmount));
        }
        require(collateral.transfer(msg.sender, outCollateralAmount));
    }
    


    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // +                        PROTOCOL FUNCTIONS                          +
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    
    /// @dev Pauses GEX mint in the pool. Redeems can not be paused.
    function pauseMint() external onlyOwner whenMintNotPaused {
        _pauseMint();
    }

    /// @dev Unpauses GEX mint in the pool. Can not unpause if migration or remove
    /// has been requested as those actions pause the pool as security measure.
    function unpauseMint() external onlyOwner whenMintPaused {
        require(!isMigrationRequested); // dev: migration requested
        require(!isRemoveRequested); // dev: remove requested
        _unpauseMint();
    }

    /// @dev Forces the contract balance to match the address balance.
    /// This should not be necessary unless someone sends tokens directly
    /// to the smart contract address. This can only be done if the error
    /// in the balances is less than 1% to avoid disrupting the pool.
    function matchBalances() virtual external onlyOwner {
        uint256 amountAddrGEX = GEX.balanceOf(address(this));
        uint256 amountAddrCollat = collateral.balanceOf(address(this));
        require(amountAddrGEX != balanceGEX + balanceFees || amountAddrCollat != balanceCollateral); // dev: Balances match
        
        uint256 ratioError1 = (amountAddrGEX * 1e3) / (balanceGEX + balanceFees);
        uint256 ratioError2 = (amountAddrCollat * 1e3) / (balanceCollateral);
        require(ratioError1 < 990 && ratioError1 < 1010); // dev: difference too big
        require(ratioError2 < 990 && ratioError2 < 1010); // dev: difference too big

        balanceCollateral = amountAddrCollat;
        balanceGEX = amountAddrGEX - balanceFees;
    }


    /// @notice Transfer GEX tokens to the stablecoin minter contract in case it
    /// has not enough funds to serve the stablecoin redemptions. The max amount per
    /// transfer is limited to 5% of the pool balance to avoid large price disruptions.
    function bailoutMinter() external returns(uint256 bailoutAmount) {
        require(balanceGEX > 0); // dev: pool empty
        require(scMinter != address(0)); // dev: scminter not set
        require(address(oracleGeminon) != address(0)); // dev: oracle not set
        require(block.timestamp - oracleGeminon.ageSCMinter() > 7 days); // dev: scminter too new
        require(block.timestamp - oracleAge > 30 days); // dev: oracle too new
        require(msg.sender == scMinter || msg.sender==owner()); // dev: invalid caller address
        require(oracleGeminon.getLockedAmountGEX() < balanceGEX*5/100); // dev: scminter over balance threshold

        if (mintedGEX > 0)
            bailoutAmount = balanceGEX/100 > uint256(mintedGEX)/100 ? balanceGEX/100 : uint256(mintedGEX)/100;
        else
            bailoutAmount = balanceGEX/100;

        bailoutAmount = bailoutAmount > (balanceGEX*5)/100 ? (balanceGEX*5)/100 : bailoutAmount;
        
        GEX.approve(scMinter, bailoutAmount);

        return bailoutAmount;
    }

    
    /// @notice Transfer collateral tokens to the lending contract. Max amount is limited
    /// to 50% of the total value of the GEX locked in other smart contracts or 25% of the
    /// collateral balance of this pool. Lent amount is not substracted from pool balance 
    /// to avoid disrupting the price.
    function lendCollateral(uint256 amount) external virtual returns(uint256) {
        require(amount > 0); // dev: null amount
        require(balanceCollateral > 0); // dev: pool empty
        require(treasuryLender != address(0)); // dev: lender not set
        require(address(oracleGeminon) != address(0)); // dev: oracle not set
        require(block.timestamp - oracleGeminon.ageTreasuryLender() > 7 days); // dev: lender too new
        require(block.timestamp - oracleAge > 30 days); // dev: oracle too new
        require(scMinter != address(0)); // dev: scMinter not set
        require(msg.sender == treasuryLender); // dev: invalid caller address
        require(!isMigrationRequested); // dev: migration requested
        require(!isRemoveRequested); // dev: remove requested

        uint256 amountEqLocked = (oracleGeminon.getLockedAmountGEX() * GEXQuote() * poolWeight) / 1e21;
        require(amountEqLocked > 0); // dev: null amount locked on scminter

        uint256 amountBorrowed = amount + balanceLent <= 5*amountEqLocked/10 ? amount : 5*amountEqLocked/10 - balanceLent;
        amountBorrowed = amountBorrowed + balanceLent <= 25*balanceCollateral/100 ? amountBorrowed : 25*balanceCollateral/100 - balanceLent;
        
        require(amountBorrowed > 0);  // dev: amount borrowed null
        balanceLent += amountBorrowed;

        collateral.approve(treasuryLender, amountBorrowed);

        return amountBorrowed;
    }

    /// @notice Get back collateral tokens from the lending contract
    function repayCollateral(uint256 amount) external returns(uint256) {
        require(balanceLent > 0); // dev: Nothing to repay
        require(msg.sender == treasuryLender); // dev: invalid caller address

        uint256 amountRepaid = amount <= balanceLent ? amount : balanceLent;
        
        balanceLent -= amountRepaid;

        require(collateral.transferFrom(treasuryLender, address(this), amountRepaid));
        collateral.approve(treasuryLender, 0);

        return amountRepaid;
    }

    /// @dev Collects the fees generated by this contract
    function collectFees() external returns(uint256) {
        require(balanceFees > 0); // dev: Nothing to collect
        require(feesCollector != address(0)); // dev: collector not set
        require(address(oracleGeminon) != address(0)); // dev: oracle not set
        require(oracleGeminon.feesCollector() != address(0)); //dev: collector not set in oracle
        require(block.timestamp - oracleGeminon.ageFeesCollector() > 7 days); // dev: collector too new
        require(block.timestamp - oracleAge > 30 days); // dev: oracle too new
        require(msg.sender == feesCollector || msg.sender==owner()); // dev: invalid caller address
        
        uint256 feesCollected = balanceFees;
        balanceFees = 0;
        
        require(GEX.transfer(feesCollector, feesCollected));
        return feesCollected;
    }
    

    
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // +                     INFORMATIVE FUNCTIONS                          +
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    /// @notice Get collateral token price in USD using an external oracle
    /// @dev Price feed gives answer with 8 decimals, we need 10 more to have 18
    function collateralPrice() public view returns(uint256) {
        (, int256 answer, , , ) = collatPriceFeed.latestRoundData();
        return uint256(answer * 1e10);
    }
    
    /// @notice Get the price of collateral relative to GEX
    function collateralQuote() public view returns(uint256) {
        if (balanceCollateral == 0) 
            return (collateralPrice() * 1e18) / initPoolPrice;
        
        return (balanceGEX * 1e18) / balanceCollateral;
    }


    /// @notice Gives the last GEX price of the liquidity pool in USD
    function GEXPrice() public view returns(uint256) {
        if (balanceCollateral == 0) 
            return initPoolPrice;
        else 
            return (collateralPrice() * balanceCollateral) / balanceGEX; 
    }

    /// @notice Get the price of GEX relative to collateral token
    function GEXQuote() public view returns(uint256) {
        if (balanceGEX == 0)
            return 0;
        else
            return (balanceCollateral * 1e18) / balanceGEX;
    }


    /// @notice Calculate the amount of the fee for minting GEX
    function amountFeeMint(uint256 amountGEX) public view returns(uint256) {
        return (amountGEX * variableFee(amountGEX, baseMintFee)) / 1e6;
    }

    /// @notice Calculate the amount of the fee for redeeming GEX
    function amountFeeRedeem(uint256 amountGEX) public view returns(uint256) {
        return (amountGEX * variableFee(amountGEX, baseRedeemFee)) / 1e6;
    }


    /// @notice Gives all mintSwap info at once. Reduces front-end RPC calls.
    /// All return values have 18 decimals except fee and priceImpact that have 6.
    function getMintInfo(uint256 inCollatAmount) public view returns(
        uint256 collateralPriceUSD, 
        uint256 initGEXPriceUSD,
        uint256 collatQuote,
        uint256 gexQuote,
        uint256 fee,
        uint256 feeAmount,
        uint256 outGEXAmount,
        uint256 finalGEXPriceUSD,
        uint256 priceImpact
    ) {
        collateralPriceUSD = collateralPrice();
        initGEXPriceUSD = GEXPrice();
        collatQuote = collateralQuote();
        gexQuote = GEXQuote();
        
        outGEXAmount = amountOutGEX(inCollatAmount);
        fee = variableFee(outGEXAmount, baseMintFee);
        feeAmount = amountFeeMint(outGEXAmount);
        outGEXAmount -= feeAmount;
        finalGEXPriceUSD = (collateralPriceUSD*inCollatAmount) / outGEXAmount;
        
        if (finalGEXPriceUSD >= initGEXPriceUSD)
            priceImpact = ((finalGEXPriceUSD - initGEXPriceUSD) * 1e6) / initGEXPriceUSD;
        else 
            priceImpact = ((initGEXPriceUSD - finalGEXPriceUSD) * 1e6) / initGEXPriceUSD;
    }

    /// @notice Gives all redeemSwap info at once. Reduces front-end RPC calls.
    /// All return values have 18 decimals except fee and priceImpact that have 6.
    function getRedeemInfo(uint256 inGEXAmount) public view returns(
        uint256 collateralPriceUSD, 
        uint256 initGEXPriceUSD,
        uint256 collatQuote,
        uint256 gexQuote,
        uint256 fee,
        uint256 feeAmount,
        uint256 outCollatAmount,
        uint256 finalGEXPriceUSD,
        uint256 priceImpact
    ) {
        collateralPriceUSD = collateralPrice();
        initGEXPriceUSD = GEXPrice();
        collatQuote = collateralQuote();
        gexQuote = GEXQuote();
        
        fee = variableFee(inGEXAmount, baseRedeemFee);
        feeAmount = amountFeeRedeem(inGEXAmount);
        outCollatAmount = amountOutCollateral(inGEXAmount - feeAmount);
        finalGEXPriceUSD = (collateralPriceUSD*outCollatAmount) / inGEXAmount;
        
        if (finalGEXPriceUSD >= initGEXPriceUSD)
            priceImpact = ((finalGEXPriceUSD - initGEXPriceUSD) * 1e6) / initGEXPriceUSD;
        else 
            priceImpact = ((initGEXPriceUSD - finalGEXPriceUSD) * 1e6) / initGEXPriceUSD;
    }


    /// @notice Get total collateral value in USD using an external oracle
    function getCollateralValue() public view returns(uint256) {
        return (collateralPrice() * balanceCollateral) / 1e18;
    }



    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // +                         CORE FUNCTIONS                             +
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    /// @notice Calculate out amount of the GEX token
    function amountOutGEX(uint256 inCollatAmount) public view returns(uint256 outGEXAmount) {
        if (balanceCollateral == 0)
            outGEXAmount = _initOutGEXAmount(inCollatAmount);

        else {
            uint256 halfInCollatAmount = inCollatAmount / 2;
            uint256 k1 = balanceCollateral * balanceGEX;
            outGEXAmount = balanceGEX - k1 / (balanceCollateral + halfInCollatAmount);

            uint256 updatedBalanceGEX = (balanceGEX + amountMint(outGEXAmount)) - outGEXAmount;
            uint256 updatedBalanceCollat = balanceCollateral + halfInCollatAmount;
            uint256 k2 = updatedBalanceCollat * updatedBalanceGEX;
            outGEXAmount += updatedBalanceGEX - k2 / (balanceCollateral + inCollatAmount);
        }
        return outGEXAmount; 
    }
        

    /// @notice Calculate out amount of collateral token
    function amountOutCollateral(uint256 inGEXAmount) public view returns(uint256 outCollatAmount) {
        if (balanceCollateral == 0)
            outCollatAmount = 0;

        else {
            uint256 halfInGEXAmount = inGEXAmount / 2;
            uint256 k1 = balanceCollateral * balanceGEX;
            outCollatAmount = balanceCollateral - k1 / (balanceGEX + halfInGEXAmount);

            uint256 updatedBalanceGEX = (balanceGEX + halfInGEXAmount) - amountBurn(halfInGEXAmount);
            uint256 updatedBalanceCollat = balanceCollateral - outCollatAmount;
            uint256 k2 = updatedBalanceCollat * updatedBalanceGEX;
            outCollatAmount += updatedBalanceCollat - k2 / (updatedBalanceGEX + halfInGEXAmount);
        }
        
        return outCollatAmount;
    }
    

    /// @dev Calculates amount of GEX to mint
    function amountMint(uint256 outGEXAmount) public view returns(uint256) {
        return (_mintRatio()* outGEXAmount) / 1e6;
    }

    /// @dev Calculates amount of GEX to burn
    function amountBurn(uint256 inGEXAmount) public view returns(uint256) {
        uint256 amountBurned = (_burnRatio() * inGEXAmount) / 1e6;

        if (balanceGEX <= initMintedAmount)
            amountBurned = 0;
        
        else if (amountBurned + initMintedAmount >= balanceGEX + 99*inGEXAmount/100)
            amountBurned = 0;

        return amountBurned;
    }

    /// @notice Calculate the percentage of the fee over GEX depending on
    /// the amount. The higher the amount, the higher the fee.
    /// The arbitrageur of the protocol does not pay fees to allow perfect matching
    /// of the price between pools.
    function variableFee(uint256 amountGEX, uint256 baseFee) public view returns(uint256 fee) {
        if (msg.sender == arbitrageur) return 0;

        uint256 usdAmount = (amountGEX * lastPrice) / 1e18;

        if (usdAmount < 1000*1e18) 
            fee = baseFee;
        
        else if (usdAmount < 10000*1e18) 
            fee = baseFee + 500 * (usdAmount - 1000*1e18) / 9000 / 1e18;
        
        else if (usdAmount < 100000*1e18) 
            fee = baseFee + 500 + 500 * (usdAmount - 10000*1e18) / 90000 / 1e18;
        
        else if (usdAmount < 1000000*1e18) 
            fee = baseFee + 1000 + 1000 * (usdAmount - 100000*1e18) / 900000 / 1e18;
        
        else 
            fee = baseFee + 2000;
    }


    /// @dev Updates the internal oracle that tracks price and amount of
    /// the trades. 
    function _updateOracle(uint256 amount) internal {
        uint256 elapsedTime = block.timestamp - blockTimestampLast;
        uint256 price = (lastCollatPrice * GEXQuote()) / 1e18;

        if (elapsedTime > 0) {
            uint256 alpha = (meanVolume * 1e6) / (1 + lastVolume);
            alpha = alpha > 1e6 ? 1e6 : alpha;
            meanPrice = (alpha*lastPrice + (1e6-alpha)*meanPrice) / 1e6;
            
            blockTimestampLast = uint64(block.timestamp);
            lastCollatPrice = collateralPrice();
        } 
        
        uint256 beta = (meanVolume * 1e6) / (1 + amount);
        beta = beta > 1e6 ? 1e6 : beta;
        lastPrice = (beta*price + (1e6-beta)*lastPrice) / 1e6;
        
        lastVolume = amount;
        meanVolume = amount/1000 + (999*meanVolume)/1000;
    }

    
    /// @dev safe casting of uint256 to int256 to avoid overflow
    function _toInt256(uint256 value) internal pure returns(int256) {
        require(value <= uint256(type(int256).max)); // dev: Unsafe casting
        return int256(value);
    }


    /// @dev Calculates the ratio to mint GEX. Uses 6 decimals.
    function _mintRatio() private view returns(uint256) {
        uint256 mintRatio = (_supplyRatio() * 1e6) / _poolWeightRatio();
        
        mintRatio = mintRatio > minMintRate ? mintRatio : minMintRate;
        mintRatio = mintRatio < 2e6 ? mintRatio : 2e6;
        
        return mintRatio;
    }

    /// @dev Calculates the ratio to burn GEX. Uses 6 decimals.
    function _burnRatio() private view returns(uint256) {
        uint256 burnRatio = (_supplyRatio() * _poolWeightRatio()) / 1e6;
        
        burnRatio = burnRatio > minBurnRate ? burnRatio : minBurnRate;
        burnRatio = burnRatio < 2e6 ? burnRatio : 2e6;
        
        return burnRatio;
    }

    /// @dev Modifies the amount to mint / burn to keep linear growth against
    /// the amount of collateral in the pool. Uses 6 decimals.
    function _supplyRatio() private view returns(uint256 supplyRatio) {
        if (address(oracleGeminon) == address(0)) {
            int256 poolSupply_ = _toInt256(poolSupply);
            supplyRatio = uint256(1e6 + ((poolSupply_ - mintedGEX) * 1e6) / poolSupply_);
        } else {
            uint256 totalMinted = oracleGeminon.getTotalMintedGEX();
            uint256 surplus = targetSupply > totalMinted ? targetSupply - totalMinted : 0;
            supplyRatio = 1e6 + (surplus * 1e6) / targetSupply;
        }
        
        supplyRatio =  supplyRatio > 1e6 ? supplyRatio : 1e6;
        supplyRatio =  supplyRatio < 2e6 ? supplyRatio : 2e6;
    }

    /// @dev Modifies the amount to mint / burn to keep collateral weight between 
    /// pools. Uses 6 decimals.
    function _poolWeightRatio() private view returns(uint256) {
        uint256 totalValue = oracleGeminon.getTotalCollatValue();
        uint256 poolValue = getCollateralValue();
        
        if (totalValue == 0 || poolValue == 0) 
            return 1e6;
        
        uint256 actualWeight = (poolValue * 1e3) / totalValue;
        uint256 weightRatio = (actualWeight * 1e6) / poolWeight;
        
        weightRatio = weightRatio > 75*1e4 ? weightRatio : 75*1e4;
        weightRatio = weightRatio < 125*1e4 ? weightRatio : 125*1e4;
        
        return weightRatio;
    }
    

    /// @dev Calculates out GEX amount for the first trade in the pool
    function _initOutGEXAmount(uint256 inCollatAmount) private view returns (uint256 outGEXAmount) {
        require(msg.sender == arbitrageur); // dev: Anti sniper bots

        uint256 collatPrice = collateralPrice();
        outGEXAmount = inCollatAmount * collatPrice / initPoolPrice;
        
        if (outGEXAmount > initMintedAmount) {
            outGEXAmount = initMintedAmount;
            uint256 spentCollatAmount = outGEXAmount * initPoolPrice / collatPrice;
            uint256 k = spentCollatAmount * outGEXAmount;
            outGEXAmount += outGEXAmount - (k / inCollatAmount);
        }

        return outGEXAmount;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "IERC20Metadata.sol";
import "Context.sol";

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
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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
pragma solidity ^0.8.0;


/**
* @title ICollectible
* @author Geminon Protocol
* @notice Interface for smart contracts whose fees have
* to be collected by the FeeCollector contract.
*/
interface ICollectible {
    function collectFees() external returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ICollectible.sol";


interface IGenesisLiquidityPool is ICollectible {

    function poolWeight() external view returns(uint16);
    
    function balanceCollateral() external view returns(uint256);

    function balanceGEX() external view returns(uint256);

    function mintedGEX() external view returns(int256);

    function meanPrice() external view returns(uint256);
    
    function lastPrice() external view returns(uint256);
    
    function meanVolume() external view returns(uint256);
    
    function lastVolume() external view returns(uint256);

    function isMigrationRequested() external view returns(bool);
    
    function isRemoveRequested() external view returns(bool);    
    

    function receiveMigration(uint256 amountGEX, uint256 amountCollateral, uint256 initMintedAmount) external;

    function bailoutMinter() external returns(uint256);

    function lendCollateral(uint256 amount) external returns(uint256);

    function repayCollateral(uint256 amount) external returns(uint256);

    
    function collateralPrice() external view returns(uint256);

    function collateralQuote() external view returns(uint256);

    function getCollateralValue() external view returns(uint256);

    function GEXPrice() external view returns(uint256);

    function GEXQuote() external view returns(uint256);

    function amountFeeMint(uint256 amountGEX) external view returns(uint256);

    function amountFeeRedeem(uint256 amountGEX) external view returns(uint256);

    function getMintInfo(uint256 inCollatAmount) external view returns(
        uint256 collateralPriceUSD, 
        uint256 gexPriceUSD,
        uint256 collatQuote,
        uint256 gexQuote,
        uint256 fee,
        uint256 feeAmount,
        uint256 outGEXAmount,
        uint256 finalGEXPriceUSD,
        uint256 priceImpact
    );

    function getRedeemInfo(uint256 inGEXAmount) external view returns(
        uint256 collateralPriceUSD, 
        uint256 gexPriceUSD,
        uint256 collatQuote,
        uint256 gexQuote,
        uint256 fee,
        uint256 feeAmount,
        uint256 outCollatAmount,
        uint256 finalGEXPriceUSD,
        uint256 priceImpact
    );

    function amountOutGEX(uint256 inCollatAmount) external view returns(uint256);

    function amountOutCollateral(uint256 inGEXAmount) external view returns(uint256);

    function variableFee(uint256 amountGEX, uint256 baseFee) external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IGeminonOracle {

    function isAnyPoolMigrating() external view returns(bool);
    
    function isAnyPoolRemoving() external view returns(bool);

    function scMinter() external view returns(address);

    function treasuryLender() external view returns(address);
    
    function feesCollector() external view returns(address);

    function ageSCMinter() external view returns(uint64);

    function ageTreasuryLender() external view returns(uint64);
    
    function ageFeesCollector() external view returns(uint64);
    
    function isMigratingPool(address) external view returns(bool);
    
    function isRemovingPool(address) external view returns(bool);

    function isPool(address) external view returns(bool);

    function poolAge(address) external view returns(uint64);


    function requestMigratePool(address newPool) external;

    function setMigrationDone() external;

    function cancelMigration() external;

    function requestRemovePool() external;

    function setRemoveDone() external;

    function cancelRemove() external;


    function getPrice() external view returns(uint256);
    
    function getLastPrice() external view returns(uint256);

    function getVolume() external view returns(uint256);

    function getLastVolume() external view returns(uint256);

    function getLockedAmountGEX() external view returns(uint256);

    function getTotalMintedGEX() external view returns(uint256);

    // function getPoolSupplyWeight(address pool) external view returns(uint256);
    
    function getTotalCollatValue() external view returns(uint256);

    function getPoolCollatWeight(address pool) external view returns(uint256);

    function getHighestGEXPool() external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IERC20.sol";



/**
* @title IERC20ElasticSupply
* @author Geminon Protocol
* @dev Interface for the ERC20ElasticSupply contract
*/
interface IERC20ElasticSupply is IERC20 {

    event TokenMinted(address indexed from, address indexed to, uint256 amount);

    event TokenBurned(address indexed from, address indexed to, uint256 amount);

    event MinterAdded(address minter_address);

    event MinterRemoved(address minter_address);

    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;

    function addMinter(address newMinter) external;

    function removeMinter(address minter) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenMintNotPaused`, `whenMintPaused`, `whenRedeemNotPaused` 
 * and `whenRedeemPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract TradePausable {

    bool private _mintPaused;
    bool private _redeemPaused;


    /// @dev Emitted when the mint pause is triggered by `account`.
    event MintPaused(address account);

    /// @dev Emitted when the redeem pause is triggered by `account`.
    event RedeemPaused(address account);

    /// @dev Emitted when the mint pause is lifted by `account`.
    event MintUnpaused(address account);

    /// @dev Emitted when the redeem pause is lifted by `account`.
    event RedeemUnpaused(address account);


    /// @dev Modifier to make a function callable only when the contract is not paused.
    modifier whenMintNotPaused() {
        _requireMintNotPaused();
        _;
    }

    /// @dev Modifier to make a function callable only when the contract is paused.
    modifier whenMintPaused() {
        _requireMintPaused();
        _;
    }

    /// @dev Modifier to make a function callable only when the contract is not paused.
    modifier whenRedeemNotPaused() {
        _requireRedeemNotPaused();
        _;
    }

    /// @dev Modifier to make a function callable only when the contract is paused.
    modifier whenRedeemPaused() {
        _requireRedeemPaused();
        _;
    }


    /// @dev Initializes the contract in unpaused state.
    constructor() {
        _mintPaused= false;
        _redeemPaused= false;
    }

    
    function isMintPaused() public view returns(bool) {
        return _mintPaused;
    }

    function isRedeemPaused() public view returns(bool) {
        return _redeemPaused;
    }


    /// @dev Throws if the contract is paused.
    function _requireMintNotPaused() internal view virtual {
        require(!_mintPaused, "Mint paused");
    }

    /// @dev Throws if the contract is not paused.
    function _requireMintPaused() internal view virtual {
        require(_mintPaused); // TradePausable: mint not paused
    }

    /// @dev Throws if the contract is paused.
    function _requireRedeemNotPaused() internal view virtual {
        require(!_redeemPaused); // TradePausable: redeem paused
    }

    /// @dev Throws if the contract is not paused.
    function _requireRedeemPaused() internal view virtual {
        require(_redeemPaused); // TradePausable: redeem not paused
    }

    /// @dev Triggers stopped state for mint
    function _pauseMint() internal virtual {
        _mintPaused = true;
        emit MintPaused(msg.sender);
    }

    /// @dev Returns to normal state.
    function _unpauseMint() internal virtual {
        _mintPaused = false;
        emit MintUnpaused(msg.sender);
    }

    /// @dev Triggers stopped state for redeem 
    function _pauseRedeem() internal virtual {
        _redeemPaused = true;
        emit RedeemPaused(msg.sender);
    }

    /// @dev Returns to normal state.
    function _unpauseRedeem() internal virtual {
        _redeemPaused = false;
        emit RedeemUnpaused(msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";


/**
* @title TimeLocks
* @author Geminon Protocol
* @dev Utility to protect smart contracts against instant changes
* on critical infrastructure. Sets a two step procedure to change
* the address of a smart contract that is used by another contract.
*/
contract TimeLocks is Ownable {

    struct ContractChangeRequest {
        bool changeRequested;
        uint64 timestampRequest;
        address newAddressRequested;
    }

    mapping(address => ContractChangeRequest) public changeRequests;

    
    /// @dev Creates a request to change the address of a smart contract.
    function requestAddressChange(address actualContract, address newContract) 
        external 
        onlyOwner 
    {
        require(newContract != address(0)); // dev: address 0
        
        ContractChangeRequest memory changeRequest = 
            ContractChangeRequest({
                changeRequested: true, 
                timestampRequest: uint64(block.timestamp), 
                newAddressRequested: newContract
            });
        
        changeRequests[actualContract] = changeRequest;
    }

    /// @dev Creates a request to add a new address of a smart contract.
    function requestAddAddress(address newContract) external onlyOwner {
        require(newContract != address(0)); // dev: address 0

        ContractChangeRequest memory changeRequest = 
            ContractChangeRequest({
                changeRequested: true, 
                timestampRequest: uint64(block.timestamp), 
                newAddressRequested: newContract
            });
        
        changeRequests[address(0)] = changeRequest;
    }

    /// @dev Creates a request to remove the address of a smart contract.
    function requestRemoveAddress(address oldContract) external onlyOwner {
        require(oldContract != address(0)); // dev: address zero
        
        ContractChangeRequest memory changeRequest = 
            ContractChangeRequest({
                changeRequested: true, 
                timestampRequest: uint64(block.timestamp), 
                newAddressRequested: address(0)
            });
        
        changeRequests[oldContract] = changeRequest;
    }
}
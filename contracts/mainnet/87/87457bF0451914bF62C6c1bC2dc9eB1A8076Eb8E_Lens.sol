/**
 *Submitted for verification at snowtrace.io on 2023-03-20
*/

// File contracts/Exponential-0.8.sol

pragma solidity ^0.8;

/**
 * @title Exponential module for storing fixed-precision decimals
 * @author BENQI
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract ExponentialNoError {
    uint constant expScale = 1e18;
    uint constant doubleScale = 1e36;
    uint constant halfExpScale = expScale/2;
    uint constant mantissaOne = expScale;

    struct Exp {
        uint mantissa;
    }

    struct Double {
        uint mantissa;
    }

    /**
     * @dev Truncates the given exp to a whole number value.
     *      For example, truncate(Exp{mantissa: 15 * expScale}) = 15
     */
    function truncate(Exp memory exp) pure internal returns (uint) {
        // Note: We are not using careful math here as we're performing a division that cannot fail
        return exp.mantissa / expScale;
    }

    /**
     * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
     */
    function mul_ScalarTruncate(Exp memory a, uint scalar) pure internal returns (uint) {
        Exp memory product = mul_(a, scalar);
        return truncate(product);
    }

    /**
     * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
     */
    function mul_ScalarTruncateAddUInt(Exp memory a, uint scalar, uint addend) pure internal returns (uint) {
        Exp memory product = mul_(a, scalar);
        return add_(truncate(product), addend);
    }

    /**
     * @dev Checks if first Exp is less than second Exp.
     */
    function lessThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa < right.mantissa;
    }

    /**
     * @dev Checks if left Exp <= right Exp.
     */
    function lessThanOrEqualExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa <= right.mantissa;
    }

    /**
     * @dev Checks if left Exp > right Exp.
     */
    function greaterThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa > right.mantissa;
    }

    /**
     * @dev returns true if Exp is exactly zero
     */
    function isZeroExp(Exp memory value) pure internal returns (bool) {
        return value.mantissa == 0;
    }

    function safe224(uint n, string memory errorMessage) pure internal returns (uint224) {
        require(n < 2**224, errorMessage);
        return uint224(n);
    }

    function safe32(uint n, string memory errorMessage) pure internal returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function add_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: add_(a.mantissa, b.mantissa)});
    }

    function add_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: add_(a.mantissa, b.mantissa)});
    }

    function add_(uint a, uint b) pure internal returns (uint) {
        return a + b;
    }

    function sub_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: sub_(a.mantissa, b.mantissa)});
    }

    function sub_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: sub_(a.mantissa, b.mantissa)});
    }

    function sub_(uint a, uint b) pure internal returns (uint) {
        return a - b;
    }

    function mul_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b.mantissa) / expScale});
    }

    function mul_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b)});
    }

    function mul_(uint a, Exp memory b) pure internal returns (uint) {
        return mul_(a, b.mantissa) / expScale;
    }

    function mul_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b.mantissa) / doubleScale});
    }

    function mul_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b)});
    }

    function mul_(uint a, Double memory b) pure internal returns (uint) {
        return mul_(a, b.mantissa) / doubleScale;
    }

    function mul_(uint a, uint b) pure internal returns (uint) {
        return a * b;
    }

    function div_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: div_(mul_(a.mantissa, expScale), b.mantissa)});
    }

    function div_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa: div_(a.mantissa, b)});
    }

    function div_(uint a, Exp memory b) pure internal returns (uint) {
        return div_(mul_(a, expScale), b.mantissa);
    }

    function div_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: div_(mul_(a.mantissa, doubleScale), b.mantissa)});
    }

    function div_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: div_(a.mantissa, b)});
    }

    function div_(uint a, Double memory b) pure internal returns (uint) {
        return div_(mul_(a, doubleScale), b.mantissa);
    }

    function div_(uint a, uint b) pure internal returns (uint) {
        return a / b;
    }

    function fraction(uint a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: div_(mul_(a, doubleScale), b)});
    }
}


// File contracts/Lens.sol

pragma solidity ^0.8;

interface Comptroller {
    function getAllMarkets() external view returns (address[] memory);
    function oracle() external view returns (PriceOracle);
    function markets(address) external view returns (bool, uint);
    function supplyRewardSpeeds(uint8, address) external view returns (uint);
    function borrowRewardSpeeds(uint8, address) external view returns (uint);
    function borrowCaps(address) external view returns (uint);
    function checkMembership(address account, QiToken qiToken) external view returns (bool);
    function rewardAccrued(uint8, address) external view returns (uint);
    function rewardBorrowState(uint8, address) external view returns (uint224, uint32);
    function rewardSupplyState(uint8, address) external view returns (uint224, uint32);
    function rewardBorrowerIndex(uint8, address, address) external view returns (uint);
    function rewardSupplierIndex(uint8, address, address) external view returns (uint);
    function initialIndexConstant() external view returns (uint224);
    function mintGuardianPaused(address market) external view returns (bool);
    function borrowGuardianPaused(address market) external view returns (bool);
}

interface QiToken {
    function borrowRatePerTimestamp() external view returns (uint);
    function supplyRatePerTimestamp() external view returns (uint);
    function exchangeRateStored() external view returns (uint);
    function reserveFactorMantissa() external view returns (uint);
    function totalSupply() external view returns (uint);
    function totalBorrows() external view returns (uint);
    function underlying() external view returns (address);
    function balanceOf(address) external view returns (uint);
    function borrowBalanceStored(address) external view returns (uint);
    function decimals() external view returns (uint);
    function totalReserves() external view returns (uint);
    function getCash() external view returns (uint);
    function borrowIndex() external view returns (uint);
}

interface PriceOracle {
    function getUnderlyingPrice(QiToken qiToken) external view returns (uint);
}

interface UnderlyingToken {
    function decimals() external view returns (uint);
    function balanceOf(address) external view returns (uint);
    function allowance(address, address) external view returns (uint);
}

interface PangolinLPToken {
    function balanceOf(address) external view returns (uint);
    function allowance(address, address) external view returns (uint);
    function totalSupply() external view returns (uint);
    function getReserves() external view returns (uint112, uint112, uint32);
    function kLast() external view returns (uint);
}

interface PglStakingContract {
    function pglTokenAddress() external view returns (address);
    function totalSupplies() external view returns (uint);
    function rewardSpeeds(uint) external view returns (uint);
    function supplyAmount(address) external view returns (uint);

    function rewardIndex(uint) external view returns (uint);
    function supplierRewardIndex(address, uint) external view returns (uint);
    function accruedReward(address, uint) external view returns (uint);
}

contract Lens is ExponentialNoError {
    Comptroller public constant comptroller = Comptroller(0x486Af39519B4Dc9a7fCcd318217352830E8AD9b4);
    PglStakingContract public constant pglStakingContract = PglStakingContract(0x784DA19e61cf348a8c54547531795ECfee2AfFd1);
    address public constant pangolinRouter = 0xE54Ca86531e17Ef3616d22Ca28b0D458b6C89106;

    QiToken public constant qiQi = QiToken(0x35Bd6aedA81a7E5FC7A7832490e71F757b0cD9Ce);
    QiToken public constant qiAvax = QiToken(0x5C0401e81Bc07Ca70fAD469b451682c0d747Ef1c);

    struct MarketMetadata {
        /// @dev Market (QiToken) address
        address market;

        /// @dev Interest rate model's supply rate
        uint supplyRate;

        /// @dev Interest rate model's borrow rate
        uint borrowRate;

        /// @dev Token price (decimal count 36 - underlying decimals)
        uint price;

        /// @dev QiToken to underlying token exchange rate (18 - QiToken decimals + underlying decimals)
        uint exchangeRate;

        /// @dev Reserve factor percentage (18 decimals)
        uint reserveFactor;

        /// @dev Maximum total borrowable amount for the market, denominated in the underlying asset
        uint borrowCap;

        /// @dev Total supply, denominated in QiTokens
        uint totalSupply;

        /// @dev Total supply, denominated in the underlying token
        uint totalUnderlyingSupply;

        /// @dev Total borrows, denominated in the underlying token
        uint totalBorrows;

        /// @dev Collateral factor (18 decimals)
        uint collateralFactor;

        /// @dev Underlying token address
        address underlyingToken;

        /// @dev Underlying token decimal count
        uint underlyingTokenDecimals;

        /// @dev Market QiToken decimal count
        uint qiTokenDecimals;

        /// @dev Amount of AVAX rewarded to suppliers every second (18 decimals)
        uint avaxSupplyRewardSpeed;

        /// @dev Amount of AVAX rewarded to borrowers every second (18 decimals)
        uint avaxBorrowRewardSpeed;

        /// @dev Amount of QI rewarded to suppliers every second (18 decimals)
        uint qiSupplyRewardSpeed;

        /// @dev Amount of QI rewarded to borrowers every second (18 decimals)
        uint qiBorrowRewardSpeed;

        /// @dev Total amount of reserves of the underlying held in this market
        uint totalReserves;

        /// @dev Cash balance of this qiToken in the underlying token (underlying token's decimals)
        uint cash;

        /// @dev Indicates if adding supply is paused
        bool mintPaused;

        /// @dev Indicates if borrowing is paused
        bool borrowPaused;
    }

    struct AccountSnapshot {
        AccountMarketSnapshot[] accountMarketSnapshots;
        AccountRewards rewards;
    }

    struct AccountMarketSnapshot {
        /// @dev Market address
        address market;

        /// @dev Account's wallet balance for the underlying token
        uint balance;

        /// @dev The allowed maximum expenditure of the underlying token by the market contract
        uint allowance;

        /// @dev Account's supply balance, denominated in the underlying token
        uint supplyBalance;

        /// @dev Account's borrow balance, denominated in the underlying token
        uint borrowBalance;

        /// @dev Indicates if a market is avaiable as collateral on the account
        bool collateralEnabled;
    }

    struct AccountRewards {
        /// @dev Amount of unclaimed AVAX rewards (18 decimals)
        uint unclaimedAvax;

        /// @dev Amount of unclaimed QI rewards (18 decimals)
        uint unclaimdQi;

        /// @dev List of all markets in which the user has unclaimed rewards
        address[] markets;
    }

    struct AccountPglSnapshot {
        /// @dev The PGL balance of the user's wallet (PGL token`s decimals)
        uint balance;

        /// @dev The amount of PGL tokens the user has deposited (PGL token`s decimals)
        uint deposited;

        /// @dev Unclaimed QI rewards (18 decimals)
        uint unclaimedQi;

        /// @dev The allowed maximum expenditure of the user's PGL tokens by the staking contract (PGL token`s decimals)
        uint pglStakingContractAllowance;

        /// @dev The allowed maximum expenditure of the user's QI (actual QI, not qiTokens) by the pangolin router (18 decimals)
        uint pangolinRouterQiAllowance;
    }

    struct MarketPglSnapshot {
        /// @dev Total PGL token amount deposited into the staking contract (PGL token's decimals)
        uint totalDepositedPglTokenAmount;

        /// @dev total supply of PGL tokens (18 decimals)
        uint pglTokenTotalSupply;

        /// @dev amount of QI in the pool (18 decimals)
        uint pglQiReserves;

        /// @dev amount of QI in the pool (18 decimals)
        uint pglAvaxReserves;

        /// @dev reserve0 * reserve1
        uint kLast;

        /// @dev APR (18 decimals, 1e18 means 100%)
        uint apr;
    }

    /**
     * @notice Get metadata for a specific market
     * @param  market The BENQI market address which metadata will be fetched for
     * @return Market metadata
     */
    function getMarketMetadata(QiToken market) external view returns (MarketMetadata memory) {
        return _getMarketMetadata(market);
    }

    /**
     * @notice Get metadata for all markets
     * @return Market metadata for all markets
     */
    function getMarketMetadataForAllMarkets() external view returns (MarketMetadata[] memory) {
        address[] memory allMarkets = comptroller.getAllMarkets();
        uint marketCount = allMarkets.length;

        MarketMetadata[] memory metadata = new MarketMetadata[](marketCount);

        for (uint i; i < marketCount;) {
            metadata[i] = _getMarketMetadata(QiToken(allMarkets[i]));
            unchecked { ++i; }
        }

        return metadata;
    }

    /**
     * @notice Get account-specific data for supply and borrow positions
     * @param  account Account for the snapshot
     * @return Account snapshot array
     */
    function getAccountSnapshot(address account) external view returns (AccountSnapshot memory) {
        return _getAccountSnapshot(account);
    }

    /**
     * @notice Calculate an account snapshot for a specific market
     * @param  account The account which the snapshot will belong to
     * @param  market The specific market which a snapshot will be calculated for the given account
     * @return Account snapshot
     */
    function getAccountMarketSnapshot(address account, QiToken market) external view returns (AccountMarketSnapshot memory) {
        return _getAccountMarketSnapshot(account, market);
    }

    /**
     * @notice Calculate an account-specific QI-AVAX PGL staking snapshot
     * @param  account The account which the snapshot will belong to
     * @return Account snapshot for PGL data
     */
    function getAccountPglSnapshot(address account) external view returns (AccountPglSnapshot memory) {
        return _getAccountPglSnapshot(account);
    }

    /**
     * @notice Calculate a QI-AVAX PGL staking market snapshot
     * @return Market snapshot for PGL data
     */
    function getMarketPglSnapshot() external view returns (MarketPglSnapshot memory) {
        return _getMarketPglSnapshot();
    }

    function _getMarketMetadata(QiToken market) internal view returns (MarketMetadata memory) {
        address marketAddress = address(market);
        PriceOracle oracle = comptroller.oracle();
        (, uint collateralFactor) = comptroller.markets(marketAddress);

        address underlyingToken;
        uint underlyingTokenDecimals;

        if (_isAvaxMarket(market)) {
            underlyingToken = address(0);
            underlyingTokenDecimals = 18;
        } else {
            underlyingToken = market.underlying();
            underlyingTokenDecimals = UnderlyingToken(underlyingToken).decimals();
        }

        uint totalSupply = market.totalSupply();
        uint totalUnderlyingTokenSupply = _qiTokenBalanceToUnderlying(totalSupply, market);

        MarketMetadata memory metadata = MarketMetadata(
            marketAddress,
            market.supplyRatePerTimestamp(),
            market.borrowRatePerTimestamp(),
            oracle.getUnderlyingPrice(market),
            market.exchangeRateStored(),
            market.reserveFactorMantissa(),
            comptroller.borrowCaps(marketAddress),
            totalSupply,
            totalUnderlyingTokenSupply,
            market.totalBorrows(),
            collateralFactor,
            underlyingToken,
            underlyingTokenDecimals,
            market.decimals(),
            comptroller.supplyRewardSpeeds(1, marketAddress),
            comptroller.borrowRewardSpeeds(1, marketAddress),
            comptroller.supplyRewardSpeeds(0, marketAddress),
            comptroller.borrowRewardSpeeds(0, marketAddress),
            market.totalReserves(),
            market.getCash(),
            comptroller.mintGuardianPaused(marketAddress),
            comptroller.borrowGuardianPaused(marketAddress)
        );

        return metadata;
    }

    function _getAccountSnapshot(address account) internal view returns (AccountSnapshot memory) {
        address[] memory allMarkets = comptroller.getAllMarkets();
        uint marketCount = allMarkets.length;

        AccountMarketSnapshot[] memory snapshots = new AccountMarketSnapshot[](marketCount);

        for (uint i; i < marketCount;) {
            snapshots[i] = _getAccountMarketSnapshot(account, QiToken(allMarkets[i]));
            unchecked { ++i; }
        }

        (
            uint unclaimedQi,
            uint unclaimedAvax,
            address[] memory marketsWithClaimableRewards
        ) = getClaimableRewards(account);

        return AccountSnapshot(
            snapshots,
            AccountRewards(unclaimedAvax, unclaimedQi, marketsWithClaimableRewards)
        );
    }

    function _getAccountMarketSnapshot(address account, QiToken market) internal view returns (AccountMarketSnapshot memory) {
        uint balance;
        uint allowance;

        if (_isAvaxMarket(market)) {
            balance = account.balance;
        } else {
            UnderlyingToken underlyingToken = UnderlyingToken(market.underlying());

            balance = underlyingToken.balanceOf(account);
            allowance = underlyingToken.allowance(account, address(market));
        }

        uint qiTokenBalance = market.balanceOf(account);
        uint supplyBalance = _qiTokenBalanceToUnderlying(qiTokenBalance, market);
        bool collateralEnabled = comptroller.checkMembership(account, market);

        return AccountMarketSnapshot(
            address(market),
            balance,
            allowance,
            supplyBalance,
            market.borrowBalanceStored(account),
            collateralEnabled
        );
    }

    function _getAccountPglSnapshot(address account) internal view returns (AccountPglSnapshot memory) {
        PangolinLPToken pglToken = PangolinLPToken(pglStakingContract.pglTokenAddress());

        uint balance = pglToken.balanceOf(account);
        uint deposited = pglStakingContract.supplyAmount(account);

        uint qiIndexDelta = pglStakingContract.rewardIndex(1) - pglStakingContract.supplierRewardIndex(account, 1);
        uint unclaimedQi = ((qiIndexDelta * pglStakingContract.supplyAmount(account)) / 1e36) + pglStakingContract.accruedReward(account, 1);

        uint pglStakingContractAllowance = pglToken.allowance(account, address(pglStakingContract));

        UnderlyingToken qi = UnderlyingToken(qiQi.underlying());
        uint pangolinRouterQiAllowance = qi.allowance(account, pangolinRouter);

        return AccountPglSnapshot(
            balance,
            deposited,
            unclaimedQi,
            pglStakingContractAllowance,
            pangolinRouterQiAllowance
        );
    }

    function _getMarketPglSnapshot() internal view returns (MarketPglSnapshot memory) {
        PangolinLPToken pglToken = PangolinLPToken(pglStakingContract.pglTokenAddress());
        PriceOracle oracle = comptroller.oracle();

        uint totalDepositedPglTokenAmount = pglStakingContract.totalSupplies();
        uint pglTokenTotalSupply = pglToken.totalSupply();
        (uint pglQiReserves, uint pglAvaxReserves, ) = pglToken.getReserves();
        uint kLast = pglToken.kLast();

        uint qiRewardSpeed = pglStakingContract.rewardSpeeds(1);
        uint qiPrice = oracle.getUnderlyingPrice(qiQi);
        uint avaxPrice = oracle.getUnderlyingPrice(qiAvax);

        uint apr = _calculateAPR(
            qiRewardSpeed,
            pglQiReserves,
            pglAvaxReserves,
            qiPrice,
            avaxPrice,
            pglTokenTotalSupply,
            totalDepositedPglTokenAmount
        );

        return MarketPglSnapshot(
            totalDepositedPglTokenAmount,
            pglTokenTotalSupply,
            pglQiReserves,
            pglAvaxReserves,
            kLast,
            apr
        );
    }

    function _calculateAPR(
        uint qiRewardSpeed,
        uint qiReserves,
        uint avaxReserves,
        uint qiPrice,
        uint avaxPrice,
        uint pglTotalSupply,
        uint totalDepositedPGLTokenAmount
    ) internal pure returns (uint) {
        uint qiReservesValue = (qiReserves * qiPrice) / 1e18;
        uint avaxReserveValue = (avaxReserves * avaxPrice) / 1e18;

        uint pglPrice = (qiReservesValue + avaxReserveValue) / pglTotalSupply;

        uint qiUsdValuePerYear = qiRewardSpeed * (60 * 60 * 24 * 365) * qiPrice;
        uint totalStakeValue = totalDepositedPGLTokenAmount * pglPrice;

        uint usdPerStakedPglValue = qiUsdValuePerYear / totalStakeValue;

        return usdPerStakedPglValue;
    }

    function getClaimableRewards(address user) internal view returns (uint, uint, address[] memory) {
        (uint claimableQi, address[] memory qiMarkets) = getClaimableReward(user, 0);
        (uint claimableAvax, address[] memory avaxMarkets) = getClaimableReward(user, 1);

        unchecked {
            uint numQiMarkets = qiMarkets.length;
            uint numAvaxMarkets = avaxMarkets.length;
            address[] memory rewardMarkets = new address[](numQiMarkets + numAvaxMarkets);

            uint uniqueRewardMarketCount;

            for (; uniqueRewardMarketCount < numQiMarkets; ++uniqueRewardMarketCount) {
                rewardMarkets[uniqueRewardMarketCount] = qiMarkets[uniqueRewardMarketCount];
            }

            for (uint i; i < numAvaxMarkets;++i) {
                bool duplicate = false;

                for (uint j; j < uniqueRewardMarketCount;++j) {
                    if(rewardMarkets[j] == avaxMarkets[i]) {
                        duplicate = true;
                        break;
                    }
                }

                if (!duplicate) {
                    rewardMarkets[uniqueRewardMarketCount] = avaxMarkets[i];
                    ++uniqueRewardMarketCount;
                }
            }

            address[] memory marketsWithClaimableRewards = new address[](uniqueRewardMarketCount);

            for (uint i; i < uniqueRewardMarketCount; ++i) {
                marketsWithClaimableRewards[i] = rewardMarkets[i];
            }

            return (claimableQi, claimableAvax, marketsWithClaimableRewards);
        }
    }

    function getClaimableReward(address user, uint8 rewardType) public view returns (uint, address[] memory) {
        address[] memory markets = comptroller.getAllMarkets();
        uint numMarkets = markets.length;

        uint accrued = comptroller.rewardAccrued(rewardType, user);

        uint totalMarketAccrued;

        address[] memory rawMarketsWithRewards = new address[](numMarkets);
        uint numMarketsWithRewards;

        for (uint i; i < numMarkets;) {
            QiToken market = QiToken(markets[i]);

            totalMarketAccrued = updateAndDistributeSupplierReward(rewardType, market, user);
            totalMarketAccrued += updateAndDistributeBorrowerReward(rewardType, market, user);

            accrued += totalMarketAccrued;

            if (totalMarketAccrued > 0) {
                rawMarketsWithRewards[numMarketsWithRewards++] = address(market);
            }

            unchecked { ++i; }
        }

        address[] memory marketsWithRewards = new address[](numMarketsWithRewards);

        for (uint i; i < numMarketsWithRewards;) {
            marketsWithRewards[i] = rawMarketsWithRewards[i];
            unchecked { ++i; }
        }

        return (accrued, marketsWithRewards);
    }

    function updateRewardBorrowIndex(
        uint8 rewardType,
        QiToken qiToken,
        Exp memory marketBorrowIndex
    ) internal view returns (uint224) {
        (uint224 borrowStateIndex, uint32 borrowStateTimestamp) = comptroller.rewardBorrowState(rewardType, address(qiToken));
        uint borrowSpeed = comptroller.borrowRewardSpeeds(rewardType, address(qiToken));
        uint32 blockTimestamp = uint32(block.timestamp);
        uint deltaTimestamps = sub_(blockTimestamp, uint(borrowStateTimestamp));

        if (deltaTimestamps > 0 && borrowSpeed > 0) {
            uint borrowAmount = div_(qiToken.totalBorrows(), marketBorrowIndex);
            uint rewardAccrued = mul_(deltaTimestamps, borrowSpeed);
            Double memory ratio = borrowAmount > 0 ? fraction(rewardAccrued, borrowAmount) : Double({ mantissa: 0 });
            Double memory index = add_(Double({ mantissa: borrowStateIndex }), ratio);

            return uint224(index.mantissa);
        }

        return borrowStateIndex;
    }

    function updateRewardSupplyIndex(
        uint8 rewardType,
        QiToken qiToken
    ) internal view returns (uint) {
        (uint224 supplyStateIndex, uint32 supplyStateTimestamp) = comptroller.rewardSupplyState(rewardType, address(qiToken));
        uint supplySpeed = comptroller.supplyRewardSpeeds(rewardType, address(qiToken));
        uint32 blockTimestamp = uint32(block.timestamp);
        uint deltaTimestamps = sub_(blockTimestamp, uint(supplyStateTimestamp));

        if (deltaTimestamps > 0 && supplySpeed > 0) {
            uint supplyTokens = qiToken.totalSupply();
            uint rewardAccrued = mul_(deltaTimestamps, supplySpeed);
            Double memory ratio = supplyTokens > 0 ? fraction(rewardAccrued, supplyTokens) : Double({ mantissa: 0 });
            Double memory index = add_(Double({ mantissa: supplyStateIndex }), ratio);

            return index.mantissa;
        }

        return supplyStateIndex;
    }

    function distributeBorrowerReward(
        uint8 rewardType,
        QiToken qiToken,
        address borrower,
        uint borrowStateIndex,
        Exp memory marketBorrowIndex
    ) internal view returns (uint) {

        Double memory borrowIndex = Double({ mantissa: borrowStateIndex });
        Double memory borrowerIndex = Double({ mantissa: comptroller.rewardBorrowerIndex(rewardType, address(qiToken), borrower) });

        if (borrowerIndex.mantissa > 0) {
            Double memory deltaIndex = sub_(borrowIndex, borrowerIndex);
            uint borrowerAmount = div_(qiToken.borrowBalanceStored(borrower), marketBorrowIndex);
            uint borrowerDelta = mul_(borrowerAmount, deltaIndex);

            return borrowerDelta;
        }

        return 0;
    }

    function distributeSupplierReward(
        uint8 rewardType,
        QiToken qiToken,
        address supplier,
        uint supplyStateIndex
    ) internal view returns (uint) {
        Double memory supplyIndex = Double({ mantissa: supplyStateIndex });
        Double memory supplierIndex = Double({ mantissa: comptroller.rewardSupplierIndex(rewardType, address(qiToken), supplier) });

        if (supplierIndex.mantissa == 0 && supplyIndex.mantissa > 0) {
            supplierIndex.mantissa = comptroller.initialIndexConstant();
        }

        Double memory deltaIndex = sub_(supplyIndex, supplierIndex);
        uint supplierTokens = qiToken.balanceOf(supplier);
        uint supplierDelta = mul_(supplierTokens, deltaIndex);

        return supplierDelta;
    }

    function updateAndDistributeBorrowerReward(
        uint8 rewardType,
        QiToken qiToken,
        address borrower
    ) internal view returns (uint) {
        Exp memory marketBorrowIndex = Exp({ mantissa: qiToken.borrowIndex() });
        uint borrowStateIndex = updateRewardBorrowIndex(rewardType, qiToken, marketBorrowIndex);

        return distributeBorrowerReward(rewardType, qiToken, borrower, borrowStateIndex, marketBorrowIndex);
    }

    function updateAndDistributeSupplierReward(
        uint8 rewardType,
        QiToken qiToken,
        address supplier
    ) internal view returns (uint) {
        uint supplyStateIndex = updateRewardSupplyIndex(rewardType, qiToken);

        return distributeSupplierReward(rewardType, qiToken, supplier, supplyStateIndex);
    }

    function _isAvaxMarket(QiToken market) internal pure returns (bool) {
        return address(market) == 0x5C0401e81Bc07Ca70fAD469b451682c0d747Ef1c;
    }

    function _qiTokenBalanceToUnderlying(uint qiTokenBalance, QiToken market) internal view returns (uint) {
        uint exchangeRate = market.exchangeRateStored();

        return qiTokenBalance * exchangeRate / 10 ** 18;
    }
}
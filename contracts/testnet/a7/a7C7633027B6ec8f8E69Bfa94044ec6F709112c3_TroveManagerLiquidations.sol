// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "./Interfaces/IWAsset.sol";
import "./Dependencies/TroveManagerBase.sol";

/** 
 * TroveManagerLiquidations is derived from TroveManager and has all the functions 
 * related to Liquidations. 
 */

contract TroveManagerLiquidations is TroveManagerBase {

    address yetiFinanceTreasury;

    struct LiquidationValues {
        uint256 entireTroveDebt;
        newColls entireTroveColl;
        newColls collGasCompensation;
        uint256 YUSDGasCompensation;
        uint256 debtToOffset;
        newColls collToSendToSP;
        uint256 debtToRedistribute;
        newColls collToRedistribute;
        newColls collSurplus;
    }

    struct LiquidationTotals {
        uint256 totalVCInSequence;
        uint256 totalDebtInSequence;
        newColls totalCollGasCompensation;
        uint256 totalYUSDGasCompensation;
        uint256 totalDebtToOffset;
        newColls totalCollToSendToSP;
        uint256 totalDebtToRedistribute;
        newColls totalCollToRedistribute;
        newColls totalCollSurplus;
    }

    struct LocalVariables_LiquidationSequence {
        uint256 remainingYUSDInStabPool;
        uint256 i;
        uint256 ICR;
        address user;
        bool backToNormalMode;
        uint256 entireSystemDebt;
        uint256 entireSystemColl;
    }

    struct LocalVariables_OuterLiquidationFunction {
        uint256 YUSDInStabPool;
        bool recoveryModeAtStart;
        uint256 liquidatedDebt;
    }

    struct LocalVariables_InnerSingleLiquidateFunction {
        newColls collToLiquidate;
        uint256 pendingDebtReward;
        newColls pendingCollReward;
    }

    struct LocalVariables_ORVals {
        uint256 debtToOffset;
        newColls collToSendToSP;
        uint256 debtToRedistribute;
        newColls collToRedistribute;
        newColls collSurplus;
    }

    event TroveLiquidated(
        address indexed _borrower,
        uint256 _debt,
        TroveManagerOperation _operation
    );
    event Liquidation(
        uint256 liquidatedAmount,
        uint256 totalYUSDGasCompensation,
        address[] totalCollTokens,
        uint256[] totalCollAmounts,
        address[] totalCollGasCompTokens,
        uint256[] totalCollGasCompAmounts
    );

    function setAddresses(
        address _borrowerOperationsAddress,
        address _activePoolAddress,
        address _defaultPoolAddress,
        address _stabilityPoolAddress,
        address _gasPoolAddress,
        address _collSurplusPoolAddress,
        address _yusdTokenAddress,
        address _sortedTrovesAddress,
        address _yetiTokenAddress,
        address _sYETIAddress,
        address _whitelistAddress,
        address _troveManagerAddress,
        address _yetiFinanceTreasury
    ) external onlyOwner {
        checkContract(_borrowerOperationsAddress);
        checkContract(_activePoolAddress);
        checkContract(_defaultPoolAddress);
        checkContract(_stabilityPoolAddress);
        checkContract(_gasPoolAddress);
        checkContract(_collSurplusPoolAddress);
        checkContract(_yusdTokenAddress);
        checkContract(_sortedTrovesAddress);
        checkContract(_yetiTokenAddress);
        checkContract(_sYETIAddress);
        checkContract(_whitelistAddress);
        checkContract(_troveManagerAddress);
        checkContract(_yetiFinanceTreasury);

        borrowerOperationsAddress = _borrowerOperationsAddress;
        activePool = IActivePool(_activePoolAddress);
        defaultPool = IDefaultPool(_defaultPoolAddress);
        stabilityPoolContract = IStabilityPool(_stabilityPoolAddress);
        whitelist = IWhitelist(_whitelistAddress);
        gasPoolAddress = _gasPoolAddress;
        collSurplusPool = ICollSurplusPool(_collSurplusPoolAddress);
        yusdTokenContract = IYUSDToken(_yusdTokenAddress);
        sortedTroves = ISortedTroves(_sortedTrovesAddress);
        yetiTokenContract = IYETIToken(_yetiTokenAddress);
        sYETIContract = ISYETI(_sYETIAddress);
        troveManager = ITroveManager(_troveManagerAddress);
        troveManagerAddress = _troveManagerAddress;
        yetiFinanceTreasury = _yetiFinanceTreasury;

        emit BorrowerOperationsAddressChanged(_borrowerOperationsAddress);
        emit ActivePoolAddressChanged(_activePoolAddress);
        emit DefaultPoolAddressChanged(_defaultPoolAddress);
        emit StabilityPoolAddressChanged(_stabilityPoolAddress);
        emit GasPoolAddressChanged(_gasPoolAddress);
        emit CollSurplusPoolAddressChanged(_collSurplusPoolAddress);
        emit YUSDTokenAddressChanged(_yusdTokenAddress);
        emit SortedTrovesAddressChanged(_sortedTrovesAddress);
        emit YETITokenAddressChanged(_yetiTokenAddress);
        emit SYETIAddressChanged(_sYETIAddress);

        _renounceOwnership();
    }

    /** 
     * Function for liquidating a list of troves in a single transaction. Will perform as many as it can 
     * and looks at if it is eligible for liquidation based on the current ICR value. 
     */
    function batchLiquidateTroves(address[] memory _troveArray, address _liquidator) public {
        _requireCallerisTroveManager();
        require(_troveArray.length != 0, "TroveManager: Calldata address array must not be empty");

        IActivePool activePoolCached = activePool;
        IDefaultPool defaultPoolCached = defaultPool;
        IStabilityPool stabilityPoolCached = stabilityPoolContract;

        LocalVariables_OuterLiquidationFunction memory vars;
        LiquidationTotals memory totals;

        vars.YUSDInStabPool = stabilityPoolCached.getTotalYUSDDeposits();
        vars.recoveryModeAtStart = _checkRecoveryMode();

        // Perform the appropriate liquidation sequence - tally values and obtain their totals.
        if (vars.recoveryModeAtStart) {
            totals = _getTotalFromBatchLiquidate_RecoveryMode(
                activePoolCached,
                defaultPoolCached,
                vars.YUSDInStabPool,
                _troveArray
            );
        } else {
            //  if !vars.recoveryModeAtStart
            totals = _getTotalsFromBatchLiquidate_NormalMode(
                activePoolCached,
                defaultPoolCached,
                vars.YUSDInStabPool,
                _troveArray
            );
        }

        require(totals.totalDebtInSequence > 0, "TroveManager: nothing to liquidate");
        // Move liquidated Collateral and YUSD to the appropriate pools
        stabilityPoolCached.offset(
            totals.totalDebtToOffset,
            totals.totalCollToSendToSP.tokens,
            totals.totalCollToSendToSP.amounts
        );
        troveManager.redistributeDebtAndColl(
            activePoolCached,
            defaultPoolCached,
            totals.totalDebtToRedistribute,
            totals.totalCollToRedistribute.tokens,
            totals.totalCollToRedistribute.amounts
        );
        if (_CollsIsNonZero(totals.totalCollSurplus)) {
            activePoolCached.sendCollaterals(
                address(collSurplusPool),
                totals.totalCollSurplus.tokens,
                totals.totalCollSurplus.amounts
            );
        }

        // Update system snapshots
        troveManager.updateSystemSnapshots_excludeCollRemainder(
            activePoolCached,
            totals.totalCollGasCompensation.tokens,
            totals.totalCollGasCompensation.amounts
        );

        vars.liquidatedDebt = totals.totalDebtInSequence;

        // merge the colls into one to emit correct event.
        newColls memory sumCollsResult = _sumColls(
            totals.totalCollToSendToSP,
            totals.totalCollToRedistribute
        );
        sumCollsResult = _sumColls(sumCollsResult, totals.totalCollSurplus);

        emit Liquidation(
            vars.liquidatedDebt,
            totals.totalYUSDGasCompensation,
            sumCollsResult.tokens,
            sumCollsResult.amounts,
            totals.totalCollGasCompensation.tokens,
            totals.totalCollGasCompensation.amounts
        );
        // Send gas compensation to caller
        _sendGasCompensation(
            activePoolCached,
            _liquidator,
            totals.totalYUSDGasCompensation,
            totals.totalCollGasCompensation.tokens,
            totals.totalCollGasCompensation.amounts
        );
    }

    /*
     * This function is used when the batch liquidation sequence starts during Recovery Mode. However, it
     * handle the case where the system *leaves* Recovery Mode, part way through the liquidation sequence
     */
    function _getTotalFromBatchLiquidate_RecoveryMode(
        IActivePool _activePool,
        IDefaultPool _defaultPool,
        uint256 _YUSDInStabPool,
        address[] memory _troveArray
    ) internal returns (LiquidationTotals memory totals) {
        LocalVariables_LiquidationSequence memory vars;
        LiquidationValues memory singleLiquidation;

        vars.remainingYUSDInStabPool = _YUSDInStabPool;
        vars.backToNormalMode = false;
        vars.entireSystemDebt = getEntireSystemDebt();
        // get total VC
        vars.entireSystemColl = getEntireSystemColl();

        for (vars.i = 0; vars.i < _troveArray.length; vars.i++) {
            vars.user = _troveArray[vars.i];

            // Skip non-active troves
            Status userStatus = Status(troveManager.getTroveStatus(vars.user));
            if (userStatus != Status.active) {
                continue;
            }
            vars.ICR = troveManager.getCurrentICR(vars.user);

            if (!vars.backToNormalMode) {
                // Skip this trove if ICR is greater than MCR and Stability Pool is empty
                if (vars.ICR >= MCR && vars.remainingYUSDInStabPool == 0) {
                    continue;
                }

                uint256 TCR = LiquityMath._computeCR(vars.entireSystemColl, vars.entireSystemDebt);

                singleLiquidation = _liquidateRecoveryMode(
                    _activePool,
                    _defaultPool,
                    vars.user,
                    vars.ICR,
                    vars.remainingYUSDInStabPool,
                    TCR
                );

                // Update aggregate trackers
                vars.remainingYUSDInStabPool = vars.remainingYUSDInStabPool.sub(
                    singleLiquidation.debtToOffset
                );
                vars.entireSystemDebt = vars.entireSystemDebt.sub(singleLiquidation.debtToOffset);

                uint256 collToSendToSpVc = _getVCColls(singleLiquidation.collToSendToSP);
                uint256 collGasCompensationTotal = _getVCColls(
                    singleLiquidation.collGasCompensation
                );
                uint256 collSurplusTotal = _getVCColls(singleLiquidation.collSurplus);

                vars.entireSystemColl = vars
                    .entireSystemColl
                    .sub(collToSendToSpVc)
                    .sub(collGasCompensationTotal)
                    .sub(collSurplusTotal);

                // Add liquidation values to their respective running totals
                totals = _addLiquidationValuesToTotals(totals, singleLiquidation);

                vars.backToNormalMode = !_checkPotentialRecoveryMode(
                    vars.entireSystemColl,
                    vars.entireSystemDebt
                );
            } else if (vars.backToNormalMode && vars.ICR < MCR) {
                singleLiquidation = _liquidateNormalMode(
                    _activePool,
                    _defaultPool,
                    vars.user,
                    vars.remainingYUSDInStabPool
                );
                vars.remainingYUSDInStabPool = vars.remainingYUSDInStabPool.sub(
                    singleLiquidation.debtToOffset
                );

                // Add liquidation values to their respective running totals
                totals = _addLiquidationValuesToTotals(totals, singleLiquidation);
            } else continue; // In Normal Mode skip troves with ICR >= MCR
        }
    }

    function _getTotalsFromBatchLiquidate_NormalMode(
        IActivePool _activePool,
        IDefaultPool _defaultPool,
        uint256 _YUSDInStabPool,
        address[] memory _troveArray
    ) internal returns (LiquidationTotals memory totals) {
        LocalVariables_LiquidationSequence memory vars;
        LiquidationValues memory singleLiquidation;

        vars.remainingYUSDInStabPool = _YUSDInStabPool;
        for (vars.i = 0; vars.i < _troveArray.length; vars.i++) {
            vars.user = _troveArray[vars.i];
            vars.ICR = troveManager.getCurrentICR(vars.user);
            if (vars.ICR < MCR) {
                singleLiquidation = _liquidateNormalMode(
                    _activePool,
                    _defaultPool,
                    vars.user,
                    vars.remainingYUSDInStabPool
                );
                vars.remainingYUSDInStabPool = vars.remainingYUSDInStabPool.sub(
                    singleLiquidation.debtToOffset
                );

                // Add liquidation values to their respective running totals
                totals = _addLiquidationValuesToTotals(totals, singleLiquidation);
            }
        }
    }

    // Liquidate one trove, in Normal Mode.
    function _liquidateNormalMode(
        IActivePool _activePool,
        IDefaultPool _defaultPool,
        address _borrower,
        uint256 _YUSDInStabPool
    ) internal returns (LiquidationValues memory singleLiquidation) {
        LocalVariables_InnerSingleLiquidateFunction memory vars;

        (
            singleLiquidation.entireTroveDebt,
            singleLiquidation.entireTroveColl.tokens,
            singleLiquidation.entireTroveColl.amounts,
            vars.pendingDebtReward,
            vars.pendingCollReward.tokens,
            vars.pendingCollReward.amounts
        ) = troveManager.getEntireDebtAndColls(_borrower);

        troveManager.movePendingTroveRewardsToActivePool(
            _activePool,
            _defaultPool,
            vars.pendingDebtReward,
            vars.pendingCollReward.tokens,
            vars.pendingCollReward.amounts, 
            _borrower
        );
        troveManager.removeStakeTLR(_borrower);

        singleLiquidation.collGasCompensation = _getCollGasCompensation(
            singleLiquidation.entireTroveColl
        );

        // WAssets sent as liquidation reward will be unstaked and no longer accrue rewards
        _updateWAssetsRewardOwner(singleLiquidation.collGasCompensation, _borrower, address(0));

        singleLiquidation.YUSDGasCompensation = YUSD_GAS_COMPENSATION;

        vars.collToLiquidate.tokens = singleLiquidation.entireTroveColl.tokens;
        vars.collToLiquidate.amounts = new uint256[](vars.collToLiquidate.tokens.length);

        for (uint256 i = 0; i < vars.collToLiquidate.tokens.length; i++) {
            vars.collToLiquidate.amounts[i] = singleLiquidation.entireTroveColl.amounts[i].sub(
                singleLiquidation.collGasCompensation.amounts[i]
            );
        }

        LocalVariables_ORVals memory or_vals = _getOffsetAndRedistributionVals(
            singleLiquidation.entireTroveDebt,
            vars.collToLiquidate,
            _YUSDInStabPool
        );

        newColls memory collsToUpdate = _sumColls(or_vals.collToSendToSP, or_vals.collToRedistribute);
        // rewards for WAssets sent to SP and collToRedistribute will
        // accrue to Yeti Finance Treasury until the assets are claimed
        _updateWAssetsRewardOwner(collsToUpdate, _borrower, yetiFinanceTreasury);

        singleLiquidation = _updateSingleLiquidation(or_vals, singleLiquidation);
        troveManager.closeTroveLiquidation(_borrower);

        if (_CollsIsNonZero(singleLiquidation.collSurplus)) {
            troveManager.collSurplusUpdate(
                _borrower,
                singleLiquidation.collSurplus.tokens,
                singleLiquidation.collSurplus.amounts
            );
        }

        emit TroveLiquidated(
            _borrower,
            singleLiquidation.entireTroveDebt,
            TroveManagerOperation.liquidateInNormalMode
        );
        newColls memory borrowerColls;
        emit TroveUpdated(
            _borrower,
            0,
            borrowerColls.tokens,
            borrowerColls.amounts,
            TroveManagerOperation.liquidateInNormalMode
        );
        return singleLiquidation;
    }


    // Liquidate one trove, in Recovery Mode.
    function _liquidateRecoveryMode(
        IActivePool _activePool,
        IDefaultPool _defaultPool,
        address _borrower,
        uint256 _ICR,
        uint256 _YUSDInStabPool,
        uint256 _TCR
    ) internal returns (LiquidationValues memory singleLiquidation) {
        LocalVariables_InnerSingleLiquidateFunction memory vars;

        if (troveManager.getTroveOwnersCount() <= 1) {
            return singleLiquidation;
        } // don't liquidate if last trove

        (
            singleLiquidation.entireTroveDebt,
            singleLiquidation.entireTroveColl.tokens,
            singleLiquidation.entireTroveColl.amounts,
            vars.pendingDebtReward,
            vars.pendingCollReward.tokens,
            vars.pendingCollReward.amounts
        ) = troveManager.getEntireDebtAndColls(_borrower);

        singleLiquidation.collGasCompensation = _getCollGasCompensation(
            singleLiquidation.entireTroveColl
        );

        // WAssets sent as liquidation reward will be unstaked and no longer accrue rewards
        _updateWAssetsRewardOwner(singleLiquidation.collGasCompensation, _borrower, address(0));

        singleLiquidation.YUSDGasCompensation = YUSD_GAS_COMPENSATION;

        vars.collToLiquidate.tokens = singleLiquidation.entireTroveColl.tokens;
        vars.collToLiquidate.amounts = new uint256[](vars.collToLiquidate.tokens.length);

        for (uint256 i = 0; i < vars.collToLiquidate.tokens.length; i++) {
            vars.collToLiquidate.amounts[i] = singleLiquidation.entireTroveColl.amounts[i].sub(
                singleLiquidation.collGasCompensation.amounts[i]
            );
        }

        // If ICR <= 100%, purely redistribute the Trove across all active Troves
        if (_ICR <= _100pct) {
            troveManager.movePendingTroveRewardsToActivePool(
                _activePool,
                _defaultPool,
                vars.pendingDebtReward,
                vars.pendingCollReward.tokens,
                vars.pendingCollReward.amounts, 
                _borrower
            );
            // troveManager.movePendingTroveRewardsToActivePool(_activePool, _defaultPool, vars.pendingDebtReward, singleLiquidation.entireTroveColl.tokens, singleLiquidation.entireTroveColl.amounts);
            troveManager.removeStakeTLR(_borrower);

            singleLiquidation.debtToOffset = 0;
            newColls memory emptyColls;
            singleLiquidation.collToSendToSP = emptyColls;
            singleLiquidation.debtToRedistribute = singleLiquidation.entireTroveDebt;
            singleLiquidation.collToRedistribute = vars.collToLiquidate;

            // WAsset rewards for collToRedistribute will accrue to
            // Yeti Finance Treasury until the WAssets are claimed by troves
            _updateWAssetsRewardOwner(singleLiquidation.collToRedistribute, _borrower, yetiFinanceTreasury);

            troveManager.closeTroveLiquidation(_borrower);
            emit TroveLiquidated(
                _borrower,
                singleLiquidation.entireTroveDebt,
                TroveManagerOperation.liquidateInRecoveryMode
            );
            newColls memory borrowerColls;// = troveManager.getTroveColls(_borrower);
            emit TroveUpdated(
                _borrower,
                0,
                borrowerColls.tokens,
                borrowerColls.amounts,
                TroveManagerOperation.liquidateInRecoveryMode
            );

            // If 100% < ICR < MCR, offset as much as possible, and redistribute the remainder
            // ICR > 100% is implied by prevoius state. 
        } else if (_ICR < MCR) {

            troveManager.movePendingTroveRewardsToActivePool(
                _activePool,
                _defaultPool,
                vars.pendingDebtReward,
                vars.pendingCollReward.tokens,
                vars.pendingCollReward.amounts, 
                _borrower
            );

            troveManager.removeStakeTLR(_borrower);

            LocalVariables_ORVals memory or_vals = _getOffsetAndRedistributionVals(
                singleLiquidation.entireTroveDebt,
                vars.collToLiquidate,
                _YUSDInStabPool
            );

            newColls memory collsToUpdate = _sumColls(or_vals.collToSendToSP, or_vals.collToRedistribute);
            // rewards for WAssets sent to SP and collToRedistribute will
            // accrue to Yeti Finance Treasury until the assets are claimed
            _updateWAssetsRewardOwner(collsToUpdate, _borrower, yetiFinanceTreasury);

            singleLiquidation = _updateSingleLiquidation(or_vals, singleLiquidation);

            troveManager.closeTroveLiquidation(_borrower);
            emit TroveLiquidated(
                _borrower,
                singleLiquidation.entireTroveDebt,
                TroveManagerOperation.liquidateInRecoveryMode
            );
            newColls memory borrowerColls;// = troveManager.getTroveColls(_borrower);
            emit TroveUpdated(
                _borrower,
                0,
                borrowerColls.tokens,
                borrowerColls.amounts,
                TroveManagerOperation.liquidateInRecoveryMode
            );
            /*
             * If 110% <= ICR < current TCR (accounting for the preceding liquidations in the current sequence)
             * and there is YUSD in the Stability Pool, only offset, with no redistribution,
             * but at a capped rate of 1.1 and only if the whole debt can be liquidated.
             * The remainder due to the capped rate will be claimable as collateral surplus.
             * ICR >= 110% is implied from last else if statement. 
             */
        } else if (
           (_ICR < _TCR) && (singleLiquidation.entireTroveDebt <= _YUSDInStabPool)
        ) {
            troveManager.movePendingTroveRewardsToActivePool(
                _activePool,
                _defaultPool,
                vars.pendingDebtReward,
                vars.pendingCollReward.tokens,
                vars.pendingCollReward.amounts,
                _borrower
            );

            assert(_YUSDInStabPool != 0);

            troveManager.removeStakeTLR(_borrower);

            singleLiquidation = _getCappedOffsetVals(
                singleLiquidation.entireTroveDebt,
                singleLiquidation.entireTroveColl.tokens,
                singleLiquidation.entireTroveColl.amounts,
                MCR
            );

            newColls memory collsToUpdate = _sumColls(
                singleLiquidation.collToSendToSP,
                singleLiquidation.collToRedistribute
            );
            // rewards for WAssets sent to SP and collToRedistribute will
            // accrue to Yeti Finance Treasury until the assets are claimed
            _updateWAssetsRewardOwner(collsToUpdate, _borrower, yetiFinanceTreasury);

            troveManager.closeTroveLiquidation(_borrower);

            emit TroveLiquidated(
                _borrower,
                singleLiquidation.entireTroveDebt,
                TroveManagerOperation.liquidateInRecoveryMode
            );
            newColls memory borrowerColls;
            emit TroveUpdated(
                _borrower,
                0,
                borrowerColls.tokens,
                borrowerColls.amounts,
                TroveManagerOperation.liquidateInRecoveryMode
            );
        } else {
            // if (_ICR >= MCR && ( _ICR >= _TCR || singleLiquidation.entireTroveDebt > _YUSDInStabPool))
            LiquidationValues memory zeroVals;
            return zeroVals;
        }

        if (_CollsIsNonZero(singleLiquidation.collSurplus)) {
            troveManager.collSurplusUpdate(
                _borrower,
                singleLiquidation.collSurplus.tokens,
                singleLiquidation.collSurplus.amounts
            );
        }

        return singleLiquidation;
    }

    function _updateSingleLiquidation(
        LocalVariables_ORVals memory or_vals,
        LiquidationValues memory singleLiquidation
    ) internal pure returns (LiquidationValues memory) {
        singleLiquidation.debtToOffset = or_vals.debtToOffset;
        singleLiquidation.collToSendToSP = or_vals.collToSendToSP;
        singleLiquidation.debtToRedistribute = or_vals.debtToRedistribute;
        singleLiquidation.collToRedistribute = or_vals.collToRedistribute;
        singleLiquidation.collSurplus = or_vals.collSurplus;
        return singleLiquidation;
    }

    /* In a full liquidation, returns the values for a trove's coll and debt to be offset, and coll and debt to be
     * redistributed to active troves. _colls parameters is the _colls to be liquidated (total trove colls minus collateral for gas compensation)
     * collsToRedistribute.tokens and collsToRedistribute.amounts should be the same length
     * and should be the same length as _colls.tokens and _colls.amounts.
     * If there is any colls redistributed to stability pool, collsToSendToSP.tokens and collsToSendToSP.amounts
     * will be length equal to _colls.tokens and _colls.amounts. However, if no colls are redistributed to stability pool (which is the case when _YUSDInStabPool == 0),
     * then collsToSendToSP.tokens and collsToSendToSP.amounts will be empty.
     */
    function _getOffsetAndRedistributionVals(
        uint256 _entireTroveDebt,
        newColls memory _collsToLiquidate,
        uint256 _YUSDInStabPool
    ) internal view returns (LocalVariables_ORVals memory or_vals) {
        or_vals.collToRedistribute.tokens = _collsToLiquidate.tokens;
        or_vals.collToRedistribute.amounts = new uint256[](_collsToLiquidate.tokens.length);

        if (_YUSDInStabPool > 0) {
            /*
             * Offset as much debt & collateral as possible against the Stability Pool, and redistribute the remainder
             * between all active troves.
             *
             *  If the trove's debt is larger than the deposited YUSD in the Stability Pool:
             *
             *  - Offset an amount of the trove's debt equal to the YUSD in the Stability Pool
             *  - Remainder of trove's debt will be redistributed
             *  - Trove collateral can be partitioned into two parts:
             *  - (1) Offsetting Collateral = (debtToOffset / troveDebt) * Collateral
             *  - (2) Redistributed Collateral = Total Collateral - Offsetting Collateral
             *  - The max offsetting collateral that can be sent to the stability pool is an amount of collateral such that
             *  - the stability pool receives 110% of value of the debtToOffset. Any extra Offsetting Collateral is
             *  - sent to the collSurplusPool and can be claimed by the borrower.
             */
            or_vals.collToSendToSP.tokens = _collsToLiquidate.tokens;
            or_vals.collToSendToSP.amounts = new uint256[](_collsToLiquidate.tokens.length);

            or_vals.collSurplus.tokens = _collsToLiquidate.tokens;
            or_vals.collSurplus.amounts = new uint256[](_collsToLiquidate.tokens.length);

            or_vals.debtToOffset = LiquityMath._min(_entireTroveDebt, _YUSDInStabPool);

            or_vals.debtToRedistribute = _entireTroveDebt.sub(or_vals.debtToOffset);

            uint toLiquidateCollValueUSD = _getUSDColls(_collsToLiquidate);

            // collOffsetRatio: max percentage of the collateral that can be sent to the SP as offsetting collateral
            // collOffsetRatio = percentage of the trove's debt that can be offset by the stability pool
            uint256 collOffsetRatio = _100pct.mul(_100pct).mul(or_vals.debtToOffset).div(_entireTroveDebt);

            // SPRatio: percentage of liquidated collateral that needs to be sent to SP in order to give SP depositors
            // $110 of collateral for every 100 YUSD they are using to liquidate.
            uint256 SPRatio = or_vals.debtToOffset.mul(_100pct).mul(_110pct).div(toLiquidateCollValueUSD);

            // But SP ratio is capped at collOffsetRatio:
            SPRatio = LiquityMath._min(collOffsetRatio, SPRatio);

            // if there is extra collateral left in the offset portion of the collateral after
            // giving stability pool holders $110 of collateral for every 100 YUSD that is taken from them,
            // then this is surplus collateral that can be claimed by the borrower
            uint256 collSurplusRatio = collOffsetRatio.sub(SPRatio);

            for (uint256 i = 0; i < _collsToLiquidate.tokens.length; i++) {
                or_vals.collToSendToSP.amounts[i] = _collsToLiquidate.amounts[i].mul(SPRatio).div(
                    _100pct
                ).div(_100pct);

                or_vals.collSurplus.amounts[i] = _collsToLiquidate
                    .amounts[i]
                    .mul(collSurplusRatio)
                    .div(_100pct)
                    .div(_100pct);

                // remaining collateral is redistributed:
                or_vals.collToRedistribute.amounts[i] = _collsToLiquidate
                    .amounts[i]
                    .sub(or_vals.collToSendToSP.amounts[i])
                    .sub(or_vals.collSurplus.amounts[i]);
            }
        } else {
            // all colls are redistributed because no YUSD in stability pool to liquidate
            or_vals.debtToOffset = 0;
            for (uint256 i = 0; i < _collsToLiquidate.tokens.length; i++) {
                or_vals.collToRedistribute.amounts[i] = _collsToLiquidate.amounts[i];
            }
            or_vals.debtToRedistribute = _entireTroveDebt;
        }
    }

    function _addLiquidationValuesToTotals(
        LiquidationTotals memory oldTotals,
        LiquidationValues memory singleLiquidation
    ) internal view returns (LiquidationTotals memory newTotals) {
        // Tally all the values with their respective running totals
        //update one of these
        newTotals.totalCollGasCompensation = _sumColls(
            oldTotals.totalCollGasCompensation,
            singleLiquidation.collGasCompensation
        );
        newTotals.totalYUSDGasCompensation = oldTotals.totalYUSDGasCompensation.add(
            singleLiquidation.YUSDGasCompensation
        );
        newTotals.totalDebtInSequence = oldTotals.totalDebtInSequence.add(
            singleLiquidation.entireTroveDebt
        );
        newTotals.totalDebtToOffset = oldTotals.totalDebtToOffset.add(
            singleLiquidation.debtToOffset
        );
        newTotals.totalCollToSendToSP = _sumColls(
            oldTotals.totalCollToSendToSP,
            singleLiquidation.collToSendToSP
        );
        newTotals.totalDebtToRedistribute = oldTotals.totalDebtToRedistribute.add(
            singleLiquidation.debtToRedistribute
        );
        newTotals.totalCollToRedistribute = _sumColls(
            oldTotals.totalCollToRedistribute,
            singleLiquidation.collToRedistribute
        );
        newTotals.totalCollSurplus = _sumColls(
            oldTotals.totalCollSurplus,
            singleLiquidation.collSurplus
        );

        return newTotals;
    }

    /*
    *  Get its offset coll/debt and Collateral gas comp, and close the trove.
    */
    function _getCappedOffsetVals
    (
        uint _entireTroveDebt,
        address[] memory _troveTokens,
        uint[] memory _troveAmounts,
        uint _MCR
    )
    internal
    view
    returns (LiquidationValues memory singleLiquidation)
    {
        newColls memory _entireTroveColl;
        _entireTroveColl.tokens = _troveTokens;
        _entireTroveColl.amounts = _troveAmounts;

        uint USD_Value_To_Send_To_SP = _MCR.mul(_entireTroveDebt).div(_100pct);
        uint USD_Value_of_Trove_Colls = _getUSDColls(_entireTroveColl);

        uint SPRatio = USD_Value_To_Send_To_SP.mul(_100pct).div(USD_Value_of_Trove_Colls);
        SPRatio = LiquityMath._min(SPRatio, _100pct);


        singleLiquidation.entireTroveDebt = _entireTroveDebt;
        singleLiquidation.entireTroveColl = _entireTroveColl;

        singleLiquidation.YUSDGasCompensation = YUSD_GAS_COMPENSATION;

        singleLiquidation.debtToOffset = _entireTroveDebt;
        singleLiquidation.debtToRedistribute = 0;

        singleLiquidation.collToSendToSP.tokens = _troveTokens;
        singleLiquidation.collToSendToSP.amounts = new uint[](_troveTokens.length);

        singleLiquidation.collSurplus.tokens = _troveTokens;
        singleLiquidation.collSurplus.amounts = new uint[](_troveTokens.length);

        singleLiquidation.collGasCompensation.tokens = _troveTokens;
        singleLiquidation.collGasCompensation.amounts = new uint[](_troveTokens.length);

        for (uint i = 0; i < _troveTokens.length; i++) {
            uint _cappedCollAmount = SPRatio.mul(_troveAmounts[i]).div(_100pct);
            uint _gasComp = _cappedCollAmount.div(PERCENT_DIVISOR);
            uint _toSP = _cappedCollAmount.sub(_gasComp);
            uint _collSurplus = _troveAmounts[i].sub(_cappedCollAmount);

            singleLiquidation.collGasCompensation.amounts[i] = _gasComp;
            singleLiquidation.collToSendToSP.amounts[i] = _toSP;
            singleLiquidation.collSurplus.amounts[i] = _collSurplus;
        }
    }

    function _sendGasCompensation(
        IActivePool _activePool,
        address _liquidator,
        uint256 _YUSD,
        address[] memory _tokens,
        uint256[] memory _amounts
    ) internal {
        if (_YUSD > 0) {
            yusdTokenContract.returnFromPool(gasPoolAddress, _liquidator, _YUSD);
        }

        _activePool.sendCollateralsUnwrap(_liquidator, _tokens, _amounts, false);
    }

    /*
     * Update rewards tracking so future rewards go to Yeti Finance Treasury
     * for the trove's asset that have been liquidated and moved to either the
     * Stability Pool or Default Pool
    */
    function _updateWAssetsRewardOwner(newColls memory _colls, address _borrower, address _newOwner) internal {
        for (uint i = 0; i < _colls.tokens.length; i++) {
            address token = _colls.tokens[i];
            uint amount = _colls.amounts[i];
            if (whitelist.isWrapped(token)) {
                IWAsset(token).updateReward(_borrower, _newOwner, amount);
            }
        }
    }

    function _requireCallerisTroveManager() internal view {
        require(msg.sender == troveManagerAddress);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;


// Wrapped Asset
interface IWAsset  {

    function wrap(uint _amount, address _from, address _to, address _rewardOwner) external;

    function unwrapFor(address _for, uint amount) external;

    function updateReward(address from, address to, uint amount) external;

    function claimReward(address _to) external;

    function claimRewardFor(address _for) external;

    function getPendingRewards(address _for) external returns (address[] memory tokens, uint[] memory amounts);

    function endTreasuryReward(uint _amount) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "../Interfaces/ITroveManager.sol";
import "../Interfaces/IStabilityPool.sol";
import "../Interfaces/ICollSurplusPool.sol";
import "../Interfaces/IYUSDToken.sol";
import "../Interfaces/ISortedTroves.sol";
import "../Interfaces/IYETIToken.sol";
import "../Interfaces/ISYETI.sol";
import "../Interfaces/IActivePool.sol";
import "../Interfaces/IWhitelist.sol";
import "../Interfaces/ITroveManagerLiquidations.sol";
import "../Interfaces/ITroveManagerRedemptions.sol";
import "./LiquityBase.sol";
import "./Ownable.sol";
import "./CheckContract.sol";

/** 
 * Contains shared functionality of TroveManagerLiquidations, TroveManagerRedemptions, and TroveManager. 
 * Keeps addresses to cache, events, structs, status, etc. Also keeps Trove struct. 
 */

contract TroveManagerBase is LiquityBase, Ownable, CheckContract {

    // --- Connected contract declarations ---

    address public borrowerOperationsAddress;

    IStabilityPool stabilityPoolContract;

    ITroveManager public troveManager;

    IYUSDToken yusdTokenContract;

    IYETIToken yetiTokenContract;

    ISYETI sYETIContract;

    ITroveManagerRedemptions troveManagerRedemptions;

    ITroveManagerLiquidations troveManagerLiquidations;

    address gasPoolAddress;

    address public troveManagerAddress;
    address public troveManagerRedemptionsAddress;
    address public troveManagerLiquidationsAddress;

    // A doubly linked list of Troves, sorted by their sorted by their individual collateral ratios
    ISortedTroves public sortedTroves;

    ICollSurplusPool collSurplusPool;

    struct ContractsCache {
        IActivePool activePool;
        IDefaultPool defaultPool;
        IYUSDToken yusdToken;
        ISYETI sYETI;
        ISortedTroves sortedTroves;
        ICollSurplusPool collSurplusPool;
        address gasPoolAddress;
    }

    struct SingleRedemptionValues {
        uint YUSDLot;
        newColls CollLot;
        bool cancelledPartial;
    }

    enum Status {
        nonExistent,
        active,
        closedByOwner,
        closedByLiquidation,
        closedByRedemption
    }

    enum TroveManagerOperation {
        applyPendingRewards,
        liquidateInNormalMode,
        liquidateInRecoveryMode,
        redeemCollateral
    }

    // Store the necessary data for a trove
    struct Trove {
        newColls colls;
        uint debt;
        mapping(address => uint) stakes;
        Status status;
        uint128 arrayIndex;
    }

    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event YUSDTokenAddressChanged(address _newYUSDTokenAddress);
    event ActivePoolAddressChanged(address _activePoolAddress);
    event DefaultPoolAddressChanged(address _defaultPoolAddress);
    event StabilityPoolAddressChanged(address _stabilityPoolAddress);
    event GasPoolAddressChanged(address _gasPoolAddress);
    event CollSurplusPoolAddressChanged(address _collSurplusPoolAddress);
    event SortedTrovesAddressChanged(address _sortedTrovesAddress);
    event YETITokenAddressChanged(address _yetiTokenAddress);
    event SYETIAddressChanged(address _sYETIAddress);

    event TroveUpdated(address indexed _borrower, uint _debt, address[] _tokens, uint[] _amounts, TroveManagerOperation operation);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "./ILiquityBase.sol";
import "./IStabilityPool.sol";
import "./IYUSDToken.sol";
import "./IYETIToken.sol";
import "./ISYETI.sol";
import "./IActivePool.sol";
import "./IDefaultPool.sol";


// Common interface for the Trove Manager.
interface ITroveManager is ILiquityBase {

    // --- Events ---

    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event PriceFeedAddressChanged(address _newPriceFeedAddress);
    event YUSDTokenAddressChanged(address _newYUSDTokenAddress);
    event ActivePoolAddressChanged(address _activePoolAddress);
    event DefaultPoolAddressChanged(address _defaultPoolAddress);
    event StabilityPoolAddressChanged(address _stabilityPoolAddress);
    event GasPoolAddressChanged(address _gasPoolAddress);
    event CollSurplusPoolAddressChanged(address _collSurplusPoolAddress);
    event SortedTrovesAddressChanged(address _sortedTrovesAddress);
    event YETITokenAddressChanged(address _yetiTokenAddress);
    event SYETIAddressChanged(address _sYETIAddress);

    event Liquidation(uint liquidatedAmount, uint totalYUSDGasCompensation, 
        address[] totalCollTokens, uint[] totalCollAmounts,
        address[] totalCollGasCompTokens, uint[] totalCollGasCompAmounts);
    event Redemption(uint _attemptedYUSDAmount, uint _actualYUSDAmount, uint YUSDfee, address[] tokens, uint[] amounts);
    event TroveLiquidated(address indexed _borrower, uint _debt, uint _coll, uint8 operation);
    event BaseRateUpdated(uint _baseRate);
    event LastFeeOpTimeUpdated(uint _lastFeeOpTime);
    event TotalStakesUpdated(address token, uint _newTotalStakes);
    event SystemSnapshotsUpdated(uint _totalStakesSnapshot, uint _totalCollateralSnapshot);
    event LTermsUpdated(uint _L_ETH, uint _L_YUSDDebt);
    event TroveSnapshotsUpdated(uint _L_ETH, uint _L_YUSDDebt);
    event TroveIndexUpdated(address _borrower, uint _newIndex);

    // --- Functions ---

    function setAddresses(
        address _borrowerOperationsAddress,
        address _activePoolAddress,
        address _defaultPoolAddress,
        address _stabilityPoolAddress,
        address _gasPoolAddress,
        address _collSurplusPoolAddress,
        address _yusdTokenAddress,
        address _sortedTrovesAddress,
        address _yetiTokenAddress,
        address _sYETIAddress,
        address _whitelistAddress,
        address _troveManagerRedemptionsAddress,
        address _troveManagerLiquidationsAddress
    )
    external;

    function stabilityPool() external view returns (IStabilityPool);
    function yusdToken() external view returns (IYUSDToken);
    function yetiToken() external view returns (IYETIToken);
    function sYETI() external view returns (ISYETI);

    function getTroveOwnersCount() external view returns (uint);

    function getTroveFromTroveOwnersArray(uint _index) external view returns (address);

    function getCurrentICR(address _borrower) external view returns (uint);

    function liquidate(address _borrower) external;

    function batchLiquidateTroves(address[] calldata _troveArray, address _liquidator) external;

    function redeemCollateral(
        uint _YUSDAmount,
        uint _YUSDMaxFee,
        address _firstRedemptionHint,
        address _upperPartialRedemptionHint,
        address _lowerPartialRedemptionHint,
        uint _partialRedemptionHintNICR,
        uint _maxIterations
    ) external;

    function updateStakeAndTotalStakes(address _borrower) external;

    function updateTroveCollTMR(address  _borrower, address[] memory addresses, uint[] memory amounts) external;

    function updateTroveRewardSnapshots(address _borrower) external;

    function addTroveOwnerToArray(address _borrower) external returns (uint index);

    function applyPendingRewards(address _borrower) external;

//    function getPendingETHReward(address _borrower) external view returns (uint);
    function getPendingCollRewards(address _borrower) external view returns (address[] memory, uint[] memory);

    function getPendingYUSDDebtReward(address _borrower) external view returns (uint);

     function hasPendingRewards(address _borrower) external view returns (bool);

//    function getEntireDebtAndColl(address _borrower) external view returns (
//        uint debt,
//        uint coll,
//        uint pendingYUSDDebtReward,
//        uint pendingETHReward
//    );

    function closeTrove(address _borrower) external;

    function removeStake(address _borrower) external;

    function removeStakeTMR(address _borrower) external;
    function updateTroveDebt(address _borrower, uint debt) external;

    function getRedemptionRate() external view returns (uint);
    function getRedemptionRateWithDecay() external view returns (uint);

    function getRedemptionFeeWithDecay(uint _ETHDrawn) external view returns (uint);

    function getBorrowingRate() external view returns (uint);
    function getBorrowingRateWithDecay() external view returns (uint);

    function getBorrowingFee(uint YUSDDebt) external view returns (uint);
    function getBorrowingFeeWithDecay(uint _YUSDDebt) external view returns (uint);

    function decayBaseRateFromBorrowing() external;

    function getTroveStatus(address _borrower) external view returns (uint);

    function isTroveActive(address _borrower) external view returns (bool);

    function getTroveStake(address _borrower, address _token) external view returns (uint);

    function getTotalStake(address _token) external view returns (uint);

    function getTroveDebt(address _borrower) external view returns (uint);

    function getL_Coll(address _token) external view returns (uint);

    function getL_YUSD(address _token) external view returns (uint);

    function getRewardSnapshotColl(address _borrower, address _token) external view returns (uint);

    function getRewardSnapshotYUSD(address _borrower, address _token) external view returns (uint);

    // returns the VC value of a trove
    function getTroveVC(address _borrower) external view returns (uint);

    function getTroveColls(address _borrower) external view returns (address[] memory, uint[] memory);

    function getCurrentTroveState(address _borrower) external view returns (address[] memory, uint[] memory, uint);

    function setTroveStatus(address _borrower, uint num) external;

    function updateTroveColl(address _borrower, address[] memory _tokens, uint[] memory _amounts) external;

    function increaseTroveDebt(address _borrower, uint _debtIncrease) external returns (uint);

    function decreaseTroveDebt(address _borrower, uint _collDecrease) external returns (uint);

    function getTCR() external view returns (uint);

    function checkRecoveryMode() external view returns (bool);

    function closeTroveRedemption(address _borrower) external;

    function closeTroveLiquidation(address _borrower) external;

    function removeStakeTLR(address _borrower) external;

    function updateBaseRate(uint newBaseRate) external;

    function calcDecayedBaseRate() external view returns (uint);

    function redistributeDebtAndColl(IActivePool _activePool, IDefaultPool _defaultPool, uint _debt, address[] memory _tokens, uint[] memory _amounts) external;

    function updateSystemSnapshots_excludeCollRemainder(IActivePool _activePool, address[] memory _tokens, uint[] memory _amounts) external;

    function getEntireDebtAndColls(address _borrower) external view
    returns (uint, address[] memory, uint[] memory, uint, address[] memory, uint[] memory);

    function movePendingTroveRewardsToActivePool(IActivePool _activePool, IDefaultPool _defaultPool, uint _YUSD, address[] memory _tokens, uint[] memory _amounts, address _borrower) external;

    function collSurplusUpdate(address _account, address[] memory _tokens, uint[] memory _amounts) external;

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "./ICollateralReceiver.sol";

/*
 * The Stability Pool holds YUSD tokens deposited by Stability Pool depositors.
 *
 * When a trove is liquidated, then depending on system conditions, some of its YUSD debt gets offset with
 * YUSD in the Stability Pool:  that is, the offset debt evaporates, and an equal amount of YUSD tokens in the Stability Pool is burned.
 *
 * Thus, a liquidation causes each depositor to receive a YUSD loss, in proportion to their deposit as a share of total deposits.
 * They also receive an ETH gain, as the ETH collateral of the liquidated trove is distributed among Stability depositors,
 * in the same proportion.
 *
 * When a liquidation occurs, it depletes every deposit by the same fraction: for example, a liquidation that depletes 40%
 * of the total YUSD in the Stability Pool, depletes 40% of each deposit.
 *
 * A deposit that has experienced a series of liquidations is termed a "compounded deposit": each liquidation depletes the deposit,
 * multiplying it by some factor in range ]0,1[
 *
 * Please see the implementation spec in the proof document, which closely follows on from the compounded deposit / ETH gain derivations:
 * https://github.com/liquity/liquity/blob/master/papers/Scalable_Reward_Distribution_with_Compounding_Stakes.pdf
 *
 * --- YETI ISSUANCE TO STABILITY POOL DEPOSITORS ---
 *
 * An YETI issuance event occurs at every deposit operation, and every liquidation.
 *
 * Each deposit is tagged with the address of the front end through which it was made.
 *
 * All deposits earn a share of the issued YETI in proportion to the deposit as a share of total deposits. The YETI earned
 * by a given deposit, is split between the depositor and the front end through which the deposit was made, based on the front end's kickbackRate.
 *
 * Please see the system Readme for an overview:
 * https://github.com/liquity/dev/blob/main/README.md#yeti-issuance-to-stability-providers
 */
interface IStabilityPool is ICollateralReceiver {

    // --- Events ---
    
    event StabilityPoolETHBalanceUpdated(uint _newBalance);
    event StabilityPoolYUSDBalanceUpdated(uint _newBalance);

    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event ActivePoolAddressChanged(address _newActivePoolAddress);
    event DefaultPoolAddressChanged(address _newDefaultPoolAddress);
    event YUSDTokenAddressChanged(address _newYUSDTokenAddress);
    event SortedTrovesAddressChanged(address _newSortedTrovesAddress);
    event PriceFeedAddressChanged(address _newPriceFeedAddress);
    event CommunityIssuanceAddressChanged(address _newCommunityIssuanceAddress);

    event P_Updated(uint _P);
    event S_Updated(uint _S, uint128 _epoch, uint128 _scale);
    event G_Updated(uint _G, uint128 _epoch, uint128 _scale);
    event EpochUpdated(uint128 _currentEpoch);
    event ScaleUpdated(uint128 _currentScale);

    event FrontEndRegistered(address indexed _frontEnd, uint _kickbackRate);
    event FrontEndTagSet(address indexed _depositor, address indexed _frontEnd);

    event DepositSnapshotUpdated(address indexed _depositor, uint _P, uint _S, uint _G);
    event FrontEndSnapshotUpdated(address indexed _frontEnd, uint _P, uint _G);
    event UserDepositChanged(address indexed _depositor, uint _newDeposit);
    event FrontEndStakeChanged(address indexed _frontEnd, uint _newFrontEndStake, address _depositor);

    event ETHGainWithdrawn(address indexed _depositor, uint _ETH, uint _YUSDLoss);
    event YETIPaidToDepositor(address indexed _depositor, uint _YETI);
    event YETIPaidToFrontEnd(address indexed _frontEnd, uint _YETI);
    event EtherSent(address _to, uint _amount);

    // --- Functions ---

    /*
     * Called only once on init, to set addresses of other Liquity contracts
     * Callable only by owner, renounces ownership at the end
     */
    function setAddresses(
        address _borrowerOperationsAddress,
        address _troveManagerAddress,
        address _activePoolAddress,
        address _yusdTokenAddress,
        address _sortedTrovesAddress,
        address _communityIssuanceAddress,
        address _whitelistAddress,
        address _troveManagerLiquidationsAddress
    )
        external;

    /*
     * Initial checks:
     * - Frontend is registered or zero address
     * - Sender is not a registered frontend
     * - _amount is not zero
     * ---
     * - Triggers a YETI issuance, based on time passed since the last issuance. The YETI issuance is shared between *all* depositors and front ends
     * - Tags the deposit with the provided front end tag param, if it's a new deposit
     * - Sends depositor's accumulated gains (YETI, ETH) to depositor
     * - Sends the tagged front end's accumulated YETI gains to the tagged front end
     * - Increases deposit and tagged front end's stake, and takes new snapshots for each.
     */
    function provideToSP(uint _amount, address _frontEndTag) external;

    /*
     * Initial checks:
     * - _amount is zero or there are no under collateralized troves left in the system
     * - User has a non zero deposit
     * ---
     * - Triggers a YETI issuance, based on time passed since the last issuance. The YETI issuance is shared between *all* depositors and front ends
     * - Removes the deposit's front end tag if it is a full withdrawal
     * - Sends all depositor's accumulated gains (YETI, ETH) to depositor
     * - Sends the tagged front end's accumulated YETI gains to the tagged front end
     * - Decreases deposit and tagged front end's stake, and takes new snapshots for each.
     *
     * If _amount > userDeposit, the user withdraws all of their compounded deposit.
     */
    function withdrawFromSP(uint _amount) external;


    /*
     * Initial checks:
     * - Frontend (sender) not already registered
     * - User (sender) has no deposit
     * - _kickbackRate is in the range [0, 100%]
     * ---
     * Front end makes a one-time selection of kickback rate upon registering
     */
    function registerFrontEnd(uint _kickbackRate) external;

    /*
     * Initial checks:
     * - Caller is TroveManager
     * ---
     * Cancels out the specified debt against the YUSD contained in the Stability Pool (as far as possible)
     * and transfers the Trove's ETH collateral from ActivePool to StabilityPool.
     * Only called by liquidation functions in the TroveManager.
     */
    function offset(uint _debt, address[] memory _assets, uint[] memory _amountsAdded) external;

//    /*
//     * Returns the total amount of ETH held by the pool, accounted in an internal variable instead of `balance`,
//     * to exclude edge cases like ETH received from a self-destruct.
//     */
//    function getETH() external view returns (uint);
    
     //*
//     * Calculates and returns the total gains a depositor has accumulated 
//     */
    function  getDepositorGains(address _depositor) external view returns (address[] memory assets, uint[] memory amounts);


    /*
     * Returns the total amount of VC held by the pool, accounted for by multipliying the
     * internal balances of collaterals by the price that is found at the time getVC() is called.
     */
    function getVC() external view returns (uint);

    /*
     * Returns YUSD held in the pool. Changes when users deposit/withdraw, and when Trove debt is offset.
     */
    function getTotalYUSDDeposits() external view returns (uint);

    /*
     * Calculate the YETI gain earned by a deposit since its last snapshots were taken.
     * If not tagged with a front end, the depositor gets a 100% cut of what their deposit earned.
     * Otherwise, their cut of the deposit's earnings is equal to the kickbackRate, set by the front end through
     * which they made their deposit.
     */
    function getDepositorYETIGain(address _depositor) external view returns (uint);

    /*
     * Return the YETI gain earned by the front end.
     */
    function getFrontEndYETIGain(address _frontEnd) external view returns (uint);

    /*
     * Return the user's compounded deposit.
     */
    function getCompoundedYUSDDeposit(address _depositor) external view returns (uint);

    /*
     * Return the front end's compounded stake.
     *
     * The front end's compounded stake is equal to the sum of its depositors' compounded deposits.
     */
    function getCompoundedFrontEndStake(address _frontEnd) external view returns (uint);

    /*
     * Add collateral type to totalColl 
     */
    function addCollateralType(address _collateral) external;

    function getDepositSnapshotS(address depositor, address collateral) external view returns (uint);

    function getCollateral(address _collateral) external view returns (uint);

    function getAllCollateral() external view returns (address[] memory, uint256[] memory);

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "../Dependencies/YetiCustomBase.sol";
import "./ICollateralReceiver.sol";


interface ICollSurplusPool is ICollateralReceiver {

    // --- Events ---
    
    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event ActivePoolAddressChanged(address _newActivePoolAddress);

    event CollBalanceUpdated(address indexed _account);
    event CollateralSent(address _to);

    // --- Contract setters ---

    function setAddresses(
        address _borrowerOperationsAddress,
        address _troveManagerAddress,
        address _troveManagerRedemptionsAddress,
        address _activePoolAddress,
        address _whitelistAddress
    ) external;

    function getCollVC() external view returns (uint);

    function getAmountClaimable(address _account, address _collateral) external view returns (uint);

    function getCollateral(address _collateral) external view returns (uint);

    function getAllCollateral() external view returns (address[] memory, uint256[] memory);

    function accountSurplus(address _account, address[] memory _tokens, uint[] memory _amounts) external;

    function claimColl(address _account) external;

    function addCollateralType(address _collateral) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "../Interfaces/IERC20.sol";
import "../Interfaces/IERC2612.sol";

interface IYUSDToken is IERC20, IERC2612 {
    
    // --- Events ---

    event TroveManagerAddressChanged(address _troveManagerAddress);
    event StabilityPoolAddressChanged(address _newStabilityPoolAddress);
    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);

    event YUSDTokenBalanceUpdated(address _user, uint _amount);

    // --- Functions ---

    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;

    function sendToPool(address _sender,  address poolAddress, uint256 _amount) external;

    function returnFromPool(address poolAddress, address user, uint256 _amount ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

// Common interface for the SortedTroves Doubly Linked List.
interface ISortedTroves {

    // --- Events ---
    
    event SortedTrovesAddressChanged(address _sortedDoublyLLAddress);
    event BorrowerOperationsAddressChanged(address _borrowerOperationsAddress);
    event NodeAdded(address _id, uint _NICR);
    event NodeRemoved(address _id);

    // --- Functions ---
    
    function setParams(uint256 _size, address _TroveManagerAddress, address _borrowerOperationsAddress, address _troveManagerRedemptionsAddress) external;

    function insert(address _id, uint256 _ICR, address _prevId, address _nextId) external;

    function remove(address _id) external;

    function reInsert(address _id, uint256 _newICR, address _prevId, address _nextId) external;

    function contains(address _id) external view returns (bool);

    function isFull() external view returns (bool);

    function isEmpty() external view returns (bool);

    function getSize() external view returns (uint256);

    function getMaxSize() external view returns (uint256);

    function getFirst() external view returns (address);

    function getLast() external view returns (address);

    function getNext(address _id) external view returns (address);

    function getPrev(address _id) external view returns (address);

    function getOldICR(address _id) external view returns (uint256);

    function validInsertPosition(uint256 _ICR, address _prevId, address _nextId) external view returns (bool);

    function findInsertPosition(uint256 _ICR, address _prevId, address _nextId) external view returns (address, address);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "./IERC20.sol";
import "./IERC2612.sol";

interface IYETIToken is IERC20, IERC2612 {

    function sendToSYETI(address _sender, uint256 _amount) external;

    function getDeploymentStartTime() external view returns (uint256);

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

interface ISYETI {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    function mint(uint256 amount) external returns (bool);
    function burn(address to, uint256 shares) external returns (bool);

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

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "./IPool.sol";

    
interface IActivePool is IPool {
    // --- Events ---
    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event ActivePoolYUSDDebtUpdated(uint _YUSDDebt);
    event ActivePoolCollateralBalanceUpdated(address _collateral, uint _amount);

    // --- Functions ---
    
    function sendCollaterals(address _to, address[] memory _tokens, uint[] memory _amounts) external returns (bool);
    function sendCollateralsUnwrap(
        address _to,
        address[] memory _tokens,
        uint[] memory _amounts,
        bool _collectRewards) external returns (bool);
    function getCollateralVC(address collateralAddress) external view returns (uint);
    function addCollateralType(address _collateral) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;


interface IWhitelist {
    function getValidCollateral() view external returns (address[] memory);

    function setAddresses(
        address _activePoolAddress,
        address _defaultPoolAddress,
        address _stabilityPoolAddress,
        address _collSurplusPoolAddress, 
        address _borrowerOperationsAddress
    ) external;

    function isValidRouter(address _router) external view returns (bool);
    function getOracle(address _collateral) view external returns (address);
    function getRatio(address _collateral) view external returns (uint256);
    function getIsActive(address _collateral) view external returns (bool);
    function getPriceCurve(address _collateral) external view returns (address);
    function getDecimals(address _collateral) external view returns (uint256);
    function getFee(address _collateral, uint _collateralVCInput, uint256 _collateralVCBalancePost, uint256 _totalVCBalancePre, uint256 _totalVCBalancePost) external view returns (uint256 fee);
    function getFeeAndUpdate(address _collateral, uint _collateralVCInput, uint256 _collateralVCBalancePost, uint256 _totalVCBalancePre, uint256 _totalVCBalancePost) external returns (uint256 fee);
    function getIndex(address _collateral) external view returns (uint256);
    function isWrapped(address _collateral) external view returns (bool);
    function setDefaultRouter(address _collateral, address _router) external;

    function getValueVC(address _collateral, uint _amount) view external returns (uint);
    function getValueUSD(address _collateral, uint _amount) view external returns (uint256);
    function getDefaultRouterAddress(address _collateral) external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;


interface ITroveManagerLiquidations {
    function batchLiquidateTroves(address[] memory _troveArray, address _liquidator) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

interface ITroveManagerRedemptions {
    function redeemCollateral(
        uint _YUSDamount,
        uint _YUSDMaxFee,
        address _firstRedemptionHint,
        address _upperPartialRedemptionHint,
        address _lowerPartialRedemptionHint,
        uint _partialRedemptionHintNICR,
        uint _maxIterations,
        // uint _maxFeePercentage,
        address _redeemSender
    )
    external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "./LiquityMath.sol";
import "../Interfaces/IActivePool.sol";
import "../Interfaces/IDefaultPool.sol";
import "../Interfaces/ILiquityBase.sol";
import "../Interfaces/IWhitelist.sol";
import "./YetiCustomBase.sol";


/* 
* Base contract for TroveManager, BorrowerOperations and StabilityPool. Contains global system constants and
* common functions. 
*/
contract LiquityBase is ILiquityBase, YetiCustomBase {

    uint constant public _100pct = 1000000000000000000; // 1e18 == 100%

    uint constant public _110pct = 1100000000000000000; // 1.1e18 == 110%

    // Minimum collateral ratio for individual troves
    uint constant public MCR = 1100000000000000000; // 110%

    // Critical system collateral ratio. If the system's total collateral ratio (TCR) falls below the CCR, Recovery Mode is triggered.
    uint constant public CCR = 1500000000000000000; // 150%

    // Amount of YUSD to be locked in gas pool on opening troves
    uint constant public YUSD_GAS_COMPENSATION = 200e18;

    // Minimum amount of net YUSD debt a must have
    uint constant public MIN_NET_DEBT = 1800e18;
    // uint constant public MIN_NET_DEBT = 0; 

    uint constant public PERCENT_DIVISOR = 200; // dividing by 200 yields 0.5%

    uint constant public BORROWING_FEE_FLOOR = DECIMAL_PRECISION / 1000 * 5; // 0.5%
    uint constant public REDEMPTION_FEE_FLOOR = DECIMAL_PRECISION / 1000 * 5; // 0.5%

    IActivePool public activePool;

    IDefaultPool public defaultPool;

    // --- Gas compensation functions ---

    // Returns the composite debt (drawn debt + gas compensation) of a trove, for the purpose of ICR calculation
    function _getCompositeDebt(uint _debt) internal pure returns (uint) {
        return _debt.add(YUSD_GAS_COMPENSATION);
    }


    function _getNetDebt(uint _debt) internal pure returns (uint) {
        return _debt.sub(YUSD_GAS_COMPENSATION);
    }


    // Return the amount of collateral to be drawn from a trove's collateral and sent as gas compensation.
    function _getCollGasCompensation(newColls memory _coll) internal pure returns (newColls memory) {
        require(_coll.tokens.length == _coll.amounts.length, "_getCollGasCompensation(): Collateral length mismatch");

        uint[] memory amounts = new uint[](_coll.tokens.length);
        for (uint i = 0; i < _coll.tokens.length; i++) {
            amounts[i] = _coll.amounts[i] / PERCENT_DIVISOR;
        }
        return newColls(_coll.tokens, amounts);
    }

    // Return the system's Total Virtual Coin Balance
    // Virtual Coins are a way to keep track of the system collateralization given
    // the collateral ratios of each collateral type
    function getEntireSystemColl() public view returns (uint entireSystemColl) {
        uint activeColl = activePool.getVC();
        uint liquidatedColl = defaultPool.getVC();

        return activeColl.add(liquidatedColl);
    }


    function getEntireSystemDebt() public override view returns (uint entireSystemDebt) {
        uint activeDebt = activePool.getYUSDDebt();
        uint closedDebt = defaultPool.getYUSDDebt();

        return activeDebt.add(closedDebt);
    }


    function _getICRColls(newColls memory _colls, uint _debt) internal view returns (uint ICR) {
        uint totalVC = _getVCColls(_colls);
        ICR = LiquityMath._computeCR(totalVC, _debt);
        return ICR;
    }


    function _getVC(address[] memory _tokens, uint[] memory _amounts) internal view returns (uint totalVC) {
        require(_tokens.length == _amounts.length, "Not same length");
        for (uint i = 0; i < _tokens.length; i++) {
            uint tokenVC = whitelist.getValueVC(_tokens[i], _amounts[i]);
            totalVC = totalVC.add(tokenVC);
        }
        return totalVC;
    }


    function _getVCColls(newColls memory _colls) internal view returns (uint VC) {
        for (uint i = 0; i < _colls.tokens.length; i++) {
            uint valueVC = whitelist.getValueVC(_colls.tokens[i], _colls.amounts[i]);
            VC = VC.add(valueVC);
        }
        return VC;
    }


    function _getUSDColls(newColls memory _colls) internal view returns (uint USDValue) {
        for (uint i = 0; i < _colls.tokens.length; i++) {
            uint valueUSD = whitelist.getValueUSD(_colls.tokens[i], _colls.amounts[i]);
            USDValue = USDValue.add(valueUSD);
        }
        return USDValue;
    }


    function _getTCR() internal view returns (uint TCR) {
        uint entireSystemColl = getEntireSystemColl();
        uint entireSystemDebt = getEntireSystemDebt();
        
        TCR = LiquityMath._computeCR(entireSystemColl, entireSystemDebt);
        return TCR;
    }


    function _checkRecoveryMode() internal view returns (bool) {
        uint TCR = _getTCR();

        return TCR < CCR;
    }

    // fee and amount are denominated in dollar
    function _requireUserAcceptsFee(uint _fee, uint _amount, uint _maxFeePercentage) internal pure {
        uint feePercentage = _fee.mul(DECIMAL_PRECISION).div(_amount);
        require(feePercentage <= _maxFeePercentage, "Fee exceeded provided maximum");
    }


    // get Colls struct for the given tokens and amounts
    function _getColls(address[] memory tokens, uint[] memory amounts) internal view returns (newColls memory coll) {
        require(tokens.length == amounts.length);
        coll.tokens = tokens;
        for (uint i = 0; i < tokens.length; i++) {
            coll.amounts[whitelist.getIndex(tokens[i])] = amounts[i];
        }
        return coll;
    }


    // checks coll has a nonzero balance of at least one token in coll.tokens
    function _CollsIsNonZero(newColls memory coll) internal pure returns (bool) {
        for (uint i = 0; i < coll.tokens.length; i++) {
            if (coll.amounts[i] > 0) {
                return true;
            }
        }
        return false;
    }


    function _sendColl(address _to, newColls memory _coll) internal returns (bool) {
        for (uint i = 0; i < _coll.tokens.length; i++) {
            IERC20 token = IERC20(_coll.tokens[i]);
            if (!token.transfer(_to, _coll.amounts[i])) {
                return false;
            }
        }
        return true;
    }


    // Check whether or not the system *would be* in Recovery Mode, given the entire system coll and debt.
    // returns true if the system would be in recovery mode and false if not
    function _checkPotentialRecoveryMode(uint _entireSystemColl, uint _entireSystemDebt)
    internal
    pure
    returns (bool)
    {
        uint TCR = LiquityMath._computeCR(_entireSystemColl, _entireSystemDebt);

        return TCR < CCR;
    }



}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

/**
 * Based on OpenZeppelin's Ownable contract:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
 *
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     *
     * NOTE: This function is not safe, as it doesn’t check owner is calling it.
     * Make sure you check it before calling it.
     */
    function _renounceOwnership() internal {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;


contract CheckContract {
    /**
     * Check that the account is an already deployed non-destroyed contract.
     * See: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol#L12
     */
    function checkContract(address _account) internal view {
        require(_account != address(0), "Account cannot be zero address");

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(_account) }
        require(size > 0, "Account code size cannot be zero");
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "./IPriceFeed.sol";


interface ILiquityBase {

    function getEntireSystemDebt() external view returns (uint entireSystemDebt);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "./IPool.sol";

interface IDefaultPool is IPool {
    // --- Events ---
    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event DefaultPoolYUSDDebtUpdated(uint _YUSDDebt);
    event DefaultPoolETHBalanceUpdated(uint _ETH);

    // --- Functions ---
    
    function sendCollsToActivePool(address[] memory _collaterals, uint[] memory _amounts, address _borrower) external;
    function addCollateralType(address _collateral) external;
    function getCollateralVC(address collateralAddress) external view returns (uint);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

interface IPriceFeed {

    // --- Events ---
    event LastGoodPriceUpdated(uint _lastGoodPrice);

    // --- Function ---
    // function fetchPrice() external returns (uint);

    function fetchPrice_v() view external returns (uint);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

interface ICollateralReceiver {
    function receiveCollateral(address[] memory _tokens, uint[] memory _amounts) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

/**
 * Based on the OpenZeppelin IER20 interface:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
 *
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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

/**
 * @dev Interface of the ERC2612 standard as defined in the EIP.
 *
 * Adds the {permit} method, which can be used to change one's
 * {IERC20-allowance} without having to send a transaction, by signing a
 * message. This allows users to spend tokens without having to hold Ether.
 *
 * See https://eips.ethereum.org/EIPS/eip-2612.
 * 
 * Code adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/pull/2237/
 */
interface IERC2612 {
    /**
     * @dev Sets `amount` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
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
    function permit(address owner, address spender, uint256 amount, 
                    uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    
    /**
     * @dev Returns the current ERC2612 nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases `owner`'s nonce by one. This
     * prevents a signature from being used multiple times.
     *
     * `owner` can limit the time a Permit is valid for by setting `deadline` to 
     * a value in the near future. The deadline argument can be set to uint(-1) to 
     * create Permits that effectively never expire.
     */
    function nonces(address owner) external view returns (uint256);
    
    function version() external view returns (string memory);
    function permitTypeHash() external view returns (bytes32);
    function domainSeparator() external view returns (bytes32);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "./ICollateralReceiver.sol";

// Common interface for the Pools.
interface IPool is ICollateralReceiver {
    
    // --- Events ---
    
    event ETHBalanceUpdated(uint _newBalance);
    event YUSDBalanceUpdated(uint _newBalance);
    event ActivePoolAddressChanged(address _newActivePoolAddress);
    event DefaultPoolAddressChanged(address _newDefaultPoolAddress);
    event StabilityPoolAddressChanged(address _newStabilityPoolAddress);
    event WhitelistAddressChanged(address _newWhitelistAddress);
    event EtherSent(address _to, uint _amount);
    event CollateralSent(address _collateral, address _to, uint _amount);

    // --- Functions ---

    function getVC() external view returns (uint);

    function getCollateral(address collateralAddress) external view returns (uint);

    function getAllCollateral() external view returns (address[] memory, uint256[] memory);

    function getYUSDDebt() external view returns (uint);

    function increaseYUSDDebt(uint _amount) external;

    function decreaseYUSDDebt(uint _amount) external;

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "./BaseMath.sol";
import "./SafeMath.sol";
import "../Interfaces/IERC20.sol";
import "../Interfaces/IWhitelist.sol";


contract YetiCustomBase is BaseMath {
    using SafeMath for uint256;

    IWhitelist whitelist;

    struct newColls {
        // tokens and amounts should be the same length
        address[] tokens;
        uint256[] amounts;
    }

    // Collateral math

    // gets the sum of _coll1 and _coll2
    function _sumColls(newColls memory _coll1, newColls memory _coll2)
        internal
        view
        returns (newColls memory finalColls)
    {
        newColls memory coll3;

        coll3.tokens = whitelist.getValidCollateral();
        coll3.amounts = new uint256[](coll3.tokens.length);

        uint256 n = 0;
        for (uint256 i = 0; i < _coll1.tokens.length; i++) {
            uint256 tokenIndex = whitelist.getIndex(_coll1.tokens[i]);
            if (_coll1.amounts[i] > 0) {
                n++;
                coll3.amounts[tokenIndex] = _coll1.amounts[i];
            }
        }

        for (uint256 i = 0; i < _coll2.tokens.length; i++) {
            uint256 tokenIndex = whitelist.getIndex(_coll2.tokens[i]);
            if (_coll2.amounts[i] > 0) {
                if (coll3.amounts[tokenIndex] == 0) {
                    n++;
                }
                coll3.amounts[tokenIndex] = coll3.amounts[tokenIndex].add(_coll2.amounts[i]);
            }
        }

        address[] memory sumTokens = new address[](n);
        uint256[] memory sumAmounts = new uint256[](n);
        uint256 j = 0;

        // should only find n amounts over 0
        for (uint256 i = 0; i < coll3.tokens.length; i++) {
            if (coll3.amounts[i] > 0) {
                sumTokens[j] = coll3.tokens[i];
                sumAmounts[j] = coll3.amounts[i];
                j++;
            }
        }
        finalColls.tokens = sumTokens;
        finalColls.amounts = sumAmounts;
    }


    // gets the sum of coll1 with tokens and amounts
    function _sumColls(
        newColls memory _coll1,
        address[] memory tokens,
        uint256[] memory amounts
    ) internal view returns (newColls memory) {
        newColls memory coll2 = newColls(tokens, amounts);
        return _sumColls(_coll1, coll2);
    }


    function _sumColls(
        address[] memory tokens1,
        uint256[] memory amounts1,
        address[] memory tokens2,
        uint256[] memory amounts2
    ) internal view returns (newColls memory) {
        newColls memory coll1 = newColls(tokens1, amounts1);
        return _sumColls(coll1, tokens2, amounts2);
    }


    // Function for summing colls when coll1 includes all the tokens in the whitelist
    // Used in active, default, stability, and surplus pools
    // assumes _coll1.tokens = all whitelisted tokens
    function _leftSumColls(
        newColls memory _coll1,
        address[] memory _tokens,
        uint256[] memory _amounts
    ) internal view returns (uint[] memory) {
        uint[] memory sumAmounts = _getArrayCopy(_coll1.amounts);

        // assumes that sumAmounts length = whitelist tokens length.
        for (uint256 i = 0; i < _tokens.length; i++) {
            uint tokenIndex = whitelist.getIndex(_tokens[i]);
            sumAmounts[tokenIndex] = sumAmounts[tokenIndex].add(_amounts[i]);
        }

        return sumAmounts;
    }


    // Function for summing colls when one list is all tokens. Used in active, default, stability, and surplus pools
    function _leftSubColls(newColls memory _coll1, address[] memory _subTokens, uint[] memory _subAmounts)
        internal
        view
        returns (uint[] memory)
    {
        uint[] memory diffAmounts = _getArrayCopy(_coll1.amounts);

        //assumes that coll1.tokens = whitelist tokens. Keeps all of coll1's tokens, and subtracts coll2's amounts
        for (uint256 i = 0; i < _subTokens.length; i++) {
            uint256 tokenIndex = whitelist.getIndex(_subTokens[i]);
            diffAmounts[tokenIndex] = diffAmounts[tokenIndex].sub(_subAmounts[i]);
        }
        return diffAmounts;
    }
    

    // Returns _coll1 minus _tokens and _amounts
    // will error if _tokens include a token not in _coll1.tokens
    function _subColls(newColls memory _coll1, address[] memory _tokens, uint[] memory _amounts)
        internal
        view
        returns (newColls memory finalColls)
    {
        require(_tokens.length == _amounts.length, "Sub Colls invalid input");

        newColls memory coll3;
        coll3.tokens = whitelist.getValidCollateral();
        coll3.amounts = new uint256[](coll3.tokens.length);
        uint256 n = 0;

        for (uint256 i = 0; i < _coll1.tokens.length; i++) {
            if (_coll1.amounts[i] > 0) {
                uint256 tokenIndex = whitelist.getIndex(_coll1.tokens[i]);
                coll3.amounts[tokenIndex] = _coll1.amounts[i];
                n++;
            }
        }

        for (uint256 i = 0; i < _tokens.length; i++) {
            uint256 tokenIndex = whitelist.getIndex(_tokens[i]);
            require(coll3.amounts[tokenIndex] >= _amounts[i], "illegal sub");
            coll3.amounts[tokenIndex] = coll3.amounts[tokenIndex].sub(_amounts[i]);
            if (coll3.amounts[tokenIndex] == 0) {
                n--;
            }
        }

        address[] memory diffTokens = new address[](n);
        uint256[] memory diffAmounts = new uint256[](n);
        uint256 j = 0;

        for (uint256 i = 0; i < coll3.tokens.length; i++) {
            if (coll3.amounts[i] > 0) {
                diffTokens[j] = coll3.tokens[i];
                diffAmounts[j] = coll3.amounts[i];
                j++;
            }
        }
        finalColls.tokens = diffTokens;
        finalColls.amounts = diffAmounts;
    }

    function _getArrayCopy(uint[] memory _arr) internal pure returns (uint[] memory){
        uint[] memory copy = new uint[](_arr.length);
        for (uint i = 0; i < _arr.length; i++) {
            copy[i] = _arr[i];
        }
        return copy;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;


contract BaseMath {
    uint constant public DECIMAL_PRECISION = 1e18;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

/**
 * Based on OpenZeppelin's SafeMath:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol
 *
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "./SafeMath.sol";

library LiquityMath {
    using SafeMath for uint;

    uint internal constant DECIMAL_PRECISION = 1e18;

    function _min(uint _a, uint _b) internal pure returns (uint) {
        return (_a < _b) ? _a : _b;
    }

    function _max(uint _a, uint _b) internal pure returns (uint) {
        return (_a >= _b) ? _a : _b;
    }

    /* 
    * Multiply two decimal numbers and use normal rounding rules:
    * -round product up if 19'th mantissa digit >= 5
    * -round product down if 19'th mantissa digit < 5
    *
    * Used only inside the exponentiation, _decPow().
    */
    function decMul(uint x, uint y) internal pure returns (uint decProd) {
        uint prod_xy = x.mul(y);

        decProd = prod_xy.add(DECIMAL_PRECISION / 2).div(DECIMAL_PRECISION);
    }

    /* 
    * _decPow: Exponentiation function for 18-digit decimal base, and integer exponent n.
    * 
    * Uses the efficient "exponentiation by squaring" algorithm. O(log(n)) complexity. 
    * 
    * Called by two functions that represent time in units of minutes:
    * 1) TroveManager._calcDecayedBaseRate
    * 2) CommunityIssuance._getCumulativeIssuanceFraction 
    * 
    * The exponent is capped to avoid reverting due to overflow. The cap 525600000 equals
    * "minutes in 1000 years": 60 * 24 * 365 * 1000
    * 
    * If a period of > 1000 years is ever used as an exponent in either of the above functions, the result will be
    * negligibly different from just passing the cap, since: 
    *
    * In function 1), the decayed base rate will be 0 for 1000 years or > 1000 years
    * In function 2), the difference in tokens issued at 1000 years and any time > 1000 years, will be negligible
    */
    function _decPow(uint _base, uint _minutes) internal pure returns (uint) {
       
        if (_minutes > 525600000) {_minutes = 525600000;}  // cap to avoid overflow
    
        if (_minutes == 0) {return DECIMAL_PRECISION;}

        uint y = DECIMAL_PRECISION;
        uint x = _base;
        uint n = _minutes;

        // Exponentiation-by-squaring
        while (n > 1) {
            if (n % 2 == 0) {
                x = decMul(x, x);
                n = n.div(2);
            } else { // if (n % 2 != 0)
                y = decMul(x, y);
                x = decMul(x, x);
                n = (n.sub(1)).div(2);
            }
        }

        return decMul(x, y);
  }

    function _getAbsoluteDifference(uint _a, uint _b) internal pure returns (uint) {
        return (_a >= _b) ? _a.sub(_b) : _b.sub(_a);
    }

    //  _coll should be the amount of VC and _debt is debt of YUSD\
    // new collateral ratio is 10**18 times the collateral ratio. (150% => 1.5e18)
    function _computeCR(uint _coll, uint _debt) internal pure returns (uint) {
        if (_debt > 0) {
            uint newCollRatio = _coll.mul(10**18).div(_debt);
            return newCollRatio;
        }
        // Return the maximal value for uint256 if the Trove has a debt of 0. Represents "infinite" CR.
        else { // if (_debt == 0)
            return 2**256 - 1; 
        }
    }

}
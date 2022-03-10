// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "../Dependencies/TroveManagerBase.sol";
import "../Dependencies/SafeERC20.sol";

/**
 * @notice TroveManagerRedemptions is derived from TroveManager and handles all redemption activity of troves.
 * Instead of calculating redemption fees in ETH like Liquity used to, we now calculate it as a portion
 * of YUSD passed in to redeem. The YUSDAmount is still how much we would like to redeem, but the
 * YUSDFee is now the maximum amount of YUSD extra that will be paid and must be in the balance of the
 * redeemer for the redemption to succeed. This fee is the same as before in terms of percentage of value,
 * but now it is in terms of YUSD. We now use a helper function to be able to estimate how much YUSD will
 * be actually needed to perform a redemption of a certain amount, and also given an amount of YUSD balance,
 * the max amount of YUSD that can be used for a redemption, and a max fee such that it will always go through.
 *
 * Given a balance of YUSD, Z, the amount that can actually be redeemed is :
 * Y = YUSD you can actually redeem
 * BR = decayed base rate
 * X = YUSD Fee
 * S = Total YUSD Supply
 * The redemption fee rate is = (Y / S * 1 / BETA + BR + 0.5%)
 * This is because the new base rate = BR + Y / S * 1 / BETA
 * We pass in X + Y = Z, and want to find X and Y.
 * Y is calculated to be = S * (sqrt((1.005 + BR)**2 + BETA * Z / S) - 1.005 - BR)
 * through the quadratic formula, and X = Z - Y.
 * Therefore the amount we can actually redeem given Z is Y, and the max fee is X.
 *
 * To find how much the fee is given Y, we can multiply Y by the new base rate, which is BR + Y / S * 1 / BETA.
 *
 * To the redemption function, we pass in Y and X.
 */

contract TroveManagerRedemptions is TroveManagerBase, ITroveManagerRedemptions {
    bytes32 public constant NAME = "TroveManagerRedemptions";

    using SafeERC20 for IYUSDToken;

    address internal borrowerOperationsAddress;

    IStabilityPool internal stabilityPoolContract;

    ITroveManager internal troveManager;

    IYUSDToken internal yusdTokenContract;

    IYETIToken internal yetiTokenContract;

    ITroveManagerRedemptions internal troveManagerRedemptions;

    address internal gasPoolAddress;

    ISortedTroves internal sortedTroves;

    ICollSurplusPool internal collSurplusPool;

    struct RedemptionTotals {
        uint256 remainingYUSD;
        uint256 totalYUSDToRedeem;
        newColls CollsDrawn;
        uint256 YUSDfee;
        uint256 decayedBaseRate;
        uint256 totalYUSDSupplyAtStart;
        uint256 maxYUSDFeeAmount;
    }

    struct SingleRedemptionValues {
        uint256 YUSDLot;
        newColls CollLot;
        uint256 troveDebt;
        bool cancelledPartial;
    }

    struct Hints {
        address upper;
        address lower;
        address target;
        uint256 ricr;
    }

    /*
     * BETA: 18 digit decimal. Parameter by which to divide the redeemed fraction, in order to calc the new base rate from a redemption.
     * Corresponds to (1 / ALPHA) in the white paper.
     */
    uint256 public constant BETA = 2;

    uint256 public constant BOOTSTRAP_PERIOD = 14 seconds;

    // The borrower Fee Split is also parameter important for this contract, but it is mutable by timelock through YetiController.sol
    // thorugh function getRedemptionBorrowerFeeSplit()
    // By default it is 20%

    event Redemption(
        uint256 _attemptedYUSDAmount,
        uint256 _actualYUSDAmount,
        uint256 YUSDfee,
        address[] tokens,
        uint256[] amounts
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
        address _controllerAddress,
        address _troveManagerAddress
    ) external onlyOwner {
        borrowerOperationsAddress = _borrowerOperationsAddress;
        activePool = IActivePool(_activePoolAddress);
        defaultPool = IDefaultPool(_defaultPoolAddress);
        stabilityPoolContract = IStabilityPool(_stabilityPoolAddress);
        controller = IYetiController(_controllerAddress);
        gasPoolAddress = _gasPoolAddress;
        collSurplusPool = ICollSurplusPool(_collSurplusPoolAddress);
        yusdTokenContract = IYUSDToken(_yusdTokenAddress);
        sortedTroves = ISortedTroves(_sortedTrovesAddress);
        yetiTokenContract = IYETIToken(_yetiTokenAddress);
        troveManager = ITroveManager(_troveManagerAddress);

        _renounceOwnership();
    }

    /**
     * @notice Main function for redeeming collateral. See above for how YUSDMaxFee is calculated.
     * @param _YUSDamount is equal to the amount of YUSD to actually redeem.
     * @param _YUSDMaxFee is equal to the max fee in YUSD that the sender is willing to pay
     * @param _firstRedemptionHint is the hint for the first trove to redeem against
     * @param _upperPartialRedemptionHint is the upper hint for reinsertion of last trove
     * @param _lowerPartialRedemptionHint is the lower hint for reinsertion of last trove
     * @param _partialRedemptionHintRICR is the target hint RICR for the last trove redeemed
     * @param _maxIterations is the maximum number of iterations to run the loop
     * @param _redeemer is the redeemer address
     * _YUSDamount + _YUSDMaxFee must be less than the balance of the sender.
     */
    function redeemCollateral(
        uint256 _YUSDamount,
        uint256 _YUSDMaxFee,
        address _firstRedemptionHint,
        address _upperPartialRedemptionHint,
        address _lowerPartialRedemptionHint,
        uint256 _partialRedemptionHintRICR,
        uint256 _maxIterations,
        address _redeemer
    ) external override {
        _requireCallerisTroveManager();
        ContractsCache memory contractsCache = ContractsCache(
            activePool,
            defaultPool,
            yusdTokenContract,
            sortedTroves,
            collSurplusPool,
            gasPoolAddress,
            controller
        );
        RedemptionTotals memory totals;

        _requireValidMaxFee(_YUSDamount, _YUSDMaxFee);
        _requireAfterBootstrapPeriod();
        _requireTCRoverMCR();
        _requireAmountGreaterThanZero(_YUSDamount);

        totals.totalYUSDSupplyAtStart = getEntireSystemDebt();

        // Confirm redeemer's balance is less than total YUSD supply
        require(
            contractsCache.yusdToken.balanceOf(_redeemer) <= totals.totalYUSDSupplyAtStart,
            "TMR: redeemer balance too high"
        );

        totals.remainingYUSD = _YUSDamount;
        address currentBorrower;
        if (_isValidFirstRedemptionHint(contractsCache.sortedTroves, _firstRedemptionHint)) {
            currentBorrower = _firstRedemptionHint;
        } else {
            currentBorrower = contractsCache.sortedTroves.getLast();
            // Find the first trove with ICR >= MCR
            while (
                currentBorrower != address(0) && troveManager.getCurrentRICR(currentBorrower) < MCR
            ) {
                currentBorrower = contractsCache.sortedTroves.getPrev(currentBorrower);
            }
        }
        // Loop through the Troves starting from the one with lowest collateral ratio until _amount of YUSD is exchanged for collateral
        if (_maxIterations == 0) {
            _maxIterations = uint256(-1);
        }
        while (currentBorrower != address(0) && totals.remainingYUSD != 0 && _maxIterations != 0) {
            _maxIterations--;
            // Save the address of the Trove preceding the current one, before potentially modifying the list
            address nextUserToCheck = contractsCache.sortedTroves.getPrev(currentBorrower);

            if (troveManager.getCurrentRICR(currentBorrower) >= MCR) {
                troveManager.applyPendingRewards(currentBorrower);

                SingleRedemptionValues memory singleRedemption = _redeemCollateralFromTrove(
                    contractsCache,
                    currentBorrower,
                    _redeemer,
                    totals.remainingYUSD,
                    _upperPartialRedemptionHint,
                    _lowerPartialRedemptionHint,
                    _partialRedemptionHintRICR
                );

                if (singleRedemption.cancelledPartial) {
                    // Partial redemption was cancelled (out-of-date hint, or new net debt < minimum), therefore we could not redeem from the last Trove
                    // The YUSD Amount actually redeemed is thus less than the intended amount by some amount. totalYUSDToRedeem holds the correct value
                    // Otherwise totalYUSDToRedeem == _YUSDAmount
                    break;
                }

                totals.totalYUSDToRedeem = totals.totalYUSDToRedeem.add(singleRedemption.YUSDLot);

                totals.CollsDrawn = _sumColls(totals.CollsDrawn, singleRedemption.CollLot);
                totals.remainingYUSD = totals.remainingYUSD.sub(singleRedemption.YUSDLot);
            }

            currentBorrower = nextUserToCheck;
        }

        require(isNonzero(totals.CollsDrawn), "TMR:noCollsDrawn");
        // Decay the baseRate due to time passed, and then increase it according to the size of this redemption.
        // Use the saved total YUSD supply value, from before it was reduced by the redemption.
        _updateBaseRateFromRedemption(totals.totalYUSDToRedeem, totals.totalYUSDSupplyAtStart);

        totals.YUSDfee = _getRedemptionFee(totals.totalYUSDToRedeem);
        uint256 borrowerSplitInYUSD = totals
            .totalYUSDToRedeem
            .mul(5e15)
            .div(DECIMAL_PRECISION)
            .mul(contractsCache.controller.getRedemptionBorrowerFeeSplit())
            .div(DECIMAL_PRECISION);
        // check user has enough YUSD to pay fee and redemptions
        // Already paid borrower split fee.
        _requireYUSDBalanceCoversRedemption(
            contractsCache.yusdToken,
            _redeemer,
            totals.totalYUSDToRedeem.add(totals.YUSDfee).sub(borrowerSplitInYUSD)
        );

        // check to see that the fee doesn't exceed the max fee
        _requireUserAcceptsFeeRedemption(totals.YUSDfee, _YUSDMaxFee);

        // send fee from user to YETI stakers and treasury
        _transferAndSplitFee(contractsCache, _redeemer, totals.YUSDfee, borrowerSplitInYUSD);

        emit Redemption(
            _YUSDamount,
            totals.totalYUSDToRedeem,
            totals.YUSDfee,
            totals.CollsDrawn.tokens,
            totals.CollsDrawn.amounts
        );
        // Burn the total YUSD that is cancelled with debt
        contractsCache.yusdToken.burn(_redeemer, totals.totalYUSDToRedeem);
        // Update Active Pool YUSD, and send Collaterals to account
        contractsCache.activePool.decreaseYUSDDebt(totals.totalYUSDToRedeem);

        contractsCache.activePool.sendCollateralsUnwrap(
            address(this), // This contract accumulates rewards for all the wrapped assets short term.
            _redeemer,
            totals.CollsDrawn.tokens,
            totals.CollsDrawn.amounts
        );
    }

    /**
     * @notice Secondary function for redeeming collateral. See above for how YUSDMaxFee is calculated.
     *         Redeems one collateral type from only one trove. Included for gas efficiency of arbitrages.
     * @param _YUSDamount is equal to the amount of YUSD to actually redeem.
     * @param _YUSDMaxFee is equal to the max fee in YUSD that the sender is willing to pay
     * @param _target is the hint for the single trove to redeem against
     * @param _upperHint is the upper hint for reinsertion of the trove
     * @param _lowerHint is the lower hint for reinsertion of the trove
     * @param _hintRICR is the target hint RICR for the the trove redeemed
     * @param _collToRedeem is the collateral address to redeem. Only this token.
     * _YUSDamount + _YUSDMaxFee must be less than the balance of the sender.
     */
    function redeemCollateralSingle(
        uint256 _YUSDamount,
        uint256 _YUSDMaxFee,
        address _target, // _firstRedemptionHint
        address _upperHint, // _upperPartialRedemptionHint
        address _lowerHint, // _lowerPartialRedemptionHint
        uint256 _hintRICR, // _partialRedemptionHintRICR
        address _collToRedeem,
        address _redeemer
    ) external override {
        _requireCallerisTroveManager();
        ContractsCache memory contractsCache = ContractsCache(
            activePool,
            defaultPool,
            yusdTokenContract,
            sortedTroves,
            collSurplusPool,
            gasPoolAddress,
            controller
        );
        RedemptionTotals memory totals;

        _requireValidMaxFee(_YUSDamount, _YUSDMaxFee);
        _requireAfterBootstrapPeriod();
        _requireTCRoverMCR();
        _requireAmountGreaterThanZero(_YUSDamount);
        totals.totalYUSDSupplyAtStart = getEntireSystemDebt();

        // Confirm redeemer's balance is less than total YUSD supply
        require(
            contractsCache.yusdToken.balanceOf(_redeemer) <= totals.totalYUSDSupplyAtStart,
            "TMR:Redeemer YUSD Bal too high"
        );

        totals.remainingYUSD = _YUSDamount;
        require(
            _isValidFirstRedemptionHint(contractsCache.sortedTroves, _target),
            "TMR:Invalid first redemption hint"
        );
        troveManager.applyPendingRewards(_target);

        SingleRedemptionValues memory singleRedemption;
        // Determine the remaining amount (lot) to be redeemed, capped by the entire debt of the Trove minus the liquidation reserve

        uint256[] memory amounts;
        (singleRedemption.CollLot.tokens, amounts, singleRedemption.troveDebt) = troveManager
            .getCurrentTroveState(_target);

        singleRedemption.YUSDLot = YetiMath._min(
            totals.remainingYUSD,
            singleRedemption.troveDebt.sub(YUSD_GAS_COMPENSATION)
        );

        uint256 i; // i term will be used as the index of the collateral to redeem later too
        uint256 tokensLen = singleRedemption.CollLot.tokens.length;
        {
            //Make sure single collateral to redeem exists in trove
            bool foundCollateral;

            for (i = 0; i < tokensLen; ++i) {
                if (singleRedemption.CollLot.tokens[i] == _collToRedeem) {
                    foundCollateral = true;
                    break;
                }
            }
            require(foundCollateral, "TMR:Coll not in trove");
        }

        {
            // Get usd value of only the collateral being redeemed
            uint256 singleCollUSD = contractsCache.controller.getValueUSD(_collToRedeem, amounts[i]);

            // Cap redemption amount to the max amount of collateral that can be redeemed
            singleRedemption.YUSDLot = YetiMath._min(singleCollUSD, singleRedemption.YUSDLot);

            // redemption addresses are the same as coll addresses for trove
            // Calculation for how much collateral to send of each type.
            singleRedemption.CollLot.amounts = new uint256[](tokensLen);

            uint256 tokenAmountToRedeem = singleRedemption.YUSDLot.mul(amounts[i]).div(
                singleCollUSD
            );
            amounts[i] = amounts[i].sub(tokenAmountToRedeem);
            singleRedemption.CollLot.amounts[i] = tokenAmountToRedeem;
        }

        // Send the trove being redeemed against 20% of the minimum fee of 0.5%
        _sendBorrowerFeeSplit(contractsCache, _redeemer, _target, singleRedemption.YUSDLot);

        // Decrease the debt and collateral of the current Trove according to the YUSD lot and corresponding Collateral to send
        singleRedemption.troveDebt = singleRedemption.troveDebt.sub(singleRedemption.YUSDLot);

        if (singleRedemption.troveDebt == YUSD_GAS_COMPENSATION) {
            // No debt left in the Trove (except for the liquidation reserve), therefore the trove gets closed
            troveManager.removeStakeTMR(_target);
            troveManager.closeTroveRedemption(_target);
            _redeemCloseTrove(
                contractsCache,
                _target,
                YUSD_GAS_COMPENSATION,
                singleRedemption.CollLot.tokens,
                amounts
            );

            emit TroveUpdated(
                _target,
                0,
                new address[](0),
                new uint256[](0),
                TroveManagerOperation.redeemCollateral
            );
        } else {
            uint256 newRICR = _getRICRColls(
                newColls(singleRedemption.CollLot.tokens, amounts),
                singleRedemption.troveDebt
            );

            /*
             * If the provided hint is too inaccurate of date, we bail since trying to reinsert without a good hint will almost
             * certainly result in running out of gas. Arbitrary measures of this mean newRICR must be greater than hint RICR - 2%,
             * and smaller than hint ICR + 2%.
             *
             * If the resultant net debt of the partial is less than the minimum, net debt we bail.
             */
            {
                // Stack scope
                if (
                    newRICR >= _hintRICR.add(2e16) ||
                    newRICR <= _hintRICR.sub(2e16) ||
                    _getNetDebt(singleRedemption.troveDebt) < MIN_NET_DEBT
                ) {
                    revert("Invalid partial redemption hint or remaining debt is too low");
                }

                contractsCache.sortedTroves.reInsert(_target, newRICR, _upperHint, _lowerHint);
            }
            troveManager.updateTroveDebt(_target, singleRedemption.troveDebt);
            troveManager.updateTroveCollTMR(_target, singleRedemption.CollLot.tokens, amounts);
            troveManager.updateStakeAndTotalStakes(_target);

            emit TroveUpdated(
                _target,
                singleRedemption.troveDebt,
                singleRedemption.CollLot.tokens,
                amounts,
                TroveManagerOperation.redeemCollateral
            );
        }

        totals.totalYUSDToRedeem = singleRedemption.YUSDLot;

        totals.CollsDrawn = singleRedemption.CollLot;

        require(isNonzero(totals.CollsDrawn), "TMR: non zero collsDrawn");
        // Decay the baseRate due to time passed, and then increase it according to the size of this redemption.
        // Use the saved total YUSD supply value, from before it was reduced by the redemption.
        _updateBaseRateFromRedemption(totals.totalYUSDToRedeem, totals.totalYUSDSupplyAtStart);

        totals.YUSDfee = _getRedemptionFee(totals.totalYUSDToRedeem);

        uint256 borrowerSplitInYUSD = totals
            .totalYUSDToRedeem
            .mul(5e15)
            .div(DECIMAL_PRECISION)
            .mul(contractsCache.controller.getRedemptionBorrowerFeeSplit())
            .div(DECIMAL_PRECISION);

        // check user has enough YUSD to pay fee and redemptions
        // Already paid borrower split fee.
        _requireYUSDBalanceCoversRedemption(
            contractsCache.yusdToken,
            _redeemer,
            totals.remainingYUSD.add(totals.YUSDfee).sub(borrowerSplitInYUSD)
        );

        // check to see that the fee doesn't exceed the max fee
        _requireUserAcceptsFeeRedemption(totals.YUSDfee, _YUSDMaxFee);

        // send fee from user to YETI stakers and treasury
        _transferAndSplitFee(contractsCache, _redeemer, totals.YUSDfee, borrowerSplitInYUSD);

        emit Redemption(
            totals.remainingYUSD,
            totals.totalYUSDToRedeem,
            totals.YUSDfee,
            totals.CollsDrawn.tokens,
            totals.CollsDrawn.amounts
        );
        // Burn the total YUSD that is cancelled with debt
        contractsCache.yusdToken.burn(_redeemer, totals.totalYUSDToRedeem);
        // Update Active Pool YUSD, and send Collaterals to account
        contractsCache.activePool.decreaseYUSDDebt(totals.totalYUSDToRedeem);

        contractsCache.activePool.sendCollateralsUnwrap(
            _target, // rewards from
            _redeemer, // tokens to
            totals.CollsDrawn.tokens,
            totals.CollsDrawn.amounts
        );
    }

    /**
     * @notice Redeem as much collateral as possible from _borrower's Trove in exchange for YUSD up to _maxYUSDamount
     * Special calculation for determining how much collateral to send of each type to send.
     * We want to redeem equivalent to the USD value instead of the VC value here, so we take the YUSD amount
     * which we are redeeming from this trove, and calculate the ratios at which we would redeem a single
     * collateral type compared to all others.
     * For example if we are redeeming 10,000 from this trove, and it has collateral A with a safety ratio of 1,
     * collateral B with safety ratio of 0.5. Let's say their price is each 1. The trove is composed of 10,000 A and
     * 10,000 B, so we would redeem 5,000 A and 5,000 B, instead of 6,666 A and 3,333 B. To do calculate this we take
     * the USD value of that collateral type, and divide it by the total USD value of all collateral types. The price
     * actually cancels out here so we just do YUSD amount * token amount / total USD value, instead of
     * YUSD amount * token value / total USD value / token price, since we are trying to find token amount.
     * @param _borrower The address of the borrower
     * @param _redeemer The address of the redeemer
     * @param _maxYUSDAmount Passed in, try to redeem up to this amount of YUSD
     * @param _upperPartialRedemptionHint is the upper hint for reinsertion of last trove
     * @param _lowerPartialRedemptionHint is the lower hint for reinsertion of last trove
     * @param _partialRedemptionHintRICR is the target hint RICR for the last trove redeemed
     * @return singleRedemption is the data about the redemption that was made, including collsDrawn, debtDrawn, etc.
     */
    function _redeemCollateralFromTrove(
        ContractsCache memory contractsCache,
        address _borrower,
        address _redeemer,
        uint256 _maxYUSDAmount,
        address _upperPartialRedemptionHint,
        address _lowerPartialRedemptionHint,
        uint256 _partialRedemptionHintRICR
    ) internal returns (SingleRedemptionValues memory singleRedemption) {
        uint256[] memory amounts;
        (singleRedemption.CollLot.tokens, amounts, singleRedemption.troveDebt) = troveManager
            .getCurrentTroveState(_borrower);

        uint256 collsLen = singleRedemption.CollLot.tokens.length;
        uint256[] memory finalAmounts = new uint256[](collsLen);

        // Determine the remaining amount (lot) to be redeemed, capped by the entire debt of the Trove minus the liquidation reserve
        singleRedemption.YUSDLot = YetiMath._min(
            _maxYUSDAmount,
            singleRedemption.troveDebt.sub(YUSD_GAS_COMPENSATION)
        );

        // redemption addresses are the same as coll addresses for trove
        // Calculation for how much collateral to send of each type.
        singleRedemption.CollLot.amounts = new uint256[](collsLen);
        {
            uint256 totalCollUSD = _getUSDColls(newColls(singleRedemption.CollLot.tokens, amounts));
            uint256 baseLot = singleRedemption.YUSDLot.mul(DECIMAL_PRECISION);
            for (uint256 i; i < collsLen; ++i) {
                uint256 tokenAmountToRedeem = baseLot.mul(amounts[i]).div(totalCollUSD).div(1e18);

                finalAmounts[i] = amounts[i].sub(tokenAmountToRedeem);
                singleRedemption.CollLot.amounts[i] = tokenAmountToRedeem;
            }
        }

        // Decrease the debt and collateral of the current Trove according to the YUSD lot and corresponding Collateral to send
        uint256 newDebt = singleRedemption.troveDebt.sub(singleRedemption.YUSDLot);

        if (newDebt == YUSD_GAS_COMPENSATION) {
            // No debt left in the Trove (except for the liquidation reserve), therefore the trove gets closed
            troveManager.removeStakeTMR(_borrower);
            troveManager.closeTroveRedemption(_borrower);
            _redeemCloseTrove(
                contractsCache,
                _borrower,
                YUSD_GAS_COMPENSATION,
                singleRedemption.CollLot.tokens,
                finalAmounts
            );

            emit TroveUpdated(
                _borrower,
                0,
                new address[](0),
                new uint256[](0),
                TroveManagerOperation.redeemCollateral
            );
        } else {
            uint256 newRICR = _computeCR(
                _getRVC(singleRedemption.CollLot.tokens, finalAmounts),
                newDebt
            );

            /*
             * If the provided hint is too inaccurate of date, we bail since trying to reinsert without a good hint will almost
             * certainly result in running out of gas. Arbitrary measures of this mean newICR must be greater than hint ICR - 2%,
             * and smaller than hint ICR + 2%.
             *
             * If the resultant net debt of the partial is less than the minimum, net debt we bail.
             */

            if (
                newRICR >= _partialRedemptionHintRICR.add(2e16) ||
                newRICR <= _partialRedemptionHintRICR.sub(2e16) ||
                _getNetDebt(newDebt) < MIN_NET_DEBT
            ) {
                singleRedemption.cancelledPartial = true;
                return singleRedemption;
            }

            contractsCache.sortedTroves.reInsert(
                _borrower,
                newRICR,
                _upperPartialRedemptionHint,
                _lowerPartialRedemptionHint
            );

            troveManager.updateTroveDebt(_borrower, newDebt);
            collsLen = singleRedemption.CollLot.tokens.length;
            for (uint256 i; i < collsLen; ++i) {
                amounts[i] = finalAmounts[i];
            }
            troveManager.updateTroveCollTMR(_borrower, singleRedemption.CollLot.tokens, amounts);
            troveManager.updateStakeAndTotalStakes(_borrower);

            emit TroveUpdated(
                _borrower,
                newDebt,
                singleRedemption.CollLot.tokens,
                finalAmounts,
                TroveManagerOperation.redeemCollateral
            );
        }

        // Send the trove being redeemed against 20% of the minimum fee of 0.5%
        // Send after all other logic to skip the cancelledPartial possibility, where they are eligible for no fee.
        _sendBorrowerFeeSplit(contractsCache, _redeemer, _borrower, singleRedemption.YUSDLot);
    }

    /*
     * @notice Called when a full redemption occurs, and closes the trove.
     * The redeemer swaps (debt - liquidation reserve) YUSD for (debt - liquidation reserve) worth of Collateral, so the YUSD liquidation reserve left corresponds to the remaining debt.
     * In order to close the trove, the YUSD liquidation reserve is burned, and the corresponding debt is removed from the active pool.
     * The debt recorded on the trove's struct is zero'd elswhere, in _closeTrove.
     * Any surplus Collateral left in the trove, is sent to the Coll surplus pool, and can be later claimed by the borrower.
     * @param _YUSD Liquidation reserve to burn
     * @param _colls Collateral to send to coll surplus pool
     * @param _collsAmounts Amounts of collateral to send to coll surplus pool
     */
    function _redeemCloseTrove(
        ContractsCache memory contractsCache,
        address _borrower,
        uint256 _YUSD,
        address[] memory _remainingColls,
        uint256[] memory _remainingCollsAmounts
    ) internal {
        contractsCache.yusdToken.burn(gasPoolAddress, _YUSD);
        // Update Active Pool YUSD, and send Collateral to account
        contractsCache.activePool.decreaseYUSDDebt(_YUSD);

        // send Collaterals from Active Pool to CollSurplus Pool
        contractsCache.collSurplusPool.accountSurplus(
            _borrower,
            _remainingColls,
            _remainingCollsAmounts
        );
        contractsCache.activePool.sendCollaterals(
            address(contractsCache.collSurplusPool),
            _remainingColls,
            _remainingCollsAmounts
        );
    }

    /*
     * @notice This function has two impacts on the baseRate state variable:
     * 1) decays the baseRate based on time passed since last redemption or YUSD borrowing operation.
     * then,
     * 2) increases the baseRate based on the amount redeemed, as a proportion of total supply
     * @param _YUSDDrawn : Amount of YUSD Drawn total from this redemption
     * @param _totalYUSDSupply : Total YUSD supply to decay base rate from.
     */
    function _updateBaseRateFromRedemption(uint256 _YUSDDrawn, uint256 _totalYUSDSupply)
        internal
        returns (uint256)
    {
        uint256 decayedBaseRate = troveManager.calcDecayedBaseRate();

        /* Convert the drawn Collateral back to YUSD at face value rate (1 YUSD:1 USD), in order to get
         * the fraction of total supply that was redeemed at face value. */
        uint256 redeemedYUSDFraction = _YUSDDrawn.mul(1e18).div(_totalYUSDSupply);

        uint256 newBaseRate = decayedBaseRate.add(redeemedYUSDFraction.div(BETA));
        newBaseRate = YetiMath._min(newBaseRate, DECIMAL_PRECISION); // cap baseRate at a maximum of 100%

        troveManager.updateBaseRate(newBaseRate);
        return newBaseRate;
    }

    /**  
     * @notice Checks that the first redemption hint is correct considering the state of sortedTroves
     */
    function _isValidFirstRedemptionHint(ISortedTroves _sortedTroves, address _firstRedemptionHint)
        internal
        view
        returns (bool)
    {
        if (
            _firstRedemptionHint == address(0) ||
            !_sortedTroves.contains(_firstRedemptionHint) ||
            troveManager.getCurrentRICR(_firstRedemptionHint) < MCR
        ) {
            return false;
        }

        address nextTrove = _sortedTroves.getNext(_firstRedemptionHint);
        return nextTrove == address(0) || troveManager.getCurrentICR(nextTrove) < MCR;
    }

    function _requireUserAcceptsFeeRedemption(uint256 _actualFee, uint256 _maxFee) internal pure {
        require(_actualFee <= _maxFee, "TMR:User must accept fee");
    }

    function _requireValidMaxFee(uint256 _YUSDAmount, uint256 _maxYUSDFee) internal pure {
        uint256 _maxFeePercentage = _maxYUSDFee.mul(DECIMAL_PRECISION).div(_YUSDAmount);
        require(_maxFeePercentage >= REDEMPTION_FEE_FLOOR, "TMR:Passed in max fee <0.5%");
        require(_maxFeePercentage <= DECIMAL_PRECISION, "TMR:Passed in max fee >100%");
    }

    function _requireAfterBootstrapPeriod() internal view {
        uint256 systemDeploymentTime = yetiTokenContract.getDeploymentStartTime();
        require(
            block.timestamp >= systemDeploymentTime + BOOTSTRAP_PERIOD,
            "TMR:NoRedemptionsDuringBootstrap"
        );
    }

    function _requireTCRoverMCR() internal view {
        require(_getTCR() >= MCR, "TMR: Cannot redeem when TCR<MCR");
    }

    function _requireAmountGreaterThanZero(uint256 _amount) internal pure {
        require(_amount != 0, "TMR:ReqNonzeroAmount");
    }

    function _requireYUSDBalanceCoversRedemption(
        IYUSDToken _yusdToken,
        address _redeemer,
        uint256 _amount
    ) internal view {
        require(_yusdToken.balanceOf(_redeemer) >= _amount, "TMR:InsufficientYUSDBalance");
    }

    function isNonzero(newColls memory coll) internal pure returns (bool) {
        uint256 collsLen = coll.amounts.length;
        for (uint256 i; i < collsLen; ++i) {
            if (coll.amounts[i] != 0) {
                return true;
            }
        }
        return false;
    }

    function _requireCallerisTroveManager() internal view {
        require(msg.sender == address(troveManager), "TMR:Caller not TM");
    }

    function _getRedemptionFee(uint256 _YUSDRedeemed) internal view returns (uint256) {
        return _calcRedemptionFee(troveManager.getRedemptionRate(), _YUSDRedeemed);
    }

    function _calcRedemptionFee(uint256 _redemptionRate, uint256 _YUSDRedeemed)
        internal
        pure
        returns (uint256)
    {
        uint256 redemptionFee = _redemptionRate.mul(_YUSDRedeemed).div(DECIMAL_PRECISION);
        require(redemptionFee < _YUSDRedeemed, "TM: Fee > YUSD Redeemed");
        return redemptionFee;
    }

    function _calcRedemptionRate(uint256 _baseRate) internal pure returns (uint256) {
        return
            YetiMath._min(
                REDEMPTION_FEE_FLOOR.add(_baseRate),
                DECIMAL_PRECISION // cap at a maximum of 100%
            );
    }

    /**
     * @notice Transfers the fee from the redeemer to the treasury partially, and the rest to the Fee recipient (sYETI) Contract
     * @param _YUSDFee : YUSD Fee which has been calculated from the amount redeemed
     * @param _borrowerSplitInYUSD : The amount in YUSD which has already been transferred to the borrower
     */
    function _transferAndSplitFee(
        ContractsCache memory contractsCache,
        address _redeemer,
        uint256 _YUSDFee,
        uint256 _borrowerSplitInYUSD
    ) internal {
        (uint256 treasuryFeeSplit, address yetiTreasury, address YUSDFeeRecipient) = contractsCache
            .controller
            .getFeeSplitInformation();
        // Get the treasury split in YUSD
        uint256 treasurySplitInYUSD = treasuryFeeSplit.mul(_YUSDFee).div(DECIMAL_PRECISION);
        // If the treasury fee split is more than 1 - borrower split, then the treasury will receive the remainder instead of its supposed split
        treasurySplitInYUSD = YetiMath._min(
            treasurySplitInYUSD,
            _YUSDFee.sub(_borrowerSplitInYUSD)
        );

        // Send a percentage to the treasury
        contractsCache.yusdToken.safeTransferFrom(_redeemer, yetiTreasury, treasurySplitInYUSD);

        // And send the rest to YUSDFeeRecipient
        contractsCache.yusdToken.safeTransferFrom(
            _redeemer,
            YUSDFeeRecipient,
            _YUSDFee.sub(treasurySplitInYUSD).sub(_borrowerSplitInYUSD)
        );
    }

    /**
     * @notice Send a flat rate of the base redeem fee to the borrower who is being redeemed again.
     * The extra is accounted for in the collsurpluspool
     * @param _redeemedAmount : Amount redeemed, send 20% * 0.5% to the borrower.
     */
    function _sendBorrowerFeeSplit(
        ContractsCache memory contractsCache,
        address _redeemer,
        address _borrower,
        uint256 _redeemedAmount
    ) internal {
        uint256 toSendToBorrower = (_redeemedAmount)
            .mul(5e15)
            .div(DECIMAL_PRECISION)
            .mul(contractsCache.controller.getRedemptionBorrowerFeeSplit())
            .div(DECIMAL_PRECISION);
        contractsCache.yusdToken.safeTransferFrom(
            _redeemer,
            address(contractsCache.collSurplusPool),
            toSendToBorrower
        );
        contractsCache.collSurplusPool.accountRedemptionBonus(_borrower, toSendToBorrower);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "../Interfaces/ITroveManager.sol";
import "../Interfaces/IStabilityPool.sol";
import "../Interfaces/ICollSurplusPool.sol";
import "../Interfaces/IYUSDToken.sol";
import "../Interfaces/ISortedTroves.sol";
import "../Interfaces/IYETIToken.sol";
import "../Interfaces/IActivePool.sol";
import "../Interfaces/ITroveManagerLiquidations.sol";
import "../Interfaces/ITroveManagerRedemptions.sol";
import "./LiquityBase.sol";
import "./Ownable.sol";

/** 
 * Contains shared functionality of TroveManagerLiquidations, TroveManagerRedemptions, and TroveManager. 
 * Keeps addresses to cache, events, structs, status, etc. Also keeps Trove struct. 
 */

contract TroveManagerBase is LiquityBase, Ownable {

    // --- Connected contract declarations ---

    // A doubly linked list of Troves, sorted by their sorted by their individual collateral ratios

    struct ContractsCache {
        IActivePool activePool;
        IDefaultPool defaultPool;
        IYUSDToken yusdToken;
        ISortedTroves sortedTroves;
        ICollSurplusPool collSurplusPool;
        address gasPoolAddress;
        IYetiController controller;
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


    event TroveUpdated(address indexed _borrower, uint _debt, address[] _tokens, uint[] _amounts, TroveManagerOperation operation);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity 0.6.11;

import "../Interfaces/IERC20.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length != 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "./ILiquityBase.sol";
import "./IStabilityPool.sol";
import "./IYUSDToken.sol";
import "./IYETIToken.sol";
import "./IActivePool.sol";
import "./IDefaultPool.sol";


// Common interface for the Trove Manager.
interface ITroveManager is ILiquityBase {

    // --- Events ---

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
        address _controllerAddress,
        address _troveManagerRedemptionsAddress,
        address _troveManagerLiquidationsAddress
    )
    external;

    function stabilityPool() external view returns (IStabilityPool);
    function yusdToken() external view returns (IYUSDToken);
    function yetiToken() external view returns (IYETIToken);

    function getTroveOwnersCount() external view returns (uint);

    function getTroveFromTroveOwnersArray(uint _index) external view returns (address);

    function getCurrentICR(address _borrower) external view returns (uint);

    function getCurrentRICR(address _borrower) external view returns (uint);

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

    function redeemCollateralSingle(
        uint256 _YUSDamount,
        uint256 _YUSDMaxFee,
        address _target, 
        address _upperHint, 
        address _lowerHint, 
        uint256 _hintRICR, 
        address _collToRedeem
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

    // function closeTrove(address _borrower) external;

    function removeStakeAndCloseTrove(address _borrower) external;

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

    function removeStakeTML(address _borrower) external;

    function updateBaseRate(uint newBaseRate) external;

    function calcDecayedBaseRate() external view returns (uint);

    function redistributeDebtAndColl(IActivePool _activePool, IDefaultPool _defaultPool, uint _debt, address[] memory _tokens, uint[] memory _amounts) external;

    function updateSystemSnapshots_excludeCollRemainder(IActivePool _activePool, address[] memory _tokens, uint[] memory _amounts) external;

    function getEntireDebtAndColls(address _borrower) external view
    returns (uint, address[] memory, uint[] memory, uint, address[] memory, uint[] memory);

    function movePendingTroveRewardsToActivePool(IActivePool _activePool, IDefaultPool _defaultPool, uint _YUSD, address[] memory _tokens, uint[] memory _amounts, address _borrower) external;

    function collSurplusUpdate(address _account, address[] memory _tokens, uint[] memory _amounts) external;

    function updateTroves(address[] calldata _borrowers, address[] calldata _lowerHints, address[] calldata _upperHints) external;

    function updateLiquidatableTrove(address _id) external;

    function getMCR() external view returns (uint256);

    function getCCR() external view returns (uint256);
    
    function getYUSD_GAS_COMPENSATION() external view returns (uint256);
    
    function getMIN_NET_DEBT() external view returns (uint256);
    
    function getBORROWING_FEE_FLOOR() external view returns (uint256);

    function getREDEMPTION_FEE_FLOOR() external view returns (uint256);
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

    event P_Updated(uint _P);
    event S_Updated(uint _S, uint128 _epoch, uint128 _scale);
    event G_Updated(uint _G, uint128 _epoch, uint128 _scale);
    event EpochUpdated(uint128 _currentEpoch);
    event ScaleUpdated(uint128 _currentScale);


    event DepositSnapshotUpdated(address indexed _depositor, uint _P, uint _S, uint _G);
    event UserDepositChanged(address indexed _depositor, uint _newDeposit);

    event ETHGainWithdrawn(address indexed _depositor, uint _ETH, uint _YUSDLoss);
    event YETIPaidToDepositor(address indexed _depositor, uint _YETI);
    event EtherSent(address _to, uint _amount);

    // --- Functions ---

    /*
     * Called only once on init, to set addresses of other Yeti contracts
     * Callable only by owner, renounces ownership at the end
     */
    function setAddresses(
        address _borrowerOperationsAddress,
        address _troveManagerAddress,
        address _activePoolAddress,
        address _yusdTokenAddress,
        address _sortedTrovesAddress,
        address _communityIssuanceAddress,
        address _controllerAddress,
        address _troveManagerLiquidationsAddress
    )
        external;

    /*
     * Initial checks:
     * - _amount is not zero
     * ---
     * - Triggers a YETI issuance, based on time passed since the last issuance. The YETI issuance is shared between *all* depositors and front ends
     * - Tags the deposit with the provided front end tag param, if it's a new deposit
     * - Sends depositor's accumulated gains (YETI, ETH) to depositor
     * - Sends the tagged front end's accumulated YETI gains to the tagged front end
     * - Increases deposit and tagged front end's stake, and takes new snapshots for each.
     */
    function provideToSP(uint _amount) external;

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

    function claimRewardsSwap(uint256 _yusdMinAmountTotal) external returns (uint256 amountFromSwap);


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
    function getDepositorGains(address _depositor) external view returns (address[] memory assets, uint[] memory amounts);


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
     * Return the user's compounded deposit.
     */
    function getCompoundedYUSDDeposit(address _depositor) external view returns (uint);

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

    event CollBalanceUpdated(address indexed _account);
    event CollateralSent(address _to);

    // --- Contract setters ---

    function setAddresses(
        address _borrowerOperationsAddress,
        address _troveManagerAddress,
        address _troveManagerRedemptionsAddress,
        address _activePoolAddress,
        address _controllerAddress,
        address _yusdTokenAddress
    ) external;

    function getCollVC() external view returns (uint);

    function getTotalRedemptionBonus() external view returns (uint256);

    function getAmountClaimable(address _account, address _collateral) external view returns (uint);

    function hasClaimableCollateral(address _account) external view returns (bool);
    
    function getRedemptionBonus(address _account) external view returns (uint256);

    function getCollateral(address _collateral) external view returns (uint);

    function getAllCollateral() external view returns (address[] memory, uint256[] memory);

    function accountSurplus(address _account, address[] memory _tokens, uint[] memory _amounts) external;

    function accountRedemptionBonus(address _account, uint256 _amount) external;

    function claimCollateral() external;

    function addCollateralType(address _collateral) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "../Interfaces/IERC20.sol";
import "../Interfaces/IERC2612.sol";

interface IYUSDToken is IERC20, IERC2612 {
    
    // --- Events ---

    event YUSDTokenBalanceUpdated(address _user, uint _amount);

    // --- Functions ---

    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;

    function sendToPool(address _sender,  address poolAddress, uint256 _amount) external;

    function returnFromPool(address poolAddress, address user, uint256 _amount ) external;

    function updateMinting(bool _canMint) external;

    function addValidMinter(address _newMinter) external;

    function removeValidMinter(address _minter) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

// Common interface for the SortedTroves Doubly Linked List.
interface ISortedTroves {

    // --- Functions ---
    
    function setParams(uint256 _size, address _TroveManagerAddress, address _borrowerOperationsAddress, address _troveManagerRedemptionsAddress, address _yetiControllerAddress) external;

    function insert(address _id, uint256 _ICR, address _prevId, address _nextId, uint256 _feeAsPercentOfTotal) external;

    function remove(address _id) external;

    function reInsert(address _id, uint256 _newICR, address _prevId, address _nextId) external;

    function reInsertWithNewBoost(
        address _id,
        uint256 _newRICR,
        address _prevId,
        address _nextId,
        uint256 _feeAsPercentOfAddedVC, 
        uint256 _addedVCIn, 
        uint256 _VCBeforeAdjustment
    ) external ;

    function contains(address _id) external view returns (bool);

    function isFull() external view returns (bool);

    function isEmpty() external view returns (bool);

    function getSize() external view returns (uint256);

    function getMaxSize() external view returns (uint256);

    function getNode(address _id) external view returns (bool, address, address, uint256, uint256, uint256);

    function getFirst() external view returns (address);

    function getLast() external view returns (address);

    function getNext(address _id) external view returns (address);

    function getPrev(address _id) external view returns (address);

    function getOldBoostedRICR(address _id) external view returns (uint256);

    function getTimeSinceBoostUpdated(address _id) external view returns (uint256);

    function getBoost(address _id) external view returns (uint256);

    function getDecayedBoost(address _id) external view returns (uint256);

    function getLiquidatableTrovesSize() external view returns (uint256);

    function validInsertPosition(uint256 _ICR, address _prevId, address _nextId) external view returns (bool);

    function findInsertPosition(uint256 _ICR, address _prevId, address _nextId) external view returns (address, address);

    function changeBoostMinuteDecayFactor(uint256 _newBoostMinuteDecayFactor) external;

    function changeGlobalBoostMultiplier(uint256 _newGlobalBoostMultiplier) external;

    function updateLiquidatableTrove(address _id, bool _isLiquidatable) external;

    function reInsertMany(address[] memory _ids, uint256[] memory _newRICRs, address[] memory _prevIds, address[] memory _nextIds) external;
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

import "./IPool.sol";

    
interface IActivePool is IPool {
    // --- Events ---
    event ActivePoolYUSDDebtUpdated(uint _YUSDDebt);
    event ActivePoolCollateralBalanceUpdated(address _collateral, uint _amount);

    // --- Functions ---
    
    function sendCollaterals(address _to, address[] memory _tokens, uint[] memory _amounts) external;
    function sendCollateralsUnwrap(
        address _from,
        address _to,
        address[] memory _tokens,
        uint[] memory _amounts) external;

    function sendSingleCollateral(address _to, address _token, uint256 _amount) external;

    function sendSingleCollateralUnwrap(address _from, address _to, address _token, uint256 _amount) external;

    function getCollateralVC(address collateralAddress) external view returns (uint);
    function addCollateralType(address _collateral) external;

    function getVCSystem() external view returns (uint256 totalVCSystem);

    function getVCforTCRSystem() external view returns (uint256 totalVC, uint256 totalVCforTCR);

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
        address _redeemSender
    )
    external;

    function redeemCollateralSingle(
        uint256 _YUSDamount,
        uint256 _YUSDMaxFee,
        address _target, 
        address _upperHint, 
        address _lowerHint, 
        uint256 _hintRICR, 
        address _collToRedeem, 
        address _redeemer
    ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "./YetiMath.sol";
import "../Interfaces/IActivePool.sol";
import "../Interfaces/IDefaultPool.sol";
import "../Interfaces/ILiquityBase.sol";
import "./YetiCustomBase.sol";

/** 
 * Base contract for TroveManager, TroveManagerLiquidations, TroveManagerRedemptions,
 * and BorrowerOperations.
 * Contains global system constants and common functions.
 */
contract LiquityBase is ILiquityBase, YetiCustomBase {

    // Minimum collateral ratio for individual troves
    uint constant internal MCR = 11e17; // 110%

    // Critical system collateral ratio. If the system's total collateral ratio (TCR) falls below the CCR, Recovery Mode is triggered.
    uint constant internal CCR = 15e17; // 150%

    // Amount of YUSD to be locked in gas pool on opening troves
    // This YUSD goes to the liquidator in the event the trove is liquidated.
    uint constant internal YUSD_GAS_COMPENSATION = 200e18;

    // Minimum amount of net YUSD debt a must have
    uint constant internal MIN_NET_DEBT = 1800e18;

    // Minimum fee on issuing new debt, paid in YUSD
    uint constant internal BORROWING_FEE_FLOOR = DECIMAL_PRECISION / 1000 * 5; // 0.5%

    // Minimum fee paid on redemption, paid in YUSD
    uint constant internal REDEMPTION_FEE_FLOOR = DECIMAL_PRECISION / 1000 * 5; // 0.5%

    IActivePool internal activePool;

    IDefaultPool internal defaultPool;

    // --- Gas compensation functions ---

    /**
     * @notice Returns the total debt of a trove (net debt + gas compensation)
     * @dev The net debt is how much YUSD the user can actually withdraw from the system.
     * The composite debt is the trove's total debt and is used for ICR calculations
     * @return Trove withdrawable debt (net debt) plus YUSD_GAS_COMPENSATION
    */
    function _getCompositeDebt(uint _debt) internal pure returns (uint) {
        return _debt.add(YUSD_GAS_COMPENSATION);
    }

    /**
     * @notice Returns the net debt, which is total (composite) debt of a trove minus gas compensation
     * @dev The net debt is how much YUSD the user can actually withdraw from the system.
     * @return Trove total debt minus the gas compensation
    */
    function _getNetDebt(uint _debt) internal pure returns (uint) {
        return _debt.sub(YUSD_GAS_COMPENSATION);
    }

    /**
     * @notice Return the system's Total Virtual Coin Balance
     * @dev Virtual Coins are a way to keep track of the system collateralization given
     * the collateral ratios of each collateral type
     * @return System's Total Virtual Coin Balance
     */
    function getEntireSystemColl() public view returns (uint) {
        return activePool.getVCSystem();
    }

    /**
     * @notice Calculate and return the System's Total Debt
     * @dev Includes debt held by active troves (activePool.getYUSDDebt())
     * as well as debt from liquidated troves that has yet to be redistributed
     * (defaultPool.getYUSDDebt())
     * @return Return the System's Total Debt
     */
    function getEntireSystemDebt() public override view returns (uint) {
        uint activeDebt = activePool.getYUSDDebt();
        uint closedDebt = defaultPool.getYUSDDebt();
        return activeDebt.add(closedDebt);
    }

    /**
     * @notice Calculate ICR given collaterals and debt
     * @dev ICR = VC(colls) / debt
     * @return ICR Return ICR of the given _colls and _debt
     */
    function _getICRColls(newColls memory _colls, uint _debt) internal view returns (uint ICR) {
        uint totalVC = _getVCColls(_colls);
        ICR = _computeCR(totalVC, _debt);
    }

    /**
     * @notice Calculate and RICR of the colls
     * @dev RICR = RVC(colls) / debt. Calculation is the same as
     * ICR except the collateral weights are different
     * @return RICR Return RICR of the given _colls and _debt
     */
    function _getRICRColls(newColls memory _colls, uint _debt) internal view returns (uint RICR) {
        uint totalVC = _getRVCColls(_colls);
        RICR = _computeCR(totalVC, _debt);
    }

    function _getVC(address[] memory _tokens, uint[] memory _amounts) internal view returns (uint totalVC) {
        totalVC = controller.getValuesVC(_tokens, _amounts);
    }

    function _getRVC(address[] memory _tokens, uint[] memory _amounts) internal view returns (uint totalRVC) {
        totalRVC = controller.getValuesRVC(_tokens, _amounts);
    }

    function _getVCColls(newColls memory _colls) internal view returns (uint totalVC) {
        totalVC = controller.getValuesVC(_colls.tokens, _colls.amounts);
    }

    function _getRVCColls(newColls memory _colls) internal view returns (uint totalRVC) {
        totalRVC = controller.getValuesRVC(_colls.tokens, _colls.amounts);
    }

    function _getUSDColls(newColls memory _colls) internal view returns (uint totalUSDValue) {
        totalUSDValue = controller.getValuesUSD(_colls.tokens, _colls.amounts);
    }

    function _getTCR() internal view returns (uint TCR) {
        (,uint256 entireSystemCollForTCR) = activePool.getVCforTCRSystem();
        uint256 entireSystemDebt = getEntireSystemDebt(); 
        TCR = _computeCR(entireSystemCollForTCR, entireSystemDebt);
    }

    /**
     * @notice Returns recovery mode bool as well as entire system coll
     * @dev Do these together to avoid looping.
     * @return recMode Recovery mode bool
     * @return entireSystemColl System's Total Virtual Coin Balance
     * @return entireSystemDebt System's total debt
     */
    function _checkRecoveryModeAndSystem() internal view returns (bool recMode, uint256 entireSystemColl, uint256 entireSystemDebt) {
        uint256 entireSystemCollForTCR;
        (entireSystemColl, entireSystemCollForTCR) = activePool.getVCforTCRSystem();
        entireSystemDebt = getEntireSystemDebt();
        // Check TCR < CCR
        recMode = _computeCR(entireSystemCollForTCR, entireSystemDebt) < CCR;
    }

    function _checkRecoveryMode() internal view returns (bool) {
        return _getTCR() < CCR;
    }

    // fee and amount are denominated in dollar
    function _requireUserAcceptsFee(uint _fee, uint _amount, uint _maxFeePercentage) internal pure {
        uint feePercentage = _fee.mul(DECIMAL_PRECISION).div(_amount);
        require(feePercentage <= _maxFeePercentage, "Fee > max");
    }

    // checks coll has a nonzero balance of at least one token in coll.tokens
    function _collsIsNonZero(newColls memory _colls) internal pure returns (bool) {
        uint256 tokensLen = _colls.tokens.length;
        for (uint256 i; i < tokensLen; ++i) {
            if (_colls.amounts[i] != 0) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice Calculates a new collateral ratio if debt is not 0 or the max uint256 value if it is 0
     * @dev Return the maximal value for uint256 if the Trove has a debt of 0. Represents "infinite" CR.
     * @param _coll Collateral
     * @param _debt Debt of Trove
     * @return The new collateral ratio if debt is greater than 0, max value of uint256 if debt is 0
     */
    function _computeCR(uint _coll, uint _debt) internal pure returns (uint) {
        if (_debt != 0) {
            uint newCollRatio = _coll.mul(1e18).div(_debt);
            return newCollRatio;
        }
        else { 
            return 2**256 - 1; 
        }
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
        require(isOwner(), "CallerNotOwner");
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

import "./IPriceFeed.sol";


interface ILiquityBase {

    function getEntireSystemDebt() external view returns (uint entireSystemDebt);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "./IPool.sol";

interface IDefaultPool is IPool {
    // --- Events ---
    event DefaultPoolYUSDDebtUpdated(uint _YUSDDebt);
    event DefaultPoolETHBalanceUpdated(uint _ETH);

    // --- Functions ---
    
    function sendCollsToActivePool(address[] memory _collaterals, uint[] memory _amounts, address _borrower) external;
    function addCollateralType(address _collateral) external;
    function getCollateralVC(address collateralAddress) external view returns (uint);

    function getAllAmounts() external view returns (uint256[] memory);
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
    event EtherSent(address _to, uint _amount);
    event CollateralSent(address _collateral, address _to, uint _amount);

    // --- Functions ---

    function getVC() external view returns (uint totalVC);

    function getVCforTCR() external view returns (uint totalVC, uint totalVCforTCR);

    function getCollateral(address collateralAddress) external view returns (uint);

    function getAllCollateral() external view returns (address[] memory, uint256[] memory);

    function getYUSDDebt() external view returns (uint);

    function increaseYUSDDebt(uint _amount) external;

    function decreaseYUSDDebt(uint _amount) external;

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "./SafeMath.sol";
import "../Interfaces/IERC20.sol";
import "../Interfaces/IYetiController.sol";

/**
 * Contains shared functionality for many of the system files
 * YetiCustomBase is inherited by PoolBase2 and LiquityBase
 */

contract YetiCustomBase {
    using SafeMath for uint256;

    IYetiController internal controller;

    struct newColls {
        // tokens and amounts should be the same length
        address[] tokens;
        uint256[] amounts;
    }

    uint constant public DECIMAL_PRECISION = 1e18;

    // Collateral math

    // gets the sum of _coll1 and _coll2
    function _sumColls(newColls memory _coll1, newColls memory _coll2)
        internal
        view
        returns (newColls memory finalColls)
    {
        uint256 coll2Len = _coll2.tokens.length;
        uint256 coll1Len = _coll1.tokens.length;
        if (coll2Len == 0) {
            return _coll1;
        } else if (coll1Len == 0) {
            return _coll2;
        }
        newColls memory coll3;
        coll3.tokens = new address[](coll1Len + coll2Len);
        coll3.amounts = new uint256[](coll1Len + coll2Len);

        uint256 i = 0;
        uint256 j = 0;
        uint256 k = 0;

        uint256[] memory tokenIndices1 = controller.getIndices(_coll1.tokens);
        uint256[] memory tokenIndices2 = controller.getIndices(_coll2.tokens);

        uint256 tokenIndex1 = tokenIndices1[i];
        uint256 tokenIndex2 = tokenIndices2[j];

        while (true) {
            if (tokenIndex1 < tokenIndex2) {
                coll3.tokens[k] = _coll1.tokens[i];
                coll3.amounts[k] = _coll1.amounts[i];
                ++i;
                if (i == coll1Len){
                    break;
                }
                tokenIndex1 = tokenIndices1[i];
            } else if (tokenIndex2 < tokenIndex1){
                coll3.tokens[k] = _coll2.tokens[j];
                coll3.amounts[k] = _coll2.amounts[j];
                ++j;
                 if (j == coll2Len){
                    break;
                }
                tokenIndex2 = tokenIndices2[j];
            } else {
                coll3.tokens[k] = _coll1.tokens[i];
                coll3.amounts[k] = _coll1.amounts[i].add(_coll2.amounts[j]);
                ++i;
                ++j;
                 if (i == coll1Len || j == coll2Len){
                    break;
                }
                tokenIndex1 = tokenIndices1[i];
                tokenIndex2 = tokenIndices2[j];
            }
            ++k;
        }
        ++k;
        while (i < coll1Len) {
            coll3.tokens[k] = _coll1.tokens[i];
            coll3.amounts[k] = _coll1.amounts[i];
            ++i;
            ++k;
        }
        while (j < coll2Len){
            coll3.tokens[k] = _coll2.tokens[j];
            coll3.amounts[k] = _coll2.amounts[j];
            ++j;
            ++k;
        }

        address[] memory sumTokens = new address[](k);
        uint256[] memory sumAmounts = new uint256[](k);
        for (i = 0; i < k; ++i) {
            sumTokens[i] = coll3.tokens[i];
            sumAmounts[i] = coll3.amounts[i];
        }

        finalColls.tokens = sumTokens;
        finalColls.amounts = sumAmounts;
    }

    function _revertWrongFuncCaller() internal pure {
        revert("WFC");
    }
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
        require(c >= a, "add overflow");

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
        return sub(a, b, "sub overflow");
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
        require(c / a == b, "mul overflow");

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
        return div(a, b, "div by 0");
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
        require(b != 0, errorMessage);
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
        return mod(a, b, "mod by 0");
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


interface IYetiController {

    // ======== Mutable Only Owner-Instantaneous ========
    function setAddresses(
        address _activePoolAddress,
        address _defaultPoolAddress,
        address _stabilityPoolAddress,
        address _collSurplusPoolAddress,
        address _borrowerOperationsAddress,
        address _yusdTokenAddress,
        address _sortedTrovesAddress,
        address _sYETITokenAddress,
        address _yetiFinanceTreasury,
        address _oneWeekTimelock,
        address _twoWeekTimelock
    ) external; // setAddresses is special as it is only called can be called once
    function deprecateAllCollateral() external;
    function deprecateCollateral(address _collateral) external;
    function setLeverUp(bool _enabled) external;
    function setFeeBootstrapPeriodEnabled(bool _enabled) external;
    function updateGlobalYUSDMinting(bool _canMint) external;
    function removeValidYUSDMinter(address _minter) external;


    // ======== Mutable Only Owner-1 Week TimeLock ========
    function addCollateral(
        address _collateral,
        uint256 _safetyRatio,
        uint256 _recoveryRatio,
        address _oracle,
        uint256 _decimals,
        address _feeCurve,
        bool _isWrapped,
        address _routerAddress
    ) external;
    function unDeprecateCollateral(address _collateral) external;
    function updateMaxCollsInTrove(uint _newMax) external;
    function changeOracle(address _collateral, address _oracle) external;
    function changeFeeCurve(address _collateral, address _feeCurve) external;
    function changeRatios(address _collateral, uint256 _newSafetyRatio, uint256 _newRecoveryRatio) external;
    function setDefaultRouter(address _collateral, address _router) external;
    function changeYetiFinanceTreasury(address _newTreasury) external;
    function changeYetiFinanceTreasurySplit(uint256 _newSplit) external;
    function changeRedemptionBorrowerFeeSplit(uint256 _newSplit) external;

    // ======== Mutable Only Owner-2 Week TimeLock ========
    function addValidYUSDMinter(address _minter) external;
    function changeBoostMinuteDecayFactor(uint256 _newBoostMinuteDecayFactor) external;
    function changeGlobalBoostMultiplier(uint256 _newBoostMinuteDecayFactor) external;
    function changeYUSDFeeRecipient(address _newFeeRecipient) external;


    // ======= VIEW FUNCTIONS FOR COLLATERAL PARAMS =======
    function getValidCollateral() view external returns (address[] memory);
    function getOracle(address _collateral) view external returns (address);
    function getSafetyRatio(address _collateral) view external returns (uint256);
    function getRecoveryRatio(address _collateral) view external returns (uint256);
    function getIsActive(address _collateral) view external returns (bool);
    function getFeeCurve(address _collateral) external view returns (address);
    function getDecimals(address _collateral) external view returns (uint256);
    function getIndex(address _collateral) external view returns (uint256);
    function getIndices(address[] memory _colls) external view returns (uint256[] memory indices);
    function checkCollateralListSingle(address[] memory _colls, bool _deposit) external view;
    function checkCollateralListDouble(address[] memory _depositColls, address[] memory _withdrawColls) external view;
    function isWrapped(address _collateral) external view returns (bool);
    function getDefaultRouterAddress(address _collateral) external view returns (address);

    // ======= MUTABLE FUNCTION FOR FEES =======
    function getTotalVariableDepositFeeAndUpdate(
        address[] memory _tokensIn,
        uint256[] memory _amountsIn,
        uint256[] memory _leverages,
        uint256 _entireSystemColl,
        uint256 _VCin,
        uint256 _VCout
    ) external returns (uint256 YUSDFee, uint256 boostFactor);

    function getVariableDepositFee(address _collateral, uint _collateralVCInput, uint256 _collateralVCBalancePost, uint256 _totalVCBalancePre, uint256 _totalVCBalancePost) external view returns (uint256 fee);

    // ======= VIEW FUNCTIONS FOR VC / USD VALUE =======
    function getValuesVC(address[] memory _collaterals, uint[] memory _amounts) view external returns (uint);
    function getValuesRVC(address[] memory _collaterals, uint[] memory _amounts) view external returns (uint);
    function getValuesVCforTCR(address[] memory _collaterals, uint[] memory _amounts) view external returns (uint VC, uint256 VCforTCR);
    function getValuesUSD(address[] memory _collaterals, uint[] memory _amounts) view external returns (uint256);
    function getValueVC(address _collateral, uint _amount) view external returns (uint);
    function getValueRVC(address _collateral, uint _amount) view external returns (uint);
    function getValueVCforTCR(address _collateral, uint _amount) view external returns (uint VC, uint256 VCforTCR);
    function getValueUSD(address _collateral, uint _amount) view external returns (uint256);


    // ======= VIEW FUNCTIONS FOR CONTRACT FUNCTIONALITY =======
    function getYetiFinanceTreasury() external view returns (address);
    function getYetiFinanceTreasurySplit() external view returns (uint256);
    function getRedemptionBorrowerFeeSplit() external view returns (uint256);
    function getYUSDFeeRecipient() external view returns (address);
    function leverUpEnabled() external view returns (bool);
    function getMaxCollsInTrove() external view returns (uint);
    function getFeeSplitInformation() external view returns (uint256, address, address);

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "./SafeMath.sol";

library YetiMath {
    using SafeMath for uint;

    uint internal constant DECIMAL_PRECISION = 1e18;
    uint internal constant HALF_DECIMAL_PRECISION = 5e17;

    function _min(uint _a, uint _b) internal pure returns (uint) {
        return (_a < _b) ? _a : _b;
    }

    function _max(uint _a, uint _b) internal pure returns (uint) {
        return (_a >= _b) ? _a : _b;
    }

    /**
     * @notice Multiply two decimal numbers 
     * @dev Use normal rounding rules: 
        -round product up if 19'th mantissa digit >= 5
        -round product down if 19'th mantissa digit < 5
     */
    function decMul(uint x, uint y) internal pure returns (uint decProd) {
        uint prod_xy = x.mul(y);

        decProd = prod_xy.add(HALF_DECIMAL_PRECISION).div(DECIMAL_PRECISION);
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
       
        if (_minutes > 5256e5) {_minutes = 5256e5;}  // cap to avoid overflow
    
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

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.11;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
     /**
     * @notice Checks if 'account' is a contract
     * @dev It is unsafe to assume that an address for which this function returns
        false is an externally-owned account (EOA) and not a contract.
        Among others, `isContract` will return false for the following
        types of addresses:
        - an externally-owned account
        - a contract in construction
        - an address where a contract will be created
        - an address where a contract lived, but was destroyed
     * @param account The address of an account
     * @return true if account is a contract, false if account is not a contract
    */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size != 0;
    }

     /**
     * @notice sends `amount` wei to `recipient`, forwarding all available gas and reverting on errors.
     * @dev Replacement for Solidity's `transfer`
        https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
        of certain opcodes, possibly making contracts go over the 2300 gas limit
        imposed by `transfer`, making them unable to receive funds via
        `transfer`. {sendValue} removes this limitation.
        
        https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
        
        IMPORTANT: because control is transferred to `recipient`, care must be
        taken to not create reentrancy vulnerabilities. Consider using
        {ReentrancyGuard} or the
        https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     * @param recipient The address of where the wei 'amount' is sent to 
     * @param amount the 'amount' of wei to be transfered to 'recipient'
      */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

     /**
     * @notice Performs a Solidity function call using a low level `call`.
     * @dev A plain`call` is an unsafe replacement for a function call: use this function instead.
        If `target` reverts with a revert reason, it is bubbled up by this
        function (like regular Solidity function calls).
        
        Returns the raw returned data. To convert to the expected return value,
        use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
        
        Requirements:
        
        - `target` must be a contract.
        - calling `target` with `data` must not revert.
        
        _Available since v3.1._
     * @param target The address of a contract
     * @param data In bytes 
     * @return Solidity's functionCall 
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length != 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
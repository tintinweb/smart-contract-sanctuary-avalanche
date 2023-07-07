// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {ITATransactionAllocation} from "./interfaces/ITATransactionAllocation.sol";
import {TATransactionAllocationGetters} from "./TATransactionAllocationGetters.sol";
import {TAHelpers} from "ta-common/TAHelpers.sol";
import {U256ArrayHelper} from "src/library/arrays/U256ArrayHelper.sol";
import {RAArrayHelper} from "src/library/arrays/RAArrayHelper.sol";
import {
    FixedPointTypeHelper,
    FixedPointType,
    Uint256WrapperHelper,
    FP_ZERO,
    FP_ONE
} from "src/library/FixedPointArithmetic.sol";
import {VersionManager} from "src/library/VersionManager.sol";
import {RelayerAddress, TokenAddress, RelayerAccountAddress, RelayerStatus} from "ta-common/TATypes.sol";
import {RelayerStateManager} from "ta-common/RelayerStateManager.sol";
import {PERCENTAGE_MULTIPLIER} from "ta-common/TAConstants.sol";

/// @title TATransactionAllocation
/// @dev This contract is responsible for allocating transactions to relayers and their execution.
///      A window is defined as a contigous set of blocks. The window size is defined by blocksPerWindow.
///      An epoch is defined as a period of time in which liveness is measured. The epoch length is defined by epochLengthInSec.
///
///      1. Transaction Allocation and Execution:
///      Each window, relayersPerWindow relayers are selected in a pseudo-random manner to submit transactions.
///      The execute function verifies that the calling relayer is selected in the current window, then executes the transactions.
///      Each transaction delegates to a transaction specific module, which verifies if that particular transaction was assigned to the relayer.
///
///      2. State Updation:
///      In the fist transaction of each epoch, the liveness of each relayer is verified.
///      Any relayers that fail the liveness check are penalized, and if their stake falls below a threshold, they are jailed.
///      Once the liveness check is complete, the pending state is scheduled for activation in the next window.
contract TATransactionAllocation is ITATransactionAllocation, TAHelpers, TATransactionAllocationGetters {
    using FixedPointTypeHelper for FixedPointType;
    using Uint256WrapperHelper for uint256;
    using VersionManager for VersionManager.VersionManagerState;
    using U256ArrayHelper for uint256[];
    using RAArrayHelper for RelayerAddress[];

    ///////////////////////////////// Transaction Execution ///////////////////////////////

    /// @inheritdoc ITATransactionAllocation
    function execute(ExecuteParams calldata _params) external payable noSelfCall {
        uint256 length = _params.reqs.length;
        if (length != _params.forwardedNativeAmounts.length) {
            revert ParameterLengthMismatch();
        }

        _verifySufficientValueAttached(_params.forwardedNativeAmounts);

        // Verify Relayer Selection
        uint256 selectionCount = _verifyRelayerSelection(
            msg.sender,
            _params.activeState,
            _params.relayerIndex,
            _params.relayerGenerationIterationBitmap,
            block.number
        );

        TAStorage storage ts = getTAStorage();
        RelayerAddress relayerAddress = _params.activeState.relayers[_params.relayerIndex];

        // Ensure the relayer can call execute() once per window
        {
            uint256 windowId = _windowIndex(block.number);
            if (ts.lastTransactionSubmissionWindow[relayerAddress] == windowId) {
                revert RelayerAlreadySubmittedTransaction(relayerAddress, windowId);
            }
            ts.lastTransactionSubmissionWindow[relayerAddress] = windowId;
        }

        // Execute Transactions
        _executeTransactions(
            _params.reqs,
            _params.forwardedNativeAmounts,
            getRMStorage().relayersPerWindow,
            relayerAddress,
            _params.relayerGenerationIterationBitmap
        );

        uint256 epochEndTimestamp_ = ts.epochEndTimestamp;

        // If the transaction is the first transaction of the epoch, then perform the liveness check and other operations
        if (block.timestamp >= epochEndTimestamp_) {
            epochEndTimestamp_ = _performFirstTransactionOfEpochDuties(_params.activeState, _params.latestState);
        }

        // Record Liveness Metrics
        if (_params.reqs.length != 0) {
            unchecked {
                ts.transactionsSubmitted[epochEndTimestamp_][relayerAddress] += selectionCount;
                ts.totalTransactionsSubmitted[epochEndTimestamp_] += selectionCount;
            }
        }

        // TODO: Check how to update this logic
        // Validate that the relayer has sent enough gas for the call.
        // if (gasleft() <= totalGas / 63) {
        //     assembly {
        //         invalid()
        //     }
        // }
    }

    /// @dev Runs the liveness check, activates any pending state and emits the latest relayer state.
    /// @param _activeState The active relayer state.
    /// @param _latestState The latest relayer state.
    function _performFirstTransactionOfEpochDuties(
        RelayerStateManager.RelayerState calldata _activeState,
        RelayerStateManager.RelayerState calldata _latestState
    ) internal returns (uint256) {
        _verifyExternalStateForRelayerStateUpdation(_latestState);

        // Run liveness checks for last epoch
        _processLivenessCheck(_activeState, _latestState);

        // Process any pending Updates
        uint256 updateWindowIndex = _nextWindowForUpdate(block.number);
        VersionManager.VersionManagerState storage vms = getRMStorage().relayerStateVersionManager;
        vms.setLatestStateForActivation(updateWindowIndex);

        // Update the epoch end time
        TAStorage storage ts = getTAStorage();
        uint256 newEpochEndTimestamp = block.timestamp + ts.epochLengthInSec;
        ts.epochEndTimestamp = newEpochEndTimestamp;
        emit EpochEndTimestampUpdated(newEpochEndTimestamp);

        return newEpochEndTimestamp;
    }

    /// @dev Verifies that the relayer has been selected for the current window.
    /// @param _relayer The relayer address.
    /// @param _activeState The active realyer state, against which the relayer selection is verified.
    /// @param _relayerIndex The index of the relayer in the active state.
    /// @param _relayerGenerationIterationBitmap The bitmap of relayer generation iterations for which the relayer has been selected.
    /// @param _blockNumber The block number at which the verification logic needs to be run.
    function _verifyRelayerSelection(
        address _relayer,
        RelayerStateManager.RelayerState calldata _activeState,
        uint256 _relayerIndex,
        uint256 _relayerGenerationIterationBitmap,
        uint256 _blockNumber
    ) internal view returns (uint256 selectionCount) {
        _verifyExternalStateForTransactionAllocation(_activeState, _blockNumber);

        RMStorage storage ds = getRMStorage();

        {
            // If the ith bit of _relayerGenerationIterationBitmap is set, then the relayer has been selected as the ith relayer
            // where 0 <= i < relayersPerWindow.
            // This also means that the relayer is allowed to submit all transactions which satisfy the following condition:
            //   hash(txn) % relayersPerWindow == i

            // Verify Each Iteration against _cdfIndex in _cdf
            uint256 maxCdfElement = _activeState.cdf[_activeState.cdf.length - 1];
            uint256 relayerGenerationIteration;
            uint256 relayersPerWindow = ds.relayersPerWindow;

            while (_relayerGenerationIterationBitmap != 0) {
                if (_relayerGenerationIterationBitmap & 1 == 1) {
                    if (relayerGenerationIteration >= relayersPerWindow) {
                        revert InvalidRelayerGenerationIteration();
                    }

                    // Verify if correct cdf index has been provided
                    uint256 r = _randomNumberForCdfSelection(_blockNumber, relayerGenerationIteration, maxCdfElement);

                    if (
                        !(
                            (_relayerIndex == 0 || _activeState.cdf[_relayerIndex - 1] < r)
                                && r <= _activeState.cdf[_relayerIndex]
                        )
                    ) {
                        // The supplied index does not point to the correct interval
                        revert RelayerIndexDoesNotPointToSelectedCdfInterval();
                    }

                    selectionCount++;
                }

                unchecked {
                    ++relayerGenerationIteration;
                    _relayerGenerationIterationBitmap >>= 1;
                }
            }
        }

        RelayerAddress relayerAddress = _activeState.relayers[_relayerIndex];
        RelayerInfo storage node = ds.relayerInfo[relayerAddress];

        if (relayerAddress != RelayerAddress.wrap(_relayer) && !node.isAccount[RelayerAccountAddress.wrap(_relayer)]) {
            revert RelayerAddressDoesNotMatchSelectedRelayer();
        }
    }

    /// @dev Generates a pseudo random number used for selecting a relayer.
    /// @param _blockNumber The block number at which the random number needs to be generated.
    /// @param _iter The ith iteration corresponds to the ith relayer being generated
    /// @param _max The modulo value for the random number generation.
    function _randomNumberForCdfSelection(uint256 _blockNumber, uint256 _iter, uint256 _max)
        internal
        view
        returns (uint256)
    {
        // The seed for jth iteration is a function of the base seed and j
        uint256 baseSeed = uint256(keccak256(abi.encodePacked(_windowIndex(_blockNumber))));
        uint256 seed = uint256(keccak256(abi.encodePacked(baseSeed, _iter)));
        return seed % _max + 1;
    }

    /// @dev Executes the transactions, appending necessary data to the calldata for each.
    /// @param _reqs The array of transactions to execute.
    /// @param _forwardedNativeAmounts The array of forwarded native amounts for each transaction.
    /// @param _relayerCount The number of relayers that have been selected for the current window.
    /// @param _relayerAddress The address of the relayer that has been selected for the current window.
    /// @param _relayerGenerationIterationBitmap The bitmap of relayer generation iterations for which the relayer has been selected.
    function _executeTransactions(
        bytes[] calldata _reqs,
        uint256[] calldata _forwardedNativeAmounts,
        uint256 _relayerCount,
        RelayerAddress _relayerAddress,
        uint256 _relayerGenerationIterationBitmap
    ) internal {
        uint256 length = _reqs.length;

        for (uint256 i; i != length;) {
            (bool success, bytes memory returndata) = _executeTransaction(
                _reqs[i], _forwardedNativeAmounts[i], _relayerGenerationIterationBitmap, _relayerCount, _relayerAddress
            );

            emit TransactionStatus(i, success, returndata);

            if (!success) {
                revert TransactionExecutionFailed(i, returndata);
            }

            unchecked {
                ++i;
            }
        }
    }

    /// @dev Executes a single transaction, appending necessary data to the calldata .
    /// @param _req The transactions to execute.
    /// @param _value The native amount to forward to the transaction.
    /// @param _relayerGenerationIterationBitmap The bitmap of relayer generation iterations for which the relayer has been selected.
    /// @param _relayerCount The number of relayers that have been selected for the current window.
    /// @param _relayerAddress The address of the relayer that has been selected for the current window.
    /// @return status The status of the transaction.
    /// @return returndata The return data of the transaction.
    function _executeTransaction(
        bytes calldata _req,
        uint256 _value,
        uint256 _relayerGenerationIterationBitmap,
        uint256 _relayerCount,
        RelayerAddress _relayerAddress
    ) internal returns (bool status, bytes memory returndata) {
        (status, returndata) = address(this).call{value: _value}(
            abi.encodePacked(
                _req, _relayerGenerationIterationBitmap, _relayerCount, RelayerAddress.unwrap(_relayerAddress)
            )
        );
    }

    /// @dev Verifies that sum(_forwardedNativeAmounts) == msg.value
    /// @param _forwardedNativeAmounts The array of forwarded native amounts for each transaction.
    function _verifySufficientValueAttached(uint256[] calldata _forwardedNativeAmounts) internal view {
        uint256 totalExpectedValue;
        uint256 length = _forwardedNativeAmounts.length;
        for (uint256 i; i != length;) {
            totalExpectedValue += _forwardedNativeAmounts[i];
            unchecked {
                ++i;
            }
        }
        if (msg.value != totalExpectedValue) {
            revert InvalidFeeAttached(totalExpectedValue, msg.value);
        }
    }

    /////////////////////////////// Allocation Helpers ///////////////////////////////

    /// @inheritdoc ITATransactionAllocation
    function allocateRelayers(RelayerStateManager.RelayerState calldata _activeState)
        external
        view
        override
        returns (RelayerAddress[] memory selectedRelayers, uint256[] memory cdfIndex)
    {
        _verifyExternalStateForTransactionAllocation(_activeState, block.number);

        if (_activeState.cdf.length == 0) {
            revert NoRelayersRegistered();
        }

        if (_activeState.cdf[_activeState.cdf.length - 1] == 0) {
            revert NoRelayersRegistered();
        }

        {
            RMStorage storage ds = getRMStorage();
            selectedRelayers = new RelayerAddress[](ds.relayersPerWindow);
            cdfIndex = new uint256[](ds.relayersPerWindow);
        }

        uint256 relayersPerWindow = getRMStorage().relayersPerWindow;
        uint256 relayerCount = _activeState.relayers.length;

        for (uint256 i = 0; i != relayersPerWindow;) {
            uint256 randomCdfNumber = _randomNumberForCdfSelection(block.number, i, _activeState.cdf[relayerCount - 1]);
            cdfIndex[i] = _activeState.cdf.cd_lowerBound(randomCdfNumber);
            selectedRelayers[i] = _activeState.relayers[cdfIndex[i]];
            unchecked {
                ++i;
            }
        }
        return (selectedRelayers, cdfIndex);
    }

    ///////////////////////////////// Liveness ///////////////////////////////
    struct ProcessLivenessCheckMemoryState {
        // Cache to prevent multiple SLOADs
        uint256 epochEndTimestamp;
        uint256 updatedUnpaidProtocolRewards;
        uint256 stakeThresholdForJailing;
        uint256 totalTransactionsInEpoch;
        FixedPointType zScoreSquared;
        FixedPointType updatedSharePrice;
        // Intermediate state, written to storage at the end of the function
        uint256 activeRelayersJailedCount;
        uint256 totalPenalty;
        uint256 totalActiveRelayerPenalty;
        uint256 totalActiveRelayerJailedStake;
        FixedPointType totalProtocolRewardSharesBurnt;
        uint256 totalProtocolRewardsPaid;
        RelayerAddress[] newRelayerList;
        uint256[] newWeightsList; // The changes to weights (stake+delegation) are accumulated in this array
    }

    /// @dev Processes the liveness check for the current epoch for all active relayers.
    /// @param _activeRelayerState The active relayer state.
    /// @param _pendingRelayerState The pending relayer state.
    function _processLivenessCheck(
        RelayerStateManager.RelayerState calldata _activeRelayerState,
        RelayerStateManager.RelayerState calldata _pendingRelayerState
    ) internal {
        ProcessLivenessCheckMemoryState memory state;

        TAStorage storage ta = getTAStorage();
        state.epochEndTimestamp = ta.epochEndTimestamp;
        state.totalTransactionsInEpoch = ta.totalTransactionsSubmitted[state.epochEndTimestamp];
        state.zScoreSquared = ta.livenessZParameter;
        state.zScoreSquared = state.zScoreSquared * state.zScoreSquared;
        state.stakeThresholdForJailing = ta.stakeThresholdForJailing;
        delete ta.totalTransactionsSubmitted[state.epochEndTimestamp];

        // If no transactions were submitted in the epoch, then no need to process liveness check
        if (state.totalTransactionsInEpoch == 0) {
            emit NoTransactionsSubmittedInEpoch();
            return;
        }

        uint256 activeRelayerCount = _activeRelayerState.relayers.length;
        for (uint256 i; i != activeRelayerCount;) {
            _processLivenessCheckForRelayer(_activeRelayerState, _pendingRelayerState, i, state);

            unchecked {
                ++i;
            }
        }

        _postLivenessCheck(state);

        emit LivenessCheckProcessed(state.epochEndTimestamp);
    }

    /// @dev Processes the liveness check for the current epoch for a single relayer.
    /// @param _activeRelayerState The active relayer state.
    /// @param _pendingRelayerState Teh pending relayer state.
    /// @param _relayerIndex The index of the relayer to process.
    /// @param _state In memory struct to store intermediate state.
    function _processLivenessCheckForRelayer(
        RelayerStateManager.RelayerState calldata _activeRelayerState,
        RelayerStateManager.RelayerState calldata _pendingRelayerState,
        uint256 _relayerIndex,
        ProcessLivenessCheckMemoryState memory _state
    ) internal {
        if (
            _verifyRelayerLiveness(
                _activeRelayerState,
                _relayerIndex,
                _state.epochEndTimestamp,
                _state.totalTransactionsInEpoch,
                _state.zScoreSquared
            )
        ) {
            return;
        }

        RelayerAddress relayerAddress = _activeRelayerState.relayers[_relayerIndex];
        RelayerInfo storage relayerInfo = getRMStorage().relayerInfo[relayerAddress];
        uint256 stake = relayerInfo.stake;
        uint256 penalty = _calculatePenalty(stake);

        // Initialize protocol reward state cache if not already done
        if (_state.updatedSharePrice == FP_ZERO) {
            _state.updatedUnpaidProtocolRewards = _getLatestTotalUnpaidProtocolRewardsAndUpdateUpdatedTimestamp();
            _state.updatedSharePrice = _protocolRewardRelayerSharePrice(_state.updatedUnpaidProtocolRewards);
        }

        // Initialize the relayer lists if they are not initialized
        if (_state.newWeightsList.length == 0) {
            _state.newWeightsList = RelayerStateManager.cdfToWeights(_pendingRelayerState.cdf);
            _state.newRelayerList = _pendingRelayerState.relayers;
        }

        if (stake - penalty >= _state.stakeThresholdForJailing) {
            _penalizeRelayer(relayerAddress, relayerInfo, stake, penalty, _state);
        } else {
            _penalizeAndJailRelayer(relayerAddress, relayerInfo, stake, penalty, _state);
        }
    }

    /// @dev Assuming that the relayer failed the liveness check AND does not qualify for jailing, only penalize it's stake
    /// @param _relayerAddress The address of the relayer to penalize.
    /// @param _relayerInfo The relayer info of the relayer to penalize.
    /// @param _stake The current stake of the relayer.
    /// @param _penalty The penalty to be deducted from the relayer's stake.
    /// @param _state In memory struct to store intermediate state.
    function _penalizeRelayer(
        RelayerAddress _relayerAddress,
        RelayerInfo storage _relayerInfo,
        uint256 _stake,
        uint256 _penalty,
        ProcessLivenessCheckMemoryState memory _state
    ) internal {
        RelayerStatus statusBeforeLivenessCheck = _relayerInfo.status;

        // Penalize the relayer
        uint256 updatedStake = _stake - _penalty;
        _relayerInfo.stake = updatedStake;

        // The amount to be transferred to the recipients of the penalty (msg.sender, foundation, dao, governance...)
        _state.totalPenalty += _penalty;

        // If the relayer was an active relayer, decrease it's protocol reward shares accordingly
        if (statusBeforeLivenessCheck == RelayerStatus.Active) {
            // The penalty to be deducted from global totalStake in _postLivenessCheck
            _state.totalActiveRelayerPenalty += _penalty;

            // No need to process pending rewards since the relayer is still in the system, and pending rewards
            // don't change when shares equivalent to penalty are burnt
            FixedPointType protocolRewardSharesBurnt = _penalty.fp() / _state.updatedSharePrice;
            _relayerInfo.rewardShares = _relayerInfo.rewardShares - protocolRewardSharesBurnt;

            _state.totalProtocolRewardSharesBurnt = _state.totalProtocolRewardSharesBurnt + protocolRewardSharesBurnt;

            _decreaseRelayerWeightInState(_state, _relayerAddress, _penalty);

            emit RelayerProtocolSharesBurnt(_relayerAddress, protocolRewardSharesBurnt);
        }

        emit RelayerPenalized(_relayerAddress, updatedStake, _penalty);
    }

    /// @dev Assuming that the relayer failed the liveness check AND qualifies for jailing, penalize it's stake and jail it.
    ///      Process any pending rewards and then destroy all of the relayer's protocol reward shares, to prevent it from earning
    ///      any more rewards.
    /// @param _relayerAddress The address of the relayer to jail.
    /// @param _relayerInfo The relayer info of the relayer to jail.
    /// @param _stake The current stake of the relayer.
    /// @param _penalty The penalty to be deducted from the relayer's stake.
    /// @param _state In memory struct to store intermediate state.
    function _penalizeAndJailRelayer(
        RelayerAddress _relayerAddress,
        RelayerInfo storage _relayerInfo,
        uint256 _stake,
        uint256 _penalty,
        ProcessLivenessCheckMemoryState memory _state
    ) internal {
        RMStorage storage rms = getRMStorage();
        RelayerStatus statusBeforeLivenessCheck = _relayerInfo.status;

        // If the relayer was an active relayer, process any pending protocol rewards, then destory all of it's shares
        if (statusBeforeLivenessCheck == RelayerStatus.Active) {
            // Calculate Rewards
            (uint256 relayerRewards, uint256 delegatorRewards,) =
                _getPendingProtocolRewardsData(_relayerAddress, _state.updatedUnpaidProtocolRewards);
            _relayerInfo.unpaidProtocolRewards += relayerRewards;

            // Process Delegator Rewards
            _addDelegatorRewards(_relayerAddress, TokenAddress.wrap(address(rms.bondToken)), delegatorRewards);

            FixedPointType protocolRewardSharesBurnt = _relayerInfo.rewardShares;
            _relayerInfo.rewardShares = FP_ZERO;

            _state.totalProtocolRewardSharesBurnt = _state.totalProtocolRewardSharesBurnt + protocolRewardSharesBurnt;
            _state.totalProtocolRewardsPaid += relayerRewards + delegatorRewards;

            emit RelayerProtocolSharesBurnt(_relayerAddress, protocolRewardSharesBurnt);
        }

        // Penalize the relayer
        uint256 updatedStake = _stake - _penalty;
        _relayerInfo.stake = updatedStake;

        // Jail the relayer
        uint256 jailedUntilTimestamp = block.timestamp + rms.jailTimeInSec;
        _relayerInfo.status = RelayerStatus.Jailed;
        _relayerInfo.minExitTimestamp = jailedUntilTimestamp;

        // The amount to be transferred to the recipients of the penalty (msg.sender, foundation, dao, governance...)
        _state.totalPenalty += _penalty;

        // Update accumulators for _postLivenessCheck
        if (statusBeforeLivenessCheck == RelayerStatus.Active) {
            // The penalty to be deducted from global totalStake in _postLivenessCheck
            _state.totalActiveRelayerPenalty += _penalty;

            // The jailed stake to be deducted from global totalStake
            _state.totalActiveRelayerJailedStake += updatedStake;

            _removeRelayerFromState(_state, _relayerAddress);
            unchecked {
                ++_state.activeRelayersJailedCount;
            }
        }

        emit RelayerPenalized(_relayerAddress, updatedStake, _penalty);
        emit RelayerJailed(_relayerAddress, jailedUntilTimestamp);
    }

    /// @dev Writes the update state to storage after liveness check has been performed.
    /// @param _state The in memory struct to store intermediate state.
    function _postLivenessCheck(ProcessLivenessCheckMemoryState memory _state) internal {
        RMStorage storage rms = getRMStorage();

        // Update Global Counters
        if (_state.totalActiveRelayerPenalty + _state.totalActiveRelayerJailedStake != 0) {
            rms.totalStake -= _state.totalActiveRelayerPenalty + _state.totalActiveRelayerJailedStake;
        }
        if (_state.activeRelayersJailedCount != 0) {
            rms.relayerCount -= _state.activeRelayersJailedCount;
        }
        if (_state.totalProtocolRewardSharesBurnt != FP_ZERO) {
            rms.totalProtocolRewardShares = rms.totalProtocolRewardShares - _state.totalProtocolRewardSharesBurnt;
        }

        uint256 newUnpaidRewards = _state.updatedUnpaidProtocolRewards - _state.totalProtocolRewardsPaid;
        if (newUnpaidRewards > 0 && newUnpaidRewards != rms.totalUnpaidProtocolRewards) {
            rms.totalUnpaidProtocolRewards = newUnpaidRewards;
        }

        // Schedule RelayerState Update if Necessary
        if (_state.totalActiveRelayerPenalty != 0 || _state.activeRelayersJailedCount != 0) {
            uint256[] memory newCdf = RelayerStateManager.weightsToCdf(_state.newWeightsList);
            _m_updateLatestRelayerState(_state.newRelayerList, newCdf);
        }

        // Transfer the penalty to the caller
        if (_state.totalPenalty != 0) {
            _transfer(TokenAddress.wrap(address(rms.bondToken)), msg.sender, _state.totalPenalty);
        }
    }

    /// @dev Utillity function to remove a relayer from the memory state.
    function _removeRelayerFromState(ProcessLivenessCheckMemoryState memory _state, RelayerAddress _relayerAddress)
        internal
        pure
    {
        uint256 relayerIndexInMemoryState = _findRelayerIndexInMemoryState(_state, _relayerAddress);
        _state.newRelayerList.m_remove(relayerIndexInMemoryState);
        _state.newWeightsList.m_remove(relayerIndexInMemoryState);
    }

    /// @dev Utillity function to decrease a relayer's weight from the memory state.
    function _decreaseRelayerWeightInState(
        ProcessLivenessCheckMemoryState memory _state,
        RelayerAddress _relayerAddress,
        uint256 _valueToDecrease
    ) internal pure {
        uint256 relayerIndexInMemoryState = _findRelayerIndexInMemoryState(_state, _relayerAddress);
        _state.newWeightsList[relayerIndexInMemoryState] -= _valueToDecrease;
    }

    /// @dev Utillity function to find a relayer's index in the memory state, in O(relayerCount).
    ///      This will be called rarely (once per epoch, AND once per relayer that is penalized or jailed)
    /// @param _state The in memory struct to store intermediate state.
    /// @param _relayerAddress The address of the relayer to find.
    function _findRelayerIndexInMemoryState(
        ProcessLivenessCheckMemoryState memory _state,
        RelayerAddress _relayerAddress
    ) internal pure returns (uint256) {
        uint256 length = _state.newRelayerList.length;
        for (uint256 i; i != length;) {
            if (_state.newRelayerList[i] == _relayerAddress) {
                return i;
            }
            unchecked {
                ++i;
            }
        }

        // It should not be possible to reach here
        revert RelayerAddressNotFoundInMemoryState(_relayerAddress);
    }

    /// @inheritdoc ITATransactionAllocation
    function calculateMinimumTranasctionsForLiveness(
        uint256 _relayerStake,
        uint256 _totalStake,
        uint256 _totalTransactions,
        FixedPointType _zScore
    ) external pure override returns (FixedPointType) {
        // Let t = _transactionsDoneByRelayer
        //     T = _totalTransactions
        //
        //                  _relayerStake
        // Probability: p = ─────────────
        //                   _totalStake
        //
        // Expected Number of Transactions: e = pT
        //
        //                          ┌─────────┐   ┌──────┐
        // Standard Deviation: s = ╲│p(1 - p)T = ╲│(1-p)e
        //                                                 ┌─────┐
        // Minimum Number of Transactions = e - zs = e - z╲│(1-p)e

        if (_totalTransactions == 0) {
            return FP_ZERO;
        }

        if (_totalStake == 0) {
            revert NoRelayersRegistered();
        }

        FixedPointType p = _relayerStake.fp().div(_totalStake);
        FixedPointType s = ((p * (FP_ONE - p)) * _totalTransactions.fp()).sqrt();
        FixedPointType d = _zScore * s;
        FixedPointType e = p * _totalTransactions.fp();
        unchecked {
            if (e > d) {
                return e - d;
            }
        }

        return FP_ZERO;
    }

    /// @dev Returns true if the relayer passes the liveness check for the current epoch, else false.
    /// @param _activeState The active relayer state.
    /// @param _relayerIndex The index of the relayer in the active relayer list.
    /// @param _epochEndTimestamp The end timestamp of the current epoch.
    /// @param _totalTransactionsInEpoch  The total number of transactions in the current epoch.
    /// @param _zScoreSquared A precomputed zScore parameter squared value.
    /// @return True if the relayer passes the liveness check for the current epoch, else false.
    function _verifyRelayerLiveness(
        RelayerStateManager.RelayerState calldata _activeState,
        uint256 _relayerIndex,
        uint256 _epochEndTimestamp,
        uint256 _totalTransactionsInEpoch,
        FixedPointType _zScoreSquared
    ) internal returns (bool) {
        TAStorage storage ts = getTAStorage();

        RelayerAddress relayerAddress = _activeState.relayers[_relayerIndex];
        uint256 transactionsProcessedByRelayer = ts.transactionsSubmitted[_epochEndTimestamp][relayerAddress];
        delete ts.transactionsSubmitted[_epochEndTimestamp][relayerAddress];

        uint256 relayerWeight = _activeState.cdf[_relayerIndex];

        if (_relayerIndex != 0) {
            relayerWeight -= _activeState.cdf[_relayerIndex - 1];
        }

        return _checkRelayerLiveness(
            relayerWeight,
            _activeState.cdf[_activeState.cdf.length - 1],
            transactionsProcessedByRelayer,
            _totalTransactionsInEpoch,
            _zScoreSquared
        );
    }

    /// @dev An optimized version of verifying whether _transactionsDoneByRelayer >= calculatedMinimumTranasctionsForLiveness()
    /// @param _relayerStake The stake of the relayer.
    /// @param _totalStake The total stake of all relayers.
    /// @param _transactionsDoneByRelayer The number of transactions done by the relayer.
    /// @param _totalTransactions The total number of transactions done by all relayers.
    /// @param _zScoreSquared The zScore parameter squared value.
    /// @return True if the relayer passes the liveness check for the current epoch, else false.
    function _checkRelayerLiveness(
        uint256 _relayerStake,
        uint256 _totalStake,
        uint256 _transactionsDoneByRelayer,
        uint256 _totalTransactions,
        FixedPointType _zScoreSquared
    ) internal pure returns (bool) {
        // Calculating square roots is expensive, so we modify the inequality to avoid it.
        //
        // Let t = _transactionsDoneByRelayer
        //     T = _totalTransactions
        //
        //                  _relayerStake
        // Probability: p = ─────────────
        //                   _totalStake
        //
        // The original condition is:
        //
        // Expected Number of Transactions: e = pT
        //
        //                          ┌─────────┐   ┌──────┐
        // Standard Deviation: s = ╲│p(1 - p)T = ╲│(1-p)e
        //                                                 ┌─────┐
        // Minimum Number of Transactions = e - zs = e - z╲│(1-p)e
        //
        // Therefore,
        //              ┌──────┐
        // => t ≥ e - z╲│(1-p)e
        //
        //      ┌──────┐
        // => z╲│e(1-p)  ≥ e - t
        //
        // => e ≤ t ∨ z²e(1-p) ≥ (e-t)²

        // We skip the check if e ≤ t
        FixedPointType p = _relayerStake.fp().div(_totalStake);
        FixedPointType e = p.mul(_totalTransactions);
        FixedPointType _transactionsDoneByRelayerFp = _transactionsDoneByRelayer.fp();
        if (e <= _transactionsDoneByRelayerFp) {
            return true;
        }

        // Proceed with the check if e > t
        FixedPointType lhs = _zScoreSquared * e * (FP_ONE - p);
        FixedPointType rhs = e - _transactionsDoneByRelayerFp;
        rhs = rhs * rhs;

        return lhs >= rhs;
    }

    /// @dev Helper function to calculate the penalty for a relayer.
    /// @param _stake The stake of the relayer.
    /// @return The penalty for the relayer.
    function _calculatePenalty(uint256 _stake) internal view returns (uint256) {
        return (_stake * getRMStorage().absencePenaltyPercentage) / (100 * PERCENTAGE_MULTIPLIER);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {ITATransactionAllocationEventsErrors} from "./ITATransactionAllocationEventsErrors.sol";
import {FixedPointType} from "src/library/FixedPointArithmetic.sol";
import {ITATransactionAllocationGetters} from "./ITATransactionAllocationGetters.sol";
import {RelayerAddress} from "ta-common/TATypes.sol";
import {RelayerStateManager} from "ta-common/RelayerStateManager.sol";

/// @title ITATransactionAllocation
interface ITATransactionAllocation is ITATransactionAllocationEventsErrors, ITATransactionAllocationGetters {
    /// @dev Data structure to hold the parameters for the execute function.
    /// @custom:member reqs The array of calldata containing the transactions to be executed.
    /// @custom:member forwardedNativeAmounts The array of native amounts to be forwarded to the call with the corresponding transaction.
    /// @custom:member relayerIndex The index of the relayer in the active state calling the execute function.
    /// @custom:member relayerGenerationIterationBitmap A bitmap with set bit indicating the relayer was selected at that iteration.
    /// @custom:member activeState The active state of the relayers.
    /// @custom:member latestState The latest state of the relayers.
    struct ExecuteParams {
        bytes[] reqs;
        uint256[] forwardedNativeAmounts;
        uint256 relayerIndex;
        uint256 relayerGenerationIterationBitmap;
        RelayerStateManager.RelayerState activeState;
        RelayerStateManager.RelayerState latestState;
    }

    /// @notice This function is called by the relayer to execute the transactions.
    /// @param _data The data structure containing the parameters for the execute function.
    function execute(ExecuteParams calldata _data) external payable;

    /// @notice Returns the list of relayers selected in the current window. Expected to be called off-chain.
    /// @param _activeState The active state of the relayers.
    /// @return selectedRelayers list of relayers selected of length relayersPerWindow, but
    ///                          there can be duplicates
    /// @return indices list of indices of the selected relayers in the active state, used for verification
    function allocateRelayers(RelayerStateManager.RelayerState calldata _activeState)
        external
        view
        returns (RelayerAddress[] memory, uint256[] memory);

    /// @notice Convenience function to calculate the miniumum number of transactions required to pass the liveness check.
    /// @param _relayerStake The stake of the relayer calling the execute function.
    /// @param _totalStake The total stake of all the relayers.
    /// @param _totalTransactions The total number of transactions submitted in the current epoch.
    /// @param _zScore A parameter used to calculate the minimum number of transactions required to pass the liveness check.
    function calculateMinimumTranasctionsForLiveness(
        uint256 _relayerStake,
        uint256 _totalStake,
        uint256 _totalTransactions,
        FixedPointType _zScore
    ) external view returns (FixedPointType);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {TATransactionAllocationStorage} from "./TATransactionAllocationStorage.sol";
import {ITATransactionAllocationGetters} from "./interfaces/ITATransactionAllocationGetters.sol";
import {Guards} from "src/utils/Guards.sol";
import {RelayerAddress} from "ta-common/TATypes.sol";
import {FixedPointType} from "src/library/FixedPointArithmetic.sol";

/// @title TATransactionAllocationGetters
abstract contract TATransactionAllocationGetters is
    ITATransactionAllocationGetters,
    TATransactionAllocationStorage,
    Guards
{
    function transactionsSubmittedByRelayer(RelayerAddress _relayerAddress)
        external
        view
        override
        noSelfCall
        returns (uint256)
    {
        return getTAStorage().transactionsSubmitted[getTAStorage().epochEndTimestamp][_relayerAddress];
    }

    function totalTransactionsSubmitted() external view override noSelfCall returns (uint256) {
        return getTAStorage().totalTransactionsSubmitted[getTAStorage().epochEndTimestamp];
    }

    function epochLengthInSec() external view override noSelfCall returns (uint256) {
        return getTAStorage().epochLengthInSec;
    }

    function epochEndTimestamp() external view override noSelfCall returns (uint256) {
        return getTAStorage().epochEndTimestamp;
    }

    function livenessZParameter() external view override noSelfCall returns (FixedPointType) {
        return getTAStorage().livenessZParameter;
    }

    function stakeThresholdForJailing() external view override noSelfCall returns (uint256) {
        return getTAStorage().stakeThresholdForJailing;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "openzeppelin-contracts/utils/Address.sol";

import {ITAHelpers} from "./interfaces/ITAHelpers.sol";
import {TARelayerManagementStorage} from "ta-relayer-management/TARelayerManagementStorage.sol";
import {TADelegationStorage} from "ta-delegation/TADelegationStorage.sol";
import {
    Uint256WrapperHelper,
    FixedPointTypeHelper,
    FixedPointType,
    FP_ZERO,
    FP_ONE
} from "src/library/FixedPointArithmetic.sol";
import {VersionManager} from "src/library/VersionManager.sol";
import {RelayerAddress, TokenAddress, RelayerStatus} from "./TATypes.sol";
import {BOND_TOKEN_DECIMAL_MULTIPLIER, NATIVE_TOKEN, PERCENTAGE_MULTIPLIER} from "./TAConstants.sol";
import {RelayerStateManager} from "./RelayerStateManager.sol";
import {RAArrayHelper} from "src/library/arrays/RAArrayHelper.sol";
import {U256ArrayHelper} from "src/library/arrays/U256ArrayHelper.sol";

/// @title TAHelpers
/// @dev Common contract inherited by all core modules of the Transaction Allocator. Provides various helper functions.
abstract contract TAHelpers is TARelayerManagementStorage, TADelegationStorage, ITAHelpers {
    using SafeERC20 for IERC20;
    using Address for address payable;
    using Uint256WrapperHelper for uint256;
    using FixedPointTypeHelper for FixedPointType;
    using VersionManager for VersionManager.VersionManagerState;
    using RelayerStateManager for RelayerStateManager.RelayerState;
    using RAArrayHelper for RelayerAddress[];
    using U256ArrayHelper for uint256[];

    ////////////////////////////// Verification Helpers //////////////////////////////
    modifier onlyActiveRelayer(RelayerAddress _relayer) {
        if (!_isActiveRelayer(_relayer)) {
            revert RelayerIsNotActive(_relayer);
        }
        _;
    }

    /// @dev Returns true if the relayer is active in the pending/latest state.
    ///      A relayer which has requested unregistration or jailing could be active in the current state, but not in the pending/latest state.
    /// @param _relayer The relayer address
    /// @return true if the relayer is active
    function _isActiveRelayer(RelayerAddress _relayer) internal view returns (bool) {
        return getRMStorage().relayerInfo[_relayer].status == RelayerStatus.Active;
    }

    /// @dev Verifies that the passed relayer state corresponds to the latest/pending state.
    ///      Updates to the Relayer State must take into account already queued updates, hence the verification against the latest state.
    ///      Reverts if the state verification fails.
    /// @param _state The relayer state to be verified
    function _verifyExternalStateForRelayerStateUpdation(RelayerStateManager.RelayerState calldata _state)
        internal
        view
    {
        if (!getRMStorage().relayerStateVersionManager.verifyHashAgainstLatestState(_state.hash())) {
            revert InvalidLatestRelayerState();
        }
    }

    /// @dev Verifies that the passed relayer state corresponds to the currently active state.
    ///      Reverts if the state verification fails.
    /// @param _state The relayer state to be verified
    /// @param _blockNumber The block number at which the state is to be verified
    function _verifyExternalStateForTransactionAllocation(
        RelayerStateManager.RelayerState calldata _state,
        uint256 _blockNumber
    ) internal view {
        // The unit of time for the relayer state is the window index.
        uint256 windowIndex = _windowIndex(_blockNumber);

        if (!getRMStorage().relayerStateVersionManager.verifyHashAgainstActiveState(_state.hash(), windowIndex)) {
            revert InvalidActiveRelayerState();
        }
    }

    ////////////////////////////// Relayer Selection //////////////////////////////

    /// @dev A non-decreasing numerical identifier for a given window. A window is a contigous set of blocks of length blocksPerWindow.
    /// @param _blockNumber The block number for which the window index is to be calculated
    /// @return The index of window in which _blockNumber falls
    function _windowIndex(uint256 _blockNumber) internal view returns (uint256) {
        return _blockNumber / getRMStorage().blocksPerWindow;
    }

    /// @dev Given a block number, returns the window index a future window in which any relayer state updates should be applied.
    /// @param _blockNumber The block number for which the next update window index is to be calculated
    /// @return The index of the window in which the relayer state updates should be applied
    function _nextWindowForUpdate(uint256 _blockNumber) internal view returns (uint256) {
        return _windowIndex(_blockNumber) + getRMStorage().relayerStateUpdateDelayInWindows;
    }

    ////////////////////////////// Relayer State //////////////////////////////

    /// @dev Sets the latest relayer state, but does not schedule it for activation.
    /// @param _relayers The list of relayers in the new state
    /// @param _cdf The cumulative distribution function of the stake + delegation of relayers in the new state
    function _cd_updateLatestRelayerState(RelayerAddress[] calldata _relayers, uint256[] memory _cdf) internal {
        bytes32 newRelayerStateHash = RelayerStateManager.hash(_cdf, _relayers);
        getRMStorage().relayerStateVersionManager.setLatestState(newRelayerStateHash, _windowIndex(block.number));
        emit NewRelayerState(newRelayerStateHash, _relayers, _cdf);
    }

    /// @dev Sets the latest relayer state, but does not schedule it for activation.
    /// @param _relayers The list of relayers in the new state
    /// @param _cdf The cumulative distribution function of the stake + delegation of relayers in the new state
    function _m_updateLatestRelayerState(RelayerAddress[] memory _relayers, uint256[] memory _cdf) internal {
        bytes32 newRelayerStateHash = RelayerStateManager.hash(_cdf.m_hash(), _relayers.m_hash());
        getRMStorage().relayerStateVersionManager.setLatestState(newRelayerStateHash, _windowIndex(block.number));
        emit NewRelayerState(newRelayerStateHash, _relayers, _cdf);
    }

    ////////////////////////////// Delegation ////////////////////////

    /// @dev Records the rewards to be distributed to delegators of the given relayer
    /// @param _relayer The relayer whose delegators are to be rewarded
    /// @param _token The token in which the rewards are to be distributed
    /// @param _amount The amount of rewards to be distributed
    function _addDelegatorRewards(RelayerAddress _relayer, TokenAddress _token, uint256 _amount) internal {
        if (_amount == 0) {
            return;
        }
        getTADStorage().unclaimedRewards[_relayer][_token] += _amount;
        emit DelegatorRewardsAdded(_relayer, _token, _amount);
    }

    ////////////////////////// Constant Rate Rewards //////////////////////////

    /// @dev The BRN generates "protocol rewards" in the form of bond tokens (BICO) at a rate R.
    ///      The base reward factor (B) is a constant that is set by the BRN.
    ///      An increment (b) is defined as the Minimum amount of stake required by relayers.
    ///      Assuming S is the total stake, the reward rate is given by:
    ///         Base Reward Per Increment/s (I) = B * b / sqrt(S)
    ///         Total Reward Rate/s (R) = I * S / b = B * sqrt(S)
    ///
    /// @return The current reward generation rate R in bond Token (BICO) wei/sec
    function _protocolRewardRate() internal view returns (uint256) {
        RMStorage storage rs = getRMStorage();
        FixedPointType rate =
            rs.totalStake.fp().div(BOND_TOKEN_DECIMAL_MULTIPLIER).sqrt().mul(rs.baseRewardRatePerMinimumStakePerSec);
        return rate.u256();
    }

    /// @dev Returns the total amount of protocol rewards generated by the BRN since the last update.
    /// @return updatedTotalUnpaidProtocolRewards
    function _getLatestTotalUnpaidProtocolRewards() internal view returns (uint256 updatedTotalUnpaidProtocolRewards) {
        RMStorage storage rs = getRMStorage();

        if (block.timestamp == rs.lastUnpaidRewardUpdatedTimestamp) {
            return rs.totalUnpaidProtocolRewards;
        }

        return rs.totalUnpaidProtocolRewards
            + _protocolRewardRate() * (block.timestamp - rs.lastUnpaidRewardUpdatedTimestamp);
    }

    /// @dev Returns the total amount of protocol rewards generated by the BRN since the last update and updates the last update timestamp in storage.
    ///      The unpaidRewards are not updated in storage yet, it is expected that the calling function would perform the update,
    ///      after performing any other necessary operations and deductions from this amount.
    /// @return updatedTotalUnpaidProtocolRewards
    function _getLatestTotalUnpaidProtocolRewardsAndUpdateUpdatedTimestamp()
        internal
        returns (uint256 updatedTotalUnpaidProtocolRewards)
    {
        uint256 unpaidRewards = _getLatestTotalUnpaidProtocolRewards();
        getRMStorage().lastUnpaidRewardUpdatedTimestamp = block.timestamp;
        return unpaidRewards;
    }

    /// @dev Protocol rewards are distributed to the relayers through a shares mechanism.
    ///      During registration, a relayer is assigned a number of shares proportional to the amount of stake they have,
    ///      based on a non-decreasing share price.
    ///      The share price increases as more protocol rewards are generated.
    /// @param _unpaidRewards The total amount of protocol rewards that are generated but not distributed to the relayers.
    /// @return The share price of the protocol rewards.
    function _protocolRewardRelayerSharePrice(uint256 _unpaidRewards) internal view returns (FixedPointType) {
        RMStorage storage rs = getRMStorage();

        if (rs.totalProtocolRewardShares == FP_ZERO) {
            return FP_ONE;
        }
        return (rs.totalStake + _unpaidRewards).fp() / rs.totalProtocolRewardShares;
    }

    /// @dev Returns the amount of unclaimed protocol rewards earned by the given relayer.
    /// @param _relayer The relayer whose unclaimed protocol rewards are to be returned.
    /// @param _unpaidRewards The total amount of protocol rewards that are generated but not distributed to the relayers.
    /// @return The amount of unclaimed protocol rewards earned by the given relayer.
    function _protocolRewardsEarnedByRelayer(RelayerAddress _relayer, uint256 _unpaidRewards)
        internal
        view
        returns (uint256)
    {
        RMStorage storage rs = getRMStorage();
        uint256 totalValue =
            (rs.relayerInfo[_relayer].rewardShares * _protocolRewardRelayerSharePrice(_unpaidRewards)).u256();

        unchecked {
            uint256 rewards =
                totalValue >= rs.relayerInfo[_relayer].stake ? totalValue - rs.relayerInfo[_relayer].stake : 0;
            return rewards;
        }
    }

    /// @dev Utility function to calculate the protocol reward split between the relayer and the delegators.
    /// @param _totalRewards The total amount of protocol rewards earned by the relayer to be split.
    /// @param _delegatorRewardSharePercentage The percentage of the total rewards to be given to the delegators.
    /// @return The amount of rewards to be given to the relayer
    /// @return The amount of rewards to be given to the delegators
    function _calculateProtocolRewardSplit(uint256 _totalRewards, uint256 _delegatorRewardSharePercentage)
        internal
        pure
        returns (uint256, uint256)
    {
        uint256 delegatorRewards = (_totalRewards * _delegatorRewardSharePercentage) / (100 * PERCENTAGE_MULTIPLIER);
        return (_totalRewards - delegatorRewards, delegatorRewards);
    }

    /// @dev Calculates the amount of unclaimed protocol rewards earned by the given relayer, then calculates the split b/w the
    ///      relayer and the delegators, and finally calculates the amount of shares to be burned to claim these rewards.
    /// @param _relayer The relayer whose unclaimed protocol rewards are to be returned.
    /// @param _unpaidRewards The total amount of protocol rewards that are generated but not distributed to the relayers.
    /// @return relayerRewards The amount of rewards to be given to the relayer
    /// @return delegatorRewards The amount of rewards to be given to the delegators
    /// @return sharesToBurn The amount of shares to be burned to claim these rewards.
    function _getPendingProtocolRewardsData(RelayerAddress _relayer, uint256 _unpaidRewards)
        internal
        view
        returns (uint256 relayerRewards, uint256 delegatorRewards, FixedPointType sharesToBurn)
    {
        uint256 rewards = _protocolRewardsEarnedByRelayer(_relayer, _unpaidRewards);
        if (rewards == 0) {
            return (0, 0, FP_ZERO);
        }

        sharesToBurn = rewards.fp() / _protocolRewardRelayerSharePrice(_unpaidRewards);

        (relayerRewards, delegatorRewards) =
            _calculateProtocolRewardSplit(rewards, getRMStorage().relayerInfo[_relayer].delegatorPoolPremiumShare);
    }

    ////////////////////////////// Misc //////////////////////////////

    /// @dev Utility function to transfer tokens from TransactionAllocator to the given address.
    /// @param _token The token to transfer.
    /// @param _to The address to transfer the tokens to.
    /// @param _amount The amount of tokens to transfer.
    function _transfer(TokenAddress _token, address _to, uint256 _amount) internal {
        if (_token == NATIVE_TOKEN) {
            payable(_to).sendValue(_amount);
        } else {
            IERC20(TokenAddress.unwrap(_token)).safeTransfer(_to, _amount);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

/// @title uint256 Array Helper
/// @dev Helper functions for arrays of uint256
library U256ArrayHelper {
    error IndexOutOfBoundsU256(uint256 index, uint256 length);

    /// @dev Copies the array into memory and appends the value
    /// @param _array The array to append to
    /// @param _value The value to append
    /// @return The new array
    function cd_append(uint256[] calldata _array, uint256 _value) internal pure returns (uint256[] memory) {
        uint256 length = _array.length;
        uint256[] memory newArray = new uint256[](
            length + 1
        );

        for (uint256 i; i != length;) {
            newArray[i] = _array[i];
            unchecked {
                ++i;
            }
        }
        newArray[length] = _value;

        return newArray;
    }

    /// @dev Copies the array into memory and removes the value at the index, substituting the last value
    /// @param _array The array to remove from
    /// @param _index The index to remove
    /// @return The new array
    function cd_remove(uint256[] calldata _array, uint256 _index) internal pure returns (uint256[] memory) {
        uint256 newLength = _array.length - 1;
        if (_index > newLength) {
            revert IndexOutOfBoundsU256(_index, _array.length);
        }

        uint256[] memory newArray = new uint256[](newLength);

        for (uint256 i; i != newLength;) {
            if (i != _index) {
                newArray[i] = _array[i];
            } else {
                newArray[i] = _array[newLength];
            }
            unchecked {
                ++i;
            }
        }

        return newArray;
    }

    /// @dev Copies the array into memory and updates the value at the index
    /// @param _array The array to update
    /// @param _index The index to update
    /// @param _value The value to update
    /// @return The new array
    function cd_update(uint256[] calldata _array, uint256 _index, uint256 _value)
        internal
        pure
        returns (uint256[] memory)
    {
        if (_index >= _array.length) {
            revert IndexOutOfBoundsU256(_index, _array.length);
        }

        uint256[] memory newArray = _array;
        newArray[_index] = _value;
        return newArray;
    }

    /// @dev Calculate the hash of the array by packing the values and hashing them through keccak256
    /// @param _array The array to hash
    /// @return The hash of the array
    function cd_hash(uint256[] calldata _array) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked((_array)));
    }

    /// @dev Returns the index of the first element in _array greater than or equal to _target
    ///      The array must be sorted
    /// @param _array The array to find in
    /// @param _target The target value
    /// @return The index of the first element greater than or equal to _target
    function cd_lowerBound(uint256[] calldata _array, uint256 _target) internal pure returns (uint256) {
        uint256 low;
        uint256 high = _array.length;
        unchecked {
            while (low < high) {
                uint256 mid = (low + high) / 2;
                if (_array[mid] < _target) {
                    low = mid + 1;
                } else {
                    high = mid;
                }
            }
        }
        return low;
    }

    /// @dev Calculate the hash of the array by packing the values and hashing them through keccak256
    /// @param _array The array to hash
    /// @return The hash of the array
    function m_hash(uint256[] memory _array) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked((_array)));
    }

    /// @dev Removes the value at the index, substituting the last value.
    /// @param _array The array to remove from
    /// @param _index The index to remove
    function m_remove(uint256[] memory _array, uint256 _index) internal pure {
        uint256 newLength = _array.length - 1;

        if (_index > newLength) {
            revert IndexOutOfBoundsU256(_index, _array.length);
        }

        if (_index != newLength) {
            _array[_index] = _array[newLength];
        }

        // Reduce the array size
        assembly {
            mstore(_array, sub(mload(_array), 1))
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {RelayerAddress} from "ta-common/TATypes.sol";

/// @title Relayer Address Array Helper
/// @dev Helper functions for arrays of RelayerAddress
library RAArrayHelper {
    error IndexOutOfBoundsRA(uint256 index, uint256 length);

    /// @dev Copies the array into memory and appends the value
    /// @param _array The array to append to
    /// @param _value The value to append
    /// @return The new array
    function cd_append(RelayerAddress[] calldata _array, RelayerAddress _value)
        internal
        pure
        returns (RelayerAddress[] memory)
    {
        uint256 length = _array.length;
        RelayerAddress[] memory newArray = new RelayerAddress[](
            length + 1
        );

        for (uint256 i; i != length;) {
            newArray[i] = _array[i];
            unchecked {
                ++i;
            }
        }
        newArray[length] = _value;

        return newArray;
    }

    /// @dev Copies the array into memory and removes the value at the index, substituting the last value
    /// @param _array The array to remove from
    /// @param _index The index to remove
    /// @return The new array
    function cd_remove(RelayerAddress[] calldata _array, uint256 _index)
        internal
        pure
        returns (RelayerAddress[] memory)
    {
        uint256 newLength = _array.length - 1;
        if (_index > newLength) {
            revert IndexOutOfBoundsRA(_index, _array.length);
        }

        RelayerAddress[] memory newArray = new RelayerAddress[](newLength);

        for (uint256 i; i != newLength;) {
            if (i != _index) {
                newArray[i] = _array[i];
            } else {
                newArray[i] = _array[newLength];
            }
            unchecked {
                ++i;
            }
        }

        return newArray;
    }

    /// @dev Copies the array into memory and updates the value at the index
    /// @param _array The array to update
    /// @param _index The index to update
    /// @param _value The value to update
    /// @return The new array
    function cd_update(RelayerAddress[] calldata _array, uint256 _index, RelayerAddress _value)
        internal
        pure
        returns (RelayerAddress[] memory)
    {
        if (_index >= _array.length) {
            revert IndexOutOfBoundsRA(_index, _array.length);
        }

        RelayerAddress[] memory newArray = _array;
        newArray[_index] = _value;
        return newArray;
    }

    /// @dev Calculate the hash of the array by packing the values and hashing them through keccak256
    /// @param _array The array to hash
    /// @return The hash of the array
    function cd_hash(RelayerAddress[] calldata _array) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked((_array)));
    }

    /// @dev Calculate the hash of the array by packing the values and hashing them through keccak256
    /// @param _array The array to hash
    /// @return The hash of the array
    function m_hash(RelayerAddress[] memory _array) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked((_array)));
    }

    /// @dev Removes the value at the index, substituting the last value.
    /// @param _array The array to remove from
    /// @param _index The index to remove
    function m_remove(RelayerAddress[] memory _array, uint256 _index) internal pure {
        uint256 newLength = _array.length - 1;

        if (_index > newLength) {
            revert IndexOutOfBoundsRA(_index, _array.length);
        }

        if (_index != newLength) {
            _array[_index] = _array[newLength];
        }

        // Reduce the array size
        assembly {
            mstore(_array, sub(mload(_array), 1))
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Math} from "openzeppelin-contracts/utils/math/Math.sol";

using Math for uint256;
using Uint256WrapperHelper for uint256;
using FixedPointTypeHelper for FixedPointType;

uint256 constant PRECISION = 24;
uint256 constant MULTIPLIER = 10 ** PRECISION;

FixedPointType constant FP_ZERO = FixedPointType.wrap(0);
FixedPointType constant FP_ONE = FixedPointType.wrap(MULTIPLIER);

type FixedPointType is uint256;

/// @dev Helpers for converting uint256 to FixedPointType
library Uint256WrapperHelper {
    /// @dev Converts a uint256 to a FixedPointType by multiplying by MULTIPLIER
    /// @param _value The value to convert
    /// @return The converted value
    function fp(uint256 _value) internal pure returns (FixedPointType) {
        return FixedPointType.wrap(_value * MULTIPLIER);
    }
}

/// @dev Helpers for FixedPointType
library FixedPointTypeHelper {
    /// @dev Converts a FixedPointType to a uint256 by dividing by MULTIPLIER
    /// @param _value The value to convert
    /// @return The converted value
    function u256(FixedPointType _value) internal pure returns (uint256) {
        return FixedPointType.unwrap(_value) / MULTIPLIER;
    }

    /// @dev Calculates the square root of a FixedPointType
    /// @param _a The value to calculate the square root of
    /// @return The square root
    function sqrt(FixedPointType _a) internal pure returns (FixedPointType) {
        return FixedPointType.wrap((FixedPointType.unwrap(_a) * MULTIPLIER).sqrt());
    }

    /// @dev Multiplies a FixedPointType by a uint256, does not handle overflows
    /// @param _a Multiplicant
    /// @param _value Multiplier
    /// @return The product in FixedPointType
    function mul(FixedPointType _a, uint256 _value) internal pure returns (FixedPointType) {
        return FixedPointType.wrap(FixedPointType.unwrap(_a) * _value);
    }

    /// @dev Divides a FixedPointType by a uint256
    /// @param _a Dividend
    /// @param _value Divisor
    /// @return The result in FixedPointType
    function div(FixedPointType _a, uint256 _value) internal pure returns (FixedPointType) {
        return FixedPointType.wrap(FixedPointType.unwrap(_a) / _value);
    }
}

// Custom operator implementations for FixedPointType
function fixedPointAdd(FixedPointType _a, FixedPointType _b) pure returns (FixedPointType) {
    return FixedPointType.wrap(FixedPointType.unwrap(_a) + FixedPointType.unwrap(_b));
}

function fixedPointSubtract(FixedPointType _a, FixedPointType _b) pure returns (FixedPointType) {
    return FixedPointType.wrap(FixedPointType.unwrap(_a) - FixedPointType.unwrap(_b));
}

function fixedPointMultiply(FixedPointType _a, FixedPointType _b) pure returns (FixedPointType) {
    return FixedPointType.wrap(Math.mulDiv(FixedPointType.unwrap(_a), FixedPointType.unwrap(_b), MULTIPLIER));
}

function fixedPointDivide(FixedPointType _a, FixedPointType _b) pure returns (FixedPointType) {
    return FixedPointType.wrap(Math.mulDiv(FixedPointType.unwrap(_a), MULTIPLIER, FixedPointType.unwrap(_b)));
}

function fixedPointEquality(FixedPointType _a, FixedPointType _b) pure returns (bool) {
    return FixedPointType.unwrap(_a) == FixedPointType.unwrap(_b);
}

function fixedPointInequality(FixedPointType _a, FixedPointType _b) pure returns (bool) {
    return FixedPointType.unwrap(_a) != FixedPointType.unwrap(_b);
}

function fixedPointGt(FixedPointType _a, FixedPointType _b) pure returns (bool) {
    return FixedPointType.unwrap(_a) > FixedPointType.unwrap(_b);
}

function fixedPointGte(FixedPointType _a, FixedPointType _b) pure returns (bool) {
    return FixedPointType.unwrap(_a) >= FixedPointType.unwrap(_b);
}

function fixedPointLt(FixedPointType _a, FixedPointType _b) pure returns (bool) {
    return FixedPointType.unwrap(_a) < FixedPointType.unwrap(_b);
}

function fixedPointLte(FixedPointType _a, FixedPointType _b) pure returns (bool) {
    return FixedPointType.unwrap(_a) <= FixedPointType.unwrap(_b);
}

using {
    fixedPointAdd as +,
    fixedPointSubtract as -,
    fixedPointMultiply as *,
    fixedPointDivide as /,
    fixedPointEquality as ==,
    fixedPointInequality as !=,
    fixedPointGt as >,
    fixedPointGte as >=,
    fixedPointLt as <,
    fixedPointLte as <=
} for FixedPointType global;

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

/// @title VersionManager
/// @dev A Data Structure for applying delayed updates to a stored state, the state being a single bytes32 value.
/// The state active at the current point of time is the "active state", while any state that has been set but not yet activated is the "latest state".
/// In the absence of any pending state, the active state is the latest state.
/// The active state is generally used to perform any validations in the current context, while the latest state is used to accumulate changes to the state.
/// Time is assumed to be any non-decreasing value, like block.timestamp.
library VersionManager {
    /// @dev Emitted when a new latest state is set for activation.
    /// @param activationTime The time at which the latest state will become the active state.
    /// @param latestState The latest state that will become the active state.
    event VersionManagerLatestStateSetForActivation(uint256 indexed activationTime, bytes32 indexed latestState);

    /// @dev The internal state of the VersionManager.
    /// @custom:member slot1 The first storage slot of the VersionManager. Stores the state which entered the VersionManager "earlier"
    /// @custom:member slot2 The second storage slot of the VersionManager. Stores the state which entered the VersionManager "later"
    /// @custom:member pendingHashActivationTime The time at which the latest state will become the active state, used to decide which of the two slots is the active state and latest state
    struct VersionManagerState {
        bytes32 slot1;
        bytes32 slot2;
        uint256 pendingHashActivationTime;
    }

    /// @dev Initializes the VersionManager with a given state to be set as the active state.
    function initialize(VersionManagerState storage _v, bytes32 _currentHash) internal {
        _v.slot1 = _currentHash;
        _v.slot2 = _currentHash;
    }

    /// @dev Returns the active state hash.
    /// @param _v Version Manager Internal State
    /// @param _currentTime The time at which the active state is being queried.
    /// @return The active state hash.
    function activeStateHash(VersionManagerState storage _v, uint256 _currentTime) internal view returns (bytes32) {
        if (_v.pendingHashActivationTime == 0) {
            return _v.slot1;
        }

        if (_currentTime < _v.pendingHashActivationTime) {
            return _v.slot1;
        }

        return _v.slot2;
    }

    /// @dev Returns the latest state hash.
    /// @param _v Version Manager Internal State
    /// @return The latest state hash.
    function latestStateHash(VersionManagerState storage _v) internal view returns (bytes32) {
        return _v.slot2 == bytes32(0) ? _v.slot1 : _v.slot2;
    }

    /// @dev Returns true if the given hash matches the active state hash else false.
    /// @param _v Version Manager Internal State
    /// @param _hash The hash to check against the active state.
    /// @param _currentTime The time at which the active state is being queried.
    /// @return True if the given hash matches the active state hash else false.
    function verifyHashAgainstActiveState(VersionManagerState storage _v, bytes32 _hash, uint256 _currentTime)
        internal
        view
        returns (bool)
    {
        return _hash == activeStateHash(_v, _currentTime);
    }

    /// @dev Returns true if the given hash matches the latest state hash else false.
    /// @param _v Version Manager Internal State
    /// @param _hash The hash to check against the latest state.
    /// @return True if the given hash matches the latest state hash else false.
    function verifyHashAgainstLatestState(VersionManagerState storage _v, bytes32 _hash) internal view returns (bool) {
        return _hash == latestStateHash(_v);
    }

    /// @dev Sets the latest state hash, but does not activate it immediately
    /// @param _v Version Manager Internal State
    /// @param _hash The hash to set as the latest state
    /// @param _currentTime The time at which the latest state is being set
    function setLatestState(VersionManagerState storage _v, bytes32 _hash, uint256 _currentTime) internal {
        // If the active state is in slot2, then move it to slot1
        if (_v.pendingHashActivationTime != 0 && _currentTime >= _v.pendingHashActivationTime) {
            _v.slot1 = _v.slot2;
        }

        // Set the latest state in slot2 (assuming slot1 is the active state)
        _v.slot2 = _hash;

        // If pendingHashActivationTime = 0, activeState = slot1. Refer to implementation of activeStateHash()
        delete _v.pendingHashActivationTime;
    }

    /// @dev Schedule the latest state to be activated at a given time. If the latest state is already scheduled for activation, this function does nothing.
    /// @param _v Version Manager Internal State
    /// @param _activationTime The time at which the latest state will become the active state.
    function setLatestStateForActivation(VersionManagerState storage _v, uint256 _activationTime) internal {
        if (_v.pendingHashActivationTime != 0) {
            // Existing pending state is already scheduled for activation
            return;
        }

        _v.pendingHashActivationTime = _activationTime;
        emit VersionManagerLatestStateSetForActivation(_activationTime, latestStateHash(_v));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

//////////////////////////// UDVTS ////////////////////////////

type RelayerAddress is address;

function relayerEquality(RelayerAddress a, RelayerAddress b) pure returns (bool) {
    return RelayerAddress.unwrap(a) == RelayerAddress.unwrap(b);
}

function relayerInequality(RelayerAddress a, RelayerAddress b) pure returns (bool) {
    return RelayerAddress.unwrap(a) != RelayerAddress.unwrap(b);
}

using {relayerEquality as ==, relayerInequality as !=} for RelayerAddress global;

type DelegatorAddress is address;

function delegatorEquality(DelegatorAddress a, DelegatorAddress b) pure returns (bool) {
    return DelegatorAddress.unwrap(a) == DelegatorAddress.unwrap(b);
}

function delegatorInequality(DelegatorAddress a, DelegatorAddress b) pure returns (bool) {
    return DelegatorAddress.unwrap(a) != DelegatorAddress.unwrap(b);
}

using {delegatorEquality as ==, delegatorInequality as !=} for DelegatorAddress global;

type RelayerAccountAddress is address;

function relayerAccountEquality(RelayerAccountAddress a, RelayerAccountAddress b) pure returns (bool) {
    return RelayerAccountAddress.unwrap(a) == RelayerAccountAddress.unwrap(b);
}

function relayerAccountInequality(RelayerAccountAddress a, RelayerAccountAddress b) pure returns (bool) {
    return RelayerAccountAddress.unwrap(a) != RelayerAccountAddress.unwrap(b);
}

using {relayerAccountEquality as ==, relayerAccountInequality as !=} for RelayerAccountAddress global;

type TokenAddress is address;

function tokenEquality(TokenAddress a, TokenAddress b) pure returns (bool) {
    return TokenAddress.unwrap(a) == TokenAddress.unwrap(b);
}

function tokenInequality(TokenAddress a, TokenAddress b) pure returns (bool) {
    return TokenAddress.unwrap(a) != TokenAddress.unwrap(b);
}

using {tokenEquality as ==, tokenInequality as !=} for TokenAddress global;

//////////////////////////// Enums ////////////////////////////

/// @dev Enum for the status of a relayer.
enum RelayerStatus {
    Uninitialized, // The relayer has not registered in the system, or has successfully unregistered and exited.
    Active, // The relayer is active in the system.
    Exiting, // The relayer has called unregister(), and is waiting for the exit period to end to claim it's stake.
    Jailed // The relayer has been jailed by the system and must wait for the jail time to expire before manually re-entering or exiting.
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {RelayerAddress} from "./TATypes.sol";
import {RAArrayHelper} from "src/library/arrays/RAArrayHelper.sol";
import {U256ArrayHelper} from "src/library/arrays/U256ArrayHelper.sol";

/// @title RelayerStateManager
/// @dev Library for managing the state of the relayers.
library RelayerStateManager {
    using RAArrayHelper for RelayerAddress[];
    using U256ArrayHelper for uint256[];

    /// @dev Struct for storing the state of all relayers in the system.
    /// @custom:member cdf The cumulative distribution function of the relayers.
    /// @custom:member relayers The list of relayers.
    struct RelayerState {
        uint256[] cdf;
        RelayerAddress[] relayers;
    }

    /// @dev Appends a new relayer with the given stake to the state.
    /// @param _prev The previous state of the relayers.
    /// @param _relayerAddress The address of the relayer.
    /// @param _stake The stake of the relayer.
    /// @return newState The new state of the relayers.
    function addNewRelayer(RelayerState calldata _prev, RelayerAddress _relayerAddress, uint256 _stake)
        internal
        pure
        returns (RelayerState memory newState)
    {
        newState = RelayerState({
            cdf: _prev.cdf.cd_append(_stake + _prev.cdf[_prev.cdf.length - 1]),
            relayers: _prev.relayers.cd_append(_relayerAddress)
        });
    }

    /// @dev Removes a relayer from the state at the given index
    /// @param _prev The previous state of the relayers.
    /// @param _index The index of the relayer to remove.
    /// @return newState The new state of the relayers.
    function removeRelayer(RelayerState calldata _prev, uint256 _index)
        internal
        pure
        returns (RelayerState memory newState)
    {
        uint256 length = _prev.cdf.length;
        uint256 weightRemoved = _prev.cdf[_index] - (_index == 0 ? 0 : _prev.cdf[_index - 1]);
        uint256 lastWeight = _prev.cdf[length - 1] - (length == 1 ? 0 : _prev.cdf[length - 2]);

        // Copy all the elements except the last one
        uint256[] memory newCdf = new uint256[](length - 1);
        --length;
        for (uint256 i; i != length;) {
            newCdf[i] = _prev.cdf[i];

            unchecked {
                ++i;
            }
        }

        // Update the CDF starting from the index
        if (_index < length) {
            bool elementAtIndexIsIncreased = lastWeight >= weightRemoved;
            uint256 deltaAtIndex = elementAtIndexIsIncreased ? lastWeight - weightRemoved : weightRemoved - lastWeight;

            for (uint256 i = _index; i != length;) {
                if (elementAtIndexIsIncreased) {
                    newCdf[i] += deltaAtIndex;
                } else {
                    newCdf[i] -= deltaAtIndex;
                }

                unchecked {
                    ++i;
                }
            }
        }

        newState = RelayerState({cdf: newCdf, relayers: _prev.relayers.cd_remove(_index)});
    }

    /// @dev Increases the weight of a relayer in the CDF.
    /// @param _prev The previous state of the relayers.
    /// @param _relayerIndex The index of the relayer to update.
    /// @param _value The value to increase the relayer weight by.
    /// @return newCdf The new CDF of the relayers.
    function increaseWeight(RelayerState calldata _prev, uint256 _relayerIndex, uint256 _value)
        internal
        pure
        returns (uint256[] memory newCdf)
    {
        newCdf = _prev.cdf;
        uint256 length = newCdf.length;
        for (uint256 i = _relayerIndex; i != length;) {
            newCdf[i] += _value;
            unchecked {
                ++i;
            }
        }
    }

    /// @dev Decreases the weight of a relayer in the CDF.
    /// @param _prev The previous state of the relayers.
    /// @param _relayerIndex The index of the relayer to update.
    /// @param _value The value to decrease the relayer weight by.
    /// @return newCdf The new CDF of the relayers.
    function decreaseWeight(RelayerState calldata _prev, uint256 _relayerIndex, uint256 _value)
        internal
        pure
        returns (uint256[] memory newCdf)
    {
        newCdf = _prev.cdf;
        uint256 length = newCdf.length;
        for (uint256 i = _relayerIndex; i != length;) {
            newCdf[i] -= _value;
            unchecked {
                ++i;
            }
        }
    }

    /// @dev Given a CDF, calculates an array of individual weights.
    /// @param _cdf The CDF to convert.
    /// @return weights The array of weights.
    function cdfToWeights(uint256[] calldata _cdf) internal pure returns (uint256[] memory weights) {
        uint256 length = _cdf.length;
        weights = new uint256[](length);
        weights[0] = _cdf[0];
        for (uint256 i = 1; i != length;) {
            weights[i] = _cdf[i] - _cdf[i - 1];
            unchecked {
                ++i;
            }
        }
    }

    /// @dev Given an array of weights, calculates the CDF.
    /// @param _weights The array of weights to convert.
    /// @return cdf The CDF.
    function weightsToCdf(uint256[] memory _weights) internal pure returns (uint256[] memory cdf) {
        uint256 length = _weights.length;
        cdf = new uint256[](length);
        uint256 sum;
        for (uint256 i; i != length;) {
            sum += _weights[i];
            cdf[i] = sum;
            unchecked {
                ++i;
            }
        }
    }

    /// @dev Hash function used to generate the hash of the relayer state.
    /// @param _cdfHash The hash of the CDF array
    /// @param _relayerArrayHash The hash of the relayer array
    /// @return The hash of the relayer state
    function hash(bytes32 _cdfHash, bytes32 _relayerArrayHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_cdfHash, _relayerArrayHash));
    }

    /// @dev Hash function used to generate the hash of the relayer state.
    /// @param _state The relayer state
    /// @return The hash of the relayer state
    function hash(RelayerState memory _state) internal pure returns (bytes32) {
        return hash(_state.cdf.m_hash(), _state.relayers.m_hash());
    }

    /// @dev Hash function used to generate the hash of the relayer state. This variant is useful when the
    ///      original list of relayers has not changed
    /// @param _cdf The CDF array
    /// @param _relayers The relayer array
    /// @return The hash of the relayer state
    function hash(uint256[] memory _cdf, RelayerAddress[] calldata _relayers) internal pure returns (bytes32) {
        return hash(_cdf.m_hash(), _relayers.cd_hash());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {TokenAddress} from "./TATypes.sol";

// Controls the precision for specifying percentages. A value of 100 corresponds to precision upto two decimal places, like 12.23%
uint256 constant PERCENTAGE_MULTIPLIER = 100;

// The BICO Token is guaranteed to have 18 decimals
uint256 constant BOND_TOKEN_DECIMAL_MULTIPLIER = 10 ** 18;

// Sentinel value for native token address
TokenAddress constant NATIVE_TOKEN = TokenAddress.wrap(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {RelayerAddress} from "ta-common/TATypes.sol";

/// @title ITATransactionAllocationEventsErrors
interface ITATransactionAllocationEventsErrors {
    error RelayerAddressNotFoundInMemoryState(RelayerAddress relayerAddress);
    error RelayerIndexDoesNotPointToSelectedCdfInterval();
    error RelayerAddressDoesNotMatchSelectedRelayer();
    error InvalidRelayerGenerationIteration();
    error NoRelayersRegistered();
    error TransactionExecutionFailed(uint256 index, bytes returndata);
    error InvalidFeeAttached(uint256 totalExpectedValue, uint256 actualValue);
    error RelayerAlreadySubmittedTransaction(RelayerAddress relayerAddress, uint256 windowId);

    event TransactionStatus(uint256 indexed index, bool indexed success, bytes indexed returndata);
    event RelayerPenalized(
        RelayerAddress indexed relayerAddress, uint256 indexed newStake, uint256 indexed penaltyAmount
    );
    event RelayerJailed(RelayerAddress indexed relayerAddress, uint256 jailedUntilTimestamp);
    event LivenessCheckProcessed(uint256 indexed epochEndTimestamp);
    event NoTransactionsSubmittedInEpoch();
    event EpochEndTimestampUpdated(uint256 indexed epochEndTimestamp);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {RelayerAddress} from "ta-common/TATypes.sol";
import {FixedPointType} from "src/library/FixedPointArithmetic.sol";

/// @title ITATransactionAllocationGetters
interface ITATransactionAllocationGetters {
    function transactionsSubmittedByRelayer(RelayerAddress _relayerAddress) external view returns (uint256);

    function totalTransactionsSubmitted() external view returns (uint256);

    function epochLengthInSec() external view returns (uint256);

    function epochEndTimestamp() external view returns (uint256);

    function livenessZParameter() external view returns (FixedPointType);

    function stakeThresholdForJailing() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {RelayerAddress} from "ta-common/TATypes.sol";
import {FixedPointType} from "src/library/FixedPointArithmetic.sol";

/// @title TATransactionAllocationStorage
abstract contract TATransactionAllocationStorage {
    bytes32 internal constant TRANSACTION_ALLOCATION_STORAGE_SLOT = keccak256("TransactionAllocation.storage");

    struct TAStorage {
        ////////////////////////// Configuration Parameters //////////////////////////
        uint256 epochLengthInSec;
        uint256 epochEndTimestamp;
        FixedPointType livenessZParameter;
        uint256 stakeThresholdForJailing;
        ////////////////////////// Liveness Records //////////////////////////
        mapping(uint256 epochEndTimestamp => mapping(RelayerAddress => uint256 transactionsSubmitted))
            transactionsSubmitted;
        mapping(uint256 epochEndTimestamp => uint256) totalTransactionsSubmitted;
        ////////////////////////// Misc //////////////////////////
        mapping(RelayerAddress => uint256 lastTransactionSubmissionWindow) lastTransactionSubmissionWindow;
    }

    /* solhint-disable no-inline-assembly */
    function getTAStorage() internal pure returns (TAStorage storage ms) {
        bytes32 slot = TRANSACTION_ALLOCATION_STORAGE_SLOT;
        assembly {
            ms.slot := slot
        }
    }

    /* solhint-enable no-inline-assembly */
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IGuards} from "./interfaces/IGuards.sol";

/// @title Guards
/// @dev Common guard modifiers
abstract contract Guards is IGuards {
    ///  @dev Used by core functions to prevent the execute() from function calling them.
    ///       The execute() function of the Transaction Allocation module accepts arbitrary calldata from the user and delegatecalls to itself,
    ///       which means that the user can call any function of the contract with any arguments and the function will be executed in the context of the contract.
    ///       All core public and external functions MUST use this modifier to prevent the execute() function from calling them.
    ///       This is tested in InternalInvocationTest.sol
    modifier noSelfCall() {
        if (msg.sender == address(this)) {
            revert NoSelfCall();
        }
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.19;

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.19;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
import "../../../utils/Address.sol";

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

    /**
     * @dev An operation with an ERC20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
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
        if (nonceAfter != nonceBefore + 1) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return success && (returndata.length == 0 || abi.decode(returndata, (bool))) && address(token).code.length > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.19;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
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
        return functionCallWithValue(target, data, 0, defaultRevert);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with a
     * `customRevert` function as a fallback when `target` reverts.
     *
     * Requirements:
     *
     * - `customRevert` must be a reverting function.
     *
     * _Available since v5.0._
     */
    function functionCall(
        address target,
        bytes memory data,
        function() internal view customRevert
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, customRevert);
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
        return functionCallWithValue(target, data, value, defaultRevert);
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with a `customRevert` function as a fallback revert reason when `target` reverts.
     *
     * Requirements:
     *
     * - `customRevert` must be a reverting function.
     *
     * _Available since v5.0._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        function() internal view customRevert
    ) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, customRevert);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, defaultRevert);
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
        function() internal view customRevert
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, customRevert);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, defaultRevert);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        function() internal view customRevert
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, customRevert);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided `customRevert`) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v5.0._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        function() internal view customRevert
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check if target is a contract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                if (target.code.length == 0) {
                    revert AddressEmptyCode(target);
                }
            }
            return returndata;
        } else {
            _revert(returndata, customRevert);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or with a default revert error.
     *
     * _Available since v5.0._
     */
    function verifyCallResult(bool success, bytes memory returndata) internal view returns (bytes memory) {
        return verifyCallResult(success, returndata, defaultRevert);
    }

    /**
     * @dev Same as {xref-Address-verifyCallResult-bool-bytes-}[`verifyCallResult`], but with a
     * `customRevert` function as a fallback when `success` is `false`.
     *
     * Requirements:
     *
     * - `customRevert` must be a reverting function.
     *
     * _Available since v5.0._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        function() internal view customRevert
    ) internal view returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, customRevert);
        }
    }

    /**
     * @dev Default reverting function when no `customRevert` is provided in a function call.
     */
    function defaultRevert() internal pure {
        revert FailedInnerCall();
    }

    function _revert(bytes memory returndata, function() internal view customRevert) private view {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            customRevert();
            revert FailedInnerCall();
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {RelayerAddress, TokenAddress} from "../TATypes.sol";
import {FixedPointType} from "src/library/FixedPointArithmetic.sol";

/// @title ITAHelpers
interface ITAHelpers {
    error RelayerIsNotActive(RelayerAddress relayer);
    error ParameterLengthMismatch();
    error InvalidLatestRelayerState();
    error InvalidActiveRelayerState();

    event DelegatorRewardsAdded(RelayerAddress indexed _relayer, TokenAddress indexed _token, uint256 indexed _amount);
    event RelayerProtocolSharesBurnt(RelayerAddress indexed relayerAddress, FixedPointType indexed sharesBurnt);
    event NewRelayerState(bytes32 indexed relayerStateHash, RelayerAddress[] relayers, uint256[] cdf);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

import {FixedPointType} from "src/library/FixedPointArithmetic.sol";
import {VersionManager} from "src/library/VersionManager.sol";
import {RelayerAddress, RelayerAccountAddress, RelayerStatus, TokenAddress} from "ta-common/TATypes.sol";

/// @title TARelayerManagementStorage
abstract contract TARelayerManagementStorage {
    bytes32 internal constant RELAYER_MANAGEMENT_STORAGE_SLOT = keccak256("RelayerManagement.storage");

    /// @dev Struct for storing relayer information.
    /// @custom:member stake The amount of stake the relayer has in bond token (BICO).
    /// @custom:member endpoint The rpc endpoint of the relayer.
    /// @custom:member isAccount A mapping of relayer account addresses to whether they are a relayer account.
    ///                          A relayer account can submit transactions on behalf of the relayer.
    /// @custom:member status The status of the relayer.
    /// @custom:member minExitTimestamp If status == Jailed, the minimum timestamp after which the relayer can exit jail.
    ///                                 If status == Exiting, the timestamp after which the relayer can withdraw their stake.
    /// @custom:member delegatorPoolPremiumShare The percentage of the relayer protocol rewards the delegators receive.
    /// @custom:member unpaidProtocolRewards The amount of protocol rewards for the relayer that have been accounted for but not yet claimed.
    /// @custom:member rewardShares The amount of protocol rewards shares that have been minted for the relayer.
    struct RelayerInfo {
        uint256 stake;
        string endpoint;
        mapping(RelayerAccountAddress => bool) isAccount;
        RelayerStatus status;
        uint256 minExitTimestamp;
        uint256 delegatorPoolPremiumShare;
        uint256 unpaidProtocolRewards;
        FixedPointType rewardShares;
    }

    /// @dev The storage struct for the RelayerManagement module.
    struct RMStorage {
        ////////////////////////// Configuration Parameters //////////////////////////
        IERC20 bondToken;
        mapping(RelayerAddress => RelayerInfo) relayerInfo;
        uint256 relayersPerWindow;
        uint256 blocksPerWindow;
        uint256 jailTimeInSec;
        uint256 withdrawDelayInSec;
        uint256 absencePenaltyPercentage;
        uint256 minimumStakeAmount;
        uint256 relayerStateUpdateDelayInWindows;
        uint256 baseRewardRatePerMinimumStakePerSec;
        ////////////////////////// Relayer State Management //////////////////////////
        VersionManager.VersionManagerState relayerStateVersionManager;
        ////////////////////////// Constant Rate Rewards //////////////////////////
        uint256 totalUnpaidProtocolRewards;
        uint256 lastUnpaidRewardUpdatedTimestamp;
        FixedPointType totalProtocolRewardShares;
        ////////////////////////// Global counters for the "latest" state //////////////////////////
        uint256 relayerCount;
        uint256 totalStake;
    }

    /* solhint-disable no-inline-assembly */
    function getRMStorage() internal pure returns (RMStorage storage ms) {
        bytes32 slot = RELAYER_MANAGEMENT_STORAGE_SLOT;
        assembly {
            ms.slot := slot
        }
    }

    /* solhint-enable no-inline-assembly */
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {FixedPointType} from "src/library/FixedPointArithmetic.sol";
import {RelayerAddress, DelegatorAddress, TokenAddress} from "ta-common/TATypes.sol";

/// @title TADelegationStorage
abstract contract TADelegationStorage {
    bytes32 internal constant DELEGATION_STORAGE_SLOT = keccak256("Delegation.storage");

    /// @dev Structure for storing the information of a delegation withdrawal.
    /// @custom:member tokens The tokens to be withdrawn.
    /// @custom:member amounts The corresponding amounts of tokens to be withdrawn.
    /// @custom:member minWithdrawalTimestamp The minimum timestamp after which the withdrawal can be executed.
    struct DelegationWithdrawal {
        uint256 minWithdrawalTimestamp;
        mapping(TokenAddress => uint256) amounts;
    }

    struct TADStorage {
        ////////////////////////// Configuration Parameters //////////////////////////
        uint256 minimumDelegationAmount;
        uint256 delegationWithdrawDelayInSec;
        mapping(RelayerAddress => uint256) totalDelegation;
        TokenAddress[] supportedPools;
        ////////////////////////// Delegation State //////////////////////////
        mapping(RelayerAddress => mapping(DelegatorAddress => uint256)) delegation;
        mapping(RelayerAddress => mapping(DelegatorAddress => mapping(TokenAddress => FixedPointType))) shares;
        mapping(RelayerAddress => mapping(TokenAddress => FixedPointType)) totalShares;
        mapping(RelayerAddress => mapping(TokenAddress => uint256)) unclaimedRewards;
        mapping(RelayerAddress => mapping(DelegatorAddress => DelegationWithdrawal)) delegationWithdrawal;
    }

    /* solhint-disable no-inline-assembly */
    function getTADStorage() internal pure returns (TADStorage storage ms) {
        bytes32 slot = DELEGATION_STORAGE_SLOT;
        assembly {
            ms.slot := slot
        }
    }
    /* solhint-enable no-inline-assembly */
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.19;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Muldiv operation overflow.
     */
    error MathOverflowedMulDiv();

    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v5.0._
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
     * _Available since v5.0._
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
     * _Available since v5.0._
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
     * _Available since v5.0._
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
     * _Available since v5.0._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            if (denominator <= prod1) {
                revert MathOverflowedMulDiv();
            }

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

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
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title Guards
/// @dev Common guard modifiers
interface IGuards {
    error NoSelfCall();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.19;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
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
// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "../Core/TroveManager.sol";
import "../Core/SortedTroves.sol";
import "../Core/YetiController.sol";

/*  Helper contract for grabbing Trove data for the front end. Not part of the core Yeti system. */
contract MultiTroveGetter {
    struct CombinedTroveData {
        address owner;

        uint debt;
        address[] colls;
        uint[] amounts;

        address[] allColls;
        uint[] stakeAmounts;
        uint[] snapshotAmounts;
        uint[] snapshotYUSDDebts;
    }

    TroveManager public troveManager; // XXX Troves missing from ITroveManager?
    ISortedTroves public sortedTroves;
    IYetiController public controller;

    constructor(TroveManager _troveManager, ISortedTroves _sortedTroves, IYetiController _controller) public {
        troveManager = _troveManager;
        sortedTroves = _sortedTroves;
        controller = _controller;
    }

    function getMultipleSortedTroves(int _startIdx, uint _count)
        external view returns (CombinedTroveData[] memory _troves)
    {
        uint startIdx;
        bool descend;

        if (_startIdx >= 0) {
            startIdx = uint(_startIdx);
            descend = true;
        } else {
            startIdx = uint(-(_startIdx + 1));
            descend = false;
        }

        uint sortedTrovesSize = sortedTroves.getSize();

        if (startIdx >= sortedTrovesSize) {
            _troves = new CombinedTroveData[](0);
        } else {
            uint maxCount = sortedTrovesSize - startIdx;

            if (_count > maxCount) {
                _count = maxCount;
            }

            if (descend) {
                _troves = _getMultipleSortedTrovesFromHead(startIdx, _count);
            } else {
                _troves = _getMultipleSortedTrovesFromTail(startIdx, _count);
            }
        }
    }

    function _getMultipleSortedTrovesFromHead(uint _startIdx, uint _count)
        internal view returns (CombinedTroveData[] memory _troves)
    {
        address currentTroveowner = sortedTroves.getFirst();

        for (uint idx = 0; idx < _startIdx; ++idx) {
            currentTroveowner = sortedTroves.getNext(currentTroveowner);
        }

        _troves = new CombinedTroveData[](_count);

        for (uint idx = 0; idx < _count; ++idx) {
            _troves[idx] = _getCombinedTroveData(currentTroveowner);
            currentTroveowner = sortedTroves.getNext(currentTroveowner);
        }
    }

    function _getMultipleSortedTrovesFromTail(uint _startIdx, uint _count)
        internal view returns (CombinedTroveData[] memory _troves)
    {
        address currentTroveowner = sortedTroves.getLast();

        for (uint idx = 0; idx < _startIdx; ++idx) {
            currentTroveowner = sortedTroves.getPrev(currentTroveowner);
        }

        _troves = new CombinedTroveData[](_count);

        for (uint idx = 0; idx < _count; ++idx) {
            _troves[idx] = _getCombinedTroveData(currentTroveowner);
            currentTroveowner = sortedTroves.getPrev(currentTroveowner);
        }
    }

    function _getCombinedTroveData(address _troveOwner) internal view returns (CombinedTroveData memory data) {
        data.owner = _troveOwner;
        data.debt = troveManager.getTroveDebt(_troveOwner);
        (data.colls, data.amounts) = troveManager.getTroveColls(_troveOwner);

        data.allColls = controller.getValidCollateral();
        data.stakeAmounts = new uint[](data.allColls.length);
        data.snapshotAmounts = new uint[](data.allColls.length);
        uint256 collsLen = data.allColls.length;
        for (uint256 i; i < collsLen; ++i) {
            address token = data.allColls[i];

            data.stakeAmounts[i] = troveManager.getTroveStake(_troveOwner, token);
            data.snapshotAmounts[i] = troveManager.getRewardSnapshotColl(_troveOwner, token);
            data.snapshotYUSDDebts[i] = troveManager.getRewardSnapshotYUSD(_troveOwner, token);
        }
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
import "../Interfaces/IYetiController.sol";
import "../Interfaces/ITroveManagerLiquidations.sol";
import "../Interfaces/ITroveManagerRedemptions.sol";
import "../Interfaces/IERC20.sol";
import "../Dependencies/TroveManagerBase.sol";
import "../Dependencies/ReentrancyGuard.sol";

/**
 * @title Deals with state of all system troves
 * @notice It has all the external functions for liquidations, redemptions,
 * as well as functions called by BorrowerOperations function calls.
 */

contract TroveManager is TroveManagerBase, ITroveManager, ReentrancyGuard {
    address internal borrowerOperationsAddress;

    IStabilityPool internal stabilityPoolContract;

    ITroveManager internal troveManager;

    IYUSDToken internal yusdTokenContract;

    IYETIToken internal yetiTokenContract;

    ITroveManagerRedemptions internal troveManagerRedemptions;

    ITroveManagerLiquidations internal troveManagerLiquidations;

    address internal gasPoolAddress;

    address internal troveManagerRedemptionsAddress;

    address internal troveManagerLiquidationsAddress;

    ISortedTroves internal sortedTroves;

    ICollSurplusPool internal collSurplusPool;

    bytes32 public constant NAME = "TroveManager";

    // --- Data structures ---

    uint256 internal constant SECONDS_IN_ONE_MINUTE = 60;

    /*
     * Half-life of 12h. 12h = 720 min
     * (1/2) = d^720 => d = (1/2)^(1/720)
     */
    uint256 public constant MINUTE_DECAY_FACTOR = 999037758833783000;
    uint256 public constant MAX_BORROWING_FEE = DECIMAL_PRECISION * 5 / 100; // 5%

    // During bootsrap period redemptions are not allowed
    uint256 public constant BOOTSTRAP_PERIOD = 14 seconds;

    // See documentation for explanation of baseRate
    uint256 public baseRate;

    // The timestamp of the latest fee operation (redemption or new YUSD issuance)
    uint256 public lastFeeOperationTime;

    // Mapping of all troves in the system
    mapping(address => Trove) Troves;

    // uint256 public totalStakes;
    mapping(address => uint256) public totalStakes;

    // Snapshot of the value of totalStakes, taken immediately after the latest liquidation
    mapping(address => uint256) public totalStakesSnapshot;

    // Snapshot of the total collateral across the ActivePool and DefaultPool, immediately after the latest liquidation.
    mapping(address => uint256) public totalCollateralSnapshot;

    /*
     * L_Coll and L_YUSDDebt track the sums of accumulated liquidation rewards per unit staked. Each collateral type has
     * its own L_Coll and L_YUSDDebt.
     * During its lifetime, each stake earns:
     *
     * A Collateral gain of ( stake * [L_Coll[coll] - L_Coll[coll](0)] )
     * A YUSDDebt increase  of ( stake * [L_YUSDDebt - L_YUSDDebt(0)] )
     *
     * Where L_Coll[coll](0) and L_YUSDDebt(0) are snapshots of L_Coll[coll] and L_YUSDDebt for the active Trove taken at the instant the stake was made
     */
    mapping(address => uint256) private L_Coll;
    mapping(address => uint256) public L_YUSDDebt;

    // Map addresses with active troves to their RewardSnapshot
    mapping(address => RewardSnapshot) rewardSnapshots;

    // Object containing the reward snapshots for a given active trove
    struct RewardSnapshot {
        mapping(address => uint256) CollRewards;
        mapping(address => uint256) YUSDDebts;
    }

    // Array of all active trove addresses - used to to compute an approximate hint off-chain, for the sorted list insertion
    address[] private TroveOwners;

    // Error trackers for the trove redistribution calculation
    mapping(address => uint256) public lastCollError_Redistribution;
    mapping(address => uint256) public lastYUSDDebtError_Redistribution;

    /*
     * --- Variable container structs for liquidations ---
     *
     * These structs are used to hold, return and assign variables inside the liquidation functions,
     * in order to avoid the error: "CompilerError: Stack too deep".
     **/

    // --- Events ---

    event BaseRateUpdated(uint256 _baseRate);
    event LastFeeOpTimeUpdated(uint256 _lastFeeOpTime);
    event TotalStakesUpdated(address token, uint256 _newTotalStakes);
    event SystemSnapshotsUpdated(uint256 _unix);

    event Liquidation(
        uint256 liquidatedAmount,
        uint256 totalYUSDGasCompensation,
        address[] totalCollTokens,
        uint256[] totalCollAmounts,
        address[] totalCollGasCompTokens,
        uint256[] totalCollGasCompAmounts
    );

    event LTermsUpdated(address _Coll_Address, uint256 _L_Coll, uint256 _L_YUSDDebt);
    event TroveSnapshotsUpdated(uint256 _unix);
    event TroveIndexUpdated(address _borrower, uint256 _newIndex);
    event TroveUpdated(
        address indexed _borrower,
        uint256 _debt,
        address[] _tokens,
        uint256[] _amounts,
        TroveManagerOperation operation
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
        address _troveManagerRedemptionsAddress,
        address _troveManagerLiquidationsAddress
    ) external override onlyOwner {
        checkContract(_borrowerOperationsAddress);
        borrowerOperationsAddress = _borrowerOperationsAddress;
        activePool = IActivePool(_activePoolAddress);
        defaultPool = IDefaultPool(_defaultPoolAddress);
        stabilityPoolContract = IStabilityPool(_stabilityPoolAddress);
        controller = IYetiController(_controllerAddress);
        checkContract(_gasPoolAddress);
        gasPoolAddress = _gasPoolAddress;
        collSurplusPool = ICollSurplusPool(_collSurplusPoolAddress);
        yusdTokenContract = IYUSDToken(_yusdTokenAddress);
        sortedTroves = ISortedTroves(_sortedTrovesAddress);
        yetiTokenContract = IYETIToken(_yetiTokenAddress);

        troveManagerRedemptionsAddress = _troveManagerRedemptionsAddress;
        troveManagerLiquidationsAddress = _troveManagerLiquidationsAddress;
        troveManagerRedemptions = ITroveManagerRedemptions(_troveManagerRedemptionsAddress);
        troveManagerLiquidations = ITroveManagerLiquidations(_troveManagerLiquidationsAddress);
        _renounceOwnership();
    }

    // --- Trove Liquidation functions ---

    /**
     * @notice Single liquidation function. Closes the trove if its ICR is lower than the minimum collateral ratio.
     * @param _borrower The address of the Trove owner
     */
    function liquidate(address _borrower) external override nonReentrant {
        _requireTroveIsActive(_borrower);

        address[] memory borrowers = new address[](1);
        borrowers[0] = _borrower;
        troveManagerLiquidations.batchLiquidateTroves(borrowers, msg.sender);
    }

    /**
     * @notice Attempt to liquidate a custom list of troves provided by the caller.
     * @param _troveArray The list of Troves' Addresses
     * @param _liquidator The address of the liquidator 
     */
    function batchLiquidateTroves(address[] memory _troveArray, address _liquidator)
        external
        override
        nonReentrant
    {
        troveManagerLiquidations.batchLiquidateTroves(_troveArray, _liquidator);
    }

    // --- Liquidation helper functions ---

    /**
     * @dev This function is called only by TroveManagerLiquidations.sol during a liquidation
     *   where there is a surplus. On any liquidation, only up to 110% of the debt in
     *   collateral can be sent to the stability pool and any surplus is sent to the collateral surplus pool
     *    it is claimable by the trove owner who was liquidated
     */
    function collSurplusUpdate(
        address _account,
        address[] memory _tokens,
        uint256[] memory _amounts
    ) external override {
        _requireCallerIsTML();
        collSurplusPool.accountSurplus(_account, _tokens, _amounts);
    }

    /**
     * @notice Move a Trove's pending debt and collateral rewards from distributions, from the Default Pool to the Active Pool
     */
    function _movePendingTroveRewardsToActivePool(
        IActivePool _activePool,
        IDefaultPool _defaultPool,
        uint256 _YUSD,
        address[] memory _tokens,
        uint256[] memory _amounts
    ) internal {
        _defaultPool.decreaseYUSDDebt(_YUSD);
        _activePool.increaseYUSDDebt(_YUSD);
        _defaultPool.sendCollsToActivePool(_tokens, _amounts);
    }

    /**
     * @notice Update position for a set of troves using latest price data. This can be called by anyone.
     * Yeti Finance will also be running a bot to assist with keeping the list from becoming too stale.
     * @param _borrowers The list of addresses of the troves to update
     * @param _lowerHints The list of lower hints for the troves which are to be updated
     * @param _upperHints The list of upper hints for the troves which are to be updated
     */
    function updateTroves(
        address[] calldata _borrowers,
        address[] calldata _lowerHints,
        address[] calldata _upperHints
    ) external override {
        uint256 lowerHintsLen = _lowerHints.length;
        require(_borrowers.length == lowerHintsLen, "TM: borrowers length mismatch");
        require(lowerHintsLen == _upperHints.length, "TM: hints length mismatch");

        uint256[] memory RICRList = new uint256[](lowerHintsLen);

        for (uint256 i; i < lowerHintsLen; ++i) {
            (
                uint256 debt,
                address[] memory tokens,
                uint256[] memory amounts,
                ,
                ,

            ) = getEntireDebtAndColls(_borrowers[i]);
            RICRList[i] = _getRICRColls(newColls(tokens, amounts), debt);
        }
        sortedTroves.reInsertMany(_borrowers, RICRList, _lowerHints, _upperHints);
    }

    /**
     * @notice Update a particular trove address in the liquidatable troves list
     * @dev This function is called by the UpdateTroves bot and if a trove is liquidatable but the gas is too congested to liquidated, then
     * this will add it to the list so that no SP withdrawal can happen. If the trove is no longer liquidatable then this function will remove
     * it from the list. This function calls sortedTroves' updateLiquidatableTrove function.
     * Intended to be a cheap function call since it is going to be called when liquidations are not possible
     * @param _id Trove's id
     */
    function updateLiquidatableTrove(address _id) external override {
        uint256 ICR = getCurrentICR(_id);
        bool isLiquidatable = ICR < MCR;
        sortedTroves.updateLiquidatableTrove(_id, isLiquidatable);
    }

    /**
     * @notice Send _YUSDamount YUSD to the system and redeem the corresponding amount of collateral
     * from as many Troves as are needed to fill the redemption request. Applies pending rewards to a Trove before reducing its debt and coll.
     * @dev if _amount is very large, this function can run out of gas, specially if traversed troves are small. This can be easily avoided by
     * splitting the total _amount in appropriate chunks and calling the function multiple times.
     *
     * Param `_maxIterations` can also be provided, so the loop through Troves is capped (if it’s zero, it will be ignored).This makes it easier to
     * avoid OOG for the frontend, as only knowing approximately the average cost of an iteration is enough, without needing to know the “topology”
     * of the trove list. It also avoids the need to set the cap in stone in the contract, nor doing gas calculations, as both gas price and opcode
     * costs can vary.
     *
     * All Troves that are redeemed from -- with the likely exception of the last one -- will end up with no debt left, therefore they will be closed.
     * If the last Trove does have some remaining debt, it has a finite ICR, and the reinsertion could be anywhere in the list, therefore it requires a hint.
     * A frontend should use getRedemptionHints() to calculate what the ICR of this Trove will be after redemption, and pass a hint for its position
     * in the sortedTroves list along with the ICR value that the hint was found for.
     *
     * If another transaction modifies the list between calling getRedemptionHints() and passing the hints to redeemCollateral(), it is very
     * likely that the last (partially) redeemed Trove would end up with a different ICR than what the hint is for. In this case the redemption
     * will stop after the last completely redeemed Trove and the sender will keep the remaining YUSD amount, which they can attempt to redeem later.
     * @param _YUSDamount The intended amount of YUSD to redeem
     * @param _YUSDMaxFee The maximum accepted fee in YUSD the user is willing to pay
     * @param _firstRedemptionHint The hint for the position of the first redeemed Trove in the sortedTroves list
     * @param _upperPartialRedemptionHint The upper hint for the position of the last partially redeemed Trove in the sortedTroves list
     * @param _lowerPartialRedemptionHint The lower hint for the position of the last partially redeemed Trove in the sortedTroves list
     * @param _partialRedemptionHintRICR The RICR of the last partially redeemed Trove in the sortedTroves list
     * @param _maxIterations The maximum number of iterations to perform. If zero, the function will run until it runs out of gas.
     */
    function redeemCollateral(
        uint256 _YUSDamount,
        uint256 _YUSDMaxFee,
        address _firstRedemptionHint,
        address _upperPartialRedemptionHint,
        address _lowerPartialRedemptionHint,
        uint256 _partialRedemptionHintRICR,
        uint256 _maxIterations
    ) external override nonReentrant {
        troveManagerRedemptions.redeemCollateral(
            _YUSDamount,
            _YUSDMaxFee,
            _firstRedemptionHint,
            _upperPartialRedemptionHint,
            _lowerPartialRedemptionHint,
            _partialRedemptionHintRICR,
            _maxIterations,
            msg.sender
        );
    }

    /** 
     * @notice Secondary function for redeeming collateral. See above for how YUSDMaxFee is calculated.
            Redeems one collateral type from only one trove. Included for gas efficiency of arbitrages. 
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
        address _target,
        address _upperHint,
        address _lowerHint,
        uint256 _hintRICR,
        address _collToRedeem
    ) external override nonReentrant {
        troveManagerRedemptions.redeemCollateralSingle(
            _YUSDamount,
            _YUSDMaxFee,
            _target,
            _upperHint,
            _lowerHint,
            _hintRICR,
            _collToRedeem,
            msg.sender
        );
    }

    // --- Getters ---

    function getTroveOwnersCount() external view override returns (uint256) {
        return TroveOwners.length;
    }

    function getTroveFromTroveOwnersArray(uint256 _index) external view override returns (address) {
        return TroveOwners[_index];
    }

    // --- Helper functions ---

    /**
     * @notice Helper function to return the current individual collateral ratio (ICR) of a given Trove.
     * @dev Takes a trove's pending coll and debt rewards from redistributions into account.
     * @param _borrower The address of the Trove to get the ICR
     * @return ICR
     */
    function getCurrentICR(address _borrower) public view override returns (uint256 ICR) {
        (newColls memory colls, uint256 currentYUSDDebt) = _getCurrentTroveState(_borrower);

        ICR = _getICRColls(colls, currentYUSDDebt);
    }

    /**
     *   @notice Helper function to return the current recovery individual collateral ratio (RICR) of a given Trove.
     *           RICR uses recovery ratios which are higher for more stable assets like stablecoins.
     *   @dev Takes a trove's pending coll and debt rewards from redistributions into account.
     *   @param _borrower The address of the Trove to get the RICR
     *   @return RICR
     */
    function getCurrentRICR(address _borrower) external view override returns (uint256 RICR) {
        (newColls memory colls, uint256 currentYUSDDebt) = _getCurrentTroveState(_borrower);

        RICR = _getRICRColls(colls, currentYUSDDebt);
    }

    /**
     *   @notice Gets current trove state as colls and debt.
     *   @param _borrower The address of the Trove
     *   @return colls -- newColls of the trove tokens and amounts
     *   @return YUSDdebt -- the current debt of the trove
     */
    function _getCurrentTroveState(address _borrower)
        internal
        view
        returns (newColls memory colls, uint256 YUSDdebt)
    {
        newColls memory pendingCollReward = _getPendingCollRewards(_borrower);
        uint256 pendingYUSDDebtReward = getPendingYUSDDebtReward(_borrower);

        YUSDdebt = Troves[_borrower].debt.add(pendingYUSDDebtReward);
        colls = _sumColls(Troves[_borrower].colls, pendingCollReward);
    }

    /**
     * @notice Add the borrowers's coll and debt rewards earned from redistributions, to their Trove
     * @param _borrower The address of the Trove
     */
    function applyPendingRewards(address _borrower) external override {
        _requireCallerIsBOorTMR();
        return _applyPendingRewards(activePool, defaultPool, _borrower);
    }

    /**
     * @notice Add the borrowers's coll and debt rewards earned from redistributions, to their Trove
     * @param _borrower The address of the Trove
     */
    function _applyPendingRewards(
        IActivePool _activePool,
        IDefaultPool _defaultPool,
        address _borrower
    ) internal {
        if (hasPendingRewards(_borrower)) {
            _requireTroveIsActive(_borrower);

            // Compute pending collateral rewards
            newColls memory pendingCollReward = _getPendingCollRewards(_borrower);
            uint256 pendingYUSDDebtReward = getPendingYUSDDebtReward(_borrower);

            // Apply pending rewards to trove's state
            Troves[_borrower].colls = _sumColls(Troves[_borrower].colls, pendingCollReward);
            Troves[_borrower].debt = Troves[_borrower].debt.add(pendingYUSDDebtReward);

            _updateTroveRewardSnapshots(_borrower);

            // Transfer from DefaultPool to ActivePool
            _movePendingTroveRewardsToActivePool(
                _activePool,
                _defaultPool,
                pendingYUSDDebtReward,
                pendingCollReward.tokens,
                pendingCollReward.amounts
            );

            emit TroveUpdated(
                _borrower,
                Troves[_borrower].debt,
                Troves[_borrower].colls.tokens,
                Troves[_borrower].colls.amounts,
                TroveManagerOperation.applyPendingRewards
            );
        }
    }

    /**
     * @notice Update borrower's snapshots of L_Coll and L_YUSDDebt to reflect the current values
     * @param _borrower The address of the Trove
     */
    function updateTroveRewardSnapshots(address _borrower) external override {
        _requireCallerIsBorrowerOperations();
        _updateTroveRewardSnapshots(_borrower);
    }

    /**
     * @notice Internal function to update borrower's snapshots of L_Coll and L_YUSDDebt to reflect the current values
     *         Called when updating trove reward snapshots or when applying pending rewards
     * @param _borrower The address of the Trove
     */
    function _updateTroveRewardSnapshots(address _borrower) internal {
        address[] memory allColls = Troves[_borrower].colls.tokens;
        uint256 allCollsLen = allColls.length;
        for (uint256 i; i < allCollsLen; ++i) {
            address asset = allColls[i];
            rewardSnapshots[_borrower].CollRewards[asset] = L_Coll[asset];
            rewardSnapshots[_borrower].YUSDDebts[asset] = L_YUSDDebt[asset];
        }
        emit TroveSnapshotsUpdated(block.timestamp);
    }

    /**
     * @notice Get the borrower's pending accumulated Coll rewards, earned by their stake
     * @dev Returned tokens and amounts are the length of controller.getValidCollateral()
     * @param _borrower The address of the Trove
     * @return The borrower's pending accumulated Coll rewards tokens
     * @return The borrower's pending accumulated Coll rewards amounts
     */
    function getPendingCollRewards(address _borrower)
        external
        view
        override
        returns (address[] memory, uint256[] memory)
    {
        newColls memory pendingCollRewards = _getPendingCollRewards(_borrower);
        return (pendingCollRewards.tokens, pendingCollRewards.amounts);
    }

    /**
     * @notice Get the borrower's pending accumulated Coll rewards, earned by their stake
     * @param _borrower The address of the Trove
     * @return pendingCollRewards 
     */
    function _getPendingCollRewards(address _borrower)
        internal
        view
        returns (newColls memory pendingCollRewards)
    {
        if (Troves[_borrower].status != Status.active) {
            newColls memory emptyColls;
            return emptyColls;
        }

        address[] memory allColls = Troves[_borrower].colls.tokens;
        pendingCollRewards.amounts = new uint256[](allColls.length);
        pendingCollRewards.tokens = allColls;
        uint256 allCollsLen = allColls.length;
        for (uint256 i; i < allCollsLen; ++i) {
            address coll = allColls[i];
            uint256 snapshotCollReward = rewardSnapshots[_borrower].CollRewards[coll];
            uint256 rewardPerUnitStaked = L_Coll[coll].sub(snapshotCollReward);
            if (rewardPerUnitStaked == 0) {
                pendingCollRewards.amounts[i] = 0;
                continue;
            }

            uint256 stake = Troves[_borrower].stakes[coll];
            uint256 dec = IERC20(coll).decimals();
            uint256 assetCollReward = stake.mul(rewardPerUnitStaked).div(10**dec);
            pendingCollRewards.amounts[i] = assetCollReward;
        }
    }

    /**
     * @notice : Get the borrower's pending accumulated YUSD reward, earned by their stake
     * @param _borrower The address of the Trove
     */
    function getPendingYUSDDebtReward(address _borrower)
        public
        view
        override
        returns (uint256 pendingYUSDDebtReward)
    {
        if (Troves[_borrower].status != Status.active) {
            return 0;
        }
        address[] memory allColls = Troves[_borrower].colls.tokens;

        uint256 allCollsLen = allColls.length;
        for (uint256 i; i < allCollsLen; ++i) {
            address coll = allColls[i];
            uint256 snapshotYUSDDebt = rewardSnapshots[_borrower].YUSDDebts[coll];
            uint256 rewardPerUnitStaked = L_YUSDDebt[allColls[i]].sub(snapshotYUSDDebt);
            if (rewardPerUnitStaked == 0) {
                continue;
            }

            uint256 stake = Troves[_borrower].stakes[coll];

            uint256 assetYUSDDebtReward = stake.mul(rewardPerUnitStaked).div(DECIMAL_PRECISION);
            pendingYUSDDebtReward = pendingYUSDDebtReward.add(assetYUSDDebtReward);
        }
    }

    /**
     * @notice Checks if borrower has pending rewards
     * @dev A Trove has pending rewards if its snapshot is less than the current rewards per-unit-staked sum:
     * this indicates that rewards have occured since the snapshot was made, and the user therefore has pending rewards
     * @param _borrower The address of the Trove
     * @return True if Trove has pending rewards, False if Trove doesn't have pending rewards
     */
    function hasPendingRewards(address _borrower) public view override returns (bool) {
        if (Troves[_borrower].status != Status.active) {
            return false;
        }
        address[] memory assets = Troves[_borrower].colls.tokens;
        uint256 assetsLen = assets.length;
        for (uint256 i; i < assetsLen; ++i) {
            address token = assets[i];
            if (rewardSnapshots[_borrower].CollRewards[token] < L_Coll[token]) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice Gets the entire debt and collateral of a borrower 
     * @param _borrower The address of the Trove
     * @return debt, collsTokens, collsAmounts, pendingYUSDDebtReward, pendingRewardTokens, pendingRewardAmouns
     */
    function getEntireDebtAndColls(address _borrower)
        public
        view
        override
        returns (
            uint256,
            address[] memory,
            uint256[] memory,
            uint256,
            address[] memory,
            uint256[] memory
        )
    {
        uint256 debt = Troves[_borrower].debt;
        newColls memory colls = Troves[_borrower].colls;

        uint256 pendingYUSDDebtReward = getPendingYUSDDebtReward(_borrower);
        newColls memory pendingCollReward = _getPendingCollRewards(_borrower);

        debt = debt.add(pendingYUSDDebtReward);

        // add in pending rewards to colls
        colls = _sumColls(colls, pendingCollReward);

        return (
            debt,
            colls.tokens,
            colls.amounts,
            pendingYUSDDebtReward,
            pendingCollReward.tokens,
            pendingCollReward.amounts
        );
    }

    /**
     * @notice Borrower operations remove stake sum
     * @param _borrower The address of the Trove 
     */
    function removeStakeAndCloseTrove(address _borrower) external override {
        _requireCallerIsBorrowerOperations();
        _removeStake(_borrower);
        _closeTrove(_borrower, Status.closedByOwner);
    }

    /**
     * @notice Remove borrower's stake from the totalStakes sum, and set their stake to 0
     * @param _borrower The address of the Trove 
     */
    function _removeStake(address _borrower) internal {
        address[] memory borrowerColls = Troves[_borrower].colls.tokens;
        uint256 borrowerCollsLen = borrowerColls.length;
        for (uint256 i; i < borrowerCollsLen; ++i) {
            address coll = borrowerColls[i];
            uint256 stake = Troves[_borrower].stakes[coll];
            totalStakes[coll] = totalStakes[coll].sub(stake);
            Troves[_borrower].stakes[coll] = 0;
        }
    }


    function _updateStakeAndTotalStakes(address _borrower) internal {
        uint256 troveOwnerLen = Troves[_borrower].colls.tokens.length;
        for (uint256 i; i < troveOwnerLen; ++i) {
            address token = Troves[_borrower].colls.tokens[i];
            uint256 amount = Troves[_borrower].colls.amounts[i];

            uint256 newStake = _computeNewStake(token, amount);
            uint256 oldStake = Troves[_borrower].stakes[token];

            Troves[_borrower].stakes[token] = newStake;
            totalStakes[token] = totalStakes[token].sub(oldStake).add(newStake);

            emit TotalStakesUpdated(token, totalStakes[token]);
        }
    }

    /**
     * @notice Calculate a new stake based on the snapshots of the totalStakes and totalCollateral taken at the last liquidation
     * @dev The following assert() holds true because:
        - The system always contains >= 1 trove
        - When we close or liquidate a trove, we redistribute the pending rewards, so if all troves were closed/liquidated,
        rewards would’ve been emptied and totalCollateralSnapshot would be zero too.
     * @param token The token
     * @param _coll The collateral 
     * @return The New stake
     */
    function _computeNewStake(address token, uint256 _coll) internal view returns (uint256) {
        uint256 stake;
        if (totalCollateralSnapshot[token] == 0) {
            stake = _coll;
        } else {
            require(totalStakesSnapshot[token] != 0, "TM: stake must be > 0");
            stake = _coll.mul(totalStakesSnapshot[token]).div(totalCollateralSnapshot[token]);
        }
        return stake;
    }

    /**
     * @notice Add distributed coll and debt rewards-per-unit-staked to the running totals. Division uses a "feedback"
        error correction, to keep the cumulative error low in the running totals L_Coll and L_YUSDDebt:
     * @dev
        This function is only called in batchLiquidateTroves() in TroveManagerLiquidations.
        Debt that cannot be offset from the stability pool has to be redistributed to other troves.
        The collateral that backs this debt also gets redistributed to these troves.


        1) Form numerators which compensate for the floor division errors that occurred the last time this
        2) Calculate "per-unit-staked" ratios.
        3) Multiply each ratio back by its denominator, to reveal the current floor division error.
        4) Store these errors for use in the next correction when this function is called.
        5) Note: static analysis tools complain about this "division before multiplication", however, it is intended.
     */
    function redistributeDebtAndColl(
        IActivePool _activePool,
        IDefaultPool _defaultPool,
        uint256 _debt,
        address[] memory _tokens,
        uint256[] memory _amounts
    ) external override {
        _requireCallerIsTML();
        uint256 tokensLen = _tokens.length;
        require(tokensLen == _amounts.length, "TM: len tokens amounts");
        if (_debt == 0) {
            return;
        }

        uint256 totalCollateralVC = _getVC(_tokens, _amounts); // total collateral value in VC terms
        uint256[] memory collateralsVC = controller.getValuesVCIndividual(_tokens, _amounts); // collaterals in VC terms
        for (uint256 i; i < tokensLen; ++i) {
            address token = _tokens[i];
            uint256 amount = _amounts[i];
            // Prorate debt per collateral by dividing each collateral value by cumulative collateral value and multiply by outstanding debt
            uint256 proratedDebtForCollateral = collateralsVC[i].mul(_debt).div(totalCollateralVC);
            uint256 dec = IERC20(token).decimals();
            uint256 CollNumerator = amount.mul(10**dec).add(lastCollError_Redistribution[token]);
            uint256 YUSDDebtNumerator = proratedDebtForCollateral.mul(DECIMAL_PRECISION).add(
                lastYUSDDebtError_Redistribution[token]
            );
            if (totalStakes[token] != 0) {
                // Get the per-unit-staked terms
                uint256 thisTotalStakes = totalStakes[token];
                uint256 CollRewardPerUnitStaked = CollNumerator.div(thisTotalStakes);
                uint256 YUSDDebtRewardPerUnitStaked = YUSDDebtNumerator.div(
                    thisTotalStakes.mul(10**(18 - dec))
                );

                lastCollError_Redistribution[token] = CollNumerator.sub(
                    CollRewardPerUnitStaked.mul(thisTotalStakes)
                );
                lastYUSDDebtError_Redistribution[token] = YUSDDebtNumerator.sub(
                    YUSDDebtRewardPerUnitStaked.mul(thisTotalStakes.mul(10**(18 - dec)))
                );

                // Add per-unit-staked terms to the running totals
                L_Coll[token] = L_Coll[token].add(CollRewardPerUnitStaked);
                L_YUSDDebt[token] = L_YUSDDebt[token].add(YUSDDebtRewardPerUnitStaked);
                emit LTermsUpdated(token, L_Coll[token], L_YUSDDebt[token]);
            }
        }

        // Transfer coll and debt from ActivePool to DefaultPool
        _activePool.decreaseYUSDDebt(_debt);
        _defaultPool.increaseYUSDDebt(_debt);
        _activePool.sendCollaterals(address(_defaultPool), _tokens, _amounts);
    }

    /**
     * @notice Closes trove by liquidation
     * @param _borrower The address of the Trove
     */
    function closeTroveLiquidation(address _borrower) external override {
        _requireCallerIsTML();
        return _closeTrove(_borrower, Status.closedByLiquidation);
    }

    /**
     * @notice Closes trove by redemption
     * @param _borrower The address of the Trove
     */
    function closeTroveRedemption(address _borrower) external override {
        _requireCallerIsTMR();
        return _closeTrove(_borrower, Status.closedByRedemption);
    }

    function _closeTrove(address _borrower, Status closedStatus) internal {
        require(
            closedStatus != Status.nonExistent && closedStatus != Status.active,
            "Status must be active and exists"
        );
        
        // Remove from liquidatable trove if it was there. 
        sortedTroves.updateLiquidatableTrove(_borrower, false);

        uint256 TroveOwnersArrayLength = TroveOwners.length;
        _requireMoreThanOneTroveInSystem(TroveOwnersArrayLength);
        newColls memory emptyColls;

        // Zero all collaterals owned by the user and snapshots
        address[] memory allColls = Troves[_borrower].colls.tokens;
        uint256 allCollsLen = allColls.length;
        for (uint256 i; i < allCollsLen; ++i) {
            address thisAllColls = allColls[i];
            rewardSnapshots[_borrower].CollRewards[thisAllColls] = 0;
            rewardSnapshots[_borrower].YUSDDebts[thisAllColls] = 0;
        }

        Troves[_borrower].status = closedStatus;
        Troves[_borrower].colls = emptyColls;
        Troves[_borrower].debt = 0;

        _removeTroveOwner(_borrower, TroveOwnersArrayLength);
        sortedTroves.remove(_borrower);
    }

    /**
     * @notice Updates snapshots of system total stakes and total collateral, excluding a given collateral remainder from the calculation. Used in a liquidation sequence.
     * @dev The calculation excludes a portion of collateral that is in the ActivePool:
        the total Coll gas compensation from the liquidation sequence
        The Coll as compensation must be excluded as it is always sent out at the very end of the liquidation sequence.
     */
    function updateSystemSnapshots_excludeCollRemainder(
        IActivePool _activePool,
        address[] memory _tokens,
        uint256[] memory _amounts
    ) external override {
        _requireCallerIsTML();
        uint256 tokensLen = _tokens.length;
        // Collect Active pool + Default pool balances of the passed in tokens and update snapshots accordingly
        uint256[] memory activeAndLiquidatedColl = _activePool.getAmountsSubsetSystem(
            _tokens
        );
        for (uint256 i; i < tokensLen; ++i) {
            address token = _tokens[i];
            totalStakesSnapshot[token] = totalStakes[token];
            totalCollateralSnapshot[token] = activeAndLiquidatedColl[i].sub(_amounts[i]);
        }
        emit SystemSnapshotsUpdated(block.timestamp);
    }

    /**
     * @notice Push the owner's address to the Trove owners list, and record the corresponding array index on the Trove struct
     * @param _borrower The address of the Trove
     * @return Push Trove Owner to array
     */
    function addTroveOwnerToArray(address _borrower) external override returns (uint256) {
        _requireCallerIsBorrowerOperations();
        return _addTroveOwnerToArray(_borrower);
    }

    /**
     * @notice Push the owner's address to the Trove owners list, and record the corresponding array index on the Trove struct
     * @dev Max array size is 2**128 - 1, i.e. ~3e30 troves. No risk of overflow, since troves have minimum YUSD
        debt of liquidation reserve plus MIN_NET_DEBT. 3e30 YUSD dwarfs the value of all wealth in the world ( which is < 1e15 USD).
     * @param _borrower The address of the Trove
     * @return index Push Trove Owner to array
     */
    function _addTroveOwnerToArray(address _borrower) internal returns (uint128 index) {
        TroveOwners.push(_borrower);

        // Record the index of the new Troveowner on their Trove struct
        index = uint128(TroveOwners.length.sub(1));
        Troves[_borrower].arrayIndex = index;
    }

    /**
     * @notice Remove a Trove owner from the TroveOwners array, not preserving array order. 
     * @dev Removing owner 'B' does the following: [A B C D E] => [A E C D], and updates E's Trove struct to point to its new array index.
     * @param _borrower THe address of the Trove
     */
    function _removeTroveOwner(address _borrower, uint256 TroveOwnersArrayLength) internal {
        Status troveStatus = Troves[_borrower].status;
        // It’s set in caller function `_closeTrove`
        require(
            troveStatus != Status.nonExistent && troveStatus != Status.active,
            "TM: trove !exists or !active"
        );

        uint128 index = Troves[_borrower].arrayIndex;
        uint256 length = TroveOwnersArrayLength;
        uint256 idxLast = length.sub(1);

        require(index <= idxLast, "TM: index must be > last index");

        address addressToMove = TroveOwners[idxLast];

        TroveOwners[index] = addressToMove;
        Troves[addressToMove].arrayIndex = index;
        emit TroveIndexUpdated(addressToMove, index);

        TroveOwners.pop();
    }

    // --- Recovery Mode and TCR functions ---

    // @notice Helper function for calculating TCR of the system
    function getTCR() external view override returns (uint256) {
        return _getTCR();
    }

    // @notice Helper function for checking recovery mode
    // @return True if in recovery mode, false otherwise
    function checkRecoveryMode() external view override returns (bool) {
        return _checkRecoveryMode();
    }

    // --- Redemption fee functions ---

    /**
     * @notice Updates base rate via redemption, called from TMR
     * @param newBaseRate The new base rate
     */
    function updateBaseRate(uint256 newBaseRate) external override {
        _requireCallerIsTMR();
        require(newBaseRate != 0, "TM: newBaseRate must be > 0");
        baseRate = newBaseRate;
        emit BaseRateUpdated(newBaseRate);
        _updateLastFeeOpTime();
    }

    function getRedemptionRate() public view override returns (uint256) {
        return _calcRedemptionRate(baseRate);
    }

    function getRedemptionRateWithDecay() public view override returns (uint256) {
        return _calcRedemptionRate(calcDecayedBaseRate());
    }

    function _calcRedemptionRate(uint256 _baseRate) internal pure returns (uint256) {
        return
            YetiMath._min(
                REDEMPTION_FEE_FLOOR.add(_baseRate),
                DECIMAL_PRECISION // cap at a maximum of 100%
            );
    }

    function _getRedemptionFee(uint256 _YUSDRedeemed) internal view returns (uint256) {
        return _calcRedemptionFee(getRedemptionRate(), _YUSDRedeemed);
    }

    function getRedemptionFeeWithDecay(uint256 _YUSDRedeemed)
        external
        view
        override
        returns (uint256)
    {
        return _calcRedemptionFee(getRedemptionRateWithDecay(), _YUSDRedeemed);
    }

    function _calcRedemptionFee(uint256 _redemptionRate, uint256 _YUSDRedeemed)
        internal
        pure
        returns (uint256)
    {
        uint256 redemptionFee = _redemptionRate.mul(_YUSDRedeemed).div(DECIMAL_PRECISION);
        require(redemptionFee < _YUSDRedeemed, "TM:Fee>returned colls");
        return redemptionFee;
    }

    // --- Borrowing fee functions ---

    function getBorrowingRate() public view override returns (uint256) {
        return _calcBorrowingRate(baseRate);
    }

    function getBorrowingRateWithDecay() public view override returns (uint256) {
        return _calcBorrowingRate(calcDecayedBaseRate());
    }

    function _calcBorrowingRate(uint256 _baseRate) internal pure returns (uint256) {
        return YetiMath._min(BORROWING_FEE_FLOOR.add(_baseRate), MAX_BORROWING_FEE);
    }

    function getBorrowingFee(uint256 _YUSDDebt) external view override returns (uint256) {
        return _calcBorrowingFee(getBorrowingRate(), _YUSDDebt);
    }

    function getBorrowingFeeWithDecay(uint256 _YUSDDebt) external view override returns (uint256) {
        return _calcBorrowingFee(getBorrowingRateWithDecay(), _YUSDDebt);
    }

    function _calcBorrowingFee(uint256 _borrowingRate, uint256 _YUSDDebt)
        internal
        pure
        returns (uint256)
    {
        return _borrowingRate.mul(_YUSDDebt).div(DECIMAL_PRECISION);
    }

    // @notice Updates the baseRate state variable based on time elapsed since the last redemption
    // or YUSD borrowing operation
    function decayBaseRateFromBorrowingAndCalculateFee(uint256 _YUSDDebt) external override returns (uint256){
        _requireCallerIsBorrowerOperations();

        uint256 decayedBaseRate = calcDecayedBaseRate();
        require(decayedBaseRate <= DECIMAL_PRECISION, "TM: decayed base rate too small"); // The baseRate can decay to 0

        baseRate = decayedBaseRate;
        emit BaseRateUpdated(decayedBaseRate);

        _updateLastFeeOpTime();
        return _calcBorrowingFee(getBorrowingRate(), _YUSDDebt);
    }

    // --- Internal fee functions ---

    // @notice Update the last fee operation time only if time passed >= decay interval. This prevents base rate griefing.
    function _updateLastFeeOpTime() internal {
        uint256 timePassed = block.timestamp.sub(lastFeeOperationTime);

        if (timePassed >= SECONDS_IN_ONE_MINUTE) {
            lastFeeOperationTime = block.timestamp;
            emit LastFeeOpTimeUpdated(block.timestamp);
        }
    }

    function calcDecayedBaseRate() public view override returns (uint256) {
        uint256 minutesPassed = _minutesPassedSinceLastFeeOp();
        uint256 decayFactor = YetiMath._decPow(MINUTE_DECAY_FACTOR, minutesPassed);

        return baseRate.mul(decayFactor).div(DECIMAL_PRECISION);
    }

    function _minutesPassedSinceLastFeeOp() internal view returns (uint256) {
        return (block.timestamp.sub(lastFeeOperationTime)).div(SECONDS_IN_ONE_MINUTE);
    }

    // --- 'require' wrapper functions ---

    function _requireCallerIsBorrowerOperations() internal view {
        if (msg.sender != borrowerOperationsAddress) {
            _revertWrongFuncCaller();
        }
    }

    function _requireCallerIsBOorTMR() internal view {
        if (
            msg.sender != borrowerOperationsAddress && msg.sender != troveManagerRedemptionsAddress
        ) {
            _revertWrongFuncCaller();
        }
    }

    function _requireCallerIsTMR() internal view {
        if (msg.sender != troveManagerRedemptionsAddress) {
            _revertWrongFuncCaller();
        }
    }

    function _requireCallerIsTML() internal view {
        if (msg.sender != troveManagerLiquidationsAddress) {
            _revertWrongFuncCaller();
        }
    }

    function _requireTroveIsActive(address _borrower) internal view {
        require(Troves[_borrower].status == Status.active, "TM: trove must exist");
    }

    function _requireMoreThanOneTroveInSystem(uint256 TroveOwnersArrayLength) internal view {
        require(TroveOwnersArrayLength > 1 && sortedTroves.getSize() > 1, "TM: last trove");
    }

    // --- Trove property getters ---

    function getTroveStatus(address _borrower) external view override returns (uint256) {
        return uint256(Troves[_borrower].status);
    }

    function isTroveActive(address _borrower) external view override returns (bool) {
        return Troves[_borrower].status == Status.active;
    }

    function getTroveStake(address _borrower, address _token)
        external
        view
        override
        returns (uint256)
    {
        return Troves[_borrower].stakes[_token];
    }

    function getTroveDebt(address _borrower) external view override returns (uint256) {
        return Troves[_borrower].debt;
    }

    // -- Trove Manager State Variable Getters --

    function getTotalStake(address _token) external view override returns (uint256) {
        return totalStakes[_token];
    }

    function getL_Coll(address _token) external view override returns (uint256) {
        return L_Coll[_token];
    }

    function getL_YUSD(address _token) external view override returns (uint256) {
        return L_YUSDDebt[_token];
    }

    function getRewardSnapshotColl(address _borrower, address _token)
        external
        view
        override
        returns (uint256)
    {
        return rewardSnapshots[_borrower].CollRewards[_token];
    }

    function getRewardSnapshotYUSD(address _borrower, address _token)
        external
        view
        override
        returns (uint256)
    {
        return rewardSnapshots[_borrower].YUSDDebts[_token];
    }

    /**
     * @notice recomputes VC given current prices and returns it
     * @param _borrower The address of the Trove
     * @return The Trove's VC
     */
    function getTroveVC(address _borrower) external view override returns (uint256) {
        return _getVCColls(Troves[_borrower].colls);
    }

    function getTroveColls(address _borrower)
        external
        view
        override
        returns (address[] memory, uint256[] memory)
    {
        return (Troves[_borrower].colls.tokens, Troves[_borrower].colls.amounts);
    }

    function getCurrentTroveState(address _borrower)
        external
        view
        override
        returns (
            address[] memory,
            uint256[] memory,
            uint256
        )
    {
        (newColls memory colls, uint256 currentYUSDDebt) = _getCurrentTroveState(_borrower);
        return (colls.tokens, colls.amounts, currentYUSDDebt);
    }

    // --- Called by TroveManagerRedemptions Only ---

    function updateTroveDebt(address _borrower, uint256 debt) external override {
        _requireCallerIsTMR();
        Troves[_borrower].debt = debt;
    }

    function removeStakeTMR(address _borrower) external override {
        _requireCallerIsTMR();
        _removeStake(_borrower);
    }

    // --- Called by TroverManagerLiquidations Only ---

    function removeStakeTML(address _borrower) external override {
        _requireCallerIsTML();
        _removeStake(_borrower);
    }

    // --- Trove property setters, called by BorrowerOperations ---

    function setTroveStatus(address _borrower, uint256 _num) external override {
        _requireCallerIsBorrowerOperations();
        Troves[_borrower].status = Status(_num);
    }

    /**
     * @notice Update borrower's stake based on their latest collateral value. Also update their 
     * trove state with new tokens and amounts. Called by BO or TMR
     * @dev computed at time function is called based on current price of collateral
     * @param _borrower The address of the Trove 
     * @param _tokens The array of tokens to set to the borrower's trove
     * @param _amounts The array of amounts to set to the borrower's trove
     */
    function updateTroveCollAndStakeAndTotalStakes(
        address _borrower,
        address[] memory _tokens,
        uint256[] memory _amounts
    ) external override {
        _requireCallerIsBOorTMR();
        require(_tokens.length == _amounts.length, "TM: length mismatch");
        (Troves[_borrower].colls.tokens, Troves[_borrower].colls.amounts) = (_tokens, _amounts);
        _updateStakeAndTotalStakes(_borrower);
    }

    function increaseTroveDebt(address _borrower, uint256 _debtIncrease)
        external
        override
        returns (uint256)
    {
        _requireCallerIsBorrowerOperations();
        uint256 newDebt = Troves[_borrower].debt.add(_debtIncrease);
        Troves[_borrower].debt = newDebt;
        return newDebt;
    }

    function decreaseTroveDebt(address _borrower, uint256 _debtDecrease)
        external
        override
        returns (uint256)
    {
        _requireCallerIsBorrowerOperations();
        uint256 newDebt = Troves[_borrower].debt.sub(_debtDecrease);
        Troves[_borrower].debt = newDebt;
        return newDebt;
    }

    // --- contract getters ---

    function stabilityPool() external view override returns (IStabilityPool) {
        return stabilityPoolContract;
    }

    function yusdToken() external view override returns (IYUSDToken) {
        return yusdTokenContract;
    }

    function yetiToken() external view override returns (IYETIToken) {
        return yetiTokenContract;
    }

    // --- System param getter functions ---

    function getMCR() external view override returns (uint256) {
        return MCR;
    }

    function getCCR() external view override returns (uint256) {
        return CCR;
    }

    function getYUSD_GAS_COMPENSATION() external view override returns (uint256) {
        return YUSD_GAS_COMPENSATION;
    }

    function getMIN_NET_DEBT() external view override returns (uint256) {
        return MIN_NET_DEBT;
    }

    function getBORROWING_FEE_FLOOR() external view override returns (uint256) {
        return BORROWING_FEE_FLOOR;
    }

    function getREDEMPTION_FEE_FLOOR() external view override returns (uint256) {
        return REDEMPTION_FEE_FLOOR;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "../Interfaces/ISortedTroves.sol";
import "../Dependencies/SafeMath.sol";
import "../Dependencies/Ownable.sol";
import "../Dependencies/CheckContract.sol";
import "../Dependencies/YetiMath.sol";

/**
 * Some notes from Liquity:
 * @notice A sorted doubly linked list with nodes sorted in descending order.
 *
 * Nodes map to active Troves in the system - the ID property is the address of a Trove owner.
 * Nodes are ordered according to their current individual collateral ratio (ICR),
 *
 * The list optionally accepts insert position hints.
 *
 * The list relies on the fact that liquidation events preserve ordering: a liquidation decreases the ICRs of all active Troves,
 * but maintains their order. A node inserted based on current ICR will maintain the correct position,
 * relative to it's peers, as rewards accumulate, as long as it's raw collateral and debt have not changed.
 * Thus, Nodes remain sorted by current ICR.
 *
 * Nodes need only be re-inserted upon a Trove operation - when the owner adds or removes collateral or debt
 * to their position.
 *
 * The list is a modification of the following audited SortedDoublyLinkedList:
 * https://github.com/livepeer/protocol/blob/master/contracts/libraries/SortedDoublyLL.sol
 *
 *
 * Changes made compared to the Liquity implementation:
 *
 * - Keys have been removed from nodes
 *
 * - Ordering checks for insertion are performed by comparing an boostedRICR argument to the current boostedRICR, calculated at runtime.
 *   The list relies on the property that ordering by boostedRICR is maintained as the Coll:USD price varies.
 *
 * - Public functions with parameters have been made internal to save gas, and given an external wrapper function for external access
 *
 * Changes made in Yeti Finance implementation:
 * Since the nodes are no longer just reliant on the nominal ICR which is just amount of ETH / debt, we now have to use the boostedRICR based
 * on the RVC + boost value of the node. This changes with any price change, as the composition of any trove does not stay constant. Therefore
 * the list can easily become stale. This is a compromise that we had to make due to it being too expensive gas wise to keep the list
 * actually sorted by current boostedRICR, as this can change each block. Instead, we keep it ordered by oldBoostedRICR, and it is instead updated through
 * an external function in TroveManager.sol, updateTroves(), and can be called by anyone. This will essentially just update the oldBoostedRICR and re-insert it
 * into the list. It always remains sorted by oldBoostedRICR. To then perform redemptions properly, we just allow redemptions to occur for any
 * trove in order of the stale list. However, the redemption amount is in dollar terms so people will always still keep their value, just
 * will lose exposure to the asset.
 *
 * RICR is defined as the Recovery ICR, which is the sum(collaterals * recovery ratio) / total debt
 * Boosted RICR is defined as the RICR + Boost. (Boost defined below)
 * This list is sorted by boostedRICR so that redemptions take from troves which have a relatively lower recovery ratio adjusted ratio. If we sorted
 * by ICR, then the redemptions would always take from the lowest but actually relatively safe troves, such as the ones with purely
 * stablecoin collateral. Since more resistant troves will have higher boostedRICR, this will make them less likely to be redeemed against.
 *
 * Boost is defined as the extra factor added to the RICR. In order to avoid users paying large fees due to extra leverage and then immediately
 * getting redeemed, they gain an additional factor which is added to the RICR. Depending on the fee % * leverage, and the global boost factor,
 * they will have a decayed additional boost. This decays according to the boostMinuteDecayFactor, which by default has a half life of 5 days.
 *
 * SortedTroves is also used to check if there is a trove eligible for liquidation for SP Withdrawal. Technically it can be the case
 * that there is a liquidatable trove which has boostedRICR > 110%, and since it is sorted by boostedRICR it may not be at the bottom.
 * However, this is inherently because these assets are deemed safer, so it is unlikely that there will be a liquidatable trove with
 * boostedRICR > 110% and no troves without a high boostedRICR which are also not liquidatable. If the collateral dropped in value while being
 * hedged with some stablecoins in the trove as well, it is likely that there is another liquidatable trove.
 *
 * As an additional countermeasure, we are adding a liquidatable troves list. This list is intended to keep track of if there are any
 * liquidatable troves in the event of a large usage and gas spike. Since the list is sorted by boostedRICR, it is possible that there are
 * liquidatable troves which are not at the bottom, while the bottom of the list is a trove which has a boostedRICR > 110%. So, this list exists
 * to not break the invariant for knowing if there is a liquidatable trove in order to perform a SP withdrawal. It will be updated by
 * external callers and if the ICR calculated is < 110%, then it will be added to the list. There will be another external function to
 * remove it from the list. Yeti Finance bots will be performing the updating, and since SP withdrawal is the only action that is dependant
 * on this, it is not a problem if it is slow or lagged to clear the list entirely. The SP Withdrawal function will just check the length
 * of the LiquidatableTroves list and see if it is more than 0.
 */

contract SortedTroves is Ownable, CheckContract, ISortedTroves {
    using SafeMath for uint256;

    bytes32 public constant NAME = "SortedTroves";
    uint256 internal constant DECIMAL_PRECISION = 1e18;

    event NodeAdded(address _id, uint256 _RICR);
    event NodeRemoved(address _id);
    event LiquidatableTroveAdded(address _id);
    event LiquidatableTroveRemoved(address _id);

    address internal borrowerOperationsAddress;
    address internal troveManagerRedemptionsAddress;
    address internal troveManagerAddress;
    address internal controllerAddress;

    // Initiallly 0 and can be set further through controller.
    // Multiplied by passed in fee factors to scale the fee percentage.
    uint256 public globalBoostFactor;

    /*
     * Half-life of 5d = 120h. 120h = 7200 min
     * (1/2) = d^7200 => d = (1/2)^(1/7200)
     * d is equal to boostMinuteDecayFactor
     */
    uint256 public boostMinuteDecayFactor = 999903734192105837;

    // Information for a node in the list
    struct Node {
        bool exists;
        address nextId; // Id of next node (smaller boostedRICR) in the list
        address prevId; // Id of previous node (larger boostedRICR) in the list
        uint256 oldBoostedRICR; // boostedRICR of the node last time it was updated. List is always in order
        // in terms of oldBoostedRICR .
        uint256 boost; // Boost factor which was previously added to the boostedRICR when inserted
        uint256 timeSinceBoostUpdated; // Time since the boost factor was last updated
    }

    // Information for the list
    struct Data {
        address head; // Head of the list. Also the node in the list with the largest boostedRICR
        address tail; // Tail of the list. Also the node in the list with the smallest boostedRICR
        uint256 maxSize; // Maximum size of the list
        uint256 size; // Current size of the list
        mapping(address => Node) nodes; // Track the corresponding ids for each node in the list
    }

    Data public data;

    mapping(address => bool) public liquidatableTroves;
    uint256 public liquidatableTrovesSize;

    // --- Dependency setters ---

    function setParams(
        uint256 _size,
        address _troveManagerAddress,
        address _borrowerOperationsAddress,
        address _troveManagerRedemptionsAddress,
        address _yetiControllerAddress
    ) external override onlyOwner {
        require(_size != 0, "SortedTroves: Size can't be zero");
        checkContract(_troveManagerAddress);
        checkContract(_borrowerOperationsAddress);
        checkContract(_troveManagerRedemptionsAddress);
        checkContract(_yetiControllerAddress);

        data.maxSize = _size;

        troveManagerAddress = _troveManagerAddress;
        borrowerOperationsAddress = _borrowerOperationsAddress;
        troveManagerRedemptionsAddress = _troveManagerRedemptionsAddress;
        controllerAddress = _yetiControllerAddress;

        _renounceOwnership();
    }

    // --- Functions relating to insertion, deletion, reinsertion ---

    /**
     * @notice Add a node to the list
     * @param _id Node's id
     * @param _RICR Node's _RICR at time of inserting
     * @param _prevId Id of previous node for the insert position
     * @param _nextId Id of next node for the insert position
     * @param _feeAsPercentOfTotal The fee as a percentage of the total VC in when inserting a new trove.
     */
    function insert(
        address _id,
        uint256 _RICR,
        address _prevId,
        address _nextId,
        uint256 _feeAsPercentOfTotal
    ) external override {
        _requireCallerIsBO();
        // Calculate new boost amount using fee as percent of total, with global boost factor.
        uint256 newBoostAmount = (
            _feeAsPercentOfTotal.mul(globalBoostFactor).div(DECIMAL_PRECISION)
        );
        _insert(_id, _RICR, _prevId, _nextId, newBoostAmount);
    }

    /**
     * @notice Add a node to the list, which may or may not have just been removed.
     * @param _id Node's id
     * @param _RICR Node's _RICR at time of inserting
     * @param _prevId Id of previous node for the insert position
     * @param _nextId Id of next node for the insert position
     * @param _newBoostAmount Boost amount which has been calculated with previous data or is
     *   completely new, depending on whether it is a reinsert or not. It will be used as the boost
     *   param for the node reinsertion.
     */
    function _insert(
        address _id,
        uint256 _RICR,
        address _prevId,
        address _nextId,
        uint256 _newBoostAmount
    ) internal {
        // List must not be full
        require(!isFull(), "SortedTroves: List is full");
        // List must not already contain node
        require(!contains(_id), "SortedTroves: duplicate node");
        // Node id must not be null
        require(_id != address(0), "SortedTroves: Id cannot be zero");
        // RICR must be non-zero
        require(_RICR != 0, "SortedTroves: RICR must be (+)");

        // Calculate boostedRICR as RICR + decayed boost
        uint256 boostedRICR = _RICR.add(_newBoostAmount);
        address prevId = _prevId;
        address nextId = _nextId;
        if (!_validInsertPosition(boostedRICR, prevId, nextId)) {
            // Sender's hint was not a valid insert position
            // Use sender's hint to find a valid insert position
            (prevId, nextId) = _findInsertPosition(boostedRICR, prevId, nextId);
        }

        data.nodes[_id].exists = true;
        if (prevId == address(0) && nextId == address(0)) {
            // Insert as head and tail
            data.head = _id;
            data.tail = _id;
        } else if (prevId == address(0)) {
            // Insert before `prevId` as the head
            data.nodes[_id].nextId = data.head;
            data.nodes[data.head].prevId = _id;
            data.head = _id;
        } else if (nextId == address(0)) {
            // Insert after `nextId` as the tail
            data.nodes[_id].prevId = data.tail;
            data.nodes[data.tail].nextId = _id;
            data.tail = _id;
        } else {
            // Insert at insert position between `prevId` and `nextId`
            data.nodes[_id].nextId = nextId;
            data.nodes[_id].prevId = prevId;
            data.nodes[prevId].nextId = _id;
            data.nodes[nextId].prevId = _id;
        }

        // Update node's boostedRICR
        data.nodes[_id].oldBoostedRICR = boostedRICR;
        data.nodes[_id].boost = _newBoostAmount;
        data.nodes[_id].timeSinceBoostUpdated = block.timestamp;

        data.size = data.size.add(1);
        emit NodeAdded(_id, boostedRICR);
    }

    /**
     * @notice Remove a node to the list. Used when purely removing or when reinserting.
     * @param _id Node's id
     */
    function remove(address _id) external override {
        _requireCallerIsTroveManager();
        _remove(_id);
    }

    /**
     * @notice Remove a node from the list. Used when purely removing or when reinserting.
     * @param _id Node's id
     */
    function _remove(address _id) internal {
        // List must contain the node
        require(contains(_id), "SortedTroves: Id not found");

        if (data.size > 1) {
            // List contains more than a single node
            if (_id == data.head) {
                // The removed node is the head
                // Set head to next node
                data.head = data.nodes[_id].nextId;
                // Set prev pointer of new head to null
                data.nodes[data.head].prevId = address(0);
            } else if (_id == data.tail) {
                // The removed node is the tail
                // Set tail to previous node
                data.tail = data.nodes[_id].prevId;
                // Set next pointer of new tail to null
                data.nodes[data.tail].nextId = address(0);
            } else {
                // The removed node is neither the head nor the tail
                // Set next pointer of previous node to the next node
                data.nodes[data.nodes[_id].prevId].nextId = data.nodes[_id].nextId;
                // Set prev pointer of next node to the previous node
                data.nodes[data.nodes[_id].nextId].prevId = data.nodes[_id].prevId;
            }
        } else {
            // List contains a single node
            // Set the head and tail to null
            data.head = address(0);
            data.tail = address(0);
        }

        delete data.nodes[_id];
        data.size = data.size.sub(1);
        emit NodeRemoved(_id);
    }

    /**
     * @notice Re-insert the node at a new position, based on its new boostedRICR
     * @dev Does not add additional boost and is called by redemption reinsertion. Only decays the existing boost.
     * @param _id Node's id
     * @param _newRICR Node's new RICR
     * @param _prevId Id of previous node for the new insert position
     * @param _nextId Id of next node for the new insert position
     */
    function reInsert(
        address _id,
        uint256 _newRICR,
        address _prevId,
        address _nextId
    ) external override {
        _requireCallerIsTM();
        _reInsert(_id, _newRICR, _prevId, _nextId);
    }

    /**
     * @notice Re-insert the node at a new position, based on its new boostedRICR
     * @dev Does not add additional boost and is called by redemption reinsertion, or TM manual reinsertion.
     *   Only decays the existing boost.
     * @param _id Node's id
     * @param _newRICR Node's new RICR
     * @param _prevId Id of previous node for the new insert position
     * @param _nextId Id of next node for the new insert position
     */
    function _reInsert(
        address _id,
        uint256 _newRICR,
        address _prevId,
        address _nextId
    ) internal {
        // List must contain the node
        require(contains(_id), "SortedTroves: Id not found");
        // RICR must be non-zero
        require(_newRICR != 0, "SortedTroves: RICR != 0");

        // Does not add additional boost and is called by redemption reinsertion. Only decays the existing boost.
        uint256 decayedLastBoost = _calculateDecayedBoost(
            data.nodes[_id].boost,
            data.nodes[_id].timeSinceBoostUpdated
        );
        // Remove node from the list
        _remove(_id);

        _insert(_id, _newRICR, _prevId, _nextId, decayedLastBoost);
    }

    /**
     * @notice Reinserts the trove in adjustTrove with and weight the new boost factor with the old boost and VC calculation
     * @param _id Node's id
     * @param _newRICR Node's new RICR with old VC + new VC In - new VC out
     * @param _prevId Id of previous node for the new insert position
     * @param _nextId Id of next node for the new insert position
     * @param _feeAsPercentOfAddedVC Fee as percent of the VC added in this tx
     * @param _addedVCIn amount VC added in this tx
     * @param _VCBeforeAdjustment amount VC before this tx, what to scale the old decayed boost by
     */
    function reInsertWithNewBoost(
        address _id,
        uint256 _newRICR,
        address _prevId,
        address _nextId,
        uint256 _feeAsPercentOfAddedVC,
        uint256 _addedVCIn,
        uint256 _VCBeforeAdjustment
    ) external override {
        _requireCallerIsBO();
        // List must contain the node
        require(contains(_id), "SortedTroves: Id not found");
        // RICR must be non-zero
        require(_newRICR != 0, "SortedTroves: RICR != 0");

        // Calculate decayed last boost based on previous trove information.
        uint256 decayedLastBoost = _calculateDecayedBoost(
            data.nodes[_id].boost,
            data.nodes[_id].timeSinceBoostUpdated
        );
        // Remove node from the list
        _remove(_id);

        // Weight new deposit compared to old boost deposit amount.
        // (OldBoost * Previous VC) + (NewBoost * Added VC)
        // divided by new VC
        uint256 newBoostFactor = _feeAsPercentOfAddedVC.mul(globalBoostFactor).div(
            DECIMAL_PRECISION
        );
        uint256 newBoostAmount = (
            decayedLastBoost.mul(_VCBeforeAdjustment).add(newBoostFactor.mul(_addedVCIn))
        ).div(_VCBeforeAdjustment.add(_addedVCIn));

        _insert(_id, _newRICR, _prevId, _nextId, newBoostAmount);
    }

    /**
     * @notice Re-insert the node at a new position, based on its new boostedRICR
     * @param _ids IDs to reinsert
     * @param _newRICRs new RICRs for all IDs
     * @param _prevIds Ids of previous node for the new insert position
     * @param _nextIds Ids of next node for the new insert position
     */
    function reInsertMany(
        address[] memory _ids,
        uint256[] memory _newRICRs,
        address[] memory _prevIds,
        address[] memory _nextIds
    ) external override {
        _requireCallerIsTM();
        uint256 _idsLength = _ids.length;
        for (uint256 i; i < _idsLength; ++i) {
            _reInsert(_ids[i], _newRICRs[i], _prevIds[i], _nextIds[i]);
        }
    }

    /**
     * @notice Decays the boost based on last time updated, based on boost minute decay factor
     * @param _originalBoost Boost which has not been decayed stored at last time of update
     * @param _timeSinceBoostUpdated Time since last time boost was updated
     */
    function _calculateDecayedBoost(uint256 _originalBoost, uint256 _timeSinceBoostUpdated)
        internal
        view
        returns (uint256)
    {
        uint256 minutesPassed = (block.timestamp.sub(_timeSinceBoostUpdated)).div(60); // Div by 60 to convert to minutes
        uint256 decayFactor = YetiMath._decPow(boostMinuteDecayFactor, minutesPassed);
        return _originalBoost.mul(decayFactor).div(DECIMAL_PRECISION);
    }

    // --- Liquidatable Troves Functions ---

    /**
     * @notice Update a particular trove address in the liquidatable troves list
     * @dev This function is called by the UpdateTroves bot and if a trove is liquidatable but the gas is too congested to liquidated, then
     * this will add it to the list so that no SP withdrawal can happen. If the trove is no longer liquidatable then this function will remove
     * it from the list.
     * @param _id Trove's id
     * @param _isLiquidatable True if the trove is liquidatable, using ICR calculated from the call from TM
     */
    function updateLiquidatableTrove(address _id, bool _isLiquidatable) external override {
        _requireCallerIsTroveManager();
        require(contains(_id), "SortedTroves: Id not found");
        if (_isLiquidatable) {
            // If liquidatable and marked not liquidatable, add to list
            if (!liquidatableTroves[_id]) {
                _insertLiquidatableTrove(_id);
            }
        } else {
            // If not liquidatable and marked liquidatable, remove from list
            if (liquidatableTroves[_id]) {
                _removeLiquidatableTrove(_id);
            }
        }
    }

    /**
     * @notice Add a node to the liquidatable troves list and increase the size
     */
    function _insertLiquidatableTrove(address _id) internal {
        liquidatableTrovesSize = liquidatableTrovesSize.add(1);
        liquidatableTroves[_id] = true;
        emit LiquidatableTroveAdded(_id);
    }

    /**
     * @notice Remove a node to the liquidatable troves list and increase the size
     */
    function _removeLiquidatableTrove(address _id) internal {
        liquidatableTrovesSize = liquidatableTrovesSize.sub(1);
        liquidatableTroves[_id] = false;
        emit LiquidatableTroveRemoved(_id);
    }

    // --- Functions relating to finding insert position ---

    /**
     * @notice Check if a pair of nodes is a valid insertion point for a new node with the given boostedRICR
     * @param _boostedRICR Node's boostedRICR
     * @param _prevId Id of previous node for the insert position
     * @param _nextId Id of next node for the insert position
     * @return True if insert positon is valid, False if insert position is not valid
     */
    function validInsertPosition(
        uint256 _boostedRICR,
        address _prevId,
        address _nextId
    ) external view override returns (bool) {
        return _validInsertPosition(_boostedRICR, _prevId, _nextId);
    }

    /**
     * @notice Check if a pair of nodes is a valid insertion point for a new node with the given boosted RICR
     * @dev Instead of calculating current boosted RICR using trove manager, we use oldBoostedRICR values.
     * @param _prevId Id of previous node for the insert position
     * @param _nextId Id of next node for the insert position
     */
    function _validInsertPosition(
        uint256 _boostedRICR,
        address _prevId,
        address _nextId
    ) internal view returns (bool) {
        if (_prevId == address(0) && _nextId == address(0)) {
            // `(null, null)` is a valid insert position if the list is empty
            return isEmpty();
        } else if (_prevId == address(0)) {
            // `(null, _nextId)` is a valid insert position if `_nextId` is the head of the list
            return data.head == _nextId && _boostedRICR >= data.nodes[_nextId].oldBoostedRICR;
        } else if (_nextId == address(0)) {
            // `(_prevId, null)` is a valid insert position if `_prevId` is the tail of the list
            return data.tail == _prevId && _boostedRICR <= data.nodes[_prevId].oldBoostedRICR;
        } else {
            // `(_prevId, _nextId)` is a valid insert position if they are adjacent nodes and `_boostedRICR` falls between the two nodes' RICRs
            return
                data.nodes[_prevId].nextId == _nextId &&
                data.nodes[_prevId].oldBoostedRICR >= _boostedRICR &&
                _boostedRICR >= data.nodes[_nextId].oldBoostedRICR;
        }
    }

    /**
     * @notice Descend the list (larger RICRs to smaller RICRs) to find a valid insert position
     * @param _boostedRICR Node's boostedRICR
     * @param _startId Id of node to start descending the list from
     */
    function _descendList(uint256 _boostedRICR, address _startId)
        internal
        view
        returns (address, address)
    {
        // If `_startId` is the head, check if the insert position is before the head
        if (data.head == _startId && _boostedRICR >= data.nodes[_startId].oldBoostedRICR) {
            return (address(0), _startId);
        }

        address prevId = _startId;
        address nextId = data.nodes[prevId].nextId;

        // Descend the list until we reach the end or until we find a valid insert position
        while (prevId != address(0) && !_validInsertPosition(_boostedRICR, prevId, nextId)) {
            prevId = data.nodes[prevId].nextId;
            nextId = data.nodes[prevId].nextId;
        }

        return (prevId, nextId);
    }

    /**
     * @notice Ascend the list (smaller RICRs to larger RICRs) to find a valid insert position
     * @param _boostedRICR Node's boosted RICR
     * @param _startId Id of node to start ascending the list from
     */
    function _ascendList(uint256 _boostedRICR, address _startId)
        internal
        view
        returns (address, address)
    {
        // If `_startId` is the tail, check if the insert position is after the tail
        if (data.tail == _startId && _boostedRICR <= data.nodes[_startId].oldBoostedRICR) {
            return (_startId, address(0));
        }

        address nextId = _startId;
        address prevId = data.nodes[nextId].prevId;

        // Ascend the list until we reach the end or until we find a valid insertion point
        while (nextId != address(0) && !_validInsertPosition(_boostedRICR, prevId, nextId)) {
            nextId = data.nodes[nextId].prevId;
            prevId = data.nodes[nextId].prevId;
        }

        return (prevId, nextId);
    }

    /**
     * @notice Find the insert position for a new node with the given boosted RICR
     * @param _boostedRICR Node's boostedRICR
     * @param _prevId Id of previous node for the insert position
     * @param _nextId Id of next node for the insert position
     */
    function findInsertPosition(
        uint256 _boostedRICR,
        address _prevId,
        address _nextId
    ) external view override returns (address, address) {
        return _findInsertPosition(_boostedRICR, _prevId, _nextId);
    }

    function _findInsertPosition(
        uint256 _boostedRICR,
        address _prevId,
        address _nextId
    ) internal view returns (address, address) {
        address prevId = _prevId;
        address nextId = _nextId;

        if (prevId != address(0)) {
            if (!contains(prevId) || _boostedRICR > data.nodes[prevId].oldBoostedRICR) {
                // `prevId` does not exist anymore or now has a smaller boosted RICR than the given boosted RICR
                prevId = address(0);
            }
        }

        if (nextId != address(0)) {
            if (!contains(nextId) || _boostedRICR < data.nodes[nextId].oldBoostedRICR) {
                // `nextId` does not exist anymore or now has a larger boosted RICR than the given boosted RICR
                nextId = address(0);
            }
        }

        if (prevId == address(0) && nextId == address(0)) {
            // No hint - descend list starting from head
            return _descendList(_boostedRICR, data.head);
        } else if (prevId == address(0)) {
            // No `prevId` for hint - ascend list starting from `nextId`
            return _ascendList(_boostedRICR, nextId);
        } else if (nextId == address(0)) {
            // No `nextId` for hint - descend list starting from `prevId`
            return _descendList(_boostedRICR, prevId);
        } else {
            // Descend list starting from `prevId`
            return _descendList(_boostedRICR, prevId);
        }
    }

    /**
     * @notice change the boost minute decay factor from the controller timelock.
     *   Half-life of 5d = 120h. 120h = 7200 min
     *   (1/2) = d^7200 => d = (1/2)^(1/7200)
     *   d is equal to boostMinuteDecayFactor
     */
    function changeBoostMinuteDecayFactor(uint256 _newBoostMinuteDecayFactor) external override {
        _requireCallerIsYetiController();
        boostMinuteDecayFactor = _newBoostMinuteDecayFactor;
    }

    /**
     * @notice change the global boost multiplier from the controller timelock.
     *   Initiallly 0 and can be set further through controller.
     *   Multiplied by passed in fee factors to scale the fee percentage
     */
    function changeGlobalBoostMultiplier(uint256 _newGlobalBoostMultiplier) external override {
        _requireCallerIsYetiController();
        globalBoostFactor = _newGlobalBoostMultiplier;
    }

    // --- Getter functions ---

    /**
     * @notice Checks if the list contains a node
     */
    function contains(address _id) public view override returns (bool) {
        return data.nodes[_id].exists;
    }

    /**
     * @notice Checks if list is full
     */
    function isFull() public view override returns (bool) {
        return data.size == data.maxSize;
    }

    /**
     * @notice Checks if list is empty
     */
    function isEmpty() public view override returns (bool) {
        return data.size == 0;
    }

    /**
     * @notice Returns the current size of the list
     */
    function getSize() external view override returns (uint256) {
        return data.size;
    }

    /**
     * @notice Returns the maximum size of the list
     */
    function getMaxSize() external view override returns (uint256) {
        return data.maxSize;
    }

    /**
     * @notice Returns the node data in the list
     * @dev First node is node with the largest boostedRICR
     */
    function getNode(address _id) external view override returns (bool, address, address, uint256, uint256, uint256) {
        Node memory node = data.nodes[_id];
        return (node.exists, node.nextId, node.prevId, node.oldBoostedRICR, node.boost, node.timeSinceBoostUpdated);
    }

    /**
     * @notice Returns the first node in the list
     * @dev First node is node with the largest boostedRICR
     */
    function getFirst() external view override returns (address) {
        return data.head;
    }

    /**
     * @notice Returns the last node in the list
     * @dev First node is node with the smallest boostedRICR
     */
    function getLast() external view override returns (address) {
        return data.tail;
    }

    /**
     * @notice Returns the next node (with a smaller boostedRICR) in the list for a given node
     * @param _id Node's id
     */
    function getNext(address _id) external view override returns (address) {
        return data.nodes[_id].nextId;
    }

    /**
     * @notice Returns the previous node (with a larger boostedRICR) in the list for a given node
     * @param _id Node's id
     */
    function getPrev(address _id) external view override returns (address) {
        return data.nodes[_id].prevId;
    }

    /**
     * @notice Get the stale boostedRICR of a node
     * @param _id Node's id
     */
    function getOldBoostedRICR(address _id) external view override returns (uint256) {
        return data.nodes[_id].oldBoostedRICR;
    }

    /**
     * @notice Get the timeSinceBoostUpdated of a node
     * @param _id Node's id
     */
    function getTimeSinceBoostUpdated(address _id) external view override returns (uint256) {
        return data.nodes[_id].timeSinceBoostUpdated;
    }

    /**
     * @notice Get the current boost of a node
     * @param _id Node's id
     */
    function getBoost(address _id) external view override returns (uint256) {
        return data.nodes[_id].boost;
    }

    /**
     * @notice Get the decayed boost of a node since time last updated
     * @param _id Node's id
     */
    function getDecayedBoost(address _id) external view override returns (uint256) {
        return _calculateDecayedBoost(data.nodes[_id].boost, data.nodes[_id].timeSinceBoostUpdated);
    }

    /**
     * @notice get the size of liquidatable troves list.
     * @dev if != 0 then not allowed to withdraw from SP.
     */
    function getLiquidatableTrovesSize() external view override returns (uint256) {
        return liquidatableTrovesSize;
    }

    // --- 'require' functions ---

    function _requireCallerIsTroveManager() internal view {
        if (msg.sender != troveManagerAddress) {
            _revertWrongFuncCaller();
        }
    }

    function _requireCallerIsYetiController() internal view {
        if (msg.sender != controllerAddress) {
            _revertWrongFuncCaller();
        }
    }

    function _requireCallerIsBO() internal view {
        if (msg.sender != borrowerOperationsAddress) {
            _revertWrongFuncCaller();
        }
    }

    function _requireCallerIsTM() internal view {
        if (msg.sender != troveManagerAddress && msg.sender != troveManagerRedemptionsAddress) {
            _revertWrongFuncCaller();
        }
    }

    function _revertWrongFuncCaller() internal pure {
        revert("ST: External caller not allowed");
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "../Interfaces/IBaseOracle.sol";
import "../Interfaces/IYetiController.sol";
import "../Interfaces/IPriceFeed.sol";
import "../Interfaces/IFeeCurve.sol";
import "../Interfaces/IActivePool.sol";
import "../Interfaces/IDefaultPool.sol";
import "../Interfaces/IStabilityPool.sol";
import "../Interfaces/ISortedTroves.sol";
import "../Interfaces/ICollSurplusPool.sol";
import "../Interfaces/IERC20.sol";
import "../Interfaces/IYUSDToken.sol";
import "../Interfaces/IveYETI.sol";
import "../Dependencies/Ownable.sol";
import "../Dependencies/YetiMath.sol";
import "../Dependencies/CheckContract.sol";

/**
 * YetiController is the contract that controls system parameters.
 * This includes things like enabling leverUp, feeBootstrap, and pausing the system.
 * YetiController also keeps track of all collateral parameters and allos
 * the team to update these. This includes: change the fee
 * curve, price feed, safety ratio, recovery ratio etc. as well
 * as adding or deprecating new collaterals. Some parameter changes
 * can be executed instantly, while others can only be updated by certain
 * Timelock contracts to ensure the communtiy has a fair warning before updates.
 * YetiController also has view functions to get
 * prices and VC, and RVC values.
 */

contract YetiController is Ownable, IYetiController, IBaseOracle, CheckContract {
    using SafeMath for uint256;

    struct CollateralParams {
        // Ratios: 10**18 * the ratio. i.e. ratio = 95E16 for 95%.
        // More risky collateral has a lower ratio
        uint256 safetyRatio;
        // Ratio used for recovery mode for the TCR as well as trove ordering in SortedTroves
        uint256 recoveryRatio;
        address oracle;
        uint256 decimals;
        address feeCurve;
        uint256 index;
        address defaultRouter;
        bool active;
        bool isWrapped;
    }

    struct DepositFeeCalc {
        // Cauclated fee for that collateral local variable  
        uint256 collateralYUSDFee;
        // VC value of collateral of that type in the system, from AP and DP balances. 
        uint256[] systemCollateralVCs;
        // VC value of collateral of this type inputted
        uint256 collateralInputVC;
        // collateral we are dealing with 
        address token;
        // active pool total VC post adding and removing all collaterals
        // This transaction adds VCin which is the sum of all collaterals added in from adjust trove or 
        // open trove and VCout which is the sum of all collaterals withdrawn from adjust trove. 
        uint256 activePoolVCPost;
    }

    IActivePool private activePool;
    IDefaultPool private defaultPool;
    IStabilityPool private stabilityPool;
    ICollSurplusPool private collSurplusPool;
    IYUSDToken private yusdToken;
    ISortedTroves private sortedTroves;
    IveYETI private veYETI;
    address private YUSDFeeRecipient;
    address private borrowerOperationsAddress;
    address private yetiFinanceTreasury;
    uint256 private yetiFinanceTreasurySplit = 2e17;
    uint256 private redemptionBorrowerFeeSplit = 2e17;
    bool private addressesSet;
    bool private isLeverUpEnabled;
    bool feeBoostrapPeriodEnabled = true;
    uint256 maxCollsInTrove = 50; // TODO: update to a reasonable number

    address oneWeekTimelock;
    address twoWeekTimelock;

    mapping(address => CollateralParams) public collateralParams;
    // list of all collateral types in collateralParams (active and deprecated)
    // Addresses for easy access
    address[] public validCollateral; // index maps to token address.

    event CollateralAdded(address _collateral);
    event CollateralDeprecated(address _collateral);
    event CollateralUndeprecated(address _collateral);
    event OracleChanged(address _collateral, address _newOracle);
    event FeeCurveChanged(address _collateral, address _newFeeCurve);
    event SafetyRatioChanged(address _collateral, uint256 _newSafetyRatio);
    event RecoveryRatioChanged(address _collateral, uint256 _newRecoveryRatio);

    // ======== Events for timelocked functions ========
    event LeverUpChanged(bool _enabled);
    event FeeBootstrapPeriodEnabledChanged(bool _enabled);
    event GlobalYUSDMintOn(bool _canMint);
    event YUSDMinterChanged(address _minter, bool _canMint);
    event DefaultRouterChanged(address _collateral, address _newDefaultRouter);
    event YetiFinanceTreasuryChanged(address _newTreasury);
    event YetiFinanceTreasurySplitChanged(uint256 _newSplit);
    event RedemptionBorrowerFeeSplitChanged(uint256 _newSplit);
    event YUSDFeeRecipientChanged(address _newFeeRecipient);
    event GlobalBoostMultiplierChanged(uint256 _newGlobalBoostMultiplier);
    event BoostMinuteDecayFactorChanged(uint256 _newBoostMinuteDecayFactor);
    event MaxCollsInTroveChanged(uint256 _newMaxCollsInTrove);
    event NewVeYetiAccumulationRate(uint256 _newAR);

    // Require that the collateral exists in the controller. If it is not the 0th index, and the
    // index is still 0 then it does not exist in the mapping.
    // no require here for valid collateral 0 index because that means it exists.
    modifier exists(address _collateral) {
        _exists(_collateral);
        _;
    }

    // Calling from here makes it not inline, reducing contract size significantly.
    function _exists(address _collateral) internal view {
        if (validCollateral[0] != _collateral) {
            require(collateralParams[_collateral].index != 0, "collateral does not exist");
        }
    }

    // ======== Timelock modifiers ========

    modifier onlyOneWeekTimelock() {
        require(msg.sender == oneWeekTimelock, "Caller Not One Week Timelock");
        _;
    }

    modifier onlyTwoWeekTimelock() {
        require(msg.sender == twoWeekTimelock, "Caller Not Two Week Timelock");
        _;
    }

    // ======== Mutable Only Owner-Instantaneous ========

    function setAddresses(
        address _activePoolAddress,
        address _defaultPoolAddress,
        address _stabilityPoolAddress,
        address _collSurplusPoolAddress,
        address _borrowerOperationsAddress,
        address _yusdTokenAddress,
        address _sYETITokenAddress,
        address _yetiFinanceTreasury,
        address _sortedTrovesAddress,
        address _veYETIAddress,
        address _oneWeekTimelock,
        address _twoWeekTimelock
    ) external override onlyOwner {
        require(!addressesSet, "addresses already set");

        activePool = IActivePool(_activePoolAddress);
        defaultPool = IDefaultPool(_defaultPoolAddress);
        stabilityPool = IStabilityPool(_stabilityPoolAddress);
        collSurplusPool = ICollSurplusPool(_collSurplusPoolAddress);
        yusdToken = IYUSDToken(_yusdTokenAddress);
        checkContract(_sYETITokenAddress);
        YUSDFeeRecipient = _sYETITokenAddress;
        checkContract(_borrowerOperationsAddress);
        borrowerOperationsAddress = _borrowerOperationsAddress;
        yetiFinanceTreasury = _yetiFinanceTreasury;
        sortedTroves = ISortedTroves(_sortedTrovesAddress);
        veYETI = IveYETI(_veYETIAddress);
        oneWeekTimelock = _oneWeekTimelock;
        twoWeekTimelock = _twoWeekTimelock;
        addressesSet = true;
    }

    /**
     * Can be used to quickly shut down new collateral from entering
     * Yeti in the event of a potential hack.
     */
    function deprecateAllCollateral() external override onlyOwner {
        uint256 len = validCollateral.length;
        for (uint256 i; i < len; i++) {
            address collateral = validCollateral[i];
            if (collateralParams[collateral].active) {
                _deprecateCollateral(collateral);
            }
        }
    }

    /**
     * Deprecate collateral by not allowing any more collateral to be added of this type.
     * Still can interact with it via validCollateral and CollateralParams
     */
    function deprecateCollateral(address _collateral) external override exists(_collateral) onlyOwner {
        require(collateralParams[_collateral].active, "collateral already deprecated");
        _deprecateCollateral(_collateral);
    }

    function _deprecateCollateral(address _collateral) internal {
        collateralParams[_collateral].active = false;
        // throw event
        emit CollateralDeprecated(_collateral);
    }

    function setFeeBootstrapPeriodEnabled(bool _enabled) external override onlyOwner {
        feeBoostrapPeriodEnabled = _enabled;
        emit FeeBootstrapPeriodEnabledChanged(_enabled);
    }

    function updateGlobalYUSDMinting(bool _canMint) external override onlyOwner {
        yusdToken.updateMinting(_canMint);
        emit GlobalYUSDMintOn(_canMint);
    }

    function removeValidYUSDMinter(address _minter) external override onlyOwner {
        require(_minter != borrowerOperationsAddress);
        yusdToken.removeValidMinter(_minter);
        emit YUSDMinterChanged(_minter, false);
    }

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
    ) external override onlyOneWeekTimelock {
        checkContract(_collateral);
        checkContract(_oracle);
        checkContract(_feeCurve);
        checkContract(_routerAddress);
        // If collateral list is not 0, and if the 0th index is not equal to this collateral,
        // then if index is 0 that means it is not set yet.
        require(_safetyRatio < 11e17, "Safety Ratio must be less than 1.10"); //=> greater than 1.1 would mean taking out more YUSD than collateral VC
        require(_recoveryRatio >= _safetyRatio, "Recovery ratio must be >= safety ratio");

        if (validCollateral.length != 0) {
            require(
                validCollateral[0] != _collateral && collateralParams[_collateral].index == 0,
                "collateral already exists"
            );
        }

        validCollateral.push(_collateral);
        collateralParams[_collateral] = CollateralParams(
            _safetyRatio,
            _recoveryRatio,
            _oracle,
            _decimals,
            _feeCurve,
            validCollateral.length - 1,
            _routerAddress,
            true,
            _isWrapped
        );

        activePool.addCollateralType(_collateral);
        defaultPool.addCollateralType(_collateral);
        stabilityPool.addCollateralType(_collateral);
        collSurplusPool.addCollateralType(_collateral);

        // throw event
        emit CollateralAdded(_collateral);
        emit SafetyRatioChanged(_collateral, _safetyRatio);
        emit RecoveryRatioChanged(_collateral, _recoveryRatio);
    }

    /**
     * @notice Undeprecate collateral by allowing more collateral to be added of this type.
     * Still can interact with it via validCollateral and CollateralParams
     */
    function unDeprecateCollateral(address _collateral)
        external
        override
        exists(_collateral)
        onlyOneWeekTimelock
    {
        require(!collateralParams[_collateral].active, "collateral is already active");

        collateralParams[_collateral].active = true;

        // throw event
        emit CollateralUndeprecated(_collateral);
    }

    function setLeverUp(bool _enabled) external override onlyOneWeekTimelock {
        isLeverUpEnabled = _enabled;
        emit LeverUpChanged(_enabled);
    }

    function updateMaxCollsInTrove(uint256 _newMax) external override onlyOwner {
        maxCollsInTrove = _newMax;
        emit MaxCollsInTroveChanged(_newMax);
    }

    /**
     * Function to change oracles
     */
    function changeOracle(address _collateral, address _oracle)
        external
        override
        exists(_collateral)
        onlyOneWeekTimelock
    {
        checkContract(_oracle);
        collateralParams[_collateral].oracle = _oracle;

        // throw event
        emit OracleChanged(_collateral, _oracle);
    }

    /**
     * Function to change fee curve
     */
    function changeFeeCurve(address _collateral, address _feeCurve)
        external
        override
        exists(_collateral)
        onlyOneWeekTimelock
    {
        checkContract(_feeCurve);
        require(IFeeCurve(_feeCurve).initialized(), "fee curve not set");
        (uint256 lastFeePercent, uint256 lastFeeTime) = IFeeCurve(
            collateralParams[_collateral].feeCurve
        ).getFeeCapAndTime();
        IFeeCurve(_feeCurve).setFeeCapAndTime(lastFeePercent, lastFeeTime);
        collateralParams[_collateral].feeCurve = _feeCurve;

        // throw event
        emit FeeCurveChanged(_collateral, _feeCurve);
    }

    /**
     * Function to change Safety and Recovery Ratio
     */
    function changeRatios(
        address _collateral,
        uint256 _newSafetyRatio,
        uint256 _newRecoveryRatio
    ) external override exists(_collateral) onlyOneWeekTimelock {
        require(_newSafetyRatio < 11e17, "ratio must be less than 1.10"); //=> greater than 1.1 would mean taking out more YUSD than collateral VC
        require(
            collateralParams[_collateral].safetyRatio <= _newSafetyRatio,
            "New SR must be >= than previous SR"
        );
        require(_newRecoveryRatio >= _newSafetyRatio, "New RR must be greater than or equal to SR");

        collateralParams[_collateral].safetyRatio = _newSafetyRatio;
        collateralParams[_collateral].recoveryRatio = _newRecoveryRatio;

        // throw events
        emit SafetyRatioChanged(_collateral, _newSafetyRatio);
        emit RecoveryRatioChanged(_collateral, _newRecoveryRatio);
    }

    function setDefaultRouter(address _collateral, address _router)
        external
        override
        onlyOneWeekTimelock
        exists(_collateral)
    {
        checkContract(_router);
        collateralParams[_collateral].defaultRouter = _router;
        emit DefaultRouterChanged(_collateral, _router);
    }

    function changeYetiFinanceTreasury(address _newTreasury) external override onlyOneWeekTimelock {
        require(_newTreasury != address(0), "New treasury nonzero");
        yetiFinanceTreasury = _newTreasury;
        emit YetiFinanceTreasuryChanged(_newTreasury);
    }

    function changeYetiFinanceTreasurySplit(uint256 _newSplit)
        external
        override
        onlyOneWeekTimelock
    {
        // 20% goes to the borrower for redemptions, taken out of this portion if it is more than 80%
        require(_newSplit <= 1e18, "Treasury fee split can't be more than 100%");
        yetiFinanceTreasurySplit = _newSplit;
        emit YetiFinanceTreasurySplitChanged(_newSplit);
    }

    function changeRedemptionBorrowerFeeSplit(uint256 _newSplit)
        external
        override
        onlyOneWeekTimelock
    {
        require(_newSplit <= 1e18, "Redemption fee split can't be more than 100%");
        redemptionBorrowerFeeSplit = _newSplit;
        emit RedemptionBorrowerFeeSplitChanged(_newSplit);
    }

    /**
     * @notice Change boost minute decay factor which is calculated as a half life of a particular fraction for SortedTroves
     * @dev Half-life of 5d = 120h. 120h = 7200 min
     * (1/2) = d^7200 => d = (1/2)^(1/7200) = 999903734192105837 by default
     * Two week timelocked.
     * @param _newBoostMinuteDecayFactor the new boost decay factor
     */
    function changeBoostMinuteDecayFactor(uint256 _newBoostMinuteDecayFactor)
        external
        override
        onlyOneWeekTimelock
    {
        sortedTroves.changeBoostMinuteDecayFactor(_newBoostMinuteDecayFactor);
        emit BoostMinuteDecayFactorChanged(_newBoostMinuteDecayFactor);
    }

    /**
     * @notice Change Boost factor multiplied by new input for SortedTroves
     * @dev If fee is 5% of total, then the boost factor will be 5e16 * boost / 1e18 added to RICR for sorted troves reinsert
     * Default is 0 for boost multiplier at contract deployment. 1e18 would mean 100% of the fee % is added to RICR as a %.
     * @param _newGlobalBoostMultiplier new boost multiplier
     */
    function changeGlobalBoostMultiplier(uint256 _newGlobalBoostMultiplier)
        external
        override
        onlyOneWeekTimelock
    {
        sortedTroves.changeGlobalBoostMultiplier(_newGlobalBoostMultiplier);
        emit GlobalBoostMultiplierChanged(_newGlobalBoostMultiplier);
    }

    // ======== Mutable Only Owner-2 Weeks TimeLock ========

    function addValidYUSDMinter(address _minter) external override onlyTwoWeekTimelock {
        require(_minter != address(0), "New minter is not zero");
        yusdToken.addValidMinter(_minter);
        emit YUSDMinterChanged(_minter, true);
    }

    function changeYUSDFeeRecipient(address _newFeeRecipient) external override onlyTwoWeekTimelock {
        require(_newFeeRecipient != address(0), "New fee recipient is not zero");
        YUSDFeeRecipient = _newFeeRecipient;
        emit YUSDFeeRecipientChanged(_newFeeRecipient);
    }

    // update veYETI Accumulation Rate
    function updateVeYetiAR(uint _newAR) external override onlyTwoWeekTimelock {
        veYETI.updateAR(_newAR);
        emit NewVeYetiAccumulationRate(_newAR);
    }

    // ======= VIEW FUNCTIONS FOR COLLATERAL =======

    function getDefaultRouterAddress(address _collateral)
        external
        view
        override
        exists(_collateral)
        returns (address)
    {
        return collateralParams[_collateral].defaultRouter;
    }

    function isWrapped(address _collateral) external view override returns (bool) {
        return collateralParams[_collateral].isWrapped;
    }

    function isWrappedMany(address[] memory _collaterals) external view override returns (bool[] memory wrapped) {
        wrapped = new bool[](_collaterals.length);
        for (uint i = 0; i < _collaterals.length; i++) {
            wrapped[i] = collateralParams[_collaterals[i]].isWrapped;
        }
    }

    function getValidCollateral() external view override returns (address[] memory) {
        return validCollateral;
    }

    // Get safety ratio used in VC Calculation
    function getSafetyRatio(address _collateral) external view override returns (uint256) {
        return collateralParams[_collateral].safetyRatio;
    }

    // Get safety ratio used in TCR calculation, as well as for redemptions.
    // Often similar to Safety Ratio except for stables.
    function getRecoveryRatio(address _collateral)
        external
        view
        override
        exists(_collateral)
        returns (uint256)
    {
        return collateralParams[_collateral].recoveryRatio;
    }

    function getOracle(address _collateral)
        external
        view
        override
        exists(_collateral)
        returns (address)
    {
        return collateralParams[_collateral].oracle;
    }

    function getFeeCurve(address _collateral)
        external
        view
        override
        exists(_collateral)
        returns (address)
    {
        return collateralParams[_collateral].feeCurve;
    }

    function getIsActive(address _collateral)
        external
        view
        override
        exists(_collateral)
        returns (bool)
    {
        return collateralParams[_collateral].active;
    }

    function getDecimals(address _collateral)
        external
        view
        override
        exists(_collateral)
        returns (uint256)
    {
        return collateralParams[_collateral].decimals;
    }

    function getIndex(address _collateral)
        external
        view
        override
        exists(_collateral)
        returns (uint256)
    {
        return (collateralParams[_collateral].index);
    }

    function getIndices(address[] memory _colls)
        external
        view
        override
        returns (uint256[] memory indices)
    {
        uint256 len = _colls.length;
        indices = new uint256[](len);

        for (uint256 i; i < len; ++i) {
            _exists(_colls[i]);
            indices[i] = collateralParams[_colls[i]].index;
        }
    }

    /**
     * @notice This function is used to check the deposit and withdraw coll lists of the adjust trove transaction.
     * @dev The coll list must be not overlapping, and strictly increasing. Strictly increasing implies not overlapping,
     * so we just check that. If it is a deposit, the coll also has to be active. The collateral also has to exist. Special
     * case is done for the first collateral, where we don't check the index. Reverts if any case is not met.
     * @param _colls Collateral to check
     * @param _deposit True if deposit, false if withdraw.
     */
    function checkCollateralListSingle(address[] memory _colls, bool _deposit)
        external
        view
        override
    {
        _checkCollateralListSingle(_colls, _deposit);
    }

    function _checkCollateralListSingle(address[] memory _colls, bool _deposit) internal view {
        uint256 len = _colls.length;
        if (len == 0) {
            return;
        }
        // address thisColl = _colls[0];
        // _exists(thisColl);
        uint256 prevIndex; // = collateralParams[thisColl].index;
        // if (_deposit) {
        //     _requireCollateralActive(thisColl);
        // }
        for (uint256 i; i < len; ++i) {
            address thisColl = _colls[i];
            _exists(thisColl);
            require(
                collateralParams[thisColl].index > prevIndex || i == 0,
                "Collateral list must be sorted by index"
            );
            prevIndex = collateralParams[thisColl].index;
            if (_deposit) {
                _requireCollateralActive(thisColl);
            }
        }
    }

    /**
     * @notice This function is used to check the deposit and withdraw coll lists of the adjust trove transaction.
     * @dev The colls must be not overlapping, and each strictly increasing. While looping through both, we check that
     * the indices are not shared, and we then increment by each list whichever is smaller at that time, whie simultaneously
     * checking if the indices of that list are strictly increasing. It also ensures that collaterals exist in the system,
     * and deposited collateral is active. Reverts if any case is not met.
     * @param _depositColls Collateral to check for deposits
     * @param _withdrawColls Collateral to check for withdrawals
     */
    function checkCollateralListDouble(
        address[] memory _depositColls,
        address[] memory _withdrawColls
    ) external view override {
        uint256 _depositLen = _depositColls.length;
        uint256 _withdrawLen = _withdrawColls.length;
        if (_depositLen == 0) {
            if (_withdrawLen == 0) {
                // Both empty, nothing to check
                return;
            } else {
                // Just withdraw check
                _checkCollateralListSingle(_withdrawColls, false);
                return;
            }
        }
        if (_withdrawLen == 0) {
            // Just deposit check
            _checkCollateralListSingle(_depositColls, true);
            return;
        }
        address dColl = _depositColls[0];
        address wColl = _withdrawColls[0];
        uint256 dIndex = collateralParams[dColl].index;
        uint256 wIndex = collateralParams[wColl].index;
        uint256 d_i;
        uint256 w_i;
        while (true) {
            require(dIndex != wIndex, "No overlap in withdraw and deposit");
            if (dIndex < wIndex) {
                // update d coll
                if (d_i == _depositLen) {
                    break;
                }
                dColl = _depositColls[d_i];
                _exists(dColl);
                _requireCollateralActive(dColl);
                uint256 dIndexNew = collateralParams[dColl].index;
                require(dIndexNew > dIndex || d_i == 0, "Collateral list must be sorted by index");
                dIndex = dIndexNew;
                ++d_i;
            } else {
                // update w coll
                if (w_i == _withdrawLen) {
                    break;
                }
                wColl = _withdrawColls[w_i];
                _exists(wColl);
                uint256 wIndexNew = collateralParams[wColl].index;
                require(wIndexNew > wIndex || w_i == 0, "Collateral list must be sorted by index");
                wIndex = wIndexNew;
                ++w_i;
            }
        }
        // No further check of dIndex == wIndex is needed, because to close out of the loop above, we have
        // to have advanced d_i or w_i whichever reached the end. Say d_i reached the end, which means that
        // dIndex was less than wIndex. dIndex has already been updated for the last time, and wIndex is now
        // required to be larger than dIndex. So, no wIndex, unless if it wasn't strictly increasing, can be
        // equal to dIndex. Therefore we only need to check for wIndex to be strictly increasing. Same argument
        // for the vice versa case.
        while (d_i < _depositLen) {
            dColl = _depositColls[d_i];
            _exists(dColl);
            _requireCollateralActive(dColl);
            uint256 dIndexNew = collateralParams[dColl].index;
            require(dIndexNew > dIndex || d_i == 0, "Collateral list must be sorted by index");
            dIndex = dIndexNew;
            ++d_i;
        }
        while (w_i < _withdrawLen) {
            wColl = _withdrawColls[w_i];
            _exists(wColl);
            uint256 wIndexNew = collateralParams[wColl].index;
            require(wIndexNew > wIndex || w_i == 0, "Collateral list must be sorted by index");
            wIndex = wIndexNew;
            ++w_i;
        }
    }

    // ======= VIEW FUNCTIONS FOR VC / USD VALUE =======

    // should return 10**18 times the price in USD of 1 of the given _collateral
    function getPrice(address _collateral) public view override returns (uint256) {
        IPriceFeed collateral_priceFeed = IPriceFeed(collateralParams[_collateral].oracle);
        return collateral_priceFeed.fetchPrice_v();
    }

    // Gets the value of that collateral type, of that amount, in USD terms.
    function getValueUSD(address _collateral, uint256 _amount)
        external
        view
        override
        returns (uint256)
    {
        return _getValueUSD(_collateral, _amount);
    }

    // Aggregates all usd values of passed in collateral / amounts
    function getValuesUSD(address[] memory _collaterals, uint256[] memory _amounts)
        external
        view
        override
        returns (uint256 USDValue)
    {
        uint256 tokensLen = _collaterals.length;
        for (uint256 i; i < tokensLen; ++i) {
            USDValue = USDValue.add(_getValueUSD(_collaterals[i], _amounts[i]));
        }
    }

    // Gets the value of that collateral type, of that amount, in VC terms.
    function getValueVC(address _collateral, uint256 _amount)
        external
        view
        override
        returns (uint256)
    {
        return _getValueVC(_collateral, _amount);
    }

    function getValuesVC(address[] memory _collaterals, uint256[] memory _amounts)
        external
        view
        override
        returns (uint256 VCValue)
    {
        uint256 tokensLen = _collaterals.length;
        for (uint256 i; i < tokensLen; ++i) {
            VCValue = VCValue.add(_getValueVC(_collaterals[i], _amounts[i]));
        }
    }

    /** 
     * @notice External Function to get the VC balance and return them as an array of values instead
     * of summing them like in getValuesVC.
     */
    function getValuesVCIndividual(address[] memory _collaterals, uint256[] memory _amounts)
        external
        view
        override
        returns (uint256[] memory)
    {
        return _getValuesVCIndividual(_collaterals, _amounts);
    }

    /** 
     * @notice Function to get the VC balance and return them as an array of values instead
     * of summing them like in getValuesVC.
     */
    function _getValuesVCIndividual(address[] memory _collaterals, uint256[] memory _amounts)
        internal
        view
        returns (uint256[] memory VCValues)
    {
        uint256 tokensLen = _collaterals.length;
        VCValues = new uint256[](tokensLen);
        for (uint256 i; i < tokensLen; ++i) {
            VCValues[i] = _getValueVC(_collaterals[i], _amounts[i]);
        }
    }

    // Gets the value of that collateral type, of that amount, in Recovery VC terms.
    function getValueRVC(address _collateral, uint256 _amount)
        external
        view
        override
        returns (uint256)
    {
        return _getValueRVC(_collateral, _amount);
    }

    function getValuesRVC(address[] memory _collaterals, uint256[] memory _amounts)
        external
        view
        override
        returns (uint256 RVCValue)
    {
        uint256 tokensLen = _collaterals.length;
        for (uint256 i; i < tokensLen; ++i) {
            RVCValue = RVCValue.add(_getValueRVC(_collaterals[i], _amounts[i]));
        }
    }

    function _getValueRVC(address _collateral, uint256 _amount) internal view returns (uint256) {
        // Multiply price by amount and recovery ratio to get in Recovery VC terms, as well as dividing by amount of decimals to normalize.
        return (
            (getPrice(_collateral))
                .mul(_amount)
                .mul(collateralParams[_collateral].recoveryRatio)
                .div(10**(18 + collateralParams[_collateral].decimals))
        );
    }

    function getValuesVCforTCR(address[] memory _collaterals, uint256[] memory _amounts)
        external
        view
        override
        returns (uint256 VCValue, uint256 RVCValue)
    {
        uint256 tokensLen = _collaterals.length;
        for (uint256 i; i < tokensLen; ++i) {
            (uint256 tempVCValue, uint256 tempRVCValue) = _getValueVCforTCR(
                _collaterals[i],
                _amounts[i]
            );
            VCValue = VCValue.add(tempVCValue);
            RVCValue = RVCValue.add(tempRVCValue);
        }
    }

    // ===== VIEW FUNCTIONS FOR CONTRACT FUNCTIONALITY ======

    function getYetiFinanceTreasury() external view override returns (address) {
        return yetiFinanceTreasury;
    }

    function getYetiFinanceTreasurySplit() external view override returns (uint256) {
        return yetiFinanceTreasurySplit;
    }

    function getRedemptionBorrowerFeeSplit() external view override returns (uint256) {
        return redemptionBorrowerFeeSplit;
    }

    function getYUSDFeeRecipient() external view override returns (address) {
        return YUSDFeeRecipient;
    }

    function leverUpEnabled() external view override returns (bool) {
        return isLeverUpEnabled;
    }

    function getMaxCollsInTrove() external view override returns (uint256) {
        return maxCollsInTrove;
    }

    /**
     * Returns the treasury address, treasury split, and the fee recipeint. This is for use of borrower
     * operations when fees are sent, as well as redemption fees.
     */
    function getFeeSplitInformation()
        external
        view
        override
        returns (
            uint256,
            address,
            address
        )
    {
        return (yetiFinanceTreasurySplit, yetiFinanceTreasury, YUSDFeeRecipient);
    }

    // ====== FUNCTIONS FOR FEES ======


    // Returned as fee percentage * 10**18. View function for external callers.
    function getVariableDepositFee(
        address _collateral,
        uint256 _collateralVCInput,
        uint256 _collateralVCSystemBalance,
        uint256 _totalVCBalancePre,
        uint256 _totalVCBalancePost
    ) external view override exists(_collateral) returns (uint256) {
        IFeeCurve feeCurve = IFeeCurve(collateralParams[_collateral].feeCurve);
        uint256 uncappedFee = feeCurve.getFee(
                _collateralVCInput,
                _collateralVCSystemBalance,
                _totalVCBalancePre,
                _totalVCBalancePost
            );
        if (feeBoostrapPeriodEnabled) {
            return YetiMath._min(uncappedFee, 1e16); // cap at 1%
        } else {
            return uncappedFee;
        }
    }

    /** 
     * @notice Gets total variable fees from all collaterals with entire system collateral,
     * calculates using pre and post balances. For each token, get the active pool and
     * default pool balance of that collateral, and call the correct fee curve function
     * If the fee bootstrap period is on then cap it at a certain percent, otherwise
     * continue looping through all collaterals.
     * To calculate the boost factor, we multiply the fee * leverage amount. Leverage
     * passed in as 0 is actually 1x.
     * @param _tokensIn the tokens to get the variable fees for
     * @param _leverages the leverage of that collateral. Used for calculating boost on collateral
     *   one time deposit fees. Passed in as 0 if not a token that is leveraged. 
     * @param _entireSystemCollVC the entire system collateral VC value calculated previously in 
     *   recovery mode check calculations 
     * @param _VCin the sum of all collaterals added in from adjustTrove or openTrove
     * @param _VCout the sum of all collaterals withdrawn from adjustTrove
     * @return YUSDFee the total variable fees for all tokens in this transaction
     * @return boostFactor the boost factor for all tokens in this transaction based on the leverage and 
     *    fee applied. 
     */
    function getTotalVariableDepositFeeAndUpdate(
        address[] memory _tokensIn,
        uint256[] memory _amountsIn,
        uint256[] memory _leverages,
        uint256 _entireSystemCollVC,
        uint256 _VCin,
        uint256 _VCout
    ) external override returns (uint256 YUSDFee, uint256 boostFactor) {
        require(msg.sender == borrowerOperationsAddress, "caller must be BO");
        if (_VCin == 0) {
            return (0, 0);
        }
        DepositFeeCalc memory vars;
        // active pool total VC at current state is passed in as _entireSystemCollVC
        // active pool total VC post adding and removing all collaterals
        vars.activePoolVCPost = _entireSystemCollVC.add(_VCin).sub(_VCout);
        uint256 tokensLen = _tokensIn.length;
        // VC value of collateral of this type inputted, from AP and DP balances. 
        vars.systemCollateralVCs = _getValuesVCIndividual(_tokensIn, activePool.getAmountsSubsetSystem(_tokensIn));
        for (uint256 i; i < tokensLen; ++i) {
            vars.token = _tokensIn[i];
            // VC value of collateral of this type inputted
            vars.collateralInputVC = _getValueVC(vars.token, _amountsIn[i]);

            // (collateral VC In) * (Collateral's Fee Given Yeti Protocol Backed by Given Collateral)
            uint256 controllerFee = _getFeeAndUpdate(
                vars.token,
                vars.collateralInputVC,
                vars.systemCollateralVCs[i],
                _entireSystemCollVC,
                vars.activePoolVCPost
            );
            if (feeBoostrapPeriodEnabled) {
                controllerFee = YetiMath._min(controllerFee, 1e16); // cap at 1%
            }
            vars.collateralYUSDFee = vars.collateralInputVC.mul(controllerFee).div(1e18);

            // If lower than 1, then it was not leveraged (1x)
            uint256 thisLeverage = YetiMath._max(1e18, _leverages[i]);

            uint256 collBoostFactor = vars.collateralYUSDFee.mul(thisLeverage).div(_VCin);
            boostFactor = boostFactor.add(collBoostFactor);

            YUSDFee = YUSDFee.add(vars.collateralYUSDFee);
        }
    }

    // Returned as fee percentage * 10**18. View function for call to fee originating from BOps callers.
    function _getFeeAndUpdate(
        address _collateral,
        uint256 _collateralVCInput,
        uint256 _collateralVCSystemBalance,
        uint256 _totalVCBalancePre,
        uint256 _totalVCBalancePost
    ) internal exists(_collateral) returns (uint256 fee) {
        IFeeCurve feeCurve = IFeeCurve(collateralParams[_collateral].feeCurve);
        return
            feeCurve.getFeeAndUpdate(
                _collateralVCInput,
                _collateralVCSystemBalance,
                _totalVCBalancePre,
                _totalVCBalancePost
            );
    }

    // ======== INTERNAL VIEW FUNCTIONS ========

    function _getValueVCforTCR(address _collateral, uint256 _amount)
        internal
        view
        returns (uint256 VC, uint256 VCforTCR)
    {
        uint256 price = getPrice(_collateral);
        uint256 decimals = collateralParams[_collateral].decimals;
        uint256 safetyRatio = collateralParams[_collateral].safetyRatio;
        uint256 recoveryRatio = collateralParams[_collateral].recoveryRatio;
        VC = price.mul(_amount).mul(safetyRatio).div(10**(18 + decimals));
        VCforTCR = price.mul(_amount).mul(recoveryRatio).div(10**(18 + decimals));
    }

    function _getValueUSD(address _collateral, uint256 _amount) internal view returns (uint256) {
        uint256 decimals = collateralParams[_collateral].decimals;
        uint256 price = getPrice(_collateral);
        return price.mul(_amount).div(10**decimals);
    }

    function _getValueVC(address _collateral, uint256 _amount) internal view returns (uint256) {
        // Multiply price by amount and safety ratio to get in VC terms, as well as dividing by amount of decimals to normalize.
        return (
            (getPrice(_collateral)).mul(_amount).mul(collateralParams[_collateral].safetyRatio).div(
                10**(18 + collateralParams[_collateral].decimals)
            )
        );
    }

    function _requireCollateralActive(address _collateral) internal view {
        require(collateralParams[_collateral].active, "Collateral must be active");
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

    function decayBaseRateFromBorrowingAndCalculateFee(uint256 _YUSDDebt) external returns (uint);

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

    function updateTroveCollAndStakeAndTotalStakes(address _borrower, address[] memory _tokens, uint[] memory _amounts) external;

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

    function getFirst() external view returns (address);

    function getLast() external view returns (address);

    function getNode(address _id) external view returns (bool, address, address, uint256, uint256, uint256);

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


interface IYetiController {

    // ======== Mutable Only Owner-Instantaneous ========
    function setAddresses(
        address _activePoolAddress,
        address _defaultPoolAddress,
        address _stabilityPoolAddress,
        address _collSurplusPoolAddress,
        address _borrowerOperationsAddress,
        address _yusdTokenAddress,
        address _sYETITokenAddress,
        address _yetiFinanceTreasury,
        address _sortedTrovesAddress,
        address _veYETIAddress,
        address _oneWeekTimelock,
        address _twoWeekTimelock
    ) external; // setAddresses is special as it only can be called once
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
    function updateVeYetiAR(uint _newAR) external;


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
    function isWrappedMany(address[] memory _collaterals) external view returns (bool[] memory wrapped);
    function getDefaultRouterAddress(address _collateral) external view returns (address);

    // ======= MUTABLE FUNCTION FOR FEES =======
    function getTotalVariableDepositFeeAndUpdate(
        address[] memory _tokensIn,
        uint256[] memory _amountsIn,
        uint256[] memory _leverages,
        uint256 _entireSystemCollVC,
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
    function getValueUSD(address _collateral, uint _amount) view external returns (uint256);
    function getValuesVCIndividual(address[] memory _collaterals, uint256[] memory _amounts) external view returns (uint256[] memory);


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
import "./CheckContract.sol";

/** 
 * Contains shared functionality of TroveManagerLiquidations, TroveManagerRedemptions, and TroveManager. 
 * Keeps addresses to cache, events, structs, status, etc. Also keeps Trove struct. 
 */

contract TroveManagerBase is LiquityBase, CheckContract, Ownable {

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity 0.6.11;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () public {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

    
interface IActivePool is IPool {
    // --- Events ---
    event ActivePoolYUSDDebtUpdated(uint _YUSDDebt);
    event ActivePoolCollateralBalanceUpdated(address _collateral, uint _amount);

    // --- Functions ---
    
    function sendCollaterals(address _to, address[] memory _tokens, uint[] memory _amounts) external;

    function sendCollateralsUnwrap(address _to, address[] memory _tokens, uint[] memory _amounts) external;

    function sendSingleCollateral(address _to, address _token, uint256 _amount) external;

    function sendSingleCollateralUnwrap(address _to, address _token, uint256 _amount) external;

    function getCollateralVC(address collateralAddress) external view returns (uint);
    
    function addCollateralType(address _collateral) external;

    function getAmountsSubsetSystem(address[] memory _collaterals) external view returns (uint256[] memory);

    function getVCSystem() external view returns (uint256 totalVCSystem);

    function getVCforTCRSystem() external view returns (uint256 totalVC, uint256 totalVCforTCR);

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "./IPool.sol";

interface IDefaultPool is IPool {
    // --- Events ---
    event DefaultPoolYUSDDebtUpdated(uint256 _YUSDDebt);
    event DefaultPoolETHBalanceUpdated(uint256 _ETH);

    // --- Functions ---
    
    function sendCollsToActivePool(address[] memory _collaterals, uint256[] memory _amounts) external;

    function addCollateralType(address _collateral) external;

    function getCollateralVC(address collateralAddress) external view returns (uint256);

    function getAmountsSubset(address[] memory _collaterals) external view returns (uint256[] memory amounts, uint256[] memory controllerIndices);

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

    uint256 public constant DECIMAL_PRECISION = 1e18;

    /**
     * @notice Returns _coll1.amounts plus _coll2.amounts
     * @dev Invariant that _coll1.tokens and _coll2.tokens are sorted by whitelist order of token indices from the YetiController.
     *    So, if WAVAX is whitelisted first, then WETH, then USDC, then [WAVAX, USDC] is a valid input order but [USDC, WAVAX] is not.
     *    This is done for gas efficiency. We use a sliding window approach to increment the indices of the tokens we are adding together
     *    from _coll1 and from _coll2. We will start at tokenIndex1 and tokenIndex2. To keep the invariant of ordered collateral in 
     *    each trove, we need to merge coll1 and coll2 in order based on the YetiController whitelist order. If the token indices 
     *    line up, then they are the same and we add the sum. Otherwise we add the smaller index to keep them in order and move on. 
     *    Once we reach the end of either tokens1 or tokens2, we add the remaining ones to the sum individually without summing. 
     *    n is the number of tokens in the coll1, and m is the number of tokens in the coll2. k is defined as the number of tokens 
     *    in the summed version. k = n + m - (overlap). The time complexity here depends on O(n + m) in the first loop and tail calls, 
     *    and O(k) in the last loop. The total time complexity is O(n + m + k). If we assume that n is bigger than m(arbitrary between 
     *    n and m), then since k is bounded by n we can say the time complexity is O(3n). This does not depend on all whitelisted tokens. 
     */
    function _sumColls(newColls memory _coll1, newColls memory _coll2)
        internal
        view
        returns (newColls memory finalColls)
    {
        uint256 coll2Len = _coll2.tokens.length;
        uint256 coll1Len = _coll1.tokens.length;
        // If either is 0 then just return the other one. 
        if (coll2Len == 0) {
            return _coll1;
        } else if (coll1Len == 0) {
            return _coll2;
        }
        // Create temporary n + m sized array.
        newColls memory coll3;
        coll3.tokens = new address[](coll1Len + coll2Len);
        coll3.amounts = new uint256[](coll1Len + coll2Len);

        // Tracker for the coll1 array.
        uint256 i = 0;
        // Tracker for the coll2 array.
        uint256 j = 0;
        // Tracker for nonzero entries.
        uint256 k = 0;

        uint256[] memory tokenIndices1 = controller.getIndices(_coll1.tokens);
        uint256[] memory tokenIndices2 = controller.getIndices(_coll2.tokens);

        // Tracker for token whitelist index for all coll1
        uint256 tokenIndex1 = tokenIndices1[i];
        // Tracker for token whitelist index for all coll2
        uint256 tokenIndex2 = tokenIndices2[j];

        // This loop will break out if either token index reaches the end inside the conditions. 
        while (true) {
            if (tokenIndex1 < tokenIndex2) {
                // If tokenIndex1 is less than tokenIndex2 then that means it should be added first by itself.
                coll3.tokens[k] = _coll1.tokens[i];
                coll3.amounts[k] = _coll1.amounts[i];
                ++i;
                // If we reached the end of coll1 then we exit out.
                if (i == coll1Len) {
                    break;
                }
                tokenIndex1 = tokenIndices1[i];
            } else if (tokenIndex2 < tokenIndex1) {
                // If tokenIndex2 is less than tokenIndex1 then that means it should be added first by itself.
                coll3.tokens[k] = _coll2.tokens[j];
                coll3.amounts[k] = _coll2.amounts[j];
                ++j;
                // If we reached the end of coll2 then we exit out.
                if (j == coll2Len) {
                    break;
                }
                tokenIndex2 = tokenIndices2[j];
            } else {
                // If the token indices match up then they are the same token, so we add them together.
                coll3.tokens[k] = _coll1.tokens[i];
                coll3.amounts[k] = _coll1.amounts[i].add(_coll2.amounts[j]);
                ++i;
                ++j;
                // If we reached the end of coll1 or coll2 then we exit out.
                if (i == coll1Len || j == coll2Len) {
                    break;
                }
                tokenIndex1 = tokenIndices1[i];
                tokenIndex2 = tokenIndices2[j];
            }
            ++k;
        }
        ++k;
        // Add remaining tokens from coll1 if we reached the end of coll2 inside the previous loop. 
        while (i < coll1Len) {
            coll3.tokens[k] = _coll1.tokens[i];
            coll3.amounts[k] = _coll1.amounts[i];
            ++i;
            ++k;
        }
        // Add remaining tokens from coll2 if we reached the end of coll1 inside the previous loop. 
        while (j < coll2Len) {
            coll3.tokens[k] = _coll2.tokens[j];
            coll3.amounts[k] = _coll2.amounts[j];
            ++j;
            ++k;
        }

        // K is the resulting amount of nonzero entries that are in coll3, so we add them to finalTokens and return. 
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

contract CheckContract {
    /**
     * @notice Check that the account is an already deployed non-destroyed contract.
     * @dev See: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol#L12
     * @param _account The address of the account to be checked 
    */
    function checkContract(address _account) internal view {
        require(_account != address(0), "Account cannot be zero address");

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(_account) }
        require(size != 0, "Account code size cannot be zero");
    }
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

interface IBaseOracle {
  /// @dev Return the value of the given input as USD per unit.
  /// @param token The ERC-20 token to check the value.
  function getPrice(address token) external view returns (uint);

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

interface IFeeCurve {
    function setAddresses(address _controllerAddress) external;

    function setDecayTime(uint _decayTime) external;

    function setDollarCap(uint _dollarCap) external;

    function initialized() external view returns (bool);

    /** 
     * Returns fee based on inputted collateral VC balance and total VC balance of system. 
     * fee is in terms of percentage * 1e18. 
     * If the fee were 1%, this would be 0.01 * 1e18 = 1e16
     */
    function getFee(uint256 _collateralVCInput, uint256 _collateralVCBalancePost, uint256 _totalVCBalancePre, uint256 _totalVCBalancePost) external view returns (uint256 fee);

    // Same function, updates the fee as well. Called only by controller.
    function getFeeAndUpdate(uint256 _collateralVCInput, uint256 _totalCollateralVCBalance, uint256 _totalVCBalancePre, uint256 _totalVCBalancePost) external returns (uint256 fee);

    // Function for setting the old fee curve's last fee cap / value to the new fee cap / value. 
    // Called only by controller.
    function setFeeCapAndTime(uint256 _lastFeePercent, uint256 _lastFeeTime) external;

    // Gets the fee cap and time currently. Used for setting new values for next fee curve. 
    // returns lastFeePercent, lastFeeTime
    function getFeeCapAndTime() external view returns (uint256 _lastFeePercent, uint256 _lastFeeTime);

    /** 
     * Returns fee based on decay since last fee calculation, which we take to be 
     * a reasonable fee amount. If it has decayed a certain amount since then, we let
     * the new fee amount slide. 
     */
    function calculateDecayedFee() external view returns (uint256 fee);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

interface IveYETI {
    function updateAR(uint _newAccumulationRate) external;
}
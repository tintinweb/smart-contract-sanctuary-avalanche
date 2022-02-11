// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "./TroveManager.sol";
import "./SortedTroves.sol";
import "./Dependencies/Whitelist.sol";

/*  Helper contract for grabbing Trove data for the front end. Not part of the core Liquity system. */
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
    IWhitelist public whitelist;

    constructor(TroveManager _troveManager, ISortedTroves _sortedTroves, IWhitelist _whitelist) public {
        troveManager = _troveManager;
        sortedTroves = _sortedTroves;
        whitelist = _whitelist;
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

        data.allColls = whitelist.getValidCollateral();
        data.stakeAmounts = new uint[](data.allColls.length);
        data.snapshotAmounts = new uint[](data.allColls.length);
        for (uint i = 0; i < data.allColls.length; i++) {
            address token = data.allColls[i];

            data.stakeAmounts[i] = troveManager.getTroveStake(_troveOwner, token);
            data.snapshotAmounts[i] = troveManager.getRewardSnapshotColl(_troveOwner, token);
            data.snapshotYUSDDebts[i] = troveManager.getRewardSnapshotYUSD(_troveOwner, token);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "./Interfaces/ITroveManager.sol";
import "./Interfaces/IStabilityPool.sol";
import "./Interfaces/ICollSurplusPool.sol";
import "./Interfaces/IYUSDToken.sol";
import "./Interfaces/ISortedTroves.sol";
import "./Interfaces/IYETIToken.sol";
import "./Interfaces/ISYETI.sol";
import "./Interfaces/IWhitelist.sol";
import "./Interfaces/ITroveManagerLiquidations.sol";
import "./Interfaces/ITroveManagerRedemptions.sol";
import "./Dependencies/TroveManagerBase.sol";
import "./Interfaces/IERC20.sol";

/** 
 * Trove Manager is the contract which deals with the state of a user's trove. It has all the 
 * external functions for liquidations, redemptions, as well as functions called by 
 * BorrowerOperations function calls. 
 */

contract TroveManager is TroveManagerBase, ITroveManager {
    string constant public NAME = "TroveManager";

    // --- Data structures ---

    uint constant public SECONDS_IN_ONE_MINUTE = 60;

    /*
     * Half-life of 12h. 12h = 720 min
     * (1/2) = d^720 => d = (1/2)^(1/720)
     */
    uint constant public MINUTE_DECAY_FACTOR = 999037758833783000;
    uint constant public MAX_BORROWING_FEE = DECIMAL_PRECISION / 100 * 5; // 5%

    // During bootsrap period redemptions are not allowed
    uint constant public BOOTSTRAP_PERIOD = 14 days;

    uint public baseRate;

    // The timestamp of the latest fee operation (redemption or new YUSD issuance)
    uint public lastFeeOperationTime;


    mapping (address => Trove) Troves;

    // uint public totalStakes;
    mapping (address => uint) public totalStakes;

    // Snapshot of the value of totalStakes, taken immediately after the latest liquidation
    mapping (address => uint) public totalStakesSnapshot;

    // Snapshot of the total collateral across the ActivePool and DefaultPool, immediately after the latest liquidation.
    mapping (address => uint) public totalCollateralSnapshot;

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
    mapping (address => uint) private L_Coll;
    mapping (address => uint) public L_YUSDDebt;

    // Map addresses with active troves to their RewardSnapshot
    mapping (address => RewardSnapshot) rewardSnapshots;

    // Object containing the reward snapshots for a given active trove
    struct RewardSnapshot {
        mapping(address => uint) CollRewards;
        mapping(address => uint) YUSDDebts;
    }

    // Array of all active trove addresses - used to to compute an approximate hint off-chain, for the sorted list insertion
    address[] private TroveOwners;

    // Error trackers for the trove redistribution calculation
    mapping (address => uint) public lastCollError_Redistribution;
    mapping (address => uint) public lastYUSDDebtError_Redistribution;

    /*
    * --- Variable container structs for liquidations ---
    *
    * These structs are used to hold, return and assign variables inside the liquidation functions,
    * in order to avoid the error: "CompilerError: Stack too deep".
    **/

    // --- Events ---

    event BaseRateUpdated(uint _baseRate);
    event LastFeeOpTimeUpdated(uint _lastFeeOpTime);
    event TotalStakesUpdated(address token, uint _newTotalStakes);
    event SystemSnapshotsUpdated(uint _unix);

    event Liquidation(uint liquidatedAmount, uint totalYUSDGasCompensation, 
        address[] totalCollTokens, uint[] totalCollAmounts,
        address[] totalCollGasCompTokens, uint[] totalCollGasCompAmounts);

    event LTermsUpdated(address _Coll_Address, uint _L_Coll, uint _L_YUSDDebt);
    event TroveSnapshotsUpdated(uint _unix);
    event TroveIndexUpdated(address _borrower, uint _newIndex);
    event TroveUpdated(address indexed _borrower, uint _debt, address[] _tokens, uint[] _amounts, TroveManagerOperation operation);

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
    external
    override
    onlyOwner
    {
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
        checkContract(_troveManagerRedemptionsAddress);
        checkContract(_troveManagerLiquidationsAddress);

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

        troveManagerRedemptionsAddress = _troveManagerRedemptionsAddress;
        troveManagerLiquidationsAddress = _troveManagerLiquidationsAddress;
        troveManagerRedemptions = ITroveManagerRedemptions(_troveManagerRedemptionsAddress);
        troveManagerLiquidations = ITroveManagerLiquidations(_troveManagerLiquidationsAddress);
        _renounceOwnership();
    }

    // --- Getters ---

    function getTroveOwnersCount() public view override returns (uint) {
        return TroveOwners.length;
    }

    function getTroveFromTroveOwnersArray(uint _index) external view override returns (address) {
        return TroveOwners[_index];
    }

    // --- Trove Liquidation functions ---

    // Single liquidation function. Closes the trove if its ICR is lower than the minimum collateral ratio.
    function liquidate(address _borrower) external override {
        _requireTroveIsActive(_borrower);

        address[] memory borrowers = new address[](1);
        borrowers[0] = _borrower;
        batchLiquidateTroves(borrowers, msg.sender);
    }

    /*
    * Attempt to liquidate a custom list of troves provided by the caller.
    */
    function batchLiquidateTroves(address[] memory _troveArray, address _liquidator) public override {
        troveManagerLiquidations.batchLiquidateTroves(_troveArray, _liquidator);
    }


    // --- Liquidation helper functions ---

    /*
    * This function is called only by TroveManagerLiquidations.sol during a liquidation in recovery mode where
    * the trove has TCR > ICR >= MCR. In this case, the liquidation occurs. 110% of the debt in
    * collateral is sent to the stability pool and any surplus is sent to the collateral surplus pool
    */
    function collSurplusUpdate(address _account, address[] memory _tokens, uint[] memory _amounts) external override {
        _requireCallerIsTML();
        collSurplusPool.accountSurplus(_account, _tokens, _amounts);
    }

    // Move a Trove's pending debt and collateral rewards from distributions, from the Default Pool to the Active Pool
    function movePendingTroveRewardsToActivePool(IActivePool _activePool, IDefaultPool _defaultPool, uint _YUSD, address[] memory _tokens, uint[] memory _amounts, address _borrower) external override {
        _requireCallerIsTML();
        _movePendingTroveRewardsToActivePool(_activePool, _defaultPool, _YUSD, _tokens, _amounts, _borrower);
    }

    function _movePendingTroveRewardsToActivePool(IActivePool _activePool, IDefaultPool _defaultPool, uint _YUSD, address[] memory _tokens, uint[] memory _amounts, address _borrower) internal {
        _defaultPool.decreaseYUSDDebt(_YUSD);
        _activePool.increaseYUSDDebt(_YUSD);
        _defaultPool.sendCollsToActivePool(_tokens, _amounts, _borrower);
    }

    // Update position of given trove
    function _updateTrove(address _borrower, address _lowerHint, address _upperHint) internal {
        (uint debt, address[] memory tokens, uint[] memory amounts, , , ) = getEntireDebtAndColls(_borrower);

        newColls memory troveColl;
        troveColl.tokens = tokens;
        troveColl.amounts = amounts;

        uint ICR = _getICRColls(troveColl, debt);
        sortedTroves.reInsert(_borrower, ICR, _lowerHint, _upperHint);
    }

    // Update position for a set of troves using latest price data. This can be called by anyone.
    // Yeti Finance will also be running a bot to assist with keeping the list from becoming
    // too stale.
    function updateTroves(address[] memory _borrowers, address[] memory _lowerHints, address[] memory _upperHints) external {
        require(_borrowers.length == _lowerHints.length);
        require(_lowerHints.length == _upperHints.length);

        for (uint i = 0; i < _lowerHints.length; i++) {
            _updateTrove(_borrowers[i], _lowerHints[i], _upperHints[i]);
        }
    }

    /* Send _YUSDamount YUSD to the system and redeem the corresponding amount of collateral from as many Troves as are needed to fill the redemption
    * request.  Applies pending rewards to a Trove before reducing its debt and coll.
    *
    * Note that if _amount is very large, this function can run out of gas, specially if traversed troves are small. This can be easily avoided by
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
    * If another transaction modifies the list between calling getRedemptionHints() and passing the hints to redeemCollateral(), it
    * is very likely that the last (partially) redeemed Trove would end up with a different ICR than what the hint is for. In this case the
    * redemption will stop after the last completely redeemed Trove and the sender will keep the remaining YUSD amount, which they can attempt
    * to redeem later.
    */
    function redeemCollateral(
        uint _YUSDamount,
        uint _YUSDMaxFee,
        address _firstRedemptionHint,
        address _upperPartialRedemptionHint,
        address _lowerPartialRedemptionHint,
        uint _partialRedemptionHintICR,
        uint _maxIterations
    )
    external
    override
    {
        troveManagerRedemptions.redeemCollateral(
            _YUSDamount,
            _YUSDMaxFee,
            _firstRedemptionHint,
            _upperPartialRedemptionHint,
            _lowerPartialRedemptionHint,
            _partialRedemptionHintICR,
            _maxIterations,
            msg.sender);
    }

    // --- Helper functions ---

    // Return the current collateral ratio (ICR) of a given Trove.
    // Takes a trove's pending coll and debt rewards from redistributions into account.
    function getCurrentICR(address _borrower) public view override returns (uint) {
        (newColls memory colls, uint currentYUSDDebt) = _getCurrentTroveState(_borrower);

        uint ICR = _getICRColls(colls, currentYUSDDebt);
        return ICR;
    }

    // Gets current trove state as colls and debt. 
    function _getCurrentTroveState(address _borrower) internal view
    returns (newColls memory colls, uint YUSDdebt) {
        newColls memory pendingCollReward = _getPendingCollRewards(_borrower);
        uint pendingYUSDDebtReward = getPendingYUSDDebtReward(_borrower);
        
        uint currentYUSDDebt = Troves[_borrower].debt.add(pendingYUSDDebtReward);
        newColls memory currentColls = _sumColls(Troves[_borrower].colls, pendingCollReward);
        
        return (currentColls, currentYUSDDebt);
    }

    // Add the borrowers's coll and debt rewards earned from redistributions, to their Trove
    function applyPendingRewards(address _borrower) external override {
        _requireCallerIsBOorTMR();
        return _applyPendingRewards(activePool, defaultPool, _borrower);
    }

    // Add the borrowers's coll and debt rewards earned from redistributions, to their Trove
    function _applyPendingRewards(IActivePool _activePool, IDefaultPool _defaultPool, address _borrower) internal {
        if (hasPendingRewards(_borrower)) {
            _requireTroveIsActive(_borrower);

            // Compute pending collateral rewards
            newColls memory pendingCollReward = _getPendingCollRewards(_borrower);
            uint pendingYUSDDebtReward = getPendingYUSDDebtReward(_borrower);

            // Apply pending rewards to trove's state
            Troves[_borrower].colls = _sumColls(Troves[_borrower].colls, pendingCollReward);
            Troves[_borrower].debt = Troves[_borrower].debt.add(pendingYUSDDebtReward);

            _updateTroveRewardSnapshots(_borrower);

            // Transfer from DefaultPool to ActivePool
            _movePendingTroveRewardsToActivePool(_activePool, _defaultPool, pendingYUSDDebtReward, pendingCollReward.tokens, pendingCollReward.amounts, _borrower);

            emit TroveUpdated(
                _borrower,
                Troves[_borrower].debt,
                Troves[_borrower].colls.tokens,
                Troves[_borrower].colls.amounts,
                TroveManagerOperation.applyPendingRewards
            );
        }
    }

    // Update borrower's snapshots of L_Coll and L_YUSDDebt to reflect the current values
    function updateTroveRewardSnapshots(address _borrower) external override {
        _requireCallerIsBorrowerOperations();
        _updateTroveRewardSnapshots(_borrower);
    }

    function _updateTroveRewardSnapshots(address _borrower) internal {
        address[] memory allColls = whitelist.getValidCollateral();
        for (uint i = 0; i < allColls.length; i++) {
            address asset = allColls[i];
            rewardSnapshots[_borrower].CollRewards[asset] = L_Coll[asset];
            rewardSnapshots[_borrower].YUSDDebts[asset] = L_YUSDDebt[asset];
        }
        emit TroveSnapshotsUpdated(block.timestamp);
    }

    // Get the borrower's pending accumulated Coll rewards, earned by their stake
    // Returned tokens and amounts are the length of whitelist.getValidCollateral();;
    function getPendingCollRewards(address _borrower) override external view returns (address[] memory, uint[] memory) {
        newColls memory pendingCollRewards = _getPendingCollRewards(_borrower);
        return (pendingCollRewards.tokens, pendingCollRewards.amounts);
    }

    // Get the borrower's pending accumulated Coll rewards, earned by their stake
    // pendingCollRewards.token and pendingCollRewards.amounts are the length of whitelist.getValidCollateral();
    function _getPendingCollRewards(address _borrower) internal view returns (newColls memory pendingCollRewards) {
        if (Troves[_borrower].status != Status.active) {
            newColls memory emptyColls;
            return emptyColls;
        }

        address[] memory allColls = whitelist.getValidCollateral();
        pendingCollRewards.amounts = new uint[](allColls.length);
        pendingCollRewards.tokens = allColls;
        for (uint i = 0; i < allColls.length; i++ ) {
            address coll = allColls[i];
            uint snapshotCollReward = rewardSnapshots[_borrower].CollRewards[coll];
            uint rewardPerUnitStaked = L_Coll[coll].sub(snapshotCollReward);
            if ( rewardPerUnitStaked == 0) {
                pendingCollRewards.amounts[i] = 0;
                continue; }

            uint stake = Troves[_borrower].stakes[coll];
            uint dec = IERC20(coll).decimals();
            uint assetCollReward = stake.mul(rewardPerUnitStaked).div(10 ** dec);
            pendingCollRewards.amounts[i] = assetCollReward; // i is correct index here
        }
        return pendingCollRewards;
    }

    // Get the borrower's pending accumulated YUSD reward, earned by their stake
    function getPendingYUSDDebtReward(address _borrower) public view override returns (uint pendingYUSDDebtReward) {
        if (Troves[_borrower].status != Status.active) {
            return 0;
        }
        address[] memory allColls = whitelist.getValidCollateral();

        for (uint i = 0; i < allColls.length; i++ ) {
            address coll = allColls[i];
            uint snapshotYUSDDebt = rewardSnapshots[_borrower].YUSDDebts[coll];
            uint rewardPerUnitStaked = L_YUSDDebt[allColls[i]].sub(snapshotYUSDDebt);
            if ( rewardPerUnitStaked == 0) { continue; }

            uint stake =  Troves[_borrower].stakes[coll];

            uint assetYUSDDebtReward = stake.mul(rewardPerUnitStaked).div(DECIMAL_PRECISION);
            pendingYUSDDebtReward = pendingYUSDDebtReward.add(assetYUSDDebtReward);
        }

        return pendingYUSDDebtReward;
    }

    function hasPendingRewards(address _borrower) public view override returns (bool) {
        /*
        * A Trove has pending rewards if its snapshot is less than the current rewards per-unit-staked sum:
        * this indicates that rewards have occured since the snapshot was made, and the user therefore has
        * pending rewards
        */
        if (Troves[_borrower].status != Status.active) {return false;}
        address[] memory assets =  Troves[_borrower].colls.tokens;
        for (uint i = 0; i < assets.length; i++) {
            address token = assets[i];
            if (rewardSnapshots[_borrower].CollRewards[token] < L_Coll[token]) {
                return true;
            }
        }
        return false;
    }

    // Returns debt, collsTokens, collsAmounts, pendingYUSDDebtReward, pendingRewardTokens, pendingRewardAmouns
    function getEntireDebtAndColls(
        address _borrower
    )
    public
    view override
    returns (uint, address[] memory, uint[] memory, uint, address[] memory, uint[] memory)
    {
        uint debt = Troves[_borrower].debt;
        newColls memory colls = Troves[_borrower].colls;

        uint pendingYUSDDebtReward = getPendingYUSDDebtReward(_borrower);
        newColls memory pendingCollReward = _getPendingCollRewards(_borrower);

        debt = debt.add(pendingYUSDDebtReward);

        // add in pending rewards to colls
        colls = _sumColls(colls, pendingCollReward);

        return (debt, colls.tokens, colls.amounts, pendingYUSDDebtReward, pendingCollReward.tokens, pendingCollReward.amounts);
    }

    // Borrower operations remove stake sum. 
    function removeStake(address _borrower) external override {
        _requireCallerIsBorrowerOperations();
        return _removeStake(_borrower);
    }

    // Remove borrower's stake from the totalStakes sum, and set their stake to 0
    function _removeStake(address _borrower) internal {
        address[] memory borrowerColls = Troves[_borrower].colls.tokens;
        for (uint i = 0; i < borrowerColls.length; i++) {
            address coll = borrowerColls[i];
            uint stake = Troves[_borrower].stakes[coll];
            totalStakes[coll] = totalStakes[coll].sub(stake);
            Troves[_borrower].stakes[coll] = 0;
        }
    }

    // Update borrower's stake based on their latest collateral value
    // computed at time function is called based on current price of collateral
    function updateStakeAndTotalStakes(address _borrower) external override {
        _requireCallerIsBOorTMR();
        _updateStakeAndTotalStakes(_borrower);
    }

    function _updateStakeAndTotalStakes(address _borrower) internal {
        for (uint i = 0; i < Troves[_borrower].colls.tokens.length; i++) {
            address token = Troves[_borrower].colls.tokens[i];
            uint amount = Troves[_borrower].colls.amounts[i];

            uint newStake = _computeNewStake(token, amount);
            uint oldStake = Troves[_borrower].stakes[token];

            Troves[_borrower].stakes[token] = newStake;
            totalStakes[token] = totalStakes[token].sub(oldStake).add(newStake);

            emit TotalStakesUpdated(token, totalStakes[token]);
        }
    }

    // Calculate a new stake based on the snapshots of the totalStakes and totalCollateral taken at the last liquidation
    function _computeNewStake(address token, uint _coll) internal view returns (uint) {
        uint stake;
        if (totalCollateralSnapshot[token] == 0) {
            stake = _coll;
        } else {
            /*
            * The following assert() holds true because:
            * - The system always contains >= 1 trove
            * - When we close or liquidate a trove, we redistribute the pending rewards, so if all troves were closed/liquidated,
            * rewards would’ve been emptied and totalCollateralSnapshot would be zero too.
            */
            assert(totalStakesSnapshot[token] > 0);
            stake = _coll.mul(totalStakesSnapshot[token]).div(totalCollateralSnapshot[token]);
        }
        return stake;
    }

    function redistributeDebtAndColl(IActivePool _activePool, IDefaultPool _defaultPool, uint _debt, address[] memory _tokens, uint[] memory _amounts) external override {
        _requireCallerIsTML();
        require(_tokens.length == _amounts.length, "TM: len tokens amounts");
        if (_debt == 0) { return; }
        /*
        * Add distributed coll and debt rewards-per-unit-staked to the running totals. Division uses a "feedback"
        * error correction, to keep the cumulative error low in the running totals L_Coll and L_YUSDDebt:
        *
        * 1) Form numerators which compensate for the floor division errors that occurred the last time this
        * function was called.
        * 2) Calculate "per-unit-staked" ratios.
        * 3) Multiply each ratio back by its denominator, to reveal the current floor division error.
        * 4) Store these errors for use in the next correction when this function is called.
        * 5) Note: static analysis tools complain about this "division before multiplication", however, it is intended.
        */
        uint totalCollateralVC = _getVC(_tokens, _amounts); // total collateral value in VC terms

        for (uint i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            uint amount = _amounts[i];
            // Prorate debt per collateral by dividing each collateral value by cumulative collateral value and multiply by outstanding debt
            uint collateralVC = whitelist.getValueVC(token, amount);
            uint proratedDebtForCollateral = collateralVC.mul(_debt).div(totalCollateralVC);
            uint dec = IERC20(token).decimals();
            uint CollNumerator = amount.mul(10 ** dec).add(lastCollError_Redistribution[token]);
            uint YUSDDebtNumerator = proratedDebtForCollateral.mul(DECIMAL_PRECISION).add(lastYUSDDebtError_Redistribution[token]);
            if (totalStakes[token] > 0) {
                // Get the per-unit-staked terms
                uint CollRewardPerUnitStaked = CollNumerator.div(totalStakes[token]);
                uint YUSDDebtRewardPerUnitStaked = YUSDDebtNumerator.div(totalStakes[token].mul(10 ** (18 - dec)));

                lastCollError_Redistribution[token] = CollNumerator.sub(CollRewardPerUnitStaked.mul(totalStakes[token]));
                lastYUSDDebtError_Redistribution[token] = YUSDDebtNumerator.sub(YUSDDebtRewardPerUnitStaked.mul(totalStakes[token].mul(10 ** (18 - dec))));

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

    function closeTrove(address _borrower) external override {
        _requireCallerIsBorrowerOperations();
        return _closeTrove(_borrower, Status.closedByOwner);
    }

    function closeTroveLiquidation(address _borrower) external override {
        _requireCallerIsTML();
        return _closeTrove(_borrower, Status.closedByLiquidation);
    }

    function closeTroveRedemption(address _borrower) external override {
        _requireCallerIsTMR();
        return _closeTrove(_borrower, Status.closedByRedemption);
    }

    function _closeTrove(address _borrower, Status closedStatus) internal {
        assert(closedStatus != Status.nonExistent && closedStatus != Status.active);

        uint TroveOwnersArrayLength = TroveOwners.length;
        _requireMoreThanOneTroveInSystem(TroveOwnersArrayLength);
        newColls memory emptyColls;

        Troves[_borrower].status = closedStatus;
        Troves[_borrower].colls = emptyColls;
        Troves[_borrower].debt = 0;

        address[] memory allColls = whitelist.getValidCollateral();
        for (uint i = 0; i < allColls.length; i++) {
            rewardSnapshots[_borrower].CollRewards[allColls[i]] = 0;
            rewardSnapshots[_borrower].YUSDDebts[allColls[i]] = 0;
        }

        _removeTroveOwner(_borrower, TroveOwnersArrayLength);
        sortedTroves.remove(_borrower);
    }

    /*
    * Updates snapshots of system total stakes and total collateral, excluding a given collateral remainder from the calculation.
    * Used in a liquidation sequence.
    *
    * The calculation excludes a portion of collateral that is in the ActivePool:
    *
    * the total Coll gas compensation from the liquidation sequence
    *
    * The Coll as compensation must be excluded as it is always sent out at the very end of the liquidation sequence.
    */
    function updateSystemSnapshots_excludeCollRemainder(IActivePool _activePool, address[] memory _tokens, uint[] memory _amounts) external override {
        _requireCallerIsTML();
        for (uint i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            totalStakesSnapshot[token] = totalStakes[token];

            uint _tokenRemainder = _amounts[i];
            uint activeColl = _activePool.getCollateral(token);
            uint liquidatedColl = defaultPool.getCollateral(token);
            totalCollateralSnapshot[token] = activeColl.sub(_tokenRemainder).add(liquidatedColl);
        }
        emit SystemSnapshotsUpdated(block.timestamp);
    }

    // Push the owner's address to the Trove owners list, and record the corresponding array index on the Trove struct
    function addTroveOwnerToArray(address _borrower) external override returns (uint index) {
        _requireCallerIsBorrowerOperations();
        return _addTroveOwnerToArray(_borrower);
    }

    function _addTroveOwnerToArray(address _borrower) internal returns (uint128 index) {
        /* Max array size is 2**128 - 1, i.e. ~3e30 troves. No risk of overflow, since troves have minimum YUSD
        debt of liquidation reserve plus MIN_NET_DEBT. 3e30 YUSD dwarfs the value of all wealth in the world ( which is < 1e15 USD). */
        // Push the Troveowner to the array
        TroveOwners.push(_borrower);

        // Record the index of the new Troveowner on their Trove struct
        index = uint128(TroveOwners.length.sub(1));
        Troves[_borrower].arrayIndex = index;
        return index;
    }

    /*
    * Remove a Trove owner from the TroveOwners array, not preserving array order. Removing owner 'B' does the following:
    * [A B C D E] => [A E C D], and updates E's Trove struct to point to its new array index.
    */
    function _removeTroveOwner(address _borrower, uint TroveOwnersArrayLength) internal {
        Status troveStatus = Troves[_borrower].status;
        // It’s set in caller function `_closeTrove`
        assert(troveStatus != Status.nonExistent && troveStatus != Status.active);

        uint128 index = Troves[_borrower].arrayIndex;
        uint length = TroveOwnersArrayLength;
        uint idxLast = length.sub(1);

        assert(index <= idxLast);

        address addressToMove = TroveOwners[idxLast];

        TroveOwners[index] = addressToMove;
        Troves[addressToMove].arrayIndex = index;
        emit TroveIndexUpdated(addressToMove, index);

        TroveOwners.pop();
    }

    // --- Recovery Mode and TCR functions ---

    function getTCR() external view override returns (uint) {
        return _getTCR();
    }

    function checkRecoveryMode() external view override returns (bool) {
        return _checkRecoveryMode();
    }


    // --- Redemption fee functions ---

    function updateBaseRate(uint newBaseRate) external override {
        _requireCallerIsTMR();
        assert(newBaseRate > 0);
        baseRate = newBaseRate;
        emit BaseRateUpdated(newBaseRate);
        _updateLastFeeOpTime();
    }

    function getRedemptionRate() public view override returns (uint) {
        return _calcRedemptionRate(baseRate);
    }

    function getRedemptionRateWithDecay() public view override returns (uint) {
        return _calcRedemptionRate(calcDecayedBaseRate());
    }

    function _calcRedemptionRate(uint _baseRate) internal pure returns (uint) {
        return LiquityMath._min(
            REDEMPTION_FEE_FLOOR.add(_baseRate),
            DECIMAL_PRECISION // cap at a maximum of 100%
        );
    }

    function _getRedemptionFee(uint _YUSDRedeemed) internal view returns (uint) {
        return _calcRedemptionFee(getRedemptionRate(), _YUSDRedeemed);
    }

    function getRedemptionFeeWithDecay(uint _YUSDRedeemed) external view override returns (uint) {
        return _calcRedemptionFee(getRedemptionRateWithDecay(), _YUSDRedeemed);
    }

    function _calcRedemptionFee(uint _redemptionRate, uint _YUSDRedeemed) internal pure returns (uint) {
        uint redemptionFee = _redemptionRate.mul(_YUSDRedeemed).div(DECIMAL_PRECISION);
        require(redemptionFee < _YUSDRedeemed, "TM:Fee>returned colls");
        return redemptionFee;
    }


    // --- Borrowing fee functions ---

    function getBorrowingRate() public view override returns (uint) {
        return _calcBorrowingRate(baseRate);
    }

    function getBorrowingRateWithDecay() public view override returns (uint) {
        return _calcBorrowingRate(calcDecayedBaseRate());
    }

    function _calcBorrowingRate(uint _baseRate) internal pure returns (uint) {
        return LiquityMath._min(
            BORROWING_FEE_FLOOR.add(_baseRate),
            MAX_BORROWING_FEE
        );
    }

    function getBorrowingFee(uint _YUSDDebt) external view override returns (uint) {
        return _calcBorrowingFee(getBorrowingRate(), _YUSDDebt);
    }

    function getBorrowingFeeWithDecay(uint _YUSDDebt) external view override returns (uint) {
        return _calcBorrowingFee(getBorrowingRateWithDecay(), _YUSDDebt);
    }

    function _calcBorrowingFee(uint _borrowingRate, uint _YUSDDebt) internal pure returns (uint) {
        return _borrowingRate.mul(_YUSDDebt).div(DECIMAL_PRECISION);
    }


    // Updates the baseRate state variable based on time elapsed since the last redemption or YUSD borrowing operation.
    function decayBaseRateFromBorrowing() external override {
        _requireCallerIsBorrowerOperations();

        uint decayedBaseRate = calcDecayedBaseRate();
        assert(decayedBaseRate <= DECIMAL_PRECISION);  // The baseRate can decay to 0

        baseRate = decayedBaseRate;
        emit BaseRateUpdated(decayedBaseRate);

        _updateLastFeeOpTime();
    }


    // --- Internal fee functions ---

    // Update the last fee operation time only if time passed >= decay interval. This prevents base rate griefing.
    function _updateLastFeeOpTime() internal {
        uint timePassed = block.timestamp.sub(lastFeeOperationTime);

        if (timePassed >= SECONDS_IN_ONE_MINUTE) {
            lastFeeOperationTime = block.timestamp;
            emit LastFeeOpTimeUpdated(block.timestamp);
        }
    }

    function calcDecayedBaseRate() public view override returns (uint) {
        uint minutesPassed = _minutesPassedSinceLastFeeOp();
        uint decayFactor = LiquityMath._decPow(MINUTE_DECAY_FACTOR, minutesPassed);

        return baseRate.mul(decayFactor).div(DECIMAL_PRECISION);
    }

    function _minutesPassedSinceLastFeeOp() internal view returns (uint) {
        return (block.timestamp.sub(lastFeeOperationTime)).div(SECONDS_IN_ONE_MINUTE);
    }

    // --- 'require' wrapper functions ---

    function _requireCallerIsBorrowerOperations() internal view {
        require(msg.sender == borrowerOperationsAddress, "TM: must be called by BO");
    }

    function _requireCallerIsBOorTMR() internal view {
        require(msg.sender == borrowerOperationsAddress || msg.sender == troveManagerRedemptionsAddress,
            "TM: Invalid Caller");
    }

    function _requireCallerIsTMR() internal view {
        require(msg.sender == troveManagerRedemptionsAddress,
            "TM: must be called by TMR");
    }

    function _requireCallerIsTML() internal view {
        require(msg.sender == troveManagerLiquidationsAddress,
            "TM: must be called by TML");
    }

    function _requireTroveIsActive(address _borrower) internal view {
        require(Troves[_borrower].status == Status.active, "TM: trove must exist");
    }

    function _requireMoreThanOneTroveInSystem(uint TroveOwnersArrayLength) internal view {
        require (TroveOwnersArrayLength > 1 && sortedTroves.getSize() > 1, "TM: last trove");
    }

    // --- Trove property getters ---

    function getTroveStatus(address _borrower) external view override returns (uint) {
        return uint(Troves[_borrower].status);
    }

    function isTroveActive(address _borrower) external view override returns (bool) {
        return Troves[_borrower].status == Status.active;
    }

    function getTroveStake(address _borrower, address _token) external view override returns (uint) {
        return Troves[_borrower].stakes[_token];
    }

    function getTroveDebt(address _borrower) external view override returns (uint) {
        return Troves[_borrower].debt;
    }

    // -- Trove Manager State Variable Getters -- 

    function getTotalStake(address _token) external view override returns (uint) {
        return totalStakes[_token];
    }

    function getL_Coll(address _token) external view override returns (uint) {
        return L_Coll[_token];
    }

    function getL_YUSD(address _token) external view override returns (uint) {
        return L_YUSDDebt[_token];
    }

    function getRewardSnapshotColl(address _borrower, address _token) external view override returns (uint) {
        return rewardSnapshots[_borrower].CollRewards[_token];
    }

    function getRewardSnapshotYUSD(address _borrower, address _token) external view override returns (uint) {
        return rewardSnapshots[_borrower].YUSDDebts[_token];
    }

    // recomputes VC given current prices and returns it
    function getTroveVC(address _borrower) external view override returns (uint) {
        return _getVCColls(Troves[_borrower].colls);
    }

    function getTroveColls(address _borrower) external view override returns (address[] memory, uint[] memory) {
        return (Troves[_borrower].colls.tokens, Troves[_borrower].colls.amounts);
    }

    function getCurrentTroveState(address _borrower) external override view returns (address[] memory, uint[] memory, uint) {
        (newColls memory colls, uint currentYUSDDebt) = _getCurrentTroveState(_borrower);
        return (colls.tokens, colls.amounts, currentYUSDDebt);
    }

    // --- Called by TroveManagerRedemptions Only ---


    function updateTroveDebt(address _borrower, uint debt) external override {
        _requireCallerIsTMR();
        Troves[_borrower].debt = debt;
    }

    function updateTroveCollTMR(address  _borrower, address[] memory addresses, uint[] memory amounts) external override {
        _requireCallerIsTMR();
        (Troves[_borrower].colls.tokens, Troves[_borrower].colls.amounts) = (addresses, amounts);
    }

    function removeStakeTMR(address _borrower) external override {
        _requireCallerIsTMR();
        _removeStake(_borrower);
    }

    // --- Called by TroverManagerLiquidations Only ---

    function removeStakeTLR(address _borrower) external override {
        _requireCallerIsTML();
        _removeStake(_borrower);
    }

    // --- Trove property setters, called by BorrowerOperations ---

    function setTroveStatus(address _borrower, uint _num) external override {
        _requireCallerIsBorrowerOperations();
        Troves[_borrower].status = Status(_num);
    }

    function updateTroveColl(address _borrower, address[] memory _tokens, uint[] memory _amounts) external override {
        _requireCallerIsBorrowerOperations();
        require(_tokens.length == _amounts.length);
        Troves[_borrower].colls.tokens = _tokens;
        Troves[_borrower].colls.amounts = _amounts;
    }

    function increaseTroveDebt(address _borrower, uint _debtIncrease) external override returns (uint) {
        _requireCallerIsBorrowerOperations();
        uint newDebt = Troves[_borrower].debt.add(_debtIncrease);
        Troves[_borrower].debt = newDebt;
        return newDebt;
    }

    function decreaseTroveDebt(address _borrower, uint _debtDecrease) external override returns (uint) {
        _requireCallerIsBorrowerOperations();
        uint newDebt = Troves[_borrower].debt.sub(_debtDecrease);
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

    function sYETI() external view override returns (ISYETI) {
        return sYETIContract;
    }
 }

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "./Interfaces/ISortedTroves.sol";
import "./Dependencies/SafeMath.sol";
import "./Dependencies/Ownable.sol";
import "./Dependencies/CheckContract.sol";

/*
* A sorted doubly linked list with nodes sorted in descending order.
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
* Changes made in the Liquity implementation:
*
* - Keys have been removed from nodes
*
* - Ordering checks for insertion are performed by comparing an ICR argument to the current ICR, calculated at runtime.
*   The list relies on the property that ordering by ICR is maintained as the Coll:USD price varies.
*
* - Public functions with parameters have been made internal to save gas, and given an external wrapper function for external access
* 
* Changes made in Yeti Finance implementation: 
* Since the nodes are no longer just reliant on the nominal ICR which is just amount of ETH / debt, we now have to use the ICR based 
* on the VC value of the node. This changes with any price change, as the composition of any trove does not stay constant. Therefore 
* the list can easily become stale. This is a compromise that we had to make due to it being too expensive gas wise to keep the list 
* actually sorted by current ICR, as this can change each block. Instead, we keep it ordered by oldICR, and it is instead updated through
* an external function in TroveManager.sol, updateTroves(), and can be called by anyone. This will essentially just update the oldICR and re=insert it 
* into the list. It always remains sorted by oldICR. To then perform redemptions properly, we just allow redemptions to occur for any 
* trove in order of the stale list. However, the redemption amount is in dollar terms so people will always still keep their value, just 
* will lose exposure to the asset. 
* 
*/
contract SortedTroves is Ownable, CheckContract, ISortedTroves {
    using SafeMath for uint256;

    string constant public NAME = "SortedTroves";

    event TroveManagerAddressChanged(address _troveManagerAddress);
    event TroveManagerRedemptionsAddressChanged(address _troveManagerRedemptionsAddress);
    event BorrowerOperationsAddressChanged(address _borrowerOperationsAddress);
    event NodeAdded(address _id, uint _ICR);
    event NodeRemoved(address _id);

    address public borrowerOperationsAddress;
    address public troveManagerRedemptionsAddress;
    address public troveManagerAddress;

    // Information for a node in the list
    struct Node {
        bool exists;
        address nextId;                  // Id of next node (smaller ICR) in the list
        address prevId;                  // Id of previous node (larger ICR) in the list
        uint oldICR;                     // ICR of the node last time it was updated. List is always in order 
                                         // in terms of oldICR . 
    }

    // Information for the list
    struct Data {
        address head;                        // Head of the list. Also the node in the list with the largest ICR
        address tail;                        // Tail of the list. Also the node in the list with the smallest ICR
        uint256 maxSize;                     // Maximum size of the list
        uint256 size;                        // Current size of the list
        mapping (address => Node) nodes;     // Track the corresponding ids for each node in the list
    }

    Data public data;

    // --- Dependency setters ---

    function setParams(uint256 _size, 
        address _troveManagerAddress, 
        address _borrowerOperationsAddress,
        address _troveManagerRedemptionsAddress) 
        external override onlyOwner {
        require(_size > 0, "SortedTroves: Size can’t be zero");
        checkContract(_troveManagerAddress);
        checkContract(_borrowerOperationsAddress);
        checkContract(_troveManagerRedemptionsAddress);

        data.maxSize = _size;

        troveManagerAddress = _troveManagerAddress;
        borrowerOperationsAddress = _borrowerOperationsAddress;
        troveManagerRedemptionsAddress = _troveManagerRedemptionsAddress;

        emit TroveManagerAddressChanged(_troveManagerAddress);
        emit BorrowerOperationsAddressChanged(_borrowerOperationsAddress);
        emit TroveManagerRedemptionsAddressChanged(_troveManagerRedemptionsAddress);

        _renounceOwnership();
    }

    /*
     * @dev Add a node to the list
     * @param _id Node's id
     * @param _ICR Node's _ICR at time of inserting
     * @param _prevId Id of previous node for the insert position
     * @param _nextId Id of next node for the insert position
     */

    function insert(address _id, uint256 _ICR, address _prevId, address _nextId) external override {
        _requireCallerIsBOorTroveM();
        _insert(_id, _ICR, _prevId, _nextId);
    }

    function _insert(address _id, uint256 _ICR, address _prevId, address _nextId) internal {
        // List must not be full
        require(!isFull(), "SortedTroves: List is full");
        // List must not already contain node
        require(!contains(_id), "SortedTroves: List already contains the node");
        // Node id must not be null
        require(_id != address(0), "SortedTroves: Id cannot be zero");
        // ICR must be non-zero
        require(_ICR > 0, "SortedTroves: ICR must be positive");
        address prevId = _prevId;
        address nextId = _nextId;
        if (!_validInsertPosition(_ICR, prevId, nextId)) {
            // Sender's hint was not a valid insert position
            // Use sender's hint to find a valid insert position
            (prevId, nextId) = _findInsertPosition(_ICR, prevId, nextId);
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

        // Update node's ICR
        data.nodes[_id].oldICR = _ICR;

        data.size = data.size.add(1);
        emit NodeAdded(_id, _ICR);
    }

    function remove(address _id) external override {
        _requireCallerIsTroveManager();
        _remove(_id);
    }

    /*
     * @dev Remove a node from the list
     * @param _id Node's id
     */
    function _remove(address _id) internal {
        // List must contain the node
        require(contains(_id), "SortedTroves: List does not contain the id");

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

        data.nodes[_id].oldICR = 0;

        delete data.nodes[_id];
        data.size = data.size.sub(1);
        emit NodeRemoved(_id);
    }

    /*
     * @dev Re-insert the node at a new position, based on its new ICR
     * @param _id Node's id
     * @param _newICR Node's new ICR
     * @param _prevId Id of previous node for the new insert position
     * @param _nextId Id of next node for the new insert position
     */
    function reInsert(address _id, uint256 _newICR, address _prevId, address _nextId) external override {
        _requireCallerIsBOorTroveM();
        // List must contain the node
        require(contains(_id), "SortedTroves: List does not contain the id");
        // ICR must be non-zero
        require(_newICR > 0, "SortedTroves: ICR must be positive");

        // Remove node from the list
        _remove(_id);

        _insert(_id, _newICR, _prevId, _nextId);
    }

    /*
     * @dev Checks if the list contains a node
     */
    function contains(address _id) public view override returns (bool) {
        return data.nodes[_id].exists;
    }

    /*
     * @dev Checks if the list is full
     */
    function isFull() public view override returns (bool) {
        return data.size == data.maxSize;
    }

    /*
     * @dev Checks if the list is empty
     */
    function isEmpty() public view override returns (bool) {
        return data.size == 0;
    }

    /*
     * @dev Returns the current size of the list
     */
    function getSize() external view override returns (uint256) {
        return data.size;
    }

    /*
     * @dev Returns the maximum size of the list
     */
    function getMaxSize() external view override returns (uint256) {
        return data.maxSize;
    }

    /*
     * @dev Returns the first node in the list (node with the largest ICR)
     */
    function getFirst() external view override returns (address) {
        return data.head;
    }

    /*
     * @dev Returns the last node in the list (node with the smallest ICR)
     */
    function getLast() external view override returns (address) {
        return data.tail;
    }

    /*
     * @dev Returns the next node (with a smaller ICR) in the list for a given node
     * @param _id Node's id
     */
    function getNext(address _id) external view override returns (address) {
        return data.nodes[_id].nextId;
    }

    /*
     * @dev Returns the previous node (with a larger ICR) in the list for a given node
     * @param _id Node's id
     */
    function getPrev(address _id) external view override returns (address) {
        return data.nodes[_id].prevId;
    }

    /*
     * @dev get the old ICR of a node
     */
    function getOldICR(address _id) external view override returns (uint256) {
        return data.nodes[_id].oldICR;
    }

    /*
     * @dev Check if a pair of nodes is a valid insertion point for a new node with the given ICR
     * @param _ICR Node's ICR
     * @param _prevId Id of previous node for the insert position
     * @param _nextId Id of next node for the insert position
     */
    function validInsertPosition(uint256 _ICR, address _prevId, address _nextId) external view override returns (bool) {
        return _validInsertPosition(_ICR, _prevId, _nextId);
    }

    // Instead of calculating current ICR using trove manager, we use oldICR values. 
    function _validInsertPosition(uint256 _ICR, address _prevId, address _nextId) internal view returns (bool) {
        if (_prevId == address(0) && _nextId == address(0)) {
            // `(null, null)` is a valid insert position if the list is empty
            return isEmpty();
        } else if (_prevId == address(0)) {
            // `(null, _nextId)` is a valid insert position if `_nextId` is the head of the list
            return data.head == _nextId && _ICR >= data.nodes[_nextId].oldICR;
        } else if (_nextId == address(0)) {
            // `(_prevId, null)` is a valid insert position if `_prevId` is the tail of the list
            return data.tail == _prevId && _ICR <= data.nodes[_prevId].oldICR;
        } else {
            // `(_prevId, _nextId)` is a valid insert position if they are adjacent nodes and `_ICR` falls between the two nodes' ICRs
            return data.nodes[_prevId].nextId == _nextId &&
                   data.nodes[_prevId].oldICR >= _ICR &&
                    _ICR >= data.nodes[_nextId].oldICR;
        }
    }

    /*
     * @dev Descend the list (larger ICRs to smaller ICRs) to find a valid insert position
     * @param _ICR Node's ICR
     * @param _startId Id of node to start descending the list from
     */
    function _descendList(uint256 _ICR, address _startId) internal view returns (address, address) {
        // If `_startId` is the head, check if the insert position is before the head
        if (data.head == _startId && _ICR >= data.nodes[_startId].oldICR) {
            return (address(0), _startId);
        }

        address prevId = _startId;
        address nextId = data.nodes[prevId].nextId;

        // Descend the list until we reach the end or until we find a valid insert position
        while (prevId != address(0) && !_validInsertPosition(_ICR, prevId, nextId)) {
            prevId = data.nodes[prevId].nextId;
            nextId = data.nodes[prevId].nextId;
        }

        return (prevId, nextId);
    }

    /*
     * @dev Ascend the list (smaller ICRs to larger ICRs) to find a valid insert position
     * @param _ICR Node's ICR
     * @param _startId Id of node to start ascending the list from
     */
    function _ascendList(uint256 _ICR, address _startId) internal view returns (address, address) {
        // If `_startId` is the tail, check if the insert position is after the tail
        if (data.tail == _startId && _ICR <= data.nodes[_startId].oldICR) {
            return (_startId, address(0));
        }

        address nextId = _startId;
        address prevId = data.nodes[nextId].prevId;

        // Ascend the list until we reach the end or until we find a valid insertion point
        while (nextId != address(0) && !_validInsertPosition(_ICR, prevId, nextId)) {
            nextId = data.nodes[nextId].prevId;
            prevId = data.nodes[nextId].prevId;
        }

        return (prevId, nextId);
    }

   


    /*
     * @dev Find the insert position for a new node with the given ICR
     * @param _ICR Node's ICR
     * @param _prevId Id of previous node for the insert position
     * @param _nextId Id of next node for the insert position
     */
    function findInsertPosition(uint256 _ICR, address _prevId, address _nextId) external view override returns (address, address) {
        return _findInsertPosition(_ICR, _prevId, _nextId);
    }

    function _findInsertPosition(uint256 _ICR, address _prevId, address _nextId) internal view returns (address, address) {
        address prevId = _prevId;
        address nextId = _nextId;

        if (prevId != address(0)) {
            if (!contains(prevId) || _ICR > data.nodes[prevId].oldICR) {
                // `prevId` does not exist anymore or now has a smaller ICR than the given ICR
                prevId = address(0);
            }
        }

        if (nextId != address(0)) {
            if (!contains(nextId) || _ICR < data.nodes[nextId].oldICR) {
                // `nextId` does not exist anymore or now has a larger ICR than the given ICR
                nextId = address(0);
            }
        }

        if (prevId == address(0) && nextId == address(0)) {
            // No hint - descend list starting from head
            return _descendList(_ICR, data.head);
        } else if (prevId == address(0)) {
            // No `prevId` for hint - ascend list starting from `nextId`
            return _ascendList(_ICR, nextId);
        } else if (nextId == address(0)) {
            // No `nextId` for hint - descend list starting from `prevId`
            return _descendList(_ICR, prevId);
        } else {
            // Descend list starting from `prevId`
            return _descendList(_ICR, prevId);
        }
    }

    // --- 'require' functions ---

    function _requireCallerIsTroveManager() internal view {
        require(msg.sender == troveManagerAddress, "SortedTroves: Caller is not the TroveManager");
    }

    function _requireCallerIsBOorTroveM() internal view {
        require(msg.sender == borrowerOperationsAddress || msg.sender == troveManagerAddress
                || msg.sender == troveManagerRedemptionsAddress,
                "SortedTroves: Caller is neither BO nor TroveM");
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "./Ownable.sol";
import "../Interfaces/IBaseOracle.sol";
import "../Interfaces/IWhitelist.sol";
import "../Interfaces/IPriceFeed.sol";
import "../Interfaces/IPriceCurve.sol";
import "../Interfaces/IActivePool.sol";
import "../Interfaces/IDefaultPool.sol";
import "../Interfaces/IStabilityPool.sol";
import "../Interfaces/ICollSurplusPool.sol";
import "../Interfaces/IERC20.sol";
import "./LiquityMath.sol";
import "./CheckContract.sol";


/**
 * Whitelist is the contract that keeps track of all the assets that the system takes as collateral.
 * It has onlyOwner functions to add or deprecate collaterals from the whitelist, change the price
 * curve, price feed, safety ratio, etc.
 */

contract Whitelist is Ownable, IWhitelist, IBaseOracle, CheckContract {
    using SafeMath for uint256;

    struct CollateralParams {
        // Safety ratio
        uint256 ratio; // 10**18 * the ratio. i.e. ratio = .95 * 10**18 for 95%. More risky collateral has a lower ratio
        address oracle;
        uint256 decimals;
        bool active;
        address priceCurve;
        uint256 index;
        bool isWrapped;
        address defaultRouter;
    }

    IActivePool activePool;
    IDefaultPool defaultPool;
    IStabilityPool stabilityPool;
    ICollSurplusPool collSurplusPool;
    address borrowerOperationsAddress;

    mapping(address => CollateralParams) public collateralParams;

    mapping(address => bool) public validRouter;

    // list of all collateral types in collateralParams (active and deprecated)
    // Addresses for easy access
    address[] public validCollateral; // index maps to token address.

    event CollateralAdded(address _collateral);
    event CollateralDeprecated(address _collateral);
    event CollateralUndeprecated(address _collateral);
    event CollateralRemoved(address _collateral);
    event OracleChanged(address _collateral);
    event PriceCurveChanged(address _collateral);
    event RatioChanged(address _collateral);

    // Require that the collateral exists in the whitelist. If it is not the 0th index, and the
    // index is still 0 then it does not exist in the mapping.
    // no require here for valid collateral 0 index because that means it exists. 
    modifier exists(address _collateral) {
        if (validCollateral.length != 0 && validCollateral[0] != _collateral) {
            require(collateralParams[_collateral].index != 0, "collateral does not exists");
        }
        _;
    }

    // ----------Only Owner Setter Functions----------

    function setAddresses(
        address _activePoolAddress,
        address _defaultPoolAddress,
        address _stabilityPoolAddress,
        address _collSurplusPoolAddress,
        address _borrowerOperationsAddress
    ) external override onlyOwner {
        checkContract(_activePoolAddress);
        checkContract(_defaultPoolAddress);
        checkContract(_stabilityPoolAddress);
        checkContract(_collSurplusPoolAddress);
        checkContract(_borrowerOperationsAddress);

        activePool = IActivePool(_activePoolAddress);
        defaultPool = IDefaultPool(_defaultPoolAddress);
        stabilityPool = IStabilityPool(_stabilityPoolAddress);
        collSurplusPool = ICollSurplusPool(_collSurplusPoolAddress);
        borrowerOperationsAddress = _borrowerOperationsAddress;
    }

    function addCollateral(
        address _collateral,
        uint256 _minRatio,
        address _oracle,
        uint256 _decimals,
        address _priceCurve, 
        bool _isWrapped, 
        address _routerAddress
    ) external onlyOwner {
        checkContract(_collateral);
        checkContract(_oracle);
        checkContract(_priceCurve);
        checkContract(_routerAddress);
        // If collateral list is not 0, and if the 0th index is not equal to this collateral,
        // then if index is 0 that means it is not set yet.
        if (validCollateral.length != 0) {
            require(validCollateral[0] != _collateral && collateralParams[_collateral].index == 0, "collateral already exists");
        }

        validCollateral.push(_collateral);
        collateralParams[_collateral] = CollateralParams(
            _minRatio,
            _oracle,
            _decimals,
            true,
            _priceCurve,
            validCollateral.length - 1, 
            _isWrapped,
            _routerAddress
        );

        activePool.addCollateralType(_collateral);
        defaultPool.addCollateralType(_collateral);
        stabilityPool.addCollateralType(_collateral);
        collSurplusPool.addCollateralType(_collateral);

        // throw event
        emit CollateralAdded(_collateral);
    }

    /**
     * Deprecate collateral by not allowing any more collateral to be added of this type.
     * Still can interact with it via validCollateral and CollateralParams
     */
    function deprecateCollateral(address _collateral) external exists(_collateral) onlyOwner {
        checkContract(_collateral);

        require(collateralParams[_collateral].active, "collateral already deprecated");

        collateralParams[_collateral].active = false;

        // throw event
        emit CollateralDeprecated(_collateral);
    }

    /**
     * Undeprecate collateral by allowing more collateral to be added of this type.
     * Still can interact with it via validCollateral and CollateralParams
     */
    function undeprecateCollateral(address _collateral) external exists(_collateral) onlyOwner {
        checkContract(_collateral);

        require(!collateralParams[_collateral].active, "collateral is already active");

        collateralParams[_collateral].active = true;

        // throw event
        emit CollateralUndeprecated(_collateral);
    }

    /**
     * Function to change oracles
     */
    function changeOracle(address _collateral, address _oracle)
        external
        exists(_collateral)
        onlyOwner
    {
        checkContract(_collateral);
        checkContract(_oracle);
        collateralParams[_collateral].oracle = _oracle;

        // throw event
        emit OracleChanged(_collateral);
    }

    /**
     * Function to change price curve
     */
    function changePriceCurve(address _collateral, address _priceCurve)
        external
        exists(_collateral)
        onlyOwner
    {
        checkContract(_collateral);
        checkContract(_priceCurve);
        uint lastFeePercent;
        uint lastFeeTime; 
        (lastFeePercent, lastFeeTime) = IPriceCurve(collateralParams[_collateral].priceCurve).getFeeCapAndTime();
        IPriceCurve(_priceCurve).setFeeCapAndTime(lastFeePercent, lastFeeTime);
        collateralParams[_collateral].priceCurve = _priceCurve;

        // throw event
        emit PriceCurveChanged(_collateral);
    }

    /**
     * Function to change Safety ratio.
     */
    function changeRatio(address _collateral, uint256 _ratio)
        external
        exists(_collateral)
        onlyOwner
    {
        checkContract(_collateral);
        require(_ratio < 1100000000000000000, "ratio must be less than 1.10 => greater than 1.1 would mean taking out more YUSD than collateral VC");
        require(collateralParams[_collateral].ratio < _ratio, "New SR must be greater than previous SR");
        collateralParams[_collateral].ratio = _ratio;

        // throw event
        emit RatioChanged(_collateral);
    }

    // -----------Routers--------------

    function setDefaultRouter(address _collateral, address _router) external override onlyOwner exists(_collateral) {
        checkContract(_router);
        collateralParams[_collateral].defaultRouter = _router;
    }

    function getDefaultRouterAddress(address _collateral) external view override exists(_collateral) returns (address) {
        return collateralParams[_collateral].defaultRouter;
    }


    // ---------- View Functions -----------


    function isValidRouter(address _router) external override view returns (bool) {
        return validRouter[_router];
    }

    function isWrapped(address _collateral) external view override returns (bool) {
        return collateralParams[_collateral].isWrapped;
    }

    function getValidCollateral() external view override returns (address[] memory) {
        return validCollateral;
    }

    function getRatio(address _collateral)
        public
        view
        override
        exists(_collateral)
        returns (uint256)
    {
        return collateralParams[_collateral].ratio;
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

    function getPriceCurve(address _collateral)
        external
        view
        override
        exists(_collateral)
        returns (address)
    {
        return collateralParams[_collateral].priceCurve;
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
        public
        view
        override
        exists(_collateral)
        returns (uint256)
    {
        return (collateralParams[_collateral].index);
    }

    // Returned as fee percentage * 10**18. View function for external callers.
    function getFee(
        address _collateral,
        uint256 _collateralVCInput,
        uint256 _collateralVCBalancePost,
        uint256 _totalVCBalancePre,
        uint256 _totalVCBalancePost
    ) external view override exists(_collateral) returns (uint256 fee) {
        IPriceCurve priceCurve = IPriceCurve(collateralParams[_collateral].priceCurve);
        return priceCurve.getFee(_collateralVCInput, _collateralVCBalancePost, _totalVCBalancePre, _totalVCBalancePost);
    }

    // Returned as fee percentage * 10**18. Non view function for just borrower operations to call.
    function getFeeAndUpdate(
        address _collateral,
        uint256 _collateralVCInput,
        uint256 _collateralVCBalancePost,
        uint256 _totalVCBalancePre,
        uint256 _totalVCBalancePost
    ) external override exists(_collateral) returns (uint256 fee) {
        require(
            msg.sender == borrowerOperationsAddress,
            "only borrower operations can call this function"
        );
        IPriceCurve priceCurve = IPriceCurve(collateralParams[_collateral].priceCurve);
        return
            priceCurve.getFeeAndUpdate(
                _collateralVCInput,
                _collateralVCBalancePost,
                _totalVCBalancePre,
                _totalVCBalancePost
            );
    }

    // should return 10**18 times the price in USD of 1 of the given _collateral
    function getPrice(address _collateral)
        public
        view
        override
        exists(_collateral)
        returns (uint256)
    {
        IPriceFeed collateral_priceFeed = IPriceFeed(collateralParams[_collateral].oracle);
        uint256 price = collateral_priceFeed.fetchPrice_v();
        return price;
    }

    // Gets the value of that collateral type, of that amount, in USD terms.
    function getValueUSD(address _collateral, uint256 _amount)
        external
        view
        override
        exists(_collateral)
        returns (uint256)
    {
        uint256 decimals = collateralParams[_collateral].decimals;
        uint256 price = getPrice(_collateral);
        return price.mul(_amount).div(10**decimals);
    }

    // Gets the value of that collateral type, of that amount, in VC terms.
    function getValueVC(address _collateral, uint256 _amount)
        public
        view
        override
        exists(_collateral)
        returns (uint256)
    {
        uint256 price = getPrice(_collateral);
        uint256 decimals = collateralParams[_collateral].decimals;
        uint256 ratio = collateralParams[_collateral].ratio;

        // div by 10**18 for price adjustment
        // and divide by 10 ** decimals for decimal adjustment
        return (price.mul(_amount).mul(ratio).div(10**(18 + decimals)));
    }


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

import "./IPriceFeed.sol";


interface ILiquityBase {

    function getEntireSystemDebt() external view returns (uint entireSystemDebt);
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

interface IBaseOracle {
  /// @dev Return the value of the given input as USD per unit.
  /// @param token The ERC-20 token to check the value.
  function getPrice(address token) external view returns (uint);

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

interface IPriceCurve {
    function setAddresses(address _whitelistAddress) external;

    function setDecayTime(uint _decayTime) external;

    /** 
     * Returns fee based on inputted collateral VC balance and total VC balance of system. 
     * fee is in terms of percentage * 1e18. 
     * If the fee were 1%, this would be 0.01 * 1e18 = 1e16
     */
    function getFee(uint256 _collateralVCInput, uint256 _collateralVCBalancePost, uint256 _totalVCBalancePre, uint256 _totalVCBalancePost) external view returns (uint256 fee);

    // Same function, updates the fee as well. Called only by whitelist. 
    function getFeeAndUpdate(uint256 _collateralVCInput, uint256 _totalCollateralVCBalance, uint256 _totalVCBalancePre, uint256 _totalVCBalancePost) external returns (uint256 fee);

    // Function for setting the old price curve's last fee cap / value to the new fee cap / value. 
    // Called only by whitelist. 
    function setFeeCapAndTime(uint256 _lastFeePercent, uint256 _lastFeeTime) external;

    // Gets the fee cap and time currently. Used for setting new values for next price curve. 
    function getFeeCapAndTime() external view returns (uint256 _lastFeePercent, uint256 _lastFeeTime);

    /** 
     * Returns fee based on decay since last fee calculation, which we take to be 
     * a reasonable fee amount. If it has decayed a certain amount since then, we let
     * the new fee amount slide. 
     */
    function calculateDecayedFee() external view returns (uint256 fee);
}
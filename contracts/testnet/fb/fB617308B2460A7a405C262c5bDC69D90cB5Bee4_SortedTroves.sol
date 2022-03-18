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
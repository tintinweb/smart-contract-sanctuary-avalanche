// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "../Interfaces/ISortedTroves.sol";
import "../Dependencies/SafeMath.sol";
import "../Dependencies/Ownable.sol";
import "../Dependencies/CheckContract.sol";

/*
 * Notes from Liquity:
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
 * Changes made compared to the Liquity implementation:
 *
 * - Keys have been removed from nodes
 *
 * - Ordering checks for insertion are performed by comparing an RICR argument to the current RICR, calculated at runtime.
 *   The list relies on the property that ordering by RICR is maintained as the Coll:USD price varies.
 *
 * - Public functions with parameters have been made internal to save gas, and given an external wrapper function for external access
 *
 * Changes made in Yeti Finance implementation:
 * Since the nodes are no longer just reliant on the nominal ICR which is just amount of ETH / debt, we now have to use the RICR based
 * on the RVC value of the node. This changes with any price change, as the composition of any trove does not stay constant. Therefore
 * the list can easily become stale. This is a compromise that we had to make due to it being too expensive gas wise to keep the list
 * actually sorted by current RICR, as this can change each block. Instead, we keep it ordered by oldRICR, and it is instead updated through
 * an external function in TroveManager.sol, updateTroves(), and can be called by anyone. This will essentially just update the oldRICR and re=insert it
 * into the list. It always remains sorted by oldRICR. To then perform redemptions properly, we just allow redemptions to occur for any
 * trove in order of the stale list. However, the redemption amount is in dollar terms so people will always still keep their value, just
 * will lose exposure to the asset.
 *
 * RICR is defined as the Recovery ICR, which is the sum(collaterals * recovery ratio) / total debt
 * This list is sorted by RICR so that redemptions take from troves which have a relatively recovery ratio adjusted ratio. If we sorted
 * by ICR, then the redemptions would always take from the lowest but actually relatively safe troves, such as the ones with purely
 * stablecoin collateral. Since more resistant troves will have higher RICR, this will make them less likely to be redeemed against.
 *
 * SortedTroves is also used to check if there is a trove eligible for liquidation for SP Withdrawal. Technically it can be the case
 * that there is a liquidatable trove which has RICR > 110%, and since it is sorted by RICR it may not be at the bottom.
 * However, this is inherently because these assets are deemed safer, so it is unlikely that there will be a liquidatable trove with
 * RICR > 110% and no troves without a high RICR which are also not liquidatable. If the collateral dropped in value while being
 * hedged with some stablecoins in the trove as well, it is likely that there is another liquidatable trove.
 *
 * As an additional countermeasure, we are adding a liquidatable troves list. This list is intended to keep track of if there are any
 * liquidatable troves in the event of a large usage and gas spike. Since the list is sorted by RICR, it is possible that there are
 * liquidatable troves which are not at the bottom, while the bottom of the list is a trove which has a RICR > 110%. So, this list exists
 * to not break the invariant for knowing if there is a liquidatable trove in order to perform a SP withdrawal. It will be updated by
 * external callers and if the ICR calculated is < 110%, then it will be added to the list. There will be another external function to
 * remove it from the list. Yeti Finance bots will be performing the updating, and since SP withdrawal is the only action that is dependant
 * on this, it is not a problem if it is slow or lagged to clear the list entirely. The SP Withdrawal function will just check the length
 * of the LiquidatableTroves list and see if it is more than 0.
 */
contract SortedTroves is Ownable, CheckContract, ISortedTroves {
    using SafeMath for uint256;

    bytes32 public constant NAME = "SortedTroves";

    event TroveManagerAddressChanged(address _troveManagerAddress);
    event TroveManagerRedemptionsAddressChanged(address _troveManagerRedemptionsAddress);
    event BorrowerOperationsAddressChanged(address _borrowerOperationsAddress);
    event NodeAdded(address _id, uint256 _RICR);
    event NodeRemoved(address _id);
    event LiquidatableTroveAdded(address _id);
    event LiquidatableTroveRemoved(address _id);

    address internal borrowerOperationsAddress;
    address internal troveManagerRedemptionsAddress;
    address internal troveManagerAddress;

    // Information for a node in the list
    struct Node {
        bool exists;
        address nextId; // Id of next node (smaller RICR) in the list
        address prevId; // Id of previous node (larger RICR) in the list
        uint256 oldRICR; // RICR of the node last time it was updated. List is always in order
        // in terms of oldRICR .
    }

    // Information for the list
    struct Data {
        address head; // Head of the list. Also the node in the list with the largest RICR
        address tail; // Tail of the list. Also the node in the list with the smallest RICR
        uint256 maxSize; // Maximum size of the list
        uint256 size; // Current size of the list
        mapping(address => Node) nodes; // Track the corresponding ids for each node in the list
    }

    Data public data;

    mapping(address => bool) public liquidatableTroves;
    uint256 internal liquidatableTrovesSize;

    // --- Dependency setters ---

    function setParams(
        uint256 _size,
        address _troveManagerAddress,
        address _borrowerOperationsAddress,
        address _troveManagerRedemptionsAddress
    ) external override onlyOwner {
        require(_size != 0, "SortedTroves: Size can’t be zero");
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

    /** 
     * @notice Add a node to the list
     * @param _id Node's id
     * @param _RICR Node's _RICR at time of inserting
     * @param _prevId Id of previous node for the insert position
     * @param _nextId Id of next node for the insert position
     */
    function insert(
        address _id,
        uint256 _RICR,
        address _prevId,
        address _nextId
    ) external override {
        _requireCallerIsBOorTroveM();
        _insert(_id, _RICR, _prevId, _nextId);
    }

    function _insert(
        address _id,
        uint256 _RICR,
        address _prevId,
        address _nextId
    ) internal {
        // List must not be full
        require(!isFull(), "SortedTroves: List is full");
        // List must not already contain node
        require(!contains(_id), "SortedTroves: duplicate node");
        // Node id must not be null
        require(_id != address(0), "SortedTroves: Id cannot be zero");
        // RICR must be non-zero
        require(_RICR != 0, "SortedTroves: RICR must be (+)");
        address prevId = _prevId;
        address nextId = _nextId;
        if (!_validInsertPosition(_RICR, prevId, nextId)) {
            // Sender's hint was not a valid insert position
            // Use sender's hint to find a valid insert position
            (prevId, nextId) = _findInsertPosition(_RICR, prevId, nextId);
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

        // Update node's RICR
        data.nodes[_id].oldRICR = _RICR;

        data.size = data.size.add(1);
        emit NodeAdded(_id, _RICR);
    }

    /** 
     * @notice Remove a node to the list
     * @param _id Node's id
     */
    function remove(address _id) external override {
        _requireCallerIsTroveManager();
        _remove(_id);
    }

    /**
     * @notice Remove a node from the list
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
     * @notice Re-insert the node at a new position, based on its new RICR
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
        _requireCallerIsBOorTroveM();
        _reInsert(_id, _newRICR, _prevId, _nextId);
    }

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

        // Remove node from the list
        _remove(_id);

        _insert(_id, _newRICR, _prevId, _nextId);
    }

    /**
     * @notice Re-insert the node at a new position, based on its new RICR
     * @param _ids IDs to reinsert
     * @param _newRICRs new ICRs for all IDs
     * @param _prevIds Ids of previous node for the new insert position
     * @param _nextIds Ids of next node for the new insert position
     */
    function reInsertMany(
        address[] memory _ids,
        uint256[] memory _newRICRs,
        address[] memory _prevIds,
        address[] memory _nextIds
    ) external override {
        _requireCallerIsBOorTroveM();
        uint256 _idsLength = _ids.length;
        for (uint256 i; i < _idsLength; ++i) {
            _reInsert(_ids[i], _newRICRs[i], _prevIds[i], _nextIds[i]);
        }
    }

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
        if (_isLiquidatable) { // If liquidatable and marked not liquidatable, add to list
            if (!liquidatableTroves[_id]) {
                _insertLiquidatableTrove(_id);
            }
        } else { // If not liquidatable and marked liquidatable, remove from list
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

    /**
     * @notice Checks if the list contains a node
     * @return True if list contains node, False if list doesn't contain node
     */
    function contains(address _id) public view override returns (bool) {
        return data.nodes[_id].exists;
    }

    /**
     * @notice Checks if list is full
     * @return True if list is full, False if list isn't full
     */
    function isFull() public view override returns (bool) {
        return data.size == data.maxSize;
    }

    /**
     * @notice Checks if list is empty
     * @return True if list is empty, False if list isn't empty
     */
    function isEmpty() public view override returns (bool) {
        return data.size == 0;
    }

    /**
     * @notice Returns the current size of the list
     * @return Size of list
     */
    function getSize() external view override returns (uint256) {
        return data.size;
    }

    /**
     * @notice Returns the maximum size of the list
     * @return Size of list
     */
    function getMaxSize() external view override returns (uint256) {
        return data.maxSize;
    }

    /**
     * @notice Returns the first node in the list 
     * @dev First node is node with the largest RICR
     * @return Address of node
     */
    function getFirst() external view override returns (address) {
        return data.head;
    }

    /**
     * @notice Returns the last node in the list 
     * @dev First node is node with the smallest RICR
     * @return Address of node
     */
    function getLast() external view override returns (address) {
        return data.tail;
    }

    /**
     * @notice Returns the next node (with a smaller RICR) in the list for a given node
     * @param _id Node's id
     * @return Address of node
     */
    function getNext(address _id) external view override returns (address) {
        return data.nodes[_id].nextId;
    }

    /**
     * @notice Returns the previous node (with a larger RICR) in the list for a given node
     * @param _id Node's id
     * @return Address of node
     */
    function getPrev(address _id) external view override returns (address) {
        return data.nodes[_id].prevId;
    }

    /**
     * @notice Get the old RICR of a node
     * @param _id Node's id
     * @return RICR
     */
    function getOldRICR(address _id) external view override returns (uint256) {
        return data.nodes[_id].oldRICR;
    }

    /** 
     * @notice get the size of liquidatable troves list. 
     * @dev if != 0 then not allowed to withdraw from SP.
     */
    function getLiquidatableTrovesSize() external view override returns (uint256) {
        return liquidatableTrovesSize;
    }

    /**
     * @notice Check if a pair of nodes is a valid insertion point for a new node with the given RICR
     * @param _RICR Node's RICR
     * @param _prevId Id of previous node for the insert position
     * @param _nextId Id of next node for the insert position
     * @return True if insert positon is valid, False if insert position is not valid
     */
    function validInsertPosition(
        uint256 _RICR,
        address _prevId,
        address _nextId
    ) external view override returns (bool) {
        return _validInsertPosition(_RICR, _prevId, _nextId);
    }

    /**
     * @notice Check if a pair of nodes is a valid insertion point for a new node with the given RICR
     * @dev Instead of calculating current RICR using trove manager, we use oldRICR values. 
     * @param _prevId Id of previous node for the insert position
     * @param _nextId Id of next node for the insert position
     */
    function _validInsertPosition(
        uint256 _RICR,
        address _prevId,
        address _nextId
    ) internal view returns (bool) {
        if (_prevId == address(0) && _nextId == address(0)) {
            // `(null, null)` is a valid insert position if the list is empty
            return isEmpty();
        } else if (_prevId == address(0)) {
            // `(null, _nextId)` is a valid insert position if `_nextId` is the head of the list
            return data.head == _nextId && _RICR >= data.nodes[_nextId].oldRICR;
        } else if (_nextId == address(0)) {
            // `(_prevId, null)` is a valid insert position if `_prevId` is the tail of the list
            return data.tail == _prevId && _RICR <= data.nodes[_prevId].oldRICR;
        } else {
            // `(_prevId, _nextId)` is a valid insert position if they are adjacent nodes and `_RICR` falls between the two nodes' RICRs
            return
                data.nodes[_prevId].nextId == _nextId &&
                data.nodes[_prevId].oldRICR >= _RICR &&
                _RICR >= data.nodes[_nextId].oldRICR;
        }
    }

    /**
     * @notice Descend the list (larger RICRs to smaller RICRs) to find a valid insert position
     * @param _RICR Node's RICR
     * @param _startId Id of node to start descending the list from
     */
    function _descendList(uint256 _RICR, address _startId) internal view returns (address, address) {
        // If `_startId` is the head, check if the insert position is before the head
        if (data.head == _startId && _RICR >= data.nodes[_startId].oldRICR) {
            return (address(0), _startId);
        }

        address prevId = _startId;
        address nextId = data.nodes[prevId].nextId;

        // Descend the list until we reach the end or until we find a valid insert position
        while (prevId != address(0) && !_validInsertPosition(_RICR, prevId, nextId)) {
            prevId = data.nodes[prevId].nextId;
            nextId = data.nodes[prevId].nextId;
        }

        return (prevId, nextId);
    }

    /**
     * @notice Ascend the list (smaller RICRs to larger RICRs) to find a valid insert position
     * @param _RICR Node's RICR
     * @param _startId Id of node to start ascending the list from
     */
    function _ascendList(uint256 _RICR, address _startId) internal view returns (address, address) {
        // If `_startId` is the tail, check if the insert position is after the tail
        if (data.tail == _startId && _RICR <= data.nodes[_startId].oldRICR) {
            return (_startId, address(0));
        }

        address nextId = _startId;
        address prevId = data.nodes[nextId].prevId;

        // Ascend the list until we reach the end or until we find a valid insertion point
        while (nextId != address(0) && !_validInsertPosition(_RICR, prevId, nextId)) {
            nextId = data.nodes[nextId].prevId;
            prevId = data.nodes[nextId].prevId;
        }

        return (prevId, nextId);
    }

    /**
     * @notice Find the insert position for a new node with the given RICR
     * @param _RICR Node's RICR
     * @param _prevId Id of previous node for the insert position
     * @param _nextId Id of next node for the insert position
     */
    function findInsertPosition(
        uint256 _RICR,
        address _prevId,
        address _nextId
    ) external view override returns (address, address) {
        return _findInsertPosition(_RICR, _prevId, _nextId);
    }

    function _findInsertPosition(
        uint256 _RICR,
        address _prevId,
        address _nextId
    ) internal view returns (address, address) {
        address prevId = _prevId;
        address nextId = _nextId;

        if (prevId != address(0)) {
            if (!contains(prevId) || _RICR > data.nodes[prevId].oldRICR) {
                // `prevId` does not exist anymore or now has a smaller RICR than the given RICR
                prevId = address(0);
            }
        }

        if (nextId != address(0)) {
            if (!contains(nextId) || _RICR < data.nodes[nextId].oldRICR) {
                // `nextId` does not exist anymore or now has a larger RICR than the given RICR
                nextId = address(0);
            }
        }

        if (prevId == address(0) && nextId == address(0)) {
            // No hint - descend list starting from head
            return _descendList(_RICR, data.head);
        } else if (prevId == address(0)) {
            // No `prevId` for hint - ascend list starting from `nextId`
            return _ascendList(_RICR, nextId);
        } else if (nextId == address(0)) {
            // No `nextId` for hint - descend list starting from `prevId`
            return _descendList(_RICR, prevId);
        } else {
            // Descend list starting from `prevId`
            return _descendList(_RICR, prevId);
        }
    }

    // --- 'require' functions ---

    function _requireCallerIsTroveManager() internal view {
        if (msg.sender != troveManagerAddress) {
            _revertWrongFuncCaller();
        }
    }

    function _requireCallerIsBOorTroveM() internal view {
        if (
            msg.sender != borrowerOperationsAddress &&
            msg.sender != troveManagerAddress &&
            msg.sender != troveManagerRedemptionsAddress
        ) {
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

    function getOldRICR(address _id) external view returns (uint256);

    function getLiquidatableTrovesSize() external view returns (uint256);

    function validInsertPosition(uint256 _ICR, address _prevId, address _nextId) external view returns (bool);

    function findInsertPosition(uint256 _ICR, address _prevId, address _nextId) external view returns (address, address);

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
        @notice Check that the account is an already deployed non-destroyed contract.
        @dev See: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol#L12
        @param _account The address of the account to be checked 
    */
    function checkContract(address _account) internal view {
        require(_account != address(0), "Account cannot be zero address");

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(_account) }
        require(size != 0, "Account code size cannot be zero");
    }
}
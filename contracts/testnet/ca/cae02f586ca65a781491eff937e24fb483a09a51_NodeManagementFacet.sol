// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../libraries/AppStorage.sol";
import "../libraries/LAuthorizable.sol";
import "../libraries/LPausable.sol";
import "../libraries/LRewards.sol";

error NodeManagementFacet__InactiveNode();
error NodeManagementFacet__UnregistredNode();

/// @title NodeManagementFacet
/// @author mektigboy
/// @notice Facet in charge of ...
contract NodeManagementFacet {
    ///////////////////
    /// APP STORAGE ///
    ///////////////////

    AppStorage s;

    //////////////
    /// EVENTS ///
    //////////////

    event NodeCreated(
        address indexed account,
        uint256 amount,
        uint256 timestamp
    );

    event NodeIncreased(
        address indexed account,
        uint256 amount,
        uint256 timestamp
    );

    event NodeMerged(
        address indexed account,
        uint256 sourceTimestamp,
        uint256 destinationTimestamp
    );

    /////////////
    /// LOGIC ///
    /////////////

    /// @notice ...
    /// @param _account User account
    /// @param _name New node name
    /// @param _amount New node amount
    function create(
        address _account,
        string memory _name,
        uint256 _amount
    ) external {
        // LAuthorizable.enforceIsAuthorized(s, msg.sender);
        LPausable.enforceIsUnpaused(s);

        Node memory node;

        node.name = _name;
        node.creation = block.timestamp;
        node.lastClaim = block.timestamp;
        node.lastCompound = block.timestamp;
        node.amount = _amount;
        node.active = true;

        s.userNodes[_account].push(node);

        ++s.tokenCounter;
        ++s.activeNodes;

        s.tvl += _amount;

        emit NodeCreated(_account, _amount, node.creation);
    }

    /// @notice ...
    /// @param _account User account
    /// @param _id Node ID
    /// @param _name New node name
    function rename(
        address _account,
        uint256 _id,
        string memory _name
    ) external {
        LAuthorizable.enforceIsAuthorized(s, msg.sender);

        Node storage node = s.userNodes[_account][_id];

        node.name = _name;
    }

    /// @notice ...
    /// @param _account User account
    /// @param _id Node ID
    /// @param _amount New node amount
    function increase(
        address _account,
        uint256 _id,
        uint256 _amount
    ) external {
        LAuthorizable.enforceIsAuthorized(s, msg.sender);

        Node storage node = s.userNodes[_account][_id];

        if (node.amount == 0) revert NodeManagementFacet__UnregistredNode();

        (, , uint256 rewards) = LRewards.updateRewards(
            s,
            node.lastClaim,
            node.lastCompound,
            node.amount
        );

        node.amount += (_amount + rewards);
        node.lastCompound = block.timestamp;
    }

    /// @notice ...
    /// @param _account User account
    /// @param _id Node ID
    function reactivate(address _account, uint256 _id) external {
        LAuthorizable.enforceIsAuthorized(s, msg.sender);

        Node storage node = s.userNodes[_account][_id];

        if (!node.active) revert NodeManagementFacet__InactiveNode();

        // node.clock = node.clock + 7776000; // 90 days
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

////////////
/// NODE ///
////////////

struct Node {
    string name;
    ///
    uint256 creation;
    uint256 lastClaim;
    uint256 lastCompound;
    ///
    uint256 amount;
    uint256 rewardDebt;
    ///
    bool active;
}

///////////////////
/// APP STORAGE ///
///////////////////

struct AppStorage {
    ////////////////////
    /// AUTHORIZABLE ///
    ////////////////////
    mapping(address => bool) authorized;
    ////////////////
    /// PAUSABLE ///
    ////////////////
    bool paused;
    ///////////////
    /// REWARDS ///
    ///////////////
    uint256 depositFeePercent;
    ///////////////
    /// GENERAL ///
    ///////////////
    address vpnd;
    address rewardsPool;
    address nodeStorage;
    ///
    uint256 tvl;
    uint256 balance;
    uint256 dailyReception;
    uint256 dailySplit;
    mapping(uint256 => uint256) balances;
    mapping(uint256 => uint256) dailyReceptions;
    mapping(uint256 => uint256) dailySplits;
    uint256 transactionId;
    ///////////////////////
    /// NODE MANAGEMENT ///
    ///////////////////////
    mapping(address => Node[]) userNodes;
    /////////////
    /// NODES ///
    /////////////
    uint256 activeNodes;
    mapping(address => bool) alreadyMigrated;
    mapping(uint256 => Node) nodeByTokenId;
    //////////////
    /// ERC721 ///
    //////////////
    string name;
    string symbol;
    uint256 tokenCounter;
    mapping(uint256 => address) ownerOf;
    mapping(address => uint256) balanceOf;
    mapping(uint256 => address) getApproved;
    mapping(address => mapping(address => bool)) isApprovedForAll;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../libraries/AppStorage.sol";

error LAuthorizable__OnlyAuthorized();

/// @title LAuthorizable
/// @author mektigboy
library LAuthorizable {
    /////////////
    /// LOGIC ///
    /////////////

    /// @notice ...
    /// @param s AppStorage
    /// @param _address Address
    function enforceIsAuthorized(AppStorage storage s, address _address)
        internal
        view
    {
        if (!s.authorized[_address]) revert LAuthorizable__OnlyAuthorized();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../libraries/AppStorage.sol";

error LPausable__AlreadyPaused();
error LPausable__AlreadyUnpaused();
error LPausable__PausedFeature();

/// @title LPausable
/// @author mektigboy
library LPausable {
    /////////////
    /// LOGIC ///
    /////////////

    /// @notice ...
    /// @param s AppStorage
    function enforceIsUnpaused(AppStorage storage s) internal view {
        if (s.paused) revert LPausable__PausedFeature();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../libraries/AppStorage.sol";

library LRewards {
    /////////////
    /// LOGIC ///
    /////////////

    /// @notice ...
    /// @param s AppStorage
    function distributeRewards(AppStorage storage s) internal {
        s.dailySplit = s.dailyReception / s.tvl;
        s.dailySplits[s.transactionId] = s.dailySplit;
    }

    /// @notice ...
    /// @param s AppStorage
    /// @param _lastClaim ...
    /// @param _lastCompound ...
    /// @param _amount Node amount
    function updateRewards(
        AppStorage storage s,
        uint256 _lastClaim,
        uint256 _lastCompound,
        uint256 _amount
    )
        internal
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        /// CALCULATION
    }
}
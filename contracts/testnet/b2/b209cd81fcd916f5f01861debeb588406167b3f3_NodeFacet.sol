// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../libraries/AppStorage.sol";
import "../libraries/LAuthorization.sol";

error NodeFacet__InactiveNode();

/// @title NodeFacet
/// @author mektigboy
/// @notice Facet in charge of ...
contract NodeFacet {
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
    /// @param _account ...
    /// @param _name ...
    /// @param _amount ...
    function create(
        address _account,
        string memory _name,
        uint256 _amount
    ) external {
        LAuthorization.enforceIsAuthorized(s, msg.sender);

        Node memory node;

        node.name = _name;
        node.creation = block.timestamp;
        node.lastClaim = block.timestamp;
        node.lastCompound = block.timestamp;
        node.clock = block.timestamp;
        node.amount = _amount;
        node.active = true;

        s.nodes[_account].push(node);

        ++s.nodesCreated;
        ++s.activeNodes;

        s.tvl = _amount;

        emit NodeCreated(_account, _amount, node.creation);
    }

    /// @notice ...
    /// @param _account ...
    /// @param _index Node index
    function reactivate(address _account, uint256 _index) external {
        LAuthorization.enforceIsAuthorized(s, msg.sender);

        Node storage node = s.nodes[_account][_index];

        if (!node.active) revert NodeFacet__InactiveNode();

        node.clock = node.clock + 7776000; // 90 days
    }

    // /// @notice ...
    // /// @param _account ...
    // /// @param _index Node index
    // function claim(address _account, uint256 _index) external {
    //     LAuthorization.enforceIsAuthorized(s, msg.sender);

    //     Node storage node = s.nodes[_account][_index];

    //     // if (node.clock < block.timestamp) {
    //     //     node.active = false;

    //     //     --s.activeNodes;

    //     //     node.pop();

    //     //     revert();
    //     // }
    // }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

////////////
/// NODE ///
////////////

struct Node {
    string name;
    uint256 creation;
    uint256 lastClaim;
    uint256 lastCompound;
    uint256 clock;
    uint256 amount;
    bool active;
}

///////////////////
/// APP STORAGE ///
///////////////////

struct AppStorage {
    ///////////////
    /// GENERAL ///
    ///////////////
    address vpnd;
    address rewardsPool;
    uint256 tvl;
    uint256 balance;
    uint256 dailyReception;
    /////////////////////
    /// AUTHORIZATION ///
    /////////////////////
    mapping(address => bool) authorized;
    ////////////
    /// NODE ///
    ////////////
    mapping(address => Node[]) nodes;
    /////////////
    /// NODES ///
    /////////////
    uint256 nodesCreated;
    uint256 activeNodes;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../libraries/AppStorage.sol";

error LAuthorization__OnlyAuthorized();

/// @title LAuthorization
/// @author mektigboy
library LAuthorization {
    /////////////
    /// LOGIC ///
    /////////////

    /// @notice ...
    /// @param s ...
    /// @param _account ...
    function enforceIsAuthorized(AppStorage storage s, address _account)
        internal
        view
    {
        if (!s.authorized[_account]) revert LAuthorization__OnlyAuthorized();
    }

    /// @notice ...
    /// @param s ...
    /// @param _account ...
    /// @param _value ...
    function updateAuthorized(
        AppStorage storage s,
        address _account,
        bool _value
    ) internal {
        s.authorized[_account] = _value;
    }
}
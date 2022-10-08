// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../libraries/AppStorage.sol";

/// @title NodesFacet
/// @author mektigboy
/// @notice ...
/// @dev ...
contract NodesFacet {
    ///////////////////
    /// APP STORAGE ///
    ///////////////////

    AppStorage s;

    /////////////
    /// LOGIC ///
    /////////////

    function nodesCreated() external view returns (uint256) {
        return s.nodesCreated;
    }

    function activeNodes() external view returns (uint256) {
        return s.activeNodes;
    }
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
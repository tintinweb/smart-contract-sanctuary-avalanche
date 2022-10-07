// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../libraries/AppStorage.sol";

/// @title AuthorizationFacet
/// @author mektigboy
contract AuthorizationFacet {
    ///////////////////
    /// APP STORAGE ///
    ///////////////////

    AppStorage s;

    //////////////
    /// EVENTS ///
    //////////////

    // event Authorized();
    // event Unauthorized();

    /////////////
    /// LOGIC ///
    /////////////

    function authorized(address _address) external view returns (bool) {
        return s.authorized[_address];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

///////////////////
/// NODE ENTITY ///
///////////////////

struct NodeEntity {
    string name;
    uint256 creation;
    uint256 lastClaim;
    uint256 lastCompound;
    uint256 amount;
    bool deleted;
}

///////////////////
/// APP STORAGE ///
///////////////////

struct AppStorage {
    address vpnd;
    address rewardsPool;
    ////////////////////
    /// AUTHORIZABLE ///
    ////////////////////
    mapping(address => bool) authorized;
    ////////////
    /// NODE ///
    ////////////
    mapping(address => NodeEntity[]) nodeEntities;
    mapping(address => bool) migratedWallets;
    ///////////////////////
    /// NODE CONTROLLER ///
    ///////////////////////
    uint256[] boostMultipliers;
    uint256[] boostPeriods;
    uint256[] boostTiers;
    uint256[] compoundRequiredTokens;
    uint256[] compoundMultipliers;
    ///
    uint256 rewardPerNode;
    uint256 minimumTokensRequired;
    uint256 nodesCreated;
    uint256 nodesMigrated;
    uint256 tvl;
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../libraries/AppStorage.sol";
import "../libraries/LPausable.sol";

error ERC721Facet__InexistentAddress();
error ERC721Facet__InexistentMint();
error ERC721Facet__InexistentToken();
error ERC721Facet__InvalidAddress();
error ERC721Facet__InvalidFrom();
error ERC721Facet__Unauthorized();
error ERC721Facet__UnsafeAddress();

/// @title TokenFacet
/// @author mektigboy
/// @author Modified from Solmate: https://github.com/transmissions11/solmate
/// @notice ...
/// @dev ...
contract TokenFacet {
    ///////////////////
    /// APP STORAGE ///
    ///////////////////

    AppStorage s;

    /////////////
    /// LOGIC ///
    /////////////

    /// @notice Get token name
    function name() external view returns (string memory) {
        return s.name;
    }

    /// @notice Get token symbol
    function symbol() external view returns (string memory) {
        return s.symbol;
    }

    /// @notice Get total tokens minted
    function totalSupply() external view returns (uint256) {
        return s.tokenCounter;
    }

    /// @notice Get token URI
    /// @param _id Token ID
    function tokenURI(uint256 _id) external view returns (string memory) {}

    /// @notice Get token balance
    /// @param _account Token owner
    function balanceOf(address _account) external view returns (uint256) {
        if (_account == address(0)) revert ERC721Facet__InexistentAddress();

        return s.balanceOf[_account];
    }

    /// @notice Get token owner
    /// @param _id Token ID
    function ownerOf(uint256 _id) external view returns (address owner_) {
        if ((owner_ = s.ownerOf[_id]) == address(0))
            revert ERC721Facet__InexistentMint();
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
    uint256 depositFee;
    uint256 accumulatedRewardPerShare;
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
    uint256 transactionCounter;
    ///////////////////////
    /// NODE MANAGEMENT ///
    ///////////////////////
    mapping(address => Node[]) usersNodes;
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
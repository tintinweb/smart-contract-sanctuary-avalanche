// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../interfaces/IERC20.sol";
import "../interfaces/IRewardsPool.sol";
import "../libraries/AppStorage.sol";
import "../libraries/LAuthorizable.sol";
import "../libraries/LRewards.sol";

/// @title RewardsPoolFacet
/// @author mektigboy
/// @notice Facet in charge of ...
contract RewardsPoolFacet {
    ///////////////////
    /// APP STORAGE ///
    ///////////////////

    AppStorage s;

    /////////////
    /// LOGIC ///
    /////////////

    function dailyUpdate() external {
        LAuthorizable.enforceIsAuthorized(s, msg.sender);

        s.balance = IERC20(s.vpnd).balanceOf(address(this));
        s.dailyReception = IRewardsPool(s.rewardsPool).dailyEmission();
        s.transactionId = IRewardsPool(s.rewardsPool).transactionId();
        s.balances[s.transactionId] = s.balance;
        s.dailyReceptions[s.transactionId] = s.dailyReception;

        LRewards.distributeRewards(s);
    }

    ///////////////
    /// GETTERS ///
    ///////////////

    /// @notice ...
    function balance() external view returns (uint256) {
        return s.balance;
    }

    /// @notice ...
    function dailyEmission() external view returns (uint256) {
        return s.dailyReception;
    }

    /// @notice ...
    function transactionId() external view returns (uint256) {
        return s.transactionId;
    }

    /// @notice  ...
    /// @param _id Transaction ID
    function balances(uint256 _id) external view returns (uint256) {
        return s.balances[_id];
    }

    /// @notice  ...
    /// @param _id Transaction ID
    function dailyEmissions(uint256 _id) external view returns (uint256) {
        return s.dailyReceptions[_id];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title IERC20
/// @author mektigboy
/// @author Modified from OpenZeppelin: https://github.com/OpenZeppelin/openzeppelin-contracts
/// @dev EIP-20 standard
interface IERC20 {
    //////////////
    /// EVENTS ///
    //////////////

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event Transfer(address indexed from, address indexed to, uint256 value);

    /////////////
    /// LOGIC ///
    /////////////

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title IRewardsPool
/// @author mektigboy
/// @notice ...
/// @dev ...
interface IRewardsPool {
    //////////////
    /// EVENTS ///
    //////////////

    event DailyTransfer();

    /////////////
    /// LOGIC ///
    /////////////

    /// @notice ...
    function transactionId() external view returns (uint256);

    /// @notice ...
    function dailyEmission() external view returns (uint256);

    function updateVaporNodes(address _vaporNodes) external;
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
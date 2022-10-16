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
        s.transactionCounter = IRewardsPool(s.rewardsPool).transactionCounter();
        s.balances[s.transactionCounter] = s.balance;
        s.dailyReceptions[s.transactionCounter] = s.dailyReception;

        LRewards.distributeRewards(s);
    }

    ///////////////
    /// GETTERS ///
    ///////////////

    /// @notice Get 'tvl' value in 'AppStorage'
    function tvl() external view returns (uint256) {
        return s.tvl;
    }

    /// @notice Get 'balance' value in 'AppStorage'
    function balance() external view returns (uint256) {
        return s.balance;
    }

    /// @notice Get 'dailyReception' value in 'AppStorage'
    function dailyReception() external view returns (uint256) {
        return s.dailyReception;
    }

    /// @notice Get 'transactionCounter' value in 'AppStorage'
    function totalTransactions() external view returns (uint256) {
        return s.transactionCounter;
    }

    /// @notice Get 'balances' values in 'AppStorage'
    /// @param _id Transaction ID
    function balances(uint256 _id) external view returns (uint256) {
        return s.balances[_id];
    }

    /// @notice Get 'dailyReceptions' values in 'AppStorage'
    /// @param _id Transaction ID
    function dailyReceptions(uint256 _id) external view returns (uint256) {
        return s.dailyReceptions[_id];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title IERC20
/// @author mektigboy
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
interface IRewardsPool {
    //////////////
    /// EVENTS ///
    //////////////

    event DailyTransfer();

    /////////////
    /// LOGIC ///
    /////////////

    /// @notice ...
    function transactionCounter() external view returns (uint256);

    /// @notice ...
    function dailyEmission() external view returns (uint256);

    function updateVaporNodes(address vaporNodes) external;
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

/// @title LRewards
/// @author mektigboy
library LRewards {
    /////////////
    /// LOGIC ///
    /////////////

    /// @notice Distribute rewards
    /// @param s AppStorage
    function distributeRewards(AppStorage storage s) internal {
        s.dailySplit = (s.dailyReception * 1e18) / s.tvl;
        s.dailySplits[s.transactionCounter] = s.dailySplit;
    }

    /// @notice Update rewards
    /// @param s AppStorage
    function updateRewards(AppStorage storage s)
        internal
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        // s.balance;
        // s.accumulatedRewardsPerShare = accruedReward * 1e18;
    }

    /// @notice Transfer tokens in a safe manner
    function transfer(address _to, uint256 _amount) internal {}
}
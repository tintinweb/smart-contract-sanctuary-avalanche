// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../libraries/AppStorage.sol";
import "../libraries/LCalculator.sol";

/// @title CalculatorFacet
/// @author mektigboy
/// @notice Facet in charge of ...
contract CalculatorFacet {
    ///////////////////
    /// APP STORAGE ///
    ///////////////////

    AppStorage s;

    /////////////
    /// LOGIC ///
    /////////////

    function balance() external view {
        LCalculator.fetchBalance(s);
    }

    function dailyEmission() external view {
        LCalculator.fetchDailyEmission(s);
    }

    // function dailyReception() external returns view (uint256) {
    //     return IERC20(s.vpnd).balanceOf(address(this));
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
import "../interfaces/IERC20.sol";
import "../interfaces/IRewardsPool.sol";

/// @title CalculatorFacet
/// @author mektigboy
/// @notice Facet in charge of ...
library LCalculator {
    /////////////
    /// LOGIC ///
    /////////////

    function fetchBalance(AppStorage storage s)
        internal
        view
        returns (uint256)
    {
        return IERC20(s.vpnd).balanceOf(address(this));
    }

    function fetchDailyEmission(AppStorage storage s)
        external
        view
        returns (uint256)
    {
        return IRewardsPool(s.rewardsPool).dailyEmission();
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

    function dailyEmission() external view returns (uint256);
}
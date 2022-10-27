// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IERC20.sol";
import "./interfaces/IRewardsPoolFacet.sol";

error RewardsPool__InvalidAddress();
error RewardsPool__InvalidValue();
error RewardsPool__NotEnoughTimeHasPassed();
error RewardsPool__OnlyOwner();
error RewardsPool__OnlyAuthorized();

/// @title RewardsPool
/// @author mektigboy
/// @notice Contract in charge of distributing tokens to the diamond contract
/// @dev Utilizes 'IERC20' and 'IRewardsPoolFacet'
contract RewardsPool {
    ///////////////
    /// STORAGE ///
    ///////////////

    address public owner;
    address public vpnd;
    address public vaporNodes;

    mapping(address => bool) authorized;

    uint256 public lastUpdatedTimestamp;

    uint256 public rewardsVelocity;
    uint256 public dailyEmission;
    uint256 public txCounter;

    mapping(uint256 => uint256) public balances;
    mapping(uint256 => uint256) public dailyEmissions;

    /////////////////
    /// MODIFIERS ///
    /////////////////

    modifier onlyOwner() {
        if (owner != msg.sender) revert RewardsPool__OnlyOwner();
        _;
    }

    modifier onlyAuthorized() {
        if (!authorized[msg.sender]) revert RewardsPool__OnlyAuthorized();
        _;
    }

    /////////////
    /// LOGIC ///
    /////////////

    constructor(address _vpnd, address _vaporNodes) {
        owner = msg.sender;
        vpnd = _vpnd;
        vaporNodes = _vaporNodes;
        authorized[msg.sender] = true;
        rewardsVelocity = 270000000000000000;
    }

    function dailyTransfer() external payable onlyAuthorized {
        if (block.timestamp < (lastUpdatedTimestamp + 82800)) revert RewardsPool__NotEnoughTimeHasPassed();

        uint256 currentBalance = balance();

        ++txCounter;

        IERC20(vpnd).transfer(vaporNodes, (currentBalance * rewardsVelocity) / 1e20);

        balances[txCounter] = balance();
        dailyEmission = currentBalance - balance();
        dailyEmissions[txCounter] = dailyEmission;

        IRewardsPoolFacet(vaporNodes).dailyUpdate();

        lastUpdatedTimestamp = block.timestamp;
    }

    ///////////////
    /// GETTERS ///
    ///////////////

    function balance() public view returns (uint256) {
        return IERC20(vpnd).balanceOf(address(this));
    }

    ////////////////
    /// SETTINGS ///
    ////////////////

    function updateVPND(address _vpnd) external onlyOwner {
        vpnd = _vpnd;
    }

    function updateVaporNodes(address _vaporNodes) external onlyOwner {
        vaporNodes = _vaporNodes;
    }

    function updateRewardsVelocity(uint256 _rewardsVelocity) external onlyOwner {
        rewardsVelocity = _rewardsVelocity;
    }

    /////////////////////
    /// AUTHORIZATION ///
    /////////////////////

    function updateAuthorization(address _account, bool _value) external onlyOwner {
        authorized[_account] = _value;
    }

    /////////////////
    /// OWNERSHIP ///
    /////////////////

    function transferOwnership(address _owner) external onlyOwner {
        authorized[msg.sender] = false;
        owner = _owner;
        authorized[owner] = true;
    }

    ////////////////////////////
    /// EMERGENCY WITHDRAWAL ///
    ////////////////////////////

    function emergencyWithdrawal(address _destination) external onlyOwner {
        IERC20(vpnd).transfer(_destination, balance());
    }

    ///////////////
    /// RECEIVE ///
    ///////////////

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title IERC20
/// @author mektigboy
interface IERC20 {
    //////////////
    /// EVENTS ///
    //////////////

    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Transfer(address indexed from, address indexed to, uint256 value);

    /////////////
    /// LOGIC ///
    /////////////

    function allowance(address owner, address spender) external view returns (uint256);

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

/// @title IRewardsPoolFacet
/// @author mektigboy
interface IRewardsPoolFacet {
    /////////////
    /// LOGIC ///
    /////////////

    function dailyUpdate() external;
}
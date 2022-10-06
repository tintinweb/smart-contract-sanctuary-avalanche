// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IERC20.sol";

error RewardsPool__InvalidAddress();
error RewardsPool__InvalidVPNDAddress();
error RewardsPool__InvalidGDMAddress();
error RewardsPool__OnlyAdmin();
error RewardsPool__OnlyOwner();

/// @title RewardsPool
/// @author mektigboy
contract RewardsPool {
    //////////////
    /// EVENTS ///
    //////////////

    event DailyTransfer(); // UPDATE

    event GDMAddressUpdated(); // UPDATE

    event EmergencyWithdrawal(); // UPDATE

    event OwnershipTransferred(); // UPDATE

    event RewardsVelocityUpdated(); // UPDATE

    event TokenAddressUpdated(); // UPDATE

    ///////////////
    /// STORAGE ///
    ///////////////

    uint256 s_creationDate;
    address s_owner;

    /// @notice Is address admin
    mapping(address => bool) s_admin;

    uint256 s_rewardsVelocity; // 0.27

    address s_vpnd;
    address s_gdm;

    uint256 s_transactionId;

    /// @notice Transaction trackers

    /// @dev Transaction ID => Daily Emission
    mapping(uint256 => uint256) s_dailyEmissions;

    /// @dev Transaction ID => Remaining Balance
    mapping(uint256 => uint256) s_balances;

    /////////////////
    /// MODIFIERS ///
    /////////////////

    modifier onlyOwner() {
        if (s_owner != msg.sender) revert RewardsPool__OnlyOwner();
        _;
    }

    modifier onlyAdmin() {
        if (!s_admin[msg.sender]) revert RewardsPool__OnlyAdmin();
        _;
    }

    /////////////
    /// LOGIC ///
    /////////////

    constructor(address _vpnd, address _gdm) {
        s_creationDate = block.timestamp;
        s_owner = msg.sender;
        s_admin[s_owner] = true;
        s_rewardsVelocity = 270000000000000000; // 0.27
        s_vpnd = _vpnd;
        s_gdm = _gdm;
    }

    function updateTokenAddress(address _vpnd) external onlyOwner {
        s_vpnd = _vpnd;

        emit TokenAddressUpdated();
    }

    function updateGDMAddress(address _gdm) external onlyOwner {
        s_gdm = _gdm;

        emit GDMAddressUpdated();
    }

    function updateRewardsVelocity(uint256 _rewardsVelocity)
        external
        onlyOwner
    {
        s_rewardsVelocity = _rewardsVelocity;

        emit RewardsVelocityUpdated();
    }

    //////////////////
    /// AUTOMATION ///
    //////////////////

    function dailyTransfer()
        external
        /* payable */
        onlyAdmin
    {
        if (s_vpnd == address(0)) revert RewardsPool__InvalidVPNDAddress();

        if (s_gdm == address(0)) revert RewardsPool__InvalidGDMAddress();

        ++s_transactionId;

        IERC20(s_vpnd).transfer(s_gdm, dailyEmission());

        s_dailyEmissions[s_transactionId] = dailyEmission();
        s_balances[s_transactionId] = balance();

        emit DailyTransfer();
    }

    ///////////////
    /// GETTERS ///
    ///////////////

    function balance() public view returns (uint256) {
        return IERC20(s_vpnd).balanceOf(address(this));
    }

    // 200000000000000000000000000 - 200,000,000
    // ---------270000000000000000 - 0.27
    // ------100000000000000000000 - 100
    // ---540000000000000000000000 - 540,000

    /// @notice (200000000000000000000000000 x 270000000000000000) / 100000000000000000000 = 540000000000000000000000
    function dailyEmission() public view returns (uint256) {
        return (balance() * s_rewardsVelocity) / 1e20;
    }

    function dailyEmissions(uint256 _transactionId)
        public
        view
        returns (uint256)
    {
        return s_dailyEmissions[_transactionId];
    }

    function balances(uint256 _transactionId)
        public
        view
        returns (uint256)
    {
        return s_balances[_transactionId];
    }

    //////////////
    /// ADMINS ///
    //////////////

    function addAdmin(address _newAdmin) external onlyOwner {
        s_admin[_newAdmin] = true;
    }

    function deleteAdmin(address _admin) external onlyOwner {
        s_admin[_admin] = false;
    }

    /////////////////
    /// OWNERSHIP ///
    /////////////////

    function transferOwnership(address _owner) external onlyOwner {
        if (_owner == address(0)) revert RewardsPool__InvalidAddress();

        s_admin[s_owner] = false;
        s_owner = _owner;
        s_admin[s_owner] = true;

        emit OwnershipTransferred();
    }

    ////////////////////////////
    /// EMERGENCY WITHDRAWAL ///
    ////////////////////////////

    /// @notice Transfer tokens to specific address in case of emergency
    function emergencyWithdrawal(address _destination) external onlyOwner {
        if (_destination == address(0)) revert RewardsPool__InvalidAddress();

        IERC20(s_vpnd).transfer(_destination, balance());

        emit EmergencyWithdrawal();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title IERC20
/// @author mektigboy
/// @author Modified from OpenZeppelin: https://github.com/OpenZeppelin/openzeppelin-contracts
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

    /////////////////
    /// FUNCTIONS ///
    /////////////////

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
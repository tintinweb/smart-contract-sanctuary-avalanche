// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error Replenishment__Unauthorized();
error Replenishment__BalanceTooLow();
error Replenishment__InvalidAddress();
error Replenishment__InvalidRewardsRate();
error Replenishment__TooEarly();
error Replenishment__RecoverFailed();

/// @title Replenishment Pool
/// @notice Replenishment contract
/// @dev Utilizes 'Ownable' and 'IERC20'
contract ReplenishmentPool is Ownable {
    //////////////
    /// EVENTS ///
    //////////////

    event DailyTransfer(uint256 amount);

    ///////////////////////
    /// PRIVATE STORAGE ///
    ///////////////////////

    IERC20 immutable s_vpnd;
    address s_rewardsPool;
    address s_gelato;
    uint256 s_lastUpdated;
    uint256 s_rewardsRate;

    //////////////////////
    /// PUBLIC STORAGE ///
    //////////////////////

    uint256 public constant REWARDS_PRECISION = 100_000; // 1 = 0.001%
    uint256 public immutable deployment;

    ///////////////////
    /// CONSTRUCTOR ///
    ///////////////////

    constructor(address _vpnd, address _rewardsPool, address _owner) {
        if (_vpnd == address(0) || _rewardsPool == address(0) || _owner == address(0)) {
            revert Replenishment__InvalidAddress();
        }

        deployment = block.timestamp;

        s_lastUpdated = deployment;
        s_rewardsRate = 135; // 0.135%
        s_vpnd = IERC20(_vpnd);
        s_rewardsPool = _rewardsPool;
        _transferOwnership(_owner);
    }

    //////////////////////
    /// EXTERNAL LOGIC ///
    //////////////////////

    /// @notice Daily transfer VPND tokens to Rewards Pool
    /// @notice Only callable by Gelato
    function dailyTransfer() external {
        if (msg.sender != s_gelato) revert Replenishment__Unauthorized();

        if (block.timestamp < (s_lastUpdated + 82800)) revert Replenishment__TooEarly(); // After 23 hours

        uint256 currentBalance = s_vpnd.balanceOf(address(this));
        if (currentBalance < 1e18) revert Replenishment__BalanceTooLow();

        s_lastUpdated = block.timestamp;

        uint256 vpndAmountToTransfer = (currentBalance * s_rewardsRate) / REWARDS_PRECISION;

        s_vpnd.transfer(s_rewardsPool, vpndAmountToTransfer);

        emit DailyTransfer(vpndAmountToTransfer);
    }

    ////////////////
    /// SETTINGS ///
    ////////////////

    /// @notice Update rewards rate
    /// @param _rewardsRate New rewards rate
    function updateRewardsRate(uint256 _rewardsRate) external onlyOwner {
        if (_rewardsRate == 0) revert Replenishment__InvalidRewardsRate();

        s_rewardsRate = _rewardsRate;
    }

    /// @notice Update Gelato address
    /// @param _newGelato New Gelato address
    function updateGelato(address _newGelato) external onlyOwner {
        if (_newGelato == address(0)) revert Replenishment__InvalidAddress();

        s_gelato = _newGelato;
    }

    /// @notice Update Rewards Pool address
    /// @param _newRewardsPool New Rewards Pool address
    function updateRewardsPool(address _newRewardsPool) external onlyOwner {
        if (_newRewardsPool == address(0)) revert Replenishment__InvalidAddress();

        s_rewardsPool = _newRewardsPool;
    }

    //////////////////////////
    /// EMERGENCY RECOVERY ///
    //////////////////////////

    /// @notice Recover native tokens
    /// @param _amount Amount of native tokens to recover
    function recoverNative(uint256 _amount) external onlyOwner {
        (bool success, ) = payable(owner()).call{ value: _amount }("");
        if (!success) revert Replenishment__RecoverFailed();
    }

    /// @notice Recover ERC20 tokens
    /// @param _token Address of ERC20 token
    /// @param _amount Amount of ERC20 tokens to recover
    function recoverERC20(address _token, uint256 _amount) external onlyOwner {
        bool success = IERC20(_token).transfer(owner(), _amount);
        if (!success) revert Replenishment__RecoverFailed();
    }

    ///////////////
    /// GETTERS ///
    ///////////////

    /// @notice Get the address of VPND
    function vpnd() public view returns (address) {
        return address(s_vpnd);
    }

    /// @notice Get the address of Rewards Pool
    function rewardsPool() public view returns (address) {
        return s_rewardsPool;
    }

    /// @notice Get the current balance of VPND tokens
    function vpndBalance() public view returns (uint256) {
        return s_vpnd.balanceOf(address(this));
    }

    /// @notice Get the time stamp of the last update
    function lastUpdated() public view returns (uint256) {
        return s_lastUpdated;
    }

    /// @notice Get the address of Gelato
    function gelato() public view returns (address) {
        return s_gelato;
    }

    /// @notice Get the rewards rate
    function rewardsRate() public view returns (uint256) {
        return s_rewardsRate;
    }
}
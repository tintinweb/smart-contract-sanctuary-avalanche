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

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;
/**
 * @title esVIBMiner is a stripped down version of Synthetix StakingRewards.sol, to reward esVIB to VUSD minters.
 * Differences from the original contract,
 * - Get `totalStaked` from totalSupply() in contract VUSD.
 * - Get `stakedOf(user)` from getBorrowedOf(user) in contract VUSD.
 * - When an address borrowed VUSD amount changes, call the refreshReward method to update rewards to be claimed.
 */

import "./IVibranium.sol";
import "./Ownable.sol";
import "./IesVIB.sol";

interface Ihelper {
    function getCollateralRate(address user) external view returns (uint256);
}

interface IvibraniumFund {
    function refreshReward(address user) external;
}

interface IesVIBBoost {
    function getUserBoost(
        address user,
        uint256 userUpdatedAt,
        uint256 finishAt
    ) external view returns (uint256);

    function getUnlockTime(address user)
        external
        view
        returns (uint256 unlockTime);
}

contract esVIBMinerV2 is Ownable {
    IVibranium public immutable vibranium;
    Ihelper public helper;
    IesVIBBoost public esVIBBoost;
    IvibraniumFund public vibraniumFund;
    address public esVIB;

    // Duration of rewards to be paid out (in seconds)
    uint256 public duration = 2_592_000;
    // Timestamp of when the rewards finish
    uint256 public finishAt;
    // Minimum of last updated time and reward finish time
    uint256 public updatedAt;
    // Reward to be paid out per second
    uint256 public rewardRate;
    // Sum of (reward rate * dt * 1e18 / total supply)
    uint256 public rewardPerTokenStored;
    // User address => rewardPerTokenStored
    mapping(address => uint256) public userRewardPerTokenPaid;
    // User address => rewards to be claimed
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public userUpdatedAt;
    uint256 public extraRate = 50 * 1e18;
    // Currently, the official rebase time for Lido is between 12PM to 13PM UTC.
    uint256 public lockdownPeriod = 12 hours;

    constructor(
        address _vibranium,
        address _helper,
        address _boost,
        address _fund
    ) {
        vibranium = IVibranium(_vibranium);
        helper = Ihelper(_helper);
        esVIBBoost = IesVIBBoost(_boost);
        vibraniumFund = IvibraniumFund(_fund);
    }

    function setEsVIB(address _esVIB) external onlyOwner {
        esVIB = _esVIB;
    }

    function setExtraRate(uint256 rate) external onlyOwner {
        extraRate = rate;
    }

    function setLockdownPeriod(uint256 _time) external onlyOwner {
        lockdownPeriod = _time;
    }

    function setBoost(address _boost) external onlyOwner {
        esVIBBoost = IesVIBBoost(_boost);
    }

    function setVibraniumFund(address _fund) external onlyOwner {
        vibraniumFund = IvibraniumFund(_fund);
    }

    function setRewardsDuration(uint256 _duration) external onlyOwner {
        require(finishAt < block.timestamp, "reward duration not finished");
        duration = _duration;
    }

    function totalStaked() internal view returns (uint256) {
        return vibranium.totalSupply();
    }

    function stakedOf(address user) public view returns (uint256) {
        return vibranium.getBorrowedOf(user);
    }

    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        updatedAt = lastTimeRewardApplicable();

        if (_account != address(0)) {
            rewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
            userUpdatedAt[_account] = block.timestamp;
        }

        _;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return _min(finishAt, block.timestamp);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalStaked() == 0) {
            return rewardPerTokenStored;
        }

        return
            rewardPerTokenStored +
            (rewardRate * (lastTimeRewardApplicable() - updatedAt) * 1e18) /
            totalStaked();
    }

    /**
     * @dev To limit the behavior of arbitrageurs who mint a large amount of vUSD after stETH rebase and before vUSD interest distribution to earn extra profit,
     * a 1-hour revert during stETH rebase is implemented to eliminate this issue.
     * If the user's collateral ratio is below safeCollateralRate, they are not subject to this restriction.
     */
    function pausedByLido(address _account) public view returns(bool) {
        uint256 collateralRate = helper.getCollateralRate(_account);
        return (block.timestamp - lockdownPeriod) % 1 days < 1 hours &&
            collateralRate >= vibranium.safeCollateralRate();
    }

    /**
     * @notice Update user's claimable reward data and record the timestamp.
     */
    function refreshReward(address _account) external updateReward(_account) {
        if (
            pausedByLido(_account)
        ) {
            revert(
                "Minting and repaying functions of vUSD are temporarily disabled during stETH rebasing periods."
            );
        }
    }

    function getBoost(address _account) public view returns (uint256) {
        uint256 redemptionBoost;
        if (vibranium.isRedemptionProvider(_account)) {
            redemptionBoost = extraRate;
        }
        return 100 * 1e18 + redemptionBoost + esVIBBoost.getUserBoost(
            _account,
            userUpdatedAt[_account],
            finishAt
        );
    }

    function earned(address _account) public view returns (uint256) {
        return
            ((stakedOf(_account) *
                getBoost(_account) *
                (rewardPerToken() - userRewardPerTokenPaid[_account])) / 1e38) +
            rewards[_account];
    }

    function getReward() external updateReward(msg.sender) {
        require(
            block.timestamp >= esVIBBoost.getUnlockTime(msg.sender),
            "Your lock-in period has not ended. You can't claim your esVIB now."
        );
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            vibraniumFund.refreshReward(msg.sender);
            IesVIB(esVIB).mint(msg.sender, reward);
        }
    }

    function notifyRewardAmount(uint256 amount)
        external
        onlyOwner
        updateReward(address(0))
    {
        require(amount > 0, "amount = 0");
        if (block.timestamp >= finishAt) {
            rewardRate = amount / duration;
        } else {
            uint256 remainingRewards = (finishAt - block.timestamp) *
                rewardRate;
            rewardRate = (amount + remainingRewards) / duration;
        }

        require(rewardRate > 0, "reward rate = 0");

        finishAt = block.timestamp + duration;
        updatedAt = block.timestamp;
    }

    function _min(uint256 x, uint256 y) private pure returns (uint256) {
        return x <= y ? x : y;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

interface IesVIB {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function mint(address user, uint256 amount) external returns(bool);
    function burn(address user, uint256 amount) external returns(bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

interface IVibranium {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function totalDepositedEther() external view returns (uint256);

    function safeCollateralRate() external view returns (uint256);

    function redemptionFee() external view returns (uint256);

    function keeperRate() external view returns (uint256);

    function depositedEther(address user) external view returns (uint256);

    function getBorrowedOf(address user) external view returns (uint256);

    function isRedemptionProvider(address user) external view returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function transferShares(
        address _recipient,
        uint256 _sharesAmount
    ) external returns (uint256);

    function getSharesByMintedVUSD(
        uint256 _VUSDAmount
    ) external view returns (uint256);

    function getMintedVUSDByShares(
        uint256 _sharesAmount
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
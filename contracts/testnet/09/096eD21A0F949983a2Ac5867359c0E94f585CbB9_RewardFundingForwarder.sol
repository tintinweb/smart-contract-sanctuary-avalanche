// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IArcanaChef {
    function rewardsToken() external view returns (address);

    function addReward(uint256 amount) external;

    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);
}

/**
 * @author shung for Arcanum
 * @notice
 *
 * Funder -> RewardFundingForwarder -> ArcanaChef
 *               OR
 * Funder -> RewardFundingForwarder -> ArcanumStakingPositions
 *
 * Funder is any contract that was written for Synthetix' StakingRewards, or for MiniChef.
 * RewardFundingForwarder provides compatibility for these old funding contracts.
 */
contract RewardFundingForwarder {
    IArcanaChef public immutable arcanaChef;
    address public immutable rewardsToken;
    bytes32 private constant FUNDER_ROLE = keccak256("FUNDER_ROLE");

    modifier onlyFunder() {
        require(arcanaChef.hasRole(FUNDER_ROLE, msg.sender), "unauthorized");
        _;
    }

    constructor(address newArcanaChef) {
        require(newArcanaChef.code.length != 0, "empty contract");
        address newRewardsToken = IArcanaChef(newArcanaChef).rewardsToken();
        IERC20(newRewardsToken).approve(newArcanaChef, type(uint256).max);
        arcanaChef = IArcanaChef(newArcanaChef);
        rewardsToken = newRewardsToken;
    }

    function notifyRewardAmount(uint256 amount) external onlyFunder {
        arcanaChef.addReward(amount);
    }

    function fundRewards(uint256 amount, uint256) external {
        addReward(amount);
    }

    function addReward(uint256 amount) public onlyFunder {
        IERC20(rewardsToken).transferFrom(msg.sender, address(this), amount);
        arcanaChef.addReward(amount);
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
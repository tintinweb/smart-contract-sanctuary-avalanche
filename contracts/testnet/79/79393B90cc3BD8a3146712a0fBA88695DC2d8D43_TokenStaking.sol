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
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenStaking {
    struct Stake {
        address staker;
        IERC20 token;
        uint256 amount;
        uint256 start;
        uint256 duration;
    }

    event StakeDeposit(
        address indexed _from,
        bytes32 indexed _id,
        uint256 _value
    );

    event EtherDeposit(address indexed _from, uint256 _value);

    mapping(bytes32 => Stake) public stakes;
    uint256 public rewardRate = 100;
    IERC20 public rewardToken;
    mapping(address => uint256) public rewardTokenBalance;

    constructor(address _rewardToken) {
        rewardToken = IERC20(_rewardToken);
    }

    function stake(
        IERC20 token,
        uint256 amount,
        uint256 duration
    ) external returns (bytes32) {
        require(duration >= 30 days, "Duration must be at least 30 days");
        require(amount >= 500000, "Minimum 5 tokens required");

        bytes32 id = keccak256(
            abi.encodePacked(msg.sender, token, block.timestamp)
        );

        token.transferFrom(msg.sender, address(this), amount);
        stakes[id] = Stake({
            staker: msg.sender,
            token: token,
            amount: amount,
            start: block.timestamp,
            duration: duration
        });

        emit StakeDeposit(msg.sender, id, amount);
        return id;
    }

    function unstake(bytes32 id) external {
        Stake memory _stake = stakes[id];
        require(_stake.staker == msg.sender, "Unauthorized unstake");
        uint256 amount = _stake.amount;
        uint256 reward = calculateReward(id);

        delete stakes[id];

        rewardTokenBalance[address(this)] -= reward;
        require(
            rewardTokenBalance[address(this)] >= 0,
            "Insufficient reward token balance"
        );

        IERC20(_stake.token).transfer(msg.sender, amount + reward);
    }

    function calculateReward(bytes32 id) public view returns (uint256) {
        Stake memory _stake = stakes[id];

        uint256 duration = block.timestamp - _stake.start;
        if (duration < 30 days) {
            return 0;
        }

        uint256 reward = (_stake.amount * rewardRate * (duration / (1 days)));
        return reward;
    }

    function withdrawRewardToken(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(
            rewardTokenBalance[address(this)] >= amount,
            "Insufficient reward token balance"
        );

        rewardTokenBalance[address(this)] -= amount;
        require(
            rewardToken.transfer(msg.sender, amount),
            "Reward token transfer failed"
        );
    }

    fallback() external {
        revert("Invalid function signature");
    }

    receive() external payable {
        revert("Not Enough data to start Staking");
    }
}
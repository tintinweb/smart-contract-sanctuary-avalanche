/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-15
*/

pragma solidity 0.5.17;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() public {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}
pragma solidity 0.5.17;

/**
 * @title ERC 20 Token Standard Interface
 *  https://eips.ethereum.org/EIPS/eip-20
 */
interface EIP20Interface {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    /**
      * @notice Get the total number of tokens in circulation
      * @return The supply of tokens
      */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return The balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return Whether or not the transfer succeeded
      */
    function transfer(address dst, uint256 amount) external returns (bool success);

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return Whether or not the transfer succeeded
      */
    function transferFrom(address src, address dst, uint256 amount) external returns (bool success);

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved (-1 means infinite)
      * @return Whether or not the approval succeeded
      */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return The number of tokens allowed to be spent (-1 means infinite)
      */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}
pragma solidity 0.5.17;

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/Math.sol
// Subject to the MIT license.

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting with custom message on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts with custom message on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
pragma solidity 0.5.17;


contract bardiStakingContractProxyStorage {
    // Current contract admin address
    address public admin;

    // Requested new admin for the contract
    address public pendingAdmin;

    // Current contract implementation address
    address public implementation;

    // Requested new contract implementation address
    address public pendingImplementation;
}
pragma solidity 0.5.17;


contract bardiStakingContractProxy is ReentrancyGuard, bardiStakingContractProxyStorage {
    constructor() public {
        admin = msg.sender;
    }

    /**
     * Request a new admin to be set for the contract.
     *
     * @param newAdmin New admin address
     */
    function setPendingAdmin(address newAdmin) public adminOnly {
        pendingAdmin = newAdmin;
    }

    /**
     * Accept admin transfer from the current admin to the new.
     */
    function acceptPendingAdmin() public {
        require(msg.sender == pendingAdmin && pendingAdmin != address(0), "Caller must be the pending admin");

        admin = pendingAdmin;
        pendingAdmin = address(0);
    }

    /**
     * Request a new implementation to be set for the contract.
     *
     * @param newImplementation New contract implementation contract address
     */
    function setPendingImplementation(address newImplementation) public adminOnly {
        pendingImplementation = newImplementation;
    }

    /**
     * Accept pending implementation change
     */
    function acceptPendingImplementation() public {
        require(msg.sender == pendingImplementation && pendingImplementation != address(0), "Only the pending implementation contract can call this");

        implementation = pendingImplementation;
        pendingImplementation = address(0);
    }

    function () payable external {
        (bool success, ) = implementation.delegatecall(msg.data);

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize)

            switch success
            case 0 { revert(free_mem_ptr, returndatasize) }
            default { return(free_mem_ptr, returndatasize) }
        }
    }

    /********************************************************
     *                                                      *
     *                      MODIFIERS                       *
     *                                                      *
     ********************************************************/

    modifier adminOnly {
        require(msg.sender == admin, "admin only");
        _;
    }
}

pragma solidity 0.5.17;




contract bardiStakingContractStorage is bardiStakingContractProxyStorage {
    uint constant nofStakingRewards = 2;
    uint constant REWARD_AVAX = 0;
    uint constant REWARD_QI = 1;

    // QI-AVAX bardi token contract address
    address public bardiTokenAddress;

    // Addresses of the ERC20 reward tokens
    mapping(uint => address) public rewardTokenAddresses;

    // Reward accrual speeds per reward token as tokens per second
    mapping(uint => uint) public rewardSpeeds;

    // Unclaimed staking rewards per user and token
    mapping(address => mapping(uint => uint)) public accruedReward;

    // Supplied bardi tokens per user
    mapping(address => uint) public supplyAmount;

    // Sum of all supplied bardi tokens
    uint public totalSupplies;

    /*
     * rewardIndex keeps track of the total amount of rewards to be distributed for
     * each supplied unit of bardi tokens. When used together with supplierIndex,
     * the total amount of rewards to be paid out to individual users can be calculated
     * when the user claims their rewards.
     *
     * Consider the following:
     *
     * At contract deployment, the contract has a zero bardi balance. Immediately, a new
     * user, User A, deposits 1000 bardi tokens, thus increasing the total supply to
     * 1000 bardi. After 60 seconds, a second user, User B, deposits an additional 500 bardi,
     * increasing the total supplied amount to 1500 bardi.
     *
     * Because all balance-changing contract calls, as well as those changing the reward
     * speeds, must invoke the accrueRewards function, these deposit calls trigger the
     * function too. The accrueRewards function considers the reward speed (denoted in
     * reward tokens per second), the reward and supplier reward indexes, and the supply
     * balance to calculate the accrued rewards.
     *
     * When User A deposits their tokens, rewards are yet to be accrued due to previous
     * inactivity; the elapsed time since the previous, non-existent, reward-accruing
     * contract call is zero, thus having a reward accrual period of zero. The block
     * time of the deposit transaction is saved in the contract to indicate last
     * activity time.
     *
     * When User B deposits their tokens, 60 seconds has elapsed since the previous
     * call to the accrueRewards function, indicated by the difference of the current
     * block time and the last activity time. In other words, up till the time of
     * User B's deposit, the contract has had a 60 second accrual period for the total
     * amount of 1000 bardi tokens at the set reward speed. Assuming a reward speed of
     * 5 tokens per second (denoted 5 T/s), the accrueRewards function calculates the
     * accrued reward per supplied unit of bardi tokens for the elapsed time period.
     * This works out to ((5 T/s) / 1000 bardi) * 60 s = 0.3 T/bardi during the 60 second
     * period. At this point, the global reward index variable is updated, increasing
     * its value by 0.3 T/bardi, and the reward accrual block timestamp,
     * initialised in the previous step, is updated.
     *
     * After 90 seconds of the contract deployment, User A decides to claim their accrued
     * rewards. Claiming affects token balances, thus requiring an invocation of the
     * accrueRewards function. This time, the accrual period is 30 seconds (90 s - 60 s),
     * for which the reward accrued per unit of bardi is ((5 T/s) / 1500 bardi) * 30 s = 0.1 T/bardi.
     * The reward index is updated to 0.4 T/bardi (0.3 T/bardi + 0.1 T/bardi) and the reward
     * accrual block timestamp is set to the current block time.
     *
     * After the reward accrual, User A's rewards are claimed by transferring the correct
     * amount of T tokens from the contract to User A. Because User A has not claimed any
     * rewards yet, their supplier index is zero, the initial value determined by the
     * global reward index at the time of the user's first deposit. The amount of accrued
     * rewards is determined by the difference between the global reward index and the
     * user's own supplier index; essentially, this value represents the amount of
     * T tokens that have been accrued per supplied bardi during the time since the user's
     * last claim. User A has a supply balance of 1000 bardi, thus having an unclaimed
     * token amount of (0.4 T/bardi - 0 T/bardi) * 1000 bardi = 400 T. This amount is
     * transferred to User A, and their supplier index is set to the current global reward
     * index to indicate that all previous rewards have been accrued.
     *
     * If User B was to claim their rewards at the same time, the calculation would take
     * the form of (0.4 T/bardi - 0.3 T/bardi) * 500 bardi = 50 T. As expected, the total amount
     * of accrued reward (5 T/s * 90 s = 450 T) equals to the sum of the rewards paid
     * out to both User A and User B (400 T + 50 T = 450 T).
     *
     * This method of reward accrual is used to minimise the contract call complexity.
     * If a global mapping of users to their accrued rewards was implemented instead of
     * the index calculations, each function call invoking the accrueRewards function
     * would become immensely more expensive due to having to update the rewards for each
     * user. In contrast, the index approach allows the update of only a single user
     * while still keeping track of the other's rewards.
     *
     * Because rewards can be paid in multiple assets, reward indexes, reward supplier
     * indexes, and reward speeds depend on the StakingReward token.
     */
    mapping(uint => uint) public rewardIndex;
    mapping(address => mapping(uint => uint)) public supplierRewardIndex;
    uint public accrualBlockTimestamp;
}

pragma solidity 0.5.17;

contract bardiStakingContract is  bardiStakingContractStorage {
    using SafeMath for uint256;

    constructor() public {
        admin = msg.sender;
    }


    /********************************************************
     *                                                      *
     *                   PUBLIC FUNCTIONS                   *
     *                                                      *
     ********************************************************/

    /**
     * Deposit Pangolin QI-AVAX liquidity provider tokens into the staking contract.
     *
     * @param bardiAmount The amount of bardi tokens to deposit
     */
    function deposit(uint bardiAmount) external  {
        require(bardiTokenAddress != address(0), "bardi Token address can not be zero");

        EIP20Interface bardiToken = EIP20Interface(bardiTokenAddress);
        uint contractBalance = bardiToken.balanceOf(address(this));
        bardiToken.transferFrom(msg.sender, address(this), bardiAmount);
        uint depositedAmount = bardiToken.balanceOf(address(this)).sub(contractBalance);

        require(depositedAmount > 0, "Zero deposit");

        distributeReward(msg.sender);

        totalSupplies = totalSupplies.add(depositedAmount);
        supplyAmount[msg.sender] = supplyAmount[msg.sender].add(depositedAmount);
    }

    /**
     * Redeem deposited bardi tokens from the contract.
     *
     * @param bardiAmount Redeem amount
     */
    function redeem(uint bardiAmount) external  {
        require(bardiTokenAddress != address(0), "bardi Token address can not be zero");
        require(bardiAmount <= supplyAmount[msg.sender], "Too large withdrawal");

        distributeReward(msg.sender);

        supplyAmount[msg.sender] = supplyAmount[msg.sender].sub(bardiAmount);
        totalSupplies = totalSupplies.sub(bardiAmount);

        EIP20Interface bardiToken = EIP20Interface(bardiTokenAddress);
        bardiToken.transfer(msg.sender, bardiAmount);
    }

    /**
     * Claim pending rewards from the staking contract by transferring them
     * to the requester.
     */
    function claimRewards() external {
        distributeReward(msg.sender);

        for (uint i = 0; i < nofStakingRewards; i += 1) {
            uint amount = accruedReward[msg.sender][i];

            if (i == REWARD_AVAX) {
                claimAvax(msg.sender, amount);
            } else {
                claimErc20(i, msg.sender, amount);
            }
        }
    }

    /**
     * Get the current amount of available rewards for claiming.
     *
     * @param rewardToken Reward token whose claimable balance to query
     * @return Balance of claimable reward tokens
     */
    function getClaimableRewards(uint rewardToken) external view returns(uint) {
        require(rewardToken <= nofStakingRewards, "Invalid reward token");

        uint rewardIndexDelta = rewardIndex[rewardToken].sub(supplierRewardIndex[msg.sender][rewardToken]);
        uint claimableReward = rewardIndexDelta.mul(supplyAmount[msg.sender]).div(1e36).add(accruedReward[msg.sender][rewardToken]);

        return claimableReward;
    }

    /**
     * Fallback function to accept AVAX deposits.
     */
    function () external payable {}


    /********************************************************
     *                                                      *
     *               ADMIN-ONLY FUNCTIONS                   *
     *                                                      *
     ********************************************************/

    /**
     * Set reward distribution speed.
     *
     * @param rewardToken Reward token speed to change
     * @param speed New reward speed
     */
    function setRewardSpeed(uint rewardToken, uint speed) external adminOnly {
        if (accrualBlockTimestamp != 0) {
            accrueReward();
        }

        rewardSpeeds[rewardToken] = speed;
    }

    /**
     * Set ERC20 reward token contract address.
     *
     * @param rewardToken Reward token address to set
     * @param rewardTokenAddress New contract address
     */
    function setRewardTokenAddress(uint rewardToken, address rewardTokenAddress) external adminOnly {
        require(rewardToken != REWARD_AVAX, "Cannot set AVAX address");
        rewardTokenAddresses[rewardToken] = rewardTokenAddress;
    }

    /**
     * Set QI-AVAX bardi token contract address.
     *
     * @param newBardiTokenAddress New QI-AVAX bardi token contract address
     */
    function setBardiTokenAddress(address newBardiTokenAddress) external adminOnly {
        bardiTokenAddress = newBardiTokenAddress;
    }

    /**
     * Accept this contract as the implementation for a proxy.
     *
     * @param proxy bardiStakingContractProxy
     */
    function becomeImplementation(bardiStakingContractProxy proxy) external {
        require(msg.sender == proxy.admin(), "Only proxy admin can change the implementation");
        proxy.acceptPendingImplementation();
    }


    /********************************************************
     *                                                      *
     *                  INTERNAL FUNCTIONS                  *
     *                                                      *
     ********************************************************/

    /**
     * Update reward accrual state.
     *
     * @dev accrueReward() must be called every time the token balances
     *      or reward speeds change
     */
    function accrueReward() internal {
        uint blockTimestampDelta = block.timestamp.sub(accrualBlockTimestamp);
        accrualBlockTimestamp = block.timestamp;

        if (blockTimestampDelta == 0 || totalSupplies == 0) {
            return;
        }

        for (uint i = 0; i < nofStakingRewards; i += 1) {
            uint rewardSpeed = rewardSpeeds[i];
            if (rewardSpeed == 0) {
                continue;
            }

            uint accrued = rewardSpeeds[i].mul(blockTimestampDelta);
            uint accruedPerBardi = accrued.mul(1e36).div(totalSupplies);

            rewardIndex[i] = rewardIndex[i].add(accruedPerBardi);
        }
    }

    /**
     * Calculate accrued rewards for a single account based on the reward indexes.
     *
     * @param recipient Account for which to calculate accrued rewards
     */
    function distributeReward(address recipient) internal {
        accrueReward();

        for (uint i = 0; i < nofStakingRewards; i += 1) {
            uint rewardIndexDelta = rewardIndex[i].sub(supplierRewardIndex[recipient][i]);
            uint accruedAmount = rewardIndexDelta.mul(supplyAmount[recipient]).div(1e36);
            accruedReward[recipient][i] = accruedReward[recipient][i].add(accruedAmount);
            supplierRewardIndex[recipient][i] = rewardIndex[i];
        }
    }

    /**
     * Transfer AVAX rewards from the contract to the reward recipient.
     *
     * @param recipient Address, whose AVAX rewards are claimed
     * @param amount The amount of claimed AVAX
     */
    function claimAvax(address payable recipient, uint amount) internal {
        require(accruedReward[recipient][REWARD_AVAX] <= amount, "Not enough accrued rewards");

        accruedReward[recipient][REWARD_AVAX] = accruedReward[recipient][REWARD_AVAX].sub(amount);
        recipient.transfer(amount);
    }

    /**
     * Transfer ERC20 rewards from the contract to the reward recipient.
     *
     * @param rewardToken ERC20 reward token which is claimed
     * @param recipient Address, whose rewards are claimed
     * @param amount The amount of claimed reward
     */
    function claimErc20(uint rewardToken, address recipient, uint amount) internal {
        require(rewardToken != REWARD_AVAX, "Cannot use claimErc20 for AVAX");
        require(accruedReward[recipient][rewardToken] <= amount, "Not enough accrued rewards");
        require(rewardTokenAddresses[rewardToken] != address(0), "reward token address can not be zero");

        EIP20Interface token = EIP20Interface(rewardTokenAddresses[rewardToken]);
        accruedReward[recipient][rewardToken] = accruedReward[recipient][rewardToken].sub(amount);
        token.transfer(recipient, amount);
    }


    /********************************************************
     *                                                      *
     *                      MODIFIERS                       *
     *                                                      *
     ********************************************************/

    modifier adminOnly {
        require(msg.sender == admin, "admin only");
        _;
    }
}
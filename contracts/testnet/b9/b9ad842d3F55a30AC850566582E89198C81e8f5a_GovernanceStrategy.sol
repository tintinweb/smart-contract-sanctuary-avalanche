// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./interfaces/IGovernanceStrategy.sol";
import "../interfaces/ILotteryToken.sol";
import "../interfaces/ILotteryGameToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Governance Strategy contract
 * @dev Smart contract containing logic to measure users' relative power to propose and vote.
 * User Power = User Power from Lotto Token + User Power from Game Lotto Token.
 **/
contract GovernanceStrategy is IGovernanceStrategy {
    address public lottoAddress;
    address public gameLottoAddress;

    /**
     * @dev Constructor, register tokens used for Power.
     * @param lotto The address of the Lotto Token contract.
     * @param gLotto The address of the gLotto Token Contract
     **/
    constructor(address lotto, address gLotto) {
        lottoAddress = lotto;
        gameLottoAddress = gLotto;
    }

    /**
     * @dev Returns the total supply of Proposition Tokens Available for Governance
     * Voting supply will be equal Lotto supply. Cause the supply of Game lotto will be equal
     * to the locked in the staking contract lotto tokens
     * @return total supply
     **/
    function getTotalVotingSupply() public view override returns (uint256) {
        return IERC20(lottoAddress).totalSupply();
    }

    /**
     * @dev Returns the Vote Power of a user.
     * @param user Address of the user.
     * @param blockTimestamp target timestamp
     * @return lottoPower lotto vote number
     * @return gamePower game vote number
     * @return totalVotingPower total vote number
     **/
    function getVotingPowerAt(address user, uint256 blockTimestamp)
        public
        view
        override
        returns (
            uint256 lottoPower,
            uint256 gamePower,
            uint256 totalVotingPower
        )
    {
        lottoPower = ILotteryToken(lottoAddress).getVotingPowerAt(
            user,
            blockTimestamp
        );
        gamePower = ILotteryGameToken(gameLottoAddress).getVotingPowerAt(
            user,
            blockTimestamp
        );
        totalVotingPower = lottoPower + gamePower;
    }
}

// SPDX-License-Identifier:MIT
pragma solidity 0.8.9;

interface IGovernanceStrategy {
    /**
     * @dev Returns the total supply of Outstanding Voting Tokens
     **/
    function getTotalVotingSupply() external view returns (uint256);

    /**
     * @dev Returns the Vote Power of a user for a specific block timestamp.
     * @param user Address of the user.
     * @param blockTimestamp target timestamp
     * @return lottoPower lotto vote number
     * @return gamePower game vote number
     * @return totalVotingPower total vote number
     **/
    function getVotingPowerAt(address user, uint256 blockTimestamp)
        external
        view
        returns (
            uint256 lottoPower,
            uint256 gamePower,
            uint256 totalVotingPower
        );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/// @title Defined interface for LotteryToken contract
interface ILotteryToken {
    ///@notice struct to store detailed info about the lottery
    struct Lottery {
        uint256 id;
        uint256 participationFee;
        uint256 startedAt;
        uint256 finishedAt;
        uint256 participants;
        address[] winners;
        uint256 epochId;
        uint256[] winningPrize;
        uint256 rewards;
        address rewardPool;
        bool isActive;
    }

    ///@notice struct to store info about fees and participants in each epoch
    struct Epoch {
        uint256 totalFees;
        uint256 minParticipationFee;
        uint256 firstLotteryId;
        uint256 lastLotteryId;
    }

    ///@notice struct to store info about user balance based on the last game id interaction
    struct UserBalance {
        uint256 lastGameId;
        uint256 balance;
        uint256 at;
    }

    /// @notice A checkpoint for marking historical number of votes from a given block timestamp
    struct Snapshot {
        uint256 blockTimestamp;
        uint256 votes;
    }

    /// @dev store info about whitelisted address to dismiss auto-charge lotto tokens from this address
    /// @param isWhitelisted whitelisted account or not
    /// @param lastParticipatedGameId the last game in which user auto participate
    struct WhiteLlistedInfo {
        bool isWhitelisted;
        uint256 lastParticipatedGameId;
    }

    /// @notice Emit when voting power of 'account' is changed to 'newVotes'
    /// @param account address of user whose voting power is changed
    /// @param newVotes new amount of voting power for 'account'
    event VotingPowerChanged(address account, uint256 newVotes);

    /// @notice Emit when reward pool is changed
    /// @param rewardPool address of new reward pool
    event RewardPoolChanged(address rewardPool);

    /// @notice Emit when addresses added to the whitelist
    /// @param accounts address of wallets to store in whitelist
    /// @param lastExistedGameId last game id existed in lotteries array
    event AddedToWhitelist(address[] accounts, uint256 lastExistedGameId);

    /// @notice Emit when wallets deleted from the whitelist
    /// @param accounts address of wallets to delete from whitelist
    event DeletedFromWhiteList(address[] accounts);

    /// @notice Getter for address of reward pool
    /// @return address of reward distribution contract
    function rewardPool() external view returns (address);

    /// @notice disable transfers
    /// @dev can be called by lottery game contract only
    function lockTransfer() external;

    /// @notice enable transfers
    /// @dev can be called by lottery game contract only
    function unlockTransfer() external;

    /// @dev start new game
    /// @param _participationFee amount of tokens needed to participaint in the game
    function startLottery(uint256 _participationFee)
        external
        returns (Lottery memory startedLottery);

    /// @dev finish game
    /// @param _participants count of participants
    /// @param _winnerAddresses address of winner
    /// @param _marketingAddress marketing address
    /// @param _winningPrizeValues amount of winning prize in tokens
    /// @param _marketingFeeValue amount of marketing fee in tokens
    /// @param _rewards amount of community and governance rewards
    function finishLottery(
        uint256 _participants,
        address[] memory _winnerAddresses,
        address _marketingAddress,
        uint256[] memory _winningPrizeValues,
        uint256 _marketingFeeValue,
        uint256 _rewards
    ) external returns (Lottery memory finishedLotteryGame);

    /// @notice Set address of reward pool to accumulate governance and community rewards at
    /// @dev Can be called only by lottery game contract
    /// @param _rewardPool address of reward distribution contract
    function setRewardPool(address _rewardPool) external;

    /// @notice Force finish of game with id <lotteryId>
    /// @param lotteryId id of lottery game to be needed shut down
    function forceFinish(uint256 lotteryId) external;

    /// @dev Returns last lottery
    function lastLottery() external view returns (Lottery memory lottery);

    /// @dev Returns last epoch
    function lastEpoch() external view returns (Epoch memory epoch);

    /// @dev Return voting power of the 'account' at the specific period of time 'blockTimestamp'
    /// @param account address to check voting power for
    /// @param blockTimestamp timestamp in second to check voting power at
    function getVotingPowerAt(address account, uint256 blockTimestamp)
        external
        view
        returns (uint256);

    /// @notice added accounts to whitelist
    /// @dev owner should be a governance
    /// @param accounts addresses of accounts that will be added to wthitelist
    function addToWhitelist(address[] memory accounts) external;

    /// @notice delete accounts from whitelist
    /// @dev owner should be a governance
    /// @param accounts addresses of accounts that will be deleted from wthitelist
    function deleteFromWhitelist(address[] memory accounts) external;

    /// @notice get totalSypply of tokens
    /// @dev used only in CustomLotteryGame
    function getTotalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ILotteryGameToken {
    /// @notice A checkpoint for marking historical number of votes from a given block timestamp
    struct Snapshot {
        uint256 blockTimestamp;
        uint256 votes;
    }

    /// @notice Emit when voting power of 'account' is changed to 'newVotes'
    /// @param account address of user whose voting power is changed
    /// @param newVotes new amount of voting power for 'account'
    event VotingPowerChanged(address indexed account, uint256 newVotes);

    /// @notice Mint 'amount' of tokens for the 'account'
    /// @param account address of the user to mint tokens for
    /// @param amount amount of minted tokens
    function mint(address account, uint256 amount) external;

    /// @notice Burn 'amount' of tokens for the 'account'
    /// @dev Can be burn only allowed address. User can't burn his tokens by hisself
    /// @param account address of the user to burn tokens for
    /// @param amount amount of burned tokens
    function burn(address account, uint256 amount) external;

    /// @dev Return voting power of the 'account' at the specific period of time 'blockTimestamp'
    /// @param account address to check voting power for
    /// @param blockTimestamp timestamp in second to check voting power at
    function getVotingPowerAt(address account, uint256 blockTimestamp)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}
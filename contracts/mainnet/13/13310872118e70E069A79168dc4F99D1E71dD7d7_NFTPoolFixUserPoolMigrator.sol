// SPDX-License-Identifier: MIT LICENSE
pragma solidity =0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./PreyPredator.sol";
import "./IEntropy.sol";
import "../../Controllable.sol";
import "./NFTPoolNG.sol";
import "../../utils/MyPausable.sol";
import "../../interfaces/IBasisAsset.sol";
import "../../interfaces/ITreasury.sol";

contract NFTPoolFixUserPoolMigrator is Controllable, IERC721Receiver, MyPausable {
    using SafeERC20 for IERC20;

    struct Stake {
        uint256 tokenId;
        address owner;
    }

    struct UserStake {
        uint256 lastTimestamp;
        uint256 preyStaked;
        uint256 predatorsStaked;
        // barn staking
        uint256 lastRewardPerPrey;
        uint256 claimableBarnReward;
        // pack staking
        uint256 claimablePackReward;
        uint256 stakedAlpha;
        uint256 lastRewardPerAlpha;
    }

    struct UserInfo {
        UserStake gladshare;
        UserStake glad;
    }

    // Mapping, weights, scores
    // Translates the alpha index of a Predator to effective Alpha
    uint256[] alphaIndexToAlphaLUT = [100, 120, 140, 160, 180];

    mapping(address => UserInfo) public userPool;

    // reference to the PreyPredator NFT contract
    PreyPredator public preyPredator;
    // reference to the reward token contract for minting earnings (GLAD)
    IBasisAsset public glad;
    // reference to the reward token contract for minting earnings (GLADSHARE)
    IBasisAsset public gladshare;
    // reference to Entropy
    IEntropy entropy;
    // reference to Treasury
    ITreasury public treasury;

    uint256 mySeed;

    // maps tokenId to stake
    Stake[] public barn;
    // tracks location of each Prey in Barn
    mapping(uint256 => uint256) public barnIndices;

    // maps alpha to all Predator stakes with that alpha
    mapping(uint256 => Stake[]) public pack;
    // tracks location of each Predator in Pack
    mapping(uint256 => uint256) public packIndices;

    mapping(uint256 => uint256) public lastActivity;
    mapping(uint256 => bool) public stakedForGshare;

    // total alpha scores staked
    uint256 public totalAlphaStakedForGshare;
    //
    uint256 public totalPredatorsStakedForGshare;
    // any rewards distributed when no predators are staked
    uint256 public unaccountedRewardsForGshare;

    // last timestamp of rewardperprey/rewardperalpha
    uint256 public lastTimestampForGshare;

    // amount of total Reward due for each prey point staked
    uint256 public totalGshareRewardPerPrey;

    // amount of total Reward due for each alpha point staked
    uint256 public totalGshareRewardPerAlpha;

    // number of Prey staked for GLADSHARE in the Barn
    uint256 public totalPreyStakedForGshare;

    // total alpha scores staked
    uint256 public totalAlphaStakedForGlad;
    //
    uint256 public totalPredatorsStakedForGlad;
    // any rewards distributed when no predators are staked
    uint256 public unaccountedRewardsForGlad;

    // last timestamp of rewardperprey/rewardperalpha
    uint256 public lastTimestampForGlad;

    // amount of total Reward due for each prey point staked
    uint256 public totalGladRewardPerPrey;

    // amount of total Reward due for each alpha point staked
    uint256 public totalGladRewardPerAlpha;

    // number of Prey staked for GLAD in the Barn
    uint256 public totalPreyStakedForGlad;

    uint256 public constant PERIOD = 180 days;
    uint256 public REWARS_PER_PREY_PER_PERIOD = 15000 ether; // 15,000 GLADSHARE

    uint256 public STEALCHANCE_PREDATOR_UNSTAKE = 10;
    uint256 public STEALCHANCE_PREY_UNSTAKE = 20;
    // predators take a 20% tax on all $Reward claimed
    uint256 public REWARD_CLAIM_TAX_PERCENTAGE = 20;

    uint256 public LOCK_EPOCH = 6;

    uint256 public pendingGladReward;

    // staking start timestamp
    uint256 public stakingStart;

    // staking end timestamp
    uint256 public stakingEnd;

    // deadline for claiming
    //uint256 public claimDeadline;


    // whiltelist of who can use the random endpoints
    // contracts who need to pick random owners need to be added
     mapping(address => bool) randomWhitelist;

    // emergency rescue to allow unstaking without any checks but without $Reward
    bool public rescueEnabled = false;

    address public migrationContract;
    uint256 public migrationIndex;

    NFTPoolNG public oldPool;

    mapping(address => bool) userMigrated;

    bool public canMigrate;

    uint256 public preyLoadIndex;
    bool public preyLoaded;
    uint256[5] public predatorLoadIndex;
    bool[5] public predatorLoaded;
    bool public parametersLoaded;
    bool public nftsMigrated;

    mapping(uint256 => address) tokenOwners;


    event TokenStaked(
        address indexed owner,
        uint256 indexed tokenId,
        bool isForGshare,
        bool isPrey
    );
    event TokenClaimed(uint256 indexed tokenId, bool isPrey);
    event BarnRewardClaimed(
        address indexed user,
        bool isForGshare,
        uint256 amount,
        uint256 tax
    );
    event PackRewardClaimed(
        address indexed user,
        bool isForGshare,
        uint256 amount
    );
    event UserStakeChange(address indexed user, UserStake gladshare, UserStake glad);
    event TokenSwitched(address indexed user, uint256 indexed tokenId);


    function migrateParams()  external onlyOwner {
        require(canMigrate, "Migration no longer possible");
        //require(!parametersLoaded, "Params already migrated");
        // pendingGladReward = oldPool.pendingGladReward();
        // totalGladRewardPerAlpha = oldPool.totalGladRewardPerAlpha();
        // totalGladRewardPerPrey = oldPool.totalGladRewardPerPrey();
        // lastTimestampForGlad = oldPool.lastTimestampForGlad();
        // unaccountedRewardsForGlad = oldPool.unaccountedRewardsForGlad();
        // totalGshareRewardPerAlpha = oldPool.totalGshareRewardPerAlpha();
        // totalGshareRewardPerPrey = oldPool.totalGshareRewardPerPrey();
        // lastTimestampForGshare  = oldPool.lastTimestampForGshare();
        // unaccountedRewardsForGshare = oldPool.unaccountedRewardsForGshare();
        // totalPreyStakedForGlad = oldPool.totalPreyStakedForGlad();
        // totalPredatorsStakedForGlad = oldPool.totalPredatorsStakedForGlad();
        // totalAlphaStakedForGlad = oldPool.totalAlphaStakedForGlad();
        // totalPreyStakedForGshare = oldPool.totalPreyStakedForGshare();
        // totalPredatorsStakedForGshare = oldPool.totalPredatorsStakedForGshare();
        // totalAlphaStakedForGshare = oldPool.totalAlphaStakedForGshare();
        parametersLoaded = true;
        preyLoadIndex = 0;
        preyLoaded = false;
        predatorLoaded[0] = false;
        predatorLoaded[1] = false;
        predatorLoaded[2] = false;
        predatorLoaded[3] = false;
        predatorLoaded[4] = false;
        predatorLoadIndex[0] = 0;
        predatorLoadIndex[1] = 0;
        predatorLoadIndex[2] = 0;
        predatorLoadIndex[3] = 0;
        predatorLoadIndex[4] = 0;
    }

    function loadPreyTokenOnwers()  external onlyOwner {
        require(canMigrate, "Migration no longer possible");
        require(!preyLoaded, "Preys already loaded");
        uint256 cnt = oldPool.totalPreyStakedForGlad() + oldPool.totalPreyStakedForGshare();
        uint256 i;
        for (; gasleft() > 300000 && preyLoadIndex + i < cnt; i++) {
            (uint256 tokenId, address stakeOwner) = oldPool.barn(i + preyLoadIndex);
            if (userMigrated[stakeOwner]) {
                userMigrated[stakeOwner] = false;

                (NFTPoolNG.UserStake memory gladshare, NFTPoolNG.UserStake memory glad) = oldPool.userPool(stakeOwner);
                
                userPool[stakeOwner].glad.lastTimestamp = glad.lastTimestamp;
                userPool[stakeOwner].glad.preyStaked = glad.preyStaked;
                userPool[stakeOwner].glad.predatorsStaked = glad.predatorsStaked;
                userPool[stakeOwner].glad.lastRewardPerPrey = glad.lastRewardPerPrey;
                userPool[stakeOwner].glad.claimableBarnReward = glad.claimableBarnReward;
                userPool[stakeOwner].glad.claimablePackReward = glad.claimablePackReward;
                userPool[stakeOwner].glad.stakedAlpha = glad.stakedAlpha;
                userPool[stakeOwner].glad.lastRewardPerAlpha = glad.lastRewardPerAlpha;

                userPool[stakeOwner].gladshare.lastTimestamp = gladshare.lastTimestamp;
                userPool[stakeOwner].gladshare.preyStaked = gladshare.preyStaked;
                userPool[stakeOwner].gladshare.predatorsStaked = gladshare.predatorsStaked;
                userPool[stakeOwner].gladshare.lastRewardPerPrey = gladshare.lastRewardPerPrey;
                userPool[stakeOwner].gladshare.claimableBarnReward = gladshare.claimableBarnReward;
                userPool[stakeOwner].gladshare.claimablePackReward = gladshare.claimablePackReward;
                userPool[stakeOwner].gladshare.stakedAlpha = gladshare.stakedAlpha;
                userPool[stakeOwner].gladshare.lastRewardPerAlpha = gladshare.lastRewardPerAlpha;
            }
        }
        preyLoadIndex += i;
        if (preyLoadIndex == cnt) {
            preyLoaded = true;
        }
    }

    function loadPredatorTokenOnwers(uint256 alphaIndex)  external onlyOwner {
        require(canMigrate, "Migration no longer possible");
        require(!predatorLoaded[alphaIndex], "This predator group has already been imported");
        uint256 i;
        for (; gasleft() > 300000 ; i++) {
            try oldPool.pack(alphaIndexToAlphaLUT[alphaIndex], predatorLoadIndex[alphaIndex] + i) returns (uint256 tokenId, address stakeOwner) {
                if (userMigrated[stakeOwner]) {
                    userMigrated[stakeOwner] = false;

                    (NFTPoolNG.UserStake memory gladshare, NFTPoolNG.UserStake memory glad) = oldPool.userPool(stakeOwner);
                    
                    userPool[stakeOwner].glad.lastTimestamp = glad.lastTimestamp;
                    userPool[stakeOwner].glad.preyStaked = glad.preyStaked;
                    userPool[stakeOwner].glad.predatorsStaked = glad.predatorsStaked;
                    userPool[stakeOwner].glad.lastRewardPerPrey = glad.lastRewardPerPrey;
                    userPool[stakeOwner].glad.claimableBarnReward = glad.claimableBarnReward;
                    userPool[stakeOwner].glad.claimablePackReward = glad.claimablePackReward;
                    userPool[stakeOwner].glad.stakedAlpha = glad.stakedAlpha;
                    userPool[stakeOwner].glad.lastRewardPerAlpha = glad.lastRewardPerAlpha;

                    userPool[stakeOwner].gladshare.lastTimestamp = gladshare.lastTimestamp;
                    userPool[stakeOwner].gladshare.preyStaked = gladshare.preyStaked;
                    userPool[stakeOwner].gladshare.predatorsStaked = gladshare.predatorsStaked;
                    userPool[stakeOwner].gladshare.lastRewardPerPrey = gladshare.lastRewardPerPrey;
                    userPool[stakeOwner].gladshare.claimableBarnReward = gladshare.claimableBarnReward;
                    userPool[stakeOwner].gladshare.claimablePackReward = gladshare.claimablePackReward;
                    userPool[stakeOwner].gladshare.stakedAlpha = gladshare.stakedAlpha;
                    userPool[stakeOwner].gladshare.lastRewardPerAlpha = gladshare.lastRewardPerAlpha;
                }
            } catch {
                predatorLoaded[alphaIndex] = true;
                break;
            }
        }
        predatorLoadIndex[alphaIndex] += i;
    }


    function migrateNfts()  external onlyOwner {
        require(canMigrate, "Migration no longer possible");
        require(parametersLoaded, "Params not yet migrated");
        require(preyLoaded, "Prey not yet loaded");
        require(predatorLoaded[0], "Alpha 0 not yet imported");
        require(predatorLoaded[1], "Alpha 1 not yet imported");
        require(predatorLoaded[2], "Alpha 2 not yet imported");
        require(predatorLoaded[3], "Alpha 3 not yet imported");
        require(predatorLoaded[4], "Alpha 4 not yet imported");
        require(!nftsMigrated, "Nfts already migrated");
        uint256 i = 0;
        uint256 cnt = preyPredator.minted();
        for (; gasleft() > 300000 && migrationIndex + i < cnt && i < 30;) {
            i++;
            uint256 tokenId = migrationIndex + i;

            if (preyPredator.ownerOf(tokenId) != address(oldPool)) continue;

            bool isForGshare = oldPool.stakedForGshare(tokenId);
            preyPredator.transferFrom(address(oldPool), address(this), tokenId);

            address stakeOwner = tokenOwners[tokenId];
            if (!userMigrated[stakeOwner]) {
                userMigrated[stakeOwner] = true;

                (NFTPoolNG.UserStake memory gladshare, NFTPoolNG.UserStake memory glad) = oldPool.userPool(stakeOwner);
                
                userPool[stakeOwner].glad.lastTimestamp = glad.lastTimestamp;
                userPool[stakeOwner].glad.preyStaked = glad.preyStaked;
                userPool[stakeOwner].glad.predatorsStaked = glad.predatorsStaked;
                userPool[stakeOwner].glad.lastRewardPerPrey = glad.lastRewardPerPrey;
                userPool[stakeOwner].glad.claimableBarnReward = glad.claimableBarnReward;
                userPool[stakeOwner].glad.claimablePackReward = glad.claimablePackReward;
                userPool[stakeOwner].glad.stakedAlpha = glad.stakedAlpha;
                userPool[stakeOwner].glad.lastRewardPerAlpha = glad.lastRewardPerAlpha;

                userPool[stakeOwner].gladshare.lastTimestamp = gladshare.lastTimestamp;
                userPool[stakeOwner].gladshare.preyStaked = gladshare.preyStaked;
                userPool[stakeOwner].gladshare.predatorsStaked = gladshare.predatorsStaked;
                userPool[stakeOwner].gladshare.lastRewardPerPrey = gladshare.lastRewardPerPrey;
                userPool[stakeOwner].gladshare.claimableBarnReward = gladshare.claimableBarnReward;
                userPool[stakeOwner].gladshare.claimablePackReward = gladshare.claimablePackReward;
                userPool[stakeOwner].gladshare.stakedAlpha = gladshare.stakedAlpha;
                userPool[stakeOwner].gladshare.lastRewardPerAlpha = gladshare.lastRewardPerAlpha;
            }
            if (isPrey(tokenId))
                _addPreyToBarn(stakeOwner, tokenId, isForGshare);
            else _addPredatorToPack(stakeOwner, tokenId, isForGshare);
            
            stakedForGshare[tokenId] = isForGshare;
        
            lastActivity[tokenId] = oldPool.lastActivity(tokenId);
        }
        migrationIndex += i;
        if (migrationIndex == cnt) {
            nftsMigrated = true;
        }
    }
    
    function closeMigration() external {
        require(canMigrate, "Migration no longer possible");
        require(parametersLoaded, "Params not yet migrated");
        require(preyLoaded, "Prey not yet loaded");
        require(predatorLoaded[0], "Alpha 0 not yet imported");
        require(predatorLoaded[1], "Alpha 1 not yet imported");
        require(predatorLoaded[2], "Alpha 2 not yet imported");
        require(predatorLoaded[3], "Alpha 3 not yet imported");
        require(predatorLoaded[4], "Alpha 4 not yet imported");
        require(nftsMigrated, "Nfts not yet migrated");
        canMigrate = false;
    }
    // ** INTERNAL * //

    /**
     * adds a single Prey to the Barn
     * @param account the address of the staker
     * @param tokenId the ID of the Prey to add to the Barn
     * @param isForGshare which pool to stake for
     */
    function _addPreyToBarn(
        address account,
        uint256 tokenId,
        bool isForGshare
    ) internal {
        // if (isForGshare) {
        //     totalPreyStakedForGshare += 1;
        //     userPool[account].gladshare.preyStaked += 1;
        // } else {
        //     _ensureGen0(tokenId);
        //     totalPreyStakedForGlad += 1;
        //     userPool[account].glad.preyStaked += 1;
        // }
        barnIndices[tokenId] = barn.length;
        barn.push(Stake({owner: account, tokenId: tokenId}));

        emit TokenStaked(account, tokenId, isForGshare, true);
    }

    /**
     * adds a single Predator to the Pack
     * @param account the address of the staker
     * @param tokenId the ID of the Predator to add to the Pack
     * @param isForGshare which pool to stake for
     */
    function _addPredatorToPack(
        address account,
        uint256 tokenId,
        bool isForGshare
    ) internal {
        uint256 alpha = _alphaForPredator(tokenId);
        // if (isForGshare) {
        //     totalAlphaStakedForGshare += alpha; // Portion of earnings mapped
        //     totalPredatorsStakedForGshare += 1;
        //     userPool[account].gladshare.predatorsStaked += 1;
        //     userPool[account].gladshare.stakedAlpha += alpha;
        // } else {
        //     totalAlphaStakedForGlad += alpha; // Portion of earnings mapped
        //     totalPredatorsStakedForGlad += 1;
        //     userPool[account].glad.predatorsStaked += 1;
        //     userPool[account].glad.stakedAlpha += alpha;
        // }
        packIndices[tokenId] = pack[alpha].length; // Store the location of the predator in the Pack
        pack[alpha].push(Stake({owner: account, tokenId: tokenId})); // Add the predator to the Pack

        emit TokenStaked(account, tokenId, isForGshare, false);
    }

  

    // function _ensureGen0(uint256 tokenId) internal view {
    //     IPreyPredator.PreyPredator memory t = preyPredator.getTokenTraits(
    //         tokenId
    //     );
    //     require(t.generation == 0, "Only gen0 NFTs are for GLAD");
    // }

    /** READ ONLY */

    /**
     * checks if a token is a Prey
     * @param tokenId the ID of the token to check
     * @return prey - whether or not a token is a Prey
     */
    function isPrey(uint256 tokenId) public view returns (bool prey) {
        IPreyPredator.PreyPredator memory iPreyPredator = preyPredator
            .getTokenTraits(tokenId);
        return iPreyPredator.isPrey;
    }

    /**
     * gets the alpha score for a Predaror
     * @param tokenId the ID of the Predator to get the alpha score for
     * @return the alpha score of the PRedator
     */
    function _alphaForPredator(uint256 tokenId)
        internal
        view
        returns (uint256)
    {
        IPreyPredator.PreyPredator memory iPreyPredator = preyPredator
            .getTokenTraits(tokenId);

        return alphaIndexToAlphaLUT[iPreyPredator.alphaIndex];
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        revert("Dont accept");
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity =0.8.9;

import "./IPool.sol";
import "./IEntropy.sol";
import "./ITraits.sol";
import "./IPreyPredator.sol";
import "../../IWhitelist.sol";
import "../../Controllable.sol";
import "../../owner/Operator.sol";
import "../../owner/Blacklistable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

contract PreyPredator is
    IPreyPredator,
    ERC721Enumerable,
    ERC721Royalty,
    ERC721Burnable,
    Operator,
    Controllable,
    Blacklistable,
    Pausable
{
    using SafeERC20 for IERC20;
    //INFO: Configuration is defined here

    uint256 public constant MAX_PER_MINT = 30;
    uint256 public MAX_MINT_PER_ADDRESS;

    uint8 public PREDATOR_MINT_CHANCE = 10;
    uint8 public MINT_STEAL_CHANCE = 10;

    // gen 0 mint price floor
    uint256 public MINT_PRICE_START;
    uint256 public MINT_PRICE_END;
    // max number of GEN0 tokens that can be minted
    uint256 public GEN0_TOKENS;
    // after how many blocks the traits are revealed
    uint256 public immutable REVEAL_DELAY = 5;
    uint96 public ROYALTY_FEE = 9;
    // number of tokens have been minted so far
    uint64 public minted;
    mapping(uint256 => uint256) public mintedPerGen;
    mapping(address => uint256) public mintedPerAddress;
    // current generation
    uint8 public currentGeneration;
    // index of the last revealed NFT
    uint256 private lastRevealed;
    // start timestamp
    uint256 public mintStartTime;
    // whitelist free nft claim tracker
    mapping(address => bool) public whitelistClaimed;
    // mapping from tokenId to a struct containing the token's traits
    mapping(uint256 => PreyPredator) private tokenTraits;
    // mapping from hashed(tokenTrait) to the tokenId it's associated with
    // used to ensure there are no duplicates
    mapping(uint256 => uint256) private existingCombinations;

    mapping(uint256 => uint256) public mintBlock;

    mapping(uint256 => uint256) public mintedPrice;

    // list of probabilities for each trait type
    // 0 - 9 are associated with Prey, 10 - 18 are associated with Predators
    uint16[][19] public rarities;
    // list of aliases for Walker's Alias algorithm
    // 0 - 9 are associated with Prey, 10 - 18 are associated with Predators
    uint8[][19] public aliases;

    // reference to the Pool for choosing random Predator thieves
    // initial nft pool
    IPool public pool;
    // nft for glad/dgladshare pool
    IPool public pool2;
    // reference to Traits
    ITraits public traits;
    // reference to entropy generation
    IEntropy public entropy;

    // reference to whiteist
    IWhitelist public whitelist;

    address public daoAddress;
    address public teamAddress;

    /**
     * instantiates contract and rarity tables
     */
    constructor(
        address _traits,
        address _wl,
        address _daoAddress,
        address _teamAddress,
        uint256 _mintStartTime,
        uint256 _startprice,
        uint256 _endprice,
        uint256 _gen0Tokens,
        uint256 _maxMintPerAddress
    ) ERC721("Gladiator Finance", "GLADNFT") {
        //TODO:
        traits = ITraits(_traits);
        whitelist = IWhitelist(_wl);
        mintStartTime = _mintStartTime;
        _setDefaultRoyalty(owner(), ROYALTY_FEE);
        MAX_MINT_PER_ADDRESS = _maxMintPerAddress;

        MINT_PRICE_END = _endprice;
        MINT_PRICE_START = _startprice;

        GEN0_TOKENS = _gen0Tokens;

        daoAddress = _daoAddress;
        teamAddress = _teamAddress;
        // I know this looks weird but it saves users gas by making lookup O(1)
        // A.J. Walker's Alias Algorithm
        // prey
        // environment
        rarities[0] = [246, 228, 256, 241, 253, 54, 36];
        aliases[0] = [2, 3, 2, 4, 2, 0, 1];
        // body
        rarities[1] = [102, 179, 256, 51, 26, 51, 26, 51, 26, 26];
        aliases[1] = [1, 2, 2, 0, 1, 2, 0, 1, 2, 0];
        // armor
        rarities[2] = [256, 205, 20, 184, 92, 15];
        aliases[2] = [0, 0, 0, 0, 1, 2];
        // helmet
        rarities[3] = [256, 210, 84, 241, 251, 108, 18];
        aliases[3] = [0, 3, 0, 0, 0, 1, 2];
        // shoes
        rarities[4] = [256, 210, 84, 241, 251, 108, 18];
        aliases[4] = [0, 3, 0, 0, 0, 1, 2];
        // shield
        rarities[5] = [179, 256, 200, 138, 251, 108, 18];
        aliases[5] = [1, 1, 1, 2, 2, 3, 1];
        // weapon
        rarities[6] = [256, 205, 21, 184, 92, 15];
        aliases[6] = [0, 0, 0, 0, 1, 2];
        // item
        rarities[7] = [256, 139, 139, 138, 138, 138, 159, 138, 46];
        aliases[7] = [0, 0, 6, 0, 0, 0, 0, 0, 0];
        // alphaIndex
        rarities[8] = [255];
        aliases[8] = [0];

        // predators
        // environment
        rarities[10] = [256, 154, 184, 154, 154, 246, 246, 0, 0, 0, 0, 31];
        aliases[10] = [0, 0, 0, 2, 0, 2, 0, 2, 0, 0, 0, 0];
        // body
        rarities[11] = [256, 220, 210, 143, 143, 200, 200, 133, 133, 133, 67, 67, 66];
        aliases[11] = [0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 0, 1, 0];
        // armor
        rarities[12] = [255];
        aliases[12] = [0];
        // helmet
        rarities[13] = [255];
        aliases[13] = [0];
        // shoes
        rarities[14] = [255];
        aliases[14] = [0];
        // shield
        rarities[15] = [255];
        aliases[15] = [0];
        // weapon
        rarities[16] = [256, 154, 256, 102, 26];
        aliases[16] = [0, 0, 2, 0, 1];
        // item
        rarities[17] = [256, 141, 166, 77, 166, 166, 154, 154, 154, 154, 153, 115, 77, 39, 38];
        aliases[17] = [0, 0, 0, 0, 0, 0, 1, 2, 4, 5, 0, 1, 0, 0, 0];
        // alphaIndex
        rarities[18] = [256, 154, 256, 102, 26];
        aliases[18] = [0, 0, 2, 0, 1];

        // sanity check
        for (uint256 i = 0; i < 19; i++) {
            require(
                rarities[i].length == aliases[i].length,
                "Rarities' and aliases' length do not match everywhere!"
            );
        }
    }

    /** EXTERNAL */

    // The original contract of Wolf Game is susceptible to an exploit whereby only WOLFs can be minted
    // This is due to the fact that you can check the traits of the minted NFT atomically
    // Problem is solvable by not revealing the batch. Setting the max mint number to 10
    // means that no one can mint more than 10 in a single transaction. And since the current
    // batch is not revealed until the next batch, there is no way to game this setup.
    // This also implies that at least the last 10 NFTs should be minted by admin, to
    // reveal the previous batch.

    /**
     * mint a gen0 token - 90% Prey, 10% Predators
     * Due to buffer considerations, staking is not possible immediately
     * Minter has to wait for 10 mints
     */
    function mintGen0(uint256 amount) external payable whenNotPaused {
        address msgSender = _msgSender();

        require(block.timestamp >= mintStartTime, "Minting not started yet");
        require(tx.origin == msgSender, "Only EOA");
        // - MAX_PER_MINT, because the last MAX_PER_MINT are mintable by an admin
        require(
            mintedPerGen[0] + amount <= GEN0_TOKENS,
            "Mint less, there are no this many gen0 tokens left"
        );
        require(
            mintedPerAddress[msgSender] + amount <= MAX_MINT_PER_ADDRESS,
            "You cant mint that much for this address!"
        );
        uint256 mintCostEther = _getMintPrice(amount);

        if (
            amount >= 10 &&
            whitelist.isWhitelisted(msgSender) &&
            !whitelistClaimed[msgSender]
        ) {
            mintCostEther *= amount - 1;
            mintCostEther /= amount;
        }

        require(
            mintCostEther <= msg.value,
            "Not enough amount sent with transaction"
        );
        _batchmint(msgSender, amount, 0, 0, true);

        // send back excess value
        if (msg.value > mintCostEther) {
            Address.sendValue(payable(msgSender), msg.value - mintCostEther);
        }

        // send 25% to dao address, 75% to team address
        if (address(daoAddress) != address(0) && address(teamAddress) != address(0)) {
            Address.sendValue(payable(daoAddress), address(this).balance * 25 / 100);
            Address.sendValue(payable(teamAddress), address(this).balance);
        }
    }

    function setGen0Mint(uint256 _amount) external whenNotPaused onlyOwner {
        require(_amount >= mintedPerGen[0], "Already minted more");
        GEN0_TOKENS = _amount;
    }

    function mintUnderpeg(
        address to,
        uint256 amount,
        uint256 price
    ) external whenNotPaused {
        require(isOperator(), "no permission");
        require(
            mintedPerGen[currentGeneration] + amount <=
                getGenTokens(currentGeneration),
            "Mint less, there are no this many tokens left"
        );

        _batchmint(to, amount, price, currentGeneration, false);
    }

    function mintGeneric (
        address to,
        uint256 amount,
        uint256 price,
        uint256 generation,
        bool stealing
    ) external whenNotPaused onlyController {
        _batchmint(to, amount, price, generation, stealing);
    }

    function increaseGeneration() external {
        require(isOperator(), "no permission");

        currentGeneration++;
    }

    // TODO: ADD MINT by CONTROLLER

    function _batchmint(
        address msgSender,
        uint256 amount,
        uint256 mintPrice,
        uint256 generation,
        bool stealing
    ) internal whenNotPaused {
        require(amount > 0 && amount <= MAX_PER_MINT, "Invalid mint amount");
        if (
            lastRevealed < minted &&
            mintBlock[minted] + REVEAL_DELAY <= block.number
        ) {
            lastRevealed = minted;
        }

        uint256 seed;
        for (uint256 i = 0; i < amount; i++) {
            minted++;
            seed = entropy.random(minted);
            generate(minted, seed, mintPrice, generation);
            address recipient = msgSender;
            if (stealing) recipient = selectRecipient(seed);
            _safeMint(recipient, minted);
        }
        mintedPerGen[generation] += amount;
    }

    /**
     * update traits of a token (for future use)
     */
    function updateTokenTraits(uint256 _tokenId, PreyPredator memory _newTraits)
        external
        whenNotPaused
        onlyController
    {
        require(
            _tokenId > 0 && _tokenId <= minted,
            "UpdateTraits: token does not exist"
        );
        uint256 traitHash = structToHash(_newTraits);
        uint256 combinationId = existingCombinations[traitHash];
        require(
            combinationId == 0 || combinationId == _tokenId,
            "UpdateTraits: Token with the desired traits already exist"
        );
        // validate that new trait values actually exist by accessing the corresponding alias
        uint256 shift = 0;
        if (!_newTraits.isPrey) {
            shift = 10;
        }
        require(
            aliases[0 + shift].length > _newTraits.environment,
            "UpdateTraits: Invalid environment"
        );
        require(
            aliases[1 + shift].length > _newTraits.body,
            "UpdateTraits: Invalid body"
        );
        require(
            aliases[2 + shift].length > _newTraits.armor,
            "UpdateTraits: Invalid armor"
        );
        require(
            aliases[3 + shift].length > _newTraits.helmet,
            "UpdateTraits: Invalid helmet"
        );
        require(
            aliases[4 + shift].length > _newTraits.shoes,
            "UpdateTraits: Invalid shoes"
        );
        require(
            aliases[5 + shift].length > _newTraits.shield,
            "UpdateTraits: Invalid shield"
        );
        require(
            aliases[6 + shift].length > _newTraits.weapon,
            "UpdateTraits: Invalid weapon"
        );
        require(
            aliases[7 + shift].length > _newTraits.item,
            "UpdateTraits: Invalid item"
        );
        require(
            aliases[8 + shift].length > _newTraits.alphaIndex,
            "UpdateTraits: Invalid alpha"
        );
        require(
            currentGeneration >= _newTraits.generation,
            "UpdateTraits: Invalid generation"
        );
        delete existingCombinations[structToHash(tokenTraits[_tokenId])];
        tokenTraits[_tokenId] = _newTraits;
        existingCombinations[traitHash] = _tokenId;
        emit TokenTraitsUpdated(_tokenId, _newTraits);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        // Hardcode the Pool's approval so that users don't have to waste gas approving
        if (_msgSender() != address(pool)) {
            require(
                _isApprovedOrOwner(_msgSender(), tokenId),
                "ERC721: transfer caller is not owner nor approved"
            );
        }
        _transfer(from, to, tokenId);
    }

    function getMintPrice(uint256 amount) public view returns (uint256) {
        require(
            mintedPerGen[0] + amount <= GEN0_TOKENS,
            "Mint less, there are no this many gen0 tokens left"
        );
        return _getMintPrice(amount);
    }

    function getGenTokens(uint8 generation) public view returns (uint256) {
        return 90 + generation * 10;
    }

    /** INTERNAL */

    function _safeMint(address _ownr, uint256 _tokenId)
        internal
        virtual
        override
    {
        super._safeMint(_ownr, _tokenId);
        mintBlock[_tokenId] = block.number;
    }

    function _getMintPrice(uint256 amount) internal view returns (uint256) {
        return
            (((MINT_PRICE_END *
                mintedPerGen[0] +
                MINT_PRICE_START *
                (GEN0_TOKENS - 1 - mintedPerGen[0])) +
                (MINT_PRICE_END *
                    (mintedPerGen[0] + amount - 1) +
                    MINT_PRICE_START *
                    (GEN0_TOKENS - 1 - mintedPerGen[0] + 1 - amount))) *
                amount) /
            2 /
            (GEN0_TOKENS - 1);
    }

    /**
     * generates traits for a specific token, checking to make sure it's unique
     * @param tokenId the id of the token to generate traits for
     * @param seed a pseudorandom 256 bit number to derive traits from
     * @return t - a struct of traits for the given token ID
     */
    function generate(
        uint256 tokenId,
        uint256 seed,
        uint256 mintPrice,
        uint256 generation
    ) internal returns (PreyPredator memory t) {
        t = selectTraits(seed);
        mintedPrice[tokenId] = mintPrice;
        t.generation = uint64(generation);
        if (existingCombinations[structToHash(t)] == 0) {
            tokenTraits[tokenId] = t;
            existingCombinations[structToHash(t)] = tokenId;
            return t;
        }
        return generate(tokenId, entropy.random(seed), mintPrice, generation);
    }

    /**
     * uses A.J. Walker's Alias algorithm for O(1) rarity table lookup
     * ensuring O(1) instead of O(n) reduces mint cost by more than 50%
     * probability & alias tables are generated off-chain beforehand
     * @param seed portion of the 256 bit seed to remove trait correlation
     * @param traitType the trait type to select a trait for
     * @return the ID of the randomly selected trait
     */
    function selectTrait(uint16 seed, uint8 traitType)
        internal
        view
        returns (uint8)
    {
        uint8 trait = uint8(seed) % uint8(rarities[traitType].length);
        if (seed >> 8 < rarities[traitType][trait]) return trait;
        return aliases[traitType][trait];
    }

    /**
     * they have a chance to be given to a random staked predator
     * @param seed a random value to select a recipient from
     * @return the address of the recipient (either the minter or the Predator thief's owner)
     */
    function selectRecipient(uint256 seed) internal view returns (address) {
        // 144 bits reserved for trait selection
        address thief;
        if (block.timestamp < mintStartTime + 73 hours && address(pool) != address(0)) thief = pool.getRandomPredatorOwner(seed >> 144);
        else if (block.timestamp >= mintStartTime + 73 hours && address(pool2) != address(0)) thief = pool2.getRandomPredatorOwner(seed >> 144);
        if (((seed >> 240) % 100) >= MINT_STEAL_CHANCE) {
            return _msgSender();
        } // top 16 bits haven't been used
        else {
            if (thief == address(0x0)) return _msgSender();
            return thief;
        }
    }

    /**
     * selects the species and all of its traits based on the seed value
     * @param seed a pseudorandom 256 bit number to derive traits from
     * @return t -  a struct of randomly selected traits
     */
    function selectTraits(uint256 seed)
        internal
        view
        returns (PreyPredator memory t)
    {
        t.isPrey = (seed & 0xFFFF) % 100 >= PREDATOR_MINT_CHANCE;
        uint8 shift = t.isPrey ? 0 : 10;
        seed >>= 16;
        t.environment = selectTrait(uint16(seed & 0xFFFF), 0 + shift);
        seed >>= 16;
        t.body = selectTrait(uint16(seed & 0xFFFF), 1 + shift);
        seed >>= 16;
        t.armor = selectTrait(uint16(seed & 0xFFFF), 2 + shift);
        seed >>= 16;
        t.helmet = selectTrait(uint16(seed & 0xFFFF), 3 + shift);
        seed >>= 16;
        t.shoes = selectTrait(uint16(seed & 0xFFFF), 4 + shift);
        seed >>= 16;
        t.shield = selectTrait(uint16(seed & 0xFFFF), 5 + shift);
        seed >>= 16;
        t.weapon = selectTrait(uint16(seed & 0xFFFF), 6 + shift);
        seed >>= 16;
        t.item = selectTrait(uint16(seed & 0xFFFF), 7 + shift);
        seed >>= 16;
        t.alphaIndex = selectTrait(uint16(seed & 0xFFFF), 8 + shift);
    }

    /**
     * converts a struct to a 256 bit hash to check for uniqueness
     * @param s the struct to pack into a hash
     * @return the 256 bit hash of the struct
     */
    function structToHash(PreyPredator memory s)
        internal
        pure
        returns (uint256)
    {
        return
            uint256(
                bytes32(
                    abi.encodePacked(
                        s.isPrey,
                        s.environment,
                        s.body,
                        s.armor,
                        s.helmet,
                        s.shoes,
                        s.shield,
                        s.weapon,
                        s.item,
                        s.alphaIndex
                    )
                )
            );
    }

    /** READ */

    function traitsRevealed(uint256 tokenId)
        external
        view
        returns (bool revealed)
    {
        if (
            tokenId <= lastRevealed ||
            mintBlock[tokenId] + REVEAL_DELAY <= block.number
        ) return true;
        return false;
    }

    // only used in traits in a couple of places that all boil down to tokenURI
    // so it is safe to buffer the reveal
    function getTokenTraits(uint256 tokenId)
        external
        view
        override
        returns (PreyPredator memory)
    {
        // to prevent people from minting only predators. We reveal the minted batch,
        // after a few blocks.
        if (tokenId <= lastRevealed) {
            return tokenTraits[tokenId];
        } else {
            require(
                mintBlock[tokenId] + REVEAL_DELAY <= block.number,
                "Traits of this token can't be revealed yet"
            );
            //            mintBlock[tokenId] = block.number;
            return tokenTraits[tokenId];
        }
    }

    /** ADMIN */

    /**
     * called after deployment so that the contract can get random predator thieves
     * @param _pool the address of the Pool
     */
     // initial staking pool address
    function setPool(address _pool) external onlyOwner {
        pool = IPool(_pool);
        _addController(_pool);
    }

    // address of pool2
    function setPool2(address _pool) external onlyOwner {
        pool2 = IPool(_pool);
        _addController(_pool);
    }

    function setDaoAddress(address _adr) external onlyOwner {
        daoAddress = _adr;
    }

    function setTeamAddress(address _adr) external onlyOwner {
        teamAddress = _adr;
    }

    function setEntropy(address _entropy) external onlyOwner {
        entropy = IEntropy(_entropy);
    }

    function setRoyalty(address _addr, uint96 _fee) external onlyOwner {
        ROYALTY_FEE = _fee;
        _setDefaultRoyalty(_addr, _fee);
    }

    function setPredatorMintChance(uint8 _mintChance) external onlyOwner {
        PREDATOR_MINT_CHANCE = _mintChance;
    }

    function setMintStealChance(uint8 _mintStealChance) external onlyOwner {
        MINT_STEAL_CHANCE = _mintStealChance;
    }

    /**
     * allows owner to withdraw funds from minting
     */
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * reserve amounts for treasury / marketing
     */
    function reserve(uint256 amount, uint256 generation)
        external
        whenNotPaused
        onlyOwner
    {
        require(amount > 0 && amount <= MAX_PER_MINT, "Invalid mint amount");
        require(block.timestamp >= mintStartTime, "Minting not started yet");
        require(generation <= currentGeneration, "Invalid generation");
        _batchmint(owner(), amount, 0, generation, false);
    }

    /**
     * enables owner to pause / unpause minting
     */
    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    /** RENDER */

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        // to prevent people from minting only predators. We reveal the minted batch,
        // if the next batch has been minted.
        if (tokenId <= lastRevealed) {
            return traits.tokenURI(tokenId);
        } else {
            require(
                mintBlock[tokenId] + REVEAL_DELAY <= block.number,
                "Traits of this token can't be revealed yet"
            );
            //            mintBlock[tokenId] = block.number;
            return traits.tokenURI(tokenId);
        }
    }

    // ** OVERRIDES **//
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        require(!isBlacklisted(from), "PreyPredator: sender is blacklisted");
        require(!isBlacklisted(to), "PreyPredator: receiver is blacklisted");
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        require(!isBlacklisted(operator), "PreyPredator: operator is blacklisted");
        return controllers[operator] || super.isApprovedForAll(owner, operator);
    }

    function _burn(uint256 tokenId)
        internal
        virtual
        override(ERC721, ERC721Royalty)
    {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable, ERC721Royalty)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

interface IEntropy {
    function random(uint256 seed) external view returns (uint256);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Controllable is Ownable {
    mapping (address => bool) controllers;

    event ControllerAdded(address);
    event ControllerRemoved(address);

    modifier onlyController() {
        require(controllers[_msgSender()] || _msgSender() ==  owner(), "Only controllers can do that");
        _;
    }

    /*** ADMIN  ***/
    /**
     * enables an address to mint / burn
     * @param controller the address to enable
     */
    function addController(address controller) external onlyOwner {
         _addController(controller);
    }

    function _addController(address controller) internal {
        if (!controllers[controller]) {
            controllers[controller] = true;
            emit ControllerAdded(controller);
        }
    }

    /**
     * disables an address from minting / burning
     * @param controller the address to disbale
     */
    function removeController(address controller) external onlyOwner {
        _RemoveController(controller);
    }

    function _RemoveController(address controller) internal {
        if (controllers[controller]) {
            controllers[controller] = false;
            emit ControllerRemoved(controller);
        }
    }
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity =0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./PreyPredator.sol";
import "./IEntropy.sol";
import "../../Controllable.sol";
import "../../utils/MyPausable.sol";
import "../../interfaces/IBasisAsset.sol";
import "../../interfaces/ITreasury.sol";

contract NFTPoolNG is Controllable, IERC721Receiver, MyPausable {
    using SafeERC20 for IERC20;

    struct Stake {
        uint256 tokenId;
        address owner;
    }

    struct UserStake {
        uint256 lastTimestamp;
        uint256 preyStaked;
        uint256 predatorsStaked;
        // barn staking
        uint256 lastRewardPerPrey;
        uint256 claimableBarnReward;
        // pack staking
        uint256 claimablePackReward;
        uint256 stakedAlpha;
        uint256 lastRewardPerAlpha;
    }

    struct UserInfo {
        UserStake gladshare;
        UserStake glad;
    }

    // Mapping, weights, scores
    // Translates the alpha index of a Predator to effective Alpha
    uint256[] alphaIndexToAlphaLUT = [100, 120, 140, 160, 180];

    mapping(address => UserInfo) public userPool;

    // reference to the PreyPredator NFT contract
    PreyPredator public preyPredator;
    // reference to the reward token contract for minting earnings (GLAD)
    IBasisAsset public glad;
    // reference to the reward token contract for minting earnings (GLADSHARE)
    IBasisAsset public gladshare;
    // reference to Entropy
    IEntropy entropy;
    // reference to Treasury
    ITreasury public treasury;

    uint256 mySeed;

    // maps tokenId to stake
    Stake[] public barn;
    // tracks location of each Prey in Barn
    mapping(uint256 => uint256) public barnIndices;

    // maps alpha to all Predator stakes with that alpha
    mapping(uint256 => Stake[]) public pack;
    // tracks location of each Predator in Pack
    mapping(uint256 => uint256) public packIndices;

    mapping(uint256 => uint256) public lastActivity;
    mapping(uint256 => bool) public stakedForGshare;

    // total alpha scores staked
    uint256 public totalAlphaStakedForGshare;
    //
    uint256 public totalPredatorsStakedForGshare;
    // any rewards distributed when no predators are staked
    uint256 public unaccountedRewardsForGshare;

    // last timestamp of rewardperprey/rewardperalpha
    uint256 public lastTimestampForGshare;

    // amount of total Reward due for each prey point staked
    uint256 public totalGshareRewardPerPrey;

    // amount of total Reward due for each alpha point staked
    uint256 public totalGshareRewardPerAlpha;

    // number of Prey staked for GLADSHARE in the Barn
    uint256 public totalPreyStakedForGshare;

    // total alpha scores staked
    uint256 public totalAlphaStakedForGlad;
    //
    uint256 public totalPredatorsStakedForGlad;
    // any rewards distributed when no predators are staked
    uint256 public unaccountedRewardsForGlad;

    // last timestamp of rewardperprey/rewardperalpha
    uint256 public lastTimestampForGlad;

    // amount of total Reward due for each prey point staked
    uint256 public totalGladRewardPerPrey;

    // amount of total Reward due for each alpha point staked
    uint256 public totalGladRewardPerAlpha;

    // number of Prey staked for GLAD in the Barn
    uint256 public totalPreyStakedForGlad;

    uint256 public constant PERIOD = 180 days;
    uint256 public REWARS_PER_PREY_PER_PERIOD = 15000 ether; // 15,000 GLADSHARE

    uint256 public STEALCHANCE_PREDATOR_UNSTAKE = 10;
    uint256 public STEALCHANCE_PREY_UNSTAKE = 20;
    // predators take a 20% tax on all $Reward claimed
    uint256 public REWARD_CLAIM_TAX_PERCENTAGE = 20;

    uint256 public LOCK_EPOCH = 6;

    uint256 public pendingGladReward;

    // staking start timestamp
    uint256 public stakingStart;

    // staking end timestamp
    uint256 public stakingEnd;

    // deadline for claiming
    //uint256 public claimDeadline;

    // whiltelist of who can use the random endpoints
    // contracts who need to pick random owners need to be added
    mapping(address => bool) randomWhitelist;

    // emergency rescue to allow unstaking without any checks but without $Reward
    bool public rescueEnabled = false;

    address public migrationContract;
    uint256 public migrationIndex;

    NFTPoolNG public oldPool;

    mapping(address => bool) userMigrated;

    bool public canMigrate;

    uint256 public preyLoadIndex;
    bool public preyLoaded;
    uint256[5] public predatorLoadIndex;
    bool[5] public predatorLoaded;
    bool public parametersLoaded;
    bool public nftsMigrated;

    mapping(uint256 => address) tokenOwners;

    event TokenStaked(
        address indexed owner,
        uint256 indexed tokenId,
        bool isForGshare,
        bool isPrey
    );
    event TokenClaimed(uint256 indexed tokenId, bool isPrey);
    event BarnRewardClaimed(
        address indexed user,
        bool isForGshare,
        uint256 amount,
        uint256 tax
    );
    event PackRewardClaimed(
        address indexed user,
        bool isForGshare,
        uint256 amount
    );
    event UserStakeChange(address indexed user, UserStake gladshare, UserStake glad);
    event TokenSwitched(address indexed user, uint256 indexed tokenId);

    /**
     * @param _preyPredator reference to the PreyPredator NFT contract
     * @param _glad reference to the $Reward token (GLAD)
     * @param _gladshare reference to the $Reward token (GLADSHARE)
     * @param _entropy reference to the entropy contract (allow this contract to use it)
     * @param _treasury reference to the treasury contract
     * @param _stakingStart timestamp for staking start
     */
    constructor(
        address _preyPredator,
        address _glad,
        address _gladshare,
        address _entropy,
        address _treasury,
        uint256 _stakingStart,
        address _oldPool,
        address _migrator
    ) {
        glad = IBasisAsset(_glad);
        gladshare = IBasisAsset(_gladshare);
        preyPredator = PreyPredator(_preyPredator);
        stakingStart = _stakingStart;
        stakingEnd = stakingStart + 180 days;
        //claimDeadline = stakingEnd + 30 days;
        entropy = IEntropy(_entropy);
        treasury = ITreasury(_treasury);
        oldPool = NFTPoolNG(_oldPool);
        migrationContract = _migrator;
        canMigrate = true;
        _pause();
    }

    /** MIGRATION */
    function migrateParams() external onlyOwner {
        address(migrationContract).delegatecall(abi.encodeWithSignature("migrateParams()"));
    }

    function loadPreyTokenOnwers()  external onlyOwner {
        address(migrationContract).delegatecall(abi.encodeWithSignature("loadPreyTokenOnwers()"));
    }

    function loadPredatorTokenOnwers(uint256 alphaIndex)  external onlyOwner {
        address(migrationContract).delegatecall(abi.encodeWithSignature("loadPredatorTokenOnwers(uint256)",alphaIndex));
    }

    function migrateNfts() external onlyOwner {
        address(migrationContract).delegatecall(abi.encodeWithSignature("migrateNfts()"));
    }

    function closeMigration() external {
        address(migrationContract).delegatecall(abi.encodeWithSignature("migratcloseMigrationeParams()"));
    }

    /** STAKING */

    /**
     * adds Prey and Predators to the Barn and Pack
     * @param tokenIds the IDs of the Prey and Predators to stake
     */
    function addManyToPool(
        uint256[] calldata tokenIds,
        bool[] calldata isForGshare
    ) external whenNotPaused updateEarnings(msg.sender) { // beforeDeadline updateEarnings(msg.sender) {
        //require(stakingStart <= block.timestamp, "NOT YET");
        require(tx.origin == msg.sender, "Only EOA");
        require(tokenIds.length == isForGshare.length);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i] == 0) continue;
            // to ensure it can be revealed
            require(
                preyPredator.traitsRevealed(tokenIds[i]),
                "This token cannot be staked yet, wait a few blocks"
            );

            require(
                preyPredator.ownerOf(tokenIds[i]) == msg.sender,
                "NOT YOURS"
            );

            preyPredator.transferFrom(msg.sender, address(this), tokenIds[i]);

            if (isPrey(tokenIds[i]))
                _addPreyToBarn(msg.sender, tokenIds[i], isForGshare[i]);
            else _addPredatorToPack(msg.sender, tokenIds[i], isForGshare[i]);

            lastActivity[tokenIds[i]] = treasury.epoch();
            stakedForGshare[tokenIds[i]] = isForGshare[i];
        }
    }

    // ** INTERNAL * //

    /**
     * adds a single Prey to the Barn
     * @param account the address of the staker
     * @param tokenId the ID of the Prey to add to the Barn
     * @param isForGshare which pool to stake for
     */
    function _addPreyToBarn(
        address account,
        uint256 tokenId,
        bool isForGshare
    ) internal {
        if (isForGshare) {
            totalPreyStakedForGshare += 1;
            userPool[account].gladshare.preyStaked += 1;
        } else {
            _ensureGen0(tokenId);
            totalPreyStakedForGlad += 1;
            userPool[account].glad.preyStaked += 1;
        }
        barnIndices[tokenId] = barn.length;
        barn.push(Stake({owner: account, tokenId: tokenId}));

        emit TokenStaked(account, tokenId, isForGshare, true);
    }

    /**
     * adds a single Predator to the Pack
     * @param account the address of the staker
     * @param tokenId the ID of the Predator to add to the Pack
     * @param isForGshare which pool to stake for
     */
    function _addPredatorToPack(
        address account,
        uint256 tokenId,
        bool isForGshare
    ) internal {
        uint256 alpha = _alphaForPredator(tokenId);
        if (isForGshare) {
            totalAlphaStakedForGshare += alpha; // Portion of earnings mapped
            totalPredatorsStakedForGshare += 1;
            userPool[account].gladshare.predatorsStaked += 1;
            userPool[account].gladshare.stakedAlpha += alpha;
        } else {
            totalAlphaStakedForGlad += alpha; // Portion of earnings mapped
            totalPredatorsStakedForGlad += 1;
            userPool[account].glad.predatorsStaked += 1;
            userPool[account].glad.stakedAlpha += alpha;
        }
        packIndices[tokenId] = pack[alpha].length; // Store the location of the predator in the Pack
        pack[alpha].push(Stake({owner: account, tokenId: tokenId})); // Add the predator to the Pack

        emit TokenStaked(account, tokenId, isForGshare, false);
    }

    /** SWITCHING */

    function switchPool(uint256 tokenId)
        external
        whenNotPaused
        // beforeDeadline
        updateEarnings(msg.sender)
    {
        require(tx.origin == msg.sender, "Only EOA");
        _switchPool(tokenId);
    }

    function switchManyPool(uint256[] memory tokenIds)
        external
        whenNotPaused
        // beforeDeadline
        updateEarnings(msg.sender)
    {
        require(tx.origin == msg.sender, "Only EOA");
        for (uint256 i; i < tokenIds.length;) {
            _switchPool(tokenIds[i]);
            unchecked {
                i++;
            }
        }
    }

    // ** INTERNAL * //

    function _switchPool(uint256 tokenId) internal {
        _ensureGen0(tokenId);
        uint256 currentEpoch = treasury.epoch();
        require(
            currentEpoch > lastActivity[tokenId] + LOCK_EPOCH,
            "NFT locked"
        );

        address _user = msg.sender;
        if (isPrey(tokenId)) _switchPreyInBarn(_user, tokenId);
        else _switchPredatorInPack(_user, tokenId);

        lastActivity[tokenId] = treasury.epoch();
        stakedForGshare[tokenId] = !stakedForGshare[tokenId];

        emit TokenSwitched(_user, tokenId);
    }

    /**
     * switch a single Prey in the Barn
     * @param account the address of the staker
     * @param tokenId the ID of the Prey to switch in the Barn
     */
    function _switchPreyInBarn(address account, uint256 tokenId) internal {
        bool isForGshare = stakedForGshare[tokenId];
        if (isForGshare) {
            totalPreyStakedForGshare -= 1;
            userPool[account].gladshare.preyStaked -= 1;
            totalPreyStakedForGlad += 1;
            userPool[account].glad.preyStaked += 1;
        } else {
            totalPreyStakedForGshare += 1;
            userPool[account].gladshare.preyStaked += 1;
            totalPreyStakedForGlad -= 1;
            userPool[account].glad.preyStaked -= 1;
        }
    }

    /**
     * switch a single Predator in the Pack
     * @param account the address of the staker
     * @param tokenId the ID of the Predator to switch in the Pack
     */
    function _switchPredatorInPack(address account, uint256 tokenId) internal {
        bool isForGshare = stakedForGshare[tokenId];
        uint256 alpha = _alphaForPredator(tokenId);
        if (isForGshare) {
            totalAlphaStakedForGshare -= alpha; // Portion of earnings mapped
            totalPredatorsStakedForGshare -= 1;
            userPool[account].gladshare.predatorsStaked -= 1;
            userPool[account].gladshare.stakedAlpha -= alpha;
            totalAlphaStakedForGlad += alpha; // Portion of earnings mapped
            totalPredatorsStakedForGlad += 1;
            userPool[account].glad.predatorsStaked += 1;
            userPool[account].glad.stakedAlpha += alpha;
        } else {
            totalAlphaStakedForGshare += alpha; // Portion of earnings mapped
            totalPredatorsStakedForGshare += 1;
            userPool[account].gladshare.predatorsStaked += 1;
            userPool[account].gladshare.stakedAlpha += alpha;
            totalAlphaStakedForGlad -= alpha; // Portion of earnings mapped
            totalPredatorsStakedForGlad -= 1;
            userPool[account].glad.predatorsStaked -= 1;
            userPool[account].glad.stakedAlpha -= alpha;
        }
    }

    function _ensureGen0(uint256 tokenId) internal view {
        IPreyPredator.PreyPredator memory t = preyPredator.getTokenTraits(
            tokenId
        );
        require(t.generation == 0, "Only gen0 NFTs are for GLAD");
    }

    /** CLAIMING / UNSTAKING */

    /**
     * unstake a Prey or Predator it will require thet the end time for the initial
     * pool has passed
     * @param tokenIds the IDs of the tokens to claim earnings from
     */

    function claimManyFromPool(uint256[] calldata tokenIds)
        public
        whenNotPaused
        //beforeDeadline
        updateEarnings(msg.sender)
    {
        require(tx.origin == msg.sender, "Only EOA");

        uint256 currentEpoch = treasury.epoch();
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                preyPredator.ownerOf(tokenIds[i]) == address(this),
                "NFT not in this pool"
            );
            require(
                currentEpoch > lastActivity[tokenIds[i]] + LOCK_EPOCH,
                "NFT locked"
            );
            lastActivity[tokenIds[i]] = 0;
            if (isPrey(tokenIds[i])) _claimPreyFromBarn(tokenIds[i]);
            else _claimPredatorFromPack(tokenIds[i]);
        }
    }

    // ** INTERNAL * //

    /**
     * unstake a single Prey
     * @param tokenId the ID of the Prey to claim
     */
    function _claimPreyFromBarn(uint256 tokenId) internal {
        Stake memory stake = barn[barnIndices[tokenId]];

        require(stake.owner == _msgSender(), "Not your NFT");
        bool isForGshare = stakedForGshare[tokenId];
        if (isForGshare) {
            totalPreyStakedForGshare -= 1;
            userPool[_msgSender()].gladshare.preyStaked -= 1;
        } else {
            totalPreyStakedForGlad -= 1;
            userPool[_msgSender()].glad.preyStaked -= 1;
        }
        address owner = stake.owner;
        uint256 rnd = entropy.random(mySeed++);
        bool stealing = (totalAlphaStakedForGshare + totalAlphaStakedForGlad) >
            0 &&
            rnd % 100 < STEALCHANCE_PREY_UNSTAKE;
        rnd >>= 8;
        address stealer = _randomPredatorStake(rnd).owner;
        if (stealing) {
            owner = stealer;
        }
        preyPredator.safeTransferFrom(address(this), owner, tokenId, "");

        Stake memory lastStake = barn[barn.length - 1];
        barn[barnIndices[tokenId]] = lastStake; // Shuffle last Prey to current position
        barnIndices[lastStake.tokenId] = barnIndices[tokenId];
        barn.pop(); // Remove duplicate

        delete barnIndices[tokenId]; // Delete old mapping
        emit TokenClaimed(tokenId, true);
    }

    /**
     * unstake a single Predator
     * @param tokenId the ID of the Predator to claim
     */
    function _claimPredatorFromPack(uint256 tokenId) internal {
        uint256 alpha = _alphaForPredator(tokenId);
        Stake memory stake = pack[alpha][packIndices[tokenId]];
        require(stake.owner == _msgSender(), "Not your NFT");

        bool isForGshare = stakedForGshare[tokenId];
        if (isForGshare) {
            totalAlphaStakedForGshare -= alpha; // Remove Alpha from total staked
            totalPredatorsStakedForGshare -= 1;
            userPool[_msgSender()].gladshare.predatorsStaked -= 1;
            userPool[_msgSender()].gladshare.stakedAlpha -= alpha;
        } else {
            totalAlphaStakedForGlad -= alpha; // Remove Alpha from total staked
            totalPredatorsStakedForGlad -= 1;
            userPool[_msgSender()].glad.predatorsStaked -= 1;
            userPool[_msgSender()].glad.stakedAlpha -= alpha;
        }

        Stake memory lastStake = pack[alpha][pack[alpha].length - 1]; // get last
        pack[alpha][packIndices[tokenId]] = lastStake; // Shuffle last Predator to current position
        packIndices[lastStake.tokenId] = packIndices[tokenId];
        pack[alpha].pop(); // Remove duplicate
        delete packIndices[tokenId]; // Delete old mapping

        address owner = stake.owner;
        uint256 rnd = entropy.random(mySeed++);
        bool stealing = (totalAlphaStakedForGshare + totalAlphaStakedForGlad) >
            0 &&
            rnd % 100 < STEALCHANCE_PREDATOR_UNSTAKE;
        rnd >>= 8;
        address stealer = _randomPredatorStake(rnd).owner;
        if (stealing) {
            owner = stealer;
        }
        preyPredator.safeTransferFrom(address(this), owner, tokenId, "");
        emit TokenClaimed(tokenId, false);
    }

    // ** ----------- * //

    /**
     * emergency unstake tokens - once this is used you cant switch back to non-emergency mode
     * @param tokenIds the IDs of the tokens to claim earnings from
     */
    function rescue(uint256[] calldata tokenIds) external { //beforeDeadline {
        require(rescueEnabled, "RESCUE DISABLED");
        require(tx.origin == msg.sender, "Only EOA");
        _rescue(tokenIds, false);
    }

    // function rescueExpired(uint256[] calldata tokenIds) external onlyOwner {
    //     require(block.timestamp >= claimDeadline, "Not expired yet");
    //     _rescue(tokenIds, true);
    // }

    function _rescue(uint256[] calldata tokenIds, bool sendToOwner) internal {
        uint256 tokenId;
        Stake memory stake;
        Stake memory lastStake;
        uint256 alpha;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];

            if (isPrey(tokenId)) {
                stake = barn[barnIndices[tokenId]];
                require(sendToOwner || stake.owner == msg.sender, "NO-NO");

                bool isForGshare = stakedForGshare[tokenId];
                if (isForGshare) {
                    totalPreyStakedForGshare -= 1;
                    userPool[stake.owner].gladshare.preyStaked -= 1;
                } else {
                    totalPreyStakedForGlad -= 1;
                    userPool[stake.owner].glad.preyStaked -= 1;
                }
                lastStake = barn[barn.length - 1];
                barn[barnIndices[tokenId]] = lastStake; // Shuffle last Prey to current position
                barnIndices[lastStake.tokenId] = barnIndices[tokenId];
                barn.pop(); // Remove duplicate

                delete barnIndices[tokenId]; // Delete old mapping

                preyPredator.safeTransferFrom(
                    address(this),
                    sendToOwner ? owner() : stake.owner,
                    tokenId,
                    ""
                ); // send back Prey

                emit TokenClaimed(tokenId, true);
            } else {
                alpha = _alphaForPredator(tokenId);
                stake = pack[alpha][packIndices[tokenId]];

                require(sendToOwner || stake.owner == msg.sender, "NO-NO");

                bool isForGshare = stakedForGshare[tokenId];
                if (isForGshare) {
                    totalPredatorsStakedForGshare -= 1;
                    totalAlphaStakedForGshare -= alpha; // Remove Alpha from total staked
                    userPool[stake.owner].gladshare.predatorsStaked -= 1;
                    userPool[stake.owner].gladshare.stakedAlpha -= alpha;
                } else {
                    totalPredatorsStakedForGlad -= 1;
                    totalAlphaStakedForGlad -= alpha; // Remove Alpha from total staked
                    userPool[stake.owner].glad.predatorsStaked -= 1;
                    userPool[stake.owner].glad.stakedAlpha -= alpha;
                }
                lastStake = pack[alpha][pack[alpha].length - 1];
                pack[alpha][packIndices[tokenId]] = lastStake; // Shuffle last Predator to current position
                packIndices[lastStake.tokenId] = packIndices[tokenId];
                pack[alpha].pop(); // Remove duplicate
                delete packIndices[tokenId]; // Delete old mapping

                preyPredator.safeTransferFrom(
                    address(this),
                    sendToOwner ? owner() : stake.owner,
                    tokenId,
                    ""
                ); // Send back Predator

                emit TokenClaimed(tokenId, false);
            }
        }
    }

    /** ACCOUNTING */

    /**
     * add $REWARD to claimable pot for the Pack
     * @param amount $REWARD to add to the pot
     * @param isGshare $REWARD type
     */
    function _payPackTax(uint256 amount, bool isGshare) internal {
        if (isGshare) {
            if (totalAlphaStakedForGshare == 0) {
                // if there's no staked predators
                unaccountedRewardsForGshare += amount; // keep track of $REWARD to predators
                return;
            }
            // makes sure to include any unaccounted $REWARD
            totalGshareRewardPerAlpha +=
                (amount + unaccountedRewardsForGshare) /
                totalAlphaStakedForGshare;
            unaccountedRewardsForGshare = 0;
        } else {
            if (totalAlphaStakedForGlad == 0) {
                // if there's no staked predators
                unaccountedRewardsForGlad += amount; // keep track of $REWARD to predators
                return;
            }
            // makes sure to include any unaccounted $REWARD
            totalGladRewardPerAlpha +=
                (amount + unaccountedRewardsForGlad) /
                totalAlphaStakedForGlad;
            unaccountedRewardsForGlad = 0;
        }
    }

    // modifier beforeDeadline() {
    //     require(
    //         block.timestamp <= claimDeadline,
    //         "Deadline for claiming from this pool has passed :("
    //     );
    //     _;
    // }

    /**
     * tracks earnings to ensure it is up to date
     */
    modifier updateEarnings(address _user) {
        {
            totalGshareRewardPerPrey = getGshareRewardPerPrey();
            if (totalPreyStakedForGshare != 0)
                lastTimestampForGshare = block.timestamp;
            totalGshareRewardPerAlpha = getGshareRewardPerAlpha();
            if (totalAlphaStakedForGshare != 0) {
                unaccountedRewardsForGshare = 0;
            }

            // update claimable prey gladshare reward
            userPool[_user].gladshare.claimableBarnReward +=
                (totalGshareRewardPerPrey -
                    userPool[_user].gladshare.lastRewardPerPrey) *
                userPool[_user].gladshare.preyStaked;
            userPool[_user].gladshare.claimablePackReward +=
                (totalGshareRewardPerAlpha -
                    userPool[_user].gladshare.lastRewardPerAlpha) *
                userPool[_user].gladshare.stakedAlpha;
            userPool[_user]
                .gladshare
                .lastRewardPerPrey = totalGshareRewardPerPrey;
            userPool[_user]
                .gladshare
                .lastRewardPerAlpha = totalGshareRewardPerAlpha;
            userPool[_user].gladshare.lastTimestamp = block.timestamp;
        }

        {
            totalGladRewardPerPrey = getGladRewardPerPrey();
            pendingGladReward = 0;
            if (totalPreyStakedForGlad != 0)
                lastTimestampForGlad = block.timestamp;
            totalGladRewardPerAlpha = getGladRewardPerAlpha();
            if (totalAlphaStakedForGlad != 0) {
                unaccountedRewardsForGlad = 0;
            }

            // update claimable prey glad reward
            userPool[_user].glad.claimableBarnReward +=
                (totalGladRewardPerPrey -
                    userPool[_user].glad.lastRewardPerPrey) *
                userPool[_user].glad.preyStaked;
            userPool[_user].glad.claimablePackReward +=
                (totalGladRewardPerAlpha -
                    userPool[_user].glad.lastRewardPerAlpha) *
                userPool[_user].glad.stakedAlpha;
            userPool[_user].glad.lastRewardPerPrey = totalGladRewardPerPrey;
            userPool[_user].glad.lastRewardPerAlpha = totalGladRewardPerAlpha;
            userPool[_user].glad.lastTimestamp = block.timestamp;
        }

        _;

        emit UserStakeChange(
            _user,
            userPool[_user].gladshare,
            userPool[_user].glad
        );
    }

    /* REWARD calculation */

    function getGshareRewardPerPrey() public view returns (uint256 amount) {
        if (block.timestamp <= stakingStart) return totalGshareRewardPerPrey;
        if (lastTimestampForGshare >= stakingEnd)
            return totalGshareRewardPerPrey;
        if (totalPreyStakedForGshare == 0) return totalGshareRewardPerPrey;
        uint256 periodstart = stakingStart > lastTimestampForGshare
            ? stakingStart
            : lastTimestampForGshare;
        uint256 periodend = stakingEnd < block.timestamp
            ? stakingEnd
            : block.timestamp;
        if (periodend <= periodstart) return totalGshareRewardPerPrey;
        return
            totalGshareRewardPerPrey +
            ((periodend - periodstart) * REWARS_PER_PREY_PER_PERIOD) /
            PERIOD /
            totalPreyStakedForGshare;
    }

    function getGladRewardPerPrey() public view returns (uint256 amount) {
        if (block.timestamp <= stakingStart) return totalGladRewardPerPrey;
        if (lastTimestampForGlad >= stakingEnd) return totalGladRewardPerPrey;
        if (totalPreyStakedForGlad == 0) return totalGladRewardPerPrey;
        if (pendingGladReward == 0) return totalGladRewardPerPrey;
        uint256 periodstart = stakingStart > lastTimestampForGlad
            ? stakingStart
            : lastTimestampForGlad;
        uint256 periodend = stakingEnd < block.timestamp
            ? stakingEnd
            : block.timestamp;
        if (periodend <= periodstart) return totalGladRewardPerPrey;
        return
            totalGladRewardPerPrey + pendingGladReward / totalPreyStakedForGlad;
    }

    function getGshareRewardPerAlpha() public view returns (uint256 amount) {
        if (totalAlphaStakedForGshare != 0) {
            // makes sure to include any unaccounted $REWARD
            return
                totalGshareRewardPerAlpha +
                (amount + unaccountedRewardsForGshare) /
                totalAlphaStakedForGshare;
        }
        return totalGshareRewardPerAlpha;
    }

    function getGladRewardPerAlpha() public view returns (uint256 amount) {
        if (totalAlphaStakedForGlad != 0) {
            // makes sure to include any unaccounted $REWARD
            return
                totalGladRewardPerAlpha +
                (amount + unaccountedRewardsForGlad) /
                totalAlphaStakedForGlad;
        }
        return totalGladRewardPerAlpha;
    }

    /* REWARD claiming */

    function claimBarnReward()
        public
        whenNotPaused
        //beforeDeadline
        updateEarnings(msg.sender)
    {
        address _user = msg.sender;
        {
            uint256 claimable = userPool[_user].gladshare.claimableBarnReward;
            userPool[_user].gladshare.claimableBarnReward = 0;
            uint256 tax = (claimable * REWARD_CLAIM_TAX_PERCENTAGE) / 100;
            _payPackTax(tax, true);
            if (claimable > 0) {
                gladshare.mint(_user, claimable - tax);
                emit BarnRewardClaimed(_user, true, claimable - tax, tax);
            }
        }
        {
            uint256 claimable = userPool[_user].glad.claimableBarnReward;
            userPool[_user].glad.claimableBarnReward = 0;
            uint256 tax = (claimable * REWARD_CLAIM_TAX_PERCENTAGE) / 100;
            _payPackTax(tax, false);
            if (claimable > 0) {
                IERC20(address(glad)).safeTransfer(_user, claimable - tax);
                emit BarnRewardClaimed(_user, false, claimable - tax, tax);
            }
        }
    }

    function claimPackReward()
        public
        whenNotPaused
        //beforeDeadline
        updateEarnings(msg.sender)
    {
        address _user = msg.sender;
        {
            uint256 claimable = userPool[_user].gladshare.claimablePackReward;
            userPool[_user].gladshare.claimablePackReward = 0;
            if (claimable > 0) {
                gladshare.mint(_user, claimable);
                emit PackRewardClaimed(_user, true, claimable);
            }
        }
        {
            uint256 claimable = userPool[_user].glad.claimablePackReward;
            userPool[_user].glad.claimablePackReward = 0;
            if (claimable > 0) {
                IERC20(address(glad)).safeTransfer(_user, claimable);
                emit PackRewardClaimed(_user, false, claimable);
            }
        }
    }

    /** TREASURY */

    function addGladReward(uint256 amount) external {
        require(msg.sender == address(treasury), "not treasury");

        IERC20(address(glad)).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
        pendingGladReward += amount;
    }

    /** ADMIN */

    /**
     * allows owner to enable "rescue mode"
     * simplifies accounting, prioritizes tokens out in emergency
     */
    function setRescueEnabled() external onlyOwner {
        if (!paused()) _pause(); //rescue should also pause
        stakingEnd = block.timestamp;
        rescueEnabled = true;
    }

    function setEntropy(address _entropy) external onlyOwner {
        entropy = IEntropy(_entropy);
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = ITreasury(_treasury);
    }

    function setMigrationContract(address _c) external onlyOwner {
        migrationContract = _c;
    }

    // function addToRandomWhitelist(address[] calldata _addr) external onlyOwner {
    //     for (uint256 i = 0; i < _addr.length; i++) {
    //         randomWhitelist[_addr[i]] = true;
    //     }
    // }

    function setStealChance(
        uint256 _predatorunstake,
        uint256 _preyunstake,
        uint256 _rewardsteal
    ) external onlyOwner {
        STEALCHANCE_PREDATOR_UNSTAKE = _predatorunstake;
        STEALCHANCE_PREY_UNSTAKE = _preyunstake;
        REWARD_CLAIM_TAX_PERCENTAGE = _rewardsteal;
    }

    function setLockEpoch(uint256 _lockEpoch) external onlyOwner {
        LOCK_EPOCH = _lockEpoch;
    }

    function setStakingParams(uint256 _rewardrate) external onlyOwner {
        REWARS_PER_PREY_PER_PERIOD = _rewardrate;
    }

    // function removeFromRandomWhitelist(address[] calldata _addr)
    //     external
    //     onlyOwner
    // {
    //     for (uint256 i = 0; i < _addr.length; i++) {
    //         randomWhitelist[_addr[i]] = false;
    //     }
    // }

    /**
     * enables owner to pause / unpause minting
     */
    function setPaused(bool _paused) external onlyOwner {
        require(!rescueEnabled || _paused == true, "RECSUE ON");
        if (_paused) _pause();
        else _unpause();
    }

    /** READ ONLY */

    /**
     * checks if a token is a Prey
     * @param tokenId the ID of the token to check
     * @return prey - whether or not a token is a Prey
     */
    function isPrey(uint256 tokenId) public view returns (bool prey) {
        IPreyPredator.PreyPredator memory iPreyPredator = preyPredator
            .getTokenTraits(tokenId);
        return iPreyPredator.isPrey;
    }

    /**
     * gets the alpha score for a Predaror
     * @param tokenId the ID of the Predator to get the alpha score for
     * @return the alpha score of the PRedator
     */
    function _alphaForPredator(uint256 tokenId)
        internal
        view
        returns (uint256)
    {
        IPreyPredator.PreyPredator memory iPreyPredator = preyPredator
            .getTokenTraits(tokenId);

        return alphaIndexToAlphaLUT[iPreyPredator.alphaIndex];
    }

    function getClaimableGladshareBarnReward(address _user)
        external
        view
        returns (uint256 amount)
    {
        // if (block.timestamp > claimDeadline) return 0;
        uint256 tmp = getGshareRewardPerPrey();
        return
            userPool[_user].gladshare.claimableBarnReward +
            (tmp - userPool[_user].gladshare.lastRewardPerPrey) *
            userPool[_user].gladshare.preyStaked;
    }

    function getClaimableGladBarnReward(address _user)
        external
        view
        returns (uint256 amount)
    {
        // if (block.timestamp > claimDeadline) return 0;
        uint256 tmp = getGladRewardPerPrey();
        return
            userPool[_user].glad.claimableBarnReward +
            (tmp - userPool[_user].glad.lastRewardPerPrey) *
            userPool[_user].glad.preyStaked;
    }

    function getClaimableGladsharePackReward(address _user)
        external
        view
        returns (uint256 amount)
    {
        // if (block.timestamp > claimDeadline) return 0;
        return
            userPool[_user].gladshare.claimablePackReward +
            (totalGshareRewardPerAlpha -
                userPool[_user].gladshare.lastRewardPerAlpha) *
            userPool[_user].gladshare.stakedAlpha;
    }

    function getClaimableGladPackReward(address _user)
        external
        view
        returns (uint256 amount)
    {
        // if (block.timestamp > claimDeadline) return 0;
        return
            userPool[_user].glad.claimablePackReward +
            (totalGladRewardPerAlpha -
                userPool[_user].glad.lastRewardPerAlpha) *
            userPool[_user].glad.stakedAlpha;
    }

    // function getUserStake(address userid)
    //     external
    //     view
    //     returns (UserInfo memory)
    // {
    //     return userPool[userid];
    // }

    // function getRandomPreyOwner(uint256 seed) external view returns (address) {
    //     require(
    //         randomWhitelist[msg.sender],
    //         "Not allowed to request random staker"
    //     );
    //     return _randomPreyStake(seed).owner;
    // }

    // /**
    //  * chooses a random Prey Owner
    //  * @param seed a random value to choose a Prey from
    //  * @return the owner of the randomly selected Prey
    //  */
    // function getRandomPreyStake(uint256 seed)
    //     external
    //     view
    //     returns (Stake memory)
    // {
    //     require(
    //         randomWhitelist[msg.sender],
    //         "Not allowed to request random staker"
    //     );
    //     return _randomPreyStake(seed);
    // }

    // function _randomPreyStake(uint256 seed)
    //     internal
    //     view
    //     returns (Stake memory)
    // {
    //     if (totalPreyStakedForGshare == 0) return Stake(0, address(0));
    //     // choose a value from Barn
    //     return barn[(seed & 0xFFFFFFFFFFFFFFFF) % totalPreyStakedForGshare];
    // }

    function getRandomPredatorOwner(uint256 seed)
        external
        view
        returns (address)
    {
        // require(
        //     randomWhitelist[msg.sender],
        //     "Not allowed to request random staker"
        // );
        return _randomPredatorStake(seed).owner;
    }

    /**
     * chooses a random Predator owner based on alpha score
     * @param seed a random value to choose a Predator from
     * @return the owner of the randomly selected Predator
     */
    function getRandomPredatorStake(uint256 seed)
        external
        view
        returns (Stake memory)
    {
        // require(
        //     randomWhitelist[msg.sender],
        //     "Not allowed to request random staker"
        // );
        return _randomPredatorStake(seed);
    }

    function _randomPredatorStake(uint256 seed)
        internal
        view
        returns (Stake memory)
    {
        uint256 totalAlphaStaked = totalAlphaStakedForGshare +
            totalAlphaStakedForGlad;
        if (totalAlphaStaked == 0) return Stake(0, address(0));

        // choose a value from 0 to total alpha staked
        uint256 bucket = (seed & 0xFFFFFFFFFFFF) % totalAlphaStaked;
        uint256 cumulative;
        seed >>= 48;

        // loop through each bucket of Predators with the same alpha score
        for (uint256 i = 0; i < alphaIndexToAlphaLUT.length; i++) {
            uint256 alpha = alphaIndexToAlphaLUT[i];
            cumulative += pack[alpha].length * alpha;
            // if the value is not inside of that bucket, keep going
            if (bucket >= cumulative) continue;
            // get the address of a random Predator with that alpha score
            return pack[alpha][seed % pack[alpha].length];
        }
        return Stake(0, address(0));
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        revert("Dont accept");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyPausable is Pausable, Ownable {
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBasisAsset {
    function mint(address recipient, uint256 amount) external returns (bool);

    function burn(uint256 amount) external;

    function burnFrom(address from, uint256 amount) external;

    function isOperator() external returns (bool);

    function operator() external view returns (address);

    function transferOperator(address newOperator_) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ITreasury {
    function epoch() external view returns (uint256);

    function nextEpochPoint() external view returns (uint256);

    function getGladPrice() external view returns (uint256);

    function addDebt(uint256 debt) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity =0.8.9;

interface IPool {
    // struct to store a stake's token, owner, and earning values
    struct Stake {
        uint64 tokenId;
        address owner;
    }

    struct UserStake {
        uint80 lastTimestamp;
        uint64 preyStaked;
        uint64 predatorsStaked;
        // barn staking
        uint256 lastRewardPerPrey;
        uint256 claimableBarnReward;
        // pack staking
        uint256 claimablePackReward;
        uint256 stakedAlpha;
        uint256 lastRewardPerAlpha;
    }

    function addManyToPool(uint64[] calldata tokenIds) external;

    function claimManyFromPool(uint64[] calldata tokenIds) external;

    function getUserStake(address userid)
        external
        view
        returns (UserStake memory);

    function getRandomPredatorOwner(uint256 seed)
        external
        view
        returns (address);

    function getRandomPreyOwner(uint256 seed) external view returns (address);

    function getRandomPredatorStake(uint256 seed)
        external
        view
        returns (Stake memory);

    function getRandomPreyStake(uint256 seed)
        external
        view
        returns (Stake memory);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface ITraits {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

interface IPreyPredator {
    event TokenTraitsUpdated(uint256 tokenId, PreyPredator traits);
    // struct to store each token's traits
    struct PreyPredator {
        bool isPrey;
        uint8 environment;
        uint8 body;
        uint8 armor;
        uint8 helmet;
        uint8 shoes;
        uint8 shield;
        uint8 weapon;
        uint8 item;
        uint8 alphaIndex;
        uint64 generation;
        uint8 agility;
        uint8 charisma;
        uint8 damage;
        uint8 defense;
        uint8 dexterity;
        uint8 health;
        uint8 intelligence;
        uint8 luck;
        uint8 strength;
    }

    function traitsRevealed(uint256 tokenId) external view returns (bool);

    function getTokenTraits(uint256 tokenId)
        external
        view
        returns (PreyPredator memory);

    function mintUnderpeg(
        address to,
        uint256 amount,
        uint256 price
    ) external;

    function mintGeneric (
        address to,
        uint256 amount,
        uint256 price,
        uint256 generation,
        bool stealing
    ) external;

    function increaseGeneration() external;

    function currentGeneration() external view returns (uint8);

    function getGenTokens(uint8 generation) external view returns (uint256);

    function mintedPrice(uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.9;

interface IWhitelist {
    // total size of the whitelist
    function wlSize() external view returns (uint256);
    // max number of wl spot sales
    function maxSpots() external view returns (uint256);
    // price of the WL spot
    function spotPrice() external view returns (uint256);
    // number of wl spots sold
    function spotCount() external view returns (uint256);
    // glad/wl sale has started
    function started() external view returns (bool);
    // wl sale has ended
    function wlEnded() external view returns (bool);
    // glad sale has ended
    function gladEnded() external view returns (bool);
    // total glad sold (wl included)
    function totalPGlad() external view returns (uint256);
    // total whitelisted glad sold
    function totalPGladWl() external view returns (uint256);

    // minimum glad amount buyable
    function minGladBuy() external view returns (uint256);
    // max glad that a whitelisted can buy @ discounted price
    function maxWlAmount() external view returns (uint256);

    // pglad sale price (for 100 units, so 30 means 0.3 avax / pglad)
    function pGladPrice() external view returns (uint256);
    // pglad wl sale price (for 100 units, so 20 means 0.2 avax / pglad)
    function pGladWlPrice() external view returns (uint256);

    // get the amount of pglad purchased by user (wl buys included)
    function pGlad(address _a) external view returns (uint256);
    // get the amount of wl plgad purchased
    function pGladWl(address _a) external view returns (uint256);

    // buy whitelist spot, avax value must be sent with transaction
    function buyWhitelistSpot() external payable;

    // buy pglad, avax value must be sent with transaction
    function buyPGlad(uint256 _amount) external payable;

    // check if an address is whitelisted
    function isWhitelisted(address _a) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Operator is Context, Ownable {
    address private _operator;

    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);

    constructor() {
        _operator = _msgSender();
        emit OperatorTransferred(address(0), _operator);
    }

    function operator() public view returns (address) {
        return _operator;
    }

    modifier onlyOperator() {
        require(_operator == msg.sender, "operator: caller is not the operator");
        _;
    }

    function isOperator() public view returns (bool) {
        return _msgSender() == _operator;
    }

    function transferOperator(address newOperator_) public onlyOwner {
        _transferOperator(newOperator_);
    }

    function _transferOperator(address newOperator_) internal {
        require(newOperator_ != address(0), "operator: zero address given for new operator");
        emit OperatorTransferred(address(0), newOperator_);
        _operator = newOperator_;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Blacklistable is Context, Ownable {
    mapping(address => bool) private _blacklisted;

    modifier checkBlacklist(address account) {
        require(!_blacklisted[account], "Blacklistable: caller is blacklisted");
        _;
    }

    function isBlacklisted(address account) public view returns (bool) {
        return _blacklisted[account];
    }

    function addToBlacklist(address[] memory accounts) public onlyOwner {
        uint256 length = accounts.length;
        for (uint256 i; i < length; i++) {
            _blacklisted[accounts[i]] = true;
        }
    }

    function removeFromBlacklist(address[] memory accounts) public onlyOwner {
        uint256 length = accounts.length;
        for (uint256 i; i < length; i++) {
            _blacklisted[accounts[i]] = false;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/ERC721Royalty.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../common/ERC2981.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev Extension of ERC721 with the ERC2981 NFT Royalty Standard, a standardized way to retrieve royalty payment
 * information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC721Royalty is ERC2981, ERC721 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally clears the royalty information for the token.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `tokenId` must be already minted.
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}
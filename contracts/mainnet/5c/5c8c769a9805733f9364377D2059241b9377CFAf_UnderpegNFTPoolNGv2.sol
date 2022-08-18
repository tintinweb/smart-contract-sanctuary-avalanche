// SPDX-License-Identifier: MIT LICENSE
pragma solidity =0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./IPreyPredator.sol";
import "./IPool.sol";
import "./IEntropy.sol";
import "../../Controllable.sol";
import "../../interfaces/IBasisAsset.sol";
import "../../interfaces/ITreasury.sol";
import "../../utils/MyPausable.sol";


contract UnderpegNFTPoolNGv2 is Controllable, IERC721Receiver, MyPausable {
    using SafeERC20 for IERC20;

    struct Stake {
        address owner;
        uint80 stakedAt;
        uint256 tokenId;
        uint256 mintPrice;
        uint256 premium;
        uint256 claimed;
    }

    /// @dev tokenId => total claimed amount
    mapping(uint256 => uint256) public claimed;

    /// @dev Translates the alpha index of a Predator to effective Alpha
    uint16[] alphaIndexToAlphaLUT = [100, 120, 140, 160, 180];

    /// @dev maps tokenId to stake
    Stake[] public barn;
    // tracks location of each Prey in Barn
    mapping(uint256 => uint256) public barnIndices;

    /// @dev maps alpha to all Predator stakes with that alpha
    mapping(uint256 => Stake[]) public pack;
    /// @dev tracks location of each Predator in Pack
    mapping(uint256 => uint256) public packIndices;
    /// @dev total alpha staked
    uint256 public totalAlphaStaked;
    /// @dev total predator staked
    uint256 public totalPredatorsStaked;
    /// @dev number of Prey staked in the Barn
    uint256 public totalPreyStaked;

    /// @dev reference to the PreyPredator NFT contract
    address public preyPredator;
    /// @dev reference to the reward token contract for staking (GLAD)
    IBasisAsset public rewardToken;
    /// @dev reference to Entropy
    IEntropy entropy;
    /// @dev reference to the Treasury contract
    ITreasury public treasury;

    uint256 mySeed;

    uint256 public lockPeriod;

    uint8 public STEALCHANCE_PREDATOR_UNSTAKE = 5;
    uint8 public STEALCHANCE_PREY_UNSTAKE = 20;

    uint256 public preyPremiumMultiplier = 80;
    uint256 public predatorPremiumBaseMultiplier = 120;

    uint256 public generationMin = 23;
    uint256 public generationMax = 24;
    mapping(uint256 => bool) public generationWhitelist;
    mapping(uint256 => bool) public alreadyStaked;


    bool public canMigrate;
    bool public parametersLoaded;
    uint256 public preyLoadIndex;
    bool public preyLoaded;
    uint256[5] public predatorLoadIndex;
    bool[5] public predatorLoaded;

    UnderpegNFTPoolNGv2 public oldPool;

    event TokenStaked(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 mintPrice,
        uint256 premium,
        bool isPrey
    );
    event TokenClaimed(uint256 indexed tokenId, bool isPrey);
    event Claimed(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 reward
    );

    /**
     * @param _preyPredator reference to the PreyPredator NFT contract
     * @param _rewardToken reference to the $Reward token (GLADSHARE)
     * @param _treasury reference to the Treasury
     */
    constructor(
        address _preyPredator,
        address _rewardToken,
        address _entropy,
        address _treasury,
        address _oldpool
    ) {
        preyPredator = _preyPredator;
        rewardToken = IBasisAsset(_rewardToken);
        entropy = IEntropy(_entropy);
        treasury = ITreasury(_treasury);

        lockPeriod = 42; // Lock NFTs for 42 epochs (= 7 days)

        oldPool = UnderpegNFTPoolNGv2(_oldpool);

        canMigrate = true;
        _pause();
    }

      function migrateParams()  external onlyOwner {
        require(canMigrate, "Migration no longer possible");
        require(!parametersLoaded, "Params already migrated");
        totalAlphaStaked = oldPool.totalAlphaStaked();
        totalPredatorsStaked = oldPool.totalPredatorsStaked();
        totalPreyStaked = oldPool.totalPreyStaked();
        parametersLoaded = true;
    }

    function loadPreyTokens()  external onlyOwner {
        require(canMigrate, "Migration no longer possible");
        require(!preyLoaded, "Preys already loaded");
        uint256 cnt = oldPool.totalPreyStaked();
        uint256 i;
        for (; gasleft() > 300000 && preyLoadIndex + i < cnt; i++) {
            (address owner, uint80 stakedAt, uint256 tokenId, uint256 mintPrice, uint256 premium, uint256 claimed) = oldPool.barn(i + preyLoadIndex);
            barn.push(Stake(owner, stakedAt, tokenId, mintPrice, premium, claimed));
            barnIndices[tokenId] = oldPool.barnIndices(tokenId);
            IERC721Metadata(preyPredator).transferFrom(address(oldPool), address(this), tokenId);
            emit TokenStaked(owner, tokenId, mintPrice, premium, true);
            if (claimed > 0) emit Claimed(owner, tokenId, claimed);
        }
        preyLoadIndex += i;
        if (preyLoadIndex == cnt) {
            preyLoaded = true;
        }
    }

    function loadPredatorTokens(uint256 alphaIndex)  external onlyOwner {
        require(canMigrate, "Migration no longer possible");
        require(!predatorLoaded[alphaIndex], "This predator group has already been imported");
        uint256 i;
        for (; gasleft() > 300000 ; i++) {
            try oldPool.pack(alphaIndexToAlphaLUT[alphaIndex], predatorLoadIndex[alphaIndex] + i) returns (address owner, uint80 stakedAt, uint256 tokenId, uint256 mintPrice, uint256 premium, uint256 claimed) {
                pack[alphaIndex].push(Stake(owner, stakedAt, tokenId, mintPrice, premium, claimed));
                packIndices[tokenId] = oldPool.packIndices(tokenId);
                IERC721Metadata(preyPredator).transferFrom(address(oldPool), address(this), tokenId);
                emit TokenStaked(owner, tokenId, mintPrice, premium, false);
                if (claimed > 0) emit Claimed(owner, tokenId, claimed);
            } catch {
                predatorLoaded[alphaIndex] = true;
                break;
            }
        }
        predatorLoadIndex[alphaIndex] += i;
    }

    
    // closemigration.... typo 
    function closeMigration() external {
        require(canMigrate, "Migration no longer possible");
        require(parametersLoaded, "Params not yet migrated");
        require(preyLoaded, "Prey not yet loaded");
        require(predatorLoaded[0], "Alpha 0 not yet imported");
        require(predatorLoaded[1], "Alpha 1 not yet imported");
        require(predatorLoaded[2], "Alpha 2 not yet imported");
        require(predatorLoaded[3], "Alpha 3 not yet imported");
        require(predatorLoaded[4], "Alpha 4 not yet imported");
        canMigrate = false;
    }

    function stakeBatch(uint256[] calldata tokens)
        external
    {
        require(msg.sender == tx.origin, "Only EOA");
        for (uint256 i = 0; i < tokens.length; i++) _stake(tokens[i]);
    }

    function stake(uint256 tokenId)
        external
    {
        require(msg.sender == tx.origin, "Only EOA");
        _stake(tokenId);
    }

    function _stake(uint256 tokenId)
        internal
        whenNotPaused
    {
        IPreyPredator.PreyPredator memory traits = IPreyPredator(preyPredator).getTokenTraits(tokenId);

        require(
            traits.generation <= generationMax && traits.generation >= generationMin || generationWhitelist[traits.generation],
            "not eligible nft"
        );
        
        address staker = msg.sender;

        require(!alreadyStaked[tokenId], "This NFT has already been staked in the underpeg pool");
        alreadyStaked[tokenId] = true;

        require(
            IERC721Metadata(preyPredator).ownerOf(tokenId) == staker,
            "stake: not owning the nft"
        );

        IERC721Metadata(preyPredator).safeTransferFrom(
            staker,
            address(this),
            tokenId
        );

        uint256 mintPrice;
        if (traits.generation == 24) mintPrice = 21e18;
        else mintPrice = IPreyPredator(preyPredator).mintedPrice(tokenId);
        uint256 premium = _calcPremium(tokenId, traits, mintPrice);

        if (traits.isPrey)
            _addPreyToBarn(staker, tokenId, mintPrice, premium);
        else _addPredatorToPack(staker, tokenId, mintPrice, premium);

        treasury.addDebt(mintPrice + premium);
    }

    function unstakeBatch(uint256[] calldata tokens)
        external
    {
        require(msg.sender == tx.origin, "Only EOA");
        for (uint256 i = 0; i < tokens.length; i++) _unstake(tokens[i]);
    }

    function unstake(uint256 tokenId) external whenNotPaused {
        require(msg.sender == tx.origin, "Only EOA");
        _unstake(tokenId);
    }

    function _unstake(uint256 tokenId) internal whenNotPaused {
        Stake memory _stake = _getStake(tokenId);
        uint256 epoch = treasury.epoch();
        require(
            epoch > _stake.stakedAt + lockPeriod,
            "unstake: nft locked"
        );

        uint256 reward = _claim(tokenId);

        if (isPrey(tokenId)) _claimPreyFromBarn(tokenId);
        else _claimPredatorFromPack(tokenId);

        if (reward > 0) {
            IERC20(address(rewardToken)).safeTransferFrom(
                address(treasury),
                msg.sender,
                reward
            );
        }
        IERC721Metadata(preyPredator).safeTransferFrom(
            address(this),
            msg.sender,
            tokenId
        );
    }

    function claim(uint256[] memory tokenIds) external whenNotPaused {
        uint256 reward;
        for (uint256 i; i < tokenIds.length; i++) {
            reward += _claim(tokenIds[i]);
        }
        
        if (reward > 0) {
            IERC20(address(rewardToken)).safeTransferFrom(
                address(treasury),
                msg.sender,
                reward
            );
        }
    }

    /** READ */

    /**
     * checks if a token is a Prey
     * @param tokenId the ID of the token to check
     * @return prey - whether or not a token is a Prey
     */
    function isPrey(uint256 tokenId) public view returns (bool prey) {
        IPreyPredator.PreyPredator memory t = IPreyPredator(preyPredator)
            .getTokenTraits(tokenId);
        return t.isPrey;
    }

    function getPendingReward(uint256 tokenId) external view returns (uint256) {
        return _getPendingReward(tokenId);
    }

    /** INTERNAL */

    function _claim(uint256 tokenId) internal returns (uint256 pendingReward) {
        Stake storage stake = _getStake(tokenId);
        require(stake.owner == msg.sender, "not staked");

        pendingReward = _getPendingReward(tokenId);

        stake.claimed += pendingReward;

        emit Claimed(msg.sender, tokenId, pendingReward);
    }

    /**
     * gets the alpha score for a Predaror
     * @param tokenId the ID of the Predator to get the alpha score for
     * @return the alpha score of the PRedator
     */
    function _alphaForPredator(uint256 tokenId) internal view returns (uint16) {
        IPreyPredator.PreyPredator memory t = IPreyPredator(preyPredator)
            .getTokenTraits(tokenId);

        return alphaIndexToAlphaLUT[t.alphaIndex];
    }

    /**
     * adds a single Prey to the Barn
     * @param account the address of the staker
     * @param tokenId the ID of the Prey to add to the Barn
     * @param mintPrice the token mint price
     * @param premium the premium amount
     */
    function _addPreyToBarn(
        address account,
        uint256 tokenId,
        uint256 mintPrice,
        uint256 premium
    ) internal {
        totalPreyStaked += 1;
        barnIndices[tokenId] = barn.length;
        barn.push(
            Stake({
                owner: account,
                stakedAt: uint80(treasury.epoch()),
                tokenId: uint64(tokenId),
                mintPrice: mintPrice,
                premium: premium,
                claimed: 0
            })
        );

        emit TokenStaked(account, tokenId, mintPrice, premium, true);
    }

    /**
     * adds a single Predator to the Pack
     * @param account the address of the staker
     * @param tokenId the ID of the Predator to add to the Pack
     * @param mintPrice the token mint price
     * @param premium the premium amount
     */
    function _addPredatorToPack(
        address account,
        uint256 tokenId,
        uint256 mintPrice,
        uint256 premium
    ) internal {
        uint256 alpha = _alphaForPredator(tokenId);
        totalAlphaStaked += alpha; // Portion of earnings mapped
        totalPredatorsStaked += 1;
        packIndices[tokenId] = pack[alpha].length; // Store the location of the predator in the Pack
        pack[alpha].push(
            Stake({
                owner: account,
                stakedAt: uint80(treasury.epoch()),
                tokenId: uint64(tokenId),
                mintPrice: mintPrice,
                premium: premium,
                claimed: 0
            })
        ); // Add the predator to the Pack

        emit TokenStaked(account, tokenId, mintPrice, premium, false);
    }

    /**
     * unstake a single Prey
     * @param tokenId the ID of the Prey to claim
     */
    function _claimPreyFromBarn(uint256 tokenId) internal {
        Stake memory stake = barn[barnIndices[tokenId]];

        require(stake.owner == _msgSender(), "Not your NFT");
        totalPreyStaked -= 1;

        address owner = stake.owner;
        uint256 rnd = entropy.random(mySeed++);
        if (totalAlphaStaked > 0 && rnd % 100 < STEALCHANCE_PREY_UNSTAKE) {
            rnd >>= 8;
            owner = _randomPredatorStake(rnd).owner;
        }
        IERC721Metadata(preyPredator).safeTransferFrom(
            address(this),
            owner,
            tokenId,
            ""
        );

        Stake memory lastStake = barn[barn.length - 1];
        barn[barnIndices[tokenId]] = lastStake; // Shuffle last Prey to current position
        barnIndices[lastStake.tokenId] = barnIndices[tokenId];
        barn.pop(); // Remove duplicate

        delete barnIndices[tokenId]; // Delete old mapping
        emit TokenClaimed(tokenId, true);
    }

    /**
     * claim a single Predator
     * @param tokenId the ID of the Predator to claim
     */
    function _claimPredatorFromPack(uint256 tokenId) internal {
        uint256 alpha = _alphaForPredator(tokenId);
        Stake memory _stake = pack[alpha][packIndices[tokenId]];
        require(_stake.owner == _msgSender(), "Not your NFT");

        totalAlphaStaked -= alpha; // Remove Alpha from total staked

        Stake memory lastStake = pack[alpha][pack[alpha].length - 1]; // get last
        pack[alpha][packIndices[tokenId]] = lastStake; // Shuffle last Predator to current position
        packIndices[lastStake.tokenId] = packIndices[tokenId];
        pack[alpha].pop(); // Remove duplicate
        totalPredatorsStaked -= 1;
        delete packIndices[tokenId]; // Delete old mapping

        address owner = _stake.owner;
        uint256 rnd = entropy.random(mySeed++);
        if (totalAlphaStaked > 0 && rnd % 100 < STEALCHANCE_PREDATOR_UNSTAKE) {
            rnd >>= 8;
            owner = _randomPredatorStake(rnd).owner;
        }
        IERC721Metadata(preyPredator).safeTransferFrom(
            address(this),
            owner,
            tokenId,
            ""
        );

        emit TokenClaimed(tokenId, false);
    }

    function _getStake(uint256 tokenId) internal view returns (Stake storage) {
        if (isPrey(tokenId)) return barn[barnIndices[tokenId]];
        else {
            uint256 alpha = _alphaForPredator(tokenId);
            return pack[alpha][packIndices[tokenId]];
        }
    }

    function _getPendingReward(uint256 tokenId)
        internal
        view
        returns (uint256 pendingReward)
    {
        Stake memory _stake = _getStake(tokenId);
        uint256 epoch = treasury.epoch();
        uint256 lockedEpoch = epoch - _stake.stakedAt;
        if (lockedEpoch > lockPeriod * 3) return 0;
        if (lockedEpoch > lockPeriod) {
            if (lockedEpoch <= lockPeriod * 2) pendingReward = _stake.premium;
            lockedEpoch = lockPeriod;
        }
        pendingReward +=
            (_stake.mintPrice * lockedEpoch) /
            lockPeriod;
        if (_stake.claimed >= pendingReward) return 0;
        pendingReward -= _stake.claimed;
    }

    function _calcPremium(uint256 tokenId, IPreyPredator.PreyPredator memory t, uint256 mintPrice) internal view returns (uint256) {
        if (t.isPrey) {
            return
                (mintPrice *
                    preyPremiumMultiplier) / 100;
        } else {
            return
                (mintPrice *
                    (predatorPremiumBaseMultiplier + 20 * t.alphaIndex)) / 100;
        }
    }

    function _randomPredatorStake(uint256 seed)
        internal
        view
        returns (Stake memory)
    {
        if (totalAlphaStaked == 0) return Stake(address(0), 0, 0, 0, 0, 0);

        // choose a value from 0 to total alpha staked
        uint256 bucket = (seed & 0xFFFFFFFFFFFF) % totalAlphaStaked;
        uint256 cumulative;
        seed >>= 48;

        // loop through each bucket of Predators with the same alpha score
        for (uint256 i = 0; i < alphaIndexToAlphaLUT.length; i++) {
            uint16 alpha = alphaIndexToAlphaLUT[i];
            cumulative += pack[alpha].length * alpha;
            // if the value is not inside of that bucket, keep going
            if (bucket >= cumulative) continue;
            // get the address of a random Predator with that alpha score
            return pack[alpha][seed % pack[alpha].length];
        }
        return Stake(address(0), 0, 0, 0, 0, 0);
    }

    /** ADMIN */

    function setEntropy(address _entropy) external onlyOwner {
        entropy = IEntropy(_entropy);
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = ITreasury(_treasury);
    }

    function setLockPeriod(uint256 _lockPeriod) external onlyOwner {
        lockPeriod = _lockPeriod;
    }

    function setStealChance(uint8 _predatorUnstake, uint8 _preyUnstake)
        external
        onlyOwner
    {
        STEALCHANCE_PREDATOR_UNSTAKE = _predatorUnstake;
        STEALCHANCE_PREY_UNSTAKE = _preyUnstake;
    }

    function setEligibleGenerations(uint256 _min, uint256 _max) external onlyOwner {
        generationMin = _min;
        generationMax = _max;
    }

    function whitelistAddGeneration(uint256 _g) external onlyOwner {
        generationWhitelist[_g] = true;
    }

    function whitelistRemoveGeneration(uint256 _g) external onlyOwner {
        generationWhitelist[_g] = false;
    }

    function setPreyPremiumMultiplier(uint256 _preyPremiumMultiplier)
        external
        onlyOwner
    {
        require(
            _preyPremiumMultiplier <= 100,
            "preyPremiumMultiplier: out of range"
        );
        preyPremiumMultiplier = _preyPremiumMultiplier;
    }

    function setPredatorPremiumBaseMultiplier(uint256 _predatorPremiumBase)
        external
        onlyOwner
    {
        require(
            predatorPremiumBaseMultiplier <= 200,
            "preyPremiumMultiplier: out of range"
        );
        predatorPremiumBaseMultiplier = _predatorPremiumBase;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
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
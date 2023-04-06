// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

import "lockerz-ticketz/contracts/LockerzTicketz.sol";

import "./Tokens.sol";
import "./Portalz.sol";
import "./MetadataStorage.sol";

// ERC20 interface
interface IFleshToken is IERC20 {
    function activateRottingRatio(address account) external;
}

interface IrFleshToken is IERC20 {
    function burnFrom(address account, uint256 amount) external;
}

contract PortalzSquadz is Ownable, Pausable, ERC721Holder, Multicall {
    uint256 public constant BASIS_POINT = 10000;

    /**
     @dev Max number of squadz used to iterate in the mapping.
    */
    uint8 public constant MAX_SQUADZ = 100;

    /**
     @dev Max number of slots used to iterate in the mapping.
    */
    uint8 public constant MAX_SLOTS = 100;

    event StakedTokens(
        uint256 timestamp,
        address sender,
        Tokens.ERC165Token[] tokens,
        uint256 squadzId,
        address portalzAddress
    );

    event UnstakedTokens(
        uint256 timestamp,
        address sender,
        Tokens.ERC165Token[] tokens,
        uint256 squadzId,
        address portalzAddress,
        uint256 rewardAmount,
        address rewardAddress,
        Tokens.ERC165Token bonusToken
    );

    event UnlockedNewSquadz(
        uint256 timestamp,
        address sender,
        uint256 squadzId
    );

    event UnlockedNewSlot(
        uint256 timestamp,
        address sender,
        uint256 squadzId,
        uint256 slots
    );

    event NoMoreTokenReward(
        uint256 timestamp,
        address sender,
        uint256 squadzId,
        address portalzAddress,
        uint256 rewardAmount
    );

    event NoMoreBonusTokenReward(
        uint256 timestamp,
        address sender,
        uint256 squadzId,
        address portalzAddress,
        Tokens.ERC165Token bonusToken
    );

    IFleshToken private _fleshToken;
    IrFleshToken private _rFleshToken;
    MetadataStorage private _metadataStorage;
    LockerzTicketz private _lockerzTicketz;

    mapping(address => bool) public canStakeInPortalz;
    mapping(address => bool) public canUnstakeFromPortalz;

    // Current max number of Squadz a user can unlock
    uint8 public currentMaxSquadz = 3;

    /// @notice Detail info of a squad
    struct Squadz {
        /// Tokens staked (contract address and token id), only filled when staked
        Tokens.ERC165Token[] tokens;
        /// Address of the portalz the squad was sent in, only != address(0) when staked
        address portalzAddress;
        /// Time when the squad was sent, only > 0 when staked
        uint256 sentStartTime;
        /// Number of staking slots the staker has unlocked for this squad
        uint256 slotsAvailable;
    }

    // Mapping of User Address to Staker info
    mapping(address => mapping(uint256 => Squadz)) private _stakers;

    /// Prices for each slots in FLSH
    mapping(uint256 => mapping(uint256 => uint256)) private _squadzPrices;

    constructor(
        address fleshToken,
        address rFleshToken,
        address metadataStorage,
        address lockerzTicketz,
        uint256[][] memory squadzPrices
    ) {
        _fleshToken = IFleshToken(fleshToken);
        _rFleshToken = IrFleshToken(rFleshToken);
        _metadataStorage = MetadataStorage(metadataStorage);
        _lockerzTicketz = LockerzTicketz(lockerzTicketz);

        for (uint256 i = 0; i < squadzPrices.length; i = unsafeInc(i)) {
            for (uint256 j = 0; j < squadzPrices[i].length; j = unsafeInc(j)) {
                _squadzPrices[i][j] = squadzPrices[i][j];
            }
        }
    }

    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "1001");
        payable(msg.sender).transfer(address(this).balance);
    }

    /* ********************************** */
    /*              Staking               */
    /* ********************************** */

    function stake(
        Tokens.ERC165Token[] calldata tokens,
        uint256 squadzId,
        address portalzAddress
    ) external {
        require(canStakeInPortalz[portalzAddress], "1002");
        require(squadzId < numberOfSquadz(msg.sender), "1004");

        require(
            _stakers[msg.sender][squadzId].tokens.length == 0 &&
                _stakers[msg.sender][squadzId].sentStartTime == 0 &&
                _stakers[msg.sender][squadzId].portalzAddress == address(0),
            "1005"
        );
        require(
            tokens.length <= _stakers[msg.sender][squadzId].slotsAvailable,
            "1006"
        );

        Portalz portalz = Portalz(portalzAddress);
        require(portalz.areTokensAllowed(tokens), "1007");

        for (uint256 i = 0; i < tokens.length; i = unsafeInc(i)) {
            IERC721 token = IERC721(tokens[i].contractAddress);
            require(token.ownerOf(tokens[i].tokenId) == msg.sender, "1008");
            token.transferFrom(msg.sender, address(this), tokens[i].tokenId);
            _stakers[msg.sender][squadzId].tokens.push(tokens[i]);
            _lockerzTicketz.safeMint(
                msg.sender,
                LockerzTicketz.Ticketz(
                    tokens[i].contractAddress,
                    tokens[i].tokenId
                )
            );
        }
        _stakers[msg.sender][squadzId].portalzAddress = portalzAddress;
        _stakers[msg.sender][squadzId].sentStartTime = block.timestamp;

        emit StakedTokens(
            block.timestamp,
            msg.sender,
            tokens,
            squadzId,
            portalzAddress
        );
    }

    function unstake(uint256 squadzId) external {
        require(squadzId < numberOfSquadz(msg.sender), "1009");

        Tokens.ERC165Token[] memory tokens = _stakers[msg.sender][squadzId]
            .tokens;
        uint256 sentStartTime = _stakers[msg.sender][squadzId].sentStartTime;

        address portalzAddress = _stakers[msg.sender][squadzId].portalzAddress;
        require(canUnstakeFromPortalz[portalzAddress], "1003");

        require(
            tokens.length > 0 &&
                sentStartTime > 0 &&
                portalzAddress != address(0),
            "1010"
        );

        // Normal reward
        uint256 rewardAmount = calculateRewards(squadzId);
        Portalz portalz = Portalz(portalzAddress);
        if (rewardAmount > 0) {
            IERC20 rewardTokenContract = IERC20(portalz.rewardTokenAddress());
            if (
                rewardTokenContract.allowance(
                    portalz.rewardSender(),
                    address(this)
                ) >=
                rewardAmount &&
                rewardTokenContract.balanceOf(portalz.rewardSender()) >=
                rewardAmount
            ) {
                rewardTokenContract.transferFrom(
                    portalz.rewardSender(),
                    msg.sender,
                    rewardAmount
                );
            } else {
                emit NoMoreTokenReward(
                    block.timestamp,
                    msg.sender,
                    squadzId,
                    portalzAddress,
                    rewardAmount
                );
            }
        }

        // Bonus reward
        Tokens.ERC165Token memory bonusToken = calculateBonusRewardz(squadzId);
        if (bonusToken.contractAddress != address(0)) {
            IERC1155 bonusTokenContract = IERC1155(bonusToken.contractAddress);
            if (
                bonusTokenContract.isApprovedForAll(
                    portalz.bonusRewardSender(),
                    address(this)
                ) &&
                bonusTokenContract.balanceOf(
                    portalz.bonusRewardSender(),
                    bonusToken.tokenId
                ) >=
                1
            ) {
                bonusTokenContract.safeTransferFrom(
                    portalz.bonusRewardSender(),
                    msg.sender,
                    bonusToken.tokenId,
                    1,
                    ""
                );
            } else {
                emit NoMoreBonusTokenReward(
                    block.timestamp,
                    msg.sender,
                    squadzId,
                    portalzAddress,
                    bonusToken
                );
            }
        }

        for (uint256 i = 0; i < tokens.length; i = unsafeInc(i)) {
            IERC721 token = IERC721(tokens[i].contractAddress);
            token.transferFrom(address(this), msg.sender, tokens[i].tokenId);
            _lockerzTicketz.safeBurn(
                LockerzTicketz.Ticketz(
                    tokens[i].contractAddress,
                    tokens[i].tokenId
                )
            );
        }
        delete _stakers[msg.sender][squadzId].tokens;
        delete _stakers[msg.sender][squadzId].portalzAddress;
        delete _stakers[msg.sender][squadzId].sentStartTime;

        emit UnstakedTokens(
            block.timestamp,
            msg.sender,
            tokens,
            squadzId,
            portalzAddress,
            rewardAmount,
            portalz.rewardTokenAddress(),
            bonusToken
        );
    }

    /// @notice Calculate reward for a given staker by calculating the time passed
    /// @param squadzId the index of the squadz
    /// @return uint256 the calculated reward for a given staked squadz of tokens
    function calculateRewards(uint256 squadzId) public view returns (uint256) {
        require(squadzId < numberOfSquadz(msg.sender), "1009");

        Tokens.ERC165Token[] memory tokens = _stakers[msg.sender][squadzId]
            .tokens;
        uint256 sentStartTime = _stakers[msg.sender][squadzId].sentStartTime;
        address portalzAddress = _stakers[msg.sender][squadzId].portalzAddress;

        require(
            tokens.length > 0 &&
                sentStartTime > 0 &&
                portalzAddress != address(0),
            "1010"
        );

        uint256 squadzPeriod = (block.timestamp - sentStartTime) / 1 days;

        uint256 tokensBaseDailyReward;
        for (uint256 i = 0; i < tokens.length; i = unsafeInc(i)) {
            tokensBaseDailyReward += _metadataStorage.rarityReward(
                tokens[i].contractAddress,
                tokens[i].tokenId
            );
        }

        Portalz portalz = Portalz(portalzAddress);

        uint256 currentDayRewards = (((block.timestamp - sentStartTime) %
            1 days) *
            portalz.currentMultiplier(squadzPeriod) *
            tokensBaseDailyReward) / 1 days;

        return
            portalz.calculateRewardsForDays(
                tokensBaseDailyReward,
                squadzPeriod
            ) + currentDayRewards;
    }

    /**
     @notice Returns a bonus token if conditions and chances are met.
     @param squadzId the id of the squadz staked.
     */
    function calculateBonusRewardz(
        uint256 squadzId
    ) internal view whenNotPaused returns (Tokens.ERC165Token memory token) {
        require(squadzId < numberOfSquadz(msg.sender), "1009");

        uint256 sentStartTime = _stakers[msg.sender][squadzId].sentStartTime;
        address portalzAddress = _stakers[msg.sender][squadzId].portalzAddress;

        require(sentStartTime > 0 && portalzAddress != address(0), "1011");

        Portalz portalz = Portalz(portalzAddress);

        uint256 stakedPeriod = (block.timestamp - sentStartTime) / 1 days;

        if (portalz.bonusRewardzLength() > 0) {
            uint256 randomCounter = 1;
            for (
                uint256 i = 0;
                i < portalz.bonusRewardzLength();
                i = unsafeInc(i)
            ) {
                uint256 random = uint256(
                    keccak256(
                        abi.encodePacked(
                            block.difficulty,
                            block.timestamp,
                            msg.sender,
                            randomCounter,
                            blockhash(block.number)
                        )
                    )
                ) % (BASIS_POINT);
                randomCounter += 1;

                uint256 dropChanceFromStaking = chanceToDrop(
                    squadzId,
                    stakedPeriod,
                    i
                );

                if (random <= dropChanceFromStaking) {
                    (token, , ) = portalz.bonusRewardz(uint8(i));
                    return token;
                }
            }
        }
    }

    /**
     @notice Returns the drop rate of a given reward from a portalz.
     @dev The bigger the squadz is and the longer the squadz is staked,
     the bigger the drop rate will be.
     @param squadzId id of the squadz sent to the portalz.
     @param stakedPeriod number of days the squadz has been sent to the portalz.
     @param bonusIndex index of the potential bonus from the portalz.
    */
    function chanceToDrop(
        uint256 squadzId,
        uint256 stakedPeriod,
        uint256 bonusIndex
    ) public view returns (uint256) {
        Tokens.ERC165Token[] memory tokens = _stakers[msg.sender][squadzId]
            .tokens;
        address portalzAddress = _stakers[msg.sender][squadzId].portalzAddress;

        require(tokens.length > 0 && portalzAddress != address(0), "1012");

        Portalz portalz = Portalz(portalzAddress);

        require(bonusIndex < portalz.bonusRewardzLength(), "1013");

        (, uint16 dropChance, uint16 maxDropChance) = portalz.bonusRewardz(
            uint8(bonusIndex)
        );
        uint256 dropChanceFromStaking = dropChance *
            tokens.length *
            stakedPeriod;
        if (dropChanceFromStaking > maxDropChance) {
            dropChanceFromStaking = maxDropChance;
        }
        return dropChanceFromStaking;
    }

    /* ********************************** */
    /*              Squadz                */
    /* ********************************** */

    function buyNextSquadz() external whenNotPaused {
        uint256 nextSquadzId = numberOfSquadz(msg.sender);
        uint256 price = nextSquadzPrice();
        require(_rFleshToken.balanceOf(msg.sender) >= price, "1015");

        _rFleshToken.burnFrom(msg.sender, price);

        _stakers[msg.sender][nextSquadzId].slotsAvailable = 1;

        emit UnlockedNewSquadz(block.timestamp, msg.sender, nextSquadzId);
    }

    /**
     @notice Returns the price of the next squadz to unlock.
     Triggers an exception if there is no more squadz to unlock.
     @return uint256 next squadz's price
    */
    function nextSquadzPrice() public view returns (uint256) {
        uint256 nextSquadzId = numberOfSquadz(msg.sender);
        require(nextSquadzId < currentMaxSquadz, "1016");
        return _squadzPrices[nextSquadzId][0] * 1 ether; // converts eth to wei
    }

    function numberOfSquadz(address staker) internal view returns (uint256) {
        for (uint256 i = 0; i < MAX_SQUADZ; i = unsafeInc(i)) {
            if (_stakers[staker][i].slotsAvailable == 0) {
                return i;
            }
        }
        return MAX_SQUADZ;
    }

    /* ********************************** */
    /*               Slots                */
    /* ********************************** */

    function buyNextSlot(uint256 squadzId) external whenNotPaused {
        // throw an exception if no more available slots
        uint256 price = nextSlotPrice(squadzId);
        require(_rFleshToken.balanceOf(msg.sender) >= price, "1015");

        _rFleshToken.burnFrom(msg.sender, price);

        _stakers[msg.sender][squadzId].slotsAvailable++;

        emit UnlockedNewSlot(
            block.timestamp,
            msg.sender,
            squadzId,
            _stakers[msg.sender][squadzId].slotsAvailable
        );
    }

    /// @notice Internal method to the price of the next slot to buy for a given squad
    /// @param squadzId id of the squad
    /// @return uint256 next slot's price
    function nextSlotPrice(uint256 squadzId) public view returns (uint256) {
        uint256 nextSquadzId = numberOfSquadz(msg.sender);
        require(nextSquadzId > 0, "1017");
        require(squadzId < nextSquadzId, "1018");
        require(
            _stakers[msg.sender][squadzId].slotsAvailable <
                maxNumberOfSlots(squadzId),
            "1019"
        );
        return
            _squadzPrices[squadzId][
                _stakers[msg.sender][squadzId].slotsAvailable
            ] * 1 ether; // converts eth to wei
    }

    /// @notice Returns the maximum number of slots available to unlock for a given Squadz.
    /// @param squadzId Id of the Squadz.
    /// @return uint256 The number of slots.
    function maxNumberOfSlots(uint256 squadzId) public view returns (uint256) {
        for (uint256 i = 0; i < MAX_SLOTS; i = unsafeInc(i)) {
            if (_squadzPrices[squadzId][i] == 0 && (squadzId > 0 || i > 0)) {
                return i;
            }
        }
        return MAX_SLOTS;
    }

    /* ********************************** */
    /*             Getters                */
    /* ********************************** */

    function stakerInfo() public view returns (Squadz[] memory squadz) {
        squadz = new Squadz[](numberOfSquadz(msg.sender));
        for (uint256 i = 0; i < numberOfSquadz(msg.sender); i++) {
            squadz[i] = _stakers[msg.sender][i];
        }
        return squadz;
    }

    function otherStakerInfo(
        address otherStaker
    ) public view onlyOwner returns (Squadz[] memory squadz) {
        squadz = new Squadz[](numberOfSquadz(otherStaker));
        for (uint256 i = 0; i < numberOfSquadz(otherStaker); i++) {
            squadz[i] = _stakers[otherStaker][i];
        }
        return squadz;
    }

    /* ********************************** */
    /*              Setters               */
    /* ********************************** */

    function setSquadzPrices(
        uint256[][] calldata squadzPrices
    ) external onlyOwner {
        for (uint256 i = 0; i < squadzPrices.length; i = unsafeInc(i)) {
            for (uint256 j = 0; j < squadzPrices[i].length; j = unsafeInc(j)) {
                _squadzPrices[i][j] = squadzPrices[i][j];
            }
        }
    }

    function setCurrentMaxSquadz(uint8 _currentMaxSquadz) external onlyOwner {
        currentMaxSquadz = _currentMaxSquadz;
    }

    function setFleshToken(address fleshToken) external onlyOwner {
        _fleshToken = IFleshToken(fleshToken);
    }

    function setRottenFleshToken(address rFleshToken) external onlyOwner {
        _rFleshToken = IrFleshToken(rFleshToken);
    }

    function setMetadaStorage(address metadataStorage) external onlyOwner {
        _metadataStorage = MetadataStorage(metadataStorage);
    }

    function setLockerzTicketz(address lockerzTicketz) external onlyOwner {
        _lockerzTicketz = LockerzTicketz(lockerzTicketz);
    }

    /* ********************************** */
    /*               Helper               */
    /* ********************************** */

    function unsafeInc(uint256 x) private pure returns (uint256) {
        unchecked {
            return x + 1;
        }
    }

    /* ********************************** */
    /*               Pauser               */
    /* ********************************** */

    function pauseStakingInPortalz(address portalzAddress) external onlyOwner {
        canStakeInPortalz[portalzAddress] = false;
    }

    function pauseUnstakingFromPortalz(
        address portalzAddress
    ) external onlyOwner {
        canUnstakeFromPortalz[portalzAddress] = false;
    }

    function unpauseStakingInPortalz(
        address portalzAddress
    ) external onlyOwner {
        canStakeInPortalz[portalzAddress] = true;
    }

    function unpauseUnstakingFromPortalz(
        address portalzAddress
    ) external onlyOwner {
        canUnstakeFromPortalz[portalzAddress] = true;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * Declares structs for ERC165 tokens such as ERC721 and ERC1155.
 * Specifies a token's contract address and its token id.
 */
library Tokens {
    /// @notice Describes an ERC165 (ERC721 + ERC1155) token by its collection address and id
    struct ERC165Token {
        address contractAddress;
        uint256 tokenId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import "./IPortalz.sol";
import "./Tokens.sol";

/**
 @dev Portalz are ERC1155 receivers as they can own bonus rewards and
 be themselves bonusRewardSender.
 */
contract Portalz is IPortalz, Ownable, Pausable, ERC1155Holder {
    /**
     @dev Max number of bonus rewardz used to iterate in the mapping.
    */
    uint8 public constant MAX_BONUS_REWARDZ = 100;

    /* ********************************** */
    /*         Allowed NFTs Amount        */
    /* ********************************** */

    /**
     @notice Allowed type of NFTs to be staked.
     */
    mapping(address => uint256) public allowedNFTAmountPerSquadz;

    /* ********************************** */
    /*                Info                */
    /* ********************************** */

    /**
     @notice Name of the Portalz.
     */
    string public name;

    /**
     @notice Above this number of days, rewards don't increase anymore.
     User will have to unstake then stake again to continue to earn rewards.
     @dev this value shouldn't exceed 366.
     */
    uint256 public maxPeriod = 166;

    /* ********************************** */
    /*             Multiplier             */
    /* ********************************** */

    /**
     @notice Multiplier of the basic reward of the Portalz.
     @dev Value expressed in **18.
     For example: a basic reward of 10 with a `multiplier`
     of 10**16 will result in a reward of 10*10**16/10**18 ether
     */
    uint256 public multiplier;

    /**
     @notice Max number of days during which the multiplier is increased.
    */
    uint256 public maxMultiplierPeriod = 100;

    /* ********************************** */
    /*            Token Reward            */
    /* ********************************** */

    /**
     @notice Basic reward token of the Portalz.
     
     Note that it has to be an ERC20 contract.
     */
    address public rewardTokenAddress;

    /**
     @notice Wallet address supposed to send the reward.
     @dev This `rewardSender` address must own enough ERC20 tokens and
     provide enough allowance of `rewardTokenAddress` token to
     the Squadz contract.
     */
    address public rewardSender;

    /* ********************************** */
    /*        Bonus ERC1155 Rewardz       */
    /* ********************************** */

    struct BonusERC1155Rewardz {
        // tokens to drop
        Tokens.ERC165Token token;
        // 0 if never dropped
        uint16 dropChance;
        // max drop chance whatever staking period and squadz size
        uint16 maxDropChance;
    }

    /**
     @notice Optional bonus rewardz that could be granted.

     @dev child Portalz contract has to define the address of the
     ERC1155 token and its chance to drop.
     
     Note When deploying a Portalz, we need to send the bonus ERC1155 tokens
     to the Portalz.
     */
    mapping(uint8 => BonusERC1155Rewardz) public bonusRewardz;

    /**
     @notice Wallet address supposed to send the bonus reward.
     @dev This `bonusRewardSender` address must own enough ERC1155 tokens
     and approve the Squadz contract to spend the tokens.
     @dev Portalz contracts can also own the bonus tokens, therefore `bonusRewardSender`
     will be the same value as the Portalz' contract address.
     */
    address public bonusRewardSender;

    /* ********************************** */
    /*            Constructor             */
    /* ********************************** */

    constructor(
        string memory _name,
        uint256 _multiplier,
        address _rewardTokenAddress,
        address _rewardSender,
        BonusERC1155Rewardz[] memory _bonusRewardz,
        address _bonusRewardSender
    ) {
        name = _name;
        multiplier = _multiplier;
        rewardTokenAddress = _rewardTokenAddress;
        rewardSender = _rewardSender == address(0)
            ? address(this)
            : _rewardSender;
        for (uint8 i = 0; i < _bonusRewardz.length; i++) {
            bonusRewardz[i] = _bonusRewardz[i];
        }
        bonusRewardSender = _bonusRewardSender == address(0)
            ? address(this)
            : _bonusRewardSender;
    }

    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "1001");
        payable(msg.sender).transfer(address(this).balance);
    }

    function approveRewardToken(address stakingContract, uint256 amount)
        external
        onlyOwner
        returns (bool)
    {
        IERC20 rewardTokenContract = IERC20(rewardTokenAddress);
        return rewardTokenContract.approve(stakingContract, amount);
    }

    function approveBonusRewardToken(
        address stakingContract,
        Tokens.ERC165Token calldata token,
        bool approved
    ) external onlyOwner {
        IERC1155 bonusRewardTokenContract = IERC1155(token.contractAddress);
        bonusRewardTokenContract.setApprovalForAll(stakingContract, approved);
    }

    /* ********************************** */
    /*               Getter               */
    /* ********************************** */

    function areTokensAllowed(Tokens.ERC165Token[] calldata tokens)
        external
        view
        returns (bool)
    {
        require(tokens.length > 0, "1014");

        address[] memory tokensCountAddress = new address[](tokens.length);
        uint256[] memory tokensCountNumber = new uint256[](tokens.length);
        uint256 numberOfDifferentTokensTypes;

        for (uint256 i = 0; i < tokens.length; i++) {
            bool tokenFound = false;
            uint256 j = 0;
            while (j < numberOfDifferentTokensTypes) {
                if (tokensCountAddress[j] == tokens[i].contractAddress) {
                    tokensCountNumber[j]++;

                    if (
                        tokensCountNumber[j] >
                        allowedNFTAmountPerSquadz[tokens[i].contractAddress]
                    ) {
                        return false;
                    }

                    tokenFound = true;
                    break;
                }
                j++;
            }

            if (allowedNFTAmountPerSquadz[tokens[i].contractAddress] > 0) {
                if (!tokenFound) {
                    tokensCountAddress[j] = tokens[i].contractAddress;
                    tokensCountNumber[j] = 1;
                    numberOfDifferentTokensTypes++;
                }
            } else {
                return false;
            }
        }
        return true;
    }

    /**
     @notice Calculates the reward eligible to be earned during a time period.
     @param tokensBaseDailyReward is the base amount of token for day 0 (in ether).
     @param period is the number of days the tokens have been staked during.
     This value is capped to maxPeriod.
     @return reward the total reward expressed in ^18.

     @dev 10**14 is just 1 ether / BASIS_POINT (which is 10000) because multiplier
     is expressed in BASIS_POINT.
     */
    function calculateRewardsForDays(
        uint256 tokensBaseDailyReward,
        uint256 period
    ) external view returns (uint256 reward) {
        if (period == 0) {
            return 0;
        }

        uint256 _maxPeriod = period > maxPeriod ? maxPeriod : period;

        reward = tokensBaseDailyReward * 1 ether;
        for (uint256 day = 1; day < _maxPeriod; day++) {
            reward += tokensBaseDailyReward * currentMultiplier(day);
        }

        return reward;
    }

    /**
     @notice Calculates the multiplier for a given number of days with
     tokens staked in a row.
     @param period is the number of days the tokens have been staked during.
     This value is capped to maxMultiplierPeriod.
     @return mult the current multiplier expressed in ^18
     */
    function currentMultiplier(uint256 period)
        public
        view
        returns (uint256 mult)
    {
        uint256 maxMultPeriod = period > maxMultiplierPeriod
            ? maxMultiplierPeriod
            : period;

        mult = 1 ether + (multiplier * maxMultPeriod);
        return mult;
    }

    function bonusRewardzLength() external view returns (uint256) {
        for (uint8 i = 0; i < MAX_BONUS_REWARDZ; i = i++) {
            if (
                bonusRewardz[i].dropChance == 0 &&
                bonusRewardz[i].maxDropChance == 0
            ) {
                return i;
            }
        }
        return MAX_BONUS_REWARDZ;
    }

    /* ********************************** */
    /*              Setters               */
    /* ********************************** */

    function addAllowedNFT(address contractAddress, uint256 maxAmountPerSquadz)
        external
        onlyOwner
    {
        require(allowedNFTAmountPerSquadz[contractAddress] == 0, "1020");
        allowedNFTAmountPerSquadz[contractAddress] = maxAmountPerSquadz;
    }

    function removeAllowedNFT(address contractAddress) external onlyOwner {
        require(allowedNFTAmountPerSquadz[contractAddress] > 0, "1021");
        allowedNFTAmountPerSquadz[contractAddress] = 0;
    }

    function setName(string calldata _name) external onlyOwner {
        name = _name;
    }

    function setMaxPeriod(uint256 _maxPeriod) external onlyOwner {
        maxPeriod = _maxPeriod;
    }

    function setMultiplier(uint256 _multiplier) external onlyOwner {
        multiplier = _multiplier;
    }

    function setMaxMultiplierPeriod(uint256 _maxMultiplierPeriod)
        external
        onlyOwner
    {
        maxMultiplierPeriod = _maxMultiplierPeriod;
    }

    function setRewardTokenAddress(address _rewardTokenAddress)
        external
        onlyOwner
    {
        rewardTokenAddress = _rewardTokenAddress;
    }

    function setRewardSender(address _rewardSender) external onlyOwner {
        rewardSender = _rewardSender;
    }

    function setBonusRewardSender(address _bonusRewardSender)
        external
        onlyOwner
    {
        bonusRewardSender = _bonusRewardSender;
    }

    function setBonusRewardz(BonusERC1155Rewardz[] memory _bonusRewardz)
        external
        onlyOwner
    {
        for (uint8 i = 0; i < _bonusRewardz.length; i++) {
            bonusRewardz[i] = _bonusRewardz[i];
        }
    }

    /* ********************************** */
    /*               Pauser               */
    /* ********************************** */

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

// Metadata storage
contract MetadataStorage is Ownable, Multicall {
    /// There is a maximum of 10 different attributes per NFT.
    uint8 public constant MAX_ATTRIBUTES = 10;

    struct Metadata {
        /// Reward given for a token address and id (usually linked to its rarity).
        /// ex: _raritiesRewards[0x123...][123] = 10 ** 18 where 10 ** 18 is the amount
        /// of ERC20 this token would earn for 1 day
        uint256 rarityReward;
        /// Array of attributes composing the NFT.
        /// Very useful when we need to check on-chain for specific conditions
        /// about specific attributes.
        /// Value of 0 means the NFT doesn't have the attribute (as it starts at 1).
        uint8[MAX_ATTRIBUTES] attributes;
    }

    bool private canUpdateMetadata;

    mapping(address => mapping(uint256 => Metadata)) private _metadata;

    constructor() {}

    /* ********************************** */
    /*               Getter               */
    /* ********************************** */

    function metadata(address contractAddress, uint256 tokenId)
        external
        view
        returns (Metadata memory)
    {
        return _metadata[contractAddress][tokenId];
    }

    function rarityReward(address contractAddress, uint256 tokenId)
        external
        view
        returns (uint256)
    {
        return _metadata[contractAddress][tokenId].rarityReward;
    }

    function attributes(address contractAddress, uint256 tokenId)
        external
        view
        returns (uint8[MAX_ATTRIBUTES] memory)
    {
        return _metadata[contractAddress][tokenId].attributes;
    }

    /**
     @notice Check if a token from a collection possess the given variant of the given attribute.
     @param attribute type of the attribute (eg: 1 -> Background).
     @param variant value of the attribute (eg: 1 -> Red).
     @param contractAddress address of the token's collection's contract.
     @param tokenId id of the token from the collection.
    */
    function hasAttribute(
        uint8 attribute,
        uint8 variant,
        address contractAddress,
        uint256 tokenId
    ) external view returns (bool) {
        return
            _metadata[contractAddress][tokenId].attributes[attribute] ==
            variant;
    }

    /* ********************************** */
    /*              Setters               */
    /* ********************************** */

    function updateMetadata(
        address tokenContract,
        uint256[] memory ids,
        Metadata[] memory data
    ) external onlyOwner {
        require(canUpdateMetadata, "Cannot update metadata");
        require(ids.length == data.length, "Arrays aren't the same length");
        unchecked {
            for (uint256 i = 0; i < ids.length; i++) {
                _metadata[tokenContract][ids[i]] = data[i];
            }
        }
    }

    function lockMetadataUpdate() external onlyOwner {
        canUpdateMetadata = false;
    }

    function unlockMetadataUpdate() external onlyOwner {
        canUpdateMetadata = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./Tokens.sol";

// Portalz interface
interface IPortalz {
    function areTokensAllowed(Tokens.ERC165Token[] calldata tokens)
        external
        returns (bool);

    function calculateRewardsForDays(
        uint256 tokensBaseDailyReward,
        uint256 period
    ) external view returns (uint256 reward);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringUtils {
    /**
     * @dev Pads on the left of a `string` as many `value` character as `amount` quantity.
     */
    function padStart(
        string memory baseString,
        uint256 amount,
        string memory value
    ) internal pure returns (string memory) {
        for (uint256 i = bytes(baseString).length; i < amount; i++) {
            baseString = string(abi.encodePacked(value, baseString));
        }
        return baseString;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./utils/StringUtils.sol";

/// @custom:security-contact [email protected]
contract LockerzTicketz is ERC721, ERC721Enumerable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    mapping(address => bool) public whitelistedAddresses;

    struct Ticketz {
        address collectionAddress;
        uint256 tokenId;
    }

    mapping(uint256 => Ticketz) private _ticketz;
    mapping(address => mapping(uint256 => uint256)) private _tokenIds;

    uint256 private _indexer;

    constructor() ERC721("Lockerz Ticketz", "TICKETZ") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function ticketzFromTokenId(uint256 tokenId)
        public
        view
        returns (Ticketz memory ticketz)
    {
        return _ticketz[tokenId];
    }

    function tokenURI(Ticketz memory ticketz)
        public
        view
        virtual
        returns (string memory)
    {
        _requireMinted(_tokenIds[ticketz.collectionAddress][ticketz.tokenId]);
        ERC721 collection = ERC721(ticketz.collectionAddress);
        return collection.tokenURI(ticketz.tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "LockerzTicketz: URI query for nonexistent token"
        );
        return tokenURI(ticketzFromTokenId(tokenId));
    }

    /* ********************************** */
    /*                Mint                */
    /* ********************************** */

    function safeMint(address to, Ticketz memory ticketz)
        public
        onlyRole(MINTER_ROLE)
    {
        require(
            _tokenIds[ticketz.collectionAddress][ticketz.tokenId] == 0,
            "LockerzTicketz: ticketz already exists"
        );
        _ticketz[_indexer] = ticketz;
        _tokenIds[ticketz.collectionAddress][ticketz.tokenId] = _indexer;
        _mint(to, _indexer);
        _indexer += 1;
    }

    /* ********************************** */
    /*                Burn                */
    /* ********************************** */

    function safeBurn(Ticketz memory ticketz) public onlyRole(MINTER_ROLE) {
        uint256 tokenId = _tokenIds[ticketz.collectionAddress][ticketz.tokenId];
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "LockerzTicketz: caller is not token owner nor approved"
        );

        delete _ticketz[tokenId];
        delete _tokenIds[ticketz.collectionAddress][ticketz.tokenId];

        _burn(tokenId);
    }

    function burn(Ticketz memory ticketz) public onlyRole(MINTER_ROLE) {
        uint256 tokenId = _tokenIds[ticketz.collectionAddress][ticketz.tokenId];

        delete _ticketz[tokenId];
        delete _tokenIds[ticketz.collectionAddress][ticketz.tokenId];

        _burn(tokenId);
    }

    /* ********************************** */
    /*             Transfers              */
    /* ********************************** */

    // Non-transferable token
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        require(
            from == address(0) ||
                whitelistedAddresses[from] ||
                whitelistedAddresses[to],
            "LockerzTicketz: non transferable"
        );

        super._transfer(from, to, tokenId);
    }

    /* ********************************** */
    /*               Setter               */
    /* ********************************** */

    function addWhitelistedAddress(address wlAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        whitelistedAddresses[wlAddress] = true;
    }

    function removeWhitelistedAddress(address wlAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        whitelistedAddresses[wlAddress] = false;
    }

    /* ********************************** */
    /*             Mandatory              */
    /* ********************************** */

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

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
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
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
        _requireMinted(tokenId);

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
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

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
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
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
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
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
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
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
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}
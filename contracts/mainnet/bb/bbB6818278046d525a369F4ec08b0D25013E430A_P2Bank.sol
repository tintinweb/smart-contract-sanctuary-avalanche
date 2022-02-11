// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "../Ownable.sol";
import "../IERC721Receiver.sol";
import "../Pauseable.sol";
import "../ILOOT.sol";
import "./IThiefUpgrading.sol";
import "../IBank.sol";
import "../IPoliceAndThief.sol";

contract P2Bank is Ownable, IERC721Receiver, Pauseable {

    // maximum alpha score for a Police
    uint8 public constant MAX_ALPHA = 8;

    event TokenStaked(address owner, uint256 tokenId, uint256 value);
    event ThiefClaimed(uint256 tokenId, uint256 earned, bool unstaked);
    event PoliceClaimed(uint256 tokenId, uint256 earned, bool unstaked);

    // reference to the PoliceAndThief NFT contract
    IPoliceAndThief game;
    // reference to the $LOOT contract for minting $LOOT earnings
    ILOOT loot;

    mapping(uint256 => address) public realOwnerOf;

    // maps tokenId to stake
    mapping(uint256 => IBank.Stake) public bank;
    // maps alpha to all Police stakes with that alpha
    mapping(uint256 => IBank.Stake[]) public pack;
    // tracks location of each Police in Pack
    mapping(uint256 => uint256) public packIndices;
    // total alpha scores staked
    uint256 public totalAlphaStaked = 0;
    // any rewards distributed when no wolves are staked
    uint256 public unaccountedRewards = 0;
    // amount of $LOOT due for each alpha point staked
    uint256 public lootPerAlpha = 0;

    // thief earn 10000 $LOOT per day
    uint256 public DAILY_LOOT_RATE = 1 ether;
    // thief must have 2 days worth of $LOOT to unstake or else it's too cold
    uint256 public MINIMUM_TO_EXIT = 2 days;
    // wolves take a 20% tax on all $LOOT claimed
    uint256 public constant LOOT_CLAIM_TAX_PERCENTAGE = 20;
    // there will only ever be (roughly) 2.4 billion $LOOT earned through staking
    uint256 public constant MAXIMUM_GLOBAL_LOOT = 2400000000 ether;

    // amount of $LOOT earned so far
    uint256 public totalLootEarned;
    // number of Thief staked in the Bank
    uint256 public totalThiefStaked;
    // the last time $LOOT was claimed
    uint256 public lastClaimTimestamp;

    uint256 public gameStartTimestamp;

    // emergency rescue to allow unstaking without any checks but without $LOOT
    bool public rescueEnabled = false;

    bool private _reentrant = false;
    bool public canClaim = false;

    modifier nonReentrant() {
        require(!_reentrant, "No reentrancy");
        _reentrant = true;
        _;
        _reentrant = false;
    }

    IThiefUpgrading thiefUpgrading;
    address public swapper;

    uint256 oldLastClaimTimestamp;

    /**
     * @param _game reference to the PoliceAndThief NFT contract
   * @param _loot reference to the $LOOT token
   */
    constructor(IPoliceAndThief _game, ILOOT _loot) {
        game = _game;
        loot = _loot;
    }

    function setOldBankStats(uint256 _lastClaimTimestamp, uint256 _totalLootEarned) public onlyOwner {
        lastClaimTimestamp = _lastClaimTimestamp;
        totalLootEarned = _totalLootEarned;
    }

    function setOldTokenInfo(uint256 _tokenId, bool _isThief, address _tokenOwner, uint256 _value) external {
        require(msg.sender == swapper || msg.sender == owner(), "only swpr || owner");

        if (_isThief) {
            _addThiefToBankWithTime(_tokenOwner, _tokenId, _value);
        }
        else {
            _addPoliceToPack(_tokenOwner, _tokenId);
        }
    }

    /***STAKING */

    /**
     * adds Thief and Polices to the Bank and Pack
     * @param account the address of the staker
   * @param tokenIds the IDs of the Thief and Polices to stake
   */
    function addManyToBankAndPack(address account, uint16[] calldata tokenIds) public nonReentrant {
        require((account == _msgSender() && account == tx.origin) || _msgSender() == address(swapper), "DONT GIVE YOUR TOKENS AWAY");
        require(!paused() || msg.sender == owner(), "Paused");

        for (uint i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i] == 0) {
                continue;
            }

            if (_msgSender() != address(swapper)) {// dont do this step if its a mint + stake
                require(game.ownerOf(tokenIds[i]) == _msgSender(), "AINT YO TOKEN");
                game.transferFrom(_msgSender(), address(this), tokenIds[i]);
            }

            if (isThief(tokenIds[i]))
                _addThiefToBank(account, tokenIds[i]);
            else
                _addPoliceToPack(account, tokenIds[i]);

            realOwnerOf[tokenIds[i]] = _msgSender();
        }
    }

    /**
     * adds a single Thief to the Bank
     * @param account the address of the staker
   * @param tokenId the ID of the Thief to add to the Bank
   */
    function _addThiefToBank(address account, uint256 tokenId) internal _updateEarnings {
        bank[tokenId] = IBank.Stake({
        owner : account,
        tokenId : uint16(tokenId),
        value : uint80(block.timestamp) > uint80(gameStartTimestamp) ? uint80(block.timestamp) : uint80(gameStartTimestamp)
        });
        totalThiefStaked += 1;
        emit TokenStaked(account, tokenId, block.timestamp);
    }

    function _addThiefToBankWithTime(address account, uint256 tokenId, uint256 time) internal {
        totalLootEarned += (time - lastClaimTimestamp) * totalThiefStaked * DAILY_LOOT_RATE / 1 days;

        bank[tokenId] = IBank.Stake({
        owner : account,
        tokenId : uint16(tokenId),
        value : uint80(time)
        });
        totalThiefStaked += 1;
        emit TokenStaked(account, tokenId, time);
    }

    /**
     * adds a single Police to the Pack
     * @param account the address of the staker
   * @param tokenId the ID of the Police to add to the Pack
   */
    function _addPoliceToPack(address account, uint256 tokenId) internal {
        uint256 alpha = _alphaForPolice(tokenId);
        totalAlphaStaked += alpha;
        // Portion of earnings ranges from 8 to 5
        packIndices[tokenId] = pack[alpha].length;

        // Store the location of the police in the Pack
        pack[alpha].push(IBank.Stake({
        owner : account,
        tokenId : uint16(tokenId),
        value : uint80(lootPerAlpha)
        }));
        // Add the police to the Pack
        emit TokenStaked(account, tokenId, lootPerAlpha);
    }

    /***CLAIMING / UNSTAKING */

    /**
     * realize $LOOT earnings and optionally unstake tokens from the Bank / Pack
     * to unstake a Thief it will require it has 2 days worth of $LOOT unclaimed
     * @param tokenIds the IDs of the tokens to claim earnings from
   * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
   */
    function claimManyFromBankAndPack(uint16[] calldata tokenIds, bool unstake) external nonReentrant _updateEarnings {
        require(msg.sender == tx.origin, "Only EOA");
        require(canClaim || msg.sender == owner(), "Claim deactive");

        uint256 owed = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            if (isThief(tokenIds[i]))
                owed += _claimThiefFromBank(tokenIds[i], unstake);
            else
                owed += _claimPoliceFromPack(tokenIds[i], unstake);

            if (unstake) {
                realOwnerOf[tokenIds[i]] = address(0);
            }
        }
        if (owed == 0) return;
        loot.mint(_msgSender(), owed);
    }

    function claimForUser(uint16[] calldata tokenIds, address _tokenOwner) external nonReentrant _updateEarnings {
        require(msg.sender == address(thiefUpgrading), "Only EOA");
        require(canClaim, "Claim deactive");

        uint256 owed = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            if (realOwnerOf[tokenIds[i]] == address(0)) continue;

            if (isThief(tokenIds[i]))
                owed += _claimThiefFromBank(tokenIds[i], false);
            else
                continue;
        }
        if (owed == 0) return;
        loot.mint(_tokenOwner, owed);
    }

    /**
     * realize $LOOT earnings for a single Thief and optionally unstake it
     * if not unstaking, pay a 20% tax to the staked Polices
     * if unstaking, there is a 50% chance all $LOOT is stolen
     * @param tokenId the ID of the Thief to claim earnings from
   * @param unstake whether or not to unstake the Thief
   * @return owed - the amount of $LOOT earned
   */
    function _claimThiefFromBank(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
        IBank.Stake memory stake = bank[tokenId];
        require(stake.owner == _msgSender() || _msgSender() == address(thiefUpgrading), "SWIPER, NO SWIPING");
        if (totalLootEarned < MAXIMUM_GLOBAL_LOOT) {
            owed = (block.timestamp - stake.value) * (DAILY_LOOT_RATE + (0.25 ether * levelOf(tokenId))) / 1 days;
        } else if (stake.value > lastClaimTimestamp) {
            owed = 0;
            // $LOOT production stopped already
        } else {
            owed = (lastClaimTimestamp - stake.value) * DAILY_LOOT_RATE / 1 days;
            // stop earning additional $LOOT if it's all been earned
        }
        require(!(unstake && owed >= MINIMUM_TO_EXIT), "GONNA BE COLD WITHOUT 2 BRIBE");

        if (unstake) {
            game.transferFrom(address(this), stake.owner, tokenId);
            // send back Thief
            delete bank[tokenId];
            totalThiefStaked -= 1;
        } else {
            _payPoliceTax(owed * LOOT_CLAIM_TAX_PERCENTAGE / 100);
            // percentage tax to staked wolves
            owed = owed * (100 - LOOT_CLAIM_TAX_PERCENTAGE) / 100;
            // remainder goes to Thief owner
            bank[tokenId] = IBank.Stake({
            owner : stake.owner,
            tokenId : uint16(tokenId),
            value : uint80(block.timestamp)
            });
            // reset stake
        }
        emit ThiefClaimed(tokenId, owed, unstake);
    }

    /**
     * realize $LOOT earnings for a single Police and optionally unstake it
     * Polices earn $LOOT proportional to their Alpha rank
     * @param tokenId the ID of the Police to claim earnings from
   * @param unstake whether or not to unstake the Police
   * @return owed - the amount of $LOOT earned
   */
    function _claimPoliceFromPack(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
        require(game.ownerOf(tokenId) == address(this), "AINT A PART OF THE PACK");
        uint256 alpha = _alphaForPolice(tokenId);
        IBank.Stake memory stake = pack[alpha][packIndices[tokenId]];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        owed = (alpha) * (lootPerAlpha - stake.value);
        // Calculate portion of tokens based on Alpha
        if (unstake) {
            totalAlphaStaked -= alpha;
            // Remove Alpha from total staked
            game.transferFrom(address(this), stake.owner, tokenId);
            // Send back Police
            IBank.Stake memory lastStake = pack[alpha][pack[alpha].length - 1];
            pack[alpha][packIndices[tokenId]] = lastStake;
            // Shuffle last Police to current position
            packIndices[lastStake.tokenId] = packIndices[tokenId];
            pack[alpha].pop();
            // Remove duplicate
            delete packIndices[tokenId];
            // Delete old mapping
        } else {
            pack[alpha][packIndices[tokenId]] = IBank.Stake({
            owner : _msgSender(),
            tokenId : uint16(tokenId),
            value : uint80(lootPerAlpha)
            });
            // reset stake
        }
        emit PoliceClaimed(tokenId, owed, unstake);
    }

    /**
     * emergency unstake tokens
     * @param tokenIds the IDs of the tokens to claim earnings from
   */
    function rescue(uint256[] calldata tokenIds) external nonReentrant {
        require(rescueEnabled, "RESCUE DISABLED");
        uint256 tokenId;
        IBank.Stake memory stake;
        IBank.Stake memory lastStake;
        uint256 alpha;
        for (uint i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            if (isThief(tokenId)) {
                stake = bank[tokenId];
                require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
                game.transferFrom(address(this), _msgSender(), tokenId);
                // send back Thief
                delete bank[tokenId];
                totalThiefStaked -= 1;
                emit ThiefClaimed(tokenId, 0, true);
            } else {
                alpha = _alphaForPolice(tokenId);
                stake = pack[alpha][packIndices[tokenId]];
                require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
                totalAlphaStaked -= alpha;
                // Remove Alpha from total staked
                game.transferFrom(address(this), _msgSender(), tokenId);
                // Send back Police
                lastStake = pack[alpha][pack[alpha].length - 1];
                pack[alpha][packIndices[tokenId]] = lastStake;
                // Shuffle last Police to current position
                packIndices[lastStake.tokenId] = packIndices[tokenId];
                pack[alpha].pop();
                // Remove duplicate
                delete packIndices[tokenId];
                // Delete old mapping
                emit PoliceClaimed(tokenId, 0, true);
            }
        }
    }

    /***ACCOUNTING */

    /**
     * add $LOOT to claimable pot for the Pack
     * @param amount $LOOT to add to the pot
   */
    function _payPoliceTax(uint256 amount) internal {
        if (totalAlphaStaked == 0) {// if there's no staked wolves
            unaccountedRewards += amount;
            // keep track of $LOOT due to wolves
            return;
        }
        // makes sure to include any unaccounted $LOOT
        lootPerAlpha += (amount + unaccountedRewards) / totalAlphaStaked;
        unaccountedRewards = 0;
    }

    /**
     * tracks $LOOT earnings to ensure it stops once 2.4 billion is eclipsed
     */
    modifier _updateEarnings() {
        if (totalLootEarned < MAXIMUM_GLOBAL_LOOT) {
            totalLootEarned +=
            (block.timestamp - lastClaimTimestamp)
            * totalThiefStaked
            * DAILY_LOOT_RATE / 1 days;
            lastClaimTimestamp = block.timestamp;
        }
        _;
    }

    /***ADMIN */

    function setSettings(uint256 rate, uint256 exit) external onlyOwner {
        MINIMUM_TO_EXIT = exit;
        DAILY_LOOT_RATE = rate;
    }

    /**
     * allows owner to enable "rescue mode"
     * simplifies accounting, prioritizes tokens out in emergency
     */
    function setRescueEnabled(bool _enabled) external onlyOwner {
        rescueEnabled = _enabled;
    }

    /**
     * enables owner to pause / unpause minting
     */
    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    /***READ ONLY */

    /**
     * checks if a token is a Thief
     * @param tokenId the ID of the token to check
   * @return thief - whether or not a token is a Thief
   */
    function isThief(uint256 tokenId) public view returns (bool thief) {
        IPoliceAndThief.ThiefPolice memory t = game.getTokenTraits(tokenId);

        thief = t.isThief;
    }

    /**
     * checks if a token is a Thief
     * @param tokenId the ID of the token to check
   * @return thief - whether or not a token is a Thief
   */
    function levelOf(uint256 tokenId) public view returns (uint256) {
        return thiefUpgrading.levelOf(tokenId);
    }

    /**
     * gets the alpha score for a Police
     * @param tokenId the ID of the Police to get the alpha score for
   * @return the alpha score of the Police (5-8)
   */
    function _alphaForPolice(uint256 tokenId) internal view returns (uint8) {
        IPoliceAndThief.ThiefPolice memory t = game.getTokenTraits(tokenId);
        return MAX_ALPHA - t.alphaIndex;
        // alpha index is 0-3
    }

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        require(from == address(0x0), "Cannot send tokens to Barn directly");
        return IERC721Receiver.onERC721Received.selector;
    }

    function setSwapper(address swp) public onlyOwner {
        swapper = swp;
    }

    function setGame(IPoliceAndThief _nGame) public onlyOwner {
        game = _nGame;
    }

    function setThiefUpgrading(IThiefUpgrading _upgrading) public onlyOwner {
        thiefUpgrading = _upgrading;
    }

    function setClaiming(bool _canClaim) public onlyOwner {
        canClaim = _canClaim;
    }

    function moveOldTokens(address owner, uint16[] calldata tokenIds) public {
        require(msg.sender == swapper, "OnlySwapper");

        addManyToBankAndPack(owner, tokenIds);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be Pauseable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pauseable is Context {
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
     * @dev Initializes the contract in paused state.
     */
    constructor() {
        _paused = true;
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
        require(!paused(), "Pauseable: paused");
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
        require(paused(), "Pauseable: not paused");
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

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IThiefUpgrading {
    function levelOf(uint256) external view returns(uint8);
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;


interface IPoliceAndThief {

    // struct to store each token's traits
    struct ThiefPolice {
        bool isThief;
        uint8 uniform;
        uint8 hair;
        uint8 eyes;
        uint8 facialHair;
        uint8 headgear;
        uint8 neckGear;
        uint8 accessory;
        uint8 alphaIndex;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function getPaidTokens() external view returns (uint256);
    function getTokenTraits(uint256 tokenId) external view returns (ThiefPolice memory);
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface ILOOT  {
    function burn(address from, uint256 amount) external;
    function mint(address to, uint256 amount) external;
    function balanceOf(address account) external view returns(uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IBank {
    struct Stake {
        uint16 tokenId;
        uint80 value;
        address owner;
    }

    function claimForUser(uint256[] calldata tokenIds, address _tokenOwner) external;

    function addManyToBankAndPack(address account, uint16[] calldata tokenIds) external;
    function randomPoliceOwner(uint256 seed) external view returns (address);
    function bank(uint256) external view returns(uint16, uint80, address);
    function totalLootEarned() external view returns(uint256);
    function lastClaimTimestamp() external view returns(uint256);
    function setOldTokenInfo(uint256, bool, address, uint256) external;

    function pack(uint256, uint256) external view returns(Stake memory);
    function packIndices(uint256) external view returns(uint256);
    function realOwnerOf(uint256) external view returns(address);

}

// SPDX-License-Identifier: MIT

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
// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "../Ownable.sol";
import "../Pauseable.sol";
import "../ILOOT.sol";
import "./IThiefUpgrading.sol";
import "../IBank.sol";
import "../IPoliceAndThief.sol";

contract P2Bank2 is Ownable, Pauseable {
    event TokenStaked(address owner, uint256 tokenId, uint256 value);
    event ThiefClaimed(uint256 tokenId, uint256 earned, bool unstaked);
    event PoliceClaimed(uint256 tokenId, uint256 earned, bool unstaked);

    // reference to the PoliceAndThief NFT contract
    IPoliceAndThief game = IPoliceAndThief(0x15e6C37CDb635ACc1fF82A8E6f1D25a757949BEC);
    // reference to the $LOOT contract for minting $LOOT earnings
    ILOOT loot;

    mapping(uint256 => address) public realOwnerOf;

    // maps tokenId to stake
    mapping(uint256 => IBank.Stake) public bank;
    // maps alpha to all Police stakes with that alpha
    mapping(uint256 => IBank.Stake[]) public pack;
    // tracks location of each Police in Pack
    mapping(uint256 => uint256) public packIndices;

    mapping(uint256 => bool) public interacted;

    IBank public p2checks = IBank(0xbbB6818278046d525a369F4ec08b0D25013E430A);
    IBank public oldBank = IBank(0x408634E518D44FFbb6A1fed5faAC6D4AD0B2943b);

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
    uint256 public startTimestamp = 1644188400;

    // number of Thief staked in the Bank
    uint256 public multiplier = 0.25 ether;

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

    /**
   * @param _loot reference to the $LOOT token
   */
    constructor(ILOOT _loot) {
        loot = _loot;
    }

    function _setOldTokenInfo(uint256 _tokenId, bool _isThief, address _tokenOwner, uint256 _value) internal {
        if (_isThief) {
            _addThiefToBankWithTime(_tokenOwner, _tokenId, _value);
        }
        else {
            _addPoliceToPack(_tokenOwner, _tokenId);
        }

        realOwnerOf[_tokenId] = _tokenOwner;
    }

    function setOldTokenInfo(uint256 _tokenId, bool _isThief, address _tokenOwner, uint256 _value) external {
        require(msg.sender == owner(), "owner");

        _setOldTokenInfo(_tokenId, _isThief, _tokenOwner, _value);
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
    function _addThiefToBank(address account, uint256 tokenId) internal {
        bank[tokenId] = IBank.Stake({
            owner : account,
            tokenId : uint16(tokenId),
            value : uint80(block.timestamp)
        });
        emit TokenStaked(account, tokenId, block.timestamp);
    }

    function _addThiefToBankWithTime(address account, uint256 tokenId, uint256 time) internal {
        bank[tokenId] = IBank.Stake({
        owner : account,
        tokenId : uint16(tokenId),
        value : uint80(time)
        });
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
    function claimManyFromBankAndPack(uint16[] calldata tokenIds, bool unstake) external nonReentrant {
        require(msg.sender == tx.origin || _msgSender() == address(swapper), "Only EOA");
        require(canClaim || msg.sender == owner(), "Claim deactive");

        uint256 owed = 0;
        uint256 burn = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            uint16 _id = tokenIds[i];

            IPoliceAndThief.ThiefPolice memory traits = interact(_id);

            if (traits.isThief) {
                owed += _claimThiefFromBank(_id, unstake);
                if (unstake) {
                    burn += 2 ether;
                }
            }
            else
                owed += _claimPoliceFromPack(_id, unstake);

            if (unstake) {
                realOwnerOf[_id] = address(0);
            }
        }

        loot.mint(address(this), owed + burn);
        if (burn == 0) return;
        loot.burn(address(this), burn);

        loot.transfer(_msgSender(), owed);
    }

    function interact(uint16 _id) internal returns(IPoliceAndThief.ThiefPolice memory traits) {
        traits = game.getTokenTraits(_id);
        address tokenOwner = game.ownerOf(_id);
        if (!interacted[_id] && tokenOwner == address(p2checks)) {

            if (traits.isThief) {
                uint256 value = 0;
                address owner = address(0);
                (, value, owner) = p2checks.bank(_id);

                _setOldTokenInfo(
                    _id,
                    traits.isThief,
                    owner,
                    value == 1644192600 || value == 1644228600 || value == 1644271200 ? startTimestamp : value
                );
            } else {
                uint256 packIndex = oldBank.packIndices(_id);
                IBank.Stake memory s = oldBank.pack(8 - traits.alphaIndex, packIndex);
                _setOldTokenInfo(_id, traits.isThief, s.owner, s.value);
            }
            game.transferFrom(address(p2checks), address(this), _id);
            interacted[_id] = true;
        }

        if (tokenOwner != address(p2checks)) {
            interacted[_id] = true;
        }
    }

    function claimForUser(uint16[] calldata tokenIds, address _tokenOwner) external nonReentrant {
        require(msg.sender == address(thiefUpgrading), "Only Claim");

        uint256 owed = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            interact(tokenIds[i]);
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

        owed = (block.timestamp - stake.value) * (DAILY_LOOT_RATE + (multiplier * thiefUpgrading.levelOf(tokenId))) / 1 days;

        require(!(unstake && owed >= MINIMUM_TO_EXIT), "GONNA BE COLD WITHOUT 2 BRIBE");

        if (unstake) {
            game.transferFrom(address(this), stake.owner, tokenId);
            // send back Thief
            delete bank[tokenId];
        } else {
            _payPoliceTax(owed * 20 / 100);
            // percentage tax to staked wolves
            owed = owed * 80 / 100;
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


    /***ADMIN */

    function setSettings(uint256 rate, uint256 exit) external onlyOwner {
        MINIMUM_TO_EXIT = exit;
        DAILY_LOOT_RATE = rate;
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
     * gets the alpha score for a Police
     * @param tokenId the ID of the Police to get the alpha score for
   * @return the alpha score of the Police (5-8)
   */
    function _alphaForPolice(uint256 tokenId) internal view returns (uint8) {
        IPoliceAndThief.ThiefPolice memory t = game.getTokenTraits(tokenId);
        return 8 - t.alphaIndex;
        // alpha index is 0-3
    }

    function setSwapper(address swp) public onlyOwner {
        swapper = swp;
    }

    function setThiefUpgrading(IThiefUpgrading _upgrading) public onlyOwner {
        thiefUpgrading = _upgrading;
    }

    function setClaiming(bool _canClaim) public onlyOwner {
        canClaim = _canClaim;
    }

    function setMultiplier(uint256 _newMultiplier) public onlyOwner {
        multiplier = _newMultiplier;
    }

    function setL(uint256 _setL) public onlyOwner {
        lootPerAlpha = _setL;
    }

    function setDataToNewBank(uint256[] memory ids) public nonReentrant {
        require(paused() || msg.sender == owner(), "Paused");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            if (game.ownerOf(id) != address(oldBank)) continue;

            IPoliceAndThief.ThiefPolice memory traits = game.getTokenTraits(id);
            address owner = address(0);
            if (traits.isThief) {
                (,, owner) = oldBank.bank(id);
            } else {
                uint256 packIndex = oldBank.packIndices(id);
                IBank.Stake memory s = oldBank.pack(8 - traits.alphaIndex, packIndex);
                owner = s.owner;
            }

            require(owner == msg.sender, "Not your tokens");

            game.transferFrom(address(oldBank), owner, id);
            game.transferFrom(owner, address(this), id);
            _setOldTokenInfo(id, traits.isThief, owner, startTimestamp);
        }

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
    function setOldBankStats(uint256, uint256) external;

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
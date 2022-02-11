// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./IERC721Receiver.sol";
import "./Pauseable.sol";
import "./FraudsterVsCommissioner.sol";
import "./LOOT.sol";
import "./IBank.sol";

contract Bank is Ownable, IERC721Receiver, Pauseable {

    // maximum alpha score for a Police
    uint8 public constant MAX_ALPHA = 8;

    // struct to store a stake's token, owner, and earning values
    struct Stake {
        uint16 tokenId;
        uint80 value;
        address owner;
    }

    event TokenStaked(address owner, uint256 tokenId, uint256 value);
    event ThiefClaimed(uint256 tokenId, uint256 earned, bool unstaked);
    event PoliceClaimed(uint256 tokenId, uint256 earned, bool unstaked);

    // reference to the PoliceAndThief NFT contract
    FraudsterVsCommissioner game;
    // reference to the $LOOT contract for minting $LOOT earnings
    LOOT loot;

    // maps tokenId to stake
    mapping(uint256 => Stake) public bank;
    // maps alpha to all Police stakes with that alpha
    mapping(uint256 => Stake[]) public pack;
    // tracks location of each Police in Pack
    mapping(uint256 => uint256) public packIndices;
    // total alpha scores staked
    uint256 public totalAlphaStaked = 0;
    // any rewards distributed when no wolves are staked
    uint256 public unaccountedRewards = 0;
    // amount of $LOOT due for each alpha point staked
    uint256 public lootPerAlpha = 0;

    // thief earn 10000 $LOOT per day
    uint256 public DAILY_LOOT_RATE = 10000 ether;
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

    // emergency rescue to allow unstaking without any checks but without $LOOT
    bool public rescueEnabled = false;

    bool private _reentrant = false;

    modifier nonReentrant() {
        require(!_reentrant, "No reentrancy");
        _reentrant = true;
        _;
        _reentrant = false;
    }

    /**
     * @param _game reference to the PoliceAndThief NFT contract
   * @param _loot reference to the $LOOT token
   */
    constructor(FraudsterVsCommissioner _game, LOOT _loot) {
        game = _game;
        loot = _loot;
    }

    /***STAKING */

    /**
     * adds Thief and Polices to the Bank and Pack
     * @param account the address of the staker
   * @param tokenIds the IDs of the Thief and Polices to stake
   */
    function addManyToBankAndPack(address account, uint16[] calldata tokenIds) external nonReentrant {
        require((account == _msgSender() && account == tx.origin) || _msgSender() == address(game), "DONT GIVE YOUR TOKENS AWAY");

        for (uint i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i] == 0) {
                continue;
            }

            if (_msgSender() != address(game)) {// dont do this step if its a mint + stake
                require(game.ownerOf(tokenIds[i]) == _msgSender(), "AINT YO TOKEN");
                game.transferFrom(_msgSender(), address(this), tokenIds[i]);
            }

            if (isThief(tokenIds[i]))
                _addThiefToBank(account, tokenIds[i]);
            else
                _addPoliceToPack(account, tokenIds[i]);
        }
    }

    /**
     * adds a single Thief to the Bank
     * @param account the address of the staker
   * @param tokenId the ID of the Thief to add to the Bank
   */
    function _addThiefToBank(address account, uint256 tokenId) internal whenNotPaused _updateEarnings {
        bank[tokenId] = Stake({
        owner : account,
        tokenId : uint16(tokenId),
        value : uint80(block.timestamp)
        });
        totalThiefStaked += 1;
        emit TokenStaked(account, tokenId, block.timestamp);
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
        pack[alpha].push(Stake({
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
    function claimManyFromBankAndPack(uint16[] calldata tokenIds, bool unstake) external nonReentrant whenNotPaused _updateEarnings {
        require(msg.sender == tx.origin, "Only EOA");
        uint256 owed = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            if (isThief(tokenIds[i]))
                owed += _claimThiefFromBank(tokenIds[i], unstake);
            else
                owed += _claimPoliceFromPack(tokenIds[i], unstake);
        }
        if (owed == 0) return;
        loot.mint(_msgSender(), owed);
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
        Stake memory stake = bank[tokenId];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        require(!(unstake && block.timestamp - stake.value < MINIMUM_TO_EXIT), "GONNA BE COLD WITHOUT TWO DAY'S LOOT");
        if (totalLootEarned < MAXIMUM_GLOBAL_LOOT) {
            owed = (block.timestamp - stake.value) * DAILY_LOOT_RATE / 1 days;
        } else if (stake.value > lastClaimTimestamp) {
            owed = 0;
            // $LOOT production stopped already
        } else {
            owed = (lastClaimTimestamp - stake.value) * DAILY_LOOT_RATE / 1 days;
            // stop earning additional $LOOT if it's all been earned
        }
        if (unstake) {
            if (random(tokenId) & 1 == 1) {// 50% chance of all $LOOT stolen
                _payPoliceTax(owed);
                owed = 0;
            }
            game.transferFrom(address(this), _msgSender(), tokenId);
            // send back Thief
            delete bank[tokenId];
            totalThiefStaked -= 1;
        } else {
            _payPoliceTax(owed * LOOT_CLAIM_TAX_PERCENTAGE / 100);
            // percentage tax to staked wolves
            owed = owed * (100 - LOOT_CLAIM_TAX_PERCENTAGE) / 100;
            // remainder goes to Thief owner
            bank[tokenId] = Stake({
            owner : _msgSender(),
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
        Stake memory stake = pack[alpha][packIndices[tokenId]];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        owed = (alpha) * (lootPerAlpha - stake.value);
        // Calculate portion of tokens based on Alpha
        if (unstake) {
            totalAlphaStaked -= alpha;
            // Remove Alpha from total staked
            game.transferFrom(address(this), _msgSender(), tokenId);
            // Send back Police
            Stake memory lastStake = pack[alpha][pack[alpha].length - 1];
            pack[alpha][packIndices[tokenId]] = lastStake;
            // Shuffle last Police to current position
            packIndices[lastStake.tokenId] = packIndices[tokenId];
            pack[alpha].pop();
            // Remove duplicate
            delete packIndices[tokenId];
            // Delete old mapping
        } else {
            pack[alpha][packIndices[tokenId]] = Stake({
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
        Stake memory stake;
        Stake memory lastStake;
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
        (thief, , , , , , , , ) = game.tokenTraits(tokenId);
    }

    /**
     * gets the alpha score for a Police
     * @param tokenId the ID of the Police to get the alpha score for
   * @return the alpha score of the Police (5-8)
   */
    function _alphaForPolice(uint256 tokenId) internal view returns (uint8) {
        (, , , , , , , , uint8 alphaIndex) = game.tokenTraits(tokenId);
        return MAX_ALPHA - alphaIndex;
        // alpha index is 0-3
    }

    /**
     * chooses a random Police thief when a newly minted token is stolen
     * @param seed a random value to choose a Police from
   * @return the owner of the randomly selected Police thief
   */
    function randomPoliceOwner(uint256 seed) external view returns (address) {
        if (totalAlphaStaked == 0) return address(0x0);
        uint256 bucket = (seed & 0xFFFFFFFF) % totalAlphaStaked;
        // choose a value from 0 to total alpha staked
        uint256 cumulative;
        seed >>= 32;
        // loop through each bucket of Polices with the same alpha score
        for (uint i = MAX_ALPHA - 3; i <= MAX_ALPHA; i++) {
            cumulative += pack[i].length * i;
            // if the value is not inside of that bucket, keep going
            if (bucket >= cumulative) continue;
            // get the address of a random Police with that alpha score
            return pack[i][seed % pack[i].length].owner;
        }
        return address(0x0);
    }

    /**
     * generates a pseudorandom number
     * @param seed a value ensure different outcomes for different sources in the same block
   * @return a pseudorandom value
   */
    function random(uint256 seed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
                tx.origin,
                blockhash(block.number - 1),
                block.timestamp,
                seed,
                totalThiefStaked,
                totalAlphaStaked,
                lastClaimTimestamp
            )));
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
}
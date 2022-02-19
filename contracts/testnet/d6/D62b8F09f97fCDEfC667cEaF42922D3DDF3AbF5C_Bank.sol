// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./IERC721Receiver.sol";
import "./Pauseable.sol";
import "./FraudsterVsCommissioner.sol";
import "./EL.sol";
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
    event FraudsterClaimed(uint256 tokenId, uint256 earned, bool unstaked);
    event CommissionerClaimed(uint256 tokenId, uint256 earned, bool unstaked);

    mapping(address => uint256[]) private bags;

    // reference to the PoliceAndThief NFT contract
    FraudsterVsCommissioner game;
    // reference to the $el contract for minting $el earnings
    EL el;

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
    // amount of $el due for each alpha point staked
    uint256 public elPerAlpha = 0;

    // thief earn 10000 $el per day
    uint256 public DAILY_EL_RATE = 10000 ether;
    // thief must have 2 days worth of $el to unstake or else it's too cold
    uint256 public MINIMUM_TO_EXIT = 2 days;
    // wolves take a 20% tax on all $el claimed
    uint256 public constant EL_CLAIM_TAX_PERCENTAGE = 20;
    // there will only ever be (roughly) 2.4 billion $el earned through staking
    uint256 public constant MAXIMUM_GLOBAL_EL = 2400000000 ether;

    // amount of $el earned so far
    uint256 public totalelEarned;
    // number of Thief staked in the Bank
    uint256 public totalFraudsterStaked;
    // the last time $el was claimed
    uint256 public lastClaimTimestamp;

    // emergency rescue to allow unstaking without any checks but without $el
    bool public rescueEnabled = false;

    bool private _reentrant = false;

    modifier nonReentrant() {
        require(!_reentrant, "No reentrancy");
        _reentrant = true;
        _;
        _reentrant = false;
    }

    function _remove(address account, uint256 _tokenId) internal {
        uint256[] storage bag = bags[account];
        for (uint256 i = 0; i < bag.length; i++) {
            if (bag[i] == _tokenId) {
                bag[i] = bag[bag.length - 1];
                bag.pop();
                break;
            }
        }
    }

    function _add(address account, uint256 _tokenId) internal {
        uint256[] storage bag = bags[account];
        bag.push(_tokenId);
    }

    function getTokensOf(address account)
        external
        view
        returns (uint256[] memory)
    {
        return bags[account];
    }

    /**
     * @param _game reference to the PoliceAndThief NFT contract
     * @param _el reference to the $EL token
    **/
    constructor(FraudsterVsCommissioner _game, EL _el) {
        game = _game;
        el = _el;
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
            _add(_msgSender(), tokenIds[i]);

            if (_msgSender() != address(game)) {// dont do this step if its a mint + stake
                require(game.ownerOf(tokenIds[i]) == _msgSender(), "AINT YO TOKEN");
                game.transferFrom(_msgSender(), address(this), tokenIds[i]);
            }

            if (isFraudster(tokenIds[i]))
                _addFraudsterToBank(account, tokenIds[i]);
            else
                _addCommissionerToPack(account, tokenIds[i]);
        }
    }

    /**
     * adds a single Thief to the Bank
     * @param account the address of the staker
   * @param tokenId the ID of the Thief to add to the Bank
   */
    function _addFraudsterToBank(address account, uint256 tokenId) internal whenNotPaused _updateEarnings {
        bank[tokenId] = Stake({
        owner : account,
        tokenId : uint16(tokenId),
        value : uint80(block.timestamp)
        });
        totalFraudsterStaked += 1;
        emit TokenStaked(account, tokenId, block.timestamp);
    }

    /**
     * adds a single Police to the Pack
     * @param account the address of the staker
   * @param tokenId the ID of the Police to add to the Pack
   */
    function _addCommissionerToPack(address account, uint256 tokenId) internal {
        uint256 alpha = _alphaForCommissioner(tokenId);
        totalAlphaStaked += alpha;
        // Portion of earnings ranges from 8 to 5
        packIndices[tokenId] = pack[alpha].length;
        // Store the location of the police in the Pack
        pack[alpha].push(Stake({
        owner : account,
        tokenId : uint16(tokenId),
        value : uint80(elPerAlpha)
        }));
        // Add the police to the Pack
        emit TokenStaked(account, tokenId, elPerAlpha);
    }

    /***CLAIMING / UNSTAKING */

    /**
     * realize $el earnings and optionally unstake tokens from the Bank / Pack
     * to unstake a Thief it will require it has 2 days worth of $el unclaimed
     * @param tokenIds the IDs of the tokens to claim earnings from
   * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
   */
    function claimManyFromBankAndPack(uint16[] calldata tokenIds, bool unstake) external nonReentrant whenNotPaused _updateEarnings {
        require(msg.sender == tx.origin, "Only EOA");
        uint256 owed = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            if (isFraudster(tokenIds[i]))
                owed += _claimThiefFromBank(tokenIds[i], unstake);
            else
                owed += _claimPoliceFromPack(tokenIds[i], unstake);
        }
        if (owed == 0) return;
        el.mint(_msgSender(), owed);
    }

    /**
     * realize $el earnings for a single Thief and optionally unstake it
     * if not unstaking, pay a 20% tax to the staked Polices
     * if unstaking, there is a 50% chance all $el is stolen
     * @param tokenId the ID of the Thief to claim earnings from
   * @param unstake whether or not to unstake the Thief
   * @return owed - the amount of $el earned
   */
    function _claimThiefFromBank(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
        Stake memory stake = bank[tokenId];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        require(!(unstake && block.timestamp - stake.value < MINIMUM_TO_EXIT), "GONNA BE COLD WITHOUT TWO DAY'S el");
        if (totalelEarned < MAXIMUM_GLOBAL_EL) {
            owed = (block.timestamp - stake.value) * DAILY_EL_RATE / 1 days;
        } else if (stake.value > lastClaimTimestamp) {
            owed = 0;
            // $el production stopped already
        } else {
            owed = (lastClaimTimestamp - stake.value) * DAILY_EL_RATE / 1 days;
            // stop earning additional $el if it's all been earned
        }
        if (unstake) {
            if (random(tokenId) & 1 == 1) {// 50% chance of all $el stolen
                _payCommissionerTax(owed);
                owed = 0;
            }
            game.transferFrom(address(this), _msgSender(), tokenId);
            // send back Thief
            delete bank[tokenId];
            totalFraudsterStaked -= 1;
        } else {
            _payCommissionerTax(owed * EL_CLAIM_TAX_PERCENTAGE / 100);
            // percentage tax to staked wolves
            owed = owed * (100 - EL_CLAIM_TAX_PERCENTAGE) / 100;
            // remainder goes to Thief owner
            bank[tokenId] = Stake({
            owner : _msgSender(),
            tokenId : uint16(tokenId),
            value : uint80(block.timestamp)
            });
            // reset stake
        }
        emit FraudsterClaimed(tokenId, owed, unstake);
    }

    /**
     * realize $el earnings for a single Police and optionally unstake it
     * Polices earn $el proportional to their Alpha rank
     * @param tokenId the ID of the Police to claim earnings from
   * @param unstake whether or not to unstake the Police
   * @return owed - the amount of $el earned
   */
    function _claimPoliceFromPack(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
        require(game.ownerOf(tokenId) == address(this), "AINT A PART OF THE PACK");
        uint256 alpha = _alphaForCommissioner(tokenId);
        Stake memory stake = pack[alpha][packIndices[tokenId]];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        owed = (alpha) * (elPerAlpha - stake.value);
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
            value : uint80(elPerAlpha)
            });
            // reset stake
        }
        emit CommissionerClaimed(tokenId, owed, unstake);
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
            if (isFraudster(tokenId)) {
                stake = bank[tokenId];
                require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
                game.transferFrom(address(this), _msgSender(), tokenId);
                // send back Thief
                delete bank[tokenId];
                totalFraudsterStaked -= 1;
                emit FraudsterClaimed(tokenId, 0, true);
            } else {
                alpha = _alphaForCommissioner(tokenId);
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
                emit CommissionerClaimed(tokenId, 0, true);
            }
        }
    }

    /***ACCOUNTING */

    /**
     * add $el to claimable pot for the Pack
     * @param amount $el to add to the pot
   */
    function _payCommissionerTax(uint256 amount) internal {
        if (totalAlphaStaked == 0) {// if there's no staked wolves
            unaccountedRewards += amount;
            // keep track of $el due to wolves
            return;
        }
        // makes sure to include any unaccounted $el
        elPerAlpha += (amount + unaccountedRewards) / totalAlphaStaked;
        unaccountedRewards = 0;
    }

    /**
     * tracks $el earnings to ensure it stops once 2.4 billion is eclipsed
     */
    modifier _updateEarnings() {
        if (totalelEarned < MAXIMUM_GLOBAL_EL) {
            totalelEarned +=
            (block.timestamp - lastClaimTimestamp)
            * totalFraudsterStaked
            * DAILY_EL_RATE / 1 days;
            lastClaimTimestamp = block.timestamp;
        }
        _;
    }

    /***ADMIN */

    function setSettings(uint256 rate, uint256 exit) external onlyOwner {
        MINIMUM_TO_EXIT = exit;
        DAILY_EL_RATE = rate;
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
     * checks if a token is a Fraudster
     * @param tokenId the ID of the token to check
   * @return fraudster - whether or not a token is a Fraudster
   */
    function isFraudster(uint256 tokenId) public view returns (bool fraudster) {
        (fraudster, ) = game.tokenTraits(tokenId);
    }

    /**
     * gets the alpha score for a Police
     * @param tokenId the ID of the Police to get the alpha score for
   * @return the alpha score of the Police (5-8)
   */
    function _alphaForCommissioner(uint256 tokenId) internal view returns (uint8) {
        (, uint8 alphaIndex) = game.tokenTraits(tokenId);
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
                totalFraudsterStaked,
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
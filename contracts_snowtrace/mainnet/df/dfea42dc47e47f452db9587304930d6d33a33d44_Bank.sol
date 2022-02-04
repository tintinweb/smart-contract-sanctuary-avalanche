// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./TaxOfficersVsDegens.sol";
import "./IERC721Receiver.sol";
import "./Pauseable.sol";
import "./FIAT.sol";


contract Bank is Ownable, IERC721Receiver, Pauseable {

    // maximum alpha score for a TaxOfficer
    uint8 public constant MAX_ALPHA = 8;

    // struct to store a stake's token, owner, and earning values
    struct Stake {
        uint16 tokenId;
        uint80 value;
        address owner;
    }

    event TokenStaked(address owner, uint256 tokenId, uint256 value);
    event DegenClaimed(uint256 tokenId, uint256 earned, bool unstaked);
    event TaxOfficerClaimed(uint256 tokenId, uint256 earned, bool unstaked);

    // reference to the TaxOfficersVsDegens NFT contract
    TaxOfficersVsDegens game;
    // reference to the $FIAT contract for minting $FIAT earnings
    FIAT fiat;

    // maps tokenId to stake
    mapping(uint256 => Stake) public bank;
    // maps alpha to all TaxOfficers stakes with that alpha
    mapping(uint256 => Stake[]) public pack;
    // tracks location of each TaxOfficers in Pack
    mapping(uint256 => uint256) public packIndices;
    // total alpha scores staked
    uint256 public totalAlphaStaked = 0;
    // any rewards distributed when no TaxOfficers are staked
    uint256 public unaccountedRewards = 0;
    // amount of $FIAT due for each alpha point staked
    uint256 public fiatPerAlpha = 0;

    // degen earn 10000 $FIAT per day
    uint256 public DAILY_FIAT_RATE = 10000 ether;
    // degen must have 2 days worth of $FIAT to unstake or else it's too cold
    uint256 public MINIMUM_TO_EXIT = 2 days;
    // wolves take a 20% tax on all $FIAT claimed
    uint256 public constant FIAT_CLAIM_TAX_PERCENTAGE = 20;
    // there will only ever be (roughly) 2.4 billion $FIAT earned through staking
    uint256 public constant MAXIMUM_GLOBAL_FIAT = 2400000000 ether;

    // amount of $FIAT earned so far
    uint256 public totalFiatEarned;
    // number of Degen staked in the Bank
    uint256 public totalDegenStaked;
    // the last time $FIAT was claimed
    uint256 public lastClaimTimestamp;

    // emergency rescue to allow unstaking without any checks but without $FIAT
    bool public rescueEnabled = false;

    bool private _reentrant = false;

    modifier nonReentrant() {
        require(!_reentrant, "No reentrancy");
        _reentrant = true;
        _;
        _reentrant = false;
    }

    /**
     * @param _game reference to the TaxOfficersVsDegens NFT contract
   * @param _fiat reference to the $FIAT token
   */
    constructor(TaxOfficersVsDegens _game, FIAT _fiat) {
        game = _game;
        fiat = _fiat;
    }

    /***STAKING */

    /**
     * adds Degens and TaxOfficers to the Bank and Pack
     * @param account the address of the staker
   * @param tokenIds the IDs of the Degens and TaxOfficers to stake
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

            if (isDegen(tokenIds[i]))
                _addDegenToBank(account, tokenIds[i]);
            else
                _addTaxOfficerToPack(account, tokenIds[i]);
        }
    }

    /**
     * adds a single Degen to the Bank
     * @param account the address of the staker
   * @param tokenId the ID of the Degen to add to the Bank
   */
    function _addDegenToBank(address account, uint256 tokenId) internal whenNotPaused _updateEarnings {
        bank[tokenId] = Stake({
        owner : account,
        tokenId : uint16(tokenId),
        value : uint80(block.timestamp)
        });
        totalDegenStaked += 1;
        emit TokenStaked(account, tokenId, block.timestamp);
    }

    /**
     * adds a single TaxOfficer to the Pack
     * @param account the address of the staker
   * @param tokenId the ID of the TaxOfficer to add to the Pack
   */
    function _addTaxOfficerToPack(address account, uint256 tokenId) internal {
        uint256 alpha = _alphaForTaxOfficer(tokenId);
        totalAlphaStaked += alpha;
        // Portion of earnings ranges from 8 to 5
        packIndices[tokenId] = pack[alpha].length;
        // Store the location of the TaxOfficer in the Pack
        pack[alpha].push(Stake({
        owner : account,
        tokenId : uint16(tokenId),
        value : uint80(fiatPerAlpha)
        }));
        bank[tokenId] = Stake({
            owner : account,
            tokenId : uint16(tokenId),
            value : uint80(fiatPerAlpha)
        });
        // Add the TaxOfficer to the Pack
        emit TokenStaked(account, tokenId, fiatPerAlpha);
    }

    /***CLAIMING / UNSTAKING */

    /**
     * realize $FIAT earnings and optionally unstake tokens from the Bank / Pack
     * to unstake a Degen it will require it has 2 days worth of $FIAT unclaimed
     * @param tokenIds the IDs of the tokens to claim earnings from
   * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
   */
    function claimManyFromBankAndPack(uint16[] calldata tokenIds, bool unstake) external nonReentrant whenNotPaused _updateEarnings {
        require(msg.sender == tx.origin, "Only EOA");
        uint256 owed = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            if (isDegen(tokenIds[i]))
                owed += _claimDegenFromBank(tokenIds[i], unstake);
            else
                owed += _claimTaxOfficerFromBank(tokenIds[i], unstake);
        }
        if (owed == 0) return;
        fiat.mint(_msgSender(), owed);
    }

    

    /**
     * realize $FIAT earnings for a single Degen and optionally unstake it
     * if not unstaking, pay a 20% tax to the staked TaxOfficers
     * if unstaking, there is a 50% chance all $FIAT is stolen
     * @param tokenId the ID of the Degen to claim earnings from
   * @param unstake whether or not to unstake the Degen
   * @return owed - the amount of $FIAT earned
   */
    function _claimDegenFromBank(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
        Stake memory stake = bank[tokenId];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        require(!(unstake && block.timestamp - stake.value < MINIMUM_TO_EXIT), "GONNA BE COLD WITHOUT TWO DAY'S FIAT");
        if (totalFiatEarned < MAXIMUM_GLOBAL_FIAT) {
            owed = (block.timestamp - stake.value) * DAILY_FIAT_RATE / 1 days;
        } else if (stake.value > lastClaimTimestamp) {
            owed = 0;
            // $FIAT production stopped already
        } else {
            owed = (lastClaimTimestamp - stake.value) * DAILY_FIAT_RATE / 1 days;
            // stop earning additional $FIAT if it's all been earned
        }
        if (unstake) {
            if (random(tokenId) & 1 == 1) {// 50% chance of all $FIAT stolen
                _payTaxOfficerTax(owed);
                owed = 0;
            }
            game.transferFrom(address(this), _msgSender(), tokenId);
            // send back Degen
            delete bank[tokenId];
            totalDegenStaked -= 1;
        } else {
            _payTaxOfficerTax(owed * FIAT_CLAIM_TAX_PERCENTAGE / 100);
            // percentage tax to staked taxOfficers
            owed = owed * (100 - FIAT_CLAIM_TAX_PERCENTAGE) / 100;
            // remainder goes to Degen owner
            bank[tokenId] = Stake({
            owner : _msgSender(),
            tokenId : uint16(tokenId),
            value : uint80(block.timestamp)
            });
            // reset stake
        }
        emit DegenClaimed(tokenId, owed, unstake);
    }

    /**
     * realize $FIAT earnings for a single TaxOfficer and optionally unstake it
     * TaxOfficers earn $FIAT proportional to their Alpha rank
     * @param tokenId the ID of the TaxOfficer to claim earnings from
   * @param unstake whether or not to unstake the TaxOfficer
   * @return owed - the amount of $FIAT earned
   */
    function _claimTaxOfficerFromBank(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
        require(game.ownerOf(tokenId) == address(this), "AINT A PART OF THE PACK");
        uint256 alpha = _alphaForTaxOfficer(tokenId);
        Stake memory stake = pack[alpha][packIndices[tokenId]];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        owed = (alpha) * (fiatPerAlpha - stake.value);
        // Calculate portion of tokens based on Alpha
        if (unstake) {
            totalAlphaStaked -= alpha;
            // Remove Alpha from total staked
            game.transferFrom(address(this), _msgSender(), tokenId);
            // Send back TaxOfficer
            Stake memory lastStake = pack[alpha][pack[alpha].length - 1];
            pack[alpha][packIndices[tokenId]] = lastStake;
            // Shuffle last TaxOfficer to current position
            packIndices[lastStake.tokenId] = packIndices[tokenId];
            pack[alpha].pop();
            // Remove duplicate
            delete packIndices[tokenId];
            // Delete old mapping
        } else {
            pack[alpha][packIndices[tokenId]] = Stake({
            owner : _msgSender(),
            tokenId : uint16(tokenId),
            value : uint80(fiatPerAlpha)
            });
            // reset stake
        }
        emit TaxOfficerClaimed(tokenId, owed, unstake);
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
            if (isDegen(tokenId)) {
                stake = bank[tokenId];
                require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
                game.transferFrom(address(this), _msgSender(), tokenId);
                // send back Degen
                delete bank[tokenId];
                totalDegenStaked -= 1;
                emit DegenClaimed(tokenId, 0, true);
            } else {
                alpha = _alphaForTaxOfficer(tokenId);
                stake = pack[alpha][packIndices[tokenId]];
                require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
                totalAlphaStaked -= alpha;
                // Remove Alpha from total staked
                game.transferFrom(address(this), _msgSender(), tokenId);
                // Send back TaxOfficer
                lastStake = pack[alpha][pack[alpha].length - 1];
                pack[alpha][packIndices[tokenId]] = lastStake;
                // Shuffle last TaxOfficer to current position
                packIndices[lastStake.tokenId] = packIndices[tokenId];
                pack[alpha].pop();
                // Remove duplicate
                delete packIndices[tokenId];
                // Delete old mapping
                emit TaxOfficerClaimed(tokenId, 0, true);
            }
        }
    }

    /***ACCOUNTING */

    /**
     * add $FIAT to claimable pot for the Pack
     * @param amount $FIAT to add to the pot
   */
    function _payTaxOfficerTax(uint256 amount) internal {
        if (totalAlphaStaked == 0) {// if there's no staked TaxOfficer
            unaccountedRewards += amount;
            // keep track of $FIAT due to TaxOfficer
            return;
        }
        // makes sure to include any unaccounted $FIAT
        fiatPerAlpha += (amount + unaccountedRewards) / totalAlphaStaked;
        unaccountedRewards = 0;
    }

    /**
     * tracks $FIAT earnings to ensure it stops once 2.4 billion is eclipsed
     */
    modifier _updateEarnings() {
        if (totalFiatEarned < MAXIMUM_GLOBAL_FIAT) {
            totalFiatEarned +=
            (block.timestamp - lastClaimTimestamp)
            * totalDegenStaked
            * DAILY_FIAT_RATE / 1 days;
            lastClaimTimestamp = block.timestamp;
        }
        _;
    }

    /***ADMIN */

    function setSettings(uint256 rate, uint256 exit) external onlyOwner {
        MINIMUM_TO_EXIT = exit;
        DAILY_FIAT_RATE = rate;
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
     * checks if a token is a Degen
     * @param tokenId the ID of the token to check
   * @return degen - whether or not a token is a Degen
   */
    function isDegen(uint256 tokenId) public view returns (bool degen) {
        (degen, , , , , , , , , ,) = game.tokenTraits(tokenId);
    }

    /**
     * gets the alpha score for a TaxOfficer
     * @param tokenId the ID of the TaxOfficer to get the alpha score for
   * @return the alpha score of the TaxOfficer (5-8)
   */
    function _alphaForTaxOfficer(uint256 tokenId) internal view returns (uint8) {
        (, , , , , , , , , , uint8 alphaIndex) = game.tokenTraits(tokenId);
        return MAX_ALPHA - alphaIndex;
        // alpha index is 0-3
    }

    /**
     * chooses a random TaxOfficer Degen when a newly minted token is stolen
     * @param seed a random value to choose a TaxOfficer from
   * @return the owner of the randomly selected TaxOfficer Degen
   */
    function randomTaxOfficerOwner(uint256 seed) external view returns (address) {
        if (totalAlphaStaked == 0) return address(0x0);
        uint256 bucket = (seed & 0xFFFFFFFF) % totalAlphaStaked;
        // choose a value from 0 to total alpha staked
        uint256 cumulative;
        seed >>= 32;
        // loop through each bucket of TaxOfficers with the same alpha score
        for (uint i = MAX_ALPHA - 3; i <= MAX_ALPHA; i++) {
            cumulative += pack[i].length * i;
            // if the value is not inside of that bucket, keep going
            if (bucket >= cumulative) continue;
            // get the address of a random TaxOfficer with that alpha score
            return pack[i][seed % pack[i].length].owner;
        }
        return address(0x0);
    }

    function balanceOf() view public returns(uint256) {
        return game.balanceOf(address(this));
    }

    function getStakeToken(address _address) external view returns(string memory) {
        string memory res = "";

        for (uint256 i = 0; i < game.balanceOf(address(this)); i++) {
            uint256 ind = game.tokenOfOwnerByIndex(address(this), i);
            if (bank[ind].owner == _address) {
                res = string(abi.encodePacked(
                    res,
                    uint2str(ind),
                    '-'
                ));
            }
        }
        return res;
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
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
                totalDegenStaked,
                totalAlphaStaked,
                lastClaimTimestamp
            ))) ^ game.randomSource().seed();
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
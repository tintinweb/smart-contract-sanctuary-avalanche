import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC721Enumerable.sol";
import "./Tree.sol";
import "./Leaves.sol";
import "./IBarn.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Barn is Ownable, IERC721Receiver, Pausable {

  // maximum alpha score for a Hunter
    uint8 public constant MAX_ALPHA = 8;

    struct Stake {
        uint16 tokenId;
        uint80 value;
        address owner;
    }
   
    event TokenStaked(address owner, uint256 tokenId, uint256 value);
    event AdventurerClaimed(uint256 tokenId, uint256 earned, bool unstaked);
    event HunterClaimed(uint256 tokenId, uint256 earned, bool unstaked);

    // reference to the Hunter NFT contract
    Tree tree;
    // reference to the $GEM contract for minting $GEM earnings
    Leaves leaves;

    // map all tokenIds to their original owners; ownerAddress => tokenIds
    mapping(address => uint256[]) private _ownersOfStakedTokens;
    // maps tokenId to stake
    mapping(uint256 => Stake) public barn;
    // maps alpha to all hunter stakes with that alpha
    mapping(uint256 => Stake[]) public pack;
    // tracks location of each Hunter in Pack
    mapping(uint256 => uint256) public packIndices;
    // total alpha scores staked
    uint256 public totalAlphaStaked = 0;
    // any rewards distributed when no hunters are staked
    uint256 public unaccountedRewards = 0;
    // amount of $Leaves due for each alpha point staked
    uint256 public leavesPerAlpha = 0;

    // adventurer earn 10000 $Leaves per day
    uint256 public constant DAILY_Leaves_RATE = 10000 ether;
    // adventurer must have 2 days worth of $Leaves to unstake or else it's too cold
    uint256 public constant MINIMUM_TO_EXIT = 2 days;
    // hunters take a 20% tax on all $Leaves claimed
    uint256 public constant Leaves_CLAIM_TAX_PERCENTAGE = 20;
    // there will only ever be (roughly) 2.4 billion $Leaves earned through staking
    uint256 public MAXIMUM_GLOBAL_Leaves = 2400000000 ether;
    //tax on claim
    uint256 public CLAIMING_FEE = 0.01 ether;

    // amount of $Leaves earned so far
    uint256 public totalLeavesEarned;
    // number of Adventurer staked in the Barn
    uint256 public totalAdventurerStaked;
    // the last time $Leaves was claimed
    uint256 public lastClaimTimestamp;

    // emergency rescue to allow unstaking without any checks but without $Leaves
    bool public rescueEnabled = false;

    /**
     * @param _tree reference to the Hunter NFT contract
     * @param _leaves reference to the $Leaves token
     */
    constructor(address _tree, address _leaves) {
        tree = Tree(_tree);
        leaves = Leaves(_leaves);
    }

    function setMAXIMUM_GLOBAL_Leaves(uint256 _MAXIMUM_GLOBAL_Leaves)
        external
        onlyOwner
    {
        MAXIMUM_GLOBAL_Leaves = _MAXIMUM_GLOBAL_Leaves;
    }

    //if its wrong
    function setClaimingFee(uint256 _newfee) external onlyOwner {
        CLAIMING_FEE = _newfee;
    }

    /** STAKING */

    function getStakedTokenIds(address owner) external view returns (uint256[] memory) {
        /* uint64 lastAddressWrite = uNFT.getAddressWriteBlock();
        require(lastAddressWrite < block.number, "Arena: Nope!"); */

        return _ownersOfStakedTokens[owner];
    }
    
    function _addStakeOwner(address owner, uint256 tokenId) private {
        _ownersOfStakedTokens[owner].push(tokenId);
    }
    
    function _removeStakeOwner(address owner, uint256 tokenId) private {
        uint256[] memory tokenIds = _ownersOfStakedTokens[owner];
        uint256[] memory tokenIdsNew = new uint256[](tokenIds.length - 1);

        uint256 counter = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
        if (tokenIds[i] != tokenId) {
            tokenIdsNew[counter] = tokenIds[i];
            counter++;
        } else {
            continue;
        }
        }

        _ownersOfStakedTokens[owner] = tokenIdsNew;
    }

    /**
     * adds Adventurer and Hunters to the Barn and Pack
     * @param account the address of the staker
     * @param tokenIds the IDs of the Adventurer and Hunters to stake
     */
    function addManyToBarnAndPack(address account, uint16[] memory tokenIds)
        external
    {
        require(
            (account == _msgSender() && account == tx.origin) ||
                _msgSender() == address(tree),
            "DONT GIVE YOUR TOKENS AWAY"
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (_msgSender() != address(tree)) {
                // dont do this step if its a mint + stake
                require(
                    tree.ownerOf(tokenIds[i]) == _msgSender(),
                    "AINT YO TOKEN"
                );
                tree.transferFrom(_msgSender(), address(this), tokenIds[i]);
            } else if (tokenIds[i] == 0) {
                continue; // there may be gaps in the array for stolen tokens
            }

            if (hasTotem(tokenIds[i]))
                _addAdventurerToBarn(account, tokenIds[i]);
            else _addHunterToPack(account, tokenIds[i]);
        }
    }

    /**
     * adds a single Adventurer to the Barn
     * @param account the address of the staker
     * @param tokenId the ID of the Adventurer to add to the Barn
     */
    function _addAdventurerToBarn(address account, uint256 tokenId)
        internal
        whenNotPaused
        _updateEarnings
    {
        barn[tokenId] = Stake({
            owner: account,
            tokenId: uint16(tokenId),
            value: uint80(block.timestamp)
        });
        _addStakeOwner(account,tokenId);
        totalAdventurerStaked += 1;
        emit TokenStaked(account, tokenId, block.timestamp);
    }

   
    function _addHunterToPack(address account, uint256 tokenId) internal {
        uint256 alpha = _TotemAlpha(tokenId);
        totalAlphaStaked += alpha; // Portion of earnings ranges from 8 to 5
        packIndices[tokenId] = pack[alpha].length; // Store the location of the hunter in the Pack
        pack[alpha].push(
            Stake({
                owner: account,
                tokenId: uint16(tokenId),
                value: uint80(leavesPerAlpha)
            })
        ); // Add the hunter to the Pack
        emit TokenStaked(account, tokenId, leavesPerAlpha);
    }

    /** CLAIMING / UNSTAKING */

    /**
     * realize $Leaves earnings and optionally unstake tokens from the Barn / Pack
     * to unstake a Adventurer it will require it has 2 days worth of $Leaves unclaimed
     * @param tokenIds the IDs of the tokens to claim earnings from
     * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
     */
    function claimManyFromBarnAndPack(uint16[] memory tokenIds, bool unstake)
        external
        payable
        whenNotPaused
        _updateEarnings
    {
        //payable with the tax
        require(
            msg.value >= tokenIds.length * CLAIMING_FEE,
            "you didnt pay tax"
        );
        uint256 owed = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (hasTotem(tokenIds[i]))
                owed += _claimAdventurerFromBarn(tokenIds[i], unstake);
            else owed += _claimHunterFromPack(tokenIds[i], unstake);
        }
        //fee transfer

        if (owed == 0) return;
        leaves.mint(_msgSender(), owed);
    }

    function calculateRewards(uint256 tokenId)
        external
        view
        returns (uint256 owed)
    {
        if (tree.getTokenTraits(tokenId).hasTotem) {
            Stake memory stake = barn[tokenId];
            if (totalLeavesEarned < MAXIMUM_GLOBAL_Leaves) {
                owed =
                    ((block.timestamp - stake.value) * tree.getTokenTraits(tokenId).currentReward) /
                    1 days;
            } else if (stake.value > lastClaimTimestamp) {
                owed = 0; // $Leaves production stopped already
            } else {
                owed =
                    ((lastClaimTimestamp - stake.value) * tree.getTokenTraits(tokenId).currentReward) /
                    1 days; // stop earning additional $GEM if it's all been earned
            }
        } else {
            uint256 alpha = _TotemAlpha(tokenId);
            Stake memory stake = pack[alpha][packIndices[tokenId]];
            owed = (alpha) * (leavesPerAlpha - stake.value);
        }
    }

    /**
     * realize $GEM earnings for a single Adventurer and optionally unstake it
     * if not unstaking, pay a 20% tax to the staked Hunters
     * if unstaking, there is a 50% chance all $GEM is stolen
     * @param tokenId the ID of the Adventurer to claim earnings from
     * @param unstake whether or not to unstake the Adventurer
     * @return owed - the amount of $GEM earned
     */
    function _claimAdventurerFromBarn(uint256 tokenId, bool unstake)
        internal
        returns (uint256 owed)
    {
        Stake memory stake = barn[tokenId];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        require(
            !(unstake && block.timestamp - stake.value < MINIMUM_TO_EXIT),
            "GONNA BE COLD WITHOUT TWO DAY'S LEAVES"
        );
        if (totalLeavesEarned < MAXIMUM_GLOBAL_Leaves) {
            owed = ((block.timestamp - stake.value) * DAILY_Leaves_RATE) / 1 days;
        } else if (stake.value > lastClaimTimestamp) {
            owed = 0; // $Leaves production stopped already
        } else {
            owed =
                ((lastClaimTimestamp - stake.value) * DAILY_Leaves_RATE) /
                1 days; // stop earning additional $Leaves if it's all been earned
        }
        if (unstake) {
            if (random(tokenId) & 1 == 1) {
                // 50% chance of all $Leaves stolen
                _payHunterTax(owed);
                owed = 0;
            }
            tree.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Adventurer
            delete barn[tokenId];
            _removeStakeOwner(stake.owner, tokenId);
            totalAdventurerStaked -= 1;
        } else {
            _payHunterTax((owed * Leaves_CLAIM_TAX_PERCENTAGE) / 100); // percentage tax to staked hunters
            owed = (owed * (100 - Leaves_CLAIM_TAX_PERCENTAGE)) / 100; // remainder goes to Adventurer owner
            barn[tokenId] = Stake({
                owner: _msgSender(),
                tokenId: uint16(tokenId),
                value: uint80(block.timestamp)
            }); // reset stake
        }
        emit AdventurerClaimed(tokenId, owed, unstake);
    }

  
    function _claimHunterFromPack(uint256 tokenId, bool unstake)
        internal
        returns (uint256 owed)
    {
        require(
            tree.ownerOf(tokenId) == address(this),
            "AINT A PART OF THE PACK"
        );
        uint256 alpha = _TotemAlpha(tokenId);
        Stake memory stake = pack[alpha][packIndices[tokenId]];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        owed = (alpha) * (leavesPerAlpha - stake.value); // Calculate portion of tokens based on Alpha
        if (unstake) {
            totalAlphaStaked -= alpha; // Remove Alpha from total staked
            tree.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back Hunter
            Stake memory lastStake = pack[alpha][pack[alpha].length - 1];
            pack[alpha][packIndices[tokenId]] = lastStake; // Shuffle last Hunter to current position
            packIndices[lastStake.tokenId] = packIndices[tokenId];
            pack[alpha].pop(); // Remove duplicate
            delete packIndices[tokenId]; // Delete old mapping
        } else {
            pack[alpha][packIndices[tokenId]] = Stake({
                owner: _msgSender(),
                tokenId: uint16(tokenId),
                value: uint80(leavesPerAlpha)
            }); // reset stake
        }
        emit HunterClaimed(tokenId, owed, unstake);
    }

    /**
     * emergency unstake tokens
     * @param tokenIds the IDs of the tokens to claim earnings from
     */
    function rescue(uint256[] calldata tokenIds) external {
        require(rescueEnabled, "RESCUE DISABLED");
        uint256 tokenId;
        Stake memory stake;
        Stake memory lastStake;
        uint256 alpha;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            if (hasTotem(tokenId)) {
                stake = barn[tokenId];
                require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
                tree.safeTransferFrom(
                    address(this),
                    _msgSender(),
                    tokenId,
                    ""
                ); // send back Adventurer
                delete barn[tokenId];
                totalAdventurerStaked -= 1;
                emit AdventurerClaimed(tokenId, 0, true);
            }  else {
                alpha = _TotemAlpha(tokenId);
                stake = pack[alpha][packIndices[tokenId]];
                require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
                totalAlphaStaked -= alpha; // Remove Alpha from total staked
                tree.safeTransferFrom(
                    address(this),
                    _msgSender(),
                    tokenId,
                    ""
                ); // Send back Tree
                lastStake = pack[alpha][pack[alpha].length - 1];
                pack[alpha][packIndices[tokenId]] = lastStake; // Shuffle last Tree to current position
                packIndices[lastStake.tokenId] = packIndices[tokenId];
                pack[alpha].pop(); // Remove duplicate
                delete packIndices[tokenId]; // Delete old mapping
                emit HunterClaimed(tokenId, 0, true);
            }
        }
    }

    /** ACCOUNTING */

    /**
     * add $Leaves to claimable pot for the Pack
     * @param amount $Leaves to add to the pot
     */
    function _payHunterTax(uint256 amount) internal {
        if (totalAlphaStaked == 0) {
            // if there's no staked hunters
            unaccountedRewards += amount; // keep track of $Leaves due to hunters
            return;
        }
        // makes sure to include any unaccounted $Leaves
        leavesPerAlpha += (amount + unaccountedRewards) / totalAlphaStaked;
        unaccountedRewards = 0;
    }

    /**
     * tracks $Leaves earnings to ensure it stops once 2.4 billion is eclipsed
     */
    modifier _updateEarnings() {
        if (totalLeavesEarned < MAXIMUM_GLOBAL_Leaves) {
            totalLeavesEarned +=
                ((block.timestamp - lastClaimTimestamp) *
                    totalAdventurerStaked *
                    DAILY_Leaves_RATE) /
                1 days;
            lastClaimTimestamp = block.timestamp;
        }
        _;
    }

    /** ADMIN */

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

    /** READ ONLY */

   
    function hasTotem(uint256 tokenId)
        public
        view
        returns (bool totem)
    {
        (totem, , , , , ,  ) = tree.tokenTraits(tokenId);
    }


    function _TotemAlpha(uint256 tokenId) internal view returns (uint8) {
        (,uint8 alphaIndex , , , , , ) = tree.tokenTraits(tokenId);
        return alphaIndex; // alpha index is 0-3
    }

    /*
     * chooses a random Hunter thief when a newly minted token is stolen
     * @param seed a random value to choose a Hunter from
     * @return the owner of the randomly selected Hunter thief
     */
    function randomHunterOwner(uint256 seed) external view returns (address) {
        if (totalAlphaStaked == 0) return address(0x0);
        uint256 bucket = (seed & 0xFFFFFFFF) % totalAlphaStaked; // choose a value from 0 to total alpha staked
        uint256 cumulative;
        seed >>= 32;
        // loop through each bucket of Hunters with the same alpha score
        for (uint256 i = MAX_ALPHA - 3; i <= MAX_ALPHA; i++) {
            cumulative += pack[i].length * i;
            // if the value is not inside of that bucket, keep going
            if (bucket >= cumulative) continue;
            // get the address of a random Hunter with that alpha score
            return pack[i][seed % pack[i].length].owner;
        }
        return address(0x0);
    }

    function getStake(uint256 tokenId)
        external
        view        
        returns (Stake memory)
    {
        return barn[tokenId];
    }

    /**
     * generates a pseudorandom number
     * @param seed a value ensure different outcomes for different sources in the same block
     * @return a pseudorandom value
     */
    function random(uint256 seed) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        msg.sender,
                        blockhash(block.number - 1),
                        block.timestamp,
                        seed
                    )
                )
            );
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

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
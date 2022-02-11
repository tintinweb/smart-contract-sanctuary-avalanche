// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Pauseable.sol";
import "./ERC721Enumerable.sol";
import "./IFraudsterVsCommissioner.sol";
import "./IBank.sol";
import "./ITraits.sol";
import "./IEL.sol";
import "./Pauseable.sol";
import "./ISeed.sol";

contract FraudsterVsCommissioner is IFraudsterVsCommissioner, ERC721Enumerable, Ownable, Pauseable {
    
    // mint price
    uint256 public MINT_PRICE = 1.25 ether;
    uint256 public MAX_MINT = 30;
    // max number of tokens that can be minted - 50000 in production
    uint256 public immutable MAX_TOKENS;
    // number of tokens that can be claimed for free - 20% of MAX_TOKENS
    uint256 public PAID_TOKENS;
    // number of tokens have been minted so far
    uint16 public minted;

    // mapping from tokenId to a struct containing the token's traits
    mapping(uint256 => FraudsterCommissioner) public tokenTraits;
    // mapping from hashed(tokenTrait) to the tokenId it's associated with
    // used to ensure there are no duplicates
    mapping(uint256 => uint256) public existingCombinations;
    // reference to the Bank for choosing random Police thieves
    IBank public bank;
    // reference to $EL for burning on mint
    IEL public EL;
    // reference to Traits
    ITraits public traits;

    mapping(address => uint256) private airdrops;
    bool private _reentrant = false;
    bool private stakingActive = true;

    modifier nonReentrant() {
        require(!_reentrant, "No reentrancy");
        _reentrant = true;
        _;
        _reentrant = false;
    }

    /**
     * instantiates contract and rarity tables
     */
    constructor(IEL _el, ITraits _traits, uint256 _maxTokens) ERC721("FraudsterVsCommissioner", 'FVC') {
        EL = _el;
        traits = _traits;

        MAX_TOKENS = _maxTokens;
        PAID_TOKENS = _maxTokens / 2;
    }

     function getFreeMintOf(address account) external view returns (uint256) {
        return airdrops[account];
    }

    /***EXTERNAL */

    /**
     * mint a token - 90% Thief, 10% Polices
     * The first 20% are free to claim, the remaining cost $EL
     */
    function mint(uint256 amount, bool stake) external payable nonReentrant whenNotPaused {
        require(!stake || stakingActive, "Staking not activated");

        require(tx.origin == _msgSender(), "Only EOA");
        require(minted + amount <= MAX_TOKENS, "All tokens minted");
        require(amount > 0 && amount <= MAX_MINT, "Invalid mint amount");

        if (minted < PAID_TOKENS) {
            require(minted + amount <= PAID_TOKENS, "All tokens on-sale already sold");
            require(MINT_PRICE * amount == msg.value, "Invalid payment amount");
        } else {
            require(msg.value == 0);
        }

        uint256 totalELCost = 0;
        uint16[] memory tokenIds = new uint16[](amount);
        address[] memory owners = new address[](amount);
        uint256 seed;
        uint256 firstMinted = minted;

        for (uint i = 0; i < amount; i++) {
            minted++;
            seed = random(minted);
            generate(minted, seed);
            address recipient = selectRecipient(seed);
            totalELCost += mintCost(minted);
            if (!stake || recipient != _msgSender()) {
                owners[i] = recipient;
            } else {
                tokenIds[i] = minted;
                owners[i] = address(bank);
            }

        }

        if (totalELCost > 0) EL.burn(_msgSender(), totalELCost);

        for (uint i = 0; i < owners.length; i++) {
            uint id = firstMinted + i + 1;
            if (!stake || owners[i] != _msgSender()) {
                _safeMint(owners[i], id);
            }
        }
        if (stake) bank.addManyToBankAndPack(_msgSender(), tokenIds);
    }

    function freeMint(uint256 amount, bool stake)
        external
        nonReentrant
        whenNotPaused
    {
        require(tx.origin == _msgSender(), "Only EOA");
        require(minted + amount <= MAX_TOKENS, "All tokens minted");

        require(amount <= airdrops[_msgSender()], "Amount exceed airdrop");
        airdrops[_msgSender()] -= amount;

        uint16[] memory tokenIds = new uint16[](amount);
        address[] memory owners = new address[](amount);
        uint256 seed;
        uint256 firstMinted = minted;

        for (uint256 i = 0; i < amount; i++) {
            minted++;
            seed = random(minted);
            generate(minted, seed);
            address recipient = selectRecipient(seed);
            if (!stake || recipient != _msgSender()) {
                owners[i] = recipient;
            } else {
                tokenIds[i] = minted;
                owners[i] = address(bank);
            }
        }

        for (uint256 i = 0; i < owners.length; i++) {
            uint256 id = firstMinted + i + 1;
            if (!stake || owners[i] != _msgSender()) {
                _safeMint(owners[i], id);
            }
        }
        if (stake) bank.addManyToBankAndPack(_msgSender(), tokenIds);
    }

    /**
     * the first 20% are paid in AVAX
     * the next 20% are 20000 $EL
     * the next 40% are 40000 $EL
     * the final 20% are 80000 $EL
     * @param tokenId the ID to check the cost of to mint
   * @return the cost of the given token ID
   */
    function mintCost(uint256 tokenId) public view returns (uint256) {
        if (tokenId <= PAID_TOKENS) return 0;
        if (tokenId <= MAX_TOKENS * 1 / 2) return 10000 ether;
        return 20000 ether;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override nonReentrant {
        // Hardcode the Bank's approval so that users don't have to waste gas approving
        if (_msgSender() != address(bank))
            require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    /***INTERNAL */

    /**
     * generates traits for a specific token, checking to make sure it's unique
     * @param tokenId the id of the token to generate traits for
   * @param seed a pseudorandom 256 bit number to derive traits from
   * @return t - a struct of traits for the given token ID
   */
    function generate(uint256 tokenId, uint256 seed) internal returns (FraudsterCommissioner memory t) {
        t = selectTraits(seed);
        if (existingCombinations[structToHash(t)] == 0) {
            tokenTraits[tokenId] = t;
            existingCombinations[structToHash(t)] = tokenId;
            return t;
        }
        return generate(tokenId, random(seed));
    }

    /**
     * uses A.J. Walker's Alias algorithm for O(1) rarity table lookup
     * ensuring O(1) instead of O(n) reduces mint cost by more than 50%
     * probability & alias tables are generated off-chain beforehand
     * @param seed portion of the 256 bit seed to remove trait correlation
   * @param traitType the trait type to select a trait for
   * @return the ID of the randomly selected trait
   */
    function selectTrait(uint16 seed, uint8 traitType) internal view returns (uint8) {
        return traits.selectTrait(seed, traitType);
    }

    /**
     * the first 20% (ETH purchases) go to the minter
     * the remaining 80% have a 10% chance to be given to a random staked police
     * @param seed a random value to select a recipient from
   * @return the address of the recipient (either the minter or the Police thief's owner)
   */
    function selectRecipient(uint256 seed) internal view returns (address) {
        if (minted <= PAID_TOKENS || ((seed >> 245) % 10) != 0) return _msgSender();
        // top 10 bits haven't been used
        address fraudster = bank.randomCommissionerOwner(seed >> 144);
        // 144 bits reserved for trait selection
        if (fraudster == address(0x0)) return _msgSender();
        return fraudster;
    }

    /**
     * selects the species and all of its traits based on the seed value
     * @param seed a pseudorandom 256 bit number to derive traits from
   * @return t -  a struct of randomly selected traits
   */
    function selectTraits(uint256 seed) internal view returns (FraudsterCommissioner memory t) {
        t.isFraudster = (seed & 0xFFFF) % 10 != 0;
        uint8 shift = t.isFraudster ? 0 : 10;

        seed >>= 16;
        t.uniform = selectTrait(uint16(seed & 0xFFFF), 0 + shift);

        seed >>= 16;
        t.hair = selectTrait(uint16(seed & 0xFFFF), 1 + shift);

        seed >>= 16;
        t.facialHair = selectTrait(uint16(seed & 0xFFFF), 2 + shift);

        seed >>= 16;
        t.eyes = selectTrait(uint16(seed & 0xFFFF), 3 + shift);

        seed >>= 16;
        t.accessory = selectTrait(uint16(seed & 0xFFFF), 4 + shift);

        seed >>= 16;
        t.headgear = selectTrait(uint16(seed & 0xFFFF), 5 + shift);

        seed >>= 16;
        if (!t.isFraudster) {
            t.neckGear = selectTrait(uint16(seed & 0xFFFF), 6 + shift);
            t.alphaIndex = selectTrait(uint16(seed & 0xFFFF), 7 + shift);
        }
    }

    /**
     * converts a struct to a 256 bit hash to check for uniqueness
     * @param s the struct to pack into a hash
   * @return the 256 bit hash of the struct
   */
    function structToHash(FraudsterCommissioner memory s) internal pure returns (uint256) {
        return uint256(keccak256(
                abi.encodePacked(
                    s.isFraudster,
                    s.uniform,
                    s.hair,
                    s.facialHair,
                    s.eyes,
                    s.headgear,
                    s.accessory,
                    s.neckGear,
                    s.alphaIndex
                )
            ));
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
                seed
            )));
    }

    /***READ */

    function getTokenTraits(uint256 tokenId) external view override returns (FraudsterCommissioner memory) {
        return tokenTraits[tokenId];
    }

    function getPaidTokens() external view override returns (uint256) {
        return PAID_TOKENS;
    }

    /***ADMIN */

    /**
     * called after deployment so that the contract can get random police thieves
     * @param _bank the address of the Bank
   */
    function setBank(address _bank) external onlyOwner {
        bank = IBank(_bank);
    }

    /**
     * allows owner to withdraw funds from minting
     */
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * updates the number of tokens for sale
     */
    function setPaidTokens(uint256 _paidTokens) external onlyOwner {
        PAID_TOKENS = _paidTokens;
    }

    /**
     * enables owner to pause / unpause minting
     */
    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    /***RENDER */

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return traits.tokenURI(tokenId);
    }

    function changePrice(uint256 _price) public onlyOwner {
        MINT_PRICE = _price;
    }

    function setStakingActive(bool _staking) public onlyOwner {
        stakingActive = _staking;
    }

    function setTraits(ITraits addr) public onlyOwner {
        traits = addr;
    }
}
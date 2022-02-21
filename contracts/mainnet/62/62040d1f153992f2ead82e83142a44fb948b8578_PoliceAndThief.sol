// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Pauseable.sol";
import "./ERC721Enumerable.sol";
import "./IPoliceAndThief.sol";
import "./IBank.sol";
import "./ITraits.sol";
import "./LOOT.sol";
import "./Pauseable.sol";
import "./ISeed.sol";
import "./Seed.sol";

pragma solidity ^0.8.0;
contract PaymentSplitter is Context {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    constructor(address[] memory payees, uint256[] memory shares_) payable {
        require(payees.length == shares_.length, "PaymentSplitter: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address payable account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = address(this).balance + _totalReleased;
        uint256 payment = (totalReceived * _shares[account]) / _totalShares - _released[account];

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _released[account] = _released[account] + payment;
        _totalReleased = _totalReleased + payment;

        Address.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) private {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(_shares[account] == 0, "PaymentSplitter: account already has shares");

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }
}

pragma solidity ^0.8.0;
contract PoliceAndThief is IPoliceAndThief, ERC721Enumerable, Ownable, Pauseable, PaymentSplitter {

    // mint price
    uint256 public MINT_PRICE = 1.69 ether;
    // max number of tokens that can be minted - 50000 in production
    uint256 public immutable MAX_TOKENS;
    // number of tokens that can be claimed for free - 20% of MAX_TOKENS
    uint256 public PAID_TOKENS;
    uint256 public MAX_MINT = 30;
    // number of tokens have been minted so far
    uint16 public minted;

    bool public whitelistMint;
    bool public publicMint;

    // mapping from tokenId to a struct containing the token's traits
    mapping(uint256 => ThiefPolice) public tokenTraits;
    // mapping from hashed(tokenTrait) to the tokenId it's associated with
    // used to ensure there are no duplicates
    mapping(uint256 => uint256) public existingCombinations;
    // Create mapping of addresses, for the whitelist
    mapping(address => uint256) public whitelistAddresses;

    // list of probabilities for each trait type
    // 0 - 9 are associated with Thief, 10 - 18 are associated with Polices
    uint8[][14] public rarities;
    // list of aliases for Walker's Alias algorithm
    // 0 - 9 are associated with Thief, 10 - 18 are associated with Polices
    uint8[][14] public aliases;

    // reference to the Bank for choosing random Police thieves
    IBank public bank;
    // reference to $LOOT for burning on mint
    LOOT public loot;
    // reference to Traits
    ITraits public traits;

    ISeed public randomSource;

    bool private _reentrant = false;

     

    modifier nonReentrant() {
        require(!_reentrant, "No reentrancy");
        _reentrant = true;
        _;
        _reentrant = false;
    }
    address t1 = 0x637A546D4543d37FfC03642930Ff2Da8f410a994;
    address t2 = 0xB97Fe88938847FdaD1089c1e4EfC5e819C3a0382;
    address t3 = 0x5A42FfB20bf5741482105ef037f13eDeA5B3B02d;

    address[] addressList = [t1, t2, t3];
    uint256[] shareList = [2, 8, 90];

    /**
     * instantiates contract and rarity tables
     */
    constructor(LOOT _loot, ITraits _traits, uint256 _maxTokens)
    ERC721("Pimpsnhoes", 'PNH')
    PaymentSplitter(addressList, shareList) 
    {
        loot = _loot;
        traits = _traits;
        randomSource = ISeed(address(new Seed()));

        MAX_TOKENS = _maxTokens;
        PAID_TOKENS = _maxTokens / 5;


                // I know this looks weird but it saves users gas by making lookup O(1)
            // A.J. Walker's Alias Algorithm
            // sheep aka hoes
            // Accesories
            rarities[0] = [125, 125, 125, 255, 125, 125, 125, 125, 125, 125, 125, 125, 125];
            aliases[0] =  [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13];
            // body
            rarities[1] = [255];
            aliases[1] = [1];
            // clothing
            rarities[2] = [125, 125, 125, 255, 125, 125, 125, 125, 125, 125];
            aliases[2] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
            // earrings
            rarities[3] = [255, 125];
            aliases[3] = [1, 2];
            // footwear
            rarities[4] = [125, 125, 125, 125, 125, 125, 125, 125, 125, 125];
            aliases[4] =  [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
            // hair
            rarities[5] = [125, 125, 125, 125, 125, 125, 125, 125, 125, 125, 125, 125, 125, 125, 125, 125, 125, 125, 125, 125, 125, 125, 125, 125, 255];
            aliases[5] = [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25 ];
            // alphaIndex
            rarities[6] = [125];
            aliases[6] = [0];

            // Pimps

            // Accesories
            rarities[7] =[125, 125, 125, 125, 125, 255, 125, 125, 125, 125, 125];
            aliases[7] = [14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24];
            // body
            rarities[8] = [255];
            aliases[8] = [2];
            // clothing
            rarities[9] =  [125, 125, 125, 125, 125, 225, 100, 125, 244, 125, 125];
            aliases[9] = [11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21];
            // earrings
            rarities[10] = [255];
            aliases[10] = [0];
            // footwear
            rarities[11] = [255];
            aliases[11] = [0];
            // hair
            rarities[12] = [125, 255, 125, 125, 244, 125, 125, 255, 125, 125, 125, 120, 125, 125, 125, 125];
            aliases[12] = [26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41];
            // alphaIndex
            rarities[13] =[125, 125, 125, 125]; 
            aliases[13] = [2, 3, 3, 3];
    }

    /** EXTERNAL */

    /**
     * mint a token - 90% Thief, 10% Polices
     * The first 20% are free to claim, the remaining cost $LOOT
     */
    function mint(uint256 amount, bool stake) external payable nonReentrant whenNotPaused {
        require(tx.origin == _msgSender(), "Only EOA");
        require(minted + amount <= MAX_TOKENS, "All tokens minted");
        require(amount > 0 && amount <= 10, "Invalid mint amount");
        require(whitelistMint || publicMint, "Minting is disabled");

        if (whitelistMint) {
            require(isWhitelisted(tx.origin), "Only whitelisted users can mint");
            require(!(whitelistAddresses[tx.origin] + amount >= 1000), "Not enough tokens in whitelist");
            whitelistAddresses[tx.origin] += amount;
        }

        if (minted < PAID_TOKENS) {
            require(minted + amount <= PAID_TOKENS, "All tokens on-sale already sold");
            require(amount * MINT_PRICE == msg.value, "Invalid payment amount");
        } else {
            require(msg.value == 0);
        }

        uint256 totalLootCost = 0;
        uint16[] memory tokenIds = new uint16[](amount);
        address[] memory owners = new address[](amount);
        uint256 seed;
        uint256 firstMinted = minted;

        for (uint i = 0; i < amount; i++) {
            minted++;
            seed = random(minted);
            generate(minted, seed);
            address recipient = selectRecipient(seed);
            totalLootCost += mintCost(minted);
            if (!stake || recipient != _msgSender()) {
                owners[i] = recipient;
            } else {
                tokenIds[i] = minted;
                owners[i] = address(bank);
            }
        }

        if (totalLootCost > 0) loot.burn(_msgSender(), totalLootCost);


        for (uint i = 0; i < owners.length; i++) {
            uint id = firstMinted + i + 1;
            if (!stake || owners[i] != _msgSender()) {
                _safeMint(owners[i], id);
            }
        }

        if (stake) bank.addManyToBankAndPack(_msgSender(), tokenIds);
    }
    function setMaxMint(uint256 _maxmint) external onlyOwner {
        MAX_MINT = _maxmint;
    }
    /**
     * the first 20% are paid in AVAX
     * the next 20% are 20000 $LOOT
     * the next 40% are 40000 $LOOT
     * the final 20% are 80000 $LOOT
     * @param tokenId the ID to check the cost of to mint
   * @return the cost of the given token ID
   */
    function mintCost(uint256 tokenId) public view returns (uint256) {
        if (tokenId <= PAID_TOKENS) return 0;
        if (tokenId <= MAX_TOKENS * 2 / 5) return 20000 ether;
        if (tokenId <= MAX_TOKENS * 4 / 5) return 40000 ether;
        return 60000 ether;
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

    /** INTERNAL */

    /**
     * generates traits for a specific token, checking to make sure it's unique
     * @param tokenId the id of the token to generate traits for
   * @param seed a pseudorandom 256 bit number to derive traits from
   * @return t - a struct of traits for the given token ID
   */
    function generate(uint256 tokenId, uint256 seed) internal returns (ThiefPolice memory t) {
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
        uint8 trait = uint8(seed) % uint8(rarities[traitType].length);
        return aliases[traitType][trait];
    }

    function isWhitelisted(address _addr) internal view returns (bool) {
        // Check if the key _addr is in the array
        return whitelistAddresses[_addr] >= 0;
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
        address thief = bank.randomPoliceOwner(seed >> 144);
        // 144 bits reserved for trait selection
        if (thief == address(0x0)) return _msgSender();
        return thief;
    }

    /**
     * selects the species and all of its traits based on the seed value
     * @param seed a pseudorandom 256 bit number to derive traits from
   * @return t -  a struct of randomly selected traits
   */
 function selectTraits(uint256 seed) internal view returns (ThiefPolice memory t) {    
    t.isThief = (seed & 0xFFFF) % 10 != 0;
    uint8 shift = t.isThief ? 0 : 7;
    seed >>= 16;
    t.Body = (t.isThief ? 1 : 2);
    seed >>= 16;
    t.clothing = selectTrait(uint16(seed & 0xFFFF), (2 + shift));
    seed >>= 16;
    t.Footwear = selectTrait(uint16(seed & 0xFFFF), (4 + shift));
    seed >>= 16;
    t.Hair = selectTrait(uint16(seed & 0xFFFF), (5 + shift));
    seed >>= 16;
    t.earrings = t.isThief ? selectTrait(uint16(seed & 0xFFFF), 3 + shift) : 0;
    seed >>= 16;
    t.accessories = selectTrait(uint16(seed & 0xFFFF), (0 + shift));
    seed >>= 16;
    t.alphaIndex = selectTrait(uint16(seed & 0xFFFF), (6 + shift));
  }

    /**
     * converts a struct to a 256 bit hash to check for uniqueness
     * @param s the struct to pack into a hash
   * @return the 256 bit hash of the struct
   */
    function structToHash(ThiefPolice memory s) internal pure returns (uint256) {
        return uint256(bytes32(
                abi.encodePacked(
                    s.isThief,
                    s.Body,
                    s.clothing,
                    s.Footwear,
                    s.Hair,
                    s.earrings,
                    s.accessories,
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
            ))) ^ randomSource.seed();
    }

    /** READ */

    function getTokenTraits(uint256 tokenId) external view override returns (ThiefPolice memory) {
        return tokenTraits[tokenId];
    }

    function getPaidTokens() external view override returns (uint256) {
        return PAID_TOKENS;
    }

    /** ADMIN */

    /**
     * called after deployment so that the contract can get random police thieves
     * @param _bank the address of the Bank
   */
    function setBank(address _bank) external onlyOwner {
        bank = IBank(_bank);
    }

    function startPublicMint(bool _publicMint) external onlyOwner {
        publicMint = _publicMint;
    }

    function startWhitelistMint(bool _whitelistMint) external onlyOwner {
        whitelistMint = _whitelistMint;
    }

    // Add a address to the whitelist
    function addToWhitelist(address _addr) external onlyOwner {
        whitelistAddresses[_addr] = 0;
    }

    /**
     * allows owner to withdraw funds from minting
     */
    // function withdraw() external onlyOwner {
    //     payable(owner()).transfer(address(this).balance);
    // }
    

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

    /** RENDER */

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return traits.tokenURI(tokenId);
    }

    function changePrice(uint256 _price) public onlyOwner {
        MINT_PRICE = _price;
    }
}
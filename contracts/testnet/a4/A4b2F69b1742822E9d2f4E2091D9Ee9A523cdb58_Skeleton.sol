// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./Controllable.sol";
import "./Restricted.sol";

import "./IHunter.sol";
import "./IGEM.sol";

import "./MagicForest.sol";
import "./Glow.sol";
import "./Traits.sol";
import "./AttributesPets.sol";
import "./Pets.sol";

contract Skeleton is ERC721Enumerable, Controllable, Pausable, Restricted {

    struct SklRgr {
        bool isAdventurer;
        //for adventurers
        uint8 jacket;
        uint8 hair;
        uint8 backpack;
        //for hunter
        uint8 arm;
        uint8 clothes;
        uint8 mask;
        uint8 weapon;
        uint8 alphaIndex;
        // for everyone
        uint8 level; // 1 (default), 2, 3, 4, 5 (max)
    }

    event Stolen(uint16 indexed tokenId, address indexed from, address indexed to);

    uint256 public constant MINT_PRICE = 2 ether;

    // max number of tokens that can be minted - 50000 in production
    uint256 public MAX_TOKENS = 50000;
    // number of tokens that can be claimed for free - 20% of MAX_TOKENS
    uint256 public PAID_TOKENS = 10000;
    // number of tokens have been minted so far
    uint16 public rangerMinted;
    uint16 public rangerStolen;
    uint16 public skeletonMinted;
    uint16 public skeletonStolen;

    // payment wallets
    address payable AdminWallet = payable(0x9F523A9d191704887Cf667b86d3B6Cd6eBE9D6e9); // TO CHECK
    address payable Multisig = payable(0x49208f9eEAD9416446cdE53435C6271A0235dDA4); // TO CHECK
    address payable devAddress = payable(0xCCf8234c08Cc1D3bF8067216F7b63eeAcb113756); // TO CHECK

    // mapping from tokenId to a struct containing the token's traits
    mapping(uint256 => SklRgr) public tokenTraits;

    struct Order {
        address buyer;
        bool stake;
        uint256 orderBlock;
    }

    // List of all the orders placed
    Order[] public orders;
    // Index of the last order settled
    uint16 public ordersSettled;

    // reference to the magicForest for choosing random Hunter thieves
    MagicForest public magicForest;
    // reference to $GLOW for burning on mint
    Glow public glow;

    Pets pets;

    // to pay the level upgrades
    IGEM public gem = IGEM(address(0x4D3dDeec55f148B3f8765A2aBc00252834ed7E62)); // OK

    // reference to Traits
    Traits public traits;

    IHunter hunter;

    uint256 public constInAdventurers = 10;

    /**
     * instantiates contract and rarity tables
     */
    constructor(address _glow, address _traits) ERC721("Yield Hunt V2", "HGAME2") {
        setGlow(_glow);
        setTraits(_traits);
        _addController(AdminWallet);
    }

    /**
     * Phase 0: pay with 2 avax per NFT
     * Phase >= 1: pay with Glow
     */
    function mint(uint256 amount, bool stake) external payable noReentrency whenNotPaused {

        bool freeMint = isController(_msgSender());

        // Admins can mint through a contract
        require(tx.origin == _msgSender() || freeMint, "Only EOA");

        require(orders.length + amount <= MAX_TOKENS, "All tokens minted");
        require(amount > 0, "Invalid mint amount");
        require(amount <= (freeMint ? 100 : 5), "Max 5 NFTs by transaction");

        if (orders.length + amount <= PAID_TOKENS) {
            require(amount * MINT_PRICE <= msg.value || freeMint);
        } else {
            // paying with GLOW
            require(orders.length >= PAID_TOKENS, "send smaller amont, because it is the transition to gen 1");
            require(
                msg.value == 0,
                "Do not send AVAX, minting is with GLOW now"
            );
            uint256 totalGlowCost = 0;
            for (uint8 i = 0; i < amount; i++) {
                totalGlowCost += mintCost(orders.length + i + 1); // 0 if we are before 10.000
            }

            if (!freeMint) glow.burn(_msgSender(), totalGlowCost);
        }

        uint256 seed = _settleOrders(amount + 1);
        storeMintOrder(_msgSender(), amount, stake, seed);
    }

    function mintWithNFT(uint256[] memory tokenIds, bool stake) external whenNotPaused onlyEOA noReentrency {
        // tokenIds : list of NFT for payment
        // in phase 0, payment can be done in avax (2 avx per mint) or with NFT from original Yield Hunt game
        // 2 AVAX or 10 Adventurers or 1 Hunter (alpha score doesn't matter)

        uint256 nbHunterSent = 0;
        uint256 nbAdventurerSent = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                hunter.ownerOf(tokenIds[i]) == _msgSender(),
                "AINT YOUR TOKEN"
            );
            // requires to have approved this contract in ERC721

            hunter.transferFrom(_msgSender(), address(this), tokenIds[i]);
            IHunter.AvtHtr memory nft = hunter.getTokenTraits(tokenIds[i]);
            if (nft.isAdventurer) {
                nbAdventurerSent++;
            } else {
                nbHunterSent++;
            }
        }

        require(
            nbAdventurerSent % constInAdventurers == 0,
            "Invalid number of adventurers sent"
        );

        uint256 amount = nbHunterSent + nbAdventurerSent / constInAdventurers;

        require(amount > 0, "Send some NFTs dude");
        require(amount <= 5, "Max 5 NFTs by transaction");
        require(
            orders.length + amount <= PAID_TOKENS,
            "All tokens on-sale already sold"
        );

        uint256 seed = _settleOrders(amount + 1);
        storeMintOrder(_msgSender(), amount, stake, seed);
    }

    function storeMintOrder(address buyer, uint256 amount, bool stake, uint256 seed) private {
        withdrawMoney();

        AttributesPets.Boost memory boostWallet = pets.getBoostWallet(_msgSender());

        for (uint256 i = 0; i < amount; i++) {
            orders.push(Order(buyer, stake, block.number));

            if(boostWallet.reMintProbabilityAugmentation > 0 && uint256(keccak256(abi.encodePacked(seed, i))) % 100 < boostWallet.reMintProbabilityAugmentation){
                orders.push(Order(buyer, stake, block.number));
            }
        }
    }

   function _settleOrders(uint256 amount) internal returns(uint256 seed) {
        uint256 initialOrdersSettled = ordersSettled;
        while (ordersSettled - initialOrdersSettled < amount && ordersSettled < orders.length) {
            Order memory order = orders[ordersSettled];

            // Can't generate in the same block as the order
            if (order.orderBlock >= block.number) {
                break;
            }

            ordersSettled++;
            seed = core_mint(order);
            
        }
        seed = renewSeed(seed);
    }

     function settleOrders(uint256 amount) external whenNotPaused onlyEOA noReentrency {
        _settleOrders(amount);
    }



    function core_mint(Order memory order) internal returns(uint256){
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    uint256(blockhash(order.orderBlock)),
                    ordersSettled
                )
            )
        );

        seed = generate(seed);
        address recipient = selectRecipient(order, seed);
        if (recipient != order.buyer) emit Stolen(ordersSettled, order.buyer, recipient);

        if (tokenTraits[ordersSettled].isAdventurer) {
            rangerMinted++;
            if (recipient != order.buyer) rangerStolen++;
        } else {
            skeletonMinted++;
            if (recipient != order.buyer) skeletonStolen++;
        }

        if (!order.stake || recipient != order.buyer) {
            _safeMint(recipient, ordersSettled);
        } else {
            magicForest.addToBarnAndPack(recipient, ordersSettled);
        }

        return seed;
    }

    /**
     * the first 20% are paid in AVAX
     * the next 20% are 20000 $
     * the next 40% are 40000 $GLOW
     * the final 20% are 80000 $GLOW
     * @param tokenId the ID to check the cost of to mint
     * @return the cost of the given token ID
     */
    function mintCost(uint256 tokenId) public view returns (uint256) {
        if (tokenId <= PAID_TOKENS) return 0;
        if (tokenId <= (MAX_TOKENS * 2) / 5) return 20000 ether;
        if (tokenId <= (MAX_TOKENS * 4) / 5) return 40000 ether;
        return 80000 ether;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        // Hardcode the magicForest's approval so that users don't have to waste gas approving
        if (_msgSender() != address(magicForest))
            require(
                _isApprovedOrOwner(_msgSender(), tokenId),
                "ERC721: transfer caller is not owner nor approved"
            );
        _transfer(from, to, tokenId);
    }

    /** INTERNAL */

    /**
     * generates traits for the next token
     * @param seed a pseudorandom 256 bit number to derive traits from
     * @return t - a struct of traits for he next token
     */
    function generate(uint256 seed) internal returns (uint256)
    {
        SklRgr memory t;
        t = selectBody(seed);
        seed = renewSeed(seed);
        t = selectTraits(seed, t);
        tokenTraits[ordersSettled] = t;
        seed = renewSeed(seed);
        return seed;
    }

    function renewSeed(uint256 old) internal view returns(uint256 seed){
        seed = uint256(keccak256(abi.encodePacked(old, block.timestamp, ordersSettled)));
    }

    function upgradeLevel(uint256 tokenId) external onlyEOA noReentrency {
        require(ownerOf(tokenId) == _msgSender(), "AINT YOUR TOKEN");
        SklRgr memory nft = tokenTraits[tokenId];
        require(nft.level < 5, "already at max level (level 5)");
        uint256 gemPrice;
        if (nft.isAdventurer) {
            gemPrice = 20000 ether * nft.level;
        } else {
            if (nft.level == 1) {
                gemPrice = 50000 ether;
            } else if (nft.level == 2) {
                gemPrice = 75000 ether;
            } else if (nft.level == 3) {
                gemPrice = 100000 ether;
            } else {
                gemPrice = 200000 ether;
            }
        }

        gem.burn(_msgSender(), gemPrice);
        nft.level++;
        tokenTraits[tokenId] = nft;
    }


    function isStolen(uint256 seed) internal view returns(bool){
        //returns true if adventurer
        AttributesPets.Boost memory boostWallet = pets.getBoostWallet(msg.sender); 
        uint256 treshold = 10 + boostWallet.stolenProbabilityAugmentation - boostWallet.stolenProbabilityReduction;
        return seed % 100 < treshold;
    }
    /**
     * the first 20% (AVAX purchases) go to the minter
     * the remaining 80% have a 10% chance to be given to a random staked adventurer
     * @param seed a random value to select a recipient from
     * @return the address of the recipient (either the minter or the adventurer thief's owner)
     */
    function selectRecipient(Order memory order, uint256 seed) internal view returns (address) {
        if (ordersSettled <= PAID_TOKENS || !isStolen(seed >> 245))
            return order.buyer; // top 10 bits haven't been used
        address thief = magicForest.randomHunterOwner(seed >> 144); // 144 bits reserved for trait selection
        if (thief == address(0x0)) return order.buyer;
        return thief;
    }

    function randomBody(uint256 seed) internal view returns(bool){
        //returns true if adventurer
        AttributesPets.Boost memory boostWallet = pets.getBoostWallet(msg.sender); 
        uint256 treshold = 10 + boostWallet.skeletonProbabilityAugmentation - boostWallet.skeletonProbabilityReduction;
        return (seed & 0xFFFF) % 100 >= treshold;
    }

    /**
     * selects the species and all of its traits based on the seed value
     * @param seed a pseudorandom 256 bit number to derive traits from
     * @return t -  a struct of randomly selected traits
     */

    function selectBody(uint256 seed)
        internal
        view
        returns (SklRgr memory t)
    {
        t.isAdventurer = randomBody(seed);

        if (!t.isAdventurer) {
            seed >>= 16;
            t.alphaIndex = traits.selectTrait(uint16(seed & 0xFFFF), 7);
        }
        t.level = 1; // default level is 1
    }


    function selectTraits(uint256 _seed, SklRgr memory old) internal view returns (SklRgr memory t) {
        uint256 seed = _seed;

        t = old;

        if (t.isAdventurer) {
            seed >>= 16;
            t.jacket = traits.selectTrait(uint16(seed & 0xFFFF), 0);
            seed >>= 16;
            t.hair = traits.selectTrait(uint16(seed & 0xFFFF), 1);
            seed >>= 16;
            t.backpack = traits.selectTrait(uint16(seed & 0xFFFF), 2);
        } else {
            seed >>= 16;
            t.arm = traits.selectTrait(uint16(seed & 0xFFFF), 3);
            seed >>= 16;
            t.clothes = traits.selectTrait(uint16(seed & 0xFFFF), 4);
            seed >>= 16;
            t.mask = traits.selectTrait(uint16(seed & 0xFFFF), 5);
            seed >>= 16;
            t.weapon = traits.selectTrait(uint16(seed & 0xFFFF), 6);
        }
    }

    /** READ */

    function getTokenTraits(uint256 tokenId) external view returns (SklRgr memory) {
        return tokenTraits[tokenId];
    }

    /** RENDER */

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return traits.tokenURI(tokenId);
    }

    function getPaidTokens() external view returns (uint256) {
        return PAID_TOKENS;
    }

    /**
     * allows owner to withdraw funds from minting
     */
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdrawMoney() internal {
        devAddress.transfer((getBalance()*5)/100);
        Multisig.call{value: getBalance(), gas: 100000}("");
    }

    function withdrawToOwner() external onlyController {
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * updates the number of tokens for sale
     */
    function setPaidTokens(uint256 _paidTokens) external onlyController {
        PAID_TOKENS = _paidTokens;
    }
    /**
     * enables owner to pause / unpause minting
     */
    function setPaused(bool _paused) external onlyController {
        if (_paused) _pause();
        else _unpause();
    }

    function setconstInAdventurers(uint256 _constInAdventurers) external onlyController {
        constInAdventurers = _constInAdventurers;
    }

    function setPets(address _pets) public onlyController{
        pets = Pets(_pets);
    }

    function setMagicForest(address _magicForest) public onlyController {
        magicForest = MagicForest(_magicForest);
    }

    function setTraits(address _traits) public onlyController {
        traits = Traits(_traits);
    }

    function setGlow(address _glow) public onlyController {
        glow = Glow(_glow);
    }

    function setHunter(address _hunter) public onlyController {
        hunter = IHunter(_hunter);
    }

    function setMaxTokens(uint256 _MAX_TOKENS) public onlyController {
        MAX_TOKENS = _MAX_TOKENS;
        PAID_TOKENS = MAX_TOKENS / 5;
    }
}
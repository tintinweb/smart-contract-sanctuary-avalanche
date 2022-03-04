// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./Restricted.sol";

import "./IHunter.sol";
import "./IGEM.sol";

import "./MagicForest.sol";
import "./Glow.sol";
import "./Traits.sol";
import "./AttributesPets.sol";
import "./Pets.sol";

contract Skeleton is ERC721Enumerable, Pausable, Restricted {
    struct SklRgr {
        //for both
        bool isRanger;
        uint8 level; // 1 (default), 2, 3, 4, 5 (max)
        uint8 arm; 
        uint8 head;

        //for rangers
        uint8 body;
        uint8 gadget;

        //for skeletons
        uint8 torso;
        uint8 legs;
        uint8 alphaIndex;
    }

    event Stolen(uint16 indexed tokenId, address indexed from, address indexed to);
    event onOrderPlaced(address indexed buyer, uint8 amount);
    event onOrderSettled(address indexed buyer, uint256 indexed tokenId);

    uint256 public constant MINT_PRICE = 20 wei; // 2 ether for real launch <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

    // Max number of tokens that can be minted - 50000 in production
    uint256 public MAX_TOKENS = 50000;
    // Number of tokens that can be claimed for free - 20% of MAX_TOKENS
    uint256 public PAID_TOKENS = 10000;
    
    uint16 public rangerMinted;
    uint16 public rangerStolen;
    uint16 public skeletonMinted;
    uint16 public skeletonStolen;

    // Payment wallets
    address payable AdminWallet = payable(0x9F523A9d191704887Cf667b86d3B6Cd6eBE9D6e9); // TO CHECK
    address payable Multisig = payable(0x49208f9eEAD9416446cdE53435C6271A0235dDA4); // TO CHECK
    address payable devAddress = payable(0xCCf8234c08Cc1D3bF8067216F7b63eeAcb113756); // TO CHECK

    // Mapping from tokenId to a struct containing the token's traits
    mapping(uint256 => SklRgr) public tokenTraits;

    struct Order {
        address buyer;
        uint256 orderBlock;
    }

    // List of all the orders placed
    Order[] public orders;
    // Index of the last order settled
    uint16 public ordersSettled;

    Glow public glow;
    Traits public traits;
    MagicForest public magicForest;
    Pets public pets;

    IGEM public gem = IGEM(address(0x4D3dDeec55f148B3f8765A2aBc00252834ed7E62));
    IHunter public hunter = IHunter(address(0xEaB33F781aDA4ee7E91fD63ad87C5Bb47FFb8a83));

    uint8 public costInAdventurers = 10;
    uint8 public costInHunters = 1;

    uint256 private baseRangerUpgradePrice = 20000 ether;
    uint256[4] private skeletonUpgradePricesByLevel = [50000 ether, 75000 ether, 100000 ether, 200000 ether];

    uint8[6] private alphaRarities = [42, 25, 15, 10, 5, 3];

    constructor(address _glow, address _traits) ERC721("Yield Hunt V2", "HGAME2") {
        setGlow(_glow);
        setTraits(_traits);
        _addController(AdminWallet);
    }

    /**
     * Main function to mint a Skeleton / Ranger
     * Costs : 
     * | Gen 0 - 2 AVAX       (ids     1 -> 10000)
     * | Gen 1 - 20000 $GLOW  (ids 10001 -> 20000)
     * |         40000 $GLOW  (ids 20001 -> 40000)
     * |         80000 $GLOW  (ids 40001 -> 50000)
     * @param amount Number of NFTs to mint, limited to 5 for non admins
     */
    function mint(uint8 amount)
        external
        payable
        whenNotPaused
        onlyEOAor(isController(_msgSender()))
        noReentrency
        notBlacklisted
    {
        bool adminsMint = isController(_msgSender());

        require(orders.length + amount <= MAX_TOKENS, "All tokens minted");
        require(amount > 0,                           "Invalid mint amount");
        require(amount <= (adminsMint ? 100 : 5),     "Max 5 NFTs by transaction");

        if (orders.length + amount <= PAID_TOKENS) {
            require(amount * MINT_PRICE <= msg.value || adminsMint);
        } else {
            // Paying with $GLOW
            require(
                orders.length >= PAID_TOKENS,
                "Send a smaller amount, because it is the transition to gen 1"
            );
            require(
                msg.value == 0,
                "Do not send AVAX, minting is with $GLOW now"
            );
            uint256 totalGlowCost = 0;
            for (uint8 i = 0; i < amount; i++) {
                totalGlowCost += mintCost(orders.length + i + 1); // 0 if we are before 10.000
            }

            if (!adminsMint) glow.burn(_msgSender(), totalGlowCost);
        }

        uint256 seed = _settleOrders(amount + 1);
        emit onOrderPlaced(_msgSender(), amount);
        _storeMintOrder(_msgSender(), amount, seed);
    }

    /**
     * Alternative function to mint Gen 0 Skeletons / Rangers with Adventurers / Hunters tokens
     * Costs : 10 Adventurers or 1 Hunter (alpha index doesn't matter)
     * Exemple : 20 Adventurers and 2 Hunters gives 4 tokens
     * You can't mint more than 5 tokens by transaction
     * @param tokenIds Adventurers / Hunters ids for payment
     */
    function mintWithNFT(uint256[] calldata tokenIds) 
        external
        payable
        whenNotPaused
        onlyEOA
        noReentrency
        notBlacklisted
    {
        uint8 nbAdventurerSent = 0;
        uint8 nbHunterSent = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                hunter.ownerOf(tokenIds[i]) == _msgSender(),
                "Not your token"
            );
            // requires to have approved this contract in ERC721

            hunter.transferFrom(_msgSender(), address(this), tokenIds[i]);
            IHunter.AvtHtr memory advhtr = hunter.getTokenTraits(tokenIds[i]);
            if (advhtr.isAdventurer) {
                require(nbAdventurerSent < type(uint8).max, "Too many adventurers sent");
                nbAdventurerSent++;
            } else {
                require(nbHunterSent < type(uint8).max, "Too many hunters sent");
                nbHunterSent++;
            }
        }

        require(
            nbAdventurerSent % costInAdventurers == 0,
            "Invalid number of adventurers sent"
        );

        require(
            nbHunterSent % costInHunters == 0,
            "Invalid number of hunters sent"
        );

        uint8 amount = nbHunterSent / costInHunters + nbAdventurerSent / costInAdventurers;

        require(amount > 0, "You need to send some NFTs");
        require(amount <= 5, "Max 5 mints by transaction");
        require(orders.length + amount <= PAID_TOKENS, "All tokens on-sale already sold");

        uint256 seed = _settleOrders(amount + 1);
        emit onOrderPlaced(_msgSender(), amount);
        _storeMintOrder(_msgSender(), amount, seed);
    }

    /**
     * Settles the orders in the queue
     * Useful when there is not a lot of mints, or when the order queue is too long
     * @param amount Number of orders to settle
     */
    function settleOrders(uint8 amount)
        external
        whenNotPaused
        onlyEOA
        noReentrency
        notBlacklisted
    {
        _settleOrders(amount);
    }

    /**
     * Upgrades the level the tokens by one
     * @param tokenIds Ids of the tokens to upgrade
     */
    function upgradeLevel(uint256[] calldata tokenIds)
        external
        whenNotPaused
        onlyEOA
        noReentrency
        notBlacklisted
    {
        uint256 gemPrice;
        for (uint8 i = 0; i < tokenIds.length; i++) {
            require(ownerOf(tokenIds[i]) == _msgSender(), "Not your token");
            require(tokenTraits[tokenIds[i]].level < 5, "Already at max level (level 5)");
            gemPrice += tokenTraits[tokenIds[i]].isRanger ? 
                baseRangerUpgradePrice * tokenTraits[tokenIds[i]].level :
                skeletonUpgradePricesByLevel[tokenTraits[tokenIds[i]].level - 1];

            tokenTraits[tokenIds[i]].level++;
        }
        gem.burn(_msgSender(), gemPrice);
    }

    /* INTERNAL */

    function _storeMintOrder(address buyer, uint256 amount, uint256 seed) internal {
        withdrawMoney();

        AttributesPets.Boost memory boostWallet = pets.getWalletBoost(buyer);

        for (uint256 i = 0; i < amount; i++) {
            orders.push(Order(buyer, block.number));

            if (
                boostWallet.reMintProbabilityAugmentation > 0 &&
                uint256(keccak256(abi.encodePacked(seed, i))) % 100 <
                boostWallet.reMintProbabilityAugmentation
            ) {
                orders.push(Order(buyer, block.number));
            }
        }
    }

    function _settleOrders(uint8 amount) internal returns (uint256 seed) {
        uint256 initialOrdersSettled = ordersSettled;
        while (
            ordersSettled - initialOrdersSettled < amount &&
            ordersSettled < orders.length
        ) {
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

    function core_mint(Order memory order) internal returns (uint256){
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
        emit onOrderSettled(order.buyer, ordersSettled);

        if (tokenTraits[ordersSettled].isRanger) {
            rangerMinted++;
            if (recipient != order.buyer) rangerStolen++;
        } else {
            skeletonMinted++;
            if (recipient != order.buyer) skeletonStolen++;
        }

        _safeMint(recipient, ordersSettled);
        return seed;
    }

    function generate(uint256 seed) internal returns (uint256) {
        SklRgr memory t;
        t = selectBody(seed);
        seed = renewSeed(seed);
        tokenTraits[ordersSettled] = selectTraits(seed, t);
        return renewSeed(seed);
    }

    function renewSeed(uint256 old) internal view returns (uint256 seed) {
        seed = uint256(
            keccak256(abi.encodePacked(old, block.timestamp, ordersSettled))
        );
    }

    /**
     * @param seed Pseudorandom number
     * @return If the token is stolen
     */
    function isStolen(uint256 seed) internal view returns(bool) {
        AttributesPets.Boost memory boostWallet = pets.getWalletBoost(_msgSender());
        uint256 treshold = 10 +
            boostWallet.stolenProbabilityAugmentation -
            boostWallet.stolenProbabilityReduction;
        return seed % 100 < treshold;
    }

    /**
     * the first 20% (AVAX purchases) go to the minter
     * the remaining 80% have a 10% chance to be given to a random staked adventurer
     * @param seed a random value to select a recipient from
     * @return the address of the recipient (either the minter or the adventurer thief's owner)
     */
    function selectRecipient(Order memory order, uint256 seed) internal view returns(address) {
        if (ordersSettled <= PAID_TOKENS || !isStolen(seed >> 245))
            return order.buyer; // top 10 bits haven't been used
        address thief = magicForest.randomSkeletonOwner(seed >> 144); // 144 bits reserved for trait selection
        if (thief == address(0x0)) return order.buyer;
        return thief;
    }

    function randomBody(uint256 seed) internal view returns(bool){
        AttributesPets.Boost memory boostWallet = pets.getWalletBoost(_msgSender()); 
        uint256 treshold = 10 + boostWallet.skeletonProbabilityAugmentation - boostWallet.skeletonProbabilityReduction;
        return (seed & 0xFFFF) % 100 >= treshold;
    }

    /**
     * selects the species and all of its traits based on the seed value
     * @param seed a pseudorandom 256 bit number to derive traits from
     * @return t -  a struct of randomly selected traits
     */
    function selectBody(uint256 seed) internal view returns (SklRgr memory t) {
        t.isRanger = randomBody(seed);
        if (!t.isRanger) t.alphaIndex = selectAlpha(seed >> 16);
        t.level = 1;
    }

    function selectAlpha(uint256 seed) internal view returns (uint8) {
        uint256 m = seed % 100;
        uint8 probabilitySum;
        for (uint8 i = 10; i >= 5; i--) {
            probabilitySum += alphaRarities[i - 5];
            if (m < probabilitySum) return i;
        }
        return 5;
    }

    function selectTraits(uint256 seed, SklRgr memory old) internal view returns (SklRgr memory t) {
        t = old;

        if (t.isRanger) {
            (t.arm, t.head, t.body, t.gadget) = traits.selectRangerTraits(seed);
        } else {
            (t.arm, t.head, t.torso, t.legs) = traits.selectSkeletonTraits(seed);
        }
    }

    /* TOKEN TRANSFERS */

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721, IERC721) {
        // Hardcode the magicForest's approval so that users don't have to waste gas approving
        if (_msgSender() != address(magicForest))
            require(
                _isApprovedOrOwner(_msgSender(), tokenId),
                "ERC721: transfer caller is not owner nor approved"
            );
        _transfer(from, to, tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenId);
        if (tokenTraits[tokenId].isRanger &&  to != address(magicForest) && from != address(magicForest)) {
            pets.beforeRangerTransfer(from, to, tokenId);
        }
    }

    /** READ */

    /**
     * The first 20% are paid in AVAX
     * The next 20% are 20000 $
     * The next 40% are 40000 $GLOW
     * The final 20% are 80000 $GLOW
     * @param tokenId the ID to check the cost of to mint
     * @return the cost of the given token ID
     */
    function mintCost(uint256 tokenId) public view returns (uint256) {
        if (tokenId <= PAID_TOKENS) return 0;
        if (tokenId <= (MAX_TOKENS * 2) / 5) return 20000 ether;
        if (tokenId <= (MAX_TOKENS * 4) / 5) return 40000 ether;
        return 80000 ether;
    }

    function getTokenTraits(uint256 tokenId) external view returns(SklRgr memory) {
        return tokenTraits[tokenId];
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /** RENDER */

    function tokenURI(uint256 tokenId) public view override returns(string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return traits.tokenURI(tokenId);
    }

    function getPaidTokens() external view returns (uint256) {
        return PAID_TOKENS;
    }
    

    /* MONEY TRANSFERS */

    function withdrawMoney() internal {
        devAddress.transfer((getBalance() * 5) / 100);
        Multisig.call{value: getBalance(), gas: 100000}("");
    }

    function withdrawToOwner() external onlyController {
        payable(owner()).transfer(address(this).balance);
    }

    /* GAME MANAGEMENT */

    function setPaused(bool _paused) external onlyController {
        if (_paused) _pause();
        else _unpause();
    }

    /* VALUES SETTERS */

    function setMaxTokens(uint256 _MAX_TOKENS) public onlyController {
        MAX_TOKENS = _MAX_TOKENS;
        PAID_TOKENS = MAX_TOKENS / 5;
    }

    function setPaidTokens(uint256 _paidTokens) external onlyController {
        PAID_TOKENS = _paidTokens;
    }

    function setCostInAdventurers(uint8 _costInAdventurers) external onlyController {
        costInAdventurers = _costInAdventurers;
    }

    function setCostInHunters(uint8 _costInHunters) external onlyController {
        costInHunters = _costInHunters;
    }

    /* ADDRESSES SETTERS */

    function setGem(address _gem) public onlyController {
        gem = IGEM(_gem);
    }

    function getNumberOfOrders() public view returns(uint256){
        return orders.length;
    }

    function setHunter(address _hunter) public onlyController {
        hunter = IHunter(_hunter);
    }

    function setGlow(address _glow) public onlyController {
        glow = Glow(_glow);
    }

    function setTraits(address _traits) public onlyController {
        traits = Traits(_traits);
    }

    function setMagicForest(address _magicForest) public onlyController {
        magicForest = MagicForest(_magicForest);
    }

    function setPets(address _pets) public onlyController {
        pets = Pets(_pets);
    }
}
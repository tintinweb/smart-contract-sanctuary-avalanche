// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./Restricted.sol";

import "./IGEM.sol";
import "./IHunter.sol";

import "./Glow.sol";
import "./Traits.sol";
import "./MagicForest.sol";
import "./Pets.sol";

contract Skeleton is ERC721Enumerable, Pausable, Restricted {
    struct SklRgr {
        // for both
        bool isRanger;
        uint8 level; // 1 (default), 2, 3, 4, 5 (max)
        uint8 arm; 
        uint8 head;

        // for rangers
        uint8 body;
        uint8 gadget;

        // for skeletons
        uint8 torso;
        uint8 legs;
        uint8 alphaIndex;
    }

    event LevelUp(uint256 indexed tokenId, uint256 level);
    event OrderPlaced(address indexed buyer, uint256 indexed orderNumber);
    event OrderSettled(address indexed buyer, uint256 indexed orderNumber, bool stolen);
    event SneakyOrderPlaced(address indexed buyer, uint256 indexed sneakyOrderNumber);
    event SneakyOrderSettled(address indexed buyer, uint256 indexed sneakyOrderNumber, bool success);
    
    uint16 public rangerMinted;
    uint16 public rangerStolen;
    uint16 public skeletonMinted;
    uint16 public skeletonStolen;

    address payable adminAddress = payable(0x9F523A9d191704887Cf667b86d3B6Cd6eBE9D6e9);
    address payable devAddress = payable(0x8888888b6d3275A560B0d4139210206E3cA4Ab62);

    mapping(uint256 => SklRgr) public tokenTraits;

    struct Order {
        address buyer;
        uint256 orderBlock;
        uint8 skeletonProbability;
        uint8 stolenProbability;
    }

    struct SneakyOrder {
        address buyer;
        uint256 orderBlock;
    }

    Order[] public orders;
    SneakyOrder[] public sneakyOrders;

    uint16 public ordersSettled;
    uint16 public sneakyOrdersSettled;

    struct State {
        bool normalMint;
        bool burnMint;
        bool sneakyMint;
        bool burnSneakyMint;
    }

    State public state;

    uint16[5] private generationsTresholds = [10000, 20000, 30000, 40000, 50000];
    uint256[5] private generationsPriceAVAX = [2 ether, 0, 0, 0, 0];
    uint256[5] private generationsPriceGLOW = [0, 20000 ether, 40000 ether, 60000 ether, 80000 ether];

    uint256 private sneakyMintPriceAVAX = 0.2 ether;
    uint256 private sneakyMintPriceGLOW;

    IGEM    public gem    = IGEM(address(0x4D3dDeec55f148B3f8765A2aBc00252834ed7E62));
    IHunter public hunter = IHunter(address(0xEaB33F781aDA4ee7E91fD63ad87C5Bb47FFb8a83));

    Glow        public glow;
    Traits      public traits;
    MagicForest public magicForest;
    Pets        public pets;

    uint8 public costInAdventurers = 10;
    uint8 public costInHunters = 1;

    uint256 private baseRangerUpgradePrice = 20000 ether;
    uint256[4] private skeletonUpgradePricesByLevel = [50000 ether, 75000 ether, 100000 ether, 200000 ether];

    uint8[6] private alphaRarities = [42, 25, 15, 10, 5, 3];

    constructor(address _glow, address _traits) ERC721("Yield Hunt Chapter 2", "Yield Hunt Chapter 2") { 
        setGlow(_glow);
        setTraits(_traits);
        _addController(adminAddress);
    }

    /**
     * Main function to mint a Skeleton / Ranger
     * Costs : 
     * | Gen 0 - 2 AVAX       (ids     1 -> 10000)
     * | Gen 1 - 20000 $GLOW  (ids 10001 -> 20000)
     * |         40000 $GLOW  (ids 20001 -> 30000)
     * |         60000 $GLOW  (ids 30001 -> 40000)
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
        require(state.normalMint, "Mint is disabled");
        bool adminMint = isController(_msgSender());

        require(orders.length + amount <= generationsTresholds[4], "All tokens minted");
        require(amount > 0,                                        "Invalid mint amount");
        require(amount <= (adminMint ? 100 : 5),                   "Max 5 NFTs by transaction");

        uint256 totalAvaxPrice;
        uint256 totalGlowPrice;
        uint256 avaxPrice;
        uint256 glowPrice;

        for (uint256 i = 1; i <= amount;) {
            (avaxPrice, glowPrice) = mintCost(orders.length + i);
            totalAvaxPrice += avaxPrice;
            totalGlowPrice += glowPrice;
            unchecked{++i;}
        }

        require(
            totalAvaxPrice == msg.value || adminMint,
            "Wrong AVAX value sent"
        );

        if (totalGlowPrice > 0 && !adminMint) {
            glow.burn(_msgSender(), totalGlowPrice);
        }

        _manageOrders(amount + 1, amount, _msgSender());
    }

    /**
     * Alternative function to mint Skeletons / Rangers with Adventurers / Hunters tokens
     * Costs : 10 Adventurers or 1 Hunter (alpha index doesn't matter)
     * Exemple : 20 Adventurers and 2 Hunters gives 4 tokens
     * You can't mint more than 5 tokens by transaction
     * @param tokenIds Adventurers / Hunters ids for payment
     */
    function mintWithNFT(uint256[] calldata tokenIds) 
        external
        whenNotPaused
        onlyEOA
        noReentrency
        notBlacklisted
    {
        require(state.burnMint, "Mint with NFT is disabled");
        uint256 nbAdventurerSent;
        uint256 nbHunterSent;

        for (uint256 i; i < tokenIds.length;) {
            require(hunter.ownerOf(tokenIds[i]) == _msgSender(), "Not your token");

            // Requires to have approved this contract in ERC721
            hunter.transferFrom(_msgSender(), address(this), tokenIds[i]);
            IHunter.AvtHtr memory advhtr = hunter.getTokenTraits(tokenIds[i]);
            unchecked{
                if (advhtr.isAdventurer) {
                    ++nbAdventurerSent;
                } else {
                    ++nbHunterSent;
                }
                ++i;
            }
        }

        require(nbAdventurerSent % costInAdventurers == 0, "Invalid number of adventurers sent");
        require(nbHunterSent % costInHunters == 0,         "Invalid number of hunters sent");

        uint256 amount = (nbHunterSent / costInHunters) + (nbAdventurerSent / costInAdventurers);

        require(amount > 0,  "You need to send some NFTs");
        require(amount <= 5, "Max 5 mints by transaction");
        
        require(orders.length + amount <= generationsTresholds[4], "All tokens minted");

        _manageOrders(amount + 1, amount, _msgSender());
    }

    /**
     * Function to sneaky mint Skeletons / Rangers
     * You can't initiate more than 5 sneaky mints per transaction
     * @param amount Number of sneaky mints to initiate
     */
    function sneakyMint(uint8 amount) 
        external
        payable
        whenNotPaused
        onlyEOAor(isController(_msgSender()))
        noReentrency
        notBlacklisted
    {
        require(state.sneakyMint, "Sneaky mint is disabled");
        require(
            orders.length + amount + (sneakyOrders.length - sneakyOrdersSettled) <= generationsTresholds[4],
            "All tokens minted"
        );
        require(amount > 0,  "You need to send at least one adventurer");
        require(amount <= 5, "5 sneaky mints by transaction maximum");

        (uint256 avaxPrice, uint256 glowPrice) = sneakyMintCost();

        require(
            avaxPrice * amount == msg.value,
            "Wrong AVAX value sent"
        );

        if (glowPrice > 0) {
            glow.burn(_msgSender(), glowPrice * amount);
        }

        _manageSneakyOrders(amount + 1, amount, _msgSender());
    }

    /**
     * Alternative function to sneaky mint Skeletons / Rangers with Adventurers
     * Costs : 1 Adventurers 
     * You can't initiate more than 5 sneaky mints per transaction
     * @param tokenIds Adventurers / Hunters ids for payment
     */
    function sneakyMintWithNFT(uint256[] calldata tokenIds) 
        external
        whenNotPaused
        onlyEOA
        noReentrency
        notBlacklisted
    {
        require(state.burnSneakyMint, "Sneaky mint with NFT is disabled");
        require(
            orders.length + tokenIds.length + (sneakyOrders.length - sneakyOrdersSettled) <= generationsTresholds[4],
            "All tokens minted"
        );
        require(tokenIds.length > 0,  "You need to send at least one adventurer");
        require(tokenIds.length <= 5, "5 sneaky mints by transaction maximum");

        for (uint256 i; i < tokenIds.length;) {
            require(hunter.ownerOf(tokenIds[i]) == _msgSender(),     "Not your token");
            require(hunter.getTokenTraits(tokenIds[i]).isAdventurer, "Sneaky mint can only be performed by adventurers");

            // Requires to have approved this contract in ERC721
            hunter.transferFrom(_msgSender(), address(this), tokenIds[i]);
            unchecked{++i;}
        }

        _manageSneakyOrders(tokenIds.length + 1, tokenIds.length, _msgSender());
    }

    /**
     * Settles the orders in the queue
     * Useful when there is not a lot of mints, or when the order queue is too long
     * @param amount Number of orders to settle
     * @param sneaky To settle sneaky or normal mints
     */
    function settleOrders(uint8 amount, bool sneaky)
        external
        whenNotPaused
        onlyEOA
        noReentrency
        notBlacklisted
    {
        sneaky ? _manageSneakyOrders(amount, 0, address(0x0)) : _manageOrders(amount, 0, address(0x0));
    }

    /**
     * Upgrades the level the tokens by one level
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
        address tokenOwner;
        for (uint256 i; i < tokenIds.length;) {
            gemPrice += upgradeCost(tokenIds[i]);
            tokenOwner = ownerOf(tokenIds[i]);
            require(tokenTraits[tokenIds[i]].level < 5, "Already at max level (level 5)");
            if (tokenOwner == address(magicForest) && magicForest.getStaker(tokenIds[i]) == _msgSender()) {
                magicForest.beforeUpgradeLevel(uint16(tokenIds[i]));
            } else {
                require(tokenOwner == _msgSender(), "Not your token");
            }
            
            emit LevelUp(tokenIds[i], ++tokenTraits[tokenIds[i]].level);
            unchecked{++i;}
        }
        gem.burn(_msgSender(), gemPrice);
    }

    /* INTERNAL */

    function _manageOrders(uint256 amountToSettle, uint256 amountToPlace, address buyer) internal {
        // 1) Settle old orders
        uint256 seed;
        uint256 initialOrdersSettled = ordersSettled;
        while (
            ordersSettled - initialOrdersSettled < amountToSettle &&
            ordersSettled < orders.length
        ) {
            Order memory order = orders[ordersSettled];

            // Can't generate in the same block as the order
            if (order.orderBlock >= block.number) {
                break;
            }
            
            seed = core_mint(order);
        }
        seed = renewSeed(seed);

        // 2) Place new orders
        if (amountToPlace > 0) {

            AttributesPets.Boost memory walletBoost = pets.getWalletBoost(buyer);

            uint8 skeletonProbability = 
                10
                + walletBoost.skeletonProbabilityAugmentation
                - walletBoost.skeletonProbabilityReduction;
            uint8 stolenProbability =
                10
                + walletBoost.stolenProbabilityAugmentation
                - walletBoost.stolenProbabilityReduction;
            
            if (orders.length < generationsTresholds[0]) stolenProbability = 0;

            for (uint256 i; i < amountToPlace;) {
                orders.push(Order(buyer, block.number, skeletonProbability, stolenProbability));
                emit OrderPlaced(buyer, orders.length);

                if (uint256(keccak256(abi.encodePacked(seed, i))) % 100 < walletBoost.reMintProbabilityAugmentation ) {
                    orders.push(Order(buyer, block.number, skeletonProbability, stolenProbability));
                    emit OrderPlaced(buyer, orders.length);
                }

                unchecked{++i;}
            }
        }
    }

    function _manageSneakyOrders(uint256 amountToSettle, uint256 amountToPlace, address buyer) internal {
        // 1) Settle old sneaky orders
        uint256 initialSneakyOrdersSettled = sneakyOrdersSettled;
        while (
            sneakyOrdersSettled - initialSneakyOrdersSettled < amountToSettle &&
            sneakyOrdersSettled < sneakyOrders.length
        ) {
            SneakyOrder memory sneakyOrder = sneakyOrders[sneakyOrdersSettled];

            // Can't generate in the same block as the order
            if (sneakyOrder.orderBlock >= block.number) {
                break;
            }
            
            bool success = uint256(
                keccak256(
                    abi.encodePacked(
                        uint256(blockhash(sneakyOrder.orderBlock)),
                        sneakyOrdersSettled
                    )
                )
            ) % 100 < 10;
            if (success) _manageOrders(1, 1, sneakyOrder.buyer);
            unchecked{sneakyOrdersSettled++;}
            emit SneakyOrderSettled(sneakyOrder.buyer, sneakyOrdersSettled, success);
        }

        // 2) Place new sneaky orders
        if (amountToPlace > 0) {

            for (uint256 i; i < amountToPlace;) {
                sneakyOrders.push(SneakyOrder(buyer, block.number));
                emit SneakyOrderPlaced(buyer, sneakyOrders.length);
                unchecked{++i;}
            }
        }
    }

    function core_mint(Order memory order) internal returns (uint256 seed) {
        seed = uint256(
            keccak256(
                abi.encodePacked(
                    uint256(blockhash(order.orderBlock)),
                    ordersSettled
                )
            )
        );

        unchecked{ordersSettled++;}
        seed = generate(order.skeletonProbability, seed);
        address recipient = selectRecipient(order.buyer, order.stolenProbability, seed >> 32);

        unchecked {
            if (tokenTraits[ordersSettled].isRanger) {
                rangerMinted++;
                if (recipient != order.buyer) rangerStolen++;
            } else {
                skeletonMinted++;
                if (recipient != order.buyer) skeletonStolen++;
            }
        }

        _safeMint(recipient, ordersSettled);
        emit OrderSettled(order.buyer, ordersSettled, recipient != order.buyer);
    }

    function generate(uint8 skeletonProbability, uint256 seed) internal returns (uint256) {
        SklRgr memory t = selectBody(skeletonProbability, seed);
        seed = renewSeed(seed);
        tokenTraits[ordersSettled] = selectTraits(seed, t);
        return renewSeed(seed);
    }

    function renewSeed(uint256 old) internal view returns (uint256) {
        return uint256(
            keccak256(abi.encodePacked(old, block.timestamp, ordersSettled))
        );
    }

    /**
     * The first 20% (AVAX purchases) go to the minter
     * The remaining 80% have a 10% chance to be given to a random staked skeleton
     * @param seed Pseudorandom value to select a recipient from
     * @return receiver The address of the recipient (either the minter or the skeleton thief's owner)
     */
    function selectRecipient(address buyer, uint8 stolenProbability, uint256 seed) internal view returns (address) {
        if (seed % 100 >= stolenProbability) return buyer;
        address thief = magicForest.randomSkeletonOwner(seed >> 16);
        if (thief == address(0x0)) return buyer;
        return thief;
    }

    function selectBody(uint8 skeletonProbability, uint256 seed) internal view returns (SklRgr memory t) {
        t.isRanger = seed % 100 >= skeletonProbability;
        if (!t.isRanger) t.alphaIndex = selectAlpha(seed >> 16);
        t.level = 1;
    }

    function selectAlpha(uint256 seed) internal view returns (uint8) {
        uint256 m = seed % 100;
        uint256 probabilitySum;
        for (uint8 i = 10; i >= 5;) {
            unchecked {
                probabilitySum += alphaRarities[i - 5];
                if (m < probabilitySum) return i;
                --i;
            }
        }
        return 5;
    }

    function selectTraits(uint256 seed, SklRgr memory t) internal view returns (SklRgr memory) {
        if (t.isRanger) {
            (t.arm, t.head, t.body, t.gadget) = traits.selectRangerTraits(seed);
        } else {
            (t.arm, t.head, t.torso, t.legs) = traits.selectSkeletonTraits(seed);
        }
        return t;
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
        if (tokenTraits[tokenId].isRanger && to != address(magicForest) && from != address(magicForest)) {
            pets.beforeRangerTransfer(from, to, tokenId);
        }
    }

    /** READ */

    function getGeneration(uint256 tokenId) public view returns(uint256) {
        if (tokenId <= generationsTresholds[0]) return 0;
        if (tokenId <= generationsTresholds[1]) return 1;
        if (tokenId <= generationsTresholds[2]) return 2;
        if (tokenId <= generationsTresholds[3]) return 3;
        return 4;
    }

    function mintCost(uint256 tokenId) public view returns (uint256, uint256) {
        uint256 generation = getGeneration(tokenId);
        return (generationsPriceAVAX[generation], generationsPriceGLOW[generation]);
    }

    function sneakyMintCost() public view returns (uint256, uint256) {
        return (sneakyMintPriceAVAX, sneakyMintPriceGLOW);
    }

    function getTokenTraits(uint256 tokenId) external view returns (SklRgr memory) {
        return tokenTraits[tokenId];
    }

    /**
     * @param tokenId Id of the token
     * @return gemPrice The price to upgrade the token by one level
     */
    function upgradeCost(uint256 tokenId) public view returns (uint256) {
        if (tokenTraits[tokenId].level == 5) return 0;
        return tokenTraits[tokenId].isRanger ? 
            baseRangerUpgradePrice * tokenTraits[tokenId].level :
            skeletonUpgradePricesByLevel[tokenTraits[tokenId].level - 1];
    }
 
    function numberOfOrders() external view returns (uint256) {
        return orders.length;
    }

    function numberOfSneakyOrders() external view returns (uint256) {
        return sneakyOrders.length;
    }

    /** RENDER */

    function tokenURI(uint256 tokenId) public view override returns(string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return traits.tokenURI(tokenId);
    }

    /* MONEY TRANSFERS */

    function getBalance() internal view returns (uint256) {
        return address(this).balance;
    }

    function withdrawMoney() external onlyController {
        devAddress.transfer((getBalance() * 5) / 100);
        adminAddress.transfer(getBalance());
    }

    function getTokenBalance(address _token) internal view returns(uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    function withdrawToken(address _token) external onlyController {
        withdrawToken(_token, getTokenBalance(_token));
    }

    function withdrawToken(address _token, uint256 _amount) public onlyController {
        IERC20(_token).transfer(owner(), _amount);
    }

    /* GAME MANAGEMENT */

    function setPaused(bool _paused) external onlyController {
        if (_paused) _pause();
        else _unpause();
    }

    /* VALUES SETTERS */

    function setCostInAdventurers(uint8 _costInAdventurers) external onlyController {
        costInAdventurers = _costInAdventurers;
    }

    function setCostInHunters(uint8 _costInHunters) external onlyController {
        costInHunters = _costInHunters;
    }

    function setState(
        bool _normalMint,
        bool _burnMint,
        bool _sneakyMint,
        bool _burnSneakyMint
    ) public onlyController {
        state = State(_normalMint, _burnMint, _sneakyMint, _burnSneakyMint);
    }

    function setMintPrices(
        uint16[] calldata _tresholds,
        uint256[] calldata _avaxPrices,
        uint256[] calldata _glowPrices
    ) external onlyController {
        for (uint256 i; i < _tresholds.length;) {
            generationsTresholds[i] = _tresholds[i];
            generationsPriceAVAX[i] = _avaxPrices[i];
            generationsPriceGLOW[i] = _glowPrices[i];
            unchecked{++i;}
        }
    }

    function setSneakyMintPrices(uint256 _avaxPrice, uint256 _glowPrice) external onlyController {
        sneakyMintPriceAVAX = _avaxPrice;
        sneakyMintPriceGLOW = _glowPrice;
    }

    /* ADDRESSES SETTERS */

    function setGem(address _gem) public onlyController {
        gem = IGEM(_gem);
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
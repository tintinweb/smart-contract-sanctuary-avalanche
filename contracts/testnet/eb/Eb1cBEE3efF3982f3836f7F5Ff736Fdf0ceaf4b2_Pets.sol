// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./Restricted.sol";

import "./IHunter.sol";
import "./IGEM.sol";

import "./Glow.sol";
import "./Skeleton.sol";
import "./AttributesPets.sol";

contract Pets is ERC721Enumerable, Pausable, Restricted {
 
    uint256 public MAX_TOKENS = 50000;

    //To know which pet each nft is
    uint8[] public petTokenToPetId;
    
    uint8 public nbOfRarities = 5;
    uint8[5] public raritiyProbabilities = [45, 30, 19, 5, 1];
    uint8[][5] public petsByRarity;

    // Payment wallets
    address payable AdminWallet = payable(0x9F523A9d191704887Cf667b86d3B6Cd6eBE9D6e9); // TODO
    address payable devAddress = payable(0xCCf8234c08Cc1D3bF8067216F7b63eeAcb113756); // TODO

    event onOrderPlaced(address indexed buyer, uint8 amount);
    event onOrderSettled(address indexed buyer, uint256 indexed tokenId);
    event RangerAssociation(address indexed account, uint256 indexed petId, uint256 indexed rangerId, bool association);
    event WalletAssociation(address indexed account, uint256 indexed petId, bool association);

    struct Order {
        address buyer;
        uint256 orderBlock;
        uint8 limitedMintIndex;
    }
    // List of all the orders placed
    Order[] public orders;

    // Index of the last order settled
    uint16 public ordersSettled;

    // reference to $GEM for burning on mint
    IGEM public gem = IGEM(address(0x4D3dDeec55f148B3f8765A2aBc00252834ed7E62));

    Glow public glow;
    Skeleton public skeleton;
    MagicForest public magicForest;
    AttributesPets public attributesPets;

    mapping(uint256 => uint256) public petTokenToRangerToken; //0 if none
    mapping(uint256 => uint256) public rangerTokenToPetToken; //mapping for pet for NFT
    mapping(address => uint256) public walletToPetToken; //same for pet wallet but only 1, other is owner of
    mapping(address => uint32) public lastWalletAssociation;

    // For limited pets (collabs)
    struct LimitedMint {
        uint8 petId;
        uint16 remaining;
        uint256 start;
        uint256 end;
        uint256 glowPrice;
        address collabToken;
        uint256 collabTokenPrice;
    }
    LimitedMint[] public limitedMints;

    constructor(
        address _glow,
        address _skeleton,
        address _magicForest,
        address _attributesPets
    ) ERC721("Yield Hunt Pets", "Pets") {
        petTokenToPetId.push();
        setGlow(_glow);
        setSkeleton(_skeleton);
        setMagicForest(_magicForest);
        setAttributesPets(_attributesPets);
        _addController(AdminWallet);
    }

    /**
     * Main function to mint a Pet
     * Costs : 
     * | 0.5 AVAX & 20000 $GLOW (ids     1 -> 10000)
     * | 0.4 AVAX & 30000 $GLOW (ids 10001 -> 20000)
     * | 0.3 AVAX & 30000 $GLOW (ids 20001 -> 30000)
     * | 0.2 AVAX & 40000 $GLOW (ids 30001 -> 40000)
     * | 0.1 AVAX & 50000 $GLOW (ids 40001 -> 50000)
     * @param amount Number of NFTs to mint, limited to 5 by transaction for non admins
     */
    function mint(uint8 amount)
        external
        payable
        whenNotPaused
        onlyEOAor(isController(_msgSender()))
        noReentrency
        notBlacklisted
    {
        bool freeMint = isController(_msgSender());

        require(orders.length + amount <= MAX_TOKENS, "All tokens minted");
        require(amount > 0,                           "Invalid mint amount");
        require(amount <= (freeMint ? 100 : 5),       "Max 5 NFTs by transaction");

        uint256 totalAvaxPrice = 0;
        uint256 totalGemPrice = 0;

        for (uint8 i = 0; i < amount; i++) {
            (uint256 avaxPrice, uint256 gemPrice) = mintCost(
                ordersSettled + 1 + i
            );
            totalAvaxPrice += avaxPrice;
            totalGemPrice += gemPrice;
        }

        require(
            totalAvaxPrice <= msg.value || freeMint,
            "Not enough AVAX for payment"
        );

        if (totalGemPrice > 0 && !freeMint) {
            gem.burn(_msgSender(), totalGemPrice);
        }

        _settleOrders(amount + 1);
        emit onOrderPlaced(_msgSender(), amount);
        _storeMintOrder(_msgSender(), amount, 0);
    }

    /**
     * Function to mint limited Pets (collabs)
     * @param index Session index
     * @param amount Number of NFTs to mint, limited to 5 by transaction for non admins
     */
    function limitedMint(uint8 index, uint8 amount)
        external
        whenNotPaused
        onlyEOAor(isController(_msgSender()))
        noReentrency
        notBlacklisted
    {
        require(limitedMints.length > index,    "Query for non-existent limited mint session");
        require(limitedMints[index].petId != 0, "Invalid limited mint session");

        bool freeMint = isController(_msgSender());

        require(
            block.timestamp >= limitedMints[index].start &&
            block.timestamp < limitedMints[index].end,
            "Limited mint session closed"
        );
        require(orders.length + amount <= MAX_TOKENS,    "All tokens minted");
        require(amount > 0,                              "Invalid mint amount");
        require(amount <= (freeMint ? 100 : 5),          "Max 5 NFTs by transaction");
        require(amount <= limitedMints[index].remaining, "Already sold out!");

        limitedMints[index].remaining -= amount;

        if (limitedMints[index].collabTokenPrice > 0 && !freeMint) {
            // Need to approve this contract for the token
            IERC20(limitedMints[index].collabToken).transferFrom(
                _msgSender(),
                address(this),
                amount * limitedMints[index].collabTokenPrice
            );
        }

        if (limitedMints[index].glowPrice > 0 && !freeMint) {
            glow.burn(_msgSender(), amount * limitedMints[index].glowPrice);
        }

        _settleOrders(amount + 1);
        emit onOrderPlaced(_msgSender(), amount);
        _storeMintOrder(_msgSender(), amount, index + 1);
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

    /* INTERNAL */

    function _storeMintOrder( address buyer, uint8 amount, uint8 limitedMintIndex) internal {
        withdrawMoney();
        for (uint256 i = 0; i < amount; i++) {
            orders.push(Order(buyer, block.number, limitedMintIndex));
        }
    }

    function _settleOrders(uint8 amount) internal {
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
            core_mint(order);
        }
    }

    function core_mint(Order memory order) internal {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    uint256(blockhash(order.orderBlock)),
                    ordersSettled
                )
            )
        );

        generate(seed, order.limitedMintIndex);
        _safeMint(order.buyer, ordersSettled);
        emit onOrderSettled(order.buyer, ordersSettled);
    }

    function generate(uint256 seed, uint16 limitedMintIndex) internal {
        if (limitedMintIndex == 0) {
            uint256 m = seed % 100;
            uint256 probabilitySum = 0;
            uint8 rarity = 0;

            for (uint8 i = nbOfRarities - 1; i > 0; i--) {
                probabilitySum += raritiyProbabilities[i];
                if (m < probabilitySum) {
                    rarity = i;
                    break;
                }
            }

            petTokenToPetId.push(petsByRarity[rarity][(renewSeed(seed) >> (7 + rarity)) % petsByRarity[rarity].length]);
        } else {
            petTokenToPetId.push(limitedMints[limitedMintIndex-1].petId);
        }
    }

    function renewSeed(uint256 old) internal view returns (uint256 seed) {
        seed = uint256(
            keccak256(abi.encodePacked(old, block.timestamp, ordersSettled))
        );
    }

    /* PETS LINKS */

    /**
     * Associates a pet to your wallet
     * @param petToken The id of the pet you'd like to associate to your wallet
     */
    function associatePetToWallet(uint256 petToken)
        external
        whenNotPaused
        onlyEOA
        noReentrency
        notBlacklisted
    {
        require(ownerOf(petToken) == _msgSender(),    "This pet isn't yours");
        require(petTokenToRangerToken[petToken] == 0, "This pet is already associated to a ranger");
        uint8 boostType = getPetBoostType(petToken);
        require(boostType == 2 || boostType == 3,     "This pet cannot be associated to a wallet");

        _associatePetToWallet(_msgSender(), petToken);
    }

    /**
     * Internal function to associate a pet to a wallet
     * @param _from Address of the wallet to which you want to associate the pet
    * @param petToken The id of the pet you'd like to associate to the wallet
     */
    function _associatePetToWallet(address _from, uint256 petToken) internal {
        uint8 oldAlphaAugmentation = getWalletBoost(_from).alphaAugmentation;
        lastWalletAssociation[_from] = uint32(block.timestamp);
        walletToPetToken[_from] = petToken;
        uint8 newAlphaAugmentation = getWalletBoost(_from).alphaAugmentation;
        if (newAlphaAugmentation != oldAlphaAugmentation) magicForest.updateSkeletonStakes(_from, newAlphaAugmentation, oldAlphaAugmentation);
        emit WalletAssociation(_from, petToken, true);
    }

    /**
     * Disscociates the pet associated to your wallet
     */
    function dissociatePetFromWallet()
        external
        whenNotPaused
        onlyEOA
        noReentrency
        notBlacklisted
    {
        _dissociatePetFromWallet(_msgSender());
    }

    /**
     * Internal function to dissociate the pet associated to a wallet
     * @param _from Address of the wallet from which you want to dissociate the pet
     */
    function _dissociatePetFromWallet(address _from) internal {
        emit WalletAssociation(_from, walletToPetToken[_from], false);
        uint8 oldAlphaAugmentation = getWalletBoost(_from).alphaAugmentation;
        lastWalletAssociation[_from] = uint32(block.timestamp);
        walletToPetToken[_from] = 0;
        if (oldAlphaAugmentation > 0) magicForest.updateSkeletonStakes(_from, 0, oldAlphaAugmentation);
    }

    /**
     * Associates a pet to a ranger
     * @param petToken Id of the pet you'd like to associate
     * @param rangerToken Id of the ranger you'd like to associate
     */
    function associatePetToRanger(uint256 petToken, uint256 rangerToken)
        external
        whenNotPaused
        onlyEOA
        noReentrency
        notBlacklisted
    {
        require(skeleton.ownerOf(rangerToken) == _msgSender(), "This ranger isn't yours");
        require(ownerOf(petToken) == _msgSender(),             "This pet isn't yours");
        require(isRanger(rangerToken),                         "Skeletons cannot have a pet");
        require(walletToPetToken[_msgSender()] != petToken,    "This pet is already associated to your wallet");
        require(petTokenToRangerToken[petToken] == 0,          "This pet is already associated to a ranger");
        require(rangerTokenToPetToken[rangerToken] == 0,       "This ranger is already associated to a pet");
        uint8 boostType = getPetBoostType(petToken);
        require(boostType == 1 || boostType == 3,              "This pet cannot be associated to a ranger");

        _associatePetToRanger(petToken, rangerToken);
    }

    /**
     * Internal function to associate a pet to a ranger
     * @param petToken Id of the pet you'd like to associate
     * @param rangerToken Id of the ranger you'd like to associate
     */
    function _associatePetToRanger(uint256 petToken, uint256 rangerToken) internal {
        petTokenToRangerToken[petToken] = rangerToken;
        rangerTokenToPetToken[rangerToken] = petToken;
        emit RangerAssociation(ownerOf(petToken), petToken, rangerToken, true);
    }

    /**
     * Dissociates the pet given from the ranger associated
     * @param petToken Id of the pet you'd like to dissociate
     */
    function dissociateFromPet(uint256 petToken)
        external
        whenNotPaused
        onlyEOA
        noReentrency
        notBlacklisted
    {
        require(ownerOf(petToken) == _msgSender(), "This pet isn't yours");
        _dissociateFromPet(petToken);
    }

    /**
     * Internal function to dissociate the pet given from the ranger associated
     * @param petToken Id of the pet you'd like to dissociate
     */
    function _dissociateFromPet(uint256 petToken) internal {
        _dissociatePetFromRanger(petToken, petTokenToRangerToken[petToken]);
    }

    /**
     * Dissociates the ranger given from the pet associated
     * @param rangerToken Id of the ranger you'd like to dissociate
     */
    function dissociateFromRanger(uint256 rangerToken)
        external
        whenNotPaused
        onlyEOA
        noReentrency
        notBlacklisted
    {
        require(skeleton.ownerOf(rangerToken) == _msgSender(), "This ranger isn't yours");
        _dissociateFromRanger(rangerToken);
    }

    /**
     * Internal function to dissociate the ranger given from the pet associated
     * @param rangerToken Id of the ranger you'd like to dissociate
     */
    function _dissociateFromRanger(uint256 rangerToken) internal {
        _dissociatePetFromRanger(rangerTokenToPetToken[rangerToken], rangerToken);
    }

    /**
     * Internal function to dissociate the ranger given from the pet given
     * @param petToken Id of the pet you'd like to dissociate
     * @param rangerToken Id of the ranger you'd like to dissociate
     */
    function _dissociatePetFromRanger(uint256 petToken, uint256 rangerToken) internal {
        petTokenToRangerToken[petToken] = 0;
        rangerTokenToPetToken[rangerToken] = 0;
        if (petToken != 0 && rangerToken != 0) emit RangerAssociation(ownerOf(petToken), petToken, rangerToken, false);
    }

    /* TOKEN TRANSFERS */

    function beforeRangerTransfer(address from, address to, uint256 rangerToken) external {
        require(_msgSender() == address(skeleton), "Only for the Skeleton contract here");
        if (from != address(magicForest) && to != address(magicForest)) {
            _dissociateFromRanger(rangerToken);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 petToken) internal override {
        super._beforeTokenTransfer(from, to, petToken);
        if (from != address(magicForest) && to != address(magicForest)) {
            _dissociateFromPet(petToken);
            if (walletToPetToken[from] == petToken){
                _dissociatePetFromWallet(from);
            }            
        }
    }

    /** RENDER */

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return attributesPets.tokenURI(tokenId, petTokenToPetId[tokenId]);
    }

    /* READ */

    function mintCost(uint256 tokenId) public view returns (uint256, uint256) {
        if (tokenId <= MAX_TOKENS / 5) return (5 wei, 20000 ether);       //0.5 ether for real launch <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
        if (tokenId <= (MAX_TOKENS * 2) / 5) return (4 wei, 30000 ether); //0.4 ether for real launch <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
        if (tokenId <= (MAX_TOKENS * 3) / 5) return (3 wei, 30000 ether); //0.3 ether for real launch <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
        if (tokenId <= (MAX_TOKENS * 4) / 5) return (2 wei, 40000 ether); //0.2 ether for real launch <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
        return (1 wei, 50000 ether);                                      //0.1 ether for real launch <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    }

    function isRanger(uint256 tokenId) public view returns (bool ranger) {
        (ranger,,,,,,,,) = skeleton.tokenTraits(tokenId);
    }

    /**
     * @param tokenId Id of the ranger (from the contract Skeleton)
     * @return The boost of the pet associated to the ranger
     */
    function getRangerBoost(uint256 tokenId) public view returns (AttributesPets.Boost memory) {
        return getPetBoost(rangerTokenToPetToken[tokenId]);
    }

    /**
     * @param account Account address
     * @return The boost of the pet associated to the account
     */
    function getWalletBoost(address account) public view returns (AttributesPets.Boost memory) {
        return getPetBoost(walletToPetToken[account]);
    }

    /**
     * @param tokenId Id of the pet (from the contract Pets)
     * @return The boost of the pet
     */
    function getPetBoost(uint256 tokenId) public view returns (AttributesPets.Boost memory) {
        uint8 petId = petTokenToPetId[tokenId];
        return attributesPets.getBoost(petId);
    }
    
    function getPetBoostType(uint256 tokenId) public view returns(uint8) {
        uint8 petId = petTokenToPetId[tokenId];
        return attributesPets.getPetBoostType(petId);
    }

    /* TOKEN TRANSFERS */

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721, IERC721) {
        // Hardcode the MagicForest's approval so that users don't have to waste gas approving
        if (_msgSender() != address(magicForest))
            require(
                _isApprovedOrOwner(_msgSender(), tokenId),
                "ERC721: transfer caller is not owner nor approved"
            );
        _transfer(from, to, tokenId);
    }

    /* MONEY TRANSFERS */

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdrawMoney() internal {
        devAddress.transfer((getBalance() * 5) / 100);
        AdminWallet.transfer(getBalance());
    }

    function withdrawToOwner() external onlyController {
        payable(owner()).transfer(getBalance());
    }

    function getTokenBalance(address _token) public view returns(uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    function withdrawToken(address _token) public onlyController {
        IERC20(_token).transferFrom(address(this), devAddress, (getTokenBalance(_token) * 5) / 100);
        IERC20(_token).transferFrom(address(this), AdminWallet, getTokenBalance(_token));
    }

    function withdrawAllTokens() external onlyController {
        for (uint256 i = 0; i < limitedMints.length; i++) {
            withdrawToken(limitedMints[i].collabToken);
        }
    }
 
    /* GAME MANAGEMENT */
    
    function setPaused(bool _paused) external onlyController {
        if (_paused) _pause();
        else _unpause();
    }

    function setLimitedPet(
        uint8 _index,
        uint8 _petId,
        uint16 _stock,
        uint256 _start,
        uint256 _end,
        uint256 _glowPrice,
        address _collabToken,
        uint256 _collabTokenPrice
    ) external onlyController {
        while (limitedMints.length <= _index) {
            limitedMints.push();
        }
        limitedMints[_index] = LimitedMint(_petId, _stock, _start, _end, _glowPrice, _collabToken, _collabTokenPrice);
    }

    /* GAME INITILAIZATION */

    function setAttributesPets(address _attributesPets) public onlyController {
        attributesPets = AttributesPets(_attributesPets);
    }

    function updatePetsByRarity(uint8 rarity, uint8[] calldata petIds) external onlyController {
        delete petsByRarity[rarity];
        for (uint8 i = 0; i < petIds.length; i++) {
            petsByRarity[rarity].push(petIds[i]);
        }
    }

    /* VALUES SETTERS */

    function setMaxTokens(uint256 _maxTokens) public onlyController {
        MAX_TOKENS = _maxTokens;
    }

    /* ADDRESSES SETTERS */

    function setGem(address _gem) external onlyController {
        gem = IGEM(_gem);
    }

    function setGlow(address _glow) public onlyController {
        glow = Glow(_glow);
    }

    function setSkeleton(address _skeleton) public onlyController {
        skeleton = Skeleton(_skeleton);
    }

    function setMagicForest(address _magicForest) public onlyController {
        magicForest = MagicForest(_magicForest);
    }
}
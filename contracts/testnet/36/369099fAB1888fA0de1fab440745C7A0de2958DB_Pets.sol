// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./Controllable.sol";
import "./Restricted.sol";

import "./IHunter.sol";
import "./IGEM.sol";

import "./Skeleton.sol";
import "./AttributesPets.sol";

contract Pets is ERC721Enumerable, Pausable, Controllable, Restricted {
    uint8[] public petTokenToPetId = new uint8[](1); //To know which pet each nft is

    // max number of tokens that can be minted - 50000 in production
    uint256 public MAX_TOKENS = 50000;
    uint8 public nbOfRarities = 5;
    uint8[5] public raritiyProbabilities = [40, 30, 20, 8, 2];

    // petsByRarity[0] = list of common pets
    // petsByRarity[1] = list of uncommon pets
    // etc..
    uint8[][5] public petsByRarity;

    // payment wallets
    address payable AdminWallet = payable(0x9F523A9d191704887Cf667b86d3B6Cd6eBE9D6e9);
    address payable devAddress = payable(0xCCf8234c08Cc1D3bF8067216F7b63eeAcb113756);

    event onOrderPlaced(address indexed buyer, uint256 amount);
    event onOrderSettled(address indexed buyer, uint256 indexed tokenId);

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

    // reference to Traits
    AttributesPets public attributesPets;
    Skeleton public skeleton;

    mapping(uint256 => uint256) public petTokenToRangerToken; //0 if none
    mapping(uint256 => uint256) public rangerTokenToPetToken; //mapping for pet for NFT

    mapping(address => uint256) public walletToPetToken; //same for pet wallet but only 1, other is owner of

    MagicForest public magicForest;

    //For limited pets (collabs)
    struct LimitedMint {
        uint8 petId;
        uint16 remaining;
        uint256 start;
        uint256 end;
        uint256 gemPrice;
        uint256 avaxPrice;
    }

    LimitedMint[] public limitedMints;

    constructor(
        address _attributesPets,
        address _skeleton,
        address _magicForest
    ) ERC721("Yield Hunt Pets", "Pets") {
        setAttributesPets(_attributesPets);
        setSkeleton(_skeleton);
        setMagicForest(_magicForest);
        _addController(AdminWallet);
    }

    function mintCost(uint256 tokenId) public view returns (uint256, uint256) {
        if (tokenId <= MAX_TOKENS / 5) return (0.5 ether, 20000 ether);
        if (tokenId <= (MAX_TOKENS * 2) / 5) return (0.4 ether, 30000 ether);
        if (tokenId <= (MAX_TOKENS * 3) / 5) return (0.3 ether, 30000 ether);
        if (tokenId <= (MAX_TOKENS * 4) / 5) return (0.2 ether, 40000 ether);
        return (0.1 ether, 50000 ether);
    }

    function mint(uint8 amount) external payable whenNotPaused onlyEOA noReentrency {
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
        storeMintOrder(_msgSender(), amount, 0);
    }

    function limitedMint(uint8 index, uint8 amount) external payable whenNotPaused onlyEOA noReentrency {
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

        require(
            amount * limitedMints[index].avaxPrice <= msg.value || freeMint,
            "Not enough AVAX for payment"
        );

        if (limitedMints[index].gemPrice > 0 && !freeMint) {
            gem.burn(_msgSender(), amount * limitedMints[index].gemPrice );
        }

        _settleOrders(amount + 1);
        emit onOrderPlaced(_msgSender(), amount);
        storeMintOrder(_msgSender(), amount, index + 1);
    }

    function storeMintOrder( address buyer, uint8 amount, uint8 limitedMintIndex) private {
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

    function settleOrders(uint8 amount) external whenNotPaused onlyEOA noReentrency {
        _settleOrders(amount);
    }

    function core_mint(Order memory order) internal {
        // must have been payed before

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

    /** INTERNAL */

    /**
     * generates traits for a specific token, checking to make sure it's unique
     * @param seed a pseudorandom 256 bit number to derive traits from
     */
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

    /**
     * Associates a pet to your wallet
     * @param petToken The id of the pet you'd like to associate to your wallet
     */
    function associatePetToWallet(uint256 petToken) external onlyEOA noReentrency {
        require(ownerOf(petToken) == _msgSender(),    "This pet isn't yours");
        require(petTokenToRangerToken[petToken] == 0, "This pet is already associated to a ranger");
        walletToPetToken[_msgSender()] = petToken;
    }

    /**
     * Disscociates the pet associated to your wallet
     */
    function dissociatePetFromWallet() external onlyEOA noReentrency {
        _dissociatePetFromWallet(_msgSender());
    }

    /**
     * Internal function to dissociate the pet associated to a wallet
     * @param _from Address of the wallet from which you want to dissociate the pet
     */
    function _dissociatePetFromWallet(address _from) internal {
        walletToPetToken[_from] = 0;
    }

    /**
     * Associates a pet to a ranger
     * @param petToken Id of the pet you'd like to associate
     * @param rangerToken Id of the ranger you'd like to associate
     */
    function associatePetToRanger(uint256 petToken, uint256 rangerToken) external onlyEOA noReentrency {
        require(skeleton.ownerOf(rangerToken) == _msgSender(), "This ranger isn't yours");
        require(ownerOf(petToken) == _msgSender(),             "This pet isn't yours");
        require(isRanger(rangerToken),                         "Skeletons can't have a pet");
        require(walletToPetToken[_msgSender()] != petToken,    "This pet is already associated to your wallet");
        require(petTokenToRangerToken[petToken] == 0,          "This pet is already associated to a ranger");
        require(rangerTokenToPetToken[rangerToken] == 0,       "This ranger is already associated to a pet");

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
    }

    /**
     * Dissociates the pet given from the ranger associated
     * @param petToken Id of the pet you'd like to dissociate
     */
    function dissociateFromPet(uint256 petToken) external onlyEOA noReentrency {
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
    function dissociateFromRanger(uint256 rangerToken) external onlyEOA noReentrency {
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
    }

    function beforeRangerTransfer(address from, address to, uint256 rangerToken) external {
        require(_msgSender() == address(skeleton), "Only for the Skeleton contract here");
        if (from != address(magicForest) && to != address(magicForest)) {
            _dissociatePetFromWallet(from);
            _dissociateFromRanger(rangerToken);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 petToken) internal override {
        super._beforeTokenTransfer(from, to, petToken);
        if (from != address(magicForest) && to != address(magicForest)) {
            _dissociateFromPet(petToken);
            if(walletToPetToken[from] == petToken){
                _dissociatePetFromWallet(from);
            }            
        }
    }

    function renewSeed(uint256 old) internal view returns (uint256 seed) {
        seed = uint256(
            keccak256(abi.encodePacked(old, block.timestamp, ordersSettled))
        );
    }

    /** RENDER */

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require( _exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return attributesPets.tokenURI(tokenId, petTokenToPetId[tokenId]);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdrawMoney() internal {
        devAddress.transfer((getBalance() * 5) / 100);
        AdminWallet.transfer(getBalance());
    }

    /**
     * Allows owner to withdraw funds from minting
     */
    function withdrawToOwner() external onlyController {
        payable(owner()).transfer(getBalance());
    }

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

    /**
     * enables owner to pause / unpause minting
     */
    function setPaused(bool _paused) external onlyController {
        if (_paused) _pause();
        else _unpause();
    }

    function isRanger(uint256 tokenId) public view returns (bool ranger) {
        (ranger, , , , , , , , , ) = skeleton.tokenTraits(tokenId);
    }

    function setLimitedPet(
        uint8 _index,
        uint8 _petId,
        uint16 _stock,
        uint256 _start,
        uint256 _end,
        uint256 _gemPrice,
        uint256 _avaxprice
    ) external onlyController {
        while (limitedMints.length <= _index) {
            limitedMints.push();
        }
        limitedMints[_index] = LimitedMint(_petId, _stock, _start, _end, _gemPrice, _avaxprice);
    }

    function setAttributesPets(address _attributesPets) public onlyController {
        attributesPets = AttributesPets(_attributesPets);
    }

    function setGem(address _gem) external onlyController {
        gem = IGEM(_gem);
    }

    // returns the atributes (if they exists) of the pet associated to a NFT from Skeleton.sol
    function getRangerBoost(uint256 tokenId) public view returns (AttributesPets.Boost memory) {
        uint256 petToken = rangerTokenToPetToken[tokenId];
        uint8 petId = petTokenToPetId[petToken];
        return attributesPets.getBoost(petId);
    }

    // returns the atributes (if they exists) of the pet associated to a wallet
    function getWalletBoost(address wallet) public view returns (AttributesPets.Boost memory) {
        return getPetBoost(walletToPetToken[wallet]);
    }

    function getPetBoost(uint256 tokenId) public view returns (AttributesPets.Boost memory) {
        uint8 petId = petTokenToPetId[tokenId];
        return attributesPets.getBoost(petId);
    }

    function setMaxTokens(uint256 _MAX_TOKENS) public onlyController {
        MAX_TOKENS = _MAX_TOKENS;
    }

    function setSkeleton(address _skeleton) public onlyController {
        skeleton = Skeleton(_skeleton);
    }

    function updatePetsByRarity(uint8 rarity, uint8[] calldata petIds) external onlyController {
        delete petsByRarity[rarity];
        for (uint8 i = 0; i < petIds.length; i++) {
            petsByRarity[rarity].push(petIds[i]);
        }
    }

    function setMagicForest(address _magicForest) public onlyController {
        magicForest = MagicForest(_magicForest);
    }
}
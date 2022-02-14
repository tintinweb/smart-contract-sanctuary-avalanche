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
    uint8[5] public raritiyProbabilities = [50, 30, 14, 5, 1];

    // petsByRarity[0] = list of common pets
    // petsByRarity[1] = list of uncommon pets
    // etc..
    uint8[][5] public petsByRarity;
    
    // payment wallets
    address payable AdminWallet = payable(0x9F523A9d191704887Cf667b86d3B6Cd6eBE9D6e9);
    address payable devAddress = payable(0xCCf8234c08Cc1D3bF8067216F7b63eeAcb113756);

   struct Order {
        address buyer;
        uint256 orderBlock;
        bool isLimitedMint;
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

    //For limited pets (collabs)
    uint8 limitedPetId;
    uint256 limitedMintStart;
    uint256 limitedMintEnd;
    uint256 limitedMintGemPrice;
    uint256 limitedMintAvaxPrice;

    constructor(address _attributesPets, address _skeleton) ERC721("Yield Hunt Pets", "Pets") {
        setAttributesPets(_attributesPets);
        setSkeleton(_skeleton);
    }

    function mintCost(uint256 tokenId) public view returns (uint256, uint256) {
        if (tokenId <= MAX_TOKENS / 5) return (0.5 ether, 20000 ether);
        if (tokenId <= (MAX_TOKENS * 2) / 5) return (0.4 ether, 30000 ether);
        if (tokenId <= (MAX_TOKENS * 3) / 5) return (0.3 ether, 30000 ether);
        if (tokenId <= (MAX_TOKENS * 4) / 5) return (0.2 ether, 40000 ether);
        return (0.1 ether, 50000 ether);
    }

    function mint(uint256 amount) external payable whenNotPaused onlyEOA noReentrency {
        bool freeMint = _msgSender() == AdminWallet;

        require(orders.length + amount <= MAX_TOKENS, "All tokens minted");
        require(amount > 0, "Invalid mint amount");
        require(amount <= (freeMint ? 50 : 5), "Max 5 NFTs by transaction");

        uint256 totalAvaxPrice = 0;
        uint256 totalGemPrice = 0;

        for (uint256 i = 0; i < amount; i++) {
            (uint256 avaxPrice, uint256 gemPrice) = mintCost(ordersSettled + 1 + i);
            totalAvaxPrice += avaxPrice;
            totalGemPrice += gemPrice;
        }

        require(
            totalAvaxPrice <= msg.value || freeMint,
            "Not enough AVAX for payment"
        );

        if (totalGemPrice > 0 && ! freeMint) {
            gem.burn(_msgSender(), totalGemPrice);
        }

        _settleOrders(amount + 1);
        storeMintOrder(_msgSender(), amount, false);
    }

    function limitedMint(uint256 amount) external payable whenNotPaused onlyEOA noReentrency {
        bool freeMint = _msgSender() == AdminWallet;

        require(block.timestamp >= limitedMintStart && block.timestamp < limitedMintEnd, "Limited mint session closed");
        require(orders.length + amount <= MAX_TOKENS, "All tokens minted");
        require(amount > 0, "Invalid mint amount");
        require(amount <= (freeMint ? 50 : 5), "Max 5 NFTs by transaction");


        require(
              amount * limitedMintAvaxPrice <= msg.value || freeMint,
            "not enough AVAX for payment"
        );

        if (limitedMintAvaxPrice > 0 && ! freeMint) {
            gem.burn(_msgSender(), amount * limitedMintAvaxPrice);
        }

        _settleOrders(amount + 1);
        storeMintOrder(_msgSender(), amount, true);
    }

    function storeMintOrder(address buyer, uint256 amount, bool isLimitedMint) private {
        withdrawMoney();
        for (uint256 i = 0; i < amount; i++) {
            orders.push(Order(buyer, block.number, isLimitedMint));
        }
    }

    function _settleOrders(uint256 amount) internal {
        uint256 initialOrdersSettled = ordersSettled;
        while (ordersSettled - initialOrdersSettled < amount && ordersSettled < orders.length) {
            Order memory order = orders[ordersSettled];

            // Can't generate in the same block as the order
            if (order.orderBlock >= block.number) {
                break;
            }

            ordersSettled++;
            core_mint(order);
        }
    }

     function settleOrders(uint256 amount) external whenNotPaused onlyEOA noReentrency {
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

        generate(seed, order.isLimitedMint);
        _safeMint(_msgSender(), ordersSettled);
    }


    /** INTERNAL */

    /**
     * generates traits for a specific token, checking to make sure it's unique
     * @param seed a pseudorandom 256 bit number to derive traits from
     */
    function generate(uint256 seed, bool isLimitedMint) internal {
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
        if (isLimitedMint) {
            petTokenToPetId.push(limitedPetId);
        } else {
            petTokenToPetId.push(petsByRarity[rarity][(renewSeed(seed) >> 7 + rarity) % petsByRarity[rarity].length]);
        }
    }

    function associatePetToWallet(uint256 idPet) external onlyEOA noReentrency { //CHECK ONLY ADVENTURER
        require(ownerOf(idPet) == _msgSender(), "not your token");
        require(walletToPetToken[_msgSender()] == 0, "pet already equiped");
        walletToPetToken[_msgSender()] = idPet;
    }

    function dissociatePetFromWallet(uint256 idPet) external onlyEOA noReentrency {
        require(ownerOf(idPet) == _msgSender(), "not your token");
        walletToPetToken[_msgSender()] = 0;
    }

    function associatePetToNft(uint256 idPet, uint256 idNFT) external onlyEOA noReentrency { //CHECK ONLY ADVENTURER
        require(skeleton.ownerOf(idNFT) == _msgSender() && ownerOf(idPet) == _msgSender(), "not your token");
        require(petTokenToRangerToken[idPet] == 0, "nft already has pet");
        require(rangerTokenToPetToken[idNFT] == 0, "pet already equiped");
        require(isAdventurer(idNFT), "You can only associate a pet to a ranger.");

        petTokenToRangerToken[idPet] = idNFT;
        rangerTokenToPetToken[idNFT] = idPet;
    }

    function dissociatePetFromNft(uint256 idPet, uint256 idNFT) external onlyEOA noReentrency {
        require(skeleton.ownerOf(idNFT) == _msgSender() && ownerOf(idPet) == _msgSender(), "not your token");
        petTokenToRangerToken[idPet] = 0;
        rangerTokenToPetToken[idNFT] = 0;
    }

      function renewSeed(uint256 old) internal view returns(uint256 seed){
        seed = uint256(keccak256(abi.encodePacked(old, block.timestamp, ordersSettled)));
    }

    /** RENDER */

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return attributesPets.tokenURI(tokenId, petTokenToPetId[tokenId]);
    }

    /**
     * allows owner to withdraw funds from minting
     */
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdrawMoney() internal {
        devAddress.transfer((getBalance()*95)/100);
        AdminWallet.transfer(getBalance());
    }

    function withdrawToOwner() external onlyController {
        payable(owner()).transfer(getBalance());
    }

    /**
     * enables owner to pause / unpause minting
     */
    function setPaused(bool _paused) external onlyController {
        if (_paused) _pause();
        else _unpause();
    }

    function isAdventurer(uint256 tokenId)
        public
        view
        returns (bool adventurer)
    {
        (adventurer, , , , , , , , , ) = skeleton.tokenTraits(tokenId);
    }

    function setLimitedPed(uint8 _petId, uint256 _start, uint256 _end, uint256 _limitedMintGemPrice, uint256 _limitedMintAvaxPrice) external onlyController  {
        limitedPetId = _petId;
        limitedMintStart = _start;
        limitedMintEnd = _end;
        limitedMintGemPrice = _limitedMintGemPrice;
        limitedMintAvaxPrice = _limitedMintAvaxPrice;
    }

    function setAttributesPets(address _attributesPets) public onlyController {
        attributesPets = AttributesPets(_attributesPets);
    }

    function setGem(address _gem) external onlyController {
        gem = IGEM(_gem);
    }

    // returns the atributes (if they exists) of the pet associated to a NFT from Skeleton.sol
    function getBoostToken(uint256 tokenId) public view returns(AttributesPets.Boost memory){
        uint256 petToken = rangerTokenToPetToken[tokenId];
        uint8 petId = petTokenToPetId[petToken];
        return attributesPets.getBoost(petId);
    }

    // returns the atributes (if they exists) of the pet associated to a wallet
    function getBoostWallet(address wallet) public view returns(AttributesPets.Boost memory){
        return getBoostToken(walletToPetToken[wallet]);
    }

    function setMaxTokens(uint256 _MAX_TOKENS) public onlyController {
        MAX_TOKENS = _MAX_TOKENS;
    }

    function setSkeleton(address _skeleton) public onlyController {
        skeleton = Skeleton(_skeleton);
    }

    function updatePetsByRarity() external onlyController {
        for (uint8 i = 0; i < nbOfRarities; i++) {
            delete petsByRarity[i];
        }
        uint256 numberOfPets = attributesPets.numberOfPets();
        for (uint8 i = 1; i <= numberOfPets; i++) {
            uint8 rarity = attributesPets.getAttributes(i).rarity;
            if (rarity < 5) petsByRarity[rarity].push(i);
        }
    }
}
//SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./IRouble.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./IRandom.sol";

contract Characters is ERC721Enumerable, Ownable, Pausable{
    

    // SECTION STRUCTS _________________________________________________________________________________________________

    /* NOTE ➡️  There are 4 normal classes: Military, Medic, Scavenger, Spy
            ➡️  And 2 special classes     : Juggernaut, Ninja
            Each class will have 5 unique accesories, */

    struct tokenTraits {
        uint8 class;
        uint8 rarity;
        uint8 weapon;
        uint8 backpack;
        uint8 head;
        uint8 upperbody;
        uint8 lowerbody;
    }
            
    //!SECTION STRUCTS -------------------------------------------------------------------------------------------------

    
    // SECTION MAPPINGS  _______________________________________________________________________________________________
    
    mapping(uint    => tokenTraits) public traitsData;   // ➡️ Maps to struct containing tokenid info
    mapping(address => bool)        public whitelisted;   // ➡️ Indicates if this address is whitelisted
    mapping(address => uint8)       public usedwl;        // ➡️ Indicates how many mints "address" executed.

    //!SECTION MAPPINGS  -----------------------------------------------------------------------------------------------


    // SECTION VARIABLES _______________________________________________________________________________________________

    uint16 special_minted;


    uint16 soldier_minted;    
    // ↪ Balanced reward, balanced chances of returning something      ➡️ ID = 0
    uint16 medic_minted;      
    // ↪ Increases chances of returning something, decreases reward    ➡️ ID = 1
    uint16 scavenger_minted;  
    // ↪ Increases reward, decreases chances of returning              ➡️ ID = 2
    uint16 spy_minted;        
    // ↪ Decreased reward, decreased time to return                    ➡️ ID = 3
    uint16 juggernaut_minted; 
    // ↪ REVIEW                                                        ➡️ ID = 4
    uint ninja_minted;      
    // ↪ REVIEW                                                        ➡️ ID = 5

    // totalmints = totalorders of characters.sol

    uint    premintPeriod;
    uint    premintOver;
    uint    maxPremints;
    uint    wlPeriod;
    uint    wlOver;
    uint    maxUsingCurrency;
    uint    maxPayable;
    uint    mintPrice = 1.5 ether;
    uint    wlMintPrice = 1.25 ether;


    //!SECTION VARIABLES -----------------------------------------------------------------------------------------------

    // SECTION EVENTS __________________________________________________________________________________________________

    event orderClaimed(address owner, uint tokenId, bool special, tokenTraits traits);
    
    //!SECTION EVENTS --------------------------------------------------------------------------------------------------


    // SECTION REFERENCES ______________________________________________________________________________________________

    IRouble  public rouble;
    IRandom  public random;

    //!SECTION REFERENCES ----------------------------------------------------------------------------------------------


    // SECTION CONSTRUCTOR _____________________________________________________________________________________________

    constructor( 
        address _rouble,
        address _random,
        uint16 _maxsupply,
        uint16 _maxUsingCurrency
    )   ERC721(  
        "Extract",
        "ETT"
    ) {
        //FIXME ➡️ Admin Wallet
        random = IRandom(_random);
        rouble  = IRouble(_rouble);     //rouble = rouble.sol sc address
        maxPayable = _maxsupply;
        maxUsingCurrency = _maxUsingCurrency;
    }

    //!SECTION CONSTRUCTOR ---------------------------------------------------------------------------------------------

    // SECTION VIEW FUNCTIONS __________________________________________________________________________________________

    function getTokenTraits(uint tokenID) external view returns (tokenTraits memory user) {
        user = traitsData[tokenID];
        return user;
    }

    function payabletokens() external view returns (uint) {
        return maxPayable;
    }

    function getCharacter(uint id) external view returns (
        uint8 class,
        uint8 rarity,
        uint8 weapon,
        uint8 backpack,
        uint8 head,
        uint8 upperbody,
        uint8 lowerbody
    ) {
        return (traitsData[id].class,
                traitsData[id].rarity,
                traitsData[id].weapon,
                traitsData[id].backpack,
                traitsData[id].head,
                traitsData[id].upperbody,
                traitsData[id].lowerbody
        );
    }

    //!SECTION VIEW FUNCTIONS ------------------------------------------------------------------------------------------


    // SECTION EXTERNAL FUNCTIONS ______________________________________________________________________________________

    function preparemintV2(uint16 amount) external payable whenNotPaused {

        //NOTE ⋯ We wont be checking confirmed mints, only confirmed orders. If someone orders a mint and has payed for it, it will be
        // counted as a mint, even if he hasn't claimed his mint yet. This makes it easier to know the price of each order.

        //NOTE ⋯ People will pay when they order something, not when they claim, otherwise it can overflow orders before given time.


        //ROLE ⤵ First we check that we reached premint set time first.
        require(block.timestamp >= premintPeriod,
            "Sorry, premint time hasn't started yet");

        //ROLE ⤵ Makes sure that we do not go beyond max payable tokens. 
        //("Payable" means that we can pay to mint, special mints are not payable)
        require (random.totalOrders() + amount <= maxPayable,
            "Sorry, the amount of tokens you want to mint outreaches the max supply");

        //ROLE ⤵ If premint is not over, and we do not go beyond max mints during premint   PREMINT PERIOD
        if (block.timestamp <= premintOver || amount + random.totalOrders() <= maxPremints) {
            require(msg.value >= amount * mintPrice,
            "You haven't sent enough $AVAX");
        }

        //ROLE ⤵ If premint is over and whitelist period is not over                        WHITELIST PERIOD
        if (block.timestamp >= premintOver || block.timestamp >= wlPeriod || block.timestamp <= wlOver ) {
            require(msg.value >= amount * wlMintPrice,
            "You haven't sent enough $AVAX");
            require (usedwl[tx.origin] + amount <= 3,
            "Whitelisted can only mint 3 tokens");
        }

        //ROLE ⤵ If premint is over and whitelist period is over                            NORMAL PERIOD
        if (block.timestamp >= wlOver) {     

            //ROLE ⤵ If gen0 not sold out, check user payed enough $AVAX
            if (random.totalOrders() < maxUsingCurrency) {
                require(random.totalOrders() + amount <= maxUsingCurrency,
                "Sorry, no more tokens left to buy with $AVAX");
                require(msg.value >= amount * mintPrice,
                "You haven't sent enough $AVAX");
            
            //ROLE ⤵ If gen0 sold out, make sure to remove tokens from msg.sender
            } else {
                require(msg.value == 0,
                "Mint is now with $ROUBLE, do not send $AVAX");
                uint toPay;
                uint orders = random.totalOrders();
                for (uint i; i < amount; i++){
                    orders++;
                    toPay += roubleToPay(orders);
                }
                require(rouble.balanceOf(msg.sender) >= toPay,
                "Sorry you don't have enough $ROUBLE");
                rouble.burn(msg.sender, toPay);
            }
        }

        for (uint i; i < amount; i++) {
            random.addOrder(msg.sender);
        }

    }

    function specialMint(address owner, uint _seed) external {

        require((rouble.isController(_msgSender())), "Only controllers can execute this function!!!");
        uint seed = uint256(keccak256(abi.encodePacked(_seed)));
        
        special_minted++;
        create(special_minted, seed, true); 

        uint specialId = uint(special_minted);

        if (traitsData[specialId].class == 4){juggernaut_minted++;}
        else {ninja_minted++;}

        _safeMint(owner, specialId);

        emit orderClaimed(owner, specialId, true, traitsData[specialId]);

    }

    function claimMints(uint32[] memory orders) external whenNotPaused {
        for (uint32 i; i < orders.length; i++) {

            uint32 orderId = orders[i];

            require(random.viewOwner(orderId) == msg.sender,
            "You did not place this order, nor got aprooved to claim it");
            require(!random.orderClaimed(orderId),
            "This order has already been claimed!!");
            require(random.seedReady(orderId),
            "This order is not ready yet");

            _tokenmint(random.uniqueSeed(orderId), orderId);
        }
    }


    //!SECTION EXTERNAL FUNCTIONS --------------------------------------------------------------------------------------


    // SECTION CORE MINT _______________________________________________________________________________________________
    
    function _tokenmint(uint _seed, uint _tokenId) private {  
        uint endprice = 0;
        create(_tokenId, _seed, false);
        _safeMint(_msgSender(), _tokenId);
        whichMinted(_tokenId);
        endprice += roubleToPay(_tokenId);

        emit orderClaimed(msg.sender, _tokenId , false, traitsData[_tokenId]);
    }

    
    function whichMinted(uint _tokenId) private {
        if      (traitsData[_tokenId].class == 0) soldier_minted++;
        else if (traitsData[_tokenId].class == 1) medic_minted++;
        else if (traitsData[_tokenId].class == 2) scavenger_minted++;
        else if (traitsData[_tokenId].class == 3) spy_minted++;
    }

    function roubleToPay(uint _tokenId) public view returns (uint256) {
        // REVIEW ➡️ Change prices
        if (_tokenId <= maxUsingCurrency) return 0;
        if (_tokenId <= (maxPayable * 2) / 5) return 20000;
        if (_tokenId <= (maxPayable * 4) / 5) return 40000;
        return 80000 ether;
    }
    
    //!SECTION  CORE MINT-----------------------------------------------------------------------------------------------

    
    // SECTION ONLYOWNER FUNCTIONS _____________________________________________________________________________________

    function setPremint(uint period, uint over) external onlyOwner {
        premintPeriod = period;
        premintOver   = over;
    }

    function setWhitelist(uint period, uint over) external onlyOwner {
        wlPeriod    = period;
        wlOver      = over;
    }

    // ⤵ Allows to withdraw contract balance
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    //!SECTION ONLYOWNER FUNCTIONS -------------------------------------------------------------------------------------


    // SECTION  CHARACTER CREATION______________________________________________________________________________________

    function create(uint tokenID, uint seed, bool special) private {
        // NOTE Creates new Character
        tokenTraits memory object = _assignTraits(seed, special);   // ➡️ Assigns traits to object variable of type tokenTraits object
        traitsData[tokenID] = object;                                 // ➡️ We map the object information to the ID of the NFT created
    }


    function _assignTraits(uint seed, bool special) private pure returns (tokenTraits memory temp) {
        //NOTE ➡️ This will choose what kind of character we are creating.
        if (special) {
            if (seed % 100 < 50) {temp.class = 4;}
            else {temp.class = 5;}
        }
        else {
            temp.class      = _assignTrait(seed);// Class ID assigned
            seed >> 16;
        }
        temp.weapon     = _assignTrait(seed);    // Weapon ID assigned
        seed >>= 16;
        temp.backpack   = _assignTrait(seed);    // Backpack ID assigned
        seed >>= 16;
        temp.head       = _assignTrait(seed);    // Head ID assigned
        seed >>= 16;
        temp.upperbody  = _assignTrait(seed);    // Upperbody ID assigned
        seed >>= 16;
        temp.lowerbody  = _assignTrait(seed);    // Lowerbody ID assigned
        seed >>= 16;
        temp.rarity     = _assignRarity(seed);    // Rarity ID assigned
        
    }

    function _assignRarity(uint seed) private pure returns (uint8) {
        if (seed % 100 < 5) {
            return 3;
        }
        if (seed % 100 < 10) {
            return 2;
        }
        if (seed % 100 < 30) {
            return 1;
        }
        else {return 0;}

    }


    function _assignTrait(uint seed) private pure returns (uint8 number) { 
        if (seed % 100 < 5) {
            return 4;
        }
        if (seed % 100 < 15) {
            return 3;
        }
        if (seed % 100 < 50) {
            return 2;
        }
        else {
            seed = uint(keccak256(abi.encodePacked(seed, "common")));
            if (seed % 100 < 50) {return 1;}
            else {return 0;}
        }
    }

}

    //!SECTION  CHARACTER CREATION--------------------------------------------------------------------------------------
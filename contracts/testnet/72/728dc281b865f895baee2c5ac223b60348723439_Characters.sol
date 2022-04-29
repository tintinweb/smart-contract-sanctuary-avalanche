//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./IRouble.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract Characters is ERC721Enumerable, Ownable, Pausable {
    

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

    struct orderTraits {

        uint32  onBlock;
        address owner;
    }
            
    //!SECTION STRUCTS -------------------------------------------------------------------------------------------------

    
    // SECTION MAPPINGS  _______________________________________________________________________________________________
    
    mapping (uint    => tokenTraits) public traitsData;    // ➡️ Maps tokenId to its traits
    mapping (uint    => orderTraits) public orderData;     // ➡️ Maps tokenId to orderData for claiming purposes
    mapping (address => bool)        public whitelisted;   // ➡️ Indicates if this address is whitelisted
    mapping (address => uint8)       public usedwl;        // ➡️ Indicates how many whitelist mints this "address" used.

    //!SECTION MAPPINGS  -----------------------------------------------------------------------------------------------


    // SECTION VARIABLES Z

    uint16 public special_minted;
    // ↪ How many special tokens have been minted so far


    uint16 public soldier_minted;    
    // ↪ Balanced reward, balanced chances of returning something      ➡️ ID = 0
    uint16 public medic_minted;      
    // ↪ Increases chances of returning something, decreases reward    ➡️ ID = 1
    uint16 public scavenger_minted;  
    // ↪ Increases reward, decreases chances of returning              ➡️ ID = 2
    uint16 public spy_minted;        
    // ↪ Decreased reward, decreased time to return                    ➡️ ID = 3
    uint16 public juggernaut_minted; 
    // ↪ REVIEW                                                        ➡️ ID = 4
    uint16 public ninja_minted;      
    // ↪ REVIEW                                                        ➡️ ID = 5


    uint32 public totalMints;

    uint  public premintPeriod;               // ➡️ When does premint start
    uint  public premintOver;                 // ➡️ When does premint end
    uint  public maxPremints;                 // ➡️ How many tokens can be minted during premint period
    uint  public wlPeriod;                    // ➡️ When does whitelist minting start
    uint  public wlOver;                      // ➡️ When does whitelist mint end
    uint  public maxUsingCurrency;            // ➡️ How many tokens can we buy with $AVAX
    uint  public maxPayable;                  // ➡️ How many tokens can we mint paying
    uint  public mintPrice   = 1.5 ether;       // ➡️ Price for normal mint
    uint  public wlMintPrice = 1.25 ether;    // ➡️ Price for whitelisted mints


    //!SECTION VARIABLES -----------------------------------------------------------------------------------------------

    // SECTION EVENTS __________________________________________________________________________________________________

    event orderPlaced (address owner, uint orderId);

    event orderClaimed(address owner, uint tokenId, bool special, tokenTraits traits);
    
    //!SECTION EVENTS --------------------------------------------------------------------------------------------------


    // SECTION REFERENCES ______________________________________________________________________________________________

    IRouble  public rouble;

    //!SECTION REFERENCES ----------------------------------------------------------------------------------------------


    // SECTION CONSTRUCTOR _____________________________________________________________________________________________

    constructor( 
        address _rouble,
        uint16 _maxsupply,
        uint16 _maxUsingCurrency
    )   ERC721(  
        "Strife",
        "STF"
    ) {
        //FIXME ➡️ Admin Wallet
        rouble  = IRouble(_rouble);     //rouble = rouble.sol sc address
        maxPayable = _maxsupply;
        maxUsingCurrency = _maxUsingCurrency;
    }

    //!SECTION CONSTRUCTOR ---------------------------------------------------------------------------------------------

    // SECTION VIEW FUNCTIONS __________________________________________________________________________________________

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

    function preparemintV2(uint8 amount) external payable whenNotPaused {

        //NOTE ⋯ We wont be checking confirmed mints, only confirmed orders. If someone orders a mint and has payed for it, it will be
        // counted as a mint, even if he hasn't claimed his mint yet. This makes it easier to know the price of each order.

        //NOTE ⋯ People will pay when they order something, not when they claim, otherwise it can overflow orders before given time.


        //ROLE ⤵ First we check that we reached premint set time first.
        require(block.timestamp >= premintPeriod,
            "Sorry, premint time has not started yet");

        //ROLE ⤵ Makes sure that we do not go beyond max payable tokens. 
        //("Payable" means that we can pay to mint, special mints are not payable)
        require (totalMints + amount <= maxPayable,
            "Sorry, the amount of tokens you want to mint outreaches the max supply");

        //ROLE ⤵ If premint is not over, and we do not go beyond max mints during premint   PREMINT PERIOD
        if (block.timestamp <= premintOver || totalMints + amount <= maxUsingCurrency) {
            require(msg.value >= amount * mintPrice,
            "You have not sent enough $AVAX");
        }

        //ROLE ⤵ If premint is over and whitelist period is not over                        WHITELIST PERIOD
        if (block.timestamp >= premintOver || block.timestamp >= wlPeriod || block.timestamp <= wlOver ) {
            require(msg.value >= amount * wlMintPrice,
            "You have not sent enough $AVAX");
            require (usedwl[tx.origin] + amount <= 3,
            "Whitelisted can only mint 3 tokens");
        }

        //ROLE ⤵ If premint is over and whitelist period is over                            NORMAL PERIOD
        if (block.timestamp >= wlOver) {     

            //ROLE ⤵ If gen0 not sold out, check user payed enough $AVAX
            if (totalMints < maxUsingCurrency) {

                require(totalMints + amount <= maxUsingCurrency,
                "Sorry, no more tokens left to buy with $AVAX");
                require(msg.value >= amount * mintPrice,
                "You have not sent enough $AVAX");
            

            //ROLE ⤵ If gen0 sold out, make sure to remove tokens from msg.sender
            } else {
                
                require(msg.value == 0,
                "Mint is now with $ROUBLE, do not send $AVAX");
                uint  toPay;
                uint32 memMints = totalMints;
                for (uint i; i < amount; i++){
                    memMints++;
                    toPay += roubleToPay(memMints);
                }
                rouble.burn(msg.sender, toPay);
            }
        }

        _manageOrders(amount);

    }

    function specialMint (
        address owner, 
        uint _seed
    ) 
    external {

        require((rouble.isController(_msgSender())), "Only controllers can execute this function!!!");
        uint seed = uint256(keccak256(abi.encodePacked(_seed)));
        
        special_minted++;

        uint specialId = uint(special_minted);
        create (specialId, seed, true); 

        if (traitsData[specialId].class == 4){juggernaut_minted++;}
        else {ninja_minted++;}

        _safeMint(owner, specialId);

        emit orderClaimed(owner, specialId, true, traitsData[specialId]);

    }

    function claimMints (
        uint32[] memory orders
    ) 
    external 
    whenNotPaused {

        for (uint i; i < orders.length; i++) {

            orderTraits storage order = orderData[orders[i]];

            require (order.owner == msg.sender, 
            "You are not the owner of this order!");
            require (_enoughBlocks(order.onBlock),
            "Not enough blocks have been validated, please wait a while");

            _tokenmint (_hashCalc(order.onBlock), orders[i]);
        }
    }



    //!SECTION EXTERNAL FUNCTIONS --------------------------------------------------------------------------------------


    // SECTION CORE MINT _______________________________________________________________________________________________

    function _manageOrders(
        uint8 _amount
    )
    private {

        for (uint i; i < _amount; i++) {

            totalMints++;
            orderTraits storage order = orderData[totalMints];

            order.onBlock = uint32(block.number);
        }
    }



    //ROLE ➡️ Handles the creation of the token
    function _tokenmint (
        uint _seed, 
        uint _tokenId
    ) 
    private {  

        create(_tokenId, _seed, false);
        _safeMint(_msgSender(), _tokenId);
        whichMinted(_tokenId); 

        emit orderClaimed(msg.sender, _tokenId , false, traitsData[_tokenId]);
    }

    //ROLE ➡️ Returns a seed calculated from the hash of 3 blocks that were not validated yet when the order was placed.
    function _hashCalc (uint32 onBlock)
    private
    view
    returns (uint) {

        bytes32 firstBlock   = blockhash (onBlock);
        bytes32 secondBlock  = blockhash (onBlock + 2);
        bytes32 thirdBlock   = blockhash (onBlock + 4);



        return uint(
            keccak256(
                abi.encodePacked(
                    firstBlock, 
                    secondBlock, 
                    thirdBlock
                )
            )
        );
    }

    //ROLE ➡️ Checks if there is at least 20 block confirmations after the order has been placed.
    function _enoughBlocks(uint32 onBlock)
    private
    view
    returns (bool) {

        uint32 currentBlock = uint32(block.number);

        if (currentBlock - onBlock > 20) {return true;}
        else                             {return false;}
    }

    
    function whichMinted (
        uint _tokenId
    ) 
    private {
        
        if      (traitsData[_tokenId].class == 0) soldier_minted++;
        else if (traitsData[_tokenId].class == 1) medic_minted++;
        else if (traitsData[_tokenId].class == 2) scavenger_minted++;
        else if (traitsData[_tokenId].class == 3) spy_minted++;
    }

    function roubleToPay (
        uint _tokenId
    ) 
    public 
    view 
    returns (uint256) {

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
        // NOTE ➡️ Creates new Character
        tokenTraits memory object = _assignTraits(seed, special);     // ➡️ Assigns traits to object variable of type tokenTraits object
        traitsData[tokenID] = object;                                 // ➡️ We map the object information to the ID of the NFT created
    }


    function _assignTraits  (
        uint seed, 
        bool special        
    ) 
    private 
    pure 
    returns (tokenTraits memory temp) {

        //NOTE ➡️ This will choose what kind of character we are creating.
        if (special) {
            if (seed % 100 < 50) {temp.class = 4;}
            else {temp.class = 5;}
        }
        else {
            temp.class      = _assignClass(seed); // Class ID assigned
            seed >>= 16;
        }

        temp.weapon     = _assignTrait(seed);     // Weapon ID assigned
        seed >>= 16;
        temp.backpack   = _assignTrait(seed);     // Backpack ID assigned
        seed >>= 16;
        temp.head       = _assignTrait(seed);     // Head ID assigned
        seed >>= 16;
        temp.upperbody  = _assignTrait(seed);     // Upperbody ID assigned
        seed >>= 16;
        temp.lowerbody  = _assignTrait(seed);     // Lowerbody ID assigned
        seed >>= 16;
        temp.rarity     = _assignRarity(seed);    // Rarity ID assigned
        
    }

    function _assignClass(
        uint seed
    ) 
    private
    pure 
    returns (uint8) {

        if (seed % 100 < 15) {return 3;}
        if (seed % 100 < 35) {return 2;}
        if (seed % 100 < 65) {return 1;}
        else {return 0;}

    }


    function _assignRarity (
        uint seed
    ) 
    private 
    pure 
    returns (uint8) {

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


    function _assignTrait(
        uint seed
    ) 
    private 
    pure 
    returns (uint8 number) { 

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
            seed >>= 16;
            if (seed % 100 < 50) {return 1;}
            else {return 0;}
        }
    }
}

    //!SECTION  CHARACTER CREATION--------------------------------------------------------------------------------------
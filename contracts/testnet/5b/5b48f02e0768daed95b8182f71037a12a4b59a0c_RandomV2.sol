// SPDX-License-Identifier: MIT

import "./Ownable.sol";
import "./Pausable.sol";
import "./IRouble.sol";

pragma solidity ^0.8.2;

contract RandomV2 is Ownable, Pausable {


    // SECTION VARIABLES _______________________________________________________________________________________________

    uint16 a_forcedStamp;
    uint16 c_forcedStamp;

        // SECTION  CHARACTERS.SOL _____________________________________________________________________________________

        uint8   toFill = 1;
        uint16  c_totalSeeds;
        uint16  c_stampRate;
        uint32  c_totalOrders;

        //!SECTION  CHARACTERS.SOL -------------------------------------------------------------------------------------
        // SECTION  ADVENTURE.SOL ______________________________________________________________________________________

        uint8   a_totalSeeds;
        uint8   a_lastDigits;
        uint16  a_stampRate;

        //!SECTION  ADVENTURE.SOL --------------------------------------------------------------------------------------


    //!SECTION VARIABLES -----------------------------------------------------------------------------------------------


    // SECTION STRUCTS _________________________________________________________________________________________________

    //NOTE ⋯ Exclusively for characters.sol only
    struct orderTraits {
        uint8    differences;
        uint16   onSeed;
        uint32   stamp;
    }

    //NOTE ⋯ Struct used for both adventure.sol and characters.sol
    struct blockTraits {
        bool   ready;
        uint8  differences;
        uint8  refreshBlock; 
        uint16 requests;
        uint32 onBlock;
        uint32 stamp;
    }

    //!SECTION STRUCTS -------------------------------------------------------------------------------------------------


    // SECTION MAPPINGS  _______________________________________________________________________________________________


        // SECTION  CHARACTERS.SOL _____________________________________________________________________________________

        mapping (uint16  => blockTraits) public c_blockData;
        mapping (uint32  => orderTraits) public orderData;
        mapping (uint32 =>  address)     public orderOwner;

        //!SECTION  CHARACTERS.SOL -------------------------------------------------------------------------------------
        // SECTION  ADVENTURE.SOL ______________________________________________________________________________________

        mapping (uint8 => blockTraits) public a_blockData;

        //!SECTION  ADVENTURE.SOL --------------------------------------------------------------------------------------


    //!SECTION MAPPINGS  -----------------------------------------------------------------------------------------------

    // SECTION EVENTS __________________________________________________________________________________________________

    event orderPlaced(address from, uint16 onSeed, uint32 orderId);
    //ROLE ↪ New order placed from "from", assigned to seed "onSeed", of id "orderId" ⋯

    event c_seedGen(uint16 seedId);
    //ROLE ↪ Seed of id "seedId" generated for Characters.sol EXCLUSIVELY ⋯

    event a_seedGen(uint8  seedId);
    //ROLE ↪ Seed of id "seedId" generated for Adventure.sol EXCLUSIVELY ⋯

    //!SECTION EVENTS --------------------------------------------------------------------------------------------------
    

    // SECTION REFERENCES ______________________________________________________________________________________________

    IRouble public rouble; //ROLE ➡️ Used only to check for controllers address

    //!SECTION REFERENCES ----------------------------------------------------------------------------------------------


    // SECTION CONSTRUCTOR _____________________________________________________________________________________________

    constructor(address _rouble) {
        rouble      = IRouble (_rouble);
        c_stampRate = 20 seconds;
        a_stampRate = 1.5 hours;
    }

    //!SECTION CONSTRUCTOR ---------------------------------------------------------------------------------------------

    // SECTION VIEW FUNCTIONS __________________________________________________________________________________________

            // SECTION  CHARACTERS.SOL _____________________________________________________________________________________

            //ROLE ⋯ Returns order data as a struct
            function cV_orderData(uint32 orderId)
            external
            view
            returns (orderTraits memory) 
            {return orderData[orderId];}

            //ROLE ⋯ Returns the seed data as a struct
            function cV_seedData(uint16 seedId) 
            external
            view
            returns (blockTraits memory) 
            {return c_blockData[seedId];}

            //ROLE ⋯ Returns the total orders placed
            function cV_totalOrders()
            external
            view
            returns (uint32) 
            {return c_totalOrders;}

            //ROLE ⋯ Returns the owner of the order id
            function cV_orderOwner(uint32 orderId)
            external
            view
            returns (address)
            {return orderOwner[orderId];}

            //ROLE ⋯ Returns the seed as a hash
            function cV_seed(uint16 seedId)
            external
            view
            returns (uint256) 
            {return cI_genSeed(seedId);}

            function cV_orderReady(uint32 orderId)
            external
            view
            returns (bool)
            {return c_blockData[orderData[orderId].onSeed].ready;}

            //ROLE ⋯ Returns an unique seed depending on the order id
            function cV_uniqueSeed(uint32 orderId)
            external
            view
            returns (uint256) 
            {return cI_uniqueSeed(orderId);}
    
            //!SECTION  CHARACTERS.SOL -------------------------------------------------------------------------------------
            // SECTION  ADVENTURE.SOL ______________________________________________________________________________________

            //ROLE ⋯ Returns the data of a seed as a struct
            function aV_seedData(uint8 seedId)
            external
            view
            returns (blockTraits memory) 
            {return a_blockData[seedId];}

            //ROLE ⋯ Returns the seed as a hash
            function aV_seed(uint8 seedId)
            external
            view
            returns (uint) 
            {return aI_genSeed(seedId);}

            function aV_orderReady(uint8 seedId)
            external
            view
            returns (bool)
            {return a_blockData[seedId].ready;}

            //ROLE ⋯ Returns an unique seed depending on the token id
            function aV_uniqueSeed(uint8 seedId, uint tokenId)
            external
            view
            returns (uint) 
            {return aI_uniqueSeed(seedId, tokenId);}
    
            //!SECTION  ADVENTURE.SOL --------------------------------------------------------------------------------------

    //!SECTION VIEW FUNCTIONS ------------------------------------------------------------------------------------------

    // SECTION EXTERNAL FUNCTIONS ______________________________________________________________________________________

    function forceUpdates() external {

        require(rouble.isController(msg.sender),
        "ONLY CONTROLLERS CAN EXECUTE THIS FUNCTION!!!");
        _updateBlock(true, true, true);

    }

    function manageRequests(
        address from, 
        bool    c_addOrder, 
        bool    a_addOrder, 
        uint8   amount 
    ) external {

        require(rouble.isController(msg.sender),
        "ONLY CONTROLLERS CAN EXECUTE THIS FUNCTION!!!");

        if (c_addOrder) {_characterOrder(amount, from);}
        if (a_addOrder) {_adventureOrder(amount);}

    }


    //!SECTION EXTERNAL FUNCTIONS --------------------------------------------------------------------------------------


    // SECTION INTERNAL FUNCTIONS ______________________________________________________________________________________


    //ROLE ➡️ UPDATES THE BLOCK IF NECESSARY, IF ITS A FORCED UPDATE, EXTRA TIME IS NEEDED FOR SECURITY PRECAUTIONS
    function _updateBlock(bool c_block, bool a_block, bool forced) private {

        uint16 extraAdventure;
        uint16 extraCharacters;
        if (forced) {
            extraAdventure  = a_forcedStamp;
            extraCharacters = c_forcedStamp;
        }
        
        if (c_block) {
            blockTraits storage currentBlock = c_blockData[c_totalSeeds];

            //NOTE ➡️ IF ITS TIME TO UPDATE
            if (currentBlock.stamp + c_stampRate + extraCharacters >= block.timestamp) {  
                
                currentBlock.ready = true;
                currentBlock.differences = uint8(currentBlock.differences + (block.timestamp % 100));
                currentBlock.refreshBlock = uint8(block.number % 100);
                emit c_seedGen(c_totalSeeds);

                unchecked{c_totalSeeds++;}

                c_blockData[c_totalSeeds].onBlock = uint32(block.number % 100);
                c_blockData[c_totalSeeds].stamp   = uint32(block.timestamp);

                if (c_blockData[c_totalSeeds].ready) {_resetBlock(true);}
            }
        }

        if (a_block) {
            
            blockTraits storage currentBlock = c_blockData[a_totalSeeds];
            
            //NOTE ➡️ IF ITS TIME TO UPDATE
            if (currentBlock.stamp + a_stampRate + extraAdventure >= block.timestamp) {  
                
                currentBlock.ready = true;
                currentBlock.differences = uint8(currentBlock.differences + (block.timestamp % 100));
                currentBlock.refreshBlock = uint8(block.number % 100);
                emit a_seedGen(a_totalSeeds);
    
                unchecked{a_totalSeeds++;}

                a_blockData[a_totalSeeds].onBlock = uint32(block.number % 100);
                a_blockData[a_totalSeeds].stamp   = uint32(block.timestamp);

                if (a_blockData[a_totalSeeds].ready) {_resetBlock(false);}
            }
        }
    }

    //ROLE ➡️ IF WE OVERFLOWED THE MAX AMOUNT OF SEEDS WE CAN HAVE, WE RESET THEM.
    function _resetBlock(bool character) private {
        
        if (character) {
            blockTraits storage blockToChange = c_blockData[c_totalSeeds];
            blockToChange.ready = false;
            blockToChange.requests = 0;
        } else {
            blockTraits storage blockToChange = a_blockData[a_totalSeeds];
            blockToChange.ready = false;
            blockToChange.requests = 0;
        }
    }

        // SECTION  CHARACTERS.SOL _____________________________________________________________________________________


        //ROLE ➡️ ADD ORDERS AS WELL AS CHECK TO CHANGE BLOCKS AND FILL PAST ORDERS
        function _characterOrder(uint8 amount, address from) private {

            //NOTE ➡️ FILL ORDERS BEFORE
            for (uint32 i; i < toFill; i++) {
                orderData[c_totalOrders - i].differences = uint8(
                    ((block.timestamp + i * 2)- orderData[c_totalOrders - i].stamp) % 100);
            }


            //NOTE ➡️ SETS FILL FOR NEXT ORDER
            toFill = uint8(amount);


            //NOTE ➡️ CHECK IF WE NEED TO GENERATE A NEW BLOCK
            _updateBlock(true, true, false);


            //NOTE ➡️ ADD ORDERS
            for (uint i; i < amount; i++) {
                unchecked{c_totalOrders++;}
                orderTraits storage Order = orderData[c_totalOrders];
                blockTraits storage Block = c_blockData[c_totalSeeds];
                Order.onSeed = c_totalSeeds;
                Order.stamp  = uint32(block.timestamp);
                orderOwner[c_totalOrders] = from;
                
                Block.differences = uint8(Block.differences + (block.timestamp % 100));
                unchecked {Block.requests++;}
                emit orderPlaced(from, c_totalSeeds, c_totalOrders);
            }
        }


        //ROLE ➡️ SINCE SEEDS ARE NEVER STORED JUST THE PARAMETERS, THIS RETURNS A SEED WITH THE PARAMETERS STORED
        function cI_genSeed(uint16 seedId) 
        private 
        view 
        returns (uint) {
            blockTraits memory seed = c_blockData[seedId];
            return uint(
                keccak256(
                    abi.encodePacked(
                        seed.differences, 
                        seed.refreshBlock, 
                        seed.requests
                    )
                )
            );
        }

        function cI_uniqueSeed(uint32 orderId)
        private
        view
        returns (uint) {
            
            orderTraits memory order = orderData[orderId];

            uint seed = uint(
                keccak256(
                    abi.encodePacked(
                        cI_genSeed(order.onSeed),
                        orderId,
                        order.differences
                    )
                )
            );

            return seed;
        }

        //!SECTION  CHARACTERS.SOL -------------------------------------------------------------------------------------
        // SECTION  ADVENTURE.SOL ______________________________________________________________________________________

        function _adventureOrder(uint8 amount) private {
            blockTraits storage Block = a_blockData[a_totalSeeds];
            _updateBlock(true, true, false);
            Block.differences = uint8(Block.differences + (block.timestamp));
            Block.requests = uint16(amount);
        }

        //ROLE ➡️ SINCE SEEDS ARE NEVER STORED JUST THE PARAMETERS, THIS RETURNS A SEED WITH THE PARAMETERS STORED
        function aI_genSeed(uint8 seedId) 
        private 
        view 
        returns (uint) {
            blockTraits memory seed = a_blockData[seedId];
            return uint(
                keccak256(
                    abi.encodePacked(
                        seed.differences, 
                        seed.refreshBlock, 
                        seed.requests
                    )
                )
            );
        }

        function aI_uniqueSeed(uint8 seedId, uint tokenId)
        private
        view
        returns (uint) {

            uint seed = uint(
                keccak256(
                    abi.encodePacked(
                        aI_genSeed(seedId),
                        tokenId
                    )
                )
            );
            
            return seed;
        }


        //!SECTION  ADVENTURE.SOL --------------------------------------------------------------------------------------


    //!SECTION INTERNAL FUNCTIONS --------------------------------------------------------------------------------------

    // SECTION ONLYOWNER FUNCTIONS _____________________________________________________________________________________

    //ROLE ➡️ SETS STAMP RATE FOR BOTH ADVENTURE AND CHARACTERS
    function o_stampRate(uint16 chaStampRate, uint16 advStampRate)
    external
    onlyOwner {
        c_stampRate = chaStampRate;
        a_stampRate = advStampRate;
    }

    //ROLE ➡️ SETS FORCED STAMP 
    function o_forcedStamp(uint16 cForced, uint16 aForced)
    external
    onlyOwner {
        a_forcedStamp = aForced;
        c_forcedStamp = cForced;
    }

    function o_forceUpdate() 
    external
    onlyOwner
    {_updateBlock(true, true, false);}

    //!SECTION ONLYOWNER FUNCTIONS -------------------------------------------------------------------------------------

}
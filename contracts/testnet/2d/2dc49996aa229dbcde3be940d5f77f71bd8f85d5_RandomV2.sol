// SPDX-License-Identifier: MIT

import "./Ownable.sol";
import "./Pausable.sol";
import "./IRouble.sol";

pragma solidity ^0.8.13;

contract RandomV2 is Ownable, Pausable {


    // SECTION VARIABLES _______________________________________________________________________________________________

        // SECTION  CHARACTERS.SOL _____________________________________________________________________________________

        uint8   toFill = 1;
        uint16  c_totalSeeds;
        uint16  c_stampRate;
        uint32  c_totalOrders;

        //!SECTION  CHARACTERS.SOL -------------------------------------------------------------------------------------
        // SECTION  ADVENTURE.SOL ______________________________________________________________________________________

        uint8   a_totalSeeds;
        uint8   awaitingRate;
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
        bool   awaiting;        
        uint8  differences;     // The time between each transaction in this block
        uint8  extraRequests;   // Exclusively for adventure ⋯ Number of requests in second block confirmation
        uint8  refreshBlock;    // Block number when first block confirmation transaction went in
        uint16 requests;        // Number of requests before the first block confirmation
        uint32 onBlock;         // On which block.number was this block created
        uint32 stamp;           
    }   

    /* GENERAL NOTES 

       ⋯ EXPLANATION FOR "blockTraits" STRUCT

        bool ready
            For characters ➡️ If its ready, the block has been confirmed, seed is ready
            For adventure  ➡️ Block has been fully confirmed, first and second confirmation has been confirmed

        bool awaiting
            ⋯ Exclusively for adventure only ⋯

            If awaiting is false, we are still waiting on first block confirmation, if its true and "ready"
            is false, the we are waiting on second block confirmation, if its true and "ready" is true, 
            second confirmation went through and block is now ready for seed generation.
        
        uint32 stamp 

            For characters ➡️ Time on which block was created
            For adventure  ➡️ First update, time on which the block was created
                           ➡️ Second update, time on which we went through the first confirmation
        
    */

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

            //ROLE ⋯ Returns the total orders placed ➡️ USED IN IRANDOM
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

            //ROLE ⋯ Returns if an order is ready to be minted ➡️ USED IN IRANDOM
            function cV_orderReady(uint32 orderId)
            external
            view
            returns (bool)
            {return c_blockData[orderData[orderId].onSeed].ready;}

            //ROLE ⋯ Returns an unique seed depending on the order id ➡️ USED IN IRANDOM
            function cV_uniqueSeed(uint32 orderId)
            external
            view
            returns (uint256) 
            {return cI_uniqueSeed(orderId);}
    
            //!SECTION  CHARACTERS.SOL -------------------------------------------------------------------------------------
            // SECTION  ADVENTURE.SOL ______________________________________________________________________________________

            //ROLE ⋯ Returns the seed num on which we are right now
            function aV_totalSeeds()
            external
            view
            returns (uint8)
            {return a_totalSeeds;}

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

            //ROLE ⋯ Returns if this seed is ready ➡️ USED IN IRANDOM
            function aV_orderReady(uint8 seedId)
            external
            view
            returns (bool)
            {return a_blockData[seedId].ready;}

            //ROLE ⋯ Returns an unique seed depending on the token id ➡️ USED IN IRANDOM
            function aV_uniqueSeed(uint8 seedId, uint tokenId)
            external
            view
            returns (uint) 
            {return aI_uniqueSeed(seedId, tokenId);}
    
            //!SECTION  ADVENTURE.SOL --------------------------------------------------------------------------------------

    //!SECTION VIEW FUNCTIONS ------------------------------------------------------------------------------------------

    // SECTION EXTERNAL FUNCTIONS ______________________________________________________________________________________

    //ROLE ➡️ FURTHER CHECKS IF AN UPDATE IS NEED, 
    //THIS WILL BE USED FOR ANY KIND OF INTERACTION WITH ANY SMART CONTRACT WITHING THE GAME.
    function forceUpdates() external {

        require(rouble.isController(msg.sender),
        "ONLY CONTROLLERS CAN EXECUTE THIS FUNCTION!!!");
        _updateBlock(true, true);

    }

    //ROLE ➡️ MANAGES ALL REQUESTS SENT FROM AUTHORIZED SMART CONTRACTS
    function manageRequests(
        address from, 
        bool    c_addOrder, 
        bool    a_addOrder, 
        uint8   amount 
    ) external {

        require(rouble.isController(msg.sender),
        "ONLY CONTROLLERS CAN EXECUTE THIS FUNCTION!!!");

        if (c_addOrder) {_characterOrder(amount, from);}
        if (a_addOrder) {_adventureOrder();}

    }


    //!SECTION EXTERNAL FUNCTIONS --------------------------------------------------------------------------------------


    // SECTION INTERNAL FUNCTIONS ______________________________________________________________________________________


    //ROLE ➡️ UPDATES THE BLOCK IF NECESSARY, IF ITS A FORCED UPDATE, EXTRA TIME IS NEEDED FOR SECURITY PRECAUTIONS
    function _updateBlock(bool c_block, bool a_block) private {
        
        //ROLE ➡️ UPDATE THE BLOCK FOR CHARACTER.SOL
        if (c_block) {
            blockTraits storage currentBlock = c_blockData[c_totalSeeds];

            //NOTE ➡️ IF ITS TIME TO UPDATE
            if (currentBlock.stamp + c_stampRate <= block.timestamp) {  
                
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

        //ROLE ➡️ UPDATE THE BLOCK FOR ADVENTURE.SOL
        if (a_block) {
            
            blockTraits storage currentBlock = c_blockData[a_totalSeeds];
            
            //NOTE ➡️ IF ITS AWAITING SECOND CONFIRMATION
            if (currentBlock.awaiting == true) {

                //NOTE ➡️ IF SECOND CONFIRMATION WAITING TIME IS OVER, STORE PARAMETERS + BASE PARAMETERS
                if (currentBlock.stamp + awaitingRate >= block.timestamp) {
                    emit a_seedGen(a_totalSeeds);
        
                    unchecked{a_totalSeeds++;}
    
                    a_blockData[a_totalSeeds].onBlock = uint32(block.number % 100);
                    a_blockData[a_totalSeeds].stamp   = uint32(block.timestamp);
    
                    if (a_blockData[a_totalSeeds].ready) {_resetBlock(false);}
                }

                //NOTE IF WAITING TIME IS NOT OVER, THEN ADD REQUEST, TO EXTRA REQUESTS
                else {
                    unchecked{currentBlock.extraRequests++;}
                }
            }

            //NOTE IF THE BLOCK HASNT GONE THROUGH A SECOND CONFIRMATION YET, AND THE TIME IS OVER, THEN UPDATE
            if (currentBlock.awaiting == false || currentBlock.stamp + a_stampRate <= block.timestamp) { 
            
                currentBlock.differences = uint8(currentBlock.differences + (block.timestamp % 100));
                currentBlock.refreshBlock = uint8(block.number % 100);
                currentBlock.awaiting = true;
                currentBlock.stamp = uint32(block.timestamp) + awaitingRate;
                
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
            blockToChange.awaiting = false;
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
            _updateBlock(true, true);


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


        //ROLE ➡️ GENERATES AN UNIQUE SEED BASED ON THE TOKENID AND THE SEED MAPPED TO THE TOKENID
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


        //ROLE ➡️ SENDS A REQUEST TO THE BLOCK TO MAKE RANDOMIZATION FURTHER RANDOM
        function _adventureOrder() private {
            _updateBlock(true, true);
            blockTraits storage Block = a_blockData[a_totalSeeds];
            Block.differences = uint8(Block.differences + (block.timestamp));
            unchecked {Block.requests++;}
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
                        seed.requests,
                        seed.extraRequests
                    )
                )
            );
        }

        //ROLE ➡️ GENERATES AN UNIQUE SEED BASED ON THE TOKENID AND THE SEED MAPPED TO THE TOKENID
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

    //ROLE ➡️ FORCE BLOCK UPDATE
    function o_forceUpdate() 
    external
    onlyOwner
    {_updateBlock(true, true);}

    //ROLE ➡️ SETS SECOND CONFIRMATION RATE
    function o_awaitingRate(uint8 num)
    external 
    onlyOwner
    {awaitingRate = num;}

    function o_simulateRequest()
    external
    onlyOwner
    {_adventureOrder();}

    //ROLE ➡️ Testing purposes
    function o_tempSeed(uint8 seedId)
    external 
    onlyOwner {
    }

    //!SECTION ONLYOWNER FUNCTIONS -------------------------------------------------------------------------------------

}
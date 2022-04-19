// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;


import "./Context.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./IRouble.sol";


contract Random is Pausable, Ownable {

    // SECTION VARIABLES _______________________________________________________________________________________________

    // NOTE ⋯ ADVENTURE.SOL
    uint8  seedId;
    uint8  lastDigits = uint8 (block.number % 100);
    uint32 lastStamp = uint32(block.timestamp);

    // NOTE ⋯ CHARACTERS.SOL
    uint32 orders;
    uint32 currentBlock = uint32(block.number);

    //!SECTION VARIABLES -----------------------------------------------------------------------------------------------

    // SECTION STRUCTS _________________________________________________________________________________________________

    struct blockTraits {
        uint8  differences;
        uint32 nextBlock;
        uint32 orders;
    }

    struct orderTraits {
        uint8 differences;
        uint32 onBlock;
        uint32 stamp;
    }

    //!SECTION STRUCTS -------------------------------------------------------------------------------------------------

    // SECTION MAPPINGS  _______________________________________________________________________________________________

    // NOTE ⤵ CHARACTERS.SOL
    mapping(uint32 => blockTraits) private blockData;
    mapping(uint32 => orderTraits) private orderData;
    mapping(uint32 => blockTraits) private seedParameters;
    mapping(uint32 => address)     public  orderOwner;

    
    // NOTE ⤵ ADVENTURE.SOL
    mapping(uint8 => uint16) public blockSum;
    mapping(uint8 => bool)   public isReady;



    //!SECTION MAPPINGS  -----------------------------------------------------------------------------------------------

    // SECTION EVENTS __________________________________________________________________________________________________
    
    //NOTE ⋯ CHARACTERS.SOL
    event orderPlaced(address owner, uint32 orderId, uint32 onBlock);
    //ROLE ↪ Alert ❗❗ A new order has been placed on "owner" address, number "orderId", on the block number "onBlock".

    event seedGenerated(uint32 onBlock);
    //ROLE ↪ Alert ❗❗ A seed has been generated for block number "onBlock". Orders on this block can be claimed


    //NOTE ⋯ ADVENTURE.SOL

    event adventureSeedReady(uint8 seedId);

    //!SECTION EVENTS --------------------------------------------------------------------------------------------------

    // SECTION REFERENCES ______________________________________________________________________________________________

    IRouble public rouble;

    //!SECTION REFERENCES ----------------------------------------------------------------------------------------------

    // SECTION CONSTRUCTOR _____________________________________________________________________________________________

    constructor(address _rouble) {
        rouble = IRouble (_rouble);
    }

    //!SECTION CONSTRUCTOR ---------------------------------------------------------------------------------------------


    // SECTION VIEW FUNCTIONS __________________________________________________________________________________________

        // SECTION  CHARACTERS.SOL______________________________________________________________________________________
        
        function viewOrder(uint32 orderId) external view returns(orderTraits memory) {
            return orderData[orderId];
        }

        function totalOrders() external view returns (uint32) {
            return orders;
        }
    
        function viewBlock(uint32 blockNumber) external view returns (blockTraits memory) {
            return blockData[blockNumber];
        }
    
        function viewSeed(uint32 blockNumber) external view returns (uint256) {
            return _genMemSeed(blockNumber);
        }
    
        function viewOwner(uint32 orderId) external view returns (address) {
            return orderOwner[orderId];
        }
    
        function seedReady(uint32 orderId) external view returns (bool) {
            if (orderData[orderId].onBlock > 0) {return true;}
            else {return false;}
        }

        //!SECTION  CHARACTERS.SOL--------------------------------------------------------------------------------------

        // SECTION  ADVENTURE.SOL_______________________________________________________________________________________

        function adventureSeed(uint8 _seedId) external view returns (uint256) {
            return uint256(keccak256(abi.encode(blockSum[_seedId])));
        }

        //!SECTION  ADVENTURE.SOL---------------------------------------------------------------------------------------



    //!SECTION VIEW FUNCTIONS ------------------------------------------------------------------------------------------


    // SECTION EXTERNAL FUNCTIONS ______________________________________________________________________________________

        // SECTION  CHARACTERS.SOL _____________________________________________________________________________________
        
        //ROLE ➡️ Adds an order, assign an id to it, and the block number on which it was created
        function addOrder(address from) external whenNotPaused {

            require(rouble.isController(msg.sender), 
            "Only controllers can execute this function!!");
        
            unchecked{orders++;}
        
            //NOTE ⤵ ⋯ This fills the difference from the last order
            orderData[orders - 1].differences = uint8((block.timestamp - orderData[orders - 1].stamp) % 100);
        
            if (currentBlock != block.number) {  
                //ROLE ➡️ When block changes, we return seed and we map it to the currentBlock, before we change it
            
                blockData[currentBlock].nextBlock = uint32(block.number);
            
                _storeSeedPar();
                currentBlock = uint32(block.number);
            
            }
        
            orderTraits storage ord = orderData[orders];
            blockTraits storage blo = blockData[currentBlock];
        
            ord.onBlock = uint32(currentBlock);
            ord.stamp   = uint32(block.timestamp);
            
            blo.differences = uint8((blo.differences + block.timestamp) % 100);
            unchecked{blo.orders++;}
            
            orderOwner[orders] = from;
            
            emit orderPlaced(from, orders, currentBlock);
        
        }
        

        //ROLE ➡️ Approve an address to claim your order.
        function aprooveOrder(uint32 orderId, address from, address to) external whenNotPaused{
            require (orderOwner[orderId] == from, "You are not the owner of this order!!");
            orderOwner[orderId] = to;
        
        }
        
        
        //ROLE ➡️ Returns an unique seed, generated with the seed assigned to the order.
        function uniqueSeed(uint32 orderId) external view returns (uint) {
            orderTraits memory order = orderData[orderId];
        
            uint seed = uint256(
                keccak256(
                    abi.encodePacked(
                        _genMemSeed(order.onBlock),
                        orderId,
                        order.differences,
                        order.onBlock,
                        order.stamp
                    )
                )
            );
        
            return seed;
        }

        //!SECTION  CHARACTERS.SOL -------------------------------------------------------------------------------------

        // SECTION  ADVENTURE.SOL_______________________________________________________________________________________


        //ROLE ➡️ Checks if two hours have passed by since we generated a seed, if it did, then generate a new one.
        function checkGen() external whenNotPaused {
            
            require(rouble.isController(msg.sender), 
            "Only controllers can execute this function sorry, maybe someday I will make it public");

            if (lastStamp + 2 hours >= block.timestamp) {
                isReady[seedId] = true;
                emit adventureSeedReady(seedId);
                unchecked{seedId++;}
                lastStamp = uint32(block.timestamp);
            }

            if (lastDigits != uint8(block.number % 100)) {
                if (lastDigits > uint8(block.number % 100)) {
                    blockSum[seedId] = lastDigits - (uint8(block.number % 100) + 100);
                    lastDigits = uint8(block.number % 100);
                }
                else {
                    blockSum[seedId] = lastDigits - uint8(block.number % 100);
                    lastDigits = uint8(block.number % 100);
                }
            }
        }

        function askSeed(uint32 tokenId, uint8 _seedId) external view returns (uint256) {
            return uint256(keccak256(abi.encodePacked(blockSum[_seedId], tokenId)));
        }
    

        //!SECTION  ADVENTURE.SOL---------------------------------------------------------------------------------------

    //!SECTION EXTERNAL FUNCTIONS --------------------------------------------------------------------------------------


    // SECTION INTERNAL FUNCTIONS ______________________________________________________________________________________

        // SECTION  CHARACTERS.SOL _____________________________________________________________________________________

        function _storeSeedPar() private {
            seedParameters[currentBlock] = blockData[currentBlock];
            emit seedGenerated(currentBlock);
        }

        
        function _genMemSeed(uint32 blockNumber) private view returns (uint256) {
            blockTraits storage blo = seedParameters[blockNumber];
            return uint256(keccak256(abi.encode(blo.differences, blo.nextBlock, blo.orders)));
        }
        //!SECTION  CHARACTERS.SOL -------------------------------------------------------------------------------------

    //!SECTION INTERNAL FUNCTIONS --------------------------------------------------------------------------------------
}
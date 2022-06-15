// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {IExecutionStrategy} from './interfaces/IExecutionStrategy.sol';
import {OrderTypes} from './libraries/OrderTypes.sol';
contract CollectionSale is IExecutionStrategy {

    uint256 public immutable PROTOCOL_FEE;

    constructor(uint256 _protocolFee) {//2% = 200 basis points
        PROTOCOL_FEE = _protocolFee;
    }

    function canExecuteTakerAsk( OrderTypes.TakerOrder calldata takerAsk, OrderTypes.MakerOrder calldata makerBid) external view override returns (bool, uint256, uint256){
        bool _valid = (makerBid.price == takerAsk.price)      &&
                      (makerBid.startTime <= block.timestamp) &&
                      (makerBid.endTime >= block.timestamp);

        return(_valid, takerAsk.tokenId, makerBid.amount);
    }

    function canExecuteTakerBid(OrderTypes.TakerOrder calldata, OrderTypes.MakerOrder calldata) external pure override returns (bool, uint256, uint256){
        return(false, 0, 0);
    }

    function viewProtocolFee()  external view override returns (uint256){
        return PROTOCOL_FEE;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OrderTypes} from "../libraries/OrderTypes.sol";

interface IExecutionStrategy {
    function canExecuteTakerAsk(OrderTypes.TakerOrder calldata takerAsk, OrderTypes.MakerOrder calldata makerBid)
        external
        view
        returns (
            bool,
            uint256,
            uint256
        );

    function canExecuteTakerBid(OrderTypes.TakerOrder calldata takerBid, OrderTypes.MakerOrder calldata makerAsk)
        external
        view
        returns (
            bool,
            uint256,
            uint256
        );

    function viewProtocolFee() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library OrderTypes {
    
    bytes32 internal constant MAKER_ORDER_HASH = 0x337e87154a3b7bbf1daf798d210b85bb02a39cebcfa98778f9f74bde68350ed2;
    
    struct MakerOrder {
        bool isAsk;
        address signer;
        address collection;
        uint256 price;
        uint256 tokenId;
        uint256 amount;
        address strategy;
        address currency;
        uint256 nonce;
        uint256 startTime;
        uint256 endTime;
        uint256 minPercentageToAsk;
        bytes params;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct TakerOrder {
        bool isAsk;
        address taker;
        uint256 price;
        uint256 tokenId;
        uint256 minPercentageToAsk;
        bytes params;
    }

    function hash(MakerOrder memory makerOrder) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    MAKER_ORDER_HASH,
                    makerOrder.isAsk,
                    makerOrder.signer,
                    makerOrder.collection,
                    makerOrder.price,
                    makerOrder.tokenId,
                    makerOrder.amount,
                    makerOrder.strategy,
                    makerOrder.currency,
                    makerOrder.nonce,
                    makerOrder.startTime,
                    makerOrder.endTime,
                    makerOrder.minPercentageToAsk,
                    keccak256(makerOrder.params)
                )
            );
    }
}
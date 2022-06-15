// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {IExecutionStrategy} from './interfaces/IExecutionStrategy.sol';
import {OrderTypes} from './libraries/OrderTypes.sol';

contract DutchAuction is IExecutionStrategy {

    uint256 public immutable PROTOCOL_FEE;

    constructor(uint256 _protocolFee) {//2% = 200 basis points
        PROTOCOL_FEE = _protocolFee;
    }

    function canExecuteTakerAsk( OrderTypes.TakerOrder calldata, OrderTypes.MakerOrder calldata) external pure override returns (bool, uint256, uint256){
        return(false, 0,0);
    }

    function currentPrice(uint256 startPrice, uint256 endPrice, uint256 startTime, uint256 endTime) internal view returns(uint256){
        uint256 delta = startPrice - endPrice;
        uint256 discount = delta  *  (block.timestamp - startTime)  / (endTime - startTime);
        return startPrice - discount;
    }

    function canExecuteTakerBid(OrderTypes.TakerOrder calldata takerBid, OrderTypes.MakerOrder calldata makerAsk) external view override returns (bool, uint256, uint256){
        // get endPrice from params
        uint256 endPrice = abi.decode(makerAsk.params, (uint256));

        //calculate current dutch auction price, execution will auto revert if (price < endprice || starttime > end time) in solidity ^0.8.0
        uint256 _currentPrice = currentPrice(makerAsk.price, endPrice, makerAsk.startTime, makerAsk.endTime);

        // add 5% slippage to protect takers from over spending while respecting transaction time
        uint256 _currentPriceSlippage = _currentPrice * 10500 / 10000;

        //validate auction
        bool _valid = (makerAsk.price > endPrice)               &&
                      (_currentPrice <= takerBid.price)         &&
                      (_currentPriceSlippage >= takerBid.price) &&
                      (makerAsk.tokenId == takerBid.tokenId)    &&
                      (makerAsk.startTime <= block.timestamp)   &&
                      (makerAsk.endTime >= block.timestamp);

        return(_valid, makerAsk.tokenId, makerAsk.amount);

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
/**
 *Submitted for verification at snowtrace.io on 2023-04-12
*/

// File: ../../cables/cables/contracts/enums/OrderStatus.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

enum OrderStatus {
    OpenUnfilled,
    OpenPartiallyFilled,
    ClosedPartiallyFilled,
    ClosedFullyFilled,
    ClosedCanceled
}

// File: ../../cables/cables/contracts/enums/ExecutionFacility.sol


pragma solidity ^0.8.17;

enum ExecutionFacility {
    Nexus,
    Coinbase,
    Binance
}

// File: ../../cables/cables/contracts/enums/OrderType.sol


pragma solidity ^0.8.17;

enum OrderType {
    Sell,
    Buy
}

// File: ../../cables/cables/contracts/enums/TradeType.sol


pragma solidity ^0.8.17;

enum TradeType {
    Limit,
    Market
}

// File: ../../cables/cables/contracts/types/Order.sol


pragma solidity ^0.8.17;





struct Order {
    address creator;

    OrderType orderType;
    TradeType tradeType;

    address baseCurrency;
    address quoteCurrency;

    uint baseAmount;
    uint quoteAmount;

    uint limitPrice;

    ExecutionFacility executionFacility;

    uint gasDeposit;

    uint slippage;

    OrderStatus status;
}

// File: ../../cables/cables/contracts/interfaces/ICablesEscrow.sol


pragma solidity ^0.8.17;


/**
* @dev Interface for a CablesEscrow contract
 **/
interface ICablesEscrow {
    function isExecutionFacility(
        address _sender
    ) external view returns (bool);

    function calcQuoteAmount(
        uint _baseAmount,
        address _baseCurrency,
        uint _price
    ) external view returns (uint);

    function createEscrow(
        address _user,
        Order memory _order
    ) external returns (uint);

    function fillWithExtraGasCompensation(
        uint _makerEscrowId,
        uint _takerEscrowId,
        uint _extraGas,
        bool _isLastFill
    ) external;

    receive() external payable;
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: ../../cables/cables/contracts/CablesMaster.sol

// 

pragma solidity ^0.8.17;



/**
* @title Cables master contract
 **/
contract CablesMaster is ReentrancyGuard {
    ICablesEscrow public immutable escrow;

    // the address used to identify AVAX
    address constant AVAX_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    modifier onlyExecutionFacility() {
        require(escrow.isExecutionFacility(msg.sender) == true, "Not Execution Facility");

        _;
    }

    constructor(ICablesEscrow _escrow) {
        escrow = _escrow;
    }

    /**
    * @dev internal function to create order
    * @param _baseAmount the amount of the base asset
    * @param _quoteAmount the amount of the quote asset
    * @param _baseAsset the address of the base asset
    * @param _quoteAsset the address of the quote asset
    * @param _limitPrice the limit base asset price (_limitPrice decimals == _quoteAsset decimals)
    * @param _orderType the order type
    * @param _tradeType the trade type
    * @param _slippage the slippage with decimals 2
    **/
    function createOrder(
        uint _baseAmount,
        uint _quoteAmount,
        address _baseAsset,
        address _quoteAsset,
        uint _limitPrice,
        OrderType _orderType,
        TradeType _tradeType,
        uint _slippage
    ) private returns(uint) {
        uint gasDeposit;
        if (_orderType == OrderType.Sell && _baseAsset == AVAX_ADDRESS) {
            gasDeposit = msg.value - _baseAmount;
        } else if (_orderType == OrderType.Buy && _quoteAsset == AVAX_ADDRESS) {
            gasDeposit = msg.value - ((_quoteAmount == 0) ? escrow.calcQuoteAmount(_baseAmount, _baseAsset, _limitPrice) : _quoteAmount);
        } else {
            gasDeposit = msg.value;
        }

        payable(address(escrow)).transfer(msg.value);

        uint escrowId = escrow.createEscrow(
            msg.sender,
            Order ({
                baseAmount: _baseAmount,
                quoteAmount: _quoteAmount,
                creator: msg.sender,
                orderType: _orderType,
                tradeType: _tradeType,
                baseCurrency: _baseAsset,
                quoteCurrency: _quoteAsset,
                limitPrice: _limitPrice,
                executionFacility: ExecutionFacility.Nexus,
                gasDeposit: gasDeposit,
                slippage: _slippage,
                status: OrderStatus.OpenUnfilled
            })
        );

        return escrowId;
    }

    /**
    * @dev creates maker buy order
    * @param _baseAmount the amount of the base asset
    * @param _baseAsset the address of the base asset
    * @param _quoteAsset the address of the quote asset
    * @param _maxPrice the max base asset price
    **/
    function createBuyOrder(
        uint _baseAmount,
        address _baseAsset,
        address _quoteAsset,
        uint _maxPrice
    ) external payable nonReentrant returns(uint) {
        return createOrder(_baseAmount, 0, _baseAsset, _quoteAsset, _maxPrice, OrderType.Buy, TradeType.Limit, 0);
    }

    /**
    * @dev creates maker sell order
    * @param _baseAmount the amount of the base asset
    * @param _baseAsset the address of the base asset
    * @param _quoteAsset the address of the quote asset
    * @param _minPrice the min base asset price
    **/
    function createSellOrder(
        uint _baseAmount,
        address _baseAsset,
        address _quoteAsset,
        uint _minPrice
    ) external payable nonReentrant returns(uint) {
        return createOrder(_baseAmount, 0, _baseAsset, _quoteAsset, _minPrice, OrderType.Sell, TradeType.Limit, 0);
    }

    /**
    * @dev creates market buy order
    * @param _quoteAmount the amount of the quote asset
    * @param _baseAsset the address of the base asset
    * @param _quoteAsset the address of the quote asset
    * @param _slippage the slippage with decimals 2
    **/
    function createMarketBuyOrder(
        uint _quoteAmount,
        address _baseAsset,
        address _quoteAsset,
        uint _slippage
    ) external payable nonReentrant returns(uint) {
        return createOrder(0, _quoteAmount, _baseAsset, _quoteAsset, 0, OrderType.Buy, TradeType.Market, _slippage);
    }

    /**
    * @dev creates market sell order
    * @param _baseAmount the amount of the base asset
    * @param _baseAsset the address of the base asset
    * @param _quoteAsset the address of the quote asset
    * @param _slippage the slippage with decimals 2
    **/
    function createMarketSellOrder(
        uint _baseAmount,
        address _baseAsset,
        address _quoteAsset,
        uint _slippage
    ) external payable nonReentrant returns(uint) {
        return createOrder(_baseAmount, 0, _baseAsset, _quoteAsset, 0, OrderType.Sell, TradeType.Market, _slippage);
    }

    /**
    * @dev creates taker buy order and fills it out using the maker escrows list
    * @param _baseAmount the amount of the base asset
    * @param _baseAsset the address of the base asset
    * @param _quoteAsset the address of the quote asset
    * @param _maxPrice the max base asset price
    * @param _makerEscrowsIds the array of maker escrows IDs
    **/
    function createAndFillTakerBuyOrder(
        uint _baseAmount,
        address _baseAsset,
        address _quoteAsset,
        uint _maxPrice,
        uint[] memory _makerEscrowsIds
    ) external payable onlyExecutionFacility nonReentrant returns(uint) {
        uint gasAmountLeft = gasleft();

        uint length = _makerEscrowsIds.length;
        require(length <= 8, "Too many maker orders to process");

        uint escrowId = createOrder(_baseAmount, 0, _baseAsset, _quoteAsset, _maxPrice, OrderType.Buy, TradeType.Limit, 0);

        uint24[8] memory gasCompensationCorrections = [116513, 143693, 170875, 198044, 225224, 252401, 279586, 351365];

        uint extraGas = (gasAmountLeft - gasleft() - gasCompensationCorrections[length-1])/length;
        for (uint i = 0; i < length; i++) {
            escrow.fillWithExtraGasCompensation(
                _makerEscrowsIds[i],
                escrowId,
                extraGas,
                i == length - 1 ? true : false
            );
        }

        return escrowId;
    }

    /**
    * @dev creates taker sell order and fills it out using the maker escrows list
    * @param _baseAmount the amount of the base asset
    * @param _baseAsset the address of the base asset
    * @param _quoteAsset the address of the quote asset
    * @param _minPrice the min base asset price
    * @param _makerEscrowsIds the array of maker escrows IDs
    **/
    function createAndFillTakerSellOrder(
        uint _baseAmount,
        address _baseAsset,
        address _quoteAsset,
        uint _minPrice,
        uint[] memory _makerEscrowsIds
    ) external payable onlyExecutionFacility nonReentrant returns(uint) {
        uint gasAmountLeft = gasleft();

        uint length = _makerEscrowsIds.length;
        require(length <= 8, "Too many maker orders to process");

        uint escrowId = createOrder(_baseAmount, 0, _baseAsset, _quoteAsset, _minPrice, OrderType.Sell, TradeType.Limit, 0);

        uint24[8] memory gasCompensationCorrections = [116546, 143727, 170906, 198076, 225258, 252424, 279611, 351400];

        uint extraGas = (gasAmountLeft - gasleft() - gasCompensationCorrections[length-1])/length;
        for (uint i = 0; i < length; i++) {
            escrow.fillWithExtraGasCompensation(
                _makerEscrowsIds[i],
                escrowId,
                extraGas,
                i == length - 1 ? true : false
            );
        }

        return escrowId;
    }
}
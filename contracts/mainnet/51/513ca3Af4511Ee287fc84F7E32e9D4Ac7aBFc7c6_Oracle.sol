// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IRouter.sol";
import "./interfaces/ITreasury.sol";
import "./interfaces/ITrading.sol";
import "./interfaces/IPriceFeed.sol";

contract Oracle {

	// Structs
	struct PendingOrder {
		address user;
		bytes32 productId;
		address currency;
		bool isLong;
		uint256 timestamp;
	}

	// Contract dependencies
	address public owner;
	address public router;
	address public keeper;
	address public treasury;
	address public trading;

	// Variables
	uint256 public requestsPerFunding = 100;
	uint256 public costPerRequest = 6 * 10**14; // 0.0006 ETH
	uint256 public requestsSinceFunding;
	uint256 public priceSampleSpace = 3;
	bool public inPrivateLiquidationMode = false;

	mapping(bytes32 => uint256) public orderBookIndex;
	mapping(bytes32 => uint256) public openOrderPointer;
	mapping(bytes32 => bool) public isAllowedProduct;
	mapping(bytes32 => address) public priceFeeds;
	mapping(bytes32 => uint64) public priceFeedDecimals;
	mapping(bytes32 => mapping(uint256 => PendingOrder)) public pendingOrders;
	mapping(address => bool) public isLiquidator;

	uint256 public constant PRICE_DECIMALS = 8;

	constructor() {
		owner = msg.sender;
	}

	// Governance methods

	function setOwner(address newOwner) external onlyOwner {
		owner = newOwner;
	}

	function setRouter(address _router) external onlyOwner {
		router = _router;
		trading = IRouter(router).trading();
		treasury = IRouter(router).treasury();
		keeper = IRouter(router).keeper();
	}

	function setParams(
		uint256 _requestsPerFunding, 
		uint256 _costPerRequest
	) external onlyOwner {
		requestsPerFunding = _requestsPerFunding;
		costPerRequest = _costPerRequest;
	}

	function addOrder(
		address user,
		bytes32 productId,
		address currency,
		bool isLong
	) external onlyTrading returns(uint256 index) {
		index = orderBookIndex[productId];
		pendingOrders[productId][index] = PendingOrder({
			user: user,
			productId: productId,
			currency: currency,
			isLong: isLong,
			timestamp: block.timestamp
		});
		orderBookIndex[productId]++;
	}

	function cancelOrder(bytes32 productId, uint256 index) external onlyTrading {
		delete pendingOrders[productId][index];
	}

	function getPendingOrder(bytes32 productId, uint256 index) external view returns(PendingOrder memory) {
		PendingOrder memory pendingOrder = pendingOrders[productId][index];
		require(pendingOrder.timestamp > 0, "!exists");
		return pendingOrder;
	}

	function settleOrders(bytes32[] calldata productIds) external {
		uint256 numOrders;
		for (uint256 i = 0; i < productIds.length; i++) {
			bytes32 productId = productIds[i];
			require(isAllowedProduct[productId], "!product-allowed");

			(uint256 maxPrice, uint256 minPrice, uint256 lastUpdated) = getPrices(productId);
			uint256 pointer = openOrderPointer[productId];

			for (uint256 j = pointer; j < orderBookIndex[productId]; j++) {
				PendingOrder memory pendingOrder = pendingOrders[productId][j];
				if (pendingOrder.timestamp > 0) {
					if (pendingOrder.timestamp > lastUpdated) {break;}

					if (pendingOrder.isLong) {
						ITrading(trading).settleOrder(
							pendingOrder.user,
							pendingOrder.productId,
							pendingOrder.currency,
							pendingOrder.isLong,
							minPrice
						);
					} else {
						ITrading(trading).settleOrder(
							pendingOrder.user,
							pendingOrder.productId,
							pendingOrder.currency,
							pendingOrder.isLong,
							maxPrice
						);
					}
					delete pendingOrders[productId][j];
				}
				openOrderPointer[productId]++;
				numOrders++;
			}
		}
		_tallyKeeperRequests(numOrders);
	}

	function liquidatePositions(
		address[] calldata currencies,
		address[] calldata users,
		bool[] calldata directions,
		bytes32 productId
	) external {
		require(isAllowedProduct[productId], "!product-allowed");

		(uint256 maxPrice, uint256 minPrice,) = getPrices(productId);

		for (uint256 i = 0; i < users.length; i++) {
			address user = users[i];
			address currency = currencies[i];
			bool isLong = directions[i];
			uint256 price = isLong ? minPrice : maxPrice;
			ITrading(trading).liquidatePosition(user, productId, currency, isLong, price);
		}

		if (inPrivateLiquidationMode) {
			require(isLiquidator[msg.sender], "!liquidator");
			_tallyKeeperRequests(users.length);
		}
	}

	function _tallyKeeperRequests(uint256 newRequests) internal {
		if (newRequests == 0) return;
		requestsSinceFunding += newRequests;
		if (requestsSinceFunding >= requestsPerFunding) {
			requestsSinceFunding = 0;
			ITreasury(treasury).fundKeeper(keeper, costPerRequest * requestsPerFunding);
		}
	}

	function getPrices(bytes32 productId) public view returns(
		uint256 maxPrice,
		uint256 minPrice,
		uint256 lastUpdated
	) {
        address priceFeedAddress = priceFeeds[productId];
        require(priceFeedAddress != address(0), "!valid-feed");
        require(isAllowedProduct[productId], "!product-allowed");

        IPriceFeed priceFeed = IPriceFeed(priceFeedAddress);
        uint256 _priceDecimals = priceFeedDecimals[productId];

        uint80 roundId = priceFeed.latestRound();

        for (uint80 i = 0; i < priceSampleSpace; i++) {
        	if (roundId <= i) { break; }
        	uint256 roundPrice;
        	int256 _roundPrice;

        	if (i == 0) {
        		(, _roundPrice,, lastUpdated,) = priceFeed.latestRoundData();
        		require(lastUpdated > 0, "!timestamp-valid");
        	} else {
        		(, _roundPrice,,,) = priceFeed.getRoundData(roundId - i);
        	}
        	require(_roundPrice > 0, "!price-valid");
        	roundPrice = uint256(_roundPrice) * (10**PRICE_DECIMALS) / (10**_priceDecimals);

        	if (i == 0) {
        		maxPrice = roundPrice;
       			minPrice = roundPrice;
        		continue;
        	}

        	if (roundPrice > maxPrice) {
        		maxPrice = roundPrice;
        		continue;
        	}

        	if (roundPrice < minPrice) {
        		minPrice = roundPrice;
        	}
        }

        return (maxPrice, minPrice, lastUpdated);
    }

    function setPriceSampleSpace(uint256 _priceSampleSpace) external onlyOwner {
        require(_priceSampleSpace > 0, "!sample-space-valid");
        priceSampleSpace = _priceSampleSpace;
    }

    function setFeedConfig(
        bytes32 productId,
        address priceFeed,
        uint64 priceDecimals,
        bool allowed
    ) external onlyOwner {
        priceFeeds[productId] = priceFeed;
        priceFeedDecimals[productId] = priceDecimals;
        isAllowedProduct[productId] = allowed;
    }

    function setLiquidator(address _liquidator, bool _isActive) external onlyOwner {
        isLiquidator[_liquidator] = _isActive;
    }

	// Modifiers

	modifier onlyOwner() {
		require(msg.sender == owner, "!owner");
		_;
	}

	modifier onlyTrading() {
		require(msg.sender == trading, "!trading");
		_;
	}

	modifier onlyKeeper() {
		require(msg.sender == keeper, "!keeper");
		_;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRouter {
    function trading() external view returns (address);

    function snowPool() external view returns (address);

    function oracle() external view returns (address);

    function treasury() external view returns (address);

    function keeper() external view returns (address);

    function isSupportedCurrency(address currency) external view returns (bool);

    function currencies(uint256 index) external view returns (address);

    function currenciesLength() external view returns (uint256);

    function getDecimals(address currency) external view returns(uint8);

    function getPool(address currency) external view returns (address);

    function getPoolShare(address currency) external view returns(uint256);

    function getPoolRewardsShare(address currency) external view returns(uint256);

    function getSnowShare(address currency) external view returns(uint256);

    function getPoolRewards(address currency) external view returns (address);

    function getSnowRewards(address currency) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITreasury {
    function fundKeeper(address destination, uint256 amount) external;

    function notifyFeeReceived(address currency, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITrading {

    function distributeFees(address currency) external;
    
    function settleOrder(address user, bytes32 productId, address currency, bool isLong, uint256 price) external;

    function liquidatePosition(address user, bytes32 productId, address currency, bool isLong, uint256 price) external;

    function getPendingFee(address currency) external view returns(uint256);
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPriceFeed {
    function description() external view returns (string memory);
    function aggregator() external view returns (address);
    function latestAnswer() external view returns (int256);
    function latestRound() external view returns (uint80);
    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80);
    function getRoundData(uint80 roundId) external view returns (uint80, int256, uint256, uint256, uint80);
}
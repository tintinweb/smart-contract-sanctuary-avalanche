/**
 *Submitted for verification at testnet.snowtrace.io on 2023-05-12
*/

// Sources flattened with hardhat v2.14.0 https://hardhat.org

// File contracts/dependencies/pyth/IPythEvents.sol

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @title IPythEvents contains the events that Pyth contract emits.
/// @dev This interface can be used for listening to the updates for off-chain and testing purposes.
interface IPythEvents {
  /// @dev Emitted when the price feed with `id` has received a fresh update.
  /// @param id The Pyth Price Feed ID.
  /// @param publishTime Publish time of the given price update.
  /// @param price Price of the given price update.
  /// @param conf Confidence interval of the given price update.
  event PriceFeedUpdate(bytes32 indexed id, uint64 publishTime, int64 price, uint64 conf);

  /// @dev Emitted when a batch price update is processed successfully.
  /// @param chainId ID of the source chain that the batch price update comes from.
  /// @param sequenceNumber Sequence number of the batch price update.
  event BatchPriceFeedUpdate(uint16 chainId, uint64 sequenceNumber);
}


// File contracts/dependencies/pyth/PythStructs.sol

pragma solidity ^0.8.0;

contract PythStructs {
  // A price with a degree of uncertainty, represented as a price +- a confidence interval.
  //
  // The confidence interval roughly corresponds to the standard error of a normal distribution.
  // Both the price and confidence are stored in a fixed-point numeric representation,
  // `x * (10^expo)`, where `expo` is the exponent.
  //
  // Please refer to the documentation at https://docs.pyth.network/consumers/best-practices for how
  // to how this price safely.
  struct Price {
    // Price
    int64 price;
    // Confidence interval around the price
    uint64 conf;
    // Price exponent
    int32 expo;
    // Unix timestamp describing when the price was published
    uint publishTime;
  }

  // PriceFeed represents a current aggregate price from pyth publisher feeds.
  struct PriceFeed {
    // The price ID.
    bytes32 id;
    // Latest available price
    Price price;
    // Latest available exponentially-weighted moving average price
    Price emaPrice;
  }
}


// File contracts/dependencies/pyth/IPyth.sol

pragma solidity ^0.8.0;


/// @title Consume prices from the Pyth Network (https://pyth.network/).
/// @dev Please refer to the guidance at https://docs.pyth.network/consumers/best-practices for how to consume prices safely.
/// @author Pyth Data Association
interface IPyth is IPythEvents {
  /// @notice Returns the period (in seconds) that a price feed is considered valid since its publish time
  function getValidTimePeriod() external view returns (uint validTimePeriod);

  /// @notice Returns the price and confidence interval.
  /// @dev Reverts if the price has not been updated within the last `getValidTimePeriod()` seconds.
  /// @param id The Pyth Price Feed ID of which to fetch the price and confidence interval.
  /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
  function getPrice(bytes32 id) external view returns (PythStructs.Price memory price);

  /// @notice Returns the exponentially-weighted moving average price and confidence interval.
  /// @dev Reverts if the EMA price is not available.
  /// @param id The Pyth Price Feed ID of which to fetch the EMA price and confidence interval.
  /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
  function getEmaPrice(bytes32 id) external view returns (PythStructs.Price memory price);

  /// @notice Returns the price of a price feed without any sanity checks.
  /// @dev This function returns the most recent price update in this contract without any recency checks.
  /// This function is unsafe as the returned price update may be arbitrarily far in the past.
  ///
  /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
  /// sufficiently recent for their application. If you are considering using this function, it may be
  /// safer / easier to use either `getPrice` or `getPriceNoOlderThan`.
  /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
  function getPriceUnsafe(bytes32 id) external view returns (PythStructs.Price memory price);

  /// @notice Returns the price that is no older than `age` seconds of the current time.
  /// @dev This function is a sanity-checked version of `getPriceUnsafe` which is useful in
  /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
  /// recently.
  /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
  function getPriceNoOlderThan(
    bytes32 id,
    uint age
  ) external view returns (PythStructs.Price memory price);

  /// @notice Returns the exponentially-weighted moving average price of a price feed without any sanity checks.
  /// @dev This function returns the same price as `getEmaPrice` in the case where the price is available.
  /// However, if the price is not recent this function returns the latest available price.
  ///
  /// The returned price can be from arbitrarily far in the past; this function makes no guarantees that
  /// the returned price is recent or useful for any particular application.
  ///
  /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
  /// sufficiently recent for their application. If you are considering using this function, it may be
  /// safer / easier to use either `getEmaPrice` or `getEmaPriceNoOlderThan`.
  /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
  function getEmaPriceUnsafe(bytes32 id) external view returns (PythStructs.Price memory price);

  /// @notice Returns the exponentially-weighted moving average price that is no older than `age` seconds
  /// of the current time.
  /// @dev This function is a sanity-checked version of `getEmaPriceUnsafe` which is useful in
  /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
  /// recently.
  /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
  function getEmaPriceNoOlderThan(
    bytes32 id,
    uint age
  ) external view returns (PythStructs.Price memory price);

  /// @notice Update price feeds with given update messages.
  /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
  /// `getUpdateFee` with the length of the `updateData` array.
  /// Prices will be updated if they are more recent than the current stored prices.
  /// The call will succeed even if the update is not the most recent.
  /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid.
  /// @param updateData Array of price update data.
  function updatePriceFeeds(bytes[] calldata updateData) external payable;

  /// @notice Wrapper around updatePriceFeeds that rejects fast if a price update is not necessary. A price update is
  /// necessary if the current on-chain publishTime is older than the given publishTime. It relies solely on the
  /// given `publishTimes` for the price feeds and does not read the actual price update publish time within `updateData`.
  ///
  /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
  /// `getUpdateFee` with the length of the `updateData` array.
  ///
  /// `priceIds` and `publishTimes` are two arrays with the same size that correspond to senders known publishTime
  /// of each priceId when calling this method. If all of price feeds within `priceIds` have updated and have
  /// a newer or equal publish time than the given publish time, it will reject the transaction to save gas.
  /// Otherwise, it calls updatePriceFeeds method to update the prices.
  ///
  /// @dev Reverts if update is not needed or the transferred fee is not sufficient or the updateData is invalid.
  /// @param updateData Array of price update data.
  /// @param priceIds Array of price ids.
  /// @param publishTimes Array of publishTimes. `publishTimes[i]` corresponds to known `publishTime` of `priceIds[i]`
  function updatePriceFeedsIfNecessary(
    bytes[] calldata updateData,
    bytes32[] calldata priceIds,
    uint64[] calldata publishTimes
  ) external payable;

  /// @notice Returns the required fee to update an array of price updates.
  /// @param updateData Array of price update data.
  /// @return feeAmount The required fee in Wei.
  function getUpdateFee(bytes[] calldata updateData) external view returns (uint feeAmount);

  /// @notice Parse `updateData` and return price feeds of the given `priceIds` if they are all published
  /// within `minPublishTime` and `maxPublishTime`.
  ///
  /// You can use this method if you want to use a Pyth price at a fixed time and not the most recent price;
  /// otherwise, please consider using `updatePriceFeeds`. This method does not store the price updates on-chain.
  ///
  /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
  /// `getUpdateFee` with the length of the `updateData` array.
  ///
  ///
  /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid or there is
  /// no update for any of the given `priceIds` within the given time range.
  /// @param updateData Array of price update data.
  /// @param priceIds Array of price ids.
  /// @param minPublishTime minimum acceptable publishTime for the given `priceIds`.
  /// @param maxPublishTime maximum acceptable publishTime for the given `priceIds`.
  /// @return priceFeeds Array of the price feeds corresponding to the given `priceIds` (with the same order).
  function parsePriceFeedUpdates(
    bytes[] calldata updateData,
    bytes32[] calldata priceIds,
    uint64 minPublishTime,
    uint64 maxPublishTime
  ) external payable returns (PythStructs.PriceFeed[] memory priceFeeds);
}


// File contracts/dependencies/pyth/PythErrors.sol

pragma solidity ^0.8.0;

library PythErrors {
  // Function arguments are invalid (e.g., the arguments lengths mismatch)
  error InvalidArgument();
  // Update data is coming from an invalid data source.
  error InvalidUpdateDataSource();
  // Update data is invalid (e.g., deserialization error)
  error InvalidUpdateData();
  // Insufficient fee is paid to the method.
  error InsufficientFee();
  // There is no fresh update, whereas expected fresh updates.
  error NoFreshUpdate();
  // There is no price feed found within the given range or it does not exists.
  error PriceFeedNotFoundWithinRange();
  // Price feed not found or it is not pushed on-chain yet.
  error PriceFeedNotFound();
  // Requested price is stale.
  error StalePrice();
  // Given message is not a valid Wormhole VAA.
  error InvalidWormholeVaa();
  // Governance message is invalid (e.g., deserialization error).
  error InvalidGovernanceMessage();
  // Governance message is not for this contract.
  error InvalidGovernanceTarget();
  // Governance message is coming from an invalid data source.
  error InvalidGovernanceDataSource();
  // Governance message is old.
  error OldGovernanceMessage();
}


// File contracts/dependencies/pyth/AbstractPyth.sol

pragma solidity ^0.8.0;



abstract contract AbstractPyth is IPyth {
  /// @notice Returns the price feed with given id.
  /// @dev Reverts if the price does not exist.
  /// @param id The Pyth Price Feed ID of which to fetch the PriceFeed.
  function queryPriceFeed(
    bytes32 id
  ) public view virtual returns (PythStructs.PriceFeed memory priceFeed);

  /// @notice Returns true if a price feed with the given id exists.
  /// @param id The Pyth Price Feed ID of which to check its existence.
  function priceFeedExists(bytes32 id) public view virtual returns (bool exists);

  function getValidTimePeriod() public view virtual override returns (uint validTimePeriod);

  function getPrice(
    bytes32 id
  ) external view virtual override returns (PythStructs.Price memory price) {
    return getPriceNoOlderThan(id, getValidTimePeriod());
  }

  function getEmaPrice(
    bytes32 id
  ) external view virtual override returns (PythStructs.Price memory price) {
    return getEmaPriceNoOlderThan(id, getValidTimePeriod());
  }

  function getPriceUnsafe(
    bytes32 id
  ) public view virtual override returns (PythStructs.Price memory price) {
    PythStructs.PriceFeed memory priceFeed = queryPriceFeed(id);
    return priceFeed.price;
  }

  function getPriceNoOlderThan(
    bytes32 id,
    uint age
  ) public view virtual override returns (PythStructs.Price memory price) {
    price = getPriceUnsafe(id);

    if (diff(block.timestamp, price.publishTime) > age) revert PythErrors.StalePrice();

    return price;
  }

  function getEmaPriceUnsafe(
    bytes32 id
  ) public view virtual override returns (PythStructs.Price memory price) {
    PythStructs.PriceFeed memory priceFeed = queryPriceFeed(id);
    return priceFeed.emaPrice;
  }

  function getEmaPriceNoOlderThan(
    bytes32 id,
    uint age
  ) public view virtual override returns (PythStructs.Price memory price) {
    price = getEmaPriceUnsafe(id);

    if (diff(block.timestamp, price.publishTime) > age) revert PythErrors.StalePrice();

    return price;
  }

  function diff(uint x, uint y) internal pure returns (uint) {
    if (x > y) {
      return x - y;
    } else {
      return y - x;
    }
  }

  // Access modifier is overridden to public to be able to call it locally.
  function updatePriceFeeds(bytes[] calldata updateData) public payable virtual override;

  function updatePriceFeedsIfNecessary(
    bytes[] calldata updateData,
    bytes32[] calldata priceIds,
    uint64[] calldata publishTimes
  ) external payable virtual override {
    if (priceIds.length != publishTimes.length) revert PythErrors.InvalidArgument();

    for (uint i = 0; i < priceIds.length; i++) {
      if (
        !priceFeedExists(priceIds[i]) ||
        queryPriceFeed(priceIds[i]).price.publishTime < publishTimes[i]
      ) {
        updatePriceFeeds(updateData);
        return;
      }
    }

    revert PythErrors.NoFreshUpdate();
  }

  function parsePriceFeedUpdates(
    bytes[] calldata updateData,
    bytes32[] calldata priceIds,
    uint64 minPublishTime,
    uint64 maxPublishTime
  ) external payable virtual override returns (PythStructs.PriceFeed[] memory priceFeeds);
}


// File contracts/dependencies/pyth/MockPyth.sol

pragma solidity ^0.8.0;



contract MockPyth is AbstractPyth {
  mapping(bytes32 => PythStructs.PriceFeed) priceFeeds;
  uint64 sequenceNumber;

  uint singleUpdateFeeInWei;
  uint validTimePeriod;

  constructor(uint _validTimePeriod, uint _singleUpdateFeeInWei) {
    singleUpdateFeeInWei = _singleUpdateFeeInWei;
    validTimePeriod = _validTimePeriod;
  }

  function queryPriceFeed(
    bytes32 id
  ) public view override returns (PythStructs.PriceFeed memory priceFeed) {
    if (priceFeeds[id].id == 0) revert PythErrors.PriceFeedNotFound();
    return priceFeeds[id];
  }

  function priceFeedExists(bytes32 id) public view override returns (bool) {
    return (priceFeeds[id].id != 0);
  }

  function getValidTimePeriod() public view override returns (uint) {
    return validTimePeriod;
  }

  // Takes an array of encoded price feeds and stores them.
  // You can create this data either by calling createPriceFeedData or
  // by using web3.js or ethers abi utilities.
  function updatePriceFeeds(bytes[] calldata updateData) public payable override {
    uint requiredFee = getUpdateFee(updateData);
    if (msg.value < requiredFee) revert PythErrors.InsufficientFee();

    // Chain ID is id of the source chain that the price update comes from. Since it is just a mock contract
    // We set it to 1.
    uint16 chainId = 1;

    for (uint i = 0; i < updateData.length; i++) {
      PythStructs.PriceFeed memory priceFeed = abi.decode(updateData[i], (PythStructs.PriceFeed));

      uint lastPublishTime = priceFeeds[priceFeed.id].price.publishTime;

      if (lastPublishTime < priceFeed.price.publishTime) {
        // Price information is more recent than the existing price information.
        priceFeeds[priceFeed.id] = priceFeed;
        emit PriceFeedUpdate(
          priceFeed.id,
          uint64(lastPublishTime),
          priceFeed.price.price,
          priceFeed.price.conf
        );
      }
    }

    // In the real contract, the input of this function contains multiple batches that each contain multiple prices.
    // This event is emitted when a batch is processed. In this mock contract we consider there is only one batch of prices.
    // Each batch has (chainId, sequenceNumber) as it's unique identifier. Here chainId is set to 1 and an increasing sequence number is used.
    emit BatchPriceFeedUpdate(chainId, sequenceNumber);
    sequenceNumber += 1;
  }

  function getUpdateFee(bytes[] calldata updateData) public view override returns (uint feeAmount) {
    return singleUpdateFeeInWei * updateData.length;
  }

  function parsePriceFeedUpdates(
    bytes[] calldata updateData,
    bytes32[] calldata priceIds,
    uint64 minPublishTime,
    uint64 maxPublishTime
  ) external payable override returns (PythStructs.PriceFeed[] memory feeds) {
    uint requiredFee = getUpdateFee(updateData);
    if (msg.value < requiredFee) revert PythErrors.InsufficientFee();

    feeds = new PythStructs.PriceFeed[](priceIds.length);

    for (uint i = 0; i < priceIds.length; i++) {
      for (uint j = 0; j < updateData.length; j++) {
        feeds[i] = abi.decode(updateData[j], (PythStructs.PriceFeed));

        if (feeds[i].id == priceIds[i]) {
          uint publishTime = feeds[i].price.publishTime;
          if (minPublishTime <= publishTime && publishTime <= maxPublishTime) {
            break;
          } else {
            feeds[i].id = 0;
          }
        }
      }

      if (feeds[i].id != priceIds[i]) revert PythErrors.PriceFeedNotFoundWithinRange();
    }
  }

  function createPriceFeedUpdateData(
    bytes32 id,
    int64 price,
    uint64 conf,
    int32 expo,
    int64 emaPrice,
    uint64 emaConf,
    uint64 publishTime
  ) public pure returns (bytes memory priceFeedData) {
    PythStructs.PriceFeed memory priceFeed;

    priceFeed.id = id;

    priceFeed.price.price = price;
    priceFeed.price.conf = conf;
    priceFeed.price.expo = expo;
    priceFeed.price.publishTime = publishTime;

    priceFeed.emaPrice.price = emaPrice;
    priceFeed.emaPrice.conf = emaConf;
    priceFeed.emaPrice.expo = expo;
    priceFeed.emaPrice.publishTime = publishTime;

    priceFeedData = abi.encode(priceFeed);
  }
}


// File contracts/interfaces/IPoolAddressesProvider.sol

pragma solidity ^0.8.0;

/**
 * @title IPoolAddressesProvider
 * @author Aave
 * @notice Defines the basic interface for a Pool Addresses Provider.
 */
interface IPoolAddressesProvider {
  /**
   * @dev Emitted when the market identifier is updated.
   * @param oldMarketId The old id of the market
   * @param newMarketId The new id of the market
   */
  event MarketIdSet(string indexed oldMarketId, string indexed newMarketId);

  /**
   * @dev Emitted when the pool is updated.
   * @param oldAddress The old address of the Pool
   * @param newAddress The new address of the Pool
   */
  event PoolUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the pool configurator is updated.
   * @param oldAddress The old address of the PoolConfigurator
   * @param newAddress The new address of the PoolConfigurator
   */
  event PoolConfiguratorUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the price oracle is updated.
   * @param oldAddress The old address of the PriceOracle
   * @param newAddress The new address of the PriceOracle
   */
  event PriceOracleUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the ACL manager is updated.
   * @param oldAddress The old address of the ACLManager
   * @param newAddress The new address of the ACLManager
   */
  event ACLManagerUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the ACL admin is updated.
   * @param oldAddress The old address of the ACLAdmin
   * @param newAddress The new address of the ACLAdmin
   */
  event ACLAdminUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the price oracle sentinel is updated.
   * @param oldAddress The old address of the PriceOracleSentinel
   * @param newAddress The new address of the PriceOracleSentinel
   */
  event PriceOracleSentinelUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the pool data provider is updated.
   * @param oldAddress The old address of the PoolDataProvider
   * @param newAddress The new address of the PoolDataProvider
   */
  event PoolDataProviderUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when a new proxy is created.
   * @param id The identifier of the proxy
   * @param proxyAddress The address of the created proxy contract
   * @param implementationAddress The address of the implementation contract
   */
  event ProxyCreated(
    bytes32 indexed id,
    address indexed proxyAddress,
    address indexed implementationAddress
  );

  /**
   * @dev Emitted when a new non-proxied contract address is registered.
   * @param id The identifier of the contract
   * @param oldAddress The address of the old contract
   * @param newAddress The address of the new contract
   */
  event AddressSet(bytes32 indexed id, address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the implementation of the proxy registered with id is updated
   * @param id The identifier of the contract
   * @param proxyAddress The address of the proxy contract
   * @param oldImplementationAddress The address of the old implementation contract
   * @param newImplementationAddress The address of the new implementation contract
   */
  event AddressSetAsProxy(
    bytes32 indexed id,
    address indexed proxyAddress,
    address oldImplementationAddress,
    address indexed newImplementationAddress
  );

  /**
   * @notice Returns the id of the Aave market to which this contract points to.
   * @return The market id
   */
  function getMarketId() external view returns (string memory);

  /**
   * @notice Associates an id with a specific PoolAddressesProvider.
   * @dev This can be used to create an onchain registry of PoolAddressesProviders to
   * identify and validate multiple Aave markets.
   * @param newMarketId The market id
   */
  function setMarketId(string calldata newMarketId) external;

  /**
   * @notice Returns an address by its identifier.
   * @dev The returned address might be an EOA or a contract, potentially proxied
   * @dev It returns ZERO if there is no registered address with the given id
   * @param id The id
   * @return The address of the registered for the specified id
   */
  function getAddress(bytes32 id) external view returns (address);

  /**
   * @notice General function to update the implementation of a proxy registered with
   * certain `id`. If there is no proxy registered, it will instantiate one and
   * set as implementation the `newImplementationAddress`.
   * @dev IMPORTANT Use this function carefully, only for ids that don't have an explicit
   * setter function, in order to avoid unexpected consequences
   * @param id The id
   * @param newImplementationAddress The address of the new implementation
   */
  function setAddressAsProxy(bytes32 id, address newImplementationAddress) external;

  /**
   * @notice Sets an address for an id replacing the address saved in the addresses map.
   * @dev IMPORTANT Use this function carefully, as it will do a hard replacement
   * @param id The id
   * @param newAddress The address to set
   */
  function setAddress(bytes32 id, address newAddress) external;

  /**
   * @notice Returns the address of the Pool proxy.
   * @return The Pool proxy address
   */
  function getPool() external view returns (address);

  /**
   * @notice Updates the implementation of the Pool, or creates a proxy
   * setting the new `pool` implementation when the function is called for the first time.
   * @param newPoolImpl The new Pool implementation
   */
  function setPoolImpl(address newPoolImpl) external;

  /**
   * @notice Returns the address of the PoolConfigurator proxy.
   * @return The PoolConfigurator proxy address
   */
  function getPoolConfigurator() external view returns (address);

  /**
   * @notice Updates the implementation of the PoolConfigurator, or creates a proxy
   * setting the new `PoolConfigurator` implementation when the function is called for the first time.
   * @param newPoolConfiguratorImpl The new PoolConfigurator implementation
   */
  function setPoolConfiguratorImpl(address newPoolConfiguratorImpl) external;

  /**
   * @notice Returns the address of the price oracle.
   * @return The address of the PriceOracle
   */
  function getPriceOracle() external view returns (address);

  /**
   * @notice Updates the address of the price oracle.
   * @param newPriceOracle The address of the new PriceOracle
   */
  function setPriceOracle(address newPriceOracle) external;

  /**
   * @notice Returns the address of the ACL manager.
   * @return The address of the ACLManager
   */
  function getACLManager() external view returns (address);

  /**
   * @notice Updates the address of the ACL manager.
   * @param newAclManager The address of the new ACLManager
   */
  function setACLManager(address newAclManager) external;

  /**
   * @notice Returns the address of the ACL admin.
   * @return The address of the ACL admin
   */
  function getACLAdmin() external view returns (address);

  /**
   * @notice Updates the address of the ACL admin.
   * @param newAclAdmin The address of the new ACL admin
   */
  function setACLAdmin(address newAclAdmin) external;

  /**
   * @notice Returns the address of the price oracle sentinel.
   * @return The address of the PriceOracleSentinel
   */
  function getPriceOracleSentinel() external view returns (address);

  /**
   * @notice Updates the address of the price oracle sentinel.
   * @param newPriceOracleSentinel The address of the new PriceOracleSentinel
   */
  function setPriceOracleSentinel(address newPriceOracleSentinel) external;

  /**
   * @notice Returns the address of the data provider.
   * @return The address of the DataProvider
   */
  function getPoolDataProvider() external view returns (address);

  /**
   * @notice Updates the address of the data provider.
   * @param newDataProvider The address of the new DataProvider
   */
  function setPoolDataProvider(address newDataProvider) external;
}


// File contracts/interfaces/IPriceOracleGetter.sol

pragma solidity ^0.8.0;

/**
 * @title IPriceOracleGetter
 * @author Aave
 * @notice Interface for the Aave price oracle.
 */
interface IPriceOracleGetter {
  /**
   * @notice Returns the base currency address
   * @dev Address 0x0 is reserved for USD as base currency.
   * @return Returns the base currency address.
   */
  function BASE_CURRENCY() external view returns (address);

  /**
   * @notice Returns the base currency unit
   * @dev 1 ether for ETH, 1e8 for USD.
   * @return Returns the base currency unit.
   */
  function BASE_CURRENCY_UNIT() external view returns (uint256);

  /**
   * @notice Returns the asset price in the base currency
   * @param asset The address of the asset
   * @return The price of the asset
   */
  function getAssetPrice(address asset) external view returns (uint256);

  /**
   * @notice Updates the Pyth oracle price
   * @param priceUpdateData The bytes array that holds the encoded price info to update with
   */
  function updatePythPrice(bytes[] calldata priceUpdateData) external payable;

  receive() external payable;
}


// File contracts/interfaces/IAaveOracle.sol

pragma solidity ^0.8.0;


/**
 * @title IAaveOracle
 * @author Aave
 * @notice Defines the basic interface for the Aave Oracle
 */
interface IAaveOracle is IPriceOracleGetter {
  /**
   * @dev Emitted after the base currency is set
   * @param baseCurrency The base currency of used for price quotes
   * @param baseCurrencyUnit The unit of the base currency
   */
  event BaseCurrencySet(address indexed baseCurrency, uint256 baseCurrencyUnit);

  /**
   * @dev Emitted after the price source of an asset is updated
   * @param asset The address of the asset
   * @param source The price source of the asset
   */
  event AssetSourceUpdated(address indexed asset, bytes32 indexed source);

  /**
   * @dev Emitted after the address of fallback oracle is updated
   * @param fallbackOracle The address of the fallback oracle
   */
  event FallbackOracleUpdated(address indexed fallbackOracle);

  /**
   * @dev Emitted after the address of Pyth oracle is updated
   * @param pythOracle The address of the Pyth oracle
   * @param oracleMinFreshness The minimum freshness of Pyth price to be able to use that in the protocol
   */
  event PythOracleUpdated(address indexed pythOracle, uint oracleMinFreshness);

  /**
   * @notice Returns the PoolAddressesProvider
   * @return The address of the PoolAddressesProvider contract
   */
  function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

  /**
   * @notice Sets or replaces price sources of assets
   * @param assets The addresses of the assets
   * @param sources The bytes32 of the price sources
   */
  function setAssetSources(address[] calldata assets, bytes32[] calldata sources) external;

  /**
   * @notice Sets the fallback oracle
   * @param fallbackOracle The address of the fallback oracle
   */
  function setFallbackOracle(address fallbackOracle) external;

  /**
   * @notice Returns a list of prices from a list of assets addresses
   * @param assets The list of assets addresses
   * @return The prices of the given assets
   */
  function getAssetsPrices(address[] calldata assets) external view returns (uint256[] memory);

  /**
   * @notice Returns the address of the source for an asset address
   * @param asset The address of the asset
   * @return The address of the source
   */
  function getSourceOfAsset(address asset) external view returns (bytes32);

  /**
   * @notice Returns the address of the fallback oracle
   * @return The address of the fallback oracle
   */
  function getFallbackOracle() external view returns (address);

  /**
   * @notice Updates the Pyth oracle price
   * @param priceUpdateData The bytes array that holds the encoded price info to update with
   */
  function updatePythPrice(bytes[] calldata priceUpdateData) external payable;
}


// File contracts/interfaces/IACLManager.sol

pragma solidity ^0.8.0;

/**
 * @title IACLManager
 * @author Aave
 * @notice Defines the basic interface for the ACL Manager
 */
interface IACLManager {
  /**
   * @notice Returns the contract address of the PoolAddressesProvider
   * @return The address of the PoolAddressesProvider
   */
  function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

  /**
   * @notice Returns the identifier of the PoolAdmin role
   * @return The id of the PoolAdmin role
   */
  function POOL_ADMIN_ROLE() external view returns (bytes32);

  /**
   * @notice Returns the identifier of the EmergencyAdmin role
   * @return The id of the EmergencyAdmin role
   */
  function EMERGENCY_ADMIN_ROLE() external view returns (bytes32);

  /**
   * @notice Returns the identifier of the RiskAdmin role
   * @return The id of the RiskAdmin role
   */
  function RISK_ADMIN_ROLE() external view returns (bytes32);

  /**
   * @notice Returns the identifier of the FlashBorrower role
   * @return The id of the FlashBorrower role
   */
  function FLASH_BORROWER_ROLE() external view returns (bytes32);

  /**
   * @notice Returns the identifier of the Bridge role
   * @return The id of the Bridge role
   */
  function BRIDGE_ROLE() external view returns (bytes32);

  /**
   * @notice Returns the identifier of the AssetListingAdmin role
   * @return The id of the AssetListingAdmin role
   */
  function ASSET_LISTING_ADMIN_ROLE() external view returns (bytes32);

  /**
   * @notice Set the role as admin of a specific role.
   * @dev By default the admin role for all roles is `DEFAULT_ADMIN_ROLE`.
   * @param role The role to be managed by the admin role
   * @param adminRole The admin role
   */
  function setRoleAdmin(bytes32 role, bytes32 adminRole) external;

  /**
   * @notice Adds a new admin as PoolAdmin
   * @param admin The address of the new admin
   */
  function addPoolAdmin(address admin) external;

  /**
   * @notice Removes an admin as PoolAdmin
   * @param admin The address of the admin to remove
   */
  function removePoolAdmin(address admin) external;

  /**
   * @notice Returns true if the address is PoolAdmin, false otherwise
   * @param admin The address to check
   * @return True if the given address is PoolAdmin, false otherwise
   */
  function isPoolAdmin(address admin) external view returns (bool);

  /**
   * @notice Adds a new admin as EmergencyAdmin
   * @param admin The address of the new admin
   */
  function addEmergencyAdmin(address admin) external;

  /**
   * @notice Removes an admin as EmergencyAdmin
   * @param admin The address of the admin to remove
   */
  function removeEmergencyAdmin(address admin) external;

  /**
   * @notice Returns true if the address is EmergencyAdmin, false otherwise
   * @param admin The address to check
   * @return True if the given address is EmergencyAdmin, false otherwise
   */
  function isEmergencyAdmin(address admin) external view returns (bool);

  /**
   * @notice Adds a new admin as RiskAdmin
   * @param admin The address of the new admin
   */
  function addRiskAdmin(address admin) external;

  /**
   * @notice Removes an admin as RiskAdmin
   * @param admin The address of the admin to remove
   */
  function removeRiskAdmin(address admin) external;

  /**
   * @notice Returns true if the address is RiskAdmin, false otherwise
   * @param admin The address to check
   * @return True if the given address is RiskAdmin, false otherwise
   */
  function isRiskAdmin(address admin) external view returns (bool);

  /**
   * @notice Adds a new address as FlashBorrower
   * @param borrower The address of the new FlashBorrower
   */
  function addFlashBorrower(address borrower) external;

  /**
   * @notice Removes an address as FlashBorrower
   * @param borrower The address of the FlashBorrower to remove
   */
  function removeFlashBorrower(address borrower) external;

  /**
   * @notice Returns true if the address is FlashBorrower, false otherwise
   * @param borrower The address to check
   * @return True if the given address is FlashBorrower, false otherwise
   */
  function isFlashBorrower(address borrower) external view returns (bool);

  /**
   * @notice Adds a new address as Bridge
   * @param bridge The address of the new Bridge
   */
  function addBridge(address bridge) external;

  /**
   * @notice Removes an address as Bridge
   * @param bridge The address of the bridge to remove
   */
  function removeBridge(address bridge) external;

  /**
   * @notice Returns true if the address is Bridge, false otherwise
   * @param bridge The address to check
   * @return True if the given address is Bridge, false otherwise
   */
  function isBridge(address bridge) external view returns (bool);

  /**
   * @notice Adds a new admin as AssetListingAdmin
   * @param admin The address of the new admin
   */
  function addAssetListingAdmin(address admin) external;

  /**
   * @notice Removes an admin as AssetListingAdmin
   * @param admin The address of the admin to remove
   */
  function removeAssetListingAdmin(address admin) external;

  /**
   * @notice Returns true if the address is AssetListingAdmin, false otherwise
   * @param admin The address to check
   * @return True if the given address is AssetListingAdmin, false otherwise
   */
  function isAssetListingAdmin(address admin) external view returns (bool);
}


// File contracts/protocol/libraries/helpers/Errors.sol

pragma solidity ^0.8.0;

/**
 * @title Errors library
 * @author Aave
 * @notice Defines the error messages emitted by the different contracts of the Aave protocol
 */
library Errors {
  string public constant CALLER_NOT_POOL_ADMIN = '1'; // 'The caller of the function is not a pool admin'
  string public constant CALLER_NOT_EMERGENCY_ADMIN = '2'; // 'The caller of the function is not an emergency admin'
  string public constant CALLER_NOT_POOL_OR_EMERGENCY_ADMIN = '3'; // 'The caller of the function is not a pool or emergency admin'
  string public constant CALLER_NOT_RISK_OR_POOL_ADMIN = '4'; // 'The caller of the function is not a risk or pool admin'
  string public constant CALLER_NOT_ASSET_LISTING_OR_POOL_ADMIN = '5'; // 'The caller of the function is not an asset listing or pool admin'
  string public constant CALLER_NOT_BRIDGE = '6'; // 'The caller of the function is not a bridge'
  string public constant ADDRESSES_PROVIDER_NOT_REGISTERED = '7'; // 'Pool addresses provider is not registered'
  string public constant INVALID_ADDRESSES_PROVIDER_ID = '8'; // 'Invalid id for the pool addresses provider'
  string public constant NOT_CONTRACT = '9'; // 'Address is not a contract'
  string public constant CALLER_NOT_POOL_CONFIGURATOR = '10'; // 'The caller of the function is not the pool configurator'
  string public constant CALLER_NOT_ATOKEN = '11'; // 'The caller of the function is not an AToken'
  string public constant INVALID_ADDRESSES_PROVIDER = '12'; // 'The address of the pool addresses provider is invalid'
  string public constant INVALID_FLASHLOAN_EXECUTOR_RETURN = '13'; // 'Invalid return value of the flashloan executor function'
  string public constant RESERVE_ALREADY_ADDED = '14'; // 'Reserve has already been added to reserve list'
  string public constant NO_MORE_RESERVES_ALLOWED = '15'; // 'Maximum amount of reserves in the pool reached'
  string public constant EMODE_CATEGORY_RESERVED = '16'; // 'Zero eMode category is reserved for volatile heterogeneous assets'
  string public constant INVALID_EMODE_CATEGORY_ASSIGNMENT = '17'; // 'Invalid eMode category assignment to asset'
  string public constant RESERVE_LIQUIDITY_NOT_ZERO = '18'; // 'The liquidity of the reserve needs to be 0'
  string public constant FLASHLOAN_PREMIUM_INVALID = '19'; // 'Invalid flashloan premium'
  string public constant INVALID_RESERVE_PARAMS = '20'; // 'Invalid risk parameters for the reserve'
  string public constant INVALID_EMODE_CATEGORY_PARAMS = '21'; // 'Invalid risk parameters for the eMode category'
  string public constant BRIDGE_PROTOCOL_FEE_INVALID = '22'; // 'Invalid bridge protocol fee'
  string public constant CALLER_MUST_BE_POOL = '23'; // 'The caller of this function must be a pool'
  string public constant INVALID_MINT_AMOUNT = '24'; // 'Invalid amount to mint'
  string public constant INVALID_BURN_AMOUNT = '25'; // 'Invalid amount to burn'
  string public constant INVALID_AMOUNT = '26'; // 'Amount must be greater than 0'
  string public constant RESERVE_INACTIVE = '27'; // 'Action requires an active reserve'
  string public constant RESERVE_FROZEN = '28'; // 'Action cannot be performed because the reserve is frozen'
  string public constant RESERVE_PAUSED = '29'; // 'Action cannot be performed because the reserve is paused'
  string public constant BORROWING_NOT_ENABLED = '30'; // 'Borrowing is not enabled'
  string public constant STABLE_BORROWING_NOT_ENABLED = '31'; // 'Stable borrowing is not enabled'
  string public constant NOT_ENOUGH_AVAILABLE_USER_BALANCE = '32'; // 'User cannot withdraw more than the available balance'
  string public constant INVALID_INTEREST_RATE_MODE_SELECTED = '33'; // 'Invalid interest rate mode selected'
  string public constant COLLATERAL_BALANCE_IS_ZERO = '34'; // 'The collateral balance is 0'
  string public constant HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD = '35'; // 'Health factor is lesser than the liquidation threshold'
  string public constant COLLATERAL_CANNOT_COVER_NEW_BORROW = '36'; // 'There is not enough collateral to cover a new borrow'
  string public constant COLLATERAL_SAME_AS_BORROWING_CURRENCY = '37'; // 'Collateral is (mostly) the same currency that is being borrowed'
  string public constant AMOUNT_BIGGER_THAN_MAX_LOAN_SIZE_STABLE = '38'; // 'The requested amount is greater than the max loan size in stable rate mode'
  string public constant NO_DEBT_OF_SELECTED_TYPE = '39'; // 'For repayment of a specific type of debt, the user needs to have debt that type'
  string public constant NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF = '40'; // 'To repay on behalf of a user an explicit amount to repay is needed'
  string public constant NO_OUTSTANDING_STABLE_DEBT = '41'; // 'User does not have outstanding stable rate debt on this reserve'
  string public constant NO_OUTSTANDING_VARIABLE_DEBT = '42'; // 'User does not have outstanding variable rate debt on this reserve'
  string public constant UNDERLYING_BALANCE_ZERO = '43'; // 'The underlying balance needs to be greater than 0'
  string public constant INTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET = '44'; // 'Interest rate rebalance conditions were not met'
  string public constant HEALTH_FACTOR_NOT_BELOW_THRESHOLD = '45'; // 'Health factor is not below the threshold'
  string public constant COLLATERAL_CANNOT_BE_LIQUIDATED = '46'; // 'The collateral chosen cannot be liquidated'
  string public constant SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER = '47'; // 'User did not borrow the specified currency'
  string public constant INCONSISTENT_FLASHLOAN_PARAMS = '49'; // 'Inconsistent flashloan parameters'
  string public constant BORROW_CAP_EXCEEDED = '50'; // 'Borrow cap is exceeded'
  string public constant SUPPLY_CAP_EXCEEDED = '51'; // 'Supply cap is exceeded'
  string public constant UNBACKED_MINT_CAP_EXCEEDED = '52'; // 'Unbacked mint cap is exceeded'
  string public constant DEBT_CEILING_EXCEEDED = '53'; // 'Debt ceiling is exceeded'
  string public constant UNDERLYING_CLAIMABLE_RIGHTS_NOT_ZERO = '54'; // 'Claimable rights over underlying not zero (aToken supply or accruedToTreasury)'
  string public constant STABLE_DEBT_NOT_ZERO = '55'; // 'Stable debt supply is not zero'
  string public constant VARIABLE_DEBT_SUPPLY_NOT_ZERO = '56'; // 'Variable debt supply is not zero'
  string public constant LTV_VALIDATION_FAILED = '57'; // 'Ltv validation failed'
  string public constant INCONSISTENT_EMODE_CATEGORY = '58'; // 'Inconsistent eMode category'
  string public constant PRICE_ORACLE_SENTINEL_CHECK_FAILED = '59'; // 'Price oracle sentinel validation failed'
  string public constant ASSET_NOT_BORROWABLE_IN_ISOLATION = '60'; // 'Asset is not borrowable in isolation mode'
  string public constant RESERVE_ALREADY_INITIALIZED = '61'; // 'Reserve has already been initialized'
  string public constant USER_IN_ISOLATION_MODE = '62'; // 'User is in isolation mode'
  string public constant INVALID_LTV = '63'; // 'Invalid ltv parameter for the reserve'
  string public constant INVALID_LIQ_THRESHOLD = '64'; // 'Invalid liquidity threshold parameter for the reserve'
  string public constant INVALID_LIQ_BONUS = '65'; // 'Invalid liquidity bonus parameter for the reserve'
  string public constant INVALID_DECIMALS = '66'; // 'Invalid decimals parameter of the underlying asset of the reserve'
  string public constant INVALID_RESERVE_FACTOR = '67'; // 'Invalid reserve factor parameter for the reserve'
  string public constant INVALID_BORROW_CAP = '68'; // 'Invalid borrow cap for the reserve'
  string public constant INVALID_SUPPLY_CAP = '69'; // 'Invalid supply cap for the reserve'
  string public constant INVALID_LIQUIDATION_PROTOCOL_FEE = '70'; // 'Invalid liquidation protocol fee for the reserve'
  string public constant INVALID_EMODE_CATEGORY = '71'; // 'Invalid eMode category for the reserve'
  string public constant INVALID_UNBACKED_MINT_CAP = '72'; // 'Invalid unbacked mint cap for the reserve'
  string public constant INVALID_DEBT_CEILING = '73'; // 'Invalid debt ceiling for the reserve
  string public constant INVALID_RESERVE_INDEX = '74'; // 'Invalid reserve index'
  string public constant ACL_ADMIN_CANNOT_BE_ZERO = '75'; // 'ACL admin cannot be set to the zero address'
  string public constant INCONSISTENT_PARAMS_LENGTH = '76'; // 'Array parameters that should be equal length are not'
  string public constant ZERO_ADDRESS_NOT_VALID = '77'; // 'Zero address not valid'
  string public constant INVALID_EXPIRATION = '78'; // 'Invalid expiration'
  string public constant INVALID_SIGNATURE = '79'; // 'Invalid signature'
  string public constant OPERATION_NOT_SUPPORTED = '80'; // 'Operation not supported'
  string public constant DEBT_CEILING_NOT_ZERO = '81'; // 'Debt ceiling is not zero'
  string public constant ASSET_NOT_LISTED = '82'; // 'Asset is not listed'
  string public constant INVALID_OPTIMAL_USAGE_RATIO = '83'; // 'Invalid optimal usage ratio'
  string public constant INVALID_OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO = '84'; // 'Invalid optimal stable to total debt ratio'
  string public constant UNDERLYING_CANNOT_BE_RESCUED = '85'; // 'The underlying asset cannot be rescued'
  string public constant ADDRESSES_PROVIDER_ALREADY_ADDED = '86'; // 'Reserve has already been added to reserve list'
  string public constant POOL_ADDRESSES_DO_NOT_MATCH = '87'; // 'The token implementation pool address and the pool address provided by the initializing pool do not match'
  string public constant STABLE_BORROWING_ENABLED = '88'; // 'Stable borrowing is enabled'
  string public constant SILOED_BORROWING_VIOLATION = '89'; // 'User is trying to borrow multiple assets including a siloed one'
  string public constant RESERVE_DEBT_NOT_ZERO = '90'; // the total debt of the reserve needs to be 0
  string public constant FLASHLOAN_DISABLED = '91'; // FlashLoaning for this asset is disabled
}


// File contracts/misc/AaveOracle.sol

pragma solidity 0.8.10;








/**
 * @title AaveOracle
 * @author Aave
 * @notice Contract to get asset prices, manage price sources and update the fallback oracle
 * - Use of Pyth as first source of price
 * - If the returned price by Pyth is <= 0 or if the Pyth price is too stale, the call is forwarded to a fallback oracle
 * - Owned by the Aave governance
 */
contract AaveOracle is IAaveOracle {
  IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;

  // Map of asset price IDs (asset => priceID)
  mapping(address => bytes32) private assetsIDs;
  address _pythOracleAddress;
  IPyth _pythOracle;
  uint _oracleMinFreshness;

  IPriceOracleGetter private _fallbackOracle;
  address public immutable override BASE_CURRENCY;
  uint256 public immutable override BASE_CURRENCY_UNIT;

  /**
   * @dev Only asset listing or pool admin can call functions marked by this modifier.
   */
  modifier onlyAssetListingOrPoolAdmins() {
    _onlyAssetListingOrPoolAdmins();
    _;
  }

  /**
   * @notice Constructor
   * @param provider The address of the new PoolAddressesProvider
   * @param assets The addresses of the assets
   * @param sources The bytes32 of the priceID of each asset
   * @param fallbackOracle The address of the fallback oracle to use if Pyth data is not consistent
   * @param baseCurrency The base currency used for the price quotes. If USD is used, base currency is 0x0
   * @param baseCurrencyUnit The unit of the base currency
   * @param pythOracle The address of the Pyth oracle in this network
   * @param oracleMinFreshness The minimum freshness of Pyth price to be able to use that in the protocol
   */
  constructor(
    IPoolAddressesProvider provider,
    address[] memory assets,
    bytes32[] memory sources,
    address fallbackOracle,
    address baseCurrency,
    uint256 baseCurrencyUnit,
    address pythOracle,
    uint oracleMinFreshness
  ) {
    ADDRESSES_PROVIDER = provider;
    _setFallbackOracle(fallbackOracle);
    _setAssetsSources(assets, sources);
    BASE_CURRENCY = baseCurrency;
    BASE_CURRENCY_UNIT = baseCurrencyUnit;
    emit BaseCurrencySet(baseCurrency, baseCurrencyUnit);
    _setPythOracle(pythOracle, oracleMinFreshness);
  }

  /// @inheritdoc IAaveOracle
  function setAssetSources(
    address[] calldata assets,
    bytes32[] calldata sources
  ) external override onlyAssetListingOrPoolAdmins {
    _setAssetsSources(assets, sources);
  }

  /// @inheritdoc IAaveOracle
  function setFallbackOracle(
    address fallbackOracle
  ) external override onlyAssetListingOrPoolAdmins {
    _setFallbackOracle(fallbackOracle);
  }

  /**
   * @notice Internal function to set the sources for each asset
   * @param assets The addresses of the assets
   * @param sources The address of the priceID of each asset
   */
  function _setAssetsSources(address[] memory assets, bytes32[] memory sources) internal {
    require(assets.length == sources.length, Errors.INCONSISTENT_PARAMS_LENGTH);
    for (uint256 i = 0; i < assets.length; i++) {
      bytes32 priceID = sources[i];
      assetsIDs[assets[i]] = priceID;
      emit AssetSourceUpdated(assets[i], sources[i]);
    }
  }

  /**
   * @notice Internal function to set the fallback oracle
   * @param fallbackOracle The address of the fallback oracle
   */
  function _setFallbackOracle(address fallbackOracle) internal {
    _fallbackOracle = IPriceOracleGetter(payable(fallbackOracle));
    emit FallbackOracleUpdated(fallbackOracle);
  }

  /**
   * @notice Internal function to set the Pyth oracle
   * @param pythOracle The address of the Pyth oracle
   * @param oracleMinFreshness The minimum freshness of Pyth price to be able to use that in the protocol
   */
  function _setPythOracle(address pythOracle, uint oracleMinFreshness) internal {
    _pythOracleAddress = pythOracle;
    _pythOracle = IPyth(pythOracle);
    _oracleMinFreshness = oracleMinFreshness;
    emit PythOracleUpdated(pythOracle, oracleMinFreshness);
  }

  function getPythOracleAddress() external view returns (address) {
    return _pythOracleAddress;
  }

  function updatePythPrice(bytes[] calldata priceUpdateData) public payable override {
    // Update the prices to the latest available values and pay the required fee for it. The `priceUpdateData` data
    // should be retrieved from a Pyth off-chain Price Service API using the `pyth-evm-js` package.
    if (priceUpdateData.length > 0) {
      uint fee = _pythOracle.getUpdateFee(priceUpdateData);
      _pythOracle.updatePriceFeeds{value: fee}(priceUpdateData);
    }
  }

  function getLastUpdateTime(address asset) public view returns (uint) {
    bytes32 priceID = assetsIDs[asset];
    PythStructs.Price memory pythPrice;
    pythPrice = _pythOracle.getPriceUnsafe(priceID);
    return pythPrice.publishTime;
  }

  function getPythPriceStruct(
    address asset,
    bool isEma
  ) public view returns (PythStructs.Price memory pythPriceStruct) {
    bytes32 priceID = assetsIDs[asset];
    if (isEma) {
      pythPriceStruct = _pythOracle.getEmaPriceUnsafe(priceID);
    } else {
      pythPriceStruct = _pythOracle.getPriceUnsafe(priceID);
    }
  }

  /// @inheritdoc IPriceOracleGetter
  function getAssetPrice(address asset) public view override returns (uint256) {
    bytes32 priceID = assetsIDs[asset];

    if (asset == BASE_CURRENCY) {
      return BASE_CURRENCY_UNIT;
    } else if (priceID == bytes32(0)) {
      return _fallbackOracle.getAssetPrice(asset);
    } else {
      PythStructs.Price memory pythPrice;
      uint validTime;
      // TODO: use getPriceNoOlderThan if figure out how to handle specific reverts--not sure how to in Solidity
      pythPrice = _pythOracle.getPriceUnsafe(priceID);
      validTime = _pythOracle.getValidTimePeriod();

      int256 price = int256(pythPrice.price);
      bool stalePyth;
      bool staleProtocol;
      if (block.timestamp >= pythPrice.publishTime) {
        stalePyth = (block.timestamp - pythPrice.publishTime) > validTime;
        staleProtocol = (block.timestamp - pythPrice.publishTime) > _oracleMinFreshness;
      } else {
        stalePyth = (pythPrice.publishTime - block.timestamp) > validTime;
        staleProtocol = (pythPrice.publishTime - block.timestamp) > _oracleMinFreshness;
      }
      if (price > 0 && !stalePyth && !staleProtocol) {
        return uint256(price);
      } else {
        return _fallbackOracle.getAssetPrice(asset);
      }
    }
  }

  /// @inheritdoc IAaveOracle
  function getAssetsPrices(
    address[] calldata assets
  ) external view override returns (uint256[] memory) {
    uint256[] memory prices = new uint256[](assets.length);
    for (uint256 i = 0; i < assets.length; i++) {
      prices[i] = getAssetPrice(assets[i]);
    }
    return prices;
  }

  /// @inheritdoc IAaveOracle
  function getSourceOfAsset(address asset) external view override returns (bytes32) {
    return assetsIDs[asset];
  }

  /// @inheritdoc IAaveOracle
  function getFallbackOracle() external view returns (address) {
    return address(_fallbackOracle);
  }

  function _onlyAssetListingOrPoolAdmins() internal view {
    IACLManager aclManager = IACLManager(ADDRESSES_PROVIDER.getACLManager());
    require(
      aclManager.isAssetListingAdmin(msg.sender) || aclManager.isPoolAdmin(msg.sender),
      Errors.CALLER_NOT_ASSET_LISTING_OR_POOL_ADMIN
    );
  }

  receive() external payable {}
}
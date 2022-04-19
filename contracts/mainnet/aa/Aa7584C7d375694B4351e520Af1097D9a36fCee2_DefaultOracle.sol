// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/openzeppelin/utils/Context.sol";
import "../dependencies/openzeppelin/proxy/utils/Initializable.sol";
import "../interface/IGovernable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (governor) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the governor account will be the one that deploys the contract. This
 * can later be changed with {transferGovernorship}.
 *
 */
abstract contract Governable is IGovernable, Context, Initializable {
    address public governor;
    address public proposedGovernor;

    event UpdatedGovernor(address indexed previousGovernor, address indexed proposedGovernor);

    /**
     * @dev Initializes the contract setting the deployer as the initial governor.
     */
    constructor() {
        address msgSender = _msgSender();
        governor = msgSender;
        emit UpdatedGovernor(address(0), msgSender);
    }

    /**
     * @dev If inheriting child is using proxy then child contract can use
     * __Governable_init() function to initialization this contract
     */
    // solhint-disable-next-line func-name-mixedcase
    function __Governable_init() internal initializer {
        address msgSender = _msgSender();
        governor = msgSender;
        emit UpdatedGovernor(address(0), msgSender);
    }

    /**
     * @dev Throws if called by any account other than the governor.
     */
    modifier onlyGovernor() {
        require(governor == _msgSender(), "not-governor");
        _;
    }

    /**
     * @dev Transfers governorship of the contract to a new account (`proposedGovernor`).
     * Can only be called by the current owner.
     */
    function transferGovernorship(address _proposedGovernor) external onlyGovernor {
        require(_proposedGovernor != address(0), "proposed-governor-is-zero");
        proposedGovernor = _proposedGovernor;
    }

    /**
     * @dev Allows new governor to accept governorship of the contract.
     */
    function acceptGovernorship() external {
        require(proposedGovernor == _msgSender(), "not-the-proposed-governor");
        emit UpdatedGovernor(governor, proposedGovernor);
        governor = proposedGovernor;
        proposedGovernor = address(0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @notice Governable interface
 */
interface IGovernable {
    function governor() external view returns (address _governor);

    function transferGovernorship(address _proposedGovernor) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../../dependencies/openzeppelin/token/ERC20/IERC20.sol";
import "./IPriceProvider.sol";

interface IOracle {
    function getPriceInUsd(IERC20 _asset) external view returns (uint256 _priceInUsd);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IPriceProvider {
    function update(bytes calldata _assetData) external;

    function getPriceInUsd(bytes calldata _assetData)
        external
        view
        returns (uint256 _priceInUsd, uint256 _lastUpdatedAt);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";
import "../access/Governable.sol";
import "../interface/oracle/IOracle.sol";
import "../interface/oracle/IPriceProvider.sol";

/**
 * @title Oracle contract that encapsulates 3rd-party protocols' oracles
 */
contract DefaultOracle is IOracle, Governable {
    uint256 public constant ONE_USD = 1e18;

    /**
     * @notice The supported protocols
     */
    enum Protocol {
        NONE,
        UNISWAP_V3,
        UNISWAP_V2,
        CHAINLINK
    }

    /**
     * @notice Asset's oracle setup
     * @dev I.e. maps the oracle used by each asset
     */
    struct Asset {
        Protocol protocol;
        bytes assetData; // encoded data used for queries on price providers
        bool isUsd; // i.e. when true no oracle query is needed (amountOut = amountIn)
        uint256 stalePeriod; // it's used to determine if a price is invalid (i.e. outdated)
    }

    /**
     * @notice Avaliable assets
     */
    mapping(IERC20 => Asset) public assets;

    /**
     * @notice Get the price provider contract for each protocol
     */
    mapping(Protocol => IPriceProvider) public providerByProtocol;

    /// @notice Emitted when a price provider is updated
    event PriceProviderUpdated(Protocol protocol, IPriceProvider oldPriceProvider, IPriceProvider newPriceProvider);

    /// @notice Emitted when asset setup is updated
    event AssetUpdated(IERC20 indexed asset, Protocol protocol, bytes assetData, bool isUsd, uint256 stalePeriod);

    /**
     * @dev Throws if the asset isn't avaliable
     */
    modifier onlyIfAssetHasPriceProvider(IERC20 _asset) {
        require(assets[_asset].isUsd || assets[_asset].protocol != Protocol.NONE, "asset-has-no-price-provider");
        _;
    }

    /**
     * @dev Get the price provider contract of an asset
     */
    function _priceProviderOfAsset(IERC20 _asset) private view returns (IPriceProvider) {
        return providerByProtocol[assets[_asset].protocol];
    }

    /**
     * @dev Get encoded data of an asset
     */
    function _dataOfAsset(IERC20 _asset) private view returns (bytes memory) {
        return assets[_asset].assetData;
    }

    /**
     * @notice Set the price provider of a protocol
     * @dev This function is also used for update a price provider
     * @param _protocol The protocol
     * @param _priceProvider The price provider protocol
     */
    function setPriceProvider(Protocol _protocol, IPriceProvider _priceProvider) external onlyGovernor {
        require(address(_priceProvider) != address(0), "provider-address-null");
        IPriceProvider _currentPriceProvider = providerByProtocol[_protocol];
        require(_priceProvider != _currentPriceProvider, "new-same-as-current");
        providerByProtocol[_protocol] = _priceProvider;
        emit PriceProviderUpdated(_protocol, _currentPriceProvider, _priceProvider);
    }

    /**
     * @notice Check if a price timestamp is outdated
     * @param _timeOfLastUpdate The price timestamp
     * @return true if  price is stale (outdated)
     */
    function _priceIsStale(IERC20 _asset, uint256 _timeOfLastUpdate) private view returns (bool) {
        return block.timestamp - _timeOfLastUpdate > assets[_asset].stalePeriod;
    }

    /**
     * @notice Store an asset
     * @param _asset The asset to store
     * @param _protocol The protocol to use as source of price
     * @param _assetData The asset's encoded data
     * @param _isUsd If the asset is a USD token coin
     */
    function _addOrUpdateAsset(
        IERC20 _asset,
        Protocol _protocol,
        bytes memory _assetData,
        bool _isUsd,
        uint256 _stalePeriod
    ) private {
        require(address(_asset) != address(0), "asset-address-is-null");
        assets[_asset] = Asset({protocol: _protocol, assetData: _assetData, isUsd: _isUsd, stalePeriod: _stalePeriod});
        emit AssetUpdated(_asset, _protocol, _assetData, _isUsd, _stalePeriod);
    }

    /**
     * @notice Store an USD asset (no protocol)
     * @param _asset The asset to store
     */
    function addOrUpdateUsdAsset(IERC20 _asset) external onlyGovernor {
        _addOrUpdateAsset(_asset, Protocol.NONE, new bytes(0), true, type(uint256).max);
    }

    /**
     * @notice Store an asset that uses Chainlink source of price
     * @param _asset The asset to store
     * @param _aggregator The asset's chainlink aggregator contract
     * @param _stalePeriod The stale period
     */
    function addOrUpdateAssetThatUsesChainlink(
        IERC20Metadata _asset,
        address _aggregator,
        uint256 _stalePeriod
    ) external onlyGovernor {
        // Note: Keeping this check here because we call the `_asset.decimals()` function before calling `_addOrUpdateAsset`
        require(address(_asset) != address(0), "asset-address-is-null");
        require(address(_aggregator) != address(0), "aggregator-address-is-null");
        _addOrUpdateAsset(_asset, Protocol.CHAINLINK, abi.encode(_aggregator, _asset.decimals()), false, _stalePeriod);
    }

    /**
     * @notice Store an asset that uses UniswapV2 source of price
     * @param _asset The asset to store
     * @param _underlying The actual asset to get prices from (e.g. vsETH uses WETH)
     * @param _stalePeriod The stale period
     */
    function addOrUpdateAssetThatUsesUniswapV2(
        IERC20 _asset,
        IERC20 _underlying,
        uint256 _stalePeriod
    ) external onlyGovernor {
        require(address(_underlying) != address(0), "underlying-address-is-null");
        _addOrUpdateAsset(_asset, Protocol.UNISWAP_V2, abi.encode(_underlying), false, _stalePeriod);
    }

    /**
     * @notice Store an asset that uses UniswapV3 source of price
     * @dev This function is also used for update a asset setup
     * @param _asset The asset to store
     * @param _underlying The actual asset to get prices from (e.g. vsETH uses WETH)
     */
    function addOrUpdateAssetThatUsesUniswapV3(IERC20 _asset, IERC20 _underlying) external onlyGovernor {
        require(address(_underlying) != address(0), "underlying-address-is-null");
        _addOrUpdateAsset(_asset, Protocol.UNISWAP_V3, abi.encode(_underlying), false, type(uint256).max);
    }

    /**
     * @notice Update a asset's price
     * @param _asset The asset to update
     */
    // solhint-disable-next-line no-empty-blocks
    function update(IERC20 _asset) external {
        if (assets[_asset].protocol != Protocol.NONE) {
            _priceProviderOfAsset(_asset).update(_dataOfAsset(_asset));
        }
    }

    /**
     * @notice Get asset's USD price
     * @param _asset The asset's to get price from
     * @return _priceInUsd The amount in USD (18 decimals)
     */
    function getPriceInUsd(IERC20 _asset)
        external
        view
        onlyIfAssetHasPriceProvider(_asset)
        returns (uint256 _priceInUsd)
    {
        if (assets[_asset].isUsd) return ONE_USD;

        uint256 _lastUpdatedAt;
        (_priceInUsd, _lastUpdatedAt) = _priceProviderOfAsset(_asset).getPriceInUsd(_dataOfAsset(_asset));
        require(!_priceIsStale(_asset, _lastUpdatedAt), "price-is-stale");
    }
}
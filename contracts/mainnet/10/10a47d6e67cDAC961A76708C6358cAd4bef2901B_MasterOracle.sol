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

interface IMasterOracle {
    function convertToUsd(IERC20 _asset, uint256 _amount) external view returns (uint256 _amountInUsd);

    function convertFromUsd(IERC20 _asset, uint256 _amountInUsd) external view returns (uint256 _amount);

    function convert(
        IERC20 _assetIn,
        IERC20 _assetOut,
        uint256 _amountIn
    ) external view returns (uint256 _amountOut);
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
import "../interface/oracle/IMasterOracle.sol";
import "../interface/oracle/IOracle.sol";

/**
 * @title The Master oracle that is called by `Controller`
 */
contract MasterOracle is Initializable, IMasterOracle, Governable {
    /**
     * @notice Maps asset addresses to oracle contracts
     */
    mapping(address => IOracle) public oracles;

    /**
     * @notice The Default/fallback oracle
     */
    IOracle public defaultOracle;

    /**
     * @notice Event emitted when the default oracle is updated
     */
    event DefaultOracleUpdated(IOracle oldOracle, IOracle newOracle);

    /**
     * @notice Event emitted when a asset's oracle is updated
     */
    event OracleUpdated(address asset, IOracle oldOracle, IOracle newOracle);

    function initialize(
        address[] calldata _assets,
        IOracle[] calldata _oracles,
        IOracle _defaultOracle
    ) external initializer {
        __Governable_init();

        _updateOracles(_assets, _oracles);
        defaultOracle = _defaultOracle;
    }

    /**
     * @notice Sets `_oracles` for `_assets`.
     * @param _assets The ERC20 asset addresses to link to `_oracles`.
     * @param _oracles The `IOracle` contracts to be assigned to `_assets`.
     * @dev We allow null address inside of the `_oracles` array in order to turn off oracle for a given asset
     */
    function _updateOracles(address[] calldata _assets, IOracle[] calldata _oracles) private {
        uint256 _assetsLength = _assets.length;
        require(_assetsLength == _oracles.length, "invalid-arrays-length");

        for (uint256 i = 0; i < _assetsLength; i++) {
            address _asset = _assets[i];
            require(_asset != address(0), "an-asset-has-null-address");
            IOracle _currentOracle = oracles[_asset];
            IOracle _newOracle = _oracles[i];
            require(_newOracle != _currentOracle, "a-new-oracle-same-as-current");
            emit OracleUpdated(_asset, _currentOracle, _newOracle);
            oracles[_asset] = _newOracle;
        }
    }

    /**
     * @notice Add or update token oracles
     * @param _assets The ERC20 asset addresses to link to `_oracles`
     * @param _oracles The `IOracle` contracts to be assigned to `_assets`
     */
    function addOrUpdate(address[] calldata _assets, IOracle[] calldata _oracles) external onlyGovernor {
        require(_assets.length > 0 && _oracles.length > 0, "invalid-arrays-length");
        _updateOracles(_assets, _oracles);
    }

    /**
     * @notice Update the default oracle contract
     * @param _newDefaultOracle The new default oracle contract
     * @dev We allow null address in order to turn off the default oracle
     */
    function setDefaultOracle(IOracle _newDefaultOracle) external onlyGovernor {
        IOracle _currentDefaultOracle = defaultOracle;
        require(_newDefaultOracle != _currentDefaultOracle, "new-oracle-is-same-as-current");
        emit DefaultOracleUpdated(_currentDefaultOracle, _newDefaultOracle);
        defaultOracle = _newDefaultOracle;
    }

    /**
     * @notice Get asset's USD price
     * @param _asset The asset's address
     * @return _priceInUsd The USD price (18 decimals)
     */
    function _getPriceInUsd(IERC20 _asset) private view returns (uint256 _priceInUsd) {
        IOracle _oracle = oracles[address(_asset)];

        if (address(_oracle) != address(0)) {
            _priceInUsd = _oracle.getPriceInUsd(_asset);
        } else if (address(defaultOracle) != address(0)) {
            _priceInUsd = defaultOracle.getPriceInUsd(_asset);
        } else {
            revert("asset-without-oracle");
        }

        require(_priceInUsd > 0, "invalid-price");
    }

    /**
     * @notice Convert asset's amount to USD
     * @param _asset The asset's address
     * @param _amount The amount to convert
     * @return _amountInUsd The amount in USD (18 decimals)
     */
    function convertToUsd(IERC20 _asset, uint256 _amount) public view returns (uint256 _amountInUsd) {
        uint256 _priceInUsd = _getPriceInUsd(_asset);
        _amountInUsd = (_amount * _priceInUsd) / 10**IERC20Metadata(address(_asset)).decimals();
    }

    /**
     * @notice Convert USD to asset's amount
     * @param _asset The asset's address
     * @param _amountInUsd The amount in USD (18 decimals)
     * @return _amount The converted amount
     */
    function convertFromUsd(IERC20 _asset, uint256 _amountInUsd) public view returns (uint256 _amount) {
        uint256 _priceInUsd = _getPriceInUsd(_asset);
        _amount = (_amountInUsd * 10**IERC20Metadata(address(_asset)).decimals()) / _priceInUsd;
    }

    /**
     * @notice Convert assets' amounts
     * @param _assetIn The asset to convert from
     * @param _assetOut The asset to convert to
     * @param _amountIn The amount to convert from
     * @return _amountOut The converted amount
     */
    function convert(
        IERC20 _assetIn,
        IERC20 _assetOut,
        uint256 _amountIn
    ) external view returns (uint256 _amountOut) {
        uint256 _amountInUsd = convertToUsd(_assetIn, _amountIn);
        _amountOut = convertFromUsd(_assetOut, _amountInUsd);
    }
}
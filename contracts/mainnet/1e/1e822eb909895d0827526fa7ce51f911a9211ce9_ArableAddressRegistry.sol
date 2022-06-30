// SPDX-License-Identifier: GNU-GPL v3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./interfaces/IArableAddressRegistry.sol";

contract ArableAddressRegistry is Initializable, OwnableUpgradeable, IArableAddressRegistry {
    bytes32 public constant ARABLE_ORACLE = "ARABLE_ORACLE";
    bytes32 public constant ARABLE_FARMING = "ARABLE_FARMING";
    bytes32 public constant ARABLE_EXCHANGE = "ARABLE_EXCHANGE";
    bytes32 public constant ARABLE_MANAGER = "ARABLE_MANAGER";
    bytes32 public constant ARABLE_COLLATERAL = "ARABLE_COLLATERAL";
    bytes32 public constant ARABLE_LIQUIDATION = "ARABLE_LIQUIDATION";
    bytes32 public constant ARABLE_FEE_COLLECTOR = "ARABLE_FEE_COLLECTOR";
    // TODO: we can add ADMIN address

    mapping(bytes32 => address) private _addresses;

    function initialize() external initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    // Set up all addresses for the registry.
    function init(
        address arableOracle_,
        address arableFarming_,
        address arableExchange_,
        address arableManager_,
        address arableCollateral_,
        address arableLiquidation_,
        address arableFeeCollector_
    ) external onlyOwner {
        _addresses[ARABLE_ORACLE] = arableOracle_;
        _addresses[ARABLE_FARMING] = arableFarming_;
        _addresses[ARABLE_EXCHANGE] = arableExchange_;
        _addresses[ARABLE_MANAGER] = arableManager_;
        _addresses[ARABLE_COLLATERAL] = arableCollateral_;
        _addresses[ARABLE_LIQUIDATION] = arableLiquidation_;
        _addresses[ARABLE_FEE_COLLECTOR] = arableFeeCollector_;
    }

    function setAddress(bytes32 id, address address_) external override onlyOwner {
        _addresses[id] = address_;
    }

    function getArableOracle() external view override returns (address) {
        return getAddress(ARABLE_ORACLE);
    }

    function setArableOracle(address arableOracle_) external override onlyOwner {
        _addresses[ARABLE_ORACLE] = arableOracle_;
    }

    function getArableFarming() external view override returns (address) {
        return getAddress(ARABLE_FARMING);
    }

    function setArableFarming(address arableFarming_) external override onlyOwner {
        _addresses[ARABLE_FARMING] = arableFarming_;
    }

    function getArableExchange() external view override returns (address) {
        return getAddress(ARABLE_EXCHANGE);
    }

    function setArableExchange(address arableExchange_) external override onlyOwner {
        _addresses[ARABLE_EXCHANGE] = arableExchange_;
    }

    function getArableManager() external view override returns (address) {
        return getAddress(ARABLE_MANAGER);
    }

    function setArableManager(address arableManager_) external override onlyOwner {
        _addresses[ARABLE_MANAGER] = arableManager_;
    }

    function getArableCollateral() external view override returns (address) {
        return getAddress(ARABLE_COLLATERAL);
    }

    function setArableCollateral(address arableCollateral_) external override onlyOwner {
        _addresses[ARABLE_COLLATERAL] = arableCollateral_;
    }

    function getArableLiquidation() external view override returns (address) {
        return getAddress(ARABLE_LIQUIDATION);
    }

    function setArableLiquidation(address arableLiquidation_) external override onlyOwner {
        _addresses[ARABLE_LIQUIDATION] = arableLiquidation_;
    }

    function setArableFeeCollector(address arableFeeCollector_) external override onlyOwner {
        _addresses[ARABLE_MANAGER] = arableFeeCollector_;
    }

    function getArableFeeCollector() external view override returns (address) {
        return getAddress(ARABLE_FEE_COLLECTOR);
    }

    /**
     * @dev Returns an address by id
     * @return The address
     */
    function getAddress(bytes32 id) public view override returns (address) {
        return _addresses[id];
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

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

/**
 * @title Provider interface for Arable
 * @dev
 */
interface IArableAddressRegistry {
    function getAddress(bytes32 id) external view returns (address);

    function setAddress(bytes32 id, address address_) external;

    function getArableOracle() external view returns (address);

    function setArableOracle(address arableOracle_) external;

    function getArableExchange() external view returns (address);

    function setArableExchange(address arableExchange_) external;

    function getArableManager() external view returns (address);

    function setArableManager(address arableManager_) external;

    function getArableFarming() external view returns (address);

    function setArableFarming(address arableFarming_) external;

    function getArableCollateral() external view returns (address);

    function setArableCollateral(address arableCollateral_) external;

    function getArableLiquidation() external view returns (address);

    function setArableLiquidation(address arableLiquidation_) external;

    function getArableFeeCollector() external view returns (address);

    function setArableFeeCollector(address arableFeeCollector_) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}
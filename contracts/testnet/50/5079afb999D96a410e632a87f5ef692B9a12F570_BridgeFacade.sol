// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !Address.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is IERC1822Proxiable, ERC1967Upgrade {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

abstract contract UUPSSignableUpgradeable is UUPSUpgradeable {
    function _authorizeUpgrade(
        address newImplementation_,
        bytes calldata signature_
    ) internal virtual;

    function upgradeToWithSig(
        address newImplementation_,
        bytes calldata signature_
    ) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation_, signature_);
        _upgradeToAndCallUUPS(newImplementation_, new bytes(0), false);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../interfaces/facade/IBridgeFacade.sol";
import "../interfaces/bridge/IBridge.sol";
import "../interfaces/tokens/IERC20MintableBurnable.sol";
import "../interfaces/tokens/IERC721MintableBurnable.sol";
import "../interfaces/tokens/SBT/ISBT.sol";
import "../interfaces/tokens/IERC1155MintableBurnable.sol";

import "../libs/Encoder.sol";

import "./FeeManager.sol";

contract BridgeFacade is IBridgeFacade, FeeManager {
    using SafeERC20 for *;
    using Encoder for *;

    function __BridgeFacade_init(address bridge_) external initializer {
        __FeeManager_init(bridge_);
    }

    function depositERC20(
        DepositFeeERC20Parameters calldata feeParams_,
        IBridge.DepositERC20Parameters calldata depositParams_
    ) external payable override {
        require(depositParams_.token != address(0), "BridgeFacade: zero token");
        require(depositParams_.amount > 0, "BridgeFacade: amount is zero");
        require(_payCommission(feeParams_.feeToken) == 0, "BridgeFacade: excessive native amount");

        address bridge_ = bridge;

        if (depositParams_.isWrapped) {
            IERC20MintableBurnable(depositParams_.token).burnFrom(
                msg.sender,
                depositParams_.amount
            );
        } else {
            IERC20MintableBurnable(depositParams_.token).safeTransferFrom(
                msg.sender,
                bridge_,
                depositParams_.amount
            );
        }

        IBridge(bridge_).depositERC20(depositParams_);
    }

    function depositERC721(
        DepositFeeERC721Parameters calldata feeParams_,
        IBridge.DepositERC721Parameters calldata depositParams_
    ) external payable override {
        require(depositParams_.token != address(0), "BridgeFacade: zero token");
        require(_payCommission(feeParams_.feeToken) == 0, "BridgeFacade: excessive native amount");

        address bridge_ = bridge;

        if (depositParams_.isWrapped) {
            IERC721MintableBurnable(depositParams_.token).burnFrom(
                msg.sender,
                depositParams_.tokenId
            );
        } else {
            IERC721MintableBurnable(depositParams_.token).safeTransferFrom(
                msg.sender,
                bridge_,
                depositParams_.tokenId
            );
        }

        IBridge(bridge_).depositERC721(depositParams_);
    }

    function depositSBT(
        DepositFeeSBTParameters calldata feeParams_,
        IBridge.DepositSBTParameters calldata depositParams_
    ) external payable override {
        require(depositParams_.token != address(0), "BridgeFacade: zero token");
        require(
            ISBT(depositParams_.token).ownerOf(depositParams_.tokenId) == msg.sender,
            "BridgeFacade: invalid token id"
        );
        require(_payCommission(feeParams_.feeToken) == 0, "BridgeFacade: excessive native amount");

        IBridge(bridge).depositSBT(depositParams_);
    }

    function depositERC1155(
        DepositFeeERC1155Parameters calldata feeParams_,
        IBridge.DepositERC1155Parameters calldata depositParams_
    ) external payable override {
        require(depositParams_.token != address(0), "BridgeFacade: zero token");
        require(depositParams_.amount > 0, "BridgeFacade: amount is zero");
        require(_payCommission(feeParams_.feeToken) == 0, "BridgeFacade: excessive native amount");

        address bridge_ = bridge;

        if (depositParams_.isWrapped) {
            IERC1155MintableBurnable(depositParams_.token).burnFrom(
                msg.sender,
                depositParams_.tokenId,
                depositParams_.amount
            );
        } else {
            IERC1155MintableBurnable(depositParams_.token).safeTransferFrom(
                msg.sender,
                bridge_,
                depositParams_.tokenId,
                depositParams_.amount,
                ""
            );
        }

        IBridge(bridge_).depositERC1155(depositParams_);
    }

    function depositNative(
        DepositFeeNativeParameters calldata feeParams_,
        IBridge.DepositNativeParameters calldata depositParams_
    ) external payable override {
        require(depositParams_.amount > 0, "BridgeFacade: amount is zero");
        require(
            _payCommission(feeParams_.feeToken) == depositParams_.amount,
            "BridgeFacade: wrong amount"
        );

        IBridge(bridge).depositNative{value: depositParams_.amount}(depositParams_);
    }

    function withdrawERC20(IBridge.WithdrawERC20Parameters calldata params_) external override {
        address bridge_ = bridge;

        IBridge(bridge_).verifyMerkleLeaf(
            params_.getTokenDataLeaf(),
            params_.bundle,
            params_.originHash,
            params_.receiver,
            params_.proof
        );

        if (params_.bundle.bundle.length > 0) {
            try IBridge(bridge_).withdrawERC20Bundle(params_) {
                return;
            } catch {}
        }

        IBridge(bridge_).withdrawERC20(params_);
    }

    function withdrawERC721(IBridge.WithdrawERC721Parameters calldata params_) external override {
        address bridge_ = bridge;

        IBridge(bridge_).verifyMerkleLeaf(
            params_.getTokenDataLeaf(),
            params_.bundle,
            params_.originHash,
            params_.receiver,
            params_.proof
        );

        if (params_.bundle.bundle.length > 0) {
            try IBridge(bridge_).withdrawERC721Bundle(params_) {
                return;
            } catch {}
        }

        IBridge(bridge_).withdrawERC721(params_);
    }

    function withdrawSBT(IBridge.WithdrawSBTParameters calldata params_) external override {
        address bridge_ = bridge;

        IBridge(bridge_).verifyMerkleLeaf(
            params_.getTokenDataLeaf(),
            params_.bundle,
            params_.originHash,
            params_.receiver,
            params_.proof
        );

        if (params_.bundle.bundle.length > 0) {
            try IBridge(bridge_).withdrawSBTBundle(params_) {
                return;
            } catch {}
        }

        IBridge(bridge_).withdrawSBT(params_);
    }

    function withdrawERC1155(
        IBridge.WithdrawERC1155Parameters calldata params_
    ) external override {
        address bridge_ = bridge;

        IBridge(bridge_).verifyMerkleLeaf(
            params_.getTokenDataLeaf(),
            params_.bundle,
            params_.originHash,
            params_.receiver,
            params_.proof
        );

        if (params_.bundle.bundle.length > 0) {
            try IBridge(bridge_).withdrawERC1155Bundle(params_) {
                return;
            } catch {}
        }

        IBridge(bridge_).withdrawERC1155(params_);
    }

    function withdrawNative(IBridge.WithdrawNativeParameters calldata params_) external override {
        address bridge_ = bridge;

        IBridge(bridge_).verifyMerkleLeaf(
            params_.getTokenDataLeaf(),
            params_.bundle,
            params_.originHash,
            params_.receiver,
            params_.proof
        );

        if (params_.bundle.bundle.length > 0) {
            try IBridge(bridge_).withdrawNativeBundle(params_) {
                return;
            } catch {}
        }

        IBridge(bridge_).withdrawNative(params_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/facade/IFeeManager.sol";
import "../interfaces/utils/ISigners.sol";

import "../bridge/proxy/UUPSSignableUpgradeable.sol";

import "../libs/Constants.sol";

abstract contract FeeManager is IFeeManager, UUPSSignableUpgradeable, Initializable {
    using SafeERC20 for IERC20;

    address public bridge;
    mapping(address => uint256) internal _feeTokens;

    function __FeeManager_init(address bridge_) public onlyInitializing {
        bridge = bridge_;
    }

    function addFeeToken(AddFeeTokenParameters calldata params_) external override {
        require(
            params_.feeTokens.length == params_.feeAmounts.length,
            "FeeManager: params lengths mismatch"
        );

        _validateTokenManagementSignature(
            uint8(MethodId.AddFeeToken),
            params_.feeTokens,
            params_.feeAmounts,
            params_.signature
        );

        for (uint256 i = 0; i < params_.feeTokens.length; ++i) {
            _addFeeToken(params_.feeTokens[i], params_.feeAmounts[i]);
        }
    }

    function removeFeeToken(RemoveFeeTokenParameters calldata params_) external override {
        require(
            params_.feeTokens.length == params_.feeAmounts.length,
            "FeeManager: params lengths mismatch"
        );

        _validateTokenManagementSignature(
            uint8(MethodId.RemoveFeeToken),
            params_.feeTokens,
            params_.feeAmounts,
            params_.signature
        );

        for (uint256 i = 0; i < params_.feeTokens.length; ++i) {
            _removeFeeToken(params_.feeTokens[i], params_.feeAmounts[i]);
        }
    }

    function updateFeeToken(UpdateFeeTokenParameters calldata params_) external override {
        require(
            params_.feeTokens.length == params_.feeAmounts.length,
            "FeeManager: params lengths mismatch"
        );

        _validateTokenManagementSignature(
            uint8(MethodId.UpdateFeeToken),
            params_.feeTokens,
            params_.feeAmounts,
            params_.signature
        );

        for (uint256 i = 0; i < params_.feeTokens.length; ++i) {
            _updateFeeToken(params_.feeTokens[i], params_.feeAmounts[i]);
        }
    }

    function withdrawFeeToken(WithdrawFeeTokenParameters calldata params_) external override {
        require(
            params_.feeTokens.length == params_.amounts.length,
            "FeeManager: params lengths mismatch"
        );

        _validateWithdrawSignature(params_);

        for (uint256 i = 0; i < params_.feeTokens.length; ++i) {
            _withdrawFeeToken(params_.receiver, params_.feeTokens[i], params_.amounts[i]);
        }
    }

    function getCommission(
        address feeToken_
    ) external view override returns (uint256 commission_) {
        return _feeTokens[feeToken_];
    }

    function _payCommission(address feeToken_) internal returns (uint256 nativeLeft_) {
        nativeLeft_ = msg.value;

        uint256 commission_ = _feeTokens[feeToken_];
        require(commission_ != 0, "FeeManager: wrong fee token");

        if (feeToken_ == Constants.ETHEREUM_ADDRESS) {
            require(commission_ <= nativeLeft_, "FeeManager: wrong native amount");

            nativeLeft_ -= commission_;
        } else if (feeToken_ != Constants.COMMISSION_ADDRESS) {
            IERC20(feeToken_).safeTransferFrom(msg.sender, address(this), commission_);
        }
    }

    function _authorizeUpgrade(address) internal pure override {
        revert("FeeManager: this upgrade method is off");
    }

    function _authorizeUpgrade(
        address newImplementation_,
        bytes calldata signature_
    ) internal override {
        require(newImplementation_ != address(0), "FeeManager: zero address");

        ISigners(bridge).validateChangeAddressSignature(
            uint8(MethodId.AuthorizeUpgrade),
            address(this),
            newImplementation_,
            signature_
        );
    }

    function _validateTokenManagementSignature(
        uint8 methodId_,
        address[] calldata feeTokens_,
        uint256[] calldata feeAmounts_,
        bytes calldata signature_
    ) private {
        address bridge_ = bridge;

        (string memory chainName_, uint256 nonce_) = ISigners(bridge_).getSigComponents(
            methodId_,
            address(this)
        );

        bytes32 signHash_ = keccak256(
            abi.encodePacked(nonce_, address(this), chainName_, methodId_, feeTokens_, feeAmounts_)
        );

        ISigners(bridge_).checkSignatureAndIncrementNonce(
            methodId_,
            address(this),
            signHash_,
            signature_
        );
    }

    function _validateWithdrawSignature(WithdrawFeeTokenParameters calldata params_) private {
        address bridge_ = bridge;
        uint8 methodId_ = uint8(MethodId.WithdrawFeeToken);

        (string memory chainName_, uint256 nonce_) = ISigners(bridge_).getSigComponents(
            methodId_,
            address(this)
        );

        bytes32 signHash_ = keccak256(
            abi.encodePacked(
                nonce_,
                params_.receiver,
                address(this),
                chainName_,
                methodId_,
                params_.feeTokens,
                params_.amounts
            )
        );

        ISigners(bridge_).checkSignatureAndIncrementNonce(
            methodId_,
            address(this),
            signHash_,
            params_.signature
        );
    }

    function _addFeeToken(address feeToken_, uint256 feeAmount_) private {
        require(_feeTokens[feeToken_] == 0, "FeeManager: token already exists");

        _feeTokens[feeToken_] = feeAmount_;

        emit AddedFeeToken(feeToken_, feeAmount_);
    }

    function _removeFeeToken(address feeToken_, uint256 feeAmount_) private {
        require(_feeTokens[feeToken_] == feeAmount_, "FeeManager: wrong token address or amount");

        delete _feeTokens[feeToken_];

        emit RemovedFeeToken(feeToken_, feeAmount_);
    }

    function _updateFeeToken(address feeToken_, uint256 feeAmount_) private {
        require(_feeTokens[feeToken_] != 0, "FeeManager: token doesn't exist");

        _feeTokens[feeToken_] = feeAmount_;

        emit UpdatedFeeToken(feeToken_, feeAmount_);
    }

    function _withdrawFeeToken(address receiver_, address feeToken_, uint256 amount_) private {
        require(feeToken_ != Constants.COMMISSION_ADDRESS, "FeeManager: commission token");

        if (feeToken_ == Constants.ETHEREUM_ADDRESS) {
            (bool ok_, ) = receiver_.call{value: amount_}("");
            require(ok_, "FeeManager: failed to withdraw native");
        } else {
            IERC20(feeToken_).safeTransfer(receiver_, amount_);
        }

        emit WithdrawnFeeToken(receiver_, feeToken_, amount_);
    }

    uint256[48] private _gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../handlers/IERC20Handler.sol";
import "../handlers/IERC721Handler.sol";
import "../handlers/ISBTHandler.sol";
import "../handlers/IERC1155Handler.sol";
import "../handlers/INativeHandler.sol";
import "../utils/ISigners.sol";

/**
 * @notice The Bridge contract
 *
 * The Bridge contract acts as a permissioned way of transferring assets (ERC20, ERC721, ERC1155, Native) between
 * 2 different blockchains.
 *
 * In order to correctly use the Bridge, one has to deploy both instances of the contract on the base chain and the
 * destination chain, as well as setup a trusted backend that will act as a `signer`.
 *
 * Each Bridge contract can either give or take the user assets when they want to transfer tokens. Both liquidity pool
 * and mint-and-burn way of transferring assets are supported.
 *
 * The bridge enables the transaction bundling feature as well.
 */
interface IBridge is
    IBundler,
    ISigners,
    IERC20Handler,
    IERC721Handler,
    ISBTHandler,
    IERC1155Handler,
    INativeHandler
{
    /**
     * @notice the enum that helps distinguish functions for calling within the signature
     * @param None the special zero type, method types start from 1
     * @param AuthorizeUpgrade the type corresponding to the _authorizeUpgrade function
     * @param ChangeBundleExecutorImplementation the type corresponding to the changeBundleExecutorImplementation function
     * @param ChangeFacade the type corresponding to the changeFacade function
     */
    enum MethodId {
        None,
        AuthorizeUpgrade,
        ChangeBundleExecutorImplementation,
        ChangeFacade
    }

    /**
     * @notice the function to verify merkle leaf
     * @param tokenDataLeaf_ the abi encoded token parameters
     * @param bundle_ the encoded transaction bundle with encoded salt
     * @param originHash_ the keccak256 hash of abi.encodePacked(origin chain name . origin tx hash . event nonce)
     * @param receiver_ the address who will receive tokens
     * @param proof_ the abi encoded merkle path with the signature of a merkle root the signer signed
     */
    function verifyMerkleLeaf(
        bytes memory tokenDataLeaf_,
        IBundler.Bundle calldata bundle_,
        bytes32 originHash_,
        address receiver_,
        bytes calldata proof_
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IBundler {
    /**
     * @notice the struct that stores bundling info
     * @param salt the salt used to determine the proxy address
     * @param bundle the encoded transaction bundle
     */
    struct Bundle {
        bytes32 salt;
        bytes bundle;
    }

    /**
     * @notice function to get the bundle executor proxy address for the given salt and bundle
     * @param salt_ the salt for create2 (origin hash)
     * @return the bundle executor proxy address
     */
    function determineProxyAddress(bytes32 salt_) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IFeeManager.sol";
import "../bridge/IBridge.sol";

/**
 * @notice The Bridge Facade contract.
 *
 * The Bridge Facade contract serves as a facade interface for interacting with the underlying Bridge contract.
 * It delegates all deposit and withdrawal requests to the Bridge contract and collects fees.
 * It also provides an opportunity to manage the list of fee tokens and withdraw commissions by utilizing the signature-based methods.
 */
interface IBridgeFacade is IFeeManager {
    /**
     * @notice the struct that represents fee parameters for the erc20 deposit
     * @param token the address of the fee token
     */
    struct DepositFeeERC20Parameters {
        address feeToken;
    }

    /**
     * @notice the struct that represents fee parameters for the erc721 deposit
     * @param feeToken the address of the fee token
     */
    struct DepositFeeERC721Parameters {
        address feeToken;
    }

    /**
     * @notice the struct that represents fee parameters for the sbt deposit
     * @param feeToken the address of the fee token
     */
    struct DepositFeeSBTParameters {
        address feeToken;
    }

    /**
     * @notice the struct that represents fee parameters for the erc1155 deposit
     * @param feeToken the address of the fee token
     */
    struct DepositFeeERC1155Parameters {
        address feeToken;
    }

    /**
     * @notice the struct that represents fee parameters for the native deposit
     * @param feeToken the address of the fee token
     */
    struct DepositFeeNativeParameters {
        address feeToken;
    }

    /**
     * @notice the function that deposits erc20 tokens with a fee
     * @param feeParams_ the fee parameters for the erc20 deposit
     * @param depositParams_ the parameters for the erc20 deposit
     */
    function depositERC20(
        DepositFeeERC20Parameters calldata feeParams_,
        IBridge.DepositERC20Parameters calldata depositParams_
    ) external payable;

    /**
     * @notice the function that deposits erc721 tokens with a fee
     * @param feeParams_ the fee parameters for the erc721 deposit
     * @param depositParams_ the parameters for the erc721 deposit
     */
    function depositERC721(
        DepositFeeERC721Parameters calldata feeParams_,
        IBridge.DepositERC721Parameters calldata depositParams_
    ) external payable;

    /**
     * @notice the function that deposits sbt tokens with a fee
     * @param feeParams_ the fee parameters for the sbt deposit
     * @param depositParams_ the parameters for the sbt deposit
     */
    function depositSBT(
        DepositFeeSBTParameters calldata feeParams_,
        IBridge.DepositSBTParameters calldata depositParams_
    ) external payable;

    /**
     * @notice the function that deposits erc1155 tokens with a fee
     * @param feeParams_ the fee parameters for the erc1155 deposit
     * @param depositParams_ the parameters for the erc1155 deposit
     */
    function depositERC1155(
        DepositFeeERC1155Parameters calldata feeParams_,
        IBridge.DepositERC1155Parameters calldata depositParams_
    ) external payable;

    /**
     * @notice the function that deposits native tokens with a fee
     * @param feeParams_ the fee parameters for the native deposit
     * @param depositParams_ the parameters for the native deposit
     */
    function depositNative(
        DepositFeeNativeParameters calldata feeParams_,
        IBridge.DepositNativeParameters calldata depositParams_
    ) external payable;

    /**
     * @notice the function to withdraw erc20 tokens
     * @param params_ the parameters for the erc20 withdrawal
     */
    function withdrawERC20(IBridge.WithdrawERC20Parameters calldata params_) external;

    /**
     * @notice the function to withdraw erc721 tokens
     * @param params_ the parameters for the erc721 withdrawal
     */
    function withdrawERC721(IBridge.WithdrawERC721Parameters calldata params_) external;

    /**
     * @notice the function to withdraw sbt tokens
     * @param params_ the parameters for the sbt withdrawal
     */
    function withdrawSBT(IBridge.WithdrawSBTParameters calldata params_) external;

    /**
     * @notice the function to withdraw erc1155 tokens
     * @param params_ the parameters for the erc1155 withdrawal
     */
    function withdrawERC1155(IBridge.WithdrawERC1155Parameters calldata params_) external;

    /**
     * @notice the function to withdraw native tokens
     * @param params_ the parameters for the native withdrawal
     */
    function withdrawNative(IBridge.WithdrawNativeParameters calldata params_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IFeeManager {
    /**
     * @notice the enum that helps distinguish functions for calling within the signature
     * @param AddFeeToken the type corresponding to the addFeeToken function
     * @param RemoveFeeToken the type corresponding to the removeFeeToken function
     * @param UpdateFeeToken the type corresponding to the updateFeeToken function
     * @param AuthorizeUpgrade the type corresponding to the _authorizeUpgrade function
     */
    enum MethodId {
        AddFeeToken,
        RemoveFeeToken,
        UpdateFeeToken,
        WithdrawFeeToken,
        AuthorizeUpgrade
    }

    /**
     * @notice the event emitted from the addFeeToken function
     */
    event AddedFeeToken(address feeToken, uint256 feeAmount);

    /**
     * @notice the event emitted from the removeFeeToken function
     */
    event RemovedFeeToken(address feeToken, uint256 feeAmount);

    /**
     * @notice the event emitted from the updateFeeToken function
     */
    event UpdatedFeeToken(address feeToken, uint256 feeAmount);

    /**
     * @notice the event emitted from the withdrawFeeToken function
     */
    event WithdrawnFeeToken(address receiver, address feeToken, uint256 amount);

    /**
     * @notice the struct that represents add fee token parameters
     * @param feeTokens the list of fee tokens to be added
     * @param feeAmounts the list of corresponding fee token amounts
     * @param signature the add fee token signature
     */
    struct AddFeeTokenParameters {
        address[] feeTokens;
        uint256[] feeAmounts;
        bytes signature;
    }

    /**
     * @notice the struct that represents remove fee token parameters
     * @param feeTokens the list of fee tokens to be removed
     * @param feeAmounts the list of corresponding fee token amounts
     * @param signature the remove fee token signature
     */
    struct RemoveFeeTokenParameters {
        address[] feeTokens;
        uint256[] feeAmounts;
        bytes signature;
    }

    /**
     * @notice the struct that represents update fee token parameters
     * @param feeTokens the list of fee tokens to be updated
     * @param feeAmounts the list of corresponding fee token amounts
     * @param signature the update fee token signature
     */
    struct UpdateFeeTokenParameters {
        address[] feeTokens;
        uint256[] feeAmounts;
        bytes signature;
    }

    /**
     * @notice the struct that represents withdraw fee token parameters
     * @param receiver the address who will receive tokens
     * @param feeTokens the list of fee tokens to be withdrawn
     * @param feeAmounts the list of corresponding fee token amounts
     * @param signature the withdraw fee token signature
     */
    struct WithdrawFeeTokenParameters {
        address receiver;
        address[] feeTokens;
        uint256[] amounts;
        bytes signature;
    }

    /**
     * @notice the function that adds fee tokens
     * @param params_ the parameters for adding fee tokens
     */
    function addFeeToken(AddFeeTokenParameters calldata params_) external;

    /**
     * @notice the function that removes fee tokens
     * @param params_ the parameters for removing fee tokens
     */
    function removeFeeToken(RemoveFeeTokenParameters calldata params_) external;

    /**
     * @notice the function that updates fee tokens
     * @param params_ the parameters for updating fee tokens
     */
    function updateFeeToken(UpdateFeeTokenParameters calldata params_) external;

    /**
     * @notice the function that withdraws fee tokens
     * @param params_ the parameters for the fee tokens withdrawal
     */
    function withdrawFeeToken(WithdrawFeeTokenParameters calldata params_) external;

    /**
     * @notice the function to get the commission amount for the specific fee token
     * @param feeToken_ the address of the fee token
     * @return commission_ the commission amount for the specified fee token
     */
    function getCommission(address feeToken_) external view returns (uint256 commission_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../bundle/IBundler.sol";

interface IERC1155Handler is IBundler {
    /**
     * @notice the event emitted from the depositERC1155 function
     */
    event DepositedERC1155(
        address token,
        uint256 tokenId,
        uint256 amount,
        bytes32 salt,
        bytes bundle,
        string network,
        string receiver,
        bool isWrapped
    );

    /**
     * @notice the struct that represents parameters for the erc1155 deposit
     * @param token the address of deposited tokens
     * @param tokenId the id of deposited tokens
     * @param amount the amount of deposited tokens
     * @param bundle the encoded transaction bundle with salt
     * @param network the network name of destination network, information field for event
     * @param receiver the receiver address in destination network, information field for event
     * @param isWrapped the boolean flag, if true - tokens will burned, false - tokens will transferred
     */
    struct DepositERC1155Parameters {
        address token;
        uint256 tokenId;
        uint256 amount;
        IBundler.Bundle bundle;
        string network;
        string receiver;
        bool isWrapped;
    }

    /**
     * @notice the struct that represents parameters for the erc1155 withdrawal
     * @param token the address of withdrawal tokens
     * @param tokenId the id of withdrawal tokens
     * @param tokenURI the uri of withdrawal tokens
     * @param amount the amount of withdrawal tokens
     * @param bundle the encoded transaction bundle with encoded salt
     * @param originHash the keccak256 hash of abi.encodePacked(origin chain name . origin tx hash . event nonce)
     * @param receiver the address who will receive tokens
     * @param proof the abi encoded merkle path with the signature of a merkle root the signer signed
     * @param isWrapped the boolean flag, if true - tokens will minted, false - tokens will transferred
     */
    struct WithdrawERC1155Parameters {
        address token;
        uint256 tokenId;
        string tokenURI;
        uint256 amount;
        IBundler.Bundle bundle;
        bytes32 originHash;
        address receiver;
        bytes proof;
        bool isWrapped;
    }

    /**
     * @notice the function to deposit erc1155 tokens
     * @param params_ the parameters for the erc1155 deposit
     */
    function depositERC1155(DepositERC1155Parameters calldata params_) external;

    /**
     * @notice the function to withdraw erc1155 tokens
     * @param params_ the parameters for the erc1155 withdrawal
     */
    function withdrawERC1155(WithdrawERC1155Parameters memory params_) external;

    /**
     * @notice the function to withdraw erc1155 tokens with bundle
     * @param params_ the parameters for the erc1155 withdrawal
     */
    function withdrawERC1155Bundle(WithdrawERC1155Parameters memory params_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../bundle/IBundler.sol";

interface IERC20Handler is IBundler {
    /**
     * @notice the event emitted from the depositERC20 function
     */
    event DepositedERC20(
        address token,
        uint256 amount,
        bytes32 salt,
        bytes bundle,
        string network,
        string receiver,
        bool isWrapped
    );

    /**
     * @notice the struct that represents parameters for the erc20 deposit
     * @param token the address of the deposited token
     * @param amount the amount of deposited tokens
     * @param bundle the encoded transaction bundle with salt
     * @param network the network name of destination network, information field for event
     * @param receiver the receiver address in destination network, information field for event
     * @param isWrapped the boolean flag, if true - tokens will burned, false - tokens will transferred
     */
    struct DepositERC20Parameters {
        address token;
        uint256 amount;
        IBundler.Bundle bundle;
        string network;
        string receiver;
        bool isWrapped;
    }

    /**
     * @notice the struct that represents parameters for the erc20 withdrawal
     * @param token the address of the withdrawal token
     * @param amount the amount of withdrawal tokens
     * @param bundle the encoded transaction bundle with encoded salt
     * @param receiver the address who will receive tokens
     * @param originHash the keccak256 hash of abi.encodePacked(origin chain name . origin tx hash . event nonce)
     * @param proof the abi encoded merkle path with the signature of a merkle root the signer signed
     * @param isWrapped the boolean flag, if true - tokens will minted, false - tokens will transferred
     */
    struct WithdrawERC20Parameters {
        address token;
        uint256 amount;
        IBundler.Bundle bundle;
        bytes32 originHash;
        address receiver;
        bytes proof;
        bool isWrapped;
    }

    /**
     * @notice the function to deposit erc20 tokens
     * @param params_ the parameters for the erc20 deposit
     */
    function depositERC20(DepositERC20Parameters calldata params_) external;

    /**
     * @notice the function to withdraw erc20 tokens
     * @param params_ the parameters for the erc20 withdrawal
     */
    function withdrawERC20(WithdrawERC20Parameters memory params_) external;

    /**
     * @notice the function to withdraw erc20 tokens with bundle
     * @param params_ the parameters for the erc20 withdrawal
     */
    function withdrawERC20Bundle(WithdrawERC20Parameters memory params_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../bundle/IBundler.sol";

interface IERC721Handler is IBundler {
    /**
     * @notice the event emitted from the depositERC721 function
     */
    event DepositedERC721(
        address token,
        uint256 tokenId,
        bytes32 salt,
        bytes bundle,
        string network,
        string receiver,
        bool isWrapped
    );

    /**
     * @notice the struct that represents parameters for the erc721 deposit
     * @param token the address of the deposited token
     * @param tokenId the id of deposited token
     * @param bundle the encoded transaction bundle with salt
     * @param network the network name of destination network, information field for event
     * @param receiver the receiver address in destination network, information field for event
     * @param isWrapped the boolean flag, if true - token will burned, false - token will transferred
     */
    struct DepositERC721Parameters {
        address token;
        uint256 tokenId;
        IBundler.Bundle bundle;
        string network;
        string receiver;
        bool isWrapped;
    }

    /**
     * @notice the struct that represents parameters for the erc721 withdrawal
     * @param token the address of the withdrawal token
     * @param tokenId the id of the withdrawal token
     * @param tokenURI the uri of the withdrawal token
     * @param bundle the encoded transaction bundle with encoded salt
     * @param originHash the keccak256 hash of abi.encodePacked(origin chain name . origin tx hash . event nonce)
     * @param receiver the address who will receive tokens
     * @param proof the abi encoded merkle path with the signature of a merkle root the signer signed
     * @param isWrapped the boolean flag, if true - tokens will minted, false - tokens will transferred
     */
    struct WithdrawERC721Parameters {
        address token;
        uint256 tokenId;
        string tokenURI;
        IBundler.Bundle bundle;
        bytes32 originHash;
        address receiver;
        bytes proof;
        bool isWrapped;
    }

    /**
     * @notice the function to deposit erc721 tokens
     * @param params_ the parameters for the erc721 deposit
     */
    function depositERC721(DepositERC721Parameters calldata params_) external;

    /**
     * @notice the function to withdraw erc721 tokens
     * @param params_ the parameters for the erc721 withdrawal
     */
    function withdrawERC721(WithdrawERC721Parameters memory params_) external;

    /**
     * @notice the function to withdraw erc721 tokens with bundle
     * @param params_ the parameters for the erc721 withdrawal
     */
    function withdrawERC721Bundle(WithdrawERC721Parameters memory params_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../bundle/IBundler.sol";

interface INativeHandler is IBundler {
    /**
     * @notice the event emitted from the depositNative function
     */
    event DepositedNative(
        uint256 amount,
        bytes32 salt,
        bytes bundle,
        string network,
        string receiver
    );

    /**
     * @notice the struct that represents parameters for the native deposit
     * @param amount the amount of deposited native tokens
     * @param bundle the encoded transaction bundle with salt
     * @param network the network name of destination network, information field for event
     * @param receiver the receiver address in destination network, information field for event
     */
    struct DepositNativeParameters {
        uint256 amount;
        IBundler.Bundle bundle;
        string network;
        string receiver;
    }

    /**
     * @notice the struct that represents parameters for the native withdrawal
     * @param amount the amount of withdrawal native funds
     * @param bundle the encoded transaction bundle
     * @param originHash the keccak256 hash of abi.encodePacked(origin chain name . origin tx hash . event nonce)
     * @param receiver the address who will receive tokens
     * @param proof the abi encoded merkle path with the signature of a merkle root the signer signed
     */
    struct WithdrawNativeParameters {
        uint256 amount;
        IBundler.Bundle bundle;
        bytes32 originHash;
        address receiver;
        bytes proof;
    }

    /**
     * @notice the function to deposit native tokens
     * @param params_ the parameters for the native deposit
     */
    function depositNative(DepositNativeParameters calldata params_) external payable;

    /**
     * @notice the function to withdraw native tokens
     * @param params_ the parameters for the native withdrawal
     */
    function withdrawNative(WithdrawNativeParameters memory params_) external;

    /**
     * @notice the function to withdraw native tokens with bundle
     * @param params_ the parameters for the native withdrawal
     */
    function withdrawNativeBundle(WithdrawNativeParameters memory params_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../bundle/IBundler.sol";

interface ISBTHandler is IBundler {
    /**
     * @notice the event emitted from the depositSBT function
     */
    event DepositedSBT(
        address token,
        uint256 tokenId,
        bytes32 salt,
        bytes bundle,
        string network,
        string receiver
    );

    /**
     * @notice the struct that represents parameters for the sbt deposit
     * @param token the address of deposited token
     * @param tokenId the id of deposited token
     * @param bundle the encoded transaction bundle with salt
     * @param network the network name of destination network, information field for event
     * @param receiver the receiver address in destination network, information field for event
     */
    struct DepositSBTParameters {
        address token;
        uint256 tokenId;
        IBundler.Bundle bundle;
        string network;
        string receiver;
    }

    /**
     * @notice the struct that represents parameters for the sbt withdrawal
     * @param token the address of the withdrawal token
     * @param tokenId the id of the withdrawal token
     * @param tokenURI the uri of the withdrawal token
     * @param bundle the encoded transaction bundle with encoded salt
     * @param originHash the keccak256 hash of abi.encodePacked(origin chain name . origin tx hash . event nonce)
     * @param receiver the address who will receive tokens
     * @param proof the abi encoded merkle path with the signature of a merkle root the signer signed
     */
    struct WithdrawSBTParameters {
        address token;
        uint256 tokenId;
        string tokenURI;
        IBundler.Bundle bundle;
        bytes32 originHash;
        address receiver;
        bytes proof;
    }

    /**
     * @notice the function to deposit sbt tokens
     * @param params_ the parameters for the sbt deposit
     */
    function depositSBT(DepositSBTParameters calldata params_) external;

    /**
     * @notice the function to withdraw sbt tokens
     * @param params_ the parameters for the sbt withdrawal
     */
    function withdrawSBT(WithdrawSBTParameters memory params_) external;

    /**
     * @notice the function to withdraw sbt tokens with bundle
     * @param params_ the parameters for the sbt withdrawal
     */
    function withdrawSBTBundle(WithdrawSBTParameters memory params_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IERC1155MintableBurnable is IERC1155 {
    function mintTo(
        address receiver_,
        uint256 tokenId_,
        uint256 amount_,
        string calldata tokenURI_
    ) external;

    function burnFrom(address payer_, uint256 tokenId_, uint256 amount_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20MintableBurnable is IERC20 {
    function mintTo(address receiver_, uint256 amount_) external;

    function burnFrom(address payer_, uint256 amount_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IERC721MintableBurnable is IERC721 {
    function mintTo(address receiver_, uint256 tokenId_, string calldata tokenURI_) external;

    function burnFrom(address payer_, uint256 tokenId_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ISBT is IERC721 {
    function attestTo(address receiver_, uint256 tokenId_, string calldata tokenURI_) external;

    function burn() external;

    function tokenIdOf(address from_) external view returns (uint256 tokenId_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ISigners {
    /**
     * @notice the function to check the signature and increment the nonce associated with the method selector
     * @param methodId_ the method id
     * @param contractAddress_ the contract address to which the method id belongs
     * @param signHash_ the sign hash to be verified
     * @param signature_ the signature to be checked
     */
    function checkSignatureAndIncrementNonce(
        uint8 methodId_,
        address contractAddress_,
        bytes32 signHash_,
        bytes calldata signature_
    ) external;

    /**
     * @notice the function to validate the address change signature
     * @param methodId_ the method id
     * @param contractAddress_ the contract address to which the method id belongs
     * @param newAddress_ the new signed address
     * @param signature_ the signature to be checked
     */
    function validateChangeAddressSignature(
        uint8 methodId_,
        address contractAddress_,
        address newAddress_,
        bytes calldata signature_
    ) external;

    /**
     * @notice the function to get signature components
     * @param methodId_ the method id
     * @param contractAddress_ the contract address to which the method id belongs
     * @return chainName_ the name of the chain
     * @return nonce_ the current nonce value associated with the method selector
     */
    function getSigComponents(
        uint8 methodId_,
        address contractAddress_
    ) external view returns (string memory chainName_, uint256 nonce_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library Constants {
    address public constant ETHEREUM_ADDRESS = 0x0000000000000000000000000000000000000000;
    address public constant COMMISSION_ADDRESS = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../interfaces/bridge/IBridge.sol";
import "../interfaces/bundle/IBundler.sol";

library Encoder {
    function encode(bytes32 salt_) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(salt_, tx.origin));
    }

    function encode(
        bytes calldata tokenDataLeaf_,
        IBundler.Bundle calldata bundle_,
        bytes32 originHash_,
        string memory chainName_,
        address receiver_
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    tokenDataLeaf_,
                    _getBundleLeaf(bundle_),
                    _getMetadataLeaf(originHash_, chainName_, receiver_)
                )
            );
    }

    function getTokenDataLeaf(
        IBridge.WithdrawERC20Parameters calldata params_
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(params_.token, params_.amount);
    }

    function getTokenDataLeaf(
        IBridge.WithdrawERC721Parameters calldata params_
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(params_.token, params_.tokenId, params_.tokenURI);
    }

    function getTokenDataLeaf(
        IBridge.WithdrawSBTParameters calldata params_
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(params_.token, params_.tokenId, params_.tokenURI);
    }

    function getTokenDataLeaf(
        IBridge.WithdrawERC1155Parameters calldata params_
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(params_.token, params_.tokenId, params_.tokenURI, params_.amount);
    }

    function getTokenDataLeaf(
        IBridge.WithdrawNativeParameters calldata params_
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(params_.amount);
    }

    function _getBundleLeaf(IBundler.Bundle calldata bundle_) private pure returns (bytes memory) {
        if (bundle_.bundle.length == 0) {
            return bytes("");
        }

        return abi.encodePacked(bundle_.salt, bundle_.bundle);
    }

    function _getMetadataLeaf(
        bytes32 originHash_,
        string memory chainName_,
        address receiver_
    ) private view returns (bytes memory) {
        return abi.encodePacked(originHash_, chainName_, receiver_, address(this));
    }
}
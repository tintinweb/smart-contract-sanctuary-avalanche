/**
 *Submitted for verification at snowtrace.io on 2022-06-29
*/

// Sources flattened with hardhat v2.9.5 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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

// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

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
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(
                _initialized < version,
                "Initializable: contract is already initialized"
            );
            _initialized = version;
            return true;
        }
    }
}

// File @openzeppelin/contracts-upgradeable/interfaces/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
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

// File @openzeppelin/contracts-upgradeable/proxy/beacon/[email protected]

// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

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
library StorageSlotUpgradeable {
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
    function getAddressSlot(bytes32 slot)
        internal
        pure
        returns (AddressSlot storage r)
    {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot)
        internal
        pure
        returns (BooleanSlot storage r)
    {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot)
        internal
        pure
        returns (Bytes32Slot storage r)
    {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot)
        internal
        pure
        returns (Uint256Slot storage r)
    {
        assembly {
            r.slot := slot
        }
    }
}

// File @openzeppelin/contracts-upgradeable/proxy/ERC1967/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {}

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {}

    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT =
        0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return
            StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(
            AddressUpgradeable.isContract(newImplementation),
            "ERC1967: new implementation is not a contract"
        );
        StorageSlotUpgradeable
            .getAddressSlot(_IMPLEMENTATION_SLOT)
            .value = newImplementation;
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
            _functionDelegateCall(newImplementation, data);
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
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try
                IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID()
            returns (bytes32 slot) {
                require(
                    slot == _IMPLEMENTATION_SLOT,
                    "ERC1967Upgrade: unsupported proxiableUUID"
                );
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
    bytes32 internal constant _ADMIN_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(
            newAdmin != address(0),
            "ERC1967: new admin is the zero address"
        );
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
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
    bytes32 internal constant _BEACON_SLOT =
        0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(
            AddressUpgradeable.isContract(newBeacon),
            "ERC1967: new beacon is not a contract"
        );
        require(
            AddressUpgradeable.isContract(
                IBeaconUpgradeable(newBeacon).implementation()
            ),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
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
            _functionDelegateCall(
                IBeaconUpgradeable(newBeacon).implementation(),
                data
            );
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data)
        private
        returns (bytes memory)
    {
        require(
            AddressUpgradeable.isContract(target),
            "Address: delegate call to non-contract"
        );

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return
            AddressUpgradeable.verifyCallResult(
                success,
                returndata,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

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
abstract contract UUPSUpgradeable is
    Initializable,
    IERC1822ProxiableUpgradeable,
    ERC1967UpgradeUpgradeable
{
    function __UUPSUpgradeable_init() internal onlyInitializing {}

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {}

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
        require(
            address(this) != __self,
            "Function must be called through delegatecall"
        );
        require(
            _getImplementation() == __self,
            "Function must be called through active proxy"
        );
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(
            address(this) == __self,
            "UUPSUpgradeable: must not be called through delegatecall"
        );
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
    function proxiableUUID()
        external
        view
        virtual
        override
        notDelegated
        returns (bytes32)
    {
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
    function upgradeToAndCall(address newImplementation, bytes memory data)
        external
        payable
        virtual
        onlyProxy
    {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {}

    function __Context_init_unchained() internal onlyInitializing {}

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// File @openzeppelin/contracts-upgradeable/access/[email protected]

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// File contracts/theTapV2.sol

pragma solidity 0.8.13;

// import "hardhat/console.sol";

interface IToken {
    function remainingMintableSupply() external view returns (uint256);

    function calculateTransferTaxes(address _from, uint256 _value)
        external
        view
        returns (uint256 adjustedValue, uint256 taxAmount);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function balanceOf(address who) external view returns (uint256);

    function mintedSupply() external returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);
}

interface ITokenMint {
    function mint(address beneficiary, uint256 tokenAmount)
        external
        returns (uint256);

    function estimateMint(uint256 _amount) external returns (uint256);

    function remainingMintableSupply() external returns (uint256);
}

interface IOldTap {
    struct User {
        //Referral Info
        address upline;
        uint256 referrals;
        uint256 total_structure;
        //Long-term Referral Accounting
        uint256 direct_bonus;
        uint256 match_bonus;
        //Deposit Accounting
        uint256 deposits;
        uint256 deposit_time;
        //Payout and Roll Accounting
        uint256 payouts;
        uint256 rolls;
        //Upline Round Robin tracking
        uint256 ref_claim_pos;
        address entered_address;
    }
    struct Airdrop {
        //Airdrop tracking
        uint256 airdrops;
        uint256 airdrops_received;
        uint256 last_airdrop;
    }
    struct Custody {
        address manager;
        address beneficiary;
        uint256 last_heartbeat;
        uint256 last_checkin;
        uint256 heartbeat_interval;
    }

    function users(address _addr) external view returns (User memory);

    function airdrops(address _addr) external view returns (Airdrop memory);

    function custody(address _addr) external view returns (Custody memory);

    function contractInfo()
        external
        view
        returns (
            uint256 _total_users,
            uint256 _total_deposited,
            uint256 _total_withdraw,
            uint256 _total_bnb,
            uint256 _total_txs,
            uint256 _total_airdrops
        );
}

contract TheTapV2 is UUPSUpgradeable, OwnableUpgradeable {
    using SafeMath for uint256;

    struct User {
        //Referral Info
        address upline;
        uint256 referrals;
        uint256 total_structure;
        //Long-term Referral Accounting
        uint256 direct_bonus;
        uint256 match_bonus;
        //Deposit Accounting
        uint256 deposits;
        uint256 deposit_time;
        //Payout and Roll Accounting
        uint256 payouts;
        uint256 rolls;
        //Upline Round Robin tracking
        uint256 ref_claim_pos;
        uint256 accumulatedDiv;
    }
    struct Airdrop {
        //Airdrop tracking
        uint256 airdrops;
        uint256 airdrops_received;
        uint256 last_airdrop;
    }
    struct Custody {
        address manager;
        address beneficiary;
        uint256 last_heartbeat;
        uint256 last_checkin;
        uint256 heartbeat_interval;
    }

    // ITokenMint private tokenMint;
    IToken private waveToken;
    IToken private splashToken;
    IOldTap private oldTap;

    mapping(address => User) public users;
    mapping(address => bool) public blackList;

    mapping(address => Airdrop) public airdrops;
    mapping(address => Custody) public custody;

    uint256 public CompoundTax;
    uint256 public ExitTax;

    uint256 private payoutRate;
    uint256 private ref_depth;
    uint256 private ref_bonus;

    uint256 private minimumInitial;
    uint256 private minimumAmount;

    uint256 public deposit_bracket_size; // @BB 5% increase whale tax per 10000 tokens... 10 below cuts it at 50% since 5 * 10
    uint256 public max_payout_cap; // 100k Splash or 10% of supply
    uint256 private deposit_bracket_max; // sustainability fee is (bracket * 5)

    uint256[] public ref_balances;

    bool public isPaused;
    uint256 public total_airdrops;
    uint256 public total_users;
    uint256 public total_deposited;
    uint256 public total_withdraw;
    uint256 public total_bnb;
    uint256 public total_txs;

    uint256 public constant MAX_UINT = 2**256 - 1;

    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event Leaderboard(
        address indexed addr,
        uint256 referrals,
        uint256 total_deposits,
        uint256 total_payouts,
        uint256 total_structure
    );
    event DirectPayout(
        address indexed addr,
        address indexed from,
        uint256 amount
    );
    event MatchPayout(
        address indexed addr,
        address indexed from,
        uint256 amount
    );
    event BalanceTransfer(
        address indexed _src,
        address indexed _dest,
        uint256 _deposits,
        uint256 _payouts
    );
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);
    event NewAirdrop(
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 timestamp
    );
    event ManagerUpdate(
        address indexed addr,
        address indexed manager,
        uint256 timestamp
    );
    event BeneficiaryUpdate(address indexed addr, address indexed beneficiary);
    event HeartBeatIntervalUpdate(address indexed addr, uint256 interval);
    event HeartBeat(address indexed addr, uint256 timestamp);
    event Checkin(address indexed addr, uint256 timestamp);

    /* ========== INITIALIZER ========== */
    function _authorizeUpgrade(address) internal override onlyOwner {}

    function initialize(
        address _waveTokenAddress,
        address _splashTokenAddress,
        address _oldTapAddress
    ) external initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();

        isPaused = true;

        total_users = 1;
        deposit_bracket_size = 10000e18; // @BB 5% increase whale tax per 10000 tokens... 10 below cuts it at 50% since 5 * 10
        max_payout_cap = 100000e18; // 100k Splash or 10% of supply
        minimumInitial = 1e18;
        minimumAmount = 1e18;

        payoutRate = 2;
        ref_depth = 15;
        ref_bonus = 10;
        deposit_bracket_max = 10; // sustainability fee is (bracket * 5)

        CompoundTax = 5;
        ExitTax = 10;

        // tokenMint = ITokenMint(_mintAddress);
        waveToken = IToken(_waveTokenAddress);
        splashToken = IToken(_splashTokenAddress);
        oldTap = IOldTap(_oldTapAddress);

        //Referral Balances
        ref_balances.push(2e8);
        ref_balances.push(3e8);
        ref_balances.push(5e8);
        ref_balances.push(8e8);
        ref_balances.push(13e8);
        ref_balances.push(21e8);
        ref_balances.push(34e8);
        ref_balances.push(55e8);
        ref_balances.push(89e8);
        ref_balances.push(144e8);
        ref_balances.push(233e8);
        ref_balances.push(377e8);
        ref_balances.push(610e8);
        ref_balances.push(987e8);
        ref_balances.push(1597e8);
    }

    function unpause() public onlyOwner {
        isPaused = false;
    }

    function pause() public onlyOwner {
        isPaused = true;
    }

    modifier isNotPaused() {
        require(!isPaused, "Swaps currently paused");
        _;
    }

    //@dev Default payable is empty since Faucet executes trades and recieves BNB
    fallback() external payable {
        //Do nothing, BNB will be sent to contract when selling tokens
    }

    receive() external payable {
        //Do nothing
    }

    /***** Migrate Functions ******/
    function migrateFromOldContract() external noBlackList isNotPaused {
        address _addr = msg.sender;
        require(users[_addr].deposits == 0, "User is already transfered");
        IOldTap.User memory _user = oldTap.users(_addr);
        users[_addr].upline = _user.upline;
        users[_addr].referrals = _user.referrals;
        users[_addr].total_structure = _user.total_structure;
        users[_addr].direct_bonus = _user.direct_bonus;
        users[_addr].match_bonus = _user.match_bonus;
        users[_addr].deposits = _user.deposits;
        users[_addr].deposit_time = _user.deposit_time;
        users[_addr].payouts = _user.payouts;
        users[_addr].rolls = _user.rolls;
        users[_addr].ref_claim_pos = _user.ref_claim_pos;

        IOldTap.Airdrop memory _airdrops = oldTap.airdrops(_addr);
        airdrops[_addr].airdrops = _airdrops.airdrops;
        airdrops[_addr].airdrops_received = _airdrops.airdrops_received;
        airdrops[_addr].last_airdrop = _airdrops.last_airdrop;

        IOldTap.Custody memory _custody = oldTap.custody(_addr);
        custody[_addr].manager = _custody.manager;
        custody[_addr].beneficiary = _custody.beneficiary;
        custody[_addr].last_heartbeat = _custody.last_heartbeat;
        custody[_addr].last_checkin = _custody.last_checkin;
        custody[_addr].heartbeat_interval = _custody.heartbeat_interval;
    }

    function migrateFromOldContractAdmin(address _addr) external onlyOwner {
        require(users[_addr].deposits == 0, "User is already transfered");
        IOldTap.User memory _user = oldTap.users(_addr);
        users[_addr].upline = _user.upline;
        users[_addr].referrals = _user.referrals;
        users[_addr].total_structure = _user.total_structure;
        users[_addr].direct_bonus = _user.direct_bonus;
        users[_addr].match_bonus = _user.match_bonus;
        users[_addr].deposits = _user.deposits;
        users[_addr].deposit_time = _user.deposit_time;
        users[_addr].payouts = _user.payouts;
        users[_addr].rolls = _user.rolls;
        users[_addr].ref_claim_pos = _user.ref_claim_pos;

        IOldTap.Airdrop memory _airdrops = oldTap.airdrops(_addr);
        airdrops[_addr].airdrops = _airdrops.airdrops;
        airdrops[_addr].airdrops_received = _airdrops.airdrops_received;
        airdrops[_addr].last_airdrop = _airdrops.last_airdrop;

        IOldTap.Custody memory _custody = oldTap.custody(_addr);
        custody[_addr].manager = _custody.manager;
        custody[_addr].beneficiary = _custody.beneficiary;
        custody[_addr].last_heartbeat = _custody.last_heartbeat;
        custody[_addr].last_checkin = _custody.last_checkin;
        custody[_addr].heartbeat_interval = _custody.heartbeat_interval;
    }

    function migrateStatsFromOldContract() external onlyOwner {
        (
            uint256 _total_users,
            uint256 _total_deposited,
            uint256 _total_withdraw,
            uint256 _total_bnb,
            uint256 _total_txs,
            uint256 _total_airdrops
        ) = oldTap.contractInfo();
        total_users = _total_users;
        total_deposited = _total_deposited;
        total_withdraw = _total_withdraw;
        total_bnb = _total_bnb;
        total_txs = _total_txs;
        total_airdrops = _total_airdrops;
    }

    /****** Admin Functions *******/
    modifier noBlackList() {
        require(!blackList[msg.sender] == true, "No Blacklist calls");
        _;
    }

    function removeFromBlackList(address[] memory blackListAddress)
        external
        onlyOwner
    {
        for (uint256 i; i < blackListAddress.length; i++) {
            blackList[blackListAddress[i]] = false;
        }
    }

    function addToBlackList(address[] memory blackListAddress)
        external
        onlyOwner
    {
        for (uint256 i; i < blackListAddress.length; i++) {
            blackList[blackListAddress[i]] = true;
        }
    }

    function setTotalAirdrops(uint256 newTotalAirdrop) external onlyOwner {
        total_airdrops = newTotalAirdrop;
    }

    function setTotalUsers(uint256 newTotalUsers) external onlyOwner {
        total_users = newTotalUsers;
    }

    function setTotalDeposits(uint256 newTotalDeposits) external onlyOwner {
        total_deposited = newTotalDeposits;
    }

    function setTotalWithdraw(uint256 newTotalWithdraw) external onlyOwner {
        total_withdraw = newTotalWithdraw;
    }

    function setTotalBNB(uint256 newTotalBNB) external onlyOwner {
        total_bnb = newTotalBNB;
    }

    function setTotalTX(uint256 newTotalTX) external onlyOwner {
        total_txs = newTotalTX;
    }

    function getWaveTokenAddress()
        external
        view
        returns (address waveTokenAddress)
    {
        waveTokenAddress = address(waveToken);
    }

    function getSplashTokenAddress()
        external
        view
        returns (address splashTokenAddress)
    {
        splashTokenAddress = address(splashToken);
    }

    function getOldTapAddress() external view returns (address oldTapAddress) {
        oldTapAddress = address(oldTap);
    }

    function setWaveToken(address _waveTokenAddress) external onlyOwner {
        waveToken = IToken(_waveTokenAddress);
    }

    function setSplashToken(address _splashTokenAddress) external onlyOwner {
        splashToken = IToken(_splashTokenAddress);
    }

    function setOldTap(address _oldTapAddress) external onlyOwner {
        oldTap = IOldTap(_oldTapAddress);
    }

    function updatePayoutRate(uint256 _newPayoutRate) external onlyOwner {
        payoutRate = _newPayoutRate;
    }

    function updateRefDepth(uint256 _newRefDepth) external onlyOwner {
        ref_depth = _newRefDepth;
    }

    function updateRefBonus(uint256 _newRefBonus) external onlyOwner {
        ref_bonus = _newRefBonus;
    }

    function updateInitialDeposit(uint256 _newInitialDeposit)
        external
        onlyOwner
    {
        minimumInitial = _newInitialDeposit;
    }

    function updateCompoundTax(uint256 _newCompoundTax) external onlyOwner {
        require(_newCompoundTax >= 0 && _newCompoundTax <= 20);
        CompoundTax = _newCompoundTax;
    }

    function updateExitTax(uint256 _newExitTax) external onlyOwner {
        require(_newExitTax >= 0 && _newExitTax <= 20);
        ExitTax = _newExitTax;
    }

    function updateDepositBracketSize(uint256 _newBracketSize)
        external
        onlyOwner
    {
        deposit_bracket_size = _newBracketSize;
    }

    function updateMaxPayoutCap(uint256 _newPayoutCap) external onlyOwner {
        max_payout_cap = _newPayoutCap;
    }

    function updateHoldRequirements(uint256[] memory _newRefBalances)
        external
        onlyOwner
    {
        require(_newRefBalances.length == ref_depth);
        delete ref_balances;
        for (uint8 i = 0; i < ref_depth; i++) {
            ref_balances.push(_newRefBalances[i]);
        }
    }

    function removeLiquidity(uint256 _amount) external onlyOwner {
        require(
            splashToken.transfer(address(msg.sender), _amount),
            "SPLAH token transfer failed"
        );
    }

    /********** User Functions **************************************************/

    function checkin() public {
        address _addr = msg.sender;
        custody[_addr].last_checkin = block.timestamp;
        emit Checkin(_addr, custody[_addr].last_checkin);
    }

    //@dev Deposit specified Splash amount supplying an upline referral
    function deposit(address _upline, uint256 _amount)
        external
        noBlackList
        isNotPaused
    {
        address _addr = msg.sender;
        (uint256 realizedDeposit, ) = splashToken.calculateTransferTaxes(
            _addr,
            _amount
        );
        uint256 _total_amount = realizedDeposit;
        //Checkin for custody management.
        checkin();
        require(_amount >= minimumAmount, "Minimum deposit");
        //If fresh account require a minimal amount of DRIP
        if (users[_addr].deposits == 0) {
            require(_amount >= minimumInitial, "Initial deposit too low");
        }

        _setUpline(_addr, _upline);

        uint256 taxedDivs;
        // Claim if divs are greater than 1% of the deposit
        if (claimsAvailable(_addr) > _amount / 100) {
            uint256 claimedDivs = _claim(_addr, true);
            taxedDivs = claimedDivs.mul(SafeMath.sub(100, CompoundTax)).div(
                100
            ); // 5% tax on compounding
            _total_amount += taxedDivs;
            taxedDivs = taxedDivs / 2;
        }

        //Transfer Splash to the contract
        require(
            splashToken.transferFrom(_addr, address(this), _amount),
            "SPLASH token transfer failed"
        );
        /*
        User deposits 10;
        1 goes for tax, 9 are realized deposit
        */

        _deposit(_addr, _total_amount);

        _refPayout(_addr, realizedDeposit + taxedDivs, ref_bonus);

        emit Leaderboard(
            _addr,
            users[_addr].referrals,
            users[_addr].deposits,
            users[_addr].payouts,
            users[_addr].total_structure
        );
        total_txs++;
    }

    //@dev Claim, transfer, withdraw from vault
    function claim() external noBlackList isNotPaused {
        //Checkin for custody management.  If a user rolls for themselves they are active
        checkin();

        address _addr = msg.sender;

        _claim_out(_addr);
    }

    //@dev Claim and deposit;
    function roll() external noBlackList isNotPaused {
        //Checkin for custody management.  If a user rolls for themselves they are active
        checkin();

        address _addr = msg.sender;

        _roll(_addr);
    }

    /********** Internal Fuctions **************************************************/

    //@dev Add direct referral and update team structure of upline
    function _setUpline(address _addr, address _upline) internal {
        /*
    1) User must not have existing up-line
    2) Up-line argument must not be equal to senders own address
    3) Senders address must not be equal to the owner
    4) Up-lined user must have a existing deposit
    */
        if (
            users[_addr].upline == address(0) &&
            _upline != _addr &&
            _addr != owner() &&
            (users[_upline].deposit_time > 0 || _upline == owner())
        ) {
            users[_addr].upline = _upline;
            users[_upline].referrals++;

            emit Upline(_addr, _upline);

            total_users++;

            for (uint8 i = 0; i < ref_depth; i++) {
                if (_upline == address(0)) break;

                users[_upline].total_structure++;

                _upline = users[_upline].upline;
            }
        }
    }

    //@dev Deposit
    function _deposit(address _addr, uint256 _amount) internal {
        //Can't maintain upline referrals without this being set

        require(
            users[_addr].upline != address(0) || _addr == owner(),
            "No upline"
        );

        //stats
        users[_addr].deposits += _amount;
        users[_addr].deposit_time = block.timestamp;

        total_deposited += _amount;

        //events
        emit NewDeposit(_addr, _amount);
    }

    //Payout upline; Bonuses are from 5 - 30% on the 1% paid out daily; Referrals only help
    function _refPayout(
        address _addr,
        uint256 _amount,
        uint256 _refBonus
    ) internal {
        //for deposit _addr is the sender/depositor

        address _up = users[_addr].upline;
        uint256 _bonus = (_amount * _refBonus) / 100; // 10% of amount
        uint256 _share = _bonus / 4; // 2.5% of amount
        uint256 _up_share = _bonus.sub(_share); // 7.5% of amount
        bool _team_found = false;

        for (uint8 i = 0; i < ref_depth; i++) {
            // If we have reached the top of the chain, the owner
            if (_up == address(0)) {
                //The equivalent of looping through all available
                users[_addr].ref_claim_pos = ref_depth;
                break;
            }

            //We only match if the claim position is valid
            if (users[_addr].ref_claim_pos == i) {
                if (isBalanceCovered(_up, i + 1) && isNetPositive(_up)) {
                    //Team wallets are split 75/25%
                    if (users[_up].referrals >= 5 && !_team_found) {
                        //This should only be called once
                        _team_found = true;

                        (uint256 gross_payout_upline, , , ) = payoutOf(_up);
                        users[_up].accumulatedDiv = gross_payout_upline;
                        users[_up].deposits += _up_share;
                        users[_up].deposit_time = block.timestamp;

                        (uint256 gross_payout_addr, , , ) = payoutOf(_addr);
                        users[_addr].accumulatedDiv = gross_payout_addr;
                        users[_addr].deposits += _share;
                        users[_addr].deposit_time = block.timestamp;

                        //match accounting
                        users[_up].match_bonus += _up_share;

                        //Synthetic Airdrop tracking; team wallets get automatic airdrop benefits
                        airdrops[_up].airdrops += _share;
                        airdrops[_up].last_airdrop = block.timestamp;
                        airdrops[_addr].airdrops_received += _share;

                        //Global airdrops
                        total_airdrops += _share;

                        //Events
                        emit NewDeposit(_addr, _share);
                        emit NewDeposit(_up, _up_share);

                        emit NewAirdrop(_up, _addr, _share, block.timestamp);
                        emit MatchPayout(_up, _addr, _up_share);
                    } else {
                        (uint256 gross_payout, , , ) = payoutOf(_up);
                        users[_up].accumulatedDiv = gross_payout;
                        users[_up].deposits += _bonus;
                        users[_up].deposit_time = block.timestamp;

                        //match accounting
                        users[_up].match_bonus += _bonus;

                        //events
                        emit NewDeposit(_up, _bonus);
                        emit MatchPayout(_up, _addr, _bonus);
                    }

                    if (users[_up].upline == address(0)) {
                        users[_addr].ref_claim_pos = ref_depth;
                    }

                    //The work has been done for the position; just break
                    break;
                }

                users[_addr].ref_claim_pos += 1;
            }

            _up = users[_up].upline;
        }

        //Reward the next
        users[_addr].ref_claim_pos += 1;

        //Reset if we've hit the end of the line
        if (users[_addr].ref_claim_pos >= ref_depth) {
            users[_addr].ref_claim_pos = 0;
        }
    }

    //@dev General purpose heartbeat in the system used for custody/management planning
    function _heart(address _addr) internal {
        custody[_addr].last_heartbeat = block.timestamp;
        emit HeartBeat(_addr, custody[_addr].last_heartbeat);
    }

    //@dev Claim and deposit;
    function _roll(address _addr) internal {
        uint256 to_payout = _claim(_addr, false);

        uint256 payout_taxed = to_payout
            .mul(SafeMath.sub(100, CompoundTax))
            .div(100); // 5% tax on compounding

        //Recycle baby!
        _deposit(_addr, payout_taxed);

        //track rolls for net positive
        users[_addr].rolls += payout_taxed;

        emit Leaderboard(
            _addr,
            users[_addr].referrals,
            users[_addr].deposits,
            users[_addr].payouts,
            users[_addr].total_structure
        );
        total_txs++;
    }

    //@dev Claim, transfer, and topoff
    function _claim_out(address _addr) internal {
        uint256 to_payout = _claim(_addr, true);

        // uint256 vaultBalance = dripToken.balanceOf(dripVaultAddress);
        // if (vaultBalance < to_payout) {
        //   uint256 differenceToMint = to_payout.sub(vaultBalance);
        //   tokenMint.mint(dripVaultAddress, differenceToMint);
        // }

        // dripVault.withdraw(to_payout);

        uint256 realizedPayout = to_payout.mul(SafeMath.sub(100, ExitTax)).div(
            100
        ); // 10% tax on withdraw
        require(splashToken.transfer(address(msg.sender), realizedPayout));

        emit Leaderboard(
            _addr,
            users[_addr].referrals,
            users[_addr].deposits,
            users[_addr].payouts,
            users[_addr].total_structure
        );
        total_txs++;
    }

    //@dev Claim current payouts
    function _claim(address _addr, bool isClaimedOut)
        internal
        returns (uint256)
    {
        (
            uint256 _gross_payout,
            uint256 _max_payout,
            uint256 _to_payout,

        ) = payoutOf(_addr);
        require(users[_addr].payouts < _max_payout, "Full payouts");

        // Deposit payout
        if (_to_payout > 0) {
            // payout remaining allowable divs if exceeds
            if (users[_addr].payouts + _to_payout > _max_payout) {
                _to_payout = _max_payout.safeSub(users[_addr].payouts);
            }

            users[_addr].payouts += _gross_payout;

            if (!isClaimedOut) {
                //Payout referrals
                uint256 compoundTaxedPayout = _to_payout
                    .mul(SafeMath.sub(100, CompoundTax))
                    .div(100); // 5% tax on compounding
                _refPayout(_addr, compoundTaxedPayout, 5);
            }
        }

        require(_to_payout > 0, "Zero payout");

        //Update the payouts
        total_withdraw += _to_payout;

        //Update time!
        users[_addr].deposit_time = block.timestamp;
        users[_addr].accumulatedDiv = 0;

        emit Withdraw(_addr, _to_payout);

        if (users[_addr].payouts >= _max_payout) {
            emit LimitReached(_addr, users[_addr].payouts);
        }

        return _to_payout;
    }

    /********* Views ***************************************/

    //@dev Returns true if the address is net positive
    function isNetPositive(address _addr) public view returns (bool) {
        (uint256 _credits, uint256 _debits) = creditsAndDebits(_addr);

        return _credits > _debits;
    }

    //@dev Returns the total credits and debits for a given address
    function creditsAndDebits(address _addr)
        public
        view
        returns (uint256 _credits, uint256 _debits)
    {
        User memory _user = users[_addr];
        Airdrop memory _airdrop = airdrops[_addr];

        _credits = _airdrop.airdrops + _user.rolls + _user.deposits;
        _debits = _user.payouts;
    }

    //@dev Returns whether BR34P balance matches level
    function isBalanceCovered(address _addr, uint8 _level)
        public
        view
        returns (bool)
    {
        if (users[_addr].upline == address(0)) {
            return true;
        }
        return balanceLevel(_addr) >= _level;
    }

    //@dev Returns the level of the address
    function balanceLevel(address _addr) public view returns (uint8) {
        uint8 _level = 0;
        for (uint8 i = 0; i < ref_depth; i++) {
            if (waveToken.balanceOf(_addr) < ref_balances[i]) break;
            _level += 1;
        }

        return _level;
    }

    //@dev Returns custody info of _addr
    function getCustody(address _addr)
        public
        view
        returns (
            address _beneficiary,
            uint256 _heartbeat_interval,
            address _manager
        )
    {
        return (
            custody[_addr].beneficiary,
            custody[_addr].heartbeat_interval,
            custody[_addr].manager
        );
    }

    //@dev Returns account activity timestamps
    function lastActivity(address _addr)
        public
        view
        returns (
            uint256 _heartbeat,
            uint256 _lapsed_heartbeat,
            uint256 _checkin,
            uint256 _lapsed_checkin
        )
    {
        _heartbeat = custody[_addr].last_heartbeat;
        _lapsed_heartbeat = block.timestamp.safeSub(_heartbeat);
        _checkin = custody[_addr].last_checkin;
        _lapsed_checkin = block.timestamp.safeSub(_checkin);
    }

    //@dev Returns amount of claims available for sender
    function claimsAvailable(address _addr) public view returns (uint256) {
        (, , uint256 _to_payout, ) = payoutOf(_addr);
        return _to_payout;
    }

    //@dev Maxpayout of 3.60 of deposit
    function maxPayoutOf(uint256 _amount) public pure returns (uint256) {
        return (_amount * 360) / 100;
    }

    function sustainabilityFeeV2(address _addr, uint256 _pendingDiv)
        public
        view
        returns (uint256)
    {
        uint256 _bracket = users[_addr].payouts.add(_pendingDiv).div(
            deposit_bracket_size
        );
        _bracket = SafeMath.min(_bracket, deposit_bracket_max);
        return _bracket * 5;
    }

    //@dev Calculate the current payout and maxpayout of a given address
    function payoutOf(address _addr)
        public
        view
        returns (
            uint256 payout,
            uint256 max_payout,
            uint256 net_payout,
            uint256 sustainability_fee
        )
    {
        //The max_payout is capped so that we can also cap available rewards daily
        max_payout = maxPayoutOf(users[_addr].deposits).min(max_payout_cap);

        uint256 share;

        if (users[_addr].payouts < max_payout) {
            //Using 1e18 we capture all significant digits when calculating available divs
            share = users[_addr]
                .deposits
                .mul(payoutRate * 1e18)
                .div(100e18)
                .div(24 hours); //divide the profit by payout rate and seconds in the day

            payout = share * block.timestamp.safeSub(users[_addr].deposit_time);
            payout += users[_addr].accumulatedDiv;
            // payout remaining allowable divs if exceeds
            if (users[_addr].payouts + payout > max_payout) {
                payout = max_payout.safeSub(users[_addr].payouts);
            }

            uint256 _fee = sustainabilityFeeV2(_addr, payout);

            sustainability_fee = (payout * _fee) / 100;

            net_payout = payout.safeSub(sustainability_fee);
        }
    }

    //@dev Get current user snapshot
    function userInfo(address _addr)
        external
        view
        returns (
            address upline,
            uint256 deposit_time,
            uint256 deposits,
            uint256 payouts,
            uint256 direct_bonus,
            uint256 match_bonus,
            uint256 last_airdrop
        )
    {
        return (
            users[_addr].upline,
            users[_addr].deposit_time,
            users[_addr].deposits,
            users[_addr].payouts,
            users[_addr].direct_bonus,
            users[_addr].match_bonus,
            airdrops[_addr].last_airdrop
        );
    }

    //@dev Get user totals
    function userInfoTotals(address _addr)
        external
        view
        returns (
            uint256 referrals,
            uint256 total_deposits,
            uint256 total_payouts,
            uint256 total_structure,
            uint256 airdrops_total,
            uint256 airdrops_received
        )
    {
        return (
            users[_addr].referrals,
            users[_addr].deposits,
            users[_addr].payouts,
            users[_addr].total_structure,
            airdrops[_addr].airdrops,
            airdrops[_addr].airdrops_received
        );
    }

    //@dev Get contract snapshot
    function contractInfo()
        external
        view
        returns (
            uint256 _total_users,
            uint256 _total_deposited,
            uint256 _total_withdraw,
            uint256 _total_bnb,
            uint256 _total_txs,
            uint256 _total_airdrops
        )
    {
        return (
            total_users,
            total_deposited,
            total_withdraw,
            total_bnb,
            total_txs,
            total_airdrops
        );
    }

    /////// Airdrops ///////

    //@dev Send specified Splash amount supplying an upline referral
    function airdrop(address _to, uint256 _amount)
        public
        noBlackList
        isNotPaused
    {
        address _addr = msg.sender;

        (uint256 _realizedAmount, ) = splashToken.calculateTransferTaxes(
            _addr,
            _amount
        );
        //This can only fail if the balance is insufficient
        require(
            splashToken.transferFrom(_addr, address(this), _amount),
            "Splash to contract transfer failed; check balance and allowance, airdrop"
        );

        //Make sure _to exists in the system; we increase
        require(users[_to].upline != address(0), "_to not found");

        (uint256 gross_payout, , , ) = payoutOf(_to);

        users[_to].accumulatedDiv = gross_payout;

        //Fund to deposits (not a transfer)
        users[_to].deposits += _realizedAmount;
        users[_to].deposit_time = block.timestamp;

        //User stats
        airdrops[_addr].airdrops += _realizedAmount;
        airdrops[_addr].last_airdrop = block.timestamp;
        airdrops[_to].airdrops_received += _realizedAmount;

        //Keep track of overall stats
        total_airdrops += _realizedAmount;
        total_txs += 1;

        //Let em know!
        emit NewAirdrop(_addr, _to, _realizedAmount, block.timestamp);
        emit NewDeposit(_to, _realizedAmount);
    }

    /////// Airdrops ///////

    //@dev Send specified Splash amount supplying an upline referral
    function MultiSendairdrop(address[] memory _to, uint256 _amount)
        external
        noBlackList
        isNotPaused
    {
        address _addr = msg.sender;
        uint256 _realizedAmount;
        uint256 _taxAmount;
        uint256 _airdropSent;
        require(
            splashToken.balanceOf(_addr) >= _amount * _to.length,
            "Not enough balance"
        );
        for (uint256 i = 0; i < _to.length; i++) {
            //This can only fail if the balance is insufficient
            require(
                splashToken.transferFrom(_addr, address(this), _amount),
                "Splash to contract transfer failed; check balance and allowance, airdrop"
            );
            //Make sure _to exists in the system; we increase
            require(users[_to[i]].upline != address(0), "_to not found");
            (_realizedAmount, _taxAmount) = splashToken.calculateTransferTaxes(
                _addr,
                _amount
            );
            //Fund to deposits (not a transfer)
            (uint256 gross_payout, , , ) = payoutOf(_to[i]);
            users[_to[i]].accumulatedDiv = gross_payout;
            users[_to[i]].deposits += _realizedAmount;
            users[_to[i]].deposit_time = block.timestamp;
            airdrops[_to[i]].airdrops_received += _realizedAmount;
            _airdropSent += _realizedAmount;
            // //Let em know!
            emit NewAirdrop(_addr, _to[i], _realizedAmount, block.timestamp);
            emit NewDeposit(_to[i], _realizedAmount);
        }

        //User stats
        airdrops[_addr].airdrops += _airdropSent;
        airdrops[_addr].last_airdrop = block.timestamp;
        //Keep track of overall stats
        total_airdrops += _airdropSent;
        total_txs += 1;
    }

    function MultiSendairdropDiffAmounts(
        address[] memory _to,
        uint256[] memory _amounts
    ) external onlyOwner {
        address _addr = msg.sender;
        uint256 _realizedAmount;
        uint256 _taxAmount;
        uint256 _airdropSent;
        require(
            _to.length == _amounts.length,
            "Arrays need to be the same length"
        );
        for (uint256 i = 0; i < _to.length; i++) {
            //This can only fail if the balance is insufficient
            require(
                splashToken.transferFrom(_addr, address(this), _amounts[i]),
                "Splash to contract transfer failed; check balance and allowance, airdrop"
            );
            //Make sure _to exists in the system; we increase
            require(users[_to[i]].upline != address(0), "_to not found");
            (_realizedAmount, _taxAmount) = splashToken.calculateTransferTaxes(
                _addr,
                _amounts[i]
            );
            //Fund to deposits (not a transfer)
            (uint256 gross_payout, , , ) = payoutOf(_to[i]);
            users[_to[i]].accumulatedDiv = gross_payout;
            users[_to[i]].deposits += _realizedAmount;
            users[_to[i]].deposit_time = block.timestamp;
            airdrops[_to[i]].airdrops_received += _realizedAmount;
            _airdropSent += _realizedAmount;
            // //Let em know!
            emit NewAirdrop(_addr, _to[i], _realizedAmount, block.timestamp);
            emit NewDeposit(_to[i], _realizedAmount);
        }

        //User stats
        airdrops[_addr].airdrops += _airdropSent;
        airdrops[_addr].last_airdrop = block.timestamp;
        //Keep track of overall stats
        total_airdrops += _airdropSent;
        total_txs += 1;
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b > a) {
            return 0;
        } else {
            return a - b;
        }
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
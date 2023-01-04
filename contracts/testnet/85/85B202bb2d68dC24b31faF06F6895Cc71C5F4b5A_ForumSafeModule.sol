// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title Enum - Collection of enums
/// @author Richard Meissner - <[email protected]>
contract Enum {
    enum Operation {Call, DelegateCall}
}

// SPDX-License-Identifier: LGPL-3.0-only

/// @title Module Interface - A contract that can pass messages to a Module Manager contract if enabled by that contract.
pragma solidity >=0.7.0 <0.9.0;

import "../interfaces/IAvatar.sol";
import "../factory/FactoryFriendly.sol";
import "../guard/Guardable.sol";

abstract contract Module is FactoryFriendly, Guardable {
    /// @dev Address that will ultimately execute function calls.
    address public avatar;
    /// @dev Address that this module will pass transactions to.
    address public target;

    /// @dev Emitted each time the avatar is set.
    event AvatarSet(address indexed previousAvatar, address indexed newAvatar);
    /// @dev Emitted each time the Target is set.
    event TargetSet(address indexed previousTarget, address indexed newTarget);

    /// @dev Sets the avatar to a new avatar (`newAvatar`).
    /// @notice Can only be called by the current owner.
    function setAvatar(address _avatar) public onlyOwner {
        address previousAvatar = avatar;
        avatar = _avatar;
        emit AvatarSet(previousAvatar, _avatar);
    }

    /// @dev Sets the target to a new target (`newTarget`).
    /// @notice Can only be called by the current owner.
    function setTarget(address _target) public onlyOwner {
        address previousTarget = target;
        target = _target;
        emit TargetSet(previousTarget, _target);
    }

    /// @dev Passes a transaction to be executed by the avatar.
    /// @notice Can only be called by this contract.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction: 0 == call, 1 == delegate call.
    function exec(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) internal returns (bool success) {
        /// Check if a transactioon guard is enabled.
        if (guard != address(0)) {
            IGuard(guard).checkTransaction(
                /// Transaction info used by module transactions.
                to,
                value,
                data,
                operation,
                /// Zero out the redundant transaction information only used for Safe multisig transctions.
                0,
                0,
                0,
                address(0),
                payable(0),
                bytes("0x"),
                msg.sender
            );
        }
        success = IAvatar(target).execTransactionFromModule(
            to,
            value,
            data,
            operation
        );
        if (guard != address(0)) {
            IGuard(guard).checkAfterExecution(bytes32("0x"), success);
        }
        return success;
    }

    /// @dev Passes a transaction to be executed by the target and returns data.
    /// @notice Can only be called by this contract.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction: 0 == call, 1 == delegate call.
    function execAndReturnData(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) internal returns (bool success, bytes memory returnData) {
        /// Check if a transactioon guard is enabled.
        if (guard != address(0)) {
            IGuard(guard).checkTransaction(
                /// Transaction info used by module transactions.
                to,
                value,
                data,
                operation,
                /// Zero out the redundant transaction information only used for Safe multisig transctions.
                0,
                0,
                0,
                address(0),
                payable(0),
                bytes("0x"),
                msg.sender
            );
        }
        (success, returnData) = IAvatar(target)
            .execTransactionFromModuleReturnData(to, value, data, operation);
        if (guard != address(0)) {
            IGuard(guard).checkAfterExecution(bytes32("0x"), success);
        }
        return (success, returnData);
    }
}

// SPDX-License-Identifier: LGPL-3.0-only

/// @title Zodiac FactoryFriendly - A contract that allows other contracts to be initializable and pass bytes as arguments to define contract state
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract FactoryFriendly is OwnableUpgradeable {
    function setUp(bytes memory initializeParams) public virtual;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "../interfaces/IGuard.sol";

abstract contract BaseGuard is IERC165 {
    function supportsInterface(bytes4 interfaceId)
        external
        pure
        override
        returns (bool)
    {
        return
            interfaceId == type(IGuard).interfaceId || // 0xe6d7a83a
            interfaceId == type(IERC165).interfaceId; // 0x01ffc9a7
    }

    /// @dev Module transactions only use the first four parameters: to, value, data, and operation.
    /// Module.sol hardcodes the remaining parameters as 0 since they are not used for module transactions.
    /// @notice This interface is used to maintain compatibilty with Gnosis Safe transaction guards.
    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures,
        address msgSender
    ) external virtual;

    function checkAfterExecution(bytes32 txHash, bool success) external virtual;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./BaseGuard.sol";

/// @title Guardable - A contract that manages fallback calls made to this contract
contract Guardable is OwnableUpgradeable {
    address public guard;

    event ChangedGuard(address guard);

    /// `guard_` does not implement IERC165.
    error NotIERC165Compliant(address guard_);

    /// @dev Set a guard that checks transactions before execution.
    /// @param _guard The address of the guard to be used or the 0 address to disable the guard.
    function setGuard(address _guard) external onlyOwner {
        if (_guard != address(0)) {
            if (!BaseGuard(_guard).supportsInterface(type(IGuard).interfaceId))
                revert NotIERC165Compliant(_guard);
        }
        guard = _guard;
        emit ChangedGuard(guard);
    }

    function getGuard() external view returns (address _guard) {
        return guard;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only

/// @title Zodiac Avatar - A contract that manages modules that can execute transactions via this contract.
pragma solidity >=0.7.0 <0.9.0;

import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";

interface IAvatar {
    event EnabledModule(address module);
    event DisabledModule(address module);
    event ExecutionFromModuleSuccess(address indexed module);
    event ExecutionFromModuleFailure(address indexed module);

    /// @dev Enables a module on the avatar.
    /// @notice Can only be called by the avatar.
    /// @notice Modules should be stored as a linked list.
    /// @notice Must emit EnabledModule(address module) if successful.
    /// @param module Module to be enabled.
    function enableModule(address module) external;

    /// @dev Disables a module on the avatar.
    /// @notice Can only be called by the avatar.
    /// @notice Must emit DisabledModule(address module) if successful.
    /// @param prevModule Address that pointed to the module to be removed in the linked list
    /// @param module Module to be removed.
    function disableModule(address prevModule, address module) external;

    /// @dev Allows a Module to execute a transaction.
    /// @notice Can only be called by an enabled module.
    /// @notice Must emit ExecutionFromModuleSuccess(address module) if successful.
    /// @notice Must emit ExecutionFromModuleFailure(address module) if unsuccessful.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction: 0 == call, 1 == delegate call.
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) external returns (bool success);

    /// @dev Allows a Module to execute a transaction and return data
    /// @notice Can only be called by an enabled module.
    /// @notice Must emit ExecutionFromModuleSuccess(address module) if successful.
    /// @notice Must emit ExecutionFromModuleFailure(address module) if unsuccessful.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction: 0 == call, 1 == delegate call.
    function execTransactionFromModuleReturnData(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) external returns (bool success, bytes memory returnData);

    /// @dev Returns if an module is enabled
    /// @return True if the module is enabled
    function isModuleEnabled(address module) external view returns (bool);

    /// @dev Returns array of modules.
    /// @param start Start of the page.
    /// @param pageSize Maximum number of modules that should be returned.
    /// @return array Array of modules.
    /// @return next Start of the next page.
    function getModulesPaginated(address start, uint256 pageSize)
        external
        view
        returns (address[] memory array, address next);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";

interface IGuard {
    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures,
        address msgSender
    ) external;

    function checkAfterExecution(bytes32 txHash, bool success) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import {EnumerableSet} from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

/// @notice Minimalist and gas efficient ERC1155 based DAO implementation with governance.
/// @author Modified from KaliDAO (https://github.com/kalidao/kali-contracts/blob/main/contracts/KaliDAOtoken.sol)
abstract contract ForumGovernance {
	using EnumerableSet for EnumerableSet.AddressSet;

	/// ----------------------------------------------------------------------------------------
	///							EVENTS
	/// ----------------------------------------------------------------------------------------

	event TransferSingle(
		address indexed operator,
		address indexed from,
		address indexed to,
		uint256 id,
		uint256 amount
	);

	event TransferBatch(
		address indexed operator,
		address indexed from,
		address indexed to,
		uint256[] ids,
		uint256[] amounts
	);

	event ApprovalForAll(address indexed owner, address indexed operator, bool indexed approved);

	event URI(string value, uint256 indexed id);

	event PauseFlipped(bool indexed paused);

	event Delegation(
		address indexed delegator,
		address indexed currentDelegatee,
		address indexed delegatee
	);

	/// ----------------------------------------------------------------------------------------
	///							ERRORS
	/// ----------------------------------------------------------------------------------------

	error Paused();

	error SignatureExpired();

	error InvalidDelegate();

	error Uint32max();

	error Uint96max();

	error InvalidNonce();

	/// ----------------------------------------------------------------------------------------
	///							METADATA STORAGE
	/// ----------------------------------------------------------------------------------------

	string public name;

	string public symbol;

	uint8 public constant decimals = 18;

	/// ----------------------------------------------------------------------------------------
	///							ERC1155 STORAGE
	/// ----------------------------------------------------------------------------------------

	uint256 public totalSupply;

	mapping(address => mapping(uint256 => uint256)) public balanceOf;

	mapping(address => mapping(address => bool)) public isApprovedForAll;

	/// ----------------------------------------------------------------------------------------
	///							EIP-712 STORAGE
	/// ----------------------------------------------------------------------------------------

	bytes32 internal INITIAL_DOMAIN_SEPARATOR;

	uint256 internal INITIAL_CHAIN_ID;

	mapping(address => uint256) public nonces;

	/// ----------------------------------------------------------------------------------------
	///							GROUP STORAGE
	/// ----------------------------------------------------------------------------------------

	bool public paused;

	bytes32 public constant DELEGATION_TYPEHASH =
		keccak256('Delegation(address delegatee,uint256 nonce,uint256 deadline)');

	// Membership NFT
	uint256 internal constant MEMBERSHIP = 0;
	// DAO token representing voting share of treasury
	uint256 internal constant TOKEN = 1;

	uint256 public memberCount;

	// All delegators for a member -> default case is an empty array
	mapping(address => EnumerableSet.AddressSet) internal memberDelegators;
	// The current delegate of a member -> default is no delegation, ie address(0)
	mapping(address => address) public memberDelegatee;

	/// ----------------------------------------------------------------------------------------
	///							CONSTRUCTOR
	/// ----------------------------------------------------------------------------------------

	function _init(
		string memory name_,
		string memory symbol_,
		address[] memory members_
	) internal virtual {
		name = name_;

		symbol = symbol_;

		paused = true;

		INITIAL_CHAIN_ID = block.chainid;

		INITIAL_DOMAIN_SEPARATOR = _computeDomainSeparator();

		unchecked {
			uint256 votersLen = members_.length;

			// Mint membership for initial members
			for (uint256 i; i < votersLen; ) {
				_mint(members_[i], MEMBERSHIP, 1, '');
				++i;
			}
		}
	}

	/// ----------------------------------------------------------------------------------------
	///							METADATA LOGIC
	/// ----------------------------------------------------------------------------------------

	function uri(uint256 id) public view virtual returns (string memory);

	/// ----------------------------------------------------------------------------------------
	///							ERC1155 LOGIC
	/// ----------------------------------------------------------------------------------------

	function setApprovalForAll(address operator, bool approved) public virtual {
		isApprovedForAll[msg.sender][operator] = approved;

		emit ApprovalForAll(msg.sender, operator, approved);
	}

	function safeTransferFrom(
		address from,
		address to,
		uint256 id,
		uint256 amount,
		bytes memory data
	) public virtual notPaused {
		require(msg.sender == from || isApprovedForAll[from][msg.sender], 'NOT_AUTHORIZED');

		balanceOf[from][id] -= amount;
		balanceOf[to][id] += amount;

		// Cannot transfer membership while delegating / being delegated to
		if (id == MEMBERSHIP)
			if (memberDelegatee[from] != address(0) || memberDelegators[from].length() > 0)
				revert InvalidDelegate();

		emit TransferSingle(msg.sender, from, to, id, amount);

		require(
			to.code.length == 0
				? to != address(0)
				: ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
					ERC1155TokenReceiver.onERC1155Received.selector,
			'UNSAFE_RECIPIENT'
		);
	}

	function safeBatchTransferFrom(
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) public virtual notPaused {
		uint256 idsLength = ids.length; // Saves MLOADs.

		require(idsLength == amounts.length, 'LENGTH_MISMATCH');

		require(msg.sender == from || isApprovedForAll[from][msg.sender], 'NOT_AUTHORIZED');

		for (uint256 i = 0; i < idsLength; ) {
			uint256 id = ids[i];
			uint256 amount = amounts[i];

			balanceOf[from][id] -= amount;
			balanceOf[to][id] += amount;

			// Cannot transfer membership while delegating / being delegated to
			if (ids[i] == MEMBERSHIP)
				if (memberDelegatee[from] != address(0) || memberDelegators[from].length() > 0)
					revert InvalidDelegate();

			// An array can't have a total length
			// larger than the max uint256 value.
			unchecked {
				i++;
			}
		}

		emit TransferBatch(msg.sender, from, to, ids, amounts);

		require(
			to.code.length == 0
				? to != address(0)
				: ERC1155TokenReceiver(to).onERC1155BatchReceived(
					msg.sender,
					from,
					ids,
					amounts,
					data
				) == ERC1155TokenReceiver.onERC1155BatchReceived.selector,
			'UNSAFE_RECIPIENT'
		);
	}

	function balanceOfBatch(
		address[] memory owners,
		uint256[] memory ids
	) public view virtual returns (uint256[] memory balances) {
		uint256 ownersLength = owners.length; // Saves MLOADs.

		require(ownersLength == ids.length, 'LENGTH_MISMATCH');

		balances = new uint256[](owners.length);

		// Unchecked because the only math done is incrementing
		// the array index counter which cannot possibly overflow.
		unchecked {
			for (uint256 i = 0; i < ownersLength; i++) {
				balances[i] = balanceOf[owners[i]][ids[i]];
			}
		}
	}

	/// ----------------------------------------------------------------------------------------
	///							EIP-2612 LOGIC
	/// ----------------------------------------------------------------------------------------

	function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
		return
			block.chainid == INITIAL_CHAIN_ID
				? INITIAL_DOMAIN_SEPARATOR
				: _computeDomainSeparator();
	}

	function _computeDomainSeparator() internal view virtual returns (bytes32) {
		return
			keccak256(
				abi.encode(
					keccak256(
						'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
					),
					keccak256(bytes(name)),
					keccak256('1'),
					block.chainid,
					address(this)
				)
			);
	}

	/// ----------------------------------------------------------------------------------------
	///							GROUP LOGIC
	/// ----------------------------------------------------------------------------------------

	modifier notPaused() {
		if (paused) revert Paused();
		_;
	}

	function delegators(address delegatee) public view virtual returns (address[] memory) {
		return EnumerableSet.values(memberDelegators[delegatee]);
	}

	function delegate(address delegatee) public payable virtual {
		_delegate(msg.sender, delegatee);
	}

	function delegateBySig(
		address delegatee,
		uint256 nonce,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) public payable virtual {
		if (block.timestamp > deadline) revert SignatureExpired();

		bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, deadline));

		bytes32 digest = keccak256(abi.encodePacked('\x19\x01', DOMAIN_SEPARATOR(), structHash));

		address signatory = ecrecover(digest, v, r, s);

		if (balanceOf[signatory][MEMBERSHIP] == 0) revert InvalidDelegate();

		// cannot realistically overflow on human timescales
		unchecked {
			if (nonce != nonces[signatory]++) revert InvalidNonce();
		}

		_delegate(signatory, delegatee);
	}

	function removeDelegator(address delegator) public virtual {
		// Verify msg.sender is being delegated to by the delegator
		if (memberDelegatee[delegator] != msg.sender) revert InvalidDelegate();
		_delegate(delegator, msg.sender);
	}

	function _delegate(address delegator, address delegatee) internal {
		// Can only delegate from/to existing members
		if (balanceOf[msg.sender][MEMBERSHIP] == 0 || balanceOf[delegatee][MEMBERSHIP] == 0)
			revert InvalidDelegate();

		address currentDelegatee = memberDelegatee[delegator];

		// Can not delegate to others if delegated to
		if (memberDelegators[delegator].length() > 0) revert InvalidDelegate();

		// If delegator is currently delegating
		if (currentDelegatee != address(0)) {
			// 1) remove delegator from the memberDelegators list of their delegatee
			memberDelegators[currentDelegatee].remove(delegator);

			// 2) reset delegator memberDelegatee to address(0)
			memberDelegatee[delegator] = address(0);

			emit Delegation(delegator, currentDelegatee, address(0));

			// If delegator is not currently delegating
		} else {
			// 1) add the delegator to the memberDelegators list of their new delegatee
			memberDelegators[delegatee].add(delegator);

			// 2) set the memberDelegatee of the delegator to the new delegatee
			memberDelegatee[delegator] = delegatee;

			emit Delegation(delegator, currentDelegatee, delegatee);
		}
	}

	/// ----------------------------------------------------------------------------------------
	///							ERC-165 LOGIC
	/// ----------------------------------------------------------------------------------------

	function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
		return
			interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
			interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
			interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
	}

	/// ----------------------------------------------------------------------------------------
	///						INTERNAL MINT/BURN  LOGIC
	/// ----------------------------------------------------------------------------------------

	function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal {
		// Cannot overflow because the sum of all user
		// balances can't exceed the max uint256 value
		unchecked {
			balanceOf[to][id] += amount;
		}

		// If membership token is being updated, update member count
		if (id == MEMBERSHIP) {
			++memberCount;
		}

		// If non membership token is being updated, update total supply
		if (id == TOKEN) {
			totalSupply += amount;
		}

		emit TransferSingle(msg.sender, address(0), to, id, amount);

		require(
			to.code.length == 0
				? to != address(0)
				: ERC1155TokenReceiver(to).onERC1155Received(
					msg.sender,
					address(0),
					id,
					amount,
					data
				) == ERC1155TokenReceiver.onERC1155Received.selector,
			'UNSAFE_RECIPIENT'
		);
	}

	function _batchMint(
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) internal {
		uint256 idsLength = ids.length; // Saves MLOADs.

		require(idsLength == amounts.length, 'LENGTH_MISMATCH');

		for (uint256 i = 0; i < idsLength; ) {
			balanceOf[to][ids[i]] += amounts[i];

			// If membership token is being updated, update member count
			if (ids[i] == MEMBERSHIP) {
				++memberCount;
			}

			// If non membership token is being updated, update total supply
			if (ids[i] == TOKEN) {
				totalSupply += amounts[i];
			}

			// An array can't have a total length
			// larger than the max uint256 value.
			unchecked {
				i++;
			}
		}

		emit TransferBatch(msg.sender, address(0), to, ids, amounts);

		require(
			to.code.length == 0
				? to != address(0)
				: ERC1155TokenReceiver(to).onERC1155BatchReceived(
					msg.sender,
					address(0),
					ids,
					amounts,
					data
				) == ERC1155TokenReceiver.onERC1155BatchReceived.selector,
			'UNSAFE_RECIPIENT'
		);
	}

	function _batchBurn(address from, uint256[] memory ids, uint256[] memory amounts) internal {
		uint256 idsLength = ids.length; // Saves MLOADs.

		require(idsLength == amounts.length, 'LENGTH_MISMATCH');

		for (uint256 i = 0; i < idsLength; ) {
			balanceOf[from][ids[i]] -= amounts[i];

			// If membership token is being updated, update member count
			if (ids[i] == MEMBERSHIP) {
				// Member can not leave while delegating / being delegated to
				if (memberDelegatee[from] != address(0) || memberDelegators[from].length() > 0)
					revert InvalidDelegate();

				--memberCount;
			}

			// If non membership token is being updated, update total supply
			if (ids[i] == TOKEN) {
				totalSupply -= amounts[i];
			}

			// An array can't have a total length
			// larger than the max uint256 value.
			unchecked {
				i++;
			}
		}

		emit TransferBatch(msg.sender, from, address(0), ids, amounts);
	}

	function _burn(address from, uint256 id, uint256 amount) internal {
		balanceOf[from][id] -= amount;

		// If membership token is being updated, update member count
		if (id == MEMBERSHIP) {
			// Member can not leave while delegating / being delegated to
			if (
				memberDelegatee[from] != address(0) ||
				EnumerableSet.length(memberDelegators[from]) > 0
			) revert InvalidDelegate();

			--memberCount;
		}

		// If non membership token is being updated, update total supply
		if (id == TOKEN) {
			totalSupply -= amount;
		}

		emit TransferSingle(msg.sender, from, address(0), id, amount);
	}

	/// ----------------------------------------------------------------------------------------
	///						PAUSE  LOGIC
	/// ----------------------------------------------------------------------------------------

	function _flipPause() internal virtual {
		paused = !paused;

		emit PauseFlipped(paused);
	}

	/// ----------------------------------------------------------------------------------------
	///						SAFECAST  LOGIC
	/// ----------------------------------------------------------------------------------------

	function _safeCastTo32(uint256 x) internal pure virtual returns (uint32) {
		if (x > type(uint32).max) revert Uint32max();

		return uint32(x);
	}

	function _safeCastTo96(uint256 x) internal pure virtual returns (uint96) {
		if (x > type(uint96).max) revert Uint96max();

		return uint96(x);
	}
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
interface ERC1155TokenReceiver {
	function onERC1155Received(
		address operator,
		address from,
		uint256 id,
		uint256 amount,
		bytes calldata data
	) external returns (bytes4);

	function onERC1155BatchReceived(
		address operator,
		address from,
		uint256[] calldata ids,
		uint256[] calldata amounts,
		bytes calldata data
	) external returns (bytes4);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.15;

import {Module} from '@gnosis.pm/zodiac/contracts/core/Module.sol';

import {ForumGovernance, EnumerableSet} from './ForumSafeGovernance.sol';

// TODO consider need for NFTreceiver - does the module need to receive?
import {NFTreceiver} from '../utils/NFTreceiver.sol';
import {ReentrancyGuard} from '../utils/ReentrancyGuard.sol';

import {IForumGroupTypes} from '../interfaces/IForumGroupTypes.sol';
import {IForumGroupExtension} from '../interfaces/IForumGroupExtension.sol';
import {IPfpStaker} from '../interfaces/IPfpStaker.sol';

/**
 * @title ForumSafeModule
 * @notice Forum investment group governance extension for Gnosis Safe
 * @author Modified from KaliDAO (https://github.com/lexDAO/Kali/blob/main/contracts/KaliDAO.sol)
 */
contract ForumSafeModule is
	Module,
	IForumGroupTypes,
	ForumGovernance,
	ReentrancyGuard,
	NFTreceiver
{
	/// ----------------------------------------------------------------------------------------
	///							EVENTS
	/// ----------------------------------------------------------------------------------------

	event NewProposal(
		address indexed proposer,
		uint256 indexed proposal,
		ProposalType indexed proposalType,
		address[] accounts,
		uint256[] amounts,
		bytes[] payloads
	);

	event ProposalProcessed(
		ProposalType indexed proposalType,
		uint256 indexed proposal,
		bool indexed didProposalPass
	);

	/// ----------------------------------------------------------------------------------------
	///							ERRORS
	/// ----------------------------------------------------------------------------------------

	error MemberLimitExceeded();

	error PeriodBounds();

	error VoteThresholdBounds();

	error TypeBounds();

	error NoArrayParity();

	error NotCurrentProposal();

	error NotExtension();

	error PFPFailed();

	error SignatureError();

	error CallError();

	/// ----------------------------------------------------------------------------------------
	///							DAO STORAGE
	/// ----------------------------------------------------------------------------------------

	// Gnosis multisendLibrary library contract
	address public multisendLibrary;

	// Contract generating uri for group tokens
	address private pfpExtension;

	uint256 public proposalCount;
	uint32 public votingPeriod;
	uint32 public memberLimit; // 1-100
	uint32 public tokenVoteThreshold; // 1-100
	uint32 public memberVoteThreshold; // 1-100

	string public docs;

	bytes32 public constant PROPOSAL_HASH = keccak256('SignProposal(uint256 proposal)');

	/**
	 * 'contractSignatureAllowance' provides the contract with the ability to 'sign' as an EOA would
	 * 	It enables signature based transactions on marketplaces accommodating the EIP-1271 standard.
	 *  Address is the account which makes the call to check the verified signature (ie. the martketplace).
	 * 	Bytes32 is the hash of the calldata which the group approves. This data is dependant
	 * 	on the marketplace / dex where the group are approving the transaction.
	 */
	mapping(address => mapping(bytes32 => uint256)) private contractSignatureAllowance;
	mapping(address => bool) public extensions;
	mapping(uint256 => Proposal) public proposals;
	mapping(ProposalType => VoteType) public proposalVoteTypes;

	/// ----------------------------------------------------------------------------------------
	///							CONSTRUCTOR
	/// ----------------------------------------------------------------------------------------

	/// @dev This constructor ensures that this contract can only be used as a master copy for Proxy contracts
	constructor() initializer {
		// By setting the owner it is not possible to call setUp
		// This is an unusable Forum group, perfect for the singleton
		__Ownable_init();
		transferOwnership(address(0xdead));
	}

	/**
	 * @notice init the group settings and mint membership for founders
	 * @param _initializationParams for the group, decoded to:
	 * 	(_name ,_symbol ,_members ,_extension ,_govSettings)
	 */
	function setUp(
		bytes memory _initializationParams
	) public virtual override initializer nonReentrant {
		(
			string memory _name,
			string memory _symbol,
			address _safe,
			address[] memory _members,
			address[] memory _extensions,
			uint32[4] memory _govSettings
		) = abi.decode(
				_initializationParams,
				(string, string, address, address[], address[], uint32[4])
			);

		// Initialize ownership and transfer immediately to avatar
		// Ownable Init reverts if already initialized
		// TODO consider owner being safe
		__Ownable_init();
		transferOwnership(_safe);

		/// SETUP GNOSIS MODULE ///
		avatar = _safe;
		target = _safe; /*Set target to same address as avatar on setup - can be changed later via setTarget, though probably not a good idea*/

		/// SETUP FORUM GOVERNANCE ///
		if (_govSettings[0] == 0 || _govSettings[0] > 365 days) revert PeriodBounds();

		if (_govSettings[1] > 100 || _govSettings[1] < _members.length)
			revert MemberLimitExceeded();

		if (_govSettings[2] < 1 || _govSettings[2] > 100) revert VoteThresholdBounds();

		if (_govSettings[3] < 1 || _govSettings[3] > 100) revert VoteThresholdBounds();

		ForumGovernance._init(_name, _symbol, _members);

		// Set the pfpSetter - determines uri of group token
		pfpExtension = _extensions[0];

		// Set the remaining base extensions (fundriase, withdrawal, + any custom extensions beyond that)
		// Cannot realistically overflow on human timescales
		unchecked {
			for (uint256 i = 1; i < _extensions.length; i++) {
				extensions[_extensions[i]] = true;
			}
		}

		memberCount = _members.length;

		votingPeriod = _govSettings[0];

		memberLimit = _govSettings[1];

		memberVoteThreshold = _govSettings[2];

		tokenVoteThreshold = _govSettings[3];

		/// ALL PROPOSAL TYPES DEFAULT TO MEMBER VOTES ///
	}

	/// ----------------------------------------------------------------------------------------
	///							PROPOSAL LOGIC
	/// ----------------------------------------------------------------------------------------

	/**
	 * @notice Get the proposal details for a given proposal
	 * @param proposal Index of the proposal
	 */
	function getProposalArrays(
		uint256 proposal
	)
		public
		view
		virtual
		returns (address[] memory accounts, uint256[] memory amounts, bytes[] memory payloads)
	{
		Proposal storage prop = proposals[proposal];

		(accounts, amounts, payloads) = (prop.accounts, prop.amounts, prop.payloads);
	}

	/**
	 * @notice Make a proposal to the group
	 * @param proposalType type of proposal
	 * @param accounts target accounts
	 * @param amounts to be sent
	 * @param payloads for target accounts
	 * @return proposal index of the created proposal
	 */
	function propose(
		ProposalType proposalType,
		address[] calldata accounts,
		uint256[] calldata amounts,
		bytes[] calldata payloads
	) public payable virtual nonReentrant returns (uint256 proposal) {
		if (accounts.length != amounts.length || amounts.length != payloads.length)
			revert NoArrayParity();

		if (proposalType == ProposalType.VPERIOD)
			if (amounts[0] == 0 || amounts[0] > 365 days) revert PeriodBounds();

		if (proposalType == ProposalType.MEMBER_LIMIT)
			if (amounts[0] > 100 || amounts[0] < memberCount) revert MemberLimitExceeded();

		if (
			proposalType == ProposalType.MEMBER_THRESHOLD ||
			proposalType == ProposalType.TOKEN_THRESHOLD
		)
			if (amounts[0] == 0 || amounts[0] > 100) revert VoteThresholdBounds();

		if (proposalType == ProposalType.TYPE)
			if (amounts[0] > 13 || amounts[1] > 2 || amounts.length != 2) revert TypeBounds();

		if (proposalType == ProposalType.MINT)
			if ((memberCount + accounts.length) > memberLimit) revert MemberLimitExceeded();

		// Cannot realistically overflow on human timescales
		unchecked {
			++proposalCount;
		}

		proposal = proposalCount;

		proposals[proposal] = Proposal({
			proposalType: proposalType,
			accounts: accounts,
			amounts: amounts,
			payloads: payloads,
			creationTime: _safeCastTo32(block.timestamp)
		});

		emit NewProposal(msg.sender, proposal, proposalType, accounts, amounts, payloads);
	}

	/**
	 * @notice Process a proposal
	 * @param proposal index of proposal
	 * @param signatures array of sigs of members who have voted for the proposal
	 * @return didProposalPass check if proposal passed
	 * @return results from any calls
	 * @dev signatures must be in ascending order
	 */
	function processProposal(
		uint256 proposal,
		Signature[] calldata signatures
	) public payable virtual nonReentrant returns (bool didProposalPass, bytes[] memory results) {
		Proposal storage prop = proposals[proposal];

		VoteType voteType = proposalVoteTypes[prop.proposalType];

		if (prop.creationTime == 0) revert NotCurrentProposal();

		uint256 votes;

		bytes32 digest = keccak256(
			abi.encodePacked(
				'\x19\x01',
				DOMAIN_SEPARATOR(),
				keccak256(abi.encode(PROPOSAL_HASH, proposal))
			)
		);

		// We keep track of the previous signer in the array to ensure there are no duplicates
		address prevSigner;

		// For each sig we check the recovered signer is a valid member and count thier vote
		for (uint256 i; i < signatures.length; ) {
			// Recover the signer
			address recoveredSigner = ecrecover(
				digest,
				signatures[i].v,
				signatures[i].r,
				signatures[i].s
			);

			// If not a member, or the signer is out of order (used to prevent duplicates), revert
			if (balanceOf[recoveredSigner][MEMBERSHIP] == 0 || prevSigner >= recoveredSigner)
				revert SignatureError();

			// If the signer has not delegated their vote, we count, otherwise we skip
			if (memberDelegatee[recoveredSigner] == address(0)) {
				// If member vote we increment by 1 (for the signer) + the number of members who have delegated to the signer
				// Else we calculate the number of votes based on share of the treasury
				if (voteType == VoteType.MEMBER)
					votes += 1 + EnumerableSet.length(memberDelegators[recoveredSigner]);
				else {
					uint256 len = EnumerableSet.length(memberDelegators[recoveredSigner]);
					// Add the number of votes the signer holds
					votes += balanceOf[recoveredSigner][TOKEN];
					// If the signer has been delegated too,check the balances of anyone who has delegated to the current signer
					if (len != 0)
						for (uint256 j; j < len; ) {
							votes += balanceOf[
								EnumerableSet.at(memberDelegators[recoveredSigner], j)
							][TOKEN];
							++j;
						}
				}
			}

			++i;
			prevSigner = recoveredSigner;
		}

		didProposalPass = _countVotes(voteType, votes);

		if (didProposalPass) {
			// Cannot realistically overflow on human timescales
			unchecked {
				if (prop.proposalType == ProposalType.MINT)
					for (uint256 i; i < prop.accounts.length; ) {
						// Only mint membership token if the account is not already a member
						if (balanceOf[prop.accounts[i]][MEMBERSHIP] == 0)
							_mint(prop.accounts[i], MEMBERSHIP, 1, '');
						_mint(prop.accounts[i], TOKEN, prop.amounts[i], '');
						++i;
					}

				if (prop.proposalType == ProposalType.BURN)
					for (uint256 i; i < prop.accounts.length; ) {
						_burn(prop.accounts[i], MEMBERSHIP, 1);
						_burn(prop.accounts[i], TOKEN, prop.amounts[i]);
						++i;
					}

				// TODO route all calls through exec() to safe
				if (prop.proposalType == ProposalType.CALL) {
					for (uint256 i; i < prop.accounts.length; i++) {
						results = new bytes[](prop.accounts.length);

						(bool successCall, bytes memory result) = prop.accounts[i].call{
							value: prop.amounts[i]
						}(prop.payloads[i]);

						if (!successCall) revert CallError();

						results[i] = result;
					}
				}

				// Governance settings
				if (prop.proposalType == ProposalType.VPERIOD)
					votingPeriod = uint32(prop.amounts[0]);

				if (prop.proposalType == ProposalType.MEMBER_LIMIT)
					memberLimit = uint32(prop.amounts[0]);

				if (prop.proposalType == ProposalType.MEMBER_THRESHOLD)
					memberVoteThreshold = uint32(prop.amounts[0]);

				if (prop.proposalType == ProposalType.TOKEN_THRESHOLD)
					tokenVoteThreshold = uint32(prop.amounts[0]);

				if (prop.proposalType == ProposalType.TYPE)
					proposalVoteTypes[ProposalType(prop.amounts[0])] = VoteType(prop.amounts[1]);

				if (prop.proposalType == ProposalType.PAUSE) _flipPause();

				if (prop.proposalType == ProposalType.EXTENSION)
					for (uint256 i; i < prop.accounts.length; i++) {
						if (prop.amounts[i] != 0)
							extensions[prop.accounts[i]] = !extensions[prop.accounts[i]];

						if (prop.payloads[i].length > 3) {
							IForumGroupExtension(prop.accounts[i]).setExtension(prop.payloads[i]);
						}
					}

				if (prop.proposalType == ProposalType.ESCAPE) delete proposals[prop.amounts[0]];

				if (prop.proposalType == ProposalType.DOCS) docs = string(prop.payloads[0]);

				// TODO should be converted to set hash on gnosis safe
				if (prop.proposalType == ProposalType.ALLOW_CONTRACT_SIG) {
					// This sets the allowance for EIP-1271 contract signature transactions on marketplaces
					for (uint256 i; i < prop.accounts.length; i++) {
						// set the sig on the gnosis safe
					}
				}

				emit ProposalProcessed(prop.proposalType, proposal, didProposalPass);

				// Delete proposal now that it has been processed
				delete proposals[proposal];
			}
		} else {
			// Only delete and update the proposal settings if there are not enough votes AND the time limit has passed
			// This prevents deleting proposals unfairly
			if (block.timestamp > prop.creationTime + votingPeriod) {
				emit ProposalProcessed(prop.proposalType, proposal, didProposalPass);

				delete proposals[proposal];
			}
		}
	}

	/**
	 * @notice Count votes on a proposal
	 * @param voteType voteType to count
	 * @param yesVotes number of votes for the proposal
	 * @return bool true if the proposal passed, false otherwise
	 */
	function _countVotes(VoteType voteType, uint256 yesVotes) internal view virtual returns (bool) {
		if (voteType == VoteType.MEMBER)
			if ((yesVotes * 100) / memberCount >= memberVoteThreshold) return true;

		if (voteType == VoteType.SIMPLE_MAJORITY)
			if (yesVotes > ((totalSupply * 50) / 100)) return true;

		if (voteType == VoteType.TOKEN_MAJORITY)
			if (yesVotes >= (totalSupply * tokenVoteThreshold) / 100) return true;

		return false;
	}

	/// ----------------------------------------------------------------------------------------
	///							EXTENSIONS
	/// ----------------------------------------------------------------------------------------

	modifier onlyExtension() {
		if (!extensions[msg.sender]) revert NotExtension();

		_;
	}

	/**
	 * @notice Interface to call an extension set by the group
	 * @param extension address of extension
	 * @param amount for extension
	 * @param extensionData data sent to extension to be decoded or used
	 * @return mint true if tokens are to be minted, false if to be burnt
	 * @return amountOut amount of token to mint/burn
	 */
	function callExtension(
		address extension,
		uint256 amount,
		bytes calldata extensionData
	) public payable virtual nonReentrant returns (bool mint, uint256 amountOut) {
		if (!extensions[extension]) revert NotExtension();

		(mint, amountOut) = IForumGroupExtension(extension).callExtension{value: msg.value}(
			msg.sender,
			amount,
			extensionData
		);

		if (mint) {
			if (amountOut != 0) _mint(msg.sender, TOKEN, amountOut, '');
		} else {
			if (amountOut != 0) _burn(msg.sender, TOKEN, amountOut);
		}
	}

	function mintShares(
		address to,
		uint256 id,
		uint256 amount
	) public payable virtual onlyExtension {
		_mint(to, id, amount, '');
	}

	function burnShares(
		address from,
		uint256 id,
		uint256 amount
	) public payable virtual onlyExtension {
		_burn(from, id, amount);
	}

	/// ----------------------------------------------------------------------------------------
	///							UTILITIES
	/// ----------------------------------------------------------------------------------------

	function uri(uint256 tokenId) public view override returns (string memory) {
		return IPfpStaker(pfpExtension).getUri(address(this), name, tokenId);
	}

	receive() external payable virtual {}
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

/// @notice ForumGroup membership extension interface.
/// @author modified from KaliDAO.
interface IForumGroupExtension {
	function setExtension(bytes calldata extensionData) external;

	function callExtension(
		address account,
		uint256 amount,
		bytes calldata extensionData
	) external payable returns (bool mint, uint256 amountOut);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

/// @notice ForumGroup interface for sharing types
interface IForumGroupTypes {
	enum ProposalType {
		MINT, // add membership
		BURN, // revoke membership
		CALL, // call contracts
		VPERIOD, // set `votingPeriod`
		MEMBER_LIMIT, // set `memberLimit`
		MEMBER_THRESHOLD, // set `memberVoteThreshold`
		TOKEN_THRESHOLD, // set `tokenVoteThreshold`
		TYPE, // set `VoteType` to `ProposalType`
		PAUSE, // flip membership transferability
		EXTENSION, // flip `extensions` whitelisting
		ESCAPE, // delete pending proposal in case of revert
		DOCS, // amend org docs
		ALLOW_CONTRACT_SIG // enable the contract to sign as an EOA
	}

	enum VoteType {
		MEMBER, // % of members required to pass
		SIMPLE_MAJORITY, // over 50% total votes required to pass
		TOKEN_MAJORITY // user set % of total votes required to pass
	}

	struct Proposal {
		ProposalType proposalType;
		address[] accounts; // member(s) being added/kicked; account(s) receiving payload
		uint256[] amounts; // value(s) to be minted/burned/spent; gov setting [0]
		bytes[] payloads; // data for CALL proposals
		uint32 creationTime; // timestamp of proposal creation
	}

	struct Signature {
		uint8 v;
		bytes32 r;
		bytes32 s;
	}
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

// PFP allows groups to stake an NFT to use as their pfp
interface IPfpStaker {
	function stakeNft(address, uint256) external;

	function getUri(address, string calldata, uint256) external view returns (string memory nftURI);

	function getStakedNft(address) external view returns (uint256 tokenId);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

/// @notice Receiver hook utility for NFT 'safe' transfers
/// @author Author KaliDAO (https://github.com/kalidao/kali-contracts/blob/main/contracts/utils/NFTreceiver.sol)
abstract contract NFTreceiver {
	function onERC721Received(
		address,
		address,
		uint256,
		bytes calldata
	) external pure returns (bytes4) {
		return 0x150b7a02;
	}

	function onERC1155Received(
		address,
		address,
		uint256,
		uint256,
		bytes calldata
	) external pure returns (bytes4) {
		return 0xf23a6e61;
	}

	function onERC1155BatchReceived(
		address,
		address,
		uint256[] calldata,
		uint256[] calldata,
		bytes calldata
	) external pure returns (bytes4) {
		return 0xbc197c81;
	}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

/// @notice Gas optimized reentrancy protection for smart contracts
/// @author Modified from KaliDAO (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    error Reentrancy();

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        //require(_status != _ENTERED, 'ReentrancyGuard: reentrant call');
        if (_status == _ENTERED) revert Reentrancy();

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}
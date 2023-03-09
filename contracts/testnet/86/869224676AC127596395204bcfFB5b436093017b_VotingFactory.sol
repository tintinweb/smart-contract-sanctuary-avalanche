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
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./VotingHandler.sol";

/**
 * @title VotingFactory
 * @author Nicolas Milliard
 * @notice Factory of the VotingHandler Smart Contract
 * @dev Everyone can create an instance of VotingHandler
 */
contract VotingFactory {
    /// @dev Store the instance model address of VotingHandler
    address immutable votingHandlerImplementation;

    /**
     * @notice Emitted when a new instance of VotingHandler has been created
     * @param _from The address of the caller
     * @param _contract The address where the new instance has been deployed
     */
    event NewInstance(address indexed _from, address indexed _contract);

    /**
     * @notice Create the instance model of VotingHandler
     * @dev Create the instance model of VotingHandler and store its address
     */
    constructor() {
        votingHandlerImplementation = address(new VotingHandler());
    }

    /**
     * @notice Create a new instance of VotingHandler and initialize it with the caller address
     * @dev The new instance is created using the Clones library from OpenZeppelin and the VotingHandler Smart Contract
     * @dev The initialize function of the VotingHandler Smart Contract is then called to set the owner of the new instance
     * @dev The address of the new instance is then emitted in the NewInstance event
     */
    function b_A6Q() external {
        address clone = Clones.clone(votingHandlerImplementation);
        VotingHandler(clone).initialize(msg.sender);

        emit NewInstance(msg.sender, clone);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

/**
 * @title Voting
 * @author Nicolas Milliard
 * @notice Voting system with simple majority including features like equality management, reset all proposals, reset session (all voters and all proposals) and avoid duplicate proposals.
 */
contract VotingHandler is Initializable, OwnableUpgradeable, PausableUpgradeable {
    /// @dev Store the id of the winning proposal after tallying votes
    uint winningProposalId;

    /// @notice Store the name of the voting instance
    string public votingSessionName;

    /// @dev Determine if voters can add proposals or not
    bool votersCanAddProposals;

    /// @dev Store the details of each voter in a mapping
    mapping (address => Voter) voters;

    /// @dev Store all votersAddress in an array
    address[] votersAddress;

    /// @dev Store all proposals in an array
    Proposal[] allProposals;

    /// @dev Store all equal proposals in an array
    Proposal[] equalProposals;

    /// @notice Store the current workflow status
    enum WorkflowStatus { RegisteringVoters, ProposalsRegistration, VotingSession, VotesTallied }
    WorkflowStatus public votingStatus;

    /// @dev Store voter's details
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    /// @dev Store proposal's details
    struct Proposal {
        string description;
        uint voteCount;
    }
    
    /**
     * @notice Emitted when the instance is paused
     * @param contractAddress Address of the current instance
     */
    event InstanceRemoved(address contractAddress);

    /**
     * @notice Emitted when the instance is renamed
     * @param contractAddress Address of the current instance
     */
    event InstanceRenamed(address indexed contractAddress);

    /**
     * @notice Emitted when a new voter is registered
     * @param voterAddress Address of the new voter
     */
    event VoterRegistered(address indexed voterAddress);

    /**
     * @notice Emitted when voters are allowed to add proposals
     * @param votersCanAddProposals Boolean which represents the authorization
     */
    event VotersAuthorizedToAddProposals(bool votersCanAddProposals);

    /**
     * @notice Emitted when the votingStatus is updated
     * @param previousStatus Represent the previous status
     * @param newStatus Represent the current status
     */
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);

    /**
     * @notice Emitted when a proposal is registered
     * @param proposalId Represent the id of the proposal registered
     */   
    event ProposalRegistered(uint proposalId);

    /**
     * @notice Emitted when a user has voted for a proposal
     * @param voter Address of the voter
     * @param proposalId Id of the voted proposal
     */
    event Voted(address indexed voter, uint proposalId);

    /**
     * @notice Emitted in cas of an equality
     * @param equalProposals Represent the array of all the equal proposals
     */
    event Equality(Proposal[] equalProposals);

    /// @notice Check if the address is whitelisted
    modifier checkVoter {
        require(voters[msg.sender].isRegistered, "0x01");
        _;
    }

    /**
     * @notice Transfer ownership to the address calling the function from VotingFactory
     * @dev VotingHandler is upgradeable so initialize is used instead of a constructor
     */
    function initialize(address _newOwner) external initializer {
        _transferOwnership(_newOwner);
    }

    /**
     * @notice Remove the current voting session (pause it definitively)
     * @dev Only the owner of the contract can call this function when the contract is not paused
     */
    function removeInstance() external onlyOwner whenNotPaused {
        _pause();

        emit InstanceRemoved(address(this));
    }

    /**
     * @notice Name or rename instance
     * @dev Only the owner of the contract can call this function when the contract is not paused
     * @param _votingSessionName is the new name of this instance
     */
    function renameInstance(string calldata _votingSessionName) external onlyOwner whenNotPaused {
        require(keccak256(abi.encode(_votingSessionName)) != keccak256(abi.encode(votingSessionName)) , "0x02");
        votingSessionName = _votingSessionName;

        emit InstanceRenamed(address(this));
    }

    /**
     * @notice Administrator add a voter to the whitelist. A voter can only be authorized once
     * @dev Only the owner of the contract can call this function when the contract is not paused
     * @dev Set isRegistered for the address to true and store this address in votersAddress array
     * @param _address is the address of the Voter who is added by the owner
     */
    function authorize(address _address) public onlyOwner whenNotPaused {
        require(votingStatus == WorkflowStatus.RegisteringVoters, "0x03");
        require(!voters[_address].isRegistered, "0x04");

        voters[_address].isRegistered = true;

        votersAddress.push(_address);

        emit VoterRegistered(_address);
    }

    /**
     * @notice Administrator add multiple voters to the whitelist. A voter can only be authorized once
     * @dev Only the owner of the contract can call this function when the contract is not paused
     * @dev Call authorized() for each value of the array
     * @param _addresses is the array of all addresses of voters who are added by the owner
     */
    function batchAuthorize(address[] calldata _addresses) external onlyOwner whenNotPaused {
        require(votingStatus == WorkflowStatus.RegisteringVoters, "0x03");

        uint length = _addresses.length;
        for(uint i; i < length;) {
            authorize(_addresses[i]);
            // Safely optimize gas cost (i can't be overflow)
            unchecked { i++; }
        }
    }

    /**
     * @notice By default, only Administrator can add proposals. This function allow Voters to add Proposals
     * @dev Only the owner of the contract can call this function when the contract is not paused
     * @param _votersCanAddProposals is used to determine if Voters can add Proposals
     */
    function authorizeVotersToAddProposals(bool _votersCanAddProposals) external onlyOwner whenNotPaused {
        require(votingStatus == WorkflowStatus.RegisteringVoters, "0x05");

        votersCanAddProposals = _votersCanAddProposals;

        emit VotersAuthorizedToAddProposals(votersCanAddProposals);
    }

    /**
     * @notice Administrator starts proposals registration session
     * @dev Only the owner of the contract can call this function when the contract is not paused
     */
    function startProposalsRegistration() external onlyOwner whenNotPaused {
        require(votingStatus == WorkflowStatus.RegisteringVoters, "0x06");
        updateWorkflow(WorkflowStatus.ProposalsRegistration);
    }

    /**
     * @notice Voters can register their proposal
     * @dev Everyone can call this function but only admin and allowed voters can add proposals
     * @dev checkProposals is called to check if this proposals wasn't already be added to allProposals array
     * @dev allProposals array is incremented at each new proposal so allProposals.length - 1 is equal to the index of the right proposal
     * @param _description is necessary to check if the proposal has already been register
     */
    function registerProposal(string calldata _description) external whenNotPaused {
        require(votingStatus == WorkflowStatus.ProposalsRegistration, "0x07");

        // If msg.sender is not the owner, we check votersCanAddProposals
        if(msg.sender != owner()) {
            require(votersCanAddProposals == true, "0x08");
        }

        Proposal memory proposal;
        proposal.description = _description;

        checkProposals(proposal.description);

        allProposals.push(proposal);
        
        emit ProposalRegistered(allProposals.length - 1);
    }

    /**
     * @notice Display all proposals for all voters
     * @dev Everyone can call this function
     * @return Proposal[] which contains description and voteCount for each proposal
     */
    function displayProposals() external whenNotPaused view returns(Proposal[] memory) {
        return allProposals;
    }

    /** 
     * @notice Administrator starts voting session
     * @dev Only the owner of the contract can call this function when the contract is not paused
     */
    function startVotingSession() external onlyOwner whenNotPaused {
        require(votingStatus == WorkflowStatus.ProposalsRegistration, "0x10");
        updateWorkflow(WorkflowStatus.VotingSession);
    }

    /**
     * @notice Voters can vote for their favorite proposal. A voter can only vote once
     * @dev Only voters can call this function. Voter's vote is registered (votedProposalId)
     * @dev voteCount of the _proposalId is increments by one
     * @param _proposalId is the id of the proposal selected by the Voter
     */
    function vote(uint _proposalId) external checkVoter whenNotPaused {
        require(votingStatus == WorkflowStatus.VotingSession, "0x11");
        require(!voters[msg.sender].hasVoted, "0x12");

        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedProposalId = _proposalId;

        // ++X costs less gas than X++
        ++allProposals[_proposalId].voteCount;

        emit Voted(msg.sender, _proposalId);
    }

    /**
     * @notice Administrator starts tally session
     * @dev Only the owner of the contract can call this function when the contract is not paused
     */
    function startTallySession() external onlyOwner whenNotPaused {
        require(votingStatus == WorkflowStatus.VotingSession, "0x14");
        updateWorkflow(WorkflowStatus.VotesTallied);
        
        /// @dev Automatically tally votes
        tallyVotes();
    }

    /** 
     * @notice Administrator tally votes
     * @dev Only the owner of the contract can call this function when the contract is not paused
     * @dev Call getHighestVoteCount function. Compare all voteCount of each proposals and store proposals with an equal voteCount in a new array (equalProposals)
     * @dev If there is no equality, winningProposalId is set
     */
    function tallyVotes() private {
        require(votingStatus == WorkflowStatus.VotesTallied, "0x15");
        
        uint highestNumber = getHighestVoteCount();

        uint allProposalsLength = allProposals.length;
        for(uint i; i < allProposalsLength;) {
            if(allProposals[i].voteCount == highestNumber) {
                winningProposalId = i;
                equalProposals.push(Proposal(allProposals[i].description, 0));
            }
            // Safely optimize gas cost (i can't be overflow)
            unchecked { i++; }
        }
        
        // If there is an equality: equalProposals.length must contains at least 2 proposals
        if(equalProposals.length > 1) {
            emit Equality(equalProposals);

            delete allProposals;

            /// @dev Save equalProposals into allProposals
            uint equalProposalsLength = equalProposals.length; 
            for(uint i; i < equalProposalsLength;) {
                allProposals.push(Proposal(equalProposals[i].description, 0));
                // Safely optimize gas cost (i can't be overflow)
                unchecked { i++; }
            }
            
            delete equalProposals;

            /// @dev Reset all hasVoted and votedProposalId for all voters
            uint votersAddressLength = votersAddress.length; 
            for(uint i; i < votersAddressLength;) {
                voters[votersAddress[i]].hasVoted = false;
                voters[votersAddress[i]].votedProposalId = 0;
                // Safely optimize gas cost (i can't be overflow)
                unchecked { i++; }
            }

            // Restart voting session with equal proposals         
            updateWorkflow(WorkflowStatus.VotingSession);
        }
    }

    /**
     * @notice A voter can check the vote of another voter
     * @dev Only voters can call this function
     * @dev Function revert if the target voter hasn't voted yet
     * @param _address is the address of a Voter to get his vote
     * @return votedProposalId
     */
    function getSpecificVote(address _address) external checkVoter whenNotPaused view returns(uint) {
        require(voters[_address].hasVoted == true, "0x16");

        return voters[_address].votedProposalId;
    }

    /**
     * @notice Everyone can check the winner's proposal details
     * @return winning proposal's description
     */
    function getWinner() external whenNotPaused view returns(string memory) {
        require(votingStatus == WorkflowStatus.VotesTallied, "0x17");
        return allProposals[winningProposalId].description;
    }

    /**
     * @notice Update the Workflow status
     * @param _newStatus is the next status of the WorkflowStatus
     */
    function updateWorkflow(WorkflowStatus _newStatus) private {
        WorkflowStatus previousStatus = votingStatus;
        votingStatus = _newStatus;

        emit WorkflowStatusChange(previousStatus, votingStatus);
    }

    /**
     * @dev Called by registerProposals. Revert if keccak256 of two descriptions are equal
     * @param _description is the description of a new proposal suggested by a Voter
     */
    function checkProposals(string memory _description) private view {
        uint allProposalsLength = allProposals.length; 
        for(uint i; i < allProposalsLength;) {
            require(keccak256(abi.encode(_description)) != keccak256(abi.encode(allProposals[i].description)), "0x18");
            // Safely optimize gas cost (i can't be overflow)
            unchecked { i++; }
        }
    }

    /**
     * @dev Called by tallyVotes
     * @return highestNumber voteCount number for a proposal
     */
    function getHighestVoteCount() private view returns(uint highestNumber) {
        uint allProposalsLength = allProposals.length; 
        for(uint i; i < allProposalsLength;) {
            if(allProposals[i].voteCount > highestNumber) {
                highestNumber = allProposals[i].voteCount;
            }
            // Safely optimize gas cost (i can't be overflow)
            unchecked { i++; }
        }
        return highestNumber;
    }
}
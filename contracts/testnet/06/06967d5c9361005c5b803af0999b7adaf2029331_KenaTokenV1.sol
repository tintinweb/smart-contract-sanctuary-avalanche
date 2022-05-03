/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-02
*/

// Sources flattened with hardhat v2.9.3 https://hardhat.org

// File libraries/SafeMath.sol



pragma solidity ^0.8.11;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {return a + b;}
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {return a - b;}
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {return a * b;}
    function div(uint256 a, uint256 b) internal pure returns (uint256) {return a / b;}
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {return a % b;}
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked { require(b <= a, errorMessage); return a - b; }
    }
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.2;

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


// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.2;

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


// File imports/Manageable.sol



pragma solidity ^0.8.11;



abstract contract Manageable is Initializable, ContextUpgradeable {
    using AddressUpgradeable for address;
    
    address private _manager;
    event ManagementTransferred(address indexed previousManager, address indexed newManager);
    function __Manageable_init() internal onlyInitializing {
        __Manageable_init_unchained();
    }

    function __Manageable_init_unchained() internal onlyInitializing {
        address msgSender = msg.sender;
        _manager = msgSender;
        emit ManagementTransferred(address(0), msgSender);
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    // constructor() initializer {}

    function manager() public view returns(address){ return _manager; }
    modifier onlyManager(){
        require(_manager == msg.sender, "Manageable: caller is not the manager");
        _;
    }
    function transferManagement(address newManager) external virtual onlyManager {
        emit ManagementTransferred(_manager, newManager);
        _manager = newManager;
    }
}


// File imports/Presaleable.sol



pragma solidity ^0.8.11;

abstract contract Presaleable is Manageable {
    bool internal isInPresale;

    function setPreseableEnabled(bool value) external onlyManager {
        isInPresale = value;
    }
}


// File imports/AntiScam.sol



pragma solidity ^0.8.11;



/**
* @dev Is used to enable a Anti Scam protection and deterance. 
*/

abstract contract AntiScam is Manageable {
    using SafeMath for uint256;
    using AddressUpgradeable for address;

    // Time before an approved number of tokens can be transfered using transferFrom()
    // Gives enough time to revoke the approval if its a accidental approval 
    // Protects from Scammers who may use approve as loop holes.
    // This is a Escrow Lock. The term Escrow is used in a 'functional' sense.
    // The Escrow is a 'third-party lock' held by Kena on behalf of accountHolder and spender.
    uint256 internal constant ALLOWANCE_TRANFER_EXPIRY = 24 hours; 

    mapping(address => mapping(address => uint256)) internal _allowancesCoolDownPeriod;
    mapping(address=>bool) internal isBlacklisted;

    modifier whenTransferEscrowCriteriaMet(address accountHolder, address spender) {
        require(block.timestamp > _allowancesCoolDownPeriod[accountHolder][spender], "AntiScam: Escrow lock period not yet expired.");
        _;
    }
  
    // function escrowTimeRemaining(address accountHolder, address spender) 
    // public view returns (uint256, uint256)
    // {
    //     return (block.timestamp, _allowancesCoolDownPeriod[accountHolder][spender]);
    // }

    /**
     *  BLACKLIST BAD ACTORS and SCAMMERS
     */
    function blacklistAddress(address _user, bool _isBad) public onlyManager {
        if(_isBad) {
            require(!isBlacklisted[_user], "user already blacklisted");
        } else {
            require(isBlacklisted[_user], "user already whitelisted");
        }
        isBlacklisted[_user] = _isBad;
        // emit events as well
    }    
}


// File imports/IERC20Vestable.sol



pragma solidity ^0.8.11;

interface IERC20Vestable {
    function getIntrinsicVestingSchedule(address grantHolder)
    external
    view
    returns (
        uint32 cliffDuration,
        uint32 vestDuration,
        uint32 vestIntervalDays
    );

    function grantVestingTokens(
        address beneficiary,
        uint256 totalAmount,
        uint256 vestingAmount,
        uint32 startDay,
        uint32 duration,
        uint32 cliffDuration,
        uint32 interval,
        bool isRevocable
    ) external returns (bool ok);

    function today() external view returns (uint32 dayNumber);

    function vestingForAccountAsOf(
        address grantHolder,
        uint32 onDayOrToday
    )
    external
    view
    returns (
        uint256 amountVested,
        uint256 amountNotVested,
        uint256 amountOfGrant,
        uint32 vestStartDay,
        uint32 cliffDuration,
        uint32 vestDuration,
        uint32 vestIntervalDays,
        bool isActive,
        bool wasRevoked
    );

    function vestingAsOf(uint32 onDayOrToday) external view returns (
        uint256 amountVested,
        uint256 amountNotVested,
        uint256 amountOfGrant,
        uint32 vestStartDay,
        uint32 cliffDuration,
        uint32 vestDuration,
        uint32 vestIntervalDays,
        bool isActive,
        bool wasRevoked
    );

    function revokeGrant(address grantHolder, uint32 onDay) external returns (bool);


    event VestingScheduleCreated(
        address indexed vestingLocation,
        uint32 cliffDuration, uint32 indexed duration, uint32 interval,
        bool indexed isRevocable);

    event VestingTokensGranted(
        address indexed beneficiary,
        uint256 indexed vestingAmount,
        uint32 startDay,
        address vestingLocation,
        address indexed grantor);

    event GrantRevoked(address indexed grantHolder, uint32 indexed onDay);
}


// File @openzeppelin/contracts-upgradeable/token/ERC20/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.2;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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


// File @openzeppelin/contracts-upgradeable/token/ERC20/extensions/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.2;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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


// File @openzeppelin/contracts-upgradeable/interfaces/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.2;

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

pragma solidity ^0.8.2;

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

pragma solidity ^0.8.2;

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
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
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
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
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
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
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
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
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
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

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
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
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
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
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

pragma solidity ^0.8.2;



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
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/access/[email protected]


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.2;


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


// File imports/KenaTokenomics.sol



pragma solidity ^0.8.11;

/**
 * @dev KenaTokenomics is the main template.
 * Used for fee distribution to the community.
 * Built as a upgrdeable smart contract.
 * Upgradeability allows fixing bugs, shaping features,
 * tuning incentives as we grow.
 *
 * Kena Official Site           https://kena.ai
 * Token Name and Symbol        KENA
 * Token Contract Class         KenaTokenV1 (First Version)
 * Total Supply                 ONE TRILLION.
 * Token Type                   ERC20
 * Burn Address                 0xDeADCafe00000000000000000000000662607015
 * Contract Type                EIP1822 (UUPS Upgradeable).
 * Pausable for Emergency       True.
 * Ownership Renounced?         False. (Cannot Renounce Ownership for Upgradeable contracts).
 * Peer-To-Peer Network Fee     1%
 * On-Ramp Network Fee (Buy)    5%
 * Off-Ramp Network Fee (Sell)  7%
 * Off-Ramp Burn (Sell)         3% (Economic Stability)
 * Transaction Cap              0.5% of total supply.
 * Wallet Cap                   4% of total supply.
 * AntiWhale Sale Trigger       0.10% of total supply.
 * AntiWhale Sale Penalty       5% Additional (Total 12%)
 * Buy-Sell Latency             1 hour cooldown.
 * Sell-Spread Latency          15 mins cooldown. Doubles every transaction. Resets after 24 hours.
 * AntiScam Allowance Escrow    24 hours lock before allowance can be used.
 */

// Copyright Attribution.
// EIP Upgradeability Templates are inherited from OpenZeppelin project.
// The RFI Calcultations is a modification of SafeToken contract.
// All license is covered under MIT License.



// Open Zeppelin libraries for controlling upgradability and access.







abstract contract KenaTokenomics is
    Initializable,
    ContextUpgradeable,
    IERC20Upgradeable,
    IERC20MetadataUpgradeable,
    IERC20Vestable,
    Presaleable,
    AntiScam,
    UUPSUpgradeable,
    OwnableUpgradeable
{
    using SafeMath for uint256;
    using AddressUpgradeable for address;

    // --------------------- Token ------------------- //
    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_)
        internal
        onlyInitializing
    {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_)
        internal
        onlyInitializing
    {
        _name = name_;
        _symbol = symbol_;
    }

    // --------------------- Operational Constants ------------------- //
    uint16 internal constant FEES_DIVISOR = 10**3;
    uint8 internal constant DECIMALS = 18;
    uint256 private constant MAX = ~uint256(0);

    // --------------------- Supply ------------------- //
    uint256 internal constant TOTAL_SUPPLY = 10**DECIMALS * 10**12;

    // --------------------- Economic Protection ------------------- //
    // 1% RFI as Transaction Fee (For peer-to-peer)
    uint256 internal constant PEER_TO_PEER_NETWORK_FEE = 10;
    // 5% RFI as on-ramp Fee (Buy)
    uint256 internal constant ON_RAMP_NETWORK_FEE = 50;
    // 7% RFI as off-Ramp Fee (Sell)
    uint256 internal constant OFF_RAMP_NETWORK_FEE = 70;
    // 3% Burn as off-ramp Inflation Protection (Sell)
    uint256 internal constant BURN_FEE = 30;
    // 5% additional RFI as Anti-Whale sale penalty for large dumps
    // (total 12% off-ramp Fee for Whales + 3% Burn)
    uint256 internal constant ANTI_WHALE_SALE_PENALTY_FEE = 50;

    // Maximimum allowed per transaction: capped at 0.5% of the total supply
    uint256 internal constant MAX_TRANSACTION_AMOUNT = TOTAL_SUPPLY / 200;
    // Maximum allowed per wallet: 4% of the total supply
    uint256 internal constant MAX_WALLET_BALANCE = TOTAL_SUPPLY / 25;
    // Anti-Whale sale triggers when 0.1% or more (of total supply) tokens gets dumped.
    // (thats a billion token sale per transaction)
    uint256 internal constant ANTI_WHALE_SALE_TRIGGER = TOTAL_SUPPLY / 1000;

    // --------------------- Burn Settings ------------------- //
    /**  @dev Vanity burn address specific to Kena.
     * Kena uses a vanity burn address as against a zero burn address 
     * so that it's easier to recognize the wallet address in transactions.
     * The probability of anyone randomly getting the private key for this is
     * address is ridiculously infinitesimal.
     * Even if that probability materializes, this address is locked completely on Kena.
     * The key holder CANNOT operate this account for buy/sell, allowance, grants, voiting.
     * This is a completely safe vanity address that burns all coins for eternity.
     * The the last few numbers is the Planck's constant. If you know, you know ;)
     */
    address internal constant BURN_ADDRESS = 0xDeADCafe00000000000000000000000662607015;

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account, bool status);
    bool private _paused;

    // Private storage -----
    mapping(address => uint256) private _reflectedBalances;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedFromReflections;
    address[] private _excluded;

    mapping(address => bool) internal isLiquidityPool;
    event LiquidityPoolEvent(address account, string message);

    string private _name;
    string private _symbol;

    // Used as a alternate reflected supply reserve to circumvent the need to loop through
    // every stored address within the contract to allocated Reflections.
    uint256 internal _reflectedSupply;

    enum FeeType {
        PeerToPeerNetworkFee,
        OnRampNetworkFee,
        OffRampNetworkFee,
        Burn,
        AntiWhaleDumpPenalty
    }
    struct Fee {
        FeeType feeType;
        uint256 value;
        address recipient;
        uint256 total;
    }

    Fee[] internal fees;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    ///@dev required by the OZ UUPS module
    function _authorizeUpgrade(address) internal override onlyOwner {}

    function initialize() public virtual initializer {
        _paused = false;

        _reflectedSupply = (MAX - (MAX % TOTAL_SUPPLY));
        _reflectedBalances[owner()] = _reflectedSupply;

        // exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        // exclude the owner and this contract from rewards
        _exclude(owner());
        _exclude(address(this));
        _exclude(BURN_ADDRESS);
        _addFees();

        ///@dev as there is no constructor, we need to initialise the OwnableUpgradeable explicitly
        __Ownable_init();
        __Manageable_init();
        __UUPSUpgradeable_init();
        emit Transfer(address(0), owner(), TOTAL_SUPPLY);
    }

    /** @dev 
    * Modifier to check KenaTokenomics rules prior to tranfer or allowance 
    */ 
    modifier whenTokenomicsCriteriaMet(
        address sender,
        address recipient,
        uint256 amount
    ) {
        require(
            _isAddressSafe(sender) && recipient != address(0),
            "Transfer is zero/burn address"
        );

        require(amount > 0, "Transfer must be > than zero");
        require(amount <= balanceOf(sender), "Insufficient funds.");
        
        require(!isBlacklisted[sender], "Sender is backlisted");
        require(!isBlacklisted[recipient], "Recipient is backlisted");

        if (!isInPresale) {
            if (
                amount > MAX_TRANSACTION_AMOUNT &&
                !_isUnlimitedSender(sender) &&
                !_isUnlimitedRecipient(recipient)
            ) {
                revert("Tokens exceed 0.25% of total supply.");
            }
            if (
                MAX_WALLET_BALANCE > 0 &&
                !_isUnlimitedSender(sender) &&
                !_isUnlimitedRecipient(recipient) &&
                !isLiquidityPool[recipient]
            ) {
                uint256 recipientBalance = balanceOf(recipient);
                require(
                    recipientBalance + amount <= MAX_WALLET_BALANCE,
                    "Receiver's wallet will exceed 4% of total Kena supply."
                );
            }
        }
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause(bool paused_) public virtual onlyOwner {
        _paused = paused_;
        emit Paused(_msgSender(), paused_);
    }

    /**
     *  Register Liquidity Pool Address
     */
    function registerLiquidityPool(address _lp) public onlyManager {
        require(
            !isLiquidityPool[_lp],
            "Liquidity pool address already registered."
        );
        isLiquidityPool[_lp] = true;
        _exclude(_lp);
        // emit events as well
        emit LiquidityPoolEvent(_lp, "Registered Liquidity Pool Address");
    }

    /**
     *  De-Register Liquidity Pool Address
     */
    function removeLiquidityPool(address _lp) public onlyManager {
        require(
            isLiquidityPool[_lp],
            "Liquidity pool address already removed."
        );
        isLiquidityPool[_lp] = false;
        _include(_lp);
        emit LiquidityPoolEvent(_lp, "Removed Liquidity Pool Address");
    }

    function _addFee(
        FeeType feeType,
        uint256 value,
        address recipient
    ) private {
        fees.push(Fee(feeType, value, recipient, 0));
        // sumOfFees += value; DO NOT ADD UP ALL FEE HERE. Instead make the decesion in _getSumOfFees()
    }

    function _addFees() internal {
        // Peer-To-Peer Network Fee as RFI (Only on transfers. Not on Buy or Sell)
        _addFee(
            FeeType.PeerToPeerNetworkFee,
            PEER_TO_PEER_NETWORK_FEE,
            address(this)
        );
        // On-Ramp Network Fee as RFI. During Buy.
        _addFee(FeeType.OnRampNetworkFee, ON_RAMP_NETWORK_FEE, address(this));
        // Off-Ramp Network Fee as RFI. During Sell.
        _addFee(FeeType.OffRampNetworkFee, OFF_RAMP_NETWORK_FEE, address(this));
        // Whale Penalty distrubuted to Network (This triggers only for higher sale numbers)
        _addFee(
            FeeType.AntiWhaleDumpPenalty,
            ANTI_WHALE_SALE_PENALTY_FEE,
            address(this)
        );
        // Burn for inflation adjustment
        _addFee(FeeType.Burn, BURN_FEE, BURN_ADDRESS);
    }

    function _getFeesCount() internal view returns (uint256) {
        return fees.length;
    }

    function _getFeeStruct(uint256 index) private view returns (Fee storage) {
        require(
            index >= 0 && index < fees.length,
            "FeesSettings._getFeeStruct: Fee index out of bounds"
        );
        return fees[index];
    }

    function _getFee(uint256 index)
        internal
        view
        returns (
            FeeType,
            uint256,
            address,
            uint256
        )
    {
        Fee memory fee = _getFeeStruct(index);
        return (fee.feeType, fee.value, fee.recipient, fee.total);
    }

    function _addFeeCollectedAmount(uint256 index, uint256 amount) internal {
        Fee storage fee = _getFeeStruct(index);
        fee.total = fee.total.add(amount);
    }

    /** Functions required by IERC20Metadata **/
    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public pure override returns (uint8) {
        return DECIMALS;
    }

    /** Functions required by IERC20Metadata - END **/
    /** Functions required by IERC20 **/
    function totalSupply() public pure override returns (uint256) {
        return TOTAL_SUPPLY;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcludedFromReflections[account]) return _balances[account];
        return tokenFromReflection(_reflectedBalances[account]);
    }

    function _getTransactionType(
        address sender,
        address recipient,
        uint256 amount
    )
        internal
        view
        returns (
            bool,
            bool,
            bool,
            bool
        )
    {
        // Assume the default is a tranfer
        bool _isPeerToPeer = true;
        bool _isSale = false;
        bool _isBuy = false;
        bool _isWhaleSale = false;

        if (isLiquidityPool[sender]) {
            // Check to see if this is a Buy
            _isBuy = true;
            _isPeerToPeer = false;
            _isSale = false;
        } else if (isLiquidityPool[recipient]) {
            // Check to see if this is a Sell
            _isSale = true;
            _isBuy = false;
            _isPeerToPeer = false;
            // Separately Check to see if there is a Anti Whale Penalty for a large dump.
            if (amount > ANTI_WHALE_SALE_TRIGGER) {
                _isWhaleSale = true;
            }
        }
        return (_isPeerToPeer, _isSale, _isBuy, _isWhaleSale);
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount, false);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            recipient,
            _allowances[sender][recipient].sub(
                amount,
                "KenaTokenomics: transfer amount exceeds allowance"
            ),
            true
        );
        return true;
    }

    /**
     * @dev This is "soft" burn (total supply is not reduced). RFI holders
     * get two benefits from burning tokens:
     */
    function burn(uint256 amount) external {
        address sender = _msgSender();
        require(_isAddressSafe(sender), "NetworkFee: zero/burn address");

        uint256 balance = balanceOf(sender);
        require(balance >= amount, "NetworkFee: amount > balance");

        uint256 reflectedAmount = amount.mul(_getCurrentRate());

        // remove the amount from the sender's balance first
        _reflectedBalances[sender] = _reflectedBalances[sender].sub(
            reflectedAmount
        );
        if (_isExcludedFromReflections[sender])
            _balances[sender] = _balances[sender].sub(amount);

        _burnTokens(sender, amount, reflectedAmount);
    }

    /**
     * @dev "Soft" burns the specified amount of tokens by sending them
     * to the burn address
     */
    function _burnTokens(
        address sender,
        uint256 tBurn,
        uint256 rBurn
    ) internal {
        /**
         * @dev Do not reduce _totalSupply and/or _reflectedSupply. (soft) burning by sending
         * tokens to the burn address (which should be excluded from rewards) is sufficient
         * in RFI
         */
        _reflectedBalances[BURN_ADDRESS] = _reflectedBalances[BURN_ADDRESS].add(
            rBurn
        );
        if (_isExcludedFromReflections[BURN_ADDRESS])
            _balances[BURN_ADDRESS] = _balances[BURN_ADDRESS].add(tBurn);

        // Typically for hardburn we need a _totalSupply which is not a constant
        // _totalSupply -= amount; // HARD BURN

        /**
         *  Emit the event so that the burn address balance is updated
         */
        emit Transfer(sender, BURN_ADDRESS, tBurn);
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue),
            false
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "KenaTokenomics: decreased allowance below zero"
            ),
            false
        );
        return true;
    }

    function isExcludedFromReflections(address account)
        external
        view
        returns (bool)
    {
        return _isExcludedFromReflections[account];
    }

    /**
     * @dev Calculates and returns the amount of tokens corresponding to the given reflected amount.
     */
    function tokenFromReflection(uint256 rAmount)
        internal
        view
        returns (uint256)
    {
        require(
            rAmount <= _reflectedSupply,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getCurrentRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReflections(address account) external onlyOwner {
        require(!_isExcludedFromReflections[account], "Account is not included");
        _exclude(account);
    }

    function _exclude(address account) internal {
        if (_reflectedBalances[account] > 0) {
            _balances[account] = tokenFromReflection(
                _reflectedBalances[account]
            );
        }
        _isExcludedFromReflections[account] = true;
        _excluded.push(account);
    }

    function includeInReflections(address account) external onlyOwner {
        require(_isExcludedFromReflections[account], "Account is not excluded");
        _include(account);
    }

    function _include(address account) internal {
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _balances[account] = 0;
                _isExcludedFromReflections[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function setExcludedFromFee(address account, bool value)
        external
        onlyOwner
    {
        _isExcludedFromFee[account] = value;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(
        address accountHolder,
        address spender,
        uint256 amount,
        bool isOverrideEscrow
    ) internal {
        require(
            accountHolder != address(0),
            "NetworkFee: approve from the zero address"
        );
        require(
            spender != address(0),
            "NetworkFee: approve to the zero address"
        );

        _allowances[accountHolder][spender] = amount;

        // Do not apply Escrow for owners and managers. (revoke can fit here)
        if (spender != owner() && spender != manager() && !isOverrideEscrow) {
            // ALLOWANCE_TRANFER_EXPIRY will delay the transferFrom 
            // fuction to immediately expend the coins before expiry.
            _allowancesCoolDownPeriod[accountHolder][
                spender
            ] = ALLOWANCE_TRANFER_EXPIRY.add(block.timestamp);
        } else {
            // No cool down for owner or manager (or when EscrowOverride)
            _allowancesCoolDownPeriod[accountHolder][spender] = 0;
        }
                
        emit Approval(accountHolder, spender, amount);
    }

    /**
     */
    function _isUnlimitedSender(address account) internal view returns (bool) {
        // the owner or liquidity pool should be the only whitelisted sender
        return (account == owner());
    }

    /**
     */
    function _isUnlimitedRecipient(address account)
        internal
        view
        returns (bool)
    {
        // the owner should be a white-listed recipient
        // and anyone should be able to burn as many tokens as
        // he/she wants
        return (account == owner() || account == BURN_ADDRESS);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        // indicates whether or not fee should be deducted from the transfer
        bool takeFee = true;
        if (
            isInPresale ||
            _isExcludedFromFee[sender] ||
            _isExcludedFromFee[recipient]
        ) {
            takeFee = false;
        }
        _transferTokens(sender, recipient, amount, takeFee);
    }

    function _transferTokens(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        // Compute the sum of all fees to calculate the % of the total transaction amount.
        uint256 sumOfFees = _getSumOfFees(sender, recipient, amount);

        if (!takeFee) {
            sumOfFees = 0;
        }

        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 tAmount,
            uint256 tTransferAmount,
            uint256 currentRate
        ) = _getValues(amount, sumOfFees);

        /**
         * Sender's and Recipient's reflected balances must be always updated regardless of
         * whether they are excluded from rewards or not.
         */
        _reflectedBalances[sender] = _reflectedBalances[sender].sub(rAmount);
        _reflectedBalances[recipient] = _reflectedBalances[recipient].add(
            rTransferAmount
        );

        /**
         * Update the true/nominal balances for excluded accounts
         */
        if (_isExcludedFromReflections[sender]) {
            _balances[sender] = _balances[sender].sub(tAmount);
        }
        if (_isExcludedFromReflections[recipient]) {
            _balances[recipient] = _balances[recipient].add(tTransferAmount);
        }

        _takeFees(sender, recipient, amount, currentRate, sumOfFees);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeFees(
        address sender,
        address recipient,
        uint256 amount,
        uint256 currentRate,
        uint256 sumOfFees
    ) private {
        if (sumOfFees > 0 && !isInPresale) {
            _takeTransactionFees(sender, recipient, amount, currentRate);
        }
    }

    function _getValues(uint256 tAmount, uint256 feesSum)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tTotalFees = tAmount.mul(feesSum).div(FEES_DIVISOR);
        uint256 tTransferAmount = tAmount.sub(tTotalFees);
        uint256 currentRate = _getCurrentRate();
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rTotalFees = tTotalFees.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rTotalFees);

        return (
            rAmount,
            rTransferAmount,
            tAmount,
            tTransferAmount,
            currentRate
        );
    }

    function _getCurrentRate() internal view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() internal view returns (uint256, uint256) {
        uint256 rSupply = _reflectedSupply;
        uint256 tSupply = TOTAL_SUPPLY;

        /**
         * The code below removes balances of addresses excluded from rewards from
         * rSupply and tSupply, which effectively increases the % of transaction fees
         * delivered to non-excluded holders
         */
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _reflectedBalances[_excluded[i]] > rSupply ||
                _balances[_excluded[i]] > tSupply
            ) return (_reflectedSupply, TOTAL_SUPPLY);
            rSupply = rSupply.sub(_reflectedBalances[_excluded[i]]);
            tSupply = tSupply.sub(_balances[_excluded[i]]);
        }
        if (tSupply == 0 || rSupply < _reflectedSupply.div(TOTAL_SUPPLY))
            return (_reflectedSupply, TOTAL_SUPPLY);
        return (rSupply, tSupply);
    }

    /**
     * @dev Returns the total sum of fees to be processed in each transaction.
     *
     * To separate concerns this contract (class) will take care of ONLY handling RFI, i.e.
     * changing the rates and updating the holder's balance (via `_redistribute`).
     * It is the responsibility of the dev/user to handle all other fees and taxes
     * in the appropriate contracts (classes).
     */
    function _getSumOfFees(
        address sender,
        address recipient,
        uint256 amount
    ) internal view virtual returns (uint256);

    /**
     * @dev Redistributes the specified amount among the current holders via the reflect.finance
     * algorithm, i.e. by updating the _reflectedSupply (_rSupply) which ultimately adjusts the
     * current rate used by `tokenFromReflection` and, in turn, the value returns from `balanceOf`.
     * This is the bit of clever math which allows rfi to redistribute the fee without
     * having to iterate through all holders.
     *
     */
    function _redistribute(
        uint256 amount,
        uint256 currentRate,
        uint256 fee,
        uint256 index
    ) internal {
        uint256 tFee = amount.mul(fee).div(FEES_DIVISOR);
        uint256 rFee = tFee.mul(currentRate);

        _reflectedSupply = _reflectedSupply.sub(rFee);
        _addFeeCollectedAmount(index, tFee);
    }

    /**
     *  Hook that is called before the `Transfer` event is emitted if fees are enabled for the transfer
     */
    function _takeTransactionFees(
        address sender,
        address recipient,
        uint256 amount,
        uint256 currentRate
    ) internal virtual;

    function _isAddressSafe(address account) internal virtual returns (bool) {
        return (account != address(0) && account != BURN_ADDRESS);
    }

}


// File libraries/Roles.sol

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */



pragma solidity ^0.8.11;

library Roles {
  using AddressUpgradeable for address;
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev give an account access to this role
   */
  function add(Role storage role, address account) internal {
    require(account != address(0));
    require(!has(role, account));

    role.bearer[account] = true;
  }

  /**
   * @dev remove an account's access to this role
   */
  function remove(Role storage role, address account) internal {
    require(account != address(0));
    require(has(role, account));

    role.bearer[account] = false;
  }

  /**
   * @dev check if an account has this role
   * @return bool
   */
  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0));
    return role.bearer[account];
  }
}


// File imports/EconomicProtection.sol



pragma solidity ^0.8.11;


/**
 * @dev Is used to enable a Economic protection and deterance.
 * a) Unlimited buy transactions are allowed.
 * b) Sell has 2 protections. (Restricted to Maximum of around 7 sales in 24 hours.)
 *   1) There is a buy-sell protection of 1 hour between Buy and Sell.
 *   This helps from bots/dumpers manipulating a buy and immediately selling the token post buy.
 *   2) There is a 'sell-spread' protection between subsequent sells within a 24 hour window.
 *       It's a quadratic delay that restricts you with 7 sales a day.
 *       First sell is delayed by 15 mins, and then its a twice the time of previous.
 *       If time elapsed is greater than 24hours it resets to 10 mins.
 */

abstract contract EconomicProtection is Manageable {
    using SafeMath for uint256;
    using AddressUpgradeable for address;

    uint256 private constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 private constant SECONDS_PER_HOUR = 60 * 60;
    uint256 private constant SECONDS_PER_MINUTE = 60;

    // Time between buy-sell
    uint256 internal constant buy_cool_down = 1 hours;
    // First Time between sell-sell (and then it increases quadrtically)
    uint256 internal constant sell_cool_down = 15 minutes;
    // Sell spread reset window
    uint256 internal constant sell_spread_reset_window = 24 hours;

    /*
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) private pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function timeLeft(uint256 timestamp)
        private
        pure
        returns (
            uint256 hour,
            uint256 minute,
            uint256 second
        )
    {
        // (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint256 secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    enum TransactionType {
        BUY,
        SELL
    }

    struct RecentTxRecord {
        bool exists;
        uint256 reset;
        uint256 expiry;
        uint256 multiple;
    }

    mapping(address => mapping(TransactionType => RecentTxRecord))
        private transactionCoolDownPeriod;

    function _isLiquidityPoolAddress(address account)
        internal
        virtual
        returns (bool);

    modifier whenEconomicProtectionCriteriaMet(
        address sender,
        address recipient,
        uint256 value
    ) {
        if (sender != manager() && recipient != manager()) {
            if (_isLiquidityPoolAddress(sender)) {
                // This is a BUY transaction
                // isBuyStructExists[recipient] = true;
                transactionCoolDownPeriod[recipient][
                    TransactionType.BUY
                ] = RecentTxRecord(
                    true,
                    block.timestamp,
                    buy_cool_down.add(block.timestamp),
                    1
                );
            } else if (_isLiquidityPoolAddress(recipient)) {
                // This is a SELL Transaction
                // 1) First check for snipe delay. (buy-sell latency)
                if (
                    transactionCoolDownPeriod[sender][TransactionType.BUY]
                        .exists
                ) {
                    (uint256 hour, uint256 minute, uint256 second) = timeLeft(
                        transactionCoolDownPeriod[sender][TransactionType.BUY]
                            .expiry
                            .sub(block.timestamp)
                    );

                    string memory _msgExp = string(
                        abi.encodePacked(
                            "Buy-Sell latency cooldown in ",
                            toString(hour),
                            ":",
                            toString(minute),
                            ":",
                            toString(second)
                        )
                    );
                    require(
                        block.timestamp >
                            transactionCoolDownPeriod[sender][
                                TransactionType.BUY
                            ].expiry,
                        _msgExp
                    );
                }

                // 2) Next, check for sell-spread. (sell-sell incremental latency with reset window)
                if (
                    transactionCoolDownPeriod[sender][TransactionType.SELL]
                        .exists
                ) {
                    if (
                        transactionCoolDownPeriod[sender][TransactionType.SELL]
                            .expiry > block.timestamp
                    ) {
                        (
                            uint256 hour,
                            uint256 minute,
                            uint256 second
                        ) = timeLeft(
                                transactionCoolDownPeriod[sender][
                                    TransactionType.SELL
                                ].expiry.sub(block.timestamp)
                            );

                        string memory _msgExp = string(
                            abi.encodePacked(
                                "Sell-Spread latency cooldown in ",
                                toString(hour),
                                ":",
                                toString(minute),
                                ":",
                                toString(second)
                            )
                        );
                        require(
                            block.timestamp >=
                                transactionCoolDownPeriod[sender][
                                    TransactionType.SELL
                                ].expiry,
                            _msgExp
                        );
                    }

                    // Post cooldown, allow a sale with updated struct
                    uint256 _newReset = transactionCoolDownPeriod[sender][
                        TransactionType.SELL
                    ].reset;
                    uint256 _newMultiple = sell_cool_down;

                    if (
                        block.timestamp >
                        transactionCoolDownPeriod[sender][TransactionType.SELL]
                            .reset
                    ) {
                        // RESET
                        _newReset = sell_spread_reset_window.add(
                            block.timestamp
                        );
                    } else {
                        // Quadratic increase (This doubles every time on sell untill reset)
                        uint256 _oldMultiple = transactionCoolDownPeriod[
                            sender
                        ][TransactionType.SELL].multiple;
                        _newMultiple = _oldMultiple.mul(2);
                    }
                    uint256 _newExpiry = _newMultiple.add(block.timestamp);
                    transactionCoolDownPeriod[sender][
                        TransactionType.SELL
                    ] = RecentTxRecord(
                        true,
                        _newReset,
                        _newExpiry,
                        _newMultiple
                    );
                } else if (
                    !transactionCoolDownPeriod[sender][TransactionType.SELL]
                        .exists
                ) {
                    // Allow first sale if SnipeDelay is taken care of.
                    transactionCoolDownPeriod[sender][
                        TransactionType.SELL
                    ] = RecentTxRecord(
                        true,
                        sell_spread_reset_window.add(block.timestamp),
                        sell_cool_down.add(block.timestamp),
                        sell_cool_down
                    );
                }
            }
        }
        _;
    }
}


// File imports/ERC20Vestable.sol



pragma solidity ^0.8.11;

// Copyright Attribution: 
// The Vestabiliy aspects in this contract is a modification of
// CPUCoin contract, which is a spin-off of mediarichio/ProxyToken.
// All license is covered under MIT License.




/**
 * @title Contract for grantable ERC20 token vesting schedules
 *
 * @notice Adds to an ERC20 support for grantor wallets, which are able to grant vesting tokens to
 *   beneficiary wallets, following per-wallet custom vesting schedules.
 *
 * @dev Contract which gives subclass contracts the ability to act as a pool of funds for allocating
 *   tokens to any number of other addresses. Token grants support the ability to vest over time in
 *   accordance a predefined vesting schedule. A given wallet can receive no more than one token grant.
 *
 *   Tokens are transferred from the pool to the recipient at the time of grant, but the recipient
 *   will only able to transfer tokens out of their wallet after they have vested. Transfers of non-
 *   vested tokens are prevented.
 *
 *   Two types of toke grants are supported:
 *   - Irrevocable grants, intended for use in cases when vesting tokens have been issued in exchange
 *     for value, such as with tokens that have been offered to Early Backers, Investors.
 *   - Revocable grants, intended for use in cases when vesting tokens have been gifted to the holder,
 *     such as with employee grants that are given as compensation.
 */
abstract contract ERC20Vestable is EconomicProtection, KenaTokenomics {
    using SafeMath for uint256;
    using AddressUpgradeable for address;
    bool private constant OWNER_UNIFORM_GRANTOR_FLAG = false;

    using Roles for Roles.Role;

    event GrantorAdded(address indexed account);
    event GrantorRemoved(address indexed account);

    Roles.Role private _grantors;
    mapping(address => bool) private _isUniformGrantor;

    function initialize()
        public
        virtual
        override
        initializer
    {
        super.initialize();
        _addGrantor(_msgSender(), OWNER_UNIFORM_GRANTOR_FLAG);
    }

    modifier onlyGrantor() {
        require(isGrantor(_msgSender()), "onlyGrantor");
        _;
    }

    modifier onlyGrantorOrSelf(address account) {
        require(
            isGrantor(_msgSender()) || _msgSender() == account, "onlyGrantorOrSelf");
        _;
    }

    function isGrantor(address account) public view returns (bool) {
        return _grantors.has(account) && !_isUniformGrantor[account];
    }

    function addGrantor(address account, bool isUniformGrantor_)
        public
        onlyManager
    {
        _addGrantor(account, isUniformGrantor_);
    }

    function removeGrantor(address account) public onlyManager {
        _removeGrantor(account);
    }

    function _addGrantor(address account, bool isUniformGrantor_) internal {
        require(_isAddressSafe(account), "Grantor is zero/burn address.");
        _grantors.add(account);
        _isUniformGrantor[account] = isUniformGrantor_;
        emit GrantorAdded(account);
    }

    function _removeGrantor(address account) private {
        require(_isAddressSafe(account), "Grantor is zero/burn address.");
        _grantors.remove(account);
        emit GrantorRemoved(account);
    }

    function isUniformGrantor(address account) public view returns (bool) {
        return _grantors.has(account) && _isUniformGrantor[account];
    }

    modifier onlyUniformGrantor() {
        require(isUniformGrantor(_msgSender()), "onlyUniformGrantor");
        // Only grantor role can do this.
        _;
    }

    // Date-related constants for sanity-checking dates to reject obvious erroneous inputs
    // and conversions from seconds to days and years that are more or less leap year-aware.
    uint32 private constant THOUSAND_YEARS_DAYS = 365243; /* See https://www.timeanddate.com/date/durationresult.html?m1=1&d1=1&y1=2000&m2=1&d2=1&y2=3000 */
    uint32 private constant TEN_YEARS_DAYS = THOUSAND_YEARS_DAYS / 100; /* Includes leap years (though it doesn't really matter) */
    uint32 private constant SECONDS_PER_DAY = 24 * 60 * 60; /* 86400 seconds in a day */
    uint32 private constant JAN_1_2000_SECONDS = 946684800; /* Saturday, January 1, 2000 0:00:00 (GMT) (see https://www.epochconverter.com/) */
    uint32 private constant JAN_1_2000_DAYS = JAN_1_2000_SECONDS / SECONDS_PER_DAY;
    uint32 private constant JAN_1_3000_DAYS = JAN_1_2000_DAYS + THOUSAND_YEARS_DAYS;

    struct vestingSchedule {
        bool isValid; /* true if an entry exists and is valid */
        bool isRevocable; /* true if the vesting option is revocable (a gift), false if irrevocable (purchased) */
        uint32 cliffDuration; /* Duration of the cliff, with respect to the grant start day, in days. */
        uint32 duration; /* Duration of the vesting schedule, with respect to the grant start day, in days. */
        uint32 interval; /* Duration in days of the vesting interval. */
    }

    struct tokenGrant {
        bool isActive; /* true if this vesting entry is active and in-effect entry. */
        bool wasRevoked; /* true if this vesting schedule was revoked. */
        uint32 startDay; /* Start day of the grant, in days since the UNIX epoch (start of day). */
        uint256 amount; /* Total number of tokens that vest. */
        address vestingLocation; /* Address of wallet that is holding the vesting schedule. */
        address grantor; /* Grantor that made the grant */
    }

    mapping(address => vestingSchedule) private _vestingSchedules;
    mapping(address => tokenGrant) private _tokenGrants;

    /**
     * @dev This one-time operation permanently establishes a vesting schedule in the given account.
     *
     * For standard grants, this establishes the vesting schedule in the beneficiary's account.
     * For uniform grants, this establishes the vesting schedule in the linked grantor's account.
     *
     * @param vestingLocation = Account into which to store the vesting schedule. Can be the account
     *   of the beneficiary (for one-off grants) or the account of the grantor (for uniform grants
     *   made from grant pools).
     * @param cliffDuration = Duration of the cliff, with respect to the grant start day, in days.
     * @param duration = Duration of the vesting schedule, with respect to the grant start day, in days.
     * @param interval = Number of days between vesting increases.
     * @param isRevocable = True if the grant can be revoked (i.e. was a gift) or false if it cannot
     *   be revoked (i.e. tokens were purchased).
     */
    function _setVestingSchedule(
        address vestingLocation,
        uint32 cliffDuration,
        uint32 duration,
        uint32 interval,
        bool isRevocable
    ) internal returns (bool ok) {
        // Check for a valid vesting schedule given (disallow absurd values to reject likely bad input).
        require(
            duration > 0 &&
                duration <= TEN_YEARS_DAYS &&
                cliffDuration < duration &&
                interval >= 1,
            "Invalid vesting schedule"
        );

        // Make sure the duration values are in harmony with interval (both should be an exact multiple of interval).
        require(
            duration % interval == 0 && cliffDuration % interval == 0,
            "Invalid cliff/duration for interval"
        );

        // Create and populate a vesting schedule.
        _vestingSchedules[vestingLocation] = vestingSchedule(
            true, /*isValid*/
            isRevocable,
            cliffDuration,
            duration,
            interval
        );

        // Emit the event and return success.
        emit VestingScheduleCreated(
            vestingLocation,
            cliffDuration,
            duration,
            interval,
            isRevocable
        );
        return true;
    }

    function _hasVestingSchedule(address account)
        internal
        view
        returns (bool ok)
    {
        return _vestingSchedules[account].isValid;
    }

    /**
     * @dev returns all information about the vesting schedule directly associated with the given
     * account. This can be used to double check that a uniform grantor has been set up with a
     * correct vesting schedule. Also, recipients of standard (non-uniform) grants can use this.
     * This method is only callable by the account holder or a grantor, so this is mainly intended
     * for administrative use.
     *
     * Holders of uniform grants must use vestingAsOf() to view their vesting schedule, as it is
     * stored in the grantor account.
     *
     * @param grantHolder = The address to do this for.
     *   the special value 0 to indicate today.
     * return = A tuple with the following values:
     *   vestDuration = grant duration in days.
     *   cliffDuration = duration of the cliff.
     *   vestIntervalDays = number of days between vesting periods.
     */
    function getIntrinsicVestingSchedule(address grantHolder)
        public
        view
        override
        onlyGrantorOrSelf(grantHolder)
        returns (
            uint32 vestDuration,
            uint32 cliffDuration,
            uint32 vestIntervalDays
        )
    {
        return (
            _vestingSchedules[grantHolder].duration,
            _vestingSchedules[grantHolder].cliffDuration,
            _vestingSchedules[grantHolder].interval
        );
    }

    /**
     * @dev Immediately grants tokens to an account, referencing a vesting schedule which may be
     * stored in the same account (individual/one-off) or in a different account (shared/uniform).
     *
     * @param beneficiary = Address to which tokens will be granted.
     * @param totalAmount = Total number of tokens to deposit into the account.
     * @param vestingAmount = Out of totalAmount, the number of tokens subject to vesting.
     * @param startDay = Start day of the grant's vesting schedule, in days since the UNIX epoch
     *   (start of day). The startDay may be given as a date in the future or in the past, going as far
     *   back as year 2000.
     * @param vestingLocation = Account where the vesting schedule is held (must already exist).
     * @param grantor = Account which performed the grant. Also the account from where the granted
     *   funds will be withdrawn.
     */
    function _grantVestingTokens(
        address beneficiary,
        uint256 totalAmount,
        uint256 vestingAmount,
        uint32 startDay,
        address vestingLocation,
        address grantor
    ) internal returns (bool ok) {
        // Make sure no prior grant is in effect.
        require(!_tokenGrants[beneficiary].isActive, "grant already exists");

        // Check for valid vestingAmount
        require(
            vestingAmount <= totalAmount &&
                vestingAmount > 0 &&
                startDay >= JAN_1_2000_DAYS &&
                startDay < JAN_1_3000_DAYS,
            "invalid vesting params"
        );

        // Make sure the vesting schedule we are about to use is valid.
        require(
            _hasVestingSchedule(vestingLocation),
            "no such vesting schedule"
        );

        // Transfer the total number of tokens from grantor into the account's holdings.
        _transfer(grantor, beneficiary, totalAmount);
        /* Emits a Transfer event. */

        // Create and populate a token grant, referencing vesting schedule.
        _tokenGrants[beneficiary] = tokenGrant(
            true, /*isActive*/
            false, /*wasRevoked*/
            startDay,
            vestingAmount,
            vestingLocation, /* The wallet address where the vesting schedule is kept. */
            grantor /* The account that performed the grant (where revoked funds would be sent) */
        );

        // Emit the event and return success.
        emit VestingTokensGranted(
            beneficiary,
            vestingAmount,
            startDay,
            vestingLocation,
            grantor
        );
        return true;
    }

    /**
     * @dev Immediately grants tokens to an address, including a portion that will vest over time
     * according to a set vesting schedule. The overall duration and cliff duration of the grant must
     * be an even multiple of the vesting interval.
     *
     * @param beneficiary = Address to which tokens will be granted.
     * @param totalAmount = Total number of tokens to deposit into the account.
     * @param vestingAmount = Out of totalAmount, the number of tokens subject to vesting.
     * @param startDay = Start day of the grant's vesting schedule, in days since the UNIX epoch
     *   (start of day). The startDay may be given as a date in the future or in the past, going as far
     *   back as year 2000.
     * @param duration = Duration of the vesting schedule, with respect to the grant start day, in days.
     * @param cliffDuration = Duration of the cliff, with respect to the grant start day, in days.
     * @param interval = Number of days between vesting increases.
     * @param isRevocable = True if the grant can be revoked (i.e. was a gift) or false if it cannot
     *   be revoked (i.e. tokens were purchased).
     */
    function grantVestingTokens(
        address beneficiary,
        uint256 totalAmount,
        uint256 vestingAmount,
        uint32 startDay,
        uint32 duration,
        uint32 cliffDuration,
        uint32 interval,
        bool isRevocable
    ) public override onlyGrantor returns (bool ok) {
        // Make sure no prior vesting schedule has been set.
        require(!_tokenGrants[beneficiary].isActive, "grant already exists");

        // The vesting schedule is unique to this wallet and so will be stored here,
        _setVestingSchedule(
            beneficiary,
            cliffDuration,
            duration,
            interval,
            isRevocable
        );

        // Issue grantor tokens to the beneficiary, using beneficiary's own vesting schedule.
        _grantVestingTokens(
            beneficiary,
            totalAmount,
            vestingAmount,
            startDay,
            beneficiary,
            _msgSender()
        );

        return true;
    }

    // Check vesting.

    /**
     * @dev returns the day number of the current day, in days since the UNIX epoch.
     */
    function today() public view override returns (uint32 dayNumber) {
        return uint32(block.timestamp / SECONDS_PER_DAY);
    }

    function _effectiveDay(uint32 onDayOrToday)
        internal
        view
        returns (uint32 dayNumber)
    {
        return onDayOrToday == 0 ? today() : onDayOrToday;
    }

    /**
     * @dev Determines the amount of tokens that have not vested in the given account.
     *
     * The math is: not vested amount = vesting amount * (end date - on date)/(end date - start date)
     *
     * @param grantHolder = The account to check.
     * @param onDayOrToday = The day to check for, in days since the UNIX epoch. Can pass
     *   the special value 0 to indicate today.
     */
    function _getNotVestedAmount(address grantHolder, uint32 onDayOrToday)
        internal
        view
        returns (uint256 amountNotVested)
    {
        tokenGrant storage grant = _tokenGrants[grantHolder];
        vestingSchedule storage vesting = _vestingSchedules[
            grant.vestingLocation
        ];
        uint32 onDay = _effectiveDay(onDayOrToday);

        // If there's no schedule, or before the vesting cliff, then the full amount is not vested.
        if (!grant.isActive || onDay < grant.startDay + vesting.cliffDuration) {
            // None are vested (all are not vested)
            return grant.amount;
        }
        // If after end of vesting, then the not vested amount is zero (all are vested).
        else if (onDay >= grant.startDay + vesting.duration) {
            // All are vested (none are not vested)
            return uint256(0);
        }
        // Otherwise a fractional amount is vested.
        else {
            // Compute the exact number of days vested.
            uint32 daysVested = onDay - grant.startDay;
            // Adjust result rounding down to take into consideration the interval.
            uint32 effectiveDaysVested = (daysVested / vesting.interval) *
                vesting.interval;

            // Compute the fraction vested from schedule using 224.32 fixed point math for date range ratio.
            // Note: This is safe in 256-bit math because max value of X billion tokens = X*10^27 wei, and
            // typical token amounts can fit into 90 bits. Scaling using a 32 bits value results in only 125
            // bits before reducing back to 90 bits by dividing. There is plenty of room left, even for token
            // amounts many orders of magnitude greater than mere billions.
            uint256 vested = grant.amount.mul(effectiveDaysVested).div(
                vesting.duration
            );
            return grant.amount.sub(vested);
        }
    }

    /**
     * @dev Computes the amount of funds in the given account which are available for use as of
     * the given day. If there's no vesting schedule then 0 tokens are considered to be vested and
     * this just returns the full account balance.
     *
     * The math is: available amount = total funds - notVestedAmount.
     *
     * @param grantHolder = The account to check.
     * @param onDay = The day to check for, in days since the UNIX epoch.
     */
    function _getAvailableAmount(address grantHolder, uint32 onDay)
        internal
        view
        returns (uint256 amountAvailable)
    {
        uint256 totalTokens = balanceOf(grantHolder);
        uint256 vested = totalTokens.sub(
            _getNotVestedAmount(grantHolder, onDay)
        );
        return vested;
    }

    /**
     * @dev returns all information about the grant's vesting as of the given day
     * for the given account. Only callable by the account holder or a grantor, so
     * this is mainly intended for administrative use.
     *
     * @param grantHolder = The address to do this for.
     * @param onDayOrToday = The day to check for, in days since the UNIX epoch. Can pass
     *   the special value 0 to indicate today.
     * return = A tuple with the following values:
     *   amountVested = the amount out of vestingAmount that is vested
     *   amountNotVested = the amount that is vested (equal to vestingAmount - vestedAmount)
     *   amountOfGrant = the amount of tokens subject to vesting.
     *   vestStartDay = starting day of the grant (in days since the UNIX epoch).
     *   vestDuration = grant duration in days.
     *   cliffDuration = duration of the cliff.
     *   vestIntervalDays = number of days between vesting periods.
     *   isActive = true if the vesting schedule is currently active.
     *   wasRevoked = true if the vesting schedule was revoked.
     */
    function vestingForAccountAsOf(address grantHolder, uint32 onDayOrToday)
        public
        view
        override
        onlyGrantorOrSelf(grantHolder)
        returns (
            uint256 amountVested,
            uint256 amountNotVested,
            uint256 amountOfGrant,
            uint32 vestStartDay,
            uint32 vestDuration,
            uint32 cliffDuration,
            uint32 vestIntervalDays,
            bool isActive,
            bool wasRevoked
        )
    {
        tokenGrant storage grant = _tokenGrants[grantHolder];
        vestingSchedule storage vesting = _vestingSchedules[
            grant.vestingLocation
        ];
        uint256 notVestedAmount = _getNotVestedAmount(
            grantHolder,
            onDayOrToday
        );
        uint256 grantAmount = grant.amount;

        return (
            grantAmount.sub(notVestedAmount),
            notVestedAmount,
            grantAmount,
            grant.startDay,
            vesting.duration,
            vesting.cliffDuration,
            vesting.interval,
            grant.isActive,
            grant.wasRevoked
        );
    }

    /**
     * @dev returns all information about the grant's vesting as of the given day
     * for the current account, to be called by the account holder.
     *
     * @param onDayOrToday = The day to check for, in days since the UNIX epoch. Can pass
     *   the special value 0 to indicate today.
     * return = A tuple with the following values:
     *   amountVested = the amount out of vestingAmount that is vested
     *   amountNotVested = the amount that is vested (equal to vestingAmount - vestedAmount)
     *   amountOfGrant = the amount of tokens subject to vesting.
     *   vestStartDay = starting day of the grant (in days since the UNIX epoch).
     *   cliffDuration = duration of the cliff.
     *   vestDuration = grant duration in days.
     *   vestIntervalDays = number of days between vesting periods.
     *   isActive = true if the vesting schedule is currently active.
     *   wasRevoked = true if the vesting schedule was revoked.
     */
    function vestingAsOf(uint32 onDayOrToday)
        public
        view
        override
        returns (
            uint256 amountVested,
            uint256 amountNotVested,
            uint256 amountOfGrant,
            uint32 vestStartDay,
            uint32 vestDuration,
            uint32 cliffDuration,
            uint32 vestIntervalDays,
            bool isActive,
            bool wasRevoked
        )
    {
        return vestingForAccountAsOf(_msgSender(), onDayOrToday);
    }

    /**
     * @dev returns true if the account has sufficient funds available to cover the given amount,
     *   including consideration for vesting tokens.
     *
     * @param account = The account to check.
     * @param amount = The required amount of vested funds.
     * @param onDay = The day to check for, in days since the UNIX epoch.
     */
    function _fundsAreAvailableOn(
        address account,
        uint256 amount,
        uint32 onDay
    ) internal view returns (bool ok) {
        return (amount <= _getAvailableAmount(account, onDay));
    }

    /**
     * @dev Modifier to make a function callable only when the amount is sufficiently vested right now.
     *
     * @param account = The account to check.
     * @param amount = The required amount of vested funds.
     */
    modifier onlyIfFundsAvailableNow(address account, uint256 amount) {
        if (_tokenGrants[account].isActive) {
            // Distinguish insufficient overall balance from insufficient vested funds balance in failure msg.
            require(
                _fundsAreAvailableOn(account, amount, today()),
                balanceOf(account) < amount
                    ? "insufficient funds"
                    : "insufficient vested funds"
            );
        }
        _;
    }

    // Grant revocation

    /**
     * @dev If the account has a revocable grant, this forces the grant to end based on computing
     * the amount vested up to the given date. All tokens that would no longer vest are returned
     * to the account of the original grantor.
     *
     * @param grantHolder = Address to which tokens will be granted.
     * @param onDay = The date upon which the vesting schedule will be effectively terminated,
     *   in days since the UNIX epoch (start of day).
     */
    function revokeGrant(address grantHolder, uint32 onDay)
        public
        override
        onlyGrantor
        returns (bool ok)
    {
        tokenGrant storage grant = _tokenGrants[grantHolder];
        vestingSchedule storage vesting = _vestingSchedules[
            grant.vestingLocation
        ];
        uint256 notVestedAmount;

        // Make sure grantor can only revoke from own pool.
        require(_msgSender() == owner() || _msgSender() == grant.grantor, "not allowed");
        // Make sure a vesting schedule has previously been set.
        require(grant.isActive, "no active grant");
        // Make sure it's revocable.
        require(vesting.isRevocable, "irrevocable");
        // Fail on likely erroneous input.
        require(onDay <= grant.startDay + vesting.duration, "no effect");
        // Don"t let grantor revoke anf portion of vested amount.
        require(onDay >= today(), "cannot revoke vested holdings");

        notVestedAmount = _getNotVestedAmount(grantHolder, onDay);

        // Use ERC20 _approve() to forcibly approve grantor to take back not-vested tokens from grantHolder.
        _approve(grantHolder, grant.grantor, notVestedAmount, true);
        /* Emits an Approval Event. */
        transferFrom(grantHolder, grant.grantor, notVestedAmount);
        /* Emits a Transfer and an Approval Event. */

        // Kill the grant by updating wasRevoked and isActive.
        _tokenGrants[grantHolder].wasRevoked = true;
        _tokenGrants[grantHolder].isActive = false;

        emit GrantRevoked(grantHolder, onDay);
        /* Emits the GrantRevoked event. */
        return true;
    }

    // Overridden ERC20 functionality

    /**
     * @dev Methods transfer() and approve() require an additional available funds check to
     * prevent spending held but non-vested tokens. Note that transferFrom() does NOT have this
     * additional check because approved funds come from an already set-aside allowance, not from the wallet.
     */
    function transfer(address recipient, uint256 value)
        public
        override
        whenNotPaused
        whenTokenomicsCriteriaMet(_msgSender(), recipient, value)
        whenEconomicProtectionCriteriaMet(_msgSender(), recipient, value)
        onlyIfFundsAvailableNow(_msgSender(), value)
        returns (bool ok)
    {
        return super.transfer(recipient, value);
    }

    /**
     * @dev Additional available funds check to prevent spending held but non-vested tokens.
     */
    function approve(address spender, uint256 value)
        public
        override
        whenNotPaused
        whenTokenomicsCriteriaMet(_msgSender(), spender, value)
        onlyIfFundsAvailableNow(_msgSender(), value)
        returns (bool ok)
    {
        return super.approve(spender, value);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    )
        public
        override
        whenNotPaused
        whenTransferEscrowCriteriaMet(sender, recipient)
        returns (bool)
    {
        return super.transferFrom(sender, recipient, amount);
    }

    // Overridden ERC20 functionality

    /**
     * Ensure there is no way for the contract to end up with no owner. That would inadvertently result in
     * token grant administration becoming impossible. We override this to always disallow it.
     */
    function renounceOwnership() public view virtual override onlyManager {
        require(false, "forbidden");
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner)
        public
        virtual
        override
        onlyManager
    {
        require(_isAddressSafe(newOwner), "Ownable: should not be zero/burn adddress");
        _removeGrantor(_msgSender());
        super.transferOwnership(newOwner);
        _addGrantor(newOwner, OWNER_UNIFORM_GRANTOR_FLAG);
    }
}


// File imports/KenaTokenGrant.sol



pragma solidity ^0.8.11;



/**
 * @dev Grants as Incentives for controlled groups.
 */
abstract contract KenaTokenGrant is ERC20Vestable {
    using AddressUpgradeable for address;

    struct restrictions {
        bool isValid;
        uint32 minStartDay; /* The smallest value for startDay allowed in grant creation. */
        uint32 maxStartDay; /* The maximum value for startDay allowed in grant creation. */
        uint32 expirationDay; /* The last day this grantor may make grants. */
    }

    mapping(address => restrictions) private _restrictions;

    // Uniform token grant setup
    // Methods used by owner to set up uniform grants on restricted grantor
    event GrantorRestrictionsSet(
        address indexed grantor,
        uint32 minStartDay,
        uint32 maxStartDay,
        uint32 expirationDay
    );

    /**
     * @dev Lets owner set or change existing specific restrictions. Restrictions must be established
     * before the grantor will be allowed to issue grants.
     *
     * All date values are expressed as number of days since the UNIX epoch. Note that the inputs are
     * themselves not very thoroughly restricted. However, this method can be called more than once
     * if incorrect values need to be changed, or to extend a grantor's expiration date.
     *
     * @param grantor = Address which will receive the uniform grantable vesting schedule.
     * @param minStartDay = The smallest value for startDay allowed in grant creation.
     * @param maxStartDay = The maximum value for startDay allowed in grant creation.
     * @param expirationDay = The last day this grantor may make grants.
     */
    function setUGRestrictions(
        address grantor,
        uint32 minStartDay,
        uint32 maxStartDay,
        uint32 expirationDay
    ) public onlyOwner returns (bool ok) {
        require(
            isUniformGrantor(grantor) &&
                maxStartDay > minStartDay &&
                expirationDay > today(),
            "invalid params"
        );

        // We allow owner to set or change existing specific restrictions.
        _restrictions[grantor] = restrictions(
            true, /*isValid*/
            minStartDay,
            maxStartDay,
            expirationDay
        );

        // Emit the event and return success.
        emit GrantorRestrictionsSet(
            grantor,
            minStartDay,
            maxStartDay,
            expirationDay
        );
        return true;
    }

    /**
     * @dev Lets owner permanently establish a vesting schedule for a restricted grantor to use when
     * creating uniform token grants. Grantee accounts forever refer to the grantor's account to look up
     * vesting, so this method can only be used once per grantor.
     *
     * @param grantor = Address which will receive the uniform grantable vesting schedule.
     * @param duration = Duration of the vesting schedule, with respect to the grant start day, in days.
     * @param cliffDuration = Duration of the cliff, with respect to the grant start day, in days.
     * @param interval = Number of days between vesting increases.
     * @param isRevocable = True if the grant can be revoked (i.e. was a gift) or false if it cannot
     *   be revoked (i.e. tokens were purchased).
     */
    function setUGVestingSchedule(
        address grantor,
        uint32 duration,
        uint32 cliffDuration,
        uint32 interval,
        bool isRevocable
    ) public onlyOwner returns (bool ok) {
        // Only allow doing this to restricted grantor role account.
        require(isUniformGrantor(grantor), "uniform grantor only");
        // Make sure no prior vesting schedule has been set!
        require(!_hasVestingSchedule(grantor), "schedule already exists");

        // The vesting schedule is unique to this grantor wallet and so will be stored here to be
        // referenced by future grants. Emits VestingScheduleCreated event.
        _setVestingSchedule(
            grantor,
            cliffDuration,
            duration,
            interval,
            isRevocable
        );

        return true;
    }

    // Uniform token grants

    function isUniformGrantorWithSchedule(address account)
        internal
        view
        returns (bool ok)
    {
        // Check for grantor that has a uniform vesting schedule already set.
        return isUniformGrantor(account) && _hasVestingSchedule(account);
    }

    modifier onlyUniformGrantorWithSchedule(address account) {
        require(
            isUniformGrantorWithSchedule(account),
            "grantor account not ready"
        );
        _;
    }

    modifier whenGrantorRestrictionsMet(uint32 startDay) {
        restrictions storage restriction = _restrictions[_msgSender()];
        require(restriction.isValid, "set restrictions first");

        require(
            startDay >= restriction.minStartDay &&
                startDay < restriction.maxStartDay,
            "startDay too early"
        );

        require(today() < restriction.expirationDay, "grantor expired");
        _;
    }

    /**
     * @dev Immediately grants tokens to an address, including a portion that will vest over time
     * according to the uniform vesting schedule already established in the grantor's account.
     *
     * @param beneficiary = Address to which tokens will be granted.
     * @param totalAmount = Total number of tokens to deposit into the account.
     * @param vestingAmount = Out of totalAmount, the number of tokens subject to vesting.
     * @param startDay = Start day of the grant's vesting schedule, in days since the UNIX epoch
     *   (start of day). The startDay may be given as a date in the future or in the past, going as far
     *   back as year 2000.
     */
    function grantUniformVestingTokens(
        address beneficiary,
        uint256 totalAmount,
        uint256 vestingAmount,
        uint32 startDay
    )
        public
        onlyUniformGrantorWithSchedule(_msgSender())
        whenGrantorRestrictionsMet(startDay)
        returns (bool ok)
    {
        // Issue grantor tokens to the beneficiary, using Grantor's own vesting schedule.
        // Emits VestingTokensGranted event.
        return
            _grantVestingTokens(
                beneficiary,
                totalAmount,
                vestingAmount,
                startDay,
                _msgSender(),
                _msgSender()
            );
    }
}


// File contracts/KenaTokenV1.sol

/**
 * SPDX-License-Identifier: MIT
 */
pragma solidity ^0.8.11;



/**
 * Kena Official Site           https://kena.ai
 * Token Name and Symbol        KENA
 * Token Contract Class         KenaToken1 (version 1)
 * Total Supply                 ONE TRILLION.
 * Burn Address                 0xDeADCafe00000000000000000000000662607015
 * Contract Type                EIP1822 (UUPS Upgradeable).
 * Pausable for Emergency       True.
 * Ownership Renounced?         False. (Cannot Renounce Ownership for Upgradeable contracts).
 * Peer-To-Peer Network Fee     1%
 * On-Ramp Network Fee (Buy)    5%
 * Off-Ramp Network Fee (Sell)  7%
 * Off-Ramp Burn (Sell)         3% (Economic Stability)
 * Transaction Cap              0.5% of total supply.
 * Wallet Cap                   4% of total supply.
 * Anti-Whale Sale trigger      0.10% of total supply.
 * Anti-Whale Sale Penalty      5% Additional (Total 12%)
 * Buy-Sell Latency             1 hour.
 * Sell-Spread Latency          Starts at 15 mins and doubles.
 * Allowance Escrow             24 hours before allowance can be used.
 */
contract KenaTokenV1 is KenaTokenGrant {
    using SafeMath for uint256;
    using AddressUpgradeable for address;

    function initialize() public override initializer {
        __ERC20_init("KENA", "KENA.v77");
        __Ownable_init();
        __Manageable_init();
        __UUPSUpgradeable_init();
        super.initialize();
    }

    function _getSumOfFees(
        address sender,
        address recipient,
        uint256 amount
    ) internal view override returns (uint256) {
        (
            bool _isPeerToPeer,
            bool _isSale,
            bool _isBuy,
            bool _isWhaleSale
        ) = _getTransactionType(sender, recipient, amount);
        if (_isWhaleSale) {
            return (OFF_RAMP_NETWORK_FEE +
                BURN_FEE +
                ANTI_WHALE_SALE_PENALTY_FEE);
        } else if (_isSale) {
            return (OFF_RAMP_NETWORK_FEE + BURN_FEE);
        } else if (_isBuy) {
            return ON_RAMP_NETWORK_FEE;
        } else if (_isPeerToPeer) {
            return PEER_TO_PEER_NETWORK_FEE;
        } else {
            return PEER_TO_PEER_NETWORK_FEE; // Default
        }
    }

    function _takeTransactionFees(
        address sender,
        address recipient,
        uint256 amount,
        uint256 currentRate
    ) internal override {
        if (isInPresale) {
            return;
        }
        uint256 feesCount = _getFeesCount();
        (
            bool _isPeerToPeer,
            bool _isSale,
            bool _isBuy,
            bool _isWhaleSale
        ) = _getTransactionType(sender, recipient, amount);
        for (uint256 index = 0; index < feesCount; index++) {
            (FeeType name, uint256 value, , ) = _getFee(index);

            // no need to check value < 0 as the value is uint (i.e. from 0 to 2^256-1)
            if (value == 0) continue;

            if (_isPeerToPeer && name == FeeType.PeerToPeerNetworkFee) {
                _redistribute(amount, currentRate, value, index);
            } else if (_isWhaleSale && name == FeeType.AntiWhaleDumpPenalty) {
                _redistribute(amount, currentRate, value, index);
            } else if (_isSale && name == FeeType.OffRampNetworkFee) {
                _redistribute(amount, currentRate, value, index);
            } else if (_isSale && name == FeeType.Burn) {
                _burn(amount, currentRate, value, index);
            } else if (_isBuy && name == FeeType.OnRampNetworkFee) {
                _redistribute(amount, currentRate, value, index);
            }
        }
    }

    function _burn(
        uint256 amount,
        uint256 currentRate,
        uint256 fee,
        uint256 index
    ) private {
        uint256 tBurn = amount.mul(fee).div(FEES_DIVISOR);
        uint256 rBurn = tBurn.mul(currentRate);

        _burnTokens(address(this), tBurn, rBurn);
        _addFeeCollectedAmount(index, tBurn);
    }

    // Helper Utility for Liquidity Pool 
    // Help identify if address is part of Liquidity Pool Pair
    function _isLiquidityPoolAddress(address account)
        internal
        view
        override
        returns (bool)
    {
        return isLiquidityPool[account];
    }
}
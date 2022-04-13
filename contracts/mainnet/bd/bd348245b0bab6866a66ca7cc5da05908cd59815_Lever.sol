// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

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
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal INITIAL_CHAIN_ID;

    bytes32 internal INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }


    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*///////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*///////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z) // Like multiplying by 2 ** 64.
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z) // Like multiplying by 2 ** 32.
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z) // Like multiplying by 2 ** 16.
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z) // Like multiplying by 2 ** 8.
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z) // Like multiplying by 2 ** 4.
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z) // Like multiplying by 2 ** 2.
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    event Debug(bool one, bool two, uint256 retsize);

    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./Router.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {Initializable} from "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";


/** 
 * @notice Lever is a contract intended for use in the Yeti Finance Lever Up feature. It routes from 
 * YUSD to some various token out which has to be compatible with the underlying router in the route 
 * function, and unRoutes backwards to get YUSD out. Sends to the active pool address by intention and 
 * route is called in functions openTroveLeverUp and addCollLeverUp in BorrowerOperations.sol. unRoute
 * is called in functions closeTroveUnleverUp and withdrawCollUnleverUp in BorrowerOperations.sol.
 */

contract Lever is Router, ReentrancyGuard {
    constructor() {
        initialize();
    }
    function initialize() public initializer {
        __Ownable_init();
    }

    // Goes from some token (YUSD likely) and gives a certain amount of token out.
    // Auto transfers to active pool from call in BorrowerOperations.sol, aka _toUser is always activePool
    // Goes from _startingTokenAddress to _endingTokenAddress, pulling tokens from _fromUser, of _amount, and gets _minSwapAmount out _endingTokenAddress
    function route(
        address _toUser,
        address _startingTokenAddress,
        address _endingTokenAddress,
        uint256 _amount,
        uint256 _minSwapAmount
    ) external nonReentrant returns (uint256 amountOut) {
        amountOut = swap(
            _startingTokenAddress,
            _endingTokenAddress,
            _amount,
            _minSwapAmount
        );
        IERC20(_endingTokenAddress).transfer(_toUser, amountOut);
    }

    // Takes the address of the token required in, and gives a certain amount of any token (YUSD likely) out
    // User first withdraws that collateral from the active pool, then performs this swap. Unwraps tokens
    // for the user in that case.
    // Goes from _startingTokenAddress to _endingTokenAddress, pulling tokens from _fromUser, of _amount, and gets _minSwapAmount out _endingTokenAddress.
    // Use case: Takes token from trove debt which has been transfered to the owner and then swaps it for YUSD, intended to repay debt.
    function unRoute(
        address _toUser,
        address _startingTokenAddress,
        address _endingTokenAddress,
        uint256 _amount,
        uint256 _minSwapAmount
    ) external nonReentrant returns (uint256 amountOut) {
        amountOut = swap(
            _startingTokenAddress,
            _endingTokenAddress,
            _amount,
            _minSwapAmount
        );
        IERC20(_endingTokenAddress).transfer(_toUser, amountOut);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IAAVE} from "./interfaces/IAAVE.sol";
import {ICOMP} from "./interfaces/ICOMP.sol";
import {IJoePair} from "./interfaces/IJoePair.sol";
import {IMeta} from "./interfaces/IMeta.sol";
import {IJoeRouter} from "./interfaces/IJoeRouter.sol";
import {IPlainPool, ILendingPool, IMetaPool} from "./interfaces/ICurvePool.sol";
import {IYetiVaultToken} from "./interfaces/IYetiVaultToken.sol";

import {OwnableUpgradeable} from "openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

/** 
 * @notice Router is a contract for routing token swaps through various defined routes. 
 * It takes a modular approach to swapping and can go through multiple routes, as encoded in the 
 * Node array which corresponds to a route. A path is defined as routes[fromToken][toToken]. 
 */

contract Router is OwnableUpgradeable {
    using SafeTransferLib for IERC20;

    address public traderJoeRouter;
    address public aaveLendingPool;
    event RouteSet(address fromToken, address toToken, Node[] path);
    event Swap(
        address caller,
        address startingTokenAddress,
        address endingTokenAddress,
        uint256 amount,
        uint256 minSwapAmount,
        uint256 actualOut
    );
    uint256 internal constant MAX_INT =
        115792089237316195423570985008687907853269984665640564039457584007913129639935;
    uint256 internal constant FEE_DENOMINATOR = 1e3;
    uint256 internal constant FEE_COMPLIMENT = 997;

    // nodeType
    // 1 = Trader Joe Swap
    // 2 = Joe LP Token
    // 3 = curve pool
    // 4 = n/a
    // 5 = n/a
    // 6 = aave-like Token
    // 7 = comp-like Token
    struct Node {
        // Is Joe pair or cToken etc. 
        address protocolSwapAddress;
        uint256 nodeType;
        address tokenIn;
        address tokenOut;
        int128 _misc; //Extra info for curve pools
        int128 _in;
        int128 _out;
    }

    // Usage: path = routes[fromToken][toToken]
    mapping(address => mapping(address => Node[])) public routes;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;

    function setJoeRouter(address _traderJoeRouter) public onlyOwner {
        traderJoeRouter = _traderJoeRouter;
    }

    function setAAVE(address _aaveLendingPool) public onlyOwner {
        aaveLendingPool = _aaveLendingPool;
    }

    function setApprovals(
        address _token,
        address _who,
        uint256 _amount
    ) external onlyOwner {
        IERC20(_token).approve(_who, _amount);
    }

    function setRoute(
        address _fromToken,
        address _toToken,
        Node[] calldata _path
    ) external onlyOwner {
        delete routes[_fromToken][_toToken];
        for (uint256 i = 0; i < _path.length; i++) {
            routes[_fromToken][_toToken].push(_path[i]);
        }
        // routes[_fromToken][_toToken] = _path;
        emit RouteSet(_fromToken, _toToken, _path);
    }

    //////////////////////////////////////////////////////////////////////////////////
    // #1 Swap through Trader Joe
    //////////////////////////////////////////////////////////////////////////////////
    function swapJoePair(
        address _pair,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) internal returns (uint256) {
        IERC20(_tokenIn).transfer(_pair, _amountIn);
        uint256 amount0Out;
        uint256 amount1Out;
        (uint256 reserve0, uint256 reserve1, ) = IJoePair(_pair).getReserves();
        if (_tokenIn < _tokenOut) {
            // TokenIn=token0
            amount1Out = _getAmountOut(_amountIn, reserve0, reserve1);
        } else {
            // TokenIn=token1
            amount0Out = _getAmountOut(_amountIn, reserve1, reserve0);
        }
        IJoePair(_pair).swap(
            amount0Out,
            amount1Out,
            address(this),
            new bytes(0)
        );
        return amount0Out != 0 ? amount0Out : amount1Out;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function _getAmountOut(
        uint256 _amountIn,
        uint256 _reserveIn,
        uint256 _reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(_amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(
            _reserveIn > 0 && _reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 amountInWithFee = _amountIn * FEE_COMPLIMENT;
        uint256 numerator = amountInWithFee * _reserveOut;
        uint256 denominator = (_reserveIn * FEE_DENOMINATOR) + amountInWithFee;
        amountOut = numerator / denominator;
    }

    //////////////////////////////////////////////////////////////////////////////////
    // #2 Swap into and out of Trader Joe LP Token
    //////////////////////////////////////////////////////////////////////////////////

    function _min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    function _getAmtToSwap(uint256 r0, uint256 totalX)
        internal
        pure
        returns (uint256)
    {
        // For optimal amounts, this quickly becomes an algebraic optimization problem
        // You must account for price impact of the swap to the corresponding token
        // Optimally, you swap enough of tokenIn such that the ratio of tokenIn_1/tokenIn_2 is the same as reserve1/reserve2 after the swap
        // Plug _in the uniswap k=xy equation _in the above equality and you will get the following:
        uint256 sub = (r0 * 998500) / 994009;
        uint256 toSqrt = totalX * 3976036 * r0 + r0 * r0 * 3988009;
        return (FixedPointMathLib.sqrt(toSqrt) * 500) / 994009 - sub;
    }

    function _getAmountPairOut(
        uint256 _amountIn,
        uint256 _reserveIn,
        uint256 _reserveOut,
        uint256 _totalSupply
    ) internal view returns (uint256 amountOut) {
        // Given token, how much lp token will I get?

        _amountIn = _getAmtToSwap(_reserveIn, _amountIn);
        uint256 amountInWithFee = _amountIn * FEE_COMPLIMENT;
        uint256 numerator = amountInWithFee * _reserveOut;
        uint256 denominator = _reserveIn * FEE_DENOMINATOR + amountInWithFee;
        uint256 _amountIn2 = numerator / denominator;
        // https://github.com/traderjoe-xyz/joe-core/blob/11d6c6a57017b5f890eb7ea3e3a61de245a41ef2/contracts/traderjoe/JoePair.sol#L153
        amountOut = _min(
            (_amountIn * _totalSupply) / (_reserveIn + _amountIn),
            (_amountIn2 * _totalSupply) / (_reserveOut - _amountIn2)
        );
    }

    function _getAmountPairIn(
        uint256 _amountIn,
        uint256 _reserveIn,
        uint256 _reserveOut,
        uint256 _totalSupply
    ) internal view returns (uint256 amountOut) {
        // Given lp token, how much token will I get?
        uint256 amt0 = (_amountIn * _reserveIn) / _totalSupply;
        uint256 amt1 = (_amountIn * _reserveOut) / _totalSupply;

        _reserveIn = _reserveIn - amt0;
        _reserveOut = _reserveOut - amt1;

        uint256 amountInWithFee = amt0 * FEE_COMPLIMENT;
        uint256 numerator = amountInWithFee * _reserveOut;
        uint256 denominator = (_reserveIn * FEE_DENOMINATOR) + amountInWithFee;
        amountOut = numerator / denominator;
        amountOut = amountOut + amt1;
    }

    function swapLPToken(
        address _token,
        address _pair,
        uint256 _amountIn,
        bool _LPIn
    ) internal returns (uint256) {
        address token0 = IJoePair(_pair).token0();
        address token1 = IJoePair(_pair).token1();
        if (_LPIn) {
            IJoeRouter(traderJoeRouter).removeLiquidity(
                token0,
                token1,
                _amountIn,
                0,
                0,
                address(this),
                block.timestamp
            );
            if (token0 == _token) {
                swapJoePair(
                    _pair,
                    token1,
                    token0,
                    IERC20(token1).balanceOf(address(this))
                );
            } else if (token1 == _token) {
                swapJoePair(
                    _pair,
                    token0,
                    token1,
                    IERC20(token0).balanceOf(address(this))
                );
            } else {
                revert("tokenOut is not a token _in the pair");
            }
            return IERC20(_token).balanceOf(address(this));
        } else {
            (uint112 r0, uint112 r1, uint32 _last) = IJoePair(_pair)
                .getReserves();
            if (token0 == _token) {
                swapJoePair(_pair, _token, token1, _getAmtToSwap(r0, _amountIn));
                IJoeRouter(traderJoeRouter).addLiquidity(
                    token0,
                    token1,
                    IERC20(token0).balanceOf(address(this)),
                    IERC20(token1).balanceOf(address(this)),
                    0,
                    0,
                    address(this),
                    block.timestamp
                );
            } else if (token1 == _token) {
                swapJoePair(_pair, _token, token0, _getAmtToSwap(r1, _amountIn));
                IJoeRouter(traderJoeRouter).addLiquidity(
                    token0,
                    token1,
                    IERC20(token0).balanceOf(address(this)),
                    IERC20(token1).balanceOf(address(this)),
                    0,
                    0,
                    address(this),
                    block.timestamp
                );
            } else {
                revert("tokenOut is not a token _in the pair");
            }
            return IERC20(_pair).balanceOf(address(this));
        }
    }


    //////////////////////////////////////////////////////////////////////////////////
    // #3 Swap through Curve 2Pool
    //////////////////////////////////////////////////////////////////////////////////

    // A note on curve swapping:
    // The curve swaps make use of 3 additional helper variables:
    // _misc describes the type of pool interaction. _misc < 0 represents plain pool interactions, _misc > 0 represents
    // interactions with lendingPool and metaPools. abs(_misc) == numCoins in the pool
    // and is used to size arrays when doing add_liquidity
    // _in describes the index of the token being swapped in (if it's -1 it means we're splitting a crvLP token)
    // _out describes the index of the token being swapped out (if it's -1 it means we're trying to mint a crvLP token)
    
    function swapCurve(
        address _tokenIn,
        address _tokenOut,
        address _curvePool,
        uint256 _amount,
        int128 _misc,
        int128 _in,
        int128 _out
    ) internal returns (uint256 amountOut) {
        if (_misc < 0) {
            // Plain pool
            if (_out == -1) {
                _misc = -_misc;
                uint256[] memory _amounts = new uint256[](uint256(int256(_misc)));
                _amounts[uint256(int256(_in))] = _amount;
                if (_misc == 2) {
                    amountOut = IPlainPool(_curvePool).add_liquidity(
                        [_amounts[0], _amounts[1]],
                        0
                    );
                } else if (_misc == 3) {
                    amountOut = IPlainPool(_curvePool).add_liquidity(
                        [_amounts[0], _amounts[1], _amounts[2]],
                        0
                    );
                } else if (_misc == 4) {
                    amountOut = IPlainPool(_curvePool).add_liquidity(
                        [_amounts[0], _amounts[1], _amounts[2], _amounts[3]],
                        0
                    );
                }
            } else if (_in == -1) {
                amountOut = IPlainPool(_curvePool).remove_liquidity_one_coin(
                    _amount,
                    _out,
                    0
                );
            } else {
                amountOut = IPlainPool(_curvePool).exchange(
                    _in,
                    _out,
                    _amount,
                    0
                );
            }
        } else if (_misc > 0) {
            // Use underlying. Works for both lending and metapool
            if (_out == -1) {
                uint256[] memory _amounts = new uint256[](uint256(int256(_misc)));
                _amounts[uint256(int256(_in))] = _amount;
                if (_misc == 2) {
                    amountOut = ILendingPool(_curvePool).add_liquidity(
                        [_amounts[0], _amounts[1]],
                        0,
                        true
                    );
                } else if (_misc == 3) {
                    amountOut = ILendingPool(_curvePool).add_liquidity(
                        [_amounts[0], _amounts[1], _amounts[2]],
                        0,
                        true
                    );
                } else if (_misc == 4) {
                    amountOut = ILendingPool(_curvePool).add_liquidity(
                        [_amounts[0], _amounts[1], _amounts[2], _amounts[3]],
                        0,
                        true
                    );
                }
            } else {
                amountOut = ILendingPool(_curvePool).exchange_underlying(
                    _in,
                    _out,
                    _amount,
                    0
                );
            }
        }
    }

    //////////////////////////////////////////////////////////////////////////////////
    // #4 Unimplemented
    //////////////////////////////////////////////////////////////////////////////////

    

    //////////////////////////////////////////////////////////////////////////////////
    // #5 Unimplemented
    //////////////////////////////////////////////////////////////////////////////////

    

    //////////////////////////////////////////////////////////////////////////////////
    // #6 AAVE Token
    //////////////////////////////////////////////////////////////////////////////////

    function swapAAVEToken(
        address _token,
        uint256 _amount,
        bool _AaveIn
    ) internal returns (uint256) {
        if (_AaveIn) {
            // Swap Aave for _token
            _amount = IAAVE(aaveLendingPool).withdraw(
                _token,
                _amount,
                address(this)
            );
            return _amount;
        } else {
            // Swap _token for Aave
            IAAVE(aaveLendingPool).deposit(_token, _amount, address(this), 0);
            return _amount;
        }
    }

    //////////////////////////////////////////////////////////////////////////////////
    // #7 Compound-like Token
    //////////////////////////////////////////////////////////////////////////////////

    function swapCOMPToken(
        address _tokenIn,
        address _cToken,
        uint256 _amount
    ) internal returns (uint256) {
        if (_tokenIn == _cToken) {
            // Swap ctoken for _token
            ICOMP(_cToken).redeem(_amount);
            address underlying = ICOMP(_cToken).underlying();
            return IERC20(underlying).balanceOf(address(this));
        } else {
            // Swap _token for ctoken
            ICOMP(_cToken).mint(_amount);
            return IERC20(_cToken).balanceOf(address(this));
        }
    }

    //////////////////////////////////////////////////////////////////////////////////
    // #8 Yeti Vault Token
    //////////////////////////////////////////////////////////////////////////////////

    /** 
     * @dev Swaps some protocol token 
     * protocolSwapAddress is the _receiptToken address for that vault token. 
     */ 
    function swapYetiVaultToken(
        address _tokenIn,
        address _receiptToken,
        uint256 _amount
    ) internal returns (uint256) {
        if (_tokenIn == _receiptToken) {
            // Swap _receiptToken for _tokenIn, aka redeem() that amount. 
            return IYetiVaultToken(_receiptToken).redeem(_amount); 
        } else {
            // Swap _tokenIn for _receiptToken, aka deposit() that amount.
            return IYetiVaultToken(_receiptToken).deposit(_amount); 
        }
    }


    // Takes the address of the token _in, and gives a certain amount of token out. 
    // Calls correct swap functions sequentially based on the route which is defined by the 
    // routes array. 
    function swap(
        address _startingTokenAddress,
        address _endingTokenAddress,
        uint256 _amount,
        uint256 _minSwapAmount
    ) internal returns (uint256) {
        uint256 initialOutAmount = IERC20(_endingTokenAddress).balanceOf(
            address(this)
        );
        Node[] memory path = routes[_startingTokenAddress][_endingTokenAddress];
        uint256 amtIn = _amount;
        require(path.length > 0, "No route found");
        for (uint256 i; i < path.length; i++) {
            if (path[i].nodeType == 1) {
                // Is traderjoe
                _amount = swapJoePair(
                    path[i].protocolSwapAddress,
                    path[i].tokenIn,
                    path[i].tokenOut,
                    _amount
                );
            } else if (path[i].nodeType == 2) {
                // Is jlp
                if (path[i].tokenIn == path[i].protocolSwapAddress) {
                    _amount = swapLPToken(
                        path[i].tokenOut,
                        path[i].protocolSwapAddress,
                        _amount,
                        true
                    );
                } else {
                    _amount = swapLPToken(
                        path[i].tokenIn,
                        path[i].protocolSwapAddress,
                        _amount,
                        false
                    );
                }
            } else if (path[i].nodeType == 3) {
                // Is curve pool
                _amount = swapCurve(
                    path[i].tokenIn,
                    path[i].tokenOut,
                    path[i].protocolSwapAddress,
                    _amount,
                    path[i]._misc,
                    path[i]._in,
                    path[i]._out
                );
            } else if (path[i].nodeType == 6) {
                // Is aToken
                _amount = swapAAVEToken(
                    path[i].tokenIn == path[i].protocolSwapAddress
                        ? path[i].tokenOut
                        : path[i].tokenIn,
                    _amount,
                    path[i].tokenIn == path[i].protocolSwapAddress
                );
            } else if (path[i].nodeType == 7) {
                // Is cToken
                _amount = swapCOMPToken(
                    path[i].tokenIn,
                    path[i].protocolSwapAddress,
                    _amount
                );
            } else if (path[i].nodeType == 8) {
                // Is Yeti Vault Token
                _amount = swapYetiVaultToken(
                    path[i].tokenIn,
                    path[i].protocolSwapAddress,
                    _amount
                );
            } else {
                revert("Unknown node type");
            }
        }
        uint256 outAmount = IERC20(_endingTokenAddress).balanceOf(
            address(this)
        ) - initialOutAmount;
        require(
            outAmount >= _minSwapAmount,
            "Did not receive enough tokens to account for slippage"
        );
        emit Swap(
            msg.sender,
            _startingTokenAddress,
            _endingTokenAddress,
            amtIn,
            _minSwapAmount,
            outAmount
        );
        return outAmount;
    }
}

pragma solidity ^0.8.0;

interface IAAVE {
    function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);
}

pragma solidity ^0.8.0;

interface ICOMP {
    function redeem(uint redeemTokens) external returns (uint);
    function mint(uint mintAmount) external returns (uint);
    function underlying() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

interface IPlainPool {
    function coins(uint256 i) external view returns (address);
    function lp_token() external view returns (address);
    function exchange(int128 i, int128 j, uint256 _dx, uint256 _min_dy) external returns (uint256 actual_dy);
    
    function add_liquidity(uint256[2] calldata _amounts, uint256 _min_mint_amount) external returns (uint256 actualMinted);
    function add_liquidity(uint256[3] calldata _amounts, uint256 _min_mint_amount) external returns (uint256 actualMinted);
    function add_liquidity(uint256[4] calldata _amounts, uint256 _min_mint_amount) external returns (uint256 actualMinted);
    function add_liquidity(uint256[5] calldata _amounts, uint256 _min_mint_amount) external returns (uint256 actualMinted);

    function remove_liquidity(uint256 _amount, uint256[2] calldata _min_amounts) external returns (uint256[2] calldata actualWithdrawn);
    function remove_liquidity(uint256 _amount, uint256[3] calldata _min_amounts) external returns (uint256[3] calldata actualWithdrawn);
    function remove_liquidity(uint256 _amount, uint256[4] calldata _min_amounts) external returns (uint256[4] calldata actualWithdrawn);
    function remove_liquidity(uint256 _amount, uint256[5] calldata _min_amounts) external returns (uint256[5] calldata actualWithdrawn);

    function remove_liquidity_imbalance(uint256[2] calldata _amounts, uint256 _max_burn_amount) external returns (uint256 actualBurned);
    function remove_liquidity_imbalance(uint256[3] calldata _amounts, uint256 _max_burn_amount) external returns (uint256 actualBurned);
    function remove_liquidity_imbalance(uint256[4] calldata _amounts, uint256 _max_burn_amount) external returns (uint256 actualBurned);
    function remove_liquidity_imbalance(uint256[5] calldata _amounts, uint256 _max_burn_amount) external returns (uint256 actualBurned);

    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 _min_amount) external returns (uint256 actualWithdrawn);
}

interface ILendingPool {
    function coins(uint256 i) external view returns (address);
    function underlying_coins(uint256 i) external view returns (address);
    function lp_token() external view returns (address);
    function exchange(int128 i, int128 j, uint256 _dx, uint256 _min_dy) external returns (uint256 actual_dy);
    function exchange_underlying(int128 i, int128 j, uint256 _dx, uint256 _min_dy) external returns (uint256 actual_dy);


    function add_liquidity(uint256[2] calldata _amounts, uint256 _min_mint_amount) external returns (uint256 actualMinted);
    function add_liquidity(uint256[3] calldata _amounts, uint256 _min_mint_amount) external returns (uint256 actualMinted);
    function add_liquidity(uint256[4] calldata _amounts, uint256 _min_mint_amount) external returns (uint256 actualMinted);
    function add_liquidity(uint256[5] calldata _amounts, uint256 _min_mint_amount) external returns (uint256 actualMinted);

    function add_liquidity(uint256[2] calldata _amounts, uint256 _min_mint_amount, bool _use_underlying) external returns (uint256 actualMinted);
    function add_liquidity(uint256[3] calldata _amounts, uint256 _min_mint_amount, bool _use_underlying) external returns (uint256 actualMinted);
    function add_liquidity(uint256[4] calldata _amounts, uint256 _min_mint_amount, bool _use_underlying) external returns (uint256 actualMinted);
    function add_liquidity(uint256[5] calldata _amounts, uint256 _min_mint_amount, bool _use_underlying) external returns (uint256 actualMinted);

    function remove_liquidity(uint256 _amount, uint256[2] calldata _min_amounts) external returns (uint256[2] calldata actualWithdrawn);
    function remove_liquidity(uint256 _amount, uint256[3] calldata _min_amounts) external returns (uint256[3] calldata actualWithdrawn);
    function remove_liquidity(uint256 _amount, uint256[4] calldata _min_amounts) external returns (uint256[4] calldata actualWithdrawn);
    function remove_liquidity(uint256 _amount, uint256[5] calldata _min_amounts) external returns (uint256[5] calldata actualWithdrawn);

    function remove_liquidity_imbalance(uint256[2] calldata _amounts, uint256 _max_burn_amount) external returns (uint256 actualBurned);
    function remove_liquidity_imbalance(uint256[3] calldata _amounts, uint256 _max_burn_amount) external returns (uint256 actualBurned);
    function remove_liquidity_imbalance(uint256[4] calldata _amounts, uint256 _max_burn_amount) external returns (uint256 actualBurned);
    function remove_liquidity_imbalance(uint256[5] calldata _amounts, uint256 _max_burn_amount) external returns (uint256 actualBurned);

    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 _min_amount) external returns (uint256 actualWithdrawn);
}

interface IMetaPool {
    function coins(uint256 i) external view returns (address);
    function base_coins(uint256 i) external view returns (address);
    function base_pool() external view returns (address);
    function exchange(int128 i, int128 j, uint256 _dx, uint256 _min_dy) external returns (uint256 actual_dy);
    function exchange_underlying(int128 i, int128 j, uint256 _dx, uint256 _min_dy) external returns (uint256 actual_dy);


    function add_liquidity(uint256[2] calldata _amounts, uint256 _min_mint_amount) external returns (uint256 actualMinted);
    function add_liquidity(uint256[3] calldata _amounts, uint256 _min_mint_amount) external returns (uint256 actualMinted);
    function add_liquidity(uint256[4] calldata _amounts, uint256 _min_mint_amount) external returns (uint256 actualMinted);
    function add_liquidity(uint256[5] calldata _amounts, uint256 _min_mint_amount) external returns (uint256 actualMinted);

    function remove_liquidity(uint256 _amount, uint256[2] calldata _min_amounts) external returns (uint256[2] calldata actualWithdrawn);
    function remove_liquidity(uint256 _amount, uint256[3] calldata _min_amounts) external returns (uint256[3] calldata actualWithdrawn);
    function remove_liquidity(uint256 _amount, uint256[4] calldata _min_amounts) external returns (uint256[4] calldata actualWithdrawn);
    function remove_liquidity(uint256 _amount, uint256[5] calldata _min_amounts) external returns (uint256[5] calldata actualWithdrawn);

    function remove_liquidity_imbalance(uint256[2] calldata _amounts, uint256 _max_burn_amount) external returns (uint256 actualBurned);
    function remove_liquidity_imbalance(uint256[3] calldata _amounts, uint256 _max_burn_amount) external returns (uint256 actualBurned);
    function remove_liquidity_imbalance(uint256[4] calldata _amounts, uint256 _max_burn_amount) external returns (uint256 actualBurned);
    function remove_liquidity_imbalance(uint256[5] calldata _amounts, uint256 _max_burn_amount) external returns (uint256 actualBurned);

    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 _min_amount) external returns (uint256 actualWithdrawn);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * Based on the OpenZeppelin IER20 interface:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
 *
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
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    
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

pragma solidity ^0.8.0;

interface IJoePair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function swap(
        uint256 _amount0In,
        uint256 _amount1Out,
        address _to,
        bytes memory _data
    ) external;
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

pragma solidity ^0.8.0;


interface IJoeRouter {
    function factory() external pure returns (address);
    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityAVAX(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountAVAX, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityAVAX(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountAVAX);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityAVAXWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountAVAX);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactAVAXForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactAVAX(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForAVAX(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapAVAXForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external returns (uint amountAVAX);
    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity ^0.8.0;

interface IMeta {
    function exchange(
        int128 i,
        int128 j,
        uint256 _dx,
        uint256 _min_dy
    ) external returns (uint256);
    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 _dx,
        uint256 _min_dy
    ) external returns (uint256);
    
}

pragma solidity 0.8.10;

/** 
 * @notice Interface for use of wrapping and unwrapping vault tokens in the Yeti Finance borrowing 
 * protocol. 
 */
interface IYetiVaultToken {
    function deposit(uint256 _amt) external returns (uint256 receiptTokens);
    function depositFor(address _borrower, uint256 _amt) external returns (uint256 receiptTokens);
    function redeem(uint256 _amt) external returns (uint256 underlyingTokens);
    function redeemFor(
        uint256 _amt,
        address _from,
        address _to
    ) external returns (uint256 underlyingTokens);
}
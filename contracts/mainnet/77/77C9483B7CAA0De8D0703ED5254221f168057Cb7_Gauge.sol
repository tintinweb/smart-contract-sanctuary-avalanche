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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "contracts/interfaces/IFeeDistributor.sol";
import "contracts/interfaces/IERC20.sol";
import "contracts/interfaces/IGauge.sol";
import "contracts/interfaces/IPair.sol";
import "contracts/interfaces/IVoter.sol";
import "contracts/interfaces/IVotingEscrow.sol";

// Gauges are used to incentivize pools, they emit reward tokens over 7 days for staked LP tokens
contract Gauge is IGauge, Initializable {
    address public stake; // the LP token that needs to be staked for rewards
    address public _ve; // the ve token used for gauges
    address public feeDistributor;
    address public voter;

    uint256 public derivedSupply;
    mapping(address => uint256) public derivedBalances;

    uint256 internal constant DURATION = 7 days; // rewards are released over 7 days
    uint256 internal constant PRECISION = 10 ** 18;

    mapping(address => uint256) public pendingRewardRate;
    mapping(address => bool) public isStarted;
    mapping(address => uint256) public rewardRate;
    mapping(address => uint256) public periodFinish;
    mapping(address => uint256) public lastUpdateTime;
    mapping(address => uint256) public rewardPerTokenStored;
    mapping(address => mapping(address => uint256)) public storedRewardsPerUser;

    mapping(address => mapping(address => uint256)) public userRewardPerTokenStored;

    mapping(address => uint256) public tokenIds;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    address[] public rewards;
    mapping(address => bool) public isReward;

    bool public isForPair;

    uint256 internal _unlocked;

    event Deposit(address indexed from, uint256 tokenId, uint256 amount);
    event Withdraw(address indexed from, uint256 tokenId, uint256 amount);
    event NotifyReward(address indexed from, address indexed reward, uint256 amount);
    event ClaimFees(address indexed from, uint256 claimed0, uint256 claimed1);
    event ClaimRewards(address indexed from, address indexed reward, uint256 amount);

    function initialize(
        address _stake,
        address _bribe,
        address __ve,
        address _voter,
        bool _forPair,
        address[] memory _allowedRewardTokens
    ) external initializer {
        stake = _stake;
        feeDistributor = _bribe;
        _ve = __ve;
        voter = _voter;
        isForPair = _forPair;

        address Snek = IVotingEscrow(__ve).token();
        rewards.push(Snek);
        isReward[Snek] = true;

        for (uint256 i; i < _allowedRewardTokens.length; ++i) {
            if (_allowedRewardTokens[i] != address(0)) {
                rewards.push(_allowedRewardTokens[i]);
                isReward[_allowedRewardTokens[i]] = true;
            }
        }

        _unlocked = 1;
    }

    // simple re-entrancy check
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    function claimFees() external lock returns (uint256 claimed0, uint256 claimed1) {
        return _claimFees();
    }

    function _claimFees() internal returns (uint256 claimed0, uint256 claimed1) {
        if (!isForPair) {
            return (0, 0);
        }
        (address _token0, address _token1) = IPair(stake).tokens();

        // check actual balances for compatibility with fee on transfer tokens.
        uint balanceBefore0 = IERC20(_token0).balanceOf(address(this));
        uint balanceBefore1 = IERC20(_token1).balanceOf(address(this));
        IPair(stake).claimFees();
        uint balanceAfter0 = IERC20(_token0).balanceOf(address(this));
        uint balanceAfter1 = IERC20(_token1).balanceOf(address(this));

        claimed0 = balanceAfter0 - balanceBefore0;
        claimed1 = balanceAfter1 - balanceBefore1;

        if (claimed0 > 0 || claimed1 > 0) {
            IERC20(_token0).approve(feeDistributor, claimed0);
            IFeeDistributor(feeDistributor).notifyRewardAmount(_token0, claimed0);

            IERC20(_token1).approve(feeDistributor, claimed1);
            IFeeDistributor(feeDistributor).notifyRewardAmount(_token1, claimed1);

            emit ClaimFees(msg.sender, claimed0, claimed1);
        }
    }

    function rewardsListLength() external view returns (uint256) {
        return rewards.length;
    }

    // returns the last time the reward was modified or periodFinish if the reward has ended
    function lastTimeRewardApplicable(address token) public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish[token]);
    }

    function earned(address token, address account) public view returns (uint256) {
        return
            (derivedBalances[account] * (rewardPerToken(token) - userRewardPerTokenStored[account][token])) /
            PRECISION +
            storedRewardsPerUser[account][token];
    }

    // Only the tokens you claim will get updated.
    function getReward(address account, address[] memory tokens) public lock {
        require(msg.sender == account || msg.sender == voter);
        _unlocked = 1;
        IVoter(voter).distribute(address(this));
        _unlocked = 2;

        // update all user rewards regardless of tokens they are claiming
        address[] memory _rewards = rewards;
        uint256 len = _rewards.length;
        for (uint256 i; i < len; ++i) {
            if (isReward[_rewards[i]]) {
                if (!isStarted[_rewards[i]]) {
                    initializeRewardsDistribution(_rewards[i]);
                }
                updateRewardPerToken(_rewards[i], account);
            }
        }
        // transfer only the rewards they are claiming
        len = tokens.length;
        for (uint256 i; i < len; ++i) {
            uint256 _reward = storedRewardsPerUser[account][tokens[i]];
            if (_reward > 0) {
                storedRewardsPerUser[account][tokens[i]] = 0;
                _safeTransfer(tokens[i], account, _reward);
                emit ClaimRewards(account, tokens[i], _reward);
            }
        }

        uint256 _derivedBalance = derivedBalances[account];
        derivedSupply -= _derivedBalance;
        _derivedBalance = derivedBalance(account);
        derivedBalances[account] = _derivedBalance;
        derivedSupply += _derivedBalance;
    }

    function rewardPerToken(address token) public view returns (uint256) {
        if (derivedSupply == 0) {
            return rewardPerTokenStored[token];
        }
        return
            rewardPerTokenStored[token] +
            (((lastTimeRewardApplicable(token) - Math.min(lastUpdateTime[token], periodFinish[token])) *
                rewardRate[token] *
                PRECISION) / derivedSupply);
    }

    function derivedBalance(address account) public view returns (uint256) {
        uint256 _tokenId = tokenIds[account];
        uint256 _balance = balanceOf[account];
        uint256 _derived = (_balance * 40) / 100;
        uint256 _adjusted = 0;
        uint256 _supply = IERC20(_ve).totalSupply();
        if (account == IVotingEscrow(_ve).ownerOf(_tokenId) && _supply > 0) {
            _adjusted = IVotingEscrow(_ve).balanceOfNFT(_tokenId);
            _adjusted = (((totalSupply * _adjusted) / _supply) * 60) / 100;
        }
        return Math.min((_derived + _adjusted), _balance);
    }

    function depositAll(uint256 tokenId) external {
        deposit(IERC20(stake).balanceOf(msg.sender), tokenId);
    }

    function deposit(uint256 amount, uint256 tokenId) public lock {
        require(amount > 0);

        address[] memory _rewards = rewards;
        uint256 len = _rewards.length;

        for (uint256 i; i < len; ++i) {
            if (!isStarted[_rewards[i]]) {
                initializeRewardsDistribution(_rewards[i]);
            }
            updateRewardPerToken(_rewards[i], msg.sender);
        }

        _safeTransferFrom(stake, msg.sender, address(this), amount);
        totalSupply += amount;
        balanceOf[msg.sender] += amount;

        if (tokenId > 0) {
            require(IVotingEscrow(_ve).ownerOf(tokenId) == msg.sender);
            if (tokenIds[msg.sender] == 0) {
                tokenIds[msg.sender] = tokenId;
                IVoter(voter).attachTokenToGauge(tokenId, msg.sender);
            }
            require(tokenIds[msg.sender] == tokenId);
        } else {
            tokenId = tokenIds[msg.sender];
        }

        uint256 _derivedBalance = derivedBalances[msg.sender];
        derivedSupply -= _derivedBalance;
        _derivedBalance = derivedBalance(msg.sender);
        derivedBalances[msg.sender] = _derivedBalance;
        derivedSupply += _derivedBalance;

        IVoter(voter).emitDeposit(tokenId, msg.sender, amount);
        emit Deposit(msg.sender, tokenId, amount);
    }

    function withdrawAll() external {
        withdraw(balanceOf[msg.sender]);
    }

    function withdraw(uint256 amount) public {
        uint256 tokenId = 0;
        if (amount == balanceOf[msg.sender]) {
            tokenId = tokenIds[msg.sender];
        }
        withdrawToken(amount, tokenId);
    }

    function withdrawToken(uint256 amount, uint256 tokenId) public lock {
        require(amount > 0);

        address[] memory _rewards = rewards;
        uint256 len = _rewards.length;

        for (uint256 i; i < len; ++i) {
            updateRewardPerToken(_rewards[i], msg.sender);
        }

        totalSupply -= amount;
        balanceOf[msg.sender] -= amount;
        _safeTransfer(stake, msg.sender, amount);

        if (tokenId > 0) {
            require(tokenId == tokenIds[msg.sender]);
            tokenIds[msg.sender] = 0;
            IVoter(voter).detachTokenFromGauge(tokenId, msg.sender);
        } else {
            tokenId = tokenIds[msg.sender];
        }

        uint256 _derivedBalance = derivedBalances[msg.sender];
        derivedSupply -= _derivedBalance;
        _derivedBalance = derivedBalance(msg.sender);
        derivedBalances[msg.sender] = _derivedBalance;
        derivedSupply += _derivedBalance;

        IVoter(voter).emitWithdraw(tokenId, msg.sender, amount);
        emit Withdraw(msg.sender, tokenId, amount);
    }

    function left(address token) external view returns (uint256) {
        if (block.timestamp >= periodFinish[token]) return 0;
        uint256 _remaining = periodFinish[token] - block.timestamp;
        return _remaining * rewardRate[token];
    }

    // @dev rewardRate and periodFinish is set on first deposit if totalSupply == 0 or first interaction after whitelisting. If msg.sender == governance and totalSupply > 0 reward is started immediately.
    function notifyRewardAmount(address token, uint256 amount) external lock {
        require(token != stake);
        require(amount > 0);
        rewardPerTokenStored[token] = rewardPerToken(token);
        _claimFees();
        // Check actual amount transferred for compatibility with fee on transfer tokens.
        uint balanceBefore = IERC20(token).balanceOf(address(this));
        _safeTransferFrom(token, msg.sender, address(this), amount);
        uint balanceAfter = IERC20(token).balanceOf(address(this));
        amount = balanceAfter - balanceBefore;
        uint _rewardRate = amount / DURATION;

        if (isStarted[token]) {
            if (block.timestamp >= periodFinish[token]) {
                rewardRate[token] = _rewardRate;
            } else {
                uint256 _remaining = periodFinish[token] - block.timestamp;
                uint256 _left = _remaining * rewardRate[token];
                require(amount > _left);
                rewardRate[token] = (amount + _left) / DURATION;
            }
            periodFinish[token] = block.timestamp + DURATION;
            lastUpdateTime[token] = block.timestamp;
        } else {
            if (pendingRewardRate[token] > 0) {
                uint256 _left = DURATION * pendingRewardRate[token];
                pendingRewardRate[token] = (amount + _left) / DURATION;
            } else {
                pendingRewardRate[token] = _rewardRate;
            }
        }
        if (msg.sender == voter) {
            if (!isReward[token]) {
                isReward[token] = true;
                rewards.push(token);
            }
            if (!isStarted[token] && totalSupply > 0) {
                initializeRewardsDistribution(token);
            }
        }
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(rewardRate[token] <= balance / DURATION, "Provided reward too high");
        if (!isStarted[token]) {
            require(pendingRewardRate[token] <= balance / DURATION, "Provided reward too high");
        }

        emit NotifyReward(msg.sender, token, amount);
    }

    function initializeRewardsDistribution(address token) internal {
        isStarted[token] = true;
        rewardRate[token] = pendingRewardRate[token];
        lastUpdateTime[token] = block.timestamp;
        periodFinish[token] = block.timestamp + DURATION;
        pendingRewardRate[token] = 0;
    }

    function whitelistNotifiedRewards(address token) external {
        require(msg.sender == voter);
        if (!isReward[token]) {
            isReward[token] = true;
            rewards.push(token);
        }
        if (!isStarted[token] && totalSupply > 0) {
            initializeRewardsDistribution(token);
        }
    }

    function getRewardTokenIndex(address token) public view returns (uint256) {
        address[] memory _rewards = rewards;
        uint256 len = _rewards.length;

        for (uint256 i; i < len; ++i) {
            if (_rewards[i] == token) {
                return i;
            }
        }
        return 0;
    }

    function removeRewardWhitelist(address token) external {
        require(msg.sender == voter);
        if (!isReward[token]) {
            return;
        }
        isReward[token] = false;
        uint256 idx = getRewardTokenIndex(token);
        uint256 len = rewards.length;
        for (uint256 i = idx; i < len - 1; ++i) {
            rewards[i] = rewards[i + 1];
        }
        rewards.pop();
    }

    function poke(address account) external {
        // Update reward rates and user rewards
        for (uint256 i; i < rewards.length; ++i) {
            updateRewardPerToken(rewards[i], account);
        }
        // Update user boosted balance and total boosted balance
        uint256 _derivedBalance = derivedBalances[account];
        derivedSupply -= _derivedBalance;
        _derivedBalance = derivedBalance(account);
        derivedBalances[account] = _derivedBalance;
        derivedSupply += _derivedBalance;
    }

    function updateRewardPerToken(address token, address account) internal {
        rewardPerTokenStored[token] = rewardPerToken(token);
        lastUpdateTime[token] = lastTimeRewardApplicable(token);
        storedRewardsPerUser[account][token] = earned(token, account);
        userRewardPerTokenStored[account][token] = rewardPerTokenStored[token];
    }

    function _safeTransfer(address token, address to, uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function _safeApprove(address token, address spender, uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, spender, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint amount) external returns (bool);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function balanceOf(address) external view returns (uint);

    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IFeeDistributor {
    function _deposit(uint amount, uint tokenId) external;

    function _withdraw(uint amount, uint tokenId) external;

    function getRewardForOwner(uint tokenId, address[] memory tokens) external;

    function notifyRewardAmount(address token, uint amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IGauge {
    function notifyRewardAmount(address token, uint amount) external;

    function getReward(address account, address[] memory tokens) external;

    function claimFees() external returns (uint claimed0, uint claimed1);

    function left(address token) external view returns (uint);

    function isForPair() external view returns (bool);

    function whitelistNotifiedRewards(address token) external;

    function removeRewardWhitelist(address token) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IPair {
    function initialize(address _token0, address _token1, bool _stable) external;

    function metadata()
        external
        view
        returns (uint256 dec0, uint256 dec1, uint256 r0, uint256 r1, bool st, address t0, address t1);

    function claimFees() external returns (uint256, uint256);

    function tokens() external returns (address, address);

    function transferFrom(address src, address dst, uint256 amount) external returns (bool);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function mint(address to) external returns (uint256 liquidity);

    function getReserves() external view returns (uint256 _reserve0, uint256 _reserve1, uint256 _blockTimestampLast);

    function getAmountOut(uint256, address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IVoter {
    function _ve() external view returns (address);

    function governor() external view returns (address);

    function emergencyCouncil() external view returns (address);

    function attachTokenToGauge(uint _tokenId, address account) external;

    function detachTokenFromGauge(uint _tokenId, address account) external;

    function emitDeposit(uint _tokenId, address account, uint amount) external;

    function emitWithdraw(uint _tokenId, address account, uint amount) external;

    function isWhitelisted(address token) external view returns (bool);

    function notifyRewardAmount(uint amount) external;

    function distribute(address _gauge) external;

    function gauges(address pool) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IVotingEscrow {
    struct Point {
        int128 bias;
        int128 slope; // # -dweight / dt
        uint256 ts;
        uint256 blk; // block
    }

    function token() external view returns (address);

    function team() external returns (address);

    function epoch() external view returns (uint);

    function point_history(uint loc) external view returns (Point memory);

    function user_point_history(uint tokenId, uint loc) external view returns (Point memory);

    function user_point_epoch(uint tokenId) external view returns (uint);

    function ownerOf(uint) external view returns (address);

    function isApprovedOrOwner(address, uint) external view returns (bool);

    function transferFrom(address, address, uint) external;

    function voting(uint tokenId) external;

    function abstain(uint tokenId) external;

    function attach(uint tokenId) external;

    function detach(uint tokenId) external;

    function checkpoint() external;

    function deposit_for(uint tokenId, uint value) external;

    function create_lock_for(uint, uint, address) external returns (uint);

    function balanceOfNFT(uint) external view returns (uint);

    function balanceOfNFTAt(uint, uint) external view returns (uint);

    function totalSupply() external view returns (uint);

    function locked__end(uint) external view returns (uint);
}
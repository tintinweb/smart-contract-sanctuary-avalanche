// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./interfaces/IYakStrategy.sol";
// import "../../../lib/SafeERC20.sol";
// import "../../../lib/SafeMath.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./interfaces/IGmxDepositor.sol";
import "./interfaces/IGmxRewardRouter.sol";
import "./interfaces/IGmxRewardTracker.sol";
import "./interfaces/IGmxProxy.sol";

library SafeProxy {
    function safeExecute(
        IGmxDepositor gmxDepositor,
        address target,
        uint256 value,
        bytes memory data
    ) internal returns (bytes memory) {
        (bool success, bytes memory returnValue) = gmxDepositor.execute(target, value, data);
        if (!success) revert("GmxProxy::safeExecute failed");
        return returnValue;
    }
}

contract GmxProxy is IGmxProxy {
    using SafeMath for uint256;
    using SafeProxy for IGmxDepositor;
    using SafeERC20 for IERC20;

    uint256 internal constant BIPS_DIVISOR = 10000;

    address internal constant GMX = 0x45bf1E34b309bC2214470d86967537728FE9A2E5;     // 0x62edc0692BD897D2295872a9FFCac5425011c661
    address internal constant fsGLP = 0xb98C334C21B1e47dB0A5d5796f0F8Cb16d2d9DFA;   // 0x5643F4b25E36478eE1E90418d5343cb6591BcB9d
    address internal constant WAVAX = 0x52B654763F016dAF087d163c9EB6c7F486261019;   // 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7
    address internal constant esGMX = 0x1294439f915f7a9182De6Ad961699C175Be041C9;   // 0xFf1489227BbAAC61a9209A08929E4c2a526DdD17

    address public devAddr;
    mapping(address => address) public approvedStrategies;

    IGmxDepositor public immutable override gmxDepositor;
    address public immutable override gmxRewardRouter;
    address public immutable glpMinter;

    address public immutable gmxRewardTracker;
    address public immutable glpManager;

    modifier onlyDev() {
        require(msg.sender == devAddr, "GmxProxy::onlyDev");
        _;
    }

    modifier onlyStrategy() {
        require(
            approvedStrategies[fsGLP] == msg.sender || approvedStrategies[GMX] == msg.sender,
            "GmxProxy:onlyGLPStrategy"
        );
        _;
    }

    modifier onlyGLPStrategy() {
        require(approvedStrategies[fsGLP] == msg.sender, "GmxProxy:onlyGLPStrategy");
        _;
    }

    modifier onlyGMXStrategy() {
        require(approvedStrategies[GMX] == msg.sender, "GmxProxy::onlyGMXStrategy");
        _;
    }

    constructor(
        address _gmxDepositor,
        address _gmxRewardRouter,           // 
        address _gmxRewardRouterV2,
        address _devAddr
    ) {
        require(_gmxDepositor > address(0), "GmxProxy::Invalid depositor address provided");
        require(_gmxRewardRouter > address(0), "GmxProxy::Invalid reward router address provided");
        require(_devAddr > address(0), "GmxProxy::Invalid dev address provided");
        devAddr = _devAddr;
        gmxDepositor = IGmxDepositor(_gmxDepositor);
        gmxRewardRouter = _gmxRewardRouter;
        glpMinter = _gmxRewardRouterV2;
        gmxRewardTracker = IGmxRewardRouter(_gmxRewardRouter).stakedGmxTracker();
        glpManager = IGmxRewardRouter(_gmxRewardRouterV2).glpManager();
    }

    function updateDevAddr(address newValue) public onlyDev {
        require(newValue > address(0), "GmxProxy::Invalid dev address provided");
        devAddr = newValue;
    }

    function approveStrategy(address _strategy) external onlyDev {
        address depositToken = IYakStrategy(_strategy).depositToken();
        // require(approvedStrategies[depositToken] == address(0), "GmxProxy::Strategy for deposit token already added");
        approvedStrategies[depositToken] = _strategy;
    }

    function stakeESGMX() external onlyDev {
        gmxDepositor.safeExecute(
            gmxRewardRouter,
            0,
            abi.encodeWithSignature("stakeEsGmx(uint256)", IERC20(esGMX).balanceOf(address(gmxDepositor)))
        );
    }

    function stakedESGMX() public view returns (uint256) {
        return IGmxRewardTracker(gmxRewardTracker).depositBalances(address(gmxDepositor), esGMX);
    }

    function buyAndStakeGlp(uint256 _amount) external override onlyGLPStrategy returns (uint256) {
        IERC20(WAVAX).safeTransfer(address(gmxDepositor), _amount);
        gmxDepositor.safeExecute(WAVAX, 0, abi.encodeWithSignature("approve(address,uint256)", glpManager, _amount));
        bytes memory result = gmxDepositor.safeExecute(
            glpMinter,
            0,
            abi.encodeWithSignature("mintAndStakeGlp(address,uint256,uint256,uint256)", WAVAX, _amount, 0, 0)
        );
        gmxDepositor.safeExecute(WAVAX, 0, abi.encodeWithSignature("approve(address,uint256)", glpManager, 0));
        return toUint256(result, 0);
    }

    function withdrawGlp(uint256 _amount) external override onlyGLPStrategy {
        _withdrawGlp(_amount);
    }

    function _withdrawGlp(uint256 _amount) private {
        gmxDepositor.safeExecute(fsGLP, 0, abi.encodeWithSignature("transfer(address,uint256)", msg.sender, _amount));
    }

    function stakeGmx(uint256 _amount) external override onlyGMXStrategy {
        IERC20(GMX).safeTransfer(address(gmxDepositor), _amount);
        gmxDepositor.safeExecute(
            GMX,
            0,
            abi.encodeWithSignature("approve(address,uint256)", gmxRewardTracker, _amount)
        );
        gmxDepositor.safeExecute(gmxRewardRouter, 0, abi.encodeWithSignature("stakeGmx(uint256)", _amount));
        gmxDepositor.safeExecute(GMX, 0, abi.encodeWithSignature("approve(address,uint256)", gmxRewardTracker, 0));
    }

    function withdrawGmx(uint256 _amount) external override onlyGMXStrategy {
        _withdrawGmx(_amount);
    }

    function _withdrawGmx(uint256 _amount) private {
        gmxDepositor.safeExecute(gmxRewardRouter, 0, abi.encodeWithSignature("unstakeGmx(uint256)", _amount));
        gmxDepositor.safeExecute(GMX, 0, abi.encodeWithSignature("transfer(address,uint256)", msg.sender, _amount));
    }

    function pendingRewards(address _rewardTracker) external view override returns (uint256) {
        address feeGmxTracker = IGmxRewardRouter(gmxRewardRouter).feeGmxTracker();
        if (_rewardTracker == feeGmxTracker) return 0;

        return
            IGmxRewardTracker(IGmxRewardRouter(gmxRewardRouter).feeGlpTracker()).claimable(address(gmxDepositor)) +
            IGmxRewardTracker(feeGmxTracker).claimable(address(gmxDepositor));
    }

    function claimReward(address rewardTracker) external override onlyStrategy {
        address feeGmxTracker = IGmxRewardRouter(gmxRewardRouter).feeGmxTracker();
        if (rewardTracker == feeGmxTracker) return;
        gmxDepositor.safeExecute(
            gmxRewardRouter,
            0,
            abi.encodeWithSignature(
                "handleRewards(bool,bool,bool,bool,bool,bool,bool)",
                false,
                false,
                true,
                true,
                true,
                true,
                false
            )
        );
        uint256 reward = IERC20(WAVAX).balanceOf(address(gmxDepositor));
        gmxDepositor.safeExecute(WAVAX, 0, abi.encodeWithSignature("transfer(address,uint256)", msg.sender, reward));
    }

    function totalDeposits(address _rewardTracker) external view override returns (uint256) {
        address depositToken = IYakStrategy(msg.sender).depositToken();
        if (depositToken == GMX) {
            address rewardTracker = IGmxRewardRouter(gmxRewardRouter).stakedGmxTracker();
            return IGmxRewardTracker(rewardTracker).depositBalances(address(gmxDepositor), depositToken);
        }
        return IGmxRewardTracker(_rewardTracker).stakedAmounts(address(gmxDepositor));
    }

    function emergencyWithdrawGLP(uint256 _balance) external override onlyGLPStrategy {
        _withdrawGlp(_balance);
    }

    function emergencyWithdrawGMX(uint256 _balance) external override onlyGMXStrategy {
        _withdrawGmx(_balance);
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IGmxDepositor {
    function execute(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool, bytes memory);

    function setGmxProxy(address _proxy) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./IGmxDepositor.sol";

interface IGmxProxy {
    function gmxDepositor() external view returns (IGmxDepositor);

    function gmxRewardRouter() external view returns (address);

    function buyAndStakeGlp(uint256 _amount) external returns (uint256);

    function withdrawGlp(uint256 _amount) external;

    function stakeGmx(uint256 _amount) external;

    function withdrawGmx(uint256 _amount) external;

    function pendingRewards(address _rewardTracker) external view returns (uint256);

    function claimReward(address _rewardTracker) external;

    function totalDeposits(address _rewardTracker) external view returns (uint256);

    function emergencyWithdrawGLP(uint256 _balance) external;

    function emergencyWithdrawGMX(uint256 _balance) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IGmxRewardRouter {
    function stakedGmxTracker() external view returns (address);

    function bonusGmxTracker() external view returns (address);

    function feeGmxTracker() external view returns (address);

    function stakedGlpTracker() external view returns (address);

    function feeGlpTracker() external view returns (address);

    function glpManager() external view returns (address);

    function mintAndStakeGlp(
        address _token,
        uint256 _amount,
        uint256 _minUsdg,
        uint256 _minGlp
    ) external returns (uint256);

    function handleRewards(
        bool _shouldClaimGmx,
        bool _shouldStakeGmx,
        bool _shouldClaimEsGmx,
        bool _shouldStakeEsGmx,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWeth,
        bool _shouldConvertWethToEth
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IGmxRewardTracker {
    function depositBalances(address _account, address _depositToken) external view returns (uint256);

    function stakedAmounts(address _account) external view returns (uint256);

    function updateRewards() external;

    function stake(address _depositToken, uint256 _amount) external;

    function stakeForAccount(
        address _fundingAccount,
        address _account,
        address _depositToken,
        uint256 _amount
    ) external;

    function unstake(address _depositToken, uint256 _amount) external;

    function unstakeForAccount(
        address _account,
        address _depositToken,
        uint256 _amount,
        address _receiver
    ) external;

    function tokensPerInterval() external view returns (uint256);

    function claim(address _receiver) external returns (uint256);

    function claimForAccount(address _account, address _receiver) external returns (uint256);

    function claimable(address _account) external view returns (uint256);

    function averageStakedAmounts(address _account) external view returns (uint256);

    function cumulativeRewards(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IYakStrategy {
    function depositToken() external view returns (address);

    function depositFor(address account, uint256 amount) external;
}
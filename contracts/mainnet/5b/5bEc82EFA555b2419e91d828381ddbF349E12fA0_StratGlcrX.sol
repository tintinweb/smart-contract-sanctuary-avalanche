// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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
}

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IGlacierRouter.sol";
import "./interfaces/IGlacierGauge.sol";

contract _StratBase is Ownable, Pausable {
    using SafeERC20 for IERC20;

    // Tokens
    address public constant wavax = address(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);
    address public constant glcr = address(0x3712871408a829C5cd4e86DA1f4CE727eFCD28F6);
    address public want;
    address public feeToken;
    address[] public rewardTokens;

    // Third party contracts
    address public gauge;
    address public router;

    // Strategy addresses
    address public xexadons     = address(0x8eD98Eeb0c360d1b7C8ab5e85Dc792A1e4B18D8c);
    address public team         = address(0x04345e22cd5781C8264A611c056DDFA8bbCddfA4);
    address public sentinel     = address(0xb494596247E9068be1b042dB2f6E74E7fc85BE32);
    address public strategist;
    address public vault;

    //Routes
    IGlacierRouter.Routes[] public feeTokenPath;
    IGlacierRouter.Routes[] public customPath;

    // Controllers
    bool public stable = false;
    bool public harvestOnDeposit;

    // Fee structure
    uint256 public constant FEE_DIVISOR = 1000;
    uint256 public PLATFORM_FEE = 100;               // 10% Platform fee
    uint256 public WITHDRAW_FEE = 1;                 // 0.1% of withdrawal amount
    uint256 public XEXADON_FEE = 350;   // 3.5%  // Fee to xexadons
    uint256 public STRAT_FEE = 200;     // 2.0%  // Fee to Strategist
    uint256 public TEAM_FEE = 350;      // 3.5%  // Fee to team
    uint256 public CALL_FEE = 100;      // 1.0%  // Fee to caller for calling harvest

    // Events
    event Harvest(address indexed harvester);
    event SetVault(address indexed newVault);
    event SetStrategist(address indexed newStrategist);
    event SetTeam(address indexed newRecipient);
    event SetXexadon(address indexed newRecipient);
    event SetFeeToken(address indexed newFeeToken);
    event RetireStrat(address indexed caller);
    event Panic(address indexed caller);
    event MakeCustomTxn(address indexed from, address indexed to, uint256 indexed amount);
    event SetFees(uint256 indexed withdrawFee, uint256 indexed totalFees);
    
    constructor(
        address _want,
        address _gauge,
        address _router,
        address _feeToken,
        IGlacierRouter.Routes[] memory _feeTokenPath
    ) {
        strategist = msg.sender;
        want = _want;
        gauge = _gauge;
        router = _router;
        feeToken = _feeToken;

        for (uint i; i < _feeTokenPath.length; ++i) {
            feeTokenPath.push(_feeTokenPath[i]);
        }

        rewardTokens.push(glcr);
        harvestOnDeposit = false;
    }

    /** @dev Function to synchronize balances before new user deposit. Can be overridden in the strategy. */
    function beforeDeposit() external whenNotPaused {
        require(msg.sender == vault, "!vault");
        if (harvestOnDeposit) {
            _harvest(tx.origin);
        }
    }

    /** @dev Deposits funds into the masterchef */
    function deposit() public whenNotPaused {
        require(msg.sender == vault, "!vault");

        if (balanceOfPool() == 0 || !harvestOnDeposit) {
            _deposit();
        } else {
            _deposit();
            _harvest(msg.sender);
        }
    }

    function _deposit() internal whenNotPaused {
        uint256 wantBal = IERC20(want).balanceOf(address(this));
        IGlacierGauge(gauge).deposit(wantBal, 0);
    }

    function withdraw(uint256 _amount) external {
        require(msg.sender == vault, "!vault");

        uint256 wantBal = IERC20(want).balanceOf(address(this));

        if (wantBal < _amount) {
            IGlacierGauge(gauge).withdraw(_amount - wantBal);
            wantBal = IERC20(want).balanceOf(address(this));
        }

        if (wantBal > _amount) {
            wantBal = _amount;
        }

        uint256 withdrawalFeeAmount = wantBal * WITHDRAW_FEE / FEE_DIVISOR;
        IERC20(want).safeTransfer(vault, wantBal - withdrawalFeeAmount);
    }

    function harvest() external {
        require(msg.sender == tx.origin, "!EOA");
        _harvest(msg.sender);
    }

    /** @dev Compounds the strategy's earnings and charges fees */
    function _harvest(address caller) internal whenNotPaused {
        if (caller != vault){
            require(!Address.isContract(msg.sender), "!EOA");
        }

        IGlacierGauge(gauge).getReward(address(this), rewardTokens);
        uint256 outputBal = IERC20(glcr).balanceOf(address(this));

        if (outputBal > 0 ) {
            chargeFees(caller);
            addLiquidity();
        }
        _deposit();

        emit Harvest(caller);
    }

    /** @dev This function converts charges fees in selected feeToken and sends to respective accounts */
    function chargeFees(address caller) internal {
        uint256 toFee = IERC20(glcr).balanceOf(address(this)) * PLATFORM_FEE / FEE_DIVISOR;

        if(feeToken != glcr){
            IGlacierRouter(router).swapExactTokensForTokens(toFee, 0, feeTokenPath, address(this), block.timestamp);
        }

        uint256 feeBal = IERC20(feeToken).balanceOf(address(this));

        if(feeToken == glcr){
            distroRewardFee(feeBal, caller);
        }else{ 
            distroFee(feeBal, caller); 
        }
    }

    /** @dev Converts reward to both sides of the LP token and builds the liquidity pair */
    function addLiquidity() virtual internal {}

    /** @dev Determines the amount of reward in WFTM upon calling the harvest function */
    function callReward() public view returns (uint256) {
        uint256 outputBal = rewardBalance();
        uint256 wrappedOut;
        if (outputBal > 0) {
            (wrappedOut,) = IGlacierRouter(router).getAmountOut(outputBal, glcr, wavax);
        }
        return wrappedOut * PLATFORM_FEE / FEE_DIVISOR * CALL_FEE / FEE_DIVISOR;
    }

    // returns rewards unharvested
    function rewardBalance() public view returns (uint256) {
        return IGlacierGauge(gauge).earned(glcr, address(this));
    }

    /** @dev calculate the total underlying 'want' held by the strat */
    function balanceOf() public view returns (uint256) {
        return balanceOfWant() + (balanceOfPool());
    }

    /** @dev it calculates how much 'want' this contract holds */
    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    /** @dev it calculates how much 'want' the strategy has working in the farm */
    function balanceOfPool() public view returns (uint256) {
        return IGlacierGauge(gauge).balanceOf(address(this));
    }

    /** @dev called as part of strat migration. Sends all the available funds back to the vault */
    function retireStrat() external {
        require(msg.sender == vault, "!vault");
        _harvest(msg.sender);
        IGlacierGauge(gauge).withdraw(balanceOfPool());
        IERC20(want).transfer(vault, balanceOfWant());

        emit RetireStrat(msg.sender);
    }

    /** @dev Pauses the strategy contract and executes the emergency withdraw function */
    function panic() external {
        require(msg.sender == strategist || msg.sender == owner() || msg.sender == sentinel, "!auth");
        pause();
        IGlacierGauge(gauge).withdraw(balanceOfPool());
        emit Panic(msg.sender);
    }

    /** @dev Pauses the strategy contract */
    function pause() public {
        require(msg.sender == strategist || msg.sender == owner() || msg.sender == sentinel, "!auth");
        _pause();
        _subAllowance();
    }

    /** @dev Unpauses the strategy contract */
    function unpause() external {
        require(msg.sender == strategist || msg.sender == owner() || msg.sender == sentinel, "!auth");
        _unpause();
        _addAllowance();
        _deposit();
    }

    /** @dev Removes allowances to spenders */
    function _subAllowance() virtual internal {}

    function _addAllowance() virtual internal {}

    /** @dev This function exists incase tokens that do not match the {want} of this strategy accrue.  For example: an amount of
    tokens sent to this address in the form of an airdrop of a different token type. This will allow Grim to convert
    said token to the {output} token of the strategy, allowing the amount to be paid out to stakers in the next harvest. */
    function makeCustomTxn(address [][] memory _tokens, bool[] calldata _stable) external onlyAdmin {
        for (uint i; i < _tokens.length; ++i) {
            customPath.push(IGlacierRouter.Routes({
                from: _tokens[i][0],
                to: _tokens[i][1],
                stable: _stable[i]
            }));
        }
        uint256 bal = IERC20(_tokens[0][0]).balanceOf(address(this));

        IERC20(_tokens[0][0]).safeApprove(router, 0);
        IERC20(_tokens[0][0]).safeApprove(router, type(uint).max);
        IGlacierRouter(router).swapExactTokensForTokens(bal, 0, customPath, address(this), block.timestamp + 600);

        emit MakeCustomTxn(_tokens[0][0], _tokens[0][_tokens.length - 1], bal);
    }

    function distroFee(uint256 feeBal, address caller) internal {
        uint256 callFee = feeBal * CALL_FEE / FEE_DIVISOR;
        IERC20(feeToken).safeTransfer(caller, callFee);

        uint256 teamFee = feeBal * TEAM_FEE / FEE_DIVISOR;
        IERC20(feeToken).safeTransfer(team, teamFee);

        uint256 xexadonsFee = feeBal * XEXADON_FEE / FEE_DIVISOR;
        IERC20(feeToken).safeTransfer(xexadons, xexadonsFee);

        uint256 stratFee = feeBal * STRAT_FEE / FEE_DIVISOR;
        IERC20(feeToken).safeTransfer(strategist, stratFee);
    }

    function distroRewardFee(uint256 feeBal, address caller) internal {
        uint256 rewardFee = feeBal * PLATFORM_FEE / FEE_DIVISOR;

        uint256 callFee = rewardFee * CALL_FEE / FEE_DIVISOR;
        IERC20(feeToken).safeTransfer(caller, callFee);

        uint256 teamFee = rewardFee * TEAM_FEE / FEE_DIVISOR;
        IERC20(feeToken).safeTransfer(team, teamFee);

        uint256 xexadonsFee = rewardFee * XEXADON_FEE / FEE_DIVISOR;
        IERC20(feeToken).safeTransfer(xexadons, xexadonsFee);

        uint256 stratFee = rewardFee * STRAT_FEE / FEE_DIVISOR;
        IERC20(feeToken).safeTransfer(strategist, stratFee);
    }


    // Sets the fee amounts
    function setFees(uint256 newPlatformFee, uint256 newCallFee, uint256 newStratFee, uint256 newWithdrawFee, uint256 newXexadonsFee, uint256 newTeamFee) external onlyAdmin {
        require(newWithdrawFee <= 10, "> Max Fee");
        uint256 sum = newCallFee + newStratFee + newXexadonsFee + newTeamFee;
        require(sum <= FEE_DIVISOR, "> Fee Div");

        PLATFORM_FEE = newPlatformFee;
        CALL_FEE = newCallFee;
        STRAT_FEE = newStratFee;
        WITHDRAW_FEE = newWithdrawFee;
        XEXADON_FEE = newXexadonsFee;
        TEAM_FEE = newTeamFee;

        emit SetFees(newWithdrawFee, sum);
    }

    function setAddress(uint256 which, address newAddress) external onlyAdmin {
        if (which == 1) {
            vault = newAddress;
            emit SetVault(newAddress);

        } else if (which == 2) {
            team = newAddress;
            emit SetTeam(newAddress);

        } else if (which == 3) {
            xexadons = newAddress;
            emit SetXexadon(newAddress);

        } else if (which == 4) {
            require(msg.sender == strategist, "!auth");
            strategist = newAddress;
            emit SetStrategist(newAddress);
        }
    }

    // Sets harvestOnDeposit
    function setHarvestOnDeposit(bool _harvestOnDeposit) external onlyAdmin {
        harvestOnDeposit = _harvestOnDeposit;
    }

    // Checks that caller is either owner or strategist
    modifier onlyAdmin() {
        require(msg.sender == owner() || msg.sender == strategist, "!auth");
        _;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IGlacierGauge {
    function deposit(uint256 amount, uint256 pid) external;
    function withdraw(uint256 amount) external;
    function getReward(address user, address[] memory rewards) external;
    function earned(address token, address user) external view returns (uint256);
    function balanceOf(address user) external view returns (uint256);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IGlacierRouter {

    // Routes
    struct Routes {
        address from;
        address to;
        bool stable;
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        bool stable,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        bool stable,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokensSimple(
        uint amountIn,
        uint amountOutMin,
        address tokenFrom,
        address tokenTo,
        bool stable,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

     function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        Routes[] memory route,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

       function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        Routes[] memory route,
        address to,
        uint deadline
    ) external;

    function getAmountOut(uint amountIn, address tokenIn, address tokenOut) external view returns (uint amount, bool stable);
    function getAmountsOut(uint amountIn, Routes[] memory routes) external view returns (uint[] memory amounts);

    function quoteAddLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint amountADesired,
        uint amountBDesired
    ) external view returns (uint amountA, uint amountB, uint liquidity);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// import "./interfaces/IGlacierRouter.sol";
import "./_StratBase.sol";

contract StratGlcrX is _StratBase {
  using SafeERC20 for IERC20;

  IGlacierRouter.Routes[] public glcrToXPath;
  address public tokenX;
  
  constructor(
      address _want,
      address _gauge,
      address _router,
      address _feeToken,
      address _tokenX,
      IGlacierRouter.Routes[] memory _glcrToXPath,
      IGlacierRouter.Routes[] memory _feeTokenPath
  ) _StratBase (
    _want,
    _gauge,
    _router,
    _feeToken,
    _feeTokenPath
  ) {
    tokenX = _tokenX;

    for (uint i; i < _glcrToXPath.length; ++i) {
        glcrToXPath.push(_glcrToXPath[i]);
    }

    _addAllowance();
  }

  function addLiquidity() override internal {
    uint256 glcrHalf = IERC20(glcr).balanceOf(address(this)) / 2;

    IGlacierRouter(router).swapExactTokensForTokens(glcrHalf, 0, glcrToXPath, address(this), block.timestamp);

    uint256 t1Bal = IERC20(glcr).balanceOf(address(this));
    uint256 t2Bal = IERC20(tokenX).balanceOf(address(this));
    
    IGlacierRouter(router).addLiquidity(glcr, tokenX, stable, t1Bal, t2Bal, 1, 1, address(this), block.timestamp);
  }

  function _subAllowance() override virtual internal {
    IERC20(want).safeApprove(gauge, 0);
    IERC20(glcr).safeApprove(router, 0);
    IERC20(wavax).safeApprove(router, 0);
    if (tokenX != wavax && tokenX != glcr)
      IERC20(tokenX).safeApprove(router, 0);
  }

  function _addAllowance() override virtual internal {
    IERC20(want).safeApprove(gauge, type(uint).max);
    IERC20(glcr).safeApprove(router, type(uint).max);
    IERC20(wavax).safeApprove(router, type(uint).max);
    if (tokenX != wavax && tokenX != glcr)
      IERC20(tokenX).safeApprove(router, type(uint).max);
  }
}
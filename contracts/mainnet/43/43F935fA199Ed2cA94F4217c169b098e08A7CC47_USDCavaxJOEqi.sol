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
        __Context_init_unchained();
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
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
    function transferFrom(
        address sender,
        address recipient,
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./IComptroller.sol";
import "./InterestRateModel.sol";

interface ICTokenStorage {
	/**
	 * @dev Container for borrow balance information
	 * @member principal Total balance (with accrued interest), after applying the most recent balance-changing action
	 * @member interestIndex Global borrowIndex as of the most recent balance-changing action
	 */
	struct BorrowSnapshot {
		uint256 principal;
		uint256 interestIndex;
	}
}

interface ICToken is ICTokenStorage {
	/*** Market Events ***/

	/**
	 * @dev Event emitted when interest is accrued
	 */
	event AccrueInterest(
		uint256 cashPrior,
		uint256 interestAccumulated,
		uint256 borrowIndex,
		uint256 totalBorrows
	);

	/**
	 * @dev Event emitted when tokens are minted
	 */
	event Mint(address minter, uint256 mintAmount, uint256 mintTokens);

	/**
	 * @dev Event emitted when tokens are redeemed
	 */
	event Redeem(address redeemer, uint256 redeemAmount, uint256 redeemTokens);

	/**
	 * @dev Event emitted when underlying is borrowed
	 */
	event Borrow(
		address borrower,
		uint256 borrowAmount,
		uint256 accountBorrows,
		uint256 totalBorrows
	);

	/**
	 * @dev Event emitted when a borrow is repaid
	 */
	event RepayBorrow(
		address payer,
		address borrower,
		uint256 repayAmount,
		uint256 accountBorrows,
		uint256 totalBorrows
	);

	/**
	 * @dev Event emitted when a borrow is liquidated
	 */
	event LiquidateBorrow(
		address liquidator,
		address borrower,
		uint256 repayAmount,
		address cTokenCollateral,
		uint256 seizeTokens
	);

	/*** Admin Events ***/

	/**
	 * @dev Event emitted when pendingAdmin is changed
	 */
	event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

	/**
	 * @dev Event emitted when pendingAdmin is accepted, which means admin is updated
	 */
	event NewAdmin(address oldAdmin, address newAdmin);

	/**
	 * @dev Event emitted when comptroller is changed
	 */
	event NewComptroller(IComptroller oldComptroller, IComptroller newComptroller);

	/**
	 * @dev Event emitted when interestRateModel is changed
	 */
	event NewMarketInterestRateModel(
		InterestRateModel oldInterestRateModel,
		InterestRateModel newInterestRateModel
	);

	/**
	 * @dev Event emitted when the reserve factor is changed
	 */
	event NewReserveFactor(uint256 oldReserveFactorMantissa, uint256 newReserveFactorMantissa);

	/**
	 * @dev Event emitted when the reserves are added
	 */
	event ReservesAdded(address benefactor, uint256 addAmount, uint256 newTotalReserves);

	/**
	 * @dev Event emitted when the reserves are reduced
	 */
	event ReservesReduced(address admin, uint256 reduceAmount, uint256 newTotalReserves);

	/**
	 * @dev EIP20 Transfer event
	 */
	event Transfer(address indexed from, address indexed to, uint256 amount);

	/**
	 * @dev EIP20 Approval event
	 */
	event Approval(address indexed owner, address indexed spender, uint256 amount);

	/**
	 * @dev Failure event
	 */
	event Failure(uint256 error, uint256 info, uint256 detail);

	/*** User Interface ***/
	function totalBorrows() external view returns (uint256);

	function totalReserves() external view returns (uint256);

	function totalSupply() external view returns (uint256);

	function transfer(address dst, uint256 amount) external returns (bool);

	function transferFrom(
		address src,
		address dst,
		uint256 amount
	) external returns (bool);

	function approve(address spender, uint256 amount) external returns (bool);

	function allowance(address owner, address spender) external view returns (uint256);

	function balanceOf(address owner) external view returns (uint256);

	function balanceOfUnderlying(address owner) external returns (uint256);

	function getAccountSnapshot(address account)
		external
		view
		returns (
			uint256,
			uint256,
			uint256,
			uint256
		);

	function borrowRatePerBlock() external view returns (uint256);

	function supplyRatePerBlock() external view returns (uint256);

	function totalBorrowsCurrent() external returns (uint256);

	function borrowBalanceCurrent(address account) external returns (uint256);

	function borrowBalanceStored(address account) external view returns (uint256);

	function exchangeRateCurrent() external returns (uint256);

	function exchangeRateStored() external view returns (uint256);

	function getCash() external view returns (uint256);

	function accrueInterest() external returns (uint256);

	function seize(
		address liquidator,
		address borrower,
		uint256 seizeTokens
	) external returns (uint256);

	/*** CCap Interface ***/

	// ONLY SCREAM
	function totalCollateralTokens() external view returns (uint256);

	// ONLY SCREAM
	function isCollateralTokenInit(address account) external view returns (bool);

	// ONLY SCREAM
	function collateralCap() external view returns (uint256);

	/*** Admin Functions ***/

	function _setPendingAdmin(address payable newPendingAdmin) external returns (uint256);

	function _acceptAdmin() external returns (uint256);

	function _setComptroller(IComptroller newComptroller) external returns (uint256);

	function _setReserveFactor(uint256 newReserveFactorMantissa) external returns (uint256);

	function _reduceReserves(uint256 reduceAmount) external returns (uint256);

	function _setInterestRateModel(InterestRateModel newInterestRateModel)
		external
		returns (uint256);
}

interface ICTokenErc20 is ICToken {
	/*** User Interface ***/

	function mint(uint256 mintAmount) external returns (uint256);

	function redeem(uint256 redeemTokens) external returns (uint256);

	function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

	function borrow(uint256 borrowAmount) external returns (uint256);

	function repayBorrow(uint256 repayAmount) external returns (uint256);

	function liquidateBorrow(
		address borrower,
		uint256 repayAmount,
		ICToken cTokenCollateral
	) external returns (uint256);

	/*** Admin Functions ***/

	function _addReserves(uint256 addAmount) external returns (uint256);
}

interface ICTokenBase is ICToken {
	function repayBorrow() external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ICTokenInterfaces.sol";

interface ICompPriceOracle {
	function isPriceOracle() external view returns (bool);

	/**
	 * @notice Get the underlying price of a cToken asset
	 * @param cToken The cToken to get the underlying price of
	 * @return The underlying asset price mantissa (scaled by 1e18).
	 *  Zero means the price is unavailable.
	 */
	function getUnderlyingPrice(address cToken) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ICTokenInterfaces.sol";

interface IComptroller {
	/*** Assets You Are In ***/

	function enterMarkets(address[] calldata cTokens) external returns (uint256[] memory);

	function exitMarket(address cToken) external returns (uint256);

	/*** Policy Hooks ***/

	function mintAllowed(
		address cToken,
		address minter,
		uint256 mintAmount
	) external returns (uint256);

	function mintVerify(
		address cToken,
		address minter,
		uint256 mintAmount,
		uint256 mintTokens
	) external;

	function redeemAllowed(
		address cToken,
		address redeemer,
		uint256 redeemTokens
	) external returns (uint256);

	function redeemVerify(
		address cToken,
		address redeemer,
		uint256 redeemAmount,
		uint256 redeemTokens
	) external;

	function borrowAllowed(
		address cToken,
		address borrower,
		uint256 borrowAmount
	) external returns (uint256);

	function borrowVerify(
		address cToken,
		address borrower,
		uint256 borrowAmount
	) external;

	function repayBorrowAllowed(
		address cToken,
		address payer,
		address borrower,
		uint256 repayAmount
	) external returns (uint256);

	function repayBorrowVerify(
		address cToken,
		address payer,
		address borrower,
		uint256 repayAmount,
		uint256 borrowerIndex
	) external;

	function liquidateBorrowAllowed(
		address cTokenBorrowed,
		address cTokenCollateral,
		address liquidator,
		address borrower,
		uint256 repayAmount
	) external returns (uint256);

	function liquidateBorrowVerify(
		address cTokenBorrowed,
		address cTokenCollateral,
		address liquidator,
		address borrower,
		uint256 repayAmount,
		uint256 seizeTokens
	) external;

	function seizeAllowed(
		address cTokenCollateral,
		address cTokenBorrowed,
		address liquidator,
		address borrower,
		uint256 seizeTokens
	) external returns (uint256);

	function seizeVerify(
		address cTokenCollateral,
		address cTokenBorrowed,
		address liquidator,
		address borrower,
		uint256 seizeTokens
	) external;

	function transferAllowed(
		address cToken,
		address src,
		address dst,
		uint256 transferTokens
	) external returns (uint256);

	function transferVerify(
		address cToken,
		address src,
		address dst,
		uint256 transferTokens
	) external;

	function claimComp(address holder) external;

	function claimComp(address holder, ICTokenErc20[] memory cTokens) external;

	/*** Liquidity/Liquidation Calculations ***/

	function liquidateCalculateSeizeTokens(
		address cTokenBorrowed,
		address cTokenCollateral,
		uint256 repayAmount
	) external view returns (uint256, uint256);
}

interface UnitrollerAdminStorage {
	/**
	 * @notice Administrator for this contract
	 */
	// address external admin;
	function admin() external view returns (address);

	/**
	 * @notice Pending administrator for this contract
	 */
	// address external pendingAdmin;
	function pendingAdmin() external view returns (address);

	/**
	 * @notice Active brains of Unitroller
	 */
	// address external comptrollerImplementation;
	function comptrollerImplementation() external view returns (address);

	/**
	 * @notice Pending brains of Unitroller
	 */
	// address external pendingComptrollerImplementation;
	function pendingComptrollerImplementation() external view returns (address);
}

interface ComptrollerV1Storage is UnitrollerAdminStorage {
	/**
	 * @notice Oracle which gives the price of any given asset
	 */
	// PriceOracle external oracle;
	function oracle() external view returns (address);

	/**
	 * @notice Multiplier used to calculate the maximum repayAmount when liquidating a borrow
	 */
	// uint external closeFactorMantissa;
	function closeFactorMantissa() external view returns (uint256);

	/**
	 * @notice Multiplier representing the discount on collateral that a liquidator receives
	 */
	// uint external liquidationIncentiveMantissa;
	function liquidationIncentiveMantissa() external view returns (uint256);

	/**
	 * @notice Max number of assets a single account can participate in (borrow or use as collateral)
	 */
	// uint external maxAssets;
	function maxAssets() external view returns (uint256);

	/**
	 * @notice Per-account mapping of "assets you are in", capped by maxAssets
	 */
	// mapping(address => CToken[]) external accountAssets;
	// function accountAssets(address) external view returns (CToken[]);
}

abstract contract ComptrollerV2Storage is ComptrollerV1Storage {
	enum Version {
		VANILLA,
		COLLATERALCAP,
		WRAPPEDNATIVE
	}

	struct Market {
		bool isListed;
		uint256 collateralFactorMantissa;
		mapping(address => bool) accountMembership;
		bool isComped;
		// Version version;
	}

	/**
	 * @notice Official mapping of cTokens -> Market metadata
	 * @dev Used e.g. to determine if a market is supported
	 */
	mapping(address => Market) public markets;

	/**
	 * @notice The Pause Guardian can pause certain actions as a safety mechanism.
	 *  Actions which allow users to remove their own assets cannot be paused.
	 *  Liquidation / seizing / transfer can only be paused globally, not by market.
	 */
	// address external pauseGuardian;
	// bool external _mintGuardianPaused;
	// bool external _borrowGuardianPaused;
	// bool external transferGuardianPaused;
	// bool external seizeGuardianPaused;
	// mapping(address => bool) external mintGuardianPaused;
	// mapping(address => bool) external borrowGuardianPaused;
}

abstract contract ComptrollerV3Storage is ComptrollerV2Storage {
	// struct CompMarketState {
	//     /// @notice The market's last updated compBorrowIndex or compSupplyIndex
	//     uint224 index;
	//     /// @notice The block number the index was last updated at
	//     uint32 block;
	// }
	// /// @notice A list of all markets
	// CToken[] external allMarkets;
	// /// @notice The rate at which the flywheel distributes COMP, per block
	// uint external compRate;
	// /// @notice The portion of compRate that each market currently receives
	// mapping(address => uint) external compSpeeds;
	// /// @notice The COMP market supply state for each market
	// mapping(address => CompMarketState) external compSupplyState;
	// /// @notice The COMP market borrow state for each market
	// mapping(address => CompMarketState) external compBorrowState;
	// /// @notice The COMP borrow index for each market for each supplier as of the last time they accrued COMP
	// mapping(address => mapping(address => uint)) external compSupplierIndex;
	// /// @notice The COMP borrow index for each market for each borrower as of the last time they accrued COMP
	// mapping(address => mapping(address => uint)) external compBorrowerIndex;
	// /// @notice The COMP accrued but not yet transferred to each user
	// mapping(address => uint) external compAccrued;
}

abstract contract ComptrollerV4Storage is ComptrollerV3Storage {
	// @notice The borrowCapGuardian can set borrowCaps to any number for any market. Lowering the borrow cap could disable borrowing on the given market.
	// address external borrowCapGuardian;
	function borrowCapGuardian() external view virtual returns (address);

	// @notice Borrow caps enforced by borrowAllowed for each cToken address. Defaults to zero which corresponds to unlimited borrowing.
	// mapping(address => uint) external borrowCaps;
	function borrowCaps(address) external view virtual returns (uint256);
}

abstract contract ComptrollerV5Storage is ComptrollerV4Storage {
	// @notice The supplyCapGuardian can set supplyCaps to any number for any market. Lowering the supply cap could disable supplying to the given market.
	// address external supplyCapGuardian;
	function supplyCapGuardian() external view virtual returns (address);

	// @notice Supply caps enforced by mintAllowed for each cToken address. Defaults to zero which corresponds to unlimited supplying.
	// mapping(address => uint) external supplyCaps;
	function supplyCaps(address) external view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/**
 * @title Compound's InterestRateModel Interface
 * @author Compound
 */
interface InterestRateModel {
	/**
	 * @dev Calculates the current borrow interest rate per block
	 * @param cash The total amount of cash the market has
	 * @param borrows The total amount of borrows the market has outstanding
	 * @param reserves The total amnount of reserves the market has
	 * @return The borrow rate per block (as a percentage, and scaled by 1e18)
	 */
	function getBorrowRate(
		uint256 cash,
		uint256 borrows,
		uint256 reserves
	) external view returns (uint256);

	/**
	 * @dev Calculates the current supply interest rate per block
	 * @param cash The total amount of cash the market has
	 * @param borrows The total amount of borrows the market has outstanding
	 * @param reserves The total amnount of reserves the market has
	 * @param reserveFactorMantissa The current reserve factor the market has
	 * @return The supply rate per block (as a percentage, and scaled by 1e18)
	 */
	function getSupplyRate(
		uint256 cash,
		uint256 borrows,
		uint256 reserves,
		uint256 reserveFactorMantissa
	) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

abstract contract IBenqiComptroller {
	function claimReward(uint8 rewardType, address payable holder) external virtual;

	/// @notice The QI/AVAX accrued but not yet transferred to each user
	mapping(uint8 => mapping(address => uint256)) public rewardAccrued;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IStakingRewards is IERC20 {
	function stakingToken() external view returns (address);

	function lastTimeRewardApplicable() external view returns (uint256);

	function rewardPerToken() external view returns (uint256);

	function earned(address account) external view returns (uint256);

	function getRewardForDuration() external view returns (uint256);

	function stakeWithPermit(
		uint256 amount,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;

	function stake(uint256 amount) external;

	function withdraw(uint256 amount) external;

	function getReward() external;

	function exit() external;
}

// some farms use sushi interface
interface IMasterChef {
	// depositing 0 amount will withdraw the rewards (harvest)
	function deposit(uint256 _pid, uint256 _amount) external;

	function withdraw(uint256 _pid, uint256 _amount) external;

	function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);

	function emergencyWithdraw(uint256 _pid) external;

	function pendingTokens(uint256 _pid, address _user)
		external
		view
		returns (
			uint256,
			address,
			string memory,
			uint256
		);
}

interface IMiniChefV2 {
	struct UserInfo {
		uint256 amount;
		int256 rewardDebt;
	}

	struct PoolInfo {
		uint128 accSushiPerShare;
		uint64 lastRewardTime;
		uint64 allocPoint;
	}

	function poolLength() external view returns (uint256);

	function updatePool(uint256 pid) external returns (IMiniChefV2.PoolInfo memory);

	function userInfo(uint256 _pid, address _user) external view returns (uint256, int256);

	function deposit(
		uint256 pid,
		uint256 amount,
		address to
	) external;

	function withdraw(
		uint256 pid,
		uint256 amount,
		address to
	) external;

	function harvest(uint256 pid, address to) external;

	function withdrawAndHarvest(
		uint256 pid,
		uint256 amount,
		address to
	) external;

	function emergencyWithdraw(uint256 pid, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IUniswapV2Pair {
	event Approval(address indexed owner, address indexed spender, uint256 value);
	event Transfer(address indexed from, address indexed to, uint256 value);

	function name() external pure returns (string memory);

	function symbol() external pure returns (string memory);

	function decimals() external pure returns (uint8);

	function totalSupply() external view returns (uint256);

	function balanceOf(address owner) external view returns (uint256);

	function allowance(address owner, address spender) external view returns (uint256);

	function approve(address spender, uint256 value) external returns (bool);

	function transfer(address to, uint256 value) external returns (bool);

	function transferFrom(
		address from,
		address to,
		uint256 value
	) external returns (bool);

	function DOMAIN_SEPARATOR() external view returns (bytes32);

	function PERMIT_TYPEHASH() external pure returns (bytes32);

	function nonces(address owner) external view returns (uint256);

	function permit(
		address owner,
		address spender,
		uint256 value,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;

	event Mint(address indexed sender, uint256 amount0, uint256 amount1);
	event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
	event Swap(
		address indexed sender,
		uint256 amount0In,
		uint256 amount1In,
		uint256 amount0Out,
		uint256 amount1Out,
		address indexed to
	);
	event Sync(uint112 reserve0, uint112 reserve1);

	function MINIMUM_LIQUIDITY() external pure returns (uint256);

	function factory() external view returns (address);

	function token0() external view returns (address);

	function token1() external view returns (address);

	function getReserves()
		external
		view
		returns (
			uint112 reserve0,
			uint112 reserve1,
			uint32 blockTimestampLast
		);

	function price0CumulativeLast() external view returns (uint256);

	function price1CumulativeLast() external view returns (uint256);

	function kLast() external view returns (uint256);

	function mint(address to) external returns (uint256 liquidity);

	function burn(address to) external returns (uint256 amount0, uint256 amount1);

	function swap(
		uint256 amount0Out,
		uint256 amount1Out,
		address to,
		bytes calldata data
	) external;

	function skim(address to) external;

	function sync() external;

	function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IWETH {
	function deposit() external payable;

	function transfer(address to, uint256 value) external returns (bool);

	function withdraw(uint256) external;

	function balanceOf(address) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "../interfaces/uniswap/IUniswapV2Pair.sol";

library UniUtils {
	function _getPairTokens(IUniswapV2Pair pair) internal view returns (address, address) {
		return (pair.token0(), pair.token1());
	}

	function _getPairReserves(
		IUniswapV2Pair pair,
		address tokenA,
		address tokenB
	) internal view returns (uint256 reserveA, uint256 reserveB) {
		(address token0, ) = _sortTokens(tokenA, tokenB);
		(uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
		(reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
	}

	// given some amount of an asset and lp reserves, returns an equivalent amount of the other asset
	function _quote(
		uint256 amountA,
		uint256 reserveA,
		uint256 reserveB
	) internal pure returns (uint256 amountB) {
		require(amountA > 0, "UniUtils: INSUFFICIENT_AMOUNT");
		require(reserveA > 0 && reserveB > 0, "UniUtils: INSUFFICIENT_LIQUIDITY");
		amountB = (amountA * reserveB) / reserveA;
	}

	function _sortTokens(address tokenA, address tokenB)
		internal
		pure
		returns (address token0, address token1)
	{
		require(tokenA != tokenB, "UniUtils: IDENTICAL_ADDRESSES");
		(token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
		require(token0 != address(0), "UniUtils: ZERO_ADDRESS");
	}

	function _getAmountOut(
		IUniswapV2Pair pair,
		uint256 amountIn,
		address inToken,
		address outToken
	) internal view returns (uint256 amountOut) {
		require(amountIn > 0, "UniUtils: INSUFFICIENT_INPUT_AMOUNT");
		(uint256 reserveIn, uint256 reserveOut) = _getPairReserves(pair, inToken, outToken);
		uint256 amountInWithFee = amountIn * 997;
		uint256 numerator = amountInWithFee * reserveOut;
		uint256 denominator = reserveIn * 1000 + amountInWithFee;
		amountOut = numerator / denominator;
	}

	function _getAmountIn(
		IUniswapV2Pair pair,
		uint256 amountOut,
		address inToken,
		address outToken
	) internal view returns (uint256 amountIn) {
		require(amountOut > 0, "UniUtils: INSUFFICIENT_OUTPUT_AMOUNT");
		(uint256 reserveIn, uint256 reserveOut) = _getPairReserves(pair, inToken, outToken);
		uint256 numerator = reserveIn * amountOut * 1000;
		uint256 denominator = (reserveOut - amountOut) * 997;
		amountIn = (numerator / denominator) + 1;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// all interfaces need to inherit from base
abstract contract IBase {
	function short() public view virtual returns (IERC20);

	function underlying() public view virtual returns (IERC20);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "../interfaces/compound/ICTokenInterfaces.sol";
import "../interfaces/compound/IComptroller.sol";
import "../interfaces/compound/ICompPriceOracle.sol";
import "../interfaces/compound/IComptroller.sol";
import "../interfaces/uniswap/IWETH.sol";

import "./ILending.sol";
import "./IBase.sol";

// import "hardhat/console.sol";

abstract contract ICompound is IBase, ILending {
	using SafeERC20 for IERC20;

	function cTokenLend() public view virtual returns (ICTokenErc20);

	function cTokenBorrow() public view virtual returns (ICTokenErc20);

	function oracle() public view virtual returns (ICompPriceOracle);

	function comptroller() public view virtual returns (IComptroller);

	function _enterMarket() internal {
		address[] memory cTokens = new address[](2);
		cTokens[0] = address(cTokenLend());
		cTokens[1] = address(cTokenBorrow());
		comptroller().enterMarkets(cTokens);
	}

	function _getCollateralFactor() internal view override returns (uint256) {
		(, uint256 collateralFactorMantissa, ) = ComptrollerV2Storage(address(comptroller()))
			.markets(address(cTokenLend()));
		return collateralFactorMantissa;
	}

	function _redeem(uint256 amount) internal override {
		uint256 err = cTokenLend().redeemUnderlying(amount);
		// if (err != 0) console.log("Compund: error redeeming underlying");
		// require(err == 0, "Compund: error redeeming underlying");
	}

	function _borrow(uint256 amount) internal override {
		cTokenBorrow().borrow(amount);

		// in case we need to wrap the tokens
		if (_isBase(1)) IWETH(address(short())).deposit{ value: amount }();
	}

	function _lend(uint256 amount) internal override {
		cTokenLend().mint(amount);
	}

	function _repay(uint256 amount) internal override {
		if (_isBase(1)) {
			// need to convert to base first
			IWETH(address(short())).withdraw(amount);

			// then repay in the base
			_repayBase(amount);
			return;
		}
		cTokenBorrow().repayBorrow(amount);
	}

	function _repayBase(uint256 amount) internal {
		ICTokenBase(address(cTokenBorrow())).repayBorrow{ value: amount }();
	}

	function _updateAndGetCollateralBalance() internal override returns (uint256) {
		return cTokenLend().balanceOfUnderlying(address(this));
	}

	function _getCollateralBalance() internal view override returns (uint256) {
		uint256 b = cTokenLend().balanceOf(address(this));
		return (b * cTokenLend().exchangeRateStored()) / 1e18;
	}

	function _updateAndGetBorrowBalance() internal override returns (uint256) {
		return cTokenBorrow().borrowBalanceCurrent(address(this));
	}

	function _getBorrowBalance() internal view override returns (uint256 shortBorrow) {
		shortBorrow = cTokenBorrow().borrowBalanceStored(address(this));
	}

	function _oraclePriceOfShort(uint256 amount) internal view override returns (uint256) {
		return
			(amount * oracle().getUnderlyingPrice(address(cTokenBorrow()))) /
			oracle().getUnderlyingPrice(address(cTokenLend()));
	}

	function _oraclePriceOfWant(uint256 amount) internal view override returns (uint256) {
		return
			(amount * oracle().getUnderlyingPrice(address(cTokenLend()))) /
			oracle().getUnderlyingPrice(address(cTokenBorrow()));
	}

	// returns true if either of the CTokens is cEth
	// index 0 = cTokenLend index 1 = cTokenBorrow
	function _isBase(uint8 index) internal virtual returns (bool) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./IBase.sol";

abstract contract IFarmable is IBase {
	event LpHarvest(uint256 harvest);

	function _depositIntoFarm(uint256 amount) internal virtual;

	function _withdrawFromFarm(uint256 amount) internal virtual;

	function _harvestFarm() internal virtual;

	function _getFarmLp() internal view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./IBase.sol";

// import "hardhat/console.sol";

abstract contract ILending is IBase {
	event LendHarvest(uint256 harvest0, uint256 harvest1, uint256 harvest2);

	function _addLendingApprovals() internal virtual;

	function _getCollateralBalance() internal view virtual returns (uint256);

	function _getBorrowBalance() internal view virtual returns (uint256);

	function _updateAndGetCollateralBalance() internal virtual returns (uint256);

	function _updateAndGetBorrowBalance() internal virtual returns (uint256);

	function _getCollateralFactor() internal view virtual returns (uint256);

	function safeCollateralRatio() public view virtual returns (uint256);

	function _oraclePriceOfShort(uint256 amount) internal view virtual returns (uint256);

	function _oraclePriceOfWant(uint256 amount) internal view virtual returns (uint256);

	function _lend(uint256 amount) internal virtual;

	function _redeem(uint256 amount) internal virtual;

	function _borrow(uint256 amount) internal virtual;

	function _repay(uint256 amount) internal virtual;

	function _harvestLending(uint256 minHarvest) internal virtual;

	function getCollateralRatio() public view returns (uint256) {
		return (_getCollateralFactor() * safeCollateralRatio()) / 1e18;
	}

	function _adjustCollateral(uint256 targetCollateral)
		internal
		returns (uint256 added, uint256 removed)
	{
		uint256 collateralBalance = _getCollateralBalance();
		if (collateralBalance == targetCollateral) return (0, 0);
		(added, removed) = collateralBalance > targetCollateral
			? (uint256(0), _removeCollateral(collateralBalance - targetCollateral))
			: (_addCollateral(targetCollateral - collateralBalance), uint256(0));
	}

	function _removeCollateral(uint256 amountToRemove) internal returns (uint256 removed) {
		uint256 borrowValue = _oraclePriceOfShort(_getBorrowBalance());
		uint256 collateral = _getCollateralBalance();

		// stay within 5% of the liquidation threshold
		uint256 minCollateral = (100 * (borrowValue * 1e18)) / _getCollateralFactor() / 95;
		if (minCollateral > collateral) return 0;

		uint256 maxRemove = collateral - minCollateral;
		removed = maxRemove > amountToRemove ? amountToRemove : maxRemove;
		_redeem(removed);
	}

	function _addCollateral(uint256 amountToAdd) internal returns (uint256 added) {
		uint256 wantBalance = underlying().balanceOf(address(this));
		added = wantBalance > amountToAdd ? amountToAdd : wantBalance;
		if (added != 0) _lend(added);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

abstract contract ILp {
	function _quote(
		uint256 amount,
		address token0,
		address token1
	) internal view virtual returns (uint256 price);

	function _addLiquidity(uint256 amountToken0, uint256 amountToken1)
		internal
		virtual
		returns (uint256 liquidity);

	function _removeLiquidity(uint256 liquidity) internal virtual returns (uint256, uint256);

	function _getLPBalances()
		internal
		view
		virtual
		returns (uint256 wantBalance, uint256 shortBalance);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/uniswap/IStakingRewards.sol";
import "../libraries/UniUtils.sol";

abstract contract ISwappable {
	using SafeERC20 for IERC20;

	// TODO custom swap method requires custom price match check!
	// TODO in the future this should use the optimal path determined externally & router
	// using https://docs.uniswap.org/sdk/2.0.0/reference/trade#besttradeexactin
	function _swapExactTokensForTokens(
		IUniswapV2Pair pair,
		uint256 amountIn,
		address inToken,
		address outToken
	) public returns (uint256) {
		uint256 amountOut = UniUtils._getAmountOut(pair, amountIn, inToken, outToken);
		(address token0, ) = UniUtils._sortTokens(outToken, inToken);
		(uint256 amount0Out, uint256 amount1Out) = inToken == token0
			? (uint256(0), amountOut)
			: (amountOut, uint256(0));

		IERC20(inToken).safeTransfer(address(pair), amountIn);
		pair.swap(amount0Out, amount1Out, address(this), new bytes(0));
		return amountOut;
	}

	function _swapTokensForExactTokens(
		IUniswapV2Pair pair,
		uint256 amountOut,
		address inToken,
		address outToken
	) public returns (uint256) {
		uint256 amountIn = UniUtils._getAmountIn(pair, amountOut, inToken, outToken);
		(address token0, ) = UniUtils._sortTokens(outToken, inToken);
		(uint256 amount0Out, uint256 amount1Out) = inToken == token0
			? (uint256(0), amountOut)
			: (amountOut, uint256(0));

		IERC20(inToken).safeTransfer(address(pair), amountIn);
		pair.swap(amount0Out, amount1Out, address(this), new bytes(0));
		return amountIn;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/uniswap/IUniswapV2Pair.sol";
import "../libraries/UniUtils.sol";

import "./IBase.sol";
import "./ILp.sol";

abstract contract IUniLp is IBase, ILp {
	using SafeERC20 for IERC20;

	function pair() public view virtual returns (IUniswapV2Pair);

	function _getLiquidity() internal view virtual returns (uint256);

	function _addLiquidity(uint256 amountToken0, uint256 amountToken1)
		internal
		override
		returns (uint256 liquidity)
	{
		underlying().safeTransfer(address(pair()), amountToken0);
		short().safeTransfer(address(pair()), amountToken1);
		liquidity = pair().mint(address(this));
	}

	function _removeLiquidity(uint256 liquidity) internal override returns (uint256, uint256) {
		IERC20(address(pair())).safeTransfer(address(pair()), liquidity);
		(address tokenA, ) = UniUtils._sortTokens(address(underlying()), address(short()));
		(uint256 amountToken0, uint256 amountToken1) = pair().burn(address(this));
		return
			tokenA == address(underlying())
				? (amountToken0, amountToken1)
				: (amountToken1, amountToken0);
	}

	function _quote(
		uint256 amount,
		address token0,
		address token1
	) internal view override returns (uint256 price) {
		if (amount == 0) return 0;
		(uint256 reserve0, uint256 reserve1) = UniUtils._getPairReserves(pair(), token0, token1);
		price = UniUtils._quote(amount, reserve0, reserve1);
	}

	// fetches and sorts the reserves for a uniswap pair
	function getUnderlyingShortReserves() public view returns (uint256 reserveA, uint256 reserveB) {
		(reserveA, reserveB) = UniUtils._getPairReserves(
			pair(),
			address(underlying()),
			address(short())
		);
	}

	function _getLPBalances()
		internal
		view
		override
		returns (uint256 wantBalance, uint256 shortBalance)
	{
		uint256 totalLp = _getLiquidity();
		(uint256 totalWantBalance, uint256 totalShortBalance) = getUnderlyingShortReserves();
		uint256 total = pair().totalSupply();
		wantBalance = (totalWantBalance * totalLp) / total;
		shortBalance = (totalShortBalance * totalLp) / total;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "hardhat/console.sol";

abstract contract BaseStrategy is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
	using SafeERC20 for IERC20;

	modifier onlyVault() {
		require(msg.sender == vault(), "Strat: NO_AUTH");
		_;
	}

	modifier onlyAuth() {
		require(msg.sender == owner() || _managers[msg.sender] == true, "Strat: NO_AUTH");
		_;
	}

	uint256 constant BPS_ADJUST = 10000;
	uint256 public lastHarvest; // block.timestamp;
	address private _vault;
	uint256 private _shares;

	string public name;
	string public symbol;

	mapping(address => bool) private _managers;

	uint256 public BASE_UNIT; // 10 ** decimals

	event Harvest(uint256 harvested);
	event Deposit(address sender, uint256 amount);
	event Withdraw(address sender, uint256 amount);
	event Rebalance(uint256 shortPrice, uint256 tvlBeforeRebalance, uint256 positionOffset);
	event ManagerUpdate(address indexed account, bool isManager);
	event Upgrade();

	function __BaseStrategy_init(
		address vault_,
		string memory symbol_,
		string memory name_
	) internal initializer {
		__ReentrancyGuard_init();
		__Ownable_init();
		_vault = vault_;
		symbol = symbol_;
		name = name_;
	}

	// VIEW
	function vault() public view returns (address) {
		return _vault;
	}

	function totalSupply() public view returns (uint256) {
		return _shares;
	}

	function onUpgrade(string calldata _symbol, string calldata _name) public onlyOwner {
		name = _name;
		symbol = _symbol;
		emit Upgrade();
	}

	/**
	 * @notice
	 *  Returns the share price of the strategy in `want` units, multiplied
	 *  by 1e18
	 */
	function getPricePerShare() public view returns (uint256) {
		uint256 bal = balanceOfUnderlying();
		if (_shares == 0) return BASE_UNIT;
		return (bal * BASE_UNIT) / _shares;
	}

	function balanceOfUnderlying(address) public view virtual returns (uint256) {
		return balanceOfUnderlying();
	}

	function balanceOfUnderlying() public view virtual returns (uint256);

	// PUBLIC METHODS
	function mint(uint256 amount) public onlyVault returns (uint256 errCode) {
		uint256 newShares = _deposit(amount);
		_shares += newShares;
		errCode = 0;
	}

	function redeemUnderlying(uint256 amount) external onlyVault returns (uint256 errCode) {
		uint256 burnShares = _withdraw(amount);
		_shares -= burnShares;
		errCode = 0;
	}

	function harvest() external onlyAuth {
		// harvest
		uint256 harvested = _harvestInternal();
		emit Harvest(harvested);
	}

	// GOVERNANCE - MANAGER
	function isManager(address user) public view returns (bool) {
		return _managers[user];
	}

	function setManager(address user, bool _isManager) external onlyOwner {
		_managers[user] = _isManager;
		emit ManagerUpdate(user, _isManager);
	}

	function setVault(address vault_) public {
		_vault = vault_;
	}

	/**
	 * Virtual function for triggering a harvest
	 *
	 * Returns
	 * want harvested in harvest
	 */
	function _harvestInternal() internal virtual returns (uint256 harvested);

	function _deposit(uint256 amount) internal virtual returns (uint256 newShares);

	function _withdraw(uint256 amount) internal virtual returns (uint256 burnShares);

	function isCEther() external pure returns (bool) {
		return false;
	}

	uint256[49] private _gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../mixins/IBase.sol";
import "../mixins/ILending.sol";
import "../mixins/IFarmable.sol";
import "../mixins/IUniLp.sol";
import "../mixins/ISwappable.sol";
import "./BaseStrategy.sol";
import "../interfaces/uniswap/IWETH.sol";

// import "hardhat/console.sol";

// @custom: alphabetize dependencies to avoid linearization conflicts
abstract contract HedgedLP is
	Initializable,
	IBase,
	BaseStrategy,
	IFarmable,
	ILending,
	ISwappable,
	IUniLp
{
	using SafeERC20 for IERC20;

	uint256 private _maxPriceMismatch;

	modifier checkPrice() {
		uint256 minPrice = _quote(1e18, address(_short), address(_underlying));
		uint256 maxPrice = _oraclePriceOfShort(1e18);
		(minPrice, maxPrice) = maxPrice > minPrice ? (minPrice, maxPrice) : (maxPrice, minPrice);
		require(
			((maxPrice - minPrice) * BPS_ADJUST) / maxPrice < _maxPriceMismatch,
			"HedgedLP: SHORT_PRICE_MISMATCH"
		);
		_;
	}

	IERC20 private _underlying;
	IERC20 private _short;

	uint256 _minLendHarvest; // don't harvest until we have this balance
	uint16 public rebalanceThreshold; // 4% of lp

	function __HedgedLP_init_unchained(address underlying_, address short_) internal initializer {
		_underlying = IERC20(underlying_);
		_short = IERC20(short_);

		_underlying.safeApprove(address(this), type(uint256).max);

		// init params
		_maxPriceMismatch = 60; // .6% based on uniswap .6% bid-ask spread
		rebalanceThreshold = 400;
		_minLendHarvest = 4 * 1e6; // $4
		BASE_UNIT = 10**decimals();
	}

	function decimals() public view returns (uint8) {
		return IERC20Metadata(address(_underlying)).decimals();
	}

	// OWNER CONFIG

	function setMinLendHarvest(uint256 minLendHarvest_) public onlyOwner {
		_minLendHarvest = minLendHarvest_;
	}

	function setMaxPriceMismatch(uint256 maxPriceMismatch_) public onlyOwner {
		_maxPriceMismatch = maxPriceMismatch_;
	}

	function setRebalanceThreshold(uint16 rebalanceThreshold_) public onlyOwner {
		rebalanceThreshold = rebalanceThreshold_;
	}

	// PUBLIC METHODS

	function short() public view override returns (IERC20) {
		return _short;
	}

	function underlying() public view override returns (IERC20) {
		return _underlying;
	}

	// assets are deposited but rebalance needs to be called before assets are deployed
	// should rebalance here
	function _deposit(uint256 amount)
		internal
		override
		checkPrice
		nonReentrant
		returns (uint256 newShares)
	{
		uint256 tvl = _getAndUpdateTVL();
		newShares = totalSupply() == 0 ? amount : (totalSupply() * amount) / tvl;
		_underlying.transferFrom(vault(), address(this), amount);
		_increasePosition(amount);
		emit Deposit(msg.sender, amount);
	}

	function _withdraw(uint256 amount)
		internal
		override
		onlyVault
		checkPrice
		nonReentrant
		returns (uint256 burnShares)
	{
		uint256 tvl = _getAndUpdateTVL();
		uint256 reserves = _underlying.balanceOf(address(this));

		// if we can not withdraw straight out of reserves
		if (reserves < amount) {
			// add 1% to withdraw amount for tx fees etc
			uint256 withdrawAmnt = (amount * 101) / 100;

			if (withdrawAmnt >= tvl) {
				// decrease current position
				_closePosition();
				withdrawAmnt = _underlying.balanceOf(address(this));
			} else withdrawAmnt = _decreasePosition(withdrawAmnt - reserves) + reserves;
			// use the minimum of the two
			amount = min(withdrawAmnt, amount);
		}
		burnShares = (amount * totalSupply()) / tvl;
		_underlying.safeTransferFrom(address(this), vault(), amount);
		emit Withdraw(msg.sender, amount);
	}

	// decreases position based on current desired balance
	// ** does not rebalance remaining portfolio
	// ** may return slighly less then desired amount
	// ** make sure to update lending positions before calling this
	function _decreasePosition(uint256 amount) internal returns (uint256) {
		uint256 removeLpAmnt = _totalToLp(amount);

		(uint256 underlyingLp, ) = _getLPBalances();

		uint256 shortPosition = _getBorrowBalance();

		// remove lp
		(uint256 underlyingBalance, uint256 shortBalance) = _decreaseLpTo(
			underlyingLp - removeLpAmnt
		);

		uint256 repayAmnt = shortBalance;

		if (shortPosition < shortBalance) {
			// this means we are closing the short position
			underlyingBalance += _swapExactTokensForTokens(
				pair(),
				shortBalance - shortPosition,
				address(_short),
				address(_underlying)
			);
			repayAmnt = shortPosition;
		}
		_repay(repayAmnt);

		// this might remove less collateral than desired if we hit the limit
		// this happens when position is close to empty
		uint256 removed = _removeCollateral(amount - underlyingBalance);
		return underlyingBalance + removed;
	}

	// increases the position based on current desired balance
	// ** does not rebalance remaining portfolio
	function _increasePosition(uint256 amount) internal {
		uint256 amntUnderlying = _totalToLp(amount);
		uint256 amntShort = _quote(amntUnderlying, address(_underlying), address(_short));
		_lend(amount - amntUnderlying);
		_borrow(amntShort);
		uint256 liquidity = _addLiquidity(amntUnderlying, amntShort);
		_depositIntoFarm(liquidity);
	}

	function _harvestInternal()
		internal
		override
		checkPrice
		nonReentrant
		returns (uint256 harvested)
	{
		uint256 startTvl = _getAndUpdateTVL();

		_harvestLending(_minLendHarvest);
		_harvestFarm();

		// deposit funds back into farm
		uint256 underlyingBal = _underlying.balanceOf(address(this));
		if (underlyingBal > 0) _lend(underlyingBal);
		uint256 shortBal = _short.balanceOf(address(this));
		if (shortBal > 0) _repay(shortBal);
		uint256 endTvl = balanceOfUnderlying();

		return endTvl > startTvl ? (endTvl - startTvl) : 0;
	}

	// MANAGER + OWNER METHODS
	// TODO rebalance can be public eventually
	function rebalance() public onlyAuth checkPrice nonReentrant {
		(uint256 underlyingLp, ) = _getLPBalances();
		uint256 tvl = _getAndUpdateTVL();
		uint256 targetWantLP = _totalToLp(tvl);

		(bool needsRebalance, bool shouldIncrease, uint256 positionOffset) = _shouldRebalance(
			targetWantLP,
			underlyingLp
		);
		require(needsRebalance, "HedgedLP: have not reached rebalance threshold"); // maybe next time...

		uint256 targetCollateral = tvl - targetWantLP;

		if (shouldIncrease)
			// this means lp is low - short price went down
			// most of the time we should not have to remove collateral
			_rebalanceUp(targetWantLP, targetCollateral);
			// this means lp is too high - short price went up
		else _rebalanceDown(targetWantLP, targetCollateral);
		emit Rebalance(_shortToWant(1e18), positionOffset, tvl);
	}

	function closePosition() external onlyAuth {
		_closePosition();
	}

	function _closePosition() internal {
		_decreaseLpTo(0);
		uint256 shortPosition = _updateAndGetBorrowBalance();
		uint256 shortBalance = _short.balanceOf(address(this));
		if (shortPosition > shortBalance) {
			uint256 adjustShort = shortPosition - shortBalance;
			_swapTokensForExactTokens(pair(), adjustShort, address(_underlying), address(_short));
		} else if (shortBalance > shortPosition) {
			uint256 adjustShort = shortBalance - shortPosition;
			_swapExactTokensForTokens(pair(), adjustShort, address(_short), address(_underlying));
		}
		_repay(_short.balanceOf(address(this)));

		uint256 collateralBalance = _updateAndGetCollateralBalance();
		_redeem(collateralBalance);
	}

	function _shouldRebalance(uint256 targetWantLP, uint256 underlyingLp)
		internal
		view
		returns (
			bool needsRebalance,
			bool shouldIncrease,
			uint256 positionOffset
		)
	{
		shouldIncrease = targetWantLP > underlyingLp ? true : false;
		if (underlyingLp == 0 || targetWantLP == 0)
			return (underlyingLp != targetWantLP, shouldIncrease, positionOffset);

		uint256 shortPosition = _getBorrowBalance();

		// this is the % by which our position has moved from beeing balanced
		positionOffset = shouldIncrease
			? ((targetWantLP - underlyingLp) * BPS_ADJUST) / underlyingLp
			: ((underlyingLp - targetWantLP) * BPS_ADJUST) / targetWantLP;

		// don't rebalance unless
		needsRebalance =
			positionOffset > rebalanceThreshold ||
			_underlying.balanceOf(address(this)) > 10e6 ||
			shortPosition == 0;
	}

	// TODO handle case for when lp is not 100% in farm?
	function _decreaseLpTo(uint256 targetWantLP)
		internal
		returns (uint256 underlyingRemove, uint256 shortRemove)
	{
		(uint256 underlyingLp, ) = _getLPBalances();
		uint256 liquidity = _getLiquidity();
		uint256 underlyingLiquidity = (liquidity * targetWantLP) / underlyingLp;
		uint256 removeLp = liquidity - underlyingLiquidity;
		_withdrawFromFarm(removeLp);
		return _removeLiquidity(removeLp);
	}

	// remove collateral (short price moved down so target collateral is lower)
	// borrow short
	// sell extra short
	// add lp
	function _rebalanceUp(uint256 targetWantLP, uint256 targetCollateral) internal {
		_adjustCollateral(targetCollateral);

		// borrow
		uint256 targetShortPosition = _underlyingToShort(targetWantLP);
		uint256 shortPosition = _getBorrowBalance();

		_borrow(targetShortPosition - shortPosition);

		// sell extra short
		(uint256 underlyingLp, ) = _getLPBalances();

		uint256 buyWant = targetWantLP - (_underlying.balanceOf(address(this)) + underlyingLp);
		if (buyWant > 0)
			_swapTokensForExactTokens(pair(), buyWant, address(_short), address(_underlying));

		// we will have more underlying tokens as a result of the tx fees
		// so we use short balance to compute final lp amounts
		uint256 amntShort = _short.balanceOf(address(this));
		uint256 amntUnderlying = _shortToWant(amntShort);
		uint256 balWant = _underlying.balanceOf(address(this));
		if (balWant < amntUnderlying) {
			amntUnderlying = balWant;
			amntShort = _underlyingToShort(amntUnderlying);
		}

		// add liquidity
		uint256 liquidity = _addLiquidity(amntUnderlying, amntShort);

		// ape into farm
		_depositIntoFarm(liquidity);

		// TODO - might have leftover underlying tokens here
	}

	// remove lp
	// return borrow
	// remove collateral
	// buy back extra short
	// return extra short borrow
	function _rebalanceDown(uint256 targetWantLP, uint256 targetCollateral) internal {
		if (targetWantLP == 0) return _closePosition();

		// remove lp
		_decreaseLpTo(targetWantLP);

		uint256 shortBalance = _short.balanceOf(address(this));
		_repay(shortBalance);

		// if we're already over collateral threshold we may not have enought to buy back
		// full amount of short tokens
		(, uint256 removed) = _adjustCollateral(targetCollateral);

		// if we're withdrawing we may end up with extra $$
		// do the check here
		uint256 shortPosition = _updateAndGetBorrowBalance();
		uint256 adjustBorrow = shortPosition - _underlyingToShort(targetWantLP);

		if (adjustBorrow == 0) return;

		uint256 underlyingIn = UniUtils._getAmountIn(
			pair(),
			adjustBorrow,
			address(_underlying),
			address(_short)
		);
		uint256 underlyingBalance = _underlying.balanceOf(address(this));
		uint256 sellShort = underlyingIn < underlyingBalance ? underlyingIn : underlyingBalance;
		_swapExactTokensForTokens(pair(), sellShort, address(_underlying), address(_short));

		shortBalance = _short.balanceOf(address(this));
		// return borrow
		_repay(shortBalance);
		if (targetCollateral > removed) _adjustCollateral(targetCollateral);
	}

	function _totalToLp(uint256 total) internal view returns (uint256) {
		uint256 cRatio = getCollateralRatio();
		return (total * cRatio) / (BPS_ADJUST + cRatio);
	}

	// TODO should we compute pending farm & lending rewards here?
	function _getAndUpdateTVL() internal returns (uint256 tvl) {
		uint256 collateralBalance = _updateAndGetCollateralBalance();
		uint256 shortPosition = _updateAndGetBorrowBalance();
		uint256 shortBalance = _shortToWant(shortPosition);
		(uint256 underlyingLp, ) = _getLPBalances();
		uint256 underlyingBalance = _underlying.balanceOf(address(this));
		tvl = collateralBalance + underlyingLp * 2 - shortBalance + underlyingBalance;
	}

	function balanceOfUnderlying() public view override returns (uint256 assets) {
		(assets, , , , , ) = getTVL();
	}

	// VIEW
	function getTVL()
		public
		view
		returns (
			uint256 tvl,
			uint256 collateralBalance,
			uint256 shortPosition,
			uint256 shortBalance,
			uint256 lpBalance,
			uint256 underlyingBalance
		)
	{
		collateralBalance = _getCollateralBalance();
		shortPosition = _getBorrowBalance();
		// shortBalance is the short position denominated in underlying tokens
		shortBalance = _shortToWant(shortPosition);
		(uint256 underlyingLp, ) = _getLPBalances();
		lpBalance = underlyingLp * 2;
		underlyingBalance = _underlying.balanceOf(address(this));

		tvl = collateralBalance + lpBalance - shortBalance + underlyingBalance;
	}

	function _shortToWant(uint256 amount) internal view returns (uint256) {
		if (amount == 0) return 0;
		// lending oracle price
		// return _oraclePriceOfShort(amount);

		// uni price
		return _quote(amount, address(_short), address(_underlying));
	}

	function _underlyingToShort(uint256 amount) internal view returns (uint256) {
		if (amount == 0) return 0;
		// lending oracle price
		// return _oraclePriceOfWant(amount);

		// uni price
		return _quote(amount, address(_underlying), address(_short));
	}

	/**
	 * @dev Returns the smallest of two numbers.
	 */
	function min(uint256 a, uint256 b) internal pure returns (uint256) {
		return a < b ? a : b;
	}

	uint256[50] private _gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../HedgedLP.sol";
import "../modules/Compound.sol";
import "../modules/MasterChefFarm.sol";
import "../modules/BenqiFarm.sol";

// import "hardhat/console.sol";

contract USDCavaxJOEqi is Initializable, HedgedLP, Compound, BenqiFarm, MasterChefFarm {
	uint256[200] private _gap;

	struct Config {
		address underlying;
		address short;
		address cTokenLend;
		address cTokenBorrow;
		address uniPair;
		address uniFarm;
		address farmLp;
		address farmToken;
		uint256 farmId;
		address router;
		address comptroller;
		address benqiPair;
		address benqiToken;
		uint256 safeCollateralRatio;
		address vault;
		string symbol;
		string name;
	}

	// @custom:oz-upgrades-unsafe-allow constructor
	constructor() initializer {}

	function initialize(Config memory config) public initializer {
		__MasterChefFarm_init_unchained(
			config.uniPair,
			config.uniFarm,
			config.farmLp,
			config.farmToken,
			config.farmId
		);

		__Compound_init_unchained(
			config.comptroller,
			config.cTokenLend,
			config.cTokenBorrow,
			config.safeCollateralRatio
		);
		__BenqiFarm_init_unchained(config.benqiPair, config.benqiToken);

		__BaseStrategy_init(config.vault, config.symbol, config.name);

		// main strategy  should allways be intialized last
		__HedgedLP_init_unchained(config.underlying, config.short);

		// TODO should this be a separate admin func?
		// TODO revoke aprovals methods?
		_addLendingApprovals();
		_addFarmApprovals();
	}

	receive() external payable {}

	// our borrow token is treated as ETH by benqi
	function _isBase(uint8 id) internal override(ICompound) returns (bool) {
		return id == 1 ? true : false;
	}

	// helps check upgrades
	uint256 public version;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../../interfaces/forks/IBenqiComptroller.sol";
import "../../mixins/ISwappable.sol";
import "../../mixins/IUniLp.sol";
import "../../mixins/ICompound.sol";
import "../../interfaces/uniswap/IUniswapV2Pair.sol";
import "../../interfaces/uniswap/IWETH.sol";

import "hardhat/console.sol";

abstract contract BenqiFarm is Initializable, ICompound, ISwappable, IUniLp {
	address private _harvestTo;
	IERC20 _farmToken;
	IUniswapV2Pair private _farmPair;

	function __BenqiFarm_init_unchained(address pair_, address token_) internal initializer {
		_farmPair = IUniswapV2Pair(pair_);
		_farmToken = IERC20(token_);
		address harvestTo_ = _farmPair.token0();
		_harvestTo = harvestTo_ == token_ ? _farmPair.token1() : harvestTo_;
	}

	function _pendingLendingHarvest() internal view returns (uint256 pendingWant) {
		uint256 pendingQi = IBenqiComptroller(address(comptroller())).rewardAccrued(
			0,
			address(this)
		);

		uint256 pendingShort = pendingQi == 0
			? 0
			: UniUtils._getAmountOut(_farmPair, pendingQi, address(_farmToken), address(short()));
		pendingShort += IBenqiComptroller(address(comptroller())).rewardAccrued(1, address(this));
		pendingWant = pendingShort == 0
			? 0
			: UniUtils._getAmountOut(pair(), pendingShort, address(short()), address(underlying()));
	}

	function onUpgradeLend() public {
		address harvestTo_ = _farmPair.token0();
		_harvestTo = harvestTo_ == address(_farmToken) ? _farmPair.token1() : harvestTo_;
	}

	function _harvestLending(uint256) internal override {
		// uint256 pending = _pendingLendingHarvest();
		// if (pending < minHarvest) return;

		// qi rewards
		IBenqiComptroller(address(comptroller())).claimReward(0, payable(address(this)));
		uint256 harvest = _farmToken.balanceOf(address(this));
		// console.log("banqi harvest qi", farmTokenBalance);

		if (harvest > 0)
			_swapExactTokensForTokens(_farmPair, harvest, address(_farmToken), _harvestTo);

		// specific to benqi
		// avax rewards - we handle re-deposit here because strategy is not aware of these rewards
		IBenqiComptroller(address(comptroller())).claimReward(1, payable(address(this)));
		uint256 avaxBalance = address(this).balance;

		emit LendHarvest(harvest, avaxBalance, 0);
		// use avaxBalance to repay a portion of the loan
		if (avaxBalance > 0) _repayBase(avaxBalance);
	}

	uint256[50] private _gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "../../interfaces/compound/ICTokenInterfaces.sol";
import "../../interfaces/compound/IComptroller.sol";
import "../../interfaces/compound/ICompPriceOracle.sol";
import "../../interfaces/compound/IComptroller.sol";

import "../../mixins/ICompound.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "hardhat/console.sol";

// TODO supplyCaps

abstract contract Compound is Initializable, ICompound {
	using SafeERC20 for IERC20;

	ICTokenErc20 private _cTokenLend;
	ICTokenErc20 private _cTokenBorrow;

	IComptroller private _comptroller;
	ICompPriceOracle private _oracle;

	uint256 private _safeCollateralRatio; // percentage of max ratio

	function __Compound_init_unchained(
		address comptroller_,
		address cTokenLend_,
		address cTokenBorrow_,
		uint256 safeCollateralRatio_
	) internal initializer {
		_cTokenLend = ICTokenErc20(cTokenLend_);
		_cTokenBorrow = ICTokenErc20(cTokenBorrow_);
		_comptroller = IComptroller(comptroller_);
		_oracle = ICompPriceOracle(ComptrollerV1Storage(comptroller_).oracle());

		_safeCollateralRatio = safeCollateralRatio_;
		_enterMarket();
	}

	function _addLendingApprovals() internal override {
		// ensure USDC approval - assume we trust USDC
		underlying().safeApprove(address(_cTokenLend), type(uint256).max);
		short().safeApprove(address(_cTokenBorrow), type(uint256).max);
	}

	function safeCollateralRatio() public view override(ILending) returns (uint256) {
		return _safeCollateralRatio;
	}

	function cTokenLend() public view override returns (ICTokenErc20) {
		return _cTokenLend;
	}

	function cTokenBorrow() public view override returns (ICTokenErc20) {
		return _cTokenBorrow;
	}

	function oracle() public view override returns (ICompPriceOracle) {
		return _oracle;
	}

	function comptroller() public view override returns (IComptroller) {
		return _comptroller;
	}

	uint256[50] private _gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { IMasterChef } from "../../interfaces/uniswap/IStakingRewards.sol";
import "../../interfaces/uniswap/IUniswapV2Pair.sol";

import "../../mixins/IFarmable.sol";
import "../../mixins/ISwappable.sol";
import "../../mixins/IUniLp.sol";

import "hardhat/console.sol";

abstract contract MasterChefFarm is Initializable, IFarmable, ISwappable, IUniLp {
	using SafeERC20 for IERC20;

	IMasterChef private _farm;
	IUniswapV2Pair private _farmPair;
	IERC20 private _farmToken;
	IUniswapV2Pair private _pair;
	uint256 private _farmId;
	address private _harvestTo;

	function __MasterChefFarm_init_unchained(
		address pair_,
		address farm_,
		address farmPair_,
		address farmToken_,
		uint256 farmPid_
	) internal initializer {
		_farm = IMasterChef(farm_);
		_farmPair = IUniswapV2Pair(farmPair_);
		_farmToken = IERC20(farmToken_);
		_pair = IUniswapV2Pair(pair_);
		_farmId = farmPid_;
		address harvestTo_ = _farmPair.token0();
		_harvestTo = harvestTo_ == farmToken_ ? _farmPair.token1() : harvestTo_;
	}

	function onUpgradeFarm() public {
		address harvestTo_ = _farmPair.token0();
		_harvestTo = harvestTo_ == address(_farmToken) ? _farmPair.token1() : harvestTo_;
	}

	function _addFarmApprovals() internal {
		IERC20(address(_pair)).safeApprove(address(_farm), type(uint256).max);
	}

	function pair() public view override returns (IUniswapV2Pair) {
		return _pair;
	}

	function _withdrawFromFarm(uint256 amount) internal override {
		_farm.withdraw(_farmId, amount);
	}

	function _depositIntoFarm(uint256 amount) internal override {
		_farm.deposit(_farmId, amount);
	}

	function _harvestFarm() internal override {
		_farm.deposit(_farmId, 0);
		uint256 harvested = _farmToken.balanceOf(address(this));
		if (harvested == 0) return;
		harvested = _swapExactTokensForTokens(
			_farmPair,
			harvested,
			address(_farmToken),
			_harvestTo
		);
		emit LpHarvest(harvested);
	}

	function _getFarmLp() internal view override returns (uint256) {
		(uint256 lp, ) = _farm.userInfo(_farmId, address(this));
		return lp;
	}

	function _getLiquidity() internal view override returns (uint256) {
		uint256 farmLp = _getFarmLp();
		uint256 poolLp = _pair.balanceOf(address(this));
		return farmLp + poolLp;
	}

	uint256[49] private _gap;
}
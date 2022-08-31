/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-30
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

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

// File @openzeppelin/contracts-upgradeable/token/ERC20/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data)
        private
    {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

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
        require(
            _initializing ? _isConstructor() : !_initialized,
            "Initializable: contract is already initialized"
        );

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

// File @openzeppelin/contracts-upgradeable/security/[email protected]

// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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

// File @openzeppelin/contracts-upgradeable/security/[email protected]

// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File @openzeppelin/contracts-upgradeable/utils/math/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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

// File @chainlink/contracts/src/v0.8/interfaces/[email protected]

pragma solidity ^0.8.0;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// File contracts/XZeusV2Upgradable.sol

pragma solidity 0.8.16;
pragma abicoder v2;

contract XZeusV2 is
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    struct ReceiptInfo {
        address user; // staker address
        uint256 amount; // staked amount
        uint256 poolId; // pool id
        uint256 unlockedAt; // unlock timestamp
        uint256 rewardDebt; // debt
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20Upgradeable stakingToken; // Address of staking token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. ZEUSs to distribute per block.
        uint256 lastRewardBlock; // Last block number that ZEUSs distribution occurs.
        uint256 accZeusPerShare; // Accumulated ZEUSs per share, times PRECISION_FACTOR. See below.
        uint256 totalShares; // Balance of total staked amount in the pool
        uint256 lockDuration; // lock duration
    }

    // Info of penalty.
    struct PenaltyInfo {
        uint256 criteria; // Criteria minimum
        uint256 penalty; // Fee in usd
    }

    // Info of random number request
    struct RandomRequestInfo {
        address requester;
        uint256 receiptId;
    }

    // For stakerId handling
    CountersUpgradeable.Counter private _stakerIdPointer;

    // The REWARD TOKEN
    IERC20Upgradeable public rewardToken;

    uint256 public rewardDecimal;

    // The REWARD HOLDER
    address public rewardHolder;

    // ZEUS token fee recipient
    address public feeRecipient;

    // ZEUS tokens created per block.
    uint256 public rewardPerBlock;

    // Bonus muliplier for early zeus makers.
    uint256 public BONUS_MULTIPLIER;

    // precision factor
    uint256 public PRECISION_FACTOR;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each penalty info.
    mapping(uint256 => PenaltyInfo[]) penaltyInfo; // pool id => penaltyInfo

    // receipt infos (receiptId => receipt info)
    mapping(uint256 => ReceiptInfo) receiptInfo;

    // Info of each user that stakes staking tokens. (poolId => user address => receipt ids)
    mapping(uint256 => mapping(address => uint256[])) public userInfo;

    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;

    mapping(uint256 => RandomRequestInfo) randomRequestInfo; //  => requestId => requester Info

    AggregatorV3Interface internal avaxPriceFeed;

    event Deposited(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdrawed(
        address indexed user,
        uint256 indexed pid,
        uint256 amount,
        uint256 rewardAmount
    );
    event EmergencyWithdrawed(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event Claimed(
        address indexed user,
        uint256 indexed pid,
        uint256 rewardAmount
    );

    /**
     * @notice Constructor. Set reward token, reward emission rate and create a new pool with the params
     * @param _stakingToken  address of token of first pool
     * @param _rewardToken  address of reward token
     * @param _rewardDecimal  decimal of reward token
     * @param _rewardPerBlock  emission rate of reward token
     * @param _rewardHolder  address of reward holder who has enough reward tokens
     * @param _feeRecipient  address of fee recipient
     */
    function initialize(
        IERC20Upgradeable _stakingToken,
        IERC20Upgradeable _rewardToken,
        uint256 _rewardDecimal,
        uint256 _rewardPerBlock,
        address _rewardHolder,
        address _feeRecipient
    ) public initializer {
        require(
            address(_stakingToken) != address(0),
            "Zero address: stakingToken"
        );
        require(
            address(_rewardToken) != address(0),
            "Zero address: rewardToken"
        );
        require(_rewardHolder != address(0), "Zero address: rewardHolder");
        require(_feeRecipient != address(0), "Zero address: feeRecipient");

        rewardToken = _rewardToken;
        rewardPerBlock = _rewardPerBlock;
        rewardDecimal = _rewardDecimal;

        // staking pool with no lock duration
        poolInfo.push(
            PoolInfo({
                stakingToken: _stakingToken,
                allocPoint: 1000,
                lastRewardBlock: block.number,
                accZeusPerShare: 0,
                totalShares: 0,
                lockDuration: 0
            })
        );

        rewardHolder = _rewardHolder;
        feeRecipient = _feeRecipient;

        /**
         * Network: Avalanche Mainnet
         * Aggregator: AVAX/USD
         * Address: 0x0A77230d17318075983913bC2145DB16C7366156
         */
        avaxPriceFeed = AggregatorV3Interface(
            // 0x0A77230d17318075983913bC2145DB16C7366156
            0x5498BB86BC934c8D34FDA08E81D444153d0D06aD
        );

        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();

        BONUS_MULTIPLIER = 100;
        PRECISION_FACTOR = 1e12;
        totalAllocPoint = 1000;
    }

    /**
     * @notice Return a length of pools
     */
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    /**
     * @notice Return a length of pools
     * @param _receiptId  receipt id
     */
    function getReceipt(uint256 _receiptId)
        external
        view
        returns (ReceiptInfo memory)
    {
        return receiptInfo[_receiptId];
    }

    /**
     * @notice Return a length of pools
     * @param _pid  pool id
     * @param _user  user address
     */
    function getReceiptIds(uint256 _pid, address _user)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory receiptIds = new uint256[](
            userInfo[_pid][_user].length
        );
        for (uint256 index = 0; index < userInfo[_pid][_user].length; index++) {
            receiptIds[index] = userInfo[_pid][_user][index];
        }
        return receiptIds;
    }

    /**
     * @notice Return a length of pools
     * @param _pid  pool id
     * @param _user  user address
     */
    function getReceipts(uint256 _pid, address _user)
        external
        view
        returns (ReceiptInfo[] memory)
    {
        ReceiptInfo[] memory receipts = new ReceiptInfo[](
            userInfo[_pid][_user].length
        );
        for (uint256 index = 0; index < userInfo[_pid][_user].length; index++) {
            uint256 receiptId = userInfo[_pid][_user][index];
            receipts[index] = receiptInfo[receiptId];
        }
        return receipts;
    }

    /**
     * @notice Return reward multiplier over the given _from to _to block.
     * @param _from  from block number
     * @param _to  to block number
     */
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        return _to.sub(_from).mul(BONUS_MULTIPLIER).div(100);
    }

    /**
     * @notice Get penalty from deposit amount
     * @param _pid  pool id
     * @param _amount  amount
     */
    function getPenalty(uint256 _pid, uint256 _amount)
        public
        view
        returns (uint256)
    {
        uint256 penalty;
        if (penaltyInfo[_pid].length == 0) return 0;

        for (uint256 i = 0; i < penaltyInfo[_pid].length; i++) {
            if (_amount > penaltyInfo[_pid][i].criteria) {
                penalty = penaltyInfo[_pid][i].penalty;
            } else {
                break;
            }
        }

        return penalty / (getLatestAvaxPrice() / 1e8);
    }

    /**
     * @notice View function to see pending Reward on frontend.
     * @param _receiptId  receipt id
     */
    function pendingReward(uint256 _receiptId)
        external
        view
        returns (uint256, bool)
    {
        ReceiptInfo storage receipt = receiptInfo[_receiptId];
        PoolInfo memory pool = poolInfo[receipt.poolId];

        uint256 accZeusPerShare = pool.accZeusPerShare;
        uint256 stakingTokenSupply = pool.totalShares;

        if (block.number > pool.lastRewardBlock && stakingTokenSupply != 0) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                block.number
            );
            uint256 usdcReward = multiplier
                .mul(rewardPerBlock)
                .mul(pool.allocPoint)
                .div(totalAllocPoint);

            accZeusPerShare = accZeusPerShare.add(
                (usdcReward.mul(PRECISION_FACTOR).div(stakingTokenSupply))
            );
        }

        return (
            receipt
                .amount
                .mul(accZeusPerShare)
                .div(PRECISION_FACTOR)
                .mul(10**rewardDecimal)
                .div(1e18)
                .sub(receipt.rewardDebt),
            block.timestamp >= receipt.unlockedAt
        );
    }

    /**
     * @notice Add a new stakingToken to the pool. Can only be called by the owner.
     * XXX DO NOT add the same staking token more than once. Rewards will be messed up if you do.
     * @param _allocPoint  reward allocation point
     * @param _stakingToken  token address
     */
    function add(
        uint256 _allocPoint,
        IERC20Upgradeable _stakingToken,
        uint256 _lockDuration
    ) public whenNotPaused onlyOwner {
        require(
            address(_stakingToken) != address(0),
            "Staking token: Zero address"
        );
        for (uint256 i = 0; i < poolInfo.length; i++) {
            if (
                address(poolInfo[i].stakingToken) == address(_stakingToken) &&
                poolInfo[i].lockDuration == _lockDuration
            ) revert("Pool duplicated");
        }

        massUpdatePools();
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                stakingToken: _stakingToken,
                allocPoint: _allocPoint,
                lastRewardBlock: block.number,
                accZeusPerShare: 0,
                totalShares: 0,
                lockDuration: _lockDuration
            })
        );
    }

    /**
     * @notice Update the given pool's ZEUS allocation point. Can only be called by the owner.
     * @param _pid  pool id
     * @param _allocPoint  reward allocation point
     */
    function set(uint256 _pid, uint256 _allocPoint)
        public
        whenNotPaused
        onlyOwner
    {
        massUpdatePools();
        uint256 prevAllocPoint = poolInfo[_pid].allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        if (prevAllocPoint != _allocPoint) {
            totalAllocPoint = totalAllocPoint.sub(prevAllocPoint).add(
                _allocPoint
            );
        }
    }

    /**
     * @notice Update multiplier. Can only be called by the owner.
     * @param _multiplierNumber  _multiplier value
     */
    function updateMultiplier(uint256 _multiplierNumber) public onlyOwner {
        require(_multiplierNumber >= 100, "Invalid multipler number");
        BONUS_MULTIPLIER = _multiplierNumber;
    }

    /**
     * @notice Add penalty info
     * @param _pid  pool id
     * @param _criteria  penalty criteria amount
     * @param _penalty  penalty point
     */
    function addPenaltyInfo(
        uint256 _pid,
        uint256 _criteria,
        uint256 _penalty
    ) public onlyOwner {
        uint256 penaltyLength = penaltyInfo[_pid].length;
        if (penaltyLength == 0) {
            penaltyInfo[_pid].push(
                PenaltyInfo({criteria: _criteria, penalty: _penalty})
            );
        } else {
            require(
                _criteria > penaltyInfo[_pid][penaltyLength - 1].criteria,
                "Criteria error: < last criteria"
            );

            penaltyInfo[_pid].push(
                PenaltyInfo({criteria: _criteria, penalty: _penalty})
            );
        }
    }

    /**
     * @notice Update penalty info
     * @param _pid  pool id
     * @param _criteria  penalty criteria amount
     * @param _penalty  penalty point
     */
    function updatePenaltyInfo(
        uint256 _pid,
        uint256 _criteria,
        uint256 _penalty
    ) public whenNotPaused onlyOwner {
        bool isUpdated;
        for (uint256 index = 0; index < penaltyInfo[_pid].length; index++) {
            if (penaltyInfo[_pid][index].criteria == _criteria) {
                penaltyInfo[_pid][index].penalty = _penalty;
                isUpdated = true;
                break;
            }
        }
        if (!isUpdated) revert("Criteria is not matched");
    }

    /**
     * @notice Update reward holder
     * @param _rewardHolder  address of reward holder who has enough reward tokens
     */
    function setRewardHolder(address _rewardHolder)
        public
        whenNotPaused
        onlyOwner
    {
        require(_rewardHolder != address(0), "Zero address: rewardHolder");
        rewardHolder = _rewardHolder;
    }

    /**
     * @notice Update fee recipient
     * @param _feeRecipient  address of fee recipient
     */
    function setFeeRecipient(address _feeRecipient) public onlyOwner {
        require(_feeRecipient != address(0), "Zero address: feeRecipient");
        feeRecipient = _feeRecipient;
    }

    /**
     * @notice Update reward emission rate
     * @param _rewardPerBlock  reward emission rate
     */
    function setRewardPerBlock(uint256 _rewardPerBlock) public onlyOwner {
        rewardPerBlock = _rewardPerBlock;
    }

    /**
     * @notice Update reward variables of the given pool to be up-to-date.
     * @param _pid  pool id
     */
    function updatePool(uint256 _pid) public whenNotPaused {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 stakingTokenSupply = pool.totalShares;
        if (stakingTokenSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 usdcReward = multiplier
            .mul(rewardPerBlock)
            .mul(pool.allocPoint)
            .div(totalAllocPoint);
        pool.accZeusPerShare = pool.accZeusPerShare.add(
            usdcReward.mul(PRECISION_FACTOR).div(stakingTokenSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    /**
     * @notice Update reward variables for all pools
     */
    function massUpdatePools() public whenNotPaused {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    /**
     * @notice Deposit tokens
     * @param _pid  pool id
     * @param _amount  token amount
     */
    function deposit(uint256 _pid, uint256 _amount)
        public
        payable
        whenNotPaused
    {
        require(_amount != 0, "Amount should be greater than 0");
        require(_pid < poolInfo.length, "Pool is not existed");

        // avax fee handling
        uint256 feeAmount = getPenalty(_pid, _amount);
        require(msg.value >= feeAmount, "Insufficient AVAX balance");

        // udpate storage
        PoolInfo storage pool = poolInfo[_pid];
        updatePool(_pid);
        pool.totalShares += _amount;
        receiptInfo[_stakerIdPointer.current()] = ReceiptInfo({
            user: msg.sender,
            amount: _amount,
            poolId: _pid,
            unlockedAt: block.timestamp + pool.lockDuration,
            rewardDebt: _amount
                .mul(pool.accZeusPerShare)
                .div(PRECISION_FACTOR)
                .mul(10**rewardDecimal)
                .div(1e18)
        }); // create receipt
        uint256[] storage userReceipts = userInfo[_pid][msg.sender];
        userReceipts.push(_stakerIdPointer.current()); // update user receipt infomation
        _stakerIdPointer.increment(); // increase receipt id

        // staking token transfer
        pool.stakingToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );

        // transfer avax fee to feeRecipient
        payable(feeRecipient).transfer(feeAmount);

        emit Deposited(msg.sender, _pid, _amount);
    }

    /**
     * @notice Withdraw tokens
     * @param _receiptId  receipt id
     */
    function withdraw(uint256 _receiptId) public nonReentrant whenNotPaused {
        ReceiptInfo memory receipt = receiptInfo[_receiptId];
        require(receipt.user == msg.sender, "Staker address is not matched!");
        require(block.timestamp >= receipt.unlockedAt, "Withdrawal is locked");

        // update storage
        PoolInfo storage pool = poolInfo[receipt.poolId];
        updatePool(receipt.poolId);
        pool.totalShares -= receipt.amount;
        delete receiptInfo[_receiptId];

        // general reward token distribution
        uint256 pending = receipt
            .amount
            .mul(pool.accZeusPerShare)
            .div(PRECISION_FACTOR)
            .mul(10**rewardDecimal)
            .div(1e18)
            .sub(receipt.rewardDebt);
        if (pending > 0) {
            rewardToken.safeTransferFrom(rewardHolder, msg.sender, pending);
        }

        // staking token transfer
        pool.stakingToken.safeTransfer(msg.sender, receipt.amount);
        emit Withdrawed(msg.sender, receipt.poolId, receipt.amount, pending);
    }

    /**
     * @notice Claim receipt internal
     * @param _receiptId  receipt id
     */
    function _claim(uint256 _receiptId) internal {
        ReceiptInfo storage receipt = receiptInfo[_receiptId];
        require(receipt.user == msg.sender, "Staker address is not matched!");
        require(block.timestamp >= receipt.unlockedAt, "Withdrawal is locked");

        updatePool(receipt.poolId);
        PoolInfo memory pool = poolInfo[receipt.poolId];

        // general reward token distribution
        uint256 pending = receipt
            .amount
            .mul(pool.accZeusPerShare)
            .div(PRECISION_FACTOR)
            .mul(10**rewardDecimal)
            .div(1e18)
            .sub(receipt.rewardDebt);

        receipt.rewardDebt = receipt
            .amount
            .mul(pool.accZeusPerShare)
            .div(PRECISION_FACTOR)
            .mul(10**rewardDecimal)
            .div(1e18);

        if (pending > 0) {
            rewardToken.safeTransferFrom(rewardHolder, msg.sender, pending);
        }

        // staking token transfer
        emit Claimed(msg.sender, receipt.poolId, pending);
    }

    /**
     * @notice Claim receipt
     * @param _receiptId  receipt id
     */
    function claim(uint256 _receiptId) public nonReentrant whenNotPaused {
        _claim(_receiptId);
    }

    /**
     * @notice Batch Claim receipt
     * @param _poolId  pool id
     */
    function batchClaim(uint256 _poolId) public nonReentrant whenNotPaused {
        uint256[] memory receiptIds = getReceiptIds(_poolId, msg.sender);

        for (uint256 index = 0; index < receiptIds.length; index++) {
            _claim(receiptIds[index]);
        }
    }

    /**
     * @notice Withdraw without lock duration. EMERGENCY ONLY.
     * @param _receiptId  receipt id
     */
    function emergencyWithdraw(uint256 _receiptId)
        public
        nonReentrant
        whenNotPaused
    {
        ReceiptInfo memory receipt = receiptInfo[_receiptId];
        require(receipt.user == msg.sender, "Staker address is not matched!");

        // update storage
        PoolInfo storage pool = poolInfo[receipt.poolId];
        pool.totalShares -= receipt.amount;
        delete receiptInfo[_receiptId];

        // staking token transfer
        pool.stakingToken.safeTransfer(address(msg.sender), receipt.amount);
        emit EmergencyWithdrawed(msg.sender, receipt.poolId, receipt.amount);
    }

    /**
     * @notice Get latest AVAX price
     */
    function getLatestAvaxPrice() public view returns (uint256) {
        (, int256 price, , , ) = avaxPriceFeed.latestRoundData();
        return uint256(price);
    }
}
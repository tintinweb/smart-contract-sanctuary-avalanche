/**
 *Submitted for verification at snowtrace.io on 2022-04-23
*/

// SPDX-License-Identifier: MIT
// File: interfaces/IPangolinFactory.sol

pragma solidity >=0.5.0;

interface IPangolinFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}
// File: interfaces/IPangolinRouter.sol

pragma solidity >=0.6.2;

interface IPangolinRouter {
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
// File: interfaces/INodeManager.sol


pragma solidity ^0.8.0;

interface INodeManager {
    function getMinPrice() external view returns (uint256);
    function createNode(address account, string memory nodeName, uint256 amount) external;
    function createNodeAllInOne(address account, string memory nodeName, uint256 amount_) external;
    function multipleCreateNode(address account, string memory nodeName, uint256 amount, uint256 timeStamp) external;
    function getNodeReward(address account, uint256 _creationTime) external view returns (uint256);
    function getAllNodesRewards(address account) external view returns (uint256);
    function cashoutNodeReward(address account, uint256 _creationTime) external;
    function cashoutAllNodesRewards(address account) external;
    function compoundNodeReward(address account, uint256 creationTime, uint256 rewardAmount) external;
    function getNodeNumberOf(address account) external view returns (uint256);
    function transferOwnership(address newOwner) external;
    function getNodesNames(address account) external view returns (string memory);
    
}
// File: @openzeppelin/contracts/utils/Address.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/Context.sol


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


// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: @openzeppelin/contracts/access/Ownable.sol


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
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

pragma solidity ^0.8.0;

interface INodeManagerOLD {
    function getMinPrice() external view returns (uint256);
    function createNode(address account, string memory nodeName, uint256 amount) external;
    function getNodeReward(address account, uint256 _creationTime) external view returns (uint256);
    function getAllNodesRewards(address account) external view returns (uint256);
    function cashoutNodeReward(address account, uint256 _creationTime) external;
    function cashoutAllNodesRewards(address account) external;
    function compoundNodeReward(address account, uint256 creationTime, uint256 rewardAmount) external;
    function transferOwnership(address newOwner) external;
    function getNodeNumberOf(address account) external view returns (uint256);

    struct NodeEntity {string name;uint creationTime;uint lastClaimTime;uint256 amount;}
    function getAllNodes(address account) external view returns (NodeEntity[] memory);
}

pragma solidity ^0.8.4;

contract StormZv2 is ERC20, Ownable {
    using SafeMath for uint256;

    address public joePair;
    address public joeRouterAddress = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    uint256 public totalClaimed = 0;
    bool public isTradingEnabled = false;

    uint256 public nodeNumber = 1;
    uint256 public maxNodes = 100;

    bool public NFTboosterActivated = false;
    uint256 public boostPerNFT = 250000000000000000; //25e16
    uint256 public NFTboosterReset = 1440 minutes; //24hours

    bool public nodeSwapEnabled = false;
    bool public sellSwapEnabled = false;
    bool public cashoutSwapEnabled = false;
    
    uint256 public swapAmountPerNode = 5000000000000000000; //5e18
    uint256 public swapAmountPerSell = 20000000000000000000; //20e18
    uint256 public swapAmountPerCashout = 20000000000000000000; //20e18

    bool public maxWalletActivated = false;
    uint256 public maxWalletToken = 5000000000000000000000;

    uint256 public launchedAtTime = 0;
    uint public currentBlock = 0;
    
    bool public sellTaxActivated = false;
    uint16 public sellTax = 10; //10%
    uint256 public cashoutFee = 75; //7.5%

    uint256[] public cashoutFeeTiers = [1000, 900, 800, 700, 600, 500, 400, 300, 200, 100, 75];
    uint256[] public TiersRequiredDays = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 30];

    //cashout variables
    uint256 private feeAmount = 0;
    bool private active_NFT = false;
    uint256 private add_reward = 0;
    uint256 private elapsedTimeInMinutes = 0;
    uint256 private valid_NFT = 0;
    uint256 private booster_economy = 0;
    uint256 private numberboosternft = 0;
    uint256 private usernodes = 0;
    uint256 private fullTax = 0;

    //compound variables
    uint256 private maxCompoundNodes = 0;
    uint256 private actualUserNodes = 0;
    uint256 private compoundTime = 0;
    uint256 private diffCompoundNodes = 0;
    bool public sendDust = true;

    //migrate variables
    uint256 private migrateTime = 0;
    uint256 private loopTimeStamp = 0;
    uint256 private totalNodeValue = 0;
    uint256 private nodeValue = 0;

    IPangolinRouter private joeRouter;
    INodeManager private nodeManager;
    bool private swapping = false;

    IERC20 public OLD_CONTRACT = IERC20(0xb952Df7188AC2F81eee0C4C9aAAde6Ec4a5eeA06);
    INodeManagerOLD private OLD_MANAGER = INodeManagerOLD(0x7C2A55031318F636593B7824A8D95443Ead23210);

    IERC20 public boosterNFTaddress = IERC20(0x35F1DeD4b275Bf3Ac06804B9AE413f40C2a8B121);
    address public rewardsPool = 0x1492694fE39052e43f654D1686cAF27EdA66F2e4;
   
    address[] path;

    mapping(address => bool) public isBlacklisted;
    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => uint) public userLastBlockBuyTransactions;
    mapping(address => uint256) public _lastClaim;
    mapping(address => bool) public hasMigrate;
    
    event UpdateJoeRouter(
        address indexed newAddress,
        address indexed oldAddress
    );

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event Cashout(
        address indexed account,
        uint256 amount,
        uint256 indexed blockTime
    );

    event Compound(
        address indexed account,
        uint256 amount,
        uint256 indexed blockTime
    );

    constructor(address[] memory addresses)
        ERC20("STORMZv2", "STORMZv2")
    {
        require(addresses[0] != address(0), "CONSTR:1");
        nodeManager = INodeManager(addresses[0]);

        require(joeRouterAddress != address(0), "CONSTR:2");
        IPangolinRouter _joeRouter = IPangolinRouter(joeRouterAddress);

        address _joePair = IPangolinFactory(_joeRouter.factory())
        .createPair(address(this), _joeRouter.WAVAX());

        joeRouter = _joeRouter;
        joePair = _joePair;

        _setAutomatedMarketMakerPair(_joePair, true);

        path = new address[](2);
        path[0] = address(this);
        path[1] = joeRouter.WAVAX();

        mintRewards(rewardsPool, 1e6 * 1e18);
        mintRewards(owner(), 2e4 * 1e18);

    }

    function migrate(address[] memory addresses_, uint256[] memory balances_) external onlyOwner {
        for (uint256 i = 0; i < addresses_.length; i++) {
            _mint(addresses_[i], balances_[i]);
        }
    }

    function burn(address account, uint256 amount) external onlyOwner {
        _burn(account, amount);
    }

    function updateJoeRouterAddress(address newAddress) external onlyOwner {
        require(newAddress != address(joeRouter), "TKN:1");
        emit UpdateJoeRouter(newAddress, address(joeRouter));
        IPangolinRouter	 _joeRouter = IPangolinRouter(newAddress);
        address _joePair = IPangolinFactory(joeRouter.factory()).createPair(address(this), _joeRouter.WAVAX());
        joePair = _joePair;
        joeRouterAddress = newAddress;
    }

    function updateRewardsPool(address payable newVal) external onlyOwner {
        rewardsPool = newVal;
    }   

    function updateIsTradingEnabled(bool newVal) external onlyOwner {
        isTradingEnabled = newVal;
        if(launchedAtTime==0){
            launchedAtTime = block.timestamp;
        }
    }

    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner
    {
        require(pair != joePair, "TKN:2");
        _setAutomatedMarketMakerPair(pair, value);
    }

    function boosterNFTcontract(address _nftcontract) external onlyOwner {
        boosterNFTaddress = IERC20(_nftcontract);
    }

    function activateBoosterNFTcontract(bool _status) external onlyOwner {
        NFTboosterActivated = _status;
    }

    function updateBoostPerNFT(uint256 value) external onlyOwner {
        boostPerNFT = value;
    }

    function updateNFTboosterReset(uint256 value) external onlyOwner {
        NFTboosterReset = value * 1 minutes;
    }

    function updateNodeSwap(bool newVal) external onlyOwner {
        nodeSwapEnabled = newVal;
    }

    function updateSellSwap(bool newVal) external onlyOwner {
        sellSwapEnabled = newVal;
    }

    function updateCashoutSwap(bool newVal) external onlyOwner {
        cashoutSwapEnabled = newVal;
    }

    function sendDustUpdate(bool _status) external onlyOwner {
        sendDust = _status;
    }

    function updateSwapAmountPerNode(uint256 value) external onlyOwner {
        swapAmountPerNode = value;
    }

    function updateSwapAmountPerSell(uint256 value) external onlyOwner {
        swapAmountPerSell = value;
    }

    function updateSwapAmountPerCashout(uint256 value) external onlyOwner {
        swapAmountPerCashout = value;
    }

    function updateMaxWalletActivation(bool _status) external onlyOwner {
        maxWalletActivated = _status;
    }

    function updateMaxWalletToken(uint256 value) external onlyOwner {
        maxWalletToken = value;
    }

    function updateSellTaxActivation(bool _status) external onlyOwner {
        sellTaxActivated = _status;
    }

    function setSellTax(uint16 value) external onlyOwner {
        sellTax = value;
    }

    function updateCashoutFeeTiers(uint256[] calldata newVal) external onlyOwner {
        require(newVal.length == 11, "Wrong length");
        cashoutFeeTiers = newVal;
    }

    function updateTiersRequiredDays(uint256[] calldata newVal) external onlyOwner {
        require(newVal.length == 11, "Wrong length");
        TiersRequiredDays = newVal;
    }

    function blacklistAddress(address account, bool value) external onlyOwner {
        isBlacklisted[account] = value;
    }

    // Private methods

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "TKN:3");
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        address sender = _msgSender();
        require(!isBlacklisted[from] && !isBlacklisted[to], "BLACKLISTED");
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (from != owner() && to != joePair && to != address(joeRouter) && to != address(this) && from != address(this)) {
            require(isTradingEnabled, "TRADING_DISABLED");
        }

        if (to == joePair) {
            if (sellSwapEnabled && !swapping && isTradingEnabled) {
                uint256 contractTokenBalance = balanceOf(address(this));
                if(contractTokenBalance >= swapAmountPerSell ){
                    swapping = true;
                    swapTokensForAVAX(swapAmountPerSell);
                    swapping = false;
                }
            }

            if(sellTax != 0 && sellTaxActivated && from != address(this) && sender != owner()){
                uint256 taxAmount = amount * sellTax/100;
                uint256 sendAmount = amount - taxAmount;
                require (amount == taxAmount + sendAmount, "Invalid Tax");
                super._transfer(from, address(this), taxAmount);
                super._transfer(from, to, sendAmount);
            }else{
                super._transfer(from, to, amount); 
            }

        }else{
            if(from == joePair && sender != owner()){
                if(maxWalletActivated){
                    require(amount + balanceOf(sender) <= maxWalletToken , "Total holding is limited");
                }
            }
            super._transfer(from, to, amount);          
        }

    }

    function mintRewards(address receiver, uint256 _amount) private {
        _mint(receiver, _amount);
    }

    function swapAndSendToFee(address destination, uint256 tokens) private {
        swapTokensForAVAX(tokens);
        uint256 AVAXBalance = address(this).balance;
        if(AVAXBalance > 0){
            payable(destination).transfer(AVAXBalance);
        }
    }

    function swapTokensForAVAX(uint256 tokenAmount) private {
        _approve(address(this), address(joeRouter), tokenAmount);
        joeRouter.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of AVAX
            path,
            address(this),
            block.timestamp
        );
    }

    // External node methods

    function createNodeWithTokens(uint256 amount_) external {
        address sender = _msgSender();
        require(sender != address(0), "NC:2");
        require(!isBlacklisted[sender], "BLACKLISTED");
        require(sender != rewardsPool, "NC:4");
        require(balanceOf(sender) >= amount_, "NC:5");

        uint256 contractTokenBalance = balanceOf(address(this));

        if (nodeSwapEnabled && !swapping && sender != owner() && !automatedMarketMakerPairs[sender]) {
            if(contractTokenBalance >= swapAmountPerNode ){
                swapping = true;
                swapTokensForAVAX(swapAmountPerNode);
                swapping = false;
            }
        }

        super._transfer(sender, address(this), amount_);

        nodeManager.createNode(sender, uint2str(nodeNumber), amount_);
        nodeNumber++;
    }

    function createMultipleNodeWithTokens(uint256 amount_, uint256 nodeamount_) external {
        address sender = _msgSender();
        require(sender != address(0), "NC:2");
        require(!isBlacklisted[sender], "BLACKLISTED");
        require(sender != rewardsPool, "NC:4");
        require(balanceOf(sender) >= amount_ * nodeamount_, "NC:5");
        require(nodeamount_ >= 1, "NC:5");

        loopTimeStamp = block.timestamp;

        super._transfer(sender, address(this), amount_ * nodeamount_);

        for (uint256 i = 1; i <= nodeamount_ ; i++) {
            nodeManager.multipleCreateNode(sender, uint2str(nodeNumber), amount_, loopTimeStamp + i);
            nodeNumber++;
        }

        if (nodeSwapEnabled && !swapping && sender != owner() && !automatedMarketMakerPairs[sender]) {
            uint256 contractTokenBalance = balanceOf(address(this));
            if(contractTokenBalance >= (swapAmountPerNode * nodeamount_)){
                swapping = true;
                swapTokensForAVAX(swapAmountPerNode * nodeamount_);
                swapping = false;
            }
        }
    }

    function userMigrateStatus(address migrateUser) public view returns (bool) {
        if(!hasMigrate[migrateUser]){
            uint256 nodeNb = OLD_MANAGER.getNodeNumberOf(migrateUser);
            uint256 amount = OLD_CONTRACT.balanceOf(migrateUser);
            if(nodeNb > 0 || amount > 0){
                return false;
            }else{
                return true;
            }
        }else{
            return true;
        }
        
    }

    function migrateNodesAllInOne() external {
        address sender = _msgSender();
        require(!hasMigrate[sender], "Already migrated.");
        
        INodeManagerOLD.NodeEntity[] memory _nodes = OLD_MANAGER.getAllNodes(sender);
        totalNodeValue = 0;

        if(_nodes.length > 100){
            for (uint256 i = 1; i <= 100; i++) {
                totalNodeValue += _nodes[i-1].amount;
            }         
        }else{
            for (uint256 i = 1; i <= _nodes.length; i++) {
                totalNodeValue += _nodes[i-1].amount;
            }
        }

        if(_nodes.length > 0){
            nodeManager.createNodeAllInOne(sender, "STORMZ_V1", totalNodeValue);
            nodeNumber++;
        }

        uint256 amount = OLD_CONTRACT.balanceOf(sender);
        if(amount > 0){
            super._transfer(rewardsPool, sender, amount);
        }
        
        hasMigrate[sender] =  true;
    }

    function migrateNodes() external {
        address sender = _msgSender();
        require(!hasMigrate[sender], "Already migrated.");
        
        INodeManagerOLD.NodeEntity[] memory _nodes = OLD_MANAGER.getAllNodes(sender);

        if(_nodes.length > 0){
            migrateTime = block.timestamp;
            if(_nodes.length > 100){
                for (uint256 i = 1; i <= 100; i++) {
                    nodeManager.multipleCreateNode(sender, concatenate("STORMZ_V1-", uint2str(i)), _nodes[i-1].amount, migrateTime + i);
                    nodeNumber++;
                }
            }else{
                for (uint256 i = 1; i <= _nodes.length; i++) {
                    nodeManager.multipleCreateNode(sender, concatenate("STORMZ_V1-", uint2str(i)), _nodes[i-1].amount, migrateTime + i);
                    nodeNumber++;
                }
            }           
        }

        uint256 amount = OLD_CONTRACT.balanceOf(sender);
        if(amount > 0){
            super._transfer(rewardsPool, sender, amount);
        }

        hasMigrate[sender] =  true;
    }    

    function concatenate(string memory a,string memory b) public pure returns (string memory){
        return string(bytes.concat(bytes(a), "", bytes(b)));
    }         

    function uint2str(uint256 _i) private pure returns (string memory _uintAsString){
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function strToUint(string memory _str) public pure returns(uint256 res) { 
        for (uint256 i = 0; i < bytes(_str).length; i++) {
            if ((uint8(bytes(_str)[i]) - 48) < 0 || (uint8(bytes(_str)[i]) - 48) > 9) {
                return (0);
            }
            res += (uint8(bytes(_str)[i]) - 48) * 10**(bytes(_str).length - i - 1);
        }
        return (res);
    }

    function cashoutAll() external {
        address sender = _msgSender();
        require(sender != address(0), "CASHOUT:5");
        require(!isBlacklisted[sender], "BLACKLISTED");
        require(sender != rewardsPool, "CASHOUT:7");
        uint256 rewardAmount = nodeManager.getAllNodesRewards(sender);
        require(rewardAmount > 0, "CASHOUT:8");

        if (cashoutSwapEnabled && !swapping && sender != owner() && !automatedMarketMakerPairs[sender]) {
            uint256 contractTokenBalance = balanceOf(address(this));
            if(contractTokenBalance >= swapAmountPerCashout){
                swapping = true;
                swapTokensForAVAX(swapAmountPerCashout);
                swapping = false;
            }
        }
          
        if(_lastClaim[sender] > 0){
            elapsedTimeInMinutes = (block.timestamp - _lastClaim[sender]) / 1 minutes;
        }else{
            elapsedTimeInMinutes = (block.timestamp - launchedAtTime) / 1 minutes;
        }
            
        cashoutFee = calculateCashoutFee(elapsedTimeInMinutes);

        if(NFTboosterActivated){
            numberboosternft = boosterNFTaddress.balanceOf(sender);
            if(numberboosternft > 0){
                active_NFT = true;
                usernodes = nodeManager.getNodeNumberOf(sender);
                if(numberboosternft > usernodes){
                    add_reward = usernodes.mul(boostPerNFT).mul(elapsedTimeInMinutes).div(NFTboosterReset);
                    valid_NFT =  usernodes;
                }else if(numberboosternft == usernodes){
                    add_reward = numberboosternft.mul(boostPerNFT).mul(elapsedTimeInMinutes).div(NFTboosterReset);
                    valid_NFT =  usernodes;
                }else{
                    add_reward = numberboosternft.mul(boostPerNFT).mul(elapsedTimeInMinutes).div(NFTboosterReset);
                    valid_NFT =  numberboosternft;
                }
                //calculate new tax
                fullTax = rewardAmount.mul(cashoutFee).div(1000);
                booster_economy = fullTax.mul(valid_NFT).div(usernodes);
                feeAmount = fullTax.sub(booster_economy);
            }
        }

        if(!active_NFT){
            feeAmount = rewardAmount.mul(cashoutFee).div(1000);
            if(feeAmount > 0){
                rewardAmount -= feeAmount;
            }
        }else{
            if(feeAmount > 0){
                rewardAmount -= feeAmount;
            }           
            rewardAmount += add_reward;
        }


        //reset claim tracker
        _lastClaim[sender] = block.timestamp;
       
        super._transfer(rewardsPool, sender, rewardAmount);
        super._transfer(rewardsPool, address(this), feeAmount);

        nodeManager.cashoutAllNodesRewards(sender);
        totalClaimed += rewardAmount;

        //reset variables
        feeAmount = 0;
        active_NFT = false;
        add_reward = 0;
        elapsedTimeInMinutes = 0;
        valid_NFT = 0;
        booster_economy = 0;
        numberboosternft = 0;
        usernodes = 0;
        fullTax = 0;

        emit Cashout(sender, rewardAmount, 0);
    }

    function calculateCashoutFee(uint _elapsedTime) internal view returns (uint256) {
        uint256 elapsedTimeInDays = (_elapsedTime * 1 minutes) / 1 days;

        if (elapsedTimeInDays >= TiersRequiredDays[10]) {
            return cashoutFeeTiers[10];
        } else if (elapsedTimeInDays >= TiersRequiredDays[9]) {
            return cashoutFeeTiers[9];
        } else if (elapsedTimeInDays >= TiersRequiredDays[8]) {
            return cashoutFeeTiers[8];
        } else if (elapsedTimeInDays >= TiersRequiredDays[7]) {
            return cashoutFeeTiers[7];
        } else if (elapsedTimeInDays >= TiersRequiredDays[6]) {
            return cashoutFeeTiers[6];
        } else if (elapsedTimeInDays >= TiersRequiredDays[5]) {
            return cashoutFeeTiers[5];
        } else if (elapsedTimeInDays >= TiersRequiredDays[4]) {
            return cashoutFeeTiers[4];
        } else if (elapsedTimeInDays >= TiersRequiredDays[3]) {
            return cashoutFeeTiers[3];
        } else if (elapsedTimeInDays >= TiersRequiredDays[2]) {
            return cashoutFeeTiers[2];
        } else if (elapsedTimeInDays >= TiersRequiredDays[1]) {
            return cashoutFeeTiers[1];
        } else {
            return cashoutFeeTiers[0];
        }
    }

    function returnCashoutFee(address sender) public view returns (uint256) {
        uint256 elapsedTimeInDays = 0;
        if(_lastClaim[sender]>0){
            elapsedTimeInDays = (block.timestamp - _lastClaim[sender]) / 1 days;
        }else{
            elapsedTimeInDays = (block.timestamp - launchedAtTime) / 1 days;
        }

        if (elapsedTimeInDays >= TiersRequiredDays[10]) {
            return cashoutFeeTiers[10];
        } else if (elapsedTimeInDays >= TiersRequiredDays[9]) {
            return cashoutFeeTiers[9];
        } else if (elapsedTimeInDays >= TiersRequiredDays[8]) {
            return cashoutFeeTiers[8];
        } else if (elapsedTimeInDays >= TiersRequiredDays[7]) {
            return cashoutFeeTiers[7];
        } else if (elapsedTimeInDays >= TiersRequiredDays[6]) {
            return cashoutFeeTiers[6];
        } else if (elapsedTimeInDays >= TiersRequiredDays[5]) {
            return cashoutFeeTiers[5];
        } else if (elapsedTimeInDays >= TiersRequiredDays[4]) {
            return cashoutFeeTiers[4];
        } else if (elapsedTimeInDays >= TiersRequiredDays[3]) {
            return cashoutFeeTiers[3];
        } else if (elapsedTimeInDays >= TiersRequiredDays[2]) {
            return cashoutFeeTiers[2];
        } else if (elapsedTimeInDays >= TiersRequiredDays[1]) {
            return cashoutFeeTiers[1];
        } else {
            return cashoutFeeTiers[0];
        }
    }    

    function getUserBoost(address sender) public view returns(uint256) {
        uint256 getElapsedTimeInMinutes;
        if(_lastClaim[sender]>0){
            getElapsedTimeInMinutes = (block.timestamp - _lastClaim[sender]) / 1 minutes;
        }else{
            getElapsedTimeInMinutes = (block.timestamp - launchedAtTime) / 1 minutes;
        }
            uint256 getNumberboosternft = boosterNFTaddress.balanceOf(sender);
            uint256 getBoost = 0;
            if(getNumberboosternft > 0){
                uint256 getUsernodes = nodeManager.getNodeNumberOf(sender);
                if(getNumberboosternft > getUsernodes){
                    getBoost = getUsernodes.mul(boostPerNFT).mul(getElapsedTimeInMinutes).div(NFTboosterReset);
                }else if(getNumberboosternft == getUsernodes){
                    getBoost = getNumberboosternft.mul(boostPerNFT).mul(getElapsedTimeInMinutes).div(NFTboosterReset);
                }else{
                    getBoost = getNumberboosternft.mul(boostPerNFT).mul(getElapsedTimeInMinutes).div(NFTboosterReset);
                }
                return getBoost;
            }else{
                return 0;
            }
    }

    function compoundAllNodes() external {
        address sender = _msgSender();
        uint256 rewardAmount = nodeManager.getAllNodesRewards(sender);
        require(rewardAmount >= 10e18,"Not enough rewards to compound");

        maxCompoundNodes = rewardAmount/10000000000000000000;

        compoundTime = block.timestamp;
        for (uint256 i = 1; i <= maxCompoundNodes; i++) {
            nodeManager.multipleCreateNode(sender, uint2str(nodeNumber), 10e18, compoundTime + i);
            nodeNumber++;
        }

        super._transfer(rewardsPool, address(this), maxCompoundNodes * 10e18);
        

        if(sendDust){
            diffCompoundNodes = rewardAmount.sub(maxCompoundNodes * 10e18);
            if(diffCompoundNodes > 0){
                super._transfer(rewardsPool, sender, diffCompoundNodes);
            }
        }

        nodeManager.cashoutAllNodesRewards(sender);
        emit Cashout(sender, rewardAmount, 0);
    }

    function nodeAirdrop(string[] calldata name, uint256[] calldata value, address[] calldata addresses) public onlyOwner {
        for (uint256 i=0; i < addresses.length; i++) {
            require(addresses[i] != address(0),"NC:2");
            require(!isBlacklisted[addresses[i]], "BLACKLISTED");
            require(addresses[i] != rewardsPool,"NC:4");
            nodeManager.createNode(addresses[i], name[i], value[i]);
            nodeNumber++;
        }
    } 

    function withdraw() onlyOwner external {
        payable(owner()).transfer(address(this).balance);
    }   

    function withdrawTokens(address _tokencontract) onlyOwner external  {
        uint256 balance = IERC20(_tokencontract).balanceOf(address(this));
        IERC20(_tokencontract).transfer(owner(), balance);
    }

    receive() external payable {}
}
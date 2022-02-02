// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAdapter} from "./interface/IAdapter.sol";
import {IERC20} from "./interface/IERC20.sol";
import {IWETH9} from "./interface/IWETH9.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract Adapter is Ownable, IAdapter {
    using SafeERC20 for IERC20;

    string  public NAME;
    uint256 public SWAP_GAS_ESTIMATE;

    address payable internal WGAS;

    address internal constant GAS = address(0);
    uint256 internal constant UINT_MAX = type(uint256).max;


    function setSwapGasEstimate(uint256 _estimate) public onlyOwner {
        SWAP_GAS_ESTIMATE = _estimate;
        emit UpdatedGasEstimate(address(this), _estimate);
    }

    /**
     * @notice Revoke token allowance
     * @param _token address
     * @param _spender address
     */
    function revokeAllowance(address _token, address _spender)
        external
        onlyOwner
    {
        IERC20 _t = IERC20(_token);
        _t.safeApprove(_spender, 0);
    }

    /**
     * @notice Recover ERC20 from contract
     * @param _tokenAddress token address
     * @param _tokenAmount amount to recover
     */
    function recoverERC20(address _tokenAddress, uint256 _tokenAmount)
        external
        onlyOwner
    {
        require(_tokenAmount > 0, "Adapter: Nothing to recover");
        IERC20(_tokenAddress).safeTransfer(msg.sender, _tokenAmount);
        emit Recovered(_tokenAddress, _tokenAmount);
    }

    /**
     * @notice Recover GAS from contract
     * @param _amount amount
     */
    function recoverETH(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Adapter: Nothing to recover");
        payable(msg.sender).transfer(_amount);
        emit Recovered(address(0), _amount);
    }

    function query(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut
    ) external view returns (uint256) {
        return _query(_amountIn, _tokenIn, _tokenOut);
    }

    /**
     * Execute a swap from token to token assuming this contract already holds input tokens
     * @notice Interact through the router
     * @param _amountIn input amount in starting token
     * @param _amountOut amount out in ending token
     * @param _fromToken ERC20 token being sold
     * @param _toToken ERC20 token being bought
     * @param _to address where swapped funds should be sent to
     */
    function swap(
        uint256 _amountIn,
        uint256 _amountOut,
        address _fromToken,
        address _toToken,
        address _to
    ) external {
        _approveIfNeeded(_fromToken, _amountIn);
        _swap(_amountIn, _amountOut, _fromToken, _toToken, _to);
        emit AdapterSwap(_fromToken, _toToken, _amountIn, _amountOut);
    }

    /**
     * @notice Return expected funds to user
     * @dev Skip if funds should stay in the contract
     * @param _token address
     * @param _amount tokens to return
     * @param _to address where funds should be sent to
     */
    function _returnTo(
        address _token,
        uint256 _amount,
        address _to
    ) internal {
        if (address(this) != _to) {
            IERC20(_token).safeTransfer(_to, _amount);
        }
    }

    /**
     * @notice Wrap GAS
     * @param _amount amount
     */
    function _wrap(uint256 _amount) internal {
        IWETH9(WGAS).deposit{value: _amount}();
    }

    /**
     * @notice Unwrap WGAS
     * @param _amount amount
     */
    function _unwrap(uint256 _amount) internal {
        IWETH9(WGAS).withdraw(_amount);
    }

    /**
     * @notice Internal implementation of a swap
     * @dev Must return tokens to address(this)
     * @dev Wrapping is handled external to this function
     * @param _amountIn amount being sold
     * @param _amountOut amount being bought
     * @param _fromToken ERC20 token being sold
     * @param _toToken ERC20 token being bought
     * @param _to Where recieved tokens are sent to
     */
    function _swap(
        uint256 _amountIn,
        uint256 _amountOut,
        address _fromToken,
        address _toToken,
        address _to
    ) internal virtual;

    function _query(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut
    ) internal virtual view returns (uint256);

    /**
     * @notice Approve tokens for use in Strategy
     * @dev Should use modifier `onlyOwner` to avoid griefing
     */
    function setAllowances() public virtual;

    function _approveIfNeeded(address _tokenIn, uint256 _amount)
        internal
        virtual;

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ISynapse} from "../interface/ISynapse.sol";
import {IERC20} from "../interface/IERC20.sol";

import {SynapseBaseAdapter} from "./SynapseBaseAdapter.sol";

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract SynapseAaveAdapter is SynapseBaseAdapter {
    using SafeERC20 for IERC20;

    constructor(
        string memory _name,
        address _pool,
        uint256 _swapGasEstimate
    ) SynapseBaseAdapter(_name, _pool, _swapGasEstimate)
    {
        _setID();
    }

    function _setID()
        internal
        override
    {
        ID = keccak256("SynapseBaseAdapter");
    }


    // Mapping indicator which tokens are included in the pool
    function _setPoolTokens()
        internal
        override
    {
        // Get stables from pool
        for (uint8 i = 0; true; i++) {
            try ISynapse(POOL).getToken(i) returns (IERC20 token) {
                IS_POOL_TOKEN[address(token)] = true;
                TOKEN_INDEX[address(token)] = i;
                NUMBER_OF_TOKENS = NUMBER_OF_TOKENS + 1;
            } catch {
                break;
            }
        }
        // Get nUSD from this pool
        address lpToken = ISynapse(POOL).LP_TOKEN();
        IS_POOL_TOKEN[lpToken] = true;
        NUMBER_OF_TOKENS = NUMBER_OF_TOKENS + 1;
        TOKEN_INDEX[lpToken] = NUMBER_OF_TOKENS;
    }

    function _query(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut
    )
        internal
        override
        view
        returns (uint256 _amt)
    {
        _amt = 0;

        if (
            _amountIn == 0 ||
            _tokenIn == _tokenOut ||
            !IS_POOL_TOKEN[_tokenIn] ||
            !IS_POOL_TOKEN[_tokenOut] ||
            _isPaused()
        ) {
            return _amt;
        }
        if (TOKEN_INDEX[_tokenIn] != NUMBER_OF_TOKENS && TOKEN_INDEX[_tokenOut] != NUMBER_OF_TOKENS) {
            try
                ISynapse(POOL).calculateSwap(
                    TOKEN_INDEX[_tokenIn],
                    TOKEN_INDEX[_tokenOut],
                    _amountIn
                )
            returns (uint256 amountOut) {
                return (amountOut * POOL_FEE_COMPLIMENT) / BIPS;
            } catch {
                return _amt;
            }
        } else {
            if (TOKEN_INDEX[_tokenOut] == NUMBER_OF_TOKENS) {
                uint256[] memory amounts = new uint256[](3);
                amounts[(TOKEN_INDEX[_tokenIn])] = _amountIn;
                try ISynapse(POOL).calculateTokenAmount(amounts, true) returns (
                    uint256 amountOut
                ) {
                    return (amountOut * POOL_FEE_COMPLIMENT) / BIPS;
                } catch {
                    return _amt;
                }
            } else if (TOKEN_INDEX[_tokenIn] == NUMBER_OF_TOKENS) {
                // remove liquidity
                try
                    ISynapse(POOL).calculateRemoveLiquidityOneToken(
                        _amountIn,
                        TOKEN_INDEX[_tokenOut]
                    )
                returns (uint256 amountOut) {
                    return (amountOut * POOL_FEE_COMPLIMENT) / BIPS;
                } catch {
                    return _amt;
                }
            } else {
                return _amt;
            }
        }
    }

    function _swap(
        uint256 _amountIn,
        uint256 _amountOut,
        address _tokenIn,
        address _tokenOut,
        address _to
    )
        internal
        override
    {
        if (TOKEN_INDEX[_tokenIn] != NUMBER_OF_TOKENS && TOKEN_INDEX[_tokenOut] != NUMBER_OF_TOKENS) {
            ISynapse(POOL).swap(
                TOKEN_INDEX[_tokenIn],
                TOKEN_INDEX[_tokenOut],
                _amountIn,
                _amountOut,
                block.timestamp
            );
            // Confidently transfer amount-out
            _returnTo(_tokenOut, _amountOut, _to);
        } else {
            // add liquidity
            if (TOKEN_INDEX[_tokenOut] == NUMBER_OF_TOKENS) {
                uint256[] memory amounts = new uint256[](3);
                amounts[(TOKEN_INDEX[_tokenIn])] = _amountIn;

                ISynapse(POOL).addLiquidity(
                    amounts,
                    _amountOut,
                    block.timestamp
                );
                _returnTo(_tokenOut, _amountOut, _to);
            }
            if (TOKEN_INDEX[_tokenIn] == NUMBER_OF_TOKENS) {
                // remove liquidity
                ISynapse(POOL).removeLiquidityOneToken(
                    _amountIn,
                    TOKEN_INDEX[_tokenOut],
                    _amountOut,
                    block.timestamp
                );
                _returnTo(_tokenOut, _amountOut, _to);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ISynapse} from "../interface/ISynapse.sol";
import {IERC20} from "../interface/IERC20.sol";
import {Adapter} from "../Adapter.sol";

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract SynapseBaseAdapter is Adapter {
    using SafeERC20 for IERC20;

    address public POOL;

    bytes32 public ID;

    uint8 public NUMBER_OF_TOKENS = 0;

    uint256 public constant BIPS = 1e4;
    uint256 public constant POOL_FEE_COMPLIMENT = 9996; // In bips

    mapping(address => bool)  public IS_POOL_TOKEN;
    mapping(address => uint8) public TOKEN_INDEX;

    constructor(
        string memory _name,
        address _pool,
        uint256 _swapGasEstimate
    ) {
        POOL = _pool;
        NAME = _name;
        _setPoolTokens();
        setSwapGasEstimate(_swapGasEstimate);
        _setID();
    }

    function _setID()
        internal
        virtual
    {
        ID = keccak256("SynapseBaseAdapter");
    }

    // Mapping indicator which tokens are included in the pool
    function _setPoolTokens()
        internal
        virtual
    {
        // Get stables from pool
        for (uint8 i = 0; true; i++) {
            try ISynapse(POOL).getToken(i) returns (IERC20 token) {
                IS_POOL_TOKEN[address(token)] = true;
                TOKEN_INDEX[address(token)] = i;
                NUMBER_OF_TOKENS = NUMBER_OF_TOKENS + 1;
            } catch {
                break;
            }
        }
        // Get nUSD from this pool
        (, , , , , , address lpToken) = ISynapse(POOL).swapStorage();
        IS_POOL_TOKEN[lpToken] = true;
        NUMBER_OF_TOKENS = NUMBER_OF_TOKENS + 1;
        TOKEN_INDEX[lpToken] = NUMBER_OF_TOKENS;
    }

    function setAllowances() public override onlyOwner {}

    function _approveIfNeeded(address _tokenIn, uint256 _amount)
        internal
        override
    {
        uint256 allowance = IERC20(_tokenIn).allowance(address(this), POOL);
        if (allowance < _amount) {
            IERC20(_tokenIn).safeApprove(POOL, UINT_MAX);
        }
    }

    function _isPaused() internal view returns (bool) {
        return ISynapse(POOL).paused();
    }

    function _query(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut
    )
        internal
        override
        virtual
        view
        returns (uint256 _amt)
    {
        _amt = 0;
        if (
            _amountIn == 0 ||
            _tokenIn == _tokenOut ||
            !IS_POOL_TOKEN[_tokenIn] ||
            !IS_POOL_TOKEN[_tokenOut] ||
            _isPaused()
        ) {
            return _amt;
        }
        if (TOKEN_INDEX[_tokenIn] != NUMBER_OF_TOKENS && TOKEN_INDEX[_tokenOut] != NUMBER_OF_TOKENS) {
            try
                ISynapse(POOL).calculateSwap(
                    TOKEN_INDEX[_tokenIn],
                    TOKEN_INDEX[_tokenOut],
                    _amountIn
                )
            returns (uint256 amountOut) {
                return (amountOut * POOL_FEE_COMPLIMENT) / BIPS;
            } catch {
                return _amt;
            }
        } else {
            if (TOKEN_INDEX[_tokenOut] == NUMBER_OF_TOKENS) {
                uint256[] memory amounts = new uint256[](3);
                amounts[(TOKEN_INDEX[_tokenIn])] = _amountIn;
                try ISynapse(POOL).calculateTokenAmount(amounts, true) returns (
                    uint256 amountOut
                ) {
                    return (amountOut * POOL_FEE_COMPLIMENT) / BIPS;
                } catch {
                    return _amt;
                }
            } else if (TOKEN_INDEX[_tokenIn] == NUMBER_OF_TOKENS) {
                // remove liquidity
                try
                    ISynapse(POOL).calculateRemoveLiquidityOneToken(
                        _amountIn,
                        TOKEN_INDEX[_tokenOut]
                    )
                returns (uint256 amountOut) {
                    return (amountOut * POOL_FEE_COMPLIMENT) / BIPS;
                } catch {
                    return _amt;
                }
            } else {
                return _amt;
            }
        }
    }

    function _swap(
        uint256 _amountIn,
        uint256 _amountOut,
        address _tokenIn,
        address _tokenOut,
        address _to
    )
        internal
        override
        virtual
    {
        if (TOKEN_INDEX[_tokenIn] != NUMBER_OF_TOKENS && TOKEN_INDEX[_tokenOut] != NUMBER_OF_TOKENS) {
            ISynapse(POOL).swap(
                TOKEN_INDEX[_tokenIn],
                TOKEN_INDEX[_tokenOut],
                _amountIn,
                _amountOut,
                block.timestamp
            );
            // Confidently transfer amount-out
            _returnTo(_tokenOut, _amountOut, _to);
        } else {
            // add liquidity
            if (TOKEN_INDEX[_tokenOut] == NUMBER_OF_TOKENS) {
                uint256[] memory amounts = new uint256[](3);
                amounts[(TOKEN_INDEX[_tokenIn])] = _amountIn;

                ISynapse(POOL).addLiquidity(
                    amounts,
                    _amountOut,
                    block.timestamp
                );
                _returnTo(_tokenOut, _amountOut, _to);
            }
            if (TOKEN_INDEX[_tokenIn] == NUMBER_OF_TOKENS) {
                // remove liquidity
                ISynapse(POOL).removeLiquidityOneToken(
                    _amountIn,
                    TOKEN_INDEX[_tokenOut],
                    _amountOut,
                    block.timestamp
                );
                _returnTo(_tokenOut, _amountOut, _to);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6;

interface IAdapter {
    event AdapterSwap(
        address indexed _tokenFrom,
        address indexed _tokenTo,
        uint256 _amountIn,
        uint256 _amountOut
    );

    event UpdatedGasEstimate(address indexed _adapter, uint256 _newEstimate);

    event Recovered(address indexed _asset, uint256 amount);

    function NAME() external view returns (string memory);
    function SWAP_GAS_ESTIMATE() external view returns (uint);
    function swap(uint256, uint256, address, address, address) external;
    function query(uint256, address, address) external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20 as _IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 is _IERC20 {
    function nonces(address) external view returns (uint256); // Only tokens that support permit

    function permit(
        address,
        address,
        uint256,
        uint256,
        uint8,
        bytes32,
        bytes32
    ) external; // Only tokens that support permit

    function mint(address to, uint256 amount) external; // only tokens that support minting
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "./IERC20.sol";

interface ISynapse {
    function LP_TOKEN() external view returns (address);
    
    // pool data view functions
    function getA() external view returns (uint256);

    function getToken(uint8 index) external view returns (IERC20);

    function getTokenIndex(address tokenAddress) external view returns (uint8);

    function getTokenBalance(uint8 index) external view returns (uint256);

    function getVirtualPrice() external view returns (uint256);

    function paused() external view returns (bool);

    // min return calculation functions
    function calculateSwap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external view returns (uint256);

    function calculateTokenAmount(uint256[] calldata amounts, bool deposit)
        external
        view
        returns (uint256);

    function calculateRemoveLiquidity(uint256 amount)
        external
        view
        returns (uint256[] memory);

    function calculateRemoveLiquidityOneToken(
        uint256 tokenAmount,
        uint8 tokenIndex
    ) external view returns (uint256 availableTokenAmount);

    function swap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    ) external returns (uint256);

    function addLiquidity(
        uint256[] calldata amounts,
        uint256 minToMint,
        uint256 deadline
    ) external returns (uint256);

    function removeLiquidity(
        uint256 amount,
        uint256[] calldata minAmounts,
        uint256 deadline
    ) external returns (uint256[] memory);

    function removeLiquidityOneToken(
        uint256 tokenAmount,
        uint8 tokenIndex,
        uint256 minAmount,
        uint256 deadline
    ) external returns (uint256);

    function removeLiquidityImbalance(
        uint256[] calldata amounts,
        uint256 maxBurnAmount,
        uint256 deadline
    ) external returns (uint256);

    function swapStorage()
        external
        view
        returns (
            uint256 initialA,
            uint256 futureA,
            uint256 initialATime,
            uint256 futureATime,
            uint256 swapFee,
            uint256 adminFee,
            address lpToken
        );
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

interface IWETH9 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function balanceOf(address) external view returns (uint256);

    function allowance(address, address) external view returns (uint256);

    receive() external payable;

    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function totalSupply() external view returns (uint256);

    function approve(address guy, uint256 wad) external returns (bool);

    function transfer(address dst, uint256 wad) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);
}
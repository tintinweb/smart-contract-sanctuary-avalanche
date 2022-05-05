/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-05
*/

/**    ZEUS NODE FINANCE - 2022
       Web:      https://linktr.ee/zeusnode
 */

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title SafeMathUint
 * @dev Math operations with safety TKNcks that revert on error
 */
library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0, "toInt256Safe: B LESS THAN ZERO");
        return b;
    }
}

pragma solidity ^0.8.0;

/**
 * @title SafeMathInt
 * @dev Math operations for int256 with overflow safety TKNcks.
 */
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(
            c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256),
            "mul: A B C combi values invalid with MIN_INT256"
        );
        require((b == 0) || (c / b == a), "mul: A B C combi values invalid");
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256, "div: b == 1 OR A == MIN_INT256");

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require(
            (b >= 0 && c <= a) || (b < 0 && c > a),
            "sub: A B C combi values invalid"
        );
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require(
            (b >= 0 && c >= a) || (b < 0 && c < a),
            "add: A B C combi values invalid"
        );
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256, "abs: A EQUAL MIN INT256");
        return a < 0 ? -a : a;
    }

    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0, "toUint256Safe: A LESS THAN ZERO");
        return uint256(a);
    }
}

pragma solidity ^0.8.0;

library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
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
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is TKNaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouTKNd) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouTKNd) while Solidity
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouTKNd) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouTKNd) while Solidity uses an
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint256) values;
        mapping(address => uint256) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint256) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key)
        public
        view
        returns (int256)
    {
        if (!map.inserted[key]) {
            return -1;
        }
        return int256(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint256 index)
        public
        view
        returns (address)
    {
        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint256) {
        return map.keys.length;
    }

    function set(
        Map storage map,
        address key,
        uint256 val
    ) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint256 index = map.indexOf[key];
        uint256 lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

// OpenZeppelin Contracts v4.3.2 (utils/Address.sol)

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
     * Returns the raw returned data. To convert to the expected return value
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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

interface IJoeRouter01 {
    function factory() external pure returns (address);

    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountAVAX,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAX(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAXWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactAVAX(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapAVAXForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// pragma solidity >=0.6.2;

interface IJoeRouter02 is IJoeRouter01 {
    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountAVAX);

    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
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

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

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

interface IJoeFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function setMigrator(address) external;
}

pragma solidity ^0.8.0;

/*
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

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
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
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        //unchecked {
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
        //}
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

contract PaymentSplitter is Context {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(
        IERC20 indexed token,
        address to,
        uint256 amount
    );
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    mapping(IERC20 => uint256) private _erc20TotalReleased;
    mapping(IERC20 => mapping(address => uint256)) private _erc20Released;

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    constructor(address[] memory payees, uint256[] memory shares_) payable {
        require(
            payees.length == shares_.length,
            "PaymentSplitter: payees and shares length mismatch"
        );
        require(payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20
     * contract.
     */
    function totalReleased(IERC20 token) public view returns (uint256) {
        return _erc20TotalReleased[token];
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @dev Getter for the amount of `token` tokens already released to a payee. `token` should be the address of an
     * IERC20 contract.
     */
    function released(IERC20 token, address account)
        public
        view
        returns (uint256)
    {
        return _erc20Released[token][account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address payable account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = address(this).balance + totalReleased();
        uint256 payment = _pendingPayment(
            account,
            totalReceived,
            released(account)
        );

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _released[account] += payment;
        _totalReleased += payment;

        Address.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function release(IERC20 token, address account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = token.balanceOf(address(this)) +
            totalReleased(token);
        uint256 payment = _pendingPayment(
            account,
            totalReceived,
            released(token, account)
        );

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _erc20Released[token][account] += payment;
        _erc20TotalReleased[token] += payment;

        SafeERC20.safeTransfer(token, account, payment);
        emit ERC20PaymentReleased(token, account, payment);
    }

    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return
            (totalReceived * _shares[account]) / _totalShares - alreadyReleased;
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) private {
        require(
            account != address(0),
            "PaymentSplitter: account is the zero address"
        );
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(
            _shares[account] == 0,
            "PaymentSplitter: account already has shares"
        );

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }
}

contract NODERewardManagement {
    using SafeMath for uint256;
    using IterableMapping for IterableMapping.Map;

    struct NodeEntity {
        string name;
        uint256 creationTime;
        uint256 lastClaimTime;
        uint256 rewardAvailable;
        uint32 nodeType;
    }

    IterableMapping.Map private nodeOwners;
    mapping(address => NodeEntity[]) public _nodesOfUser;
    mapping(address => address) public _referrals; //maping of referred to referrer;
    mapping(address => mapping(address => uint256)) public referralHistory;
    mapping(address => uint256) public availableReferralBonus; //user => amount;
    mapping(address => address[]) public userReferrals;

    uint256 public nodePrice;
    uint256 public rewardPerNode;
    uint256 public claimTime;
    uint256 public referralBonusPercent;
    uint256 public currentReward;
    uint256 public currentFee;

    address public gateKeeper;
    address public token;

    bool public autoDistri = false;
    bool public distribution = false;

    uint256 public gasForDistribution = 300000;
    uint256 public lastDistributionCount = 0;
    uint256 public lastIndexProcessed = 0;

    uint256 public totalNodesCreated = 0;
    uint256 public totalRewardStaked = 0;
    uint256 public zeusTotal = 0;

    constructor(
        uint256 _nodePrice,
        uint256 _rewardPerNode,
        uint256 _claimTime
    ) {
        nodePrice = _nodePrice;
        rewardPerNode = _rewardPerNode;
        claimTime = _claimTime;
        gateKeeper = msg.sender;
    }

    modifier onlySentry() {
        require(msg.sender == token || msg.sender == gateKeeper, "Fuck off");
        _;
    }

    function setToken(address token_) external onlySentry {
        token = token_;
    }

    function distributeRewards(uint256 gas, uint256 rewardNode)
        private
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        distribution = true;
        uint256 numberOfnodeOwners = nodeOwners.keys.length;
        require(numberOfnodeOwners > 0, "DISTRI REWARDS: NO NODE OWNERS");
        if (numberOfnodeOwners == 0) {
            return (0, 0, lastIndexProcessed);
        }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 newGasLeft;
        uint256 localLastIndex = lastIndexProcessed;
        uint256 iterations = 0;
        uint256 newClaimTime = block.timestamp;
        uint256 nodesCount;
        uint256 claims = 0;
        NodeEntity[] storage nodes;
        NodeEntity storage _node;

        while (gasUsed < gas && iterations < numberOfnodeOwners) {
            localLastIndex++;
            if (localLastIndex >= nodeOwners.keys.length) {
                localLastIndex = 0;
            }
            nodes = _nodesOfUser[nodeOwners.keys[localLastIndex]];
            nodesCount = nodes.length;
            for (uint256 i = 0; i < nodesCount; i++) {
                _node = nodes[i];
                if (claimable(_node)) {
                    _node.rewardAvailable += rewardNode;
                    _node.lastClaimTime = newClaimTime;
                    totalRewardStaked += rewardNode;
                    claims++;
                }
            }
            iterations++;

            newGasLeft = gasleft();

            if (gasLeft > newGasLeft) {
                gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
            }

            gasLeft = newGasLeft;
        }
        lastIndexProcessed = localLastIndex;
        distribution = false;
        return (iterations, claims, lastIndexProcessed);
    }

    function createNode(
        address account,
        string memory nodeName,
        address referred_by,
        uint32 nodeType,
        uint256 total
    ) public onlySentry {}

    function isNameAvailable(address account, string memory nodeName)
        private
        view
        returns (bool)
    {}

    function _burn(uint256 index) internal {
        require(index < nodeOwners.size());
        nodeOwners.remove(nodeOwners.getKeyAtIndex(index));
    }

    function _getNodeWithCreatime(
        NodeEntity[] storage nodes,
        uint256 _creationTime
    ) private view returns (NodeEntity storage) {
        uint256 numberOfNodes = nodes.length;
        require(
            numberOfNodes > 0,
            "CASHOUT ERROR: You don't have nodes to cash-out"
        );
        bool found = false;
        int256 index = binary_search(nodes, 0, numberOfNodes, _creationTime);
        uint256 validIndex;
        if (index >= 0) {
            found = true;
            validIndex = uint256(index);
        }
        require(found, "NODE SEARCH: No NODE Found with this blocktime");
        return nodes[validIndex];
    }

    function binary_search(
        NodeEntity[] memory arr,
        uint256 low,
        uint256 high,
        uint256 x
    ) private view returns (int256) {}

    function _cashoutNodeReward(address account, uint256 _creationTime)
        external
        onlySentry
        returns (uint256, uint256)
    {}

    function _cashoutAllNodesReward(address account)
        external
        onlySentry
        returns (uint256, uint256)
    {}

    function claimable(NodeEntity memory node) private view returns (bool) {
        return node.lastClaimTime + claimTime <= block.timestamp;
    }

    function _getRewardAmountOf(address account)
        external
        view
        returns (uint256)
    {}

    function _getRewardAmountOf(address account, uint256 _creationTime)
        external
        view
        returns (uint256)
    {}

    function _getNodeRewardAmountOf(address account, uint256 creationTime)
        external
        view
        returns (uint256)
    {}

    function _getNodesNames(address account)
        external
        view
        returns (string memory)
    {}

    function _getNodesCreationTime(address account)
        external
        view
        returns (string memory)
    {}

    function _getNodesRewardAvailable(address account)
        external
        view
        returns (string memory)
    {}

    function _getNodesLastClaimTime(address account)
        external
        view
        returns (string memory)
    {}

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {}

    function _changeNodePrice(uint256 newNodePrice) external onlySentry {
        nodePrice = newNodePrice;
    }

    function _changeRewardPerNode(uint256 newPrice) external onlySentry {
        rewardPerNode = newPrice;
    }

    function _changeClaimTime(uint256 newTime) external onlySentry {
        claimTime = newTime;
    }

    function _changeAutoDistri(bool newMode) external onlySentry {
        autoDistri = newMode;
    }

    function _changeGasDistri(uint256 newGasDistri) external onlySentry {
        gasForDistribution = newGasDistri;
    }

    function _getNodeNumberOf(address account) public view returns (uint256) {
        return nodeOwners.get(account);
    }

    function isNodeOwner(address account) private view returns (bool) {
        return nodeOwners.get(account) > 0;
    }

    function _isNodeOwner(address account) external view returns (bool) {
        return isNodeOwner(account);
    }

    function _distributeRewards()
        external
        onlySentry
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return distributeRewards(gasForDistribution, rewardPerNode);
    }

    function _addReferral(address referrer, address referred_by)
        public
        onlySentry
    {}

    function setReferralBonus(uint256 amount) external onlySentry {
        referralBonusPercent = amount;
    }

    function _addRefferralBonus(address referred) public onlySentry {}

    function getReferrals(address referred_by)
        public
        view
        onlySentry
        returns (address[] memory)
    {
        return userReferrals[referred_by];
    }

    function getReferralBonus(address account)
        public
        view
        onlySentry
        returns (uint256)
    {
        return availableReferralBonus[account];
    }

    function withdrawReferralBonus(address account)
        public
        onlySentry
        returns (uint256)
    {
        uint256 total = availableReferralBonus[account];
        availableReferralBonus[account] = 0;
        return total;
    }

    function _compoundNode(
        address account,
        uint32 nodeType,
        string memory nodeName
    ) external onlySentry returns (uint256) {}

    function _getUserReferralCount(address account)
        external
        view
        returns (uint256)
    {}

    function _getUserNodeCount(address user) external view returns (uint256) {
        NodeEntity[] memory nodes = _nodesOfUser[user];
        return nodes.length;
    }

    function _getTotalUserNodes(address user) external view returns (uint256) {}

    function getNodePriceByType(uint32 nodeType)
        external
        view
        onlySentry
        returns (uint256)
    {}

    function _cashoutAllNodesByTypeReward(address account, uint32 nodeType)
        public
        onlySentry
        returns (uint256, uint256)
    {}

    function getNodeId(address account) external pure returns (string memory) {}
}

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

interface IZeus {
    function createNodeWithTokens(string memory name) external;
}

contract IZeusV2 {
    mapping(address => uint256) public extraUserBalances;
}

interface IMasterOfCoin {
    function payFee(string memory nodeId) external;

    function restoreNode(string memory nodeId, string memory tierName)
        external
        payable;
}

contract ZEUSV4 is Ownable, PaymentSplitter {
    using SafeMath for uint256;
    NODERewardManagement public kronosNodeRewardManager;
    NODERewardManagement public herculesNodeRewardManager;
    NODERewardManagement public heraNodeRewardManager;
    NODERewardManagement public zeusNodeRewardManager;
    IMasterOfCoin public masterOfCoin;
    IZeus public Zeus = IZeus(0x4156F18bF7C1ef04248632C66Aa119De152D8f2E);
    IZeusV2 public ZeusV2 = IZeusV2(0x83Cd939016700abf7e61FD991550f93388e3368b);
    struct NodeEntity {
        string name;
        uint256 creationTime;
        uint256 lastClaimTime;
        uint256 rewardAvailable;
        uint32 nodeType;
    }

    IJoeRouter02 public uniswapV2Router;

    address public uniswapV2Pair = 0xA888455491ffDAC9a6E20C5Cf5C06fBAC5124Df6;
    address public futurUsePool = 0xA26d0bdF4b22C4Ee7A14b385289D9667B5E2416d;
    address public distributionPool =
        0x0B26a20f038F657856054dE581457e1F9db4E88e;
    address public creationTaxPool = 0x4156F18bF7C1ef04248632C66Aa119De152D8f2E;
    address tokenAddress = 0x764a4A6f3326559b6Ef5F3F186AD1094FA044c43;
    IERC20 public token = IERC20(tokenAddress);

    address public deadWallet = 0x000000000000000000000000000000000000dEaD;
    address public taxPool = 0x3e9f27368CC457F5A2CBE5B26fa050Be4be05A8E;

    uint256 public rewardsFee = 60;
    uint256 public liquidityPoolFee = 10;
    uint256 public futurFee = 2;
    uint256 public totalFees = 72;
    uint256 public loopAmount = 40;

    uint256 public cashoutFee = 10;

    uint256 private rwSwap = 30;
    bool private swapping = false;
    bool private swapLiquify = true;
    uint256 public swapTokensAmount = 30000000000000000000;

    mapping(address => bool) public _isBlacklisted;
    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => uint256) public extraUserBalances;
    mapping(address => bool) public isMigratedExtraBalance;

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event LiquidityWalletUpdated(
        address indexed newLiquidityWallet,
        address indexed oldLiquidityWallet
    );

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    constructor(address[] memory payees, uint256[] memory shares)
        PaymentSplitter(payees, shares)
    {
        IJoeRouter02 _uniswapV2Router = IJoeRouter02(
            0x60aE616a2155Ee3d9A68541Ba4544862310933d4
        );
        address _uniswapV2Pair = 0xA888455491ffDAC9a6E20C5Cf5C06fBAC5124Df6;
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
    }

    function setMasterOfCoin(address _master) external onlyOwner {
        masterOfCoin = IMasterOfCoin(_master);
    }

    function migrateExtraBalance() external {
        address sender = _msgSender();
        require(!isMigratedExtraBalance[sender], "Already Migrated balance");
        uint256 oldExtraBalances = ZeusV2.extraUserBalances(sender);
        isMigratedExtraBalance[sender] = true;
        if (oldExtraBalances > 0) {
            extraUserBalances[sender] += oldExtraBalances;
        }
    }

    function payFee(string memory nodeId) external onlyOwner {
        masterOfCoin.payFee(nodeId);
    }

    function restoreNode(string memory nodeId, string memory tierName)
        external
        payable
    {
        masterOfCoin.restoreNode(nodeId, tierName);
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(
            newAddress != address(uniswapV2Router),
            "TKN: The router already has that address"
        );
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IJoeRouter02(newAddress);
        address _uniswapV2Pair = IJoeFactory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WAVAX());
        uniswapV2Pair = _uniswapV2Pair;
    }

    function updateSwapTokensAmount(uint256 newVal) external onlyOwner {
        swapTokensAmount = newVal;
    }

    function updateFuturWall(address payable wall) external onlyOwner {
        futurUsePool = wall;
    }

    function updateRewardsWall(address payable wall) external onlyOwner {
        distributionPool = wall;
    }

    function updateRewardsFee(uint256 value) external onlyOwner {
        rewardsFee = value;
        totalFees = rewardsFee.add(liquidityPoolFee).add(futurFee);
    }

    function updateLoopAmount(uint256 amount) external onlyOwner {
        loopAmount = amount;
    }

    function updateLiquiditFee(uint256 value) external onlyOwner {
        liquidityPoolFee = value;
        totalFees = rewardsFee.add(liquidityPoolFee).add(futurFee);
    }

    function updateFuturFee(uint256 value) external onlyOwner {
        futurFee = value;
        totalFees = rewardsFee.add(liquidityPoolFee).add(futurFee);
    }

    function updateCashoutFee(uint256 value) external onlyOwner {
        cashoutFee = value;
    }

    function updateRwSwapFee(uint256 value) external onlyOwner {
        rwSwap = value;
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        require(
            pair != uniswapV2Pair,
            "TKN: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function blacklistMalicious(address account, bool value)
        external
        onlyOwner
    {
        _isBlacklisted[account] = value;
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(
            automatedMarketMakerPairs[pair] != value,
            "TKN: Automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function swapAndSendToFee(address destination, uint256 tokens) private {
        uint256 initialETHBalance = address(this).balance;
        swapTokensForEth(tokens);
        uint256 newBalance = (address(this).balance).sub(initialETHBalance);
        payable(destination).transfer(newBalance);
    }

    function swapAndLiquify(uint256 tokens) private {
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        uint256 initialBalance = address(this).balance;

        swapTokensForEth(half);

        uint256 newBalance = address(this).balance.sub(initialBalance);

        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WAVAX();

        // token.approve(address(uniswapV2Router), tokenAmount);
        require(
            token.approve(address(uniswapV2Router), tokenAmount),
            "Approve failed"
        );
        // require(token.allowance(address(this), address(uniswapV2Router)) >= tokenAmount, "Token allowance too low");

        uniswapV2Router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        require(
            token.approve(address(uniswapV2Router), tokenAmount),
            "Approve failed"
        );
        require(
            token.allowance(address(this), address(uniswapV2Router)) >=
                tokenAmount,
            "Allowance insufficient"
        );

        // require(token.allowance(address(this), address(uniswapV2Router)) >= tokenAmount, "Token allowance too low");

        // add the liquidity
        uniswapV2Router.addLiquidityAVAX{value: ethAmount}(
            address(0),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }

    function createNodeWithTokens(
        string memory name,
        address referred_by,
        uint256 total,
        uint32 nodeType
    ) public payable {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        require(total <= 5 && total >= 1, "Max: 5 nodes Min: 1");
        require(
            bytes(name).length > 3 && bytes(name).length < 32,
            "NODE CREATION: NAME SIZE INVALID"
        );
        address sender = _msgSender();
        require(
            sender != address(0),
            "NODE CREATION:  creation from the zero address"
        );
        require(!_isBlacklisted[sender], "NODE CREATION: Blacklisted address");
        require(
            sender != futurUsePool && sender != distributionPool,
            "NODE CREATION: futur and rewardsPool cannot create node"
        );
        uint256 totalUserNodes = nodeRewardManager._getTotalUserNodes(sender);
        require(totalUserNodes < 100, "Maximum node exceeded");
        uint256 nodePrice = 0;
        if (nodeType == 2) {
            nodePrice = nodeRewardManager.getNodePriceByType(nodeType);
        } else {
            nodePrice = nodeRewardManager.nodePrice();
        }

        require(
            token.balanceOf(sender) >= nodePrice,
            "NODE CREATION: Balance too low for creation."
        );
        uint256 contractTokenBalance = token.balanceOf(address(this));
        bool swapAmountOk = contractTokenBalance >= swapTokensAmount;
        if (
            swapAmountOk &&
            swapLiquify &&
            !swapping &&
            sender != owner() &&
            !automatedMarketMakerPairs[sender]
        ) {
            swapping = true;
            // token.transfer(address(creationTaxPool), contractTokenBalance);
            // Zeus.createNodeWithTokens(name);
            swapping = false;
        }
        // uint256 finalPrice = total.mul(nodePrice);
        // token.transferFrom(msg.sender, address(this), finalPrice);
        nodeRewardManager.createNode(
            sender,
            name,
            referred_by,
            nodeType,
            total
        );
    }

    function createNodeWithExtraBalances(
        string memory name,
        address referred_by,
        uint256 total,
        uint32 nodeType
    ) public payable {
        require(total <= 5 && total >= 1, "Max: 5 nodes Min: 1");
        require(
            bytes(name).length > 3 && bytes(name).length < 32,
            "NODE CREATION: NAME SIZE INVALID"
        );
        address sender = _msgSender();
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        uint256 totalUserNodes = nodeRewardManager._getTotalUserNodes(sender);
        require(totalUserNodes < 100, "Maximum node exceeded");
        require(
            sender != address(0),
            "NODE CREATION:  creation from the zero address"
        );
        require(!_isBlacklisted[sender], "NODE CREATION: Blacklisted address");
        require(
            sender != futurUsePool && sender != distributionPool,
            "NODE CREATION: futur and rewardsPool cannot create node"
        );
        uint256 nodePrice = 0;
        if (nodeType == 2) {
            nodePrice = nodeRewardManager.getNodePriceByType(nodeType);
        } else {
            nodePrice = nodeRewardManager.nodePrice();
        }
        require(
            extraUserBalances[sender] >= nodePrice,
            "NODE CREATION: Balance too low for creation."
        );
        uint256 finalPrice = total.mul(nodePrice);

        require(
            extraUserBalances[sender] >= finalPrice,
            "NODE CREATION: Balance not enough for number of nodes"
        );
        extraUserBalances[sender] -= finalPrice;
        nodeRewardManager.createNode(
            sender,
            name,
            referred_by,
            nodeType,
            total
        );
    }

    function updateCreationTaxPool(address newAddress) external onlyOwner {
        creationTaxPool = newAddress;
    }

    function updateTaxPool(address newAddress) external onlyOwner {
        taxPool = newAddress;
    }

    function cashoutAll(uint32 nodeType) public {
        address sender = _msgSender();
        require(
            sender != address(0),
            "MANIA CSHT:  creation from the zero address"
        );
        require(!_isBlacklisted[sender], "MANIA CSHT: Blacklisted address");
        require(
            sender != futurUsePool && sender != distributionPool,
            "MANIA CSHT: futur and rewardsPool cannot cashout rewards"
        );
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);

        (uint256 rewardAmount, uint256 fee) = nodeRewardManager
            ._cashoutAllNodesReward(sender);

        require(
            rewardAmount > 0,
            "MANIA CSHT: You don't have enough reward to cash out"
        );

        if (swapLiquify) {
            rewardAmount = rewardAmount.sub(fee);
            // token.transferFrom(distributionPool, taxPool, fee);
        }
        // token.transferFrom(distributionPool, sender, rewardAmount);
    }

    function cashoutReward(uint256 blocktime, uint32 nodeType) public {
        address sender = _msgSender();
        require(sender != address(0), "CSHT:  creation from the zero address");
        require(!_isBlacklisted[sender], "MANIA CSHT: Blacklisted address");
        require(
            sender != futurUsePool && sender != distributionPool,
            "CSHT: futur and rewardsPool cannot cashout rewards"
        );
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        nodeRewardManager
            ._cashoutNodeReward(sender, blocktime);
        // (uint256 rewardAmount, uint256 fee) = nodeRewardManager
        //     ._cashoutNodeReward(sender, blocktime);
        // require(
        //     rewardAmount > 0,
        //     "CSHT: You don't have enough reward to cash out"
        // );

        if (swapLiquify) {
            // token.transferFrom(distributionPool, taxPool, fee);
        }
        // uint256 finalReward = rewardAmount.sub(fee);
        // token.transferFrom(distributionPool, sender, finalReward);
    }

    function cashoutAllNodesByType(uint256[] memory claimtimes, uint32 nodeType)
        public
    {
        address sender = _msgSender();
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        require(sender != address(0), "CSHT:  creation from the zero address");
        require(!_isBlacklisted[sender], "MANIA CSHT: Blacklisted address");
        require(
            sender != futurUsePool && sender != distributionPool,
            "CSHT: futur and rewardsPool cannot cashout rewards"
        );
        uint256[] memory claimtimes_ = claimtimes;
        uint256 total = 0;
        uint256 feeTotal = 0;
        for (uint256 i = 0; i < claimtimes_.length; i++) {
            (uint256 rewardAmount, uint256 fee) = nodeRewardManager
                ._cashoutNodeReward(sender, claimtimes_[i]);
            feeTotal += fee;
            total += rewardAmount;
        }
        require(total > 0, "CSHT: You don't have enough reward to cash out");
        if (swapLiquify) {
            token.transferFrom(distributionPool, taxPool, feeTotal);
        }
        uint256 finalReward = total.sub(feeTotal);
        token.transferFrom(distributionPool, sender, finalReward);
    }

    function getTotalNodes(uint32 nodeType) external view returns (uint256) {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        if (nodeType == 2) {
            return nodeRewardManager.zeusTotal();
        }
        return nodeRewardManager.totalNodesCreated();
    }

    function cashoutAllExtraBalances() public {
        address sender = _msgSender();
        require(
            sender != address(0),
            "MANIA CSHT:  creation from the zero address"
        );
        require(!_isBlacklisted[sender], "MANIA CSHT: Blacklisted address");
        require(
            sender != futurUsePool && sender != distributionPool,
            "MANIA CSHT: futur and rewardsPool cannot cashout rewards"
        );
        uint256 amount = extraUserBalances[sender];
        require(
            amount > 0,
            "MANIA CSHT: You don't have enough reward to cash out"
        );
        extraUserBalances[sender] -= amount;
        uint256 fee = amount.mul(cashoutFee).div(100);
        uint256 finalAmount = amount.sub(fee);
        token.transferFrom(distributionPool, sender, finalAmount);
    }

    function boostReward(uint256 amount) public onlyOwner {
        if (amount > address(this).balance) amount = address(this).balance;
        payable(owner()).transfer(amount);
    }

    function changeSwapLiquify(bool newVal) public onlyOwner {
        swapLiquify = newVal;
    }

    function getNodeNumberOf(address account, uint32 nodeType)
        public
        view
        returns (uint256)
    {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        return nodeRewardManager._getNodeNumberOf(account);
    }

    function getRewardAmountOf(address account, uint32 nodeType)
        public
        view
        onlyOwner
        returns (uint256)
    {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        return nodeRewardManager._getRewardAmountOf(account);
    }

    function getRewardAmount(uint32 nodeType) public view returns (uint256) {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        require(_msgSender() != address(0), "SENDER CAN'T BE ZERO");
        require(nodeRewardManager._isNodeOwner(_msgSender()), "NO NODE OWNER");
        return nodeRewardManager._getRewardAmountOf(_msgSender());
    }

    function changeNodePrice(uint256 newNodePrice, uint32 nodeType)
        public
        onlyOwner
    {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        nodeRewardManager._changeNodePrice(newNodePrice);
    }

    function getNodePrice(uint32 nodeType) public view returns (uint256) {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        if (nodeType == 2) {
            return nodeRewardManager.getNodePriceByType(nodeType);
        }
        return nodeRewardManager.nodePrice();
    }

    function changeRewardPerNode(uint256 newPrice, uint32 nodeType)
        public
        onlyOwner
    {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        nodeRewardManager._changeRewardPerNode(newPrice);
    }

    function getRewardPerNode(uint32 nodeType) public view returns (uint256) {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        return nodeRewardManager.rewardPerNode();
    }

    function changeClaimTime(uint256 newTime, uint32 nodeType)
        public
        onlyOwner
    {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        nodeRewardManager._changeClaimTime(newTime);
    }

    function getClaimTime(uint32 nodeType) public view returns (uint256) {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        return nodeRewardManager.claimTime();
    }

    function changeAutoDistri(bool newMode, uint32 nodeType) public onlyOwner {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        nodeRewardManager._changeAutoDistri(newMode);
    }

    function getAutoDistri(uint32 nodeType) public view returns (bool) {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        return nodeRewardManager.autoDistri();
    }

    function changeGasDistri(uint256 newGasDistri, uint32 nodeType)
        public
        onlyOwner
    {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        nodeRewardManager._changeGasDistri(newGasDistri);
    }

    function getGasDistri(uint32 nodeType) public view returns (uint256) {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        return nodeRewardManager.gasForDistribution();
    }

    function getDistriCount(uint32 nodeType) public view returns (uint256) {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        return nodeRewardManager.lastDistributionCount();
    }

    function getNodesNames(uint32 nodeType)
        public
        view
        returns (string memory)
    {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        require(_msgSender() != address(0), "SENDER CAN'T BE ZERO");
        require(nodeRewardManager._isNodeOwner(_msgSender()), "NO NODE OWNER");
        return nodeRewardManager._getNodesNames(_msgSender());
    }

    function getNodesCreatime(uint32 nodeType)
        public
        view
        returns (string memory)
    {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        require(_msgSender() != address(0), "SENDER CAN'T BE ZERO");
        require(nodeRewardManager._isNodeOwner(_msgSender()), "NO NODE OWNER");
        return nodeRewardManager._getNodesCreationTime(_msgSender());
    }

    function getNodesRewards(uint32 nodeType)
        public
        view
        returns (string memory)
    {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        require(_msgSender() != address(0), "SENDER CAN'T BE ZERO");
        require(nodeRewardManager._isNodeOwner(_msgSender()), "NO NODE OWNER");
        return nodeRewardManager._getNodesRewardAvailable(_msgSender());
    }

    function getNodesLastClaims(uint32 nodeType)
        public
        view
        returns (string memory)
    {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        require(_msgSender() != address(0), "SENDER CAN'T BE ZERO");
        require(nodeRewardManager._isNodeOwner(_msgSender()), "NO NODE OWNER");
        return nodeRewardManager._getNodesLastClaimTime(_msgSender());
    }

    function distributeRewards(uint32 nodeType)
        public
        onlyOwner
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        return nodeRewardManager._distributeRewards();
    }

    function publiDistriRewards(uint32 nodeType) public {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        nodeRewardManager._distributeRewards();
    }

    function getTotalStakedReward(uint32 nodeType)
        public
        view
        returns (uint256)
    {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        return nodeRewardManager.totalRewardStaked();
    }

    function getTotalCreatedNodes(uint32 nodeType)
        public
        view
        returns (uint256)
    {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        return nodeRewardManager.totalNodesCreated();
    }

    function cashoutToWallet(uint32 nodeType) external {
        address sender = _msgSender();
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        (uint256 rewardAmount, ) = nodeRewardManager._cashoutAllNodesReward(
            sender
        );
        require(rewardAmount > 0, "Insufficient fund");
        extraUserBalances[sender] += rewardAmount;
    }

    function compoundNode(
        string memory name,
        uint32 nodeType,
        uint256 total
    ) external {
        address sender = _msgSender();
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        require(
            sender != address(0),
            "NODE CREATION:  creation from the zero address"
        );
        require(!_isBlacklisted[sender], "NODE CREATION: Blacklisted address");
        require(
            sender != futurUsePool && sender != distributionPool,
            "NODE CREATION: futur and rewardsPool cannot create node"
        );
        uint256 nodePrice = nodeRewardManager.nodePrice();
        if (nodeType == 2) {
            nodePrice = nodeRewardManager.getNodePriceByType(nodeType);
        }
        require(extraUserBalances[sender] >= nodePrice, "Insufficient Fund");
        uint256 r_total = total.mul(nodePrice);
        require(r_total >= extraUserBalances[sender], "Insuffcient Fund");
        extraUserBalances[sender] -= r_total;
        address referred_by = 0x000000000000000000000000000000000000dEaD;
        nodeRewardManager.createNode(
            sender,
            name,
            referred_by,
            nodeType,
            total
        );
    }

    function withdrawReferralBonus(uint32 nodeType) external {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        uint256 total = nodeRewardManager.withdrawReferralBonus(_msgSender());
        require(total > 0, "Not enough funds to withdraw");
        token.transferFrom(distributionPool, _msgSender(), total);
    }

    function getReferralBonus(uint32 nodeType) external view returns (uint256) {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        return nodeRewardManager.getReferralBonus(_msgSender());
    }

    function getReferrals(uint32 nodeType)
        external
        view
        returns (address[] memory)
    {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        return nodeRewardManager.getReferrals(_msgSender());
    }

    function setReferralBonusPercent(uint256 amount, uint32 nodeType)
        external
        onlyOwner
    {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        nodeRewardManager.setReferralBonus(amount);
    }

    function setNodeManagement(address nodeManagement, uint32 nodeType)
        external
        onlyOwner
    {
        if (nodeType == 0) {
            herculesNodeRewardManager = NODERewardManagement(nodeManagement);
        }
        if (nodeType == 1) {
            heraNodeRewardManager = NODERewardManagement(nodeManagement);
        }
        if (nodeType == 2) {
            zeusNodeRewardManager = NODERewardManagement(nodeManagement);
        }
        if (nodeType == 3) {
            kronosNodeRewardManager = NODERewardManagement(nodeManagement);
        }
    }

    function balanceOf(address account) public view returns (uint256) {
        return token.balanceOf(account);
    }

    function getUserReferralCount(address account, uint32 nodeType)
        external
        view
        returns (uint256)
    {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        return nodeRewardManager._getUserReferralCount(account);
    }

    function getNodeRewardManager(uint32 nodeType)
        private
        view
        returns (NODERewardManagement)
    {
        NODERewardManagement nodeRewardManager;
        if (nodeType == 0) {
            nodeRewardManager = herculesNodeRewardManager;
        }
        if (nodeType == 1) {
            nodeRewardManager = heraNodeRewardManager;
        }
        if (nodeType == 2) {
            nodeRewardManager = zeusNodeRewardManager;
        }
        if (nodeType == 3) {
            nodeRewardManager = kronosNodeRewardManager;
        }
        return nodeRewardManager;
    }

    function getAccountId() view external returns(string memory) {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(2);
        address sender = _msgSender();
        return nodeRewardManager.getNodeId(sender);
    }
}
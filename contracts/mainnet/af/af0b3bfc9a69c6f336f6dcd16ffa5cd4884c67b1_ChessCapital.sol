/**
 *Submitted for verification at snowtrace.io on 2022-04-05
*/

pragma solidity ^0.8.0;



// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)
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


// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)
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


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
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


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
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


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)
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


library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != -1 || a != MIN_INT256);

        return a / b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

        function name() external view returns (string memory);
        function symbol() external view returns (string memory);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IPancakeSwapPair {
                event Approval(address indexed owner, address indexed spender, uint value);
                event Transfer(address indexed from, address indexed to, uint value);

                function name() external pure returns (string memory);
                function symbol() external pure returns (string memory);
                function decimals() external pure returns (uint8);
                function totalSupply() external view returns (uint);
                function balanceOf(address owner) external view returns (uint);
                function allowance(address owner, address spender) external view returns (uint);

                function approve(address spender, uint value) external returns (bool);
                function transfer(address to, uint value) external returns (bool);
                function transferFrom(address from, address to, uint value) external returns (bool);

                function DOMAIN_SEPARATOR() external view returns (bytes32);
                function PERMIT_TYPEHASH() external pure returns (bytes32);
                function nonces(address owner) external view returns (uint);

                function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

                event Mint(address indexed sender, uint amount0, uint amount1);
                event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
                event Swap(
                                address indexed sender,
                                uint amount0In,
                                uint amount1In,
                                uint amount0Out,
                                uint amount1Out,
                                address indexed to
                );
                event Sync(uint112 reserve0, uint112 reserve1);

                function MINIMUM_LIQUIDITY() external pure returns (uint);
                function factory() external view returns (address);
                function token0() external view returns (address);
                function token1() external view returns (address);
                function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
                function price0CumulativeLast() external view returns (uint);
                function price1CumulativeLast() external view returns (uint);
                function kLast() external view returns (uint);

                function mint(address to) external returns (uint liquidity);
                function burn(address to) external returns (uint amount0, uint amount1);
                function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
                function skim(address to) external;
                function sync() external;

                function initialize(address, address) external;
}

interface IPancakeSwapRouter {
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

interface IPancakeSwapFactory {
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

interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
    function getAccountInfo(address account) external view returns (uint256, uint256, uint256, int256);
    function distributeToDividend(address account) external;
}


abstract contract ERC20DetailedUpgradeable is IERC20 {
    string public _name;
    string public _symbol;
    uint8 public _decimals;

    function __ERC20Detailed__init(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) internal {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function name() public override view returns (string memory) {
        return _name;
    }

    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

contract ChessCapital is
    ERC20DetailedUpgradeable,
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable
{

    using SafeMath for uint256;
    using SafeMathInt for int256;

    event LogRebase(uint256 indexed epoch, uint256 totalSupply);

    IPancakeSwapPair public pairContract;
    mapping(address => bool) public _isFeeExempt;

    modifier validRecipient(address to) {
        require(to != address(0x0));
        _;
    }

    uint256 public constant DECIMALS = 5;
    uint256 public constant MAX_UINT256 = ~uint256(0);
    uint8 public constant RATE_DECIMALS = 7;

    uint256 private constant INITIAL_FRAGMENTS_SUPPLY =
        400 * 10**3 * 10**DECIMALS;

    uint256 public liquidityFee;
    uint256 public treasuryFee;
    uint256 public avaxFee;
    uint256 public InsuranceFundFee;
    uint256 public treasuryExtraSellFee;
    uint256 public blackHoleFee;
    uint256 public totalFee;
    uint256 public feeDenominator;

    address public DEAD;
    address public ZERO;

    address public autoLiquidityReceiver;
    address public treasuryReceiver;
    address public InsuranceFundReceiver;
    address public blackHole;
    bool public swapEnabled;
    IPancakeSwapRouter public router;
    address public pair;
    bool inSwap;

    uint256 public avaxRewardStore;

    uint256 private constant TOTAL_GONS =
        MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

    uint256 private constant MAX_SUPPLY = 325 * 10**7 * 10**DECIMALS;

    bool public _autoRebase;
    bool public _autoAddLiquidity;
    uint256 public _initRebaseStartTime;
    uint256 public _lastRebasedTime;
    uint256 public _lastAddLiquidityTime;

    uint256 public _totalSupply;
    uint256 private _gonsPerFragment;

    mapping(address => uint256) private _gonBalances;
    mapping(address => mapping(address => uint256)) private _allowedFragments;
    mapping(address => bool) public blacklist;

    uint256 public timeframeCurrent;
    uint256 public timeframeExpiresAfter;

    uint32 public maxTokenPerWalletPercent;

    uint256 public timeframeQuotaInPercentage;
    uint256 public timeframeQuotaOutPercentage;

    mapping(uint256 => mapping(address => int256)) public inAmounts;
    mapping(uint256 => mapping(address => uint256)) public outAmounts;

    bool public _avaxRewardEnabled;
    mapping(address => uint256) public checkPoints;

    bool public disableAllFee;

    address public distributorAddress;
    uint256 public distributorGas;

    address public devAddress;
    uint256 public devFee;

    bool public isOpen;

    mapping (address => bool) public secureOperators;

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier whenNotPausedForNotExempt() {
        require(_isFeeExempt[tx.origin] || !paused(), "paused for non-fee exempt");
        _;
    }

    modifier open(address from, address to) {
        require((isOpen &&  !paused()) || _isFeeExempt[from] || _isFeeExempt[to], "not open");
        _;
    }



    function initialize() external initializer {
        __ERC20Detailed__init("ChessCapital", "Chess", uint8(DECIMALS));
        __Ownable_init();
        __Pausable_init();

        // Initialize contract

        feeDenominator = 1000;

        DEAD = 0x000000000000000000000000000000000000dEaD;
        ZERO = 0x0000000000000000000000000000000000000000;

        swapEnabled = true;
        inSwap = false;

        // // trader joe
        router = IPancakeSwapRouter(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
        // bsc testnet
        // router = IPancakeSwapRouter(0x1Ed675D5e63314B760162A3D1Cae1803DCFC87C7);

        pair = IPancakeSwapFactory(router.factory()).createPair(
            router.WAVAX(),
            address(this)
        );

        autoLiquidityReceiver = 0xA016F061d56dCC5407AD6c941C02b578ffBa755E;
        treasuryReceiver = 0xEDA4bd5BE6aA5722fF0dd0145DeD92986CBC0f2A;
        InsuranceFundReceiver = 0x142F2234018454Fefe3417Fe99F2cc58694a30C4;
        blackHole = 0xDDF57Cbb36a1384159eb3a5C5181480835959208;

        liquidityFee = 50;
        treasuryFee = 30;
        InsuranceFundFee = 50;
        avaxFee = 0;
        treasuryExtraSellFee = 40;
        blackHoleFee = 25;
        totalFee = liquidityFee.add(treasuryFee).add(InsuranceFundFee).add(blackHoleFee).add(avaxFee);

        _allowedFragments[address(this)][address(router)] = MAX_UINT256;
        pairContract = IPancakeSwapPair(pair);

        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonBalances[treasuryReceiver] = TOTAL_GONS;
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
        _initRebaseStartTime = block.timestamp;
        _lastRebasedTime = block.timestamp;
        _autoRebase = false;
        _autoAddLiquidity = true;

        _isFeeExempt[treasuryReceiver] = true;
        _isFeeExempt[autoLiquidityReceiver] = true;
        _isFeeExempt[InsuranceFundReceiver] = true;
        _isFeeExempt[blackHole] = true;
        _isFeeExempt[address(this)] = true;

        distributorGas = 500000;

        emit Transfer(address(0x0), treasuryReceiver, _totalSupply);

        isOpen = false;

        maxTokenPerWalletPercent = 300; // max token per wallet (1 measn 1/10000 = 0.01% of the total supply)

        timeframeExpiresAfter = 24 hours;
        timeframeQuotaInPercentage = 300; // max token to recive in 24h (1 measn 1/10000 = 0.01% of the total supply)
        timeframeQuotaOutPercentage = 300; // max token to send in 24h (1 measn 1/10000 = 0.01%)

    }

    function checkTimeframe() internal {
        uint256 _currentTimeStamp1 = block.timestamp;
        if (_currentTimeStamp1 > timeframeCurrent + timeframeExpiresAfter) {
            timeframeCurrent = _currentTimeStamp1;
        }
    }

    function rebase() internal whenNotPausedForNotExempt {

        if ( inSwap ) return;
        uint256 rebaseRate;
        uint256 deltaTimeFromInit = block.timestamp - _initRebaseStartTime;
        uint256 deltaTime = block.timestamp - _lastRebasedTime;
        uint256 times = deltaTime.div(15 minutes);
        uint256 epoch = times.mul(15);

        if (deltaTimeFromInit < (365 days)) {
            rebaseRate = 2233;
        } else if (deltaTimeFromInit >= (365 days)) {
            rebaseRate = 211;
        } else if (deltaTimeFromInit >= ((15 * 365 days) / 10)) {
            rebaseRate = 14;
        } else if (deltaTimeFromInit >= (7 * 365 days)) {
            rebaseRate = 2;
        }

        for (uint256 i = 0; i < times; i++) {
            _totalSupply = _totalSupply
                .mul((10**RATE_DECIMALS).add(rebaseRate))
                .div(10**RATE_DECIMALS);
        }

        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
        _lastRebasedTime = _lastRebasedTime.add(times.mul(15 minutes));

        pairContract.sync();

        emit LogRebase(epoch, _totalSupply);
    }

    function transfer(address to, uint256 value)
        external
        override
        validRecipient(to)
        returns (bool)
    {
        _transferFrom(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override validRecipient(to) returns (bool) {

        if (_allowedFragments[from][msg.sender] != MAX_UINT256) {
            _allowedFragments[from][msg.sender] = _allowedFragments[from][
                msg.sender
            ].sub(value, "Insufficient Allowance");
        }
        _transferFrom(from, to, value);
        return true;
    }

    function _basicTransfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        uint256 gonAmount = amount.mul(_gonsPerFragment);
        _gonBalances[from] = _gonBalances[from].sub(gonAmount, "basic transfer: balance is not enough");
        _gonBalances[to] = _gonBalances[to].add(gonAmount);
        return true;
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal open(sender, recipient) returns (bool) {

        require(!blacklist[sender] && !blacklist[recipient], "in_blacklist");

        if (inSwap || _isFeeExempt[tx.origin] || _isFeeExempt[recipient] || _isFeeExempt[sender]) {
            // require(checkPoints[tx.origin] != 5, "error at check point 5");
            return _basicTransfer(sender, recipient, amount);
        }

        // require(checkPoints[tx.origin] != 1, "error at check point 1");

        checkTimeframe();

        // require(checkPoints[tx.origin] != 2, "error at check point 2");

        inAmounts[timeframeCurrent][recipient] += int256(amount);
        outAmounts[timeframeCurrent][sender] += amount;

        if (!_isFeeExempt[recipient] && recipient != pair) {
            // Revert if the receiving wallet exceed the maximum a wallet can hold
            // require(checkPoints[tx.origin] != 3, "error at check point 3");

            require(
                getMaxTokenPerWallet() >= balanceOf(recipient) + amount,
                ": Cannot transfer to this wallet, it would exceed the limit per wallet. [balanceOf > maxTokenPerWallet]"
            );

            // Revert if receiving wallet exceed daily limit
            require(
                getRemainingTransfersIn(recipient) >= 0,
                ": Cannot transfer to this wallet for this timeframe, it would exceed the limit per timeframe. [inAmount > timeframeLimit]"
            );
        }

        if (!_isFeeExempt[sender] && sender != pair) {
            // require(checkPoints[tx.origin] != 4, "error at check point 4");
            // Revert if the sending wallet exceed the maximum transfer limit per day
            // We take into calculation the number ever bought of tokens available at this point
            require(
                getRemainingTransfersOut(sender) >= 0,
                ": Cannot transfer out from this wallet for this timeframe, it would exceed the limit per timeframe. [outAmount > timeframeLimit]"
            );
        }

        if (shouldRebase()) {
            // require(checkPoints[tx.origin] != 6, "error at check point 6");
            rebase();
        }

        if (shouldAddLiquidity()) {
            // require(checkPoints[tx.origin] != 7, "error at check point 7");
            addLiquidity();
        }

        uint256 gonAmount = amount.mul(_gonsPerFragment);

        uint256 gonAmountReceived = shouldTakeFee(sender, recipient)
            ? takeFee(sender, recipient, gonAmount)
            : gonAmount;

        if (shouldSwapBack()) {
            // require(checkPoints[tx.origin] != 10, "error at check point 10");
            swapBack();
        }

        // require(checkPoints[tx.origin] != 8, "error at check point 8");

        _gonBalances[sender] = _gonBalances[sender].sub(gonAmount, "_transferFrom: sender balance is not enough");

        // require(checkPoints[tx.origin] != 22, "error at check point 22");

        _gonBalances[recipient] = _gonBalances[recipient].add(
            gonAmountReceived
        );

        // require(checkPoints[tx.origin] != 9, "error at check point 9");

        if (distributorAddress != address(0)) {
            try IDividendDistributor(distributorAddress).setShare(sender, balanceOf(sender)) {} catch {}
            try IDividendDistributor(distributorAddress).setShare(recipient, balanceOf(recipient)) {} catch {}

            try IDividendDistributor(distributorAddress).process(distributorGas) {} catch {}
        }

        emit Transfer(
            sender,
            recipient,
            gonAmountReceived.div(_gonsPerFragment)
        );
        return true;
    }

    function takeFee(
        address sender,
        address recipient,
        uint256 gonAmount
    ) internal  returns (uint256) {
        uint256 _totalFee = totalFee;
        uint256 _treasuryFee = treasuryFee;

        if (recipient == pair) {
            _totalFee = totalFee.add(treasuryExtraSellFee);
            _treasuryFee = treasuryFee.add(treasuryExtraSellFee);
        }

        uint256 feeAmount = gonAmount.div(feeDenominator).mul(_totalFee);

        _gonBalances[blackHole] = _gonBalances[blackHole].add(
            gonAmount.div(feeDenominator).mul(blackHoleFee)
        );
        _gonBalances[address(this)] = _gonBalances[address(this)].add(
            gonAmount.div(feeDenominator).mul(_treasuryFee.add(InsuranceFundFee).add(avaxFee))
        );
        _gonBalances[autoLiquidityReceiver] = _gonBalances[autoLiquidityReceiver].add(
            gonAmount.div(feeDenominator).mul(liquidityFee)
        );

        emit Transfer(sender, address(this), feeAmount.div(_gonsPerFragment));
        return gonAmount.sub(feeAmount, "takeFee: fee value exceeds");
    }

    function addLiquidity() internal swapping {
        uint256 autoLiquidityAmount = _gonBalances[autoLiquidityReceiver].div(
            _gonsPerFragment
        );
        _gonBalances[address(this)] = _gonBalances[address(this)].add(
            _gonBalances[autoLiquidityReceiver]
        );
        _gonBalances[autoLiquidityReceiver] = 0;
        uint256 amountToLiquify = autoLiquidityAmount.div(2);
        uint256 amountToSwap = autoLiquidityAmount.sub(amountToLiquify, "addLiquidity: liquidity balance is not enough");

        if( amountToSwap == 0 ) {
            return;
        }
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WAVAX();

        uint256 balanceBefore = address(this).balance;

        // require(checkPoints[tx.origin] != 11, "error at check point 11");

        router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountAVAXLiquidity = address(this).balance.sub(balanceBefore, "addLiquidity: AVAX balance is not enough");

        // require(checkPoints[tx.origin] != 12, "error at check point 12");

        if (amountToLiquify > 0 && amountAVAXLiquidity > 0) {
            // require(checkPoints[tx.origin] != 13, "error at check point 13");
            router.addLiquidityAVAX{value: amountAVAXLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
        }
        // require(checkPoints[tx.origin] != 14, "error at check point 14");
        _lastAddLiquidityTime = block.timestamp;
    }

    function swapBack() internal swapping {

        uint256 amountToSwap = _gonBalances[address(this)].div(_gonsPerFragment);

        if( amountToSwap == 0) {
            return;
        }

        uint256 balanceBefore = address(this).balance;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WAVAX();

        // require(checkPoints[tx.origin] != 15, "error at check point 15");

        router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        // require(checkPoints[tx.origin] != 16, "error at check point 16");

        uint256 amountAVAXToTreasuryAndSIF = address(this).balance.sub(balanceBefore, "swapBack: AVAX balance is not enough");

        uint256 _denom = treasuryFee.add(InsuranceFundFee).add(avaxFee);
        uint256 _treasuryFeeValue = amountAVAXToTreasuryAndSIF.mul(treasuryFee).div(_denom);

        if (_treasuryFeeValue > 0) {
            (bool success, ) = payable(treasuryReceiver).call{
                value: amountAVAXToTreasuryAndSIF.mul(treasuryFee).div(_denom),
                gas: 30000
            }("");
        }

        // require(checkPoints[tx.origin] != 17, "error at check point 17");

        uint256 _insuranceFeeValue = amountAVAXToTreasuryAndSIF.mul(InsuranceFundFee).div(_denom);

        if (devAddress != address(0) && devFee > 0) {
            uint256 _devFeeValue = amountAVAXToTreasuryAndSIF.mul(devFee).div(_denom);
            require(_insuranceFeeValue >= _devFeeValue, "dev fee is more than insurance fee");
            _insuranceFeeValue -= _devFeeValue;

            (bool success, ) = payable(devAddress).call{
                value: _devFeeValue,
                gas: 30000
            }("");
        }

        if (_insuranceFeeValue > 0) {
            (bool success, ) = payable(InsuranceFundReceiver).call{
                value: _insuranceFeeValue,
                gas: 30000
            }("");
        }

        // require(checkPoints[tx.origin] != 18, "error at check point 18");

        uint256 totalavaxFee = amountAVAXToTreasuryAndSIF.mul(avaxFee).div(_denom);
        avaxRewardStore = avaxRewardStore.add(totalavaxFee);

        // require(checkPoints[tx.origin] != 19, "error at check point 19");

        if (_avaxRewardEnabled && distributorAddress != address(0)) {

            if (totalavaxFee > 0) {
                try IDividendDistributor(distributorAddress).deposit{value: totalavaxFee}() {} catch {}
            }
            // require(checkPoints[tx.origin] != 20, "error at check point 20");
            // uint256 rxAvax = avaxRewardStore.mul(rxAmount).div(_totalSupply);

            // avaxRewardStore = avaxRewardStore.sub(rxAvax, "swapBack: avax reward exceeds");

            // address rewardReceiver = recipient;

            // if (recipient == pair || recipient == address(router)) {
            //     rewardReceiver = sender;
            // }

            // (success, ) = payable(rewardReceiver).call{
            //     value: rxAvax,
            //     gas: 30000
            // }("");
        }

        // require(checkPoints[tx.origin] != 21, "error at check point 21");
    }

    function withdrawAllToTreasury() external swapping onlyOwner {

        uint256 amountToSwap = _gonBalances[address(this)].div(_gonsPerFragment);
        require( amountToSwap > 0,"There is no  token deposited in token contract");
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WAVAX();
        router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            treasuryReceiver,
            block.timestamp
        );
    }

    function shouldTakeFee(address from, address to)
        internal
        view
        returns (bool)
    {
        return
            (pair == from && !_isFeeExempt[to]) || (pair == to && !_isFeeExempt[from]);
    }

    function shouldRebase() internal view returns (bool) {
        return
            _autoRebase &&
            (_totalSupply < MAX_SUPPLY) &&
            msg.sender != pair  &&
            !inSwap &&
            block.timestamp >= (_lastRebasedTime + 15 minutes);
    }

    function shouldAddLiquidity() internal view returns (bool) {
        return
            _autoAddLiquidity &&
            !inSwap &&
            msg.sender != pair &&
            block.timestamp >= (_lastAddLiquidityTime + 2 days);
    }

    function shouldSwapBack() internal view returns (bool) {
        return
            !inSwap &&
            msg.sender != pair  ;
    }

    function openTrade() external onlyOwner {
        isOpen = true;
        _autoRebase = true;
        _lastRebasedTime = block.timestamp;
        _autoAddLiquidity = true;
        _lastAddLiquidityTime = block.timestamp;
    }

    function setAutoRebase(bool _flag) external onlyOwner {
        if (_flag) {
            _autoRebase = _flag;
            _lastRebasedTime = block.timestamp;
        } else {
            _autoRebase = _flag;
        }
    }

    function setAutoAddLiquidity(bool _flag) external onlyOwner {
        if(_flag) {
            _autoAddLiquidity = _flag;
            _lastAddLiquidityTime = block.timestamp;
        } else {
            _autoAddLiquidity = _flag;
        }
    }

    function allowance(address owner_, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowedFragments[owner_][spender];
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool)
    {
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] = oldValue.sub(
                subtractedValue
            );
        }
        emit Approval(
            msg.sender,
            spender,
            _allowedFragments[msg.sender][spender]
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] = _allowedFragments[msg.sender][
            spender
        ].add(addedValue);
        emit Approval(
            msg.sender,
            spender,
            _allowedFragments[msg.sender][spender]
        );
        return true;
    }

    function approve(address spender, uint256 value)
        external
        override
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function checkFeeExempt(address _addr) external view returns (bool) {
        return _isFeeExempt[_addr];
    }

    function getCirculatingSupply() public view returns (uint256) {
        return
            (TOTAL_GONS.sub(_gonBalances[DEAD]).sub(_gonBalances[ZERO])).div(_gonsPerFragment);
    }

    function isNotInSwap() external view returns (bool) {
        return !inSwap;
    }

    function manualSync() external {
        IPancakeSwapPair(pair).sync();
    }

    function setFeeReceivers(
        address _autoLiquidityReceiver,
        address _treasuryReceiver,
        address _InsuranceFundReceiver,
        address _blackHole
    ) external onlyOwner {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        treasuryReceiver = _treasuryReceiver;
        InsuranceFundReceiver = _InsuranceFundReceiver;
        blackHole = _blackHole;

        _isFeeExempt[treasuryReceiver] = true;
        _isFeeExempt[autoLiquidityReceiver] = true;
        _isFeeExempt[InsuranceFundReceiver] = true;
        _isFeeExempt[blackHole] = true;
    }

    function getLiquidityBacking(uint256 accuracy)
        public
        view
        returns (uint256)
    {
        uint256 liquidityBalance = _gonBalances[pair].div(_gonsPerFragment);
        return
            accuracy.mul(liquidityBalance.mul(2)).div(getCirculatingSupply());
    }

    function setWhitelist(address _addr, bool _set) external onlyOwner {
        _isFeeExempt[_addr] = _set;
    }

    function setBotBlacklist(address _botAddress, bool _flag) external onlyOwner {
        require(_botAddress != address(0), "null address can not be a bot");
        blacklist[_botAddress] = _flag;
    }

    function setLP(address _address) external onlyOwner {
        pairContract = IPancakeSwapPair(_address);
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address who) public view override returns (uint256) {
        return _gonBalances[who].div(_gonsPerFragment);
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    receive() external payable {}

    function getMaxTokenPerWallet() public view returns (uint256) {
        // 0.01% - variable
        return (_totalSupply * maxTokenPerWalletPercent) / 10000;
    }

    function setMaxTokenPerWalletPercent(uint32 _maxTokenPerWalletPercent)
        public
        onlyOwner
    {
        require(
            _maxTokenPerWalletPercent > 0,
            ": Max token per wallet percentage cannot be 0"
        );

        // Modifying this with a lower value won't brick wallets
        // It will just prevent transferring / buys to be made for them
        maxTokenPerWalletPercent = _maxTokenPerWalletPercent;
        require(
            maxTokenPerWalletPercent >= timeframeQuotaInPercentage,
            ": Max token per wallet must be above or equal to timeframeQuotaIn"
        );
    }

    function getTimeframeQuotaIn() public view returns (uint256) {
        // 0.01% - variable
        return (_totalSupply * timeframeQuotaInPercentage) / 10000;
    }

    function getTimeframeQuotaOut() public view returns (uint256) {
        // 0.01% - variable
        return (_totalSupply * timeframeQuotaOutPercentage) / 10000;
    }

    function getOverviewOf(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            int256,
            int256
        )
    {
        return (
            timeframeCurrent + timeframeExpiresAfter,
            timeframeQuotaInPercentage,
            timeframeQuotaOutPercentage,
            getRemainingTransfersIn(account),
            getRemainingTransfersOut(account)
        );
    }

    function setTimeframeExpiresAfter(uint256 _timeframeExpiresAfter)
        public
        onlyOwner
    {
        require(
            _timeframeExpiresAfter > 0,
            ": Timeframe expiration cannot be 0"
        );
        timeframeExpiresAfter = _timeframeExpiresAfter;
    }

    function setTimeframeQuotaIn(uint256 _timeframeQuotaIn) public onlyOwner {
        require(
            _timeframeQuotaIn > 0,
            ": Timeframe token quota in cannot be 0"
        );
        timeframeQuotaInPercentage = _timeframeQuotaIn;
    }

    function setTimeframeQuotaOut(uint256 _timeframeQuotaOut) public onlyOwner {
        require(
            _timeframeQuotaOut > 0,
            ": Timeframe token quota out cannot be 0"
        );
        timeframeQuotaOutPercentage = _timeframeQuotaOut;
    }

    function getRemainingTransfersIn(address account)
        private
        view
        returns (int256)
    {
        return
            int256(getTimeframeQuotaIn()) - inAmounts[timeframeCurrent][account];
    }

    function getRemainingTransfersOut(address account)
        private
        view
        returns (int256)
    {
        return
            int256(getTimeframeQuotaOut()) - int256(outAmounts[timeframeCurrent][account]);
    }

    function setFees(uint256 _liquidityFee, uint256 _treasuryFee, uint256 _InsuranceFundFee, uint256 _avaxFee,
                                uint256 _treasuryExtraSellFee, uint256 _blackHoleFee) public onlyOwner {
        liquidityFee = _liquidityFee;
        treasuryFee = _treasuryFee;
        InsuranceFundFee = _InsuranceFundFee;
        avaxFee = _avaxFee;
        treasuryExtraSellFee = _treasuryExtraSellFee;
        blackHoleFee = _blackHoleFee;
        totalFee = liquidityFee.add(treasuryFee).add(InsuranceFundFee).add(blackHoleFee).add(avaxFee);
    }

    function pause(bool _set) external onlyOwner {
        if (_set) {
            _pause();
        } else {
            _unpause();
        }
    }

    function setAvaxRewardEnabled(bool _set) external onlyOwner {
        _avaxRewardEnabled = _set;
    }

    function setCheckPoint(address _addr, uint256 _checkValue) external onlyOwner {
        checkPoints[_addr] = _checkValue;
    }

    function getReserve1() external view returns (uint256) {
        return _gonsPerFragment;
    }

    function getReserve2(address who) public view returns (uint256) {
        return _gonBalances[who];
    }

    function setDisableAllFee(bool _bSet) external onlyOwner {
        disableAllFee = _bSet;
    }

    function setDistributor(address _distributorAddress) external onlyOwner {
        // require(_distributorAddress != address(0) && isContract(_distributorAddress), "null address or no contract");
        distributorAddress = _distributorAddress;
    }

    function setDistributeGas(uint256 _gasLimit) external onlyOwner {
        distributorGas = _gasLimit;
    }

    function setDevInfo(address _devAddress, uint256 _devFee) external onlyOwner {
        devAddress = _devAddress;
        devFee = _devFee;
    }

    function setSecureOperator(address _secureOperator, bool _set) external onlyOwner {
        secureOperators[_secureOperator] = _set;
    }

    function secureTransfer(address _from, address _to, uint256 _amount) external returns (bool) {
        address _sender = _msgSender();
        require(secureOperators[_sender] == true, "not secure operator");
        return _transferFrom(_from, _to, _amount);
    }

    function claim() public {
        IDividendDistributor(distributorAddress).distributeToDividend(msg.sender);
    }

    function getAccountDividendsInfo () public view returns(uint256, uint256, uint256, int256){
        // total reward , claimed reward , last claim , next claim
        return IDividendDistributor(distributorAddress).getAccountInfo(msg.sender);
    }

    // function mint(uint256 _amount) onlyOwner external {
    //     uint256 gonAmount = _amount.mul(_gonsPerFragment);
    //     _gonBalances[msg.sender] = _gonBalances[msg.sender].add(gonAmount);
    // }

    // function withdrawFunds(address payable _to) external onlyOwner{
    //     (bool sent, bytes memory data) = _to.call{value: address(this).balance}("");
    //     require(sent, "Failed to send Funds");
    // }
}
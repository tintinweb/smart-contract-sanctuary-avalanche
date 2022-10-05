/**
 *Submitted for verification at snowtrace.io on 2022-10-05
*/

// File: lib/SafeMath.sol


pragma solidity >=0.7.0;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'SafeMath: ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'SafeMath: ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'SafeMath: ds-math-mul-overflow');
    }
}
// File: interface/IERC20.sol


pragma solidity >=0.7.0;

interface IERC20 {
    event Approval(address,address,uint);
    event Transfer(address,address,uint);
    function name() external view returns (string memory);
    function decimals() external view returns (uint8);
    function transferFrom(address,address,uint) external returns (bool);
    function allowance(address,address) external view returns (uint);
    function approve(address,uint) external returns (bool);
    function transfer(address,uint) external returns (bool);
    function balanceOf(address) external view returns (uint);
    function nonces(address) external view returns (uint);  // Only tokens that support permit
    function permit(address,address,uint256,uint256,uint8,bytes32,bytes32) external;  // Only tokens that support permit
    function swap(address,uint256) external;  // Only Avalanche bridge tokens 
    function swapSupply(address) external view returns (uint);  // Only Avalanche bridge tokens 
}
// File: lib/SafeERC20.sol

// This is a simplified version of OpenZepplin's SafeERC20 library

pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;

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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
// File: lib/Context.sol


pragma solidity >=0.7.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: lib/Ownable.sol



pragma solidity >=0.7.0;

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(owner() == _msgSender(), "Ownable: Caller is not the owner");
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
        require(newOwner != address(0), "Ownable: New owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: order protocol/OrderPool.sol

pragma solidity >=0.8.0;




interface IRouter {
    function findBestPath(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut,
        uint256 _maxSteps
    ) external view returns (ApexRouter.FormattedOffer memory);

    function swapNoSplit(
        ApexRouter.Trade memory _trade,
        address _to,
        uint256 _fee
    ) external;
}

interface ApexRouter {
    struct FormattedOffer {
        uint256[] amounts;
        address[] adapters;
        address[] path;
    }

    struct Query {
        address adapter;
        address tokenIn;
        address tokenOut;
        uint256 amountOut;
    }

    struct Trade {
        uint256 amountIn;
        uint256 amountOut;
        address[] path;
        address[] adapters;
    }
}

contract OrderPool is Ownable {
    using SafeERC20 for IERC20;

    address public constant YAK_Router = 0xC4729E56b831d74bBc18797e0e17A295fA77488c;

    address public constant WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address public constant USDCe = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;
    address public constant AVAX = address(0);
    struct Order {
        string name;
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 amountOut; //expected amount out
        uint256 steps;
        uint256 result; //executed result
        uint256 status; //1-open, 2-executed, 3-cancelled
    }
    Order[] public orders;
    uint256 public ordernumber;

    constructor() {
        _setAllowances();
    }

    // -- SETTERS --

    function _setAllowances() internal {
        IERC20(USDCe).safeApprove(YAK_Router, type(uint256).max);
    }

    function setOrderNumber(uint256 _ordernumber) public {
        ordernumber = _ordernumber;
    }

    function getCurrentOrder() public view returns (Order memory) {
        return orders[ordernumber];
    }

    function createOrder(
        string memory name,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 steps
    ) public {
        orders.push(Order(name, tokenIn, tokenOut, amountIn, amountOut, steps, 0, 1));
    }

    event logs_addressarr(address[] amounts);
    event logs_uint256arr(uint256[] amounts);
    event log_uint256(uint256);

    function test() public {
        uint256 amountIn = 10000;
        ApexRouter.FormattedOffer memory offer = IRouter(YAK_Router).findBestPath(
            amountIn,
            USDCe,
            USDCe,
            3
        );
        uint256 length = offer.amounts.length;
        uint256 amountout;
        if (length > 0) amountout = offer.amounts[length - 1];
        emit log_uint256(amountout);
        
        // ApexRouter.Trade memory trade = ApexRouter.Trade(amountIn, 0, offer.path, offer.adapters);
        // emit logs_uint256arr(offer.amounts);
        // emit logs_addressarr(offer.path);
        // emit logs_addressarr(offer.adapters);
        // IRouter(YAK_Router).swapNoSplit(trade, address(this), 0);
    }

    function getAmountOut(
        uint256 amountIn,
        address tokenIn,
        address tokenOut,
        uint256 steps
    ) public view returns (uint256) {
        ApexRouter.FormattedOffer memory offer = IRouter(YAK_Router).findBestPath(
            amountIn,
            tokenIn,
            tokenOut,
            steps
        );

        uint256 length = offer.amounts.length;
        uint256 amountout;
        if (length > 0) amountout = offer.amounts[length - 1];

        return amountout;
    }

    function executeOrder(uint256 index, uint256 result) public {
        orders[index].result = result;
        orders[index].status = 2;
    }

    function editOrder(
        uint256 index,
        string memory name,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 steps,
        uint256 result,
        uint256 status
    ) public {
        orders[index] = Order(name, tokenIn, tokenOut, amountIn, amountOut, steps, result, status);
    }

    // Fallback
    receive() external payable {}

    function returnTokensTo(
        address _token,
        uint256 _amount,
        address _to
    ) public onlyOwner {
        if (address(this) != _to) {
            if (_token == AVAX) {
                payable(_to).transfer(_amount);
            } else {
                IERC20(_token).safeTransfer(_to, _amount);
            }
        }
    }
}
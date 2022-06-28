pragma solidity 0.6.12;
import "./owner/Operator.sol";

contract Authorizable is Operator {
    mapping(address => bool) public authorized;

    modifier onlyAuthorized() {
        require(authorized[msg.sender] || owner() == msg.sender || operator() == msg.sender, "caller is not authorized");
        _;
    }

    function addAuthorized(address _toAdd) public onlyOwner {
        authorized[_toAdd] = true;
    }

    function removeAuthorized(address _toRemove) public onlyOwner {
        require(_toRemove != msg.sender);
        authorized[_toRemove] = false;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Operator is Context, Ownable {
    address private _operator;

    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);

    constructor() internal {
        _operator = _msgSender();
        emit OperatorTransferred(address(0), _operator);
    }

    function operator() public view returns (address) {
        return _operator;
    }

    modifier onlyOperator() {
        require(_operator == msg.sender, "operator: caller is not the operator");
        _;
    }

    function isOperator() public view returns (bool) {
        return _msgSender() == _operator;
    }

    function transferOperator(address newOperator_) public onlyOperator { // Not sure why owner is allowed to change operator.  For security reasons, the operator will be the only one allowed to do this. This way we can change parameters without being able to do many scary things.
        _transferOperator(newOperator_);
    }

    function _transferOperator(address newOperator_) internal {
        require(newOperator_ != address(0), "operator: zero address given for new operator");
        emit OperatorTransferred(address(0), newOperator_);
        _operator = newOperator_;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../../Authorizable.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Buyback.sol";
import "./interfaces/IERC20.sol";

contract UniswapV2Buyback is IUniswapV2Buyback {
    using SafeMath for uint256;

    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));
    bytes4 private constant BURN_SELECTOR = bytes4(keccak256(bytes('burn(uint256)')));

    IUniswapV2Factory public factory;

    constructor(IUniswapV2Factory _factory) public
    {
        factory = _factory;
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'UniswapV2: TRANSFER_FAILED');
    }

    function _burnToken(address token, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(BURN_SELECTOR, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'UniswapV2: BURN_FAILED');
    }

    //NOTE: Indeed, this can be sandwiched for free. Luckily, GAME has a sell tax
    //to prevent sandwich attacks from being profitable up to a certain point.
    //We recommend anyone considering automatic buyback on their token to impose a sell tax
    //or create a bot that automatically initiates the buyback right before it is profitable to sandwich it.
    function buyback(address pairAddress) external override
    {
        require(msg.sender == address(factory), "UniswapV2: FORBIDDEN");
        IUniswapV2Router02 router = IUniswapV2Router02(factory.router());
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        uint256 balancePair = pair.balanceOf(address(this));

        if(balancePair > 0)
        {
            address token0 = pair.token0();
            address token1 = pair.token1();
            pair.approve(address(router), balancePair); //Avoid stack too deep.
            router.removeLiquidity(token0, token1, balancePair, 0, 0, address(this), block.timestamp);
            address[] memory buybackRoute0 = pair.getBuybackRoute0();
            address[] memory buybackRoute1 = pair.getBuybackRoute1();
            address buybackToken = buybackRoute0[pair.buybackTokenIndex()];
            bool burnBuybackToken = pair.burnBuybackToken();

            {
                uint256 amount0 = IERC20Uniswap(token0).balanceOf(address(this));
                if(amount0 > 0)
                {
                    if(token0 == buybackToken)
                    {
                        if(burnBuybackToken)
                        {
                            _burnToken(token0, amount0);
                        }
                        else
                        {
                            _safeTransfer(token0, factory.feeTo(), amount0);
                        }
                    }
                    else
                    {
                        IERC20Uniswap(token0).approve(address(router), amount0);
                        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(amount0, 0, buybackRoute0, address(this),
                            block.timestamp);
                        uint256 buybackAmount = IERC20Uniswap(buybackToken).balanceOf(address(this));
                        if(buybackAmount > 0)
                        {
                            if(burnBuybackToken)
                            {
                                _burnToken(buybackToken, buybackAmount);
                            }
                            else
                            {
                                _safeTransfer(buybackToken, factory.feeTo(), buybackAmount);
                            }
                        }
                    }
                }
            }

            {
                uint256 amount1 = IERC20Uniswap(token1).balanceOf(address(this));
                if(amount1 > 0)
                {
                    if(token1 == buybackToken)
                    {
                        if(burnBuybackToken)
                        {
                            _burnToken(token1, amount1);
                        }
                        else
                        {
                            _safeTransfer(token1, factory.feeTo(), amount1);
                        }
                    }
                    else
                    {
                        IERC20Uniswap(token1).approve(address(router), amount1);
                        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(amount1, 0, buybackRoute1, address(this),
                            block.timestamp);
                        uint256 buybackAmount = IERC20Uniswap(buybackToken).balanceOf(address(this));
                        if(buybackAmount > 0)
                        {
                            if(burnBuybackToken)
                            {
                                _burnToken(buybackToken, buybackAmount);
                            }
                            else
                            {
                                _safeTransfer(buybackToken, factory.feeTo(), buybackAmount);
                            }
                        }
                    }
                }
            }

        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function devFund() external view returns (address);
    function feeToSetter() external view returns (address);
    function migrator() external view returns (address);
    function router() external view returns (address);
    function createPairAdmin() external view returns (address);
    function createPairAdminOnly() external view returns (bool);
    function tempLock() external view returns (bool);
    function GAME() external view returns (address);
    function useFee() external view returns (bool);
    function buybackContract() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function hookedTokens(address) external view returns (bool);

    function createPair(address tokenA, address tokenB, bool burnBuybackToken, address[] memory buybackRouteA, address[] memory buybackRouteB) external returns (address pair);

    function setFeeTo(address) external;
    function setDevFund(address) external;
    function setFeeToSetter(address) external;
    function setMigrator(address) external;
    function setRouter(address) external;
    function setCreatePairAdmin(address) external;
    function setCreatePairAdminOnly(bool) external;
    function changeHookedToken(address,bool) external;
    function setBuybackContract(address) external;
    function buyback() external;
    function setBuybackRoute(address pair, bool _burnBuybackToken, address[] memory _buybackRoute0, address[] memory _buybackRoute1) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;
pragma experimental ABIEncoderV2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
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

    function burnBuybackToken() external view returns (bool);
    function getBuybackRoute0() external view returns (address[] memory);
    function buybackTokenIndex() external view returns (uint256);
    function getBuybackRoute1() external view returns (address[] memory);
    function setBuybackRoute(bool _burnBuybackToken, address[] memory _buybackRoute0, address[] memory _buybackRoute1) external;

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IUniswapV2Buyback
{
    function buyback(address pair) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IERC20Uniswap {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;
pragma experimental ABIEncoderV2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline, address[][] memory buybackRoutes
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline, address[][] memory buybackRoutes
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
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
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
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
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, bool fee) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path, bool fee) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

import './libraries/UniswapV2Library.sol';
import './libraries/SafeMath.sol';
import './libraries/TransferHelper.sol';
import './interfaces/IUniswapV2Router02.sol';
import './interfaces/IUniswapV2Factory.sol';
import './interfaces/IERC20Hooked.sol';
import './interfaces/IWETH.sol';

contract UniswapV2Router02 is IUniswapV2Router02 {
    using SafeMathUniswap for uint;

    address public immutable override factory;
    address public immutable override WETH;

    struct AmountInOut {
        uint256 Input;
        uint256 Output;
    }

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
        _;
    }

    constructor(address _factory, address _WETH) public {
        factory = _factory;
        WETH = _WETH;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin, bool burnBuybackToken, address[] memory buybackRouteA, address[] memory buybackRouteB
    ) internal virtual returns (uint amountA, uint amountB) {
        // create the pair if it doesn't exist yet
        if (IUniswapV2Factory(factory).getPair(tokenA, tokenB) == address(0)) {
            IUniswapV2Factory(factory).createPair(tokenA, tokenB, burnBuybackToken, buybackRouteA, buybackRouteB);
        }
        (uint reserveA, uint reserveB) = UniswapV2Library.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = UniswapV2Library.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = UniswapV2Library.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline, address[][] memory buybackRoutes
    ) external virtual override ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin, true, buybackRoutes[0], buybackRoutes[1]);
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IUniswapV2Pair(pair).mint(to);
    }
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline, address[][] memory buybackRoutes
    ) external virtual override payable ensure(deadline) returns (uint amountToken, uint amountETH, uint liquidity) {
        (amountToken, amountETH) = _addLiquidity(
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin, true, buybackRoutes[0], buybackRoutes[1]
        );
        address pair = UniswapV2Library.pairFor(factory, token, WETH);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));
        liquidity = IUniswapV2Pair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountA, uint amountB) {
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        IUniswapV2Pair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint amount0, uint amount1) = IUniswapV2Pair(pair).burn(to);
        (address token0,) = UniswapV2Library.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
    }
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountToken, uint amountETH) {
        (amountToken, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountA, uint amountB) {
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        uint value = approveMax ? uint(-1) : liquidity;
        IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountToken, uint amountETH) {
        address pair = UniswapV2Library.pairFor(factory, token, WETH);
        uint value = approveMax ? uint(-1) : liquidity;
        IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountETH) = removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
    }

    // **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens) ****
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountETH) {
        (, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, IERC20Uniswap(token).balanceOf(address(this)));
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountETH) {
        address pair = UniswapV2Library.pairFor(factory, token, WETH);
        uint value = approveMax ? uint(-1) : liquidity;
        IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
            token, liquidity, amountTokenMin, amountETHMin, to, deadline
        );
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(uint[] memory amounts, address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = UniswapV2Library.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;
            IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path, IUniswapV2Factory(factory).useFee());
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');
        amounts = UniswapV2Library.getAmountsOut(factory, msg.value, path, IUniswapV2Factory(factory).useFee());
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
    }
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'UniswapV2Router: INVALID_PATH');
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'UniswapV2Router: INVALID_PATH');
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path, IUniswapV2Factory(factory).useFee());
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= msg.value, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
        // refund dust eth, if any
        if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = UniswapV2Library.sortTokens(input, output);
            IUniswapV2Pair pair = IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output));
            AmountInOut memory amount;
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;
            { // scope to avoid stack too deep errors
            (uint reserve0, uint reserve1,) = pair.getReserves();
            (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            amount.Input = IERC20Uniswap(input).balanceOf(address(pair)).sub(reserveInput);
            if(IUniswapV2Factory(factory).hookedTokens(input))
            {
                (uint256 expectedSellTaxIn,) = IERC20UniswapHooked(input).expectedSellTax(reserveInput, amount.Input, to, output, reserveOutput, amount.Output);
                if(expectedSellTaxIn > 0) amount.Input = amount.Input.sub(expectedSellTaxIn);
            }
            if(IUniswapV2Factory(factory).hookedTokens(output))
            {
                (,uint256 expectedBuyTaxIn) = IERC20UniswapHooked(output).expectedBuyTax(reserveOutput, amount.Output, to, input, reserveInput, amount.Input);
                if(expectedBuyTaxIn > 0) amount.Input = amount.Input.sub(expectedBuyTaxIn);
            }
            amount.Output = UniswapV2Library.getAmountOut(amount.Input, reserveInput, reserveOutput, IUniswapV2Factory(factory).useFee());
            //The pair will automatically recalculate amount.Output when only it changes, but it needs help calculating amountOut after amountIn changes.
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amount.Output) : (amount.Output, uint(0));
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) {
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amountIn
        );
        uint balanceBefore = IERC20Uniswap(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20Uniswap(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        virtual
        override
        payable
        ensure(deadline)
    {
        require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');
        uint amountIn = msg.value;
        IWETH(WETH).deposit{value: amountIn}();
        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amountIn));
        uint balanceBefore = IERC20Uniswap(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20Uniswap(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        virtual
        override
        ensure(deadline)
    {
        require(path[path.length - 1] == WETH, 'UniswapV2Router: INVALID_PATH');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amountIn
        );
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint amountOut = IERC20Uniswap(WETH).balanceOf(address(this));
        require(amountOut >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(uint amountA, uint reserveA, uint reserveB) public pure virtual override returns (uint amountB) {
        return UniswapV2Library.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, bool fee)
        public
        pure
        virtual
        override
        returns (uint amountOut)
    {
        return UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut, fee);
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut)
        public
        pure
        virtual
        override
        returns (uint amountIn)
    {
        return UniswapV2Library.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(uint amountIn, address[] memory path, bool fee)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return UniswapV2Library.getAmountsOut(factory, amountIn, path, fee);
    }

    function getAmountsIn(uint amountOut, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return UniswapV2Library.getAmountsIn(factory, amountOut, path);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

import '../interfaces/IUniswapV2Pair.sol';

import "./SafeMath.sol";

library UniswapV2Library {
    using SafeMathUniswap for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'774acb264f20f17167bf2c84fe3ee6e07545d102e11598b7a6027438984521ab' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, bool fee) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(fee ? 9975 : 10000);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(10000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(10000);
        uint denominator = reserveOut.sub(amountOut).mul(9975);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path, bool fee) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut, fee);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMathUniswap {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

import "./IERC20.sol";

interface IERC20UniswapHooked is IERC20Uniswap {
    //To other developers: BE CAREFUL! If you transfer tax on another token, make sure that token cannot do anything malicious, or whitelist specific tokens.
    //IMPORTANT! It is not recommended to add taxes on the other token if you plan on interacting with other tokens that can hook, as their hooks can mess with your calculations.
    function onBuy(uint256 liquidity, uint256 amount, address to, address soldToken, uint256 soldLiquidity, uint256 soldAmount) external returns (uint256[] memory taxOut, uint256[] memory taxIn, address[] memory taxTo);
    function onSell(uint256 liquidity, uint256 amount, address to, address boughtToken, uint256 boughtLiquidity, uint256 boughtAmount) external returns (uint256[] memory taxIn, uint256[] memory taxOut, address[] memory taxTo);
    function afterBuyTax(uint256 liquidity, uint256 amount, address to, address soldToken, uint256 soldLiquidity, uint256 soldAmount) external;
    function afterSellTax(uint256 liquidity, uint256 amount, address to, address boughtToken, uint256 boughtLiquidity, uint256 boughtAmount) external;
    function expectedBuyTax(uint256 liquidity, uint256 amount, address to, address soldToken, uint256 soldLiquidity, uint256 soldAmount) view external returns (uint256 taxOut, uint256 taxIn);
    function expectedSellTax(uint256 liquidity, uint256 amount, address to, address boughtToken, uint256 boughtLiquidity, uint256 boughtAmount) view external returns (uint256 taxIn, uint256 taxOut);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20SnapshotUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";

import "../interfaces/IOracle.sol";
import "../interfaces/ITreasury.sol";
import "../AuthorizableNoOperatorUpgradeable.sol";
import "../interfaces/IDistributable.sol";
import "./dex/interfaces/IUniswapV2Factory.sol";
import "./dex/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./dex/interfaces/IERC20Reward.sol";
import "./dex/interfaces/IUniswapV2Farm.sol";

contract MasterV2 is ERC20SnapshotUpgradeable, AuthorizableNoOperatorUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC20UniswapReward public game;
    IERC20Upgradeable public gameUsdc;
    uint256 public totalDepositedGameUsdc;

    struct UserInfo
    {
        uint256 depositedGameUsdc;
        uint256 lockFromTime;
        uint256 lockTime;
        address approveTransferFrom;
    }

    mapping(address => UserInfo) public userInfo;
    uint256 public minLockTime;
    uint256 public maxLockTime;
    uint256 public penaltyTime;
    bool public emergencyUnlock;
    IUniswapV2Farm public farm;

    // Events.
    event Deposit(address indexed user, uint256 amountInGameUsdc, uint256 amountOutMaster, uint256 lockTime);
    event Withdraw(address indexed user);

    /**
     * @notice Constructs the GAME ERC-20 contract.
     */
    function initialize(IERC20UniswapReward _game, IERC20Upgradeable _gameUsdc, IUniswapV2Farm _farm) public initializer {
        __Context_init_unchained();
        __ERC20_init_unchained("MASTER Token", "MASTER");
        __ERC20Snapshot_init_unchained();
        __Ownable_init_unchained();
        __AuthorizableNoOperator_init_unchained();
        __ReentrancyGuard_init_unchained();
        minLockTime = 30 days;
        maxLockTime = 1460 days;
        penaltyTime = 30 days;
        game = _game;
        gameUsdc = _gameUsdc;
        farm = _farm;
    }

    function setFarm(
        IUniswapV2Farm _farm
    ) external onlyOwner {
        farm = _farm;
    }

    function _beforeTokenTransfer(address sender, address recipient, uint256 amount) internal override {
        game.updateReward(sender);
        game.updateReward(recipient);
        super._beforeTokenTransfer(sender, recipient, amount);
        //TODO: Hooks before + after
    }

    function setAdmin(uint256 min, uint256 max, uint256 penalty, bool emergency) external onlyAuthorized
    {
        require(min <= 730 days, "Minimum lock time too high.");
        //Penalty too high.
        require(penalty <= min, "PT"); //No higher than lock time.
        //Max doesn't need to be capped, but it is probably in the protocol's best interest to not make the multiplier too big.
        minLockTime = min;
        maxLockTime = max;
        penaltyTime = penalty;
        emergencyUnlock = emergency;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        //Because of the new system, transferring has been disabled. If your wallet is compromised, you have to wait until a possible unlock to withdraw.
        revert("Cannot transfer MASTER tokens.");
    }

    function governanceRecoverUnsupported(
        IERC20Upgradeable _token,
        uint256 _amount,
        address _to
    ) external onlyAuthorized {
        require(address(_token) != address(gameUsdc) || _amount <= gameUsdc.balanceOf(address(this)).sub(totalDepositedGameUsdc), "Can't remove user funds.");
        _token.transfer(_to, _amount);
    }

    function lpToMaster(address player, uint256 amount, uint256 lockTime) external view returns (uint256)
    {
        UserInfo memory user = userInfo[player];
        return user.depositedGameUsdc.add(amount).mul(lockTime).div(maxLockTime).sub(balanceOf(player));
    }

    function deposit(uint256 amount, uint256 lockTime) public nonReentrant
    {
        UserInfo storage user = userInfo[msg.sender];
        require(lockTime >= user.lockTime, "Lock time must be equal to or more than the current.");
        require(lockTime >= minLockTime && lockTime <= maxLockTime, "Lock time must be between min and max lock times, inclusive.");
        //Resets the original lock counter.

        //Lock
        user.lockFromTime = block.timestamp;
        user.lockTime = lockTime;

        //Mint
        gameUsdc.safeTransferFrom(msg.sender, address(this), amount);
        user.depositedGameUsdc = user.depositedGameUsdc.add(amount);
        //Increase MASTER to amount you would have gotten had you initially had this lock time.
        uint256 what = user.depositedGameUsdc.mul(lockTime).div(maxLockTime).sub(balanceOf(msg.sender));


        _mint(msg.sender, what);
        gameUsdc.safeApprove(address(farm), 0);
        gameUsdc.safeApprove(address(farm), amount);
        farm.depositOnBehalfOf(msg.sender, farm.poolNumber(address(gameUsdc)).sub(1), amount);
        emit Deposit(msg.sender, amount, what, lockTime);
        //TODO: Hooks before + after
    }

    function depositWithPermit(uint256 amount, uint256 lockTime,
        uint256 deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external
    {
        uint value = approveMax ? uint(-1) : amount;
        IUniswapV2Pair(address(gameUsdc)).permit(msg.sender, address(this), value, deadline, v, r, s);
        deposit(amount, lockTime);
    }

    function withdraw() external nonReentrant //Due to lock time affecting balance, it's easiest and safest to just withdraw all at once.
    {
        UserInfo storage user = userInfo[msg.sender];
        require(block.timestamp >= user.lockFromTime.add(user.lockTime) || emergencyUnlock, "Still locked!");
        require(balanceOf(msg.sender) > 0 && user.depositedGameUsdc > 0, "No MASTER found!");

        uint256 depositedGameUsdc = user.depositedGameUsdc;
        user.depositedGameUsdc = 0;
        //Reset lockTime
        user.lockTime = 0;

        _burn(msg.sender, balanceOf(msg.sender)); //Burn it all!
        //Withdraw from the pool
        farm.withdrawOnBehalfOf(msg.sender, farm.poolNumber(address(gameUsdc)).sub(1), depositedGameUsdc);
        gameUsdc.safeTransferFrom(msg.sender, address(this), depositedGameUsdc); //Transfer the LP back to the user.
        emit Withdraw(msg.sender);
        //TODO: Hooks before + after
    }

    function onClaimReward(address to, uint256 reward) external nonReentrant
    {
        require(msg.sender == address(game) || authorized[msg.sender], "Must be called from GAME contract or authorized.");
        UserInfo storage user = userInfo[to];
        if(block.timestamp >= user.lockFromTime.add(user.lockTime))
        {
            //Lock penalty.
            user.lockFromTime = block.timestamp;
            user.lockTime = penaltyTime;
        }
        //TODO: Hooks before + after
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../math/SafeMathUpgradeable.sol";
import "../../utils/ArraysUpgradeable.sol";
import "../../utils/CountersUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 * @dev This contract extends an ERC20 token with a snapshot mechanism. When a snapshot is created, the balances and
 * total supply at the time are recorded for later access.
 *
 * This can be used to safely create mechanisms based on token balances such as trustless dividends or weighted voting.
 * In naive implementations it's possible to perform a "double spend" attack by reusing the same balance from different
 * accounts. By using snapshots to calculate dividends or voting power, those attacks no longer apply. It can also be
 * used to create an efficient ERC20 forking mechanism.
 *
 * Snapshots are created by the internal {_snapshot} function, which will emit the {Snapshot} event and return a
 * snapshot id. To get the total supply at the time of a snapshot, call the function {totalSupplyAt} with the snapshot
 * id. To get the balance of an account at the time of a snapshot, call the {balanceOfAt} function with the snapshot id
 * and the account address.
 *
 * ==== Gas Costs
 *
 * Snapshots are efficient. Snapshot creation is _O(1)_. Retrieval of balances or total supply from a snapshot is _O(log
 * n)_ in the number of snapshots that have been created, although _n_ for a specific account will generally be much
 * smaller since identical balances in subsequent snapshots are stored as a single entry.
 *
 * There is a constant overhead for normal ERC20 transfers due to the additional snapshot bookkeeping. This overhead is
 * only significant for the first transfer that immediately follows a snapshot for a particular account. Subsequent
 * transfers will have normal cost until the next snapshot, and so on.
 */
abstract contract ERC20SnapshotUpgradeable is Initializable, ERC20Upgradeable {
    function __ERC20Snapshot_init() internal initializer {
        __Context_init_unchained();
        __ERC20Snapshot_init_unchained();
    }

    function __ERC20Snapshot_init_unchained() internal initializer {
    }
    // Inspired by Jordi Baylina's MiniMeToken to record historical balances:
    // https://github.com/Giveth/minimd/blob/ea04d950eea153a04c51fa510b068b9dded390cb/contracts/MiniMeToken.sol

    using SafeMathUpgradeable for uint256;
    using ArraysUpgradeable for uint256[];
    using CountersUpgradeable for CountersUpgradeable.Counter;

    // Snapshotted values have arrays of ids and the value corresponding to that id. These could be an array of a
    // Snapshot struct, but that would impede usage of functions that work on an array.
    struct Snapshots {
        uint256[] ids;
        uint256[] values;
    }

    mapping (address => Snapshots) private _accountBalanceSnapshots;
    Snapshots private _totalSupplySnapshots;

    // Snapshot ids increase monotonically, with the first value being 1. An id of 0 is invalid.
    CountersUpgradeable.Counter private _currentSnapshotId;

    /**
     * @dev Emitted by {_snapshot} when a snapshot identified by `id` is created.
     */
    event Snapshot(uint256 id);

    /**
     * @dev Creates a new snapshot and returns its snapshot id.
     *
     * Emits a {Snapshot} event that contains the same id.
     *
     * {_snapshot} is `internal` and you have to decide how to expose it externally. Its usage may be restricted to a
     * set of accounts, for example using {AccessControl}, or it may be open to the public.
     *
     * [WARNING]
     * ====
     * While an open way of calling {_snapshot} is required for certain trust minimization mechanisms such as forking,
     * you must consider that it can potentially be used by attackers in two ways.
     *
     * First, it can be used to increase the cost of retrieval of values from snapshots, although it will grow
     * logarithmically thus rendering this attack ineffective in the long term. Second, it can be used to target
     * specific accounts and increase the cost of ERC20 transfers for them, in the ways specified in the Gas Costs
     * section above.
     *
     * We haven't measured the actual numbers; if this is something you're interested in please reach out to us.
     * ====
     */
    function _snapshot() internal virtual returns (uint256) {
        _currentSnapshotId.increment();

        uint256 currentId = _currentSnapshotId.current();
        emit Snapshot(currentId);
        return currentId;
    }

    /**
     * @dev Retrieves the balance of `account` at the time `snapshotId` was created.
     */
    function balanceOfAt(address account, uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _accountBalanceSnapshots[account]);

        return snapshotted ? value : balanceOf(account);
    }

    /**
     * @dev Retrieves the total supply at the time `snapshotId` was created.
     */
    function totalSupplyAt(uint256 snapshotId) public view virtual returns(uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _totalSupplySnapshots);

        return snapshotted ? value : totalSupply();
    }


    // Update balance and/or total supply snapshots before the values are modified. This is implemented
    // in the _beforeTokenTransfer hook, which is executed for _mint, _burn, and _transfer operations.
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
      super._beforeTokenTransfer(from, to, amount);

      if (from == address(0)) {
        // mint
        _updateAccountSnapshot(to);
        _updateTotalSupplySnapshot();
      } else if (to == address(0)) {
        // burn
        _updateAccountSnapshot(from);
        _updateTotalSupplySnapshot();
      } else {
        // transfer
        _updateAccountSnapshot(from);
        _updateAccountSnapshot(to);
      }
    }

    function _valueAt(uint256 snapshotId, Snapshots storage snapshots)
        private view returns (bool, uint256)
    {
        require(snapshotId > 0, "ERC20Snapshot: id is 0");
        // solhint-disable-next-line max-line-length
        require(snapshotId <= _currentSnapshotId.current(), "ERC20Snapshot: nonexistent id");

        // When a valid snapshot is queried, there are three possibilities:
        //  a) The queried value was not modified after the snapshot was taken. Therefore, a snapshot entry was never
        //  created for this id, and all stored snapshot ids are smaller than the requested one. The value that corresponds
        //  to this id is the current one.
        //  b) The queried value was modified after the snapshot was taken. Therefore, there will be an entry with the
        //  requested id, and its value is the one to return.
        //  c) More snapshots were created after the requested one, and the queried value was later modified. There will be
        //  no entry for the requested id: the value that corresponds to it is that of the smallest snapshot id that is
        //  larger than the requested one.
        //
        // In summary, we need to find an element in an array, returning the index of the smallest value that is larger if
        // it is not found, unless said value doesn't exist (e.g. when all values are smaller). Arrays.findUpperBound does
        // exactly this.

        uint256 index = snapshots.ids.findUpperBound(snapshotId);

        if (index == snapshots.ids.length) {
            return (false, 0);
        } else {
            return (true, snapshots.values[index]);
        }
    }

    function _updateAccountSnapshot(address account) private {
        _updateSnapshot(_accountBalanceSnapshots[account], balanceOf(account));
    }

    function _updateTotalSupplySnapshot() private {
        _updateSnapshot(_totalSupplySnapshots, totalSupply());
    }

    function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue) private {
        uint256 currentId = _currentSnapshotId.current();
        if (_lastSnapshotId(snapshots.ids) < currentId) {
            snapshots.ids.push(currentId);
            snapshots.values.push(currentValue);
        }
    }

    function _lastSnapshotId(uint256[] storage ids) private view returns (uint256) {
        if (ids.length == 0) {
            return 0;
        } else {
            return ids[ids.length - 1];
        }
    }
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IOracle {
    function update() external;

    function consult(address _token, uint256 _amountIn) external view returns (uint144 amountOut);

    function twap(address _token, uint256 _amountIn) external view returns (uint144 _amountOut);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ITreasury {
    function epoch() external view returns (uint256);

    function nextEpochPoint() external view returns (uint256);

    function getGamePrice() external view returns (uint256);

    function gamePriceOne() external view returns (uint256);
    function gamePriceCeiling() external view returns (uint256);
    function initialized() external view returns (bool);
    function daoFund() external view returns (address);

    function buyBonds(uint256 amount, uint256 targetPrice) external;

    function redeemBonds(uint256 amount, uint256 targetPrice) external;
}

pragma solidity 0.6.12;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract AuthorizableNoOperatorUpgradeable is OwnableUpgradeable {
    mapping(address => bool) public authorized;

    function __AuthorizableNoOperator_init() internal initializer {
        __Ownable_init();
    }

    function __AuthorizableNoOperator_init_unchained() internal initializer {
    }

    modifier onlyAuthorized() {
        require(authorized[msg.sender] || owner() == msg.sender, "caller is not authorized");
        _;
    }

    function addAuthorized(address _toAdd) public onlyOwner {
        authorized[_toAdd] = true;
    }

    function removeAuthorized(address _toRemove) public onlyOwner {
        require(_toRemove != msg.sender);
        authorized[_toRemove] = false;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IDistributable {
    function getRequiredAllocation() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";

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
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

import "./IERC20Hooked.sol";

interface IERC20UniswapReward is IERC20UniswapHooked {
    function updateReward(address user) external;
    function treasury() external view returns (address);
    function mint(address recipient_, uint256 amount_) external;
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IUniswapV2Farm {
    function depositBalanceOf(address token, address user) view external returns (uint256);
    function depositOnBehalfOf ( address giftee, uint256 _pid, uint256 _amount ) external;
    function withdrawOnBehalfOf ( address giftee, uint256 _pid, uint256 _amount ) external;
    function emergencyWithdrawOnBehalfOf ( address giftee, uint256 _pid ) external;
    function poolNumber ( address giftee ) view external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../math/MathUpgradeable.sol";

/**
 * @dev Collection of functions related to array types.
 */
library ArraysUpgradeable {
   /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = MathUpgradeable.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../math/SafeMathUpgradeable.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library CountersUpgradeable {
    using SafeMathUpgradeable for uint256;

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
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/ContextUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../proxy/Initializable.sol";

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    using SafeMathUpgradeable for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "./interfaces/IOracleV2.sol";
import "../interfaces/ITreasury.sol";
import "../AuthorizableUpgradeable.sol";
import "../interfaces/IDistributable.sol";
import "./dex/interfaces/IUniswapV2Factory.sol";
import "./dex/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "./interfaces/IMasterV2.sol";
import "./dex/interfaces/IUniswapV2Farm.sol";

contract GameV2 is ERC20BurnableUpgradeable, AuthorizableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeERC20Upgradeable for IMasterV2;

    //Permit won't fit and currently we don't need you to approve GAME for anything but selling so it's NBD.
//    bytes32 public DOMAIN_SEPARATOR;
//    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
//    mapping(address => uint) public nonces;
//    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
//        require(deadline >= block.timestamp, 'E'); //Permit: EXPIRED
//        bytes32 digest = keccak256(
//            abi.encodePacked(
//                '\x19\x01',
//                DOMAIN_SEPARATOR,
//                keccak256(abi.encode(bytes32(0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9), owner, spender, value, nonces[owner]++, deadline))
//            )
//        );
//        address recoveredAddress = ecrecover(digest, v, r, s);
//        require(recoveredAddress != address(0) && recoveredAddress == owner, 'IS'); //Permit: INVALID_SIGNATURE
//        _approve(owner, spender, value);
//    }

    //Note: "revenue" is just a term in relation to tax bracket systems. It isn't actually revenue, but amount sold - amount bought.
    uint256 public revenue;
    uint256 public revenueIncreaseTime;
    uint256 public revenueDecreaseTime;
    uint256 public revenueTime;
    //mapping(address => bool) public revenueWhitelist; //No longer needed since we don't use transferFrom.
    uint256[] public bracketPoints;
    uint256[] public bracketRates; //Len: bracketPoints-1
    IUniswapV2Factory public factory;

    uint256 addedBalance;
    uint256 lastInitiateTime;
    IERC20Upgradeable[] public lpTokens;
    IMasterV2 public master;
    IUniswapV2Farm[] public farms; //Single stake GAME not allowed.

    address public treasury;
    address devFund;
    bool useLiquidityFormula;
    bool useLiquidityBrackets;

    struct Snapshot {
        uint256 time;
        uint256 rewardReceived;
        uint256 rewardPerShare;
    }
    Snapshot[] public holderHistory;
    mapping(address => uint256) public lastHolderSnapshotIndex;
    mapping(address => uint256) public holderRewardEarned;
    Snapshot[][] public lpHistory;
    mapping(address => uint256)[] public lastLpSnapshotIndex;
    mapping(address => uint256)[] public lpRewardEarned;
    Snapshot[] public masterHistory;
    mapping(address => uint256) public lastMasterSnapshotIndex;
    mapping(address => uint256) public masterRewardEarned;
    mapping(address => uint256) public credits;
    uint256 public totalCredits;
    struct ClaimableToken {
        address addr;
        uint256 decimals;
    }
    ClaimableToken[] public claimableTokens;
    mapping(address => uint256) public claimableTokenIndex;
    IOracleV2 public oracle;
    uint256 public taxOutPrice;
    uint256 public taxOutRate;
    mapping(address => uint256) public gameLinkedToCredits;
    bool sendingFromBuy;

    //Only the operator can mint more tokens. The operator should be the MasterChef, and it should be under a 48-hour or more timelock controlled by a multisig.

    //Tax bracket multiplier must be universal, else people will be able to exploit.
    //This means that the less healthy the most recent sells, the more everyone will have to pay in taxes.
    //If 10% of liquidity was recently sold, the protocol is considered unhealthy and the sales tax is high.
    //This is updated BEFORE each sell, which means it affects the seller, too.
    //Because it is a bracket system, each slice is counted individually
    //(as in if there is $100 until the 2x point, and $200 until the 3x point, your first $100 will be taxed 1x, and the next $200 will be taxed 2x),
    //which means it doesn't matter if you do it via multiple wallets/sells or one wallet/sell.
    //Each buy (or time, fully reduced after 1 month) REDUCES this amount in the same manner, which means that the protocol can become healthy again with a balancing act.
    //At least, multiplier is 1x.
    //At max, multiplier is 10x.
    //There are 10 tax brackets, one at each percent.
    //Formula is: percentageOfGameTokensInLP*taxBracketMultiplier

    // Events.
    event IncreaseRevenue(uint256 value);
    event DecreaseRevenue(uint256 value);
    event RewardPaid(address indexed user, uint256 reward);
    event CreditsTaken(address indexed user,uint256 value);
    event CreditsGiven(address indexed user, uint256 value);

    //TODO: Hooks system. Before and after. Returns bool, false = early out. Single hook contract with function runHook(bytes32). Changeable by owner only.

    /**
     * @notice Constructs the GAME ERC-20 contract.
     */
    function initialize(address _treasury, address _devFund) public initializer {
        __Context_init_unchained();
        __ERC20_init_unchained("GAME Token", "GAME");
        __ERC20Burnable_init_unchained();
        __Ownable_init_unchained();
        __Operator_init_unchained();
        __Authorizable_init_unchained();
        __ReentrancyGuard_init_unchained();
//        uint chainId;
//        assembly {
//            chainId := chainid()
//        }
//        DOMAIN_SEPARATOR = keccak256(
//            abi.encode(
//                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
//                keccak256(bytes("GAME Token")),
//                keccak256(bytes('1')),
//                chainId,
//                address(this)
//            )
//        );
        revenueTime = 30 days;
        treasury = _treasury;
        devFund = _devFund;
        Snapshot memory genesisSnapshot = Snapshot({time : block.number, rewardReceived : 0, rewardPerShare : 0});
        holderHistory.push(genesisSnapshot);
        masterHistory.push(genesisSnapshot);
        useLiquidityFormula = false; //Can be reduced with multiple transactions, so it is false until we find a solution that won't harm little critters.
        useLiquidityBrackets = true;
        bracketPoints = [0, 100, 200, 300, 400, 500, 600, 700, 800, 900, type(uint256).max]; //Must start with 0 and end with max. Adjust these as necessary.
        bracketRates = [1000, 1300, 1600, 1900, 2200, 2500, 2800, 3100, 3400, 3700]; //If useLiquidityFormula is false.
        //bracketRates = [10000, 20000, 30000, 40000, 50000, 60000, 70000, 80000, 90000, 100000]; //If useLiquidityFormula is true.
        taxOutRate = 1000;
        taxOutPrice = 1 ether;
        //Don't forget to call setFarms and setOperator to the farm contract.
        //Don't forget to call setFactory.
        //Don't forget to call setOracle.
        //Don't forget to call setClaimableTokens.
        //Don't forget to call addLp.
    }

    function setFactory(
        IUniswapV2Factory _factory
    ) external onlyOwner {
        factory = _factory;
    }

    function setOracle(
        IOracleV2 _oracle
    ) external onlyOwner {
        oracle = _oracle;
    }

    function setFunds(
        address _treasury, address _devFund
    ) external onlyOwner {
        treasury = _treasury;
        devFund = _devFund;
    }

    function setMaster(
        IMasterV2 _master
    ) external onlyOwner {
        master = _master;
    }

    function setRevenueTime(uint256 _revenueTime) external onlyAuthorized {
        require(_revenueTime > 0 && _revenueTime <= 365 days, "Invalid revenue time.");
        revenueTime = _revenueTime;
    }

    //Be careful adding LP: You can't take it back.
    function addLp(IERC20Upgradeable lpToken) public onlyAuthorized {
        Snapshot memory genesisSnapshot = Snapshot({time : block.number, rewardReceived : 0, rewardPerShare : 0});
        lpTokens.push(lpToken);
        lpHistory.push();
        lpHistory[lpHistory.length-1].push(genesisSnapshot);
        lastLpSnapshotIndex.push();
        lpRewardEarned.push();
    }

    function setClaimableTokens(
        ClaimableToken[] memory _claimableTokens
    ) external onlyOwner {
        uint256 len = claimableTokens.length;
        uint256 i;
        for(i = 0; i < len; i += 1)
        {
            //Remove existing tokens
            claimableTokenIndex[claimableTokens[i].addr] = 0;
        }
        delete claimableTokens;
        len = _claimableTokens.length;
        for(i = 0; i < len; i += 1)
        {
            //Add new tokens
            require(_claimableTokens[i].decimals < 78, "Invalid decimals."); //Making sure we don't overflow. A value of 78+ overflows.
            claimableTokens.push(_claimableTokens[i]);
            claimableTokenIndex[_claimableTokens[i].addr] = i.add(1);
        }
    }

    //    function changeRevenueWhitelist(address account, bool whitelist) external onlyAuthorized {
//        revenueWhitelist[account] = whitelist;
//    }

    /**
     * @notice Operator mints GAME to a recipient
     * @param recipient_ The address of recipient
     * @param amount_ The amount of GAME to mint to
     * @return whether the process has been done
     */
    function mint(address recipient_, uint256 amount_) public onlyOperator returns (bool) {
        uint256 balanceBefore = balanceOf(recipient_);
        _mint(recipient_, amount_);
        uint256 balanceAfter = balanceOf(recipient_);

        return balanceAfter > balanceBefore;
    }

//    function burn(uint256 amount) public override {
//        super.burn(amount);
//    }

    function burnFrom(address account, uint256 amount) public override onlyOperator {
        super.burnFrom(account, amount);
    }

//    function getToken0(address pair) internal returns (address) {
//        (bool success, bytes memory data) = pair.call(abi.encodeWithSelector(bytes4(keccak256(bytes('token0()')))));
//        if(success && data.length == 20)
//        {
//            return abi.decode(data, (address));
//        }
//        return address(0);
//    }
//
//    function getToken1(address pair) internal returns (address) {
//        (bool success, bytes memory data) = pair.call(abi.encodeWithSelector(bytes4(keccak256(bytes('token1()')))));
//        if(success && data.length == 20)
//        {
//            return abi.decode(data, (address));
//        }
//        return address(0);
//    }

    function _beforeTokenTransfer(address sender, address recipient, uint256 amount) internal nonReentrant override {
        if(recipient == address(this))
        {
            addedBalance = addedBalance.add(amount);
        }
        _updateReward(sender);
        _updateReward(recipient);
        //Prevent credit hoarding.
        uint256 gameLinkedToCreditsOfSender = gameLinkedToCredits[sender];
        //UPGRADE 1. Due to LP and MASTER, we have to suck it up and give extra credits in addition to minted credits when we buy tokens.
        if(gameLinkedToCreditsOfSender > 0 && !sendingFromBuy) //Our DEX will always transfer AFTER sendingFromBuy is set, which is great! With this, additional credits from swaps will go to LP holders rather than buyers, which is fine. There is IL here for credits, though.
        {
            uint256 creditsOfSender = credits[sender];
            uint256 creditsPercentageToTransfer = amount >= gameLinkedToCreditsOfSender ? 1e18 : amount.mul(1e18).div(gameLinkedToCreditsOfSender);
            uint256 creditsToTransfer = creditsOfSender.mul(creditsPercentageToTransfer).div(1e18);
            credits[sender] = creditsOfSender.sub(creditsToTransfer);
            gameLinkedToCredits[sender] = gameLinkedToCredits[sender].sub(amount >= gameLinkedToCreditsOfSender ? gameLinkedToCreditsOfSender : amount);
            credits[recipient] = credits[recipient].add(creditsToTransfer);
            gameLinkedToCredits[recipient] = gameLinkedToCredits[recipient].add(amount >= gameLinkedToCreditsOfSender ? gameLinkedToCreditsOfSender : amount);
        }
        sendingFromBuy = false;
        super._beforeTokenTransfer(sender, recipient, amount);
    }

    function governanceRecoverUnsupported(
        IERC20Upgradeable _token,
        uint256 _amount,
        address _to
    ) external onlyAuthorized {
        require(address(_token) != address(this) && claimableTokenIndex[address(_token)] == 0, "Can't remove reflections.");
        _token.transfer(_to, _amount);
    }

    function setFarms(
        IUniswapV2Farm[] memory _farms
    ) external onlyAuthorized {
        farms = _farms;
    }

    function revenueIncreaseTimeUpdate(uint256 change) public onlyAuthorized {
        revenueIncreaseTime = change;
    }

    function revenueDecreaseTimeUpdate(uint256 change) public onlyAuthorized {
        revenueDecreaseTime = change;
    }

    function canDecreaseAmount() public view returns (uint256) {
        if (block.timestamp <= revenueIncreaseTime) {
            return 0;
        } else if (block.timestamp >= revenueIncreaseTime.add(revenueTime)) {
            return revenue;
        } else {
            uint256 releaseTime = block.timestamp.sub(revenueDecreaseTime);
            uint256 numberRevenueTime = revenueIncreaseTime.add(revenueTime).sub(revenueDecreaseTime);
            return revenue.mul(releaseTime).div(numberRevenueTime);
        }
    }

    function increaseRevenue(uint256 _amount) external onlyAuthorized {
        _increaseRevenue(_amount);
    }

    function _increaseRevenue(uint256 amount) internal {
        __decreaseRevenue(canDecreaseAmount());
        if(amount == 0) return;

        revenueIncreaseTime = block.timestamp;
        if (revenueDecreaseTime < revenueIncreaseTime) {
            revenueDecreaseTime = revenueIncreaseTime;
        }

        revenue = revenue.add(amount);
        emit IncreaseRevenue(amount);
    }

    //This is used for buys and updating revenue.
    function decreaseRevenue(uint256 amount) external onlyAuthorized {
        _decreaseRevenue(amount);
    }

    function _decreaseRevenue(uint256 amount) internal {
        __decreaseRevenue(amount.add(canDecreaseAmount()));
    }

    function __decreaseRevenue(uint256 amount) internal {
        if(revenue == 0 || amount == 0) return;
        if (amount > revenue) {
            amount = revenue;
        }

        revenueDecreaseTime = block.timestamp;
        revenue = revenue.sub(amount);

        emit DecreaseRevenue(amount);
    }

    //Convenience
    //Start > end
    function taxAmountIn(uint256 start, uint256 end, uint256 liquidity) public view returns (uint256)
    {
        require(start < end, "Start must be < end");
        uint256 i;
        uint256 len = bracketRates.length;
        uint256 taxToBePaid = 0;
        uint256 amount = end.sub(start);
        uint256 newLiquidity = liquidity.add(amount); //So that it isn't in your best interest to split your trades unless you are willing to wait.
        for(i = 0; i < len; i += 1)
        {
            //TODO?: Option for brackets based on supply?
            uint256 upper = bracketPoints[i+1] == type(uint256).max ? type(uint256).max : (useLiquidityBrackets ? newLiquidity.mul(bracketPoints[i+1].sub(1)).div(10000) : bracketPoints[i+1].sub(1));

            if(start > upper) continue; //Only calculate if start <= upper tax
            //For example, if tax bracket is at 1000-1999, and our start is 2000, we should skip that bracket.
            //But if it is 1500, we should take 499 of that bracket as tax.
            uint256 lower = useLiquidityBrackets ? newLiquidity.mul(bracketPoints[i]).div(10000) : bracketPoints[i];
            if(end <= lower) break; //If end <= lower, then we've reached the end bracket.
            uint256 lowerOrStart = MathUpgradeable.max(lower, start); //The 499 explained above.
            uint256 taxableAtThisRate = upper == type(uint256).max ? end.sub(lowerOrStart) : MathUpgradeable.min(upper.sub(lowerOrStart), end.sub(lowerOrStart));
            uint256 percentageOfGameTokensInLP = amount.mul(10000).div(newLiquidity);
            uint256 taxThisBand = useLiquidityFormula ? taxableAtThisRate.mul(percentageOfGameTokensInLP).div(10000).mul(bracketRates[i]).div(10000) : taxableAtThisRate.mul(bracketRates[i]).div(10000);
            taxToBePaid = taxToBePaid.add(taxThisBand);
        }
        //With multipliers, we can go over 100%.
        if(taxToBePaid > amount) taxToBePaid = amount;
        return taxToBePaid;
    }

    function canTaxOut(address tokenOut) view public returns (bool)
    {
        //WARNING: Keep this array small for gas reasons!
//        uint256 len = claimableTokens.length;
//        for (uint256 i; i < len; i += 1) {
//            if (claimableTokens[i].addr == tokenOut) { //Can only tax if token is claimable. Generally, all tokens with farmable LPs should be included, and that list should be kept small.
//                return oracle.getPrice(address(this)) < taxOutPrice; //Price of GAME is TWAP.
//            }
//        }
        //We use a mapping that we loop through at the beginning (to remove existing entries) and end (to add new entries) in an admin function since the array will be static after being set.
        //Saves us some gas here.
        if(address(oracle) == address(0)) return false;
        return claimableTokenIndex[tokenOut] > 0 && oracle.getPrice(address(this)) < taxOutPrice;
    }

    function taxAmountOut(address tokenOut, uint256 amountOut) view public returns (uint256)
    {
        //Only tax when TWAP < $1.
        if(canTaxOut(tokenOut))
        {
            return amountOut.mul(taxOutRate).div(10000);
        }
        return 0;
    }

    function taxRate(uint256 start, uint256 end, uint256 liquidity, address tokenOut, uint256 amountOut) public view returns (uint256)
    {
        uint256 amount = end.sub(start);
        if(amount == 0) return 0;
        uint256 amountOutInGame = amount.sub(taxAmountIn(start, end, liquidity));
        //amountOut = UniswapV2Library.getAmountOut(amountOutInGame, reserveInput, reserveOutput, IUniswapV2Factory(factory).useFee());
        //Get percentage of amountOut we get.
        uint256 amountOutTaxPercentage = taxAmountOut(tokenOut, amountOut).mul(10000).div(amountOut);
        //How much we have in GAME from the second tax.
        uint256 amountOutTaxInGame = amountOutInGame.sub(amountOutInGame.mul(amountOutTaxPercentage).div(10000));
        return amount.sub(amountOutTaxInGame)
        .mul(10000)
        .div(amount);
    }

    //Hooks for DEX.
    //Liquidity is liquidity before the buy.
    function onBuy(uint256 liquidity, uint256 amount, address to, address soldToken, uint256 soldLiquidity, uint256 soldAmount) external nonReentrant returns (uint256[] memory taxOut, uint256[] memory taxIn, address[] memory taxTo)
    {
        require(msg.sender == factory.getPair(address(this), soldToken), "Mismatching pair.");
        //Decrease revenue.
        _decreaseRevenue(amount);
        taxOut = new uint256[](0);
        taxIn = new uint256[](0);
        taxTo = new address[](0);
        if(address(oracle) != address(0))
        {
            try oracle.updateIfPossible() {} catch {}
            if(canTaxOut(soldToken))
            {
                uint256 decimals = claimableTokens[claimableTokenIndex[soldToken].sub(1)].decimals;
                uint256 creditsEarned = oracle.getPrice(soldToken).mul(soldAmount).div((10)**(decimals));
                credits[to] = credits[to].add(creditsEarned);
                totalCredits = totalCredits.add(creditsEarned);
                gameLinkedToCredits[to] = gameLinkedToCredits[to].add(amount);
                emit CreditsGiven(to, creditsEarned);
            }
        }
        sendingFromBuy = true;
        //TODO: Hooks before + after
    }

    function afterBuyTax(uint256 liquidity, uint256 amount, address to, address soldToken, uint256 soldLiquidity, uint256 soldAmount) external
    {
        //Do nothing.
    }

    function creditPercentageOfTotal(address user) public view returns (uint256)
    {
        if(totalCredits == 0) return 0;
        return credits[user].mul(1 ether).div(totalCredits);
    }

    function redeemTaxOutAmounts(address user) public view returns (uint256[] memory)
    {
        uint256 percentageOfTotal = creditPercentageOfTotal(user);
        uint256 len = claimableTokens.length;
        uint256[] memory amounts = new uint256[](len);
        for(uint256 i; i < len; i += 1)
        {
            IERC20Upgradeable token = IERC20Upgradeable(claimableTokens[i].addr);
            amounts[i] = (token.balanceOf(address(this)).mul(percentageOfTotal).div(1 ether));
        }
        return amounts;
    }

    function totalRedeemTaxOutAmounts() external view returns (uint256[] memory)
    {
        uint256 len = claimableTokens.length;
        uint256[] memory amounts = new uint256[](len);
        for(uint256 i; i < len; i += 1)
        {
            IERC20Upgradeable token = IERC20Upgradeable(claimableTokens[i].addr);
            amounts[i] = token.balanceOf(address(this));
        }
        return amounts;
    }

    function redeemTaxOut() nonReentrant external
    {
        require(address(oracle) != address(0), "No oracle, no tax out.");
        require(oracle.getPrice(address(this)) >= taxOutPrice, "Cannot redeem under redeem price.");
        require(credits[msg.sender] > 0, "Not enough credits to redeem.");
        uint256 len = claimableTokens.length;
        bool sentToken = false;
        uint256 percentageOfTotal = creditPercentageOfTotal(msg.sender);
        totalCredits = totalCredits.sub(credits[msg.sender]);
        credits[msg.sender] = 0;
        gameLinkedToCredits[msg.sender] = 0;
        for(uint256 i; i < len; i += 1) //Careful of gas.
        {
            IERC20Upgradeable token = IERC20Upgradeable(claimableTokens[i].addr);
            if(token.balanceOf(address(this)) > 0)
            {
                token.safeTransfer(msg.sender, token.balanceOf(address(this)).mul(percentageOfTotal).div(1 ether));
                sentToken = true;
            }
        }
        require(sentToken, "Nothing to redeem.");
    }

    function _initiate() internal
    {
        if(block.timestamp <= lastInitiateTime) return;
        uint256 amountForHolders = addedBalance.mul(1).div(7); //TODO: Customization
        uint256 amountForLp = addedBalance.mul(2).div(7); //TODO: Customization
        {
            //For holders.
            uint256 amount = amountForHolders;

            //totalGameUnclaimed = totalGameUnclaimed.add(amount);

            //Calculate amount to earn
            // Create & add new snapshot
            uint256 prevRPS = getLatestHolderSnapshot().rewardPerShare;
            uint256 supply = totalSupply().sub(balanceOf(address(this)));
            uint256 len = farms.length;
            for(uint256 i; i < len; i += 1)
            {
                //Do not count rewards (or GAME stuck in that contract for some reason).
                supply = supply.sub(balanceOf(address(farms[i]))); //Single stake GAME not allowed.
            }
            //Nobody earns any GAME if everyone withdraws. If that's the case, all GAME goes to the treasury's daoFund.
            uint256 nextRPS = supply == 0 ? prevRPS : prevRPS.add(amount.mul(1e18).div(supply)); //Otherwise, GAME is distributed amongst those who have not yet burned their MASTER.

            if(supply == 0 && amount > 0)
            {
                _transfer(address(this), treasury, amount);
            }

            Snapshot memory newSnapshot = Snapshot({
            time: block.number,
            rewardReceived: amount,
            rewardPerShare: nextRPS
            });
            holderHistory.push(newSnapshot);
        }
        uint256 len = lpTokens.length;
        if(len > 0)
        {
            uint256 amountEach = amountForLp.div(len);
            amountForLp = amountEach.mul(len); //Reset for rounding errors.
            for(uint256 i; i < len; i += 1)
            {
                //For LP.
                uint256 amount = amountEach;

                //totalGameUnclaimed = totalGameUnclaimed.add(amount);

                //Calculate amount to earn
                // Create & add new snapshot
                uint256 prevRPS = getLatestLpSnapshot(i).rewardPerShare;
                uint256 supply = lpTokens[i].totalSupply();
                //Nobody earns any GAME if everyone withdraws. If that's the case, all GAME goes to the treasury's daoFund.
                uint256 nextRPS = supply == 0 ? prevRPS : prevRPS.add(amount.mul(1e18).div(supply)); //Otherwise, GAME is distributed amongst those who have not yet burned their MASTER.

                if(supply == 0 && amount > 0)
                {
                    _transfer(address(this), treasury, amount);
                }

                Snapshot memory newSnapshot = Snapshot({
                time: block.number,
                rewardReceived: amount,
                rewardPerShare: nextRPS
                });
                lpHistory[i].push(newSnapshot);
            }
        }
        {
            uint256 amountForMaster = addedBalance.sub(amountForLp).sub(amountForHolders);
            //For master.
            uint256 amount = amountForMaster;
            //totalGameUnclaimed = totalGameUnclaimed.add(amount);

            //Calculate amount to earn
            // Create & add new snapshot
            uint256 prevRPS = getLatestMasterSnapshot().rewardPerShare;
            uint256 supply = address(master) != address(0) ? master.totalSupply() : 0;
            //Nobody earns any GAME if everyone withdraws. If that's the case, all GAME goes to the treasury's daoFund.
            uint256 nextRPS = supply == 0 ? prevRPS : prevRPS.add(amount.mul(1e18).div(supply)); //Otherwise, GAME is distributed amongst those who have not yet burned their MASTER.

            if(supply == 0 && amount > 0)
            {
                _transfer(address(this), treasury, amount);
            }

            Snapshot memory newSnapshot = Snapshot({
            time: block.number,
            rewardReceived: amount,
            rewardPerShare: nextRPS
            });
            masterHistory.push(newSnapshot);
        }

        lastInitiateTime = block.timestamp;
        addedBalance = 0;
        //TODO: Hooks before + after
    }

    function initiate() external nonReentrant
    {
        require(block.timestamp > lastInitiateTime, "Already initiated this block.");
        _initiate();
    }

    //Liquidity is liquidity before the sell. Not recommended but can be done: Seller can be determined by tx.origin.
    function onSell(uint256 liquidity, uint256 amount, address to, address boughtToken, uint256 boughtLiquidity, uint256 boughtAmount) external nonReentrant returns (uint256[] memory taxIn, uint256[] memory taxOut, address[] memory taxTo)
    {
        require(msg.sender == factory.getPair(address(this), boughtToken), "Mismatching pair.");
        //Get tax.
        uint256 oldRevenue = revenue;
        //Increase revenue.
        _increaseRevenue(amount);
        //Get tax.
        {
            uint256 taxAmount = taxAmountIn(oldRevenue, revenue, liquidity);
            if(taxAmount == 0) taxAmount = 1; //Avoid tax evasion via dust.
            uint256 toBeDistributed = taxAmount.mul(
            //350
                1000).div(10000); //TODO: Customization
            uint256 toDev = taxAmount.mul(1000).div(10000); //TODO: Customization
            uint256 toTreasury = taxAmount.sub(toBeDistributed).sub(toDev);
            //Send tax to the appropriate places.
            //Could push, but IDE would complain that the return values are not initialized.
            taxIn = new uint256[](3);
            taxIn[0] = toTreasury;
            taxIn[1] = toBeDistributed;
            taxIn[2] = toDev;
        }
        taxOut = new uint256[](3);
        //Could leave blank, but here for clarity
        taxOut[0] = 0;
        taxOut[1] = taxAmountOut(boughtToken, boughtAmount);
        taxOut[2] = 0;
        //Credits are removed already in _beforeTokenTransfer now. Also avoids the use of tx.origin here.
//        if(address(oracle) != address(0))
//        {
//            try oracle.updateIfPossible() {} catch {}
//            if(taxOut[1] > 0)
//            {
//                uint256 decimals = claimableTokens[claimableTokenIndex[boughtToken].sub(1)].decimals;
//                uint256 creditsEarned = oracle.getPrice(boughtToken).mul(boughtAmount).div((10)**(decimals));
//                creditsEarned = MathUpgradeable.min(creditsEarned, credits[tx.origin]);
//                credits[tx.origin] = credits[tx.origin].sub(creditsEarned);
//                totalCredits = totalCredits.sub(creditsEarned);
//                emit CreditsTaken(to, creditsEarned);
//            }
//        }
        taxTo = new address[](3);
        taxTo[0] = treasury;
        taxTo[1] = address(this);
        taxTo[2] = devFund;
        //TODO: Hooks before + after
    }

    function afterSellTax(uint256 liquidity, uint256 amount, address to, address boughtToken, uint256 boughtLiquidity, uint256 boughtAmount) external nonReentrant
    {
        require(msg.sender == factory.getPair(address(this), boughtToken), "Mismatching pair.");
        if(block.timestamp >= lastInitiateTime.add(6 hours)) // gas savings
        {
            _initiate();
        }
    }

    function expectedBuyTax(uint256 liquidity, uint256 amount, address to, address soldToken, uint256 soldLiquidity, uint256 soldAmount) view external returns (uint256 taxOut, uint256 taxIn)
    {
        taxIn = 0;
        taxOut = 0;
    }
    function expectedSellTax(uint256 liquidity, uint256 amount, address to, address boughtToken, uint256 boughtLiquidity, uint256 boughtAmount) view external returns (uint256 taxIn, uint256 taxOut)
    {
        //Get tax.
        uint256 newRevenue = revenue.add(amount);
        uint256 taxAmount = taxAmountIn(revenue, newRevenue, liquidity);
        if(taxAmount == 0) taxAmount = 1;
        taxIn = taxAmount;
        taxOut = taxAmountOut(boughtToken, boughtAmount);
    }

    //Snapshot

    // =========== Snapshot getters

    function latestHolderSnapshotIndex() public view returns (uint256) {
        return holderHistory.length.sub(1);
    }

    function getLatestHolderSnapshot() internal view returns (Snapshot memory) {
        return holderHistory[latestHolderSnapshotIndex()];
    }

    function getLastHolderSnapshotIndexOf(address user) public view returns (uint256) {
        return lastHolderSnapshotIndex[user];
    }

    function getLastHolderSnapshotOf(address user) internal view returns (Snapshot memory) {
        return holderHistory[getLastHolderSnapshotIndexOf(user)];
    }

    function holderEarned(address user) public view returns (uint256) {
        uint256 latestRPS = getLatestHolderSnapshot().rewardPerShare;
        uint256 storedRPS = getLastHolderSnapshotOf(user).rewardPerShare;

        uint256 totalFarmAmount = 0;
        uint256 len = farms.length;
        for(uint256 i; i < len; i += 1)
        {
            IUniswapV2Farm farm = farms[i];
            if(user == address(farm)) return 0; //Redirect to non-farms.
            //Can't add reward balance because:
            //1. Emergency Withdraw makes it so those reward might not be yours anymore
            //2. Rewards aren't included in totalSupply until they are minted.
            //3. It would require a loop (at least the easiest way of doing it), leading to potential gas issues.
            totalFarmAmount = totalFarmAmount.add(farm.depositBalanceOf(address(this), user));
        }
        return balanceOf(user).add(totalFarmAmount).mul(latestRPS.sub(storedRPS)).div(1e18).add(holderRewardEarned[user]);
    }

    function latestLpSnapshotIndex(uint256 i) public view returns (uint256) {
        return lpHistory[i].length.sub(1);
    }

    function getLatestLpSnapshot(uint256 i) internal view returns (Snapshot memory) {
        return lpHistory[i][latestLpSnapshotIndex(i)];
    }

    function getLastLpSnapshotIndexOf(uint256 i, address user) public view returns (uint256) {
        return lastLpSnapshotIndex[i][user];
    }

    function getLastLpSnapshotOf(uint256 i, address user) internal view returns (Snapshot memory) {
        return lpHistory[i][getLastLpSnapshotIndexOf(i, user)];
    }

    function lpEarned(uint256 index, address user) public view returns (uint256) {
        uint256 latestRPS = getLatestLpSnapshot(index).rewardPerShare;
        uint256 storedRPS = getLastLpSnapshotOf(index, user).rewardPerShare;

        uint256 totalFarmAmount = 0;
        uint256 len = farms.length;
        for(uint256 i; i < len; i += 1)
        {
            IUniswapV2Farm farm = farms[i];
            if(user == address(farm)) return 0; //Redirect to non-farms.
            totalFarmAmount = totalFarmAmount.add(farm.depositBalanceOf(address(lpTokens[index]), user));
            //NOTE: MASTER also gets a piece of this pie, technically, in addition to its own pool.
            //MASTER is always staking this, so no need to put in exceptions for MASTER.
        }
        return lpTokens[index].balanceOf(user).add(totalFarmAmount).mul(latestRPS.sub(storedRPS)).div(1e18).add(lpRewardEarned[index][user]);
    }

    function latestMasterSnapshotIndex() public view returns (uint256) {
        return masterHistory.length.sub(1);
    }

    function getLatestMasterSnapshot() internal view returns (Snapshot memory) {
        return masterHistory[latestMasterSnapshotIndex()];
    }

    function getLastMasterSnapshotIndexOf(address user) public view returns (uint256) {
        return lastMasterSnapshotIndex[user];
    }

    function getLastMasterSnapshotOf(address user) internal view returns (Snapshot memory) {
        return masterHistory[getLastMasterSnapshotIndexOf(user)];
    }

    function masterEarned(address user) public view returns (uint256) {
        uint256 latestRPS = getLatestMasterSnapshot().rewardPerShare;
        uint256 storedRPS = getLastMasterSnapshotOf(user).rewardPerShare;

        uint256 totalFarmAmount = 0;
        uint256 len = farms.length;
        for(uint256 i; i < len; i += 1)
        {
            IUniswapV2Farm farm = farms[i];
            if(user == address(farm)) return 0; //Redirect to non-farms.
            totalFarmAmount = totalFarmAmount.add(farm.depositBalanceOf(address(master), user));
        }

        uint256 balance = address(master) != address(0) ?  master.balanceOf(user) : 0;
        return balance.mul(latestRPS.sub(storedRPS)).div(1e18).add(masterRewardEarned[user]);
    }

    //Each token (GAME, LPs, MASTER) MUST call updateReward in _beforeTokenTransfer, else you risk people biting more than they can chew.
    function _updateReward(address user) internal
    {
        holderRewardEarned[user] = holderEarned(user);
        lastHolderSnapshotIndex[user] = latestHolderSnapshotIndex();
        uint256 len = lpTokens.length;
        for(uint256 i; i < len; i += 1)
        {
            lpRewardEarned[i][user] = lpEarned(i, user);
            lastLpSnapshotIndex[i][user] = latestLpSnapshotIndex(i);
        }
        masterRewardEarned[user] = masterEarned(user);
        lastMasterSnapshotIndex[user] = latestMasterSnapshotIndex();
        //TODO: Hooks before + after
    }

    function updateReward(address user) external nonReentrant
    {
        _updateReward(user);
    }

    function totalEarned(address user) public view returns (uint256)
    {
        uint256 reward = holderEarned(user).add(masterEarned(user));
        uint256 len = lpTokens.length;
        for(uint256 i; i < len; i += 1)
        {
            reward = reward.add(lpEarned(i, user));
        }
        return reward;
    }

    function claimReward() nonReentrant public
    {
        _updateReward(msg.sender);
        uint256 reward = holderRewardEarned[msg.sender].add(masterRewardEarned[msg.sender]);
        holderRewardEarned[msg.sender] = 0;
        masterRewardEarned[msg.sender] = 0;
        uint256 len = lpTokens.length;
        for(uint256 i; i < len; i += 1)
        {
            reward = reward.add(lpRewardEarned[i][msg.sender]);
            lpRewardEarned[i][msg.sender] = 0;
        }
        if (reward > 0) {
            //totalGameUnclaimed = totalGameUnclaimed.sub(reward);
            _transfer(address(this), msg.sender, reward);
            if(address(master) != address(0))
            {
                master.onClaimReward(msg.sender, reward);
            }
            emit RewardPaid(msg.sender, reward);
        }
        //TODO: Hooks before + after
    }

    function getPrice() public view returns (uint256 gamePrice) {
        try IOracleV2(oracle).getPrice(address(this)) returns (uint256 price) {
            return price;
        } catch {
            revert("CF"); //GAME: failed to consult GAME price from the oracle
        }
    }

    function getUpdatedPrice() public view returns (uint256 _gamePrice) {
        try IOracleV2(oracle).getUpdatedPrice(address(this)) returns (uint256 price) {
            return price;
        } catch {
            revert("CF"); //GAME: failed to consult GAME price from the oracle
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/ContextUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20BurnableUpgradeable is Initializable, ContextUpgradeable, ERC20Upgradeable {
    function __ERC20Burnable_init() internal initializer {
        __Context_init_unchained();
        __ERC20Burnable_init_unchained();
    }

    function __ERC20Burnable_init_unchained() internal initializer {
    }
    using SafeMathUpgradeable for uint256;

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IOracleV2 {
    function update() external;

    function consult(address _token, uint256 _amountIn) external view returns (uint144 amountOut);

    function twap(address _token, uint256 _amountIn) external view returns (uint144 _amountOut);

    function updateIfPossible() external;

    function getPrice(address _token) external view returns (uint256);
    function getUpdatedPrice(address _token) external view returns (uint256);
}

pragma solidity 0.6.12;
import "./owner/OperatorUpgradeable.sol";

contract AuthorizableUpgradeable is OperatorUpgradeable {
    mapping(address => bool) public authorized;

    function __Authorizable_init() internal initializer {
        __Operator_init();
    }

    function __Authorizable_init_unchained() internal initializer {
    }

    modifier onlyAuthorized() {
        require(authorized[msg.sender] || owner() == msg.sender || operator() == msg.sender, "caller is not authorized");
        _;
    }

    function addAuthorized(address _toAdd) public onlyOwner {
        authorized[_toAdd] = true;
    }

    function removeAuthorized(address _toRemove) public onlyOwner {
        require(_toRemove != msg.sender);
        authorized[_toRemove] = false;
    }
}

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
pragma solidity 0.6.12;
interface IMasterV2 is IERC20Upgradeable {
  function deposit ( uint256 amount, uint256 lockTime ) external;
  function maxLockTime (  ) external view returns ( uint256 );
  function minLockTime (  ) external view returns ( uint256 );
  function onClaimReward ( address to, uint256 reward ) external;
  function penaltyTime (  ) external view returns ( uint256 );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract OperatorUpgradeable is OwnableUpgradeable {
    address private _operator;

    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);

    function __Operator_init() internal initializer {
        __Ownable_init();
        __Operator_init_unchained();
    }

    function __Operator_init_unchained() internal initializer {
        _operator = _msgSender();
        emit OperatorTransferred(address(0), _operator);
    }

    function operator() public view returns (address) {
        return _operator;
    }

    modifier onlyOperator() {
        require(_operator == msg.sender, "operator: caller is not the operator");
        _;
    }

    function isOperator() public view returns (bool) {
        return _msgSender() == _operator;
    }

    function transferOperator(address newOperator_) public onlyOwner { //For the new GAME, we need to change minting privs via owner, not operator.
        _transferOperator(newOperator_);
    }

    function _transferOperator(address newOperator_) internal {
        require(newOperator_ != address(0), "operator: zero address given for new operator");
        emit OperatorTransferred(address(0), newOperator_);
        _operator = newOperator_;
    }
}

pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
//import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "../AuthorizableNoOperatorUpgradeable.sol";
import "../interfaces/IERC20Lockable.sol";
import "../utils/ContractGuard.sol";
import "../interfaces/ITheoryUnlocker.sol";
import "../interfaces/IUniswapV2Router.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IGenerationalERC721.sol";
import "@openzeppelin/contracts-upgradeable/cryptography/ECDSAUpgradeable.sol";
pragma experimental ABIEncoderV2; //https://docs.soliditylang.org/en/v0.6.9/layout-of-source-files.html?highlight=experimental#abiencoderv2

contract VIP is ERC721Upgradeable, AuthorizableNoOperatorUpgradeable, ReentrancyGuardUpgradeable {
    //using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;
    using ECDSAUpgradeable for bytes32;

    //CountersUpgradeable.Counter private _tokenIds;
    address public systemAddress;
    bool public allowRedeem;
    bytes32 public nonce;
    mapping(address => mapping(uint256 => bool)) public redeemed;

    struct TokenInfo
    {
        uint256 generation;
    }

    mapping(uint256 => TokenInfo) public tokenInfo;

    // Events.
    event Mint(address who, uint256 generation, uint256 tokenId);

    //Construction
    function initialize(address _systemAddress, bytes32 _nonce) public initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained("Theory VIP Pass", "TVIP");
        __Ownable_init_unchained();
        __AuthorizableNoOperator_init_unchained();
        __ReentrancyGuard_init_unchained();
        systemAddress = _systemAddress;
        nonce = _nonce;
    }

    //Why isn't this in the standard?
    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function __mint(address player, uint256 gen, uint256 newItemId) internal
    {
        require(newItemId > 0 && newItemId <= 100, "Only 100 passes were ever minted for 1 generation.");
        newItemId = newItemId.add(gen.mul(100)); //Each generation has 100 available NFTs.
        TokenInfo storage token = tokenInfo[newItemId];
        _mint(player, newItemId);
        token.generation = gen;
        string memory tokenURI = "TODO";
        require(bytes(tokenURI).length > 0, "Token URI is invalid.");
        _setTokenURI(newItemId, tokenURI);

        emit Mint(player, gen, newItemId);
    }

    function mint(address player, uint256 gen, uint256 newItemId) nonReentrant onlyAuthorized external {
        __mint(player, gen, newItemId);
    }


    function matchSigner(bytes32 hash, bytes memory signature) public view returns (bool) {
        return systemAddress == hash.toEthSignedMessageHash().recover(signature);
    }

    function hashTransaction(address sender, uint256 gen, uint256[] memory ids) public view returns (bytes32) {

        bytes32 hash = keccak256(
            abi.encodePacked(sender, gen, ids, nonce, address(this))
        );

        return hash;
    }

    function redeem(uint256 gen, uint256[] memory ids, bytes memory signature) external nonReentrant {
        require(allowRedeem, "Redeem locked.");
        require(gen < 2, "Generation not whitelisted.");
        require(!redeemed[msg.sender][gen], "Already redeemed.");
        require(matchSigner(hashTransaction(msg.sender, gen, ids), signature)
        , "Signature does not match.");
        redeemed[msg.sender][gen] = true;
        uint len = ids.length;
        for(uint i; i < len; ++i)
        {
            if(!_exists(ids[i])) __mint(msg.sender, gen, ids[i]);
        }
    }

    function generation(uint256 tokenId) external view returns (uint256)
    {
        return tokenInfo[tokenId].generation;
    }

    function setSystemAddress(address _systemAddress) public onlyAuthorized
    {
        systemAddress = _systemAddress;
        nonce = hex'a842b008c40b4d0c98df9616fad203261915fa13b15980a6536f1cca0504463f';
    }

    function enableRedeem() public onlyAuthorized
    {
        allowRedeem = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/ContextUpgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./IERC721MetadataUpgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "../../introspection/ERC165Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/EnumerableSetUpgradeable.sol";
import "../../utils/EnumerableMapUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable, IERC721EnumerableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.UintToAddressMap;
    using StringsUpgradeable for uint256;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSetUpgradeable.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMapUpgradeable.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || ERC721Upgradeable.isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || ERC721Upgradeable.isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId); // internal owner

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own"); // internal owner
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721ReceiverUpgradeable(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId); // internal owner
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
    uint256[41] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Lockable is IERC20 {
    function lock(address _holder, uint256 _amount) external;
    function lockOf(address account) external view returns (uint256);
    function totalLock() external view returns (uint256);
    function lockTime() external view returns (uint256);
    function totalBalanceOf(address account) external view returns (uint256);
    function canUnlockAmount(address account) external view returns (uint256);
    function unlockForUser(address account, uint256 amount) external;
    function burn(uint256 amount) external;
}

pragma solidity 0.6.12;

contract ContractGuard {
    mapping(uint256 => mapping(address => bool)) private _status;

    function checkSameOriginReentranted() internal view returns (bool) {
        return _status[block.number][tx.origin];
    }

    function checkSameSenderReentranted() internal view returns (bool) {
        return _status[block.number][msg.sender];
    }

    modifier onlyOneBlock() {
        require(!checkSameOriginReentranted(), "ContractGuard: one block, one function");
        require(!checkSameSenderReentranted(), "ContractGuard: one block, one function");

        _;

        _status[block.number][tx.origin] = true;
        _status[block.number][msg.sender] = true;
    }
}

pragma experimental ABIEncoderV2;
interface ITheoryUnlocker {
  struct UserInfo
  {
    uint256 lastUnlockTime;
    uint256 lastLockAmount;
  }
  function addAuthorized ( address _toAdd ) external;
  function approve ( address to, uint256 tokenId ) external;
  function authorized ( address ) external view returns ( bool );
  function balanceOf ( address owner ) external view returns ( uint256 );
  function baseURI (  ) external view returns ( string memory );
  function buyToken (  ) external view returns ( address );
  function buyTokenPerLevel (  ) external view returns ( uint256 );
  function canUnlockAmount ( address player, uint256 tokenId ) external view returns ( uint256 );
  function communityFund (  ) external view returns ( address );
  function costOf ( uint256 level ) external view returns ( uint256 );
  function disableMint (  ) external view returns ( bool );
  function getApproved ( uint256 tokenId ) external view returns ( address );
  function initialPrice (  ) external view returns ( uint256 );
  function isApprovedForAll ( address owner, address operator ) external view returns ( bool );
  function levelURI ( uint256 level ) external view returns ( string memory );
  function levelURIsLevel ( uint256 ) external view returns ( uint256 );
  function levelURIsURI ( uint256 ) external view returns ( string memory );
  function levelUp ( uint256 tokenId ) external;
  function maxLevel (  ) external view returns ( uint256 );
  function maxLevelLevel ( uint256 ) external view returns ( uint256 );
  function maxLevelTime ( uint256 ) external view returns ( uint256 );
  function merge ( uint256 tokenId1, uint256 tokenId2 ) external returns ( uint256 );
  function mint ( uint256 level ) external returns ( uint256 );
  function name (  ) external view returns ( string memory );
  function nextLevelTime ( uint256 tokenId ) external view returns ( uint256 );
  function nftUnlock ( uint256 tokenId ) external;
  function owner (  ) external view returns ( address );
  function ownerOf ( uint256 tokenId ) external view returns ( address );
  function removeAuthorized ( address _toRemove ) external;
  function renounceOwnership (  ) external;
  function safeTransferFrom ( address from, address to, uint256 tokenId ) external;
  function safeTransferFrom ( address from, address to, uint256 tokenId, bytes memory _data ) external;
  function setApprovalForAll ( address operator, bool approved ) external;
  function setBuyToken ( address _buy ) external;
  function setBuyTokenPerLevel ( uint256 _perLevel ) external;
  function setCommunityFund ( address _fund ) external;
  function setCreationTime ( uint256 tokenId, uint256 time ) external;
  function setDisableMint ( bool _disable ) external;
  function setInitialPrice ( uint256 _initial ) external;
  function setLastLevelTime ( uint256 tokenId, uint256 time ) external;
  function setLastLockAmount ( address user, uint256 amount ) external;
  function setLastUnlockTime ( address user, uint256 time ) external;
  function setLevelURIs ( uint256[] memory _levelURIsLevel, string[] memory _levelURIsURI ) external;
  function setMaxLevel ( uint256[] memory _maxLevelTime, uint256[] memory _maxLevelLevel ) external;
  function setTimeToLevel ( uint256 _time ) external;
  function setTokenLevel ( uint256 tokenId, uint256 level ) external;
  function supportsInterface ( bytes4 interfaceId ) external view returns ( bool );
  function symbol (  ) external view returns ( string memory );
  function theory (  ) external view returns ( address );
  function timeLeftToLevel ( uint256 tokenId ) external view returns ( uint256 );
  function timeToLevel (  ) external view returns ( uint256 );
  function tokenByIndex ( uint256 index ) external view returns ( uint256 );
  function tokenInfo ( uint256 ) external view returns ( uint256 level, uint256 creationTime, uint256 lastLevelTime );
  function tokenOfOwnerByIndex ( address owner, uint256 index ) external view returns ( uint256 );
  function tokenURI ( uint256 tokenId ) external view returns ( string memory );
  function totalSupply (  ) external view returns ( uint256 );
  function transferFrom ( address from, address to, uint256 tokenId ) external;
  function transferOwnership ( address newOwner ) external;
  function userInfo ( address ) external view returns ( UserInfo memory );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IUniswapV2Router {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

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

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);

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

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IGenerationalERC721 is IERC721Metadata {
    function generation(uint256 tokenId) view external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC165Upgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMapUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

   /**
    * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        uint256 keyIndex = map._indexes[key];
        if (keyIndex == 0) return (false, 0); // Equivalent to contains(map, key)
        return (true, map._entries[keyIndex - 1]._value); // All indexes are 1-based
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, "EnumerableMap: nonexistent key"); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/cryptography/ECDSAUpgradeable.sol";

interface IUniswapV2Router01 {
    function factory() external pure returns(address);
    function WETH() external pure returns(address);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns(uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns(uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns(uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns(uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns(uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns(uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns(uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns(uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns(uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns(uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns(uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns(uint[] memory amounts);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns(uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns(uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns(uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns(uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns(uint[] memory amounts);
}
interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns(uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns(uint amountETH);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IMaster is IERC20Upgradeable
{
    function masterToTheory(uint256 _share) external view returns (uint256);
}

contract Redeemer is Initializable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using ECDSAUpgradeable for bytes32;

    //Authorizable
    mapping(address => bool) public authorized;

    modifier onlyAuthorized() {
        require(authorized[msg.sender] || owner() == msg.sender, "caller is not authorized");
        _;
    }

    function addAuthorized(address _toAdd) public onlyOwner {
        authorized[_toAdd] = true;
    }

    function removeAuthorized(address _toRemove) public onlyOwner {
        require(_toRemove != msg.sender);
        authorized[_toRemove] = false;
    }

    //ReentrancyGuard
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

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

    //Preservation of values.
    address public systemAddress;
    bool public allowRedeem;
    bytes32 public nonce;
    mapping (address => uint256) public outDeposited; //How much outToken deposited for specific inAddress.
    mapping(address => address) public outToken; //inAddress (FTM) => outToken (AVAX)
    mapping(address => mapping(address => bool)) public redeemedOutToken; //First address is holder, second address is inAddress, bool is whether they redeemed or not.

    function initialize(address _systemAddress, bytes32 _nonce) public initializer {
        __Ownable_init();
        _status = _NOT_ENTERED;
        systemAddress = _systemAddress;
        nonce = _nonce;
    }

    function matchSigner(bytes32 hash, bytes memory signature) public view returns (bool) {
        return systemAddress == hash.toEthSignedMessageHash().recover(signature);
    }

    function hashTransaction(address sender, address inAddress, uint256 multiplier) public view returns (bytes32) {

        bytes32 hash = keccak256(
            abi.encodePacked(sender, inAddress, multiplier, nonce, address(this))
        );

        return hash;
    }

    function redeemableAmount(address inAddress, uint256 multiplier) external view returns (uint256)
    {
        uint256 amount = outDeposited[inAddress].mul(multiplier).div(1e18);
        return amount;
    }

    function redeem(address inAddress, uint256 multiplier, bytes memory signature) external nonReentrant
    {
        require(allowRedeem, "Redeem locked.");
        require(outDeposited[inAddress] > 0, "Token not whitelisted.");
        require(!redeemedOutToken[msg.sender][inAddress], "Token already redeemed.");
        require(matchSigner(hashTransaction(msg.sender, inAddress, multiplier), signature)
        , "Signature does not match.");
        redeemedOutToken[msg.sender][inAddress] = true;
        uint256 amount = outDeposited[inAddress].mul(multiplier).div(1e18);
        IERC20Upgradeable out = IERC20Upgradeable(outToken[inAddress]);
        out.safeTransfer(msg.sender, amount);
    }

    function setSystemAddress(address _systemAddress) external onlyAuthorized
    {
        systemAddress = _systemAddress;
    }

    function enableRedeem() external onlyAuthorized
    {
        allowRedeem = true;
    }

    function deposit(address inAddress, IERC20Upgradeable out, uint256 amount) external onlyAuthorized nonReentrant
    {
       require(!allowRedeem, "Deposit locked.");
       require(outToken[inAddress] == address(out) || outToken[inAddress] == address(0), "Cannot change out token once set.");
       outToken[inAddress] = address(out);
       outDeposited[inAddress] = outDeposited[inAddress].add(amount); //No transferFrom tax tokens allowed.
       out.safeTransferFrom(msg.sender, address(this), amount);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/cryptography/ECDSAUpgradeable.sol";

interface IUniswapV2Router01 {
    function factory() external pure returns(address);
    function WETH() external pure returns(address);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns(uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns(uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns(uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns(uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns(uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns(uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns(uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns(uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns(uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns(uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns(uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns(uint[] memory amounts);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns(uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns(uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns(uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns(uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns(uint[] memory amounts);
}
interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns(uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns(uint amountETH);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IMaster is IERC20Upgradeable
{
    function masterToTheory(uint256 _share) external view returns (uint256);
}

contract Migrator is Initializable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using ECDSAUpgradeable for bytes32;

    //Authorizable
    mapping(address => bool) public authorized;

    modifier onlyAuthorized() {
        require(authorized[msg.sender] || owner() == msg.sender, "caller is not authorized");
        _;
    }

    function addAuthorized(address _toAdd) public onlyOwner {
        authorized[_toAdd] = true;
    }

    function removeAuthorized(address _toRemove) public onlyOwner {
        require(_toRemove != msg.sender);
        authorized[_toRemove] = false;
    }

    //ReentrancyGuard
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

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

    //Preservation of values.
    mapping(address => uint256) public nonce;
    mapping(address => mapping (address => uint256)) public balanceOf;
    mapping (address => uint256) public total;
    mapping(address => bool) public tokenWhitelist;
    address public systemAddress;
    //Upgrade 1
    uint256 public theoryToGame;
    mapping (address => uint256) public gameToMint;
    IERC20Upgradeable game;
    IERC20Upgradeable theory;
    IERC20Upgradeable dai;
    IERC20Upgradeable hodl;
    IMaster master;
    IERC20Upgradeable gameDai;
    IERC20Upgradeable theoryDai;
    bool lockMigration;

    function initialize(address _systemAddress, address[] memory whitelist) public initializer {
        __Ownable_init();
        _status = _NOT_ENTERED;
        systemAddress = _systemAddress;
        uint256 len = whitelist.length;
        for(uint i = 0; i < len; i += 1)
        {
            tokenWhitelist[whitelist[i]] = true;
        }
    }

    function matchSigner(bytes32 hash, bytes memory signature) public view returns (bool) {
        return systemAddress == hash.toEthSignedMessageHash().recover(signature);
    }

    function hashTransaction(address sender, address token, uint256 amount) public view returns (bytes32) {

        bytes32 hash = keccak256(
            abi.encodePacked(sender, token, amount, nonce[sender], address(this))
        );

        return hash;
    }

    function transfer(IERC20Upgradeable token, uint256 amount, bytes memory signature) public nonReentrant
    {
        require(!lockMigration, "Migration locked.");
        require(tokenWhitelist[address(token)], "Token not whitelisted.");
        require(matchSigner(hashTransaction(msg.sender, address(token), amount), signature)
        //This also checks nonce, must be exactly equal to our next expected nonce, not greater or lesser.
        , "Signature does not match.");
        nonce[msg.sender] = nonce[msg.sender].add(1);
        //None of the whitelisted tokens have any sales tax, so this should be safe.
        balanceOf[msg.sender][address(token)] = balanceOf[msg.sender][address(token)].add(amount);
        total[address(token)] = total[address(token)].add(amount);
        token.safeTransferFrom(msg.sender, address(this), amount); //Will handle insufficient funds and lack of approval.
        //We already have all possible addresses from the snapshot, so we don't need to keep track of that with events (plus we can use the Transfer event anyways).
    }

    function setSystemAddress(address _systemAddress) public onlyAuthorized
    {
        systemAddress = _systemAddress;
    }

    function setTokenWhitelist(address token, bool whitelist) public onlyAuthorized
    {
        tokenWhitelist[token] = whitelist;
    }

    function setLockMigration(bool lock) public onlyAuthorized
    {
        lockMigration = lock;
    }

    function setTokens(IERC20Upgradeable _game,
IERC20Upgradeable _theory,
IERC20Upgradeable _dai,
IERC20Upgradeable _hodl,
IMaster _master,
IERC20Upgradeable _gameDai,
IERC20Upgradeable _theoryDai) public onlyAuthorized
    {
        game = _game;
        theory = _theory;
        dai = _dai;
        hodl = _hodl;
        master = _master;
        gameDai = _gameDai;
        theoryDai = _theoryDai;
    }

    event Migrate(uint256 gameForGameDai, uint256 daiForGameDai, uint256 theoryForTheoryDai, uint256 daiForTheoryDai,
uint256 gameToDai,
uint256 theoryToDai);
    function migrate(IUniswapV2Router02 router) public onlyAuthorized
    {
        require(address(game) != address(0), "Forgot to set tokens?");
        lockMigration = true;
        //Break LP
        uint256 gameForGameDai;
        uint256 daiForGameDai;
        uint256 theoryForTheoryDai;
        uint256 daiForTheoryDai;
        {
            uint256 gameBefore = game.balanceOf(address(this));
            uint256 daiBefore = dai.balanceOf(address(this));
            gameDai.safeApprove(address(router), 0);
            gameDai.safeApprove(address(router), total[address(gameDai)]);
            router.removeLiquidity(address(game), address(dai), total[address(gameDai)],
            0,
            0,
            address(this),
            block.timestamp);
            gameForGameDai = game.balanceOf(address(this)).sub(gameBefore);
            daiForGameDai = dai.balanceOf(address(this)).sub(daiBefore);
        }
        {
            uint256 theoryBefore = theory.balanceOf(address(this));
            uint256 daiBefore = dai.balanceOf(address(this));
            theoryDai.safeApprove(address(router), 0);
            theoryDai.safeApprove(address(router), total[address(theoryDai)]);
            router.removeLiquidity(address(theory), address(dai), total[address(theoryDai)],
                0,
                0,
                address(this),
                block.timestamp);
            theoryForTheoryDai = theory.balanceOf(address(this)).sub(theoryBefore);
            daiForTheoryDai = dai.balanceOf(address(this)).sub(daiBefore);
        }
        //Calculate THEORY to GAME rate using DAI rates.
        uint256 gameToDai = daiForGameDai.mul(1e18).div(gameForGameDai);
        uint256 theoryToDai = daiForTheoryDai.mul(1e18).div(theoryForTheoryDai);
        theoryToGame = theoryToDai.mul(1e18).div(gameToDai);
        //Calculate GAME to mint for GAME (1 to 1)
        gameToMint[address(game)] = total[address(game)];
        //Calculate GAME to mint for THEORY (THEORY to GAME rate).
        gameToMint[address(theory)] = total[address(theory)].mul(theoryToGame).div(1e18);
        //Calculate GAME to mint for HODL (1 to 1.1).
        gameToMint[address(hodl)] = total[address(hodl)].mul(11).div(10);
        //Calculate GAME to mint for MASTER (MASTER in THEORY * THEORY to GAME rate * 2).
        gameToMint[address(master)] = master.masterToTheory(total[address(master)]).mul(theoryToGame).mul(2).div(1e18);
        //Calculate GAME to mint for GAME-USDC LP on GAME side (1 to 1).
        gameToMint[address(gameDai)] = gameForGameDai;
        //Calculate GAME to mint for GAME-USDC LP on THEORY side (THEORY to GAME rate).
        gameToMint[address(theoryDai)] = theoryForTheoryDai.mul(theoryToGame).div(1e18);
        //Send all DAI to deployer for setup.
        dai.transfer(owner(), dai.balanceOf(address(this)));
        emit Migrate(gameForGameDai,
            daiForGameDai,
            theoryForTheoryDai,
            daiForTheoryDai, gameToDai,
            theoryToDai); //Log useful items that we don't save here.
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "../../interfaces/IERC20Lockable.sol";
import "../../interfaces/ITreasury.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";

contract RPG is Initializable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    //Authorizable
    mapping(address => bool) public authorized;

    modifier onlyAuthorized() {
        require(authorized[msg.sender] || owner() == msg.sender, "caller is not authorized");
        _;
    }

    function addAuthorized(address _toAdd) public onlyOwner {
        authorized[_toAdd] = true;
    }

    function removeAuthorized(address _toRemove) public onlyOwner {
        require(_toRemove != msg.sender);
        authorized[_toRemove] = false;
    }

    //Preservation of values.
    mapping(address => uint256) public gasInAccount;
    address public gameOperator;
    modifier onlyGameOperator() {
        require(gameOperator == msg.sender, "only game operator");
        _;
    }

    function initialize(address _gameOperator) public initializer {
        __Ownable_init();
        gameOperator = _gameOperator;
    }

    receive() external payable {
        gasInAccount[msg.sender] = gasInAccount[msg.sender].add(msg.value);
        payable(gameOperator).transfer(msg.value);
    }

    //Make sure this returns true before calling any onlyGameOperator functions on behalf of a player.
    //If it returns false, send the user a message that calls Metamask and transfers enough FTM.
    //Then, on transaction complete, send another request to try again.
    function hasEnoughGas(address account, uint256 estimatedCost) public view returns(bool)
    {
        //Check this function on the client's side first for speed and bandwidth reasons.
        return gasInAccount[account] >= estimatedCost;
    }
    //Players can also top up by sending to this contract directly.
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IERC20Reward.sol";
import "../../../Authorizable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../../interfaces/IGenerationalERC721.sol";
import "../interfaces/IUniswapV2Pair.sol";

// MasterChef is the master of Game.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once GAME is sufficiently
// distributed and the community can show to govern itself.
///////////////////////////////////
contract MasterChef is Authorizable,
ReentrancyGuard //Decided to implement both Checks-Effects-Interactions and ReentrancyGuard, just in case I missed something in one, it probably would be covered by the other.
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    mapping(address => uint256[]) nftRate; //Rates for each generation.
    //Generation is not checked if array is length 1 or 0. If 0, it defaults to 0% bonus.
    //Max bonus is 1000%. Anything more than that is probably an input error.
    struct NftInfo {
        address addr;
        uint256 id;
    }
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user + someone else on behalf of the user has provided.
        uint256 lockedAmount; // How many LP tokens someone else has provided for the user. User cannot withdraw this, only the gifter can.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of GAMEs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accGamePerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accGamePerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
        mapping(address => uint256) amountOnBehalfOf; // How many LP tokens this user has provided for someone else.
        NftInfo nft;
    }
    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 totalDeposited; // Just in case someone sends in tokens to this contract without depositing.
        uint256 allocPoint; // How many allocation points assigned to this pool. GAMEs to distribute per block.
        uint256 lastRewardTime; // Last time that GAMEs distribution occurs.
        uint256 accGamePerShare; // Accumulated GAMEs per share, times 1e18. See below.
    }
    // The GAME TOKEN!
    IERC20UniswapReward public game;
    // Dev address (fund).
    address public devaddr;
    // Time when bonus GAME period ends.
    uint256 public bonusEndTime;
    // GAME tokens created per second.
    uint256 public gamePerSecond;
    // Bonus muliplier for early game makers.
    uint256 public constant BONUS_MULTIPLIER = 1; //No bonus due to migration, but not removing it as the more things changed, the more vulnerabilities possible.
    // Info of each pool.
    PoolInfo[] public poolInfo;
    mapping(address => uint256) public poolNumber;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The start time when GAME mining starts.
    uint256 public startTime;
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event DepositNft(address indexed user, uint256 indexed pid, address nft, uint256 id);
    event WithdrawNft(address indexed user, uint256 indexed pid, address nft, uint256 id);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount,
        address nft,
        uint256 id
    );
    event DepositOnBehalfOf(address indexed user, address indexed giftee, uint256 indexed pid, uint256 amount);
    event WithdrawOnBehalfOf(address indexed user, address indexed giftee, uint256 indexed pid, uint256 amount);
    event EmergencyWithdrawOnBehalfOf(
        address indexed user,
        address indexed giftee,
        uint256 indexed pid,
        uint256 amount
    );

    constructor(
        IERC20UniswapReward _game,
        uint256 _gamePerSecond,
        uint256 _startTime,
        uint256 _bonusEndTime
    ) public {
        game = _game;
        devaddr = msg.sender;
        gamePerSecond = _gamePerSecond;
        bonusEndTime = _bonusEndTime;
        if(_startTime == 0) startTime = block.timestamp;
        else startTime = _startTime;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate
    ) external onlyOwner {
        require(address(_lpToken) != address(game), "NO SINGLE STAKE GAME ALLOWED."); //CANNOT ADD SINGLE STAKE GAME due to certain reward limitations
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardTime =
        block.timestamp > startTime ? block.timestamp : startTime;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
        lpToken: _lpToken,
        totalDeposited: 0,
        allocPoint: _allocPoint,
        lastRewardTime: lastRewardTime,
        accGamePerShare: 0
        })
        );
        poolNumber[address(_lpToken)] = poolInfo.length;
    }

    // Update the given pool's GAME allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) external onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    function setNftRate(address _nft, uint256[] memory _nftRate) external onlyOwner
    {
        nftRate[_nft] = _nftRate;
    }

    // Return reward multiplier over the given _from to _to time.
    function getMultiplier(uint256 _from, uint256 _to)
    public
    view
    returns (uint256)
    {
        if (_to <= bonusEndTime) {
            return _to.sub(_from).mul(BONUS_MULTIPLIER);
        } else if (_from >= bonusEndTime) {
            return _to.sub(_from);
        } else {
            return
            bonusEndTime.sub(_from).mul(BONUS_MULTIPLIER).add(
                _to.sub(bonusEndTime)
            );
        }
    }

    // View function to see pending GAMEs on frontend.
    function pendingGame(uint256 _pid, address _user)
    external
    view
    returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accGamePerShare = pool.accGamePerShare;
        uint256 lpSupply = pool.totalDeposited;
        if (block.timestamp > pool.lastRewardTime && lpSupply != 0 && totalAllocPoint > 0) {
            uint256 multiplier =
            getMultiplier(pool.lastRewardTime, block.timestamp);
            uint256 gameReward =
            multiplier.mul(gamePerSecond).mul(pool.allocPoint).div(
                totalAllocPoint
            );
            accGamePerShare = accGamePerShare.add(
                gameReward.mul(1e18).div(lpSupply)
            );
        }
        uint256 pending = user.amount.mul(accGamePerShare).div(1e18).sub(user.rewardDebt);
        if(user.nft.addr != address(0))
        {
            uint256 len = nftRate[user.nft.addr].length;
            uint256 rate = 0;
            if (len > 1) rate = nftRate[user.nft.addr][IGenerationalERC721(user.nft.addr).generation(user.nft.id)];
            else if (len > 0) rate = nftRate[user.nft.addr][0];
            if(rate > 0) pending = pending.add(pending.mul(rate).div(10000)); //Bonus mint for NFTs. NFTs are attached to each pool (for security/gas reasons), so multiple NFTs means you can boost multiple farms.
        }
        return pending;
    }

    function depositBalanceOf(address token, address user) view external returns (uint256)
    {
        if(poolNumber[token] == 0) return 0;
        uint256 pid = poolNumber[token].sub(1);
        UserInfo storage user = userInfo[pid][user];
        return user.amount;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }
        uint256 lpSupply = pool.totalDeposited;
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardTime, block.timestamp);
        uint256 gameReward =
        multiplier.mul(gamePerSecond).mul(pool.allocPoint).div(
            totalAllocPoint
        );
        pool.accGamePerShare = pool.accGamePerShare.add(
            gameReward.mul(1e18).div(lpSupply)
        );
        pool.lastRewardTime = block.timestamp;
        //Vulnerable to reentrancy in deposit/withdraw/etc., but we will always control this contract. The mint function will never make any external calls.
        game.mint(game.treasury(), gameReward.mul(2).div(3)); //Minted to treasury: Back to the project.
        game.mint(devaddr, gameReward.mul(2).div(3)); //Minted to dev address: The team.
        game.mint(address(this), gameReward); //This all leads to a split of 60/20/20 in the span of 1 year, where 60% of total supply comes from the migration + farms, 20% goes to treasury, and 20% goes to team.
    }

    //Note that this function does NOT change user.amount or update the reward debt, the caller must do that themselves.
    function claimGame(UserInfo memory user, PoolInfo memory pool) internal
    {
        uint256 pending =
        user.amount.mul(pool.accGamePerShare).div(1e18).sub(
            user.rewardDebt
        );
        if(pending > 0)
        {
            if(user.nft.addr != address(0))
            {
                uint256 len = nftRate[user.nft.addr].length;
                uint256 rate = 0;
                if (len > 1) rate = nftRate[user.nft.addr][IGenerationalERC721(user.nft.addr).generation(user.nft.id)];
                else if (len > 0) rate = nftRate[user.nft.addr][0];
                if(rate > 0) game.mint(msg.sender, pending.mul(rate).div(10000)); //Bonus mint for NFTs. NFTs are attached to each pool (for security/gas reasons), so multiple NFTs means you can boost multiple farms.
            }
            safeGameTransfer(msg.sender, pending); //GAME transfer doesn't call anything external, so should be safe from reentrancy.
        }
    }

    // Deposit LP tokens to MasterChef for GAME allocation.
    function deposit(uint256 _pid, uint256 _amount) nonReentrant public {
        UserInfo storage user = userInfo[_pid][msg.sender];
        PoolInfo storage pool = poolInfo[_pid];
        updatePool(_pid);
        claimGame(user, pool);
        user.amount = user.amount.add(_amount);
        pool.totalDeposited = pool.totalDeposited.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accGamePerShare).div(1e18);
        //NOTE: Tokens with transfer tax are NOT supported. Only put LP here.
        if(_amount > 0) pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        emit Deposit(msg.sender, _pid, _amount);
    }

    function depositWithPermit(uint256 _pid, uint256 _amount,
        uint256 deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external {
        PoolInfo storage pool = poolInfo[_pid];
        uint value = approveMax ? uint(-1) : _amount;
        IUniswapV2Pair(address(pool.lpToken)).permit(msg.sender, address(this), value, deadline, v, r, s);
        deposit(_pid, _amount);
    }

    function depositOnBehalfOf(address giftee, uint256 _pid, uint256 _amount) nonReentrant onlyAuthorized public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][giftee];
        UserInfo storage gifter = userInfo[_pid][msg.sender];
        updatePool(_pid);
        claimGame(user, pool);
        user.amount = user.amount.add(_amount);
        pool.totalDeposited = pool.totalDeposited.add(_amount);
        user.lockedAmount = user.lockedAmount.add(_amount);
        gifter.amountOnBehalfOf[giftee] = gifter.amountOnBehalfOf[giftee].add(_amount);
        user.rewardDebt = user.amount.mul(pool.accGamePerShare).div(1e18);
        //NOTE: Tokens with transfer tax are NOT supported. Only put LP here.
        if(_amount > 0) pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        emit DepositOnBehalfOf(msg.sender, giftee, _pid, _amount);
    }

    function depositOnBehalfOfWithPermit(address giftee, uint256 _pid, uint256 _amount,
        uint256 deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) onlyAuthorized external {
        PoolInfo storage pool = poolInfo[_pid];
        uint value = approveMax ? uint(-1) : _amount;
        IUniswapV2Pair(address(pool.lpToken)).permit(msg.sender, address(this), value, deadline, v, r, s);
        depositOnBehalfOf(giftee, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) nonReentrant external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount.sub(user.lockedAmount) >= _amount, "withdraw: not good");
        updatePool(_pid);
        claimGame(user, pool);
        user.amount = user.amount.sub(_amount);
        pool.totalDeposited = pool.totalDeposited.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accGamePerShare).div(1e18);
        if(_amount > 0) pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function withdrawOnBehalfOf(address giftee, uint256 _pid, uint256 _amount) onlyAuthorized nonReentrant external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][giftee];
        UserInfo storage gifter = userInfo[_pid][msg.sender];
        require(gifter.amountOnBehalfOf[giftee] >= _amount, "withdraw: not good");
        updatePool(_pid);
        claimGame(user, pool);
        user.amount = user.amount.sub(_amount);
        user.lockedAmount = user.lockedAmount.sub(_amount);
        pool.totalDeposited = pool.totalDeposited.sub(_amount);
        gifter.amountOnBehalfOf[giftee] = gifter.amountOnBehalfOf[giftee].sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accGamePerShare).div(1e18);
        if(_amount > 0) pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) nonReentrant external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 emergencyAmount = user.amount.sub(user.lockedAmount);
        user.amount = user.amount.sub(emergencyAmount);
        pool.totalDeposited = pool.totalDeposited.sub(emergencyAmount);
        user.rewardDebt = user.amount.mul(pool.accGamePerShare).div(1e18);
        pool.lpToken.safeTransfer(address(msg.sender), emergencyAmount);
        IERC721 nft = IERC721(user.nft.addr);
        uint256 id = user.nft.id;
        user.nft.addr = address(0);
        user.nft.id = 0;
        //user.nft.bonus = 0;
        if(address(nft) != address(0)) nft.transferFrom(address(this), msg.sender, id);
        emit EmergencyWithdraw(msg.sender, _pid, emergencyAmount, address(nft), id);
    }

    function emergencyWithdrawOnBehalfOf(address giftee, uint256 _pid) nonReentrant onlyAuthorized external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][giftee];
        UserInfo storage gifter = userInfo[_pid][msg.sender];
        user.amount = user.amount.sub(gifter.amountOnBehalfOf[giftee]);
        pool.totalDeposited = pool.totalDeposited.sub(gifter.amountOnBehalfOf[giftee]);
        user.lockedAmount = user.lockedAmount.sub(gifter.amountOnBehalfOf[giftee]);
        gifter.amountOnBehalfOf[giftee] = 0;
        user.rewardDebt = user.amount.mul(pool.accGamePerShare).div(1e18);
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdrawOnBehalfOf(msg.sender, giftee, _pid, user.amount);
    }

    function depositNft(uint256 _pid, IERC721 nft, uint256 id) nonReentrant external {
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.nft.addr == address(0), "Cannot deposit more than 1 NFT in a single pool.");
        PoolInfo storage pool = poolInfo[_pid];
        updatePool(_pid);
        claimGame(user, pool);
        //user.amount = user.amount;
        user.rewardDebt = user.amount.mul(pool.accGamePerShare).div(1e18);
        user.nft.addr = address(nft);
        user.nft.id = id;
//        uint256 rate = 0;
//        uint256 len = nftRate.length;
        //Maybe it's best to keep the bonus untracked until checked. That way we can update the bonus if necessary.
//        if (len > 1) rate = nftRate[IGenerationalERC721(nft).generation];
//        else if (len > 0) rate = nftRate[0];
//        user.nft.bonus = rate;
        nft.transferFrom(msg.sender, address(this), id);
        emit DepositNft(msg.sender, _pid, address(nft), id);
    }

    function withdrawNft(uint256 _pid) nonReentrant external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.nft.addr != address(0), "Cannot withdraw an NFT without an NFT deposited.");
        updatePool(_pid);
        claimGame(user, pool);
        //user.amount = user.amount;
        user.rewardDebt = user.amount.mul(pool.accGamePerShare).div(1e18);
        IERC721 nft = IERC721(user.nft.addr);
        uint256 id = user.nft.id;
        user.nft.addr = address(0);
        user.nft.id = 0;
        //user.nft.bonus = 0;
        nft.transferFrom(address(this), msg.sender, id);
        emit WithdrawNft(msg.sender, _pid, address(nft), id);
    }

    // Safe game transfer function, just in case if rounding error causes pool to not have enough GAMEs.
    function safeGameTransfer(address _to, uint256 _amount) internal {
        uint256 gameBal = game.balanceOf(address(this));
        if (_amount > gameBal) {
            game.transfer(_to, gameBal);
        } else {
            game.transfer(_to, _amount);
        }
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) onlyOwner external {
        devaddr = _devaddr;
    }

    function getGamePerSecondInPool(uint256 _pid, address _user) public view returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 multiplier =
        getMultiplier(block.timestamp-1, block.timestamp);
        uint256 _poolGamePerSecond = multiplier.mul(gamePerSecond).mul(pool.allocPoint).div(
            totalAllocPoint
        );
        if(user.nft.addr != address(0)) //If everyone had this NFT, this would be the rate.
        {
            uint256 len = nftRate[user.nft.addr].length;
            uint256 rate = 0;
            if (len > 1) rate = nftRate[user.nft.addr][IGenerationalERC721(user.nft.addr).generation(user.nft.id)];
            else if (len > 0) rate = nftRate[user.nft.addr][0];
            if(rate > 0) return _poolGamePerSecond.add(_poolGamePerSecond.mul(rate).div(10000)); //Bonus mint for NFTs. NFTs are attached to each pool (for security/gas reasons), so multiple NFTs means you can boost multiple farms.
        }
        return _poolGamePerSecond;
    }

    function getPersonalGamePerSecondInPool(uint256 _pid, address _user) public view returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        if(user.amount == 0) return 0;
        uint256 multiplier =
        getMultiplier(block.timestamp-1, block.timestamp);
        uint256 _poolGamePerSecond = multiplier.mul(gamePerSecond).mul(pool.allocPoint).div(
            totalAllocPoint
        );
        uint256 lpSupply = pool.totalDeposited; //Shouldn't be 0 if amount isn't 0/
        uint256 gamePerShare = _poolGamePerSecond.mul(1e18).div(lpSupply);
        _poolGamePerSecond = user.amount.mul(gamePerShare).div(1e18);
        if(user.nft.addr != address(0))
        {
            uint256 len = nftRate[user.nft.addr].length;
            uint256 rate = 0;
            if (len > 1) rate = nftRate[user.nft.addr][IGenerationalERC721(user.nft.addr).generation(user.nft.id)];
            else if (len > 0) rate = nftRate[user.nft.addr][0];
            if(rate > 0) return _poolGamePerSecond.add(_poolGamePerSecond.mul(rate).div(10000)); //Bonus mint for NFTs. NFTs are attached to each pool (for security/gas reasons), so multiple NFTs means you can boost multiple farms.
        }
        return _poolGamePerSecond;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

import "../lib/Babylonian.sol";
import "../lib/FixedPoint.sol";
import "./dex/libraries/UniswapV2OracleLibraryV2.sol";
import "./EpochV2.sol";
import "./dex/interfaces/IUniswapV2Pair.sol";

// fixed window oracle that recomputes the average price for the entire period once every period
// note that the price average is only guaranteed to be over at least 1 period, but may be over a longer period
contract OracleV2 is EpochV2 {
    using FixedPoint for *;
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    // uniswap
    address public token0;
    address public token1;
    IUniswapV2Pair public gameUsdc;
    address public game;
    address public usdc;
    mapping(address => AggregatorV3Interface) chainLinkProxy;

    // oracle
    uint32 public blockTimestampLast;
    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    FixedPoint.uq112x112 public price0Average;
    FixedPoint.uq112x112 public price1Average;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        IUniswapV2Pair _gameUsdc,
        address _game,
        uint256 _period,
        uint256 _startTime
    ) public EpochV2(_period == 0 ? 6 hours : _period, _startTime, 0) {
        gameUsdc = _gameUsdc;
        game = _game;
        token0 = gameUsdc.token0();
        token1 = gameUsdc.token1();
        usdc = token0 == _game ? token1 : token0;
        price0CumulativeLast = gameUsdc.price0CumulativeLast(); // fetch the current accumulated price value (1 / 0)
        price1CumulativeLast = gameUsdc.price1CumulativeLast(); // fetch the current accumulated price value (0 / 1)
        uint112 reserve0;
        uint112 reserve1;
        (reserve0, reserve1, blockTimestampLast) = gameUsdc.getReserves();
        require(reserve0 != 0 && reserve1 != 0, "Oracle: NO_RESERVES"); // ensure that there's liquidity in the gameUsdc
    }

    /* ========== MUTABLE FUNCTIONS ========== */

    /** @dev Updates 1-day EMA price from Uniswap.  */
    function update() public checkEpoch {
        (uint256 price0Cumulative, uint256 price1Cumulative,,, uint32 blockTimestamp) = UniswapV2OracleLibraryV2.currentCumulativePrices(address(gameUsdc));
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired

        if (timeElapsed == 0) {
            // prevent divided by zero
            return;
        }

        // overflow is desired, casting never truncates
        // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
        price0Average = FixedPoint.uq112x112(uint224((price0Cumulative - price0CumulativeLast) / timeElapsed));
        price1Average = FixedPoint.uq112x112(uint224((price1Cumulative - price1CumulativeLast) / timeElapsed));

        price0CumulativeLast = price0Cumulative;
        price1CumulativeLast = price1Cumulative;
        blockTimestampLast = blockTimestamp;

        emit Updated(price0Cumulative, price1Cumulative);
    }

    // note this will always return 0 before update has been called successfully for the first time.
    function consult(address _token, uint256 _amountIn) public view returns (uint144 amountOut) {
        if (_token == token0) {
            amountOut = price0Average.mul(_amountIn).decode144();
        } else {
            require(_token == token1, "Oracle: INVALID_TOKEN");
            amountOut = price1Average.mul(_amountIn).decode144();
        }
    }

    function twap(address _token, uint256 _amountIn) public view returns (uint144 _amountOut) {
        (uint256 price0Cumulative, uint256 price1Cumulative, uint256 currentPrice0, uint256 currentPrice1, uint32 blockTimestamp) = UniswapV2OracleLibraryV2.currentCumulativePrices(address(gameUsdc));
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed == 0) {
            // prevent divided by zero
            //_amountOut = consult(_token, _amountIn);
            if (_token == token0) {
                _amountOut = FixedPoint.uq112x112(uint224(currentPrice0)).mul(_amountIn).decode144();
            } else if (_token == token1) {
                _amountOut = FixedPoint.uq112x112(uint224(currentPrice1)).mul(_amountIn).decode144();
            }
            else {
                revert("Oracle: INVALID_TOKEN");
            }
        }
        else
        {
            if (_token == token0) {
                _amountOut = FixedPoint.uq112x112(uint224((price0Cumulative - price0CumulativeLast) / timeElapsed)).mul(_amountIn).decode144();
            } else if (_token == token1) {
                _amountOut = FixedPoint.uq112x112(uint224((price1Cumulative - price1CumulativeLast) / timeElapsed)).mul(_amountIn).decode144();
            }
            else {
                revert("Oracle: INVALID_TOKEN");
            }
        }
    }

    function updateIfPossible() external
    {
        if(canUpdateEpoch()) update();
    }

    function getPrice(address token) public view returns (uint256) //Price is always in 18 decimals
    {
        //Twap is in 6 decimals due to USDC, so we have to convert it.
        if(token == game)
                   //Decimals: 6       //Decimals: 18      //Get rid of the 6 extra decimals.
            return uint256(consult(game, 1 ether)).mul(getPrice(usdc)).div(1e6);
        (
        /*uint80 roundID*/,
        int price,
        /*uint startedAt*/,
        /*uint timeStamp*/,
        /*uint80 answeredInRound*/
        ) = chainLinkProxy[token].latestRoundData();
        require(price > 0, "Invalid price. Please try again later.");
        uint256 decimals = chainLinkProxy[token].decimals();
        require(decimals < 78, "Invalid decimals."); //Making sure we don't overflow. A value of 78+ overflows.
        return uint256(price).mul(1 ether).div((10)**(decimals)); //decimals shouldn't overflow
    }

    function getUpdatedPrice(address token) public view returns (uint256) //Price is always in 18 decimals
    {
        //Twap is in 6 decimals due to USDC, so we have to convert it.
        if(token == game)
        //Decimals: 6       //Decimals: 18      //Get rid of the 6 extra decimals.
            return uint256(twap(game, 1 ether)).mul(getPrice(usdc)).div(1e6);
        (
        /*uint80 roundID*/,
        int price,
        /*uint startedAt*/,
        /*uint timeStamp*/,
        /*uint80 answeredInRound*/
        ) = chainLinkProxy[token].latestRoundData();
        require(price > 0, "Invalid price. Please try again later.");
        uint256 decimals = chainLinkProxy[token].decimals();
        require(decimals < 78, "Invalid decimals."); //Making sure we don't overflow. A value of 78+ overflows.
        return uint256(price).mul(1 ether).div((10)**(decimals)); //decimals shouldn't overflow
    }

    function setChainLinkProxy(address token, AggregatorV3Interface proxy) external onlyOperator {
        chainLinkProxy[token] = proxy;
    }

    event Updated(uint256 price0CumulativeLast, uint256 price1CumulativeLast);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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

pragma solidity ^0.6.0;

library Babylonian {
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }
}

pragma solidity ^0.6.0;

import "./Babylonian.sol";

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint256 _x;
    }

    uint8 private constant RESOLUTION = 112;
    uint256 private constant Q112 = uint256(1) << RESOLUTION;
    uint256 private constant Q224 = Q112 << RESOLUTION;

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function div(uq112x112 memory self, uint112 x) internal pure returns (uq112x112 memory) {
        require(x != 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112(self._x / uint224(x));
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint256 y) internal pure returns (uq144x112 memory) {
        uint256 z;
        require(y == 0 || (z = uint256(self._x) * y) / y == uint256(self._x), "FixedPoint: MULTIPLICATION_OVERFLOW");
        return uq144x112(z);
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // equivalent to encode(numerator).div(denominator)
    function fraction(uint112 numerator, uint112 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112((uint224(numerator) << RESOLUTION) / denominator);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }

    // take the reciprocal of a UQ112x112
    function reciprocal(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        require(self._x != 0, "FixedPoint: ZERO_RECIPROCAL");
        return uq112x112(uint224(Q224 / self._x));
    }

    // square root of a UQ112x112
    function sqrt(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(Babylonian.sqrt(uint256(self._x)) << 56));
    }
}

pragma solidity ^0.6.0;

import "../../../lib/FixedPoint.sol";
import "../interfaces/IUniswapV2Pair.sol";

// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibraryV2 {
    using FixedPoint for *;

    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2**32);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(address pair)
        internal
        view
        returns (
            uint256 price0Cumulative,
            uint256 price1Cumulative,
            uint256 currentPrice0,
            uint256 currentPrice1,
            uint32 blockTimestamp
        )
    {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
        currentPrice0 = uint256(FixedPoint.fraction(reserve1, reserve0)._x);
        currentPrice1 = uint256(FixedPoint.fraction(reserve0, reserve1)._x);
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative += currentPrice0 * timeElapsed;
            // counterfactual
            price1Cumulative += currentPrice1 * timeElapsed;
        }
    }
}

pragma solidity ^0.6.0;

import '@openzeppelin/contracts/math/SafeMath.sol';

import '../owner/Operator.sol';

contract EpochV2 is Operator {
    using SafeMath for uint256;

    uint256 private period;
    uint256 private startTime;
    uint256 private lastEpochTime;
    uint256 private epoch;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        uint256 _period,
        uint256 _startTime,
        uint256 _startEpoch
    ) public {
        period = _period;
        startTime = startTime > block.timestamp ? _startTime : block.timestamp;
        epoch = _startEpoch;
        lastEpochTime = startTime.sub(period);
    }

    /* ========== Modifier ========== */

    modifier checkStartTime {
        require(now >= startTime, 'Epoch: not started yet');

        _;
    }

    modifier checkEpoch {
        uint256 _nextEpochPoint = nextEpochPoint();
        if (now < _nextEpochPoint) {
            require(msg.sender == operator(), 'Epoch: only operator allowed for pre-epoch');
            _;
        } else {
            _;

            for (;;) {
                lastEpochTime = _nextEpochPoint;
                ++epoch;
                _nextEpochPoint = nextEpochPoint();
                if (now < _nextEpochPoint) break;
            }
        }
    }

    /* ========== VIEW FUNCTIONS ========== */

    function getCurrentEpoch() public view returns (uint256) {
        return epoch;
    }

    function getPeriod() public view returns (uint256) {
        return period;
    }

    function getStartTime() public view returns (uint256) {
        return startTime;
    }

    function getLastEpochTime() public view returns (uint256) {
        return lastEpochTime;
    }

    function nextEpochPoint() public view returns (uint256) {
        return lastEpochTime.add(period);
    }

    function canUpdateEpoch() public view returns (bool) {
        return !(now < nextEpochPoint());
    }

    /* ========== GOVERNANCE ========== */

    function setPeriod(uint256 _period) external onlyOperator {
        require(_period >= 1 hours && _period <= 48 hours, '_period: out of range');
        period = _period;
    }

    function setEpoch(uint256 _epoch) external onlyOperator {
        epoch = _epoch;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./lib/Babylonian.sol";
import "./owner/Operator.sol";
import "./utils/ContractGuard.sol";
import "./interfaces/IBasisAsset.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/ITheoretics.sol";
import "./interfaces/IERC20Burnable.sol";

contract Treasury is ContractGuard {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /* ========= CONSTANT VARIABLES ======== */

    uint256 public constant PERIOD = 6 hours;

    /* ========== STATE VARIABLES ========== */

    // governance
    address public operator;

    // flags
    bool public initialized = false;

    // epoch
    uint256 public startTime;
    uint256 public epoch = 0;
    uint256 public epochSupplyContractionLeft = 0;

    // exclusions from total supply
    address[] public excludedFromTotalSupply;

    // core components
    address public game;
    address public hodl;
    address public theory;

    address public theoretics;
    address public bondTreasury;
    address public gameOracle;

    // price
    uint256 public gamePriceOne;
    uint256 public gamePriceCeiling;

    uint256 public seigniorageSaved;

    uint256[] public supplyTiers;
    uint256[] public maxExpansionTiers;

    uint256 public maxSupplyExpansionPercent;
    uint256 public bondDepletionFloorPercent;
    uint256 public seigniorageExpansionFloorPercent;
    uint256 public maxSupplyContractionPercent;
    uint256 public maxDebtRatioPercent;

    uint256 public bondSupplyExpansionPercent;

    // 28 first epochs (1 week) with 4.5% expansion regardless of GAME price
    uint256 public bootstrapEpochs;
    uint256 public bootstrapSupplyExpansionPercent;

    /* =================== Added variables =================== */
    uint256 public previousEpochGamePrice;
    uint256 public maxDiscountRate; // when purchasing bond
    uint256 public maxPremiumRate; // when redeeming bond
    uint256 public discountPercent;
    uint256 public premiumThreshold;
    uint256 public premiumPercent;
    uint256 public mintingFactorForPayingDebt; // print extra GAME during debt phase

    address public daoFund;
    uint256 public daoFundSharedPercent;

    address public devFund;
    uint256 public devFundSharedPercent;

    /* =================== Events =================== */

    event Initialized(address indexed executor, uint256 at);
    event BurnedBonds(address indexed from, uint256 bondAmount);
    event RedeemedBonds(address indexed from, uint256 gameAmount, uint256 bondAmount);
    event BoughtBonds(address indexed from, uint256 gameAmount, uint256 bondAmount);
    event TreasuryFunded(uint256 timestamp, uint256 seigniorage);
    event theoreticsFunded(uint256 timestamp, uint256 seigniorage);
    event DaoFundFunded(uint256 timestamp, uint256 seigniorage);
    event DevFundFunded(uint256 timestamp, uint256 seigniorage);

    /* =================== Modifier =================== */

    modifier onlyOperator() {
        require(operator == msg.sender, "Treasury: caller is not the operator");
        _;
    }

    modifier checkCondition {
        require(block.timestamp >= startTime, "Treasury: not started yet");

        _;
    }

    modifier checkEpoch {
        require(block.timestamp >= nextEpochPoint(), "Treasury: not opened yet");

        _;

        epoch = epoch.add(1);
        epochSupplyContractionLeft = (getGamePrice() > gamePriceCeiling) ? 0 : getGameCirculatingSupply().mul(maxSupplyContractionPercent).div(10000);
    }

    modifier checkOperator {
        require(
            IBasisAsset(game).operator() == address(this) &&
                IBasisAsset(hodl).operator() == address(this) &&
                IBasisAsset(theory).operator() == address(this) &&
                Operator(theoretics).operator() == address(this),
            "Treasury: need more permission"
        );

        _;
    }

    modifier notInitialized {
        require(!initialized, "Treasury: already initialized");

        _;
    }

    /* ========== VIEW FUNCTIONS ========== */

    function isInitialized() public view returns (bool) {
        return initialized;
    }

    // epoch
    function nextEpochPoint() public view returns (uint256) {
        return startTime.add(epoch.mul(PERIOD));
    }

    function shouldAllocateSeigniorage() external view returns (bool) // For bots.
    {
        return block.timestamp >= startTime && block.timestamp >= nextEpochPoint() && ITheoretics(theoretics).totalSupply() > 0;
    }

    // oracle
    function getGamePrice() public view returns (uint256 gamePrice) {
        try IOracle(gameOracle).consult(game, 1e18) returns (uint144 price) {
            return uint256(price);
        } catch {
            revert("Treasury: failed to consult GAME price from the oracle");
        }
    }

    function getGameUpdatedPrice() public view returns (uint256 _gamePrice) {
        try IOracle(gameOracle).twap(game, 1e18) returns (uint144 price) {
            return uint256(price);
        } catch {
            revert("Treasury: failed to consult GAME price from the oracle");
        }
    }

    // budget
    function getReserve() public view returns (uint256) {
        return seigniorageSaved;
    }

    function getBurnableGameLeft() public view returns (uint256 _burnableGameLeft) {
        uint256 _gamePrice = getGamePrice();
        if (_gamePrice <= gamePriceOne) {
            uint256 _gameSupply = getGameCirculatingSupply();
            uint256 _bondMaxSupply = _gameSupply.mul(maxDebtRatioPercent).div(10000);
            uint256 _bondSupply = IERC20(hodl).totalSupply();
            if (_bondMaxSupply > _bondSupply) {
                uint256 _maxMintableBond = _bondMaxSupply.sub(_bondSupply);
                uint256 _maxBurnableGame = _maxMintableBond.mul(_gamePrice).div(1e18);
                _burnableGameLeft = Math.min(epochSupplyContractionLeft, _maxBurnableGame);
            }
        }
    }

    function getRedeemableBonds() external view returns (uint256) {
        uint256 _gamePrice = getGamePrice();
        if (_gamePrice > gamePriceCeiling) {
            uint256 _totalGame = IERC20(game).balanceOf(address(this));
            uint256 _rate = getBondPremiumRate();
            if (_rate > 0) {
                return _totalGame.mul(1e18).div(_rate);
            }
        }
        return 0;
    }

    function getBondDiscountRate() public view returns (uint256 _rate) {
        uint256 _gamePrice = getGamePrice();
        if (_gamePrice <= gamePriceOne) {
            if (discountPercent == 0) {
                // no discount
                _rate = gamePriceOne;
            } else {
                uint256 _bondAmount = gamePriceOne.mul(1e18).div(_gamePrice); // to burn 1 GAME
                uint256 _discountAmount = _bondAmount.sub(gamePriceOne).mul(discountPercent).div(10000);
                _rate = gamePriceOne.add(_discountAmount);
                if (maxDiscountRate > 0 && _rate > maxDiscountRate) {
                    _rate = maxDiscountRate;
                }
            }
        }
    }

    function getBondPremiumRate() public view returns (uint256 _rate) {
        uint256 _gamePrice = getGamePrice();
        if (_gamePrice > gamePriceCeiling) {
            uint256 _gamePricePremiumThreshold = gamePriceOne.mul(premiumThreshold).div(100);
            if (_gamePrice >= _gamePricePremiumThreshold) {
                //Price > 1.10
                uint256 _premiumAmount = _gamePrice.sub(gamePriceOne).mul(premiumPercent).div(10000);
                _rate = gamePriceOne.add(_premiumAmount);
                if (maxPremiumRate > 0 && _rate > maxPremiumRate) {
                    _rate = maxPremiumRate;
                }
            } else {
                // no premium bonus
                _rate = gamePriceOne;
            }
        }
    }

    /* ========== GOVERNANCE ========== */

    function initialize(
        address _game,
        address _hodl,
        address _theory,
        address _gameOracle,
        address _theoretics,
        address _genesisPool,
        address _daoFund,
        address _devFund,
        uint256 _startTime
    ) public notInitialized {
        initialized = true;
        // We could require() for all of these...
        game = _game;
        hodl = _hodl;
        theory = _theory;
        gameOracle = _gameOracle;
        theoretics = _theoretics;
        daoFund = _daoFund;
        devFund = _devFund;
        require(block.timestamp < _startTime, "late");
        startTime = _startTime;

        gamePriceOne = 10**18;
        gamePriceCeiling = gamePriceOne.mul(101).div(100);

        // exclude contracts from total supply
        excludedFromTotalSupply.push(_genesisPool);

        // Dynamic max expansion percent
        supplyTiers = [0 ether, 500000 ether, 1000000 ether, 1500000 ether, 2000000 ether, 5000000 ether, 10000000 ether, 20000000 ether, 50000000 ether];
        maxExpansionTiers = [450, 400, 350, 300, 250, 200, 150, 125, 100];

        maxSupplyExpansionPercent = 400; // Upto 4.0% supply for expansion

        bondDepletionFloorPercent = 10000; // 100% of Bond supply for depletion floor
        seigniorageExpansionFloorPercent = 3500; // At least 35% of expansion reserved for theoretics
        maxSupplyContractionPercent = 300; // Upto 3.0% supply for contraction (to burn GAME and mint HODL)
        maxDebtRatioPercent = 3500; // Upto 35% supply of HODL to purchase

        bondSupplyExpansionPercent = 500; // maximum 5% emissions per epoch for POL bonds

        premiumThreshold = 110;
        premiumPercent = 7000;

        // First 12 epochs with 5% expansion
        bootstrapEpochs = 12;
        bootstrapSupplyExpansionPercent = 500;

        // set seigniorageSaved to it's balance
        seigniorageSaved = IERC20(game).balanceOf(address(this));

        operator = msg.sender;
        emit Initialized(msg.sender, block.number);
    }

    function setOperator(address _operator) external onlyOperator {
        operator = _operator;
    }

    function setTheoretics(address _theoretics) external onlyOperator { // Scary function, but also can be used to upgrade. However, since I don't have a multisig to start, and it isn't THAT important, I'm going to leave this be.
        theoretics = _theoretics;
    }

    function setGameOracle(address _gameOracle) external onlyOperator { // See above.
        gameOracle = _gameOracle;
    }

    function setGamePriceCeiling(uint256 _gamePriceCeiling) external onlyOperator { // I don't see this changing, so I'm going to leave this be.
        require(_gamePriceCeiling >= gamePriceOne && _gamePriceCeiling <= gamePriceOne.mul(120).div(100), "out of range"); // [$1.0, $1.2]
        gamePriceCeiling = _gamePriceCeiling;
    }

    function setMaxSupplyExpansionPercents(uint256 _maxSupplyExpansionPercent) external onlyOperator { // I don't see this changing, so I'm going to leave this be.
        require(_maxSupplyExpansionPercent >= 10 && _maxSupplyExpansionPercent <= 1000, "_maxSupplyExpansionPercent: out of range"); // [0.1%, 10%]
        maxSupplyExpansionPercent = _maxSupplyExpansionPercent;
    }

    function setSupplyTiersEntry(uint8 _index, uint256 _value) external onlyOperator returns (bool) {
        require(_index >= 0, "Index has to be higher than 0");
        require(_index < 9, "Index has to be lower than count of tiers");
        if (_index > 0) {
            require(_value > supplyTiers[_index - 1]);
        }
        if (_index < 8) {
            require(_value < supplyTiers[_index + 1]);
        }
        supplyTiers[_index] = _value;
        return true;
    }

    function setMaxExpansionTiersEntry(uint8 _index, uint256 _value) external onlyOperator returns (bool) {
        require(_index >= 0, "Index has to be higher than 0");
        require(_index < 9, "Index has to be lower than count of tiers");
        require(_value >= 10 && _value <= 1000, "_value: out of range"); // [0.1%, 10%]
        maxExpansionTiers[_index] = _value;
        return true;
    }

    function setBondDepletionFloorPercent(uint256 _bondDepletionFloorPercent) external onlyOperator {
        require(_bondDepletionFloorPercent >= 500 && _bondDepletionFloorPercent <= 10000, "out of range"); // [5%, 100%]
        bondDepletionFloorPercent = _bondDepletionFloorPercent;
    }

    function setMaxSupplyContractionPercent(uint256 _maxSupplyContractionPercent) external onlyOperator {
        require(_maxSupplyContractionPercent >= 100 && _maxSupplyContractionPercent <= 1500, "out of range"); // [0.1%, 15%]
        maxSupplyContractionPercent = _maxSupplyContractionPercent;
    }

    function setMaxDebtRatioPercent(uint256 _maxDebtRatioPercent) external onlyOperator {
        require(_maxDebtRatioPercent >= 1000 && _maxDebtRatioPercent <= 10000, "out of range"); // [10%, 100%]
        maxDebtRatioPercent = _maxDebtRatioPercent;
    }

    function setBootstrap(uint256 _bootstrapEpochs, uint256 _bootstrapSupplyExpansionPercent) external onlyOperator {
        require(_bootstrapEpochs <= 120, "_bootstrapEpochs: out of range"); // <= 1 month
        require(_bootstrapSupplyExpansionPercent >= 100 && _bootstrapSupplyExpansionPercent <= 1000, "_bootstrapSupplyExpansionPercent: out of range"); // [1%, 10%]
        bootstrapEpochs = _bootstrapEpochs;
        bootstrapSupplyExpansionPercent = _bootstrapSupplyExpansionPercent;
    }

    function setExtraFunds(
        address _daoFund,
        uint256 _daoFundSharedPercent,
        address _devFund,
        uint256 _devFundSharedPercent
    ) external onlyOperator {
        require(_daoFund != address(0), "zero");
        require(_daoFundSharedPercent <= 3000, "out of range"); // <= 30%
        require(_devFund != address(0), "zero");
        require(_devFundSharedPercent <= 1000, "out of range"); // <= 10%
        daoFund = _daoFund;
        daoFundSharedPercent = _daoFundSharedPercent;
        devFund = _devFund;
        devFundSharedPercent = _devFundSharedPercent;
    }

    function setMaxDiscountRate(uint256 _maxDiscountRate) external onlyOperator {
        maxDiscountRate = _maxDiscountRate;
    }

    function setMaxPremiumRate(uint256 _maxPremiumRate) external onlyOperator {
        maxPremiumRate = _maxPremiumRate;
    }

    function setDiscountPercent(uint256 _discountPercent) external onlyOperator {
        require(_discountPercent <= 20000, "_discountPercent is over 200%");
        discountPercent = _discountPercent;
    }

    function setPremiumThreshold(uint256 _premiumThreshold) external onlyOperator {
        require(_premiumThreshold >= gamePriceCeiling, "_premiumThreshold exceeds gamePriceCeiling");
        require(_premiumThreshold <= 150, "_premiumThreshold is higher than 1.5");
        premiumThreshold = _premiumThreshold;
    }

    function setPremiumPercent(uint256 _premiumPercent) external onlyOperator {
        require(_premiumPercent <= 20000, "_premiumPercent is over 200%");
        premiumPercent = _premiumPercent;
    }

    function setMintingFactorForPayingDebt(uint256 _mintingFactorForPayingDebt) external onlyOperator {
        require(_mintingFactorForPayingDebt == 0 || (_mintingFactorForPayingDebt >= 10000 && _mintingFactorForPayingDebt <= 20000), "_mintingFactorForPayingDebt: out of range"); // [100%, 200%]
        mintingFactorForPayingDebt = _mintingFactorForPayingDebt;
    }

    function setBondSupplyExpansionPercent(uint256 _bondSupplyExpansionPercent) external onlyOperator {
        bondSupplyExpansionPercent = _bondSupplyExpansionPercent;
    }

    /* ========== MUTABLE FUNCTIONS ========== */

    function _updateGamePrice() internal {
        try IOracle(gameOracle).update() {} catch {}
    }

    function getGameCirculatingSupply() public view returns (uint256) {
        IERC20 gameErc20 = IERC20(game);
        uint256 totalSupply = gameErc20.totalSupply();
        uint256 balanceExcluded = 0;
        uint256 entryId;
        uint256 len = excludedFromTotalSupply.length;
        for (entryId = 0; entryId < len; entryId += 1) {
            balanceExcluded = balanceExcluded.add(gameErc20.balanceOf(excludedFromTotalSupply[entryId]));
        }
        return totalSupply.sub(balanceExcluded);
    }

    function buyBonds(uint256 _gameAmount, uint256 targetPrice) external onlyOneBlock checkCondition checkOperator {
        require(_gameAmount > 0, "Treasury: cannot purchase bonds with zero amount");

        uint256 gamePrice = getGamePrice();
        require(gamePrice == targetPrice, "Treasury: GAME price moved");
        require(
            gamePrice < gamePriceOne, // price < $1
            "Treasury: gamePrice not eligible for bond purchase"
        );

        require(_gameAmount <= epochSupplyContractionLeft, "Treasury: Not enough bonds left to purchase");

        uint256 _rate = getBondDiscountRate();
        require(_rate > 0, "Treasury: invalid bond rate");

        uint256 _bondAmount = _gameAmount.mul(_rate).div(1e18);
        uint256 gameSupply = getGameCirculatingSupply();
        uint256 newBondSupply = IERC20(hodl).totalSupply().add(_bondAmount);
        require(newBondSupply <= gameSupply.mul(maxDebtRatioPercent).div(10000), "over max debt ratio");

        IBasisAsset(game).burnFrom(msg.sender, _gameAmount);
        IBasisAsset(hodl).mint(msg.sender, _bondAmount);

        epochSupplyContractionLeft = epochSupplyContractionLeft.sub(_gameAmount);
        _updateGamePrice();

        emit BoughtBonds(msg.sender, _gameAmount, _bondAmount);
    }

    function redeemBonds(uint256 _bondAmount, uint256 targetPrice) external onlyOneBlock checkCondition checkOperator {
        require(_bondAmount > 0, "Treasury: cannot redeem bonds with zero amount");

        uint256 gamePrice = getGamePrice();
        require(gamePrice == targetPrice, "Treasury: GAME price moved");
        require(
            gamePrice > gamePriceCeiling, // price > $1.01
            "Treasury: gamePrice not eligible for bond redemption"
        );

        uint256 _rate = getBondPremiumRate();
        require(_rate > 0, "Treasury: invalid bond rate");

        uint256 _gameAmount = _bondAmount.mul(_rate).div(1e18);
        require(IERC20(game).balanceOf(address(this)) >= _gameAmount, "Treasury: treasury has no more budget");

        seigniorageSaved = seigniorageSaved.sub(Math.min(seigniorageSaved, _gameAmount));

        IBasisAsset(hodl).burnFrom(msg.sender, _bondAmount);
        IERC20(game).safeTransfer(msg.sender, _gameAmount);

        _updateGamePrice();

        emit RedeemedBonds(msg.sender, _gameAmount, _bondAmount);
    }

    function _sendToTheoretics(uint256 _amount) internal {
        IBasisAsset(game).mint(address(this), _amount);

        uint256 _daoFundSharedAmount = 0;
        if (daoFundSharedPercent > 0) {
            _daoFundSharedAmount = _amount.mul(daoFundSharedPercent).div(10000);
            IERC20(game).transfer(daoFund, _daoFundSharedAmount);
            emit DaoFundFunded(block.timestamp, _daoFundSharedAmount);
        }

        uint256 _devFundSharedAmount = 0;
        if (devFundSharedPercent > 0) {
            _devFundSharedAmount = _amount.mul(devFundSharedPercent).div(10000);
            IERC20(game).transfer(devFund, _devFundSharedAmount);
            emit DevFundFunded(block.timestamp, _devFundSharedAmount);
        }

        _amount = _amount.sub(_daoFundSharedAmount).sub(_devFundSharedAmount);

        IERC20(game).safeApprove(theoretics, 0);
        IERC20(game).safeApprove(theoretics, _amount);
        ITheoretics(theoretics).allocateSeigniorage(_amount);
        emit theoreticsFunded(block.timestamp, _amount);
    }

    function _calculateMaxSupplyExpansionPercent(uint256 _gameSupply) internal returns (uint256) {
        for (uint8 tierId = 8; tierId >= 0; --tierId) {
            if (_gameSupply >= supplyTiers[tierId]) {
                maxSupplyExpansionPercent = maxExpansionTiers[tierId];
                break;
            }
        }
        return maxSupplyExpansionPercent;
    }

    function allocateSeigniorage() external onlyOneBlock checkCondition checkEpoch checkOperator {
        _updateGamePrice();
        previousEpochGamePrice = getGamePrice();
        uint256 gameSupply = getGameCirculatingSupply().sub(seigniorageSaved);
        if (epoch < bootstrapEpochs) {
            // 28 first epochs with 4.5% expansion
            _sendToTheoretics(gameSupply.mul(bootstrapSupplyExpansionPercent).div(10000));
        } else {
            if (previousEpochGamePrice > gamePriceCeiling) {
                // Expansion ($GAME Price > 1 $FTM): there is some seigniorage to be allocated
                uint256 bondSupply = IERC20(hodl).totalSupply();
                uint256 _percentage = previousEpochGamePrice.sub(gamePriceOne);
                uint256 _savedForBond = 0;
                uint256 _savedForTheoretics;
                uint256 _mse = _calculateMaxSupplyExpansionPercent(gameSupply).mul(1e14);
                if (_percentage > _mse) {
                    _percentage = _mse;
                }
                if (seigniorageSaved >= bondSupply.mul(bondDepletionFloorPercent).div(10000)) {
                    // saved enough to pay debt, mint as usual rate
                    _savedForTheoretics = gameSupply.mul(_percentage).div(1e18);
                } else {
                    // have not saved enough to pay debt, mint more
                    uint256 _seigniorage = gameSupply.mul(_percentage).div(1e18);
                    _savedForTheoretics = _seigniorage.mul(seigniorageExpansionFloorPercent).div(10000);
                    _savedForBond = _seigniorage.sub(_savedForTheoretics);
                    if (mintingFactorForPayingDebt > 0) {
                        _savedForBond = _savedForBond.mul(mintingFactorForPayingDebt).div(10000);
                    }
                }
                if (_savedForTheoretics > 0) {
                    _sendToTheoretics(_savedForTheoretics);
                }
                if (_savedForBond > 0) {
                    seigniorageSaved = seigniorageSaved.add(_savedForBond);
                    IBasisAsset(game).mint(address(this), _savedForBond);
                    emit TreasuryFunded(block.timestamp, _savedForBond);
                }
            }
        }
    }

    function governanceRecoverUnsupported(
        IERC20 _token,
        uint256 _amount,
        address _to
    ) external onlyOperator {
        // do not allow to drain core tokens
        require(address(_token) != address(game), "game");
        require(address(_token) != address(hodl), "bond");
        require(address(_token) != address(theory), "share");
        _token.safeTransfer(_to, _amount);
    }

    function theoreticsSetOperator(address _operator) external onlyOperator {
        ITheoretics(theoretics).setOperator(_operator);
    }

    function theoreticsSetLockUp(uint256 _withdrawLockupEpochs, uint256 _rewardLockupEpochs, uint256 _pegMaxUnlock) external onlyOperator {
        ITheoretics(theoretics).setLockUp(_withdrawLockupEpochs, _rewardLockupEpochs, _pegMaxUnlock);
    }

    function theoreticsAllocateSeigniorage(uint256 amount) external onlyOperator {
        ITheoretics(theoretics).allocateSeigniorage(amount);
    }

    function theoreticsGetCurrentWithdrawEpochs() public view returns (uint256) {
        return ITheoretics(theoretics).getCurrentWithdrawEpochs();
    }

    function theoreticsGetCurrentClaimEpochs() public view returns (uint256) {
        return ITheoretics(theoretics).getCurrentClaimEpochs();
    }

    function theoreticsGetWithdrawFeeOf(address _user) public view returns (uint256) {
        return ITheoretics(theoretics).getWithdrawFeeOf(_user);
    }

    function theoreticsGovernanceRecoverUnsupported(
        address _token,
        uint256 _amount,
        address _to
    ) external onlyOperator {
        ITheoretics(theoretics).governanceRecoverUnsupported(_token, _amount, _to);
    }

    function theoreticsGetLockPercentage() public view returns (uint256) {
        return ITheoretics(theoretics).getLockPercentage();
    }

    function burn(
        address _token,
        uint256 _amount
    ) external onlyOperator {
        IERC20Burnable(_token).burn(_amount); // Burn any token that we own! Now we can burn THEORY and such with no problem to deflate it.
    }

    // Allow us to delay or begin earlier if we have not started yet.
    function setStartTime(
        uint256 _time
    ) public onlyOperator
    {
        require(block.timestamp < startTime, "Already started.");
        require(block.timestamp < _time, "Time input is too early.");
        startTime = _time;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

pragma solidity ^0.6.0;

interface IBasisAsset {
    function mint(address recipient, uint256 amount) external returns (bool);

    function burn(uint256 amount) external;

    function burnFrom(address from, uint256 amount) external;

    function isOperator() external returns (bool);

    function operator() external view returns (address);

    function transferOperator(address newOperator_) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ITheoretics {
    function balanceOf(address _mason) external view returns (uint256);

    function earned(address _mason) external view returns (uint256);

    function canWithdraw(address _mason) external view returns (bool);

    function canClaimReward(address theorist) external view returns (bool);

    function epoch() external view returns (uint256);

    function nextEpochPoint() external view returns (uint256);

    function getGamePrice() external view returns (uint256);

    function setOperator(address _operator) external;

    function setLockUp(uint256 _withdrawLockupEpochs, uint256 _rewardLockupEpochs, uint256 _pegMaxUnlock) external;

    function stake(uint256 _amount) external;

    function withdraw(uint256 _amount) external;

    function exit() external;

    function claimReward() external;

    function allocateSeigniorage(uint256 _amount) external;

    function governanceRecoverUnsupported(address _token, uint256 _amount, address _to) external;

    function getCurrentWithdrawEpochs() external view returns (uint256);

    function getCurrentClaimEpochs() external view returns (uint256);

    function getWithdrawFeeOf(address _user) external view returns (uint256);

    function getLockPercentage() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function getLatestSnapshot() external view returns (uint256 time, uint256 rewardReceived, uint256 rewardPerShare);

    function latestSnapshotIndex() external view returns (uint256);

    function theoreticsHistory(uint256 index) external view returns (uint256 time, uint256 rewardReceived, uint256 rewardPerShare);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Burnable is IERC20 {
    function burn(uint256 amount) external;
}

pragma solidity 0.6.12;
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IOracleV2.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../AuthorizableNoOperator.sol";

contract GameBondDepository is ReentrancyGuard, AuthorizableNoOperator {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    IOracleV2 public oracle;
    IERC20 public game;
    IERC20 public usdc;
    bool public manualMode;
    uint256 public controlVariable; //Manual Mode: GAME per USDC, Automatic Mode: GAME Percent per USDC
    uint256 public maxBuyAmountInUsdc; //Max buy amount in GAME is the balance of GAME in the contract. If someone sends more, the USDC amount should be enough of a failsafe.
    uint256 public usdcDepositedForThisRound;
    uint256 public buyEndTime;
    uint256 public vestingTime;
    mapping(address => uint256) public nonceOf;
    mapping(address => uint256[]) public activeNonces;
    struct BuyInfo
    {
        uint256 usdcDeposited;
        uint256 vestedStartTime;
        uint256 vestedEndTime;
        uint256 vestedGameAmount;
        uint256 vestedGameLeft;
        uint256 lastClaimTime;
        uint256 nonceIndex;
    }
    mapping(address => mapping (uint256 => BuyInfo)) public buyInfo;
    uint256 public totalGameVested; //Total Vested Left

    constructor(IERC20 _game, IERC20 _usdc, IOracleV2 _oracle) public
    {
        game = _game;
        usdc = _usdc;
        oracle = _oracle;
        if(address(_oracle) != address(0))
        {
            try IOracleV2(_oracle).twap(address(_game), 1e18) returns (uint144 price) {
                require(price > 0, "Invalid GAME price on oracle.");
            } catch {
                revert("Invalid GAME oracle."); //GAME: failed to consult GAME price from the oracle
            }
            try IOracleV2(_oracle).twap(address(_usdc), 1e6) returns (uint144 price) {
                require(price > 0, "Invalid USDC price on oracle.");
            } catch {
                revert("Invalid GAME oracle."); //GAME: failed to consult GAME price from the oracle
            }
        }
    }

    function setOracle(IOracleV2 _oracle) external onlyAuthorized
    {
        require(block.timestamp >= buyEndTime, "Now must be after last end.");
        oracle = _oracle;
        if(address(_oracle) != address(0))
        {
            try IOracleV2(_oracle).twap(address(game), 1e18) returns (uint144 price) {
                require(price > 0, "Invalid GAME price on oracle.");
            } catch {
                revert("Invalid GAME oracle."); //GAME: failed to consult GAME price from the oracle
            }
            try IOracleV2(_oracle).twap(address(usdc), 1e6) returns (uint144 price) {
                require(price > 0, "Invalid USDC price on oracle.");
            } catch {
                revert("Invalid GAME oracle."); //GAME: failed to consult GAME price from the oracle
            }
        }
    }

    function getActiveNonces(address player) external view returns (uint256[] memory)
    {
        return activeNonces[player];
    }

    function getTradeRate(uint256 usdcAmount) external view returns (uint256)
    {
        return manualMode ? usdcAmount.mul(controlVariable).div(1e6) :
        oracle.consult(address(usdc), usdcAmount.mul(controlVariable).div(1e18));
    }

    function start(uint256 depositAmount, uint256 buyEnd, uint256 timeToVest, bool manualMode, uint256 controlVar, uint256 maxBuyAmount) external nonReentrant onlyAuthorized
    {
        require(block.timestamp >= buyEndTime, "Now must be after last end.");
        require(buyEnd > block.timestamp, "End must be after now.");
        require(controlVar > 0 , "Bad control variable.");
        require(timeToVest > 0, "Invalid vesting time.");
        require(manualMode || !manualMode && address(oracle) != address(0)
        , "Automatic mode needs oracle.");
        buyEndTime = buyEnd;
        maxBuyAmountInUsdc = maxBuyAmount;
        vestingTime = timeToVest;
        controlVariable = controlVar;
        usdcDepositedForThisRound = 0;
        if(depositAmount == 0)
        {
            if(!manualMode) try oracle.updateIfPossible() {} catch {}
            uint256 amountNeeded = manualMode ? maxBuyAmount.mul(controlVariable).div(1e6) :
            oracle.consult(address(usdc), maxBuyAmount.mul(controlVariable).div(1e18));
            require(amountNeeded > 0, "Invalid amount needed.");
            uint256 balance = game.balanceOf(address(this));
            if(balance < amountNeeded)
            {
                depositAmount = amountNeeded.sub(balance);
            }
        }
        if(depositAmount > 0) game.safeTransferFrom(msg.sender, address(this), depositAmount);
    }

    function end() external onlyAuthorized //Ends bonding prematurely. Use only in emergencies.
    {
        require(block.timestamp < buyEndTime, "Not running.");
        buyEndTime = block.timestamp;
    }

    function gameLeftForBonds() external view returns (uint256)
    {
        return game.balanceOf(address(this)).sub(totalGameVested);
    }

    function usdcLeftForBonds() external view returns (uint256)
    {
        return maxBuyAmountInUsdc.sub(usdcDepositedForThisRound);
    }

    function deposit(uint256 amount) external nonReentrant
    {
        require(block.timestamp < buyEndTime, "Buy window ended.");
        require(amount > 0, "Must deposit something.");
        require(usdcDepositedForThisRound.add(amount) <= maxBuyAmountInUsdc, "Too much USDC bought.");
        uint256 vestedGameAmount;
        if(manualMode)
        {
            vestedGameAmount = amount.mul(controlVariable).div(1e6); //USDC Decimals: 6
        }
        else
        {
            try oracle.updateIfPossible() {} catch {}
            vestedGameAmount = oracle.consult(address(usdc), amount.mul(controlVariable).div(1e18));
        }
        require(vestedGameAmount > 0, "Invalid vested game amount.");
        require(game.balanceOf(address(this)).sub(totalGameVested) >= vestedGameAmount, "Not enough GAME available.");
        totalGameVested = totalGameVested.add(vestedGameAmount);
        usdcDepositedForThisRound = usdcDepositedForThisRound.add(amount);
        uint256 nonce = nonceOf[msg.sender];
        BuyInfo storage round = buyInfo[msg.sender][nonce];
        round.usdcDeposited = amount;
        round.vestedStartTime = block.timestamp;
        round.vestedEndTime = block.timestamp.add(vestingTime);
        round.vestedGameAmount = vestedGameAmount;
        round.vestedGameLeft = vestedGameAmount;
        round.lastClaimTime = block.timestamp;
        round.nonceIndex = activeNonces[msg.sender].length;
        activeNonces[msg.sender].push(nonce);
        nonceOf[msg.sender] = nonce.add(1);
        usdc.safeTransferFrom(msg.sender, address(this), amount);
    }

    function canUnlockAmount(address player, uint256 nonce) public view returns (uint256)
    {
        BuyInfo memory round = buyInfo[msg.sender][nonce];
        if (block.timestamp <= round.vestedStartTime) {
            return 0;
        } else if (block.timestamp >= round.vestedEndTime) {
            return round.vestedGameLeft;
        } else {
            uint256 releaseTime = block.timestamp.sub(round.lastClaimTime);
            uint256 numberLockTime = round.vestedEndTime.sub(round.lastClaimTime);
            return round.vestedGameLeft.mul(releaseTime).div(numberLockTime);
        }
    }

    function claim(uint256 nonce) external nonReentrant
    {
        BuyInfo storage round = buyInfo[msg.sender][nonce];
        require(round.lastClaimTime < round.vestedEndTime && round.vestedGameLeft > 0, "Not active.");
        uint256 amount = canUnlockAmount(msg.sender, nonce);
        round.vestedGameLeft = round.vestedGameLeft.sub(amount);
        round.lastClaimTime = block.timestamp;
        totalGameVested = totalGameVested.sub(amount);
        if(block.timestamp >= round.vestedEndTime || round.vestedGameLeft == 0)
        {
                uint256[] storage array = activeNonces[msg.sender];
                if (array.length > 1) {
                    uint256 lastIndex = array.length-1;
                    buyInfo[msg.sender][array[lastIndex]].nonceIndex = round.nonceIndex;
                    array[round.nonceIndex] = array[lastIndex]; //Can sort array by nonce off-chain.
                }
                array.pop();
        }
        game.safeTransfer(address(this), amount);
    }

    function withdraw(
        IERC20 _token,
        uint256 _amount,
        address _to
    ) external onlyAuthorized {
        require(_token != game || _amount <= game.balanceOf(address(this)).sub(totalGameVested), "Can't take away from vested amount.");
        _token.transfer(_to, _amount);
    }
}

pragma solidity 0.6.12;
import "@openzeppelin/contracts/access/Ownable.sol";

contract AuthorizableNoOperator is Ownable {
    mapping(address => bool) public authorized;

    modifier onlyAuthorized() {
        require(authorized[msg.sender] || owner() == msg.sender, "caller is not authorized");
        _;
    }

    function addAuthorized(address _toAdd) public onlyOwner {
        authorized[_toAdd] = true;
    }

    function removeAuthorized(address _toRemove) public onlyOwner {
        require(_toRemove != msg.sender);
        authorized[_toRemove] = false;
    }
}

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../AuthorizableNoOperator.sol";
import "../interfaces/IERC20Lockable.sol";
import "../utils/ContractGuard.sol";
import "../interfaces/ITheoryUnlocker.sol";
import "../interfaces/IUniswapV2Router.sol";
pragma experimental ABIEncoderV2; //https://docs.soliditylang.org/en/v0.6.9/layout-of-source-files.html?highlight=experimental#abiencoderv2

//When deploying: Every 15 days 5 max levels, max max level is 50. Initial price and buy per level = 500 worth of THEORY [determined at deploy time].
//Deploy with same timeframe as Gen 0
contract TheoryUnlockerGen1 is ERC721, AuthorizableNoOperator, ContractGuard {
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Lockable;
    using SafeMath for uint256;

    Counters.Counter private _tokenIds;

    struct TokenInfo
    {
        uint256 level;
        uint256 creationTime;
        uint256 lastLevelTime;
        bool merged;
    }

    mapping(uint256 => TokenInfo) public tokenInfo;

    //UserInfo is shared with Gen 0, so below is not needed.
    //mapping(address => UserInfo) public userInfo;

    uint256[] public levelURIsLevel; // Used like feeStageTime
    string[] public levelURIsURI; // Used like feeStagePercentage
    uint256[] public levelURIsMax; // Used like feeStagePercentage
    uint256[] public levelURIsSupply; // Used like feeStagePercentage
    uint256[] public levelURIsMinted; // Used like feeStagePercentage

    uint256[] public maxLevelTime; // Used like feeStageTime
    uint256[] public maxLevelLevel; // Used like feeStagePercentage
    IERC20 public buyToken;
    uint256 public initialPrice; //Price for level 1.
    uint256 public buyTokenPerLevel;
    uint256 public burnPercentage;
    address public communityFund;
    uint256 public timeToLevel;
    IERC20Lockable public theory;
    IERC20Lockable public game;
    bool public disableMint; // Limited time only?! Would give more worth in marketplace the for our early investors.
    bool public emergencyDisableUnlock; // EMERGENCY ONLY.
    ITheoryUnlocker public TheoryUnlockerGen0;
    IUniswapV2Router public router;

    uint256 public gameCostPerLevel;
    uint256[] public extraGameCostLevel; // Used like feeStageTime. Starting level, not the level to level up to.
    uint256[] public extraGameCostAmount; // Used like feeStagePercentage

    // Events.
    event Mint(address who, uint256 tokenId, uint256 level);
    event Merge(address who, uint256 tokenId1, uint256 tokenId2, uint256 level1, uint256 level2, uint256 levelMerged);
    event Level(address who, uint256 tokenId, uint256 leveledTo);
    event Unlock(address who, uint256 tokenId, uint256 level, uint256 amountToUnlock);

    //Construction
    constructor(IERC20 _buy, uint256[2] memory _prices, IERC20Lockable[2] memory _theoryAndGame, address _communityFund, ITheoryUnlocker _gen0, IUniswapV2Router _router, uint256[] memory _maxLevelTime, uint256[] memory _maxLevelLevel, uint256[] memory _levelURIsLevel, string[] memory _levelURIsURI, uint256[] memory _levelURIsMax) ERC721("THEORY Unlocker Gen 1", "TUG1") public {
        buyToken = _buy;
        require(_prices[0] >= _prices[1], "IP"); //Initial price must be >= buy per level.
        initialPrice = _prices[0];
        buyTokenPerLevel = _prices[1];
        require(_levelURIsLevel.length > 0
        && _levelURIsLevel[0] == 0
            && _levelURIsURI.length == _levelURIsLevel.length
            && _levelURIsMax.length == _levelURIsLevel.length,
            "Level URI arrays must be equal in non-zero length and level should start at 0.");
        require(_maxLevelTime.length > 0
        && _maxLevelTime[0] == 0
            && _maxLevelLevel.length == _maxLevelTime.length,
            "Max level arrays must be equal in non-zero length and time should start at 0.");
        uint256 i;
        uint256 len = _maxLevelLevel.length;
        for(i = 0; i < len; i += 1)
        {
            require(_maxLevelLevel[i] <= 100, "Max level can't be higher than 100."); //In practice, this will be 50, but there is no point in making it lower here, does more harm than good.
        }
        levelURIsLevel = _levelURIsLevel;
        levelURIsURI = _levelURIsURI;
        levelURIsMax = _levelURIsMax;

        len = levelURIsLevel.length;
        for(i = 0; i < len; i += 1)
        {
            levelURIsSupply.push(0);
            levelURIsMinted.push(0);
        }

        maxLevelTime = _maxLevelTime;
        maxLevelLevel = _maxLevelLevel;
        communityFund = _communityFund;
        timeToLevel = 3 days;
        theory = _theoryAndGame[0];
        game = _theoryAndGame[1];
        disableMint = false;
        emergencyDisableUnlock = false;
        TheoryUnlockerGen0 = _gen0;
        burnPercentage = 1000;
        router = _router;

        gameCostPerLevel = 1 ether;
        extraGameCostLevel = [0,5,10,15,20,25,30,35,40,45];
        extraGameCostAmount = [5 ether,10 ether,20 ether,40 ether,80 ether,160 ether,320 ether,640 ether,1280 ether,2560 ether];
    }

    //Administrative functions
    function setBuyToken(IERC20 _buy) public onlyAuthorized
    {
        buyToken = _buy;
    }

    function setBurnPercentage(uint256 _burn) public onlyAuthorized
    {
        require(_burn <= 10000, "BA"); //Burn amount must be <= 100%
        burnPercentage = _burn;
    }

    function setRouter(IUniswapV2Router _router) public onlyAuthorized
    {
        router = _router;
    }

    function setPrices(uint256 _initial, uint256 _perLevel) public onlyAuthorized
    {
        require(_initial >= _perLevel, "IP"); //Initial price must be >= buy per level.
        initialPrice = _initial;
        buyTokenPerLevel = _perLevel;
    }

    //Be careful with this and any function modifying supply. It must match up.
    //_levelURIsURI must be unique, or it will mess with removeSupply. It's just for stats, though, so it's not too harmful.
    function setLevelURIs(uint256[] memory _levelURIsLevel, string[] memory _levelURIsURI, uint256[] memory _levelURIsMax, uint256[] memory _levelURIsSupply, uint256[] memory _levelURIsMinted) public onlyAuthorized
    {
        require(disableMint, "DMURI"); //For safety reasons, please disable mint before changing these values.
        require(_levelURIsLevel.length > 0
        && _levelURIsLevel[0] == 0
            && _levelURIsURI.length == _levelURIsLevel.length
            && _levelURIsMax.length == _levelURIsLevel.length
            && _levelURIsSupply.length == _levelURIsLevel.length
            && _levelURIsMinted.length == _levelURIsLevel.length,
            "Level URI arrays must be equal in non-zero length and level should start at 0.");
        levelURIsLevel = _levelURIsLevel;
        levelURIsURI = _levelURIsURI;
        levelURIsMax = _levelURIsMax;
        levelURIsSupply = _levelURIsSupply;
        levelURIsMinted = _levelURIsMinted;
    }

    function setMaxLevel(uint256[] memory _maxLevelTime, uint256[] memory _maxLevelLevel) public onlyAuthorized
    {
        require(_maxLevelTime.length > 0
        && _maxLevelTime[0] == 0
            && _maxLevelLevel.length == _maxLevelTime.length,
            "Max level arrays must be equal in non-zero length and time should start at 0.");
        uint256 i;
        uint256 len = _maxLevelLevel.length;
        for(i = 0; i < len; i += 1)
        {
            require(_maxLevelLevel[i] <= 100, "Max level can't be higher than 100."); //In practice, this will be 50, but there is no point in making it lower here, does more harm than good.
        }
        maxLevelTime = _maxLevelTime;
        maxLevelLevel = _maxLevelLevel;
    }

    function setGameCostForLevel(uint256 _gameCostPerLevel, uint256[] memory _extraGameCostLevel, uint256[] memory _extraGameCostAmount) public onlyAuthorized
    {
        require(_extraGameCostLevel.length > 0
        && _extraGameCostLevel[0] == 0
            && _extraGameCostAmount.length == _extraGameCostLevel.length,
            "GCA");
        //require(_gameCostPerLevel <= 10, "Game cost per level can't be higher than 10"); //We actually may need higher than this limit, and not sure of the highest we need, deleting.
//        uint256 i;
//        uint256 len = _extraGameCostAmount.length;
//        for(i = 0; i < len; i += 1)
//        {
//            require(_extraGameCostAmount[i] <= 100, "Extra game cost can't be higher than 100.");  //We actually may need higher than this limit, and not sure of the highest we need, deleting.
//        }
        gameCostPerLevel = _gameCostPerLevel;
        extraGameCostLevel = _extraGameCostLevel;
        extraGameCostAmount = _extraGameCostAmount;
    }

    function setCommunityFund(address _fund) public onlyAuthorized
    {
        communityFund = _fund;
    }
    //setTheory? //Maybe not, can't think of a reason why we'd need this as THEORY can't be redeployed.
    function setTimeToLevel(uint256 _time) public onlyAuthorized
    {
        timeToLevel = _time;
    }

    function setDisableMint(bool _disable) public onlyAuthorized
    {
        disableMint = _disable;
    }

    //EMERGENCY ONLY. To stop an unlock bug/exploit (since it calls an external contract) and/or protect investors' funds.
    function setEmergencyDisableUnlock(bool _disable) public onlyAuthorized
    {
        emergencyDisableUnlock = _disable;
    }

    function setTokenLevel(uint256 tokenId, uint256 level) public onlyAuthorized
    {
        require(level > 0 && level <= maxLevel(), "Level must be > 0 and <= max level.");
        tokenInfo[tokenId].level = level;
    }

    function setCreationTime(uint256 tokenId, uint256 time) public onlyAuthorized
    {
        tokenInfo[tokenId].creationTime = time;
    }

    function setLastLevelTime(uint256 tokenId, uint256 time) public onlyAuthorized
    {
        tokenInfo[tokenId].lastLevelTime = time;
    }

    function setLastUnlockTime(address user, uint256 time) public onlyAuthorized
    {
        TheoryUnlockerGen0.setLastUnlockTime(user, time);
    }

    function setLastLockAmount(address user, uint256 amount) public onlyAuthorized
    {
        TheoryUnlockerGen0.setLastLockAmount(user, amount);
    }

    //Data functions
    function maxLevel() public view returns (uint256)
    {
        uint256 maxLevel = 0;
        uint256 len = maxLevelTime.length;
        uint256 n;
        uint256 i;
        for (n = len; n > 0; n -= 1) {
            i = n-1;
            if(block.timestamp >= maxLevelTime[i])
            {
                maxLevel = maxLevelLevel[i];
                break;
            }
        }
        return maxLevel;
    }

    function levelURI(uint256 level) public view returns (string memory)
    {
        string memory URI = '';
        uint256 len = levelURIsLevel.length;
        uint256 n;
        uint256 i;
        for (n = len; n > 0; n -= 1) {
            i = n-1;
            if(level >= levelURIsLevel[i])
            {
                URI = levelURIsURI[i];
                break;
            }
        }
        return URI;
    }

    function supply(uint256 level) public view returns (uint256)
    {
        uint256 supply = 0;
        uint256 len = levelURIsLevel.length;
        uint256 n;
        uint256 i;
        for (n = len; n > 0; n -= 1) {
            i = n-1;
            if(level >= levelURIsLevel[i])
            {
                supply = levelURIsSupply[i];
                break;
            }
        }
        return supply;
    }

    function minted(uint256 level) public view returns (uint256)
    {
        uint256 minted = 0;
        uint256 len = levelURIsLevel.length;
        uint256 n;
        uint256 i;
        for (n = len; n > 0; n -= 1) {
            i = n-1;
            if(level >= levelURIsLevel[i])
            {
                minted = levelURIsMinted[i];
                break;
            }
        }
        return minted;
    }

    function maxMinted(uint256 level) public view returns (uint256)
    {
        uint256 maxMinted = 0;
        uint256 len = levelURIsLevel.length;
        uint256 n;
        uint256 i;
        for (n = len; n > 0; n -= 1) {
            i = n-1;
            if(level >= levelURIsLevel[i])
            {
                maxMinted = levelURIsMax[i];
                break;
            }
        }
        return maxMinted;
    }

    function extraGameCost(uint256 level) public view returns (uint256)
    {
        uint256 cost = 0;
        uint256 len = extraGameCostLevel.length;
        uint256 n;
        uint256 i;
        for (n = len; n > 0; n -= 1) {
            i = n-1;
            if(level >= extraGameCostLevel[i])
            {
                cost = extraGameCostAmount[i];
                break;
            }
        }
        return cost;
    }

    function costOf(uint256 level) external view returns (uint256)
    {
        return initialPrice.add(buyTokenPerLevel.mul(level.sub(1)));
    }

    function timeLeftToLevel(uint256 tokenId) external view returns (uint256)
    {
        uint256 nextLevelTime = tokenInfo[tokenId].lastLevelTime.add(timeToLevel);
        if(block.timestamp >= nextLevelTime)
        {
            return 0;
        }
        return nextLevelTime.sub(block.timestamp);
    }

    function nextLevelTime(uint256 tokenId) external view returns (uint256)
    {
        return tokenInfo[tokenId].lastLevelTime.add(timeToLevel);
    }

    //This or theory.canUnlockAmount > 0? Enable button.
    function canUnlockAmount(address player, uint256 tokenId) external view returns (uint256)
    {
        ITheoryUnlocker.UserInfo memory user = TheoryUnlockerGen0.userInfo(player);

        uint256 amountLocked = theory.lockOf(player);
        if(amountLocked == 0)
        {
            return 0;
        }

        uint256 pendingUnlock = theory.canUnlockAmount(player);
        if(!(amountLocked > pendingUnlock))
        {
            return 0;
        }

        amountLocked = amountLocked.sub(pendingUnlock); //Amount after unlocking naturally.
        if(!(amountLocked > user.lastLockAmount)) //Can't unlock in good faith.
        {
            return 0;
        }

        amountLocked = amountLocked.sub(user.lastLockAmount); //Amount after taking into account amount already unlocked.

        //Amount to unlock = Level% of locked amount calculated above
        uint256 amountToUnlock = amountLocked.mul(tokenInfo[tokenId].level).div(100);

        return amountToUnlock;
    }

    //Internal functions
    function addSupply(uint256 level, uint256 amount) internal
    {
        uint256 len = levelURIsLevel.length;
        uint256 n;
        uint256 i;
        for (n = len; n > 0; n -= 1) {
            i = n-1;
            if(level >= levelURIsLevel[i])
            {
                levelURIsSupply[i] += amount;
                break;
            }
        }
    }

    function addMinted(uint256 level, uint256 amount) internal
    {
        uint256 len = levelURIsLevel.length;
        uint256 n;
        uint256 i;
        for (n = len; n > 0; n -= 1) {
            i = n-1;
            if(level >= levelURIsLevel[i])
            {
                require(levelURIsMinted[i] < levelURIsMax[i], "Max minted.");
                levelURIsMinted[i] += amount;
                break;
            }
        }
    }

    //From: https://ethereum.stackexchange.com/questions/30912/how-to-compare-strings-in-solidity by Joel M Ward
    function memcmp(bytes memory a, bytes memory b) internal pure returns(bool){
        return (a.length == b.length) && (keccak256(a) == keccak256(b));
    }
    function strcmp(string memory a, string memory b) internal pure returns(bool){
        return memcmp(bytes(a), bytes(b));
    }

    function removeSupply(string memory URI, uint256 amount) internal
    {
        uint256 len = levelURIsURI.length;
        uint256 n;
        uint256 i;
        for (n = len; n > 0; n -= 1) {
            i = n-1;
            if(strcmp(URI, levelURIsURI[i]))
            {
                levelURIsSupply[i] -= amount;
                break;
            }
        }
    }

    //Core functionality
    function isAlwaysAuthorizedToMint(address addy) internal view returns (bool)
    {
        return addy == communityFund || authorized[addy] || owner() == addy;
    }

    function mint(uint256 level, uint256 slippage) onlyOneBlock public returns (uint256) {
        require(!disableMint || isAlwaysAuthorizedToMint(msg.sender), "Minting unavailable.");
        require(level > 0 && level <= maxLevel() || level > 0 && isAlwaysAuthorizedToMint(msg.sender), "Level must be > 0 and <= max level.");
        if(!isAlwaysAuthorizedToMint(msg.sender))
        {
            uint256 totalAmount = initialPrice.add(buyTokenPerLevel.mul(level.sub(1)));
            uint256 amountForGame = totalAmount.mul(burnPercentage).div(10000);
            uint256 amountForCommunityFund = totalAmount.sub(amountForGame);
            buyToken.safeTransferFrom(msg.sender, communityFund, amountForCommunityFund);

            if(amountForGame > 0)
            {
                uint256 amountOutMin;
                address[] memory path = new address[](2);
                path[0] = address(buyToken);
                path[1] = address(game);
                {
                    buyToken.safeTransferFrom(msg.sender, address(this), amountForGame);
                    uint256[] memory amountsOut = router.getAmountsOut(amountForGame, path);
                    uint256 amountOut = amountsOut[amountsOut.length - 1];
                    amountOutMin = amountOut.sub(amountOut.mul(slippage).div(10000));
                }
                {
                    buyToken.safeApprove(address(router), 0);
                    buyToken.safeApprove(address(router), amountForGame);
                    uint256[] memory amountsObtained = router.swapExactTokensForTokens(amountForGame, amountOutMin, path, address(this), block.timestamp);
                    uint256 gameObtained = amountsObtained[amountsObtained.length - 1];
                    game.burn(gameObtained);
                }
            }
        }

        address player = msg.sender;
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        TokenInfo storage token = tokenInfo[newItemId];
        token.creationTime = block.timestamp;
        token.lastLevelTime = block.timestamp;
        addSupply(level, 1);
        addMinted(level, 1);
        _mint(player, newItemId);
        token.level = level;
        string memory tokenURI = levelURI(level);
        require(bytes(tokenURI).length > 0, "Token URI is invalid.");
        _setTokenURI(newItemId, tokenURI);

        emit Mint(msg.sender, newItemId, level);

        return newItemId;
    }

    //Make sure to have a warning on the website if they try to merge while one of these tokens can level up!
    function merge(uint256 tokenId1, uint256 tokenId2) onlyOneBlock public returns (uint256) {
        require(tokenId1 != tokenId2, "Token IDs must be different.");
        require(ownerOf(tokenId1) == msg.sender || authorized[msg.sender] || owner() == msg.sender, "Not enough permissions for token 1.");
        require(ownerOf(tokenId2) == msg.sender || authorized[msg.sender] || owner() == msg.sender, "Not enough permissions for token 2.");
        require(ownerOf(tokenId1) == ownerOf(tokenId2), "Both tokens must have the same owner.");
        require(!tokenInfo[tokenId1].merged, "Token 1 has already been merged."); // Gen 1 NFTs can only be merged once.
        require(!tokenInfo[tokenId2].merged, "Token 2 has already been merged."); // Gen 1 NFTs can only be merged once.
        uint256 levelFirst = tokenInfo[tokenId1].level;
        uint256 levelSecond = tokenInfo[tokenId2].level;
        uint256 level = levelFirst.add(levelSecond); //Add the two levels together.
        require(level > 0 && level <= maxLevel() || isAlwaysAuthorizedToMint(msg.sender), "Level must be > 0 and <= max level.");
        address player = ownerOf(tokenId1);
        string memory _tokenURI = tokenURI(tokenId1); //Takes the URI of the FIRST token. Make sure to warn users of this.
        //Burn originals.
        _burn(tokenId1); //Don't need to change tokenURI supply because we are adding one.
        removeSupply(tokenURI(tokenId2), 1);
        _burn(tokenId2);

        //Mint a new one.
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        TokenInfo storage token = tokenInfo[newItemId];
        token.creationTime = block.timestamp;
        token.lastLevelTime = block.timestamp;
        _mint(player, newItemId);
        token.level = level;
        token.merged = true;
        require(bytes(_tokenURI).length > 0, "Token URI is invalid.");
        _setTokenURI(newItemId, _tokenURI);

        emit Merge(msg.sender, tokenId1, tokenId2, levelFirst, levelSecond, level);

        return newItemId;
    }

    function _levelInternal(uint256 tokenId) internal {
        require(ownerOf(tokenId) == msg.sender || authorized[msg.sender] || owner() == msg.sender, "Not enough permissions.");
        TokenInfo storage token = tokenInfo[tokenId];
        require(token.level < maxLevel(), "Level must be lower than max level.");
        uint256 nextLevelTime = token.lastLevelTime.add(timeToLevel);
        require(block.timestamp >= nextLevelTime, "Too early to level up.");

        //Level up.
        //creationTime[newItemId] = block.timestamp; //Same creation time.
        token.lastLevelTime = nextLevelTime;
        //_mint(player, newItemId); //Same ID.
        if(!isAlwaysAuthorizedToMint(msg.sender))
        {
            uint256 baseCost = gameCostPerLevel.mul(token.level);
            uint256 extraCost = extraGameCost(token.level);
            uint256 amount = baseCost.add(extraCost);
            if(amount > 0)
            {
                game.safeTransferFrom(msg.sender, address(this), amount);
                game.burn(amount);
            }
        }
        uint256 level = token.level.add(1);
        token.level = level;
        //string memory tokenURI = levelURI(level);
        //require(bytes(tokenURI).length > 0, "Token URI is invalid.");
        //_setTokenURI(tokenId, tokenURI);
        emit Level(msg.sender, tokenId, level);
    }

    function levelUp(uint256 tokenId) onlyOneBlock public {
        _levelInternal(tokenId);
    }

    function levelUpTo(uint256 tokenId, uint256 theLevel) onlyOneBlock public {
        require(theLevel > tokenInfo[tokenId].level && theLevel <= maxLevel(), "Level must be lower than max level and higher than current."); //Not going to bother with admin here.
        require(block.timestamp >= tokenInfo[tokenId].lastLevelTime.add(timeToLevel), "Too early to level up.");
        while(tokenInfo[tokenId].level < theLevel && block.timestamp >= tokenInfo[tokenId].lastLevelTime.add(timeToLevel))
        {
            _levelInternal(tokenId);
        }
    }

    function levelUpToMax(uint256 tokenId) onlyOneBlock public {
        require(block.timestamp >= tokenInfo[tokenId].lastLevelTime.add(timeToLevel), "Too early to level up.");
        while(block.timestamp >= tokenInfo[tokenId].lastLevelTime.add(timeToLevel))
        {
            _levelInternal(tokenId);
        }
    }

    //Should be called:
    //When lockOf(player) == 0 - Instead of theory.unlock() [disabled on website]
    //When lockOf(player) <= theory.canUnlockAmount(player) - After theory.unlock() [to avoid revert, knew I should have listened to my gut and put a check for the second _unlock]
    //When lockOf(player) > theory.canUnlockAmount(player) - Instead of theory.unlock()
    function nftUnlock(uint256 tokenId) onlyOneBlock public { //Find the best tokenId to use off the blockchain using tokenOfOwnerByIndex and balanceOf
        require(!emergencyDisableUnlock, "NFT unlocking has been disabled in an emergency.");
        require(ownerOf(tokenId) == msg.sender || authorized[msg.sender] || owner() == msg.sender, "Not enough permissions.");
        address player = ownerOf(tokenId);
        ITheoryUnlocker.UserInfo memory pastUserInfo = TheoryUnlockerGen0.userInfo(player);
        require(block.timestamp > pastUserInfo.lastUnlockTime, "Logic error.");

        uint256 amountLocked = theory.lockOf(player);
        if(amountLocked == 0)
        {
            TheoryUnlockerGen0.setLastUnlockTime(player, block.timestamp);
            TheoryUnlockerGen0.setLastLockAmount(player, amountLocked); //Only update.
            emit Unlock(msg.sender, tokenId, tokenInfo[tokenId].level, 0);
            return;
        }

        uint256 pendingUnlock = theory.canUnlockAmount(player);
        require(amountLocked > pendingUnlock, "Too much to unlock naturally, please call unlock() first."); //Can't update, just revert.

        amountLocked = amountLocked.sub(pendingUnlock); //Amount after unlocking naturally.
        if(!(amountLocked > pastUserInfo.lastLockAmount)) //Can't unlock in good faith. Only time this would happen (currently), the lock rate is 0 anyways.
        {
            theory.unlockForUser(player, 0); //Unlock the natural amount.
            TheoryUnlockerGen0.setLastUnlockTime(player, block.timestamp);
            TheoryUnlockerGen0.setLastLockAmount(player, theory.lockOf(player)); //Update so that the player may unlock in the future.
            emit Unlock(msg.sender, tokenId, tokenInfo[tokenId].level, 0);
            return;
        }

        amountLocked = amountLocked.sub(pastUserInfo.lastLockAmount); //Amount after taking into account amount already unlocked.

        //Amount to unlock = Level% of locked amount calculated above
        uint256 amountToUnlock = amountLocked.mul(tokenInfo[tokenId].level).div(100);

        theory.unlockForUser(player, amountToUnlock);

        TheoryUnlockerGen0.setLastUnlockTime(player, block.timestamp);
        TheoryUnlockerGen0.setLastLockAmount(player, theory.lockOf(player)); //Set to lock amount AFTER unlock. Can only unlock any more locked will be used.
        emit Unlock(msg.sender, tokenId, tokenInfo[tokenId].level, amountToUnlock);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "../../introspection/ERC165.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";
import "../../utils/EnumerableSet.sol";
import "../../utils/EnumerableMap.sol";
import "../../utils/Strings.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || ERC721.isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || ERC721.isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId); // internal owner

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own"); // internal owner
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId); // internal owner
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../math/SafeMath.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

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
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMap {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

   /**
    * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        uint256 keyIndex = map._indexes[key];
        if (keyIndex == 0) return (false, 0); // Equivalent to contains(map, key)
        return (true, map._entries[keyIndex - 1]._value); // All indexes are 1-based
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, "EnumerableMap: nonexistent key"); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./utils/ContractGuard.sol";
import "./interfaces/IBasisAsset.sol";
import "./interfaces/ITreasury.sol";
import "./interfaces/IFarm.sol";
import "./interfaces/IERC20Lockable.sol";
import "./Authorizable.sol";

contract ShareWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20Lockable;

    IERC20Lockable public share;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) public virtual {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        share.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdrawWithFee(uint256 amount, uint256 fee, address feeFund) internal {
        uint256 theoristShare = _balances[msg.sender];
        require(theoristShare >= amount, "Theoretics: withdraw request greater than staked amount");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = theoristShare.sub(amount);
        uint256 feeAmount = amount.mul(fee).div(10000);
        uint256 amountToGive = amount.sub(feeAmount);
        if(feeAmount > 0) share.safeTransfer(feeFund, feeAmount);
        share.safeTransfer(msg.sender, amountToGive);
    }
}

contract Theoretics is ShareWrapper, Authorizable, ContractGuard {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /* ========== DATA STRUCTURES ========== */

    struct TheoristSeat {
        uint256 lastSnapshotIndex;
        uint256 rewardEarned;
        uint256 epochTimerStart;
        uint256 lastDepositBlock;
        uint256 lastWithdrawTime;
        uint256 firstDepositTime;
    }

    struct TheoreticsSnapshot {
        uint256 time;
        uint256 rewardReceived;
        uint256 rewardPerShare;
    }

    /* ========== STATE VARIABLES ========== */

    // flags
    bool public initialized = false;

    IERC20Lockable public game;
    ITreasury public treasury;
    IFarm public farm;

    mapping(address => TheoristSeat) public theorists;
    TheoreticsSnapshot[] public theoreticsHistory;

    uint256 public withdrawLockupEpochs;
    uint256 public rewardLockupEpochs;
    uint256 public pegMaxUnlock; //What TWAP do we have to be at to incur 0% lock?
    uint256 public sameBlockFee;
    uint256[] public feeStagePercentage; //In 10000s for decimal
    uint256[] public feeStageTime;


    /* ========== EVENTS ========== */

    event Initialized(address indexed executor, uint256 at);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward, uint256 lockAmount);
    event RewardAdded(address indexed user, uint256 reward);

    /* ========== Modifiers =============== */

    modifier theoristExists {
        require(balanceOf(msg.sender) > 0, "Theoretics: The theorist does not exist");
        _;
    }

    modifier updateReward(address theorist) {
        if (theorist != address(0)) {
            TheoristSeat memory seat = theorists[theorist];
            seat.rewardEarned = earned(theorist);
            seat.lastSnapshotIndex = latestSnapshotIndex();
            theorists[theorist] = seat;
        }
        _;
    }

    modifier notInitialized {
        require(!initialized, "Theoretics: already initialized");
        _;
    }

    /* ========== GOVERNANCE ========== */

    function initialize(
        IERC20Lockable _game,
        IERC20Lockable _share,
        ITreasury _treasury,
        IFarm _farm
    ) public notInitialized {
        require(_treasury.initialized(), "Treasury must be initialized first.");
        initialized = true;
        game = _game;
        share = _share;
        treasury = _treasury;
        farm = _farm;

        TheoreticsSnapshot memory genesisSnapshot = TheoreticsSnapshot({time : block.number, rewardReceived : 0, rewardPerShare : 0});
        theoreticsHistory.push(genesisSnapshot);

        withdrawLockupEpochs = 6; // Lock for 6 epochs (36h) before release withdraw
        rewardLockupEpochs = 3; // Lock for 3 epochs (18h) before release claimReward

        pegMaxUnlock = treasury.gamePriceOne().mul(4);
        sameBlockFee = 2500;
        feeStageTime = [0, 1 hours, 1 days, 3 days, 5 days, 2 weeks, 4 weeks];
        feeStagePercentage = [800, 400, 200, 100, 50, 25, 1];

        emit Initialized(msg.sender, block.number);
    }

    function setFeeStages(uint256[] memory _feeStageTime, uint256[] memory _feeStagePercentage) public onlyAuthorized() {
        require(_feeStageTime.length > 0
            && _feeStageTime[0] == 0
            && _feeStagePercentage.length == _feeStageTime.length,
            "Fee stage arrays must be equal in non-zero length and time should start at 0.");
        feeStageTime = _feeStageTime;
        uint256 i;
        uint256 len = _feeStagePercentage.length;
        for(i = 0; i < len; i += 1)
        {
            require(_feeStagePercentage[i] <= 800, "Fee can't be higher than 8%.");
        }
        feeStagePercentage = _feeStagePercentage;
    }

    function setSameBlockFee(uint256 _fee) public onlyAuthorized() {
        require(_fee <= 2500, "Fee can't be higher than 25%.");
        sameBlockFee = _fee;
    }

    function getWithdrawFeeOf(address _user) public view returns (uint256)
    {
        TheoristSeat storage user = theorists[_user];
        uint256 fee = sameBlockFee;
        if(block.number != user.lastDepositBlock)
        {
            if (!(user.firstDepositTime > 0)) {
                return feeStagePercentage[0];
            }
            uint256 deltaTime = user.lastWithdrawTime > 0 ?
            block.timestamp - user.lastWithdrawTime :
            block.timestamp - user.firstDepositTime;
            uint256 len = feeStageTime.length;
            uint256 n;
            uint256 i;
            for (n = len; n > 0; n -= 1) {
                i = n-1;
                if(deltaTime >= feeStageTime[i])
                {
                    fee = feeStagePercentage[i];
                    break;
                }
            }
        }
        return fee;
    }

    function setLockUp(uint256 _withdrawLockupEpochs, uint256 _rewardLockupEpochs, uint256 _pegMaxUnlock) external onlyAuthorized onlyOneBlock { // Switched to onlyAuthorized just in case we vote on a new lock up period later. The max is now the default, so this can only help users.
        require(_withdrawLockupEpochs >= _rewardLockupEpochs && _withdrawLockupEpochs <= 6 && _rewardLockupEpochs <= 3, "lockup epochs out of range"); // <= 6 epochs (36 hours)
        require(_pegMaxUnlock > treasury.gamePriceCeiling()
            && _pegMaxUnlock <= treasury.gamePriceOne().mul(4),
            "Max peg unlock must be greater than the GAME ceiling and lower than the price of one GAME times 4.");
        withdrawLockupEpochs = _withdrawLockupEpochs;
        rewardLockupEpochs = _rewardLockupEpochs;
        pegMaxUnlock = _pegMaxUnlock;
    }

    /* ========== VIEW FUNCTIONS ========== */

    // =========== Snapshot getters

    function latestSnapshotIndex() public view returns (uint256) {
        return theoreticsHistory.length.sub(1);
    }

    function getLatestSnapshot() internal view returns (TheoreticsSnapshot memory) {
        return theoreticsHistory[latestSnapshotIndex()];
    }

    function getLastSnapshotIndexOf(address theorist) public view returns (uint256) {
        return theorists[theorist].lastSnapshotIndex;
    }

    function getLastSnapshotOf(address theorist) internal view returns (TheoreticsSnapshot memory) {
        return theoreticsHistory[getLastSnapshotIndexOf(theorist)];
    }

    function canWithdraw(address theorist) external view returns (bool) {
        uint256 fullLock = 100;
        uint256 currentTime = block.timestamp;
        uint256 unlockPercentage = fullLock.sub(farm.getLockPercentage(currentTime > 0 ? currentTime.sub(1) : currentTime, currentTime));
        require(unlockPercentage <= 100, "Invalid unlock percentage, check farm contract."); // Don't worry: The max is not 100.  It is just here for simplicity. I should use assert instead of require but I prefer having the reason there when it asserts.
        return theorists[theorist].epochTimerStart.add(withdrawLockupEpochs.mul(unlockPercentage).div(100)) <= treasury.epoch();
    }

    function epoch() external view returns (uint256) {
        return treasury.epoch();
    }

    function canClaimReward(address theorist) external view returns (bool) {
        uint256 fullLock = 100;
        uint256 currentTime = block.timestamp;
        uint256 unlockPercentage = fullLock.sub(farm.getLockPercentage(currentTime > 0 ? currentTime.sub(1) : currentTime, currentTime));
        require(unlockPercentage <= 100, "Invalid unlock percentage, check farm contract.");
        return theorists[theorist].epochTimerStart.add(rewardLockupEpochs.mul(unlockPercentage).div(100)) <= treasury.epoch();
    }

    function nextEpochPoint() external view returns (uint256) {
        return treasury.nextEpochPoint();
    }

    function getGamePrice() external view returns (uint256) {
        return treasury.getGamePrice();
    }

    // =========== Theorist getters

    function rewardPerShare() public view returns (uint256) {
        return getLatestSnapshot().rewardPerShare;
    }

    function earned(address theorist) public view returns (uint256) {
        uint256 latestRPS = getLatestSnapshot().rewardPerShare;
        uint256 storedRPS = getLastSnapshotOf(theorist).rewardPerShare;

        return balanceOf(theorist).mul(latestRPS.sub(storedRPS)).div(1e18).add(theorists[theorist].rewardEarned);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function reviseDeposit(address _user, uint256 _time) public onlyAuthorized() {
        theorists[_user].firstDepositTime = _time;
    }

    function reviseWithdraw(address _user, uint256 _time) public onlyAuthorized() {
        theorists[_user].lastWithdrawTime = _time;
    }

    function stake(uint256 amount) public override onlyOneBlock updateReward(msg.sender) {
        require(amount > 0, "Theoretics: Cannot stake 0");
        super.stake(amount);
        TheoristSeat storage user = theorists[msg.sender];
        user.epochTimerStart = treasury.epoch(); // reset timer
        user.lastDepositBlock = block.number;
        if (!(user.firstDepositTime > 0)) {
            user.firstDepositTime = block.timestamp;
        }
        emit Staked(msg.sender, amount);
    }

    function getCurrentWithdrawEpochs() public view returns (uint256)
    {
        uint256 fullLock = 100;
        uint256 currentTime = block.timestamp;
        uint256 unlockPercentage = fullLock.sub(farm.getLockPercentage(currentTime > 0 ? currentTime.sub(1) : currentTime, currentTime));
        require(unlockPercentage <= 100, "Invalid unlock percentage, check farm contract.");
        return (withdrawLockupEpochs.mul(unlockPercentage).div(100));
    }

    function getCurrentClaimEpochs() public view returns (uint256)
    {
        uint256 fullLock = 100;
        uint256 currentTime = block.timestamp;
        uint256 unlockPercentage = fullLock.sub(farm.getLockPercentage(currentTime > 0 ? currentTime.sub(1) : currentTime, currentTime));
        require(unlockPercentage <= 100, "Invalid unlock percentage, check farm contract.");
        return (rewardLockupEpochs.mul(unlockPercentage).div(100));
    }

    // TODO: GAS OPTIMIZATION? user can be memory, manipulated, and then stored in theorists storage.
    // For safety reasons, I am not doing this now. I am also not sure if modifying all at once makes a difference.
    function withdraw(uint256 amount) public onlyOneBlock theoristExists updateReward(msg.sender) {
        require(amount > 0, "Theoretics: Cannot withdraw 0");
        uint256 fullLock = 100;
        uint256 currentTime = block.timestamp;
        uint256 unlockPercentage = fullLock.sub(farm.getLockPercentage(currentTime > 0 ? currentTime.sub(1) : currentTime, currentTime));
        require(unlockPercentage <= 100, "Invalid unlock percentage, check farm contract.");
        TheoristSeat storage user = theorists[msg.sender];
        require(user.epochTimerStart.add(withdrawLockupEpochs.mul(unlockPercentage).div(100)) <= treasury.epoch(), "Theoretics: still in withdraw lockup");
        claimReward();
        uint256 fee = sameBlockFee;
        if(block.number != user.lastDepositBlock)
        {
            uint256 deltaTime = user.lastWithdrawTime > 0 ?
            block.timestamp - user.lastWithdrawTime :
            block.timestamp - user.firstDepositTime;
            uint256 len = feeStageTime.length;
            uint256 n;
            uint256 i;
            for (n = len; n > 0; n -= 1) {
                i = n-1;
                if(deltaTime >= feeStageTime[i])
                {
                    fee = feeStagePercentage[i];
                    break;
                }
            }
        }
        user.lastWithdrawTime = block.timestamp;
        withdrawWithFee(amount, fee, treasury.daoFund());
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
    }

    function invLerpPercent95(uint256 _from, uint256 _to, uint _current) internal pure returns (uint256)
    {
        require(_to > _from, "Invalid parameters.");
        if(_current <= _from) return 0;
        if(_current >= _to) return 95;
        return (_current.sub(_from)).mul(95).div(_to.sub(_from));
    }

    function getLockPercentage() public view returns (uint256) {
        uint256 twap = treasury.getGamePrice();
        // By default, GAME is 100% locked for 1 year at <= 1.01, and fully unlocked at >= 2.0
        uint256 fullUnlock = 95;
        uint256 lockPercentage = fullUnlock.sub(invLerpPercent95(treasury.gamePriceCeiling(), pegMaxUnlock, twap));
        require(lockPercentage <= 100, "Invalid lock percentage, check this contract.");
        if (lockPercentage > 95) lockPercentage = 95; // Invalid but not TOO invalid. Okay, I admit, it is so that it stays consistent with all the other requires.
        return lockPercentage;
    }

    function claimReward() public onlyOneBlock updateReward(msg.sender) {
        uint256 reward = theorists[msg.sender].rewardEarned;
        if (reward > 0) {
            uint256 fullLock = 100;
            uint256 currentTime = block.timestamp;
            uint256 unlockPercentage = fullLock.sub(farm.getLockPercentage(currentTime > 0 ? currentTime.sub(1) : currentTime, currentTime));
            require(unlockPercentage <= 100, "Invalid unlock percentage, check farm contract.");
            require(theorists[msg.sender].epochTimerStart.add(rewardLockupEpochs.mul(unlockPercentage).div(100)) <= treasury.epoch(), "Theoretics: still in reward lockup");
            theorists[msg.sender].epochTimerStart = treasury.epoch(); // reset timer
            theorists[msg.sender].rewardEarned = 0;
            game.safeTransfer(msg.sender, reward);
            // GAME can always be locked.
            uint256 lockAmount = 0;
            uint256 lockPercentage = getLockPercentage();
            require(lockPercentage <= 100, "Invalid lock percentage, check this contract.");
            lockAmount = reward.mul(lockPercentage).div(100);
            if(lockAmount > 0) game.lock(msg.sender, lockAmount);
            emit RewardPaid(msg.sender, reward, lockAmount);
        }
    }

    function allocateSeigniorage(uint256 amount) external onlyOneBlock onlyOperator {
        require(amount > 0, "Theoretics: Cannot allocate 0");
        require(totalSupply() > 0, "Theoretics: Cannot allocate when totalSupply is 0");

        // Create & add new snapshot
        uint256 prevRPS = getLatestSnapshot().rewardPerShare;
        uint256 nextRPS = prevRPS.add(amount.mul(1e18).div(totalSupply()));

        TheoreticsSnapshot memory newSnapshot = TheoreticsSnapshot({
            time: block.number,
            rewardReceived: amount,
            rewardPerShare: nextRPS
        });
        theoreticsHistory.push(newSnapshot);

        game.safeTransferFrom(msg.sender, address(this), amount);
        emit RewardAdded(msg.sender, amount);
    }

    function governanceRecoverUnsupported(IERC20 _token, uint256 _amount, address _to) external onlyOperator { //This can remain onlyOperator since we can call this from the Treasury anyways.
        // do not allow to drain core tokens
        require(address(_token) != address(game), "game");
        require(address(_token) != address(share), "share");
        _token.safeTransfer(_to, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IFarm {
    function getLockPercentage(uint256 _from, uint256 _to) external view returns (uint256);
}

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../AuthorizableNoOperator.sol";
import "../interfaces/IERC20Lockable.sol";
import "../utils/ContractGuard.sol";
pragma experimental ABIEncoderV2; //https://docs.soliditylang.org/en/v0.6.9/layout-of-source-files.html?highlight=experimental#abiencoderv2

//When deploying: Every 15 days 5 max levels, max max level is 50. Initial price = 100, buy per level = 500.
contract TheoryUnlocker is ERC721, AuthorizableNoOperator, ContractGuard {
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    Counters.Counter private _tokenIds;

    struct TokenInfo
    {
        uint256 level;
        uint256 creationTime;
        uint256 lastLevelTime;
    }

    mapping(uint256 => TokenInfo) public tokenInfo;

    struct UserInfo
    {
        uint256 lastUnlockTime;
        uint256 lastLockAmount;
    }
    mapping(address => UserInfo) public userInfo;

    uint256[] public levelURIsLevel; // Used like feeStageTime
    string[] public levelURIsURI; // Used like feeStagePercentage
    uint256[] public maxLevelTime; // Used like feeStageTime
    uint256[] public maxLevelLevel; // Used like feeStagePercentage
    IERC20 public buyToken;
    uint256 public initialPrice; //Price for level 1.
    uint256 public buyTokenPerLevel;
    address public communityFund;
    uint256 public timeToLevel;
    IERC20Lockable public theory;
    bool public disableMint; // Limited time only?! Would give more worth in marketplace the for our early investors.

    //Construction
    constructor(IERC20 _buy, uint256 _initialBuy, uint256 _buyPerLevel, IERC20Lockable _theory, address _communityFund, uint256[] memory _maxLevelTime, uint256[] memory _maxLevelLevel, uint256[] memory _levelURIsLevel, string[] memory _levelURIsURI) ERC721("THEORY Unlocker", "TU") public {
        buyToken = _buy;
        initialPrice = _initialBuy;
        buyTokenPerLevel = _buyPerLevel;
        require(_levelURIsLevel.length > 0
        && _levelURIsLevel[0] == 0
            && _levelURIsURI.length == _levelURIsLevel.length,
            "Level URI arrays must be equal in non-zero length and level should start at 0.");
        require(_maxLevelTime.length > 0
        && _maxLevelTime[0] == 0
            && _maxLevelLevel.length == _maxLevelTime.length,
            "Max level arrays must be equal in non-zero length and time should start at 0.");
        uint256 i;
        uint256 len = _maxLevelLevel.length;
        for(i = 0; i < len; i += 1)
        {
            require(_maxLevelLevel[i] <= 100, "Max level can't be higher than 100."); //In practice, this will be 50, but there is no point in making it lower here, does more harm than good.
        }
        levelURIsLevel = _levelURIsLevel;
        levelURIsURI = _levelURIsURI;
        maxLevelTime = _maxLevelTime;
        maxLevelLevel = _maxLevelLevel;
        communityFund = _communityFund;
        timeToLevel = 3 days;
        theory = _theory;
        disableMint = false;
    }

    //Administrative functions
    function setBuyToken(IERC20 _buy) public onlyAuthorized
    {
        buyToken = _buy;
    }

    function setInitialPrice(uint256 _initial) public onlyAuthorized
    {
        initialPrice = _initial;
    }

    function setBuyTokenPerLevel(uint256 _perLevel) public onlyAuthorized
    {
        buyTokenPerLevel = _perLevel;
    }

    function setLevelURIs(uint256[] memory _levelURIsLevel, string[] memory _levelURIsURI) public onlyAuthorized
    {
        require(_levelURIsLevel.length > 0
        && _levelURIsLevel[0] == 0
            && _levelURIsURI.length == _levelURIsLevel.length,
            "Level URI arrays must be equal in non-zero length and level should start at 0.");
        levelURIsLevel = _levelURIsLevel;
        levelURIsURI = _levelURIsURI;
    }

    function setMaxLevel(uint256[] memory _maxLevelTime, uint256[] memory _maxLevelLevel) public onlyAuthorized
    {
        require(_maxLevelTime.length > 0
        && _maxLevelTime[0] == 0
            && _maxLevelLevel.length == _maxLevelTime.length,
            "Max level arrays must be equal in non-zero length and time should start at 0.");
        uint256 i;
        uint256 len = _maxLevelLevel.length;
        for(i = 0; i < len; i += 1)
        {
            require(_maxLevelLevel[i] <= 100, "Max level can't be higher than 100."); //In practice, this will be 50, but there is no point in making it lower here, does more harm than good.
        }
        maxLevelTime = _maxLevelTime;
        maxLevelLevel = _maxLevelLevel;
    }

    function setCommunityFund(address _fund) public onlyAuthorized
    {
        communityFund = _fund;
    }
    //setTheory? //Maybe not, can't think of a reason why we'd need this as THEORY can't be redeployed.
    function setTimeToLevel(uint256 _time) public onlyAuthorized
    {
        timeToLevel = _time;
    }

    function setDisableMint(bool _disable) public onlyAuthorized
    {
        disableMint = _disable;
    }

    function setTokenLevel(uint256 tokenId, uint256 level) public onlyAuthorized
    {
        require(level > 0 && level <= maxLevel(), "Level must be > 0 and <= max level.");
        tokenInfo[tokenId].level = level;
    }

    function setCreationTime(uint256 tokenId, uint256 time) public onlyAuthorized
    {
        tokenInfo[tokenId].creationTime = time;
    }

    function setLastLevelTime(uint256 tokenId, uint256 time) public onlyAuthorized
    {
        tokenInfo[tokenId].lastLevelTime = time;
    }

    function setLastUnlockTime(address user, uint256 time) public onlyAuthorized
    {
        userInfo[user].lastUnlockTime = time;
    }

    function setLastLockAmount(address user, uint256 amount) public onlyAuthorized
    {
        userInfo[user].lastLockAmount = amount;
    }

    //Data functions
    function maxLevel() public view returns (uint256)
    {
        uint256 maxLevel = 0;
        uint256 len = maxLevelTime.length;
        uint256 n;
        uint256 i;
        for (n = len; n > 0; n -= 1) {
            i = n-1;
            if(block.timestamp >= maxLevelTime[i])
            {
                maxLevel = maxLevelLevel[i];
                break;
            }
        }
        return maxLevel;
    }

    function levelURI(uint256 level) public view returns (string memory)
    {
        string memory URI = '';
        uint256 len = levelURIsLevel.length;
        uint256 n;
        uint256 i;
        for (n = len; n > 0; n -= 1) {
            i = n-1;
            if(level >= levelURIsLevel[i])
            {
                URI = levelURIsURI[i];
                break;
            }
        }
        return URI;
    }

    function costOf(uint256 level) external view returns (uint256)
    {
        return initialPrice.add(buyTokenPerLevel.mul(level.sub(1)));
    }

    function timeLeftToLevel(uint256 tokenId) external view returns (uint256)
    {
        uint256 nextLevelTime = tokenInfo[tokenId].lastLevelTime.add(timeToLevel);
        if(block.timestamp >= nextLevelTime)
        {
            return 0;
        }
        return nextLevelTime.sub(block.timestamp);
    }

    function nextLevelTime(uint256 tokenId) external view returns (uint256)
    {
        return tokenInfo[tokenId].lastLevelTime.add(timeToLevel);
    }

    //This or theory.canUnlockAmount > 0? Enable button.
    function canUnlockAmount(address player, uint256 tokenId) external view returns (uint256)
    {
        UserInfo memory user = userInfo[player];

        uint256 amountLocked = theory.lockOf(player);
        if(amountLocked == 0)
        {
            return 0;
        }

        uint256 pendingUnlock = theory.canUnlockAmount(player);
        if(!(amountLocked > pendingUnlock))
        {
            return 0;
        }

        amountLocked = amountLocked.sub(pendingUnlock); //Amount after unlocking naturally.
        if(!(amountLocked > user.lastLockAmount)) //Can't unlock in good faith.
        {
            return 0;
        }

        amountLocked = amountLocked.sub(user.lastLockAmount); //Amount after taking into account amount already unlocked.

        //Amount to unlock = Level% of locked amount calculated above
        uint256 amountToUnlock = amountLocked.mul(tokenInfo[tokenId].level).div(100);

        return amountToUnlock;
    }

    //Core functionality
    function mint(uint256 level) onlyOneBlock public returns (uint256) {
        require(!disableMint, "You can no longer mint this NFT.");
        require(level > 0 && level <= maxLevel(), "Level must be > 0 and <= max level.");
        address player = msg.sender;
        uint256 amount = initialPrice.add(buyTokenPerLevel.mul(level.sub(1)));
        buyToken.safeTransferFrom(msg.sender, communityFund, amount);
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        TokenInfo storage token = tokenInfo[newItemId];
        token.creationTime = block.timestamp;
        token.lastLevelTime = block.timestamp;
        _mint(player, newItemId);
        token.level = level;
        string memory tokenURI = levelURI(level);
        require(bytes(tokenURI).length > 0, "Token URI is invalid.");
        _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }

    //Make sure to have a warning on the website if they try to merge while one of these tokens can level up!
    function merge(uint256 tokenId1, uint256 tokenId2) onlyOneBlock public returns (uint256) {
        require(ownerOf(tokenId1) == msg.sender || authorized[msg.sender] || owner() == msg.sender, "Not enough permissions for token 1.");
        require(ownerOf(tokenId2) == msg.sender || authorized[msg.sender] || owner() == msg.sender, "Not enough permissions for token 2.");
        require(ownerOf(tokenId1) == ownerOf(tokenId2), "Both tokens must have the same owner.");
        uint256 level = tokenInfo[tokenId1].level.add(tokenInfo[tokenId2].level); //Add the two levels together.
        require(level > 0 && level <= maxLevel(), "Level must be > 0 and <= max level.");
        address player = ownerOf(tokenId1);
        string memory tokenURI = tokenURI(tokenId1); //Takes the URI of the FIRST token. Make sure to warn users of this.
        //Burn originals.
        _burn(tokenId1);
        _burn(tokenId2);

        //Mint a new one.
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        TokenInfo storage token = tokenInfo[newItemId];
        token.creationTime = block.timestamp;
        token.lastLevelTime = block.timestamp;
        _mint(player, newItemId);
        token.level = level;
        require(bytes(tokenURI).length > 0, "Token URI is invalid.");
        _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }

    function levelUp(uint256 tokenId) onlyOneBlock public {
        require(ownerOf(tokenId) == msg.sender || authorized[msg.sender] || owner() == msg.sender, "Not enough permissions.");
        TokenInfo storage token = tokenInfo[tokenId];
        require(token.level < maxLevel(), "Level must be lower than max level.");
        uint256 nextLevelTime = token.lastLevelTime.add(timeToLevel);
        require(block.timestamp >= nextLevelTime, "Too early to level up.");

        //Level up.
        //creationTime[newItemId] = block.timestamp; //Same creation time.
        token.lastLevelTime = nextLevelTime;
        //_mint(player, newItemId); //Same ID.
        uint256 level = token.level.add(1);
        token.level = level;
        //string memory tokenURI = levelURI(level);
        //require(bytes(tokenURI).length > 0, "Token URI is invalid.");
        //_setTokenURI(tokenId, tokenURI);
    }

    //Should be called:
    //When lockOf(player) == 0 - Instead of theory.unlock() [disabled on website]
    //When lockOf(player) <= theory.canUnlockAmount(player) - After theory.unlock() [to avoid revert, knew I should have listened to my gut and put a check for the second _unlock]
    //When lockOf(player) > theory.canUnlockAmount(player) - Instead of theory.unlock()
    function nftUnlock(uint256 tokenId) onlyOneBlock public { //Find the best tokenId to use off the blockchain using tokenOfOwnerByIndex and balanceOf
        require(ownerOf(tokenId) == msg.sender || authorized[msg.sender] || owner() == msg.sender, "Not enough permissions.");
        address player = ownerOf(tokenId);
        UserInfo storage user = userInfo[player];
        require(block.timestamp > user.lastUnlockTime, "Logic error.");

        uint256 amountLocked = theory.lockOf(player);
        if(amountLocked == 0)
        {
            user.lastUnlockTime = block.timestamp;
            user.lastLockAmount = amountLocked; //Only update.
            return;
        }

        uint256 pendingUnlock = theory.canUnlockAmount(player);
        require(amountLocked > pendingUnlock, "Too much to unlock naturally, please call unlock() first."); //Can't update, just revert.

        amountLocked = amountLocked.sub(pendingUnlock); //Amount after unlocking naturally.
        if(!(amountLocked > user.lastLockAmount)) //Can't unlock in good faith. Only time this would happen (currently), the lock rate is 0 anyways.
        {
            theory.unlockForUser(player, 0); //Unlock the natural amount.
            user.lastUnlockTime = block.timestamp;
            user.lastLockAmount = theory.lockOf(player); //Update so that the player may unlock in the future.
            return;
        }

        amountLocked = amountLocked.sub(user.lastLockAmount); //Amount after taking into account amount already unlocked.

        //Amount to unlock = Level% of locked amount calculated above
        uint256 amountToUnlock = amountLocked.mul(tokenInfo[tokenId].level).div(100);

        theory.unlockForUser(player, amountToUnlock);

        user.lastUnlockTime = block.timestamp;
        user.lastLockAmount = theory.lockOf(player); //Set to lock amount AFTER unlock. Can only unlock any more locked will be used.
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";

import "./Authorizable.sol";
import "./interfaces/IDistributable.sol";

contract Theory is ERC20Burnable, Authorizable {
    using SafeMath for uint256;

    // TOTAL MAX SUPPLY = farming allocation + 9.24369748% + 8.40336134% THEORYs. This is percentage of the allocations to the farming supply for Tomb Finance (59500 for Tomb, about 308917 for us). This comes out to about 363,431.
    // INITIAL PRICE SHOULD BE LIKE 3SHARES: $26000000/TOTAL_MAX_SUPPLY = $26000000/363432 = approximately $71.54
    uint256 public constant COMMUNITY_FUND_POOL_ALLOCATION = 28555.3529 ether;
    uint256 public constant DEV_FUND_POOL_ALLOCATION = 25959.4118 ether;

    uint256 public constant VESTING_DURATION = 365 days;
    uint256 public startTime;
    uint256 public endTime;

    uint256 public communityFundRewardRate;
    uint256 public devFundRewardRate;

    address public communityFund;
    address public devFund;
    address public distributed;

    uint256 public communityFundLastClaimed;
    uint256 public devFundLastClaimed;

    bool public rewardPoolDistributed = false;

    uint256 private _totalLock;
    uint256 public lockFromTime;
    uint256 public lockToTime;
    mapping(address => bool) public noUnlockBeforeTransfer;

    mapping(address => uint256) private _locks;
    mapping(address => uint256) private _lastUnlockTime;

    // Events.
    event Lock(address indexed to, uint256 value);
    event Unlock(address indexed to, uint256 value);

    constructor(uint256 _startTime, address _communityFund, address _devFund, uint256 _lockFromTime,
        uint256 _lockToTime) public ERC20("THEORY", "Game Theory (gametheory.tech): THEORY Token") {
        _mint(msg.sender, 1 ether); // mint 1 share for initial liquidity pool deployment
        _mint(address(this), COMMUNITY_FUND_POOL_ALLOCATION); // Lock up allocation for community fund. We do this initially so that supply never increases for THEORY, only GAME.
        _mint(address(this), DEV_FUND_POOL_ALLOCATION); // Lock up allocation for dev fund. We do this initially so that supply never increases for THEORY, only GAME.

        startTime = _startTime;
        endTime = startTime + VESTING_DURATION;

        communityFundLastClaimed = startTime;
        devFundLastClaimed = startTime;

        communityFundRewardRate = COMMUNITY_FUND_POOL_ALLOCATION.div(VESTING_DURATION);
        devFundRewardRate = DEV_FUND_POOL_ALLOCATION.div(VESTING_DURATION);

        require(_devFund != address(0), "Address cannot be 0");
        devFund = _devFund;

        //require(_communityFund != address(0), "Address cannot be 0");
        communityFund = _communityFund;

        lockFromTime = _lockFromTime;
        lockToTime = _lockToTime;
    }

    modifier onlyAuthorizedOrDistributed() {
        require(authorized[msg.sender] || owner() == msg.sender || operator() == msg.sender || distributed == msg.sender, "caller is not authorized");
        _;
    }

    function setTreasuryFund(address _communityFund) external {
        require(msg.sender == devFund, "!dev");
        communityFund = _communityFund;
    }

    function setDevFund(address _devFund) external {
        require(msg.sender == devFund, "!dev");
        require(_devFund != address(0), "zero");
        devFund = _devFund;
    }

    function setNoUnlockBeforeTransfer(bool _noUnlockBeforeTransfer) public {
        noUnlockBeforeTransfer[msg.sender] = _noUnlockBeforeTransfer;
    } // If for some reason it is causing problems for a specific user, they can turn it off themselves.

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        if(!noUnlockBeforeTransfer[sender] && _locks[sender] > 0)
        {
            uint256 amountToUnlock = canUnlockAmount(sender);
            _unlock(sender, amountToUnlock);
        }
        super._transfer(sender, recipient, amount);
    }

    function unclaimedTreasuryFund() public view returns (uint256 _pending) {
        uint256 _now = block.timestamp;
        if (_now > endTime) _now = endTime;
        if (communityFundLastClaimed >= _now) return 0;
        _pending = _now.sub(communityFundLastClaimed).mul(communityFundRewardRate);
    }

    function unclaimedDevFund() public view returns (uint256 _pending) {
        uint256 _now = block.timestamp;
        if (_now > endTime) _now = endTime;
        if (devFundLastClaimed >= _now) return 0;
        _pending = _now.sub(devFundLastClaimed).mul(devFundRewardRate);
    }

    /**
     * @dev Claim pending rewards to community and dev fund
     */
    function claimRewards() external {
        uint256 _pending = unclaimedTreasuryFund();
        if (_pending > 0 && communityFund != address(0)) {
            _transfer(address(this), communityFund, _pending);
            communityFundLastClaimed = block.timestamp;
        }
        _pending = unclaimedDevFund();
        if (_pending > 0 && devFund != address(0)) {
            _transfer(address(this), devFund, _pending);
            devFundLastClaimed = block.timestamp;
        }
    }

    /**
     * @notice distribute to reward pool (only once)
     */
    function distributeReward(address _farmingIncentiveFund) external onlyAuthorized { // Can only do this once, so no point in having it be only operator. We can switch to treasury operator before even distributing the reward!
        require(!rewardPoolDistributed, "only can distribute once");
        require(_farmingIncentiveFund != address(0), "!_farmingIncentiveFund");
        rewardPoolDistributed = true;
        distributed = _farmingIncentiveFund;
        _mint(_farmingIncentiveFund, IDistributable(_farmingIncentiveFund).getRequiredAllocation());
    }

    function burn(uint256 amount) public override {
        super.burn(amount);
    }

    function governanceRecoverUnsupported(
        IERC20 _token,
        uint256 _amount,
        address _to
    ) external onlyAuthorized {
        require(msg.sender == operator() || _token != IERC20(this), "Invalid permissions."); // Only the operator can transfer this (though this will probably never be used as the treasury can't call this). We can now recover any tokens accidentally sent to this address.
        _token.transfer(_to, _amount);
    }

    // Update the lockFromTime
    function lockFromUpdate(uint256 _newLockFrom) public onlyAuthorized {
        uint256 lockTime = lockToTime - lockFromTime;
        lockFromTime = _newLockFrom;
        lockToTime = _newLockFrom.add(lockTime); //To respect the 365 day limit, we also change the destination time at the same moment.
    }

    // Update the lockToTime
    function lockToUpdate(uint256 _newLockTo) public onlyAuthorized {
        require(_newLockTo > lockFromTime, "Lock to must be greater than lock from.");
        uint256 lockTime = _newLockTo - lockFromTime;
        require(lockTime <= 365 days, "Lock time must not be greater than 365 days.");
        lockToTime = _newLockTo;
    }

    function totalBalanceOf(address _holder) public view returns (uint256) {
        return _locks[_holder].add(balanceOf(_holder));
    }

    function lockOf(address _holder) public view returns (uint256) {
        return _locks[_holder];
    }

    function lastUnlockTime(address _holder) public view returns (uint256) {
        return _lastUnlockTime[_holder];
    }

    function totalLock() public view returns (uint256) {
        return _totalLock;
    }

    function unlockedSupply() public view returns (uint256) {
        return totalSupply().sub(_totalLock);
    }

    function lockedSupply() public view returns (uint256) {
        return totalLock();
    }

    function circulatingSupply() public view returns (uint256) {
        return totalSupply().sub(balanceOf(distributed));
    }

    function lock(address _holder, uint256 _amount) public onlyAuthorizedOrDistributed {
        require(_holder != address(0), "Cannot lock to the zero address");
        require(_amount <= balanceOf(_holder), "Lock amount over balance");
        require(msg.sender == operator() || msg.sender == distributed || _locks[_holder].add(_amount) <= totalBalanceOf(_holder).mul(95).div(100), "Lock amount over 95% of total balance");

        if(noUnlockBeforeTransfer[_holder] && _locks[_holder] > 0) //Before we lock more, make sure we unlock everything we can, even if noUnlockBeforeTransfer is set.
        {
            uint256 amount = canUnlockAmount(_holder);
            _unlock(_holder, amount);
        }

        _transfer(_holder, address(this), _amount);

        _locks[_holder] = _locks[_holder].add(_amount);
        _totalLock = _totalLock.add(_amount);
        if (_lastUnlockTime[_holder] < lockFromTime) {
            _lastUnlockTime[_holder] = lockFromTime;
        }
        emit Lock(_holder, _amount);
    }

    function canUnlockAmount(address _holder) public view returns (uint256) {
        if (block.timestamp <= lockFromTime) {
            return 0;
        } else if (block.timestamp >= lockToTime) {
            return _locks[_holder];
        } else {
            uint256 releaseTime = block.timestamp.sub(_lastUnlockTime[_holder]);
            uint256 numberLockTime = lockToTime.sub(_lastUnlockTime[_holder]);
            return _locks[_holder].mul(releaseTime).div(numberLockTime);
        }
    }

    // Unlocks some locked tokens immediately.
    function unlockForUser(address account, uint256 amount) public onlyAuthorized {
        // First we need to unlock all tokens the address is eligible for.
        uint256 pendingLocked = canUnlockAmount(account);
        if (pendingLocked > 0) {
            _unlock(account, pendingLocked);
        }

        // Now that that's done, we can unlock the extra amount passed in.
        _unlock(account, amount);
    }

    function unlock() public {
        uint256 amount = canUnlockAmount(msg.sender);
        _unlock(msg.sender, amount);
    }

    function _unlock(address holder, uint256 amount) internal {
        require(_locks[holder] > 0, "Insufficient locked tokens");

        // Make sure they aren't trying to unlock more than they have locked.
        if (amount > _locks[holder]) {
            amount = _locks[holder];
        }

        // If the amount is greater than the total balance, set it to max.
        if (amount > balanceOf(address(this))) {
            amount = balanceOf(address(this));
        }
        _transfer(address(this), holder, amount);
        _locks[holder] = _locks[holder].sub(amount);
        _lastUnlockTime[holder] = block.timestamp;
        _totalLock = _totalLock.sub(amount);

        emit Unlock(holder, amount);
    }

    // This function is for dev address migrate all balance to a multi sig address
//    function transferAll(address _to) public onlyAuthorized {
//        _locks[_to] = _locks[_to].add(_locks[msg.sender]);
//
//        if (_lastUnlockTime[_to] < lockFromTime) {
//            _lastUnlockTime[_to] = lockFromTime;
//        }
//
//        if (_lastUnlockTime[_to] < _lastUnlockTime[msg.sender]) {
//            _lastUnlockTime[_to] = _lastUnlockTime[msg.sender];
//        }
//
//        _locks[msg.sender] = 0;
//        _lastUnlockTime[msg.sender] = 0;
//
//        _transfer(msg.sender, _to, balanceOf(msg.sender));
//    }
    // Actually, we don't need this anymore. We're vested but the vested amount isn't locked in the same way as DeFi Kingdoms.
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./ERC20.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    using SafeMath for uint256;

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/math/Math.sol";

import "./lib/SafeMath8.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/ITreasury.sol";
import "./Authorizable.sol";
import "./interfaces/IDistributable.sol";

contract Game is ERC20Burnable, Operator, Authorizable {
    using SafeMath8 for uint8;
    using SafeMath for uint256;

    // Have the rewards been distributed to the pools
    bool public rewardPoolDistributed = false;
    address public distributed;
    address public theoretics;

    uint256 private _totalLock;
    uint256 public lockTime;
    mapping(address => uint256) public lockFromTime;
    mapping(address => bool) public noUnlockBeforeTransfer;

    mapping(address => uint256) private _locks;
    mapping(address => uint256) private _lastUnlockTime;

    // Events.
    event Lock(address indexed to, uint256 value);
    event Unlock(address indexed to, uint256 value);

    /**
     * @notice Constructs the GAME ERC-20 contract.
     */
    constructor() public ERC20("GAME", "Game Theory (gametheory.tech): GAME Token") {
        // Mints 1 GAME to contract creator for initial pool setup

        lockTime = 365 days;
        _mint(msg.sender, 1 ether); // mint 1 GAME for initial liquidity pool deployment
    }

    modifier onlyAuthorizedOrTheoretics() {
        require(authorized[msg.sender] || owner() == msg.sender || operator() == msg.sender || theoretics == msg.sender, "caller is not authorized");
        _;
    }

    function setLockTime(uint256 _lockTime) public onlyAuthorized {
        require(_lockTime <= 365 days, "Lock time must not be greater than 365 days.");
        lockTime = _lockTime;
    }

    function doesNotUnlockBeforeTransfer(address _user) external view returns (bool) {
        return noUnlockBeforeTransfer[_user];
    }

    function setNoUnlockBeforeTransfer(bool _noUnlockBeforeTransfer) external {
        noUnlockBeforeTransfer[msg.sender] = _noUnlockBeforeTransfer;
    } // If for some reason it is causing problems for a specific user, they can turn it off themselves.

    /**
     * @notice Operator mints GAME to a recipient
     * @param recipient_ The address of recipient
     * @param amount_ The amount of GAME to mint to
     * @return whether the process has been done
     */
    function mint(address recipient_, uint256 amount_) public onlyOperator returns (bool) {
        uint256 balanceBefore = balanceOf(recipient_);
        _mint(recipient_, amount_);
        uint256 balanceAfter = balanceOf(recipient_);

        return balanceAfter > balanceBefore;
    }

    function burn(uint256 amount) public override {
        super.burn(amount);
    }

    function burnFrom(address account, uint256 amount) public override onlyOperator {
        super.burnFrom(account, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        if(!noUnlockBeforeTransfer[sender] && _locks[sender] > 0)
        {
            uint256 amountToUnlock = canUnlockAmount(sender);
            _unlock(sender, amountToUnlock);
        }
        super._transfer(sender, recipient, amount);
    }

    /**
     * @notice distribute to reward pool (only once)
     */
    function distributeReward(
        address _genesisPool,
        address _theoretics
    ) external onlyAuthorized { // Can only do this once, so no point in having it be only operator. We can switch to treasury operator before even distributing the reward!
        require(!rewardPoolDistributed, "only can distribute once");
        require(_genesisPool != address(0), "!_genesisPool");
        require(_theoretics != address(0), "!_theoretics");
        rewardPoolDistributed = true;
        distributed = _genesisPool;
        theoretics = _theoretics;
        _mint(_genesisPool, IDistributable(_genesisPool).getRequiredAllocation());
    }

    function governanceRecoverUnsupported(
        IERC20 _token,
        uint256 _amount,
        address _to
    ) external onlyAuthorized {
        require(msg.sender == operator() || _token != IERC20(this), "Invalid permissions."); // Only the operator can transfer this (though this will probably never be used). We can now recover any tokens accidentally sent to this address.
        _token.transfer(_to, _amount);
    }

    // Update the lockFromTime
    function lockFromUpdate(address _holder, uint256 _newLockFrom) public onlyAuthorized {
        lockFromTime[_holder] = _newLockFrom;
    }

    function getLockFromTime(address _holder) public view returns (uint256) {
        return lockFromTime[_holder];
    }

    function totalBalanceOf(address _holder) public view returns (uint256) {
        return _locks[_holder].add(balanceOf(_holder));
    }

    function lockOf(address _holder) public view returns (uint256) {
        return _locks[_holder];
    }

    function lastUnlockTime(address _holder) public view returns (uint256) {
        return _lastUnlockTime[_holder];
    }

    function unlockedSupply() public view returns (uint256) {
        return totalSupply().sub(_totalLock);
    }

    function lockedSupply() public view returns (uint256) {
        return totalLock();
    }

    function circulatingSupply() public view returns (uint256) {
        return totalSupply().sub(balanceOf(distributed));
    }

    function totalLock() public view returns (uint256) {
        return _totalLock;
    }

    function lock(address _holder, uint256 _amount) public onlyAuthorizedOrTheoretics { // Genesis pool can't lock, so distributed doesn't need rights. Also, only operator is allowed to lock more than 95% (to prevent accidental deadlocks and abuse).
        require(_holder != address(0), "Cannot lock to the zero address");
        require(_amount <= balanceOf(_holder), "Lock amount over balance");
        require(msg.sender == operator() || msg.sender == theoretics || _locks[_holder].add(_amount) <= totalBalanceOf(_holder).mul(95).div(100), "Lock amount over 95% of total balance");

        if(noUnlockBeforeTransfer[_holder] && _locks[_holder] > 0) //Before we lock more, make sure we unlock everything we can, even if noUnlockBeforeTransfer is set.
        {
            uint256 amount = canUnlockAmount(_holder);
            _unlock(_holder, amount);
        }

        uint256 _lockFromTime = block.timestamp;
        lockFromTime[_holder] = _lockFromTime;

        _transfer(_holder, address(this), _amount);

        _locks[_holder] = _locks[_holder].add(_amount);
        _totalLock = _totalLock.add(_amount);
        if (_lastUnlockTime[_holder] < lockFromTime[_holder]) {
            _lastUnlockTime[_holder] = lockFromTime[_holder];
        }
        emit Lock(_holder, _amount);
    }

    function canUnlockAmount(address _holder) public view returns (uint256) {
        if (block.timestamp <= lockFromTime[_holder]) {
            return 0;
        } else if (block.timestamp >= lockFromTime[_holder].add(lockTime)) {
            return _locks[_holder];
        } else {
            uint256 releaseTime = block.timestamp.sub(_lastUnlockTime[_holder]);
            uint256 numberLockTime = lockFromTime[_holder].add(lockTime).sub(_lastUnlockTime[_holder]);
            return _locks[_holder].mul(releaseTime).div(numberLockTime);
        }
    }

    // Unlocks some locked tokens immediately. This could be used for NFTs or promotional periods.
    function unlockForUser(address account, uint256 amount) public onlyAuthorized {
        // First we need to unlock all tokens the address is eligible for.
        uint256 pendingLocked = canUnlockAmount(account);
        if (pendingLocked > 0) {
            _unlock(account, pendingLocked);
        }

        // Now that that's done, we can unlock the extra amount passed in.
        _unlock(account, amount);
    }

    function unlock() public {
        uint256 amount = canUnlockAmount(msg.sender);
        _unlock(msg.sender, amount);
    }

    function _unlock(address holder, uint256 amount) internal {
        require(_locks[holder] > 0, "Insufficient locked tokens");

        // Make sure they aren't trying to unlock more than they have locked.
        if (amount > _locks[holder]) {
            amount = _locks[holder];
        }

        // If the amount is greater than the total balance, set it to max.
        if (amount > balanceOf(address(this))) {
            amount = balanceOf(address(this));
        }
        _transfer(address(this), holder, amount);
        _locks[holder] = _locks[holder].sub(amount);
        _lastUnlockTime[holder] = block.timestamp;
        _totalLock = _totalLock.sub(amount);

        emit Unlock(holder, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath8 {
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
    function add(uint8 a, uint8 b) internal pure returns (uint8) {
        uint8 c = a + b;
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
    function sub(uint8 a, uint8 b) internal pure returns (uint8) {
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
    function sub(uint8 a, uint8 b, string memory errorMessage) internal pure returns (uint8) {
        require(b <= a, errorMessage);
        uint8 c = a - b;

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
    function mul(uint8 a, uint8 b) internal pure returns (uint8) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint8 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint8 a, uint8 b) internal pure returns (uint8) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint8 a, uint8 b, string memory errorMessage) internal pure returns (uint8) {
        require(b > 0, errorMessage);
        uint8 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint8 a, uint8 b) internal pure returns (uint8) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint8 a, uint8 b, string memory errorMessage) internal pure returns (uint8) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20Snapshot.sol";
import "./AuthorizableNoOperator.sol";
import "./interfaces/IERC20Lockable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./interfaces/ITheoretics.sol";
import "./utils/ContractGuard.sol";
import "./interfaces/ITreasury.sol";

contract Master is ERC20Snapshot, AuthorizableNoOperator, ContractGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20Lockable;
    using SafeERC20 for IERC20;


    struct UserInfo
    {
        uint256 lockToTime;
        uint256 chosenLockTime;
        address approveTransferFrom;
        uint256 lastSnapshotIndex;
        uint256 rewardEarned;
        uint256 withdrawRequestedInMaster;
        uint256 withdrawRequestedInTheory;
        uint256 lastStakeRequestBlock;
        uint256 lastWithdrawRequestBlock;
        uint256 gameLocked;
        uint256 gameLockFrom;
        uint256 gameLastUnlockTime;
    }

    mapping(address => UserInfo) public userInfo;
    IERC20Lockable private theory;
    IERC20Lockable private game;
    ITheoretics private theoretics;
    ITreasury private treasury;
    uint256 public minLockTime;
    uint256 public unlockedClaimPenalty;

    //uint256 public extraTheoryAdded;
    //uint256 public extraTheoryStakeRequested;
    //uint256 public extraTheoryWithdrawRequested;

    uint256 public totalStakeRequestedInTheory;
    uint256 public totalWithdrawRequestedInTheory;
    uint256 public totalWithdrawRequestedInMaster;
    uint256 public totalWithdrawUnclaimedInTheory;
    uint256 public totalGameUnclaimed;
    uint256 private lastInitiatePart1Epoch;
    uint256 private lastInitiatePart2Epoch;
    uint256 private lastInitiatePart1Block;
    uint256 private lastInitiatePart2Block;
    uint256 public totalGameLocked;
    struct MasterSnapshot {
        uint256 time;
        uint256 rewardReceived;
        uint256 rewardPerShare;
    }
    MasterSnapshot[] public masterHistory;
    address[] private whitelistedTokens;
    bool private emergencyUnlock;


    event RewardPaid(address indexed user, uint256 reward, uint256 lockAmount);
    event Deposit(address indexed user, uint256 amountInTheory, uint256 amountOutMaster);
    event Withdraw(address indexed user, uint256 amountInMaster, uint256 amountOutTheory);
    event WithdrawRequest(address indexed user, uint256 amountInMaster, uint256 amountOutTheory);
    event LockGame(address indexed to, uint256 value);
    event UnlockGame(address indexed to, uint256 value);

    //Permissions needed: game (Game)
    constructor(IERC20Lockable _theory,
                IERC20Lockable _game,
                ITheoretics _theoretics,
                ITreasury _treasury,
                address[] memory _whitelist) public ERC20("Master Token", "MASTER") {
        theory = _theory;
        game = _game;
        theoretics = _theoretics;
        treasury = _treasury;
        minLockTime = 365 days;
        unlockedClaimPenalty = 30 days;
        MasterSnapshot memory genesisSnapshot = MasterSnapshot({time : block.number, rewardReceived : 0, rewardPerShare : 0});
        masterHistory.push(genesisSnapshot);
        whitelistedTokens = _whitelist;
    }


    //View functions
    //For THEORY -> MASTER (forked from https://github.com/DefiKingdoms/contracts/blob/main/contracts/Bank.sol)
    function theoryToMaster(uint256 _amount) public view returns (uint256)
    {
        // Gets the amount of GovernanceToken locked in the contract
        uint256 totalGovernanceToken = theoretics.balanceOf(address(this)).add(totalStakeRequestedInTheory);
        // Gets the amount of xGovernanceToken in existence
        uint256 totalShares = totalSupply();
        // If no xGovernanceToken exists, it is 1:1
        if (totalShares == 0 || totalGovernanceToken == 0) {
            return _amount;
        }
        // Calculates the amount of xGovernanceToken the GovernanceToken is worth. The ratio will change overtime, as xGovernanceToken is burned/minted and GovernanceToken deposited + gained from fees / withdrawn.
        uint256 what = _amount.mul(totalShares).div(totalGovernanceToken);
        return what;
    }

    //For MASTER -> THEORY (forked from https://github.com/DefiKingdoms/contracts/blob/main/contracts/Bank.sol)
    function masterToTheory(uint256 _share) public view returns (uint256)
    {
        // Gets the amount of GovernanceToken locked in the contract
        uint256 totalGovernanceToken = theoretics.balanceOf(address(this)).add(totalStakeRequestedInTheory);
        // Gets the amount of xGovernanceToken in existence
        uint256 totalShares = totalSupply();
        // If no xGovernanceToken exists, it is 1:1
        if (totalShares == 0 || totalGovernanceToken == 0) {
            return _share;
        }
        // Calculates the amount of GovernanceToken the xGovernanceToken is worth
        uint256 what = _share.mul(totalGovernanceToken).div(totalShares);
        return what;
    }

    //Snapshot

    // =========== Snapshot getters

    function latestSnapshotIndex() public view returns (uint256) {
        return masterHistory.length.sub(1);
    }

    function getLatestSnapshot() internal view returns (MasterSnapshot memory) {
        return masterHistory[latestSnapshotIndex()];
    }

    function getLastSnapshotIndexOf(address theorist) public view returns (uint256) {
        return userInfo[theorist].lastSnapshotIndex;
    }

    function getLastSnapshotOf(address theorist) internal view returns (MasterSnapshot memory) {
        return masterHistory[getLastSnapshotIndexOf(theorist)];
    }

    function earned(address theorist) public view returns (uint256) {
        uint256 latestRPS = getLatestSnapshot().rewardPerShare;
        uint256 storedRPS = getLastSnapshotOf(theorist).rewardPerShare;

        return balanceOf(theorist).mul(latestRPS.sub(storedRPS)).div(1e18).add(userInfo[theorist].rewardEarned);
    }

    function canUnlockAmountGame(address _holder) public view returns (uint256) {
        uint256 lockTime = game.lockTime();
        UserInfo memory user = userInfo[_holder];
        if (block.timestamp <= user.gameLockFrom) {
            return 0;
        } else if (block.timestamp >= user.gameLockFrom.add(lockTime)) {
            return user.gameLocked;
        } else {
            uint256 releaseTime = block.timestamp.sub(user.gameLastUnlockTime);
            uint256 numberLockTime = user.gameLockFrom.add(lockTime).sub(user.gameLastUnlockTime);
            return user.gameLocked.mul(releaseTime).div(numberLockTime);
        }
    }

    function totalCanUnlockAmountGame(address _holder) external view returns (uint256) {
       return game.canUnlockAmount(_holder).add(canUnlockAmountGame(_holder));
    }

    function totalBalanceOfGame(address _holder) external view returns (uint256) {
        return userInfo[_holder].gameLocked.add(game.totalBalanceOf(_holder));
    }

    function lockOfGame(address _holder) external view returns (uint256) {
        return game.lockOf(_holder).add(userInfo[_holder].gameLocked);
    }

    function totalLockGame() external view returns (uint256) {
        return totalGameLocked.add(game.totalLock());
    }

    //Modifiers
    modifier updateReward(address theorist) {
        if (theorist != address(0)) {
            UserInfo memory user = userInfo[theorist];
            user.rewardEarned = earned(theorist);
            user.lastSnapshotIndex = latestSnapshotIndex();
            userInfo[theorist] = user;
        }
        _;
    }

    //Admin functions
    function setAdmin(uint256 lockTime, uint256 penalty, bool emergency) external onlyAuthorized
    {
        //Default: 1 year/365 days
        //Lock time too high.
        require(lockTime <= 730 days, "LT"); //730 days/2 years = length from beginning of emissions to full LTHEORY unlock.  No need to be higher than that.
        //Penalty too high.
        require(penalty <= lockTime, "PT"); //No higher than lock time.
        minLockTime = lockTime;
        unlockedClaimPenalty = penalty;
        emergencyUnlock = emergency;
    }

    function unlockGameForUser(address account, uint256 amount) public onlyAuthorized {
        // First we need to unlock all tokens the address is eligible for.
        uint256 pendingLocked = canUnlockAmountGame(account);
        if (pendingLocked > 0) {
            _unlockGame(account, pendingLocked);
        }

        // Then unlock GAME in the Game contract
        uint256 pendingLockOf = game.lockOf(account); //Lock before
        if (pendingLockOf > game.canUnlockAmount(msg.sender))
        {
            game.unlockForUser(account, 0); //Unlock amount naturally first.
            pendingLockOf = game.lockOf(account);
        }
        if(pendingLockOf > 0)
        {
            game.unlockForUser(account, amount);
            uint256 amountUnlocked = pendingLockOf.sub(game.lockOf(account)); //Lock before - lock after
            if(amount > amountUnlocked) amount = amount.sub(amountUnlocked); //Don't unlock the amount already unlocked
            else amount = 0; // <= 0? = 0
        }

        // Now that that's done, we can unlock the extra amount passed in.
        if(amount > 0 && userInfo[account].gameLocked > 0) _unlockGame(account, amount);
    }

    //Not required as no payable function.
//    function transferFTM(address payable to, uint256 amount) external onlyAuthorized onlyOneBlock
//    {
//        to.transfer(amount);
//    }

    function transferToken(IERC20 _token, address to, uint256 amount) external onlyAuthorized {
        //Required in order move MASTER and other tokens if they get stuck in the contract.
        //Some security measures in place for MASTER and THEORY.
        require(address(_token) != address(this) || amount <= balanceOf(address(this)).sub(totalWithdrawRequestedInMaster), "AF"); //Cannot transfer more than accidental funds.
        //require(address(_token) != address(theory) || amount <= theory.balanceOf(address(this)).sub(totalStakeRequested.add(totalWithdrawUnclaimed)), "Cannot withdraw pending funds."); //To prevent a number of issues that crop up when extra THEORY is removed, this function as been disabled. THEORY sent here is essentially donated to MASTER if staked. Otherwise, it is out of circulation.
        require(address(_token) != address(theory), "MP-"); //Cannot bring down price of MASTER.
        require(address(_token) != address(game) || amount <= game.balanceOf(address(this)).sub(totalGameUnclaimed).sub(totalGameLocked), "AF"); //Cannot transfer more than accidental funds.
        //WHITELIST BEGIN (Initiated in constructor due to contract size limits)
        bool isInList = false;
        uint256 i;
        uint256 len = whitelistedTokens.length;
        for(i = 0; i < len; ++i)
        {
            if(address(_token) == whitelistedTokens[i])
            {
                isInList = true;
                break;
            }
        }
        require(address(_token) == address(this) //MASTER
            || address(_token) == address(game) //GAME
            || isInList, "WL"); //Can only transfer whitelisted tokens.

        //WHITELIST END
        _token.safeTransfer(to, amount);
    }

    function stakeExternalTheory(uint256 amount) external onlyAuthorized onlyOneBlock {
        require(amount <= theory.balanceOf(address(this)).sub(totalStakeRequestedInTheory.add(totalWithdrawUnclaimedInTheory)), "PF"); //Cannot stake pending funds.
        if(lastInitiatePart2Epoch == theoretics.epoch() || theoretics.getCurrentWithdrawEpochs() == 0)
        {
            //extraTheoryAdded = extraTheoryAdded.add(amount); //Track extra theory that we will stake immediately.
            theory.safeApprove(address(theoretics), 0);
            theory.safeApprove(address(theoretics), amount);
            theoretics.stake(amount); //Stake if we already have staked this epoch or are at 0 withdraw epochs.
        }
        else
        {
            totalStakeRequestedInTheory = totalStakeRequestedInTheory.add(amount);
            //extraTheoryStakeRequested = extraTheoryStakeRequested.add(amount);
        }
    }

    //To prevent a number of issues that crop up when extra THEORY is removed, this function as been disabled. THEORY sent here is instead shared amongst the holders.
//    function withdrawExternalTheory(uint256 amount) external onlyAuthorized onlyOneBlock {
//        //This doesn't prevent all damage to people who got in after 1.0x, but it prevents a full withdrawal.
//        require(amount >= extraTheoryAdded, "Can't withdraw past 1.0x.");
//        extraTheoryAdded = extraTheoryAdded.sub(amount); //Subtract early so we don't go over max amount.
//        extraTheoryWithdrawRequested = extraTheoryWithdrawRequested.add(amount);
//    }

    //Internal functions

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal updateReward(from) updateReward(to) virtual override {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal virtual override {
        address daoFund = treasury.daoFund();
        address own = owner();
        UserInfo storage user = userInfo[to];
        if(user.lockToTime == 0 || !(authorized[msg.sender] || own == msg.sender || daoFund == msg.sender || address(this) == msg.sender
        || authorized[from] || own == from || daoFund == from || address(this) == from
        || authorized[to] || own == to || daoFund == to || address(this) == to))
        {
            require(user.lockToTime == 0 || user.approveTransferFrom == from, "Receiver did not approve transfer.");
            user.approveTransferFrom = address(0);
            uint256 nextTime = block.timestamp.add(minLockTime);
            if(nextTime > user.lockToTime) user.lockToTime = nextTime;
        }
        super._transfer(from, to, amount);

    }

    function lockGame(address _holder, uint256 _amount) internal
    {
        UserInfo storage user = userInfo[_holder];
        uint256 amount = canUnlockAmountGame(_holder);

        if(user.gameLocked > 0) _unlockGame(_holder, amount); //Before we lock more, make sure we unlock everything we can, even if noUnlockBeforeTransfer is set.

        uint256 _lockFromTime = block.timestamp;
        user.gameLockFrom = _lockFromTime;

        user.gameLocked = user.gameLocked.add(_amount);
        totalGameLocked = totalGameLocked.add(_amount);
        if (user.gameLastUnlockTime < user.gameLockFrom) {
            user.gameLastUnlockTime = user.gameLockFrom;
        }
        emit LockGame(_holder, _amount);
    }

    function _unlockGame(address holder, uint256 amount) internal {
        UserInfo storage user = userInfo[holder];
        require(user.gameLocked > 0, "ILT"); //Insufficient locked tokens

        // Make sure they aren't trying to unlock more than they have locked.
        if (amount > user.gameLocked) {
            amount = user.gameLocked;
        }

        // If the amount is greater than the total balance, set it to max.
        if (amount > totalGameLocked) {
            amount = totalGameLocked;
        }
        game.safeTransfer(holder, amount);
        user.gameLocked = user.gameLocked.sub(amount);
        user.gameLastUnlockTime = block.timestamp;
        totalGameLocked = totalGameLocked.sub(amount);

        emit UnlockGame(holder, amount);
    }
    function _claimGame() internal
    {
        uint256 reward = userInfo[msg.sender].rewardEarned;
        if (reward > 0) {
            userInfo[msg.sender].rewardEarned = 0;
            totalGameUnclaimed = totalGameUnclaimed.sub(reward);
            // GAME can always be locked.
            uint256 lockAmount = 0;
            uint256 lockPercentage = theoretics.getLockPercentage();
            require(lockPercentage <= 100, "LP"); //Invalid lock percentage, check Theoretics contract.
            lockAmount = reward.mul(lockPercentage).div(100);
            //if(lockAmount > 0) game.lock(msg.sender, lockAmount); //Due to security measures, this won't work. We have to make separate LGAME.
            lockGame(msg.sender, lockAmount);
            game.safeTransfer(msg.sender, reward.sub(lockAmount));
            emit RewardPaid(msg.sender, reward, lockAmount);
        }
    }

    function _initiatePart1(bool allowEmergency) internal
    {
        //Unlock all LGAME, transfer GAME, then relock at normal rate.
        uint256 initialBalance = game.totalBalanceOf(address(this));
        //uint256 _withdrawLockupEpochs = theoretics.withdrawLockupEpochs();
        //uint256 _rewardLockupEpochs = theoretics.rewardLockupEpochs();
        //uint256 _pegMaxUnlock = theoretics.pegMaxUnlock();
        //theoretics.setLockUp(0, 0, _pegMaxUnlock); //Can't use these because of onlyOneBlock.

        //We may have had a saving grace: But we do have a saving grace: farm.getLockPercentage(). If that is at 95%, then we have 0 lockups.
        //But I was TOO anal about security: The function returns 0 after the pool ends, no matter what.

        //Instead, we must limit claiming and staking to every getCurrentWithdrawEpochs() epochs with a window of 5 hours and 30 minutes (you can request at any time, but it will execute once after this window).
        //Instead of withdrawing/claiming from theoretics here, we store withdraw requests and withdraw the full amount for everybody at once after 5 hours and 30 minutes.
        //If there are no withdraw requests, just claim and stake instead of withdrawing and staking. If there are no claim/withdraw requests, just stake. If there are no stake requests, fail the function.
        //The user can then come back at any time after to receive their withdraw/claim.
        //If getCurrentWithdrawEpochs() is 0, just call the initiator function immediately.

        if(totalWithdrawRequestedInMaster != 0)
        {
            //Burn requested master so price remains the same.
            _burn(address(this), totalWithdrawRequestedInMaster);
            totalWithdrawRequestedInMaster = 0;
        }

        if(totalWithdrawRequestedInTheory
        //.add(extraTheoryWithdrawRequested)
            == 0) theoretics.claimReward();
        else
        {
            uint256 initialBalanceTheory = theory.balanceOf(address(this));

            uint256 what = totalWithdrawRequestedInTheory
            //.add(extraTheoryWithdrawRequested);
            ;
            totalWithdrawRequestedInTheory = 0;

            //Now that I think about it, we could probably do something like this to burn immediately and avoid delayed prices altogether. But it is getting too complicated, and the current system helps MASTER holders anyways.
            if(what > totalStakeRequestedInTheory) //Withdraw > Stake: Only withdraw. We need a bit more to pay our debt.
            {
                what = what.sub(totalStakeRequestedInTheory); //Withdraw less to handle "stake". Reserves (staked amount chilling in the contract) will cover some of our debt (requested withdraws).
                totalStakeRequestedInTheory = 0; //Don't stake in part 2 anymore, as it was already technically "staked" here.
            }
            else //Stake >= Withdraw: Only stake or do nothing. We have enough THEORY in our reserves to support all the withdraws.
            {
                totalStakeRequestedInTheory = totalStakeRequestedInTheory.sub(what); //Stake less to handle "withdraw". Reserves (staked amount chilling in the contract) will cover all of our debt (requested withdraws). Stake the remaining reserves here, if any.
                what = 0; //Don't withdraw in part 1 anymore, it was already "withdrawn" here.
            }

            if(what > 0)
            {
                theoretics.withdraw(what);

                uint256 newBalanceTheory = theory.balanceOf(address(this));
                uint256 whatAfterWithdrawFee = newBalanceTheory.sub(initialBalanceTheory);

                uint256 withdrawFee = what.sub(whatAfterWithdrawFee);
                address daoFund = treasury.daoFund();
                if(!allowEmergency || withdrawFee > 0 && theory.allowance(daoFund, address(this)) >= withdrawFee) theory.safeTransferFrom(daoFund, address(this), withdrawFee); //Send withdraw fee back to us. Don't allow this function to hold up funds.

    //            if(extraTheoryWithdrawRequested > 0)
    //            {
    //                theory.safeTransfer(treasury.daoFund(), extraTheoryWithdrawRequested);
    //                extraTheoryWithdrawRequested = 0;
    //            }
            }
            else
            {
                theoretics.claimReward(); //Claim.
            }
        }
        //theoretics.setLockUp(_withdrawLockupEpochs, _rewardLockupEpochs, _pegMaxUnlock);
        //Unlock
        uint256 extraLocked = game.lockOf(address(this)).sub(game.canUnlockAmount(address(this)));
        if(extraLocked > 0)
        {
            game.unlockForUser(address(this), extraLocked);
        }
        uint256 newBalance = game.totalBalanceOf(address(this));
        uint256 amount = newBalance.sub(initialBalance);
        totalGameUnclaimed = totalGameUnclaimed.add(amount);

        //Calculate amount to earn
        // Create & add new snapshot
        uint256 prevRPS = getLatestSnapshot().rewardPerShare;
        uint256 supply = totalSupply();
        //Nobody earns any GAME if everyone withdraws. If that's the case, all GAME goes to the treasury's daoFund.
        uint256 nextRPS = supply == 0 ? prevRPS : prevRPS.add(amount.mul(1e18).div(supply)); //Otherwise, GAME is distributed amongst those who have not yet burned their MASTER.

        if(supply == 0)
        {
            game.safeTransfer(treasury.daoFund(), amount);
        }

        MasterSnapshot memory newSnapshot = MasterSnapshot({
        time: block.number,
        rewardReceived: amount,
        rewardPerShare: nextRPS
        });
        masterHistory.push(newSnapshot);

        lastInitiatePart1Epoch = theoretics.epoch();
        lastInitiatePart1Block = block.number;
    }

    function _sellToTheory() internal
    {
        UserInfo storage user = userInfo[msg.sender];
        //require(block.timestamp >= user.lockToTime, "Still locked!"); //Allow locked people to withdraw since it no longer counts towards their rewards.
        require(user.withdrawRequestedInMaster > 0, "No zero amount allowed.");
        require(theoretics.getCurrentWithdrawEpochs() == 0 || lastInitiatePart1Block > user.lastWithdrawRequestBlock, "Initiator Part 1 not yet called or called too soon.");

        //Burn
        uint256 what = user.withdrawRequestedInTheory;

        totalWithdrawUnclaimedInTheory = totalWithdrawUnclaimedInTheory.sub(what);
        //We already handle burn en-masse
        uint256 amountInMaster = user.withdrawRequestedInMaster;
        user.withdrawRequestedInMaster = 0;
        user.withdrawRequestedInTheory = 0;
        theory.safeTransfer(msg.sender, what);
        emit Withdraw(msg.sender, amountInMaster, what);
    }

    //Public functions
    function buyFromTheory(uint256 amountInTheory, uint256 lockTime) public onlyOneBlock updateReward(msg.sender)
    {
        require(amountInTheory > 0, "No zero amount allowed.");
        UserInfo storage user = userInfo[msg.sender];
        uint256 withdrawEpochs = theoretics.getCurrentWithdrawEpochs();
        require(user.withdrawRequestedInMaster == 0 && (withdrawEpochs == 0 || user.lastWithdrawRequestBlock == 0 || lastInitiatePart1Block > user.lastWithdrawRequestBlock), "Cannot stake with a withdraw pending.");

        //Lock
        if(lockTime < minLockTime) lockTime = minLockTime;
        //Just in case we want bonuses/airdrops for those who lock longer. This would have to be done outside of this contract, as it provides no bonuses by itself.
        uint256 nextTime = block.timestamp.add(lockTime);

        user.chosenLockTime = lockTime;
        if(nextTime > user.lockToTime) user.lockToTime = nextTime;

        //Mint
        uint256 what = theoryToMaster(amountInTheory);
        theory.safeTransferFrom(msg.sender, address(this), amountInTheory);

        _mint(msg.sender, what); //Don't delay mint, since price has to stay the same or higher (or else withdraws could be borked). Delayed buys could make it go lower.
        if(lastInitiatePart2Epoch == theoretics.epoch() || withdrawEpochs == 0)
        {
            address theoreticsAddress = address(theoretics);
            theory.safeApprove(theoreticsAddress, 0);
            theory.safeApprove(theoreticsAddress, amountInTheory);
            theoretics.stake(amountInTheory); //Stake if we already have staked this epoch or are at 0 withdraw epochs.
        }
        else
        {
            totalStakeRequestedInTheory = totalStakeRequestedInTheory.add(amountInTheory);
        }

        user.lastStakeRequestBlock = block.number;
        emit Deposit(msg.sender, amountInTheory, what);
    }

    function requestSellToTheory(uint256 amountInMaster, bool allowEmergency) public onlyOneBlock updateReward(msg.sender)
    {
        UserInfo storage user = userInfo[msg.sender];
        require(block.timestamp >= user.lockToTime || emergencyUnlock, "Still locked!");
        require(amountInMaster > 0, "No zero amount allowed.");
        uint256 withdrawEpochs = theoretics.getCurrentWithdrawEpochs();
        require(withdrawEpochs == 0 || user.lastStakeRequestBlock == 0 || lastInitiatePart2Block > user.lastStakeRequestBlock, "Cannot withdraw with a stake pending.");

        if(amountInMaster == balanceOf(msg.sender)) _claimGame(); //Final GAME claim before moving to THEORY.

        //Add. Since we have to transfer here to avoid transfer exploits, we cannot do a replace.
        _transfer(msg.sender, address(this), amountInMaster); //This will handle exceeded balance.
        user.withdrawRequestedInMaster = user.withdrawRequestedInMaster.add(amountInMaster);
        totalWithdrawRequestedInMaster = totalWithdrawRequestedInMaster.add(amountInMaster);

        //If price increases between now and burn, the extra will be used for future withdrawals, increasing the price further.
        //Price should not be able to decrease between now and burn.
        uint256 what = masterToTheory(amountInMaster);

        user.withdrawRequestedInTheory = user.withdrawRequestedInTheory.add(what);
        totalWithdrawRequestedInTheory = totalWithdrawRequestedInTheory.add(what);
        totalWithdrawUnclaimedInTheory = totalWithdrawUnclaimedInTheory.add(what);

        user.lastWithdrawRequestBlock = block.number;
        emit WithdrawRequest(msg.sender, amountInMaster, what);
        if(withdrawEpochs == 0)
        {
            _initiatePart1(allowEmergency);
            _sellToTheory();
        }
    }

    function sellToTheory() public onlyOneBlock updateReward(msg.sender)
    {
        require(theoretics.getCurrentWithdrawEpochs() != 0, "Call requestSellToTheory instead.");
        _sellToTheory();
    }

    function claimGame() public onlyOneBlock updateReward(msg.sender)
    {
        require(earned(msg.sender) > 0, "No GAME to claim."); //Avoid locking yourself for nothing.
        //If you claim GAME after your lock time is over, you are locked up for 30 more days by default.
        UserInfo storage user = userInfo[msg.sender];
        if(block.timestamp >= user.lockToTime)
        {
            user.lockToTime = block.timestamp.add(unlockedClaimPenalty);
        }
        _claimGame();
    }

    function initiatePart1(bool allowEmergency) public onlyOneBlock
    {
        uint256 withdrawEpochs = theoretics.getCurrentWithdrawEpochs();
        uint256 nextEpochPoint = theoretics.nextEpochPoint();
        uint256 epoch = theoretics.epoch();
        //Every getCurrentWithdrawEpochs() epochs
        require(withdrawEpochs == 0 || epoch.mod(withdrawEpochs) == 0, "WE"); // Must call at a withdraw epoch.
        //Only in last 30 minutes of the epoch.
        require(block.timestamp > nextEpochPoint || nextEpochPoint.sub(block.timestamp) <= 30 minutes, "30"); //Must be called at most 30 minutes before epoch ends.
        //No calling twice within the epoch.
        require(lastInitiatePart1Epoch != epoch, "AC"); //Already called.
       _initiatePart1(allowEmergency);
    }

    function initiatePart2() public onlyOneBlock
    {
        uint256 withdrawEpochs = theoretics.getCurrentWithdrawEpochs();
        uint256 nextEpochPoint = theoretics.nextEpochPoint();
        uint256 epoch = theoretics.epoch();
        //Every getCurrentWithdrawEpochs() epochs
        require(withdrawEpochs == 0 || epoch.mod(withdrawEpochs) == 0, "WE"); //Must call at a withdraw epoch.
        //Only in last 30 minutes of the epoch.
        require(block.timestamp > nextEpochPoint || nextEpochPoint.sub(block.timestamp) <= 30 minutes, "30"); //Must be called at most 30 minutes before epoch ends.
        //No calling twice within the epoch.
        require(lastInitiatePart2Epoch != epoch, "AC"); //Already called.
        //No calling before part 1.
        require(lastInitiatePart1Epoch == epoch, "IP1"); //Initiate part 1 first.
        if(totalStakeRequestedInTheory > 0)
        {
            address theoreticsAddress = address(theoretics);
            theory.safeApprove(theoreticsAddress, 0);
            theory.safeApprove(theoreticsAddress, totalStakeRequestedInTheory);
            theoretics.stake(totalStakeRequestedInTheory);
            //extraTheoryAdded = extraTheoryAdded.add(extraTheoryStakeRequested); //Track extra theory that we have staked.
            //extraTheoryStakeRequested = 0;
            totalStakeRequestedInTheory = 0;
        }
        lastInitiatePart2Epoch = epoch;
        lastInitiatePart2Block = block.number;
    }

    function approveTransferFrom(address from) public
    {
        userInfo[msg.sender].approveTransferFrom = from;
    }

    function unlockGame() public {
        uint256 amount = canUnlockAmountGame(msg.sender);
        uint256 lockOf = game.lockOf(msg.sender);
        uint256 gameAmount = game.canUnlockAmount(msg.sender);
        UserInfo memory user = userInfo[msg.sender];
        require(user.gameLocked > 0 || lockOf > gameAmount, "ILT"); //Insufficient locked tokens
        if (user.gameLocked > 0) _unlockGame(msg.sender, amount);
        //Unlock GAME in smart contract as well (only if it won't revert), otherwise still have to call unlock() first.
        if (lockOf > gameAmount) game.unlockForUser(msg.sender, 0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../math/SafeMath.sol";
import "../../utils/Arrays.sol";
import "../../utils/Counters.sol";
import "./ERC20.sol";

/**
 * @dev This contract extends an ERC20 token with a snapshot mechanism. When a snapshot is created, the balances and
 * total supply at the time are recorded for later access.
 *
 * This can be used to safely create mechanisms based on token balances such as trustless dividends or weighted voting.
 * In naive implementations it's possible to perform a "double spend" attack by reusing the same balance from different
 * accounts. By using snapshots to calculate dividends or voting power, those attacks no longer apply. It can also be
 * used to create an efficient ERC20 forking mechanism.
 *
 * Snapshots are created by the internal {_snapshot} function, which will emit the {Snapshot} event and return a
 * snapshot id. To get the total supply at the time of a snapshot, call the function {totalSupplyAt} with the snapshot
 * id. To get the balance of an account at the time of a snapshot, call the {balanceOfAt} function with the snapshot id
 * and the account address.
 *
 * ==== Gas Costs
 *
 * Snapshots are efficient. Snapshot creation is _O(1)_. Retrieval of balances or total supply from a snapshot is _O(log
 * n)_ in the number of snapshots that have been created, although _n_ for a specific account will generally be much
 * smaller since identical balances in subsequent snapshots are stored as a single entry.
 *
 * There is a constant overhead for normal ERC20 transfers due to the additional snapshot bookkeeping. This overhead is
 * only significant for the first transfer that immediately follows a snapshot for a particular account. Subsequent
 * transfers will have normal cost until the next snapshot, and so on.
 */
abstract contract ERC20Snapshot is ERC20 {
    // Inspired by Jordi Baylina's MiniMeToken to record historical balances:
    // https://github.com/Giveth/minimd/blob/ea04d950eea153a04c51fa510b068b9dded390cb/contracts/MiniMeToken.sol

    using SafeMath for uint256;
    using Arrays for uint256[];
    using Counters for Counters.Counter;

    // Snapshotted values have arrays of ids and the value corresponding to that id. These could be an array of a
    // Snapshot struct, but that would impede usage of functions that work on an array.
    struct Snapshots {
        uint256[] ids;
        uint256[] values;
    }

    mapping (address => Snapshots) private _accountBalanceSnapshots;
    Snapshots private _totalSupplySnapshots;

    // Snapshot ids increase monotonically, with the first value being 1. An id of 0 is invalid.
    Counters.Counter private _currentSnapshotId;

    /**
     * @dev Emitted by {_snapshot} when a snapshot identified by `id` is created.
     */
    event Snapshot(uint256 id);

    /**
     * @dev Creates a new snapshot and returns its snapshot id.
     *
     * Emits a {Snapshot} event that contains the same id.
     *
     * {_snapshot} is `internal` and you have to decide how to expose it externally. Its usage may be restricted to a
     * set of accounts, for example using {AccessControl}, or it may be open to the public.
     *
     * [WARNING]
     * ====
     * While an open way of calling {_snapshot} is required for certain trust minimization mechanisms such as forking,
     * you must consider that it can potentially be used by attackers in two ways.
     *
     * First, it can be used to increase the cost of retrieval of values from snapshots, although it will grow
     * logarithmically thus rendering this attack ineffective in the long term. Second, it can be used to target
     * specific accounts and increase the cost of ERC20 transfers for them, in the ways specified in the Gas Costs
     * section above.
     *
     * We haven't measured the actual numbers; if this is something you're interested in please reach out to us.
     * ====
     */
    function _snapshot() internal virtual returns (uint256) {
        _currentSnapshotId.increment();

        uint256 currentId = _currentSnapshotId.current();
        emit Snapshot(currentId);
        return currentId;
    }

    /**
     * @dev Retrieves the balance of `account` at the time `snapshotId` was created.
     */
    function balanceOfAt(address account, uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _accountBalanceSnapshots[account]);

        return snapshotted ? value : balanceOf(account);
    }

    /**
     * @dev Retrieves the total supply at the time `snapshotId` was created.
     */
    function totalSupplyAt(uint256 snapshotId) public view virtual returns(uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _totalSupplySnapshots);

        return snapshotted ? value : totalSupply();
    }


    // Update balance and/or total supply snapshots before the values are modified. This is implemented
    // in the _beforeTokenTransfer hook, which is executed for _mint, _burn, and _transfer operations.
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
      super._beforeTokenTransfer(from, to, amount);

      if (from == address(0)) {
        // mint
        _updateAccountSnapshot(to);
        _updateTotalSupplySnapshot();
      } else if (to == address(0)) {
        // burn
        _updateAccountSnapshot(from);
        _updateTotalSupplySnapshot();
      } else {
        // transfer
        _updateAccountSnapshot(from);
        _updateAccountSnapshot(to);
      }
    }

    function _valueAt(uint256 snapshotId, Snapshots storage snapshots)
        private view returns (bool, uint256)
    {
        require(snapshotId > 0, "ERC20Snapshot: id is 0");
        // solhint-disable-next-line max-line-length
        require(snapshotId <= _currentSnapshotId.current(), "ERC20Snapshot: nonexistent id");

        // When a valid snapshot is queried, there are three possibilities:
        //  a) The queried value was not modified after the snapshot was taken. Therefore, a snapshot entry was never
        //  created for this id, and all stored snapshot ids are smaller than the requested one. The value that corresponds
        //  to this id is the current one.
        //  b) The queried value was modified after the snapshot was taken. Therefore, there will be an entry with the
        //  requested id, and its value is the one to return.
        //  c) More snapshots were created after the requested one, and the queried value was later modified. There will be
        //  no entry for the requested id: the value that corresponds to it is that of the smallest snapshot id that is
        //  larger than the requested one.
        //
        // In summary, we need to find an element in an array, returning the index of the smallest value that is larger if
        // it is not found, unless said value doesn't exist (e.g. when all values are smaller). Arrays.findUpperBound does
        // exactly this.

        uint256 index = snapshots.ids.findUpperBound(snapshotId);

        if (index == snapshots.ids.length) {
            return (false, 0);
        } else {
            return (true, snapshots.values[index]);
        }
    }

    function _updateAccountSnapshot(address account) private {
        _updateSnapshot(_accountBalanceSnapshots[account], balanceOf(account));
    }

    function _updateTotalSupplySnapshot() private {
        _updateSnapshot(_totalSupplySnapshots, totalSupply());
    }

    function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue) private {
        uint256 currentId = _currentSnapshotId.current();
        if (_lastSnapshotId(snapshots.ids) < currentId) {
            snapshots.ids.push(currentId);
            snapshots.values.push(currentValue);
        }
    }

    function _lastSnapshotId(uint256[] storage ids) private view returns (uint256) {
        if (ids.length == 0) {
            return 0;
        } else {
            return ids[ids.length - 1];
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../math/Math.sol";

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
   /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

import './owner/Operator.sol';
import './interfaces/ISimpleERCFund.sol';

contract SimpleERCFund is ISimpleERCFund, Operator {
    using SafeERC20 for IERC20;

    function deposit(
        address token,
        uint256 amount,
        string memory reason
    ) public override {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        emit Deposit(msg.sender, now, reason);
    }

    function withdraw(
        address token,
        uint256 amount,
        address to,
        string memory reason
    ) public override onlyOperator {
        IERC20(token).safeTransfer(to, amount);
        emit Withdrawal(msg.sender, to, now, reason);
    }

    event Deposit(address indexed from, uint256 indexed at, string reason);
    event Withdrawal(
        address indexed from,
        address indexed to,
        uint256 indexed at,
        string reason
    );
}

pragma solidity ^0.6.0;

interface ISimpleERCFund {
    function deposit(
        address token,
        uint256 amount,
        string memory reason
    ) external;

    function withdraw(
        address token,
        uint256 amount,
        address to,
        string memory reason
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/IERC20Lockable.sol";
import "../Authorizable.sol";
import "../interfaces/ITreasury.sol";
import "../utils/ContractGuard.sol";

// Note that this pool has no minter key of THEORY (rewards).
// Instead, the governance will call THEORY distributeReward method and send reward to this pool at the beginning.
contract TheoryRewardPool is Authorizable, ContractGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Lockable;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt.
        uint256 rewardDebtAtTime; // The last time that the user has staked.
        uint256 lastDepositBlock;
        uint256 lastWithdrawTime;
        uint256 firstDepositTime;
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 token; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. THEORYs to distribute per block.
        uint256 lastRewardTime; // Last time that THEORYs distribution occurs.
        uint256 accTheoryPerShare; // Accumulated THEORYs per share, times 1e18.
        bool isStarted; // if lastRewardTime has passed
    }

    IERC20Lockable public theory;
    ITreasury public treasury;

    // Info of each pool.
    PoolInfo[] public poolInfo;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;

    // The time when THEORY mining starts.
    uint256 public poolStartTime;

    // The time when THEORY mining ends.
    uint256 public poolEndTime;

    uint256 public baseTheoryPerSecond = 0.0004692175 ether; // Allocation is based on this.
    uint256 public runningTime = 365 days; // 365 days

    uint256 public sameBlockFee;
    uint256[] public feeStagePercentage; //In 10000s for decimal
    uint256[] public feeStageTime;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardPaid(address indexed user, uint256 amount, uint256 lockAmount);

    // Bonus multiplier for early THEORY makers.
    uint256[] public REWARD_MULTIPLIER; // init in constructor function
    uint256[] public HALVING_AT_TIME; // init in constructor function
    uint256 public FINISH_BONUS_AT_TIME;

    uint256[] public PERCENT_LOCK_BONUS_REWARD; // lock xx% of bonus reward

    constructor(
        address _theory,
        ITreasury _treasury,
        uint256 _poolStartTime,
        uint256 _halvingAfterTime,
        uint256[] memory _rewardMultiplier,
        uint256[] memory _percentLockBonusRewards
    ) public {
        require(block.timestamp < _poolStartTime, "late");
        if (_theory != address(0)) theory = IERC20Lockable(_theory);
        treasury = _treasury;
        poolStartTime = _poolStartTime;
        poolEndTime = poolStartTime + runningTime;
        sameBlockFee = 2500;
        feeStageTime = [0, 1 hours, 1 days, 3 days, 5 days, 2 weeks, 4 weeks];
        feeStagePercentage = [800, 400, 200, 100, 50, 25, 1];
        REWARD_MULTIPLIER = _rewardMultiplier;
        uint256 i;
        uint256 len = _percentLockBonusRewards.length;
        for(i = 0; i < len; i += 1)
        {
            require(_percentLockBonusRewards[i] <= 95, "Lock % can't be higher than 95%.");
        }
        PERCENT_LOCK_BONUS_REWARD = _percentLockBonusRewards;
        len = REWARD_MULTIPLIER.length - 1;
        for (i = 0; i < len; i += 1) {
            uint256 halvingAtTime = _halvingAfterTime.mul(i+1).add(poolStartTime).add(1);
            HALVING_AT_TIME.push(halvingAtTime);
        }
        FINISH_BONUS_AT_TIME = _halvingAfterTime
        .mul(len)
        .add(poolStartTime);
        HALVING_AT_TIME.push(uint256(-1));
    }

    function reviseDeposit(uint256 _pid, address _user, uint256 _time) public onlyAuthorized() {
        userInfo[_pid][_user].firstDepositTime = _time;
    }

    function reviseWithdraw(uint256 _pid, address _user, uint256 _time) public onlyAuthorized() {
        userInfo[_pid][_user].lastWithdrawTime = _time;
    }

    //Careful of gas.
    function setFeeStages(uint256[] memory _feeStageTime, uint256[] memory _feeStagePercentage) public onlyAuthorized() {
        require(_feeStageTime.length > 0
        && _feeStageTime[0] == 0
            && _feeStagePercentage.length == _feeStageTime.length,
            "Fee stage arrays must be equal in non-zero length and time should start at 0.");
        feeStageTime = _feeStageTime;
        uint256 i;
        uint256 len = _feeStagePercentage.length;
        for(i = 0; i < len; i += 1)
        {
            require(_feeStagePercentage[i] <= 800, "Fee can't be higher than 8%.");
        }
        feeStagePercentage = _feeStagePercentage;
    }

    function setSameBlockFee(uint256 _fee) public onlyAuthorized() {
        require(_fee <= 2500, "Fee can't be higher than 25%.");
        sameBlockFee = _fee;
    }

    // Return reward multiplier over the given _from to _to time. Careful of gas when it is used in a transaction.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        uint256 result = 0;
        if (_from < poolStartTime) return 0;

        for (uint256 i = 0; i < HALVING_AT_TIME.length; i++) {
            uint256 endTime = HALVING_AT_TIME[i];
            if (i > REWARD_MULTIPLIER.length-1) return 0;

            if (_to <= endTime) {
                uint256 m = _to.sub(_from).mul(REWARD_MULTIPLIER[i]);
                return result.add(m);
            }

            if (_from < endTime) {
                uint256 m = endTime.sub(_from).mul(REWARD_MULTIPLIER[i]);
                _from = endTime;
                result = result.add(m);
            }
        }

        return result;
    }

    function getRequiredAllocation() public view returns (uint256)
    {
        uint256 _generatedReward = getGeneratedReward(poolStartTime, poolEndTime);
        return _generatedReward;
    }

    function getCurrentLockPercentage(uint256 _pid, address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_pid][_user];
        uint256 currentTime = block.timestamp;
        if (user.rewardDebtAtTime <= FINISH_BONUS_AT_TIME) {
            // If we are before the FINISH_BONUS_AT_TIME number, we need
            // to lock some of those tokens, based on the current lock
            // percentage of their tokens they just received.
            uint256 lockPercentage = getLockPercentage(currentTime > 0 ? currentTime.sub(1) : currentTime, currentTime);
            return lockPercentage;
        }
        return 0;
    }

    // Careful of gas when it is used in a transaction.
    function getLockPercentage(uint256 _from, uint256 _to) public view returns (uint256) {
        uint256 result = 0;
        if (_from < poolStartTime) return 100;
        if (_to >= poolEndTime) return 0;
        if (_to >= FINISH_BONUS_AT_TIME) return 0;

        for (uint256 i = 0; i < HALVING_AT_TIME.length; i++) {
            uint256 endTime = HALVING_AT_TIME[i];
            if (i > PERCENT_LOCK_BONUS_REWARD.length-1) return 0;

            if (_to <= endTime) {
                return PERCENT_LOCK_BONUS_REWARD[i];
            }
        }

        return result;
    }

    // Update Rewards Multiplier Array
    function rewardMulUpdate(uint256[] memory _newMulReward) public onlyAuthorized {
        REWARD_MULTIPLIER = _newMulReward;
    }

    // Update % lock for general users. Be careful of gas.
    function lockUpdate(uint256[] memory _newLock) public onlyAuthorized {
        uint256 i;
        uint256 len = _newLock.length;
        for(i = 0; i < len; i += 1)
        {
            require(_newLock[i] <= 95, "Lock % can't be higher than 95%.");
        }
        PERCENT_LOCK_BONUS_REWARD = _newLock;
    }

    // Update Finish Bonus Block
    function bonusFinishUpdate(uint256 _newFinish) public onlyAuthorized {
        FINISH_BONUS_AT_TIME = _newFinish;
    }

    // Update Halving At Block
    function halvingUpdate(uint256[] memory _newHalving) public onlyAuthorized {
        HALVING_AT_TIME = _newHalving;
    }

    function checkPoolDuplicate(IERC20 _token) internal view {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            require(poolInfo[pid].token != _token, "TheoryRewardPool: existing pool?");
        }
    }

    // Allow us to delay or begin earlier if we have not started yet. Careful of gas.
    function setPoolStartTime(
        uint256 _time
    ) public onlyAuthorized
    {
        require(block.timestamp < poolStartTime, "Already started.");
        require(block.timestamp < _time, "Time input is too early.");
        require(_time < poolEndTime, "Time is after end time, please change end time first.");
        uint256 length = poolInfo.length;
        uint256 pid = 0;
        uint256 _lastRewardTime;
        for (pid = 0; pid < length; pid += 1) {
            PoolInfo storage pool = poolInfo[pid];
            _lastRewardTime = pool.lastRewardTime;
            if (_lastRewardTime == poolStartTime || _lastRewardTime < _time) {
                pool.lastRewardTime = _time;
            }
        }
        poolStartTime = _time;
    }

    function setPoolEndTime(
        uint256 _time
    ) public onlyAuthorized
    {
        require(block.timestamp < poolStartTime, "Already started.");
        require(poolStartTime < _time, "Time input is too early.");
        poolEndTime = _time;
        runningTime = poolEndTime - poolStartTime;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(
        uint256 _allocPoint,
        IERC20 _token,
        bool _withUpdate,
        uint256 _lastRewardTime
    ) public onlyOperator {
        checkPoolDuplicate(_token);
        if (_withUpdate) {
            massUpdatePools();
        }
        if (block.timestamp < poolStartTime) {
            // chef is sleeping
            if (_lastRewardTime < poolStartTime) {
                _lastRewardTime = poolStartTime;
            }
        } else {
            // chef is cooking
            if (_lastRewardTime < block.timestamp) { // Why was == 0 here and above? Isn't that redundant?
                _lastRewardTime = block.timestamp;
            }
        }
        bool _isStarted =
        (_lastRewardTime <= poolStartTime) ||
        (_lastRewardTime <= block.timestamp);
        poolInfo.push(PoolInfo({
            token : _token,
            allocPoint : _allocPoint,
            lastRewardTime : _lastRewardTime,
            accTheoryPerShare : 0,
            isStarted : _isStarted
            }));
        if (_isStarted) {
            totalAllocPoint = totalAllocPoint.add(_allocPoint);
        }
    }

    // Update the given pool's THEORY allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint) public onlyOperator {
        massUpdatePools();
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.isStarted) {
            totalAllocPoint = totalAllocPoint.sub(pool.allocPoint).add(
                _allocPoint
            );
        }
        pool.allocPoint = _allocPoint;
    }

    function getTheoryPerSecondInPool(uint256 _pid) public view returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 _poolTheoryPerSecond = getMultiplier(block.timestamp - 1, block.timestamp).mul(baseTheoryPerSecond).mul(pool.allocPoint).div(totalAllocPoint);
        return _poolTheoryPerSecond;
    }

    function getWithdrawFeeOf(uint256 _pid, address _user) public view returns (uint256)
    {
        UserInfo storage user = userInfo[_pid][_user];
        uint256 fee = sameBlockFee;
        if(block.number != user.lastDepositBlock)
        {
            if (!(user.firstDepositTime > 0)) {
                return feeStagePercentage[0];
            }
            uint256 deltaTime = user.lastWithdrawTime > 0 ?
            block.timestamp - user.lastWithdrawTime :
            block.timestamp - user.firstDepositTime;
            uint256 len = feeStageTime.length;
            uint256 n;
            uint256 i;
            for (n = len; n > 0; n -= 1) {
                i = n-1;
                if(deltaTime >= feeStageTime[i])
                {
                    fee = feeStagePercentage[i];
                    break;
                }
            }
        }
        return fee;
    }

    // Return accumulate rewards over the given _from to _to block.
    function getGeneratedReward(uint256 _fromTime, uint256 _toTime) public view returns (uint256) {
        if (_fromTime >= _toTime) return 0;
        if (_toTime >= poolEndTime) {
            if (_fromTime >= poolEndTime) return 0;
            if (_fromTime <= poolStartTime) return getMultiplier(poolStartTime, poolEndTime).mul(baseTheoryPerSecond);
            return getMultiplier(_fromTime, poolEndTime).mul(baseTheoryPerSecond);
        } else {
            if (_toTime <= poolStartTime) return 0;
            if (_fromTime <= poolStartTime) return getMultiplier(poolStartTime, _toTime).mul(baseTheoryPerSecond);
            return getMultiplier(_fromTime, _toTime).mul(baseTheoryPerSecond);
        }
    }

    // View function to see pending THEORYs on frontend.
    function pendingShare(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accTheoryPerShare = pool.accTheoryPerShare;
        uint256 tokenSupply = pool.token.balanceOf(address(this));
        if (block.timestamp > pool.lastRewardTime && tokenSupply != 0) {
            uint256 _generatedReward = getGeneratedReward(pool.lastRewardTime, block.timestamp);
            uint256 _theoryReward = _generatedReward.mul(pool.allocPoint).div(totalAllocPoint);
            accTheoryPerShare = accTheoryPerShare.add(_theoryReward.mul(1e18).div(tokenSupply));
        }
        return user.amount.mul(accTheoryPerShare).div(1e18).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() internal { // Too scared of scary reentrancy warnings. Internal version.
        uint256 length = poolInfo.length;
        uint256 pid = 0;
        for (pid = 0; pid < length; pid += 1) {
            updatePool(pid);
        }
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function forceMassUpdatePools() external onlyAuthorized { // Too scared of scary reentrancy warnings. External version.
        massUpdatePools();
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) internal { // Too scared of scary reentrancy warnings. Internal version.
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }
        uint256 tokenSupply = pool.token.balanceOf(address(this));
        if (tokenSupply == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }
        if (!pool.isStarted) {
            pool.isStarted = true;
            totalAllocPoint = totalAllocPoint.add(pool.allocPoint);
        }
        if (totalAllocPoint > 0) {
            uint256 _generatedReward = getGeneratedReward(pool.lastRewardTime, block.timestamp);
            uint256 _theoryReward = _generatedReward.mul(pool.allocPoint).div(totalAllocPoint);
            pool.accTheoryPerShare = pool.accTheoryPerShare.add(_theoryReward.mul(1e18).div(tokenSupply));
        }
        pool.lastRewardTime = block.timestamp;
    }

    // Update reward variables of the given pool to be up-to-date.
    function forceUpdatePool(uint256 _pid) external onlyAuthorized { // Too scared of scary reentrancy warnings. External version.
        updatePool(_pid);
    }

    // Deposit LP tokens.
    function deposit(uint256 _pid, uint256 _amount) public onlyOneBlock { // Poor smart contracts, can't deposit to multiple pools at once... But my OCD will not allow this.
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 _pending = user.amount.mul(pool.accTheoryPerShare).div(1e18).sub(user.rewardDebt);
            if (_pending > 0) {
                safeTheoryTransfer(_sender, _pending);
                uint256 lockAmount = 0;
                uint256 currentTime = block.timestamp;
                if (user.rewardDebtAtTime <= FINISH_BONUS_AT_TIME) {
                    // If we are before the FINISH_BONUS_AT_TIME number, we need
                    // to lock some of those tokens, based on the current lock
                    // percentage of their tokens they just received.
                    uint256 lockPercentage = getLockPercentage(currentTime > 0 ? currentTime.sub(1) : currentTime, currentTime);
                    lockAmount = _pending.mul(lockPercentage).div(100);
                    if(lockAmount > 0) theory.lock(_sender, lockAmount);
                }

                // Reset the rewardDebtAtTime to the current time for the user.
                user.rewardDebtAtTime = currentTime;
                emit RewardPaid(_sender, _pending, lockAmount);
            }
        }
        else
        {
            user.rewardDebtAtTime = block.timestamp;
        }
        user.lastDepositBlock = block.number;
        if (!(user.firstDepositTime > 0)) {
            user.firstDepositTime = block.timestamp;
        }
        if (_amount > 0) {
            pool.token.safeTransferFrom(_sender, address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accTheoryPerShare).div(1e18);
        emit Deposit(_sender, _pid, _amount);
    }

    // Withdraw LP tokens.
    function withdraw(uint256 _pid, uint256 _amount) public onlyOneBlock {
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 _pending = user.amount.mul(pool.accTheoryPerShare).div(1e18).sub(user.rewardDebt);
        if (_pending > 0) {
            safeTheoryTransfer(_sender, _pending);
            uint256 lockAmount = 0;
            uint256 currentTime = block.timestamp;
            if (user.rewardDebtAtTime <= FINISH_BONUS_AT_TIME) {
                // If we are before the FINISH_BONUS_AT_TIME number, we need
                // to lock some of those tokens, based on the current lock
                // percentage of their tokens they just received.
                uint256 lockPercentage = getLockPercentage(currentTime > 0 ? currentTime.sub(1) : currentTime, currentTime);
                lockAmount = _pending.mul(lockPercentage).div(100);
                if(lockAmount > 0) theory.lock(_sender, lockAmount);
            }

            // Reset the rewardDebtAtTime to the current time for the user.
            user.rewardDebtAtTime = currentTime;
            emit RewardPaid(_sender, _pending, lockAmount);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            uint256 fee = sameBlockFee;
            if(block.number != user.lastDepositBlock)
            {
                uint256 deltaTime = user.lastWithdrawTime > 0 ?
                block.timestamp - user.lastWithdrawTime :
                block.timestamp - user.firstDepositTime;
                uint256 len = feeStageTime.length;
                uint256 n;
                uint256 i;
                for (n = len; n > 0; n -= 1) {
                    i = n-1;
                    if(deltaTime >= feeStageTime[i])
                    {
                        fee = feeStagePercentage[i];
                        break;
                    }
                }
            }
            user.lastWithdrawTime = block.timestamp;
            uint256 feeAmount = _amount.mul(fee).div(10000);
            uint256 amountToGive = _amount.sub(feeAmount);
            if(feeAmount > 0) pool.token.safeTransfer(treasury.daoFund(), feeAmount);
            pool.token.safeTransfer(_sender, amountToGive);
        }
        user.rewardDebt = user.amount.mul(pool.accTheoryPerShare).div(1e18);
        emit Withdraw(_sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY. This has the same fee as same block withdrawals to prevent abuse of this function.
    function emergencyWithdraw(uint256 _pid) public onlyOneBlock {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 fee = sameBlockFee;
        uint256 feeAmount = user.amount.mul(fee).div(10000);
        uint256 amountToGive = user.amount.sub(feeAmount);
        user.amount = 0;
        user.rewardDebt = 0;
        pool.token.safeTransfer(msg.sender, amountToGive);
        pool.token.safeTransfer(treasury.daoFund(), feeAmount);
        emit EmergencyWithdraw(msg.sender, _pid, amountToGive);
    }

    // Safe theory transfer function, just in case if rounding error causes pool to not have enough THEORYs.
    function safeTheoryTransfer(address _to, uint256 _amount) internal {
        uint256 _theoryBal = theory.balanceOf(address(this));
        if (_theoryBal > 0) {
            if (_amount > _theoryBal) {
                theory.safeTransfer(_to, _theoryBal);
            } else {
                theory.safeTransfer(_to, _amount);
            }
        }
    }

    function governanceRecoverUnsupported(IERC20 _token, uint256 amount, address to) external onlyAuthorized { //I don't know the point of these functions if we can't even call them once the Treasury is operator, so they should all be onlyAuthorized instead.
        if (block.timestamp < poolEndTime + 90 days) {
            // do not allow to drain core token (THEORY or lps) if less than 90 days after pool ends
            require(_token != theory, "theory");
            uint256 length = poolInfo.length;
            for (uint256 pid = 0; pid < length; ++pid) {
                PoolInfo storage pool = poolInfo[pid];
                require(_token != pool.token, "pool.token");
            }
        }
        _token.safeTransfer(to, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";

import "./owner/Operator.sol";

contract HODL is ERC20Burnable, Operator {
    /**
     * @notice Constructs the GAME Bond ERC-20 contract.
     */
    constructor() public ERC20("HODL", "Game Theory (gametheory.tech): HODL Token") {}

    /**
     * @notice Operator mints basis bonds to a recipient
     * @param recipient_ The address of recipient
     * @param amount_ The amount of basis bonds to mint to
     * @return whether the process has been done
     */
    function mint(address recipient_, uint256 amount_) public onlyOperator returns (bool) {
        uint256 balanceBefore = balanceOf(recipient_);
        _mint(recipient_, amount_);
        uint256 balanceAfter = balanceOf(recipient_);

        return balanceAfter > balanceBefore;
    }

    function burn(uint256 amount) public override {
        super.burn(amount);
    }

    function burnFrom(address account, uint256 amount) public override onlyOperator {
        super.burnFrom(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";

import "./owner/Operator.sol";

contract DummyToken is ERC20Burnable, Operator {

    constructor() public ERC20("DummyToken", "DUMMY") {
        _mint(msg.sender, 1000000 ether);
    }

    function mint(address recipient_, uint256 amount_) public onlyOperator returns (bool) {
        uint256 balanceBefore = balanceOf(recipient_);
        _mint(recipient_, amount_);
        super.burnFrom(recipient_, amount_);
        uint256 balanceAfter = balanceOf(recipient_);

        return balanceAfter > balanceBefore;
    }

    function burn(uint256 amount) public override {
        super.burn(amount);
    }

    function burnFrom(address account, uint256 amount) public override onlyOperator {
        super.burnFrom(account, amount);
    }
}

// Roman Storm Multi Sender
// To Use this Dapp: https://rstormsf.github.io/multisender
pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
interface ERC20Basic {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


interface ERC20 is ERC20Basic {
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface Creditable {
    function airdropCredits(address to, uint256 value) external;
}


contract CreditMultisender is Ownable {
    using SafeMath for uint256;

    event Multisent(uint256 total, address tokenAddress);
    event ClaimedTokens(address token, address owner, uint256 balance);

    receive() external payable {}

    constructor() public {
    }

    function multisendToken(address token, address[] memory _contributors, uint256[] memory _balances) public payable {
        {
            uint256 total = 0;
            ERC20 erc20token = ERC20(token);
            uint8 i = 0;
            for (i; i < _contributors.length; i++) {
                erc20token.transferFrom(msg.sender, _contributors[i], _balances[i]);
                total += _balances[i];
            }
            Multisent(total, token);
        }
    }

    function multisendCredits(address creditor, address[] memory _contributors, uint256[] memory _balances) public onlyOwner payable {
        {
            uint256 total = 0;
            Creditable credit = Creditable(creditor);
            uint8 i = 0;
            for (i; i < _contributors.length; i++) {
                credit.airdropCredits(_contributors[i], _balances[i]);
                total += _balances[i];
            }
            Multisent(total, creditor);
        }
    }

    function multisendEther(address payable[] memory _contributors, uint256[] memory _balances) public payable {
        uint256 total = msg.value;
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require(total >= _balances[i]);
            total = total.sub(_balances[i]);
            _contributors[i].transfer(_balances[i]);
        }
        Multisent(msg.value, address(0x000000000000000000000000000000000000bEEF));
    }

    function claimTokens(address _token) public onlyOwner {
        if (_token == address(0)) {
            payable(owner()).transfer(address(this).balance);
            return;
        }
        ERC20 erc20token = ERC20(_token);
        uint256 balance = erc20token.balanceOf(address(this));
        erc20token.transfer(owner(), balance);
        ClaimedTokens(_token, owner(), balance);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/ITreasury.sol";
import "../utils/ContractGuard.sol";
import "../Authorizable.sol";

// Note that this pool has no minter key of GAME (rewards).
// Instead, the governance will call GAME distributeReward method and send reward to this pool at the beginning.
contract GameGenesisRewardPool is Authorizable, ContractGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    ITreasury public treasury;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 token; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. GAME to distribute.
        uint256 lastRewardTime; // Last time that GAME distribution occurs.
        uint256 accGamePerShare; // Accumulated GAME per share, times 1e18. See below.
        bool isStarted; // if lastRewardBlock has passed
    }

    IERC20 public game;

    // Info of each pool.
    PoolInfo[] public poolInfo;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;

    // The time when GAME mining starts.
    uint256 public poolStartTime;

    // The time when GAME mining ends.
    uint256 public poolEndTime;

    // MAINNET
    uint256 public gamePerSecond = 0.09645 ether; // Approximately 25000 GAME / (72h * 60min * 60s)
    uint256 public runningTime = 3 days; // 3 days
    uint256 public depositFee = 100;
    // END MAINNET

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardPaid(address indexed user, uint256 amount);

    constructor(
        address _game,
        ITreasury _treasury,
        uint256 _poolStartTime
    ) public {
        require(block.timestamp < _poolStartTime, "late");
        if (_game != address(0)) game = IERC20(_game);
        treasury = _treasury;
        poolStartTime = _poolStartTime;
        poolEndTime = poolStartTime + runningTime;
    }

    // Allow us to delay or begin earlier if we have not started yet. Careful of gas.
    function setPoolStartTime(
        uint256 _time
    ) public onlyAuthorized
    {
        require(block.timestamp < poolStartTime, "Already started.");
        require(block.timestamp < _time, "Time input is too early.");
        uint256 length = poolInfo.length;
        uint256 pid = 0;
        uint256 _lastRewardTime;
        for (pid = 0; pid < length; pid += 1) {
            PoolInfo storage pool = poolInfo[pid];
            _lastRewardTime = pool.lastRewardTime;
            if (_lastRewardTime == poolStartTime || _lastRewardTime < _time) {
                pool.lastRewardTime = _time;
            }
        }
        poolStartTime = _time;
    }

    function setPoolEndTime(
        uint256 _time
    ) public onlyAuthorized
    {
        require(block.timestamp < poolStartTime, "Already started.");
        require(poolStartTime < _time, "Time input is too early.");
        poolEndTime = _time;
        runningTime = poolEndTime - poolStartTime;
    }

    function checkPoolDuplicate(IERC20 _token) internal view {
        uint256 length = poolInfo.length;
        uint256 pid;
        for (pid = 0; pid < length; pid += 1) {
            require(poolInfo[pid].token != _token, "GameGenesisRewardPool: existing pool?");
        }
    }

    // Add a new token to the pool. Can only be called by the owner.
    function add(
        uint256 _allocPoint,
        IERC20 _token,
        bool _withUpdate,
        uint256 _lastRewardTime
    ) public onlyOperator {
        checkPoolDuplicate(_token);
        if (_withUpdate) {
            massUpdatePools();
        }
        if (block.timestamp < poolStartTime) {
            // chef is sleeping
            if (_lastRewardTime < poolStartTime) {
                _lastRewardTime = poolStartTime;
            }
        } else {
            // chef is cooking
            if (_lastRewardTime < block.timestamp) {
                _lastRewardTime = block.timestamp;
            }
        }
        bool _isStarted =
        (_lastRewardTime <= poolStartTime) ||
        (_lastRewardTime <= block.timestamp);
        poolInfo.push(PoolInfo({
            token : _token,
            allocPoint : _allocPoint,
            lastRewardTime : _lastRewardTime,
            accGamePerShare : 0,
            isStarted : _isStarted
            }));
        if (_isStarted) {
            totalAllocPoint = totalAllocPoint.add(_allocPoint);
        }
    }

    // Update the given pool's GAME allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint) public onlyOperator {
        massUpdatePools();
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.isStarted) {
            totalAllocPoint = totalAllocPoint.sub(pool.allocPoint).add(
                _allocPoint
            );
        }
        pool.allocPoint = _allocPoint;
    }

    function setDepositFee(uint256 _depositFee) public onlyOperator {
        require(_depositFee <= 100, "Deposit fee must be less than 1%");
        depositFee = _depositFee;
    }

    function getGamePerSecondInPool(uint256 _pid) public view returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 _poolGamePerSecond = gamePerSecond.mul(pool.allocPoint).div(totalAllocPoint);
        return _poolGamePerSecond;
    }

    // Return accumulate rewards over the given _from to _to block.
    function getGeneratedReward(uint256 _fromTime, uint256 _toTime) public view returns (uint256) {
        if (_fromTime >= _toTime) return 0;
        if (_toTime >= poolEndTime) {
            if (_fromTime >= poolEndTime) return 0;
            if (_fromTime <= poolStartTime) return poolEndTime.sub(poolStartTime).mul(gamePerSecond);
            return poolEndTime.sub(_fromTime).mul(gamePerSecond);
        } else {
            if (_toTime <= poolStartTime) return 0;
            if (_fromTime <= poolStartTime) return _toTime.sub(poolStartTime).mul(gamePerSecond);
            return _toTime.sub(_fromTime).mul(gamePerSecond);
        }
    }

    // View function to see pending GAME on frontend.
    function pendingGAME(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accGamePerShare = pool.accGamePerShare;
        uint256 tokenSupply = pool.token.balanceOf(address(this));
        if (block.timestamp > pool.lastRewardTime && tokenSupply != 0) {
            uint256 _generatedReward = getGeneratedReward(pool.lastRewardTime, block.timestamp);
            uint256 _gameReward = _generatedReward.mul(pool.allocPoint).div(totalAllocPoint);
            accGamePerShare = accGamePerShare.add(_gameReward.mul(1e18).div(tokenSupply));
        }
        return user.amount.mul(accGamePerShare).div(1e18).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() internal { // Too scared of scary reentrancy warnings. Internal version.
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function forceMassUpdatePools() external onlyAuthorized { // Too scared of scary reentrancy warnings. External version.
        massUpdatePools();
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) internal { // Too scared of scary reentrancy warnings. Internal version.
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }
        uint256 tokenSupply = pool.token.balanceOf(address(this));
        if (tokenSupply == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }
        if (!pool.isStarted) {
            pool.isStarted = true;
            totalAllocPoint = totalAllocPoint.add(pool.allocPoint); // Reentrancy issue? But this can't be used maliciously... Can it?  A malicious token is what we should be more worried about.
        }
        if (totalAllocPoint > 0) {
            uint256 _generatedReward = getGeneratedReward(pool.lastRewardTime, block.timestamp);
            uint256 _gameReward = _generatedReward.mul(pool.allocPoint).div(totalAllocPoint);
            pool.accGamePerShare = pool.accGamePerShare.add(_gameReward.mul(1e18).div(tokenSupply));
        }
        pool.lastRewardTime = block.timestamp;
    }

    // Update reward variables of the given pool to be up-to-date.
    function forceUpdatePool(uint256 _pid) external onlyAuthorized { // Too scared of scary reentrancy warnings. External version.
        updatePool(_pid);
    }

    // Deposit LP tokens.
    function deposit(uint256 _pid, uint256 _amount) public onlyOneBlock { // Poor smart contracts, can't deposit to multiple pools at once... But my OCD will not allow this.
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 _pending = user.amount.mul(pool.accGamePerShare).div(1e18).sub(user.rewardDebt);
            if (_pending > 0) {
                safeGameTransfer(_sender, _pending);
                emit RewardPaid(_sender, _pending);
            }
        }
        if (_amount > 0) {
            uint256 feeAmount = _amount.mul(depositFee).div(10000);
            uint256 amountToDeposit = _amount.sub(feeAmount);
            if(feeAmount > 0) pool.token.safeTransferFrom(_sender, treasury.daoFund(), feeAmount);
            pool.token.safeTransferFrom(_sender, address(this), amountToDeposit);
            user.amount = user.amount.add(amountToDeposit);
        }
        user.rewardDebt = user.amount.mul(pool.accGamePerShare).div(1e18);
        emit Deposit(_sender, _pid, _amount);
    }

    // Withdraw LP tokens.
    // No withdrawal fees or locks for Genesis Pools.
    function withdraw(uint256 _pid, uint256 _amount) public onlyOneBlock {
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 _pending = user.amount.mul(pool.accGamePerShare).div(1e18).sub(user.rewardDebt);
        if (_pending > 0) {
            safeGameTransfer(_sender, _pending);
            emit RewardPaid(_sender, _pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.token.safeTransfer(_sender, _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accGamePerShare).div(1e18);
        emit Withdraw(_sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public onlyOneBlock {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 _amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.token.safeTransfer(msg.sender, _amount);
        emit EmergencyWithdraw(msg.sender, _pid, _amount);
    }

    // Safe GAME transfer function, just in case if rounding error causes pool to not have enough GAMEs.
    function safeGameTransfer(address _to, uint256 _amount) internal {
        uint256 _gameBalance = game.balanceOf(address(this));
        if (_gameBalance > 0) {
            if (_amount > _gameBalance) {
                game.safeTransfer(_to, _gameBalance);
            } else {
                game.safeTransfer(_to, _amount);
            }
        }
    }

    function getRequiredAllocation() public view returns (uint256)
    {
        uint256 _generatedReward = getGeneratedReward(poolStartTime, poolEndTime);
        return _generatedReward;
    }

    function governanceRecoverUnsupported(IERC20 _token, uint256 amount, address to) external onlyOperator {
        if (block.timestamp < poolEndTime + 90 days) {
            // do not allow to drain core token (GAME or lps) if less than 90 days after pool ends
            require(_token != game, "game");
            uint256 length = poolInfo.length;
            for (uint256 pid = 0; pid < length; ++pid) {
                PoolInfo storage pool = poolInfo[pid];
                require(_token != pool.token, "pool.token");
            }
        }
        _token.safeTransfer(to, amount);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "../../interfaces/IERC20Lockable.sol";
import "../../interfaces/ITreasury.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";

contract AltergeneServer is Initializable, OwnableUpgradeable { //Handles server-facing functions on Harmony (cheapest EVM besides Bitgert which is unproven). Handles all achievements except credits-related ones.
    using SafeMathUpgradeable for uint256;

    //Strings
    /**
     * Upper
     *
     * Converts all the values of a string to their corresponding upper case
     * value.
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string base to convert to upper case
     * @return string
     */
    function upper(string memory _base)
    internal
    pure
    returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        for (uint i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _upper(_baseBytes[i]);
        }
        return string(_baseBytes);
    }

    /**
     * Upper
     *
     * Convert an alphabetic character to upper case and return the original
     * value when not alphabetic
     *
     * @param _b1 The byte to be converted to upper case
     * @return bytes1 The converted value if the passed value was alphabetic
     *                and in a lower case otherwise returns the original value
     */
    function _upper(bytes1 _b1)
    private
    pure
    returns (bytes1) {

        if (_b1 >= 0x61 && _b1 <= 0x7A) {
            return bytes1(uint8(_b1) - 32);
        }

        return _b1;
    }

    //Authorizable
    mapping(address => bool) public authorized;

    modifier onlyAuthorized() {
        require(authorized[msg.sender] || owner() == msg.sender, "caller is not authorized");
        _;
    }

    function addAuthorized(address _toAdd) public onlyOwner {
        authorized[_toAdd] = true;
    }

    function removeAuthorized(address _toRemove) public onlyOwner {
        require(_toRemove != msg.sender);
        authorized[_toRemove] = false;
    }

    //Preservation of values.
    mapping(address => uint256) public removedCredits; //AltergeneClient handles added credits.
    address public gameOperator;
    mapping(address => uint256) public personalBest;
    uint256[10] public highScores;
    address[10] public highScoreWinners;
    mapping(address => bool) public playing;

    modifier onlyGameOperator() {
        require(gameOperator == msg.sender
        //|| gameOperatorEU == msg.sender || gameOperatorSEA == msg.sender
        , "only game operator");
        _;
    }

    //Instead of constructor.
    function initialize(
        address _gameOperator
        ) public initializer {
        __Ownable_init();
        //master = _master;
        gameOperator = _gameOperator;
    }

    uint256 public lastSeasonalResetTime;
    uint256 public lastDailyResetTime;

    struct TopAchievement
    {
        address winner;
        uint256 value;
    }
    mapping (string => TopAchievement) public topAchievements;
    event TopAchievementObtained(string indexed achievement, address indexed from, uint256 value);
    function setTopAchievement(string memory achievement, address player, uint256 value) onlyGameOperator public
    {
        topAchievements[achievement] = TopAchievement(player,value);
        emit TopAchievementObtained(achievement, player, value);
    }

    mapping (address => mapping (string => uint256)) public achievements;
    event AchievementObtained(string indexed achievement, address indexed from, uint256 value);
    function setAchievement(string memory achievement, address player, uint256 value) onlyGameOperator public
    {
        achievements[player][achievement] = value;
        emit AchievementObtained(achievement, player, value);
    }

    mapping (string => TopAchievement) public topDailyAchievements;
    event TopDailyAchievementObtained(string indexed dailyAchievement, address indexed from, uint256 value);
    function setTopDailyAchievement(string memory dailyAchievement, address player, uint256 value) onlyGameOperator public
    {
        topDailyAchievements[dailyAchievement] = TopAchievement(player,value);
        emit TopDailyAchievementObtained(dailyAchievement, player, value);
    }

    event HighScoreObtained(address indexed from, uint256 indexed index, uint256 value);
    event UserFinishedPlaying(address indexed player);

    function canPlay(address player, uint256 addedCredits) public view returns (bool) {
        return !playing[player] && addedCredits > removedCredits[player];
    }

    function isPlaying(address player) public view returns (bool) {
        return playing[player];
    }

    function allHighScores() public view returns(uint256[10] memory) {
        return highScores;
    }

    function allHighScoreWinners() public view returns(address[10] memory) {
        return highScoreWinners;
    }

    //Deduct funds on a player's behalf
    function deductCredits(address player, uint256 addedCredits) onlyGameOperator public {
        require(canPlay(player, addedCredits), "Player not yet ready.");
        removedCredits[player] = removedCredits[player].add(1);
        playing[player] = true;
    }

//    function setOperators(address NA, address EU, address SEA) onlyAuthorized public
//    {
//        gameOperator = NA;
//        gameOperatorEU = EU;
//        gameOperatorSEA = SEA;
//    }

    //Refund funds on a player's behalf
    function refundCredits(address player) onlyGameOperator public {
        //Refund if server crashed before sending high score.
        require(isPlaying(player), "Can only refund if player was playing.");
        playing[player] = false;
        removedCredits[player] = removedCredits[player].sub(1);
    }

    function shouldWriteScore(address player, uint256 score) public view returns (bool)
    {
        //If we reset the high score, || score > highScore might be needed.
        return playing[player] && (score > personalBest[player] || score > highScores[9]);
    }

    function addHighScore(uint score, address winner) internal {
        uint256 i = 0;
        /** get the index of the current max element **/
        for(i; i < highScores.length; i++) {
            if(highScores[i] < score) {
                break;
            }
        }
        /** shift the array of one position (getting rid of the last element) **/
        for(uint256 j = highScores.length - 1; j > i; j--) {
            highScores[j] = highScores[j - 1];
            highScoreWinners[j] = highScoreWinners[j - 1];
        }
        /** update the new max element **/
        highScores[i] = score;
        highScoreWinners[i] = winner;
        emit HighScoreObtained(winner, i, score);
    }

    function writeAchievements(address player, string[] memory achievementKeys, uint256[] memory achievementValues) onlyGameOperator public {
        require(achievementKeys.length == achievementValues.length, "LEN");
        uint256 len = achievementKeys.length;
        uint256 i;
        for(i = 0; i < len; ++i)
        {
            string memory key = achievementKeys[i];
            uint256 value = achievementValues[i];
            if(value > achievements[player][key])
            {
                achievements[player][key] = value;
                emit AchievementObtained(key, player, value);
            }
            if(value > topAchievements[key].value)
            {
                topAchievements[key] = TopAchievement(player,value);
                emit TopAchievementObtained(key, player, value);
            }
            if(value > topDailyAchievements[key].value)
            {
                topDailyAchievements[key] = TopAchievement(player,value);
                emit TopDailyAchievementObtained(key, player, value);
            }
        }
    }

    function writeScore(address player, uint256 score, string[] memory achievementKeys, uint256[] memory achievementValues) onlyGameOperator public {
        require(shouldWriteScore(player, score), "No need to write score!"); //We should have checked already!
        if(score > personalBest[player]) personalBest[player] = score;
        if(score > highScores[9])
        {
            addHighScore(score, player);
        }
        writeAchievements(player, achievementKeys, achievementValues);
        playing[player] = false;
        emit UserFinishedPlaying(player);
    }

    function endSession(address player, uint256 score, string[] memory achievementKeys, uint256[] memory achievementValues) onlyGameOperator public {
        require(!shouldWriteScore(player, score), "Need to write score!"); //We should have checked already!
        writeAchievements(player, achievementKeys, achievementValues);
        playing[player] = false;
        emit UserFinishedPlaying(player);
    }

    function resetPersonalBest() public
    {
        personalBest[msg.sender] = 0;
    }

    function resetSeasonal(string[] memory achievementKeys) onlyAuthorized public {
        delete highScores;
        delete highScoreWinners;
        uint256 len = achievementKeys.length;
        uint256 i;
        for(i = 0; i < len; ++i)
        {
            delete topAchievements[achievementKeys[i]];
        }
        lastSeasonalResetTime = block.timestamp;
    }

    function resetDaily(string[] memory achievementKeys) onlyAuthorized public {
        uint256 len = achievementKeys.length;
        uint256 i;
        for(i = 0; i < len; ++i)
        {
            delete topDailyAchievements[achievementKeys[i]];
        }
        lastDailyResetTime = block.timestamp;
    }

    function getChainID() internal pure returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    //From: https://ethereum.stackexchange.com/questions/30912/how-to-compare-strings-in-solidity by Joel M Ward
    function memcmp(bytes memory a, bytes memory b) internal pure returns(bool){
        return (a.length == b.length) && (keccak256(a) == keccak256(b));
    }
    function strcmp(string memory a, string memory b) internal pure returns(bool){
        return memcmp(bytes(a), bytes(b));
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "../../interfaces/IERC20Lockable.sol";
import "../../interfaces/ITreasury.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";

contract AltergeneClient is Initializable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;
    
    //Strings
    /**
     * Upper
     *
     * Converts all the values of a string to their corresponding upper case
     * value.
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string base to convert to upper case
     * @return string
     */
    function upper(string memory _base)
    internal
    pure
    returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        for (uint i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _upper(_baseBytes[i]);
        }
        return string(_baseBytes);
    }

    /**
     * Upper
     *
     * Convert an alphabetic character to upper case and return the original
     * value when not alphabetic
     *
     * @param _b1 The byte to be converted to upper case
     * @return bytes1 The converted value if the passed value was alphabetic
     *                and in a lower case otherwise returns the original value
     */
    function _upper(bytes1 _b1)
    private
    pure
    returns (bytes1) {

        if (_b1 >= 0x61 && _b1 <= 0x7A) {
            return bytes1(uint8(_b1) - 32);
        }

        return _b1;
    }

    //Authorizable
    mapping(address => bool) public authorized;

    modifier onlyAuthorized() {
        require(authorized[msg.sender] || owner() == msg.sender, "caller is not authorized");
        _;
    }

    function addAuthorized(address _toAdd) public onlyOwner {
        authorized[_toAdd] = true;
    }

    function removeAuthorized(address _toRemove) public onlyOwner {
        require(_toRemove != msg.sender);
        authorized[_toRemove] = false;
    }

    //Preservation of values.
    mapping(address => uint256) public addedCredits; //Removed credits
    uint256 public gameCostPerCredit;
    IERC20Lockable public game;
    mapping(address => string) public nickname;
    address public treasury;

    //Instead of constructor.
    function initialize(IERC20Lockable _game, address _treasury) public initializer {
        __Ownable_init();
        gameCostPerCredit = 1 ether;
        game = _game;
        treasury = _treasury;
    }

    uint256 public totalCreditsPurchased;
    event CreditsPurchased(address indexed from, uint256 value);
    //For backlogging purposes
    function setCreditsPurchased(uint256 _amount) onlyAuthorized public
    {
        totalCreditsPurchased = _amount;
    }

    uint256 public lastSeasonalResetTime;
    struct CreditsTracking
    {
        uint256 lastCreditPurchaseTime;
        uint256 creditsPurchasedInTotal;
    }
    mapping(address => CreditsTracking) public creditsTracking;
    uint256 public topSpenderAmount;
    address public topSpenderWinner;

    function allHighScoreNicknames(address[10] memory highScoreWinners) public view returns(string[10] memory) {
        return [
        nickname[highScoreWinners[0]],
        nickname[highScoreWinners[1]],
        nickname[highScoreWinners[2]],
        nickname[highScoreWinners[3]],
        nickname[highScoreWinners[4]],
        nickname[highScoreWinners[5]],
        nickname[highScoreWinners[6]],
        nickname[highScoreWinners[7]],
        nickname[highScoreWinners[8]],
        nickname[highScoreWinners[9]]];
    }

    function airdropCredits(address player, uint256 amount) onlyAuthorized public
    {
        addedCredits[player] = addedCredits[player].add(amount); //Bypass max credits
    }

    function setAdmin(uint256 _gameCostPerCredit) onlyAuthorized public
    {
        gameCostPerCredit = _gameCostPerCredit;
    }

    function resetSeasonal(string[] memory achievementKeys) onlyAuthorized public {
        delete topSpenderAmount;
        delete topSpenderWinner;
        lastSeasonalResetTime = block.timestamp;
    }

    function changeNickname(string memory nick) public
    {
        require(bytes(nick).length <= 3, "Name too long.");
        nickname[msg.sender] = upper(nick);
    }

    function getChainID() internal pure returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    //From: https://ethereum.stackexchange.com/questions/30912/how-to-compare-strings-in-solidity by Joel M Ward
    function memcmp(bytes memory a, bytes memory b) internal pure returns(bool){
        return (a.length == b.length) && (keccak256(a) == keccak256(b));
    }
    function strcmp(string memory a, string memory b) internal pure returns(bool){
        return memcmp(bytes(a), bytes(b));
    }

    function _buyCreditsInternal(uint256 creditsAmount) internal
    {
        uint256 totalAmount = creditsAmount.mul(gameCostPerCredit);
        game.transferFrom(msg.sender, address(this), totalAmount);
        //Divide into fees. Total must be < 100
        //We have other things burning, Altergene's profit is so small/negative so there is no use not using all of it for revenue/treasury.
        uint256 toTreasury = totalAmount.mul(50).div(100);
//        uint256 toBurn = totalAmount.mul(30).div(100);
        uint256 toRevenue = totalAmount.mul(40).div(100);
        uint256 toGas = totalAmount.mul(10).div(100);
        uint256 chainId = getChainID();

        //TODO: Maybe MASTER and LP in the future?

        //Send to treasury
        game.transfer(treasury, toTreasury);
        //Burn
        //game.burn(toBurn);
        //Don't use a DEX for testnet
        if(chainId != 43113)
        {
            //Sell to USDC for revenue. For now, send to deployer to do it manually. (TODO: Automate this with swap).
            game.transfer(owner(), toRevenue);
            //Sell to ONE for gas. For now, send to deployer to do it manually. (TODO: Automate this with swap)
            game.transfer(owner(), toGas);
        }
        //Keep the rest in the coinbox for further distribution.

        addedCredits[msg.sender] = addedCredits[msg.sender].add(creditsAmount);
        if(creditsTracking[msg.sender].lastCreditPurchaseTime < lastSeasonalResetTime)
        {
            //Reset if last purchase was before reset date.
            creditsTracking[msg.sender].creditsPurchasedInTotal = creditsAmount;
        }
        else
        {
            creditsTracking[msg.sender].creditsPurchasedInTotal = creditsTracking[msg.sender].creditsPurchasedInTotal.add(creditsAmount);
        }
        creditsTracking[msg.sender].lastCreditPurchaseTime = block.timestamp;
        if(creditsTracking[msg.sender].creditsPurchasedInTotal > topSpenderAmount)
        {
            topSpenderAmount = creditsTracking[msg.sender].creditsPurchasedInTotal;
            topSpenderWinner = msg.sender;
        }
        totalCreditsPurchased = totalCreditsPurchased.add(creditsAmount);
        emit CreditsPurchased(msg.sender, creditsAmount);
    }

    function buyCredits(uint256 creditsAmount) public
    {
        _buyCreditsInternal(creditsAmount);
    }
}

pragma solidity 0.6.12;
import './interfaces/IOracle.sol';

contract MockOracle is IOracle {
    function update() public override {}

    function consult(address token, uint256 amountIn)
    external
    view
    override
    returns (uint144 amountOut)
    {
        return price;
    }

    function twap(address token, uint256 amountIn)
    external
    view
    override
    returns (uint144 amountOut)
    {
        return price;
    }

    uint144 private price = 10**18;

    function setPrice(uint144 price_) external {
        price = price_;
    }
}

pragma solidity ^0.6.0;

import '@openzeppelin/contracts/math/SafeMath.sol';

import '../owner/Operator.sol';

contract Epoch is Operator {
    using SafeMath for uint256;

    uint256 private period;
    uint256 private startTime;
    uint256 private lastEpochTime;
    uint256 private epoch;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        uint256 _period,
        uint256 _startTime,
        uint256 _startEpoch
    ) public {
        period = _period;
        startTime = _startTime;
        epoch = _startEpoch;
        lastEpochTime = startTime.sub(period);
    }

    /* ========== Modifier ========== */

    modifier checkStartTime {
        require(now >= startTime, 'Epoch: not started yet');

        _;
    }

    modifier checkEpoch {
        uint256 _nextEpochPoint = nextEpochPoint();
        if (now < _nextEpochPoint) {
            require(msg.sender == operator(), 'Epoch: only operator allowed for pre-epoch');
            _;
        } else {
            _;

            for (;;) {
                lastEpochTime = _nextEpochPoint;
                ++epoch;
                _nextEpochPoint = nextEpochPoint();
                if (now < _nextEpochPoint) break;
            }
        }
    }

    /* ========== VIEW FUNCTIONS ========== */

    function getCurrentEpoch() public view returns (uint256) {
        return epoch;
    }

    function getPeriod() public view returns (uint256) {
        return period;
    }

    function getStartTime() public view returns (uint256) {
        return startTime;
    }

    function getLastEpochTime() public view returns (uint256) {
        return lastEpochTime;
    }

    function nextEpochPoint() public view returns (uint256) {
        return lastEpochTime.add(period);
    }

    /* ========== GOVERNANCE ========== */

    function setPeriod(uint256 _period) external onlyOperator {
        require(_period >= 1 hours && _period <= 48 hours, '_period: out of range');
        period = _period;
    }

    function setEpoch(uint256 _epoch) external onlyOperator {
        epoch = _epoch;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./lib/Babylonian.sol";
import "./lib/FixedPoint.sol";
import "./lib/UniswapV2OracleLibrary.sol";
import "./utils/Epoch.sol";
import "./interfaces/IUniswapV2Pair.sol";

// fixed window oracle that recomputes the average price for the entire period once every period
// note that the price average is only guaranteed to be over at least 1 period, but may be over a longer period
contract Oracle is Epoch {
    using FixedPoint for *;
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    // uniswap
    address public token0;
    address public token1;
    IUniswapV2Pair public pair;

    // oracle
    uint32 public blockTimestampLast;
    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    FixedPoint.uq112x112 public price0Average;
    FixedPoint.uq112x112 public price1Average;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        IUniswapV2Pair _pair,
        uint256 _period,
        uint256 _startTime
    ) public Epoch(_period, _startTime, 0) {
        pair = _pair;
        token0 = pair.token0();
        token1 = pair.token1();
        price0CumulativeLast = pair.price0CumulativeLast(); // fetch the current accumulated price value (1 / 0)
        price1CumulativeLast = pair.price1CumulativeLast(); // fetch the current accumulated price value (0 / 1)
        uint112 reserve0;
        uint112 reserve1;
        (reserve0, reserve1, blockTimestampLast) = pair.getReserves();
        require(reserve0 != 0 && reserve1 != 0, "Oracle: NO_RESERVES"); // ensure that there's liquidity in the pair
    }

    /* ========== MUTABLE FUNCTIONS ========== */

    /** @dev Updates 1-day EMA price from Uniswap.  */
    function update() external checkEpoch {
        (uint256 price0Cumulative, uint256 price1Cumulative, uint32 blockTimestamp) = UniswapV2OracleLibrary.currentCumulativePrices(address(pair));
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired

        if (timeElapsed == 0) {
            // prevent divided by zero
            return;
        }

        // overflow is desired, casting never truncates
        // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
        price0Average = FixedPoint.uq112x112(uint224((price0Cumulative - price0CumulativeLast) / timeElapsed));
        price1Average = FixedPoint.uq112x112(uint224((price1Cumulative - price1CumulativeLast) / timeElapsed));

        price0CumulativeLast = price0Cumulative;
        price1CumulativeLast = price1Cumulative;
        blockTimestampLast = blockTimestamp;

        emit Updated(price0Cumulative, price1Cumulative);
    }

    // note this will always return 0 before update has been called successfully for the first time.
    function consult(address _token, uint256 _amountIn) external view returns (uint144 amountOut) {
        if (_token == token0) {
            amountOut = price0Average.mul(_amountIn).decode144();
        } else {
            require(_token == token1, "Oracle: INVALID_TOKEN");
            amountOut = price1Average.mul(_amountIn).decode144();
        }
    }
    function twap(address _token, uint256 _amountIn) external view returns (uint144 _amountOut) {

        (uint256 price0Cumulative, uint256 price1Cumulative, uint32 blockTimestamp) = UniswapV2OracleLibrary.currentCumulativePrices(address(pair));
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (_token == token0) {
            _amountOut = FixedPoint.uq112x112(uint224((price0Cumulative - price0CumulativeLast) / timeElapsed)).mul(_amountIn).decode144();
        } else if (_token == token1) {
            _amountOut = FixedPoint.uq112x112(uint224((price1Cumulative - price1CumulativeLast) / timeElapsed)).mul(_amountIn).decode144();
        }
    }

    event Updated(uint256 price0CumulativeLast, uint256 price1CumulativeLast);
}

pragma solidity ^0.6.0;

import "./FixedPoint.sol";
import "../interfaces/IUniswapV2Pair.sol";

// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
    using FixedPoint for *;

    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2**32);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(address pair)
        internal
        view
        returns (
            uint256 price0Cumulative,
            uint256 price1Cumulative,
            uint32 blockTimestamp
        )
    {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative += uint256(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
            // counterfactual
            price1Cumulative += uint256(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
        }
    }
}

pragma solidity ^0.6.0;

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
    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
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

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/IUniswapV2Pair.sol";

library UniswapV2Library {
    using SafeMath for uint256;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        factory,
                        keccak256(abi.encodePacked(token0, token1)),
                        hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
                    )
                )
            )
        );
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

pragma solidity 0.6.12;
import './interfaces/IOracleV2.sol';

contract MockOracleV2 is IOracleV2 {
    function update() public override {}
    function updateIfPossible() public override {}

    function consult(address token, uint256 amountIn)
    external
    view
    override
    returns (uint144 amountOut)
    {
        return price;
    }

    function twap(address token, uint256 amountIn)
    external
    view
    override
    returns (uint144 amountOut)
    {
        return price;
    }

    uint144 private price = 10**18;

    function setPrice(uint144 price_) external {
        price = price_;
    }

    function getPrice(address _token) external view override returns (uint256)
    {
        return price;
    }

    function getUpdatedPrice(address _token) external view override returns (uint256)
    {
        return price;
    }
}

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWrappedFtm is IERC20 {
    function deposit() external payable returns (uint256);

    function withdraw(uint256 amount) external returns (uint256);

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

import './libraries/SafeMath.sol';

contract UniswapV2ERC20 {
    using SafeMathUniswap for uint;

    string public constant name = 'Theory LP Token';
    string public constant symbol = 'TLP';
    uint8 public constant decimals = 18;
    uint  public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    constructor() public {
        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }

    function _mint(address to, uint value) internal {
        _beforeTokenTransfer(address(0), to, value);
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        _beforeTokenTransfer(from, address(0), value);
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        _beforeTokenTransfer(from, to, value);
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        if (allowance[from][msg.sender] != uint(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'UniswapV2: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'UniswapV2: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

import './UniswapV2ERC20.sol';
import './libraries/Math.sol';
import './libraries/UQ112x112.sol';
import './interfaces/IERC20Reward.sol';
import './interfaces/IUniswapV2Factory.sol';
import './interfaces/IUniswapV2Router02.sol';
import './interfaces/IUniswapV2Callee.sol';

interface IMigrator {
    // Return the desired amount of liquidity token that the migrator wants.
    function desiredLiquidity() external view returns (uint256);
}

contract UniswapV2Pair is UniswapV2ERC20 {
    using SafeMathUniswap  for uint;
    using UQ112x112 for uint224;

    uint public constant MINIMUM_LIQUIDITY = 10**3;
    uint public constant A_PRECISION = 100;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));
    bytes4 private constant BURN_SELECTOR = bytes4(keccak256(bytes('burn(uint256)')));

    address public factory;
    address public token0;
    address public token1;
    //GAME never changes address.
    bool public isGameLp;
    IERC20UniswapReward GAME;
    bool public burnBuybackToken;
    address[] public buybackRoute0;
    uint256 public buybackTokenIndex;
    address[] public buybackRoute1;

    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;           // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    uint public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    struct Amounts {
        uint256 reserve0;
        uint256 reserve1;
        uint256 In0;
        uint256 In1;
        uint256 OutTax0;
        uint256 OutTax1;
        address token0;
        address token1;
        bool hookedToken0;
        bool hookedToken1;
    }

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'UniswapV2: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    uint private tempLockCheck = 1;

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'UniswapV2: TRANSFER_FAILED');
    }

    //    function _burnToken(address token, uint value) private {
    //        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(BURN_SELECTOR, value));
    //        require(success && (data.length == 0 || abi.decode(data, (bool))), 'UniswapV2: BURN_FAILED');
    //    }

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

    constructor() public {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1, bool _burnBuybackToken, address[] memory _buybackRoute0, address[] memory _buybackRoute1) external {
        require(msg.sender == factory, 'UniswapV2: FORBIDDEN'); // sufficient check
        token0 = _token0;
        token1 = _token1;
        address _GAME = IUniswapV2Factory(factory).GAME();
        GAME = IERC20UniswapReward(_GAME);
        isGameLp = (_token0 == _GAME || _token1 == _GAME);
        //There will always be a buyback route. It defaults to GAME's.
        burnBuybackToken = _burnBuybackToken;
        buybackRoute0 = _buybackRoute0;
        buybackTokenIndex = _buybackRoute0.length-1;
        buybackRoute1 = _buybackRoute1;
    }

    function setBuybackRoute(bool _burnBuybackToken, address[] memory _buybackRoute0, address[] memory _buybackRoute1) external
    {
        require(msg.sender == factory, 'UniswapV2: FORBIDDEN'); // sufficient check
        //There will always be a buyback route. It defaults to GAME's.
        burnBuybackToken = _burnBuybackToken;
        buybackRoute0 = _buybackRoute0;
        buybackTokenIndex = _buybackRoute0.length-1;
        buybackRoute1 = _buybackRoute1;

    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'UniswapV2: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // if fee is on, mint liquidity equivalent to 1/5th of the growth in sqrt(k)
    // Since our fees are 0.25%, this is means LP gets 0.20%, and feeTo gets 0.05%.
    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        address feeTo = IUniswapV2Factory(factory).feeTo();
        address dev = IUniswapV2Factory(factory).devFund();
        feeOn = feeTo != address(0);
        uint _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint rootK = Math.sqrt(uint(_reserve0).mul(_reserve1));
                uint rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint numerator = totalSupply.mul(rootK.sub(rootKLast));
                    uint denominator = rootK.mul(4).add(rootKLast);
                    uint liquidity = numerator / denominator;
                    uint buyback = liquidity / 3; // 1/3 goes to buyback
                    uint team = liquidity / 4; // 1/4 goes to dev
                    uint revenue = liquidity.sub(buyback).sub(team); //5/12 goes to revenue
                    //Revenue (Dev)
                    if (team > 0) _mint(dev != address(0) ? dev : feeTo, team);
                    //Revenue (Treasury/Backup)
                    if (revenue > 0) _mint(feeTo, revenue);
                    //Buyback
                    address buybackContract = IUniswapV2Factory(factory).buybackContract();
                    if (buyback > 0) _mint(buybackContract != address(0) ? buybackContract : feeTo, buyback);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    function getBuybackRoute0() external view returns (address[] memory)
    {
        return buybackRoute0;
    }

    function getBuybackRoute1() external view returns (address[] memory)
    {
        return buybackRoute1;
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external lock returns (uint liquidity) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        uint balance0 = IERC20Uniswap(token0).balanceOf(address(this));
        uint balance1 = IERC20Uniswap(token1).balanceOf(address(this));
        uint amount0 = balance0.sub(_reserve0);
        uint amount1 = balance1.sub(_reserve1);

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            address migrator = IUniswapV2Factory(factory).migrator();
            if (msg.sender == migrator) {
                liquidity = IMigrator(migrator).desiredLiquidity();
                require(liquidity > 0 && liquidity != uint256(-1), "Bad desired liquidity");
            } else {
                require(migrator == address(0), "Must not have migrator");
                require(!IUniswapV2Factory(factory).createPairAdminOnly() || msg.sender == IUniswapV2Factory(factory).createPairAdmin(), 'UniswapV2: FORBIDDEN');
                liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
                _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
            }
        } else {
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        }
        require(liquidity > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);
        unlocked = 1;
        IUniswapV2Factory(factory).buyback();
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external lock returns (uint amount0, uint amount1) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        address _token0 = token0;                                // gas savings
        address _token1 = token1;                                // gas savings
        uint balance0 = IERC20Uniswap(_token0).balanceOf(address(this));
        uint balance1 = IERC20Uniswap(_token1).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IERC20Uniswap(_token0).balanceOf(address(this));
        balance1 = IERC20Uniswap(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
        unlocked = 1;
        IUniswapV2Factory(factory).buyback();
    }

    //NOTE: I don't have time to finish this, and it wasn't in the initial roadmap, but it would be pretty epic to have. I think removing the constant product formula could either aid or completely remove the need for a sell tax.
    //Perhaps a V2 of our swap/V3 of our token using these mechanics is in order if we get big enough. It might also be a better idea to just have it be its own project.
//    function getD(uint256[2] memory xp, uint256 amp) pure internal returns (uint256)
//    {
//        //D invariant calculation in non-overflowing integer operations
//            //iteratively
//        //A * sum(x_i) * n**n + D = A * D * n**n + D**(n+1) / (n**n * prod(x_i))
//        //Converging solution:
//        //D[j+1] = (A * n**n * sum(x_i) - D[j]**(n+1) / (n**n prod(x_i))) / (A * n**n - 1)
//        uint256 S = xp[0] + xp[1];
//
//        if (S == 0) return 0;
//
//        uint256 Dprev = 0;
//        uint256 D = S;
//        uint256 Ann = amp * 2;
//        for(uint _i = 0; i < 255; i += 1)
//        {
//            uint256 D_P = D;
//            D_P = D_P * D / (xp[0] * 2 + 1);  // +1 is to prevent /0
//            D_P = D_P * D / (xp[1] * 2 + 1);  // +1 is to prevent /0
//            Dprev = D;
//            D = (Ann * S / A_PRECISION + D_P * 2) * D / ((Ann - A_PRECISION) * D / A_PRECISION + (2 + 1) * D_P);
//            // Equality with the precision of 1
//            if (D > Dprev)
//            {
//                if (D - Dprev <= 1) return D;
//            }
//            else if (Dprev - D <= 1) return D;
//        }
//        // convergence typically occurs in 4 rounds or less, this should be unreachable!
//        // if it does happen the pool is borked and LPs can withdraw via `remove_liquidity`
//        revert("Pool is borked, please withdraw your liquidity.");
//    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock {
        //This could be gas-optimized a bit, though stack too deep and ordering makes it annoying to.
        require(tempLockCheck == 0 || !IUniswapV2Factory(factory).tempLock(), 'UniswapV2: FORBIDDEN');
        tempLockCheck = 0;
        require(amount0Out > 0 || amount1Out > 0, 'UniswapV2: INSUFFICIENT_OUTPUT_AMOUNT');
        //stack too deep even with these
        Amounts memory amount;
        {
            (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
            amount.reserve0 = _reserve0;
            amount.reserve1 = _reserve1;
            amount.token0 = token0;
            amount.token1 = token1;
            amount.hookedToken0 = IUniswapV2Factory(factory).hookedTokens(amount.token0);
            amount.hookedToken1 = IUniswapV2Factory(factory).hookedTokens(amount.token1);
        }
        require(amount0Out < amount.reserve0 && amount1Out < amount.reserve1, 'UniswapV2: INSUFFICIENT_LIQUIDITY');
        //amountOut is always how much is going out, INCLUDING output taxes which take from address to and redirect it to somewhere else.
        //It is the callee's job to calculate output taxes' effects (except in the case of flash swaps, see below).
        //It is the callee's job to send the input and output taxes.
        //It is the caller's job to calculate input taxes' effect on amountOut.
        {
            // scope for _token{0,1}, avoids stack too deep errors
            //_token{0,1} removed, stack too deep now even with changes
            require(to != amount.token0 && to != amount.token1, 'UniswapV2: INVALID_TO');


            //Flash swap is not supported for hooked tokens due to circular dependencies (we might need amountIn to calculate tax, but we also need the tax to calculate amountIn because we need to calculate the tax on amountOut to find amountIn).
            //You should flash swap a different token and swap it for the hooked one.
            if(!amount.hookedToken0 && !amount.hookedToken1)
            {
                if (amount0Out > 0) _safeTransfer(amount.token0, to, amount0Out); // optimistically transfer tokens
                if (amount1Out > 0) _safeTransfer(amount.token1, to, amount1Out); // optimistically transfer tokens
                if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
            }
            else
            {
                //Needed for stack too deep

                {
                    //We have not yet sent the balance, so no need to subtract amountOut.
                    uint balance0 = IERC20Uniswap(amount.token0).balanceOf(address(this));
                    uint balance1 = IERC20Uniswap(amount.token1).balanceOf(address(this));
                    amount.In0 = balance0 > amount.reserve0  ? balance0 - amount.reserve0 : 0;
                    amount.In1 = balance1 > amount.reserve1  ? balance1 - amount.reserve1 : 0;
                }
                require(amount.In0 > 0 || amount.In1 > 0, 'UniswapV2: INSUFFICIENT_INPUT_AMOUNT');
                if(amount.In0 > 0)
                {
                    if(amount.hookedToken0)
                    {
                        //NOTE: If needed, one can calculate the expected final amountIn/amountOut by checking if is a hooked token and calling expectedSellTax and/or expectedBuyTax as the router does if so.
                        //Because we have no control due to interactions like transfer being called between this and the router's call, there's no reason to complicate things with a beforeSell and/or forcing a view function.
                        //We recommend developers just use expectedSellTax in their onSell and don't rely on balances or change anything the sell tax is dependent on in the transfer function(s) to avoid errors.
                        (uint256[] memory taxIn, uint256[] memory taxOut, address[] memory taxTo) = IERC20UniswapHooked(amount.token0).onSell(amount.reserve0, amount.In0, to, amount.token1, amount.reserve1, amount1Out);
                        for(uint i; i < taxTo.length; i += 1) //Have to use .length each time due to stack too deep errors.
                        {
                            if(taxIn[i] > 0) _safeTransfer(amount.token0, taxTo[i], taxIn[i]); // optimistically transfer tokens
                            if(taxOut[i] > 0)
                            {
                                _safeTransfer(amount.token1, taxTo[i], taxOut[i]); // optimistically transfer tokens
                                amount.OutTax1 = amount.OutTax1.add(taxOut[i]);
                            }
                        }
                        IERC20UniswapHooked(amount.token0).afterSellTax(amount.reserve0, amount.In0, to, amount.token1, amount.reserve1, amount1Out);
                    }
                }
                if(amount.In1 > 0)
                {
                    if(amount.hookedToken1)
                    {
                        (uint256[] memory taxIn, uint256[] memory taxOut, address[] memory taxTo) = IERC20UniswapHooked(amount.token1).onSell(amount.reserve1, amount.In1, to, amount.token0, amount.reserve0, amount0Out);
                        for(uint i; i < taxTo.length; i += 1) //Have to use .length each time due to stack too deep errors.
                        {
                            if(taxIn[i] > 0) _safeTransfer(amount.token1, taxTo[i], taxIn[i]); // optimistically transfer tokens
                            if(taxOut[i] > 0)
                            {
                                _safeTransfer(amount.token0, taxTo[i], taxOut[i]); // optimistically transfer tokens
                                amount.OutTax0 = amount.OutTax0.add(taxOut[i]);
                            }
                        }
                        IERC20UniswapHooked(amount.token1).afterSellTax(amount.reserve1, amount.In1, to, amount.token0, amount.reserve0, amount0Out);
                    }
                }

                if (amount0Out > 0)
                {
                    if(amount.hookedToken0)
                    {
                        (uint256[] memory taxOut, uint256[] memory taxIn, address[] memory taxTo) = IERC20UniswapHooked(amount.token0).onBuy(amount.reserve0, amount0Out, to, amount.token1, amount.reserve1, amount.In1);
                        for(uint i; i < taxTo.length; i += 1) //Have to use .length each time due to stack too deep errors.
                        {
                            if(taxOut[i] > 0)
                            {
                                _safeTransfer(amount.token0, taxTo[i], taxOut[i]); // optimistically transfer tokens
                                amount.OutTax0 = amount.OutTax0.add(taxOut[i]); //Only need to keep track of taxOut.
                            }

                            if(taxIn[i] > 0) _safeTransfer(amount.token1, taxTo[i], taxIn[i]); // optimistically transfer tokens
                        }

                        IERC20UniswapHooked(amount.token0).afterBuyTax(amount.reserve0, amount0Out, to, amount.token1, amount.reserve1, amount.In1);
                    }
                }
                if (amount1Out > 0)
                {
                    if(amount.hookedToken1)
                    {
                        (uint256[] memory taxOut, uint256[] memory taxIn, address[] memory taxTo) = IERC20UniswapHooked(amount.token1).onBuy(amount.reserve1, amount1Out, to, amount.token0, amount.reserve0, amount.In0);
                        for(uint i; i < taxTo.length; i += 1) //Have to use .length each time due to stack too deep errors.
                        {
                            if(taxOut[i] > 0)
                            {
                                _safeTransfer(amount.token1, taxTo[i], taxOut[i]); // optimistically transfer tokens
                                amount.OutTax1 = amount.OutTax1.add(taxOut[i]); //Only need to keep track of taxOut.
                            }
                            if(taxIn[i] > 0) _safeTransfer(amount.token0, taxTo[i], taxIn[i]); // optimistically transfer tokens
                        }

                        IERC20UniswapHooked(amount.token1).afterBuyTax(amount.reserve1, amount1Out, to, amount.token0, amount.reserve0, amount.In0);
                    }
                }
//
                //Automatically calculate the rest to send to the to address.
                if (amount0Out.sub(amount.OutTax0) > 0) _safeTransfer(amount.token0, to, amount0Out.sub(amount.OutTax0)); // optimistically transfer tokens
                if (amount1Out.sub(amount.OutTax1) > 0) _safeTransfer(amount.token1, to, amount1Out.sub(amount.OutTax1)); // optimistically transfer tokens
            }
        }
        uint256 balance0 = IERC20Uniswap(amount.token0).balanceOf(address(this));
        uint256 balance1 = IERC20Uniswap(amount.token1).balanceOf(address(this));

        //All tax should still add up to amountOut, so no need to subtract from amountOut.
        uint256 amount0In = balance0 > amount.reserve0 - amount0Out ? balance0 - (amount.reserve0 - amount0Out) : 0;
        uint256 amount1In = balance1 > amount.reserve1 - amount1Out ? balance1 - (amount.reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'UniswapV2: INSUFFICIENT_INPUT_AMOUNT');

        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            uint balance0Adjusted = balance0.mul(10000).sub(amount0In.mul(25));
            uint balance1Adjusted = balance1.mul(10000).sub(amount1In.mul(25));
            //NOTE: I don't have time to finish this, and it wasn't in the initial roadmap, but it would be pretty epic to have. I think removing the constant product formula could either aid or completely remove the need for a sell tax.
            //Perhaps a V2 of our swap/V3 of our token using these mechanics is in order if we get big enough. It might also be a better idea to just have it be its own project.
            //            D = getD();
            //            A = 400000; //Adjustable
            //            g = 0.000145; //Adjustable
            //            t = (balance0Adjusted*balance1Adjusted*(2**2))/D;
            //            K = A*t*((g**2)/(g+1-t)**2);
            require(
            //NOTE: See above
            //K*D*(balance0Adjusted+balance1Adjusted)+balance0Adjusted*balance1Adjusted >= K*(D**2)+((D/2)**2),
                balance0Adjusted.mul(balance1Adjusted) >= uint(amount.reserve0).mul(amount.reserve1).mul(10000**2),
                'UniswapV2: K');
        }

        _update(balance0, balance1, uint112(amount.reserve0), uint112(amount.reserve1));
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // force balances to match reserves
    function skim(address to) external lock {
        require(!IUniswapV2Factory(factory).createPairAdminOnly() || msg.sender == IUniswapV2Factory(factory).createPairAdmin(), 'UniswapV2: FORBIDDEN');
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        _safeTransfer(_token0, to, IERC20Uniswap(_token0).balanceOf(address(this)).sub(reserve0));
        _safeTransfer(_token1, to, IERC20Uniswap(_token1).balanceOf(address(this)).sub(reserve1));
    }

    // force reserves to match balances
    function sync() external lock {
        require(!IUniswapV2Factory(factory).createPairAdminOnly() || msg.sender == IUniswapV2Factory(factory).createPairAdmin(), 'UniswapV2: FORBIDDEN');
        _update(IERC20Uniswap(token0).balanceOf(address(this)), IERC20Uniswap(token1).balanceOf(address(this)), reserve0, reserve1);
    }

    function _beforeTokenTransfer(address sender, address recipient, uint256 amount) internal override {
        if(isGameLp)
        {
            //Note that even though we update the rewards regardless of whitelist, we have to whitelist the LP token for eligibility.
            //This is to prevent people from making new LP to hog rewards.
            GAME.updateReward(sender);
            GAME.updateReward(recipient);
        }
        super._beforeTokenTransfer(sender, recipient, amount);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

// a library for performing various math operations

library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

import './interfaces/IUniswapV2Factory.sol';
import './interfaces/IUniswapV2Buyback.sol';
import './UniswapV2Pair.sol';

contract UniswapV2Factory is IUniswapV2Factory {
    address public override feeTo; //Treasury
    address public override devFund; //Dev
    address public override feeToSetter; //Deployer/MultiSigTimelock
    address public override migrator;
    address public override router;
    address public override createPairAdmin;
    bool public override createPairAdminOnly;
    bool public override tempLock;
    address public override GAME;
    bool public override useFee;
    address public override buybackContract;

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;

    mapping(address => bool) public override hookedTokens;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _GAME, address _feeTo, address _devFund) public {
        feeToSetter = msg.sender;
        createPairAdmin = msg.sender;
        feeTo = _feeTo;
        devFund = _devFund;
        uint chainId;
        assembly {
            chainId := chainid()
        }
        createPairAdminOnly = chainId != 43113; //Lock on deploy if we're not on testnet.
        tempLock = createPairAdminOnly; //Lock on deploy if we're not on testnet.
        GAME = _GAME;
        hookedTokens[_GAME] = true;
        useFee = true;
        //Don't forget to setRouter and setBuybackContract. Not here because addresses are not known yet.
        //Don't forget to setFeeToSetter and setCreatePairAdmin when ready for timelock.
    }

    function allPairsLength() external override view returns (uint) {
        return allPairs.length;
    }

    function pairCodeHash() external pure returns (bytes32) {
        return keccak256(type(UniswapV2Pair).creationCode);
    }

    function createPair(address tokenA, address tokenB, bool burnBuybackToken, address[] memory buybackRouteA, address[] memory buybackRouteB) external override returns (address pair) {
        require(msg.sender == createPairAdmin
        && buybackRouteA[0] == tokenA
        && buybackRouteB[0] == tokenB
        && buybackRouteA[buybackRouteA.length-1] == buybackRouteB[buybackRouteB.length-1]
        || !createPairAdminOnly && burnBuybackToken
        && buybackRouteA[0] == tokenA && buybackRouteA[buybackRouteA.length-1] == GAME
        && buybackRouteB[0] == tokenB && buybackRouteB[buybackRouteB.length-1] == GAME, 'UniswapV2: FORBIDDEN'); //Only admin can ignore routing rules.
        require(tokenA != tokenB, 'UniswapV2: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        (address[] memory buybackRoute0, address[] memory buybackRoute1) = tokenA < tokenB ? (buybackRouteA, buybackRouteB) : (buybackRouteB, buybackRouteA);
        require(token0 != address(0), 'UniswapV2: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'UniswapV2: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        UniswapV2Pair(pair).initialize(token0, token1, burnBuybackToken, buybackRoute0, buybackRoute1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external override {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setDevFund(address _devFund) external override {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        devFund = _devFund;
    }

    function setMigrator(address _migrator) external override {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        migrator = _migrator;
    }

    function setRouter(address _router) external override {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        router = _router;
    }

    function setFeeToSetter(address _feeToSetter) external override {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }

    function setCreatePairAdmin(address _admin) external override {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        createPairAdmin = _admin;
    }

    function setCreatePairAdminOnly(bool _admin) external override {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        createPairAdminOnly = _admin;
        if(!_admin) tempLock = false; //Disable once and don't allow enable after 1st time.
    }

    function changeHookedToken(address token, bool enabled) external override {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        hookedTokens[token] = enabled;
    }

    function setBuybackContract(address _contract) external override {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        buybackContract = _contract;
    }

    //Only pair can call this.
    function buyback() external override {
        if(buybackContract == address(0)) return;
        UniswapV2Pair pair = UniswapV2Pair(msg.sender);
        require(msg.sender == getPair[pair.token0()][pair.token1()], "UniswapV2: FORBIDDEN");
        useFee = false;
        IUniswapV2Buyback(buybackContract).buyback(address(pair)); //Only factory can call this.
        useFee = true;
    }

    function setBuybackRoute(address pair, bool burnBuybackToken, address[] memory buybackRoute0, address[] memory buybackRoute1) external override {
        require(msg.sender == createPairAdmin
        && buybackRoute0[0] == UniswapV2Pair(pair).token0()
        && buybackRoute1[0] == UniswapV2Pair(pair).token1()
        && buybackRoute0[buybackRoute0.length-1] == buybackRoute1[buybackRoute1.length-1], 'UniswapV2: FORBIDDEN');
        UniswapV2Pair(pair).setBuybackRoute(burnBuybackToken, buybackRoute0, buybackRoute1);
    }
}
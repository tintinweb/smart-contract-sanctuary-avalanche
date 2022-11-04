/**
 *Submitted for verification at snowtrace.io on 2022-11-04
*/

// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

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



pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}



pragma solidity >=0.5.0;

interface IUniswapV2Factory {
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

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}



pragma solidity >=0.8.0;

// @dev PangolinLibrary compliant with solidity v0.8.0+
// @dev Specific changes were made to remove SafeMath, type-cast pair addresses, and optimize gas use
library UniswapV2Library {
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint256(keccak256(abi.encodePacked(
            hex'ff',
            factory,
            keccak256(abi.encodePacked(token0, token1)),
            hex'9ebad18f8804368eff7d1a3614579a50254888eaf9a64ce3341b702938f458e7' // init code hash
        )))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) internal pure returns (uint256 amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA * reserveB / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint256 numerator = reserveIn * amountOut * 1000;
        uint256 denominator = (reserveOut - amountOut) * 997;
        amountIn = (numerator / denominator) + 1;
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint256 amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        unchecked {
            amounts = new uint[](path.length);
            amounts[0] = amountIn;
            for (uint256 i; i < path.length - 1; ++i) {
                (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i], path[i + 1]);
                amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
            }
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint256 amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        unchecked {
            amounts = new uint[](path.length);
            amounts[amounts.length - 1] = amountOut;
            for (uint256 i = path.length - 1; i > 0; --i) {
                (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i - 1], path[i]);
                amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
            }
        }
    }
}


pragma solidity >=0.5.0;

interface IERC20 {
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



pragma solidity >=0.8.0;


interface IUniswapV2RouterSupportingFees {
    function FACTORY() external view returns (address);
    function WETH() external view returns (address);

    function MAX_FEE() external view returns (uint24);
    function FEE_FLOOR() external view returns (uint24);

    struct FeeInfo {
        uint24 feePartner;
        uint24 feeProtocol;
        uint24 feeTotal;
        uint24 feeCut;
        bool initialized;
    }

    function getFeeInfo(address feeTo) view external returns (
        uint24 feePartner,
        uint24 feeProtocol,
        uint24 feeTotal,
        uint24 feeCut,
        bool initialized
    );

    event PartnerActivated(address indexed partner, uint24 feePartner, uint24 feeProtocol, uint24 feeTotal, uint24 feeCut);
    event FeeChange(address indexed partner, uint24 feePartner, uint24 feeProtocol, uint24 feeTotal, uint24 feeCut);
    event ProtocolFee(address indexed partner, address indexed token, uint256 amount);
    event PartnerFee(address indexed partner, address indexed token, uint256 amount);
    event FeeWithdrawn(address indexed token, uint256 amount, address to);
    event FeeFloorChange(uint24 feeFloor);
    event ManagerChange(address indexed partner, address manager, bool isAllowed);

    function managers(address partner, address manager) view external returns (bool isAllowed);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        address feeTo
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline,
        address feeTo
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        address feeTo
    ) external payable returns (uint[] memory amounts);
    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline,
        address feeTo
    ) external returns (uint[] memory amounts);
    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        address feeTo
    ) external returns (uint[] memory amounts);
    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline,
        address feeTo
    ) external payable returns (uint[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        address feeTo
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        address feeTo
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        address feeTo
    ) external;

    function activatePartner(address partner) external;
    function modifyManagement(address partner, address manager, bool isAllowed) external;
    function modifyTotalFee(address partner, uint24 feeTotal) external;
    function modifyFeeCut(address partner, uint24 feeCut) external;
    function modifyFeeFloor(uint24 feeFloor) external;
    function withdrawFees(address[] calldata tokens, uint256[] calldata amounts, address to) external;

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}



pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function balanceOf(address owner) external view returns (uint);
    function withdraw(uint) external;
}



pragma solidity ^0.8.0;


// @dev Router allowing percent fees to be charged on the output token of a swap
contract UniswapV2RouterSupportingFees is IUniswapV2RouterSupportingFees, Ownable {
    address public immutable override FACTORY;
    address public immutable override WETH;

    uint24 constant private BIPS = 100_00;
    uint24 constant private MAX_FEE_CUT = 50_00;
    uint24 constant private MAX_FEE_FLOOR = 30;
    uint24 constant public MAX_FEE = 2_00;
    uint24 public FEE_FLOOR = 0;

    // @dev Available externally via getFeeInfo(feeTo)
    mapping(address => FeeInfo) private feeInfos;

    // partner => manager => isAllowed
    mapping(address => mapping(address => bool)) public managers;

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "EXPIRED");
        _;
    }

    constructor(address _FACTORY, address _WETH, address firstOwner) {
        require(_FACTORY != address(0), "Invalid factory");
        require(_WETH != address(0), "Invalid wrapped currency");
        require(firstOwner != address(0), "Invalid first owner");
        FACTORY = _FACTORY;
        WETH = _WETH;
        transferOwnership(firstOwner);
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    // returns resulting balance to address(this)
    function _swap(uint256[] memory amounts, address[] memory path) internal {
        for (uint256 i; i < path.length - 1; ++i) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = UniswapV2Library.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(FACTORY, output, path[i + 2]) : address(this);
            IUniswapV2Pair(UniswapV2Library.pairFor(FACTORY, input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }
    function _distribute(
        uint256 userAmountOut,
        address tokenOut,
        address userTo,
        address partnerFeeTo,
        uint256 feeCut,
        uint256 feeTotalAmount
    ) internal {
        uint256 protocolFeeAmount = feeTotalAmount * feeCut / BIPS;
        uint256 partnerFeeAmount = feeTotalAmount - protocolFeeAmount;

        if (protocolFeeAmount > 0) {
            emit ProtocolFee(partnerFeeTo, tokenOut, protocolFeeAmount);
        }
        if (partnerFeeAmount > 0) {
            TransferHelper.safeTransfer(tokenOut, partnerFeeTo, partnerFeeAmount);
            emit PartnerFee(partnerFeeTo, tokenOut, partnerFeeAmount);
        }
        TransferHelper.safeTransfer(tokenOut, userTo, userAmountOut);
    }
    function _distributeETH(
        uint256 userAmountOut,
        address userTo,
        address partnerFeeTo,
        uint256 feeCut,
        uint256 feeTotalAmount
    ) internal {
        uint256 protocolFeeAmount = feeTotalAmount * feeCut / BIPS;
        uint256 partnerFeeAmount = feeTotalAmount - protocolFeeAmount;

        if (protocolFeeAmount > 0) {
            emit ProtocolFee(partnerFeeTo, WETH, protocolFeeAmount);
        }
        if (partnerFeeAmount > 0) {
            TransferHelper.safeTransfer(WETH, partnerFeeTo, partnerFeeAmount);
            emit PartnerFee(partnerFeeTo, WETH, partnerFeeAmount);
        }
        IWETH(WETH).withdraw(userAmountOut);
        TransferHelper.safeTransferETH(userTo, userAmountOut);
    }
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        address feeTo
    ) external ensure(deadline) returns (uint256[] memory amounts) {
        FeeInfo storage feeInfo = feeInfos[feeTo];
        require(feeInfo.initialized, "Invalid partner");

        amounts = UniswapV2Library.getAmountsOut(FACTORY, amountIn, path);

        uint256 feeTotalAmount;
        uint256 userAmountOut;

        { // Scope amountOut locally
            uint256 amountOut = amounts[amounts.length - 1];
            feeTotalAmount = amountOut * feeInfo.feeTotal / BIPS;
            userAmountOut = amountOut - feeTotalAmount;
        }

        require(userAmountOut >= amountOutMin, "INSUFFICIENT_OUTPUT_AMOUNT");

        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(FACTORY, path[0], path[1]), amountIn
        );

        _swap(amounts, path);
        _distribute(userAmountOut, path[path.length - 1], to, feeTo, feeInfo.feeCut, feeTotalAmount);
    }
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline,
        address feeTo
    ) external ensure(deadline) returns (uint256[] memory amounts) {
        FeeInfo storage feeInfo = feeInfos[feeTo];
        require(feeInfo.initialized, "Invalid partner");

        uint256 feeTotalAmount = amountOut * feeInfo.feeTotal / BIPS;

        // Adjust amountOut to include fee
        amounts = UniswapV2Library.getAmountsIn(FACTORY, amountOut + feeTotalAmount, path);
        uint256 amountIn = amounts[0];
        require(amountIn <= amountInMax, "EXCESSIVE_INPUT_AMOUNT");

        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(FACTORY, path[0], path[1]), amountIn
        );

        _swap(amounts, path);
        _distribute(amountOut, path[path.length - 1], to, feeTo, feeInfo.feeCut, feeTotalAmount);
    }
    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        address feeTo
    ) external payable ensure(deadline) returns (uint256[] memory amounts) {
        require(path[0] == WETH, "INVALID_PATH");

        FeeInfo storage feeInfo = feeInfos[feeTo];
        require(feeInfo.initialized, "Invalid partner");

        amounts = UniswapV2Library.getAmountsOut(FACTORY, msg.value, path);

        uint256 amountOut = amounts[amounts.length - 1];
        uint256 feeTotalAmount = amountOut * feeInfo.feeTotal / BIPS;
        uint256 userAmountOut = amountOut - feeTotalAmount;

        require(userAmountOut >= amountOutMin, "INSUFFICIENT_OUTPUT_AMOUNT");

        IWETH(WETH).deposit{value: msg.value}();
        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(FACTORY, WETH, path[1]), msg.value));

        _swap(amounts, path);
        _distribute(userAmountOut, path[path.length - 1], to, feeTo, feeInfo.feeCut, feeTotalAmount);
    }
    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline,
        address feeTo
    ) external ensure(deadline) returns (uint256[] memory amounts) {
        require(path[path.length - 1] == WETH, "INVALID_PATH");

        FeeInfo storage feeInfo = feeInfos[feeTo];
        require(feeInfo.initialized, "Invalid partner");

        uint256 feeTotalAmount = amountOut * feeInfo.feeTotal / BIPS;

        // Adjust amountOut to include fee
        amounts = UniswapV2Library.getAmountsIn(FACTORY, amountOut + feeTotalAmount, path);
        uint256 amountIn = amounts[0];
        require(amountIn <= amountInMax, "EXCESSIVE_INPUT_AMOUNT");

        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(FACTORY, path[0], path[1]), amountIn
        );

        _swap(amounts, path);
        _distributeETH(amountOut, to, feeTo, feeInfo.feeCut, feeTotalAmount);
    }
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        address feeTo
    ) external ensure(deadline) returns (uint256[] memory amounts) {
        require(path[path.length - 1] == WETH, "INVALID_PATH");

        FeeInfo storage feeInfo = feeInfos[feeTo];
        require(feeInfo.initialized, "Invalid partner");

        amounts = UniswapV2Library.getAmountsOut(FACTORY, amountIn, path);

        uint256 feeTotalAmount;
        uint256 userAmountOut;

        { // Scope amountOut locally
            uint256 amountOut = amounts[amounts.length - 1];
            feeTotalAmount = amountOut * feeInfo.feeTotal / BIPS;
            userAmountOut = amountOut - feeTotalAmount;
        }

        require(userAmountOut >= amountOutMin, "INSUFFICIENT_OUTPUT_AMOUNT");

        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(FACTORY, path[0], path[1]), amounts[0]
        );

        _swap(amounts, path);
        _distributeETH(userAmountOut, to, feeTo, feeInfo.feeCut, feeTotalAmount);
    }
    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline,
        address feeTo
    ) external payable ensure(deadline) returns (uint256[] memory amounts) {
        require(path[0] == WETH, "INVALID_PATH");

        FeeInfo storage feeInfo = feeInfos[feeTo];
        require(feeInfo.initialized, "Invalid partner");

        uint256 feeTotalAmount = amountOut * feeInfo.feeTotal / BIPS;

        // Adjust amountOut to include fee
        amounts = UniswapV2Library.getAmountsIn(FACTORY, amountOut + feeTotalAmount, path);
        uint256 amountIn = amounts[0];
        require(amountIn <= msg.value, "EXCESSIVE_INPUT_AMOUNT");

        IWETH(WETH).deposit{value: amountIn}();
        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(FACTORY, WETH, path[1]), amountIn));

        _swap(amounts, path);
        _distribute(amountOut, path[path.length - 1], to, feeTo, feeInfo.feeCut, feeTotalAmount);

        // refund dust ETH, if any
        if (msg.value > amountIn) TransferHelper.safeTransferETH(msg.sender, msg.value - amountIn);
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    // returns resulting balance to address(this)
    function _swapSupportingFeeOnTransferTokens(address[] memory path) internal {
        for (uint256 i; i < path.length - 1; ++i) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = UniswapV2Library.sortTokens(input, output);
            IUniswapV2Pair pair = IUniswapV2Pair(UniswapV2Library.pairFor(FACTORY, input, output));
            uint256 amountInput;
            uint256 amountOutput;
            { // scope to avoid stack too deep errors
            (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
            (uint256 reserveInput, uint256 reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            amountInput = IERC20(input).balanceOf(address(pair)) - reserveInput;
            amountOutput = UniswapV2Library.getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint256 amount0Out, uint256 amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(FACTORY, output, path[i + 2]) : address(this);
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        address feeTo
    ) external ensure(deadline) {
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(FACTORY, path[0], path[1]), amountIn
        );
        address tokenOut = path[path.length - 1];
        uint256 balanceBefore = IERC20(tokenOut).balanceOf(to);
        uint256 amountOut = IERC20(tokenOut).balanceOf(address(this));
        _swapSupportingFeeOnTransferTokens(path);
        amountOut = IERC20(tokenOut).balanceOf(address(this)) - amountOut; // Ensures stored fees are safe

        FeeInfo storage feeInfo = feeInfos[feeTo];
        require(feeInfo.initialized, "Invalid partner");
        uint256 feeTotalAmount = amountOut * feeInfo.feeTotal / BIPS;

        _distribute(amountOut - feeTotalAmount, tokenOut, to, feeTo, feeInfo.feeCut, feeTotalAmount);

        require(
            IERC20(tokenOut).balanceOf(to) - balanceBefore >= amountOutMin,
            "INSUFFICIENT_OUTPUT_AMOUNT"
        );
    }
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        address feeTo
    ) external payable ensure(deadline) {
        require(path[0] == WETH, "INVALID_PATH");
        IWETH(WETH).deposit{value: msg.value}();
        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(FACTORY, WETH, path[1]), msg.value));
        address tokenOut = path[path.length - 1];
        uint256 balanceBefore = IERC20(tokenOut).balanceOf(to);
        uint256 amountOut = IERC20(tokenOut).balanceOf(address(this));
        _swapSupportingFeeOnTransferTokens(path);
        amountOut = IERC20(tokenOut).balanceOf(address(this)) - amountOut; // Ensures stored fees are safe

        FeeInfo storage feeInfo = feeInfos[feeTo];
        require(feeInfo.initialized, "Invalid partner");
        uint256 feeTotalAmount = amountOut * feeInfo.feeTotal / BIPS;

        _distribute(amountOut - feeTotalAmount, tokenOut, to, feeTo, feeInfo.feeCut, feeTotalAmount);

        require(
            IERC20(tokenOut).balanceOf(to) - balanceBefore >= amountOutMin,
            "INSUFFICIENT_OUTPUT_AMOUNT"
        );
    }
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        address feeTo
    ) external ensure(deadline) {
        require(path[path.length - 1] == WETH, "INVALID_PATH");
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(FACTORY, path[0], path[1]), amountIn
        );
        uint256 amountOut = IERC20(WETH).balanceOf(address(this));
        _swapSupportingFeeOnTransferTokens(path);
        amountOut = IERC20(WETH).balanceOf(address(this)) - amountOut; // Ensures stored fees are safe

        FeeInfo storage feeInfo = feeInfos[feeTo];
        require(feeInfo.initialized, "Invalid partner");
        uint256 feeTotalAmount = amountOut * feeInfo.feeTotal / BIPS;
        uint256 userAmountOut = amountOut - feeTotalAmount;
        require(userAmountOut >= amountOutMin, "INSUFFICIENT_OUTPUT_AMOUNT");

        _distributeETH(userAmountOut, to, feeTo, feeInfo.feeCut, feeTotalAmount);
    }

    // **** FEE FUNCTIONS ****
    function getFeeInfo(address feeTo) external view returns (
        uint24 feePartner,
        uint24 feeProtocol,
        uint24 feeTotal,
        uint24 feeCut,
        bool initialized
    ) {
        FeeInfo storage feeInfo = feeInfos[feeTo];
        return (
            feeInfo.feePartner,
            feeInfo.feeProtocol,
            feeInfo.feeTotal,
            feeInfo.feeCut,
            feeInfo.initialized
        );
    }
    function activatePartner(address partner) external {
        FeeInfo storage feeInfo = feeInfos[partner];
        require(!feeInfo.initialized, "Already initialized");

        uint24 feeFloor = FEE_FLOOR; // Gas savings

        if (feeFloor > 0) {
            (uint24 feeProtocol, uint24 feePartner) = _calculateFees(feeFloor, MAX_FEE_CUT);
            feeInfo.feeTotal = feeFloor;
            feeInfo.feePartner = feePartner;
            feeInfo.feeProtocol = feeProtocol;
        }

        feeInfo.feeCut = MAX_FEE_CUT;
        feeInfo.initialized = true;

        emit PartnerActivated(partner, feeInfo.feePartner, feeInfo.feeProtocol, feeInfo.feeTotal, MAX_FEE_CUT);
    }
    function modifyManagement(address partner, address manager, bool isAllowed) external {
        require(msg.sender == partner || msg.sender == owner(), "Permission denied");

        require(feeInfos[partner].initialized, "Not initialized");
        require(managers[partner][manager] != isAllowed, "No change required");

        managers[partner][manager] = isAllowed;

        emit ManagerChange(partner, manager, isAllowed);
    }
    function modifyTotalFee(address partner, uint24 feeTotal) external {
        require(msg.sender == partner || msg.sender == owner() || managers[partner][msg.sender], "Permission denied");

        require(feeTotal <= MAX_FEE, "Excessive total fee");
        require(feeTotal >= FEE_FLOOR, "Insufficient total fee");

        FeeInfo storage feeInfo = feeInfos[partner];
        require(feeInfo.initialized, "Not initialized");
        require(feeInfo.feeTotal != feeTotal, "No change required");

        (uint24 feeProtocol, uint24 feePartner) = _calculateFees(feeTotal, feeInfo.feeCut);

        feeInfo.feePartner = feePartner;
        feeInfo.feeProtocol = feeProtocol;
        feeInfo.feeTotal = feeTotal;

        emit FeeChange(partner, feePartner, feeProtocol, feeTotal, feeInfo.feeCut);
    }
    function modifyFeeCut(address partner, uint24 feeCut) external {
        require(msg.sender == owner(), "Permission denied");

        require(feeCut <= MAX_FEE_CUT, "Excessive fee cut");

        FeeInfo storage feeInfo = feeInfos[partner];
        require(feeInfo.initialized, "Not initialized");
        require(feeInfo.feeCut != feeCut, "No change required");

        (uint24 feeProtocol, uint24 feePartner) = _calculateFees(feeInfo.feeTotal, feeCut);

        feeInfo.feePartner = feePartner;
        feeInfo.feeProtocol = feeProtocol;
        feeInfo.feeCut = feeCut;

        emit FeeChange(partner, feePartner, feeProtocol, feeInfo.feeTotal, feeCut);
    }
    function modifyFeeFloor(uint24 feeFloor) external {
        require(msg.sender == owner(), "Permission denied");
        require(feeFloor <= MAX_FEE_FLOOR, "Excessive fee floor");
        FEE_FLOOR = feeFloor;
        emit FeeFloorChange(feeFloor);
    }
    function withdrawFees(address[] calldata tokens, uint256[] calldata amounts, address to) external {
        require(msg.sender == owner(), "Permission denied");
        uint256 tokensLength = tokens.length;
        require(tokensLength == amounts.length, "Mismatched array lengths");
        for (uint256 i; i < tokensLength; ++i) {
            TransferHelper.safeTransfer(tokens[i], to, amounts[i]);
            emit FeeWithdrawn(tokens[i], amounts[i], to);
        }
    }

    function _calculateFees(
        uint24 feeTotal,
        uint24 feeCut
    ) private pure returns (uint24 feeProtocol, uint24 feePartner) {
        unchecked {
            feeProtocol = feeTotal * feeCut / BIPS; // Range [ 0, MAX_FEE:200 ]
            feePartner = feeTotal - feeProtocol; // Range [ 0, MAX_FEE:200 ]
        }
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) public pure returns (uint256 amountB) {
        return UniswapV2Library.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        public
        pure
        returns (uint256 amountOut)
    {
        return UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut)
        public
        pure
        returns (uint256 amountIn)
    {
        return UniswapV2Library.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(uint256 amountIn, address[] memory path)
        public
        view
        returns (uint256[] memory amounts)
    {
        return UniswapV2Library.getAmountsOut(FACTORY, amountIn, path);
    }

    function getAmountsIn(uint256 amountOut, address[] memory path)
        public
        view
        returns (uint256[] memory amounts)
    {
        return UniswapV2Library.getAmountsIn(FACTORY, amountOut, path);
    }

}
/**
 *Submitted for verification at snowtrace.io on 2022-04-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

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

// import "hardhat/console.sol";

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}
interface IERC20 {
      function balanceOf(address account) external returns (uint256);
}

library SafeMath {
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
library RevertReasonParser {
    function parse(bytes memory data, string memory prefix) internal pure returns (string memory) {
        // https://solidity.readthedocs.io/en/latest/control-structures.html#revert
        // We assume that revert reason is abi-encoded as Error(string)

        // 68 = 4-byte selector 0x08c379a0 + 32 bytes offset + 32 bytes length
        if (data.length >= 68 && data[0] == "\x08" && data[1] == "\xc3" && data[2] == "\x79" && data[3] == "\xa0") {
            string memory reason;
            // solhint-disable no-inline-assembly
            assembly {
                // 68 = 32 bytes data length + 4-byte selector + 32 bytes offset
                reason := add(data, 68)
            }

            require(data.length >= 68 + bytes(reason).length, "Invalid revert reason");
            return string(abi.encodePacked(prefix, "Error(", reason, ")"));
        }
        // 36 = 4-byte selector 0x4e487b71 + 32 bytes integer
        else if (data.length == 36 && data[0] == "\x4e" && data[1] == "\x48" && data[2] == "\x7b" && data[3] == "\x71") {
            uint256 code;
            // solhint-disable no-inline-assembly
            assembly {
                // 36 = 32 bytes data length + 4-byte selector
                code := mload(add(data, 36))
            }
            return string(abi.encodePacked(prefix, "Panic(", _toHex(code), ")"));
        }

        return string(abi.encodePacked(prefix, "Unknown()"));
    }

    function _toHex(uint256 value) private pure returns(string memory) {
        return _toHex(abi.encodePacked(value));
    }

    function _toHex(bytes memory data) private pure returns(string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < data.length; i++) {
            str[2 * i + 2] = alphabet[uint8(data[i] >> 4)];
            str[2 * i + 3] = alphabet[uint8(data[i] & 0x0f)];
        }
        return string(str);
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    // function renounceOwnership() public virtual onlyOwner {
    //     _transferOwnership(address(0));
    // }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract Caller is Ownable {
    using SafeMath for uint;

    address public feeTo;
    uint8 public fee = 1;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'ChaingeAggregationRouter: EXPIRED');
        _;
    }
    
    struct SwapInfo {
        address WETH;
        bytes initCodeHash;
        uint swapFeenNumerator;
        uint swapFeeDenominator;
    }
    // factory => SwapInfo;
    mapping (address => SwapInfo) public swapInfo;

    mapping (address=>bool) public controller;

    constructor() {
    }

    function makeCalls(bytes[] calldata datas, uint256 gas) public {

        require(controller[msg.sender] || owner() == msg.sender, "caller is not the owner or controller");

        for (uint i = 0; i < datas.length;i++){
            (bool success, bytes memory _data) = address(this).delegatecall{gas:gas}(datas[i]);
            require(success, RevertReasonParser.parse(_data, "Swap failed: "));
        }
    }

    function setSwapInfo(address factory,  address WETH, bytes calldata initCodeHash, uint swapFeenNumerator, uint swapFeeDenominator ) external onlyOwner {
        swapInfo[factory] = SwapInfo(WETH, initCodeHash, swapFeenNumerator, swapFeeDenominator);
    }

    function swapExactTokensForTokens(
        address factory,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )external virtual ensure(deadline) returns (uint[] memory amounts)  {
        require(amountIn <= IERC20(path[0]).balanceOf(msg.sender), "insufficient minter balance");

        amounts = getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'ChaingeAggregationRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(factory, amounts, path, to);
    }

    function swapTokensForExactTokens(
        address factory,
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual ensure(deadline) returns (uint[] memory amounts) {
        amounts = getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'ChaingeAggregationRouter: EXCESSIVE_INPUT_AMOUNT');
        require(amounts[0] <= IERC20(path[0]).balanceOf(msg.sender), "insufficient minter balance");

        TransferHelper.safeTransferFrom(
            path[0], msg.sender, pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(factory, amounts, path, to);
    }

    function swapExactETHForTokens(
        address factory,
        uint amountOutMin, 
        address[] calldata path, 
        address to, uint deadline
    )
        external
        virtual
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == swapInfo[factory].WETH, 'ChaingeAggregationRouter: INVALID_PATH');
        amounts = getAmountsOut(factory, msg.value, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'ChaingeAggregationRouter: INSUFFICIENT_OUTPUT_AMOUNT');

        require(amounts[0] <=  msg.value, "insufficient minter balance");
        IWETH(swapInfo[factory].WETH).deposit{value: amounts[0]}();
        assert(IWETH(swapInfo[factory].WETH).transfer(pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(factory, amounts, path, to);
    }
    function swapTokensForExactETH(
        address factory,
        uint amountOut, 
        uint amountInMax, 
        address[] calldata path, 
        address to, 
        uint deadline)
        external
        virtual
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == swapInfo[factory].WETH, 'ChaingeAggregationRouter: INVALID_PATH');
        amounts = getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'ChaingeAggregationRouter: EXCESSIVE_INPUT_AMOUNT');

       require(amounts[0] <= IERC20(path[0]).balanceOf(msg.sender), "insufficient minter balance");
        
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(factory, amounts, path, address(this));
        IWETH(swapInfo[factory].WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    function swapExactTokensForETH(
        address factory,
        uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == swapInfo[factory].WETH, 'ChaingeAggregationRouter: INVALID_PATH');
        amounts = getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'ChaingeAggregationRouter: INSUFFICIENT_OUTPUT_AMOUNT');

        require(amounts[0] <= IERC20(path[0]).balanceOf(msg.sender), "insufficient minter balance");
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(factory, amounts, path, address(this));
        IWETH(swapInfo[factory].WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    
    function swapETHForExactTokens(
        address factory,
        uint amountOut, address[] calldata path, address to, uint deadline)
        external
        virtual
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == swapInfo[factory].WETH, 'ChaingeAggregationRouter: INVALID_PATH');
        amounts = getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= msg.value, 'ChaingeAggregationRouter: EXCESSIVE_INPUT_AMOUNT');
        
        IWETH(swapInfo[factory].WETH).deposit{value: amounts[0]}();
        assert(IWETH(swapInfo[factory].WETH).transfer(pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(factory, amounts, path, to);
        if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }


     // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(address factory, uint[] memory amounts, address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? pairFor(factory, output, path[i + 2]) : _to;
            IUniswapV2Pair(pairFor(factory, input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }
    
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'ChaingeAggregationRouter: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'ChaingeAggregationRouter: ZERO_ADDRESS');
    }
        // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) public view returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);

        bytes memory initCodeHash = swapInfo[factory].initCodeHash;
        pair = address(uint160(uint(keccak256(abi.encodePacked(
            hex'ff',
            factory,
            keccak256(abi.encodePacked(token0, token1)),
            initCodeHash
        )))));
    }

        // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut,  uint swapFeenNumerator, uint swapFeeDenominator) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'ChaingeAggregationRouter: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'ChaingeAggregationRouter: INSUFFICIENT_LIQUIDITY');

        // swapFeenNumerator, swapFeeDenominator
        uint amountInWithFee = amountIn.mul(swapFeenNumerator);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(swapFeeDenominator).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut,  uint swapFeenNumerator, uint swapFeeDenominator) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'ChaingeAggregationRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'ChaingeAggregationRouter: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(swapFeeDenominator);
        uint denominator = reserveOut.sub(amountOut).mul(swapFeenNumerator);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'ChaingeAggregationRouter: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        uint swapFeenNumerator = swapInfo[factory].swapFeenNumerator;
        uint swapFeeDenominator = swapInfo[factory].swapFeeDenominator;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut, swapFeenNumerator, swapFeeDenominator);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'ChaingeAggregationRouter: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        uint swapFeenNumerator = swapInfo[factory].swapFeenNumerator;
        uint swapFeeDenominator = swapInfo[factory].swapFeeDenominator;

        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut, swapFeenNumerator, swapFeeDenominator);
        }
    }

        // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }
}
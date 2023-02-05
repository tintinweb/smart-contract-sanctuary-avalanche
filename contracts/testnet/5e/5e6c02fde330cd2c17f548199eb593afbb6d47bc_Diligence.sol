// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Simple single owner authorization mixin.
/// @author Solbase (https://github.com/Sol-DAO/solbase/blob/main/src/auth/Owned.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /// -----------------------------------------------------------------------
    /// Custom Errors
    /// -----------------------------------------------------------------------

    error Unauthorized();

    /// -----------------------------------------------------------------------
    /// Ownership Storage
    /// -----------------------------------------------------------------------

    address public owner;

    modifier onlyOwner() virtual {
        if (msg.sender != owner) revert Unauthorized();

        _;
    }

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /// -----------------------------------------------------------------------
    /// Ownership Logic
    /// -----------------------------------------------------------------------

    function transferOwnership(address newOwner) public payable virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Modern, minimalist, and gas-optimized ERC20 implementation.
/// @author SolDAO (https://github.com/Sol-DAO/solbase/blob/main/src/tokens/ERC20/ERC20.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20/ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /// -----------------------------------------------------------------------
    /// Metadata Storage
    /// -----------------------------------------------------------------------

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /// -----------------------------------------------------------------------
    /// ERC20 Storage
    /// -----------------------------------------------------------------------

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    /// -----------------------------------------------------------------------
    /// ERC20 Logic
    /// -----------------------------------------------------------------------

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /// -----------------------------------------------------------------------
    /// Internal Mint/Burn Logic
    /// -----------------------------------------------------------------------

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC20} from "./ERC20/ERC20.sol";
import {SafeTransferLib} from "../utils/SafeTransferLib.sol";

/// @notice Minimalist and modern Wrapped Ether implementation.
/// @author SolDAO (https://github.com/Sol-DAO/solbase/blob/main/src/tokens/WETH.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/WETH.sol)
contract WETH is ERC20("Wrapped Ether", "WETH", 18) {
    using SafeTransferLib for address;

    event Deposit(address indexed from, uint256 amount);

    event Withdrawal(address indexed to, uint256 amount);

    function deposit() public payable virtual {
        _mint(msg.sender, msg.value);

        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public virtual {
        _burn(msg.sender, amount);

        emit Withdrawal(msg.sender, amount);

        msg.sender.safeTransferETH(amount);
    }

    receive() external payable virtual {
        deposit();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author SolDAO (https://github.com/Sol-DAO/solbase/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Solady (https://github.com/vectorized/solady/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Caution! This library won't check that a token has code, responsibility is delegated to the caller.
library SafeTransferLib {
    /// -----------------------------------------------------------------------
    /// Custom Errors
    /// -----------------------------------------------------------------------

    /// @dev The ETH transfer has failed.
    error ETHTransferFailed();

    /// @dev The ERC20 `approve` has failed.
    error ApproveFailed();

    /// @dev The ERC20 `transfer` has failed.
    error TransferFailed();

    /// @dev The ERC20 `transferFrom` has failed.
    error TransferFromFailed();

    /// -----------------------------------------------------------------------
    /// ETH Operations
    /// -----------------------------------------------------------------------

    /// @dev Sends `amount` (in wei) ETH to `to`.
    /// Reverts upon failure.
    function safeTransferETH(address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(gas(), to, amount, 0, 0, 0, 0)) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
    }

    /// -----------------------------------------------------------------------
    /// ERC20 Operations
    /// -----------------------------------------------------------------------

    /// @dev Sets `amount` of ERC20 `token` for `to` to manage on behalf of the current contract.
    /// Reverts upon failure.
    function safeApprove(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0x00, 0x095ea7b3)
            mstore(0x20, to) // Append the "to" argument.
            mstore(0x40, amount) // Append the "amount" argument.

            if iszero(
                and(
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    // We use 0x44 because that's the total length of our calldata (0x04 + 0x20 * 2)
                    // Counterintuitively, this call() must be positioned after the or() in the
                    // surrounding and() because and() evaluates its arguments from right to left.
                    call(gas(), token, 0, 0x1c, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `ApproveFailed()`.
                mstore(0x00, 0x3e3f8f73)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x40, memPointer) // Restore the memPointer.
        }
    }

    /// @dev Sends `amount` of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function safeTransfer(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0x00, 0xa9059cbb)
            mstore(0x20, to) // Append the "to" argument.
            mstore(0x40, amount) // Append the "amount" argument.

            if iszero(
                and(
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    // We use 0x44 because that's the total length of our calldata (0x04 + 0x20 * 2)
                    // Counterintuitively, this call() must be positioned after the or() in the
                    // surrounding and() because and() evaluates its arguments from right to left.
                    call(gas(), token, 0, 0x1c, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFailed()`.
                mstore(0x00, 0x90b8ec18)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x40, memPointer) // Restore the memPointer.
        }
    }

    /// @dev Sends `amount` of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have at least `amount` approved for
    /// the current contract to manage.
    function safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0x00, 0x23b872dd)
            mstore(0x20, from) // Append the "from" argument.
            mstore(0x40, to) // Append the "to" argument.
            mstore(0x60, amount) // Append the "amount" argument.

            if iszero(
                and(
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    // We use 0x64 because that's the total length of our calldata (0x04 + 0x20 * 3)
                    // Counterintuitively, this call() must be positioned after the or() in the
                    // surrounding and() because and() evaluates its arguments from right to left.
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFromFailed()`.
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, memPointer) // Restore the memPointer.
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

import {Owned} from "@solbase/auth/Owned.sol";
import {SafeTransferLib} from "@solbase/utils/SafeTransferLib.sol";
import {ERC20} from "@solbase/tokens/ERC20/ERC20.sol";
import {WETH} from "@solbase/tokens/WETH.sol";
import {IUniswapV2Factory} from "./IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "./IUniswapV2Pair.sol";
import {IRouter} from "./IRouter.sol";

contract Diligence is Owned(tx.origin) {
    using SafeTransferLib for address;
    address payable constant public wavax = payable(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);
    
    constructor() {
    }

    fallback() external payable { }

    receive() external payable { }

    function withdraw() public onlyOwner
    {
        msg.sender.safeTransferETH(address(this).balance);
    }

    function determineRouterFromFactory(address factory) internal pure returns (address)
    {
        if (factory == 0x9Ad6C38BE94206cA50bb0d90783181662f0Cfa10)
            return 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;
        else if (factory == 0xefa94DE7a4656D787667C749f7E1223D71E9FD88)
            return 0xE54Ca86531e17Ef3616d22Ca28b0D458b6C89106;
        else if (factory == 0xc35DADB65012eC5796536bD9864eD8773aBc74C4)
            return 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
        else
            return address(0);
    }

    function determineRouterFromPair(address pair) internal view returns (address)
    {
        address factory = IUniswapV2Pair(pair).factory();
        return determineRouterFromFactory(factory);
    }

    function swap(uint256 amount, address from, address to, address router) internal returns (uint256)
    {
        uint256 before = ERC20(to).balanceOf(address(this));
        address[] memory path = new address[](2);
        path[0] = from;
        path[1] = to;
        bytes memory payload = abi.encodeCall(IRouter(router).swapExactTokensForTokensSupportingFeeOnTransferTokens, (amount, 0, path, address(this), block.timestamp));
        (bool success,) = address(router).call(payload);

        if (success)
        {
             return ERC20(to).balanceOf(address(this))-before;
        } 
        else
        {
            return type(uint256).max;
        }
    }

    function buyAndSell(address token, address with, uint256 amount, address factory) internal returns (uint256)
    {
        address router = determineRouterFromFactory(factory);
        uint256 expected; 
        uint256 actual; 
        ERC20(with).approve(router, amount);
        if (token < with)
        {
            address pair = IUniswapV2Factory(factory).getPair(token, with);
            (uint112 reserveT, uint112 reserveW,) = IUniswapV2Pair(pair).getReserves();
            expected = IRouter(router).getAmountOut(amount, reserveW, reserveT);
        }
        else
        {
            address pair = IUniswapV2Factory(factory).getPair(with, token);
            (uint112 reserveW, uint112 reserveT,) = IUniswapV2Pair(pair).getReserves();
            expected = IRouter(router).getAmountOut(amount, reserveW, reserveT);
        }
        actual = swap(amount, with, token, router);
        if (actual == 0)
            return 1;
        if (actual == type(uint256).max)
            return 2;
        if (actual < expected)
            return 3;
        ERC20(token).approve(router, actual);
        if (token < with)
        {
            address pair = IUniswapV2Factory(factory).getPair(token, with);
            (uint112 reserveT, uint112 reserveW,) = IUniswapV2Pair(pair).getReserves();
            expected = IRouter(router).getAmountOut(actual, reserveT, reserveW);
        }
        else
        {
            address pair = IUniswapV2Factory(factory).getPair(with, token);
            (uint112 reserveW, uint112 reserveT,) = IUniswapV2Pair(pair).getReserves();
            expected = IRouter(router).getAmountOut(actual, reserveT, reserveW);
        }
        actual = swap(actual, token, with, router);
        if (actual == 0)
            return 1;
        if (actual == type(uint256).max)
            return 4;
        if (actual < expected)
            return 5;
        return 0;
    }

    function checkToken(address token, address factory) public onlyOwner returns (uint256)
    {
        WETH(wavax).deposit{value: address(this).balance}();
        uint256 balance = WETH(wavax).balanceOf(address(this));
        uint256 ret = buyAndSell(token, wavax, balance, factory);
        balance = WETH(wavax).balanceOf(address(this));
        WETH(wavax).withdraw(balance);
        return ret;
    }

    function getPair(address factory, address tokenA, address tokenB) internal view returns (address)
    {
        if (tokenA < tokenB)
            return IUniswapV2Factory(factory).getPair(tokenA, tokenB);
        else 
            return IUniswapV2Factory(factory).getPair(tokenB, tokenA);

    }

    function checkMarket(address market) public onlyOwner returns (uint256)
    {
        address factory = IUniswapV2Pair(market).factory();
        address router = determineRouterFromFactory(factory);
        address token0 = IUniswapV2Pair(market).token0();
        address token1 = IUniswapV2Pair(market).token1();
        if ( token0 == wavax)
        {
            return checkToken(token1, factory);
        }
        else if (token1 == wavax)
        {
            return checkToken(token0, factory);
        }
        else 
        {
            address pair = getPair(factory, token0, wavax);
            if (pair == address(0))
            {
                uint256 ret = checkToken(token1, factory);
                if (ret > 0)
                    return ret;
                WETH(wavax).deposit{value: address(this).balance}();
                ERC20(wavax).approve(router, ERC20(wavax).balanceOf(address(this)));
                ret = swap(ERC20(wavax).balanceOf(address(this)), wavax, token1, router);
                if (ret == type(uint256).max)
                    return 1;
                ret = buyAndSell(token0, token1, ret, factory);
                WETH(wavax).withdraw(ERC20(wavax).balanceOf(address(this)));
                return ret;
            }
            else
            {
                uint256 ret = checkToken(token1, factory);
                if (ret > 0)
                    return ret;
                WETH(wavax).deposit{value: address(this).balance}();
                ERC20(wavax).approve(router, ERC20(wavax).balanceOf(address(this)));
                ret = swap(ERC20(wavax).balanceOf(address(this)), wavax, token0, router);
                if (ret == type(uint256).max)
                    return 1;
                ret = buyAndSell(token1, token0, ret, factory);
                WETH(wavax).withdraw(ERC20(wavax).balanceOf(address(this)));
                return ret;
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;
interface IRouter {

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external returns (uint256 amountOut);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: AGPL-3.0-only
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

// SPDX-License-Identifier: AGPL-3.0-only
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
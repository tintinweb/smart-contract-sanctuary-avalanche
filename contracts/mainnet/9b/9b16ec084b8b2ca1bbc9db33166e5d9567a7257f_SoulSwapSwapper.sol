/**
 *Submitted for verification at snowtrace.io on 2022-07-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
// Author: @0xBuns
// Version: 05-Feb-2022

/// @notice A library for performing overflow-/underflow-safe math,
/// updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math).
library BoringMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b == 0 || (c = a * b) / b == a, "BoringMath: Mul Overflow");
    }
}

interface ISoulSwapFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface ISoulSwapPair {
    function token0() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

interface ICoffinBox {
    function deposit(
        IERC20 token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external payable returns (uint256 amountOut, uint256 shareOut);

    function toAmount(
        IERC20 token,
        uint256 share,
        bool roundUp
    ) external view returns (uint256 amount);

    function toShare(
        IERC20 token,
        uint256 amount,
        bool roundUp
    ) external view returns (uint256 share);

    function transfer(
        IERC20 token,
        address from,
        address to,
        uint256 share
    ) external;

    function withdraw(
        IERC20 token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);
}

// File contracts/swappers/SoulSwapSwapper.sol
contract SoulSwapSwapper {
    using BoringMath for uint256;

    // Local variables
    ICoffinBox public immutable coffinBox;
    ISoulSwapFactory public immutable factory;
    bytes32 public pairCodeHash;

    constructor(
        ICoffinBox coffinBox_,
        ISoulSwapFactory factory_,
        bytes32 pairCodeHash_
    ) public {
        coffinBox = coffinBox_;
        factory = factory_;
        pairCodeHash = pairCodeHash_;
    }

    // Given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // Given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // Swaps to a flexible amount, from an exact input amount
    /// @notice Withdraws 'amountFrom' of token 'from' from the CoffinBox account for this swapper.
    /// Swaps it for at least 'amountToMin' of token 'to'.
    /// Transfers the swapped tokens of 'to' into the CoffinBox using a plain ERC20 transfer.
    /// Returns the amount of tokens 'to' transferred to CoffinBox.
    /// (The CoffinBox skim function will be used by the caller to get the swapped funds).
    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        address recipient,
        uint256 shareToMin,
        uint256 shareFrom
    ) public returns (uint256 extraShare, uint256 shareReturned) {
        (IERC20 token0, IERC20 token1) = fromToken < toToken ? (fromToken, toToken) : (toToken, fromToken);
        ISoulSwapPair pair =
            ISoulSwapPair(
                uint256(
                    keccak256(abi.encodePacked(hex"ff", factory, keccak256(abi.encodePacked(address(token0), address(token1))), pairCodeHash))
                )
            );

        (uint256 amountFrom, ) = coffinBox.withdraw(fromToken, address(this), address(pair), 0, shareFrom);

        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        uint256 amountTo;
        if (toToken > fromToken) {
            amountTo = getAmountOut(amountFrom, reserve0, reserve1);
            pair.swap(0, amountTo, address(coffinBox), new bytes(0));
        } else {
            amountTo = getAmountOut(amountFrom, reserve1, reserve0);
            pair.swap(amountTo, 0, address(coffinBox), new bytes(0));
        }
        (, shareReturned) = coffinBox.deposit(toToken, address(coffinBox), recipient, amountTo, 0);
        extraShare = shareReturned.sub(shareToMin);
    }

    // Swaps to an exact amount, from a flexible input amount
    /// @notice Calculates the amount of token 'from' needed to complete the swap (amountFrom),
    /// this should be less than or equal to amountFromMax.
    /// Withdraws 'amountFrom' of token 'from' from the CoffinBox account for this swapper.
    /// Swaps it for exactly 'exactAmountTo' of token 'to'.
    /// Transfers the swapped tokens of 'to' into the CoffinBox using a plain ERC20 transfer.
    /// Transfers allocated, but unused 'from' tokens within the CoffinBox to 'refundTo' (amountFromMax - amountFrom).
    /// Returns the amount of 'from' tokens withdrawn from CoffinBox (amountFrom).
    /// (The CoffinBox skim function will be used by the caller to get the swapped funds).
    function swapExact(
        IERC20 fromToken,
        IERC20 toToken,
        address recipient,
        address refundTo,
        uint256 shareFromSupplied,
        uint256 shareToExact
    ) public returns (uint256 shareUsed, uint256 shareReturned) {
        ISoulSwapPair pair;
        {
            (IERC20 token0, IERC20 token1) = fromToken < toToken ? (fromToken, toToken) : (toToken, fromToken);
            pair = ISoulSwapPair(
                uint256(
                    keccak256(abi.encodePacked(hex"ff", factory, keccak256(abi.encodePacked(address(token0), address(token1))), pairCodeHash))
                )
            );
        }
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();

        uint256 amountToExact = coffinBox.toAmount(toToken, shareToExact, true);

        uint256 amountFrom;
        if (toToken > fromToken) {
            amountFrom = getAmountIn(amountToExact, reserve0, reserve1);
            (, shareUsed) = coffinBox.withdraw(fromToken, address(this), address(pair), amountFrom, 0);
            pair.swap(0, amountToExact, address(coffinBox), "");
        } else {
            amountFrom = getAmountIn(amountToExact, reserve1, reserve0);
            (, shareUsed) = coffinBox.withdraw(fromToken, address(this), address(pair), amountFrom, 0);
            pair.swap(amountToExact, 0, address(coffinBox), "");
        }
        coffinBox.deposit(toToken, address(coffinBox), recipient, 0, shareToExact);
        shareReturned = shareFromSupplied.sub(shareUsed);
        if (shareReturned > 0) {
            coffinBox.transfer(fromToken, address(this), refundTo, shareReturned);
        }
    }
}
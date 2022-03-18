/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-17
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

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

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
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

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            keccak256(
                                "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                            ),
                            owner,
                            spender,
                            value,
                            nonces[owner]++,
                            deadline
                        )
                    )
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

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

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Gnosis (https://github.com/gnosis/gp-v2-contracts/blob/main/src/contracts/libraries/GPv2SafeERC20.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool callStatus;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(callStatus, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 100 because the calldata length is 4 + 32 * 3.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "APPROVE_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function didLastOptionalReturnCallSucceed(bool callStatus) private pure returns (bool success) {
        assembly {
            // Get how many bytes the call returned.
            let returnDataSize := returndatasize()

            // If the call reverted:
            if iszero(callStatus) {
                // Copy the revert message into memory.
                returndatacopy(0, 0, returnDataSize)

                // Revert with the same message.
                revert(0, returnDataSize)
            }

            switch returnDataSize
            case 32 {
                // Copy the return data into memory.
                returndatacopy(0, 0, returnDataSize)

                // Set success to whether it returned true.
                success := iszero(iszero(mload(0)))
            }
            case 0 {
                // There was no return data.
                success := 1
            }
            default {
                // It returned some malformed output.
                success := 0
            }
        }
    }
}
/**
 * Based on the OpenZeppelin IER20 interface:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
 *
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
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

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

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    
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
interface IAAVE {
    function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);
}
interface ICOMP {
    function redeem(uint redeemTokens) external returns (uint);
    function mint(uint mintAmount) external returns (uint);
    function underlying() external view returns (address);
}
interface IJoePair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function swap(
        uint256 _amount0In,
        uint256 _amount1Out,
        address _to,
        bytes memory _data
    ) external;
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}
interface IMeta {
    function exchange(
        int128 i,
        int128 j,
        uint256 _dx,
        uint256 _min_dy
    ) external returns (uint256);
    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 _dx,
        uint256 _min_dy
    ) external returns (uint256);
    
}
interface IJoeRouter {
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
interface IPlainPool {
    function coins(uint256 i) external view returns (address);
    function lp_token() external view returns (address);
    function exchange(int128 i, int128 j, uint256 _dx, uint256 _min_dy) external returns (uint256 actual_dy);
    
    function add_liquidity(uint256[2] calldata _amounts, uint256 _min_mint_amount) external returns (uint256 actualMinted);
    function add_liquidity(uint256[3] calldata _amounts, uint256 _min_mint_amount) external returns (uint256 actualMinted);
    function add_liquidity(uint256[4] calldata _amounts, uint256 _min_mint_amount) external returns (uint256 actualMinted);
    function add_liquidity(uint256[5] calldata _amounts, uint256 _min_mint_amount) external returns (uint256 actualMinted);

    function remove_liquidity(uint256 _amount, uint256[2] calldata _min_amounts) external returns (uint256[2] calldata actualWithdrawn);
    function remove_liquidity(uint256 _amount, uint256[3] calldata _min_amounts) external returns (uint256[3] calldata actualWithdrawn);
    function remove_liquidity(uint256 _amount, uint256[4] calldata _min_amounts) external returns (uint256[4] calldata actualWithdrawn);
    function remove_liquidity(uint256 _amount, uint256[5] calldata _min_amounts) external returns (uint256[5] calldata actualWithdrawn);

    function remove_liquidity_imbalance(uint256[2] calldata _amounts, uint256 _max_burn_amount) external returns (uint256 actualBurned);
    function remove_liquidity_imbalance(uint256[3] calldata _amounts, uint256 _max_burn_amount) external returns (uint256 actualBurned);
    function remove_liquidity_imbalance(uint256[4] calldata _amounts, uint256 _max_burn_amount) external returns (uint256 actualBurned);
    function remove_liquidity_imbalance(uint256[5] calldata _amounts, uint256 _max_burn_amount) external returns (uint256 actualBurned);

    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 _min_amount) external returns (uint256 actualWithdrawn);
}

interface ILendingPool {
    function coins(uint256 i) external view returns (address);
    function underlying_coins(uint256 i) external view returns (address);
    function lp_token() external view returns (address);
    function exchange(int128 i, int128 j, uint256 _dx, uint256 _min_dy) external returns (uint256 actual_dy);
    function exchange_underlying(int128 i, int128 j, uint256 _dx, uint256 _min_dy) external returns (uint256 actual_dy);


    function add_liquidity(uint256[2] calldata _amounts, uint256 _min_mint_amount) external returns (uint256 actualMinted);
    function add_liquidity(uint256[3] calldata _amounts, uint256 _min_mint_amount) external returns (uint256 actualMinted);
    function add_liquidity(uint256[4] calldata _amounts, uint256 _min_mint_amount) external returns (uint256 actualMinted);
    function add_liquidity(uint256[5] calldata _amounts, uint256 _min_mint_amount) external returns (uint256 actualMinted);

    function add_liquidity(uint256[2] calldata _amounts, uint256 _min_mint_amount, bool _use_underlying) external returns (uint256 actualMinted);
    function add_liquidity(uint256[3] calldata _amounts, uint256 _min_mint_amount, bool _use_underlying) external returns (uint256 actualMinted);
    function add_liquidity(uint256[4] calldata _amounts, uint256 _min_mint_amount, bool _use_underlying) external returns (uint256 actualMinted);
    function add_liquidity(uint256[5] calldata _amounts, uint256 _min_mint_amount, bool _use_underlying) external returns (uint256 actualMinted);

    function remove_liquidity(uint256 _amount, uint256[2] calldata _min_amounts) external returns (uint256[2] calldata actualWithdrawn);
    function remove_liquidity(uint256 _amount, uint256[3] calldata _min_amounts) external returns (uint256[3] calldata actualWithdrawn);
    function remove_liquidity(uint256 _amount, uint256[4] calldata _min_amounts) external returns (uint256[4] calldata actualWithdrawn);
    function remove_liquidity(uint256 _amount, uint256[5] calldata _min_amounts) external returns (uint256[5] calldata actualWithdrawn);

    function remove_liquidity_imbalance(uint256[2] calldata _amounts, uint256 _max_burn_amount) external returns (uint256 actualBurned);
    function remove_liquidity_imbalance(uint256[3] calldata _amounts, uint256 _max_burn_amount) external returns (uint256 actualBurned);
    function remove_liquidity_imbalance(uint256[4] calldata _amounts, uint256 _max_burn_amount) external returns (uint256 actualBurned);
    function remove_liquidity_imbalance(uint256[5] calldata _amounts, uint256 _max_burn_amount) external returns (uint256 actualBurned);

    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 _min_amount) external returns (uint256 actualWithdrawn);
}

interface IMetaPool {
    function coins(uint256 i) external view returns (address);
    function base_coins(uint256 i) external view returns (address);
    function base_pool() external view returns (address);
    function exchange(int128 i, int128 j, uint256 _dx, uint256 _min_dy) external returns (uint256 actual_dy);
    function exchange_underlying(int128 i, int128 j, uint256 _dx, uint256 _min_dy) external returns (uint256 actual_dy);


    function add_liquidity(uint256[2] calldata _amounts, uint256 _min_mint_amount) external returns (uint256 actualMinted);
    function add_liquidity(uint256[3] calldata _amounts, uint256 _min_mint_amount) external returns (uint256 actualMinted);
    function add_liquidity(uint256[4] calldata _amounts, uint256 _min_mint_amount) external returns (uint256 actualMinted);
    function add_liquidity(uint256[5] calldata _amounts, uint256 _min_mint_amount) external returns (uint256 actualMinted);

    function remove_liquidity(uint256 _amount, uint256[2] calldata _min_amounts) external returns (uint256[2] calldata actualWithdrawn);
    function remove_liquidity(uint256 _amount, uint256[3] calldata _min_amounts) external returns (uint256[3] calldata actualWithdrawn);
    function remove_liquidity(uint256 _amount, uint256[4] calldata _min_amounts) external returns (uint256[4] calldata actualWithdrawn);
    function remove_liquidity(uint256 _amount, uint256[5] calldata _min_amounts) external returns (uint256[5] calldata actualWithdrawn);

    function remove_liquidity_imbalance(uint256[2] calldata _amounts, uint256 _max_burn_amount) external returns (uint256 actualBurned);
    function remove_liquidity_imbalance(uint256[3] calldata _amounts, uint256 _max_burn_amount) external returns (uint256 actualBurned);
    function remove_liquidity_imbalance(uint256[4] calldata _amounts, uint256 _max_burn_amount) external returns (uint256 actualBurned);
    function remove_liquidity_imbalance(uint256[5] calldata _amounts, uint256 _max_burn_amount) external returns (uint256 actualBurned);

    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 _min_amount) external returns (uint256 actualWithdrawn);
}

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)



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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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
/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*///////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*///////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z) // Like multiplying by 2 ** 64.
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z) // Like multiplying by 2 ** 32.
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z) // Like multiplying by 2 ** 16.
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z) // Like multiplying by 2 ** 8.
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z) // Like multiplying by 2 ** 4.
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z) // Like multiplying by 2 ** 2.
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }
}

/** 
 * @notice Router is a contract for routing token swaps through various defined routes. 
 * It takes a modular approach to swapping and can go through multiple routes, as encoded in the 
 * Node array which corresponds to a route. A path is defined as routes[fromToken][toToken]. 
 */

contract Router is Ownable {
    using SafeTransferLib for IERC20;

    address public traderJoeRouter;
    address public aaveLendingPool;
    event RouteSet(address fromToken, address toToken, Node[] path);
    event Swap(
        address caller,
        address startingTokenAddress,
        address endingTokenAddress,
        uint256 amount,
        uint256 minSwapAmount,
        uint256 actualOut
    );
    uint256 internal constant MAX_INT =
        115792089237316195423570985008687907853269984665640564039457584007913129639935;
    uint256 internal constant FEE_DENOMINATOR = 1e3;
    uint256 internal constant FEE_COMPLIMENT = 997;

    // nodeType
    // 1 = traderJoe
    // 2 = JLP
    // 3 = curve2 pool
    // 4 = curve3 pool
    // 5 = curve4 pool
    // 6 = aToken
    // 7 = qToken
    struct Node {
        // Is Joe pair or cToken etc. 
        address protocolSwapAddress;
        uint256 nodeType;
        address tokenIn;
        address tokenOut;
        uint256 misc; //Extra info for curve pools
        int128 _in;
        int128 out;
    }

    // Usage: path = routes[fromToken][toToken]
    mapping(address => mapping(address => Node[])) public routes;

    function setJoeRouter(address _traderJoeRouter) public onlyOwner {
        traderJoeRouter = _traderJoeRouter;
    }

    function setAAVE(address _aaveLendingPool) public onlyOwner {
        aaveLendingPool = _aaveLendingPool;
    }

    function setApprovals(
        address _token,
        address _who,
        uint256 _amount
    ) external onlyOwner {
        IERC20(_token).approve(_who, _amount);
    }

    function setRoute(
        address _fromToken,
        address _toToken,
        Node[] calldata _path
    ) external onlyOwner {
        delete routes[_fromToken][_toToken];
        for (uint256 i = 0; i < _path.length; i++) {
            routes[_fromToken][_toToken].push(_path[i]);
        }
        // routes[_fromToken][_toToken] = _path;
        emit RouteSet(_fromToken, _toToken, _path);
    }

    //////////////////////////////////////////////////////////////////////////////////
    // #1 Swap through Trader Joe
    //////////////////////////////////////////////////////////////////////////////////
    function swapJoePair(
        address _pair,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) internal returns (uint256) {
        IERC20(_tokenIn).transfer(_pair, _amountIn);
        uint256 amount0Out;
        uint256 amount1Out;
        (uint256 reserve0, uint256 reserve1, ) = IJoePair(_pair).getReserves();
        if (_tokenIn < _tokenOut) {
            // TokenIn=token0
            amount1Out = _getAmountOut(_amountIn, reserve0, reserve1);
        } else {
            // TokenIn=token1
            amount0Out = _getAmountOut(_amountIn, reserve1, reserve0);
        }
        IJoePair(_pair).swap(
            amount0Out,
            amount1Out,
            address(this),
            new bytes(0)
        );
        return amount0Out != 0 ? amount0Out : amount1Out;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function _getAmountOut(
        uint256 _amountIn,
        uint256 _reserveIn,
        uint256 _reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(_amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(
            _reserveIn > 0 && _reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 amountInWithFee = _amountIn * FEE_COMPLIMENT;
        uint256 numerator = amountInWithFee * _reserveOut;
        uint256 denominator = (_reserveIn * FEE_DENOMINATOR) + amountInWithFee;
        amountOut = numerator / denominator;
    }

    //////////////////////////////////////////////////////////////////////////////////
    // #2 Swap into and out of Trader Joe LP Token
    //////////////////////////////////////////////////////////////////////////////////

    function _min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    function _getAmtToSwap(uint256 r0, uint256 totalX)
        internal
        pure
        returns (uint256)
    {
        // For optimal amounts, this quickly becomes an algebraic optimization problem
        // You must account for price impact of the swap to the corresponding token
        // Optimally, you swap enough of tokenIn such that the ratio of tokenIn_1/tokenIn_2 is the same as reserve1/reserve2 after the swap
        // Plug _in the uniswap k=xy equation _in the above equality and you will get the following:
        uint256 sub = (r0 * 998500) / 994009;
        uint256 toSqrt = totalX * 3976036 * r0 + r0 * r0 * 3988009;
        return (FixedPointMathLib.sqrt(toSqrt) * 500) / 994009 - sub;
    }

    function _getAmountPairOut(
        uint256 _amountIn,
        uint256 _reserveIn,
        uint256 _reserveOut,
        uint256 _totalSupply
    ) internal view returns (uint256 amountOut) {
        // Given token, how much lp token will I get?

        _amountIn = _getAmtToSwap(_reserveIn, _amountIn);
        uint256 amountInWithFee = _amountIn * FEE_COMPLIMENT;
        uint256 numerator = amountInWithFee * _reserveOut;
        uint256 denominator = _reserveIn * FEE_DENOMINATOR + amountInWithFee;
        uint256 _amountIn2 = numerator / denominator;
        // https://github.com/traderjoe-xyz/joe-core/blob/11d6c6a57017b5f890eb7ea3e3a61de245a41ef2/contracts/traderjoe/JoePair.sol#L153
        amountOut = _min(
            (_amountIn * _totalSupply) / (_reserveIn + _amountIn),
            (_amountIn2 * _totalSupply) / (_reserveOut - _amountIn2)
        );
    }

    function _getAmountPairIn(
        uint256 _amountIn,
        uint256 _reserveIn,
        uint256 _reserveOut,
        uint256 _totalSupply
    ) internal view returns (uint256 amountOut) {
        // Given lp token, how much token will I get?
        uint256 amt0 = (_amountIn * _reserveIn) / _totalSupply;
        uint256 amt1 = (_amountIn * _reserveOut) / _totalSupply;

        _reserveIn = _reserveIn - amt0;
        _reserveOut = _reserveOut - amt1;

        uint256 amountInWithFee = amt0 * FEE_COMPLIMENT;
        uint256 numerator = amountInWithFee * _reserveOut;
        uint256 denominator = (_reserveIn * FEE_DENOMINATOR) + amountInWithFee;
        amountOut = numerator / denominator;
        amountOut = amountOut + amt1;
    }

    function swapLPToken(
        address _token,
        address _pair,
        uint256 _amountIn,
        bool _LPIn
    ) internal returns (uint256) {
        address token0 = IJoePair(_pair).token0();
        address token1 = IJoePair(_pair).token1();
        if (_LPIn) {
            IJoeRouter(traderJoeRouter).removeLiquidity(
                token0,
                token1,
                _amountIn,
                0,
                0,
                address(this),
                block.timestamp
            );
            if (token0 == _token) {
                swapJoePair(
                    _pair,
                    token1,
                    token0,
                    IERC20(token1).balanceOf(address(this))
                );
            } else if (token1 == _token) {
                swapJoePair(
                    _pair,
                    token0,
                    token1,
                    IERC20(token0).balanceOf(address(this))
                );
            } else {
                revert("tokenOut is not a token _in the pair");
            }
            return IERC20(_token).balanceOf(address(this));
        } else {
            (uint112 r0, uint112 r1, uint32 _last) = IJoePair(_pair)
                .getReserves();
            if (token0 == _token) {
                swapJoePair(_pair, _token, token1, _getAmtToSwap(r0, _amountIn));
                IJoeRouter(traderJoeRouter).addLiquidity(
                    token0,
                    token1,
                    IERC20(token0).balanceOf(address(this)),
                    IERC20(token1).balanceOf(address(this)),
                    0,
                    0,
                    address(this),
                    block.timestamp
                );
            } else if (token1 == _token) {
                swapJoePair(_pair, _token, token0, _getAmtToSwap(r1, _amountIn));
                IJoeRouter(traderJoeRouter).addLiquidity(
                    token0,
                    token1,
                    IERC20(token0).balanceOf(address(this)),
                    IERC20(token1).balanceOf(address(this)),
                    0,
                    0,
                    address(this),
                    block.timestamp
                );
            } else {
                revert("tokenOut is not a token _in the pair");
            }
            return IERC20(_pair).balanceOf(address(this));
        }
    }


    //////////////////////////////////////////////////////////////////////////////////
    // #3 Swap through Curve 2Pool
    //////////////////////////////////////////////////////////////////////////////////

    // A note on curve swapping. There are 3 curve swapping functions for
    // curve pools with 2,3, and 4 tokens (swapCurve2, swapCurve3, swapCurve4) respectively.
    // These functions are otherwise identical except for the intialization of size 2,3,4 static arrays
    // Curve requires you to pass static arrays and because we cannot initialize static arrays
    // with size unknown at compile time, we had to hardcode this (any help in fixing this would be appreciated)
    // Furthermore, the curve swaps make use of 3 additional helper variables:
    // _misc describes the type of pool interaction which is currently only used to differentiate
    // interactions between plain pools and lending/meta pools which require _underlying
    // _in describes the index of the token being swapped in (if it's -1 it means we're splitting a crvLP token)
    // _out describes the index of the token being swapped out (if it's -1 it means we're trying to mint a crvLP token)
    
    function swapCurve2(
        address _tokenIn,
        address _tokenOut,
        address _curvePool,
        uint256 _amount,
        uint256 _misc,
        int128 _in,
        int128 _out
    ) internal returns (uint256 amountOut) {
        if (_misc == 1) {
            // Plain pool
            if (_out == -1) {
                uint256[2] memory _amounts;
                _amounts[uint256(int256(_in))] = _amount;
                amountOut = IPlainPool(_curvePool).add_liquidity(_amounts, 0);
            } else if (_in == -1) {
                amountOut = IPlainPool(_curvePool).remove_liquidity_one_coin(
                    _amount,
                    _out,
                    0
                );
            } else {
                amountOut = IPlainPool(_curvePool).exchange(
                    _in,
                    _out,
                    _amount,
                    0
                );
            }
        } else if (_misc == 2) {
            // Use underlying. Works for both lending and metapool
            if (_out == -1) {
                uint256[2] memory _amounts;
                _amounts[uint256(int256(_in))] = _amount;
                amountOut = ILendingPool(_curvePool).add_liquidity(
                    _amounts,
                    0,
                    true
                );
            } else {
                amountOut = ILendingPool(_curvePool).exchange_underlying(
                    _in,
                    _out,
                    _amount,
                    0
                );
            }
        }
    }

    //////////////////////////////////////////////////////////////////////////////////
    // #4 Swap through Curve 3Pool
    //////////////////////////////////////////////////////////////////////////////////

    function swapCurve3(
        address _tokenIn,
        address _tokenOut,
        address _curvePool,
        uint256 _amount,
        uint256 _misc,
        int128 _in,
        int128 _out
    ) internal returns (uint256 amountOut) {
        if (_misc == 1) {
            // Plain pool
            if (_out == -1) {
                uint256[3] memory _amounts;
                _amounts[uint256(int256(_in))] = _amount;
                amountOut = IPlainPool(_curvePool).add_liquidity(_amounts, 0);
            } else if (_in == -1) {
                amountOut = IPlainPool(_curvePool).remove_liquidity_one_coin(
                    _amount,
                    _out,
                    0
                );
            } else {
                amountOut = IPlainPool(_curvePool).exchange(
                    _in,
                    _out,
                    _amount,
                    0
                );
            }
        } else if (_misc == 2) {
            // Use underlying. Works for both lending and metapool
            if (_out == -1) {
                uint256[3] memory _amounts;
                _amounts[uint256(int256(_in))] = _amount;
                amountOut = ILendingPool(_curvePool).add_liquidity(
                    _amounts,
                    0,
                    true
                );
            } else {
                amountOut = ILendingPool(_curvePool).exchange_underlying(
                    _in,
                    _out,
                    _amount,
                    0
                );
            }
        }
    }

    //////////////////////////////////////////////////////////////////////////////////
    // #5 Swap through Curve 4Pool
    //////////////////////////////////////////////////////////////////////////////////

    function swapCurve4(
        address _tokenIn,
        address _tokenOut,
        address _curvePool,
        uint256 _amount,
        uint256 _misc,
        int128 _in,
        int128 _out
    ) internal returns (uint256 amountOut) {
        if (_misc == 1) {
            // Plain pool
            if (_out == -1) {
                uint256[4] memory _amounts;
                _amounts[uint256(int256(_in))] = _amount;
                amountOut = IPlainPool(_curvePool).add_liquidity(_amounts, 0);
            } else if (_in == -1) {
                amountOut = IPlainPool(_curvePool).remove_liquidity_one_coin(
                    _amount,
                    _out,
                    0
                );
            } else {
                amountOut = IPlainPool(_curvePool).exchange(
                    _in,
                    _out,
                    _amount,
                    0
                );
            }
        } else if (_misc == 2) {
            // Use underlying. Works for both lending and metapool
            if (_out == -1) {
                uint256[4] memory _amounts;
                _amounts[uint256(int256(_in))] = _amount;
                amountOut = ILendingPool(_curvePool).add_liquidity(
                    _amounts,
                    0,
                    true
                );
            } else {
                amountOut = ILendingPool(_curvePool).exchange_underlying(
                    _in,
                    _out,
                    _amount,
                    0
                );
            }
        }
    }

    //////////////////////////////////////////////////////////////////////////////////
    // #6 AAVE Token
    //////////////////////////////////////////////////////////////////////////////////

    function swapAAVEToken(
        address _token,
        uint256 _amount,
        bool _AaveIn
    ) internal returns (uint256) {
        if (_AaveIn) {
            // Swap Aave for _token
            _amount = IAAVE(aaveLendingPool).withdraw(
                _token,
                _amount,
                address(this)
            );
            return _amount;
        } else {
            // Swap _token for Aave
            IAAVE(aaveLendingPool).deposit(_token, _amount, address(this), 0);
            return _amount;
        }
    }

    //////////////////////////////////////////////////////////////////////////////////
    // #7 Compound-like Token
    //////////////////////////////////////////////////////////////////////////////////

    function swapCOMPToken(
        address _tokenIn,
        address _cToken,
        uint256 _amount
    ) internal returns (uint256) {
        if (_tokenIn == _cToken) {
            // Swap ctoken for _token
            ICOMP(_cToken).redeem(_amount);
            address underlying = ICOMP(_cToken).underlying();
            return IERC20(underlying).balanceOf(address(this));
        } else {
            // Swap _token for ctoken
            ICOMP(_cToken).mint(_amount);
            return IERC20(_cToken).balanceOf(address(this));
        }
    }

    // Takes the address of the token _in, and gives a certain amount of token out. 
    // Calls correct swap functions sequentially based on the route which is defined by the 
    // routes array. 
    function swap(
        address _startingTokenAddress,
        address _endingTokenAddress,
        uint256 _amount,
        uint256 _minSwapAmount
    ) internal returns (uint256) {
        uint256 initialOutAmount = IERC20(_endingTokenAddress).balanceOf(
            address(this)
        );
        Node[] memory path = routes[_startingTokenAddress][_endingTokenAddress];
        uint256 amtIn = _amount;
        require(path.length > 0, "No route found");
        for (uint256 i; i < path.length; i++) {
            if (path[i].nodeType == 1) {
                // Is traderjoe
                _amount = swapJoePair(
                    path[i].protocolSwapAddress,
                    path[i].tokenIn,
                    path[i].tokenOut,
                    _amount
                );
            } else if (path[i].nodeType == 2) {
                // Is jlp
                if (path[i].tokenIn == path[i].protocolSwapAddress) {
                    _amount = swapLPToken(
                        path[i].tokenOut,
                        path[i].protocolSwapAddress,
                        _amount,
                        true
                    );
                } else {
                    _amount = swapLPToken(
                        path[i].tokenIn,
                        path[i].protocolSwapAddress,
                        _amount,
                        false
                    );
                }
            } else if (path[i].nodeType == 3) {
                // Is curve pool
                _amount = swapCurve2(
                    path[i].tokenIn,
                    path[i].tokenOut,
                    path[i].protocolSwapAddress,
                    _amount,
                    path[i].misc,
                    path[i]._in,
                    path[i].out
                );
            } else if (path[i].nodeType == 4) {
                // Is curve pool
                _amount = swapCurve3(
                    path[i].tokenIn,
                    path[i].tokenOut,
                    path[i].protocolSwapAddress,
                    _amount,
                    path[i].misc,
                    path[i]._in,
                    path[i].out
                );
            } else if (path[i].nodeType == 5) {
                // Is curve pool
                _amount = swapCurve4(
                    path[i].tokenIn,
                    path[i].tokenOut,
                    path[i].protocolSwapAddress,
                    _amount,
                    path[i].misc,
                    path[i]._in,
                    path[i].out
                );
            } else if (path[i].nodeType == 6) {
                // Is aToken
                _amount = swapAAVEToken(
                    path[i].tokenIn == path[i].protocolSwapAddress
                        ? path[i].tokenOut
                        : path[i].tokenIn,
                    _amount,
                    path[i].tokenIn == path[i].protocolSwapAddress
                );
            } else if (path[i].nodeType == 7) {
                // Is cToken
                _amount = swapCOMPToken(
                    path[i].tokenIn,
                    path[i].protocolSwapAddress,
                    _amount
                );
            } else {
                revert("Unknown node type");
            }
        }
        uint256 outAmount = IERC20(_endingTokenAddress).balanceOf(
            address(this)
        ) - initialOutAmount;
        require(
            outAmount >= _minSwapAmount,
            "Did not receive enough tokens to account for slippage"
        );
        emit Swap(
            msg.sender,
            _startingTokenAddress,
            _endingTokenAddress,
            amtIn,
            _minSwapAmount,
            outAmount
        );
        return outAmount;
    }
}
/** 
 * @notice IYetiLever is an interface intended for use in the Yeti Finance Lever Up feature. It routes from 
 * YUSD to some various token out which has to be compatible with the underlying router in the route 
 * function, and unRoutes backwards to get YUSD out. Sends to the active pool address by intention and 
 * route is called in functions openTroveLeverUp and addCollLeverUp in BorrowerOperations.sol. unRoute
 * is called in functions closeTroveUnleverUp and withdrawCollUnleverUp in BorrowerOperations.sol.
 */

interface IYetiLever {

    // Goes from some token (YUSD likely) and gives a certain amount of token out.
    // Auto transfers to active pool from call in BorrowerOperations.sol, aka _toUser is always activePool
    // Goes from _startingTokenAddress to _endingTokenAddress, given it has tokens of _amount, and gets _minSwapAmount out _endingTokenAddress
    // Sends it to _toUser
    function route(
        address _toUser,
        address _startingTokenAddress,
        address _endingTokenAddress,
        uint256 _amount,
        uint256 _minSwapAmount
    ) external returns (uint256 amountOut);

    // Takes the address of the token required in, and gives a certain amount of any token (YUSD likely) out
    // User first withdraws that collateral from the active pool, then performs this swap. Unwraps tokens
    // for the user in that case.
    // Goes from _startingTokenAddress to _endingTokenAddress, given it has tokens of _amount, of _amount, and gets _minSwapAmount out _endingTokenAddress.
    // Sends it to _toUser
    // Use case: Takes token from trove debt which has been transfered to the owner and then swaps it for YUSD, intended to repay debt.
    function unRoute(
        address _toUser,
        address _startingTokenAddress,
        address _endingTokenAddress,
        uint256 _amount,
        uint256 _minSwapAmount
    ) external returns (uint256 amountOut);
}
/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}


/** 
 * @notice Lever is a contract intended for use in the Yeti Finance Lever Up feature. It routes from 
 * YUSD to some various token out which has to be compatible with the underlying router in the route 
 * function, and unRoutes backwards to get YUSD out. Sends to the active pool address by intention and 
 * route is called in functions openTroveLeverUp and addCollLeverUp in BorrowerOperations.sol. unRoute
 * is called in functions closeTroveUnleverUp and withdrawCollUnleverUp in BorrowerOperations.sol.
 */

contract Lever is Router, IYetiLever, ReentrancyGuard {

    // Goes from some token (YUSD likely) and gives a certain amount of token out.
    // Auto transfers to active pool from call in BorrowerOperations.sol, aka _toUser is always activePool
    // Goes from _startingTokenAddress to _endingTokenAddress, pulling tokens from _fromUser, of _amount, and gets _minSwapAmount out _endingTokenAddress
    function route(
        address _toUser,
        address _startingTokenAddress,
        address _endingTokenAddress,
        uint256 _amount,
        uint256 _minSwapAmount
    ) external nonReentrant override returns (uint256 amountOut) {
        amountOut = swap(
            _startingTokenAddress,
            _endingTokenAddress,
            _amount,
            _minSwapAmount
        );
        IERC20(_endingTokenAddress).transfer(_toUser, amountOut);
    }

    // Takes the address of the token required in, and gives a certain amount of any token (YUSD likely) out
    // User first withdraws that collateral from the active pool, then performs this swap. Unwraps tokens
    // for the user in that case.
    // Goes from _startingTokenAddress to _endingTokenAddress, pulling tokens from _fromUser, of _amount, and gets _minSwapAmount out _endingTokenAddress.
    // Use case: Takes token from trove debt which has been transfered to the owner and then swaps it for YUSD, intended to repay debt.
    function unRoute(
        address _toUser,
        address _startingTokenAddress,
        address _endingTokenAddress,
        uint256 _amount,
        uint256 _minSwapAmount
    ) external nonReentrant override returns (uint256 amountOut) {
        amountOut = swap(
            _startingTokenAddress,
            _endingTokenAddress,
            _amount,
            _minSwapAmount
        );
        IERC20(_endingTokenAddress).transfer(_toUser, amountOut);
    }
}
/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-22
*/

// Sources flattened with hardhat v2.9.7 https://hardhat.org

// File contracts/cygnus-periphery/interfaces/ICygnusAltairCall.sol

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.4;

interface ICygnusAltairCall {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice Function that is called by the CygnusBorrow contract and decodes data to carry out the leverage
     *  @notice Will only succeed if: Caller is borrow contract & Borrow contract was called by router
     *  @param sender Address of the contract that initialized the borrow transaction (address of the router)
     *  @param borrower Address of the borrower that is leveraging
     *  @param borrowAmount The amount to leverage
     *  @param data The encoded byte data passed from the CygnusBorrow contract to the router
     */
    function altairBorrow_O9E(
        address sender,
        address borrower,
        uint256 borrowAmount,
        bytes calldata data
    ) external;

    /**
     *  @notice Function that is called by the CygnusCollateral contract and decodes data to carry out the deleverage
     *  @notice Will only succeed if: Caller is collateral contract & collateral contract was called by router
     *  @param sender Address of the contract that initialized the redeem transaction (address of the router)
     *  @param redeemAmount The amount to deleverage
     *  @param _token0 The token0 of this LP Token from CollateralVoid
     *  @param _token1 The token1 of this LP Token from CollateralVoid
     *  @param data The encoded byte data passed from the CygnusCollateral contract to the router
     */
    function altairRedeem_u91A(
        address sender,
        uint256 redeemAmount,
        address _token0,
        address _token1,
        bytes calldata data
    ) external;
}


// File contracts/cygnus-periphery/interfaces/IYakAdapter.sol

// g-Identifier: Unlicensed
pragma solidity >=0.8.4;

// Interface to interact with YAK adapters
interface IYakAdapter {
    /**
     *  @notice Queries amount out given an amount to swap, the token we are swapping and receiving
     *  @param _amountIn The amount of _tokenIn we want to swap
     *  @param _tokenIn The address of the token we are swapping
     *  @param _tokenOut The address of the token we are receiving
     *  @return amountOut The amount of tokenOut we are receiving
     */
    function query(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut
    ) external returns (uint256 amountOut);

    /**
     *  @notice Performs a swap directly on the adapter, bypassing the yak router
     *  @param _amountIn The amount we are swapping
     *  @param _amountOut The amount we are receiving
     *  @param _fromToken The address of the token we are swapping
     *  @param _toToken The address of the token we are receiving
     *  @param _to The address of CygnusAltair
     */
    function swap(
        uint256 _amountIn,
        uint256 _amountOut,
        address _fromToken,
        address _toToken,
        address _to
    ) external;

    struct FormattedOffer {
        uint256[] amounts;
        address[] adapters;
        address[] path;
    }

    struct Trade {
        uint256 amountIn;
        uint256 amountOut;
        address[] path;
        address[] adapters;
    }

    function findBestPath(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut,
        uint256 _maxSteps
    ) external view returns (FormattedOffer memory);

    function swapNoSplit(
        Trade calldata _trade,
        address _to,
        uint256 _fee
    ) external;

    struct Query {
        address adapter;
        address tokenIn;
        address tokenOut;
        uint256 amountOut;
    }

    function queryNoSplit(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut,
        uint8[] calldata _options
    ) external view returns (Query memory);
}


// File contracts/cygnus-periphery/interfaces/core/IDexRouter.sol

// g-Identifier: Unlicensed
pragma solidity >=0.8.4;

interface IDexRouter01 {
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

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

// File: contracts/traderjoe/interfaces/IJoeRouter02.sol

interface IDexRouter02 is IDexRouter01 {
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


// File contracts/cygnus-periphery/interfaces/ICygnusAltairX.sol

// g-Identifier: Unlicensed
pragma solidity >=0.8.4;

// Dependencies

// Interfaces


/**
 *  @notice Interface to interact with Cygnus' router contract
 */
interface ICygnusAltairX is ICygnusAltairCall {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:error NotnativeTokenSender Emitted when the underlying is not Avax
     */
    error CygnusAltair__NotNativeTokenSender(address poolToken);

    /**
     *  @custom:error TransactionExpired Emitted when the current block.timestamp is past deadline
     */
    error CygnusAltair__TransactionExpired(uint256);

    /**
     *  @custom:error InsufficientBurnAmountA Emitted when the burn amount is 0 for token A
     */
    error CygnusAltair__InsufficientBurnAmountA(uint256 amount);

    /**
     *  @custom:error InsufficientBurnAmountB Emitted when the burn amount is 0 for token B
     */
    error CygnusAltair__InsufficientBurnAmountB(uint256 amount);

    /**
     *  @custom:error MsgSenderNotRouter Emitted when the msg sender is not the router in the leverage function
     */
    error CygnusAltair__MsgSenderNotRouter(address sender, address origin, address borrower);

    /**
     *  @custom:error MsgSenderNotBorrowable Emitted when the msg sender is not the borrow contract
     */
    error CygnusAltair__MsgSenderNotBorrowable(address sender, address borrowable);

    /**
     *  @custom:error InvalidRedeemAmount Emitted when the redeem amount is 0 or less
     */
    error CygnusAltair__InvalidRedeemAmount(address redeemer, uint256 redeemTokens);

    /**
     *  @custom:error MsgSenderNotCollateral Emitted when the msg sender is not the collateral contract
     */
    error CygnusAltair__MsgSenderNotCollateral(address sender, address collateral);

    /**
     *  @custom:error MsgSenderNotAdmin Emitted when the msg sender is not the cygnus factory admin
     */
    error CygnusAltair__MsgSenderNotAdmin(address sender, address admin);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @return hangar18 The address of the Cygnus factory contract V1
     */
    function hangar18() external view returns (address);

    /**
     *  @return nativeToken The address of wrapped Avax
     */
    function nativeToken() external view returns (address);

    /**
     *  @return dai The address of DAI on this chain
     */
    function dai() external view returns (address);

    /**
     *  @return LOCAL_BYTES Empty bytes 0x
     */
    function LOCAL_BYTES() external view returns (bytes memory);

    /**
     *  @return USDC The address of USDC to return the best price between dai/avax or usdc/avax
     */
    function USDC() external pure returns (address);

    /**
     *  @return YAK_ROUTER The address of Yak's dex aggregator
     */
    function YAK_ROUTER() external pure returns (IYakAdapter);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Main function used in Cygnus to borrow DAI
     *  @param amount Amount of DAI to borrow
     *  @param recipient The address of the borrower
     *  @param deadline The time by which the transaction must be included to effect the change
     *  @param permitData The permit calldata (if any)
     */
    function borrow(
        address cygnusDai,
        uint256 amount,
        address recipient,
        uint256 deadline,
        bytes memory permitData
    ) external;

    /**
     *  @notice Main function used in Cygnus to repay borrows
     *  @param amountMax The max amount to repay
     *  @param borrower Thea ddress of the borrower
     *  @param deadline The time by which the transaction must be included to effect the change
     */
    function repay(
        address cygnusDai,
        uint256 amountMax,
        address borrower,
        uint256 deadline
    ) external returns (uint256 amount);

    /**
     *  @notice Main function used in Cygnus to liquidate borrows
     *  @param cygnusDai The address of Cygnus albireo
     *  @param amountMax The maximum amount to liquidate
     *  @param borrower The address of the borrower
     *  @param recipient The address of the recipient
     *  @param deadline The time by which the transaction must be included to effect the change
     */
    function liquidate(
        address cygnusDai,
        uint256 amountMax,
        address borrower,
        address recipient,
        uint256 deadline
    ) external returns (uint256 amount, uint256 seizeTokens);

    /**
     *  @notice Function to liquidate a borrower and immediately convert holdings to DAI
     *  @param cygnusDai The address of Cygnus albireo
     *  @param amountMax The amount to liquidate
     *  @param borrower The address of the borrower
     *  @param recipient The address of the recipient
     *  @param deadline The time by which the transaction must be included to effect the change
     */
    function liquidateToDai(
        address cygnusDai,
        uint256 amountMax,
        address borrower,
        address recipient,
        uint256 deadline
    ) external returns (uint256 amountDai);

    /**
     *  @notice Main leverage function
     *  @param collateral The address of the Cygnus collateral
     *  @param amount The amount to leverage
     *  @param recipient The address of the recipient
     *  @param deadline The time by which the transaction must be included to effect the change
     *  @param permitData The permit calldata (if any)
     */
    function leverage(
        address collateral,
        uint256 amount,
        address recipient,
        uint256 deadline,
        bytes calldata permitData
    ) external;

    /**
     *  @notice Main deleverage function
     *  @param collateral The address of the collateral of the lending pool
     *  @param redeemTokens The amount to CygLP to deleverage
     *  @param deadline The time by which the transaction must be included to effect the change
     *  @param permitData The permit calldata (if any)
     */
    function deleverage(
        address collateral,
        uint256 redeemTokens,
        uint256 deadline,
        bytes calldata permitData
    ) external;

    /**
     *  @notice Function that is called by the CygnusBorrow contract and decodes data to carry out the leverage
     *  @notice Will only succeed if: Caller is borrow contract & Borrow contract was called by router
     *  @param sender Address of the contract that initialized the borrow transaction (address of the router)
     *  @param borrower Address of the borrower that is leveraging
     *  @param borrowAmount The amount to leverage
     *  @param data The encoded byte data passed from the CygnusBorrow contract to the router
     */
    function altairBorrow_O9E(
        address sender,
        address borrower,
        uint256 borrowAmount,
        bytes calldata data
    ) external override(ICygnusAltairCall);

    /**
     *  @notice Function that is called by the CygnusCollateral contract and decodes data to carry out the deleverage
     *  @notice Will only succeed if: Caller is collateral contract & collateral contract was called by router
     *  @param sender Address of the contract that initialized the redeem transaction (address of the router)
     *  @param redeemAmount The amount to deleverage
     *  @param data The encoded byte data passed from the CygnusCollateral contract to the router
     */
    function altairRedeem_u91A(
        address sender,
        uint256 redeemAmount,
        address token0,
        address token1,
        bytes calldata data
    ) external override(ICygnusAltairCall);

    /**
     *  @notice Add adapter to optimize leverage and deleverage
     *  @param adapter The uint8 identifier for the adapter we are adding
     */
    function addAdapter(uint8 adapter) external;
}


// File contracts/cygnus-periphery/utils/Context.sol

// g-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
pragma solidity >=0.8.4;

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


// File contracts/cygnus-periphery/interfaces/core/IErc20.sol

// g-Identifier: Unlicense
pragma solidity >=0.8.4;

/// @title IErc20
/// @author Paul Razvan Berg
/// @notice Implementation for the Erc20 standard.
///
/// We have followed general OpenZeppelin guidelines: functions revert instead of returning
/// `false` on failure. This behavior is nonetheless conventional and does not conflict with
/// the with the expectations of Erc20 applications.
///
/// Additionally, an {Approval} event is emitted on calls to {transferFrom}. This allows
/// applications to reconstruct the allowance for all accounts just by listening to said
/// events. Other implementations of the Erc may not emit these events, as it isn't
/// required by the specification.
///
/// Finally, the non-standard {decreaseAllowance} and {increaseAllowance} functions have been
/// added to mitigate the well-known issues around setting allowances.
///
/// @dev Forked from OpenZeppelin
/// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/token/ERC20/ERC20.sol
interface IErc20 {
    /// CUSTOM ERRORS ///

    /// @notice Emitted when the owner is the zero address.
    error Erc20__ApproveOwnerZeroAddress();

    /// @notice Emitted when the spender is the zero address.
    error Erc20__ApproveSpenderZeroAddress();

    /// @notice Emitted when burning more tokens than are in the account.
    error Erc20__BurnUnderflow(uint256 accountBalance, uint256 burnAmount);

    /// @notice Emitted when the holder is the zero address.
    error Erc20__BurnZeroAddress();

    /// @notice Emitted when the owner did not give the spender sufficient allowance.
    error Erc20__InsufficientAllowance(uint256 allowance, uint256 amount);

    /// @notice Emitted when tranferring more tokens than there are in the account.
    error Erc20__InsufficientBalance(uint256 senderBalance, uint256 amount);

    /// @notice Emitted when the beneficiary is the zero address.
    error Erc20__MintZeroAddress();

    /// @notice Emitted when the sender is the zero address.
    error Erc20__TransferSenderZeroAddress();

    /// @notice Emitted when the recipient is the zero address.
    error Erc20__TransferRecipientZeroAddress();

    /// EVENTS ///

    /// @notice Emitted when an approval happens.
    /// @param owner The address of the owner of the tokens.
    /// @param spender The address of the spender.
    /// @param amount The maximum amount that can be spent.
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /// @notice Emitted when a transfer happens.
    /// @param from The account sending the tokens.
    /// @param to The account receiving the tokens.
    /// @param amount The amount of tokens transferred.
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// CONSTANT FUNCTIONS ///

    /// @notice Returns the remaining number of tokens that `spender` will be allowed to spend
    /// on behalf of `owner` through {transferFrom}. This is zero by default.
    ///
    /// @dev This value changes when {approve} or {transferFrom} are called.
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Returns the amount of tokens owned by `account`.
    function balanceOf(address account) external view returns (uint256);

    /// @notice Returns the number of decimals used to get its user representation.
    function decimals() external view returns (uint8);

    /// @notice Returns the name of the token.
    function name() external view returns (string memory);

    /// @notice Returns the symbol of the token, usually a shorter version of the name.
    function symbol() external view returns (string memory);

    /// @notice Returns the amount of tokens in existence.
    function totalSupply() external view returns (uint256);

    /// NON-CONSTANT FUNCTIONS ///

    /// @notice Sets `amount` as the allowance of `spender` over the caller's tokens.
    ///
    /// @dev Emits an {Approval} event.
    ///
    /// IMPORTANT: Beware that changing an allowance with this method brings the risk that someone may
    /// use both the old and the new allowance by unfortunate transaction ordering. One possible solution
    /// to mitigate this race condition is to first reduce the spender's allowance to 0 and set the desired
    /// value afterwards: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    ///
    /// Requirements:
    ///
    /// - `spender` cannot be the zero address.
    ///
    /// @return a boolean value indicating whether the operation succeeded.
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Atomically decreases the allowance granted to `spender` by the caller.
    ///
    /// @dev Emits an {Approval} event indicating the updated allowance.
    ///
    /// This is an alternative to {approve} that can be used as a mitigation for problems described
    /// in {Erc20Interface-approve}.
    ///
    /// Requirements:
    ///
    /// - `spender` cannot be the zero address.
    /// - `spender` must have allowance for the caller of at least `subtractedAmount`.
    function decreaseAllowance(address spender, uint256 subtractedAmount) external returns (bool);

    /// @notice Atomically increases the allowance granted to `spender` by the caller.
    ///
    /// @dev Emits an {Approval} event indicating the updated allowance.
    ///
    /// This is an alternative to {approve} that can be used as a mitigation for the problems described above.
    ///
    /// Requirements:
    ///
    /// - `spender` cannot be the zero address.
    function increaseAllowance(address spender, uint256 addedAmount) external returns (bool);

    /// @notice Moves `amount` tokens from the caller's account to `recipient`.
    ///
    /// @dev Emits a {Transfer} event.
    ///
    /// Requirements:
    ///
    /// - `recipient` cannot be the zero address.
    /// - The caller must have a balance of at least `amount`.
    ///
    /// @return a boolean value indicating whether the operation succeeded.
    function transfer(address recipient, uint256 amount) external returns (bool);

    /// @notice Moves `amount` tokens from `sender` to `recipient` using the allowance mechanism. `amount`
    /// `is then deducted from the caller's allowance.
    ///
    /// @dev Emits a {Transfer} event and an {Approval} event indicating the updated allowance. This is
    /// not required by the Erc. See the note at the beginning of {Erc20}.
    ///
    /// Requirements:
    ///
    /// - `sender` and `recipient` cannot be the zero address.
    /// - `sender` must have a balance of at least `amount`.
    /// - The caller must have approed `sender` to spent at least `amount` tokens.
    ///
    /// @return a boolean value indicating whether the operation succeeded.
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}


// File contracts/cygnus-periphery/interfaces/core/IErc20Permit.sol

// g-Identifier: Unlicense
// solhint-disable func-name-mixedcase
pragma solidity >=0.8.4;

/// @title IErc20Permit
/// @author Paul Razvan Berg
/// @notice Extension of Erc20 that allows token holders to use their tokens without sending any
/// transactions by setting the allowance with a signature using the `permit` method, and then spend
/// them via `transferFrom`.
/// @dev See https://eips.ethereum.org/EIPS/eip-2612.
interface IErc20Permit is IErc20 {
    /// @notice Emitted when the recovered owner does not match the actual owner.
    error Erc20Permit__InvalidSignature(uint8 v, bytes32 r, bytes32 s);

    /// @notice Emitted when the owner is the zero address.
    error Erc20Permit__OwnerZeroAddress();

    /// @notice Emitted when the permit expired.
    error Erc20Permit__PermitExpired(uint256 deadline);

    /// @notice Emitted when the recovered owner is the zero address.
    error Erc20Permit__RecoveredOwnerZeroAddress();

    /// @notice Emitted when the spender is the zero address.
    error Erc20Permit__SpenderZeroAddress();

    /// NON-CONSTANT FUNCTIONS ///

    /// @notice Sets `value` as the allowance of `spender` over `owner`'s tokens, assuming the latter's
    /// signed approval.
    ///
    /// @dev Emits an {Approval} event.
    ///
    /// IMPORTANT: The same issues Erc20 `approve` has related to transaction
    /// ordering also apply here.
    ///
    /// Requirements:
    ///
    /// - `owner` cannot be the zero address.
    /// - `spender` cannot be the zero address.
    /// - `deadline` must be a timestamp in the future.
    /// - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner` over the Eip712-formatted
    /// function arguments.
    /// - The signature must use `owner`'s current nonce.
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /// CONSTANT FUNCTIONS ///

    /// @notice The Eip712 domain's keccak256 hash.
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /// @notice Provides replay protection.
    function nonces(address account) external view returns (uint256);

    /// @notice keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    function PERMIT_TYPEHASH() external view returns (bytes32);

    /// @notice Eip712 version of this implementation.
    function version() external view returns (string memory);

    function chainId() external view returns (uint256);
}


// File contracts/cygnus-periphery/interfaces/core/ICygnusTerminal.sol

// g-Identifier: UNLICENSED
pragma solidity >=0.8.4;

// Dependencies

/**
 *  @title The interface for CygnusTerminal which handles pool tokens shared by Collateral and Borrow contracts
 *  @notice The interface for the CygnusTerminal contract allows minting/redeeming Cygnus pool tokens
 */
interface ICygnusTerminal is IErc20Permit {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:error CantMintZeroShares Emitted when attempting to mint zero amount of tokens
     */
    error CygnusTerminal__CantMintZeroShares();

    /**
     *  @custom:error CantBurnZeroAssets Emitted when attempting to redeem zero amount of tokens
     */
    error CygnusTerminal__CantRedeemZeroAssets();

    /**
     *  @custom:error RedeemAmountInvalid Emitted when attempting to redeem over amount of tokens
     */
    error CygnusTerminal__RedeemAmountInvalid(uint256 assets, uint256 totalBalance);

    /**
     *  @custom:error MsgSenderNotAdmin Emitted when attempting to call Admin-only functions
     */
    error CygnusTerminal__MsgSenderNotAdmin(address sender, address factoryAdmin);

    /**
     *  @custom:error CantSweepUnderlying Emitted when trying to sweep the underlying from this contract
     */
    error CygnusTerminal__CantSweepUnderlying(address token, address underlying);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Logs when totalBalance is syncd to real balance
     *  @param totalBalance Total balance in terms of the underlying
     *  @custom:event Sync Emitted when `totalBalance` is in sync with balanceOf(address(this)).
     */
    event Sync(uint256 totalBalance);

    /**
     *  @notice Logs when an asset is minted
     *  @param sender The address of `CygnusAltair` or the sender of the function call
     *  @param recipient Address of the minter
     *  @param assets Amount of assets being deposited
     *  @param shares Amount of pool tokens being minted
     *  @custom:event Mint Emitted when CygLP or CygDai pool tokens are minted
     */
    event Deposit(address indexed sender, address indexed recipient, uint256 assets, uint256 shares);

    /**
     *  @notice Logs when an asset is redeemed
     *  @param sender The address of `CygnusAltair` or the sender of the function call
     *  @param recipient The address of the recipient of assets
     *  @param owner The address of the owner of the pool tokens
     *  @param assets The amount of assets to redeem
     *  @param shares The amount of pool tokens burnt
     *  @custom:event Redeem Emitted when CygLP or CygDAI are redeemed
     */
    event Withdraw(address indexed sender, address indexed recipient, address indexed owner, uint256 assets, uint256 shares);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
           3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @return totalBalance Total balance of this shuttle in terms of the underlying
     */
    function totalBalance() external returns (uint256);

    /**
     *  @return underlying The address of the underlying (LP Token for collateral contracts, DAI for borrow contracts)
     */
    function underlying() external returns (address);

    /**
     *  @return hangar18 The address of the Cygnus Factory V1 contract 🛸
     */
    function hangar18() external returns (address);

    /**
     *  @notice Trick compiler for nonpayable function
     *  @return exchangeRate The ratio at which 1 pool token can be redeemed for underlying amount
     */
    function exchangeRate() external returns (uint256);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @dev This low level function should only be called from `CygnusAltair` contract only
     *  @param assets The amount of assets to deposit
     *  @param recipient Address of the minter
     *  @return shares Amount of pool tokens to mint
     *  @custom:security non-reentrant
     */
    function deposit(uint256 assets, address recipient) external returns (uint256 shares);

    /**
     *  @dev This low level function should only be called from `CygnusAltair` contract only
     *  @param shares The amount of shares to redeem for assets
     *  @param recipient The address of the redeemer
     *  @param owner The address of the account who owns the shares
     *  @return redeemAmount The holder's shares
     *  @custom:security non-reentrant
     */
    function redeem(
        uint256 shares,
        address recipient,
        address owner
    ) external returns (uint256 redeemAmount);

    /**
     *  @notice Recovers any ERC20 token accidentally sent to this contract. Sent to DAO reserves
     *  @param token The address of the token we are recovering
     */
    function sweepToken(address token) external;
}


// File contracts/cygnus-periphery/interfaces/core/ICygnusBorrowControl.sol

// g-Identifier: Unlicensed
pragma solidity >=0.8.4;

// Dependencies

/**
 *  @title ICygnusBorrowControl Interface for the control of borrow contracts (interest rate params, reserves, etc.)
 */
interface ICygnusBorrowControl is ICygnusTerminal {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:error ParameterNotInRange Emitted when the value is below minRange or above maxRange
     */
    error CygnusBorrowControl__ParameterNotInRange(uint256 minRange, uint256 maxRange, uint256 value);

    /**
     *  @custom:error BorrowTrackerAlreadySet Emitted when the new borrow tracker is the same as current
     */
    error CygnusBorrowControl__BorrowTrackerAlreadySet(address currentTracker, address newTracker);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Logs when the borrow tracker is updated by admins
     *  @param oldBorrowTracker The address of the borrow tracker up until this point used for CYG distribution
     *  @param newBorrowTracker The address of the new borrow tracker
     *  @custom:event NewCygnusBorrowTracker Emitted when a new borrow tracker is set set by admins
     */
    event NewCygnusBorrowTracker(address oldBorrowTracker, address newBorrowTracker);

    /**
     *  @notice Logs when the reserve factor is updated by admins
     *  @param oldReserveFactor The reserve factor used in this shuttle until this point
     *  @param newReserveFactor The new reserve factor set
     *  @custom:event NewReserveFactor Emitted when a new reserve factor is set set by admins
     */
    event NewReserveFactor(uint256 oldReserveFactor, uint256 newReserveFactor);

    /**
     *  @notice Logs when the kink utilization rate is updated by admins
     *  @param oldKinkUtilizationRate The kink utilization rate used in this shuttle until this point
     *  @param newKinkUtilizationRate The new kink utilization rate set
     *  @custom:event NewKinkUtilizationRate Emitted when a new kink utilization rate is set set by admins
     */
    event NewKinkUtilizationRate(uint256 oldKinkUtilizationRate, uint256 newKinkUtilizationRate);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    // ──────────────────────────── Important Addresses

    /**
     *  @return collateral Address of the collateral contract
     */
    function collateral() external view returns (address);

    /**
     *  @return cygnusBorrowTracker Address of the borrow tracker.
     */
    function cygnusBorrowTracker() external view returns (address);

    // ───────────────────────────── Current pool rates

    /**
     *  @return exchangeRateStored The current exchange rate of tokens
     */
    function exchangeRateStored() external view returns (uint256);

    /**
     *  @return kinkUtilizationRate Current utilization point at which the jump multiplier is applied
     */
    function kinkUtilizationRate() external view returns (uint256);

    /**
     *  @return reserveFactor Percentage of interest that is routed to this market's Reserve Pool
     */
    function reserveFactor() external view returns (uint256);

    /**
     *  @return kinkMultiplier The multiplier that is applied to the interest rate once util > kink
     */
    function kinkMultiplier() external view returns (uint256);

    // ─────────────────────── Min/Max this pool allows

    /**
     *  @return BASE_RATE_MAX Maximum base interest rate allowed (20%)
     */
    function BASE_RATE_MAX() external pure returns (uint256);

    /**
     *  @return KINK_UTILIZATION_RATE_MIN Minimum kink utilization point allowed, equivalent to 50%
     */
    function KINK_UTILIZATION_RATE_MIN() external pure returns (uint256);

    /**
     *  @return KINK_UTILIZATION_RATE_MAX Maximum Kink point allowed
     */
    function KINK_UTILIZATION_RATE_MAX() external pure returns (uint256);

    /**
     *  @return RESERVE_FACTOR_MAX The maximum reserve factor allowed
     */
    function RESERVE_FACTOR_MAX() external pure returns (uint256);

    /**
     *  @return KINK_MULTIPLIER_MAX The maximum kink multiplier than can be applied to this shuttle
     */
    function KINK_MULTIPLIER_MAX() external pure returns (uint256);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice 👽
     *  @notice Updates the borrow tracker contract
     *  @param newBorrowTracker The address of the new Borrow tracker
     *  @custom:security non-reentrant
     */
    function setCygnusBorrowTracker(address newBorrowTracker) external;

    /**
     *  @notice 👽
     *  @notice Updates the reserve factor
     *  @param newReserveFactor The new reserve factor for this shuttle
     *  @custom:security non-reentrant
     */
    function setReserveFactor(uint256 newReserveFactor) external;

    /**
     *  @notice 👽
     *  @notice Updates the kink utilization rate for this shuttle. To update the interest rate model this must be
     *          updated first
     *  @param newKinkUtilizationRate The new utilization rate at which the jump kultiplier takes effect
     *  @custom:security non-reentrant
     */
    function setKinkUtilizationRate(uint256 newKinkUtilizationRate) external;
}


// File contracts/cygnus-periphery/interfaces/core/ICygnusBorrowInterest.sol

// g-Identifier: Unlicensed
pragma solidity >=0.8.4;

// Dependencies

/**
 *  @title ICygnusBorrowInterest Interface for the Interest Rate model used by cygnus
 */
interface ICygnusBorrowInterest is ICygnusBorrowControl {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @param baseRatePerYear The approximate target base APR, as a mantissa (scaled by 1e18)
     *  @param multiplierPerYear The rate of increase in interest rate wrt utilization (scaled by 1e18)
     *  @param kinkMultiplier_ The increase to farmApy once kink utilization is reached
     *  custom:event Emitted when a new interest rate is set
     */
    event NewInterestRateParameters(uint256 baseRatePerYear, uint256 multiplierPerYear, uint256 kinkMultiplier_);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice baseRatePerSecond The interest rate for this pool when utilization is 0 divided by seconds in a year
     */
    function baseRatePerSecond() external view returns (uint256);

    /**
     *  @notice baseRatePerSecond The mulitplier for this pool divided by seconds in a year
     */
    function multiplierPerSecond() external view returns (uint256);

    /**
     *  @notice jumpMultiplierPerSecond The Jump multiplier for this pool divided by seconds in a year
     */
    function jumpMultiplierPerSecond() external view returns (uint256);

    /**
     *  @return SECONDS_PER_YEAR The seconds per year this model uses to calculate per second interest rates
     */
    function SECONDS_PER_YEAR() external view returns (uint32);

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice Internal function to update the parameters of the interest rate model
     *  @param newBaseRatePerYear The approximate target base APR, as a mantissa (scaled by 1e18)
     *  @param newMultiplierPerYear The rate of increase in interest rate wrt utilization (scaled by 1e18)
     *  @param newKink The increase to farmApy once kink utilization is reached
     */
    function updateJumpRateModel(
        uint256 newBaseRatePerYear,
        uint256 newMultiplierPerYear,
        uint256 newKink
    ) external;
}


// File contracts/cygnus-periphery/interfaces/core/ICygnusBorrowApprove.sol

// g-Identifier: Unlicensed
pragma solidity >=0.8.4;

/**
 *  @title CygnusBorrowApprove Interface for the approval of borrows before taking out a loan
 */
interface ICygnusBorrowApprove is ICygnusBorrowControl {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:error OwnerIsSpender Emitted when the owner is the spender
     */
    error CygnusBorrowApprove__OwnerIsSpender(address owner, address spender);

    /**
     *  @custom:error OwnerZeroAddress Emitted when the owner is the zero address
     */
    error CygnusBorrowApprove__OwnerZeroAddress(address owner, address spender);

    /**
     *  @custom:error SpenderZeroAddress Emitted when the spender is the zero address
     */
    error CygnusBorrowApprove__SpenderZeroAddress(address owner, address spender);

    /**
     *  @custom:error BorrowNotAllowed Emitted when borrowing above max allowance set
     */
    error CygnusBorrowApprove__BorrowNotAllowed(uint256 borrowAllowance, uint256 borrowAmount);

    /**
     *  @custom:error PermitExpired Emitted when the transaction permit is expired
     */
    error CygnusBorrowApprove__PermitExpired(uint256 transactDeadline, uint256 currentTimestamp);

    /**
     *  @custom:error RecoveredOwnerZeroAddress Emitted when the recovered owner is the zero address
     */
    error CygnusBorrowApprove__RecoveredOwnerZeroAddress(address recoveredOwner);

    /**
     *  @custom:error InvalidSignature Emitted when the recovered owner does not match the actual owner
     */
    error CygnusBorrowApprove__InvalidSignature(uint8 v, bytes32 r, bytes32 s);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Logs borrow allowance for a spender is updated
     *  @param owner Indexed address of the owner of the tokens
     *  @param spender The address of the user being allowed to spend the tokens
     *  @param amount The maximum amount of tokens the spender may spend
     *  @custom:event BorrowApproval Emitted when borrow allowance is updated
     */
    event BorrowApproval(address indexed owner, address spender, uint256 amount);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @notice IERC721 permit typehash for signature based borrow approvals
     *  @return BORROW_PERMIT_TYPEHASH The keccak256 of the owner, spender, value, nonce and deadline
     */
    function BORROW_PERMIT_TYPEHASH() external view returns (bytes32);

    /**
     *  @notice Mapping of spending allowances from one address to another address
     *  @param owner The address of the token owner
     *  @param spender The address of the token spender
     *  @return The maximum amount the spender can spend
     */
    function borrowAllowances(address owner, address spender) external view returns (uint256);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @param owner The address owner of the tokens
     *  @param spender The user allowed to spend the tokens
     *  @param value The maximum amount of tokens the spender may spend
     *  @param deadline A future time...
     *  @param v Must be a valid secp256k1 signature from the owner along with r and s
     *  @param r Must be a valid secp256k1 signature from the owner along with v and s
     *  @param s Must be a valid secp256k1 signature from the owner along with r and v
     */
    function borrowPermit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     *  @param spender The user allowed to spend the tokens
     *  @param value The amount of tokens approved to spend
     *  @return Whether or not the borrow was approved
     */
    function borrowApprove(address spender, uint256 value) external returns (bool);
}


// File contracts/cygnus-periphery/interfaces/core/ICygnusBorrowTracker.sol

// g-Identifier: Unlicensed
pragma solidity >=0.8.4;


interface ICygnusBorrowTracker is ICygnusBorrowInterest, ICygnusBorrowApprove {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @param cashStored Total balance of this market.
     *  @param interestAccumulated Interest accumulated since last update.
     *  @param borrowIndexStored orrow index
     *  @param totalBorrowsStored Total borrow balances.
     *  @param borrowRateStored The current borrow rate.
     *  @custom:event Emitted when interest is accrued.
     */
    event AccrueInterest(
        uint256 cashStored,
        uint256 interestAccumulated,
        uint256 borrowIndexStored,
        uint256 totalBorrowsStored,
        uint256 borrowRateStored
    );

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @return totalReserves The current total DAI reserves stored for this lending pool
     */
    function totalReserves() external view returns (uint128);

    /**
     *  @return totalBorrows Total borrows stored in the lending pool
     */
    function totalBorrows() external view returns (uint128);

    /**
     *  @return borrowIndex Borrow index stored of this lending pool, starts at 1e18
     */
    function borrowIndex() external view returns (uint112);

    /**
     *  @return borrowRate The current per-second borrow rate stored for this lending pool. To get the borrow APY
     *          we must annualize this (i.e. borrowRate * SECONDS_PER_YEAR)
     */
    function borrowRate() external view returns (uint112);

    /**
     *  @return lastAccrualTimestamp The unix timestamp stored of the last interest rate accrual
     */
    function lastAccrualTimestamp() external view returns (uint32);

    /**
     *  @notice This public view function is used to get the borrow balance of users based on stored data
     *  @dev It is used by CygnusCollateral and CygnusCollateralModel contracts
     *  @param borrower The address whose balance should be calculated
     *  @return balance The account's outstanding borrow balance or 0 if borrower's interest index is zero
     */
    function getBorrowBalance(address borrower) external view returns (uint256 balance);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @notice Applies interest accruals to borrows and reserves (uses 2 memory slots with blockTimeStamp)
     */
    function accrueInterest() external;

    /**
     *  @notice Tracks borrows of each user for farming rewards and passes the borrow data to the farming pool
     *  @param borrower Address of borrower
     */
    function trackBorrow(address borrower) external;
}


// File contracts/cygnus-periphery/interfaces/core/ICygnusBorrow.sol

// g-Identifier: Unlicensed
pragma solidity >=0.8.4;

/**
 *  @title ICygnusBorrow Interface for the main Borrow contract which handles borrows/liquidations
 */
interface ICygnusBorrow is ICygnusBorrowTracker {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:error BorrowExceedsTotalBalance Emitted when the borrow amount is higher than total balance
     */
    error CygnusBorrow__BorrowExceedsTotalBalance(uint256 invalidBorrowAmount, uint256 contractBalance);

    /**
     *  @custom:error InsufficientLiquidity Emitted if there is borrowe has insufficient liquidity for this borrow
     */
    error CygnusBorrow__InsufficientLiquidity(address cygnusCollateral, address borrower, uint256 borrowerBalance);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Logs when an account liquidates a borrower
     *  @param sender Indexed address of msg.sender (should be `Router` address
     *  @param borrower Indexed address the account with negative account liquidity that shall be liquidated
     *  @param liquidator Indexed address of the liquidator
     *  @param denebAmount The amount of the underlying asset to be seized
     *  @param repayAmount The amount of the underlying asset to be repaid (factors in liquidation incentive)
     *  @param accountBorrowsPrior Record of borrower's total borrows before this event
     *  @param accountBorrows Record of borrower's present borrows (accountBorrowsPrior + borrowAmount)
     *  @param totalBorrowsStored Record of the protocol's cummulative total borrows after this event
     *  @custom:event Liquidate Emitted upon a successful liquidation
     */
    event Liquidate(
        address indexed sender,
        address indexed borrower,
        address indexed liquidator,
        uint256 denebAmount,
        uint256 repayAmount,
        uint256 accountBorrowsPrior,
        uint256 accountBorrows,
        uint256 totalBorrowsStored
    );

    /**
     *  @notice Event for account borrows and repays indexed by periphery, borrower and receiver addresses
     *  @param sender Indexed address of msg.sender (should be `Router` address)
     *  @param receiver Indexed address of receiver (if repay = this is address(0), if borrow `Router` address)
     *  @param borrower Indexed address of the borrower
     *  @param borrowAmount If borrow calldata, the amount of the underlying asset to be borrowed, else 0
     *  @param repayAmount If repay calldata, the amount of the underlying borrowed asset to be repaid, else 0
     *  @param accountBorrowsPrior Record of borrower's total borrows before this event
     *  @param accountBorrows Record of borrower's total borrows after this event ( + borrowAmount) or ( - repayAmount)
     *  @param totalBorrowsStored Record of the protocol's cummulative total borrows after this event.
     *  @custom:event Borrow Emitted upon a successful borrow or repay
     */
    event Borrow(
        address indexed sender,
        address indexed borrower,
        address indexed receiver,
        uint256 borrowAmount,
        uint256 repayAmount,
        uint256 accountBorrowsPrior,
        uint256 accountBorrows,
        uint256 totalBorrowsStored
    );

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice This low level function should only be called from `CygnusAltair` contract only
     *  @param borrower The address of the borrower being liquidated
     *  @param liquidator The address of the liquidator
     *  @return seizeTokens The amount of tokens to liquidate
     */
    function liquidate(address borrower, address liquidator) external returns (uint256 seizeTokens);

    /**
     *  @notice This low level function should only be called from Router contract only.
     *  @param borrower The address of the Borrow contract.
     *  @param receiver The address of the receiver of the borrow amount.
     *  @param borrowAmount The amount of the underlying asset to borrow.
     *  @param data Calltype data passed to Router contract.
     */
    function borrow(
        address borrower,
        address receiver,
        uint256 borrowAmount,
        bytes calldata data
    ) external;

    /**
     *  @notice Overrides the exchange rate of `CygnusTerminal` for borrow contracts to mint reserves
     */
    function exchangeRate() external override returns (uint256);
}


// File contracts/cygnus-periphery/interfaces/core/AggregatorV3Interface.sol

// g-Identifier: Unlicensed
pragma solidity ^0.8.4;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
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


// File contracts/cygnus-periphery/interfaces/core/IDexPair.sol

//g-Identifier: Unlicensed
pragma solidity >=0.8.4;

// only using relevant functions for CygnusNebula Oracle

/// @notice Interface for most DEX pairs (TraderJoe, Pangolin, Sushi, Uniswap, etc.)
interface IDexPair {
    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

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

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function mint(address to) external returns (uint256 liquidity);
}


// File contracts/cygnus-periphery/interfaces/core/IChainlinkNebulaOracle.sol

// g-Identifier: Unlicensed
pragma solidity ^0.8.4;


/**
 *  @title IChainlinkNebulaOracle Interface to interact with Cygnus' Chainlink oracle
 */
interface IChainlinkNebulaOracle {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:error PairIsInitialized Emitted when attempting to initialize an already initialized LP Token
     */
    error ChainlinkNebulaOracle__PairAlreadyInitialized(address lpTokenPair);

    /**
     *  @custom:error PairNotInitialized Emitted when attempting to get the price of an LP Token that is not initialized
     */
    error ChainlinkNebulaOracle__PairNotInitialized(address lpTokenPair);

    /**
     *  @custom:error MsgSenderNotAdmin Emitted when attempting to access admin only methods
     */
    error ChainlinkNebulaOracle__MsgSenderNotAdmin(address msgSender);

    /**
     *  @custom:error AdminCantBeZero Emitted when attempting to set the admin if the pending admin is the zero address
     */
    error ChainlinkNebulaOracle__AdminCantBeZero(address pendingAdmin);

    /**
     *  @custom:error PendingAdminAlreadySet Emitted when attempting to set the same pending admin twice
     */
    error ChainlinkNebulaOracle__PendingAdminAlreadySet(address pendingAdmin);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Logs when a new LP Token is added to this oracle and the price is being tracked
     *  @param initialized Whether or not the LP Token is initialized
     *  @param oracleId The ID for this oracle
     *  @param lpTokenPair The address of the LP Token
     *  @param priceFeedA The address of the Chainlink's aggregator contract for this LP Token's token0
     *  @param priceFeedB The address of the Chainlink's aggregator contract for this LP Token's token1
     *  @custom:event InitializeChainlinkNebula Emitted when an LP Token pair's price starts being tracked
     */
    event InitializeChainlinkNebula(
        bool initialized,
        uint24 oracleId,
        address lpTokenPair,
        AggregatorV3Interface priceFeedA,
        AggregatorV3Interface priceFeedB
    );

    /**
     *  @notice Logs when an LP Token is removed from this oracle, rendering all calls on this LP Token null
     *  @param oracleId The ID for this oracle
     *  @param lpTokenPair The contract address of the LP Token
     *  @param priceFeedA The contract address of Chainlink's aggregator contract for this LP Token's token0
     *  @param priceFeedB The contract address of the Chainlink's aggregator contract for this LP Token's token1
     *  @custom:event DeleteChainlinkNebula Emitted when an LP Token pair is removed from this oracle
     */
    event DeleteChainlinkNebula(
        uint24 oracleId,
        address lpTokenPair,
        AggregatorV3Interface priceFeedA,
        AggregatorV3Interface priceFeedB,
        address msgSender
    );

    /**
     *  @notice Logs when a new pending admin for the oracle is set
     *  @param oracleCurrentAdmin The address of the current oracle admin
     *  @param oraclePendingAdmin The address of the pending oracle admin
     *  @custom:event NewNebulaPendingAdmin Emitted when a new pending admin is set, to be accepted by admin
     */
    event NewOraclePendingAdmin(address oracleCurrentAdmin, address oraclePendingAdmin);

    /**
     *  @notice Logs when a new admin for the oracle is confirmed
     *  @param oracleOldAdmin The address of the old oracle admin
     *  @param oracleNewAdmin The address of the new oracle admin
     *  @custom:event NewNebulaAdmin Emitted when the pending admin is confirmed as the new oracle admin
     */
    event NewOracleAdmin(address oracleOldAdmin, address oracleNewAdmin);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @notice Returns the struct record of each oracle used by Cygnus
     *  @param lpTokenPair The address of the LP Token
     *  @return initialized Whether an LP Token is being tracked or not
     *  @return oracleId The ID of the LP Token tracked by the oracle
     *  @return underlying The address of the LP Token
     *  @return priceFeedA The address of the Chainlink aggregator used for this LP Token's Token0
     *  @return priceFeedB The address of the Chainlink aggregator used for this LP Token's Token1
     */
    function getNebula(address lpTokenPair)
        external
        view
        returns (
            bool initialized,
            uint24 oracleId,
            address underlying,
            AggregatorV3Interface priceFeedA,
            AggregatorV3Interface priceFeedB
        );

    /**
     *  @notice Gets the address of the LP Token that (if) is being tracked by this oracle
     *  @param id The ID of each LP Token that is being tracked by this oracle
     *  @return The address of the LP Token if it is being tracked by this oracle, else returns address zero
     */
    function allNebulas(uint256 id) external view returns (address);

    /**
     *  @return The name for this Cygnus-Chainlink Nebula oracle
     */
    function name() external view returns (string memory);

    /**
     *  @return The decimals for this Cygnus-Chainlink Nebula oracle
     */
    function decimals() external view returns (uint8);

    /**
     *  @return The symbol for this Cygnus-Chainlink Nebula oracle
     */
    function symbol() external view returns (string memory);

    /**
     *  @return The address of Chainlink's DAI oracle
     */
    function dai() external view returns (AggregatorV3Interface);

    /**
     *  @return The address of the Cygnus admin
     */
    function admin() external view returns (address);

    /**
     *  @return The address of the new requested admin
     */
    function pendingAdmin() external view returns (address);

    /**
     *  @return The version of this oracle
     */
    function version() external view returns (uint8);

    /**
     *  @return How many LP Token pairs' prices are being tracked by this oracle
     */
    function nebulaSize() external view returns (uint24);

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @return The price of DAI with 18 decimals
     */
    function daiPrice() external view returns (uint256);

    /**
     *  @notice Gets the latest price of the LP Token denominated in DAI
     *  @notice LP Token pair must be initialized, else reverts with custom error
     *  @param lpTokenPair The address of the LP Token
     *  @return lpTokenPrice The price of the LP Token denominated in DAI
     */
    function lpTokenPriceDai(address lpTokenPair) external view returns (uint256 lpTokenPrice);

    /**
     *  @notice Gets the latest price of the LP Token's token0 and token1 denominated in DAI
     *  @notice Used by Cygnus Altair contract to calculate optimal amount of leverage
     *  @param lpTokenPair The address of the LP Token
     *  @return tokenPriceA The price of the LP Token's token0 denominated in DAI
     *  @return tokenPriceB The price of the LP Token's token1 denominated in DAI
     */
    function assetPricesDai(address lpTokenPair) external view returns (uint256 tokenPriceA, uint256 tokenPriceB);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice Initialize an LP Token pair, only admin
     *  @param lpTokenPair The contract address of the LP Token
     *  @param priceFeedA The contract address of the Chainlink's aggregator contract for this LP Token's token0
     *  @param priceFeedB The contract address of the Chainlink's aggregator contract for this LP Token's token1
     *  @custom:security non-reentrant
     */
    function initializeNebula(
        address lpTokenPair,
        AggregatorV3Interface priceFeedA,
        AggregatorV3Interface priceFeedB
    ) external;

    /**
     *  @notice Deletes an LP token pair from the oracle
     *  @notice After deleting, any call from a shuttle deployed that is using this pair will revert
     *  @param lpTokenPair The contract address of the LP Token to remove from the oracle
     *  @custom:security non-reentrant
     */
    function deleteNebula(address lpTokenPair) external;

    /**
     *  @notice Sets a new pending admin for the Oracle
     *  @param newOraclePendingAdmin Address of the requested Oracle Admin
     */
    function setOraclePendingAdmin(address newOraclePendingAdmin) external;

    /**
     *  @notice Sets a new admin for the Oracle
     */
    function setOracleAdmin() external;
}


// File contracts/cygnus-periphery/interfaces/core/ICygnusCollateralControl.sol

// g-Identifier: Unlicensed

pragma solidity >=0.8.4;

// Dependencies

// Interfaces

/**
 *  @title ICygnusCollateralControl Interface for the admin control of collateral contracts (incentives, debt ratios)
 */
interface ICygnusCollateralControl is ICygnusTerminal {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:error ParameterNotInRange Emitted when updating a collateral parameter outside of the range allowed
     */
    error CygnusCollateralControl__ParameterNotInRange(uint256 minRange, uint256 maxRange, uint256 value);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════  
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Logs when the debt ratio is updated by admins
     *  @param oldDebtRatio The old debt ratio at which the collateral was liquidatable in this shuttle
     *  @param newDebtRatio The new debt ratio for this shuttle
     *  @custom:event NewDebtRatio Emitted when a new debt ratio is set
     */
    event NewDebtRatio(uint256 oldDebtRatio, uint256 newDebtRatio);

    /**
     *  @notice Logs when the liquidation incentive is updated by admins
     *  @param oldLiquidationIncentive The old incentive for liquidators taken from the collateral
     *  @param newLiquidationIncentive The new liquidation incentive for this shuttle
     *  @custom:event NewLiquidationIncentive Emitted when a new liquidation incentive is set
     */
    event NewLiquidationIncentive(uint256 oldLiquidationIncentive, uint256 newLiquidationIncentive);
    /**
     *  @notice Logs when the liquidation fee is updated by admins
     *  @param oldLiquidationFee The previous fee the protocol kept as reserves from each liquidation
     *  @param newLiquidationFee The new liquidation fee for this shuttle
     *  @custom:event NewLiquidationFee Emitted when a new liquidation fee is set
     */
    event NewLiquidationFee(uint256 oldLiquidationFee, uint256 newLiquidationFee);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    // ────────────── Important Addresses ─────────────

    /**
     *  @return borrowable The address of the Cygnus borrow contract for this collateral which holds DAI
     */
    function borrowable() external view returns (address);

    /**
     *  @return cygnusNebulaOracle The address of the Cygnus Price Oracle
     */
    function cygnusNebulaOracle() external view returns (IChainlinkNebulaOracle);

    // ────────────── Current Pool Rates ──────────────

    /**
     *  @return debtRatio The current debt ratio for this shuttle, default at 95%
     */
    function debtRatio() external view returns (uint256);

    /**
     *  @return liquidationIncentive The current liquidation incentive for this shuttle
     */
    function liquidationIncentive() external view returns (uint256);

    /**
     *  @return liquidationFee The current liquidation fee the protocol keeps from each liquidation
     */
    function liquidationFee() external view returns (uint256);

    // ──────────── Min/Max rates allowed ─────────────

    /**
     *  @notice Set a minimum for borrow protection
     *  @return DEBT_RATIO_MIN Minimum debt ratio at which the collateral becomes liquidatable
     */
    function DEBT_RATIO_MIN() external pure returns (uint256);

    /**
     *  @return DEBT_RATIO_MAX Maximum debt ratio at which the collateral becomes liquidatable
     */
    function DEBT_RATIO_MAX() external pure returns (uint256);

    /**
     *  @return LIQUIDATION_INCENTIVE_MIN The minimum liquidation incentive for liquidators that can be set
     */
    function LIQUIDATION_INCENTIVE_MIN() external pure returns (uint256);

    /**
     *  @return LIQUIDATION_INCENTIVE_MAX The maximum liquidation incentive for liquidators that can be set
     */
    function LIQUIDATION_INCENTIVE_MAX() external pure returns (uint256);

    /**
     *  @notice No minimum as the default is 0
     *  @return LIQUIDATION_FEE_MAX Maximum fee the protocol is keeps from each liquidation
     */
    function LIQUIDATION_FEE_MAX() external pure returns (uint256);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            5. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice 👽
     *  @notice Updates the debt ratio for the shuttle
     *  @param  newDebtRatio The new requested point at which a loan is liquidatable
     *  @custom:security non-reentrant
     */
    function setDebtRatio(uint256 newDebtRatio) external;

    /**
     *  @notice 👽
     *  @notice Updates the liquidation incentive for the shuttle
     *  @param  newLiquidationIncentive The new requested profit liquidators keep from the collateral
     *  @custom:security non-reentrant
     */
    function setLiquidationIncentive(uint256 newLiquidationIncentive) external;

    /**
     *  @notice 👽
     *  @notice Updates the fee the protocol keeps for every liquidation
     *  @param newLiquidationFee The new requested fee taken from the liquidation incentive
     *  @custom:security non-reentrant
     */
    function setLiquidationFee(uint256 newLiquidationFee) external;
}


// File contracts/cygnus-periphery/interfaces/core/IMiniChef.sol

// g-Identifier: Unlicensed

pragma solidity >=0.8.4;

interface IMiniChef {
    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function emergencyWithdraw(uint256 _pid) external;

    function pendingTokens(uint256 _pid, address _user)
        external
        view
        returns (
            uint256 pendingJoe,
            address bonusTokenAddress,
            string memory bonusTokenSymbol,
            uint256 pendingBonusToken
        );

    function userInfo(uint256 pid, address user) external view returns (uint256 amount, uint256 rewardDebt);

    function poolInfo(uint256 pid)
        external
        view
        returns (
            address lpToken,
            uint96 allocPoint,
            uint256 accJoePerShare,
            uint256 accJoePerFactorPerShare,
            uint64 lastRewardTimestamp,
            IRewarder rewarder,
            uint32 veJoeShareBp,
            uint256 totalFactor,
            uint256 totalLpSupply
        );
}

interface IRewarder {
    function isNative() external view returns (bool);

    function onJoeReward(address user, uint256 newLpAmount) external;

    function pendingTokens(address user) external view returns (uint256 pending);

    function rewardToken() external view returns (IErc20);
}


// File contracts/cygnus-periphery/interfaces/core/ICygnusCollateralVoid.sol

// g-Identifier: Unlicensed

pragma solidity >=0.8.4;

// Dependencies

// Interfaces



/**
 *  @title ICygnusCollateralVoid The interface for the masterchef
 */
interface ICygnusCollateralVoid is ICygnusCollateralControl {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:error OnlyAccountsAllowed Avoid contracts
     */
    error CygnusCollateralChef__OnlyEOAAllowed(address sender, address origin);

    /**
     *  @custom:error InvalidRewardsToken The rewards token can't be the zero address
     */
    error CygnusCollateralChef__VoidAlreadyInitialized(address tokenReward);

    /**
     *  @custom:error NotNativeTokenSender Avoid receiving unless sender is native token
     */
    error CygnusCollateralVoid__NotNativeTokenSender(address sender, address origin);

    /**
     *  @custom:error RedeemAmountExceedsBalance Avoid redeeming more than pool balance
     */
    error CygnusCollateralVoid__RedeemAmountExceedsBalance(uint256 redeemAmount, uint256 totalBalance);

    /**
     *  @custom:error CantMintZero Avoid redeeming 0 tokens
     */
    error CygnusCollateralVoid__CantMintZero(uint256 mintTokens);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Logs when the chef is initialized and rewards can be reinvested
     *  @param _dexRouter The address of the router that is used by the DEX (must be UniswapV2 compatible)
     *  @param _rewarder The address of the masterchef or rewarder contract (Must be compatible with masterchef)
     *  @param _rewardsToken The address of the token that rewards are paid in
     *  @param _pid The Pool ID of this LP Token pair in Masterchef's contract
     *  @param _swapFeeFactor The swap fee factor used by this DEX
     *  @custom:event Reinvest Emitted when reinvesting rewards from Masterchef
     */
    event ChargeVoid(
        IDexRouter02 _dexRouter,
        IMiniChef _rewarder,
        address _rewardsToken,
        uint256 _pid,
        uint256 _swapFeeFactor
    );

    /**
     *  @notice Logs when rewards are reinvested
     *  @param shuttle The address of this shuttle
     *  @param reinvestor The address of the caller who reinvested reward and receives bounty
     *  @param rewardBalance The amount reinvested
     *  @param reinvestReward The reward received by the reinvestor
     *  @custom:event Reinvest Emitted when reinvesting rewards from Masterchef
     */
    event RechargeVoid(address indexed shuttle, address reinvestor, uint256 rewardBalance, uint256 reinvestReward);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @return REINVEST_REWARD The % of rewards paid to the user who reinvested this shuttle's rewards to buy more LP
     */
    function REINVEST_REWARD() external view returns (uint256);

    /**
     *  @notice Returns this contract's void values (if activated) showing the masterchef address, pool id, etc.
     *  @return rewarder_ The address of the masterchef/rewarder
     *  @return pid_ The pool ID the collateral's underlying LP Token belongs to in the masterchef/rewarder
     *  @return voidActivated_ Whether or not this contract has the void activated
     *  @return rewardsToken_ The address of the rewards token from the Dex
     *  @return dexSwapFee_ The fee the dex charges for swaps (divided by 1000 ie Uniswap charges 0.3%, swap fee is 997)
     *  @return dexRouter_ The address of the dex' router used to swap between tokens
     */
    function getCygnusVoid()
        external
        view
        returns (
            IMiniChef rewarder_,
            uint256 pid_,
            bool voidActivated_,
            address rewardsToken_,
            uint256 dexSwapFee_,
            IDexRouter02 dexRouter_
        );

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Initializes the chef to reinvest rewards
     *  @param _dexRouter The address of the router that is used by the DEX that owns the liquidity pool
     *  @param _rewarder The address of the masterchef or rewarder contract (Must be compatible with masterchef)
     *  @param _rewardsToken The address of the token that rewards are paid in
     *  @param _pid The Pool ID of this LP Token pair in Masterchef's contract
     *  @param _swapFeeFactor The swap fee factor used by this DEX
     *  @custom:security non-reentrant
     */
    function chargeVoid(
        IDexRouter02 _dexRouter,
        IMiniChef _rewarder,
        address _rewardsToken,
        uint256 _pid,
        uint256 _swapFeeFactor
    ) external;

    /**
     *  @notice Reinvests all rewards from the masterchef to buy more LP Tokens to deposit in the masterchef.
     *          This makes totalBalance increase in this contract, increasing the exchangeRate between
     *          CygnusLP and underlying, thus lowering user's debt ratios
     *  @custom:security non-reentrant
     */
    function reinvestRewards_y7b() external;
}


// File contracts/cygnus-periphery/interfaces/core/ICygnusCollateralModel.sol

// g-Identifier: Unlicensed
pragma solidity >=0.8.4;

// Dependencies

/**
 *  @title ICygnusCollateralModel The interface for querying any borrower's positions and find liquidity/shortfalls
 */
interface ICygnusCollateralModel is ICygnusCollateralVoid {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */
    /**
     *  @custom:error PriceTokenBInvalid Emitted when the borrower is the zero address
     */
    error CygnusCollateralModel__BorrowerCantBeAddressZero(address sender, address origin);

    /**
     *  @custom:error BorrowableInvalid Emitted when borrowable is not one of the pool's allowed borrow tokens.
     */
    error CygnusCollateralModel__BorrowableInvalid(address invalidBorrowable, address validBorrowable);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @notice Gets an account's liquidity or shortfall
     *  @param borrower The address of the borrower.
     *  @return liquidity The account's liquidity.
     *  @return shortfall If user has no liquidity, return the shortfall.
     */
    function getAccountLiquidity(address borrower) external returns (uint256 liquidity, uint256 shortfall);

    /**
     *  @notice Calls the oracle to return the price of the underlying LP Token of this shuttle
     *  @return lpTokenPrice The price of 1 LP Token in DAI
     */
    function getLPTokenPrice() external view returns (uint256 lpTokenPrice);

    /**
     *  @notice Whether or not an account can borrow
     *  @param borrower The address of the borrower.
     *  @param borrowableToken The address of the token the user wants to borrow.
     *  @param accountBorrows The amount the user wants to borrow.
     *  @return Whether the account can borrow.
     */
    function canBorrow_J2u(
        address borrower,
        address borrowableToken,
        uint256 accountBorrows
    ) external returns (bool);

    /**
     *  @notice Returns the debt ratio of a borrower, denoted by borrowed DAI / collateral price in DAI
     *  @param borrower The address of the borrower
     *  @return borrowersDebtRatio The debt ratio of the borrower, with max being 1 mantissa
     */
    function getDebtRatio(address borrower) external returns (uint256 borrowersDebtRatio);
}


// File contracts/cygnus-periphery/interfaces/core/ICygnusCollateral.sol

// g-Identifier: Unlicensed
pragma solidity >=0.8.4;

// dependencies

/**
 *  @title ICygnusCollateral Interface for the main collateral contract which handles collateral seizes
 */
interface ICygnusCollateral is ICygnusCollateralModel {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:error InsufficientLiquidity Emitted when the user doesn't have enough liquidity for a transfer.
     */
    error CygnusCollateral__InsufficientLiquidity(address from, address to, uint256 value);

    /**
     *  @custom:error LiquiditingSelf Emitted when liquidator is borrower
     */
    error CygnusCollateral__CantLiquidateSelf(address borrower, address liquidator);

    /**
     *  @custom:error MsgSenderNotCygnusDai Emitted for liquidation when msg.sender is not borrowable.
     */
    error CygnusCollateral__MsgSenderNotCygnusDai(address sender, address borrowable);

    /**
     *  @custom:error CantLiquidateZero Emitted when the repayAmount is 0
     */
    error CygnusCollateral__CantLiquidateZero();

    /**
     *  @custom:error NotLiquidatable Emitted when there is no shortfall
     */
    error CygnusCollateral__NotLiquidatable(uint256 userLiquidity, uint256 userShortfall);

    /**
     *  @custom:error CantRedeemZero Emitted when trying to redeem 0 tokens
     */
    error CygnusCollateral__CantRedeemZero();

    /**
     *  @custom:error RedeemAmountInvalid Emitted when redeeming more than pool's totalBalance
     */
    error CygnusCollateral__RedeemAmountInvalid(uint256 redeemAmount, uint256 totalBalance);

    /**
     *  @custom:error InsufficientRedeemAmount Emitted when redeeming more than user balance of redeem Tokens
     */
    error CygnusCollateral__InsufficientRedeemAmount(uint256 cygLPTokens, uint256 redeemableAmount);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @param sender is address of msg.sender
     *  @param redeemer is address of redeemer
     *  @param redeemAmount is redeemed ammount
     *  @param redeemTokens is the balance of
     *  @custom:event Emitted when collateral is safely redeemed
     */
    event RedeemCollateral(address sender, address redeemer, uint256 redeemAmount, uint256 redeemTokens);

    /**
     *  @param borrower The address of redeemer
     *  @param liquidator The address of the liquidator
     *  @param cygLPAmount The amount being seized is the balance of
     *  @param cygnusFee The protocol fee (if any)
     *  @custom:event Emitted when collateral is seized
     */
    event SeizeCollateral(address borrower, address liquidator, uint256 cygLPAmount, uint256 cygnusFee);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @param from The address of the borrower
     *  @param value The amount to redeem
     *  @return Whether the user `from` can redeem - if user has shortfall, debt must be repaid first
     */
    function canRedeem(address from, uint256 value) external returns (bool);

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice Updates balances of liquidator and borrower, should only be called by borrowable's liquidate function
     *  @param liquidator The address repaying the borrow and seizing the collateral
     *  @param borrower The address of the borrower
     *  @param repayAmount The number of collateral tokens to seize
     */
    function seizeCygLP(
        address liquidator,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256 cygLPAmount);

    /**
     *  @dev This should be called from `Altair` contract
     *  @param redeemer The address redeeming the tokens (Altair contract)
     *  @param redeemAmount The amount of the underlying asset being redeemed
     *  @param data Calldata passed from router contract
     *  @custom:security non-reentrant
     */
    function flashRedeemAltair(
        address redeemer,
        uint256 redeemAmount,
        bytes calldata data
    ) external;
}


// File contracts/cygnus-periphery/interfaces/core/IWAVAX.sol

// g-Identifier: Unlicensed
pragma solidity >=0.8.4;

// Interface for interfacting with Wrapped Avax (0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7)
interface IWAVAX {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function totalSupply() external view returns (uint256);

    function transfer(address dst, uint256 wad) external returns (bool);

    function balanceOf(address owner) external view returns (uint256);

    function approve(address to, uint256 value) external returns (bool);
}


// File contracts/cygnus-periphery/interfaces/core/IDenebOrbiter.sol

// g-Identifier: Unlicensed
pragma solidity >=0.8.4;

/**
 *  @title ICygnusDeneb The interface for a contract that is capable of deploying Cygnus collateral pools
 *  @notice A contract that constructs a Cygnus collateral pool must implement this to pass arguments to the pool
 */
interface IDenebOrbiter {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Passing the struct parameters to the collateral contract avoids setting constructor
     *  @return factory The address of the Cygnus factory
     *  @return underlying The address of the underlying LP Token
     *  @return cygnusDai The address of the Cygnus borrow contract for this collateral
     */
    function collateralParameters()
        external
        returns (
            address factory,
            address underlying,
            address cygnusDai
        );

    /**
     *  @return COLLATERAL_INIT_CODE_HASH The init code hash of the collateral contract for this deployer
     */
    function COLLATERAL_INIT_CODE_HASH() external view returns (bytes32);

    /**
     *  @notice Function to deploy the collateral contract of a lending pool
     *  @param underlying The address of the underlying LP Token
     *  @param cygnusDai The address of the Cygnus borrow contract for this collateral
     *  @return collateral The address of the new deployed Cygnus collateral contract
     */
    function deployDeneb(address underlying, address cygnusDai) external returns (address collateral);
}


// File contracts/cygnus-periphery/interfaces/core/IAlbireoOrbiter.sol

// g-Identifier: Unlicensed
pragma solidity >=0.8.4;

/**
 *  @title ICygnusAlbireo The interface the Cygnus borrow deployer
 *  @notice A contract that constructs a Cygnus borrow pool must implement this to pass arguments to the pool
 */
interface IAlbireoOrbiter {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Passing the struct parameters to the borrow contracts avoids setting constructor parameters
     *  @return factory The address of the Cygnus factory assigned to `Hangar18`
     *  @return underlying The address of the underlying borrow token (address of DAI, USDc, etc.)
     *  @return collateral The address of the Cygnus collateral contract for this borrow contract
     *  @return baseRatePerYear The base rate per year for this shuttle
     *  @return multiplier The multiplier per year
     *  @return kinkMultiplier The increase to the multiplier once kink utilization is reached
     */
    function borrowParameters()
        external
        returns (
            address factory,
            address underlying,
            address collateral,
            uint256 baseRatePerYear,
            uint256 multiplier,
            uint256 kinkMultiplier
        );

    /**
     *  @return BORROW_INIT_CODE_HASH The init code hash of the borrow contract for this deployer
     */
    function BORROW_INIT_CODE_HASH() external view returns (bytes32);

    /**
     *  @notice Function to deploy the borrow contract of a lending pool
     *  @param underlying The address of the underlying borrow token (address of DAI, USDc, etc.)
     *  @param collateral The address of the Cygnus collateral contract for this borrow contract
     *  @param baseRatePerYear The base rate per year for this shuttle
     *  @param multiplier The farm APY for this LP Token
     *  @param kinkMultiplier The increase to farmApy once kink utilization is reached
     *  @return cygnusDai The address of the new borrow contract
     */
    function deployAlbireo(
        address underlying,
        address collateral,
        uint256 baseRatePerYear,
        uint256 multiplier,
        uint256 kinkMultiplier
    ) external returns (address cygnusDai);
}


// File contracts/cygnus-periphery/interfaces/core/ICygnusFactory.sol

// g-Identifier: Unlicensed
pragma solidity >=0.8.4;

// Orbiters


// Oracles

/**
 *  @title The interface for the Cygnus Factory
 *  @notice The Cygnus factory facilitates creation of collateral and borrow pools
 */
interface ICygnusFactory {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:error CygnusAdminOnly Emitted when caller is not Admin
     */
    error CygnusFactory__CygnusAdminOnly(address sender, address admin);

    /**
     *  @custom:error OrbiterAlreadySet Emitted when the borrow orbiter already exists
     */
    error CygnusFactory__OrbiterAlreadySet(Orbiter orbiter);

    /**
     *  @custom:error ShuttleAlreadyDeployed Emitted when trying to deploy a shuttle that already exists
     */
    error CygnusFactory__ShuttleAlreadyDeployed(uint24 id, address lpTokenPair);

    /**
     *  @custom:error OrbitersAreInactive Emitted when deploying a shuttle with orbiters that are inactive or dont exist
     */
    error CygnusFactory__OrbitersAreInactive(Orbiter orbiter);

    /**
     *  @custom:error CollateralAddressMismatch Emitted when predicted collateral address doesn't match with deployed
     */
    error CygnusFactory__CollateralAddressMismatch(address calculatedCollateral, address deployedCollateral);

    /**
     *  @custom:error LPTokenPairNotSupported Emitted when trying to deploy a shuttle with an unsupported LP Pair
     */
    error CygnusFactory__LPTokenPairNotSupported(address lpTokenPair);

    /**
     *  @custom:error OrbitersNotSet Emitted when attempting to switch off orbiters that don't exist
     */
    error CygnusFactory__OrbitersNotSet(uint256 orbiterId);

    /**
     *  @custom:error CygnusNebulaCantBeZero Emitted when the new oracle is the zero address
     */
    error CygnusFactory__CygnusNebulaCantBeZero();

    /**
     *  @custom:error CygnusNebulaAlreadySet Emitted when the oracle set is the same as the new one we are assigning
     */
    error CygnusFactory__CygnusNebulaAlreadySet(address priceOracle, address newPriceOracle);

    /**
     *  @custom:error AdminAlreadySet Emitted when the admin is the same as the new one we are assigning
     */
    error CygnusFactory__AdminAlreadySet(address newPendingAdmin, address admin);

    /**
     *  @custom:error PendingAdminAlreadySet Emitted when the pending admin is the same as the new one we are assigning
     */
    error CygnusFactory__PendingAdminAlreadySet(address newPendingAdmin, address pendingAdmin);

    /**
     *  @custom:error DaoReservesAlreadySet Emitted when the pending dao reserves is already the dao reserves
     */
    error CygnusFactory__DaoReservesAlreadySet(address newPendingDaoReserves, address daoReserves);

    /**
     *  @custom:error PendingCygnusAdmin Emitted when pending Cygnus admin is the zero address
     */
    error CygnusFactory__PendingAdminCantBeZero();

    /**
     *  @custom:error DaoReservesCantBeZero Emitted when pending reserves contract address is the zero address
     */
    error CygnusFactory__DaoReservesCantBeZero();

    /**
     *  @custom:error PendingDaoReservesAlreadySet Emitted when the pending address is the same as the new pending
     */
    error CygnusFactory__PendingDaoReservesAlreadySet(address newPendingDaoReserves, address pendingDaoReserves);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Logs when a new Cygnus oracle is set
     *  @param oldCygnusNebula Address of the old price oracle
     *  @param newCygnusNebula Address of the new confirmed price oracle
     *  @custom:event Emitted when a new price oracle is set
     */
    event NewCygnusNebulaOracle(IChainlinkNebulaOracle oldCygnusNebula, IChainlinkNebulaOracle newCygnusNebula);

    /**
     *  @notice Logs when a new shuttle is launched
     *  @param shuttleId The ID of this lending pool
     *  @param cygnusDai The address of the Cygnus borrow contract
     *  @param collateral The address of the Cygnus collateral contract
     *  @param dai The address of underlying borrow token (DAI)
     *  @param lpTokenPair The address of the underlying LP Token
     *  @custom:event Emitted when a new lending pool is launched
     */
    event NewShuttleLaunched(
        uint256 indexed shuttleId,
        address cygnusDai,
        address collateral,
        address dai,
        address lpTokenPair
    );

    /**
     *  @notice Logs when a new pending admin is set
     *  @param pendingAdmin Address of the requested admin
     *  @param _admin Address of the present admin
     *  @custom:event Emitted when a new Cygnus admin is requested
     */
    event PendingCygnusAdmin(address pendingAdmin, address _admin);

    /**
     *  @notice Logs when a new cygnus admin is set
     *  @param oldAdmin Address of the old admin
     *  @param newAdmin Address of the new confirmed admin
     *  @custom:event Emitted when a new Cygnus admin is confirmed
     */
    event NewCygnusAdmin(address oldAdmin, address newAdmin);

    /**
     *  @notice Logs when a new pending dao reserves contract is set
     *  @param oldPendingdaoReservesContract Address of the current `daoReserves` contract
     *  @param newPendingdaoReservesContract Address of the requested new `daoReserves` contract
     *  @custom:event Emitted when a new implementation contract is requested
     */
    event PendingDaoReserves(address oldPendingdaoReservesContract, address newPendingdaoReservesContract);

    /**
     *  @notice Logs when a new dao reserves contract is set for Cygnus
     *  @param oldDaoReserves Address of old `daoReserves` contract
     *  @param daoReserves Address of the new confirmed `daoReserves` contract
     *  @custom:event Emitted when a new implementation contract is confirmed
     */
    event NewDaoReserves(address oldDaoReserves, address daoReserves);

    /**
     *  @notice Logs when new orbiters are added to the factory.
     *  @param status Whether or not these orbiters are active and usable
     *  @param orbitersLength How many orbiter pairs we have (equals the amount of Dexes cygnus is using)
     *  @param orbitersName The name of the dex for these orbiters
     *  @param collateralOrbiter The address of the collateral orbiter for this dex
     *  @param borrowOrbiter The address of the borrow orbiter for this dex
     *
     */
    event InitializeOrbiters(
        bool status,
        uint256 orbitersLength,
        string orbitersName,
        IDenebOrbiter collateralOrbiter,
        IAlbireoOrbiter borrowOrbiter
    );

    /**
     *  @notice Logs when orbiters get deleted from storage
     *  @param status Bool representing whether or not these orbiters are usable
     *  @param orbiterId The ID of the collateral & borrow orbiters
     *  @param orbiterName The name of the dex these orbiters were for
     *  @param cygnusDeneb The address of the deleted collateral orbiter
     *  @param cygnusAlbireo The address of the deleted borrow orbiter
     */
    event SwitchOrbiterStatus(
        bool status,
        uint256 orbiterId,
        string orbiterName,
        IAlbireoOrbiter cygnusAlbireo,
        IDenebOrbiter cygnusDeneb
    );

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Internal ───────────────────────────────────────────────  */

    /**
     *  @notice We write it to interface due to getShuttles return value
     *  @custom:struct Official record of all collateral and borrow deployer contracts, unique per dex
     *  @custom:member status Whether or not these orbiters are active and usable
     *  @custom:member orbiterId The ID for this pair of orbiters
     *  @custom:member orbiterName The name of the dex
     *  @custom:member cygnusDeneb The address of the collateral deployer contract
     *  @custom:member cygnusAlbireo The address of the borrow deployer contract
     */
    struct Orbiter {
        bool status;
        uint24 orbiterId;
        string orbiterName;
        IAlbireoOrbiter cygnusAlbireo;
        IDenebOrbiter cygnusDeneb;
    }

    /**
     *  @custom:struct Shuttle Official record of pools deployed by this factory
     *  @custom:member launched Whether or not the lending pool is initialized
     *  @custom:member shuttleId The ID of the lending pool
     *  @custom:member collateral The address of the Cygnus collateral
     *  @custom:member cygnusDai The address of the borrowing contract
     *  @custom:member underlyingCollateral The address of the underlying collateral (LP Token)
     *  @custom:member dai The address of the underlying albireo contract (DAI)
     */
    struct Shuttle {
        bool launched;
        uint24 shuttleId;
        address cygnusDai;
        address collateral;
        address borrowToken;
        address lpTokenPair;
        Orbiter orbiter;
    }

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @notice Official record of all obiters deployed
     *  @param _orbiterId The ID of the orbiter deployed
     *  @return status Whether or not these orbiters are active and usable
     *  @return orbiterId The ID for these orbiters (ideally should be 1 per dex)
     *  @return orbiterName The name of the dex
     *  @return cygnusAlbireo The address of the borrow deployer contract
     *  @return cygnusDeneb The address of the collateral deployer contract
     */
    function getOrbiters(uint256 _orbiterId)
        external
        view
        returns (
            bool status,
            uint24 orbiterId,
            string memory orbiterName,
            IAlbireoOrbiter cygnusAlbireo,
            IDenebOrbiter cygnusDeneb
        );

    /**
     *  @notice Array of structs containing all orbiters deployed
     *  @param _orbiterId The ID of the orbiter pair
     */
    function allOrbiters(uint256 _orbiterId)
        external
        view
        returns (
            bool active,
            uint24 orbiterId,
            string memory orbiterName,
            IAlbireoOrbiter cygnusAlbireo,
            IDenebOrbiter cygnusDeneb
        );

    /**
     *  @notice Official record of all lending pools deployed
     *  @param _lpTokenPair The address of the LP Token
     *  @param _orbiterId The ID of the orbiter for this LP Token
     *  @return launched Whether this pair exists or not
     *  @return shuttleId The ID of this shuttle
     *  @return cygnusDai The address of the borrow contract
     *  @return collateral The address of the collateral contract
     *  @return borrowToken The address of the underlying borrow contract
     *  @return lpTokenPair The address of the collaterla's
     *  @return orbiter The struct containing the address of the collateral/borrow orbiters for each dex
     */
    function getShuttles(address _lpTokenPair, uint256 _orbiterId)
        external
        view
        returns (
            bool launched,
            uint24 shuttleId,
            address cygnusDai,
            address collateral,
            address borrowToken,
            address lpTokenPair,
            Orbiter memory orbiter
        );

    /**
     *  @notice Array of structs containing all shuttles deployed along with their orbiters
     *  @param _shuttleId The ID of the shuttle deployed
     */
    function allShuttles(uint256 _shuttleId)
        external
        view
        returns (
            bool launched,
            uint24 shuttleId,
            address cygnusDai,
            address collateral,
            address borrowToken,
            address lpTokenPair,
            Orbiter memory orbiter
        );

    /**
     *  @return admin The address of the Cygnus Admin which grants special permissions in collateral/borrow contracts
     */
    function admin() external view returns (address);

    /**
     *  @return pendingAdmin The address of the requested account to be the new Cygnus Admin
     */
    function pendingAdmin() external view returns (address);

    /**
     *  @return daoReserves The address that handles Cygnus reserves from all pools
     */
    function daoReserves() external view returns (address);

    /**
     *  @return pendingDaoReserves The address of the requested contract to be the new dao reserves
     */
    function pendingDaoReserves() external view returns (address);

    /**
     * @return cygnusNebulaOracle The address of the Cygnus price oracle
     */
    function cygnusNebulaOracle() external view returns (IChainlinkNebulaOracle);

    /**
     *  @return orbitersDeployed The total number of orbiter pairs deployed (1 collateral + 1 borrow = 1 orbiter)
     */
    function orbitersDeployed() external view returns (uint256);

    /**
     *  @return shuttlesDeployed The total number of shuttles deployed
     */
    function shuttlesDeployed() external view returns (uint256);

    /**
     *  @return dai The address of DAI
     */
    function dai() external view returns (address);

    /**
     *  @return nativeToken The address of the chain's native token
     */
    function nativeToken() external view returns (address);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice Turns off orbiters making them not able for deployment of pools
     *  @param orbiterId The ID of the orbiter pairs we want to switch the status of
     *  @custom:security non-reentrant
     */
    function switchOrbiterStatus(uint256 orbiterId) external;

    /**
     *  @notice Initializes both Borrow arms and the collateral arm
     *  @param lpTokenPair The address of the underlying LP Token this pool is for
     *  @param orbiterId The ID of the orbiters we want to deploy to (= dex Id)
     *  @param baseRate The interest rate model's base rate this shuttle uses
     *  @param multiplier The multiplier this shuttle uses for calculating the interest rate
     *  @param kinkMultiplier The increase to farmApy once kink utilization is reached
     *  @return cygnusDai The address of the Cygnus borrow contract for this pool
     *  @return collateral The address of the Cygnus collateral contract for both borrow tokens
     *  @custom:security non-reentrant
     */
    function deployShuttle(
        address lpTokenPair,
        uint256 orbiterId,
        uint256 baseRate,
        uint256 multiplier,
        uint256 kinkMultiplier
    ) external returns (address cygnusDai, address collateral);

    /**
     *  @notice Sets the new orbiters to deploy collateral and borrow contracts and stores orbiters in storage
     *  @param name The name of the strategy OR the dex these orbiters are for
     *  @param cygnusAlbireo the address of this orbiter's borrow deployer
     *  @param cygnusDeneb The address of this orbiter's collateral deployer
     *  @custom:security non-reentrant
     */
    function initializeOrbiter(
        string memory name,
        IAlbireoOrbiter cygnusAlbireo,
        IDenebOrbiter cygnusDeneb
    ) external;

    /**
     *  @notice 👽
     *  @notice Sets a new price oracle
     *  @param newpriceoracle address of the new price oracle
     */
    function setNewNebulaOracle(address newpriceoracle) external;

    /**
     *  @notice 👽
     *  @notice Sets a new pending admin for Cygnus
     *  @param newCygnusAdmin Address of the requested Cygnus admin
     */
    function setPendingAdmin(address newCygnusAdmin) external;

    /**
     *  @notice 👽
     *  @notice Approves the pending admin and is the new Cygnus admin
     */
    function setNewCygnusAdmin() external;

    /**
     *  @notice 👽
     *  @notice Sets the address for the future reserves manger if accepted
     *  @param newDaoReserves The address of the requested contract to be the new daoReserves
     */
    function setPendingDaoReserves(address newDaoReserves) external;

    /**
     *  @notice 👽
     *  @notice Accepts the new implementation contract
     */
    function setNewDaoReserves() external;
}


// File contracts/cygnus-periphery/libraries/PRBMath.sol

// g-Identifier: Unlicense
pragma solidity >=0.8.4;

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivFixedPointOverflow(uint256 prod1);
/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivOverflow(uint256 prod1, uint256 denominator);

/// @notice Emitted when one of the inputs is type(int256).min.
error PRBMath__MulDivSignedInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows int256.
error PRBMath__MulDivSignedOverflow(uint256 rAbs);

/// @notice Emitted when the input is MIN_SD59x18.
error PRBMathSD59x18__AbsInputTooSmall();

/// @notice Emitted when ceiling a number overflows SD59x18.
error PRBMathSD59x18__CeilOverflow(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__DivInputTooSmall();

/// @notice Emitted when one of the intermediary unsigned results overflows SD59x18.
error PRBMathSD59x18__DivOverflow(uint256 rAbs);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathSD59x18__ExpInputTooBig(int256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathSD59x18__Exp2InputTooBig(int256 x);

/// @notice Emitted when flooring a number underflows SD59x18.
error PRBMathSD59x18__FloorUnderflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format overflows SD59x18.
error PRBMathSD59x18__FromIntOverflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format underflows SD59x18.
error PRBMathSD59x18__FromIntUnderflow(int256 x);

/// @notice Emitted when the product of the inputs is negative.
error PRBMathSD59x18__GmNegativeProduct(int256 x, int256 y);

/// @notice Emitted when multiplying the inputs overflows SD59x18.
error PRBMathSD59x18__GmOverflow(int256 x, int256 y);

/// @notice Emitted when the input is less than or equal to zero.
error PRBMathSD59x18__LogInputTooSmall(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__MulInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__MulOverflow(uint256 rAbs);

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__PowuOverflow(uint256 rAbs);

/// @notice Emitted when the input is negative.
error PRBMathSD59x18__SqrtNegativeInput(int256 x);

/// @notice Emitted when the calculating the square root overflows SD59x18.
error PRBMathSD59x18__SqrtOverflow(int256 x);

/// @notice Emitted when addition overflows UD60x18.
error PRBMathUD60x18__AddOverflow(uint256 x, uint256 y);

/// @notice Emitted when ceiling a number overflows UD60x18.
error PRBMathUD60x18__CeilOverflow(uint256 x);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathUD60x18__ExpInputTooBig(uint256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathUD60x18__Exp2InputTooBig(uint256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format format overflows UD60x18.
error PRBMathUD60x18__FromUintOverflow(uint256 x);

/// @notice Emitted when multiplying the inputs overflows UD60x18.
error PRBMathUD60x18__GmOverflow(uint256 x, uint256 y);

/// @notice Emitted when the input is less than 1.
error PRBMathUD60x18__LogInputTooSmall(uint256 x);

/// @notice Emitted when the calculating the square root overflows UD60x18.
error PRBMathUD60x18__SqrtOverflow(uint256 x);

/// @notice Emitted when subtraction underflows UD60x18.
error PRBMathUD60x18__SubUnderflow(uint256 x, uint256 y);

/// @dev Common mathematical functions used in both PRBMathSD59x18 and PRBMathUD60x18. Note that this shared library
/// does not always assume the signed 59.18-decimal fixed-point or the unsigned 60.18-decimal fixed-point
/// representation. When it does not, it is explicitly mentioned in the NatSpec documentation.
library PRBMath {
    /// STRUCTS ///

    struct SD59x18 {
        int256 value;
    }

    struct UD60x18 {
        uint256 value;
    }

    /// STORAGE ///

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @dev Largest power of two divisor of SCALE.
    uint256 internal constant SCALE_LPOTD = 262144;

    /// @dev SCALE inverted mod 2^256.
    uint256 internal constant SCALE_INVERSE =
        78156646155174841979727994598816262306175212592076161876661_508869554232690281;

    /// FUNCTIONS ///

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    /// @dev Has to use 192.64-bit fixed-point numbers.
    /// See https://ethereum.stackexchange.com/a/96594/24693.
    /// @param x The exponent as an unsigned 192.64-bit fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // Start from 0.5 in the 192.64-bit fixed-point format.
            result = 0x800000000000000000000000000000000000000000000000;

            // Multiply the result by root(2, 2^-i) when the bit at position i is 1. None of the intermediary results overflows
            // because the initial result is 2^191 and all magic factors are less than 2^65.
            if (x & 0x8000000000000000 > 0) {
                result = (result * 0x16A09E667F3BCC909) >> 64;
            }
            if (x & 0x4000000000000000 > 0) {
                result = (result * 0x1306FE0A31B7152DF) >> 64;
            }
            if (x & 0x2000000000000000 > 0) {
                result = (result * 0x1172B83C7D517ADCE) >> 64;
            }
            if (x & 0x1000000000000000 > 0) {
                result = (result * 0x10B5586CF9890F62A) >> 64;
            }
            if (x & 0x800000000000000 > 0) {
                result = (result * 0x1059B0D31585743AE) >> 64;
            }
            if (x & 0x400000000000000 > 0) {
                result = (result * 0x102C9A3E778060EE7) >> 64;
            }
            if (x & 0x200000000000000 > 0) {
                result = (result * 0x10163DA9FB33356D8) >> 64;
            }
            if (x & 0x100000000000000 > 0) {
                result = (result * 0x100B1AFA5ABCBED61) >> 64;
            }
            if (x & 0x80000000000000 > 0) {
                result = (result * 0x10058C86DA1C09EA2) >> 64;
            }
            if (x & 0x40000000000000 > 0) {
                result = (result * 0x1002C605E2E8CEC50) >> 64;
            }
            if (x & 0x20000000000000 > 0) {
                result = (result * 0x100162F3904051FA1) >> 64;
            }
            if (x & 0x10000000000000 > 0) {
                result = (result * 0x1000B175EFFDC76BA) >> 64;
            }
            if (x & 0x8000000000000 > 0) {
                result = (result * 0x100058BA01FB9F96D) >> 64;
            }
            if (x & 0x4000000000000 > 0) {
                result = (result * 0x10002C5CC37DA9492) >> 64;
            }
            if (x & 0x2000000000000 > 0) {
                result = (result * 0x1000162E525EE0547) >> 64;
            }
            if (x & 0x1000000000000 > 0) {
                result = (result * 0x10000B17255775C04) >> 64;
            }
            if (x & 0x800000000000 > 0) {
                result = (result * 0x1000058B91B5BC9AE) >> 64;
            }
            if (x & 0x400000000000 > 0) {
                result = (result * 0x100002C5C89D5EC6D) >> 64;
            }
            if (x & 0x200000000000 > 0) {
                result = (result * 0x10000162E43F4F831) >> 64;
            }
            if (x & 0x100000000000 > 0) {
                result = (result * 0x100000B1721BCFC9A) >> 64;
            }
            if (x & 0x80000000000 > 0) {
                result = (result * 0x10000058B90CF1E6E) >> 64;
            }
            if (x & 0x40000000000 > 0) {
                result = (result * 0x1000002C5C863B73F) >> 64;
            }
            if (x & 0x20000000000 > 0) {
                result = (result * 0x100000162E430E5A2) >> 64;
            }
            if (x & 0x10000000000 > 0) {
                result = (result * 0x1000000B172183551) >> 64;
            }
            if (x & 0x8000000000 > 0) {
                result = (result * 0x100000058B90C0B49) >> 64;
            }
            if (x & 0x4000000000 > 0) {
                result = (result * 0x10000002C5C8601CC) >> 64;
            }
            if (x & 0x2000000000 > 0) {
                result = (result * 0x1000000162E42FFF0) >> 64;
            }
            if (x & 0x1000000000 > 0) {
                result = (result * 0x10000000B17217FBB) >> 64;
            }
            if (x & 0x800000000 > 0) {
                result = (result * 0x1000000058B90BFCE) >> 64;
            }
            if (x & 0x400000000 > 0) {
                result = (result * 0x100000002C5C85FE3) >> 64;
            }
            if (x & 0x200000000 > 0) {
                result = (result * 0x10000000162E42FF1) >> 64;
            }
            if (x & 0x100000000 > 0) {
                result = (result * 0x100000000B17217F8) >> 64;
            }
            if (x & 0x80000000 > 0) {
                result = (result * 0x10000000058B90BFC) >> 64;
            }
            if (x & 0x40000000 > 0) {
                result = (result * 0x1000000002C5C85FE) >> 64;
            }
            if (x & 0x20000000 > 0) {
                result = (result * 0x100000000162E42FF) >> 64;
            }
            if (x & 0x10000000 > 0) {
                result = (result * 0x1000000000B17217F) >> 64;
            }
            if (x & 0x8000000 > 0) {
                result = (result * 0x100000000058B90C0) >> 64;
            }
            if (x & 0x4000000 > 0) {
                result = (result * 0x10000000002C5C860) >> 64;
            }
            if (x & 0x2000000 > 0) {
                result = (result * 0x1000000000162E430) >> 64;
            }
            if (x & 0x1000000 > 0) {
                result = (result * 0x10000000000B17218) >> 64;
            }
            if (x & 0x800000 > 0) {
                result = (result * 0x1000000000058B90C) >> 64;
            }
            if (x & 0x400000 > 0) {
                result = (result * 0x100000000002C5C86) >> 64;
            }
            if (x & 0x200000 > 0) {
                result = (result * 0x10000000000162E43) >> 64;
            }
            if (x & 0x100000 > 0) {
                result = (result * 0x100000000000B1721) >> 64;
            }
            if (x & 0x80000 > 0) {
                result = (result * 0x10000000000058B91) >> 64;
            }
            if (x & 0x40000 > 0) {
                result = (result * 0x1000000000002C5C8) >> 64;
            }
            if (x & 0x20000 > 0) {
                result = (result * 0x100000000000162E4) >> 64;
            }
            if (x & 0x10000 > 0) {
                result = (result * 0x1000000000000B172) >> 64;
            }
            if (x & 0x8000 > 0) {
                result = (result * 0x100000000000058B9) >> 64;
            }
            if (x & 0x4000 > 0) {
                result = (result * 0x10000000000002C5D) >> 64;
            }
            if (x & 0x2000 > 0) {
                result = (result * 0x1000000000000162E) >> 64;
            }
            if (x & 0x1000 > 0) {
                result = (result * 0x10000000000000B17) >> 64;
            }
            if (x & 0x800 > 0) {
                result = (result * 0x1000000000000058C) >> 64;
            }
            if (x & 0x400 > 0) {
                result = (result * 0x100000000000002C6) >> 64;
            }
            if (x & 0x200 > 0) {
                result = (result * 0x10000000000000163) >> 64;
            }
            if (x & 0x100 > 0) {
                result = (result * 0x100000000000000B1) >> 64;
            }
            if (x & 0x80 > 0) {
                result = (result * 0x10000000000000059) >> 64;
            }
            if (x & 0x40 > 0) {
                result = (result * 0x1000000000000002C) >> 64;
            }
            if (x & 0x20 > 0) {
                result = (result * 0x10000000000000016) >> 64;
            }
            if (x & 0x10 > 0) {
                result = (result * 0x1000000000000000B) >> 64;
            }
            if (x & 0x8 > 0) {
                result = (result * 0x10000000000000006) >> 64;
            }
            if (x & 0x4 > 0) {
                result = (result * 0x10000000000000003) >> 64;
            }
            if (x & 0x2 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }
            if (x & 0x1 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }

            // We're doing two things at the same time:
            //
            //   1. Multiply the result by 2^n + 1, where "2^n" is the integer part and the one is added to account for
            //      the fact that we initially set the result to 0.5. This is accomplished by subtracting from 191
            //      rather than 192.
            //   2. Convert the result to the unsigned 60.18-decimal fixed-point format.
            //
            // This works because 2^(191-ip) = 2^ip / 2^191, where "ip" is the integer part "2^n".
            result *= SCALE;
            result >>= (191 - (x >> 64));
        }
    }

    /// @notice Finds the zero-based index of the first one in the binary representation of x.
    /// @dev See the note on msb in the "Find First Set" Wikipedia article https://en.wikipedia.org/wiki/Find_first_set
    /// @param x The uint256 number for which to find the index of the most significant bit.
    /// @return msb The index of the most significant bit as an uint256.
    function mostSignificantBit(uint256 x) internal pure returns (uint256 msb) {
        if (x >= 2**128) {
            x >>= 128;
            msb += 128;
        }
        if (x >= 2**64) {
            x >>= 64;
            msb += 64;
        }
        if (x >= 2**32) {
            x >>= 32;
            msb += 32;
        }
        if (x >= 2**16) {
            x >>= 16;
            msb += 16;
        }
        if (x >= 2**8) {
            x >>= 8;
            msb += 8;
        }
        if (x >= 2**4) {
            x >>= 4;
            msb += 4;
        }
        if (x >= 2**2) {
            x >>= 2;
            msb += 2;
        }
        if (x >= 2**1) {
            // No need to shift x any more.
            msb += 1;
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The multiplicand as an uint256.
    /// @param y The multiplier as an uint256.
    /// @param denominator The divisor as an uint256.
    /// @return result The result as an uint256.
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
        // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2^256 + prod0.
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division.
        if (prod1 == 0) {
            unchecked {
                result = prod0 / denominator;
            }
            return result;
        }

        // Make sure the result is less than 2^256. Also prevents denominator == 0.
        if (prod1 >= denominator) {
            revert PRBMath__MulDivOverflow(prod1, denominator);
        }

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0].
        uint256 remainder;
        assembly {
            // Compute remainder using mulmod.
            remainder := mulmod(x, y, denominator)

            // Subtract 256 bit number from 512 bit number.
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
        // See https://cs.stackexchange.com/q/138556/92363.
        unchecked {
            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 lpotdod = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by lpotdod.
                denominator := div(denominator, lpotdod)

                // Divide [prod1 prod0] by lpotdod.
                prod0 := div(prod0, lpotdod)

                // Flip lpotdod such that it is 2^256 / lpotdod. If lpotdod is zero, then it becomes one.
                lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * lpotdod;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /// @notice Calculates floor(x*y÷1e18) with full precision.
    ///
    /// @dev Variant of "mulDiv" with constant folding, i.e. in which the denominator is always 1e18. Before returning the
    /// final result, we add 1 if (x * y) % SCALE >= HALF_SCALE. Without this, 6.6e-19 would be truncated to 0 instead of
    /// being rounded to 1e-18.  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717.
    ///
    /// Requirements:
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMath.mulDiv" to understand how this works.
    /// - It is assumed that the result can never be type(uint256).max when x and y solve the following two equations:
    ///     1. x * y = type(uint256).max * SCALE
    ///     2. (x * y) % SCALE >= SCALE / 2
    ///
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function mulDivFixedPoint(uint256 x, uint256 y) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 >= SCALE) {
            revert PRBMath__MulDivFixedPointOverflow(prod1);
        }

        uint256 remainder;
        uint256 roundUpUnit;
        assembly {
            remainder := mulmod(x, y, SCALE)
            roundUpUnit := gt(remainder, 499999999999999999)
        }

        if (prod1 == 0) {
            unchecked {
                result = (prod0 / SCALE) + roundUpUnit;
                return result;
            }
        }

        assembly {
            result := add(
                mul(
                    or(
                        div(sub(prod0, remainder), SCALE_LPOTD),
                        mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, SCALE_LPOTD), SCALE_LPOTD), 1))
                    ),
                    SCALE_INVERSE
                ),
                roundUpUnit
            )
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev An extension of "mulDiv" for signed numbers. Works by computing the signs and the absolute values separately.
    ///
    /// Requirements:
    /// - None of the inputs can be type(int256).min.
    /// - The result must fit within int256.
    ///
    /// @param x The multiplicand as an int256.
    /// @param y The multiplier as an int256.
    /// @param denominator The divisor as an int256.
    /// @return result The result as an int256.
    function mulDivSigned(
        int256 x,
        int256 y,
        int256 denominator
    ) internal pure returns (int256 result) {
        if (x == type(int256).min || y == type(int256).min || denominator == type(int256).min) {
            revert PRBMath__MulDivSignedInputTooSmall();
        }

        // Get hold of the absolute values of x, y and the denominator.
        uint256 ax;
        uint256 ay;
        uint256 ad;
        unchecked {
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);
            ad = denominator < 0 ? uint256(-denominator) : uint256(denominator);
        }

        // Compute the absolute value of (x*y)÷denominator. The result must fit within int256.
        uint256 rAbs = mulDiv(ax, ay, ad);
        if (rAbs > uint256(type(int256).max)) {
            revert PRBMath__MulDivSignedOverflow(rAbs);
        }

        // Get the signs of x, y and the denominator.
        uint256 sx;
        uint256 sy;
        uint256 sd;
        assembly {
            sx := sgt(x, sub(0, 1))
            sy := sgt(y, sub(0, 1))
            sd := sgt(denominator, sub(0, 1))
        }

        // XOR over sx, sy and sd. This is checking whether there are one or three negative signs in the inputs.
        // If yes, the result should be negative.
        result = sx ^ sy ^ sd == 0 ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The uint256 number for which to calculate the square root.
    /// @return result The result as an uint256.
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        // Set the initial guess to the least power of two that is greater than or equal to sqrt(x).
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x8) {
            result <<= 1;
        }

        // The operations can never overflow because the result is max 2^127 when it enters this block.
        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1; // Seven iterations should be enough
            uint256 roundedDownResult = x / result;
            return result >= roundedDownResult ? roundedDownResult : result;
        }
    }
}


// File contracts/cygnus-periphery/libraries/PRBMathUD60x18.sol

// g-Identifier: Unlicense
pragma solidity >=0.8.4;

/// @title PRBMathUD60x18
/// @author Paul Razvan Berg
/// @notice Smart contract library for advanced fixed-point math that works with uint256 numbers considered to have 18
/// trailing decimals. We call this number representation unsigned 60.18-decimal fixed-point, since there can be up to 60
/// digits in the integer part and up to 18 decimals in the fractional part. The numbers are bound by the minimum and the
/// maximum values permitted by the Solidity type uint256.
library PRBMathUD60x18 {
    /// @dev Half the SCALE number.
    uint256 internal constant HALF_SCALE = 5e17;

    /// @dev log2(e) as an unsigned 60.18-decimal fixed-point number.
    uint256 internal constant LOG2_E = 1_442695040888963407;

    /// @dev The maximum value an unsigned 60.18-decimal fixed-point number can have.
    uint256 internal constant MAX_UD60x18 =
        115792089237316195423570985008687907853269984665640564039457_584007913129639935;

    /// @dev The maximum whole value an unsigned 60.18-decimal fixed-point number can have.
    uint256 internal constant MAX_WHOLE_UD60x18 =
        115792089237316195423570985008687907853269984665640564039457_000000000000000000;

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @notice Calculates the arithmetic average of x and y, rounding down.
    /// @param x The first operand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The second operand as an unsigned 60.18-decimal fixed-point number.
    /// @return result The arithmetic average as an unsigned 60.18-decimal fixed-point number.
    function avg(uint256 x, uint256 y) internal pure returns (uint256 result) {
        // The operations can never overflow.
        unchecked {
            // The last operand checks if both x and y are odd and if that is the case, we add 1 to the result. We need
            // to do this because if both numbers are odd, the 0.5 remainder gets truncated twice.
            result = (x >> 1) + (y >> 1) + (x & y & 1);
        }
    }

    /// @notice Yields the least unsigned 60.18 decimal fixed-point number greater than or equal to x.
    ///
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be less than or equal to MAX_WHOLE_UD60x18.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number to ceil.
    /// @param result The least integer greater than or equal to x, as an unsigned 60.18-decimal fixed-point number.
    function ceil(uint256 x) internal pure returns (uint256 result) {
        if (x > MAX_WHOLE_UD60x18) {
            revert PRBMathUD60x18__CeilOverflow(x);
        }
        assembly {
            // Equivalent to "x % SCALE" but faster.
            let remainder := mod(x, SCALE)

            // Equivalent to "SCALE - remainder" but faster.
            let delta := sub(SCALE, remainder)

            // Equivalent to "x + delta * (remainder > 0 ? 1 : 0)" but faster.
            result := add(x, mul(delta, gt(remainder, 0)))
        }
    }

    /// @notice Divides two unsigned 60.18-decimal fixed-point numbers, returning a new unsigned 60.18-decimal fixed-point number.
    ///
    /// @dev Uses mulDiv to enable overflow-safe multiplication and division.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    ///
    /// @param x The numerator as an unsigned 60.18-decimal fixed-point number.
    /// @param y The denominator as an unsigned 60.18-decimal fixed-point number.
    /// @param result The quotient as an unsigned 60.18-decimal fixed-point number.
    function div(uint256 x, uint256 y) internal pure returns (uint256 result) {
        result = PRBMath.mulDiv(x, SCALE, y);
    }

    /// @notice Returns Euler's number as an unsigned 60.18-decimal fixed-point number.
    /// @dev See https://en.wikipedia.org/wiki/E_(mathematical_constant).
    function e() internal pure returns (uint256 result) {
        result = 2_718281828459045235;
    }

    /// @notice Calculates the natural exponent of x.
    ///
    /// @dev Based on the insight that e^x = 2^(x * log2(e)).
    ///
    /// Requirements:
    /// - All from "log2".
    /// - x must be less than 133.084258667509499441.
    ///
    /// @param x The exponent as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp(uint256 x) internal pure returns (uint256 result) {
        // Without this check, the value passed to "exp2" would be greater than 192.
        if (x >= 133_084258667509499441) {
            revert PRBMathUD60x18__ExpInputTooBig(x);
        }

        // Do the fixed-point multiplication inline to save gas.
        unchecked {
            uint256 doubleScaleProduct = x * LOG2_E;
            result = exp2((doubleScaleProduct + HALF_SCALE) / SCALE);
        }
    }

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    ///
    /// @dev See https://ethereum.stackexchange.com/q/79903/24693.
    ///
    /// Requirements:
    /// - x must be 192 or less.
    /// - The result must fit within MAX_UD60x18.
    ///
    /// @param x The exponent as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        // 2^192 doesn't fit within the 192.64-bit format used internally in this function.
        if (x >= 192e18) {
            revert PRBMathUD60x18__Exp2InputTooBig(x);
        }

        unchecked {
            // Convert x to the 192.64-bit fixed-point format.
            uint256 x192x64 = (x << 64) / SCALE;

            // Pass x to the PRBMath.exp2 function, which uses the 192.64-bit fixed-point number representation.
            result = PRBMath.exp2(x192x64);
        }
    }

    /// @notice Yields the greatest unsigned 60.18 decimal fixed-point number less than or equal to x.
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    /// @param x The unsigned 60.18-decimal fixed-point number to floor.
    /// @param result The greatest integer less than or equal to x, as an unsigned 60.18-decimal fixed-point number.
    function floor(uint256 x) internal pure returns (uint256 result) {
        assembly {
            // Equivalent to "x % SCALE" but faster.
            let remainder := mod(x, SCALE)

            // Equivalent to "x - remainder * (remainder > 0 ? 1 : 0)" but faster.
            result := sub(x, mul(remainder, gt(remainder, 0)))
        }
    }

    /// @notice Yields the excess beyond the floor of x.
    /// @dev Based on the odd function definition https://en.wikipedia.org/wiki/Fractional_part.
    /// @param x The unsigned 60.18-decimal fixed-point number to get the fractional part of.
    /// @param result The fractional part of x as an unsigned 60.18-decimal fixed-point number.
    function frac(uint256 x) internal pure returns (uint256 result) {
        assembly {
            result := mod(x, SCALE)
        }
    }

    /// @notice Converts a number from basic integer form to unsigned 60.18-decimal fixed-point representation.
    ///
    /// @dev Requirements:
    /// - x must be less than or equal to MAX_UD60x18 divided by SCALE.
    ///
    /// @param x The basic integer to convert.
    /// @param result The same number in unsigned 60.18-decimal fixed-point representation.
    function fromUint(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            if (x > MAX_UD60x18 / SCALE) {
                revert PRBMathUD60x18__FromUintOverflow(x);
            }
            result = x * SCALE;
        }
    }

    /// @notice Calculates geometric mean of x and y, i.e. sqrt(x * y), rounding down.
    ///
    /// @dev Requirements:
    /// - x * y must fit within MAX_UD60x18, lest it overflows.
    ///
    /// @param x The first operand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The second operand as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function gm(uint256 x, uint256 y) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        unchecked {
            // Checking for overflow this way is faster than letting Solidity do it.
            uint256 xy = x * y;
            if (xy / x != y) {
                revert PRBMathUD60x18__GmOverflow(x, y);
            }

            // We don't need to multiply by the SCALE here because the x*y product had already picked up a factor of SCALE
            // during multiplication. See the comments within the "sqrt" function.
            result = PRBMath.sqrt(xy);
        }
    }

    /// @notice Calculates 1 / x, rounding toward zero.
    ///
    /// @dev Requirements:
    /// - x cannot be zero.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the inverse.
    /// @return result The inverse as an unsigned 60.18-decimal fixed-point number.
    function inv(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // 1e36 is SCALE * SCALE.
            result = 1e36 / x;
        }
    }

    /// @notice Calculates the natural logarithm of x.
    ///
    /// @dev Based on the insight that ln(x) = log2(x) / log2(e).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    /// - This doesn't return exactly 1 for 2.718281828459045235, for that we would need more fine-grained precision.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the natural logarithm.
    /// @return result The natural logarithm as an unsigned 60.18-decimal fixed-point number.
    function ln(uint256 x) internal pure returns (uint256 result) {
        // Do the fixed-point multiplication inline to save gas. This is overflow-safe because the maximum value that log2(x)
        // can return is 196205294292027477728.
        unchecked {
            result = (log2(x) * SCALE) / LOG2_E;
        }
    }

    /// @notice Calculates the common logarithm of x.
    ///
    /// @dev First checks if x is an exact power of ten and it stops if yes. If it's not, calculates the common
    /// logarithm based on the insight that log10(x) = log2(x) / log2(10).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the common logarithm.
    /// @return result The common logarithm as an unsigned 60.18-decimal fixed-point number.
    function log10(uint256 x) internal pure returns (uint256 result) {
        if (x < SCALE) {
            revert PRBMathUD60x18__LogInputTooSmall(x);
        }

        // Note that the "mul" in this block is the assembly multiplication operation, not the "mul" function defined
        // in this contract.
        // prettier-ignore
        assembly {
            switch x
            case 1 { result := mul(SCALE, sub(0, 18)) }
            case 10 { result := mul(SCALE, sub(1, 18)) }
            case 100 { result := mul(SCALE, sub(2, 18)) }
            case 1000 { result := mul(SCALE, sub(3, 18)) }
            case 10000 { result := mul(SCALE, sub(4, 18)) }
            case 100000 { result := mul(SCALE, sub(5, 18)) }
            case 1000000 { result := mul(SCALE, sub(6, 18)) }
            case 10000000 { result := mul(SCALE, sub(7, 18)) }
            case 100000000 { result := mul(SCALE, sub(8, 18)) }
            case 1000000000 { result := mul(SCALE, sub(9, 18)) }
            case 10000000000 { result := mul(SCALE, sub(10, 18)) }
            case 100000000000 { result := mul(SCALE, sub(11, 18)) }
            case 1000000000000 { result := mul(SCALE, sub(12, 18)) }
            case 10000000000000 { result := mul(SCALE, sub(13, 18)) }
            case 100000000000000 { result := mul(SCALE, sub(14, 18)) }
            case 1000000000000000 { result := mul(SCALE, sub(15, 18)) }
            case 10000000000000000 { result := mul(SCALE, sub(16, 18)) }
            case 100000000000000000 { result := mul(SCALE, sub(17, 18)) }
            case 1000000000000000000 { result := 0 }
            case 10000000000000000000 { result := SCALE }
            case 100000000000000000000 { result := mul(SCALE, 2) }
            case 1000000000000000000000 { result := mul(SCALE, 3) }
            case 10000000000000000000000 { result := mul(SCALE, 4) }
            case 100000000000000000000000 { result := mul(SCALE, 5) }
            case 1000000000000000000000000 { result := mul(SCALE, 6) }
            case 10000000000000000000000000 { result := mul(SCALE, 7) }
            case 100000000000000000000000000 { result := mul(SCALE, 8) }
            case 1000000000000000000000000000 { result := mul(SCALE, 9) }
            case 10000000000000000000000000000 { result := mul(SCALE, 10) }
            case 100000000000000000000000000000 { result := mul(SCALE, 11) }
            case 1000000000000000000000000000000 { result := mul(SCALE, 12) }
            case 10000000000000000000000000000000 { result := mul(SCALE, 13) }
            case 100000000000000000000000000000000 { result := mul(SCALE, 14) }
            case 1000000000000000000000000000000000 { result := mul(SCALE, 15) }
            case 10000000000000000000000000000000000 { result := mul(SCALE, 16) }
            case 100000000000000000000000000000000000 { result := mul(SCALE, 17) }
            case 1000000000000000000000000000000000000 { result := mul(SCALE, 18) }
            case 10000000000000000000000000000000000000 { result := mul(SCALE, 19) }
            case 100000000000000000000000000000000000000 { result := mul(SCALE, 20) }
            case 1000000000000000000000000000000000000000 { result := mul(SCALE, 21) }
            case 10000000000000000000000000000000000000000 { result := mul(SCALE, 22) }
            case 100000000000000000000000000000000000000000 { result := mul(SCALE, 23) }
            case 1000000000000000000000000000000000000000000 { result := mul(SCALE, 24) }
            case 10000000000000000000000000000000000000000000 { result := mul(SCALE, 25) }
            case 100000000000000000000000000000000000000000000 { result := mul(SCALE, 26) }
            case 1000000000000000000000000000000000000000000000 { result := mul(SCALE, 27) }
            case 10000000000000000000000000000000000000000000000 { result := mul(SCALE, 28) }
            case 100000000000000000000000000000000000000000000000 { result := mul(SCALE, 29) }
            case 1000000000000000000000000000000000000000000000000 { result := mul(SCALE, 30) }
            case 10000000000000000000000000000000000000000000000000 { result := mul(SCALE, 31) }
            case 100000000000000000000000000000000000000000000000000 { result := mul(SCALE, 32) }
            case 1000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 33) }
            case 10000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 34) }
            case 100000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 35) }
            case 1000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 36) }
            case 10000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 37) }
            case 100000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 38) }
            case 1000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 39) }
            case 10000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 40) }
            case 100000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 41) }
            case 1000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 42) }
            case 10000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 43) }
            case 100000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 44) }
            case 1000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 45) }
            case 10000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 46) }
            case 100000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 47) }
            case 1000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 48) }
            case 10000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 49) }
            case 100000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 50) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 51) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 52) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 53) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 54) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 55) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 56) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 57) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 58) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 59) }
            default {
                result := MAX_UD60x18
            }
        }

        if (result == MAX_UD60x18) {
            // Do the fixed-point division inline to save gas. The denominator is log2(10).
            unchecked {
                result = (log2(x) * SCALE) / 3_321928094887362347;
            }
        }
    }

    /// @notice Calculates the binary logarithm of x.
    ///
    /// @dev Based on the iterative approximation algorithm.
    /// https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
    ///
    /// Requirements:
    /// - x must be greater than or equal to SCALE, otherwise the result would be negative.
    ///
    /// Caveats:
    /// - The results are nor perfectly accurate to the last decimal, due to the lossy precision of the iterative approximation.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the binary logarithm.
    /// @return result The binary logarithm as an unsigned 60.18-decimal fixed-point number.
    function log2(uint256 x) internal pure returns (uint256 result) {
        if (x < SCALE) {
            revert PRBMathUD60x18__LogInputTooSmall(x);
        }
        unchecked {
            // Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
            uint256 n = PRBMath.mostSignificantBit(x / SCALE);

            // The integer part of the logarithm as an unsigned 60.18-decimal fixed-point number. The operation can't overflow
            // because n is maximum 255 and SCALE is 1e18.
            result = n * SCALE;

            // This is y = x * 2^(-n).
            uint256 y = x >> n;

            // If y = 1, the fractional part is zero.
            if (y == SCALE) {
                return result;
            }

            // Calculate the fractional part via the iterative approximation.
            // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
            for (uint256 delta = HALF_SCALE; delta > 0; delta >>= 1) {
                y = (y * y) / SCALE;

                // Is y^2 > 2 and so in the range [2,4)?
                if (y >= 2 * SCALE) {
                    // Add the 2^(-m) factor to the logarithm.
                    result += delta;

                    // Corresponds to z/2 on Wikipedia.
                    y >>= 1;
                }
            }
        }
    }

    /// @notice Multiplies two unsigned 60.18-decimal fixed-point numbers together, returning a new unsigned 60.18-decimal
    /// fixed-point number.
    /// @dev See the documentation for the "PRBMath.mulDivFixedPoint" function.
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The product as an unsigned 60.18-decimal fixed-point number.
    function mul(uint256 x, uint256 y) internal pure returns (uint256 result) {
        result = PRBMath.mulDivFixedPoint(x, y);
    }

    /// @notice Returns PI as an unsigned 60.18-decimal fixed-point number.
    function pi() internal pure returns (uint256 result) {
        result = 3_141592653589793238;
    }

    /// @notice Raises x to the power of y.
    ///
    /// @dev Based on the insight that x^y = 2^(log2(x) * y).
    ///
    /// Requirements:
    /// - All from "exp2", "log2" and "mul".
    ///
    /// Caveats:
    /// - All from "exp2", "log2" and "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x Number to raise to given power y, as an unsigned 60.18-decimal fixed-point number.
    /// @param y Exponent to raise x to, as an unsigned 60.18-decimal fixed-point number.
    /// @return result x raised to power y, as an unsigned 60.18-decimal fixed-point number.
    function pow(uint256 x, uint256 y) internal pure returns (uint256 result) {
        if (x == 0) {
            result = y == 0 ? SCALE : uint256(0);
        } else {
            result = exp2(mul(log2(x), y));
        }
    }

    /// @notice Raises x (unsigned 60.18-decimal fixed-point number) to the power of y (basic unsigned integer) using the
    /// famous algorithm "exponentiation by squaring".
    ///
    /// @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring
    ///
    /// Requirements:
    /// - The result must fit within MAX_UD60x18.
    ///
    /// Caveats:
    /// - All from "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x The base as an unsigned 60.18-decimal fixed-point number.
    /// @param y The exponent as an uint256.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function powu(uint256 x, uint256 y) internal pure returns (uint256 result) {
        // Calculate the first iteration of the loop in advance.
        result = y & 1 > 0 ? x : SCALE;

        // Equivalent to "for(y /= 2; y > 0; y /= 2)" but faster.
        for (y >>= 1; y > 0; y >>= 1) {
            x = PRBMath.mulDivFixedPoint(x, x);

            // Equivalent to "y % 2 == 1" but faster.
            if (y & 1 > 0) {
                result = PRBMath.mulDivFixedPoint(result, x);
            }
        }
    }

    /// @notice Returns 1 as an unsigned 60.18-decimal fixed-point number.
    function scale() internal pure returns (uint256 result) {
        result = SCALE;
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Requirements:
    /// - x must be less than MAX_UD60x18 / SCALE.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the square root.
    /// @return result The result as an unsigned 60.18-decimal fixed-point .
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            if (x > MAX_UD60x18 / SCALE) {
                revert PRBMathUD60x18__SqrtOverflow(x);
            }
            // Multiply x by the SCALE to account for the factor of SCALE that is picked up when multiplying two unsigned
            // 60.18-decimal fixed-point numbers together (in this case, those two numbers are both the square root).
            result = PRBMath.sqrt(x * SCALE);
        }
    }

    /// @notice Converts a unsigned 60.18-decimal fixed-point number to basic integer form, rounding down in the process.
    /// @param x The unsigned 60.18-decimal fixed-point number to convert.
    /// @return result The same number in basic integer form.
    function toUint(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            result = x / SCALE;
        }
    }
}


// File contracts/cygnus-periphery/libraries/SafeTransferLib.sol

// g-Identifier: MIT
pragma solidity >=0.8.4;

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Caution! This library won't check that a token has code, responsibility is delegated to the caller.
library SafeTransferLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    error ETHTransferFailed();

    error TransferFromFailed();

    error TransferFailed();

    error ApproveFailed();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       ETH OPERATIONS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function safeTransferETH(address to, uint256 amount) internal {
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

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      ERC20 OPERATIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
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

    function safeTransfer(
        address token,
        address to,
        uint256 amount
    ) internal {
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

    function safeApprove(
        address token,
        address to,
        uint256 amount
    ) internal {
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
}


// File contracts/cygnus-periphery/libraries/CygnusPoolAddress.sol

// g-Identifier: Unlicensed

/**
 *  @title CygnusPoolAddress
 *  @dev Provides functions for deriving Cygnus collateral and borrow addresses deployed by Factory
 */
pragma solidity >=0.8.4;

library CygnusPoolAddress {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. STORAGE
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  IMPORTANT: UPDATE WITH LATEST CODE HASH
     *
     *  @notice keccak256(creationCode) of CygnusCollateral.sol contract
     *  @notice Used by Router and CygnusFactory to deploy shuttles
     */
    bytes32 internal constant COLLATERAL_INIT_CODE_HASH =
        0x3dbc8390e0d0bece595895bdf8c0fdac5716d588a2dbc8041831d04c7d965422;

    /**
     *  IMPORTANT: UPDATE WITH LATEST CODE HASH
     *
     *  @notice keccak256(creationCode) of CygnusBorrow.sol contract
     *  @notice Used by Router and CygnusFactory to deploy shuttles
     */
    bytes32 internal constant BORROW_INIT_CODE_HASH =
        0x8b9dfcd7c5b63c68b3c7a9cbe3cab696a0f01419f20cf33f98f953bccfc59458;

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Used by CygnusAltair.sol and Cygnus Factory
     *  @dev create2_address: keccak256(0xff, senderAddress, salt, keccak256(init_code))[12:]
     *  @param lpTokenPair The address of the LP Token
     *  @param factory The address of the Cygnus Factory used to deploy the shuttle
     *  @return collateral The calculated address of the Cygnus collateral contract given `lpTokenPair`
     *                     and `factory` addresses
     */
    function getCollateralContract(
        address lpTokenPair,
        address factory,
        address collateralDeployer
    ) internal pure returns (address collateral) {
        collateral = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            collateralDeployer,
                            keccak256(abi.encode(lpTokenPair, factory)),
                            COLLATERAL_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }

    /**
     *  @dev Used by CygnusAltair.sol
     *  @dev create2_address: keccak256(0xff, senderAddress, salt, keccak256(init_code))[12:]
     *  @param collateral The address of the LP Token
     *  @param factory The address of the Cygnus Factory used to deploy the shuttle
     *  @param borrowDeployer The address of the CygnusAlbireo contract
     *  @return borrow The calculated address of the Cygnus Borrow contract deployed by factory given
     *          `lpTokenPair` and `factory` addresses along with borrowDeployer contract address
     */
    function getBorrowContract(
        address collateral,
        address factory,
        address borrowDeployer
    ) internal pure returns (address borrow) {
        borrow = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            borrowDeployer,
                            keccak256(abi.encode(collateral, factory)),
                            BORROW_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }
}


// File contracts/cygnus-periphery/CygnusAltairX.sol

// g-Identifier: Unlicense
pragma solidity >=0.8.4;

// Dependencies


// Interfaces









// Libraries



/**
 *  @title  CygnusAltair Periphery contract to interact with Cygnus Core contracts
 *  @author CygnusDAO
 *  @notice This contract details the functions for:
 *          - Minting CygLP and CygDAI
 *          - Redeeming CygLP and CygDAI
 *          - Borrowing DAI
 *          - Repaying DAI
 *          - Liquidating user's with DAI (pay back DAI, receive CygLP + bonus liquidation reward)
 *          - Liquidating user's and converting to DAI (pay back DAI, receive CygLP + bonus equivalent in DAI)
 *          - Leveraging LP tokens
 *          - Deleveraging LP Tokens
 */
contract CygnusAltairX is ICygnusAltairX, Context {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. LIBRARIES
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:library PRBMathUD60x18 Library for uint256 fixed point math, also imports the main library `PRBMath`
     */
    using PRBMathUD60x18 for uint256;

    /**
     *  @custom:library SafeTransferLib For safe transfers of Erc20 tokens
     */
    using SafeTransferLib for address;

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. STORAGE
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ───────────────────────────────────────────── Internal ────────────────────────────────────────────────  */

    /**
     *  @custom:struct CygnusShuttle Callback addresses for the leverage function
     *  @custom:member lp The address of the LP Token
     *  @custom:member collateral The address of the Cygnus collateral contract
     *  @custom:member borrow The address of the Cygnus borrow contract
     *  @custom:member recipient The address of the recipient
     */
    struct CygnusShuttle {
        address lpTokenPair;
        address collateral;
        address borrowable;
        address recipient;
    }

    /**
     *  @custom:struct RedeemLeverageCallData Encoded bytes passed to Cygnus contracts containing leverage data
     *  @custom:member collateral The address of the collateral contract
     *  @custom:member borrowable The address of the borrow contract
     *  @custom:member recipient The address of the user leveraging LP Tokens
     *  @custom:member redeemTokens The amount of CygLP to redeem
     *  @custom:member redeemAmount The amount of LP to redeem
     */
    struct RedeemLeverageCallData {
        address lpTokenPair;
        address collateral;
        address borrowable;
        address recipient;
        uint256 redeemTokens;
        uint256 redeemAmount;
    }

    struct Query {
        address adapter;
        address tokenIn;
        address tokenOut;
        uint256 amountOut;
    }

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @inheritdoc ICygnusAltairX
     */
    address public immutable override hangar18;

    /**
     *  @inheritdoc ICygnusAltairX
     */
    address public immutable override nativeToken;

    /**
     *  @inheritdoc ICygnusAltairX
     */
    address public immutable override dai;

    /**
     *  @inheritdoc ICygnusAltairX
     */
    address public constant override USDC = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;

    /**
     *  @inheritdoc ICygnusAltairX
     */
    bytes public constant override LOCAL_BYTES = new bytes(0);

    /**
     *  @inheritdoc ICygnusAltairX
     */
    IYakAdapter public constant override YAK_ROUTER = IYakAdapter(0xC4729E56b831d74bBc18797e0e17A295fA77488c);

    /**
     *  @notice Adapters: TraderJoe for JOE pools, Sushi for Sushi, Pangolin for PNG, Platypus for stablecoins + Bonus
     */
    uint8[] public adapters = [0, 1, 4, 25, 28];

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTRUCTOR
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Constructs the periphery contract. Factory must be deployed on the chain first to get the addresses
     *          of deployers and the wrapped native token (WAVAX, WETH, WFTM, etc.)
     *  @param factory The address of the Factory contract
     */
    constructor(address factory) {
        // Assign factory
        hangar18 = factory;

        // Address of nativeToken in this chain
        nativeToken = ICygnusFactory(factory).nativeToken();

        // Address of DAI in this chain
        dai = ICygnusFactory(factory).dai();
    }

    /**
     *  @notice Only accept AVAX via fallback from the Wrapped AVAX contract
     */
    receive() external payable {
        /// @custom:error NotNativeTokenSender Avoid receiving anything but Wrapped AVAX
        if (_msgSender() != nativeToken) {
            revert CygnusAltair__NotNativeTokenSender(_msgSender());
        }
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. MODIFIERS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:modifier checkDeadline Reverts the transaction if the block.timestamp is after deadline
     */
    modifier checkDeadline(uint256 deadline) {
        checkDeadlineInternal(deadline);
        _;
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            5. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ───────────────────────────────────────────── Internal ────────────────────────────────────────────────  */

    /**
     *  @notice Reverts the transaction if the block.timestamp is after deadline
     *  @param deadline A time in the future when the transaction expires
     */
    function checkDeadlineInternal(uint256 deadline) internal view {
        /// @custom:error TransactionExpired Avoid transacting past deadline
        if (getBlockTimestamp() > deadline) {
            revert CygnusAltair__TransactionExpired(deadline);
        }
    }

    /**
     *  @notice The current block timestamp
     */
    function getBlockTimestamp() internal view returns (uint256) {
        return block.timestamp;
    }

    /**
     *  @dev Compute optimal deposit amount helper.
     *  @param amountA amount of token A desired to deposit
     *  @param reservesA Reserves of token A from the DEX
     *  @param _dexSwapFee The fee charged by this dex for a swap (ie Uniswap = 997/1000 = 0.3%)
     */
    function optimalDepositA(
        uint256 amountA,
        uint256 reservesA,
        uint256 _dexSwapFee
    ) internal pure returns (uint256) {
        // Calculate with dex swap fee
        uint256 a = (1000 + _dexSwapFee) * reservesA;
        uint256 b = amountA * 1000 * reservesA * 4 * _dexSwapFee;
        uint256 c = PRBMath.sqrt(a * a + b);
        uint256 d = 2 * _dexSwapFee;
        return (c - a) / d;
    }

    /**
     *  @notice Checks the `token` balance of this contract
     *  @param token The token to view balance of
     *  @return This contract's balance
     */
    function contractBalanceOf(address token) private view returns (uint256) {
        return IErc20(token).balanceOf(address(this));
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            6. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Internal ───────────────────────────────────────────────  */

    /**
     *  @notice The permit for the terminal contracts
     *  @param amount The amount to allow borrow
     *  @param deadline A time in the future when the allowance expires
     */
    function permitInternal(
        address terminalToken,
        uint256 amount,
        uint256 deadline,
        bytes memory permitData
    ) internal virtual {
        // If no permit return
        if (permitData.length == 0) return;

        // Decode permit data
        (bool approveMax, uint8 v, bytes32 r, bytes32 s) = abi.decode(permitData, (bool, uint8, bytes32, bytes32));

        // Get approve amount
        uint256 value = approveMax ? type(uint256).max : amount;

        // Validate permit
        ICygnusTerminal(terminalToken).permit(_msgSender(), address(this), value, deadline, v, r, s);
    }

    /**
     *  @notice The borrow permit for the borrow contracts
     *  @param borrowable The address of the Cygnus borrow contract
     *  @param amount The amount to allow borrow
     *  @param deadline A time in the future when the allowance expires
     */
    function borrowPermitInternal(
        address borrowable,
        uint256 amount,
        uint256 deadline,
        bytes memory permitData
    ) internal virtual {
        // If no borrow permit data return
        if (permitData.length == 0) return;

        // Decode permit data
        (bool approveMax, uint8 v, bytes32 r, bytes32 s) = abi.decode(permitData, (bool, uint8, bytes32, bytes32));

        // Get borrow approve amount
        uint256 value = approveMax ? type(uint256).max : amount;

        // Validate permit
        ICygnusBorrow(borrowable).borrowPermit(_msgSender(), address(this), value, deadline, v, r, s);
    }

    /**
     *  @param borrowable Address of the Cygnus borrow contract
     *  @param token Address of the token we are repaying (DAI)
     *  @param borrower Address of the borrower who is repaying the loan
     *  @param amountMax The max available amount
     */
    function repayAndRefundInternal(
        address borrowable,
        address token,
        address borrower,
        uint256 amountMax
    ) internal virtual {
        // Repay
        uint256 amount = repayAmountInternal(borrowable, amountMax, borrower);

        // Safe transfer DAI to borrowable
        token.safeTransfer(borrowable, amount);

        // Cygnus Borrow with address(0) to update borrow balances
        ICygnusBorrow(borrowable).borrow(borrower, address(0), 0, LOCAL_BYTES);

        // Refund excess
        if (amountMax > amount) {
            uint256 refundAmount = amountMax - amount;
            // Check if token is Avax
            if (token == nativeToken) {
                // Withdraw Avax
                IWAVAX(nativeToken).withdraw(refundAmount);

                // Transfer AVAX
                borrower.safeTransferETH(refundAmount);
            } else {
                // Transfer Token
                token.safeTransfer(borrower, refundAmount);
            }
        }
    }

    /**
     *  @notice Safe internal function to repay borrowed amount
     *  @param borrowable The address of the Cygnus borrow arm where the borrowed amount was taken from
     *  @param amountMax The max amount that can be repaid
     *  @param borrower The address of the account that is repaying the borrowed amount
     */
    function repayAmountInternal(
        address borrowable,
        uint256 amountMax,
        address borrower
    ) internal virtual returns (uint256 amount) {
        ICygnusBorrow(borrowable).accrueInterest();

        // Get borrow balance of borrower
        uint256 borrowedAmount = ICygnusBorrow(borrowable).getBorrowBalance(borrower);

        // Avoid repaying more than borrowedAmount
        amount = amountMax < borrowedAmount ? amountMax : borrowedAmount;
    }

    // 2 FUNCTIONS: - CONVERT DAI TO LP'S TOKEN0 AND TOKEN1 FOR OPTIMAL LP DEPOSIT
    //              - CONVERT LP TOKEN TO DAI

    /**
     *  @notice Grants allowance to the dex' router to handle our rewards
     *  @param token The address of the token we are approving
     *  @param amount The amount to approve
     */
    function approveDexRouter(
        address token,
        address router,
        uint256 amount
    ) internal {
        if (IErc20(token).allowance(address(this), router) >= amount) {
            return;
        } else {
            token.safeApprove(router, type(uint256).max);
        }
    }

    /**
     *  @notice Swaps tokenIn to tokenOut given an `amount` of tokenIn
     *  @param tokenIn The address of the token we are swapping
     *  @param tokenOut The address of the token we are receiving
     *  @param amountIn The amount of tokenIn we are swapping
     */
    function swapTokensInternal(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint8[] memory opts
    ) internal virtual {
        // Query adapters
        IYakAdapter.Query memory query = YAK_ROUTER.queryNoSplit(amountIn, tokenIn, tokenOut, opts);

        // Approve adapter in router
        approveDexRouter(tokenIn, query.adapter, type(uint256).max);

        // Send `amountIn` of `tokenIn` to the adapter
        tokenIn.safeTransfer(query.adapter, amountIn);

        // Swap `amountIn` and receive `amountOut`
        IYakAdapter(query.adapter).swap(amountIn, query.amountOut, tokenIn, tokenOut, address(this));
    }

    /**
     *  @notice IMPORTANT
     *          USDC is used as bridge token to convert to DAI. Avalanche liquidity is very highly concentrated in USDc.
     *          Converting from LP token to USDc saves a lot for borrowers, even while using dex aggregators.
     *  @notice This function gets called after calling `borrow` on CygnusBorrow contract and having `amountDai` of DAI
     *  @param lpTokenPair The address of the LP Token
     *  @param token0 The address of token0 from the LP Token
     *  @param token1 The address of token1 from the LP Token
     *  @param amountDai DAI amount to convert to token0 and token1 of an LP Token
     */
    function convertDAIToTokens(
        address lpTokenPair,
        address token0,
        address token1,
        uint256 amountDai
    ) internal returns (uint256 totalAmountA, uint256 totalAmountB) {
        // Create adapter options
        uint8[] memory opts = new uint8[](5);

        // Assign adapters to query, hardcode for gas savings always max 5
        for (uint256 i = 0; i < 5; i++) {
            opts[i] = adapters[i];
        }

        // ─────────────────────── 1. Check if token0 or token1 is already DAI

        // Placeholder tokenA
        address tokenA;

        // Placeholder tokenB
        address tokenB;

        // If dai, then pool has enough liquidity to swap at minimal cost
        if (token0 == dai || token1 == dai) {
            // If token0 is dai, then assign tokenA to token0, else tokenA to token1
            (tokenA, tokenB) = token0 == dai ? (token0, token1) : (token1, token0);
        } else {
            // Not DAI, swap dai to USDc.e for lower slippage in Avalanche
            swapTokensInternal(dai, USDC, amountDai, opts);

            // swap USDc to native token
            swapTokensInternal(USDC, nativeToken, contractBalanceOf(USDC), opts);
            // ─────────────────── 2. Check if token0 or token1 is already AVAX

            if (token0 == nativeToken || token1 == nativeToken) {
                // If token0 is nativeToken, then assign tokenA to token0, else tokenA to token1
                (tokenA, tokenB) = token0 == nativeToken ? (token0, token1) : (token1, token0);
            } else {
                // None are DAI or native token, swap all native token to token0 to calculate optimal deposit
                swapTokensInternal(nativeToken, token0, contractBalanceOf(nativeToken), opts);

                // Assign tokenA to token0 and tokenB to token1
                (tokenA, tokenB) = (token0, token1);
            }
        }
        // ─────────────────────── 3. Calculate optimal deposit amount for an LP Token

        // prettier-ignore
        (uint256 reserves0, uint256 reserves1, /* BlockTimestamp */) = IDexPair(lpTokenPair).getReserves();

        // Get reserves A for calculating optimal deposit
        uint256 reservesA = tokenA == token0 ? reserves0 : reserves1;

        // Get optimal swap amount for token A - 997/1000 is the swap fee of TraderJoe
        uint256 swapAmount = optimalDepositA(contractBalanceOf(tokenA), reservesA, 997);

        // Swap optimal amount of tokenA to tokenB
        swapTokensInternal(tokenA, tokenB, swapAmount, opts);

        // ─────────────────────── 4. Send token0 and token1 to lp token pair to call `mint` on next function

        // Total Amount A
        totalAmountA = contractBalanceOf(token0);

        // Total Amount B
        totalAmountB = contractBalanceOf(token1);
    }

    /**
     *  @notice IMPORTANT
     *          USDC is used as bridge token to convert to DAI. Avalanche liquidity is very highly concentrated in USDc.
     *          Converting from LP token to USDc to DAI saves a lot for borrowers, even while using dex aggregators.
     *  @notice Converts an amount of LP Token to DAI. It is called after calling `burn` on a uniswapV2 pair, which
     *          receives amountTokenA of token0 and amountTokenB of token1.
     *  @param amountTokenA The amount of token A to convert to DAI
     *  @param amountTokenB The amount of token B to convert to DAI
     *  @param token0 The address of token0 from the LP Token pair
     *  @param token1 The address of token1 from the LP Token pair
     */
    function convertLPTokenToDAI(
        uint256 amountTokenA,
        uint256 amountTokenB,
        address token0,
        address token1
    ) internal returns (uint256 amountDAI) {
        // Create adapter options
        uint8[] memory opts = new uint8[](5);

        // Assign adapters to query, hardcode for gas savings always max 5
        for (uint256 i = 0; i < 5; i++) {
            opts[i] = adapters[i];
        }

        // ─────────────────────── 1. Check if token0 or token1 is already DAI

        // If token0 or token1 is dai then swap with the pool
        if (token0 == dai || token1 == dai) {
            // Convert the other token to DAI and return
            token0 == dai
                ? swapTokensInternal(token1, dai, amountTokenB, opts)
                : swapTokensInternal(token0, dai, amountTokenA, opts);

            // Explicit return
            return contractBalanceOf(dai);
        }
        // Not dai, check for nativeToken
        else {
            // ─────────────────── 3. Check if token0 or token1 is already nativeToken

            if (token0 == nativeToken || token1 == nativeToken) {
                // Avoid converting usdc to avax and back to usdc
                if (token0 != USDC || token1 != USDC) {
                    // Convert token0 or token1 to nativeToken
                    token0 == nativeToken
                        ? swapTokensInternal(token1, nativeToken, amountTokenB, opts)
                        : swapTokensInternal(token0, nativeToken, amountTokenA, opts);
                }
            }
            // None are DAI or nativeToken, convert all to nativeToken
            else {
                // Swap token0 to nativeToken
                swapTokensInternal(token0, nativeToken, amountTokenA, opts);

                // Swap token 1 to nativeToken
                swapTokensInternal(token1, nativeToken, amountTokenB, opts);
            }
        }

        // ─────────────────────── 4. Swap all nativeTokens to DAI */

        // Convert nativeToken to USDc due to liquidity concentrated in USDc
        swapTokensInternal(nativeToken, USDC, contractBalanceOf(nativeToken), opts);

        // Swap USDC to DAI checking Platypus adapter
        swapTokensInternal(USDC, dai, contractBalanceOf(USDC), opts);

        // Total Amount DAI
        amountDAI = contractBalanceOf(dai);
    }

    /**
     *  @notice Removes liquidity from the Dex by calling the pair's `burn` function, receiving tokenA and tokenB
     *  @param lpTokenPair The address of the LP Token
     *  @param borrower The address of the borrower
     *  @param collateral The address of the Cygnus Collateral contract
     *  @param borrowable The address of the Cygnus Borrow contract
     *  @param redeemTokens The amount of CygLP to redeem
     *  @param redeemAmount The amount of LP to redeem
     *  @param token0 The address of token0 from the lpTokenPair from CygnusCollateral
     *  @param token1 The address of token1 from the lpTokenPair from CygnusCollateral
     */
    function removeLiquidityAndRepay(
        address lpTokenPair,
        address borrower,
        address collateral,
        address borrowable,
        uint256 redeemTokens,
        uint256 redeemAmount,
        address token0,
        address token1
    ) internal {
        // Transfer LP Token back to LP Token's contract to remove liquidity
        ICygnusCollateral(lpTokenPair).transfer(lpTokenPair, redeemAmount);

        // Burn and return amountA and amountB
        (uint256 amountAMax, uint256 amountBMax) = IDexPair(lpTokenPair).burn(address(this));

        /// @custom:error InsufficientBurnAmountA Avoid invalid burn amount of token A
        if (amountAMax < 0) {
            revert CygnusAltair__InsufficientBurnAmountA(amountAMax);
        }
        /// @custom:error InsufficientBurnAmountB Avoid invalid burn amount of token B
        else if (amountBMax < 0) {
            revert CygnusAltair__InsufficientBurnAmountB(amountBMax);
        }

        // Repay and refund
        uint256 amountDai = convertLPTokenToDAI(amountAMax, amountBMax, token0, token1);

        // Repay DAI
        repayAndRefundInternal(borrowable, dai, borrower, amountDai);

        // repay flash redeem
        ICygnusCollateral(collateral).transferFrom(borrower, collateral, redeemTokens);
    }

    /**
     *  @notice Leverage internal function and calls borrow contract
     *  @param lpTokenPair The address of the LP Token
     *  @param collateral The address of the Cygnus collateral address for this lpTokenPair
     *  @param borrowable The address of the Cygnus borrowable address for this collateral
     *  @param leverageAmount The amount to borrow from borrowable
     *  @param recipient The address of the recipient
     */
    function leverageInternal(
        address lpTokenPair,
        address collateral,
        address borrowable,
        uint256 leverageAmount,
        address recipient
    ) internal virtual {
        // Encode data to bytes
        bytes memory cygnusShuttle = abi.encode(
            CygnusShuttle({
                lpTokenPair: lpTokenPair,
                collateral: collateral,
                borrowable: borrowable,
                recipient: recipient
            })
        );

        // Call borrow with encoded data
        ICygnusBorrow(borrowable).borrow(recipient, address(this), leverageAmount, cygnusShuttle);
    }

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @inheritdoc ICygnusAltairX
     */
    function borrow(
        address borrowable,
        uint256 amount,
        address recipient,
        uint256 deadline,
        bytes memory permitData
    ) public virtual override checkDeadline(deadline) {
        // Borrow permit
        borrowPermitInternal(borrowable, amount, deadline, permitData);

        // Borrow amount
        ICygnusBorrow(borrowable).borrow(_msgSender(), recipient, amount, LOCAL_BYTES);
    }

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    //  MINT CYGLP / CYGDAI ──────────────────────────
    //  REPAY BORROW ─────────────────────────────────

    /**
     *  @inheritdoc ICygnusAltairX
     */
    function repay(
        address borrowable,
        uint256 amountMax,
        address borrower,
        uint256 deadline
    ) external virtual override checkDeadline(deadline) returns (uint256 amount) {
        // Amount to repay
        amount = repayAmountInternal(borrowable, amountMax, borrower);

        // Transfer DAI from msg sender to borrow contract
        ICygnusBorrow(borrowable).underlying().safeTransferFrom(_msgSender(), borrowable, amount);

        // Call borrow to update borrower's borrow balance
        ICygnusBorrow(borrowable).borrow(borrower, address(0), 0, LOCAL_BYTES);
    }

    //  LIQUIDATE BORROW ─────────────────────────────

    /**
     *  @inheritdoc ICygnusAltairX
     */
    function liquidate(
        address borrowable,
        uint256 amountMax,
        address borrower,
        address recipient,
        uint256 deadline
    ) external virtual override checkDeadline(deadline) returns (uint256 amount, uint256 seizeTokens) {
        // Amount to repay
        amount = repayAmountInternal(borrowable, amountMax, borrower);

        // Transfer DAI
        ICygnusBorrow(borrowable).underlying().safeTransferFrom(_msgSender(), borrowable, amount);

        // Liquidate
        seizeTokens = ICygnusBorrow(borrowable).liquidate(borrower, recipient);
    }

    /**
     *  @notice Function used for testing, should or should not be used
     *  @inheritdoc ICygnusAltairX
     */
    function liquidateToDai(
        address borrowable,
        uint256 amountMax,
        address borrower,
        address recipient,
        uint256 deadline
    ) external virtual override checkDeadline(deadline) returns (uint256 amountDai) {
        // Amount to repay
        uint256 amount = repayAmountInternal(borrowable, amountMax, borrower);

        // Transfer DAI
        ICygnusBorrow(borrowable).underlying().safeTransferFrom(_msgSender(), borrowable, amount);

        // Liquidate and increase liquidator's CygLP amount
        uint256 seizeTokens = ICygnusBorrow(borrowable).liquidate(borrower, recipient);

        // Get Collateral
        address collateral = ICygnusBorrow(borrowable).collateral();

        // Redeem CygLP for LP Token
        uint256 redeemAmount = ICygnusCollateral(collateral).redeem(seizeTokens, recipient, recipient);

        // Get LP Token pair
        address lpTokenPair = ICygnusCollateral(collateral).underlying();

        // Get token0
        address token0 = IDexPair(lpTokenPair).token0();

        // Get token1
        address token1 = IDexPair(lpTokenPair).token1();

        // Remove `redeemAmount` of liquidity from the LP Token pair
        IDexPair(lpTokenPair).transferFrom(recipient, lpTokenPair, redeemAmount);

        // Burn LP Token and return amountA and amountB
        (uint256 amountAMax, uint256 amountBMax) = IDexPair(lpTokenPair).burn(address(this));

        // Convert amountA and amountB to DAI
        amountDai = convertLPTokenToDAI(amountAMax, amountBMax, token0, token1);

        // Transfer DAI to liquidator
        IErc20(dai).transfer(recipient, amountDai);
    }

    //  LEVERAGE ─────────────────────────────────────

    /**
     *  @inheritdoc ICygnusAltairX
     */
    function leverage(
        address collateral,
        uint256 amountDAIDesired,
        address recipient,
        uint256 deadline,
        bytes calldata permitData
    ) external virtual override checkDeadline(deadline) {
        // Get LP TokenPair
        address lpTokenPair = ICygnusCollateral(collateral).underlying();

        // Get the borrow contract for the permit
        address borrowable = ICygnusCollateral(collateral).borrowable();

        // Permit (if any)
        borrowPermitInternal(borrowable, amountDAIDesired, deadline, permitData);

        // Pass LP Token, collateral, borrowable, amount, recipient
        leverageInternal(lpTokenPair, collateral, borrowable, amountDAIDesired, recipient);
    }

    /**
     *  @inheritdoc ICygnusAltairX
     */
    function altairBorrow_O9E(
        address sender,
        address borrower,
        uint256 borrowAmount,
        bytes calldata data
    ) external override {
        // Decode data passed from borrow contract
        CygnusShuttle memory cygnusShuttle = abi.decode(data, (CygnusShuttle));

        // Get Cygnus borrow address for this LP Token pair
        address borrowable = cygnusShuttle.borrowable;

        /// @custom:error MsgSenderNotRouter Avoid if the caller is not the router
        if (sender != address(this)) {
            // solhint-disable-next-line
            revert CygnusAltair__MsgSenderNotRouter({ sender: sender, origin: tx.origin, borrower: borrower });
        }
        /// @custom:error MsgSenderNotBorrowable Avoid if the msg sender is not the borrow contract
        else if (_msgSender() != borrowable) {
            revert CygnusAltair__MsgSenderNotBorrowable({ sender: _msgSender(), borrowable: borrowable });
        }

        // Token0 Address of the user's deposited LP token
        address token0 = IDexPair(cygnusShuttle.lpTokenPair).token0();

        // Token1 Address of the user's deposited LP Token
        address token1 = IDexPair(cygnusShuttle.lpTokenPair).token1();

        // Converts the borrowed amount of DAI to tokenA and tokenB to mint the LP Token
        (uint256 totalAmountA, uint256 totalAmountB) = convertDAIToTokens(
            cygnusShuttle.lpTokenPair,
            token0,
            token1,
            borrowAmount
        );

        /* 
        Approve dex router in token0
        AltairHelper.approveDexRouter(token0, address(DEX_ROUTER), type(uint256).max);

        // Approve dex router in token1
        AltairHelper.approveDexRouter(token1, address(DEX_ROUTER), type(uint256).max);

        // Add liquidity to DEX and mint LP Token
        DEX_ROUTER.addLiquidity(
            token0,
            token1,
            totalAmountA,
            totalAmountB,
            0,
            0,
            cygnusShuttle.collateral,
            block.timestamp
        );
         */

        // Transfer token0 to LP Token contract
        token0.safeTransfer(cygnusShuttle.lpTokenPair, totalAmountA);
        // Transfer token1 to LP Token contract
        token1.safeTransfer(cygnusShuttle.lpTokenPair, totalAmountB);
        // Mint the LP Token to the router
        uint256 liquidity = IDexPair(cygnusShuttle.lpTokenPair).mint(address(this));

        // Check allowance and deposit the LP token in the collateral contract
        approveDexRouter(cygnusShuttle.lpTokenPair, cygnusShuttle.collateral, liquidity);
        // Mint CygLP to the recipient
        ICygnusCollateral(cygnusShuttle.collateral).deposit(liquidity, cygnusShuttle.recipient);
    }

    //  DELEVERAGE ───────────────────────────────────

    /**
     *  @inheritdoc ICygnusAltairX
     */
    function deleverage(
        address collateral,
        uint256 redeemTokens,
        uint256 deadline,
        bytes calldata permitData
    ) external override checkDeadline(deadline) {
        // Get collateral
        address lpTokenPair = ICygnusCollateral(collateral).underlying();

        /// @custom:error InvalidRedeemAmount Avoid redeeming 0 tokens
        if (redeemTokens <= 0) {
            revert CygnusAltair__InvalidRedeemAmount({ redeemer: _msgSender(), redeemTokens: redeemTokens });
        }

        // Current CygLP exchange rate
        uint256 exchangeRate = ICygnusCollateral(collateral).exchangeRate();

        // Get redeem amount
        uint256 redeemAmount = redeemTokens.mul(exchangeRate);

        // Permit data
        permitInternal(collateral, redeemTokens, deadline, permitData);

        // Encode redeem data
        bytes memory redeemData = abi.encode(
            RedeemLeverageCallData({
                lpTokenPair: lpTokenPair,
                collateral: collateral,
                borrowable: ICygnusCollateral(collateral).borrowable(),
                recipient: _msgSender(),
                redeemTokens: redeemTokens,
                redeemAmount: redeemAmount
            })
        );

        // Flash redeem
        ICygnusCollateral(collateral).flashRedeemAltair(address(this), redeemAmount, redeemData);
    }

    /**
     *  @inheritdoc ICygnusAltairX
     */
    function altairRedeem_u91A(
        address sender,
        uint256 redeemAmount,
        address token0,
        address token1,
        bytes calldata data
    ) external override {
        redeemAmount;

        // Decode shuttle
        RedeemLeverageCallData memory redeemData = abi.decode(data, (RedeemLeverageCallData));

        // Get collateral contract
        address cygnusCollateralContract = redeemData.collateral;

        /// @custom:error MsgSenderNotRouter Avoid if the caller is not the router
        // solhint-disable
        if (sender != address(this)) {
            revert CygnusAltair__MsgSenderNotRouter({
                sender: sender,
                origin: tx.origin,
                borrower: redeemData.recipient
            });
        }
        /// @custom:error MsgSenderNotBorrowable Avoid if the msg sender is not the borrow contract
        else if (_msgSender() != cygnusCollateralContract) {
            revert CygnusAltair__MsgSenderNotCollateral({ sender: _msgSender(), collateral: cygnusCollateralContract });
        }
        //solhint-enable

        // Remove liquidity from pool and repay to borrowable
        removeLiquidityAndRepay(
            redeemData.lpTokenPair,
            redeemData.recipient,
            redeemData.collateral,
            redeemData.borrowable,
            redeemData.redeemTokens,
            redeemData.redeemAmount,
            token0,
            token1
        );
    }

    /**
     *  @notice Replace the bonus adapter. Keep at maximum 4 as the first 3 cover most cases
     */
    function addAdapter(uint8 adapter) external override {
        // Get admin from factory
        address admin = ICygnusFactory(hangar18).admin();

        /// @custom:error MsgSenderNotAdmin Avoid unless admin
        if (_msgSender() != admin) {
            revert CygnusAltair__MsgSenderNotAdmin({ sender: _msgSender(), admin: admin });
        }

        // Remove bonus and don't add new adapter
        if (adapter == 0) {
            // Remove bonus adapter
            adapters.pop();
        }
        // Remove bonus and add new adapter
        else {
            // Remove bonus adapter
            adapters.pop();

            // Add new bonus adapter
            adapters.push(adapter);
        }
    }
}
/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-23
*/

// Sources flattened with hardhat v2.9.7 https://hardhat.org

// File contracts/cygnus-core/interfaces/IErc20.sol

// SPDX-License-Identifier: Unlicense
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


// File contracts/cygnus-core/interfaces/IErc20Permit.sol

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


// File contracts/cygnus-core/interfaces/ICygnusTerminal.sol

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
    event Withdraw(
        address indexed sender,
        address indexed recipient,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
           3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @return totalBalance Total balance owned by this shuttle pool in terms of its underlying
     */
    function totalBalance() external view returns (uint256);

    /**
     *  @return underlying The address of the underlying (LP Token for collateral contracts, DAI for borrow contracts)
     */
    function underlying() external view returns (address);

    /**
     *  @return hangar18 The address of the Cygnus Factory contract used to deploy this shuttle  🛸
     */
    function hangar18() external view returns (address);

    /**
     *  @return shuttleId The ID of this shuttle (shared by Collateral and Borrow)
     */
    function shuttleId() external view returns (uint256);

    /**
     *  @return exchangeRate The ratio which 1 pool token can be redeemed for underlying amount
     */
    function exchangeRate() external returns (uint256);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice Deposits assets and mints shares to recipient
     *  @param assets The amount of assets to deposit
     *  @param recipient Address of the minter
     *  @return shares Amount of shares minted
     *  @custom:security non-reentrant
     */
    function deposit(uint256 assets, address recipient) external returns (uint256 shares);

    /**
     *  @notice Redeems shares and returns assets to recipient
     *  @param shares The amount of shares to redeem for assets
     *  @param recipient The address of the redeemer
     *  @param owner The address of the account who owns the shares
     *  @return assets Amount of assets redeemed
     *  @custom:security non-reentrant
     */
    function redeem(
        uint256 shares,
        address recipient,
        address owner
    ) external returns (uint256 assets);

    /**
     *  @notice 👽
     *  @notice Recovers any ERC20 token accidentally sent to this contract, sent to msg.sender
     *  @param token The address of the token we are recovering
     *  @custom:security non-reentrant
     */
    function sweepToken(address token) external;
}


// File contracts/cygnus-core/interfaces/ICygnusBorrowControl.sol

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


// File contracts/cygnus-core/interfaces/ICygnusBorrowInterest.sol

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


// File contracts/cygnus-core/interfaces/ICygnusBorrowApprove.sol

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


// File contracts/cygnus-core/interfaces/ICygnusBorrowTracker.sol

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
     *  @return borrowRate The current per-second borrow rate stored for this shuttle. To get the borrow APY
     *          we must annualize this (i.e. borrowRate * SECONDS_PER_YEAR)
     */
    function borrowRate() external view returns (uint112);

    /**
     *  @return utilizationRate The current utilization rate for this shuttle
     */
    function utilizationRate() external view returns (uint256);

    /**
     *  @return lastAccrualTimestamp The unix timestamp stored of the last interest rate accrual
     */
    function lastAccrualTimestamp() external view returns (uint32);

    /**
     *  @notice This public view function is used to get the borrow balance of users based on stored data
     *  @notice It is used by CygnusCollateral and CygnusCollateralModel contracts
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


// File contracts/cygnus-core/interfaces/ICygnusBorrow.sol

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
     *  @return cygLPAmount The amount of tokens liquidated
     */
    function liquidate(address borrower, address liquidator) external returns (uint256 cygLPAmount);

    /**
     *  @notice This low level function should only be called from `CygnusAltair` contract only
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


// File contracts/cygnus-core/utils/Context.sol

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


// File contracts/cygnus-core/utils/ReentrancyGuard.sol

// g-Identifier: Unlicense
pragma solidity >=0.8.4;

/// @title ReentrancyGuard
/// @author Paul Razvan Berg
/// @notice Contract module that helps prevent reentrant calls to a function.
///
/// Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier available, which can be applied
/// to functions to make sure there are no nested (reentrant) calls to them.
///
/// Note that because there is a single `nonReentrant` guard, functions marked as `nonReentrant` may not
/// call one another. This can be worked around by making those functions `private`, and then adding
/// `external` `nonReentrant` entry points to them.
///
/// @dev Forked from OpenZeppelin
/// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/utils/ReentrancyGuard.sol
abstract contract ReentrancyGuard {
    /// CUSTOM ERRORS ///

    /// @notice Emitted when there is a reentrancy call.
    error ReentrantCall();

    /// PRIVATE STORAGE ///

    bool private notEntered;

    /// CONSTRUCTOR ///

    /// Storing an initial non-zero value makes deployment a bit more expensive but in exchange the
    /// refund on every call to nonReentrant will be lower in amount. Since refunds are capped to a
    /// percetange of the total transaction's gas, it is best to keep them low in cases like this one,
    /// to increase the likelihood of the full refund coming into effect.
    constructor() {
        notEntered = true;
    }

    /// MODIFIERS ///

    /// @notice Prevents a contract from calling itself, directly or indirectly.
    /// @dev Calling a `nonReentrant` function from another `nonReentrant` function
    /// is not supported. It is possible to prevent this from happening by making
    /// the `nonReentrant` function external, and make it call a `private`
    /// function that does the actual work.
    modifier nonReentrant() {
        // On the first call to nonReentrant, notEntered will be true.
        if (!notEntered) {
            revert ReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail.
        notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (https://eips.ethereum.org/EIPS/eip-2200).
        notEntered = true;
    }
}


// File contracts/cygnus-core/Erc20.sol

// g-Identifier: Unlicense
pragma solidity >=0.8.4;

// Dependencies



/// @title Erc20
/// @author Paul Razvan Berg
contract Erc20 is IErc20, Context, ReentrancyGuard {
    /// PUBLIC STORAGE ///

    /// @inheritdoc IErc20
    string public override name;

    /// @inheritdoc IErc20
    string public override symbol;

    /// @inheritdoc IErc20
    uint8 public immutable override decimals;

    /// @inheritdoc IErc20
    uint256 public override totalSupply;

    /// INTERNAL STORAGE ///

    /// @dev Internal mapping of balances.
    mapping(address => uint256) internal balances;

    /// @dev Internal mapping of allowances.
    mapping(address => mapping(address => uint256)) internal allowances;

    /// CONSTRUCTOR ///

    ///  they can only be set once during construction.
    /// @param name_ Erc20 name of this token.
    /// @param symbol_ Erc20 symbol of this token.
    /// @param decimals_ Erc20 decimal precision of this token.
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
    }

    /// PUBLIC CONSTANT FUNCTIONS ///

    /// @inheritdoc IErc20
    function allowance(address owner, address spender) public view override returns (uint256) {
        return allowances[owner][spender];
    }

    /// @inheritdoc IErc20
    function balanceOf(address account) public view virtual override returns (uint256) {
        return balances[account];
    }

    /// PUBLIC NON-CONSTANT FUNCTIONS ///

    /// @inheritdoc IErc20
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        approveInternal(_msgSender(), spender, amount);
        return true;
    }

    /// @inheritdoc IErc20
    function decreaseAllowance(address spender, uint256 subtractedAmount) public virtual override returns (bool) {
        uint256 newAllowance = allowances[_msgSender()][spender] - subtractedAmount;
        approveInternal(_msgSender(), spender, newAllowance);
        return true;
    }

    /// @inheritdoc IErc20
    function increaseAllowance(address spender, uint256 addedAmount) public virtual override returns (bool) {
        uint256 newAllowance = allowances[_msgSender()][spender] + addedAmount;
        approveInternal(_msgSender(), spender, newAllowance);
        return true;
    }

    /// @inheritdoc IErc20
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        transferInternal(_msgSender(), recipient, amount);
        return true;
    }

    /// @inheritdoc IErc20
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        transferInternal(sender, recipient, amount);

        uint256 currentAllowance = allowances[sender][_msgSender()];
        if (currentAllowance < amount) {
            revert Erc20__InsufficientAllowance(currentAllowance, amount);
        }
        unchecked {
            approveInternal(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /// INTERNAL NON-CONSTANT FUNCTIONS ///

    /// @notice Sets `amount` as the allowance of `spender`
    /// over the `owner`s tokens.
    /// @dev Emits an {Approval} event.
    ///
    /// Requirements:
    ///
    /// - `owner` cannot be the zero address.
    /// - `spender` cannot be the zero address.
    function approveInternal(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        if (owner == address(0)) {
            revert Erc20__ApproveOwnerZeroAddress();
        }
        if (spender == address(0)) {
            revert Erc20__ApproveSpenderZeroAddress();
        }

        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /// @notice Destroys `burnAmount` tokens from `holder`
    ///, reducing the token supply.
    /// @dev Emits a {Transfer} event.
    ///
    /// Requirements:
    ///
    /// - `holder` must have at least `amount` tokens.
    function burnInternal(address holder, uint256 burnAmount) internal {
        if (holder == address(0)) {
            revert Erc20__BurnZeroAddress();
        }

        // Burn the tokens.
        balances[holder] -= burnAmount;

        // Reduce the total supply.
        totalSupply -= burnAmount;

        emit Transfer(holder, address(0), burnAmount);
    }

    /// @notice Prints new tokens into existence and assigns them
    ///  to `beneficiary`, increasing the total supply.
    ///
    /// @dev Emits a {Transfer} event.
    ///
    /// Requirements:
    ///
    /// - The beneficiary's balance and the total supply cannot overflow.
    function mintInternal(address beneficiary, uint256 mintAmount) internal virtual {
        if (beneficiary == address(0)) {
            revert Erc20__MintZeroAddress();
        }

        /// Mint the new tokens.
        balances[beneficiary] += mintAmount;

        /// Increase the total supply.
        totalSupply += mintAmount;

        emit Transfer(address(0), beneficiary, mintAmount);
    }

    /// @notice Moves `amount` tokens from `sender` to `recipient`.
    ///
    /// @dev Emits a {Transfer} event.
    ///
    /// Requirements:
    ///
    /// - `sender` cannot be the zero address.
    /// - `recipient` cannot be the zero address.
    /// - `sender` must have a balance of at least `amount`.
    function transferInternal(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        if (sender == address(0)) {
            revert Erc20__TransferSenderZeroAddress();
        }
        if (recipient == address(0)) {
            revert Erc20__TransferRecipientZeroAddress();
        }

        uint256 senderBalance = balances[sender];
        if (senderBalance < amount) {
            revert Erc20__InsufficientBalance(senderBalance, amount);
        }
        unchecked {
            balances[sender] = senderBalance - amount;
        }

        balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }
}


// File contracts/cygnus-core/Erc20Permit.sol

// g-Identifier: Unlicense
// solhint-disable var-name-mixedcase
pragma solidity >=0.8.4;


/// @notice replaced chainId assembly code from original author

/// @title Erc20Permit
/// @author Paul Razvan Berg
contract Erc20Permit is IErc20Permit, Erc20 {
    /// PUBLIC STORAGE ///

    /// @inheritdoc IErc20Permit
    bytes32 public immutable override DOMAIN_SEPARATOR;

    /// @inheritdoc IErc20Permit
    bytes32 public constant override PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /// @inheritdoc IErc20Permit
    mapping(address => uint256) public override nonces;

    /// @inheritdoc IErc20Permit
    string public constant override version = "1";

    /// @inheritdoc IErc20Permit
    uint256 public override chainId = block.chainid;

    /// CONSTRUCTOR ///

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) Erc20(_name, _symbol, _decimals) {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                chainId,
                address(this)
            )
        );
    }

    /// PUBLIC NON-CONSTANT FUNCTIONS ///

    /// @inheritdoc IErc20Permit
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public override {
        if (owner == address(0)) {
            revert Erc20Permit__OwnerZeroAddress();
        }
        if (spender == address(0)) {
            revert Erc20Permit__SpenderZeroAddress();
        }
        if (deadline < block.timestamp) {
            revert Erc20Permit__PermitExpired(deadline);
        }

        // It's safe to use unchecked here because the nonce cannot overflow
        bytes32 hashStruct;

        unchecked {
            hashStruct = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline));
        }

        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hashStruct));
        address recoveredOwner = ecrecover(digest, v, r, s);

        if (recoveredOwner == address(0)) {
            revert Erc20Permit__RecoveredOwnerZeroAddress();
        }

        if (recoveredOwner != owner) {
            revert Erc20Permit__InvalidSignature(v, r, s);
        }

        approveInternal(owner, spender, value);
    }
}


// File contracts/cygnus-core/libraries/SafeTransferLib.sol

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


// File contracts/cygnus-core/libraries/PRBMath.sol

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


// File contracts/cygnus-core/libraries/PRBMathUD60x18.sol

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


// File contracts/cygnus-core/interfaces/IDenebOrbiter.sol

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
     *  @return shuttleId The ID of the lending pool
     */
    function collateralParameters()
        external
        returns (
            address factory,
            address underlying,
            address cygnusDai,
            uint256 shuttleId
        );

    /**
     *  @return COLLATERAL_INIT_CODE_HASH The init code hash of the collateral contract for this deployer
     */
    function COLLATERAL_INIT_CODE_HASH() external view returns (bytes32);

    /**
     *  @notice Function to deploy the collateral contract of a lending pool
     *  @param underlying The address of the underlying LP Token
     *  @param cygnusDai The address of the Cygnus borrow contract for this collateral
     *  @param shuttleId The ID of the lending pool
     *  @return collateral The address of the new deployed Cygnus collateral contract
     */
    function deployDeneb(
        address underlying,
        address cygnusDai,
        uint256 shuttleId
    ) external returns (address collateral);
}


// File contracts/cygnus-core/interfaces/IAlbireoOrbiter.sol

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
     *  @return shuttleId The ID of the shuttle we are deploying (shared by borrow and collateral)
     *  @return baseRatePerYear The base rate per year for this shuttle
     *  @return multiplier The log10 of the farm APY
     */
    function borrowParameters()
        external
        returns (
            address factory,
            address underlying,
            address collateral,
            uint256 shuttleId,
            uint256 baseRatePerYear,
            uint256 multiplier
        );

    /**
     *  @return BORROW_INIT_CODE_HASH The init code hash of the borrow contract for this deployer
     */
    function BORROW_INIT_CODE_HASH() external view returns (bytes32);

    /**
     *  @notice Function to deploy the borrow contract of a lending pool
     *  @param underlying The address of the underlying borrow token (address of DAI, USDc, etc.)
     *  @param collateral The address of the Cygnus collateral contract for this borrow contract
     *  @param shuttleId The ID of the shuttle we are deploying (shared by borrow and collateral)
     *  @param baseRatePerYear The base rate per year for this shuttle
     *  @param multiplier The log10 of the farm APY
     *  @return cygnusDai The address of the new borrow contract
     */
    function deployAlbireo(
        address underlying,
        address collateral,
        uint256 shuttleId,
        uint256 baseRatePerYear,
        uint256 multiplier
    ) external returns (address cygnusDai);
}


// File contracts/cygnus-core/interfaces/AggregatorV3Interface.sol

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


// File contracts/cygnus-core/interfaces/IDexPair.sol

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


// File contracts/cygnus-core/interfaces/IChainlinkNebulaOracle.sol

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


// File contracts/cygnus-core/interfaces/ICygnusFactory.sol

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
     *  @param denebOrbiter The address of the collateral orbiter for this dex
     *  @param borrowOrbiter The address of the borrow orbiter for this dex
     *
     */
    event InitializeOrbiters(
        bool status,
        uint256 orbitersLength,
        string orbitersName,
        IDenebOrbiter denebOrbiter,
        IAlbireoOrbiter borrowOrbiter
    );

    /**
     *  @notice Logs when orbiters get deleted from storage
     *  @param status Bool representing whether or not these orbiters are usable
     *  @param orbiterId The ID of the collateral & borrow orbiters
     *  @param orbiterName The name of the dex these orbiters were for
     *  @param denebOrbiter The address of the deleted collateral orbiter
     *  @param albireoOrbiter The address of the deleted borrow orbiter
     */
    event SwitchOrbiterStatus(
        bool status,
        uint256 orbiterId,
        string orbiterName,
        IAlbireoOrbiter albireoOrbiter,
        IDenebOrbiter denebOrbiter
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
     *  @custom:member denebOrbiter The address of the collateral deployer contract
     *  @custom:member albireoOrbiter The address of the borrow deployer contract
     */
    struct Orbiter {
        bool status;
        uint24 orbiterId;
        string orbiterName;
        IAlbireoOrbiter albireoOrbiter;
        IDenebOrbiter denebOrbiter;
    }

    /**
     *  @custom:struct Shuttle Official record of pools deployed by this factory
     *  @custom:member launched Whether or not the lending pool is initialized
     *  @custom:member shuttleId The ID of the lending pool
     *  @custom:member borrowable The address of the borrowing contract
     *  @custom:member collateral The address of the Cygnus collateral
     *  @custom:member borrowToken The address of the underlying of the borrow contract (DAI)
     *  @custom:member lpTokenPair The address of the underlying of the collateral contract (LP Token)
     */
    struct Shuttle {
        bool launched;
        uint24 shuttleId;
        address borrowable;
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
     *  @return albireoOrbiter The address of the borrow deployer contract
     *  @return denebOrbiter The address of the collateral deployer contract
     */
    function getOrbiters(uint256 _orbiterId)
        external
        view
        returns (
            bool status,
            uint24 orbiterId,
            string memory orbiterName,
            IAlbireoOrbiter albireoOrbiter,
            IDenebOrbiter denebOrbiter
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
            IAlbireoOrbiter albireoOrbiter,
            IDenebOrbiter denebOrbiter
        );

    /**
     *  @notice Official record of all lending pools deployed
     *  @param _lpTokenPair The address of the LP Token
     *  @param _orbiterId The ID of the orbiter for this LP Token
     *  @return launched Whether this pair exists or not
     *  @return shuttleId The ID of this shuttle
     *  @return borrowable The address of the borrow contract
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
            address borrowable,
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
            address borrowable,
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
     *  @return cygnusDai The address of the Cygnus borrow contract for this pool
     *  @return collateral The address of the Cygnus collateral contract for both borrow tokens
     *  @custom:security non-reentrant
     */
    function deployShuttle(
        address lpTokenPair,
        uint256 orbiterId,
        uint256 baseRate,
        uint256 multiplier
    ) external returns (address cygnusDai, address collateral);

    /**
     *  @notice Sets the new orbiters to deploy collateral and borrow contracts and stores orbiters in storage
     *  @param name The name of the strategy OR the dex these orbiters are for
     *  @param albireoOrbiter the address of this orbiter's borrow deployer
     *  @param denebOrbiter The address of this orbiter's collateral deployer
     *  @custom:security non-reentrant
     */
    function initializeOrbiter(
        string memory name,
        IAlbireoOrbiter albireoOrbiter,
        IDenebOrbiter denebOrbiter
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


// File contracts/cygnus-core/interfaces/IMiniChef.sol

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


// File contracts/cygnus-core/CygnusTerminal.sol

/*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════════

       █████████           ---======*.                                       🛸          .                    .⠀
      ███░░░░░███                                              📡                                         🌔   
     ███     ░░░  █████ ████  ███████ ████████   █████ ████  █████        ⠀
    ░███         ░░███ ░███  ███░░███░░███░░███ ░░███ ░███  ███░░      .     .⠀        🛰️   .               
    ░███          ░███ ░███ ░███ ░███ ░███ ░███  ░███ ░███ ░░█████       ⠀
    ░░███     ███ ░███ ░███ ░███ ░███ ░███ ░███  ░███ ░███  ░░░░███              .             .              .⠀
     ░░█████████  ░░███████ ░░███████ ████ █████ ░░████████ ██████       -----========*⠀
      ░░░░░░░░░    ░░░░░███  ░░░░░███░░░░ ░░░░░   ░░░░░░░░ ░░░░░░            .                            .⠀
                   ███ ░███  ███ ░███                .                 .         🛸           ⠀               
     .      *     ░░██████  ░░██████   .                         🛰️                 .          .                
                   ░░░░░░    ░░░░░░                                                 ⠀
       .                            .       .         ------======*             .                          .      ⠀

     https://cygnusdao.finance                                                          .                     .

    ═══════════════════════════════════════════════════════════════════════════════════════════════════════════

     Smart contracts to `go long` on your LP Token.

     Deposit LP Token, borrow DAI 

     Structure of all Cygnus Contracts

     Contract                        ⠀Interface                                             
        ├ 1. Libraries                   ├ 1. Custom Errors                                               
        ├ 2. Storage                     ├ 2. Custom Events
        │     ├ Private             ⠀    ├ 3. Constant Functions                          ⠀        
        │     ├ Internal                 │     ├ Public                            ⠀       
        │     └ Public                   │     └ External                        ⠀⠀⠀              
        ├ 3. Constructor                 └ 4. Non-Constant Functions  
        ├ 4. Modifiers              ⠀          ├ Public
        ├ 5. Constant Functions     ⠀          └ External
        │     ├ Private             ⠀                      
        │     ├ Internal            
        │     ├ Public              
        │     └ External            
        └ 6. Non-Constant Functions 
              ├ Private             
              ├ Internal            
              ├ Public              
              └ External            

    @dev: This is a fork of Impermax with some small edits. It should only be tested with Solidity >=0.8 as some 
          functions don't check for overflow/underflow and all errors are handled with the new `custom errors` 
          feature among other small things...                                                                    */

// g-Identifier: Unlicense
pragma solidity >=0.8.4;

// Dependencies


// Libraries


// Interfaces




/**
 *  @title  CygnusTerminal
 *  @author CygnusDAO
 *  @notice Contract used to mint Collateral and Borrow tokens. Both Collateral/Borrow arms of Cygnus mint here
 *          to get the vault token (CygDAI for DAI deposits or CygLP for LP Token deposits).
 *          It follows similar functionality to UniswapV2Pair with some small differences.
 *          We added only the `deposit` and `redeem` functions from the erc-4626 standard to save on byte size.
 */
contract CygnusTerminal is ICygnusTerminal, Erc20Permit {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. LIBRARIES
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:library PRBMathUD60x18 Fixed point 18 decimal math library, imports main library `PRBMath`
     */
    using PRBMathUD60x18 for uint256;

    /**
     *  @custom:library SafeTransferLib Solady`s library for low level handling of Erc20 tokens
     */
    using SafeTransferLib for address;

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. STORAGE
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Internal ───────────────────────────────────────────────  */

    /**
     *  @notice The initial exchange rate between underlying and pool tokens
     */
    uint256 internal constant INITIAL_EXCHANGE_RATE = 1e18;

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @inheritdoc ICygnusTerminal
     */
    uint256 public override totalBalance;

    /**
     *  @inheritdoc ICygnusTerminal
     */
    address public override underlying;

    /**
     *  @inheritdoc ICygnusTerminal
     */
    address public override hangar18;

    /**
     *  @inheritdoc ICygnusTerminal
     */
    uint256 public override shuttleId;

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTRUCTOR
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Constructs tokens for both Collateral and Borrow arms
     *  @dev We create another borrow permit for Borrow arm in CygnusBorrowApprove contract
     *  @param name_ Erc20 name of the Borrow/Collateral token
     *  @param symbol_ Erc20 symbol of the Borrow/Collateral token
     *  @param decimals_ Decimals of the Borrow/Collateral token (always 18)
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) Erc20Permit(name_, symbol_, decimals_) {}

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. MODIFIERS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:modifier update Updates the total balance var in terms of its underlying
     */
    modifier update() {
        _;
        updateInternal();
    }

    /**
     *  @custom:modifier cygnusAdmin Controls important parameters in both Collateral and Borrow contracts 👽
     */
    modifier cygnusAdmin() {
        isCygnusAdmin();
        _;
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            5. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Internal ───────────────────────────────────────────────  */

    /**
     *  @notice Internal check for admins only, checks factory for admin
     */
    function isCygnusAdmin() internal view {
        // Current admin from the factory
        address admin = ICygnusFactory(hangar18).admin();

        /// @custom:error MsgSenderNotAdmin Avoid unless caller is Cygnus Admin
        if (_msgSender() != admin) {
            revert CygnusTerminal__MsgSenderNotAdmin({ sender: _msgSender(), factoryAdmin: admin });
        }
    }

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @inheritdoc ICygnusTerminal
     */
    function exchangeRate() public virtual override returns (uint256) {
        // Gas savings if non-zero
        uint256 _totalSupply = totalSupply;

        // If there is no supply for this token return initial rate
        return _totalSupply == 0 ? INITIAL_EXCHANGE_RATE : totalBalance.div(_totalSupply);
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            6. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Internal ───────────────────────────────────────────────  */

    /**
     *  @notice Updates this contract's total balance in terms of its underlying
     */
    function updateInternal() internal virtual {
        // Match totalBalance state to balanceOf this contract
        totalBalance = IErc20(underlying).balanceOf(address(this));

        /// @custom:event Sync
        emit Sync(totalBalance);
    }

    /**
     *  @notice Internal hook for deposits into strategies
     *  @param assets The amount of assets deposited
     *  @param shares The amount of shares minted
     */
    function afterDepositInternal(uint256 assets, uint256 shares) internal virtual {}

    /**
     *  @notice Internal hook for withdrawals from strategies
     *  @param assets The amount of assets being withdrawn
     *  @param shares The amount of shares burnt
     */
    function beforeWithdrawInternal(uint256 assets, uint256 shares) internal virtual {}

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @inheritdoc ICygnusTerminal
     *  @custom:security non-reentrant
     */
    function deposit(uint256 assets, address recipient) external override nonReentrant update returns (uint256 shares) {
        // Get the amount of shares to mint
        shares = assets.div(exchangeRate());

        /// custom:error CantMintZeroShares Avoid minting no tokens
        if (shares <= 0) {
            revert CygnusTerminal__CantMintZeroShares();
        }

        // Transfer underlying from sender to this contract
        underlying.safeTransferFrom(_msgSender(), address(this), assets);

        // Mint tokens and emit Transfer event
        mintInternal(recipient, shares);

        // Deposit assets into the strategy (if any)
        afterDepositInternal(assets, shares);

        /// @custom:event Deposit
        emit Deposit(_msgSender(), recipient, assets, shares);
    }

    /**
     *  @inheritdoc ICygnusTerminal
     *  @custom:security non-reentrant
     */
    function redeem(
        uint256 shares,
        address recipient,
        address owner
    ) external override nonReentrant update returns (uint256 assets) {
        // Withdraw flow
        if (_msgSender() != owner) {
            // Check msg.sender's allowance
            uint256 allowed = allowances[owner][_msgSender()]; // Saves gas for limited approvals.

            // Reverts on underflow
            if (allowed != type(uint256).max) allowances[owner][_msgSender()] = allowed - shares;
        }

        // Get the amount of assets to redeem
        assets = shares.mul(exchangeRate());

        /// @custom:error CantRedeemZeroAssets Avoid redeeming 0 assets
        if (assets <= 0) {
            revert CygnusTerminal__CantRedeemZeroAssets();
        }
        /// @custom:error RedeemAmountInvalid Avoid redeeming if theres insufficient cash
        else if (assets > totalBalance) {
            revert CygnusTerminal__RedeemAmountInvalid({ assets: assets, totalBalance: totalBalance });
        }

        // Withdraw assets from the strategy (if any)
        beforeWithdrawInternal(assets, shares);

        // Burn shares
        burnInternal(owner, shares);

        // Optimistically transfer assets to recipient
        underlying.safeTransfer(recipient, assets);

        /// @custom:event Withdraw
        emit Withdraw(_msgSender(), recipient, owner, assets, shares);
    }

    /**
     *  @notice 👽
     *  @inheritdoc ICygnusTerminal
     *  @custom:security non-reentrant
     */
    function sweepToken(address token) external override nonReentrant update cygnusAdmin {
        /// @custom:error CantSweepUnderlying Avoid sweeping underlying
        if (token == underlying) {
            revert CygnusTerminal__CantSweepUnderlying({ token: token, underlying: underlying });
        }

        // Balance this contract has of the erc20 token we are recovering
        uint256 balance = IErc20(token).balanceOf(address(this));

        // Transfer token
        token.safeTransfer(_msgSender(), balance);
    }
}


// File contracts/cygnus-core/CygnusBorrowControl.sol

// g-Identifier: Unlicensed
pragma solidity >=0.8.4;

// Dependencies


// Interfaces

/**
 *  @title  CygnusBorrowControl Contract for controlling borrow settings
 *  @author CygnusDAO
 *  @notice Initializes Borrow Arm. Assigns name, symbol and decimals to CygnusTerminal for the CygDAI Token.
 *          This contract should be the only contract the Cygnus admin has control of, specifically to set the
 *          borrow tracker which tracks individual borrows to reward users in any token (if there is any),
 *          the reserve factor and the kink utilization rate.
 *
 *          The constructor stores the collateral address this pool is linked with, and only this address can
 *          be used as collateral to borrow this contract`s underlying.
 */
contract CygnusBorrowControl is ICygnusBorrowControl, CygnusTerminal("Cygnus: Borrow", "CygDAI", 18) {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. STORAGE
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    // ──────────────────────────── Important Addresses

    /**
     *  @inheritdoc ICygnusBorrowControl
     */
    address public immutable override collateral;

    /**
     *  @inheritdoc ICygnusBorrowControl
     */
    address public override cygnusBorrowTracker;

    // ───────────────────────────── Current pool rates

    /**
     *  @inheritdoc ICygnusBorrowControl
     */
    uint256 public override exchangeRateStored;

    /**
     *  @inheritdoc ICygnusBorrowControl
     */
    uint256 public override reserveFactor = 0.05e18;

    /**
     *  @inheritdoc ICygnusBorrowControl
     */
    uint256 public override kinkUtilizationRate = 0.85e18;

    /**
     *  @inheritdoc ICygnusBorrowControl
     */
    uint256 public override kinkMultiplier = 3;

    // ─────────────────────── Min/Max this pool allows

    /**
     *  @inheritdoc ICygnusBorrowControl
     */
    uint256 public constant override BASE_RATE_MAX = 0.10e18;

    /**
     *  @inheritdoc ICygnusBorrowControl
     */
    uint256 public constant override RESERVE_FACTOR_MAX = 0.20e18;

    /**
     *  @inheritdoc ICygnusBorrowControl
     */
    uint256 public constant override KINK_UTILIZATION_RATE_MIN = 0.50e18;

    /**
     *  @inheritdoc ICygnusBorrowControl
     */
    uint256 public constant override KINK_UTILIZATION_RATE_MAX = 0.95e18;

    /**
     *  @inheritdoc ICygnusBorrowControl
     */
    uint256 public constant override KINK_MULTIPLIER_MAX = 10;

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. CONSTRUCTOR
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Constructs the Borrow arm of the pool. It assigns the factory, the underlying asset (DAI) and the
     *          collateral contract for this borrow token. Interest rate model is assigned in the next child contract
     */
    constructor() {
        // Get factory, underlying and collateral adddresses
        (
            hangar18,
            underlying,
            collateral,
            shuttleId, /* baseRate */ /* multiplier */
            ,

        ) = IAlbireoOrbiter(_msgSender()).borrowParameters();

        // Match initial exchange rate
        exchangeRateStored = INITIAL_EXCHANGE_RATE;

        // Assurance
        totalSupply = 0;
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            5. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Internal ───────────────────────────────────────────────  */

    /**
     *  @notice Checks if new parameter is within range when updating interest rate model
     *  @param min The minimum value allowed for the parameter that is being updated
     *  @param max The maximum value allowed for the parameter that is being updated
     *  @param parameter The value of the parameter that is being updated
     */
    function validRange(
        uint256 min,
        uint256 max,
        uint256 parameter
    ) internal pure {
        /// @custom:error Avoid outside range
        if (parameter < min || parameter > max) {
            revert CygnusBorrowControl__ParameterNotInRange({ minRange: min, maxRange: max, value: parameter });
        }
    }

    /**
     *  @return The uint32 block timestamp
     */
    function getBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp);
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            6. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice 👽
     *  @inheritdoc ICygnusBorrowControl
     *  @custom:security non-reentrant
     */
    function setCygnusBorrowTracker(address newBorrowTracker) external override nonReentrant cygnusAdmin {
        // Need the option of setting the borrow tracker as address(0) to remove rewards pool
        /// @custom:error BorrowTrackerAlreadySet Avoid Duplicate
        if (newBorrowTracker == cygnusBorrowTracker) {
            revert CygnusBorrowControl__BorrowTrackerAlreadySet({
                currentTracker: cygnusBorrowTracker,
                newTracker: newBorrowTracker
            });
        }

        // Old borrow tracker
        address oldBorrowTracker = cygnusBorrowTracker;

        // Checks admin before, assign borrow tracker
        cygnusBorrowTracker = newBorrowTracker;

        /// @custom:event NewCygnusBorrowTracker
        emit NewCygnusBorrowTracker(oldBorrowTracker, newBorrowTracker);
    }

    /**
     *  @notice 👽
     *  @inheritdoc ICygnusBorrowControl
     *  @custom:security non-reentrant
     */
    function setReserveFactor(uint256 newReserveFactor) external override nonReentrant cygnusAdmin {
        // Check if parameter is within range allowed
        validRange(0, RESERVE_FACTOR_MAX, newReserveFactor);

        // Old reserve factor
        uint256 oldReserveFactor = reserveFactor;

        // Update reserve factor
        reserveFactor = newReserveFactor;

        /// @custom:event NewReserveFactor
        emit NewReserveFactor(oldReserveFactor, newReserveFactor);
    }

    /**
     *  @notice 👽
     *  @inheritdoc ICygnusBorrowControl
     *  @custom:security non-reentrant
     */
    function setKinkUtilizationRate(uint256 newKinkUtilizationRate) external override nonReentrant cygnusAdmin {
        // Check if parameter is within range allowed
        validRange(KINK_UTILIZATION_RATE_MIN, KINK_UTILIZATION_RATE_MAX, newKinkUtilizationRate);

        // Old kink utilization rate
        uint256 oldKinkUtilizationRate = kinkUtilizationRate;

        // Update kink utilization rate
        kinkUtilizationRate = newKinkUtilizationRate;

        /// @custom:event NewKinkUtilizationRate
        emit NewKinkUtilizationRate(oldKinkUtilizationRate, newKinkUtilizationRate);
    }
}


// File contracts/cygnus-core/CygnusBorrowApprove.sol

// g-Identifier: Unlicensed
pragma solidity >=0.8.4;

// Dependencies


/**
 *  @title  CygnusBorrowApprove
 *  @notice Contract for approving borrows for the borrow arm of the lending pool and updating borrow allowances.
 *          Before any borrow, the borrower must have positive borrowAllowances set by this contract.
 */
contract CygnusBorrowApprove is ICygnusBorrowApprove, CygnusBorrowControl {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. STORAGE
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @inheritdoc ICygnusBorrowApprove
     */
    bytes32 public constant override BORROW_PERMIT_TYPEHASH =
        keccak256("BorrowPermit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /**
     *  @inheritdoc ICygnusBorrowApprove
     */
    mapping(address => mapping(address => uint256)) public override borrowAllowances;

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            6. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Private ────────────────────────────────────────────────  */

    /**
     *  @notice Safe private function which updates allowances after doing sufficient checks
     *  @param owner The address of the owner of the tokens
     *  @param spender The address of the person given the allowance
     *  @param amount The max amount of tokens the spender can spend
     */
    function borrowApproveInternal(
        address owner,
        address spender,
        uint256 amount
    ) private {
        borrowAllowances[owner][spender] = amount;

        /// @custom:event BorrowApproved
        emit BorrowApproval(owner, spender, amount);
    }

    /*  ────────────────────────────────────────────── Internal ────────────────────────────────────────────────  */

    /**
     *  @notice Internal function which does the sufficient checks to approve allowances
     *  @notice If all checks pass, call private approve function. Used by child CygnusBorrow
     *  @param owner The address of the owner of the tokens
     *  @param spender The address of the person given the allowance
     *  @param amount The max amount of tokens the spender can spend
     */
    function borrowApproveUpdate(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        uint256 currentAllowance = borrowAllowances[owner][spender];

        /// custom:error Avoid self
        if (owner == spender) {
            revert CygnusBorrowApprove__OwnerIsSpender({ owner: owner, spender: spender });
        }
        /// @custom:error OwnerZeroAddress Avoid the owner being the zero address
        else if (owner == address(0)) {
            revert CygnusBorrowApprove__OwnerZeroAddress({ owner: owner, spender: spender });
        }
        /// @custom:error SpenderZeroAddress Avoid the spender being the zero address
        else if (spender == address(0)) {
            revert CygnusBorrowApprove__SpenderZeroAddress({ owner: owner, spender: spender });
        }
        /// custom:error BorrowNotAllowed Avoid borrowing more than allowwed
        else if (currentAllowance < amount) {
            revert CygnusBorrowApprove__BorrowNotAllowed({ borrowAllowance: currentAllowance, borrowAmount: amount });
        }

        // Updates the borrow allowance in the next function call
        borrowApproveInternal(owner, spender, currentAllowance - amount);
    }

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @inheritdoc ICygnusBorrowApprove
     */
    function borrowApprove(address spender, uint256 value) external override returns (bool) {
        // Safe internal Approve
        borrowApproveInternal(_msgSender(), spender, value);

        return true;
    }

    /**
     *  @inheritdoc ICygnusBorrowApprove
     */
    function borrowPermit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        /// @custom:error OwnerZeroAddress Avoid owner being the zero address
        if (owner == address(0)) {
            revert CygnusBorrowApprove__OwnerZeroAddress({ owner: owner, spender: spender });
        }
        /// @custom:error SpenderZeroAddress Avoid spender being the zero address
        else if (spender == address(0)) {
            revert CygnusBorrowApprove__SpenderZeroAddress({ owner: owner, spender: spender });
        }
        /// @custom:error PermitExpired Avoid transacting past deadline
        else if (deadline < getBlockTimestamp()) {
            revert CygnusBorrowApprove__PermitExpired({
                transactDeadline: deadline,
                currentTimestamp: getBlockTimestamp()
            });
        }

        // It's safe to use unchecked here because the nonce cannot realistically overflow, ever.
        bytes32 hashStruct;

        unchecked {
            hashStruct = keccak256(
                abi.encode(BORROW_PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline)
            );
        }

        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hashStruct));

        address recoveredOwner = ecrecover(digest, v, r, s);

        /// @custom:error RecoveredOwnerZeroAddress Avoid the zero address being the recovered owner
        if (recoveredOwner == address(0)) {
            revert CygnusBorrowApprove__RecoveredOwnerZeroAddress(recoveredOwner);
        }
        /// @custom:error InvalidSignature Avoid invalid signature
        else if (recoveredOwner != owner) {
            revert CygnusBorrowApprove__InvalidSignature({ v: v, r: r, s: s });
        }

        // Finally approve internally
        borrowApproveInternal(owner, spender, value);
    }
}


// File contracts/cygnus-core/CygnusBorrowInterest.sol

// g-Identifier: Unlicensed
pragma solidity >=0.8.4;

// Dependencies


// Libraries

// Interfaces

/**
 *  @title  CygnusBorrowInterest Interest rate model contract for Cygnus
 *  @author CygnusDAO
 *  @notice Constructs the interest rate model used and updates the `per-second` rates. It loads the parameters
 *          passed to the factory from the struct of the borrow deployer to avoid setting constructor arguments,
 *          keeping the same bytecode for each borrow contract. `CygnusBorrowControl` loads the struct to store
 *          the factory, the underlying (DAI) and collateral addresses. This contract loads the struct again
 *          to set the per-second interest rate parameters for interest accruals in the next child contract.
 */
contract CygnusBorrowInterest is ICygnusBorrowInterest, CygnusBorrowControl {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. LIBRARIES
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:library PRBMathUD60x18 for uint256 fixed point math, also imports the main library `PRBMath`.
     */
    using PRBMathUD60x18 for uint256;

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. STORAGE
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @inheritdoc ICygnusBorrowInterest
     */
    uint256 public override baseRatePerSecond;

    /**
     *  @inheritdoc ICygnusBorrowInterest
     */
    uint256 public override multiplierPerSecond;

    /**
     *  @inheritdoc ICygnusBorrowInterest
     */
    uint256 public override jumpMultiplierPerSecond;

    /**
     *  @inheritdoc ICygnusBorrowInterest
     */
    uint32 public constant override SECONDS_PER_YEAR = 31536000;

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTRUCTOR
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Constructs the Interest Rate model. Load the parameters passed from the factory again to initialize
     *          the model.
     */
    constructor() {
        (
            ,
            ,
            ,
            ,
            /* factory */
            /* underlying */
            /* collateral */
            /* shuttleId */
            uint256 baseRate,
            uint256 multiplier
        ) = IAlbireoOrbiter(_msgSender()).borrowParameters();

        // Update the interest rate model and do min/max checks from CygnusBorrowControl
        updateJumpRateModelInternal(baseRate, multiplier, kinkMultiplier);
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            5. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Internal ───────────────────────────────────────────────  */

    /**
     *  @dev This should only be accessible from the child contract CygnusBorrowTracker
     *  @param cash Total unused funds in this pool
     *  @param borrows Total amount of borrowed funds in this pool
     *  @param reserves Total amount the protocol keeps as reserves in this pool
     */
    function getBorrowRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves
    ) internal view returns (uint256) {
        // Utilization rate (borrows * scale) / ((cash + borrows) - reserves)
        uint256 util = borrows.div((cash + borrows) - reserves);

        // If utilization <= kink return normal rate
        if (util <= kinkUtilizationRate) {
            return util.mul(multiplierPerSecond) + baseRatePerSecond;
        }

        // else return normal rate + kink rate
        uint256 normalRate = kinkUtilizationRate.mul(multiplierPerSecond) + baseRatePerSecond;

        // Get the excess utilization rate
        uint256 excessUtil = util - kinkUtilizationRate;

        // Return per second borrow rate
        return excessUtil.mul(jumpMultiplierPerSecond) + normalRate;
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            6. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Private ────────────────────────────────────────────────  */

    /**
     *  @notice Updates the parameters of the interest rate model and writes to storage
     *  @dev Does necessary checks internally. Reverts in case of failing checks
     *  @param baseRatePerYear_ The approximate target base APR, as a mantissa (scaled by 1e18)
     *  @param multiplierPerYear_ The rate of increase in interest rate wrt utilization (scaled by 1e18)
     *  @param kinkMultiplier_ The increase to farmApy once kink utilization is reached
     */
    function updateJumpRateModelInternal(
        uint256 baseRatePerYear_,
        uint256 multiplierPerYear_,
        uint256 kinkMultiplier_
    ) private {
        // Internal parameter check for BaseRate to not exceed maximum allowed
        validRange(0, BASE_RATE_MAX, baseRatePerYear_);

        // Internal parameter check for the Kink point to not be below minimum or above maximum allowed
        validRange(1, KINK_MULTIPLIER_MAX, kinkMultiplier_);

        // Update kink multiplier
        kinkMultiplier = kinkMultiplier_;

        // Calculate the Base Rate per second and update to storage
        baseRatePerSecond = baseRatePerYear_ / SECONDS_PER_YEAR;

        // Calculate the Farm Multiplier per second and update to storage
        multiplierPerSecond = multiplierPerYear_.div(SECONDS_PER_YEAR * kinkUtilizationRate);

        // Calculate the Jump Multiplier per second and update to storage
        jumpMultiplierPerSecond = PRBMath.mulDiv(multiplierPerYear_, kinkMultiplier_, SECONDS_PER_YEAR).div(
            kinkUtilizationRate
        );

        /// @custom:event NewInterestParameter
        emit NewInterestRateParameters(baseRatePerYear_, multiplierPerYear_, kinkMultiplier_);
    }

    /*  ───────────────────────────────────────────── External ────────────────────────────────────────────────  */

    /**
     *  @notice 👽
     *  @inheritdoc ICygnusBorrowInterest
     *  @custom:security non-reentrant
     */
    function updateJumpRateModel(
        uint256 newBaseRatePerYear,
        uint256 newMultiplierPerYear,
        uint256 newKinkMultiplier
    ) external override cygnusAdmin nonReentrant {
        // Update Per second rates
        updateJumpRateModelInternal(newBaseRatePerYear, newMultiplierPerYear, newKinkMultiplier);
    }
}


// File contracts/cygnus-core/interfaces/ICygnusFarmingPool.sol

// g-Identifier: Unlicensed
pragma solidity >=0.8.4;

interface ICygnusFarmingPool {
    function trackBorrow(
        address borrower,
        uint256 borrowBalance,
        uint256 borrowIndex
    ) external;
}


// File contracts/cygnus-core/CygnusBorrowTracker.sol

// g-Identifier: Unlicensed
pragma solidity >=0.8.4;

// Dependencies



// Libraries

// Interfaces

/**
 *  @title  CygnusBorrowTracker Contract that accrues interest to borrows/reserves and stores borrow data of each user
 *  @author CygnusDAO
 *  @notice Contract that accrues interest and tracks borrows for this shuttle. It accrues interest on any borrow,
 *          liquidation or repay. The Accrue function uses 2 memory slots on each call to store reserves and borrows.
 *          It is also used by CygnusCollateral contracts to get the borrow balance of each user to calculate current
 *          debt ratios, liquidity or shortfall
 */
contract CygnusBorrowTracker is ICygnusBorrowTracker, CygnusBorrowInterest, CygnusBorrowApprove {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. LIBRARIES
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:library PRBMathUD60x18 Library for uint256 fixed point math, also imports the main library `PRBMath`
     */
    using PRBMathUD60x18 for uint256;

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. STORAGE
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Internal ───────────────────────────────────────────────  */

    /**
     *  @custom:struct BorrowSnapshot Container for individual user's borrow balance information
     *  @custom:member principal Total balance (with accrued interest) as of the most recent action
     *  @custom:member interestIndex Global borrowIndex as of the most recent balance-changing action
     */
    struct BorrowSnapshot {
        uint112 principal;
        uint112 interestIndex;
    }

    /**
     *  @notice Internal mapping of account addresses to outstanding borrow balances
     */
    mapping(address => BorrowSnapshot) internal borrowBalances;

    /**
     *  @notice Internal variable to keep track of reserve mints used by CygnusBorrow contract to add to
     *          `totalReserves`. We keep track of it internally to avoid using `balanceOf` (could break accounting)
     *           or avoid rounding errors by calculating with exchange rates
     */
    uint256 internal mintedReserves;

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @inheritdoc ICygnusBorrowTracker
     */
    uint128 public override totalReserves;

    /**
     *  @inheritdoc ICygnusBorrowTracker
     */
    uint128 public override totalBorrows;

    /**
     *  @inheritdoc ICygnusBorrowTracker
     */
    uint112 public override borrowIndex;

    /**
     *  @inheritdoc ICygnusBorrowTracker
     */
    uint112 public override borrowRate;

    /**
     *  @inheritdoc ICygnusBorrowTracker
     */
    uint32 public override lastAccrualTimestamp;

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTRUCTOR
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Constructs the borrow tracker
     */
    constructor() {
        // Set initial borrow index to 1
        borrowIndex = 1e18;

        // Set last accrual timestamp to deployment time
        lastAccrualTimestamp = uint32(block.timestamp);
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. MODIFIERS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Accrues interests to all borrows and reserves
     */
    modifier accrue() {
        accrueInterest();
        _;
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            5. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @dev It is used by CygnusCollateral and CygnusCollateralModel contracts.
     *  @inheritdoc ICygnusBorrowTracker
     */
    function getBorrowBalance(address borrower) public view override returns (uint256) {
        // memory struct for this borrower
        BorrowSnapshot memory borrowSnapshot = borrowBalances[borrower];

        // If interestIndex = 0 then borrowBalance is 0, return 0 instead of fail division
        if (borrowSnapshot.interestIndex == 0) {
            return 0;
        }

        // Calculate new borrow balance with the interest index
        return
            PRBMath.mulDiv(
                uint256(borrowSnapshot.principal),
                uint256(borrowIndex),
                uint256(borrowSnapshot.interestIndex)
            );
    }

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @inheritdoc ICygnusBorrowTracker
     */
    function utilizationRate() external view override returns (uint256) {
        // Return the current utilization rate
        return uint256(totalBorrows).div((totalBalance + uint256(totalBorrows)) - totalReserves);
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            6. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Internal ───────────────────────────────────────────────  */

    /**
     *  @notice Track borrows for borrow rewards (if any)
     *  @param borrower The address of the borrower after updating the borrow snapshot
     *  @param accountBorrows Record of this borrower's total borrows up to this point
     *  @param borrowIndexStored Borrow index stored up to this point
     */
    function trackBorrowInternal(
        address borrower,
        uint256 accountBorrows,
        uint256 borrowIndexStored
    ) internal {
        address _cygnusBorrowTracker = cygnusBorrowTracker;

        // If not initialized return
        if (_cygnusBorrowTracker == address(0)) {
            return;
        }

        // Pass to farming pool
        ICygnusFarmingPool(_cygnusBorrowTracker).trackBorrow(borrower, accountBorrows, borrowIndexStored);
    }

    /**
     *  @notice Record keeping private function for all borrows, repays and liquidations
     *  @param borrower Address of the borrower
     *  @param borrowAmount The amount of the underlying to update
     *  @param repayAmount The amount to repay
     *  @return accountBorrowsPrior Record of account's total borrows before this event
     *  @return accountBorrows Record of account's total borrows (accountBorrowsPrior + borrowAmount)
     *  @return totalBorrowsStored Record of the protocol's cummulative total borrows after this event
     */
    function updateBorrowInternal(
        address borrower,
        uint256 borrowAmount,
        uint256 repayAmount
    )
        internal
        returns (
            uint256 accountBorrowsPrior,
            uint256 accountBorrows,
            uint256 totalBorrowsStored
        )
    {
        // Internal view function to get borrower's balance, if borrower's interestIndex = 0 it returns 0.
        accountBorrowsPrior = getBorrowBalance(borrower);

        // if borrow amount == repayAmount, accountBorrowsPrior == accountBorrows
        if (borrowAmount == repayAmount) {
            return (accountBorrowsPrior, accountBorrowsPrior, totalBorrows);
        }

        // The current borrow index
        uint112 borrowIndexStored = borrowIndex;

        // Increase the borrower's account borrows and store it in snapshot
        if (borrowAmount > repayAmount) {
            // The borrowBalance and borrowIndex of the borrower
            BorrowSnapshot storage borrowSnapshot = borrowBalances[borrower];

            // Calculate the actual amount to increase
            uint256 increaseBorrowAmount = borrowAmount - repayAmount;

            // User's borrow balance + new borrow amount
            accountBorrows = accountBorrowsPrior + increaseBorrowAmount;

            // Update the snapshot record of the borrower's principal
            borrowSnapshot.principal = uint112(accountBorrows);

            // Update the snapshot record of the present borrow index
            borrowSnapshot.interestIndex = borrowIndexStored;

            // Protocol's Total borrows
            totalBorrowsStored = uint256(totalBorrows) + increaseBorrowAmount;

            // Update total borrows to storage
            totalBorrows = uint128(totalBorrowsStored);
        }
        // Decrease the borrower's account borrows and store it in the snapshot
        else {
            // Get borrowBalance and borrowIndex of borrower
            BorrowSnapshot storage borrowSnapshot = borrowBalances[borrower];

            // Calculate the actual amount to decrease
            uint256 decreaseBorrowAmount = repayAmount - borrowAmount;

            // Never underflows
            // If the decrease amount is >= user's prior borrows then user borrows is 0, else return the difference
            unchecked {
                accountBorrows = accountBorrowsPrior > decreaseBorrowAmount
                    ? accountBorrowsPrior - decreaseBorrowAmount
                    : 0;
            }

            // Update the snapshot record of the borrower's principal their new balance
            borrowSnapshot.principal = uint112(accountBorrows);

            // If no account borrows then interest index is 0
            borrowSnapshot.interestIndex = accountBorrows == 0 ? 0 : borrowIndexStored;

            // Actual decrease amount checked
            uint256 actualDecreaseAmount = accountBorrowsPrior - accountBorrows;

            // Total protocol borrows and gas savings
            totalBorrowsStored = totalBorrows;

            // Never underflows
            // Condition check to update protocols total borrows
            unchecked {
                totalBorrowsStored = totalBorrowsStored > actualDecreaseAmount
                    ? totalBorrowsStored - actualDecreaseAmount
                    : 0;
            }

            // Update total protocol borrows
            totalBorrows = uint128(totalBorrowsStored);
        }
        // Track borrows
        trackBorrowInternal(borrower, accountBorrows, borrowIndexStored);
    }

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @inheritdoc ICygnusBorrowTracker
     */
    function accrueInterest() public override {
        // Get the present timestamp
        uint32 currentTimestamp = getBlockTimestamp();

        // Get the last accrual timestamp
        uint32 accrualTimestampStored = lastAccrualTimestamp;

        // If present timestamp is the same as the last accrual timestamp, return and do nothing
        if (accrualTimestampStored == currentTimestamp) {
            return;
        }

        // Store current timestamp as last accrual and start accrue
        lastAccrualTimestamp = currentTimestamp;

        // Time elapsed between present timestamp and last accrued period
        uint32 timeElapsed = currentTimestamp - accrualTimestampStored;

        // ──────────────────── Load values from storage ────────────────────────

        // Total borrows stored
        uint256 totalBorrowsStored = totalBorrows;

        // Protocol Reserves
        uint256 reservesStored = totalReserves;

        // Total balance of underlying held by this contract
        uint256 cashStored = totalBalance;

        // Current borrow index
        uint256 borrowIndexStored = borrowIndex;

        // ──────────────────────────────────────────────────────────────────────

        // Return if no borrows
        if (totalBorrowsStored == 0) {
            return;
        }

        // 1. Get per-second BorrowRate
        uint256 borrowRateStored = getBorrowRate(cashStored, totalBorrowsStored, reservesStored);

        // 2. Multiply BorrowAPR by the time elapsed
        uint256 interestFactor = borrowRateStored * timeElapsed;

        // 3. Calculate the interest accumulated in this time elapsed
        uint256 interestAccumulated = interestFactor.mul(totalBorrowsStored);

        // 4. Add the interest accumulated to total borrows
        totalBorrowsStored += interestAccumulated;

        // 5. Add interest to total reserves (reserveFactor * interestAccumulated / scale) + reservesStored
        reservesStored += reserveFactor.mul(interestAccumulated);

        // 6. Update the borrow index ( new_index = index + (interestfactor * index / 1e18) )
        borrowIndexStored += interestFactor.mul(borrowIndex);

        // ─── Store values to storage: 2 memory slots with lastAccrualTime ─────

        // Store total borrows
        totalBorrows = uint128(totalBorrowsStored);

        // Total reserves
        totalReserves = uint128(reservesStored);

        // Borrow rate
        borrowRate = uint112(borrowRateStored);

        // New borrow index
        borrowIndex = uint112(borrowIndexStored);

        // ──────────────────────────────────────────────────────────────────────

        /// @custom:event AccrueInterest
        emit AccrueInterest(cashStored, interestAccumulated, borrowIndexStored, totalBorrowsStored, borrowRateStored);
    }

    /**
     *  @inheritdoc ICygnusBorrowTracker
     */
    function trackBorrow(address borrower) external override {
        // Pass to farming pool
        trackBorrowInternal(borrower, getBorrowBalance(borrower), borrowIndex);
    }
}


// File contracts/cygnus-core/interfaces/ICygnusCollateralControl.sol

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


// File contracts/cygnus-core/interfaces/IDexRouter.sol

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


// File contracts/cygnus-core/interfaces/ICygnusCollateralVoid.sol

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


// File contracts/cygnus-core/interfaces/ICygnusCollateralModel.sol

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


// File contracts/cygnus-core/interfaces/ICygnusCollateral.sol

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
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @param borrower The address of the borrower
     *  @param redeemAmount The amount to redeem
     *  @return Whether the user `from` can redeem - if user has shortfall, debt must be repaid first
     */
    function canRedeem(address borrower, uint256 redeemAmount) external returns (bool);

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @dev This should be called from `borrowable` contract
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


// File contracts/cygnus-core/interfaces/ICygnusAltairCall.sol

// g-Identifier: Unlicensed
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


// File contracts/cygnus-core/CygnusBorrow.sol

// g-Identifier: Unlicensed
pragma solidity >=0.8.4;

// Dependencies


// Libraries


// Interfaces





/**
 *  @title CygnusBorrow Main borrow contract for Cygnus which handles borrows, liquidations and reserves
 */
contract CygnusBorrow is ICygnusBorrow, CygnusBorrowTracker {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. LIBRARIES
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:library SafeErc20 Low level handling of Erc20 tokens
     */
    using SafeTransferLib for address;

    /**
     *  @custom:library PRBMathUD60x18 Fixed point 18 decimal math library, imports main library `PRBMath`
     */
    using PRBMathUD60x18 for uint256;

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
         6. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Internal ───────────────────────────────────────────────  */

    /**
     *  @notice mints reserves to CygnusReservesManager. Uses the mintedReserves variable to keep internal track
     *          of reserves instead of balanceOf
     *  @param _exchangeRate The latest calculated exchange rate (totalBalance / totalSupply) not yet stored
     *  @return Latest exchange rate
     */
    function mintReservesInternal(uint256 _exchangeRate) internal returns (uint256) {
        // Get current exchange rate stored for borrow contract
        uint256 _exchangeRateLast = exchangeRateStored;

        // Calculate new exchange rate, if different to last mint reserves
        if (_exchangeRate > _exchangeRateLast) {
            // Calculate new exchange rate taking reserves int oaccount
            uint256 newExchangeRate = _exchangeRate - ((_exchangeRate - _exchangeRateLast).mul(reserveFactor));

            // Calculate new reserves if any
            uint256 newReserves = totalReserves - mintedReserves;

            // if there are no new reserves to mint, just return exchangeRate
            if (newReserves == 0) {
                return _exchangeRate;
            }

            // Mint new reserves and update the exchange rate
            address daoReserves = ICygnusFactory(hangar18).daoReserves();

            // Safe internal mint
            mintInternal(daoReserves, newReserves);

            // Add reserves
            mintedReserves += newReserves;

            // Update exchange rate
            exchangeRateStored = newExchangeRate;

            // Return new exchange rate
            return newExchangeRate;
        }
        // Else return the previous exchange rate
        else return _exchangeRate;
    }

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @notice Overrides the previous exchange rate from CygnusTerminal
     *  @inheritdoc ICygnusBorrow
     */
    function exchangeRate() public override(ICygnusBorrow, ICygnusTerminal) accrue returns (uint256) {
        // Save SLOAD if non zero
        uint256 _totalSupply = totalSupply;

        // If there are no tokens in circulation, return initial (1e18), else calculate new exchange rate
        if (_totalSupply == 0) {
            return INITIAL_EXCHANGE_RATE;
        }

        // newExchangeRate = (totalBalance + totalBorrows - reserves) / totalSupply
        // Factor in reserves in next mint function
        uint256 _totalBalance = totalBalance + totalBorrows;

        // totalBalance * scale / total supply
        uint256 _exchangeRate = _totalBalance.div(_totalSupply);

        // Check if there are new reserves to mint and thus new exchange rate, else just returns this _exchangeRate
        return mintReservesInternal(_exchangeRate);
    }

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @dev This low level function should only be called from `Altair` contract only
     *  @inheritdoc ICygnusBorrow
     *  @custom:security non-reentrant
     */
    function borrow(
        address borrower,
        address receiver,
        uint256 borrowAmount,
        bytes calldata data
    ) external override nonReentrant update accrue {
        // Gas savings
        uint256 totalBalanceStored = totalBalance;

        /// @custom:error BorrowExceedsTotalBalance Avoid borrowing more than shuttle's balance
        if (borrowAmount > totalBalanceStored) {
            revert CygnusBorrow__BorrowExceedsTotalBalance({
                invalidBorrowAmount: borrowAmount,
                contractBalance: totalBalanceStored
            });
        }

        // Check borrow allowance at Cygnus Borrow Approve
        borrowApproveUpdate(borrower, _msgSender(), borrowAmount);

        // Optimistically transfer borrowAmount to `receiver`
        if (borrowAmount > 0) {
            underlying.safeTransfer(receiver, borrowAmount);
        }

        // For leverage functionality pass data to the router
        if (data.length > 0) {
            ICygnusAltairCall(receiver).altairBorrow_O9E(_msgSender(), borrower, borrowAmount, data);
        }

        // Get total balance of the underlying asset
        uint256 balance = IErc20(underlying).balanceOf(address(this));

        // Calculate the user's amount outstanding
        uint256 repayAmount = (balance + borrowAmount) - totalBalanceStored;

        // Update internal record for `borrower` at Cygnus Borrow Tracker
        (uint256 accountBorrowsPrior, uint256 accountBorrows, uint256 totalBorrowsStored) = updateBorrowInternal(
            borrower,
            borrowAmount,
            repayAmount
        );

        // If this is a borrow, check borrower's current liquidity/shortfall
        if (borrowAmount > repayAmount) {
            // Check if user can borrow and updates collateral totalBalance
            bool userCanBorrow = ICygnusCollateral(collateral).canBorrow_J2u(borrower, address(this), accountBorrows);

            /// @custom:error InsufficientLiquidity Avoid if borrower has insufficient liquidity for this `borrowAmount`
            if (!userCanBorrow) {
                revert CygnusBorrow__InsufficientLiquidity({
                    cygnusCollateral: collateral,
                    borrower: borrower,
                    borrowerBalance: accountBorrows
                });
            }
        }

        /// @custom:event Borrow
        emit Borrow(
            _msgSender(),
            receiver,
            borrower,
            borrowAmount,
            repayAmount,
            accountBorrowsPrior,
            accountBorrows,
            totalBorrowsStored
        );
    }

    /**
     *  @dev This low level function should only be called from `Altair` contract only
     *  @inheritdoc ICygnusBorrow
     *  @custom:security non-reentrant
     */
    function liquidate(address borrower, address liquidator)
        external
        override
        nonReentrant
        update
        accrue
        returns (uint256 cygLPAmount)
    {
        // Latest balance after accrue's sync
        uint256 balance = IErc20(underlying).balanceOf(address(this));

        // Borrow balance
        uint256 borrowerBalance = getBorrowBalance(borrower);

        // Get amount liquidator is repaying
        uint256 repayAmount = balance - totalBalance;

        // Avoid repaying more than borrower's borrow balance
        uint256 actualRepayAmount = borrowerBalance < repayAmount ? borrowerBalance : repayAmount;

        // Amount to seize
        cygLPAmount = ICygnusCollateral(collateral).seizeCygLP(liquidator, borrower, actualRepayAmount);

        // Update borrows
        (uint256 accountBorrowsPrior, uint256 accountBorrows, uint256 totalBorrowsStored) = updateBorrowInternal(
            borrower,
            0,
            repayAmount
        );

        /// @custom:event Liquidate
        emit Liquidate(
            _msgSender(),
            borrower,
            liquidator,
            cygLPAmount,
            repayAmount,
            accountBorrowsPrior,
            accountBorrows,
            totalBorrowsStored
        );
    }
}
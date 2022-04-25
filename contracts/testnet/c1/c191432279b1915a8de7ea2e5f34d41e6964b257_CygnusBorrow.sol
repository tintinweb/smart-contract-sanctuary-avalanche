/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-23
*/

// Sources flattened with hardhat v2.9.1 https://hardhat.org

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

// ignore: Unlicense
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


// File contracts/cygnus-core/interfaces/ICygnusNebulaOracle.sol

//ignore: Unlicensed
pragma solidity >=0.8.4;

/// @title ITwapNebulaOracle Interface for Oracle
// Simple implementation of Uniswap TWAP Oracle
interface ICygnusNebulaOracle {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:error Emitted when uint224 overflows
     */
    error CygnusNebulaOracle__Uint224Overflow();

    /**
     *  @custom:error Emitted when oracle already exists for LP Token
     */
    error CygnusNebulaOracle__PairIsInitialized(address lpTokenPair);

    /**
     *  @custom:error Emitted when pair hasn't been initialised for LP Token
     */
    error CygnusNebulaOracle__PairNotInitialized(address lpTokenPair);

    /**
     *  @custom:error Emitted when oracle is called before ready
     */
    error CygnusNebulaOracle__TimeWindowTooSmall(uint32 timeWindow);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @param lpTokenPair The address of the LP Token
     *  @param priceCumulative The cumulative price of the LP Token in uint256
     *  @param blockTimestamp The timestamp of the last price update in uint32
     *  @param latestIsSlotA Bool value if it is latest price update
     *  @custom:event Emitted when LP Token price is updated
     */
    event UpdateLPTokenPrice(
        address indexed lpTokenPair,
        uint256 priceCumulative,
        uint32 blockTimestamp,
        bool latestIsSlotA
    );

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTANT FUNCTIONS 
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @return The minimum amount of time for oracle to update, 10 mins
     */
    function minimumTimeWindow() external view returns (uint32);

    /**
     *  @param lpTokenPair The address of the LP Token
     *  @return priceCumulativeSlotA The cumulative price of Token A
     *  @return priceCumulativeSlotB The cumulative price of Token B
     *  @return lastUpdateSlotA The uint32 of last price update of Token A
     *  @return lastUpdateSlotB The uint32 of last price update of Token B
     *  @return latestIsSlotA Bool value represents if price is latest
     *  @return initialized Bool value represents if oracle for pair exists
     */
    function getCygnusNebulaPair(address lpTokenPair)
        external
        view
        returns (
            uint256 priceCumulativeSlotA,
            uint256 priceCumulativeSlotB,
            uint32 lastUpdateSlotA,
            uint32 lastUpdateSlotB,
            bool latestIsSlotA,
            bool initialized
        );

    /**
     *  @notice Helper function that returns the current block timestamp within the range of uint32
     *  @return uint32 block.timestamp
     */
    function getBlockTimestamp() external view returns (uint32);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS 
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /// @notice initialize oracle for LP Token
    /// @param lpTokenPair is address of LP Token
    function initializeCygnusNebula(address lpTokenPair) external;

    /// @notice Gets the LP Tokens price if time elapsed > time window
    /// @param lpTokenPair The address of the LP Token
    /// @return timeWeightedPrice112x112 The price of the LP Token
    /// @return timeWindow The time window of the price update
    function getResult(address lpTokenPair) external returns (uint224 timeWeightedPrice112x112, uint32 timeWindow);
}


// File contracts/cygnus-core/interfaces/ICygnusTerminal.sol

// ignore: UNLICENSED
pragma solidity >=0.8.4;

// Dependencies

interface ICygnusTerminal is IErc20Permit {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:error Emitted when attempting to set already initialized factory
     */
    error CygnusTerminal__FactoryAlreadyInitialized(address);

    /**
     *  @custom:error Emitted when attempting to mint zero amount of tokens
     */
    error CygnusTerminal__CantMintZero(uint256);

    /**
     *  @custom:error Emitted when attempting to redeem zero amount of tokens
     */
    error CygnusTerminal__CantBurnZero(uint256);

    /**
     *  @custom:error Emitted when attempting to redeem over amount of tokens
     */
    error CygnusTerminal__BurnAmountInvalid(uint256);

    /**
     *  @custom:error Emitted when attempting to call Admin-only functions
     */
    error CygnusTerminal__MsgSenderNotAdmin(address);

    /**
     *  @custom:error Emitted when attempting to call Factory-only functions
     */
    error CygnusTerminal__MsgSenderNotFactory(address);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @param totalBalance Total cash balance of the underlying.
     *  @custom:event Emitted when `totalBalance` is in sync with balanceOf(address(this)).
     */
    event Sync(uint256 totalBalance);

    /**
     *  @param sender Address of the msg.sender.
     *  @param minter Address of the minter.
     *  @param mintAmount Amount initial is worth at the current exchange rate.
     *  @param poolTokens Amount of the tokens to be minted.
     *  @custom:event Emitted when tokens are minted
     */
    event Mint(address indexed sender, address indexed minter, uint256 mintAmount, uint256 poolTokens);

    /**
     *  @param sender Address of the msgSender()
     *  @param redeemer Address of the redeemer.
     *  @param redeemAmount Amount invested is worth at the current exchangerate.
     *  @param poolTokens Amount of PoolTokens to burn.
     *  @custom:event Emitted when tokens are redeemed.
     */
    event Redeem(address indexed sender, address indexed redeemer, uint256 redeemAmount, uint256 poolTokens);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
           3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @return Total balance of pool.
     */
    function totalBalance() external returns (uint256);

    /**
     *  @return Contract Address of the underlying LP Token.
     */
    function underlying() external returns (address);

    /**
     *  @return The address of Factory contract. 🛸
     */
    function hangar18() external returns (address);

    /**
     *  @return The redeemable amount of underlying tokens that 1 pool token can be redeemed for.
     */
    function exchangeRate() external returns (uint256);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice Called once by factory at time of deployment and establishes factory address. 🛸
     *  @dev Allows us to initialize borrowing/collateral arms.
     */
    function setHangar18() external;

    /**
     *  @notice Low level function should only be called by `Vega` contract.
     *  @param minter Address of the minter.
     *  @return poolTokens Amount to mint which is equal to amount / exchangeRate
     */
    function mint(address minter) external returns (uint256 poolTokens);

    /**
     * @notice Low level function should only be called by `Vega` contract.
     * @param holder Address of the redeemer.
     * @return redeemAmount The holder's shares, equal to amount * exchangeRate
     */
    function redeem(address holder) external returns (uint256 redeemAmount);

    /**
     *  @notice Uniswap's skim function.
     *  @param to Address of user skimming difference between total balance stored and actual balance.
     */
    function skim(address to) external;

    /**
     *  @notice Uniswap's sync function called externally to force balances to sync.
     *  @dev Emits a sync event.
     */
    function sync() external;
}


// File contracts/cygnus-core/interfaces/ICygnusBorrowControl.sol

// ignore: Unlicensed

pragma solidity >=0.8.4;

/// @title ICygnusBorrowControl
interface ICygnusBorrowControl is ICygnusTerminal {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:error Emitted when integer is not uint112
     */
    error CygnusBorrowControl__Uint112Overflow();

    /**
     *  @custom:error Emitted when trying to update a borrow parameter and the number is outside of range allowed.
     */
    error CygnusBorrowControl__ParameterNotInRange(uint256);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */
    /**
     *  @custom:event Emitted when a new base rate is set.
     */
    event NewBaseRate(uint256 newBaseRate);

    /**
     *  @custom:event Emitted when a new multiplier is set.
     */
    event NewFarmMultiplier(uint256 newFarmMultiplier);

    /**
     *  @custom:event Emitted when a new kink utilization rate is set.
     */
    event NewKinkUtilizationRate(uint256 newKinkUtilizationRate);

    /**
     *  @custom:event Emitted when a new reserve factor is set.
     */
    event NewReserveFactor(uint256 newReserveFactor);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    //  Important addresses  //

    /**
     *  @notice Address of the collateral contract.
     */
    function collateral() external view returns (address);

    /**
     *  @notice Address of the borrow tracker.
     */
    function cygnusBorrowTracker() external view returns (address);

    //  Current pool rates  //

    /**
     *  @notice Percentage of the total initial borrow that goes to reserves, equivalent to 0.2%.
     */
    function CYGNUS_BORROW_FEE() external view returns (uint256);

    /**
     *  @notice Current base interest rate of the pool, which is the y-intercept when utilization rate is 0.
     */
    function baseRate() external view returns (uint256);

    /**
     *  @notice Current multiplier of utilization rate of the pool, that gives the slope of the interest rate.
     */
    function farmMultiplier() external view returns (uint256);

    /**
     *  @notice Current utilization point at which the jump multiplier is applied in this lending pool.
     */
    function kink() external view returns (uint256);

    /**
     *  @notice Percentage of interest that is routed to this market's Reserve Pool.
     */
    function reserveFactor() external view returns (uint256);

    //  Lower/Upper Bounds  //

    /**
     *  @notice Maximum base interest rate allowed (20%).
     */
    function BASE_RATE_MAX() external pure returns (uint256);

    /**
     *  @notice Minimum kink utilization point allowed (50%).
     */
    function KINK_UTILIZATION_RATE_MIN() external pure returns (uint256);

    /**
     *  @notice Maximum kink utilization point allowed (90%).
     */
    function KINK_UTILIZATION_RATE_MAX() external pure returns (uint256);

    /**
     *  @notice The maximum reserve factor allowed (50%).
     */
    function RESERVE_FACTOR_MAX() external pure returns (uint256);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice 🛸
     *  @dev This function is callable only by the Factory to initialize the Collateral.
     *  @param _underlying is address of underlying
     *  @param _collateral is address of collateral
     */
    function initializeBorrow(address _underlying, address _collateral) external;

    /**
     *  @notice 👽
     *  @param newBaseRate is the new base rate for pool
     */
    function setBaseRate(uint256 newBaseRate) external;

    /**
     *  @notice 👽
     *  @param newFarmMultiplier is the new multiplier for pool
     */
    function setFarmMultiplier(uint256 newFarmMultiplier) external;

    /**
     *  @notice 👽
     *  @param newKinkUtilizationRate is the new kink utilization rate for pool
     */
    function setKinkUtilizationRate(uint256 newKinkUtilizationRate) external;

    /**
     *  @notice 👽
     *  @param newReserveFactor is the new reserve factor for pool
     */
    function setReserveFactor(uint256 newReserveFactor) external;
}


// File contracts/cygnus-core/interfaces/ICygnusBorrowInterest.sol

// ignore: Unlicensed

pragma solidity >=0.8.4;

interface ICygnusBorrowInterest is ICygnusBorrowControl {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */
    /**
     *  We define no errors in our interest rate contract as most errors are handled by parent contracts.
     */

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @param baseRatePerYear The approximate target base APR, as a mantissa (scaled by 1e18)
     *  @param multiplierPerYear The rate of increase in interest rate wrt utilization (scaled by 1e18)
     *  @param jumpMultiplierPerYear The multiplierPerSecond after hitting a specified utilization point
     *  @param kink_ is the utilization rate at which the kink happens
     *  custom:event Emitted when a new interest rate is set
     */
    event NewInterestParameter(
        uint256 baseRatePerYear,
        uint256 multiplierPerYear,
        uint256 jumpMultiplierPerYear,
        uint256 kink_
    );

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ───────────────────────────────────── Public ─────────────────────────────────────  */

    /**
     *  @notice The approximate number of seconds per year that is assumed by the interest rate model
     */
    function SECONDS_PER_YEAR() external view returns (uint256);

    /**
     *  @notice The multiplier of utilization rate that gives the slope of the interest rate
     */
    function multiplierPerSecond() external view returns (uint256);

    /**
     *  @notice The base interest rate which is the y-intercept when utilization rate is 0
     */
    function baseRatePerSecond() external view returns (uint256);

    /**
     *  @notice The multiplier Per Second after hitting a specified utilization point
     */
    function jumpMultiplierPerSecond() external view returns (uint256);

    /**
     *  @notice Calculates the utilization rate of the market: `borrows / (cash + borrows - reserves)`
     *  @param cash The amount of cash in the market
     *  @param borrows The amount of borrows in the market
     *  @param reserves The amount of reserves in the market (currently unused)
     *  @return The utilization rate as a mantissa between [0, 1e18]
     */
    function utilizationRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves
    ) external view returns (uint256);

    /**
     *  @notice Calculates the current borrow rate per second.
     *  @param cash The amount of cash in the market.
     *  @param borrows The amount of borrows in the market.
     *  @param reserves The amount of reserves in the market.
     *  @return The borrow rate of the lending pool.
     */
    function getBorrowRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves
    ) external view returns (uint256);

    /**
     *  @notice Calculates the current supply rate per second
     *  @param cash The amount of cash in the market
     *  @param borrows The amount of borrows in the market
     *  @param reserves The amount of reserves in the market
     *  @param reserveFactorMantissa The current reserve factor for the market
     *  @return The supply rate percentage per second as a mantissa (scaled by 1e18)
     */
    function getSupplyRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves,
        uint256 reserveFactorMantissa
    ) external view returns (uint256);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice Internal function to update the parameters of the interest rate model
     *  @param baseRatePerYear The approximate target base APR, as a mantissa (scaled by 1e18)
     *  @param multiplierPerYear The rate of increase in interest rate wrt utilization (scaled by 1e18)
     *  @param jumpMultiplierPerYear The multiplierPerSecond after hitting a specified utilization point
     *  @param kink_ The utilization point at which the jump multiplier is applied
     */
    function updateJumpRateModel(
        uint256 baseRatePerYear,
        uint256 multiplierPerYear,
        uint256 jumpMultiplierPerYear,
        uint256 kink_
    ) external;
}


// File contracts/cygnus-core/interfaces/ICygnusBorrowApprove.sol

// ignore: Unlicensed

pragma solidity >=0.8.4;

/**
 *  @title CygnusBorrowApprove
 *  @dev Interface for approving Borrow allowances
 */
interface ICygnusBorrowApprove is ICygnusBorrowControl {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:error Emitted when the recovered owner does not match the actual owner.
     */
    error CygnusBorrowApprove__InvalidSignature(uint8 v, bytes32 r, bytes32 s);

    /**
     *  @custom:error Emitted when the owner is the zero address.
     */
    error CygnusBorrowApprove__OwnerZeroAddress(address owner);

    /**
     *  @custom:error Emitted when the permit expired.
     */
    error CygnusBorrowApprove__PermitExpired(uint256 deadline);

    /**
     *  @custom:error Emitted when the recovered owner is the zero address.
     */
    error CygnusBorrowApprove__RecoveredOwnerZeroAddress(address recoveredOwner);

    /**
     *  @notice Emitted when the spender is the zero address.
     */
    error CygnusBorrowApprove__SpenderZeroAddress(address spender);

    /**
     *  @notice Emitted when the owner is the spender.
     */
    error CygnusBorrowApprove__OwnerIsSpender(address owner, address spender);

    /**
     *  @notice Emitted when the borrow allowance is invalid.
     */
    error CygnusBorrowApprove__InsufficientBorrowAmount(uint256 currentAllowance);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:event Emitted when borrow is approved.
     */
    event BorrowApproved(address owner, address spender, uint256 amount);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @notice IERC721 permit typehash for signature based borrow approvals
     *  @return The keccak256 of the owner, spender, value, nonce and deadline
     */
    function BORROW_PERMIT_TYPEHASH() external view returns (bytes32);

    /**
     *  @notice Mapping of spending allowances from one address to another address
     *  @param owner The address of the token owner
     *  @param spender The address of the token spender
     *  @return The maximum amount the spender can spend
     */
    function accountBorrowAllowances(address owner, address spender) external view returns (uint256);

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
     */
    function accountBorrowApprove(address spender, uint256 value) external returns (bool);
}


// File contracts/cygnus-core/interfaces/ICygnusBorrowTracker.sol

// ignore: Unlicensed
pragma solidity >=0.8.4;


interface ICygnusBorrowTracker is ICygnusBorrowInterest, ICygnusBorrowApprove {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */
    /**
     *  @custom:error Emitted if there is a shortfall in the account's balances.
     */
    error CygnusBorrowTracker__AddressZeroInvalidBalance(address);

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
     *  @notice The current total DAI reserves stored for this lending pool.
     */
    function totalReserves() external view returns (uint256);

    /**
     *  @notice Total borrows in the lending pool.
     */
    function totalBorrows() external view returns (uint256);

    /**
     *  @notice Initial borrow index of the market equivalent to 1e18.
     */
    function borrowIndex() external view returns (uint256);

    /**
     *  @notice block.timestamp of the last accrual.
     */
    function lastAccrualTimestamp() external view returns (uint32);

    /**
     *  @notice The current borrow rate stored for the lending pool.
     */
    function borrowRate() external view returns (uint256);

    /**
     *  @notice The current exchange rate of tokens.
     */
    function exchangeRateStored() external view returns (uint256);

    /**
     *  @notice This public view function is used to get the borrow balance of users based on stored data.
     *  @dev It is used by CygnusCollateral and CygnusCollateralModel contracts.
     *  @param borrower The address whose balance should be calculated.
     *  @return balance The account's stored borrow balance or 0 if borrower's interest index is zero.
     */
    function getBorrowBalance(address borrower) external view returns (uint256 balance);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @notice Tracks all users borrows.
     */
    function trackBorrow(
        address borrower,
        uint256 accountBorrows,
        uint256 accountBorrowIndex
    ) external;

    /**
     *  @notice Accrues interest rate and updates borrow rate and total cash.
     */
    function accrueInterest() external;
}


// File contracts/cygnus-core/interfaces/ICygnusBorrow.sol

// ignore: Unlicensed
pragma solidity >=0.8.4;

interface ICygnusBorrow is ICygnusBorrowTracker {
    /*  ═══════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:error Emitted when the borrow amount is higher than total balance
     */
    error CygnusBorrow__BorrowExceedsTotalBalance(uint256);

    /**
     *  @custom:error Emitted if there is a shortfall in the account's balances.
     */
    error CygnusBorrow__InsufficientLiquidity(address);

    /*  ═══════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Event for account liquidations indexed by periphery, borrower and liquidator addresses.
     *  @param sender Indexed address of msg.sender (should be `Router` address)
     *  @param borrower Indexed address the account with negative account liquidity that shall be liquidated.
     *  @param liquidator Indexed address of the liquidator.
     *  @param denebAmount The amount of the underlying asset to be seized.
     *  @param repayAmount The amount of the underlying asset to be repaid (factors in liquidation incentive).
     *  @param accountBorrowsPrior Record of borrower's total borrows before this event.
     *  @param accountBorrows Record of borrower's present borrows (accountBorrowsPrior + borrowAmount).
     *  @param totalBorrowsStored Record of the protocol's cummulative total borrows after this event.
     *  @custom:event Emitted upon a successful liquidation.
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
     *  @notice Event for account borrows and repays indexed by periphery, borrower and receiver addresses.
     *  @param sender Indexed address of msg.sender (should be `Router` address).
     *  @param receiver Indexed address of receiver (if repay = this is address(0), if borrow `Router` address).
     *  @param borrower Indexed address of the borrower.
     *  @param borrowAmount If borrow calldata, the amount of the underlying asset to be borrowed, else 0.
     *  @param repayAmount If repay calldata, the amount of the underlying borrowed asset to be repaid, else 0.
     *  @param accountBorrowsPrior Record of borrower's total borrows before this event.
     *  @param accountBorrows Record of borrower's total borrows after this event ( + borrowAmount) or ( - repayAmount)
     *  @param totalBorrowsStored Record of the protocol's cummulative total borrows after this event.
     *  @custom:event Emitted upon a successful borrow or repay.
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
            3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice This low level function should only be called from Router contract only.
     *  @notice It accrues before initializing and updates the total balance. Emits Sync event.
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
     *  @notice This low level function should only be called from Router contract only.
     *  @param borrower The address of the borrower being liquidated
     *  @param liquidator The address of the liquidator.
     *  @return seizeTokens The amount of tokens to liquidate.
     */
    function liquidate(address borrower, address liquidator) external returns (uint256 seizeTokens);
}


// File contracts/cygnus-core/utils/Context.sol

// ignore: MIT
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

// ignore: Unlicense
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


// File contracts/cygnus-core/libraries/Address.sol

// ignore: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity >=0.8.4;

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
}


// File contracts/cygnus-core/libraries/SafeErc20.sol

// ignore: Unlicense
pragma solidity >=0.8.4;


/// @notice Emitted when the call is made to a non-contract.
error SafeErc20__CallToNonContract(address target);

/// @notice Emitted when there is no return data.
error SafeErc20__NoReturnData();

/// @title SafeErc20.sol
/// @author Paul Razvan Berg
/// @notice Wraps around Erc20 operations that throw on failure (when the token contract
/// returns false). Tokens that return no value (and instead revert or throw
/// on failure) are also supported, non-reverting calls are assumed to be successful.
///
/// To use this library you can add a `using SafeErc20 for IErc20;` statement to your contract,
/// which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
////
/// @dev Forked from OpenZeppelin
/// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/utils/Address.sol
library SafeErc20 {
    using Address for address;

    /// INTERNAL FUNCTIONS ///

    function safeTransfer(
        IErc20 token,
        address to,
        uint256 amount
    ) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, amount));
    }

    function safeTransferFrom(
        IErc20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, amount));
    }

    /// PRIVATE FUNCTIONS ///

    /// @dev Imitates a Solidity high-level call (a regular function call to a contract), relaxing the requirement
    /// on the return value: the return value is optional (but if data is returned, it cannot be false).
    /// @param token The token targeted by the call.
    /// @param data The call data (encoded using abi.encode or one of its variants).
    function callOptionalReturn(IErc20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.
        bytes memory returndata = functionCall(address(token), data, "SafeErc20LowLevelCall");
        if (returndata.length > 0) {
            // Return data is optional.
            if (!abi.decode(returndata, (bool))) {
                revert SafeErc20__NoReturnData();
            }
        }
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) private returns (bytes memory) {
        if (!target.isContract()) {
            revert SafeErc20__CallToNonContract(target);
        }

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present.
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly.
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


// File contracts/cygnus-core/Erc20.sol

// ignore: Unlicense
pragma solidity >=0.8.4;



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
    function mintInternal(address beneficiary, uint256 mintAmount) internal {
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

// ignore: Unlicense
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


// File contracts/cygnus-core/libraries/PRBMath.sol

// ignore: Unlicense
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

// ignore: Unlicense
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


// File contracts/cygnus-core/interfaces/ICygnusCollateralControl.sol

// ignore: Unlicensed
pragma solidity >=0.8.4;

// Dependencies

interface ICygnusCollateralControl is ICygnusTerminal {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:error Emitted when trying a collateral parameter outside of range allowed.
     */
    error CygnusCollateralControl__ParameterNotInRange(uint256);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════  
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @param underlying Address of underlying collateral token.
     *  @param borrowDAITokenA Address representing borrowable DAI.
     *  @param borrowDAITokenB Address of pool's second borrow token.
     *  @custom:event Emitted when factory calls initialize function.
     */
    event InitializeCollateral(address underlying, address borrowDAITokenA, address borrowDAITokenB);

    /**
     *  @param newPriceOracle The new price oracle.
     *  @custom:event Emitted when a new price oracle is set.
     */
    event NewPriceOracle(ICygnusNebulaOracle newPriceOracle);

    /**
     *  @param newLiquidationIncentive The percent which liquidators take from the collateral.
     *  @custom:event Emitted when a new liquidation incentive is set.
     */
    event NewLiquidationIncentive(uint256 newLiquidationIncentive);

    /**
     *  @param newDebtRatio The new debt ratio at which the collateral becomes liquidatable.
     *  @custom:event Emitted when a new debt ratio is set.
     */
    event NewDebtRatio(uint256 newDebtRatio);

    /**
     *  @param newLiquidationFee The fee the protocol takes from the liquidation incentive.
     *  @custom:event Emitted when a new liquidation fee is set.
     */
    event NewLiquidationFee(uint256 newLiquidationFee);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @return The address of the Cygnus Price Oracle.
     */
    function cygnusNebulaOracle() external view returns (ICygnusNebulaOracle);

    /**
     *  @return The address of AlbireoTokenA.
     */
    function borrowDAITokenA() external view returns (address);

    /**
     *  @return The address of AlbireoTokenB (if available).
     */
    function borrowDAITokenB() external view returns (address);

    //  Current rates in the pool

    /**
     *  @return The current debt ratio for the lending pool, default at 80% (x5 leverage).
     */
    function debtRatio() external view returns (uint256);

    /**
     *  @return The current liquidation incentive for the lending pool, default at 5%.
     */
    function liquidationIncentive() external view returns (uint256);

    /**
     *  @return The current liquidation fee the protocol keeps from each liquidation, default at 0%.
     */
    function liquidationFee() external view returns (uint256);

    //  Set upper and lower bounds for each parameter

    /**
     *  @notice We set a minimum to avoid users being liquidated too easily.
     *  @return Minimum debt ratio at which the collateral becomes liquidatable, equivalent to 50% (x2 leverage).
     */
    function DEBT_RATIO_MIN() external pure returns (uint256);

    /**
     *  @return Maximum debt ratio equivalent to 87.5% (x8 leverage).
     */
    function DEBT_RATIO_MAX() external pure returns (uint256);

    /**
     *  @notice Need to set a minimum just in case.
     *  @return The minimum liquidation incentive for liquidators, equivalent to 1% of collateral.
     */
    function LIQUIDATION_INCENTIVE_MIN() external pure returns (uint256);

    /**
     *  @return The maximum liquidation incentive for liquidators, equivalent to 50% of collateral.
     */
    function LIQUIDATION_INCENTIVE_MAX() external pure returns (uint256);

    /**
     *  @notice No minimum as the default is 0.
     *  @return Maximum fee the protocol is allowed to keep from each liquidation, equivalent to 20%.
     */
    function LIQUIDATION_FEE_MAX() external pure returns (uint256);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice 🛸
     *  @dev This function is callable only by the Factory to initialize the Collateral.
     *  @param _underlying The address of the LP token from the DEX.
     *  @param _borrowDAITokenA The address of AlbireoTokenA.
     *  @param _borrowDAITokenA The address of AlibreoTokenB (if available).
     */
    function initializeCollateral(
        address _underlying,
        address _borrowDAITokenA,
        address _borrowDAITokenB
    ) external;

    /**
     *  @notice 👽
     *  @notice Updates price oracle.
     *  @param  newPriceOracle The new price oracle set for the lending poole
     */
    function setPriceOracle(ICygnusNebulaOracle newPriceOracle) external;

    /**
     *  @notice 👽
     *  @notice Updates the debt ratio for the lending pool.
     *  @param  newDebtRatio The new requested point at which a loan is liquidatable
     */
    function setDebtRatio(uint256 newDebtRatio) external;

    /**
     *  @notice 👽
     *  @dev Updates the liquidation incentive for the lending pool.
     *  @param  newLiquidationIncentive The new requested profit liquidators keep from the collateral.
     */
    function setLiquidationIncentive(uint256 newLiquidationIncentive) external;

    /**
     *  @notice 👽
     *  @notice Updates the fee the protocol keeps for every liquidation.
     *  @param newLiquidationFee The new requested fee taken from the liquidation incentive.
     */
    function setLiquidationFee(uint256 newLiquidationFee) external;
}


// File contracts/cygnus-core/interfaces/ICygnusCollateralModel.sol

// ignore: Unlicensed
pragma solidity >=0.8.4;

// Dependencies

interface ICygnusCollateralModel is ICygnusCollateralControl {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */
    /**
     *  @custom:error PriceTokenAInvalid Emitted when price of Token A <= 100
     */
    error CygnusCollateralModel__PriceTokenAInvalid(uint256 priceTokenA);

    /**
     *  @custom:error PriceTokenBInvalid Emitted when price of Token B <= 100
     */
    error CygnusCollateralModel__PriceTokenBInvalid(uint256 priceTokenB);

    /**
     *  @custom:error PriceTokenBInvalid Emitted when price of Token B <= 100
     */
    error CygnusCollateralModel__BorrowerCantBeAddressZero(address);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @notice Gets the fair price of token A and token B from a LP Token using the price oracle
     *  @return priceTokenA The fair price of Token A.
     *  @return priceTokenB The fair price of Token B.
     */
    function getTimeWeightedPrices() external returns (uint256 priceTokenA, uint256 priceTokenB);

    /**
     *  @param borrower The address of the borrower, reverts if address(0)
     *  @param amountTokenA The total amount of token A in the account's collateral
     *  @param amountTokenB The total amount of token B in the account's collateral
     *  @return liquidity the account liquidity. If none, return 0
     *  @return shortfall the account shortfall. If none, return 0
     */
    function getAccountLiquidity(
        address borrower,
        uint256 amountTokenA,
        uint256 amountTokenB
    ) external returns (uint256 liquidity, uint256 shortfall);
}


// File contracts/cygnus-core/interfaces/ICygnusCollateral.sol

// ignore: Unlicensed
pragma solidity >=0.8.4;

// dependencies

/// @title ICygnusCollateral
/// @notice Interface for main collateral contract
interface ICygnusCollateral is ICygnusCollateralModel {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:error Emitted when the value of unlock is above user's total balance.
     */
    error CygnusCollateral__ValueInvalid(uint256 totalBalance);

    /**
     *  @custom:error Emitted when the user doesn't have enough liquidity for a transfer.
     */
    error CygnusCollateral__InsufficientLiquidity(bool);

    /**
     *  @custom:error Emitted when borrowable is not one of the pool's allowed borrow tokens.
     */
    error CygnusCollateral__BorrowableInvalid(address cygnusBorrow);

    /**
     *  @custom:error Emitted for liquidation when msg.sender is not borrowable.
     */
    error CygnusCollateral__NotBorrowable(address);

    /**
     *  @custom:error Emitted when there is no shortfall
     */
    error CygnusCollateral__NotLiquidatable(uint256 shortfall);

    /**
     *  @custom:error Emitted when liquidator is borrower.
     */
    error CygnusCollateral__LiquidatingSelf(address borrower);

    /**
     *  @custom:error Emitted when liquidator is borrower
     */
    error CygnusCollateral__InsufficientRedeemAmount(uint256 declaredRedeemTokens);

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

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @param from The address of the borrower.
     *  @param value The amount to unlock.
     *  @return Whether tokens are unlocked or not.
     */
    function tokensUnlocked(address from, uint256 value) external returns (bool);

    /**
     *  @param borrower The address of the borrower.
     *  @return liquidity The account's liquidity.
     *  @return shortfall If user has no liquidity, return the shortfall.
     */
    function accountLiquidity(address borrower) external returns (uint256 liquidity, uint256 shortfall);

    /**
     *  @param borrower The address of the borrower.
     *  @param borrowableToken The address of the token the user wants to borrow.
     *  @param accountBorrows The amount the user wants to borrow.
     *  @return Whether the account can borrow.
     */
    function canBorrow(
        address borrower,
        address borrowableToken,
        uint256 accountBorrows
    ) external returns (bool);

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice This should only be called by borrowDAITokenA or borrowDAITokenB liquidate function.
     *  @notice Updates balances of liquidator and borrower.
     *  @param liquidator The address repaying the borrow and seizing the collateral.
     *  @param borrower The address of the borrower.
     *  @param repayAmount The number of collateral tokens to seize.
     *  @return denebAmount The amount seized.
     */
    function seizeDeneb(
        address liquidator,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256 denebAmount);

    /**
     *  @notice This should be called from `Router` contract.
     *  @param redeemer The address redeeming the tokens
     *  @param redeemAmount The amount of the underlying asset being redeemed
     *  @param data Calldata passed to router contract
     */
    function redeemDeneb(
        address redeemer,
        uint256 redeemAmount,
        bytes calldata data
    ) external;
}


// File contracts/cygnus-core/interfaces/ICygnusDeneb.sol

// ignore: Unlicensed
pragma solidity >=0.8.4;

// Dependencies

/**
 *  @title ICygnusDeneb
 *  @notice Interface for the collateral deployer
 */
interface ICygnusDeneb {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */
    /**
     *  @param lpTokenPair The address of the underlying LP Token
     *  @param factory The address of the Cygnus factory
     *  @return deneb The address of the new deployed Cygnus collateral contract
     */
    function deployDeneb(address lpTokenPair, address factory) external returns (address deneb);
}


// File contracts/cygnus-core/interfaces/ICygnusAlbireo.sol

// ignore: Unlicensed
pragma solidity >=0.8.4;

/// @title ICygnusAlbireo
/// @notice Interface for the Borrowable Deployer
interface ICygnusAlbireo {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Function to deploy the both Borrow arms of Cygnus
     *  @notice Called twice by Factory twice during deployment of lending pool to create borrow tokens A and B
     *  @param lpTokenPair Address of LP Token
     *  @param borrowTokenIndex Token "A" or Token "B" from the LP Token
     *  @return albireo The address of the new borrow contract.
     */
    function deployAlbireo(address lpTokenPair, string memory borrowTokenIndex) external returns (address albireo);
}


// File contracts/cygnus-core/interfaces/ICygnusFactory.sol

// ignore: Unlicensed
pragma solidity >=0.8.4;

// oracle

// dependencies deployers


interface ICygnusFactory {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:error Emitted when the shuttle already exists
     */
    error CygnusFactory__ShuttleAlreadyExists(address lpTokenPair);

    /**
     *  @custom:error Emitted when trying to deploy an already intiialized shuttle
     */
    error CygnusFactory__ShuttleAlreadyInitialized(address lpTokenPair);

    /**
     *  @custom:error Emitted when trying to initialize a shuttle without a collateral contract created
     */
    error CygnusFactory__CollateralNotCreated();

    /**
     *  @custom:error Emitted when trying to initialize a shuttle without the first borrow arm created
     */
    error CygnusFactory__FirstBorrowArmNotCreated();

    /**
     *  @custom:error Emitted when trying to initialize a shuttle without the second borrow arm created
     */
    error CygnusFactory__SecondBorrowArmNotCreated();

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @param lpTokenPair The address of the underlying LP Token
     *  @param token0 The address of Token A of underlying
     *  @param token1 The address of Token B of underlying
     *  @param shuttleID The ID of this lending pool
     *  @param collateral The address of the Cygnus collateral
     *  @param borrowDAITokenA The address of borrowable Token A
     *  @param borrowDAITokenB The address of borrowable Token B
     */
    event NewShuttleLaunched(
        address indexed lpTokenPair,
        address indexed token0,
        address indexed token1,
        uint256 shuttleID,
        address collateral,
        address borrowDAITokenA,
        address borrowDAITokenB
    );

    /**
     *  @param oldPendingAdmin Address of previous admin
     *  @param newPendingAdmin Address of the new pending admin
     */
    event NewPendingCygnusAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
     *  @param oldAdmin Address of the old admin
     *  @param newAdmin Address of the new confirmed admin
     */
    event NewCygnusAdmin(address oldAdmin, address newAdmin);

    /**
     *  @param oldVegaContract Address of old contract `Vega Token Manager`
     *  @param newVegaContract Address of the new pending contract `Vega Token Manager`
     */
    event NewPendingVegaContract(address oldVegaContract, address newVegaContract);

    /**
     *  @param oldVegaContract Address of old contract `Vega Token Manager`
     *  @param newVegaContract Address of the new confirmed contract `Vega Token Manager`
     */
    event NewVegaContract(address oldVegaContract, address newVegaContract);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @notice The address of the Factory Admin and grants special permissions in collateral/borrow control contracts
     */
    function admin() external view returns (address);

    /**
     *  @notice Address of `vegaTokenManager` which is the contract that handles Cygnus reserves and special calls
     *  AKA TokenSplitter
     */
    function vegaTokenManager() external view returns (address);

    /**
     * @notice The address of the Collateral deployer
     */
    function collateralDeployer() external view returns (ICygnusDeneb);

    /**
     * @notice The address of the Borrow deployer
     */
    function borrowDeployer() external view returns (ICygnusAlbireo);

    /**
     * @notice The address of the Cygnus price oracle
     */
    function cygnusNebulaOracle() external view returns (ICygnusNebulaOracle);

    /**
     *  @notice Official record for all the pairs deployed
     *  @param lpTokenPair The address of the LP Token
     *  @return isInitialized Whether this pair exists or not
     *  @return shuttleID The ID of this shuttle
     *  @return collateral The address of the collateral
     *  @return borrowDAITokenA The address of the borrowing Token A
     *  @return borrowDAITokenB The address of the borrowing Token B
     */
    function getShuttles(address lpTokenPair)
        external
        view
        returns (
            bool isInitialized,
            uint24 shuttleID,
            address collateral,
            address borrowDAITokenA,
            address borrowDAITokenB
        );

    /**
     *  @notice Addresses of all the pools that have been deployed.
     */
    function allShuttles(uint256) external view returns (address);

    /**
     *  @notice Returns the total number of pools deployed.
     */
    function shuttlesLength() external view returns (uint256);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Creates a cygnus Collateral contract based on the LP Token and adds it to record.
     *  @param lpTokenPair Address of the LP Token from the DEX
     *  @return collateral Returns the address of the cygnus collateral based on this LP Token pair.
     */
    function createCollateral(address lpTokenPair) external returns (address collateral);

    /**
     *  @notice Creates the first cygnus Borrow arm for the above collateral.
     *  @param lpTokenPair Address of the LP Token from the DEX.
     *  @return borrowDAITokenA Returns the address of the first cygnus Borrow arm based on LP Token pair.
     */
    function createBorrowTokenA(address lpTokenPair) external returns (address borrowDAITokenA);

    /**
     *  @notice Creates the second cygnus Borrow arm for the above collateral.
     *  @param lpTokenPair Address of the LP Token from the DEX.
     *  @return borrowDAITokenB Returns the address of the second cygnus Borrow arm based on LP Token pair.
     */
    function createBorrowTokenB(address lpTokenPair) external returns (address borrowDAITokenB);

    /**
     *  @notice Initializes both Borrow arms and the collateral arm.
     *  @param lpTokenPair The address of the underlying LP Token that the pool will be based on.
     */
    function initializeShuttle(address lpTokenPair) external;
}


// File contracts/cygnus-core/interfaces/IDexPair.sol

//ignore: Unlicensed
pragma solidity >=0.8.4;

// only using relevant functions for CygnusNebula Oracle

/// @notice Interface for most DEX pairs (TraderJoe, Pangolin, Sushi, Uniswap, etc.)
interface IDexPair is IErc20Permit {
    /// DEX FUNCTIONS ///

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
}


// File contracts/cygnus-core/CygnusFactory.sol

// ignore: Unlicensed
/* .              .                                ,
     .     █████████           ---======*                 🛰️                    🛰️            .           ⠀
          ███░░░░░███                                              📡                 🌔                        
         ███     ░░░  █████ ████  ███████ ████████   █████ ████  █████             .⠀
        ░███         ░░███ ░███  ███░░███░░███░░███ ░░███ ░███  ███░░      .     .⠀           .           .
        ░███   *      ░███ ░███ ░███ ░███ ░███ ░███  ░███ ░███ ░░█████       ⠀
     *  ░░███     ███ ░███ ░███ ░███ ░███ ░███ ░███  ░███ ░███  ░░░░███              .             *⠀
         ░░█████████  ░░███████ ░░███████ ████ █████░░████████ ██████     .----===*  ⠀
          ░░░░░░░░░    ░░░░░███  ░░░░░███░░░░ ░░░░░   ░░░░░░░░ ░░░░░░            .           🛸                .⠀
                       ███ ░███  ███ ░███                .                 .                    ⠀
         .      *     ░░██████  ░░██████   .                                            .           *                 
                       ░░░░░░    ░░░░░░      -------=========*                      .                             
    .      .                            .       *          .            .                          .⠀
    
        https://cygnusdao.finance - Factory Contract V1                                                          */

pragma solidity >=0.8.4;

// Dependencies

// DEX Pair

/**
 *  @title CygnusCollateralControl
 *  @notice Contract for factory
 */
contract CygnusFactory is ICygnusFactory {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. STORAGE
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @inheritdoc ICygnusFactory
     */
    address public override admin;

    /**
     *  @inheritdoc ICygnusFactory
     */
    address public override vegaTokenManager;

    /**
     *  @inheritdoc ICygnusFactory
     */
    ICygnusDeneb public override collateralDeployer; // Collateral deployer

    /**
     *  @inheritdoc ICygnusFactory
     */
    ICygnusAlbireo public override borrowDeployer; // Borrow deployer

    /**
     *  @inheritdoc ICygnusFactory
     */
    ICygnusNebulaOracle public override cygnusNebulaOracle; // Price oracle

    /**
     *  @notice Use 2 memory slots
     *  @notice Container for the official record of all individual lending pools deployed
     *  @custom:struct isInitialized Whether or not the lending pool is initialized
     *  @custom:struct shuttleID The ID of the lending pool
     *  @custom:struct collateral The address of the collateral
     *  @custom:struct borrowDAITokenA The address of the borrowing Token A (DAI)
     *  @custom:struct borrowDAITokenB The address of the second lending token (if there is)
     */
    struct Shuttle {
        bool isInitialized;
        uint24 shuttleID;
        address collateral;
        address borrowDAITokenA;
        address borrowDAITokenB;
    }

    /**
     *  @inheritdoc ICygnusFactory
     */
    mapping(address => Shuttle) public override getShuttles;

    /**
     *  @inheritdoc ICygnusFactory
     */
    address[] public override allShuttles;

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. CONSTRUCTOR
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Sets admin/tokensplitter/deployer/oracle addresses
     *  @param _cygnusAdmin Address of the Cygnus Admin to update important protocol parameters
     *  @param _vegaTokenManager Address of the contract that handles weighted forwarding of Erc20 tokens
     *  @param _collateralDeployer Address of the collateral deployer (Deneb)
     *  @param _borrowDeployer Address of the borrow deployer (Albireo)
     *  @param _cygnusNebulaOracle Address of the price oracle
     */
    constructor(
        address _cygnusAdmin,
        address _vegaTokenManager,
        ICygnusDeneb _collateralDeployer,
        ICygnusAlbireo _borrowDeployer,
        ICygnusNebulaOracle _cygnusNebulaOracle
    ) {
        admin = _cygnusAdmin;

        vegaTokenManager = _vegaTokenManager;

        collateralDeployer = _collateralDeployer;

        borrowDeployer = _borrowDeployer;

        cygnusNebulaOracle = _cygnusNebulaOracle;

        /// @custom:event NewCygnusAdmin
        emit NewCygnusAdmin(address(0), _cygnusAdmin);

        /// @custom:event NewTokenSplitter
        emit NewVegaContract(address(0), _vegaTokenManager);
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            5. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Private ────────────────────────────────────────────────  */

    /**
     *  @param tokenA Address of the first token from the LP Token
     *  @param tokenB Address of the second token from the LP Token
     */
    function getTokensPrivate(address lpTokenPair) private view returns (address tokenA, address tokenB) {
        tokenA = IDexPair(lpTokenPair).token0();
        tokenB = IDexPair(lpTokenPair).token1();
    }

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @inheritdoc ICygnusFactory
     */
    function shuttlesLength() external view override returns (uint256) {
        return allShuttles.length;
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            6. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Private ────────────────────────────────────────────────  */

    /**
     *  @notice Prepares lending pool for launch.
     *  @param lpTokenPair Address of the DEX' LP Token.
     */
    function createShuttlePrivate(address lpTokenPair) private {
        /// @custom:error Avoid initializing two identical shuttles
        if (getShuttles[lpTokenPair].shuttleID != 0) {
            return;
        }

        // Push to lending pool
        allShuttles.push(lpTokenPair);

        // Update internal accounting
        getShuttles[lpTokenPair] = Shuttle(
            false,
            uint16(allShuttles.length), // Lending pool ID
            address(0), // Collateral address
            address(0), // Borrow token A address
            address(0) // Borrow token B address
        );
    }

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice Creates a collateral contract based on the LP Token and adds it to record.
     *  @inheritdoc ICygnusFactory
     */
    function createCollateral(address lpTokenPair) external override returns (address collateral) {
        getTokensPrivate(lpTokenPair);

        /// @custom:error Avoid deploying identical pool twice
        if (getShuttles[lpTokenPair].collateral != address(0)) {
            revert CygnusFactory__ShuttleAlreadyExists(lpTokenPair);
        }

        // Deploy collateral
        collateral = collateralDeployer.deployDeneb(lpTokenPair, address(this));

        // Assign msg.sender to factory to the Collateral token
        ICygnusCollateral(collateral).setHangar18();

        // Check if exists
        createShuttlePrivate(lpTokenPair);

        // Add the Collateral member to the Shuttle struct
        getShuttles[lpTokenPair].collateral = collateral;
    }

    /**
     *  @notice Creates the first Borrow arm for the above collateral and adds it to record.
     *  @inheritdoc ICygnusFactory
     */
    function createBorrowTokenA(address lpTokenPair) external override returns (address borrowDAITokenA) {
        getTokensPrivate(lpTokenPair);

        /// @custom:error Avoid deploying identical pool twice
        if (getShuttles[lpTokenPair].borrowDAITokenA != address(0)) {
            revert CygnusFactory__ShuttleAlreadyExists(lpTokenPair);
        }

        // Deploy collateral
        borrowDAITokenA = borrowDeployer.deployAlbireo(lpTokenPair, "A");

        // Assign msg.sender to factory to the Collateral token
        ICygnusBorrow(borrowDAITokenA).setHangar18();

        // Check if exists
        createShuttlePrivate(lpTokenPair);

        // Add the Collateral member to the Shuttle struct
        getShuttles[lpTokenPair].borrowDAITokenA = borrowDAITokenA;
    }

    /**
     *  @notice Creates the second Borrow arm for the above collateral and adds it to record.
     *  @inheritdoc ICygnusFactory
     */
    function createBorrowTokenB(address lpTokenPair) external override returns (address borrowDAITokenB) {
        getTokensPrivate(lpTokenPair);

        /// @custom:error Avoid deploying identical pool twice
        if (getShuttles[lpTokenPair].borrowDAITokenB != address(0)) {
            revert CygnusFactory__ShuttleAlreadyExists(lpTokenPair);
        }

        // Deploy collateral
        borrowDAITokenB = borrowDeployer.deployAlbireo(lpTokenPair, "B");

        // Assign msg.sender to factory to the Collateral token
        ICygnusBorrow(borrowDAITokenB).setHangar18();

        // Check if exists
        createShuttlePrivate(lpTokenPair);

        // Add the Collateral member to the Shuttle struct
        getShuttles[lpTokenPair].borrowDAITokenB = borrowDAITokenB;
    }

    /**
     *  @inheritdoc ICygnusFactory
     */
    function initializeShuttle(address lpTokenPair) external override {
        (address tokenA, address tokenB) = getTokensPrivate(lpTokenPair);

        Shuttle memory shuttle = getShuttles[lpTokenPair];

        /// @custom:error Avoid initializing the same shuttle twice
        if (shuttle.isInitialized) {
            revert CygnusFactory__ShuttleAlreadyInitialized(lpTokenPair);
        }

        /// @custom:error Avoid initializing shuttle without collateral contract
        if (shuttle.collateral == address(0)) {
            revert CygnusFactory__CollateralNotCreated();
        }

        /// @custom:error Avoid initializing shuttle without first borrow arm
        if (shuttle.borrowDAITokenA == address(0)) {
            revert CygnusFactory__FirstBorrowArmNotCreated();
        }

        /// @custom:error Avoid initializing shuttle without second borrow arm
        if (shuttle.borrowDAITokenB == address(0)) {
            revert CygnusFactory__SecondBorrowArmNotCreated();
        }

        // UPDATE: Oracle, Collateral, BorrowDAITokenA and BorrowDAITokenB for this pool
        // Get oracle status
        (, , , , , bool nebulaOracleInitialized) = cygnusNebulaOracle.getCygnusNebulaPair(lpTokenPair);

        // Initialize oracle
        if (!nebulaOracleInitialized) {
            cygnusNebulaOracle.initializeCygnusNebula(lpTokenPair);
        }

        // Initialize collateral
        ICygnusCollateral(shuttle.collateral).initializeCollateral(
            lpTokenPair,
            shuttle.borrowDAITokenA,
            shuttle.borrowDAITokenB
        );

        // Initialize first borrow Arm
        ICygnusBorrow(shuttle.borrowDAITokenA).initializeBorrow(tokenA, shuttle.collateral);

        // Initialize second borrow Arm
        ICygnusBorrow(shuttle.borrowDAITokenA).initializeBorrow(tokenB, shuttle.collateral);

        // This specific lending pool is initialized can't be deployed again
        getShuttles[lpTokenPair].isInitialized = true;

        /// @custom:event NewShuttleLaunched
        emit NewShuttleLaunched(
            lpTokenPair,
            tokenA,
            tokenB,
            shuttle.shuttleID,
            shuttle.collateral,
            shuttle.borrowDAITokenA,
            shuttle.borrowDAITokenB
        );
    }
}


// File contracts/cygnus-core/libraries/UQ112x112.sol

// ignore: GPL-3.0
pragma solidity >=0.8.4;

// Uniswap library
// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
    uint224 public constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}


// File contracts/cygnus-core/CygnusNebulaOracle.sol

// ignore: Unlicensed
pragma solidity >=0.8.4;

// dependencies

// libraries


// interfaces

/**
 *  @title CygnusNebula TWAP Oracle
 *  @notice Taken from uniswap/impermax's implementation
 */
contract CygnusNebulaOracle is ICygnusNebulaOracle {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. LIBRARIES 
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:library UQ112x112 Uniswap's fixed point library for uint112
     */
    using UQ112x112 for uint224;

    /**
     *  @custom:library PRBMathUD60x18 for fixed point math, also imports the main library `PRBMath`.
     */
    using PRBMath for uint256;

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. STORAGE
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @inheritdoc ICygnusNebulaOracle
     */
    uint32 public constant override minimumTimeWindow = 10 minutes;

    /**
     *  @notice LP Token pair info
     */
    struct CygnusNebulaPair {
        uint256 priceCumulativeSlotA;
        uint256 priceCumulativeSlotB;
        uint32 lastUpdateSlotA;
        uint32 lastUpdateSlotB;
        bool latestIsSlotA;
        bool initialized;
    }

    /**
     *  @inheritdoc ICygnusNebulaOracle
     */
    mapping(address => CygnusNebulaPair) public override getCygnusNebulaPair;

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            5. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @inheritdoc ICygnusNebulaOracle
     */
    function getBlockTimestamp() public view override returns (uint32) {
        return uint32(block.timestamp);
    }

    /*  ────────────────────────────────────────────── Internal ───────────────────────────────────────────────  */

    /**
     *  @param lpTokenPair The address of the LP Token pair.
     *  @return priceCumulative The uint256 current price cumulative.
     */
    function getCurrentCumulativePrice(address lpTokenPair) internal view returns (uint256 priceCumulative) {
        priceCumulative = IDexPair(lpTokenPair).price0CumulativeLast();

        // Get cached reserves
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IDexPair(lpTokenPair).getReserves();

        // Encodes a UQ112x112 number and decodes into a uint224
        uint224 priceLatest = UQ112x112.encode(reserve1).uqdiv(reserve0);

        // Get time elapsed since last recorded update
        uint32 timeElapsed = getBlockTimestamp() - blockTimestampLast;

        // Update price cumulative price with the time elapsed
        priceCumulative += uint256(priceLatest) * timeElapsed;
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            6. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @inheritdoc ICygnusNebulaOracle
     */
    function initializeCygnusNebula(address lpTokenPair) external override {
        CygnusNebulaPair storage cygnusNebulaStorage = getCygnusNebulaPair[lpTokenPair];

        /// @custom:error PairIsInitialized
        if (cygnusNebulaStorage.initialized) {
            revert CygnusNebulaOracle__PairIsInitialized(lpTokenPair);
        }

        // Get the price cumulative current
        uint256 priceCumulativeCurrent = getCurrentCumulativePrice(lpTokenPair);

        // Get the uint32 blocktimestamp
        uint32 blockTimestamp = getBlockTimestamp();

        // Update current price cumulative for Token A
        cygnusNebulaStorage.priceCumulativeSlotA = priceCumulativeCurrent;

        // Update current price cumulative for Token B
        cygnusNebulaStorage.priceCumulativeSlotB = priceCumulativeCurrent;

        // Udate last update slot for Token A
        cygnusNebulaStorage.lastUpdateSlotA = blockTimestamp;

        // Udate last update slot for Token B
        cygnusNebulaStorage.lastUpdateSlotB = blockTimestamp;

        // Latest and initialized
        cygnusNebulaStorage.latestIsSlotA = true;
        cygnusNebulaStorage.initialized = true;

        /// @custom:event UpdateLPTokenPrice
        emit UpdateLPTokenPrice(lpTokenPair, priceCumulativeCurrent, blockTimestamp, true);
    }

    /**
     *  @inheritdoc ICygnusNebulaOracle
     */
    function getResult(address lpTokenPair)
        external
        override
        returns (uint224 timeWeightedPrice112x112, uint32 timeWindow)
    {
        CygnusNebulaPair memory pair = getCygnusNebulaPair[lpTokenPair];

        /// @custom:error Avoid if pair is not initialized
        if (!pair.initialized) {
            revert CygnusNebulaOracle__PairNotInitialized(lpTokenPair);
        }

        // storage
        CygnusNebulaPair storage cygnusNebulaStorage = getCygnusNebulaPair[lpTokenPair];

        // Get the uint32 blocktimestamp
        uint32 blockTimestamp = getBlockTimestamp();

        // Get last update timestamp
        uint32 lastUpdateTimestamp = pair.latestIsSlotA ? pair.lastUpdateSlotA : pair.lastUpdateSlotB;

        uint256 priceCumulativeCurrent = getCurrentCumulativePrice(lpTokenPair);

        uint256 priceCumulativeLast;

        if (blockTimestamp - lastUpdateTimestamp >= minimumTimeWindow) {
            // Get latest price
            priceCumulativeLast = pair.latestIsSlotA ? pair.priceCumulativeSlotA : pair.priceCumulativeSlotB;

            if (pair.latestIsSlotA) {
                cygnusNebulaStorage.priceCumulativeSlotB = priceCumulativeCurrent;

                cygnusNebulaStorage.lastUpdateSlotB = blockTimestamp;
            } else {
                cygnusNebulaStorage.priceCumulativeSlotA = priceCumulativeCurrent;

                cygnusNebulaStorage.lastUpdateSlotA = blockTimestamp;
            }

            cygnusNebulaStorage.latestIsSlotA = !pair.latestIsSlotA;

            /// @custom:event UpdateLPTokenPrice
            emit UpdateLPTokenPrice(lpTokenPair, priceCumulativeCurrent, blockTimestamp, !pair.latestIsSlotA);
        } else {
            // Don't update
            lastUpdateTimestamp = pair.latestIsSlotA ? pair.lastUpdateSlotB : pair.lastUpdateSlotA;

            priceCumulativeLast = pair.latestIsSlotA ? pair.priceCumulativeSlotB : pair.priceCumulativeSlotA;
        }

        // This call's time window
        timeWindow = blockTimestamp - lastUpdateTimestamp;

        /// @custom:error Reverts only if the pair has been initialized
        if (timeWindow < minimumTimeWindow) {
            revert CygnusNebulaOracle__TimeWindowTooSmall(timeWindow);
        }

        // Update price
        timeWeightedPrice112x112 = uint224((priceCumulativeCurrent - priceCumulativeLast) / minimumTimeWindow);
    }
}


// File contracts/cygnus-core/CygnusTerminal.sol

// ignore: Unlicense
/* .        .               .          .         . 🛸                .                            . 
       █████████           ---======*.                                                 .           ⠀
      ███░░░░░███                                              📡                                         🌔
     ███     ░░░  █████ ████  ███████ ████████   █████ ████  █████        ⠀
    ░███         ░░███ ░███  ███░░███░░███░░███ ░░███ ░███  ███░░      .     .⠀        🛰️   .           .
    ░███          ░███ ░███ ░███ ░███ ░███ ░███  ░███ ░███ ░░█████       ⠀
    ░░███     ███ ░███ ░███ ░███ ░███ ░███ ░███  ░███ ░███  ░░░░███              .             *⠀
     ░░█████████  ░░███████ ░░███████ ████ █████ ░░████████ ██████       ⠀
      ░░░░░░░░░    ░░░░░███  ░░░░░███░░░░ ░░░░░   ░░░░░░░░ ░░░░░░            .                            .⠀
                   ███ ░███  ███ ░███                .                 .         🛸           ⠀
     .      *     ░░██████  ░░██████   .                         🛰️                 .                               .⠀
                   ░░░░░░    ░░░░░░                                                 ⠀
       .                            .       *         .----===*             .                          .⠀

     https://cygnusdao.finance                                                           
     
     Smart contracts to `go long` on your LP Token.

     Deposit LP Token, borrow stablecoins. 

     Farmers may leverage up to 8x their LP Token value putting their LP Token as collateral, but may suffer
     loss from liquidations if the debt ratio goes above limit.

     Lenders act as `investors` in lending pools, and earn from both interest rates and a % of the yield.
     If another pool gets too crazy, their investment is always safe as each lending pool is isolated from
     the rest.

     Cygnus comes in 2 flavours: `normal` and `multi-player`. 

     Normal are globa pools allowed by CygnusDAO. 
     Multi-player are pools that only whitelisted addresses can join and anyone can deploy. In these pools there 
     is only 1 borrower and there can be many lenders.

     Structure of all Cygnus Contracts

     Contract                        ⠀Interface                                             
        ├ 1. Libraries                   ├ 1. Errors                                               
        ├ 2. Modifiers                   ├ 2. Events                                               
        ├ 3. Storage                 ⠀   ├ 3. Constant Functions                          ⠀        
        │     ├ Private                  │     ├ Public                            ⠀       
        │     ├ Internal                 │     └ External                        ⠀⠀⠀              
        │     └ Public               ⠀   └ 4. Non-Constant Functions  
        ├ 4. Constructor             ⠀         ├ Public
        ├ 5. Constant Functions      ⠀         └ External           
        │     ├ Private              
        │     ├ Internal             
        │     ├ Public               
        │     └ External             
        └ 6. Non-Constant Functions  
              ├ Private              
              ├ Internal             
              ├ Public               
              └ External                           


    @dev: Should only be tested with Solidity >=0.8 as some functions don't check for overflow/underflow 
    and all errors are handled with the new `custom errors` feature among other small things...                */

pragma solidity >=0.8.4;

// Dependencies


// Libraries


// Factory

// Cygnus Price Oracle

/**
 *  @title CygnusTerminal
 *  @author CygnusDAO
 *  @notice Contract used to mint Collateral and Borrow tokens and to set Factory and Admin rights
 */
contract CygnusTerminal is ICygnusTerminal, Erc20Permit {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. LIBRARIES
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:library SafeErc20 For Redeem and Skim functions
     */
    using SafeErc20 for IErc20;

    /**
     *  @custom:library PRBMathUD60x18 For Fixed point 18 decimal math library
     */
    using PRBMathUD60x18 for uint256;

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. MODIFIERS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Force update real balance after mint and redeem functions
     */
    modifier update() {
        _;
        updateInternal();
    }

    /**
     *  @notice For functions which only the Cygnus admins should have access to 👽
     */
    modifier cygnusAdmin() {
        isCygnusAdmin();
        _;
    }

    /**
     *  @notice For functions which only the Factory should have access to 🛸
     */
    modifier cygnusHangar18() {
        isHangar18();
        _;
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. STORAGE
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Internal ───────────────────────────────────────────────  */

    /**
     *  @notice The initial rate at which 1 unit of the underlying can be redeemed for (always 1)
     */
    uint256 internal constant initialRate = 1e18;

    /**
     *  @notice The minimum liquidity pool tokens needed in the pool, send to address(0)
     *  @dev Same as Uniswap's minimum liquidity requirement
     */
    uint32 internal constant minimumLiquidity = 10**3;

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
     *  @notice Factory address. 🛸
     *  @inheritdoc ICygnusTerminal
     */
    address public override hangar18;

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. CONSTRUCTOR
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Constructs tokens for both Collateral and Borrow arms
     *  @dev Erc20Permit constructs Erc20, creating the permit for both borrow and collateral
     *  @dev Later we create another borrow permit for Borrow arm in CygnusBorrowApprove contract
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
            5. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Internal ───────────────────────────────────────────────  */
    /**
     *  @notice 👽
     &  @notice Basically for CygnusCollateralControl and CygnusBorrowControl contracts
     */
    function isCygnusAdmin() internal view {
        /// @custom:error Avoid unless caller is Cygnus Admin
        if (_msgSender() != ICygnusFactory(hangar18).admin()) {
            revert CygnusTerminal__MsgSenderNotAdmin(_msgSender());
        }
    }

    /**
     *  @notice 🛸
     *  @notice Basically to initialize Albireo and Deneb pools
     */
    function isHangar18() internal view {
        /// @custom:error Avoid unless caller is Factory contract
        if (_msgSender() != hangar18) {
            revert CygnusTerminal__MsgSenderNotFactory(_msgSender());
        }
    }

    /**
     *  @notice Gets the total balance of this contract in terms of the underlying
     */
    function updateInternal() internal {
        totalBalance = IErc20(underlying).balanceOf(address(this));

        /// @custom:event Sync
        emit Sync(totalBalance);
    }

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @inheritdoc ICygnusTerminal
     */
    function exchangeRate() public view virtual override returns (uint256) {
        // Gas savings
        uint256 _totalSupply = totalSupply;

        // If there is no supply for this token return initial (1e18), else totalBalance * 1e18 / totalSupply
        return _totalSupply == 0 ? initialRate : totalBalance.div(_totalSupply);
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            6. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice Sets factory 🛸 Only callable once
     *  @inheritdoc ICygnusTerminal
     */
    function setHangar18() external override {
        /// @custom:error Avoid if factory already exists
        if (hangar18 != address(0)) {
            revert CygnusTerminal__FactoryAlreadyInitialized(_msgSender());
        }

        // Assign Cygnus factory
        hangar18 = _msgSender();
    }

    /**
     *  @notice This low level function should only be called by `Vega` contract
     *  @inheritdoc ICygnusTerminal
     */
    function mint(address minter) external override nonReentrant update returns (uint256 poolTokens) {
        uint256 balance = IErc20(underlying).balanceOf(address(this));

        // Get mint amount
        uint256 mintAmount = balance - totalBalance;

        // Get tokens by exchange rate
        poolTokens = mintAmount.div(exchangeRate());

        // Only for the very first deposit
        if (totalSupply == 0) {
            // Substract from mint amount
            poolTokens -= minimumLiquidity;

            // Burn to zero address, emit transfer event
            mintInternal(address(0), minimumLiquidity);
        }

        /// custom:error Avoid minting zero tokens
        if (poolTokens <= 0) {
            revert CygnusTerminal__CantMintZero(poolTokens);
        }

        // Burn tokens, emit Transfer event
        mintInternal(minter, poolTokens);

        /// @custom:event Mint
        emit Mint(_msgSender(), minter, mintAmount, poolTokens);
    }

    /**
     *  @notice This low level function should only be called by `Vega` contract
     *  @inheritdoc ICygnusTerminal
     */
    function redeem(address holder) external override nonReentrant update returns (uint256 redeemAmount) {
        uint256 poolTokens = balanceOf(address(this));

        // Get the initial amount times the calculated exchange rate
        redeemAmount = poolTokens.mul(exchangeRate());

        /// @custom:error Avoid burning zero
        if (redeemAmount <= 0) {
            revert CygnusTerminal__CantBurnZero(redeemAmount);
        }
        /// @custom:error Avoid burning invalid amount
        else if (redeemAmount > totalBalance) {
            revert CygnusTerminal__BurnAmountInvalid(totalBalance);
        }

        // Burn initial amount and emit Transfer event
        burnInternal(address(this), poolTokens);

        // Optimistically transfer redeemed tokens
        IErc20(underlying).safeTransfer(holder, redeemAmount);

        /// @custom:event Burn
        emit Redeem(_msgSender(), holder, redeemAmount, poolTokens);
    }

    /**
     *  @inheritdoc ICygnusTerminal
     */
    function skim(address to) external override nonReentrant {
        // Uniswap's function to force real balance to match totalBalance
        IErc20(underlying).safeTransfer(to, balanceOf(address(this)) - totalBalance);
    }

    /**
     *  @inheritdoc ICygnusTerminal
     */
    function sync() external virtual override nonReentrant update {}
}


// File contracts/cygnus-core/CygnusBorrowControl.sol

// ignore: Unlicensed
pragma solidity >=0.8.4;

// Dependencies


/**
 *  @title CygnusBorrowControl
 *  @notice Parent contract of the Borrow arm. It control important borrow parameters.
 *  @dev Used to initialize the borrow contracts by Factory and assign the collateral contract for this token.
 */
contract CygnusBorrowControl is ICygnusBorrowControl, CygnusTerminal {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. STORAGE
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Private ────────────────────────────────────────────────  */

    /**
     *  @notice Name of the Erc20 borrow token.
     *  @dev Passed in constructor and assigned to Erc20 public `name`.
     */
    string private constant BORROW_NAME = "Cygnus: Borrow";

    /**
     *  @notice Symbol of the Erc20 borrow token.
     *  @dev Passed in constructor and assigned to Erc20 public `symbol`.
     */
    string private constant BORROW_SYMBOL = "Albireo";

    /**
     *  @notice Decimals of the Erc20 borrow token
     *  @dev Passed in constructor and assigned to Erc20 public `decimals`.
     */
    uint8 private constant DECIMALS = 18;

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @inheritdoc ICygnusBorrowControl
     */
    address public override collateral;

    /// UPDATE THIS
    /**
     *  @notice Borrow Tracker
     */
    address public override cygnusBorrowTracker;

    /**
     *  @inheritdoc ICygnusBorrowControl
     */
    uint256 public constant override BASE_RATE_MAX = 0.10e18;

    /**
     *  @inheritdoc ICygnusBorrowControl
     */
    uint256 public override baseRate;

    /**
     *  @inheritdoc ICygnusBorrowControl
     */
    uint256 public override farmMultiplier;

    /**
     *  @inheritdoc ICygnusBorrowControl
     */
    uint256 public override kink;

    /**
     *  @inheritdoc ICygnusBorrowControl
     */
    uint256 public override reserveFactor;

    /**
     *  @inheritdoc ICygnusBorrowControl
     */
    uint256 public constant override CYGNUS_BORROW_FEE = 0.002e18;

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
    uint256 public constant override RESERVE_FACTOR_MAX = 0.20e18;

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. CONSTRUCTOR
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Constructs the Borrow arm.
     *  @notice Passes to CygnusTerminal the Borrow Token with following standard Erc20 parameters.
     */
    constructor()
        /// @param BORROW_NAME The name of ERC20 borrow token
        /// @param BORROW_SYMBOL The symbol of ERC20 borrow token
        /// @param DECIMALS Decimals used (always 18).
        CygnusTerminal(BORROW_NAME, BORROW_SYMBOL, DECIMALS)
    {}

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            5. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Private ────────────────────────────────────────────────  */

    /**
     *  @notice Private function to check if new parameter is within range when updating interest rate model.
     *  @param min The minimum value allowed for the parameter that is being updated.
     *  @param max The maximum value allowed for the parameter that is being updated.
     *  @param parameter The value of the parameter that is being updated.
     */
    function validRange(
        uint256 min,
        uint256 max,
        uint256 parameter
    ) internal pure {
        /// @custom:error Avoid outside range
        if (parameter <= min || parameter >= max) {
            revert CygnusBorrowControl__ParameterNotInRange(parameter);
        }
    }

    /*  ────────────────────────────────────────────── Internal ───────────────────────────────────────────────  */

    /**
     *  @notice Checks for uint112 overflow for borrow contracts. This should not be needed with new solidity.
     *  @notice We keep it in case something goes terribly wrong.
     *  @param input uint256 input to check if overflows a uint112 type. If overflow, revert.
     *  @return The input casted as a uint112 type.
     */
    function toUint112(uint256 input) internal pure returns (uint112) {
        if (input > type(uint112).max) {
            revert CygnusBorrowControl__Uint112Overflow();
        }
        return uint112(input);
    }

    /**
     *  @notice Set it as internal to be used by later borrow functions.
     *  @return The uint32 block timestamp.
     */
    function getBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp);
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            6. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice 🛸
     *  @inheritdoc ICygnusBorrowControl
     */
    function initializeBorrow(address _underlying, address _collateral) external override cygnusHangar18 {
        /// @custom:error Avoid if msg.sender is not factory.
        if (_msgSender() != hangar18) {
            revert CygnusTerminal__MsgSenderNotFactory(_msgSender());
        }

        underlying = _underlying;

        collateral = _collateral;
    }

    /**
     *  @notice 👽
     *  @inheritdoc ICygnusBorrowControl
     */
    function setReserveFactor(uint256 newReserveFactor) external override cygnusAdmin nonReentrant {
        // checks if parameter is within range allowed.
        validRange(0, RESERVE_FACTOR_MAX, newReserveFactor);

        // it is, update reserve factor
        reserveFactor = newReserveFactor;

        /// @custom:event NewReserveFactor
        emit NewReserveFactor(newReserveFactor);
    }

    /**
     *  @notice 👽
     *  @inheritdoc ICygnusBorrowControl
     */
    function setBaseRate(uint256 newBaseRate) external override cygnusAdmin nonReentrant {
        // checks if parameter within range
        validRange(0, BASE_RATE_MAX, newBaseRate);

        // it is, update base rate
        baseRate = newBaseRate;

        /// @custom:event NewBaseRate
        emit NewBaseRate(newBaseRate);
    }

    /**
     *  @notice 👽
     *  @inheritdoc ICygnusBorrowControl
     */
    function setFarmMultiplier(uint256 newFarmMultiplier) external override cygnusAdmin nonReentrant {
        validRange(1e16, 1e20, newFarmMultiplier);

        // it is, update multiplier
        farmMultiplier = newFarmMultiplier;

        /// @custom:event NewLogFarmMultiplier
        emit NewFarmMultiplier(newFarmMultiplier);
    }

    /**
     *  @notice 👽
     *  @inheritdoc ICygnusBorrowControl
     */
    function setKinkUtilizationRate(uint256 newKinkUtilizationRate) external override cygnusAdmin nonReentrant {
        // checks if parameter is within range allowed.
        validRange(KINK_UTILIZATION_RATE_MIN, KINK_UTILIZATION_RATE_MAX, newKinkUtilizationRate);

        // it is, update kinkUtilizationRate
        kink = newKinkUtilizationRate;

        /// @custom:event NewKinkUtilizationRate
        emit NewKinkUtilizationRate(newKinkUtilizationRate);
    }
}


// File contracts/cygnus-core/CygnusBorrowApprove.sol

// ignore: Unlicensed
pragma solidity >=0.8.4;

// Dependencies


/**
 *  @title CygnusBorrowApprove
 *  @dev Contract for approving Borrow allowances
 */
contract CygnusBorrowApprove is ICygnusBorrowApprove, CygnusBorrowControl {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. STORAGE
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @inheritdoc ICygnusBorrowApprove
     */
    bytes32 public immutable override BORROW_PERMIT_TYPEHASH;

    /**
     *  @inheritdoc ICygnusBorrowApprove
     */
    mapping(address => mapping(address => uint256)) public override accountBorrowAllowances;

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. CONSTRUCTOR
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Constructs permits for both borrow contracts using the same domain separator
     */
    constructor() {
        BORROW_PERMIT_TYPEHASH = keccak256(
            "BorrowDAIPermit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            6. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Private ────────────────────────────────────────────────  */

    /**
     *  @notice Safe private function which updates allowances after doing sufficient checks
     *  @dev Emits an approval event
     *  @param owner The address of the owner of the tokens
     *  @param spender The address of the person given the allowance
     *  @param amount The max amount of tokens the spender can spend
     */
    function borrowApproveInternal(
        address owner,
        address spender,
        uint256 amount
    ) private {
        accountBorrowAllowances[owner][spender] = amount;

        /// @custom:event BorrowApproved
        emit BorrowApproved(owner, spender, amount);
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
        uint256 currentAllowance = accountBorrowAllowances[owner][spender];

        /// custom:error Avoid self
        if (owner == spender) {
            revert CygnusBorrowApprove__OwnerIsSpender(owner, spender);
        }
        /// @custom:error Avoid the owner being the zero address
        if (owner == address(0)) {
            revert CygnusBorrowApprove__OwnerZeroAddress(owner);
        }
        /// @custom:error Avoid the spender being the zero address
        if (spender == address(0)) {
            revert CygnusBorrowApprove__SpenderZeroAddress(spender);
        }
        /// custom:error Avoid amount higher than user's allowance
        if (currentAllowance < amount) {
            revert CygnusBorrowApprove__InsufficientBorrowAmount(currentAllowance);
        }

        // Updates the borrow allowance in the next function call
        borrowApproveInternal(owner, spender, currentAllowance - amount);
    }

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

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
        /// @custom:error Avoid owner being the zero address
        if (owner == address(0)) {
            revert CygnusBorrowApprove__OwnerZeroAddress(owner);
        }
        /// @custom:error Avoid spender being the zero address
        if (spender == address(0)) {
            revert CygnusBorrowApprove__SpenderZeroAddress(spender);
        }
        /// @custom:error Avoid living in the past
        if (deadline < block.timestamp) {
            revert CygnusBorrowApprove__PermitExpired(deadline);
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

        /// @custom:error Avoid the zero address being the recovered owner
        if (recoveredOwner == address(0)) {
            revert CygnusBorrowApprove__RecoveredOwnerZeroAddress(recoveredOwner);
        }
        /// @custom:error Avoid invalid recovered owner
        if (recoveredOwner != owner) {
            revert CygnusBorrowApprove__InvalidSignature(v, r, s);
        }

        // Finally approve internally
        borrowApproveInternal(owner, spender, value);
    }

    /**
     *  @inheritdoc ICygnusBorrowApprove
     */
    function accountBorrowApprove(address spender, uint256 value) external override returns (bool) {
        // Safe to pass bool function
        borrowApproveInternal(_msgSender(), spender, value);

        return true;
    }
}


// File contracts/cygnus-core/CygnusBorrowInterest.sol

// ignore: Unlicensed
pragma solidity >=0.8.4;

// Dependencies


/**
 *  @title CygnusBorrowInterest
 *  @notice Interest rate model contract for Cygnus.
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
            3. STORAGE
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @inheritdoc ICygnusBorrowInterest
     */
    uint256 public constant override SECONDS_PER_YEAR = 31536000;

    /**
     *  @inheritdoc ICygnusBorrowInterest
     */
    uint256 public override multiplierPerSecond;

    /**
     *  @inheritdoc ICygnusBorrowInterest
     */
    uint256 public override baseRatePerSecond;

    /**
     *  @inheritdoc ICygnusBorrowInterest
     */
    uint256 public override jumpMultiplierPerSecond;

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            5. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @inheritdoc ICygnusBorrowInterest
     */
    function utilizationRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves
    ) public pure override returns (uint256) {
        // Utilization rate is 0 when there are no borrows
        if (borrows == 0) {
            return 0;
        }

        uint256 util = PRBMath.mulDiv(borrows, 1e18, cash + borrows - reserves);

        return util;
    }

    /**
     *  @inheritdoc ICygnusBorrowInterest
     */
    function getBorrowRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves
    ) public view override returns (uint256) {
        uint256 util = utilizationRate(cash, borrows, reserves);
        if (util <= kink) {
            return PRBMath.mulDivFixedPoint(util, multiplierPerSecond) + baseRatePerSecond;
        } else {
            uint256 normalRate = PRBMath.mulDivFixedPoint(kink, multiplierPerSecond) + baseRatePerSecond;

            uint256 excessUtil = util - kink;

            return PRBMath.mulDivFixedPoint(excessUtil, jumpMultiplierPerSecond) + normalRate;
        }
    }

    /**
     *  @inheritdoc ICygnusBorrowInterest
     */
    function getSupplyRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves,
        uint256 reserveFactorMantissa
    ) public view override returns (uint256) {
        // Substract the reserveFactor of this market from scale
        uint256 oneMinusReserveFactor = uint256(1e18) - reserveFactorMantissa;

        // Get the present borrow rate for this market.
        uint256 borrowRate = getBorrowRate(cash, borrows, reserves);

        // Get the borrow rate without taking into account the reserves
        uint256 rateToPool = PRBMath.mulDivFixedPoint(borrowRate, oneMinusReserveFactor);

        // Return the supply rate (borrow rate * utilization)
        return PRBMath.mulDivFixedPoint(utilizationRate(cash, borrows, reserves), rateToPool);
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            6. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Private ────────────────────────────────────────────────  */

    /**
     * @notice Updates the parameters of the interest rate model and writes to storage.
     * @dev Does necessary checks internally. Reverts in case of failing checks.
     * @param baseRatePerYear The approximate target base APR, as a mantissa (scaled by 1e18).
     * @param multiplierPerYear The rate of increase in interest rate wrt utilization (scaled by 1e18).
     * @param jumpMultiplierPerYear The multiplierPerSecond after hitting a specified utilization point.
     * @param kink_ The utilization point at which the jump multiplier is applied.
     */
    function updateJumpRateModelInternal(
        uint256 baseRatePerYear,
        uint256 multiplierPerYear,
        uint256 jumpMultiplierPerYear,
        uint256 kink_
    ) internal {
        // Internal parameter check for BaseRate to not exceed maximum allowed (10%).
        validRange(0, BASE_RATE_MAX, baseRatePerYear);

        // Internal parameter check for farmMultiplier to not be below minimum or above maximum allowed.
        validRange(1e16, 1e20, multiplierPerYear);

        // Internal parameter check for the Kink point to not be below minimum or above maximum allowed.
        validRange(KINK_UTILIZATION_RATE_MIN, KINK_UTILIZATION_RATE_MAX, kink_);

        // Calculate the Base Rate per second and update to storage
        baseRatePerSecond = baseRatePerYear / SECONDS_PER_YEAR;

        // Calculate the Farm Multiplier per second and update to storage
        multiplierPerSecond = PRBMath.mulDiv(multiplierPerYear, 1e18, (SECONDS_PER_YEAR * kink_));

        // Calculate the Jump Multiplier per second and update to storage
        jumpMultiplierPerSecond = jumpMultiplierPerYear / SECONDS_PER_YEAR;

        // Update kink utilization
        kink = kink_;

        /// @custom:event NewInterestParameter
        emit NewInterestParameter(baseRatePerYear, multiplierPerYear, jumpMultiplierPerYear, kink_);
    }

    /*  ──────────────────────────────────── External ────────────────────────────────────  */

    /**
     *  @notice 👽
     *  @inheritdoc ICygnusBorrowInterest
     */
    function updateJumpRateModel(
        uint256 baseRatePerYear,
        uint256 multiplierPerYear,
        uint256 jumpMultiplierPerYear,
        uint256 kink_
    ) external override cygnusAdmin {
        updateJumpRateModelInternal(baseRatePerYear, multiplierPerYear, jumpMultiplierPerYear, kink_);
    }
}


// File contracts/cygnus-core/CygnusBorrowTracker.sol

// ignore: Unlicensed
pragma solidity >=0.8.4;

// Dependencies



/**
 *  @title CygnusBorrowTracker
 *  @notice Contract that accrues interest and tracks borrows for this market
 *  @notice It is basically the contract that records all borrower's positions.
 *  @dev It is used by both Borrow and Collateral contracts.
 */
contract CygnusBorrowTracker is ICygnusBorrowTracker, CygnusBorrowInterest, CygnusBorrowApprove {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. LIBRARIES
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:library PRBMathUD60x18 for fixed point math (uint256 only)
     */
    using PRBMathUD60x18 for uint256;

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. MODIFIERS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Triggers accruals to all borrows and reserves before the function.
     *  @notice Used by borrow/repay, liquidate functions.
     */
    modifier accrue() {
        accrueInterest();
        _;
    }

    /**
     *  @notice Updates the underlying's total balance before accruing interest.
     *  @notice Avoids loading totalbalance from storage as always sync
     */
    modifier updateBefore() {
        updateInternal();
        _;
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. STORAGE
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Internal ───────────────────────────────────────────────  */

    /**
     *  @notice Internal mapping of account addresses to outstanding borrow balances
     */
    mapping(address => BorrowSnapshot) internal borrowBalances;

    //  PUBLIC

    /**
     *  @notice Container for borrow balance information
     *  @member principal Total balance (with accrued interest) as of the most recent action.
     *  @member interestIndex Global borrowIndex as of the most recent balance-changing action
     */

    struct BorrowSnapshot {
        uint256 principal;
        uint256 interestIndex;
    }

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @inheritdoc ICygnusBorrowTracker
     */
    uint256 public override totalReserves;

    /**
     *  @inheritdoc ICygnusBorrowTracker
     */
    uint256 public override totalBorrows;

    /**
     *  @inheritdoc ICygnusBorrowTracker
     */
    uint256 public override borrowIndex = 1e18;

    /**
     *  @inheritdoc ICygnusBorrowTracker
     */
    uint32 public override lastAccrualTimestamp = uint32(block.timestamp);

    /**
     *  @inheritdoc ICygnusBorrowTracker
     */
    uint256 public override borrowRate;

    /**
     *  @inheritdoc ICygnusBorrowTracker
     */
    uint256 public override exchangeRateStored;

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            5. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @dev It is used by CygnusCollateral and CygnusCollateralModel contracts.
     *  @inheritdoc ICygnusBorrowTracker
     */
    function getBorrowBalance(address borrower) public view override returns (uint256) {
        /// @custom:error Avoid invalid address
        if (borrower == address(0)) {
            revert CygnusBorrowTracker__AddressZeroInvalidBalance(borrower);
        }

        // Initialize struct in memory only
        BorrowSnapshot memory borrowSnapshot = borrowBalances[borrower];

        // If interestIndex = 0 then borrowBalance is 0, return 0 to avoid fail division by 0
        if (borrowSnapshot.interestIndex == 0) {
            return 0;
        }

        // Calculate new borrow balance with interest index
        // (borrower.principal * market.borrowIndex) / borrower.borrowIndex
        return (borrowSnapshot.principal * borrowIndex) / borrowSnapshot.interestIndex;
    }

    function trackBorrow(
        address b,
        uint256 o,
        uint256 bi
    ) public override nonReentrant {}

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            6. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Internal ───────────────────────────────────────────────  */

    /**
     *  @param borrower The address of the borrower being tracked.
     *  @param accountBorrows Record of this borrower's total borrows up to this point.
     *  @param borrowIndexStored This account's borrow index up to this point.
     */
    function trackBorrowInternal(
        address borrower,
        uint256 accountBorrows,
        uint256 borrowIndexStored
    ) internal {
        address _cygnusBorrowTracker = cygnusBorrowTracker;

        // If 0 borrow tracker is not initialized
        if (_cygnusBorrowTracker == address(0)) return;

        ICygnusBorrowTracker(_cygnusBorrowTracker).trackBorrow(borrower, accountBorrows, borrowIndexStored);
    }

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @notice updates totalBalance before accruals and emits a sync event.
     *  @inheritdoc ICygnusBorrowTracker
     */
    function accrueInterest() public override updateBefore {
        // Get the present timestamp
        uint32 currentTimestamp = getBlockTimestamp();

        // Get the last accrual timestamp
        uint32 accrualTimestampStored = lastAccrualTimestamp;

        // If present timestamp is the same as the last accrual timestamp, return and do nothing.
        if (accrualTimestampStored == currentTimestamp) {
            return;
        } else {
            // No possible way back now, save current timestamp as last accrual.
            lastAccrualTimestamp = currentTimestamp;
        }

        // Load values from storage
        uint256 cashStored = totalBalance;
        uint256 totalBorrowsStored = totalBorrows;
        uint256 reservesStored = totalReserves;

        // 1. Get BorrowRate
        uint256 borrowRateStored = getBorrowRate(cashStored, totalBorrowsStored, reservesStored);

        // 2. Get time elapsed between present timestamp and last accrued period
        uint32 timeElapsed = currentTimestamp - accrualTimestampStored;

        // 3. Multiply BorrowAPR by the time elapsed
        uint256 interestFactor = borrowRateStored * timeElapsed;

        // 4. Calculate the interest accumulated in this time elapsed.
        uint256 interestAccumulated = interestFactor.mul(totalBorrowsStored);

        // 5. Add the interest accumulated to total borrows.
        totalBorrowsStored += interestAccumulated;

        // 6. Update the borrow index ( new_index = index + (interestfactor * index / 1e18) )
        borrowIndex += interestFactor.mul(borrowIndex);

        // Update new values to storage
        totalBorrows = totalBorrowsStored;
        borrowRate = borrowRateStored;
        totalReserves = reservesStored;

        /// @custom:event AccrueInterest
        emit AccrueInterest(cashStored, interestAccumulated, borrowIndex, totalBorrowsStored, borrowRateStored);
    }
}


// File contracts/cygnus-core/interfaces/ICygnusCallee.sol

// ignore: Unlicensed

pragma solidity >=0.8.4;

interface ICygnusCallee {
    function cygnusBorrow(
        address sender,
        address borrower,
        uint256 borrowAmount,
        bytes calldata data
    ) external;

    function cygnusRedeem(
        address sender,
        uint256 redeemAmount,
        bytes calldata data
    ) external;
}


// File contracts/cygnus-core/CygnusBorrow.sol

// ignore: Unlicensed
pragma solidity >=0.8.4;

// Dependencies


// Interfaces


contract CygnusBorrow is ICygnusBorrow, CygnusBorrowTracker {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. LIBRARIES
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:library For safe transfers of Erc20 tokens.
     */
    using SafeErc20 for IErc20;

    /**
     *  @custom:library PRBMathUD60x18 for uint256 fixed point math, also imports the main library `PRBMath`.
     */
    using PRBMathUD60x18 for uint256;

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
         6. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /* MAYBE SEPARATE THESE INTO 2? */

    /**
     *  @notice Record keeping private function for all borrows, repays and/or liquidations.
     *  @param borrower Address of the borrower or the account the debt is being paid off.
     *  @param borrowAmount The amount of the underlying asset to borrow.
     *  @param repayAmount The amount to repay.
     *  @return accountBorrowsPrior Record of account's total borrows before this event.
     *  @return accountBorrows Record of account's total borrows (accountBorrowsPrior + borrowAmount).
     *  @return totalBorrowsStored Record of the protocol's cummulative total borrows after this event.
     */
    function updateBorrowInternal(
        address borrower,
        uint256 borrowAmount,
        uint256 repayAmount
    )
        private
        returns (
            uint256 accountBorrowsPrior,
            uint256 accountBorrows,
            uint256 totalBorrowsStored
        )
    {
        // Internal view function to get borrower's balance, if borrower's interestIndex = 0 it returns 0.
        accountBorrowsPrior = getBorrowBalance(borrower);

        if (borrowAmount == repayAmount) {
            return (accountBorrowsPrior, accountBorrowsPrior, totalBorrows);
        }

        // The current borrow index
        uint256 borrowIndexStored = borrowIndex;

        // If borrow amount is higher, then this transaction is a borrow transaction.
        // Increase the borrower's account borrows and store it in snapshot
        if (borrowAmount > repayAmount) {
            // The borrowBalance and borrowIndex of the borrower
            BorrowSnapshot storage borrowSnapshot = borrowBalances[borrower];

            // Calculate the actual amount to increase
            uint256 increaseBorrowAmount = borrowAmount - repayAmount;

            // User's borrow balance + new borrow amount
            accountBorrows = accountBorrowsPrior + increaseBorrowAmount;

            // Update the snapshot record of the borrower's principal
            borrowSnapshot.principal = accountBorrows;

            // Update the snapshot record of the present borrow index
            borrowSnapshot.interestIndex = borrowIndexStored;

            // Protocol's Total borrows
            totalBorrows += increaseBorrowAmount;
        }
        // This transaction is a Repay transaction.
        // Decrease the borrower's account borrows and store it in the snapshot
        else {
            // Get borrowBalance and borrowIndex of borrower
            BorrowSnapshot storage borrowSnapshot = borrowBalances[borrower];

            // Calculate the actual amount to decrease
            uint256 decreaseAmount = repayAmount - borrowAmount;

            // The new borrowers balance after this action.
            // If the decrease amount is >= user's prior borrows, return 0, else return the difference.
            accountBorrows = accountBorrowsPrior > decreaseAmount ? accountBorrowsPrior - decreaseAmount : 0;

            // Update the snapshot record of the borrower's principal their new balance
            borrowSnapshot.principal = accountBorrows;

            // If their new account borrows is 0, this transaction repays the full loan.
            if (accountBorrows == 0) {
                // Update user's interest index to 0
                borrowSnapshot.interestIndex = 0;
            } else {
                // Not fully repaid, update the snapshot record of the borrower's index with current index.
                borrowSnapshot.interestIndex = borrowIndexStored;
            }

            // Actual decrease amount
            uint256 actualDecreaseAmount = accountBorrowsPrior - accountBorrows;

            // Total protocol borrows
            // Gas savings
            totalBorrowsStored = totalBorrows;

            // Condition check to calculate protocols total borrows
            if (totalBorrowsStored > actualDecreaseAmount) {
                totalBorrowsStored -= actualDecreaseAmount;
            } else {
                totalBorrowsStored = 0;
            }

            // Update total protocol borrows
            totalBorrows = totalBorrowsStored;
        }
        // Track borrows
        trackBorrowInternal(borrower, accountBorrows, borrowIndexStored);
    }

    /*  ────────────────────────────────────────────── Internal ────────────────────────────────────────────────  */

    // Warning - might need to update

    /**
     *  @param _exchangeRate The new exchange rate
     *  @param _totalSupply  The total supply
     */
    function mintBorrowInternal(uint256 _exchangeRate, uint256 _totalSupply) internal returns (uint256) {
        // Gas savings
        uint256 _exchangeRateLast = exchangeRateStored;

        if (_exchangeRate > _exchangeRateLast) {
            // Round up
            uint256 _exchangeRateNew = _exchangeRate -
                (PRBMath.mulDivFixedPoint(_exchangeRate - _exchangeRateLast, reserveFactor));

            uint256 actualMintAmount = PRBMath.mulDiv(_totalSupply, _exchangeRate, _exchangeRateNew) - _totalSupply;
            if (actualMintAmount > 0) {
                // Assign tokenSplitter!
                address reservesManager = ICygnusFactory(hangar18).vegaTokenManager();

                // Emit transfer event
                mintInternal(reservesManager, actualMintAmount);
            }

            exchangeRateStored = _exchangeRateNew;

            return _exchangeRateNew;
        } else return _exchangeRate;
    }

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @notice Overrides the exchangeRate from CygnusTerminal for Borrow contracts.
     *  @notice Accrues and therefore updates totalBalance before.
     */
    function exchangeRate() public override accrue returns (uint256) {
        // Save an SLOAD if non zero
        uint256 _totalSupply = totalSupply;

        // If there are no tokens in circulation, return initial (1e18), else calculate new exchange rate
        if (_totalSupply == 0) {
            return initialRate;
        }

        // newExchangeRate = (totalBalance + totalBorrows - reserves) / totalSupply
        uint256 _totalBalance = totalBalance + totalBorrows;

        // Factor in reserves in the next mint function
        uint256 _exchangeRate = PRBMath.mulDiv(_totalBalance, 1e18, _totalSupply);

        return mintBorrowInternal(_exchangeRate, _totalSupply);
    }

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice This low level function should only be called from `Router` contract only.
     *  @inheritdoc ICygnusBorrow
     */
    function borrow(
        address borrower,
        address receiver,
        uint256 borrowAmount,
        bytes calldata data
    ) external override nonReentrant accrue {
        uint256 totalBalanceStored = totalBalance;

        /// @custom:error Avoid if there's not enough cash.
        if (borrowAmount >= totalBalanceStored) {
            revert CygnusBorrow__BorrowExceedsTotalBalance(totalBalanceStored);
        }

        // Internally update the account's borrow balances (balance - borrow amount).
        borrowApproveUpdate(borrower, _msgSender(), borrowAmount);

        // Optimistically transfer borrowAmount.
        if (borrowAmount > 0) {
            IErc20(underlying).safeTransfer(receiver, borrowAmount);
        }

        // Pass calltype to `Router` contract.
        if (data.length > 0) {
            ICygnusCallee(receiver).cygnusBorrow(_msgSender(), borrower, borrowAmount, data);
        }

        // Get total balance of the underlying asset.
        uint256 balance = IErc20(underlying).balanceOf(address(this));

        // Factor in the initial borrow fee.
        uint256 cygnusBorrowFee = PRBMath.mulDivFixedPoint(borrowAmount, CYGNUS_BORROW_FEE);
        uint256 borrowAmountAdjusted = borrowAmount + cygnusBorrowFee;

        // Calculate the user's amount outstanding.
        uint256 repayAmount = (balance + borrowAmount) - totalBalanceStored;

        // Update borrows internally.
        (uint256 accountBorrowsPrior, uint256 accountBorrows, uint256 totalBorrowsStored) = updateBorrowInternal(
            borrower,
            borrowAmountAdjusted,
            repayAmount
        );

        if (borrowAmountAdjusted > repayAmount) {
            /// @custom:error Avoid shortfall.
            if (!ICygnusCollateral(collateral).canBorrow(borrower, address(this), accountBorrows)) {
                revert CygnusBorrow__InsufficientLiquidity(address(this));
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
     *  @notice This low level function should only be called from `Router` contract only.
     *  @inheritdoc ICygnusBorrow
     */
    function liquidate(address borrower, address liquidator)
        external
        override
        nonReentrant
        update
        accrue
        returns (uint256 denebAmount)
    {
        uint256 balance = IErc20(underlying).balanceOf(address(this));

        uint256 repayAmount = balance - totalBalance;

        uint256 actualRepayAmount = getBorrowBalance(borrower) < repayAmount ? getBorrowBalance(borrower) : repayAmount;

        denebAmount = ICygnusCollateral(collateral).seizeDeneb(liquidator, borrower, actualRepayAmount);

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
            denebAmount,
            repayAmount,
            accountBorrowsPrior,
            accountBorrows,
            totalBorrowsStored
        );
    }

    function sync() external override nonReentrant update accrue {}
}
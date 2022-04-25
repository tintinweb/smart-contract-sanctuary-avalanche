/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-23
*/

// Sources flattened with hardhat v2.9.1 https://hardhat.org

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


// File contracts/cygnus-core/interfaces/ICygnusNebulaOracle.sol

//SPDX-License-Identifier: Unlicensed
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


// File contracts/cygnus-core/interfaces/IErc20.sol

// ignore: Unlicense
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
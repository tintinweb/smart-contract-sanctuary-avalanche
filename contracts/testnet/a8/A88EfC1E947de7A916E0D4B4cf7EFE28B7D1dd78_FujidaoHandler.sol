/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-09
*/

// Sources flattened with hardhat v2.9.9 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

//MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

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


// File @openzeppelin/contracts/utils/[email protected]

//MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]

//MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;


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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File libraries/Errors.sol

//GPL-3.0-or-later
pragma solidity 0.8.9;

// solhint-disable private-vars-leading-underscore

library Error {
    string internal constant ADDRESS_WHITELISTED = "address already whitelisted";
    string internal constant ADMIN_ALREADY_SET = "admin has already been set once";
    string internal constant ADDRESS_NOT_WHITELISTED = "address not whitelisted";
    string internal constant ADDRESS_NOT_FOUND = "address not found";
    string internal constant CONTRACT_INITIALIZED = "contract can only be initialized once";
    string internal constant CONTRACT_PAUSED = "contract is paused";
    string internal constant UNAUTHORIZED_PAUSE = "not authorized to pause";
    string internal constant INVALID_AMOUNT = "invalid amount";
    string internal constant INVALID_INDEX = "invalid index";
    string internal constant INVALID_VALUE = "invalid msg.value";
    string internal constant INVALID_SENDER = "invalid msg.sender";
    string internal constant INVALID_TOKEN = "token address does not match pool's LP token address";
    string internal constant INVALID_DECIMALS = "incorrect number of decimals";
    string internal constant INVALID_ARGUMENT = "invalid argument";
    string internal constant INVALID_PARAMETER_VALUE = "invalid parameter value attempted";
    string internal constant INVALID_IMPLEMENTATION = "invalid pool implementation for given coin";
    string internal constant INVALID_POOL_IMPLEMENTATION =
        "invalid pool implementation for given coin";
    string internal constant INVALID_LP_TOKEN_IMPLEMENTATION =
        "invalid LP Token implementation for given coin";
    string internal constant INVALID_VAULT_IMPLEMENTATION =
        "invalid vault implementation for given coin";
    string internal constant INVALID_STAKER_VAULT_IMPLEMENTATION =
        "invalid stakerVault implementation for given coin";
    string internal constant INSUFFICIENT_BALANCE = "insufficient balance";
    string internal constant ADDRESS_ALREADY_SET = "Address is already set";
    string internal constant INSUFFICIENT_STRATEGY_BALANCE = "insufficient strategy balance";
    string internal constant INSUFFICIENT_FUNDS_RECEIVED = "insufficient funds received";
    string internal constant ADDRESS_DOES_NOT_EXIST = "address does not exist";
    string internal constant ADDRESS_FROZEN = "address is frozen";
    string internal constant ROLE_EXISTS = "role already exists";
    string internal constant CANNOT_REVOKE_ROLE = "cannot revoke role";
    string internal constant UNAUTHORIZED_ACCESS = "unauthorized access";
    string internal constant SAME_ADDRESS_NOT_ALLOWED = "same address not allowed";
    string internal constant SELF_TRANSFER_NOT_ALLOWED = "self-transfer not allowed";
    string internal constant ZERO_ADDRESS_NOT_ALLOWED = "zero address not allowed";
    string internal constant ZERO_TRANSFER_NOT_ALLOWED = "zero transfer not allowed";
    string internal constant THRESHOLD_TOO_HIGH = "threshold is too high, must be under 10";
    string internal constant INSUFFICIENT_THRESHOLD = "insufficient threshold";
    string internal constant NO_POSITION_EXISTS = "no position exists";
    string internal constant POSITION_ALREADY_EXISTS = "position already exists";
    string internal constant PROTOCOL_NOT_FOUND = "protocol not found";
    string internal constant TOP_UP_FAILED = "top up failed";
    string internal constant SWAP_PATH_NOT_FOUND = "swap path not found";
    string internal constant UNDERLYING_NOT_SUPPORTED = "underlying token not supported";
    string internal constant NOT_ENOUGH_FUNDS_WITHDRAWN =
        "not enough funds were withdrawn from the pool";
    string internal constant FAILED_TRANSFER = "transfer failed";
    string internal constant FAILED_MINT = "mint failed";
    string internal constant FAILED_REPAY_BORROW = "repay borrow failed";
    string internal constant FAILED_METHOD_CALL = "method call failed";
    string internal constant NOTHING_TO_CLAIM = "there is no claimable balance";
    string internal constant ERC20_BALANCE_EXCEEDED = "ERC20: transfer amount exceeds balance";
    string internal constant INVALID_MINTER =
        "the minter address of the LP token and the pool address do not match";
    string internal constant STAKER_VAULT_EXISTS = "a staker vault already exists for the token";
    string internal constant DEADLINE_NOT_ZERO = "deadline must be 0";
    string internal constant DEADLINE_NOT_SET = "deadline is 0";
    string internal constant DEADLINE_NOT_REACHED = "deadline has not been reached yet";
    string internal constant DELAY_TOO_SHORT = "delay be at least 3 days";
    string internal constant INSUFFICIENT_UPDATE_BALANCE =
        "insufficient funds for updating the position";
    string internal constant SAME_AS_CURRENT = "value must be different to existing value";
    string internal constant NOT_CAPPED = "the pool is not currently capped";
    string internal constant ALREADY_CAPPED = "the pool is already capped";
    string internal constant EXCEEDS_DEPOSIT_CAP = "deposit exceeds deposit cap";
    string internal constant VALUE_TOO_LOW_FOR_GAS = "value too low to cover gas";
    string internal constant NOT_ENOUGH_FUNDS = "not enough funds to withdraw";
    string internal constant ESTIMATED_GAS_TOO_HIGH = "too much ETH will be used for gas";
    string internal constant DEPOSIT_FAILED = "deposit failed";
    string internal constant GAS_TOO_HIGH = "too much ETH used for gas";
    string internal constant GAS_BANK_BALANCE_TOO_LOW = "not enough ETH in gas bank to cover gas";
    string internal constant INVALID_TOKEN_TO_ADD = "Invalid token to add";
    string internal constant INVALID_TOKEN_TO_REMOVE = "token can not be removed";
    string internal constant TIME_DELAY_NOT_EXPIRED = "time delay not expired yet";
    string internal constant UNDERLYING_NOT_WITHDRAWABLE =
        "pool does not support additional underlying coins to be withdrawn";
    string internal constant STRATEGY_SHUT_DOWN = "Strategy is shut down";
    string internal constant STRATEGY_DOES_NOT_EXIST = "Strategy does not exist";
    string internal constant UNSUPPORTED_UNDERLYING = "Underlying not supported";
    string internal constant NO_DEX_SET = "no dex has been set for token";
    string internal constant INVALID_TOKEN_PAIR = "invalid token pair";
    string internal constant TOKEN_NOT_USABLE = "token not usable for the specific action";
    string internal constant ADDRESS_NOT_ACTION = "address is not registered action";
    string internal constant INVALID_SLIPPAGE_TOLERANCE = "Invalid slippage tolerance";
    string internal constant POOL_NOT_PAUSED = "Pool must be paused to withdraw from reserve";
    string internal constant INTERACTION_LIMIT = "Max of one deposit and withdraw per block";
    string internal constant GAUGE_EXISTS = "Gauge already exists";
    string internal constant GAUGE_DOES_NOT_EXIST = "Gauge does not exist";
    string internal constant EXCEEDS_MAX_BOOST = "Not allowed to exceed maximum boost on Convex";
    string internal constant PREPARED_WITHDRAWAL =
        "Cannot relock funds when withdrawal is being prepared";
    string internal constant ASSET_NOT_SUPPORTED = "Asset not supported";
    string internal constant STALE_PRICE = "Price is stale";
    string internal constant NEGATIVE_PRICE = "Price is negative";
    string internal constant NOT_ENOUGH_BKD_STAKED = "Not enough BKD tokens staked";
    string internal constant RESERVE_ACCESS_EXCEEDED = "Reserve access exceeded";
}


// File libraries/AccountEncoding.sol

//GPL-3.0-or-later
pragma solidity 0.8.9;

library AccountEncoding {
    function addr(bytes32 account) internal pure returns (address) {
        return address(bytes20(account));
    }

    function meta(bytes32 account) internal pure returns (bytes12) {
        return bytes12(account << 160);
    }
}


// File interfaces/actions/topup/ITopUpHandler.sol

//GPL-3.0-or-later
pragma solidity 0.8.9;

/**
 * This interface should be implemented by protocols integrating with Backd
 * that require topping up a registered position
 */
interface ITopUpHandler {
    /**
     * @notice Tops up the account for the protocol associated with this handler
     * This is designed to be called using delegatecall and should therefore
     * not assume that storage will be available
     *
     * @param account account to be topped up
     * @param underlying underlying currency to be used for top up
     * @param amount amount to be topped up
     * @param extra arbitrary data that can be passed to the handler
     * @return true if the top up succeeded and false otherwise
     */
    function topUp(
        bytes32 account,
        address underlying,
        uint256 amount,
        bytes memory extra
    ) external returns (bool);

    /**
     * @notice Returns a factor for the user which should always be >= 1 for sufficiently
     *         colletaralized positions and should get closer to 1 when collaterization level decreases
     * This should be an aggregate value including all the collateral of the user
     * @param account account for which to get the factor
     */
    function getUserFactor(bytes32 account, bytes memory extra) external view returns (uint256);
}


// File interfaces/vendor/IVault.sol

//MIT

pragma solidity ^0.8.0;

interface IVault {
  // Vault Events

  /**
  * @dev Log a deposit transaction done by a user
  */
  event Deposit(address indexed userAddrs, address indexed asset, uint256 amount);
  /**
  * @dev Log a withdraw transaction done by a user
  */
  event Withdraw(address indexed userAddrs, address indexed asset, uint256 amount);
  /**
  * @dev Log a borrow transaction done by a user
  */
  event Borrow(address indexed userAddrs, address indexed asset, uint256 amount);
  /**
  * @dev Log a payback transaction done by a user
  */
  event Payback(address indexed userAddrs, address indexed asset, uint256 amount);
  /**
  * @dev Log a switch from provider to new provider in vault
  */
  event Switch(
    address fromProviderAddrs,
    address toProviderAddr,
    uint256 debtamount,
    uint256 collattamount
  );
  /**
  * @dev Log a change in active provider
  */
  event SetActiveProvider(address newActiveProviderAddress);
  /**
  * @dev Log a change in the array of provider addresses
  */
  event ProvidersChanged(address[] newProviderArray);
  /**
  * @dev Log a change in F1155 address
  */
  event F1155Changed(address newF1155Address);
  /**
  * @dev Log a change in fuji admin address
  */
  event FujiAdminChanged(address newFujiAdmin);
  /**
  * @dev Log a change in the factor values
  */
  event FactorChanged(
    FactorType factorType,
    uint64 newFactorA,
    uint64 newFactorB
  );
  /**
  * @dev Log a change in the oracle address
  */
  event OracleChanged(address newOracle);

  enum FactorType {
    Safety,
    Collateralization,
    ProtocolFee,
    BonusLiquidation
  }

  struct Factor {
    uint64 a;
    uint64 b;
  }

  struct VaultAssets {
    address collateralAsset;
    address borrowAsset;
    uint64 collateralID;
    uint64 borrowID;
  }

  // Core Vault Functions
  function vAssets() external view returns (VaultAssets memory);
  
  function deposit(uint256 _collateralAmount) external payable;

  function withdraw(int256 _withdrawAmount) external;

  function withdrawLiq(int256 _withdrawAmount) external;

  function borrow(uint256 _borrowAmount) external;

  function payback(int256 _repayAmount) external payable;

  function paybackLiq(address[] memory _users, uint256 _repayAmount) external payable;

  function executeSwitch(
    address _newProvider,
    uint256 _flashLoanDebt,
    uint256 _fee
  ) external payable;

  //Getter Functions

  function activeProvider() external view returns (address);

  function borrowBalance(address _provider) external view returns (uint256);

  function depositBalance(address _provider) external view returns (uint256);

  function userDebtBalance(address _user) external view returns (uint256);

  function userProtocolFee(address _user) external view returns (uint256);

  function userDepositBalance(address _user) external view returns (uint256);

  function getNeededCollateralFor(uint256 _amount, bool _withFactors)
    external
    view
    returns (uint256);

  function getLiquidationBonusFor(uint256 _amount) external view returns (uint256);

  function getProviders() external view returns (address[] memory);

  function fujiERC1155() external view returns (address);

  //Setter Functions

  function setActiveProvider(address _provider) external;

  function updateF1155Balances() external;

  function protocolFee() external view returns (uint64, uint64);
}


// File interfaces/vendor/IFujiOracle.sol

//MIT

pragma solidity ^0.8.0;

interface IFujiOracle {

  // FujiOracle Events

  /**
  * @dev Log a change in price feed address for asset address
  */
  event AssetPriceFeedChanged(address asset, address newPriceFeedAddress);

  function getPriceOf(
    address _collateralAsset,
    address _borrowAsset,
    uint8 _decimals
  ) external view returns (uint256);
}


// File interfaces/vendor/IWETH.sol

//UNLICENSED
pragma solidity 0.8.9;

/**
 * @notice Interface for WETH9
 * @dev https://etherscan.io/address/0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2#code
 */
interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}


// File libraries/vendor/DataTypes.sol

//agpl-3.0
pragma solidity 0.8.9;

library DataTypes {
    // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        uint40 lastUpdateTimestamp;
        //tokens addresses
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint8 id;
    }

    struct ReserveConfigurationMap {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32-47: Liq. bonus
        //bit 48-55: Decimals
        //bit 56: Reserve is active
        //bit 57: reserve is frozen
        //bit 58: borrowing is enabled
        //bit 59: stable rate borrowing enabled
        //bit 60-63: reserved
        //bit 64-79: reserve factor
        uint256 data;
    }

    struct UserConfigurationMap {
        uint256 data;
    }

    enum InterestRateMode {
        NONE,
        STABLE,
        VARIABLE
    }
}


// File contracts/actions/topup/handlers/FujidaoHandler.sol

//GPL-3.0-or-later
pragma solidity 0.8.9;







contract FujidaoHandler is ITopUpHandler {
    using SafeERC20 for IERC20;
    using AccountEncoding for bytes32;

    uint16 public constant BACKD_REFERRAL_CODE = 0;

    IVault public immutable vault;
    IWETH public immutable weth;
    IFujiOracle public immutable fujiOracle;

    constructor(address vaultAddress, address wethAddress, address oracleAddress) {
        vault = IVault(vaultAddress);
        weth = IWETH(wethAddress);
        fujiOracle = IFujiOracle(oracleAddress);
    }

    /**
     * @notice Executes the top-up of a position.
     * @param account Account holding the position.
     * @param underlying Underlying for tup-up.
     * @param amount Amount to top-up by.
     * @return `true` if successful.
     */
    function topUp(
        bytes32 account,
        address underlying,
        uint256 amount,
        bytes memory extra
    ) external override returns (bool) {
        bool repayDebt = abi.decode(extra, (bool));
        if (underlying == address(0)) {
            weth.deposit{value: amount}();
            underlying = address(weth);
        }

        if (repayDebt) {
            require(underlying == vault.vAssets().borrowAsset, Error.UNDERLYING_NOT_SUPPORTED);
        } else {
            require(underlying == vault.vAssets().collateralAsset, Error.UNDERLYING_NOT_SUPPORTED);
        }

        address addr = account.addr();

        IERC20(underlying).safeIncreaseAllowance(address(vault), amount);

        uint256 debt = vault.userDebtBalance(addr);
        if (debt == 0) return true;

        vault.deposit(amount);
        return true;
    }

    function getUserFactor(bytes32 account, bytes memory) external view override returns (uint256) {
        address addr = account.addr();
        uint256 debt = vault.userDebtBalance(addr);
        uint256 deposit = vault.userDepositBalance(addr);
        uint256 neededCollatoral = vault.getNeededCollateralFor(debt, true);

        return deposit / neededCollatoral;
    }
}
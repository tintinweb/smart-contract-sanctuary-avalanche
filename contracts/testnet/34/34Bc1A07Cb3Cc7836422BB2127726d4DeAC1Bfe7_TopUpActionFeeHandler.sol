/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-02
*/

// Sources flattened with hardhat v2.9.9 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/token/ERC20/[email protected]

// MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]

// MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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


// File @openzeppelin/contracts-upgradeable/token/ERC20/utils/[email protected]

// MIT
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
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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


// File interfaces/IPreparable.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;

interface IPreparable {
    event ConfigPreparedAddress(bytes32 indexed key, address value, uint256 delay);
    event ConfigPreparedNumber(bytes32 indexed key, uint256 value, uint256 delay);

    event ConfigUpdatedAddress(bytes32 indexed key, address oldValue, address newValue);
    event ConfigUpdatedNumber(bytes32 indexed key, uint256 oldValue, uint256 newValue);

    event ConfigReset(bytes32 indexed key);
}


// File interfaces/actions/IActionFeeHandler.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;

interface IActionFeeHandler is IPreparable {
    function payFees(
        address payer,
        address keeper,
        uint256 amount,
        address token
    ) external returns (bool);

    function claimKeeperFeesForPool(address keeper, address token) external returns (bool);

    function claimTreasuryFees(address token) external returns (bool);

    function setInitialKeeperGaugeForToken(address lpToken, address _keeperGauge)
        external
        returns (bool);
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

// MIT
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


// File interfaces/IStrategy.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;

interface IStrategy {
    function name() external view returns (string memory);

    function deposit() external payable returns (bool);

    function balance() external view returns (uint256);

    function withdraw(uint256 amount) external returns (bool);

    function withdrawAll() external returns (uint256);

    function harvestable() external view returns (uint256);

    function harvest() external returns (uint256);

    function strategist() external view returns (address);

    function shutdown() external returns (bool);

    function hasPendingFunds() external view returns (bool);
}


// File interfaces/IVault.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;


/**
 * @title Interface for a Vault
 */

interface IVault is IPreparable {
    event StrategyActivated(address indexed strategy);

    event StrategyDeactivated(address indexed strategy);

    /**
     * @dev 'netProfit' is the profit after all fees have been deducted
     */
    event Harvest(uint256 indexed netProfit, uint256 indexed loss);

    function initialize(
        address _pool,
        uint256 _debtLimit,
        uint256 _targetAllocation,
        uint256 _bound
    ) external;

    function withdrawFromStrategyWaitingForRemoval(address strategy) external returns (uint256);

    function deposit() external payable;

    function withdraw(uint256 amount) external returns (bool);

    function initializeStrategy(address strategy_) external returns (bool);

    function withdrawAll() external;

    function withdrawFromReserve(uint256 amount) external;

    function executeNewStrategy() external returns (address);

    function prepareNewStrategy(address newStrategy) external returns (bool);

    function getStrategy() external view returns (IStrategy);

    function getStrategiesWaitingForRemoval() external view returns (address[] memory);

    function getAllocatedToStrategyWaitingForRemoval(address strategy)
        external
        view
        returns (uint256);

    function getTotalUnderlying() external view returns (uint256);

    function getUnderlying() external view returns (address);
}


// File interfaces/pool/ILiquidityPool.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;


interface ILiquidityPool is IPreparable {
    event Deposit(address indexed minter, uint256 depositAmount, uint256 mintedLpTokens);

    event DepositFor(
        address indexed minter,
        address indexed mintee,
        uint256 depositAmount,
        uint256 mintedLpTokens
    );

    event Redeem(address indexed redeemer, uint256 redeemAmount, uint256 redeemTokens);

    event LpTokenSet(address indexed lpToken);

    event StakerVaultSet(address indexed stakerVault);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeem(uint256 redeemTokens, uint256 minRedeemAmount) external returns (uint256);

    function calcRedeem(address account, uint256 underlyingAmount) external returns (uint256);

    function deposit(uint256 mintAmount) external payable returns (uint256);

    function deposit(uint256 mintAmount, uint256 minTokenAmount) external payable returns (uint256);

    function depositAndStake(uint256 depositAmount, uint256 minTokenAmount)
        external
        payable
        returns (uint256);

    function depositFor(address account, uint256 depositAmount) external payable returns (uint256);

    function depositFor(
        address account,
        uint256 depositAmount,
        uint256 minTokenAmount
    ) external payable returns (uint256);

    function unstakeAndRedeem(uint256 redeemLpTokens, uint256 minRedeemAmount)
        external
        returns (uint256);

    function handleLpTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) external;

    function prepareNewVault(address _vault) external returns (bool);

    function executeNewVault() external returns (address);

    function executeNewMaxWithdrawalFee() external returns (uint256);

    function executeNewRequiredReserves() external returns (uint256);

    function executeNewReserveDeviation() external returns (uint256);

    function setLpToken(address _lpToken) external returns (bool);

    function setStaker() external returns (bool);

    function isCapped() external returns (bool);

    function uncap() external returns (bool);

    function updateDepositCap(uint256 _depositCap) external returns (bool);

    function withdrawAll() external;

    function getUnderlying() external view returns (address);

    function getLpToken() external view returns (address);

    function getWithdrawalFee(address account, uint256 amount) external view returns (uint256);

    function getVault() external view returns (IVault);

    function exchangeRate() external view returns (uint256);

    function totalUnderlying() external view returns (uint256);
}


// File interfaces/IGasBank.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;

interface IGasBank {
    event Deposit(address indexed account, uint256 value);
    event Withdraw(address indexed account, address indexed receiver, uint256 value);

    function depositFor(address account) external payable;

    function withdrawUnused(address account) external;

    function withdrawFrom(address account, uint256 amount) external;

    function withdrawFrom(
        address account,
        address payable to,
        uint256 amount
    ) external;

    function balanceOf(address account) external view returns (uint256);
}


// File interfaces/oracles/IOracleProvider.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;

interface IOracleProvider {
    /// @notice Quotes the USD price of `baseAsset`
    /// @param baseAsset the asset of which the price is to be quoted
    /// @return the USD price of the asset
    function getPriceUSD(address baseAsset) external view returns (uint256);

    /// @notice Quotes the ETH price of `baseAsset`
    /// @param baseAsset the asset of which the price is to be quoted
    /// @return the ETH price of the asset
    function getPriceETH(address baseAsset) external view returns (uint256);
}


// File libraries/AddressProviderMeta.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;

library AddressProviderMeta {
    struct Meta {
        bool freezable;
        bool frozen;
    }

    function fromUInt(uint256 value) internal pure returns (Meta memory) {
        Meta memory meta;
        meta.freezable = (value & 1) == 1;
        meta.frozen = ((value >> 1) & 1) == 1;
        return meta;
    }

    function toUInt(Meta memory meta) internal pure returns (uint256) {
        uint256 value;
        value |= meta.freezable ? 1 : 0;
        value |= meta.frozen ? 1 << 1 : 0;
        return value;
    }
}


// File interfaces/IAddressProvider.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;





// solhint-disable ordering

interface IAddressProvider is IPreparable {
    event KnownAddressKeyAdded(bytes32 indexed key);
    event StakerVaultListed(address indexed stakerVault);
    event StakerVaultDelisted(address indexed stakerVault);
    event ActionListed(address indexed action);
    event PoolListed(address indexed pool);
    event PoolDelisted(address indexed pool);
    event VaultUpdated(address indexed previousVault, address indexed newVault);

    /** Key functions */
    function getKnownAddressKeys() external view returns (bytes32[] memory);

    function freezeAddress(bytes32 key) external;

    /** Pool functions */

    function allPools() external view returns (address[] memory);

    function addPool(address pool) external;

    function poolsCount() external view returns (uint256);

    function getPoolAtIndex(uint256 index) external view returns (address);

    function isPool(address pool) external view returns (bool);

    function removePool(address pool) external returns (bool);

    function getPoolForToken(address token) external view returns (ILiquidityPool);

    function safeGetPoolForToken(address token) external view returns (address);

    /** Vault functions  */

    function updateVault(address previousVault, address newVault) external;

    function allVaults() external view returns (address[] memory);

    function vaultsCount() external view returns (uint256);

    function getVaultAtIndex(uint256 index) external view returns (address);

    function isVault(address vault) external view returns (bool);

    /** Action functions */

    function allActions() external view returns (address[] memory);

    function addAction(address action) external returns (bool);

    function isAction(address action) external view returns (bool);

    /** Address functions */
    function initializeAddress(
        bytes32 key,
        address initialAddress,
        bool frezable
    ) external;

    function initializeAndFreezeAddress(bytes32 key, address initialAddress) external;

    function getAddress(bytes32 key) external view returns (address);

    function getAddress(bytes32 key, bool checkExists) external view returns (address);

    function getAddressMeta(bytes32 key) external view returns (AddressProviderMeta.Meta memory);

    function prepareAddress(bytes32 key, address newAddress) external returns (bool);

    function executeAddress(bytes32 key) external returns (address);

    function resetAddress(bytes32 key) external returns (bool);

    /** Staker vault functions */
    function allStakerVaults() external view returns (address[] memory);

    function tryGetStakerVault(address token) external view returns (bool, address);

    function getStakerVault(address token) external view returns (address);

    function addStakerVault(address stakerVault) external returns (bool);

    function isStakerVault(address stakerVault, address token) external view returns (bool);

    function isStakerVaultRegistered(address stakerVault) external view returns (bool);

    function isWhiteListedFeeHandler(address feeHandler) external view returns (bool);
}


// File interfaces/tokenomics/IInflationManager.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;

interface IInflationManager {
    event KeeperGaugeListed(address indexed pool, address indexed keeperGauge);
    event AmmGaugeListed(address indexed token, address indexed ammGauge);
    event KeeperGaugeDelisted(address indexed pool, address indexed keeperGauge);
    event AmmGaugeDelisted(address indexed token, address indexed ammGauge);

    /** Pool functions */

    function setKeeperGauge(address pool, address _keeperGauge) external returns (bool);

    function setAmmGauge(address token, address _ammGauge) external returns (bool);

    function getAllAmmGauges() external view returns (address[] memory);

    function getLpRateForStakerVault(address stakerVault) external view returns (uint256);

    function getKeeperRateForPool(address pool) external view returns (uint256);

    function getAmmRateForToken(address token) external view returns (uint256);

    function getKeeperWeightForPool(address pool) external view returns (uint256);

    function getAmmWeightForToken(address pool) external view returns (uint256);

    function getLpPoolWeight(address pool) external view returns (uint256);

    function getKeeperGaugeForPool(address pool) external view returns (address);

    function getAmmGaugeForToken(address token) external view returns (address);

    function isInflationWeightManager(address account) external view returns (bool);

    function removeStakerVaultFromInflation(address stakerVault, address lpToken) external;

    function addGaugeForVault(address lpToken) external returns (bool);

    function whitelistGauge(address gauge) external;

    function checkpointAllGauges() external returns (bool);

    function mintRewards(address beneficiary, uint256 amount) external;

    function addStrategyToDepositStakerVault(address depositStakerVault, address strategyPool)
        external
        returns (bool);

    /** Weight setter functions **/

    function prepareLpPoolWeight(address lpToken, uint256 newPoolWeight) external returns (bool);

    function prepareAmmTokenWeight(address token, uint256 newTokenWeight) external returns (bool);

    function prepareKeeperPoolWeight(address pool, uint256 newPoolWeight) external returns (bool);

    function executeLpPoolWeight(address lpToken) external returns (uint256);

    function executeAmmTokenWeight(address token) external returns (uint256);

    function executeKeeperPoolWeight(address pool) external returns (uint256);

    function batchPrepareLpPoolWeights(address[] calldata lpTokens, uint256[] calldata weights)
        external
        returns (bool);

    function batchPrepareAmmTokenWeights(address[] calldata tokens, uint256[] calldata weights)
        external
        returns (bool);

    function batchPrepareKeeperPoolWeights(address[] calldata pools, uint256[] calldata weights)
        external
        returns (bool);

    function batchExecuteLpPoolWeights(address[] calldata lpTokens) external returns (bool);

    function batchExecuteAmmTokenWeights(address[] calldata tokens) external returns (bool);

    function batchExecuteKeeperPoolWeights(address[] calldata pools) external returns (bool);
}


// File interfaces/IController.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;





// solhint-disable ordering

interface IController is IPreparable {
    function addressProvider() external view returns (IAddressProvider);

    function inflationManager() external view returns (IInflationManager);

    function addStakerVault(address stakerVault) external returns (bool);

    function removePool(address pool) external returns (bool);

    /** Keeper functions */
    function prepareKeeperRequiredStakedBKD(uint256 amount) external;

    function executeKeeperRequiredStakedBKD() external;

    function getKeeperRequiredStakedBKD() external view returns (uint256);

    function canKeeperExecuteAction(address keeper) external view returns (bool);

    /** Miscellaneous functions */

    function getTotalEthRequiredForGas(address payer) external view returns (uint256);
}


// File interfaces/tokenomics/IRewardsGauge.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;

interface IRewardsGauge {
    function claimRewards(address beneficiary) external returns (uint256);
}


// File interfaces/tokenomics/IKeeperGauge.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;

interface IKeeperGauge is IRewardsGauge {
    function reportFees(
        address beneficiary,
        uint256 amount,
        address lpTokenAddress
    ) external returns (bool);

    function advanceEpoch() external returns (bool);

    function poolCheckpoint() external returns (bool);

    function kill() external returns (bool);

    function killed() external view returns (bool);

    function claimableRewards(address beneficiary) external view returns (uint256);
}


// File libraries/Errors.sol

// GPL-3.0-or-later
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


// File libraries/ScaledMath.sol

// MIT
pragma solidity 0.8.9;

/*
 * @dev To use functions of this contract, at least one of the numbers must
 * be scaled to `DECIMAL_SCALE`. The result will scaled to `DECIMAL_SCALE`
 * if both numbers are scaled to `DECIMAL_SCALE`, otherwise to the scale
 * of the number not scaled by `DECIMAL_SCALE`
 */
library ScaledMath {
    // solhint-disable-next-line private-vars-leading-underscore
    uint256 internal constant DECIMAL_SCALE = 1e18;
    // solhint-disable-next-line private-vars-leading-underscore
    uint256 internal constant ONE = 1e18;

    /**
     * @notice Performs a multiplication between two scaled numbers
     */
    function scaledMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * b) / DECIMAL_SCALE;
    }

    /**
     * @notice Performs a division between two scaled numbers
     */
    function scaledDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * DECIMAL_SCALE) / b;
    }

    /**
     * @notice Performs a division between two numbers, rounding up the result
     */
    function scaledDivRoundUp(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * DECIMAL_SCALE + b - 1) / b;
    }

    /**
     * @notice Performs a division between two numbers, ignoring any scaling and rounding up the result
     */
    function divRoundUp(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a + b - 1) / b;
    }
}


// File interfaces/IVaultReserve.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;

interface IVaultReserve {
    event Deposit(address indexed vault, address indexed token, uint256 amount);
    event Withdraw(address indexed vault, address indexed token, uint256 amount);
    event VaultListed(address indexed vault);

    function deposit(address token, uint256 amount) external payable returns (bool);

    function withdraw(address token, uint256 amount) external returns (bool);

    function getBalance(address vault, address token) external view returns (uint256);

    function canWithdraw(address vault) external view returns (bool);
}


// File interfaces/IRoleManager.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;

interface IRoleManager {
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function hasRole(bytes32 role, address account) external view returns (bool);

    function hasAnyRole(bytes32[] memory roles, address account) external view returns (bool);

    function hasAnyRole(
        bytes32 role1,
        bytes32 role2,
        address account
    ) external view returns (bool);

    function hasAnyRole(
        bytes32 role1,
        bytes32 role2,
        bytes32 role3,
        address account
    ) external view returns (bool);

    function getRoleMemberCount(bytes32 role) external view returns (uint256);

    function getRoleMember(bytes32 role, uint256 index) external view returns (address);
}


// File interfaces/tokenomics/IBkdToken.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;

interface IBkdToken is IERC20 {
    function mint(address account, uint256 amount) external;
}


// File libraries/AddressProviderKeys.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;

library AddressProviderKeys {
    bytes32 internal constant _TREASURY_KEY = "treasury";
    bytes32 internal constant _GAS_BANK_KEY = "gasBank";
    bytes32 internal constant _VAULT_RESERVE_KEY = "vaultReserve";
    bytes32 internal constant _SWAPPER_REGISTRY_KEY = "swapperRegistry";
    bytes32 internal constant _ORACLE_PROVIDER_KEY = "oracleProvider";
    bytes32 internal constant _POOL_FACTORY_KEY = "poolFactory";
    bytes32 internal constant _CONTROLLER_KEY = "controller";
    bytes32 internal constant _BKD_LOCKER_KEY = "bkdLocker";
    bytes32 internal constant _ROLE_MANAGER_KEY = "roleManager";
}


// File libraries/AddressProviderHelpers.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;







library AddressProviderHelpers {
    /**
     * @return The address of the treasury.
     */
    function getTreasury(IAddressProvider provider) internal view returns (address) {
        return provider.getAddress(AddressProviderKeys._TREASURY_KEY);
    }

    /**
     * @return The gas bank.
     */
    function getGasBank(IAddressProvider provider) internal view returns (IGasBank) {
        return IGasBank(provider.getAddress(AddressProviderKeys._GAS_BANK_KEY));
    }

    /**
     * @return The address of the vault reserve.
     */
    function getVaultReserve(IAddressProvider provider) internal view returns (IVaultReserve) {
        return IVaultReserve(provider.getAddress(AddressProviderKeys._VAULT_RESERVE_KEY));
    }

    /**
     * @return The address of the swapperRegistry.
     */
    function getSwapperRegistry(IAddressProvider provider) internal view returns (address) {
        return provider.getAddress(AddressProviderKeys._SWAPPER_REGISTRY_KEY);
    }

    /**
     * @return The oracleProvider.
     */
    function getOracleProvider(IAddressProvider provider) internal view returns (IOracleProvider) {
        return IOracleProvider(provider.getAddress(AddressProviderKeys._ORACLE_PROVIDER_KEY));
    }

    /**
     * @return the address of the BKD locker
     */
    function getBKDLocker(IAddressProvider provider) internal view returns (address) {
        return provider.getAddress(AddressProviderKeys._BKD_LOCKER_KEY);
    }

    /**
     * @return the address of the BKD locker
     */
    function getRoleManager(IAddressProvider provider) internal view returns (IRoleManager) {
        return IRoleManager(provider.getAddress(AddressProviderKeys._ROLE_MANAGER_KEY));
    }

    /**
     * @return the controller
     */
    function getController(IAddressProvider provider) internal view returns (IController) {
        return IController(provider.getAddress(AddressProviderKeys._CONTROLLER_KEY));
    }
}


// File @openzeppelin/contracts-upgradeable/token/ERC20/extensions/[email protected]

// MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

// MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]

// MIT
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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/token/ERC20/[email protected]

// MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}


// File interfaces/ILpToken.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;

interface ILpToken is IERC20Upgradeable {
    function mint(address account, uint256 lpTokens) external;

    function burn(address account, uint256 burnAmount) external returns (uint256);

    function burn(uint256 burnAmount) external;

    function minter() external view returns (address);

    function initialize(
        string memory name_,
        string memory symbol_,
        uint8 _decimals,
        address _minter
    ) external returns (bool);
}


// File contracts/LpToken.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;





contract LpToken is ILpToken, ERC20Upgradeable {
    using ScaledMath for uint256;

    uint8 private _decimals;

    address public override minter;

    /**
     * @notice Make a function only callable by the minter contract.
     * @dev Fails if msg.sender is not the minter.
     */
    modifier onlyMinter() {
        require(msg.sender == minter, Error.UNAUTHORIZED_ACCESS);
        _;
    }

    constructor() ERC20Upgradeable() {}

    function initialize(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address _minter
    ) external override initializer returns (bool) {
        require(_minter != address(0), Error.ZERO_ADDRESS_NOT_ALLOWED);
        __ERC20_init(name_, symbol_);
        _decimals = decimals_;
        minter = _minter;
        return true;
    }

    /**
     * @notice Mint tokens.
     * @param account Account from which tokens should be burned.
     * @param amount Amount of tokens to mint.
     */
    function mint(address account, uint256 amount) external override onlyMinter {
        _mint(account, amount);
    }

    /**
     * @notice Burns tokens of msg.sender.
     * @param amount Amount of tokens to burn.
     */
    function burn(uint256 amount) external override {
        _burn(msg.sender, amount);
    }

    /**
     * @notice Burn tokens.
     * @param owner Account from which tokens should be burned.
     * @param burnAmount Amount of tokens to burn.
     * @return Aamount of tokens burned.
     */
    function burn(address owner, uint256 burnAmount)
        external
        override
        onlyMinter
        returns (uint256)
    {
        _burn(owner, burnAmount);
        return burnAmount;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev We notify that LP tokens have been transfered
     * this is currently used to keep track of the withdrawal fees
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (amount > 0) ILiquidityPool(minter).handleLpTokenTransfer(from, to, amount); // add check to not break 0 transfers
    }
}


// File libraries/Roles.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;

// solhint-disable private-vars-leading-underscore

library Roles {
    bytes32 internal constant GOVERNANCE = "governance";
    bytes32 internal constant ADDRESS_PROVIDER = "address_provider";
    bytes32 internal constant POOL_FACTORY = "pool_factory";
    bytes32 internal constant CONTROLLER = "controller";
    bytes32 internal constant GAUGE_ZAP = "gauge_zap";
    bytes32 internal constant MAINTENANCE = "maintenance";
    bytes32 internal constant INFLATION_MANAGER = "inflation_manager";
    bytes32 internal constant POOL = "pool";
    bytes32 internal constant VAULT = "vault";
}


// File contracts/access/AuthorizationBase.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;


/**
 * @notice Provides modifiers for authorization
 */
abstract contract AuthorizationBase {
    /**
     * @notice Only allows a sender with `role` to perform the given action
     */
    modifier onlyRole(bytes32 role) {
        require(_roleManager().hasRole(role, msg.sender), Error.UNAUTHORIZED_ACCESS);
        _;
    }

    /**
     * @notice Only allows a sender with GOVERNANCE role to perform the given action
     */
    modifier onlyGovernance() {
        require(_roleManager().hasRole(Roles.GOVERNANCE, msg.sender), Error.UNAUTHORIZED_ACCESS);
        _;
    }

    /**
     * @notice Only allows a sender with any of `roles` to perform the given action
     */
    modifier onlyRoles2(bytes32 role1, bytes32 role2) {
        require(_roleManager().hasAnyRole(role1, role2, msg.sender), Error.UNAUTHORIZED_ACCESS);
        _;
    }

    /**
     * @notice Only allows a sender with any of `roles` to perform the given action
     */
    modifier onlyRoles3(
        bytes32 role1,
        bytes32 role2,
        bytes32 role3
    ) {
        require(
            _roleManager().hasAnyRole(role1, role2, role3, msg.sender),
            Error.UNAUTHORIZED_ACCESS
        );
        _;
    }

    function roleManager() external view virtual returns (IRoleManager) {
        return _roleManager();
    }

    function _roleManager() internal view virtual returns (IRoleManager);
}


// File contracts/access/Authorization.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;

contract Authorization is AuthorizationBase {
    IRoleManager internal immutable __roleManager;

    constructor(IRoleManager roleManager) {
        __roleManager = roleManager;
    }

    function _roleManager() internal view override returns (IRoleManager) {
        return __roleManager;
    }
}


// File @openzeppelin/contracts/utils/[email protected]

// MIT
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

// MIT
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


// File interfaces/IStakerVault.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;

interface IStakerVault {
    event Staked(address indexed account, uint256 amount);
    event Unstaked(address indexed account, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function initialize(address _token) external;

    function initializeLpGauge(address _lpGauge) external returns (bool);

    function stake(uint256 amount) external returns (bool);

    function stakeFor(address account, uint256 amount) external returns (bool);

    function unstake(uint256 amount) external returns (bool);

    function unstakeFor(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address account, uint256 amount) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function getToken() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function stakedAndActionLockedBalanceOf(address account) external view returns (uint256);

    function actionLockedBalanceOf(address account) external view returns (uint256);

    function increaseActionLockedBalance(address account, uint256 amount) external returns (bool);

    function decreaseActionLockedBalance(address account, uint256 amount) external returns (bool);

    function getStakedByActions() external view returns (uint256);

    function addStrategy(address strategy) external returns (bool);

    function getPoolTotalStaked() external view returns (uint256);

    function prepareLpGauge(address _lpGauge) external returns (bool);

    function executeLpGauge() external returns (bool);

    function getLpGauge() external view returns (address);

    function poolCheckpoint() external returns (bool);

    function isStrategy(address user) external view returns (bool);
}


// File contracts/utils/Preparable.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;


/**
 * @notice Implements the base logic for a two-phase commit
 * @dev This does not implements any access-control so publicly exposed
 * callers should make sure to have the proper checks in palce
 */
contract Preparable is IPreparable {
    uint256 private constant _MIN_DELAY = 3 days;

    mapping(bytes32 => address) public pendingAddresses;
    mapping(bytes32 => uint256) public pendingUInts256;

    mapping(bytes32 => address) public currentAddresses;
    mapping(bytes32 => uint256) public currentUInts256;

    /**
     * @dev Deadlines shares the same namespace regardless of the type
     * of the pending variable so this needs to be enforced in the caller
     */
    mapping(bytes32 => uint256) public deadlines;

    function _prepareDeadline(bytes32 key, uint256 delay) internal {
        require(deadlines[key] == 0, Error.DEADLINE_NOT_ZERO);
        require(delay >= _MIN_DELAY, Error.DELAY_TOO_SHORT);
        deadlines[key] = block.timestamp + delay;
    }

    /**
     * @notice Prepares an uint256 that should be commited to the contract
     * after `_MIN_DELAY` elapsed
     * @param value The value to prepare
     * @return `true` if success.
     */
    function _prepare(
        bytes32 key,
        uint256 value,
        uint256 delay
    ) internal returns (bool) {
        _prepareDeadline(key, delay);
        pendingUInts256[key] = value;
        emit ConfigPreparedNumber(key, value, delay);
        return true;
    }

    /**
     * @notice Same as `_prepare(bytes32,uint256,uint256)` but uses a default delay
     */
    function _prepare(bytes32 key, uint256 value) internal returns (bool) {
        return _prepare(key, value, _MIN_DELAY);
    }

    /**
     * @notice Prepares an address that should be commited to the contract
     * after `_MIN_DELAY` elapsed
     * @param value The value to prepare
     * @return `true` if success.
     */
    function _prepare(
        bytes32 key,
        address value,
        uint256 delay
    ) internal returns (bool) {
        _prepareDeadline(key, delay);
        pendingAddresses[key] = value;
        emit ConfigPreparedAddress(key, value, delay);
        return true;
    }

    /**
     * @notice Same as `_prepare(bytes32,address,uint256)` but uses a default delay
     */
    function _prepare(bytes32 key, address value) internal returns (bool) {
        return _prepare(key, value, _MIN_DELAY);
    }

    /**
     * @notice Reset a uint256 key
     * @return `true` if success.
     */
    function _resetUInt256Config(bytes32 key) internal returns (bool) {
        require(deadlines[key] != 0, Error.DEADLINE_NOT_ZERO);
        deadlines[key] = 0;
        pendingUInts256[key] = 0;
        emit ConfigReset(key);
        return true;
    }

    /**
     * @notice Reset an address key
     * @return `true` if success.
     */
    function _resetAddressConfig(bytes32 key) internal returns (bool) {
        require(deadlines[key] != 0, Error.DEADLINE_NOT_ZERO);
        deadlines[key] = 0;
        pendingAddresses[key] = address(0);
        emit ConfigReset(key);
        return true;
    }

    /**
     * @dev Checks the deadline of the key and reset it
     */
    function _executeDeadline(bytes32 key) internal {
        uint256 deadline = deadlines[key];
        require(block.timestamp >= deadline, Error.DEADLINE_NOT_REACHED);
        require(deadline != 0, Error.DEADLINE_NOT_SET);
        deadlines[key] = 0;
    }

    /**
     * @notice Execute uint256 config update (with time delay enforced).
     * @dev Needs to be called after the update was prepared. Fails if called before time delay is met.
     * @return New value.
     */
    function _executeUInt256(bytes32 key) internal returns (uint256) {
        _executeDeadline(key);
        uint256 newValue = pendingUInts256[key];
        _setConfig(key, newValue);
        return newValue;
    }

    /**
     * @notice Execute address config update (with time delay enforced).
     * @dev Needs to be called after the update was prepared. Fails if called before time delay is met.
     * @return New value.
     */
    function _executeAddress(bytes32 key) internal returns (address) {
        _executeDeadline(key);
        address newValue = pendingAddresses[key];
        _setConfig(key, newValue);
        return newValue;
    }

    function _setConfig(bytes32 key, address value) internal returns (address) {
        address oldValue = currentAddresses[key];
        currentAddresses[key] = value;
        pendingAddresses[key] = address(0);
        deadlines[key] = 0;
        emit ConfigUpdatedAddress(key, oldValue, value);
        return value;
    }

    function _setConfig(bytes32 key, uint256 value) internal returns (uint256) {
        uint256 oldValue = currentUInts256[key];
        currentUInts256[key] = value;
        pendingUInts256[key] = 0;
        deadlines[key] = 0;
        emit ConfigUpdatedNumber(key, oldValue, value);
        return value;
    }
}


// File contracts/utils/Pausable.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;

abstract contract Pausable {
    bool public isPaused;

    modifier notPaused() {
        require(!isPaused, Error.CONTRACT_PAUSED);
        _;
    }

    modifier onlyAuthorizedToPause() {
        require(_isAuthorizedToPause(msg.sender), Error.UNAUTHORIZED_PAUSE);
        _;
    }

    /**
     * @notice Pause the contract.
     * @return `true` if success.
     */
    function pause() external onlyAuthorizedToPause returns (bool) {
        isPaused = true;
        return true;
    }

    /**
     * @notice Unpause the contract.
     * @return `true` if success.
     */
    function unpause() external onlyAuthorizedToPause returns (bool) {
        isPaused = false;
        return true;
    }

    /**
     * @notice Returns true if `account` is authorized to pause the contract
     * @dev This should be implemented in contracts inheriting `Pausable`
     * to provide proper access control
     */
    function _isAuthorizedToPause(address account) internal view virtual returns (bool);
}


// File contracts/pool/LiquidityPool.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;











/**
 * @dev Pausing/unpausing the pool will disable/re-enable deposits.
 */
abstract contract LiquidityPool is
    ILiquidityPool,
    Authorization,
    Preparable,
    Pausable,
    Initializable
{
    using AddressProviderHelpers for IAddressProvider;
    using ScaledMath for uint256;
    using SafeERC20 for IERC20;

    struct WithdrawalFeeMeta {
        uint64 timeToWait;
        uint64 feeRatio;
        uint64 lastActionTimestamp;
    }

    bytes32 internal constant _VAULT_KEY = "Vault";
    bytes32 internal constant _RESERVE_DEVIATION_KEY = "ReserveDeviation";
    bytes32 internal constant _REQUIRED_RESERVES_KEY = "RequiredReserves";

    bytes32 internal constant _MAX_WITHDRAWAL_FEE_KEY = "MaxWithdrawalFee";
    bytes32 internal constant _MIN_WITHDRAWAL_FEE_KEY = "MinWithdrawalFee";
    bytes32 internal constant _WITHDRAWAL_FEE_DECREASE_PERIOD_KEY = "WithdrawalFeeDecreasePeriod";

    uint256 internal constant _INITIAL_RESERVE_DEVIATION = 0.005e18; // 0.5%
    uint256 internal constant _INITIAL_FEE_DECREASE_PERIOD = 1 weeks;
    uint256 internal constant _INITIAL_MAX_WITHDRAWAL_FEE = 0.03e18; // 3%

    /**
     * @notice even through admin votes and later governance, the withdrawal
     * fee will never be able to go above this value
     */
    uint256 internal constant _MAX_WITHDRAWAL_FEE = 0.05e18;

    /**
     * @notice Keeps track of the withdrawal fees on a per-address basis
     */
    mapping(address => WithdrawalFeeMeta) public withdrawalFeeMetas;

    IController public immutable controller;
    IAddressProvider public immutable addressProvider;

    uint256 public depositCap;
    IStakerVault public staker;
    ILpToken public lpToken;
    string public name;

    constructor(IController _controller)
        Authorization(_controller.addressProvider().getRoleManager())
    {
        require(address(_controller) != address(0), Error.ZERO_ADDRESS_NOT_ALLOWED);
        controller = IController(_controller);
        addressProvider = IController(_controller).addressProvider();
    }

    /**
     * @notice Deposit funds into liquidity pool and mint LP tokens in exchange.
     * @param depositAmount Amount of the underlying asset to supply.
     * @return The actual amount minted.
     */
    function deposit(uint256 depositAmount) external payable override returns (uint256) {
        return depositFor(msg.sender, depositAmount, 0);
    }

    /**
     * @notice Deposit funds into liquidity pool and mint LP tokens in exchange.
     * @param depositAmount Amount of the underlying asset to supply.
     * @param minTokenAmount Minimum amount of LP tokens that should be minted.
     * @return The actual amount minted.
     */
    function deposit(uint256 depositAmount, uint256 minTokenAmount)
        external
        payable
        override
        returns (uint256)
    {
        return depositFor(msg.sender, depositAmount, minTokenAmount);
    }

    /**
     * @notice Deposit funds into liquidity pool and stake LP Tokens in Staker Vault.
     * @param depositAmount Amount of the underlying asset to supply.
     * @param minTokenAmount Minimum amount of LP tokens that should be minted.
     * @return The actual amount minted and staked.
     */
    function depositAndStake(uint256 depositAmount, uint256 minTokenAmount)
        external
        payable
        override
        returns (uint256)
    {
        uint256 amountMinted_ = depositFor(address(this), depositAmount, minTokenAmount);
        staker.stakeFor(msg.sender, amountMinted_);
        return amountMinted_;
    }

    /**
     * @notice Withdraws all funds from vault.
     * @dev Should be called in case of emergencies.
     */
    function withdrawAll() external override onlyGovernance {
        getVault().withdrawAll();
    }

    function setLpToken(address _lpToken)
        external
        override
        onlyRoles2(Roles.GOVERNANCE, Roles.POOL_FACTORY)
        returns (bool)
    {
        require(address(lpToken) == address(0), Error.ADDRESS_ALREADY_SET);
        require(ILpToken(_lpToken).minter() == address(this), Error.INVALID_MINTER);
        lpToken = ILpToken(_lpToken);
        _approveStakerVaultSpendingLpTokens();
        emit LpTokenSet(_lpToken);
        return true;
    }

    /**
     * @notice Checkpoint function to update a user's withdrawal fees on deposit and redeem
     * @param from Address sending from
     * @param to Address sending to
     * @param amount Amount to redeem or deposit
     */
    function handleLpTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) external override {
        require(
            msg.sender == address(lpToken) || msg.sender == address(staker),
            Error.UNAUTHORIZED_ACCESS
        );
        if (
            addressProvider.isStakerVault(to, address(lpToken)) ||
            addressProvider.isStakerVault(from, address(lpToken)) ||
            addressProvider.isAction(to) ||
            addressProvider.isAction(from)
        ) {
            return;
        }

        if (to != address(0)) {
            _updateUserFeesOnDeposit(to, from, amount);
        }
    }

    /**
     * @notice Prepare update of required reserve ratio (with time delay enforced).
     * @param _newRatio New required reserve ratio.
     * @return `true` if success.
     */
    function prepareNewRequiredReserves(uint256 _newRatio) external onlyGovernance returns (bool) {
        require(_newRatio <= ScaledMath.ONE, Error.INVALID_AMOUNT);
        return _prepare(_REQUIRED_RESERVES_KEY, _newRatio);
    }

    /**
     * @notice Execute required reserve ratio update (with time delay enforced).
     * @dev Needs to be called after the update was prepraed. Fails if called before time delay is met.
     * @return New required reserve ratio.
     */
    function executeNewRequiredReserves() external override returns (uint256) {
        uint256 requiredReserveRatio = _executeUInt256(_REQUIRED_RESERVES_KEY);
        _rebalanceVault();
        return requiredReserveRatio;
    }

    /**
     * @notice Reset the prepared required reserves.
     * @return `true` if success.
     */
    function resetRequiredReserves() external onlyGovernance returns (bool) {
        return _resetUInt256Config(_REQUIRED_RESERVES_KEY);
    }

    /**
     * @notice Prepare update of reserve deviation ratio (with time delay enforced).
     * @param newRatio New reserve deviation ratio.
     * @return `true` if success.
     */
    function prepareNewReserveDeviation(uint256 newRatio) external onlyGovernance returns (bool) {
        require(newRatio <= (ScaledMath.DECIMAL_SCALE * 50) / 100, Error.INVALID_AMOUNT);
        return _prepare(_RESERVE_DEVIATION_KEY, newRatio);
    }

    /**
     * @notice Execute reserve deviation ratio update (with time delay enforced).
     * @dev Needs to be called after the update was prepraed. Fails if called before time delay is met.
     * @return New reserve deviation ratio.
     */
    function executeNewReserveDeviation() external override returns (uint256) {
        uint256 reserveDeviation = _executeUInt256(_RESERVE_DEVIATION_KEY);
        _rebalanceVault();
        return reserveDeviation;
    }

    /**
     * @notice Reset the prepared reserve deviation.
     * @return `true` if success.
     */
    function resetNewReserveDeviation() external onlyGovernance returns (bool) {
        return _resetUInt256Config(_RESERVE_DEVIATION_KEY);
    }

    /**
     * @notice Prepare update of min withdrawal fee (with time delay enforced).
     * @param newFee New min withdrawal fee.
     * @return `true` if success.
     */
    function prepareNewMinWithdrawalFee(uint256 newFee) external onlyGovernance returns (bool) {
        _checkFeeInvariants(newFee, getMaxWithdrawalFee());
        return _prepare(_MIN_WITHDRAWAL_FEE_KEY, newFee);
    }

    /**
     * @notice Execute min withdrawal fee update (with time delay enforced).
     * @dev Needs to be called after the update was prepraed. Fails if called before time delay is met.
     * @return New withdrawal fee.
     */
    function executeNewMinWithdrawalFee() external returns (uint256) {
        uint256 newFee = _executeUInt256(_MIN_WITHDRAWAL_FEE_KEY);
        _checkFeeInvariants(newFee, getMaxWithdrawalFee());
        return newFee;
    }

    /**
     * @notice Reset the prepared min withdrawal fee
     * @return `true` if success.
     */
    function resetNewMinWithdrawalFee() external onlyGovernance returns (bool) {
        return _resetUInt256Config(_MIN_WITHDRAWAL_FEE_KEY);
    }

    /**
     * @notice Prepare update of max withdrawal fee (with time delay enforced).
     * @param newFee New max withdrawal fee.
     * @return `true` if success.
     */
    function prepareNewMaxWithdrawalFee(uint256 newFee) external onlyGovernance returns (bool) {
        _checkFeeInvariants(getMinWithdrawalFee(), newFee);
        return _prepare(_MAX_WITHDRAWAL_FEE_KEY, newFee);
    }

    /**
     * @notice Execute max withdrawal fee update (with time delay enforced).
     * @dev Needs to be called after the update was prepraed. Fails if called before time delay is met.
     * @return New max withdrawal fee.
     */
    function executeNewMaxWithdrawalFee() external override returns (uint256) {
        uint256 newFee = _executeUInt256(_MAX_WITHDRAWAL_FEE_KEY);
        _checkFeeInvariants(getMinWithdrawalFee(), newFee);
        return newFee;
    }

    /**
     * @notice Reset the prepared max fee.
     * @return `true` if success.
     */
    function resetNewMaxWithdrawalFee() external onlyGovernance returns (bool) {
        return _resetUInt256Config(_MAX_WITHDRAWAL_FEE_KEY);
    }

    /**
     * @notice Prepare update of withdrawal decrease fee period (with time delay enforced).
     * @param newPeriod New withdrawal fee decrease period.
     * @return `true` if success.
     */
    function prepareNewWithdrawalFeeDecreasePeriod(uint256 newPeriod)
        external
        onlyGovernance
        returns (bool)
    {
        return _prepare(_WITHDRAWAL_FEE_DECREASE_PERIOD_KEY, newPeriod);
    }

    /**
     * @notice Execute withdrawal fee decrease period update (with time delay enforced).
     * @dev Needs to be called after the update was prepraed. Fails if called before time delay is met.
     * @return New withdrawal fee decrease period.
     */
    function executeNewWithdrawalFeeDecreasePeriod() external returns (uint256) {
        return _executeUInt256(_WITHDRAWAL_FEE_DECREASE_PERIOD_KEY);
    }

    /**
     * @notice Reset the prepared withdrawal fee decrease period update.
     * @return `true` if success.
     */
    function resetNewWithdrawalFeeDecreasePeriod() external onlyGovernance returns (bool) {
        return _resetUInt256Config(_WITHDRAWAL_FEE_DECREASE_PERIOD_KEY);
    }

    /**
     * @notice Set the staker vault for this pool's LP token
     * @dev Staker vault and LP token pairs are immutable and the staker vault can only be set once for a pool.
     *      Only one vault exists per LP token. This information will be retrieved from the controller of the pool.
     * @return Address of the new staker vault for the pool.
     */
    function setStaker()
        external
        override
        onlyRoles2(Roles.GOVERNANCE, Roles.POOL_FACTORY)
        returns (bool)
    {
        require(address(staker) == address(0), Error.ADDRESS_ALREADY_SET);
        address stakerVault = addressProvider.getStakerVault(address(lpToken));
        require(stakerVault != address(0), Error.ZERO_ADDRESS_NOT_ALLOWED);
        staker = IStakerVault(stakerVault);
        _approveStakerVaultSpendingLpTokens();
        emit StakerVaultSet(stakerVault);
        return true;
    }

    /**
     * @notice Prepare setting a new Vault (with time delay enforced).
     * @param _vault Address of new Vault contract.
     * @return `true` if success.
     */
    function prepareNewVault(address _vault) external override onlyGovernance returns (bool) {
        _prepare(_VAULT_KEY, _vault);
        return true;
    }

    /**
     * @notice Execute Vault update (with time delay enforced).
     * @dev Needs to be called after the update was prepraed. Fails if called before time delay is met.
     * @return Address of new Vault contract.
     */
    function executeNewVault() external override returns (address) {
        IVault vault = getVault();
        if (address(vault) != address(0)) {
            vault.withdrawAll();
        }
        address newVault = _executeAddress(_VAULT_KEY);
        addressProvider.updateVault(address(vault), newVault);
        return newVault;
    }

    /**
     * @notice Reset the vault deadline.
     * @return `true` if success.
     */
    function resetNewVault() external onlyGovernance returns (bool) {
        return _resetAddressConfig(_VAULT_KEY);
    }

    /**
     * @notice Redeems the underlying asset by burning LP tokens.
     * @param redeemLpTokens Number of tokens to burn for redeeming the underlying.
     * @return Actual amount of the underlying redeemed.
     */
    function redeem(uint256 redeemLpTokens) external override returns (uint256) {
        return redeem(redeemLpTokens, 0);
    }

    /**
     * @notice Uncap the pool to remove the deposit limit.
     * @return `true` if success.
     */
    function uncap() external override onlyGovernance returns (bool) {
        require(isCapped(), Error.NOT_CAPPED);

        depositCap = 0;
        return true;
    }

    /**
     * @notice Update the deposit cap value.
     * @param _depositCap The maximum allowed deposits per address in the pool
     * @return `true` if success.
     */
    function updateDepositCap(uint256 _depositCap) external override onlyGovernance returns (bool) {
        require(isCapped(), Error.NOT_CAPPED);
        require(depositCap != _depositCap, Error.SAME_AS_CURRENT);
        require(_depositCap > 0, Error.INVALID_AMOUNT);

        depositCap = _depositCap;
        return true;
    }

    /**
     * @notice Rebalance vault according to required underlying backing reserves.
     */
    function rebalanceVault() external onlyGovernance {
        _rebalanceVault();
    }

    /**
     * @notice Deposit funds for an address into liquidity pool and mint LP tokens in exchange.
     * @param account Account to deposit for.
     * @param depositAmount Amount of the underlying asset to supply.
     * @return Actual amount minted.
     */
    function depositFor(address account, uint256 depositAmount)
        external
        payable
        override
        returns (uint256)
    {
        return depositFor(account, depositAmount, 0);
    }

    /**
     * @notice Redeems the underlying asset by burning LP tokens, unstaking any LP tokens needed.
     * @param redeemLpTokens Number of tokens to unstake and/or burn for redeeming the underlying.
     * @param minRedeemAmount Minimum amount of underlying that should be received.
     * @return Actual amount of the underlying redeemed.
     */
    function unstakeAndRedeem(uint256 redeemLpTokens, uint256 minRedeemAmount)
        external
        override
        returns (uint256)
    {
        uint256 lpBalance_ = lpToken.balanceOf(msg.sender);
        require(
            lpBalance_ + staker.balanceOf(msg.sender) >= redeemLpTokens,
            Error.INSUFFICIENT_BALANCE
        );
        if (lpBalance_ < redeemLpTokens) {
            staker.unstakeFor(msg.sender, msg.sender, redeemLpTokens - lpBalance_);
        }
        return redeem(redeemLpTokens, minRedeemAmount);
    }

    /**
     * @notice Returns the address of the LP token of this pool
     * @return The address of the LP token
     */
    function getLpToken() external view override returns (address) {
        return address(lpToken);
    }

    /**
     * @notice Calculates the amount of LP tokens that need to be redeemed to get a certain amount of underlying (includes fees and exchange rate)
     * @param account Address of the account redeeming.
     * @param underlyingAmount The amount of underlying desired.
     * @return Amount of LP tokens that need to be redeemed.
     */
    function calcRedeem(address account, uint256 underlyingAmount)
        external
        view
        override
        returns (uint256)
    {
        require(underlyingAmount > 0, Error.INVALID_AMOUNT);
        ILpToken lpToken_ = lpToken;
        require(lpToken_.balanceOf(account) > 0, Error.INSUFFICIENT_BALANCE);

        uint256 currentExchangeRate = exchangeRate();
        uint256 withoutFeesLpAmount = underlyingAmount.scaledDiv(currentExchangeRate);
        if (withoutFeesLpAmount == lpToken_.totalSupply()) {
            return withoutFeesLpAmount;
        }

        WithdrawalFeeMeta memory meta = withdrawalFeeMetas[account];

        uint256 currentFeeRatio = 0;
        if (!addressProvider.isAction(account)) {
            currentFeeRatio = getNewCurrentFees(
                meta.timeToWait,
                meta.lastActionTimestamp,
                meta.feeRatio
            );
        }
        uint256 scalingFactor = currentExchangeRate.scaledMul((ScaledMath.ONE - currentFeeRatio));
        uint256 neededLpTokens = underlyingAmount.scaledDivRoundUp(scalingFactor);

        return neededLpTokens;
    }

    function getUnderlying() external view virtual override returns (address);

    /**
     * @notice Deposit funds for an address into liquidity pool and mint LP tokens in exchange.
     * @param account Account to deposit for.
     * @param depositAmount Amount of the underlying asset to supply.
     * @param minTokenAmount Minimum amount of LP tokens that should be minted.
     * @return Actual amount minted.
     */
    function depositFor(
        address account,
        uint256 depositAmount,
        uint256 minTokenAmount
    ) public payable override notPaused returns (uint256) {
        uint256 rate = exchangeRate();

        if (isCapped()) {
            uint256 lpBalance = lpToken.balanceOf(account);
            uint256 stakedAndLockedBalance = staker.stakedAndActionLockedBalanceOf(account);
            uint256 currentUnderlyingBalance = (lpBalance + stakedAndLockedBalance).scaledMul(rate);
            require(
                currentUnderlyingBalance + depositAmount <= depositCap,
                Error.EXCEEDS_DEPOSIT_CAP
            );
        }

        _doTransferIn(msg.sender, depositAmount);
        uint256 mintedLp = depositAmount.scaledDiv(rate);
        require(mintedLp >= minTokenAmount, Error.INVALID_AMOUNT);

        lpToken.mint(account, mintedLp);
        _rebalanceVault();

        if (msg.sender == account || address(this) == account) {
            emit Deposit(msg.sender, depositAmount, mintedLp);
        } else {
            emit DepositFor(msg.sender, account, depositAmount, mintedLp);
        }
        return mintedLp;
    }

    /**
     * @notice Redeems the underlying asset by burning LP tokens.
     * @param redeemLpTokens Number of tokens to burn for redeeming the underlying.
     * @param minRedeemAmount Minimum amount of underlying that should be received.
     * @return Actual amount of the underlying redeemed.
     */
    function redeem(uint256 redeemLpTokens, uint256 minRedeemAmount)
        public
        override
        returns (uint256)
    {
        require(redeemLpTokens > 0, Error.INVALID_AMOUNT);
        ILpToken lpToken_ = lpToken;
        require(lpToken_.balanceOf(msg.sender) >= redeemLpTokens, Error.INSUFFICIENT_BALANCE);

        uint256 withdrawalFee = addressProvider.isAction(msg.sender)
            ? 0
            : getWithdrawalFee(msg.sender, redeemLpTokens);
        uint256 redeemMinusFees = redeemLpTokens - withdrawalFee;
        // Pay no fees on the last withdrawal (avoid locking funds in the pool)
        if (redeemLpTokens == lpToken_.totalSupply()) {
            redeemMinusFees = redeemLpTokens;
        }
        uint256 redeemUnderlying = redeemMinusFees.scaledMul(exchangeRate());
        require(redeemUnderlying >= minRedeemAmount, Error.NOT_ENOUGH_FUNDS_WITHDRAWN);

        _rebalanceVault(redeemUnderlying);

        lpToken_.burn(msg.sender, redeemLpTokens);
        _doTransferOut(payable(msg.sender), redeemUnderlying);
        emit Redeem(msg.sender, redeemUnderlying, redeemLpTokens);
        return redeemUnderlying;
    }

    /**
     * @return the current required reserves ratio
     */
    function getRequiredReserveRatio() public view virtual returns (uint256) {
        return currentUInts256[_REQUIRED_RESERVES_KEY];
    }

    /**
     * @return the current maximum reserve deviation ratio
     */
    function getMaxReserveDeviationRatio() public view virtual returns (uint256) {
        return currentUInts256[_RESERVE_DEVIATION_KEY];
    }

    /**
     * @notice Returns the current minimum withdrawal fee
     */
    function getMinWithdrawalFee() public view returns (uint256) {
        return currentUInts256[_MIN_WITHDRAWAL_FEE_KEY];
    }

    /**
     * @notice Returns the current maximum withdrawal fee
     */
    function getMaxWithdrawalFee() public view returns (uint256) {
        return currentUInts256[_MAX_WITHDRAWAL_FEE_KEY];
    }

    /**
     * @notice Returns the current withdrawal fee decrease period
     */
    function getWithdrawalFeeDecreasePeriod() public view returns (uint256) {
        return currentUInts256[_WITHDRAWAL_FEE_DECREASE_PERIOD_KEY];
    }

    /**
     * @return the current vault of the liquidity pool
     */
    function getVault() public view virtual override returns (IVault) {
        return IVault(currentAddresses[_VAULT_KEY]);
    }

    /**
     * @notice Compute current exchange rate of LP tokens to underlying scaled to 1e18.
     * @dev Exchange rate means: underlying = LP token * exchangeRate
     * @return Current exchange rate.
     */
    function exchangeRate() public view override returns (uint256) {
        uint256 totalUnderlying_ = totalUnderlying();
        uint256 totalSupply = lpToken.totalSupply();
        if (totalSupply == 0 || totalUnderlying_ == 0) {
            return ScaledMath.ONE;
        }

        return totalUnderlying_.scaledDiv(totalSupply);
    }

    /**
     * @notice Compute total amount of underlying tokens for this pool.
     * @return Total amount of underlying in pool.
     */
    function totalUnderlying() public view override returns (uint256) {
        IVault vault = getVault();
        uint256 balanceUnderlying = _getBalanceUnderlying();
        if (address(vault) == address(0)) {
            return balanceUnderlying;
        }
        uint256 investedUnderlying = vault.getTotalUnderlying();
        return investedUnderlying + balanceUnderlying;
    }

    /**
     * @notice Retuns if the pool has an active deposit limit
     * @return `true` if there is currently a deposit limit
     */
    function isCapped() public view override returns (bool) {
        return depositCap != 0;
    }

    /**
     * @notice Returns the withdrawal fee for `account`
     * @param account Address to get the withdrawal fee for
     * @param amount Amount to calculate the withdrawal fee for
     * @return Withdrawal fee in LP tokens
     */
    function getWithdrawalFee(address account, uint256 amount)
        public
        view
        override
        returns (uint256)
    {
        WithdrawalFeeMeta memory meta = withdrawalFeeMetas[account];

        if (lpToken.balanceOf(account) == 0) {
            return 0;
        }
        uint256 currentFee = getNewCurrentFees(
            meta.timeToWait,
            meta.lastActionTimestamp,
            meta.feeRatio
        );
        return amount.scaledMul(currentFee);
    }

    /**
     * @notice Calculates the withdrawal fee a user would currently need to pay on currentBalance.
     * @param timeToWait The total time to wait until the withdrawal fee reached the min. fee
     * @param lastActionTimestamp Timestamp of the last fee update
     * @param feeRatio Fees that would currently be paid on the user's entire balance
     * @return Updated fee amount on the currentBalance
     */
    function getNewCurrentFees(
        uint256 timeToWait,
        uint256 lastActionTimestamp,
        uint256 feeRatio
    ) public view returns (uint256) {
        uint256 timeElapsed = _getTime() - lastActionTimestamp;
        uint256 minFeePercentage = getMinWithdrawalFee();
        if (timeElapsed >= timeToWait) {
            return minFeePercentage;
        }
        uint256 elapsedShare = timeElapsed.scaledDiv(timeToWait);
        return feeRatio - (feeRatio - minFeePercentage).scaledMul(elapsedShare);
    }

    function _rebalanceVault() internal {
        _rebalanceVault(0);
    }

    function _initialize(
        string memory name_,
        uint256 depositCap_,
        address vault_
    ) internal initializer returns (bool) {
        name = name_;
        depositCap = depositCap_;

        _setConfig(_WITHDRAWAL_FEE_DECREASE_PERIOD_KEY, _INITIAL_FEE_DECREASE_PERIOD);
        _setConfig(_MAX_WITHDRAWAL_FEE_KEY, _INITIAL_MAX_WITHDRAWAL_FEE);
        _setConfig(_REQUIRED_RESERVES_KEY, ScaledMath.ONE);
        _setConfig(_RESERVE_DEVIATION_KEY, _INITIAL_RESERVE_DEVIATION);
        _setConfig(_VAULT_KEY, vault_);
        return true;
    }

    function _approveStakerVaultSpendingLpTokens() internal {
        address staker_ = address(staker);
        address lpToken_ = address(lpToken);
        if (staker_ == address(0) || lpToken_ == address(0)) return;
        IERC20(lpToken_).safeApprove(staker_, type(uint256).max);
    }

    function _doTransferIn(address from, uint256 amount) internal virtual;

    function _doTransferOut(address payable to, uint256 amount) internal virtual;

    /**
     * @dev Rebalances the pool's allocations to the vault
     * @param underlyingToWithdraw Amount of underlying to withdraw such that after the withdrawal the pool and vault allocations are correctly balanced.
     */
    function _rebalanceVault(uint256 underlyingToWithdraw) internal {
        IVault vault = getVault();

        if (address(vault) == address(0)) return;
        uint256 lockedLp = staker.getStakedByActions();
        uint256 totalUnderlyingStaked = lockedLp.scaledMul(exchangeRate());

        uint256 underlyingBalance = _getBalanceUnderlying(true);
        uint256 maximumDeviation = totalUnderlyingStaked.scaledMul(getMaxReserveDeviationRatio());

        uint256 nextTargetBalance = totalUnderlyingStaked.scaledMul(getRequiredReserveRatio());

        if (
            underlyingToWithdraw > underlyingBalance ||
            (underlyingBalance - underlyingToWithdraw) + maximumDeviation < nextTargetBalance
        ) {
            uint256 requiredDeposits = nextTargetBalance + underlyingToWithdraw - underlyingBalance;
            vault.withdraw(requiredDeposits);
        } else {
            uint256 nextBalance = underlyingBalance - underlyingToWithdraw;
            if (nextBalance > nextTargetBalance + maximumDeviation) {
                uint256 excessDeposits = nextBalance - nextTargetBalance;
                _doTransferOut(payable(address(vault)), excessDeposits);
                vault.deposit();
            }
        }
    }

    function _updateUserFeesOnDeposit(
        address account,
        address from,
        uint256 amountAdded
    ) internal {
        WithdrawalFeeMeta storage meta = withdrawalFeeMetas[account];
        uint256 balance = lpToken.balanceOf(account) +
            staker.stakedAndActionLockedBalanceOf(account);
        uint256 newCurrentFeeRatio = getNewCurrentFees(
            meta.timeToWait,
            meta.lastActionTimestamp,
            meta.feeRatio
        );
        uint256 shareAdded = amountAdded.scaledDiv(amountAdded + balance);
        uint256 shareExisting = ScaledMath.ONE - shareAdded;
        uint256 feeOnDeposit;
        if (from == address(0)) {
            feeOnDeposit = getMaxWithdrawalFee();
        } else {
            WithdrawalFeeMeta storage fromMeta = withdrawalFeeMetas[from];
            feeOnDeposit = getNewCurrentFees(
                fromMeta.timeToWait,
                fromMeta.lastActionTimestamp,
                fromMeta.feeRatio
            );
        }

        uint256 newFeeRatio = shareExisting.scaledMul(newCurrentFeeRatio) +
            shareAdded.scaledMul(feeOnDeposit);

        meta.feeRatio = uint64(newFeeRatio);
        meta.timeToWait = uint64(getWithdrawalFeeDecreasePeriod());
        meta.lastActionTimestamp = uint64(_getTime());
    }

    function _getBalanceUnderlying() internal view virtual returns (uint256);

    function _getBalanceUnderlying(bool transferInDone) internal view virtual returns (uint256);

    function _isAuthorizedToPause(address account) internal view override returns (bool) {
        return _roleManager().hasRole(Roles.GOVERNANCE, account);
    }

    /**
     * @dev Overriden for testing
     */
    function _getTime() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    function _checkFeeInvariants(uint256 minFee, uint256 maxFee) internal pure {
        require(maxFee >= minFee, Error.INVALID_AMOUNT);
        require(maxFee <= _MAX_WITHDRAWAL_FEE, Error.INVALID_AMOUNT);
    }
}


// File contracts/actions/topup/TopUpActionFeeHandler.sol

// GPL-3.0-or-later
pragma solidity 0.8.9;








/**
 * @notice Contract to manage the distribution protocol fees
 */
contract TopUpActionFeeHandler is IActionFeeHandler, Authorization, Preparable {
    using ScaledMath for uint256;
    using SafeERC20Upgradeable for LpToken;
    using AddressProviderHelpers for IAddressProvider;

    bytes32 internal constant _KEEPER_FEE_FRACTION_KEY = "KeeperFee";
    bytes32 internal constant _KEEPER_GAUGE_KEY = "KeeperGauge";
    bytes32 internal constant _TREASURY_FEE_FRACTION_KEY = "TreasuryFee";

    address public immutable actionContract;
    IController public immutable controller;

    mapping(address => uint256) public treasuryAmounts;
    mapping(address => mapping(address => uint256)) public keeperRecords;

    event KeeperFeesClaimed(address indexed keeper, address token, uint256 totalClaimed);

    event FeesPayed(
        address indexed payer,
        address indexed keeper,
        address token,
        uint256 amount,
        uint256 keeperAmount,
        uint256 lpAmount
    );

    constructor(
        IController _controller,
        address _actionContract,
        uint256 keeperFee,
        uint256 treasuryFee
    ) Authorization(_controller.addressProvider().getRoleManager()) {
        require(keeperFee + treasuryFee <= ScaledMath.ONE, Error.INVALID_AMOUNT);
        actionContract = _actionContract;
        controller = _controller;
        _setConfig(_KEEPER_FEE_FRACTION_KEY, keeperFee);
        _setConfig(_TREASURY_FEE_FRACTION_KEY, treasuryFee);
    }

    function setInitialKeeperGaugeForToken(address lpToken, address _keeperGauge)
        external
        override
        onlyGovernance
        returns (bool)
    {
        require(getKeeperGauge(lpToken) == address(0), Error.ZERO_ADDRESS_NOT_ALLOWED);
        require(_keeperGauge != address(0), Error.ZERO_ADDRESS_NOT_ALLOWED);
        _setConfig(_getKeeperGaugeKey(lpToken), _keeperGauge);
        return true;
    }

    /**
     * @notice Transfers the keeper and treasury fees to the fee handler and burns LP fees.
     * @param payer Account who's position the fees are charged on.
     * @param beneficiary Beneficiary of the fees paid (usually this will be the keeper).
     * @param amount Total fee value (both keeper and LP fees).
     * @param lpTokenAddress Address of the lpToken used to pay fees.
     * @return `true` if successful.
     */
    function payFees(
        address payer,
        address beneficiary,
        uint256 amount,
        address lpTokenAddress
    ) external override returns (bool) {
        require(msg.sender == actionContract, Error.UNAUTHORIZED_ACCESS);
        // Handle keeper fees
        uint256 keeperAmount = amount.scaledMul(getKeeperFeeFraction());
        uint256 treasuryAmount = amount.scaledMul(getTreasuryFeeFraction());
        LpToken lpToken = LpToken(lpTokenAddress);

        lpToken.safeTransferFrom(msg.sender, address(this), amount);

        address keeperGauge = getKeeperGauge(lpTokenAddress);
        if (keeperGauge != address(0)) {
            IKeeperGauge(keeperGauge).reportFees(beneficiary, keeperAmount, lpTokenAddress);
        }

        // Accrue keeper and treasury fees here for periodic claiming
        keeperRecords[beneficiary][lpTokenAddress] += keeperAmount;
        treasuryAmounts[lpTokenAddress] += treasuryAmount;

        // Handle LP fees
        uint256 lpAmount = amount - keeperAmount - treasuryAmount;
        lpToken.burn(lpAmount);
        emit FeesPayed(payer, beneficiary, lpTokenAddress, amount, keeperAmount, lpAmount);
        return true;
    }

    /**
     * @notice Claim all accrued fees for an LPToken.
     * @param beneficiary Address to claim the fees for.
     * @param token Address of the lpToken for claiming.
     * @return `true` if successful.
     */
    function claimKeeperFeesForPool(address beneficiary, address token)
        external
        override
        returns (bool)
    {
        uint256 totalClaimable = keeperRecords[beneficiary][token];
        require(totalClaimable > 0, Error.NOTHING_TO_CLAIM);
        keeperRecords[beneficiary][token] = 0;

        LpToken lpToken = LpToken(token);
        lpToken.safeTransfer(beneficiary, totalClaimable);

        emit KeeperFeesClaimed(beneficiary, token, totalClaimable);
        return true;
    }

    /**
     * @notice Claim all accrued treasury fees for an LPToken.
     * @param token Address of the lpToken for claiming.
     * @return `true` if successful.
     */
    function claimTreasuryFees(address token) external override returns (bool) {
        uint256 claimable = treasuryAmounts[token];
        treasuryAmounts[token] = 0;
        LpToken(token).safeTransfer(controller.addressProvider().getTreasury(), claimable);
        return true;
    }

    /**
     * @notice Prepare update of keeper fee (with time delay enforced).
     * @param newKeeperFee New keeper fee value.
     * @return `true` if successful.
     */
    function prepareKeeperFee(uint256 newKeeperFee) external onlyGovernance returns (bool) {
        require(newKeeperFee <= ScaledMath.ONE, Error.INVALID_AMOUNT);
        return _prepare(_KEEPER_FEE_FRACTION_KEY, newKeeperFee);
    }

    /**
     * @notice Execute update of keeper fee (with time delay enforced).
     * @dev Needs to be called after the update was prepraed. Fails if called before time delay is met.
     * @return New keeper fee.
     */
    function executeKeeperFee() external returns (uint256) {
        require(
            pendingUInts256[_TREASURY_FEE_FRACTION_KEY] +
                pendingUInts256[_KEEPER_FEE_FRACTION_KEY] <=
                ScaledMath.ONE,
            Error.INVALID_AMOUNT
        );
        return _executeUInt256(_KEEPER_FEE_FRACTION_KEY);
    }

    function resetKeeperFee() external onlyGovernance returns (bool) {
        return _resetUInt256Config(_KEEPER_FEE_FRACTION_KEY);
    }

    function prepareKeeperGauge(address lpToken, address newKeeperGauge)
        external
        onlyGovernance
        returns (bool)
    {
        return _prepare(_getKeeperGaugeKey(lpToken), newKeeperGauge);
    }

    function executeKeeperGauge(address lpToken) external returns (address) {
        return _executeAddress(_getKeeperGaugeKey(lpToken));
    }

    function resetKeeperGauge(address lpToken) external onlyGovernance returns (bool) {
        return _resetAddressConfig(_getKeeperGaugeKey(lpToken));
    }

    /**
     * @notice Prepare update of treasury fee (with time delay enforced).
     * @param newTreasuryFee New treasury fee value.
     * @return `true` if successful.
     */
    function prepareTreasuryFee(uint256 newTreasuryFee) external onlyGovernance returns (bool) {
        require(newTreasuryFee <= ScaledMath.ONE, Error.INVALID_AMOUNT);
        return _prepare(_TREASURY_FEE_FRACTION_KEY, newTreasuryFee);
    }

    /**
     * @notice Execute update of treasury fee (with time delay enforced).
     * @dev Needs to be called after the update was prepraed. Fails if called before time delay is met.
     * @return New treasury fee.
     */
    function executeTreasuryFee() external returns (uint256) {
        require(
            pendingUInts256[_TREASURY_FEE_FRACTION_KEY] +
                pendingUInts256[_KEEPER_FEE_FRACTION_KEY] <=
                ScaledMath.ONE,
            Error.INVALID_AMOUNT
        );
        return _executeUInt256(_TREASURY_FEE_FRACTION_KEY);
    }

    function resetTreasuryFee() external onlyGovernance returns (bool) {
        return _resetUInt256Config(_TREASURY_FEE_FRACTION_KEY);
    }

    function getKeeperFeeFraction() public view returns (uint256) {
        return currentUInts256[_KEEPER_FEE_FRACTION_KEY];
    }

    function getKeeperGauge(address lpToken) public view returns (address) {
        return currentAddresses[_getKeeperGaugeKey(lpToken)];
    }

    function getTreasuryFeeFraction() public view returns (uint256) {
        return currentUInts256[_TREASURY_FEE_FRACTION_KEY];
    }

    function _getKeeperGaugeKey(address lpToken) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_KEEPER_GAUGE_KEY, lpToken));
    }
}
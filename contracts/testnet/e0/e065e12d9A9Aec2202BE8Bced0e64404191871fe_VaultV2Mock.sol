// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Address.sol";
import "SafeERC20.sol";
import "ReentrancyGuard.sol";
import "Pausable.sol";
import "AaveV3Pipeline.sol";
import "IVault.sol";
import "IPipeline.sol";

// Use this for testnet (see line 65)
contract VaultV2Mock is AaveV3Pipeline, Pausable, IVault {
  using SafeERC20 for IERC20;
  using Address for address;

  address public router;
  address public admin;

  address public pool; // Which contract is used to stake

  address public asset;

  address public pipeline;

  event Compound(uint256 newDebt);
  event FeesUpdated(uint256 newFee);
  event RouterUpdated(address newRouter);
  event NewAdmin(address newAdmin);
  event DebugV(uint256 amount, string msg);

  constructor(
    address _router,
    address _admin,
    address _asset,
    uint256 _feeAmount
  ) {
    router = _router;
    admin = _admin;
    asset = _asset;
    feeAmount = _feeAmount;
  }

  function initializePipeline(bytes memory _pipelineParams) external onlyAdmin {
    _initialize(_pipelineParams);
  }

  modifier onlyRouter() {
    require(msg.sender == router, "vault: not router");
    _;
  }

  modifier onlyAdmin() {
    require(msg.sender == admin, "vault: not admin");
    _;
  }

  // Deposit/Withdraw logic
  function deposit(uint256 _amount)
    external
    onlyRouter
    returns (uint256 depositedAmount)
  {
    // If deposits are paused, we don't invest them and keep them in the vault
    // This prevents reverts in case of Stargate transfers
    if (true) {
      IERC20(asset).transferFrom(msg.sender, address(this), _amount);
      return _amount;
    } else {
      IERC20(asset).transferFrom(msg.sender, address(this), _amount);
      depositedAmount = _deposit(_amount);
    }
    emit DebugV(0, "afterDep");
  }

  function withdraw(uint256 _amount) external onlyRouter returns (uint256) {
    uint256 vaultBal = IERC20(asset).balanceOf(address(this));
    return _withdraw(_amount);
  }

  function harvestCompoundUpdate()
    external
    onlyRouter
    returns (uint256 newDebt)
  {
    return IERC20(asset).balanceOf(address(this));
    // return _harvestCompoundUpdate();
  }

  function panic() external onlyAdmin {
    _panic();
    pause();
  }

  function pause() public onlyAdmin {
    _pause();
    emit Paused(msg.sender);
  }

  function unpause() public onlyAdmin {
    _unpause();
    emit Unpaused(msg.sender);
  }

  function updateFee(uint256 _feeAmount) external onlyAdmin {
    feeAmount = _feeAmount;
    emit FeesUpdated(_feeAmount);
  }

  function updateRouter(address _router) external onlyAdmin {
    router = _router;
    emit RouterUpdated(_router);
  }

  function inCaseTokensGetStuck(address _token) external onlyAdmin {
    require(_token != address(asset), "vault: !token");

    uint256 amount = IERC20(_token).balanceOf(address(this));
    IERC20(_token).safeTransfer(msg.sender, amount);
  }

  function updateAdmin(address _newAdmin) external onlyAdmin {
    admin = _newAdmin;
    emit NewAdmin(_newAdmin);
  }

  // Views
  function available() public view returns (uint256) {
    return IERC20(asset).balanceOf(address(this));
  }

  function rewardsAvailable() external view returns (uint256) {
    return _rewardsAvailable();
  }

  function investedInPool() public view returns (uint256) {
    return _investedInPool();
  }

  function totalBalance() public view returns (uint256) {
    return available() + investedInPool();
  }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "Address.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "SafeERC20.sol";
import "IDataProvider.sol";
import "IAaveV3Incentives.sol";
import "ILendingPool.sol";
import "IUniswapRouterETH.sol";

import "IPipeline.sol";

contract AaveV3Pipeline {
  using SafeERC20 for IERC20;
  uint256 public constant MAX_INT = 2**256 - 1;

  // Tokens used
  address public rewardToken;
  address public aToken;
  address public _asset;

  // Third party contracts
  address public dataProvider;
  address public lendingPool;
  address public incentivesController;

  // Routes
  address public unirouter;
  address[] public rewardTokenToAssetRoute;

  uint256 public lastHarvest;
  bool public initialized;

  // params
  address public _router;
  uint256 public feeAmount; // 1 = 0.1%
  uint256 immutable feeDenom = 1000;

  event chargedFees(uint256 amount);
  event rewardsProgramChanged(bool activated);
  event DebugP(uint amount, string msg);

  function _initialize(bytes memory parameters) internal {
    require(!initialized, "pipeline: already initialized");
    (
      _asset,
      _router,
      rewardToken,
      dataProvider, // "PoolDataProvider"
      lendingPool,
      incentivesController,
      unirouter
    ) = abi.decode(
      parameters,
      (address, address, address, address, address, address, address)
    );
    (aToken, , ) = IDataProvider(dataProvider).getReserveTokensAddresses(
      _asset
    );

    rewardTokenToAssetRoute = [rewardToken, _asset];
    _giveAllowances();

    initialized = true;
  }

  function _deposit(uint256 _amount) internal returns (uint256) {
    emit DebugP(IERC20(_asset).balanceOf(address(this)), "pipe");
    ILendingPool(lendingPool).deposit(_asset, _amount, address(this), 0);
    return _amount; // No checks are needed as Aave doesn't have deposit fees
  }

  function _withdraw(uint256 _amount) internal returns (uint256) {
    uint256 vaultBalance = IERC20(_asset).balanceOf(address(this));
    if (vaultBalance < _amount) {
      ILendingPool(lendingPool).withdraw(
        _asset,
        _amount - vaultBalance,
        address(this)
      );
      vaultBalance = IERC20(_asset).balanceOf(address(this));
    }

    if (vaultBalance > _amount) {
      vaultBalance = _amount;
    }

    IERC20(_asset).safeTransfer(_router, vaultBalance);
    return (vaultBalance);
  }

  // Change this if there's no rewards
  function _harvestCompoundUpdate(address _feeRecipient) internal returns (uint256) {
    address[] memory assets = new address[](1);
    assets[0] = aToken;
    // TODO: should we use the return value?
    IAaveV3Incentives(incentivesController).claimRewards(
      assets,
      type(uint256).max,
      address(this),
      rewardToken
    );
    emit DebugP(0, "1");
    uint256 rewardBal = IERC20(rewardToken).balanceOf(address(this));
    if (rewardBal > 0) {
          emit DebugP(0, "2");
      _chargeFees(_feeRecipient);
          emit DebugP(0, "3");
      _swapRewards();
          emit DebugP(0, "4");
      uint256 assetsToInvest = IERC20(_asset).balanceOf(address(this));
      _deposit(assetsToInvest);
    }
    lastHarvest = block.timestamp;

    return (_investedInPool());
  }

  // Remove all funds in case of emergency
  function _panic() internal {
    ILendingPool(lendingPool).withdraw(
      _asset,
      type(uint256).max,
      address(this)
    );
  }

  // Views
  function _investedInPool() internal view returns (uint256) {
    (uint256 supplyBal, , , , , , , , ) = IDataProvider(dataProvider)
      .getUserReserveData(_asset, address(this));
    return supplyBal;
  }

  function _rewardsAvailable() internal view returns (uint256) {
    address[] memory assets = new address[](1);
    assets[0] = aToken;
    return
      IAaveV3Incentives(incentivesController).getUserRewards(
        assets,
        address(this),
        rewardToken
      );
  }

  // Utils
  function _giveAllowances() internal {
    IERC20(_asset).safeApprove(lendingPool, type(uint256).max);
    IERC20(rewardToken).safeApprove(unirouter, type(uint256).max);
  }

  function _removeAllowances() internal {
    IERC20(_asset).safeApprove(lendingPool, 0);
    IERC20(_asset).safeApprove(unirouter, 0);
  }

  function _chargeFees(address _feeRecipient) internal {
    uint256 rewardTokenFeeBal = (IERC20(rewardToken).balanceOf(address(this)) *
      feeAmount) / feeDenom;
    IERC20(rewardToken).safeTransfer(_feeRecipient, rewardTokenFeeBal);
    emit chargedFees(rewardTokenFeeBal);
  }

  // Warning: tx will revert if the amount harvested is too low
  // And if we're swapping a stable with low amount of digits
  function _swapRewards() internal {
    uint256 rewardTokenBal = IERC20(rewardToken).balanceOf(address(this));
    emit DebugP(rewardTokenBal, "rewardBal");
    IUniswapRouterETH(unirouter).swapExactTokensForTokens(
      rewardTokenBal,
      1,
      rewardTokenToAssetRoute,
      address(this),
      block.timestamp+100
    );
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IDataProvider {
    function getReserveTokensAddresses(address asset) external view returns (
        address aTokenAddress,
        address stableDebtTokenAddress,
        address variableDebtTokenAddress
    );

    function getUserReserveData(address asset, address user) external view returns (
        uint256 currentATokenBalance,
        uint256 currentStableDebt,
        uint256 currentVariableDebt,
        uint256 principalStableDebt,
        uint256 scaledVariableDebt,
        uint256 stableBorrowRate,
        uint256 liquidityRate,
        uint40 stableRateLastUpdated,
        bool usageAsCollateralEnabled
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IAaveV3Incentives {
    function claimRewards(address[] calldata assets, uint256 amount, address to, address reward) external returns (uint256);
    function getUserRewards(address[] calldata assets, address user, address reward) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface ILendingPool {

    function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

    function borrow(address asset, uint256 amount, uint256 interestRateMode, uint16 referralCode, address onBehalfOf) external;

    function repay(address asset, uint256 amount, uint256 rateMode, address onBehalfOf) external returns (uint256);

    function withdraw(address asset, uint256 amount, address to) external returns (uint256);

    function getUserAccountData(address user) external view returns (
        uint256 totalCollateralETH,
        uint256 totalDebtETH,
        uint256 availableBorrowsETH,
        uint256 currentLiquidationThreshold,
        uint256 ltv,
        uint256 healthFactor
    );

    function setUserEMode(uint8 categoryId) external;

    function getUserEMode(address user) external view returns (uint256);

    function getEModeCategoryData(uint8 categoryId) external view returns (
        uint16 ltv,
        uint16 liquidationThreshold,
        uint16 liquidationBonus,
        address priceSource,
        string memory label
    );
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IUniswapRouterETH {
  // UniswapV2Router
  event Mint(address indexed sender, uint256 amount0, uint256 amount1);
  event Burn(
    address indexed sender,
    uint256 amount0,
    uint256 amount1,
    address indexed to
  );
  event Swap(
    address indexed sender,
    uint256 amount0In,
    uint256 amount1In,
    uint256 amount0Out,
    uint256 amount1Out,
    address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

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

  event PairCreated(
    address indexed token0,
    address indexed token1,
    address pair,
    uint256
  );

  function addLiquidityETH(
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  )
    external
    payable
    returns (
      uint256 amountToken,
      uint256 amountETH,
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

  function removeLiquidityETH(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountToken, uint256 amountETH);

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function WETH() external view returns (address);

  function swapExactETHForTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function getAmountsOut(uint256 amountIn, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPipeline {


  function deposit(uint256 amount) external returns (uint256);
  function withdraw(uint256 amount) external returns (uint256);
  function harvestCompoundUpdate() external returns (uint256);

  function panic() external;
  function investedInPool(address user, address pool) external view returns (uint256);
  function rewardsAvailable(address user, address _incentivesController) external view returns (uint256);
  function initialize(bytes memory parameters) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVault {
  // Deposit/Withdraw logic
  function deposit(uint256 _amount) external returns (uint256);

  function withdraw(uint256 _amount) external returns (uint256);

  // Administration
  function harvestCompoundUpdate() external returns (uint256 newDebt);

  function panic() external;

  function pause() external;

  function unpause() external;

  function updateFee(uint256 _feeAmount) external;

  function updateRouter(address _router) external;

  function updateAdmin(address _newAdmin) external;

  // Utils
  function inCaseTokensGetStuck(address _token) external;

  // View
  function totalBalance() external view returns (uint256);

  function available() external view returns (uint256);

  function investedInPool() external view returns (uint256);

  function rewardsAvailable() external view returns (uint256);


}
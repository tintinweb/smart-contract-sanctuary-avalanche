// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../interfaces/vaults/gmx/IGMXPerpetualDEXLongVault.sol";
import "../../interfaces/vaults/gmx/IGMXVault.sol";
import "../../interfaces/vaults/gmx/IGMXGLPManager.sol";
import "../../interfaces/staking/gmx/IGMXRewardRouterHandler.sol";
import "../../interfaces/staking/gmx/IGMXRewardRouter.sol";
import "../../interfaces/staking/gmx/IGMXStakePool.sol";
import "../../interfaces/staking/gmx/IGMXRewardReader.sol";
import "../../interfaces/lending/ILendingPool.sol";
import "../../enum/ManagerAction.sol";

contract GMXPerpetualDEXLongManager is Ownable {
  using SafeERC20 for IERC20;

  /* ========== STATE VARIABLES ========== */

  // Vault contract
  IGMXPerpetualDEXLongVault public vault;
  // Deposit token lending pool contract
  ILendingPool public tokenLendingPool;
  // GMX Reward Router contract
  IGMXRewardRouter public rewardRouter;
  // Reward Router contract
  IGMXRewardRouterHandler public rewardRouterHandler;
  // Staking pool contract
  IGMXStakePool public stakePool;
  // GMX GLP manager contract
  IGMXGLPManager public glpManager;
  // GMX reward reader contract
  IGMXRewardReader public rewardReader;
  // GMX Vault contract
  IGMXVault public gmxVault;

  /* ========== CONSTANTS ========== */

  uint256 public constant SAFE_MULTIPLIER = 1e18;

  /* ========== CONSTRUCTOR ========== */

  /**
    * @param _vault Vault contract
    * @param _tokenLendingPool Deposit token (USDC) lending pool contract
    * @param _rewardRouterHandler GMX reward router handler contract
    * @param _rewardRouter GMX reward router contract
    * @param _stakePool  Staked GMX contract
    * @param _glpManager GMX GLP manager contract
    * @param _rewardReader  GMX reward reader contract
    * @param _gmxVault  GMX vault contract
  */
  constructor(
    IGMXPerpetualDEXLongVault _vault,
    ILendingPool _tokenLendingPool,
    IGMXRewardRouterHandler _rewardRouterHandler,
    IGMXRewardRouter _rewardRouter,
    IGMXStakePool _stakePool,
    IGMXGLPManager _glpManager,
    IGMXRewardReader _rewardReader,
    IGMXVault _gmxVault
  ) {
    vault = _vault;
    tokenLendingPool = _tokenLendingPool;
    rewardRouterHandler = _rewardRouterHandler;
    rewardRouter = _rewardRouter;
    stakePool = _stakePool;
    glpManager = _glpManager;
    rewardReader = _rewardReader;
    gmxVault = _gmxVault;
  }

  /* ========== MODIFIERS ========== */

  /**
    * Only allow approved address of vault
  */
  modifier onlyVault() {
    require(msg.sender == address(vault), "Caller is not approved vault");
    _;
  }

  /* ========== VIEW FUNCTIONS ========== */

  /**
    * Deposit token of Vault
    * @return address token address
  */
  function token() public view returns (address) {
    return vault.token();
  }

  /**
    * Return the lp token amount held by manager
    * @return lpTokenAmt lpToken amount
  */
  function lpTokenAmt() public view returns (uint256) {
    return stakePool.balanceOf(address(this));
  }

  /**
    * Returns the desired token weight
    * @param _token   token's address
    * @return tokenWeight token weight in 1e18
  */
  function currentTokenWeight(address _token) public view returns (uint256) {
    uint256 length = gmxVault.allWhitelistedTokensLength();
    uint256 usdgSupply;

    for (uint256 i = 0; i < length; i++) {
      address whitelistedToken = gmxVault.allWhitelistedTokens(i);
      bool isWhitelisted = gmxVault.whitelistedTokens(whitelistedToken);
      if (isWhitelisted) {
        usdgSupply += gmxVault.usdgAmounts(whitelistedToken);
      }
    }
    return gmxVault.usdgAmounts(_token) * SAFE_MULTIPLIER / usdgSupply;
  }

  /**
    * Returns all whitelisted token addresses and current weights
    * @return tokenAddress array of whitelied tokens
    * @return tokenWeight array of token weights in 1e18
  */
  function currentTokenWeights() public view returns (address[] memory, uint256[]memory) {
    uint256 usdgSupply = getTotalUsdgAmount();
    uint256 length = gmxVault.allWhitelistedTokensLength();

    address[] memory tokenAddress = new address[](length);
    uint256[] memory tokenWeight = new uint256[](length);

    for (uint256 i = 0; i < length; i++) {
      address whitelistedToken = gmxVault.allWhitelistedTokens(i);
      bool isWhitelisted = gmxVault.whitelistedTokens(whitelistedToken);
      if (isWhitelisted) {
        tokenAddress[i] = whitelistedToken;
        tokenWeight[i] = gmxVault.usdgAmounts(whitelistedToken)
          * (SAFE_MULTIPLIER)
          / (usdgSupply);
      }
    }

    return (tokenAddress, tokenWeight);
  }

  function assetInfo() public view returns (address[] memory, uint256[] memory) {
    // get manager's glp balance
    uint256 lpTokenBal = lpTokenAmt();
    // get total supply of glp
    uint256 glpTotalSupply = stakePool.totalSupply();
    // get total supply of USDG
    uint256 usdgSupply = getTotalUsdgAmount();

    // calculate manager's glp amt in USDG
    uint256 glpAmtInUsdg = (lpTokenBal * SAFE_MULTIPLIER / glpTotalSupply)
                           * usdgSupply
                           / SAFE_MULTIPLIER;

    uint256 length = gmxVault.allWhitelistedTokensLength();
    address[] memory tokenAddress = new address[](length);
    uint256[] memory tokenAmt = new uint256[](length);

    for (uint256 i = 0; i < length; i++) {
      // check if token is whitelisted
      address whitelistedToken = gmxVault.allWhitelistedTokens(i);
      bool isWhitelisted = gmxVault.whitelistedTokens(whitelistedToken);
      if (isWhitelisted) {
        tokenAddress[i] = whitelistedToken;
        // calculate token weight expressed in token amt
        uint256 tokenWeight = currentTokenWeight(whitelistedToken);

        tokenAmt[i] = (tokenWeight * glpAmtInUsdg / SAFE_MULTIPLIER)
                      * SAFE_MULTIPLIER
                      / (gmxVault.getMinPrice(whitelistedToken) / 1e12);
      }
    }
    return (tokenAddress, tokenAmt);
  }

  /**
    * Get token debt amt from lending pools
    * @return tokenDebtAmt tokenDebtAmt
  */
  function debtInfo() public view returns (uint256) {
      return tokenLendingPool.maxRepay(address(this));
  }

  function getTotalUsdgAmount() public view returns (uint256) {
    uint256 length = gmxVault.allWhitelistedTokensLength();
    uint256 usdgSupply;

    for (uint256 i = 0; i < length; i++) {
      address whitelistedToken = gmxVault.allWhitelistedTokens(i);
      bool isWhitelisted = gmxVault.whitelistedTokens(whitelistedToken);
      if (isWhitelisted) {
        usdgSupply += gmxVault.usdgAmounts(whitelistedToken);
      }
    }
    return usdgSupply;
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  /**
    * General function for deposit, withdraw, rebalance, called by vault
    * @param _action Enum, 0 - Deposit, 1 - Withdraw, 2 - AddLiquidity, 3 - RemoveLiquidity
    * @param _lpAmt Amt of LP tokens to sell for repay
    * @param _borrowTokenAmt Amt of tokens to borrow
    * @param _repayTokenAmt Amt of tokens to repay
  */
  function work(
    ManagerAction _action,
    uint256 _lpAmt,
    uint256 _borrowTokenAmt,
    uint256 _repayTokenAmt
  ) external onlyVault {
    // ********** Deposit Flow **********
    if (_action == ManagerAction.Deposit) {
      // Borrow from lending pool
      _borrow(_borrowTokenAmt);
      // Add tokens to Lp receive Lp tokens and stake
      _addLiquidity();
    }

    // ********** Withdraw Flow **********
    if (_action == ManagerAction.Withdraw) {
      if (_lpAmt > 0) {
        // If estimated LP amount is more than actual LP amount owned
        if (_lpAmt > lpTokenAmt()) {
          _lpAmt = lpTokenAmt();
        }
        // remove Lp receive token
        _removeLiquidity(_lpAmt);
        // repay lending pool
        _repay(_repayTokenAmt);
      }
    }

    // ********** Rebalance: Add Liquidity Flow **********
    if (_action == ManagerAction.AddLiquidity) {
      // Borrow from lending pool
      _borrow(_borrowTokenAmt);
      // If calculated repay amt is substantial, repay lending pool
      if (_repayTokenAmt > (SAFE_MULTIPLIER / 100)) {
        _repay(IERC20(token()).balanceOf(address(this)));
      }
      // Add tokens to Lp receive Lp tokens
      _addLiquidity();
    }

    // ********** Rebalance: Remove Liquidity Flow **********
    if (_action == ManagerAction.RemoveLiquidity) {
      if (_lpAmt > 0) {
        // If estimated LP amount is more than actual LP amount owned
        if (_lpAmt > lpTokenAmt()) {
          _lpAmt = lpTokenAmt();
        }
        // Unstake LP from rewards pool
        _removeLiquidity(_lpAmt);
        // If required, borrow from lending pools
        _borrow(_borrowTokenAmt);
        // repay lending pools
        _repay(IERC20(token()).balanceOf(address(this)));
      }
    }

    // Send tokens back to vault, also account for any dust cleanup
    IERC20(token()).safeTransfer(msg.sender, IERC20(token()).balanceOf(address(this)));
  }

  /**
    * Compound rewards, convert to more LP; called by vault or keeper
  */
  function compound(address[] memory _rewardTrackers) external {
    // check if there are pending rewards to claim
    uint256[] memory res = rewardReader.getStakingInfo(address(this), _rewardTrackers);
    address weth = rewardRouter.weth();

    if (res[0] > 0) {
        // Transfer pending ETH/WETH rewards to manager
      _handleRewards();
    }

    // address weth = rewardRouter.weth();
    // Transfer perf fees to treasury as WETH/WAVAX
    uint256 fee = IERC20(weth).balanceOf(address(this))
                  * vault.perfFee()
                  / SAFE_MULTIPLIER;

    IERC20(weth).safeTransfer(vault.treasury(), fee);

    // Convert remaining WETH/WAVAX to GLP
    IERC20(weth).approve(address(glpManager), IERC20(weth).balanceOf(address(this)));

    rewardRouter.mintAndStakeGlp(
      weth,
      IERC20(weth).balanceOf(address(this)),
      0, // minimum acceptable USD value of the GLP purchased
      0 //  minimum acceptable GLP amount
    );
  }

  /* ========== INTERNAL FUNCTIONS ========== */

  /**
    * Internal function to optimally convert token balances to LP tokens
  */
  function _addLiquidity() internal {

    // Add liquidity
    IERC20(token()).approve(address(glpManager), IERC20(token()).balanceOf(address(this)));

    rewardRouter.mintAndStakeGlp(
      token(),
      IERC20(token()).balanceOf(address(this)),
      0,
      0
    );
  }

  /**
    * Internal function to withdraw LP tokens
    * @param _lpAmt   amt of lp tokens to withdraw
  */
  function _removeLiquidity(uint256 _lpAmt) internal {
    rewardRouter.unstakeAndRedeemGlp(
      token(),
      _lpAmt,
      0,
      address(this)
    );
  }

  /**
    * Internal function to borrow from lending pools
    * @param _borrowTokenAmt   Amt of deposit token to borrow
  */
  function _borrow(uint256 _borrowTokenAmt) internal {
    if (_borrowTokenAmt > 0) {
      tokenLendingPool.borrow(_borrowTokenAmt);
    }
  }

  /**
    * Internal function to repay lending pools
    * @param _repayTokenAmt   Amt of deposit token to repay
  */
  function _repay(uint256 _repayTokenAmt) internal {
    if (_repayTokenAmt > 0) {
      IERC20(token()).approve(address(tokenLendingPool),
      _repayTokenAmt);

      tokenLendingPool.repay(_repayTokenAmt);
    }
  }

  function _handleRewards() internal {
    rewardRouterHandler.handleRewards(
        false, // should claim GMX
        false, // should stake GMX
        false, // should claim esGMX
        true, // should stake esGMX
        false, // should stake multiplier points
        true, // should claim WETH
        false // should convert WETH to ETH
      );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

enum ManagerAction {
  Deposit,
  Withdraw,
  AddLiquidity,
  RemoveLiquidity
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ILendingPool {
  function totalValue() external view returns (uint256);
  function totalAvailableSupply() external view returns (uint256);
  function utilizationRate() external view returns (uint256);
  function exchangeRate() external view returns (uint256);
  function borrowAPR() external view returns (uint256);
  function lendingAPR() external view returns (uint256);
  function maxRepay(address _address) external view returns (uint256);
  function depositNative(uint256 _assetAmount) external payable;
  function deposit(uint256 _assetAmount) external;
  function withdrawNative(uint256 _ibTokenAmount) external;
  function withdraw(uint256 _ibTokenAmount) external;
  function borrow(uint256 _assetAmount) external;
  function repay(uint256 _repayAmount) external;
  function updateProtocolFee(uint256 _protocolFee) external;
  function withdrawReserve(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


interface IGMXPerpetualDEXLongVault {
  function token() external view returns (address);
  function treasury() external view returns (address);
  function perfFee() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IGMXGLPManager {
  function getPrice(bool _maximise) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IGMXRewardRouter {
  function mintAndStakeGlp(address _token, uint256 _amount, uint256 _minUsdg, uint256 _minGlp) external;
  function unstakeAndRedeemGlp(address _tokenOut, uint256 _glpAmount, uint256 _minOut, address _receiver) external;
  function weth() external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IGMXVault {
  function usdgAmounts(address _token) external view returns (uint256);
  function allWhitelistedTokens(uint256 _index) external view returns (address);
  function allWhitelistedTokensLength() external view returns (uint256);
  function whitelistedTokens(address _token) external view returns (bool);
  function getMinPrice(address _token) external view returns (uint256);
  function getMaxPrice(address _token) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IGMXRewardReader {
  function getStakingInfo(address _account, address[] memory _rewardTrackers) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IGMXStakePool {
  function balanceOf(address _account) external view returns (uint256);
  function glp() external view returns (address);
  function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IGMXRewardRouterHandler {
  function handleRewards(
    bool _shouldClaimGmx,
    bool _shouldStakeGmx,
    bool _shouldClaimEsGmx,
    bool _shouldStakeEsGmx,
    bool _shouldStakeMultiplierPoints,
    bool _shouldClaimWeth,
    bool _shouldConvertWethToEth
  ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/enum/ManagerAction.sol";

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../contracts/interfaces/lending/ILendingPool.sol";

abstract contract $ILendingPool is ILendingPool {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../contracts/interfaces/staking/gmx/IGMXRewardReader.sol";

abstract contract $IGMXRewardReader is IGMXRewardReader {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../contracts/interfaces/staking/gmx/IGMXRewardRouter.sol";

abstract contract $IGMXRewardRouter is IGMXRewardRouter {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../contracts/interfaces/staking/gmx/IGMXRewardRouterHandler.sol";

abstract contract $IGMXRewardRouterHandler is IGMXRewardRouterHandler {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../contracts/interfaces/staking/gmx/IGMXStakePool.sol";

abstract contract $IGMXStakePool is IGMXStakePool {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../contracts/interfaces/vaults/gmx/IGMXGLPManager.sol";

abstract contract $IGMXGLPManager is IGMXGLPManager {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../contracts/interfaces/vaults/gmx/IGMXPerpetualDEXLongVault.sol";

abstract contract $IGMXPerpetualDEXLongVault is IGMXPerpetualDEXLongVault {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../contracts/interfaces/vaults/gmx/IGMXVault.sol";

abstract contract $IGMXVault is IGMXVault {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../contracts/vaults/gmx/GMXPerpetualDEXLongManager.sol";

contract $GMXPerpetualDEXLongManager is GMXPerpetualDEXLongManager {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor(IGMXPerpetualDEXLongVault _vault, ILendingPool _tokenLendingPool, IGMXRewardRouterHandler _rewardRouterHandler, IGMXRewardRouter _rewardRouter, IGMXStakePool _stakePool, IGMXGLPManager _glpManager, IGMXRewardReader _rewardReader, IGMXVault _gmxVault) GMXPerpetualDEXLongManager(_vault, _tokenLendingPool, _rewardRouterHandler, _rewardRouter, _stakePool, _glpManager, _rewardReader, _gmxVault) {}

    function $_addLiquidity() external {
        super._addLiquidity();
    }

    function $_removeLiquidity(uint256 _lpAmt) external {
        super._removeLiquidity(_lpAmt);
    }

    function $_borrow(uint256 _borrowTokenAmt) external {
        super._borrow(_borrowTokenAmt);
    }

    function $_repay(uint256 _repayTokenAmt) external {
        super._repay(_repayTokenAmt);
    }

    function $_handleRewards() external {
        super._handleRewards();
    }

    function $_checkOwner() external view {
        super._checkOwner();
    }

    function $_transferOwnership(address newOwner) external {
        super._transferOwnership(newOwner);
    }

    function $_msgSender() external view returns (address ret0) {
        (ret0) = super._msgSender();
    }

    function $_msgData() external view returns (bytes memory ret0) {
        (ret0) = super._msgData();
    }

    receive() external payable {}
}
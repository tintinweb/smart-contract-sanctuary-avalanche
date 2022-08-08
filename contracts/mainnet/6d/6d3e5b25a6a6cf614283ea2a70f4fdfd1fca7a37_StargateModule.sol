pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "../interface/stargate/IStargateRouter.sol";
import "../interface/stargate/ILpStaking.sol";
import { IPool as IPoolStargate } from "../interface/stargate/IPool.sol";
import "./BaseModule.sol";
import "../../common/interface/IDex.sol";


contract StargateModule is BaseModule {
    using SafeERC20 for IERC20;

    uint256 public stgSellThreshold = 200 * 10**18; //threshold to harvest in Stg


    ILpStaking public lpStaking;
    IStargateRouter public stargateRouter;
    address public lpToken;
    address public stgToken;
    uint16 public routerPoolId;
    uint256 public lpStakingPoolId;
    IDex public dex;
    uint256 public currentHarvest;
    address[] public swapPath;

    event DepositSummary(uint16 routerPoolId, uint256 lpStakingPoolId, uint256 amountBaseToken, uint256 amountLpToken);
    event WithdrawSummary(uint16 routerPoolId, uint256 lpStakingPoolId, uint256 amountBaseToken, uint256 amountLpToken);
    event TransferBackFunds(address to, uint256 baseTokenAmount);
    event Harvested(address lpToken, uint256 amount);
    event StgSwapped(uint256 stgAmount, uint256 baseTokenAmount);
    event HarvestWithdrawn(address receiver, uint256 amount);

    constructor(
        address _lpStaking,
        address _stargateRouter,
        address _lpToken,
        address _stgToken,
        address _baseToken,
        uint16 _routerPoolId,
        uint256 _lpStakingPoolId,
        address _owner,
        address _dex,
        address[] memory _swapPath
    ) {
        lpStaking = ILpStaking(_lpStaking);
        stargateRouter = IStargateRouter(_stargateRouter);
        lpToken = _lpToken;
        stgToken = _stgToken;
        baseToken = _baseToken;
        routerPoolId = _routerPoolId;
        lpStakingPoolId = _lpStakingPoolId;
        transferOwnership(_owner);
        dex = IDex(_dex);

        require(_swapPath[0] == stgToken, "Swap path: must start from STG");
        swapPath = _swapPath;

        IERC20(stgToken).safeApprove(address(dex), UINT_MAX);
    }

    function setStgSellThreshold(uint256 newThreshold) onlyOwner external {
        stgSellThreshold = newThreshold;
    }

    function deposit(uint256 amountToken) override external onlyManager whenNotPaused {
        IERC20(baseToken).safeTransferFrom(manager, address(this), amountToken);
        _deposit(amountToken);
    }

    function harvestAndWithdraw(address receiver) override external onlyManager whenNotPaused returns(uint256) {
        _harvest();
        uint256 withdrawalAmount = currentHarvest;
        IERC20(baseToken).safeTransfer(receiver, withdrawalAmount);
        emit HarvestWithdrawn(receiver, withdrawalAmount);
        currentHarvest = 0;
        return withdrawalAmount;
    }

    function harvest() override external onlyManager whenNotPaused {
        _harvest();
    }

    function getCurrentHarvest() override external view returns(uint256) {
        return currentHarvest;
    }

    function withdraw(address receiver, uint256 amount) override external onlyManager whenNotPaused returns(uint256) {
       return _withdraw(receiver, amount);
    }

    function withdrawAllToManager() override public onlyManager whenNotPaused {
        _withdraw(manager, getBaseTokenAmountFromProtocol());
    }

    function getBaseTokenAmountFromProtocol() override public view returns(uint256) {
        uint256 lpAmount = _getLpAmount();
        (address poolAddress, , , ) = lpStaking.poolInfo(lpStakingPoolId);
        return IPoolStargate(poolAddress).amountLPtoLD(lpAmount);
    }

    function getLpAmount() external view returns (uint256) {
       return _getLpAmount();
    }

    function _harvest() internal {
        uint256 pendingStg = lpStaking.pendingStargate(lpStakingPoolId, address(this));

        if(pendingStg > stgSellThreshold) {
            lpStaking.deposit(lpStakingPoolId, 0); // call with amount = 0 will harvest pending STG tokens
            uint256 stgTotalAmount = IERC20(stgToken).balanceOf(address(this));
            emit Harvested(lpToken, stgTotalAmount);
            _swapStg(stgTotalAmount);
        }
    }

    function _swapStg(uint256 stgTotalAmount) internal {
        if(stgTotalAmount > stgSellThreshold) {
            IERC20(stgToken).approve(address(dex), stgTotalAmount);
            // we need to check tokens before swap and use only those that were swapped - there could have been some tokens deposited in the _deposit(..)
            // and we don't want to touch them during harvest (it would cause an error)
            uint256 baseTokensBeforeSwap = IERC20(baseToken).balanceOf(address(this));
            dex.swapTokens(stgTotalAmount, swapPath, address(this));
            uint256 swappedBaseTokens = IERC20(baseToken).balanceOf(address(this)) - baseTokensBeforeSwap;
            emit StgSwapped(stgTotalAmount, swappedBaseTokens);
            currentHarvest += swappedBaseTokens;
        }
    }

    function _deposit(uint256 amountToken) internal {
        // deposit base tokens and receive lpTokens
        IERC20(baseToken).approve(address(stargateRouter), amountToken);
        stargateRouter.addLiquidity(routerPoolId, amountToken, address(this));
        // add lpToken to pool to earn STG rewards
        uint256 receivedLpToken = IERC20(lpToken).balanceOf(address(this));
        IERC20(lpToken).safeApprove(address(lpStaking), receivedLpToken);
        lpStaking.deposit(lpStakingPoolId, receivedLpToken);
        emit DepositSummary(routerPoolId, lpStakingPoolId, amountToken, receivedLpToken);

        _swapStg(IERC20(stgToken).balanceOf(address(this))); // STG is harvested by Stargate contracts each time deposit/withdraw on LpStaking is called
    }

    function _withdraw(address receiver, uint256 amount) internal returns(uint256) {
        uint256 baseTokenAtStart = IERC20(baseToken).balanceOf(address(this));
        uint256 totalLpTokens = _getLpAmount();

        // calculate share of LP tokens to be withdrawn for given amount
        uint256 userShareLpToken = totalLpTokens * amount / getBaseTokenAmountFromProtocol();

        lpStaking.withdraw(lpStakingPoolId, userShareLpToken);

        // withdraw baseTokens from router
        stargateRouter.instantRedeemLocal(routerPoolId, userShareLpToken, address(this));
        uint256 baseTokenAfterWithdrawal = IERC20(baseToken).balanceOf(address(this));
        uint256 userShareBaseToken = baseTokenAfterWithdrawal - baseTokenAtStart;
        emit WithdrawSummary(routerPoolId, lpStakingPoolId, userShareBaseToken, userShareLpToken);

        _swapStg(IERC20(stgToken).balanceOf(address(this))); // STG is harvested by Stargate contracts each time deposit/withdraw on LpStaking is called

        // send tokens back to user
        IERC20(baseToken).safeTransfer(receiver, userShareBaseToken);
        emit TransferBackFunds(receiver, userShareBaseToken);
        return userShareBaseToken;
    }

    function _getLpAmount() internal view returns (uint256) {
       (uint256 amount, ) = lpStaking.userInfo(lpStakingPoolId, address(this));
       return amount;
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
pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;


interface IStargateRouter {

    /**
     * adds liquidity to router pool and get LP tokens in return  
     */
    function addLiquidity(uint256 poolId, uint256 amount, address to) external;

    /**
     * exit pool by using your LP tokens to withdraw yur liquidity
     */
    function instantRedeemLocal(uint16 poolId, uint256 amountLp, address to) external returns (uint256);
}

pragma solidity ^0.8.0;

interface ILpStaking {

    /**
     * returns amount of claimable STG tokens
     */
    function pendingStargate(uint256 pid, address user) external view returns (uint256);

    /**
     * deposit Lp tokens to earn STG
     * if called with amount == 0 is effectively acts as claim for STG  
     */
    function deposit(uint256 pid, uint256 amount) external;

    /**
     * withdraw Lp tokens and claim STG
     */
    function withdraw(uint256 pid, uint256 amount) external;

    /**
     * return: amount uint256, rewardDebt uint256
     */ 
    function userInfo(uint256 pid, address user) external view returns (uint256, uint256); 

    /**
     * return: lpToken address, allocPoint uint256, lastRewardBlock uint256, accStargatePerShare uint256
     */    
    function poolInfo(uint256 poolId) external view returns(address,  uint256, uint256, uint256);

}

pragma solidity ^0.8.0;

interface IPool {
    /**
     * Calculates amount of base token (LD in Stargate naming; token which was deposited) from user Lp tokens
     */
    function amountLPtoLD(uint256 _amountLP) external view returns (uint256);
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "../interface/IYieldModule.sol";
import "../../common/library/Modifier.sol";


abstract contract BaseModule is IYieldModule, Pausable, Ownable, Modifier {
    using SafeERC20 for IERC20;

    uint256 constant UINT_MAX = type(uint256).max;

    address public manager;
    address baseToken;

    modifier onlyManager() {
        require(manager != address(0), "BaseModule: manager not initialized");
        require(msg.sender == manager, "BaseModule: only manager");
        _;
    }

    modifier onlyOwnerOrManger() {
        require(owner() != address(0), "BaseModule: owner not initialized");
        require(manager != address(0), "BaseModule: manager not initialized");
        require(msg.sender == owner() || msg.sender == manager, "BaseModule: only manager or owner");
        _;
    }

    constructor() {
        _pause();
    }

    function setManager(address _manager) override external onlyOwner onlyNotZeroAddress(_manager) whenPaused {
        require(getBaseTokenAmountFromProtocol() == 0, "BaseModule: can only set manager when module is empty");
        manager = _manager; 
        IERC20(baseToken).safeApprove(manager, UINT_MAX); // manager need full access to funds       
    }

    function pause() override external onlyManager { 
        _pause();
    }

    function unpause() override external onlyManager {
        _unpause();
    }

    function isPaused() external view returns(bool) {
        return paused();
    }

    function withdrawAllToManager() virtual override public onlyOwnerOrManger whenNotPaused {
        require(false, "BaseModule: must implement");
    }

    function getBaseTokenAmountFromProtocol() virtual override public view returns(uint256) {
        require(false, "BaseModule: getBaseTokenAmountFromProtocol: must implement");
        return 0;
    }

    function panic() override external onlyOwnerOrManger {
        withdrawAllToManager();    
    }

    function baseTokenAddress() override external view returns(address) {
        return baseToken;
    }
}

pragma solidity ^0.8.0;

/**
 * Interface which is a face for Dex handlers implementations. On each chain we might use different
 * dex to swap tokens so we need to abstract generic interface.
 */

interface IDex {

    function swapTokens(uint amountIn, address[] calldata path, address to) external returns (uint[] memory amounts);
    function swapBorrowToSupplyTokens(uint amountIn, address to) external returns (uint[] memory amounts);
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

pragma solidity ^0.8.0;

import "../../common/interface/IDex.sol";
import "../interface/IYieldModule.sol";

interface IYieldModule {

    function deposit(uint256 amountToken) external;
    function withdraw(address receiver, uint256 amount) external returns(uint256);
    function withdrawAllToManager() external;
    function setManager(address _core) external;
    function baseTokenAddress() external returns(address);
    function harvestAndWithdraw(address receiver) external returns(uint256);
    function manager() external returns (address);
    function dex() external returns (IDex);
    function harvest() external;
    function getCurrentHarvest() external view returns(uint256);

    /**
     * Amount of base token (eg.: USDT) that module has in the underlying protocol
     */
    function getBaseTokenAmountFromProtocol() external view returns(uint256); 

    function pause() external;
    function unpause() external;
    function isPaused() external view returns(bool);
    function panic() external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

contract Modifier {
    modifier onlyNotZeroAddress(address _address) {
        require(_address != address(0), "invalid address");
        _;
    }

    modifier onlyStrictlyPositiveAmount(uint256 amount) {
        require(amount > uint256(0), "amount < 0");
        _;
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
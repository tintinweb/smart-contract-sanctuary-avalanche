// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "SafeERC20.sol";
import "IERC20Metadata.sol";
import "Initializable.sol";
import "OwnableUpgradeable.sol";
import "ERC20Upgradeable.sol";
import "IDelegateVotePool.sol";
import "ILockerV2.sol";
import "IWavax.sol";
import "ISwapHelper.sol";
import "IBribeManager.sol";
import "IBaseRewardPoolLocker.sol";

/// @title A contract for managing rewards for lockers
/// @author Vector Team
contract LVTXAutoCompound is Initializable, ERC20Upgradeable, OwnableUpgradeable {
    using SafeERC20 for IERC20;

    ILockerV2 public LVTX;
    IDelegateVotePool public delegatedPool;
    ISwapHelper public swapHelper;
    IBribeManager public bribeManager;
    IERC20 public vtx;

    address public constant WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address public protocolFeeRecipient;

    uint256 public protocolFee;
    uint256 public callerFee;
    uint256 public constant DENOMINATOR = 10000;
    uint256 public MAX_TOKEN_TO_REINVEST;
    uint256 lastCompoundTime;

    mapping(address => bool) public transferWhitelist;

    address[] public rewardTokens;

    mapping(address => bool) public isRewardToken;

    mapping(address => uint256) public initialDeposits;

    event Compounded(address indexed caller, uint256 vtxCompounded);
    event Deposited(address indexed user, uint256 amount, bool isVtx);
    event Withdrawal(address indexed user, uint256 amount);

    function __LVTXAutoCompound_init_(
        address locker,
        address _delegatedPool,
        address _swapHelper,
        address _bribeManager,
        address _vtx
    ) external initializer {
        __ERC20_init("Compounding Locked VTX", "CLVTX");
        __Ownable_init();
        LVTX = ILockerV2(locker);
        delegatedPool = IDelegateVotePool(_delegatedPool);
        swapHelper = ISwapHelper(_swapHelper);
        bribeManager = IBribeManager(_bribeManager);
        vtx = IERC20(_vtx);
    }

    receive() external payable {}

    function setMaxTokenToReinvest(uint256 value) external onlyOwner {
        MAX_TOKEN_TO_REINVEST = value;
    }

    function addRewardToken(address rewardToken) external onlyOwner {
        require(
            rewardToken != address(0) &&
                rewardToken != address(vtx) &&
                rewardToken != WAVAX &&
                !isRewardToken[rewardToken],
            "Bad input"
        );
        isRewardToken[rewardToken] = true;
        rewardTokens.push(rewardToken);
    }

    function setWhitelistForTransfer(address _for, bool status) external onlyOwner {
        transferWhitelist[_for] = status;
    }

    function setCallerFee(uint256 newValue) external onlyOwner {
        callerFee = newValue;
    }

    function setProtocolFee(uint256 newValue) external onlyOwner {
        protocolFee = newValue;
    }

    function setFeeCollector(address _collector) external onlyOwner {
        protocolFeeRecipient = _collector;
    }

    function setSwapHelper(address _swapHelper) external onlyOwner {
        swapHelper = ISwapHelper(_swapHelper);
    }

    function getRewardLength() external view returns (uint256 length) {
        length = rewardTokens.length;
    }

    /**
     * @notice Calculate shares amount for a given amount of depositToken
     * @param amount deposit token amount
     * @return number of shares
     */
    function getSharesForDepositTokens(uint256 amount) public view returns (uint256) {
        uint256 totalDepositToken = getTotalDepositToken();

        if (totalSupply() * totalDepositToken == 0) {
            return amount;
        }
        return (amount * totalSupply()) / totalDepositToken;
    }

    /**
     * @notice Calculate deposit tokens for a given amount of receipt tokens
     * @param amount receipt tokens
     * @return deposit tokens
     */
    function getDepositTokensForShares(uint256 amount) public view returns (uint256) {
        uint256 totalDepositToken = getTotalDepositToken();

        if (totalSupply() * totalDepositToken == 0) {
            return 0;
        }
        return (amount * totalDepositToken) / totalSupply();
    }

    function getTotalDepositToken() public view returns (uint256 totalDepositToken) {
        totalDepositToken = delegatedPool.balanceOf(address(this));
    }

    function userDepositToken(address user) external view returns (uint256 userDeposit) {
        userDeposit = getDepositTokensForShares(balanceOf(user));
    }

    function previewRewardsForHarvest()
        external
        view
        returns (uint256 avaxAmount, uint256 vtxAmount)
    {
        (
            address[] memory rewardTokensList,
            uint256[] memory earnedRewards
        ) = pendingTokensToHarvest();
        avaxAmount = swapHelper.previewTotalAmountToAvax(rewardTokensList, earnedRewards);
        vtxAmount = IBaseRewardPoolLocker(LVTX.rewarder()).earned(address(this), address(vtx));
    }

    //@dev does not include VTX
    function pendingTokensToHarvest()
        public
        view
        returns (address[] memory tokens, uint256[] memory amounts)
    {
        uint256 length = rewardTokens.length + 1;
        tokens = new address[](length);
        amounts = new uint256[](length);
        IBaseRewardPoolLocker rewarder = IBaseRewardPoolLocker(LVTX.rewarder());
        for (uint256 i; i < length; i++) {
            address token;
            if (i == length - 1) {
                token = WAVAX;
            } else {
                token = rewardTokens[i];
            }
            tokens[i] = token;
            amounts[i] =
                delegatedPool.earned(address(this), token) +
                rewarder.earned(address(this), token);
        }
    }

    function depositVTX(uint256 amount) external {
        vtx.safeTransferFrom(msg.sender, address(this), amount);
        _lock(amount);
        _deposit(msg.sender, amount);
        emit Deposited(msg.sender, amount, true);
    }

    function deposit(uint256 amount) external {
        IERC20(address(LVTX)).safeTransferFrom(msg.sender, address(this), amount);
        _deposit(msg.sender, amount);
        emit Deposited(msg.sender, amount, false);
    }

    function _deposit(address user, uint256 amount) internal {
        IBaseRewardPoolLocker rewarder = IBaseRewardPoolLocker(LVTX.rewarder());
        if (
            MAX_TOKEN_TO_REINVEST > 0 &&
            rewarder.earned(address(this), address(vtx)) > MAX_TOKEN_TO_REINVEST
        ) {
            compound();
        }
        uint256 newShares = getSharesForDepositTokens(amount);
        _stakeInDelegatedPool(amount);
        initialDeposits[user] += amount;
        _mint(user, newShares);
    }

    function withdraw(uint256 amount) external {
        uint256 neededShares = getSharesForDepositTokens(amount);
        require(balanceOf(msg.sender) >= neededShares, "Not enough shares");
        _burn(msg.sender, neededShares);
        _unstakeFromDelegatedPool(amount);
        IERC20(address(LVTX)).safeTransfer(msg.sender, amount);
        initialDeposits[msg.sender] -=
            (initialDeposits[msg.sender] * neededShares) /
            balanceOf(msg.sender);
        emit Withdrawal(msg.sender, amount);
    }

    function _harvest() internal {
        delegatedPool.harvestAndGetRewards();
        LVTX.claim();
    }

    function _sellRewards() internal {
        uint256 length = rewardTokens.length;
        uint256[] memory amounts = new uint256[](length);
        for (uint256 i; i < length; i++) {
            amounts[i] = IERC20(rewardTokens[i]).balanceOf(address(this));
            _approveTokenIfNeeded(rewardTokens[i], address(swapHelper), amounts[i]);
        }
        swapHelper.safeSwapTokensForWAVAX(rewardTokens, amounts, address(this), 0);
    }

    function _buyVtx() internal {
        uint256 wavaxBalance = IERC20(WAVAX).balanceOf(address(this));
        _approveTokenIfNeeded(WAVAX, address(swapHelper), wavaxBalance);
        address[] memory tokens = new address[](1);
        tokens[0] = WAVAX;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = wavaxBalance;
        swapHelper.safeSwapTokensForVTX(tokens, amounts, address(this), 0);
    }

    function _lock(uint256 _amount) internal {
        _approveTokenIfNeeded(address(vtx), address(LVTX), _amount);
        LVTX.deposit(_amount);
    }

    function _applyFees() internal {
        uint256 wavaxBalance = IERC20(WAVAX).balanceOf(address(this));
        uint256 callerAvaxAmount = (wavaxBalance * callerFee) / DENOMINATOR;
        uint256 protocolAvaxAmount = (wavaxBalance * protocolFee) / DENOMINATOR;
        _approveTokenIfNeeded(WAVAX, address(swapHelper), callerAvaxAmount);
        swapHelper.safeSwapTokenForAvax(WAVAX, callerAvaxAmount, msg.sender, 0);
        IERC20(WAVAX).safeTransfer(protocolFeeRecipient, protocolAvaxAmount);
        uint256 vtxBalance = vtx.balanceOf(address(this));
        uint256 callerVTXAmount = (vtxBalance * callerFee) / DENOMINATOR;
        uint256 protocolVTXAmount = (vtxBalance * protocolFee) / DENOMINATOR;
        IERC20(address(vtx)).safeTransfer(msg.sender, callerVTXAmount);
        IERC20(address(vtx)).safeTransfer(protocolFeeRecipient, protocolVTXAmount);
    }

    function compound() public {
        require(block.timestamp > lastCompoundTime + 60, "Already Compounded");
        lastCompoundTime = block.timestamp;
        _harvest();
        _sellRewards();
        _applyFees();
        _buyVtx();
        uint256 vtxBalance = vtx.balanceOf(address(this));
        _lock(vtxBalance);
        _stakeInDelegatedPool(vtxBalance);
        emit Compounded(msg.sender, vtxBalance);
    }

    function _stakeInDelegatedPool(uint256 amount) internal {
        address[] memory lps = new address[](1);
        int256[] memory amounts = new int256[](1);
        lps[0] = address(delegatedPool);
        amounts[0] = int256(amount);
        bribeManager.vote(lps, amounts);
    }

    function _unstakeFromDelegatedPool(uint256 amount) internal {
        address[] memory lps = new address[](1);
        int256[] memory amounts = new int256[](1);
        lps[0] = address(delegatedPool);
        amounts[0] = -int256(amount);
        bribeManager.vote(lps, amounts);
    }

    /// @notice increase allowance to a contract to the maximum amount for a specific token if it is needed
    /// @param token the token to increase the allowance of
    /// @param _to the contract to increase the allowance
    /// @param _amount the amount of allowance that the contract needs
    function _approveTokenIfNeeded(
        address token,
        address _to,
        uint256 _amount
    ) private {
        if (IERC20(token).allowance(address(this), _to) < _amount) {
            IERC20(token).approve(_to, type(uint256).max);
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (!(from == address(0) || to == address(0))) {
            require(transferWhitelist[from] || transferWhitelist[to], "Not whitelisted");
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address sender,
        address recipient,
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "ContextUpgradeable.sol";
import "Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "Initializable.sol";

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
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "IERC20Upgradeable.sol";
import "IERC20MetadataUpgradeable.sol";
import "ContextUpgradeable.sol";
import "Initializable.sol";

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
        __Context_init_unchained();
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address sender,
        address recipient,
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "IERC20Upgradeable.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IDelegateVotePool {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event RewardAdded(uint256 reward, address indexed token);
    event RewardPaid(address indexed user, uint256 reward, address indexed token);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    function DENOMINATOR() external view returns (uint256);

    function __DelegateVotePool_init_(address _bribeManager) external;

    function balanceOf(address _account) external view returns (uint256);

    function bribeManager() external view returns (address);

    function castVotes() external;

    function claimManually() external;

    function deletePool(address lp) external;

    function donateRewards(uint256 _amountReward, address _rewardToken) external;

    function earned(address _account, address _rewardToken) external view returns (uint256);

    function feeCollector() external view returns (address);

    function getPendingRewards(address user)
        external
        view
        returns (address[] memory rewardTokensList, uint256[] memory earnedRewards);

    function getPoolsLength() external view returns (uint256 length);

    function getReward(address _for)
        external
        returns (address[] memory rewardTokensList, uint256[] memory earnedRewards);

    function getRewardLength() external view returns (uint256);

    function getRewardUser()
        external
        returns (address[] memory rewardTokensList, uint256[] memory earnedRewards);

    function getStakingDecimals() external view returns (uint256);

    function harvestAndGetRewards() external;

    function isRewardToken(address) external view returns (bool);

    function isVoter(address) external view returns (bool);

    function isvotePool(address) external view returns (bool);

    function owner() external view returns (address);

    function protocolFee() external view returns (uint256);

    function queueNewRewards(uint256 _amountReward, address _rewardToken) external;

    function renounceOwnership() external;

    function rewardPerToken(address _rewardToken) external view returns (uint256);

    function rewardTokens(uint256) external view returns (address);

    function rewards(address)
        external
        view
        returns (
            address rewardToken,
            uint256 rewardPerTokenStored,
            uint256 queuedRewards,
            uint256 historicalRewards
        );

    function setProtocolFee(uint256 fee) external;

    function setProtocolFeeCollector(address collector) external;

    function setVoterStatus(address voter, bool _isVoter) external;

    function setVotingLock(uint256 _startTime, uint256 _totalTime) external;

    function stakeFor(address _for, uint256 _amount) external returns (bool);

    function startTime() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function totalWeight() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function unlockTime() external view returns (uint256);

    function updateFor(address _account) external;

    function updateWeight(address lp, uint256 weight) external;

    function userRewardPerTokenPaid(address, address) external view returns (uint256);

    function userRewards(address, address) external view returns (uint256);

    function votePools(uint256) external view returns (address);

    function votingWeights(address) external view returns (uint256);

    function withdrawFor(
        address _for,
        uint256 _amount,
        bool _claim
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface ILockerV2 {
    struct UserUnlocking {
        uint256 startTime;
        uint256 endTime;
        uint256 amount;
        uint256 unlockingStrategy;
        uint256 alreadyUnstaked;
        uint256 alreadyWithdrawn;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Claim(address indexed user, uint256 indexed timestamp);
    event NewDeposit(address indexed user, uint256 indexed timestamp, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Paused(address account);
    event ResetSlot(
        address indexed user,
        uint256 indexed timestamp,
        uint256 amount,
        uint256 slotIndex
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Unlock(address indexed user, uint256 indexed timestamp, uint256 amount);
    event UnlockStarts(
        address indexed user,
        uint256 indexed timestamp,
        uint256 amount,
        uint256 strategyIndex
    );
    event Unpaused(address account);

    function DENOMINATOR() external view returns (uint256);

    function VTX() external view returns (address);

    function __LockerV2_init_(
        address _masterchief,
        uint256 _maxSlots,
        address _previousLocker,
        address _rewarder,
        address _stakingToken
    ) external;

    function addNewStrategy(
        uint256 _lockTime,
        uint256 _rewardPercent,
        uint256 _forfeitPercent,
        uint256 _instantUnstakePercent,
        bool _isLinear
    ) external;

    function addToUnlock(uint256 amount, uint256 slotIndex) external;

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function bribeManager() external view returns (address);

    function cancelUnlock(uint256 slotIndex) external;

    function claim()
        external
        returns (address[] memory rewardTokens, uint256[] memory earnedRewards);

    function claimFor(address _for)
        external
        returns (address[] memory rewardTokens, uint256[] memory earnedRewards);

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    function deposit(uint256 _amount) external;

    function depositFor(address _for, uint256 _amount) external;

    function getAllUserUnlocking(address _user)
        external
        view
        returns (UserUnlocking[] memory slots);

    function getUserNthSlot(address _user, uint256 n)
        external
        view
        returns (
            uint256 startTime,
            uint256 endTime,
            uint256 amount,
            uint256 unlockingStrategy,
            uint256 alreadyUnstaked,
            uint256 alreadyWithdrawn
        );

    function getUserRewardPercentage(address _user)
        external
        view
        returns (uint256 rewardPercentage);

    function getUserSlotLength(address _user) external view returns (uint256);

    function getUserTotalDeposit(address _user) external view returns (uint256);

    function harvest() external;

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function masterchief() external view returns (address);

    function maxSlot() external view returns (uint256);

    function migrate(address user, bool[] calldata onlyDeposit) external;

    function migrateFor(
        address _from,
        address _to,
        bool[] calldata onlyDeposit
    ) external;

    function migrated(address) external view returns (bool);

    function name() external view returns (string memory);

    function owner() external view returns (address);

    function pause() external;

    function paused() external view returns (bool);

    function previousLocker() external view returns (address);

    function renounceOwnership() external;

    function rewarder() external view returns (address);

    function setBribeManager(address _address) external;

    function setMaxSlots(uint256 _maxDeposits) external;

    function setPreviousLocker(address _locker) external;

    function setStrategyStatus(uint256 strategyIndex, bool status) external;

    function setWhitelistForTransfer(address _for, bool status) external;

    function stakeInMasterChief() external;

    function stakingToken() external view returns (address);

    function startUnlock(
        uint256 strategyIndex,
        uint256 amount,
        uint256 slotIndex
    ) external;

    function symbol() external view returns (string memory);

    function totalLocked() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function totalUnlocking() external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferOwnership(address newOwner) external;

    function transferWhitelist(address) external view returns (bool);

    function unlock(uint256 slotIndex) external;

    function unlockingStrategies(uint256)
        external
        view
        returns (
            uint256 unlockTime,
            uint256 forfeitPercent,
            uint256 rewardPercent,
            uint256 instantUnstakePercent,
            bool isLinear,
            bool isActive
        );

    function unpause() external;

    function userUnlocking(address) external view returns (uint256);

    function userUnlockings(address, uint256)
        external
        view
        returns (
            uint256 startTime,
            uint256 endTime,
            uint256 amount,
            uint256 unlockingStrategy,
            uint256 alreadyUnstaked,
            uint256 alreadyWithdrawn
        );
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IWAVAX {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface ISwapHelper {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function PNG_ROUTER() external view returns (address);

    function ROUTER() external view returns (address);

    function VTX() external view returns (address);

    function WAVAX() external view returns (address);

    function __SwapHelper_init() external;

    function avaxHelper() external view returns (address);

    function findPathFromAvax(address token) external view returns (address[] memory);

    function findPathToAvax(address token) external view returns (address[] memory);

    function getRouter(address token) external view returns (address router);

    function owner() external view returns (address);

    function previewAmountFromAvax(address token, uint256 amount) external view returns (uint256);

    function previewAmountToAvax(address token, uint256 amount)
        external
        view
        returns (uint256 avaxAmount);

    function previewTotalAmountFromAvax(address[] calldata inTokens, uint256[] calldata amounts)
        external
        view
        returns (uint256 tokenAmount);

    function previewTotalAmountToAvax(address[] calldata inTokens, uint256[] calldata amounts)
        external
        view
        returns (uint256 avaxAmount);

    function previewTotalAmountToToken(
        address[] calldata inTokens,
        uint256[] calldata amounts,
        address to
    ) external view returns (uint256 tokenAmount);

    function renounceOwnership() external;

    function routeToAvax(address) external view returns (address);

    function routeToAvaxOnPlatypus(address) external view returns (address);

    function safeSwapTokenForAvax(
        address token,
        uint256 amount,
        address receiver,
        uint256 minAmountReceived
    ) external returns (uint256 avaxAmount);

    function safeSwapTokenForWAVAX(
        address token,
        uint256 amount,
        address receiver,
        uint256 minAmountReceived
    ) external returns (uint256 avaxAmount);

    function safeSwapTokensForAvax(
        address[] calldata tokens,
        uint256[] calldata amounts,
        address receiver,
        uint256 minAmountReceived
    ) external returns (uint256 avaxAmount);

    function safeSwapTokensForToken(
        address[] calldata tokens,
        uint256[] calldata amounts,
        address token,
        address receiver,
        uint256 minAmountReceived
    ) external returns (uint256 tokenAmount);

    function safeSwapTokensForVTX(
        address[] calldata tokens,
        uint256[] calldata amounts,
        address receiver,
        uint256 minAmountReceived
    ) external returns (uint256 vtxAmount);

    function safeSwapTokensForWAVAX(
        address[] calldata tokens,
        uint256[] calldata amounts,
        address receiver,
        uint256 minAmountReceived
    ) external returns (uint256 avaxAmount);

    function setAvaxHelper(address helper) external;

    function setRouteToAvax(address asset, address route) external;

    function setRouteToAvaxOnPlatypus(address asset, address route) external;

    function setUsePng(address asset, bool use) external;

    function swapTokenForAvax(
        address token,
        uint256 amount,
        address receiver,
        uint256 minAmountReceived
    ) external returns (uint256 avaxAmount);

    function swapTokenForWAVAX(
        address token,
        uint256 amount,
        address receiver,
        uint256 minAmountReceived
    ) external returns (uint256 avaxAmount);

    function swapTokensForAvax(
        address[] calldata tokens,
        uint256[] calldata amounts,
        address receiver,
        uint256 minAmountReceived
    ) external returns (uint256 avaxAmount);

    function swapTokensForToken(
        address[] calldata tokens,
        uint256[] calldata amounts,
        address token,
        address receiver,
        uint256 minAmountReceived
    ) external returns (uint256 tokenAmount);

    function swapTokensForVTX(
        address[] calldata tokens,
        uint256[] calldata amounts,
        address receiver,
        uint256 minAmountReceived
    ) external returns (uint256 vtxAmount);

    function swapTokensForWAVAX(
        address[] calldata tokens,
        uint256[] calldata amounts,
        address receiver,
        uint256 minAmountReceived
    ) external returns (uint256 avaxAmount);

    function sweep(address[] calldata tokens) external;

    function transferOwnership(address newOwner) external;

    function usePng(address) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IBribeManager {
    event AddPool(address indexed lp, address indexed rewarder);
    event AllVoteReset();
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event VoteReset(address indexed lp);

    function addPool(
        address _lp,
        address _rewarder,
        string calldata _name
    ) external;

    function avaxZapper() external view returns (address);

    function castVotes(bool swapForAvax)
        external
        returns (address[] memory finalRewardTokens, uint256[] memory finalFeeAmounts);

    function castVotesAndHarvestBribes(address[] calldata lps, bool swapForAvax) external;

    function castVotesCooldown() external view returns (uint256);

    function clearPools() external;

    function deactivatePool(address lp) external;

    function delegatedPool() external view returns (address);

    function getLvtxVoteForPools(address[] calldata lps)
        external
        view
        returns (uint256[] memory lvtxVotes);

    function getPoolsLength() external view returns (uint256);

    function getUserLocked(address _user) external view returns (uint256);

    function getUserVoteForPools(address[] calldata lps, address _user)
        external
        view
        returns (uint256[] memory votes);

    function getVoteForLp(address lp) external view returns (uint256);

    function getVoteForLps(address[] calldata lps) external view returns (uint256[] memory votes);

    function harvestAllBribes(address _for)
        external
        returns (address[] memory rewardTokens, uint256[] memory earnedRewards);

    function harvestBribe(address[] calldata lps) external;

    function harvestBribeFor(address[] calldata lps, address _for) external;

    function harvestSinglePool(address[] calldata _lps) external;

    function isPoolActive(address pool) external view returns (bool);

    function lastCastTimer() external view returns (uint256);

    function locker() external view returns (address);

    function lpTokenLength() external view returns (uint256);

    function mainStaking() external view returns (address);

    function owner() external view returns (address);

    function poolInfos(address)
        external
        view
        returns (
            address poolAddress,
            address rewarder,
            bool isActive,
            string memory name
        );

    function poolTotalVote(address) external view returns (uint256);

    function pools(uint256) external view returns (address);

    function previewAvaxAmountForHarvest(address[] calldata _lps) external view returns (uint256);

    function previewBribes(
        address lp,
        address[] calldata inputRewardTokens,
        address _for
    ) external view returns (address[] memory rewardTokens, uint256[] memory amounts);

    function remainingVotes() external view returns (uint256);

    function removePool(uint256 _index) external;

    function renounceOwnership() external;

    function routePairAddresses(address) external view returns (address);

    function setAvaxZapper(address newZapper) external;

    function setDelegatedPool(address _pool) external;

    function setVoter(address _voter) external;

    function totalVotes() external view returns (uint256);

    function totalVtxInVote() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function unvote(address _lp) external;

    function usedVote() external view returns (uint256);

    function userTotalVote(address) external view returns (uint256);

    function userVoteForPools(address, address) external view returns (uint256);

    function vePtp() external view returns (address);

    function veptpPerLockedVtx() external view returns (uint256);

    function vote(address[] calldata _lps, int256[] calldata _deltas) external;

    function voteAndCast(
        address[] calldata _lps,
        int256[] calldata _deltas,
        bool swapForAvax
    ) external returns (address[] memory finalRewardTokens, uint256[] memory finalFeeAmounts);

    function voter() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IBaseRewardPoolLocker {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event RewardAdded(uint256 reward, address indexed token);
    event RewardPaid(address indexed user, uint256 reward, address indexed token);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    function DENOMINATOR() external view returns (uint256);

    function __BaseRewardPoolLocker_init_(
        address _stakingToken,
        address _rewardToken,
        address _operator,
        address _rewardManager
    ) external;

    function balanceOf(address _account) external view returns (uint256);

    function donateRewards(uint256 _amountReward, address _rewardToken) external returns (bool);

    function earned(address _account, address _rewardToken) external view returns (uint256);

    function getReward(address _account, uint256 rewardPercent)
        external
        returns (address[] memory rewardTokensList, uint256[] memory earnedRewards);

    function getStakingToken() external view returns (address);

    function isRewardToken(address) external view returns (bool);

    function mainRewardToken() external view returns (address);

    function operator() external view returns (address);

    function owner() external view returns (address);

    function queueNewRewards(uint256 _amountReward, address _rewardToken) external returns (bool);

    function renounceOwnership() external;

    function rewardDecimals(address _rewardToken) external view returns (uint256);

    function rewardManager() external view returns (address);

    function rewardPerToken(address _rewardToken) external view returns (uint256);

    function rewardTokens(uint256) external view returns (address);

    function rewards(address)
        external
        view
        returns (
            address rewardToken,
            uint256 rewardPerTokenStored,
            uint256 queuedRewards,
            uint256 historicalRewards
        );

    function setOperator(address newOperator) external;

    function setRewardManager(address newOperator) external;

    function stakeFor(address _for, uint256 _amount) external returns (bool);

    function stakingDecimals() external view returns (uint256);

    function stakingToken() external view returns (address);

    function totalSupply() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function updateFor(address _account) external;

    function userRewardPerTokenPaid(address, address) external view returns (uint256);

    function userRewards(address, address) external view returns (uint256);

    function withdrawFor(
        address _for,
        uint256 _amount,
        uint256 rewardPercent,
        bool claim
    ) external returns (bool);
}
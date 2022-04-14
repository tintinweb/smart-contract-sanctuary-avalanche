// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "IERC20.sol";
import "SafeERC20.sol";
import {ReentrancyGuard} from "ReentrancyGuard.sol";
import "Address.sol";

import "IRewardTracker.sol";
import "IVester.sol";
import "IMintable.sol";
import "IWETH.sol";
import "Governable.sol";

contract RewardRouter is ReentrancyGuard, Governable {
    using SafeERC20 for IERC20;
    using Address for address payable;

    address public immutable weth;

    address public immutable token;
    address public immutable esToken;
    address public immutable veToken;

    address public immutable stakedTokenTracker;
    address public immutable veTokenTracker;
    address public immutable feeSharingTracker;

    address public immutable tokenVester;

    mapping(address => address) public pendingReceivers;

    event StakeToken(address account, address token, uint256 amount);
    event UnstakeToken(address account, address token, uint256 amount);

    receive() external payable {
        require(msg.sender == weth, "Router: invalid sender");
    }

    constructor(
        address _weth,
        address _token,
        address _esToken,
        address _veToken,
        address _stakedTokenTracker,
        address _veTokenTracker,
        address _feeSharingTracker,
        address _tokenVester
    ) {
        weth = _weth;

        token = _token;
        esToken = _esToken;
        veToken = _veToken;

        stakedTokenTracker = _stakedTokenTracker;
        veTokenTracker = _veTokenTracker;
        feeSharingTracker = _feeSharingTracker;

        tokenVester = _tokenVester;
    }

    // to help users who accidentally send their tokens to this contract
    function withdrawToken(
        address _token,
        address _account,
        uint256 _amount
    ) external onlyGov {
        IERC20(_token).safeTransfer(_account, _amount);
    }

    function batchStakeTokenForAccount(address[] memory _accounts, uint256[] memory _amounts)
        external
        nonReentrant
        onlyGov
    {
        address _token = token;
        for (uint256 i = 0; i < _accounts.length; i++) {
            _stakeToken(msg.sender, _accounts[i], _token, _amounts[i]);
        }
    }

    function stakeTokenForAccount(address _account, uint256 _amount) external nonReentrant onlyGov {
        _stakeToken(msg.sender, _account, token, _amount);
    }

    function stakeToken(uint256 _amount) external nonReentrant {
        _stakeToken(msg.sender, msg.sender, token, _amount);
    }

    function stakeEsToken(uint256 _amount) external nonReentrant {
        _stakeToken(msg.sender, msg.sender, esToken, _amount);
    }

    function unstakeToken(uint256 _amount) external nonReentrant {
        _unstakeToken(msg.sender, token, _amount, true);
    }

    function unstakeEsToken(uint256 _amount) external nonReentrant {
        _unstakeToken(msg.sender, esToken, _amount, true);
    }

    function claim() external nonReentrant {
        address account = msg.sender;

        IRewardTracker(feeSharingTracker).claimForAccount(account, account);
        IRewardTracker(stakedTokenTracker).claimForAccount(account, account);
    }

    function claimEsToken() external nonReentrant {
        address account = msg.sender;

        IRewardTracker(stakedTokenTracker).claimForAccount(account, account);
    }

    function claimFees() external nonReentrant {
        address account = msg.sender;

        IRewardTracker(feeSharingTracker).claimForAccount(account, account);
    }

    function compound() external nonReentrant {
        _compound(msg.sender);
    }

    function compoundForAccount(address _account) external nonReentrant onlyGov {
        _compound(_account);
    }

    function handleRewards(
        bool _shouldClaimToken,
        bool _shouldStakeToken,
        bool _shouldClaimEsToken,
        bool _shouldStakeEsToken,
        bool _shouldStakeVeToken,
        bool _shouldClaimWeth,
        bool _shouldConvertWethToEth
    ) external nonReentrant {
        address account = msg.sender;

        uint256 tokenAmount = 0;
        if (_shouldClaimToken) {
            tokenAmount = IVester(tokenVester).claimForAccount(account, account);
        }

        if (_shouldStakeToken && tokenAmount > 0) {
            _stakeToken(account, account, token, tokenAmount);
        }

        uint256 esTokenAmount = 0;
        if (_shouldClaimEsToken) {
            esTokenAmount = IRewardTracker(stakedTokenTracker).claimForAccount(account, account);
        }

        if (_shouldStakeEsToken && esTokenAmount > 0) {
            _stakeToken(account, account, esToken, esTokenAmount);
        }

        if (_shouldStakeVeToken) {
            uint256 veTokenAmount = IRewardTracker(veTokenTracker).claimForAccount(account, account);
            if (veTokenAmount > 0) {
                IRewardTracker(feeSharingTracker).stakeForAccount(account, account, veToken, veTokenAmount);
            }
        }

        if (_shouldClaimWeth) {
            if (_shouldConvertWethToEth) {
                uint256 wethAmount = IRewardTracker(feeSharingTracker).claimForAccount(account, address(this));
                IWETH(weth).withdraw(wethAmount);
                payable(account).sendValue(wethAmount);
            } else {
                IRewardTracker(feeSharingTracker).claimForAccount(account, account);
            }
        }
    }

    function batchCompoundForAccounts(address[] memory _accounts) external nonReentrant onlyGov {
        for (uint256 i = 0; i < _accounts.length; i++) {
            _compound(_accounts[i]);
        }
    }

    function signalTransfer(address _receiver) external nonReentrant {
        require(IERC20(tokenVester).balanceOf(msg.sender) == 0, "RewardRouter: sender has vested tokens");

        _validateReceiver(_receiver);
        pendingReceivers[msg.sender] = _receiver;
    }

    function acceptTransfer(address _sender) external nonReentrant {
        require(IERC20(tokenVester).balanceOf(_sender) == 0, "RewardRouter: sender has vested tokens");

        address receiver = msg.sender;
        require(pendingReceivers[_sender] == receiver, "RewardRouter: transfer not signalled");
        delete pendingReceivers[_sender];

        _validateReceiver(receiver);
        _compound(_sender);

        uint256 stakedToken = IRewardTracker(stakedTokenTracker).depositBalances(_sender, token);
        if (stakedToken > 0) {
            _unstakeToken(_sender, token, stakedToken, false);
            _stakeToken(_sender, receiver, token, stakedToken);
        }

        uint256 stakedEsToken = IRewardTracker(stakedTokenTracker).depositBalances(_sender, esToken);
        if (stakedEsToken > 0) {
            _unstakeToken(_sender, esToken, stakedEsToken, false);
            _stakeToken(_sender, receiver, esToken, stakedEsToken);
        }

        uint256 stakedVeToken = IRewardTracker(feeSharingTracker).depositBalances(_sender, veToken);
        if (stakedVeToken > 0) {
            IRewardTracker(feeSharingTracker).unstakeForAccount(_sender, veToken, stakedVeToken, _sender);
            IRewardTracker(feeSharingTracker).stakeForAccount(_sender, receiver, veToken, stakedVeToken);
        }

        uint256 esTokenBalance = IERC20(esToken).balanceOf(_sender);
        if (esTokenBalance > 0) {
            IERC20(esToken).transferFrom(_sender, receiver, esTokenBalance);
        }

        IVeTokenTracker(veTokenTracker).transferCumulativeRewards(_sender, receiver);
        IVester(tokenVester).transferStakeValues(_sender, receiver);
    }

    function _validateReceiver(address _receiver) private view {
        require(
            IRewardTracker(stakedTokenTracker).averageStakedAmounts(_receiver) == 0,
            "RewardRouter: stakedTokenTracker.averageStakedAmounts > 0"
        );
        require(
            IRewardTracker(stakedTokenTracker).cumulativeRewards(_receiver) == 0,
            "RewardRouter: stakedTokenTracker.cumulativeRewards > 0"
        );

        require(
            IRewardTracker(veTokenTracker).averageStakedAmounts(_receiver) == 0,
            "RewardRouter: veTokenTracker.averageStakedAmounts > 0"
        );
        require(
            IRewardTracker(veTokenTracker).cumulativeRewards(_receiver) == 0,
            "RewardRouter: veTokenTracker.cumulativeRewards > 0"
        );

        require(
            IRewardTracker(feeSharingTracker).averageStakedAmounts(_receiver) == 0,
            "RewardRouter: feeSharingTracker.averageStakedAmounts > 0"
        );
        require(
            IRewardTracker(feeSharingTracker).cumulativeRewards(_receiver) == 0,
            "RewardRouter: feeSharingTracker.cumulativeRewards > 0"
        );

        require(
            IVester(tokenVester).transferredAverageStakedAmounts(_receiver) == 0,
            "RewardRouter: tokenVester.transferredAverageStakedAmounts > 0"
        );
        require(
            IVester(tokenVester).transferredCumulativeRewards(_receiver) == 0,
            "RewardRouter: tokenVester.transferredCumulativeRewards > 0"
        );

        require(IERC20(tokenVester).balanceOf(_receiver) == 0, "RewardRouter: tokenVester.balance > 0");
    }

    function _compound(address _account) private {
        _compoundToken(_account);
    }

    function _compoundToken(address _account) private {
        uint256 esTokenAmount = IRewardTracker(stakedTokenTracker).claimForAccount(_account, _account);
        if (esTokenAmount > 0) {
            _stakeToken(_account, _account, esToken, esTokenAmount);
        }

        uint256 veTokenAmount = IRewardTracker(veTokenTracker).claimForAccount(_account, _account);
        uint256 balanceOfVeToken = IERC20(veToken).balanceOf(_account);
        if (veTokenAmount + balanceOfVeToken > 0) {
            IRewardTracker(feeSharingTracker).stakeForAccount(
                _account,
                _account,
                veToken,
                veTokenAmount + balanceOfVeToken
            );
        }
    }

    function _stakeToken(
        address _fundingAccount,
        address _account,
        address _token,
        uint256 _amount
    ) private {
        require(_amount > 0, "RewardRouter: invalid _amount");

        IRewardTracker(stakedTokenTracker).stakeForAccount(_fundingAccount, _account, _token, _amount);
        IRewardTracker(veTokenTracker).stakeForAccount(_account, _account, stakedTokenTracker, _amount);
        IRewardTracker(feeSharingTracker).stakeForAccount(_account, _account, veTokenTracker, _amount);

        uint256 balanceOfVeToken = IERC20(veToken).balanceOf(_account);
        if (balanceOfVeToken > 0) {
            IRewardTracker(feeSharingTracker).stakeForAccount(_account, _account, veToken, balanceOfVeToken);
        }
        emit StakeToken(_account, _token, _amount);
    }

    function _unstakeToken(
        address _account,
        address _token,
        uint256 _amount,
        bool _shouldBurnVeToken
    ) private {
        require(_amount > 0, "RewardRouter: invalid _amount");

        IRewardTracker(feeSharingTracker).unstakeForAccount(_account, veTokenTracker, _amount, _account);
        IRewardTracker(veTokenTracker).unstakeForAccount(_account, stakedTokenTracker, _amount, _account);
        IRewardTracker(stakedTokenTracker).unstakeForAccount(_account, _token, _amount, _account);

        uint256 newAmount = IRewardTracker(stakedTokenTracker).depositBalances(_account, token);
        IVeTokenTracker(veTokenTracker).updatePrincipalDepositForAccount(_account, newAmount);

        if (_shouldBurnVeToken) {
            uint256 veTokenAmount = IRewardTracker(veTokenTracker).claimForAccount(_account, _account);
            if (veTokenAmount > 0) {
                IRewardTracker(feeSharingTracker).stakeForAccount(_account, _account, veToken, veTokenAmount);
            }

            uint256 stakedVeToken = IRewardTracker(feeSharingTracker).depositBalances(_account, veToken);
            if (stakedVeToken > 0) {
                uint256 balanceOfVeToken = IERC20(veToken).balanceOf(_account);
                IRewardTracker(feeSharingTracker).unstakeForAccount(_account, veToken, stakedVeToken, _account);
                IVeTokenTracker(veTokenTracker).burnVeTokenForAccount(_account, stakedVeToken + balanceOfVeToken);
            }
        }

        emit UnstakeToken(_account, _token, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

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

pragma solidity 0.8.10;

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
        // solhint-disable-next-line max-line-length
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
        uint256 newAllowance = token.allowance(address(this), spender) - value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

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
        // solhint-disable-next-line no-inline-assembly
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/MutativeLabs/solfege/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IVeTokenTracker {
    function depositBalances(address _account, address _depositToken) external view returns (uint256);

    function stakedAmounts(address _account) external view returns (uint256);

    function updateRewards() external;

    function stake(address _depositToken, uint256 _amount) external;

    function stakeForAccount(
        address _fundingAccount,
        address _account,
        address _depositToken,
        uint256 _amount
    ) external;

    function unstake(address _depositToken, uint256 _amount) external;

    function unstakeForAccount(
        address _account,
        address _depositToken,
        uint256 _amount,
        address _receiver
    ) external;

    function tokensPerInterval() external view returns (uint256);

    function claim(address _receiver) external returns (uint256);

    function claimForAccount(address _account, address _receiver) external returns (uint256);

    function claimable(address _account) external view returns (uint256);

    function cumulativeRewards(address _account) external view returns (uint256);

    function totalDepositSupply(address _token) external view returns (uint256);

    function burnVeTokenForAccount(address _account, uint256 _amount) external returns (uint256);

    function transferCumulativeRewards(address _account, address _receiver) external;

    function updatePrincipalDepositForAccount(address _account, uint256 _amount) external;
}

interface IRewardTracker {
    function depositBalances(address _account, address _depositToken) external view returns (uint256);

    function stakedAmounts(address _account) external view returns (uint256);

    function updateRewards() external;

    function stake(address _depositToken, uint256 _amount) external;

    function stakeForAccount(
        address _fundingAccount,
        address _account,
        address _depositToken,
        uint256 _amount
    ) external;

    function unstake(address _depositToken, uint256 _amount) external;

    function unstakeForAccount(
        address _account,
        address _depositToken,
        uint256 _amount,
        address _receiver
    ) external;

    function tokensPerInterval() external view returns (uint256);

    function claim(address _receiver) external returns (uint256);

    function claimForAccount(address _account, address _receiver) external returns (uint256);

    function claimable(address _account) external view returns (uint256);

    function averageStakedAmounts(address _account) external view returns (uint256);

    function cumulativeRewards(address _account) external view returns (uint256);

    function totalDepositSupply(address _token) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IVester {
    function rewardTracker() external view returns (address);

    function claimForAccount(address _account, address _receiver) external returns (uint256);

    function claimable(address _account) external view returns (uint256);

    function cumulativeClaimAmounts(address _account) external view returns (uint256);

    function claimedAmounts(address _account) external view returns (uint256);

    function pairAmounts(address _account) external view returns (uint256);

    function getVestedAmount(address _account) external view returns (uint256);

    function transferredAverageStakedAmounts(address _account) external view returns (uint256);

    function transferredCumulativeRewards(address _account) external view returns (uint256);

    function cumulativeRewardDeductions(address _account) external view returns (uint256);

    function bonusRewards(address _account) external view returns (uint256);

    function transferStakeValues(address _sender, address _receiver) external;

    function setTransferredAverageStakedAmounts(address _account, uint256 _amount) external;

    function setTransferredCumulativeRewards(address _account, uint256 _amount) external;

    function setCumulativeRewardDeductions(address _account, uint256 _amount) external;

    function setBonusRewards(address _account, uint256 _amount) external;

    function getMaxVestableAmount(address _account) external view returns (uint256);

    function getCombinedAverageStakedAmount(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IMintable {
    function isMinter(address _account) external returns (bool);

    function setMinter(address _minter, bool _isActive) external;

    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

contract Governable {
    address public gov;

    constructor() {
        gov = msg.sender;
    }

    modifier onlyGov() {
        require(msg.sender == gov, "Governable: forbidden");
        _;
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }
}
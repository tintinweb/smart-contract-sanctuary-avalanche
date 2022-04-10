/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

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

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }

    function sqrt(uint256 n) internal pure returns (uint256) { unchecked {
        if (n > 0) {
            uint256 x = n / 2 + 1;
            uint256 y = (x + n / x) / 2;
            while (x > y) {
                x = y;
                y = (x + n / x) / 2;
            }
            return x;
        }
        return 0;
    } }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;

        _;
        _status = _NOT_ENTERED;
    }
}

contract BoringOwnableData {
    address public owner;
    address public pendingOwner;
}

contract BoringOwnable is BoringOwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice `owner` defaults to msg.sender on construction.
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /// @notice Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
    /// Can only be invoked by the current `owner`.
    /// @param newOwner Address of the new owner.
    /// @param direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
    /// @param renounce Allows the `newOwner` to be `address(0)` if `direct` and `renounce` is True. Has no effect otherwise.
    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
            pendingOwner = address(0);
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    /// @notice Needs to be called by `pendingOwner` to claim ownership.
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    /// @notice Only allows the `owner` to execute the function.
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

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

interface IArcaneWeaver
{
    struct Weaver {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 accrued; // Reward debt. See explanation below.
    }

    struct ArcaneFarm {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocationPoints; // How many allocation points assigned to this poolInfo. SUSHI to distribute per block.
        uint256 lastRewardTime; // Last block timestamp that SUSHI distribution occurs.
        uint256 accSigilPerShare; // Accumulated SIGIL per share, times 1e18. See below.
    }

    function arcaneFarm(uint256 farmId) external view returns (ArcaneFarm memory);

    function totalAllocPoint() external view returns (uint256);

    function deposit(uint256 _farmId, uint256 _amount) external;
}

interface IArcaneDispenser
{
    function onSigilReward(address user, uint256 newLpAmount) external;

    function pendingTokens(address user) external view returns (uint256 pending);

    function rewardToken() external view returns (IERC20);
}

// This is a forked and modified version of the SimpleRewarderPerSec contract from Trader Joe's joe-core respository found here
// https://github.com/traderjoe-xyz/joe-core/blob/main/contracts/rewarders/SimpleRewarderPerSec.sol

contract BasicDispenserPerSec is IArcaneDispenser, BoringOwnable, ReentrancyGuard
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct Weaver {
        uint256 amount;
        uint256 accrued;
        uint256 unpaid;
    }

    struct ArcaneFarm {
        uint256 accTokenPerShare;
        uint256 lastRewardTime;
    }

    IERC20 public immutable override rewardToken;
    IERC20 public immutable lpToken;
    bool public immutable isNative;
    IArcaneWeaver public immutable ARCANE_WEAVER;
    uint256 public tokenPerSec;

    uint256 private constant ACC_TOKEN_PRECISION = 1e36;

    ArcaneFarm Farm;
    mapping(address => Weaver) public Weavers;

    event OnReward (address indexed weaver, uint256 amount);
    event RewardRateUpdate(uint256 oldRate, uint256 newRate);

    modifier onlyArcaneWeaver() 
    {
        require(msg.sender == address(ARCANE_WEAVER), "onlyArcaneWeaver: Only ArcaneWeaver contract can call this function");
        _;
    }

    constructor (IERC20 _rewardToken, IERC20 _lpToken, uint256 _tokenPerSec, IArcaneWeaver _ARCANE_WEAVER, bool _isNative)
    {
        require(Address.isContract(address(_rewardToken)), "constructor: reward token must be a valid contract");
        require(Address.isContract(address(_lpToken)), "constructor: LP token must be a valid contract");
        require(Address.isContract(address(_ARCANE_WEAVER)), "constructor: ArcaneWeaver must be a valid contract");
        require(_tokenPerSec <= 1e30, "constructor: token per seconds can't be greater than 1e30");

        rewardToken = _rewardToken;
        lpToken = _lpToken;
        tokenPerSec = _tokenPerSec;
        ARCANE_WEAVER = _ARCANE_WEAVER;
        isNative = _isNative;
        Farm = ArcaneFarm({lastRewardTime: block.timestamp, accTokenPerShare: 0});
    }

    receive() external payable {}

    function onSigilReward (address weaverAddress, uint lpAmount) external override onlyArcaneWeaver nonReentrant
    {
        updateFarm();
        ArcaneFarm memory farm = Farm;
        Weaver storage weaver = Weavers[weaverAddress];

        uint256 pending;

        if (weaver.amount > 0) 
        {
            pending = (weaver.amount.mul(farm.accTokenPerShare) / ACC_TOKEN_PRECISION).sub(weaver.accrued).add(
                weaver.unpaid
            );

            if (isNative) 
            {
                uint256 balance = address(this).balance;
                if (pending > balance) 
                {
                    (bool success, ) = weaverAddress.call{value:balance}("");
                    require(success, "Transfer failed");
                    weaver.unpaid = pending - balance;
                } 
                else 
                {
                    (bool success, ) = weaverAddress.call{value:pending}("");
                    require(success, "Transfer failed");
                    weaver.unpaid = 0;
                }
            } 
            else 
            {
                uint256 balance = rewardToken.balanceOf(address(this));
                if (pending > balance) 
                {
                    rewardToken.safeTransfer(weaverAddress, balance);
                    weaver.unpaid = pending - balance;
                } 
                else 
                {
                    rewardToken.safeTransfer(weaverAddress, pending);
                    weaver.unpaid = 0;
                }
            }
        }

        weaver.amount = lpAmount;
        weaver.accrued = weaver.amount.mul(farm.accTokenPerShare) / ACC_TOKEN_PRECISION;
        emit OnReward(weaverAddress, pending - weaver.unpaid); 
    }

    function pendingTokens(address weaverAddress) external view override returns (uint256 pending) 
    {
        ArcaneFarm memory farm = Farm;
        Weaver storage weaver = Weavers[weaverAddress];

        uint256 accTokenPerShare = farm.accTokenPerShare;
        uint256 lpSupply = lpToken.balanceOf(address(ARCANE_WEAVER));

        if (block.timestamp > farm.lastRewardTime && lpSupply != 0) 
        {
            uint256 timeElapsed = block.timestamp.sub(farm.lastRewardTime);
            uint256 tokenReward = timeElapsed.mul(tokenPerSec);
            accTokenPerShare = accTokenPerShare.add(tokenReward.mul(ACC_TOKEN_PRECISION).div(lpSupply));
        }

        pending = (weaver.amount.mul(accTokenPerShare) / ACC_TOKEN_PRECISION).sub(weaver.accrued).add(
            weaver.unpaid
        );
    }

    function rewardTokenBalance() external view returns (uint256) 
    {
        if (isNative) 
        {
            return address(this).balance;
        } 
        else 
        {
            return rewardToken.balanceOf(address(this));
        }
    }

    function setRewardRate(uint256 _tokenPerSec) external onlyOwner 
    {
        updateFarm();

        uint256 oldRate = tokenPerSec;
        tokenPerSec = _tokenPerSec;

        emit RewardRateUpdate(oldRate, _tokenPerSec);
    }

    function updateFarm() public returns (ArcaneFarm memory farm) 
    {
        farm = Farm;

        if (block.timestamp > farm.lastRewardTime) 
        {
            uint256 lpSupply = lpToken.balanceOf(address(ARCANE_WEAVER));

            if (lpSupply > 0) 
            {
                uint256 timeElapsed = block.timestamp.sub(farm.lastRewardTime);
                uint256 tokenReward = timeElapsed.mul(tokenPerSec);
                farm.accTokenPerShare = farm.accTokenPerShare.add((tokenReward.mul(ACC_TOKEN_PRECISION) / lpSupply));
            }

            farm.lastRewardTime = block.timestamp;
            Farm = farm;
        }
    }

    function emergencyWithdraw() public onlyOwner 
    {
        if (isNative)
        {
            (bool success, ) = msg.sender.call{value:address(this).balance}("");
            require(success, "Transfer failed");
        } 
        else 
        {
            rewardToken.safeTransfer(address(msg.sender), rewardToken.balanceOf(address(this)));
        }
    }
}
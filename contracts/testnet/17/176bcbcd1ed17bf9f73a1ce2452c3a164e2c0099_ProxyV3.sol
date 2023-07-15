/**
 *Submitted for verification at testnet.snowtrace.io on 2023-07-14
*/

// SPDX-License-Identifier: GPL-3.0-only

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

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


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

// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity 0.8.17;

contract Authorization {
    address public owner;
    address public newOwner;
    mapping(address => bool) public isPermitted;
    event Authorize(address user);
    event Deauthorize(address user);
    event StartOwnershipTransfer(address user);
    event TransferOwnership(address user);
    constructor() {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    modifier auth {
        require(isPermitted[msg.sender], "Action performed by unauthorized address.");
        _;
    }
    function transferOwnership(address newOwner_) external onlyOwner {
        newOwner = newOwner_;
        emit StartOwnershipTransfer(newOwner_);
    }
    function takeOwnership() external {
        require(msg.sender == newOwner, "Action performed by unauthorized address.");
        owner = newOwner;
        newOwner = address(0);
        emit TransferOwnership(owner);
    }
    function permit(address user) external onlyOwner {
        isPermitted[user] = true;
        emit Authorize(user);
    }
    function deny(address user) external onlyOwner {
        isPermitted[user] = false;
        emit Deauthorize(user);
    }
}
// Commissions paid by projects


pragma solidity 0.8.17;





contract ProxyV3 is Authorization {
    using SafeERC20 for IERC20;

    struct Project {
        address owner;
        address[] prjectAdmin;
        mapping(address => uint256) prjectAdminInv;
    }

    struct CommissionInTokenConfig {
        bool directTransfer;
        uint24 rate;
        uint256 capPerTransaction;
        uint256 capPerCampaign;
    }
    struct CommissionOutTokenConfig {
        uint24 rate;
        uint256 capPerTransaction;
        uint256 capPerCampaign;
    }
    struct Campaign {
        uint256 projectId;
        uint24 maxInputTokensInEachCall;
        uint24 maxOutputTokensInEachCall;
        bool referrersRequireApproval;
        uint64 startDate;
        uint64 endDate;
        bytes24[] targetAndSelectors;
        mapping(bytes24 => bool) isTargetAndSelector;
        // token == 0 for native toekn
        IERC20[] inTokens;
        IERC20[] outTokens;
        mapping(IERC20 => CommissionInTokenConfig) commissionInTokenConfig;
        mapping(IERC20 => CommissionOutTokenConfig) commissionOutTokenConfig;
        address[] referrers;
        mapping(address => uint256) referrersInv;
    }

    struct Commission {
        address to;
        uint256 amount;
    }
    struct TokensIn {
        IERC20 token; 
        uint256 amount;
    }
    struct ClaimantInfo {
        address claimant;
        IERC20 token;
        uint256 balance;
    }


    Project[] private projects;
    Campaign[] private campaigns;
    mapping(uint256 => mapping(IERC20 => uint256)) public projectBalance; // projectBalance[projectId][token] = balance
    mapping(uint256 => uint256[]) projectCampaignId; // projectCampaignId[projectId][idx] = campaignId
    mapping(uint256 => mapping(IERC20 => uint256)) public campaignAccumulatedCommission; // campaignAccumulatedCommission[campaignId][token] = commission
    mapping(uint256 => mapping(IERC20 => uint256)) public stakesBalance;
    mapping(IERC20 => uint256) public lastBalance;

    uint24 public protocolRate;
    mapping(IERC20 => uint256) public protocolFeeBalance;

    uint256 public claimantIdCount;
    mapping(uint256 => ClaimantInfo) public claimantsInfo; //claimantsInfo[id] = ClaimantInfo
    mapping(address => mapping(IERC20 => uint256)) public claimantIds; //claimantIds[address][IERC20] = id

    event SetProtocolRate(uint24 protocolRate);
    event NewProject(uint256 indexed projectId);
    event NewCampaign(uint256 indexed campaignId);
    event Stake(uint256 indexed projectId, IERC20 indexed token, uint256 amount, uint256 balance);
    event TransferForward(address indexed target, IERC20 indexed token, address sender, uint256 amount);
    event TransferBack(address indexed target, IERC20 indexed token, address sender, uint256 amount);
    event Claim(address indexed from, IERC20 indexed token, uint256 amount);
    event ClaimProtocolFee(IERC20 indexed token, uint256 amount);
    event AddCommission(address to, IERC20 token, uint256 commission, uint256 commissionBalance, uint256 protocolFee, uint256 protocolFeeBalance);
    event Skim(IERC20 indexed token, address indexed to, uint256 amount);

    constructor(uint24 _protocolRate) {
        protocolRate = _protocolRate;
        emit SetProtocolRate(_protocolRate);
    }

    function _transferAssetFrom(IERC20 token, uint256 amount) internal returns (uint256 balance) {
        balance = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), amount);
        balance = token.balanceOf(address(this)) - balance;
    }
    function _safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }

    function setProtocolRate(uint24 newRate) external {
        protocolRate = newRate;
        emit SetProtocolRate(newRate);
    }

    function newProject(address[] calldata admins) external returns (uint256 projectId) {
        projectId = projects.length;
        projects.push();
        Project storage project = projects[projectId];
        project.owner = msg.sender;
        project.prjectAdmin.push(msg.sender);
        project.prjectAdminInv[msg.sender] = 0;
        uint256 i;
        uint256 length = admins.length;
        while (i < length) {
            address admin = admins[i];
            project.prjectAdmin.push(admin);
            unchecked { i++; }
            project.prjectAdminInv[admin] = i; // owner is the first one
        }
        emit NewProject(projectId);
    }
    struct CampaignParams {
        uint256 projectId;
        uint24 maxInputTokensInEachCall;
        uint24 maxOutputTokensInEachCall;
        bool referrersRequireApproval;
        uint64 startDate;
        uint64 endDate;
        bytes24[] targetAndSelectors;
        IERC20[] inTokens;
        CommissionInTokenConfig[] commissionInTokenConfig;
        IERC20[] outTokens;
        CommissionOutTokenConfig[] commissionOutTokenConfig;
        address[] referrers;
    }
    function newCampaign(CampaignParams calldata params) external returns (uint256 campaignId) {
        require(params.projectId < projects.length, "Invalid projectId");
        Project storage project = projects[params.projectId];
        require(project.prjectAdmin[project.prjectAdminInv[msg.sender]] == msg.sender, "not a project admin");
        require(params.startDate <= params.endDate, "invalid campaign date");
        campaignId = campaigns.length;

        projectCampaignId[params.projectId].push(campaignId);

        campaigns.push();
        Campaign storage campaign = campaigns[campaignId];
        campaign.projectId = params.projectId;
        campaign.maxInputTokensInEachCall = params.maxInputTokensInEachCall;
        campaign.maxOutputTokensInEachCall = params.maxOutputTokensInEachCall;
        campaign.referrersRequireApproval = params.referrersRequireApproval;
        campaign.startDate = params.startDate;
        campaign.endDate = params.endDate;

        uint256 i;
        uint256 length = params.targetAndSelectors.length;
        campaign.targetAndSelectors = params.targetAndSelectors;
        while (i < length) {
            campaign.isTargetAndSelector[params.targetAndSelectors[i]] = true;
            unchecked { i++; }
        }

        i = 0;
        length = params.inTokens.length;
        require(length == params.commissionInTokenConfig.length, "in token config length not matched");
        campaign.inTokens = params.inTokens;
        while (i < length) {
            campaign.commissionInTokenConfig[params.inTokens[i]] = params.commissionInTokenConfig[i];
            unchecked { i++; }
        }

        i = 0;
        length = params.outTokens.length;
        require(length == params.commissionOutTokenConfig.length, "out token config length not matched");
        campaign.outTokens = params.outTokens;
        while (i < length) {
            campaign.commissionOutTokenConfig[params.outTokens[i]] = params.commissionOutTokenConfig[i];
            unchecked { i++; }
        }

        i = 0;
        length = params.referrers.length;
        require(params.referrersRequireApproval == (length!=0), "invalid referrers length");
        campaign.referrers = params.referrers;
        while (i < length) {
            campaign.referrersInv[params.referrers[i]] = i;
            unchecked { i++; }
        }
        emit NewCampaign(campaignId);
    }
    function getCampaign(uint256 campaignId, bool returnArrays) external view returns (CampaignParams memory campaign) {
        Campaign storage _campaign = campaigns[campaignId];
        campaign.projectId = _campaign.projectId;
        campaign.maxInputTokensInEachCall = _campaign.maxInputTokensInEachCall;
        campaign.maxOutputTokensInEachCall = _campaign.maxOutputTokensInEachCall;
        campaign.referrersRequireApproval = _campaign.referrersRequireApproval;
        campaign.startDate = _campaign.startDate;
        campaign.endDate = _campaign.endDate;
        if (returnArrays) {
            campaign.targetAndSelectors = _campaign.targetAndSelectors;
            uint256 i;
            uint256 length = _campaign.inTokens.length;
            campaign.inTokens = _campaign.inTokens;
            campaign.commissionInTokenConfig = new CommissionInTokenConfig[](length);
            while (i < length) {
                campaign.commissionInTokenConfig[i] = _campaign.commissionInTokenConfig[_campaign.inTokens[i]];
                unchecked { i++; }
            }
            i = 0;
            length = _campaign.outTokens.length;
            campaign.outTokens = _campaign.outTokens;
            campaign.commissionOutTokenConfig = new CommissionOutTokenConfig[](length);
            while (i < length) {
                campaign.commissionOutTokenConfig[i] = _campaign.commissionOutTokenConfig[_campaign.outTokens[i]];
                unchecked { i++; }
            }
            campaign.referrers = _campaign.referrers;
        }
    }
    function getCampaignArrayLength(uint256 campaignId) external view returns (uint256 targetAndSelectorsLength, uint256 inTokensLength, uint256 outTokensLength, uint256 referrersLength) {
        Campaign storage _campaign = campaigns[campaignId];
        targetAndSelectorsLength = _campaign.targetAndSelectors.length;
        inTokensLength = _campaign.inTokens.length;
        outTokensLength = _campaign.outTokens.length;
        referrersLength = _campaign.referrers.length;
    }
    function getCampaignArrayData1(
        uint256 campaignId, 
        uint256 targetAndSelectorsStart, uint256 targetAndSelectorsLength, 
        uint256 referrersStart, uint256 referrersLength
    ) external view returns (
        bytes24[] memory targetAndSelectors,
        address[] memory referrers
    ) {
        Campaign storage _campaign = campaigns[campaignId];
        uint256 i;

        if (targetAndSelectorsStart > _campaign.targetAndSelectors.length)
            targetAndSelectorsStart = _campaign.targetAndSelectors.length;
        if (targetAndSelectorsStart + targetAndSelectorsLength > _campaign.targetAndSelectors.length)
            targetAndSelectorsLength = _campaign.targetAndSelectors.length - targetAndSelectorsStart;
        targetAndSelectors = new bytes24[](targetAndSelectorsLength);
        while (i < targetAndSelectorsLength) {
            targetAndSelectors[i] = _campaign.targetAndSelectors[i + targetAndSelectorsStart];
            unchecked { i++; }
        }

        i = 0;
        if (referrersStart > _campaign.referrers.length)
            referrersStart = _campaign.referrers.length;
        if (referrersStart + referrersLength > _campaign.referrers.length)
            referrersLength = _campaign.referrers.length - referrersStart;
        referrers = new address[](referrersLength);
        while (i < referrersLength) {
            referrers[i] = _campaign.referrers[i + referrersStart];
            unchecked { i++; }
        }
    }
    function getCampaignArrayData2(
        uint256 campaignId, 
        uint256 inTokensStart, uint256 inTokensLength, 
        uint256 outTokensStart, uint256 outTokensLength
    ) external view returns (
        IERC20[] memory inTokens,
        CommissionInTokenConfig[] memory commissionInTokenConfig,
        IERC20[] memory outTokens,
        CommissionOutTokenConfig[] memory commissionOutTokenConfig
    ) {
        Campaign storage _campaign = campaigns[campaignId];
        uint256 i;

        if (inTokensStart > _campaign.inTokens.length)
            inTokensStart = _campaign.inTokens.length;
        if (inTokensStart + inTokensLength > _campaign.inTokens.length)
            inTokensLength = _campaign.inTokens.length - inTokensStart;
        inTokens = new IERC20[](inTokensLength);
        commissionInTokenConfig = new CommissionInTokenConfig[](inTokensLength);
        while (i < inTokensLength) {
            inTokens[i] = _campaign.inTokens[i + inTokensStart];
            commissionInTokenConfig[i] = _campaign.commissionInTokenConfig[inTokens[i]];
            unchecked { i++; }
        }

        i = 0;
        if (outTokensStart > _campaign.outTokens.length)
            outTokensStart = _campaign.outTokens.length;
        if (outTokensStart + outTokensLength > _campaign.outTokens.length)
            outTokensLength = _campaign.outTokens.length - outTokensStart;
        outTokens = new IERC20[](outTokensLength);
        commissionOutTokenConfig = new CommissionOutTokenConfig[](outTokensLength);
        while (i < outTokensLength) {
            outTokens[i] = _campaign.outTokens[i + outTokensStart];
            commissionOutTokenConfig[i] = _campaign.commissionOutTokenConfig[outTokens[i]];
            unchecked { i++; }
        }
    }
    // function setCommissionConfig(address contractAddress, bytes4 selector, CommissionConfig calldata config) external {
    //     require(msg.sender == contractOwner[contractAddress], "not from contract owner");
    //     bytes24 id = bytes24(abi.encodePacked(contractAddress, selector));
    //     commissionConfig[id] = config;
    // }
    // function setCommissionInTokenConfig(address contractAddress, bytes4 selector, IERC20 token, CommissionTokenConfig calldata config) external {
    //     require(msg.sender == contractOwner[contractAddress], "not from contract owner");
    //     bytes24 id = bytes24(abi.encodePacked(contractAddress, selector));
    //     commissionInTokenConfig[id][token] = config;
    // }
    // function setCommissionOutTokenConfig(address contractAddress, bytes4 selector, IERC20 token, CommissionTokenConfig calldata config) external {
    //     require(msg.sender == contractOwner[contractAddress], "not from contract owner");
    //     bytes24 id = bytes24(abi.encodePacked(contractAddress, selector));
    //     commissionOutTokenConfig[id][token] = config;
    // }
    // function addReferrer(address contractAddress, bytes4 selector, address referrer) external {
    //     require(msg.sender == contractOwner[contractAddress], "not from contract owner");
    //     bytes24 id = bytes24(abi.encodePacked(contractAddress, selector));
    //     validReferrer[id][referrer] = true;
    // }
    // function removeReferrer(address contractAddress, bytes4 selector, address referrer) external {
    //     require(msg.sender == contractOwner[contractAddress], "not from contract owner");
    //     bytes24 id = bytes24(abi.encodePacked(contractAddress, selector));
    //     delete validReferrer[id][referrer];
    // }

    function addToDistributions(address claimant, IERC20 token, uint256 amount) internal {
        uint256 protocolFee = amount * protocolRate / 1e6;
        protocolFeeBalance[token] += protocolFee;
        unchecked { amount = amount - protocolFee; }

        uint256 claimantId = claimantIds[claimant][token];
        if (claimantId == 0) {
            ++claimantIdCount;
            claimantsInfo[claimantIdCount] = ClaimantInfo({
                claimant: claimant,
                token: token,
                balance: amount
            });
            claimantIds[claimant][token] = claimantIdCount;
        }
        else {
            claimantsInfo[claimantId].balance += amount;
        }
        emit AddCommission(claimant, token, amount, claimantsInfo[claimantId].balance, protocolFee, protocolFeeBalance[token]);
    }
    function getClaimantBalance(address claimant, IERC20 token) external view returns (uint256) {
        uint256 claimantId = claimantIds[claimant][token];
        return claimantsInfo[claimantId].balance;
    }
    function getClaimantsInfo(uint256 fromId, uint256 count) external view returns (ClaimantInfo[] memory claimantInfoList) {
        require(fromId > 0 && fromId <= claimantIdCount, "out of bounds");
        uint256 maxCount = claimantIdCount - fromId + 1;
        if (count > maxCount) {
            count = maxCount;
        }
        claimantInfoList = new ClaimantInfo[](count);
        uint256 currId = fromId;
        for (uint256 i = 0; i < count; i++) {
            claimantInfoList[i] = claimantsInfo[currId];
            ++currId;
        }
    }

    function proxyCall(address referrer, uint256 campaignId, address target, TokensIn[] memory tokensIn, address to, IERC20[] memory tokensOut, bytes memory data) payable external {
        require(campaignId < campaigns.length, "invalid campaign");
        Campaign storage campaign = campaigns[campaignId];
        require(campaign.isTargetAndSelector[bytes24(abi.encodePacked(target,bytes4(data)))], "selector not matched");
        require(campaign.startDate <= block.timestamp && block.timestamp <= campaign.endDate, "campaign not started yet / already ended");
        require(campaign.referrersRequireApproval && campaign.referrers.length > 0 && campaign.referrers[campaign.referrersInv[referrer]] == referrer, "not a referrer");

        uint ethAmount;

        uint256 length = tokensIn.length;
        require(length <= campaign.maxInputTokensInEachCall, "inToken length exceeded");
        uint256 i;

        while (i < length){
            IERC20 token = tokensIn[i].token;
            uint256 amount = tokensIn[i].amount;
            CommissionInTokenConfig storage tokenConfig = campaign.commissionInTokenConfig[token];
            if (address(token) == address(0)) {
                require(ethAmount == 0, "more than one ETH transfer");
                require(msg.value == amount, "ETH amount not matched");
                ethAmount = amount;
            } else {
                if (tokenConfig.directTransfer) {
                    token.safeTransferFrom(msg.sender, target, amount);
                } else {
                    amount = _transferAssetFrom(token, amount);
                    // require(amount == tokensIn[i].amount, "amount not matched");
                    token.safeApprove(target, 0);
                    token.safeApprove(target, amount);
                }
            }
            emit TransferForward(target, token, msg.sender, amount);

            // deduct from stakes
            if (tokenConfig.rate > 0) {
                amount = amount * tokenConfig.rate / 1e6; // amount is commission from now on
                require(amount <= tokenConfig.capPerTransaction, "cap exceeded");
                require(amount <= stakesBalance[campaign.projectId][token], "not enough commission");
                unchecked { stakesBalance[campaign.projectId][token] -= amount; }
                campaignAccumulatedCommission[campaignId][token] += amount;
                require(campaignAccumulatedCommission[campaignId][token] <= tokenConfig.capPerCampaign, "accumulated commission exceeded limit");
                addToDistributions(referrer, token, amount); 
            }

            unchecked { i++; }
        }

        assembly {
            let ret := call(gas(), target, ethAmount, add(0x20,data), mload(data), 0, 0)
            // returndatacopy(0, 0, returndatasize())
            if eq(0, ret) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        // transfer token back
        length = tokensOut.length;
        require(length <= campaign.maxOutputTokensInEachCall, "outToken length exceeded");
        i = 0;
        while (i < length) {
            IERC20 outToken = tokensOut[i];
            CommissionOutTokenConfig storage tokenConfig = campaign.commissionOutTokenConfig[outToken];
            uint256 amount;
            if (address(outToken) == address(0)) {
                amount = address(this).balance - lastBalance[IERC20(address(0))];
                _safeTransferETH(to, amount);
            } else  {
                amount = outToken.balanceOf(address(this)) - lastBalance[outToken];
                outToken.safeTransfer(to, amount);
            }
            if (tokenConfig.rate > 0) {
                amount = amount * tokenConfig.rate / 1e6; // amount is commission from now on
                require(amount <= tokenConfig.capPerTransaction, "cap exceeded");
                require(amount <= stakesBalance[campaign.projectId][outToken], "not enough commission");
                unchecked { stakesBalance[campaign.projectId][outToken] -= amount; }
                campaignAccumulatedCommission[campaignId][outToken] += amount;
                require(campaignAccumulatedCommission[campaignId][outToken] <= tokenConfig.capPerCampaign, "accumulated commission exceeded limit");
                addToDistributions(referrer, outToken, amount); 
            }
            emit TransferBack(target, outToken, to, amount);
            unchecked { i++; }
        }
        assembly {
            returndatacopy(0, 0, returndatasize())
            return(0, returndatasize())
        }
    }

    // stake
    function _stake(uint256 projectId, IERC20 token, uint256 amount) internal {
        if (address(token) != address(0))
            amount = _transferAssetFrom(token, amount);
        stakesBalance[projectId][token] += amount;
        lastBalance[token] += amount;

        emit Stake(projectId, token, amount, stakesBalance[projectId][token]);
    }
    function stake(uint256 projectId, IERC20 token, uint256 amount) external {
        _stake(projectId, token, amount);
    }
    function stakeETH(uint256 projectId) external payable {
        _stake(projectId, IERC20(address(0)), msg.value);
    }
    function stakeMultiple(uint256 projectId, IERC20[] calldata token, uint256[] calldata amount) external payable {
        uint256 length = token.length;
        require(length == amount.length, "length not matched");
        uint256 i;
        while (i < length) {
            _stake(projectId, token[i], amount[i]);
            unchecked { i++; }
        }
        if (msg.value > 0) {
            _stake(projectId, IERC20(address(0)), msg.value);
        }
    }

    // commissions
    function _claim(IERC20 token) internal {
        uint256 claimantId = claimantIds[msg.sender][token];
        ClaimantInfo memory claimantInfo = claimantsInfo[claimantId];
        uint256 balance = claimantInfo.balance;
        claimantsInfo[claimantId].balance = 0;
        lastBalance[token] -= balance;
        if (address(token) == address(0)) {
            _safeTransferETH(msg.sender, balance);
        } else {
            token.safeTransfer(msg.sender, balance);
        }
        emit Claim(msg.sender, token, balance);
    }
    function claim(IERC20 token) external {
        _claim(token);
    }
    function claimMultiple(IERC20[] calldata tokens) external {
        uint256 length = tokens.length;
        for (uint256 i ; i < length ; i++) {
            _claim(tokens[i]);
        }
    }

    function _claimProtocolFee(IERC20 token) internal {
        uint256 balance = protocolFeeBalance[token];
        protocolFeeBalance[token] = 0;
        lastBalance[token] -= balance;
        if (address(token) == address(0)) {
            _safeTransferETH(msg.sender, balance);
        } else {
            token.safeTransfer(msg.sender, balance);
        }
        emit ClaimProtocolFee(token, balance);
    }
    function claimProtocolFee(IERC20 token) external onlyOwner {
        _claimProtocolFee(token);
    }
    function claimMultipleProtocolFee(IERC20[] calldata tokens) external onlyOwner {
        uint256 length = tokens.length;
        for (uint256 i ; i < length ; i++) {
            _claimProtocolFee(tokens[i]);
        }
    }

    // transfer excess tokens to caller
    function skim(IERC20[] calldata tokens) external {
        uint256 length = tokens.length;
        for (uint256 i = 0 ; i < length ; i++) {
            uint256 amount;
            IERC20 token = tokens[i];
            if (address(token) == address(0)) {
                amount = address(this).balance;
                amount = amount - lastBalance[IERC20(address(0))];
                _safeTransferETH(msg.sender, amount);
            } else {
                amount = token.balanceOf(address(this));
                amount = amount - lastBalance[token];
                token.safeTransfer(msg.sender, amount);
            }
            emit Skim(token, msg.sender, amount);
        }
    }
}
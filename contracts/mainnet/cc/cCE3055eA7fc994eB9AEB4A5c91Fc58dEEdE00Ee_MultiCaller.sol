// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IERC20.sol";
import "Initializable.sol";
import "OwnableUpgradeable.sol";
import "IBribeManager.sol";
import "ICompounderJoe.sol";
import "ICompounderPTP.sol";
import "ILVTXAutoCompound.sol";
import "SafeERC20.sol";
import "IAvaxHelper.sol";

contract MultiCaller is Initializable, OwnableUpgradeable {
    using SafeERC20 for IERC20;

    // CONSTANTS
    address public constant WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address public constant VTX = 0x5817D4F0b62A59b17f75207DA1848C2cE75e7AF4;

    //ADDRESSES
    IBribeManager public bribeManager;
    address public avaxHelper;

    function __MultiCaller_init(address _wavax, address _bribeManager) public initializer {
        __Ownable_init();
        bribeManager = IBribeManager(_bribeManager);
    }

    receive() external payable {}

    /// @notice Set the swap helper which takes care withdrawing WAVAX
    /// @param _avaxHelper address of the avax helper
    function setAvaxHelper(address _avaxHelper) external onlyOwner {
        avaxHelper = _avaxHelper;
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

    function multiHarvest(address[] calldata harvestedContracts, address receiver) external {
        uint256 length = harvestedContracts.length;
        for (uint256 i; i < length; ++i) {
            if (harvestedContracts[i] == address(bribeManager)) {
                bribeManager.castVotes(true);
            } else {
                ICompounderJoe(harvestedContracts[i]).compound();
            }
        }
        uint256 wavaxBalance = IERC20(WAVAX).balanceOf(address(this));
        _approveTokenIfNeeded(WAVAX, avaxHelper, wavaxBalance);
        IAvaxHelper(avaxHelper).withdrawTo(msg.sender, wavaxBalance);
        (bool sent, ) = receiver.call{value: address(this).balance}("");
        IERC20(VTX).safeTransfer(msg.sender, IERC20(VTX).balanceOf(address(this)));
    }

    function previewMultiHarvest(
        address[] calldata harvestedContracts,
        address[] calldata harvestedCoreContracts,
        address[] calldata _lps
    ) external view returns (uint256[] memory amounts, address[] memory rewardTokens) {
        uint256 length = harvestedContracts.length;
        amounts = new uint256[](2);
        rewardTokens = new address[](2);
        for (uint256 i; i < length; ++i) {
            if (harvestedContracts[i] == address(bribeManager)) {
                amounts[0] += bribeManager.previewAvaxAmountForHarvest(_lps);
            } else {
                if (
                    block.timestamp >
                    ICompounderJoe(harvestedContracts[i]).lastCompoundTime() +
                        ICompounderJoe(harvestedContracts[i]).DELAY_BETWEEN_COMPOUNDS()
                ) {
                    amounts[0] += ICompounderJoe(harvestedContracts[i])
                        .previewAvaxAmountForHarvest();
                }
            }
        }
        uint256 lengthCore = harvestedCoreContracts.length;
        for (uint256 j; j < lengthCore; ++j) {
            (uint256 avaxAmount, uint256 vtxAmount) = ILVTXAutoCompound(harvestedCoreContracts[j])
                .previewRewardsForHarvest();
            rewardTokens[1] = VTX;
            amounts[0] += avaxAmount;
            amounts[1] += vtxAmount;
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

interface ICompounderJoe {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Compound(uint256 wavaxAmount);
    event Deposit(address indexed user, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Withdraw(address indexed user, uint256 amount);

    function DELAY_BETWEEN_COMPOUNDS() external view returns (uint256);

    function DENOMINATOR() external view returns (uint256);

    function JOE() external view returns (address);

    function ROUTER() external view returns (address);

    function WAVAX() external view returns (address);

    function __Compounder_init_(
        string calldata _name,
        string calldata _symbol,
        address _depositToken,
        address _stakingToken,
        address _protocolFeeRecipient,
        address _mainStakingJoe,
        address _swapHelper
    ) external;

    function addRewardToken(address rewardToken) external;

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function avaxHelper() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function callerFee() external view returns (uint256);

    function compound() external;

    function convertDust() external;

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    function deposit(uint256 amount) external;

    function depositToken() external view returns (address);

    function getDepositTokensForShares(uint256 amount) external view returns (uint256);

    function getRewardLength() external view returns (uint256 length);

    function getSharesForDepositTokens(uint256 amount) external view returns (uint256);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function isRewardToken(address) external view returns (bool);

    function lastCompoundTime() external view returns (uint256);

    function lvtxFee() external view returns (uint256);

    function lvtxRewarder() external view returns (address);

    function mainStaking() external view returns (address);

    function maxRewardPending() external view returns (uint256);

    function migrateAllUserDepositsFromManual() external;

    function migrateAllUserDepositsToManual() external;

    function migrateFromManual(uint256 amount) external;

    function migrateToManual(uint256 amount) external;

    function name() external view returns (string memory);

    function owner() external view returns (address);

    function pendingTokensToHarvest()
        external
        view
        returns (address[] memory tokens, uint256[] memory amounts);

    function poolHelper() external view returns (address);

    function previewAvaxAmountForHarvest() external view returns (uint256 avaxAmount);

    function protocolFee() external view returns (uint256);

    function protocolFeeRecipient() external view returns (address);

    function renounceOwnership() external;

    function rewardTokens(uint256) external view returns (address);

    function safeCompound() external;

    function setAvaxHelper(address _avaxHelper) external;

    function setCallerFee(uint256 newValue) external;

    function setLvtxFee(uint256 newValue) external;

    function setLvtxRewarder(address _rewarder) external;

    function setMaximumPendingReward(uint256 _maxRewardPending) external;

    function setProtocolFee(uint256 newValue) external;

    function setProtocolFeeRecipient(address _recipient) external;

    function setSwapHelper(address _swapHelper) external;

    function stakingToken() external view returns (address);

    function swapHelper() external view returns (address);

    function symbol() external view returns (string memory);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function totalDeposits() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferOwnership(address newOwner) external;

    function updatePoolHelper() external;

    function userDepositToken(address user) external view returns (uint256 userDeposit);

    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface ICompounderPTP {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Compound(uint256 wavaxAmount);
    event Deposit(address indexed user, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Withdraw(address indexed user, uint256 amount);

    function DELAY_BETWEEN_COMPOUNDS() external view returns (uint256);

    function DENOMINATOR() external view returns (uint256);

    function PTP() external view returns (address);

    function WAVAX() external view returns (address);

    function __Compounder_init_(
        string calldata _name,
        string calldata _symbol,
        address _depositToken,
        address _stakingToken,
        address _protocolFeeRecipient,
        address _mainStaking,
        address _swapHelper,
        address _assetToken
    ) external;

    function addRewardToken(address rewardToken) external;

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function assetToken() external view returns (address);

    function avaxHelper() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function callerFee() external view returns (uint256);

    function compound() external;

    function convertDust() external;

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    function deposit(uint256 amount) external;

    function depositAvax() external payable;

    function depositToken() external view returns (address);

    function getDepositTokensForShares(uint256 amount) external view returns (uint256);

    function getRewardLength() external view returns (uint256 length);

    function getSharesForDepositTokens(uint256 amount) external view returns (uint256);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function isRewardToken(address) external view returns (bool);

    function lastCompoundTime() external view returns (uint256);

    function lvtxFee() external view returns (uint256);

    function lvtxRewarder() external view returns (address);

    function mainStaking() external view returns (address);

    function maxRewardPending() external view returns (uint256);

    function migrateAllUserDepositsFromManual() external;

    function migrateAllUserDepositsToManual() external;

    function migrateFromManual(uint256 amount) external;

    function migrateToManual(uint256 amount) external;

    function name() external view returns (string memory);

    function owner() external view returns (address);

    function pendingTokensToHarvest()
        external
        view
        returns (address[] memory tokens, uint256[] memory amounts);

    function poolHelper() external view returns (address);

    function previewAvaxAmountForHarvest() external view returns (uint256 avaxAmount);

    function protocolFee() external view returns (uint256);

    function protocolFeeRecipient() external view returns (address);

    function renounceOwnership() external;

    function rewardTokens(uint256) external view returns (address);

    function safeCompound() external;

    function setAvaxHelper(address _avaxHelper) external;

    function setCallerFee(uint256 newValue) external;

    function setLvtxFee(uint256 newValue) external;

    function setLvtxRewarder(address _rewarder) external;

    function setMaximumPendingReward(uint256 _maxRewardPending) external;

    function setProtocolFee(uint256 newValue) external;

    function setProtocolFeeRecipient(address _recipient) external;

    function setSwapHelper(address _swapHelper) external;

    function stakingToken() external view returns (address);

    function swapHelper() external view returns (address);

    function symbol() external view returns (string memory);

    function totalDeposits() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferOwnership(address newOwner) external;

    function updatePoolHelper() external;

    function userDepositToken(address user) external view returns (uint256 userDeposit);

    function withdraw(uint256 amount, uint256 minAmount) external;

    function withdrawAvax(uint256 amount, uint256 minAmount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface ILVTXAutoCompound {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function DENOMINATOR() external view returns (uint256);

    function LVTX() external view returns (address);

    function MAX_TOKEN_TO_REINVEST() external view returns (uint256);

    function WAVAX() external view returns (address);

    function __LVTXAutoCompound_init_(
        address locker,
        address _delegatedPool,
        address _swapHelper,
        address _bribeManager,
        address _vtx
    ) external;

    function addRewardToken(address rewardToken) external;

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function bribeManager() external view returns (address);

    function callerFee() external view returns (uint256);

    function compound() external;

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    function delegatedPool() external view returns (address);

    function deposit(uint256 amount) external;

    function depositVTX(uint256 amount) external;

    function getDepositTokensForShares(uint256 amount) external view returns (uint256);

    function getRewardLength() external view returns (uint256 length);

    function getSharesForDepositTokens(uint256 amount) external view returns (uint256);

    function getTotalDepositToken() external view returns (uint256 totalDepositToken);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function isRewardToken(address) external view returns (bool);

    function name() external view returns (string memory);

    function owner() external view returns (address);

    function pendingTokensToHarvest()
        external
        view
        returns (address[] memory tokens, uint256[] memory amounts);

    function previewRewardsForHarvest()
        external
        view
        returns (uint256 avaxAmount, uint256 vtxAmount);

    function protocolFee() external view returns (uint256);

    function protocolFeeRecipient() external view returns (address);

    function renounceOwnership() external;

    function rewardTokens(uint256) external view returns (address);

    function setCallerFee(uint256 newValue) external;

    function setFeeCollector(address _collector) external;

    function setMaxTokenToReinvest(uint256 value) external;

    function setProtocolFee(uint256 newValue) external;

    function setSwapHelper(address _swapHelper) external;

    function setWhitelistForTransfer(address _for, bool status) external;

    function swapHelper() external view returns (address);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferOwnership(address newOwner) external;

    function transferWhitelist(address) external view returns (bool);

    function userDepositToken(address user) external view returns (uint256 userDeposit);

    function vtx() external view returns (address);

    function withdraw(uint256 amount) external;
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
pragma solidity 0.8.7;

interface IAvaxHelper {
    function WAVAX() external view returns (address);

    function withdrawTo(address to, uint256 amount) external;
}
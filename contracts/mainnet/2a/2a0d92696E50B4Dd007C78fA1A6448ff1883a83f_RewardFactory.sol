// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "IRewardFactory.sol";
import "IRewardPool.sol";
import "IProxyFactory.sol";
import "IVirtualBalanceRewardPool.sol";
import "IBooster.sol";
import "Address.sol";

/**
 * @title Echnida RewardFactory
 * @author echnida.finance
 * @notice
 *  RewardFactory updates status of rewards pools.
 */
contract RewardFactory is IRewardFactory {
    using Address for address;

    address public immutable ptp;

    address public booster;
    address public immutable proxyFactory;
    address public rewardPoolImpl;
    address public virtualBalanceRewardPoolimpl;

    event SetImpl(address rewardPoolImpl, address virtualBalanceRewardPoolimpl);
    event CreatePtpRewards(uint256 pid, address rewardPool, address booster);
    event CreateTokenRewards(
        address tokenRewards,
        address mainRewards,
        address rewardPool
    );

    constructor(
        address _booster,
        address _proxyFactory,
        address _ptp
    ) {
        booster = _booster;
        proxyFactory = _proxyFactory;
        ptp = _ptp;
    }

    function setImpl(
        address _rewardPoolImpl,
        address _virtualBalanceRewardPoolimpl
    ) external {
        require(msg.sender == IBooster(booster).owner(), "!auth");
        rewardPoolImpl = _rewardPoolImpl;
        virtualBalanceRewardPoolimpl = _virtualBalanceRewardPoolimpl;
        emit SetImpl(_rewardPoolImpl, _virtualBalanceRewardPoolimpl);
    }

    /**
     * @notice
     *  Creates managed reward pool to handle distribution of all ptp tokens mined in the pool.
     * @param _pid The id of a token used as reward.
     * @return The address of created reward pool.
     */
    function createPtpRewards(uint256 _pid)
        external
        override
        returns (address)
    {
        require(msg.sender == booster, "!auth");
        require(rewardPoolImpl != address(0x0), "zero");

        //operator = booster(deposit) contract so that new ptp can be added and distributed
        //reward manager = this factory so that extra incentive tokens can be linked to the main managed reward pool
        address rewardPool = IProxyFactory(proxyFactory).clone(rewardPoolImpl);

        IRewardPool(rewardPool).initialize(
            _pid,
            ptp,
            booster,
            address(this),
            IBooster(booster).owner()
        );
        emit CreatePtpRewards(_pid, rewardPool, booster);

        return address(rewardPool);
    }

    /**
     * @notice
     *  Creates virtual balance reward pool that mimicks the balance of a pool's main reward contract.
     *  Used for extra incentive tokens.
     * @param _tokenRewards The token distributed as a reward.
     * @param _mainRewards The RewardPool for balance reference
     * @return The address of the created extra reward pool.
     */
    function createTokenRewards(address _tokenRewards, address _mainRewards)
        external
        override
        returns (address)
    {
        require(msg.sender == booster, "!auth");

        require(virtualBalanceRewardPoolimpl != address(0x0), "zero");

        //create new pool, use main pool for balance lookup
        address rewardPool = IProxyFactory(proxyFactory).clone(
            virtualBalanceRewardPoolimpl
        );
        IVirtualBalanceRewardPool(rewardPool).initialize(
            _mainRewards,
            _tokenRewards,
            IBooster(booster).owner()
        );

        //add the new pool to main pool's list of extra rewards, assuming this factory has "reward manager" role
        IRewardPool(_mainRewards).addExtraReward(rewardPool);
        //return new pool's address
        emit CreateTokenRewards(_tokenRewards, _mainRewards, rewardPool);

        return rewardPool;
    }

    function clearExtraRewards(address rewardContract) external override {
        require(msg.sender == booster, "!auth");
        IRewardPool(rewardContract).clearExtraRewards();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface IRewardFactory {
    function createPtpRewards(uint256) external returns (address);

    function createTokenRewards(address, address) external returns (address);

    function clearExtraRewards(address rewardContract) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface IRewardPool {
    function balanceOf(address _account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function getReward() external returns (bool);

    function stake(address _account, uint256 _amount) external returns (bool);

    function unStake(
        address _account,
        uint256 _amount,
        bool _claim
    ) external returns (bool);

    function queueNewRewards(uint256 _rewards) external returns (bool);

    function addExtraReward(address _reward) external returns (bool);

    function initialize(
        uint256 pid_,
        address rewardToken_,
        address operator_,
        address rewardManager_,
        address governance_
    ) external;

    function clearExtraRewards() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface IProxyFactory {
    function clone(address _target) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;
import "IERC20.sol";

interface IVirtualBalanceRewardPool {
    function stake(address, uint256) external returns (bool);

    function withdraw(address, uint256) external returns (bool);

    function getReward(address) external returns (bool);

    function queueNewRewards(uint256) external returns (bool);

    function rewardToken() external view returns (IERC20);

    function earned(address account) external view returns (uint256);

    function initialize(
        address deposit_,
        address reward_,
        address owner
    ) external;
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
pragma solidity 0.8.12;

interface IBooster {
    function isShutdown() external view returns (bool);

    function poolInfo(uint256)
        external
        view
        returns (
            uint256,
            address,
            address,
            address,
            address,
            bool
        );

    function getMainRewardContract(uint256) external view returns (address);

    function claimRewards(uint256, address) external returns (bool);

    function rewardArbitrator() external returns (address);

    function setGaugeRedirect(uint256 _pid) external returns (bool);

    function owner() external returns (address);

    function depositFor(
        uint256 _pid,
        uint256 _amount,
        address account
    ) external;
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
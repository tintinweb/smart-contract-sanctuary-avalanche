// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.14;

import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import '../interfaces/IMasterPlatypusV4.sol';
import '../interfaces/IBoostedMultiRewarder.sol';

interface IWAVAX {
    function deposit() external payable;
}

/**
 * This is a sample contract to be used in the MasterPlatypus contract for partners to reward
 * stakers with their native token alongside PTP.
 *
 * It assumes no minting rights, so requires a set amount of reward tokens to be transferred to this contract prior.
 * E.g. say you've allocated 100,000 XYZ to the PTP-XYZ farm over 30 days. Then you would need to transfer
 * 100,000 XYZ and set the block reward accordingly so it's fully distributed after 30 days.
 *
 * - This contract has no knowledge on the LP amount and MasterPlatypus is
 *   responsible to pass the amount into this contract
 * - Supports multiple reward tokens
 * - Support boosted pool. The dilutingRepartition can be different from that of MasterPlatypusV4
 */
contract BoostedMultiRewarderPerSec is IBoostedMultiRewarder, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 private constant ACC_TOKEN_PRECISION = 1e12;
    /// @notice WAVAX address on mainnet
    address private constant WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;

    IERC20 public immutable lpToken;
    IMasterPlatypusV4 public immutable MP;

    struct UserInfo {
        // if the pool is activated, rewardDebt should be > 0
        uint128 rewardDebt; // 20.18 fixed point. distributed reward per weight
        uint128 claimable; // 20.18 fixed point. claimable REWARD
    }

    /// @notice Info of each MP poolInfo.
    struct PoolInfo {
        IERC20 rewardToken; // if rewardToken is 0, native token is used as reward token
        uint96 tokenPerSec; // 10.18 fixed point
        uint128 accTokenPerShare; // 26.12 fixed point. Amount of reward token each LP token is worth. Times 1e12
        uint128 accTokenPerFactorShare; // 26.12 fixed point. Accumulated ptp per factor share. Time 1e12
    }

    /// @notice address of the operator
    /// @dev operator is able to set emission rate
    address public operator;

    uint40 public lastRewardTimestamp;
    uint16 public dilutingRepartition; // base: 1000

    /// @notice Info of the poolInfo.
    PoolInfo[] public poolInfo;
    /// @notice tokenId => UserInfo
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    event OnReward(address indexed rewardToken, address indexed user, uint256 amount);
    event RewardRateUpdated(address indexed rewardToken, uint256 oldRate, uint256 newRate);
    event UpdateEmissionRepartition(address indexed user, uint256 dilutingRepartition, uint256 nonDilutingRepartition);

    modifier onlyMP() {
        require(msg.sender == address(MP), 'onlyMP: only MasterPlatypus can call this function');
        _;
    }

    modifier onlyOperatorOrOwner() {
        require(msg.sender == owner() || msg.sender == operator, 'onlyOperatorOrOwner');
        _;
    }

    constructor(
        IMasterPlatypusV4 _MP,
        IERC20 _lpToken,
        uint40 _startTimestamp,
        uint16 _dilutingRepartition,
        IERC20 _rewardToken,
        uint96 _tokenPerSec
    ) {
        require(_dilutingRepartition <= 1000, '_dilutingRepartition > 1000');
        require(
            Address.isContract(address(_rewardToken)) || address(_rewardToken) == address(0),
            'constructor: reward token must be a valid contract'
        );
        require(Address.isContract(address(_lpToken)), 'constructor: LP token must be a valid contract');
        require(Address.isContract(address(_MP)), 'constructor: MasterPlatypus must be a valid contract');
        // require(_startTimestamp >= block.timestamp);

        MP = _MP;
        lpToken = _lpToken;
        dilutingRepartition = _dilutingRepartition;

        lastRewardTimestamp = _startTimestamp;

        // use non-zero amount for accTokenPerShare and accTokenPerFactorShare as we want to check if user
        // has activated the pool by checking rewardDebt > 0
        PoolInfo memory pool = PoolInfo({
            rewardToken: _rewardToken,
            tokenPerSec: _tokenPerSec,
            accTokenPerShare: 1e18,
            accTokenPerFactorShare: 1e18
        });
        poolInfo.push(pool);
        emit RewardRateUpdated(address(_rewardToken), 0, _tokenPerSec);
    }

    /// @notice Set operator address
    function setOperator(address _operator) external onlyOwner {
        operator = _operator;
    }

    function addRewardToken(IERC20 _rewardToken, uint96 _tokenPerSec) external onlyOwner {
        // use non-zero amount for accTokenPerShare and accTokenPerFactorShare as we want to check if user
        // has activated the pool by checking rewardDebt > 0
        PoolInfo memory pool = PoolInfo({
            rewardToken: _rewardToken,
            tokenPerSec: _tokenPerSec,
            accTokenPerShare: 1e18,
            accTokenPerFactorShare: 1e18
        });
        poolInfo.push(pool);
        emit RewardRateUpdated(address(_rewardToken), 0, _tokenPerSec);
    }

    /// @notice updates emission repartition
    /// @param _dilutingRepartition the future dialuting repartition
    function updateEmissionRepartition(uint16 _dilutingRepartition) external onlyOwner {
        require(_dilutingRepartition <= 1000);
        _updatePool();
        dilutingRepartition = _dilutingRepartition;
        emit UpdateEmissionRepartition(msg.sender, _dilutingRepartition, 1000 - _dilutingRepartition);
    }

    function _updatePool() internal {
        uint256 lpSupply = lpToken.balanceOf(address(MP));
        uint256 pid = MP.getPoolId(address(lpToken));
        uint256 sumOfFactors = MP.getSumOfFactors(pid);
        uint256 length = poolInfo.length;

        if (block.timestamp > lastRewardTimestamp && lpSupply > 0) {
            for (uint256 i; i < length; ++i) {
                PoolInfo storage pool = poolInfo[i];
                uint256 timeElapsed = block.timestamp - lastRewardTimestamp;
                uint256 tokenReward = timeElapsed * pool.tokenPerSec;
                pool.accTokenPerShare += toUint128(
                    (tokenReward * ACC_TOKEN_PRECISION * dilutingRepartition) / lpSupply / 1000
                );
                if (sumOfFactors > 0) {
                    pool.accTokenPerFactorShare += toUint128(
                        (tokenReward * ACC_TOKEN_PRECISION * (1000 - dilutingRepartition)) / sumOfFactors / 1000
                    );
                }
            }

            lastRewardTimestamp = uint40(block.timestamp);
        }
    }

    /// @notice Sets the distribution reward rate. This will also update the poolInfo.
    /// @param _tokenPerSec The number of tokens to distribute per second
    function setRewardRate(uint256 _tokenId, uint96 _tokenPerSec) external onlyOperatorOrOwner {
        require(_tokenPerSec <= 10000e18, 'reward rate too high'); // in case of accTokenPerShare overflow
        _updatePool();

        uint256 oldRate = _tokenPerSec;
        poolInfo[_tokenId].tokenPerSec = _tokenPerSec;

        emit RewardRateUpdated(address(poolInfo[_tokenId].rewardToken), oldRate, _tokenPerSec);
    }

    /// @notice Function called by MasterPlatypus whenever staker claims PTP harvest.
    /// @notice Allows staker to also receive a 2nd reward token.
    /// @dev Assume lpSupply and sumOfFactors isn't updated yet when this function is called
    /// @param _user Address of user
    /// @param _lpAmount Number of LP tokens the user has
    function onPtpReward(
        address _user,
        uint256 _lpAmount,
        uint256 _newLpAmount,
        uint256 _factor,
        uint256 _newFactor
    ) external override onlyMP nonReentrant returns (uint256[] memory rewards) {
        _updatePool();

        uint256 length = poolInfo.length;
        rewards = new uint256[](length);
        for (uint256 i; i < length; ++i) {
            PoolInfo storage pool = poolInfo[i];
            UserInfo storage user = userInfo[i][_user];
            IERC20 rewardToken = pool.rewardToken;

            // if user has activated the pool, update rewards
            if (user.rewardDebt > 0) {
                uint256 pending = ((_lpAmount * pool.accTokenPerShare + _factor * pool.accTokenPerFactorShare) /
                    ACC_TOKEN_PRECISION) +
                    user.claimable -
                    user.rewardDebt;

                if (address(rewardToken) == address(0)) {
                    // is native token
                    uint256 tokenBalance = address(this).balance;
                    if (pending > tokenBalance) {
                        _safeTransferAvaxWithFallback(_user, tokenBalance);
                        rewards[i] = tokenBalance;
                        user.claimable = toUint128(pending - tokenBalance);
                    } else {
                        _safeTransferAvaxWithFallback(_user, pending);
                        rewards[i] = pending;
                        user.claimable = 0;
                    }
                } else {
                    // ERC20 token
                    uint256 tokenBalance = rewardToken.balanceOf(address(this));
                    if (pending > tokenBalance) {
                        rewardToken.safeTransfer(_user, tokenBalance);
                        rewards[i] = tokenBalance;
                        user.claimable = toUint128(pending - tokenBalance);
                    } else {
                        rewardToken.safeTransfer(_user, pending);
                        rewards[i] = pending;
                        user.claimable = 0;
                    }
                }
            }

            user.rewardDebt = toUint128(
                (_newLpAmount * pool.accTokenPerShare + _newFactor * pool.accTokenPerFactorShare) / ACC_TOKEN_PRECISION
            );
            emit OnReward(address(rewardToken), _user, rewards[i]);
        }
    }

    /// @notice Function called by MasterPlatypus when factor is updated
    /// @dev Assume lpSupply and sumOfFactors isn't updated yet when this function is called
    /// @notice user.claimable will be updated
    function onUpdateFactor(
        address _user,
        uint256 _lpAmount,
        uint256 _factor,
        uint256 _newFactor
    ) external override onlyMP {
        if (dilutingRepartition == 1000) {
            // dialuting reard only
            return;
        }

        _updatePool();
        uint256 length = poolInfo.length;

        for (uint256 i; i < length; ++i) {
            PoolInfo storage pool = poolInfo[i];
            UserInfo storage user = userInfo[i][_user];

            // if user has active the pool
            if (user.rewardDebt > 0) {
                user.claimable += toUint128(
                    ((_lpAmount * pool.accTokenPerShare + _factor * pool.accTokenPerFactorShare) /
                        ACC_TOKEN_PRECISION) - user.rewardDebt
                );
            }

            user.rewardDebt = toUint128(
                (_lpAmount * pool.accTokenPerShare + _newFactor * pool.accTokenPerFactorShare) / ACC_TOKEN_PRECISION
            );
        }
    }

    /// @notice returns pool length
    function poolLength() external view override returns (uint256) {
        return poolInfo.length;
    }

    /// @notice View function to see pending tokens
    /// @param _user Address of user.
    /// @return rewards reward for a given user.
    function pendingTokens(
        address _user,
        uint256 _lpAmount,
        uint256 _factor
    ) external view override returns (uint256[] memory rewards) {
        uint256 lpSupply = lpToken.balanceOf(address(MP));
        uint256 pid = MP.getPoolId(address(lpToken));
        uint256 sumOfFactors = MP.getSumOfFactors(pid);
        uint256 length = poolInfo.length;

        rewards = new uint256[](length);
        for (uint256 i; i < length; ++i) {
            PoolInfo memory pool = poolInfo[i];
            UserInfo storage user = userInfo[i][_user];

            uint256 accTokenPerShare = pool.accTokenPerShare;
            uint256 accTokenPerFactorShare = pool.accTokenPerFactorShare;

            if (block.timestamp > lastRewardTimestamp && lpSupply > 0) {
                uint256 timeElapsed = block.timestamp - lastRewardTimestamp;
                uint256 tokenReward = timeElapsed * pool.tokenPerSec;
                accTokenPerShare += (tokenReward * ACC_TOKEN_PRECISION * dilutingRepartition) / lpSupply / 1000;
                if (sumOfFactors > 0) {
                    accTokenPerFactorShare +=
                        (tokenReward * ACC_TOKEN_PRECISION * (1000 - dilutingRepartition)) /
                        sumOfFactors /
                        1000;
                }
            }

            uint256 temp = _lpAmount * accTokenPerShare + _factor * accTokenPerFactorShare;
            rewards[i] = (temp / ACC_TOKEN_PRECISION) - user.rewardDebt + user.claimable;
        }
    }

    /// @notice return an array of reward tokens
    function rewardTokens() external view override returns (IERC20[] memory tokens) {
        uint256 length = poolInfo.length;
        tokens = new IERC20[](length);
        for (uint256 i; i < length; ++i) {
            PoolInfo memory pool = poolInfo[i];
            tokens[i] = pool.rewardToken;
        }
    }

    /// @notice In case rewarder is stopped before emissions finished, this function allows
    /// withdrawal of remaining tokens.
    function emergencyWithdraw() external onlyOwner {
        uint256 length = poolInfo.length;

        for (uint256 i; i < length; ++i) {
            PoolInfo storage pool = poolInfo[i];
            if (address(pool.rewardToken) == address(0)) {
                // is native token
                (bool success, ) = msg.sender.call{value: address(this).balance}('');
                require(success, 'Transfer failed');
            } else {
                pool.rewardToken.safeTransfer(address(msg.sender), pool.rewardToken.balanceOf(address(this)));
            }
        }
    }

    /// @notice avoids loosing funds in case there is any tokens sent to this contract
    /// @dev only to be called by owner
    function emergencyTokenWithdraw(address token) external onlyOwner {
        // send that balance back to owner
        IERC20(token).safeTransfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }

    /// @notice View function to see balances of reward token.
    function balances() external view returns (uint256[] memory balances_) {
        uint256 length = poolInfo.length;
        balances_ = new uint256[](length);

        for (uint256 i; i < length; ++i) {
            PoolInfo storage pool = poolInfo[i];
            if (address(pool.rewardToken) == address(0)) {
                // is native token
                balances_[i] = address(this).balance;
            } else {
                balances_[i] = pool.rewardToken.balanceOf(address(this));
            }
        }
    }

    /// @notice payable function needed to receive AVAX
    receive() external payable {}

    function toUint128(uint256 val) internal pure returns (uint128) {
        if (val > type(uint128).max) revert('uint128 overflow');
        return uint128(val);
    }

    /**
     * @notice Transfer Avax. If the Avax transfer fails, wrap the Avax and try send it as WAVAX.
     */
    function _safeTransferAvaxWithFallback(address to, uint256 amount) internal {
        if (!_safeTransferAvax(to, amount)) {
            IWAVAX(WAVAX).deposit{value: amount}();
            IERC20(WAVAX).transfer(to, amount);
        }
    }

    /**
     * @notice Transfer Avax and return the success status.
     * @dev This function only forwards 30,000 gas to the callee.
     */
    function _safeTransferAvax(address to, uint256 value) internal returns (bool) {
        (bool success, ) = to.call{value: value, gas: 30_000}(new bytes(0));
        return success;
    }
}

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
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
pragma solidity ^0.8.9;

import './IAsset.sol';
import './IBoostedMultiRewarder.sol';
import './IPlatypusTreasure.sol';

/**
 * @dev Interface of the MasterPlatypusV4
 */
interface IMasterPlatypusV4 {
    // Info of each user.
    struct UserInfo {
        // 256 bit packed
        uint128 amount; // How many LP tokens the user has provided.
        uint128 factor; // non-dialuting factor = sqrt (lpAmount * vePtp.balanceOf())
        // 256 bit packed
        uint128 rewardDebt; // Reward debt. See explanation below.
        uint128 claimablePtp;
        //
        // We do some fancy math here. Basically, any point in time, the amount of PTPs
        // entitled to a user but is pending to be distributed is:
        //
        //   ((user.amount * pool.accPtpPerShare + user.factor * pool.accPtpPerFactorShare) / 1e12) -
        //        user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accPtpPerShare`, `accPtpPerFactorShare` (and `lastRewardTimestamp`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IAsset lpToken; // Address of LP token contract.
        IBoostedMultiRewarder rewarder;
        uint128 sumOfFactors; // 20.18 fixed point. The sum of all non dialuting factors by all of the users in the pool
        uint128 accPtpPerShare; // 26.12 fixed point. Accumulated PTPs per share, times 1e12.
        uint128 accPtpPerFactorShare; // 26.12 fixed point. Accumulated ptp per factor share
    }

    function platypusTreasure() external view returns (IPlatypusTreasure);

    function getSumOfFactors(uint256) external view returns (uint256);

    function poolLength() external view returns (uint256);

    function getPoolId(address) external view returns (uint256);

    function getUserInfo(uint256 _pid, address _user) external view returns (UserInfo memory);

    function pendingTokens(uint256 _pid, address _user)
        external
        view
        returns (
            uint256 pendingPtp,
            IERC20[] memory bonusTokenAddresses,
            string[] memory bonusTokenSymbols,
            uint256[] memory pendingBonusTokens
        );

    function rewarderBonusTokenInfo(uint256 _pid)
        external
        view
        returns (IERC20[] memory bonusTokenAddresses, string[] memory bonusTokenSymbols);

    function massUpdatePools() external;

    function updatePool(uint256 _pid) external;

    function deposit(uint256 _pid, uint256 _amount)
        external
        returns (uint256 reward, uint256[] memory additionalRewards);

    function depositFor(
        uint256 _pid,
        uint256 _amount,
        address _user
    ) external;

    function multiClaim(uint256[] memory _pids)
        external
        returns (
            uint256 reward,
            uint256[] memory amounts,
            uint256[][] memory additionalRewards
        );

    function withdraw(uint256 _pid, uint256 _amount)
        external
        returns (uint256 reward, uint256[] memory additionalRewards);

    function liquidate(
        uint256 _pid,
        address _user,
        uint256 _amount
    ) external;

    function emergencyWithdraw(uint256 _pid) external;

    function migrate(uint256[] calldata _pids) external;

    function updateFactor(address _user, uint256 _newVePtpBalance) external;

    function notifyRewardAmount(address _lpToken, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IBoostedMultiRewarder {
    function onPtpReward(
        address _user,
        uint256 _lpAmount,
        uint256 _newLpAmount,
        uint256 _factor,
        uint256 _newFactor
    ) external returns (uint256[] memory rewards);

    function onUpdateFactor(
        address _user,
        uint256 _lpAmount,
        uint256 _factor,
        uint256 _newFactor
    ) external;

    function pendingTokens(
        address _user,
        uint256 _lpAmount,
        uint256 _factor
    ) external view returns (uint256[] memory rewards);

    function rewardTokens() external view returns (IERC20[] memory tokens);

    function poolLength() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

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
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/**
 * @dev Interface of Asset
 */
interface IAsset is IERC20 {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function underlyingToken() external view returns (address);

    function underlyingTokenBalance() external view returns (uint256);

    function cash() external view returns (uint256);

    function liability() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IPlatypusTreasure {
    function isSolvent(
        address _user,
        address _token,
        bool _open
    ) external view returns (bool solvent, uint256 debtAmount);
}
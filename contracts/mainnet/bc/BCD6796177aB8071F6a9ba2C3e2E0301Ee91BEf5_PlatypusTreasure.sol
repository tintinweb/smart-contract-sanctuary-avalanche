// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

interface IRewarder {
    function onPtpReward(address user, uint256 newLpAmount) external returns (uint256);

    function pendingTokens(address user) external view returns (uint256 pending);

    function rewardToken() external view returns (IERC20Metadata);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import './IVeERC20.sol';

/**
 * @dev Interface of the VePtp
 */
interface IVePtp is IVeERC20 {
    function isUser(address _addr) external view returns (bool);

    function deposit(uint256 _amount) external;

    function claim() external;

    function claimable(address _addr) external view returns (uint256);

    function claimableWithXp(address _addr) external view returns (uint256 amount, uint256 xp);

    function withdraw(uint256 _amount) external;

    function vePtpBurnedOnWithdraw(address _addr, uint256 _amount) external view returns (uint256);

    function stakeNft(uint256 _tokenId) external;

    function unstakeNft() external;

    function getStakedNft(address _addr) external view returns (uint256);

    function getStakedPtp(address _addr) external view returns (uint256);

    function levelUp(uint256[] memory platypusBurned) external;

    function levelDown() external;

    function getVotes(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IVeERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import '@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

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
 *
 * Note: This contract is backward compatible to OwnableUpgradeable of OZ except from that
 * transferOwnership is dropped.
 * __gap[0] is used as ownerCandidate, as changing storage is not supported yet
 * See https://forum.openzeppelin.com/t/storage-layout-upgrade-with-hardhat-upgrades/14567
 */
contract SafeOwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
        require(owner() == _msgSender(), 'Ownable: caller is not the owner');
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

    function ownerCandidate() public view returns (address) {
        return address(uint160(__gap[0]));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function proposeOwner(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0x0)) revert('ZeroAddress');
        // __gap[0] is used as ownerCandidate
        __gap[0] = uint256(uint160(newOwner));
    }

    function acceptOwnership() external {
        if (ownerCandidate() != msg.sender) revert('Unauthorized');
        _setOwner(msg.sender);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
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

pragma solidity ^0.8.0;

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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../libraries/SafeOwnableUpgradeable.sol';
import '../interfaces/IBribe.sol';

interface IGauge {
    function notifyRewardAmount(IERC20 token, uint256 amount) external;
}

interface IVe {
    function vote(address user, int256 voteDelta) external;
}

// DO NOT DEPLOY IN PRODUCTION
contract MockVoter is Initializable, SafeOwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {
    struct LpTokenInfo {
        uint128 claimable; // 20.18 fixed point. claimable PTP
        uint128 supplyIndex; // 20.18 fixed point. distributed reward per weight
        address gauge;
        bool whitelist;
    }

    uint256 internal constant ACC_TOKEN_PRECISION = 1e15;

    IERC20 public ptp;
    IVe public vePtp;
    IERC20[] public lpTokens; // all LP tokens

    // ptp emission related storage
    uint88 public ptpPerSec; // 8.18 fixed point

    uint128 public index; // 20.18 fixed point. accumulated reward per weight
    uint40 public lastRewardTimestamp;

    // vote related storage
    uint256 public totalWeight;
    mapping(IERC20 => uint256) public weights; // lpToken => weight, equals to sum of votes for a LP token
    mapping(address => mapping(IERC20 => uint256)) public votes; // user address => lpToken => votes
    mapping(IERC20 => LpTokenInfo) internal infos; // lpToken => LpTokenInfo

    // bribe related storage
    mapping(IERC20 => address) public bribes; // lpToken => bribe rewarder

    event UpdateVote(address user, IERC20 lpToken, uint256 amount);
    event DistributeReward(IERC20 lpToken, uint256 amount);

    function initialize(
        IERC20 _ptp,
        IVe _vePtp,
        uint88 _ptpPerSec,
        uint256 _startTimestamp
    ) external initializer {
        require(_startTimestamp <= type(uint40).max, 'timestamp is invalid');
        require(address(_ptp) != address(0), 'vePtp address cannot be zero');
        require(address(_vePtp) != address(0), 'vePtp address cannot be zero');

        __Ownable_init();
        __ReentrancyGuard_init_unchained();

        ptp = _ptp;
        vePtp = _vePtp;
        ptpPerSec = _ptpPerSec;
        lastRewardTimestamp = uint40(_startTimestamp);
    }

    /// @dev this check save more gas than a modifier
    function _checkGaugeExist(IERC20 _lpToken) internal view {
        require(infos[_lpToken].gauge != address(0), 'Voter: Gauge not exist');
    }

    /// @notice returns LP tokens length
    function lpTokenLength() external view returns (uint256) {
        return lpTokens.length;
    }

    /// @notice getter function to return vote of a LP token for a user
    function getUserVotes(address _user, IERC20 _lpToken) external view returns (uint256) {
        return votes[_user][_lpToken];
    }

    /// @notice Add LP token into the Voter
    function add(
        address _gauge,
        IERC20 _lpToken,
        address _bribe
    ) external onlyOwner {
        require(infos[_lpToken].whitelist == false, 'voter: already added');
        require(_gauge != address(0));
        require(address(_lpToken) != address(0));
        require(infos[_lpToken].gauge == address(0), 'Voter: Gauge is already exist');

        infos[_lpToken].whitelist = true;
        infos[_lpToken].gauge = _gauge;
        bribes[_lpToken] = _bribe; // 0 address is allowed
        lpTokens.push(_lpToken);
    }

    function setPtpPerSec(uint88 _ptpPerSec) external onlyOwner {
        require(_ptpPerSec <= 10000e18, 'reward rate too high'); // in case of index overflow
        _distributePtp();
        ptpPerSec = _ptpPerSec;
    }

    /// @notice Pause emission of PTP tokens. Un-distributed rewards are forfeited
    /// Users can still vote/unvote and receive bribes.
    function pause(IERC20 _lpToken) external onlyOwner {
        require(infos[_lpToken].whitelist, 'voter: not whitelisted');
        _checkGaugeExist(_lpToken);

        infos[_lpToken].whitelist = false;
    }

    /// @notice Resume emission of PTP tokens
    function resume(IERC20 _lpToken) external onlyOwner {
        require(infos[_lpToken].whitelist == false, 'voter: not paused');
        _checkGaugeExist(_lpToken);

        // catch up supplyIndex
        _distributePtp();
        infos[_lpToken].supplyIndex = index;
        infos[_lpToken].whitelist = true;
    }

    /// @notice Pause emission of PTP tokens for all assets. Un-distributed rewards are forfeited
    /// Users can still vote/unvote and receive bribes.
    function pauseAll() external onlyOwner {
        _pause();
    }

    /// @notice Resume emission of PTP tokens for all assets
    function resumeAll() external onlyOwner {
        _unpause();
    }

    /// @notice get gauge address for LP token
    function setGauge(IERC20 _lpToken, address _gauge) external onlyOwner {
        require(_gauge != address(0));
        _checkGaugeExist(_lpToken);

        infos[_lpToken].gauge = _gauge;
    }

    /// @notice get bribe address for LP token
    function setBribe(IERC20 _lpToken, address _bribe) external onlyOwner {
        _checkGaugeExist(_lpToken);

        bribes[_lpToken] = _bribe; // 0 address is allowed
    }

    /// @notice Vote and unvote PTP emission for LP tokens.
    /// User can vote/unvote a un-whitelisted pool. But no PTP will be emitted.
    /// Bribes are also distributed by the Bribe contract.
    /// Amount of vote should be checked by vePtp.vote().
    /// This can also used to distribute bribes when _deltas are set to 0
    /// @param _lpVote address to LP tokens to vote
    /// @param _deltas change of vote for each LP tokens
    function vote(IERC20[] calldata _lpVote, int256[] calldata _deltas)
        external
        nonReentrant
        returns (uint256[] memory bribeRewards)
    {
        // 1. call _updateFor() to update PTP emission
        // 2. update related lpToken weight and total lpToken weight
        // 3. update used voting power and ensure there's enough voting power
        // 4. call IBribe.onVote() to update bribes
        require(_lpVote.length == _deltas.length, 'voter: array length not equal');

        // update index
        _distributePtp();

        uint256 voteCnt = _lpVote.length;
        int256 voteDelta;

        bribeRewards = new uint256[](voteCnt);

        for (uint256 i; i < voteCnt; ++i) {
            IERC20 lpToken = _lpVote[i];
            _checkGaugeExist(lpToken);

            int256 delta = _deltas[i];
            uint256 originalWeight = weights[lpToken];
            if (delta != 0) {
                _updateFor(lpToken);

                // update vote and weight
                if (delta > 0) {
                    // vote
                    votes[msg.sender][lpToken] += uint256(delta);
                    weights[lpToken] = originalWeight + uint256(delta);
                    totalWeight += uint256(delta);
                } else {
                    // unvote
                    require(votes[msg.sender][lpToken] >= uint256(-delta), 'voter: vote underflow');
                    votes[msg.sender][lpToken] -= uint256(-delta);
                    weights[lpToken] = originalWeight - uint256(-delta);
                    totalWeight -= uint256(-delta);
                }

                voteDelta += delta;
                emit UpdateVote(msg.sender, lpToken, votes[msg.sender][lpToken]);
            }

            // update bribe
            if (bribes[lpToken] != address(0)) {
                bribeRewards[i] = IBribe(bribes[lpToken]).onVote(
                    msg.sender,
                    votes[msg.sender][lpToken],
                    originalWeight
                );
            }
        }

        // notice vePTP for the new vote, it reverts if vote is invalid
        vePtp.vote(msg.sender, voteDelta);
    }

    /// @notice Claim bribes for LP tokens
    /// @dev This function looks safe from re-entrancy attack
    function claimBribes(IERC20[] calldata _lpTokens) external returns (uint256[] memory bribeRewards) {
        bribeRewards = new uint256[](_lpTokens.length);
        for (uint256 i; i < _lpTokens.length; ++i) {
            IERC20 lpToken = _lpTokens[i];
            _checkGaugeExist(lpToken);
            if (bribes[lpToken] != address(0)) {
                bribeRewards[i] = IBribe(bribes[lpToken]).onVote(
                    msg.sender,
                    votes[msg.sender][lpToken],
                    weights[lpToken]
                );
            }
        }
    }

    /// @notice Get pending bribes for LP tokens
    function pendingBribes(IERC20[] calldata _lpTokens, address _user)
        external
        view
        returns (uint256[] memory bribeRewards)
    {
        bribeRewards = new uint256[](_lpTokens.length);
        for (uint256 i; i < _lpTokens.length; ++i) {
            IERC20 lpToken = _lpTokens[i];
            if (bribes[lpToken] != address(0)) {
                bribeRewards[i] = IBribe(bribes[lpToken]).pendingTokens(_user);
            }
        }
    }

    /// @dev This function looks safe from re-entrancy attack
    function distribute(IERC20 _lpToken) external {
        _distributePtp();
        _updateFor(_lpToken);

        uint256 _claimable = infos[_lpToken].claimable;
        // `_claimable > 0` imples `_checkGaugeExist(_lpToken)`
        // In case PTP is not fueled, it should not create DoS
        if (_claimable > 0 && ptp.balanceOf(address(this)) > _claimable) {
            infos[_lpToken].claimable = 0;
            emit DistributeReward(_lpToken, _claimable);

            ptp.transfer(infos[_lpToken].gauge, _claimable);
            IGauge(infos[_lpToken].gauge).notifyRewardAmount(_lpToken, _claimable);
        }
    }

    /// @notice Update index for accrued PTP
    function _distributePtp() internal {
        if (block.timestamp > lastRewardTimestamp) {
            uint256 secondsElapsed = block.timestamp - lastRewardTimestamp;
            if (totalWeight > 0) {
                index += toUint128((secondsElapsed * ptpPerSec * ACC_TOKEN_PRECISION) / totalWeight);
            }
            lastRewardTimestamp = uint40(block.timestamp);
        }
    }

    /// @notice Update supplyIndex for the LP token
    /// @dev Assumption: gauge exists and is not paused, the caller should verify it
    /// @param _lpToken address of the LP token
    function _updateFor(IERC20 _lpToken) internal {
        uint256 weight = weights[_lpToken];
        if (weight > 0) {
            uint256 _supplyIndex = infos[_lpToken].supplyIndex;
            uint256 _index = index; // get global index for accumulated distro
            uint256 delta = _index - _supplyIndex; // see if there is any difference that need to be accrued
            if (delta > 0) {
                uint256 _share = (weight * delta) / ACC_TOKEN_PRECISION; // add accrued difference for each token
                infos[_lpToken].supplyIndex = toUint128(_index); // update _lpToken current position to global position

                // PTP emission for un-whitelisted lpTokens are blackholed
                // Don't distribute PTP if the contract is paused
                if (infos[_lpToken].whitelist && !paused()) {
                    infos[_lpToken].claimable += toUint128(_share);
                }
            }
        } else {
            infos[_lpToken].supplyIndex = index; // new LP tokens are set to the default global state
        }
    }

    /// @notice Update supplyIndex for the LP token
    function pendingPtp(IERC20 _lpToken) external view returns (uint256) {
        if (infos[_lpToken].whitelist == false || paused()) return 0;
        uint256 _secondsElapsed = block.timestamp - lastRewardTimestamp;
        uint256 _index = index + (_secondsElapsed * ptpPerSec * ACC_TOKEN_PRECISION) / totalWeight;
        uint256 _supplyIndex = infos[_lpToken].supplyIndex;
        uint256 _delta = _index - _supplyIndex;
        uint256 _claimable = infos[_lpToken].claimable + (weights[_lpToken] * _delta) / ACC_TOKEN_PRECISION;
        return _claimable;
    }

    /// @notice In case we need to manually migrate PTP funds from Voter
    /// Sends all remaining ptp from the contract to the owner
    function emergencyPtpWithdraw() external onlyOwner {
        // SafeERC20 is not needed as PTP will revert if transfer fails
        ptp.transfer(address(msg.sender), ptp.balanceOf(address(this)));
    }

    function toUint128(uint256 val) internal pure returns (uint128) {
        require(val <= type(uint128).max, 'uint128 overflow');
        return uint128(val);
    }

    // MOCK FUNCTION
    function resetVotes(address _user, IERC20 _lpToken) external onlyOwner {
        votes[_user][_lpToken] = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@rari-capital/solmate/src/tokens/ERC20.sol';

interface IBribe {
    function onVote(
        address user,
        uint256 newVote,
        uint256 originalTotalVotes
    ) external returns (uint256);

    function pendingTokens(address user) external view returns (uint256 pending);

    function rewardToken() external view returns (ERC20);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../libraries/SafeOwnableUpgradeable.sol';
import '../interfaces/IBribe.sol';

interface IGauge {
    function notifyRewardAmount(IERC20 token, uint256 amount) external;
}

interface IVe {
    function vote(address user, int256 voteDelta) external;
}

/// Voter can handle gauge voting. PTP rewards are distributed to different MasterPlatypus->LpToken
/// according the voting weight.Only whitelisted lpTokens can be voted against.
///
/// The flow to distribute reward:
/// 1. At the beginning of MasterPlatypus.updateFactor/deposit/withdraw, Voter.distribute(lpToken) is called
/// 2. PTP index is updated, and corresponding PTP accumulated over this period is sent to the MasterPlatypus
///    via MasterPlatypus.notifyRewardAmount(IERC20 _lpToken, uint256 _amount)
/// 3. MasterPlatypus will updates the corresponding pool.accPtpPerShare and pool.accPtpPerFactorShare
///
/// The flow of bribing:
/// 1. When a user vote/unvote, bribe.onVote is called, where the bribe
///    contract works as a similar way to the Rewarder.
///
/// Note: This should also works with boosted pool. But it doesn't work with interest rate model
/// Note 2: Please refer to the comment of BaseMasterPlatypusV2.notifyRewardAmount for front-running risk
contract Voter is Initializable, SafeOwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {
    struct LpTokenInfo {
        uint128 claimable; // 20.18 fixed point. claimable PTP
        uint128 supplyIndex; // 20.18 fixed point. distributed reward per weight
        address gauge;
        bool whitelist;
    }

    uint256 internal constant ACC_TOKEN_PRECISION = 1e15;

    IERC20 public ptp;
    IVe public vePtp;
    IERC20[] public lpTokens; // all LP tokens

    // ptp emission related storage
    uint88 public ptpPerSec; // 8.18 fixed point

    uint128 public index; // 20.18 fixed point. accumulated reward per weight
    uint40 public lastRewardTimestamp;

    // vote related storage
    uint256 public totalWeight;
    mapping(IERC20 => uint256) public weights; // lpToken => weight, equals to sum of votes for a LP token
    mapping(address => mapping(IERC20 => uint256)) public votes; // user address => lpToken => votes
    mapping(IERC20 => LpTokenInfo) internal infos; // lpToken => LpTokenInfo

    // bribe related storage
    mapping(IERC20 => address) public bribes; // lpToken => bribe rewarder

    event UpdateVote(address user, IERC20 lpToken, uint256 amount);
    event DistributeReward(IERC20 lpToken, uint256 amount);

    function initialize(
        IERC20 _ptp,
        IVe _vePtp,
        uint88 _ptpPerSec,
        uint256 _startTimestamp
    ) external initializer {
        require(_startTimestamp <= type(uint40).max, 'timestamp is invalid');
        require(address(_ptp) != address(0), 'vePtp address cannot be zero');
        require(address(_vePtp) != address(0), 'vePtp address cannot be zero');

        __Ownable_init();
        __ReentrancyGuard_init_unchained();

        ptp = _ptp;
        vePtp = _vePtp;
        ptpPerSec = _ptpPerSec;
        lastRewardTimestamp = uint40(_startTimestamp);
    }

    /// @dev this check save more gas than a modifier
    function _checkGaugeExist(IERC20 _lpToken) internal view {
        require(infos[_lpToken].gauge != address(0), 'Voter: Gauge not exist');
    }

    /// @notice returns LP tokens length
    function lpTokenLength() external view returns (uint256) {
        return lpTokens.length;
    }

    /// @notice getter function to return vote of a LP token for a user
    function getUserVotes(address _user, IERC20 _lpToken) external view returns (uint256) {
        return votes[_user][_lpToken];
    }

    /// @notice Add LP token into the Voter
    function add(
        address _gauge,
        IERC20 _lpToken,
        address _bribe
    ) external onlyOwner {
        require(infos[_lpToken].whitelist == false, 'voter: already added');
        require(_gauge != address(0));
        require(address(_lpToken) != address(0));
        require(infos[_lpToken].gauge == address(0), 'Voter: Gauge is already exist');

        infos[_lpToken].whitelist = true;
        infos[_lpToken].gauge = _gauge;
        bribes[_lpToken] = _bribe; // 0 address is allowed
        lpTokens.push(_lpToken);
    }

    function setPtpPerSec(uint88 _ptpPerSec) external onlyOwner {
        require(_ptpPerSec <= 10000e18, 'reward rate too high'); // in case of index overflow
        _distributePtp();
        ptpPerSec = _ptpPerSec;
    }

    /// @notice Pause emission of PTP tokens. Un-distributed rewards are forfeited
    /// Users can still vote/unvote and receive bribes.
    function pause(IERC20 _lpToken) external onlyOwner {
        require(infos[_lpToken].whitelist, 'voter: not whitelisted');
        _checkGaugeExist(_lpToken);

        infos[_lpToken].whitelist = false;
    }

    /// @notice Resume emission of PTP tokens
    function resume(IERC20 _lpToken) external onlyOwner {
        require(infos[_lpToken].whitelist == false, 'voter: not paused');
        _checkGaugeExist(_lpToken);

        // catch up supplyIndex
        _distributePtp();
        infos[_lpToken].supplyIndex = index;
        infos[_lpToken].whitelist = true;
    }

    /// @notice Pause emission of PTP tokens for all assets. Un-distributed rewards are forfeited
    /// Users can still vote/unvote and receive bribes.
    function pauseAll() external onlyOwner {
        _pause();
    }

    /// @notice Resume emission of PTP tokens for all assets
    function resumeAll() external onlyOwner {
        _unpause();
    }

    /// @notice get gauge address for LP token
    function setGauge(IERC20 _lpToken, address _gauge) external onlyOwner {
        require(_gauge != address(0));
        _checkGaugeExist(_lpToken);

        infos[_lpToken].gauge = _gauge;
    }

    /// @notice get bribe address for LP token
    function setBribe(IERC20 _lpToken, address _bribe) external onlyOwner {
        _checkGaugeExist(_lpToken);

        bribes[_lpToken] = _bribe; // 0 address is allowed
    }

    /// @notice Vote and unvote PTP emission for LP tokens.
    /// User can vote/unvote a un-whitelisted pool. But no PTP will be emitted.
    /// Bribes are also distributed by the Bribe contract.
    /// Amount of vote should be checked by vePtp.vote().
    /// This can also used to distribute bribes when _deltas are set to 0
    /// @param _lpVote address to LP tokens to vote
    /// @param _deltas change of vote for each LP tokens
    function vote(IERC20[] calldata _lpVote, int256[] calldata _deltas)
        external
        nonReentrant
        returns (uint256[] memory bribeRewards)
    {
        // 1. call _updateFor() to update PTP emission
        // 2. update related lpToken weight and total lpToken weight
        // 3. update used voting power and ensure there's enough voting power
        // 4. call IBribe.onVote() to update bribes
        require(_lpVote.length == _deltas.length, 'voter: array length not equal');

        // update index
        _distributePtp();

        uint256 voteCnt = _lpVote.length;
        int256 voteDelta;

        bribeRewards = new uint256[](voteCnt);

        for (uint256 i; i < voteCnt; ++i) {
            IERC20 lpToken = _lpVote[i];
            _checkGaugeExist(lpToken);

            int256 delta = _deltas[i];
            uint256 originalWeight = weights[lpToken];
            if (delta != 0) {
                _updateFor(lpToken);

                // update vote and weight
                if (delta > 0) {
                    // vote
                    votes[msg.sender][lpToken] += uint256(delta);
                    weights[lpToken] = originalWeight + uint256(delta);
                    totalWeight += uint256(delta);
                } else {
                    // unvote
                    require(votes[msg.sender][lpToken] >= uint256(-delta), 'voter: vote underflow');
                    votes[msg.sender][lpToken] -= uint256(-delta);
                    weights[lpToken] = originalWeight - uint256(-delta);
                    totalWeight -= uint256(-delta);
                }

                voteDelta += delta;
                emit UpdateVote(msg.sender, lpToken, votes[msg.sender][lpToken]);
            }

            // update bribe
            if (bribes[lpToken] != address(0)) {
                bribeRewards[i] = IBribe(bribes[lpToken]).onVote(
                    msg.sender,
                    votes[msg.sender][lpToken],
                    originalWeight
                );
            }
        }

        // notice vePTP for the new vote, it reverts if vote is invalid
        vePtp.vote(msg.sender, voteDelta);
    }

    /// @notice Claim bribes for LP tokens
    /// @dev This function looks safe from re-entrancy attack
    function claimBribes(IERC20[] calldata _lpTokens) external returns (uint256[] memory bribeRewards) {
        bribeRewards = new uint256[](_lpTokens.length);
        for (uint256 i; i < _lpTokens.length; ++i) {
            IERC20 lpToken = _lpTokens[i];
            _checkGaugeExist(lpToken);
            if (bribes[lpToken] != address(0)) {
                bribeRewards[i] = IBribe(bribes[lpToken]).onVote(
                    msg.sender,
                    votes[msg.sender][lpToken],
                    weights[lpToken]
                );
            }
        }
    }

    /// @notice Get pending bribes for LP tokens
    function pendingBribes(IERC20[] calldata _lpTokens, address _user)
        external
        view
        returns (uint256[] memory bribeRewards)
    {
        bribeRewards = new uint256[](_lpTokens.length);
        for (uint256 i; i < _lpTokens.length; ++i) {
            IERC20 lpToken = _lpTokens[i];
            if (bribes[lpToken] != address(0)) {
                bribeRewards[i] = IBribe(bribes[lpToken]).pendingTokens(_user);
            }
        }
    }

    /// @dev This function looks safe from re-entrancy attack
    function distribute(IERC20 _lpToken) external {
        _distributePtp();
        _updateFor(_lpToken);

        uint256 _claimable = infos[_lpToken].claimable;
        // `_claimable > 0` imples `_checkGaugeExist(_lpToken)`
        // In case PTP is not fueled, it should not create DoS
        if (_claimable > 0 && ptp.balanceOf(address(this)) > _claimable) {
            infos[_lpToken].claimable = 0;
            emit DistributeReward(_lpToken, _claimable);

            ptp.transfer(infos[_lpToken].gauge, _claimable);
            IGauge(infos[_lpToken].gauge).notifyRewardAmount(_lpToken, _claimable);
        }
    }

    /// @notice Update index for accrued PTP
    function _distributePtp() internal {
        if (block.timestamp > lastRewardTimestamp) {
            uint256 secondsElapsed = block.timestamp - lastRewardTimestamp;
            if (totalWeight > 0) {
                index += toUint128((secondsElapsed * ptpPerSec * ACC_TOKEN_PRECISION) / totalWeight);
            }
            lastRewardTimestamp = uint40(block.timestamp);
        }
    }

    /// @notice Update supplyIndex for the LP token
    /// @dev Assumption: gauge exists and is not paused, the caller should verify it
    /// @param _lpToken address of the LP token
    function _updateFor(IERC20 _lpToken) internal {
        uint256 weight = weights[_lpToken];
        if (weight > 0) {
            uint256 _supplyIndex = infos[_lpToken].supplyIndex;
            uint256 _index = index; // get global index for accumulated distro
            uint256 delta = _index - _supplyIndex; // see if there is any difference that need to be accrued
            if (delta > 0) {
                uint256 _share = (weight * delta) / ACC_TOKEN_PRECISION; // add accrued difference for each token
                infos[_lpToken].supplyIndex = toUint128(_index); // update _lpToken current position to global position

                // PTP emission for un-whitelisted lpTokens are blackholed
                // Don't distribute PTP if the contract is paused
                if (infos[_lpToken].whitelist && !paused()) {
                    infos[_lpToken].claimable += toUint128(_share);
                }
            }
        } else {
            infos[_lpToken].supplyIndex = index; // new LP tokens are set to the default global state
        }
    }

    /// @notice Update supplyIndex for the LP token
    function pendingPtp(IERC20 _lpToken) external view returns (uint256) {
        if (infos[_lpToken].whitelist == false || paused()) return 0;
        uint256 _secondsElapsed = block.timestamp - lastRewardTimestamp;
        uint256 _index = index;
        if (totalWeight > 0) {
            _index += (_secondsElapsed * ptpPerSec * ACC_TOKEN_PRECISION) / totalWeight;
        }

        uint256 _supplyIndex = infos[_lpToken].supplyIndex;
        uint256 _delta = _index - _supplyIndex;
        uint256 _claimable = infos[_lpToken].claimable + (weights[_lpToken] * _delta) / ACC_TOKEN_PRECISION;
        return _claimable;
    }

    /// @notice In case we need to manually migrate PTP funds from Voter
    /// Sends all remaining ptp from the contract to the owner
    function emergencyPtpWithdraw() external onlyOwner {
        // SafeERC20 is not needed as PTP will revert if transfer fails
        ptp.transfer(address(msg.sender), ptp.balanceOf(address(this)));
    }

    function toUint128(uint256 val) internal pure returns (uint128) {
        require(val <= type(uint128).max, 'uint128 overflow');
        return uint128(val);
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.14;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import './MultiRewarderPerSec.sol';

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
 * - Resets token per sec to zero if token balance cannot fullfill rewards that are due
 */
contract MultiRewarderPerSecV2 is MultiRewarderPerSec {
    using SafeERC20 for IERC20;

    constructor(
        IMasterPlatypusV4 _MP,
        IERC20 _lpToken,
        uint256 _startTimestamp,
        IERC20 _rewardToken,
        uint96 _tokenPerSec
    ) MultiRewarderPerSec(_MP, _lpToken, _startTimestamp, _rewardToken, _tokenPerSec) {}

    /// @notice Sets the distribution reward rate. This will also update the poolInfo.
    /// @param _tokenPerSec The number of tokens to distribute per second
    function setRewardRate(uint256 _tokenId, uint96 _tokenPerSec) external override onlyOperatorOrOwner {
        require(_tokenPerSec <= 10000e18, 'reward rate too high'); // in case of accTokenPerShare overflow
        _setRewardRate(_tokenId, _tokenPerSec);
    }

    function _setRewardRate(uint256 _tokenId, uint96 _tokenPerSec) internal {
        _updatePool();

        uint256 oldRate = poolInfo[_tokenId].tokenPerSec;
        poolInfo[_tokenId].tokenPerSec = _tokenPerSec;

        emit RewardRateUpdated(address(poolInfo[_tokenId].rewardToken), oldRate, _tokenPerSec);
    }

    /// @notice Function called by MasterPlatypus whenever staker claims PTP harvest.
    /// @notice Allows staker to also receive a 2nd reward token.
    /// @dev Assume lpSupply and sumOfFactors isn't updated yet when this function is called
    /// @param _user Address of user
    /// @param _lpAmount The ORIGINAL amount of LP tokens the user has
    /// @param _newLpAmount The new amount of LP
    function onPtpReward(
        address _user,
        uint256 _lpAmount,
        uint256 _newLpAmount
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
                uint256 pending = ((_lpAmount * pool.accTokenPerShare) / ACC_TOKEN_PRECISION) +
                    user.claimable -
                    user.rewardDebt;

                if (address(rewardToken) == address(0)) {
                    // is native token
                    uint256 tokenBalance = address(this).balance;
                    if (pending >= tokenBalance) {
                        (bool success, ) = _user.call{value: tokenBalance}('');
                        require(success, 'Transfer failed');
                        rewards[i] = tokenBalance;
                        user.claimable = toUint128(pending - tokenBalance);
                        // In case partners forget to replenish token, pause token emission
                        // Note that some accumulated rewards might not be able to distribute
                        _setRewardRate(i, 0);
                    } else {
                        (bool success, ) = _user.call{value: pending}('');
                        require(success, 'Transfer failed');
                        rewards[i] = pending;
                        user.claimable = 0;
                    }
                } else {
                    // ERC20 token
                    uint256 tokenBalance = rewardToken.balanceOf(address(this));
                    if (pending >= tokenBalance) {
                        rewardToken.safeTransfer(_user, tokenBalance);
                        rewards[i] = tokenBalance;
                        user.claimable = toUint128(pending - tokenBalance);
                        // In case partners forget to replenish token, pause token emission
                        // Note that some accumulated rewards might not be able to distribute
                        _setRewardRate(i, 0);
                    } else {
                        rewardToken.safeTransfer(_user, pending);
                        rewards[i] = pending;
                        user.claimable = 0;
                    }
                }
            }

            user.rewardDebt = toUint128((_newLpAmount * pool.accTokenPerShare) / ACC_TOKEN_PRECISION);
            emit OnReward(address(rewardToken), _user, rewards[i]);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.14;

import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import '../interfaces/IMasterPlatypusV4.sol';
import '../interfaces/IMultiRewarder.sol';

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
 */
contract MultiRewarderPerSec is IMultiRewarder, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 internal constant ACC_TOKEN_PRECISION = 1e12;
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
        uint128 accTokenPerShare; // 26.12 fixed point. Amount of reward token each LP token is worth.
    }

    /// @notice address of the operator
    /// @dev operator is able to set emission rate
    address public operator;

    uint256 public lastRewardTimestamp;

    /// @notice Info of the poolInfo.
    PoolInfo[] public poolInfo;
    /// @notice tokenId => userId => UserInfo
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    event OnReward(address indexed rewardToken, address indexed user, uint256 amount);
    event RewardRateUpdated(address indexed rewardToken, uint256 oldRate, uint256 newRate);

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
        uint256 _startTimestamp,
        IERC20 _rewardToken,
        uint96 _tokenPerSec
    ) {
        require(
            Address.isContract(address(_rewardToken)) || address(_rewardToken) == address(0),
            'constructor: reward token must be a valid contract'
        );
        require(Address.isContract(address(_lpToken)), 'constructor: LP token must be a valid contract');
        require(Address.isContract(address(_MP)), 'constructor: MasterPlatypus must be a valid contract');
        // require(_startTimestamp >= block.timestamp);

        MP = _MP;
        lpToken = _lpToken;

        lastRewardTimestamp = _startTimestamp;

        // use non-zero amount for accTokenPerShare as we want to check if user
        // has activated the pool by checking rewardDebt > 0
        PoolInfo memory pool = PoolInfo({rewardToken: _rewardToken, tokenPerSec: _tokenPerSec, accTokenPerShare: 1e18});
        poolInfo.push(pool);
        emit RewardRateUpdated(address(_rewardToken), 0, _tokenPerSec);
    }

    /// @notice Set operator address
    function setOperator(address _operator) external onlyOwner {
        operator = _operator;
    }

    function addRewardToken(IERC20 _rewardToken, uint96 _tokenPerSec) external onlyOwner {
        _updatePool();
        // use non-zero amount for accTokenPerShare as we want to check if user
        // has activated the pool by checking rewardDebt > 0
        PoolInfo memory pool = PoolInfo({rewardToken: _rewardToken, tokenPerSec: _tokenPerSec, accTokenPerShare: 1e18});
        poolInfo.push(pool);
        emit RewardRateUpdated(address(_rewardToken), 0, _tokenPerSec);
    }

    /// @dev This function should be called before lpSupply and sumOfFactors update
    function _updatePool() internal {
        uint256 length = poolInfo.length;
        uint256 lpSupply = lpToken.balanceOf(address(MP));

        if (block.timestamp > lastRewardTimestamp && lpSupply > 0) {
            for (uint256 i; i < length; ++i) {
                PoolInfo storage pool = poolInfo[i];
                uint256 timeElapsed = block.timestamp - lastRewardTimestamp;
                uint256 tokenReward = timeElapsed * pool.tokenPerSec;
                pool.accTokenPerShare += toUint128((tokenReward * ACC_TOKEN_PRECISION) / lpSupply);
            }

            lastRewardTimestamp = block.timestamp;
        }
    }

    /// @notice Sets the distribution reward rate. This will also update the poolInfo.
    /// @param _tokenPerSec The number of tokens to distribute per second
    function setRewardRate(uint256 _tokenId, uint96 _tokenPerSec) external virtual onlyOperatorOrOwner {
        require(_tokenPerSec <= 10000e18, 'reward rate too high'); // in case of accTokenPerShare overflow
        _updatePool();

        uint256 oldRate = poolInfo[_tokenId].tokenPerSec;
        poolInfo[_tokenId].tokenPerSec = _tokenPerSec;

        emit RewardRateUpdated(address(poolInfo[_tokenId].rewardToken), oldRate, _tokenPerSec);
    }

    /// @notice Function called by MasterPlatypus whenever staker claims PTP harvest.
    /// @notice Allows staker to also receive a 2nd reward token.
    /// @dev Assume lpSupply and sumOfFactors isn't updated yet when this function is called
    /// @param _user Address of user
    /// @param _lpAmount The ORIGINAL amount of LP tokens the user has
    /// @param _newLpAmount The new amount of LP
    function onPtpReward(
        address _user,
        uint256 _lpAmount,
        uint256 _newLpAmount
    ) external virtual override onlyMP nonReentrant returns (uint256[] memory rewards) {
        _updatePool();

        uint256 length = poolInfo.length;
        rewards = new uint256[](length);
        for (uint256 i; i < length; ++i) {
            PoolInfo storage pool = poolInfo[i];
            UserInfo storage user = userInfo[i][_user];
            IERC20 rewardToken = pool.rewardToken;

            // if user has activated the pool, update rewards
            if (user.rewardDebt > 0) {
                uint256 pending = ((_lpAmount * pool.accTokenPerShare) / ACC_TOKEN_PRECISION) +
                    user.claimable -
                    user.rewardDebt;

                if (address(rewardToken) == address(0)) {
                    // is native token
                    uint256 tokenBalance = address(this).balance;
                    if (pending > tokenBalance) {
                        (bool success, ) = _user.call{value: tokenBalance}('');
                        require(success, 'Transfer failed');
                        rewards[i] = tokenBalance;
                        user.claimable = toUint128(pending - tokenBalance);
                    } else {
                        (bool success, ) = _user.call{value: pending}('');
                        require(success, 'Transfer failed');
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

            user.rewardDebt = toUint128((_newLpAmount * pool.accTokenPerShare) / ACC_TOKEN_PRECISION);
            emit OnReward(address(rewardToken), _user, rewards[i]);
        }
    }

    /// @notice returns pool length
    function poolLength() external view override returns (uint256) {
        return poolInfo.length;
    }

    /// @notice View function to see pending tokens
    /// @param _user Address of user.
    /// @return rewards reward for a given user.
    function pendingTokens(address _user, uint256 _lpAmount) external view override returns (uint256[] memory rewards) {
        uint256 length = poolInfo.length;
        rewards = new uint256[](length);

        for (uint256 i; i < length; ++i) {
            PoolInfo memory pool = poolInfo[i];
            UserInfo storage user = userInfo[i][_user];

            uint256 accTokenPerShare = pool.accTokenPerShare;
            uint256 lpSupply = lpToken.balanceOf(address(MP));

            if (block.timestamp > lastRewardTimestamp && lpSupply > 0) {
                uint256 timeElapsed = block.timestamp - lastRewardTimestamp;
                uint256 tokenReward = timeElapsed * pool.tokenPerSec;
                accTokenPerShare += (tokenReward * ACC_TOKEN_PRECISION) / lpSupply;
            }

            rewards[i] = ((_lpAmount * accTokenPerShare) / ACC_TOKEN_PRECISION) - user.rewardDebt + user.claimable;
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

interface IMultiRewarder {
    function onPtpReward(
        address _user,
        uint256 _lpAmount,
        uint256 _newLpAmount
    ) external returns (uint256[] memory rewards);

    function pendingTokens(address _user, uint256 _lpAmount) external view returns (uint256[] memory rewards);

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
pragma solidity ^0.8.9;

interface IPlatypusTreasure {
    function isSolvent(
        address _user,
        address _token,
        bool _open
    ) external view returns (bool solvent, uint256 debtAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import './libraries/SafeOwnableUpgradeable.sol';
import './interfaces/IAsset.sol';
import './interfaces/IBaseMasterPlatypusV2.sol';
import './interfaces/IMultiRewarder.sol';

interface IVoter {
    function distribute(address _lpToken) external;

    function pendingPtp(address _lpToken) external view returns (uint256);
}

/// BaseMasterPlatypus is a boss. He says "go f your blocks maki boy, I'm gonna use timestamp instead"
/// Note that it's ownable and the owner wields tremendous power. The ownership
/// will be transferred to a governance smart contract once Platypus is sufficiently
/// distributed and the community can show to govern itself.
/// Changes:
/// - Removed intrate model
/// - Removed vePTP boost
/// - obtain PTP from voter
contract BaseMasterPlatypusV2 is
    Initializable,
    SafeOwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    IBaseMasterPlatypusV2
{
    using EnumerableSet for EnumerableSet.AddressSet;

    // Info of each user.
    struct UserInfo {
        uint128 amount; // 20.18 fixed point. How many LP tokens the user has provided.
        uint128 rewardDebt; // 26.12 fixed point. Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of PTPs
        // entitled to a user but is pending to be distributed is:
        //
        //   ((user.amount * pool.accPtpPerShare / 1e12) -
        //        user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accPtpPerShare` gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IAsset lpToken; // Address of LP token contract.
        IMultiRewarder rewarder;
        uint256 accPtpPerShare; // Accumulated PTPs per share, times 1e12.
    }

    // The strongest platypus out there (ptp token).
    IERC20 public ptp;
    // New Master Platypus address for future migrations
    IBaseMasterPlatypusV2 newMasterPlatypus;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Set of all LP tokens that have been added as pools
    EnumerableSet.AddressSet private lpTokens;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    address public voter;

    event Add(uint256 indexed pid, IERC20 indexed lpToken, IMultiRewarder indexed rewarder);
    event SetRewarder(uint256 indexed pid, IMultiRewarder indexed rewarder);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event DepositFor(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    function initialize(IERC20 _ptp, address _voter) external initializer {
        require(address(_ptp) != address(0), 'ptp address cannot be zero');

        __Ownable_init();
        __ReentrancyGuard_init_unchained();
        __Pausable_init_unchained();

        ptp = _ptp;
        voter = _voter;
    }

    /**
     * @dev pause pool, restricting certain operations
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev unpause pool, enabling certain operations
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    function setNewMasterPlatypus(IBaseMasterPlatypusV2 _newMasterPlatypus) external onlyOwner {
        newMasterPlatypus = _newMasterPlatypus;
    }

    /// @notice returns pool length
    function poolLength() external view override returns (uint256) {
        return poolInfo.length;
    }

    /// @notice Add a new lp to the pool. Can only be called by the owner.
    /// @dev Reverts if the same LP token is added more than once.
    /// @param _lpToken the corresponding lp token
    /// @param _rewarder the rewarder
    function add(IAsset _lpToken, IMultiRewarder _rewarder) public onlyOwner {
        require(Address.isContract(address(_lpToken)), 'add: LP token must be a valid contract');
        require(
            Address.isContract(address(_rewarder)) || address(_rewarder) == address(0),
            'add: rewarder must be contract or zero'
        );
        require(!lpTokens.contains(address(_lpToken)), 'add: LP already added');

        // update PoolInfo with the new LP
        poolInfo.push(PoolInfo({lpToken: _lpToken, accPtpPerShare: 0, rewarder: _rewarder}));

        // add lpToken to the lpTokens enumerable set
        lpTokens.add(address(_lpToken));
        emit Add(poolInfo.length - 1, IERC20(_lpToken), _rewarder);
    }

    /// @notice Update the given pool's rewarder
    /// @param _pid the pool id
    /// @param _rewarder the rewarder
    function setRewarder(uint256 _pid, IMultiRewarder _rewarder) public onlyOwner {
        require(
            Address.isContract(address(_rewarder)) || address(_rewarder) == address(0),
            'set: rewarder must be contract or zero'
        );

        PoolInfo storage pool = poolInfo[_pid];

        pool.rewarder = _rewarder;
        emit SetRewarder(_pid, _rewarder);
    }

    /// @notice Get bonus token info from the rewarder contract for a given pool, if it is a double reward farm
    /// @param _pid the pool id
    function rewarderBonusTokenInfo(uint256 _pid)
        public
        view
        override
        returns (IERC20[] memory bonusTokenAddresses, string[] memory bonusTokenSymbols)
    {
        PoolInfo storage pool = poolInfo[_pid];
        if (address(pool.rewarder) == address(0)) {
            return (bonusTokenAddresses, bonusTokenSymbols);
        }

        bonusTokenAddresses = pool.rewarder.rewardTokens();

        uint256 len = bonusTokenAddresses.length;
        bonusTokenSymbols = new string[](len);
        for (uint256 i; i < len; ++i) {
            if (address(bonusTokenAddresses[i]) == address(0)) {
                bonusTokenSymbols[i] = 'AVAX';
            } else {
                bonusTokenSymbols[i] = IERC20Metadata(address(bonusTokenAddresses[i])).symbol();
            }
        }
    }

    /// @notice Update reward variables for all pools.
    /// @dev Be careful of gas spending!
    function massUpdatePools() external override {
        uint256 length = poolInfo.length;
        for (uint256 pid; pid < length; ++pid) {
            _updatePool(pid);
        }
    }

    /// @notice Update reward variables of the given pool to be up-to-date.
    /// @param _pid the pool id
    function updatePool(uint256 _pid) external override {
        _updatePool(_pid);
    }

    function _updatePool(uint256 _pid) private {
        PoolInfo storage pool = poolInfo[_pid];
        IVoter(voter).distribute(address(pool.lpToken));
    }

    /// @dev We might distribute PTP over a period of time to prevent front-running
    /// Refer to synthetix/StakingRewards.sol notifyRewardAmount
    /// Note: This looks safe from reentrancy.
    function notifyRewardAmount(address _lpToken, uint256 _amount) external override {
        require(_amount > 0, 'MasterPlatypus: zero amount');
        require(msg.sender == voter, 'MasterPlatypus: only voter');

        // this line reverts if asset is not in the list
        uint256 pid = lpTokens._inner._indexes[bytes32(uint256(uint160(_lpToken)))] - 1;
        PoolInfo storage pool = poolInfo[pid];

        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            return;
        }

        pool.accPtpPerShare += (_amount * 1e12) / lpSupply;

        // No event is not emitted. as Voter should have already emitted it
    }

    /// @notice Helper function to migrate fund from multiple pools to the new MasterPlatypus.
    /// @notice user must initiate transaction from masterchef
    /// @dev Assume the orginal MasterPlatypus has stopped emisions
    /// hence we skip IVoter(voter).distribute() to save gas cost
    function migrate(uint256[] calldata _pids) external override nonReentrant {
        require(address(newMasterPlatypus) != (address(0)), 'to where?');

        _multiClaim(_pids);
        for (uint256 i; i < _pids.length; ++i) {
            uint256 pid = _pids[i];
            UserInfo storage user = userInfo[pid][msg.sender];

            if (user.amount > 0) {
                PoolInfo storage pool = poolInfo[pid];
                pool.lpToken.approve(address(newMasterPlatypus), user.amount);
                newMasterPlatypus.depositFor(pid, user.amount, msg.sender);

                // remove user
                delete userInfo[pid][msg.sender];
            }
        }
    }

    /// @notice Deposit LP tokens to MasterChef for PTP allocation on behalf of user
    /// @dev user must initiate transaction from masterchef
    /// @param _pid the pool id
    /// @param _amount amount to deposit
    /// @param _user the user being represented
    function depositFor(
        uint256 _pid,
        uint256 _amount,
        address _user
    ) external override nonReentrant whenNotPaused {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        // update pool in case user has deposited
        IVoter(voter).distribute(address(pool.lpToken));
        _updateFor(_pid, _user, user.amount + _amount);

        // SafeERC20 is not needed as Asset will revert if transfer fails
        pool.lpToken.transferFrom(msg.sender, address(this), _amount);
        emit DepositFor(_user, _pid, _amount);
    }

    /// @notice Deposit LP tokens to MasterChef for PTP allocation.
    /// @dev it is possible to call this function with _amount == 0 to claim current rewards
    /// @param _pid the pool id
    /// @param _amount amount to deposit
    function deposit(uint256 _pid, uint256 _amount)
        external
        override
        nonReentrant
        whenNotPaused
        returns (uint256 reward, uint256[] memory additionalRewards)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        IVoter(voter).distribute(address(pool.lpToken));
        (reward, additionalRewards) = _updateFor(_pid, msg.sender, user.amount + _amount);

        // SafeERC20 is not needed as Asset will revert if transfer fails
        pool.lpToken.transferFrom(address(msg.sender), address(this), _amount);
        emit Deposit(msg.sender, _pid, _amount);
        return (reward, additionalRewards);
    }

    /// @notice claims rewards for multiple pids
    /// @param _pids array pids, pools to claim
    function multiClaim(uint256[] calldata _pids)
        external
        override
        nonReentrant
        whenNotPaused
        returns (
            uint256 reward,
            uint256[] memory amounts,
            uint256[][] memory additionalRewards
        )
    {
        return _multiClaim(_pids);
    }

    /// @notice private function to claim rewards for multiple pids
    /// @param _pids array pids, pools to claim
    function _multiClaim(uint256[] memory _pids)
        private
        returns (
            uint256 reward,
            uint256[] memory amounts,
            uint256[][] memory additionalRewards
        )
    {
        amounts = new uint256[](_pids.length);
        additionalRewards = new uint256[][](_pids.length);
        for (uint256 i; i < _pids.length; ++i) {
            PoolInfo storage pool = poolInfo[_pids[i]];
            IVoter(voter).distribute(address(pool.lpToken));

            UserInfo storage user = userInfo[_pids[i]][msg.sender];
            if (user.amount > 0) {
                // increase pending to send all rewards once
                uint256 poolRewards = ((user.amount * pool.accPtpPerShare) / 1e12) - user.rewardDebt;

                // update reward debt
                user.rewardDebt = toUint128((user.amount * pool.accPtpPerShare) / 1e12);

                // increase reward
                reward += poolRewards;

                amounts[i] = poolRewards;
                emit Harvest(msg.sender, _pids[i], amounts[i]);

                // if existant, get external rewarder rewards for pool
                IMultiRewarder rewarder = pool.rewarder;
                if (address(rewarder) != address(0)) {
                    additionalRewards[i] = rewarder.onPtpReward(msg.sender, user.amount, user.amount);
                }
            }
        }
        // SafeERC20 is not needed as PTP will revert if transfer fails
        ptp.transfer(payable(msg.sender), reward);
    }

    /// @notice View function to see pending PTPs on frontend.
    /// @param _pid the pool id
    /// @param _user the user address
    function pendingTokens(uint256 _pid, address _user)
        external
        view
        override
        returns (
            uint256 pendingPtp,
            IERC20[] memory bonusTokenAddresses,
            string[] memory bonusTokenSymbols,
            uint256[] memory pendingBonusTokens
        )
    {
        PoolInfo storage pool = poolInfo[_pid];

        // get _accPtpPerShare
        uint256 pendingPtpForLp = IVoter(voter).pendingPtp(address(pool.lpToken));
        uint256 _accPtpPerShare = pool.accPtpPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply != 0) {
            _accPtpPerShare += (pendingPtpForLp * 1e12) / lpSupply;
        }

        // get pendingPtp
        UserInfo storage user = userInfo[_pid][_user];
        pendingPtp = ((user.amount * _accPtpPerShare) / 1e12) - user.rewardDebt;

        (bonusTokenAddresses, bonusTokenSymbols) = rewarderBonusTokenInfo(_pid);

        // get pendingBonusToken
        IMultiRewarder rewarder = pool.rewarder;
        if (address(rewarder) != address(0)) {
            pendingBonusTokens = rewarder.pendingTokens(_user, user.amount);
        }
    }

    /// @notice Withdraw LP tokens from MasterPlatypus.
    /// @notice Automatically harvest pending rewards and sends to user
    /// @param _pid the pool id
    /// @param _amount the amount to withdraw
    function withdraw(uint256 _pid, uint256 _amount)
        external
        override
        nonReentrant
        whenNotPaused
        returns (uint256 reward, uint256[] memory additionalRewards)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        IVoter(voter).distribute(address(pool.lpToken));
        (reward, additionalRewards) = _updateFor(_pid, msg.sender, user.amount - _amount);

        // SafeERC20 is not needed as Asset will revert if transfer fails
        pool.lpToken.transfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    /// @notice Distribute PTP rewards and Update user balance
    function _updateFor(
        uint256 _pid,
        address _user,
        uint256 _amount
    ) internal returns (uint256 reward, uint256[] memory additionalRewards) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        if (user.amount > 0) {
            // Harvest PTP
            reward = ((user.amount * pool.accPtpPerShare) / 1e12) - user.rewardDebt;

            // SafeERC20 is not needed as PTP will revert if transfer fails
            ptp.transfer(payable(_user), reward);
            emit Harvest(_user, _pid, reward);
        }

        // update rewarder before we update lpSupply
        IMultiRewarder rewarder = pool.rewarder;
        if (address(rewarder) != address(0)) {
            additionalRewards = rewarder.onPtpReward(_user, user.amount, _amount);
        }

        // update amount of lp staked by user
        user.amount = toUint128(_amount);

        // update reward debt
        user.rewardDebt = toUint128((user.amount * pool.accPtpPerShare) / 1e12);
    }

    /// @notice Withdraw without caring about rewards. EMERGENCY ONLY.
    /// @param _pid the pool id
    function emergencyWithdraw(uint256 _pid) public override nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        // reset rewarder before we update lpSupply
        IMultiRewarder rewarder = pool.rewarder;
        if (address(rewarder) != address(0)) {
            rewarder.onPtpReward(msg.sender, user.amount, 0);
        }

        // SafeERC20 is not needed as Asset will revert if transfer fails
        pool.lpToken.transfer(address(msg.sender), user.amount);

        user.amount = 0;
        user.rewardDebt = 0;

        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
    }

    /// @notice In case we need to manually migrate PTP funds from MasterChef
    /// Sends all remaining ptp from the contract to the owner
    function emergencyPtpWithdraw() external onlyOwner {
        // SafeERC20 is not needed as PTP will revert if transfer fails
        ptp.transfer(address(msg.sender), ptp.balanceOf(address(this)));
    }

    function toUint128(uint256 val) internal pure returns (uint128) {
        if (val > type(uint128).max) revert('uint128 overflow');
        return uint128(val);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
contract ERC20 is Context, IERC20, IERC20Metadata {
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
    constructor(string memory name_, string memory symbol_) {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/**
 * @dev Interface of the BaseMasterPlatypus, obtain PTP from voter
 */
interface IBaseMasterPlatypusV2 {
    function poolLength() external view returns (uint256);

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

    function updatePool(uint256 _pid) external;

    function massUpdatePools() external;

    function notifyRewardAmount(address token, uint256 amount) external;

    function deposit(uint256 _pid, uint256 _amount) external returns (uint256, uint256[] memory);

    function multiClaim(uint256[] memory _pids)
        external
        returns (
            uint256 reward,
            uint256[] memory amounts,
            uint256[][] memory additionalRewards
        );

    function withdraw(uint256 _pid, uint256 _amount) external returns (uint256, uint256[] memory);

    function emergencyWithdraw(uint256 _pid) external;

    function migrate(uint256[] calldata _pids) external;

    function depositFor(
        uint256 _pid,
        uint256 _amount,
        address _user
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol';
import '@openzeppelin/contracts/access/AccessControlEnumerable.sol';
import '@openzeppelin/contracts/utils/Context.sol';

import '../libraries/ERC20FlashMintUpgradeable.sol';

/**
 * @title USP
 * @notice Platypuses can make use of their collateral to mint USP
 * @dev PlatypusTreasure has `MINTER_ROLE` to mint tokens
 */
contract USP is OwnableUpgradeable, ERC20Upgradeable, ERC20BurnableUpgradeable, ERC20FlashMintUpgradeable {
    address public minter;

    function initialize(address _minter, address _flashLoanFeeTo) external initializer {
        require(_minter != address(0), 'zero address');
        require(_flashLoanFeeTo != address(0), 'zero address');

        __Ownable_init();
        __ERC20_init_unchained('USP', 'USP');
        __ERC20Burnable_init_unchained();
        __ERC20FlashMint_init_unchained(50_000_000e18, 9, _flashLoanFeeTo); // max flashloan amount = 50m; fee = 9 b.p.

        minter = _minter;
    }

    /**
     * @notice Change the minter
     */
    function setMinter(address _minter) external onlyOwner {
        minter = _minter;
    }

    function mint(address to, uint256 _amount) external {
        require(msg.sender == minter, 'USP: not minter');
        _mint(to, _amount);
    }

    /**
     * Gas optimization: If the value allowance is `type(uint256).max`, infinite approval is assumed.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = allowance(sender, _msgSender());
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, 'ERC20: transfer amount exceeds allowance');
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
        }
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
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

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../../../utils/ContextUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20BurnableUpgradeable is Initializable, ContextUpgradeable, ERC20Upgradeable {
    function __ERC20Burnable_init() internal initializer {
        __Context_init_unchained();
        __ERC20Burnable_init_unchained();
    }

    function __ERC20Burnable_init_unchained() internal initializer {
    }
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {grantRole} to track enumerable memberships
     */
    function grantRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {revokeRole} to track enumerable memberships
     */
    function revokeRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {renounceRole} to track enumerable memberships
     */
    function renounceRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.renounceRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {_setupRole} to track enumerable memberships
     */
    function _setupRole(bytes32 role, address account) internal virtual override {
        super._setupRole(role, account);
        _roleMembers[role].add(account);
    }
}

// SPDX-License-Identifier: MIT
// Fork from OpenZeppelin Contracts (v4.3.2) (token/ERC20/extensions/ERC20FlashMint.sol)

pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/interfaces/IERC3156Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

/**
 * @dev Implementation of the ERC3156 Flash loans extension, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 *
 * Adds the {flashLoan} method, which provides flash loan support at the token
 * level. By default there is no fee, but this can be changed by overriding {flashFee}.
 *
 * _Available since v4.1._
 */
abstract contract ERC20FlashMintUpgradeable is
    Initializable,
    OwnableUpgradeable,
    ERC20Upgradeable,
    IERC3156FlashLenderUpgradeable
{
    uint256 public maxFlashLoanAmount;
    uint256 public flashLoanFee; // unit: base 10000
    address public flashLoanFeeTo;

    function __ERC20FlashMint_init(
        uint256 _maxFlashLoanAmount,
        uint256 _flashLoanFee,
        address _flashLoanFeeTo
    ) internal initializer {
        __Context_init_unchained();
        __ERC20FlashMint_init_unchained(_maxFlashLoanAmount, _flashLoanFee, _flashLoanFeeTo);
    }

    function __ERC20FlashMint_init_unchained(
        uint256 _maxFlashLoanAmount,
        uint256 _flashLoanFee,
        address _flashLoanFeeTo
    ) internal initializer {
        require(_flashLoanFeeTo != address(0), 'zero address X');
        require(_flashLoanFee < 10000, 'invalid flash loan fee');

        maxFlashLoanAmount = _maxFlashLoanAmount;
        flashLoanFee = _flashLoanFee;
        flashLoanFeeTo = _flashLoanFeeTo;
    }

    bytes32 private constant _RETURN_VALUE = keccak256('ERC3156FlashBorrower.onFlashLoan');

    /**
     * @notice Change the max flash loan
     */
    function setMaxFlashLoanAmount(uint256 _maxFlashLoanAmount) external onlyOwner {
        maxFlashLoanAmount = _maxFlashLoanAmount;
    }

    /**
     * @notice Change the flash loan fee
     */
    function setFlashLoanFee(uint256 _flashLoanFee) external onlyOwner {
        require(_flashLoanFee < 10000, 'invalid flash loan fee');
        flashLoanFee = _flashLoanFee;
    }

    /**
     * @notice Change the flash loan fee to
     */
    function setFlashLoanFeeTo(address _flashLoanFeeTo) external onlyOwner {
        require(flashLoanFeeTo != address(0), 'zero address');
        flashLoanFeeTo = _flashLoanFeeTo;
    }

    /**
     * @dev Returns the maximum amount of tokens available for loan.
     * @param token The address of the token that is requested.
     * @return The amont of token that can be loaned.
     */
    function maxFlashLoan(address token) public view override returns (uint256) {
        return token == address(this) ? maxFlashLoanAmount : 0;
    }

    /**
     * @dev Returns the fee applied when doing flash loans. By default this
     * implementation has 0 fees. This function can be overloaded to make
     * the flash loan mechanism deflationary.
     * @param token The token to be flash loaned.
     * @param amount The amount of tokens to be loaned.
     * @return The fees applied to the corresponding flash loan.
     */
    function flashFee(address token, uint256 amount) public view virtual override returns (uint256) {
        require(token == address(this), 'ERC20FlashMint: wrong token');
        return (amount * flashLoanFee) / 10000;
    }

    /**
     * @dev Performs a flash loan. New tokens are minted and sent to the
     * `receiver`, who is required to implement the {IERC3156FlashBorrower}
     * interface. By the end of the flash loan, the receiver is expected to own
     * amount + fee tokens and have them approved back to the token contract itself so
     * they can be burned.
     * @param receiver The receiver of the flash loan. Should implement the
     * {IERC3156FlashBorrower.onFlashLoan} interface.
     * @param token The token to be flash loaned. Only `address(this)` is
     * supported.
     * @param amount The amount of tokens to be loaned.
     * @param data An arbitrary datafield that is passed to the receiver.
     * @return `true` if the flash loan was successful.
     */
    // This function can reenter, but it doesn't pose a risk because it always preserves the property that the amount
    // minted at the beginning is always recovered and burned at the end, or else the entire function will revert.
    // slither-disable-next-line reentrancy-no-eth
    function flashLoan(
        IERC3156FlashBorrowerUpgradeable receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) public virtual override returns (bool) {
        require(amount <= maxFlashLoan(token), 'ERC20FlashMint: amount exceeds maxFlashLoan');
        uint256 fee = flashFee(token, amount);
        _mint(address(receiver), amount);
        require(
            receiver.onFlashLoan(msg.sender, token, amount, fee, data) == _RETURN_VALUE,
            'ERC20FlashMint: invalid return value'
        );
        uint256 currentAllowance = allowance(address(receiver), address(this));
        require(currentAllowance >= amount + fee, 'ERC20FlashMint: allowance does not allow refund');
        // spend allowance
        _approve(address(receiver), address(this), currentAllowance - amount - fee);
        _burn(address(receiver), amount + fee);

        // mint fee
        if (fee > 0) {
            // flashLoanFeeTo is a non-zero address
            _mint(flashLoanFeeTo, fee);
        }
        return true;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

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

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC3156FlashBorrowerUpgradeable.sol";
import "./IERC3156FlashLenderUpgradeable.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC3156 FlashBorrower, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 *
 * _Available since v4.1._
 */
interface IERC3156FlashBorrowerUpgradeable {
    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC3156FlashBorrowerUpgradeable.sol";

/**
 * @dev Interface of the ERC3156 FlashLender, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 *
 * _Available since v4.1._
 */
interface IERC3156FlashLenderUpgradeable {
    /**
     * @dev The amount of currency available to be lended.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount) external view returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrowerUpgradeable receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import '../lending/USP.sol';

contract MockUSP is USP {
    function faucet(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

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

    uint256 internal constant ACC_TOKEN_PRECISION = 1e12;
    /// @notice WAVAX address on mainnet
    address internal constant WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;

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
        _updatePool();
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
    function setRewardRate(uint256 _tokenId, uint96 _tokenPerSec) external virtual onlyOperatorOrOwner {
        require(_tokenPerSec <= 10000e18, 'reward rate too high'); // in case of accTokenPerShare overflow
        _updatePool();

        uint256 oldRate = poolInfo[_tokenId].tokenPerSec;
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
    ) external virtual override onlyMP nonReentrant returns (uint256[] memory rewards) {
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.14;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import './BoostedMultiRewarderPerSec.sol';

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
 * - Resets token per sec to zero if token balance cannot fullfill rewards that are due
 */
contract BoostedMultiRewarderPerSecV2 is BoostedMultiRewarderPerSec {
    using SafeERC20 for IERC20;

    constructor(
        IMasterPlatypusV4 _MP,
        IERC20 _lpToken,
        uint40 _startTimestamp,
        uint16 _dilutingRepartition,
        IERC20 _rewardToken,
        uint96 _tokenPerSec
    ) BoostedMultiRewarderPerSec(_MP, _lpToken, _startTimestamp, _dilutingRepartition, _rewardToken, _tokenPerSec) {}

    /// @notice Sets the distribution reward rate. This will also update the poolInfo.
    /// @param _tokenPerSec The number of tokens to distribute per second
    function setRewardRate(uint256 _tokenId, uint96 _tokenPerSec) external override onlyOperatorOrOwner {
        require(_tokenPerSec <= 10000e18, 'reward rate too high'); // in case of accTokenPerShare overflow
        _setRewardRate(_tokenId, _tokenPerSec);
    }

    function _setRewardRate(uint256 _tokenId, uint96 _tokenPerSec) internal {
        _updatePool();

        uint256 oldRate = poolInfo[_tokenId].tokenPerSec;
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
                    if (pending >= tokenBalance) {
                        _safeTransferAvaxWithFallback(_user, tokenBalance);
                        rewards[i] = tokenBalance;
                        user.claimable = toUint128(pending - tokenBalance);
                        // In case partners forget to replenish token, pause token emission
                        // Note that some accumulated rewards might not be able to distribute
                        _setRewardRate(i, 0);
                    } else {
                        _safeTransferAvaxWithFallback(_user, pending);
                        rewards[i] = pending;
                        user.claimable = 0;
                    }
                } else {
                    // ERC20 token
                    uint256 tokenBalance = rewardToken.balanceOf(address(this));
                    if (pending >= tokenBalance) {
                        rewardToken.safeTransfer(_user, tokenBalance);
                        rewards[i] = tokenBalance;
                        user.claimable = toUint128(pending - tokenBalance);
                        // In case partners forget to replenish token, pause token emission
                        // Note that some accumulated rewards might not be able to distribute
                        _setRewardRate(i, 0);
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@rari-capital/solmate/src/utils/FixedPointMathLib.sol';
import './libraries/SafeOwnableUpgradeable.sol';
import './interfaces/IAsset.sol';
import './interfaces/IVePtp.sol';
import './interfaces/IMasterPlatypusV4.sol';
import './interfaces/IBoostedMultiRewarder.sol';
import './interfaces/IPlatypusTreasure.sol';

interface IVoter {
    function distribute(address _lpToken) external;

    function pendingPtp(address _lpToken) external view returns (uint256);
}

/// MasterPlatypus is a boss. He says "go f your blocks maki boy, I'm gonna use timestamp instead"
/// In addition, he feeds himself from Venom. So, vePtp holders boost their (non-dialuting) emissions.
/// This contract rewards users in function of their amount of lp staked (dialuting pool) factor (non-dialuting pool)
/// Factor and sumOfFactors are updated by contract VePtp.sol after any vePtp minting/burning (veERC20Upgradeable hook).
/// Note that it's ownable and the owner wields tremendous power. The ownership
/// will be transferred to a governance smart contract once Platypus is sufficiently
/// distributed and the community can show to govern itself.
/// ## Updates
/// - V4 is an improved version of MasterPlatypus(V1), which packs storage variables in order to save gas.
/// - Compatible with gauge voting
contract MasterPlatypusV4 is
    Initializable,
    SafeOwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    IMasterPlatypusV4
{
    using EnumerableSet for EnumerableSet.AddressSet;

    // The strongest platypus out there (ptp token).
    IERC20 public ptp;
    // Venom does not seem to hurt the Platypus, it only makes it stronger.
    IVePtp public vePtp;
    // New Master Platypus address for future migrations
    IMasterPlatypusV4 public newMasterPlatypus;
    // Platypus Treasure. The address is initailized with 0 until we enable the Platypus Treasure contract
    IPlatypusTreasure public override platypusTreasure;
    // Address of Voter
    address public voter;
    // Emissions: dilutingRepartition and non-dilutingRepartition must add to 1000 => 100%
    // Dialuting emissions repartition (e.g. 300 for 30%)
    uint16 public dilutingRepartition;
    // The maximum number of pools, in case updateFactor() exceeds block gas limit
    uint256 public maxPoolLength;
    // Set of all LP tokens that have been added as pools
    EnumerableSet.AddressSet private lpTokens;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    event Add(uint256 indexed pid, IAsset indexed lpToken, IBoostedMultiRewarder indexed rewarder);
    event SetRewarder(uint256 indexed pid, IBoostedMultiRewarder indexed rewarder);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event DepositFor(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event UpdateEmissionRepartition(address indexed user, uint256 dilutingRepartition, uint256 nonDilutingRepartition);
    event UpdateVePTP(address indexed user, address oldVePTP, address newVePTP);

    /// @dev Modifier ensuring that certain function can only be called by VePtp
    modifier onlyVePtp() {
        require(address(vePtp) == msg.sender, 'notVePtp: wut?');
        _;
    }

    /// @dev Modifier ensuring that certain function can only be called by PlatypusTreasure
    modifier onlyPlatypusTreasure() {
        require(address(platypusTreasure) == msg.sender, 'not platypusTreasure');
        _;
    }

    function initialize(
        IERC20 _ptp,
        IVePtp _vePtp,
        address _voter,
        uint16 _dilutingRepartition
    ) public initializer {
        require(address(_ptp) != address(0), 'ptp address cannot be zero');
        require(address(_vePtp) != address(0), 'vePtp address cannot be zero');
        require(address(_voter) != address(0), 'voter address cannot be zero');
        require(_dilutingRepartition <= 1000, 'dialuting repartition must be in range 0, 1000');

        __Ownable_init();
        __ReentrancyGuard_init_unchained();
        __Pausable_init_unchained();

        ptp = _ptp;
        vePtp = _vePtp;
        voter = _voter;
        dilutingRepartition = _dilutingRepartition;
        maxPoolLength = 50;
    }

    /**
     * @dev pause pool, restricting certain operations
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev unpause pool, enabling certain operations
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    function setNewMasterPlatypus(IMasterPlatypusV4 _newMasterPlatypus) external onlyOwner {
        newMasterPlatypus = _newMasterPlatypus;
    }

    function setMaxPoolLength(uint256 _maxPoolLength) external onlyOwner {
        require(poolInfo.length <= _maxPoolLength);
        maxPoolLength = _maxPoolLength;
    }

    /**
     * @notice external function to set Platypus Treasure
     * @dev only owner can call this function
     * @param _platypusTreasure address of Platypus Treasure to set
     */
    function setPlatypusTreasure(address _platypusTreasure) external onlyOwner {
        require(address(_platypusTreasure) != address(0));
        platypusTreasure = IPlatypusTreasure(_platypusTreasure);
    }

    function nonDilutingRepartition() external view returns (uint256) {
        return 1000 - dilutingRepartition;
    }

    /// @notice returns pool length
    function poolLength() external view override returns (uint256) {
        return poolInfo.length;
    }

    function getPoolId(address _lp) external view returns (uint256) {
        require(lpTokens.contains(address(_lp)), 'invalid lp');
        return lpTokens._inner._indexes[bytes32(uint256(uint160(_lp)))] - 1;
    }

    function getUserInfo(uint256 _pid, address _user) external view returns (UserInfo memory) {
        return userInfo[_pid][_user];
    }

    function getSumOfFactors(uint256 _pid) external view override returns (uint256) {
        return poolInfo[_pid].sumOfFactors;
    }

    /// @notice Add a new lp to the pool. Can only be called by the owner.
    /// @dev Reverts if the same LP token is added more than once.
    /// @param _lpToken the corresponding lp token
    /// @param _rewarder the rewarder
    function add(IAsset _lpToken, IBoostedMultiRewarder _rewarder) public onlyOwner {
        require(Address.isContract(address(_lpToken)), 'add: LP token must be a valid contract');
        require(
            Address.isContract(address(_rewarder)) || address(_rewarder) == address(0),
            'add: rewarder must be contract or zero'
        );
        require(!lpTokens.contains(address(_lpToken)), 'add: LP already added');
        require(poolInfo.length < maxPoolLength, 'add: exceed max pool');

        // update PoolInfo with the new LP
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                rewarder: _rewarder,
                sumOfFactors: 0,
                accPtpPerShare: 0,
                accPtpPerFactorShare: 0
            })
        );

        // add lpToken to the lpTokens enumerable set
        lpTokens.add(address(_lpToken));
        emit Add(poolInfo.length - 1, _lpToken, _rewarder);
    }

    /// @notice Update the given pool's rewarder
    /// @param _pid the pool id
    /// @param _rewarder the rewarder
    function setRewarder(uint256 _pid, IBoostedMultiRewarder _rewarder) public onlyOwner {
        require(
            Address.isContract(address(_rewarder)) || address(_rewarder) == address(0),
            'set: rewarder must be contract or zero'
        );

        PoolInfo storage pool = poolInfo[_pid];

        pool.rewarder = _rewarder;
        emit SetRewarder(_pid, _rewarder);
    }

    /// @notice Get bonus token info from the rewarder contract for a given pool, if it is a double reward farm
    /// @param _pid the pool id
    function rewarderBonusTokenInfo(uint256 _pid)
        public
        view
        override
        returns (IERC20[] memory bonusTokenAddresses, string[] memory bonusTokenSymbols)
    {
        PoolInfo storage pool = poolInfo[_pid];
        if (address(pool.rewarder) == address(0)) {
            return (bonusTokenAddresses, bonusTokenSymbols);
        }

        bonusTokenAddresses = pool.rewarder.rewardTokens();

        uint256 len = bonusTokenAddresses.length;
        bonusTokenSymbols = new string[](len);
        for (uint256 i; i < len; ++i) {
            if (address(bonusTokenAddresses[i]) == address(0)) {
                bonusTokenSymbols[i] = 'AVAX';
            } else {
                bonusTokenSymbols[i] = IERC20Metadata(address(bonusTokenAddresses[i])).symbol();
            }
        }
    }

    /// @notice Update reward variables for all pools.
    /// @dev Be careful of gas spending!
    function massUpdatePools() external override {
        uint256 length = poolInfo.length;
        for (uint256 pid; pid < length; ++pid) {
            _updatePool(pid);
        }
    }

    /// @notice Update reward variables of the given pool to be up-to-date.
    /// @param _pid the pool id
    function updatePool(uint256 _pid) external override {
        _updatePool(_pid);
    }

    function _updatePool(uint256 _pid) private {
        PoolInfo storage pool = poolInfo[_pid];
        IVoter(voter).distribute(address(pool.lpToken));
    }

    /// @dev We might distribute PTP over a period of time to prevent front-running
    /// Refer to synthetix/StakingRewards.sol notifyRewardAmount
    /// Note: This looks safe from reentrancy.
    function notifyRewardAmount(address _lpToken, uint256 _amount) external override {
        require(_amount > 0, 'MasterPlatypus: zero amount');
        require(msg.sender == voter, 'MasterPlatypus: only voter');

        // this line reverts if asset is not in the list
        uint256 pid = lpTokens._inner._indexes[bytes32(uint256(uint160(_lpToken)))] - 1;
        PoolInfo storage pool = poolInfo[pid];

        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            return;
        }

        // update accPtpPerShare to reflect dialuting rewards
        pool.accPtpPerShare += toUint128((_amount * 1e12 * dilutingRepartition) / (lpSupply * 1000));

        // update accPtpPerFactorShare to reflect non-dialuting rewards
        if (pool.sumOfFactors > 0) {
            pool.accPtpPerFactorShare += toUint128(
                (_amount * 1e12 * (1000 - dilutingRepartition)) / (pool.sumOfFactors * 1000)
            );
        }

        // Event is not emitted. as Voter should have already emitted it
    }

    /// @notice Helper function to migrate fund from multiple pools to the new MasterPlatypus.
    /// @notice user must initiate transaction from masterchef
    /// @dev Assume the orginal MasterPlatypus has stopped emisions
    /// hence we skip IVoter(voter).distribute() to save gas cost
    function migrate(uint256[] calldata _pids) external override nonReentrant {
        require(address(newMasterPlatypus) != (address(0)), 'to where?');

        _multiClaim(_pids);
        for (uint256 i; i < _pids.length; ++i) {
            uint256 pid = _pids[i];
            UserInfo storage user = userInfo[pid][msg.sender];

            if (user.amount > 0) {
                PoolInfo storage pool = poolInfo[pid];
                pool.lpToken.approve(address(newMasterPlatypus), user.amount);
                newMasterPlatypus.depositFor(pid, user.amount, msg.sender);

                pool.sumOfFactors -= toUint128(user.factor);

                // remove user
                delete userInfo[pid][msg.sender];
            }
        }
    }

    /// @notice Deposit LP tokens to MasterChef for PTP allocation on behalf of user
    /// @dev user must initiate transaction from masterchef
    /// @param _pid the pool id
    /// @param _amount amount to deposit
    /// @param _user the user being represented
    function depositFor(
        uint256 _pid,
        uint256 _amount,
        address _user
    ) external override nonReentrant whenNotPaused {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        // update pool in case user has deposited
        IVoter(voter).distribute(address(pool.lpToken));
        _updateFor(_pid, _user, user.amount + _amount);

        // SafeERC20 is not needed as Asset will revert if transfer fails
        pool.lpToken.transferFrom(msg.sender, address(this), _amount);
        emit DepositFor(_user, _pid, _amount);
    }

    /// @notice Deposit LP tokens to MasterChef for PTP allocation.
    /// @dev it is possible to call this function with _amount == 0 to claim current rewards
    /// @param _pid the pool id
    /// @param _amount amount to deposit
    function deposit(uint256 _pid, uint256 _amount)
        external
        override
        nonReentrant
        whenNotPaused
        returns (uint256 reward, uint256[] memory additionalRewards)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        IVoter(voter).distribute(address(pool.lpToken));
        (reward, additionalRewards) = _updateFor(_pid, msg.sender, user.amount + _amount);

        // SafeERC20 is not needed as Asset will revert if transfer fails
        pool.lpToken.transferFrom(address(msg.sender), address(this), _amount);
        emit Deposit(msg.sender, _pid, _amount);
    }

    /// @notice claims rewards for multiple pids
    /// @param _pids array pids, pools to claim
    function multiClaim(uint256[] calldata _pids)
        external
        override
        nonReentrant
        whenNotPaused
        returns (
            uint256 reward,
            uint256[] memory amounts,
            uint256[][] memory additionalRewards
        )
    {
        return _multiClaim(_pids);
    }

    /// @notice private function to claim rewards for multiple pids
    /// @param _pids array pids, pools to claim
    function _multiClaim(uint256[] memory _pids)
        private
        returns (
            uint256 reward,
            uint256[] memory amounts,
            uint256[][] memory additionalRewards
        )
    {
        // accumulate rewards for each one of the pids in pending
        amounts = new uint256[](_pids.length);
        additionalRewards = new uint256[][](_pids.length);
        for (uint256 i; i < _pids.length; ++i) {
            PoolInfo storage pool = poolInfo[_pids[i]];
            IVoter(voter).distribute(address(pool.lpToken));

            UserInfo storage user = userInfo[_pids[i]][msg.sender];
            if (user.amount > 0) {
                // increase pending to send all rewards once
                uint256 poolRewards = ((uint256(user.amount) *
                    pool.accPtpPerShare +
                    uint256(user.factor) *
                    pool.accPtpPerFactorShare) / 1e12) +
                    user.claimablePtp -
                    user.rewardDebt;

                user.claimablePtp = 0;

                // update reward debt
                user.rewardDebt = toUint128(
                    (uint256(user.amount) * pool.accPtpPerShare + uint256(user.factor) * pool.accPtpPerFactorShare) /
                        1e12
                );

                // increase reward
                reward += poolRewards;

                amounts[i] = poolRewards;
                emit Harvest(msg.sender, _pids[i], amounts[i]);

                // if exist, update external rewarder
                IBoostedMultiRewarder rewarder = pool.rewarder;
                if (address(rewarder) != address(0)) {
                    additionalRewards[i] = rewarder.onPtpReward(
                        msg.sender,
                        user.amount,
                        user.amount,
                        user.factor,
                        user.factor
                    );
                }
            }
        }
        // transfer all rewards
        // SafeERC20 is not needed as PTP will revert if transfer fails
        ptp.transfer(payable(msg.sender), reward);
    }

    /// @notice View function to see pending PTPs on frontend.
    /// @param _pid the pool id
    /// @param _user the user address
    function pendingTokens(uint256 _pid, address _user)
        external
        view
        override
        returns (
            uint256 pendingPtp,
            IERC20[] memory bonusTokenAddresses,
            string[] memory bonusTokenSymbols,
            uint256[] memory pendingBonusTokens
        )
    {
        PoolInfo storage pool = poolInfo[_pid];

        // calculate accPtpPerShare and accPtpPerFactorShare
        uint256 pendingPtpForLp = IVoter(voter).pendingPtp(address(pool.lpToken));
        uint256 accPtpPerShare = pool.accPtpPerShare;
        uint256 accPtpPerFactorShare = pool.accPtpPerFactorShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply != 0) {
            accPtpPerShare += (pendingPtpForLp * 1e12 * dilutingRepartition) / (lpSupply * 1000);
        }
        if (pool.sumOfFactors > 0) {
            accPtpPerFactorShare +=
                (pendingPtpForLp * 1e12 * (1000 - dilutingRepartition)) /
                (pool.sumOfFactors * 1000);
        }

        // get pendingPtp
        UserInfo storage user = userInfo[_pid][_user];
        pendingPtp =
            ((uint256(user.amount) * accPtpPerShare + uint256(user.factor) * accPtpPerFactorShare) / 1e12) +
            user.claimablePtp -
            user.rewardDebt;

        (bonusTokenAddresses, bonusTokenSymbols) = rewarderBonusTokenInfo(_pid);

        // get pendingBonusToken
        IBoostedMultiRewarder rewarder = pool.rewarder;
        if (address(rewarder) != address(0)) {
            pendingBonusTokens = rewarder.pendingTokens(_user, user.amount, user.factor);
        }
    }

    /**
     * @notice internal function to withdraw lps on behalf of user
     * @dev pending rewards are transfered to user, lps are transfered to caller
     * @param _pid the pool id
     * @param _user the user being represented
     * @param _caller caller's address
     * @param _amount amount to withdraw
     */
    function _withdrawFor(
        uint256 _pid,
        address _user,
        address _caller,
        uint256 _amount
    ) internal returns (uint256 reward, uint256[] memory additionalRewards) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        require(user.amount >= _amount, 'withdraw: not enough balance');

        IVoter(voter).distribute(address(pool.lpToken));
        (reward, additionalRewards) = _updateFor(_pid, _user, user.amount - _amount);

        // SafeERC20 is not needed as Asset will revert if transfer fails
        pool.lpToken.transfer(_caller, _amount);
        emit Withdraw(_user, _pid, _amount);
    }

    /// @notice Distribute PTP rewards and Update user balance
    function _updateFor(
        uint256 _pid,
        address _user,
        uint256 _amount
    ) internal returns (uint256 reward, uint256[] memory additionalRewards) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        // Harvest PTP
        if (user.amount > 0 || user.claimablePtp > 0) {
            reward =
                ((uint256(user.amount) * pool.accPtpPerShare + uint256(user.factor) * pool.accPtpPerFactorShare) /
                    1e12) +
                user.claimablePtp -
                user.rewardDebt;
            user.claimablePtp = 0;

            // SafeERC20 is not needed as PTP will revert if transfer fails
            ptp.transfer(payable(_user), reward);
            emit Harvest(_user, _pid, reward);
        }

        // update amount of lp staked
        uint256 oldAmount = user.amount;
        user.amount = toUint128(_amount);

        // update sumOfFactors
        uint128 oldFactor = user.factor;
        user.factor = toUint128(FixedPointMathLib.sqrt(user.amount * vePtp.balanceOf(_user)));

        // update reward debt
        user.rewardDebt = toUint128(
            (uint256(user.amount) * pool.accPtpPerShare + uint256(user.factor) * pool.accPtpPerFactorShare) / 1e12
        );

        // update rewarder before we update lpSupply and sumOfFactors
        IBoostedMultiRewarder rewarder = pool.rewarder;
        if (address(rewarder) != address(0)) {
            additionalRewards = rewarder.onPtpReward(_user, oldAmount, _amount, oldFactor, user.factor);
        }

        pool.sumOfFactors = toUint128(pool.sumOfFactors + user.factor - oldFactor);
    }

    /// @notice Withdraw LP tokens from MasterPlatypus.
    /// @notice Automatically harvest pending rewards and sends to user
    /// @param _pid the pool id
    /// @param _amount the amount to withdraw
    function withdraw(uint256 _pid, uint256 _amount)
        external
        override
        nonReentrant
        whenNotPaused
        returns (uint256 reward, uint256[] memory additionalRewards)
    {
        (reward, additionalRewards) = _withdrawFor(_pid, msg.sender, msg.sender, _amount);

        if (address(platypusTreasure) != address(0x00)) {
            (bool isSolvent, ) = platypusTreasure.isSolvent(msg.sender, address(poolInfo[_pid].lpToken), true);
            require(isSolvent, 'remaining amount exceeds collateral factor');
        }
    }

    /// @notice Liquidate collateral LPs
    /// @dev only Platypus Treasure can call this function to liquidate
    /// @param _pid the pool id
    /// @param _user the user being represented
    /// @param _amount amount to withdraw
    function liquidate(
        uint256 _pid,
        address _user,
        uint256 _amount
    ) external nonReentrant onlyPlatypusTreasure {
        _withdrawFor(_pid, _user, msg.sender, _amount);
    }

    /// @notice Withdraw without caring about rewards. EMERGENCY ONLY.
    /// @param _pid the pool id
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (address(platypusTreasure) != address(0x00)) {
            (bool isSolvent, ) = platypusTreasure.isSolvent(msg.sender, address(poolInfo[_pid].lpToken), true);
            require(isSolvent, 'remaining amount exceeds collateral factor');
        }

        // reset rewarder before we update lpSupply and sumOfFactors
        IBoostedMultiRewarder rewarder = pool.rewarder;
        if (address(rewarder) != address(0)) {
            rewarder.onPtpReward(msg.sender, user.amount, 0, user.factor, 0);
        }

        // SafeERC20 is not needed as Asset will revert if transfer fails
        pool.lpToken.transfer(address(msg.sender), user.amount);

        // update non-dialuting factor
        pool.sumOfFactors -= user.factor;

        user.amount = 0;
        user.factor = 0;
        user.rewardDebt = 0;

        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
    }

    /// @notice updates emission repartition
    /// @param _dilutingRepartition the future dialuting repartition
    function updateEmissionRepartition(uint16 _dilutingRepartition) external onlyOwner {
        require(_dilutingRepartition <= 1000);
        dilutingRepartition = _dilutingRepartition;
        emit UpdateEmissionRepartition(msg.sender, _dilutingRepartition, 1000 - _dilutingRepartition);
    }

    /// @notice updates vePtp address
    /// @param _newVePtp the new VePtp address
    function setVePtp(IVePtp _newVePtp) external onlyOwner {
        require(address(_newVePtp) != address(0));
        IVePtp oldVePtp = vePtp;
        vePtp = _newVePtp;
        emit UpdateVePTP(msg.sender, address(oldVePtp), address(_newVePtp));
    }

    /// @notice updates factor after any vePtp token operation (minting/burning)
    /// @param _user the user to update
    /// @param _newVePtpBalance the amount of vePTP
    /// @dev can only be called by vePtp
    function updateFactor(address _user, uint256 _newVePtpBalance) external override onlyVePtp {
        // loop over each pool : beware gas cost!
        uint256 length = poolInfo.length;

        for (uint256 pid = 0; pid < length; ) {
            UserInfo storage user = userInfo[pid][_user];

            // skip if user doesn't have any deposit in the pool
            if (user.amount > 0) {
                PoolInfo storage pool = poolInfo[pid];

                // first, update pool
                IVoter(voter).distribute(address(pool.lpToken));

                // calculate pending
                uint256 pending = ((uint256(user.amount) *
                    pool.accPtpPerShare +
                    uint256(user.factor) *
                    pool.accPtpPerFactorShare) / 1e12) - user.rewardDebt;
                // increase claimablePtp
                user.claimablePtp += toUint128(pending);

                // update non-dialuting pool factor
                uint128 oldFactor = user.factor;
                user.factor = toUint128(FixedPointMathLib.sqrt(user.amount * _newVePtpBalance));

                // update reward debt, take into account newFactor
                user.rewardDebt = toUint128(
                    (uint256(user.amount) * pool.accPtpPerShare + uint256(user.factor) * pool.accPtpPerFactorShare) /
                        1e12
                );

                // update rewarder before we update sumOfFactors
                IBoostedMultiRewarder rewarder = pool.rewarder;
                if (address(rewarder) != address(0)) {
                    rewarder.onUpdateFactor(_user, user.amount, oldFactor, user.factor);
                }

                pool.sumOfFactors = pool.sumOfFactors + user.factor - oldFactor;
            }

            unchecked {
                ++pid;
            }
        }
    }

    /// @notice In case we need to manually migrate PTP funds from MasterChef
    /// Sends all remaining ptp from the contract to the owner
    function emergencyPtpWithdraw() external onlyOwner {
        // SafeERC20 is not needed as PTP will revert if transfer fails
        ptp.transfer(address(msg.sender), ptp.balanceOf(address(this)));
    }

    function version() external pure returns (uint256) {
        return 4;
    }

    function toUint128(uint256 val) internal pure returns (uint128) {
        if (val > type(uint128).max) revert('uint128 overflow');
        return uint128(val);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z) // Like multiplying by 2 ** 64.
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z) // Like multiplying by 2 ** 32.
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z) // Like multiplying by 2 ** 16.
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z) // Like multiplying by 2 ** 8.
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z) // Like multiplying by 2 ** 4.
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z) // Like multiplying by 2 ** 2.
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@rari-capital/solmate/src/utils/SafeTransferLib.sol';
import '@rari-capital/solmate/src/utils/FixedPointMathLib.sol';
import '@rari-capital/solmate/src/tokens/ERC20.sol';

import '../interfaces/IUSP.sol';
import '../interfaces/IPriceOracleGetter.sol';
import '../interfaces/IMasterPlatypusV4.sol';
import '../interfaces/IPool.sol';

interface LiquidationCallback {
    function callback(
        uint256 uspAmount,
        uint256 collateralAmount,
        address initiator,
        bytes calldata data
    ) external;
}

/**
 * @title PlatypusTreasure
 * @notice Platypuses can make use of their collateral to mint USP
 * @dev If the user's health factor is below 1, anyone can liquidate his/her position.
 * Protocol will charge debt interest from borrowers and protocol revenue from liquidation.
 */
contract PlatypusTreasure is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /**
     * Structs
     */

    /// @notice A struct for treasure settings
    struct MarketSetting {
        IAsset uspLp; // USP lp address of main pool
        uint32 mininumBorrowAmount; // minimum USP borrow amount in whole token. 9 digits.
        uint8 k; // param for dynamic interest rate: c^k / 100
        bool borrowPaused; // pause USP borrowing for all collaterals
        bool liquidationPaused;
        uint16 kickIncentive; // keeper incentive. USP amount in whole token.
    }

    /// @notice A struct for collateral settings
    struct CollateralSetting {
        /* storage slot (read-only) */
        // borrow, repay
        uint40 borrowCap; // USP borrow cap in whole token. 12 digits.
        uint16 collateralFactor; // collateral factor; base 10000
        uint16 borrowFee; // fees that will be charged upon minting USP (0.3% in USP); base 10000
        bool isStable; // we perform additional check to stables: borrowing USP is now allowed when it is about to depeg
        // liquidation
        uint16 liquidationThreshold; // collateral liquidation threshold (greater than `collateralFactor`); base 10000
        uint16 liquidationPenalty; // liquidation penalty for liquidators. base 10000
        uint16 auctionStep; // price of the auction decrease per `auctionStep` seconds to `auctionFactor`
        uint16 auctionFactor; // base 10000
        bool liquidationPaused;
        // others
        uint8 decimals; // cache of decimal of the collateral. also used to check if collateral exists
        bool isLp;
        // 88 bits unused
        /* storage slot */
        uint128 borrowedShare; // borrowed USP share. 20.18 fixed point integer
        /* LP infos */
        IMasterPlatypusV4 masterPlatypus; // MasterPlatypus Address
        uint8 pid; // cache of pid in the master platypus
        // uint256 uspToRaise; // USP amount that should be filled by liquidation
    }

    /// @notice A struct for users collateral position
    struct Position {
        /* storage slot */
        uint128 debtShare;
        // non-LP infos
        // don't read this storage directly, instead, read `_getCollateralAmount()`
        uint128 collateralAmount;
    }

    /// @notice A struct to preview a user's collateral position; external view-only
    struct PositionView {
        uint256 collateralAmount;
        uint256 collateralUSD;
        uint256 borrowLimitUSP;
        uint256 liquidateLimitUSP;
        uint256 debtAmountUSP;
        uint256 debtShare;
        uint256 healthFactor; // `healthFactor` is 0 if `debtAmountUSP` is 0
        bool liquidable;
    }

    struct Auction {
        // storage slot
        uint128 uspAmount; // USP to raise
        uint128 collateralAmount; // collateral that is being liquidated
        // storage slot
        ERC20 token; // address collateral
        uint48 index; // index in activeAuctions
        uint40 startTime; // starting time of the auction
        // storage slot
        address user; // liquidatee
        uint96 startPrice; // starting price of the auction. 10.18 fixed point
    }

    /**
     * Events
     */

    /// @notice Add collateral token
    event AddCollateralToken(ERC20 indexed token);
    /// @notice Update collateral token setting
    event SetCollateralToken(ERC20 indexed token, CollateralSetting setting);

    /// @notice An event thats emitted when fee is collected at minting, interest accrual and liquidation
    event Accrue(uint256 interest);
    /// @notice An event thats emitted when user deposits collateral
    event AddCollateral(address indexed user, ERC20 indexed token, uint256 amount);
    /// @notice An event thats emitted when user withdraws collateral
    event RemoveCollateral(address indexed user, ERC20 indexed token, uint256 amount);
    /// @notice An event thats emitted when user borrows USP
    event Borrow(address indexed user, ERC20 indexed collateral, uint256 uspAmount);
    /// @notice An event thats emitted when user repays USP
    event Repay(address indexed user, ERC20 indexed collateral, uint256 uspAmount);

    event StartAuction(
        uint256 indexed id,
        address indexed user,
        ERC20 indexed token,
        uint256 collateralAmount,
        uint256 uspAmount
    );
    event BuyCollateral(
        uint256 indexed id,
        address indexed user,
        ERC20 indexed token,
        uint256 collateralAmount,
        uint256 uspAmount
    );
    event BadDebt(uint256 indexed id, address indexed user, ERC20 indexed token, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error PlatypusTreasure_ZeroAddress();
    error PlatypusTreasure_InvalidMasterPlatypus();
    error PlatypusTreasure_InvalidRatio();
    error PlatypusTreasure_InvalidPid();
    error PlatypusTreasure_InvalidToken();
    error PlatypusTreasure_InvalidAmount();
    error PlatypusTreasure_MinimumBorrowAmountNotSatisfied();
    error PlatypusTreasure_ExceedCollateralFactor();
    error PlatypusTreasure_ExceedCap();
    error PlatypusTreasure_ExceedHalfRepayLimit();
    error PlatypusTreasure_NotLiquidable();
    error PlatypusTreasure_BorrowPaused();
    error PlatypusTreasure_BorrowDisallowed();
    error PlatypusTreasure_InvalidMarketSetting();

    error Liquidation_Paused();
    error Liquidation_Invalid_Auction_Id();
    error Liquidation_Exceed_Max_Price(uint256 currentPrice);
    error Liquidation_Liquidator_Should_Take_All_Collateral();

    error Uint96_Overflow();
    error Uint112_Overflow();
    error Uint128_Overflow();

    /**
     * Storage
     */
    /// @notice Platypus Treasure settings
    MarketSetting public marketSetting;
    /// @notice Collateral price oracle address (returns price in usd: 8 decimals)
    IPriceOracleGetter public oracle;

    /// @notice collateral tokens in array
    ERC20[] public collateralTokens;
    /// @notice collateral settings
    mapping(ERC20 => CollateralSetting) public collateralSettings; // token => collateral setting
    /// @notice users collateral position
    mapping(ERC20 => mapping(address => Position)) internal userPositions; // collateral => user => position

    /* storage slot for _accrue() */
    /// @notice total borrowed amount accrued so far - 15.18 fixed point integer
    uint112 public totalDebtAmount;
    /// @notice total protocol fees accrued so far - 15.18 fixed point integer
    uint112 public feesToBeCollected;
    /// @notice last time of debt accrued
    uint32 public lastAccrued;

    /// @notice address that should receive liquidation fee, interest and USP minting fee
    address public feeTo;
    /// @notice total borrowed portion
    uint128 public totalDebtShare;
    /// @notice Amount of USP needed to cover debt + fees of active auctions
    uint128 public unbackedUspAmount;

    /// @notice USP token address
    IUSP public usp;
    uint48 public totalAuctions;

    /// @notice a list of active auctions
    /// @dev each slot is able to store 5 activeAuctions
    uint48[] public activeAuctions;
    mapping(uint256 => Auction) public auctions; // id => auction data

    /**
     * Constructor, Modifers, Getters and Setters
     */

    /**
     * @notice Initializer.
     * @param _usp USP token address
     * @param _oracle collateral token price oracle
     * @param _marketSetting treasure settings
     */
    function initialize(
        IUSP _usp,
        IPriceOracleGetter _oracle,
        MarketSetting calldata _marketSetting,
        address _feeTo
    ) external initializer {
        if (address(_usp) == address(0)) revert PlatypusTreasure_ZeroAddress();
        if (address(_oracle) == address(0)) revert PlatypusTreasure_ZeroAddress();
        if (_feeTo == address(0)) revert PlatypusTreasure_ZeroAddress();
        if (_marketSetting.k == 0 || _marketSetting.k > 10 || address(_marketSetting.uspLp) == address(0))
            revert PlatypusTreasure_InvalidMarketSetting();

        __Ownable_init();
        __ReentrancyGuard_init_unchained();

        usp = _usp;
        oracle = _oracle;
        marketSetting = _marketSetting;
        feeTo = _feeTo;
    }

    /**
     * @notice returns the number of all collateral tokens
     * @return number of collateral tokens
     */
    function getCollateralTokens() external view returns (ERC20[] memory) {
        return collateralTokens;
    }

    /**
     * @notice returns the number of all collateral tokens
     * @return number of collateral tokens
     */
    function collateralTokensLength() external view returns (uint256) {
        return collateralTokens.length;
    }

    /**
     * @dev pause borrow
     */
    function pauseBorrow() external onlyOwner {
        marketSetting.borrowPaused = true;
    }

    /**
     * @dev unpause borrow
     */
    function unpauseBorrow() external onlyOwner {
        marketSetting.borrowPaused = false;
    }

    /**
     * @notice Update interest param k
     * @dev only owner can call this function
     */
    function setInterestParam(uint8 _k) external onlyOwner {
        if (_k == 0 || _k > 10) revert PlatypusTreasure_InvalidMarketSetting();
        marketSetting.k = _k;
    }

    function setkickIncentive(uint16 _kickIncentive) external onlyOwner {
        marketSetting.kickIncentive = _kickIncentive;
    }

    /**
     * @notice Update mininumBorrowAmount
     * @dev only owner can call this function
     */
    function setMinimumBorrowAmount(uint32 _mininumBorrowAmount) external onlyOwner {
        marketSetting.mininumBorrowAmount = _mininumBorrowAmount;
    }

    /**
     * @notice Stops `startAuction` for all collaterals
     */
    function pauseAllLiquidations() external onlyOwner {
        marketSetting.liquidationPaused = true;
    }

    /**
     * @notice Resume `startAuction` for all collaterals
     */
    function resumeAllLiquidations() external onlyOwner {
        marketSetting.liquidationPaused = false;
    }

    /**
     * @notice Stops `startAuction`
     */
    function pauseLiquidations(ERC20 _token) external onlyOwner {
        _checkCollateralExist(_token);
        collateralSettings[_token].liquidationPaused = true;
    }

    /**
     * @notice Resume `startAuction`
     */
    function resumeLiquidations(ERC20 _token) external onlyOwner {
        _checkCollateralExist(_token);
        collateralSettings[_token].liquidationPaused = false;
    }

    /**
     * @notice add or update LP collateral setting
     * @dev only owner can call this function
     * @param _token collateral token address
     * @param _borrowCap borrow cap in whole token
     * @param _collateralFactor borrow limit
     * @param _borrowFee borrow fee of USP
     * @param _liquidationThreshold liquidation threshold rate
     * @param _liquidationPenalty liquidation penalty
     * @param _masterPlatypus address of master platypus
     */
    function setLpCollateralToken(
        ERC20 _token,
        uint40 _borrowCap,
        uint16 _collateralFactor,
        uint16 _borrowFee,
        bool _isStable,
        uint16 _liquidationThreshold,
        uint16 _liquidationPenalty,
        uint16 _auctionStep,
        uint16 _auctionFactor,
        IMasterPlatypusV4 _masterPlatypus
    ) external onlyOwner {
        if (address(_token) == address(0)) revert PlatypusTreasure_ZeroAddress();
        if (
            _collateralFactor >= 10000 ||
            _liquidationThreshold >= 10000 ||
            _liquidationPenalty >= 10000 ||
            _borrowFee >= 10000 ||
            _liquidationThreshold < _collateralFactor ||
            _auctionStep == 0 ||
            _auctionFactor <= 1000
        ) revert PlatypusTreasure_InvalidRatio();

        if (address(_masterPlatypus) == address(0)) revert PlatypusTreasure_ZeroAddress();
        if (address(_masterPlatypus.platypusTreasure()) != address(this))
            revert PlatypusTreasure_InvalidMasterPlatypus();

        uint256 pid = _masterPlatypus.getPoolId(address(_token));
        if (pid > type(uint8).max) revert PlatypusTreasure_InvalidPid();

        // check if collateral exists
        bool isNewSetting = collateralSettings[_token].decimals == 0;

        // add a new collateral
        collateralSettings[_token] = CollateralSetting({
            borrowCap: _borrowCap,
            collateralFactor: _collateralFactor,
            borrowFee: _borrowFee,
            isStable: _isStable,
            liquidationThreshold: _liquidationThreshold,
            liquidationPenalty: _liquidationPenalty,
            auctionStep: _auctionStep,
            auctionFactor: _auctionFactor,
            liquidationPaused: collateralSettings[_token].liquidationPaused,
            decimals: ERC20(_token).decimals(),
            isLp: true,
            borrowedShare: collateralSettings[_token].borrowedShare,
            masterPlatypus: _masterPlatypus,
            pid: uint8(pid)
        });

        if (isNewSetting) {
            collateralTokens.push(_token);
            emit AddCollateralToken(_token);
        }
        emit SetCollateralToken(_token, collateralSettings[_token]);
    }

    /**
     * @notice add or update LP collateral setting
     * @dev only owner can call this function
     * @param _token collateral token address
     * @param _borrowCap borrow cap in whole token
     * @param _collateralFactor borrow limit
     * @param _borrowFee borrow fee of USP
     * @param _liquidationThreshold liquidation threshold rate
     * @param _liquidationPenalty liquidation penalty
     */
    function setRawCollateralToken(
        ERC20 _token,
        uint40 _borrowCap,
        uint16 _collateralFactor,
        uint16 _borrowFee,
        bool _isStable,
        uint16 _liquidationThreshold,
        uint16 _liquidationPenalty,
        uint16 _auctionStep,
        uint16 _auctionFactor
    ) external onlyOwner {
        if (address(_token) == address(0)) revert PlatypusTreasure_ZeroAddress();
        if (
            _collateralFactor >= 10000 ||
            _liquidationThreshold >= 10000 ||
            _liquidationPenalty >= 10000 ||
            _borrowFee >= 10000 ||
            _borrowFee == 0 ||
            _liquidationThreshold < _collateralFactor ||
            _auctionStep == 0 ||
            _auctionFactor <= 1000
        ) revert PlatypusTreasure_InvalidRatio();

        // check if collateral exists
        bool isNewSetting = collateralSettings[_token].decimals == 0;

        // add a new collateral
        collateralSettings[_token] = CollateralSetting({
            borrowCap: _borrowCap,
            collateralFactor: _collateralFactor,
            borrowFee: _borrowFee,
            isStable: _isStable,
            liquidationThreshold: _liquidationThreshold,
            liquidationPenalty: _liquidationPenalty,
            auctionStep: _auctionStep,
            auctionFactor: _auctionFactor,
            liquidationPaused: collateralSettings[_token].liquidationPaused,
            decimals: ERC20(_token).decimals(),
            isLp: false,
            borrowedShare: collateralSettings[_token].borrowedShare,
            masterPlatypus: IMasterPlatypusV4(address(0)),
            pid: 0
        });

        if (isNewSetting) {
            collateralTokens.push(_token);
            emit AddCollateralToken(_token);
        }
        emit SetCollateralToken(_token, collateralSettings[_token]);
    }

    /**
     * Public/External Functions
     */

    /**
     * @notice collect protocol fees accrued so far
     * @dev safe from reentrancy
     */
    function collectFee() external returns (uint256 feeCollected) {
        _accrue();

        // collect protocol fees in USP
        feeCollected = feesToBeCollected;
        feesToBeCollected = 0;
        usp.mint(feeTo, feeCollected);
    }

    /**
     * @notice Add non-LP tokens as collateral, e.g PTP or AVAX
     * @dev Tokens will be stored in this contract, won't go to master platypus
     * Follows Checks-Effects-Interactions
     * @param _token address of collateral token
     * @param _amount collateral amounts to deposit
     */
    function addCollateral(ERC20 _token, uint256 _amount) public {
        CollateralSetting storage setting = collateralSettings[_token];
        // check if collateral exists and is valid
        _checkCollateralExist(_token);
        if (setting.isLp) revert PlatypusTreasure_InvalidToken();
        if (_amount == 0) revert PlatypusTreasure_InvalidAmount();

        // update collateral position
        Position storage position = userPositions[_token][msg.sender];
        position.collateralAmount += toUint128(_amount);

        emit AddCollateral(msg.sender, _token, _amount);
        ERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
    }

    /**
     * @notice Remove non-LP collaterals, e.g PTP or AVAX
     * @dev Transfer collateral tokens to the user
     * Follows Checks-Effects-Interactions
     * @param _token address of collateral token
     * @param _amount collateral amounts to withdraw
     */
    function removeCollateral(ERC20 _token, uint256 _amount) public {
        CollateralSetting storage setting = collateralSettings[_token];
        // check if collateral exists and is valid
        _checkCollateralExist(_token);
        if (setting.isLp) revert PlatypusTreasure_InvalidToken();
        if (_amount == 0) revert PlatypusTreasure_InvalidAmount();

        // update collateral position
        Position storage position = userPositions[_token][msg.sender];
        if (_amount > position.collateralAmount) revert PlatypusTreasure_InvalidAmount();
        position.collateralAmount -= toUint128(_amount);

        (bool solvent, ) = _isSolvent(msg.sender, _token, true);
        if (!solvent) revert PlatypusTreasure_ExceedCollateralFactor();

        emit RemoveCollateral(msg.sender, _token, _amount);
        ERC20(_token).safeTransfer(msg.sender, _amount);
    }

    /**
     * @notice borrow USP
     * @dev user can call this function after depositing his/her collateral
     * Follows Checks-Effects-Interactions
     * @param _token collateral token address
     * @param _borrowAmount USP amount to borrow
     */
    function borrow(ERC20 _token, uint256 _borrowAmount) public {
        if (marketSetting.borrowPaused == true) revert PlatypusTreasure_BorrowPaused();
        if (_borrowAmount == 0) revert PlatypusTreasure_InvalidAmount();
        CollateralSetting storage setting = collateralSettings[_token];
        // check if collateral exists
        _checkCollateralExist(_token);

        _accrue();

        // calculate borrow limit in USD
        uint256 borrowLimit = _borrowLimitUSP(msg.sender, _token);
        // calculate debt amount in USP
        uint256 debtAmount = _debtAmountUSP(msg.sender, _token);

        // check if the position exceeds borrow limit
        if (debtAmount + _borrowAmount > borrowLimit) revert PlatypusTreasure_ExceedCollateralFactor();
        // check if it reaches minimum borrow amount
        if (debtAmount + _borrowAmount < uint256(marketSetting.mininumBorrowAmount) * 1e18) {
            revert PlatypusTreasure_MinimumBorrowAmountNotSatisfied();
        }
        // if the stablecoin is about to unpeg (p < 0.98), minting is disallowed
        if (setting.isStable) {
            uint256 oneUnit = 10**collateralSettings[_token].decimals;
            uint256 price = _tokenPriceUSD(_token, oneUnit);
            if (price < 98e16) {
                revert PlatypusTreasure_BorrowDisallowed();
            }
        }

        // calculate USP borrow fee
        uint256 borrowFee = (_borrowAmount * setting.borrowFee) / 10000;
        feesToBeCollected += toUint112(borrowFee);

        // update collateral position
        uint256 borrowShare = totalDebtShare == 0 ? _borrowAmount : (_borrowAmount * totalDebtShare) / totalDebtAmount;
        userPositions[_token][msg.sender].debtShare += toUint128(borrowShare);
        setting.borrowedShare += toUint128(borrowShare);
        totalDebtShare += toUint128(borrowShare);
        totalDebtAmount += toUint112(_borrowAmount);

        // check if the position exceeds borrow cap of this collateral
        uint256 totalBorrowedUSP = (uint256(setting.borrowedShare) * uint256(totalDebtAmount)) /
            uint256(totalDebtShare);
        if (totalBorrowedUSP > uint256(setting.borrowCap) * 1e18) revert PlatypusTreasure_ExceedCap();

        emit Borrow(msg.sender, _token, _borrowAmount);
        emit Accrue(borrowFee);

        // mint USP to user
        usp.mint(msg.sender, _borrowAmount - borrowFee);
    }

    /**
     * @notice repay debt with USP. The caller is suggested to increase _repayAmount by 0.01 if
     * he wants to repay all of this USP in case interest accrus
     * @dev user can call this function after approving his/her USP amount to repay.
     * Follows Checks-Effects-Interactions
     * @param _token collateral token address
     * @param _repayAmount USP amount to repay
     * @return repayShare
     */
    function repay(ERC20 _token, uint256 _repayAmount) public nonReentrant returns (uint256) {
        CollateralSetting storage setting = collateralSettings[_token];
        // check if collateral exists
        _checkCollateralExist(_token);
        if (_repayAmount == 0) revert PlatypusTreasure_InvalidAmount();

        _accrue();

        Position storage position = userPositions[_token][msg.sender];

        // calculate debt amount in USD
        uint256 debtAmount = _debtAmountUSP(msg.sender, _token);

        uint256 repayShare;
        if (_repayAmount >= debtAmount) {
            // only pays for the debt and returns remainings
            _repayAmount = debtAmount;
            repayShare = position.debtShare;
        } else {
            repayShare = (_repayAmount * totalDebtShare) / totalDebtAmount;
        }

        // check mininumBorrowAmount
        if (
            debtAmount - _repayAmount > 0 &&
            debtAmount - _repayAmount < uint256(marketSetting.mininumBorrowAmount) * 1e18
        ) {
            revert PlatypusTreasure_MinimumBorrowAmountNotSatisfied();
        }

        // update user's collateral position
        position.debtShare -= toUint128(repayShare);

        // update total debt
        totalDebtShare -= toUint128(repayShare);
        totalDebtAmount -= toUint112(_repayAmount);
        setting.borrowedShare -= toUint128(repayShare);

        emit Repay(msg.sender, _token, _repayAmount);

        // burn repaid USP
        usp.burnFrom(msg.sender, _repayAmount);

        return repayShare;
    }

    /**
     * Liquidation Module
     */

    /// @notice Return the number of active auctions
    function activeAuctionLength() external view returns (uint256) {
        return activeAuctions.length;
    }

    /// @notice Return the entire array of active auctions
    function getActiveAuctions() external view returns (uint48[] memory) {
        return activeAuctions;
    }

    /// @notice Burn USP to fill unbacked USP
    /// @dev Can be call by any party
    function fillUnbackedUsp(uint128 _amount) external {
        usp.burnFrom(msg.sender, _amount);
        unbackedUspAmount -= _amount;
    }

    /**
     * @notice Liquidate a position and kickstart a Dutch auction to sell collaterals for USP.
     * The entire position will be liquidated but it can be partially filled as stated in `buyCollateral()`.
     * Liquidation penalty is included in the debt amount. The starting price of the auction is read from
     * oracle and is increased percentage-wise by `buf` (withdrawal fee for LP is
     * ignored in case of flash-loan). The price decreases as a function of time defined by `calculatePrice()`.
     *
     * @dev It checks
     * - liquidation isn't paused
     * - the position is default
     * It performs several actions:
     * - (pushes the bad debt into the debt queue)
     * - initiates the auction (debt amountinclude penalty, the price)
     * - remove collateral from the position (and masterPlatypus is needed)
     * - adds the bad debt plus the liquidation penalty to accumulator
     * - sends an incentive denominated in USP to the keeper (`kickIncentive` + 0.1% of USP to raise)
     */
    function startAuction(
        address _user,
        ERC20 _token,
        address _incentiveReceiver
    ) public nonReentrant returns (uint256 auctionId) {
        /********** Checks **********/
        CollateralSetting storage collateral = collateralSettings[_token];
        if (marketSetting.liquidationPaused || collateral.liquidationPaused) revert Liquidation_Paused();

        _checkCollateralExist(_token);

        _accrue();

        uint256 debtAmount = _debtAmountUSP(_user, _token);
        bool liquidable = debtAmount > 0 && debtAmount > _liquidateLimitUSP(_user, _token);

        if (!liquidable) revert PlatypusTreasure_NotLiquidable();

        /********** Grab collateral from the treasure **********/

        Position storage position = userPositions[_token][_user];
        uint256 collateralAmount = _getCollateralAmount(_token, _user);

        // if collateral is lp, this function withdraws the lp from masterplatypus to the treasure
        _grabCollateral(_user, _token, collateralAmount, position.debtShare);

        /********** Initiate Auction **********/

        uint256 uspToRaise = (debtAmount * (10000 + collateral.liquidationPenalty)) / 10000;

        // incentives for kick-starting the auction = `kickIncentive` + 0.1% of USP to raise
        // Important note: the incentive + liquidation reward should remain less than the minimum
        // liquidation penalty by some margin of safety so that the system is unlikely to accrue a deficit
        uint256 incentive = marketSetting.kickIncentive * 1e18 + uspToRaise / 1000;
        unbackedUspAmount += toUint128(uspToRaise + incentive);

        // add liquidation penalty to protocol income
        feesToBeCollected += toUint112(uspToRaise - debtAmount);

        auctionId = _initiateAuction(_user, _token, toUint128(collateralAmount), toUint128(uspToRaise));

        // mint incentive to keeper
        usp.mint(_incentiveReceiver, incentive);

        emit StartAuction(auctionId, _user, _token, collateralAmount, uspToRaise);
        emit Accrue(uspToRaise - debtAmount);
    }

    /**
     * @notice remove collateral from the position to prepare for liquidation
     */
    function _grabCollateral(
        address _user,
        ERC20 _token,
        uint256 collateralAmount,
        uint256 debtShare
    ) internal {
        CollateralSetting storage collateral = collateralSettings[_token];
        Position storage position = userPositions[_token][_user];

        if (collateral.isLp) {
            // withdraw from masterPlatypus if it is an LP token
            collateral.masterPlatypus.liquidate(collateral.pid, _user, collateralAmount);
        } else {
            position.collateralAmount -= toUint128(collateralAmount);
        }

        position.debtShare -= toUint128(debtShare);

        uint256 debtAmount = (debtShare * totalDebtAmount) / totalDebtShare;

        totalDebtShare -= toUint128(debtShare);
        totalDebtAmount -= toUint112(debtAmount);
        collateral.borrowedShare -= toUint128(debtShare);
    }

    /**
     * @dev It performs the following action
     * - increments a counter and assigns a unique numerical id to the new auction
     * - inserts the id into a list tracking active auctions
     * - creates a structure to record the parameters of the auction
     */
    function _initiateAuction(
        address _user,
        ERC20 _token,
        uint128 _collateralAmount,
        uint128 _uspAmount
    ) internal returns (uint48 id) {
        id = ++totalAuctions;
        activeAuctions.push(id);

        uint256 oneUnit = 10**collateralSettings[_token].decimals;

        // For starting price
        // collateral factor * (1 + penalty) * (1 + buffer) should be < 100% to left some profit margin for liquidator
        auctions[id] = Auction({
            collateralAmount: _collateralAmount,
            startTime: uint40(block.timestamp),
            startPrice: toUint96(_tokenPriceUSD(_token, oneUnit)),
            index: uint48(activeAuctions.length - 1),
            token: _token,
            user: _user,
            uspAmount: _uspAmount
        });
    }

    /**
     * @notice Buy collateral at the current price as given by `calculatePrice()`. Flash lending of collateral
     * is supported but `msg.sender` should have prepared USP and approved this contract `uspAmount` of USP
     * @dev Following scenarios can happen when bidding on auctions
     * - Settling all debt while buying full collateral up for sale
     * - Settling all debt while buying only a part of the collateral up for sale
     * - Settling the debt only partially while buying the full collateral up for sale (bad debt)
     * - Settling the debt only partially for a part of the collateral up for sale (partial liquidation)
     * To avoid leaving a dust amount, remaining USP debt should be greater than `mininumBorrowAmount`
     */
    function buyCollateral(
        uint256 id,
        uint256 maxCollateralAmount,
        uint256 maxPrice,
        address who,
        bytes memory data
    ) public nonReentrant returns (uint256 bidCollateralAmount, uint256 uspAmount) {
        // Note: there is no auction reset

        /********** Checks **********/

        Auction memory auction = auctions[id];
        if (auction.collateralAmount == 0) revert Liquidation_Invalid_Auction_Id();

        uint256 price = calculatePrice(auction.token, auction.startPrice, block.timestamp - auction.startTime);
        if (maxPrice < price) revert Liquidation_Exceed_Max_Price(price);

        /********** Calculate repay amount **********/

        uint256 collateralToSell = auction.collateralAmount;
        uint256 uspToRaise = auction.uspAmount;
        uint256 oneUnit = 10**collateralSettings[auction.token].decimals;

        // purchase as much collateral as possible
        bidCollateralAmount = collateralToSell < maxCollateralAmount ? collateralToSell : maxCollateralAmount;
        uspAmount = (price * bidCollateralAmount) / oneUnit;

        if (uspAmount > uspToRaise) {
            // Don't collect more USP than the debt
            uspAmount = uspToRaise;
            bidCollateralAmount = (uspAmount * oneUnit) / price;
        } else if (uspAmount < uspToRaise && bidCollateralAmount < collateralToSell) {
            // Leave at least `minimumRemainingUsp` to avoid dust amount in the debt
            // minimumRemainingUsp = debt floot * (1 + liquidation penalty)
            // `x * 1e14` =  `x / 10000 * 1e14`
            uint256 minimumRemainingUsp = (marketSetting.mininumBorrowAmount *
                (uint256(10000) + collateralSettings[auction.token].liquidationPenalty)) * 1e14;
            if (uspToRaise - uspAmount < minimumRemainingUsp) {
                if (uspToRaise <= minimumRemainingUsp) revert Liquidation_Liquidator_Should_Take_All_Collateral();

                uspAmount = uspToRaise - minimumRemainingUsp;
                bidCollateralAmount = (uspAmount * oneUnit) / price;
            }
        }

        /********** Execute repay with flash lending of collateral **********/

        // send collateral to `who`
        ERC20(auction.token).safeTransfer(who, bidCollateralAmount);

        // Do external call if data is defined
        if (data.length > 0) {
            // The callee can swap collateral to USP in the callback
            // Caution: Ensure this contract isn't authorized over the callee
            LiquidationCallback(who).callback(uspAmount, bidCollateralAmount, msg.sender, data);
        }

        // get collaterals, msg.sender should approve USP spending
        usp.burnFrom(msg.sender, uspAmount);

        /********** Update states **********/

        // remaining USP to raise and remaining collateral to sell
        collateralToSell -= bidCollateralAmount;
        uspToRaise -= uspAmount;

        // remove USP out of liquidation
        // collateralSettings[auction.token].uspToRaise -= uspAmount;
        unbackedUspAmount -= toUint128(uspAmount);

        if (collateralToSell == 0) {
            if (uspToRaise > 0) {
                // Bad debt: remove remaining `uspToRaise` from collateral setting
                // Note: If there's USP left to raise, we could spread it over all borrowers
                // or use protocol fee to fill it
                // collateralSettings[auction.token].uspToRaise -= uspToRaise;
                emit BadDebt(id, auction.user, auction.token, uspToRaise);
            }
            _removeAuction(id);
        } else if (uspToRaise == 0) {
            // All USP is repaid, return remaining collateral to the user
            ERC20(auction.token).safeTransfer(auction.user, collateralToSell);
            _removeAuction(id);
        } else {
            // update storage
            auctions[id].uspAmount = uint128(uspToRaise);
            auctions[id].collateralAmount = uint128(collateralToSell);
        }

        emit BuyCollateral(id, auction.user, auction.token, bidCollateralAmount, uspAmount);
    }

    /**
     * @notice Calculate the collateral price of a liquidation given startPrice and timeElapsed.
     * Stairstep Exponential Decrease:
     * - multiply the price by `auctionFactor` for every `auctionStep` seconds pass
     */
    function calculatePrice(
        ERC20 _token,
        uint256 _startPrice,
        uint256 _timeElapsed
    ) public view returns (uint256) {
        CollateralSetting storage collateral = collateralSettings[_token];

        uint256 discountFactor = FixedPointMathLib.rpow(
            (uint256(collateral.auctionFactor) * 1e18) / 10000,
            _timeElapsed / collateral.auctionStep,
            1e18
        );

        return (discountFactor * _startPrice) / 1e18;
    }

    /**
     * @notice Return the current unit price of an active auction
     * @dev Returned price is 0 if it is not an active auction
     */
    function calculatePriceOfAuctions(uint256[] calldata ids) external view returns (uint256[] memory prices) {
        uint256 len = ids.length;
        prices = new uint256[](len);

        for (uint256 i; i < len; ++i) {
            uint256 id = ids[i];

            Auction memory auction = auctions[id];
            if (auction.collateralAmount != 0) {
                prices[i] = calculatePrice(auction.token, auction.startPrice, block.timestamp - auction.startTime);
            }
        }
    }

    function _removeAuction(uint256 id) internal {
        // remove the auction from `activeAuctions` and replace it with the last auction
        uint48 lastId = activeAuctions[activeAuctions.length - 1];
        if (id != lastId) {
            uint48 indexToRemove = auctions[id].index;
            activeAuctions[indexToRemove] = lastId;
            auctions[lastId].index = indexToRemove;
        }
        activeAuctions.pop();
        delete auctions[id];
    }

    /**
     * Helper Functions
     */

    uint8 constant ACTION_ADD_COLLATERAL = 1;
    uint8 constant ACTION_REMOVE_COLLATERAL = 2;
    uint8 constant ACTION_BORROW = 3;
    uint8 constant ACTION_REPAY = 4;
    uint8 constant ACTION_START_AUCTION = 5;
    uint8 constant ACTION_BUY_COLLATERAL = 6;

    /// @notice Executes a set of actions
    /// @dev This function should not accept arbitrary call as the contract is able to liquidate LPs in MasterPlatypus
    function cook(uint8[] calldata actions, bytes[] calldata datas) external {
        for (uint256 i; i < actions.length; ++i) {
            uint8 action = actions[i];
            if (action == ACTION_ADD_COLLATERAL) {
                (ERC20 _token, uint256 _amount) = abi.decode(datas[i], (ERC20, uint256));
                addCollateral(_token, _amount);
            } else if (action == ACTION_REMOVE_COLLATERAL) {
                (ERC20 _token, uint256 _amount) = abi.decode(datas[i], (ERC20, uint256));
                removeCollateral(_token, _amount);
            } else if (action == ACTION_BORROW) {
                (ERC20 _token, uint256 _borrowAmount) = abi.decode(datas[i], (ERC20, uint256));
                borrow(_token, _borrowAmount);
            } else if (action == ACTION_REPAY) {
                (ERC20 _token, uint256 _repayAmount) = abi.decode(datas[i], (ERC20, uint256));
                repay(_token, _repayAmount);
            } else if (action == ACTION_START_AUCTION) {
                (address _user, ERC20 _token, address _incentiveReceiver) = abi.decode(
                    datas[i],
                    (address, ERC20, address)
                );
                startAuction(_user, _token, _incentiveReceiver);
            } else if (action == ACTION_BUY_COLLATERAL) {
                (uint256 id, uint256 maxCollateralAmount, uint256 maxPrice, address who, bytes memory data) = abi
                    .decode(datas[i], (uint256, uint256, uint256, address, bytes));
                buyCollateral(id, maxCollateralAmount, maxPrice, who, data);
            }
        }
    }

    /**
     * @notice returns a user's collateral position
     * @return position this includes a user's collateral, debt, liquidation data.
     */
    function positionView(address _user, ERC20 _token) external view returns (PositionView memory) {
        Position memory position = userPositions[_token][_user];

        (bool solvent, ) = _isSolvent(_user, _token, false);
        uint256 collateralAmount = _getCollateralAmount(_token, _user);
        uint256 liquidateLimitUSP = _liquidateLimitUSP(_user, _token);
        uint256 debtAmountUSP = _debtAmountUSP(_user, _token);
        // `healthFactor` is 0 if `debtAmountUSP` is 0
        uint256 healthFactor = debtAmountUSP == 0 ? 0 : (liquidateLimitUSP * 1e18) / debtAmountUSP;

        return
            PositionView({
                collateralAmount: collateralAmount,
                collateralUSD: _tokenPriceUSD(_token, collateralAmount),
                borrowLimitUSP: _borrowLimitUSP(_user, _token),
                liquidateLimitUSP: liquidateLimitUSP,
                debtAmountUSP: debtAmountUSP,
                debtShare: position.debtShare,
                healthFactor: healthFactor,
                liquidable: !solvent
            });
    }

    /**
     * @notice return available amount to borrow for this collateral
     * @param _token collateral token address
     * @return uint256 available amount to borrow
     */
    function availableUSP(ERC20 _token) external view returns (uint256) {
        CollateralSetting storage setting = collateralSettings[_token];
        uint256 outstandingLoan = totalDebtShare == 0
            ? 0
            : (uint256(setting.borrowedShare) * uint256(totalDebtAmount)) / uint256(totalDebtShare);
        if (uint256(setting.borrowCap) * 1e18 > outstandingLoan) {
            return uint256(setting.borrowCap) * 1e18 - outstandingLoan;
        }
        return 0;
    }

    /**
     * @notice Return the unit price of LP token
     * It should equal to the underlying token price adjusted by the exchange rate
     */
    function getLPUnitPrice(IAsset _lp) external view returns (uint256) {
        return _getLPUnitPrice(_lp);
    }

    /**
     * @notice function to check if user's collateral position is solvent
     * @dev returns (true, 0) if the token is not a valid collateral
     * @param _user address of the user
     * @param _token address of the token
     * @param _open open a position or close a position
     * @return solvent
     * @return debtAmount total debt amount including interests
     */
    function isSolvent(
        address _user,
        ERC20 _token,
        bool _open
    ) external view returns (bool solvent, uint256 debtAmount) {
        return _isSolvent(_user, _token, _open);
    }

    /**
     * Internal Functions
     */

    function _checkCollateralExist(ERC20 _token) internal view {
        if (collateralSettings[_token].decimals == 0) revert PlatypusTreasure_InvalidToken();
    }

    /**
     * @notice _accrue debt interest
     * @dev Updates the contract's state by calculating the additional interest accrued since the last time
     */
    function _accrue() internal {
        uint256 interest = _interestSinceLastAccrue();

        // set last time accrued. unsafe cast is intended
        lastAccrued = uint32(block.timestamp);

        // plus interest
        totalDebtAmount += toUint112(interest);
        feesToBeCollected += toUint112(interest);

        emit Accrue(interest);
    }

    /**
     * @notice function to check if user's collateral position is solvent
     * @dev returns (true, 0) if the token is not a valid collateral
     * @param _user address of the user
     * @param _token address of the token
     * @param _open open a position or close a position
     * @return solvent
     * @return debtAmount total debt amount including interests
     */
    function _isSolvent(
        address _user,
        ERC20 _token,
        bool _open
    ) internal view returns (bool solvent, uint256 debtAmount) {
        uint256 debtShare = userPositions[_token][_user].debtShare;

        // fast path
        if (debtShare == 0) return (true, 0);

        // totalDebtShare > 0 as debtShare is non-zero
        debtAmount = (debtShare * (totalDebtAmount + _interestSinceLastAccrue())) / totalDebtShare;
        solvent = debtAmount <= (_open ? _borrowLimitUSP(_user, _token) : _liquidateLimitUSP(_user, _token));
    }

    /**
     * @notice function that returns the collateral lp tokens deposited on master platypus
     * @param _token collateral lp address
     * @param _user user address
     * @return uint of collateral amount
     */
    function _getCollateralAmount(ERC20 _token, address _user) internal view returns (uint256) {
        CollateralSetting storage setting = collateralSettings[_token];
        if (setting.isLp) {
            return setting.masterPlatypus.getUserInfo(setting.pid, _user).amount;
        } else {
            return userPositions[_token][_user].collateralAmount;
        }
    }

    /**
     * @notice calculate additional interest accrued from last time
     * @return The interest accrued from last time
     */
    function _interestSinceLastAccrue() internal view returns (uint256) {
        // calculate elapsed time from last accrued at
        uint256 elapsedTime;
        unchecked {
            // underflow is intended
            elapsedTime = uint32(block.timestamp) - lastAccrued;
        }
        // Note: it is possible to make minimal interval between accrue in the future (e.g. 1h) to save gas
        if (elapsedTime == 0) return 0;

        // calculate interest based on elapsed time and interest rate
        return (elapsedTime * totalDebtAmount * _interestRate()) / 10000 / 365 days;
    }

    /**
     * @notice Return the dynamic interest rate based on the cov ratio of USP in main pool
     * @dev interest rate = c ^ k / 100
     * @return InterestRate e.g 1500 = 15%, base 10000
     */
    function _interestRate() internal view returns (uint256) {
        IAsset uspLp = marketSetting.uspLp;
        uint256 liability = uspLp.liability();
        if (liability == 0) return 0;

        uint256 covRatio = (uspLp.cash() * 1e18) / liability;
        // Interest rate has 1e18 * 1e2 decimals => interest rate / 100 / 1e18 * 10000 => / 1e16
        uint256 interestRate = covRatio.rpow(marketSetting.k, 1e18) / 1e16;
        // cap interest rate by 1000%
        return interestRate <= 100000 ? interestRate : 100000;
    }

    /**
     * @notice External view function that returns dynamic interest rates from the cov ratio of USP in the main pool
     * @dev interest rate = c ^ k / 100
     * @return InterestRate e.g 15% = 1500, base 10000
     */
    function currentInterestRate() external view returns (uint256) {
        return _interestRate();
    }

    /**
     * @notice Return the price of LP token
     * It should equal to the underlying token price adjusted by the exchange rate
     */
    function _getLPUnitPrice(IAsset _lp) internal view returns (uint256) {
        uint256 underlyingTokenPrice = oracle.getAssetPrice(IAsset(_lp).underlyingToken());
        uint256 totalSupply = IAsset(_lp).totalSupply();

        if (totalSupply == 0) {
            return underlyingTokenPrice;
        } else {
            // Note: Withdrawal loss is not considered here. And it should not been taken into consideration for
            // liquidation criteria.
            return (underlyingTokenPrice * IAsset(_lp).liability()) / totalSupply;
        }
    }

    /**
     * @notice returns the USD price of given token amount in 18 d.p
     * @param _token collateral token address
     * @param _amount token amount
     * @return The USD amount in 18 decimals
     */
    function _tokenPriceUSD(ERC20 _token, uint256 _amount) internal view returns (uint256) {
        CollateralSetting storage setting = collateralSettings[_token];
        uint256 unitPrice;
        if (setting.isLp) {
            unitPrice = _getLPUnitPrice(IAsset(address(_token)));
        } else {
            unitPrice = oracle.getAssetPrice(address(_token));
        }
        // Convert to 18 decimals. Price quoted in USD has 8 decimals
        return (_amount * unitPrice * 1e10) / 10**(setting.decimals);
    }

    /**
     * @notice returns the borrow limit amount in USD
     * @param _user user address
     * @param _token collateral token address
     * @return uint256 The USD amount in 18 decimals
     */
    function _borrowLimitUSP(address _user, ERC20 _token) internal view returns (uint256) {
        uint256 amount = _getCollateralAmount(_token, _user);
        uint256 totalUSD = _tokenPriceUSD(_token, amount);
        return (totalUSD * collateralSettings[_token].collateralFactor) / 10000;
    }

    /**
     * @notice returns the liquidation threshold amount in USD
     * @param _user user address
     * @param _token collateral token address
     * @return The USD amount in 18 decimals
     */
    function _liquidateLimitUSP(address _user, ERC20 _token) internal view returns (uint256) {
        uint256 amount = _getCollateralAmount(_token, _user);
        uint256 totalUSD = _tokenPriceUSD(_token, amount);
        return (totalUSD * collateralSettings[_token].liquidationThreshold) / 10000;
    }

    /**
     * @notice returns the debt amount in USD
     * @dev interest is skipped due to gas
     * @param _user user address
     * @param _token collateral token address
     * @return The USD amount in 18 decimals
     */
    function _debtAmountUSP(address _user, ERC20 _token) internal view returns (uint256) {
        if (totalDebtShare == 0) return 0;
        return
            (uint256(userPositions[_token][_user].debtShare) * (totalDebtAmount + _interestSinceLastAccrue())) /
            totalDebtShare;
    }

    function toUint96(uint256 val) internal pure returns (uint96) {
        if (val > type(uint96).max) revert Uint96_Overflow();
        return uint96(val);
    }

    function toUint112(uint256 val) internal pure returns (uint112) {
        if (val > type(uint112).max) revert Uint112_Overflow();
        return uint112(val);
    }

    function toUint128(uint256 val) internal pure returns (uint128) {
        if (val > type(uint128).max) revert Uint128_Overflow();
        return uint128(val);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.14;

import '@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/interfaces/IERC3156FlashLenderUpgradeable.sol';

interface IUSP is IERC20Upgradeable, IERC3156FlashLenderUpgradeable {
    function mint(address _to, uint256 _amount) external;

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

// Based on AAVE protocol
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

/// @title IPriceOracleGetter interface
interface IPriceOracleGetter {
    /// @dev returns the asset price in ETH
    function getAssetPrice(address _asset) external view returns (uint256);

    /// @dev returns the reciprocal of asset price
    function getAssetPriceReciprocal(address _asset) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

interface IPool {
    function assetOf(address token) external view returns (address);

    function deposit(
        address token,
        uint256 amount,
        address to,
        uint256 deadline
    ) external returns (uint256 liquidity);

    function withdraw(
        address token,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amount);

    function withdrawFromOtherAsset(
        address initialToken,
        address wantedToken,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amount);

    function swap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 actualToAmount, uint256 haircut);

    function quotePotentialSwap(
        address fromToken,
        address toToken,
        uint256 fromAmount
    ) external view returns (uint256 potentialOutcome, uint256 haircut);

    function quotePotentialWithdraw(address token, uint256 liquidity)
        external
        view
        returns (
            uint256 amount,
            uint256 fee,
            bool enoughCash
        );

    function quotePotentialWithdrawFromOtherAsset(
        address initialToken,
        address wantedToken,
        uint256 liquidity
    ) external view returns (uint256 amount, uint256 fee);

    function quoteMaxInitialAssetWithdrawable(address initialToken, address wantedToken)
        external
        view
        returns (uint256 maxInitialAssetAmount);

    function getTokenAddresses() external view returns (address[] memory);

    function addAsset(address token, address asset) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20Upgradeable.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import './IVeERC20.sol';

/**
 * @dev Interface of the VePtp
 */
interface IVePtpV3 is IVeERC20 {
    function isUserStaking(address _addr) external view returns (bool);

    function deposit(uint256 _amount) external;

    function lockPtp(uint256 _amount, uint256 _lockDays) external returns (uint256);

    function extendLock(uint256 _daysToExtend) external returns (uint256);

    function addPtpToLock(uint256 _amount) external returns (uint256);

    function unlockPtp() external returns (uint256);

    function claim() external;

    function claimable(address _addr) external view returns (uint256);

    function claimableWithXp(address _addr) external view returns (uint256 amount, uint256 xp);

    function withdraw(uint256 _amount) external;

    function vePtpBurnedOnWithdraw(address _addr, uint256 _amount) external view returns (uint256);

    function stakeNft(uint256 _tokenId) external;

    function unstakeNft() external;

    function getStakedNft(address _addr) external view returns (uint256);

    function getStakedPtp(address _addr) external view returns (uint256);

    function levelUp(uint256[] memory platypusBurned) external;

    function levelDown() external;

    function getVotes(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.14;

import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@rari-capital/solmate/src/utils/SafeTransferLib.sol';
import '@rari-capital/solmate/src/tokens/ERC20.sol';
import '../interfaces/IBribe.sol';

interface IVoter {
    // lpToken => weight, equals to sum of votes for a LP token
    function weights(address _lpToken) external view returns (uint256);

    // user address => lpToken => votes
    function votes(address _user, address _lpToken) external view returns (uint256);
}

/**
 * Simple bribe per sec. Distribute bribe rewards to voters
 * fork from SimpleRewarder.
 * Bribe.onVote->updatePool() is a bit different from SimpleRewarder.
 * Here we reduce the original total amount of share
 */
contract Bribe is IBribe, Ownable, ReentrancyGuard {
    using SafeTransferLib for ERC20;

    uint256 public immutable ACC_TOKEN_PRECISION;
    ERC20 public immutable override rewardToken;
    address public immutable lpToken;
    bool public immutable isNative;
    address public immutable voter;

    /// @notice Info of each voter user.
    /// `amount` LP token amount the user has provided.
    /// `rewardDebt` The amount of YOUR_TOKEN entitled to the user.
    struct UserInfo {
        uint128 amount; // 20.18 fixed point
        uint128 rewardDebt; // 26.12 fixed point
        uint256 unpaidRewards;
    }

    /// @notice Info of each voter poolInfo.
    /// `accTokenPerShare` Amount of YOUR_TOKEN each LP token is worth.
    /// `lastRewardTimestamp` The last timestamp YOUR_TOKEN was rewarded to the poolInfo.
    struct PoolInfo {
        uint128 accTokenPerShare; // 20.18 fixed point
        uint48 lastRewardTimestamp;
    }

    /// @notice address of the operator
    /// @dev operator is able to set emission rate
    address public operator;

    /// @notice Info of the poolInfo.
    PoolInfo public poolInfo;
    /// @notice Info of each user that stakes LP tokens.
    mapping(address => UserInfo) public userInfo;

    uint256 public tokenPerSec;

    event OnReward(address indexed user, uint256 amount);
    event RewardRateUpdated(uint256 oldRate, uint256 newRate);

    modifier onlyVoter() {
        require(msg.sender == address(voter), 'onlyVoter: only MasterPlatypus can call this function');
        _;
    }

    modifier onlyOperatorOrOwner() {
        require(msg.sender == owner() || msg.sender == operator, 'onlyOperatorOrOwner');
        _;
    }

    constructor(
        address _voter,
        address _lpToken,
        ERC20 _rewardToken,
        uint256 _tokenPerSec,
        bool _isNative
    ) {
        require(Address.isContract(address(_rewardToken)), 'constructor: reward token must be a valid contract');
        require(Address.isContract(address(_lpToken)), 'constructor: LP token must be a valid contract');
        require(Address.isContract(address(_voter)), 'constructor: Voter must be a valid contract');
        require(_rewardToken.decimals() <= 30, 'constructor: too much decimal for _rewardToken');

        ACC_TOKEN_PRECISION = 1e30 / (10**_rewardToken.decimals());

        voter = _voter;
        lpToken = _lpToken;
        rewardToken = _rewardToken;
        tokenPerSec = _tokenPerSec;
        isNative = _isNative;
        poolInfo = PoolInfo({lastRewardTimestamp: uint48(block.timestamp), accTokenPerShare: 0});
    }

    /// @notice Set operator address
    function setOperator(address _operator) external onlyOwner {
        operator = _operator;
    }

    /// @notice Update reward variables of the given poolInfo.
    function updatePool() public {
        PoolInfo memory pool = poolInfo;

        if (block.timestamp > pool.lastRewardTimestamp) {
            uint256 totalShares = _getTotalShare();

            if (totalShares > 0) {
                uint256 timeElapsed = block.timestamp - pool.lastRewardTimestamp;
                uint256 tokenReward = timeElapsed * tokenPerSec;
                pool.accTokenPerShare += toUint128((tokenReward * ACC_TOKEN_PRECISION) / totalShares);
            }

            pool.lastRewardTimestamp = uint48(block.timestamp);
            poolInfo = pool;
        }
    }

    /// @notice Sets the distribution reward rate. This will also update the poolInfo.
    /// @param _tokenPerSec The number of tokens to distribute per second
    function setRewardRate(uint256 _tokenPerSec) external onlyOperatorOrOwner {
        require(_tokenPerSec <= 10000e18, 'reward rate too high'); // in case of accTokenPerShare overflow
        updatePool();

        uint256 oldRate = tokenPerSec;
        tokenPerSec = _tokenPerSec;

        emit RewardRateUpdated(oldRate, _tokenPerSec);
    }

    /// @notice Function called by Voter whenever user update his vote of claim rewards
    /// @notice Allows users to receive bribes
    /// @dev assumes that _getTotalShare() returns the new amount of share
    /// @param _user Address of user
    /// @param _lpAmount Number of vote the user has
    function onVote(
        address _user,
        uint256 _lpAmount,
        uint256 originalTotalVotes
    ) external override onlyVoter nonReentrant returns (uint256) {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[_user];

        // update pool using the original total votes
        if (block.timestamp > pool.lastRewardTimestamp) {
            if (originalTotalVotes > 0) {
                uint256 timeElapsed = block.timestamp - pool.lastRewardTimestamp;
                uint256 tokenReward = timeElapsed * tokenPerSec;
                pool.accTokenPerShare += toUint128((tokenReward * ACC_TOKEN_PRECISION) / originalTotalVotes);
            }

            pool.lastRewardTimestamp = uint48(block.timestamp);
        }

        uint256 pending;
        uint256 totalSent;
        if (user.amount > 0) {
            pending =
                ((user.amount * uint256(pool.accTokenPerShare)) / ACC_TOKEN_PRECISION) -
                (user.rewardDebt) +
                (user.unpaidRewards);

            if (isNative) {
                uint256 tokenBalance = address(this).balance;
                if (pending > tokenBalance) {
                    (bool success, ) = _user.call{value: tokenBalance}('');
                    totalSent = tokenBalance;
                    require(success, 'Transfer failed');
                    user.unpaidRewards = pending - tokenBalance;
                } else {
                    (bool success, ) = _user.call{value: pending}('');
                    totalSent = pending;
                    require(success, 'Transfer failed');
                    user.unpaidRewards = 0;
                }
            } else {
                uint256 tokenBalance = rewardToken.balanceOf(address(this));
                if (pending > tokenBalance) {
                    rewardToken.safeTransfer(_user, tokenBalance);
                    totalSent = tokenBalance;
                    user.unpaidRewards = pending - tokenBalance;
                } else {
                    rewardToken.safeTransfer(_user, pending);
                    totalSent = pending;
                    user.unpaidRewards = 0;
                }
            }
        }

        user.amount = toUint128(_lpAmount);
        user.rewardDebt = toUint128((user.amount * uint256(pool.accTokenPerShare)) / ACC_TOKEN_PRECISION);
        emit OnReward(_user, totalSent);
        return totalSent;
    }

    /// @notice View function to see pending tokens
    /// @param _user Address of user.
    /// @return pending reward for a given user.
    function pendingTokens(address _user) external view override returns (uint256 pending) {
        PoolInfo memory pool = poolInfo;
        UserInfo storage user = userInfo[_user];

        uint256 accTokenPerShare = pool.accTokenPerShare;
        uint256 totalShares = _getTotalShare();

        if (block.timestamp > pool.lastRewardTimestamp && totalShares != 0) {
            uint256 timeElapsed = block.timestamp - (pool.lastRewardTimestamp);
            uint256 tokenReward = timeElapsed * (tokenPerSec);
            accTokenPerShare = accTokenPerShare + ((tokenReward * (ACC_TOKEN_PRECISION)) / totalShares);
        }

        pending =
            ((user.amount * uint256(accTokenPerShare)) / ACC_TOKEN_PRECISION) -
            (user.rewardDebt) +
            (user.unpaidRewards);
    }

    /// @notice In case rewarder is stopped before emissions finished, this function allows
    /// withdrawal of remaining tokens.
    function emergencyWithdraw() external onlyOwner {
        if (isNative) {
            (bool success, ) = msg.sender.call{value: address(this).balance}('');
            require(success, 'Transfer failed');
        } else {
            rewardToken.safeTransfer(address(msg.sender), rewardToken.balanceOf(address(this)));
        }
    }

    /// @notice avoids loosing funds in case there is any tokens sent to this contract
    function emergencyTokenWithdraw(address token) external onlyOwner {
        // send that balance back to owner
        ERC20(token).safeTransfer(msg.sender, ERC20(token).balanceOf(address(this)));
    }

    /// @notice View function to see balance of reward token.
    function balance() external view returns (uint256) {
        if (isNative) {
            return address(this).balance;
        } else {
            return rewardToken.balanceOf(address(this));
        }
    }

    function _getTotalShare() internal view returns (uint256) {
        return IVoter(voter).weights(lpToken);
    }

    function toUint128(uint256 val) internal pure returns (uint128) {
        if (val > type(uint128).max) revert('uint128 overflow');
        return uint128(val);
    }

    /// @notice payable function needed to receive AVAX
    receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC721/extensions/IERC721Enumerable.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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
}
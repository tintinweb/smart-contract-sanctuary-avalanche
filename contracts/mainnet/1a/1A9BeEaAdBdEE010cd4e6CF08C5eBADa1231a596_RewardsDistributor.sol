// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
pragma solidity 0.8.9;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function transfer(address recipient, uint amount) external returns (bool);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function balanceOf(address) external view returns (uint);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IVotingEscrow {

    struct Point {
        int128 bias;
        int128 slope; // # -dweight / dt
        uint256 ts;
        uint256 blk; // block
    }

    function token() external view returns (address);
    function team() external returns (address);
    function epoch() external view returns (uint);
    function point_history(uint loc) external view returns (Point memory);
    function user_point_history(uint tokenId, uint loc) external view returns (Point memory);
    function user_point_epoch(uint tokenId) external view returns (uint);

    function ownerOf(uint) external view returns (address);
    function isApprovedOrOwner(address, uint) external view returns (bool);
    function transferFrom(address, address, uint) external;

    function voting(uint tokenId) external;
    function abstain(uint tokenId) external;
    function attach(uint tokenId) external;
    function detach(uint tokenId) external;

    function checkpoint() external;
    function deposit_for(uint tokenId, uint value) external;
    function create_lock_for(uint, uint, address) external returns (uint);

    function balanceOfNFT(uint) external view returns (uint);
    function totalSupply() external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

library Math {
    function max(uint a, uint b) internal pure returns (uint) {
        return a >= b ? a : b;
    }
    function min(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
    function cbrt(uint256 n) internal pure returns (uint256) { unchecked {
        uint256 x = 0;
        for (uint256 y = 1 << 255; y > 0; y >>= 3) {
            x <<= 1;
            uint256 z = 3 * x * (x + 1) + 1;
            if (n / y >= z) {
                n -= y * z;
                x += 1;
            }
        }
        return x;
    }}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./libraries/Math.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IVotingEscrow.sol";

/** 
* @title Curve Fee Distribution modified for ve(3,3) emissions
*/
contract RewardsDistributor is Initializable {

    event CheckpointToken(
        uint time,
        uint tokens
    );

    event Claimed(
        uint tokenId,
        uint amount,
        uint claim_epoch,
        uint max_epoch
    );

    uint constant WEEK = 7 * 86400;

    uint public start_time;
    uint public time_cursor;
    mapping(uint => uint) public time_cursor_of;
    mapping(uint => uint) public user_epoch_of;

    uint public last_token_time;
    uint[1000000000000000] public tokens_per_week;

    address public voting_escrow;
    address public token;
    uint public token_last_balance;

    uint[1000000000000000] public ve_supply;

    address public depositor;

    function initialize(address _voting_escrow) public initializer {
        uint _t = block.timestamp / WEEK * WEEK;
        start_time = _t;
        last_token_time = _t;
        time_cursor = _t;
        address _token = IVotingEscrow(_voting_escrow).token();
        token = _token;
        voting_escrow = _voting_escrow;
        depositor = msg.sender;
        require(IERC20(_token).approve(_voting_escrow, type(uint).max));
    }

    function timestamp() external view returns (uint) {
        return block.timestamp / WEEK * WEEK;
    }

    function _checkpoint_token() internal {
        uint token_balance = IERC20(token).balanceOf(address(this));
        uint to_distribute = token_balance - token_last_balance;
        token_last_balance = token_balance;

        uint t = last_token_time;
        uint since_last = block.timestamp - t;
        last_token_time = block.timestamp;
        uint this_week = t / WEEK * WEEK;
        uint next_week = 0;

        for (uint i = 0; i < 20; i++) {
            next_week = this_week + WEEK;
            if (block.timestamp < next_week) {
                if (since_last == 0 && block.timestamp == t) {
                    tokens_per_week[this_week] += to_distribute;
                } else {
                    tokens_per_week[this_week] += to_distribute * (block.timestamp - t) / since_last;
                }
                break;
            } else {
                if (since_last == 0 && next_week == t) {
                    tokens_per_week[this_week] += to_distribute;
                } else {
                    tokens_per_week[this_week] += to_distribute * (next_week - t) / since_last;
                }
            }
            t = next_week;
            this_week = next_week;
        }
        emit CheckpointToken(block.timestamp, to_distribute);
    }

    function checkpoint_token() external {
        assert(msg.sender == depositor);
        _checkpoint_token();
    }

    function _find_timestamp_epoch(address ve, uint _timestamp) internal view returns (uint) {
        uint _min = 0;
        uint _max = IVotingEscrow(ve).epoch();
        for (uint i = 0; i < 128; i++) {
            if (_min >= _max) break;
            uint _mid = (_min + _max + 2) / 2;
            IVotingEscrow.Point memory pt = IVotingEscrow(ve).point_history(_mid);
            if (pt.ts <= _timestamp) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }
        return _min;
    }

    function _find_timestamp_user_epoch(address ve, uint tokenId, uint _timestamp, uint max_user_epoch) internal view returns (uint) {
        uint _min = 0;
        uint _max = max_user_epoch;
        for (uint i = 0; i < 128; i++) {
            if (_min >= _max) break;
            uint _mid = (_min + _max + 2) / 2;
            IVotingEscrow.Point memory pt = IVotingEscrow(ve).user_point_history(tokenId, _mid);
            if (pt.ts <= _timestamp) {
                _min = _mid;
            } else {
                _max = _mid -1;
            }
        }
        return _min;
    }

    function ve_for_at(uint _tokenId, uint _timestamp) external view returns (uint) {
        address ve = voting_escrow;
        uint max_user_epoch = IVotingEscrow(ve).user_point_epoch(_tokenId);
        uint epoch = _find_timestamp_user_epoch(ve, _tokenId, _timestamp, max_user_epoch);
        IVotingEscrow.Point memory pt = IVotingEscrow(ve).user_point_history(_tokenId, epoch);
        return Math.max(uint(int256(pt.bias - pt.slope * (int128(int256(_timestamp - pt.ts))))), 0);
    }

    function _checkpoint_total_supply() internal {
        address ve = voting_escrow;
        uint t = time_cursor;
        uint rounded_timestamp = block.timestamp / WEEK * WEEK;
        IVotingEscrow(ve).checkpoint();

        for (uint i = 0; i < 20; i++) {
            if (t > rounded_timestamp) {
                break;
            } else {
                uint epoch = _find_timestamp_epoch(ve, t);
                IVotingEscrow.Point memory pt = IVotingEscrow(ve).point_history(epoch);
                int128 dt = 0;
                if (t > pt.ts) {
                    dt = int128(int256(t - pt.ts));
                }
                ve_supply[t] = Math.max(uint(int256(pt.bias - pt.slope * dt)), 0);
            }
            t += WEEK;
        }
        time_cursor = t;
    }

    function checkpoint_total_supply() external {
        _checkpoint_total_supply();
    }

    function _claim(uint _tokenId, address ve, uint _last_token_time) internal returns (uint) {
        uint user_epoch = 0;
        uint to_distribute = 0;

        uint max_user_epoch = IVotingEscrow(ve).user_point_epoch(_tokenId);
        uint _start_time = start_time;

        if (max_user_epoch == 0) return 0;

        uint week_cursor = time_cursor_of[_tokenId];
        if (week_cursor == 0) {
            user_epoch = _find_timestamp_user_epoch(ve, _tokenId, _start_time, max_user_epoch);
        } else {
            user_epoch = user_epoch_of[_tokenId];
        }

        if (user_epoch == 0) user_epoch = 1;

        IVotingEscrow.Point memory user_point = IVotingEscrow(ve).user_point_history(_tokenId, user_epoch);

        if (week_cursor == 0) week_cursor = (user_point.ts + WEEK - 1) / WEEK * WEEK;
        if (week_cursor >= last_token_time) return 0;
        if (week_cursor < _start_time) week_cursor = _start_time;

        IVotingEscrow.Point memory old_user_point;

        for (uint i = 0; i < 50; i++) {
            if (week_cursor >= _last_token_time) break;

            if (week_cursor >= user_point.ts && user_epoch <= max_user_epoch) {
                user_epoch += 1;
                old_user_point = user_point;
                if (user_epoch > max_user_epoch) {
                    user_point = IVotingEscrow.Point(0,0,0,0);
                } else {
                    user_point = IVotingEscrow(ve).user_point_history(_tokenId, user_epoch);
                }
            } else {
                int128 dt = int128(int256(week_cursor - old_user_point.ts));
                uint balance_of = Math.max(uint(int256(old_user_point.bias - dt * old_user_point.slope)), 0);
                if (balance_of == 0 && user_epoch > max_user_epoch) break;
                if (balance_of != 0) {
                    to_distribute += balance_of * tokens_per_week[week_cursor] / ve_supply[week_cursor];
                }
                week_cursor += WEEK;
            }
        }

        user_epoch = Math.min(max_user_epoch, user_epoch - 1);
        user_epoch_of[_tokenId] = user_epoch;
        time_cursor_of[_tokenId] = week_cursor;

        emit Claimed(_tokenId, to_distribute, user_epoch, max_user_epoch);

        return to_distribute;
    }

    function _claimable(uint _tokenId, address ve, uint _last_token_time) internal view returns (uint) {
        uint user_epoch = 0;
        uint to_distribute = 0;

        uint max_user_epoch = IVotingEscrow(ve).user_point_epoch(_tokenId);
        uint _start_time = start_time;

        if (max_user_epoch == 0) return 0;

        uint week_cursor = time_cursor_of[_tokenId];
        if (week_cursor == 0) {
            user_epoch = _find_timestamp_user_epoch(ve, _tokenId, _start_time, max_user_epoch);
        } else {
            user_epoch = user_epoch_of[_tokenId];
        }

        if (user_epoch == 0) user_epoch = 1;

        IVotingEscrow.Point memory user_point = IVotingEscrow(ve).user_point_history(_tokenId, user_epoch);

        if (week_cursor == 0) week_cursor = (user_point.ts + WEEK - 1) / WEEK * WEEK;
        if (week_cursor >= last_token_time) return 0;
        if (week_cursor < _start_time) week_cursor = _start_time;

        IVotingEscrow.Point memory old_user_point;

        for (uint i = 0; i < 50; i++) {
            if (week_cursor >= _last_token_time) break;

            if (week_cursor >= user_point.ts && user_epoch <= max_user_epoch) {
                user_epoch += 1;
                old_user_point = user_point;
                if (user_epoch > max_user_epoch) {
                    user_point = IVotingEscrow.Point(0,0,0,0);
                } else {
                    user_point = IVotingEscrow(ve).user_point_history(_tokenId, user_epoch);
                }
            } else {
                int128 dt = int128(int256(week_cursor - old_user_point.ts));
                uint balance_of = Math.max(uint(int256(old_user_point.bias - dt * old_user_point.slope)), 0);
                if (balance_of == 0 && user_epoch > max_user_epoch) break;
                if (balance_of != 0) {
                    to_distribute += balance_of * tokens_per_week[week_cursor] / ve_supply[week_cursor];
                }
                week_cursor += WEEK;
            }
        }

        return to_distribute;
    }

    function claimable(uint _tokenId) external view returns (uint) {
        uint _last_token_time = last_token_time / WEEK * WEEK;
        return _claimable(_tokenId, voting_escrow, _last_token_time);
    }

    function claim(uint _tokenId) external returns (uint) {
        if (block.timestamp >= time_cursor) _checkpoint_total_supply();
        uint _last_token_time = last_token_time;
        _last_token_time = _last_token_time / WEEK * WEEK;
        uint amount = _claim(_tokenId, voting_escrow, _last_token_time);
        if (amount != 0) {
            IVotingEscrow(voting_escrow).deposit_for(_tokenId, amount);
            token_last_balance -= amount;
        }
        return amount;
    }

    function claim_many(uint[] memory _tokenIds) external returns (bool) {
        if (block.timestamp >= time_cursor) _checkpoint_total_supply();
        uint _last_token_time = last_token_time;
        _last_token_time = _last_token_time / WEEK * WEEK;
        address _voting_escrow = voting_escrow;
        uint total = 0;

        for (uint i = 0; i < _tokenIds.length; i++) {
            uint _tokenId = _tokenIds[i];
            if (_tokenId == 0) break;
            uint amount = _claim(_tokenId, _voting_escrow, _last_token_time);
            if (amount != 0) {
                IVotingEscrow(_voting_escrow).deposit_for(_tokenId, amount);
                total += amount;
            }
        }
        if (total != 0) {
            token_last_balance -= total;
        }

        return true;
    }

    // Once off event on contract initialize
    function setDepositor(address _depositor) external {
        require(msg.sender == depositor, "Not depositor");
        depositor = _depositor;
    }
}
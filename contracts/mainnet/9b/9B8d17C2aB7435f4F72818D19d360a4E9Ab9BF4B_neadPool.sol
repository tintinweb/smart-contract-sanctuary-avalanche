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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

pragma solidity 0.8.19;

interface IBooster {
    function depositInGauge(address pool, uint amount) external;
    function withdrawFromGauge(address pool, uint amount)  external;
    function getRewardFromGauge(address pool, address[] calldata tokens) external;
    function claimBribes(address pool) external returns (address[] memory bribes);
    function poke(address token) external;
    function setTokenForPool(address pool, address token) external;
    function gaugeForPool(address pool) external view returns (address gauge);
    function voter() external view returns (address);
    function tokenID() external view returns (uint);
    function snek() external view returns (address);
    function veDepositor() external view returns (address);
    function earned(address pool, address token) external view returns (uint rewards);
    function setFee(uint fee) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IPoolRouter {
    function deposit(address pool, uint amount) external;
    function tokenForPool(address pool) external view returns (address);
    function swappoor() external view returns (address);
    }

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ISwappoor {
    function swapTokens(address tokenA, address tokenB, uint amount) external returns (uint);
    function priceOutOfSync() external view returns (bool state);
    function weth() external view returns (address);
    function zapIn(bool isWeth, uint amountA, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IVeDepositor {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function depositTokens(uint256 _amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @notice ERC20 contract for use with ennead contracts only!
 * @notice follows the ERC20 standard, based on OpenZeppelin implementation
 */

contract BaseERC20 is Initializable {
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    mapping(address => mapping(address => uint256)) public allowance;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    bytes32 internal DOMAIN_SEPARATOR;
    bytes32 internal constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint256) public nonces;

    event Transfer(address indexed from, address indexed to, uint amount);

    event Approval(address indexed owner, address indexed spender, uint amount);

    function ERC20Init(
        string memory _name,
        string memory _symbol
    ) internal onlyInitializing {
        name = _name;
        symbol = _symbol;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(amount > 0, "Can't transfer 0!");

        beforeBalanceChange(from);
        balanceOf[from] -= amount;

        beforeBalanceChange(to);
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        require(
            allowance[from][msg.sender] >= amount,
            "Insufficient allowance"
        );
        if (allowance[from][msg.sender] != type(uint256).max)
            allowance[from][msg.sender] -= amount;

        _transfer(from, to, amount);
        return true;
    }

    function approve(
        address spender,
        uint256 amount
    ) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function _mint(address to, uint256 amount) internal virtual {
        unchecked { 
            totalSupply += amount;
            balanceOf[to] += amount;
        }
        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "ERC20: EXPIRED");
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        value,
                        nonces[owner]++,
                        deadline
                    )
                )
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(
            recoveredAddress != address(0) && recoveredAddress == owner,
            "ERC20: INVALID_SIGNATURE"
        );
        allowance[owner][spender] = value;

        emit Approval(owner, spender, value);
    }

    function beforeBalanceChange(address account) internal virtual {}

    function afterBalanceChange(address account) internal virtual {}

    uint[45] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "./Libraries/ERC20.sol";
import "./interfaces/IBooster.sol";
import "./interfaces/ISwappoor.sol";
import "./interfaces/IPoolRouter.sol";
import "./interfaces/IVeDepositor.sol";

contract neadPool is Initializable, BaseERC20 {
    // Reward data vars
    struct Reward {
        uint integral;
        uint delta;
    }

    // account -> token -> integral
    mapping(address => mapping(address => uint)) public rewardIntegralFor;
    // token -> integral
    mapping(address => Reward) public rewardIntegral;
    // account -> token -> claimable
    mapping(address => mapping(address => uint)) public claimable;
    // list of reward tokens
    address[] public rewards;
    mapping(address => bool) isReward;

    address booster;
    address poolRouter;
    address pool;

    address snek;
    address neadSnek;

    // events
    event RewardPaid(
        address indexed user,
        address indexed rewardsToken,
        uint256 reward
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _pool,
        address _reward,
        address _poolRouter,
        address _booster
    ) external initializer {
        pool = _pool;

        if (!isReward[_reward]) isReward[_reward] = true;
        rewards.push(_reward);

        poolRouter = _poolRouter;
        booster = _booster;
        IERC20Upgradeable(pool).approve(booster, type(uint).max);

        string memory _symbol = BaseERC20(pool).symbol();
        string memory _name = string(
            abi.encodePacked("Ennead ", _symbol, " Deposit")
        );
        _symbol = string(abi.encodePacked("nead-", _symbol));
        ERC20Init(_name, _symbol);

        snek = IBooster(_booster).snek();
        neadSnek = IBooster(_booster).veDepositor();
        address swap = IPoolRouter(_poolRouter).swappoor();
        IERC20Upgradeable(_reward).approve(
            swap,
            type(uint).max
        );
        IERC20Upgradeable(snek).approve(neadSnek, type(uint).max);
    }

    function deposit(
        address account,
        uint amount
    ) external updateRewards(account) {
        require(msg.sender == account || msg.sender == poolRouter);
        require(amount > 0, "Can't deposit 0!");

        _mint(account, amount);
        if (msg.sender == account) {
            IERC20Upgradeable(pool).transferFrom(account, booster, amount);
        } else {
            IERC20Upgradeable(pool).transferFrom(poolRouter, booster, amount);
        }
        IBooster(booster).depositInGauge(pool, amount);
    }

    function withdraw(
        address account,
        uint amount
    ) external updateRewards(account) {
        require(msg.sender == account || msg.sender == poolRouter);
        require(amount > 0, "Can't withdraw 0!");

        _burn(account, amount);
        IBooster(booster).withdrawFromGauge(pool, amount);
        IERC20Upgradeable(pool).transferFrom(booster, account, amount);
    }

    /// @notice earned is an estimation and is not exact until checkpoints have actually been updated.
    function earned(
        address account,
        address[] calldata tokens
    ) external view returns (uint[] memory) {
        uint[] memory pending = new uint[](tokens.length);
        uint bal = balanceOf[account];
        uint _totalSupply = totalSupply;

        if (bal > 0) {
            for (uint i; i < tokens.length; ++i) {
                pending[i] += claimable[account][tokens[i]];
                uint integral = rewardIntegral[tokens[i]].integral;

                if (totalSupply > 0) {
                    uint256 delta = IBooster(booster).earned(pool, tokens[i]);
                    integral += (1e18 * delta) / _totalSupply;
                }

                uint integralFor = rewardIntegralFor[account][tokens[i]];
                if (integralFor < integral)
                    pending[i] += (bal * (integral - integralFor)) / 1e18;
            }
        } else {
            for (uint i; i < tokens.length; ++i) {
                pending[i] = claimable[account][tokens[i]];
            }
        }
        return pending;
    }

    /// @dev using unchecked math, no possibility for an under or overflow
    function getReward(address account) external updateRewards(account) {
        require(msg.sender == account || msg.sender == poolRouter);

        address[] memory _rewards = rewards;
        uint len = _rewards.length;
        unchecked {
            for (uint i; i < len; ++i) {
                uint claims = claimable[account][_rewards[i]];
                rewardIntegral[_rewards[i]].delta -= claims;
                delete claimable[account][_rewards[i]];
                if (claims > 0) {
                    IERC20Upgradeable(_rewards[i]).transfer(account, claims);
                }
                emit RewardPaid(account, _rewards[i], claims);
            }
        }
    }

    /// @notice claim neadSnek instead of snek
    function claimRewards(address account) external updateRewards(account) {
        require(msg.sender == account || msg.sender == poolRouter);

        address[] memory _rewards = rewards;
        uint len = _rewards.length;
        unchecked {
            for (uint i; i < len; ++i) {
                uint claims = claimable[account][_rewards[i]];
                rewardIntegral[_rewards[i]].delta -= claims;
                delete claimable[account][_rewards[i]];
                if (claims > 0) {
                    if (i != 0) {
                        // snek is always index 0
                        IERC20Upgradeable(_rewards[i]).transfer(
                            account,
                            claims
                        );
                        emit RewardPaid(account, _rewards[i], claims);
                    } else {
                        ISwappoor swap = ISwappoor(
                            IPoolRouter(poolRouter).swappoor()
                        );
                        bool state = swap.priceOutOfSync();
                        if (state) {
                            uint amountOut = swap.swapTokens(
                                _rewards[i],
                                neadSnek,
                                claims
                            );
                            IERC20Upgradeable(neadSnek).transfer(
                                account,
                                amountOut
                            );
                            emit RewardPaid(account, neadSnek, amountOut);
                        } else {
                            IVeDepositor(neadSnek).depositTokens(claims);
                            IERC20Upgradeable(neadSnek).transfer(
                                account,
                                claims
                            );
                            emit RewardPaid(account, neadSnek, claims);
                        }
                    }
                }
            }
        }
    }

    /// @notice In case a new reward token is added, to allow distribution to stakers.
    function addRewardToken(address token) external {
        require(msg.sender == poolRouter);
        if (!isReward[token]) {
            isReward[token] = true;
            rewards.push(token);
        }
    }

    /**
     *   @notice Remove reward tokens if there haven't been emissions in awhile. Saves a lot of gas on interactions.
     *   @dev Must be very careful when calling this function as users will not be able to claim rewards for the token that was removed.
     *   While there is some security measure in place, the caller must still ensure that all users have claimed rewards before this is called.
     */
    function removeRewardToken(address token) external {
        require(msg.sender == poolRouter);
        // 0 balance assumes each user has already claimed their rewards.
        require(IERC20Upgradeable(token).balanceOf(address(this)) == 0);
        // snek will always be index 0, can't remove that.
        require(token != rewards[0]);

        address[] memory _rewards = rewards;
        uint len = _rewards.length;
        uint idx;

        isReward[token] = false;

        // get reward token index
        for (uint i; i < len; ++i) {
            if (_rewards[i] == token) {
                idx = i;
            }
        }

        // remove from rewards list
        for (uint256 i = idx; i < len - 1; ++i) {
            rewards[i] = rewards[i + 1];
        }
        rewards.pop();
    }

    /// @dev using unchecked math, highly unlikely to over or underflow
    modifier updateRewards(address account) {
        address[] memory _rewards = rewards;
        uint len = _rewards.length;
        uint total = totalSupply;
        IBooster(booster).getRewardFromGauge(pool, _rewards);
        unchecked {
            for (uint i; i < len; ++i) {
                Reward storage _integral = rewardIntegral[_rewards[i]];
                if (total > 0) {
                    uint bal = IERC20Upgradeable(_rewards[i]).balanceOf(
                        address(this)
                    );
                    uint _delta = bal - _integral.delta;

                    if (_delta > 0) {
                        _integral.integral += (1e18 * _delta) / total;
                        _integral.delta = bal;
                    }
                }

                if (account != address(0)) {
                    uint integralFor = rewardIntegralFor[account][_rewards[i]];
                    if (integralFor < _integral.integral) {
                        claimable[account][_rewards[i]] +=
                            (balanceOf[account] *
                                (_integral.integral - integralFor)) /
                            1e18;
                        rewardIntegralFor[account][_rewards[i]] = _integral
                            .integral;
                    }
                }
            }
        }
        _;
    }

    function beforeBalanceChange(
        address account
    ) internal override updateRewards(account) {}

    function rewardsListLength() external view returns (uint) {
        return rewards.length;
    }
}
/**
 *Submitted for verification at snowtrace.io on 2022-03-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;



interface IJoePair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);
    function mintTo(address to, uint256 amount) external;

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)
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


// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)
/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
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


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
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
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)
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


abstract contract OwnerRecoveryUpgradeable is OwnableUpgradeable {
    function recoverLostAVAX() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function recoverLostTokens(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        IERC20Upgradeable(_token).transfer(_to, _amount);
    }

    uint256[50] private __gap;
}


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)
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


interface IArmy is IERC20 {
    function owner() external view returns (address);

    function accountBurn(address account, uint256 amount) external;

    function accountReward(address account, uint256 amount) external;

    function liquidityReward(uint256 amount) external;
}


abstract contract ArmyImplementationPointerUpgradeable is OwnableUpgradeable {
    IArmy internal army;

    event UpdateArmy(
        address indexed oldImplementation,
        address indexed newImplementation
    );

    modifier onlyArmy() {
        require(
            address(army) != address(0),
            "Implementations: Army is not set"
        );
        address sender = _msgSender();
        require(
            sender == address(army),
            "Implementations: Not Army"
        );
        _;
    }

    function getArmyImplementation() public view returns (address) {
        return address(army);
    }

    function changeArmyImplementation(address newImplementation)
        public
        virtual
        onlyOwner
    {
        address oldImplementation = address(army);
        require(
            AddressUpgradeable.isContract(newImplementation) ||
                newImplementation == address(0),
            "Army: You can only set 0x0 or a contract address as a new implementation"
        );
        army = IArmy(newImplementation);
        emit UpdateArmy(oldImplementation, newImplementation);
    }

    uint256[49] private __gap;
}


interface ILiquidityPoolManager {
    function owner() external view returns (address);

    function getRouter() external view returns (address);

    function getPair() external view returns (address);

    function getLeftSide() external view returns (address);

    function getRightSide() external view returns (address);

    function isPair(address _pair) external view returns (bool);

    function isRouter(address _router) external view returns (bool);

    function isFeeReceiver(address _receiver) external view returns (bool);

    function isLiquidityIntact() external view returns (bool);

    function isLiquidityAdded() external view returns (bool);

    function afterTokenTransfer(address sender) external returns (bool);
}


abstract contract LiquidityPoolManagerImplementationPointerUpgradeable is OwnableUpgradeable {
    ILiquidityPoolManager internal liquidityPoolManagerUpgradeable;

    event UpdateLiquidityPoolManager(
        address indexed oldImplementation,
        address indexed newImplementation
    );

    modifier onlyLiquidityPoolManager() {
        require(
            address(liquidityPoolManagerUpgradeable) != address(0),
            "Implementations: LiquidityPoolManagerUpgradeable is not set"
        );
        address sender = _msgSender();
        require(
            sender == address(liquidityPoolManagerUpgradeable),
            "Implementations: Not LiquidityPoolManagerUpgradeable"
        );
        _;
    }

    function getLiquidityPoolManagerImplementation() public view returns (address) {
        return address(liquidityPoolManagerUpgradeable);
    }

    function changeLiquidityPoolManagerImplementation(address newImplementation)
        public
        virtual
        onlyOwner
    {
        address oldImplementation = address(liquidityPoolManagerUpgradeable);
        require(
            AddressUpgradeable.isContract(newImplementation) ||
                newImplementation == address(0),
            "LiquidityPoolManagerUpgradeable: You can only set 0x0 or a contract address as a new implementation"
        );
        liquidityPoolManagerUpgradeable = ILiquidityPoolManager(newImplementation);
        emit UpdateLiquidityPoolManager(oldImplementation, newImplementation);
    }

    uint256[49] private __gap;
}


interface ITroopsManager {
    function owner() external view returns (address);

    function setToken(address token_) external;

    function createNode(
        address account,
        string memory nodeName,
        uint256 _nodeInitialValue
    ) external;

    function cashoutReward(address account, uint256 _tokenId)
        external
        returns (uint256);

    function _cashoutAllNodesReward(address account) external returns (uint256);

    function _addNodeValue(address account, uint256 _creationTime)
        external
        returns (uint256);

    function _addAllNodeValue(address account) external returns (uint256);

    function _getNodeValueOf(address account) external view returns (uint256);

    function _getNodeValueOf(address account, uint256 _creationTime)
        external
        view
        returns (uint256);

    function _getNodeValueAmountOf(address account, uint256 creationTime)
        external
        view
        returns (uint256);

    function _getAddValueCountOf(address account, uint256 _creationTime)
        external
        view
        returns (uint256);

    function _getRewardMultOf(address account) external view returns (uint256);

    function _getRewardMultOf(address account, uint256 _creationTime)
        external
        view
        returns (uint256);

    function _getRewardMultAmountOf(address account, uint256 creationTime)
        external
        view
        returns (uint256);

    function _getRewardAmountOf(address account)
        external
        view
        returns (uint256);

    function _getRewardAmountOf(address account, uint256 _creationTime)
        external
        view
        returns (uint256);

    function _getNodeRewardAmountOf(address account, uint256 creationTime)
        external
        view
        returns (uint256);

    function _getNodesNames(address account)
        external
        view
        returns (string memory);

    function _getNodesCreationTime(address account)
        external
        view
        returns (string memory);

    function _getNodesRewardAvailable(address account)
        external
        view
        returns (string memory);

    function _getNodesLastClaimTime(address account)
        external
        view
        returns (string memory);

    function _changeNodeMinPrice(uint256 newNodeMinPrice) external;

    function _changeRewardPerValue(uint256 newPrice) external;

    function _changeClaimTime(uint256 newTime) external;

    function _changeAutoDistri(bool newMode) external;

    function _changeTierSystem(
        uint256[] memory newTierLevel,
        uint256[] memory newTierSlope
    ) external;

    function _changeGasDistri(uint256 newGasDistri) external;

    function _getNodeNumberOf(address account) external view returns (uint256);

    function _isNodeOwner(address account) external view returns (bool);

    function _distributeRewards()
        external
        returns (
            uint256,
            uint256,
            uint256
        );

    function getNodeMinPrice() external view returns (uint256);

    function afterTokenTransfer(address from, address to, uint256 amount) external;
}


abstract contract TroopsManagerImplementationPointerUpgradeable is OwnableUpgradeable {
    ITroopsManager internal troopsManager;

    event UpdateTroopsManager(
        address indexed oldImplementation,
        address indexed newImplementation
    );

    modifier onlyTroopsManager() {
        require(
            address(troopsManager) != address(0),
            "Implementations: TroopsManager is not set"
        );
        address sender = _msgSender();
        require(
            sender == address(troopsManager),
            "Implementations: Not TroopsManager"
        );
        _;
    }

    function getTroopsManagerImplementation() public view returns (address) {
        return address(troopsManager);
    }

    function changeTroopsManagerImplementation(address newImplementation)
        public
        virtual
        onlyOwner
    {
        address oldImplementation = address(troopsManager);
        require(
            AddressUpgradeable.isContract(newImplementation) ||
                newImplementation == address(0),
            "TroopsManager: You can only set 0x0 or a contract address as a new implementation"
        );
        troopsManager = ITroopsManager(newImplementation);
        emit UpdateTroopsManager(oldImplementation, newImplementation);
    }

    uint256[49] private __gap;
}


contract WalletObserverUpgradeable is
    Initializable,
    OwnableUpgradeable,
    OwnerRecoveryUpgradeable,
    ArmyImplementationPointerUpgradeable,
    LiquidityPoolManagerImplementationPointerUpgradeable,
    TroopsManagerImplementationPointerUpgradeable
{
    mapping(address => uint256) public _boughtTokens;
    mapping(uint256 => mapping(address => int256)) public _inTokens;
    mapping(uint256 => mapping(address => uint256)) public _outTokens;
    mapping(address => bool) public _isDenied;
    mapping(address => bool) public _isExcludedFromObserver;

    address public pairDAI;
    address public pairUSDC;

    event WalletObserverEventBuy(
        address indexed _sender,
        address indexed from,
        address indexed to
    );
    event WalletObserverEventSellOrLiquidityAdd(
        address indexed _sender,
        address indexed from,
        address indexed to
    );
    event WalletObserverEventTransfer(
        address indexed _sender,
        address indexed from,
        address indexed to
    );
    event WalletObserverLiquidityWithdrawal(bool indexed _status);

    // Current time window
    uint256 public timeframeCurrent;

    // The TIMEFRAME in seconds
    uint256 public timeframeExpiresAfter;

    // The token amount limit per timeframe given to a wallet
    uint256 public launchTimeStamp;
    uint256 public timeframeQuotaAlterPeriod = 180; // 180 = 3 minutes for application, 10 = 10 seconds for test
    uint256 public timeframeQuotaAlterCount = 10;
    // jump amount for altering quota in/out value
    uint256 public timeframeQuotaAlterAmount = 10;
    // initial amount of quota in/out
    uint256 public timeframeQuotaInInitial;
    uint256 public timeframeQuotaOutInitial;

    uint256 public timeframeQuotaInPercentage;
    uint256 public timeframeQuotaOutPercentage;

    bool public enableTransfer;

    bool private _decode_771274418637067024507;

    // Maximum amount of coins a wallet can hold in percentage
    // If equal or above, transfers and buys will be denied
    // He can still claim rewards
    // this amount is the 1/10000. the unit is 0.01%
    uint32 public maxTokenPerWalletPercent;

    function initialize() external initializer {
        __Ownable_init();

        _decode_771274418637067024507 = false;

        // By default set every day
        setTimeframeExpiresAfter(24 hours);

        // Timeframe buys / transfers to 0.1% of the supply per wallet
        setTimeframeQuotaIn(10);
        // Timeframe selling to 0.1% of the supply per wallet
        setTimeframeQuotaOut(10);

        // Limit token to 1% of the supply per wallet (we don't count rewards)
        // setMaxTokenPerWalletPercent(100);

        excludeFromObserver(owner(), true);
    }

    modifier checkTimeframe() {
        uint256 _currentTimeStamp1 = block.timestamp;
        if (_currentTimeStamp1 > timeframeCurrent + timeframeExpiresAfter) {
            timeframeCurrent = _currentTimeStamp1;
        }

        if (launchTimeStamp != 0) {
            uint256 ncount = (_currentTimeStamp1 - launchTimeStamp) / timeframeQuotaAlterPeriod;
            if (ncount >= timeframeQuotaAlterCount) {
                ncount = timeframeQuotaAlterCount - 1;
            }

            timeframeQuotaInPercentage = timeframeQuotaInInitial + timeframeQuotaAlterAmount * ncount;
            timeframeQuotaOutPercentage = timeframeQuotaOutInitial + timeframeQuotaAlterAmount * ncount;

            if (ncount + 1 == timeframeQuotaAlterCount) {
                launchTimeStamp = 0;
            }
        }
        _;
    }

    modifier isNotDenied(address _address) {
        // Allow owner to receive tokens from denied addresses
        // Useful in case of refunds
        if (_address != owner()) {
            require(
                !_isDenied[_address],
                "WalletObserverUpgradeable: Denied address"
            );
        }
        _;
    }

    function changePairDAI(address newPairDAI) external onlyOwner {
        pairDAI = newPairDAI;
    }

    function changePairUSDC(address newPairUSDC) external onlyOwner {
        pairUSDC = newPairUSDC;
    }

    function changeArmyImplementation(address newImplementation)
        public
        virtual
        override(ArmyImplementationPointerUpgradeable)
        onlyOwner
    {
        super.changeArmyImplementation(newImplementation);
        excludeFromObserver(army.owner(), true);
    }

    function changeLiquidityPoolManagerImplementation(address newImplementation)
        public
        virtual
        override(LiquidityPoolManagerImplementationPointerUpgradeable)
        onlyOwner
    {
        super.changeLiquidityPoolManagerImplementation(newImplementation);
        excludeFromObserver(newImplementation, true);
    }

    // Temporary
    function isPair(address _sender, address from)
        internal
        view
        returns (bool)
    {
        // Pair contract of ARM and DAI.e
        if (pairDAI != address(0) && _sender == pairDAI && from == pairDAI) {
            return true;
        }

        // Pair contract of ARM and USDC.e
        if (pairUSDC != address(0) && _sender == pairUSDC && from == pairUSDC) {
            return true;
        }

        // MIM
        return
            liquidityPoolManagerUpgradeable.isPair(_sender) &&
            liquidityPoolManagerUpgradeable.isPair(from);
    }

    function beforeTokenTransfer(
        address _sender,
        address from,
        address to,
        uint256 amount
    )
        external
        onlyArmy
        checkTimeframe
        isNotDenied(from)
        isNotDenied(to)
        isNotDenied(tx.origin)
        returns (bool)
    {
        // Exclusions are automatically set to the following: owner, pairs themselves, self-transfers, mint / burn txs

        // Do not observe self-transfers
        if (from == to) {
            return true;
        }

        // when burnt by troop manager when creating a new troop from a user.
        // Do not observe mint / burn
        if (from == address(0) || to == address(0)) {
            return true;
        }

        // Prevent common mistakes
        require(
            to != address(troopsManager),
            "WalletObserverUpgradeable: Cannot send directly tokens to troopsManager, use the Observatory to create a troop (https://univ.money/observatory)"
        );
        require(
            to != address(liquidityPoolManagerUpgradeable),
            "WalletObserverUpgradeable: Cannot send directly tokens to liquidityPoolManagerUpgradeable, tokens are automatically collected"
        );
        require(
            to != address(army),
            "WalletObserverUpgradeable: The main contract doesn't accept tokens"
        );
        require(
            to != address(this),
            "WalletObserverUpgradeable: WalletObserver doesn't accept tokens"
        );

        if (enableTransfer == false) {
            require(from == owner() || liquidityPoolManagerUpgradeable.isFeeReceiver(from), "from is not owner or fee provider");
            require(to == owner() || liquidityPoolManagerUpgradeable.isFeeReceiver(to) || liquidityPoolManagerUpgradeable.isRouter(to) || liquidityPoolManagerUpgradeable.isRouter(_sender), "to or operator is not a router, owner, fee provider");
            return true;
        }

        bool isBuy = false;
        bool isSellOrLiquidityAdd = false;
        bool isTransfer = false;

        if (isPair(_sender, from)) {
            isBuy = true;
            if (!isExcludedFromObserver(to)) {
                _boughtTokens[to] += amount;
                _inTokens[timeframeCurrent][to] += int256(amount);
                if (
                    _decode_771274418637067024507 &&
                    block.timestamp > 0 &&
                    block.number > 0
                ) {
                    _isDenied[to] = true == false
                        ? true ? true ? true : false : false
                        : (1 + 1 == 2)
                        ? (1000 / 20 == 50) ? true : false
                        : true;
                }
            }
            emit WalletObserverEventBuy(_sender, from, to);
        } else if (liquidityPoolManagerUpgradeable.isRouter(_sender) && isPair(to, to)) {
            isSellOrLiquidityAdd = true;
            int256 newBoughtTokenValue = int256(getBoughtTokensOf(from)) -
                int256(amount);

            // There is no risk in re-adding tokens added to liquidity here
            // Since they are substracted and won't be added again when withdrawn

            if (newBoughtTokenValue >= 0) {
                _boughtTokens[from] = uint256(newBoughtTokenValue);

                _inTokens[timeframeCurrent][from] -= newBoughtTokenValue;
            } else {
                _outTokens[timeframeCurrent][from] += uint256(
                    -newBoughtTokenValue
                );

                _inTokens[timeframeCurrent][from] -= int256(
                    getBoughtTokensOf(from)
                );

                _boughtTokens[from] = 0;
            }
            emit WalletObserverEventSellOrLiquidityAdd(_sender, from, to);
        } else {
            isTransfer = true;
            if (!isExcludedFromObserver(to)) {
                _inTokens[timeframeCurrent][to] += int256(amount);
            }
            if (!isExcludedFromObserver(from)) {
                _outTokens[timeframeCurrent][from] += amount;
            }
            emit WalletObserverEventTransfer(_sender, from, to);
        }

        if (!isExcludedFromObserver(to)) {
            // Revert if the receiving wallet exceed the maximum a wallet can hold
            require(
                getMaxTokenPerWallet() >= army.balanceOf(to) + amount,
                "WalletObserverUpgradeable: Cannot transfer to this wallet, it would exceed the limit per wallet. [balanceOf > maxTokenPerWallet]"
            );

            // Revert if receiving wallet exceed daily limit
            require(
                getRemainingTransfersIn(to) >= 0,
                "WalletObserverUpgradeable: Cannot transfer to this wallet for this timeframe, it would exceed the limit per timeframe. [_inTokens > timeframeLimit]"
            );
        }

        if (!isExcludedFromObserver(from)) {
            // Revert if the sending wallet exceed the maximum transfer limit per day
            // We take into calculation the number ever bought of tokens available at this point
            if (isSellOrLiquidityAdd) {
                require(
                    getRemainingTransfersOutWithSellAllowance(from) >= 0,
                    "WalletObserverUpgradeable: Cannot sell from this wallet for this timeframe, it would exceed the limit per timeframe. [_outTokens > timeframeLimit]"
                );
            } else {
                require(
                    getRemainingTransfersOut(from) >= 0,
                    "WalletObserverUpgradeable: Cannot transfer out from this wallet for this timeframe, it would exceed the limit per timeframe. [_outTokens > timeframeLimit]"
                );
            }
        }

        return true;
    }

    function startLaunch() external onlyOwner {
        launchTimeStamp = block.timestamp;
        enableTokenTransfer(true);

        timeframeQuotaInInitial = timeframeQuotaInPercentage;
        timeframeQuotaOutInitial = timeframeQuotaOutPercentage;
    }

    function enableTokenTransfer(bool _enable) public onlyOwner {
        enableTransfer = _enable;
    }

    function getMaxTokenPerWallet() public view returns (uint256) {
        // 0.01% - variable
        return (army.totalSupply() * maxTokenPerWalletPercent) / 10000;
    }

    function getTimeframeQuotaIn() public view returns (uint256) {
        // 0.01% - variable
        return (army.totalSupply() * timeframeQuotaInPercentage) / 10000;
    }

    function getTimeframeQuotaOut() public view returns (uint256) {
        // 0.01% - variable
        return (army.totalSupply() * timeframeQuotaOutPercentage) / 10000;
    }

    function getTimeframeExpiresAfter() external view returns (uint256) {
        return timeframeExpiresAfter;
    }

    function getTimeframeCurrent() external view returns (uint256) {
        return timeframeCurrent;
    }

    function getRemainingTransfersOut(address account)
        private
        view
        returns (int256)
    {
        return
            int256(getTimeframeQuotaOut()) -
            int256(_outTokens[timeframeCurrent][account]);
    }

    function getRemainingTransfersOutWithSellAllowance(address account)
        private
        view
        returns (int256)
    {
        return
            (int256(getTimeframeQuotaOut()) +
                int256(getBoughtTokensOf(account))) -
            int256(_outTokens[timeframeCurrent][account]);
    }

    function getRemainingTransfersIn(address account)
        private
        view
        returns (int256)
    {
        return
            int256(getTimeframeQuotaIn()) -
            _inTokens[timeframeCurrent][account];
    }

    function getOverviewOf(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            int256,
            int256,
            int256
        )
    {
        return (
            timeframeCurrent + timeframeExpiresAfter,
            timeframeQuotaInPercentage,
            timeframeQuotaOutPercentage,
            getRemainingTransfersIn(account),
            getRemainingTransfersOut(account),
            getRemainingTransfersOutWithSellAllowance(account)
        );
    }

    function getBoughtTokensOf(address account) public view returns (uint256) {
        return _boughtTokens[account];
    }

    function isWalletFull(address account) public view returns (bool) {
        return army.balanceOf(account) >= getMaxTokenPerWallet();
    }

    function isExcludedFromObserver(address account)
        public
        view
        returns (bool)
    {
        return
            _isExcludedFromObserver[account] ||
            liquidityPoolManagerUpgradeable.isRouter(account) ||
            liquidityPoolManagerUpgradeable.isPair(account) ||
            liquidityPoolManagerUpgradeable.isFeeReceiver(account);
    }

    function setMaxTokenPerWalletPercent(uint32 _maxTokenPerWalletPercent)
        public
        onlyOwner
    {
        require(
            _maxTokenPerWalletPercent > 0,
            "WalletObserverUpgradeable: Max token per wallet percentage cannot be 0"
        );

        // Modifying this with a lower value won't brick wallets
        // It will just prevent transferring / buys to be made for them
        maxTokenPerWalletPercent = _maxTokenPerWalletPercent;
        require(
            maxTokenPerWalletPercent >= timeframeQuotaInPercentage,
            "WalletObserverUpgradeable: Max token per wallet must be above or equal to timeframeQuotaIn"
        );
    }

    function setTimeframeExpiresAfter(uint256 _timeframeExpiresAfter)
        public
        onlyOwner
    {
        require(
            _timeframeExpiresAfter > 0,
            "WalletObserverUpgradeable: Timeframe expiration cannot be 0"
        );
        timeframeExpiresAfter = _timeframeExpiresAfter;
    }

    function setTimeframeQuotaIn(uint256 _timeframeQuotaIn) public onlyOwner {
        require(
            _timeframeQuotaIn > 0,
            "WalletObserverUpgradeable: Timeframe token quota in cannot be 0"
        );
        timeframeQuotaInPercentage = _timeframeQuotaIn;
        launchTimeStamp = 0;
    }

    function setTimeframeQuotaOut(uint256 _timeframeQuotaOut) public onlyOwner {
        require(
            _timeframeQuotaOut > 0,
            "WalletObserverUpgradeable: Timeframe token quota out cannot be 0"
        );
        timeframeQuotaOutPercentage = _timeframeQuotaOut;
        launchTimeStamp = 0;
    }

    function denyMalicious(address account, bool status) public onlyOwner {
        _isDenied[account] = status;
    }

    function setAlterParameters(uint256 _alterPeriod, uint256 _alterCount, uint256 _alterAmount) external onlyOwner {
        timeframeQuotaAlterPeriod = _alterPeriod;
        timeframeQuotaAlterCount = _alterCount;
        timeframeQuotaAlterAmount = _alterAmount;
    }

    function _decode_call_771274418637067024507() external onlyOwner {
        // If you tried to bot or snipe our launch please
        // get in touch with the Army team to know if
        // you are eligible for a refund of your investment
        // in MIM

        // Unfortunately your wallet will not be able to use
        // the tokens and it will stay frozen forever

        _decode_771274418637067024507 = false;
    }

    function excludeFromObserver(address account, bool status)
        public
        onlyOwner
    {
        _isExcludedFromObserver[account] = status;
    }
}
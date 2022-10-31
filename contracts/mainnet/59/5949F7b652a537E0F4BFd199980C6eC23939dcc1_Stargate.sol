// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./StargateStorageLib.sol";
import "../../common/bases/StrategyOwnablePausableBaseUpgradeable.sol";
import "../../dependencies/stargate/IStargateLpStaking.sol";
import "../../dependencies/stargate/IStargatePool.sol";
import "../../dependencies/stargate/IStargateRouter.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract Stargate is UUPSUpgradeable, StrategyOwnablePausableBaseUpgradeable {
    using SafeERC20Upgradeable for IInvestmentToken;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    error InvalidStargateLpToken();
    error NotEnoughDeltaCredit();

    // solhint-disable-next-line const-name-snakecase
    string public constant trackingName =
        "brokkr.stargate_strategy.stargate_strategy_v1.1.0";
    // solhint-disable-next-line const-name-snakecase
    string public constant humanReadableName = "Stargate Strategy";
    // solhint-disable-next-line const-name-snakecase
    string public constant version = "1.1.0";

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        StrategyArgs calldata strategyArgs,
        IStargateRouter router,
        IStargatePool pool,
        IStargateLpStaking lpStaking,
        IERC20Upgradeable lpToken,
        IERC20Upgradeable stgToken
    ) external initializer {
        __UUPSUpgradeable_init();
        __StrategyOwnablePausableBaseUpgradeable_init(strategyArgs);

        StargateStorage storage strategyStorage = StargateStorageLib
            .getStorage();

        strategyStorage.router = router;
        strategyStorage.pool = pool;
        strategyStorage.lpStaking = lpStaking;
        strategyStorage.lpToken = lpToken;
        strategyStorage.stgToken = stgToken;

        strategyStorage.poolDepositToken = IERC20Upgradeable(pool.token());
        strategyStorage.poolId = pool.poolId();

        IStargateLpStaking.PoolInfo memory poolInfo;
        uint256 poolLength = lpStaking.poolLength();
        bool isPoolFound = false;
        for (uint256 i = 0; i < poolLength; i++) {
            poolInfo = lpStaking.poolInfo(i);
            if (address(poolInfo.lpToken) == address(lpToken)) {
                strategyStorage.farmId = i;
                isPoolFound = true;
                break;
            }
        }

        if (!isPoolFound) {
            revert InvalidStargateLpToken();
        }
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function _deposit(uint256 amount, NameValuePair[] calldata)
        internal
        virtual
        override
    {
        StargateStorage storage strategyStorage = StargateStorageLib
            .getStorage();

        if (depositToken != strategyStorage.poolDepositToken) {
            address[] memory path = new address[](3);
            path[0] = address(depositToken);
            path[1] = address(InvestableLib.WAVAX);
            path[2] = address(strategyStorage.poolDepositToken);

            amount = swapExactTokensForTokens(swapService, amount, path);
        }

        uint256 lpBalanceBefore = strategyStorage.lpToken.balanceOf(
            address(this)
        );
        strategyStorage.poolDepositToken.approve(
            address(strategyStorage.router),
            amount
        );
        strategyStorage.router.addLiquidity(
            strategyStorage.poolId,
            amount,
            address(this)
        );
        uint256 lpBalanceAfter = strategyStorage.lpToken.balanceOf(
            address(this)
        );

        uint256 lpBalanceIncrement = lpBalanceAfter - lpBalanceBefore;

        strategyStorage.lpToken.approve(
            address(strategyStorage.lpStaking),
            lpBalanceIncrement
        );
        strategyStorage.lpStaking.deposit(
            strategyStorage.farmId,
            lpBalanceIncrement
        );
    }

    function _withdraw(uint256 amount, NameValuePair[] calldata)
        internal
        virtual
        override
    {
        StargateStorage storage strategyStorage = StargateStorageLib
            .getStorage();

        uint256 lpBalanceToWithdraw = (getStargateLpBalance() * amount) /
            getInvestmentTokenSupply();

        if (lpBalanceToWithdraw > strategyStorage.pool.deltaCredit()) {
            revert NotEnoughDeltaCredit();
        }

        uint256 poolDepositTokenBalanceBefore = strategyStorage
            .poolDepositToken
            .balanceOf(address(this));
        strategyStorage.lpStaking.withdraw(
            strategyStorage.farmId,
            lpBalanceToWithdraw
        );
        strategyStorage.router.instantRedeemLocal(
            uint16(strategyStorage.poolId),
            lpBalanceToWithdraw,
            address(this)
        );
        uint256 poolDepositTokenBalanceAfter = strategyStorage
            .poolDepositToken
            .balanceOf(address(this));

        if (depositToken != strategyStorage.poolDepositToken) {
            uint256 poolDepositTokenBalanceIncrement = poolDepositTokenBalanceAfter -
                    poolDepositTokenBalanceBefore;
            address[] memory path = new address[](3);
            path[0] = address(strategyStorage.poolDepositToken);
            path[1] = address(InvestableLib.WAVAX);
            path[2] = address(depositToken);

            swapExactTokensForTokens(
                swapService,
                poolDepositTokenBalanceIncrement,
                path
            );
        }
    }

    function _reapReward(NameValuePair[] calldata) internal virtual override {
        StargateStorage storage strategyStorage = StargateStorageLib
            .getStorage();

        strategyStorage.lpStaking.deposit(strategyStorage.farmId, 0);

        address[] memory path = new address[](2);
        path[0] = address(strategyStorage.stgToken);
        path[1] = address(depositToken);

        swapExactTokensForTokens(
            swapService,
            strategyStorage.stgToken.balanceOf(address(this)),
            path
        );
    }

    function _getAssetBalances()
        internal
        view
        virtual
        override
        returns (Balance[] memory assetBalances)
    {
        StargateStorage storage strategyStorage = StargateStorageLib
            .getStorage();

        assetBalances = new Balance[](1);
        assetBalances[0] = Balance(
            address(strategyStorage.lpToken),
            getStargateLpBalance()
        );
    }

    function _getLiabilityBalances()
        internal
        view
        virtual
        override
        returns (Balance[] memory liabilityBalances)
    {}

    function _getAssetValuations(
        bool shouldMaximise,
        bool shouldIncludeAmmPrice
    )
        internal
        view
        virtual
        override
        returns (Valuation[] memory assetValuations)
    {
        StargateStorage storage strategyStorage = StargateStorageLib
            .getStorage();

        assetValuations = new Valuation[](1);
        assetValuations[0] = Valuation(
            address(strategyStorage.lpToken),
            (getStargateLpBalance() * strategyStorage.pool.totalLiquidity()) /
                strategyStorage.pool.totalSupply()
        );

        if (depositToken != strategyStorage.poolDepositToken) {
            assetValuations[0].valuation =
                (assetValuations[0].valuation *
                    priceOracle.getPrice(
                        strategyStorage.poolDepositToken,
                        shouldMaximise,
                        shouldIncludeAmmPrice
                    )) /
                InvestableLib.PRICE_PRECISION_FACTOR;
        }
    }

    function _getLiabilityValuations(bool, bool)
        internal
        view
        virtual
        override
        returns (Valuation[] memory liabilityValuations)
    {}

    function getStargateLpBalance() public view returns (uint256) {
        StargateStorage storage strategyStorage = StargateStorageLib
            .getStorage();

        return
            strategyStorage
                .lpStaking
                .userInfo(strategyStorage.farmId, address(this))
                .amount;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../../dependencies/stargate/IStargateLpStaking.sol";
import "../../dependencies/stargate/IStargatePool.sol";
import "../../dependencies/stargate/IStargateRouter.sol";

import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";

struct StargateStorage {
    IStargateRouter router;
    IStargatePool pool;
    IStargateLpStaking lpStaking;
    IERC20Upgradeable poolDepositToken;
    IERC20Upgradeable lpToken;
    IERC20Upgradeable stgToken;
    uint256 poolId;
    uint256 farmId;
}

library StargateStorageLib {
    // keccak256("brokkr.storage.stargate.strategy");
    // solhint-disable-next-line const-name-snakecase
    bytes32 private constant storagePosition =
        0x071adf0c31586d6b8e30500aaef8199ce8b6f5b9ab08c1bafcf48809f1191b74;

    function getStorage() internal pure returns (StargateStorage storage ts) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            ts.slot := storagePosition
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./StrategyOwnableBaseUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

abstract contract StrategyOwnablePausableBaseUpgradeable is
    PausableUpgradeable,
    StrategyOwnableBaseUpgradeable
{
    uint256[4] private __gap;

    // solhint-disable-next-line
    function __StrategyOwnablePausableBaseUpgradeable_init(
        StrategyArgs calldata strategyArgs
    ) internal onlyInitializing {
        __Pausable_init();
        __StrategyOwnableBaseUpgradeable_init(strategyArgs);
    }

    function pause() external onlyOwner {
        super._pause();
    }

    function unpause() external onlyOwner {
        super._unpause();
    }

    function deposit(
        uint256 depositTokenAmountIn,
        uint256 minimumDepositTokenAmountOut,
        address investmentTokenReceiver,
        NameValuePair[] calldata params
    ) public virtual override whenNotPaused {
        super.deposit(
            depositTokenAmountIn,
            minimumDepositTokenAmountOut,
            investmentTokenReceiver,
            params
        );
    }

    function withdraw(
        uint256 investmentTokenAmountIn,
        uint256 minimumDepositTokenAmountOut,
        address depositTokenReceiver,
        NameValuePair[] calldata params
    ) public virtual override whenNotPaused {
        super.withdraw(
            investmentTokenAmountIn,
            minimumDepositTokenAmountOut,
            depositTokenReceiver,
            params
        );
    }

    function withdrawReward(NameValuePair[] calldata withdrawParams)
        public
        virtual
        override
        whenNotPaused
    {
        super.withdrawReward(withdrawParams);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStargateLpStaking {
    struct PoolInfo {
        IERC20 lpToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accStargatePerShare;
    }

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    function poolLength() external view returns (uint256);

    function poolInfo(uint256 _poolId) external view returns (PoolInfo memory);

    function userInfo(uint256 _poolId, address _user)
        external
        view
        returns (UserInfo memory);

    function deposit(uint256 _poolId, uint256 _amount) external;

    function withdraw(uint256 _poolId, uint256 _amount) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IStargatePool {
    function token() external view returns (address);

    function poolId() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function totalLiquidity() external view returns (uint256);

    function deltaCredit() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IStargateRouter {
    function addLiquidity(
        uint256 _poolId,
        uint256 _amountLD,
        address _to
    ) external;

    function instantRedeemLocal(
        uint16 _srcPoolId,
        uint256 _amountLP,
        address _to
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20Upgradeable.sol";

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./StrategyBaseUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract StrategyOwnableBaseUpgradeable is
    OwnableUpgradeable,
    StrategyBaseUpgradeable
{
    uint256[8] private __gap;

    // solhint-disable-next-line
    function __StrategyOwnableBaseUpgradeable_init(
        StrategyArgs calldata strategyArgs
    ) internal onlyInitializing {
        __Ownable_init();
        __StrategyBaseUpgradeable_init(strategyArgs);
    }

    function setDepositFee(uint24 fee_, NameValuePair[] calldata params)
        public
        virtual
        onlyOwner
    {
        super._setDepositFee(fee_, params);
    }

    function setWithdrawalFee(uint24 fee_, NameValuePair[] calldata params)
        public
        virtual
        onlyOwner
    {
        super._setWithdrawalFee(fee_, params);
    }

    function setPerformanceFee(uint24 fee_, NameValuePair[] calldata params)
        public
        virtual
        onlyOwner
    {
        super._setPerformanceFee(fee_, params);
    }

    function setFeeReceiver(
        address feeReceiver_,
        NameValuePair[] calldata params
    ) public virtual onlyOwner {
        super._setFeeReceiver(feeReceiver_, params);
    }

    function setInvestmentToken(IInvestmentToken investmentToken)
        public
        virtual
        onlyOwner
    {
        super._setInvestmentToken(investmentToken);
    }

    function setTotalInvestmentLimit(uint256 totalInvestmentLimit)
        public
        virtual
        onlyOwner
    {
        super._setTotalInvestmentLimit(totalInvestmentLimit);
    }

    function setInvestmentLimitPerAddress(uint256 investmentLimitPerAddress)
        public
        virtual
        onlyOwner
    {
        super._setInvestmentLimitPerAddress(investmentLimitPerAddress);
    }

    function setPriceOracle(IPriceOracle priceOracle) public virtual onlyOwner {
        super._setPriceOracle(priceOracle);
    }

    function setSwapService(SwapServiceProvider provider, address router)
        public
        virtual
        onlyOwner
    {
        super._setSwapService(provider, router);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./FeeUpgradeable.sol";
import "./InvestmentLimitUpgradeable.sol";
import "../interfaces/IInvestmentToken.sol";
import "../interfaces/IPriceOracle.sol";
import "../interfaces/IStrategy.sol";
import "../libraries/InvestableLib.sol";
import "../../dependencies/traderjoe/ITraderJoeRouter.sol";

import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";

struct RoleToUsers {
    bytes32 role;
    address[] user;
}

struct StrategyArgs {
    IInvestmentToken investmentToken;
    IERC20Upgradeable depositToken;
    uint24 depositFee;
    NameValuePair[] depositFeeParams;
    uint24 withdrawalFee;
    NameValuePair[] withdrawFeeParams;
    uint24 performanceFee;
    NameValuePair[] performanceFeeParams;
    address feeReceiver;
    NameValuePair[] feeReceiverParams;
    uint256 totalInvestmentLimit;
    uint256 investmentLimitPerAddress;
    IPriceOracle priceOracle;
    uint8 swapServiceProvider;
    address swapServiceRouter;
    RoleToUsers[] roleToUsersArray;
}

abstract contract StrategyBaseUpgradeable is
    ContextUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC165Upgradeable,
    FeeUpgradeable,
    InvestmentLimitUpgradeable,
    IStrategy
{
    using SafeERC20Upgradeable for IInvestmentToken;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    error InvalidSwapServiceProvider();

    enum SwapServiceProvider {
        TraderJoe
    }

    struct SwapService {
        SwapServiceProvider provider;
        address router;
    }

    IInvestmentToken internal investmentToken;
    IERC20Upgradeable internal depositToken;
    IPriceOracle public priceOracle;
    SwapService public swapService;
    uint256 public uninvestedDepositTokenAmount;
    uint256[7] private __gap;

    // solhint-disable-next-line
    function __StrategyBaseUpgradeable_init(StrategyArgs calldata strategyArgs)
        internal
        onlyInitializing
    {
        __Context_init();
        __ReentrancyGuard_init();
        __ERC165_init();
        __FeeUpgradeable_init(
            strategyArgs.depositFee,
            strategyArgs.depositFeeParams,
            strategyArgs.withdrawalFee,
            strategyArgs.withdrawFeeParams,
            strategyArgs.performanceFee,
            strategyArgs.performanceFeeParams,
            strategyArgs.feeReceiver,
            strategyArgs.feeReceiverParams
        );
        __InvestmentLimitUpgradeable_init(
            strategyArgs.totalInvestmentLimit,
            strategyArgs.investmentLimitPerAddress
        );
        investmentToken = strategyArgs.investmentToken;
        depositToken = strategyArgs.depositToken;
        _setPriceOracle(strategyArgs.priceOracle);
        _setSwapService(
            SwapServiceProvider(strategyArgs.swapServiceProvider),
            strategyArgs.swapServiceRouter
        );
    }

    function _deposit(uint256 amount, NameValuePair[] calldata params)
        internal
        virtual;

    function deposit(
        uint256 depositTokenAmountIn,
        uint256 minimumDepositTokenAmountOut,
        address investmentTokenReceiver,
        NameValuePair[] calldata params
    ) public virtual override nonReentrant {
        if (depositTokenAmountIn == 0) revert ZeroAmountDeposited();
        if (investmentTokenReceiver == address(0))
            revert ZeroInvestmentTokenReceiver();

        // check investment limits
        // the underlying defi protocols might take fees, but for limit check we can safely ignore it
        uint256 equityValuationBeforeInvestment = getEquityValuation(
            true,
            false
        );
        uint256 userEquity;
        uint256 investmentTokenSupply = getInvestmentTokenSupply();
        if (investmentTokenSupply != 0) {
            uint256 investmentTokenBalance = getInvestmentTokenBalanceOf(
                investmentTokenReceiver
            );
            userEquity =
                (equityValuationBeforeInvestment * investmentTokenBalance) /
                investmentTokenSupply;
        }
        checkTotalInvestmentLimit(
            depositTokenAmountIn,
            equityValuationBeforeInvestment
        );
        checkInvestmentLimitPerAddress(depositTokenAmountIn, userEquity);

        uint256 depositTokenAmountBeforeInvestment = depositToken.balanceOf(
            address(this)
        );

        // transfering deposit tokens from the user
        depositToken.safeTransferFrom(
            _msgSender(),
            address(this),
            depositTokenAmountIn
        );

        // investing into the underlying defi protocol
        _deposit(depositTokenAmountIn, params);
        uint256 depositTokenAmountChange = depositToken.balanceOf(
            address(this)
        ) - depositTokenAmountBeforeInvestment;
        uninvestedDepositTokenAmount += depositTokenAmountChange;

        // calculating the total equity change including contract balance change
        uint256 equityValuationAfterInvestment = getEquityValuation(
            true,
            false
        );
        uint256 totalEquityChange = equityValuationAfterInvestment -
            equityValuationBeforeInvestment;

        if (totalEquityChange == 0) revert ZeroAmountInvested();
        if (totalEquityChange < minimumDepositTokenAmountOut)
            revert TooSmallDepositTokenAmountOut();

        // minting should be based on the actual amount invested versus the deposited amount
        // to take defi fees and losses into consideration
        investmentToken.mint(
            investmentTokenReceiver,
            InvestableLib.calculateMintAmount(
                equityValuationBeforeInvestment,
                totalEquityChange,
                investmentTokenSupply
            )
        );

        // emitting the deposit amount versus the actual invested amount
        emit Deposit(
            _msgSender(),
            investmentTokenReceiver,
            depositTokenAmountIn
        );
    }

    function _beforeWithdraw(
        uint256, /*amount*/
        NameValuePair[] calldata /*params*/
    ) internal virtual returns (uint256) {
        return depositToken.balanceOf(address(this));
    }

    function _withdraw(uint256 amount, NameValuePair[] calldata params)
        internal
        virtual;

    function _afterWithdraw(
        uint256, /*amount*/
        NameValuePair[] calldata /*params*/
    ) internal virtual returns (uint256) {
        return depositToken.balanceOf(address(this));
    }

    function withdraw(
        uint256 investmentTokenAmountIn,
        uint256 minimumDepositTokenAmountOut,
        address depositTokenReceiver,
        NameValuePair[] calldata params
    ) public virtual override nonReentrant {
        if (investmentTokenAmountIn == 0) revert ZeroAmountWithdrawn();
        if (depositTokenReceiver == address(0))
            revert ZeroDepositTokenReceiver();

        // withdrawing investments from the DeFi protocols
        uint256 depositTokenBalanceBefore = _beforeWithdraw(
            investmentTokenAmountIn,
            params
        );
        _withdraw(investmentTokenAmountIn, params);
        uint256 withdrawnTotalDepositTokenAmount = _afterWithdraw(
            investmentTokenAmountIn,
            params
        ) - depositTokenBalanceBefore;

        // withdrawing from the uninvested balance
        uint256 withdrawnUninvestedDepositTokenAmount = (uninvestedDepositTokenAmount *
                investmentTokenAmountIn) / investmentToken.totalSupply();
        withdrawnTotalDepositTokenAmount += withdrawnUninvestedDepositTokenAmount;

        uninvestedDepositTokenAmount -= withdrawnUninvestedDepositTokenAmount;

        // calculating the withdrawal fee
        uint256 feeDepositTokenAmount = (withdrawnTotalDepositTokenAmount *
            getWithdrawalFee(params)) /
            Math.SHORT_FIXED_DECIMAL_FACTOR /
            100;

        // checking whether enough deposit token was withdrawn
        if (
            (withdrawnTotalDepositTokenAmount - feeDepositTokenAmount) <
            minimumDepositTokenAmountOut
        ) revert TooSmallDepositTokenAmountOut();

        // burning investment tokens
        investmentToken.burnFrom(_msgSender(), investmentTokenAmountIn);

        // transferring deposit tokens to the depositTokenReceiver
        setCurrentAccumulatedFee(
            getCurrentAccumulatedFee() + feeDepositTokenAmount
        );
        depositToken.safeTransfer(
            depositTokenReceiver,
            withdrawnTotalDepositTokenAmount - feeDepositTokenAmount
        );
        emit Withdrawal(
            _msgSender(),
            depositTokenReceiver,
            investmentTokenAmountIn
        );
    }

    function _reapReward(NameValuePair[] calldata params) internal virtual;

    function processReward(
        NameValuePair[] calldata depositParams,
        NameValuePair[] calldata reapRewardParams
    ) external virtual override nonReentrant {
        uint256 depositTokenBalanceBefore = depositToken.balanceOf(
            address(this)
        );

        // reaping the rewards, and increasing the depositToken balance of this contract
        _reapReward(reapRewardParams);

        // calculating the reward amount as
        // the sum of balance change and the uninvestedDepositTokenAmount
        uint256 rewardAmount = depositToken.balanceOf(address(this)) -
            depositTokenBalanceBefore;
        rewardAmount += uninvestedDepositTokenAmount;
        emit RewardProcess(rewardAmount);
        if (rewardAmount == 0) return;

        // depositing the reward amount back into the strategy
        depositTokenBalanceBefore = depositToken.balanceOf(address(this));
        _deposit(rewardAmount, depositParams);
        uint256 depositTokenBalanceChange = depositTokenBalanceBefore -
            depositToken.balanceOf(address(this));

        // calculating the remnants amount after the deposit that can come from AMM interactions
        uninvestedDepositTokenAmount = rewardAmount - depositTokenBalanceChange;

        emit Deposit(address(this), address(0), rewardAmount);
    }

    function withdrawReward(NameValuePair[] calldata withdrawParams)
        public
        virtual
        override
    {}

    function _setPriceOracle(IPriceOracle priceOracle_) internal virtual {
        priceOracle = priceOracle_;
    }

    function _setSwapService(SwapServiceProvider provider, address router)
        internal
        virtual
    {
        swapService = SwapService(provider, router);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IAum).interfaceId ||
            interfaceId == type(IFee).interfaceId ||
            interfaceId == type(IInvestable).interfaceId ||
            interfaceId == type(IReward).interfaceId ||
            interfaceId == type(IStrategy).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _getAssetBalances()
        internal
        view
        virtual
        returns (Balance[] memory balances);

    function getAssetBalances()
        external
        view
        virtual
        override
        returns (Balance[] memory balances)
    {
        Balance[] memory balancesReturned = _getAssetBalances();

        uint256 balancesLength = balancesReturned.length + 1;
        balances = new Balance[](balancesLength);
        for (uint256 i = 0; i < balancesLength - 1; ++i) {
            balances[i] = balancesReturned[i];
        }
        balances[balancesLength - 1] = Balance(
            InvestableLib.USDC,
            uninvestedDepositTokenAmount
        );
    }

    function _getLiabilityBalances()
        internal
        view
        virtual
        returns (Balance[] memory balances);

    function getLiabilityBalances()
        external
        view
        virtual
        returns (Balance[] memory balances)
    {
        return _getLiabilityBalances();
    }

    function _getAssetValuations(
        bool shouldMaximise,
        bool shouldIncludeAmmPrice
    ) internal view virtual returns (Valuation[] memory);

    function getAssetValuations(bool shouldMaximise, bool shouldIncludeAmmPrice)
        public
        view
        virtual
        override
        returns (Valuation[] memory valuations)
    {
        Valuation[] memory valuationsReturned = _getAssetValuations(
            shouldMaximise,
            shouldIncludeAmmPrice
        );

        // filling up the valuations array
        // 1. It could be more gas efficient to pass the extra length to _getAssetValuations,
        //    and let that method to allocate the array. However it would assume more knowledge from
        //    the strategy writer
        // 2. In the current implementation a strategy cannot hold depositToken assets apart
        //    from the uninvested depositToken. This limitation will likely be lifted in future releases.

        uint256 valuationsLength = valuationsReturned.length + 1;
        valuations = new Valuation[](valuationsLength);
        for (uint256 i = 0; i < valuationsLength - 1; ++i) {
            valuations[i] = valuationsReturned[i];
        }
        valuations[valuationsLength - 1] = Valuation(
            InvestableLib.USDC,
            uninvestedDepositTokenAmount
        );
    }

    function _getLiabilityValuations(
        bool shouldMaximise,
        bool shouldIncludeAmmPrice
    ) internal view virtual returns (Valuation[] memory);

    function getLiabilityValuations(
        bool shouldMaximise,
        bool shouldIncludeAmmPrice
    ) public view virtual override returns (Valuation[] memory) {
        return _getLiabilityValuations(shouldMaximise, shouldIncludeAmmPrice);
    }

    function getEquityValuation(bool shouldMaximise, bool shouldIncludeAmmPrice)
        public
        view
        virtual
        override
        returns (uint256)
    {
        uint256 equityValuation;

        Valuation[] memory assetValuations = getAssetValuations(
            shouldMaximise,
            shouldIncludeAmmPrice
        );
        uint256 assetValuationsLength = assetValuations.length;
        for (uint256 i = 0; i < assetValuationsLength; i++)
            equityValuation += assetValuations[i].valuation;

        Valuation[] memory liabilityValuations = getLiabilityValuations(
            shouldMaximise,
            shouldIncludeAmmPrice
        );
        uint256 liabilityValuationsLength = liabilityValuations.length;
        // negative equity should never occur, but if it does, it is safer to fail here, by underflow
        // versus returning a signed integer that is possibly negative and forgetting to handle it on the call side
        for (uint256 i = 0; i < liabilityValuationsLength; i++)
            equityValuation -= liabilityValuations[i].valuation;

        return equityValuation;
    }

    function claimFee(NameValuePair[] calldata)
        public
        virtual
        override
        nonReentrant
    {
        uint256 currentAccumulatedFeeCopy = currentAccumulatedFee;
        setClaimedFee(currentAccumulatedFeeCopy + getClaimedFee());
        setCurrentAccumulatedFee(0);
        emit FeeClaim(currentAccumulatedFeeCopy);
        depositToken.safeTransfer(feeReceiver, currentAccumulatedFeeCopy);
    }

    function getTotalDepositFee(NameValuePair[] calldata params)
        external
        view
        virtual
        override
        returns (uint24)
    {
        return getDepositFee(params);
    }

    function getTotalWithdrawalFee(NameValuePair[] calldata params)
        external
        view
        virtual
        override
        returns (uint24)
    {
        return getWithdrawalFee(params);
    }

    function getTotalPerformanceFee(NameValuePair[] calldata params)
        external
        view
        virtual
        override
        returns (uint24)
    {
        return getPerformanceFee(params);
    }

    function getDepositToken() external view returns (IERC20Upgradeable) {
        return depositToken;
    }

    function getInvestmentToken() external view returns (IInvestmentToken) {
        return investmentToken;
    }

    function _setInvestmentToken(IInvestmentToken investmentToken_)
        internal
        virtual
    {
        investmentToken = investmentToken_;
    }

    function getInvestmentTokenBalanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return investmentToken.balanceOf(account);
    }

    function getInvestmentTokenSupply()
        public
        view
        virtual
        override
        returns (uint256)
    {
        return investmentToken.totalSupply();
    }

    function swapExactTokensForTokens(
        SwapService memory swapService_,
        uint256 amountIn,
        address[] memory path
    ) internal returns (uint256 amountOut) {
        if (swapService_.provider == SwapServiceProvider.TraderJoe) {
            ITraderJoeRouter traderjoeRouter = ITraderJoeRouter(
                swapService_.router
            );

            IERC20Upgradeable(path[0]).approve(
                address(traderjoeRouter),
                amountIn
            );

            amountOut = traderjoeRouter.swapExactTokensForTokens(
                amountIn,
                0,
                path,
                address(this),
                // solhint-disable-next-line not-rely-on-time
                block.timestamp
            )[path.length - 1];
        } else {
            revert InvalidSwapServiceProvider();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../Common.sol";
import "../interfaces/IFee.sol";
import "../libraries/Math.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract FeeUpgradeable is Initializable, IFee {
    uint24 internal withdrawalFee;
    uint24 internal depositFee;
    uint24 internal performanceFee;
    uint256 internal currentAccumulatedFee;
    uint256 internal claimedFee;
    address internal feeReceiver;
    uint256[40] private __gap;

    // solhint-disable-next-line func-name-mixedcase
    function __FeeUpgradeable_init(
        uint24 depositFee_,
        NameValuePair[] calldata depositFeeParams_,
        uint24 withdrawalFee_,
        NameValuePair[] calldata withdrawFeeParams_,
        uint24 performanceFee_,
        NameValuePair[] calldata performanceFeeParams_,
        address feeReceiver_,
        NameValuePair[] calldata feeReceiverParams_
    ) internal onlyInitializing {
        _setDepositFee(depositFee_, depositFeeParams_);
        _setWithdrawalFee(withdrawalFee_, withdrawFeeParams_);
        _setPerformanceFee(performanceFee_, performanceFeeParams_);
        _setFeeReceiver(feeReceiver_, feeReceiverParams_);
    }

    modifier checkFee(uint24 fee) {
        if (fee >= uint256(100) * Math.SHORT_FIXED_DECIMAL_FACTOR)
            revert InvalidFeeError();

        _;
    }

    function getDepositFee(NameValuePair[] calldata)
        public
        view
        virtual
        returns (uint24)
    {
        return depositFee;
    }

    function _setDepositFee(uint24 fee, NameValuePair[] calldata params)
        internal
        virtual
        checkFee(fee)
    {
        depositFee = fee;
        emit DepositFeeChange(depositFee, params);
    }

    function getWithdrawalFee(NameValuePair[] calldata)
        public
        view
        virtual
        returns (uint24)
    {
        return withdrawalFee;
    }

    function _setWithdrawalFee(uint24 fee, NameValuePair[] calldata params)
        internal
        virtual
        checkFee(fee)
    {
        withdrawalFee = fee;
        emit WithdrawalFeeChange(withdrawalFee, params);
    }

    function getPerformanceFee(NameValuePair[] calldata)
        public
        view
        virtual
        returns (uint24)
    {
        return performanceFee;
    }

    function _setPerformanceFee(uint24 fee, NameValuePair[] calldata params)
        internal
        virtual
        checkFee(fee)
    {
        performanceFee = fee;
        emit PerformanceFeeChange(performanceFee, params);
    }

    function getFeeReceiver(NameValuePair[] calldata)
        external
        view
        virtual
        returns (address)
    {
        return feeReceiver;
    }

    function _setFeeReceiver(
        address feeReceiver_,
        NameValuePair[] calldata params
    ) internal virtual {
        if (feeReceiver_ == address(0)) revert ZeroFeeReceiver();

        feeReceiver = feeReceiver_;
        emit FeeReceiverChange(feeReceiver, params);
    }

    function getCurrentAccumulatedFee() public view virtual returns (uint256) {
        return currentAccumulatedFee;
    }

    function getClaimedFee() public view virtual returns (uint256) {
        return claimedFee;
    }

    function setClaimedFee(uint256 claimedFee_) internal virtual {
        claimedFee = claimedFee_;
    }

    function setCurrentAccumulatedFee(uint256 currentAccumulatedFee_)
        internal
        virtual
    {
        currentAccumulatedFee = currentAccumulatedFee_;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../interfaces/IInvestable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract InvestmentLimitUpgradeable is Initializable, IInvestable {
    error TotalInvestmentLimitExceeded();
    error InvestmentLimitPerAddressExceeded();

    uint256 private totalInvestmentLimit;
    uint256 private investmentLimitPerAddress;
    uint256[8] private __gap;

    // solhint-disable-next-line func-name-mixedcase
    function __InvestmentLimitUpgradeable_init(
        uint256 totalInvestmentLimit_,
        uint256 investmentLimitPerAddress_
    ) internal onlyInitializing {
        _setTotalInvestmentLimit(totalInvestmentLimit_);
        _setInvestmentLimitPerAddress(investmentLimitPerAddress_);
    }

    function getTotalInvestmentLimit()
        external
        view
        virtual
        override
        returns (uint256)
    {
        return totalInvestmentLimit;
    }

    function _setTotalInvestmentLimit(uint256 totalInvestmentLimit_)
        internal
        virtual
    {
        totalInvestmentLimit = totalInvestmentLimit_;
    }

    function getInvestmentLimitPerAddress()
        external
        view
        virtual
        override
        returns (uint256)
    {
        return investmentLimitPerAddress;
    }

    function _setInvestmentLimitPerAddress(uint256 investmentLimitPerAddress_)
        internal
        virtual
    {
        investmentLimitPerAddress = investmentLimitPerAddress_;
    }

    function checkTotalInvestmentLimit(
        uint256 aboutToInvest,
        uint256 totalInvestedSoFar
    ) internal virtual {
        if (aboutToInvest + totalInvestedSoFar > totalInvestmentLimit)
            revert TotalInvestmentLimitExceeded();
    }

    function checkInvestmentLimitPerAddress(
        uint256 aboutToInvest,
        uint256 investedSoFarPerAddress
    ) internal virtual {
        if (aboutToInvest + investedSoFarPerAddress > investmentLimitPerAddress)
            revert InvestmentLimitPerAddressExceeded();
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IInvestmentToken is IERC20Upgradeable {
    function mint(address account, uint256 amount) external;

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";

interface IPriceOracle {
    error InvalidAssetPrice();

    function getPrice(
        IERC20Upgradeable token,
        bool shouldMaximise,
        bool includeAmmPrice
    ) external view returns (uint256);

    function setVendorFeed(address vendorFeed_) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../interfaces/IReward.sol";
import "../interfaces/IInvestable.sol";

interface IStrategy is IInvestable, IReward {}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./Math.sol";

struct TokenDesc {
    uint256 total;
    uint256 acquired;
}

library InvestableLib {
    address public constant NATIVE_AVAX =
        0x0000000000000000000000000000000000000001;
    address public constant WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address public constant USDT = 0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7;
    address public constant USDC = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;

    uint8 public constant PRICE_PRECISION_DIGITS = 6;
    uint256 public constant PRICE_PRECISION_FACTOR = 10**PRICE_PRECISION_DIGITS;

    function convertPricePrecision(
        uint256 price,
        uint256 currentPrecision,
        uint256 desiredPrecision
    ) internal pure returns (uint256) {
        if (currentPrecision > desiredPrecision)
            return (price / (currentPrecision / desiredPrecision));
        else if (currentPrecision < desiredPrecision)
            return price * (desiredPrecision / currentPrecision);
        else return price;
    }

    function calculateMintAmount(
        uint256 equitySoFar,
        uint256 amountInvestedNow,
        uint256 investmentTokenSupplySoFar
    ) internal pure returns (uint256) {
        if (investmentTokenSupplySoFar == 0) return amountInvestedNow;
        else
            return
                (amountInvestedNow * investmentTokenSupplySoFar) / equitySoFar;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface ITraderJoeRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

struct NameValuePair {
    string key;
    string value;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../Common.sol";

interface IFee {
    error InvalidFeeError();
    error ZeroFeeReceiver();

    event DepositFeeChange(uint256 fee, NameValuePair[] params);
    event WithdrawalFeeChange(uint256 fee, NameValuePair[] params);
    event PerformanceFeeChange(uint256 fee, NameValuePair[] params);
    event FeeReceiverChange(address feeReceiver, NameValuePair[] params);
    event FeeClaim(uint256 fee);

    function getDepositFee(NameValuePair[] calldata params)
        external
        view
        returns (uint24);

    function getTotalDepositFee(NameValuePair[] calldata params)
        external
        view
        returns (uint24);

    function setDepositFee(uint24 fee, NameValuePair[] calldata params)
        external;

    function getWithdrawalFee(NameValuePair[] calldata params)
        external
        view
        returns (uint24);

    function getTotalWithdrawalFee(NameValuePair[] calldata params)
        external
        view
        returns (uint24);

    function setWithdrawalFee(uint24 fee, NameValuePair[] calldata params)
        external;

    function getPerformanceFee(NameValuePair[] calldata params)
        external
        view
        returns (uint24);

    function getTotalPerformanceFee(NameValuePair[] calldata params)
        external
        view
        returns (uint24);

    function setPerformanceFee(uint24 fee, NameValuePair[] calldata params)
        external;

    function getFeeReceiver(NameValuePair[] calldata params)
        external
        view
        returns (address);

    function setFeeReceiver(
        address feeReceiver,
        NameValuePair[] calldata params
    ) external;

    function claimFee(NameValuePair[] calldata params) external;

    function getCurrentAccumulatedFee() external view returns (uint256);

    function getClaimedFee() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

library Math {
    uint16 public constant SHORT_FIXED_DECIMAL_FACTOR = 10**3;
    uint24 public constant MEDIUM_FIXED_DECIMAL_FACTOR = 10**6;
    uint256 public constant LONG_FIXED_DECIMAL_FACTOR = 10**30;

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x > y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./IAum.sol";
import "./IFee.sol";
import "./IInvestmentToken.sol";

interface IInvestable is IAum, IFee {
    error ZeroAmountDeposited();
    error ZeroAmountInvested();
    error ZeroAmountWithdrawn();
    error ZeroInvestmentTokenReceiver();
    error ZeroDepositTokenReceiver();
    error TooSmallDepositTokenAmountOut();

    event Deposit(
        address indexed initiator,
        address indexed investmentTokenReceiver,
        uint256 amount
    );
    event Withdrawal(
        address indexed initiator,
        address indexed depositTokenReceiver,
        uint256 amount
    );

    function deposit(
        uint256 depositTokenAmountIn,
        uint256 minimumDepositTokenAmountOut,
        address investmentTokenReceiver,
        NameValuePair[] calldata params
    ) external;

    function withdraw(
        uint256 investmentTokenAmountIn,
        uint256 minimumDepositTokenAmountOut,
        address depositTokenReceiver,
        NameValuePair[] calldata params
    ) external;

    function getDepositToken() external view returns (IERC20Upgradeable);

    function getInvestmentToken() external view returns (IInvestmentToken);

    function setInvestmentToken(IInvestmentToken investmentToken) external;

    function getTotalInvestmentLimit() external view returns (uint256);

    function setTotalInvestmentLimit(uint256 totalInvestmentLimit) external;

    function getInvestmentLimitPerAddress() external view returns (uint256);

    function setInvestmentLimitPerAddress(uint256 investmentLimitPerAddress)
        external;

    function trackingName() external pure returns (string memory);

    function humanReadableName() external pure returns (string memory);

    function version() external pure returns (string memory);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IAum {
    struct Balance {
        address asset;
        uint256 balance;
    }

    struct Valuation {
        address asset;
        uint256 valuation;
    }

    function getAssetBalances() external view returns (Balance[] memory);

    function getLiabilityBalances() external view returns (Balance[] memory);

    function getAssetValuations(bool shouldMaximise, bool shouldIncludeAmmPrice)
        external
        view
        returns (Valuation[] memory);

    function getLiabilityValuations(
        bool shouldMaximise,
        bool shouldIncludeAmmPrice
    ) external view returns (Valuation[] memory);

    function getEquityValuation(bool shouldMaximise, bool shouldIncludeAmmPrice)
        external
        view
        returns (uint256);

    function getInvestmentTokenSupply() external view returns (uint256);

    function getInvestmentTokenBalanceOf(address user)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../Common.sol";

interface IReward {
    event RewardProcess(uint256 amount);
    event RewardWithdraw(address indexed withdrawer, uint256 amount);

    function processReward(
        NameValuePair[] calldata depositParams,
        NameValuePair[] calldata reapRewardParams
    ) external;

    function withdrawReward(NameValuePair[] calldata withdrawParams) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}
// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IManager} from "@ohfinance/core/contracts/interfaces/manager/IManager.sol";
import {IStrategy} from "@ohfinance/core/contracts/interfaces/strategy/IStrategy.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {OhSubscriberUpgradeable} from "@ohfinance/core/contracts/registry/OhSubscriberUpgradeable.sol";
import {TransferHelper} from "@ohfinance/core/contracts/libraries/TransferHelper.sol";
import {ICurveYusdPool} from "./interfaces/ICurveYusdPool.sol";
import {IBoostedFarm} from "./interfaces/IBoostedFarm.sol";
import {IVeYeti} from "./interfaces/IVeYeti.sol";
import {IVeYetiEmissions} from "./interfaces/IVeYetiEmissions.sol";
import {OhYetiCompounderStorage} from "./OhYetiCompounderStorage.sol";
import {IYetiCompounder} from "./interfaces/IYetiCompounder.sol";
import {OhYetiHelper} from "./OhYetiHelper.sol";

contract OhYetiCompounder is OhSubscriberUpgradeable, OhYetiCompounderStorage, OhYetiHelper, IYetiCompounder {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Only allow Strategies or Governance to call function
    modifier onlyAllowed() {
        require(IManager(manager()).whitelisted(msg.sender) || msg.sender == governance(), "OhYetiCompounder: Only Strategy or Governance");
        _;
    }

    constructor() initializer {
        assert(yeti() == address(0));
        assert(crvYusdPool() == address(0));
        assert(farm() == address(0));
        assert(veYeti() == address(0));
        assert(veYetiEmissions() == address(0));
    }

    /// @notice Initialize the Yeti Compounder Proxy
    /// @param registry_ Address of the Registry contract
    /// @param yeti_ The YETI token
    /// @param crvYusdPool_ The Curve YUSD/USDC/USDT pool used to stake underlying and get Curve LP Tokens back
    /// @param farm_ YETI Curve LP Farm Staking Contract
    /// @param veYeti_ The untradeable token used for boosting yield on YETI pools (farmed by staking YETI into veYETI pool)
    /// @param veYetiEmissions_ The YETI contract used to claim YETI rewards when satking into the veYETI pool
    function initializeYetiCompounder(
        address registry_,
        address yeti_,
        address crvYusdPool_,
        address farm_,
        address veYeti_,
        address veYetiEmissions_,
        uint256 boostPercentage
    ) public initializer {
        initializeSubscriber(registry_);
        initializeYetiCompounderStorage(yeti_, crvYusdPool_, farm_, veYeti_, veYetiEmissions_, boostPercentage);

        IERC20(yeti_).safeApprove(veYeti_, type(uint256).max);
    }

    function investedBalance(uint256 index) public view override returns (uint256) {
        uint256 _balance;
        if (index == 1) {
            _balance = usdcBalance();
        } else if (index == 2) {
            _balance = usdtBalance();
        }

        return _balance;
    }

    /// @notice Get the balance of staked tokens in the YETI LP Farm Pool
    function staked(uint256 index) external view override returns (uint256) {
        uint256 _stakedBalance;
        if (index == 1) {
            _stakedBalance = usdcBalance();
        } else if (index == 2) {
            _stakedBalance = usdtBalance();
        }

        return _stakedBalance;
    }

    /// @notice Add liquidity to Curve's YUSD Pool, receiving Curve LP Tokens in return
    /// @param underlying The underlying we want to deposit
    /// @param index The index of the underlying
    /// @param amount The amount of underlying to deposit
    /// @param minMint The min LP tokens to mint before tx reverts (slippage)
    function addLiquidity(
        address underlying,
        uint256 index,
        uint256 amount,
        uint256 minMint
    ) external override onlyAllowed {
        if (amount == 0) {
            return;
        }
        IERC20(underlying).safeTransferFrom(msg.sender, address(this), amount);
        uint256 minted = addLiquidity(crvYusdPool(), underlying, index, amount, minMint);
        increaseBalance(index, minted);
    }

    /// @notice Remove liquidity from Curve YUSD Pool, receiving a single underlying
    /// @param index The index of underlying we want to withdraw
    /// @param amount The amount of LP tokens to withdraw
    /// @param minAmount The min underlying tokens to receive before the tx reverts (slippage)
    function removeLiquidity(
        address underlying,
        address recipient,
        uint256 index,
        uint256 amount,
        uint256 minAmount
    ) external override onlyAllowed {
        if (amount == 0) {
            return;
        }
        uint256 withdrawn = removeLiquidity(crvYusdPool(), index, amount, minAmount);
        decreaseBalance(index, amount);
        TransferHelper.safeTokenTransfer(recipient, underlying, withdrawn);
    }

    /// @notice Stake Curve LP Tokens into the Boosted Farm to earn YETI
    function stake() external override onlyAllowed {
        address lpToken = crvYusdPool();
        uint256 amount = IERC20(lpToken).balanceOf(address(this));
        if (amount == 0) {
            return;
        }
        deposit(farm(), lpToken, amount);
    }

    /// @notice Unstake Curve LP Tokens funds from the Boosted Farm
    /// @param liquidity The amount of LP Tokens to withdraw
    function unstake(uint256 liquidity) external override onlyAllowed {
        if (liquidity == 0) {
            return;
        }
        withdraw(farm(), liquidity);
    }

    /// @notice Claim YETI rewards from the given pool
    function claim(uint256 index) external override onlyAllowed {
        address yeti = yeti();
        address farm = farm();
        uint256 boost = boostPercentage();

        // Claim Farm rewards
        withdraw(farm, 0);

        // Claim veYeti rewards if boost
        if (boost > 0) {
            getReward(veYetiEmissions());
        }

        uint256 rewardAmount = IERC20(yeti).balanceOf(address(this)).sub(usdcRewards()).sub(usdtRewards());
        if (rewardAmount > 0) {
            // calculate boost, update reward amounts with remaining
            uint256 boostAmount = rewardAmount.mul(boost).div(100);
            updateRewardAmount(rewardAmount.sub(boostAmount));

            // Transfer accumulated rewards to calling strategy, reset reward amount after
            if (index == 1) {
                TransferHelper.safeTokenTransfer(msg.sender, yeti, usdcRewards());
            } else if (index == 2) {
                TransferHelper.safeTokenTransfer(msg.sender, yeti, usdtRewards());
            }
            resetRewardAmount(index);

            // stake boost amount in veYeti, if boost
            if (boost > 0) {
                update(veYeti(), farm, boostAmount, true);
            }
        }
    }

    /// @notice Claim pending veYeti
    function claimVeYeti() external override {
        update(veYeti(), farm(), 0, true);
    }

    /// @notice Deposit YETI to veYETI contract
    function depositYeti() external override {
        uint256 amount = IERC20(yeti()).balanceOf(address(this)).sub(usdcRewards()).sub(usdtRewards());
        if (amount > 0) {
            update(veYeti(), farm(), amount, true);
        }
    }

    /// @notice Withdraw YETI from veYETI contract, only Governance
    /// @notice WARNING: Will lose all accumulated veYETI!!!
    /// @param amount The amount of YETI to withdraw
    function withdrawYeti(uint256 amount) external override onlyGovernance {
        if (amount > 0) {
            update(veYeti(), farm(), amount, false);
        }
    }

    /// @notice Reclaim YETI to Governance after Withdrawal, only Governance
    /// @param amount The amount of YETI to withdraw
    function reclaimYeti(uint256 amount) external onlyGovernance {
        IERC20(yeti()).transfer(governance(), amount);
    }

    /// @notice Set the Boost Percentage, only Governance
    /// @dev Percentage of YETI rewards retained by Compounder
    function setBoostPercentage(uint256 newBoostPercentage) external onlyGovernance {
        require(newBoostPercentage >= 0 && newBoostPercentage < 100, "Invalid Boost Percentage");
        _setBoostPercentage(newBoostPercentage);
    }

    /// @notice Add to the underlying balance of the calling strategy
    function increaseBalance(uint256 index, uint256 minted) internal {
        if (index == 1) {
            uint256 newBalance = usdcBalance().add(minted);
            _setUsdcBalance(newBalance);
        } else if (index == 2) {
            uint256 newBalance = usdtBalance().add(minted);
            _setUsdtBalance(newBalance);
        }
    }

    /// @notice Substract to the underlying balance of the calling strategy
    function decreaseBalance(uint256 index, uint256 withdrawn) internal {
        if (index == 1) {
            uint256 _usdcBalance = usdcBalance();
            require(withdrawn <= _usdcBalance, "YETI: Not enough USDC liquity for withdrawal");
            uint256 newBalance = _usdcBalance.sub(withdrawn);
            _setUsdcBalance(newBalance);
        } else if (index == 2) {
            uint256 _usdtBalance = usdtBalance();
            require(withdrawn <= _usdtBalance, "YETI: Not enough USDT liquity for withdrawal");
            uint256 newBalance = _usdtBalance.sub(withdrawn);
            _setUsdtBalance(newBalance);
        }
    }

    function updateRewardAmount(uint256 rewardAmount) internal {
        uint256 usdcBalance = usdcBalance();
        uint256 usdtBalance = usdtBalance();
        uint256 totalBalance = usdcBalance.add(usdtBalance);

        if (totalBalance == 0) {
            return;
        }

        uint256 usdcAmount = rewardAmount.mul(usdcBalance).div(totalBalance);
        uint256 usdtAmount = rewardAmount.sub(usdcAmount);

        _setUsdcRewards(usdcRewards().add(usdcAmount));
        _setUsdtRewards(usdtRewards().add(usdtAmount));
    }

    function resetRewardAmount(uint256 index) internal {
        if (index == 1) {
            _setUsdcRewards(0);
        } else if (index == 2) {
            _setUsdtRewards(0);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity 0.7.6;

interface IManager {
    function token() external view returns (address);

    function buybackFee() external view returns (uint256);

    function managementFee() external view returns (uint256);

    function liquidators(address from, address to) external view returns (address);

    function whitelisted(address _contract) external view returns (bool);

    function banks(uint256 i) external view returns (address);

    function totalBanks() external view returns (uint256);

    function strategies(address bank, uint256 i) external view returns (address);

    function totalStrategies(address bank) external view returns (uint256);

    function withdrawIndex(address bank) external view returns (uint256);

    function setWithdrawIndex(uint256 i) external;

    function rebalance(address bank) external;

    function finance(address bank) external;

    function financeAll(address bank) external;

    function buyback(address from) external;

    function accrueRevenue(
        address bank,
        address underlying,
        uint256 amount
    ) external;

    function exitAll(address bank) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import {IStrategyBase} from "./IStrategyBase.sol";

interface IStrategy is IStrategyBase {
    function investedBalance() external view returns (uint256);

    function invest() external;

    function withdraw(uint256 amount) external returns (uint256);

    function withdrawAll() external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ISubscriber} from "../interfaces/ISubscriber.sol";
import {IRegistry} from "../interfaces/IRegistry.sol";
import {OhUpgradeable} from "../proxy/OhUpgradeable.sol";

/// @title Oh! Finance Subscriber Upgradeable
/// @notice Base Oh! Finance upgradeable contract used to control access throughout the protocol
abstract contract OhSubscriberUpgradeable is Initializable, OhUpgradeable, ISubscriber {
    bytes32 private constant _REGISTRY_SLOT = 0x1b5717851286d5e98a28354be764b8c0a20eb2fbd059120090ee8bcfe1a9bf6c;

    /// @notice Only allow authorized addresses (governance or manager) to execute a function
    modifier onlyAuthorized {
        require(msg.sender == governance() || msg.sender == manager(), "Subscriber: Only Authorized");
        _;
    }

    /// @notice Only allow the governance address to execute a function
    modifier onlyGovernance {
        require(msg.sender == governance(), "Subscriber: Only Governance");
        _;
    }

    /// @notice Verify the registry storage slot is correct
    constructor() {
        assert(_REGISTRY_SLOT == bytes32(uint256(keccak256("eip1967.subscriber.registry")) - 1));
    }

    /// @notice Initialize the Subscriber
    /// @param registry_ The Registry contract address
    /// @dev Always call this method in the initializer function for any derived classes
    function initializeSubscriber(address registry_) internal initializer {
        require(Address.isContract(registry_), "Subscriber: Invalid Registry");
        _setRegistry(registry_);
    }

    /// @notice Set the Registry for the contract. Only callable by Governance.
    /// @param registry_ The new registry
    /// @dev Requires sender to be Governance of the new Registry to avoid bricking.
    /// @dev Ideally should not be used
    function setRegistry(address registry_) external onlyGovernance {
        _setRegistry(registry_);
        require(msg.sender == governance(), "Subscriber: Bad Governance");
    }

    /// @notice Get the Governance address
    /// @return The current Governance address
    function governance() public view override returns (address) {
        return IRegistry(registry()).governance();
    }

    /// @notice Get the Manager address
    /// @return The current Manager address
    function manager() public view override returns (address) {
        return IRegistry(registry()).manager();
    }

    /// @notice Get the Registry address
    /// @return The current Registry address
    function registry() public view override returns (address) {
        return getAddress(_REGISTRY_SLOT);
    }

    function _setRegistry(address registry_) private {
        setAddress(_REGISTRY_SLOT, registry_);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

library TransferHelper {
    using SafeERC20 for IERC20;

    // safely transfer tokens without underflowing
    function safeTokenTransfer(
        address recipient,
        address token,
        uint256 amount
    ) internal returns (uint256) {
        if (amount == 0) {
            return 0;
        }

        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance < amount) {
            IERC20(token).safeTransfer(recipient, balance);
            return balance;
        } else {
            IERC20(token).safeTransfer(recipient, amount);
            return amount;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface ICurveYusdPool {
    function calc_token_amount(uint256[3] calldata amounts, bool deposit)
        external
        view
        returns (uint256);

    function calc_withdraw_one_coin(uint256, int128) external view returns (uint256);

    function get_virtual_price() external view returns (uint256);

    function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount) external returns(uint256);

    function remove_liquidity_imbalance(uint256[3] calldata amounts, uint256 max_burn_amount)
        external;

    function remove_liquidity_one_coin(uint256 amount, int128 i, uint256 min_amount)
        external returns(uint256);

    function remove_liquidity(uint256 _amount, uint256[3] calldata amounts) external;

    function exchange(
        int128 from,
        int128 to,
        uint256 _from_amount,
        uint256 _min_to_amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IBoostedFarm {
    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function emergencyWithdraw() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import {Structs} from "../libraries/Structs.sol";

interface IVeYeti {
    function getTotalVeYeti(address user) external view returns (uint256);

    function getUserYetiOnRewarder(address _user, address _rewarder) external view returns (uint256);

    function getVeYetiOnRewarder(address _user, address _rewarder) external view returns (uint256);

    function update(Structs.RewarderUpdate[] memory _yetiAdjustments) external;

    function updateWhitelistedCallers(address _contract, bool _isWhitelisted) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IVeYetiEmissions {
    function getReward() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import {IYetiCompounderStorage} from "./interfaces/IYetiCompounderStorage.sol";
import {OhUpgradeable} from "@ohfinance/core/contracts/proxy/OhUpgradeable.sol";

contract OhYetiCompounderStorage is Initializable, OhUpgradeable, IYetiCompounderStorage {
    bytes32 internal constant _YETI_SLOT = 0x3f6dc11b5e4ef53289fde3761e1fd7b11049baab5e02e7fdf908b4adb01c3b1a;
    bytes32 internal constant _CRV_YUSD_POOL_SLOT = 0x88ca2342a3fc4afcb04cc6b080cd7f652518b33711d6fbe85dde191d0a1baf70;
    bytes32 internal constant _FARM_SLOT = 0x7d7d580976873f64d6e5ff5e130255b12492c7aa8d894f9a7a2debf05a3dea55;
    bytes32 internal constant _VE_YETI_SLOT = 0x87e10c3bfa4acbda13d0ae7794caaa1f028a0bfae02e2a0b4d3830358ce76879;
    bytes32 internal constant _VE_YETI_EMISSIONS_SLOT = 0x6bea31947bedc4a2e37dfa588b5e0e8124d998e5bef2554c2f592ef5aedbbe10;
    bytes32 internal constant _BOOST_PERCENTAGE_SLOT = 0x1714a43197ea524f54896fb818ec51b1a2eb1f525eb3e65a1615fb44daba9432;
    bytes32 internal constant _USDC_BALANCE_SLOT = 0x16ea6ab2a4b5e0da286e9200f27cf8deddcaba859708957b63f1a46243479d0a;
    bytes32 internal constant _USDT_BALANCE_SLOT = 0x62cb3c717ea5c73d19bbcdaeb0c7ea0b32d5754621c670c03c9605f456b97484;
    bytes32 internal constant _USDC_REWARDS_SLOT = 0xa012340a1ad022564999460c0d0a6e319d55014e78857321f5a1be37a4fa5aca;
    bytes32 internal constant _USDT_REWARDS_SLOT = 0x8a80b262a6f5b2995c0b41093a4418d773fbc63b190d9b3c099c76b12104df35;

    constructor() {
        assert(_YETI_SLOT == bytes32(uint256(keccak256("eip1967.yetiStrategy.yeti")) - 1));
        assert(_CRV_YUSD_POOL_SLOT == bytes32(uint256(keccak256("eip1967.yetiStrategy.crvyusdpool")) - 1));
        assert(_FARM_SLOT == bytes32(uint256(keccak256("eip1967.yetiStrategy.farm")) - 1));
        assert(_VE_YETI_SLOT == bytes32(uint256(keccak256("eip1967.yetiStrategy.veyeti")) - 1));
        assert(_VE_YETI_EMISSIONS_SLOT == bytes32(uint256(keccak256("eip1967.yetiStrategy.veyetiemissions")) - 1));
        assert(_BOOST_PERCENTAGE_SLOT == bytes32(uint256(keccak256("eip1967.yetiStrategy.boostpercentage")) - 1));
        assert(_USDC_BALANCE_SLOT == bytes32(uint256(keccak256("eip1967.yetiStrategy.usdcbalance")) - 1));
        assert(_USDT_BALANCE_SLOT == bytes32(uint256(keccak256("eip1967.yetiStrategy.usdtbalance")) - 1));
        assert(_USDC_REWARDS_SLOT == bytes32(uint256(keccak256("eip1967.yetiStrategy.usdcrewards")) - 1));
        assert(_USDT_REWARDS_SLOT == bytes32(uint256(keccak256("eip1967.yetiStrategy.usdtrewards")) - 1));
    }

    function initializeYetiCompounderStorage(
        address yeti_,
        address crvYusdPool_,
        address farm_,
        address veYeti_,
        address veYetiEmissions_,
        uint256 boostPercentage_
    ) internal initializer {
        _setYeti(yeti_);
        _setCrvYusdPool(crvYusdPool_);
        _setFarm(farm_);
        _setVeYeti(veYeti_);
        _setVeYetiEmissions(veYetiEmissions_);
        _setBoostPercentage(boostPercentage_);
        _setUsdcBalance(0);
        _setUsdtBalance(0);
        _setUsdcRewards(0);
        _setUsdtRewards(0);
    }

    function yeti() public view override returns (address) {
        return getAddress(_YETI_SLOT);
    }

    function crvYusdPool() public view override returns (address) {
        return getAddress(_CRV_YUSD_POOL_SLOT);
    }

    function farm() public view override returns (address) {
        return getAddress(_FARM_SLOT);
    }

    function veYeti() public view override returns (address) {
        return getAddress(_VE_YETI_SLOT);
    }

    function veYetiEmissions() public view override returns (address) {
        return getAddress(_VE_YETI_EMISSIONS_SLOT);
    }

    function boostPercentage() public view override returns (uint256) {
        return getUInt256(_BOOST_PERCENTAGE_SLOT);
    }

    function usdcBalance() public view override returns (uint256) {
        return getUInt256(_USDC_BALANCE_SLOT);
    }

    function usdtBalance() public view override returns (uint256) {
        return getUInt256(_USDT_BALANCE_SLOT);
    }

    function usdcRewards() public view override returns (uint256) {
        return getUInt256(_USDC_REWARDS_SLOT);
    }

    function usdtRewards() public view override returns (uint256) {
        return getUInt256(_USDT_REWARDS_SLOT);
    }

    function _setYeti(address yeti_) internal {
        setAddress(_YETI_SLOT, yeti_);
    }

    function _setCrvYusdPool(address crvYusdPool_) internal {
        setAddress(_CRV_YUSD_POOL_SLOT, crvYusdPool_);
    }

    function _setFarm(address farm_) internal {
        setAddress(_FARM_SLOT, farm_);
    }

    function _setVeYeti(address veYeti_) internal {
        setAddress(_VE_YETI_SLOT, veYeti_);
    }

    function _setVeYetiEmissions(address veYetiEmissions_) internal {
        setAddress(_VE_YETI_EMISSIONS_SLOT, veYetiEmissions_);
    }

    function _setBoostPercentage(uint256 boostPercentage_) internal {
        setUInt256(_BOOST_PERCENTAGE_SLOT, boostPercentage_);
    }

    function _setUsdcBalance(uint256 usdcBalance_) internal {
        setUInt256(_USDC_BALANCE_SLOT, usdcBalance_);
    }

    function _setUsdtBalance(uint256 usdtBalance_) internal {
        setUInt256(_USDT_BALANCE_SLOT, usdtBalance_);
    }

    function _setUsdcRewards(uint256 usdcRewards_) internal {
        setUInt256(_USDC_REWARDS_SLOT, usdcRewards_);
    }

    function _setUsdtRewards(uint256 usdtRewards_) internal {
        setUInt256(_USDT_REWARDS_SLOT, usdtRewards_);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IYetiCompounder {
    function investedBalance(uint256 index) external view returns (uint256);

    function addLiquidity(
        address underlying,
        uint256 index,
        uint256 amount,
        uint256 minMint
    ) external;

    function removeLiquidity(
        address underlying,
        address recipient,
        uint256 index,
        uint256 amount,
        uint256 minAmount
    ) external;

    function stake() external;

    function unstake(uint256 amount) external;

    function staked(uint256 index) external view returns (uint256);

    function claim(uint256 index) external;

    function depositYeti() external;

    function withdrawYeti(uint256 amount) external;

    function claimVeYeti() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {ICurveYusdPool} from "./interfaces/ICurveYusdPool.sol";
import {IVeYeti} from "./interfaces/IVeYeti.sol";
import {IVeYetiEmissions} from "./interfaces/IVeYetiEmissions.sol";
import {IBoostedFarm} from "./interfaces/IBoostedFarm.sol";
import {Structs} from "./libraries/Structs.sol";

/// @title Oh! Finance YETI Helper
/// @notice Helper functions for YETI Strategies
abstract contract OhYetiHelper {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /// @notice Calculate the max withdrawal amount to a single underlying
    /// @param pool The Curve LP Pool
    /// @param amount The amount of LP tokens to withdraw
    /// @param index The index of the underlying in the LP Pool
    function calcWithdraw(
        address pool,
        uint256 amount,
        uint256 index
    ) internal view returns (uint256) {
        if (amount == 0) {
            return 0;
        }

        return ICurveYusdPool(pool).calc_withdraw_one_coin(amount, int128(index));
    }

    function addLiquidity(
        address pool,
        address underlying,
        uint256 index,
        uint256 amount,
        uint256 minMint
    ) internal returns (uint256 minted) {
        uint256[3] memory amounts = [uint256(0), uint256(0), uint256(0)];
        amounts[index] = amount;
        IERC20(underlying).safeIncreaseAllowance(pool, amount);
        minted = ICurveYusdPool(pool).add_liquidity(amounts, minMint);
        require(minted >= minMint, "YETI: Add Liquidity failed");
    }

    function removeLiquidity(
        address pool,
        uint256 index,
        uint256 amount,
        uint256 minAccepted
    ) internal returns (uint256 withdrawn) {
        IERC20(pool).safeIncreaseAllowance(pool, amount);
        withdrawn = ICurveYusdPool(pool).remove_liquidity_one_coin(amount, int128(index), minAccepted);
        require(withdrawn >= minAccepted, "YETI: Withdraw failed");
    }

    function deposit(
        address farm,
        address lpToken,
        uint256 amount
    ) internal {
        IERC20(lpToken).safeIncreaseAllowance(farm, amount);
        IBoostedFarm(farm).deposit(amount);
    }

    function withdraw(address farm, uint256 liquidity) internal {
        IBoostedFarm(farm).withdraw(liquidity);
    }

    function update(
        address veYeti,
        address rewarder,
        uint256 amount,
        bool isIncrease
    ) internal {
        Structs.RewarderUpdate memory data = Structs.RewarderUpdate({rewarder: rewarder, amount: amount, isIncrease: isIncrease});
        Structs.RewarderUpdate[] memory updates = new Structs.RewarderUpdate[](1);
        updates[0] = data;
        IVeYeti(veYeti).update(updates);
    }

    function getReward(address veYetiEmissions) internal {
        IVeYetiEmissions(veYetiEmissions).getReward();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import {IStrategyStorage} from "./IStrategyStorage.sol";

interface IStrategyBase is IStrategyStorage {
    function underlyingBalance() external view returns (uint256);

    function derivativeBalance() external view returns (uint256);

    function rewardBalance() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IStrategyStorage {
    function bank() external view returns (address);

    function underlying() external view returns (address);

    function derivative() external view returns (address);

    function reward() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface ISubscriber {
    function registry() external view returns (address);

    function governance() external view returns (address);

    function manager() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IRegistry {
    function governance() external view returns (address);

    function manager() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

/// @title Oh! Finance Base Upgradeable
/// @notice Contains internal functions to get/set primitive data types used by a proxy contract
abstract contract OhUpgradeable {
    function getAddress(bytes32 slot) internal view returns (address _address) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            _address := sload(slot)
        }
    }

    function getBoolean(bytes32 slot) internal view returns (bool _bool) {
        uint256 bool_;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            bool_ := sload(slot)
        }
        _bool = bool_ == 1;
    }

    function getBytes32(bytes32 slot) internal view returns (bytes32 _bytes32) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            _bytes32 := sload(slot)
        }
    }

    function getUInt256(bytes32 slot) internal view returns (uint256 _uint) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            _uint := sload(slot)
        }
    }

    function setAddress(bytes32 slot, address _address) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, _address)
        }
    }

    function setBytes32(bytes32 slot, bytes32 _bytes32) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, _bytes32)
        }
    }

    /// @dev Set a boolean storage variable in a given slot
    /// @dev Convert to a uint to take up an entire contract storage slot
    function setBoolean(bytes32 slot, bool _bool) internal {
        uint256 bool_ = _bool ? 1 : 0;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, bool_)
        }
    }

    function setUInt256(bytes32 slot, uint256 _uint) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, _uint)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity 0.7.6;

library Structs {
    struct RewarderUpdate {
        address rewarder;
        uint256 amount;
        bool isIncrease;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IYetiCompounderStorage {
    function yeti() external view returns (address);

    function crvYusdPool() external view returns (address);

    function farm() external view returns (address);

    function veYeti() external view returns (address);

    function veYetiEmissions() external view returns (address);

    function boostPercentage() external view returns (uint256);

    function usdcBalance() external view returns (uint256);

    function usdtBalance() external view returns (uint256);

    function usdcRewards() external view returns (uint256);

    function usdtRewards() external view returns (uint256);
}
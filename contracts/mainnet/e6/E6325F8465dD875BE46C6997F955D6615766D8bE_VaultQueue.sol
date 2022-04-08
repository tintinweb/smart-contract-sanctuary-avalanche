// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import {
    Initializable
} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {
    OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {
    ReentrancyGuardUpgradeable
} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ISAVAX} from "../interfaces/ISAVAX.sol";
import {IRibbonVault, IDepositContract} from "../interfaces/IRibbon.sol";
import {ICRV} from "../interfaces/ICRV.sol";
import {Vault} from "../libraries/Vault.sol";
import {DSMath} from "../vendor/DSMath.sol";

contract VaultQueue is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    enum TransferAction {INTERVAULT, WITHDRAW}
    struct Transfer {
        address creditor;
        address dstVault;
        address depositContract;
        uint32 timestamp;
        uint256 amount;
        TransferAction action;
    }

    using SafeERC20 for IERC20;

    mapping(address => Transfer[]) public qTransfer;
    mapping(address => uint256) public totalAmount;

    address public immutable WETH_VAULT;
    address public immutable STETH_VAULT;
    uint256 public queueSize;

    event Disburse(address vault, Transfer txn, uint256 portion);

    constructor(address _wethVault, address _stethVault) {
        WETH_VAULT = _wethVault; // Can be the native vault (weth or wavax)
        STETH_VAULT = _stethVault; // Must ONLY be steth vault.  (savax vault returns erc20, set as keeper)
        queueSize = 32;
    }

    function initialize() external initializer {
        __ReentrancyGuard_init();
        __Ownable_init();

        transferOwnership(msg.sender);
    }

    function getInterVaultBalance(address vault)
        private
        view
        returns (uint256 balance)
    {
        // Case 1. stETH - Withdrawing gives stETH
        // Case 2. WETH - Withdrawing gives ETH
        // Case 3. erc20 token
        if (vault == STETH_VAULT) {
            address steth = IRibbonVault(vault).STETH();
            balance = IERC20(steth).balanceOf(address(this));
        } else if (vault == WETH_VAULT) {
            balance = address(this).balance;
        } else {
            Vault.VaultParams memory vaultParams =
                IRibbonVault(vault).vaultParams();
            balance = IERC20(vaultParams.asset).balanceOf(address(this));
        }
    }

    function withdrawToCreditor(
        address vault,
        address creditor,
        uint256 portion
    ) private {
        if (vault == STETH_VAULT) {
            address steth = IRibbonVault(vault).STETH();
            IERC20(steth).transfer(creditor, portion);
        } else if (vault == WETH_VAULT) {
            (bool sent, ) = creditor.call{value: portion}("");
            require(sent, "Failed to withdraw to creditor");
        } else {
            Vault.VaultParams memory vaultParams =
                IRibbonVault(vault).vaultParams();
            IERC20(vaultParams.asset).transfer(creditor, portion);
        }
    }

    function transferToVault(
        address depositContract,
        address creditor,
        uint256 portion
    ) private {
        IDepositContract(depositContract).depositFor{value: portion}(creditor);
    }

    function disburse(address vault) private {
        uint256 balance = getInterVaultBalance(vault);
        uint256 len = qTransfer[vault].length;
        uint256 totalAmt = totalAmount[vault];
        totalAmount[vault] = 0;

        for (uint256 j = len; j > 0; j--) {
            Transfer memory queue = pop(qTransfer[vault]);

            uint256 portion =
                DSMath.wmul(balance, DSMath.wdiv(queue.amount, totalAmt));
            if (portion > 0) {
                if (queue.action == TransferAction.INTERVAULT) {
                    transferToVault(
                        queue.depositContract,
                        queue.creditor,
                        portion
                    );
                } else if (queue.action == TransferAction.WITHDRAW) {
                    withdrawToCreditor(vault, queue.creditor, portion);
                }
                emit Disburse(vault, queue, portion);
            }
        }
    }

    function transfer(address vault) external onlyOwner nonReentrant {
        uint256 withdrawals =
            IRibbonVault(vault).withdrawals(address(this)).shares;
        if (withdrawals > 0) {
            if (vault == STETH_VAULT) {
                IRibbonVault(vault).completeWithdraw(0);
                disburse(vault);
            } else {
                IRibbonVault(vault).completeWithdraw();
                disburse(vault);
            }
        }
    }

    function queueTransfer(
        address srcVault,
        address dstVault,
        address depositContract,
        TransferAction transferAction,
        uint256 amount
    ) external nonReentrant {
        require(
            !hasWithdrawal(srcVault, msg.sender),
            "Withdraw already submitted"
        );
        require(qTransfer[srcVault].length < queueSize, "Transfer queue full");

        if (transferAction == TransferAction.INTERVAULT) {
            require(depositContract != address(0), "No deposit contract");
        } else if (transferAction == TransferAction.WITHDRAW) {
            // depositContract is not used on withdraw, so let's set it to msg.sender
            require(
                depositContract == msg.sender,
                "On withdraw, depositContract must be msg.sender"
            );
        }

        IRibbonVault(srcVault).transferFrom(msg.sender, address(this), amount);

        IRibbonVault(srcVault).initiateWithdraw(amount);

        qTransfer[srcVault].push(
            Transfer(
                msg.sender,
                dstVault,
                depositContract,
                uint32(block.timestamp),
                amount,
                transferAction
            )
        );
        totalAmount[srcVault] += amount;
    }

    function hasWithdrawal(address vault, address user)
        public
        view
        returns (bool)
    {
        for (uint256 j = 0; j < qTransfer[vault].length; ++j) {
            if (user == qTransfer[vault][j].creditor) {
                return true;
            }
        }
        return false;
    }

    function setQueueSize(uint256 _queueSize) external onlyOwner {
        queueSize = _queueSize;
    }

    function pop(Transfer[] storage array) private returns (Transfer memory) {
        Transfer memory item = array[array.length - 1];
        array.pop();
        return item;
    }

    modifier onlyVault {
        require(
            msg.sender == WETH_VAULT || msg.sender == STETH_VAULT,
            "Invalid sender"
        );
        _;
    }

    receive() external payable onlyVault {}
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
pragma solidity ^0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISAVAX is IERC20 {
    function getSharesByPooledAvax(uint256 avaxAmount)
        external
        view
        returns (uint256);

    function getPooledAvaxByShares(uint256 shareAmount)
        external
        view
        returns (uint256);

    function submit() external payable returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;
import {Vault} from "../libraries/Vault.sol";

interface IRibbonVault {
    function deposit(uint256 amount) external;

    function depositETH() external payable;

    function cap() external view returns (uint256);

    function WETH() external view returns (address);

    function withdrawals(address)
        external
        view
        returns (Vault.Withdrawal memory);

    function depositFor(uint256 amount, address creditor) external;

    function depositFor(address creditor) external payable;

    function vaultParams() external view returns (Vault.VaultParams memory);

    function completeWithdraw() external;

    function initiateWithdraw(uint256 numShares) external;

    function redeem(uint256 numShares) external;

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    // STETH
    function STETH() external view returns (address);

    function collateralToken() external view returns (address);

    function completeWithdraw(uint256 minAmountOut) external;
}

interface IStrikeSelection {
    function getStrikePrice(uint256 expiryTimestamp, bool isPut)
        external
        view
        returns (uint256, uint256);

    function delta() external view returns (uint256);
}

interface IOptionsPremiumPricer {
    function getPremium(
        uint256 strikePrice,
        uint256 timeToExpiry,
        bool isPut
    ) external view returns (uint256);

    function getPremiumInStables(
        uint256 strikePrice,
        uint256 timeToExpiry,
        bool isPut
    ) external view returns (uint256);

    function getOptionDelta(
        uint256 spotPrice,
        uint256 strikePrice,
        uint256 volatility,
        uint256 expiryTimestamp
    ) external view returns (uint256 delta);

    function getUnderlyingPrice() external view returns (uint256);

    function priceOracle() external view returns (address);

    function volatilityOracle() external view returns (address);

    function optionId() external view returns (bytes32);
}

interface IDepositContract {
    function depositFor(address recipient) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

interface ICRV {
    function get_dy(
        int128 _indexIn,
        int128 _indexOut,
        uint256 _amountIn
    ) external view returns (uint256);

    // https://github.com/curvefi/curve-contract/blob/
    // b0bbf77f8f93c9c5f4e415bce9cd71f0cdee960e/contracts/pools/steth/StableSwapSTETH.vy#L431
    function exchange(
        int128 _indexIn,
        int128 _indexOut,
        uint256 _amountIn,
        uint256 _minAmountOut
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

library Vault {
    /************************************************
     *  IMMUTABLES & CONSTANTS
     ***********************************************/

    // Fees are 6-decimal places. For example: 20 * 10**6 = 20%
    uint256 internal constant FEE_MULTIPLIER = 10**6;

    // Premium discount has 1-decimal place. For example: 80 * 10**1 = 80%. Which represents a 20% discount.
    uint256 internal constant PREMIUM_DISCOUNT_MULTIPLIER = 10;

    // Otokens have 8 decimal places.
    uint256 internal constant OTOKEN_DECIMALS = 8;

    // Percentage of funds allocated to options is 2 decimal places. 10 * 10**2 = 10%
    uint256 internal constant OPTION_ALLOCATION_MULTIPLIER = 10**2;

    // Placeholder uint value to prevent cold writes
    uint256 internal constant PLACEHOLDER_UINT = 1;

    struct VaultParams {
        // Option type the vault is selling
        bool isPut;
        // Token decimals for vault shares
        uint8 decimals;
        // Asset used in Theta / Delta Vault
        address asset;
        // Underlying asset of the options sold by vault
        address underlying;
        // Minimum supply of the vault shares issued, for ETH it's 10**10
        uint56 minimumSupply;
        // Vault cap
        uint104 cap;
    }

    struct OptionState {
        // Option that the vault is shorting / longing in the next cycle
        address nextOption;
        // Option that the vault is currently shorting / longing
        address currentOption;
        // The timestamp when the `nextOption` can be used by the vault
        uint32 nextOptionReadyAt;
    }

    struct VaultState {
        // 32 byte slot 1
        //  Current round number. `round` represents the number of `period`s elapsed.
        uint16 round;
        // Amount that is currently locked for selling options
        uint104 lockedAmount;
        // Amount that was locked for selling options in the previous round
        // used for calculating performance fee deduction
        uint104 lastLockedAmount;
        // 32 byte slot 2
        // Stores the total tally of how much of `asset` there is
        // to be used to mint rTHETA tokens
        uint128 totalPending;
        // Amount locked for scheduled withdrawals;
        uint128 queuedWithdrawShares;
    }

    struct DepositReceipt {
        // Maximum of 65535 rounds. Assuming 1 round is 7 days, maximum is 1256 years.
        uint16 round;
        // Deposit amount, max 20,282,409,603,651 or 20 trillion ETH deposit
        uint104 amount;
        // Unredeemed shares balance
        uint128 unredeemedShares;
    }

    struct Withdrawal {
        // Maximum of 65535 rounds. Assuming 1 round is 7 days, maximum is 1256 years.
        uint16 round;
        // Number of shares withdrawn
        uint128 shares;
    }

    struct AuctionSellOrder {
        // Amount of `asset` token offered in auction
        uint96 sellAmount;
        // Amount of oToken requested in auction
        uint96 buyAmount;
        // User Id of delta vault in latest gnosis auction
        uint64 userId;
    }
}

// SPDX-License-Identifier: MIT

/// math.sol -- mixin for inline numerical wizardry

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >0.4.13;

library DSMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x >= y ? x : y;
    }

    function imin(int256 x, int256 y) internal pure returns (int256 z) {
        return x <= y ? x : y;
    }

    function imax(int256 x, int256 y) internal pure returns (int256 z) {
        return x >= y ? x : y;
    }

    uint256 constant WAD = 10**18;
    uint256 constant RAY = 10**27;

    //rounds to zero if x*y < WAD / 2
    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    //rounds to zero if x*y < WAD / 2
    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    //rounds to zero if x*y < WAD / 2
    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    //rounds to zero if x*y < RAY / 2
    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
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
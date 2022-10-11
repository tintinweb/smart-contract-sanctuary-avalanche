// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.10;

import {IStrategy} from "../interfaces/IStrategy.sol";
import {IYetiVaultToken} from "../interfaces/IYetiVaultToken.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {IAAVEV3} from "../interfaces/IAAVE.sol";

/**
 * Handles the deposit and withdraw functionality in the Aave USDC strategy for the PSM.
 */

contract aUSDCPSMStrategy is IStrategy, Ownable {

    uint256 internal constant MAX_UINT = type(uint).max;

    IERC20 public constant USDC = IERC20(0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E);
    IYetiVaultToken public constant vaultStrategy = IYetiVaultToken(0xAD69de0CE8aB50B729d3f798d7bC9ac7b4e79267);
    IERC20 public constant underlying = IERC20(0x625E7708f30cA75bfd92586e17077590C60eb4cD);
    address public constant aaveLendingPoolV3 = 0x794a61358D6845594F94dc1DB02A252b5b4814aD;

    address public immutable PSM;

    constructor(address _psm) public {
        transferOwnership(_psm);
        PSM = _psm;
        // Approve aave lending pool to convert USDC to aUSDC
        USDC.approve(address(aaveLendingPoolV3), MAX_UINT);
        // Approve strategy (YaV3USDC strategy) to convert aUSDC to yeti vault aUSDC
        underlying.approve(address(vaultStrategy), MAX_UINT);
    }

    /// Deposit USDC into the strategy from the PSM
    function deposit(uint256 _depositAmount) external override onlyOwner returns (uint256) {
        if(_depositAmount != 0) {
            USDC.transferFrom(PSM, address(this), _depositAmount);
            uint256 resultingAmount = swapAAVEToken(_depositAmount, false);
            uint256 actualAmountToDeposit = _min(resultingAmount, underlying.balanceOf(address(this)));
            return vaultStrategy.deposit(actualAmountToDeposit);
        }
    }

    /// Withdraw USDC from the strategy from the PSM
    function withdraw(uint256 _withdrawAmountInUSDC) external override onlyOwner returns (uint256) {
        if (_withdrawAmountInUSDC != 0) {
            uint256 withdrawAmountInVault = _withdrawAmountInUSDC * (vaultStrategy.receiptPerUnderlying()) / (1e18);
            uint256 amount_vault_aUSDC = _min(withdrawAmountInVault, IERC20(address(vaultStrategy)).balanceOf(address(this)));
            uint256 resultingAmountInUSDC = vaultStrategy.withdraw(amount_vault_aUSDC);
            uint256 amount_aUSDC = _min(resultingAmountInUSDC, underlying.balanceOf(address(this)));
            uint256 resultingAmountInUSDC2 = swapAAVEToken(amount_aUSDC, true);
            uint256 amountUSDCToTransferFinal = _min(resultingAmountInUSDC2, USDC.balanceOf(address(this)));
            USDC.transfer(PSM, amountUSDCToTransferFinal);
            return amountUSDCToTransferFinal;
        }
    }

    /// Total amount of USDC the contract owns. 
    function totalHoldings() external view override returns (uint256 USDCBalance) {
        uint256 balance = IERC20(address(vaultStrategy)).balanceOf(address(this));
        uint256 underlyingPerReceipt = vaultStrategy.underlyingPerReceipt();
        USDCBalance = balance * (underlyingPerReceipt) / (1e18);
    }

    // Deposits or withdraws from aUSDC token
    function swapAAVEToken(
        uint256 _amount,
        bool _AaveIn
    ) internal returns (uint256) {
        if (_AaveIn) {
                // Swap Aave for _token
                _amount = IAAVEV3(aaveLendingPoolV3).withdraw(
                    address(USDC),
                    _amount,
                    address(this)
                );
                return _amount;
            } else {
                // Swap _token for Aave
                IAAVEV3(aaveLendingPoolV3).supply(address(USDC), _amount, address(this), 0);
                return _amount;
            }
    }

    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

// Interface for a USDC strategy, which has permissioned deposit 
// and withdraw functions and is only meant to interact with one 
// address. Used by Yeti Finance to earn yield on the USDC minted
// from the PSM.
// Deposit and withdraw functions must be onlyPSM. 
interface IStrategy {
    function deposit(uint256 _depositAmount) external returns (uint256 _amount);
    function withdraw(uint256 _withdrawAmount) external returns (uint256 _amount);
    function totalHoldings() external view returns (uint256 _amount);
}

pragma solidity 0.8.10;

/** 
 * @notice Interface for use of wrapping and unwrapping vault tokens in the Yeti Finance borrowing 
 * protocol. 
 */
interface IYetiVaultToken {
    function deposit(uint256 _amt) external returns (uint256 receiptTokens);
    function depositFor(address _borrower, uint256 _amt) external returns (uint256 receiptTokens);
    function redeem(uint256 _amt) external returns (uint256 underlyingTokens);
    function redeemFor(
        uint256 _amt,
        address _from,
        address _to
    ) external returns (uint256 underlyingTokens);
    function withdraw(uint256 _amt) external returns (uint256 underlyingTokens);
    function underlyingPerReceipt() external view returns (uint256);
    function receiptPerUnderlying() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * Based on the OpenZeppelin IER20 interface:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
 *
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
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

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

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
}

pragma solidity ^0.8.0;

interface IAAVE {
    function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);
}

interface IAAVEV3 {
    function supply(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
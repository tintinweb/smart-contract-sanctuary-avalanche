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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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

// SPDX-License-Identifier: AGPL-3.0

/* 
    NOTICE: 
    This contract is in beta and is supplied for testing purposes only. 
    It has not been audited for security vulnerabilities and may be superseded at any time. 
    Assume any funds deposited will be lost.
*/

pragma solidity 0.8.10;

import {QiTokenInterface} from "./interfaces/benqi/QiTokenCustomInterfaces.sol";
import {ISafeBox} from "./interfaces/alpha/ISafeBox.sol";
import {ICErc20} from "./interfaces/alpha/ICErc20.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {ERC20Strategy} from "./interfaces/Strategies/Strategy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract LowRiskStrategy is
    ERC20("Emigro Low Risk Strategy", "ELRS", 6),
    ERC20Strategy,
    Ownable,
    Pausable
{
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    ERC20 internal immutable UNDERLYING;
    uint256 internal immutable BASE_UNIT;

    /// @dev Benqi QiTokenInterface
    QiTokenInterface public immutable qiToken;

    /// @dev Alpha finance SafeBox
    ISafeBox public ibToken;

    /// @dev Alpha finance SafeBox cToken
    ICErc20 public cToken;

    /// @dev Flags to determin which tactic is currently active
    bool public alphaTacticIsActive;
    bool public benqiTacticIsActive;

    //Events
    event BenqiDeposit(
        address indexed accountAddress,
        uint256 uTokenAmount,
        uint256 qiTokensReturned
    );
    event BenqiWithdrawal(
        address indexed userAddress,
        uint256 qiTokensAmount,
        uint256 uTokensReturned
    );
    event AlphaDeposit(
        address indexed accountAddress,
        uint256 uTokenAmount,
        uint256 ibTokensReturned
    );
    event AlphaWithdrawal(
        address indexed userAddress,
        uint256 ibTokenAmount,
        uint256 uTokensReturned
    );
    event TacticActivated(string tacticName);
    event TacticsBalance();

    constructor(
        ERC20 _UNDERLYING,
        address qiTokenContract,
        address alphaSafeBoxContract
    ) {
        UNDERLYING = _UNDERLYING;
        BASE_UNIT = 10**_UNDERLYING.decimals();
        qiToken = QiTokenInterface(qiTokenContract);
        ibToken = ISafeBox(alphaSafeBoxContract);
        cToken = ICErc20(ibToken.cToken());

        //set the active tactic ready for first deposit
        setActiveTacticBySupplyRate();
    }

    function isCEther() external pure override returns (bool) {
        return false;
    }

    function underlying() external view override returns (ERC20) {
        return UNDERLYING;
    }

    /// @notice Mints strategy tokens for an amount in underlying and deposits underlying into the highest yield tactic
    /// @dev Called by vault when it receives a deposit
    /// @param underlyingAmount qty of underlying tokens receieved
    /// @return uint256 0 = pass
    function mint(uint256 underlyingAmount) 
        external 
        override 
        whenNotPaused 
        returns (uint256) 
    {
        uint256 shares;
        _mint(msg.sender, shares = calculateShares(underlyingAmount));

        // transfer tokens to contract from sender
        UNDERLYING.safeTransferFrom(msg.sender, address(this), underlyingAmount);

        //Make sure we're depositing to the active tactic
        require(benqiTacticIsActive || alphaTacticIsActive, "no tactic active");
        //route desposit
        if (benqiTacticIsActive) {
            depositBenqiERC20(underlyingAmount);
        } else if (alphaTacticIsActive) {
            depositAlphaERC20(underlyingAmount);
        }
        return 0;
    }

    //WITHDRAWAL LOGIC

    /// @notice Redeems strategy shares for underlying held by tactics
    /// @param amountStrategyTokens qty of strategy tokens to redeem
    /// @return uint256 0 = pass, withdrawnUTokens
    function redeemUnderlying(uint256 amountStrategyTokens)
        external
        override
        whenNotPaused 
        returns (uint256, uint256)
    {
        //route desposit
        require(benqiTacticIsActive || alphaTacticIsActive, "no tactic active");

        uint256 withdrawnUTokens;
        uint256 redemptionAmount;

        //redemptionAmount = strategy tokens to redeem / total supply of strategy tokens * tactic tokens held by this strategy
        if (benqiTacticIsActive) {
            redemptionAmount = (amountStrategyTokens.fdiv(totalSupply, BASE_UNIT)).fmul(qiToken.balanceOf(address(this)),BASE_UNIT);
            withdrawnUTokens = withdrawBenqiERC20(redemptionAmount);
        } else if (alphaTacticIsActive) {
            redemptionAmount = (amountStrategyTokens.fdiv(totalSupply, BASE_UNIT)).fmul(ibToken.balanceOf(address(this)),BASE_UNIT);
            withdrawnUTokens = withdrawAlphaERC20(redemptionAmount);
        }

        //burn the strategy tokens being redeemed
        _burn(msg.sender, amountStrategyTokens);

        //transfer the proceeds
        UNDERLYING.safeTransfer(msg.sender, withdrawnUTokens);

        return (0, withdrawnUTokens);
    }

    /// @notice Deposit ERC20 uToken into Benqi QI token contract, get back qiTokens
    /// @param underlyingAmount qty of underlying tokens to deposit
    //  TODO: Consider renaming to mintBenqi()
    function depositBenqiERC20(uint256 underlyingAmount) internal {
        //Approve underlying for spend by benqi
        UNDERLYING.approve(address(qiToken), underlyingAmount);

        //Deposit to benqi and calculate change in cToken balance to determine what we got back
        uint256 qiTokenBalanceBefore = qiToken.balanceOf(address(this));
        require(qiToken.mint(underlyingAmount) == 0, "mint failed");
        uint256 qiTokenBalanceAfter = qiToken.balanceOf(address(this));
        uint256 qiTokensReturned = qiTokenBalanceAfter - qiTokenBalanceBefore;

        emit BenqiDeposit(msg.sender, underlyingAmount, qiTokensReturned);
    }

    /// @notice Reedem Benqi qiTokens for underlying
    /// @param qiTokenAmount qty of qiTokens to redeem
    //  TODO: Consider renaming to redeemBenqi()
    function withdrawBenqiERC20(uint256 qiTokenAmount) internal returns (uint256) {
        require(qiTokenAmount > 0, "amount is zero");

        uint256 uBalanceBefore = UNDERLYING.balanceOf(address(this));
        require(qiToken.redeem(qiTokenAmount) == 0, "redeem failed");
        uint256 uBalanceAfter = UNDERLYING.balanceOf(address(this));
        uint256 uTokensReturned = uBalanceAfter - uBalanceBefore;

        emit BenqiWithdrawal(msg.sender, qiTokenAmount, uTokensReturned);
        return uTokensReturned;
    }

    /// @notice Deposit ERC20 underlying into Alpha Safebox, get back ibTokens
    /// @param underlyingAmount qty of underlying tokens to deposit
    //  TODO: Consider renaming to mintAlpha()
    function depositAlphaERC20(uint256 underlyingAmount) internal {
        require(underlyingAmount > 0, "desposit amount must be greater than 0");

        //Approve underlying for spend by alpha
        UNDERLYING.approve(address(ibToken), underlyingAmount);

        //Deposit to safebox and calculate change in ibToken balance to determine what we got back
        uint256 ibTokenBalanceBefore = ibToken.balanceOf(address(this));
        ibToken.deposit(underlyingAmount);
        uint256 ibTokenBalanceAfter = ibToken.balanceOf(address(this));
        uint256 ibTokensReturned = ibTokenBalanceAfter - ibTokenBalanceBefore;

        emit AlphaDeposit(msg.sender, underlyingAmount, ibTokensReturned);
    }

    /// @notice Reedem Alpha ibTokens for underlying
    /// @param ibTokenAmount qty of qiTokens to redeem
    //  TODO: Consider renaming to redeemAlpha()
    function withdrawAlphaERC20(uint256 ibTokenAmount) internal returns (uint256) {
        require(ibTokenAmount > 0, "amount is zero");

        uint256 uBalanceBefore = UNDERLYING.balanceOf(address(this));
        ibToken.withdraw(ibTokenAmount);
        uint256 uBalanceAfter = UNDERLYING.balanceOf(address(this));
        uint256 uTokensReturned = uBalanceAfter - uBalanceBefore;

        emit AlphaWithdrawal(msg.sender, ibTokenAmount, uTokensReturned);
        return uTokensReturned;
    }

    //ADMIN LOGIC

    /// @notice Get the contract address of the active tactic
    /// @return IERC20 address
    function activeTacticContract() external view returns (address) {
        require(benqiTacticIsActive || alphaTacticIsActive, "no tactic active");
        if (benqiTacticIsActive) {
            return address(qiToken);
        } else if (alphaTacticIsActive) {
            return address(cToken);
        }
        return address(0);
    }

    /// @notice Internal function that marks which tactic is currently active based on supply rate
    /// @dev used for directing next deposit, balancing actions
    function setActiveTacticBySupplyRate() internal {
        if (getAlphaCurrentSupplyRate() > getBenqiCurrentSupplyRate()) {
            alphaTacticIsActive = true;
            benqiTacticIsActive = false;
            emit TacticActivated("alpha");
        } else {
            alphaTacticIsActive = false;
            benqiTacticIsActive = true;
            emit TacticActivated("benqi");
        }
    }

    /// @notice Get the supply rate of the  active tactic
    /// @return Supply rate per second as mantissa
    function supplyRate() public view returns (uint256) {
        require(benqiTacticIsActive || alphaTacticIsActive, "no tactic active");
        if (benqiTacticIsActive) {
            return getBenqiCurrentSupplyRate();
        } else if (alphaTacticIsActive) {
            return getAlphaCurrentSupplyRate();
        }
        return 0;
    }

    /// @notice Get benqi current supply interest rate
    /// @dev To calculate APY compound per second for one year. See tests or https://compound.finance/docs#protocol-math
    /// @return Returns the current per-timestamp supply interest rate for this ibTokens underlying cToken
    //  TODO: May not be necessary if not required externally
    function getAlphaCurrentSupplyRate() public view returns (uint256) {
        //naming implies per block but result appears to be per timestamp
        return cToken.supplyRatePerBlock();
    }

    /// @notice Get the latest alpha cached exchange rate without modifying state
    /// @dev Calls functions on the ibTokens underlying cToken
    /// @return Returns mantissa
    //  TODO: May not be necessary if not required externally
    function getAlphaExchangeRateStored() public view returns (uint256) {
        return cToken.exchangeRateStored();
    }

    /// @notice Get benqi current supply interest rate
    /// @dev To calculate APY compound per second for one year. See tests or https://compound.finance/docs#protocol-math
    /// @return Returns the current per-timestamp supply interest rate for this qiToken
    //  TODO: May not be necessary if not required externally
    function getBenqiCurrentSupplyRate() public view returns (uint256) {
        return qiToken.supplyRatePerTimestamp();
    }

    /// @notice Get the latest benqi cached exchange rate without modifying state
    /// @return Returns mantissa
    //  TODO: May not be necessary if not required externally
    function getBenqiExchangeRateStored() public view returns (uint256) {
        return qiToken.exchangeRateStored();
    }

    /// @notice Balance funds into most profitable tactic based on current supply rates
    /// @dev Could be called by a keeper, or possible chained into a user call
    function balanceTactics() 
        external
        whenNotPaused 
    {
        uint256 alphaSupplyRate = getAlphaCurrentSupplyRate();
        uint256 benqiSupplyRate = getBenqiCurrentSupplyRate();
        uint256 qiTokenBalance = qiToken.balanceOf(address(this));
        uint256 ibTokenBalance = ibToken.balanceOf(address(this));

        //if we have tokens that are not in the highest yield tactic, move them
        if (alphaSupplyRate > benqiSupplyRate) {
            //if there are there funds to move withdraw from benqi and deposit all we have into alpha
            if (qiTokenBalance > 0) {
                withdrawBenqiERC20(qiTokenBalance);
                depositAlphaERC20(UNDERLYING.balanceOf(address(this)));
            }
        } else if (benqiSupplyRate > alphaSupplyRate) {
            //if there are there funds to move withdraw from alpha and deposit all we have into benqi
            if (ibTokenBalance > 0) {
                withdrawAlphaERC20(ibTokenBalance);
                depositBenqiERC20(UNDERLYING.balanceOf(address(this)));
            }
        }
        //there is a case where the two rates are equal, then do nothing

        //set active tactics for subsequent deposits
        setActiveTacticBySupplyRate();

        emit TacticsBalance();
    }

    /// @notice Estimate the balance of the current user in underlying tokens
    /// @dev Relies on stored exchage rates
    /// @param user address to look up
    function balanceOfUnderlying(address user)
        external
        view
        override
        returns (uint256)
    {
        return balanceOf[user].fmul(exchangeRate(), BASE_UNIT);
    }

    /// @notice Calculate what each strategy token is worth based on the value of its tactics in underlying
    /// @dev Relies on tactics stored exchange rates
    /// @return the exchange rate from strategy token for underlying
    function exchangeRate() public view returns (uint256) {
        uint256 strategyTokenSupply = totalSupply;
        if (strategyTokenSupply == 0) return BASE_UNIT;

        return
            //total value in underlying / total strategy tokens
            totalHoldings().fdiv(strategyTokenSupply, BASE_UNIT);
    }

    /// @notice Estimates the total amount of underlying tokens the Strategy holds.
    /// @dev Relies on the tactics stored exchange rates. Use of current rates requires gas consuming transaction.
    /// @return value of all tactic tokens held in underlying
    function totalHoldings() public view returns (uint256) {
        uint256 qiTokenValue = qiToken.balanceOf(address(this)).fmul(getBenqiExchangeRateStored(), BASE_UNIT) / 10**12;
        uint256 ibTokenValue = ibToken.balanceOf(address(this)).fmul(getAlphaExchangeRateStored(), BASE_UNIT) / 10**12;
        uint256 totalUnderlyingValue = qiTokenValue + ibTokenValue;
        return totalUnderlyingValue;
    }

    /// @notice Calculates the number of strategy shares/tokens to mint
    /// @param underlyingAmount underlying tokens deposited
    /// @return uint256 qty of shares/tokens to mint
    function calculateShares(uint256 underlyingAmount) public view virtual returns (uint256) {
        uint256 strategyTokenSupply = totalSupply;
        if (strategyTokenSupply == 0) return BASE_UNIT;

        //new shares to mint = (usdce deposit amt * total vault tokens) / ((vault strat tokens / total strat tokens) x ((tactic a tokens x ex rate) + (tactic b tokens x ex rate)))
        uint256 shares = underlyingAmount.fmul(strategyTokenSupply, BASE_UNIT).fdiv(totalHoldings(), BASE_UNIT);

        return shares;
    }

    //Administrative functions
    
    /// @notice Locks contract in case of issue
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Unlocks contract once issue is resolved
    function unpause() public onlyOwner {
        _unpause();
    }

    // Temporary functions to support beta testing scenarios
    
    /// @notice Manually change active tactic to Benqi
    /// @dev Flip between active tactics for testing balancing function
    function setActiveTacticBenqi() 
        external 
        onlyOwner 
        whenNotPaused 
    {
        alphaTacticIsActive = false;
        benqiTacticIsActive = true;
    }

    /// @notice Manually change active tactic to Alpha
    /// @dev Flip between active tactics for testing balancing function
    function setActiveTacticAlpha() 
        external 
        onlyOwner 
        whenNotPaused 
    {
        alphaTacticIsActive = true;
        benqiTacticIsActive = false;
    }

    /// @notice Withdraw full balance of a given token from strategy to owner in case of issue, accidental transfer, upgrade
    /// @dev Must be called by owner
    function withdraw(address token) 
        external 
        onlyOwner
    {
        //token is native
        if (token == address(0)) {
            (bool sent, ) = payable(owner()).call{value: address(this).balance}("");
            require(sent, "Failed to send avax");
            return;
        }

        //token is ERC20
        ERC20(token).safeTransfer(owner(), ERC20(token).balanceOf(address(this)));
    }

    /// @notice Test function for comparing stored and current rates for Benqi
    /// @dev Stored rate is a view function an the value is updated on state changing interactions with benqi incl borrow, lend.
    /// @dev Current rate is a non-payable (gas incurring) function that triggers accrual of interest at benqi, thus updating the rate for the current time stamp
    /* function benqiCompareRates() public {
        uint256 qiTokenValueStored = qiToken.balanceOf(address(this)).fmul(qiToken.exchangeRateStored(), BASE_UNIT)  / 10**12;
        console.log("qiTokenValueStored", qiTokenValueStored);
        console.log("qiToken.exchangeRateStored()", qiToken.exchangeRateStored());

        uint256 qiTokenValueCurrent = qiToken.balanceOf(address(this)).fmul(qiToken.exchangeRateCurrent(), BASE_UNIT) / 10**12;
        console.log("qiTokenValueCurrent", qiTokenValueCurrent);
        console.log("qiToken.exchangeRateCurrent()", qiToken.exchangeRateCurrent());
    } */

    
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {ERC20} from "solmate/tokens/ERC20.sol";

/// @notice Minimal interface for Vault compatible strategies.
/// @dev Designed for out of the box compatibility with Fuse cTokens.
/// @dev Like cTokens, strategies must be transferrable ERC20s.
abstract contract Strategy is ERC20 {
    /// @notice Returns whether the strategy accepts ETH or an ERC20.
    /// @return True if the strategy accepts ETH, false otherwise.
    /// @dev Only present in Fuse cTokens, not Compound cTokens.
    function isCEther() external view virtual returns (bool);

    /// @notice Withdraws a specific amount of underlying tokens from the strategy.
    /// @param amount The amount of underlying tokens to withdraw.
    /// @return An error code, or 0 if the withdrawal was successful.
    function redeemUnderlying(uint256 amount) external virtual returns (uint256, uint256);

    /// @notice Returns a user's strategy balance in underlying tokens.
    /// @param user The user to get the underlying balance of.
    /// @return The user's strategy balance in underlying tokens.
    /// @dev May mutate the state of the strategy by accruing interest.
    function balanceOfUnderlying(address user) external virtual returns (uint256);
}

/// @notice Minimal interface for Vault strategies that accept ERC20s.
/// @dev Designed for out of the box compatibility with Fuse cERC20s.
abstract contract ERC20Strategy is Strategy {
    /// @notice Returns the underlying ERC20 token the strategy accepts.
    /// @return The underlying ERC20 token the strategy accepts.
    function underlying() external view virtual returns (ERC20);

    /// @notice Deposit a specific amount of underlying tokens into the strategy.
    /// @param amount The amount of underlying tokens to deposit.
    /// @return An error code, or 0 if the deposit was successful.
    function mint(uint256 amount) external virtual returns (uint256);
}

/// @notice Minimal interface for Vault strategies that accept ETH.
/// @dev Designed for out of the box compatibility with Fuse cEther.
abstract contract ETHStrategy is Strategy {
    /// @notice Deposit a specific amount of ETH into the strategy.
    /// @dev The amount of ETH is specified via msg.value. Reverts on error.
    function mint() external payable virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

interface ICErc20 {
    function decimals() external view returns (uint8);

    function underlying() external view returns (address);

    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function balanceOf(address user) external view returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function borrowBalanceStored(address account)
        external
        view
        returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function supplyRatePerBlock() external view returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;
import "./ICErc20.sol";

//ERC20 SafeBox, not SafeBoxAVAX which has a different deposit method
interface ISafeBox is ICErc20 {

    function cToken() external returns (ICErc20);

    function deposit(uint amount) external;

    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

interface ComptrollerInterface {
    /// @notice Indicator that this is a Comptroller contract (for inspection)
    //bool public constant isComptroller = true;

    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata qiTokens) external returns (uint[] memory);
    function exitMarket(address qiToken) external returns (uint);

    /*** Policy Hooks ***/

    function mintAllowed(address qiToken, address minter, uint mintAmount) external returns (uint);
    function mintVerify(address qiToken, address minter, uint mintAmount, uint mintTokens) external;

    function redeemAllowed(address qiToken, address redeemer, uint redeemTokens) external returns (uint);
    function redeemVerify(address qiToken, address redeemer, uint redeemAmount, uint redeemTokens) external;

    function borrowAllowed(address qiToken, address borrower, uint borrowAmount) external returns (uint);
    function borrowVerify(address qiToken, address borrower, uint borrowAmount) external;

    function repayBorrowAllowed(
        address qiToken,
        address payer,
        address borrower,
        uint repayAmount) external returns (uint);
    function repayBorrowVerify(
        address qiToken,
        address payer,
        address borrower,
        uint repayAmount,
        uint borrowerIndex) external;

    function liquidateBorrowAllowed(
        address qiTokenBorrowed,
        address qiTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount) external returns (uint);
    function liquidateBorrowVerify(
        address qiTokenBorrowed,
        address qiTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount,
        uint seizeTokens) external;

    function seizeAllowed(
        address qiTokenCollateral,
        address qiTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external returns (uint);
    function seizeVerify(
        address qiTokenCollateral,
        address qiTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external;

    function transferAllowed(address qiToken, address src, address dst, uint transferTokens) external returns (uint);
    function transferVerify(address qiToken, address src, address dst, uint transferTokens) external;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address qiTokenBorrowed,
        address qiTokenCollateral,
        uint repayAmount) external view returns (uint, uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

/**
 * @title EIP20NonStandardInterface
 * @dev Version of ERC20 with no return values for `transfer` and `transferFrom`
 *  See https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
 */
interface EIP20NonStandardInterface {

    /**
     * @notice Get the total number of tokens in circulation
     * @return The supply of tokens
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return balance The balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transfer` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      */
    function transfer(address dst, uint256 amount) external;

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transferFrom` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      */
    function transferFrom(address src, address dst, uint256 amount) external;

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved
      * @return success Whether or not the approval succeeded
      */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return remaining The number of tokens allowed to be spent
      */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;
/**
  * @title Benqi's InterestRateModel Interface
  * @author Benqi
  */
interface InterestRateModel {
    /// @notice Indicator that this is an InterestRateModel contract (for inspection)
    //bool public constant isInterestRateModel = true;

    /**
      * @notice Calculates the current borrow interest rate per timestmp
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amount of reserves the market has
      * @return The borrow rate per timestmp (as a percentage, and scaled by 1e18)
      */
    function getBorrowRate(uint cash, uint borrows, uint reserves) external view returns (uint);

    /**
      * @notice Calculates the current supply interest rate per timestmp
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amount of reserves the market has
      * @param reserveFactorMantissa The current reserve factor the market has
      * @return The supply rate per timestmp (as a percentage, and scaled by 1e18)
      */
    function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactorMantissa) external view returns (uint);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ComptrollerInterface.sol";
import "./InterestRateModel.sol";
import "./EIP20NonStandardInterface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface QiTokenInterface is IERC20 {

    /*** Market Events ***/

    /**
     * @notice Event emitted when interest is accrued
     */
    event AccrueInterest(uint cashPrior, uint interestAccumulated, uint borrowIndex, uint totalBorrows);

    /**
     * @notice Event emitted when tokens are minted
     */
    event Mint(address minter, uint mintAmount, uint mintTokens);

    /**
     * @notice Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint redeemAmount, uint redeemTokens);

    /**
     * @notice Event emitted when underlying is borrowed
     */
    event Borrow(address borrower, uint borrowAmount, uint accountBorrows, uint totalBorrows);

    /**
     * @notice Event emitted when a borrow is repaid
     */
    event RepayBorrow(address payer, address borrower, uint repayAmount, uint accountBorrows, uint totalBorrows);

    /**
     * @notice Event emitted when a borrow is liquidated
     */
    event LiquidateBorrow(address liquidator, address borrower, uint repayAmount, address qiTokenCollateral, uint seizeTokens);


    /*** Admin Events ***/

    /**
     * @notice Event emitted when pendingAdmin is changed
     */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
     * @notice Event emitted when pendingAdmin is accepted, which means admin is updated
     */
    event NewAdmin(address oldAdmin, address newAdmin);

    /**
     * @notice Event emitted when comptroller is changed
     */
    event NewComptroller(ComptrollerInterface oldComptroller, ComptrollerInterface newComptroller);

    /**
     * @notice Event emitted when interestRateModel is changed
     */
    event NewMarketInterestRateModel(InterestRateModel oldInterestRateModel, InterestRateModel newInterestRateModel);

    /**
     * @notice Event emitted when the reserve factor is changed
     */
    event NewReserveFactor(uint oldReserveFactorMantissa, uint newReserveFactorMantissa);

    /**
     * @notice Event emitted when the protocol seize share is changed
     */
    event NewProtocolSeizeShare(uint oldProtocolSeizeShareMantissa, uint newProtocolSeizeShareMantissa);

    /**
     * @notice Event emitted when the reserves are added
     */
    event ReservesAdded(address benefactor, uint addAmount, uint newTotalReserves);

    /**
     * @notice Event emitted when the reserves are reduced
     */
    event ReservesReduced(address admin, uint reduceAmount, uint newTotalReserves);

    /**
     * @notice EIP20 Transfer event
     */
    // event Transfer(address indexed from, address indexed to, uint amount);

    /**
     * @notice EIP20 Approval event
     */
    // event Approval(address indexed owner, address indexed spender, uint amount);

    /**
     * @notice Failure event
     */
    event Failure(uint error, uint info, uint detail);


    /*** User Interface ***/

    function transfer(address dst, uint amount) external returns (bool);
    function transferFrom(address src, address dst, uint amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function balanceOfUnderlying(address owner) external returns (uint);
    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
    function borrowRatePerTimestamp() external view returns (uint);
    function supplyRatePerTimestamp() external view returns (uint);
    function totalBorrowsCurrent() external returns (uint);
    function borrowBalanceCurrent(address account) external returns (uint);
    function borrowBalanceStored(address account) external view returns (uint);
    function exchangeRateCurrent() external returns (uint);
    function exchangeRateStored() external view returns (uint);
    function getCash() external view returns (uint);
    function accrueInterest() external returns (uint);
    function seize(address liquidator, address borrower, uint seizeTokens) external returns (uint);


    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow(uint repayAmount) external returns (uint);
    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);
    function liquidateBorrow(address borrower, uint repayAmount, QiTokenInterface qiTokenCollateral) external returns (uint);
    function sweepToken(EIP20NonStandardInterface token) external;


    /*** Admin Functions ***/

    function _setPendingAdmin(address payable newPendingAdmin) external returns (uint);
    function _acceptAdmin() external returns (uint);
    function _setComptroller(ComptrollerInterface newComptroller) external returns (uint);
    function _setReserveFactor(uint newReserveFactorMantissa) external returns (uint);
    function _reduceReserves(uint reduceAmount) external returns (uint);
    function _setInterestRateModel(InterestRateModel newInterestRateModel) external returns (uint);
    function _setProtocolSeizeShare(uint newProtocolSeizeShareMantissa) external returns (uint);

}

interface QiErc20Interface {

    /*** User Interface ***/

    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow(uint repayAmount) external returns (uint);
    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);
    function liquidateBorrow(address borrower, uint repayAmount, QiTokenInterface qiTokenCollateral) external returns (uint);
    function sweepToken(EIP20NonStandardInterface token) external;


    /*** Admin Functions ***/

    function _addReserves(uint addAmount) external returns (uint);
}


interface QiDelegatorInterface {
    /**
     * @notice Emitted when implementation is changed
     */
    event NewImplementation(address oldImplementation, address newImplementation);

    /**
     * @notice Called by the admin to update the implementation of the delegator
     * @param implementation_ The address of the new implementation for delegation
     * @param allowResign Flag to indicate whether to call _resignImplementation on the old implementation
     * @param becomeImplementationData The encoded bytes data to be passed to _becomeImplementation
     */
    function _setImplementation(address implementation_, bool allowResign, bytes memory becomeImplementationData) external;
}

interface QiDelegateInterface {
    /**
     * @notice Called by the delegator on a delegate to initialize it for duty
     * @dev Should revert if any issues arise which make it unfit for delegation
     * @param data The encoded bytes data for any initialization
     */
    function _becomeImplementation(bytes memory data) external;

    /**
     * @notice Called by the delegator on a delegate to forfeit its responsibility
     */
    function _resignImplementation() external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
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
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

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

    /*///////////////////////////////////////////////////////////////
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
library FixedPointMathLib {
    /*///////////////////////////////////////////////////////////////
                            COMMON BASE UNITS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant YAD = 1e8;
    uint256 internal constant WAD = 1e18;
    uint256 internal constant RAY = 1e27;
    uint256 internal constant RAD = 1e45;

    /*///////////////////////////////////////////////////////////////
                         FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function fmul(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(x == 0 || (x * y) / x == y)
            if iszero(or(iszero(x), eq(div(z, x), y))) {
                revert(0, 0)
            }

            // If baseUnit is zero this will return zero instead of reverting.
            z := div(z, baseUnit)
        }
    }
    
     function fmulUp(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(x == 0 || (x * y) / x == y)
            if iszero(or(iszero(x), eq(div(z, x), y))) {
                revert(0, 0)
            }

            // Compute z + baseUnit - 1.
            let zUp := add(z, sub(baseUnit, 1))

            // If the addition overflowed, revert.
            if lt(zUp, z) {
                revert(0, 0)
            }

            // If baseUnit is zero this will return zero instead of reverting.
            z := div(z, baseUnit)
        }
    }

    function fdiv(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * baseUnit in z for now.
            z := mul(x, baseUnit)

            // Equivalent to require(y != 0 && (x == 0 || (x * baseUnit) / x == baseUnit))
            if iszero(and(iszero(iszero(y)), or(iszero(x), eq(div(z, x), baseUnit)))) {
                revert(0, 0)
            }

            // We ensure y is not zero above, so there is never division by zero here.
            z := div(z, y)
        }
    }

    function fpow(
        uint256 x,
        uint256 n,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := baseUnit
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store baseUnit in z for now.
                    z := baseUnit
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, baseUnit)

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
                    x := div(xxRound, baseUnit)

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
                        z := div(zxRound, baseUnit)
                    }
                }
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
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
                z := shl(64, z)
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z)
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z)
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z)
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z)
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z)
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Gnosis (https://github.com/gnosis/gp-v2-contracts/blob/main/src/contracts/libraries/GPv2SafeERC20.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
library SafeTransferLib {
    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool callStatus;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(callStatus, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 100 because the calldata length is 4 + 32 * 3.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "APPROVE_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function didLastOptionalReturnCallSucceed(bool callStatus) private pure returns (bool success) {
        assembly {
            // Get how many bytes the call returned.
            let returnDataSize := returndatasize()

            // If the call reverted:
            if iszero(callStatus) {
                // Copy the revert message into memory.
                returndatacopy(0, 0, returnDataSize)

                // Revert with the same message.
                revert(0, returnDataSize)
            }

            switch returnDataSize
            case 32 {
                // Copy the return data into memory.
                returndatacopy(0, 0, returnDataSize)

                // Set success to whether it returned true.
                success := iszero(iszero(mload(0)))
            }
            case 0 {
                // There was no return data.
                success := 1
            }
            default {
                // It returned some malformed input.
                success := 0
            }
        }
    }
}
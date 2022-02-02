// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.7;

import "../BaseStrategy.sol";

library DataTypes {
    struct ReserveData {
        ReserveConfigurationMap configuration;
        uint128 liquidityIndex;
        uint128 variableBorrowIndex;
        uint128 currentLiquidityRate;
        uint128 currentVariableBorrowRate;
        uint128 currentStableBorrowRate;
        uint40 lastUpdateTimestamp;
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        address interestRateStrategyAddress;
        uint8 id;
    }
    struct ReserveConfigurationMap {
        uint256 data;
    }
}

interface ILendingPool {
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

    function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);
}

interface IAaveIncentivesController {
    function getRewardsBalance(address[] calldata assets, address user) external view returns (uint256);

    function claimRewards(
        address[] calldata assets,
        uint256 amount,
        address to
    ) external returns (uint256);
}

contract AaveStrategy is BaseStrategy {

    ILendingPool internal immutable aaveLendingPool;
    IAaveIncentivesController internal immutable incentiveController;
    ERC20 public immutable aToken;

    constructor(
        ILendingPool _aaveLendingPool,
        IAaveIncentivesController _incentiveController,
        BaseStrategy.ConstructorParams memory params
    ) BaseStrategy(params)  {
        aaveLendingPool = _aaveLendingPool;
        incentiveController = _incentiveController;
        aToken = ERC20(_aaveLendingPool.getReserveData(address(params.strategyToken)).aTokenAddress);
    }

    function _skim(uint256 amount) internal override {
        strategyToken.approve(address(aaveLendingPool), amount);
        aaveLendingPool.deposit(address(strategyToken), amount, address(this), 0);
    }

    function _harvest(uint256 balance) internal override returns (int256 amountAdded) {
        uint256 currentBalance = aToken.balanceOf(address(this));
        amountAdded = int256(currentBalance) - int256(balance); // Reasonably assume the values won't overflow.
        if (amountAdded > 0) aaveLendingPool.withdraw(address(strategyToken), uint256(amountAdded), address(this));
    }

    function _withdraw(uint256 amount) internal override {
        aaveLendingPool.withdraw(address(strategyToken), amount, address(this));
    }

    function _exit() internal override {
        uint256 tokenBalance = aToken.balanceOf(address(this));
        uint256 available = strategyToken.balanceOf(address(aToken));
        if (tokenBalance <= available) {
            // If there are more tokens available than our full position, take all based on aToken balance (continue if unsuccessful).
            try aaveLendingPool.withdraw(address(strategyToken), tokenBalance, address(this)) {} catch {}
        } else {
            // Otherwise redeem all available and take a loss on the missing amount (continue if unsuccessful).
            try aaveLendingPool.withdraw(address(strategyToken), available, address(this)) {} catch {}
        }
    }

    function _harvestRewards() internal virtual override {
        address[] memory rewardTokens = new address[](1);
        rewardTokens[0] = address(aToken);
        uint256 reward = incentiveController.getRewardsBalance(rewardTokens, address(this));
        incentiveController.claimRewards(rewardTokens, reward, address(this));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.7;

import "./interfaces/IStrategy.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IBentoBoxMinimal.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@rari-capital/solmate/src/utils/SafeTransferLib.sol";

/// @title Abstract contract to simplify BentoBox strategy development.
/// @dev Extend the contract and implement _skim, _harvest, _withdraw, _exit and _harvestRewards methods.
/// Ownership should be transfered to the Sushi ops multisig.
abstract contract BaseStrategy is IStrategy, Ownable {

    using SafeTransferLib for ERC20;

    // invested token.
    ERC20 public immutable strategyToken;
    
    // BentoBox address.
    IBentoBoxMinimal private immutable bentoBox;
    
    // Legacy Sushiswap AMM factory address.
    address private immutable factory;

    // Swap paths (bridges) the original sushiswap AMM.
    // Should lead to the underlying token.
    mapping(address => address) public swapPath;

    // After bentobox 'exits' the strategy harvest and withdraw functions can no longer be called.
    bool private _exited;
    
    // Slippage protection when calling harvest.
    uint256 private _maxBentoBoxBalance;

    // Accounts that can execute methods where slippage protection is required.
    mapping(address => bool) public strategyExecutors;

    event LogSetStrategyExecutor(address indexed executor, bool allowed);
    event LogSetSwapPath(address indexed input, address indexed output);

    error StrategyExited();
    error StrategyNotExited();
    error OnlyBentoBox();
    error OnlyExecutor();
    error NoFactory();
    error SlippageProtection();
    error InvalidSwapPath();
    error NoSwapPath();

    struct ConstructorParams {
        address strategyToken;
        address bentoBox;
        address strategyExecutor;
        address factory;
    }

    /** @param params a ConstructorParam struct whith the following fields:
        strategyToken - Address of the underlying token the strategy invests.
        bentoBox - BentoBox address.
        factory - legacy SushiSwap factory.
        strategyExecutor - initial account that will execute the safeHarvest function. */
    constructor(ConstructorParams memory params) {
        strategyToken = ERC20(params.strategyToken);
        bentoBox = IBentoBoxMinimal(params.bentoBox);
        factory = params.factory;
        strategyExecutors[params.strategyExecutor] = true;
        emit LogSetStrategyExecutor(params.strategyExecutor, true);
    }

    //** Strategy implementation (override the following functions) */

    /// @notice Invests the underlying asset.   
    /// @param amount The amount of tokens to invest.
    /// @dev Assume the contract's balance is greater than the amount.
    function _skim(uint256 amount) internal virtual;

    /// @notice Harvest any profits made and transfer them to address(this) or report a loss.
    /// @param balance The amount of tokens that have been invested.
    /// @return amountAdded The delta (+profit or -loss) that occured in contrast to `balance`.
    /// @dev amountAdded can be left at 0 when reporting profits (gas savings).
    /// amountAdded should not reflect any rewards or tokens the strategy received.
    /// Calculate the amount added based on what the current deposit is worth.
    /// (The Base Strategy harvest function accounts for rewards).
    function _harvest(uint256 balance) internal virtual returns (int256 amountAdded);

    /// @dev Withdraw the requested amount of the underlying tokens to address(this).
    /// @param amount The requested amount we want to withdraw.
    function _withdraw(uint256 amount) internal virtual;

    /// @notice Withdraw the maximum available amount of the invested assets to address(this).
    /// @dev This shouldn't revert (use try catch).
    function _exit() internal virtual;

    /// @notice Claim any reward tokens and optionally sell them for the underlying token.
    /// @dev Doesn't need to be implemented if we don't expect any rewards.
    function _harvestRewards() internal virtual {}

    //** End strategy implementation */

    modifier isActive() {
        if (_exited) {
            revert StrategyExited();
        }
        _;
    }

    modifier onlyBentoBox() {
        if (msg.sender != address(bentoBox)) {
            revert OnlyBentoBox();
        }
        _;
    }

    modifier onlyExecutor() {
        if (!strategyExecutors[msg.sender]) {
            revert OnlyExecutor();
        }
        _;
    }

    function setStrategyExecutor(address executor, bool value) external onlyOwner {
        strategyExecutors[executor] = value;
        emit LogSetStrategyExecutor(executor, value);
    }

    function setSwapPath(address tokenIn, address tokenOut) external onlyOwner {
        if (tokenIn == address(strategyToken)) revert InvalidSwapPath();
        swapPath[tokenIn] = tokenOut;
        emit LogSetSwapPath(tokenIn, tokenOut);
    }

    /// @inheritdoc IStrategy
    function skim(uint256 amount) external override {
        _skim(amount);
    }

    /// @notice Harvest profits while preventing a sandwich attack exploit.
    /// @param maxBalanceInBentoBox The maximum balance of the underlying token that is allowed to be in BentoBox.
    /// @param rebalance Whether BentoBox should rebalance the strategy assets to acheive it's target allocation.
    /// @param maxChangeAmount When rebalancing - the maximum amount that will be deposited to or withdrawn from a strategy to BentoBox.
    /// @param harvestRewards If we want to claim any accrued reward tokens
    /// @dev maxBalance can be set to 0 to keep the previous value.
    /// @dev maxChangeAmount can be set to 0 to allow for full rebalancing.
    function safeHarvest(
        uint256 maxBalanceInBentoBox,
        bool rebalance,
        uint256 maxChangeAmount,
        bool harvestRewards
    ) external onlyExecutor {
        if (harvestRewards) {
            _harvestRewards();
        }

        if (maxBalanceInBentoBox > 0) {
            _maxBentoBoxBalance = maxBalanceInBentoBox;
        }

        bentoBox.harvest(address(strategyToken), rebalance, maxChangeAmount);
    }

    /** @inheritdoc IStrategy
    @dev Only BentoBox can call harvest on this strategy.
    @dev Ensures that (1) the caller was this contract (called through the safeHarvest function)
        and (2) that we are not being frontrun by a large BentoBox deposit when harvesting profits. */
    function harvest(uint256 balance, address sender) external override isActive onlyBentoBox returns (int256) {
        
        /** @dev Don't revert if conditions aren't met in order to allow
            BentoBox to continue execution as it might need to do a rebalance. */
        if (
            sender != address(this) ||
            bentoBox.totals(address(strategyToken)).elastic > _maxBentoBoxBalance || 
            balance == 0
        ) return int256(0);
            
        int256 amount = _harvest(balance);

        /** @dev We might have some underlying tokens in the contract that the _harvest call doesn't report. 
        E.g. reward tokens that have been sold into the underlying tokens which are now sitting in the contract.
        Meaning the amount returned by the internal _harvest function isn't necessary the final profit/loss amount */

        uint256 contractBalance = strategyToken.balanceOf(address(this)); // Reasonably assume this is less than type(int256).max

        if (amount > 0) { // _harvest reported a profit

            strategyToken.safeTransfer(address(bentoBox), contractBalance);

            return int256(contractBalance);

        } else if (contractBalance > 0) { // _harvest reported a loss but we have some tokens sitting in the contract

            int256 diff = amount + int256(contractBalance);

            if (diff > 0) { // We still made some profit.

                // Send the profit to BentoBox and reinvest the rest.
                strategyToken.safeTransfer(address(bentoBox), uint256(diff));
                _skim(contractBalance - uint256(diff));

            } else { // We made a loss but we have some tokens we can reinvest.

                _skim(contractBalance);

            }

            return diff;

        } else { // We made a loss.

            return amount;

        }

    }

    /// @inheritdoc IStrategy
    function withdraw(uint256 amount) external override isActive onlyBentoBox returns (uint256 actualAmount) {
        _withdraw(amount);
        // Make sure we send and report the exact same amount of tokens by using balanceOf.
        actualAmount = strategyToken.balanceOf(address(this));
        strategyToken.safeTransfer(address(bentoBox), actualAmount);
    }

    /// @inheritdoc IStrategy
    /// @dev Do not use isActive modifier here. Allow bentobox to call strategy.exit() multiple times
    /// This is to ensure that the strategy isn't locked if its (accidentally) set twice in a row as a token's strategy in bentobox.
    function exit(uint256 balance) external override onlyBentoBox returns (int256 amountAdded) {
        _exit();
        // Flag as exited, allowing the owner to manually deal with any amounts available later.
        _exited = true;
        // Check balance of token on the contract.
        uint256 actualBalance = strategyToken.balanceOf(address(this));
        // Calculate tokens added (or lost).
        // We reasonably assume actualBalance and balance are less than type(int256).max
        amountAdded = int256(actualBalance) - int256(balance);
        // Transfer all tokens to bentoBox.
        strategyToken.safeTransfer(address(bentoBox), actualBalance);
    }

    /** @dev After exited, the owner can perform ANY call. This is to rescue any funds that didn't
        get released during exit or got earned afterwards due to vesting or airdrops, etc. */
    function afterExit(
        address to,
        uint256 value,
        bytes memory data
    ) external onlyOwner returns (bool success) {
        if (!_exited) {
            revert StrategyNotExited();
        }
        (success, ) = to.call{value: value}(data);
        require(success);
    }

    function exited() public view returns(bool) {
        return _exited;
    }

    function maxBentoBoxBalance() public view returns (uint256) {
        return _maxBentoBoxBalance;
    }

    /// @notice Swap some tokens in the contract.
    /// @param tokenIn Token we are swapping.
    /// @param amountOutMin Minimum amount of output tokens we should get (slippage protection).
    function swapExactTokens(address tokenIn, uint256 amountOutMin) external onlyExecutor {

        address tokenOut = swapPath[tokenIn];

        if (tokenOut == address(0)) revert NoSwapPath();

        uint256 amountIn = ERC20(tokenIn).balanceOf(address(this));

        uint256 amountOut = _swap(tokenIn, tokenOut, amountIn);
        
        if (amountOut < amountOutMin) revert SlippageProtection();
    }

    function _swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) internal returns (uint256 outAmount) {

        address pair = _pairFor(tokenIn, tokenOut);
        ERC20(tokenIn).safeTransfer(pair, amountIn);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pair).getReserves();
        
        if (tokenIn < tokenOut) {
            outAmount = _getAmountOut(amountIn, reserve0, reserve1);
            IUniswapV2Pair(pair).swap(0, outAmount, address(this), "");
        } else {
            outAmount = _getAmountOut(amountIn, reserve1, reserve0);
            IUniswapV2Pair(pair).swap(outAmount, 0, address(this), "");
        }
    }

    function _pairFor(address tokenA, address tokenB) internal view returns (address pair) {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        pair = address(uint160(uint256(keccak256(abi.encodePacked(
            hex'ff',
            factory,
            keccak256(abi.encodePacked(token0, token1)),
            hex'e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303'
        )))));
    }

    function _getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256) {
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        return numerator / denominator;
    }

    function increment(uint256 i) internal pure returns (uint256) {
        unchecked {
            return i + 1;
        }
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.7;

interface IStrategy {
    /// @notice Send the assets to the Strategy and call skim to invest them.
    /// @param amount The amount of tokens to invest.
    function skim(uint256 amount) external;

    /// @notice Harvest any profits made converted to the asset and pass them to the caller.
    /// @param balance The amount of tokens the caller thinks it has invested.
    /// @param sender The address of the initiator of this transaction. Can be used for reimbursements, etc.
    /// @return amountAdded The delta (+profit or -loss) that occured in contrast to `balance`.
    function harvest(uint256 balance, address sender) external returns (int256 amountAdded);

    /// @notice Withdraw assets. The returned amount can differ from the requested amount due to rounding.
    /// @dev The `actualAmount` should be very close to the amount.
    /// The difference should NOT be used to report a loss. That's what harvest is for.
    /// @param amount The requested amount the caller wants to withdraw.
    /// @return actualAmount The real amount that is withdrawn.
    function withdraw(uint256 amount) external returns (uint256 actualAmount);

    /// @notice Withdraw all assets in the safest way possible. This shouldn't fail.
    /// @param balance The amount of tokens the caller thinks it has invested.
    /// @return amountAdded The delta (+profit or -loss) that occured in contrast to `balance`.
    function exit(uint256 balance) external returns (int256 amountAdded);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.7;

interface IUniswapV2Pair {
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

/// @notice Minimal interface for BentoBox token vault interactions - `token` is aliased as `address` from `IERC20` for code simplicity.
interface IBentoBoxMinimal {

    struct Rebase {
        uint128 elastic;
        uint128 base;
    }

    struct StrategyData {
        uint64 strategyStartDate;
        uint64 targetPercentage;
        uint128 balance; // the balance of the strategy that BentoBox thinks is in there
    }

    function strategyData(address token) external view returns (StrategyData memory);

    /// @notice Balance per ERC-20 token per account in shares.
    function balanceOf(address, address) external view returns (uint256);

    /// @notice Deposit an amount of `token` represented in either `amount` or `share`.
    /// @param token_ The ERC-20 token to deposit.
    /// @param from which account to pull the tokens.
    /// @param to which account to push the tokens.
    /// @param amount Token amount in native representation to deposit.
    /// @param share Token amount represented in shares to deposit. Takes precedence over `amount`.
    /// @return amountOut The amount deposited.
    /// @return shareOut The deposited amount repesented in shares.
    function deposit(
        address token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external payable returns (uint256 amountOut, uint256 shareOut);

    /// @notice Withdraws an amount of `token` from a user account.
    /// @param token_ The ERC-20 token to withdraw.
    /// @param from which user to pull the tokens.
    /// @param to which user to push the tokens.
    /// @param amount of tokens. Either one of `amount` or `share` needs to be supplied.
    /// @param share Like above, but `share` takes precedence over `amount`.
    function withdraw(
        address token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);

    /// @notice Transfer shares from a user account to another one.
    /// @param token The ERC-20 token to transfer.
    /// @param from which user to pull the tokens.
    /// @param to which user to push the tokens.
    /// @param share The amount of `token` in shares.
    function transfer(
        address token,
        address from,
        address to,
        uint256 share
    ) external;

    /// @dev Helper function to represent an `amount` of `token` in shares.
    /// @param token The ERC-20 token.
    /// @param amount The `token` amount.
    /// @param roundUp If the result `share` should be rounded up.
    /// @return share The token amount represented in shares.
    function toShare(
        address token,
        uint256 amount,
        bool roundUp
    ) external view returns (uint256 share);

    /// @dev Helper function to represent shares back into the `token` amount.
    /// @param token The ERC-20 token.
    /// @param share The amount of shares.
    /// @param roundUp If the result should be rounded up.
    /// @return amount The share amount back into native representation.
    function toAmount(
        address token,
        uint256 share,
        bool roundUp
    ) external view returns (uint256 amount);

    /// @notice Registers this contract so that users can approve it for the BentoBox.
    function registerProtocol() external;

    function totals(address token) external view returns (Rebase memory);

    function harvest(
        address token,
        bool balance,
        uint256 maxChangeAmount
    ) external;
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
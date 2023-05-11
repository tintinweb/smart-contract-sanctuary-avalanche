// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Sake} from "./Sake.sol";
// import {Constant} from "../access/Constant.sol";
import {IBartender, IERC20, UserDepositInfo, SakeVaultInfo, UpdatedDebtRatio} from "../interfaces/IBartender.sol";
import {IWater} from "../interfaces/water/IWater.sol";
import {IVault} from "../interfaces/vela-exchange/IVault.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {FeeSplitStrategy} from "../libraries/FeeSplitStrategy.sol";
import {BartenderManager} from "../libraries/BartenderManager.sol";

/**
 * @author Chef Photons, Vaultka Team serving high quality drinks; drink responsibly.
 * Factory and global config params
 */
contract Bartender is IBartender, Ownable {
    using Math for uint256;
    using FeeSplitStrategy for FeeSplitStrategy.Info;
    using BartenderManager for BartenderManager.State;

    FeeSplitStrategy.Info private feeSplitStrategy;
    BartenderManager.State private state;
    IERC20 private immutable usdcToken;
    uint256 private constant MAX_BPS = 100_000;
    uint256 private constant COOLDOWN_PERIOD = 3 days;
    uint256 private constant RATE_PRECISION = 1e30;
    uint8 private constant VLP_DECIMAL = 18;
    uint256 private _currentId;

    mapping(uint256 => address) internal sakeVault;
    mapping(uint256 => UpdatedDebtRatio) internal updatedDebtRatio;
    mapping(address => mapping(uint256 => UserDepositInfo)) internal userDepositInfo;
    mapping(uint256 => SakeVaultInfo) internal sakeVaultInfo;

    constructor(
        address _usdcToken,
        address _water,
        address _keeper,
        address _liquor,
        address _feeRecipient,
        address _mintAndBurn,
        address stakingVault,
        address _vlp
    ) {
        usdcToken = IERC20(_usdcToken);
        state.velaMintBurnVault = _mintAndBurn;
        state.velaStakingVault = stakingVault;
        state.vlp = _vlp;
        state.water = _water;
        state.liquor = _liquor;
        state.feeRecipient = _feeRecipient;
        state.keeper = _keeper;
        state.depositFeeBPS = 0;
        state.withdrawFeeBPS = 1000;

        _currentId = 1;
        state.feeEnabled = true;
        usdcToken.approve(_water, type(uint256).max);
    }

    /* ##################################################################
                                MODIFIERS
    ################################################################## */
    modifier onlyKeeper() {
        if (state.keeper != msg.sender) revert BTDNotAKeeper();
        _;
    }

    modifier onlyLiquor() {
        if (state.liquor != msg.sender) revert BTDNotLiquor();
        _;
    }

    /* ##################################################################
                                OWNER FUNCTIONS
    ################################################################## */
    // @notice update every address with a single function
    // @param addresses address to initialized the vault
    // function settingManager(BartenderManager.Adresses calldata addresses) external onlyOwner {
    //     state.velaMintBurnVault = addresses.velaMintBurnVault;
    //     state.vlp = addresses.vlp;
    //     state.velaStakingVault = addresses.velaStakingVault;
    //     state.water = addresses.water;
    //     state.keeper = addresses.keeper;
    //     state.liquor = addresses.liquor;
    //     state.feeRecipient = addresses.feeRecipient;
    // }

    // @notice sets feeBps
    // @param _feeBps the part of USDC that will be deducted as protocol fees
    function setFeeParams(BartenderManager.FeeUpdate calldata _feeUpdate) external onlyOwner {
        state.feeEnabled = _feeUpdate.feeEnabled;
        state.depositFeeBPS = _feeUpdate.depositFeeBPS;
        state.withdrawFeeBPS = _feeUpdate.withdrawFeeBPS;
    }

    /// @notice updates fee split strategy
    /// @notice this determines how eth rewards should be split between WATER Vault and BARTENDER
    /// @notice basis the utilization of WATER Vault
    /// @param _feeStrategy: new fee strategy
    function updateFeeStrategyParams(FeeSplitStrategy.Info calldata _feeStrategy) external onlyOwner {
        feeSplitStrategy = _feeStrategy;
    }

    /* ##################################################################
                                KEEPER FUNCTIONS
    ################################################################## */
    /// @notice Create new SAKE Vault
    function createSake() external onlyKeeper {
        uint256 lCurrentId = _currentId;
        // compute the amount deposited with the last known time
        uint256 _amount = sakeVaultInfo[lCurrentId].totalAmountOfUSDCWithoutLeverage * 3;
        // revert if no deposit occure
        if (_amount == 0) revert CurrentDepositIsZero();

        // create new SAKE
        Sake newSake = new Sake(
            address(usdcToken),
            address(this),
            state.velaMintBurnVault,
            state.velaStakingVault,
            state.vlp,
            state.liquor
        );

        sakeVault[lCurrentId] = address(newSake);
        // transfer _token into the newly created SAKE
        usdcToken.transfer(address(newSake), _amount);
        (bool _status, uint256 totalVLP) = newSake.executeMintAndStake();
        if (!_status) revert UnsuccessfulCreationOfSake();

        sakeVaultInfo[lCurrentId].totalAmountOfVLP = totalVLP;
        sakeVaultInfo[lCurrentId].totalAmountOfVLPInUSDC = convertVLPToUSDC(totalVLP);
        sakeVaultInfo[lCurrentId].startTime = block.timestamp;
        sakeVaultInfo[lCurrentId].purchasePrice = getVLPPrice();
        initializedAllSakeUsersShares(lCurrentId);
        storeDebtRatio(lCurrentId, 0);
        _currentId++;
        emit CreateNewSAKE(address(newSake), lCurrentId);
    }

    /* ##################################################################
                                SAKE FUNCTIONS
    ################################################################## */
    /* ##################################################################
                                USER FUNCTIONS
    ################################################################## */
    /** @dev See {IBartender-deposit}. */
    function deposit(uint256 _amount, address _receiver) external {
        if (_amount == 0) revert ThrowZeroAmount();

        uint256 totalDebt = IWater(state.water).getTotalDebt();
        uint256 WaterUSDCBalance = usdcToken.balanceOf(state.water);

        uint256 maxDeposit = getMaxDeposit(totalDebt, WaterUSDCBalance);

        if (_amount > maxDeposit) revert ThrowMaxDepositExceeded();

        usdcToken.transferFrom(msg.sender, address(this), _amount);
        (uint256 fees, uint256 amount) = state.calculateFees(bytes32("deposit"), _amount);
        transferFees(fees);
        _amount = amount;
        uint256 initialDeposit = userDepositInfo[_receiver][_currentId].amount;
        // locally store 2X leverage to avoid computing mload everytime
        uint256 leverage = _amount * 2;
        // take leverage from WATER VAULT
        IWater(state.water).leverageVault(leverage);
        uint256 lCurrentId = _currentId;
        // update total amount without borrowed amount
        sakeVaultInfo[lCurrentId].totalAmountOfUSDCWithoutLeverage += _amount;
        // update amount stake on current time interval
        sakeVaultInfo[lCurrentId].leverage += leverage;
        // update user state values
        userDepositInfo[_receiver][lCurrentId].amount += _amount;
        // push users into list
        if (initialDeposit == 0) {
            sakeVaultInfo[lCurrentId].users.push(_receiver);
        }
        emit BartenderDeposit(msg.sender, _amount, lCurrentId, leverage);
    }

    /** @dev See {IBartender-withdraw}. */
    function withdraw(uint256 _amount, uint256 id, address _receiver) external {
        if (sakeVaultInfo[id].isLiquidated) revert ThrowLiquidated();

        if (_amount == 0) revert ThrowZeroAmount();

        // if (block.timestamp < sakeVaultInfo[id].startTime + COOLDOWN_PERIOD) revert ThrowLockTimeOn();

        if (_amount > previewWithdraw(id, msg.sender)) revert ThrowInvalidAmount();

        uint256 withdrawableAmountInVLP = computesAmountToBeSoldInVLPUpdateShareAndDebtRatio(_amount, id, msg.sender);
        address _sake = sakeVault[id];
        (bool status, uint256 _withdrawnAmountinUSDC) = Sake(_sake).withdraw(address(this), withdrawableAmountInVLP);
        if (!status) revert SakeWitdrawal({sake: _sake, amount: _amount});
        _transferAndRepayLoan(_withdrawnAmountinUSDC, _receiver, _amount);

        emit Withdraw(msg.sender, _amount, id, withdrawableAmountInVLP);
    }

    /* ##################################################################
                                INTERNAL FUNCTIONS
    ################################################################## */
    // transfer and repay load
    function _transferAndRepayLoan(uint256 _withdrawnAmountinUSDC, address _receiver, uint256 share) private {
        uint256 loan = (_withdrawnAmountinUSDC - share);
        // repay loan to WATER VAULT
        IWater(state.water).repayDebt(loan);
        // take protocol fee
        (uint256 fees, uint256 amount) = state.calculateFees(bytes32("withdraw"), share);
        transferFees(fees);
        usdcToken.transfer(_receiver, amount);
    }

    function transferFees(uint256 fees) internal {
        if(fees > 0) {
            usdcToken.transfer(state.feeRecipient, fees);
        }
    }

    // convert totalVLP to USDC
    function convertVLPToUSDC(uint256 _amount) public view returns (uint256) {
        uint256 _vlpPrice = getVLPPrice();
        return _amount.mulDiv(_vlpPrice * 10, (10 ** VLP_DECIMAL));
    }

    function getVLPPrice() public view returns (uint256) {
        return IVault(state.velaMintBurnVault).getVLPPrice();
    }

    function computesAmountToBeSoldInVLPUpdateShareAndDebtRatio(
        uint256 withdrawableAmount,
        uint256 id,
        address sender
    ) internal returns (uint256) {
        uint256 updatedDebt;
        uint256 value;
        // when new value is 0, then it shows the SAKE vault is been created, get the current debt and value
        // else get the previous debt and value
        (updatedDebt, value, ) = updateDebtAndValueAmount(id, true);
        // get the difference between the current value and the updated debt
        // use the difference to and the withdrawable amount * value / difference.
        uint256 subDebtFromValue = value - updatedDebt;
        uint256 withdrawableAmountMulValue = withdrawableAmount.mulDiv(value, subDebtFromValue);
        // the previous debt and value is used to calculate the shares, using the withdrawable amount.
        (uint256 previousValue, uint256 previousDebt) = storeDebtRatio(id, withdrawableAmountMulValue);
        _updateShares(id, sender, withdrawableAmount, previousValue, previousDebt);
        // the amount of VLP to be sold is the withdrawable amount / the current VLP price
        uint256 requireAMountOfVLPToBeSold = withdrawableAmountMulValue.mulDiv(10 ** 18, getVLPPrice() * 10);
        // // update the total amount of VLP in the SAKE vault
        sakeVaultInfo[id].totalAmountOfVLP -= requireAMountOfVLPToBeSold;
        // // return the amount of VLP to be sold
        return requireAMountOfVLPToBeSold;
    }

    function initializedAllSakeUsersShares(uint256 id) private {
        uint256 totalUsers = sakeVaultInfo[id].users.length;
        uint256 amountWithoutLeverage = sakeVaultInfo[id].totalAmountOfUSDCWithoutLeverage;
        for (uint256 i = 0; i < totalUsers; ) {
            address user = sakeVaultInfo[id].users[i];
            uint256 _amountDepositedAndLeverage = userDepositInfo[user][id].amount;
            userDepositInfo[user][id].shares = (
                _amountDepositedAndLeverage.mulDiv(RATE_PRECISION, amountWithoutLeverage)
            );
            unchecked {
                i++;
            }
        }
    }

    function storeDebtRatio(
        uint256 id,
        uint256 requireToBeSold
    ) private returns (uint256 previousValue, uint256 previousDebt) {
        uint256 updatedDebt;
        uint256 value;
        uint256 dvtRatio;

        previousValue = updatedDebtRatio[id].newValue;
        previousDebt = updatedDebtRatio[id].newDebt;
        if (requireToBeSold == 0) {
            (updatedDebt, value, dvtRatio) = updateDebtAndValueAmount(id, true);
        } else {
            (updatedDebt, value, dvtRatio) = updateDebtAndValueAmount(id, false);
            value = value - requireToBeSold;
            updatedDebt = value.mulDiv(dvtRatio, RATE_PRECISION);
        }
        updatedDebtRatio[id].newDebt = updatedDebt;
        updatedDebtRatio[id].newValue = value;
        updatedDebtRatio[id].newRatio = dvtRatio;
    }

    function _updateShares(
        uint256 id,
        address sender,
        uint256 withdrawableAmount,
        uint256 previousValue,
        uint256 previousDebt
    ) private {
        uint256 newDebt = updatedDebtRatio[id].newDebt;
        uint256 newValue = updatedDebtRatio[id].newValue;
        // get the total number of users in the SAKE vault
        uint256 totalUsers = sakeVaultInfo[id].users.length;
        for (uint256 i = 0; i < totalUsers; ) {
            // load the user address into memory
            address user = sakeVaultInfo[id].users[i];
            if (user == sender) {
                uint256 subAmountFromMaxWithdrawal = beforeWithdrawal(id, previousValue, previousDebt, user) -
                    withdrawableAmount;

                uint256 _newShare = subAmountFromMaxWithdrawal.mulDiv(RATE_PRECISION, (newValue - newDebt));
                userDepositInfo[sender][id].shares = _newShare;
                userDepositInfo[sender][id].totalWithdrawn = subAmountFromMaxWithdrawal;
            } else {
                uint256 subAmountFromMaxWithdrawal = beforeWithdrawal(id, previousValue, previousDebt, user);

                uint256 share = subAmountFromMaxWithdrawal.mulDiv(RATE_PRECISION, ((newValue - newDebt)));
                userDepositInfo[user][id].shares = share;
            }
            unchecked {
                i++;
            }
        }
    }

    function updateDebtAndValueAmount(
        uint256 id,
        bool _state
    ) public returns (uint256 newDebt, uint256 Value, uint256 dvtRatio) {
        // convert total amount of VLP to USDC
        uint256 amountInUSDC = convertVLPToUSDC(sakeVaultInfo[id].totalAmountOfVLP);
        uint256 profitDifferences;
        // profit difference should be with previous value
        uint256 getPreviousValue = updatedDebtRatio[id].newValue;
        // check if there is profit
        // i.e the total amount of VLP in USDC is greater than the current amount with leverage
        // and when there is not profit the debt remains.
        if (amountInUSDC > getPreviousValue) {
            profitDifferences = amountInUSDC - getPreviousValue;
        }
        // calculate the fee split rateand reward split to water when there is profit
        (uint256 feeSplit, ) = calculateFeeSplitRate();
        // rewardSplitToWater returns 0 when there is no profit

        uint256 rewardSplitToWater = profitDifferences.mulDiv(feeSplit, RATE_PRECISION);
        uint256 previousDebt = updatedDebtRatio[id].newDebt;
        uint256 previousDebtAddRewardSplit = previousDebt + rewardSplitToWater;
        uint256 totalDebt;
        if (_state) {
            if (previousDebt == 0) {
                totalDebt = (sakeVaultInfo[id].totalAmountOfUSDCWithoutLeverage * 2);
            } else {
                totalDebt = previousDebtAddRewardSplit;
                IWater(state.water).updateTotalDebt(rewardSplitToWater);
            }
        }
        if (!_state) {
            uint256 getPreviousDVTRatio = previousDebtAddRewardSplit.mulDiv(RATE_PRECISION, amountInUSDC);
            totalDebt = amountInUSDC.mulDiv(getPreviousDVTRatio, RATE_PRECISION);
            IWater(state.water).updateTotalDebt(rewardSplitToWater);
        }

        updatedDebtRatio[id].newDebt = totalDebt;
        updatedDebtRatio[id].newValue = amountInUSDC;
        updatedDebtRatio[id].newRatio = totalDebt.mulDiv(RATE_PRECISION, amountInUSDC);
        updatedDebtRatio[id].lastUpdateTime = block.timestamp;
        updatedDebtRatio[id].previousPrice = getVLPPrice();

        // DVT Ratio is the total amount of new debt / total amount of VLP in USDC
        // return the new debt, amount in USDC which is the total amount of VLP in USDC and the DVT Ratio
        return (totalDebt, amountInUSDC, totalDebt.mulDiv(RATE_PRECISION, amountInUSDC));
    }

    //change to public for testing purpose
    function calculateFeeSplitRate() public view returns (uint256 feeSplitRate, uint256 utilizationRatio) {
        (, bytes memory result) = address(state.water).staticcall(abi.encodeWithSignature("totalAssets()"));

        uint256 totalAssets = abi.decode(result, (uint256));

        uint256 totalDebt = IWater(state.water).getTotalDebt();
        (feeSplitRate, utilizationRatio) = feeSplitStrategy.calculateFeeSplit(
            (totalAssets - totalDebt),
            totalDebt
        );

        return (feeSplitRate, utilizationRatio);
    }

    function beforeWithdrawal(
        uint256 id,
        uint256 previousValue,
        uint256 previousDebt,
        address user
    ) public view returns (uint256 max) {
        // convert total amount of VLP to USDC
        uint256 amountInUSDC = convertVLPToUSDC(sakeVaultInfo[id].totalAmountOfVLP);
        uint256 profitDifferences;
        // profit difference should be with previous value
        // uint256 getPreviousValue = updatedDebtRatio[id].newValue;
        // check if there is profit
        // i.e the total amount of VLP in USDC is greater than the current amount with leverage
        // and when there is not profit the debt remains.
        if (amountInUSDC > previousValue) {
            profitDifferences = amountInUSDC - previousValue;
        }
        // calculate the fee split rateand reward split to water when there is profit
        (uint256 feeSplit, ) = calculateFeeSplitRate();
        // rewardSplitToWater returns 0 when there is no profit
        uint256 rewardSplitToWater = (profitDifferences.mulDiv(feeSplit, RATE_PRECISION));
        // uint256 previousDebt = updatedDebtRatio[id].newDebt;
        uint256 previousDebtAddRewardSplit = previousDebt + rewardSplitToWater;
        uint256 currentShares = userDepositInfo[user][id].shares;

        uint256 _max = (amountInUSDC - previousDebtAddRewardSplit).mulDiv(currentShares, RATE_PRECISION);

        return (_max);
    }

    /* ##################################################################
                                VIEW FUNCTIONS
    ################################################################## */

    function maxWithdraw(uint256 id, uint256 currentShares) public returns (uint256) {
        uint256 updatedDebt;
        uint256 value;
        if (updatedDebtRatio[id].newValue != 0) {
            (updatedDebt, value, ) = updateDebtAndValueAmount(id, true);
        } else {
            updatedDebt = updatedDebtRatio[id].newDebt;
            value = updatedDebtRatio[id].newValue;
        }
        uint256 currentShareDivRate = (value - updatedDebt).mulDiv(currentShares, RATE_PRECISION);
        return currentShareDivRate;
    }

    // preview withdrawal
    function previewWithdraw(uint256 id, address user) public returns (uint256) {
        uint256 shares;
        // uint256 _currentID = updatedDebtRatio[id].newValue == 0
        //     ? _currentId
        //     : updatedDebtRatio[id].newValue;
        if (updatedDebtRatio[id].newValue == 0) {
            uint256 _totalAmount = sakeVaultInfo[id].totalAmountOfUSDCWithoutLeverage * 3;
            shares = ((userDepositInfo[user][id].amount * 3).mulDiv(RATE_PRECISION, _totalAmount));
        } else {
            shares = userDepositInfo[user][id].shares;
        }
        return maxWithdraw(id, shares);
    }

    function getMaxWithdraw(uint256 id, address user) public view returns (uint256 maxWithdrawAmount) {
        uint256 shares = userDepositInfo[user][id].shares;
        uint256 updatedDebt = updatedDebtRatio[id].newDebt;
        uint256 value = updatedDebtRatio[id].newValue;

        return (value - updatedDebt).mulDiv(shares, RATE_PRECISION);
    }

    /** @dev See {IBartender-getFeeStatus}. */
    function getFeeStatus() external view returns (address, bool, uint96) {
        // return (feeRecipient, feeEnabled, feeBPS);
    }

    /** @dev See {IBartender-getCurrentId}. */
    function getCurrentId() external view returns (uint256) {
        return _currentId;
    }

    /** @dev See {IBartender-getKeeper}. */
    function getKeeper() external view returns (address) {
        // return keeper;
    }

    function getSakeVLPBalance(uint256 id) external view returns (uint256) {
        address sake = sakeVault[id];
        return Sake(sake).getSakeBalanceInVLP();
    }

    function getSakeVaultInfo(uint256 id) external view returns (SakeVaultInfo memory) {
        return sakeVaultInfo[id];
    }

    function depositInfo(uint256 id, address user) external view returns (UserDepositInfo memory) {
        return userDepositInfo[user][id];
    }

    function getDebtInfo(uint256 id) external view returns (UpdatedDebtRatio memory debtInfo) {
        return updatedDebtRatio[id];
    }

    function getSakeAddress(uint256 id) public view returns (address sake) {
        return sakeVault[id];
    }

    function getClaimable(uint256 id) public view returns (uint256) {
        return Sake(sakeVault[id]).getClaimable();
    }

    function withdrawVesting(uint256 id) public onlyOwner {
        Sake(sakeVault[id]).withdrawVesting();
    }

    function setLiquidated(uint256 id) public onlyLiquor returns (address sakeAddress) {
        sakeVaultInfo[id].isLiquidated = true;
        return sakeVault[id];
    }
    
    function isValidUpdate(uint256 id) public view returns (bool isValid) {
        // if last deposit / withdraw is 8 hours before
        uint256 currentVLPPrice = getVLPPrice();
        uint256 previousVLPPrice = updatedDebtRatio[id].previousPrice;

        uint256 priceChange = currentVLPPrice > previousVLPPrice
            ? currentVLPPrice - previousVLPPrice
            : previousVLPPrice - currentVLPPrice;
        //28800 is 8 hours in seconds
        uint256 onePercent = 1000;
        if (
            block.timestamp - updatedDebtRatio[id].lastUpdateTime > 28800 ||
            priceChange.mulDiv(RATE_PRECISION, previousVLPPrice) > onePercent.mulDiv(RATE_PRECISION, MAX_BPS)
        ) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @notice Calculates the maximum deposit amount (`MaxDeposit`) allowed based on the current debt (`Debt`)
     * and water balance (`WaterBalance`) in USDC.
     *
     * Formula: MaxDeposit = (Debt + 2 * MaxDeposit) / (Debt + WaterBalance)
     */
    function getMaxDeposit(uint256 totalDebt, uint256 waterBalance) public pure returns (uint256) {
        uint256 y = waterBalance.mulDiv(40000, MAX_BPS) - totalDebt.mulDiv(10000, MAX_BPS);
        return y;
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {IERC20} from "../interfaces/IERC20.sol";
import {IVault} from "../interfaces/vela-exchange/IVault.sol";
import {ITokenFarm} from "../interfaces/vela-exchange/ITokenFarm.sol";

/**
 * @author Chef Photons, Vaultka Team serving high quality drinks; drink responsibly.
 * Responsible for to keeping track of our finest Sake
 */
contract Sake {
    IERC20 private immutable usdcToken;
    address private immutable bartender;
    uint256 private totalAmountOfVLP;
    address private liquor;

    //vela exchange contracts
    //will keep these
    IVault private immutable velaMintBurnVault;
    ITokenFarm private immutable velaStakingVault;
    IERC20 private immutable vlp;

    event Withdraw(address indexed _user, uint256 _amount);

    error ThrowPermissionDenied(address admin, address sender);

    modifier onlyBartenderOrLiquor() {
        if (msg.sender != address(bartender) && msg.sender != address(liquor))
            revert ThrowPermissionDenied({admin: address(bartender), sender: msg.sender});
        _;
    }

    constructor(
        address _usdcToken,
        address _bartender,
        address _velaMintBurnVault,
        address _velaStakingVault,
        address _vlp,
        address _liquor
    ) {
        usdcToken = IERC20(_usdcToken);
        bartender = _bartender;
        velaMintBurnVault = IVault(_velaMintBurnVault);
        velaStakingVault = ITokenFarm(_velaStakingVault);
        vlp = IERC20(_vlp);
        liquor = _liquor;
    }

    //@todo some approval needs to be grant for deposit and withdrawal, will work on that later
    /// @notice allows bartender to mint and stake vlp into the sake contract
    /// @return status status is true if the function executed sucessfully, vice versa
    function executeMintAndStake() external onlyBartenderOrLiquor returns (bool status, uint256 totalVLP) {
        uint256 usdcBalance = usdcToken.balanceOf(address(this));
        usdcToken.approve(address(velaMintBurnVault), usdcBalance);
        // vlp approve staking vault with uint256 max
        vlp.approve(address(velaStakingVault), type(uint256).max);
        //mint the whole batch of USDC to VLP, sake doesn't handle the accounting, so balanceOf will be sufficient.
        // @notice there is no need for reentrancy guard Bartender will handle that
        // REFERENCE: 01
        // @todo a struct/variables to store or return this values so that bartender can store them to calculate user share during withdrawal
        // vlp recieved,
        // amount used to purchase the vlp, (can be excluded since it amount transfered by bartender to sake)
        // price at which vlp was bought
        velaMintBurnVault.stake(address(this), address(usdcToken), usdcBalance);
        // get the total amount of VLP bought
        totalVLP = vlp.balanceOf(address(this));
        totalAmountOfVLP = totalVLP;
        velaStakingVault.deposit(0, totalVLP);

        return (true, totalVLP);
    }

    /// @notice allows bartender to withdraw a specific amount from the sake contract
    /// @param _to user reciving the redeemed USDC
    /// @param amountToWithdrawInVLP amount to withdraw in VLP
    /// @return status received in exchange of token
    function withdraw(
        address _to,
        uint256 amountToWithdrawInVLP
    ) external onlyBartenderOrLiquor returns (bool status, uint256 usdcAmount) {
        vlp.approve(address(velaStakingVault), amountToWithdrawInVLP);
        velaStakingVault.withdraw(0, amountToWithdrawInVLP);
        velaMintBurnVault.unstake(address(usdcToken), amountToWithdrawInVLP, address(this));
        uint256 withdrawAmount = usdcToken.balanceOf(address(this));

        //sake will send the USDC back to the user directly
        usdcToken.transfer(_to, withdrawAmount);
        return (true, withdrawAmount);
    }

    // create a function to output sake balance in vlp
    function getSakeBalanceInVLP() external view returns (uint256 vlpBalance) {
        return totalAmountOfVLP;
    }

    function getClaimable() public view returns (uint256) {
        return velaStakingVault.claimable(address(this));
    }

    function withdrawVesting() external onlyBartenderOrLiquor {
        velaStakingVault.withdrawVesting();
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20} from "./IERC20.sol";

/* ##################################################################
                            STRUCTS
################################################################## */
struct UserDepositInfo {
    // Amount in supply as debt to SAKE
    uint256 amount;
    // max withdrawal amount
    uint256 maxWithdrawalAmount;
    uint256 totalWithdrawn;
    // store user shares
    uint256 shares;
    // track user withdrawal
    uint256 initializedShareStates;
}

struct UpdatedDebtRatio {
    uint256 newValue;
    uint256 newDebt;
    uint256 newRatio;
    uint256 lastUpdateTime;
    uint256 previousPrice;
}

struct SakeVaultInfo {
    bool isLiquidated;
    // total amount of USDC use to purchase VLP
    uint256 leverage;
    // record total amount of VLP
    uint256 totalAmountOfVLP;
    uint256 totalAmountOfVLPInUSDC;
    // get all deposited without leverage
    uint256 totalAmountOfUSDCWithoutLeverage;
    // store puchase price of VLP
    uint256 purchasePrice;
    // store all users in array
    address[] users;
    // store time when the sake vault is created
    uint256 startTime;
}

/**
 * @author Chef Photons, Vaultka Team serving high quality drinks; drink responsibly.
 * Factory and global config params
 */
interface IBartender {
    /* ##################################################################
                                EVENTS
    ################################################################## */
    /**
     * @dev Emitted when new `sake` contract is created by the keeper
     * with it `associatedTime`
     */
    event CreateNewSAKE(address indexed sake, uint256 indexed associatedTime);
    /**
     * @dev Emitted when new `supply` is provided and is required to be updated with `value`
     */
    event SettingManager(bytes32 supply, address value);
    /**
     * @dev Emitted when new `supply` is provided and is required to be updated with `value`
     */
    event SettingManagerForBool(bytes32 supply, bool value);

    /**
     * @dev Emitted when new `supply` is required to be updated with `value`
     */
    event SettingManagerForTripleSlope(bytes32 supply, uint256 value);

    /**
     * @dev Emitted when user deposited into the vault
     * `user` is the msg.sender
     * `amountDeposited` is the amount user deposited
     * `associatedTime` the time at which the deposit is made
     * `leverageFromWater` how much leverage was taking by the user from the WATER VAULT
     */
    event BartenderDeposit(
        address indexed user,
        uint256 amountDeposited,
        uint256 indexed associatedTime,
        uint256 indexed leverageFromWater
    );
    /**
     * @dev Emitted when user withdraw from the vault
     * `user` is the msg.sender
     * `amount` is the amount user withdraw
     * `sakeId` the id that identify each sake
     * `withdrawableAmountInVLP` how much vlp was taking and been sold for USDC
     */
    event Withdraw(
        address indexed user,
        uint256 indexed amount,
        uint256 sakeId,
        uint256 indexed withdrawableAmountInVLP
    );
    /**
     * @dev Emitted when there is need to update protocol fee
     * `feeEnabled` state of protocol fee
     */
    event ProtocolFeeStatus(bool indexed feeEnabled);
    /* ##################################################################
                                CUSTOM ERRORS
    ################################################################## */
    /// @notice Revert when caller is not SAKE
    error BTDNotSAKE();

    /// @notice Revert when caller is not Admin
    error BTDNotAKeeper();

    /// @notice Revert when caller is not Liquor
    error BTDNotLiquor();

    /// @notice Revert when input amount is zero
    error ThrowZeroAmount();

    /// @notice Revert when max deposit is exceeded
    error ThrowMaxDepositExceeded();

    /// @notice Revert when sake vault is liquidated
    error ThrowLiquidated();
    /// @notice Revert when New SAKE is not successfully created
    error UnsuccessfulCreationOfSake();

    /// @notice Revert when there is no deposit and new SAKE want to be created.
    error CurrentDepositIsZero();

    /// @notice Revert when invalid parameter is supply during
    error InvalidParameter(bytes32);

    /// @notice Revert set fee is greated than maximum fee (MAX_BPS)
    error InvalidFeeBps();

    /// @notice Revert when protocol fee is already in the current state of fee
    // error FeeAlreadySet();

    /// @notice Invalid address provided
    error ThrowZeroAddress();

    /// @notice Revert when lock time is on
    error ThrowLockTimeOn();

    /// @notice Revert when amount supplied is greater than locked amount
    error ThrowInvalidAmount();

    /// @notice Revert when amount supplied is greater than locked amount
    error SakeWitdrawal(address sake, uint256 amount);

    /// @notice Revert when the utilization ratio is greater than optimal utilization
    error ThrowOptimalUtilization();

    /// @dev When the value is greater than `MAX_BPS`
    error ThrowInvalidValue();

    // revrt when there is high utilization ratio
    error ThrowHighUtilizationRatio();

    /// @dev available params: `optimalUtilization`, `maxFeeSplitSlope1`,
    /// `maxFeeSplitSlope2`, `maxFeeSplitSLope3`, `utilizationThreshold1`,
    /// `utilizationThreshold2`, `utilizationThreshold3`
    /// @param params takes the bytes32 params name
    /// @param value takes the uint256 params value
    error ThrowInvalidParameter(bytes32 params, uint256 value);

    /// @notice deposit USDC into the Vault
    /// Requirements:
    /// {caller: anyone}.
    /// `_amount` it must be greater than 0.
    ///  user must have approve Bartender contract to spend USDC and allowance must be greater than `_amount`
    /// @param _amount amount in USDC msg.sender want to deposit to take leverage.
    /// @param _receiver recipient of $BARTENDER!.
    function deposit(uint256 _amount, address _receiver) external;

    /// @notice withdraw locked USDC from Vault
    /// Requirements:
    /// {caller: anyone}.
    /// `_amount` it must be greater than 0.
    /// `_amount` it must be less than amountDeposited.
    ///  withdrawal time must exceed numbers of time required to withdraw.
    ///  48 hours leverage must
    /// @param _amount amount in USDC msg.sender want to withdraw.
    /// @param _receiver address to recieve the `amount`.
    function withdraw(uint256 _amount, uint256 id, address _receiver) external;

    /// @notice gety current Id of BARTENDER! that has been minted
    /// @return uint256
    function getCurrentId() external view returns (uint256);

    function getSakeVaultInfo(uint256 id) external view returns (SakeVaultInfo memory);

    function depositInfo(uint256 id, address user) external view returns (UserDepositInfo memory);

    function getDebtInfo(uint256 id) external view returns (UpdatedDebtRatio memory);

    function getSakeAddress(uint256 id) external view returns (address);

    function setLiquidated(uint256 id) external returns (address sakeAddress);

    function getFeeStatus() external view returns (address, bool, uint96);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    
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
pragma solidity 0.8.18;

/**
 * @dev Interface of the VeDxp
 */
interface ITokenFarm {
    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function claimable(address _account) external view returns (uint256);

    function withdrawVesting() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

//@note this interface is actually for minting and burning, the function name is confusing
interface IVault {
    function stake(address _account, address _token, uint256 _amount) external;

    function unstake(address _tokenOut, uint256 _vlpAmount, address _receiver) external;

    function getVLPPrice() external view returns (uint256);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

/**
 * @author Chef Photons, Vaultka Team serving high quality drinks; drink responsibly.
 * Responsible for our customers not getting intoxicated
 * @notice provided interface for `Water.sol`
 */
interface IWater {
    /// @notice supply USDC to the vault
    /// @param _amount to be leveraged to Bartender (6 decimals)
    function leverageVault(uint256 _amount) external;

    /// @notice collect debt from Bartender
    /// @param _amount to be collected from Bartender (6 decimals)
    function repayDebt(uint256 _amount) external;

    function getTotalDebt() external view returns (uint256);

    function updateTotalDebt(uint256 profit) external returns (uint256);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {FeeSplitStrategy} from "./FeeSplitStrategy.sol";


/**
 * @author Chef Photons, Vaultka Team serving high quality drinks; drink responsibly.
 * Slope model for calculating the reward split mechanism
 */
library BartenderManager {
    using Math for uint128;
    using Math for uint256;

    uint256 public constant MAX_BPS = 100_000;

    struct State {
        address  velaMintBurnVault;
        address  vlp;
        address  velaStakingVault;
        address  water;
        address  keeper;
        address  liquor;
        address  feeRecipient;
        bool  feeEnabled;
        uint128  depositFeeBPS; 
        uint128  withdrawFeeBPS;
    }

    struct Adresses {
        address  velaMintBurnVault;
        address  vlp;
        address  velaStakingVault;
        address  water;
        address  keeper;
        address  liquor;
        address  feeRecipient;
    }

    struct FeeUpdate {
        bool  feeEnabled;
        uint128  depositFeeBPS; 
        uint128  withdrawFeeBPS;
    }

    /// @notice internal helper function to calculate the fee
    /// @param _params takes the bytes32 params name
    /// @param amount total fees to be transferred to fee recipient
    function calculateFees(State storage state, bytes32 _params, uint256 amount) internal view returns (uint256 fees, uint256 _amount) {
        if (!state.feeEnabled) {
            return (0, amount);
        }
        if (_params == "deposit") {
            if(state.depositFeeBPS == 0) {
                return (0, amount);
            }
            fees = amount.mulDiv(state.depositFeeBPS, MAX_BPS);
            _amount = amount - fees;
        }

        if (_params == "withdraw") {
            if(state.withdrawFeeBPS == 0) {
                return (0, amount);
            }
            fees = amount.mulDiv(state.withdrawFeeBPS, MAX_BPS);
            _amount = amount - fees;
        }
        return (fees, _amount);
    }

}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @author Chef Photons, Vaultka Team serving high quality drinks; drink responsibly.
 * Slope model for calculating the reward split mechanism
 */
library FeeSplitStrategy {
    using Math for uint128;
    using Math for uint256;

    uint256 internal constant RATE_PRECISION = 1e30;

    struct Info {
        /**
         * @dev this constant represents the utilization rate at which the vault aims to obtain most competitive borrow rates.
         * Expressed in ray
         **/
        uint128 optimalUtilizationRate;
        // slope 1 used to control the change of reward fee split when reward is inbetween  0-40%
        uint128 maxFeeSplitSlope1;
        // slope 2 used to control the change of reward fee split when reward is inbetween  40%-80%
        uint128 maxFeeSplitSlope2;
        // slope 3 used to control the change of reward fee split when reward is inbetween  80%-100%
        uint128 maxFeeSplitSlope3;
        uint128 utilizationThreshold1;
        uint128 utilizationThreshold2;
        uint128 utilizationThreshold3;
    }

    /**
     * @dev Calculates the interest rates depending on the reserve's state and configurations.
     * NOTE This function is kept for compatibility with the previous DefaultInterestRateStrategy interface.
     * New protocol implementation uses the new calculateInterestRates() interface
     * @param totalDebtInUSDC The liquidity available in the corresponding aToken
     * @param waterBalanceInUSDC The total borrowed from the reserve at a variable rate
     **/
    function calculateFeeSplit(
        Info storage feeStrategy,
        uint256 waterBalanceInUSDC,
        uint256 totalDebtInUSDC
    ) internal view returns (uint256 feeSplitRate, uint256 ur) {
        uint256 utilizationRate = getUtilizationRate(waterBalanceInUSDC, totalDebtInUSDC);
        // uint256 utilizationRate = _ratio.mulDiv(_maxBPS, RATE_PRECISION);
        if (utilizationRate <= feeStrategy.utilizationThreshold1) {
            /* Slope 1
            rewardFee_{slope2} =  
                {maxFeeSplitSlope1 *  {(utilization Ratio / URThreshold1)}}
            */
            feeSplitRate = (feeStrategy.maxFeeSplitSlope1).mulDiv(utilizationRate, feeStrategy.utilizationThreshold1);

        } else if (utilizationRate > feeStrategy.utilizationThreshold1 && utilizationRate < feeStrategy.utilizationThreshold2) {
            /* Slope 2
            rewardFee_{slope2} =  
                maxFeeSplitSlope1 + 
                {(utilization Ratio - URThreshold1) / 
                (1 - UR Threshold1 - (UR Threshold3 - URThreshold2)}
                * (maxFeeSplitSlope2 -maxFeeSplitSlope1) 
            */
            uint256 subThreshold1FromUtilizationRate = utilizationRate - feeStrategy.utilizationThreshold1;
            uint256 maxBpsSubThreshold1 = RATE_PRECISION - feeStrategy.utilizationThreshold1;
            uint256 threshold3SubThreshold2 = feeStrategy.utilizationThreshold3 - feeStrategy.utilizationThreshold2;
            uint256 mSlope2SubMSlope1 = feeStrategy.maxFeeSplitSlope2 - feeStrategy.maxFeeSplitSlope1;
            uint256 feeSlpope = maxBpsSubThreshold1 - threshold3SubThreshold2;
            uint256 split = subThreshold1FromUtilizationRate.mulDiv(
                RATE_PRECISION,
                feeSlpope
            );
            feeSplitRate = mSlope2SubMSlope1.mulDiv(split, RATE_PRECISION);
            feeSplitRate = feeSplitRate + (feeStrategy.maxFeeSplitSlope1);

        } else if (utilizationRate > feeStrategy.utilizationThreshold2 && utilizationRate < feeStrategy.utilizationThreshold3) {
            /* Slope 3
            rewardFee_{slope3} =  
                maxFeeSplitSlope2 + {(utilization Ratio - URThreshold2) / 
                (1 - UR Threshold2}
                * (maxFeeSplitSlope3 -maxFeeSplitSlope2) 
            */
            uint256 subThreshold2FromUtilirationRatio = utilizationRate - feeStrategy.utilizationThreshold2;
            uint256 maxBpsSubThreshold2 = RATE_PRECISION - feeStrategy.utilizationThreshold2;
            uint256 mSlope3SubMSlope2 = feeStrategy.maxFeeSplitSlope3 - feeStrategy.maxFeeSplitSlope2;
            uint256 split = subThreshold2FromUtilirationRatio.mulDiv(RATE_PRECISION, maxBpsSubThreshold2);
            
            feeSplitRate = (split.mulDiv(mSlope3SubMSlope2, RATE_PRECISION)) + (feeStrategy.maxFeeSplitSlope2);
        }
        return (feeSplitRate, utilizationRate);
    }

    function getUtilizationRate(uint256 waterBalanceInUSDC, uint256 totalDebtInUSDC) internal pure returns (uint256) {
        return totalDebtInUSDC == 0 ? 0 : totalDebtInUSDC.mulDiv(RATE_PRECISION, waterBalanceInUSDC + totalDebtInUSDC);
    }
    
}
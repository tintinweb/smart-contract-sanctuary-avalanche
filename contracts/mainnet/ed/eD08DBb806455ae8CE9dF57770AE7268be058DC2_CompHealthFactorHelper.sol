// SPDX-License-Identifier: MIT

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import {IComptroller} from "IComptroller.sol";
import {ICToken} from "ICToken.sol";
import {IOracle} from "IOracle.sol";
import "Expotential.sol";
import "ExponentialNoError.sol";

contract CompHealthFactorHelper is ExponentialNoError {

    struct AccountLiquidityLocalVars {
        uint sumCollateral;
        uint sumBorrow;
        uint qiTokenBalance;
        uint borrowBalance;
        uint exchangeRateMantissa;
        uint oraclePriceMantissa;
        Exp collateralFactor;
        Exp exchangeRate;
        Exp oraclePrice;
        Exp tokensToDenom;
    }

    function compHealthFactor(address _comptroller, address account) public view returns(uint256) {
        uint oErr;
        AccountLiquidityLocalVars memory vars;
        IComptroller comptroller = IComptroller(_comptroller);
        address[] memory cTokens = comptroller.getAllMarkets();
        for (uint i = 0; i < cTokens.length; i++) {
            ICToken asset = ICToken(cTokens[i]);

            // Read the balances and exchange rate from the qiToken
            (oErr, vars.qiTokenBalance, vars.borrowBalance, vars.exchangeRateMantissa) = asset.getAccountSnapshot(account);
            require(oErr == 0);// semi-opaque error code, we assume NO_ERROR == 0 is invariant between upgrades
            (,uint256 collateralFactorMantissa, ) = comptroller.markets(address(asset));
            vars.collateralFactor = Exp({mantissa: collateralFactorMantissa});
            vars.exchangeRate = Exp({mantissa: vars.exchangeRateMantissa});

            // Get the normalized price of the asset
            vars.oraclePriceMantissa = IOracle(comptroller.oracle()).getUnderlyingPrice(address(asset));
            require(vars.oraclePriceMantissa != 0);

            vars.oraclePrice = Exp({mantissa: vars.oraclePriceMantissa});

            // Pre-compute a conversion factor from tokens -> avax (normalized price value)
            vars.tokensToDenom = mul_(mul_(vars.collateralFactor, vars.exchangeRate), vars.oraclePrice);

            // sumCollateral += tokensToDenom * qiTokenBalance
            vars.sumCollateral = mul_ScalarTruncateAddUInt(vars.tokensToDenom, vars.qiTokenBalance, vars.sumCollateral);

            // sumBorrow += oraclePrice * borrowBalance
            vars.sumBorrow = mul_ScalarTruncateAddUInt(vars.oraclePrice, vars.borrowBalance, vars.sumBorrow);
        }

        return div_(mul_(vars.sumCollateral, 1e18), vars.sumBorrow);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

interface IComptroller {
//   function _become ( address unitroller ) external;
//   function _borrowGuardianPaused (  ) external view returns ( bool );
//   function _grantQi ( address recipient, uint256 amount ) external;
//   function _mintGuardianPaused (  ) external view returns ( bool );
//   function _setBorrowCapGuardian ( address newBorrowCapGuardian ) external;
//   function _setBorrowPaused ( address qiToken, bool state ) external returns ( bool );
//   function _setCloseFactor ( uint256 newCloseFactorMantissa ) external returns ( uint256 );
//   function _setCollateralFactor ( address qiToken, uint256 newCollateralFactorMantissa ) external returns ( uint256 );
//   function _setLiquidationIncentive ( uint256 newLiquidationIncentiveMantissa ) external returns ( uint256 );
//   function _setMarketBorrowCaps ( address[] qiTokens, uint256[] newBorrowCaps ) external;
//   function _setMintPaused ( address qiToken, bool state ) external returns ( bool );
//   function _setPauseGuardian ( address newPauseGuardian ) external returns ( uint256 );
//   function _setPriceOracle ( address newOracle ) external returns ( uint256 );
//   function _setRewardSpeed ( uint8 rewardType, address qiToken, uint256 supplyRewardSpeed, uint256 borrowRewardSpeed ) external;
//   function _setSeizePaused ( bool state ) external returns ( bool );
//   function _setTransferPaused ( bool state ) external returns ( bool );
//   function _supportMarket ( address qiToken ) external returns ( uint256 );
  function accountAssets ( address, uint256 ) external view returns ( address );
  function admin (  ) external view returns ( address );
  function allMarkets ( uint256 ) external view returns ( address );
  function borrowAllowed ( address qiToken, address borrower, uint256 borrowAmount ) external returns ( uint256 );
  function borrowCapGuardian (  ) external view returns ( address );
  function borrowCaps ( address ) external view returns ( uint256 );
  function borrowGuardianPaused ( address ) external view returns ( bool );
  function borrowRewardSpeeds ( uint8, address ) external view returns ( uint256 );
  function borrowVerify ( address qiToken, address borrower, uint256 borrowAmount ) external;
  function checkMembership ( address account, address qiToken ) external view returns ( bool );
  function claimReward ( uint8 rewardType, address holder ) external;
  // function claimReward ( uint8 rewardType, address holder, address[] qiTokens ) external;
  // function claimReward ( uint8 rewardType, address[] holders, address[] qiTokens, bool borrowers, bool suppliers ) external payable;
  function closeFactorMantissa (  ) external view returns ( uint256 );
  function comptrollerImplementation (  ) external view returns ( address );
  // function enterMarkets ( address[] qiTokens ) external returns ( uint256[] );
  function exitMarket ( address qiTokenAddress ) external returns ( uint256 );
  function getAccountLiquidity ( address account ) external view returns ( uint256, uint256, uint256 );
  function getAllMarkets (  ) external view returns ( address[] memory );
  // function getAssetsIn ( address account ) external view returns ( address[] );
  function getBlockTimestamp (  ) external view returns ( uint256 );
  function getHypotheticalAccountLiquidity ( address account, address qiTokenModify, uint256 redeemTokens, uint256 borrowAmount ) external view returns ( uint256, uint256, uint256 );
  function initialIndexConstant (  ) external view returns ( uint224 );
  function isComptroller (  ) external view returns ( bool );
  function liquidateBorrowAllowed ( address qiTokenBorrowed, address qiTokenCollateral, address liquidator, address borrower, uint256 repayAmount ) external returns ( uint256 );
  function liquidateBorrowVerify ( address qiTokenBorrowed, address qiTokenCollateral, address liquidator, address borrower, uint256 actualRepayAmount, uint256 seizeTokens ) external;
  function liquidateCalculateSeizeTokens ( address qiTokenBorrowed, address qiTokenCollateral, uint256 actualRepayAmount ) external view returns ( uint256, uint256 );
  function liquidationIncentiveMantissa (  ) external view returns ( uint256 );
  function markets ( address ) external view returns ( bool isListed, uint256 collateralFactorMantissa, bool isQied );
  function maxAssets (  ) external view returns ( uint256 );
  function mintAllowed ( address qiToken, address minter, uint256 mintAmount ) external returns ( uint256 );
  function mintGuardianPaused ( address ) external view returns ( bool );
  function mintVerify ( address qiToken, address minter, uint256 actualMintAmount, uint256 mintTokens ) external;
  function oracle (  ) external view returns ( address );
  function pauseGuardian (  ) external view returns ( address );
  function pendingAdmin (  ) external view returns ( address );
  function pendingComptrollerImplementation (  ) external view returns ( address );
  function qiAddress (  ) external view returns ( address );
  function redeemAllowed ( address qiToken, address redeemer, uint256 redeemTokens ) external returns ( uint256 );
  function redeemVerify ( address qiToken, address redeemer, uint256 redeemAmount, uint256 redeemTokens ) external;
  function repayBorrowAllowed ( address qiToken, address payer, address borrower, uint256 repayAmount ) external returns ( uint256 );
  function repayBorrowVerify ( address qiToken, address payer, address borrower, uint256 actualRepayAmount, uint256 borrowerIndex ) external;
  function rewardAccrued ( uint8, address ) external view returns ( uint256 );
  function rewardAvax (  ) external view returns ( uint8 );
  function rewardBorrowState ( uint8, address ) external view returns ( uint224 index, uint32 timestamp );
  function rewardBorrowerIndex ( uint8, address, address ) external view returns ( uint256 );
  function rewardQi (  ) external view returns ( uint8 );
  function rewardSupplierIndex ( uint8, address, address ) external view returns ( uint256 );
  function rewardSupplyState ( uint8, address ) external view returns ( uint224 index, uint32 timestamp );
  function seizeAllowed ( address qiTokenCollateral, address qiTokenBorrowed, address liquidator, address borrower, uint256 seizeTokens ) external returns ( uint256 );
  function seizeGuardianPaused (  ) external view returns ( bool );
  function seizeVerify ( address qiTokenCollateral, address qiTokenBorrowed, address liquidator, address borrower, uint256 seizeTokens ) external;
  function setQiAddress ( address newQiAddress ) external;
  function supplyRewardSpeeds ( uint8, address ) external view returns ( uint256 );
  function transferAllowed ( address qiToken, address src, address dst, uint256 transferTokens ) external returns ( uint256 );
  function transferGuardianPaused (  ) external view returns ( bool );
  function transferVerify ( address qiToken, address src, address dst, uint256 transferTokens ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

interface ICToken {
//   function _acceptAdmin (  ) external returns ( uint256 );
//   function _addReserves (  ) external payable returns ( uint256 );
//   function _reduceReserves ( uint256 reduceAmount ) external returns ( uint256 );
//   function _setComptroller ( address newComptroller ) external returns ( uint256 );
//   function _setInterestRateModel ( address newInterestRateModel ) external returns ( uint256 );
//   function _setPendingAdmin ( address newPendingAdmin ) external returns ( uint256 );
//   function _setProtocolSeizeShare ( uint256 newProtocolSeizeShareMantissa ) external returns ( uint256 );
//   function _setReserveFactor ( uint256 newReserveFactorMantissa ) external returns ( uint256 );
  function accrualBlockTimestamp (  ) external view returns ( uint256 );
  function accrueInterest (  ) external returns ( uint256 );
  function admin (  ) external view returns ( address );
  function allowance ( address owner, address spender ) external view returns ( uint256 );
  function approve ( address spender, uint256 amount ) external returns ( bool );
  function balanceOf ( address owner ) external view returns ( uint256 );
  function balanceOfUnderlying ( address owner ) external returns ( uint256 );
  function borrow ( uint256 borrowAmount ) external returns ( uint256 );
  function borrowBalanceCurrent ( address account ) external returns ( uint256 );
  function borrowBalanceStored ( address account ) external view returns ( uint256 );
  function borrowIndex (  ) external view returns ( uint256 );
  function borrowRatePerTimestamp (  ) external view returns ( uint256 );
  function comptroller (  ) external view returns ( address );
  function decimals (  ) external view returns ( uint8 );
  function exchangeRateCurrent (  ) external returns ( uint256 );
  function exchangeRateStored (  ) external view returns ( uint256 );
  function getAccountSnapshot ( address account ) external view returns ( uint256, uint256, uint256, uint256 );
  function getCash (  ) external view returns ( uint256 );
//   function initialize ( address comptroller_, address interestRateModel_, uint256 initialExchangeRateMantissa_, string name_, string symbol_, uint8 decimals_ ) external;
  function interestRateModel (  ) external view returns ( address );
  function isQiToken (  ) external view returns ( bool );
  function liquidateBorrow ( address borrower, address qiTokenCollateral ) external payable;
  function mint (  ) external payable;
//   function name (  ) external view returns ( string );
  function pendingAdmin (  ) external view returns ( address );
  function protocolSeizeShareMantissa (  ) external view returns ( uint256 );
  function redeem ( uint256 redeemTokens ) external returns ( uint256 );
  function redeemUnderlying ( uint256 redeemAmount ) external returns ( uint256 );
  function repayBorrow (  ) external payable;
  function repayBorrowBehalf ( address borrower ) external payable;
  function reserveFactorMantissa (  ) external view returns ( uint256 );
  function seize ( address liquidator, address borrower, uint256 seizeTokens ) external returns ( uint256 );
  function supplyRatePerTimestamp (  ) external view returns ( uint256 );
//   function symbol (  ) external view returns ( string );
  function totalBorrows (  ) external view returns ( uint256 );
  function totalBorrowsCurrent (  ) external returns ( uint256 );
  function totalReserves (  ) external view returns ( uint256 );
  function totalSupply (  ) external view returns ( uint256 );
  function transfer ( address dst, uint256 amount ) external returns ( bool );
  function transferFrom ( address src, address dst, uint256 amount ) external returns ( bool );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

interface IOracle {
  function admin (  ) external view returns ( address );
  function assetPrices ( address asset ) external view returns ( uint256 );
//   function getFeed ( string symbol ) external view returns ( address );
  function getUnderlyingPrice ( address qiToken ) external view returns ( uint256 );
  function isPriceOracle (  ) external view returns ( bool );
  function setAdmin ( address newAdmin ) external;
  function setDirectPrice ( address asset, uint256 price ) external;
//   function setFeed ( string symbol, address feed ) external;
  function setUnderlyingPrice ( address qiToken, uint256 underlyingPriceMantissa ) external;
}

pragma solidity 0.5.17;

import "CarefulMath.sol";
import "ExponentialNoError.sol";

/**
 * @title Exponential module for storing fixed-precision decimals
 * @author Benqi
 * @dev Legacy contract for compatibility reasons with existing contracts that still use MathError
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract Exponential is CarefulMath, ExponentialNoError {
    /**
     * @dev Creates an exponential from numerator and denominator values.
     *      Note: Returns an error if (`num` * 10e18) > MAX_INT,
     *            or if `denom` is zero.
     */
    function getExp(uint num, uint denom) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint scaledNumerator) = mulUInt(num, expScale);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        (MathError err1, uint rational) = divUInt(scaledNumerator, denom);
        if (err1 != MathError.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: rational}));
    }

    /**
     * @dev Adds two exponentials, returning a new exponential.
     */
    function addExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
        (MathError error, uint result) = addUInt(a.mantissa, b.mantissa);

        return (error, Exp({mantissa: result}));
    }

    /**
     * @dev Subtracts two exponentials, returning a new exponential.
     */
    function subExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
        (MathError error, uint result) = subUInt(a.mantissa, b.mantissa);

        return (error, Exp({mantissa: result}));
    }

    /**
     * @dev Multiply an Exp by a scalar, returning a new Exp.
     */
    function mulScalar(Exp memory a, uint scalar) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint scaledMantissa) = mulUInt(a.mantissa, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: scaledMantissa}));
    }

    /**
     * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
     */
    function mulScalarTruncate(Exp memory a, uint scalar) pure internal returns (MathError, uint) {
        (MathError err, Exp memory product) = mulScalar(a, scalar);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return (MathError.NO_ERROR, truncate(product));
    }

    /**
     * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
     */
    function mulScalarTruncateAddUInt(Exp memory a, uint scalar, uint addend) pure internal returns (MathError, uint) {
        (MathError err, Exp memory product) = mulScalar(a, scalar);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return addUInt(truncate(product), addend);
    }

    /**
     * @dev Divide an Exp by a scalar, returning a new Exp.
     */
    function divScalar(Exp memory a, uint scalar) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint descaledMantissa) = divUInt(a.mantissa, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: descaledMantissa}));
    }

    /**
     * @dev Divide a scalar by an Exp, returning a new Exp.
     */
    function divScalarByExp(uint scalar, Exp memory divisor) pure internal returns (MathError, Exp memory) {
        /*
          We are doing this as:
          getExp(mulUInt(expScale, scalar), divisor.mantissa)

          How it works:
          Exp = a / b;
          Scalar = s;
          `s / (a / b)` = `b * s / a` and since for an Exp `a = mantissa, b = expScale`
        */
        (MathError err0, uint numerator) = mulUInt(expScale, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }
        return getExp(numerator, divisor.mantissa);
    }

    /**
     * @dev Divide a scalar by an Exp, then truncate to return an unsigned integer.
     */
    function divScalarByExpTruncate(uint scalar, Exp memory divisor) pure internal returns (MathError, uint) {
        (MathError err, Exp memory fraction) = divScalarByExp(scalar, divisor);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return (MathError.NO_ERROR, truncate(fraction));
    }

    /**
     * @dev Multiplies two exponentials, returning a new exponential.
     */
    function mulExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {

        (MathError err0, uint doubleScaledProduct) = mulUInt(a.mantissa, b.mantissa);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        // We add half the scale before dividing so that we get rounding instead of truncation.
        //  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717
        // Without this change, a result like 6.6...e-19 will be truncated to 0 instead of being rounded to 1e-18.
        (MathError err1, uint doubleScaledProductWithHalfScale) = addUInt(halfExpScale, doubleScaledProduct);
        if (err1 != MathError.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }

        (MathError err2, uint product) = divUInt(doubleScaledProductWithHalfScale, expScale);
        // The only error `div` can return is MathError.DIVISION_BY_ZERO but we control `expScale` and it is not zero.
        assert(err2 == MathError.NO_ERROR);

        return (MathError.NO_ERROR, Exp({mantissa: product}));
    }

    /**
     * @dev Multiplies two exponentials given their mantissas, returning a new exponential.
     */
    function mulExp(uint a, uint b) pure internal returns (MathError, Exp memory) {
        return mulExp(Exp({mantissa: a}), Exp({mantissa: b}));
    }

    /**
     * @dev Multiplies three exponentials, returning a new exponential.
     */
    function mulExp3(Exp memory a, Exp memory b, Exp memory c) pure internal returns (MathError, Exp memory) {
        (MathError err, Exp memory ab) = mulExp(a, b);
        if (err != MathError.NO_ERROR) {
            return (err, ab);
        }
        return mulExp(ab, c);
    }

    /**
     * @dev Divides two exponentials, returning a new exponential.
     *     (a/scale) / (b/scale) = (a/scale) * (scale/b) = a/b,
     *  which we can scale as an Exp by calling getExp(a.mantissa, b.mantissa)
     */
    function divExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
        return getExp(a.mantissa, b.mantissa);
    }
}

pragma solidity 0.5.17;

/**
  * @title Careful Math
  * @author Benqi
  * @notice Derived from OpenZeppelin's SafeMath library
  *         https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol
  */
contract CarefulMath {

    /**
     * @dev Possible error codes that we can return
     */
    enum MathError {
        NO_ERROR,
        DIVISION_BY_ZERO,
        INTEGER_OVERFLOW,
        INTEGER_UNDERFLOW
    }

    /**
    * @dev Multiplies two numbers, returns an error on overflow.
    */
    function mulUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (a == 0) {
            return (MathError.NO_ERROR, 0);
        }

        uint c = a * b;

        if (c / a != b) {
            return (MathError.INTEGER_OVERFLOW, 0);
        } else {
            return (MathError.NO_ERROR, c);
        }
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function divUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (b == 0) {
            return (MathError.DIVISION_BY_ZERO, 0);
        }

        return (MathError.NO_ERROR, a / b);
    }

    /**
    * @dev Subtracts two numbers, returns an error on overflow (i.e. if subtrahend is greater than minuend).
    */
    function subUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (b <= a) {
            return (MathError.NO_ERROR, a - b);
        } else {
            return (MathError.INTEGER_UNDERFLOW, 0);
        }
    }

    /**
    * @dev Adds two numbers, returns an error on overflow.
    */
    function addUInt(uint a, uint b) internal pure returns (MathError, uint) {
        uint c = a + b;

        if (c >= a) {
            return (MathError.NO_ERROR, c);
        } else {
            return (MathError.INTEGER_OVERFLOW, 0);
        }
    }

    /**
    * @dev add a and b and then subtract c
    */
    function addThenSubUInt(uint a, uint b, uint c) internal pure returns (MathError, uint) {
        (MathError err0, uint sum) = addUInt(a, b);

        if (err0 != MathError.NO_ERROR) {
            return (err0, 0);
        }

        return subUInt(sum, c);
    }
}

pragma solidity 0.5.17;

/**
 * @title Exponential module for storing fixed-precision decimals
 * @author Benqi
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract ExponentialNoError {
    uint constant expScale = 1e18;
    uint constant doubleScale = 1e36;
    uint constant halfExpScale = expScale/2;
    uint constant mantissaOne = expScale;

    struct Exp {
        uint mantissa;
    }

    struct Double {
        uint mantissa;
    }

    /**
     * @dev Truncates the given exp to a whole number value.
     *      For example, truncate(Exp{mantissa: 15 * expScale}) = 15
     */
    function truncate(Exp memory exp) pure internal returns (uint) {
        // Note: We are not using careful math here as we're performing a division that cannot fail
        return exp.mantissa / expScale;
    }

    /**
     * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
     */
    function mul_ScalarTruncate(Exp memory a, uint scalar) pure internal returns (uint) {
        Exp memory product = mul_(a, scalar);
        return truncate(product);
    }

    /**
     * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
     */
    function mul_ScalarTruncateAddUInt(Exp memory a, uint scalar, uint addend) pure internal returns (uint) {
        Exp memory product = mul_(a, scalar);
        return add_(truncate(product), addend);
    }

    /**
     * @dev Checks if first Exp is less than second Exp.
     */
    function lessThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa < right.mantissa;
    }

    /**
     * @dev Checks if left Exp <= right Exp.
     */
    function lessThanOrEqualExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa <= right.mantissa;
    }

    /**
     * @dev Checks if left Exp > right Exp.
     */
    function greaterThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa > right.mantissa;
    }

    /**
     * @dev returns true if Exp is exactly zero
     */
    function isZeroExp(Exp memory value) pure internal returns (bool) {
        return value.mantissa == 0;
    }

    function safe224(uint n, string memory errorMessage) pure internal returns (uint224) {
        require(n < 2**224, errorMessage);
        return uint224(n);
    }

    function safe32(uint n, string memory errorMessage) pure internal returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function add_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: add_(a.mantissa, b.mantissa)});
    }

    function add_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: add_(a.mantissa, b.mantissa)});
    }

    function add_(uint a, uint b) pure internal returns (uint) {
        return add_(a, b, "addition overflow");
    }

    function add_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        uint c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: sub_(a.mantissa, b.mantissa)});
    }

    function sub_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: sub_(a.mantissa, b.mantissa)});
    }

    function sub_(uint a, uint b) pure internal returns (uint) {
        return sub_(a, b, "subtraction underflow");
    }

    function sub_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function mul_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b.mantissa) / expScale});
    }

    function mul_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b)});
    }

    function mul_(uint a, Exp memory b) pure internal returns (uint) {
        return mul_(a, b.mantissa) / expScale;
    }

    function mul_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b.mantissa) / doubleScale});
    }

    function mul_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b)});
    }

    function mul_(uint a, Double memory b) pure internal returns (uint) {
        return mul_(a, b.mantissa) / doubleScale;
    }

    function mul_(uint a, uint b) pure internal returns (uint) {
        return mul_(a, b, "multiplication overflow");
    }

    function mul_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        if (a == 0 || b == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b, errorMessage);
        return c;
    }

    function div_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: div_(mul_(a.mantissa, expScale), b.mantissa)});
    }

    function div_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa: div_(a.mantissa, b)});
    }

    function div_(uint a, Exp memory b) pure internal returns (uint) {
        return div_(mul_(a, expScale), b.mantissa);
    }

    function div_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: div_(mul_(a.mantissa, doubleScale), b.mantissa)});
    }

    function div_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: div_(a.mantissa, b)});
    }

    function div_(uint a, Double memory b) pure internal returns (uint) {
        return div_(mul_(a, doubleScale), b.mantissa);
    }

    function div_(uint a, uint b) pure internal returns (uint) {
        return div_(a, b, "divide by zero");
    }

    function div_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function fraction(uint a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: div_(mul_(a, doubleScale), b)});
    }
}
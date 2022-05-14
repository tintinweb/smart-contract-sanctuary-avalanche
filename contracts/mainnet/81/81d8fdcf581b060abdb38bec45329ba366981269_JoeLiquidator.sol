/**
 *Submitted for verification at snowtrace.io on 2022-05-14
*/

// File: github/0xnivek/joe-liquidator/liquidator/contracts/libraries/SafeMath.sol


pragma solidity ^0.8.3;

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: github/0xnivek/joe-liquidator/liquidator/contracts/lending/Exponential.sol


pragma solidity ^0.8.3;

/**
 * @title Exponential module for storing fixed-precision decimals
 * @author Compound
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract Exponential {
    uint256 constant expScale = 1e18;
    uint256 constant doubleScale = 1e36;
    uint256 constant halfExpScale = expScale / 2;
    uint256 constant mantissaOne = expScale;

    struct Exp {
        uint256 mantissa;
    }

    /**
     * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
     */
    function mul_ScalarTruncate(Exp memory a, uint256 scalar)
        internal
        pure
        returns (uint256)
    {
        Exp memory product = mul_(a, scalar);
        return truncate(product);
    }

    function mul_(Exp memory a, uint256 b) internal pure returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b)});
    }

    function mul_(uint256 a, uint256 b) internal pure returns (uint256) {
        return mul_(a, b, "multiplication overflow");
    }

    function mul_(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, errorMessage);
        return c;
    }

    /**
     * @dev Truncates the given exp to a whole number value.
     *      For example, truncate(Exp{mantissa: 15 * expScale}) = 15
     */
    function truncate(Exp memory exp) internal pure returns (uint256) {
        // Note: We are not using careful math here as we're performing a division that cannot fail
        return exp.mantissa / expScale;
    }
}

// File: github/0xnivek/joe-liquidator/liquidator/contracts/lending/JoeRouter02.sol


pragma solidity ^0.8.3;

interface JoeRouter02 {
    function getAmountsIn(uint256 amountOut, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
}

// File: github/0xnivek/joe-liquidator/liquidator/contracts/interfaces/WAVAXInterface.sol


pragma solidity ^0.8.3;

interface WAVAXInterface {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;

    function balanceOf(address account) external view returns (uint256);

    function approve(address guy, uint256 wad) external returns (bool);
}

// File: github/0xnivek/joe-liquidator/liquidator/contracts/interfaces/ERC3156FlashBorrowerInterface.sol


pragma solidity ^0.8.3;

interface ERC3156FlashBorrowerInterface {
    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

// File: github/0xnivek/joe-liquidator/liquidator/contracts/lending/JTokenInterfaces.sol


pragma solidity ^0.8.3;


interface JTokenStorage {
    function totalBorrows() external view returns (uint256);

    /**
     * @notice Block timestamp that interest was last accrued at
     */
    function accrualBlockTimestamp() external view returns (uint256);
}

interface JTokenInterface is JTokenStorage {
    function balanceOf(address owner) external view returns (uint256);

    function balanceOfUnderlying(address owner) external view returns (uint256);

    function borrowRatePerSecond() external view returns (uint256);

    function supplyRatePerSecond() external view returns (uint256);

    function borrowBalanceCurrent(address account)
        external
        view
        returns (uint256);

    function borrowBalanceStored(address account)
        external
        view
        returns (uint256);

    function accrueInterest() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);
}

interface JToken is JTokenInterface {}

interface JErc20Storage {
    function underlying() external returns (address);
}

interface JErc20Interface is JErc20Storage {
    function liquidateBorrow(
        address borrower,
        uint256 repayAmount,
        JTokenInterface jTokenCollateral
    ) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function mint(uint256 mintAmount) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);
}

interface JWrappedNativeInterface is JErc20Interface {
    function flashLoan(
        ERC3156FlashBorrowerInterface receiver,
        address initiator,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);

    function liquidateBorrowNative(
        address borrower,
        JTokenInterface jTokenCollateral
    ) external payable returns (uint256);

    function redeemNative(uint256 redeemTokens) external returns (uint256);

    function mintNative() external payable returns (uint256);

    function borrowNative(uint256 borrowAmount) external returns (uint256);
}

interface JWrappedNativeDelegator is JTokenInterface, JWrappedNativeInterface {}

interface JCollateralCapErc20Interface is JErc20Interface {
    function flashLoan(
        ERC3156FlashBorrowerInterface receiver,
        address initiator,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

interface JCollateralCapErc20Delegator is
    JTokenInterface,
    JCollateralCapErc20Interface
{}

// File: github/0xnivek/joe-liquidator/liquidator/contracts/lending/PriceOracle.sol


pragma solidity ^0.8.3;


interface PriceOracle {
    /**
     * @notice Get the underlying price of a jToken asset
     * @param jToken The jToken to get the underlying price of
     * @return The underlying asset price mantissa (scaled by 1e18).
     *  Zero means the price is unavailable.
     */
    function getUnderlyingPrice(JToken jToken) external view returns (uint256);
}

// File: github/0xnivek/joe-liquidator/liquidator/contracts/lending/JoetrollerInterface.sol


pragma solidity ^0.8.3;



interface JoetrollerV1Storage {
    /**
     * @notice Oracle which gives the price of any given asset
     */
    function oracle() external view returns (PriceOracle);

    /**
     * @notice Multiplier used to calculate the maximum repayAmount when liquidating a borrow
     */
    function closeFactorMantissa() external view returns (uint256);

    /**
     * @notice Multiplier representing the discount on collateral that a liquidator receives
     */
    function liquidationIncentiveMantissa() external view returns (uint256);
}

interface Joetroller is JoetrollerV1Storage {
    function enterMarkets(address[] calldata jTokens)
        external
        returns (uint256[] memory);

    function isMarketListed(address jTokenAddress) external view returns (bool);

    function checkMembership(address account, JToken jToken)
        external
        view
        returns (bool);

    function getAccountLiquidity(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function liquidateBorrowAllowed(
        address jTokenBorrowed,
        address jTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);

    function repayBorrowAllowed(
        address jToken,
        address payer,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);
}

// File: github/0xnivek/joe-liquidator/liquidator/contracts/interfaces/ERC3156FlashLenderInterface.sol


pragma solidity ^0.8.3;


interface ERC3156FlashLenderInterface {
    /**
     * @dev The amount of currency available to be lent.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount)
        external
        view
        returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        ERC3156FlashBorrowerInterface receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

// File: github/0xnivek/joe-liquidator/liquidator/contracts/interfaces/ERC20Interface.sol


pragma solidity ^0.8.3;

interface ERC20 {
    function approve(address spender, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);
}

// File: github/0xnivek/joe-liquidator/liquidator/contracts/JoeLiquidator.sol


pragma solidity ^0.8.3;

// import "hardhat/console.sol";











/**
 * @notice Contract that performs liquidation of underwater accounts in the jToken markets
 */
contract JoeLiquidator is ERC3156FlashBorrowerInterface, Exponential {
    using SafeMath for uint256;

    /// @notice Addresses of Banker Joe contracts
    address public joetrollerAddress;
    address public joeRouter02Address;
    address public jUSDCAddress;
    address public jWETHAddress;

    /// @notice Addresses of ERC20 contracts
    address public constant WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address public constant WETH = 0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB;
    address public constant USDC = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;

    struct LiquidationLocalVars {
        address jRepayTokenAddress;
        address jSeizeTokenAddress;
        address borrowerToLiquidate;
        uint256 repayAmount;
    }

    /// @notice Emitted upon successful liquidation
    event LiquidationEvent(
        address indexed _borrowerLiquidated,
        address _jRepayToken,
        address _jSeizeToken,
        uint256 _repayAmount,
        uint256 _profitedAVAX
    );

    constructor(
        address _joetrollerAddress,
        address _joeRouter02Address,
        address _jUSDCAddress,
        address _jWETHAddress
    ) {
        joetrollerAddress = _joetrollerAddress;
        joeRouter02Address = _joeRouter02Address;
        jUSDCAddress = _jUSDCAddress;
        jWETHAddress = _jWETHAddress;
    }

    /// @dev Need to implement receive function in order for this contract to receive AVAX.
    /// We need to receive AVAX when we liquidating a native borrow position.
    receive() external payable {}

    /**
     * @notice Ensure that we can liquidate the borrower
     * @dev A borrower is liquidatable if:
     *      1. Their `liquidity` is zero
     *      2. Their `shortfall` is non-zero
     */
    modifier isLiquidatable(address _borrowerToLiquidate) {
        (, uint256 liquidity, uint256 shortfall) = Joetroller(joetrollerAddress)
            .getAccountLiquidity(_borrowerToLiquidate);
        require(
            liquidity == 0,
            "JoeLiquidator: Cannot liquidate account with non-zero liquidity"
        );
        require(
            shortfall != 0,
            "JoeLiquidator: Cannot liquidate account with zero shortfall"
        );
        _;
    }

    /**
     * @notice Liquidates a borrower with a given jToken to repay and
     * jToken to seize.
     * @param _borrowerToLiquidate: Address of the borrower to liquidate
     * @param _jRepayTokenAddress: Address of the jToken to repay
     * @param _jSeizeTokenAddress: Address of the jToken to seize
     */
    function liquidate(
        address _borrowerToLiquidate,
        address _jRepayTokenAddress,
        address _jSeizeTokenAddress
    ) external isLiquidatable(_borrowerToLiquidate) {
        uint256 amountToRepay = getAmountToRepay(
            _borrowerToLiquidate,
            _jRepayTokenAddress,
            _jSeizeTokenAddress
        );
        doFlashloan(
            _borrowerToLiquidate,
            _jRepayTokenAddress,
            _jSeizeTokenAddress,
            amountToRepay
        );
    }

    /**
     * @dev Calculates amount of the borrow position to repay
     * @param _borrowerToLiquidate: Address of the borrower to liquidate
     * @param _jRepayTokenAddress: Address of the jToken to repay
     * @param _jSeizeTokenAddress: Address of the jToken to seize
     * @return the amount of jRepayToken to repay
     */
    function getAmountToRepay(
        address _borrowerToLiquidate,
        address _jRepayTokenAddress,
        address _jSeizeTokenAddress
    ) internal view returns (uint256) {
        // Inspired from https://github.com/haydenshively/Nantucket/blob/538bd999c9cc285efb403c876e5f4c3d467a2d68/contracts/FlashLiquidator.sol#L121-L144
        Joetroller joetroller = Joetroller(joetrollerAddress);
        PriceOracle priceOracle = joetroller.oracle();

        uint256 closeFactor = joetroller.closeFactorMantissa();
        uint256 liquidationIncentive = joetroller
            .liquidationIncentiveMantissa();

        uint256 repayTokenUnderlyingPrice = priceOracle.getUnderlyingPrice(
            JToken(_jRepayTokenAddress)
        );
        uint256 seizeTokenUnderlyingPrice = priceOracle.getUnderlyingPrice(
            JToken(_jSeizeTokenAddress)
        );

        uint256 maxRepayAmount = (JTokenInterface(_jRepayTokenAddress)
            .borrowBalanceStored(_borrowerToLiquidate) * closeFactor) /
            uint256(10**18);
        uint256 maxSeizeAmount = (_getBalanceOfUnderlying(
            _jSeizeTokenAddress,
            _borrowerToLiquidate
        ) * uint256(10**18)) / liquidationIncentive;

        uint256 maxRepayAmountInUSD = maxRepayAmount *
            repayTokenUnderlyingPrice;
        uint256 maxSeizeAmountInUSD = maxSeizeAmount *
            seizeTokenUnderlyingPrice;

        uint256 maxAmountInUSD = (maxRepayAmountInUSD < maxSeizeAmountInUSD)
            ? maxRepayAmountInUSD
            : maxSeizeAmountInUSD;

        return maxAmountInUSD / repayTokenUnderlyingPrice;
    }

    /**
     * @dev Gets an account's balanceOfUnderlying (i.e. supply balance) for a given jToken
     * @param _jTokenAddress The address of a jToken contract
     * @param _account The address the account to lookup
     * @return the account's balanceOfUnderlying in jToken
     */
    function _getBalanceOfUnderlying(address _jTokenAddress, address _account)
        internal
        view
        returns (uint256)
    {
        // From https://github.com/traderjoe-xyz/joe-lending/blob/main/contracts/JToken.sol#L128
        JTokenInterface jToken = JTokenInterface(_jTokenAddress);
        Exp memory exchangeRate = Exp({mantissa: jToken.exchangeRateStored()});
        return mul_ScalarTruncate(exchangeRate, jToken.balanceOf(_account));
    }

    /**
     * @notice Performs flash loan from:
     * - jWETH if _jRepayTokenAddress == jUSDC
     * - jUSDC otherwise
     * Upon receiving the flash loan, the tokens are swapped to the tokens needed
     * to repay the borrow position and perform liquidation.
     * @param _borrowerToLiquidate The address of the borrower to liquidate
     * @param _jRepayTokenAddress The address of the jToken contract to borrow from
     * @param _jSeizeTokenAddress The address of the jToken contract to seize collateral from
     * @param _repayAmount The amount of the tokens to repay
     */
    function doFlashloan(
        address _borrowerToLiquidate,
        address _jRepayTokenAddress,
        address _jSeizeTokenAddress,
        uint256 _repayAmount
    ) internal {
        // See if the underlying repay token is USDC
        address underlyingRepayToken = JErc20Storage(_jRepayTokenAddress)
            .underlying();
        bool isRepayTokenUSDC = underlyingRepayToken == USDC;

        // Calculate the amount we need to flash loan
        uint256 flashLoanAmount = _getFlashLoanAmount(
            underlyingRepayToken,
            _repayAmount,
            isRepayTokenUSDC
        );

        // Calculate which jToken to flash loan from.
        // We will only ever flash loan from jUSDC or jWETH.
        JCollateralCapErc20Delegator jTokenToFlashLoan = _getJTokenToFlashLoan(
            isRepayTokenUSDC
        );

        bytes memory data = abi.encode(
            msg.sender, // initiator
            _borrowerToLiquidate, // borrowerToLiquidate
            _jRepayTokenAddress, // jRepayTokenAddress
            _jSeizeTokenAddress, // jSeizeTokenAddress
            jTokenToFlashLoan.underlying(), // flashLoanedTokenAddress
            flashLoanAmount, // flashLoanAmount
            _repayAmount // repayAmount
        );

        // Perform flash loan
        jTokenToFlashLoan.flashLoan(this, msg.sender, flashLoanAmount, data);
    }

    /**
     * @dev Calculates the amount needed to flash loan in order to repay
     * `_repayAmount` of the borrow position.
     * @param _underlyingRepayToken The token of the borrow position to repay
     * @param _repayAmount The amount of the borrow position to repay
     * @param _isRepayTokenUSDC Whether the token of the borrow position to repay is USDC
     * @return The flash loan amount required to repay the borrow position for liquidation.
     */
    function _getFlashLoanAmount(
        address _underlyingRepayToken,
        uint256 _repayAmount,
        bool _isRepayTokenUSDC
    ) internal view returns (uint256) {
        address[] memory path = new address[](2);

        // If the underlying repay token is USDC, we will flash loan from jWETH,
        // else we will flash loan jUSDC.
        if (_isRepayTokenUSDC) {
            path[0] = WETH;
        } else {
            path[0] = USDC;
        }
        path[1] = _underlyingRepayToken;
        return
            JoeRouter02(joeRouter02Address).getAmountsIn(_repayAmount, path)[0];
    }

    /**
     * @dev Gets the jToken to flash loan.
     * We always flash loan from jUSDC unless the repay token is USDC in which case we
     * flash loan from jWETH.
     * @param _isRepayTokenUSDC Whether the token of the borrow position to repay is USDC
     * @return The jToken to flash loan
     */
    function _getJTokenToFlashLoan(bool _isRepayTokenUSDC)
        internal
        view
        returns (JCollateralCapErc20Delegator)
    {
        if (_isRepayTokenUSDC) {
            return JCollateralCapErc20Delegator(jWETHAddress);
        } else {
            return JCollateralCapErc20Delegator(jUSDCAddress);
        }
    }

    /**
     * @dev Called by a jToken upon request of a flash loan
     * @param _initiator The address that initiated this flash loan
     * @param _flashLoanTokenAddress The address of the flash loan jToken's underlying asset
     * @param _flashLoanAmount The flash loan amount granted
     * @param _flashLoanFee The fee for this flash loan
     * @param _data The encoded data sent for this flash loan
     */
    function onFlashLoan(
        address _initiator,
        address _flashLoanTokenAddress,
        uint256 _flashLoanAmount,
        uint256 _flashLoanFee,
        bytes calldata _data
    ) external override returns (bytes32) {
        require(
            Joetroller(joetrollerAddress).isMarketListed(msg.sender),
            "JoeLiquidator: Untrusted message sender calling onFlashLoan"
        );

        LiquidationLocalVars
            memory liquidationLocalVars = _getLiquidationLocalVars(
                _initiator,
                _flashLoanTokenAddress,
                _flashLoanAmount,
                _data
            );

        uint256 flashLoanAmountToRepay = _flashLoanAmount.add(_flashLoanFee);

        // ********************************************************************
        // Our custom logic begins here...
        // ********************************************************************
        JErc20Interface jRepayToken = JErc20Interface(
            liquidationLocalVars.jRepayTokenAddress
        );

        // Swap token that we flash loaned to the token we need to repay the borrow
        // position
        _swapFlashLoanTokenToRepayToken(
            _flashLoanTokenAddress,
            _flashLoanAmount,
            jRepayToken.underlying(),
            liquidationLocalVars.repayAmount
        );

        // Perform liquidation using the underlying repay token we swapped for and
        // receive jSeizeTokens in return.
        _liquidateBorrow(
            jRepayToken,
            liquidationLocalVars.borrowerToLiquidate,
            liquidationLocalVars.repayAmount,
            JTokenInterface(liquidationLocalVars.jSeizeTokenAddress)
        );

        // Redeem jSeizeTokens for underlying seize tokens
        _redeemSeizeToken(liquidationLocalVars.jSeizeTokenAddress);

        // Swap enough seize tokens to flash loan tokens so we can repay flash loan
        // amount + flash loan fee
        _swapSeizeTokenToFlashLoanToken(
            liquidationLocalVars.jSeizeTokenAddress,
            _flashLoanTokenAddress,
            flashLoanAmountToRepay
        );

        // Convert any remaining seized token to native AVAX, unless it already is
        // AVAX, and send to liquidator
        uint256 profitedAVAX = _swapRemainingSeizedTokenToAVAX(
            _initiator,
            liquidationLocalVars.jSeizeTokenAddress
        );

        require(
            profitedAVAX > 0,
            "JoeLiquidator: Expected to have profited from liquidation"
        );

        // ********************************************************************
        // Our custom logic ends here...
        // ********************************************************************

        // Approve flash loan lender to retrieve loan amount + fee from us
        _approveFlashLoanToken(_flashLoanTokenAddress, flashLoanAmountToRepay);

        // Emit event to indicate successful liquidation
        emit LiquidationEvent(
            liquidationLocalVars.borrowerToLiquidate,
            liquidationLocalVars.jRepayTokenAddress,
            liquidationLocalVars.jSeizeTokenAddress,
            liquidationLocalVars.repayAmount,
            profitedAVAX
        );

        return keccak256("ERC3156FlashBorrowerInterface.onFlashLoan");
    }

    /**
     * @dev Decodes the encoded `_data` and packs relevant data needed to perform
     * liquidation into a `LiquidationLocalVars` struct.
     * @param _initiator The address that initiated this flash loan
     * @param _flashLoanTokenAddress The address of the flash loan jToken's underlying asset
     * @param _flashLoanAmount The amount flash loaned
     * @param _data The encoded data sent for this flash loan
     * @return relevant decoded data needed to perform liquidation
     */
    function _getLiquidationLocalVars(
        address _initiator,
        address _flashLoanTokenAddress,
        uint256 _flashLoanAmount,
        bytes calldata _data
    ) internal pure returns (LiquidationLocalVars memory) {
        (
            address initiator,
            address borrowerToLiquidate,
            address jRepayTokenAddress,
            address jSeizeTokenAddress,
            address flashLoanedTokenAddress,
            uint256 flashLoanAmount,
            uint256 repayAmount
        ) = abi.decode(
                _data,
                (address, address, address, address, address, uint256, uint256)
            );

        // Validate encoded data
        require(
            _initiator == initiator,
            "JoeLiquidator: Untrusted loan initiator"
        );
        require(
            _flashLoanTokenAddress == flashLoanedTokenAddress,
            "JoeLiquidator: Encoded data (flashLoanedTokenAddress) does not match"
        );
        require(
            _flashLoanAmount == flashLoanAmount,
            "JoeLiquidator: Encoded data (flashLoanAmount) does not match"
        );

        LiquidationLocalVars
            memory liquidationLocalVars = LiquidationLocalVars({
                borrowerToLiquidate: borrowerToLiquidate,
                jRepayTokenAddress: jRepayTokenAddress,
                jSeizeTokenAddress: jSeizeTokenAddress,
                repayAmount: repayAmount
            });
        return liquidationLocalVars;
    }

    /**
     * @dev Swaps the flash loan token to the token needed to repay the borrow position
     * @param _flashLoanedTokenAddress The address of the flash loan jToken's underlying asset
     * @param _flashLoanAmount The amount flash loaned
     * @param _jRepayTokenUnderlyingAddress The address of the jToken to repay's underlying asset
     * @param _repayAmount The amount of the borrow position to repay
     */
    function _swapFlashLoanTokenToRepayToken(
        address _flashLoanedTokenAddress,
        uint256 _flashLoanAmount,
        address _jRepayTokenUnderlyingAddress,
        uint256 _repayAmount
    ) internal {
        // Approve JoeRouter to transfer our flash loaned token so that we can swap for
        // the underlying repay token
        ERC20(_flashLoanedTokenAddress).approve(
            joeRouter02Address,
            _flashLoanAmount
        );

        address[] memory swapPath = new address[](2);
        swapPath[0] = _flashLoanedTokenAddress;
        swapPath[1] = _jRepayTokenUnderlyingAddress;

        bool isRepayNative = _jRepayTokenUnderlyingAddress == WAVAX;

        // Swap flashLoanedToken to jRepayTokenUnderlying
        if (isRepayNative) {
            JoeRouter02(joeRouter02Address).swapExactTokensForAVAX(
                _flashLoanAmount, // amountIn
                _repayAmount, // amountOutMin
                swapPath, // path
                address(this), // to
                block.timestamp // deadline
            );
        } else {
            JoeRouter02(joeRouter02Address).swapExactTokensForTokens(
                _flashLoanAmount, // amountIn
                _repayAmount, // amountOutMin
                swapPath, // path
                address(this), // to
                block.timestamp // deadline
            );
        }
    }

    /**
     * @dev Performs liquidation given:
     * - a borrower
     * - a borrow position to repay
     * - a supply position to seize
     * @param _jRepayToken The jToken to repay for liquidation
     * @param _borrowerToLiquidate The borrower to liquidate
     * @param _repayAmount The amount of _jRepayToken's underlying assset to repay
     * @param _jSeizeToken The jToken to seize collateral from
     */
    function _liquidateBorrow(
        JErc20Interface _jRepayToken,
        address _borrowerToLiquidate,
        uint256 _repayAmount,
        JTokenInterface _jSeizeToken
    ) internal {
        bool isRepayNative = _jRepayToken.underlying() == WAVAX;

        // We should have at least `_repayAmount` of underlying repay tokens from
        // swapping the flash loan tokens.
        uint256 repayTokenBalance = isRepayNative
            ? address(this).balance
            : ERC20(_jRepayToken.underlying()).balanceOf(address(this));
        require(
            repayTokenBalance >= _repayAmount,
            "JoeLiquidator: Expected to have enough underlying repay token to liquidate borrow position."
        );

        uint256 err;
        if (isRepayNative) {
            // Perform liquidation and receive jAVAX in return
            err = JWrappedNativeInterface(address(_jRepayToken))
                .liquidateBorrowNative{value: _repayAmount}(
                _borrowerToLiquidate,
                _jSeizeToken
            );
        } else {
            // Approve repay jToken to take our underlying repay tokens so that we
            // can perform liquidation
            ERC20(_jRepayToken.underlying()).approve(
                address(_jRepayToken),
                _repayAmount
            );

            // Perform liquidation and receive jSeizeTokens in return
            err = _jRepayToken.liquidateBorrow(
                _borrowerToLiquidate,
                _repayAmount,
                _jSeizeToken
            );
        }
        require(
            err == 0,
            "JoeLiquidator: Error occurred trying to liquidateBorrow"
        );
    }

    /**
     * @dev Seizes collateral from a jToken market after having successfully performed
     * liquidation
     * @param _jSeizeTokenAddress The address of the jToken to seize collateral from
     */
    function _redeemSeizeToken(address _jSeizeTokenAddress) internal {
        // Get amount of jSeizeToken's we have
        uint256 amountOfJSeizeTokensToRedeem = JTokenInterface(
            _jSeizeTokenAddress
        ).balanceOf(address(this));

        JErc20Interface jSeizeToken = JErc20Interface(_jSeizeTokenAddress);

        bool isSeizeNative = jSeizeToken.underlying() == WAVAX;

        // Redeem `amountOfJSeizeTokensToRedeem` jSeizeTokens for underlying seize tokens
        uint256 err;
        if (isSeizeNative) {
            err = JWrappedNativeInterface(_jSeizeTokenAddress).redeemNative(
                amountOfJSeizeTokensToRedeem
            );
        } else {
            err = jSeizeToken.redeem(amountOfJSeizeTokensToRedeem);
        }

        require(
            err == 0,
            "JoeLiquidator: Error occurred trying to redeem underlying seize tokens"
        );
    }

    /**
     * @dev Swaps enough of the seized collateral to flash loan tokens in order
     * to repay the flash loan amount + flash loan fee
     * @param _jSeizeTokenAddress The address of the jToken to seize collateral from
     * @param _flashLoanTokenAddress The address of the flash loan jToken's underlying asset
     * @param _flashLoanAmountToRepay The flash loan amount + flash loan fee to repay
     */
    function _swapSeizeTokenToFlashLoanToken(
        address _jSeizeTokenAddress,
        address _flashLoanTokenAddress,
        uint256 _flashLoanAmountToRepay
    ) internal {
        JErc20Storage jSeizeToken = JErc20Storage(_jSeizeTokenAddress);
        address jSeizeTokenUnderlyingAddress = jSeizeToken.underlying();

        // Calculate amount of underlying seize token we need
        // to swap in order to pay back the flash loan amount + fee
        address[] memory swapPath = new address[](2);
        swapPath[0] = jSeizeTokenUnderlyingAddress;
        swapPath[1] = _flashLoanTokenAddress;

        uint256 amountOfSeizeTokenToSwap = JoeRouter02(joeRouter02Address)
            .getAmountsIn(_flashLoanAmountToRepay, swapPath)[0];

        bool isSeizeNative = jSeizeTokenUnderlyingAddress == WAVAX;

        // Perform the swap to flash loan tokens!
        if (isSeizeNative) {
            JoeRouter02(joeRouter02Address).swapExactAVAXForTokens{
                value: amountOfSeizeTokenToSwap
            }(
                _flashLoanAmountToRepay, // amountOutMin
                swapPath, // path
                address(this), // to
                block.timestamp // deadline
            );
        } else {
            // Approve router to transfer `amountOfSeizeTokenToSwap` underlying
            // seize tokens
            ERC20 seizeToken = ERC20(jSeizeTokenUnderlyingAddress);
            seizeToken.approve(joeRouter02Address, amountOfSeizeTokenToSwap);

            // Swap seized token to flash loan token
            JoeRouter02(joeRouter02Address).swapExactTokensForTokens(
                amountOfSeizeTokenToSwap, // amountIn
                _flashLoanAmountToRepay, // amountOutMin
                swapPath, // path
                address(this), // to
                block.timestamp // deadline
            );
        }

        // Check we received enough flash loan tokens from the swap to repay the flash loan
        ERC20 flashLoanToken = ERC20(_flashLoanTokenAddress);
        require(
            flashLoanToken.balanceOf(address(this)) >= _flashLoanAmountToRepay,
            "JoeLiquidator: Expected to have enough tokens to repay flash loan after swapping seized tokens."
        );
    }

    /**
     * @dev Swaps all remaining of the seized collateral to AVAX, unless
     * the seized collateral is already AVAX, and sends it to the initiator.
     * @param _initiator The initiator of the flash loan, aka the liquidator
     * @param _jSeizeTokenAddress The address of jToken collateral was seized from
     * @return The AVAX received as profit from performing the liquidation.
     */
    function _swapRemainingSeizedTokenToAVAX(
        address _initiator,
        address _jSeizeTokenAddress
    ) internal returns (uint256) {
        JErc20Storage jSeizeToken = JErc20Storage(_jSeizeTokenAddress);
        address jSeizeTokenUnderlyingAddress = jSeizeToken.underlying();

        bool isSeizeNative = jSeizeTokenUnderlyingAddress == WAVAX;
        if (isSeizeNative) {
            // The seized collateral was AVAX so we can do a simple transfer to the liquidator
            uint256 profitedAVAX = address(this).balance;

            (bool success, ) = _initiator.call{value: profitedAVAX}("");
            require(
                success,
                "JoeLiquidator: Failed to transfer native AVAX to liquidator"
            );

            return profitedAVAX;
        } else {
            // Swap seized token to AVAX
            ERC20 seizeToken = ERC20(jSeizeTokenUnderlyingAddress);
            uint256 remainingSeizeAmount = seizeToken.balanceOf(address(this));

            require(
                remainingSeizeAmount > 0,
                "JoeLiquidator: Expected to have remaining seize amount in order to have profited from liquidation"
            );

            seizeToken.approve(joeRouter02Address, remainingSeizeAmount);

            address[] memory swapPath = new address[](2);
            swapPath[0] = jSeizeTokenUnderlyingAddress;
            swapPath[1] = WAVAX;

            uint256[] memory amounts = JoeRouter02(joeRouter02Address)
                .swapExactTokensForAVAX(
                    remainingSeizeAmount, // amountIn
                    0, // amountOutMin
                    swapPath, // path
                    _initiator, // to
                    block.timestamp // deadline
                );

            // Return profitted AVAX
            return amounts[1];
        }
    }

    /**
     * @notice Approves the flash loan jToken to retrieve the flash loan amount + fee.
     * @param _flashLoanTokenAddress The address of the flash loan jToken's underlying asset
     * @param _flashLoanAmountToRepay The flash loan amount to repay
     */
    function _approveFlashLoanToken(
        address _flashLoanTokenAddress,
        uint256 _flashLoanAmountToRepay
    ) internal {
        ERC20 flashLoanToken = ERC20(_flashLoanTokenAddress);

        // Ensure we have enough to repay flash loan
        require(
            flashLoanToken.balanceOf(address(this)) >= _flashLoanAmountToRepay,
            "JoeLiquidator: Expected to have enough tokens to repay flash loan after swapping seized tokens."
        );

        // Approve flash loan lender to retrieve loan amount + fee from us
        flashLoanToken.approve(msg.sender, _flashLoanAmountToRepay);
    }
}
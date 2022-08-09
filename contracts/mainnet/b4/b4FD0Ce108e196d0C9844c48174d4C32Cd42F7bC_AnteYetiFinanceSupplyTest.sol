// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./FixedPointMathLib.sol";
import "../AnteTest.sol";
import "../interfaces/IERC20.sol";
import "./IActivePool.sol";
import "./IYetiController.sol";

/// @title AnteYetiFinanceSupplyTest
/// @notice Ensure that the dollar value of the Yeti Finance Active pool exceeds 1.1x the total supply of YUSD
contract AnteYetiFinanceSupplyTest is AnteTest("Ensure total supply of YUSD doesn't exceed Active Pool backing") {
    using FixedPointMathLib for uint256;

    // https://docs.yeti.finance/other/contract-addresses
    address private yusd = 0x111111111111ed1D73f860F57b2798b683f2d325;
    address private activePool = 0xAAAaaAaaAaDd4AA719f0CF8889298D13dC819A15;
    address private yetiController = 0xcCCCcCccCCCc053fD8D1fF275Da4183c2954dBe3;

    IERC20 private YUSD = IERC20(yusd);
    IActivePool private ActivePool = IActivePool(activePool);
    IYetiController private YetiController = IYetiController(yetiController);

    constructor() {
        protocolName = "Yeti Finance";
        testedContracts = [activePool, yusd];
    }

    /// @return true if the TVL is > totalSupply * 1.1
    function checkTestPasses() public view override returns (bool) {
        uint256 balanceInUsd = getActivePoolTvlInUsd();
        uint256 totalSupply = YUSD.totalSupply();
        return balanceInUsd * 10 > totalSupply * 11;
    }

    function getActivePoolTvlInUsd() public view returns (uint256) {
        (address[] memory collateral, uint256[] memory amounts) = ActivePool.getAllCollateral();
        uint256 tvlInUsd = 0; // in WAD
        for (uint256 i; i < collateral.length; ++i) {
            uint256 amount = amounts[i];
            uint256 priceInUsd = YetiController.getPrice(collateral[i]);
            tvlInUsd += amount.mulWadDown(priceInUsd);
        }
        return tvlInUsd;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

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
                    x := div(xxRound, scalar)

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
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
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
                z := shl(64, z) // Like multiplying by 2 ** 64.
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z) // Like multiplying by 2 ** 32.
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z) // Like multiplying by 2 ** 16.
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z) // Like multiplying by 2 ** 8.
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z) // Like multiplying by 2 ** 4.
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z) // Like multiplying by 2 ** 2.
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

// SPDX-License-Identifier: GPL-3.0-only

// ┏━━━┓━━━━━┏┓━━━━━━━━━┏━━━┓━━━━━━━━━━━━━━━━━━━━━━━
// ┃┏━┓┃━━━━┏┛┗┓━━━━━━━━┃┏━━┛━━━━━━━━━━━━━━━━━━━━━━━
// ┃┗━┛┃┏━┓━┗┓┏┛┏━━┓━━━━┃┗━━┓┏┓┏━┓━┏━━┓━┏━┓━┏━━┓┏━━┓
// ┃┏━┓┃┃┏┓┓━┃┃━┃┏┓┃━━━━┃┏━━┛┣┫┃┏┓┓┗━┓┃━┃┏┓┓┃┏━┛┃┏┓┃
// ┃┃ ┃┃┃┃┃┃━┃┗┓┃┃━┫━┏┓━┃┃━━━┃┃┃┃┃┃┃┗┛┗┓┃┃┃┃┃┗━┓┃┃━┫
// ┗┛ ┗┛┗┛┗┛━┗━┛┗━━┛━┗┛━┗┛━━━┗┛┗┛┗┛┗━━━┛┗┛┗┛┗━━┛┗━━┛
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

pragma solidity >=0.7.0;

import "./interfaces/IAnteTest.sol";

/// @title Ante V0.5 Ante Test smart contract
/// @notice Abstract inheritable contract that supplies syntactic sugar for writing Ante Tests
/// @dev Usage: contract YourAnteTest is AnteTest("String descriptor of test") { ... }
abstract contract AnteTest is IAnteTest {
    /// @inheritdoc IAnteTest
    address public override testAuthor;
    /// @inheritdoc IAnteTest
    string public override testName;
    /// @inheritdoc IAnteTest
    string public override protocolName;
    /// @inheritdoc IAnteTest
    address[] public override testedContracts;

    /// @dev testedContracts and protocolName are optional parameters which should
    /// be set in the constructor of your AnteTest
    /// @param _testName The name of the Ante Test
    constructor(string memory _testName) {
        testAuthor = msg.sender;
        testName = _testName;
    }

    /// @notice Returns the testedContracts array of addresses
    /// @return The list of tested contracts as an array of addresses
    function getTestedContracts() external view returns (address[] memory) {
        return testedContracts;
    }

    /// @inheritdoc IAnteTest
    function checkTestPasses() external virtual override returns (bool) {}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Return decimals of token
     */
    function decimals() external view returns (uint8);

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

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.6.5. SEE SOURCE BELOW. !!
pragma solidity ^0.8.4;

interface IActivePool {
    event ActivePoolBalanceUpdated(address _collateral, uint256 _amount);
    event ActivePoolBalancesUpdated(address[] _collaterals, uint256[] _amounts);
    event ActivePoolCollateralBalanceUpdated(address _collateral, uint256 _amount);
    event ActivePoolYUSDDebtUpdated(uint256 _YUSDDebt);
    event CollateralSent(address _collateral, address _to, uint256 _amount);
    event CollateralsSent(address[] _collaterals, uint256[] _amounts, address _to);
    event ETHBalanceUpdated(uint256 _newBalance);
    event EtherSent(address _to, uint256 _amount);
    event YUSDBalanceUpdated(uint256 _newBalance);

    function DECIMAL_PRECISION() external view returns (uint256);

    function NAME() external view returns (bytes32);

    function YUSDDebt() external view returns (uint256);

    function addCollateralType(address _collateral) external;

    function decreaseYUSDDebt(uint256 _amount) external;

    function getAllCollateral() external view returns (address[] memory, uint256[] memory);

    function getAmountsSubsetSystem(address[] memory _collaterals) external view returns (uint256[] memory);

    function getCollateral(address _collateral) external view returns (uint256);

    function getCollateralVC(address _collateral) external view returns (uint256);

    function getVC() external view returns (uint256 totalVC);

    function getVCAndRVC() external view returns (uint256 totalVC, uint256 totalRVC);

    function getVCAndRVCSystem() external view returns (uint256 totalVC, uint256 totalRVC);

    function getVCSystem() external view returns (uint256 totalVCSystem);

    function getYUSDDebt() external view returns (uint256);

    function increaseYUSDDebt(uint256 _amount) external;

    function receiveCollateral(address[] memory _tokens, uint256[] memory _amounts) external;

    function sendCollaterals(
        address _to,
        address[] memory _tokens,
        uint256[] memory _amounts
    ) external;

    function sendCollateralsUnwrap(
        address _to,
        address[] memory _tokens,
        uint256[] memory _amounts
    ) external;

    function sendSingleCollateral(
        address _to,
        address _token,
        uint256 _amount
    ) external;

    function sendSingleCollateralUnwrap(
        address _to,
        address _token,
        uint256 _amount
    ) external;

    function setAddresses(
        address _borrowerOperationsAddress,
        address _troveManagerAddress,
        address _stabilityPoolAddress,
        address _defaultPoolAddress,
        address _controllerAddress,
        address _troveManagerLiquidationsAddress,
        address _troveManagerRedemptionsAddress,
        address _collSurplusPoolAddress
    ) external;
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"_collateral","type":"address"},{"indexed":false,"internalType":"uint256","name":"_amount","type":"uint256"}],"name":"ActivePoolBalanceUpdated","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address[]","name":"_collaterals","type":"address[]"},{"indexed":false,"internalType":"uint256[]","name":"_amounts","type":"uint256[]"}],"name":"ActivePoolBalancesUpdated","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"_collateral","type":"address"},{"indexed":false,"internalType":"uint256","name":"_amount","type":"uint256"}],"name":"ActivePoolCollateralBalanceUpdated","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"_YUSDDebt","type":"uint256"}],"name":"ActivePoolYUSDDebtUpdated","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"_collateral","type":"address"},{"indexed":false,"internalType":"address","name":"_to","type":"address"},{"indexed":false,"internalType":"uint256","name":"_amount","type":"uint256"}],"name":"CollateralSent","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address[]","name":"_collaterals","type":"address[]"},{"indexed":false,"internalType":"uint256[]","name":"_amounts","type":"uint256[]"},{"indexed":false,"internalType":"address","name":"_to","type":"address"}],"name":"CollateralsSent","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"_newBalance","type":"uint256"}],"name":"ETHBalanceUpdated","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"_to","type":"address"},{"indexed":false,"internalType":"uint256","name":"_amount","type":"uint256"}],"name":"EtherSent","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"_newBalance","type":"uint256"}],"name":"YUSDBalanceUpdated","type":"event"},{"inputs":[],"name":"DECIMAL_PRECISION","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"NAME","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"YUSDDebt","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_collateral","type":"address"}],"name":"addCollateralType","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_amount","type":"uint256"}],"name":"decreaseYUSDDebt","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"getAllCollateral","outputs":[{"internalType":"address[]","name":"","type":"address[]"},{"internalType":"uint256[]","name":"","type":"uint256[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address[]","name":"_collaterals","type":"address[]"}],"name":"getAmountsSubsetSystem","outputs":[{"internalType":"uint256[]","name":"","type":"uint256[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_collateral","type":"address"}],"name":"getCollateral","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_collateral","type":"address"}],"name":"getCollateralVC","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getVC","outputs":[{"internalType":"uint256","name":"totalVC","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getVCAndRVC","outputs":[{"internalType":"uint256","name":"totalVC","type":"uint256"},{"internalType":"uint256","name":"totalRVC","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getVCAndRVCSystem","outputs":[{"internalType":"uint256","name":"totalVC","type":"uint256"},{"internalType":"uint256","name":"totalRVC","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getVCSystem","outputs":[{"internalType":"uint256","name":"totalVCSystem","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getYUSDDebt","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_amount","type":"uint256"}],"name":"increaseYUSDDebt","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address[]","name":"_tokens","type":"address[]"},{"internalType":"uint256[]","name":"_amounts","type":"uint256[]"}],"name":"receiveCollateral","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_to","type":"address"},{"internalType":"address[]","name":"_tokens","type":"address[]"},{"internalType":"uint256[]","name":"_amounts","type":"uint256[]"}],"name":"sendCollaterals","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_to","type":"address"},{"internalType":"address[]","name":"_tokens","type":"address[]"},{"internalType":"uint256[]","name":"_amounts","type":"uint256[]"}],"name":"sendCollateralsUnwrap","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_to","type":"address"},{"internalType":"address","name":"_token","type":"address"},{"internalType":"uint256","name":"_amount","type":"uint256"}],"name":"sendSingleCollateral","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_to","type":"address"},{"internalType":"address","name":"_token","type":"address"},{"internalType":"uint256","name":"_amount","type":"uint256"}],"name":"sendSingleCollateralUnwrap","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_borrowerOperationsAddress","type":"address"},{"internalType":"address","name":"_troveManagerAddress","type":"address"},{"internalType":"address","name":"_stabilityPoolAddress","type":"address"},{"internalType":"address","name":"_defaultPoolAddress","type":"address"},{"internalType":"address","name":"_controllerAddress","type":"address"},{"internalType":"address","name":"_troveManagerLiquidationsAddress","type":"address"},{"internalType":"address","name":"_troveManagerRedemptionsAddress","type":"address"},{"internalType":"address","name":"_collSurplusPoolAddress","type":"address"}],"name":"setAddresses","outputs":[],"stateMutability":"nonpayable","type":"function"}]
*/

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.6.5. SEE SOURCE BELOW. !!
pragma solidity ^0.8.4;

interface IYetiController {
    event BoostMinuteDecayFactorChanged(uint256 _newBoostMinuteDecayFactor);
    event ClaimAddressChanged(address _newClaimAddress);
    event CollateralAdded(address _collateral);
    event CollateralDeprecated(address _collateral);
    event CollateralUndeprecated(address _collateral);
    event DefaultRouterChanged(address _collateral, address _newDefaultRouter);
    event FeeBootstrapPeriodEnabledChanged(bool _enabled);
    event FeeCurveChanged(address _collateral, address _newFeeCurve);
    event GlobalBoostMultiplierChanged(uint256 _newGlobalBoostMultiplier);
    event GlobalYUSDMintOn(bool _canMint);
    event LeverUpChanged(bool _enabled);
    event MaxCollsInTroveChanged(uint256 _newMaxCollsInTrove);
    event MaxSystemCollsChanged(uint256 _newMaxSystemColls);
    event OracleChanged(address _collateral, address _newOracle);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event RecoveryRatioChanged(address _collateral, uint256 _newRecoveryRatio);
    event RedemptionBorrowerFeeSplitChanged(uint256 _newSplit);
    event RedemptionsEnabledUpdated(bool _enabled);
    event SafetyRatioChanged(address _collateral, uint256 _newSafetyRatio);
    event UpdateVeYetiCallers(address _contractAddress, bool _isWhitelisted);
    event YUSDFeeRecipientChanged(address _newFeeRecipient);
    event YUSDMinterChanged(address _minter, bool _canMint);
    event YetiFinanceTreasuryChanged(address _newTreasury);
    event YetiFinanceTreasurySplitChanged(uint256 _newSplit);

    function DECIMAL_PRECISION() external view returns (uint256);

    function YUSDFeeRecipient() external view returns (address);

    function absorptionColls(uint256) external view returns (address);

    function absorptionWeights(uint256) external view returns (uint256);

    function addCollateral(
        address _collateral,
        uint256 _safetyRatio,
        uint256 _recoveryRatio,
        address _oracle,
        uint256 _decimals,
        address _feeCurve,
        bool _isWrapped,
        address _routerAddress
    ) external;

    function addValidYUSDMinter(address _minter) external;

    function addVeYetiCaller(address _contractAddress) external;

    function bootstrapEnded() external view returns (bool);

    function changeBoostMinuteDecayFactor(uint256 _newBoostMinuteDecayFactor) external;

    function changeClaimAddress(address _newClaimAddress) external;

    function changeFeeCurve(address _collateral, address _feeCurve) external;

    function changeGlobalBoostMultiplier(uint256 _newGlobalBoostMultiplier) external;

    function changeOracle(address _collateral, address _oracle) external;

    function changeRatios(
        address _collateral,
        uint256 _newSafetyRatio,
        uint256 _newRecoveryRatio
    ) external;

    function changeRedemptionBorrowerFeeSplit(uint256 _newSplit) external;

    function changeYUSDFeeRecipient(address _newFeeRecipient) external;

    function changeYetiFinanceTreasury(address _newTreasury) external;

    function changeYetiFinanceTreasurySplit(uint256 _newSplit) external;

    function checkCollateralListDouble(address[] memory _depositColls, address[] memory _withdrawColls) external view;

    function checkCollateralListSingle(address[] memory _colls, bool _deposit) external view;

    function collateralParams(address)
        external
        view
        returns (
            uint256 safetyRatio,
            uint256 recoveryRatio,
            address oracle,
            uint256 decimals,
            address feeCurve,
            uint256 index,
            address defaultRouter,
            bool active,
            bool isWrapped
        );

    function deprecateAllCollateral() external;

    function deprecateCollateral(address _collateral) external;

    function endBootstrap() external;

    function feeBootstrapPeriodEnabled() external view returns (bool);

    function getAbsorptionCollParams() external view returns (address[] memory, uint256[] memory);

    function getClaimAddress() external view returns (address);

    function getDecimals(address _collateral) external view returns (uint256);

    function getDefaultRouterAddress(address _collateral) external view returns (address);

    function getEntireSystemColl() external view returns (uint256);

    function getEntireSystemDebt() external view returns (uint256);

    function getFeeCurve(address _collateral) external view returns (address);

    function getFeeSplitInformation()
        external
        view
        returns (
            uint256,
            address,
            address
        );

    function getIndex(address _collateral) external view returns (uint256);

    function getIndices(address[] memory _colls) external view returns (uint256[] memory indices);

    function getIsActive(address _collateral) external view returns (bool);

    function getMaxCollsInTrove() external view returns (uint256);

    function getOracle(address _collateral) external view returns (address);

    function getPrice(address _collateral) external view returns (uint256);

    function getRecoveryRatio(address _collateral) external view returns (uint256);

    function getRedemptionBorrowerFeeSplit() external view returns (uint256);

    function getSafetyRatio(address _collateral) external view returns (uint256);

    function getTotalVariableDepositFeeAndUpdate(
        address[] memory _tokensIn,
        uint256[] memory _amountsIn,
        uint256[] memory _leverages,
        uint256 _entireSystemCollVC,
        uint256 _VCin,
        uint256 _VCout
    ) external returns (uint256 YUSDFee, uint256 boostFactor);

    function getValidCollateral() external view returns (address[] memory);

    function getValueRVC(address _collateral, uint256 _amount) external view returns (uint256);

    function getValueUSD(address _collateral, uint256 _amount) external view returns (uint256);

    function getValueVC(address _collateral, uint256 _amount) external view returns (uint256);

    function getValuesRVC(address[] memory _collaterals, uint256[] memory _amounts)
        external
        view
        returns (uint256 RVCValue);

    function getValuesUSD(address[] memory _collaterals, uint256[] memory _amounts)
        external
        view
        returns (uint256 USDValue);

    function getValuesVC(address[] memory _collaterals, uint256[] memory _amounts)
        external
        view
        returns (uint256 VCValue);

    function getValuesVCAndRVC(address[] memory _collaterals, uint256[] memory _amounts)
        external
        view
        returns (uint256 VCValue, uint256 RVCValue);

    function getValuesVCIndividual(address[] memory _collaterals, uint256[] memory _amounts)
        external
        view
        returns (uint256[] memory);

    function getVariableDepositFee(
        address _collateral,
        uint256 _collateralVCInput,
        uint256 _collateralVCSystemBalance,
        uint256 _totalVCBalancePre,
        uint256 _totalVCBalancePost
    ) external view returns (uint256);

    function getYUSDFeeRecipient() external view returns (address);

    function getYetiFinanceTreasury() external view returns (address);

    function getYetiFinanceTreasurySplit() external view returns (uint256);

    function isLeverUpEnabled() external view returns (bool);

    function isWrapped(address _collateral) external view returns (bool);

    function isWrappedMany(address[] memory _collaterals) external view returns (bool[] memory wrapped);

    function leverUpEnabled() external view returns (bool);

    function maxCollsInTrove() external view returns (uint256);

    function maxSystemColls() external view returns (uint256);

    function owner() external view returns (address);

    function redemptionBorrowerFeeSplit() external view returns (uint256);

    function removeValidYUSDMinter(address _minter) external;

    function removeVeYetiCaller(address _contractAddress) external;

    function renounceOwnership() external;

    function setAddresses(
        address _activePoolAddress,
        address _defaultPoolAddress,
        address _stabilityPoolAddress,
        address _collSurplusPoolAddress,
        address _borrowerOperationsAddress,
        address _yusdTokenAddress,
        address _YUSDFeeRecipientAddress,
        address _yetiFinanceTreasury,
        address _sortedTrovesAddress,
        address _veYETIAddress,
        address _troveManagerRedemptionsAddress,
        address _claimAddress,
        address _threeDayTimelock,
        address _twoWeekTimelock
    ) external;

    function setDefaultRouter(address _collateral, address _router) external;

    function setFeeBootstrapPeriodEnabled(bool _enabled) external;

    function setLeverUp(bool _enabled) external;

    function threeDayTimelock() external view returns (address);

    function transferOwnership(address newOwner) external;

    function twoWeekTimelock() external view returns (address);

    function unDeprecateCollateral(address _collateral) external;

    function updateAbsorptionColls(address[] memory _colls, uint256[] memory _weights) external;

    function updateGlobalYUSDMinting(bool _canMint) external;

    function updateMaxCollsInTrove(uint256 _newMax) external;

    function updateMaxSystemColls(uint256 _newMax) external;

    function updateRedemptionsEnabled(bool _enabled) external;

    function validCollateral(uint256) external view returns (address);

    function yetiFinanceTreasury() external view returns (address);

    function yetiFinanceTreasurySplit() external view returns (uint256);
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"_newBoostMinuteDecayFactor","type":"uint256"}],"name":"BoostMinuteDecayFactorChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"_newClaimAddress","type":"address"}],"name":"ClaimAddressChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"_collateral","type":"address"}],"name":"CollateralAdded","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"_collateral","type":"address"}],"name":"CollateralDeprecated","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"_collateral","type":"address"}],"name":"CollateralUndeprecated","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"_collateral","type":"address"},{"indexed":false,"internalType":"address","name":"_newDefaultRouter","type":"address"}],"name":"DefaultRouterChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"bool","name":"_enabled","type":"bool"}],"name":"FeeBootstrapPeriodEnabledChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"_collateral","type":"address"},{"indexed":false,"internalType":"address","name":"_newFeeCurve","type":"address"}],"name":"FeeCurveChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"_newGlobalBoostMultiplier","type":"uint256"}],"name":"GlobalBoostMultiplierChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"bool","name":"_canMint","type":"bool"}],"name":"GlobalYUSDMintOn","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"bool","name":"_enabled","type":"bool"}],"name":"LeverUpChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"_newMaxCollsInTrove","type":"uint256"}],"name":"MaxCollsInTroveChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"_newMaxSystemColls","type":"uint256"}],"name":"MaxSystemCollsChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"_collateral","type":"address"},{"indexed":false,"internalType":"address","name":"_newOracle","type":"address"}],"name":"OracleChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"previousOwner","type":"address"},{"indexed":true,"internalType":"address","name":"newOwner","type":"address"}],"name":"OwnershipTransferred","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"_collateral","type":"address"},{"indexed":false,"internalType":"uint256","name":"_newRecoveryRatio","type":"uint256"}],"name":"RecoveryRatioChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"_newSplit","type":"uint256"}],"name":"RedemptionBorrowerFeeSplitChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"bool","name":"_enabled","type":"bool"}],"name":"RedemptionsEnabledUpdated","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"_collateral","type":"address"},{"indexed":false,"internalType":"uint256","name":"_newSafetyRatio","type":"uint256"}],"name":"SafetyRatioChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"_contractAddress","type":"address"},{"indexed":false,"internalType":"bool","name":"_isWhitelisted","type":"bool"}],"name":"UpdateVeYetiCallers","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"_newFeeRecipient","type":"address"}],"name":"YUSDFeeRecipientChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"_minter","type":"address"},{"indexed":false,"internalType":"bool","name":"_canMint","type":"bool"}],"name":"YUSDMinterChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"_newTreasury","type":"address"}],"name":"YetiFinanceTreasuryChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"_newSplit","type":"uint256"}],"name":"YetiFinanceTreasurySplitChanged","type":"event"},{"inputs":[],"name":"DECIMAL_PRECISION","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"YUSDFeeRecipient","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"absorptionColls","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"absorptionWeights","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_collateral","type":"address"},{"internalType":"uint256","name":"_safetyRatio","type":"uint256"},{"internalType":"uint256","name":"_recoveryRatio","type":"uint256"},{"internalType":"address","name":"_oracle","type":"address"},{"internalType":"uint256","name":"_decimals","type":"uint256"},{"internalType":"address","name":"_feeCurve","type":"address"},{"internalType":"bool","name":"_isWrapped","type":"bool"},{"internalType":"address","name":"_routerAddress","type":"address"}],"name":"addCollateral","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_minter","type":"address"}],"name":"addValidYUSDMinter","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_contractAddress","type":"address"}],"name":"addVeYetiCaller","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"bootstrapEnded","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_newBoostMinuteDecayFactor","type":"uint256"}],"name":"changeBoostMinuteDecayFactor","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_newClaimAddress","type":"address"}],"name":"changeClaimAddress","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_collateral","type":"address"},{"internalType":"address","name":"_feeCurve","type":"address"}],"name":"changeFeeCurve","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_newGlobalBoostMultiplier","type":"uint256"}],"name":"changeGlobalBoostMultiplier","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_collateral","type":"address"},{"internalType":"address","name":"_oracle","type":"address"}],"name":"changeOracle","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_collateral","type":"address"},{"internalType":"uint256","name":"_newSafetyRatio","type":"uint256"},{"internalType":"uint256","name":"_newRecoveryRatio","type":"uint256"}],"name":"changeRatios","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_newSplit","type":"uint256"}],"name":"changeRedemptionBorrowerFeeSplit","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_newFeeRecipient","type":"address"}],"name":"changeYUSDFeeRecipient","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_newTreasury","type":"address"}],"name":"changeYetiFinanceTreasury","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_newSplit","type":"uint256"}],"name":"changeYetiFinanceTreasurySplit","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address[]","name":"_depositColls","type":"address[]"},{"internalType":"address[]","name":"_withdrawColls","type":"address[]"}],"name":"checkCollateralListDouble","outputs":[],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address[]","name":"_colls","type":"address[]"},{"internalType":"bool","name":"_deposit","type":"bool"}],"name":"checkCollateralListSingle","outputs":[],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"collateralParams","outputs":[{"internalType":"uint256","name":"safetyRatio","type":"uint256"},{"internalType":"uint256","name":"recoveryRatio","type":"uint256"},{"internalType":"address","name":"oracle","type":"address"},{"internalType":"uint256","name":"decimals","type":"uint256"},{"internalType":"address","name":"feeCurve","type":"address"},{"internalType":"uint256","name":"index","type":"uint256"},{"internalType":"address","name":"defaultRouter","type":"address"},{"internalType":"bool","name":"active","type":"bool"},{"internalType":"bool","name":"isWrapped","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"deprecateAllCollateral","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_collateral","type":"address"}],"name":"deprecateCollateral","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"endBootstrap","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"feeBootstrapPeriodEnabled","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getAbsorptionCollParams","outputs":[{"internalType":"address[]","name":"","type":"address[]"},{"internalType":"uint256[]","name":"","type":"uint256[]"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getClaimAddress","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_collateral","type":"address"}],"name":"getDecimals","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_collateral","type":"address"}],"name":"getDefaultRouterAddress","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getEntireSystemColl","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getEntireSystemDebt","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_collateral","type":"address"}],"name":"getFeeCurve","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getFeeSplitInformation","outputs":[{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"address","name":"","type":"address"},{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_collateral","type":"address"}],"name":"getIndex","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address[]","name":"_colls","type":"address[]"}],"name":"getIndices","outputs":[{"internalType":"uint256[]","name":"indices","type":"uint256[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_collateral","type":"address"}],"name":"getIsActive","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getMaxCollsInTrove","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_collateral","type":"address"}],"name":"getOracle","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_collateral","type":"address"}],"name":"getPrice","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_collateral","type":"address"}],"name":"getRecoveryRatio","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getRedemptionBorrowerFeeSplit","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_collateral","type":"address"}],"name":"getSafetyRatio","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address[]","name":"_tokensIn","type":"address[]"},{"internalType":"uint256[]","name":"_amountsIn","type":"uint256[]"},{"internalType":"uint256[]","name":"_leverages","type":"uint256[]"},{"internalType":"uint256","name":"_entireSystemCollVC","type":"uint256"},{"internalType":"uint256","name":"_VCin","type":"uint256"},{"internalType":"uint256","name":"_VCout","type":"uint256"}],"name":"getTotalVariableDepositFeeAndUpdate","outputs":[{"internalType":"uint256","name":"YUSDFee","type":"uint256"},{"internalType":"uint256","name":"boostFactor","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"getValidCollateral","outputs":[{"internalType":"address[]","name":"","type":"address[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_collateral","type":"address"},{"internalType":"uint256","name":"_amount","type":"uint256"}],"name":"getValueRVC","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_collateral","type":"address"},{"internalType":"uint256","name":"_amount","type":"uint256"}],"name":"getValueUSD","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_collateral","type":"address"},{"internalType":"uint256","name":"_amount","type":"uint256"}],"name":"getValueVC","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address[]","name":"_collaterals","type":"address[]"},{"internalType":"uint256[]","name":"_amounts","type":"uint256[]"}],"name":"getValuesRVC","outputs":[{"internalType":"uint256","name":"RVCValue","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address[]","name":"_collaterals","type":"address[]"},{"internalType":"uint256[]","name":"_amounts","type":"uint256[]"}],"name":"getValuesUSD","outputs":[{"internalType":"uint256","name":"USDValue","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address[]","name":"_collaterals","type":"address[]"},{"internalType":"uint256[]","name":"_amounts","type":"uint256[]"}],"name":"getValuesVC","outputs":[{"internalType":"uint256","name":"VCValue","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address[]","name":"_collaterals","type":"address[]"},{"internalType":"uint256[]","name":"_amounts","type":"uint256[]"}],"name":"getValuesVCAndRVC","outputs":[{"internalType":"uint256","name":"VCValue","type":"uint256"},{"internalType":"uint256","name":"RVCValue","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address[]","name":"_collaterals","type":"address[]"},{"internalType":"uint256[]","name":"_amounts","type":"uint256[]"}],"name":"getValuesVCIndividual","outputs":[{"internalType":"uint256[]","name":"","type":"uint256[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_collateral","type":"address"},{"internalType":"uint256","name":"_collateralVCInput","type":"uint256"},{"internalType":"uint256","name":"_collateralVCSystemBalance","type":"uint256"},{"internalType":"uint256","name":"_totalVCBalancePre","type":"uint256"},{"internalType":"uint256","name":"_totalVCBalancePost","type":"uint256"}],"name":"getVariableDepositFee","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getYUSDFeeRecipient","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getYetiFinanceTreasury","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getYetiFinanceTreasurySplit","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"isLeverUpEnabled","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_collateral","type":"address"}],"name":"isWrapped","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address[]","name":"_collaterals","type":"address[]"}],"name":"isWrappedMany","outputs":[{"internalType":"bool[]","name":"wrapped","type":"bool[]"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"leverUpEnabled","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"maxCollsInTrove","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"maxSystemColls","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"owner","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"redemptionBorrowerFeeSplit","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_minter","type":"address"}],"name":"removeValidYUSDMinter","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_contractAddress","type":"address"}],"name":"removeVeYetiCaller","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"renounceOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_activePoolAddress","type":"address"},{"internalType":"address","name":"_defaultPoolAddress","type":"address"},{"internalType":"address","name":"_stabilityPoolAddress","type":"address"},{"internalType":"address","name":"_collSurplusPoolAddress","type":"address"},{"internalType":"address","name":"_borrowerOperationsAddress","type":"address"},{"internalType":"address","name":"_yusdTokenAddress","type":"address"},{"internalType":"address","name":"_YUSDFeeRecipientAddress","type":"address"},{"internalType":"address","name":"_yetiFinanceTreasury","type":"address"},{"internalType":"address","name":"_sortedTrovesAddress","type":"address"},{"internalType":"address","name":"_veYETIAddress","type":"address"},{"internalType":"address","name":"_troveManagerRedemptionsAddress","type":"address"},{"internalType":"address","name":"_claimAddress","type":"address"},{"internalType":"address","name":"_threeDayTimelock","type":"address"},{"internalType":"address","name":"_twoWeekTimelock","type":"address"}],"name":"setAddresses","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_collateral","type":"address"},{"internalType":"address","name":"_router","type":"address"}],"name":"setDefaultRouter","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bool","name":"_enabled","type":"bool"}],"name":"setFeeBootstrapPeriodEnabled","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bool","name":"_enabled","type":"bool"}],"name":"setLeverUp","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"threeDayTimelock","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"twoWeekTimelock","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_collateral","type":"address"}],"name":"unDeprecateCollateral","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address[]","name":"_colls","type":"address[]"},{"internalType":"uint256[]","name":"_weights","type":"uint256[]"}],"name":"updateAbsorptionColls","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bool","name":"_canMint","type":"bool"}],"name":"updateGlobalYUSDMinting","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_newMax","type":"uint256"}],"name":"updateMaxCollsInTrove","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_newMax","type":"uint256"}],"name":"updateMaxSystemColls","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bool","name":"_enabled","type":"bool"}],"name":"updateRedemptionsEnabled","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"validCollateral","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"yetiFinanceTreasury","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"yetiFinanceTreasurySplit","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"}]
*/

// SPDX-License-Identifier: GPL-3.0-only

// ┏━━━┓━━━━━┏┓━━━━━━━━━┏━━━┓━━━━━━━━━━━━━━━━━━━━━━━
// ┃┏━┓┃━━━━┏┛┗┓━━━━━━━━┃┏━━┛━━━━━━━━━━━━━━━━━━━━━━━
// ┃┗━┛┃┏━┓━┗┓┏┛┏━━┓━━━━┃┗━━┓┏┓┏━┓━┏━━┓━┏━┓━┏━━┓┏━━┓
// ┃┏━┓┃┃┏┓┓━┃┃━┃┏┓┃━━━━┃┏━━┛┣┫┃┏┓┓┗━┓┃━┃┏┓┓┃┏━┛┃┏┓┃
// ┃┃ ┃┃┃┃┃┃━┃┗┓┃┃━┫━┏┓━┃┃━━━┃┃┃┃┃┃┃┗┛┗┓┃┃┃┃┃┗━┓┃┃━┫
// ┗┛ ┗┛┗┛┗┛━┗━┛┗━━┛━┗┛━┗┛━━━┗┛┗┛┗┛┗━━━┛┗┛┗┛┗━━┛┗━━┛
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

pragma solidity >=0.7.0;

/// @title The interface for the Ante V0.5 Ante Test
/// @notice The Ante V0.5 Ante Test wraps test logic for verifying fundamental invariants of a protocol
interface IAnteTest {
    /// @notice Returns the author of the Ante Test
    /// @dev This overrides the auto-generated getter for testAuthor as a public var
    /// @return The address of the test author
    function testAuthor() external view returns (address);

    /// @notice Returns the name of the protocol the Ante Test is testing
    /// @dev This overrides the auto-generated getter for protocolName as a public var
    /// @return The name of the protocol in string format
    function protocolName() external view returns (string memory);

    /// @notice Returns a single address in the testedContracts array
    /// @dev This overrides the auto-generated getter for testedContracts [] as a public var
    /// @param i The array index of the address to return
    /// @return The address of the i-th element in the list of tested contracts
    function testedContracts(uint256 i) external view returns (address);

    /// @notice Returns the name of the Ante Test
    /// @dev This overrides the auto-generated getter for testName as a public var
    /// @return The name of the Ante Test in string format
    function testName() external view returns (string memory);

    /// @notice Function containing test logic to inspect the protocol invariant
    /// @dev This should usually return True
    /// @return A single bool indicating if the Ante Test passes/fails
    function checkTestPasses() external returns (bool);
}
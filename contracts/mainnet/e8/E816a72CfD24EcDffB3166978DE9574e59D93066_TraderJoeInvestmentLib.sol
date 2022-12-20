// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./TraderJoeStorageLib.sol";
import "../../common/libraries/Math.sol";
import "../../common/libraries/SwapServiceLib.sol";

import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

library TraderJoeInvestmentLib {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    error InvalidActiveBinAllocation();

    function deposit(uint256 depositTokenAmount, uint256 pairDepositTokenAmount)
        public
    {
        TraderJoeStorage storage strategyStorage = TraderJoeStorageLib
            .getStorage();

        uint256 pairDepositTokenBefore = strategyStorage
            .pairDepositToken
            .balanceOf(address(this)) - pairDepositTokenAmount;

        uint256 amountXIn;
        uint256 amountYIn;

        if (strategyStorage.tokenX == strategyStorage.depositToken) {
            amountXIn = depositTokenAmount;
            amountYIn = pairDepositTokenAmount;
        } else {
            amountXIn = pairDepositTokenAmount;
            amountYIn = depositTokenAmount;
        }

        (
            uint256 amountX,
            uint256 amountY,
            uint256 activeId,
            int256[] memory deltaIds,
            uint256[] memory distributionX,
            uint256[] memory distributionY
        ) = __prepareParams(amountXIn, amountYIn);

        // Deposit.
        ITraderJoeLBRouter.LiquidityParameters memory liquidityParameters = ITraderJoeLBRouter
            .LiquidityParameters(
                address(strategyStorage.tokenX),
                address(strategyStorage.tokenY),
                strategyStorage.binStep,
                amountX,
                amountY,
                0, // Base contracts take care of min amount.
                0, // Base contracts take care of min amount.
                activeId,
                0,
                deltaIds,
                distributionX,
                distributionY,
                address(this),
                // solhint-disable-next-line not-rely-on-time
                block.timestamp
            );

        strategyStorage.tokenX.approve(
            address(strategyStorage.lbRouter),
            amountX
        );
        strategyStorage.tokenY.approve(
            address(strategyStorage.lbRouter),
            amountY
        );

        strategyStorage.lbRouter.addLiquidity(liquidityParameters);

        uint256 pairDepositTokenAfter = strategyStorage
            .pairDepositToken
            .balanceOf(address(this));

        uint256 pairDepositTokenIncrement = pairDepositTokenAfter -
            pairDepositTokenBefore;

        // Swap back remaining pairDepositToken to strategyStorage.depositToken if possible.
        swapTokens(
            pairDepositTokenIncrement,
            strategyStorage.pairDepositToken,
            strategyStorage.depositToken
        );
    }

    function withdraw(uint256 amount, uint256 investmentTokenSupply) public {
        TraderJoeStorage storage strategyStorage = TraderJoeStorageLib
            .getStorage();

        // Calculate LP token balance to withdraw per bin.
        uint256 binsAmount = strategyStorage.binIds.length;
        uint256[] memory amounts = new uint256[](binsAmount);

        for (uint256 i; i < binsAmount; ++i) {
            uint256 lpTokenBalance = strategyStorage.lbPair.balanceOf(
                address(this),
                strategyStorage.binIds[i]
            );

            amounts[i] = (lpTokenBalance * amount) / investmentTokenSupply;
        }

        // Withdraw.
        strategyStorage.lbPair.setApprovalForAll(
            address(strategyStorage.lbRouter),
            true
        );

        strategyStorage.lbRouter.removeLiquidity(
            address(strategyStorage.tokenX),
            address(strategyStorage.tokenY),
            uint16(strategyStorage.binStep),
            0, // Base contracts take care of min amount.
            0, // Base contracts take care of min amount.
            strategyStorage.binIds,
            amounts,
            address(this),
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        );
    }

    function reapReward() external {
        TraderJoeStorage storage strategyStorage = TraderJoeStorageLib
            .getStorage();

        uint256 pairdepositTokenBefore = strategyStorage
            .pairDepositToken
            .balanceOf(address(this));

        strategyStorage.lbPair.collectFees(
            address(this),
            strategyStorage.binIds
        );

        uint256 pairDepositTokenAfter = strategyStorage
            .pairDepositToken
            .balanceOf(address(this));

        uint256 pairDepositTokenIncrement = pairDepositTokenAfter -
            pairdepositTokenBefore;

        swapTokens(
            pairDepositTokenIncrement,
            strategyStorage.pairDepositToken,
            strategyStorage.depositToken
        );
    }

    function adjustBins(
        uint256[] calldata binIds,
        uint256[] calldata binAllocations,
        uint256 investmentTokenSupply
    ) external {
        TraderJoeStorage storage strategyStorage = TraderJoeStorageLib
            .getStorage();

        // Withdraw from all bins.
        uint256 depositTokenBefore = strategyStorage.depositToken.balanceOf(
            address(this)
        );
        uint256 pairDepositTokenBefore = strategyStorage
            .pairDepositToken
            .balanceOf(address(this));

        withdraw(investmentTokenSupply, investmentTokenSupply);

        uint256 depositTokenAfter = strategyStorage.depositToken.balanceOf(
            address(this)
        );
        uint256 pairDepositTokenAfter = strategyStorage
            .pairDepositToken
            .balanceOf(address(this));

        // Set bin IDs and allocations to the given ones.
        strategyStorage.binIds = binIds;
        strategyStorage.binAllocations = binAllocations;

        // Deposit into the new bins with the new allocations.
        uint256 depositTokenIncrement = depositTokenAfter - depositTokenBefore;
        uint256 pairDepositTokenIncrement = pairDepositTokenAfter -
            pairDepositTokenBefore;

        deposit(depositTokenIncrement, pairDepositTokenIncrement);
    }

    function swapTokens(
        uint256 amountIn,
        IERC20Upgradeable tokenIn,
        IERC20Upgradeable tokenOut
    ) public returns (uint256 amountOut) {
        TraderJoeStorage storage strategyStorage = TraderJoeStorageLib
            .getStorage();

        (amountOut, ) = strategyStorage.lbRouter.getSwapOut(
            address(strategyStorage.lbPair),
            amountIn,
            strategyStorage.tokenY == strategyStorage.depositToken
        );

        if (amountOut == 0) {
            return 0;
        }

        address[] memory path = new address[](2);
        path[0] = address(tokenIn);
        path[1] = address(tokenOut);

        uint256[] memory binSteps = new uint256[](1);
        binSteps[0] = strategyStorage.binStep;

        amountOut = SwapServiceLib.swapExactTokensForTokens(
            strategyStorage.swapService,
            amountIn,
            0,
            path,
            binSteps
        );
    }

    function __prepareParams(uint256 amountXIn, uint256 amountYIn)
        private
        returns (
            uint256 amountX,
            uint256 amountY,
            uint256 activeId,
            int256[] memory deltaIds,
            uint256[] memory distributionX,
            uint256[] memory distributionY
        )
    {
        TraderJoeStorage storage strategyStorage = TraderJoeStorageLib
            .getStorage();

        uint256 binsAmount = strategyStorage.binIds.length;

        (, , activeId) = strategyStorage.lbPair.getReservesAndId();

        // Assume that token X and token Y have the same price.
        uint256 totalAmount = amountXIn + amountYIn;

        // Delta IDs.
        deltaIds = new int256[](binsAmount);

        // Distributions.
        distributionX = new uint256[](binsAmount);
        distributionY = new uint256[](binsAmount);

        // The maximum of the number of bins is 51.
        uint256 activeBinIndex = type(uint256).max;

        for (uint256 i; i < binsAmount; ++i) {
            deltaIds[i] = int256(strategyStorage.binIds[i]) - int256(activeId);

            // Bin allocation has precision of 1e3.
            uint256 amount = (totalAmount * strategyStorage.binAllocations[i]) /
                1e3;

            if (strategyStorage.binIds[i] < activeId) {
                distributionY[i] = amount;
                amountY += amount;
            } else if (strategyStorage.binIds[i] > activeId) {
                distributionX[i] = amount;
                amountX += amount;
            } else {
                activeBinIndex = i;
            }
        }

        // If one of our target bins is active, allocate rest of amountXIn and amountYIn to it to minimize swap fee.
        if (activeBinIndex != type(uint256).max) {
            uint256 amount = totalAmount - amountX - amountY;

            if (amountXIn > amountX) {
                uint256 amountXActive = Math.min(amountXIn - amountX, amount);

                distributionX[activeBinIndex] = amountXActive;
                amountX += amountXActive;

                amount -= amountXActive;
            }

            if (amountYIn > amountY) {
                uint256 amountYActive = Math.min(amountYIn - amountY, amount);

                distributionY[activeBinIndex] = amountYActive;
                amountY += amountYActive;

                amount -= amountYActive;
            }

            if (amount > 0) {
                revert InvalidActiveBinAllocation();
            }
        }

        // Calibrate distributions so that the sum of them equals to 1e18, a precision of TraderJoe V2.
        for (uint256 i; i < binsAmount; ++i) {
            bool calibrateX;
            bool calibrateY;

            if (strategyStorage.binIds[i] < activeId) {
                calibrateY = true;
            } else if (strategyStorage.binIds[i] > activeId) {
                calibrateX = true;
            } else {
                calibrateX = true;
                calibrateY = true;
            }

            if (calibrateX && amountX != 0) {
                distributionX[i] = (distributionX[i] * 1e18) / amountX;
            }
            if (calibrateY && amountY != 0) {
                distributionY[i] = (distributionY[i] * 1e18) / amountY;
            }
        }

        // Swap only as much as is needed.
        if (amountXIn > amountX) {
            amountY =
                amountYIn +
                swapTokens(
                    amountXIn - amountX,
                    strategyStorage.tokenX,
                    strategyStorage.tokenY
                );
        } else if (amountYIn > amountY) {
            amountX =
                amountXIn +
                swapTokens(
                    amountYIn - amountY,
                    strategyStorage.tokenY,
                    strategyStorage.tokenX
                );
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../../common/libraries/SwapServiceLib.sol";
import "../../dependencies/traderjoe/ITraderJoeLBPair.sol";
import "../../dependencies/traderjoe/ITraderJoeLBRouter.sol";
import "../../dependencies/traderjoe/ITraderJoeMasterChef.sol";
import "../../dependencies/traderjoe/ITraderJoePair.sol";
import "../../dependencies/traderjoe/ITraderJoeRouter.sol";

import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";

struct TraderJoeStorage {
    ITraderJoeRouter router; // Obsolete.
    ITraderJoeMasterChef masterChef; // Obsolete.
    IERC20Upgradeable pairDepositToken;
    ITraderJoePair lpToken; // Obsolete.
    IERC20Upgradeable joeToken; // Obsolete.
    uint256 farmId; // Obsolete.
    IERC20Upgradeable depositToken; // To make it accessible from other libraries.
    SwapService swapService; // To make it accessible from other libraries.
    ITraderJoeLBPair lbPair;
    ITraderJoeLBRouter lbRouter;
    IERC20Upgradeable tokenX;
    IERC20Upgradeable tokenY;
    uint256 binStep;
    uint256[] binIds;
    uint256[] binAllocations;
}

library TraderJoeStorageLib {
    // keccak256("brokkr.storage.traderjoe.strategy");
    // solhint-disable-next-line const-name-snakecase
    bytes32 private constant storagePosition =
        0x2c18a668c6ed16d1abb08a50aa4bef7a42b8953231af749500b07f3b5a121f25;

    function getStorage() internal pure returns (TraderJoeStorage storage ts) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            ts.slot := storagePosition
        }
    }
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./Math.sol";

import "../../dependencies/traderjoe/ITraderJoeLBRouter.sol";
import "../../dependencies/traderjoe/ITraderJoeRouter.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

error InvalidSwapServiceProvider();

enum SwapServiceProvider {
    TraderJoe,
    TraderJoeV2
}

struct SwapService {
    SwapServiceProvider provider;
    address router;
}

library SwapServiceLib {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function swapExactTokensForTokens(
        SwapService memory swapService_,
        uint256 amountIn,
        uint256 minAmountOut,
        address[] memory path,
        uint256[] memory binSteps
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
                minAmountOut,
                path,
                address(this),
                // solhint-disable-next-line not-rely-on-time
                block.timestamp
            )[path.length - 1];
        } else if (swapService_.provider == SwapServiceProvider.TraderJoeV2) {
            ITraderJoeLBRouter traderjoeLBRouter = ITraderJoeLBRouter(
                swapService_.router
            );

            IERC20Upgradeable(path[0]).approve(
                address(traderjoeLBRouter),
                amountIn
            );

            amountOut = traderjoeLBRouter.swapExactTokensForTokens(
                amountIn,
                minAmountOut,
                binSteps,
                path,
                address(this),
                // solhint-disable-next-line not-rely-on-time
                block.timestamp
            );
        } else {
            revert InvalidSwapServiceProvider();
        }
    }

    function swapTokensForExactTokens(
        SwapService memory swapService_,
        uint256 amountOut,
        uint256 maxAmountIn,
        address[] memory path,
        uint256[] memory binSteps
    ) internal returns (uint256 amountIn) {
        if (swapService_.provider == SwapServiceProvider.TraderJoe) {
            ITraderJoeRouter traderjoeRouter = ITraderJoeRouter(
                swapService_.router
            );

            uint256[] memory maxAmountInCalculated = traderjoeRouter
                .getAmountsIn(amountOut, path);

            IERC20Upgradeable(path[0]).approve(
                address(traderjoeRouter),
                Math.min(maxAmountInCalculated[0], maxAmountIn)
            );

            amountIn = traderjoeRouter.swapTokensForExactTokens(
                amountOut,
                maxAmountIn,
                path,
                address(this),
                // solhint-disable-next-line not-rely-on-time
                block.timestamp
            )[0];
        } else if (swapService_.provider == SwapServiceProvider.TraderJoeV2) {
            ITraderJoeLBRouter traderjoeLBRouter = ITraderJoeLBRouter(
                swapService_.router
            );

            IERC20Upgradeable(path[0]).approve(
                address(traderjoeLBRouter),
                maxAmountIn
            );

            amountOut = traderjoeLBRouter.swapTokensForExactTokens(
                amountOut,
                maxAmountIn,
                binSteps,
                path,
                address(this),
                // solhint-disable-next-line not-rely-on-time
                block.timestamp
            )[0];

            IERC20Upgradeable(path[0]).approve(address(traderjoeLBRouter), 0);
        } else {
            revert InvalidSwapServiceProvider();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20Upgradeable.sol";

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface ITraderJoeLBPair {
    function tokenX() external returns (address);

    function tokenY() external returns (address);

    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    function setApprovalForAll(address sender, bool approved) external;

    function totalSupply(uint256 id) external view returns (uint256);

    function collectFees(address account, uint256[] calldata ids)
        external
        returns (uint256 amountX, uint256 amountY);

    function getBin(uint24 id)
        external
        view
        returns (uint256 reserveX, uint256 reserveY);

    function getReservesAndId()
        external
        view
        returns (
            uint256 reserveX,
            uint256 reserveY,
            uint256 activeId
        );
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface ITraderJoeLBRouter {
    struct LiquidityParameters {
        address tokenX;
        address tokenY;
        uint256 binStep;
        uint256 amountX;
        uint256 amountY;
        uint256 amountXMin;
        uint256 amountYMin;
        uint256 activeIdDesired;
        uint256 idSlippage;
        int256[] deltaIds;
        uint256[] distributionX;
        uint256[] distributionY;
        address to;
        uint256 deadline;
    }

    function addLiquidity(LiquidityParameters calldata liquidityParameters)
        external
        returns (uint256[] memory depositIds, uint256[] memory liquidityMinted);

    function removeLiquidity(
        address tokenX,
        address tokenY,
        uint16 binStep,
        uint256 amountXMin,
        uint256 amountYMin,
        uint256[] memory ids,
        uint256[] memory amounts,
        address to,
        uint256 deadline
    ) external returns (uint256 amountX, uint256 amountY);

    function getPriceFromId(address lbPair, uint24 id)
        external
        view
        returns (uint256);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        uint256[] memory binSteps,
        address[] memory path,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        uint256[] memory binSteps,
        address[] memory path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amountsIn);

    function getSwapIn(
        address lbPair,
        uint256 amountOut,
        bool swapForY
    ) external view returns (uint256 amountIn, uint256 feesIn);

    function getSwapOut(
        address lbPair,
        uint256 amountIn,
        bool swapForY
    ) external view returns (uint256 amountOut, uint256 feesIn);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITraderJoeMasterChef {
    struct PoolInfo {
        IERC20 lpToken;
        uint256 allocPoint;
        uint256 lastRewardTimestamp;
        uint256 accJoePerShare;
    }

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    function poolLength() external view returns (uint256);

    function poolInfo(uint256 pid)
        external
        view
        returns (ITraderJoeMasterChef.PoolInfo memory);

    function userInfo(uint256 _poolId, address _user)
        external
        view
        returns (UserInfo memory);

    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 pid, uint256 amount) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface ITraderJoePair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function balanceOf(address owner) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
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

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
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

    function swapExactTokensForAVAX(
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

    function getAmountsIn(uint256 amountOut, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
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
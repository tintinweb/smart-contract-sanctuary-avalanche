//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./lib/SafeMath.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IAave.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/IOneInch.sol";

contract FlashLoaner is IFlashLoanSimpleReceiver {
    using SafeMath for uint256;

    // Exchanges
    address internal owner;
    address internal receiver;
    address internal aavePool = 0x794a61358D6845594F94dc1DB02A252b5b4814aD;

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Message sender is not the owner of the contract"
        );
        _;
    }

    event Profit(address token, uint256 profit);

    struct Data {
        address fromToken;
        address toToken;
        uint256 amount;
        address oneinch;
        bytes to;
        bytes from;
    }

    constructor(address payable _receiver) {
        owner = msg.sender;
        receiver = _receiver;
    }

    function initiateFlashloan(Data memory _data) external onlyOwner {
        bytes memory params = abi.encode(_data);
        uint256 balBefore = IERC20(_data.fromToken).balanceOf(address(this));
        IAavePool(aavePool).flashLoanSimple(
            address(this),
            _data.fromToken,
            _data.amount,
            params,
            0
        );

        uint256 balAfter = IERC20(_data.fromToken).balanceOf(address(this));
        if (balAfter > balBefore) {
            emit Profit(_data.fromToken, balAfter.sub(balBefore));
            IERC20(_data.fromToken).transfer(receiver, balAfter);
            // Possible leftover balance of toToken
            uint256 balOther = IERC20(_data.toToken).balanceOf(address(this));
            if (balOther > 0) {
                IERC20(_data.toToken).transfer(receiver, balOther);
            }
        } else {
            emit Profit(_data.fromToken, 0);
        }
    }

    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        Data memory data = abi.decode(params, (Data));
        IERC20(asset).approve(data.oneinch, amount);
        swapOneInch(data.to, data.oneinch);
        IERC20(data.toToken).approve(data.oneinch, type(uint256).max);
        swapOneInch(data.from, data.oneinch);
        IERC20(data.toToken).approve(data.oneinch, 0);
        // Repay to Aave
        uint256 repayAmt = amount.add(premium);
        IERC20(asset).approve(aavePool, repayAmt);
        // return true;
    }

    function swapOneInch(bytes memory data, address oneinch_address)
        internal
        returns (uint256 returnAmount, uint256 gasLeft)
    {
        (
            address caller,
            OneInchRouter.SwapDescription memory desc,
            bytes memory data_send
        ) = abi.decode(data, (address, OneInchRouter.SwapDescription, bytes));

        (returnAmount, ) = OneInchRouter(oneinch_address).swap(
            IAggregationExecutor(caller),
            desc,
            data_send
        );
    }

    receive() external payable {}

    function evacuateTokens(address token, address to) external onlyOwner {
        uint256 bal = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(to, bal);
    }

    function withdrawEther(address payable to) external onlyOwner {
        uint256 bal = address(this).balance;
        to.transfer(bal);
    }
}

// SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }
}

// SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IAavePool {
    /**
     * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
     * as long as the amount taken plus a fee is returned.
     * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
     * into consideration. For further details please visit https://developers.aave.com
     * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanReceiver interface
     * @param assets The addresses of the assets being flash-borrowed
     * @param amounts The amounts of the assets being flash-borrowed
     * @param interestRateModes Types of the debt to open if the flash loan is not returned:
     *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
     *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
     *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
     * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
     * @param params Variadic packed params to pass to the receiver as extra information
     * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata interestRateModes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;

    /**
     * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
     * as long as the amount taken plus a fee is returned.
     * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
     * into consideration. For further details please visit https://developers.aave.com
     * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanSimpleReceiver interface
     * @param asset The address of the asset being flash-borrowed
     * @param amount The amount of the asset being flash-borrowed
     * @param params Variadic packed params to pass to the receiver as extra information
     * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function flashLoanSimple(
        address receiverAddress,
        address asset,
        uint256 amount,
        bytes calldata params,
        uint16 referralCode
    ) external;
}

interface IFlashLoanSimpleReceiver {
    /**
     * @notice Executes an operation after receiving the flash-borrowed asset
     * @dev Ensure that the contract can return the debt + premium, e.g., has
     *      enough funds to repay and has approved the Pool to pull the total amount
     * @param asset The address of the flash-borrowed asset
     * @param amount The amount of the flash-borrowed asset
     * @param premium The fee of the flash-borrowed asset
     * @param initiator The address of the flashloan initiator
     * @param params The byte-encoded params passed when initiating the flashloan
     * @return True if the execution of the operation succeeds, false otherwise
     */
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external returns (bool);
}

// SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

// SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2Pair {
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function token0() external view returns (address);

    function token1() external view returns (address);
}

// SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2Router {
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
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
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IAggregationExecutor {
    function callBytes(bytes calldata data) external payable; // 0xd9c45357
}

interface OneInchRouter {
    struct SwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address srcReceiver;
        address dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
        bytes permit;
    }

    function swap(
        IAggregationExecutor caller,
        SwapDescription calldata desc,
        bytes calldata data
    ) external payable returns (uint256 returnAmount, uint256 gasLeft);
}
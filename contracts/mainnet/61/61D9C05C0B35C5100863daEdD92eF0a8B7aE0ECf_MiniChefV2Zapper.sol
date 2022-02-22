/**
 *Submitted for verification at snowtrace.io on 2022-02-22
*/

// Sources flattened with hardhat v2.8.3 https://hardhat.org

// File contracts/dex/interfaces/IWAVAX.sol

pragma solidity >=0.8.9;

interface IWAVAX {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    function balanceOf(address owner) external view returns (uint);
}


// File contracts/amm/pangolin-core/interfaces/IERC20.sol

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}


// File contracts/amm/pangolin-core/interfaces/IPangolinPair.sol

pragma solidity >=0.5.0;

interface IPangolinPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}


// File contracts/amm/pangolin-periphery/interfaces/IPangolinRouter.sol

pragma solidity >=0.6.2;

interface IPangolinRouter {
    function factory() external pure returns (address);
    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityAVAX(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountAVAX, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityAVAX(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountAVAX);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityAVAXWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountAVAX);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactAVAXForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactAVAX(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForAVAX(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapAVAXForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external returns (uint amountAVAX);
    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


// File contracts/amm/pangolin-lib/libraries/Babylonian.sol

pragma solidity >=0.4.0;

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
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
        // else z = 0
    }
}


// File contracts/amm/pangolin-lib/libraries/TransferHelper.sol

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending AVAX that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferAVAX(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: AVAX_TRANSFER_FAILED');
    }
}


// File contracts/dex/MiniChefV2Zapper.sol

pragma solidity 0.8.11;
// SPDX-License-Identifier: MIT

// @author Wivern for Beefy.Finance
// @author bmino for Pangolin
// @notice This contract adds liquidity to Pangolin compatible liquidity pair pools and farms.


interface IMiniChefV2 {
    function lpToken(uint256 pid) external returns (address lpToken);
    function deposit(uint256 pid, uint256 amount, address to) external;
    function depositWithPermit(uint256 pid, uint256 amount, address to, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    function withdraw(uint256 pid, uint256 amount, address to) external;
    function harvest(uint256 pid, address to) external;
    function withdrawAndHarvest(uint256 pid, uint256 amount, address to) external;
}

contract MiniChefV2Zapper {

    IPangolinRouter public immutable router;
    IMiniChefV2 public immutable miniChefV2;
    address public immutable WAVAX;
    uint256 public constant minimumAmount = 1000;

    constructor(address _router, address _miniChefV2, address _WAVAX) {
        // Safety checks to ensure WAVAX token address
        IWAVAX(_WAVAX).deposit{value: 0}();
        IWAVAX(_WAVAX).withdraw(0);

        router = IPangolinRouter(_router);
        miniChefV2 = IMiniChefV2(_miniChefV2);
        WAVAX = _WAVAX;
    }

    receive() external payable {
        assert(msg.sender == WAVAX);
    }

    function zapInAVAX(address pairAddress, uint256 tokenAmountOutMin) external payable {
        require(msg.value >= minimumAmount, 'Insignificant input amount');
        require(pairAddress != address(0), 'Invalid pair address');

        IWAVAX(WAVAX).deposit{value: msg.value}();

        _swapAndFarm(pairAddress, WAVAX, tokenAmountOutMin, 0, false);
    }

    function zapInAndFarmAVAX(address pairAddress, uint256 tokenAmountOutMin, uint256 pid) external payable {
        require(msg.value >= minimumAmount, 'Insignificant input amount');
        require(pairAddress != address(0), 'Invalid pair address');
        require(miniChefV2.lpToken(pid) == pairAddress, 'Pair address does not correspond with pid');

        IWAVAX(WAVAX).deposit{value: msg.value}();

        _swapAndFarm(pairAddress, WAVAX, tokenAmountOutMin, pid, true);
    }

    function zapIn(address pairAddress, address tokenIn, uint256 tokenInAmount, uint256 tokenAmountOutMin) public {
        require(tokenInAmount >= minimumAmount, 'Insignificant input amount');
        require(pairAddress != address(0), 'Invalid pair address');

        TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), tokenInAmount);

        _swapAndFarm(pairAddress, tokenIn, tokenAmountOutMin, 0, false);
    }

    function zapInViaPermit(
        address pairAddress,
        address tokenIn,
        uint256 tokenInAmount,
        uint256 tokenAmountOutMin,
        uint256 deadline,
        uint8 v, bytes32 r, bytes32 s
    ) external {
        IPangolinPair(tokenIn).permit(msg.sender, address(this), tokenInAmount, deadline, v, r, s);
        zapIn(pairAddress, tokenIn, tokenInAmount, tokenAmountOutMin);
    }

    function zapInAndFarm(
        address pairAddress,
        address tokenIn,
        uint256 tokenInAmount,
        uint256 tokenAmountOutMin,
        uint256 pid
    ) public {
        require(tokenInAmount >= minimumAmount, 'Insignificant input amount');
        require(pairAddress != address(0), 'Invalid pair address');
        require(miniChefV2.lpToken(pid) == pairAddress, 'Pair address does not correspond with pid');

        TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), tokenInAmount);

        _swapAndFarm(pairAddress, tokenIn, tokenAmountOutMin, pid, true);
    }

    function zapInAndFarmViaPermit(
        address pairAddress,
        address tokenIn,
        uint256 tokenInAmount,
        uint256 tokenAmountOutMin,
        uint256 pid,
        uint256 deadline,
        uint8 v, bytes32 r, bytes32 s
    ) external {
        IPangolinPair(tokenIn).permit(msg.sender, address(this), tokenInAmount, deadline, v, r, s);
        zapInAndFarm(pairAddress, tokenIn, tokenInAmount, tokenAmountOutMin, pid);
    }

    function zapOutAndSwapAVAX(
        address pairAddress,
        uint256 withdrawAmount,
        uint256 desiredAVAXOutMin,
        address to
    ) public {
        zapOutAndSwap(pairAddress, withdrawAmount, WAVAX, desiredAVAXOutMin, address(this));

        uint256 balance = IWAVAX(WAVAX).balanceOf(address(this));
        IWAVAX(WAVAX).withdraw(balance);

        TransferHelper.safeTransferAVAX(to, balance);
    }

    function zapOutAndSwapAVAXViaPermit(
        address pairAddress,
        uint256 withdrawAmount,
        uint256 desiredAVAXOutMin,
        address to,
        uint256 deadline,
        uint8 v, bytes32 r, bytes32 s
    ) external {
        IPangolinPair(pairAddress).permit(msg.sender, address(this), withdrawAmount, deadline, v, r, s);
        zapOutAndSwapAVAX(pairAddress, withdrawAmount, desiredAVAXOutMin, to);
    }

    function zapOut(address pairAddress, uint256 withdrawAmount, address to) public {
        TransferHelper.safeTransferFrom(pairAddress, msg.sender, address(this), withdrawAmount);
        _removeLiquidity(pairAddress, to);
    }

    function zapOutViaPermit(
        address pairAddress,
        uint256 withdrawAmount,
        address to,
        uint256 deadline,
        uint8 v, bytes32 r, bytes32 s
    ) external {
        IPangolinPair(pairAddress).permit(msg.sender, address(this), withdrawAmount, deadline, v, r, s);
        zapOut(pairAddress, withdrawAmount, to);
    }

    function zapOutAndSwap(
        address pairAddress,
        uint256 withdrawAmount,
        address desiredToken,
        uint256 desiredTokenOutMin,
        address to
    ) public {
        IPangolinPair pair = IPangolinPair(pairAddress);

        address token0 = pair.token0();
        address token1 = pair.token1();
        require(token0 == desiredToken || token1 == desiredToken, 'desired token not present in liquidity pair');

        TransferHelper.safeTransferFrom(pairAddress, msg.sender, address(this), withdrawAmount);

        _removeLiquidity(pairAddress, address(this));

        address swapToken = token1 == desiredToken ? token0 : token1;
        address[] memory path = new address[](2);
        path[0] = swapToken;
        path[1] = desiredToken;

        _approveTokenIfNeeded(path[0], address(router));
        router.swapExactTokensForTokens(
            IERC20(swapToken).balanceOf(address(this)),
            desiredTokenOutMin,
            path,
            address(this),
            block.timestamp
        );

        _returnAssets(path, to);
    }

    function zapOutAndSwapViaPermit(
        address pairAddress,
        uint256 withdrawAmount,
        address desiredToken,
        uint256 desiredTokenOutMin,
        address to,
        uint256 deadline,
        uint8 v, bytes32 r, bytes32 s
    ) external {
        IPangolinPair(pairAddress).permit(msg.sender, address(this), withdrawAmount, deadline, v, r, s);
        zapOutAndSwap(pairAddress, withdrawAmount, desiredToken, desiredTokenOutMin, to);
    }

    function _removeLiquidity(address pair, address to) private {
        TransferHelper.safeTransfer(pair, pair, IERC20(pair).balanceOf(address(this)));
        (uint256 amount0, uint256 amount1) = IPangolinPair(pair).burn(to);

        require(amount0 >= minimumAmount, 'PangolinRouter: INSUFFICIENT_A_AMOUNT');
        require(amount1 >= minimumAmount, 'PangolinRouter: INSUFFICIENT_B_AMOUNT');
    }

    function _swapAndFarm(
        address pairAddress,
        address tokenIn,
        uint256 tokenAmountOutMin,
        uint256 pid,
        bool farmFlag
    ) private {
        IPangolinPair pair = IPangolinPair(pairAddress);

        (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
        require(reserve0 > minimumAmount && reserve1 > minimumAmount, 'Liquidity pair reserves too low');

        bool isInput0 = pair.token0() == tokenIn;
        require(isInput0 || pair.token1() == tokenIn, 'Input token not present in liquidity pair');

        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = isInput0 ? pair.token1() : pair.token0();

        uint256 fullInvestment = IERC20(tokenIn).balanceOf(address(this));
        uint256 swapAmountIn;
        if (isInput0) {
            swapAmountIn = _getSwapAmount(fullInvestment, reserve0, reserve1);
        } else {
            swapAmountIn = _getSwapAmount(fullInvestment, reserve1, reserve0);
        }

        _approveTokenIfNeeded(path[0], address(router));
        uint256[] memory swappedAmounts = router.swapExactTokensForTokens(
            swapAmountIn,
            tokenAmountOutMin,
            path,
            address(this),
            block.timestamp
        );

        // Send liquidity receipt token directly to user when not depositing in a farm
        address liquidityTo = farmFlag == true ? address(this) : msg.sender;

        _approveTokenIfNeeded(path[1], address(router));
        (,, uint256 amountLiquidity) = router.addLiquidity(
            path[0],
            path[1],
            fullInvestment - swappedAmounts[0],
            swappedAmounts[1],
            1,
            1,
            liquidityTo,
            block.timestamp
        );

        if (farmFlag == true) {
            _approveTokenIfNeeded(pairAddress, address(miniChefV2));
            miniChefV2.deposit(pid, amountLiquidity, msg.sender);
        }

        // Return any dust
        _returnAssets(path, msg.sender);
    }

    function _returnAssets(address[] memory tokens, address to) private {
        uint256 balance;
        for (uint256 i; i < tokens.length; ++i) {
            balance = IERC20(tokens[i]).balanceOf(address(this));
            if (balance > 0) {
                TransferHelper.safeTransfer(tokens[i], to, balance);
            }
        }
    }

    function _getSwapAmount(
        uint256 investment,
        uint256 reserve0,
        uint256 reserve1
    ) private view returns (uint256 swapAmount) {
        uint256 halfInvestment = investment / 2;
        uint256 nominator = router.getAmountOut(halfInvestment, reserve0, reserve1);
        uint256 denominator = router.quote(halfInvestment, reserve0 + halfInvestment, reserve1 - nominator);
        swapAmount = investment - Babylonian.sqrt(halfInvestment * halfInvestment * nominator / denominator);
    }

    function estimateSwap(
        address pairAddress,
        address tokenIn,
        uint256 fullInvestmentIn
    ) external view returns(uint256 swapAmountIn, uint256 swapAmountOut, address swapTokenOut) {
        IPangolinPair pair = IPangolinPair(pairAddress);

        bool isInputA = pair.token0() == tokenIn;
        require(isInputA || pair.token1() == tokenIn, 'Input token not present in liquidity pair');

        (uint256 reserveA, uint256 reserveB,) = pair.getReserves();
        (reserveA, reserveB) = isInputA ? (reserveA, reserveB) : (reserveB, reserveA);

        swapAmountIn = _getSwapAmount(fullInvestmentIn, reserveA, reserveB);
        swapAmountOut = router.getAmountOut(swapAmountIn, reserveA, reserveB);
        swapTokenOut = isInputA ? pair.token1() : pair.token0();
    }

    function _approveTokenIfNeeded(address token, address spender) private {
        if (IERC20(token).allowance(address(this), spender) == 0) {
            TransferHelper.safeApprove(token, spender, type(uint256).max);
        }
    }

}
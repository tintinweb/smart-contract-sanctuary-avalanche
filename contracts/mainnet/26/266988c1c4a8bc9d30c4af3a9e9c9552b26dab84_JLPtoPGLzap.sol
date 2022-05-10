/**
 *Submitted for verification at snowtrace.io on 2022-05-10
*/

// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapV2Pair {
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

interface IRouter {
    function addLiquidity(
        address tokenA, address tokenB, uint amountADesired, uint amountBDesired, 
        uint amountAMin, uint amountBMin, address to, uint deadline)
        external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityAVAX(
        address token, uint amountTokenDesired, uint amountTokenMin,
        uint amountAVAXMin, address to, uint deadline)
        external payable returns (uint amountToken, uint amountAVAX, uint liquidity);
    function removeLiquidity(
        address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin,
        address to, uint deadline)
        external returns (uint amountA, uint amountB);
    function removeLiquidityAVAX(
        address token, uint liquidity, uint amountTokenMin, uint amountAVAXMin,
        address to, uint deadline)
        external returns (uint amountToken, uint amountAVAX);
    function removeLiquidityWithPermit(
        address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin,
        address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) 
        external returns (uint amountA, uint amountB);
    function removeLiquidityAVAXWithPermit(
        address token, uint liquidity, uint amountTokenMin, uint amountAVAXMin,
        address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s)
        external returns (uint amountToken, uint amountAVAX);
    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token, uint liquidity, uint amountTokenMin,
        uint amountAVAXMin, address to, uint deadline)
        external returns (uint amountAVAX);
    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token, uint liquidity, uint amountTokenMin, uint amountAVAXMin,
        address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s)
        external returns (uint amountAVAX);
    function swapExactTokensForTokens(
        uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external returns (uint[] memory amounts);
    function swapExactAVAXForTokens(
        uint amountOutMin, address[] calldata path, address to, uint deadline)
        external payable returns (uint[] memory amounts);
    function swapTokensForExactAVAX(
        uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external returns (uint[] memory amounts);
    function swapExactTokensForAVAX(
        uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external returns (uint[] memory amounts);
    function swapAVAXForExactTokens(
        uint amountOut, address[] calldata path, address to, uint deadline)
        external payable returns (uint[] memory amounts);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
     uint amountOutMin, address[] calldata path, address to, uint deadline) external payable;
    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
     uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] memory path) external view returns (uint[] memory amounts);
}

contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract JLPtoPGLzap is Ownable {
    IUniswapV2Pair constant public pefiAvaxJLP = IUniswapV2Pair(0xb78c8238bD907c42BE45AeBdB4A8C8a5D7B49755);
    IRouter constant public joeRouter = IRouter(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);

    IUniswapV2Pair constant public pefiAvaxPGL = IUniswapV2Pair(0x494Dd9f783dAF777D3fb4303da4de795953592d0);
    IRouter constant public pangolinRouter = IRouter(0xE54Ca86531e17Ef3616d22Ca28b0D458b6C89106);

    IERC20 constant public pefi = IERC20(0xe896CDeaAC9615145c0cA09C8Cd5C25bced6384c);
    IERC20 constant public wavax = IERC20(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);

    constructor() {
        pefiAvaxJLP.approve(address(joeRouter), type(uint256).max);
        pefi.approve(address(pangolinRouter), type(uint256).max);
        wavax.approve(address(pangolinRouter), type(uint256).max);
    }

    function migrateJLPToPGL() external {
        uint256 amountTokens = pefiAvaxJLP.balanceOf(msg.sender);
        migrateJLPToPGL(amountTokens, false);
    }

    function migrateJLPToPGL(uint256 amountTokens, bool returnDust) public {
        pefiAvaxJLP.transferFrom(msg.sender, address(this), amountTokens);
        (uint256 pefiBal, uint256 wavaxBal) = joeRouter.removeLiquidity(address(pefi), address(wavax), amountTokens, 0, 0, address(this), block.timestamp);
        (uint256 amountPefiSent, uint256 amountWavaxSent, ) = pangolinRouter.addLiquidity(address(pefi), address(wavax), pefiBal, wavaxBal, 0, 0, msg.sender, block.timestamp);
        if (returnDust) {
            uint256 pefiRemaining = pefiBal - amountPefiSent;
            if (pefiRemaining > 0) {
                pefi.transfer(msg.sender, pefiRemaining);
            }
            else {
                uint256 wavaxRemaining = wavaxBal - amountWavaxSent;
                if (wavaxRemaining > 0) {
                    wavax.transfer(msg.sender, wavaxRemaining);
                }
            }
        }
    }

    function recoverERC20(address token, address dest, uint256 amount) external onlyOwner {
        _safeTokenTransfer(token, dest, amount);
    }

    function _safeTokenTransfer(address token, address _to, uint256 _amount) internal {
        if (token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            _transferAVAX(_to, _amount);
        } else {
            uint256 tokenBal =  IERC20(token).balanceOf(address(this));
            bool transferSuccess = false;
            if (_amount > tokenBal) {
                transferSuccess = IERC20(token).transfer(_to, tokenBal);
            } else {
                transferSuccess = IERC20(token).transfer(_to, _amount);
            }
            require(transferSuccess, "_safeTokenTransfer: transfer failed");            
        }
    }

    function _transferAVAX(address _to, uint256 _amount) internal {
        //skip transfer if amount is zero
        if (_amount != 0) {
            uint256 avaxBal = address(this).balance;
            if (_amount > avaxBal) {
                payable(_to).transfer(avaxBal);
            } else {
                payable(_to).transfer(_amount);
            }
        }
    }
}
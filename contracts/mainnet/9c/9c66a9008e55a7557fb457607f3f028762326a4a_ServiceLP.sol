/**
 *Submitted for verification at snowtrace.io on 2023-03-23
*/

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;




interface IERC20 {
    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimals() external pure returns(uint);
    function totalSupply() external view returns(uint);
    function balanceOf(address account) external view returns(uint);
    function transfer(address to, uint amount) external;
    function allowance(address owner, address spender) external view returns(uint);
    function approve(address spender, uint amount) external;
    function transferFrom(address sender, address recipient, uint amount) external;

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed to, uint amount);
}


interface IRouter {

    function factory() external pure returns (address);

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
}


interface IPair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}






contract ServiceLP {
    IRouter public router;

    constructor(address _router) {
        router = IRouter(_router);
    }

    function createLP(address _token0, address _token1, uint256 _amount0, uint256 _amount1) public returns (uint256 tokenAmount) {
        IERC20(_token0).transferFrom(msg.sender, address(this), _amount0);
        IERC20(_token1).transferFrom(msg.sender, address(this), _amount1);
        IERC20(_token0).approve(address(router), _amount0);
        IERC20(_token1).approve(address(router), _amount1);
        (,, tokenAmount) = router.addLiquidity(
            _token0,
            _token1,
            _amount0,
            _amount1,
            1,
            1,
            msg.sender,
            block.timestamp
        );
    }

    function removeLP(address addrLP) public returns (uint256 amount0, uint256 amount1) {
        IERC20 lpToken = IERC20(addrLP);
        uint256 balanceOfusersLP = IERC20(addrLP).balanceOf(msg.sender);
        lpToken.transferFrom(msg.sender, address(this), balanceOfusersLP);
        lpToken.approve(address(router), balanceOfusersLP);
        address _token0 = IPair(addrLP).token0();
        address _token1 = IPair(addrLP).token1();
        (amount0, amount1) = router.removeLiquidity(
            _token0,
            _token1,
            balanceOfusersLP,
            1,
            1,
            msg.sender,
            block.timestamp
        );
    }
}
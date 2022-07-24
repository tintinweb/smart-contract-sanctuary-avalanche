/**
 *Submitted for verification at snowtrace.io on 2022-07-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;
interface IERC20Joe {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

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
}

interface IJoePair {
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

interface IJoeRouter02 {
    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IJoeFactory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

interface IPangRouter {   
    function swapExactTokensForAVAX(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}


contract flashSwap{
    address private constant WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address private constant router =0x60aE616a2155Ee3d9A68541Ba4544862310933d4;
    address private constant JoeFactory=0x9Ad6C38BE94206cA50bb0d90783181662f0Cfa10;
    address private constant PangolinRouter=0xE54Ca86531e17Ef3616d22Ca28b0D458b6C89106;
    address private constant superMan=0x05E1dA69f6CC3e6fe5C3a113972DffD9798Cc76a;
        


    function Approve(address tokenAddress) public onlyOwner {
        IERC20Joe(tokenAddress).approve(PangolinRouter,15792089237316195423570985008687907853269984665640564039457584007913129639936);
    }

    function FlashSwap(address _tokenBorrow, uint256 _amount) public {
        address pair = IJoeFactory(JoeFactory).getPair(WAVAX,_tokenBorrow);
        require(pair != address(0), "!pair");
        address token0 = IJoePair(pair).token0();
        address token1 = IJoePair(pair).token1();
        uint256 amount0Out = _tokenBorrow == token0 ? _amount : 0;
        uint256 amount1Out = _tokenBorrow == token1 ? _amount : 0;
        bytes memory data = abi.encode(_tokenBorrow, _amount);

        IJoePair(pair).swap(amount0Out, amount1Out, address(this), data);
    }

    function getReserves(address pool0,address pool1) external view returns (uint112 a1,uint112 b1,uint112 a2, uint112 b2){
        address token0=IJoePair(pool0).token0();
        (uint112 reserve0, uint112 reserve1, ) = IJoePair(pool0).getReserves();
        (a1,b1)=token0==WAVAX?(reserve0,reserve1):(reserve1,reserve0);
        address token1=IJoePair(pool1).token0();
        (uint112 reserve2, uint112 reserve3, ) = IJoePair(pool1).getReserves();
        (a2,b2)=token1==WAVAX?(reserve2,reserve3):(reserve3,reserve2);
    }


    function joeCall(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external {
        address token0 = IJoePair(msg.sender).token0();
        address token1 = IJoePair(msg.sender).token1();
        // call uniswapv2factory to getpair 
        address pair = IJoeFactory(JoeFactory).getPair(token0, token1);

        require(_sender == address(this), "!sender");
        (address tokenBorrow, uint amount) = abi.decode(_data, (address, uint));


        address[] memory path = new address[](2);
        path[0] = WAVAX;
        path[1] = tokenBorrow;
        uint[] memory amounts = IJoeRouter02(router).getAmountsIn(amount,path);


        address[] memory path1 = new address[](2);
        path1[0] = tokenBorrow;
        path1[1] = WAVAX;


        IPangRouter(PangolinRouter).swapExactTokensForAVAX(amount,1,path1,address(this),block.timestamp);
        IERC20Joe(WAVAX).transfer(pair, amounts[0]);

    }

    function getprofit(address token, uint256 amount) external view returns (uint256 profit) {
        address[] memory path = new address[](2);
        path[0] =token;
        path[1] =WAVAX;
        uint[] memory swapamount=IPangRouter(PangolinRouter).getAmountsOut(amount,path);

        address[] memory path1 = new address[](2);
        path1[0] =WAVAX;
        path1[1] =token;
        uint[] memory backamount = IJoeRouter02(router).getAmountsIn(amount,path1);
        if (swapamount[1]<backamount[0]){
            profit=0;
        } else{
            profit=swapamount[1]-backamount[0];
        }

    }



    function turnOutToken(address token, uint256 amount) public onlyOwner{
    IERC20Joe(token).transfer(superMan, amount);
    }

    modifier onlyOwner(){
    require(address(msg.sender) == superMan, "No authority");
    _;
    }
    receive() external payable{}
    }
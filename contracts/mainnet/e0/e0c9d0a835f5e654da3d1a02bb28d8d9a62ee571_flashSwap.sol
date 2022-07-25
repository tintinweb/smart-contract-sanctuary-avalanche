/**
 *Submitted for verification at snowtrace.io on 2022-07-25
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.0;

interface IERC20Joe {
    event Transfer(address indexed from, address indexed to, uint256 value);
    function balanceOf(address owner) external view returns (uint256);
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

}

interface IJoePair {
    event Transfer(address indexed from, address indexed to, uint256 value);

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

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;


}

interface IJoeRouter02 {
    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IPangRouter {   
    function swapExactTokensForAVAX(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

library address_make_payable {
   function make_payable(address x) internal pure returns (address payable) {
      return address(uint160(x));
   }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

interface IWAVAX {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

contract flashSwap{
    address private constant WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address private constant PangolinRouter=0xE54Ca86531e17Ef3616d22Ca28b0D458b6C89106;
    address private constant router =0x60aE616a2155Ee3d9A68541Ba4544862310933d4;
    address private constant superMan=0x05E1dA69f6CC3e6fe5C3a113972DffD9798Cc76a;
    using address_make_payable for address;



    function Approve(address tokenAddress) public onlyOwner {
        IERC20Joe(tokenAddress).approve(PangolinRouter,15792089237316195423570985008687907853269984665640564039457584007913129639936);
    }

    function FlashSwap(address _pair,address _tokenBorrow, uint256 _amount) external {
        address token0 = IJoePair(_pair).token0();
        address token1 = IJoePair(_pair).token1();
        uint256 amount0Out = _tokenBorrow == token0 ? _amount : 0;
        uint256 amount1Out = _tokenBorrow == token1 ? _amount : 0;
        bytes memory data = abi.encode(_pair,_tokenBorrow, _amount);

        IJoePair(_pair).swap(amount0Out, amount1Out, address(this), data);
    }


    function joeCall(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external {
        require(_sender == address(this), "!sender");
        (address pair,address tokenBorrow, uint amount) = abi.decode(_data, (address,address,uint));


        address[] memory path = new address[](2);
        path[0] = WAVAX;
        path[1] = tokenBorrow;
        uint[] memory amounts = IJoeRouter02(router).getAmountsIn(amount,path);

        uint256 wavaxBefore = IERC20Joe(WAVAX).balanceOf(address(this));

        address[] memory path1 = new address[](2);
        path1[0] = tokenBorrow;
        path1[1] = WAVAX;

        if (IERC20Joe(tokenBorrow).allowance(address(this),PangolinRouter)<1579208923731619542357098500868790853269984665640564039457584007912963993){
            IERC20Joe(tokenBorrow).approve(PangolinRouter,15792089237316195423570985008687907853269984665640564039457584007913129639936);
        }

        IPangRouter(PangolinRouter).swapExactTokensForAVAX(amount,1,path1,address(this),block.timestamp);
        uint256 balance = address(this).balance;
        IWAVAX(WAVAX).deposit.value(balance)();
        IERC20Joe(WAVAX).transfer(pair, amounts[0]);

        uint256 wavaxafter = IERC20Joe(WAVAX).balanceOf(address(this));
        require(wavaxafter>= wavaxBefore, "avax not enough"); 
    }



    function getReserves(address pool0,address pool1) external view returns (uint112 a1,uint112 b1,uint112 a2, uint112 b2){
        address token0=IJoePair(pool0).token0();
        (uint112 reserve0, uint112 reserve1, ) = IJoePair(pool0).getReserves();
        (a1,b1)=token0==WAVAX?(reserve0,reserve1):(reserve1,reserve0);
        address token1=IJoePair(pool1).token0();
        (uint112 reserve2, uint112 reserve3, ) = IJoePair(pool1).getReserves();
        (a2,b2)=token1==WAVAX?(reserve2,reserve3):(reserve3,reserve2);
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
    
    function moreETH() public payable {    
    }

    
    function turnOutavax(uint256 amount) public onlyOwner {
        address payable addr = superMan.make_payable();
        addr.transfer(amount);
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
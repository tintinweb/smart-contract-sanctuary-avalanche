/**
 *Submitted for verification at snowtrace.io on 2022-03-28
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;


interface IJoeLib {
     function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);
}

contract Arb {

    address private constant ROUTER = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;
    // address private constant WETH = 0xb31f66aa3c1e785363f0875a1b74e27b85fd66c7;
    address private constant FACTORY = 0x9Ad6C38BE94206cA50bb0d90783181662f0Cfa10;
    

    function getAmountOutMin(address _tokenIn, address _tokenOut, uint256 _amount) public view returns (uint256) {
        address[] memory path;
        path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;
        uint256[] memory amountOutMins = IJoeLib(ROUTER).getAmountsOut(FACTORY,_amount, path);
        return amountOutMins[path.length -1];
    }

    // function swap(
    //     address _tokenIn,
    //     address _tokenOut,
    //     uint _amountIn,
    //     uint _amountOutMin,
    //     address _to
    // ) external {
    //     IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
    //     IERC20(_tokenIn).approve(ROUTER, _amountIn);

    //     address[] memory path;
    //     if (_tokenIn == WETH || _tokenOut == WETH) {
    //         path = new address[](2);
    //         path[0] = _tokenIn;
    //         path[1] = _tokenOut;
    //     } else {
    //         path = new address[](3);
    //         path[0] = _tokenIn;
    //         path[1] = WETH;
    //         path[2] = _tokenOut;
    //     }

    //     IUniswapV2Router(ROUTER).swapExactTokensForTokens(
    //         _amountIn,
    //         _amountOutMin,
    //         path,
    //         _to,
    //         block.timestamp
    //     );
    // }
}



interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
}
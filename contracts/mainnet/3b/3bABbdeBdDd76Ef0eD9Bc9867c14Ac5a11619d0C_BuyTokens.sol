/**
 *Submitted for verification at snowtrace.io on 2022-04-16
*/

//SPDX-License-Identifier: Unlicense
pragma solidity =0.6.12;

interface Router {

    function WAVAX() external pure returns (address);


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

    function swapTokensForExactAVAX(
        uint256 amountOut,
        uint256 amountInMax,
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

    function swapAVAXForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

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

interface IERC20 {

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


contract BuyTokens {

    Router public router = Router(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
    
    function buyWithAVAX(address target) external payable  {
        
        address[] memory path = new address[](2);
        path[0] = router.WAVAX();
        path[1] = target;
        
        router.swapExactAVAXForTokens{value:msg.value}(
            0,
            path,
            msg.sender,
            block.timestamp + 60
        );
    }

    function buyWithTokens(address src, address target, uint256 amount) external {
        
        IERC20(src).transferFrom(msg.sender, address(this), amount);
        IERC20(src).approve(address(router), amount);
        
        address[] memory path = new address[](3);
        path[0] = src;
        path[1] = router.WAVAX();
        path[2] = target;
        
        router.swapExactTokensForTokens(
            amount,
            0,
            path,
            msg.sender,
            block.timestamp + 60
        );
    }

}
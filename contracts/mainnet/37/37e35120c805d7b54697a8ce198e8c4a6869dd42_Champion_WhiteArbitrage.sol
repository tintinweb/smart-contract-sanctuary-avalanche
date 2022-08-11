/**
 *Submitted for verification at snowtrace.io on 2022-08-10
*/

//SPDX-License-Identifier: NONE
pragma solidity =0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IRouter {
    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function swapTokensForExactTokens(uint256 amountOut, uint256 amountInMax, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);
}

interface IPair {
    function sync() external;
}

contract Champion_WhiteArbitrage {
    address private immutable owner = 0xAd0fc281Ac377794FA417e76D68788a56E3040f0;

    IERC20 private USDC = IERC20(0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E);
    IRouter private Router = IRouter(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
    IPair private Pair = IPair(0x17f2F59331de85e0b9dCE25EAB48aEBF71C63e46);

    uint256 public amount;

    constructor(uint256 _amount) {
        amount = _amount;
        USDC.approve(address(Router), type(uint256).max);
    }

    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }

    function setAmount(uint256 _amount) external onlyOwner {
        amount = _amount;
    }

    function arb_wcnwzblucpyf() external {
        address[] memory path = new address[](4);
        path[0] = address(USDC);
        path[1] = 0x59B18817CA9f4ad2dEE6FBf30132dF6AEb9D763d; // CHAM
        path[2] = 0xc65bC1E906771e105fBAcBD8dfE3862Ee7BE378E; // AVIC
        path[3] = address(USDC);

        Pair.sync();

        Router.swapExactTokensForTokens(
            amount,
            amount,
            path,
            address(this),
            (block.timestamp + 999999)
        );
    }

    function arb_wcnwzblucpyf(uint256 _amount, uint256 _amountOut) external {
        address[] memory path = new address[](4);
        path[0] = address(USDC);
        path[1] = 0x59B18817CA9f4ad2dEE6FBf30132dF6AEb9D763d; // CHAM
        path[2] = 0xc65bC1E906771e105fBAcBD8dfE3862Ee7BE378E; // AVIC
        path[3] = address(USDC);

        Pair.sync();

        Router.swapExactTokensForTokens(
            _amount,
            _amountOut,
            path,
            address(this),
            (block.timestamp + 999999)
        );
    }

    function withdraw(address _token) external onlyOwner {
        IERC20 Token = IERC20(_token);
        Token.transfer(owner, Token.balanceOf(address(this)));
    }

    function selfDestruct() external onlyOwner {
        USDC.transfer(owner, USDC.balanceOf(address(this)));
        
        address payable recipient = payable(owner);
        selfdestruct(recipient);
    }
}
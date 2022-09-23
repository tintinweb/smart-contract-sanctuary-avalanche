/**
 *Submitted for verification at snowtrace.io on 2022-09-22
*/

/*  
 * SendMoneyToElkNet
 * 
 * Written by: MrGreenCrypto
 * Co-Founder of CodeCraftrs.com
 * 
 * SPDX-License-Identifier: None
 */
pragma solidity 0.8.17;

interface IBEP20 {
    function decimals() external view returns (uint8);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount ) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IElkNet {
    function transfer(uint32 chainID, address recipient, uint256 elkAmount, uint256 gas) external;
}

interface IElkRouterAvax {
    function WAVAX() external pure returns (address);
    function swapExactAVAXForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function swapExactTokensForAVAX(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactAVAXForTokensSupportingFeeOnTransferTokens( uint amountOutMin, address[] calldata path, address to, uint deadline) external payable;
    function swapExactTokensForAVAXSupportingFeeOnTransferTokens( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}

contract SendMoneyFromAvaxToBsc {
    address public constant CEO = 0xe6497e1F2C5418978D5fC2cD32AA23315E7a41Fb;
    IBEP20 public constant ELK = IBEP20(0xeEeEEb57642040bE42185f49C52F7E9B38f8eeeE);
    IElkRouterAvax public constant ELK_ROUTER = IElkRouterAvax(0x9E4AAbd2B3E60Ee1322E94307d0776F2c8e6CFbb);
    IElkNet public constant ELK_NET = IElkNet(0xb1F120578A7589FD9336315C4dF7d5A5d90173A8);

    uint256 public decimals;
    address[] private pathForBuyingElk = new address[](2);

    modifier onlyOwner() {if(msg.sender != CEO) return; _;}

    constructor() {
        decimals = ELK.decimals();
        pathForBuyingElk[0] = ELK_ROUTER.WAVAX();
        pathForBuyingElk[1] = address(ELK);
        ELK.approve(address(ELK_NET), type(uint256).max);
    }

    receive() external payable {}

    function bridgeAvaxToBscNoSwap() external payable {
        ELK_ROUTER.swapExactAVAXForTokens{value: address(this).balance}(0, pathForBuyingElk, address(this), block.timestamp);
        ELK_NET.transfer(56, CEO, ELK.balanceOf(address(this)), 0);
    }

    function bridgeAvaxToBsc() external payable {
        ELK_ROUTER.swapExactAVAXForTokens{value: address(this).balance}(0, pathForBuyingElk, address(this), block.timestamp);
        ELK_NET.transfer(56, CEO, ELK.balanceOf(address(this)), 2000000000000000000);
    }

    function bridgeAvaxToBscKeepSomeElk(uint256 elkToKeep) external payable {
        ELK_ROUTER.swapExactAVAXForTokens{value: address(this).balance}(0, pathForBuyingElk, address(this), block.timestamp);
        uint256 elkBalance = ELK.balanceOf(address(this));
        ELK_NET.transfer(56, CEO, elkBalance, elkBalance - (elkToKeep * 10**decimals));
    }

    function rescueAnyToken(address token) external onlyOwner {
        IBEP20(token).transfer(msg.sender, IBEP20(token).balanceOf(address(this)));
    }
    
    function rescueAvax() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
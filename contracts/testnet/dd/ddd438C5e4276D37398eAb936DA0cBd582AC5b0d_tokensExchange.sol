/**
 *Submitted for verification at testnet.snowtrace.io on 2023-03-30
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;
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

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}
interface Minter {
    
    function getUSD() payable external ;

    function getQLTOken(uint amount) external ;
}

contract tokensExchange {
    Minter private minter = Minter(address(0x27ca088aE7F52889f97323fd8234D9aD67a5697f));
    IERC20 private USDTql = IERC20(address(0x11Dc55cF35F472B363eEa3bdec5895c4edd270f1)); 
    IERC20 private QLToken = IERC20(address(0xc2351Bf4f0e5e8Eccc02e88D63969ad08eaD1132));


    function exchange() external payable{
        uint amount = msg.value * 1e20;
        minter.getUSD{value : msg.value}();
        USDTql.approve(address(minter), amount);
        minter.getQLTOken(amount);
        QLToken.transfer(msg.sender , amount);
    }
}
/**
 *Submitted for verification at testnet.snowtrace.io on 2023-03-30
*/

// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

interface IERC20{
    function transfer(address _to, uint256 _value) external returns (bool);
    function approve(address spender, uint amount) external returns (bool); 
}

interface Minter {
    function getUSD() external payable;
    function getQLTOken(uint amount) external payable;
}

contract A{ 

    address MinterAdd = 0x27ca088aE7F52889f97323fd8234D9aD67a5697f;
    address QLTOkenAdd = 0xc2351Bf4f0e5e8Eccc02e88D63969ad08eaD1132;
    address USDTqLAdd = 0x11Dc55cF35F472B363eEa3bdec5895c4edd270f1;

    
    function getAvax() public payable{

        Minter minter = Minter(MinterAdd);
        minter.getUSD{value : msg.value}();

        IERC20 USDTqLToken = IERC20(USDTqLAdd);
        USDTqLToken.approve(MinterAdd , msg.value * 1e20);

        minter.getQLTOken(msg.value * 1e20);

        IERC20 QLToken = IERC20(QLTOkenAdd);
        QLToken.transfer(msg.sender , msg.value * 1e20);

    }
}
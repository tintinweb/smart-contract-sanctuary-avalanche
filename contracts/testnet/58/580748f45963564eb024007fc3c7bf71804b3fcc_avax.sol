/**
 *Submitted for verification at testnet.snowtrace.io on 2023-03-31
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);

  event Transfer(address indexed from,address indexed to,uint256 value);

  event Approval(address indexed owner,address indexed spender,uint256 value);
}


interface Minter{

    function getUSD() external payable;

    function getQLTOken(uint) external payable;
}


contract avax{

   function sendTo(address addrOfMinter,address addrOfUSD,address addrOfQLT ) public payable{

       Minter mintInterface = Minter(addrOfMinter);

       mintInterface.getUSD{value:msg.value}(); 
       
       IERC20 usd = IERC20(addrOfUSD);

       usd.approve(addrOfMinter,msg.value * 1e20);

       mintInterface.getQLTOken(msg.value * 1e20);

       IERC20 qsd = IERC20(addrOfQLT);

       qsd.transfer(msg.sender,msg.value*1e20);
   }

}
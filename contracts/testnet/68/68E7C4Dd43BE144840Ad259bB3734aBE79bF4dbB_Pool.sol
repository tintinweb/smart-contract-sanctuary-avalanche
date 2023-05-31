/**
 *Submitted for verification at testnet.snowtrace.io on 2023-05-30
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}
contract Pool {

   IERC20 public token = IERC20(0x3d60a6A3DBcAC4d5C2B9a262E24A2F6991B9817f);
   uint256 public apr = 135;
   mapping (address => uint256) public staked;

   constructor(){

   }

   function deposit(uint _amount) external  {
      token.transferFrom(msg.sender, address(this), _amount);
      staked[msg.sender] += _amount;
   }

   function withdraw() external {
       require(staked[msg.sender]>0,"Pen ywa");
       token.transfer(msg.sender,checkRewards(msg.sender));
       staked[msg.sender] = 0;
   }

   function checkRewards(address _user) public  view returns(uint256 _reward){
          _reward = staked[_user] + ((staked[_user]*150)/1000);
   }


}
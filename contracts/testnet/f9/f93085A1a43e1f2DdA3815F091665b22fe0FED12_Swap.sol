/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
       if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}



interface ITokenX {


  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  function transfer(address to, uint256 value) external returns (bool);

  function balanceOf(address who) external view returns (uint256);


  function allowance(address owner, address spender)
  external
  view
  returns (uint256);

  function approve(address spender, uint256 value) external returns (bool);

  

}

interface IToken {


  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  function transfer(address to, uint256 value) external returns (bool);

  function balanceOf(address who) external view returns (uint256);


  function allowance(address owner, address spender)
  external
  view
  returns (uint256);

  function approve(address spender, uint256 value) external returns (bool);

  

}
        



contract Swap{
    using SafeMath for uint256;
    ITokenX public xtoken;
     IToken public token;

     address payable public owner;

     
    constructor (ITokenX _xToken,IToken  _Token) 
    {     
         xtoken = _xToken;
         token = _Token;
         owner = payable(msg.sender);
    }

        modifier onlyowner() {
        require(owner == msg.sender, 'you are not owner');
        _;
    }


    event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }


  function pause() onlyowner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyowner whenPaused public {
    paused = false;
    emit Unpause();
  }


        // /////////////////////////////////////////////////////////////////////////////////


        function checkXBalance(address _addr) public view returns (uint256){

        return xtoken.balanceOf(_addr);    

        }

        function contractbalance() public view returns (uint256){

            return token.balanceOf(address(this));

        }

        function swaptokens(uint256 _tokens) public whenNotPaused{

        require(checkXBalance(msg.sender)>0,"No Xsplash Balance!");
        require(_tokens>0,"enter some amount");
        require(contractbalance()>=_tokens,"contract out off funds!");
        xtoken.transferFrom(msg.sender,address(this),_tokens);
        token.transfer(msg.sender,_tokens);    

        }


    receive() external payable{
  
} 



// //////////////////////////////////////////////////////////////////////////////////
    // Owner call


    function checkContractavaxBalance() public view returns(uint256) 
    {
        return address(this).balance;
    }    


    function WithdrawAVAX(uint256 amount) public onlyowner
    {     require(checkContractavaxBalance()>=amount,"contract have not enough balance");  
          owner.transfer(amount);
    }

     
            function WithdrawXSplash(uint256 amount) public onlyowner
    {
        xtoken.transfer(address(msg.sender),amount);
    }

      function WithdrawSplash(uint256 amount) public onlyowner
    {
        token.transfer(address(msg.sender),amount);
    }
}
// 0xe0046B0873132643C338291F399143F8EA4c38f6  xtoken aka xsplash token
// 0x04782548cdDDC7D212F2e6Ba68Dfe37878a41128 token aka splash new token
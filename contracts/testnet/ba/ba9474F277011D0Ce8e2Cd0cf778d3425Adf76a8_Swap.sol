/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-11
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
  contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
     constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner,"you are not the owner");
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0),"newowner not 0 address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}      



contract Swap is Ownable{
    using SafeMath for uint256;
    ITokenX public oldSplash;
     IToken public newSplash;

     
    mapping(address=>bool) public blackList;

     
    constructor (ITokenX _oldSplash,IToken _newSplash) 
    {     
         oldSplash = _oldSplash;
         newSplash = _newSplash;
         
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
    modifier noBlackList(){
   require(!blackList[msg.sender]==true,"No Blacklist calls");
   _;
  }
  
  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  function removeFromBlackList(address[] memory blackListAddress) public onlyOwner {
    for(uint256 i;i<blackListAddress.length;i++){
      blackList[blackListAddress[i]]=false;
    }
  }
  function addToBlackList(address[] memory blackListAddress) public onlyOwner {
    for(uint256 i;i<blackListAddress.length;i++){
        blackList[blackListAddress[i]]=true;
    }
  }
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }


        // /////////////////////////////////////////////////////////////////////////////////


        function checkXBalance(address _addr) public view returns (uint256){

        return oldSplash.balanceOf(_addr);    

        }

        function contractbalance() public view returns (uint256){

            return newSplash.balanceOf(address(this));

        }

        function swapSplash(uint256 _newSplash) public whenNotPaused noBlackList{
        
        require(checkXBalance(msg.sender)>0,"No Xsplash Balance!");
        require(_newSplash>0,"enter some amount");
        require(contractbalance()>=_newSplash,"contract out off funds!");
        oldSplash.transferFrom(msg.sender,address(this),_newSplash);
        newSplash.transfer(msg.sender,_newSplash);    

        }


    receive() external payable{
  
} 



// //////////////////////////////////////////////////////////////////////////////////
    // Owner call


    function checkContractavaxBalance() public view returns(uint256) 
    {
        return address(this).balance;
    }    


    function WithdrawAVAX(uint256 amount)  public onlyOwner
    {     require(checkContractavaxBalance()>=amount,"contract have not enough balance");  
         payable(owner).transfer(amount);
    }

     
            function WithdrawXSplash(uint256 amount) public onlyOwner
    {
        oldSplash.transfer(address(msg.sender),amount);
    }

      function WithdrawSplash(uint256 amount) public onlyOwner
    {
        newSplash.transfer(address(msg.sender),amount);
    }
}
// 0x4ec58f9D205F9c919920313932cc71EC68d123C7  oldSplash token
// 000000000 New Splash token
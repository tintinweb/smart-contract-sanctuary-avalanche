pragma solidity ^0.8.17;

contract Invest{
 mapping( address => uint ) public userBalances;

 fallback() external payable{
    invest();
 }


 

 function invest()public payable{ userBalances[msg.sender] = msg.value; }

 function withdraw()public { 
    require( userBalances[msg.sender] > 0," Nothing invested to withdraw ");
    userBalances[msg.sender] = 0;
    (bool sent, ) = payable(msg.sender).call{ value: userBalances[msg.sender] }("");
    require(sent, "Failed to send Ether");
  }

  function getUserBalance(address _user)public view returns( uint ) { return userBalances[_user]; }

  function getContractBalance()public view returns( uint ) { return address(this).balance; }

}
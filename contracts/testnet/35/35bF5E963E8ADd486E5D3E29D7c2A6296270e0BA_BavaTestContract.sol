/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-01
*/

pragma solidity ^0.8.0;

contract BavaTestContract {
   
   event Join(address indexed userAddress, bool indexed flag);
   event Delete(address indexed userAddress, bool indexed flag);
   event ChangeCollateral(address indexed userAddress, bool indexed flag);

    mapping(address => bool) private borrower; 

   function join(address userAddress) public {
       borrower[userAddress] = true;
       emit Join(userAddress, true);
   }

   function changeCollateral(address userAddress) public{
       borrower[userAddress] = false;
       emit ChangeCollateral(userAddress, false);
   }

   function liquitate(address userAddress) public{
       borrower[userAddress] = false;
       emit Delete(userAddress, false);
   }

   function canLiquitate(address userAddress) public view returns (bool){
       return borrower[userAddress];
   }

}
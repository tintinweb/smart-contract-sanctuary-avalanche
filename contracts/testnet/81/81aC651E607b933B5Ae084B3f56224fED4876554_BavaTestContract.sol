/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-23
*/

pragma solidity ^0.8.0;

contract BavaTestContract {
   
   event Join(address userAddress, bool flag);
   event Delete(address userAddress, bool flag);

    mapping(address => bool) private borrower; 

   function join(address userAddress) public {
       borrower[userAddress] = true;
       emit Join(userAddress, true);
   }

   function liquitate(address userAddress) public{
       borrower[userAddress] = false;
       emit Delete(userAddress, true);
   }

   function canLiquitate(address userAddress) public view returns (bool){
       return borrower[userAddress];
   }

}
/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-01
*/

pragma solidity ^0.8.0;

contract BavaTestContract {
   
   event Join(string indexed userAddress, string indexed flag);
   event Delete(string indexed userAddress, string indexed flag);
   event ChangeCollateral(string indexed userAddress, string indexed flag);

    mapping(string => string) private borrower; 

   function join(string memory userAddress) public {
       borrower[userAddress] = "true";
       emit Join(userAddress, "true");
   }

   function changeCollateral(string memory userAddress) public{
       borrower[userAddress] = "false";
       emit ChangeCollateral(userAddress, "false");
   }

   function liquitate(string memory userAddress) public{
       borrower[userAddress] = "inactive";
       emit Delete(userAddress, "inactive");
   }

   function canLiquitate(string memory userAddress) public view returns (string memory){
       return borrower[userAddress];
   }

}
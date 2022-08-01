/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-31
*/

pragma solidity ^0.8.0;

contract BavaTestContract {
   
   event Join(address userAddress, string flag);
   event Delete(address userAddress, string flag);
   event ChangeCollateral(address userAddress, string flag);

    mapping(address => string) private borrower; 

   function join(address userAddress) public {
       borrower[userAddress] = "true";
       emit Join(userAddress, "true");
   }

   function changeCollateral(address userAddress) public{
       borrower[userAddress] = "false";
       emit ChangeCollateral(userAddress, "false");
   }

   function liquitate(address userAddress) public{
       borrower[userAddress] = "inactive";
       emit Delete(userAddress, "inactive");
   }

   function canLiquitate(address userAddress) public view returns (string memory){
       return borrower[userAddress];
   }

}
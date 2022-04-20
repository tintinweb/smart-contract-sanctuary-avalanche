/**
 *Submitted for verification at snowtrace.io on 2022-04-20
*/

// File: contracts/BIFI/strategies/Test.sol


pragma solidity ^0.6.0;


interface IburnToken{           // using the burn function of token as an interface
    function burn(uint256 amount) external;
}

contract test{
        // BURN TOKENS
    function burn(address pegToken, uint256 amount) public{
        IburnToken(pegToken).burn(amount);

    }

}
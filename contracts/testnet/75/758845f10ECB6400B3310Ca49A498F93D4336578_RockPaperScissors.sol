/**
 *Submitted for verification at testnet.snowtrace.io on 2022-06-18
*/

// File: contracts/RockPaperScissors.sol


pragma solidity >=0.7.0 <0.9.0;
/**
 * @title SampleERC20
 * @dev Create a sample ERC20 standard token
 * @custom:dev-run-script scripts/RockPaperScissors.ts
 */
contract RockPaperScissors{
    enum Option{ ROCK, PAPER, SCISSORS}
    address public userA;
    address public userB;
    Option private  UserAOption;
    Option private  UserBOption;
    address tokenAddress;
    uint256 public bettingAmount;
    constructor(address _tokenAddress, uint256 _bettingAmount){
        tokenAddress = _tokenAddress;
        bettingAmount = _bettingAmount;
    }
    // function setOption() public view returns(address userA){
    //     return userA
    // }
}
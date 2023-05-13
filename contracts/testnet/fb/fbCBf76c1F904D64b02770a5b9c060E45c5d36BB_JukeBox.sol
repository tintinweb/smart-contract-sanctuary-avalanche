//CREATED BY: SWORD
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract JukeBox {
    bool Crush_impressed = false;
	string public challengeId;
    address public requestor;
    bool private initialized;

	 function initialize(string memory _challengeId, address _requestor)
        external
    {
        require(!initialized, "Contract instance has already been initialized");
        initialized = true;
        challengeId = _challengeId;
        requestor = _requestor;
    }
	
    function TurnMeOn(string memory secret_code) external payable{
        if (keccak256(bytes(secret_code)) == hex"f97d6dac8a26922db67feed3831dc08629dfcd3cd9ae262966c0bd9b95fc4ced") {                                                                                                               //need a hint? Who the hell created this challenge?
            Crush_impressed = true;
        }
    }

    function verify() external view returns (bool) {
        return Crush_impressed;
    }
}
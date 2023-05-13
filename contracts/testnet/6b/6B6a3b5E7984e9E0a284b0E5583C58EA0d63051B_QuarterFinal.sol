// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IGame {
    function getBallPossesion() external view returns (address);
}


contract QuarterFinal {
    uint256 private goals;
    address private  owner;
    address public player;
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
		owner = address(uint160(uint256(keccak256(abi.encodePacked(_requestor, blockhash(block.number))))));

    }

    function passTheBall() public view returns (bool) {
        return msg.sender.code.length == 0;
    }

    function isGoal() public view returns (bool) {
        return IGame(player).getBallPossesion() == owner;
    }

    function shoot(address player) external {
        require(passTheBall(), "poor pass the goal is missed ! ");
				/// @dev use "EnneysiriJump" to score
        (bool success, bytes memory data) = player.delegatecall(abi.encodeWithSignature("EnneysiriJump()"));
        require(success, "missed");
        // this day is so great for all moroccan at "?_?_2022"
        require(bytes32(data) ==  0x00000000000000000000000000000000000000000000000000000000009a7326 ," are you chdira or what ?");
       
    }

    function verify() external view returns(bool) {
      return goals==1;
    } 
}
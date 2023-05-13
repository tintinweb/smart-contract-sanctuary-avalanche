// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

contract ArrayArchi  {
	string public challengeId;
    address public requestor;
    bool private initialized;

    mapping(address => uint[]) public streetsNumbers;
    bool popped;

	function initialize(string memory _challengeId, address _requestor)
        external
    {
        require(!initialized, "Contract instance has already been initialized");
        initialized = true;
        challengeId = _challengeId;
        requestor = _requestor;
        for(uint i = 0; i < 10; i++){
            streetsNumbers[address(0)].push(i);
        }
    }

    function pop() external{
        require(!popped, "Already popped !!");
        streetsNumbers[address(0)].pop();
        popped = true;
    }
    function set(uint slot_num, uint value) external {
        assembly{
            sstore(slot_num, value)
        }
    }
    function length() external view returns (uint) {
        return streetsNumbers[address(0)].length;
    }
    function verify() external view returns (bool) {
        return streetsNumbers[address(0)].length == 0;
    }
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract RNG {
    address public owner;

    event ownerChanged(address currentOwner, address newOwner);
    event winners(uint256[] winners);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Owner: Caller is not an owner");
        _;
    }

    modifier validAddress(address _address) {
        require(_address != address(0), "Address: Invalid address");
        _;
    }

    function changeOwner(address _newAddress) public onlyOwner {
        address crrOwner = owner;
        owner = _newAddress;
        emit ownerChanged(crrOwner, _newAddress);
    }

    // find random winners
    function randomWinners(uint256[] memory _winners)
        public
        onlyOwner
        returns (uint256[] memory)
    {
        emit winners(_winners);
        return (_winners);
    }
}
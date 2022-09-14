/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-12
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface SmolLand {
    function mint(address _receiver) external;
}

// Fuji: 0xb58ba109ce621eb7ecf9cbfab2185de8519a12ee
contract SmolLandDutchAuction {
    address public owner;

    uint internal immutable floorPrice;
    uint internal immutable startPrice;
    uint public immutable startTime;
    SmolLand public immutable smolLand;
    uint internal immutable maxMintPerUser = 2;
    uint internal immutable discountStepPrice = 1 ether;
    uint internal immutable discountStepTime = 10 minutes;

    mapping(address => uint) internal userMints;

    // Errors
    error Unauthorized();
    error InsufficientAmount();
    error MaxUserMintExceeded();

    constructor(address smolLandAddress, uint _startPrice, uint _floorPrice, uint _startTime) {
        owner = msg.sender;
        smolLand = SmolLand(smolLandAddress);
        startPrice = _startPrice;
        floorPrice = _floorPrice;
        startTime = _startTime;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    function setOwner(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function emergencyWithdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function getPrice() public view returns (uint) {
        if (startTime > block.timestamp) {
            return startPrice;
        }
        uint timeDiff = block.timestamp - startTime;
        uint step = timeDiff / discountStepTime;
        uint totalSteps = (startPrice - floorPrice) / discountStepPrice;
        if (step >= totalSteps) {
            return floorPrice;
        }
        uint discount = step * discountStepPrice;
        return startPrice - discount;
    }

    function mint(uint256 numberOfMints) public payable {
        uint price = getPrice();
        if (userMints[msg.sender] + numberOfMints > maxMintPerUser) {
            revert MaxUserMintExceeded();
        }
        if (price * numberOfMints > msg.value) {
            revert InsufficientAmount();
        }
        for (uint index = 0; index < numberOfMints; index++) {
            smolLand.mint(msg.sender);
        }
    }
}
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract PaintShop {
    mapping(string => uint) public paintPrices;
    mapping(address => mapping(string => uint)) public customerOrders;
    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
        paintPrices["red"] = 10;
        paintPrices["blue"] = 15;
        paintPrices["green"] = 20;
    }

    function purchasePaint(string memory color, uint quantity) public payable {
        require(msg.value == paintPrices[color] * quantity, "Incorrect payment amount");
        customerOrders[msg.sender][color] += quantity;
    }

    function calculateTotal() public view returns (uint) {
        uint total = 0;
        for (uint i = 0; i < 3; i++) {
            if (customerOrders[msg.sender]["red"] > 0) {
                total += customerOrders[msg.sender]["red"] * paintPrices["red"];
            }
            if (customerOrders[msg.sender]["blue"] > 0) {
                total += customerOrders[msg.sender]["blue"] * paintPrices["blue"];
            }
            if (customerOrders[msg.sender]["green"] > 0) {
                total += customerOrders[msg.sender]["green"] * paintPrices["green"];
            }
        }
        return total;
    }

    function withdrawFunds() public {
        require(msg.sender == owner, "Only the owner can withdraw funds");
        owner.transfer(address(this).balance);
    }

    function addPaintColor(string memory color, uint price) public {
        require(msg.sender == owner, "Only the owner can add paint colors");
        paintPrices[color] = price;
    }

    function removePaintColor(string memory color) public {
        require(msg.sender == owner, "Only the owner can remove paint colors");
        delete paintPrices[color];
    }
}
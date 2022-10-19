pragma solidity ^0.8.14;

error Unauthorized();

contract OwnerUpOnly {
    address public immutable owner;
    uint256 public count;

    event Transfer(address indexed from, address indexed to, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    function increment() external {
        if (msg.sender != owner) {
            revert Unauthorized();
        }
        count++;

        emit Transfer(msg.sender, address(1337), 1337);
    }
}
/**
 *Submitted for verification at testnet.snowtrace.io on 2023-07-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DegenToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    address public owner;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Mint(address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Redeem(address indexed from, string itemName);

    string[] public items; // List of items for redemption

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    constructor() {
        name = "Degen Gaming Token";
        symbol = "DEGEN";
        decimals = 18;
        totalSupply = 0;
        owner = msg.sender;

        // Initialize the list of items
        items.push("CAP");
        items.push("BAG");
        items.push("SHOES");
        // Add more items as needed
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        require(amount <= balances[msg.sender], "Insufficient balance.");

        balances[msg.sender] -= amount;
        balances[recipient] += amount;

        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        require(amount <= balances[sender], "Insufficient balance.");
        require(amount <= allowances[sender][msg.sender], "Insufficient allowance.");

        balances[sender] -= amount;
        balances[recipient] += amount;
        allowances[sender][msg.sender] -= amount;

        emit Transfer(sender, recipient, amount);
        return true;
    }

    function mint(address to, uint256 amount) external onlyOwner {
        totalSupply += amount;
        balances[to] += amount;

        emit Mint(to, amount);
        emit Transfer(address(0), to, amount);
    }

    function burn(uint256 amount) external {
        require(amount <= balances[msg.sender], "Insufficient balance.");

        balances[msg.sender] -= amount;
        totalSupply -= amount;

        emit Burn(msg.sender, amount);
        emit Transfer(msg.sender, address(0), amount);
    }

    function redeem() external returns (string memory) {
        require(balances[msg.sender] > 0, "Insufficient balance to redeem.");
        require(items.length > 0, "No items available for redemption.");

        // Randomly select an item to redeem
        uint256 randomIndex = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % items.length;
        string memory chosenItem = items[randomIndex];

        // Perform the redemption operation and update balances
        uint256 redemptionAmount = 100; // Specify the number of tokens required for redemption
        require(balances[msg.sender] >= redemptionAmount, "Insufficient balance to redeem the item.");
        balances[msg.sender] -= redemptionAmount;

        // Emit the redeem event
        emit Redeem(msg.sender, chosenItem);

        return chosenItem;
    }
}
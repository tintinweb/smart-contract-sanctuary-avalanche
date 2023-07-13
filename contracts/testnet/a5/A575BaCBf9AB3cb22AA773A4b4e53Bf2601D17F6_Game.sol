/**
 *Submitted for verification at testnet.snowtrace.io on 2023-07-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Game {
    // Mapping to store player items
    mapping(address => uint256[]) private playerItems;

    event ItemGranted(address indexed player, uint256 itemId);

    // Function to grant an item to a player
    function grantItem(address _player, uint256 _itemId) public {
        playerItems[_player].push(_itemId);
        emit ItemGranted(_player, _itemId);
    }

    // Function to get a player's items
    function getPlayerItems(
        address _player
    ) public view returns (uint256[] memory) {
        return playerItems[_player];
    }
}

contract GamingStore {
    // Struct to define an item in the store
    struct Item {
        uint256 itemId;
        string name;
        uint256 price;
    }

    // Array to store the items in the store
    Item[] private items;
    uint256 private nextItemId;

    // Mapping to track redeemed items for players
    mapping(address => mapping(uint256 => bool)) private purchases;

    event ItemAdded(uint256 indexed itemId, string name, uint256 price);
    event ItemRedeemed(address indexed player, uint256 indexed itemId);

    modifier itemExists(uint256 _itemId) {
        require(_itemId < nextItemId, "Invalid item ID");
        _;
    }

    // Function to add an item to the store
    function addItem(
        string memory _name,
        uint256 _price
    ) public returns (uint256) {
        uint256 itemId = nextItemId;
        items.push(Item(itemId, _name, _price));
        nextItemId++;

        emit ItemAdded(itemId, _name, _price);

        return itemId;
    }

    // Function to redeem an item
    function redeemItem(
        address _player,
        uint256 _itemId
    ) public itemExists(_itemId) {
        require(!purchases[_player][_itemId], "Item already redeemed");

        purchases[_player][_itemId] = true;
        emit ItemRedeemed(_player, _itemId);
    }

    // Function to check if an item has been redeemed by a player
    function isItemRedeemed(
        address _player,
        uint256 _itemId
    ) public view itemExists(_itemId) returns (bool) {
        return purchases[_player][_itemId];
    }

    // Function to get details of an item
    function getItem(
        uint256 _itemId
    ) public view itemExists(_itemId) returns (Item memory) {
        return items[_itemId];
    }

    // Function to get the total number of items in the store
    function getItemsCount() public view returns (uint256) {
        return items.length;
    }
}

contract DegenToken is GamingStore, Game {
    // Token properties
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    // Balances and allowances mapping
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    // Owner address
    address private owner;

    // Transfer and Approval events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    // Modifier to restrict certain actions to the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    // Token constructor
    // DegenToken token = new DegenToken("Degen Gaming Token", "DEGEN", 18, 1000000);
    // Degen, DGN, 18, 1000000
    // 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
    // 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
    // 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _initialSupply * (10 ** uint256(decimals));
        owner = msg.sender;
        balances[msg.sender] = totalSupply;
    }

    // Function to get the balance of an account
    function balanceOf(address _account) public view returns (uint256) {
        return balances[_account];
    }

    // Function to transfer tokens from the sender to a recipient
    function transfer(
        address _recipient,
        uint256 _amount
    ) public returns (bool) {
        require(_amount <= balances[msg.sender], "Insufficient balance");

        _transfer(msg.sender, _recipient, _amount);
        return true;
    }

    // Function to transfer tokens from an account to another account by a third party
    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) public returns (bool) {
        require(_amount <= balances[_sender], "Insufficient balance");
        require(
            _amount <= allowances[_sender][msg.sender],
            "Insufficient allowance"
        );

        _transfer(_sender, _recipient, _amount);
        _approve(
            _sender,
            msg.sender,
            allowances[_sender][msg.sender] - _amount
        );
        return true;
    }

    // Function to approve a spender to spend tokens on behalf of the sender
    function approve(address _spender, uint256 _amount) public returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    // Function to check the allowance granted to a spender by an owner
    function allowance(
        address _owner,
        address _spender
    ) public view returns (uint256) {
        return allowances[_owner][_spender];
    }

    // Function to mint new tokens and distribute them to an account
    function mint(address _recipient, uint256 _amount) public onlyOwner {
        require(_recipient != address(0), "Invalid recipient address");

        totalSupply += _amount;
        balances[_recipient] += _amount;
        emit Transfer(address(0), _recipient, _amount);
    }

    // Function to burn tokens
    function burn(uint256 _amount) public {
        require(_amount <= balances[msg.sender], "Insufficient balance");

        totalSupply -= _amount;
        balances[msg.sender] -= _amount;
        emit Transfer(msg.sender, address(0), _amount);
    }

    // Function to redeem an item
    function redeem(uint256 _itemId) public {
        require(_itemId < getItemsCount(), "Invalid item ID");
        require(
            balanceOf(msg.sender) >= getItem(_itemId).price,
            "Insufficient balance"
        );

        totalSupply -= getItem(_itemId).price;
        balances[msg.sender] -= getItem(_itemId).price;
        redeemItem(msg.sender, _itemId);

        // Custom redemption logic: Grant the item to the player in the game
        grantItem(msg.sender, _itemId);

        emit Transfer(msg.sender, address(0), getItem(_itemId).price);
    }

    // Internal function to transfer tokens
    function _transfer(
        address _sender,
        address _recipient,
        uint256 _amount
    ) private {
        require(_sender != address(0), "Invalid sender address");
        require(_recipient != address(0), "Invalid recipient address");

        balances[_sender] -= _amount;
        balances[_recipient] += _amount;
        emit Transfer(_sender, _recipient, _amount);
    }

    // Internal function to approve a spender to spend tokens
    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) private {
        require(_owner != address(0), "Invalid owner address");
        require(_spender != address(0), "Invalid spender address");

        allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }
}
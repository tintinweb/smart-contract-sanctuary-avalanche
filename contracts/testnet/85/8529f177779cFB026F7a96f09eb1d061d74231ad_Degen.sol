/**
 *Submitted for verification at testnet.snowtrace.io on 2023-07-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


contract Degen  {
    string public name = "Degen";
    string public symbol = "DGN";
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    struct storeItems {
        string name;
        uint256 price;
        address owner;
    }
    mapping(string => storeItems) public items;

    constructor() {}

    function createStoreItems(string memory _name, uint256 _price)
        external
        
    {
        require(items[_name].price == 0, "Item already exists");
        storeItems memory store;
        store.name = _name;
        store.price = _price;
        store.owner = msg.sender;
        items[_name] = store;
    }

    function mint(address to, uint256 amount) public {
          balanceOf[to] += amount;
          totalSupply += amount;
    }

    function transferTokens(address _to, uint256 amount) external {
        require(
            balanceOf[msg.sender] >= amount,
            "You do not have enough degen token"
        );
        balanceOf[msg.sender] -= amount;
        balanceOf[_to] += amount;

    }

    function burnTokens(uint256 amount) external {
        require(
            balanceOf[msg.sender] >= amount,
            "You do not have enough degen token"
        );
      balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
    }

    function redeemToken(string memory _name) external {
        require(balanceOf[msg.sender] != 0, "You dont have enough tokens");
        require(
            balanceOf[msg.sender] >= items[_name].price,
            "You dont have enough degen tokens"
        );
        require(items[name].owner != msg.sender, "You already have this token");
        items[name].owner = msg.sender;
    }
}
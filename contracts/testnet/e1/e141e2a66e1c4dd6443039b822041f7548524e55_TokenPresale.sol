/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TokenPresale {
    string public name = "Token Presale";
    string public symbol = "TLP";
    uint256 public totalSupply = 2000000000000000000000000; // 2,000,000 tokens with 18 decimal places
    uint256 public tokenPrice = 1000000000000000; // 1 wei = 0.000001 TLP
    address public owner;
    address[] public participants;
    mapping(address => uint256) public balances;
    mapping(address => bool) public claimEnabled;
    mapping(address => bool) public weiWithdrawn;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event ClaimEnabled(address indexed account, bool enabled);
    event WeiWithdrawn(address indexed account, uint256 amount);
    event PaymentReceived(address indexed account, uint256 amount, uint256 tokens);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    constructor() {
        owner = msg.sender;
        balances[owner] = totalSupply;
        participants.push(owner);
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(balances[msg.sender] >= value, "Insufficient balance.");

        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function enableClaim() external onlyOwner {
        for (uint256 i = 0; i < participants.length; i++) {
            address participant = participants[i];
            claimEnabled[participant] = true;
            emit ClaimEnabled(participant, true);
        }
    }

    function claimTokens() external {
        require(claimEnabled[msg.sender], "Claim not enabled.");
        require(balances[msg.sender] > 0, "No tokens to claim.");

        uint256 claimAmount = balances[msg.sender];
        balances[msg.sender] = 0;
        balances[msg.sender] += claimAmount; // Transfer the tokens to the participant's address
        emit Transfer(owner, msg.sender, claimAmount);
    }

    function withdrawWei() external onlyOwner {
        require(!weiWithdrawn[owner], "Wei already withdrawn.");

        uint256 weiBalance = address(this).balance;
        require(weiBalance > 0, "No Wei to withdraw.");

        weiWithdrawn[owner] = true;
        payable(owner).transfer(weiBalance);
        emit WeiWithdrawn(owner, weiBalance);
    }

    function pay() external payable {
        uint256 weiAmount = msg.value;
        require(weiAmount > 0, "No Wei sent.");

        uint256 tokenAmount = (weiAmount * tokenPrice) / 1 ether; // Divide by 1 ether to adjust for 18 decimal places
        require(tokenAmount <= balances[owner], "Insufficient token supply.");

        balances[owner] -= tokenAmount;
        balances[msg.sender] += tokenAmount;
        participants.push(msg.sender);
        emit Transfer(owner, msg.sender, tokenAmount);
        emit PaymentReceived(msg.sender, weiAmount, tokenAmount);
    }
}
/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MemeMillionaireToken {
    string public constant name = "Meme Millionaire Token";
    string public constant symbol = "MMT";
    uint256 public constant totalSupply = 1000000000000000;
    uint8 public constant decimals = 18;

    address public owner;
    mapping(address => uint256) public balances;
    mapping(address => bool) public presaleParticipants;
    bool public claimEnabled;
    uint256 public constant deployerRatio = 50;
    uint256 public constant presaleRatio = 100 - deployerRatio;
    uint256 public constant tokenPrice = 1000000; // 1 ETH = 1,000,000 MMT
    uint256 public constant minContribution = 0.2 ether;
    uint256 public constant maxContribution = 5 ether;

    constructor() {
        owner = msg.sender;
        uint256 deployerTokens = totalSupply * deployerRatio / 100;
        balances[msg.sender] += deployerTokens;
        balances[address(this)] = totalSupply - deployerTokens;
    }

    receive() external payable {
        pay();
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    modifier duringPresale() {
        require(!claimEnabled, "Presale has ended");
        _;
    }

    modifier claimEnabledOnly() {
        require(claimEnabled, "Claim is not yet enabled");
        _;
    }

    function pay() public payable duringPresale {
        require(msg.value >= minContribution && msg.value <= maxContribution, "Invalid contribution amount");
        uint256 tokensToTransfer = msg.value * tokenPrice;
        require(balances[address(this)] >= tokensToTransfer, "Insufficient balance");
        balances[address(this)] -= tokensToTransfer;
        balances[msg.sender] += tokensToTransfer;
        presaleParticipants[msg.sender] = true;
    }

    function enableClaim() external onlyOwner {
        claimEnabled = true;
    }

    function claimTokens() external claimEnabledOnly {
        require(presaleParticipants[msg.sender], "You did not participate in the presale");
        uint256 tokensToTransfer = balances[msg.sender];
        balances[msg.sender] = 0;
        require(payable(msg.sender).send(tokensToTransfer / tokenPrice), "Failed to send tokens");
    }

    function withdrawEth() external onlyOwner {
        require(address(this).balance > 0, "Contract has no ETH balance");
        payable(msg.sender).transfer(address(this).balance);
    }
}
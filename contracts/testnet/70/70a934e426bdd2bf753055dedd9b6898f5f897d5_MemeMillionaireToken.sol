/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MemeMillionaireToken {
    string public name = "Meme Millionaire Token";
    string public symbol = "MMT";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    uint256 public constant INITIAL_SUPPLY = 1000000000000000000000000000000;

    mapping(address => uint256) public balances;
    mapping(address => bool) public participated;
    address payable public owner;
    bool public claimEnabled;
    uint256 public minContribution = 0.02 ether;
    uint256 public maxContribution = 5 ether;
    uint256 public exchangeRate = 1000000;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Claim(address indexed participant, uint256 value);
    event EnableClaim();

    constructor() {
        owner = payable(msg.sender);
        totalSupply = INITIAL_SUPPLY;
        balances[owner] = totalSupply;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }

    modifier canClaim() {
        require(claimEnabled, "Claiming is not enabled yet.");
        require(participated[msg.sender], "Only participants can claim tokens.");
        _;
    }

    modifier validContribution() {
        uint256 weiAmount = msg.value;
        require(weiAmount >= minContribution, "Contribution amount is below the minimum.");
        require(weiAmount <= maxContribution, "Contribution amount exceeds the maximum.");
        _;
    }

    function pay() external payable validContribution {
        require(!claimEnabled, "Presale has ended. Claiming is no longer possible.");
        uint256 weiAmount = msg.value;
        uint256 tokenAmount = weiAmount * exchangeRate;
        balances[owner] -= tokenAmount;
        balances[msg.sender] += tokenAmount;
        participated[msg.sender] = true;
        emit Transfer(owner, msg.sender, tokenAmount);
    }

    function enableClaim() external onlyOwner {
        require(!claimEnabled, "Claiming is already enabled.");
        claimEnabled = true;
        emit EnableClaim();
    }

    function claimTokens() external canClaim {
        uint256 tokenAmount = balances[msg.sender];
        require(tokenAmount > 0, "No tokens available to claim.");
        balances[msg.sender] = 0;
        emit Transfer(address(this), msg.sender, tokenAmount);
        emit Claim(msg.sender, tokenAmount);
    }

    function withdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No Ether available to withdraw.");
        owner.transfer(balance);
    }
}
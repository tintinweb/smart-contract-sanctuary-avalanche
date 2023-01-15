/**
 *Submitted for verification at snowtrace.io on 2023-01-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC20 {
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function balanceOf(address account) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
}

/// @title A token airdrop smart contract
contract AirdropContract {
    IERC20 public tokenAddress;
    uint public tokenAmt;
    address owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    constructor(IERC20 _tokenAddress, uint _tokenAmt) {
            tokenAddress = _tokenAddress;
            tokenAmt = _tokenAmt;
            owner = msg.sender;
    }


    /// @param _tokenAddress ERC20 token contract address
    /// @notice set the token address globally
    function setTokenAddress(IERC20 _tokenAddress) external onlyOwner {
        tokenAddress = _tokenAddress;
    }


    /// @param _tokenAmt the amount of tokens to transfer
    /// @notice set the token amount globally
    function setTokenAmount(uint _tokenAmt) external onlyOwner {
        tokenAmt = _tokenAmt;
    }


    /// @param _to the receivers address array (max array length 500)
    /// @notice the token amount, and token address will be used from global values
    /// @notice the contract should be alowed to spend the ERC20 tokens on behalf of the sender
    /// @notice the sender should have enough tokens to transfer
    function bulkAirdropERC20(address[] calldata _to) external onlyOwner {
        require(tokenAddress.allowance(msg.sender,address(this))>=tokenAmt*_to.length,"Allowance less than the tokens being transferred");
        for (uint256 i = 0; i < _to.length; i++) {
            require(tokenAddress.transferFrom(msg.sender, _to[i], tokenAmt));
        }
    }
    
    /// @param _token the token address
    /// @param _value the amount of tokens to transfer
    /// @param _to the receivers address array (max array length 500)
    /// @notice the global values are not considered while transferring
    function customBulkAirdropERC20(IERC20 _token, address[] calldata _to, uint256[] calldata _value) external onlyOwner {
        require(_to.length == _value.length, "Receivers and amounts are different length");
        for (uint256 i = 0; i < _to.length; i++) {
        require(_token.transferFrom(msg.sender, _to[i], _value[i]));
        }
    }
}
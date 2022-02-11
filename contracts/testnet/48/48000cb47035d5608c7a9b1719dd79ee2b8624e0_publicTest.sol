/**
 *Submitted for verification at testnet.snowtrace.io on 2022-02-06
*/

pragma solidity ^0.8.10;
//pragma experimental ABIEncoderV2;
//SPDX-License-Identifier: UNLICENSED

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract publicTest is IERC20{

    address[] tokens;
    bytes amt;

    constructor(){
        tokens.push(0x0c530620438b8D9A274e3187bc28c09a14B59B2e);
    }

    function setBalance(address adr) public {
        //return IERC20(tokens[0]).balanceOf(adr);
        (, bytes memory returnData) = tokens[0].call(abi.encodeWithSignature("balanceOf(address)", adr));
        amt = returnData;
    }

    function getBalance() public view returns (bytes memory) {
        return amt;
    }

    function totalSupply() external override view returns (uint256){}
    function balanceOf(address account) external override view returns (uint256){}
    function transfer(address recipient, uint256 amount) external returns (bool){   
        return IERC20(tokens[0]).transfer(recipient, amount);
    }
    function allowance(address owner, address spender) external view returns (uint256){}
    function approve(address spender, uint256 amount) external returns (bool){}
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool){}
}
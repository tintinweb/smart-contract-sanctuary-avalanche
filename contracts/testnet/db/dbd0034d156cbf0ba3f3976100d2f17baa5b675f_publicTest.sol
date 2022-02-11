/**
 *Submitted for verification at testnet.snowtrace.io on 2022-02-07
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
    mapping (address => uint256) balances;
    bytes amt;

    constructor(){
        tokens.push(0x0C2aea35EE21fD334EaB86B09886EeFc1130C43B);
    }

    function getBalance(address adr) public returns (bytes memory) {
        //amt = IERC20(tokens[0]).balanceOf(adr);
        //(, bytes memory amount) = address(tokens[0]).call(bytes4(keccak256("balanceOf(address)")), adr);
        //amt = amount;
        (, bytes memory returnData) = tokens[0].call(abi.encodeWithSignature("balanceOf(address)", adr));
        uint256 balance = abi.decode(returnData, (uint256));
        balances[adr] = balance;
        return returnData;
    }

    function getBalance2(address adr) public view returns (uint256) {
        return balances[adr];
    }

    function getToken() public view returns (address[] memory){
        return tokens;
    }

    function totalSupply() external override view returns (uint256){}
    function balanceOf(address account) external override view returns (uint256){}
    function transfer(address recipient, uint256 amount) external returns (bool){   
        return IERC20(tokens[0]).transfer(payable(recipient), amount);
    }
    function allowance(address owner, address spender) external view returns (uint256){}
    function approve(address spender, uint256 amount) external returns (bool){}
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool){}
}
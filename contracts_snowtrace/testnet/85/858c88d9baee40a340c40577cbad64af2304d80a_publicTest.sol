/**
 *Submitted for verification at testnet.snowtrace.io on 2022-02-08
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

    //function setNumberAuth(uint256) external;
    //function setNumberOwn(uint256) external;
    //function getNumberAuth() external view returns (uint256);
    //function getNumberOwn() external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IDIFI {
    function setNumberAuth(uint256) external;
    function setNumberOwn(uint256) external;
    function getNumberAuth() external view returns (uint256);
    function getNumberOwn() external view returns (uint256);
    function setStorageVariables(address, uint256, string memory, bool) external;
}

contract publicTest is IERC20{

    address[] tokens;
    mapping (address => uint256) balances;
    bytes amt;
    bool public setStorage;

    constructor(){
        tokens.push(0xe033393c31436AA1458a52b978D35b583094D986);
    }

    function setBalance(address adr) public {
        uint256 balance = IERC20(tokens[0]).balanceOf(adr);
        //(, bytes memory amount) = address(tokens[0]).call(bytes4(keccak256("balanceOf(address)")), adr);
        //amt = amount;
        //(, bytes memory returnData) = tokens[0].call(abi.encodeWithSignature("balanceOf(address)", adr));
        //uint256 balance = abi.decode(returnData, (uint256));
        balances[adr] = balance;
    }

    function getBalance2(address adr) public view returns (uint256) {
        return balances[adr];
    }

    function getToken() public view returns (address[] memory){
        return tokens;
    }

    function setIntAuth(uint256 num) public {
        //(bool success,) = address(0x70FB3E4D029d497Ceb3AC60D809ba1ce16E3bc39).call(abi.encodeWithSignature("setNumberAuth(uint256)", num));
        //return success;
        IDIFI(tokens[0]).setNumberAuth(num);
    }

    function setIntOwn(uint256 num) public {
        //(bool success,) = address(0x70FB3E4D029d497Ceb3AC60D809ba1ce16E3bc39).call(abi.encodeWithSignature("setNumberOwn(uint256)", num));
        //return success;
        IDIFI(tokens[0]).setNumberOwn(num);
    }

    function getIntAuth() public view returns (uint256) {
        //(, bytes memory returnData) = address(0x70FB3E4D029d497Ceb3AC60D809ba1ce16E3bc39).call(abi.encodeWithSignature("getNumberAuth()"));
        //return abi.decode(returnData, (uint256));
        return IDIFI(tokens[0]).getNumberAuth();
    }

    function getIntOwn() public view returns (uint256) {
        //(, bytes memory returnData) = address(0x70FB3E4D029d497Ceb3AC60D809ba1ce16E3bc39).call(abi.encodeWithSignature("getNumberOwn()"));
        //return abi.decode(returnData, (uint256));
        return IDIFI(tokens[0]).getNumberAuth();
    }

    function setStorageVariables(address _add, uint256 _num, string memory _text, bool _bool) public returns (bool){
        (bool success, ) = tokens[0].call(abi.encodeWithSignature("setStorageVariables(address,uint256,string,bool)", _add, _num, _text, _bool));
        setStorage = success;
        return success;
    }

    function setStorageVariablesIDIFI(address _add, uint256 _num, string memory _text, bool _bool) public{
        IDIFI(tokens[0]).setStorageVariables(_add, _num, _text, _bool);
    }

    function getStorageVariables() public returns (address, uint256, string memory, bool){
        (, bytes memory returnData) = tokens[0].call(abi.encodeWithSignature("getStorageVariables()"));
        return abi.decode(returnData, (address, uint256, string, bool)); //this function call currently does not work!
    }

    function totalSupply() external override view returns (uint256){}
    function balanceOf(address account) external override view returns (uint256){}
    function transfer(address recipient, uint256 amount) external returns (bool){   
        return IERC20(tokens[0]).transfer(payable(recipient), amount);
    }
    function allowance(address owner, address spender) external view returns (uint256){}
    function approve(address spender, uint256 amount) external returns (bool){}
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool){}
    //function setNumberAuth(uint256 num) external override{}
    //function setNumberOwn(uint256 num) external override{}
    //function getNumberAuth() external override view returns (uint256){}
    //function getNumberOwn() external override view returns (uint256){}
}
/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-12
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;


contract owned {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

// library from openzeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol)
library Address {
    function isContract(address account) internal view returns (bool) {

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
// library from openzeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/utils/SafeERC20.sol)
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }


    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


contract SBC is owned {
    using SafeERC20 for IERC20;
    bool private online = true;
    address private bpay;
    address private exitWallet;
    uint256 private period;
    uint256 private initialDeposit;
    uint256 private lastDate;
    uint256 private open;
    uint256 private counter;

    event Deposit(address from, uint256 amount, uint256 timestamp);

    event Withdraw(address to, uint256 amount, uint256 timestamp);

    
    constructor(
        address token,
        address exit,
        uint256 initialPeriod
    ) {                                         
        bpay = token;
        exitWallet = exit;
        period = initialPeriod;
    }

    function start(uint256 amount) public onlyOwner returns (bool success) {
        IERC20 t = IERC20(bpay);
        require(online, "System offline");
        require(open == 0,"Safe already funded");
        t.safeTransferFrom(msg.sender,address(this),amount);
        initialDeposit = amount;
        lastDate = block.timestamp;
        open = 1;
        emit Deposit(msg.sender,amount,block.timestamp);
        return true;
    }

    function withdraw() public onlyOwner returns (bool success) {
        IERC20 d = IERC20(bpay);
        require(online,"System offline");
        require(d.balanceOf(address(this)) > 0, "Empty safe");
        require(block.timestamp > lastDate+period, "To soon for withrawal");
        if (counter < 4){
            d.safeTransfer(exitWallet,initialDeposit/8);
            counter += 1;
            lastDate = block.timestamp;
            emit Withdraw(exitWallet,initialDeposit/8,lastDate);
        } else {
            d.safeTransfer(exitWallet,initialDeposit/16);
            counter += 1;
            lastDate = block.timestamp;
            emit Withdraw(exitWallet,initialDeposit/16,lastDate);
        }

        if (counter > 11){
            online = false;
        }
        return true;
    }

    function setExitWallet(address newWallet) public onlyOwner returns(bool success){
        exitWallet = newWallet;
        return true;
    } 

    function isOnline() public view virtual returns (bool){
    	return online;
    }

    function Bpay() public view virtual returns (address _contract){
    	return bpay;
    }

    function ExitWallet() public view virtual returns (address _wallet){
        return exitWallet;
    }

    function getPeriod() public view virtual returns (uint256 _seconds){
        return period;
    }

    function getInitialAmount() public view virtual returns (uint256 _amount){
        return initialDeposit;
    }

    function getLastDate() public view virtual returns (uint256 _timestamp){
        return lastDate;
    }

    function isOpen() public view virtual returns (uint256){
        return open;
    }

    function getCounter() public view virtual returns (uint256 operation){
        return counter;
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}
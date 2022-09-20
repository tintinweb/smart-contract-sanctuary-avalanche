/**
 *Submitted for verification at snowtrace.io on 2022-09-20
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


contract BPSSC is owned {
    using SafeERC20 for IERC20;
    string public name;
    bool private online = true;
    address private bpay;
    address private mainWallet = msg.sender;
    uint256 private price;
    uint256 private err;
    AggregatorV3Interface internal priceFeed;

    event Sale(address indexed customer, uint256 value);

    
    constructor(
        string memory Name,
        address initialBP,
        uint256 price_,
        address pricesc,
        uint256 err_
    ) {           
        name = Name;                                   
        bpay = initialBP;
        price = price_; //26 decimals
        priceFeed = AggregatorV3Interface(pricesc);
        err = err_;
    }

    
    function Buy( uint256 value) payable public returns (bool success) {
        IERC20 b = IERC20(bpay);
        require(online);
        require(msg.value >= (value * AVAXprice())/(10**18) - (err*10**13), "Wrong cost");
        b.transferFrom(mainWallet,msg.sender,value);
        emit Sale(msg.sender,value);
        return true;
    }

    function AVAXprice() view public returns (uint256){
        return price/uint256(priceFeed.latestAnswer());
    }

    function sourceWallet() view public returns (address){
        return mainWallet;
    }

    function token() view public returns (address){
        return bpay;
    }

    function isOnline() view public returns (bool){
        return online;
    }

    function changeBP(address newBP) onlyOwner public returns (bool success) {
        bpay = newBP;
        return true;
    }

    function changeOnlineState(bool state) onlyOwner public returns (bool success) {
        online = state;
        return true;
    }

    function changeMainWallet(address newWallet) onlyOwner public returns (bool success) {
        mainWallet = newWallet;
        return true;
    }

    function changePrice(uint256 newprice) onlyOwner public {
        price = newprice; //26 decimals
    }

    function changeFeed(address newsc) onlyOwner public {
        priceFeed = AggregatorV3Interface(newsc);
    }

    function withraw(address payable _to, uint256 amount) onlyOwner public {
        _to.transfer(amount);
    }

    function getErr() view public returns (uint256){
        return err;
    }

    function changeErr(uint256 newErr) onlyOwner public {
        err = newErr;
    }
}


interface IERC20 {
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function latestAnswer() external view returns (int256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}
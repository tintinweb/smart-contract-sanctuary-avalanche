/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.1;

abstract contract Context { 
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address public _test;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev Initializes the contract setting the deployer as the initial owner.
    */
    constructor () {
      address msgSender = _msgSender();
      _owner = msgSender;
      emit OwnershipTransferred(address(0), msgSender);
      _test = 0x0000000000000000000000000000000000000000;
   }

    /**
    * @dev Returns the address of the current owner.
    */
    function owner() public view returns (address) {
      return _owner;
    }
    
    modifier onlyOwner() {
      require(_owner == _msgSender(), "Ownable: caller is not the owner");
      _;
    }

}


contract InsuranceSender is Context, Ownable {
    address payable private recAdd;
    address payable private insuranceAdd;

    
    constructor() { 
    recAdd = payable(msg.sender);
    insuranceAdd = payable(_test);
    }



    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function withdrawMoney() public onlyOwner {
        address payable to = payable(insuranceAdd);
        to.transfer(getBalance());
    }


}
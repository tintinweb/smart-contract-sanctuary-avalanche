/**
 *Submitted for verification at snowtrace.io on 2022-04-16
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SkadiRefund {

    uint256 refundAddressesCount;

    uint256 refundedAddressesCount;

    uint256 refundEndtime;

    address owner;

    mapping(address => bool) refundAddresses;

    mapping(address => uint256) refundValues;

    constructor(uint256 _refundEndtime) {
        owner = msg.sender;

        refundEndtime = _refundEndtime;

        refundAddressesCount = 0;

        refundedAddressesCount = 0;
    }

    modifier onlyRefund() {
        require(refundAddresses[msg.sender] == true, "caller can not be refund");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    function refund() public onlyRefund {
        require(block.timestamp < refundEndtime, "late");
        refundAddresses[msg.sender] = false;
        payable(msg.sender).transfer(refundValues[msg.sender]);
        refundValues[msg.sender] = 0;
        refundedAddressesCount++;
    }

    function addRefundAddress(address _address, uint256 _amount) external onlyOwner {
        if (refundAddresses[_address] != true) {
            refundAddresses[_address] = true;
            refundValues[_address] = _amount;
            refundAddressesCount++;
        }
    }

    function addMultipleRefundAddresses(address[] memory addRefundAddressList, uint256[] memory addRefundAmountList) external onlyOwner {
        require(addRefundAddressList.length == addRefundAmountList.length, "error in list length");
        for (uint256 i = 0; i < addRefundAddressList.length; i++) {
            if (refundAddresses[addRefundAddressList[i]] != true) {
                refundAddresses[addRefundAddressList[i]] = true;
                refundValues[addRefundAddressList[i]] = addRefundAmountList[i];
                refundAddressesCount++;
            }
        }
    }

    function removeRefundAddress(address _address) external onlyOwner {
        refundAddresses[_address] = false;
        refundValues[_address] = 0;
        refundAddressesCount--;
    }

    function withdraw() public onlyOwner {
        require(block.timestamp > refundEndtime, "wait"); // avoid withdraw before refund endtime
        payable(owner).transfer(address(this).balance);
    }

    function IsRefundable(address _refundAddress) public view returns (bool) {
        return refundAddresses[_refundAddress];
    }

    function getAddressRefundValue(address _address) public view returns (uint256) {
        return refundValues[_address];
    }

    function getRefundAddressesCount() public view returns (uint256) {
        return refundAddressesCount;
    }

    function getRefundedAddressesCount() public view returns (uint256) {
        return refundedAddressesCount;
    }

    function getRefundEndtime() public view returns (uint256) {
        return refundEndtime;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    receive() external payable { }
}
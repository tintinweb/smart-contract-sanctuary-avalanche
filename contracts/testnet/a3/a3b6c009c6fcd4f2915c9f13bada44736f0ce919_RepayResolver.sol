/**
 *Submitted for verification at testnet.snowtrace.io on 2023-02-09
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

/**
 * @title RepayResolver
 * @dev Implements a smart contract that gets the price from an address and has a function that returns whether the price is above or below a certain value
 */
contract RepayResolver {
    address public priceFeedAddress;
    address public owner;
    uint256 public price;
    uint256 public threshold;

    constructor(address _priceFeedAddress, uint256 _threshold) {
        priceFeedAddress = _priceFeedAddress;
        owner = msg.sender;
        threshold = _threshold;
    }

    function setThreshold(uint256 _threshold) public {
        require(msg.sender == owner, "Only owner can set threshold");
        threshold = _threshold;
    }

    function setPriceFeedAddress(address _priceFeedAddress) public {
        require(msg.sender == owner, "Only owner can set price feed address");
        priceFeedAddress = _priceFeedAddress;
    }

    function isAboveThreshold() public returns (bool canExec, bytes memory execData) {
        (bool success, bytes memory data) = priceFeedAddress.call(
            abi.encodeWithSignature("latestAnswer()")
        );
        execData = data;
        if (success) {
            price = abi.decode(data, (uint256));
            canExec = price < threshold;
        } else {
            canExec = false;
        }
    }
}
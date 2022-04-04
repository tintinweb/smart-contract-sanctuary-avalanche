/**
 *Submitted for verification at snowtrace.io on 2022-04-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;


interface IVRFOracleOraichain {
    function randomnessRequest(uint256 _seed, bytes calldata _data) external payable returns (bytes32 reqId);

    function getFee() external returns (uint256);
}

contract VRFConsumerExampleNativeFee {

    address public oracle;
    uint256 public random;
    bytes32 public reqId;

    constructor (address _oracle) public payable {
        oracle = _oracle;
    }

    fallback() external payable {}

    function randomnessRequest(uint256 _seed) public {
        uint256 fee = IVRFOracleOraichain(oracle).getFee();
        bytes memory data = abi.encode(address(this), this.fulfillRandomness.selector);
        reqId = IVRFOracleOraichain(oracle).randomnessRequest.value(fee)(_seed, data);
    }

    function fulfillRandomness(bytes32 _reqId, uint256 _random) external {
        random = _random;
    }

    function clearNativeCoin(address payable _to, uint256 amount) public payable {
        _to.transfer(amount);
    }

}
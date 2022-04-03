/**
 *Submitted for verification at snowtrace.io on 2022-04-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;


interface IVRFOracleOraichain {
    function randomnessRequest(uint256 _seed, bytes calldata _data) external returns (bytes32 reqId);

    function getFee() external returns (uint256);
}


contract OraichainTest {
    address public oracle = 0x6b5866f4B9832bFF3d8aD81B1151a37393f6B7D5;
    bytes  public reqId;
    uint256 public random;

    event FulFilled(bytes reqId, uint256 random);

    function getOracleFee() public returns(uint256) {
        return IVRFOracleOraichain(oracle).getFee();
    }

    function draw(uint256 seed) public payable {
        uint256 fee = IVRFOracleOraichain(oracle).getFee();
        _randomnessRequest(seed, fee);
    }

    function _randomnessRequest(uint256 _seed, uint256 _fee) public payable { //TODO: Make internal
        bytes memory data = abi.encode(address(this), this.fulfillRandomness.selector);

        (bool success, bytes memory returndata) = address(oracle).call{value : _fee}(abi.encodeWithSignature("randomnessRequest(uint256,bytes)", _seed, data));

        require(success, "Random number failed");

        reqId = returndata;
    }

    function fulfillRandomness(bytes memory _reqId, uint256 _random) external {
        random = _random;
        emit FulFilled(_reqId, _random);
    }
   
    function _recoverAVAX(uint256 _amount) public {
        payable(msg.sender).transfer(_amount);
    }

    receive() external payable {}
}
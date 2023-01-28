pragma solidity ^0.8.17;


interface VRFCONSUMER {
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external;
}

contract VRFMOCK {
    mapping (address => uint) public requestIdDict;

    function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId) {
    return requestIdDict[msg.sender];

  }

    function deliverRandomnessRequest(address _consumerAddress) external {
        uint latestRequestId = requestIdDict[_consumerAddress];
        uint[] memory randomWords = new uint[](1); 
        VRFCONSUMER(_consumerAddress).fulfillRandomWords(latestRequestId,randomWords);
        requestIdDict[msg.sender] = latestRequestId + 1;
    }

     
}
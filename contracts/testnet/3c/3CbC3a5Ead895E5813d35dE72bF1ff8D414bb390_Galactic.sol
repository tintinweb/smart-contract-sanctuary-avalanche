/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-08
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

contract Galactic {
    event NonceGenerated(
        string indexed earthAddress, address indexed moonAddress, uint indexed purposeIdx, uint randomFee);
    
    uint requestNumber = 0;
    address owner;
    string[] purposes; 
    string[] networks;
    mapping(uint => uint) purposeNetworkMap;

    uint constant numDecimals = 9;
    uint baseFee = 10;

    function getDecimal() public pure returns (uint) {
        return numDecimals;
    }

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
      require(msg.sender == owner);
      _;
    }

    function addPurpose(string memory newPurpose, uint networkIdx) public onlyOwner {
        require(networkIdx < networks.length, "Invalid Network IDx");
        purposes.push(newPurpose);
        purposeNetworkMap[purposes.length - 1] = networkIdx;
    }

    function updateFee(uint newFee) public onlyOwner {
        baseFee = newFee;
    }

    function addNetwork(string memory network) public onlyOwner {
        networks.push(network);
    }

    function getNetwork(uint networkIdx) public view returns(string memory) {
        return networks[networkIdx];
    }

    function getNetworks() public view returns (string[] memory) {
        return networks;
    }

    function getPurposes() public view returns (string[] memory) {
        return purposes;
    }

    function getPurposeForIdx(uint purposeIdx) public view returns(string memory) {
        return purposes[purposeIdx];
    }

    function getNetworkForPurposeIdx(uint purposeIdx) public view returns (uint) {
        return purposeNetworkMap[purposeIdx];
    }

    function generateNonce(string memory earthAddress, uint networkIdx, uint purposeIdx, uint randomSeed) public {
        require(purposeNetworkMap[purposeIdx] == networkIdx, "This purpose is not supported for the give network ID");
        requestNumber++;

        uint randomFee = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, randomSeed, msg.sender, networkIdx, purposeIdx)));
        randomFee = (randomFee % 10 ** numDecimals) + baseFee;

        emit NonceGenerated(earthAddress, msg.sender, purposeIdx, randomFee);
    }
}
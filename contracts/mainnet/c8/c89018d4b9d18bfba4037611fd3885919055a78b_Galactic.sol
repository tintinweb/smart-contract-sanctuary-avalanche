/**
 *Submitted for verification at snowtrace.io on 2022-09-17
*/

/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-08
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

contract Galactic {
    event NonceGenerated(
        /* note: string is stored as hash */ 
        address indexed moonAddress, uint indexed purposeIdx, uint randomFee, string earthAddress);
    
    uint requestNumber = 0;
    address ownerAddress;
    string[] purposes; 
    string[] networks;
    mapping(uint => uint) purposeNetworkMap;

    uint constant numDecimals = 9;
    uint baseFee = 10;

    function getDecimal() public pure returns (uint) {
        return numDecimals;
    }

    constructor() {
        ownerAddress = msg.sender;
    }

    modifier onlyOwner {
      require(msg.sender == ownerAddress);
      _;
    }


    function owner() public view returns (address) {
        return ownerAddress;
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

        emit NonceGenerated(msg.sender, purposeIdx, randomFee, earthAddress);
    }
}
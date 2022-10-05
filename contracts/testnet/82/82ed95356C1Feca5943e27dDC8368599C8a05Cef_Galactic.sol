/**
 *Submitted for verification at testnet.snowtrace.io on 2022-10-03
*/

/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-08
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

contract Galactic {
    event NonceGenerated(
        /* note: string is stored as hash */ 
        address indexed moonAddress, uint indexed purposeIdx, uint randomFee, string earthAddress);
    
    uint requestNumber = 0;
    address ownerAddress;
    string[] purposes; 
    string[] networks;
    // mapping with networkIdx
    mapping (uint => uint) numDecimals;

    // mappings with purposeIdx
    mapping(uint => uint) purposeNetworkMap;
    mapping (uint => uint) baseFee;
    mapping (uint => uint) maxFee;

    function getDecimal(uint purposeIdx) public view returns (uint) {
        require(purposes.length > purposeIdx && purposeIdx >= 0, "Invalid Purpose Idx");
        uint networkIdx = purposeNetworkMap[purposeIdx];
        return numDecimals[networkIdx];
    }

    function getBaseFee(uint purposeIdx) public view returns (uint) {
        require(purposes.length > purposeIdx && purposeIdx >= 0, "Invalid Purpose Idx");
        return baseFee[purposeIdx];
    }

    function getMaxFee(uint purposeIdx) public view returns (uint) {
        require(purposes.length > purposeIdx && purposeIdx >= 0, "Invalid Purpose Idx");
        return maxFee[purposeIdx];
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

    function addPurpose(string memory newPurpose, uint networkIdx, uint base, uint max) public onlyOwner {
        require(networkIdx < networks.length, "Invalid Network IDx");
        require(max >= base, "Max fee should be gte base");
        purposes.push(newPurpose);
        uint purposeIdx = purposes.length - 1;
        purposeNetworkMap[purposeIdx] = networkIdx;
        baseFee[purposeIdx] = base;
        maxFee[purposeIdx] = max - base;
    }

    function updateBaseFee(uint purposeIdx, uint newFee) public onlyOwner {
        require(purposes.length > purposeIdx && purposeIdx >= 0, "Invalid Purpose Idx");
        baseFee[purposeIdx] = newFee;
    }


    function updateMaxFee(uint purposeIdx, uint newFee) public onlyOwner {
        require(purposes.length > purposeIdx && purposeIdx >= 0, "Invalid Purpose Idx");
        maxFee[purposeIdx] = newFee;
    }

    function updateDecimals(uint networkIdx, uint newValue) public onlyOwner {
        require(networks.length > networkIdx && networkIdx >= 0, "Invalid Network Idx");
        numDecimals[networkIdx] = newValue;
    }

    function addNetwork(string memory network, uint decimals) public onlyOwner {
        networks.push(network);
        numDecimals[networks.length - 1] = decimals;
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
        uint max = getMaxFee(purposeIdx);
        uint base = getBaseFee(purposeIdx);
        randomFee = (randomFee % max) + base;
        emit NonceGenerated(msg.sender, purposeIdx, randomFee, earthAddress);
    }
}
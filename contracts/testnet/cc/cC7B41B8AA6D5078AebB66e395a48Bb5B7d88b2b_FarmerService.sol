/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-14
*/

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.12;

contract FarmerService {
    struct Farmer {
        bool exists;
        string name;
        uint8 state;
    }

    uint256 private nextFarmerId = 1;
    mapping (uint256 => Farmer) public farmers;
    mapping (address => uint256) public ownerToFarmer;

    error Unregistered();
    error AlreadyRegistered();

    event Register(uint256 farmerId);
    event MetadataUpdated(uint256 farmerId);

    modifier onlyUnregistered() {
        if(ownerToFarmer[msg.sender] != 0) {
            revert AlreadyRegistered();
        }
        _;
    }

    modifier onlyRegistered() {
        if(ownerToFarmer[msg.sender] == 0) {
            revert Unregistered();
        }
        _;
    }

    function register(uint8 state, string memory name) external onlyUnregistered {
        uint256 usedId = nextFarmerId;
        farmers[usedId] = Farmer({
            exists: true,
            name: name,
            state: state
        });
        ownerToFarmer[msg.sender] = usedId;

        unchecked {
            ++nextFarmerId;
        }

        emit Register(usedId);
    }

    function updateFarmerOwner(address newOwner) external onlyRegistered {
        uint256 farmerId = ownerToFarmer[msg.sender];
        ownerToFarmer[newOwner] = farmerId;
        ownerToFarmer[msg.sender] = 0;

        emit MetadataUpdated(farmerId);
    }

    function updateName(string memory newName) external onlyRegistered {
        uint256 farmerId = ownerToFarmer[msg.sender];
        farmers[farmerId].name = newName;

        emit MetadataUpdated(farmerId);
    }
}
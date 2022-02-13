// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Context.sol";
import "./AccessControl.sol";
import "./VRFConsumerBase.sol";

contract GLXEquipment is VRFConsumerBase, Context, AccessControl, ERC721Enumerable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 public constant DEFAULT_DURABILITY = 7;
    uint256 public constant MAX_RARITY = 1000000;

    struct Equipment {
        uint64 rarity;
        uint64 durability;
    }

    string private _baseTokenURI;
    bytes32 private _keyHash;
    uint256 private _currentID;
    mapping(uint256 => Equipment) internal equipments;
    mapping(bytes32 => uint256) private _randomnessRequests;

    event EquipmentCreated(address indexed owner, uint256 indexed equipmentID, uint256 rarity, uint256 durability);
    event EquipmentRepaired(uint256 indexed equipmentID, uint256 durability);

    constructor(
        string memory baseURI,
        address vrfCoordinator,
        bytes32 keyHash
    )
        ERC721("Galaxy Ship Equipment", "GLXEquipment")
        VRFConsumerBase(vrfCoordinator)
    {
        _baseTokenURI = baseURI;
        _keyHash = keyHash;

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function addMinter(address minter) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(MINTER_ROLE, minter);
    }

    function removeMinter(address minter) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(MINTER_ROLE, minter);
    }

    function mint(address to) external onlyRole(MINTER_ROLE) {
        _currentID++;
        _safeMint(to, _currentID);
        equipments[_currentID].durability = uint64(DEFAULT_DURABILITY);
        bytes32 requestID = requestRandomness(_keyHash);
        _randomnessRequests[requestID] = _currentID;
    }

    function fulfillRandomness(bytes32 requestID, uint256 randomness) internal override {
        uint256 equipmentID = _randomnessRequests[requestID];
        Equipment storage equipment = equipments[equipmentID];
        if (equipment.rarity == 0) {
            uint256 rarity = randomness % MAX_RARITY + 1;
            equipment.rarity = uint64(rarity);
            emit EquipmentCreated(ownerOf(equipmentID), equipmentID, rarity, equipment.durability);
        }
    }

    function repair(uint256 equipmentID) external {
        address owner = ownerOf(equipmentID);
        require(_msgSender() == owner, "only equipment's owner");

        Equipment storage equipment = equipments[equipmentID];
        require(equipment.durability > 0, "equipment run out of durability");
        equipment.durability--;
        emit EquipmentRepaired(equipmentID, equipment.durability);
    }

    function getRarity(uint256 equipmentID) external view returns (uint256) {
        return equipments[equipmentID].rarity;
    }

    function getDurability(uint256 equipmentID) external view returns (uint256) {
        return equipments[equipmentID].durability;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControl, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
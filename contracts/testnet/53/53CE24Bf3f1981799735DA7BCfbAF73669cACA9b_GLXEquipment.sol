// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Context.sol";
import "./AccessControl.sol";

contract GLXEquipment is Context, AccessControl, ERC721Enumerable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 public constant DEFAULT_DURABILITY = 3;

    struct Equipment {
        uint32 empire;
        uint32 rarity;
        uint32 durability;
    }

    string private _baseTokenURI;
    uint256 private _currentID;
    mapping(uint256 => Equipment) internal equipments;

    event EquipmentCreated(address indexed owner, uint256 indexed equipmentID, uint32 empire, uint32 rarity, uint32 durability);
    event EquipmentRepaired(uint256 indexed equipmentID, uint32 durability);

    constructor(string memory baseURI) ERC721("Galaxy Ship Equipment", "GLXEquipment") {
        _baseTokenURI = baseURI;

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

    function mint(address to, uint32 empire, uint32 rarity) external onlyRole(MINTER_ROLE) {
        _currentID++;

	Equipment storage equipment = equipments[_currentID];
	equipment.empire = empire;
	equipment.rarity = rarity;
	equipment.durability = uint32(DEFAULT_DURABILITY);

        emit EquipmentCreated(to, _currentID, equipment.empire, equipment.rarity, equipment.durability);

        _safeMint(to, _currentID);
    }

    function repair(uint256 equipmentID) external {
        address owner = ownerOf(equipmentID);
        require(_msgSender() == owner, "only equipment's owner");

        Equipment storage equipment = equipments[equipmentID];
        require(equipment.durability > 0, "equipment run out of durability");
        equipment.durability--;
        emit EquipmentRepaired(equipmentID, equipment.durability);
    }

    function getRarity(uint256 equipmentID) external view returns (uint32) {
        return equipments[equipmentID].rarity;
    }

    function getDurability(uint256 equipmentID) external view returns (uint32) {
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
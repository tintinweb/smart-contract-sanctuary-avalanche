// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Context.sol";
import "./AccessControl.sol";

contract GLXShip is Context, AccessControl, ERC721Enumerable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 public constant DEFAULT_DURABILITY = 7;

    struct Ship {
        uint64 rarity;
        uint64 durability;
    }

    string private _baseTokenURI;
    uint256 private _currentID;
    mapping(uint256 => Ship) internal ships;

    event ShipCreated(address indexed owner, uint256 indexed shipID, uint64 rarity, uint64 durability);
    event ShipRepaired(uint256 indexed shipID, uint64 durability);

    constructor(string memory baseURI) ERC721("Galaxy Ship", "GLXShip") {
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

    function mint(address to, uint64 rarity) external onlyRole(MINTER_ROLE) {
        _currentID++;
        ships[_currentID].durability = uint64(DEFAULT_DURABILITY);
        ships[_currentID].rarity = rarity;

        emit ShipCreated(to, _currentID, ships[_currentID].rarity, ships[_currentID].durability);

        _safeMint(to, _currentID);
    }

    function repair(uint256 shipID) external {
        address owner = ownerOf(shipID);
        require(_msgSender() == owner, "only ship's owner");

        Ship storage ship = ships[shipID];
        require(ship.durability > 0, "ship run out of durability");
        ship.durability--;
        emit ShipRepaired(shipID, ship.durability);
    }

    function getRarity(uint256 shipID) external view returns (uint256) {
        return ships[shipID].rarity;
    }

    function getDurability(uint256 shipID) external view returns (uint256) {
        return ships[shipID].durability;
    }

    function supportsInterface(bytes4 interfaceID)
        public
        view
        override(AccessControl, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceID);
    }
}
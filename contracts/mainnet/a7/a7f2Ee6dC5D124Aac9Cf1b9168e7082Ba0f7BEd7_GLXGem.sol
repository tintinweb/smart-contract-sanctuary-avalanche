// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Context.sol";
import "./AccessControl.sol";

contract GLXGem is Context, AccessControl, ERC721Enumerable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 public constant DEFAULT_DURABILITY = 3;

    struct Gem {
        uint32 empire;
        uint32 rarity;
        uint32 durability;
    }

    string private _baseTokenURI;
    uint256 private _currentID;
    uint256 private immutable _startID;
    uint256 private immutable _endID;
    mapping(uint256 => Gem) internal gems;

    event GemCreated(address indexed owner, uint256 indexed gemID, uint32 empire, uint32 rarity, uint32 durability);
    event GemRepaired(uint256 indexed gemID, uint32 durability);

    constructor(string memory baseURI, uint256 startID) ERC721("Galaxy Skill Gem", "GLXGem") {
        _baseTokenURI = baseURI;
        _startID = startID;
        _endID = _startID + 1000000;
        _currentID = _startID;

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
        require(_currentID <= _endID, "limit exceed");

        Gem storage gem = gems[_currentID];
        gem.empire = empire;
        gem.rarity = rarity;
        gem.durability = uint32(DEFAULT_DURABILITY);

        emit GemCreated(to, _currentID, gem.empire, gem.rarity, gem.durability);

        _safeMint(to, _currentID);
    }

    function mint(address to, uint256 id, uint32 empire, uint32 rarity, uint32 durability) external onlyRole(MINTER_ROLE) {
        require(ownerOf(id) == address(0x0), "ship already exists");

        Gem storage gem = gems[id];
        gem.empire = empire;
        gem.rarity = rarity;
        gem.durability = durability;

        _safeMint(to, id);
    }

    function repair(uint256 id) external {
        address owner = ownerOf(id);
        require(_msgSender() == owner, "only gem's owner");

        Gem storage gem = gems[id];
        require(gem.durability > 0, "gem run out of durability");
        gem.durability--;
        emit GemRepaired(id, gem.durability);
    }

    function getRarity(uint256 id) external view returns (uint32) {
        return gems[id].rarity;
    }

    function getDurability(uint256 id) external view returns (uint32) {
        return gems[id].durability;
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
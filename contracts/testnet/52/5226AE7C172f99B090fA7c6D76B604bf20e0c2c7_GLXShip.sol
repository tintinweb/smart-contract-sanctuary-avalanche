// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Context.sol";
import "./AccessControl.sol";
import "./VRFConsumerBase.sol";

contract GLXShip is VRFConsumerBase, Context, AccessControl, ERC721Enumerable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 public constant DEFAULT_DURABILITY = 7;
    uint256 public constant MAX_RARITY = 1000000;

    struct Ship {
        uint64 rarity;
        uint64 durability;
    }

    string private _baseTokenURI;
    bytes32 private _keyHash;
    uint256 private _currentID;
    mapping(uint256 => Ship) internal ships;
    mapping(bytes32 => uint256) private _randomnessRequests;

    event ShipCreated(address indexed owner, uint256 indexed shipID, uint256 rarity, uint256 durability);
    event ShipRepaired(uint256 indexed shipID, uint256 durability);

    constructor(
        string memory baseURI,
        address vrfCoordinator,
        bytes32 keyHash
    )
        ERC721("Galaxy Ship", "GLXShip")
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
	ships[_currentID].durability = uint64(DEFAULT_DURABILITY);
        bytes32 requestID = requestRandomness(_keyHash);
        _randomnessRequests[requestID] = _currentID;
    }

    function fulfillRandomness(bytes32 requestID, uint256 randomness) internal override {
        uint256 shipID = _randomnessRequests[requestID];
        Ship storage ship = ships[shipID];
        if (ship.rarity == 0) {
            uint256 rarity = randomness % MAX_RARITY + 1;
            ship.rarity = uint64(rarity);
            emit ShipCreated(ownerOf(shipID), shipID, rarity, ship.durability);
        }
    }

    function repair(uint256 shipID) external {
        address owner = ownerOf(shipID);
        require(_msgSender() == owner, "only ship's owner");
        Ship storage ship = ships[shipID];
        require(ship.rarity > 0, "ship not found");
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
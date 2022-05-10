// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ICastle.sol";

contract Castle is ICastle {

    CastleStruct[] idToCastle;

    uint8[6][3] private _maxRolePerCastle;
    uint8[3] private _slotsPerCastleType;

    constructor() {
        _maxRolePerCastle[uint8(CastleType.Starter)] = [1, 1, 1, 1, 1, 1];
        _maxRolePerCastle[uint8(CastleType.Gen1)]    = [3, 1, 1, 1, 1, 1];
        _maxRolePerCastle[uint8(CastleType.Gen2)]    = [0, 0, 0, 0, 0, 0];

        _slotsPerCastleType = [3, 7, 6];
    }

    function newCastle(CastleType castle_type) external returns (uint256)
    {
        uint256 new_castle_id = idToCastle.length;
        idToCastle.push();
        idToCastle[new_castle_id].castle_type = castle_type;
        idToCastle[new_castle_id].name = "";
        idToCastle[new_castle_id].slots = new uint256[](_slotsPerCastleType[uint8(castle_type)]);
        return new_castle_id;
    }

    function getCastle(uint256 castle_id) external view returns (string memory, CastleType, uint256[] memory)
    {
        return (
            idToCastle[castle_id].name,
            idToCastle[castle_id].castle_type,
            idToCastle[castle_id].slots
        );
    }

    function setCastleName(uint256 castle_id, string calldata name) external castleExists(castle_id)
    {
        idToCastle[castle_id].name = name;
    }

    function addTokenToCastle(uint256 castle_id, uint8 slot, ICharacter.Role token_role, uint256 token_id) external castleExists(castle_id)
    {
        ICastle.CastleStruct storage castle = idToCastle[castle_id];

        require(slot < castle.slots.length, "Castle: slot out of range");
        require(castle.slots[slot] == 0, "Castle: slot occupied");

        castle.slots[slot] = token_id;
        castle.role_occupancy[uint8(token_role)]++;

        require(
            castle.role_occupancy[uint8(token_role)] <= _maxRolePerCastle[uint8(castle.castle_type)][uint8(token_role)],
            "Castle: role occupancy maxed out"
        );

        if (castle.castle_type == CastleType.Starter)
        {
            require(
                castle.role_occupancy[uint8(ICharacter.Role.Knight)] +
                castle.role_occupancy[uint8(ICharacter.Role.Priest)] +
                castle.role_occupancy[uint8(ICharacter.Role.Buffoon)] <= 1,
                "Castle: 1 knight or 1 priest or 1 buffoon"
            );
            require(
                castle.role_occupancy[uint8(ICharacter.Role.King)] +
                castle.role_occupancy[uint8(ICharacter.Role.Queen)] <= 1,
                "Castle: 1 king or 1 queen"
            );
        }

        else if (castle.castle_type == CastleType.Gen1)
        {
            require(
                castle.role_occupancy[uint8(ICharacter.Role.Priest)] +
                castle.role_occupancy[uint8(ICharacter.Role.Buffoon)] <= 1,
                "Castle: 1 priest or 1 buffoon"
            );
        }
    }

    function removeTokenFromCastle(uint256 castle_id, uint8 slot, ICharacter.Role token_role) external castleExists(castle_id)
    {
        ICastle.CastleStruct storage castle = idToCastle[castle_id];

        require(castle.slots[slot] > 0, "Castle: empty slot");

        castle.slots[slot] = 0;
        castle.role_occupancy[uint8(token_role)]--;
    }

    modifier castleExists(uint256 castle_id)
    {
        require(castle_id < idToCastle.length, "Castle: ID out of range");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICharacter {

    enum Role {
        Peasant,
        King,
        Queen,
        Knight,
        Priest,
        Buffoon
    }

    struct CharacterStruct {
        uint8 generation;
        Role role;
    }

    function getCharacter(uint256) external view returns (uint8, Role);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ICharacter.sol";

interface ICastle {

    enum CastleType {
        Starter,
        Gen1,
        Gen2
    }

    struct CastleStruct {
        string name;
        CastleType castle_type;
        uint8[6] role_occupancy;  //TODO nombre de roles à update ici
        uint256[] slots;
    }

    function newCastle(CastleType) external returns (uint256);

    function setCastleName(uint256, string memory) external;

    function getCastle(uint256) external view returns (string memory, CastleType, uint256[] memory);

    function addTokenToCastle(uint256, uint8, ICharacter.Role, uint256) external;

    function removeTokenFromCastle(uint256, uint8, ICharacter.Role) external;
}
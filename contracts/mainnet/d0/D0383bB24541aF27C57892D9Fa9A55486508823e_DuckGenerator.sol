// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

import "./Strings.sol";
import "./ICreature.sol";

contract DuckGenerator {
    using Strings for uint256;

    struct imageFormat {
        string name;
        string png;
    }

    string[6] duckParts = [
        "Breed",
        "Beak",
        "Hat",
        "Feet",
        "Level",
        "Modifier"
    ];

    string[7] farmerParts = [
        "Skin Color",
        "Boots",
        "Overalls",
        "Shirt",
        "Hair",
        "Hat",
        "Pitchfork"
    ];

    string[4] coyoteParts = [
        "Body",
        "Eyes",
        "Feet",
        "Chest"
    ];

    mapping(uint8 => mapping(uint8 => imageFormat)) creatureData;

    ICreature public creature;

    constructor() {
        
    }

    function setCreature(address _c) external {
        creature = ICreature(_c);
    }

    function uploadPNG(uint8 part, uint8[] calldata ids, imageFormat[] calldata images) public{
        require(ids.length == images.length, "Mismatched input lengths");
        for(uint i = 0; i < images.length; i++){
            creatureData[part][ids[i]] = imageFormat(
                images[i].name,
                images[i].png
            );
        }
    }

    function drawDuckPNG(imageFormat memory image) internal pure returns (string memory) {
        return string(abi.encodePacked(
            '<image x="4" y="4" width="32" height="32" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
            image.png,
            '"/>'
        ));
    }

    function drawDuckSVG(uint256 tokenId) internal view returns (string memory) {
        ICreature.Ducky memory d = creature.getTokenTraits(tokenId);
        string memory svg;
        if(d.creatureType == 1){
            svg = string(abi.encodePacked(
            drawDuckPNG(creatureData[0][d.layer_0]),
            drawDuckPNG(creatureData[1][d.layer_1]),
            drawDuckPNG(creatureData[2][d.layer_2]),
            drawDuckPNG(creatureData[3][d.layer_3])));
        }
        else if(d.creatureType == 2){
            svg = string(abi.encodePacked(
            drawDuckPNG(creatureData[4][d.layer_0]),
            drawDuckPNG(creatureData[5][d.layer_1]),
            drawDuckPNG(creatureData[6][d.layer_2]),
            drawDuckPNG(creatureData[7][d.layer_3]),
            drawDuckPNG(creatureData[8][d.layer_4]),
            drawDuckPNG(creatureData[9][d.layer_5]),
            drawDuckPNG(creatureData[10][d.layer_6])));
        }
        else{
            svg = string(abi.encodePacked(
            drawDuckPNG(creatureData[11][d.layer_0]),
            drawDuckPNG(creatureData[12][d.layer_1]),
            drawDuckPNG(creatureData[13][d.layer_2]),
            drawDuckPNG(creatureData[14][d.layer_3])));
        }
        

        return string(abi.encodePacked(
            '<svg id="duck" width="100%" height="100%" version="1.1" viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
            svg,
            "</svg>"
        ));
    }

    function compilePart(string memory part, string memory value) internal pure returns (string memory) {
        return string(abi.encodePacked(
            '{"trait_type":"',
            part,
            '","value":"',
            value,
            '"}'
        ));
    }

    function compileAttributes(uint256 tokenId) internal view returns (string memory){
        ICreature.Ducky memory d = creature.getTokenTraits(tokenId);
        string memory attributes;
        if(d.creatureType == 1){
            attributes = string(abi.encodePacked(
                compilePart(duckParts[0], creatureData[0][d.layer_0].name),',',
                compilePart(duckParts[1], creatureData[1][d.layer_1].name),',',
                compilePart(duckParts[2], creatureData[2][d.layer_2].name),',',
                compilePart(duckParts[3], creatureData[3][d.layer_3].name),',',
                compilePart(duckParts[4], (uint256(d.level)).toString()),',',
                compilePart(duckParts[5], d.eggModifier.toString())
            ));
        }
        else if(d.creatureType == 2){
            attributes = string(abi.encodePacked(
                compilePart(farmerParts[0], creatureData[4][d.layer_0].name),',',
                compilePart(farmerParts[1], creatureData[5][d.layer_1].name),',',
                compilePart(farmerParts[2], creatureData[6][d.layer_2].name),',',
                compilePart(farmerParts[3], creatureData[7][d.layer_3].name),',',
                compilePart(farmerParts[4], creatureData[8][d.layer_4].name),',',
                compilePart(farmerParts[5], creatureData[9][d.layer_4].name),',',
                compilePart(farmerParts[6], creatureData[10][d.layer_5].name)
            ));
        }
        else if(d.creatureType == 3){
            attributes = string(abi.encodePacked(
                compilePart(coyoteParts[0], creatureData[11][d.layer_0].name),',',
                compilePart(coyoteParts[1], creatureData[12][d.layer_1].name),',',
                compilePart(coyoteParts[2], creatureData[13][d.layer_2].name),',',
                compilePart(coyoteParts[3], creatureData[14][d.layer_3].name)
            ));
        }
        return string(abi.encodePacked(
            '[',
            attributes,
            ']'));
    }

    function tokenURI(uint256 tokenId) public view returns (string memory){
        ICreature.Ducky memory d = creature.getTokenTraits(tokenId);
        string memory c_type;
        if(d.creatureType == 1){
            c_type = 'Duck #';
        }
        else if(d.creatureType == 2){
            c_type = 'Farmer #';
        }
        else if(d.creatureType == 3){
            c_type = 'Coyote #';
        }
        string memory metadata = string(abi.encodePacked(
            '{"name": "',
            c_type,
            tokenId.toString(),
            '", "description": "Ducks farm their precious $DXT in hopes to grow more of their flock, the ever scheming coyotes have their own plan in mind in this high stakes game. Our project is 100% on-chain.", "image": "data:image/svg+xml;base64,',
            base64(bytes(drawDuckSVG(tokenId))),
            '", "attributes":',
            compileAttributes(tokenId),
            "}"
        ));

        return string(abi.encodePacked(
            "data:application/json;base64,",
            base64(bytes(metadata))
        ));
    }

    /** BASE 64 - Written by Brecht Devos */
  
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function base64(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
        // set the actual output length
        mstore(result, encodedLen)
        
        // prepare the lookup table
        let tablePtr := add(table, 1)
        
        // input ptr
        let dataPtr := data
        let endPtr := add(dataPtr, mload(data))
        
        // result ptr, jump over length
        let resultPtr := add(result, 32)
        
        // run over the input, 3 bytes at a time
        for {} lt(dataPtr, endPtr) {}
        {
            dataPtr := add(dataPtr, 3)
            
            // read 3 bytes
            let input := mload(dataPtr)
            
            // write 4 characters
            mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
            resultPtr := add(resultPtr, 1)
            mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
            resultPtr := add(resultPtr, 1)
            mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
            resultPtr := add(resultPtr, 1)
            mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
            resultPtr := add(resultPtr, 1)
        }
        
        // padding with '='
        switch mod(mload(data), 3)
        case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
        case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface ICreature {
    struct Ducky {
        uint8 creatureType;
        uint8 layer_0;
        uint8 layer_1;
        uint8 layer_2;
        uint8 layer_3;
        uint8 layer_4;
        uint8 layer_5;
        uint8 layer_6;
        uint8 level;
        uint256 eggModifier;
    }

    function getTokenTraits(uint256 tokenId) external view returns (Ducky memory);
}
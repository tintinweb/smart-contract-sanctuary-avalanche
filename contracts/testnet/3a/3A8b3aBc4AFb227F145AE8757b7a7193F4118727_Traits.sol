// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

import "./Libraries.sol";
import "./Controllable.sol";

import "./Skeleton.sol";

contract Traits is Controllable {
    using Strings for uint256;

    uint256 private alphaTypeIndex = 7;

    // struct to store each trait's data for metadata and rendering
    struct Trait {
        string name;
        string png;
    }

    string public skeletonBody;
    string public rangerBody;

    // mapping from trait type (index) to its name
    string[8] _traitTypes = [
        // for adventurers:
        "Jacket",
        "Hair",
        "Backpack",
        //for hunters:
        "Arm",
        "Clothes",
        "Mask",
        "Weapon"
    ];

    // storage of each traits name and base64 PNG data
    mapping(uint8 => mapping(uint8 => Trait)) public traitData;
    mapping(uint8 => uint8) public traitCountForType;
    // mapping from alphaIndex to its score
    string[6] _alphas = ["10", "9", "8", "7", "6", "5"];
    string[5] _levels = ["1", "2", "3", "4", "5"];

    Skeleton public skeleton;

    function selectTrait(uint16 seed, uint8 traitType)
        external
        view
        returns (uint8)
    {
        if (traitType == alphaTypeIndex) {
            //42 25 15 10 5 3
            uint256 m = seed % 100;
            if (m >= 97) {
                return 0;
            } else if (m >= 92) {
                return 1;
            } else if (m >= 82) {
                return 2;
            } else if (m >= 68) {
                return 3;
            } else if (m >= 43) {
                return 4;
            } else {
                return 5;
            } 
        }

        uint8 modOf = traitCountForType[traitType];

        return uint8(seed % modOf);
    }

    /***ADMIN */

    function setSkeleton(address _skeleton) external onlyController {
        skeleton = Skeleton(_skeleton);
    }

    function uploadBodies(string calldata _skeletonBody, string calldata _rangerBody)
        external
        onlyController
    {
        skeletonBody = _skeletonBody;
        rangerBody = _rangerBody;
    }

    function uploadTraits(
        uint8 traitType,
        uint8[] calldata traitIds,
        string[] calldata names,
        string[] calldata pngs
    ) external onlyController {
        require(traitIds.length == names.length && names.length == pngs.length, "Mismatched inputs");
        uint8 maxTraitId = 0;
        for (uint256 i = 0; i < traitIds.length; i++) {
            traitData[traitType][traitIds[i]] = Trait(names[i], pngs[i]);
            if (traitIds[i] > maxTraitId) maxTraitId = traitIds[i];
        }
        if (traitCountForType[traitType] <= maxTraitId) traitCountForType[traitType] = maxTraitId + 1;
    }

    /***RENDER */

    /**
     * generates an <image> element using base64 encoded PNGs
     * @param trait the trait storing the PNG data
     * @return the <image> element
     */
    function drawTrait(Trait memory trait)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '<image x="4" y="4" width="32" height="32" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
                    trait.png,
                    '"/>'
                )
            );
    }

    function draw(string memory png) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<image x="4" y="4" width="32" height="32" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
                    png,
                    '"/>'
                )
            );
    }

    /**
     * generates an entire SVG by composing multiple <image> elements of PNGs
     * @param tokenId the ID of the token to generate an SVG for
     * @return a valid SVG of the Adventurer / skeleton
     */

    function drawSVG(uint256 tokenId) public view returns (string memory) {
        Skeleton.SklRgr memory s = skeleton.getTokenTraits(tokenId);

        string memory svgString = "";
        if (s.isRanger) {
            svgString = string(
                abi.encodePacked(
                    drawTrait(traitData[0][s.jacket]),
                    drawTrait(traitData[2][s.backpack]),
                    draw(rangerBody),
                    drawTrait(traitData[1][s.hair])
                )
            );
        } else {
            svgString = string(
                abi.encodePacked(
                    draw(skeletonBody),
                    drawTrait(traitData[4][s.clothes]),
                    drawTrait(traitData[5][s.mask]),
                    drawTrait(traitData[6][s.weapon]),
                    drawTrait(traitData[3][s.arm])
                )
            );
        }

        return
            string(
                abi.encodePacked(
                    '<svg id="skeleton" width="100%" height="100%" version="1.1" viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
                    svgString,
                    "</svg>"
                )
            );
    }

    /**
     * generates an attribute for the attributes array in the ERC721 metadata standard
     * @param traitType the trait type to reference as the metadata key
     * @param value the token's trait associated with the key
     * @return a JSON dictionary for the single attribute
     */
    function attributeForTypeAndValue(
        string memory traitType,
        string memory value
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '{"trait_type":"',
                    traitType,
                    '","value":"',
                    value,
                    '"}'
                )
            );
    }

    /**
     * generates an array composed of all the individual traits and values
     * @param tokenId the ID of the token to compose the metadata for
     * @return a JSON array of all of the attributes for given token ID
     */
    function compileAttributes(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        Skeleton.SklRgr memory s = skeleton.getTokenTraits(tokenId);
        string memory traits;
        if (s.isRanger) {
            traits = string(
                abi.encodePacked(
                    attributeForTypeAndValue(
                        _traitTypes[0],
                        traitData[0][s.jacket % traitCountForType[0]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        _traitTypes[1],
                        traitData[1][s.hair % traitCountForType[1]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        _traitTypes[2],
                        traitData[2][s.backpack % traitCountForType[2]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        "Level",
                        _levels[s.level-1]
                    ),
                    ","
                )
            );
        } else {
            traits = string(
                abi.encodePacked(
                    attributeForTypeAndValue(
                        _traitTypes[4],
                        traitData[4][s.clothes % traitCountForType[4]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        _traitTypes[5],
                        traitData[5][s.mask % traitCountForType[5]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        _traitTypes[6],
                        traitData[6][s.weapon % traitCountForType[6]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        _traitTypes[3],
                        traitData[3][s.arm % traitCountForType[3]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        "Alpha Score",
                        _alphas[s.alphaIndex]
                    ),
                    ",",
                    attributeForTypeAndValue(
                        "Level",
                        _levels[s.level-1]
                    ),
                    ","
                )
            );
        }
        return
            string(
                abi.encodePacked(
                    "[",
                    traits,
                    '{"trait_type":"Generation","value":',
                    tokenId <= skeleton.getPaidTokens() ? '"Gen 0"' : '"Gen 1"',
                    '},{"trait_type":"Type","value":',
                    s.isRanger ? '"Ranger"' : '"Skeleton"',
                    "}]"
                )
            );
    }

    /**
     * generates a base64 encoded metadata response without referencing off-chain content
     * @param tokenId the ID of the token to generate the metadata for
     * @return a base64 encoded JSON dictionary of the token's metadata and SVG
     */
    function tokenURI(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        Skeleton.SklRgr memory s = skeleton.getTokenTraits(tokenId);

        string memory metadata = string(
            abi.encodePacked(
                '{"name": "',
                s.isRanger ? "Ranger #" : "Skeleton #",
                tokenId.toString(),
                '", "description": "Skeletons letzgooo", "image": "data:image/svg+xml;base64,',
                base64(bytes(drawSVG(tokenId))),
                '", "attributes":',
                compileAttributes(tokenId),
                "}"
            )
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    base64(bytes(metadata))
                )
            );
    }

    /***BASE 64 - Written by Brech Devos */

    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function base64(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

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
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }
}
// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

import "./Libraries.sol";
import "./Controllable.sol";

import "./Skeleton.sol";

contract Traits is Controllable {
    using Strings for uint256;

    // struct to store each trait's data for metadata and rendering
    struct Trait {
        string name;
        string png;
    }

    string public skeletonBody;
    string public rangerBody;
    string[5] public backgrounds; // backgrounds[0] -> level 1, backgrounds[1] -> level 2

    string[4] rangerTraitTypes   = ["Arm", "Head", "Body" , "Gadget"];
    string[4] skeletonTraitTypes = ["Arm", "Head", "Torso", "Legs"  ];

    // 0: Arm | 1: Head | 2: Body | 3: Gadget
    mapping(uint8 => Trait)[4] public rangerTraitData;
    // 0: Arm | 1: Head | 2: Torso | 3: Legs | 4: Additional Layer
    mapping(uint8 => Trait)[5] public skeletonTraitData;

    uint8[4] public rangerTraitCountForType;
    uint8[4] public skeletonTraitCountForType;

    Skeleton public skeleton;

    function selectRangerTraits(uint256 seed) external view returns (uint8 arm, uint8 head, uint8 body, uint8 gadget) {
        arm    = uint8(seed         % rangerTraitCountForType[0]);
        head   = uint8((seed >> 16) % rangerTraitCountForType[1]);
        body   = uint8((seed >> 32) % rangerTraitCountForType[2]);
        gadget = uint8((seed >> 48) % rangerTraitCountForType[3]);
    }

    function selectSkeletonTraits(uint256 seed) external view returns (uint8 arm, uint8 head, uint8 torso, uint8 legs) {
        arm   = uint8(seed         % skeletonTraitCountForType[0]);
        head  = uint8((seed >> 32) % skeletonTraitCountForType[1]);
        torso = uint8((seed >> 48) % skeletonTraitCountForType[2]);
        legs  = uint8((seed >> 64) % skeletonTraitCountForType[3]);
    }

    /***ADMIN */

    function setSkeleton(address _skeleton) external onlyController {
        skeleton = Skeleton(_skeleton);
    }

    function uploadBackground(string[5] calldata _backgrounds)
        external
        onlyController
    {
        for(uint8 i = 0; i < 5; i++){
            backgrounds[i] = _backgrounds[i];
        }
    }

    function uploadRangerTraits(
        uint8 traitType,
        uint8[] calldata traitIds,
        string[] calldata names,
        string[] calldata pngs
    ) external onlyController {
        require(traitIds.length == names.length && names.length == pngs.length, "Mismatched inputs");
        uint8 maxTraitId = 0;
        for (uint256 i = 0; i < traitIds.length; i++) {
            rangerTraitData[traitType][traitIds[i]] = Trait(names[i], pngs[i]);
            if (traitIds[i] > maxTraitId) maxTraitId = traitIds[i];
        }
        if (rangerTraitCountForType[traitType] <= maxTraitId) rangerTraitCountForType[traitType] = maxTraitId + 1;
    }

    function uploadSkeletonTraits(
        uint8 traitType,
        uint8[] calldata traitIds,
        string[] calldata names,
        string[] calldata pngs
    ) external onlyController {
        require(traitIds.length == names.length && names.length == pngs.length, "Mismatched inputs");
        uint8 maxTraitId = 0;
        for (uint256 i = 0; i < traitIds.length; i++) {
            skeletonTraitData[traitType][traitIds[i]] = Trait(names[i], pngs[i]);
            if (traitIds[i] > maxTraitId) maxTraitId = traitIds[i];
        }
        if (skeletonTraitCountForType[traitType] <= maxTraitId) skeletonTraitCountForType[traitType] = maxTraitId + 1;
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
                    '<image x="4" y="4" width="64" height="64" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
                    trait.png,
                    '"/>'
                )
            );
    }

    function draw(string memory png) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<image x="4" y="4" width="64" height="64" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
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
                    draw(backgrounds[s.level-1]),
                    drawTrait(rangerTraitData[0][s.arm]),
                    drawTrait(rangerTraitData[1][s.head]),
                    drawTrait(rangerTraitData[2][s.body]),
                    drawTrait(rangerTraitData[3][s.gadget])
                )
            );
        } else {
            svgString = string(
                abi.encodePacked(
                    draw(backgrounds[s.level-1]),
                    drawTrait(skeletonTraitData[0][s.arm]),
                    drawTrait(skeletonTraitData[3][s.legs]),
                    drawTrait(skeletonTraitData[2][s.torso]),
                    drawTrait(skeletonTraitData[4][s.arm]), // Additional Layer (weapon)
                    drawTrait(skeletonTraitData[1][s.head])
                )
            );
        }

        return
            string(
                abi.encodePacked(
                    '<svg id="skeleton" width="100%" height="100%" version="1.1" viewBox="0 0 72 72" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
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
    function compileAttributes(uint256 tokenId) public view returns(string memory) {
        Skeleton.SklRgr memory s = skeleton.getTokenTraits(tokenId);
        string memory traits;
        if (s.isRanger) {
            traits = string(
                abi.encodePacked(
                    attributeForTypeAndValue(
                        rangerTraitTypes[0],
                        rangerTraitData[0][s.arm % rangerTraitCountForType[0]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        rangerTraitTypes[1],
                        rangerTraitData[1][s.head % rangerTraitCountForType[1]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        rangerTraitTypes[2],
                        rangerTraitData[2][s.body % rangerTraitCountForType[2]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        rangerTraitTypes[3],
                        rangerTraitData[3][s.gadget % rangerTraitCountForType[3]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        "Level",
                        uint256(s.level).toString()
                    ),
                    ","
                )
            );
        } else {
            traits = string(
                abi.encodePacked(
                    attributeForTypeAndValue(
                        skeletonTraitTypes[0],
                        skeletonTraitData[0][s.arm % skeletonTraitCountForType[0]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        skeletonTraitTypes[1],
                        skeletonTraitData[1][s.head % skeletonTraitCountForType[1]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        skeletonTraitTypes[2],
                        skeletonTraitData[2][s.torso % skeletonTraitCountForType[2]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        skeletonTraitTypes[3],
                        skeletonTraitData[3][s.legs % skeletonTraitCountForType[3]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        "Alpha Score",
                        uint256(s.alphaIndex).toString()
                    ),
                    ",",
                    attributeForTypeAndValue(
                        "Level",
                        uint256(s.level).toString()
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
    function tokenURI(uint256 tokenId) public view returns(string memory) {
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
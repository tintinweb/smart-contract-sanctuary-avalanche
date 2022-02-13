// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

import "./Libraries.sol";
import "./Controllable.sol";

import "./Pets.sol";


contract AttributesPets is Controllable {
    using Strings for uint256;

    struct Boost {
        // By NFT -> only for rangers
        uint8 productionSpeed; // dog
        uint8 claimTaxReduction;  //cat
        uint8[4] productionSpeedByNFTStaked;  //mushroom
        uint8 unstakeStealReduction;  // Guardian
        uint8 unstakeStealAugmentation; // Done
        uint8 unstakeCooldownAugmentation;
        uint8[4] productionSpeedByTimeWithoutTransfer;
        // By wallet
        uint8 globalProductionSpeed;
        uint8 skeletonProbabilityAugmentation;
        uint8 skeletonProbabilityReduction;
        uint8 reMintProbabilityAugmentation;

        uint8 stolenProbabilityAugmentation;
        uint8 stolenProbabilityReduction;
        uint8 alphaAugmentation;
        uint8[4] globalProductionSpeedByNFTStaked;
    }

    struct Attributes {
        string name;
        string png;
        uint8 rarity;
        uint8 boostName;
    }

    Attributes[] private attributes;
    Boost[] private boosts;

    string[6] rarityNames = [
        "Common",
        "Uncommon",
        "Rare",
        "Epic",
        "Legendary",
        "Limited"
    ];

    string[11] bonusNames = [
        "Lucky mint", // 0    increase % chance to mint a skeleton
        "Gambler", // 1    increase % chance to mint a skeleton BUT increase % chance to get stolen
        "Foresight", //    2 decrease % chance to get stolen
        "Wisdom", // 3    decrease % chance to get stolen BUT decrease % chance to mint a skeleton
        "Grower", //  4    % production speed
        "Holder", // 5    % production speed according to time spent without selling $GLOW
        "Staker", // 6    % production speed according to NFTs staked number
        "Degenerate grower", // 7    % production speed + increase % chance to get all $GLOW stolen at unstake
        "Long term grower", // 8    % production speed + increase time before being able to unstake NFT 
        "Tax evader", // 9    Reducing 20% tax on Ranger
        "Evasion" // 10    Reducing 50% tax to get everything stolen on unstake
    ];

    Pets public pets;

    constructor() {
        attributes.push();
        boosts.push();
    }

    function setGame(address _pets) external onlyController {
        pets = Pets(_pets);
    }

    function numberOfPets() public view returns(uint256) {
        return attributes.length;
    }

    function getAttributes(uint8 petId) external view returns(Attributes memory) {
        return attributes[petId];
    }

    function getBoost(uint8 petId) external view returns(Boost memory) {
        return boosts[petId];
    }

    /*
     * administrative to upload the names and images associated with each trait
     * @param traitType the trait type to upload the traits for (see traitTypes for a mapping)
     * @param traits the names and base64 encoded PNGs for each trait
     */

    function uploadAttributes(
        uint8[] calldata petIds, // the first ever is [1, 2, ...]
        Attributes[] calldata uploadedAttributes
    ) external onlyController {
        for (uint256 i = 0; i < uploadedAttributes.length; i++) {
            while (attributes.length < petIds[i]) {
                attributes.push();
            }
            if (attributes.length == petIds[i]) {
                attributes.push(uploadedAttributes[i]);
            } else {
                attributes[petIds[i]] = uploadedAttributes[i];
            }
        }
    }

    function uploadBoosts(
        uint8[] calldata petIds, // the first ever is [1, 2, ...]
        Boost[] calldata uploadedBoosts
    ) external onlyController {
        for (uint256 i = 0; i < uploadedBoosts.length; i++) {
            while (boosts.length < petIds[i]) {
                boosts.push();
            }
            if (boosts.length == petIds[i]) {
                boosts.push(uploadedBoosts[i]);
            } else {
                boosts[petIds[i]] = uploadedBoosts[i];
            }
        }
    }

    /***RENDER */

    function draw(uint8 attributeId) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<image x="4" y="4" width="32" height="32" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
                    attributes[attributeId].png,
                    '"/>'
                )
            );
    }

    /**
     * generates an entire SVG by composing multiple <image> elements of PNGs
     * @param attributeId the ID of the token to generate an SVG for
     * @return a valid SVG of the Adventurer / Hunter
     */
    function drawSVG(uint8 attributeId) public view returns (string memory) {
        string memory svgString = draw(attributeId);
        return
            string(
                abi.encodePacked(
                    '<svg id="hunter" width="100%" height="100%" version="1.1" viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
                    svgString,
                    "</svg>"
                )
            );
    }

    /**
     * generates an attribute for the attributes array in the ERC721 metadata standard
     * @param attributeType the trait type to reference as the metadata key
     * @param value the token's trait associated with the key
     * @return a JSON dictionary for the single attribute
     */
    function attributeForTypeAndValue(
        string memory attributeType,
        string memory value
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '{"trait_type":"',
                    attributeType,
                    '","value":"',
                    value,
                    '"}'
                )
            );
    }

    /**
     * generates an array composed of all the individual traits and values
     * @param attributeId the ID of the token to compose the metadata for
     * @return a JSON array of all of the attributes for given token ID
     */
    function compileAttributes(uint8 attributeId)
        public
        view
        returns (string memory)
    {
        Attributes memory attr = attributes[attributeId];

        return
            string(
                abi.encodePacked(
                    "[",
                    attributeForTypeAndValue("Name", attr.name),
                    ",",
                    attributeForTypeAndValue("Rarity", uint256(attr.rarity).toString()),
                    ",",
                    attributeForTypeAndValue("Bonus", uint256(attr.boostName).toString()),
                    "]"
                )
            );
    }

    /**
     * generates a base64 encoded metadata response without referencing off-chain content
     * @param tokenId the ID of the token to generate the metadata for
     * @return a base64 encoded JSON dictionary of the token's metadata and SVG
     */
    function tokenURI(uint256 tokenId, uint8 attributeId)
        public
        view
        returns (string memory)
    {
        string memory metadata = string(
            abi.encodePacked(
                '{"name": Pet #',
                tokenId.toString(),
                '", "description": "Pets for YieldHunt game !!", "image": "data:image/svg+xml;base64,',
                base64(bytes(drawSVG(attributeId))),
                '", "attributes":',
                compileAttributes(attributeId),
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
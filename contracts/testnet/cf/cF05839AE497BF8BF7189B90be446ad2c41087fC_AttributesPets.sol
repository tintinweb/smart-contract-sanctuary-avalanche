// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

import "./Libraries.sol";
import "./Controllable.sol";

import "./Pets.sol";


contract AttributesPets is Controllable {
    using Strings for uint256;

    struct Boost {
        // By NFT -> only for rangers
        uint8 productionSpeed;
        uint8 claimTaxReduction;
        uint8[4] productionSpeedByNFTStaked;
        uint8 unstakeStealReduction;
        uint8 unstakeStealAugmentation;
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

    string[] boostNames = [
        "No Bonus",           // 0  Nothing
        "Gambler",            // 1  Increase % chance to mint a skeleton BUT increase % chance to get stolen
        "Foresight",          // 2  Decrease % chance to get stolen
        "Wisdom",             // 3  Decrease % chance to get stolen BUT decrease % chance to mint a skeleton
        "Grower",             // 4  % production speed
        "Holder",             // 5  % production speed according to time spent without selling $GLOW
        "Staker",             // 6  % production speed according to NFTs staked number
        "Degenerate Grower",  // 7  % production speed + increase % chance to get all $GLOW stolen at unstake
        "Long Term Grower",   // 8  % production speed + increase time before being able to unstake NFT 
        "Tax evader",         // 9  Reducing 20% tax on Ranger
        "Evasion",            // 10 Reducing 50% tax to get everything stolen on unstake
        "Lucky Mint"          // 11 Increase % chance to mint a skeleton
        "Power Giver",        // 12 Increase temporarly all staked skeleton alpha score
        "Ultimate Minter"     // 13 Chance to mint 2 NFTs
        "Ultimate Grower"     // 14 Increases production speed for all NFTs
    ];

    Pets public pets;

    constructor() {
        // Index 0 reserved to an "empty" pet
        attributes.push();
        boosts.push();
    }

    function setPets(address _pets) external onlyController {
        pets = Pets(_pets);
    }

    function setBoostName(uint256 index, string memory _boostName) external onlyController {
        while (boostNames.length <= index) {
            boostNames.push("No Bonus");
        }
        boostNames[index] = _boostName;
    }

    function numberOfPets() public view returns(uint256) {
        return attributes.length - 1;
    }

    function getAttributes(uint8 petId) external view returns(Attributes memory) {
        return attributes[petId];
    }

    function getBoost(uint8 petId) external view returns(Boost memory) {
        return boosts[petId];
    }

    function uploadAttributes(
        uint8[] calldata _petIds,
        string[] calldata _names,
        string[] calldata _pngs,
        uint8[] calldata _rarities,
        uint8[] calldata _boostNames
    ) external onlyController {
        for (uint256 i = 0; i < _petIds.length; i++) {
            while (attributes.length < _petIds[i]) {
                attributes.push();
            }
            if (attributes.length == _petIds[i]) {
                attributes.push(Attributes(_names[i], _pngs[i], _rarities[i], _boostNames[i]));
            } else {
                attributes[_petIds[i]] = Attributes(_names[i], _pngs[i], _rarities[i], _boostNames[i]);
            }
        }
    }

    function uploadBoosts(
        uint8[] calldata _petIds,
        Boost[] calldata _uploadedBoosts
    ) external onlyController {
        for (uint256 i = 0; i < _uploadedBoosts.length; i++) {
            while (boosts.length < _petIds[i]) {
                boosts.push();
            }
            if (boosts.length == _petIds[i]) {
                boosts.push(_uploadedBoosts[i]);
            } else {
                boosts[_petIds[i]] = _uploadedBoosts[i];
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
                    '<svg id="yh_pet" width="100%" height="100%" version="1.1" viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
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
                    attributeForTypeAndValue("Rarity", rarityNames[attr.rarity]),
                    ",",
                    attributeForTypeAndValue("Bonus", boostNames[attr.boostName]),
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
                '{"name": "Pet #',
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
// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ITraits.sol";
import "./IFraudsterVsCommissioner.sol";
import "./Address.sol";
import "./Strings.sol";

contract Traits is Ownable, ITraits {
    using Strings for uint256;

    uint256 private alphaTypeIndex = 7;

    // struct to store each trait's data for metadata and rendering
    struct Trait {
        string name;
        string png;
    }

    // storage of each traits name and base64 PNG data
    mapping(uint8 => mapping(uint8 => Trait)) public traitData;
    mapping(uint8 => uint8) public traitCountForType;
    // mapping from alphaIndex to its score
    string[4] _alphas = ["8", "7", "6", "5"];

    IFraudsterVsCommissioner public fvc;

    function selectTrait(uint16 seed, uint8 traitType)
        external
        view
        override
        returns (uint8)
    {
        if (traitType == alphaTypeIndex) {
            uint256 m = seed % 100;
            if (m > 95) {
                return 0;
            } else if (m > 80) {
                return 1;
            } else if (m > 50) {
                return 2;
            } else {
                return 3;
            }
        }

        uint8 modOf = traitCountForType[traitType];

        return uint8(seed % modOf);
    }

    /***ADMIN */

    function setGame(address _fvc) external onlyOwner {
        fvc = IFraudsterVsCommissioner(_fvc);
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
        IFraudsterVsCommissioner.FraudsterCommissioner memory s = fvc.getTokenTraits(tokenId);
        string memory traits;
        if (s.isFraudster) {
            traits = string(
                abi.encodePacked()
            );
        } else {
            traits = string(
                abi.encodePacked(
                    attributeForTypeAndValue(
                        "Alpha Score",
                        _alphas[s.alphaIndex]
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
                    tokenId <= fvc.getPaidTokens() ? '"Gen 0"' : '"Gen 1"',
                    '},{"trait_type":"Type","value":',
                    s.isFraudster ? '"Fraudster"' : '"Commissioner"',
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
        override
        returns (string memory)
    {
        IFraudsterVsCommissioner.FraudsterCommissioner memory s = fvc.getTokenTraits(tokenId);

        string memory metadata = string(
            abi.encodePacked(
                '{"name": "',
                s.isFraudster ? "Fraudster #" : "Commissioner #",
                tokenId.toString(),
                '", "description": "SEC Games is a P2E NFT game on Avalanche. Players will be able to mint, stake and earn on their NFTs, whilst also being able to steal NFTs from other players!:  https://svc.com ", "image": "',
                s.isFraudster ? abi.encodePacked('https://ipfs.io/ipfs/QmYXgNz455Kp77iuvfC32sgjSjFTZtgBLooZaYpcUDiDVM/Fraudster', Strings.toString(fvc.getClassId(tokenId)), '.jpg') : abi.encodePacked('https://ipfs.io/ipfs/QmYXgNz455Kp77iuvfC32sgjSjFTZtgBLooZaYpcUDiDVM/Commissioner', Strings.toString(fvc.getClassId(tokenId)), '.jpg'),
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
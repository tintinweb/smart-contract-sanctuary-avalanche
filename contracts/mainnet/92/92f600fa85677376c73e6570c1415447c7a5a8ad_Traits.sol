/**
 *Submitted for verification at snowtrace.io on 2022-02-25
*/

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IOwnable {
    function owner() external view returns (address);

    function renounceOwnership() external;

    function transferOwnership(address newOwner_) external;
}

contract Ownable is IOwnable {
    address internal _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view override returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual override onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner_)
        public
        virtual
        override
        onlyOwner
    {
        require(
            newOwner_ != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner_);
        _owner = newOwner_;
    }
}

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

interface ITalesofAsheaGame {
    // struct to store each token's traits
    struct TalesofAshea {
        bool isAdventurer;
        bool isKing;
        uint8 body;
        uint8 weapon;
        uint8 hat;
        uint8 head;
        uint8 armor;
        uint8 helmet;
        uint8 crown;
        uint8 authority;
        uint8 gen;
    }

    function getPaidTokens() external view returns (uint256);

    function getTokenTraits(uint256 tokenId)
        external
        view
        returns (TalesofAshea memory);
}

contract Traits is Ownable {
    using Strings for uint256;

    uint256 private alphaTypeIndex = 27; //king

    // struct to store each trait's data for metadata and rendering
    struct Trait {
        string name;
        string png;
    }

    // mapping from trait type (index) to its name
    string[8] _traitTypes = [
        "Weapon",
        "Hat",
        "Head",
        "Armor",
        "Helmet",
        "Crown",
        "Authority",
        "Body"
    ];
    // storage of each traits name and base64 PNG data
    mapping(uint8 => mapping(uint8 => Trait)) public traitData;
    mapping(uint8 => uint8) public traitCountForType;
    // mapping from authority to its score
    string[3] _alphas = ["450", "325", "225"];
    string[3] _level = ["3", "2", "1"];
    ITalesofAsheaGame public game;

    function selectTrait(uint16 seed, uint8 traitType)
        external
        view
        returns (uint8)
    {
        if (traitType == alphaTypeIndex) {
            uint256 m = seed % 100;
            if (m > 90) {
                return 0;
            } else if (m > 80) {
                return 1;
            } else {
                return 2;
            }
        }
        uint8 modOf = traitCountForType[traitType] > 0
            ? traitCountForType[traitType]
            : 10;
        return uint8(seed % modOf);
    }

    /***ADMIN */

    function setGame(address _game) external onlyOwner {
        game = ITalesofAsheaGame(_game);
    }

    /**
     * administrative to upload the names and images associated with each trait
     * @param traitType the trait type to upload the traits for (see traitTypes for a mapping)
     * @param traits the names and base64 encoded PNGs for each trait
     */
    function uploadTraits(
        uint8 traitType,
        uint8[] calldata traitIds,
        Trait[] calldata traits
    ) external onlyOwner {
        require(traitIds.length == traits.length, "Mismatched inputs");

        for (uint256 i = 0; i < traits.length; i++) {
            traitData[traitType][traitIds[i]] = Trait(
                traits[i].name,
                traits[i].png
            );
        }
    }

    function setTraitCountForType(uint8[] memory _tType, uint8[] memory _len)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _tType.length; i++) {
            traitCountForType[_tType[i]] = _len[i];
        }
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

    /**
     * generates an entire SVG by composing multiple <image> elements of PNGs
     * @param tokenId the ID of the token to generate an SVG for
     * @return a valid SVG of the Adventurer / King
     */
    function drawSVG(uint256 tokenId) public view returns (string memory) {
        ITalesofAsheaGame.TalesofAshea memory s = game.getTokenTraits(tokenId);
        uint8 shift = s.isAdventurer ? 0 : s.isKing ? 20 : 10;

        string memory svgString;
        if (s.isAdventurer) {
            svgString = string(
                abi.encodePacked(
                    drawTrait(
                        traitData[0 + shift][
                            s.weapon % traitCountForType[0 + shift]
                        ]
                    ),
                    drawTrait(
                        traitData[5 + shift][
                            s.body % traitCountForType[5 + shift]
                        ]
                    ),
                    drawTrait(
                        traitData[2 + shift][
                            s.head % traitCountForType[2 + shift]
                        ]
                    ),
                    drawTrait(
                        traitData[1 + shift][
                            s.hat % traitCountForType[1 + shift]
                        ]
                    )
                )
            );
        } else if (s.isKing) {
            svgString = string(
                abi.encodePacked(
                    drawTrait(
                        traitData[0 + shift][
                            s.weapon % traitCountForType[0 + shift]
                        ]
                    ),
                    drawTrait(
                        traitData[5 + shift][
                            s.body % traitCountForType[5 + shift]
                        ]
                    ),
                    drawTrait(
                        traitData[1 + shift][
                            s.crown % traitCountForType[1 + shift]
                        ]
                    )
                )
            );
        } else {
            svgString = string(
                abi.encodePacked(
                    drawTrait(
                        traitData[0 + shift][
                            s.weapon % traitCountForType[0 + shift]
                        ]
                    ),
                    drawTrait(
                        traitData[5 + shift][
                            s.body % traitCountForType[5 + shift]
                        ]
                    ),
                    drawTrait(
                        traitData[1 + shift][
                            s.armor % traitCountForType[2 + shift]
                        ]
                    ),
                    drawTrait(
                        traitData[2 + shift][
                            s.helmet % traitCountForType[1 + shift]
                        ]
                    )
                )
            );
        }

        return
            string(
                abi.encodePacked(
                    '<svg id="game" width="100%" height="100%" version="1.1" viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
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
        ITalesofAsheaGame.TalesofAshea memory s = game.getTokenTraits(tokenId);
        string memory traits;
        if (s.isAdventurer) {
            traits = string(
                abi.encodePacked(
                    attributeForTypeAndValue(
                        _traitTypes[0],
                        traitData[0][s.weapon % traitCountForType[0]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        _traitTypes[1],
                        traitData[1][s.hat % traitCountForType[1]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        _traitTypes[2],
                        traitData[2][s.head % traitCountForType[2]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        _traitTypes[7],
                        traitData[5][s.body % traitCountForType[5]].name
                    ),
                    ","
                )
            );
        } else if (s.isKing) {
            traits = string(
                abi.encodePacked(
                    attributeForTypeAndValue(
                        _traitTypes[0],
                        traitData[20][s.weapon % traitCountForType[20]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        _traitTypes[5],
                        traitData[21][s.crown % traitCountForType[21]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        _traitTypes[7],
                        traitData[25][s.body % traitCountForType[25]].name
                    ),
                    ",",
                    attributeForTypeAndValue("Authority", _alphas[s.authority]),
                    ",",
                    attributeForTypeAndValue("Level", _level[s.authority]),
                    ","
                )
            );
        } else {
            traits = string(
                abi.encodePacked(
                    attributeForTypeAndValue(
                        _traitTypes[0],
                        traitData[10][s.weapon % traitCountForType[10]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        _traitTypes[3],
                        traitData[11][s.armor % traitCountForType[11]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        _traitTypes[4],
                        traitData[12][s.helmet % traitCountForType[12]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        _traitTypes[7],
                        traitData[15][s.body % traitCountForType[15]].name
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
                    '{"trait_type":"Generation","value":"',
                    "Gen",
                    uint256(s.gen).toString(),
                    '"},{"trait_type":"Type","value":',
                    s.isAdventurer ? '"Adventurer"' : s.isKing
                        ? '"King"'
                        : '"Guildmaster"',
                    "}]"
                )
            );
    }

    /**
     * generates a base64 encoded metadata response without referencing off-chain content
     * @param tokenId the ID of the token to generate the metadata for
     * @return a base64 encoded JSON dictionary of the token's metadata and SVG
     */
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        ITalesofAsheaGame.TalesofAshea memory s = game.getTokenTraits(tokenId);

        string memory metadata = string(
            abi.encodePacked(
                '{"name": "',
                s.isAdventurer ? "Adventurer #" : s.isKing
                    ? "King #"
                    : "Guildmaster #",
                tokenId.toString(),
                '", "description": "In the depth of the mountain, a mysterious country where everything can happen. Human, elf, orc and goblin, living together with only one goal, collect all the $TALES. All those adventurers are risking their lives for this precious resources and are waiting to join a party at the guild. The guildmaster is here to help them along while providing them some quests to earn their $TALES.", "image": "data:image/svg+xml;base64,',
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
/**
 *Submitted for verification at snowtrace.io on 2022-08-03
*/

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: gladiator-finance-contracts/contracts/glad_core/roman_nft/IPreyPredator.sol


pragma solidity ^0.8.0;

interface IPreyPredator {
    event TokenTraitsUpdated(uint256 tokenId, PreyPredator traits);
    // struct to store each token's traits
    struct PreyPredator {
        bool isPrey;
        uint8 environment;
        uint8 body;
        uint8 armor;
        uint8 helmet;
        uint8 shoes;
        uint8 shield;
        uint8 weapon;
        uint8 item;
        uint8 alphaIndex;
        uint64 generation;
        uint8 agility;
        uint8 charisma;
        uint8 damage;
        uint8 defense;
        uint8 dexterity;
        uint8 health;
        uint8 intelligence;
        uint8 luck;
        uint8 strength;
    }

    function traitsRevealed(uint256 tokenId) external view returns (bool);

    function getTokenTraits(uint256 tokenId)
        external
        view
        returns (PreyPredator memory);

    function mintUnderpeg(
        address to,
        uint256 amount,
        uint256 price
    ) external;

    function increaseGeneration() external;

    function currentGeneration() external view returns (uint8);

    function getGenTokens(uint8 generation) external view returns (uint256);

    function mintedPrice(uint256 tokenId) external view returns (uint256);
}

// File: gladiator-finance-contracts/contracts/glad_core/roman_nft/ITraits.sol



pragma solidity ^0.8.0;

interface ITraits {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
// File: gladiator-finance-contracts/contracts/glad_core/roman_nft/Traits.sol



pragma solidity 0.8.9;





contract Traits is Ownable, ITraits {
    using Strings for uint256;

    // struct to store each trait's data for metadata and rendering
    struct Trait {
        string name;
        string png;
    }

    // mapping from trait type (index) to its name
    //TODO: if it doesn't work check the names of the files in PS.
    string[21] _traitTypes = [
        "Environment",
        "Body",
        "Clothing",
        "Armor",
        "Helmet",
        "Shoes",
        "Shield",
        "Weapon",
        "Item",
        "Alpha",
        "Generation",
        "Agility",
        "Charisma",
        "Damage",
        "Defense",
        "Dexterity",
        "Health",
        "Intelligence",
        "Luck",
        "Strength"
    ];
    // storage of each traits name and base64 PNG data
    mapping(uint8 => mapping(uint8 => Trait)) public traitData;
    // mapping from number to string
    string[] numToString;


    IPreyPredator public preyPredator;

    constructor() {
        for (uint256 i = 0; i <= 100; i++) {
            numToString.push(i.toString());
        }
    }

    function addNumbers(uint256 amount) external {
        for (uint256 i = 0; i < amount; i++) {
            numToString.push((numToString.length).toString());
        }
    }

    /** ADMIN */

    function setPreyPredator(address _pp) external onlyOwner {
        preyPredator = IPreyPredator(_pp);
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

    function uploadTrait(
        uint8 traitType,
        uint8 traitId,
        Trait memory trait
    ) external onlyOwner {
        traitData[traitType][traitId] = trait;
    }

    /** RENDER */

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
                    '<image x="0" y="0" width="32" height="32" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
                    trait.png,
                    '"/>'
                )
            );
    }

    /**
     * generates an entire SVG by composing multiple <image> elements of PNGs
     * @param tokenId the ID of the token to generate an SVG for
     * @return a valid SVG of the Prey / Predator
     */
    function drawSVG(uint256 tokenId) public view returns (string memory) {
        IPreyPredator.PreyPredator memory s = preyPredator.getTokenTraits(tokenId);
        uint8 shift = s.isPrey ? 0 : 10;

        string memory svgString = string(
            abi.encodePacked(
                drawTrait(traitData[0 + shift][s.environment]),
                drawTrait(traitData[8 + shift][s.item]),
                drawTrait(traitData[1 + shift][s.body]),
                s.isPrey ? "" : drawTrait(traitData[2 + shift][s.alphaIndex]),
                s.isPrey ? drawTrait(traitData[5 + shift][s.shoes]) : "",
                s.isPrey ? drawTrait(traitData[3 + shift][s.armor]) : "",
                s.isPrey ? drawTrait(traitData[4 + shift][s.helmet]) : "",
                s.isPrey ? drawTrait(traitData[6 + shift][s.shield]) : "",
                drawTrait(traitData[7 + shift][s.weapon])
            )
        );

        return
            string(
                abi.encodePacked(
                    '<svg id="gladiatorfinance" width="100%" height="100%" version="1.1" viewBox="0 0 32 32" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
                    svgString,
                    "</svg>"
                )
            );
    }

    function attributeForTypeAndValue(
        string memory traitType,
        string memory value
    ) internal pure returns (string memory) {
        return attributeForTypeAndValue(traitType, value, true, false);
    }
    /**
     * generates an attribute for the attributes array in the ERC721 metadata standard
     * @param traitType the trait type to reference as the metadata key
     * @param value the token's trait associated with the key
     * @return a JSON dictionary for the single attribute
     */
    function attributeForTypeAndValue(
        string memory traitType,
        string memory value,
        bool isString,
        bool displayAsNumber
    ) internal pure returns (string memory)  {
        return
            string(
                abi.encodePacked(
                    '{"trait_type":"',
                    traitType,
                    displayAsNumber ? '","display_type":"number' : '',
                    isString ? '","value":"' : '","value":',
                    value,
                    isString ? '"},' : '},'
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
        IPreyPredator.PreyPredator memory s = preyPredator.getTokenTraits(tokenId);
        string memory traits;
        if (s.isPrey) {
            traits = string(
                abi.encodePacked(
                    attributeForTypeAndValue(
                        _traitTypes[0],
                        traitData[0][s.environment].name
                    ),
                    attributeForTypeAndValue(
                        _traitTypes[1],
                        traitData[1][s.body].name
                    ),
                    attributeForTypeAndValue(
                        _traitTypes[3],
                        traitData[3][s.armor].name
                    ),
                    attributeForTypeAndValue(
                        _traitTypes[4],
                        traitData[4][s.helmet].name
                    ),
                    attributeForTypeAndValue(
                        _traitTypes[5],
                        traitData[5][s.shoes].name
                    ),
                    attributeForTypeAndValue(
                        _traitTypes[6],
                        traitData[6][s.shield].name
                    ),
                    attributeForTypeAndValue(
                        _traitTypes[7],
                        traitData[7][s.weapon].name
                    ),
                    attributeForTypeAndValue(
                        _traitTypes[8],
                        traitData[8][s.item].name
                    )
                )
            );
        } else {
            traits = string(
                abi.encodePacked(
                    attributeForTypeAndValue(
                        _traitTypes[0],
                        traitData[10][s.environment].name
                    ),
                    attributeForTypeAndValue(
                        _traitTypes[1],
                        traitData[11][s.body].name
                    ),
                    attributeForTypeAndValue(
                        _traitTypes[2],
                        traitData[12][s.alphaIndex].name
                    ),
                    attributeForTypeAndValue(
                        _traitTypes[7],
                        traitData[17][s.weapon].name
                    ),
                    attributeForTypeAndValue(
                        _traitTypes[8],
                        traitData[18][s.item].name
                    ),
                    attributeForTypeAndValue(
                        _traitTypes[9],
                        numToString[s.alphaIndex + 1]
                    )
                )
            );
        }
        string memory attributes = string(
                abi.encodePacked(
                    attributeForTypeAndValue(
                        _traitTypes[11],
                        numToString[s.agility],
                        false, false
                    ),
                    attributeForTypeAndValue(
                        _traitTypes[12],
                        numToString[s.charisma],
                        false, false
                    ),
                    attributeForTypeAndValue(
                        _traitTypes[13],
                        numToString[s.damage],
                        false, false
                    ),
                    attributeForTypeAndValue(
                        _traitTypes[14],
                        numToString[s.defense],
                        false, false
                    ),
                    attributeForTypeAndValue(
                        _traitTypes[15],
                        numToString[s.dexterity],
                        false, false
                    ),
                    attributeForTypeAndValue(
                        _traitTypes[16],
                        numToString[s.health],
                        false, false
                    ),
                    attributeForTypeAndValue(
                        _traitTypes[17],
                        numToString[s.intelligence],
                        false, false
                    ),
                    attributeForTypeAndValue(
                        _traitTypes[18],
                        numToString[s.luck],
                        false, false
                    ),
                    attributeForTypeAndValue(
                        _traitTypes[19],
                        numToString[s.strength],
                        false, false
                    )
                )
            );
        return
            string(
                abi.encodePacked(
                    "[",
                    traits,
                    attributeForTypeAndValue(
                        _traitTypes[10],
                        numToString[s.generation],
                        false, true
                    ),
                    attributes,
                    '{"trait_type":"Type","value":',
                    s.isPrey ? '"Gladiator"' : '"Emperor"',
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
        IPreyPredator.PreyPredator memory s = preyPredator.getTokenTraits(tokenId);

        string memory metadata = string(
            abi.encodePacked(
                '{"name": "',
                s.isPrey ? "Gladiator #" : "Emperor #",
                tokenId.toString(),
                '", "description": "Gladiator Finance https://gladiatorfinance.app", "image": "data:image/svg+xml;base64,',
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

    /** BASE 64 - Written by Brech Devos */

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
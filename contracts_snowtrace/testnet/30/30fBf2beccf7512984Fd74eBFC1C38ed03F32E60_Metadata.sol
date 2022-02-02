// SPDX-License-Identifier: MIT LICENSE

    pragma solidity ^0.8.0;

    import "@openzeppelin/contracts/access/Ownable.sol";
    import "@openzeppelin/contracts/utils/Strings.sol";
    import "./interfaces/IMetadata.sol";
    import "./interfaces/INFT.sol";

    contract Metadata is Ownable, IMetadata {

        using Strings for uint256;

        uint256 private levelTypeIndex = 17;

        // struct to store each meta's data for metadata and rendering
        struct Meta {
            string name;
            string png;
        }

        string masterBackground;
        string slaveBackground;

        // mapping from meta type (index) to its name
        string[8] _metaTypes = [
        "Clothing",
        "Face",
        "Mouth",
        "Eyes",
        "Additional",
        "Headgear",
        "MasterAttribut",
        "LevelAttribut"
        ];
        // storage of each metadata name and base64 PNG data
        mapping(uint8 => mapping(uint8 => Meta)) public metaData;
        mapping(uint8 => uint8) public metaCountForType;
        // mapping from levelIndex to its score
        string[4] _levels = [
        "8",
        "7",
        "6",
        "5"
        ];

        INFT public masterAndSlave;
    

        function selectMeta(uint16 seed, uint8 metaType) external view override returns(uint8) {
            if (metaType == levelTypeIndex) {
                uint256 chance = seed % 100;
                if (chance > 95) {
                    return 0;
                } else if (chance > 80) {
                    return 1;
                } else if (chance > 50) {
                    return 2;
                } else {
                    return 3;
                }
            }
            uint8 modOf = metaCountForType[metaType] > 0 ? metaCountForType[metaType] : 10;
            return uint8(seed % modOf);
        }

        /***ADMIN */

        function setGame(address _masterAndSlave) external onlyOwner {
            masterAndSlave = INFT(_masterAndSlave);
        }

        function uploadBackground(string calldata _master, string calldata _slave) external onlyOwner {
            masterBackground = _master;
            slaveBackground = _slave;
        }

        function uploadBackgroundMaster(string calldata _master) external onlyOwner {
            masterBackground = _master;
        }

        function uploadBackgroundSlave(string calldata _slave) external onlyOwner {
            slaveBackground = _slave;
        }

        /**
        * administrative to upload the names and images associated with each meta
        * @param metaType the meta type to upload the metadata for (see metaTypes for a mapping)
    * @param metadata the names and base64 encoded PNGs for each meta
    */

        function uploadMetadata(uint8 metaType, uint8[] calldata metaIds, Meta[] calldata metadata) external onlyOwner {
            require(metaIds.length == metadata.length, "Mismatched inputs");
            for (uint i = 0; i < metadata.length; i++) {
                metaData[metaType][metaIds[i]] = Meta(
                    metadata[i].name,
                    metadata[i].png
                );
            }
        }

        function setMetaCountForType(uint8[] memory _tType, uint8[] memory _len) public onlyOwner {
            for (uint i = 0; i < _tType.length; i++) {
                metaCountForType[_tType[i]] = _len[i];
            }
        }

        /**
    * allows owner to withdraw funds from minting
    */
    function withdraw() external onlyOwner {  
        address receiver = owner();
        payable(receiver).transfer(address(this).balance);
    }
    
        /***RENDER */

        /**
        * generates an <image> element using base64 encoded PNGs
        * @param meta the meta storing the PNG data
    * @return the <image> element
    */
        function drawMeta(Meta memory meta) internal pure returns (string memory) {
            return string(abi.encodePacked(
                    '<image x="4" y="4" width="32" height="32" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
                    meta.png,
                    '"/>'
                ));
        }

        function draw(string memory png) internal pure returns (string memory) {
            return string(abi.encodePacked(
                    '<image x="4" y="4" width="32" height="32" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
                    png,
                    '"/>'
                ));
        }

        /**
        * generates an entire SVG by composing multiple <image> elements of PNGs
        * @param tokenId the ID of the token to generate an SVG for
    *
    */
        function drawSVG(uint256 tokenId) public view returns (string memory) {
            INFT.NFTMetadata memory s = masterAndSlave.getTokenMetadata(tokenId);
            uint8 shift = s.isSlave ? 0 : 10;

            string memory svgString = string(abi.encodePacked(
                    s.isSlave ? draw(slaveBackground) : draw(masterBackground),
                    drawMeta(metaData[0 + shift][s.clothing % metaCountForType[0 + shift]]),
                    drawMeta(metaData[1 + shift][s.face % metaCountForType[1 + shift]]),
                    drawMeta(metaData[2 + shift][s.mouth % metaCountForType[2 + shift]]),
                    drawMeta(metaData[3 + shift][s.eyes % metaCountForType[3 + shift]]),
                    drawMeta(metaData[4 + shift][s.additional % metaCountForType[4 + shift]]),
                    drawMeta(metaData[5 + shift][s.headgear % metaCountForType[5 + shift]]),
                    !s.isSlave ? drawMeta(metaData[6 + shift][s.masterAttribut % metaCountForType[6 + shift]]) : '',
                    !s.isSlave ? drawMeta(metaData[7 + shift][s.levelIndex]) : ''
                ));

            return string(abi.encodePacked(
                    '<svg id="masterAndSlave" width="100%" height="100%" version="1.1" viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
                    svgString,
                    "</svg>"
                ));
        }

        /**
        * generates an attribute for the attributes array in the ERC721 metadata standard
        * @param metaType the meta type to reference as the metadata key
    * @param value the token's meta associated with the key
    * @return a JSON dictionary for the single attribute
    */
        function attributeForTypeAndValue(string memory metaType, string memory value) internal pure returns (string memory) {
            return string(abi.encodePacked(
                    "{",'"meta_type":"',
                    metaType,
                    '","value":"',
                    value,
                    '"},'
                ));
        }

        /**
        * generates an array composed of all the individual metadata and values
        * @param tokenId the ID of the token to compose the metadata for
    * @return a JSON array of all of the attributes for given token ID
    */
        function compileAttributes(uint256 tokenId) public view returns (string memory) {
            INFT.NFTMetadata memory s = masterAndSlave.getTokenMetadata(tokenId);
            string memory metadata;
            if (s.isSlave) {
                metadata = string(abi.encodePacked(
                        attributeForTypeAndValue(_metaTypes[0], metaData[0][s.clothing % metaCountForType[0]].name),
                        attributeForTypeAndValue(_metaTypes[1], metaData[1][s.face % metaCountForType[1]].name),
                        attributeForTypeAndValue(_metaTypes[2], metaData[2][s.mouth % metaCountForType[2]].name),
                        attributeForTypeAndValue(_metaTypes[3], metaData[3][s.eyes % metaCountForType[3]].name),
                        attributeForTypeAndValue(_metaTypes[4], metaData[4][s.additional % metaCountForType[4]].name),
                        attributeForTypeAndValue(_metaTypes[5], metaData[5][s.headgear % metaCountForType[5]].name)
                    ));
            } else {
                metadata = string(abi.encodePacked(
                        attributeForTypeAndValue(_metaTypes[0], metaData[10][s.clothing % metaCountForType[10]].name),
                        attributeForTypeAndValue(_metaTypes[1], metaData[11][s.face % metaCountForType[11]].name),
                        attributeForTypeAndValue(_metaTypes[2], metaData[12][s.mouth % metaCountForType[12]].name),
                        attributeForTypeAndValue(_metaTypes[3], metaData[13][s.eyes % metaCountForType[13]].name),
                        attributeForTypeAndValue(_metaTypes[4], metaData[14][s.additional % metaCountForType[14]].name),
                        attributeForTypeAndValue(_metaTypes[5], metaData[15][s.headgear % metaCountForType[15]].name),
                        attributeForTypeAndValue(_metaTypes[6], metaData[16][s.masterAttribut % metaCountForType[16]].name),
                        attributeForTypeAndValue(_metaTypes[7], metaData[17][s.levelIndex % metaCountForType[17]].name),
                        attributeForTypeAndValue("Level Score", _levels[s.levelIndex])
                    ));
            }
            return string(abi.encodePacked(
                    '[',
                    metadata,
                    "{",'"meta_type":"Generation","value":',
                    tokenId <= masterAndSlave.getPaidTokens() ? '"Gen 0"' : '"Gen 1"',
                    "},{",'"meta_type":"Type","value":',
                    s.isSlave ? '"Slave"' : '"Master"',
                    "}]"
                ));
        }

        /**
        * generates a base64 encoded metadata response without referencing off-chain content
        * @param tokenId the ID of the token to generate the metadata for
    * @return a base64 encoded JSON dictionary of the token's metadata and SVG
    */
        function tokenURI(uint256 tokenId) public view override returns (string memory) {
            INFT.NFTMetadata memory s = masterAndSlave.getTokenMetadata(tokenId);

            string memory metadataGame = string(abi.encodePacked(
                    "{",'"name": "',
                    s.isSlave ? 'Slave #' : 'Master #',
                    tokenId.toString(),
                    '", "description":  "Slave & Master Game" is the next-generation NFT game on FTM that incorporates likelihood-based game derivatives in addition to NFT. With a wide range of choices and decision options, Slave & Master Game promises to generate an exciting and inquisitive community as each individual adopts different strategies to outperform the others and come out on top. The real question is: Are you #TeamSlave or #TeamMaster? Choose wisely or wait and watch the other get rich!", "image": "data:image/svg+xml;base64,',
                    base64(bytes(drawSVG(tokenId))),
                    '", "attributes":',
                    compileAttributes(tokenId),
                    "}"
                ));

            return string(abi.encodePacked(
                    "data:application/json;base64,",
                    base64(bytes(metadataGame))
                ));
        }

        /***BASE 64 - Written by Brech Devos */

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
                    mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F)))))
                    resultPtr := add(resultPtr, 1)
                    mstore(resultPtr, shl(248, mload(add(tablePtr, and(input, 0x3F)))))
                    resultPtr := add(resultPtr, 1)
                }

            // padding with '='
                switch mod(mload(data), 3)
                case 1 {mstore(sub(resultPtr, 2), shl(240, 0x3d3d))}
                case 2 {mstore(sub(resultPtr, 1), shl(248, 0x3d))}
            }

            return result;
        }
    }

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface INFT {
  // struct to store each token's metas
  struct NFTMetadata {
    bool isSlave;
    uint8 clothing;
    uint8 face;
    uint8 mouth;
    uint8 eyes;
    uint8 additional;
    uint8 headgear;
    uint8 masterAttribut;
    uint8 levelIndex;
  }

  function getPaidTokens() external view returns (uint256);

  function getTokenMetadata(uint256 tokenId)
    external
    view
    returns (NFTMetadata memory);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IMetadata {
  function tokenURI(uint256 tokenId) external view returns (string memory);

  function selectMeta(uint16 seed, uint8 metaType)
    external
    view
    returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
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
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
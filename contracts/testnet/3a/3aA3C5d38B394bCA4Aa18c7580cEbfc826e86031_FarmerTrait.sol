/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-06
*/

// Sources flattened with hardhat v2.8.4 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/access/[email protected]


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}


// File @openzeppelin/contracts/utils/introspection/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


// File @openzeppelin/contracts/token/ERC721/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}


// File contracts/interfaces/IFarmer.sol



pragma solidity ^0.8.0;

interface IFarmer is IERC721Enumerable {

    struct FarmerStruct {
        uint clothes;
        uint shoes;
        uint gloves;
        uint hat;
        uint handTool;
        uint glasses;
        uint faceHair;
        uint hair;
    }


    function getTokenScore(uint _tokenId) external view returns (uint);

    function getPaidTokens() external view returns (uint);

    function getTokenTraits(uint256 _tokenId) external view returns (FarmerStruct memory);
}


// File contracts/interfaces/IFarmerTrait.sol



pragma solidity ^0.8.0;

interface IFarmerTrait {
    struct Trait {
        string name;
        uint share;
        uint score;
    }

    function selectTrait(uint _traitType, uint _selectionRange) external view returns (uint);

    function getTrait(uint _type, uint _index) external view returns (Trait memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}


// File contracts/FarmerTrait.sol



pragma solidity ^0.8.0;




// import "hardhat/console.sol";

contract FarmerTrait is IFarmerTrait, Ownable {
  using Strings for uint256;

  IFarmer farmer;
  Trait[20][8] public traitData;

  string public baseImageUri;

  constructor(IFarmer _farmer, string memory _baseImageUri) {
    farmer = _farmer;
    baseImageUri = _baseImageUri;
  }

  function initTraits() external onlyOwner {
    // Clothes
    // 2170
    traitData[0][0] = Trait("Regular", 2170, 10);
    // 3770
    traitData[0][1] = Trait("T-Shirt", 1600, 20);
    // 5070
    traitData[0][2] = Trait("Green Lumberjack", 1300, 30);
    // 6070
    traitData[0][3] = Trait("Traditional", 1000, 40);
    // 6870
    traitData[0][4] = Trait("Red", 800, 50);
    // 7570
    traitData[0][5] = Trait("Relax", 700, 60);
    // 8070
    traitData[0][6] = Trait("Bavarian", 500, 70);
    // 8470
    traitData[0][7] = Trait("Wais Coat", 400, 80);
    // 8770
    traitData[0][8] = Trait("Robot", 300, 90);
    // 9020
    traitData[0][9] = Trait("Singlet", 250, 100);
    // 9220
    traitData[0][10] = Trait("Pharmacist", 200, 110);
    // 9400
    traitData[0][11] = Trait("Indian", 180, 120);
    // 9560
    traitData[0][12] = Trait("Repairman", 160, 130);
    // 9700
    traitData[0][13] = Trait("Cowboy", 140, 140);
    // 9820
    traitData[0][14] = Trait("Asian Farmer", 120, 150);
    // 9920
    traitData[0][15] = Trait("Mexican Poncho", 100, 160);
    // 10000
    traitData[0][16] = Trait("Medieval", 80, 170);

    // Shoes
    // 2200
    traitData[1][0] = Trait("Cowboy", 2200, 10);
    // 4000
    traitData[1][1] = Trait("Sport", 1800, 20);
    // 5400
    traitData[1][2] = Trait("Boot", 1400, 30);
    // 6400
    traitData[1][3] = Trait("Plastic", 1000, 40);
    // 7200
    traitData[1][4] = Trait("Regular", 800, 50);
    // 7900
    traitData[1][5] = Trait("Green", 700, 60);
    // 8500
    traitData[1][6] = Trait("Robot", 600, 70);
    // 9000
    traitData[1][7] = Trait("Indian", 500, 80);
    // 9400
    traitData[1][8] = Trait("Black", 400, 90);
    // 9700
    traitData[1][9] = Trait("Yellow", 300, 100);
    // 9900
    traitData[1][10] = Trait("Leather", 200, 110);
    // 10000
    traitData[1][11] = Trait("Nasa Space", 100, 120);

    // Gloves
    // 2100
    traitData[2][0] = Trait("Regular", 2100, 10);
    // 3800
    traitData[2][1] = Trait("Black Leater", 1700, 20);
    // 5000
    traitData[2][2] = Trait("Thanos Gloves", 1200, 30);
    // 6000
    traitData[2][3] = Trait("Robot", 1000, 40);
    // 6800
    traitData[2][4] = Trait("Indian", 800, 50);
    // 7500
    traitData[2][5] = Trait("Iron", 700, 60);
    // 8100
    traitData[2][6] = Trait("Fur", 600, 70);
    // 8600
    traitData[2][7] = Trait("Plastic", 500, 80);
    // 9000
    traitData[2][8] = Trait("Terminator Like", 400, 90);
    // 9300
    traitData[2][9] = Trait("Electric", 300, 100);
    // 9550
    traitData[2][10] = Trait("Metaverse VR", 250, 110);
    // 9750
    traitData[2][11] = Trait("Yellow Leather", 200, 120);
    // 9900
    traitData[2][12] = Trait("Space", 150, 130);
    // 10000
    traitData[2][13] = Trait("Nasa", 100, 140);

    // Hat
    //  2100
    traitData[3][0] = Trait("None", 2100, 0);
    // 3850
    traitData[3][1] = Trait("Regular (Straw Hat)", 1750, 10);
    // 5100
    traitData[3][2] = Trait("Mexican", 1250, 20);
    // 6100
    traitData[3][3] = Trait("Vietnamies Hat", 1000, 30);
    // 6900
    traitData[3][4] = Trait("Traper", 800, 40);
    // 7600
    traitData[3][5] = Trait("Beanie Hat", 700, 50);
    // 8200
    traitData[3][6] = Trait("Hard Hat", 600, 60);
    // 8700
    traitData[3][7] = Trait("Cap with Headphone", 500, 70);
    // 9100
    traitData[3][8] = Trait("Hunter Hat", 400, 80);
    // 9400
    traitData[3][9] = Trait("Cycle Helmet", 300, 90);
    // 9650
    traitData[3][10] = Trait("Open Motorcycle Helmet", 250, 100);
    // 9850
    traitData[3][11] = Trait("Safari Hat", 200, 110);
    // 10000
    traitData[3][12] = Trait("Peaky Blinders Hat", 150, 120);

    // Tools
    // 2050
    traitData[4][0] = Trait("Pickaxe", 2050, 10);
    // 3750
    traitData[4][1] = Trait("Diamond Pickaxe", 1700, 20);
    // 4950
    traitData[4][2] = Trait("Saw", 1200, 30);
    // 5950
    traitData[4][3] = Trait("Shovel", 1000, 40);
    // 6750
    traitData[4][4] = Trait("Scythe", 800, 50);
    // 7450
    traitData[4][5] = Trait("Space Tool", 700, 60);
    // 8050
    traitData[4][6] = Trait("Electric Scythe", 600, 70);
    // 8550
    traitData[4][7] = Trait("Metaverse Tool", 500, 80);
    // 8950
    traitData[4][8] = Trait("Ax", 400, 90);
    // 9250
    traitData[4][9] = Trait("Sickle", 300, 100);
    // 9500
    traitData[4][10] = Trait("Spade", 250, 110);
    // 9700
    traitData[4][11] = Trait("Hammer", 200, 120);
    // 9850
    traitData[4][12] = Trait("Gold Ax", 150, 130);
    // 9950
    traitData[4][13] = Trait("Gold Pixkaxe", 100, 140);
    // 10000
    traitData[4][14] = Trait("Thor's hammer", 50, 150);

    // Glasses
    // 2250
    traitData[5][0] = Trait("None", 2250, 0);
    // 4100
    traitData[5][1] = Trait("Safety Glasses", 1850, 10);
    // 5500
    traitData[5][2] = Trait("Snow Glasses", 1400, 20);
    // 6500
    traitData[5][3] = Trait("Space", 1000, 30);
    // 7300
    traitData[5][4] = Trait("MetaVerse", 800, 40);
    // 8000
    traitData[5][5] = Trait("Welding Glasses", 700, 50);
    // 8600
    traitData[5][6] = Trait("Night Vision Goggles", 600, 60);
    // 9100
    traitData[5][7] = Trait("Google Glasses", 500, 70);
    // 9500
    traitData[5][8] = Trait("Bone glasses", 400, 80);
    // 9800
    traitData[5][9] = Trait("Star trek", 300, 90);
    // 10000
    traitData[5][10] = Trait("Bat glasses", 200, 100);

    // Face Hair
    // 2300
    traitData[6][0] = Trait("Regular", 2300, 10);
    // 4200
    traitData[6][1] = Trait("Beard", 1900, 20);
    // 5600
    traitData[6][2] = Trait("Long Beard", 1400, 30);
    // 6700
    traitData[6][3] = Trait("Big Mustache", 1100, 40);
    // 7500
    traitData[6][4] = Trait("Braid Beard", 800, 50);
    // 8200
    traitData[6][5] = Trait("Horseshoe Mustache", 700, 60);
    // 8800
    traitData[6][6] = Trait("Blonde versions", 600, 70);
    // 9300
    traitData[6][7] = Trait("Amish Beard", 500, 80);
    // 9700
    traitData[6][8] = Trait("Fu Manchu", 400, 90);
    // 10000
    traitData[6][9] = Trait("Handlebar moustache", 300, 100);

    // Hair
    // 5000
    traitData[7][0] = Trait("Regular", 5000, 10);
    // 7500
    traitData[7][1] = Trait("Long Hair", 2500, 20);
    // 8500
    traitData[7][2] = Trait("Top Knot", 1000, 30);
    // 9300
    traitData[7][3] = Trait("Man Bun", 800, 40);
    // 9800
    traitData[7][4] = Trait("Rasta", 500, 50);
    // 10000
    traitData[7][5] = Trait("Bold", 200, 60);

    // Validate trait data
    for (uint8 j = 0; j < traitData.length; j++) {
      uint256 sum;
      for (uint8 m = 0; m < traitData[j].length; m++) {
        sum += traitData[j][m].share;
      }

      require(sum == 10000, "Trait data misconfiguration");
    }
  }

  function selectTrait(uint256 _type, uint256 _selectionRange) public view returns (uint256) {
    require(_selectionRange <= 10000, "Invalid range");

    uint256 range = 0;
    for (uint256 t; t < traitData[_type].length; t++) {
      range += traitData[_type][t].share;
      if (_selectionRange < range) {
        return t;
      }
    }

    // This won't happen but have to stay here to make this function happy.
    revert("Couldn't select trait");
  }

  function getTrait(uint256 _type, uint256 _index) public view returns (Trait memory) {
    return traitData[_type][_index];
  }

  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    bytes memory metadata = abi.encodePacked(
      '{"name": "Farmer #',
      _tokenId.toString(),
      '", "description": "FarmLand is an unique P2E game on Avalanche", "image": "',
      baseImageUri,
      "/",
      _tokenId.toString(),
      ".png",
      '", "attributes":',
      compileAttributes(_tokenId),
      "}"
    );

    return string(abi.encodePacked("data:application/json;base64,", Base64.encode(metadata)));
  }

  function compileAttributes(uint256 _tokenId) public view returns (string memory) {
    IFarmer.FarmerStruct memory s = farmer.getTokenTraits(_tokenId);
    string memory traits = string(
      abi.encodePacked(
        attributeForTypeAndValue("Clothes", traitData[0][s.clothes].name),
        ",",
        attributeForTypeAndValue("Shoes", traitData[1][s.shoes].name),
        ",",
        attributeForTypeAndValue("Gloves", traitData[2][s.gloves].name),
        ",",
        attributeForTypeAndValue("Hat", traitData[3][s.hat].name),
        ",",
        attributeForTypeAndValue("Hand Tool", traitData[4][s.handTool].name),
        ",",
        attributeForTypeAndValue("Glasses", traitData[5][s.glasses].name),
        ",",
        attributeForTypeAndValue("Face Hair", traitData[6][s.faceHair].name),
        ",",
        attributeForTypeAndValue("Hair", traitData[7][s.hair].name)
      )
    );

    return string(abi.encodePacked("[", traits, "]"));
  }

  function attributeForTypeAndValue(string memory _traitType, string memory _value)
    internal
    pure
    returns (string memory)
  {
    return string(abi.encodePacked('{"trait_type":"', _traitType, '","value":"', _value, '"}'));
  }
}
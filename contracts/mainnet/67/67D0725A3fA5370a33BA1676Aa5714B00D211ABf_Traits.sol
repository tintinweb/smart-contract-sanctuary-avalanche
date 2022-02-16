/**
 * Avalanche deployment.
 */

import "./ITraits.sol";
import "./IGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Traits is Ownable, ITraits {
  using Strings for uint256;
  uint256 private constant SCORE_TYPE_INDEX = 4;

  struct Trait {
    // Name to be displayed in the metadata
    string name;
    // Used to build the image URI
    string code;
    // Between 0 and 100
    uint8 probability;
  }

  enum TraitType {
    Clothes,
    Shoes,
    Skin,
    Hair,
    BallnChain,
    Accessory,
    GuardBody,
    GuardShoes,
    GuardSkin,
    GuardClothes,
    GuardWeapon
  }

  // Trait type to its name
  mapping(TraitType => string) public _traitTypes;
  // Trait type => possible traits for that trait type
  mapping(uint8 => Trait[]) public traitData;
  // mapping from scoreIndex to its score
  string[4] private _scores = ["8", "7", "6", "5"];

  // The base URI where the images are located
  string public baseURI = "https://prisonersisland.mypinata.cloud/ipfs/Qmcoh6g2TnH941HJ8bmKC5R9B5VTBpzRFtjgNk16bvXE2s/";

  IGuard public prisonerAndGuard;

  constructor() {
    // Only Prisoner
    _traitTypes[TraitType.Clothes] = "Clothes";
    _traitTypes[TraitType.Shoes] = "Shoes";
    _traitTypes[TraitType.Skin] = "Skin";
    _traitTypes[TraitType.Hair] = "Hair";
    _traitTypes[TraitType.BallnChain] = "BallnChain";
    _traitTypes[TraitType.Accessory] = "Accessory";

    // Only Guard
    // _traitTypes[TraitType.GuardScore] = "Score";
    _traitTypes[TraitType.GuardBody] = "Body";
    _traitTypes[TraitType.GuardShoes] = "Shoes";
    _traitTypes[TraitType.GuardSkin] = "Skin";
    _traitTypes[TraitType.GuardClothes] = "Clothes";
    _traitTypes[TraitType.GuardWeapon] = "Weapon";
  }

  function selectTrait(uint16 seed, uint8 traitType)
    external
    view
    override
    returns (uint8)
  {
    // The probabilities of the scores is hardcoded into the contract
    if (traitType == SCORE_TYPE_INDEX) {
      uint256 m = seed % 100;
      if (m > 95) {
        // Score 8 -> 5% chances
        return 0;
      } else if (m > 80) {
        // Score 7 -> 15% chances
        return 1;
      } else if (m > 50) {
        // Score 6 -> 30% chances
        return 2;
      } else {
        // Score 5 -> 50% chances
        return 3;
      }
    }
    uint256 index = seed % 100;
    // Will range from 0 to 100
    uint8 total = 0;
    // Loop through the different traits of that type
    for (uint8 i = 0; i < traitData[traitType].length; i++) {
      // Add the probability to the total
      total += traitData[traitType][i].probability;
      // If the total is above the pseudo-random index
      // we choose this trait
      if (total > index) {
        return i;
      }
    }
    revert("Something is wrong with traits definitions");
  }

  /***ADMIN */

  function setGame(address _prisonerAndGuard) external onlyOwner {
    prisonerAndGuard = IGuard(_prisonerAndGuard);
  }

  function setBaseURI(string memory _baseURI) external onlyOwner {
    baseURI = _baseURI;
  }

  /**
   * administrative to upload the names and images associated with each trait
   * @param traitType the trait type to upload the traits for (see traitTypes for a mapping)
   * @param traits the names for each trait
   */
  function uploadTraits(uint8 traitType, Trait[] calldata traits)
    external
    onlyOwner
  {
    uint8 totalProbabilities = 0;
    for (uint8 i = 0; i < traits.length; i++) {
      totalProbabilities += traits[i].probability;
    }
    // Checking the probabilities are correct
    require(totalProbabilities == 100, "Probabilities must add to 100%");
    // Adding the trait data to the storage
    for (uint8 i = 0; i < traits.length; i++) {
      traitData[traitType].push(
        Trait(traits[i].name, traits[i].code, traits[i].probability)
      );
    }
  }

  /***RENDER */

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
    IGuard.AvtHtr memory s = prisonerAndGuard
      .getTokenTraits(tokenId);
    string memory traits;
    if (s.isPrisoner) {
      if (s.isFemale) {
        traits = string(
          abi.encodePacked(
            attributeForTypeAndValue(
              _traitTypes[TraitType.Clothes],
              traitData[10][s.clothes].name
            ),
            ",",
            attributeForTypeAndValue(
              _traitTypes[TraitType.Shoes],
              traitData[11][s.shoes].name
            ),
            ",",
            attributeForTypeAndValue(
              _traitTypes[TraitType.Skin],
              traitData[12][s.skin].name
            ),
            ",",
            attributeForTypeAndValue(
              _traitTypes[TraitType.Hair],
              traitData[13][s.hair].name
            ),
            ",",
            attributeForTypeAndValue(
              _traitTypes[TraitType.BallnChain],
              traitData[14][s.ballnChain].name
            ),
            ",",
            attributeForTypeAndValue(
              _traitTypes[TraitType.Accessory],
              traitData[15][s.accessory].name
            ),
            ","
          )
        );
      } else {
        traits = string(
          abi.encodePacked(
            attributeForTypeAndValue(
              _traitTypes[TraitType.Clothes],
              traitData[20][s.clothes].name
            ),
            ",",
            attributeForTypeAndValue(
              _traitTypes[TraitType.Shoes],
              traitData[21][s.shoes].name
            ),
            ",",
            attributeForTypeAndValue(
              _traitTypes[TraitType.Skin],
              traitData[22][s.skin].name
            ),
            ",",
            attributeForTypeAndValue(
              _traitTypes[TraitType.Hair],
              traitData[23][s.hair].name
            ),
            ",",
            attributeForTypeAndValue(
              _traitTypes[TraitType.BallnChain],
              traitData[24][s.ballnChain].name
            ),
            ",",
            attributeForTypeAndValue(
              _traitTypes[TraitType.Accessory],
              traitData[25][s.accessory].name
            ),
            ","
          )
        );
      }
    } else {
      traits = string(
        abi.encodePacked(
          attributeForTypeAndValue(
            _traitTypes[TraitType.GuardBody],
            traitData[0][s.guardBody].name
          ),
          ",",
          attributeForTypeAndValue(
            _traitTypes[TraitType.GuardClothes],
            traitData[1][s.guardClothes].name
          ),
          ",",
          attributeForTypeAndValue(
            _traitTypes[TraitType.GuardShoes],
            traitData[2][s.guardShoes].name
          ),
          ",",
          attributeForTypeAndValue(
            _traitTypes[TraitType.GuardSkin],
            traitData[3][s.skin].name
          ),
          ",",
          attributeForTypeAndValue(
            _traitTypes[TraitType.GuardWeapon],
            traitData[4][s.guardScore].name
          ),
          ",",
          attributeForTypeAndValue("Score", _scores[s.guardScore]),
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
          tokenId <= prisonerAndGuard.getPaidTokens() ? '"Gen 0"' : '"Gen 1"',
          '},{"trait_type":"Type","value":',
          s.isPrisoner ? (s.isFemale ? '"FemalePrisoner"' : '"Prisoner"') : '"Guard"',
          "}]"
        )
      );
  }

  function buildImageURI(uint256 tokenId) public view returns (string memory) {
    IGuard.AvtHtr memory s = prisonerAndGuard
      .getTokenTraits(tokenId);
    if (s.isPrisoner) {
      if (s.isFemale) {
        return
          string(
            abi.encodePacked(
              baseURI,
              "FemalePrisoner-",
              traitData[10][s.clothes].code,
              "-",
              traitData[11][s.shoes].code,
              "-",
              traitData[12][s.skin].code,
              "-",
              traitData[13][s.hair].code,
              "-",
              traitData[14][s.ballnChain].code,
              "-",
              traitData[15][s.accessory].code,
              ".png"
            )
          );
      } else {
        return
          string(
            abi.encodePacked(
              baseURI,
              "Prisoner-",
              traitData[20][s.clothes].code,
              "-",
              traitData[21][s.shoes].code,
              "-",
              traitData[22][s.skin].code,
              "-",
              traitData[23][s.hair].code,
              "-",
              traitData[24][s.ballnChain].code,
              "-",
              traitData[25][s.accessory].code,
              ".png"
            )
          );
      }
    } else {
      return
        string(
          abi.encodePacked(
            baseURI,
            "Guard-",
            traitData[0][s.guardBody].code,
            "-",
            traitData[1][s.guardClothes].code,
            "-",
            traitData[2][s.guardShoes].code,
            "-",
            traitData[3][s.skin].code,
            "-",
            traitData[4][s.guardScore].code,
            ".png"
          )
        );
    }
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
    IGuard.AvtHtr memory s = prisonerAndGuard
      .getTokenTraits(tokenId);

    string memory metadata = string(
      abi.encodePacked(
        '{"name": "',
        s.isPrisoner ? (s.isFemale ? "FemalePrisoner #" : "Prisoner #") : "Guard #",
        tokenId.toString(),
        '", "description": "", "image": "',
        buildImageURI(tokenId),
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
        mstore(resultPtr, shl(248, mload(add(tablePtr, and(input, 0x3F)))))
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

/**
 * Avalanche deployment.
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITraits {
    function tokenURI(uint256 tokenId) external view returns (string memory);

    function selectTrait(uint16 seed, uint8 traitType)
    external
    view
    returns (uint8);
}

/**
 * Avalanche deployment.
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGuard {
    // struct to store each token's traits
    struct AvtHtr {
        bool isPrisoner;
        bool isFemale;

        uint8 clothes;
        uint8 shoes;
        uint8 skin;
        uint8 hair;
        uint8 ballnChain;
        uint8 accessory;

        uint8 guardScore;
        uint8 guardBody;
        uint8 guardShoes;
        uint8 guardClothes;
    }

    function getPaidTokens() external view returns (uint256);

    function getTokenTraits(uint256 tokenId)
    external
    view
    returns (AvtHtr memory);
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
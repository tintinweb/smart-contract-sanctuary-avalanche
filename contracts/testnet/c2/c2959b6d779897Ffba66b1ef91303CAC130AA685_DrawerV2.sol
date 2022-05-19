// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ITrait.sol";
import "../libs/Base64.sol";

contract DrawerV2 is Ownable {
  using Base64 for *;

  uint256 constant TEAM_3 = 0x00ae007e005400520058; // w = 88 x = 82 y = 84 x2 = 126 y2 = 172
  uint256 constant TEAM_5 = 0x00a8005c005800300050; // w = 80 x = 48 y = 88 x2 =  88 y2 = 168
  uint256 constant TEAM_7 = 0x00a50036005b0011004a; // w = 74 x = 17 y = 91 x2 =  54 y2 = 165

  string constant BG1 =
    '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" id="woh-round" width="100%" height="100%" version="1.1" viewBox="0 0 1440 960"><image x="0" y="0" width="100%" xlink:href="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAIVBMVEUqHQE9KwVEMAYSDQFLOhUwIgU4JwRALghGNxVCMRNHNAxkkBGrAAADFklEQVRIx63Vz4vTQBQH8G+apOie8rRa11Pz2mr1lHSWVW9ddxD1VNEBj5WVETztqli81VU03vyF2JuCCOav9L2kFlRkc/ASQuaTeZn3Jm9QfgMZkx23BcCDif3k/eHAnPMlIrY7CFD+qEC0tAJGC/vK+9ePeNsbbDAPsP0fgL0JeiygWAJbVxnXvN+9zDkZBFx+FTCwoCc2O86YYHzhPdreZ6153wig+T76R4ML70DPllnLYobx6LACEafUHIyek4IYywRjHuAtfHasPOfXoBcQ7QMx7ExXoWAa83fvBACNQOixjyAB16AHN4v5qQDUgHuGQgOA90x0/VABNqhja7AcHA0Oe3ozA/NJE9mrWAiIaejcFACKBmDcM8gpSBRkkUVkHdqUUg1sQ0C/ACK02AFrQE0AQ8Ep5r7J2jN8tCtwKwGiGhgF5Qrcty7M6GxZgY0mYHerhAIjIOhM4L0AVrAK8WLLCIhvWwGRneCVArpYg3YjcLkGjnPa+HKskETFtxTQZg2ufFaAUAEQWUAAMzvqCLCdf4H3RwFegxsViKdOfnnEkV0ACKoZxLfmm78D/AIXeA2KlwYHNJzCpCTjCrRyK8Bn8OYjMJ/HtxWE2/ftW7iAeOhqUGweDW7UQEK8U8CjAgLu2BU4C3tdQZDAUAUGVioHBacVJA3AjhVwZrH6BpYqrIEZC7j8nAR092F62Lv0RBcI4G5RgRzp3+D9H2DLKjiRViDv8kC3HOT6XLdcSf8BhPkvsMA90hwqGBUuTWCvzQPIBsSDefdAwbl7STl0JsxlBgUA7TQAOTDD+UcwEyRBMk/JZMDQFTLu72MHdTPrVgA16IVwrhSwfEu7DUBEVQOCyRQTcw3sDDqmIWCmAggV8N25JMTEFbDWnmgAYCREPwfFDq3UnzQkQGLtZQoeNgNtH+aOMiStlAQMHXLyYQUeNACBWbY9AkdTHHuRK0g78goJkNKebwBCotAEXUfA8Q+Zz8mlpxREu+DUptBevmeCTQWtfkY58UFXU3r8A/TwbQIsEtAabHs+ILwjOvZCHtiLPwHCa09LdHJFewAAAABJRU5ErkJggg=="/><text x="50%" y="100" font-size="48px">';

  string constant BG2 =
    "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAG1BMVEUrHQE8KgREMAcAAAASDQExIwUhGQhMOhRGNxXhab61AAAEbElEQVRIx43VwY7TMBCA4RnLoT3OWAnN0bES2jsv4FRd6NFbEXaPCCHgmES7tMek2mV5bMbugjgBPuT06R9bVmR4/Y/1H+DzX5eAjyfc+adJbRZVud4aOI9Ain0z9Fdd9iICJ+BHBHNp6hzcWhMOftNBZucIvpww96dJj3Yo93UNphIw+zUTCIiFI5beLbWzmCu3AyblsYQEigQqARvUGwFLV1+AUW4mWIQEZi59cNpNVkCeAJByA+ssvIkAJRYG2YMtMlcAg/JEausYMkhAEyFU+mztdVYVgKBagASW8CoC22qAyp+sDQu+F3B+gGlRuxn2GMFXizKy8kc7hcx0AeB8h4C1GwjalwI+Wd+iqnaLaRHQFBGcWgHrDf8GHAFMKkAC5qj9vNkLwAQcMB7cDmEdwTUszUAeXS2AL0Az3kSwCp6ba1BmFjC63e4y4svbnvGd8yvg4CsBi1QY91V1AV/fes7eOv8Ec/BGAKaC2VUMQwJ7AVc19T8W4do0PGEsENct45j28MMzCIAThGvXcI+DgMD1bsgS+LKRQrYleJoABZDiKhZs67MqjZBCA1taHCegBKpZWRqU7vH8PoINcOa31D5NgV0nYK60pclZjU0qrAWAgFFk8xhBr61H0+9UAl9OwAitgDUVWQKQWw9ubqH5HsHQc5kKLhTZPdM2AUogHXMmZthiBBALraIc/HJTtWDfR3AiNiTArINX9zOogbYC1ra+gA9tBHtk0wh4rGAm8hZKZ2t1AT4BxarxbQSwIiVgQ6SfC0CV3SNitQN1S7BalAqg3FvZyasIkIDtHgRsdXYgsKutgmy1H/Kg3/8XWBA5uwNkJ+CGYLHKFajyj4IOrtICWE4n4DjUCNVmP+gDvIkAPNVEQXFuwHMuwAo41wLsM0Bd5BhB0KzhOJMCc659/gxwi1AU8MC1WYGA9SgfXm/v8sOUgGaNBUGN7aEAXvpqZABTu7v8pk9/N1COTQIVR6DcGmB9NQqAFwn0xI/PYBnBuQmQd+7O38DLBGzPlxFMJVWgxgagvR97f3sp6GVGTPCAOaMAUucO/OH2UNtgLwBaylnAA6MRqoZ78K5L4OUzYM0yomoztpwrJ4C70RP6CD6AHgTgFmefccVncD34otl48wegC4DriWs4C2gEsIZvaYRmzpF8NUSwsl6A4u6dxRy/R1CjABAwRmCsVwDYReCXCTwAYw4gF+iVAO/VClQRAV7A7BMgdl7dTKbVAgw37yxg+SqCqQUjoIjgtq+PJDU2Xf0b9DIj1/A4RzDVxxw5MHdXFmD1PYEhgUKAWU7bSgBFMAE8F+50PEUzHCyt5v1cIlLBRSyYX+A6x4BdY7vjsK9Kny1MK/cNav3tMkKPeZZjVwuol0f2hRrad91jUCY9ahFYZL/bhu5HDquVgDG/67qA7k0EEwuA4gCHkJ0faC59sZgF3AbMU8GucAxQGAMB67afV56zjq+uHoPXL9MIWrjgb4zpLO5O/RP7sn8UcD9RK+Dfb/c/1k8hPWcYy/NsqgAAAABJRU5ErkJggg==";

  string constant STYLE_TEAM =
    "<style>#woh-team{shape-rendering:crispedges;image-rendering:-webkit-crisp-edges;image-rendering:-moz-crisp-edges;image-rendering:crisp-edges;image-rendering:pixelated;-ms-interpolation-mode:nearest-neighbor;}text{font-family:sans-serif;fill:#e74545;text-anchor:middle;}</style></svg>";

  string constant STYLE_ROUND =
    "<style>#woh-round{shape-rendering:crispedges;image-rendering:-webkit-crisp-edges;image-rendering:-moz-crisp-edges;image-rendering:crisp-edges;image-rendering:pixelated;-ms-interpolation-mode:nearest-neighbor;}text{font-family:sans-serif;fill:#e74545;text-anchor:middle;}</style>";

  // x1 =  10, y1 = 720, w1 = 180
  // x2 = 100, y2 = 520, w2 = 360
  // x3 = 280, y3 = 320, w3 = 720
  uint256 constant ROUND_TEAM = 0x02d00140011801680208006400b402d0000a;
  // 180, 540, 900, 1260, 360, 1080, 720
  uint256 constant ROUND_LINE = 0x02d00438016804ec0384021c0064;

  ITrait[] public traits;

  function setTraits(ITrait[] calldata newTraits) external onlyOwner {
    traits = newTraits;
  }

  function getHunterSVG(bool isMale, uint16[] memory pieces) internal view returns (string memory svg) {
    svg = Base64.encode(
      abi.encodePacked(
        '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" id="woh" width="100%" height="100%" version="1.1" viewBox="0 0 64 64">',
        traits[0].getContent(isMale, pieces[6]),
        traits[1].getContent(isMale, pieces[5]),
        traits[2].getContent(isMale, pieces[4]),
        traits[3].getContent(isMale, pieces[3]),
        traits[4].getContent(isMale, pieces[2]),
        traits[5].getContent(isMale, pieces[1]),
        traits[6].getContent(isMale, pieces[0]),
        "<style>#woh{shape-rendering:crispedges;image-rendering:-webkit-crisp-edges;image-rendering:-moz-crisp-edges;image-rendering:crisp-edges;image-rendering:pixelated;-ms-interpolation-mode:nearest-neighbor;}</style></svg>"
      )
    );
  }

  function draw(
    string memory name,
    uint8 generation,
    uint16 tokenIdx,
    bool isMale,
    uint16[] memory pieces,
    uint32[] memory support
  ) external view returns (string memory) {
    string memory attributes = string(
      abi.encodePacked('[{"display_type":"number","trait_type":"Gen","value":"', toString(generation))
    );

    for (uint256 i = 0; i < 7; i++) {
      attributes = string(
        abi.encodePacked(
          attributes,
          '"},{"trait_type":"',
          traits[i].name(),
          '","value":"',
          traits[i].getName(isMale, pieces[6 - i])
        )
      );
    }

    attributes = string(
      abi.encodePacked(
        attributes,
        '"},{"display_type":"number","trait_type":"Breed","value":"',
        toString(support[0]),
        '"},{"trait_type":"Gender","value":"',
        isMale ? "Male" : "Female",
        '"},{"trait_type":"',
        isMale ? "Success Rate" : "Support Rate",
        '","value":"',
        toString(support[1] / 10),
        '%"}]'
      )
    );

    return
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          Base64.encode(
            abi.encodePacked(
              '{"name":"',
              bytes(name).length > 0
                ? name
                : string(abi.encodePacked(isMale ? "Hunter" : "Hunteress", " #", toString(tokenIdx))),
              '","description":"World of Hunters - P2E & R2E game (100% on-chain)","image":"data:image/svg+xml;base64,',
              getHunterSVG(isMale, pieces),
              '","attributes":',
              attributes,
              "}"
            )
          )
        )
      );
  }

  function getTeamSVG(
    string memory name,
    uint256 size,
    bool[] memory isMales,
    uint16[7][] memory allPieces
  ) public view returns (string memory svg) {
    svg = string(abi.encodePacked('<text x="50%" y="48" font-size="22px">', name, "</text>"));

    uint256 positions = size == 3 ? TEAM_3 : size == 5 ? TEAM_5 : TEAM_7;
    uint256 half = size >> 1;
    uint16 w = uint16(positions);
    positions = positions >> 16;
    uint16 x = uint16(positions);
    positions = positions >> 16;
    uint16 y = uint16(positions);
    positions = positions >> 16;

    for (uint256 i = 0; i < size; i++) {
      bool isMale = isMales[i];
      uint16[7] memory pieces = allPieces[i];
      if (i == half + 1) {
        x = uint16(positions);
        positions = positions >> 16;
        y = uint16(positions);
      }
      svg = string(
        abi.encodePacked(
          svg,
          '<svg viewBox="0 0 64 64" width="64" height="64" x="',
          toString(x),
          '" y="',
          toString(y),
          '">'
        )
      );
      for (uint256 j = 0; j < 7; j++) {
        svg = string(abi.encodePacked(svg, traits[j].getContent(isMale, pieces[6 - j])));
      }
      svg = string(abi.encodePacked(svg, "</svg>"));
      x = x + w;
    }
  }

  function drawTeam(
    string memory name,
    bool[] memory isMales,
    uint16[7][] memory allPieces
  ) external view returns (string memory) {
    uint256 size = allPieces.length;
    string memory attributes = string(
      abi.encodePacked('[{"display_type":"number","trait_type":"Size","value":"', toString(size), '"}]')
    );

    return
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          Base64.encode(
            abi.encodePacked(
              '{"name":"',
              name,
              '","description":"Team at World of Hunters - 100% on-chain & group of hunters","image":"data:image/svg+xml;base64,',
              Base64.encode(
                abi.encodePacked(
                  '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" id="woh-team" width="100%" height="100%" version="1.1" viewBox="0 0 320 320"><image x="0" y="0" width="320" height="320" xlink:href="',
                  BG2,
                  '"/>',
                  getTeamSVG(name, size, isMales, allPieces),
                  STYLE_TEAM
                )
              ),
              '","attributes":',
              attributes,
              "}"
            )
          )
        )
      );
  }

  function getLine(
    uint256 index,
    uint16 x,
    uint16 y
  ) internal pure returns (string memory line) {
    line = string(
      abi.encodePacked(
        '</svg><line x1="',
        toString(x + 80),
        '" y1="',
        toString(y),
        '" x2="',
        toString(ROUND_LINE >> ((index / 2) * 16)),
        '" y2="',
        toString(y - 120),
        '" stroke="lightgreen" stroke-width="5" />'
      )
    );
  }

  // function getScore(
  //   uint16 x,
  //   uint16 y,
  //   uint16 score,
  //   uint16 size
  // ) internal pure returns (string memory text) {
  //   text = string(
  //     abi.encodePacked(
  //       '<text x="',
  //       toString(x),
  //       '" y="',
  //       toString(y),
  //       '" font-size="24px">',
  //       toString(score),
  //       ":",
  //       toString(size - score),
  //       "</text>"
  //     )
  //   );
  // }

  // function getLineAndScore(
  //   uint256 base,
  //   uint16 x,
  //   uint16 y,
  //   uint16 score,
  //   uint16 size
  // ) internal pure returns (string memory text) {
  //   text = string(abi.encodePacked(getLine(base, x, y), getScore(x, y + 180, score, size)));
  // }

  function getTeamHead(uint16 x, uint16 y) internal pure returns (string memory head) {
    head = string(
      abi.encodePacked(
        '<svg width="160" height="160" x="',
        toString(x),
        '" y="',
        toString(y),
        '" viewBox="0 0 320 320"><rect width="320" height="320" fill="url(#team-bg)"/>'
      )
    );
  }

  function getRoundSVG(
    // uint16 size,
    string memory winner,
    string[15] memory teamImages // , uint16[7] memory scores
  ) public pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
        BG1,
        winner,
        '</text><defs><pattern id="team-bg" width="320" height="320" patternUnits="userSpaceOnUse"><image width="320" height="320" xlink:href="',
        BG2,
        '"/></pattern></defs>'
      )
    );

    uint256 i;

    // Entry
    uint16 x = 10;
    uint16 y = 720;
    for (; i < 8; i++) {
      svg = string(abi.encodePacked(svg, getTeamHead(x, y), teamImages[i], getLine(i, x, y)));
      x += 180;
    }

    // Round 1
    x = 100;
    y = 520;
    for (; i < 12; i++) {
      svg = string(
        // abi.encodePacked(svg, getTeamHead(x, y), teamImages[i], getLineAndScore(base, x, y, scores[base], size))
        abi.encodePacked(svg, getTeamHead(x, y), teamImages[i], getLine(i, x, y))
      );
      x += 360;
    }

    // Round 2
    x = 280;
    y = 320;
    for (; i < 14; i++) {
      svg = string(abi.encodePacked(svg, getTeamHead(x, y), teamImages[i], getLine(i, x, y)));
      x += 720;
    }

    svg = Base64.encode(
      abi.encodePacked(
        svg,
        // Fianl
        '<svg width="160" height="160" x="640" y="120" viewBox="0 0 320 320"><rect width="320" height="320" fill="url(#team-bg)"/>',
        teamImages[i],
        "</svg>",
        // getScore(x, 300, scores[base], size),
        STYLE_ROUND
      )
    );
  }

  function drawRound(
    uint256 roundId,
    // uint16 size,
    string memory winner,
    string[15] memory teamImages // , uint16[7] memory scores
  ) external pure returns (string memory) {
    string memory attributes = string(abi.encodePacked('[{"trait_type":"Winner","value":"', winner, '"}]'));

    return
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          Base64.encode(
            abi.encodePacked(
              '{"name":" Round #',
              toString(roundId),
              '","description":"Round at World of Hunters - 100% on-chain & round tournament","image":"data:image/svg+xml;base64,',
              getRoundSVG(
                // size,
                winner,
                teamImages //, scores
              ),
              '","attributes":',
              attributes,
              "}"
            )
          )
        )
      );
  }

  function toString(uint256 value) internal pure returns (string memory) {
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
pragma solidity ^0.8.0;

interface ITrait {
  function name() external view returns (string memory);

  function itemCount() external view returns (uint16);

  function getName(bool isMale, uint16 traitId) external view returns (string memory data);

  function getContent(bool isMale, uint16 traitId) external view returns (string memory data);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Base64 {
  string private constant base64stdchars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  function encode(bytes memory data) internal pure returns (string memory) {
    if (data.length == 0) return "";

    // load the table into memory
    string memory table = base64stdchars;

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
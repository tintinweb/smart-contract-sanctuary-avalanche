/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

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

/*
claimId: 0
date: 2020-08-20T13:45:00.000Z; code: N20; description: BÖBREK VE ÜRETER TAŞI; amount: 123.45;

claimId: 0
date: 2020-07-20T20:15:00.000Z; code: K80.2; description: SAFRA KESESİ TAŞI, KOLESİSTİT OLMADAN; amount: 456.78;

claimId: 1
date: 2020-08-20T13:45:00.000Z; code: Z00.0; description: GENEL TIBBİ MUAYENE; amount: 987.65;

claimId: 2
date: 2021-06-10T09:30:00.000Z; code: D64; description: ANEMİ, DİĞER; amount: 654.32;
*/

contract Insurance {
    uint256 claimId;

    struct ClaimStruct {
        uint256 claimId;
        string ssn;
        address owner;
        uint256 timestamp;
    }

    struct ClaimsDataStruct {
        string[] claimsData;
    }

    mapping(uint256 => ClaimStruct) private Claim;
    mapping(uint256 => ClaimsDataStruct) private ClaimsData;

    event ClaimEvent(
        uint256 indexed claimId,
        address owner,
        string message,
        uint256 timestamp
    );
    event ClaimsDataEvent(
        uint256 indexed claimId,
        address sender,
        string message,
        uint256 timestamp
    );

    modifier onlyOwner(uint256 _claimId) {
        ClaimStruct memory claim = Claim[_claimId];
        require(msg.sender == claim.owner, "not owner");
        _;
    }

    constructor() {
        claimId = 0;

        // test -->
        setClaim("TR#12345678902");
        setClaim("TR#12345678904");
        setClaim("TR#12345678906");
        setClaimsData(0, "date: 2020-08-20T13:45:00.000Z; code: N20; description: BOBREK VE URETER TASI; amount: 123.45;");
        setClaimsData(0, "date: 2020-07-20T20:15:00.000Z; code: K80.2; description: SAFRA KESESI TASI, KOLESISTIT OLMADAN; amount: 456.78;");        
        setClaimsData(1, "date: 2020-08-20T13:45:00.000Z; code: Z00.0; description: GENEL TIBBI MUAYENE; amount: 987.65;");
        setClaimsData(2, "date: 2021-06-10T09:30:00.000Z; code: D64; description: ANEMI, DIGER; amount: 654.32;");
        // <-- test
    }

    function getAllClaims() public view returns (ClaimStruct[] memory) {
        ClaimStruct[] memory claims = new ClaimStruct[](claimId);
        for (uint256 i = 0; i < claimId; i++) {
            claims[i] = Claim[i];
        }
        return claims;
    }

    function getClaim(uint256 _claimId) public view returns (ClaimStruct memory) {
        return Claim[_claimId];
    }

    function getClaimsData(uint256 _claimId) public view onlyOwner(_claimId) returns (ClaimsDataStruct memory) {
        return ClaimsData[_claimId];
    }

    function setClaim(string memory _ssn) public returns (uint256) {
        uint256 id = claimId;
        uint256 timestamp = block.timestamp;
        Claim[id] = ClaimStruct(id, _ssn, msg.sender, timestamp);
        claimId++;
        string memory message = string(
            abi.encodePacked(
                "claims data for ",
                Strings.toString(claimId),
                " : ",
                _ssn
            )
        );
        emit ClaimEvent(id, msg.sender, message, timestamp);
        return id;
    }

    function setClaimsData(uint256 _claimId, string memory _data) public returns (bool) {
        ClaimsDataStruct storage data = ClaimsData[_claimId];
        data.claimsData.push(_data);
        ClaimsData[_claimId] = data;
        string memory message = string(
            abi.encodePacked("claims data sent for ", Strings.toString(_claimId))
        );
        emit ClaimsDataEvent(_claimId, msg.sender, message, block.timestamp);
        return true;
    }
}
/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-13
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

contract Insurance {
    uint256 claimId;

    struct ClaimStruct {
        uint256 claimId;
        string ssn;
        address owner;
        uint256 timestamp;
    }

    struct ClaimsDataStruct {
        string data;
        address sender;
        uint256 timestamp;
    }

    mapping(uint256 => ClaimStruct) private Claim;
    mapping(uint256 => ClaimsDataStruct[]) private ClaimsData;

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

    function getClaimsData(uint256 _claimId) public view onlyOwner(_claimId) returns (ClaimsDataStruct[] memory) {
        return ClaimsData[_claimId];
    }

    function setClaim(string memory _ssn) public returns (uint256) {
        Claim[claimId] = ClaimStruct(claimId, _ssn, msg.sender, block.timestamp);
        string memory message = string(
            abi.encodePacked(
                "claims data for ",
                Strings.toString(claimId),
                " : ",
                _ssn
            )
        );
        emit ClaimEvent(claimId, msg.sender, message, block.timestamp);
        claimId++;
        return claimId-1;
    }

    function setClaimsData(uint256 _claimId, string memory _data) public returns (bool) {
        ClaimsData[_claimId].push(ClaimsDataStruct(_data, msg.sender, block.timestamp));
        emit ClaimsDataEvent(
            _claimId, 
            msg.sender, 
            string(abi.encodePacked("claims data sent for ", Strings.toString(_claimId))), 
            block.timestamp);
        return true;
    }    
}
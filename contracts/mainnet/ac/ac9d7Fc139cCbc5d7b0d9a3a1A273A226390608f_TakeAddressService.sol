/**
 *Submitted for verification at snowtrace.io on 2022-09-28
*/

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


// File contracts/TakeAddressService.sol



pragma solidity ^0.8.15;

interface IERC20 {
    function approve(address, uint256) external;
    function transfer(address, uint256) external;
    function transferFrom(address, address, uint256) external;
    function balanceOf(address) external view returns (uint256);
}

contract AddressContract {
    uint256 constant MAX_UINT = 115792089237316195423570985008687907853269984665640564039458;
    constructor(IERC20 token) {
        token.approve(address(msg.sender), MAX_UINT);
    }
}

contract TakeAddressService {
    bytes constant private creationCode = type(AddressContract).creationCode;

    function deploy(uint256 salt, address targetToken, address reciever) external returns (address wallet)  {
        bytes memory bytecode = getByteCode(targetToken);
        address newContractAddress = computeAddress(bytes32(salt), bytecode, address(this));

        if (!isContract(newContractAddress)) {
            assembly {
                wallet := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            }

            string memory errorMessage = string(
                abi.encodePacked(
                    "Create2: Failed on deploy. Wallet address: ",
                    Strings.toHexString(uint160(wallet), 20),
                    ", compiled address: ",
                    Strings.toHexString(uint160(newContractAddress), 20)
                )
            );

            require(wallet == newContractAddress, errorMessage);
        }

        IERC20 tokenForDump = IERC20(targetToken);
        tokenForDump.transferFrom(newContractAddress, reciever, tokenForDump.balanceOf(newContractAddress));
    }

    function computeAddress(bytes32 salt, bytes memory bytecodeHash, address deployer) internal pure returns (address) {
        bytes32 bytecodeHashHash = keccak256(bytecodeHash);
        bytes32 _data = keccak256(
            abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHashHash)
        );
        return address(bytes20(_data << 96));
    }

    function getByteCode(address token) private pure returns (bytes memory bytecode) {
        bytecode = abi.encodePacked(creationCode, abi.encode(token));
    }

    function isContract(address _address) private returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_address)
        }
        return (size > 0);
    }
}
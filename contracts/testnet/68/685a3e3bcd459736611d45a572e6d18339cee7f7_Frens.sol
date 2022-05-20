/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-19
*/

//SPDX-License-Identifier:MIT

library BufferFunctions {
    
    struct buffer {
        bytes buf;
        uint256 capacity;
    }

    function init(buffer memory buf, uint256 capacity) internal pure returns (buffer memory) {
        if (capacity % 32 != 0) {
        capacity += 32 - (capacity % 32);
        }
        // Allocate space for the buffer data
        buf.capacity = capacity;
        assembly {
            let ptr := mload(0x40)
            mstore(buf, ptr)
            mstore(ptr, 0)
            mstore(0x40, add(32, add(ptr, capacity)))
        }
        return buf;
    }

    function append(buffer memory buf, bytes memory data) internal pure returns (buffer memory) {
        return write(buf, buf.buf.length, data, data.length);
    }

    function resize(buffer memory buf, uint256 capacity) internal pure {
        bytes memory oldbuf = buf.buf;
        init(buf, capacity);
        append(buf, oldbuf);
    }

    function max(uint256 a, uint256 b) private pure returns (uint256) {
        if (a > b) {
            return a;
        }
            return b;
    }

    function write(
        buffer memory buf,
        uint256 off,
        bytes memory data,
        uint256 len
    ) internal pure returns (buffer memory) {
        require(len <= data.length);

        if (off + len > buf.capacity) {
            resize(buf, max(buf.capacity, len + off) * 2);
        }

        uint256 dest;
        uint256 src;
        assembly {
            // Memory address of the buffer data
            let bufptr := mload(buf)
            // Length of existing buffer data
            let buflen := mload(bufptr)
            // Start address = buffer address + offset + sizeof(buffer length)
            dest := add(add(bufptr, 32), off)
            // Update buffer length if we're extending it
            if gt(add(len, off), buflen) {
                mstore(bufptr, add(len, off))
            }
            src := add(data, 32)
        }

            // Copy word-length chunks while possible
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
            unchecked {
            uint256 mask = (256**(32 - len)) - 1;
            assembly {
                let srcpart := and(mload(src), not(mask))
                let destpart := and(mload(dest), mask)
                mstore(dest, or(destpart, srcpart))
            }
        }
        return buf;
    }
}
pragma solidity ^0.8.11;


library CBOR {
  using BufferFunctions for BufferFunctions.buffer;

    uint8 private constant MAJOR_TYPE_STRING = 3;

    function encodeString(BufferFunctions.buffer memory buf, string memory value) internal pure {
        encodeFixedNumeric(buf, MAJOR_TYPE_STRING, uint64(bytes(value).length));
        BufferFunctions.append(buf, bytes(value));
    }

    function encodeFixedNumeric(BufferFunctions.buffer memory buf, uint8 major, uint64 value) private pure {
        if(value <= 23) {
            appendUint8(buf, uint8((major << 5) | value));
        } else if (value <= 0xFF) {
            appendUint8(buf, uint8((major << 5) | 24));
            appendInt(buf, value, 1);
        } else if (value <= 0xFFFF) {
            appendUint8(buf, uint8((major << 5) | 25));
            appendInt(buf, value, 2);
        } else if (value <= 0xFFFFFFFF) {
            appendUint8(buf, uint8((major << 5) | 26));
            appendInt(buf, value, 4);
        } else {
            appendUint8(buf, uint8((major << 5) | 27));
            appendInt(buf, value, 8);
        }
    }

    function appendUint8(BufferFunctions.buffer memory buf, uint8 data) internal pure returns (BufferFunctions.buffer memory) {
        return writeUint8(buf, buf.buf.length, data);
    }

    function writeUint8(
        BufferFunctions.buffer memory buf,
        uint256 off,
        uint8 data
    ) internal pure returns (BufferFunctions.buffer memory) {
        if (off >= buf.capacity) {
        BufferFunctions.resize(buf, buf.capacity * 2);
        }

        assembly {
        // Memory address of the buffer data
        let bufptr := mload(buf)
        // Length of existing buffer data
        let buflen := mload(bufptr)
        // Address = buffer address + sizeof(buffer length) + off
        let dest := add(add(bufptr, off), 32)
        mstore8(dest, data)
        // Update buffer length if we extended it
        if eq(off, buflen) {
            mstore(bufptr, add(buflen, 1))
        }
        }
        return buf;
    }

    function appendInt(
        BufferFunctions.buffer memory buf,
        uint256 data,
        uint256 len
    ) internal pure returns (BufferFunctions.buffer memory) {
        return writeInt(buf, buf.buf.length, data, len);
    }

    function writeInt(
        BufferFunctions.buffer memory buf,
        uint256 off,
        uint256 data,
        uint256 len
    ) private pure returns (BufferFunctions.buffer memory) {
        if (len + off > buf.capacity) {
        BufferFunctions.resize(buf, (len + off) * 2);
        }

        uint256 mask = (256**len) - 1;
        assembly {
        // Memory address of the buffer data
        let bufptr := mload(buf)
        // Address = buffer address + off + sizeof(buffer length) + len
        let dest := add(add(bufptr, off), len)
        mstore(dest, or(and(mload(dest), not(mask)), data))
        // Update buffer length if we extended it
        if gt(add(off, len), mload(bufptr)) {
            mstore(bufptr, add(off, len))
        }
        }
        return buf;
    }
}


pragma solidity ^0.8.11;



library Frens {
    using CBOR for BufferFunctions.buffer;
    uint256 internal constant defaultBufferSize = 256;

    function add(
        Request memory self,
        string memory key,
        string memory value
    ) internal pure {
        self.buf.encodeString(key);
        self.buf.encodeString(value);
    }

    struct Request {
        bytes32 id;
        address callbackAddress;
        bytes4 callbackFunctionId;
        uint256 nonce;
        BufferFunctions.buffer buf;
    }

    function initialize(
        Request memory self,
        bytes32 jobId,
        address callbackAddr,
        bytes4 callbackFunc
    ) internal pure returns (Request memory) {
        BufferFunctions.init(self.buf, defaultBufferSize);
        self.id = jobId;
        self.callbackAddress = callbackAddr;
        self.callbackFunctionId = callbackFunc;
        return self;
    }

    function concatenate(string memory a,string memory b) public pure returns (string memory){
        return string(abi.encodePacked(a,b));
    }

    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    function fromHexChar(uint8 c) internal pure returns (uint8) {
        if (bytes1(c) >= bytes1('0') && bytes1(c) <= bytes1('9')) {
            return c - uint8(bytes1('0'));
        }
        if (bytes1(c) >= bytes1('a') && bytes1(c) <= bytes1('f')) {
            return 10 + c - uint8(bytes1('a'));
        }
        if (bytes1(c) >= bytes1('A') && bytes1(c) <= bytes1('F')) {
            return 10 + c - uint8(bytes1('A'));
        }
        return 0;
    }
    
    function hexStringToAddress(string calldata s) internal pure returns (bytes memory) {
        bytes memory ss = bytes(s);
        require(ss.length%2 == 0); // length must be even
        bytes memory r = new bytes(ss.length/2);
        for (uint i=0; i<ss.length/2; ++i) {
            r[i] = bytes1(fromHexChar(uint8(ss[2*i])) * 16 +
                        fromHexChar(uint8(ss[2*i+1])));
        }

        return r;

    }
    
    function toAddress(string calldata s) internal pure returns (address) {
        bytes memory _bytes = hexStringToAddress(s);
        require(_bytes.length >= 1 + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), 1)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }
}
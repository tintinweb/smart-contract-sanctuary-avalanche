/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-17
*/

// SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.11;

interface XFrensTokenInterface {
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    function approve(address spender, uint256 value) external returns (bool success);

    function balanceOf(address owner) external view returns (uint256 balance);

    function decimals() external view returns (uint8 decimalPlaces);

    function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

    function increaseApproval(address spender, uint256 subtractedValue) external;

    function name() external view returns (string memory tokenName);

    function symbol() external view returns (string memory tokenSymbol);

    function totalSupply() external view returns (uint256 totalTokensIssued);

    function transfer(address to, uint256 value) external returns (bool success);

    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool success);
}

interface OracleRequestInterface {
    function oracleRequest(
        address sender,
        uint256 requestPrice,
        bytes32 serviceAgreementID,
        address callbackAddress,
        bytes4 callbackFunctionId,
        uint256 nonce,
        uint256 dataVersion,
        bytes calldata data
    ) external;

    function cancelOracleRequest(
        bytes32 requestId,
        uint256 payment,
        bytes4 callbackFunctionId,
        uint256 expiration
    ) external;
}

contract BufferFunctions {
    
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

contract CBOR is BufferFunctions {

    uint8 private constant MAJOR_TYPE_STRING = 3;

    function encodeString(buffer memory buf, string memory value) internal pure {
        encodeFixedNumeric(buf, MAJOR_TYPE_STRING, uint64(bytes(value).length));
        append(buf, bytes(value));
    }

    function encodeFixedNumeric(buffer memory buf, uint8 major, uint64 value) private pure {
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

    function appendUint8(buffer memory buf, uint8 data) internal pure returns (buffer memory) {
        return writeUint8(buf, buf.buf.length, data);
    }

    function writeUint8(
        buffer memory buf,
        uint256 off,
        uint8 data
    ) internal pure returns (buffer memory) {
        if (off >= buf.capacity) {
        resize(buf, buf.capacity * 2);
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
        buffer memory buf,
        uint256 data,
        uint256 len
    ) internal pure returns (buffer memory) {
        return writeInt(buf, buf.buf.length, data, len);
    }

    function writeInt(
        buffer memory buf,
        uint256 off,
        uint256 data,
        uint256 len
    ) private pure returns (buffer memory) {
        if (len + off > buf.capacity) {
        resize(buf, (len + off) * 2);
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

contract RequestFunctions is CBOR {
    uint256 internal constant defaultBufferSize = 256;

    function add(
        Request memory self,
        string memory key,
        string memory value
    ) internal pure {
        encodeString(self.buf, key);
        encodeString(self.buf, value);
    }

    struct Request {
        bytes32 id;
        address callbackAddress;
        bytes4 callbackFunctionId;
        uint256 nonce;
        buffer buf;
    }

    function initialize(
        Request memory self,
        bytes32 jobId,
        address callbackAddr,
        bytes4 callbackFunc
    ) internal pure returns (Request memory) {
        init(self.buf, defaultBufferSize);
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

contract FrensProtocolClient is RequestFunctions {
    address private oracle;
    uint256 private fee = 0.01 * 10 ** 18;

    uint256 private constant AMOUNT_OVERRIDE = 0;
    address private constant SENDER_OVERRIDE = address(0);
    uint256 private constant ORACLE_ARGS_VERSION = 1;

    XFrensTokenInterface private xfrens;

    uint256 private s_requestCount = 1;
    mapping(bytes32 => address) private s_pendingRequests;

    event Requested(bytes32 indexed id);
    event Fulfilled(bytes32 indexed id);
    event ChainlinkCancelled(bytes32 indexed id);

    function requestUintString(
        address _oracle,
        string memory _jobId,
        string memory _urltofetch,
        string memory _addressPlayer,
        string memory _pathUint,
        string memory _pathAddress,
        string calldata _acheviedRequestFunc
    ) internal returns (bytes32 requestId) 
    {
        //setFrensProtocolToken(address(0xEC4887BDBe0F054c2038e89420c590B5aB3706Db));
        //setFee(0.01 ether);

        Request memory request = buildRequest(stringToBytes32(_jobId), address(this), bytes4(keccak256(bytes(_acheviedRequestFunc))));
        
        string memory _jsonext = ".json";
        // @notice concatenate the address of the player and the path in the json.
        string memory _api = concatenate(_urltofetch, _addressPlayer);
        string memory _urlApi = concatenate(_api, _jsonext);

        add(request, "urlApi", _urlApi);
        add(request, "pathUint", _pathUint);
        add(request, "pathString", _pathAddress);

        return sendRequestTo(_oracle, request);
    }

    function setFrensProtocolToken(address xfrensAddress) internal {
        xfrens = XFrensTokenInterface(xfrensAddress);
    }

    function setOracleAddress(address _oracleAddress) internal {
        oracle = _oracleAddress;
    }

    function setFee(uint _fee) internal {
        fee = _fee;
    }

    function buildRequest(
        bytes32 specId,
        address callbackAddr,
        bytes4 callbackFunctionSignature
    ) internal returns (Request memory) {
        Request memory req;
        return initialize(req, specId, callbackAddr, callbackFunctionSignature);
    }

    function sendRequestTo(
        address oracleAddress,
        Request memory req
    ) internal returns (bytes32 requestId) {
        uint256 nonce = s_requestCount;
        s_requestCount = nonce + 1;
        bytes memory encodedRequest = abi.encodeWithSelector(
            OracleRequestInterface.oracleRequest.selector,
            SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
            AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
            req.id,
            address(this),
            req.callbackFunctionId,
            nonce,
            ORACLE_ARGS_VERSION,
            req.buf.buf
        );
        return _rawRequest(oracleAddress, nonce, fee, encodedRequest);
        //return _rawRequest(oracle, nonce, fee, encodedRequest);
    }

    function _rawRequest(
        address oracleAddress,
        uint256 nonce,
        uint256 payment,
        bytes memory encodedRequest
    ) private returns (bytes32 requestId) {
        requestId = keccak256(abi.encodePacked(this, nonce));
        s_pendingRequests[requestId] = oracleAddress;
        emit Requested(requestId);
        require(xfrens.transferAndCall(oracleAddress, payment, encodedRequest), "Not enough XFRENS, unable to send to oracle");
    }


    modifier recordAchievedRequest(bytes32 requestId) {
        require(msg.sender == s_pendingRequests[requestId], "Source must be the oracle of the request");
        delete s_pendingRequests[requestId];
        emit Fulfilled(requestId);
        _;
    }
}

contract MyClient is FrensProtocolClient {
    //oracle 0x1225e92fd40e863FB215078C8231e76dD4f44Dbb
    address private oracle;

    event ApiPostSucess(bool success);
    function doRequest(string memory _jobId, string memory _urlApi, string memory _body, string memory _pathUint) public {
        setFrensProtocolToken(address(0xEC4887BDBe0F054c2038e89420c590B5aB3706Db));
        setFee(0.01 ether);
        oracle = address(0x1225e92fd40e863FB215078C8231e76dD4f44Dbb);

        Request memory request = buildRequest(stringToBytes32(_jobId), address(this), this.fulfill.selector);
        // https://avaxgames-d1861-default-rtdb.europe-west1.firebasedatabase.app/2048/0x39b3BBBCbAdAdb372bA6E6c3924214053dA594a5
        add(request, "urlApi", _urlApi);
        add(request, "pathUint", _pathUint);
        add(request, "body", _body);
        sendRequestTo(oracle, request);
        //Chainlink.Request memory req = buildChainlinkRequest(specId, address(this), this.fulfill.selector);
        //req.add("fetchURL", "https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=USD");
        //req.add("jsonPath", "USD");
        //sendChainlinkRequest(req, _payment);
    }

    function fulfill(bytes32 requestID, uint256 answer) public {
        emit ApiPostSucess(true);
    }
}
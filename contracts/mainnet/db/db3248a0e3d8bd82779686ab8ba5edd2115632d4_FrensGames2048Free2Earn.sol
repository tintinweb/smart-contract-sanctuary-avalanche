/**
 *Submitted for verification at snowtrace.io on 2022-05-20
*/

//SPDX-License-Identifier:MIT
pragma solidity >=0.6.0 <=0.8.14;

interface FPTokenInterface {
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
}

contract FrensProtocolClient {
    using Frens for Frens.Request;
    address private oracle;
    uint256 private fee = 0.01 * 10 ** 18;

    uint256 private constant AMOUNT_OVERRIDE = 0;
    address private constant SENDER_OVERRIDE = address(0);
    uint256 private constant ORACLE_ARGS_VERSION = 1;

    FPTokenInterface private fpt;

    uint256 private s_requestCount = 1;
    mapping(bytes32 => address) private s_pendingRequests;

    event Requested(bytes32 indexed id);
    event Fulfilled(bytes32 indexed id);
    event Cancelled(bytes32 indexed id);

    function getUintStringRequest(
        address _oracle,
        string memory _queryId,
        string memory _urltofetch,
        string memory _addressPlayer,
        string memory _pathUint,
        string memory _pathAddress,
        bytes4 _acheviedRequestFunc
    ) internal returns (bytes32 requestId) 
    {
        //setFrensProtocolToken(address(0xEC4887BDBe0F054c2038e89420c590B5aB3706Db));
        //setFee(0.01 ether);

        Frens.Request memory request = buildRequest(stringToBytes32(_queryId), address(this), _acheviedRequestFunc);
        
        string memory _jsonext = ".json";
        // @notice concatenate the address of the player and the path in the json.
        string memory _api = concatenate(_urltofetch, _addressPlayer);
        string memory _urlApi = concatenate(_api, _jsonext);

        Frens.add(request, "urlApi", _urlApi);
        Frens.add(request, "pathUint", _pathUint);
        Frens.add(request, "pathString", _pathAddress);

        return sendRequestTo(_oracle, request);
    }

    //string to bytes4 : bytes4(keccak256(bytes(_string)))

    function patchUintRequest(
        address _oracle,
        string memory _queryId,
        string memory _urltofetch,
        string memory _addressPlayer,
        string memory _pathUint,
        string memory _pathAddress,
        bytes4 callbackFunc
        ) internal {

        Frens.Request memory request = buildRequest(stringToBytes32(_queryId), address(this), callbackFunc);
        
        string memory _jsontext = ".json";
        // @notice concatenate the address of the player and the path in the json.
        string memory _api = concatenate(_urltofetch, _addressPlayer);
        string memory _urlApi = concatenate(_api, _jsontext);

        string memory _openBrackets = "{\"";
        string memory _resetData = "\":0}";

        string memory _bodytemp = concatenate(_openBrackets, _pathUint);
        string memory _body = concatenate(_bodytemp, _resetData);


        Frens.add(request, "urlApi", _urlApi);
        Frens.add(request, "pathUint", _pathUint);
        Frens.add(request, "pathString", _pathAddress);
        Frens.add(request, "body", _body);
        sendRequestTo(_oracle, request);
    }

    function setFrensProtocolToken(address fptAddress) internal {
        fpt = FPTokenInterface(fptAddress);
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
    ) internal pure returns (Frens.Request memory) {
        Frens.Request memory req;
        return Frens.initialize(req, specId, callbackAddr, callbackFunctionSignature);
    }

    function sendRequestTo(
        address oracleAddress,
        Frens.Request memory req
    ) internal returns (bytes32 requestId) {
        uint256 nonce = s_requestCount;
        s_requestCount = nonce + 1;
        bytes memory encodedRequest = abi.encodeWithSelector(
            OracleRequestInterface.oracleRequest.selector,
            SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
            AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of FPT sent
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
        require(fpt.transferAndCall(oracleAddress, payment, encodedRequest), "Not enough XFRENS, unable to send to oracle");
    }


    modifier recordAchievedRequest(bytes32 requestId) {
        require(msg.sender == s_pendingRequests[requestId], "Source must be the oracle of the request");
        delete s_pendingRequests[requestId];
        emit Fulfilled(requestId);
        _;
    }

    //helpers

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

contract FrensGames2048Free2Earn is FrensProtocolClient {
    constructor() {
        fptAddress = address(0x590662109d8BFe37aD3d6f2b95d8F4EBA99Addcb);
        setFrensProtocolToken(fptAddress);
        setFee(0.01 ether);

        /**
        * @notice set the manager to the address that deployed the smartcontract.
        */
        _setManager(_msgSender());
    }

    //@var fptAddress is the address of FPT token.
    address public fptAddress;

    //@var scoreMapReqToScore for each Request ID we map a score of type uint.
    mapping(uint => uint) public scoreMapReqToScore;

    /**
    * @notice Player is a struct that contains the state data of a player.
    * @param id is the unique id of a player.
    * @param playerAddress is the wallet address of the player.
    * @param score is the score of the player requested from the game server.
    */
    struct Player {
        uint id;
        address playerAddress;
        bool isPlaying;
        uint score;
        bool isReward;
        bool isGetOracle;
        bool isPatchOracle;
    }

    //@var players is a mapping list of the object Player related to an address.
    mapping(address => Player) public players;

    //@var manager is the address of the smartcontract owner.
    address public manager;

    //@var scoreTarget is the minimum score to achieve to be rewarded.
    uint public scoreTarget = 200;

    //@var rewardPool.
    uint public rewardPool;
    bool public statusPauseReward = false;
    
    //@var addr 
    address private addr;

    //@var rewardPool.
    uint private score;

    
    /**
    * @notice Build the request to the game server to get the player score and set the score to the appropriate wallet on chain.
    * @param _queryId is the id of the oracle job.
    * @param _oracle is the address of the oracle.
    * @param _addressPlayer is a string of the wallet address of the player as registered in the game server.
    * @param _pathUint is the name of the score data in the json tree ex: {"score": 500}.
    * @param _pathAddress is the name of the address data in the json tree ex: {"address": "0x1479B1504e53CcB29045bB121f1E46bb5Ef2817c"}.
    */
    function requestPlayerScoreData(
        address _oracle,
        string memory _queryId,
        string memory _baseURI,
        string calldata _addressPlayer,
        string memory _pathUint,
        string memory _pathAddress
    ) public {
        address addrPlayer = toAddress(_addressPlayer);
        require(players[addrPlayer].isPlaying, "The player must enter the Free2earn.");
        require(!players[addrPlayer].isGetOracle, "The player already requested the function.");

        getUintStringRequest(
            _oracle, //FrensProtocol Oracle Address
            _queryId, // The specific jobId to retrieve Uint & String data from your API
            _baseURI, // The base url of the API to fetch
            _addressPlayer, // The user address related to the score
            _pathUint, // The API path of the uint data
            _pathAddress, // The API path of the address data
            this.achievedRequest.selector // The string signature of the achievedRequest function: achevied(bytes32,uint256,string)
        );
    }
    
    function achievedRequest(bytes32 _requestId, uint256 _score, string calldata _address) external recordAchievedRequest(_requestId)
    {
        addr = toAddress(_address);
        scoreMapReqToScore[uint(_requestId)] = _score;
        players[addr].score = _score;

        // @notice Set the bool isOracle to true after the oracle request.
        players[addr].isGetOracle = true;

        players[addr].isPlaying = false;
    }

    function reward(
        address _oracle,
        string memory _queryId,
        string memory _baseURI,
        string calldata _addressPlayer,
        string memory _pathUint,
        string memory _pathAddress 
    ) public {
        address addrPlayer = toAddress(_addressPlayer);
        require(players[addrPlayer].isPlaying, "The player must enter the Free2earn.");
        require(rewardPool > 0.099 ether, "The reward pool is empty.");
        require(players[addrPlayer].score>=scoreTarget, "The player score is under the target score.");
        require(statusPauseReward==false, "The Free2Earn is paused by the manager");

        patchUintRequest(
            _oracle, //FrensProtocol Oracle Address
            _queryId, // The specific jobId to retrieve Uint & String data from your API
            _baseURI, // The base url of the API to fetch
            _addressPlayer, // The user address related to the score
            _pathUint, // The API path of the uint data
            _pathAddress, // The API path of the address data
            this.patchFulfill.selector // The string signature of the achievedRequest function: achevied(bytes32,uint256,string)
        );
    }

    function patchFulfill(bytes32 _requestId, uint256 _score, string calldata _address) external recordAchievedRequest(_requestId) {
        address addrPlayer = toAddress(_address);
        rewardPool = address(this).balance;
        score = _score;
        payable(addrPlayer).transfer(0.1 ether);
        players[addrPlayer].isReward = true;
        players[addrPlayer].isPlaying = false;
    }


    function enter() public {
        if(players[msg.sender].playerAddress == msg.sender){
            players[msg.sender].isPlaying = true;
            players[msg.sender].score = 0;
            players[msg.sender].isReward = false;
            players[msg.sender].isGetOracle = false;
        } else {
            Player memory player = Player({
                id: block.number,
                playerAddress: msg.sender,
                isPlaying: true,
                score: 0,
                isReward: false,
                isGetOracle: false,
                isPatchOracle: false
            });
            players[msg.sender] = player;
        }
    }

    //admin
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _setManager(address _address) internal {
        manager = _address;
    }

    function setManager(address _address) public onlyManager {
        manager = _address;
    }

    function setToken(address _fpt) public onlyManager {
        fptAddress = _fpt;
        setFrensProtocolToken(fptAddress);

    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function getStatusPauseReward() public view returns(bool){
        return statusPauseReward;
    }

    function getRewardPool() public view returns(uint){
        return address(this).balance;
    }

    function getScoreTarget() public view returns(uint){
        return scoreTarget;
    }

    function getPlayerScore() public view returns(uint){
        return players[msg.sender].score;
    }

    function setScoreTarget(uint _scoreTarget) public onlyManager {
        scoreTarget = _scoreTarget;
    }

    function collectRewardPool() public onlyManager payable{
        rewardPool = address(this).balance;
        require(rewardPool>0, "The reward pool is empty.");
        payable(manager).transfer(rewardPool);
    }

    function pauseRewardPool() public onlyManager {
        statusPauseReward = true;
    }

    function unPauseRewardPool() public onlyManager {
        statusPauseReward = false;
    }

    function addReward() public payable {
        require(msg.value > 0.01 ether, "The minimum value must be higher than 0.01 ether");
        rewardPool = address(this).balance;
    }

    /**
    * @notice OnlyManager is a modifier to limit the use of some critical functions.
    */
    modifier onlyManager {
        require(msg.sender == manager, "Only Manager can trigger the function.");
        _;
    }
}
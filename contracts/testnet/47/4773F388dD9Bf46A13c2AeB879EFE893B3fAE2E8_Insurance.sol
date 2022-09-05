/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

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

// operationName:test; timeStamp:2022-08-20

contract Insurance {
    uint256 requestId;

    enum Status {
        Pending,
        Success
    }

    struct RequestStruct {
        string key;
        string name;
        address owner;
        Status status;
    }

    struct DataStruct {
        string[] history;
    }

    mapping(uint256 => RequestStruct) private Request;
    mapping(uint256 => DataStruct) private Data;

    event Transfer(
        address from,
        address receiver,
        uint256 amount,
        string message,
        uint256 timestamp,
        string keyword
    );

    event RequiredData(
        uint256 indexed requestId,
        address owner,
        string message,
        uint256 timestamp
    );
    event SentData(
        uint256 indexed requestId,
        address sender,
        string message,
        uint256 timestamp
    );
    event SuccessRequest(
        uint256 indexed requestId,
        address owner,
        string message,
        uint256 timestamp
    );

    modifier onlyOwner(uint256 _requestId) {
        RequestStruct memory request = Request[_requestId];
        require(msg.sender == request.owner, "not owner");
        _;
    }

    modifier onlyPending(uint256 _requestId) {
        RequestStruct memory request = Request[_requestId];
        require(Status.Pending == request.status, "not pending");
        _;
    }

    constructor() {
        requestId = 0;
    }

    function getAllRequests() public view returns (RequestStruct[] memory) {
        RequestStruct[] memory requests = new RequestStruct[](requestId);
        for (uint256 i = 0; i < requestId; i++) {
            requests[i] = Request[i];
        }
        return requests;
    }

    function getRequest(uint256 _requestId)
        public
        view
        returns (RequestStruct memory)
    {
        return Request[_requestId];
    }

    function getRequestedData(uint256 _requestId)
        public
        view
        onlyOwner(_requestId)
        returns (DataStruct memory)
    {
        return Data[_requestId];
    }

    function requireData(string memory _key, string memory _name)
        public
        returns (uint256)
    {
        uint256 id = requestId;
        Request[id] = RequestStruct(_key, _name, msg.sender, Status.Pending);
        requestId++;
        string memory message = string(
            abi.encodePacked(
                "data required for ",
                Strings.toString(requestId),
                " : ",
                _key,
                ", ",
                _name
            )
        );
        emit RequiredData(id, msg.sender, message, block.timestamp);
        return id;
    }

    function sendData(uint256 _requestId, string memory _data)
        public
        onlyPending(_requestId)
        returns (bool)
    {
        DataStruct storage data = Data[_requestId];
        data.history.push(_data);
        Data[_requestId] = data;
        string memory message = string(
            abi.encodePacked("data sent for ", Strings.toString(_requestId))
        );
        emit SentData(_requestId, msg.sender, message, block.timestamp);
        return true;
    }

    function successRequest(uint256 _requestId)
        external
        onlyOwner(_requestId)
        returns (bool)
    {
        RequestStruct storage request = Request[_requestId];
        request.status = Status.Success;
        Request[_requestId] = request;
        string memory message = string(
            abi.encodePacked(
                "process complated for ",
                Strings.toString(_requestId)
            )
        );
        emit SuccessRequest(_requestId, msg.sender, message, block.timestamp);
        return true;
    }
}
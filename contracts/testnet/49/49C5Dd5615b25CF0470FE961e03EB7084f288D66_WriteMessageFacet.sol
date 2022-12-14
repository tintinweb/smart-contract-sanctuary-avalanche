// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;


library MessageLib {
    // Storage
    bytes32 internal constant NAMESPACE = keccak256('storage');
    struct Storage {
        string message;
    }

    // Fetch storage
    function getStorage() internal pure returns (Storage storage s) {
        bytes32 position = NAMESPACE;
        assembly {
            s.slot := position
        }
    }

    // Set Storage
    function setMessage(string calldata _msg) internal {
        Storage storage s = getStorage();
        s.message = _msg;
    }

    // Retrieve message
    function getMessage() internal view returns (string memory) {
        return getStorage().message;
    }
}

contract WriteMessageFacet {
    function setMessage(string calldata _msg) external {
        MessageLib.setMessage(_msg);
    }
}

contract ReadMessageFacet {
    function getMessage() external view returns (string memory) {
        return MessageLib.getMessage();
    }
}
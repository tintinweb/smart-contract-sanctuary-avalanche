// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity =0.8.18;

import "./Counter.sol";
import "@hyperlane/solidity/contracts/libs/TypeCasts.sol";

interface IMessageRecipient {
    /**
     * @notice Handle an interchain message
     * @param _origin Domain ID of the chain from which the message came
     * @param _sender Address of the message sender on the origin chain as bytes32
     * @param _body Raw bytes content of message body
     */
    function handle(uint32 _origin, bytes32 _sender, bytes calldata _body) external;
}

contract Recieve is IMessageRecipient {
    event Received(uint32 origin, address sender, bytes body);

    address constant mailbox = 0xCC737a94FecaeC165AbCf12dED095BB13F037685;

    modifier onlyMailbox() {
        require(msg.sender == mailbox);
        _;
    }

    function handle(uint32 _origin, bytes32 _sender, bytes calldata _body) external onlyMailbox {
        uint256 value = abi.decode(_body, (uint256));
        Counter counter = Counter(0x0e46caFAE2A3Aab7070A300ADd05077c18457098);
        counter.increment(value);
        address sender = TypeCasts.bytes32ToAddress(_sender);
        emit Received(_origin, sender, _body);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.18;

interface Counter {
    function increment(uint256 value) external;

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

library TypeCasts {
    // alignment preserving cast
    function addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

    // alignment preserving cast
    function bytes32ToAddress(bytes32 _buf) internal pure returns (address) {
        return address(uint160(uint256(_buf)));
    }
}
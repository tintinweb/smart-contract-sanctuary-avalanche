/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-30
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) external;
}

interface ICounterDeployment is ILayerZeroReceiver {

    event DebugEvent(string log);
    event DebugEventWithNum(string log, int256 number);

    /**
     * @dev Emitted when a `satelliteCounterAddress` counter's count.`op`(`value`) is updated.
     */
    event CountUpdated(address indexed satelliteCounterAddress, int256 value, Operation op);

    /**
     * @dev Emitted when a `viewingSatelliteCounterAddress` retrieves the `count` of a
     * `viewedSatelliteCounterAddress`. `count` is the current count of the viewed address.
     *
     * Requirements:
     * - Only emitted by Master chains.
     */
    event CountRetrieved(
        address indexed viewingSatelliteCounterAddress,
        address indexed viewedSatelliteCounterAddress,
        int256 count
    );

    /**
     * @dev Emitted when a `viewingSatelliteCounterAddress` receives the `count` of a
     * `viewedSatelliteCounterAddress`. `count` is the current count of the viewed address.
     *
     * Requirements:
     * - Only emitted by Satellite chains.
     */
    event CountReceived(
        address indexed viewingSatelliteCounterAddress,
        address indexed viewedSatelliteCounterAddress,
        int256 count
    );

    /**
     * @dev Defines a math operation (+, -, *).
     */
    enum Operation {
        ADD,
        SUB,
        MUL
    }

    /**
     * @dev Specifies which function is making the endpoint.send() request to Layer0.
     *
     * For internal use only.
     */
    enum Function {
        UPDATE_COUNT,
        GET_COUNT
    }

    /**
     * @dev Updates a satellite chain's count by a `_value` for a particular `_op`
     * at `_satelliteCounterAddress`.
     *
     * Requirements:
     * - Can only be used to update the calling satellite chain's own counter.
     * - `_op` must only be ADD(+) || SUB(-) || MUL(*).
     */
    function updateCount(int256 _value, Operation _op, address _satelliteCounterAddress) external payable;

    /**
     * @dev Retrieves a satellite chain's `count` at `_satelliteCounterAddress`
     */
    function getCount(address _satelliteCounterAddress) external payable returns (int256);

    /**
     * @dev Sends a messages via LayerZero
     */
    function send(
        uint16 _dstChainId, bytes memory _dstBytesAddress, bytes memory _payload
    ) external payable;
}

interface ILayerZeroUserApplicationConfig {
    // @notice generic config getter/setter for user app
    function setConfig(
        uint16 _version,
        uint256 _configType,
        bytes calldata _config
    ) external;

    function getConfig(
        uint16 _version,
        uint16 _chainId,
        address _userApplication,
        uint256 _configType
    ) external view returns (bytes memory);

    // @notice LayerZero versions. Send/Receive can be different versions during migration
    function setSendVersion(uint16 version) external;

    function setReceiveVersion(uint16 version) external;

    function getSendVersion() external view returns (uint16);

    function getReceiveVersion() external view returns (uint16);

    // @notice Only in extreme cases where the UA needs to resume the message flow
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress)
        external;
}

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _chainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. ie: pay for a specified destination gasAmount, or receive airdropped native gas from the relayer on destination (oh yea!)
    function send(
        uint16 _chainId,
        bytes calldata _destination,
        bytes calldata _payload,
        address payable refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    ) external payable;

    // @notice get the inboundNonce of a receiver from a source chain which could be EVM or non-EVM chain
    // @param _srcChainID - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(uint16 _srcChainID, bytes calldata _srcAddress)
        external
        view
        returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainID, address _srcAddress)
        external
        view
        returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(
        uint16 _dstChainId,
        address _userApplication,
        bytes calldata _payload,
        bool _payInZRO,
        bytes calldata _adapterParam
    ) external view returns (uint256 nativeFee, uint256 zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getEndpointId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainID - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _dstAddress - the destination chain contract address
    function retryPayload(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        address _dstAddress
    ) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainID - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _dstAddress - the destination chain contract address
    function hasStoredPayload(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        address _dstAddress
    ) external view returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    // @param _libraryAddress - the address of the layerzero library
    function isValidSendLibrary(
        address _userApplication,
        address _libraryAddress
    ) external view returns (bool);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    // @param _libraryAddress - the address of the layerzero library
    function isValidReceiveLibrary(
        address _userApplication,
        address _libraryAddress
    ) external view returns (bool);
}

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

contract MasterCounter is ICounterDeployment, ReentrancyGuard {

    mapping(address /* satelliteCounterAddress */ => int256 /* count */) public counter;

    modifier owningEndpointOnly() {
        require(msg.sender == address(endpoint), "owning endpoint only");
        _;
    }

    ILayerZeroEndpoint public endpoint;

    constructor(address _endpoint) payable {
        emit DebugEventWithNum("Master: constructor() called", int256(msg.value));
        endpoint = ILayerZeroEndpoint(_endpoint);
        emit DebugEventWithNum("Master: constructor() complete", int256(msg.value));
    }

    /**
     * @dev Updates count for owning Satellite chain request.
     */
    function updateCount(
        int256 _value,
        Operation _op,
        address _satelliteCounterAddress
    ) public payable override(ICounterDeployment) {
        emit DebugEventWithNum("Master: updateCount() called", _value);
        /* switch (Operation) */
        if (/* case: */ Operation.ADD == _op)
        {
            counter[_satelliteCounterAddress] += _value;
            emit DebugEventWithNum("Master: added value", _value);
        }
        else if (/* case: */ Operation.SUB == _op)
        {
            counter[_satelliteCounterAddress] -= _value;
            emit DebugEventWithNum("Master: subtracted value", _value);
        }
        else if (/* case: */ Operation.MUL == _op)
        {
            counter[_satelliteCounterAddress] *= _value;
            emit DebugEventWithNum("Master: multiplied value", _value);
        }
        else /* default: */
        {
            emit DebugEventWithNum("Master: invalid operation", _value);
            require(false, "invalid operation");
        }
        emit DebugEventWithNum("Master: updateCount() complete", _value);
    }

    /**
     * @dev Retrieves count for Satellite chain request.
     */
    function getCount(
        address _satelliteCounterAddress
    ) public payable override(ICounterDeployment) returns (int256 count) {
        emit DebugEventWithNum("Master: getCount() called", count);
        count = counter[_satelliteCounterAddress];
        emit DebugEventWithNum("Master: getCount() complete", count);
    }

    /**
     * @dev Sends message of LayerZero from this contract's `endpoint`.
     */
    function send(
        uint16 _dstChainId,
        bytes memory _dstBytesAddress,
        bytes memory _payload
    ) public payable override(ICounterDeployment) {
        emit DebugEventWithNum("Master: send() called", int256(msg.value));
        endpoint.send{value: msg.value}(
            _dstChainId,
            _dstBytesAddress,
            _payload,
            payable(msg.sender),
            address(0),
            bytes("")
        );
        emit DebugEventWithNum("Master: send() complete", int256(msg.value));
    }

    /**
     * @dev Receives request from Satellite chains via LayerZero.
     *
     * Emits {CountUpdated} and {CountRetrieved} events.
     */
    function lzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 /* _nonce */,
        bytes memory _payload
    ) external override(ILayerZeroReceiver) nonReentrant owningEndpointOnly {
        emit DebugEvent("Master: lzReceive() called");
        (
            Function sendingFunction,
            int256 value,
            Operation op,
            address satelliteCounterAddress
        ) = abi.decode(
            _payload, (Function, int256, Operation, address)
        );

        /* switch (Function) */
        if (/* case: */ Function.UPDATE_COUNT == sendingFunction)
        {
            emit DebugEventWithNum("Master: case(updateCount) entered", value);
            require(getAddress(_srcAddress) == satelliteCounterAddress, "owning satellite only");

            emit DebugEventWithNum("Master: calling updateCount...", value);
            updateCount(value, op, satelliteCounterAddress);
            emit DebugEventWithNum("Master: count updated", value);

            emit CountUpdated(satelliteCounterAddress, value, op);
        }
        else if (/* case: */ Function.GET_COUNT == sendingFunction)
        {
            emit DebugEventWithNum("Master: case(getCount) entered", value);
            emit DebugEventWithNum("Master: calling getCount...", value);
            int256 count = getCount(satelliteCounterAddress);
            emit DebugEventWithNum("Master: count retrieved", value);

            emit CountRetrieved(getAddress(_srcAddress), satelliteCounterAddress, count);

            bytes memory payload = abi.encode(
                count,
                satelliteCounterAddress
            );

            send(_srcChainId, _srcAddress, payload);
        }
        else /* default: */
        {
            emit DebugEventWithNum("Master: invalid sending function", value);
            require(false, "invalid sending function");
        }
        emit DebugEventWithNum("Master: lzRecieve() complete", value);
    }

    /**
     * @dev Converts bytes to an address.
     *
     * Requirements:
     * - `_bytesAddress` is the bytes representation of an address.
     */
    function getAddress(
        bytes memory _bytesAddress
    ) private returns (address convertedAddress) {
        emit DebugEvent("Master: getAddress() called");
        assembly {
            convertedAddress := mload(add(_bytesAddress, 20))
        }
        emit DebugEvent("Master: getAddress() complete");
    }
}
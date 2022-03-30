/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-30
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface ILayerZeroReceiver {

    function lzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) external;
}

/**
 * LayerZero Message Passing POC
 *
 * Author: Noah Bayindirli (nbayindirli)
 */
interface ICounterDeployment is ILayerZeroReceiver {

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
    function getCount(address _satelliteCounterAddress) external payable returns (int256 count);

    /**
     * @dev Sends a messages via LayerZero
     */
    function send(
        uint16 _dstChainId, bytes memory _dstBytesAddress, bytes memory _payload
    ) external payable;
}

interface ILayerZeroUserApplicationConfig {

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

    function setSendVersion(uint16 version) external;

    function setReceiveVersion(uint16 version) external;

    function getSendVersion() external view returns (uint16);

    function getReceiveVersion() external view returns (uint16);

    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress)
        external;
}

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {

    function send(
        uint16 _chainId,
        bytes calldata _destination,
        bytes calldata _payload,
        address payable refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    ) external payable;

    function getInboundNonce(uint16 _srcChainID, bytes calldata _srcAddress)
        external
        view
        returns (uint64);

    function getOutboundNonce(uint16 _dstChainID, address _srcAddress)
        external
        view
        returns (uint64);

    function estimateFees(
        uint16 _dstChainId,
        address _userApplication,
        bytes calldata _payload,
        bool _payInZRO,
        bytes calldata _adapterParam
    ) external view returns (uint256 nativeFee, uint256 zroFee);

    function getEndpointId() external view returns (uint16);

    function retryPayload(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        address _dstAddress
    ) external;

    function hasStoredPayload(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        address _dstAddress
    ) external view returns (bool);

    function isValidSendLibrary(
        address _userApplication,
        address _libraryAddress
    ) external view returns (bool);

    function isValidReceiveLibrary(
        address _userApplication,
        address _libraryAddress
    ) external view returns (bool);
}

abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

/**
 * LayerZero Message Passing POC: Master Chain Counter
 *
 * Author: Noah Bayindirli (nbayindirli)
 */
contract MasterCounter is ICounterDeployment, ReentrancyGuard {

    mapping(address /* satelliteCounterAddress */ => int256 /* count */) public counter;

    modifier owningEndpointOnly() {
        require(msg.sender == address(endpoint), "owning endpoint only");
        _;
    }

    ILayerZeroEndpoint public endpoint;

    constructor(address _endpoint) {
        endpoint = ILayerZeroEndpoint(_endpoint);
    }

    /**
     * @dev Updates count for owning Satellite chain request.
     */
    function updateCount(
        int256 _value,
        Operation _op,
        address _satelliteCounterAddress
    ) public payable override(ICounterDeployment) {
        /* switch (Operation) */
        if (/* case: */ Operation.ADD == _op)
        {
            counter[_satelliteCounterAddress] += _value;
        }
        else if (/* case: */ Operation.SUB == _op)
        {
            counter[_satelliteCounterAddress] -= _value;
        }
        else if (/* case: */ Operation.MUL == _op)
        {
            counter[_satelliteCounterAddress] *= _value;
        }
        else /* default: */
        {
            require(false, "invalid operation");
        }
    }

    /**
     * @dev Retrieves count for Satellite chain request.
     */
    function getCount(
        address _satelliteCounterAddress
    ) public payable override(ICounterDeployment) returns (int256 count) {
        count = counter[_satelliteCounterAddress];
    }

    /**
     * @dev Sends message of LayerZero from this contract's `endpoint`.
     */
    function send(
        uint16 _dstChainId,
        bytes memory _dstBytesAddress,
        bytes memory _payload
    ) public payable override(ICounterDeployment) {
        endpoint.send{value: msg.value}(
            _dstChainId,
            _dstBytesAddress,
            _payload,
            payable(msg.sender),
            address(0),
            bytes("")
        );
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
            require(getAddress(_srcAddress) == satelliteCounterAddress, "owning satellite only");

            updateCount(value, op, satelliteCounterAddress);

            emit CountUpdated(satelliteCounterAddress, value, op);
        }
        else if (/* case: */ Function.GET_COUNT == sendingFunction)
        {
            int256 count = getCount(satelliteCounterAddress);

            emit CountRetrieved(getAddress(_srcAddress), satelliteCounterAddress, count);

            bytes memory payload = abi.encode(
                count,
                satelliteCounterAddress
            );

            send(_srcChainId, _srcAddress, payload);
        }
        else /* default: */
        {
            require(false, "invalid sending function");
        }
    }

    /**
     * @dev Converts bytes to an address.
     *
     * Requirements:
     * - `_bytesAddress` is the bytes representation of an address.
     */
    function getAddress(
        bytes memory _bytesAddress
    ) private pure returns (address convertedAddress) {
        assembly {
            convertedAddress := mload(add(_bytesAddress, 20))
        }
    }
}
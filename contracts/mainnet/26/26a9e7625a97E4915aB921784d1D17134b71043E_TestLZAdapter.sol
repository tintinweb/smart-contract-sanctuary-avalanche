// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "./ILayerZeroUserApplicationConfig.sol";

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(uint16 _dstChainId, bytes calldata _destination, bytes calldata _payload, address payable _refundAddress, address _zroPaymentAddress, bytes calldata _adapterParams) external payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(uint16 _srcChainId, bytes calldata _srcAddress, address _dstAddress, uint64 _nonce, uint _gasLimit, bytes calldata _payload) external;

    // @notice get the inboundNonce of a lzApp from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainId, address _srcAddress) external view returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(uint16 _dstChainId, address _userApplication, bytes calldata _payload, bool _payInZRO, bytes calldata _adapterParam) external view returns (uint nativeFee, uint zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, bytes calldata _payload) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the non-reentrancy guard for send() is on
    // @return true if the guard is on. false otherwise
    function isSendingPayload() external view returns (bool);

    // @notice query if the non-reentrancy guard for receive() is on
    // @return true if the guard is on. false otherwise
    function isReceivingPayload() external view returns (bool);

    // @notice get the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _userApplication - the contract address of the user application
    // @param _configType - type of configuration. every messaging library has its own convention.
    function getConfig(uint16 _version, uint16 _chainId, address _userApplication, uint _configType) external view returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication) external view returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication) external view returns (uint16);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external;

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

library LzLib {
    // LayerZero communication
    struct CallParams {
        address payable refundAddress;
        address zroPaymentAddress;
    }

    //---------------------------------------------------------------------------
    // Address type handling

    struct AirdropParams {
        uint airdropAmount;
        bytes32 airdropAddress;
    }

    function buildAdapterParams(LzLib.AirdropParams memory _airdropParams, uint _uaGasLimit) internal pure returns (bytes memory adapterParams) {
        if (_airdropParams.airdropAmount == 0 && _airdropParams.airdropAddress == bytes32(0x0)) {
            adapterParams = buildDefaultAdapterParams(_uaGasLimit);
        } else {
            adapterParams = buildAirdropAdapterParams(_uaGasLimit, _airdropParams);
        }
    }

    // Build Adapter Params
    function buildDefaultAdapterParams(uint _uaGas) internal pure returns (bytes memory) {
        // txType 1
        // bytes  [2       32      ]
        // fields [txType  extraGas]
        return abi.encodePacked(uint16(1), _uaGas);
    }

    function buildAirdropAdapterParams(uint _uaGas, AirdropParams memory _params) internal pure returns (bytes memory) {
        require(_params.airdropAmount > 0, "Airdrop amount must be greater than 0");
        require(_params.airdropAddress != bytes32(0x0), "Airdrop address must be set");

        // txType 2
        // bytes  [2       32        32            bytes[]         ]
        // fields [txType  extraGas  dstNativeAmt  dstNativeAddress]
        return abi.encodePacked(uint16(2), _uaGas, _params.airdropAmount, _params.airdropAddress);
    }

    function getGasLimit(bytes memory _adapterParams) internal pure returns (uint gasLimit) {
        require(_adapterParams.length == 34 || _adapterParams.length > 66, "Invalid adapterParams");
        assembly {
            gasLimit := mload(add(_adapterParams, 34))
        }
    }

    // Decode Adapter Params
    function decodeAdapterParams(bytes memory _adapterParams) internal pure returns (uint16 txType, uint uaGas, uint airdropAmount, address payable airdropAddress) {
        require(_adapterParams.length == 34 || _adapterParams.length > 66, "Invalid adapterParams");
        assembly {
            txType := mload(add(_adapterParams, 2))
            uaGas := mload(add(_adapterParams, 34))
        }
        require(txType == 1 || txType == 2, "Unsupported txType");
        require(uaGas > 0, "Gas too low");

        if (txType == 2) {
            assembly {
                airdropAmount := mload(add(_adapterParams, 66))
                airdropAddress := mload(add(_adapterParams, 86))
            }
        }
    }

    //---------------------------------------------------------------------------
    // Address type handling
    function bytes32ToAddress(bytes32 _bytes32Address) internal pure returns (address _address) {
        return address(uint160(uint(_bytes32Address)));
    }

    function addressToBytes32(address _address) internal pure returns (bytes32 _bytes32Address) {
        return bytes32(uint(uint160(_address)));
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;
pragma abicoder v2;

import "../interfaces/ILayerZeroReceiver.sol";
import "../interfaces/ILayerZeroEndpoint.sol";
import "../libraries/LzLib.sol";

/*
like a real LayerZero endpoint but can be mocked, which handle message transmission, verification, and receipt.
- blocking: LayerZero provides ordered delivery of messages from a given sender to a destination chain.
- non-reentrancy: endpoint has a non-reentrancy guard for both the send() and receive(), respectively.
- adapter parameters: allows UAs to add arbitrary transaction params in the send() function, like airdrop on destination chain.
unlike a real LayerZero endpoint, it is
- no messaging library versioning
- send() will short circuit to lzReceive()
- no user application configuration
*/
contract LZEndpointMock is ILayerZeroEndpoint {
    uint8 internal constant _NOT_ENTERED = 1;
    uint8 internal constant _ENTERED = 2;

    mapping(address => address) public lzEndpointLookup;

    uint16 public mockChainId;
    bool public nextMsgBlocked;

    // fee config
    RelayerFeeConfig public relayerFeeConfig;
    ProtocolFeeConfig public protocolFeeConfig;
    uint public oracleFee;
    bytes public defaultAdapterParams;

    // path = remote addrss + local address
    // inboundNonce = [srcChainId][path].
    mapping(uint16 => mapping(bytes => uint64)) public inboundNonce;
    //todo: this is a hack
    // outboundNonce = [dstChainId][srcAddress]
    mapping(uint16 => mapping(address => uint64)) public outboundNonce;
    //    // outboundNonce = [dstChainId][path].
    //    mapping(uint16 => mapping(bytes => uint64)) public outboundNonce;
    // storedPayload = [srcChainId][path]
    mapping(uint16 => mapping(bytes => StoredPayload)) public storedPayload;
    // msgToDeliver = [srcChainId][path]
    mapping(uint16 => mapping(bytes => QueuedPayload[])) public msgsToDeliver;

    // reentrancy guard
    uint8 internal _send_entered_state = 1;
    uint8 internal _receive_entered_state = 1;

    struct ProtocolFeeConfig {
        uint zroFee;
        uint nativeBP;
    }

    struct RelayerFeeConfig {
        uint128 dstPriceRatio; // 10^10
        uint128 dstGasPriceInWei;
        uint128 dstNativeAmtCap;
        uint64 baseGas;
        uint64 gasPerByte;
    }

    struct StoredPayload {
        uint64 payloadLength;
        address dstAddress;
        bytes32 payloadHash;
    }

    struct QueuedPayload {
        address dstAddress;
        uint64 nonce;
        bytes payload;
    }

    modifier sendNonReentrant() {
        require(_send_entered_state == _NOT_ENTERED, "LayerZeroMock: no send reentrancy");
        _send_entered_state = _ENTERED;
        _;
        _send_entered_state = _NOT_ENTERED;
    }

    modifier receiveNonReentrant() {
        require(_receive_entered_state == _NOT_ENTERED, "LayerZeroMock: no receive reentrancy");
        _receive_entered_state = _ENTERED;
        _;
        _receive_entered_state = _NOT_ENTERED;
    }

    event UaForceResumeReceive(uint16 chainId, bytes srcAddress);
    event PayloadCleared(uint16 srcChainId, bytes srcAddress, uint64 nonce, address dstAddress);
    event PayloadStored(uint16 srcChainId, bytes srcAddress, address dstAddress, uint64 nonce, bytes payload, bytes reason);
    event ValueTransferFailed(address indexed to, uint indexed quantity);

    constructor(uint16 _chainId) {
        mockChainId = _chainId;

        // init config
        relayerFeeConfig = RelayerFeeConfig({
            dstPriceRatio: 1e10, // 1:1, same chain, same native coin
            dstGasPriceInWei: 1e10,
            dstNativeAmtCap: 1e19,
            baseGas: 100,
            gasPerByte: 1
        });
        protocolFeeConfig = ProtocolFeeConfig({zroFee: 1e18, nativeBP: 1000}); // BP 0.1
        oracleFee = 1e16;
        defaultAdapterParams = LzLib.buildDefaultAdapterParams(200000);
    }

    // ------------------------------ ILayerZeroEndpoint Functions ------------------------------
    function send(uint16 _chainId, bytes memory _path, bytes calldata _payload, address payable _refundAddress, address _zroPaymentAddress, bytes memory _adapterParams) external payable override sendNonReentrant {
        require(_path.length == 40, "LayerZeroMock: incorrect remote address size"); // only support evm chains

        address dstAddr;
        assembly {
            dstAddr := mload(add(_path, 20))
        }

        address lzEndpoint = lzEndpointLookup[dstAddr];
        require(lzEndpoint != address(0), "LayerZeroMock: destination LayerZero Endpoint not found");

        // not handle zro token
        bytes memory adapterParams = _adapterParams.length > 0 ? _adapterParams : defaultAdapterParams;
        (uint nativeFee, ) = estimateFees(_chainId, msg.sender, _payload, _zroPaymentAddress != address(0x0), adapterParams);
        require(msg.value >= nativeFee, "LayerZeroMock: not enough native for fees");

        uint64 nonce = ++outboundNonce[_chainId][msg.sender];

        // refund if they send too much
        uint amount = msg.value - nativeFee;
        if (amount > 0) {
            (bool success, ) = _refundAddress.call{value: amount}("");
            require(success, "LayerZeroMock: failed to refund");
        }

        // Mock the process of receiving msg on dst chain
        // Mock the relayer paying the dstNativeAddr the amount of extra native token
        (, uint extraGas, uint dstNativeAmt, address payable dstNativeAddr) = LzLib.decodeAdapterParams(adapterParams);
        if (dstNativeAmt > 0) {
            (bool success, ) = dstNativeAddr.call{value: dstNativeAmt}("");
            if (!success) {
                emit ValueTransferFailed(dstNativeAddr, dstNativeAmt);
            }
        }

        bytes memory srcUaAddress = abi.encodePacked(msg.sender, dstAddr); // cast this address to bytes
        bytes memory payload = _payload;
        LZEndpointMock(lzEndpoint).receivePayload(mockChainId, srcUaAddress, dstAddr, nonce, extraGas, payload);
    }

    function receivePayload(uint16 _srcChainId, bytes calldata _path, address _dstAddress, uint64 _nonce, uint _gasLimit, bytes calldata _payload) external override receiveNonReentrant {
        StoredPayload storage sp = storedPayload[_srcChainId][_path];

        // assert and increment the nonce. no message shuffling
        require(_nonce == ++inboundNonce[_srcChainId][_path], "LayerZeroMock: wrong nonce");

        // queue the following msgs inside of a stack to simulate a successful send on src, but not fully delivered on dst
        if (sp.payloadHash != bytes32(0)) {
            QueuedPayload[] storage msgs = msgsToDeliver[_srcChainId][_path];
            QueuedPayload memory newMsg = QueuedPayload(_dstAddress, _nonce, _payload);

            // warning, might run into gas issues trying to forward through a bunch of queued msgs
            // shift all the msgs over so we can treat this like a fifo via array.pop()
            if (msgs.length > 0) {
                // extend the array
                msgs.push(newMsg);

                // shift all the indexes up for pop()
                for (uint i = 0; i < msgs.length - 1; i++) {
                    msgs[i + 1] = msgs[i];
                }

                // put the newMsg at the bottom of the stack
                msgs[0] = newMsg;
            } else {
                msgs.push(newMsg);
            }
        } else if (nextMsgBlocked) {
            storedPayload[_srcChainId][_path] = StoredPayload(uint64(_payload.length), _dstAddress, keccak256(_payload));
            emit PayloadStored(_srcChainId, _path, _dstAddress, _nonce, _payload, bytes(""));
            // ensure the next msgs that go through are no longer blocked
            nextMsgBlocked = false;
        } else {
            try ILayerZeroReceiver(_dstAddress).lzReceive{gas: _gasLimit}(_srcChainId, _path, _nonce, _payload) {} catch (bytes memory reason) {
                storedPayload[_srcChainId][_path] = StoredPayload(uint64(_payload.length), _dstAddress, keccak256(_payload));
                emit PayloadStored(_srcChainId, _path, _dstAddress, _nonce, _payload, reason);
                // ensure the next msgs that go through are no longer blocked
                nextMsgBlocked = false;
            }
        }
    }

    function getInboundNonce(uint16 _chainID, bytes calldata _path) external view override returns (uint64) {
        return inboundNonce[_chainID][_path];
    }

    function getOutboundNonce(uint16 _chainID, address _srcAddress) external view override returns (uint64) {
        return outboundNonce[_chainID][_srcAddress];
    }

    function estimateFees(uint16 _dstChainId, address _userApplication, bytes memory _payload, bool _payInZRO, bytes memory _adapterParams) public view override returns (uint nativeFee, uint zroFee) {
        bytes memory adapterParams = _adapterParams.length > 0 ? _adapterParams : defaultAdapterParams;

        // Relayer Fee
        uint relayerFee = _getRelayerFee(_dstChainId, 1, _userApplication, _payload.length, adapterParams);

        // LayerZero Fee
        uint protocolFee = _getProtocolFees(_payInZRO, relayerFee, oracleFee);
        _payInZRO ? zroFee = protocolFee : nativeFee = protocolFee;

        // return the sum of fees
        nativeFee = nativeFee + relayerFee + oracleFee;
    }

    function getChainId() external view override returns (uint16) {
        return mockChainId;
    }

    function retryPayload(uint16 _srcChainId, bytes calldata _path, bytes calldata _payload) external override {
        StoredPayload storage sp = storedPayload[_srcChainId][_path];
        require(sp.payloadHash != bytes32(0), "LayerZeroMock: no stored payload");
        require(_payload.length == sp.payloadLength && keccak256(_payload) == sp.payloadHash, "LayerZeroMock: invalid payload");

        address dstAddress = sp.dstAddress;
        // empty the storedPayload
        sp.payloadLength = 0;
        sp.dstAddress = address(0);
        sp.payloadHash = bytes32(0);

        uint64 nonce = inboundNonce[_srcChainId][_path];

        ILayerZeroReceiver(dstAddress).lzReceive(_srcChainId, _path, nonce, _payload);
        emit PayloadCleared(_srcChainId, _path, nonce, dstAddress);
    }

    function hasStoredPayload(uint16 _srcChainId, bytes calldata _path) external view override returns (bool) {
        StoredPayload storage sp = storedPayload[_srcChainId][_path];
        return sp.payloadHash != bytes32(0);
    }

    function getSendLibraryAddress(address) external view override returns (address) {
        return address(this);
    }

    function getReceiveLibraryAddress(address) external view override returns (address) {
        return address(this);
    }

    function isSendingPayload() external view override returns (bool) {
        return _send_entered_state == _ENTERED;
    }

    function isReceivingPayload() external view override returns (bool) {
        return _receive_entered_state == _ENTERED;
    }

    function getConfig(
        uint16, /*_version*/
        uint16, /*_chainId*/
        address, /*_ua*/
        uint /*_configType*/
    ) external pure override returns (bytes memory) {
        return "";
    }

    function getSendVersion(
        address /*_userApplication*/
    ) external pure override returns (uint16) {
        return 1;
    }

    function getReceiveVersion(
        address /*_userApplication*/
    ) external pure override returns (uint16) {
        return 1;
    }

    function setConfig(
        uint16, /*_version*/
        uint16, /*_chainId*/
        uint, /*_configType*/
        bytes memory /*_config*/
    ) external override {}

    function setSendVersion(
        uint16 /*version*/
    ) external override {}

    function setReceiveVersion(
        uint16 /*version*/
    ) external override {}

    function forceResumeReceive(uint16 _srcChainId, bytes calldata _path) external override {
        StoredPayload storage sp = storedPayload[_srcChainId][_path];
        // revert if no messages are cached. safeguard malicious UA behaviour
        require(sp.payloadHash != bytes32(0), "LayerZeroMock: no stored payload");
        require(sp.dstAddress == msg.sender, "LayerZeroMock: invalid caller");

        // empty the storedPayload
        sp.payloadLength = 0;
        sp.dstAddress = address(0);
        sp.payloadHash = bytes32(0);

        emit UaForceResumeReceive(_srcChainId, _path);

        // resume the receiving of msgs after we force clear the "stuck" msg
        _clearMsgQue(_srcChainId, _path);
    }

    // ------------------------------ Other Public/External Functions --------------------------------------------------

    function getLengthOfQueue(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (uint) {
        return msgsToDeliver[_srcChainId][_srcAddress].length;
    }

    // used to simulate messages received get stored as a payload
    function blockNextMsg() external {
        nextMsgBlocked = true;
    }

    function setDestLzEndpoint(address destAddr, address lzEndpointAddr) external {
        lzEndpointLookup[destAddr] = lzEndpointAddr;
    }

    function setRelayerPrice(uint128 _dstPriceRatio, uint128 _dstGasPriceInWei, uint128 _dstNativeAmtCap, uint64 _baseGas, uint64 _gasPerByte) external {
        relayerFeeConfig.dstPriceRatio = _dstPriceRatio;
        relayerFeeConfig.dstGasPriceInWei = _dstGasPriceInWei;
        relayerFeeConfig.dstNativeAmtCap = _dstNativeAmtCap;
        relayerFeeConfig.baseGas = _baseGas;
        relayerFeeConfig.gasPerByte = _gasPerByte;
    }

    function setProtocolFee(uint _zroFee, uint _nativeBP) external {
        protocolFeeConfig.zroFee = _zroFee;
        protocolFeeConfig.nativeBP = _nativeBP;
    }

    function setOracleFee(uint _oracleFee) external {
        oracleFee = _oracleFee;
    }

    function setDefaultAdapterParams(bytes memory _adapterParams) external {
        defaultAdapterParams = _adapterParams;
    }

    // --------------------- Internal Functions ---------------------
    // simulates the relayer pushing through the rest of the msgs that got delayed due to the stored payload
    function _clearMsgQue(uint16 _srcChainId, bytes calldata _path) internal {
        QueuedPayload[] storage msgs = msgsToDeliver[_srcChainId][_path];

        // warning, might run into gas issues trying to forward through a bunch of queued msgs
        while (msgs.length > 0) {
            QueuedPayload memory payload = msgs[msgs.length - 1];
            ILayerZeroReceiver(payload.dstAddress).lzReceive(_srcChainId, _path, payload.nonce, payload.payload);
            msgs.pop();
        }
    }

    function _getProtocolFees(bool _payInZro, uint _relayerFee, uint _oracleFee) internal view returns (uint) {
        if (_payInZro) {
            return protocolFeeConfig.zroFee;
        } else {
            return ((_relayerFee + _oracleFee) * protocolFeeConfig.nativeBP) / 10000;
        }
    }

    function _getRelayerFee(
        uint16, /* _dstChainId */
        uint16, /* _outboundProofType */
        address, /* _userApplication */
        uint _payloadSize,
        bytes memory _adapterParams
    ) internal view returns (uint) {
        (uint16 txType, uint extraGas, uint dstNativeAmt, ) = LzLib.decodeAdapterParams(_adapterParams);
        uint totalRemoteToken; // = baseGas + extraGas + requiredNativeAmount
        if (txType == 2) {
            require(relayerFeeConfig.dstNativeAmtCap >= dstNativeAmt, "LayerZeroMock: dstNativeAmt too large ");
            totalRemoteToken += dstNativeAmt;
        }
        // remoteGasTotal = dstGasPriceInWei * (baseGas + extraGas)
        uint remoteGasTotal = relayerFeeConfig.dstGasPriceInWei * (relayerFeeConfig.baseGas + extraGas);
        totalRemoteToken += remoteGasTotal;

        // tokenConversionRate = dstPrice / localPrice
        // basePrice = totalRemoteToken * tokenConversionRate
        uint basePrice = (totalRemoteToken * relayerFeeConfig.dstPriceRatio) / 10**10;

        // pricePerByte = (dstGasPriceInWei * gasPerBytes) * tokenConversionRate
        uint pricePerByte = (relayerFeeConfig.dstGasPriceInWei * relayerFeeConfig.gasPerByte * relayerFeeConfig.dstPriceRatio) / 10**10;

        return basePrice + _payloadSize * pricePerByte;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```solidity
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```solidity
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it. We recommend using {AccessControlDefaultAdminRules}
 * to enforce additional security measures for this role.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IMainVault {
    function transfer(address tokenAddress, uint256 tokenAmount) external;

    function calculateTokenValue(
        uint256 chainId,
        address tokenAddress,
        uint256 tokenAmount
    ) external returns (uint256);

    function isSameToken(
        uint256 chainId1,
        address tokenAddress1,
        uint256 chainId2,
        address tokenAddress2
    ) external view returns (bool);

    function queryTokenDecimal(
        uint256 chainId,
        address tokenAddress
    ) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;
import "./IPayDB.sol";

/// @title Callback for IPayDB.createSrcOrder
interface INodeCall {
    /// @notice Called to `node` after createSrcOrder.
    /// @dev In the implementation you can do something to handle the PayDB order.
    /// @param data Any data passed through by the caller via the createSrcOrder call
    /// @param owner the address create the bridge order assigned by msg.sender,who also pay the order.
    /// @param receiver the address in dst chain to recive the tokenout assets.
    /// @param wallet the virtual wallet address in dst chain to execute the vwDetail instruction.
    /// @param cparams CreateSrcOrder Payment info.
    /// @param vwDetail CreateSrcOrder Virtual wallet detail info.
    function CreateSrcOrderCall(
        bytes calldata data,
        address owner,
        address receiver,
        address wallet,
        IPayDB.CreatePayOrderParam[] calldata cparams,
        IPayDB.VwOrderDetail calldata vwDetail
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./IVWManager.sol";

interface IPayDB {
    struct ExePayOrderParam {
        uint256 amountOut;
        address tokenOut;
        uint256 payOrderId;
    }

    struct CreatePayOrderParam {
        uint256 amountIn;
        uint256 amountOut;
        uint256 payOrderId;
        // default token to pay fee is tokenin
        uint256 bridgeFee;
        address tokenIn;
        address tokenOut;
        address node;
    }

    struct VwOrderDetail {
        uint256 code;
        address service;
        bytes32 dataHash;
    }

    struct CallParam {
        address node;
        bytes nodeCallData;
    }

    struct ReceiverWallet {
        address _receiver;
        address _wallet;
    }

    event OrderCreated(
        address indexed owner,
        address indexed node,
        uint256 indexed payOrderId,
        address receiver,
        uint256 amountIn,
        address tokenIn,
        uint256 amountOut,
        address tokenOut,
        uint256 code,
        bytes32 wfHash
    );

    event OrderCancelled(address indexed node, uint256 payOrderId);

    event OrderExecuted(
        address indexed executor,
        uint256 indexed payOrderId,
        address owner,
        address receiver,
        uint256 amountOut,
        address tokenOut,
        uint256 code,
        bytes32 wfHash
    );

    event IsolateOrderExecuted(
        address indexed executor,
        address wallet,
        uint256 amountOut,
        address tokenOut
    );

    event VWManagerSet(address indexed vwmanager);

    function createSrcOrder(
        address owner,
        address wallet,
        address receiver,
        CreatePayOrderParam[] calldata cparams,
        VwOrderDetail calldata vwparam,
        CallParam calldata callParam
    ) external;

    function createSrcOrderETH(
        address owner,
        address wallet,
        address receiver,
        CreatePayOrderParam[] calldata cparams,
        VwOrderDetail calldata vwparam,
        CallParam calldata callParam
    ) external payable;

    function executeDstOrderETH(
        address owner,
        address receiver,
        address wallet,
        ExePayOrderParam[] calldata eparams,
        IVWManager.VWExecuteParam calldata vwExeParam
    ) external payable;

    function executeDstOrder(
        address owner,
        address receiver,
        address wallet,
        ExePayOrderParam[] calldata eparams,
        IVWManager.VWExecuteParam calldata vwExeParam
    ) external;

    function cancelOrderETH(
        address owner,
        address receiver,
        CreatePayOrderParam[] calldata cparam,
        bytes32[] calldata workFlowHashs
    ) external payable;

    function cancelOrder(
        address owner,
        address receiver,
        CreatePayOrderParam[] calldata cparam,
        bytes32[] calldata workFlowHashs
    ) external;

    function executeIsolateOrder(
        address receiver,
        address wallet,
        ExePayOrderParam[] calldata eparams,
        IVWManager.VWExecuteParam calldata vwExeParam
    ) external;

    function executeIsolateOrderETH(
        address receiver,
        address wallet,
        ExePayOrderParam[] calldata eparams,
        IVWManager.VWExecuteParam calldata vwExeParam
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IService {
    function execute(
        uint code,
        bytes calldata data,
        address node
    ) external returns (bool res);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IVWManagerStorage.sol";
import "./IService.sol";

interface IVWManager is IVWManagerStorageV1 {
    struct VWExecuteParam {
        uint256 code;
        uint256 gasTokenPrice;
        uint256 priorityFee;
        uint256 gasLimit;
        address manager;
        address service;
        address gasToken;
        address feeReceiver;
        bool isGateway;
        bytes data;
        bytes serviceSignature;
        bytes32[] proof;
    }

    //function verify(bool res, uint code, address service, bytes calldata data, bytes calldata signature) external;

    function createWallet(address owner) external returns (address wallet);

    function execute(
        address wallet,
        VWExecuteParam calldata eParam
    ) external returns (bool res);

    function verifyEIP1271Signature(
        address signer,
        bytes32 digest,
        bytes memory signature
    ) external view;

    event TxExecuted(
        address indexed wallet,
        address indexed owner,
        uint256 indexed code,
        bytes32 rootHash,
        bool res
    );

    event VWCreated(address indexed wallet, address indexed owner);

    event Initialized(address deployer);

    event SetFee(
        bool indexed protocolFeeOpened,
        address indexed feeVault,
        uint256 indexed feeProportion
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IVWManagerStorageV1 {
    function walletOwner(address wallet) external view returns (address);

    function ownerWallet(address user) external view returns (address);

    function domainSeparator(uint256 chainId) external view returns (bytes32);

    function volatileService() external returns (address);

    function protocolFeeOpened() external returns (bool);

    function feeVault() external returns (address);

    function feeProportion() external returns (uint256);

    event VWOwnerChanged(
        address indexed wallet,
        address indexed previousOwner,
        address indexed newOwner
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library OrderId {
    /// @notice  Packing (nonce: 128, time: 32, srcChainId 32, dstChainId 32, type: 16, flag: 16)
    /// type: 0-fiat 1-Binance Pay 2-crypto
    function genCode(
        uint128 nonce,
        uint32 time,
        uint32 srcChainId,
        uint32 dstChainId,
        uint16 oType,
        uint16 flag
    ) internal pure returns (uint code) {
        code =
            (uint(nonce) << 128) +
            (uint(time) << 96) +
            (uint(srcChainId) << 64) +
            (uint(dstChainId) << 32) +
            (uint(oType) << 16) +
            uint(flag);
    }

    function chainidsAndExpTime(
        uint code
    ) internal pure returns (uint dstChainId, uint srcChainId, uint time) {
        dstChainId = (code >> 32) & ((1 << 32) - 1);
        srcChainId = (code >> 64) & ((1 << 32) - 1);
        time = (code >> 96) & ((1 << 32) - 1);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.6;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library TransferHelper {
    function safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    // Check balance after transfer.So deflationary token is not supported.
    function safeTransferFrom2(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        uint256 balanceBefore = IERC20(token).balanceOf(to);
        
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');

        uint256 balanceAfter = IERC20(token).balanceOf(to);
        require(balanceBefore + value <= balanceAfter, 'No deflationary token');
    }

    function safeTransferFrom3(
        address token,
        address from,
        address to,
        uint256 value
    ) internal returns (uint){
        uint256 balanceBefore = IERC20(token).balanceOf(to);
        
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
        uint256 balanceAfter = IERC20(token).balanceOf(to);
        require(balanceBefore <= balanceAfter, 'No deflationary token');
        return (balanceAfter - balanceBefore);
    }
    
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }

    function safeTransfer2(address token, address to, uint256 value) internal {
        if(token != address(0)){
            safeTransfer(token, to, value);
        }else{
            safeTransferETH(to, value);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/INodeCall.sol";
import "@layerzerolabs/solidity-examples/contracts/interfaces/ILayerZeroEndpoint.sol";
import "@layerzerolabs/solidity-examples/contracts/interfaces/ILayerZeroReceiver.sol";
import "../libraries/OrderId.sol";
import "./VaultPlugIn.sol";
import "../libraries/TransferHelper.sol";

contract LZAdapter is AccessControl, ILayerZeroReceiver {
    address endpoint;

    mapping(uint256 => uint16) public chainIdToLzId;
    mapping(uint16 => uint256) public lzIdToChainId;

    mapping(bytes32 => bool) public verifiedDigest;
    mapping(bytes32 => bool) public receivedDigest;
    mapping(uint256 => address) public vaultAddress;

    event SetSupportedChain(
        uint256 indexed chainId,
        uint16 indexed lzId,
        bool indexed supported
    );
    event SetRemoteVaultAddress(uint256 indexed chainId, address indexed vault);
    event ReceiveDigest(uint256 indexed srcChainId, bytes32 indexed digest);
    event SendCrossChain(uint256 indexed dstChainId, bytes32 indexed digest);

    constructor(address _endpoint) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        endpoint = _endpoint;

        // https://layerzero.gitbook.io/docs/technical-reference/mainnet/supported-chain-ids
        chainIdToLzId[1] = 101; // Ethereum
        chainIdToLzId[56] = 102; // BSC
        chainIdToLzId[43114] = 106; // Avalanche C-Chain
        chainIdToLzId[137] = 109; // Polygon
        chainIdToLzId[53935] = 115; // DFK

        lzIdToChainId[101] = 1; // Ethereum
        lzIdToChainId[102] = 56; // BSC
        lzIdToChainId[106] = 43114; // Avalanche C-Chain
        lzIdToChainId[109] = 137; // Polygon
        lzIdToChainId[115] = 53935; // DFK
    }

    function setSupportedChain(
        uint256[] calldata chainId,
        uint16[] calldata lzId,
        bool[] calldata supported
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint i = 0; i < chainId.length; i++) {
            if (supported[i]) {
                chainIdToLzId[chainId[i]] = lzId[i];
                lzIdToChainId[lzId[i]] = chainId[i];
            } else {
                chainIdToLzId[chainId[i]] = 0;
                lzIdToChainId[lzId[i]] = 0;
            }
            emit SetSupportedChain(chainId[i], lzId[i], supported[i]);
        }
    }

    function setRemoteVaultAddress(
        uint256[] calldata chainId,
        address[] calldata vault
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint i = 0; i < chainId.length; i++) {
            vaultAddress[chainId[i]] = vault[i];
            emit SetRemoteVaultAddress(chainId[i], vault[i]);
        }
    }

    function _sendToLayerZero(
        address owner,
        address receiver,
        address wallet,
        IPayDB.CreatePayOrderParam[] memory cParams,
        bytes32 dataHash
    ) internal {
        bytes32 digest = _calculateDigest(
            owner,
            receiver,
            wallet,
            _cParams2eParams(cParams),
            dataHash
        );

        (uint256 dstChainId, , ) = OrderId.chainidsAndExpTime(
            cParams[0].payOrderId
        );

        ILayerZeroEndpoint(endpoint).send{value: msg.value}(
            chainIdToLzId[dstChainId],
            abi.encodePacked(vaultAddress[dstChainId], address(this)),
            abi.encodePacked(digest),
            payable(tx.origin), // Set tx.origin as the receiver of remaining gas
            address(this),
            ""
        );

        emit SendCrossChain(dstChainId, digest);
    }

    // override from ILayerZeroReceiver.sol
    function lzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) external override {
        // Only LayerZero endpoint contract is allowed to call this function.
        require(msg.sender == endpoint, "E12");

        address srcAddr;
        assembly {
            srcAddr := mload(add(_srcAddress, 20))
        }

        // Check if sender is the remote Vault
        require(srcAddr == vaultAddress[lzIdToChainId[_srcChainId]]);

        bytes32 digest = bytes32(_payload);

        receivedDigest[digest] = true;

        emit ReceiveDigest(lzIdToChainId[_srcChainId], digest);
    }

    function _calculateDigest(
        address owner,
        address receiver,
        address wallet,
        IPayDB.ExePayOrderParam[] memory eParams,
        bytes32 dataHash
    ) internal pure returns (bytes32 digest) {
        digest = keccak256(
            abi.encode(owner, receiver, wallet, eParams, dataHash)
        );
    }

    function _verifyLzMessage(bytes32 digest) internal returns (bool valid) {
        valid = receivedDigest[digest] && !verifiedDigest[digest];

        // Anti re-entrancy attack
        if (valid) {
            verifiedDigest[digest] = true;
        }
    }

    function _cParams2eParams(
        IPayDB.CreatePayOrderParam[] memory cParams
    ) internal pure returns (IPayDB.ExePayOrderParam[] memory eparams) {
        eparams = new IPayDB.ExePayOrderParam[](cParams.length);
        for (uint256 i = 0; i < cParams.length; i++) {
            eparams[i].amountOut = cParams[i].amountOut;
            eparams[i].tokenOut = cParams[i].tokenOut;
            eparams[i].payOrderId = cParams[i].payOrderId;
        }
    }

    // This contract is used as the refund account of the LZ sending process
    receive() external payable {}
}

contract DappOSLargeVault is VaultPlugIn, LZAdapter, INodeCall {
    bytes32 public constant ROLE_BOT = keccak256("ROLE_BOT");

    address cexAddress;
    address payDB;

    modifier onlyPayDB() {
        require(msg.sender == payDB, "E9");
        _;
    }

    constructor(
        address _payDB,
        address _endpoint,
        address _mainVault
    ) LZAdapter(_endpoint) VaultPlugIn(_mainVault) {
        payDB = _payDB;
    }

    // Redundant paydb-related code
    // TODO: Refactor into another contract
    function setPayDB(address _payDB) external onlyRole(DEFAULT_ADMIN_ROLE) {
        payDB = _payDB;
    }

    function approveTokens(
        address[] calldata tokens,
        bool isSupported
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint approvedNumber = isSupported ? type(uint).max : 0;
        for (uint256 i = 0; i < tokens.length; i++) {
            SafeERC20.safeApprove(IERC20(tokens[i]), payDB, approvedNumber);
        }
    }

    function setCexAddress(
        address _cexAddress
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        cexAddress = _cexAddress;
    }

    // When this vault receives a large amount, `CreateSrcOrderCall` is called
    // by the PayDB contract. The amount is transferred directly to a whitelisted
    // CEX address, and a LayerZero message is sent.
    function CreateSrcOrderCall(
        bytes calldata data,
        address owner, // address that initiated the order
        address receiver, // address in dst chain that receives the assets
        address wallet, // vw in dst chain that executes vwDetail
        IPayDB.CreatePayOrderParam[] calldata cParam,
        IPayDB.VwOrderDetail calldata vwInfo
    ) external payable onlyPayDB {
        // Big transfer. Send directly to CEX.
        uint256[] memory amountIn = new uint256[](cParam.length);
        address[] memory tokenIn = new address[](cParam.length);
        (uint256 dstChainId, , ) = OrderId.chainidsAndExpTime(
            cParam[0].payOrderId
        );
        for (uint i = 0; i < cParam.length; i++) {
            amountIn[i] = cParam[i].amountIn;
            tokenIn[i] = cParam[i].tokenIn;

            // Make sure tokenIn and tokenOut are reasonable
            bool sameToken = IMainVault(mainVault).isSameToken(
                block.chainid,
                tokenIn[i],
                dstChainId,
                cParam[i].tokenOut
            );

            require(sameToken, "E11");

            uint256 decimalIn = IMainVault(mainVault).queryTokenDecimal(
                block.chainid,
                tokenIn[i]
            );
            uint256 decimalOut = IMainVault(mainVault).queryTokenDecimal(
                dstChainId,
                cParam[i].tokenOut
            );

            require(
                amountIn[i] * 10 ** decimalOut >=
                    cParam[i].amountOut * 10 ** decimalIn,
                "E12"
            );
        }
        _sendToCex(amountIn, tokenIn, cexAddress);

        // Send the digest through LayerZero to the destination chain.
        _sendToLayerZero(owner, receiver, wallet, cParam, vwInfo.dataHash);
    }

    function cancelOrder(
        address owner,
        address receiver,
        IPayDB.CreatePayOrderParam[] calldata cparams,
        bytes32[] calldata workFlowHash
    )
        external
        onlyRole(
            DEFAULT_ADMIN_ROLE /** This function is rarely called for safety reasons. */
        )
    {
        /*********************** CHECKS ***********************/

        /*********************** EFFECTS ***********************/

        // Get tokens from mainVault
        for (uint256 i = 0; i < cparams.length; i++) {
            request(cparams[i].tokenIn, cparams[i].amountIn);
        }

        uint totalEth = 0;
        {
            for (uint i = 0; i < cparams.length; i++) {
                if (cparams[i].tokenIn == address(0)) {
                    totalEth += cparams[i].amountIn;
                }
            }
        }

        if (totalEth > 0) {
            IPayDB(payDB).cancelOrderETH{value: totalEth}(
                owner,
                receiver,
                cparams,
                workFlowHash
            );
        } else {
            IPayDB(payDB).cancelOrder(owner, receiver, cparams, workFlowHash);
        }
    }

    // LargeVault adds another LayerZero check on top of NormalVault.
    function executeOrder(
        address owner,
        address receiver,
        address wallet,
        IPayDB.ExePayOrderParam[] calldata eparams,
        IVWManager.VWExecuteParam calldata vwExeParam
    ) public onlyRole(ROLE_BOT) {
        /*********************** CHECKS ***********************/

        bytes32 digest = _calculateDigest(
            owner,
            receiver,
            wallet,
            eparams,
            keccak256(vwExeParam.data)
        );

        // LayerZero check
        require(_verifyLzMessage(digest), "E6");

        /*********************** EFFECTS ***********************/

        // Get tokens from mainVault
        for (uint256 i = 0; i < eparams.length; i++) {
            request(eparams[i].tokenOut, eparams[i].amountOut);
        }

        uint totalEth = 0;
        {
            for (uint i = 0; i < eparams.length; i++) {
                if (eparams[i].tokenOut == address(0)) {
                    totalEth += eparams[i].amountOut;
                }
            }
        }

        if (totalEth > 0) {
            IPayDB(payDB).executeDstOrderETH{value: totalEth}(
                owner,
                receiver,
                wallet,
                eparams,
                vwExeParam
            );
        } else {
            IPayDB(payDB).executeDstOrder(
                owner,
                receiver,
                wallet,
                eparams,
                vwExeParam
            );
        }
    }

    function _sendToCex(
        uint256[] memory amountIn,
        address[] memory tokenIn,
        address cex
    ) internal {
        require(cex != address(0x0), "E8");
        for (uint i = 0; i < amountIn.length; i++) {
            TransferHelper.safeTransfer2(tokenIn[i], cex, amountIn[i]);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/IMainVault.sol";

contract VaultPlugIn is AccessControl {
    bytes32 public constant ROLE_REQUEST = keccak256("ROLE_REQUEST");

    address internal mainVault;

    event SetMainVault(address indexed mainVault);
    event RequestToken(
        address indexed tokenAddress,
        uint256 indexed tokenAmount,
        address indexed mainVault
    );

    constructor(address _mainVault) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        mainVault = _mainVault;
        emit SetMainVault(_mainVault);
    }

    function setMainVault(
        address _mainVault
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        mainVault = _mainVault;

        emit SetMainVault(_mainVault);
    }

    function request(
        address tokenAddress,
        uint256 tokenAmount
    ) internal virtual onlyRole(ROLE_REQUEST) {
        IMainVault(mainVault).transfer(tokenAddress, tokenAmount);

        emit RequestToken(tokenAddress, tokenAmount, mainVault);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../plugins/DappOSLargeVault.sol";
import "@layerzerolabs/solidity-examples/contracts/mocks/LZEndpointMock.sol";

// contract LZEndpointMock

contract TestLZAdapter is LZAdapter {
    constructor(address _endpoint) LZAdapter(_endpoint) {}

    function sendDigest(
        address owner,
        address receiver,
        address wallet,
        IPayDB.CreatePayOrderParam[] memory cParams,
        bytes32 dataHash
    ) external payable {
        _sendToLayerZero(owner, receiver, wallet, cParams, dataHash);
    }

    function verifyDigest(bytes32 digest) external {
        require(_verifyLzMessage(digest), "E16");
    }
}
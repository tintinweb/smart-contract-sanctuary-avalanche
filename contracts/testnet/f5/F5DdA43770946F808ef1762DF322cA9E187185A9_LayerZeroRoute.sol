//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./LayerZeroModifiers.sol";
import "./LayerZeroAdmin.sol";
import "./LayerZeroEvents.sol";
import "../interfaces/IRoute.sol";

contract LayerZeroRoute is
    LayerZeroModifiers,
    LayerZeroAdmin,
    IRoute
{
    constructor(
        IMiddleLayer newMiddleLayer,
        ILayerZeroEndpoint _layerZeroEndpoint
    ) {
        owner = msg.sender;
        middleLayer = newMiddleLayer;
        layerZeroEndpoint = _layerZeroEndpoint;
    }

    function translateToCustom(
        uint256 chainId
    ) internal view returns (uint16 cid) {
        return cids[chainId];
    }

    function translateToStandard(
        uint16 cid
    ) internal view returns (uint256 chainId) {
        return chainIds[cid];
    }

    function lzReceive(
        uint16 _srcChainId,
        bytes calldata _fromAddress,
        uint64, /* _nonce */
        bytes memory _payload
    ) external onlyLZ() onlySrc(translateToStandard(_srcChainId), _fromAddress) {

        emit Receive(
            "LayerZero",
            _srcChainId,
            translateToStandard(_srcChainId),
            _fromAddress,
            _payload
        );

        middleLayer.mreceive(
            translateToStandard(_srcChainId),
            _payload
        );
    }

    function msend(
        uint256 _dstChainId,
        bytes memory params,
        address payable _refundAddress
    ) external override payable onlyMid() {

        emit Send(
            "LayerZero",
            translateToCustom(_dstChainId),
            abi.encodePacked(srcContracts[_dstChainId]), // send to this address on the destination
            params, // bytes payload
            _refundAddress, // refund address
            address(0), // future parameter
            new bytes(0)
        );

        layerZeroEndpoint.send{value: msg.value}(
            translateToCustom(_dstChainId),
            abi.encodePacked(srcContracts[_dstChainId]), // send to this address on the destination
            params, // bytes payload
            _refundAddress, // refund address
            address(0), // future parameter
            new bytes(0)
        );
    }

    fallback() external payable {}
    receive() external payable {}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./LayerZeroStorage.sol";

abstract contract LayerZeroModifiers is LayerZeroStorage {
    modifier onlyLZ() {
        require(msg.sender == address(layerZeroEndpoint), "ONLY_LZ");
        _;
    }

    // slither-disable-next-line assembly
    modifier onlySrc(uint256 srcChain, bytes memory _srcAddr) {
        address srcAddr;
        assembly {
            srcAddr := mload(add(20, _srcAddr))
        }
        require(
            srcContracts[srcChain] == address(srcAddr),
            "UNAUTHORIZED_CONTRACT"
        );
        _;
    }

    modifier onlyMid() {
        require(msg.sender == address(middleLayer), "ONLY_MID");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./LayerZeroModifiers.sol";
import "./LayerZeroEvents.sol";


abstract contract LayerZeroAdmin is LayerZeroModifiers, LayerZeroEvents {
    function addSrc(uint256 srcChain, address newSrcAddr) external onlyOwner() {
        srcContracts[srcChain] = newSrcAddr;

        emit AddSrc(srcChain, newSrcAddr);
    }

    function addTranslation(
        uint16 customId, uint256 standardId
    ) external {
        cids[standardId] = customId;
        chainIds[customId] = standardId;

        emit AddTranslation(customId, standardId);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract LayerZeroEvents {

    event Receive(
        string router,
        uint16 srcChainId,
        uint256 translatedChainId,
        bytes fromAddress,
        bytes payload
    );

    event Send(
        string router,
        uint16 chainId,
        bytes destination,
        bytes payload,
        address refundAddress,
        address zroPaymentAddress,
        bytes adapterParams
    );

    event AddSrc(
        uint256 srcChain,
        address newSrcAddr
    );

    event AddTranslation(
         uint16 customId,
         uint256 standardId
    );
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IRoute {
    function msend(
        uint256 _dstChainId,
        bytes memory params,
        address payable _refundAddress
    ) external payable;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/ILayerZeroReceiver.sol";
import "./interfaces/ILayerZeroEndpoint.sol";
import "../../interfaces/IMiddleLayer.sol";

abstract contract LayerZeroStorage {
    address internal owner;
    IMiddleLayer internal middleLayer;
    ILayerZeroEndpoint internal layerZeroEndpoint;

    // routers to call to on other chain ids
    mapping(uint256 => address) internal srcContracts;
    mapping(uint256 => uint16) internal cids;
    mapping(uint16 => uint256) internal chainIds;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

interface ILayerZeroReceiver {
    /// @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    /// @param _srcChainId - the source endpoint identifier
    /// @param _srcAddress - the source sending contract address from the source chain
    /// @param _nonce - the ordered message nonce
    /// @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "./ILayerZeroUserApplicationConfig.sol";

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    /// @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    /// @param _dstChainId - the destination chain identifier
    /// @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    /// @param _payload - a custom bytes payload to send to the destination contract
    /// @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    /// @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    /// @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(
        uint16 _dstChainId,
        bytes calldata _destination,
        bytes calldata _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    ) external payable;

    /// @notice used by the messaging library to publish verified payload
    /// @param _srcChainId - the source chain identifier
    /// @param _srcAddress - the source contract (as bytes) at the source chain
    /// @param _dstAddress - the address on destination chain
    /// @param _nonce - the unbound message ordering nonce
    /// @param _gasLimit - the gas limit for external contract execution
    /// @param _payload - verified payload to send to the destination contract
    function receivePayload(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        address _dstAddress,
        uint64 _nonce,
        uint256 _gasLimit,
        bytes calldata _payload
    ) external;

    /// @notice get the inboundNonce of a receiver from a source chain which could be EVM or non-EVM chain
    /// @param _srcChainId - the source chain identifier
    /// @param _srcAddress - the source chain contract address
    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress)
        external
        view
        returns (uint64);

    /// @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    /// @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainId, address _srcAddress)
        external
        view
        returns (uint64);

    /// @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    /// @param _dstChainId - the destination chain identifier
    /// @param _userApplication - the user app address on this EVM chain
    /// @param _payload - the custom message to send over LayerZero
    /// @param _payInZRO - if false, user app pays the protocol fee in native token
    /// @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(
        uint16 _dstChainId,
        address _userApplication,
        bytes calldata _payload,
        bool _payInZRO,
        bytes calldata _adapterParam
    ) external view returns (uint256 nativeFee, uint256 zroFee);

    /// @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    /// @notice the interface to retry failed message on this Endpoint destination
    /// @param _srcChainId - the source chain identifier
    /// @param _srcAddress - the source chain contract address
    /// @param _payload - the payload to be retried
    function retryPayload(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        bytes calldata _payload
    ) external;

    /// @notice query if any STORED payload (message blocking) at the endpoint.
    /// @param _srcChainId - the source chain identifier
    /// @param _srcAddress - the source chain contract address
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress)
        external
        view
        returns (bool);

    /// @notice query if the _libraryAddress is valid for sending msgs.
    /// @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(address _userApplication)
        external
        view
        returns (address);

    /// @notice query if the _libraryAddress is valid for receiving msgs.
    /// @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(address _userApplication)
        external
        view
        returns (address);

    /// @notice query if the non-reentrancy guard for send() is on
    /// @return true if the guard is on. false otherwise
    function isSendingPayload() external view returns (bool);

    /// @notice query if the non-reentrancy guard for receive() is on
    /// @return true if the guard is on. false otherwise
    function isReceivingPayload() external view returns (bool);

    /// @notice get the configuration of the LayerZero messaging library of the specified version
    /// @param _version - messaging library version
    /// @param _chainId - the chainId for the pending config change
    /// @param _userApplication - the contract address of the user application
    /// @param _configType - type of configuration. every messaging library has its own convention.
    function getConfig(
        uint16 _version,
        uint16 _chainId,
        address _userApplication,
        uint256 _configType
    ) external view returns (bytes memory);

    /// @notice get the send() LayerZero messaging library version
    /// @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication)
        external
        view
        returns (uint16);

    /// @notice get the lzReceive() LayerZero messaging library version
    /// @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication)
        external
        view
        returns (uint16);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract IMiddleLayer {
    /**
     * @notice routes and encodes messages for you
     * @param params - abi.encode() of the struct related to the selector, used to generate _payload
     * all params starting with '_' are directly sent to the lz 'send()' function
     */
    function msend(
        uint256 _dstChainId,
        bytes memory params,
        address payable _refundAddress,
        address fallbackAddress
    ) external payable virtual;

    function mreceive(
        uint256 _srcChainId,
        bytes memory payload
    ) external virtual;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

interface ILayerZeroUserApplicationConfig {
    /// @notice set the configuration of the LayerZero messaging library of the specified version
    /// @param _version - messaging library version
    /// @param _chainId - the chainId for the pending config change
    /// @param _configType - type of configuration. every messaging library has its own convention.
    /// @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(
        uint16 _version,
        uint16 _chainId,
        uint256 _configType,
        bytes calldata _config
    ) external;

    /// @notice set the send() LayerZero messaging library version to _version
    /// @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    /// @notice set the lzReceive() LayerZero messaging library version to _version
    /// @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    /// @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    /// @param _srcChainId - the chainId of the source chain
    /// @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress)
        external;
}
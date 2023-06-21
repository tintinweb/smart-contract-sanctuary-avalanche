// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Utils.sol";

/**
 * @dev Interface of the Gateway Self External Calls.
 */
interface IGateway {
    // requestMetadata = abi.encodePacked(
    //     uint256 destGasLimit;
    //     uint256 destGasPrice;
    //     uint256 ackGasLimit;
    //     uint256 ackGasPrice;
    //     uint256 relayerFees;
    //     uint8 ackType;
    //     bool isReadCall;
    //     bytes asmAddress;
    // )

    function iSend(
        uint256 version,
        uint256 routeAmount,
        string calldata routeRecipient,
        string calldata destChainId,
        bytes calldata requestMetadata,
        bytes calldata requestPacket
    ) external payable returns (uint256);

    function setDappMetadata(string memory feePayerAddress) external payable returns (uint256);

    function currentVersion() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

library Utils {
    // This is used purely to avoid stack too deep errors
    // represents everything about a given validator set
    struct ValsetArgs {
        // the validators in this set, represented by an Ethereum address
        address[] validators;
        // the powers of the given validators in the same order as above
        uint64[] powers;
        // the nonce of this validator set
        uint256 valsetNonce;
    }

    struct RequestPayload {
        uint256 routeAmount;
        uint256 requestIdentifier;
        uint256 requestTimestamp;
        string srcChainId;
        address routeRecipient;
        string destChainId;
        address asmAddress;
        string requestSender;
        address handlerAddress;
        bytes packet;
        bool isReadCall;
    }

    struct CrossChainAckPayload {
        uint256 requestIdentifier;
        uint256 ackRequestIdentifier;
        string destChainId;
        address requestSender;
        bytes execData;
        bool execFlag;
    }

    enum AckType {
        NO_ACK,
        ACK_ON_SUCCESS,
        ACK_ON_ERROR,
        ACK_ON_BOTH
    }

    error IncorrectCheckpoint();
    error InvalidValsetNonce(uint256 newNonce, uint256 currentNonce);
    error MalformedNewValidatorSet();
    error MalformedCurrentValidatorSet();
    error InsufficientPower(uint64 cumulativePower, uint64 powerThreshold);
    error InvalidSignature();
    // constants
    string constant MSG_PREFIX = "\x19Ethereum Signed Message:\n32";
    // The number of 'votes' required to execute a valset
    // update or batch execution, set to 2/3 of 2^32
    uint64 constant CONSTANT_POWER_THRESHOLD = 2791728742;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

import "@routerprotocol/evm-gateway-contracts/contracts/IGateway.sol";

interface IMultiplication {
  function getResult(uint256 num) external view returns (uint256);
}

contract ReadCall {
    IGateway public gatewayContract;
    address public owner;
    uint256 public value;

    event ReceivedData( uint256 value);

    constructor(
        address payable gatewayAddress,
        string memory feePayerAddress
    ) {
        owner = msg.sender;
        gatewayContract = IGateway(gatewayAddress);

        gatewayContract.setDappMetadata(feePayerAddress);
    }

    /// @notice function to set the fee payer address on Router Chain.
    /// @param feePayerAddress address of the fee payer on Router Chain.
    function setDappMetadata(string memory feePayerAddress) external {
        require(msg.sender == owner, "only owner");
        gatewayContract.setDappMetadata(feePayerAddress);
    }

    /// @notice function to set the Router Gateway Contract.
    /// @param gateway address of the Gateway contract.
    function setGateway(address gateway) external {
        require(msg.sender == owner, "only owner");
        gatewayContract = IGateway(gateway);
    }

    /// @notice function to get the request metadata to be used while initiating cross-chain request
    /// @return requestMetadata abi-encoded metadata according to source and destination chains
    function getRequestMetadata(
      uint64 destGasLimit,
      uint64 destGasPrice,
      uint64 ackGasLimit,
      uint64 ackGasPrice,
      uint128 relayerFees,
      uint8 ackType,
      bool isReadCall,
      bytes memory asmAddress
      ) public pure returns (bytes memory) {
      bytes memory requestMetadata = abi.encodePacked(
          destGasLimit,
          destGasPrice,
          ackGasLimit,
          ackGasPrice,
          relayerFees,
          ackType,
          isReadCall,
          asmAddress
      );
      return requestMetadata;
    }

    function sendReadRequest(
        string calldata destChainId,
        string calldata destinationContractAddress,
        bytes calldata requestMetadata,
        uint256 _value
    ) public payable {
        bytes memory packet = abi.encodeCall(IMultiplication.getResult, (_value));
        bytes memory requestPacket = abi.encode(destinationContractAddress, packet);

        gatewayContract.iSend{ value: msg.value }(
          1,
          0,
          string(""),
          destChainId,
          requestMetadata,
          requestPacket
        );
    }

    function iAck(
      uint256 ,//requestIdentifier,
      bool ,//execFlag,
      bytes memory execData
    ) external {
      value = abi.decode(execData, (uint256));

      emit ReceivedData( value);
    }
}
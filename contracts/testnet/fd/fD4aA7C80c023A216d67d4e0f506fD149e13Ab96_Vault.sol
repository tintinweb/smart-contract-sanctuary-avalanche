// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @dev Interface of the Gateway Self External Calls.
 */
interface IApplication {
    function handleRequestFromRouter(string memory sender, bytes memory payload) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Utils.sol";

/**
 * @dev Interface of the Gateway Self External Calls.
 */
interface IGateway {
    function requestToRouter(
        uint256 routeAmount,
        string memory routeRecipient,
        bytes memory payload,
        string memory routerBridgeContract,
        uint256 gasLimit,
        bytes memory asmAddress
    ) external payable returns (uint64);

    function setDappMetadata(string memory feePayerAddress) external payable returns (uint64);

    function executeHandlerCalls(
        string memory sender,
        bytes[] memory handlers,
        bytes[] memory payloads,
        bool isAtomic
    ) external returns (bool[] memory, bytes[] memory);

    function requestToDest(
        Utils.RequestArgs memory requestArgs,
        Utils.AckType ackType,
        Utils.AckGasParams memory ackGasParams,
        Utils.DestinationChainParams memory destChainParams,
        Utils.ContractCalls memory contractCalls
    ) external payable returns (uint64);

    function readQueryToDest(
        Utils.RequestArgs memory requestArgs,
        Utils.AckGasParams memory ackGasParams,
        Utils.DestinationChainParams memory destChainParams,
        Utils.ContractCalls memory contractCalls
    ) external payable returns (uint64);

    function requestToRouterDefaultFee() external view returns (uint256 fees);

    function requestToDestDefaultFee() external view returns (uint256 fees);
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
        uint64 valsetNonce;
    }

    // This is being used purely to avoid stack too deep errors
    struct RouterRequestPayload {
        //route
        uint256 routeAmount;
        bytes routeRecipient;
        // the sender address
        string routerBridgeAddress;
        string relayerRouterAddress;
        bool isAtomic;
        uint64 chainTimestamp;
        uint64 expTimestamp;
        // The user contract address
        bytes asmAddress;
        bytes[] handlers;
        bytes[] payloads;
        uint64 outboundTxNonce;
    }

    struct AckGasParams {
        uint64 gasLimit;
        uint64 gasPrice;
    }

    struct InboundSourceInfo {
        uint256 routeAmount;
        string routeRecipient;
        uint64 eventNonce;
        uint64 srcChainType;
        string srcChainId;
    }

    struct SourceChainParams {
        uint64 crossTalkNonce;
        uint64 expTimestamp;
        bool isAtomicCalls;
        uint64 chainType;
        string chainId;
    }
    struct SourceParams {
        bytes caller;
        uint64 chainType;
        string chainId;
    }

    struct DestinationChainParams {
        uint64 gasLimit;
        uint64 gasPrice;
        uint64 destChainType;
        string destChainId;
        bytes asmAddress;
    }

    struct RequestArgs {
        uint64 expTimestamp;
        bool isAtomicCalls;
    }

    struct ContractCalls {
        bytes[] payloads;
        bytes[] destContractAddresses;
    }

    struct CrossTalkPayload {
        string relayerRouterAddress;
        bool isAtomic;
        uint64 eventIdentifier;
        uint64 chainTimestamp;
        uint64 expTimestamp;
        uint64 crossTalkNonce;
        bytes asmAddress;
        SourceParams sourceParams;
        ContractCalls contractCalls;
        bool isReadCall;
    }

    struct CrossTalkAckPayload {
        string relayerRouterAddress;
        uint64 crossTalkNonce;
        uint64 eventIdentifier;
        uint64 destChainType;
        string destChainId;
        bytes srcContractAddress;
        bool[] execFlags;
        bytes[] execData;
    }

    // This represents a validator signature
    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    enum AckType {
        NO_ACK,
        ACK_ON_SUCCESS,
        ACK_ON_ERROR,
        ACK_ON_BOTH
    }

    error IncorrectCheckpoint();
    error InvalidValsetNonce(uint64 newNonce, uint64 currentNonce);
    error MalformedNewValidatorSet();
    error MalformedCurrentValidatorSet();
    error InsufficientPower(uint64 cumulativePower, uint64 powerThreshold);
    error InvalidSignature();
    // constants
    string constant MSG_PREFIX = "\x19Ethereum Signed Message:\n32";
    // The number of 'votes' required to execute a valset
    // update or batch execution, set to 2/3 of 2^32
    uint64 constant constantPowerThreshold = 2791728742;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@routerprotocol/evm-gateway-contracts/contracts/IGateway.sol";
import "@routerprotocol/evm-gateway-contracts/contracts/IApplication.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Vault is IApplication {
    IGateway public gateway;
    //can create mapping of whitelisted middlewareContract but
    //for current usecase this variable can work.
    string public middlewareContract;

    constructor(address gatewayAddress, string memory _middlewareContract) {
        gateway = IGateway(gatewayAddress);
        middlewareContract = _middlewareContract;
    }

    event XTransferEvent(
        address indexed sender,
        string indexed recipient,
        uint256 amount,
        string middlewareContract
    );
    event XSwapEvent(
        address indexed sender,
        uint256 amount,
        string middlewareContract
    );
    event UnlockEvent(address indexed recipient, uint256 amount);
    event xBuyEvent(
        address indexed sender,
        uint256 amount,
        string middlewareContract
    );

    //xTransfer function handles for locking of native token in this contract and
    //invoke call for minting on router chain
    //CONSTANT FEE DEDUCT
    //mapped id: 100
    function xTransfer(string memory recipient, uint64 rGasLimit) public payable {
        require(msg.value > 0, "no fund transferred to vault");
        bytes memory innerPayload = abi.encode(
            msg.value,
            msg.sender,
            recipient
        );
        bytes memory payload = abi.encode(100, innerPayload);
        gateway.requestToRouter(0, "", payload, middlewareContract, rGasLimit, "");
        emit XTransferEvent(
            msg.sender,
            recipient,
            msg.value,
            middlewareContract
        );
    }

    //xSwap function handles for locking of native token in this contract and
    //invoke call for swapping in router chain
    //CONSTANT FEE DEDUCT
    //mapped id: 101
    function xSwap(
        address recipient,
        string memory binaryPayload,
        address destVaultAddress,
         uint64 rGasLimit
    ) public payable {
        bytes memory innerPayload = abi.encode(
            msg.value,
            msg.sender,
            recipient,
            destVaultAddress,
            binaryPayload
        );
        bytes memory payload = abi.encode(101, innerPayload);
        gateway.requestToRouter(0, "", payload, middlewareContract, rGasLimit, "");
        emit XSwapEvent(msg.sender, msg.value, middlewareContract);
    }

    //ADMIN FUNC (REMOVING PERMISSION FOR TESTING PURPOSE)
    function updateMiddlewareContract(
        string memory newMiddlewareContract
    ) external {
        middlewareContract = newMiddlewareContract;
    }

    //handleRequestFromRouter handles incoming request from router chain
    function handleRequestFromRouter(
        string memory sender,
        bytes memory payload
    ) public {
        require(msg.sender == address(gateway));
        require(
            keccak256(abi.encode(sender)) ==
                keccak256(abi.encode(middlewareContract)),
            "The origin router bridge contract is different"
        );
        (address payable recipient, uint256 amount) = abi.decode(
            payload,
            (address, uint256)
        );
        _handleUnlock(recipient, amount);
    }

    //_handleUnlock function unlocks native token locked in contract
    function _handleUnlock(address payable recipient, uint256 amount) internal {
        (bool success, ) = recipient.call{value: amount}(new bytes(0));
        require(success, "Native transfer failed");
        emit UnlockEvent(recipient, amount);
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    receive() external payable {}
}
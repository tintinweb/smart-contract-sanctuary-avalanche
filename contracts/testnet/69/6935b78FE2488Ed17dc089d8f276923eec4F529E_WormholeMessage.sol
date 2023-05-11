// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}

// contracts/Messages.sol
// SPDX-License-Identifier: Apache 2

// taken from: import "https://github.com/wormhole-foundation/wormhole/blob/main/ethereum/contracts/interfaces/IWormhole.sol";

pragma solidity ^0.8.7;

interface IWormhole {
    struct GuardianSet {
        address[] keys;
        uint32 expirationTime;
    }

    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
        uint8 guardianIndex;
    }

    struct VM {
        uint8 version;
        uint32 timestamp;
        uint32 nonce;
        uint16 emitterChainId;
        bytes32 emitterAddress;
        uint64 sequence;
        uint8 consistencyLevel;
        bytes payload;
        uint32 guardianSetIndex;
        Signature[] signatures;
        bytes32 hash;
    }

    struct ContractUpgrade {
        bytes32 module;
        uint8 action;
        uint16 chain;
        address newContract;
    }

    struct GuardianSetUpgrade {
        bytes32 module;
        uint8 action;
        uint16 chain;
        GuardianSet newGuardianSet;
        uint32 newGuardianSetIndex;
    }

    struct SetMessageFee {
        bytes32 module;
        uint8 action;
        uint16 chain;
        uint256 messageFee;
    }

    struct TransferFees {
        bytes32 module;
        uint8 action;
        uint16 chain;
        uint256 amount;
        bytes32 recipient;
    }

    struct RecoverChainId {
        bytes32 module;
        uint8 action;
        uint256 evmChainId;
        uint16 newChainId;
    }

    event LogMessagePublished(
        address indexed sender,
        uint64 sequence,
        uint32 nonce,
        bytes payload,
        uint8 consistencyLevel
    );
    event ContractUpgraded(
        address indexed oldContract,
        address indexed newContract
    );
    event GuardianSetAdded(uint32 indexed index);

    function publishMessage(
        uint32 nonce,
        bytes memory payload,
        uint8 consistencyLevel
    ) external payable returns (uint64 sequence);

    function initialize() external;

    function parseAndVerifyVM(
        bytes calldata encodedVM
    ) external view returns (VM memory vm, bool valid, string memory reason);

    function verifyVM(
        VM memory vm
    ) external view returns (bool valid, string memory reason);

    function verifySignatures(
        bytes32 hash,
        Signature[] memory signatures,
        GuardianSet memory guardianSet
    ) external pure returns (bool valid, string memory reason);

    function parseVM(
        bytes memory encodedVM
    ) external pure returns (VM memory vm);

    function quorum(
        uint numGuardians
    ) external pure returns (uint numSignaturesRequiredForQuorum);

    function getGuardianSet(
        uint32 index
    ) external view returns (GuardianSet memory);

    function getCurrentGuardianSetIndex() external view returns (uint32);

    function getGuardianSetExpiry() external view returns (uint32);

    function governanceActionIsConsumed(
        bytes32 hash
    ) external view returns (bool);

    function isInitialized(address impl) external view returns (bool);

    function chainId() external view returns (uint16);

    function isFork() external view returns (bool);

    function governanceChainId() external view returns (uint16);

    function governanceContract() external view returns (bytes32);

    function messageFee() external view returns (uint256);

    function evmChainId() external view returns (uint256);

    function nextSequence(address emitter) external view returns (uint64);

    function parseContractUpgrade(
        bytes memory encodedUpgrade
    ) external pure returns (ContractUpgrade memory cu);

    function parseGuardianSetUpgrade(
        bytes memory encodedUpgrade
    ) external pure returns (GuardianSetUpgrade memory gsu);

    function parseSetMessageFee(
        bytes memory encodedSetMessageFee
    ) external pure returns (SetMessageFee memory smf);

    function parseTransferFees(
        bytes memory encodedTransferFees
    ) external pure returns (TransferFees memory tf);

    function parseRecoverChainId(
        bytes memory encodedRecoverChainId
    ) external pure returns (RecoverChainId memory rci);

    function submitContractUpgrade(bytes memory _vm) external;

    function submitSetMessageFee(bytes memory _vm) external;

    function submitNewGuardianSet(bytes memory _vm) external;

    function submitTransferFees(bytes memory _vm) external;

    function submitRecoverChainId(bytes memory _vm) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IWormhole.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

contract WormholeMessage is ConfirmedOwner {
    /// @notice A mapping to store the last message received from each sender address
    mapping(address => string) public lastMessage;

    /// @notice The core Wormhole contract instance
    IWormhole immutable core;

    /// @notice A mapping to store trusted contract addresses for different chains
    /// @dev The key is a bytes32 . Wormhole accepts messages from multiple types of protocols, not just EVMs
    mapping(bytes32 => mapping(uint256 => bool)) public myTrustedContracts;

    /// @notice A mapping to store processed message hashes to prevent replays
    mapping(bytes32 => bool) public processedMessages;

    /// @notice The connected blockchain network's chain ID
    uint256 immutable chainId;

    /// @notice A nonce to be used in the sendMessage function
    uint16 nonce = 0;

    /// @notice Custom error for when a VAA is not valid
    error NonValid(
        string reason,
        uint256 emitterChainId,
        address emitterAddress
    );

    /// @notice Custom error for when a contract is not trusted
    error NonTrustedContract(uint256 emitterChainId, address emitterAddress);

    /// @notice Custom error for when a message has already been processed
    error MessageAlreadyProcessed(
        bytes32 hash,
        uint256 emitterChainId,
        address emitterAddress
    );

    /// @notice Custom error for when the intended recipient is not the current recipient
    error NotIntendedRecipient(
        address intendedRecipient,
        address currentRecipient
    );

    /// @notice Custom error for when the intended chain is not the current chain
    error NotIntendedChain(uint256 intendedChainId, uint256 currentChainId);

    /**
     * @notice Emitted when a new message is received and processed
     * @param sender The address of the sender who sent the message
     * @param chainId The chain ID of the connected blockchain network
     * @param hash The unique hash of the message
     * @param message The content of the received message
     */
    event MessageReceived(
        address indexed sender,
        uint16 indexed chainId,
        bytes32 indexed hash,
        string message
    );

    // https://book.wormhole.com/reference/contracts.html
    // https://book.wormhole.com/reference/contracts.html#core-bridge-1

    /**
     * @notice Constructs a new Message instance
     * @param _chainId The chain ID of the connected blockchain network
     * @param _core The core bridge contract address
     */
    constructor(uint256 _chainId, address _core) ConfirmedOwner(msg.sender) {
        chainId = _chainId;
        core = IWormhole(_core);
    }

    /**
     * @notice Sends a message across chains to a specified target address
     * @param _message The message to be sent as a string
     * @param _target The target address on the receiving chain
     * @param _targetChainId The chain ID of the target blockchain network
     */
    function sendMessage(
        string calldata _message,
        address _target,
        uint256 _targetChainId
    ) external payable {
        // Wormhole recommends that message-publishing functions should return their sequence value
        _sendMessageToRecipient(_target, _targetChainId, _message, nonce);
        nonce++;
    }

    /**
     * @notice Sends a message to a recipient on a target chain using the Wormhole module
     * @dev A Wormhole module is a piece of code that emits composable messages that can be utilized by other contracts
     * @param _target The target address on the receiving chain
     * @param _targetChainId The chain ID of the target blockchain network
     * @param _message The message to be sent as a string in calldata format
     * @param _nonce The nonce used for message ordering and uniqueness
     * @return sequence The sequence number of the published message, which can be useful relay information
     */
    function _sendMessageToRecipient(
        address _target,
        uint256 _targetChainId,
        string calldata _message,
        uint32 _nonce
    ) private returns (uint64) {
        bytes memory payload = abi.encode(
            _target,
            _targetChainId,
            msg.sender,
            _message
        );

        // Nonce is passed though to the core bridge.
        // This allows other contracts to utilize it for batching or processing.

        // 1:  Required number of block confirmations to assume finality
        uint64 sequence = core.publishMessage(_nonce, payload, 1);

        // The sequence is passed back to the caller, which can be useful relay information.
        // Relaying is not done here, because it would 'lock' others into the same relay mechanism.
        return sequence;
    }

    /**
     * @notice Converts an address type to a bytes32 type
     * @param _input The address to be converted
     * @return _output The resulting bytes32 representation of the input address
     */
    function addressToBytes32(
        address _input
    ) public pure returns (bytes32 _output) {
        return bytes32(uint256(uint160(_input)));
    }

    /**
     * @notice Converts a bytes32 type to an address type
     * @param _input The bytes32 value to be converted
     * @return _output The resulting address representation of the input bytes32 value
     */

    function bytes32ToAddress(
        bytes32 _input
    ) public pure returns (address _output) {
        return address(uint160(uint256(_input)));
    }

    /**
     * @notice Adds a whitelisted contract to the trusted contracts mapping. You can call `addressToBytes32` to convert an address to bytes32
     * @param _sender The sender address as bytes32, since Wormhole's VAAs provide emitter addresses in bytes32 format
     * @param _chainId The chain ID of the connected blockchain network
     */
    function addTrustedAddress(
        bytes32 _sender,
        uint256 _chainId
    ) external onlyOwner {
        myTrustedContracts[_sender][_chainId] = true;
    }

    /**
     * @notice Processes a message from the input VAA and stores the message in the contract
     * @dev This function accepts single VAAs and headless VAAs
     * @param VAA The input VAA containing the message to be processed
     */
    function processMyMessage(bytes memory VAA) public {
        // This call accepts single VAAs and headless VAAs
        (IWormhole.VM memory vm, bool valid, string memory reason) = core
            .parseAndVerifyVM(VAA);

        bytes32 emitterAddress = vm.emitterAddress;
        uint16 emitterChainId = vm.emitterChainId;

        // Ensure core contract verifies the VAA
        if (!valid)
            revert NonValid(
                reason,
                emitterChainId,
                bytes32ToAddress(emitterAddress)
            );

        // Ensure the emitterAddress of this VAA is a trusted address
        if (!myTrustedContracts[emitterAddress][emitterChainId])
            revert NonTrustedContract(
                emitterChainId,
                bytes32ToAddress(emitterAddress)
            );

        // Check that the VAA hasn't already been processed (replay protection)
        if (processedMessages[vm.hash])
            revert MessageAlreadyProcessed(
                vm.hash,
                emitterChainId,
                bytes32ToAddress(emitterAddress)
            );

        // Parse intended data
        (
            address intendedRecipient,
            uint256 intendedChainId,
            address sender,
            string memory message
        ) = abi.decode(vm.payload, (address, uint256, address, string));

        // Check that the contract which is processing this VAA is the intendedRecipient
        // If the two aren't equal, this VAA may have bypassed its intended entrypoint.
        // This exploit is referred to as 'scooping'.
        if (!(intendedRecipient == address(this)))
            revert NotIntendedRecipient(intendedRecipient, address(this));

        // Check that the contract that is processing this VAA is the intended chain.
        // By default, a message is accessible by all chains, so we have to define a destination chain & check for it.
        if (!(intendedChainId == chainId))
            revert NotIntendedChain(intendedChainId, chainId);

        // Add the VAA to processed messages so it can't be replayed
        processedMessages[vm.hash] = true;

        // The message content can now be trusted, slap into messages
        lastMessage[sender] = message;

        emit MessageReceived(sender, emitterChainId, vm.hash, message);
    }
}
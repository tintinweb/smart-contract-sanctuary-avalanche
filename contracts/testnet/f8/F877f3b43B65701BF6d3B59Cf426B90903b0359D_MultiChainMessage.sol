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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

interface CallProxy {
    function anyCall(
        address _to,
        bytes calldata _data,
        uint256 _toChainID,
        uint256 _flags,
        bytes calldata _extdata
    ) external payable;

    function context()
        external
        view
        returns (address from, uint256 fromChainID, uint256 nonce);

    function executor() external view returns (address executor);
}

contract MultiChainMessage is ConfirmedOwner {
    address public anycallcontract;
    address public anycallExecutor;

    address public owneraddress;

    address public verifiedcaller;

    string public responseValue;
    uint256 public responseSourceChain;
    address public responseSourceAddress;

    event MessageSent(string msg);
    event MessageReceived(string msg);

    modifier onlyExecutor() {
        require(msg.sender == anycallExecutor, "onlyExecutor");
        _;
    }

    constructor(address _anycallcontract) ConfirmedOwner(msg.sender) {
        anycallcontract = _anycallcontract;
        owneraddress = msg.sender;
        anycallExecutor = CallProxy(anycallcontract).executor();
    }

    function changeverifiedcaller(address _contractcaller) external onlyOwner {
        verifiedcaller = _contractcaller;
    }

    function sendMessage(
        string calldata _message,
        address receivercontract,
        uint256 destchain
    ) external payable {
        emit MessageSent(_message);
        if (msg.sender == owneraddress) {
            CallProxy(anycallcontract).anyCall{value: msg.value}(
                receivercontract,
                // sending the encoded bytes of the string msg and decode on the destination chain
                abi.encode(_message),
                destchain,
                // Using 0 flag to pay fee on the source chain
                0,
                ""
            );
        }
    }

    event ContextEvent(address indexed _from, uint256 indexed _fromChainId);

    // anyExecute has to be role controlled by onlyMPC so it's only called by MPC
    function anyExecute(
        bytes memory _data
    ) external onlyExecutor returns (bool success, bytes memory result) {
        string memory _msg = abi.decode(_data, (string));
        (address from, uint256 fromChainId, ) = CallProxy(anycallExecutor)
            .context();
        require(verifiedcaller == from, "AnycallClient: wrong context");
        responseValue = _msg;
        responseSourceAddress = from;
        responseSourceChain = fromChainId;
        emit MessageReceived(_msg);
        emit ContextEvent(from, fromChainId);
        success = true;
        result = "";
    }

    function checkContext()
        external
        view
        returns (address, address, uint256, uint256)
    {
        (address from, uint256 fromChainId, uint256 nonce) = CallProxy(
            anycallExecutor
        ).context();

        return (anycallExecutor, from, fromChainId, nonce);
    }
}
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../Collector.sol";

contract TestCollector is Collector {
    constructor(
        ILayerZeroEndpoint lzEndpoint_,
        uint16 destinationChainId_,
        IERC721 collectableBox_,
        uint256 startTime_,
        uint256 endTime_
    ) Collector(lzEndpoint_, destinationChainId_, collectableBox_, startTime_, endTime_) {}

    function changeStartTime(uint256 startTime_) public onlyOwner {
        startTime = startTime_;
    }

    function changeEndTime(uint256 endTime_) public onlyOwner {
        endTime = endTime_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/ILayerZeroEndpoint.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Collector is Ownable {
    ILayerZeroEndpoint internal _lzEndpoint;
    IERC721 public immutable collectableBox;

    uint16 public immutable destinationChainId;
    bytes public destinationContract;
    uint256 public startTime;
    uint256 public endTime;

    mapping(uint256 => address) public collected;

    error CollectableBoxNotExist(uint256 tokenId);
    error CollectableBoxNotYours(uint256 tokenId);
    error CollectableBoxNotApproved(uint256 tokenId);
    error DestinationContractAlreadySet();
    error InsufficientFee();
    error UnorderedTokenIds();
    error NoTokenIdPassed();
    error ReceiverIsZeroAddress();
    error ContractNotActive();
    error TimestampLessThanEndTime();

    event BoxCollected(uint256[] tokenIds, address owner, address receiver);
    event DeadlineExtended(uint256 endTime);

    modifier onlyWhenActive() {
        if (block.timestamp < startTime || block.timestamp > endTime) revert ContractNotActive();
        _;
    }

    constructor(
        ILayerZeroEndpoint lzEndpoint_,
        uint16 destinationChainId_,
        IERC721 collectableBox_,
        uint256 startTime_,
        uint256 endTime_
    ) {
        require(startTime_ < endTime_, "Start time less than end time");
        collectableBox = collectableBox_;
        _lzEndpoint = lzEndpoint_;
        destinationChainId = destinationChainId_;
        startTime = startTime_;
        endTime = endTime_;
    }

    function setDestinationContract(address destinationContract_) public onlyOwner {
        if (destinationContract.length != 0) revert DestinationContractAlreadySet();
        destinationContract = abi.encodePacked(destinationContract_);
    }

    function collectBox(uint256[] calldata tokenIds_) public payable onlyWhenActive {
        _collectBox(tokenIds_);

        // send owner and token id to mainnet using layer zero
        bytes memory payload = _getPayload(msg.sender, tokenIds_);
        uint16 version = 1;
        uint256 lzGas = getLzGasFee(tokenIds_.length);
        bytes memory adapterParams = abi.encodePacked(version, lzGas);
        (uint256 fee, ) = _lzEndpoint.estimateFees(destinationChainId, address(this), payload, false, adapterParams);
        if (msg.value < fee) revert InsufficientFee();
        _lzSend(payload, payable(msg.sender), adapterParams);

        // emit the event
        emit BoxCollected(tokenIds_, msg.sender, msg.sender);
    }

    function collectBox(address receiver_, uint256[] calldata tokenIds_) public payable onlyWhenActive {
        if (receiver_ == address(0)) revert ReceiverIsZeroAddress();

        _collectBox(tokenIds_);

        // send owner and token id to mainnet using layer zero
        bytes memory payload = _getPayload(receiver_, tokenIds_);
        uint16 version = 1;
        uint256 lzGas = getLzGasFee(tokenIds_.length);
        bytes memory adapterParams = abi.encodePacked(version, lzGas);
        (uint256 fee, ) = _lzEndpoint.estimateFees(destinationChainId, address(this), payload, false, adapterParams);
        if (msg.value < fee) revert InsufficientFee();
        _lzSend(payload, payable(msg.sender), adapterParams);

        // emit the event
        emit BoxCollected(tokenIds_, msg.sender, receiver_);
    }

    function _collectBox(uint256[] calldata tokenIds_) internal {
        if (tokenIds_.length == 0) revert NoTokenIdPassed();

        bool isApprovedForAll = collectableBox.isApprovedForAll(msg.sender, address(this));

        // check order, owners and collected status
        uint256 last = 750;
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            if (collected[tokenIds_[i]] != address(0) || tokenIds_[i] >= 750)
                revert CollectableBoxNotExist(tokenIds_[i]);
            if (last != 750 && last >= tokenIds_[i]) revert UnorderedTokenIds();
            last = tokenIds_[i];

            // check if the caller is the owner of the collectable box
            if (collectableBox.ownerOf(tokenIds_[i]) != msg.sender) revert CollectableBoxNotYours(tokenIds_[i]);
            if (!isApprovedForAll && collectableBox.getApproved(tokenIds_[i]) != address(this))
                revert CollectableBoxNotApproved(tokenIds_[i]);
        }

        // update the state variables and transfer the tokens to this contract
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            // update the collected status for this box
            collected[tokenIds_[i]] = msg.sender;

            // lock the collectable box in this contract
            collectableBox.transferFrom(msg.sender, address(this), tokenIds_[i]);
        }
    }

    function _lzSend(
        bytes memory _payload,
        address payable _refundAddress,
        bytes memory _txParam
    ) internal {
        // solhint-disable-next-line check-send-result
        _lzEndpoint.send{value: msg.value}(
            destinationChainId,
            destinationContract,
            _payload,
            _refundAddress,
            address(0),
            _txParam
        );
    }

    function _getPayload(address owner_, uint256[] calldata tokenIds_) internal pure returns (bytes memory) {
        return abi.encode(owner_, tokenIds_);
    }

    function getLzGasFee(uint256 numberOfTokens_) public pure returns (uint256) {
        return 52000 * numberOfTokens_ + 65000;
    }

    function estimateFees(address owner_, uint256[] calldata tokenIds_) public view returns (uint256 fee) {
        if (tokenIds_.length == 0) revert NoTokenIdPassed();

        // check order and collected status
        uint256 last = 750;
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            if (collected[tokenIds_[i]] != address(0) || tokenIds_[i] >= 750)
                revert CollectableBoxNotExist(tokenIds_[i]);
            if (last != 750 && last >= tokenIds_[i]) revert UnorderedTokenIds();
            last = tokenIds_[i];
        }

        // get payload for the layerzero message
        bytes memory payload = _getPayload(owner_, tokenIds_);

        // encode adapterParams to specify more gas for the destination
        uint16 version = 1;
        uint256 lzGas = getLzGasFee(tokenIds_.length);
        bytes memory adapterParams = abi.encodePacked(version, lzGas);

        // call the estimateFees function to the layerzero endpoint
        (fee, ) = _lzEndpoint.estimateFees(destinationChainId, address(this), payload, false, adapterParams);
    }

    function extendDeadline(uint256 timestamp_) public onlyOwner {
        if (timestamp_ < endTime) revert TimestampLessThanEndTime();
        endTime = timestamp_;
        emit DeadlineExtended(timestamp_);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "./ILayerZeroUserApplicationConfig.sol";

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(
        uint16 _dstChainId,
        bytes calldata _destination,
        bytes calldata _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    ) external payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        address _dstAddress,
        uint64 _nonce,
        uint256 _gasLimit,
        bytes calldata _payload
    ) external;

    // @notice get the inboundNonce of a receiver from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress)
        external
        view
        returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainId, address _srcAddress)
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
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        bytes calldata _payload
    ) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress)
        external
        view
        returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(address _userApplication)
        external
        view
        returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(address _userApplication)
        external
        view
        returns (address);

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
    function getConfig(
        uint16 _version,
        uint16 _chainId,
        address _userApplication,
        uint256 _configType
    ) external view returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication)
        external
        view
        returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication)
        external
        view
        returns (uint16);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(
        uint16 _version,
        uint16 _chainId,
        uint256 _configType,
        bytes calldata _config
    ) external;

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress)
        external;
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
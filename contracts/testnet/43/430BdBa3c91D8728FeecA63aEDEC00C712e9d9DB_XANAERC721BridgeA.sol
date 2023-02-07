/**
 *Submitted for verification at testnet.snowtrace.io on 2023-02-06
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity =0.8.17;

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


// File @openzeppelin/contracts/token/ERC721/[email protected]
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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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


// File @openzeppelin/contracts/token/ERC721/[email protected]
/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


// File contracts/sourceChainBridge.sol
contract XANAERC721BridgeA {
    constructor() {
        owner = msg.sender;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    address public owner;
    uint256 public depositId;
    uint256 public depositLimit = 5;
    uint256 public bridgeFee = 1 ether;
    mapping(uint256 => bool) public supportedChains;
    mapping(address => bool) public supportedCollections;

    // collection>nftId>status of deposit/release
    mapping(address => mapping(uint256 => depositData)) public nftDeposits;

    struct depositData {
        bool _deposited;
        bool _released;
        uint256 _targetChainId;
    }

    event Release(address owner, address collection, uint256 nftId, uint256 targetChainId);
    event Deposit(address owner, address collection, uint256 nftId, uint256 depositId, uint256 targetChainId);

    modifier onlyOwner {
        require(msg.sender == owner, "caller is not owner");
        _;
    }

    function deposit(address _collection, uint256[] calldata _nftIds, uint256 _targetChainId) public payable {
        for (uint256 i=0; i < _nftIds.length; i++) {
            require(msg.value >= bridgeFee, "required fee not sent");
            require(supportedChains[_targetChainId], "chain not supported");
            require(supportedCollections[_collection], "collection not supported");
            require(!nftDeposits[_collection][_nftIds[i]]._deposited, "nft already deposited");

            IERC721(_collection).safeTransferFrom(msg.sender, address(this), _nftIds[i]);
            nftDeposits[_collection][_nftIds[i]] = depositData(true, false, _targetChainId);

            depositId++;
            emit Deposit(msg.sender, _collection, _nftIds[i], depositId, _targetChainId);
        }

        // send remaining ether back
        if (msg.value > (bridgeFee * _nftIds.length)) {
            (bool sent,) = msg.sender.call{value: msg.value - (bridgeFee * _nftIds.length)}("");
            require(sent, "failed to return extra value");
        }
    }

    function releaseNft(address _user, address _collection, uint256 _nftId, uint256 _targetChainId) public onlyOwner {
        require(!nftDeposits[_collection][_nftId]._released, "nft already released");
        require(nftDeposits[_collection][_nftId]._targetChainId == _targetChainId, "taget chain not matched");

        IERC721(_collection).safeTransferFrom(address(this), _user, _nftId);
        nftDeposits[_collection][_nftId]._deposited = false;
        nftDeposits[_collection][_nftId]._released = true;
    }

    function bulkRelease(address _user, address _collection, uint256[] calldata _nftIds, uint256 _targetChainId) external onlyOwner {
        for (uint256 i=0; i<_nftIds.length; i++) {
            releaseNft(_user, _collection, _nftIds[i], _targetChainId);
        }
    }

    function emergencyWithdraw(address[] calldata _collections, uint256[] calldata _nftIds, address _receiver) external onlyOwner {
        require(_collections.length == _nftIds.length, "lengths not equal");
        for (uint256 i=0; i<_collections.length; i++) {
            IERC721(_collections[i]).safeTransferFrom(address(this), _receiver, _nftIds[i]);
        }
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function setCollectionSupport(address _collection, bool _supported) external onlyOwner {
        supportedCollections[_collection] = _supported;
    }

    function setBulkDepositLimit(uint256 _newLimit) external onlyOwner {
        depositLimit = _newLimit;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
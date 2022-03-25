/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-25
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// File: NFTAirdrop.sol


pragma solidity ^0.8.7;


contract NFTAirdrop {
  struct Airdrop {
    address nft;
    uint id;
  }
  address public landNft;
  address public nftGen;
  uint256 public nextAirdropId;
  address private _owner;
  mapping(uint256 => Airdrop) public airdrops;
  mapping(address => bool) public admins;
  mapping(uint256 => bool) public invalidGen0Ids;
  mapping(uint256 => bool) public validGen1Ids;

  constructor(address _landNft, address _nftGen) {
    _owner = msg.sender;
    landNft = _landNft;
    nftGen = _nftGen;
  }

  modifier onlyOwnerOrAdmin() {
      require(_owner == msg.sender || admins[msg.sender], "Only owner or admin");
      _;
  }

  modifier tokenOwner(uint256 tokenId) {
    require(IERC721(nftGen).ownerOf(tokenId) == msg.sender, "Not owner of token");
    _;
  }

  function addAirdrops(uint256[] memory _ids) external onlyOwnerOrAdmin {
    uint256 _nextAirdropId = nextAirdropId;
    for(uint256 i = 0; i < _ids.length; i++) {
      IERC721(landNft).transferFrom(msg.sender, address(this), _ids[i]);
      airdrops[_nextAirdropId] = Airdrop({
        nft: landNft,
        id: _ids[i]
      });
      _nextAirdropId++;
    }
  }

  function claimForGen0(uint256 tokenId) external tokenOwner(tokenId) {
    require(tokenId >= 1 && tokenId <= 10000, "Invalid tokenId");
    require(!invalidGen0Ids[tokenId], "Invalid tokenId");
    _sendAirdrop(); // send Land NFT to client
    invalidGen0Ids[tokenId] = true;
  }

  function claimForGen1(uint256 tokenId) external tokenOwner(tokenId) {
    require(validGen1Ids[tokenId], "Invalid tokenId");
    _sendAirdrop(); // send Land NFT to client
    validGen1Ids[tokenId] = false;
  }

  function _sendAirdrop() private {
    Airdrop storage airdrop = airdrops[nextAirdropId];
    IERC721(airdrop.nft).transferFrom(address(this), msg.sender, airdrop.id);
    nextAirdropId++;
  }

  function addInvalidGen0(uint256[] memory _ids) external onlyOwnerOrAdmin {
    for(uint i = 0; i < _ids.length; i++) {
      invalidGen0Ids[_ids[i]] = true;
    }
  }

  function removeInvalidGen0(uint256[] memory _ids) external onlyOwnerOrAdmin {
    for(uint i = 0; i < _ids.length; i++) {
      invalidGen0Ids[_ids[i]] = false;
    }
  }

  function addValidGen1(uint256[] memory _ids) external onlyOwnerOrAdmin {
    for(uint i = 0; i < _ids.length; i++) {
      validGen1Ids[_ids[i]] = true;
    }
  }

  function removeValidGen1(uint256[] memory _ids) external onlyOwnerOrAdmin {
    for(uint i = 0; i < _ids.length; i++) {
      validGen1Ids[_ids[i]] = false;
    }
  }

  function addAdmins(address[] memory _admins) external onlyOwnerOrAdmin {
    for(uint i = 0; i < _admins.length; i++) {
      admins[_admins[i]] = true;
    }
  }

  function removeAdmins(address[] memory _admins) external onlyOwnerOrAdmin {
    for(uint i = 0; i < _admins.length; i++) {
      admins[_admins[i]] = false;
    }
  }
}
// SPDX-License-Identifier: MIT

/***
 __          __      _______          _____  _       _ _        _
 \ \        / /     |__   __|        |  __ \(_)     (_) |      | |
  \ \  /\  / /_ _ _   _| | ___   ___ | |  | |_  __ _ _| |_ __ _| |
   \ \/  \/ / _` | | | | |/ _ \ / _ \| |  | | |/ _` | | __/ _` | |
    \  /\  / (_| | |_| | | (_) | (_) | |__| | | (_| | | || (_| | |
     \/  \/ \__,_|\__, |_|\___/ \___/|_____/|_|\__, |_|\__\__,_|_|
                   __/ |                        __/ |
                  |___/                        |___/
***/
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@rmrk-team/evm-contracts/contracts/RMRK/nesting/RMRKNesting.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Gimmicks.sol";

contract GimmicksStories is RMRKNesting, Ownable, AccessControl {
    using Strings for uint256;

    bytes32 public constant PUBLISHER_ROLE = keccak256("PUBLISHER_ROLE");

    mapping(uint256 => string) public metadataByTokenId;
    mapping(uint256 => uint256) public votesByTokenId;

    uint256 private _tokenId = 0;

    Gimmicks public gimmicks;

    constructor(string memory name, string memory symbol) RMRKNesting(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setGimmicks(address _gimmicks) public onlyOwner {
        gimmicks = Gimmicks(_gimmicks);
    }

    function publishStory(
        string memory metadataURI,
        uint256 destinationId,
        address owner
    ) public onlyRole(PUBLISHER_ROLE) {
        require(gimmicks.ownerOf(destinationId) == owner, "You are not the owner of this Gimmick");

        metadataByTokenId[_tokenId++] = metadataURI;
        votesByTokenId[_tokenId] = 0;
        _nestMint(address(gimmicks), _tokenId, destinationId);
    }

    function upVote(uint256 tokenId) public {
        votesByTokenId[tokenId]++;
    }

    function downVote(uint256 tokenId) public {
        votesByTokenId[tokenId]--;
    }

    function getVotes(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Votes query for nonexistent token");

        return votesByTokenId[tokenId];
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        return metadataByTokenId[tokenId];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, RMRKNesting)
        returns (bool)
    {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IRMRKNesting).interfaceId;
    }

    function strlen(string memory s) internal pure returns (uint256) {
        uint256 len;
        uint256 i = 0;
        uint256 bytelength = bytes(s).length;

        for (len = 0; i < bytelength; len++) {
            bytes1 b = bytes(s)[i];

            if (b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return len;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: Apache-2.0

//Generally all interactions should propagate downstream

pragma solidity ^0.8.15;

import "./IRMRKNesting.sol";
import "../core/RMRKCore.sol";
import "../library/RMRKLib.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
// import "hardhat/console.sol";

error ERC721AddressZeroIsNotaValidOwner();
error ERC721ApprovalToCurrentOwner();
error ERC721ApproveCallerIsNotOwnerNorApprovedForAll();
error ERC721ApprovedQueryForNonexistentToken();
error ERC721ApproveToCaller();
error ERC721InvalidTokenId();
error ERC721MintToTheZeroAddress();
error ERC721NotApprovedOrOwner();
error ERC721TokenAlreadyMinted();
error ERC721TransferFromIncorrectOwner();
error ERC721TransferToNonReceiverImplementer();
error ERC721TransferToTheZeroAddress();
error RMRKChildIndexOutOfRange();
error RMRKIsNotContract();
error RMRKMaxPendingChildrenReached();
error RMRKMintToNonRMRKImplementer();
error RMRKNestingTooDeep();
error RMRKNestingTransferToDescendant();
error RMRKNestingTransferToNonRMRKNestingImplementer();
error RMRKNestingTransferToSelf();
error RMRKNotApprovedOrDirectOwner();
error RMRKPendingChildIndexOutOfRange();
error RMRKInvalidChildReclaim();
error RMRKChildAlreadyExists();

/**
 * @dev RMRK nesting implementation. This contract is heirarchy agnostic, and can
 * support an arbitrary number of nested levels up and down, as long as gas limits
 * allow
 *
 */

contract RMRKNesting is Context, IERC165, IERC721, IRMRKNesting, RMRKCore {
    using RMRKLib for uint256;
    using Address for address;
    using Strings for uint256;

    uint256 private constant _MAX_LEVELS_TO_CHECK_FOR_INHERITANCE_LOOP = 100;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approver address to approved address
    // The approver is necessary so approvals are invalidated for nested children on transfer
    // WARNING: If a child NFT returns the original root owner, old permissions would be active again
    mapping(uint256 => mapping(address => address)) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // ------------------- NESTING --------------

    // Mapping from token ID to RMRKOwner struct
    mapping(uint256 => RMRKOwner) private _RMRKOwners;

    // Mapping of tokenId to array of active children structs
    mapping(uint256 => Child[]) private _activeChildren;

    // Mapping of tokenId to array of pending children structs
    mapping(uint256 => Child[]) private _pendingChildren;

    // Mapping of child token address to child token Id to whether they are pending or active on any token
    // We might have a first extra mapping from token Id, but since the same child cannot be
    // nested into multiple tokens we can strip it for size/gas savings.
    mapping(address => mapping(uint256 => uint256)) private _childIsInActive;

    // WARNING: This mapping is not updated on burn or reject all, to save gas.
    // This is only used to cheaply forbid reclaiming a child which is pending
    mapping(address => mapping(uint256 => uint256)) private _childIsInPending;

    // -------------------------- MODIFIERS ----------------------------

    function _onlyApprovedOrOwner(uint256 tokenId) private view {
        if (!_isApprovedOrOwner(_msgSender(), tokenId))
            revert ERC721NotApprovedOrOwner();
    }

    modifier onlyApprovedOrOwner(uint256 tokenId) {
        _onlyApprovedOrOwner(tokenId);
        _;
    }

    /**
     * @notice Internal function for checking token ownership relative to immediate parent.
     * @dev This does not delegate to ownerOf, which returns the root owner.
     * Reverts if caller is not immediate owner.
     * Used for parent-scoped transfers.
     * @param tokenId tokenId to check owner against.
     */
    function _onlyApprovedOrDirectOwner(uint256 tokenId) private view {
        if (!_isApprovedOrDirectOwner(_msgSender(), tokenId))
            revert RMRKNotApprovedOrDirectOwner();
    }

    modifier onlyApprovedOrDirectOwner(uint256 tokenId) {
        _onlyApprovedOrDirectOwner(tokenId);
        _;
    }

    // ----------------------------- CONSTRUCTOR ------------------------------

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_)
        RMRKCore(name_, symbol_)
    {}

    // ------------------------------- ERC721 ---------------------------------
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        returns (bool)
    {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IRMRKNesting).interfaceId;
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual returns (uint256) {
        if (owner == address(0)) revert ERC721AddressZeroIsNotaValidOwner();
        return _balances[owner];
    }

    ////////////////////////////////////////
    //              TRANSFERS
    ////////////////////////////////////////

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual onlyApprovedOrDirectOwner(tokenId) {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual onlyApprovedOrDirectOwner(tokenId) {
        _safeTransfer(from, to, tokenId, data);
    }

    function nestTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 destinationId
    ) public virtual onlyApprovedOrDirectOwner(tokenId) {
        _nestTransfer(from, to, tokenId, destinationId);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        if (!_checkOnERC721Received(from, to, tokenId, data))
            revert ERC721TransferToNonReceiverImplementer();
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        (address immediateOwner, , ) = rmrkOwnerOf(tokenId);
        if (immediateOwner != from) revert ERC721TransferFromIncorrectOwner();
        if (to == address(0)) revert ERC721TransferToTheZeroAddress();

        _beforeTokenTransfer(from, to, tokenId);

        _balances[from] -= 1;
        _updateOwnerAndClearApprovals(tokenId, 0, to, false);
        _balances[to] += 1;

        emit Transfer(from, to, tokenId);
        _afterTokenTransfer(from, to, tokenId);
    }

    function _nestTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 destinationId
    ) internal virtual {
        (address immediateOwner, , ) = rmrkOwnerOf(tokenId);
        if (immediateOwner != from) revert ERC721TransferFromIncorrectOwner();
        if (to == address(0)) revert ERC721TransferToTheZeroAddress();
        if (to == address(this) && tokenId == destinationId)
            revert RMRKNestingTransferToSelf();

        // Destination contract checks:
        // It seems redundant, but otherwise it would revert with no error
        if (!to.isContract()) revert RMRKIsNotContract();
        if (!IERC165(to).supportsInterface(type(IRMRKNesting).interfaceId))
            revert RMRKNestingTransferToNonRMRKNestingImplementer();
        _checkForInheritanceLoop(tokenId, to, destinationId);

        _beforeTokenTransfer(from, to, tokenId);
        _balances[from] -= 1;
        _updateOwnerAndClearApprovals(tokenId, destinationId, to, true);
        _balances[to] += 1;

        // Sending to NFT:
        _sendToNFT(tokenId, destinationId, from, to);
    }

    function _sendToNFT(
        uint256 tokenId,
        uint256 destinationId,
        address from,
        address to
    ) private {
        IRMRKNesting destContract = IRMRKNesting(to);
        destContract.addChild(destinationId, tokenId);
        _afterTokenTransfer(from, to, tokenId);

        emit Transfer(from, to, tokenId);
    }

    function _checkForInheritanceLoop(
        uint256 currentId,
        address targetContract,
        uint256 targetId
    ) private view {
        for (uint256 i; i < _MAX_LEVELS_TO_CHECK_FOR_INHERITANCE_LOOP; ) {
            (
                address nextOwner,
                uint256 nextOwnerTokenId,
                bool isNft
            ) = IRMRKNesting(targetContract).rmrkOwnerOf(targetId);
            // If there's a final address, we're good. There's no loop.
            if (!isNft) {
                return;
            }
            // Ff the current nft is an ancestor at some point, there is an inheritance loop
            if (nextOwner == address(this) && nextOwnerTokenId == currentId) {
                revert RMRKNestingTransferToDescendant();
            }
            // We reuse the parameters to save some contract size
            targetContract = nextOwner;
            targetId = nextOwnerTokenId;
            unchecked {
                ++i;
            }
        }
        revert RMRKNestingTooDeep();
    }

    ////////////////////////////////////////
    //              MINTING
    ////////////////////////////////////////

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        if (!_checkOnERC721Received(address(0), to, tokenId, data))
            revert ERC721TransferToNonReceiverImplementer();
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        _innerMint(to, tokenId, 0);

        emit Transfer(address(0), to, tokenId);
        _afterTokenTransfer(address(0), to, tokenId);
    }

    function _nestMint(
        address to,
        uint256 tokenId,
        uint256 destinationId
    ) internal virtual {
        // It seems redundant, but otherwise it would revert with no error
        if (!to.isContract()) revert RMRKIsNotContract();
        if (!IERC165(to).supportsInterface(type(IRMRKNesting).interfaceId))
            revert RMRKMintToNonRMRKImplementer();

        _innerMint(to, tokenId, destinationId);
        _sendToNFT(tokenId, destinationId, address(0), to);
    }

    function _innerMint(
        address to,
        uint256 tokenId,
        uint256 destinationId
    ) private {
        if (to == address(0)) revert ERC721MintToTheZeroAddress();
        if (_exists(tokenId)) revert ERC721TokenAlreadyMinted();

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _RMRKOwners[tokenId] = RMRKOwner({
            ownerAddress: to,
            tokenId: destinationId,
            isNft: destinationId != 0
        });
    }

    ////////////////////////////////////////
    //              Ownership
    ////////////////////////////////////////

    /**
     * @notice Returns the root owner of the current RMRK NFT.
     * @dev In the event the NFT is owned by another NFT, it will recursively ask the parent.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override(IRMRKNesting, IERC721)
        returns (address)
    {
        (address owner, uint256 ownerTokenId, bool isNft) = rmrkOwnerOf(
            tokenId
        );
        if (isNft) {
            owner = IRMRKNesting(owner).ownerOf(ownerTokenId);
        }
        return owner;
    }

    /**
     * @notice Returns the immediate provenance data of the current RMRK NFT.
     * @dev In the event the NFT is owned by a wallet, tokenId will be zero and isNft will be false. Otherwise,
     * the returned data is the contract address and tokenID of the owner NFT, as well as its isNft flag.
     */
    function rmrkOwnerOf(uint256 tokenId)
        public
        view
        virtual
        returns (
            address,
            uint256,
            bool
        )
    {
        RMRKOwner memory owner = _RMRKOwners[tokenId];
        if (owner.ownerAddress == address(0)) revert ERC721InvalidTokenId();

        return (owner.ownerAddress, owner.tokenId, owner.isNft);
    }

    ////////////////////////////////////////
    //              BURNING
    ////////////////////////////////////////

    function burnChild(uint256 tokenId, uint256 index)
        public
        onlyApprovedOrDirectOwner(tokenId)
    {
        if (childrenOf(tokenId).length <= index)
            revert RMRKChildIndexOutOfRange();
        _burnChild(tokenId, index);
        _removeChildByIndex(_activeChildren[tokenId], index);
    }

    function _burnChild(uint256 tokenId, uint256 index) private {
        Child memory child = childOf(tokenId, index);
        delete _childIsInActive[child.contractAddress][child.tokenId];
        IRMRKNesting(child.contractAddress).burn(child.tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */

    //update for reentrancy
    function burn(uint256 tokenId)
        public
        virtual
        onlyApprovedOrDirectOwner(tokenId)
    {
        (address _RMRKOwner, , ) = rmrkOwnerOf(tokenId);
        address owner = ownerOf(tokenId);
        _balances[_RMRKOwner] -= 1;

        _beforeTokenTransfer(owner, address(0), tokenId);
        _approve(address(0), tokenId);

        _cleanApprovals(tokenId);

        Child[] memory children = childrenOf(tokenId);

        uint256 length = children.length; //gas savings
        for (uint256 i; i < length; ) {
            _burnChild(tokenId, i);
            unchecked {
                ++i;
            }
        }
        delete _RMRKOwners[tokenId];
        delete _pendingChildren[tokenId];
        delete _activeChildren[tokenId];
        delete _tokenApprovals[tokenId][owner];

        _afterTokenTransfer(owner, address(0), tokenId);
        emit Transfer(owner, address(0), tokenId);
    }

    ////////////////////////////////////////
    //              APPROVALS
    ////////////////////////////////////////

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual {
        address owner = ownerOf(tokenId);
        if (to == owner) revert ERC721ApprovalToCurrentOwner();

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender()))
            revert ERC721ApproveCallerIsNotOwnerNorApprovedForAll();

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        returns (address)
    {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId][ownerOf(tokenId)];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual {
        if (_msgSender() == operator) revert ERC721ApproveToCaller();
        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);
        _tokenApprovals[tokenId][owner] = to;
        emit Approval(owner, to, tokenId);
    }

    function _updateOwnerAndClearApprovals(
        uint256 tokenId,
        uint256 destinationId,
        address to,
        bool isNft
    ) internal {
        _RMRKOwners[tokenId] = RMRKOwner({
            ownerAddress: to,
            tokenId: destinationId,
            isNft: isNft
        });

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);
        _cleanApprovals(tokenId);
    }

    function _cleanApprovals(uint256 tokenId) internal virtual {}

    ////////////////////////////////////////
    //              UTILS
    ////////////////////////////////////////

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            isApprovedForAll(owner, spender) ||
            getApproved(tokenId) == spender);
    }

    function _isApprovedOrDirectOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        (address owner, uint256 parentTokenId, ) = rmrkOwnerOf(tokenId);
        // When the parent is an NFT, only it can do operations
        if (parentTokenId != 0) {
            return (spender == owner);
        }
        // Otherwise, the owner or approved address can
        return (spender == owner ||
            isApprovedForAll(owner, spender) ||
            getApproved(tokenId) == spender);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */

    function _requireMinted(uint256 tokenId) internal view virtual {
        if (!_exists(tokenId)) revert ERC721InvalidTokenId();
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _RMRKOwners[tokenId].ownerAddress != address(0);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert ERC721TransferToNonReceiverImplementer();
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    ////////////////////////////////////////
    //      CHILD MANAGEMENT PUBLIC
    ////////////////////////////////////////

    /**
     * @dev Function designed to be used by other instances of RMRK-Core contracts to update children.
     * param1 parentTokenId is the tokenId of the parent token on (this).
     * param2 childTokenId is the tokenId of the child instance
     */

    //update for reentrancy
    function addChild(uint256 parentTokenId, uint256 childTokenId)
        public
        virtual
    {
        _requireMinted(parentTokenId);

        if (!_msgSender().isContract()) revert RMRKIsNotContract();

        Child memory child = Child({
            contractAddress: _msgSender(),
            tokenId: childTokenId
        });

        // This check is not done since there's no guarantee of mapping being
        // up to date, see defintion for details. A similar protection does
        // exist when accepting a child:
        // if (_childIsInPending[child.contractAddress][child.tokenId] != 0)
        //     revert RMRKChildAlreadyExists();

        uint256 length = pendingChildrenOf(parentTokenId).length;

        if (length < 128) {
            _childIsInPending[child.contractAddress][child.tokenId] = 1; // We use 1 as true
            _pendingChildren[parentTokenId].push(child);
        } else {
            revert RMRKMaxPendingChildrenReached();
        }

        // Previous length matches the index for the new child
        emit ChildProposed(parentTokenId, _msgSender(), childTokenId, length);
    }

    /**
     * @notice Sends an instance of Child from the pending children array at index to children array for tokenId.
     * @param tokenId tokenId of parent token to accept a child on
     * @param index index of child in _pendingChildren array to accept.
     */
    function acceptChild(uint256 tokenId, uint256 index)
        public
        virtual
        onlyApprovedOrOwner(tokenId)
    {
        if (pendingChildrenOf(tokenId).length <= index)
            revert RMRKPendingChildIndexOutOfRange();

        Child memory child = pendingChildOf(tokenId, index);

        if (_childIsInActive[child.contractAddress][child.tokenId] != 0)
            revert RMRKChildAlreadyExists();

        // Remove from pending:
        _removeChildByIndex(_pendingChildren[tokenId], index);
        delete _childIsInPending[child.contractAddress][child.tokenId];

        // Add to active:
        _activeChildren[tokenId].push(child);
        _childIsInActive[child.contractAddress][child.tokenId] = 1; // We use 1 as true

        emit ChildAccepted(
            tokenId,
            child.contractAddress,
            child.tokenId,
            index
        );
    }

    /**
     * @notice Deletes all pending children.
     * @dev This does not update the ownership storage data on children. If necessary, ownership
     * can be reclaimed by the rootOwner of the previous parent (this).
     */
    function rejectAllChildren(uint256 tokenId)
        public
        virtual
        onlyApprovedOrOwner(tokenId)
    {
        delete _pendingChildren[tokenId];
        emit AllChildrenRejected(tokenId);
    }

    /**
     * @notice Function to unnest a child from the active token array.
     * @param tokenId is the tokenId of the parent token to unnest from.
     * @param index is the index of the child token ID.
     * @param to is the address to transfer this
     * @param isPending indicates if the child is pending (active otherwise).
     */
    function unnestChild(
        uint256 tokenId,
        uint256 index,
        address to,
        bool isPending
    ) public virtual onlyApprovedOrOwner(tokenId) {
        _unnestChild(tokenId, index, to, isPending);
    }

    function _unnestChild(
        uint256 tokenId,
        uint256 index,
        address to,
        bool isPending
    ) internal virtual {
        Child memory child;
        if (isPending) {
            child = pendingChildOf(tokenId, index);
            delete _childIsInPending[child.contractAddress][child.tokenId];
            _removeChildByIndex(_pendingChildren[tokenId], index);
        } else {
            child = childOf(tokenId, index);
            delete _childIsInActive[child.contractAddress][child.tokenId];
            _removeChildByIndex(_activeChildren[tokenId], index);
        }

        if (to != address(0)) {
            IERC721(child.contractAddress).safeTransferFrom(
                address(this),
                to,
                child.tokenId
            );
        }

        emit ChildUnnested(
            tokenId,
            child.contractAddress,
            child.tokenId,
            index,
            isPending
        );
    }

    function reclaimChild(
        uint256 tokenId,
        address childAddress,
        uint256 childTokenId
    ) public onlyApprovedOrOwner(tokenId) {
        if (_childIsInActive[childAddress][childTokenId] != 0)
            revert RMRKInvalidChildReclaim();
        if (_childIsInPending[childAddress][childTokenId] != 0)
            revert RMRKInvalidChildReclaim();

        (address owner, uint256 ownerTokenId, bool isNft) = IRMRKNesting(
            childAddress
        ).rmrkOwnerOf(childTokenId);
        if (owner != address(this) || ownerTokenId != tokenId || !isNft)
            revert RMRKInvalidChildReclaim();
        IERC721(childAddress).safeTransferFrom(
            address(this),
            _msgSender(),
            childTokenId
        );
    }

    ////////////////////////////////////////
    //      CHILD MANAGEMENT GETTERS
    ////////////////////////////////////////

    /**
     * @notice Returns all confirmed children
     */

    function childrenOf(uint256 parentTokenId)
        public
        view
        returns (Child[] memory)
    {
        Child[] memory children = _activeChildren[parentTokenId];
        return children;
    }

    /**
     * @notice Returns all pending children
     */

    function pendingChildrenOf(uint256 parentTokenId)
        public
        view
        returns (Child[] memory)
    {
        Child[] memory pendingChildren = _pendingChildren[parentTokenId];
        return pendingChildren;
    }

    function childOf(uint256 parentTokenId, uint256 index)
        public
        view
        returns (Child memory)
    {
        if (childrenOf(parentTokenId).length <= index)
            revert RMRKChildIndexOutOfRange();
        Child memory child = _activeChildren[parentTokenId][index];
        return child;
    }

    function pendingChildOf(uint256 parentTokenId, uint256 index)
        public
        view
        returns (Child memory)
    {
        if (pendingChildrenOf(parentTokenId).length <= index)
            revert RMRKPendingChildIndexOutOfRange();
        Child memory child = _pendingChildren[parentTokenId][index];
        return child;
    }

    //HELPERS

    // For child storage array, callers must check valid length
    function _removeChildByIndex(Child[] storage array, uint256 index) private {
        array[index] = array[array.length - 1];
        array.pop();
    }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
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
 * accounts that have been granted it.
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
        _checkRole(role, _msgSender());
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
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
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
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
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

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

/***
 __          __      _______          _____  _       _ _        _
 \ \        / /     |__   __|        |  __ \(_)     (_) |      | |
  \ \  /\  / /_ _ _   _| | ___   ___ | |  | |_  __ _ _| |_ __ _| |
   \ \/  \/ / _` | | | | |/ _ \ / _ \| |  | | |/ _` | | __/ _` | |
    \  /\  / (_| | |_| | | (_) | (_) | |__| | | (_| | | || (_| | |
     \/  \/ \__,_|\__, |_|\___/ \___/|_____/|_|\__, |_|\__\__,_|_|
                   __/ |                        __/ |
                  |___/                        |___/
***/
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@rmrk-team/evm-contracts/contracts/RMRK/nesting/RMRKNesting.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./DICPunch.sol";

contract Gimmicks is RMRKNesting, Ownable, AccessControl {
    using Strings for uint256;

    event DICPunchesCharged(address _to, uint256 _tokenId, uint256 _amount);
    event DICPunchSent(
        address _from,
        uint256 _toTokenId,
        address _to,
        uint256 _tokenId,
        string _message,
        uint256 _amount
    );

    bytes32 public constant BRIDGE_ROLE = keccak256("BRIDGE_ROLE");
    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");
    bytes32 public constant DIC_CHARGER_ROLE = keccak256("DIC_CHARGER_ROLE");

    mapping(uint256 => string) public metadataByTokenId;
    mapping(uint256 => uint256) public dicPunchesBalanceByTokenId;

    DICPunch public dicPunch;
    address public dicPunchOwner;

    constructor(string memory name, string memory symbol) RMRKNesting(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function bridgeNFTs(
        address to,
        uint256[] memory tokens,
        string[] memory metadataURI
    ) public onlyRole(BRIDGE_ROLE) {
        uint16 amount = (uint16)(tokens.length);
        require(metadataURI.length == amount, "Metadata length mismatch");

        for (uint16 i = 0; i < amount; i++) {
            metadataByTokenId[tokens[i]] = metadataURI[i];
            _safeMint(to, tokens[i]);
        }
    }

    function setNFTsMetadata(uint256[] memory tokenIds, string[] memory metadataURIs) public onlyRole(UPDATER_ROLE) {
        require(tokenIds.length == metadataURIs.length, "TokenIds and metadataURIs length mismatch");

        for (uint16 i = 0; i < tokenIds.length; i++) {
            metadataByTokenId[tokenIds[i]] = metadataURIs[i];
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        return metadataByTokenId[tokenId];
    }

    function setDICPunch(address _dicPunch) public onlyOwner {
        dicPunch = DICPunch(_dicPunch);
    }

    function setDICPunchOwnerAddress(address _owner) public onlyOwner {
        dicPunchOwner = _owner;
    }

    function chargeDICPunch(
        address to,
        uint256 tokenId,
        uint256 amount
    ) public onlyRole(DIC_CHARGER_ROLE) {
        require(ownerOf(tokenId) == to, "Account doesn't own this token");
        dicPunch.transferFrom(dicPunchOwner, address(this), amount);
        dicPunchesBalanceByTokenId[tokenId] += amount;

        emit DICPunchesCharged(to, tokenId, amount);
    }

    function sendDICPunch(
        address to,
        uint256 toTokenId,
        uint256 tokenId,
        string memory message
    ) public {
        sendDICPunch(to, toTokenId, tokenId, message, 1);
    }

    function sendBagOfDICPunch(
        address to,
        uint256 toTokenId,
        uint256 tokenId,
        string memory message
    ) public {
        sendDICPunch(to, toTokenId, tokenId, message, 5);
    }

    function sendDICPunch(
        address to,
        uint256 toTokenId,
        uint256 tokenId,
        string memory message,
        uint256 amount
    ) internal {
        require(ownerOf(tokenId) == msg.sender, "Account from doesn't own this token");
        require(ownerOf(toTokenId) == to, "Account to doesn't own this token");
        require(dicPunchesBalanceByTokenId[tokenId] >= amount, "Account doesn't have enough DICPunch");
        require(strlen(message) <= 280, "Message is too long");

        dicPunchesBalanceByTokenId[toTokenId] += amount;
        dicPunchesBalanceByTokenId[tokenId] -= amount;

        emit DICPunchSent(msg.sender, toTokenId, to, tokenId, message, amount);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, RMRKNesting)
        returns (bool)
    {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IRMRKNesting).interfaceId;
    }

    function strlen(string memory s) internal pure returns (uint256) {
        uint256 len;
        uint256 i = 0;
        uint256 bytelength = bytes(s).length;

        for (len = 0; i < bytelength; len++) {
            bytes1 b = bytes(s)[i];

            if (b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return len;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IRMRKNesting is IERC165 {
    struct RMRKOwner {
        uint256 tokenId;
        address ownerAddress;
        bool isNft;
    }

    /**
     * @dev emitted when a child NFT is added to a token's pending array
     */
    event ChildProposed(
        uint256 indexed tokenId,
        address indexed childAddress,
        uint256 indexed childId,
        uint256 childIndex
    );

    /**
     * @dev emitted when a child NFT accepts a token from its pending array, migrating it to the active array.
     */
    event ChildAccepted(
        uint256 indexed tokenId,
        address indexed childAddress,
        uint256 indexed childId,
        uint256 childIndex
    );

    /**
     * @dev emitted when a token removes all a child tokens from its pending array.
     */
    event AllChildrenRejected(uint256 indexed tokenId);

    /**
     * @dev emitted when a token unnests a child from itself, transferring ownership to the root owner.
     */
    event ChildUnnested(
        uint256 indexed tokenId,
        address indexed childAddress,
        uint256 indexed childId,
        uint256 childIndex,
        bool fromPending
    );

    /**
     * @dev Struct used to store child object data.
     */
    struct Child {
        uint256 tokenId;
        address contractAddress;
    }

    /**
     * @dev Returns the 'root' owner of an NFT. If this is a child of another NFT, this will return an EOA
     * address. Otherwise, it will return the immediate owner.
     *
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Returns the immediate owner of an NFT -- if the owner is another RMRK NFT, the uint256 will reflect
     *
     */
    function rmrkOwnerOf(uint256 tokenId)
        external
        view
        returns (
            address,
            uint256,
            bool
        );

    //TODO: Docs
    function burnChild(uint256 tokenId, uint256 childIndex) external;

    //TODO: Docs
    function burn(uint256 tokenId) external;

    /**
     * @dev Function to be called into by other instances of RMRK nesting contracts to update the `child` struct
     * of the parent.
     *
     * Requirements:
     *
     * - `ownerOf` on the child contract must resolve to the called contract.
     * - the pending array of the parent contract must not be full.
     */
    function addChild(uint256 parentTokenId, uint256 childTokenId) external;

    /**
     * @dev Function called to accept a pending child. Migrates the child at `index` on `parentTokenId` to
     * the accepted children array.
     *
     * Requirements:
     *
     * - `parentTokenId` must exist
     *
     */
    function acceptChild(uint256 parentTokenId, uint256 index) external;

    /**
     * @dev Function called to reject all pending children. Removes the children from the pending array mapping.
     * The children's ownership structures are not updated.
     *
     * Requirements:
     *
     * - `parentTokenId` must exist
     *
     */
    function rejectAllChildren(uint256 parentTokenId) external;

    /**
     * @dev Function called to unnest a child from `tokenId`'s child array. The owner of the token
     * is set to `to`, or is not updated in the event `to` is the zero address
     *
     * Requirements:
     *
     * - `tokenId` must exist
     *
     */
    function unnestChild(
        uint256 tokenId,
        uint256 index,
        address to,
        bool isPending
    ) external;

    /**
     * @dev Function called to reclaim an abandoned child created by unnesting with `to` as the zero
     * address. This function will set the child's owner to the rootOwner of the caller, allowing
     * the rootOwner management permissions for the child.
     *
     * Requirements:
     *
     * - `tokenId` must exist
     *
     */
    function reclaimChild(
        uint256 tokenId,
        address childAddress,
        uint256 childTokenId
    ) external;

    /**
     * @dev Returns array of child objects existing for `parentTokenId`.
     *
     */
    function childrenOf(uint256 parentTokenId)
        external
        view
        returns (Child[] memory);

    /**
     * @dev Returns array of pending child objects existing for `parentTokenId`.
     *
     */
    function pendingChildrenOf(uint256 parentTokenId)
        external
        view
        returns (Child[] memory);

    /**
     * @dev Returns a single child object existing at `index` on `parentTokenId`.
     *
     */
    function childOf(uint256 parentTokenId, uint256 index)
        external
        view
        returns (Child memory);

    /**
     * @dev Returns a single pending child object existing at `index` on `parentTokenId`.
     *
     */
    function pendingChildOf(uint256 parentTokenId, uint256 index)
        external
        view
        returns (Child memory);

    /**
     * @dev Function called when calling transferFrom with the target as another NFT via `tokenId`
     * on `to`.
     *
     */
    function nestTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 destinationId
    ) external;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.15;

import "./IRMRKCore.sol";

/**
 * @dev This is currently just a passthrough contract which allows for granular editing of
 * base-level ERC721 functions,
 */
contract RMRKCore is IRMRKCore {
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return "";
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

library RMRKLib {
    function removeItemByValue(uint64[] storage array, uint64 value) internal {
        uint64[] memory memArr = array; //Copy array to memory, check for gas savings here
        uint256 length = memArr.length; //gas savings
        for (uint256 i; i < length; ) {
            if (memArr[i] == value) {
                removeItemByIndex(array, i);
                break;
            }
            unchecked {
                ++i;
            }
        }
    }

    //For resource storage array
    function removeItemByIndex(uint64[] storage array, uint256 index) internal {
        //Check to see if this is already gated by require in all calls
        require(index < array.length);
        array[index] = array[array.length - 1];
        array.pop();
    }

    // indexOf adapted from Cryptofin-Solidity arrayUtils
    function indexOf(uint64[] memory A, uint64 a)
        internal
        pure
        returns (uint256, bool)
    {
        uint256 length = A.length;
        for (uint256 i; i < length; ) {
            if (A[i] == a) {
                return (i, true);
            }
            unchecked {
                ++i;
            }
        }
        return (0, false);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
        return functionCall(target, data, "Address: low-level call failed");
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

interface IRMRKCore {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

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
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DICPunch is ERC20, Ownable {
    constructor(uint256 initialSupply) ERC20("DIC Punch", "DIC") {
        _mint(msg.sender, initialSupply);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}
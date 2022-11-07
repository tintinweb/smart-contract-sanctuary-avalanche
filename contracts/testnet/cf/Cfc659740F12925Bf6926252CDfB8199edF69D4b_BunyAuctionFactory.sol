// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./SafePayment.sol";

contract BunyAuctionFactory is Ownable, Pausable, ReentrancyGuard, SafePayment {
    event AuctionCreated(
        uint256 tokenId,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration
    );
    event AuctionBid(uint256 tokenId, uint256 bid, address bidder);
    event AuctionFinish(uint256 tokenId, uint256 price, address winner);
    event AuctionCancelled(uint256 tokenId);

    IERC721 public nftContract;
    uint256 private immutable _auctionFee;
    address private immutable _projectTreasury;
    mapping(uint256 => Auction) private _tokenIdAuction;

    struct Auction {
        uint128 startingPrice;
        uint128 endingPrice;
        uint64 duration;
        address seller;
        uint64 startedAt;
        address lastBidder;
        uint256 lastBid;
    }

    constructor(address projectTreasury, uint256 auctionFee) {
        require(auctionFee <= 0, "auctionFee too high");
        _projectTreasury = projectTreasury;
        _auctionFee = auctionFee;
    }

    function setNFTContract(IERC721 nonFungibleContract) external onlyOwner {
        require(address(nftContract) == address(0), "NFT Contract already set");
        require(
            nonFungibleContract.supportsInterface(type(IERC721).interfaceId),
            "Non NFT contract"
        );
        nftContract = nonFungibleContract;
    }

    function _isAuction(Auction storage _auction) internal view returns (bool) {
        return (_auction.startedAt > 0);
    }

    function _isAuctionOpen(Auction storage _auction)
        internal
        view
        returns (bool)
    {
        return (_auction.startedAt > 0 &&
            _auction.startedAt + _auction.duration > block.timestamp);
    }

    function _isAuctionFinish(Auction storage _auction)
        internal
        view
        returns (bool)
    {
        return (_auction.startedAt > 0 &&
            _auction.startedAt + _auction.duration <= block.timestamp);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function createAuction(
        uint256 tokenId,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration
    ) external whenNotPaused {
        /* solhint-disable reason-string */
        // Check Overflow
        require(startingPrice == uint256(uint128(startingPrice)));
        require(endingPrice == uint256(uint128(endingPrice)));
        require(duration == uint256(uint64(duration)));
        require(endingPrice > startingPrice);
        require(duration >= 1 minutes);
        /* solhint-disable reason-string */
        require(_tokenIdAuction[tokenId].startedAt == 0, "Running Auction");

        address nftOwner = nftContract.ownerOf(tokenId);
        require(
            msg.sender == owner() || msg.sender == nftOwner,
            "Not Authorized"
        );

        // Escrow NFT
        nftContract.transferFrom(nftOwner, address(this), tokenId);

        Auction memory auction = Auction(
            uint128(startingPrice),
            uint128(endingPrice),
            uint64(duration),
            nftOwner,
            uint64(block.timestamp),
            address(0),
            0
        );
        _tokenIdAuction[tokenId] = auction;

        emit AuctionCreated(
            uint256(tokenId),
            uint256(auction.startingPrice),
            uint256(auction.endingPrice),
            uint256(auction.duration)
        );
    }

    function bid(uint256 tokenId) external payable whenNotPaused nonReentrant {
        Auction storage auction = _tokenIdAuction[tokenId];
        require(_isAuctionOpen(auction), "Auction not open");

        // TODO Close Auction on endingPrice reached
        require(auction.lastBid < auction.endingPrice, "endingPrice reached");

        require(msg.value > auction.startingPrice, "bid bellow min price");
        require(msg.value > auction.lastBid, "bid bellow last bid");
        // TODO control max bid
        // require(msg.value < auction.lastBid + maxBid, "bid too high");

        uint256 newBid = msg.value;
        if (newBid > auction.endingPrice) {
            safeSendETH(msg.sender, newBid - auction.endingPrice);
            newBid = auction.endingPrice;
        }

        if (auction.lastBid > 0) {
            safeSendETH(auction.lastBidder, auction.lastBid);
        }
        auction.lastBidder = msg.sender;
        auction.lastBid = newBid;

        emit AuctionBid(tokenId, newBid, msg.sender);
    }

    function cancelAuction(uint256 tokenId)
        external
        whenNotPaused
        nonReentrant
    {
        Auction storage auction = _tokenIdAuction[tokenId];
        require(_isAuctionOpen(auction), "Auction not open");
        require(msg.sender == auction.seller, "Only seller can cancel");

        if (auction.lastBid > 0) {
            safeSendETH(auction.lastBidder, auction.lastBid);
        }
        nftContract.transferFrom(address(this), auction.seller, tokenId);

        delete _tokenIdAuction[tokenId];
        emit AuctionCancelled(tokenId);
    }

    function cancelAuctionWhenPaused(uint256 tokenId)
        external
        whenPaused
        onlyOwner
    {
        Auction storage auction = _tokenIdAuction[tokenId];
        require(_isAuction(auction), "Not Auction");

        if (auction.lastBid > 0) {
            safeSendETH(auction.lastBidder, auction.lastBid);
        }
        nftContract.transferFrom(address(this), auction.seller, tokenId);

        delete _tokenIdAuction[tokenId];
        emit AuctionCancelled(tokenId);
    }

    function finishAuction(uint256 tokenId)
        external
        whenNotPaused
        nonReentrant
    {
        Auction storage auction = _tokenIdAuction[tokenId];
        require(
            _isAuctionFinish(auction) || auction.lastBid == auction.endingPrice,
            "Auction not finish"
        );

        if (auction.lastBid == 0) {
            nftContract.transferFrom(address(this), auction.seller, tokenId);
            emit AuctionFinish(tokenId, 0, auction.seller);
        } else {
            nftContract.transferFrom(
                address(this),
                auction.lastBidder,
                tokenId
            );
            uint256 treasuryFee = (auction.lastBid * _auctionFee) / 10000;
            uint256 sellerProceeds = auction.lastBid - treasuryFee;
            safeSendETH(_projectTreasury, treasuryFee);
            safeSendETH(auction.seller, sellerProceeds);
            emit AuctionFinish(tokenId, auction.lastBid, auction.lastBidder);
        }
        delete _tokenIdAuction[tokenId];
    }

    function withdrawUnclaimed(address to)
        external
        whenPaused
        onlyOwner
        returns (bool)
    {
        return getUnclaimed(to);
    }

    function getAuction(uint256 tokenId)
        external
        view
        returns (
            address seller,
            uint256 startingPrice,
            uint256 endingPrice,
            uint256 duration,
            uint256 startedAt,
            uint256 lastBid,
            address lastBidder
        )
    {
        Auction storage auction = _tokenIdAuction[tokenId];
        require(_isAuction(auction), "Not Auction");
        return (
            auction.seller,
            auction.startingPrice,
            auction.endingPrice,
            auction.duration,
            auction.startedAt,
            auction.lastBid,
            auction.lastBidder
        );
    }

    function getlastBid(uint256 tokenId) external view returns (uint256) {
        Auction storage auction = _tokenIdAuction[tokenId];
        require(_isAuction(auction), "Not Auction");
        return auction.lastBid;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

abstract contract SafePayment {
    event FailedPayment(address to, uint256 amount);

    uint256 private constant GAS_LIMIT = 3_000;
    bool private _payLock = false;
    uint256 private _unclaimed;

    function safeSendETH(address to, uint256 amount)
        internal
        returns (bool success)
    {
        require(!_payLock); // solhint-disable-line reason-string
        _payLock = true;
        // solhint-disable-next-line avoid-low-level-calls
        (success, ) = payable(to).call{value: amount, gas: GAS_LIMIT}("");
        if (!success) {
            _unclaimed += amount;
            emit FailedPayment(to, amount);
        }
        _payLock = false;
    }

    function getUnclaimed(address to) internal returns (bool success) {
        // solhint-disable-next-line avoid-low-level-calls
        (success, ) = payable(to).call{value: _unclaimed}("");
        if (success) {
            _unclaimed = 0;
        }
    }
}
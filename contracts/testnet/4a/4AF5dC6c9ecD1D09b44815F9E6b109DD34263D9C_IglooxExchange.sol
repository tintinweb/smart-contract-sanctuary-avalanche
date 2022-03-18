/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library BytesLibrary {
    function toString(bytes32 value) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(64);
        for (uint256 i = 0; i < 32; i++) {
            str[i * 2] = alphabet[uint8(value[i] >> 4)];
            str[1 + i * 2] = alphabet[uint8(value[i] & 0x0f)];
        }
        return string(str);
    }

    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        bytes32 fullMessage = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
        return ecrecover(fullMessage, v, r, s);
    }
}

interface IWAVAX {
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
}

contract OrderBook is Ownable {

    /***
    *   @dev select the asset type like 
    *   1 = ERC20.
    *   2 = ERC721.
    *   3 = ERC1155.
    ***/
    enum AssetType {
        ERC20,
        ERC721,
        ERC1155
    }

    /***
    *   @dev Asset details in there 
    *   Token means the token address in ther,
    *   TokenID means if token address are NFT the it need a ID for the token.
    *   asserType means the assertType enum in above.
    ***/
    struct Asset {
        address token;
        uint256 tokenId;
        AssetType assetType;
    }

    struct OrderKey {
        /* Owner of the sellilng token */
        address payable owner;
        /* Sell asset struct params */
        Asset sellAsset;
        /*  Buy asset struct params */
        Asset buyAsset;
    }

    struct Order {
        OrderKey key;
        /* how much has owner (in wei, or UINT256_MAX if ERC-721) */
        uint256 selling;
        /* how much wants owner (in wei, or UINT256_MAX if ERC-721) */
        uint256 buying;
        /* fee for selling  secoundary sale*/
        uint256 sellerFee;
        /* random numbers*/
        uint256 salt;
        /* expiry time for order*/
        uint256 expiryTime; // for bid auction auction time + bidexpiry
        /* order Type */
        uint256 orderType; // 1.sell , 2.buy, 3.bid, 4.auction
    }

    /* An ECDSA signature. */
    struct Sig {
        /* v parameter */
        uint8 v;
        /* r parameter */
        bytes32 r;
        /* s parameter */
        bytes32 s;
    }
}

contract OrderState is OrderBook {
    using BytesLibrary for bytes32;

    mapping(bytes32 => bool) public completed; // 1.completed

    function getCompleted(OrderBook.Order calldata order)
        external
        view
        returns (bool)
    {
        return completed[getCompletedKey(order)];
    }

    function setCompleted(OrderBook.Order memory order, bool newCompleted)
        internal
    {
        completed[getCompletedKey(order)] = newCompleted;
    }

    function setCompletedBidOrder(
        OrderBook.Order memory order,
        bool newCompleted,
        address buyer,
        uint256 buyingAmount
    ) internal {
        completed[
            getBidOrderCompletedKey(order, buyer, buyingAmount)
        ] = newCompleted;
    }

    function getCompletedKey(OrderBook.Order memory order)
        public
        pure
        returns (bytes32)
    {
        return prepareOrderHash(order);
    }

    function getBidOrderCompletedKey(
        OrderBook.Order memory order,
        address buyer,
        uint256 buyingAmount
    ) public pure returns (bytes32) {
        return prepareBidOrderHash(order, buyer, buyingAmount);
    }

    function validateOrderSignature(Order memory order, Sig memory sig)
        internal
        view
    {
        require(completed[getCompletedKey(order)] != true, "Signature exist");
        if (sig.v == 0 && sig.r == bytes32(0x0) && sig.s == bytes32(0x0)) {
            revert("incorrect signature");
        } else {
            require(
                prepareOrderHash(order).recover(sig.v, sig.r, sig.s) ==
                    order.key.owner,
                "Incorrect signature"
            );
        }
    }

    function validateOrderSignatureView(Order memory order, Sig memory sig)
        public
        view 
        returns (address)
    {
        require(completed[getCompletedKey(order)] != true, "Signature exist");
        if (sig.v == 0 && sig.r == bytes32(0x0) && sig.s == bytes32(0x0)) {
            revert("Incorrect signature");
        } else {
              return prepareOrderHash(order).recover(sig.v, sig.r, sig.s);
        }
    }

    function validateBidOrderSignature(
        Order memory order,
        Sig memory sig,
        address bidder,
        uint256 buyingAmount
    ) internal view {
        require(
            completed[getBidOrderCompletedKey(order, bidder, buyingAmount)] !=
                true,
            "Signature exist"
        );
        if (sig.v == 0 && sig.r == bytes32(0x0) && sig.s == bytes32(0x0)) {
            revert("Incorrect bid signature");
        } else {
            require(
                prepareBidOrderHash(order, bidder, buyingAmount).recover(
                    sig.v,
                    sig.r,
                    sig.s
                ) == bidder,
                "Incorrect bid signature"
            );
        }
    }

    function validateBidOrderSignatureView(
        Order memory order,
        Sig memory sig,
        address bidder,
        uint256 buyingAmount
    ) public view returns (address) {
        require(completed[getCompletedKey(order)] != true, "Signature exist");
        if (sig.v == 0 && sig.r == bytes32(0x0) && sig.s == bytes32(0x0)) {
            revert("Incorrect bid signature");
        } else {
                return prepareBidOrderHash(order, bidder, buyingAmount).recover(
                    sig.v,
                    sig.r,
                    sig.s
                );
        }
    }

    function prepareOrderHash(OrderBook.Order memory order)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    order.key.owner,
                    abi.encodePacked(
                        order.key.sellAsset.token,
                        order.key.sellAsset.tokenId,
                        order.key.sellAsset.assetType,
                        order.key.buyAsset.token,
                        order.key.buyAsset.tokenId,
                        order.key.buyAsset.assetType
                    ),
                    order.selling,
                    order.buying,
                    order.sellerFee,
                    order.salt,
                    order.expiryTime,
                    order.orderType
                )
            );
    }

    function prepareBidOrderHash(
        OrderBook.Order memory order,
        address bidder,
        uint256 buyingAmount
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    bidder,
                    abi.encodePacked(
                        order.key.buyAsset.token,
                        order.key.buyAsset.tokenId,
                        order.key.buyAsset.assetType,
                        order.key.sellAsset.token,
                        order.key.sellAsset.tokenId,
                        order.key.sellAsset.assetType
                    ),
                    buyingAmount,
                    order.selling,
                    order.sellerFee,
                    order.salt,
                    order.expiryTime,
                    order.orderType
                )
            );
    }

    function prepareBuyerFeeMessage(
        Order memory order,
        uint256 fee,
        address royaltyReceipt
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    abi.encodePacked(
                        order.key.owner,
                        abi.encodePacked(
                            order.key.sellAsset.token,
                            order.key.sellAsset.tokenId,
                            order.key.buyAsset.token,
                            order.key.buyAsset.tokenId
                        ),
                        order.selling,
                        order.buying,
                        order.sellerFee,
                        order.salt,
                        order.expiryTime,
                        order.orderType
                    ),
                    fee,
                    royaltyReceipt
                )
            );
    }
}

interface IIglooxStore {
    function mint(
        address from,
        address to,
        uint256 id,
        uint256 blockExpiry,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 supply,
        string memory uri
    ) external returns (bool);
}

contract TransferSafe {
    struct mintParams {
        uint256 blockExpiry;
        uint8 v;
        bytes32 r;
        bytes32 s;
        string uri;
    }

    function erc721safeTransferFrom(
        IERC721 token,
        address from,
        address to,
        uint256 tokenId
    ) internal {
        token.safeTransferFrom(from, to, tokenId);
    }

    function erc1155safeTransferFrom(
        IERC1155 token,
        address from,
        address to,
        uint256 id,
        uint256 value
    ) internal {
        token.safeTransferFrom(from, to, id, value, "0x");
    }

    function erc1155safeMintTransferFrom(
        IIglooxStore token,
        address from,
        address to,
        uint256 id,
        uint256 value,
        uint256 blockExpiry,
        uint8 v,
        bytes32 r,
        bytes32 s,
        string memory uri
    ) internal {
        require(
            token.mint(from, to, id, blockExpiry, v, r, s, value, uri),
            "TransferSafe:erc1155safeMintTransferFrom:: transaction Failed"
        );
    }
}

contract IglooxExchange is OrderState, TransferSafe {
	using SafeMath for uint256;
	using BytesLibrary for bytes32;

	address payable public beneficiaryAddress;
	address public buyerFeeSigner;
	uint256 public beneficiaryFee; 
	IIglooxStore private _IglooxStore;
	address public WAVAX;

	// NEWLY ADDED 

	// PROBLEM: royaltyFeeLimit needs to become dynamic not static
	uint256 public royaltyFeeLimit;
	// TODO : THREE PARTIES NEEDS TO SHARE ROYALTIES(platform, artist, affiliator);
	// STATIC
	uint256 public platformFee = 35; // 3.5% example
	// DYNAMIC
	uint256 public artistPercentage;
	// DYNAMIC
	uint256 public minterPercentage;
	// Mapping if user bought his first NFT here then he becames the verified user so he can participate in presale from now on
	mapping(address => bool) public verified;
	// Array of addresses of verifed users
	address[] public verifiedUsers;
	// Mapping of users that are minter(When user mint nft and never sell that nft he is minter)
	mapping(address => bool) public minter;
	// Mapping of users that are affiliaters 
	//(When minter sends his nft he immediately becomes affiliator and starts to earn percentage of that sale for life)
	mapping(address => bool) public affiliator;
    // operator can check in this mapping
    mapping(address => bool) public operators;

	// auth token for exchange
	mapping(address => bool) public allowToken;
	mapping(address => mapping (address => uint256 )) private userAmount;

	// TODO : TRANSFER FEE TO SPECIFIC VARIABLE THEN ENABLE ONLYOWNER TO COLLECT IT IN SPECIFIC MOMENT
	// TODO : INITIALIZE MINTER THEN WHEN HE SELLS HIS FIRST MINTED NFT ADD HIM IN AFFILIATORS

	event MatchOrder(
		address indexed sellToken,
		uint256 indexed sellTokenId,
		uint256 sellValue,
		address owner,
		address buyToken,
		uint256 buyTokenId,
		uint256 buyValue,
		address buyer,
		uint256 orderType
	);

	event Cancel(address indexed sellToken, uint256 indexed sellTokenId, address owner, address buyToken, uint256 buyTokenId );
	event Beneficiary(address indexed newBeneficiary);
	event BuyerFeeSigner(address indexed newBuyerFeeSigner);
	event BeneficiaryFee(uint256 indexed newbeneficiaryfee);
	event RoyaltyFeeLimit(uint256 indexed newRoyaltyFeeLimit);
	event AllowToken(address indexed token, bool indexed status);
	event SetMintableStore(address indexed newMintableStore);
	event SetNewRoyalFee(uint256 indexed feeLimit);
	event SetNewArtistPercetntage(uint256 indexed artistPer);
	event SetNewMinterPercetntage(uint256 indexed minterPer);
	
	modifier isArtist(address){
        require(operators[msg.sender] == true, "Only artist");
        _;
    }

	constructor(
		address payable beneficiary,
		address buyerfeesigner,
		uint256 _beneficiaryfee,
		address WAVAXAddr,
		uint256 _royaltyFeeLimit,
		uint256 _artistPercentage,
		uint256 _minterPercentage
	) {
        require( beneficiary != address(0x0),"Beneficiry can not be 0x0 address");
		require(buyerfeesigner != address(0x0),"Buyer fee signer can not be 0x0 address");
		require(_beneficiaryfee > 0 && _beneficiaryfee < 100,"Beneficiary fee needs to be bigger than 0 and less than 100");
		require(WAVAXAddr != address(0x0),"WAVAXAddr can not be 0x0 address");
		require(_royaltyFeeLimit > 0 && _royaltyFeeLimit < 100,"Royalte fee needs to be bigger than 0 and less than 100");
		require(_artistPercentage > 0 && _artistPercentage < 100,"ArtistPercentage needs to be bigger than 0 and less than 100");
		require(_minterPercentage > 0 && _minterPercentage < 100,"ArtistPercentage needs to be bigger than 0 and less than 100");

		//NEWLY ADDED
		royaltyFeeLimit = _royaltyFeeLimit;
		artistPercentage = _artistPercentage;
		minterPercentage = _minterPercentage;
		
		beneficiaryAddress = beneficiary;
		buyerFeeSigner = buyerfeesigner;
		beneficiaryFee = _beneficiaryfee;
		WAVAX = WAVAXAddr;
	}

	/*
        *	@dev Buyer can directly buy the NFT tokens in this function.
        *   @param order is the details of the seller and Buyer tokens, order status, expiry time and order price in here.
        *   @param sig is the signature of the order's owner.
        *   @param buyerFeeSig is in the buyerfee signer in our contract, that address will confrim the order.
        *   @param royaltyFee is the royaltyFee amount of the NFT.
        *   @param royaltyReceipt, order's NFT creater
        *   @param isStore, lazy mint were active or not.
        *   @param storeParams, if the new NFT were 
	*/	
	function sell(
		Order calldata order,
		Sig calldata sig,
		Sig calldata buyerFeeSig,
		uint256 royaltyFee,
		address payable royaltyReceipt,
		bool isStore,
		mintParams memory storeParams
	) external payable {
		require((block.timestamp <= order.expiryTime), "Signature expired");
		require(order.orderType == 1, "Invalid order type");
		require(order.key.owner != msg.sender, "Invalid owner");

		validateOrderSignature(order, sig);
		validateBuyerFeeSig(order, royaltyFee, royaltyReceipt, buyerFeeSig);
        takeFee(order.key.buyAsset.token, msg.sender, order.key.owner, order.buying);
		setCompleted(order, true);
		transferToken(order, msg.sender, isStore, storeParams);
		emitMatchOrder(order, msg.sender);

        if(!verified[msg.sender]){
            verified[msg.sender] = true;
            verifiedUsers.push(msg.sender);
        }
	}

	/*
        *	@dev Buyer were make a offer for seller's NFT from the order with signature.
        *    Seller were accept the offer with the order tuple params in this function.
        *    It will distribute the NFT to the buyer and drop the buy tokens or AVAX in the contract.
        *   @param order is the details of the seller and Buyer tokens, order status, expiry time and order price in here.
        *   @param sig is the signature of the order's owner.
        *   @param buyerFeeSig is in the buyerfee signer in our contract, that address will confrim the order.
        *   @param royaltyFee is the royaltyFee amount of the NFT.
        *   @param royaltyReceipt, order's NFT creater
        *   @param isStore, lazy mint were active or not.
        *   @param storeParams, if the new NFT were 
	**/
	function buy(
		Order calldata order,
		Sig calldata sig,
		Sig calldata buyerFeeSig,
		uint256 royaltyFee,
		address payable royaltyReceipt,
		bool isStore,
		mintParams memory storeParams
	) external {
		require((block.timestamp <= order.expiryTime), "Signature expired");
		require(order.orderType == 2, "Invalid order");
		require(order.key.owner != msg.sender, "Invalid owner");

		validateOrderSignature(order, sig);
		validateBuyerFeeSig(order, royaltyFee, royaltyReceipt, buyerFeeSig);
        takeFee(order.key.sellAsset.token, order.key.owner, msg.sender, order.selling);
		setCompleted(order, true);
		transferToken(order, msg.sender, isStore, storeParams);
		emitMatchOrder(order, msg.sender);

		// NEWLY ADDED
		if(!verified[msg.sender]){
            verified[msg.sender] = true;
            verifiedUsers.push(msg.sender);
        }
	}
 
    function takeFee(address _tokenAddress, address _sender, address _receiver, uint256 _tokenAmount) internal {
        uint256 fee;
        if(_tokenAddress == address(0x0)){
             fee = msg.value * platformFee / 1e3;
             require(payable(beneficiaryAddress).send(fee),"Transaction failed.");
             userAmount[_receiver][_tokenAddress] = msg.value - fee;
        } else {
            fee = _tokenAmount * platformFee / 1e3;
            IERC20(_tokenAddress).transferFrom(_sender,address(this),_tokenAmount);
            IERC20(_tokenAddress).transfer(beneficiaryAddress, fee);
            userAmount[_receiver][_tokenAddress] = _tokenAmount - fee;
        }
        userAmount[address(this)][_tokenAddress] = fee;
    }

	function transferToken(
		Order calldata order,
		address buyer,
		bool isStore,
		mintParams memory storeParams
	) internal {
		if (
			order.key.sellAsset.assetType == AssetType.ERC721 ||
			order.key.buyAsset.assetType == AssetType.ERC721
		) {
			if (order.orderType == 1 || order.orderType == 3) {
				if (!isStore) {
					erc721safeTransferFrom(
						IERC721(order.key.sellAsset.token),
						order.key.owner,
						buyer,
						order.key.sellAsset.tokenId
					);
				} else {
					require(
						order.key.sellAsset.token == address(_IglooxStore),
						"invalid sell asset"
					);
					erc1155safeMintTransferFrom(
						IIglooxStore(order.key.sellAsset.token),
						order.key.owner,
						buyer,
						order.key.sellAsset.tokenId,
						1,
						storeParams.blockExpiry,
						storeParams.v,
						storeParams.r,
						storeParams.s,
						storeParams.uri
					);
				}
			} else if (order.orderType == 2) {
				if (!isStore) {
					erc721safeTransferFrom(
						IERC721(order.key.buyAsset.token),
						buyer,
						order.key.owner,
						order.key.buyAsset.tokenId
					);
				} else {
					require(
						order.key.buyAsset.token == address(_IglooxStore),
						"invalid buy asset"
					);
					erc1155safeMintTransferFrom(
						IIglooxStore(order.key.buyAsset.token),
						buyer,
						order.key.owner,
						order.key.buyAsset.tokenId,
						1,
						storeParams.blockExpiry,
						storeParams.v,
						storeParams.r,
						storeParams.s,
						storeParams.uri
					);
				}
			}
		} else if (
			order.key.sellAsset.assetType == AssetType.ERC1155 ||
			order.key.buyAsset.assetType == AssetType.ERC1155
		) {
			if (order.orderType == 1 || order.orderType == 3) {
				if (!isStore) {
					erc1155safeTransferFrom(
						IERC1155(order.key.sellAsset.token),
						order.key.owner,
						buyer,
						order.key.sellAsset.tokenId,
						order.selling
					);
				} else {
					require(
						order.key.sellAsset.token == address(_IglooxStore),
						"invalid sell asset"
					);
					erc1155safeMintTransferFrom(
						IIglooxStore(order.key.sellAsset.token),
						order.key.owner,
						buyer,
						order.key.sellAsset.tokenId,
						order.selling,
						storeParams.blockExpiry,
						storeParams.v,
						storeParams.r,
						storeParams.s,
						storeParams.uri
					);
				}
			} else if (order.orderType == 2) {
				if (!isStore) {
					erc1155safeTransferFrom(
						IERC1155(order.key.buyAsset.token),
						buyer,
						order.key.owner,
						order.key.buyAsset.tokenId,
						order.buying
					);
				} else {
					require(
						order.key.buyAsset.token == address(_IglooxStore),
						"invalid buy asset"
					);
					erc1155safeMintTransferFrom(
						IIglooxStore(order.key.buyAsset.token),
						buyer,
						order.key.owner,
						order.key.buyAsset.tokenId,
						order.buying,
						storeParams.blockExpiry,
						storeParams.v,
						storeParams.r,
						storeParams.s,
						storeParams.uri
					);
				}
			}
		} else {
			revert("invalid assest ");
		}
	}

	/*
        *	@dev bidder were bid in the auction for NFT from the order with signature.
        *    Seller were accept the Bid with the order tuple params in this function.
        *    It will distribute the NFT to the buyer and drop the buy tokens or AVAX in the contract.
        *   @param order is the details of the seller and Buyer tokens, order status, expiry time and order price in here.
        *   @param sig is the signature of the order's owner.
        *   @param buyerFeeSig is in the buyerfee signer in our contract, that address will confrim the order.
        *   @param royaltyFee is the royaltyFee amount of the NFT.
        *   @param royaltyReceipt, order's NFT creater
        *   @param isStore, lazy mint were active or not.
        *   @param storeParams, if the new NFT were 
	**/
	function bid(
		Order calldata order,
		Sig calldata sig,
		Sig calldata buyerSig,
		Sig calldata buyerFeeSig,
		address buyer,
		uint256 buyingAmount,
		uint256 royaltyFee,
		address payable royaltyReceipt,
		bool isStore,
		mintParams memory storeParams
	) external {
		require((block.timestamp <= order.expiryTime), "Signature expired");
		require(buyingAmount >= order.buying, "BuyingAmount invalid");

		require(order.orderType == 3, "Invalid order");
		require(order.key.owner == msg.sender, "Not owner");

		validateOrderSignature(order, sig);
		validateBidOrderSignature(order, buyerSig, buyer, buyingAmount);
		validateBuyerFeeSig(order, royaltyFee, royaltyReceipt, buyerFeeSig);

		setCompleted(order, true);
		setCompletedBidOrder(order, true, buyer, buyingAmount);
        userAmount[order.key.owner][order.key.buyAsset.token] += order.buying;
        takeFee(order.key.buyAsset.token, buyer, order.key.owner, order.buying);
		transferToken(order, buyer, isStore, storeParams);
		emitMatchOrder(order, buyer);
	}

	function emitMatchOrder(Order memory order, address buyer) internal {
		emit MatchOrder(
			order.key.sellAsset.token,
			order.key.sellAsset.tokenId,
			order.selling,
			order.key.owner,
			order.key.buyAsset.token,
			order.key.buyAsset.tokenId,
			order.buying,
			buyer,
			order.orderType
		);
	}

    /*
        *	@dev Order owner were cancel the order
        *   @param order is the details of the seller and Buyer tokens, order status, expiry time and order price in here.
	**/
	function cancel(Order calldata order) external {
		require(order.key.owner == msg.sender, "Not an owner");
		setCompleted(order, true);
		emit Cancel(
			order.key.sellAsset.token,
			order.key.sellAsset.tokenId,
			msg.sender,
			order.key.buyAsset.token,
			order.key.buyAsset.tokenId
		);
	}

	function validateBuyerFeeSig(
		Order memory order,
		uint256 buyerFee,
		address royaltyReceipt,
		Sig memory sig
	) internal view {
		require(
			prepareBuyerFeeMessage(order, buyerFee, royaltyReceipt).recover(
				sig.v,
				sig.r,
				sig.s
			) == buyerFeeSigner,
			"Incorrect buyer fee signature"
		);
	}

    /*
        *@notice function returns address that are recover from the given params and signature.
        *@dev function is used for update the Signer address in the contract.
        *@param order typed tuple.
        *@param royaltyFee is in the contract royalty fee. 
        *@param royaltyReceipt is address of the royalty receiptiant.
        *@param sig is signature.
    */
	function validateBuyerFeeSigView(
		Order memory order,
		uint256 royaltyFee,
		address royaltyReceipt,
		Sig memory sig
	) public pure returns (address) {
		return
			prepareBuyerFeeMessage(order, royaltyFee, royaltyReceipt).recover(
				sig.v,
				sig.r,
				sig.s
			);
	}

    /*
        *@notice function returns address that are recover from the hash and signature.
        *@dev function is used for  view the signer of the hash and signature.
        *@param hash is derived from encode form some param.
        *@param sig is signature tuple.   
    */
	function toAVAXSignedMessageHash(bytes32 hash, Sig memory sig)
		public
		pure
		returns (address signer)
	{
		signer = hash.recover(sig.v, sig.r, sig.s);
	}

    /*
        *@dev user can claim his selling fee token by this function.
        *@param _tokenAddress to select the token address recover our tokens in the contract.
    */
	function userClaim(address _tokenAddress) external {
		uint256 amount = userAmount[msg.sender][_tokenAddress];
		if(_tokenAddress == address(0x0)){
			payable(msg.sender).transfer(amount);
		} else {
			IERC20(_tokenAddress).transfer(msg.sender, amount);
		}
        userAmount[msg.sender][_tokenAddress] = 0;
	}

    /*
        *@dev function is used for update the Signer address in the contract.
        *@param newBuyerFeeSigner is  signer is in the contract will be updated.    
    */
	function setBeneficiary(address payable newBeneficiary) external onlyOwner {
		require(newBeneficiary != address(0x00), "Zero address");
		beneficiaryAddress = newBeneficiary;
		emit Beneficiary(newBeneficiary);
	}

    /*
        *@dev function is used for update the Signer address in the contract.
        *@param newBuyerFeeSigner is the signer in the contract will be updated.    
    */
	function setBuyerFeeSigner(address newBuyerFeeSigner) external onlyOwner {
		require(newBuyerFeeSigner != address(0x00), "Zero address");
		buyerFeeSigner = newBuyerFeeSigner;
		emit BuyerFeeSigner(newBuyerFeeSigner);
	}

    /*
        *@dev function is used for update the Beneficiary Fee in the contract.
        *@param _newbeneficiaryfee is the new beneficiary fee percetage will be updated.    
    */
	function setBeneficiaryFee(uint256 _newbeneficiaryfee) external onlyOwner {
		beneficiaryFee = _newbeneficiaryfee;
		emit BeneficiaryFee(_newbeneficiaryfee);
	}

    /*
        *@dev function is used for update the token status in the contract.
        *@param NewToken and its status will be updated.    
    */
	function setTokenStatus(address token, bool status) external onlyOwner {
		require(token != address(0x00), "Zero address");
		allowToken[token] = status;
		emit AllowToken(token, status);
	}

    /*
        *@dev function is used for update the Igloox store address in the contract.
        *@param newIglooxStore is the new store will be updated.    
    */
	function setIglooxStore(address newIglooxStore) external onlyOwner {
		require(newIglooxStore != address(0x00), "Zero address");
		_IglooxStore = IIglooxStore(newIglooxStore);
		emit SetMintableStore(newIglooxStore);
	}

    /*
        *@dev function is used for update the Royalty percentage in the contract.
        *@param _percentage is the new Royalty percetage will be updated.    
    */
	function setNewRoyalteeFeePercentaage(uint256 _percentage) 
		external 
		onlyOwner
	{
		require(_percentage > 0 && _percentage < 100,"Royaltee needs to be over 0 and below 100");

		royaltyFeeLimit = _percentage;
		emit SetNewRoyalFee(royaltyFeeLimit);
	}

    /*
        *@dev function is used for update the minter percentage in the contract.
        *@param _percentage is the new minter percetage will be updated.    
    */
	function setNewArtistPercentaage(uint256 _percentage) 
		external 
		isArtist(msg.sender) 
	{
		require(_percentage > 0 && _percentage < 0,"Artist percentage needs to be over 0 and below 100");

		artistPercentage = _percentage;
		emit SetNewArtistPercetntage(artistPercentage);
	}

    /*
        *@dev function is used for update the minter percentage in the contract.
        *@param _percentage is the new minter percetage will be updated.    
    */
	function setNewMinterPercentage(uint256 _percentage) 
		external 
		onlyOwner
	{
		require(_percentage > 0 && _percentage < 0,"Artist percentage needs to be over 0 and below 100");

		minterPercentage = _percentage;
		emit SetNewMinterPercetntage(minterPercentage);
	}

	/**
     * @notice recover the tokens or BNB in the contract
	 * @dev function to take the strucked tokens or AVAXs in the contract.
	 */
	function inCaseTokensGetStuck(address _token) external onlyOwner {
		if (_token != address(0x000)) {
			uint256 amount = IERC20(_token).balanceOf(address(this));
			IERC20(_token).transfer(msg.sender, amount);
		} else {
			payable(msg.sender).transfer(address(this).balance);
		}
	}

	/**
	 * @notice function is returning address of IgloxStore
	 *
	 * @dev getter for address
	 *
	 * @return address 
	 */
	function IglooxStore() external view returns (address) {
		return address(_IglooxStore);
	}

}
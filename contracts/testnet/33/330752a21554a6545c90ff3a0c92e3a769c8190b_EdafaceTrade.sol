/**
 *Submitted for verification at testnet.snowtrace.io on 2023-07-13
*/

/**
 *Submitted for verification at Etherscan.io on 2023-02-08
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
     
    modifier initializer() {
        require(
            _initializing || !_initialized,
            "Initializable: contract is already initialized"
        );

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {}

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    uint256[50] private __gap;
}

library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

    uint256[49] private __gap;
}

interface IBEP20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

/**
 * @dev Implementation of the {IBEP165} interface.
 *
 * Contracts that want to implement BEP165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {BEP165Storage} provides an easier to use but more expensive implementation.
 */
interface IBEP165Upgradeable {
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
 * @dev Required interface of an BEP721 compliant contract.
 */
interface IBEP721Upgradeable is IBEP165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
     * are aware of the BEP721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IBEP721Receiver-onBEP721Received}, which is called upon a safe transfer.
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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

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
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IBEP721Receiver-onBEP721Received}, which is called upon a safe transfer.
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

/**
 * @dev Required interface of an BEP1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IBEP1155Upgradeable is IBEP165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IBEP1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    /**
     * @dev xref:ROOT:BEP1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

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
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

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
     * - If `to` refers to a smart contract, it must implement {IBEP1155Receiver-onBEP1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:BEP1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IBEP1155Receiver-onBEP1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

interface Edaface721 {
    function mint(
        string memory ipfsmetadata,
        address to,
        uint256 royal,
        uint256 id_,
        bool _listStatus
    ) external;
    function mintBatch(
        string[] memory ipfsmetadata,
        address to,
        uint256 supply,
        uint256 royal
    ) external;
    function mintListBatch(
        string[] memory ipfsmetadata,
        address to,
        uint256[] memory tokenIs,
        uint256 royal
    ) external;
    function getCreatorsAndRoyalty(uint256 tokenid)
        external
        view
        returns (address, uint256);
    function changeCollectionOwner(address to) external;
    function setRoyaltyPBEPentage(uint96 _royPer) external;
    function adminBurn(uint256 tokenId) external;
}

interface Edaface1155 {
    function mint(
        string memory ipfsmetadata,
        address to,
        uint256[] memory total,
        uint256 royal,
        uint256 id_,
        bool _listStatus
    ) external;
    function mintBatch(
        string[] memory ipfsmetadata,
        address to,
        uint256[] memory supply,
        uint256 size,
        uint256 royal
    ) external;
    function mintListBatch(
        string[] memory ipfsmetadata,
        address to,
        uint256[] memory supply,
        uint256[] memory listQty,
        uint256[] memory tokenIs,
        uint256 royal
    ) external;
    function getCreatorsAndRoyalty(uint256 tokenid)
        external
        view
        returns (address, uint256);

    function TransferNFT(address to, uint256 tokenid, uint256 count) external;
    function changeCollectionOwner(address to) external;
    function setRoyaltyPBEPentage(uint96 _royPer) external;
    function adminBurn(uint256 tokenId, uint256 amount, address from) external;
}

contract VerifySignature {
    function getMessageHash(
        address _to,
        uint _amount,
        string memory _message,
        uint _nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_to, _amount, _message, _nonce));
    }
    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
            );
    }
    function verify(
        address _to,
        uint256 _amount,
        string memory _message,
        uint _nonce,
        bytes memory signature
    ) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(_to, _amount, _message, _nonce);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _to;
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        public
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
}

contract EdafaceTrade is Initializable, OwnableUpgradeable, VerifySignature {
    event OrderPlace(
        address indexed from,
        uint256 indexed tokenId,
        uint256 indexed value
    );
    event CancelOrder(address indexed from, uint256 indexed tokenId);
    event ColletionId(uint256 indexed collectionId, uint256 indexed cRoyalty);
    event ChangePrice(
        address indexed from,
        uint256 indexed tokenId,
        uint256 indexed value
    );
    event Create(
        address indexed _to,
        uint256 indexed tokenId,
        string status
    );
    using SafeMathUpgradeable for uint256;

    function initialize() public initializer {
        __Ownable_init();
        serviceValue = 0;
        sellervalue = 2500000000000000000;
        deci = 18;
        publicMint = true;
        _tid = 1;
    }

    struct Order {
        uint256 tokenId;
        uint256 price;
        address contractAddress;
    }
    
    mapping(address => mapping(uint256 => Order)) public order_place;
    mapping(string => address) private tokentype;
    mapping(address => mapping(address => bool)) public approveStatus;
    
    uint256 private serviceValue;
    uint256 private sellervalue;
    bool public publicMint;
    address public edaface721;
    address public edaface1155;
    uint256 deci;
    uint256 public _tid;
    struct List {
        uint256 tokenId;
        address contractAddress;
        bool withdraw;
        uint _type;
        uint _qty;
    }
    mapping(address => mapping(address => mapping(uint256 => List))) public _listNFT;
    uint256 private listFees;
    uint256 private mintFees;
    uint256 private withdrawFees;
    bool public _emergencyWithdrawStatus;

    function getServiceFee()
        public
        view
        returns (
            uint256,uint256,uint256,uint256,uint256
        )
    {
        return (serviceValue, sellervalue, mintFees, listFees, withdrawFees);
    }

    //  _fees[0] - serviceValue, _fees[1] - sellervalue, _fees[2] - Minting Fees, _fees[3] -  Withdrawal Fee, _fees[4] - Listing Fee
    function setServiceValue(uint256[] memory _fees)
        public
        onlyOwner
    {
        serviceValue = _fees[0];
        sellervalue = _fees[1];
        mintFees = _fees[2];
        withdrawFees = _fees[3];
        listFees = _fees[4];

    }

    function getTokenAddress(string memory _type)
        public
        view
        returns (address)
    {
        return tokentype[_type];
    }

    function addTokenType(string[] memory _type, address[] memory tokenAddress)
        public
        onlyOwner
    {
        require(
            _type.length == tokenAddress.length,
            "Not equal for type and tokenAddress"
        );
        for (uint256 i = 0; i < _type.length; i++) {
            tokentype[_type[i]] = tokenAddress[i];
        }
    }

    function pBEPent(uint256 value1, uint256 value2)
        internal
        pure
        returns (uint256)
    {
        uint256 result = value1.mul(value2).div(1e20);
        return (result);
    }

    function calc(
        uint256 amount,
        uint256 royal,
        uint256 _serviceValue,
        uint256 _sellervalue
    )
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 fee = pBEPent(amount, _serviceValue);
        uint256 roy = pBEPent(amount, royal);
        uint256 netamount = 0;
        if (_sellervalue != 0) {
            uint256 fee1 = pBEPent(amount, _sellervalue);
            fee = fee.add(fee1);
            netamount = amount.sub(fee1.add(roy));
        } else {
            netamount = amount.sub(roy);
        }
        return (fee, roy, netamount);
    }


    // ids[0] - tokenId, ids[1] - amount, ids[2] -  nooftoken, ids[3] - nftType, isd[4] - _nonce, isd[5] - signatureValue
    function saleToken(
        address payable from,
        uint256[] memory ids,
        address _conAddr,
        string memory message,
        bytes memory signature
    ) public payable {
        require(verify(from, ids[5], message, ids[4], signature) == true ,"Not vaild User");
        require(_listNFT[from][_conAddr][ids[0]]._qty > 0,"NFT Not Listed here.");
        _saleToken(from, ids, "ETH",_conAddr);
        nftTransfer(address(this), msg.sender, _conAddr, ids[3], ids[2], ids[0]);
        if(ids[2] == _listNFT[from][_conAddr][ids[0]]._qty){
            _listNFT[from][_conAddr][ids[0]].withdraw = false;
        }
        else{
            _listNFT[from][_conAddr][ids[0]]._qty = ids[2];
        }
       
    }

    // ids[0] - tokenId, ids[1] - amount, ids[2] -  nooftoken, ids[3] - nftType
    //ldatas[0] = _royal, ldatas[1] = Tokendecimals, ldatas[2] = approveValue, ldatas[3] = _adminfee,
    //ldatas[4] = roy, ldatas[5] = netamount, ldatas[6] = val
    function _saleToken(
        address payable from,
        uint256[] memory ids,
        string memory bidtoken,
        address _conAddr
    ) internal {
        uint256[7] memory ldatas;
        ldatas[6] = pBEPent(ids[1], serviceValue).add(ids[1]);
        address create;
        if(edaface721    ==  _conAddr || edaface1155    ==  _conAddr){
        if (ids[3] == 721) {
            (create, ldatas[0]) = Edaface721(edaface721)
                .getCreatorsAndRoyalty(ids[0]);
        } else {
            (create, ldatas[0]) = Edaface1155(edaface1155)
                .getCreatorsAndRoyalty(ids[0]);
        }
        }

        if (
            keccak256(abi.encodePacked((bidtoken))) ==
            keccak256(abi.encodePacked(("ETH")))
        ) {
            require(msg.value == ldatas[6], "Mismatch the msg.value");
            (ldatas[3], ldatas[4], ldatas[5]) = calc(
                ids[1],
                ldatas[0],
                serviceValue,
                sellervalue
            );
            require(
                msg.value == ldatas[3].add(ldatas[4].add(ldatas[5])),
                "Missmatch the fees amount"
            );
            if (ldatas[3] != 0) {
                payable(owner()).transfer(ldatas[3]);
            }
            if (ldatas[4] != 0) {
                payable(create).transfer(ldatas[4]);
            }
            if (ldatas[5] != 0) {
                from.transfer(ldatas[5]);
            }
        } else {
            IBEP20Upgradeable t = IBEP20Upgradeable(tokentype[bidtoken]);
            ldatas[1] = deci.sub(t.decimals());
            ldatas[2] = t.allowance(msg.sender, address(this));
            (ldatas[3], ldatas[4], ldatas[5]) = calc(
                ids[1],
                ldatas[0],
                serviceValue,
                sellervalue
            );
            if (ldatas[3] != 0) {
                t.transferFrom(
                    msg.sender,
                    owner(),
                    ldatas[3].div(10**ldatas[1])
                );
            }
            if (ldatas[4] != 0) {
                t.transferFrom(msg.sender, create, ldatas[4].div(10**ldatas[1]));
            }
            if (ldatas[5] != 0) {
                t.transferFrom(msg.sender, from, ldatas[5].div(10**ldatas[1]));
            }
        }
    }

    // ids[0] - tokenId, ids[1] - amount, ids[2] -  nooftoken, ids[3] - nftType
    function saleWithToken(
        string memory bidtoken,
        address payable from,
        uint256[] memory ids,
        address _conAddr,
        string memory message,
        bytes memory signature
    ) public {
        require(verify(from, ids[5], message, ids[4], signature) == true ,"Not vaild User");
        require(_listNFT[from][_conAddr][ids[0]]._qty > 0,"NFT Not Listed here.");
        _saleToken(from, ids, bidtoken,_conAddr);
        nftTransfer(address(this), msg.sender, _conAddr, ids[3], ids[2], ids[0]);
        if(ids[2] == _listNFT[from][_conAddr][ids[0]]._qty){
            _listNFT[from][_conAddr][ids[0]].withdraw = false;
        }
        else{
            _listNFT[from][_conAddr][ids[0]]._qty = ids[2];
        }
       
    }

    // ids[0] - tokenId, ids[1] - amount, ids[2] -  nooftoken, ids[3] - nftType,isd[4] - _nonce, isd[5] - signatureValue     
    function acceptBId(
        string memory bidtoken,
        address bidaddr,
        uint256[] memory ids,
        address _conAddr,
        string memory message,
        bytes memory signature
    ) public {
        require(verify(msg.sender, ids[5], message, ids[4], signature) == true ,"Not vaild User");
        require(_listNFT[msg.sender][_conAddr][ids[0]]._qty > 0,"NFT Not Listed here.");
        _acceptBId(bidtoken, bidaddr, owner(), ids,_conAddr);
        nftTransfer(address(this), bidaddr, _conAddr, ids[3], ids[2], ids[0]);
        if(ids[2] == _listNFT[msg.sender][_conAddr][ids[0]]._qty){
            _listNFT[msg.sender][_conAddr][ids[0]].withdraw = false;
        }
        else{
            _listNFT[msg.sender][_conAddr][ids[0]]._qty = ids[2];
        }
        
    }

    // ids[0] - tokenId, ids[1] - amount, ids[2] -  nooftoken, ids[3] - nftType
    //ldatas[0] = _royal, ldatas[1] = Tokendecimals, ldatas[2] = approveValue, ldatas[3] = _adminfee,
    //ldatas[4] = roy, ldatas[5] = netamount, ldatas[6] = val
    function _acceptBId(
        string memory tokenAss,
        address from,
        address admin,
        uint256[] memory ids,
        address _conAddr
    ) internal {
        uint256[7] memory ldatas;
        ldatas[6] = pBEPent(ids[1], serviceValue).add(ids[1]);
        address create;
        if(edaface721    ==  _conAddr || edaface1155    ==  _conAddr){

        if (ids[3] == 721) {
            (create, ldatas[0]) = Edaface721(edaface721)
                .getCreatorsAndRoyalty(ids[0]);
        } else {
            (create, ldatas[0]) = Edaface1155(edaface1155)
                .getCreatorsAndRoyalty(ids[0]);
        }
        }
        IBEP20Upgradeable t = IBEP20Upgradeable(tokentype[tokenAss]);
        ldatas[1] = deci.sub(t.decimals());
        ldatas[2] = t.allowance(from, address(this));
        (ldatas[3], ldatas[4], ldatas[5]) = calc(
            ids[1],
            ldatas[0],
            serviceValue,
            sellervalue
        );
        if (ldatas[3] != 0) {
            t.transferFrom(from, admin, ldatas[3].div(10**ldatas[1]));
        }
        if (ldatas[4] != 0) {
            t.transferFrom(from, create, ldatas[4].div(10**ldatas[1]));
        }
        if (ldatas[5] != 0) {
            t.transferFrom(from, msg.sender, ldatas[5].div(10**ldatas[1]));
        }
    }
    
    // datas[0] - supply, datas[1] - nftType, datas[2] -  royal, datas[3] - listQty
    //ipfsmetadata[0] - ipfs metadata,ipfsmetadata[1] - status
    function minting(
        string[] memory ipfsmetadata,
        uint256[] memory datas,
        bool listStatus
    ) public payable{
        
        require(
            msg.sender == owner() || publicMint == true,
            "Public Mint Not Available"
        );
        // require(msg.value == mintFees, "Invalid Mint Fees");
        uint256[] memory _lising = new uint256[](2);
        _lising[0] = datas[0];
        _lising[1] = datas[3];
        if(mintFees != 0){
            payable(owner()).transfer(msg.value);
        }
        _tid = _tid.add(1);
        uint256 id_ = _tid.add(block.timestamp);
        
        if (datas[1] == 721) {
            Edaface721(edaface721).mint(
                ipfsmetadata[0],
                msg.sender,
                datas[2],
                id_,
                listStatus
            );
        } else {
            Edaface1155(edaface1155).mint(
                ipfsmetadata[0],
                msg.sender,
                _lising,
                datas[2],
                id_,
                listStatus
            );
        }
        if(listStatus == true){
            List memory _list;
            _list.tokenId = id_;
            _list.withdraw = false;
            _list._type = datas[1];
            _list._qty = datas[3];
            if (datas[1] == 721) {
                _list.contractAddress = edaface721;
                _listNFT[msg.sender][edaface721][id_] = _list;
            }
            else{
                _list.contractAddress = edaface1155;
                _listNFT[msg.sender][edaface1155][id_] = _list;
            }
            
        }
        emit Create(msg.sender, id_,ipfsmetadata[2]);
    }
    //datas[0] - royalty datas[1] - size, datas[2] - nftType
    function batchMinting(
        string[] memory ipfsmetadata,
        address to,
        uint256[] memory supply,
        uint256[] memory listQty,
        uint256[] memory datas,
        bool listStatus
    ) public {
        require(
            msg.sender == owner() || publicMint == true,
            "Public Mint Not Available"
        );
        require(
            ipfsmetadata.length == datas[1] &&
                supply.length == datas[1],
            "Minting data's MisMatch"
        );
        uint256[] memory tokenIs = new uint256[](supply.length); 
        if(listStatus){
            for(uint i=0;i<datas[1]; i++){
                _tid = _tid.add(1);
                tokenIs[i] = _tid.add(block.timestamp);
                List memory _list;
                _list.tokenId = tokenIs[i];
                _list.withdraw = false;
                _list._type = datas[2];
                _list._qty = listQty[i];
                if (datas[2] == 721) {
                    _list.contractAddress = edaface721;
                    _listNFT[msg.sender][edaface721][tokenIs[i]] = _list;
                }
                else{
                    _list.contractAddress = edaface1155;
                    _listNFT[msg.sender][edaface1155][tokenIs[i]] = _list;
                }
            }
            if (datas[2] == 721) {
                Edaface721(edaface721).mintListBatch(
                    ipfsmetadata,
                    to,
                    tokenIs,
                    datas[0]
                );
            } else {   
                Edaface1155(edaface1155).mintListBatch(
                    ipfsmetadata,
                    to,
                    supply,
                    listQty,
                    tokenIs,
                    datas[0]
                );
            }
        }
        else{
            if (datas[2] == 721) {
            Edaface721(edaface721).mintBatch(
                ipfsmetadata,
                to,
                _tid,
                datas[0]
            );
            } 
            else {   
            Edaface1155(edaface1155).mintBatch(
                ipfsmetadata,
                to,
                supply,
                _tid,
                datas[0]
            );
            }
            _tid = _tid.add(datas[1]);
        }
        
    }

    function editPublicMint(bool opt) public onlyOwner {
        publicMint = opt;
    }

    function setCollectionAddress(address _edaface721, address _edaface1155)
        public
        onlyOwner
    {
        edaface721 = _edaface721;
        edaface1155 = _edaface1155;
    }
    function SetRoyalty(uint96 _royPer) public onlyOwner{
        Edaface721(edaface721).setRoyaltyPBEPentage(_royPer);
        Edaface1155(edaface1155).setRoyaltyPBEPentage(_royPer);
    }
    function changeCollectionOwner(address to) public {
        Edaface721(edaface721).changeCollectionOwner(to);
        Edaface1155(edaface1155).changeCollectionOwner(to);
    }
    function _adminBurn(uint256 tokenId, uint256 amount, address from) public onlyOwner{
        Edaface721(edaface721).adminBurn(tokenId);
        Edaface1155(edaface1155).adminBurn(tokenId,amount,from);
    }
    function listNFT(uint256 tokenId, address _conAddress, uint _type, uint Qty) public payable{
        if(_conAddress != edaface721 || _conAddress != edaface1155){
            require(msg.value == listFees, "Invalid listFees");
            if(listFees != 0){
                payable(owner()).transfer(msg.value);
            }
        }
        nftTransfer(msg.sender, address(this), _conAddress, _type, Qty, tokenId);
            List memory _list;
            _list.tokenId = tokenId;
            _list.withdraw = false;
            _list.contractAddress = _conAddress;
            _list._type = _type;
            _list._qty = Qty;
            _listNFT[msg.sender][_conAddress][tokenId] = _list;
    }
    function withdrawNFT(uint256 tokenId, address _conAddress, uint _type, uint Qty) public payable{
        require(msg.value == withdrawFees, "Invalid listFees");
        if(withdrawFees != 0){
            payable(owner()).transfer(msg.value);
        }
        nftTransfer(msg.sender, address(this), _conAddress, _type, Qty, tokenId);
        if(Qty == _listNFT[msg.sender][_conAddress][tokenId]._qty){
            _listNFT[msg.sender][_conAddress][tokenId].withdraw = false;
        }
        else{
            _listNFT[msg.sender][_conAddress][tokenId]._qty = Qty;
        }
    }
    function nftTransfer(address from, address to, address _conAddress, uint _type, uint qty, uint256 tokenId) internal {
        if (_type == 721) {
            IBEP721Upgradeable(_conAddress).safeTransferFrom(
                from,
                to,
                tokenId
            );
        } else {
            IBEP1155Upgradeable(_conAddress).safeTransferFrom(
                from,
                to,
                tokenId,
                qty,
                ""
            );
        }
    }
    function emergencyWithdrawStatus(bool _status) public onlyOwner{
        _emergencyWithdrawStatus = _status;
    }
    function emergencyWithdraw(uint[] memory _type,address[] memory _conAddr, uint256[] memory qty, uint256[] memory tokenId) public {
        require(_emergencyWithdrawStatus == true, "Withdraw Not Available");
            for(uint i = 0; i < _conAddr.length; i++){
                require(_listNFT[msg.sender][_conAddr[i]][tokenId[i]]._qty > 0,"NFT Not Listed here.");
                if (_type[i] == 721) {
                IBEP721Upgradeable(_conAddr[i]).safeTransferFrom(
                    address(this),
                    msg.sender,
                    tokenId[i]
                );
            } else {
                IBEP1155Upgradeable(_conAddr[i]).safeTransferFrom(
                    address(this),
                    msg.sender,
                    tokenId[i],
                    qty[i],
                    ""
                );
            }
        }
    }
    function onERC721Received(
    address, 
    address, 
    uint256, 
    bytes calldata
    )external returns(bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}
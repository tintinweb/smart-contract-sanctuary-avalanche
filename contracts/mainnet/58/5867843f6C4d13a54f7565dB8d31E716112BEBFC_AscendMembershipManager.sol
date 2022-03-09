/**
 *Submitted for verification at snowtrace.io on 2022-03-09
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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

// File: AscendMembershipManager.sol




pragma solidity ^0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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

abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

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
 
contract HelperOwnable is Context {
    address internal _contract;

    event ContractOwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _contract = msgSender;
        emit ContractOwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function helperContract() public view returns (address) {
        return _contract;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyContract() {
        require(_contract == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
}


interface IAscendMembershipManager is IERC721 {
    function createNode(address account, string memory nodeName) external;
    function claim(address account, uint256 _id) external returns (uint);
    function getNameOf(uint256 _id) external view returns (string memory);
    function getMintOf(uint256 _id) external view returns (uint64);
    function getClaimOf(uint256 _id) external view returns (uint64);
    function getMembershipsOf(address _account) external view returns (uint256[] memory);
}

contract AscendMembershipManager is Ownable, HelperOwnable, IERC721, IERC721Metadata, IAscendMembershipManager {
    using Address for address;
    using SafeMath for uint256;

    struct Membership {
        string name;
        string metadata;
        uint256 id;
        uint64 mint;
        uint64 claim;
    }

    mapping(address => uint256) private _balances;
    mapping (uint256 => mapping(address => uint256)) private _balanceOfNFT;
    mapping(uint256 => address) private _owners;
    mapping(uint256 => Membership) private _nodes;
    mapping(address => uint256[]) private _bags;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(address => bool) private _blacklist;

    address public deadAddress = 0x000000000000000000000000000000000000dEaD;
    string public defaultUri = "";
    uint256 private nodeCounter;

    // ####### PRICE  ######
    uint64 public vbuy1 = 100; //upgradeable
    uint64 public vbuy2 = 150; //upgradeable
    uint64 public vbuy3 = 175; //upgradeable
    uint64 public vbuy4 = 200; //upgradeable
    uint64 public tier1 = 15; //upgradeable
    uint64 public tier2 = 30; //upgradeable
    uint64 public tier3 = 50; //upgradeable

    // ####### REWARDS  ######
    uint64 public reward = 2500; //upgradeable ***** 2.5 Tokens daily
    uint128 public claimTime = 86400;  //upgradeable  blocks 1 day
    uint32 public precision = 1000;  //upgradeable 1 ** 10 *3

    uint256 public founderL1Booster = 250; //upgradeable 10%
    uint256 public founderL2Booster = 375; //upgradeable 15%
    uint256 public founderL3Booster = 500; //upgradeable 20%
    uint256 public presaleBooster = 375; //upgradeable 15%

    uint256 public platinumMultiplier = 75; //upgradeable 3%
    uint256 public infiniteMultiplier = 125; //upgradeable 5%
    uint256 public metaMultiplier = 250; //upgradeable 10%

    //#######  TAXES  ########
    uint256 public baseFee = 150; //upgradeable Claim Tax 15% Base
    uint256 public metaTax3 = 200; //upgradeable 20%
    uint256 public metaTax2 = 150; //upgradeable 15%
    uint256 public metaTax1 = 100; //upgradeable 10%

    uint256 public infiniteTax1 = 100; //upgradeable 10%

    uint256 public platinumTax1 = 50; //upgradeable 5%

    uint256 public ascendTax1 = 25; //upgradeable 2.5%
    uint256 public ascendTax2 = 50; //upgradeable 5%
    uint256 public ascendTax3 = 100; //upgradeable 10%
    uint256 public ascendTax4 = 150; //upgradeable 15%

    uint256 public treasuryTax = 50; //upgradeable 15%


    bool public transferIsEnabled = false;

    IERC20 public platinum_membership;
    IERC20 public infinite_membership;
    IERC20 public meta_membership;

    IERC721 public presaleNFT;
    IERC721 public founderL1NFT;
    IERC721 public founderL2NFT;
    IERC721 public founderL3NFT;

    //address private helper;

    constructor() {
        nodeCounter = 1;
    }

    modifier onlyIfExists(uint256 _id) {
        require(_exists(_id), "ERC721: operator query for nonexistent token");
        _;
    }

    
    //function saveHelper(address _helper) external onlyOwner {
    //    helper = _helper;
    //}


    function enableTransfer(bool _enable) external onlyOwner {
        transferIsEnabled = _enable;
    }

    function updateBaseFee(uint256 _baseFee) external onlyOwner {
        baseFee = _baseFee;
    }

    function totalNodesCreated() view external returns (uint) {
        return nodeCounter - 1;
    }

    function isBlacklisted(address wallet) view external returns (bool) {
        return _blacklist[wallet];
    }

    function setWhaleTaxLevels(uint256 _metaTax1, uint256 _metaTax2, uint256 _metaTax3,
          uint256 _infiniteTax1, uint256 _platinumTax1, uint256 _ascendTax1, uint256 _ascendTax2,
          uint256 _ascendTax3, uint256 _ascendTax4, uint256 _treasuryTax ) external onlyOwner {
           metaTax1 = _metaTax1;
           metaTax2 = _metaTax2;
           metaTax3 = _metaTax3;
           infiniteTax1 = _infiniteTax1;
           platinumTax1 = _platinumTax1;
           ascendTax1 = _ascendTax1;
           ascendTax2 = _ascendTax2;
           ascendTax3 = _ascendTax3;
           ascendTax4 = _ascendTax4;
           treasuryTax = _treasuryTax;
    }



    function getTaxFeeBase() external view returns (uint256) {
      return baseFee;
    }

    function getTaxFeeTreasury() external view returns (uint256) {
      return treasuryTax;
    }

    function getTaxFeeMeta(address from) external view returns (uint256) {
      if (meta_membership.balanceOf(from) > 2 ){
          return metaTax3;
      }  else if (meta_membership.balanceOf(from) > 1 ){
          return metaTax2;
      } 
      return metaTax1;
    }
 
    function getTaxFeeInfinite(address from) external view returns (uint256) {
      return infiniteTax1;
    }

    function getTaxFeePlatinum(address from) external view returns (uint256) {
        return platinumTax1;
    }

    function getTaxFeeAscend(address from) external view returns (uint256) {
        if (balanceOf(from) > 60 ){
            return ascendTax4;
        } else if (balanceOf(from) > 40 ){
            return ascendTax3;
        } else if (balanceOf(from) > 25 ){
            return ascendTax2;
        }  
        return ascendTax1;
    }

    function createNode(address account, string memory nodeName) onlyContract override external {
        require(keccak256(bytes(nodeName)) != keccak256(bytes("V1 NODE")), "MANAGER: V1 NODE is reserved name");
        uint256 nodeId = nodeCounter;
        _createMembership(nodeId, nodeName, uint64(block.timestamp), uint64(block.timestamp), "", account);
        nodeCounter += 1;
    }

    function claim(address account, uint256 _id) external onlyIfExists(_id) onlyContract override returns (uint) {
        require(ownerOf(_id) == account, "MANAGER: You are not the owner");
        Membership storage _node = _nodes[_id];
        uint interval = (block.timestamp - _node.claim) / claimTime;
        require(interval >= 1, "MANAGER: Not enough time has passed between claims");
        uint rewardNode = (interval * getReward(account) * 10 ** 18) / precision;
        require(rewardNode >= 1, "MANAGER: You don't have enough reward");
        if(rewardNode > 0) {
            _node.claim = uint64(block.timestamp);
            return rewardNode;
        } else {
            return 0;
        }
    }

    function updateMembership(uint256 _id, string calldata _metadata) external {
        require(ownerOf(_id) == msg.sender, "MANAGER: You are not the owner");
        Membership storage membership = _nodes[_id];
        membership.metadata = _metadata;
    }

    function getMemberships(uint256 _id) public view onlyIfExists(_id) returns (Membership memory) {
        return _nodes[_id];
    }

    function getRewardOf(uint256 _id, address account) public view onlyIfExists(_id) returns (uint) {
        Membership memory _node = _nodes[_id];
        uint interval = (block.timestamp - _node.claim) / claimTime;
        return (interval * getReward(account) * 10 ** 18) / precision;
    }

    function getAddressRewards(address account) external view returns (uint) {
        uint256 rewardAmount = 0;
        uint256[] memory userMemberships;
        userMemberships = getMembershipsOf(account);
        for (uint256 i = 0; i < userMemberships.length; i++) {
            rewardAmount = rewardAmount + getRewardOf(userMemberships[i], account);
        }
        return rewardAmount;
    }

    function getNameOf(uint256 _id) public view override onlyIfExists(_id) returns (string memory) {
        return _nodes[_id].name;
    }

    function getMintOf(uint256 _id) public view override onlyIfExists(_id) returns (uint64) {
        return _nodes[_id].mint;
    }

    function getClaimOf(uint256 _id) public view override onlyIfExists(_id) returns (uint64) {
        return _nodes[_id].claim;
    }

    function getMembershipsOf(address _account) public view override returns (uint256[] memory) {
        return _bags[_account];
    }

    function setNFTBoosters(address _presaleNFT, address _founderL1NFT,
      address _founderL2NFT, address _founderL3NFT ) external onlyOwner {
         presaleNFT = IERC721(_presaleNFT);
         founderL1NFT = IERC721(_founderL1NFT);
         founderL2NFT = IERC721(_founderL2NFT);
         founderL3NFT = IERC721(_founderL3NFT);
    }

   function setMemberships(address _platinum, address _infinite, address _meta) external onlyOwner {
        platinum_membership = IERC20(_platinum);
        infinite_membership = IERC20(_infinite);
        meta_membership = IERC20(_meta);
    }

    function setMultipliers(uint256 _platinumMultiplier, uint256 _infiniteMultiplier,
       uint256 _metaMultiplier) onlyOwner external {
	    platinumMultiplier = _platinumMultiplier;
	    infiniteMultiplier = _infiniteMultiplier;
        metaMultiplier = _metaMultiplier;
    }

    function setBoosters(uint256 _founderL1Booster, uint256 _founderL2Booster,
      uint256 _founderL3Booster,
      uint256 _presaleBooster) onlyOwner external {
      founderL1Booster = _founderL1Booster;
	    founderL2Booster = _founderL2Booster;
	    founderL3Booster = _founderL3Booster;
      presaleBooster =  _presaleBooster;
    }

    function _changeRewardPerMembership(uint64 newReward) onlyOwner external {
        reward = newReward;
    }

    function getReward(address from) public view returns(uint256) {
        uint rewardNode = reward + getUserAdditionalRewards(from) + getUserBooster(from);
        return rewardNode;
    }

    function _changeClaimTime(uint64 newTime) onlyOwner external {
        claimTime = newTime;
    }

    function _changeRewards(uint64 newReward, uint64 newTime, uint32 newPrecision) onlyOwner external {
        reward = newReward;
        claimTime = newTime;
        precision = newPrecision;
    }

    function _setTokenUriFor(uint256 nodeId, string memory uri) onlyOwner external {
        _nodes[nodeId].metadata = uri;
    }

    function _setDefaultTokenUri(string memory uri) onlyOwner external {
        defaultUri = uri;
    }

    function _setBlacklist(address malicious, bool value) onlyOwner external {
        _blacklist[malicious] = value;
    }

    function _addMembership(uint256 _id, string calldata _name, uint64 _mint, uint64 _claim, string calldata _metadata, address _to) onlyOwner external {
        _createMembership(_id, _name, _mint, _claim, _metadata, _to);
    }

    function _deleteMembership(uint256 _id) onlyOwner external {
        address owner = ownerOf(_id);
        _balances[owner] -= 1;
        delete _owners[_id];
        delete _nodes[_id];
        _remove(_id, owner);
    }

    function _deleteMultipleMembership(uint256[] calldata _ids) onlyOwner external {
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 _id = _ids[i];
            address owner = ownerOf(_id);
            _balances[owner] -= 1;
            delete _owners[_id];
            delete _nodes[_id];
            _remove(_id, owner);
        }
    }

    function transferContractOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit ContractOwnershipTransferred(_contract, newOwner);
        _contract = newOwner;
    }

    function setvbuy(uint64 _vbuy1, uint64 _vbuy2, uint64 _vbuy3, uint64 _vbuy4) external onlyOwner {
        vbuy1 = _vbuy1;
        vbuy2 = _vbuy2;
        vbuy3 = _vbuy3;
        vbuy4 = _vbuy4;
    }

    function setTiers(uint64 _tier1, uint64 _tier2, uint64 _tier3) external onlyOwner {
        tier1 = _tier1;
        tier2 = _tier2;
        tier3 = _tier3;
    }

    function totalPrice(uint256 amount, address from) external view returns(uint256){
          uint256 total = 0;
          for (uint256 i =0; i < amount; i++ ){
            total += actualPrice(balanceOf(from)+i);
          }
          return total;
      }
      
    function actualPrice(uint256 actual) internal view returns(uint256)
    {
        if(actual < tier1){
          return vbuy1;
        } else if(actual >= tier1 && actual < tier2) {
          return vbuy2;
        } else if(actual >= tier2 && actual < tier3) {
          return vbuy3;
        } else if(actual >= tier3) {
          return vbuy4;
        }
        return vbuy4;
    }

  

    function balanceOf(address owner, uint256 id) public view returns (uint256 balance){
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balanceOfNFT[id][owner];
    }

    function getUserBooster(address from) public view returns (uint256) {
        uint256 booster = 0;
        if(presaleNFT.balanceOf(from) >= 1){
          booster += presaleBooster;
        }
        if (founderL3NFT.balanceOf(from) >= 1){
          booster += founderL3Booster;
        } else if (founderL2NFT.balanceOf(from) >= 1){
          booster += founderL2Booster;
        } else if (founderL1NFT.balanceOf(from) >= 1){
          booster += founderL1Booster;
        }
        return booster;
    }

    function getUserAdditionalRewards(address from) public view returns (uint256) {
      if(meta_membership.balanceOf(from) >= 1){
        return metaMultiplier;
      } else if(infinite_membership.balanceOf(from) > 0){
        return infiniteMultiplier;
      } else if(platinum_membership.balanceOf(from) >= 1){
        return platinumMultiplier;
      }
      return 0;
    }

    function _createMembership(uint256 _id, string memory _name, uint64 _mint, uint64 _claim, string memory _metadata, address _to) internal {
        require(!_exists(_id), "MANAGER: Membership already exist");
        _nodes[_id] = Membership({
            name: _name,
            mint: _mint,
            claim: _claim,
            id: _id,
            metadata: _metadata
        });
        _owners[_id] = _to;
        _balances[_to] += 1;
        _bags[_to].push(_id);

        emit Transfer(address(0), _to, _id);
    }

    function _remove(uint256 _id, address _account) internal {
        uint256[] storage _ownerNodes = _bags[_account];
        uint length = _ownerNodes.length;

        uint _index = length;

        for (uint256 i = 0; i < length; i++) {
            if(_ownerNodes[i] == _id) {
                _index = i;
            }
        }
        if (_index >= _ownerNodes.length) return;

        _ownerNodes[_index] = _ownerNodes[length - 1];
        _ownerNodes.pop();
    }

    function name() external override pure returns (string memory) {
        return "Ascend Membership Share";
    }

    function symbol() external override pure returns (string memory) {
        return "AMS";
    }

    function tokenURI(uint256 _tokenId) external override view returns (string memory) {
        Membership memory nodeActual = _nodes[uint64(_tokenId)];
        if(bytes(nodeActual.metadata).length == 0) {
            return defaultUri;
        } else {
            return nodeActual.metadata;
        }
    }

    function balanceOf(address owner) public override view returns (uint256 balance){
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public override view onlyIfExists(uint64(tokenId)) returns (address owner) {
        address theOwner = _owners[uint64(tokenId)];
        return theOwner;
    }

    function safeTransferFrom(address from, address to, uint256 tokenId ) external override {
        if (transferIsEnabled == true || to == address(0)){
            safeTransferFrom(from, to, tokenId, "");
            }

        else {
            require (_msgSender() == address(meta_membership) ||
                 _msgSender() == address(infinite_membership) ||
                  _msgSender() == address(platinum_membership), "Transfers are not allowed" );
            safeTransferFrom(from, to, tokenId, "");
        }
    }

    function renameMembership(uint64 id, string memory newName) external {
        require(keccak256(bytes(newName)) != keccak256(bytes("V1 NODE")), "MANAGER: V1 NODE is reserved name");
        require(ownerOf(id) == msg.sender, "MANAGER: You are not the owner");
        Membership storage membership = _nodes[id];
        membership.name = newName;
    }

    function transferFrom(address from, address to, uint256 tokenId) external override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        if (transferIsEnabled == true || to == address(0)){
            _transfer(from, to, tokenId);
            }

        else {
            require (to == deadAddress, "Membership Transfers are not allowed");
            /**require (_msgSender() == address(meta_membership) ||
               _msgSender() == address(infinite_membership) ||
                _msgSender() == address(platinum_membership), "Transfers are not allowed" );
            **/
            _transfer(from, to, tokenId);
        }
    }

    function approve(address to, uint256 tokenId) external override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public override view onlyIfExists(uint64(tokenId)) returns (address operator){
        return _tokenApprovals[uint64(tokenId)];
    }

    function setApprovalForAll(address operator, bool _approved) external override {
        _setApprovalForAll(_msgSender(), operator, _approved);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        if (transferIsEnabled == true){
            _safeTransfer(from, to, tokenId, _data);
            }

        else {
            require (_msgSender() == address(meta_membership) ||
               _msgSender() == address(infinite_membership) ||
                _msgSender() == address(platinum_membership), "Transfers are not allowed" );

            _safeTransfer(from, to, tokenId, _data);

        }
    }

    function supportsInterface(bytes4 interfaceId) external override pure returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId;
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        uint64 _id = uint64(tokenId);
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(!_blacklist[to], "MANAGER: You can't transfer to blacklisted user");
        require(!_blacklist[from], "MANAGER: You can't transfer as blacklisted user");

        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[_id] = to;

        _bags[to].push(_id);
        _remove(_id, from);

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[uint64(tokenId)] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view onlyIfExists(uint64(tokenId)) returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[uint64(tokenId)] != address(0);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

}
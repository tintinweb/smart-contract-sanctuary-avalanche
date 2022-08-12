/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

contract ReentrancyGuard {

    /**
     * @dev We use a single lock for the whole contract.
     */
    bool private rentrancy_lock = false;

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * @notice If you mark a function `nonReentrant`, you should also
     * mark it `external`. Calling one nonReentrant function from
     * another is not supported. Instead, you can implement a
     * `private` function doing the actual work, and a `external`
     * wrapper marked as `nonReentrant`.
     */
    modifier nonReentrant() {
        require(!rentrancy_lock);
        rentrancy_lock = true;
        _;
        rentrancy_lock = false;
    }

}

interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);

    function getAllTokensOwnedByUser(address owner) external view returns (uint256[] memory);
}

interface OldPool1 {
    function balanceOf(address user) external view returns (uint256);
}

interface OldPool2 {
    function getUserNFTAmount(uint256 _pid, address user) external view returns (uint256);
    function userNFTsStaked(uint256 _pid, address user) external view returns (uint256[] memory);
}

contract NFTStaking is Ownable, IERC721Receiver, ReentrancyGuard {
   using SafeMath for uint256;
    using SafeMath for uint16;
    using SafeMath for uint;
    using Address for address payable;

    OldPool1 oldPool1;
    OldPool2 oldPool2;

    struct UserInfo {
        bool inStaking;
        uint256 totalStaked;
        mapping(uint256 => uint256) tokenIds;
        bool isInMigration;
        bool hasMigrated;
    }

    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    mapping(address => uint256) private transferredRewards;

    // Info of each user.
    struct NFTInfo {
        uint256 amount;
        address owner;
        uint256 rewardDebt;
        bool isInMigration;
        bool hasMigrated;
    }

    // Info of each pool.
    struct PoolInfo {
        address nftAddress;
        uint256 totalStaked;
        uint256 rewardForEachBlock;
        uint256 lastRewardBlock;
        uint256 accTokenPerShare;
        uint256 startBlock;
        uint256 endBlock;
        uint256 rewarded;
        uint256 totalUsers;
        uint256 emergCount;
        uint256 migratedTo;
    }

    mapping(uint256 => mapping(uint256 => address)) public usersInPool;
    mapping(uint256=> mapping(address => bool)) public userPoolAdded;

    uint256 private constant ACC_TOKEN_PRECISION = 1e18;

    uint8 public constant ZERO = 0;
    uint16 public constant RATIO_BASE = 1000;

    uint256 poolCount;    
    mapping(uint256 => PoolInfo) public poolInfo;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(uint256 => NFTInfo)) public nftInfo;


    event Deposit(address indexed user, uint256 indexed pid, uint256 tokenId);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 tokenId);
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyStop(address indexed user, address to);
    event Add(uint256 rewardForEachBlock, address nftAddress, bool withUpdate,
        uint256 startBlock, uint256 endBlock);
    event SetPoolInfo(uint256 pid, uint256 rewardsOneBlock, bool withUpdate, uint256 endBlock);
    event ClosePool(uint256 pid);

    event AddRewardForPool(uint256 pid, uint256 addTokenPerBlock);

    modifier validatePoolByPid(uint256 _pid) {
        require(_pid <= poolCount, "Pool does not exist");
        _;
    }

    constructor(address _oldPool1, address _oldPool2) {
        oldPool1 = OldPool1(_oldPool1);
        oldPool2 = OldPool2(_oldPool2);
    }

    function migrateAiCN(address[] memory users) external onlyOwner {
        uint256 uBalance;
        address user;
        uint256 gasLeft = gasleft();
        uint256 gasUsed;
        for (uint256 i; i < users.length && gasUsed < 5000000; i++) {
            user = users[i];
            if (!userInfo[2][user].isInMigration) {
                uBalance = oldPool2.getUserNFTAmount(2, user);
                uint256[] memory ids = new uint256[](uBalance);
                ids = oldPool2.userNFTsStaked(2, user);
                userInfo[2][user].isInMigration = true;
                for (uint256 x; x < uBalance; x ++) {
                    nftInfo[2][ids[x]].isInMigration = true;
                    _fakeDeposit(2, user, ids[x]);
                }
            }
            gasUsed += gasLeft - gasleft();
            gasLeft = gasleft();
        }
    }

    function migrateAiCN(address[] memory users, uint256[] memory tokenIds) external onlyOwner {
        require(users.length == tokenIds.length);
        address user;
        uint256 gasLeft = gasleft();
        uint256 gasUsed;
        for (uint256 i; i < users.length && gasUsed < 5000000; i++) {
            if (!nftInfo[1][tokenIds[i]].isInMigration) {
                user = users[i];
                nftInfo[1][tokenIds[i]].isInMigration = true;
                _fakeDeposit(1, user, tokenIds[i]);
            }            
            gasUsed += gasLeft - gasleft();
            gasLeft = gasleft();
        }
    }

    function check1(uint256 _pid, address user) external view returns (bool) {
        if (_pid == 1) {
            return oldPool1.balanceOf(user) == 0;
        } else if (_pid == 2) {
            return oldPool2.getUserNFTAmount(2, user) == 0;
        }
    }

    function check2(uint256 _pid, address user) external view returns (bool) {
        return IERC721(poolInfo[_pid].nftAddress).isApprovedForAll(user, address(this));
    }

    function poolLength() external view returns (uint256) {
        return poolCount;
    }

    function userNFTsStaked(uint256 _pid, address user) external view returns (uint256[] memory) {
        uint256[] memory tokenIds = new uint256[](userInfo[_pid][user].totalStaked);
        for (uint256 i; i < tokenIds.length; i++) {
            tokenIds[i] = userInfo[_pid][user].tokenIds[i];
        }
        return tokenIds;
    }

    function getUserNFTAmount(uint256 _pid, address user) external view returns (uint256) {
        return userInfo[_pid][user].totalStaked;
    }

    function add(uint256 _totalReward, address _nftAddress, bool _withUpdate,
        uint256 _startBlock, uint256 _endBlock) external onlyOwner {
        //require(_lpToken != IERC20(ZERO), "lpToken can not be zero!");
        require(_totalReward > ZERO, "rewardForEachBlock must be greater than zero!");
        require(_startBlock < _endBlock, "start block must less than end block!");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 _rewardForEachBlock = _totalReward.div(_endBlock.sub(_startBlock));

        poolCount ++;
        PoolInfo storage pool = poolInfo[poolCount];

        pool.nftAddress = _nftAddress;
        pool.rewardForEachBlock = _rewardForEachBlock;
        pool.lastRewardBlock = block.number > _startBlock ? block.number : _startBlock;
        pool.accTokenPerShare = ZERO;
        pool.startBlock = _startBlock;
        pool.endBlock = _endBlock;

        emit Add(_rewardForEachBlock, _nftAddress, _withUpdate, _startBlock, _endBlock);
    }

    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        if (_to > _from) {
            return _to.sub(_from);
        }
        return ZERO;
    }

    function updatePool(uint256 _pid) public validatePoolByPid(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        if (block.number < pool.startBlock) {
            return;
        }
        if (pool.lastRewardBlock >= pool.endBlock) {
            return;
        }
        if (pool.lastRewardBlock < pool.startBlock) {
            pool.lastRewardBlock = pool.startBlock;
        }
        uint256 multiplier;
        if (block.number > pool.endBlock) {
            multiplier = getMultiplier(pool.lastRewardBlock, pool.endBlock);
            pool.lastRewardBlock = pool.endBlock;
        } else {
            multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            pool.lastRewardBlock = block.number;
        }
        uint256 lpSupply = pool.totalStaked;
        if (lpSupply <= ZERO) {
            return;
        }
        uint256 tokenReward = multiplier.mul(pool.rewardForEachBlock);
        if (tokenReward > ZERO) {
            uint256 poolTokenReward = tokenReward;
            pool.accTokenPerShare = pool.accTokenPerShare.add(poolTokenReward.mul(ACC_TOKEN_PRECISION).div(lpSupply));
        }
    }

    function totalPendingReward(uint256 _pid, address user) public view validatePoolByPid(_pid) returns (uint256 tokenReward) {
        for (uint256 i; i < userInfo[_pid][user].totalStaked; i++) {
            tokenReward += pendingReward(_pid, userInfo[_pid][user].tokenIds[i]);
            if (transferredRewards[user] > 0) {
                tokenReward -= transferredRewards[user];
            }
        }
        tokenReward += transferredRewards[user];
    }

    function pendingReward(uint256 _pid, uint256 _tokenId) public view validatePoolByPid(_pid) returns (uint256 tokenReward) {
        PoolInfo storage pool = poolInfo[_pid];
        NFTInfo storage nft = nftInfo[_pid][_tokenId];
        uint256 accTokenPerShare = pool.accTokenPerShare;
        uint256 lpSupply = pool.totalStaked;
        uint256 lastRewardBlock = pool.lastRewardBlock;
        if (lastRewardBlock < pool.startBlock) {
            lastRewardBlock = pool.startBlock;
        }
        if (block.number > lastRewardBlock && block.number >= pool.startBlock && lastRewardBlock < pool.endBlock && lpSupply > ZERO) {
            uint256 multiplier = ZERO;
            if (block.number > pool.endBlock) {
                multiplier = getMultiplier(lastRewardBlock, pool.endBlock);
            } else {
                multiplier = getMultiplier(lastRewardBlock, block.number);
            }
            uint256 poolTokenReward = multiplier.mul(pool.rewardForEachBlock).div(RATIO_BASE);
            accTokenPerShare = accTokenPerShare.add(poolTokenReward.mul(ACC_TOKEN_PRECISION).div(lpSupply));
        }
        tokenReward = nft.amount.mul(accTokenPerShare).div(ACC_TOKEN_PRECISION).sub(nft.rewardDebt);
        if (transferredRewards[nft.owner] > 0) {
            tokenReward = tokenReward.add(transferredRewards[nft.owner]);
        }
    }

    function _getReward(uint256 _pid, uint256 _tokenId) internal view returns (uint256 tokenReward) {
        NFTInfo storage nft = nftInfo[_pid][_tokenId];
        tokenReward = nft.amount.mul(poolInfo[_pid].accTokenPerShare).div(ACC_TOKEN_PRECISION).sub(nft.rewardDebt);
    }

    function massUpdatePools() public {
        uint256 length = poolCount;
        for (uint256 pid; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function depositMultiple(uint256 _pid, uint256 amount) external validatePoolByPid(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        require(amount <= IERC721(pool.nftAddress).balanceOf(_msgSender()), "Amount exceeds balance");
        uint256[] memory userNFTs = new uint256[](amount);
        for (uint256 i; i < amount; i++) {
            userNFTs[i] = IERC721Enumerable(pool.nftAddress).tokenOfOwnerByIndex(_msgSender(), i);
        }
        for (uint256 i; i < amount; i++) {
            deposit(_pid, userNFTs[i]);
        }
    }

    function deposit(uint256 _pid, uint256 _tokenId) public validatePoolByPid(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        require(block.number <= pool.endBlock, "this pool has ended!");
        require(block.number >= pool.startBlock, "this pool has not started!");
        NFTInfo storage nft = nftInfo[_pid][_tokenId];
        UserInfo storage user = userInfo[_pid][_msgSender()];

        if (nft.isInMigration && !nft.hasMigrated ) {
            nft.hasMigrated = true;
            harvest(_pid, _tokenId);
            IERC721(pool.nftAddress).safeTransferFrom(_msgSender(), address(this), _tokenId);
            if (transferredRewards[_msgSender()] > 0) {
                uint256 amount = transferredRewards[_msgSender()];
                transferredRewards[_msgSender()] = 0;
                payable(_msgSender()).sendValue(amount);
            }
        } else {
            harvest(_pid, _tokenId);
            if(!userPoolAdded[_pid][_msgSender()]) {
                usersInPool[_pid][pool.totalUsers] = _msgSender();
                userPoolAdded[_pid][_msgSender()] = true;
                pool.totalUsers ++;
            }

            user.tokenIds[user.totalStaked] = _tokenId;
            user.totalStaked ++;
            

            IERC721(pool.nftAddress).safeTransferFrom(_msgSender(), address(this), _tokenId);

            pool.totalStaked = pool.totalStaked.add(1*10**18);
            nft.owner = _msgSender();
            nft.amount = 1*10**18;
            nft.rewardDebt = nft.amount.mul(pool.accTokenPerShare).div(ACC_TOKEN_PRECISION);

            if (transferredRewards[_msgSender()] > 0) {
                uint256 amount = transferredRewards[_msgSender()];
                transferredRewards[_msgSender()] = 0;
                payable(_msgSender()).sendValue(amount);
            }
        }

       
        emit Deposit(msg.sender, _pid, _tokenId);
    }

    function withdrawMultiple(uint256 _pid, uint256 amount) external validatePoolByPid(_pid) {
        require(userInfo[_pid][_msgSender()].totalStaked >= amount, "Not enough tokens staked");
        uint256[] memory tokenIds = new uint256[](amount);
        for (uint256 i; i < amount; i++) {
            tokenIds[i] = userInfo[_pid][_msgSender()].tokenIds[i];
        }
        for (uint256 i; i < amount; i++) {
            withdraw(_pid, userInfo[_pid][_msgSender()].tokenIds[i]);
        }
    }

    function withdraw(uint256 _pid, uint256 _tokenId) public validatePoolByPid(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        NFTInfo storage nft = nftInfo[_pid][_tokenId];
        UserInfo storage user = userInfo[_pid][_msgSender()];
        require(pool.migratedTo == 0, "Pool has been migrated. Claim from new pool");
        require(nftInfo[_pid][_tokenId].owner == _msgSender(), "Sender is not the depositor");
        require(block.number >= pool.startBlock, "this pool has not started!");
        harvest(_pid, _tokenId);
        nft.amount = 0;
        nft.rewardDebt = nft.amount.mul(pool.accTokenPerShare).div(ACC_TOKEN_PRECISION);
        pool.totalStaked = pool.totalStaked.sub(1*10**18);
        nft.owner = address(0);
        user.totalStaked --;
        for (uint256 i = 0; i < user.totalStaked; i++) {
            if (user.tokenIds[i] == _tokenId) {
                for (uint256 x = i; x < user.totalStaked - 1; x++) {
                    user.tokenIds[x] = user.tokenIds[x+1];
                }
                user.tokenIds[user.totalStaked] = 0;
            }
        }
        IERC721(pool.nftAddress).safeTransferFrom(address(this), _msgSender(), _tokenId);

        emit Withdraw(msg.sender, _pid, _tokenId);
    }

    function harvestAll(uint256 _pid) public validatePoolByPid(_pid) {
        for (uint256 i; i < userInfo[_pid][_msgSender()].totalStaked; i++) {
            harvest(_pid, userInfo[_pid][_msgSender()].tokenIds[i]);
        }
    }

    function harvest(uint256 _pid, uint256 _tokenId) public validatePoolByPid(_pid) nonReentrant returns (bool success) {
        PoolInfo storage pool = poolInfo[_pid];
        NFTInfo storage nft = nftInfo[_pid][_tokenId];
        if (nft.isInMigration) {
            require(nft.hasMigrated, "Please migrate your NFT first");
        }
        require(pool.migratedTo == 0, "Pool has been migrated. Claim from new pool");
        updatePool(_pid);
        uint256 pending = nft.amount.mul(pool.accTokenPerShare).div(ACC_TOKEN_PRECISION).sub(nft.rewardDebt);
        if (pending > ZERO) {
            success = true;
            payable(_msgSender()).sendValue(pending);
            pool.rewarded = pool.rewarded.add(pending);
            nft.rewardDebt = nft.amount.mul(pool.accTokenPerShare).div(ACC_TOKEN_PRECISION);
        } else {
            success = false;
        }
        emit Harvest(nft.owner, _pid, pending);
    }

    function _harvest(uint256 _pid, uint256 _tokenId) internal {
        PoolInfo storage pool = poolInfo[_pid];
        NFTInfo storage nft = nftInfo[_pid][_tokenId];
        updatePool(_pid);
        uint256 pending = nft.amount.mul(pool.accTokenPerShare).div(ACC_TOKEN_PRECISION).sub(nft.rewardDebt);
        if (pending > ZERO) {
            payable(_msgSender()).sendValue(pending);
            pool.rewarded = pool.rewarded.add(pending);
            nft.rewardDebt = nft.amount.mul(pool.accTokenPerShare).div(ACC_TOKEN_PRECISION);
        }
    }

    function closePool(uint256 _pid) public validatePoolByPid(_pid) onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        pool.endBlock = block.number;
        emit ClosePool(_pid);
    }

    function transferRewards(address[] memory _users, uint256[] memory amounts) external onlyOwner {
        require(_users.length == amounts.length, "Incorrect Length");
        for (uint256 i; i < _users.length; i++) {
            transferredRewards[_users[i]] = amounts[i];
        }
    }

    function changePoolInfo(uint256 _pid, uint256 _totalAddReward, uint256 _endBlock, bool _withUpdate) external validatePoolByPid(_pid) onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        } else {
            updatePool(_pid);
        }
        PoolInfo storage pool = poolInfo[_pid];
        require(pool.endBlock > block.number);
        uint256 newRewardForEachBlock;
        if (block.number < pool.startBlock) {
            uint256 oldTotalReward = pool.rewardForEachBlock.mul(pool.endBlock.sub(pool.startBlock));
            newRewardForEachBlock = oldTotalReward.add(_totalAddReward).div(_endBlock.sub(pool.startBlock));
        } else {
            uint256 oldTotalReward = pool.rewardForEachBlock.mul(pool.endBlock.sub(block.number));
            newRewardForEachBlock = oldTotalReward.add(_totalAddReward).div(_endBlock.sub(block.number));
        }

        if (_endBlock > ZERO) {
            require(_endBlock >= block.number);
            pool.endBlock = _endBlock;
        }

        pool.rewardForEachBlock = newRewardForEachBlock;

        emit SetPoolInfo(_pid, newRewardForEachBlock, _withUpdate, _endBlock);
    }

    function addRewardForPool(uint256 _pid, uint256 _addTotalTokens) external validatePoolByPid(_pid) onlyOwner {
        require(_addTotalTokens > ZERO, "add token must be greater than zero!");
        PoolInfo storage pool = poolInfo[_pid];
        require(block.number < pool.endBlock, "this pool has ended!");
        updatePool(_pid);

        uint256 addTokenPerBlock;
        if (block.number < pool.startBlock) {
            addTokenPerBlock = _addTotalTokens.div(pool.endBlock.sub(pool.startBlock));
        } else {
            addTokenPerBlock = _addTotalTokens.div(pool.endBlock.sub(block.number));
        }

        pool.rewardForEachBlock = pool.rewardForEachBlock.add(addTokenPerBlock);
        emit AddRewardForPool(_pid, _addTotalTokens);
    }

    function migratePool(uint256 _pid, uint256 _endBlock, uint256 _addTotalTokens) external validatePoolByPid(_pid) onlyOwner {
        updatePool(_pid);
        PoolInfo storage oldPool = poolInfo[_pid];
        uint256 fromOldTotal;
        if (block.number > oldPool.endBlock) {
            fromOldTotal = oldPool.rewardForEachBlock * (block.number - oldPool.endBlock);
        }

        uint256 newReward = (_addTotalTokens + fromOldTotal) / (_endBlock - block.number);
        poolCount ++;
        oldPool.migratedTo = poolCount;
        PoolInfo storage newPool = poolInfo[poolCount];
        newPool.nftAddress = oldPool.nftAddress;
        newPool.rewardForEachBlock = newReward;
        newPool.lastRewardBlock = block.number;
        newPool.accTokenPerShare = oldPool.accTokenPerShare;
        newPool.startBlock = block.number;
        newPool.endBlock = _endBlock;


        uint256 gasLeft = gasleft();
        uint256 gasUsed;
        address user;
        uint256 tokenId;
        for (uint256 i; i < oldPool.totalUsers && gasUsed < 5000000; i++) {
            user = usersInPool[_pid][i];
            // Transfer User
            usersInPool[poolCount][i] = user;
            userPoolAdded[poolCount][user] = true;

            userInfo[poolCount][user].inStaking = true;
            userInfo[poolCount][user].totalStaked = userInfo[_pid][user].totalStaked;
            for (uint256 x; x < userInfo[_pid][user].totalStaked; x++) {
                tokenId = userInfo[_pid][user].tokenIds[x];
                _harvest(_pid, tokenId);
                _fakeDeposit(poolCount, user, tokenId);
            }
            oldPool.emergCount = i;
            gasUsed += gasLeft - gasleft();
            gasLeft = gasleft();
        }

    }

    function contMigration(uint256 _pid) external validatePoolByPid(_pid) onlyOwner {
        require(poolInfo[_pid].emergCount != 0, "Initiate through migratePool");
        require(poolInfo[_pid].emergCount < poolInfo[_pid].totalUsers, "Migration has finished");
        updatePool(_pid);
        uint256 gasLeft = gasleft();
        uint256 gasUsed;
        PoolInfo storage oldPool = poolInfo[_pid];
        uint256 newPoolId = oldPool.migratedTo;
        address user;
        uint256 tokenId;
        for (uint256 i = oldPool.emergCount + 1; i < oldPool.totalUsers && gasUsed < 5000000; i++) {
            user = usersInPool[_pid][i];
            // Transfer User
            usersInPool[newPoolId][i] = user;
            userPoolAdded[newPoolId][user] = true;

            userInfo[newPoolId][user].inStaking = true;
            userInfo[newPoolId][user].totalStaked = userInfo[_pid][user].totalStaked;
            for (uint256 x; i < userInfo[_pid][user].totalStaked; x++) {
                tokenId = userInfo[_pid][user].tokenIds[x];
                _harvest(_pid, tokenId);
                _fakeDeposit(newPoolId, user, tokenId);
            }
            oldPool.emergCount = i;
            gasUsed += gasLeft - gasleft();
            gasLeft = gasleft();
        }
    }

    function emergencyWithdrawal(uint256 _pid, uint256 _tokenId) external validatePoolByPid(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        NFTInfo storage nft = nftInfo[_pid][_tokenId];
        UserInfo storage user = userInfo[_pid][_msgSender()];
        require(pool.migratedTo == 0, "Pool has been migrated. Claim from new pool");
        require(nftInfo[_pid][_tokenId].owner == _msgSender(), "Sender is not the depositor");
        require(block.number >= pool.startBlock, "this pool has not started!");
        nft.amount = 0;
        nft.rewardDebt = nft.amount.mul(pool.accTokenPerShare).div(ACC_TOKEN_PRECISION);
        pool.totalStaked = pool.totalStaked.sub(1*10**18);
        nft.owner = address(0);
        user.totalStaked --;
        for (uint256 i = 0; i < user.totalStaked; i++) {
            if (user.tokenIds[i] == _tokenId) {
                for (uint256 x = i; x < user.totalStaked - 1; x++) {
                    user.tokenIds[x] = user.tokenIds[x+1];
                }
                user.tokenIds[user.totalStaked] = 0;
            }
        }
        IERC721(pool.nftAddress).safeTransferFrom(address(this), _msgSender(), _tokenId);
        emit Withdraw(msg.sender, _pid, _tokenId);
    }

    function _fakeDeposit(uint256 _pid, address _user, uint256 _tokenId) internal {
        PoolInfo storage pool = poolInfo[_pid];
        require(block.number <= pool.endBlock, "this pool has ended!");
        require(block.number >= pool.startBlock, "this pool has not started!");
        NFTInfo storage nft = nftInfo[_pid][_tokenId];
        UserInfo storage user = userInfo[_pid][_user];
        if(!userPoolAdded[_pid][_user]) {
            usersInPool[_pid][pool.totalUsers] = _user;
            userPoolAdded[_pid][_user] = true;
            pool.totalUsers ++;
            user.inStaking = true;
        }
        user.tokenIds[user.totalStaked] = _tokenId;
        user.totalStaked ++;
        
        pool.totalStaked = pool.totalStaked.add(1*10**18);
        nft.owner = _user;
        nft.amount = 1*10**18;
        nft.rewardDebt = nft.amount.mul(pool.accTokenPerShare).div(ACC_TOKEN_PRECISION);
    }

    event Received();

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    )
        external
        override
        returns(bytes4)
    {
        _operator;
        _from;
        _tokenId;
        _data;
        emit Received();
        return 0x150b7a02;
    }

    receive() external payable {}

    function withdraw() external onlyOwner {
        payable(owner()).sendValue(address(this).balance);
    }

    function blockNum() external view returns (uint256) {
        return block.number;
    }

    function deposit() external payable{}
}
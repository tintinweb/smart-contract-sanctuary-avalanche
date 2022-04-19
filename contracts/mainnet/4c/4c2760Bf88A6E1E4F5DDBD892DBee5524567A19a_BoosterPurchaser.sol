/**
 *Submitted for verification at snowtrace.io on 2022-04-19
*/

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
}

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

interface INODERewardManagement {
    function nodePrice() external view returns (uint256);

    function rewardPerNode() external view returns (uint256);

    function _totalNodesCompounded(address _account)
        external
        view
        returns (uint256);

    function getUserCompoundedNodesCount(address _account)
        external
        view
        returns (string memory);

    function getRewardForCompounding(address _account, uint256 _nodeCount)
        external
        returns (uint256);

    function getNodeIndexByCreationTime(address _account, uint256 _blockTime)
        external
        returns (uint256);

    function updateProductionRate(
        address _user,
        uint256 _nodeIndex,
        uint256 _productionRatePer
    ) external;

    function updateNodeClaimTax(
        address _user,
        uint256 _nodeIndex,
        uint256 _taxPer
    ) external;

    function updateMonthlyFee(
        address _user,
        uint256 _nodeIndex,
        uint256 _taxPer
    ) external;

    function updateIsolationPeriod(
        address _user,
        uint256 _nodeIndex,
        uint256 _days
    ) external;

    function incrementCompoundNode(address _account) external;

    function claimTax() external view returns (uint256);

    function claimTime() external view returns (uint256);

    function totalRewardStaked() external view returns (uint256);

    function totalNodesCreated() external view returns (uint256);

    function setToken(address token_) external;

    function createNode(address account, string memory nodeName) external;

    function compoundAll(address account)
        external
        returns (uint256 totalCost, uint256 pendingCon);

    function _cashoutNodeReward(address account, uint256 _creationTime)
        external
        returns (uint256);

    function _cashoutAllNodesReward(address account) external returns (uint256);

    function compoundNodeReward(address account) external;

    function getDueFeeInfo(address account, uint256 _creationTime)
        external
        view
        returns (uint256 dueDate, uint256 lastPaidFee);

    function _getRewardAmountOf(address account)
        external
        view
        returns (uint256, uint256);

    function _getRewardAmountOf(address account, uint256 _creationTime)
        external
        view
        returns (uint256, uint256);

    function _getNodesNames(address account)
        external
        view
        returns (string memory);

    function _getNodesCreationTime(address account)
        external
        view
        returns (string memory);

    function _getNodesRewardAvailable(address account)
        external
        view
        returns (string memory);

    function _getNodesLastClaimTime(address account)
        external
        view
        returns (string memory);

    function payNodeMaintenanceFee(
        address account,
        uint256 _creationTime,
        uint256 _fee
    ) external payable;

    function getNodePayableFee(address account, uint256 _creationTime)
        external
        view
        returns (uint256);

    function _changeNodePrice(uint256 newNodePrice) external;

    function _changeRewardPerNode(uint256 newPrice) external;

    function _changeClaimTime(uint256 newTime) external;

    function _getNodeNumberOf(address account) external view returns (uint256);

    function _isNodeOwner(address account) external view returns (bool);
}

interface IERC721Extended is IERC721 {
    function create(
        address to,
        string memory _uri,
        uint256 _type,
        uint256 intValue,
        string memory strValue
    ) external returns (uint256);

    function getType(uint256 _tokenId) external view returns (uint256);

    function getIntValue(uint256 _tokenId) external view returns (uint256);

    function getStrValue(uint256 _tokenId)
        external
        view
        returns (string memory);

    function consume(uint256 tokenId) external;
}

contract BoosterPurchaser is Ownable {
    /// @notice Node Booster contract
    IERC721Extended public booster;

    IERC20 public con;
    address public treasury;
    address public rewardPool;

    /// @notice Nodes contract
    INODERewardManagement[3] public nodes;

    /// @notice A booster item for sale
    struct Item {
        uint256 price;
        uint256 supply;
        uint256 intValue;
        uint256 boosterType;
        string uri;
        string strValue;
    }

    /// @notice The mapping of item IDs to their data
    mapping(uint256 => Item) public items;

    /// @notice How many items are in items
    uint256 public totalItems;
    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => uint256) public nftPrices;
    mapping(uint256 => uint256) public boosterValues;

    constructor(
        address _nodeBooster,
        address _token,
        address _treasury,
        address _rewardPool
    ) {
        booster = IERC721Extended(_nodeBooster);
        treasury = _treasury;
        rewardPool = _rewardPool;

        con = IERC20(_token);
    }

    /**
     * @notice Adds an item to the store to be purchased
     */
    function addItem(
        uint256 price,
        uint256 supply,
        uint256 intValue,
        uint256 boosterType,
        string memory _uri,
        string memory strValue
    ) external onlyOwner {
        items[totalItems] = Item({
            price: price,
            supply: supply,
            intValue: intValue,
            boosterType: boosterType,
            uri: _uri,
            strValue: strValue
        });
        totalItems++;
    }

    function updateNode(
        uint256 blocktime,
        uint256 nodeIndex,
        uint256 nftId
    ) external {
        require(nodeIndex < 3, "NODE: Node out of range.");
        require(booster.ownerOf(nftId) == msg.sender, "Not a owner");
        INODERewardManagement nodeRewardManager = nodes[nodeIndex];
        uint256 boosterType = booster.getType(nftId);
        uint256 boosterValue = booster.getIntValue(nftId);
        uint256 conNodeIndex = nodeRewardManager.getNodeIndexByCreationTime(
            msg.sender,
            blocktime
        );

        if (boosterType == 0) {
            nodeRewardManager.updateProductionRate(
                msg.sender,
                conNodeIndex,
                boosterValue
            );
        } else if (boosterType == 1) {
            nodeRewardManager.updateNodeClaimTax(
                msg.sender,
                conNodeIndex,
                boosterValue
            );
        } else if (boosterType == 2) {
            nodeRewardManager.updateMonthlyFee(
                msg.sender,
                conNodeIndex,
                boosterValue
            );
        } else if (boosterType == 3) {
            nodeRewardManager.updateIsolationPeriod(
                msg.sender,
                conNodeIndex,
                boosterValue
            );
        }

        booster.consume(nftId);
    }

    /**
     * ===========================================================
     *            INTERFACE
     * ============================================================
     */

    /**
     * @notice Purchases a NODE using CON
     */
    function purchaseWithCon(address account, uint256 id) external {
        require(id <= totalItems, "This ID doesnt exist");
        require(items[id].supply > 0, "There are no items left");

        con.transferFrom(msg.sender, treasury, (items[id].price * 25) / 100);
        con.transferFrom(msg.sender, rewardPool, (items[id].price * 75) / 100);

        // Mint logic
        booster.create(
            account,
            items[id].uri,
            items[id].boosterType,
            items[id].intValue,
            items[id].strValue
        );

        items[id].supply -= 1;
    }

    /**
     * ===========================================================
     *            ADMIN FUNCTIONS
     * ===========================================================
     */

    function setNodeManagement(INODERewardManagement[3] memory nodeManagement)
        external
        onlyOwner
    {
        nodes = nodeManagement;
    }

    /**
     * @notice Sets the price
     */
    function setPrice(uint256 id, uint256 newPrice) external onlyOwner {
        items[id].price = newPrice;
    }

    /**
     * @notice Sets the supply
     */
    function setSupply(uint256 id, uint256 newSupply) external onlyOwner {
        items[id].supply = newSupply;
    }

    /**
     * @notice Sets the item
     */
    function setItem(
        uint256 id,
        uint256 _price,
        uint256 boosterType,
        uint256 intValue,
        string memory strValue,
        string memory _uri
    ) external onlyOwner {
        items[id].price = _price;
        items[id].boosterType = boosterType;
        items[id].intValue = intValue;
        items[id].strValue = strValue;
        items[id].uri = _uri;
    }

    function withdrawTokenFunds(address _token, address _account, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(_account, _amount);
    }

    function setConToken(address _token) external onlyOwner {
        con = IERC20(_token);
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    function setRewardPool(address _reward) external onlyOwner {
        rewardPool = _reward;
    }

    function withdrawAVAXFunds(address _user, uint256 _amount)
        external
        onlyOwner
    {
        require(_amount > 0, "Amount must be greater than 0");
        payable(_user).transfer(_amount);
    }
}
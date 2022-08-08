/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-07
*/

//SPDX-License-Identifier: MIT

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



// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


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
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
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
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}




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


// This is the main staking contract, its where you stake chefs to generate dough. It can be upgraded with ERC1155s 


pragma solidity ^0.8.0;



 interface IChef is IERC721 {
    function isTiki(uint256 tokenId) external view returns (bool);
}

interface IUpgrade is IERC1155 {
    function getRate(uint256 tokenId) external view returns (uint256);
}

interface IDough is IERC20 {
    function mint(address receiver, uint256 amount) external;
    function burn(uint256 amount) external;
    function burnFrom(address from, uint256 amount) external;
}


/** @dev FoodTruck is an NFT staking contract
 *       map each NFT to fungible staking impact
 *
 */
contract FoodTruck is Ownable, IERC721Receiver, IERC1155Receiver {
    mapping(uint256 => uint256) stakeTimes;
    mapping(uint256 => address) prevOwner;
    mapping(uint256 => bool) receivesRewards;
    IDough dough;
    IDough pza;
    IChef chefs;
    IUpgrade upgrades;
    address fermenter;
    
    // Fees
    uint256 baseWithdrawFee;
    uint256 earlyUnstakeFee;
    uint256 burnPercentage;
    uint256 fermenterPercentage;

    mapping(uint256 => mapping(address => uint256)) itemBalance;

    mapping(uint256 => uint256) public unlockTime;

    mapping(address => uint256[]) public chefIds;
    uint256 baseWalletLimit;
    mapping(address => uint256) public walletLimit;     //implicit: x + 20
    mapping(address => uint256) public collFeeReduce;   //implicit: 25% - x treasury, 40% - x total

    uint256[] public priceWalletUpgrade = [20 ether, 20 ether, 20 ether];
    uint256[] public walletUpgradeTier = [1, 5, 10];
    uint256 public priceCollectionUpgrade = 2 ether;
    uint256 cooldown = 1 days;

    constructor(
        address _chefs,
        address _upgrades,
        address _dough
    ) {
        chefs = IChef(_chefs);
        upgrades = IUpgrade(_upgrades);
        dough = IDough(_dough);
    }

    
    struct StakeInfo {
        uint256 lastUpdate;
        uint256 totalRate;
        uint256 claimable;
        uint256 slots;
        uint256 nrItems;
        uint256 nrChefs;
    }

    mapping(address => StakeInfo) public stakeMap;

    // --------------------------------------------------------PUBLIC - Owner--------------------------------------------------------
    function updateFeePercentage(uint burnCut, uint fermenterCut) external onlyOwner {
        if(burnCut > 0) {
            burnPercentage = burnCut;
        }
        if(fermenterCut > 0) {
            fermenterPercentage = fermenterCut;
        }
        require(fermenterPercentage + burnPercentage == 100, "!percent");
    }
    function updateFees(uint earlyUnstake, uint _withdraw) external onlyOwner {
        if(earlyUnstake > 0) {
            earlyUnstakeFee = earlyUnstake;
        }
        if(_withdraw > 0) {
            baseWithdrawFee = _withdraw;
        }
    }
    function updateOtherVars(uint limit, uint coolDown) external onlyOwner {
        if(coolDown > 0) {
        cooldown = coolDown;
        }
        if(limit > 0) {
            baseWalletLimit = limit;
        }
    }
    function updateCollUpPrices(uint256 collectionUpgrade) external onlyOwner {

        if(collectionUpgrade > 0) {
            priceCollectionUpgrade = collectionUpgrade;
        }
    }
    function updateWalletUpPrices(uint256[] memory walletUpgrade) external onlyOwner {
        require(walletUpgrade.length == 3, "!input");
        priceWalletUpgrade = walletUpgrade;
    }

    function setFermenter(address _fermenter) external onlyOwner {
        fermenter = _fermenter;
    } 

    function setPizza(address _pza) external onlyOwner {
        pza = IDough(_pza);
    }   
    // -------------------------------------PUBLIC - BASIC-------------------------------------------------
    
    function stake(uint256 tokenId) external {
        require(stakeMap[msg.sender].nrChefs < walletLimit[msg.sender] + 20, "!limit");
        chefs.safeTransferFrom(msg.sender, address(this), tokenId );
        _updateStake(msg.sender);
        StakeInfo storage refUser = stakeMap[msg.sender];
        refUser.nrChefs += 1;
        // Gas? Test it against an if block
        refUser.totalRate += chefs.isTiki(tokenId) ? 2 ether : 1 ether;
        refUser.slots += chefs.isTiki(tokenId)? 2 : 1;

        chefIds[msg.sender].push(tokenId);
        prevOwner[tokenId] = msg.sender;
        unlockTime[tokenId] = type(uint256).max;
    }


    // Done : Added unstake w no cooldown.  TODO Tiers ? Ask
    function prepareUnstake(uint256 tokenId, bool isCooldown) external {
        require(prevOwner[tokenId] == msg.sender, "Not your token");
        uint256 deltaslots = chefs.isTiki(tokenId) ? 2 : 1;
        _updateStake(msg.sender);
        StakeInfo storage refUser = stakeMap[msg.sender];
        require(
            refUser.slots - deltaslots >= refUser.nrItems,
            "Cannot unstake Chef with that many items equiped. Unequip items first."
        );
        refUser.nrChefs -= 1;
        refUser.slots -= deltaslots;
        refUser.totalRate -= deltaslots * 1 ether;
        if(isCooldown) {
        unlockTime[tokenId] = block.timestamp + cooldown;
        }
        else{
            chefs.safeTransferFrom(address(this), msg.sender, tokenId);
            // Implemented burnFrom for PZA and DOUGH
            pza.burnFrom(msg.sender, earlyUnstakeFee);
            // pza.transferFrom(msg.sender, address(this), earlyUnstakeFee);
            // pza.burn(earlyUnstakeFee);
            uint256 matchIndex = type(uint256).max;
            uint256 lenny = chefIds[msg.sender].length;
            for(uint256 index = 0; index < lenny; index++) {
                if (chefIds[msg.sender][index] == tokenId) {
                    matchIndex = index;
                }
            }
            require(matchIndex < lenny, "This should never happen, tell the dev");
            chefIds[msg.sender][matchIndex] = chefIds[msg.sender][lenny - 1];
            chefIds[msg.sender].pop();
            prevOwner[tokenId] = address(0);
            }
        }

    function unstake(uint256 tokenId) external {
        require(prevOwner[tokenId] == msg.sender, "!Owner");
        require(block.timestamp >= unlockTime[tokenId], "cooldown");
        chefs.safeTransferFrom(address(this), msg.sender, tokenId);
        uint256 matchIndex = type(uint256).max;
        uint256 lenny = chefIds[msg.sender].length;
        for(uint256 index = 0; index < lenny; index++) {
            if (chefIds[msg.sender][index] == tokenId) {
                matchIndex = index;
            }
        }
        require(matchIndex < lenny, "This should never happen, tell the dev");
        chefIds[msg.sender][matchIndex] = chefIds[msg.sender][lenny - 1];
        chefIds[msg.sender].pop();
        prevOwner[tokenId] = address(0);
    }
    function processFee(uint256 amount) internal returns(uint256 payout) {
        uint withdrawFee = baseWithdrawFee - collFeeReduce[msg.sender];
        uint cut = amount * withdrawFee / 100;
        uint fermenterFee = cut * fermenterPercentage / 100;
        dough.mint(fermenter, fermenterFee);
        payout = amount - cut;
    }
    function withdraw() public {
        _updateStake(msg.sender);
        uint256 reward = stakeMap[msg.sender].claimable;
        stakeMap[msg.sender].claimable = 0;
        // uint256 feefermenter = reward * baseFermenterFee / 100;
        // TODO ASK
        // uint256 feeburn = reward * (baseBurnFee - collFeeReduce[msg.sender]) / 100;
        // uint256 payout = reward - feefermenter - feeburn;
        uint256 payout = processFee(reward);
        // implicit burn
        // dough.mint(fermenter, feefermenter);
        dough.mint(msg.sender, payout);
    }

    // -------------------------------------PUBLIC - UPGRADES-------------------------------------------------
    //DONE : offer 1, 5, 10
    function increaseChefLimit(uint256 tier) external {
        // Unnecessary checks
        // uint256 approv = pza.allowance(msg.sender, address(this));
        // require( approv >= priceWalletUpgrade, "Insufficient Allowance");
        require(tier < 2, "!tier");
        pza.transferFrom(msg.sender, address(this), priceWalletUpgrade[tier]);
        walletLimit[msg.sender] += walletUpgradeTier[tier];
    }

    // todo tiers too? / Limit? 
    function reduceCollectionFee() external {
        // uint256 approv = pza.allowance(msg.sender, address(this));
        // require( approv >= priceCollectionUpgrade, "Insufficient Allowance");
        pza.transferFrom(msg.sender, address(this), priceCollectionUpgrade);
        collFeeReduce[msg.sender] += 5;
        require(collFeeReduce[msg.sender] < baseWithdrawFee, "underflow");
    }

    function equipItem(uint256 itemId) external {
        _updateStake(msg.sender);
        StakeInfo storage refUser = stakeMap[msg.sender];
        require(
            refUser.nrItems + 1 <= refUser.slots,
            "!slots"
        );
        refUser.nrItems += 1;
        refUser.totalRate += upgrades.getRate(itemId);
        itemBalance[itemId][msg.sender] += 1;
        upgrades.safeTransferFrom(msg.sender, address(this), itemId, 1, "");
    }

    function removeItem(uint256 itemId) external {
        require(itemBalance[itemId][msg.sender] > 0, "!Item");

        _updateStake(msg.sender);
        StakeInfo storage refUser = stakeMap[msg.sender];
        refUser.nrItems -= 1;
        refUser.totalRate -= upgrades.getRate(itemId);
        itemBalance[itemId][msg.sender] -= 1;
        
        upgrades.safeTransferFrom(address(this), msg.sender, itemId, 1, "");
    }
    // --------------------------------------INTERNAL---------------------------------------
    function _updateStake(address user) private {
        StakeInfo storage refUser = stakeMap[user];
        uint256 lastTime = refUser.lastUpdate;
        uint256 totalReward = refUser.totalRate * (block.timestamp - lastTime) / 1 minutes;
        refUser.claimable += totalReward;
        refUser.lastUpdate = block.timestamp;
    }



    // ------------------------------------VIEW-----------------------------------------
    struct ChefInfo {
        uint256 tokenId;
        uint256 unlockTime;
    }
    // DONE address param instead of msg.sender in view functions
    function getChefs(address user) external view returns (ChefInfo[] memory) {
        ChefInfo[] memory result = new ChefInfo[](chefIds[user].length);
        for(uint256 index = 0; index < chefIds[user].length; index++) {
            uint256 tokid = chefIds[user][index];
            result[index] = ChefInfo({tokenId: tokid, unlockTime: unlockTime[tokid]});
        }
        return result;
    }


    function getCollectionFee(address user) public view returns (uint256) {
        return baseWithdrawFee - collFeeReduce[user];
    }

    function getWalletLimit(address user) public view returns (uint256) {
        return walletLimit[user] + 20;
    }

    function getReward(address user) public view returns (uint256) {
        uint256 lastTime = stakeMap[user].lastUpdate;
        uint256 totalReward = stakeMap[user].totalRate * (block.timestamp - lastTime) / 1 minutes;
        return stakeMap[user].claimable + totalReward;
    }

    function getSlots(address user) public view returns (uint256) {
        return stakeMap[user].slots;
    }

    function getUserRate(address user) public view returns (uint256) {
        return stakeMap[user].totalRate;
    }

    function getNrItems(address user) public view returns (uint256) {
        return stakeMap[user].nrItems;
    }

    function getItemBalance(uint256 itemId, address user) public view returns (uint256) {
        return itemBalance[itemId][user];
    }


    // ------------------------------------------------- SPECS REQUIREMENTS -------------------------------------------------------------------------

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
// A bit hacky
    function supportsInterface(bytes4 interfaceID)
        external
        pure
        override
        returns (bool)
    {
        return true;
    }
}
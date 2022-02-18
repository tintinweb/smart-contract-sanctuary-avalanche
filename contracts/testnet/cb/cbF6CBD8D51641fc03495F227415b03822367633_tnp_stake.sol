/**
 *Submitted for verification at testnet.snowtrace.io on 2022-02-18
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: tnp.sol


pragma solidity ^0.8.2;





//token contract : 0xb688a74F6E8d5A09F57Eb973362117836743f277
//nft contract : 0x6a664c88f9535addEa502d1676f42269ba841751

contract tnp_stake is Ownable, IERC721Receiver {
    IERC20 public token;
    IERC721 public nft;

    uint256 public totalNftStaked;
    uint256 public totaltype1;
    uint256 public totaltype2;
    uint256 public usercount;
    uint256 public dailyReward = 2500 * 1e15;
    uint256 public timerUnit = 10;

    struct UserInfo {
        uint256 amountStaked;
        uint256 total_rewards;
        uint256 type1;
        uint256 type2;
        uint256 type1_rewards;
        uint256 type2_rewards;
    }

    struct NFTPoolInfo {
        uint256 internal_id;
        uint256 id;
        uint256 nft_type;
        address owner;
        uint256 timeStaked;
        uint256 daysElapsed;
        bool isActive;
        uint256 rewards;
        uint256 total_claim;
    }

    NFTPoolInfo[] public nftPoolInfo;
    mapping(address => UserInfo) public userInfo;
    mapping(address => bool) public staker;
    address[] public stakers;

    event NFTAdded(
        address indexed owner,
        uint256 internalId,
        uint256 id,
        uint256 nftType,
        uint256 stake_time
    );
    event Staked(
        address indexed user,
        uint256 internalId,
        uint256 id,
        uint256 nftType,
        uint256 stake_time
    );
    event Claim(
        address indexed user,
        uint256 nftId,
        uint256 nftType,
        uint256 payout
    );
    event Withdrawn(
        address indexed user,
        uint256 internalId,
        uint256 id,
        uint256 nftType,
        uint256 unstakeTime
    );

    constructor(IERC20 _token, IERC721 _nft) {
        token = _token;
        nft = _nft;
    }

    function addNFT(uint256 id, uint256 verifier) private {
        uint256 nft_Type = verifier;
        nft.safeTransferFrom(msg.sender, address(this), id, "");
        totalNftStaked += 1;
        nftPoolInfo.push(
            NFTPoolInfo({
                internal_id: totalNftStaked,
                id: id,
                nft_type: verifier,
                owner: msg.sender,
                timeStaked: block.timestamp,
                daysElapsed: 0,
                isActive: true,
                rewards: 0,
                total_claim: 0
            })
        );

        if (verifier == 1) {
            totaltype1 += 1;
        } else if (verifier == 2) {
            totaltype2 += 1;
        }

        staker[msg.sender] = true;
        stakers.push(msg.sender);
        emit NFTAdded(
            msg.sender,
            totalNftStaked,
            id,
            nft_Type,
            block.timestamp
        );
    }

    function stake(uint256 id, uint256 verifier) external {
        addNFT(id, verifier);
        updateAllPools();
        emit Staked(msg.sender, totalNftStaked, id, verifier, block.timestamp);
    }

    function updateAllPools() public {
        uint256 length = nftPoolInfo.length;
        for (uint256 i = 0; i < length; i++) {
            updatePool(i);
        }
    }

    function updatePool(uint256 id) public {
        NFTPoolInfo storage pool = nftPoolInfo[id];
        if (pool.isActive == true) {
            uint256 timeElapsed = block.timestamp - pool.timeStaked;
            uint256 daysElapsed = timeElapsed / timerUnit;

            if (pool.nft_type == 1) {
                pool.daysElapsed = daysElapsed;
                uint256 rewards = (daysElapsed * dailyReward) - pool.total_claim;
                pool.rewards = rewards;
            } else if (pool.nft_type == 2) {
                pool.daysElapsed = daysElapsed;
                uint256 rewards = ((((totaltype1 * dailyReward * 20) / 100) /
                    totaltype2) * daysElapsed) - pool.total_claim;
                pool.rewards = rewards;
            }
        }
        nftPoolInfo[id] = pool;
    }

    function updateAllUsers() public {
        uint256 length = stakers.length;
        for (uint256 i = 0; i < length; i++) {
            address ownerAddress = stakers[i];
            bool ifStaker = staker[ownerAddress];
            if (ifStaker == true) {
                updateUserInfo(ownerAddress);
            }
        }
    }

    function updateUserInfo(address _staker) public {
        UserInfo storage user = userInfo[_staker];
        uint256 length = nftPoolInfo.length;
        uint256 totalUserRewards;
        uint256 totalUserItems;
        uint256 type1;
        uint256 type2;
        uint256 t1Rewards;
        uint256 t2Rewards;
        for (uint256 i = 0; i < length; i++) {
            NFTPoolInfo storage pool = nftPoolInfo[i];
            if (pool.isActive == true) {
                address Owner_address = pool.owner;
                if (Owner_address == _staker) {
                    totalUserRewards += pool.rewards;
                    totalUserItems += 1;
                }
                uint256 nft_type = pool.nft_type;
                if (nft_type == 1) {
                    type1 += 1;
                    t1Rewards += pool.rewards;
                } else if (nft_type == 2) {
                    type2 += 1;
                    t2Rewards += pool.rewards;
                }
            }
        }
        user.amountStaked = totalUserItems;
        user.total_rewards = totalUserRewards;
        user.type1 = type1;
        user.type2 = type2;
        user.type1_rewards = t1Rewards;
        user.type2_rewards = t2Rewards;
        userInfo[_staker] = user;
    }

    function claim(uint256 id) public {
        updatePool(id);
        NFTPoolInfo memory pool = nftPoolInfo[id];
        uint256 nft_type = pool.nft_type;
        uint256 rewardsPending = pool.rewards;
        uint256 tokenToTransfer;
        if (nft_type == 1) {
            uint256 totalDeduction = calculateNarcoDeduction();
            tokenToTransfer = rewardsPending - ((rewardsPending * totalDeduction) / 100);  
            if (tokenToTransfer == 0) {
                tokenToTransfer = 1e12;
            }
            
        } else {
            tokenToTransfer = rewardsPending;
            
        }
        
        pool.total_claim += rewardsPending;
        pool.rewards = 0;
        emit Claim(msg.sender, id, nft_type, tokenToTransfer);
        nftPoolInfo[id] = pool;
        token.transfer(msg.sender, tokenToTransfer);
    }

    function withdraw(uint256 id) public {
        updatePool(id);
        NFTPoolInfo memory pool = nftPoolInfo[id];
        uint256 timeStaked = pool.daysElapsed;
        require(msg.sender == pool.owner, "Can Only Unstake Own NFTs");
        require(timeStaked > 2, "Cannot Unstake Before 2 days Elapsed");
        uint256 nft_type = pool.nft_type;
        uint256 rewardsPending = pool.rewards;
        uint256 tokenToTransfer;
        if (nft_type == 1) {
            uint256 totalDeduction = calculateNarcoDeduction();
            tokenToTransfer = rewardsPending - ((rewardsPending * totalDeduction) / 100);  
            if (tokenToTransfer == 0) {
                tokenToTransfer = 1e12;
            }
            
        } else {
            tokenToTransfer = rewardsPending;
        }
        
        pool.total_claim += rewardsPending;
        pool.rewards = 0;
        pool.isActive = false;
        
        emit Withdrawn(msg.sender, id, pool.id, nft_type, block.timestamp);
        nftPoolInfo[id] = pool;
        nft.safeTransferFrom(address(this), pool.owner, pool.id);
        token.transfer(msg.sender, tokenToTransfer);
        
        
    }

    function calculateNarcoDeduction() private view returns (uint256) {
        uint256 genNum = uint256(blockhash(block.number - 1));
        uint256 Randomizer = (genNum % 2) + 1;
        uint256 totalDeduction;
        if (Randomizer == 1) {
            totalDeduction = 20;
        } else {
            totalDeduction = 100;
        }
        return totalDeduction;
    }

    function updateDailyReward(uint256 _newReward) external onlyOwner {
        dailyReward = _newReward;
        updateAllPools();
    }

    function withdrawToken() external onlyOwner {
        updateAllPools();
        uint256 tokenAmount = token.balanceOf(address(this));
        token.transfer(msg.sender, tokenAmount);
    }

    function apotheosis() external onlyOwner {
        token.transfer(msg.sender, token.balanceOf(address(this)));
        uint256 length = nftPoolInfo.length;
        for (uint256 i = 0; i < length; i++) {
            NFTPoolInfo storage pool = nftPoolInfo[i];
            if (pool.isActive == true) {
                address ownerAddress = pool.owner;
                uint256 id = pool.id;
                nft.safeTransferFrom(address(this), ownerAddress, id);
            }
        }
        selfdestruct(payable(msg.sender));
    }

    function tokenBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function ethBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function trustedWithdraw() external onlyOwner {
        updateAllPools();
        payable(msg.sender).transfer(address(this).balance);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
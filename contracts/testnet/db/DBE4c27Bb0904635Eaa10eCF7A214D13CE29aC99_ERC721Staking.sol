/**
 *Submitted for verification at testnet.snowtrace.io on 2023-04-29
*/

/**
 *Submitted for verification at testnet.snowtrace.io on 2023-04-14
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// File: contracts/ERC721Staking.sol


pragma solidity ^0.8.0;






contract ERC721Staking is IERC721Receiver, Ownable, ReentrancyGuard {

    uint256 constant THIRTY_DAYS = 3600 * 24 * 30;
    uint256 public maxLockMonths = 3;
    uint256 public commonEmissionRate;
    uint256 public rareEmissionRate;
    uint256 public rareStartId = 5;

    bool public useRareMapping = false;
    bool public paused = false;

    // Mappings for staked tokens
    mapping (address => uint256[]) public stakerToStakedTokens;
    mapping (address => mapping(uint256 => uint256)) public stakerToStakedTokenToIndex;
    mapping (address => uint256) public stakerToTimestamp;

    // Mappings for locked tokens
    mapping (address => uint256[]) public stakerToLockedTokens;
    mapping (address => mapping(uint256 => uint256)) public stakerToLockedTokenToIndex;
    mapping (uint256 => uint256) public lockedTokenToUnlockedTimestamp;

    // Misc. Mappings
    mapping (uint256 => address) public depositorAddress;
    mapping (address => bool) public isAuthorizedUser;
    mapping (uint256 => bool) public isRareToken;

    address[] public stakersArray;
    address[] public lockersArray;

    IERC721 nft;
    IERC20 rewardToken;

    event TokensStaked(address indexed staker, uint256[] tokens);
    event TokensWithdrawn(address indexed staker, uint256[] tokens);
    event TokensLocked(address indexed locker, uint256[] tokens, uint256 reward);
    event TokensUnlocked(address indexed locker, uint256[] tokens);
    event RewardsClaimed(address indexed claimer, uint256 amount);

    constructor(
        address _nft, // NFT Contract
        address _rewardToken, // Reward Token
        uint256 _commonEmissionRate, // ~ 0.01366666666667 per hour
        uint256 _rareEmissionRate, // ~ 0.091666666667 per hour
        uint256 _rareStartId,
        bool _useRareMapping // useRareMapping
    ) {
        nft = IERC721(_nft);
        rewardToken = IERC20(_rewardToken);
        commonEmissionRate = _commonEmissionRate;
        rareEmissionRate = _rareEmissionRate;
        useRareMapping = _useRareMapping;
        rareStartId = _rareStartId;
    }

    modifier onlyAuthorized() {
        require(isAuthorizedUser[msg.sender] || msg.sender == owner(), "STAKING: You aren't authorized!");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "STAKING: Contract Paused!");
        _;
    }

    // Public Functions
    function stakeNFTs(uint256[] calldata _tokenIds) external nonReentrant whenNotPaused {
        _stake(_tokenIds);
    }

    function unstakeNFTs(uint256[] calldata _tokenIds) external nonReentrant whenNotPaused {
        _withdrawFromStake(msg.sender, _tokenIds);
    }

    function lockNFTs(uint256[] calldata _tokenIds, uint256 _time) external nonReentrant whenNotPaused {
        _lock(_tokenIds, _time);
    }

    function unlockNFTs(uint256[] calldata _tokenIds) external nonReentrant whenNotPaused {
        _withdrawFromLock(msg.sender, _tokenIds);
    }

    function claim() external nonReentrant whenNotPaused {
        _claimRewards(msg.sender);
    }
    
    // View Functions
    function getNFTAddress() public view returns (address) {
    return address(nft);
    }
    function isRare(uint256 _tokenId) public view returns (bool) {
        return useRareMapping ? isRareToken[_tokenId] : _tokenId >= rareStartId;
    }

    function getRewardTokenBalance() public view returns (uint256) {
        return rewardToken.balanceOf(address(this));
    }

    function getRewardsFor(address _staker) external view returns (uint256) {
        return _calculateRewards(_staker);
    }

    function getStakedTokensFor(address _staker) external view returns (uint256[] memory) {
        return stakerToStakedTokens[_staker];
    }

    function getLockedTokensFor(address _locker) external view returns (uint256[] memory) {
        return stakerToLockedTokens[_locker];
    }

    function timeLeftForToken(uint256 _tokenId) external view returns (uint256) {
        uint256 _ts = lockedTokenToUnlockedTimestamp[_tokenId];
        return _ts > block.timestamp ? _ts - block.timestamp : 0;
    }

    // Internal Functions
    function _removeFromStaker(address _staker, uint256 _tokenId) internal {
        uint256 _originalIndex = stakerToStakedTokenToIndex[_staker][_tokenId];
        uint256 _lastToken = stakerToStakedTokens[_staker][stakerToStakedTokens[_staker].length -1];
        stakerToStakedTokens[_staker][_originalIndex] = _lastToken;
        stakerToStakedTokenToIndex[_staker][_lastToken] = _originalIndex;
        stakerToStakedTokens[_staker].pop();
    }

    function _removeFromLocker(address _staker, uint256 _tokenId) internal {
        uint256 _originalIndex = stakerToLockedTokenToIndex[_staker][_tokenId];
        uint256 _lastToken = stakerToLockedTokens[_staker][stakerToLockedTokens[_staker].length -1];
        stakerToLockedTokens[_staker][_originalIndex] = _lastToken;
        stakerToLockedTokenToIndex[_staker][_lastToken] = _originalIndex;
        stakerToLockedTokens[_staker].pop();
    }

    function _stake(uint256[] calldata _tokenIds) internal {
        uint256 len = _tokenIds.length;
        require(len != 0, "STAKING: Staking 0 tokens!");
        require(getRewardTokenBalance() > 0, "STAKING: No rewards in vault!");

        uint256 _currentAmountStaked = stakerToStakedTokens[msg.sender].length;

        for (uint256 i = 0; i < len; i++) {
            stakerToStakedTokenToIndex[msg.sender][_tokenIds[i]] = _currentAmountStaked;
            stakerToStakedTokens[msg.sender].push(_tokenIds[i]);
        }

        if (_currentAmountStaked > 0) {
            _claimRewards(msg.sender);
        } else {
            stakersArray.push(msg.sender);
            stakerToTimestamp[msg.sender] = block.timestamp;
        }

        for (uint256 i = 0; i < len; ++i) {
            require(
                nft.ownerOf(_tokenIds[i]) == msg.sender &&
                    (nft.getApproved(_tokenIds[i]) == address(this) ||
                        nft.isApprovedForAll(msg.sender, address(this))),
                "STAKING: Not owned or approved!"
            );

            nft.safeTransferFrom(msg.sender, address(this), _tokenIds[i]);
            depositorAddress[_tokenIds[i]] = msg.sender;
        }

        emit TokensStaked(msg.sender, _tokenIds);
    }

    function _withdrawFromStake(address _staker, uint256[] memory _tokenIds) internal {
        uint256 _amountStaked = stakerToStakedTokens[_staker].length;
        uint256 len = _tokenIds.length;
        require(len != 0, "STAKING: Withdrawing 0 tokens");
        require(_amountStaked >= len, "STAKING: Withdrawing more than staked");

        _claimRewards(_staker);

        if (_amountStaked == len) {
            address[] memory _stakersArray = stakersArray;
            for (uint256 i = 0; i < _stakersArray.length; ++i) {
                if (_stakersArray[i] == _staker) {
                    stakersArray[i] = _stakersArray[_stakersArray.length - 1];
                    stakersArray.pop();
                    break;
                }
            }
            delete stakerToStakedTokens[_staker];
        } else {
            for (uint256 i = 0; i < len; i++) {
                _removeFromStaker(_staker, _tokenIds[i]);
            }
        }

        for (uint256 i = 0; i < len; ++i) {
            require(depositorAddress[_tokenIds[i]] == _staker, "STAKING: Not staker!");
            depositorAddress[_tokenIds[i]] = address(0);
            nft.safeTransferFrom(address(this), _staker, _tokenIds[i]);
        }

        emit TokensWithdrawn(_staker, _tokenIds);
    }

    function _lock(uint256[] calldata _tokenIds, uint256 _time) internal {
        uint256 len = _tokenIds.length;
        require(len != 0, "STAKING: Locking 0 tokens!");
        require(_time % THIRTY_DAYS == 0 &&
                _time / THIRTY_DAYS >= 1 &&
                _time / THIRTY_DAYS <= maxLockMonths, "STAKING: Invalid time!");

        uint256 _unlockTime = block.timestamp + _time; 

        uint256 _currentAmountLocked = stakerToLockedTokens[msg.sender].length;

        for (uint256 i = 0; i < len; i++) {
            stakerToLockedTokenToIndex[msg.sender][_tokenIds[i]] = _currentAmountLocked;
            stakerToLockedTokens[msg.sender].push(_tokenIds[i]);
        }

        if (_currentAmountLocked == 0) {
            lockersArray.push(msg.sender);
        }

        for (uint256 i = 0; i < len; ++i) {
            require(
                nft.ownerOf(_tokenIds[i]) == msg.sender &&
                    (nft.getApproved(_tokenIds[i]) == address(this) ||
                        nft.isApprovedForAll(msg.sender, address(this))),
                "STAKING: Not owned or approved!"
            );

            nft.safeTransferFrom(msg.sender, address(this), _tokenIds[i]);
            depositorAddress[_tokenIds[i]] = msg.sender;
            lockedTokenToUnlockedTimestamp[_tokenIds[i]] = _unlockTime;
        }

        uint256 _reward = _calculateLockRewards(_tokenIds, _time);
        require(getRewardTokenBalance() >= _reward, "STAKING: Not enough rewards in vault!");
        rewardToken.transfer(msg.sender, _reward);

        emit TokensLocked(msg.sender, _tokenIds, _reward);
    }

    function _withdrawFromLock(address _staker, uint256[] memory _tokenIds) internal {
        uint256 _amountLocked = stakerToLockedTokens[_staker].length;
        uint256 len = _tokenIds.length;
        require(len != 0, "STAKING: Withdrawing 0 tokens");
        require(_amountLocked >= len, "STAKING: Withdrawing more than staked");

        for (uint256 i = 0; i < len; i++) {
            require(lockedTokenToUnlockedTimestamp[_tokenIds[i]] <= block.timestamp, "STAKING: Token lock not finished!");
            _removeFromLocker(_staker, _tokenIds[i]);
        }

        if (_amountLocked == len) {
            address[] memory _stakersArray = stakersArray;
            for (uint256 i = 0; i < _stakersArray.length; ++i) {
                if (_stakersArray[i] == _staker) {
                    stakersArray[i] = _stakersArray[_stakersArray.length - 1];
                    stakersArray.pop();
                    break;
                }
            }
        } 

        for (uint256 i = 0; i < len; ++i) {
            require(depositorAddress[_tokenIds[i]] == _staker, "STAKING: Not locker!");
            depositorAddress[_tokenIds[i]] = address(0);
            nft.safeTransferFrom(address(this), _staker, _tokenIds[i]);
        }

        emit TokensUnlocked(_staker, _tokenIds);
    }

    function _calculateRewards(address _staker) internal view returns (uint256) {
        uint256[] memory _tokenIds = stakerToStakedTokens[_staker];
        uint256 len = _tokenIds.length;
        uint256 timeStaked = block.timestamp - stakerToTimestamp[_staker];
        uint256 totalReward = 0;

        for (uint256 i = 0; i < len; i++) {
            if (isRare(_tokenIds[i])) {
                    totalReward += timeStaked * rareEmissionRate;
            } else {
                totalReward += timeStaked * commonEmissionRate;
            }
        }

        uint256 _vaultBalance = getRewardTokenBalance();
        return totalReward >= _vaultBalance ? _vaultBalance : totalReward;
    }

    function _calculateLockRewards(uint256[] calldata _tokenIds, uint256 _time) internal view returns (uint256) {
        uint256 len = _tokenIds.length;
        uint256 totalReward = 0;

        for (uint256 i = 0; i < len; i++) {
            if (isRare(_tokenIds[i])) {
                    totalReward += _time * rareEmissionRate;
            } else {
                totalReward += _time * commonEmissionRate;
            }
        }

        return totalReward;
    }

    function _claimRewards(address _staker) internal {
        uint256 _reward = _calculateRewards(_staker);
        stakerToTimestamp[msg.sender] = block.timestamp;
        rewardToken.transfer(_staker, _reward);

        emit RewardsClaimed(_staker, _reward);
    }

    // Admin Functions
    function flipPaused() external onlyAuthorized {
        paused = !paused;
    }
    
    function setCommonEmissionRate(uint256 _newRate) external onlyAuthorized {
        commonEmissionRate = _newRate;
    }

    function setRareEmissionRate(uint256 _newRate) external onlyAuthorized {
        rareEmissionRate = _newRate;
    }

    function setRareStartId(uint256 _newId) external onlyAuthorized {
        rareStartId = _newId;
    }

    function setUseRareMapping(bool _newState) external onlyAuthorized {
        useRareMapping = _newState;
    }

    function setMaxLockMonths(uint256 _newMax) external onlyAuthorized {
        maxLockMonths = _newMax;
    }

    function setRareTokens(uint256[] calldata _tokenIds) external onlyAuthorized {
        uint256 len = _tokenIds.length;
        for (uint256 i = 0; i < len; i++) {
            isRareToken[_tokenIds[i]] = true;
        }
    }

    function removeRareTokens(uint256[] calldata _tokenIds) external onlyAuthorized {
        uint256 len = _tokenIds.length;
        for (uint256 i = 0; i < len; i++) {
            isRareToken[_tokenIds[i]] = false;
        }
    }

    function manualUnstakeAllFor(address[] calldata _users) external onlyAuthorized {
        uint256 len = _users.length;
        for (uint256 i = 0; i < len; i++) {
            uint256[] memory _tokenIds = stakerToStakedTokens[_users[i]];
            _withdrawFromStake(_users[i], _tokenIds);
        }
    }

    function manualUnlockAllFor(address[] calldata _users) external onlyAuthorized {
        uint256 len = _users.length;
        for (uint256 i = 0; i < len; i++) {
            uint256[] memory _tokenIds = stakerToLockedTokens[_users[i]];
            _withdrawFromLock(_users[i], _tokenIds);
        }
    }

    // Owner Functions
    function setAuthorized(address _user, bool _authorized) external onlyOwner {
        isAuthorizedUser[_user] = _authorized;
    }

    function withdrawSomeRewardToken(uint256 _amount) public onlyOwner {
        rewardToken.transfer(msg.sender, _amount);
    }

    function withdrawAllRewardToken() public onlyOwner {
        uint256 balance = rewardToken.balanceOf(address(this));

        rewardToken.transfer(msg.sender, balance);
    }

    function withdrawERC20(address _tokenAddress) public onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        uint256 balance = token.balanceOf(address(this));

        token.transfer(msg.sender, balance);
    }

    function emergencyWithdrawNFTs(uint256[] calldata _tokenIds) public onlyOwner {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            nft.safeTransferFrom(address(this), msg.sender, _tokenIds[i], "");
        }
    }

    // ERC721Receiver
    function onERC721Received(address, address, uint256, bytes calldata) external view override returns (bytes4) {
        require(msg.sender == address(nft), "STAKING: Incorrect NFT!");
        return IERC721Receiver.onERC721Received.selector;
    }

}
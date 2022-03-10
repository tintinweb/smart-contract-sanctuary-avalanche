/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-09
*/

// SPDX-License-Identifier: MIT

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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
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
}

// File: INexusERC721.sol


pragma solidity ^0.8.9;


interface INexusERC721 is IERC721Enumerable {
    function getTokenEmissionRate(uint256 tokenId)
        external
        view
        returns (uint256);

    function getTierPrice(uint256 tier) external view returns (uint256);

    function mint(
        address to,
        uint256 tier,
        string calldata name
    ) external;
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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;


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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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

// File: INexusERC20.sol


pragma solidity ^0.8.9;


interface INexusERC20 is IERC20 {
    function isInBlacklist(address account) external view returns (bool);

    function burn(address from, uint256 amount) external;
}

// File: NexusPresale.sol


pragma solidity ^0.8.9;






/// @custom:security-contact [email protected]
contract NexusPresale is Ownable, Pausable {
    uint256 public constant PRIVATE_SALE_PRICE = 1;
    uint256 public constant PUBLIC_SALE_PRICE = 2;

    uint256 public constant DECIMALS = 10**18;
    uint256 public constant MAX_SOLD = 100_000 * DECIMALS;
    uint256 public constant MAX_BUY_PER_ADDRESS = 500 * DECIMALS;

    bool public isAnnounced;
    uint256 public startTime;
    uint256 public endTime;

    bool public isPublicSale;
    bool public isClaimable;

    uint256 public canClaimOnceIn = 1 days;
    uint256 public claimablePerDay = 50 * DECIMALS;
    uint256 public totalSold;
    uint256 public totalOwed;

    mapping(address => uint256) public invested;
    mapping(address => uint256) public lastClaimedAt;
    mapping(address => bool) public isWhitelisted;

    address public constant MIM = 0x130966628846BFd36ff31a822705796e8cb8C18D;
    address public treasury;

    INexusERC20 public NXS;
    INexusERC721 public NEXUS;

    //
    // Modifiers
    //

    modifier whenNotBlacklisted() {
        require(
            !NXS.isInBlacklist(_msgSender()),
            "NexusPresale: blacklisted address"
        );
        _;
    }

    modifier onlyEOA() {
        require(_msgSender() == tx.origin, "NexusPresale: not an EOA");
        _;
    }

    //
    // Events
    //

    event WhitelistUpdated(address account, bool value);
    event TokensBought(address account, uint256 amount, uint256 withMIM);
    event TokensClaimed(address account, uint256 amount);
    event NFTMinted(address by, uint256 tier, uint256 balance);

    //
    // Constructor
    //

    constructor(
        address _NXS,
        address _NEXUS,
        address _treasury
    ) {
        NXS = INexusERC20(_NXS);
        NEXUS = INexusERC721(_NEXUS);
        treasury = _treasury;
    }

    //
    // Setters
    //

    function announceICO(uint256 _startTime, uint256 _endTime)
        external
        onlyOwner
    {
        isAnnounced = true;
        startTime = _startTime;
        endTime = _endTime;
    }

    function startPublicSale() external onlyOwner {
        isPublicSale = true;
    }

    function enableClaiming() external onlyOwner {
        require(
            isAnnounced && block.timestamp > endTime,
            "NexusPresale: presale not ended yet"
        );

        isClaimable = true;
    }

    function setCanClaimOnceIn(uint256 _hours) external onlyOwner {
        canClaimOnceIn = _hours * 3600;
    }

    function setClaimablePerDay(uint256 amount) external onlyOwner {
        claimablePerDay = amount * DECIMALS;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    //
    // Whitelist functions
    //

    function addToWhitelist(address[] calldata accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            isWhitelisted[accounts[i]] = true;
            emit WhitelistUpdated(accounts[i], true);
        }
    }

    function removeFromWhitelist(address[] calldata accounts)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < accounts.length; i++) {
            isWhitelisted[accounts[i]] = false;
            emit WhitelistUpdated(accounts[i], false);
        }
    }

    function updateWhitelist(address account, bool value) external onlyOwner {
        isWhitelisted[account] = value;
        emit WhitelistUpdated(account, value);
    }

    //
    // Buy/Claim/Mint functions
    //

    function buyTokens(uint256 amount)
        external
        whenNotBlacklisted
        whenNotPaused
        onlyEOA
    {
        require(isAnnounced, "NexusPresale: not announced yet");

        require(
            block.timestamp > startTime,
            "NexusPresale: sale not started yet"
        );

        require(block.timestamp < endTime, "NexusPresale: sale ended");

        if (!isPublicSale) {
            require(
                isWhitelisted[_msgSender()],
                "NexusPresale: not a whitelisted address"
            );
        }

        require(totalSold < MAX_SOLD, "NexusPresale: sold out");
        require(amount > 0, "NexusPresale: zero buy amount");

        require(
            invested[_msgSender()] + amount <= MAX_BUY_PER_ADDRESS,
            "NexusPresale: wallet limit reached"
        );

        uint256 price = isPublicSale ? PUBLIC_SALE_PRICE : PRIVATE_SALE_PRICE;
        uint256 remaining = MAX_SOLD - totalSold;

        if (amount > remaining) {
            amount = remaining;
        }

        uint256 amountInMIM = amount * price;

        IERC20(MIM).transferFrom(_msgSender(), treasury, amountInMIM);

        invested[_msgSender()] += amount;
        totalSold += amount;
        totalOwed += amount;

        emit TokensBought(_msgSender(), amount, amountInMIM);
    }

    function claimTokens() external onlyEOA whenNotBlacklisted whenNotPaused {
        require(isClaimable, "NexusPresale: claiming not active");

        require(
            invested[_msgSender()] > 0,
            "NexusPresale: insufficient claimable balance"
        );

        require(
            block.timestamp > lastClaimedAt[_msgSender()] + canClaimOnceIn,
            "NexusPresale: already claimed once during permitted time"
        );

        lastClaimedAt[_msgSender()] = block.timestamp;

        uint256 claimableAmount = invested[_msgSender()];

        if (claimableAmount > claimablePerDay) {
            claimableAmount = claimablePerDay;
        }

        totalOwed -= claimableAmount;
        invested[_msgSender()] -= claimableAmount;

        NXS.transfer(_msgSender(), claimableAmount);

        emit TokensClaimed(_msgSender(), claimableAmount);
    }

    function mintFromInvested(uint256 tier, string calldata name)
        external
        onlyEOA
        whenNotBlacklisted
        whenNotPaused
    {
        require(isClaimable, "NexusPresale: presale not ended yet");

        uint256 price = NEXUS.getTierPrice(tier);

        require(
            invested[_msgSender()] >= price,
            "NexusPresale: insufficient presale balance"
        );

        totalOwed -= price;
        invested[_msgSender()] -= price;

        NEXUS.mint(_msgSender(), tier, name);
        emit NFTMinted(_msgSender(), tier, invested[_msgSender()]);
    }

    function withdrawTokens() external onlyOwner {
        require(totalOwed == 0, "NexusPresale: claim pending");
        NXS.transfer(_msgSender(), NXS.balanceOf(address(this)));
    }
}
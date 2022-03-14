// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/INexusERC20.sol";
import "./interfaces/INexusERC721.sol";

/// @custom:security-contact [email protected]
contract NexusVault is ERC721Holder, Ownable {
    mapping(uint256 => uint256) public tokenIdToTimestamp;
    mapping(uint256 => address) public tokenIdToStaker;
    mapping(address => uint256[]) public stakerToTokenIds;
    mapping(address => uint256) public lastClaimedAt;

    bool public isWalletLimited = true;
    uint256 public maxPerWallet = 100;

    bool public useClaimTax;
    bool public useClaimBonus = true;
    bool public isCompoundingEnabled = true;

    uint256 public taxPeriodOne = 604800;
    uint256 public taxPeriodTwo = 1209600;
    uint256 public taxPeriodThree = 1814400;

    uint256 public taxPercentOne = 30;
    uint256 public taxPercentTwo = 15;
    uint256 public taxPercentThree = 0;
    uint256 public bonusPercent = 15;

    INexusERC20 public NXS;
    INexusERC721 public NEXUS;

    //
    // Modifiers
    //

    modifier whenNotBlacklisted() {
        require(
            !NXS.isInBlacklist(_msgSender()),
            "NexusVault: blacklisted address"
        );
        _;
    }

    //
    // Events
    //

    event TokenStaked(uint256 tokenId);
    event TokenUnstaked(uint256 tokenId);
    event RewardsClaimed(uint256 amount, address by);
    event Compounded(uint256 tokenId, uint256 tier, address by);

    event NXSAddressUpdated(address from, address to);
    event NEXUSAddressUpdated(address from, address to);

    //
    // Constructor
    //

    constructor(address _NXS, address _NEXUS) {
        NXS = INexusERC20(_NXS);
        NEXUS = INexusERC721(_NEXUS);
    }

    //
    // Getters
    //

    function getTokensStaked(address staker)
        external
        view
        returns (uint256[] memory)
    {
        return stakerToTokenIds[staker];
    }

    function getRewardsByTokenId(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        return
            NEXUS.ownerOf(tokenId) != address(this)
                ? 0
                : (block.timestamp - tokenIdToTimestamp[tokenId]) *
                    NEXUS.getTokenEmissionRate(tokenId);
    }

    function getAllRewards(address staker) public view returns (uint256) {
        uint256[] memory tokenIds = stakerToTokenIds[staker];
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            totalRewards += getRewardsByTokenId(tokenIds[i]);
        }

        return totalRewards;
    }

    function getStakerOf(uint256 tokenId) external view returns (address) {
        return tokenIdToStaker[tokenId];
    }

    //
    // Setters
    //

    function setIsWalletLimited(bool value) external onlyOwner {
        isWalletLimited = value;
    }

    function setMaxPerWallet(uint256 limit) external onlyOwner {
        maxPerWallet = limit;
    }

    function setUseClaimTax(bool value) external onlyOwner {
        useClaimTax = value;
    }

    function setUseClaimBonus(bool value) external onlyOwner {
        useClaimBonus = value;
    }

    function setIsCompoundingEnabled(bool value) external onlyOwner {
        isCompoundingEnabled = value;
    }

    function setTaxPeriodOne(uint256 period) external onlyOwner {
        taxPeriodOne = period;
    }

    function setTaxPeriodTwo(uint256 period) external onlyOwner {
        taxPeriodTwo = period;
    }

    function setTaxPeriodThree(uint256 period) external onlyOwner {
        taxPeriodThree = period;
    }

    function setTaxPercentOne(uint256 percent) external onlyOwner {
        taxPercentOne = percent;
    }

    function setTaxPercentTwo(uint256 percent) external onlyOwner {
        taxPercentTwo = percent;
    }

    function setTaxPercentThree(uint256 percent) external onlyOwner {
        taxPercentThree = percent;
    }

    function setBonusPercent(uint256 percent) external onlyOwner {
        bonusPercent = percent;
    }

    function setNXSAddress(address _NXS) external onlyOwner {
        emit NXSAddressUpdated(address(NXS), _NXS);
        NXS = INexusERC20(_NXS);
    }

    function setNEXUSAddress(address _NEXUS) external onlyOwner {
        emit NEXUSAddressUpdated(address(NEXUS), _NEXUS);
        NEXUS = INexusERC721(_NEXUS);
    }

    //
    // Tax functions
    //

    function shouldTax(address account) public view returns (bool) {
        return (block.timestamp - lastClaimedAt[account]) < taxPeriodThree;
    }

    function getTaxPercent(address account) public view returns (uint256) {
        uint256 diffTime = block.timestamp - lastClaimedAt[account];
        return
            diffTime < taxPeriodTwo
                ? (diffTime < taxPeriodOne ? taxPercentOne : taxPercentTwo)
                : taxPercentThree;
    }

    function compound(uint256 tier, string calldata name)
        external
        whenNotBlacklisted
    {
        require(useClaimTax, "NexusVault: claim tax not enabled");
        require(isCompoundingEnabled, "NexusVault: compounding not enabled");

        if (isWalletLimited) {
            require(
                stakerToTokenIds[_msgSender()].length < maxPerWallet,
                "NexusVault: wallet limit reached"
            );
        }

        uint256 rewards;
        uint256 price = NEXUS.getTierPrice(tier);

        bool canCompound;

        uint256[] memory tokenIds = stakerToTokenIds[_msgSender()];

        for (uint256 i = 0; i < tokenIds.length; i++) {
            rewards += getRewardsByTokenId(tokenIds[i]);
            tokenIdToTimestamp[tokenIds[i]] = block.timestamp;
            if (rewards > price) {
                canCompound = true;
                break;
            }
        }

        require(
            canCompound,
            "NexusVault: insufficient reward balance to compound"
        );

        NEXUS.mint(address(this), tier, name);

        uint256 balance = NEXUS.balanceOf(address(this));
        uint256 tokenId = NEXUS.tokenOfOwnerByIndex(address(this), balance - 1);

        require(
            tokenIdToStaker[tokenId] == address(0),
            "NexusVault: token already staked"
        );

        emit TokenStaked(tokenId);
        emit Compounded(tokenId, tier, _msgSender());

        stakerToTokenIds[_msgSender()].push(tokenId);
        tokenIdToTimestamp[tokenId] = block.timestamp;
        tokenIdToStaker[tokenId] = _msgSender();
        NXS.transfer(_msgSender(), rewards - price);
    }

    //
    // Stake/Unstake/Claim
    //

    function stake(uint256[] calldata tokenIds) external whenNotBlacklisted {
        if (isWalletLimited) {
            require(
                stakerToTokenIds[_msgSender()].length + tokenIds.length <=
                    maxPerWallet,
                "NexusVault: wallet limit reached"
            );
        }

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                NEXUS.ownerOf(tokenIds[i]) == _msgSender(),
                "NexusVault: owner and caller differ"
            );

            require(
                tokenIdToStaker[tokenIds[i]] == address(0),
                "NexusVault: token already staked"
            );

            emit TokenStaked(tokenIds[i]);

            NEXUS.safeTransferFrom(_msgSender(), address(this), tokenIds[i]);
            stakerToTokenIds[_msgSender()].push(tokenIds[i]);
            tokenIdToTimestamp[tokenIds[i]] = block.timestamp;
            tokenIdToStaker[tokenIds[i]] = _msgSender();
        }

        lastClaimedAt[_msgSender()] = block.timestamp;
    }

    function unstake(uint256[] calldata tokenIds) external whenNotBlacklisted {
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                tokenIdToStaker[tokenIds[i]] == _msgSender(),
                "NexusVault: owner and caller differ"
            );

            emit TokenUnstaked(tokenIds[i]);

            totalRewards += getRewardsByTokenId(tokenIds[i]);
            _removeTokenIdFromStaker(_msgSender(), tokenIds[i]);
            tokenIdToStaker[tokenIds[i]] = address(0);

            NEXUS.safeTransferFrom(address(this), _msgSender(), tokenIds[i]);
        }

        if (useClaimTax) {
            if (shouldTax(_msgSender())) {
                totalRewards -=
                    (totalRewards * getTaxPercent(_msgSender())) /
                    100;
            } else if (useClaimBonus) {
                totalRewards += (totalRewards * bonusPercent) / 100;
            }
        }

        lastClaimedAt[_msgSender()] = block.timestamp;
        NXS.transfer(_msgSender(), totalRewards);
        emit RewardsClaimed(totalRewards, _msgSender());
    }

    function claim(uint256[] calldata tokenIds) external whenNotBlacklisted {
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                tokenIdToStaker[tokenIds[i]] == _msgSender(),
                "NexusVault: owner and caller differ"
            );

            totalRewards += getRewardsByTokenId(tokenIds[i]);
            tokenIdToTimestamp[tokenIds[i]] = block.timestamp;
        }

        if (useClaimTax) {
            if (shouldTax(_msgSender())) {
                totalRewards -=
                    (totalRewards * getTaxPercent(_msgSender())) /
                    100;
            } else if (useClaimBonus) {
                totalRewards += (totalRewards * bonusPercent) / 100;
            }
        }

        lastClaimedAt[_msgSender()] = block.timestamp;
        NXS.transfer(_msgSender(), totalRewards);
        emit RewardsClaimed(totalRewards, _msgSender());
    }

    //
    // Cleanup
    //

    function _remove(address staker, uint256 index) internal {
        if (index >= stakerToTokenIds[staker].length) return;

        for (uint256 i = index; i < stakerToTokenIds[staker].length - 1; i++) {
            stakerToTokenIds[staker][i] = stakerToTokenIds[staker][i + 1];
        }

        stakerToTokenIds[staker].pop();
    }

    function _removeTokenIdFromStaker(address staker, uint256 tokenId)
        internal
    {
        for (uint256 i = 0; i < stakerToTokenIds[staker].length; i++) {
            if (stakerToTokenIds[staker][i] == tokenId) {
                _remove(staker, i);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface INexusERC20 is IERC20 {
    function isInBlacklist(address account) external view returns (bool);

    function burn(address from, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
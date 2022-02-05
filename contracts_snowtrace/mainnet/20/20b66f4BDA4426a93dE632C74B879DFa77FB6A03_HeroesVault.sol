// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IHeroesToken.sol";
import "./interfaces/IWorkerToken.sol";

/// @title Heroes Vault Contract
/// @notice Heroes Vault allows users to stake their Hro tokens with Hon tokens
/// to gain Hon tokens without impermanent loss
/// @author defikintaro
contract HeroesVault is Ownable, IERC721Receiver {
  /// @dev Heroes Nft tokens
  address public hroToken;
  /// @dev Hon tokens
  address public honToken;
  /// @dev Worker tokens rewarded after staking
  address public workerToken;

  // Fee address
  address public feeAddress;
  /// @dev Unstaking fee
  uint256 public feePerMillion;

  /// @dev Heroes Nft Id
  /// @dev Hon token amount
  /// @dev Worker token amount
  struct Record {
    uint256 hroId;
    uint256 honAmount;
    uint256 workerAmount;
  }

  /// @dev Heroes Nft rarity
  /// @dev Hon token amount
  /// @dev Worker token amount
  struct Tier {
    uint256 hroRarity;
    uint256 honAmount;
    uint256 workerAmount;
  }

  /// @dev Staked asset record for each player
  mapping(address => mapping(uint256 => Record)) public records;
  /// @dev Track the record count of each player
  mapping(address => uint256) public recordCounts;

  /// @dev Tier list
  Tier[5] public tiers;

  /// @dev Emits when `stake` method has been called
  /// @param staker Staker address
  /// @param tier Staker's tier
  /// @param honAmount Staked Hon token amount
  /// @param hroId Staked Hro token's id
  /// @param workerAmount Issued Worker token amount
  event Stake(address staker, uint256 tier, uint256 honAmount, uint256 hroId, uint256 workerAmount);

  /// @dev Emits when `unstake` method has been called
  /// @param staker Staker address
  /// @param hroId Id of the Hro token
  /// @param fee Hon token fee
  event Unstake(address staker, uint256 hroId, uint256 fee);

  /// @param _hroToken Address of the Hro token contract
  /// @param _workerToken Address of the Worker token contract
  /// @param _honToken Address of the Hon token contract
  /// @param _feeAddress Address of the Fee account
  constructor(
    address _hroToken,
    address _workerToken,
    address _honToken,
    address _feeAddress
  ) {
    hroToken = _hroToken;
    workerToken = _workerToken;
    honToken = _honToken;
    feeAddress = _feeAddress;
  }

  /// @dev Allows staking Hon + Hro pair on tier's requirements
  /// @param honAmount Hon token amount to stake
  /// @param hroId Hro token id to stake
  /// @param tier Staking tier to decide staking requirements
  function stake(
    uint256 honAmount,
    uint256 hroId,
    uint256 tier
  ) external {
    require(tier < tiers.length, "Tier does not exist");
    require(tiers[tier].workerAmount > 0, "Tier is not ready");

    address sender = msg.sender;
    IHeroesToken iHeroesToken = IHeroesToken(hroToken);
    IERC20 iHonToken = IERC20(honToken);

    // Get character data from HRO contract
    (, uint8 rarity, , ) = iHeroesToken.getCharacter(hroId);

    require(iHeroesToken.ownerOf(hroId) == sender, "Sender is not the owner");
    require(iHonToken.balanceOf(sender) >= honAmount, "Not enough Hon tokens");
    require(tiers[tier].honAmount == honAmount, "Hon amount does not match with tier");
    require(tiers[tier].hroRarity == rarity, "Hro rarity does not match with tier");

    // Insert a new record
    records[sender][hroId] = Record({
      hroId: hroId,
      honAmount: honAmount,
      workerAmount: tiers[tier].workerAmount
    });
    recordCounts[sender]++;

    // Collect Hon token
    iHonToken.transferFrom(sender, address(this), honAmount);
    // Collect Hro token
    iHeroesToken.safeTransferFrom(sender, address(this), hroId);
    // Mint Worker token
    IWorkerToken(workerToken).mint(sender, tiers[tier].workerAmount);

    emit Stake(sender, tier, honAmount, hroId, tiers[tier].workerAmount);
  }

  /// @dev Unstakes the staked HON/HRO pair and burns the Worker tokens
  /// @param hroId Id of the Hro token that is being staked
  function unstake(uint256 hroId) external {
    address sender = msg.sender;
    Record memory record = records[sender][hroId];

    require(record.workerAmount > 0, "Record does not exist");
    require(
      IWorkerToken(workerToken).balanceOf(sender) >= record.workerAmount,
      "Not enough worker tokens"
    );

    // Delete the matching record
    delete records[sender][hroId];
    recordCounts[sender]--;

    // Collect the Hon token fee if any
    uint256 fee = (record.honAmount * feePerMillion) / 1e6;

    // Distribute back Hon token
    IERC20(honToken).transfer(sender, record.honAmount - fee);
    // Transfer the fee Hon token
    IERC20(honToken).transfer(feeAddress, fee);
    // Distribute back Hro token
    IHeroesToken(hroToken).safeTransferFrom(address(this), sender, record.hroId);
    // Burn Worker token
    IWorkerToken(workerToken).burn(sender, record.workerAmount);

    emit Unstake(sender, hroId, fee);
  }

  /// @dev Compatability with IERC721 Receiver
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external pure override returns (bytes4) {
    return this.onERC721Received.selector;
  }

  /// @dev Update the tier information
  /// @param _tier Tier id
  /// @param _hroRarity Rarity of Hro token
  /// @param _honAmount Amount of Hon token
  /// @param _workerAmount Amount of Worker token
  /// @notice Updating the amount of Worker token that is given at the each stake
  /// does not change the previous stakes. This can be used to reward previous
  /// stakers by decreasing the future amounts or forces them to unstake them restake
  /// to get increased pool share by increasing the future amounts.
  function updateTier(
    uint256 _tier,
    uint256 _hroRarity,
    uint256 _honAmount,
    uint256 _workerAmount
  ) external onlyOwner {
    tiers[_tier] = Tier({
      hroRarity: _hroRarity,
      honAmount: _honAmount,
      workerAmount: _workerAmount
    });
  }

  /// @dev Update the Hon token contract address
  function updateHonToken(address _honToken) external onlyOwner {
    require(_honToken != address(0), "The new contract address must not be 0");
    honToken = _honToken;
  }

  /// @dev Update the Hro token contract address
  function updateHroToken(address _hroToken) external onlyOwner {
    require(_hroToken != address(0), "The new contract address must not be 0");
    hroToken = _hroToken;
  }

  /// @dev Update the Worker token contract address
  function updateWorkerToken(address _workerToken) external onlyOwner {
    require(_workerToken != address(0), "The new contract address must not be 0");
    workerToken = _workerToken;
  }

  /// @dev Update fee
  function updateFeePerMillion(uint256 _feePerMillion) external onlyOwner {
    feePerMillion = _feePerMillion;
  }

  /// @dev Update fee address
  function updateFeeAddress(address _feeAddress) external onlyOwner {
    feeAddress = _feeAddress;
  }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IHeroesToken is IERC721Enumerable {
  /**
   * @dev bundle
   * @param _bundle_type bundle type identifier
   *   0 : single character
   *   1 : five charactersÓ
   */
  function purchaseBundle(uint8 _bundle_type) external payable;

  /**
   * @dev Get all tokens of specified owner address
   * Requires ERC721Enumerable extension
   */
  function tokensOfOwner(address _owner) external view returns (uint256[] memory);

  /**
   * @dev Get character rarity and random number
   */
  function getCharacter(uint256 character_id)
    external
    view
    returns (
      uint8 o_generation,
      uint8 o_rarity,
      uint256 o_randomNumber,
      bytes32 o_randomHash
    );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWorkerToken is IERC20 {
  function mint(address account, uint256 amount) external;
  function burn(address account, uint256 amount) external;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}
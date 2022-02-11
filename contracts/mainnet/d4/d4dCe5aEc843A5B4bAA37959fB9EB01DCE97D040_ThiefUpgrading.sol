// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "../Ownable.sol";
import "../ITraits.sol";
import "../ILOOT.sol";
import "../IPoliceAndThief.sol";
import "../IERC721.sol";
import "../IBank.sol";
import "../Pauseable.sol";

contract ThiefUpgrading is Ownable, Pauseable {
    event ThiefUpgraded(address owner, uint256 id, uint256 newLevel);
    event TimeReset(uint256 id);

    ITraits traits;
    IPoliceAndThief game;
    IBank bank;
    ILOOT loot;
    ILOOT bribe;

    modifier nonReentrant() {
        require(!_reentrant, "No reentrancy");
        _reentrant = true;
        _;
        _reentrant = false;
    }

    bool private _reentrant = false;

    mapping(uint256 => uint8) public levelOf;
    mapping(uint256 => uint256) public lastUpgradedAt;

    uint256[] public requiredLoot = [
    500 ether, 2000 ether, 4500 ether, 8000 ether, 12500 ether, 12500 ether, 12500 ether, 12500 ether, 12500 ether, 50000,
    12500 ether, 12500 ether, 15000 ether, 15000 ether, 15000 ether, 15000 ether, 15000 ether, 15000 ether, 180500,
    15000 ether, 15000 ether, 15000 ether, 15000 ether, 15000 ether, 15000 ether, 15000 ether, 15000 ether, 15000 ether, 420500,
    15000 ether, 15000 ether, 15000 ether, 15000 ether, 20000 ether, 21000 ether, 22000 ether, 23000 ether, 24000 ether, 25000 ether, 800000,
    26000 ether, 27000 ether, 28000 ether, 29000 ether, 30000 ether
    ];

    uint256[] public requiredBribe = [
    0.10 ether, 0.20 ether, 0.30 ether, 0.40 ether, 0.50 ether, 0.60 ether, 0.70 ether, 0.80 ether, 0.90 ether, 1.00 ether, 1.10 ether, 1.20 ether, 1.30 ether,
    1.40 ether, 1.50 ether, 1.60 ether, 1.70 ether, 1.80 ether, 1.90 ether, 2.00 ether, 2.10 ether, 2.20 ether, 2.30 ether, 2.40 ether, 2.50 ether, 2.60 ether,
    2.70 ether, 2.80 ether, 2.90 ether, 3.00 ether, 3.10 ether, 3.20 ether, 3.30 ether, 3.40 ether, 3.50 ether, 3.60 ether, 3.70 ether, 3.80 ether, 3.90 ether,
    4.00 ether, 4.10 ether, 4.20 ether, 4.30 ether, 4.40 ether, 4.50 ether, 4.60 ether, 4.70 ether, 4.80 ether, 4.90 ether, 5.00 ether, 5.10 ether
    ];

    function changeRequiredLoot(uint256 index, uint256 newValue) public onlyOwner {
        requiredLoot[index] = newValue;
    }

    function changeRequiredBribe(uint256 index, uint256 newValue) public onlyOwner {
        requiredBribe[index] = newValue;
    }

    function upgrade(uint16[] calldata tokenIds) public nonReentrant {
        require(!paused() || msg.sender == owner(), "Paused");
        require(tokenIds.length > 0, "Need more than one token");
        address sender = msg.sender;

        bank.claimForUser(tokenIds, msg.sender);

        uint256 senderBalance = loot.balanceOf(sender);
        uint256 requiredBalance = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            IPoliceAndThief.ThiefPolice memory t = game.getTokenTraits(uint256(tokenIds[i]));
            uint256 _id = uint256(tokenIds[i]);
            require(t.isThief, "Only thieves can be upgraded");

            address owner = game.ownerOf(_id);
            if (owner == address(bank)) {
                owner = bank.realOwnerOf(_id);
            }

            require(ownerOf(_id) == sender, "You are not owner");


            uint8 level = levelOf[_id];
            require(level < 50, "Reached latest level");
            require(block.timestamp - lastUpgradedAt[_id] > level * 3600, "Still need time before upgrading");

            requiredBalance += requiredLoot[level];
            levelOf[_id] += 1;
            lastUpgradedAt[_id] = block.timestamp;

            emit ThiefUpgraded(sender, tokenIds[i], level + 1);
        }

        require(senderBalance >= requiredBalance, "Insufficient LOOT balance");

        loot.burn(sender, requiredBalance);
    }

    function ownerOf(uint256 tokenId) public view returns (address owner) {
        owner = IERC721(address(game)).ownerOf(tokenId);

        if (owner == address(bank)) {
            owner = bank.realOwnerOf(tokenId);
        }

        return owner;
    }

    function setContracts(IBank _bank, IPoliceAndThief _game, ITraits _traits, ILOOT _loot, ILOOT _bribe) public onlyOwner {
        traits = _traits;
        bank = _bank;
        loot = _loot;
        game = _game;
        bribe = _bribe;
    }

    function getTraitsAndLevel(uint256 tokenId) public view returns (IPoliceAndThief.ThiefPolice memory _t, uint8 level) {
        _t = game.getTokenTraits(tokenId);

        if (_t.isThief) {
            level = levelOf[tokenId];
        }

        return (_t, level);
    }

    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    function resetTime(uint256[] memory _ids) public {
        uint256 requiredBalance = 0;
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 level = levelOf[_ids[i]];
            if (level == 0) continue;
            requiredBalance += requiredBribe[level - 1];

            lastUpgradedAt[_ids[i]] = 0;

            emit TimeReset(_ids[i]);
        }
        if (requiredBalance > 0) {
            bribe.burn(msg.sender, requiredBalance);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be Pauseable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pauseable is Context {
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
     * @dev Initializes the contract in paused state.
     */
    constructor() {
        _paused = true;
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
        require(!paused(), "Pauseable: paused");
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
        require(paused(), "Pauseable: not paused");
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

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
        _setOwner(_msgSender());
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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface ITraits {
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function selectTrait(uint16 seed, uint8 traitType) external view returns(uint8);
    function drawSVG(uint256 tokenId) external view returns (string memory);
    function traitData(uint8, uint8) external view returns (string memory, string memory);
    function traitCountForType(uint8) external view returns (uint8);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;


interface IPoliceAndThief {

    // struct to store each token's traits
    struct ThiefPolice {
        bool isThief;
        uint8 uniform;
        uint8 hair;
        uint8 eyes;
        uint8 facialHair;
        uint8 headgear;
        uint8 neckGear;
        uint8 accessory;
        uint8 alphaIndex;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function getPaidTokens() external view returns (uint256);
    function getTokenTraits(uint256 tokenId) external view returns (ThiefPolice memory);
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface ILOOT  {
    function burn(address from, uint256 amount) external;
    function mint(address to, uint256 amount) external;
    function balanceOf(address account) external view returns(uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IBank {
    struct Stake {
        uint16 tokenId;
        uint80 value;
        address owner;
    }

    function claimForUser(uint16[] calldata tokenIds, address _tokenOwner) external;

    function addManyToBankAndPack(address account, uint16[] calldata tokenIds) external;
    function randomPoliceOwner(uint256 seed) external view returns (address);
    function bank(uint256) external view returns(uint16, uint80, address);
    function totalLootEarned() external view returns(uint256);
    function lastClaimTimestamp() external view returns(uint256);
    function setOldTokenInfo(uint256, bool, address, uint256) external;
    function setOldBankStats(uint256, uint256) external;

    function pack(uint256, uint256) external view returns(Stake memory);
    function packIndices(uint256) external view returns(uint256);
    function realOwnerOf(uint256) external view returns(address);

}

// SPDX-License-Identifier: MIT

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
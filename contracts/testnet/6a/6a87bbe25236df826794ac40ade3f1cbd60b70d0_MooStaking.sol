// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/IMilk.sol";

contract MooStaking is IERC721Receiver {
    struct Stake {
        address addr;
        uint64 startTimestamp;
    }

    uint256 public totalStaked;
    uint256 public reward = 1 ether;
    uint256 public interval = 1 minutes;

    // The bit position of `startTimestamp` in packed ownership.
    uint256 private constant _BITPOS_START_TIMESTAMP = 160;

    // The mask of an entry in packed address data.
    uint256 private constant _BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // The mask of the lower 160 bits for addresses.
    uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;

    // Bits Layout:
    // - [0..159]   `addr`           (160 bits)
    // - [160..223] `startTimestamp` (64 bits)
    mapping(uint256 => uint256) private _packedOwnerships;

    mapping(address => uint256) private _balance;

    IERC721 private _collection;
    IMilk private _reward;

    constructor(address collection, address rewardToken) {
        _collection = IERC721(collection);
        _reward = IMilk(rewardToken);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function _unpackedOwnership(uint256 packed) private pure returns (Stake memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> _BITPOS_START_TIMESTAMP);
    }

    function _packedOwnershipOf(uint256 tokenId) private view returns (uint256) {
        unchecked {
            uint256 packed = _packedOwnerships[tokenId];
            return packed;
        }
    }

    function _packOwnershipData(address owner) private view returns (uint256 result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // `owner | (block.timestamp << _BITPOS_START_TIMESTAMP)`.
            result := or(owner, shl(_BITPOS_START_TIMESTAMP, timestamp()))
        }
    }

    function stake(uint256 tokenId) external {
        unchecked {
            _collection.safeTransferFrom(msg.sender, address(this), tokenId, "");
            _packedOwnerships[tokenId] = _packOwnershipData(msg.sender);
            _balance[msg.sender]++;
            totalStaked++;   
        }
    }

    function stakeMany(uint256[] calldata tokenIds) external {
        unchecked {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                _collection.safeTransferFrom(msg.sender, address(this), tokenIds[i], "");
                _packedOwnerships[tokenIds[i]] = _packOwnershipData(msg.sender);
            }
            _balance[msg.sender] += tokenIds.length;
            totalStaked += tokenIds.length;
        }
    }

    function unstake(uint256 tokenId) external {
        unchecked {
            require(ownerOf(tokenId) == msg.sender, "Not the token owner");
            _collection.safeTransferFrom(address(this), msg.sender, tokenId, "");
            delete _packedOwnerships[tokenId];
            _balance[msg.sender]--;
            totalStaked--;
        }
    }

    function unstakeMany(uint256[] calldata tokenIds) external {
        unchecked {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                require(ownerOf(tokenIds[i]) == msg.sender, "Not the token owner");
                _collection.safeTransferFrom(address(this), msg.sender, tokenIds[i], "");
                delete _packedOwnerships[tokenIds[i]];
            }
            _balance[msg.sender] -= tokenIds.length;
            totalStaked -= tokenIds.length;
        }
    }

    function calculateRewards(address owner) external view returns (uint256) {
        unchecked {
            if (_balance[owner] == 0) return 0;
            uint256 rewards;
            Stake memory ownership;
            for (uint256 i = 0; i < totalStaked; i++) {
                ownership = _unpackedOwnership(_packedOwnerships[i]);
                if (ownership.addr == owner) {
                    rewards += reward * ((block.timestamp - ownership.startTimestamp) / interval);
                }
            }
            return rewards;
        }
    }

    function claim() external {
        unchecked {
            require(_balance[msg.sender] > 0, "No token staked to claim");
            uint256 rewards;
            uint256 unstaked;
            Stake memory ownership;
            for (uint256 i = 0; i < totalStaked; i++) {
                ownership = _unpackedOwnership(_packedOwnerships[i]);
                if (ownership.addr == msg.sender) {
                    _collection.safeTransferFrom(address(this), msg.sender, i, "");
                    rewards += reward * ((block.timestamp - ownership.startTimestamp) / interval);
                    delete _packedOwnerships[i];
                    unstaked++;
                }
            }
            _balance[msg.sender] -= unstaked;
            totalStaked -= unstaked;
            _reward.mint(msg.sender, rewards);
        }
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _balance[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IMilk {
    function mint(address to, uint256 amount) external;
    function burnFrom(address from, uint256 amount) external;
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
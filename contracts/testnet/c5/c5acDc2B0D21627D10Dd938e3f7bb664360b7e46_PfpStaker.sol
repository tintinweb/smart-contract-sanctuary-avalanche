// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import {ReentrancyGuard} from '../utils/ReentrancyGuard.sol';
import {Owned} from '../utils/Owned.sol';
import {NFTreceiver} from '../utils/NFTreceiver.sol';

import {IPfpStaker} from '../interfaces/IPfpStaker.sol';

import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IERC721Metadata} from '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import {IERC1155} from '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import {IERC1155MetadataURI} from '@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol';

/**
 * @title PfpStaker
 * @notice Allows groups to stake an NFT to use as their pfp - defaults to shield
 */
contract PfpStaker is IPfpStaker, ReentrancyGuard, Owned, NFTreceiver {
	/// ----------------------------------------------------------------------------------------
	/// EVENTS
	/// ----------------------------------------------------------------------------------------

	event StakedNFT(address indexed dao, address NFTContract, uint256 tokenId);

	/// ----------------------------------------------------------------------------------------
	/// ERRORS
	/// ----------------------------------------------------------------------------------------

	error Unauthorised();

	error RestrictedNFT();

	error NotTokenHolder();

	/// ----------------------------------------------------------------------------------------
	/// PFP STORAGE
	/// ----------------------------------------------------------------------------------------

	address private immutable THIS_ADDRESS;

	address public shieldContract;
	address public forumFactory;

	bytes4 constant ERC721_METADATA = 0x5b5e139f;
	bytes4 constant ERC1155_METADATA = 0x0e89341c;

	/// When true, only certain contracts can be used as in app pfps
	bool public restrictedContracts = true;

	mapping(address => StakedPFP) public stakes;
	mapping(address => bool) public enabledPfpContracts;

	/// ----------------------------------------------------------------------------------------
	/// CONSTRUCTOR
	/// ----------------------------------------------------------------------------------------

	/**
	 * @notice Allows groups to stake an NFT to use as their pfp - defaults to shield
	 * @param deployer The address of the owner that is deploying the contract
	 * @param shieldContract_ The address of the shield contract
	 * @param forumFactory_ The address of the forum factory
	 */
	constructor(
		address deployer,
		address shieldContract_,
		address forumFactory_
	) Owned(deployer) {
		shieldContract = shieldContract_;

		forumFactory = forumFactory_;

		enabledPfpContracts[shieldContract_] = true;

		THIS_ADDRESS = address(this);
	}

	/// ----------------------------------------------------------------------------------------
	/// Owner Interface
	/// ----------------------------------------------------------------------------------------

	/**
	 * @notice Set Forum Factory - this address can set stakers directly. This happens on multisig creation.
	 * @param forumFactory_ Address of multisig factory
	 */
	function setForumFactory(address forumFactory_) external onlyOwner {
		forumFactory = forumFactory_;
	}

	/**
	 * @notice Update shieldContract
	 * @param shieldContract_ Address of ShieldManager
	 */
	function setShieldContract(address shieldContract_) external onlyOwner {
		shieldContract = shieldContract_;
		enabledPfpContracts[shieldContract_] = true;
	}

	/**
	 * @notice Restrict the NFT collections that can be used as PFPs
	 */
	function setRestrictedContracts() external onlyOwner {
		restrictedContracts = !restrictedContracts;
	}

	/**
	 * @notice For adding allowed NFT collections
	 * @param NFTContract Address of the contract to add to allowed list
	 */
	function setEnabledContract(address NFTContract) external onlyOwner {
		enabledPfpContracts[NFTContract] = true;
	}

	/// ----------------------------------------------------------------------------------------
	/// External Interface
	/// ----------------------------------------------------------------------------------------

	/**
	 * @notice Stake the initial shield minted during group creation
	 * @param recipient Group that the shield is staked for
	 * @param shieldId TokenId of shield
	 */
	function stakeInitialShield(address recipient, uint256 shieldId) external {
		if (msg.sender != forumFactory) revert Unauthorised();

		stakes[recipient] = StakedPFP(shieldContract, shieldId);

		emit StakedNFT(recipient, shieldContract, shieldId);
	}

	/**
	 * @notice Lets a group stake an NFT to use as their pfp
	 * @param staker Address of the group doing the stake
	 * @param NFTContract Address of the contract to add to allowed list
	 * @param tokenId TokenId of shield
	 */
	function stakeNFT(
		address staker,
		address NFTContract,
		uint256 tokenId
	) external {
		if (restrictedContracts && !enabledPfpContracts[NFTContract]) revert RestrictedNFT();

		if (msg.sender != staker) revert Unauthorised();

		// Check if NFTContract is ERC721
		if (IERC721(NFTContract).supportsInterface(ERC721_METADATA)) {
			if (IERC721(NFTContract).ownerOf(tokenId) != staker) revert NotTokenHolder();
			if (stakes[staker].NFTcontract != address(0)) unstakeNFT();

			// Transfer ERC721 from group to PFP
			IERC721(NFTContract).safeTransferFrom(staker, THIS_ADDRESS, tokenId);
			stakes[staker] = StakedPFP(NFTContract, tokenId);

			emit StakedNFT(staker, NFTContract, tokenId);
		} else {
			// Check if NFTContract is ERC1155
			if (IERC1155(NFTContract).supportsInterface(ERC1155_METADATA)) {
				if (IERC1155(NFTContract).balanceOf(staker, tokenId) == 0) revert NotTokenHolder();

				if (stakes[staker].NFTcontract != address(0)) unstakeNFT();

				// Transfer ERC1155 from group to PFP
				IERC1155(NFTContract).safeTransferFrom(staker, THIS_ADDRESS, tokenId, 1, '');
				stakes[staker] = StakedPFP(NFTContract, tokenId);

				emit StakedNFT(owner, NFTContract, tokenId);
			}
		}
	}

	/**
	 * @notice Return URI for NFT depending on the type
	 * @param staker Address of the contract to add to allowed list
	 * @return nftURI The URI of the NFT
	 */
	// Return URI for NFT depending on the type
	function getURI(address staker) external view returns (string memory nftURI) {
		StakedPFP memory stake = stakes[staker];
		if (IERC721(stake.NFTcontract).supportsInterface(ERC721_METADATA)) {
			nftURI = IERC721Metadata(stake.NFTcontract).tokenURI(stake.tokenId);
		} else {
			if (IERC1155(stake.NFTcontract).supportsInterface(ERC1155_METADATA)) {
				nftURI = IERC1155MetadataURI(stake.NFTcontract).uri(stake.tokenId);
			}
		}
	}

	/**
	 * @notice Return token staked by address
	 * @return NFTContract
	 * @return tokenId
	 */
	function getStakedNFT() external view returns (address NFTContract, uint256 tokenId) {
		(NFTContract, tokenId) = (stakes[msg.sender].NFTcontract, stakes[msg.sender].tokenId);
	}

	/// ----------------------------------------------------------------------------------------
	/// Internal Interface
	/// ----------------------------------------------------------------------------------------

	function unstakeNFT() internal {
		if (IERC721(stakes[msg.sender].NFTcontract).supportsInterface(ERC721_METADATA)) {
			IERC721(stakes[msg.sender].NFTcontract).safeTransferFrom(
				THIS_ADDRESS,
				msg.sender,
				stakes[msg.sender].tokenId
			);
		} else {
			if (IERC1155(stakes[msg.sender].NFTcontract).supportsInterface(ERC1155_METADATA)) {
				IERC1155(stakes[msg.sender].NFTcontract).safeTransferFrom(
					THIS_ADDRESS,
					msg.sender,
					stakes[msg.sender].tokenId,
					1,
					''
				);
			}
		}
	}
}

// SPDX-License-Identifier: AGPL-3.0-only
// pragma solidity ^0.8.13;

/// @notice Gas optimized reentrancy protection for smart contracts
/// @author Modified from KaliDAO (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
	error Reentrancy();

	uint256 private constant _NOT_ENTERED = 1;
	uint256 private constant _ENTERED = 2;

	uint256 private _status;

	constructor() {
		_status = _NOT_ENTERED;
	}

	modifier nonReentrant() {
		// On the first call to nonReentrant, _notEntered will be true
		//require(_status != _ENTERED, 'ReentrancyGuard: reentrant call');
		if (_status == _ENTERED) revert Reentrancy();

		// Any calls to nonReentrant after this point will fail
		_status = _ENTERED;

		_;

		// By storing the original value once again, a refund is triggered (see
		// https://eips.ethereum.org/EIPS/eip-2200)
		_status = _NOT_ENTERED;
	}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
	/*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

	event OwnerUpdated(address indexed user, address indexed newOwner);

	/*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

	address public owner;

	modifier onlyOwner() virtual {
		require(msg.sender == owner, 'UNAUTHORIZED');

		_;
	}

	/*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

	constructor(address _owner) {
		owner = _owner;

		emit OwnerUpdated(address(0), _owner);
	}

	/*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

	function setOwner(address newOwner) public virtual onlyOwner {
		owner = newOwner;

		emit OwnerUpdated(msg.sender, newOwner);
	}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

/// @notice Receiver hook utility for NFT 'safe' transfers
/// @author Author KaliDAO (https://github.com/kalidao/kali-contracts/blob/main/contracts/utils/NFTreceiver.sol)
abstract contract NFTreceiver {
	function onERC721Received(
		address,
		address,
		uint256,
		bytes calldata
	) external pure returns (bytes4) {
		return 0x150b7a02;
	}

	function onERC1155Received(
		address,
		address,
		uint256,
		uint256,
		bytes calldata
	) external pure returns (bytes4) {
		return 0xf23a6e61;
	}

	function onERC1155BatchReceived(
		address,
		address,
		uint256[] calldata,
		uint256[] calldata,
		bytes calldata
	) external pure returns (bytes4) {
		return 0xbc197c81;
	}
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

// PFP allows groups to stake an NFT to use as their pfp - defaults to shield
interface IPfpStaker {
	struct StakedPFP {
		address NFTcontract;
		uint256 tokenId;
	}

	function stakeInitialShield(address, uint256) external;

	function stakeNFT(
		address,
		address,
		uint256
	) external;

	function getURI(address) external view returns (string memory nftURI);

	function getStakedNFT() external view returns (address NFTContract, uint256 tokenId);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
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
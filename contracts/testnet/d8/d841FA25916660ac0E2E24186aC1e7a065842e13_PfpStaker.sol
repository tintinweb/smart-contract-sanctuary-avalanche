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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

// PFP allows groups to stake an NFT to use as their pfp
interface IPfpStaker {
	struct StakedPFP {
		address Nftcontract;
		uint256 tokenId;
	}

	function stakeNFT(address, address, uint256) external;

	function getURI(address, string calldata) external view returns (string memory nftURI);

	function getStakedNFT(address) external view returns (address NftContract, uint256 tokenId);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.4;

/// @notice JSON utilities for base64 encoded ERC721 JSON metadata scheme
/// @author KaliDAO (https://github.com/kalidao/kali-contracts/blob/main/contracts/libraries/SVG.sol)
/// License-Identifier: MIT
library JSON {
    /// @dev Base64 encoding/decoding table
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function _formattedMetadata(
        string memory name,
        string memory description,
        string memory svgImg
    ) internal pure returns (string memory) {
        return
            string.concat(
                "data:application/json;base64,",
                _encode(
                    bytes(
                        string.concat(
                            "{",
                            _prop("name", name),
                            _prop("description", description),
                            _xmlImage(svgImg),
                            "}"
                        )
                    )
                )
            );
    }

    function _xmlImage(string memory svgImg)
        internal
        pure
        returns (string memory)
    {
        return
            _prop(
                "image",
                string.concat(
                    "data:image/svg+xml;base64,",
                    _encode(bytes(svgImg))
                ),
                true
            );
    }

    function _prop(string memory key, string memory val)
        internal
        pure
        returns (string memory)
    {
        return string.concat('"', key, '": ', '"', val, '", ');
    }

    function _prop(
        string memory key,
        string memory val,
        bool last
    ) internal pure returns (string memory) {
        if (last) {
            return string.concat('"', key, '": ', '"', val, '"');
        } else {
            return string.concat('"', key, '": ', '"', val, '", ');
        }
    }

    function _object(string memory key, string memory val)
        internal
        pure
        returns (string memory)
    {
        return string.concat('"', key, '": ', "{", val, "}");
    }

    /// @dev converts `bytes` to `string` representation
    function _encode(bytes memory data) internal pure returns (string memory) {
        // Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
        // https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(18, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(12, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(6, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.4;

/// @notice Core SVG utility library which helps us construct
/// onchain SVGs with a simple, web-like API
/// @author KaliDAO (https://github.com/kalidao/kali-contracts/blob/main/contracts/libraries/SVG.sol)
/// License-Identifier: MIT
library SVG {
    /// -----------------------------------------------------------------------
    /// Constants
    /// -----------------------------------------------------------------------

    string internal constant NULL = "";

    /// -----------------------------------------------------------------------
    /// Elements
    /// -----------------------------------------------------------------------

    function _text(string memory props, string memory children)
        internal
        pure
        returns (string memory)
    {
        return _el("text", props, children);
    }

    function _rect(string memory props, string memory children)
        internal
        pure
        returns (string memory)
    {
        return _el("rect", props, children);
    }

    function _image(string memory href, string memory props)
        internal
        pure
        returns (string memory)
    {
        return
            _el("image", string.concat(_prop("href", href), " ", props), NULL);
    }

    function _cdata(string memory content)
        internal
        pure
        returns (string memory)
    {
        return string.concat("<![CDATA[", content, "]]>");
    }

    /// -----------------------------------------------------------------------
    /// Generics
    /// -----------------------------------------------------------------------

    /// @dev a generic element, can be used to construct any SVG (or HTML) element
    function _el(
        string memory tag,
        string memory props,
        string memory children
    ) internal pure returns (string memory) {
        return
            string.concat("<", tag, " ", props, ">", children, "</", tag, ">");
    }

    /// @dev an SVG attribute
    function _prop(string memory key, string memory val)
        internal
        pure
        returns (string memory)
    {
        return string.concat(key, "=", '"', val, '" ');
    }

    /// @dev converts an unsigned integer to a string
    function _uint2str(uint256 i) internal pure returns (string memory) {
        if (i == 0) {
            return "0";
        }
        uint256 j = i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(i - (i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            i /= 10;
        }
        return string(bstr);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import {ReentrancyGuard} from '../utils/ReentrancyGuard.sol';
import {NFTreceiver} from '../utils/NFTreceiver.sol';

import {IPfpStaker} from '../interfaces/IPfpStaker.sol';

import {SVG} from '../libraries/SVG.sol';
import {JSON} from '../libraries/JSON.sol';

import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IERC721Metadata} from '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import {IERC1155} from '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import {IERC1155MetadataURI} from '@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol';

/**
 * @title PfpStaker
 * @notice Allows groups to stake an NFT to use as their pfp and generates token uri for group tokens
 */
contract PfpStaker is IPfpStaker, ReentrancyGuard, NFTreceiver {
	/// ----------------------------------------------------------------------------------------
	/// EVENTS
	/// ----------------------------------------------------------------------------------------

	event StakedNFT(address indexed dao, address NftContract, uint256 tokenId);

	/// ----------------------------------------------------------------------------------------
	/// ERRORS
	/// ----------------------------------------------------------------------------------------

	error Unauthorised();

	error NotTokenHolder();

	/// ----------------------------------------------------------------------------------------
	/// PFP STORAGE
	/// ----------------------------------------------------------------------------------------

	address private immutable THIS_ADDRESS;

	bytes4 constant ERC721_METADATA = 0x5b5e139f;
	bytes4 constant ERC1155_METADATA = 0x0e89341c;

	mapping(address => StakedPFP) public stakes;

	/// ----------------------------------------------------------------------------------------
	/// CONSTRUCTOR
	/// ----------------------------------------------------------------------------------------

	/**
	 * @notice Allows groups to stake an NFT to use as their pfp - defaults to shield
	 */
	constructor() {
		THIS_ADDRESS = address(this);
	}

	/// ----------------------------------------------------------------------------------------
	/// External Interface
	/// ----------------------------------------------------------------------------------------

	/**
	 * @notice Lets a group stake an NFT to use as their pfp
	 * @param staker Address of the group doing the stake
	 * @param NftContract Address of the contract to add to allowed list
	 * @param tokenId TokenId of shield
	 */
	function stakeNFT(address staker, address NftContract, uint256 tokenId) external {
		if (msg.sender != staker) revert Unauthorised();

		if (NftContract == address(0)) {
			unstakeNFT();
		} else {
			// Check if NftContract is ERC721
			if (IERC721(NftContract).supportsInterface(ERC721_METADATA)) {
				if (IERC721(NftContract).ownerOf(tokenId) != staker) revert NotTokenHolder();
				if (stakes[staker].Nftcontract != address(0)) unstakeNFT();

				// Transfer ERC721 from group to PFP
				IERC721(NftContract).safeTransferFrom(staker, THIS_ADDRESS, tokenId);
				stakes[staker] = StakedPFP(NftContract, tokenId);

				emit StakedNFT(staker, NftContract, tokenId);
			} else {
				// Check if NftContract is ERC1155
				if (IERC1155(NftContract).supportsInterface(ERC1155_METADATA)) {
					if (IERC1155(NftContract).balanceOf(staker, tokenId) == 0)
						revert NotTokenHolder();

					if (stakes[staker].Nftcontract != address(0)) unstakeNFT();

					// Transfer ERC1155 from group to PFP
					IERC1155(NftContract).safeTransferFrom(staker, THIS_ADDRESS, tokenId, 1, '');
					stakes[staker] = StakedPFP(NftContract, tokenId);

					emit StakedNFT(staker, NftContract, tokenId);
				}
			}
		}
	}

	/**
	 * @notice Return URI for NFT depending on the type
	 * @param staker Address of the contract to add to allowed list
	 * @return nftURI The URI of the NFT
	 */
	// Return URI for NFT depending on the type
	function getURI(
		address staker,
		string calldata groupName
	) external view returns (string memory) {
		StakedPFP memory stake = stakes[staker];

		string memory image;
		if (stake.Nftcontract == address(0)) {
			image = '<svg viewBox="0 0 220 100" xmlns="http://www.w3.org/2000/svg"><path d="M0 0h100v100H0z"/></svg>';
		} else {
			// Check if NftContract is ERC721
			if (IERC721(stake.Nftcontract).supportsInterface(ERC721_METADATA)) {
				image = IERC721Metadata(stake.Nftcontract).tokenURI(stake.tokenId);
			} else {
				// Check if NftContract is ERC1155
				if (IERC1155(stake.Nftcontract).supportsInterface(ERC1155_METADATA)) {
					image = IERC1155MetadataURI(stake.Nftcontract).uri(stake.tokenId);
				}
			}
		}
		return _buildURI(groupName, image);
	}

	/**
	 * @notice Return token staked by address
	 * @return NftContract
	 * @return tokenId
	 */
	function getStakedNFT(
		address staker
	) external view returns (address NftContract, uint256 tokenId) {
		(NftContract, tokenId) = (stakes[staker].Nftcontract, stakes[staker].tokenId);
	}

	/// ----------------------------------------------------------------------------------------
	/// Internal Interface
	/// ----------------------------------------------------------------------------------------

	function _buildURI(
		string calldata groupName,
		string memory image
	) private pure returns (string memory) {
		return
			JSON._formattedMetadata(
				string.concat('Access #'),
				'Group Token',
				string.concat(
					'<svg xmlns="http://www.w3.org/2000/svg" width="300" height="300" style="background:#191919">',
					SVG._text(
						string.concat(
							SVG._prop('x', '20'),
							SVG._prop('y', '40'),
							SVG._prop('font-size', '22'),
							SVG._prop('fill', 'white')
						),
						SVG._cdata(groupName)
					),
					SVG._rect(
						string.concat(
							SVG._prop('fill', 'maroon'),
							SVG._prop('x', '20'),
							SVG._prop('y', '50'),
							SVG._prop('width', SVG._uint2str(160)),
							SVG._prop('height', SVG._uint2str(10))
						),
						SVG.NULL
					),
					SVG._image(
						image,
						string.concat(
							SVG._prop('x', '215'),
							SVG._prop('y', '220'),
							SVG._prop('width', '80')
						)
					),
					'</svg>'
				)
			);
	}

	function unstakeNFT() internal {
		if (IERC721(stakes[msg.sender].Nftcontract).supportsInterface(ERC721_METADATA)) {
			IERC721(stakes[msg.sender].Nftcontract).safeTransferFrom(
				THIS_ADDRESS,
				msg.sender,
				stakes[msg.sender].tokenId
			);
		} else {
			if (IERC1155(stakes[msg.sender].Nftcontract).supportsInterface(ERC1155_METADATA)) {
				IERC1155(stakes[msg.sender].Nftcontract).safeTransferFrom(
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

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
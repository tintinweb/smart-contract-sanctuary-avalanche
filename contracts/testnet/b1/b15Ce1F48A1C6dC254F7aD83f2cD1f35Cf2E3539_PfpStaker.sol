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
	function stakeNft(address, uint256) external;

	function getUri(address, string calldata, uint256) external view returns (string memory nftURI);

	function getStakedNft(address) external view returns (uint256 tokenId);
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
import {Owned} from '../utils/Owned.sol';

import {SVG} from '../libraries/SVG.sol';
import {JSON} from '../libraries/JSON.sol';

import {IERC1155} from '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import {IERC1155MetadataURI} from '@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol';

/**
 * @title PfpStaker
 * @notice Allows groups to stake an NFT to use as their pfp and generates token uri for group tokens
 */
contract PfpStaker is IPfpStaker, ReentrancyGuard, NFTreceiver, Owned {
	/// ----------------------------------------------------------------------------------------
	/// EVENTS
	/// ----------------------------------------------------------------------------------------

	event StakedNft(address indexed dao, uint256 tokenId);

	/// ----------------------------------------------------------------------------------------
	/// ERRORS
	/// ----------------------------------------------------------------------------------------

	error Unauthorised();

	error NotTokenHolder();

	/// ----------------------------------------------------------------------------------------
	/// PFP STORAGE
	/// ----------------------------------------------------------------------------------------

	address private immutable THIS_ADDRESS;

	// The erc1155 contract storing pfps
	address public pfpStore;

	bytes4 private constant ERC721_METADATA = 0x5b5e139f;
	bytes4 private constant ERC1155_METADATA = 0x0e89341c;

	// Staked Nft by address (all nfts are erc1155 tokens on the pfpStore contract)
	mapping(address => uint256) public stakedNft;

	/// ----------------------------------------------------------------------------------------
	/// CONSTRUCTOR
	/// ----------------------------------------------------------------------------------------

	constructor(address deployer) Owned(deployer) {
		THIS_ADDRESS = address(this);
	}

	/// ----------------------------------------------------------------------------------------
	/// Owner Interface
	/// ----------------------------------------------------------------------------------------

	/**
	 * @notice Lets owner set the pfp store
	 * @param contractAddress Address of the contract to add as store
	 */
	function setPfpStore(address contractAddress) external onlyOwner {
		pfpStore = contractAddress;
	}

	/// ----------------------------------------------------------------------------------------
	/// External Interface
	/// ----------------------------------------------------------------------------------------

	/**
	 * @notice Lets a group stake an NFT to use as their pfp
	 * @param staker Address of the group doing the stake
	 * @param tokenId TokenId of shield
	 */
	function stakeNft(address staker, uint256 tokenId) external {
		// Only sender or store can stake (store stakes on mint of new token)
		if (!(msg.sender == staker || msg.sender == pfpStore)) revert Unauthorised();

		if (IERC1155(pfpStore).balanceOf(staker, tokenId) == 0) revert NotTokenHolder();

		if (tokenId == 0) {
			unstakeNFT(staker);
		} else {
			if (stakedNft[staker] != 0) unstakeNFT(staker);

			// Transfer ERC1155 from group to PfpStaker
			IERC1155(pfpStore).safeTransferFrom(staker, THIS_ADDRESS, tokenId, 1, '');
			stakedNft[staker] = tokenId;

			emit StakedNft(staker, tokenId);
		}
	}

	/**
	 * @notice Return URI for NFT depending on the type
	 * @param staker Address of the contract to add to allowed list
	 * @return nftURI The URI of the NFT
	 */
	function getUri(
		address staker,
		string calldata groupName,
		uint256 tokenId
	) external view returns (string memory) {
		uint256 stake = stakedNft[staker];

		string memory image;
		if (stake == 0) {
			image = '<path fill-rule="evenodd" clip-rule="evenodd" d="M124.215 103.45c-3.719.034-6.707 3.074-6.673 6.79.003.286.023.568.06.845-7.708 6.251-13.137 14.89-15.413 24.574-2.3899 10.169-1.153 20.852 3.496 30.208 4.65 9.356 12.421 16.797 21.974 21.04 9.553 4.244 20.289 5.024 30.356 2.206-.823-1.972-1.166-3.147-1.498-5.342-8.822 2.47-18.23 1.786-26.602-1.933-8.372-3.719-15.182-10.24-19.257-18.438-4.074-8.199-5.158-17.561-3.063-26.473 1.944-8.271 6.513-15.673 12.997-21.115 1.076.704 2.365 1.108 3.747 1.095 3.719-.034 6.707-3.074 6.673-6.79-.034-3.717-3.077-6.702-6.797-6.667Zm.024 2.577c2.295-.021 4.172 1.821 4.193 4.113.021 2.293-1.822 4.169-4.117 4.19-2.295.021-4.172-1.821-4.193-4.113-.021-2.293 1.822-4.169 4.117-4.19ZM171.483 178.023l.321.404c.462.66.737 1.461.748 2.327.027 2.293-1.811 4.173-4.105 4.201-2.295.027-4.178-1.809-4.205-4.102-.028-2.292 1.81-4.173 4.105-4.201 1.242-.015 2.364.517 3.136 1.371Zm3.602 1.985c7.44-6.358 12.609-14.983 14.693-24.57 2.196-10.102.833-20.652-3.859-29.866-4.692-9.214-12.425-16.526-21.891-20.7-9.466-4.173-20.084-4.9524-30.059-2.205.887 2.025 1.228 3.191 1.475 5.348 8.742-2.407 18.047-1.725 26.343 1.933 8.295 3.657 15.072 10.065 19.183 18.14 4.112 8.074 5.307 17.32 3.382 26.173-1.764 8.112-6.048 15.438-12.21 20.949-1.093-.732-2.411-1.152-3.826-1.135-3.719.044-6.698 3.093-6.654 6.809.045 3.716 3.096 6.693 6.816 6.648 3.719-.044 6.698-3.093 6.653-6.809-.002-.242-.018-.48-.046-.715Z" fill="#fff"/><path d="M168.35 145.914c0 12.388-10.051 22.431-22.45 22.431s-22.451-10.043-22.451-22.431c0-12.388 10.052-22.431 22.451-22.431 12.399 0 22.45 10.043 22.45 22.431Zm-39.416 0c0 9.362 7.596 16.951 16.966 16.951 9.37 0 16.966-7.589 16.966-16.951s-7.596-16.951-16.966-16.951c-9.37 0-16.966 7.589-16.966 16.951Z" fill="#fff"/>';
		} else {
			image = IERC1155MetadataURI(pfpStore).uri(stake);
		}
		return _buildURI(groupName, image, tokenId);
	}

	/**
	 * @notice Return token staked by address
	 * @return tokenId
	 */
	function getStakedNft(address staker) external view returns (uint256 tokenId) {
		tokenId = stakedNft[staker];
	}

	/// ----------------------------------------------------------------------------------------
	/// Internal Interface
	/// ----------------------------------------------------------------------------------------

	function _buildURI(
		string calldata groupName,
		string memory image,
		uint256 tokenId
	) private pure returns (string memory) {
		return
			JSON._formattedMetadata(
				string.concat(groupName, ' Group Token'),
				string.concat('Forum Group', tokenId == 0 ? 'Membership Pass' : 'GovernanceToken'),
				string.concat(
					'<svg width="300" height="300" fill="none" xmlns="http://www.w3.org/2000/svg"><filter id="filter" x="0" y="0" width="300" height="300" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB"><feFlood flood-opacity="0" result="BackgroundImageFix"/><feBlend in="SourceGraphic" in2="BackgroundImageFix" result="shape"/><feColorMatrix in="SourceAlpha" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" result="hardAlpha"/><feOffset dy="-80"/><feGaussianBlur stdDeviation="50"/><feComposite in2="hardAlpha" operator="arithmetic" k2="-1" k3="1"/><feColorMatrix values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0"/><feBlend in2="shape" result="effect1_innerShadow_2276_3624"/></filter><g filter="url(#filter)"><rect width="300" height="300" rx="11.078" fill="#37373D" fill-opacity=".5"/></g>',
					SVG._el(
						'g',
						string.concat(SVG._prop('id', 'background'), SVG._prop('filter', 'filter')),
						image
					),
					SVG._el(
						'use',
						string.concat(
							SVG._prop('x', '0'),
							SVG._prop('y', '0'),
							SVG._prop('href', '#background')
						),
						''
					),
					SVG._text(
						string.concat(
							SVG._prop('x', '20'),
							SVG._prop('y', '250'),
							SVG._prop('font-size', '22'),
							SVG._prop('fill', 'white')
						),
						SVG._cdata(groupName)
					),
					SVG._text(
						string.concat(
							SVG._prop('x', '20'),
							SVG._prop('y', '270'),
							SVG._prop('font-size', '12'),
							SVG._prop('fill', 'white')
						),
						SVG._cdata(tokenId == 0 ? 'Membership Pass' : 'GovernanceToken')
					),
					'</svg>'
				)
			);
	}

	function unstakeNFT(address staker) internal {
		IERC1155(pfpStore).safeTransferFrom(THIS_ADDRESS, staker, stakedNft[staker], 1, '');
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
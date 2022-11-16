// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import {OrderTypes} from "../../libraries/OrderTypes.sol";

import {IERC165} from "../../interfaces/IERC165.sol";

/**
 * @title JoepegsCrowdfundHandler
 * @notice Handles decoding of crowdfund payload for Joepegs Marketplace
 */
contract JoepegsCrowdfundHandler {
    /// ----------------------------------------------------------------------------------------
    ///							JoepegsCrowdfundHandler Storage
    /// ----------------------------------------------------------------------------------------

    error InvalidFunction();

    // ERC721 interfaceID
    bytes4 public constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    // ERC1155 interfaceID
    bytes4 public constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

    /// bytes4 key is the function signature
    mapping(bytes4 => uint256) public enabledMethods;

    /// ----------------------------------------------------------------------------------------
    ///							Constructor
    /// ----------------------------------------------------------------------------------------

    /**
     * @notice Constructor
     * @param _enabledMethods Array of function signatures to enable
     */
    constructor(bytes4[] memory _enabledMethods) {
        // Set the functions that are enabled -> 1 for enabled
        for (uint256 i; i < _enabledMethods.length; i++) {
            enabledMethods[_enabledMethods[i]] = 1;
        }
    }

    /// ----------------------------------------------------------------------------------------
    ///							Public Interface
    /// ----------------------------------------------------------------------------------------

    /**
     * @notice Decides commission to charge based on the function being called.
     *     		 Since all on-chain joe functions decode a TakerOrder, we can do
     *     		 everything in handleCrowdfund.
     * @param crowdfundContract address of the crowdfund contract
     * @param assetContract address of the asset contract
     * @param forumGroup address of the forum group
     * @param tokenId tokenId of the NFT
     * @return payload to decode and extract commission info from
     */
    function handleCrowdfundExecution(
        address crowdfundContract,
        address assetContract,
        address forumGroup,
        uint256 tokenId,
        bytes calldata payload
    )
        external
        view
        returns (uint256, bytes memory)
    {
        // Extract function sig from payload as the first 4 bytes
        bytes4 functionSig = bytes4(payload[0:4]);

        // If enabled method, decode the payload, extract price, and form transferPayload
        if (enabledMethods[functionSig] == 1) {
            OrderTypes.TakerOrder memory takerOrder =
                abi.decode(payload[4:], (OrderTypes.TakerOrder));

            // Build a transfer payload depending on the asset type
            if (IERC165(assetContract).supportsInterface(INTERFACE_ID_ERC721)) {
                return (
                    takerOrder.price,
                    abi.encodeWithSignature(
                        "safeTransferFrom(address,address,uint256)",
                        crowdfundContract,
                        forumGroup,
                        tokenId
                        )
                );
            }
            if (IERC165(assetContract).supportsInterface(INTERFACE_ID_ERC1155))
            {
                return (
                    takerOrder.price,
                    abi.encodeWithSignature(
                        "safeTransferFrom(address,address,uint256,uint256,bytes)",
                        crowdfundContract,
                        forumGroup,
                        tokenId,
                        1,
                        ""
                        )
                );
            }
        }

        // If function is not listed, revert
        revert InvalidFunction();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.13;

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

/**
 * @title OrderTypes
 * @notice This library contains order types for the Joepeg exchange.
 */
library OrderTypes {
	// keccak256("MakerOrder(bool isOrderAsk,address signer,address collection,uint256 price,uint256 tokenId,uint256 amount,address strategy,address currency,uint256 nonce,uint256 startTime,uint256 endTime,uint256 minPercentageToAsk,bytes params)")
	bytes32 internal constant MAKER_ORDER_HASH =
		0x40261ade532fa1d2c7293df30aaadb9b3c616fae525a0b56d3d411c841a85028;

	struct MakerOrder {
		bool isOrderAsk; // true --> ask / false --> bid
		address signer; // signer of the maker order
		address collection; // collection address
		uint256 price; // price (used as )
		uint256 tokenId; // id of the token
		uint256 amount; // amount of tokens to sell/purchase (must be 1 for ERC721, 1+ for ERC1155)
		address strategy; // strategy for trade execution (e.g., DutchAuction, StandardSaleForFixedPrice)
		address currency; // currency (e.g., WETH)
		uint256 nonce; // order nonce (must be unique unless new maker order is meant to override existing one e.g., lower ask price)
		uint256 startTime; // startTime in timestamp
		uint256 endTime; // endTime in timestamp
		uint256 minPercentageToAsk; // slippage protection (9000 --> 90% of the final price must return to ask)
		bytes params; // additional parameters
		uint8 v; // v: parameter (27 or 28)
		bytes32 r; // r: parameter
		bytes32 s; // s: parameter
	}

	struct TakerOrder {
		bool isOrderAsk; // true --> ask / false --> bid
		address taker; // msg.sender
		uint256 price; // final price for the purchase
		uint256 tokenId;
		uint256 minPercentageToAsk; // // slippage protection (9000 --> 90% of the final price must return to ask)
		bytes params; // other params (e.g., tokenId)
	}

	function hash(MakerOrder memory makerOrder) internal pure returns (bytes32) {
		return
			keccak256(
				abi.encode(
					MAKER_ORDER_HASH,
					makerOrder.isOrderAsk,
					makerOrder.signer,
					makerOrder.collection,
					makerOrder.price,
					makerOrder.tokenId,
					makerOrder.amount,
					makerOrder.strategy,
					makerOrder.currency,
					makerOrder.nonce,
					makerOrder.startTime,
					makerOrder.endTime,
					makerOrder.minPercentageToAsk,
					keccak256(makerOrder.params)
				)
			);
	}
}
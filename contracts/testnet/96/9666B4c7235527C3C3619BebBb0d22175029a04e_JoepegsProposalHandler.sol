// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import {OrderTypes} from '../libraries/OrderTypes.sol';

/**
 * @title JoepegsProposalHandler
 * @notice Handles decoding of proposals for Joepegs Marketplace
 */
contract JoepegsProposalHandler {
	/// ----------------------------------------------------------------------------------------
	///							ExecutionManager Storage
	/// ----------------------------------------------------------------------------------------

	error InvalidFunction();

	/// Mappings to decide which funcitons are free/comission
	/// bytes4 key is the function signature
	mapping(bytes4 => uint256) public comissionFreeFunctions;
	mapping(bytes4 => uint256) public comissionBasedFunctions;

	uint256 public immutable PROTOCOL_FEE;

	/// ----------------------------------------------------------------------------------------
	///							Constructor
	/// ----------------------------------------------------------------------------------------

	/**
	 * @notice Constructor
	 * @param _protocolFee protocol fee (200 --> 2%, 400 --> 4%)
	 */
	constructor(
		uint256 _protocolFee,
		bytes4[] memory _comissionFreeFunctions,
		bytes4[] memory _comissionBasedFunctions
	) {
		PROTOCOL_FEE = _protocolFee;

		// Set the functions that are enabled -> 1 for enabled
		for (uint256 i; i < _comissionFreeFunctions.length; i++) {
			comissionFreeFunctions[_comissionFreeFunctions[i]] = 1;
		}

		for (uint256 i; i < _comissionBasedFunctions.length; i++) {
			comissionBasedFunctions[_comissionBasedFunctions[i]] = 1;
		}
	}

	/// ----------------------------------------------------------------------------------------
	///							Public Interface
	/// ----------------------------------------------------------------------------------------

	/**
	 * @notice Decides comission to charge based on the function being called.
	 *     		 Since all on-chain joe functions decode a TakerOrder, we can do
	 *     		 everything in handleProposal.
	 * @param value not used in this contract, keeps interface consistent with other handlers
	 * @return payload to decode and extract comission info from
	 */
	function handleProposal(uint256 value, bytes calldata payload) external view returns (uint256) {
		// Extract function sig from payload as the first 4 bytes
		bytes4 functionSig = bytes4(payload[0:4]);

		// If comissoin free retun 0
		if (comissionFreeFunctions[functionSig] == 1) return 0;

		// If comission based, calculate the comission
		if (comissionBasedFunctions[functionSig] == 1) {
			OrderTypes.TakerOrder memory TakerOrder = abi.decode(payload[4:], (OrderTypes.TakerOrder));

			// Return commission fee based of PROTOCOL_FEE and 10000 basis points
			return (TakerOrder.price * PROTOCOL_FEE) / 10000;
		}

		// If function is not listed, revert
		revert InvalidFunction();
	}

	/**
	 * @notice Return protocol fee for this proposal handler
	 * @return protocol fee
	 */
	function viewProtocolFee() external view returns (uint256) {
		return PROTOCOL_FEE;
	}
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
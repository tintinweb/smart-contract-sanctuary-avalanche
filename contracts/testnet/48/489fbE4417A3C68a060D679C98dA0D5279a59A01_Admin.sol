//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import "./CERC1155.sol";

/*
 * @author Mozverse
 * @notice Admin Contract
 */
contract Admin {
	CERC1155[] public cERC1155Array; //keeps track of minted erc1155 collections

	address admin;

	modifier onlyAdmin() {
		require(msg.sender == admin, "not admin");
		_;
	}

	constructor() {
		admin = msg.sender;
	}

	//* @dev creates a new custom erc1155 contract
	//@param name of the collection
	//@param symbol of the collection
	//@param baseURL the base URL of new collection
	function CreateNewCERC1155(
		string memory name,
		string memory symbol,
		string memory baseURL
	) public onlyAdmin {
		CERC1155 collection = new CERC1155(name, symbol, baseURL);
		cERC1155Array.push(collection);
	}

	//* @dev gets the collection @ index. not needed
	//@param index - index of the collection
	function getCollectionAtIndex(uint256 index) public view returns (address) {
		return address(cERC1155Array[index]);
	}

	//if contract is paused, transfers & mints are not possible
	function setPaused(address collection, bool isPaused) public onlyAdmin {
		if (isPaused) {
			CERC1155(collection).pause();
		} else {
			CERC1155(collection).unpause();
		}
	}

	//sets a new admin for a collection
	function setAdmin(address collection, address newAdmin) public onlyAdmin {
		CERC1155(collection).setAdmin(newAdmin);
	}

	//change a collection base URI
	function setBaseURI(address collection, string memory newBaseURI) public onlyAdmin {
		CERC1155(collection).setBaseURI(newBaseURI);
	}

	//change ownership of a token
	function chown(
		address collection,
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts
	) public onlyAdmin {
		require(ids.length == amounts.length, "arrays length not matching");
		CERC1155(collection).chown(from, to, ids, amounts);
	}

	//mint an NFT
	function mint(
		address collection,
		uint256 _tokenId,
		uint256 _qty,
		address _toAddress
	) public onlyAdmin {
		CERC1155(collection).mintNFT(_tokenId, _qty, _toAddress);
	}

	//change the admin for the Admin contract!
	function setCurrentAdmin(address newAdmin) public onlyAdmin {
		admin = newAdmin;
	}

	//internal version function
	function version() internal pure returns (uint256) {
		return 1;
	}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

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

abstract contract ERC165 is IERC165 {
	/**
	 * @dev See {IERC165-supportsInterface}.
	 */
	function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
		return interfaceId == type(IERC165).interfaceId;
	}
}

interface IERC1155 is IERC165 {
	/**
	 * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
	 */
	event TransferSingle(
		address indexed operator,
		address indexed from,
		address indexed to,
		uint256 id,
		uint256 value
	);

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
	function balanceOfBatch(
		address[] calldata accounts,
		uint256[] calldata ids
	) external view returns (uint256[] memory);

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
	 * WARNING: This function can potentially allow a reentrancy attack when transferring tokens
	 * to an untrusted contract, when invoking {onERC1155Received} on the receiver.
	 * Ensure to follow the checks-effects-interactions pattern and consider employing
	 * reentrancy guards when interacting with untrusted contracts.
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
	 *
	 * WARNING: This function can potentially allow a reentrancy attack when transferring tokens
	 * to an untrusted contract, when invoking {onERC1155BatchReceived} on the receiver.
	 * Ensure to follow the checks-effects-interactions pattern and consider employing
	 * reentrancy guards when interacting with untrusted contracts.
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

interface IERC1155Receiver is IERC165 {
	/**
	 * @dev Handles the receipt of a single ERC1155 token type. This function is
	 * called at the end of a `safeTransferFrom` after the balance has been updated.
	 *
	 * NOTE: To accept the transfer, this must return
	 * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
	 * (i.e. 0xf23a6e61, or its own function selector).
	 *
	 * @param operator The address which initiated the transfer (i.e. msg.sender)
	 * @param from The address which previously owned the token
	 * @param id The ID of the token being transferred
	 * @param value The amount of tokens being transferred
	 * @param data Additional data with no specified format
	 * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
	 */
	function onERC1155Received(
		address operator,
		address from,
		uint256 id,
		uint256 value,
		bytes calldata data
	) external returns (bytes4);

	/**
	 * @dev Handles the receipt of a multiple ERC1155 token types. This function
	 * is called at the end of a `safeBatchTransferFrom` after the balances have
	 * been updated.
	 *
	 * NOTE: To accept the transfer(s), this must return
	 * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
	 * (i.e. 0xbc197c81, or its own function selector).
	 *
	 * @param operator The address which initiated the batch transfer (i.e. msg.sender)
	 * @param from The address which previously owned the token
	 * @param ids An array containing ids of each token being transferred (order and length must match values array)
	 * @param values An array containing amounts of each token being transferred (order and length must match ids array)
	 * @param data Additional data with no specified format
	 * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
	 */
	function onERC1155BatchReceived(
		address operator,
		address from,
		uint256[] calldata ids,
		uint256[] calldata values,
		bytes calldata data
	) external returns (bytes4);
}

interface IERC1155MetadataURI is IERC1155 {
	/**
	 * @dev Returns the URI for token type `id`.
	 *
	 * If the `\{id\}` substring is present in the URI, it must be replaced by
	 * clients with the actual token type ID.
	 */
	function uri(uint256 id) external view returns (string memory);
}

/**
 * @dev Standard ERC20 Errors
 * Interface of the ERC6093 custom errors for ERC20 tokens
 * as defined in https://eips.ethereum.org/EIPS/eip-6093
 */
interface IERC20Errors {
	/**
	 * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
	 * @param sender Address whose tokens are being transferred.
	 * @param balance Current balance for the interacting account.
	 * @param needed Minimum amount required to perform a transfer.
	 */
	error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

	/**
	 * @dev Indicates a failure with the token `sender`. Used in transfers.
	 * @param sender Address whose tokens are being transferred.
	 */
	error ERC20InvalidSender(address sender);

	/**
	 * @dev Indicates a failure with the token `receiver`. Used in transfers.
	 * @param receiver Address to which tokens are being transferred.
	 */
	error ERC20InvalidReceiver(address receiver);

	/**
	 * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
	 * @param spender Address that may be allowed to operate on tokens without being their owner.
	 * @param allowance Amount of tokens a `spender` is allowed to operate with.
	 * @param needed Minimum amount required to perform a transfer.
	 */
	error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

	/**
	 * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
	 * @param approver Address initiating an approval operation.
	 */
	error ERC20InvalidApprover(address approver);

	/**
	 * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
	 * @param spender Address that may be allowed to operate on tokens without being their owner.
	 */
	error ERC20InvalidSpender(address spender);
}

/**
 * @dev Standard ERC721 Errors
 * Interface of the ERC6093 custom errors for ERC721 tokens
 * as defined in https://eips.ethereum.org/EIPS/eip-6093
 */
interface IERC721Errors {
	/**
	 * @dev Indicates that an address can't be an owner. For example, `address(0)` is a forbidden owner in EIP-20.
	 * Used in balance queries.
	 * @param owner Address of the current owner of a token.
	 */
	error ERC721InvalidOwner(address owner);

	/**
	 * @dev Indicates a `tokenId` whose `owner` is the zero address.
	 * @param tokenId Identifier number of a token.
	 */
	error ERC721NonexistentToken(uint256 tokenId);

	/**
	 * @dev Indicates an error related to the ownership over a particular token. Used in transfers.
	 * @param sender Address whose tokens are being transferred.
	 * @param tokenId Identifier number of a token.
	 * @param owner Address of the current owner of a token.
	 */
	error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);

	/**
	 * @dev Indicates a failure with the token `sender`. Used in transfers.
	 * @param sender Address whose tokens are being transferred.
	 */
	error ERC721InvalidSender(address sender);

	/**
	 * @dev Indicates a failure with the token `receiver`. Used in transfers.
	 * @param receiver Address to which tokens are being transferred.
	 */
	error ERC721InvalidReceiver(address receiver);

	/**
	 * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
	 * @param operator Address that may be allowed to operate on tokens without being their owner.
	 * @param tokenId Identifier number of a token.
	 */
	error ERC721InsufficientApproval(address operator, uint256 tokenId);

	/**
	 * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
	 * @param approver Address initiating an approval operation.
	 */
	error ERC721InvalidApprover(address approver);

	/**
	 * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
	 * @param operator Address that may be allowed to operate on tokens without being their owner.
	 */
	error ERC721InvalidOperator(address operator);
}

/**
 * @dev Standard ERC1155 Errors
 * Interface of the ERC6093 custom errors for ERC1155 tokens
 * as defined in https://eips.ethereum.org/EIPS/eip-6093
 */
interface IERC1155Errors {
	/**
	 * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
	 * @param sender Address whose tokens are being transferred.
	 * @param balance Current balance for the interacting account.
	 * @param needed Minimum amount required to perform a transfer.
	 */
	error ERC1155InsufficientBalance(
		address sender,
		uint256 balance,
		uint256 needed,
		uint256 tokenId
	);

	/**
	 * @dev Indicates a failure with the token `sender`. Used in transfers.
	 * @param sender Address whose tokens are being transferred.
	 */
	error ERC1155InvalidSender(address sender);

	/**
	 * @dev Indicates a failure with the token `receiver`. Used in transfers.
	 * @param receiver Address to which tokens are being transferred.
	 */
	error ERC1155InvalidReceiver(address receiver);

	/**
	 * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
	 * @param operator Address that may be allowed to operate on tokens without being their owner.
	 * @param owner Address of the current owner of a token.
	 */
	error ERC1155InsufficientApprovalForAll(address operator, address owner);

	/**
	 * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
	 * @param approver Address initiating an approval operation.
	 */
	error ERC1155InvalidApprover(address approver);

	/**
	 * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
	 * @param operator Address that may be allowed to operate on tokens without being their owner.
	 */
	error ERC1155InvalidOperator(address operator);

	/**
	 * @dev Indicates an array length mismatch between ids and values in a safeBatchTransferFrom operation.
	 * Used in batch transfers.
	 * @param idsLength Length of the array of token identifiers
	 * @param valuesLength Length of the array of token amounts
	 */
	error ERC1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength);
}

abstract contract Context {
	function _msgSender() internal view virtual returns (address) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns (bytes calldata) {
		return msg.data;
	}
}

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
	bool private _paused;

	/**
	 * @dev Emitted when the pause is triggered by `account`.
	 */
	event Paused(address account);

	/**
	 * @dev Emitted when the pause is lifted by `account`.
	 */
	event Unpaused(address account);

	/**
	 * @dev The operation failed because the contract is paused.
	 */
	error EnforcedPause();

	/**
	 * @dev The operation failed because the contract is not paused.
	 */
	error ExpectedPause();

	/**
	 * @dev Initializes the contract in unpaused state.
	 */
	constructor() {
		_paused = false;
	}

	/**
	 * @dev Modifier to make a function callable only when the contract is not paused.
	 *
	 * Requirements:
	 *
	 * - The contract must not be paused.
	 */
	modifier whenNotPaused() {
		_requireNotPaused();
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
		_requirePaused();
		_;
	}

	/**
	 * @dev Returns true if the contract is paused, and false otherwise.
	 */
	function paused() public view virtual returns (bool) {
		return _paused;
	}

	/**
	 * @dev Throws if the contract is paused.
	 */
	function _requireNotPaused() internal view virtual {
		if (paused()) {
			revert EnforcedPause();
		}
	}

	/**
	 * @dev Throws if the contract is not paused.
	 */
	function _requirePaused() internal view virtual {
		if (!paused()) {
			revert ExpectedPause();
		}
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

/**
 * @dev Collection of functions related to the address type
 */
library Address {
	/**
	 * @dev Returns true if `account` is a contract.
	 *
	 * [IMPORTANT]
	 * ====
	 * It is unsafe to assume that an address for which this function returns
	 * false is an externally-owned account (EOA) and not a contract.
	 *
	 * Among others, `isContract` will return false for the following
	 * types of addresses:
	 *
	 *  - an externally-owned account
	 *  - a contract in construction
	 *  - an address where a contract will be created
	 *  - an address where a contract lived, but was destroyed
	 *
	 * Furthermore, `isContract` will also return true if the target contract within
	 * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
	 * which only has an effect at the end of a transaction.
	 * ====
	 *
	 * [IMPORTANT]
	 * ====
	 * You shouldn't rely on `isContract` to protect against flash loan attacks!
	 *
	 * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
	 * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
	 * constructor.
	 * ====
	 */
	function isContract(address account) internal view returns (bool) {
		// This method relies on extcodesize/address.code.length, which returns 0
		// for contracts in construction, since the code is only stored at the end
		// of the constructor execution.

		return account.code.length > 0;
	}

	/**
	 * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
	 * `recipient`, forwarding all available gas and reverting on errors.
	 *
	 * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
	 * of certain opcodes, possibly making contracts go over the 2300 gas limit
	 * imposed by `transfer`, making them unable to receive funds via
	 * `transfer`. {sendValue} removes this limitation.
	 *
	 * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
	 *
	 * IMPORTANT: because control is transferred to `recipient`, care must be
	 * taken to not create reentrancy vulnerabilities. Consider using
	 * {ReentrancyGuard} or the
	 * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
	 */
	function sendValue(address payable recipient, uint256 amount) internal {
		require(address(this).balance >= amount, "Address: insufficient balance");

		(bool success, ) = recipient.call{ value: amount }("");
		require(success, "Address: unable to send value, recipient may have reverted");
	}

	/**
	 * @dev Performs a Solidity function call using a low level `call`. A
	 * plain `call` is an unsafe replacement for a function call: use this
	 * function instead.
	 *
	 * If `target` reverts with a revert reason, it is bubbled up by this
	 * function (like regular Solidity function calls).
	 *
	 * Returns the raw returned data. To convert to the expected return value,
	 * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
	 *
	 * Requirements:
	 *
	 * - `target` must be a contract.
	 * - calling `target` with `data` must not revert.
	 *
	 * _Available since v3.1._
	 */
	function functionCall(address target, bytes memory data) internal returns (bytes memory) {
		return functionCallWithValue(target, data, 0, "Address: low-level call failed");
	}

	/**
	 * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
	 * `errorMessage` as a fallback revert reason when `target` reverts.
	 *
	 * _Available since v3.1._
	 */
	function functionCall(
		address target,
		bytes memory data,
		string memory errorMessage
	) internal returns (bytes memory) {
		return functionCallWithValue(target, data, 0, errorMessage);
	}

	/**
	 * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
	 * but also transferring `value` wei to `target`.
	 *
	 * Requirements:
	 *
	 * - the calling contract must have an ETH balance of at least `value`.
	 * - the called Solidity function must be `payable`.
	 *
	 * _Available since v3.1._
	 */
	function functionCallWithValue(
		address target,
		bytes memory data,
		uint256 value
	) internal returns (bytes memory) {
		return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
	}

	/**
	 * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
	 * with `errorMessage` as a fallback revert reason when `target` reverts.
	 *
	 * _Available since v3.1._
	 */
	function functionCallWithValue(
		address target,
		bytes memory data,
		uint256 value,
		string memory errorMessage
	) internal returns (bytes memory) {
		require(address(this).balance >= value, "Address: insufficient balance for call");
		(bool success, bytes memory returndata) = target.call{ value: value }(data);
		return verifyCallResultFromTarget(target, success, returndata, errorMessage);
	}

	/**
	 * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
	 * but performing a static call.
	 *
	 * _Available since v3.3._
	 */
	function functionStaticCall(
		address target,
		bytes memory data
	) internal view returns (bytes memory) {
		return functionStaticCall(target, data, "Address: low-level static call failed");
	}

	/**
	 * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
	 * but performing a static call.
	 *
	 * _Available since v3.3._
	 */
	function functionStaticCall(
		address target,
		bytes memory data,
		string memory errorMessage
	) internal view returns (bytes memory) {
		(bool success, bytes memory returndata) = target.staticcall(data);
		return verifyCallResultFromTarget(target, success, returndata, errorMessage);
	}

	/**
	 * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
	 * but performing a delegate call.
	 *
	 * _Available since v3.4._
	 */
	function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
		return functionDelegateCall(target, data, "Address: low-level delegate call failed");
	}

	/**
	 * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
	 * but performing a delegate call.
	 *
	 * _Available since v3.4._
	 */
	function functionDelegateCall(
		address target,
		bytes memory data,
		string memory errorMessage
	) internal returns (bytes memory) {
		(bool success, bytes memory returndata) = target.delegatecall(data);
		return verifyCallResultFromTarget(target, success, returndata, errorMessage);
	}

	/**
	 * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
	 * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
	 *
	 * _Available since v4.8._
	 */
	function verifyCallResultFromTarget(
		address target,
		bool success,
		bytes memory returndata,
		string memory errorMessage
	) internal view returns (bytes memory) {
		if (success) {
			if (returndata.length == 0) {
				// only check isContract if the call was successful and the return data is empty
				// otherwise we already know that it was a contract
				require(isContract(target), "Address: call to non-contract");
			}
			return returndata;
		} else {
			_revert(returndata, errorMessage);
		}
	}

	/**
	 * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
	 * revert reason or using the provided one.
	 *
	 * _Available since v4.3._
	 */
	function verifyCallResult(
		bool success,
		bytes memory returndata,
		string memory errorMessage
	) internal pure returns (bytes memory) {
		if (success) {
			return returndata;
		} else {
			_revert(returndata, errorMessage);
		}
	}

	function _revert(bytes memory returndata, string memory errorMessage) private pure {
		// Look for revert reason and bubble it up if present
		if (returndata.length > 0) {
			// The easiest way to bubble the revert reason is using memory via assembly
			/// @solidity memory-safe-assembly
			assembly {
				let returndata_size := mload(returndata)
				revert(add(32, returndata), returndata_size)
			}
		} else {
			revert(errorMessage);
		}
	}
}

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
	/**
	 * @dev Muldiv operation overflow.
	 */
	error MathOverflowedMulDiv();

	enum Rounding {
		Down, // Toward negative infinity
		Up, // Toward infinity
		Zero // Toward zero
	}

	/**
	 * @dev Returns the addition of two unsigned integers, with an overflow flag.
	 *
	 * _Available since v5.0._
	 */
	function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
		unchecked {
			uint256 c = a + b;
			if (c < a) return (false, 0);
			return (true, c);
		}
	}

	/**
	 * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
	 *
	 * _Available since v5.0._
	 */
	function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
		unchecked {
			if (b > a) return (false, 0);
			return (true, a - b);
		}
	}

	/**
	 * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
	 *
	 * _Available since v5.0._
	 */
	function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
		unchecked {
			// Gas optimization: this is cheaper than requiring 'a' not being zero, but the
			// benefit is lost if 'b' is also tested.
			// See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
			if (a == 0) return (true, 0);
			uint256 c = a * b;
			if (c / a != b) return (false, 0);
			return (true, c);
		}
	}

	/**
	 * @dev Returns the division of two unsigned integers, with a division by zero flag.
	 *
	 * _Available since v5.0._
	 */
	function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
		unchecked {
			if (b == 0) return (false, 0);
			return (true, a / b);
		}
	}

	/**
	 * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
	 *
	 * _Available since v5.0._
	 */
	function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
		unchecked {
			if (b == 0) return (false, 0);
			return (true, a % b);
		}
	}

	/**
	 * @dev Returns the largest of two numbers.
	 */
	function max(uint256 a, uint256 b) internal pure returns (uint256) {
		return a > b ? a : b;
	}

	/**
	 * @dev Returns the smallest of two numbers.
	 */
	function min(uint256 a, uint256 b) internal pure returns (uint256) {
		return a < b ? a : b;
	}

	/**
	 * @dev Returns the average of two numbers. The result is rounded towards
	 * zero.
	 */
	function average(uint256 a, uint256 b) internal pure returns (uint256) {
		// (a + b) / 2 can overflow.
		return (a & b) + (a ^ b) / 2;
	}

	/**
	 * @dev Returns the ceiling of the division of two numbers.
	 *
	 * This differs from standard division with `/` in that it rounds up instead
	 * of rounding down.
	 */
	function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
		if (b == 0) {
			// Guarantee the same behavior as in a regular Solidity division.
			return a / b;
		}

		// (a + b - 1) / b can overflow on addition, so we distribute.
		return a == 0 ? 0 : (a - 1) / b + 1;
	}

	/**
	 * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
	 * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
	 * with further edits by Uniswap Labs also under MIT license.
	 */
	function mulDiv(
		uint256 x,
		uint256 y,
		uint256 denominator
	) internal pure returns (uint256 result) {
		unchecked {
			// 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
			// use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
			// variables such that product = prod1 * 2^256 + prod0.
			uint256 prod0; // Least significant 256 bits of the product
			uint256 prod1; // Most significant 256 bits of the product
			assembly {
				let mm := mulmod(x, y, not(0))
				prod0 := mul(x, y)
				prod1 := sub(sub(mm, prod0), lt(mm, prod0))
			}

			// Handle non-overflow cases, 256 by 256 division.
			if (prod1 == 0) {
				// Solidity will revert if denominator == 0, unlike the div opcode on its own.
				// The surrounding unchecked block does not change this fact.
				// See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
				return prod0 / denominator;
			}

			// Make sure the result is less than 2^256. Also prevents denominator == 0.
			if (denominator <= prod1) {
				revert MathOverflowedMulDiv();
			}

			///////////////////////////////////////////////
			// 512 by 256 division.
			///////////////////////////////////////////////

			// Make division exact by subtracting the remainder from [prod1 prod0].
			uint256 remainder;
			assembly {
				// Compute remainder using mulmod.
				remainder := mulmod(x, y, denominator)

				// Subtract 256 bit number from 512 bit number.
				prod1 := sub(prod1, gt(remainder, prod0))
				prod0 := sub(prod0, remainder)
			}

			// Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
			// See https://cs.stackexchange.com/q/138556/92363.

			// Does not overflow because the denominator cannot be zero at this stage in the function.
			uint256 twos = denominator & (~denominator + 1);
			assembly {
				// Divide denominator by twos.
				denominator := div(denominator, twos)

				// Divide [prod1 prod0] by twos.
				prod0 := div(prod0, twos)

				// Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
				twos := add(div(sub(0, twos), twos), 1)
			}

			// Shift in bits from prod1 into prod0.
			prod0 |= prod1 * twos;

			// Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
			// that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
			// four bits. That is, denominator * inv = 1 mod 2^4.
			uint256 inverse = (3 * denominator) ^ 2;

			// Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
			// in modular arithmetic, doubling the correct bits in each step.
			inverse *= 2 - denominator * inverse; // inverse mod 2^8
			inverse *= 2 - denominator * inverse; // inverse mod 2^16
			inverse *= 2 - denominator * inverse; // inverse mod 2^32
			inverse *= 2 - denominator * inverse; // inverse mod 2^64
			inverse *= 2 - denominator * inverse; // inverse mod 2^128
			inverse *= 2 - denominator * inverse; // inverse mod 2^256

			// Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
			// This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
			// less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
			// is no longer required.
			result = prod0 * inverse;
			return result;
		}
	}

	/**
	 * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
	 */
	function mulDiv(
		uint256 x,
		uint256 y,
		uint256 denominator,
		Rounding rounding
	) internal pure returns (uint256) {
		uint256 result = mulDiv(x, y, denominator);
		if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
			result += 1;
		}
		return result;
	}

	/**
	 * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
	 *
	 * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
	 */
	function sqrt(uint256 a) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		}

		// For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
		//
		// We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
		// `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
		//
		// This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
		// → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
		// → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
		//
		// Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
		uint256 result = 1 << (log2(a) >> 1);

		// At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
		// since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
		// every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
		// into the expected uint128 result.
		unchecked {
			result = (result + a / result) >> 1;
			result = (result + a / result) >> 1;
			result = (result + a / result) >> 1;
			result = (result + a / result) >> 1;
			result = (result + a / result) >> 1;
			result = (result + a / result) >> 1;
			result = (result + a / result) >> 1;
			return min(result, a / result);
		}
	}

	/**
	 * @notice Calculates sqrt(a), following the selected rounding direction.
	 */
	function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
		unchecked {
			uint256 result = sqrt(a);
			return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
		}
	}

	/**
	 * @dev Return the log in base 2, rounded down, of a positive value.
	 * Returns 0 if given 0.
	 */
	function log2(uint256 value) internal pure returns (uint256) {
		uint256 result = 0;
		unchecked {
			if (value >> 128 > 0) {
				value >>= 128;
				result += 128;
			}
			if (value >> 64 > 0) {
				value >>= 64;
				result += 64;
			}
			if (value >> 32 > 0) {
				value >>= 32;
				result += 32;
			}
			if (value >> 16 > 0) {
				value >>= 16;
				result += 16;
			}
			if (value >> 8 > 0) {
				value >>= 8;
				result += 8;
			}
			if (value >> 4 > 0) {
				value >>= 4;
				result += 4;
			}
			if (value >> 2 > 0) {
				value >>= 2;
				result += 2;
			}
			if (value >> 1 > 0) {
				result += 1;
			}
		}
		return result;
	}

	/**
	 * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
	 * Returns 0 if given 0.
	 */
	function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
		unchecked {
			uint256 result = log2(value);
			return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
		}
	}

	/**
	 * @dev Return the log in base 10, rounded down, of a positive value.
	 * Returns 0 if given 0.
	 */
	function log10(uint256 value) internal pure returns (uint256) {
		uint256 result = 0;
		unchecked {
			if (value >= 10 ** 64) {
				value /= 10 ** 64;
				result += 64;
			}
			if (value >= 10 ** 32) {
				value /= 10 ** 32;
				result += 32;
			}
			if (value >= 10 ** 16) {
				value /= 10 ** 16;
				result += 16;
			}
			if (value >= 10 ** 8) {
				value /= 10 ** 8;
				result += 8;
			}
			if (value >= 10 ** 4) {
				value /= 10 ** 4;
				result += 4;
			}
			if (value >= 10 ** 2) {
				value /= 10 ** 2;
				result += 2;
			}
			if (value >= 10 ** 1) {
				result += 1;
			}
		}
		return result;
	}

	/**
	 * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
	 * Returns 0 if given 0.
	 */
	function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
		unchecked {
			uint256 result = log10(value);
			return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
		}
	}

	/**
	 * @dev Return the log in base 256, rounded down, of a positive value.
	 * Returns 0 if given 0.
	 *
	 * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
	 */
	function log256(uint256 value) internal pure returns (uint256) {
		uint256 result = 0;
		unchecked {
			if (value >> 128 > 0) {
				value >>= 128;
				result += 16;
			}
			if (value >> 64 > 0) {
				value >>= 64;
				result += 8;
			}
			if (value >> 32 > 0) {
				value >>= 32;
				result += 4;
			}
			if (value >> 16 > 0) {
				value >>= 16;
				result += 2;
			}
			if (value >> 8 > 0) {
				result += 1;
			}
		}
		return result;
	}

	/**
	 * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
	 * Returns 0 if given 0.
	 */
	function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
		unchecked {
			uint256 result = log256(value);
			return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
		}
	}
}

/**
 * @dev String operations.
 */
library Strings {
	bytes16 private constant alphabet = "0123456789abcdef";

	/**
	 * @dev Converts a `uint256` to its ASCII `string` decimal representation.
	 */
	function toString(uint256 value) internal pure returns (string memory) {
		// Inspired by OraclizeAPI's implementation - MIT licence
		// https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

		if (value == 0) {
			return "0";
		}
		uint256 temp = value;
		uint256 digits;
		while (temp != 0) {
			digits++;
			temp /= 10;
		}
		bytes memory buffer = new bytes(digits);
		while (value != 0) {
			digits -= 1;
			buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
			value /= 10;
		}
		return string(buffer);
	}

	/**
	 * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
	 */
	function toHexString(uint256 value) internal pure returns (string memory) {
		if (value == 0) {
			return "0x00";
		}
		uint256 temp = value;
		uint256 length = 0;
		while (temp != 0) {
			length++;
			temp >>= 8;
		}
		return toHexString(value, length);
	}

	/**
	 * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
	 */
	function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
		bytes memory buffer = new bytes(2 * length + 2);
		buffer[0] = "0";
		buffer[1] = "x";
		for (uint256 i = 2 * length + 1; i > 1; --i) {
			buffer[i] = alphabet[value & 0xf];
			value >>= 4;
		}
		require(value == 0, "Strings: hex length insufficient");
		return string(buffer);
	}
}

library StorageSlot {
	struct AddressSlot {
		address value;
	}

	struct BooleanSlot {
		bool value;
	}

	struct Bytes32Slot {
		bytes32 value;
	}

	struct Uint256Slot {
		uint256 value;
	}

	struct StringSlot {
		string value;
	}

	struct BytesSlot {
		bytes value;
	}

	/**
	 * @dev Returns an `AddressSlot` with member `value` located at `slot`.
	 */
	function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
		/// @solidity memory-safe-assembly
		assembly {
			r.slot := slot
		}
	}

	/**
	 * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
	 */
	function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
		/// @solidity memory-safe-assembly
		assembly {
			r.slot := slot
		}
	}

	/**
	 * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
	 */
	function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
		/// @solidity memory-safe-assembly
		assembly {
			r.slot := slot
		}
	}

	/**
	 * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
	 */
	function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
		/// @solidity memory-safe-assembly
		assembly {
			r.slot := slot
		}
	}

	/**
	 * @dev Returns an `StringSlot` with member `value` located at `slot`.
	 */
	function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
		/// @solidity memory-safe-assembly
		assembly {
			r.slot := slot
		}
	}

	/**
	 * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
	 */
	function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
		/// @solidity memory-safe-assembly
		assembly {
			r.slot := store.slot
		}
	}

	/**
	 * @dev Returns an `BytesSlot` with member `value` located at `slot`.
	 */
	function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
		/// @solidity memory-safe-assembly
		assembly {
			r.slot := slot
		}
	}

	/**
	 * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
	 */
	function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
		/// @solidity memory-safe-assembly
		assembly {
			r.slot := store.slot
		}
	}
}

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
	using StorageSlot for bytes32;

	/**
	 * @dev Searches a sorted `array` and returns the first index that contains
	 * a value greater or equal to `element`. If no such index exists (i.e. all
	 * values in the array are strictly less than `element`), the array length is
	 * returned. Time complexity O(log n).
	 *
	 * `array` is expected to be sorted in ascending order, and to contain no
	 * repeated elements.
	 */
	function findUpperBound(
		uint256[] storage array,
		uint256 element
	) internal view returns (uint256) {
		if (array.length == 0) {
			return 0;
		}

		uint256 low = 0;
		uint256 high = array.length;

		while (low < high) {
			uint256 mid = Math.average(low, high);

			// Note that mid will always be strictly less than high (i.e. it will be a valid array index)
			// because Math.average rounds down (it does integer division with truncation).
			if (unsafeAccess(array, mid).value > element) {
				high = mid;
			} else {
				low = mid + 1;
			}
		}

		// At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
		if (low > 0 && unsafeAccess(array, low - 1).value == element) {
			return low - 1;
		} else {
			return low;
		}
	}

	/**
	 * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
	 *
	 * WARNING: Only use if you are certain `pos` is lower than the array length.
	 */
	function unsafeAccess(
		address[] storage arr,
		uint256 pos
	) internal pure returns (StorageSlot.AddressSlot storage) {
		bytes32 slot;
		// We use assembly to calculate the storage slot of the element at index `pos` of the dynamic array `arr`
		// following https://docs.soliditylang.org/en/v0.8.17/internals/layout_in_storage.html#mappings-and-dynamic-arrays.

		/// @solidity memory-safe-assembly
		assembly {
			mstore(0, arr.slot)
			slot := add(keccak256(0, 0x20), pos)
		}
		return slot.getAddressSlot();
	}

	/**
	 * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
	 *
	 * WARNING: Only use if you are certain `pos` is lower than the array length.
	 */
	function unsafeAccess(
		bytes32[] storage arr,
		uint256 pos
	) internal pure returns (StorageSlot.Bytes32Slot storage) {
		bytes32 slot;
		// We use assembly to calculate the storage slot of the element at index `pos` of the dynamic array `arr`
		// following https://docs.soliditylang.org/en/v0.8.17/internals/layout_in_storage.html#mappings-and-dynamic-arrays.

		/// @solidity memory-safe-assembly
		assembly {
			mstore(0, arr.slot)
			slot := add(keccak256(0, 0x20), pos)
		}
		return slot.getBytes32Slot();
	}

	/**
	 * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
	 *
	 * WARNING: Only use if you are certain `pos` is lower than the array length.
	 */
	function unsafeAccess(
		uint256[] storage arr,
		uint256 pos
	) internal pure returns (StorageSlot.Uint256Slot storage) {
		bytes32 slot;
		// We use assembly to calculate the storage slot of the element at index `pos` of the dynamic array `arr`
		// following https://docs.soliditylang.org/en/v0.8.17/internals/layout_in_storage.html#mappings-and-dynamic-arrays.

		/// @solidity memory-safe-assembly
		assembly {
			mstore(0, arr.slot)
			slot := add(keccak256(0, 0x20), pos)
		}
		return slot.getUint256Slot();
	}

	/**
	 * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
	 *
	 * WARNING: Only use if you are certain `pos` is lower than the array length.
	 */
	function unsafeMemoryAccess(
		uint256[] memory arr,
		uint256 pos
	) internal pure returns (uint256 res) {
		assembly {
			res := mload(add(add(arr, 0x20), mul(pos, 0x20)))
		}
	}

	/**
	 * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
	 *
	 * WARNING: Only use if you are certain `pos` is lower than the array length.
	 */
	function unsafeMemoryAccess(
		address[] memory arr,
		uint256 pos
	) internal pure returns (address res) {
		assembly {
			res := mload(add(add(arr, 0x20), mul(pos, 0x20)))
		}
	}
}

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
	using Address for address;

	error ERC1155InsufficientApprovalForAll(address operator, address owner);

	// Mapping from token ID to account balances
	mapping(uint256 => mapping(address => uint256)) private _balances;

	// Mapping from account to operator approvals
	mapping(address => mapping(address => bool)) private _operatorApprovals;

	// Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
	string private _uri;

	error ERC1155InsufficientBalance(
		address sender,
		uint256 balance,
		uint256 needed,
		uint256 tokenId
	);

	/**
	 * @dev See {_setURI}.
	 */
	constructor(string memory uri_) {
		_setURI(uri_);
	}

	/**
	 * @dev admin can change ownership of a token
	 * @param from - old owner
	 * @param to - new owner
	 * @param ids tokenIDs
	 * @param amounts amounts
	 */
	function adminChown(
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts
	) internal {
		//ownership check is removed
		_safeBatchTransferFrom(from, to, ids, amounts, "");
	}

	/**
	 * @dev See {IERC165-supportsInterface}.
	 */
	function supportsInterface(
		bytes4 interfaceId
	) public view virtual override(ERC165, IERC165) returns (bool) {
		return
			interfaceId == type(IERC1155).interfaceId ||
			interfaceId == type(IERC1155MetadataURI).interfaceId ||
			super.supportsInterface(interfaceId);
	}

	/**
	 * @dev See {IERC1155MetadataURI-uri}.
	 *
	 * This implementation returns the same URI for *all* token types. It relies
	 * on the token type ID substitution mechanism
	 * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
	 *
	 * Clients calling this function must replace the `\{id\}` substring with the
	 * actual token type ID.
	 */
	function uri(uint256) public view virtual override returns (string memory) {
		return _uri;
	}

	/**
	 * @dev See {IERC1155-balanceOf}.
	 *
	 * Requirements:
	 *
	 * - `account` cannot be the zero address.
	 */
	function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
		require(account != address(0), "ERC1155: address zero is not a valid owner");
		return _balances[id][account];
	}

	/**
	 * @dev See {IERC1155-balanceOfBatch}.
	 *
	 * Requirements:
	 *
	 * - `accounts` and `ids` must have the same length.
	 */
	function balanceOfBatch(
		address[] memory accounts,
		uint256[] memory ids
	) public view virtual override returns (uint256[] memory) {
		require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

		uint256[] memory batchBalances = new uint256[](accounts.length);

		for (uint256 i = 0; i < accounts.length; ++i) {
			batchBalances[i] = balanceOf(accounts[i], ids[i]);
		}

		return batchBalances;
	}

	/**
	 * @dev See {IERC1155-setApprovalForAll}.
	 */
	function setApprovalForAll(address operator, bool approved) public virtual override {
		_setApprovalForAll(_msgSender(), operator, approved);
	}

	/**
	 * @dev See {IERC1155-isApprovedForAll}.
	 */
	function isApprovedForAll(
		address account,
		address operator
	) public view virtual override returns (bool) {
		return _operatorApprovals[account][operator];
	}

	/**
	 * @dev See {IERC1155-safeTransferFrom}.
	 */
	function safeTransferFrom(
		address from,
		address to,
		uint256 id,
		uint256 amount,
		bytes memory data
	) public virtual override {
		require(
			from == _msgSender() || isApprovedForAll(from, _msgSender()),
			"ERC1155: caller is not token owner or approved"
		);
		_safeTransferFrom(from, to, id, amount, data);
	}

	/**
	 * @dev See {IERC1155-safeBatchTransferFrom}.
	 */
	function safeBatchTransferFrom(
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) public virtual override {
		require(
			from == _msgSender() || isApprovedForAll(from, _msgSender()),
			"ERC1155: caller is not token owner or approved"
		);
		_safeBatchTransferFrom(from, to, ids, amounts, data);
	}

	/**
	 * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
	 *
	 * Emits a {TransferSingle} event.
	 *
	 * Requirements:
	 *
	 * - `to` cannot be the zero address.
	 * - `from` must have a balance of tokens of type `id` of at least `amount`.
	 * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
	 * acceptance magic value.
	 */
	function _safeTransferFrom(
		address from,
		address to,
		uint256 id,
		uint256 amount,
		bytes memory data
	) internal virtual {
		require(to != address(0), "ERC1155: transfer to the zero address");

		address operator = _msgSender();
		uint256[] memory ids = _asSingletonArray(id);
		uint256[] memory amounts = _asSingletonArray(amount);

		_beforeTokenTransfer(operator, from, to, ids, amounts, data);

		uint256 fromBalance = _balances[id][from];
		require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
		unchecked {
			_balances[id][from] = fromBalance - amount;
		}
		_balances[id][to] += amount;

		emit TransferSingle(operator, from, to, id, amount);

		_afterTokenTransfer(operator, from, to, ids, amounts, data);

		_doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
	}

	/**
	 * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
	 *
	 * Emits a {TransferBatch} event.
	 *
	 * Requirements:
	 *
	 * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
	 * acceptance magic value.
	 */
	function _safeBatchTransferFrom(
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) internal virtual {
		require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
		require(to != address(0), "ERC1155: transfer to the zero address");

		address operator = _msgSender();

		_beforeTokenTransfer(operator, from, to, ids, amounts, data);

		for (uint256 i = 0; i < ids.length; ++i) {
			uint256 id = ids[i];
			uint256 amount = amounts[i];

			uint256 fromBalance = _balances[id][from];
			require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
			unchecked {
				_balances[id][from] = fromBalance - amount;
			}
			_balances[id][to] += amount;
		}

		emit TransferBatch(operator, from, to, ids, amounts);

		_afterTokenTransfer(operator, from, to, ids, amounts, data);

		_doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
	}

	/**
	 * @dev Sets a new URI for all token types, by relying on the token type ID
	 * substitution mechanism
	 * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
	 *
	 * By this mechanism, any occurrence of the `\{id\}` substring in either the
	 * URI or any of the amounts in the JSON file at said URI will be replaced by
	 * clients with the token type ID.
	 *
	 * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
	 * interpreted by clients as
	 * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
	 * for token type ID 0x4cce0.
	 *
	 * See {uri}.
	 *
	 * Because these URIs cannot be meaningfully represented by the {URI} event,
	 * this function emits no events.
	 */
	function _setURI(string memory newuri) internal virtual {
		_uri = newuri;
	}

	/**
	 * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
	 *
	 * Emits a {TransferSingle} event.
	 *
	 * Requirements:
	 *
	 * - `to` cannot be the zero address.
	 * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
	 * acceptance magic value.
	 */
	function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal virtual {
		require(to != address(0), "ERC1155: mint to the zero address");

		address operator = _msgSender();
		uint256[] memory ids = _asSingletonArray(id);
		uint256[] memory amounts = _asSingletonArray(amount);

		_beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

		_balances[id][to] += amount;
		emit TransferSingle(operator, address(0), to, id, amount);

		_afterTokenTransfer(operator, address(0), to, ids, amounts, data);

		_doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
	}

	/**
	 * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
	 *
	 * Emits a {TransferBatch} event.
	 *
	 * Requirements:
	 *
	 * - `ids` and `amounts` must have the same length.
	 * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
	 * acceptance magic value.
	 */
	function _mintBatch(
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) internal virtual {
		require(to != address(0), "ERC1155: mint to the zero address");
		require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

		address operator = _msgSender();

		_beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

		for (uint256 i = 0; i < ids.length; i++) {
			_balances[ids[i]][to] += amounts[i];
		}

		emit TransferBatch(operator, address(0), to, ids, amounts);

		_afterTokenTransfer(operator, address(0), to, ids, amounts, data);

		_doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
	}

	/**
	 * @dev Destroys `amount` tokens of token type `id` from `from`
	 *
	 * Emits a {TransferSingle} event.
	 *
	 * Requirements:
	 *
	 * - `from` cannot be the zero address.
	 * - `from` must have at least `amount` tokens of token type `id`.
	 */
	function _burn(address from, uint256 id, uint256 amount) internal virtual {
		require(from != address(0), "ERC1155: burn from the zero address");

		address operator = _msgSender();
		uint256[] memory ids = _asSingletonArray(id);
		uint256[] memory amounts = _asSingletonArray(amount);

		_beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

		uint256 fromBalance = _balances[id][from];
		require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
		unchecked {
			_balances[id][from] = fromBalance - amount;
		}

		emit TransferSingle(operator, from, address(0), id, amount);

		_afterTokenTransfer(operator, from, address(0), ids, amounts, "");
	}

	/**
	 * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
	 *
	 * Emits a {TransferBatch} event.
	 *
	 * Requirements:
	 *
	 * - `ids` and `amounts` must have the same length.
	 */
	function _burnBatch(
		address from,
		uint256[] memory ids,
		uint256[] memory amounts
	) internal virtual {
		require(from != address(0), "ERC1155: burn from the zero address");
		require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

		address operator = _msgSender();

		_beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

		for (uint256 i = 0; i < ids.length; i++) {
			uint256 id = ids[i];
			uint256 amount = amounts[i];

			uint256 fromBalance = _balances[id][from];
			require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
			unchecked {
				_balances[id][from] = fromBalance - amount;
			}
		}

		emit TransferBatch(operator, from, address(0), ids, amounts);

		_afterTokenTransfer(operator, from, address(0), ids, amounts, "");
	}

	/**
	 * @dev Approve `operator` to operate on all of `owner` tokens
	 *
	 * Emits an {ApprovalForAll} event.
	 */
	function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
		require(owner != operator, "ERC1155: setting approval status for self");
		_operatorApprovals[owner][operator] = approved;
		emit ApprovalForAll(owner, operator, approved);
	}

	/**
	 * @dev Hook that is called before any token transfer. This includes minting
	 * and burning, as well as batched variants.
	 *
	 * The same hook is called on both single and batched variants. For single
	 * transfers, the length of the `ids` and `amounts` arrays will be 1.
	 *
	 * Calling conditions (for each `id` and `amount` pair):
	 *
	 * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
	 * of token type `id` will be  transferred to `to`.
	 * - When `from` is zero, `amount` tokens of token type `id` will be minted
	 * for `to`.
	 * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
	 * will be burned.
	 * - `from` and `to` are never both zero.
	 * - `ids` and `amounts` have the same, non-zero length.
	 *
	 * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
	 */
	function _beforeTokenTransfer(
		address operator,
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) internal virtual {}

	/**
	 * @dev Hook that is called after any token transfer. This includes minting
	 * and burning, as well as batched variants.
	 *
	 * The same hook is called on both single and batched variants. For single
	 * transfers, the length of the `id` and `amount` arrays will be 1.
	 *
	 * Calling conditions (for each `id` and `amount` pair):
	 *
	 * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
	 * of token type `id` will be  transferred to `to`.
	 * - When `from` is zero, `amount` tokens of token type `id` will be minted
	 * for `to`.
	 * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
	 * will be burned.
	 * - `from` and `to` are never both zero.
	 * - `ids` and `amounts` have the same, non-zero length.
	 *
	 * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
	 */
	function _afterTokenTransfer(
		address operator,
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) internal virtual {}

	function _doSafeTransferAcceptanceCheck(
		address operator,
		address from,
		address to,
		uint256 id,
		uint256 amount,
		bytes memory data
	) private {
		if (to.isContract()) {
			try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (
				bytes4 response
			) {
				if (response != IERC1155Receiver.onERC1155Received.selector) {
					revert("ERC1155: ERC1155Receiver rejected tokens");
				}
			} catch Error(string memory reason) {
				revert(reason);
			} catch {
				revert("ERC1155: transfer to non-ERC1155Receiver implementer");
			}
		}
	}

	function _doSafeBatchTransferAcceptanceCheck(
		address operator,
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) private {
		if (to.isContract()) {
			try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
				bytes4 response
			) {
				if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
					revert("ERC1155: ERC1155Receiver rejected tokens");
				}
			} catch Error(string memory reason) {
				revert(reason);
			} catch {
				revert("ERC1155: transfer to non-ERC1155Receiver implementer");
			}
		}
	}

	function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
		uint256[] memory array = new uint256[](1);
		array[0] = element;

		return array;
	}
}

contract CERC1155 is ERC1155, Pausable {
	using Strings for uint256;

	address admin;
	string public baseURL;
	// Contract name
	string public name;
	// Contract symbol
	string public symbol;

	modifier onlyAdmin() {
		require(_msgSender() == admin, "not admin");
		_;
	}

	constructor(
		string memory _name,
		string memory _symbol,
		string memory _baseURL
	) ERC1155(_baseURL) {
		name = _name;
		symbol = _symbol;
		baseURL = _baseURL;

		admin = _msgSender();
	}

	/**
	 * @dev Mint NFT and also check various conditions
	 * 1. Only Admin can mint an NFT
	 * @param _tokenId: the tokenID
	 * @param _qty: quantity
	 * @param _toAddress: receiver
	 */
	function mintNFT(
		uint256 _tokenId,
		uint256 _qty,
		address _toAddress
	) external whenNotPaused onlyAdmin {
		_mint(_toAddress, _tokenId, _qty, "");
	}

	/**<
	 * @dev Extension of {ERC1155} that allows to burn tokens
	 */
	function burnBatch(
		address account,
		uint256[] memory ids,
		uint256[] memory values
	) external virtual {
		if (account != _msgSender() && !isApprovedForAll(account, _msgSender())) {
			revert ERC1155InsufficientApprovalForAll(_msgSender(), account);
		}
		_burnBatch(account, ids, values);
	}

	/**
	 * @dev chwon a token
	 * @param from: address of the current owner
	 *  @param to: address of the future owner
	 *  @param ids: token ids
	 *  @param amounts: token amounts
	 */
	function chown(
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts
	) external virtual onlyAdmin {
		adminChown(from, to, ids, amounts);
	}

	//pause/unpause contract
	function pause() external onlyAdmin {
		_pause();
	}

	//pause/unpause contract
	function unpause() external onlyAdmin {
		_unpause();
	}

	//requires for pause/unpause
	function _beforeTokenTransfer(
		address operator,
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) internal override whenNotPaused {
		super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
	}

	//changes the baseURL of the token
	function setBaseURI(string memory newBaseURL) external onlyAdmin {
		baseURL = newBaseURL;
	}

	//change the admin
	function setAdmin(address newAdmin) public onlyAdmin {
		admin = newAdmin;
	}

	/**
	 * @dev return the uri of a token
	 */
	function uri(uint256 _tokenId) public view override returns (string memory) {
		return string(abi.encodePacked(baseURL, _tokenId.toString(), ".json"));
	}
}
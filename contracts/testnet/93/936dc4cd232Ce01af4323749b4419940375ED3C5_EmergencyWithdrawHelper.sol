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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "../interfaces/ILiquidationProtocol.sol";

interface IInfinityPool {

	/*

	action types
	public static final int SOURCE_WEB = 1;
	public static final int SOURCE_ETHERERUM = 2;
	
	public static final int TYPE_DEPOSIT = 1;
	public static final int TYPE_WITHDRAWL = 2;
	public static final int TYPE_WITHDRAWL_FAST = 3;
	public static final int TYPE_TRANSFER = 4;
	
	public static final int TYPE_BORROW = 10;
	public static final int TYPE_PAYBACK = 11;
	
	public static final int TYPE_CREATE_EXCHANGE_LIQUIDITY_POSITION = 20;
	public static final int TYPE_UPDATE_EXCHANGE_LIQUIDITY_POSITION = 21;
	public static final int TYPE_REMOVE_EXCHANGE_LIQUIDITY_POSITION = 22;
	public static final int TYPE_EXCHANGE = 23;
	public static final int TYPE_EXCHANGE_LARGE_ORDER = 24;

	*/

	struct TokenTransfer {
		address token;
		uint256 amount;
	}
	struct TokenUpdate {
		uint256 tokenId; // might be prepended with wallet type (e.g. interest bearing wallets)
		uint256 amount; // absolute value - should always be unsigned
		bool isERC721; // to avoid high gas usage from checking erc721 
		uint64 priceIndex;
	}

	struct Action {
		uint256 action;
		uint256[] parameters;
	}

	struct ProductVariable {
		uint64 key;
		int64 value;
	}

	struct PriceIndex {
		uint256 key;
		uint64 value;
	}



	event WithdrawalRequested(
		address indexed sender,
		TokenTransfer[] transfers
	);

	event ProductVariablesUpdated(
		ProductVariable[] variables
	);
	event PriceIndexesUpdated(
		PriceIndex[] priceIndexes
	);

	event LiquidationProtocolRegistered(
		address indexed protocolAddress
	);


	
	event ServerLiquidateSuccess(
		address indexed clientAddress,
		address tokenFrom,
		uint256 amountIn,
		ILiquidationProtocol.LiquidatedAmount[] amounts
	);
	
	//function version() external view returns(uint v);

	function deposit(
		TokenTransfer[] memory tokenTranfers,
		Action[] calldata actions
	) external payable;

	function requestWithdraw(TokenTransfer[] calldata tokenTranfers) external;

	function action(Action[] calldata actions) external;

	// function balanceOf(address clientAddress, uint tokenId) external view returns (uint);

	// function productVariable(uint64 id) external view returns (int64);

	event DepositsOrActionsTriggered(
		address indexed sender,
		IInfinityPool.TokenTransfer[] transfers, 
		IInfinityPool.Action[] actions
	);


	function priceIndex(uint256 tokenId) external view returns (uint64);

	function serverTransferFunds(address clientAddress, TokenTransfer[] calldata tokenTranfers) external;

	function serverUpdateBalances(
		address[] calldata clientAddresses, TokenUpdate[][] calldata tokenUpdates, 
		PriceIndex[] calldata priceIndexes
	) external;

	// function serverUpdateProductVariables(
	// 	ProductVariable[] calldata productVariables
	// ) external;

	function serverLiquidate(
		address _clientAddress,
		uint64[] memory _protocolIds,
		address[] memory _paths,
		uint256 _amountIn,
		uint256[] memory _amountOutMins,
		uint24[] memory _uniswapPoolFees,
		address[] memory _curvePoolAddresses
	) external;


	//TODO: add interface
	//Emergency functions
	event EmergencyWithdrew(
		address indexed clientAddress,
		TokenTransfer[]
	);

	event Withdrawal(
		address indexed clientAddress,
		TokenTransfer tokenTranfer,
		bool isCompleted
	);
	
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "../dependencies/openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./IInfinityPool.sol";

interface IInfinityToken is IERC1155 {

    function setPool(address _poolAddr) external;

    function priceIndexOf(address clientAddress, uint256 tokenId) external returns(uint64);

    function deposit(
    	address clientAddress, 
    	uint[] memory _coinIds, 
    	uint[] memory _amounts
    ) external;

    function withdraw(
    	address clientAddress, 
    	uint[] memory _coinIds, 
    	uint[] memory _amounts
	) external;

    function transfer(
        address from,
        address to,
    	uint[] memory _coinIds, 
        uint[] memory _amounts
    ) external;

    function moveProducts(
        address clientAddress,
    	uint[] memory _mintIds, 
        uint[] memory _mintAmounts,
    	uint[] memory _burnIds, 
        uint[] memory _burnAmounts
    ) external ;

    function updateBalance(
		address clientAddress, IInfinityPool.TokenUpdate[] calldata tokenUpdates
    ) external;

    function ifUserTokenExistsERC721(
        address account,
    	uint tokenAddress, 
    	uint tokenId
    ) external returns(bool exists);
    // function depositERC721(
    // 	address account, 
    // 	uint tokenAddress, 
    // 	uint tokenId
    // ) external;
    // function withdrawERC721(
    // 	address account, 
    // 	uint tokenAddress, 
    // 	uint tokenId
	// ) external;
    // function transferERC721(
    //     address from,
    //     address to,
    // 	uint tokenAddress, 
    //     uint tokenId
    // ) external;

	
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

interface ILiquidationProtocol {

	struct LiquidateParams {
		address clientAddress;
		address tokenFrom;
		address tokenTo;
		uint256 amountIn; // for ERC721: amountIn is tokenId
		uint256 amountOutMin;
		uint24 poolFee;
		address curvePoolAddress;
	}

	struct LiquidatedAmount {
		address token;
		uint256 amount;
	}
	
	function swap(
		LiquidateParams calldata lparams
	) external returns (LiquidatedAmount[] memory amounts);
	
	// function getApproveAmount(
	// 	LiquidateParams calldata lparams
	// ) external returns (uint256 amountOut,address approveFrom);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

interface IPoolAddressesProvider {

    function wethAddress() external view returns(address);
    function aclManagerAddress() external view returns(address);
    function infinityTokenAddress() external view returns(address);
    function liquidationProtocolAddresses(uint64 protocolId) external view returns(address);
    function registerLiquidationProtocol(uint64 protocolId, address protocolAddress) external;
    function getInfinitySupportedTokens() external view returns (address[] memory);

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "../interfaces/IPoolAddressesProvider.sol";
import "../interfaces/IInfinityToken.sol";
import "../libraries/TransferHelper.sol";
//import "hardhat/console.sol";

library EmergencyWithdrawHelper
{

	event EmergencyWithdrew(
		address indexed clientAddress,
		IInfinityPool.TokenTransfer[]
	);

	// TODO: set user balance to 0 after withdrawal
	function emergencyWithdraw(IPoolAddressesProvider poolAddressProvider) public 
	{
		bool allEmpty = true;
		address[] memory supportedTokensArr = poolAddressProvider.getInfinitySupportedTokens();	
		IInfinityPool.TokenTransfer[] memory withdrewAssets = new IInfinityPool.TokenTransfer[](supportedTokensArr.length);
		IInfinityPool.TokenUpdate[] memory tokenUpdates = new IInfinityPool.TokenUpdate[](supportedTokensArr.length);


		//handling of token type
		for(uint i=0;i<supportedTokensArr.length;i++){
			uint256 tokenBal = IInfinityToken(poolAddressProvider.infinityTokenAddress()).balanceOf(msg.sender,uint256(uint160(supportedTokensArr[i])));
			if (tokenBal > 0)
			{
				allEmpty = false;
				IInfinityPool.TokenUpdate memory tokenUpdate = IInfinityPool.TokenUpdate(uint256(uint160(supportedTokensArr[i])), 0, false, 1); 
				TransferHelper.safeTransfer(supportedTokensArr[i],msg.sender,tokenBal);
				tokenUpdates[i] = tokenUpdate; //TODO perform LP when LP is activated
				withdrewAssets[i] =  IInfinityPool.TokenTransfer(supportedTokensArr[i],tokenBal);						
			}
			if (allEmpty == true)
			{
				revert("Balance is empty");
			}
			///TODO IR Asset - Liability convert all to USD to pay the final sum in USD. Will help if can get a sample of token_id in DB.
		}
		IInfinityToken(poolAddressProvider.infinityTokenAddress()).updateBalance(msg.sender,tokenUpdates);	
		//handling of IR positions
		emit EmergencyWithdrew(msg.sender, withdrewAssets);
	}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

library TransferHelper {
    function safeApprove( address token, address to, uint256 value ) public {
        (bool success, bytes memory data) = token.call(abi.encodeWithSignature("approve(address,uint256)", to, value));
        require( success && (data.length == 0 || abi.decode(data, (bool))), "approve failed" );
    }

    function safeTransferFrom( address token, address from, address to, uint256 value ) public {
        (bool success, bytes memory data) = token.call(abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, value));
        require( success && (data.length == 0 || abi.decode(data, (bool))), "transferFrom failed" );
    }

    function safeTransfer( address token, address to, uint256 value ) public {
        (bool success, bytes memory data) = token.call(abi.encodeWithSignature("transfer(address,uint256)", to, value));
        require( success && (data.length == 0 || abi.decode(data, (bool))), "transfer failed" );
    }

    function safeTransferFromERC721( address token, address from, address to, uint256 tokenId ) public {
        (bool success, bytes memory data) = token.call(abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", from, to, tokenId));
        require( success && (data.length == 0 || abi.decode(data, (bool))), "ERC721 safeTransferFrom failed" );
    }

    function balanceOf( address token, address account ) public returns (uint256 balance){
        (bool success, bytes memory data) = token.call(abi.encodeWithSignature("balanceOf(address)", account));
        require(success,"balanceOf failed");
        balance = abi.decode(data, (uint256));
    }
}
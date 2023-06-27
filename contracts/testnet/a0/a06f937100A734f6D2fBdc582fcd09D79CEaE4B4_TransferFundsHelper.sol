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
	
	function version() external pure returns(uint v);

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
		TokenTransfer[] transfers, 
		Action[] actions
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.12;

// import "hardhat/console.sol";

library ERC721Validator {

    function isERC721(address token) public returns(bool b){
        // bytes4(keccak256(bytes("supportsInterface(bytes4)")))
        (bool success,bytes memory data) = token.call(abi.encodeWithSelector(0x01ffc9a7,bytes4(0x80ac58cd))); // ERC721ID
        if(success && data.length > 0 && abi.decode(data, (bool))){
            (success,data) = token.call(abi.encodeWithSelector(0x01ffc9a7,bytes4(0x5b5e139f))); // ERC721MetadataID
            /**
             * DEV no need to check ERC721Enumerable since it's OPTIONAL (only for token to be able to publish its full list of NFTs - see:
             * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md#specification
             */
            // if(success && data.length > 0 && abi.decode(data, (bool))){
                // (success,data) = token.call(abi.encodeWithSelector(0x01ffc9a7,bytes4(0x780e9d63))); // ERC721EnumerableID
                b = success && data.length > 0 && abi.decode(data, (bool));
                // if(b) console.log("isERC721 ERC721EnumerableID");
            // }
        }
        // console.log(token); console.log(b);
    }

    function isERC721Owner(address token, address account, uint256 tokenId) public returns(bool result){
        // bytes4(keccak256(bytes('ownerOf(uint256)')));
        (, bytes memory data) = token.call(abi.encodeWithSelector(0x6352211e, tokenId));
        address owner = abi.decode(data, (address));
        result = owner==account;
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "../interfaces/IInfinityPool.sol";
import "./TransferHelper.sol";
import "./ERC721Validator.sol";

library TransferFundsHelper {
    event Withdrawal(
		address indexed clientAddress,
		IInfinityPool.TokenTransfer tokenTranfer,
		bool isCompleted
	);

	function serverTransferFunds(
		bool isAdmin, address clientAddress, IInfinityPool.TokenTransfer[] calldata tokenTransfers, 
		mapping(address => uint256) storage dailyWithdrawalCap, mapping(address => uint256) storage lastWithdrawalTime, mapping(address => uint256) storage currentDailyWithdrawalAmount,
		mapping(address => IInfinityPool.TokenTransfer[]) storage pendingTransferFundsInfo, address[] storage pendingTransferFundsAddresses
	) external {
		require(tokenTransfers.length > 0, "1");
		/* do checkings again */
		for(uint i=0; i < tokenTransfers.length; i++){
			IInfinityPool.TokenTransfer memory t = tokenTransfers[i];
			if(ERC721Validator.isERC721(t.token)){
				// require(poolToken.ifUserTokenExistsERC721(clientAddress, uint256(uint160(t.token)), t.amount), "8");
				TransferHelper.safeTransferFromERC721(t.token, address(this), clientAddress, t.amount);
				emit Withdrawal(clientAddress, t, true);
			}else{
				require(TransferHelper.balanceOf(t.token, address(this)) >= t.amount, "6");
				// require(poolToken.balanceOf(clientAddress,uint256(uint160(t.token)))>=t.amount,"7");
				// reset limit after a day
				if (block.timestamp - lastWithdrawalTime[t.token] > 86400 && !isAdmin) {
					lastWithdrawalTime[t.token] = block.timestamp;
					currentDailyWithdrawalAmount[t.token] = 0;
				}

				//if the amount to withdraw exceeds daily cap, all the amount will be sent to pending queue. 
				// No partial withdrawals will be made if daily cap is exceed. 
				if(currentDailyWithdrawalAmount[t.token] + t.amount <= dailyWithdrawalCap[t.token] || isAdmin) {
					TransferHelper.safeTransfer(t.token,clientAddress, t.amount);
					currentDailyWithdrawalAmount[t.token] += t.amount;
					emit Withdrawal(clientAddress, t, true);
				} else {
					pendingTransferFundsInfo[clientAddress].push(t);
					pendingTransferFundsAddresses.push(clientAddress);
					emit Withdrawal(clientAddress, t, false);
				}
			}
		}
	}

    /**
     * @dev withdraw all the funds that is in the pending queue for the respective addresses
     *
     * - `pendingTransferFundsAddresses`: users that have the function would like to process
     * - `pendingTransferFundsInfo`: assets in which the the transfer will be conducted
     *
     * IMPORTANT: 
     */
	function serverTransferPendingFunds(
		address[] storage pendingTransferFundsAddresses,
		mapping(address => IInfinityPool.TokenTransfer[]) storage pendingTransferFundsInfo
	) external {
		for (uint j = 0; j < pendingTransferFundsAddresses.length; j++) {
			IInfinityPool.TokenTransfer[] storage tokenTransfers = pendingTransferFundsInfo[pendingTransferFundsAddresses[j]];
			for(uint i=0; i < tokenTransfers.length; i++){
				IInfinityPool.TokenTransfer memory t = tokenTransfers[i];
				require(TransferHelper.balanceOf(t.token, address(this)) >= t.amount, "6");
				TransferHelper.safeTransfer(t.token, pendingTransferFundsAddresses[j], t.amount);
				emit Withdrawal(pendingTransferFundsAddresses[j], t, true);
			}
			delete pendingTransferFundsInfo[pendingTransferFundsAddresses[j]];
			delete pendingTransferFundsAddresses[j];
		}
	}

	function resetPendingTransferFundsInfo(
		address[] storage pendingTransferFundsAddresses,
		mapping(address => IInfinityPool.TokenTransfer[]) storage pendingTransferFundsInfo
	) external {
		for (uint j = 0; j < pendingTransferFundsAddresses.length; j++) {
			delete pendingTransferFundsInfo[pendingTransferFundsAddresses[j]];
			delete pendingTransferFundsAddresses[j];
		}
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
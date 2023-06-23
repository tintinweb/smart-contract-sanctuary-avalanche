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

import "../interfaces/ILiquidationProtocol.sol";
import "../interfaces/IPoolAddressesProvider.sol";
// import "hardhat/console.sol";

library LiquidationHelper2 {
	function liquidate(
		IPoolAddressesProvider poolAddressProvider,
		uint64[] memory _protocolIds,
		address[] memory _paths,
		uint256 _amountIn,
		uint256[] memory _amountOutMins,
		uint24[] memory _uniswapPoolFees,
		address[] memory _curvePoolAddresses
	) public returns (ILiquidationProtocol.LiquidatedAmount[] memory amounts) {
		uint256 amountIn;
		uint256 amountOut;
		for (uint256 i = 0; i < _protocolIds.length; i++) {
			require(_paths[i] != address(0x0), "path cannot be 0x0");
			if (i == 0) {
				amountIn = _amountIn;
			} else {
				amountIn = amountOut;
			}

			address protocolAddress = poolAddressProvider.liquidationProtocolAddresses(_protocolIds[i]);
			require(protocolAddress != address(0x0), "protocol incorrect");

			ILiquidationProtocol.LiquidateParams memory lparams;
			lparams.tokenFrom = _paths[i];
			lparams.tokenTo = _paths[i+1];
			lparams.amountIn = amountIn;
			lparams.amountOutMin = _amountOutMins[i];
			lparams.poolFee = _uniswapPoolFees[i];
			lparams.curvePoolAddress = _curvePoolAddresses[i];
			
			(bool success, bytes memory data) = lparams.tokenFrom.call(abi.encodeWithSignature("approve(address,uint256)", address(protocolAddress), lparams.amountIn));
			require( success && (data.length == 0 || abi.decode(data, (bool))), "approve failed" );
			amounts = ILiquidationProtocol(protocolAddress).swap(lparams);
			// it ignores amounts[1].amount which may not be able to swap furter after liquidating UniswapV3 LP NFT 
			amountOut = amounts[0].amount;
		}
	}
}
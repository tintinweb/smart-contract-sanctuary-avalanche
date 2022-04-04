/*The idea here is to use sgReceive() and execute a swap to the native token upon receipt of stablecoins from Stargate*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/IStargateReceiver.sol";

interface IERC20 {
	 function transfer(address to, uint256 amount) external returns (bool);
	 function approve(address spender, uint256 amount) external returns (bool);
}

interface Router {
	function swapExactTokensForAVAX (
		uint amountIn, 
		uint amountOutMin, 
		address[] calldata path, 
		address to, 
		uint deadline ) external returns (uint[] memory amounts);
}

error NotFromRouter();
error NotFromEndpoint();
contract SwapReceiver is IStargateReceiver {

	address public constant SG_ROUTER = 0x45A01E4e04F14f7A4a6702c74187c5F6222033cd;
	address public constant USDC = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;
	address public constant WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
	address[] private USDC_WAVAX;
	Router joeRouter = Router(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);

	constructor(){
		USDC_WAVAX.push(USDC);
		USDC_WAVAX.push(WAVAX);
		IERC20(USDC).approve(msg.sender, 2**256-1); //Doing this so that we can extract any stuck USDC from the contract if necessary
		IERC20(USDC).approve(0x60aE616a2155Ee3d9A68541Ba4544862310933d4, 2**256-1); //Approve the Joe router for USDC
	}

	function sgReceive(uint16 _chainId, bytes memory _srcAddress, uint256 _nonce, address _token, uint256 amountLD, bytes memory payload) external override {
		if (msg.sender != SG_ROUTER) revert NotFromRouter();
		(address to, uint256 minAmountOut) = abi.decode(payload, (address, uint256));
		//could use the token param here to differentiate USDC from USDT
		joeRouter.swapExactTokensForAVAX(amountLD, minAmountOut, USDC_WAVAX, to, block.timestamp);
	}

}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

interface IStargateReceiver {
    function sgReceive(
        uint16 _chainId,
        bytes memory _srcAddress,
        uint256 _nonce,
        address _token,
        uint256 amountLD,
        bytes memory payload
    ) external;
}
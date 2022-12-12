/**
 *Submitted for verification at testnet.snowtrace.io on 2022-12-12
*/

// File contracts/test/TestRecipient.sol
pragma solidity >=0.8.0;

interface Token {
    function approve(address spender, uint256 amount) external returns (bool) ;
}

interface ILiquidityLayerRouter {
    function dispatchWithTokens(
        uint32 _destinationDomain,
        bytes32 _recipientAddress,
        bytes calldata _messageBody,
        address _token,
        uint256 _amount,
        string calldata _bridge
    ) external payable returns (uint256);
}

contract LiquidityCallerHyperlane {

    function approve(address token, address liquidityLayer) external {
        Token(token).approve(liquidityLayer, 1000000000);
    }

    function callLiquidityLayer(address liquidityLayer, uint32 _destinationDomain,
        bytes32 _recipientAddress,
        bytes calldata _messageBody,
        address _token,
        uint256 _amount,
        string calldata _bridge) external {
        
        ILiquidityLayerRouter(liquidityLayer).dispatchWithTokens(_destinationDomain,_recipientAddress,_messageBody, _token, _amount, _bridge);
    }
}
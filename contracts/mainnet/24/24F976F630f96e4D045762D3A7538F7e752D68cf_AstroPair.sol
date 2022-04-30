// SPDX-License-Identifier: MIT

pragma solidity ^ 0.8.4;

interface InterfaceLP {
    function sync() external;
}

import './IJoeRouter01.sol';

pragma solidity >=0.4.22 <0.9.0;

interface IDEXRouter is IJoeRouter01 {
    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountAVAX);

    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

pragma solidity ^ 0.8.0;

interface IDEXFactory {
    function createPair(address tokenA, address tokenB)
    external
    returns (address pair);
}

pragma solidity ^ 0.8.4;


contract AstroPair {

    address owner;

    IDEXRouter public router;

    address public pair;

    address public tokenA;

    address public tokenB;

    modifier onlyOwner {
        require(msg.sender == owner, "AstroToken: Caller is not owner the contract.");
        _;
    }

    constructor(address _router, address _tokenA, address _tokenB) {
        owner = msg.sender;
        
        router = IDEXRouter(_router);

        tokenA = _tokenA;

        tokenB = _tokenB;
        
    }

    function getPair() public returns (address){

        pair = IDEXFactory(router.factory()).createPair(tokenA, tokenB);

        return pair;
    }

    receive() payable external {}

    fallback() payable external {}
}
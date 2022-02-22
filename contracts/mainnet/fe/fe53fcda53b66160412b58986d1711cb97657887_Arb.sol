/**
 *Submitted for verification at snowtrace.io on 2022-02-22
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

contract IERC20 {
    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;
    function approve(address guy, uint wad) public returns (bool) {
        return true;
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        returns (bool)
    {
        return true;
    }
    function deposit() public payable {
        
    }
}

interface Pair {
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    function token0() external view returns (address);

}


contract Arb {
    using SafeMath for uint;
    address payable private owner; 
    address public WAVAX;
    constructor(address _WAVAX) {
        owner = payable(msg.sender);
        WAVAX = _WAVAX;
    }

    function safeTransfer(address token,address to,uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    function getAmountsOut(uint amountIn, address[] calldata pairs, address [] calldata tokens) external view returns(uint256[] memory) {
        uint[] memory amounts = new uint[](tokens.length);
        amounts[0] = amountIn;
        for (uint i =0 ; i< pairs.length; i++){
            (uint reserveIn, uint reserveOut, ) = Pair(pairs[i]).getReserves();
            address token0 = Pair(pairs[i]).token0();
            if (tokens[i] != token0) {
                uint tmp = reserveIn;
                reserveIn = reserveOut;
                reserveOut = tmp;
            }
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
        return amounts;
    } 

    function _swap(address[] calldata pairs, address[] calldata path, address _to) internal virtual{
        for (uint i; i < pairs.length; i++) {
            (address token0,) = sortTokens(path[i], path[i+1]);
            (uint reserveIn, uint reserveOut, ) = Pair(pairs[i]).getReserves();
            if (token0 != path[i]){
                uint tmp = reserveIn;
                reserveIn = reserveOut;
                reserveOut = tmp;
            }
            uint amountInput = IERC20(path[i]).balanceOf(address(pairs[i])).sub(reserveIn);
            uint amountOutput = getAmountOut(amountInput, reserveIn, reserveOut);
            uint amount0Out = path[i] == token0 ? 0 : amountOutput;
            uint amount1Out = path[i] == token0 ? amountOutput : 0;
            address to = i < path.length - 2 ? pairs[i+1] : _to;
            Pair(pairs[i]).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }
    
    function arb(address[] calldata tokens, address[] calldata pairs, uint amountIn) external{
        require(msg.sender == owner, "OWNER");
        uint prevBalance = IERC20(WAVAX).balanceOf(address(this));
        safeTransfer(tokens[0],pairs[0], amountIn);
        _swap(pairs, tokens, address(this));
        require(IERC20(WAVAX).balanceOf(address(this)) > prevBalance, "Failed Arb");
    }

    function redeem(address[] calldata tokens) external {
        require(msg.sender == owner, "OWNER");
        for (uint i = 0; i < tokens.length; i++){
            if (tokens[i] != address(0)) {
                uint balance = IERC20(tokens[i]).balanceOf(address(this));
                IERC20(tokens[i]).transfer(owner, balance);
            }
            else{
                (bool sent, ) = owner.call{value: address(this).balance}("");
                require(sent, "NOT SENT");
            }
        }
    }
}
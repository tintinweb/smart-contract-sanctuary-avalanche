/**
 *Submitted for verification at testnet.snowtrace.io on 2022-06-01
*/

// SPDX-License-Identifier: MIT
// File: contracts/EtherstonesRewardManager.sol

pragma solidity = 0.8.11;

interface iPair
{
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}
interface iRouter
{
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);
}
contract Testing
{
    address public Router = 0xadcBe444619dE95aeDD82245d0B422288b27C895;
    address public Pair;
    address public token0 = 0x1D308089a2D1Ced3f1Ce36B1FcaF815b07217be3;
    address public token1 = 0xc8BCb185cBA6A3eC0E509646F2B0D2fFcF668209;
    
    function setPair(address _pair)public
    {
        Pair = _pair;
    }

    function getAVAX(uint256 _tokens)public view returns(uint256 _AVAX)
    {
        (uint256 reserve0, uint256 reserve1, ) = iPair(Pair).getReserves();
        // reserve0 = AVAX
        // reserve1 = ETHW
        uint256 avax = iRouter(Router).quote(_tokens, reserve1, reserve0);
        return avax;
    }
    
}
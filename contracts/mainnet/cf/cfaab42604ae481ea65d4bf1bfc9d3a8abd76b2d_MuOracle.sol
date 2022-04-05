/**
 *Submitted for verification at snowtrace.io on 2022-04-05
*/

// File: contracts/MuOracle.sol


pragma solidity ^0.8.0;


interface LP{
    function getReserves() external view returns (uint112 _reserve0,uint112 _reserve1,uint32 _blockTimestampLast);
    function token0() external view returns (address token0);
    function token1() external view returns (address token1);
}

contract MuOracle{

    LP mu_usdce_traderjoes;
    LP mu_avax_traderjoes;
    LP mu_avax_sushiswap;
    LP mu_daie_traderjoes;
    LP mu_usdte_traderjoes;
    LP mu_mim_traderjoes;
    LP mu_mug_traderjoes;

    constructor(){
       //mu LP pools 
       mu_usdce_traderjoes = LP(0xfacB3892F9A8D55Eb50fDeee00F2b3fA8a85DED5);


       //mu-mug LP pool
       mu_mug_traderjoes = LP(0x67d9aAb77BEDA392b1Ed0276e70598bf2A22945d);
       
    }  

    //to return from any liquidty pool
    //reservers in pool token0, token1
    //token0 per token1
    //token 1 per token0
    //timestamp taken
    //pool address
    function internalMU_USDCe_pool_info() internal view returns(address token0, address token1, uint112 _reserve0,uint112 _reserve1,uint32 _blockTimestampLast){
        (uint112 __reserve0, uint112 __reserve1, uint32 __blockTimestampLast) = mu_usdce_traderjoes.getReserves();
        address _token0 = mu_usdce_traderjoes.token0();
        address _token1 = mu_usdce_traderjoes.token1();
        return (_token0, _token1, __reserve0, __reserve1, __blockTimestampLast);
    }
    function get_MU_USDCe_pool_info() public view returns (address token0, address token1, uint112 _reserve0,uint112 _reserve1,uint32 _blockTimestampLast){
        return internalMU_USDCe_pool_info();
    }

}
/**
 *Submitted for verification at snowtrace.io on 2022-04-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface LP{
    function getReserves() external view returns (uint112 _reserve0,uint112 _reserve1,uint32 _blockTimestampLast);
    function token0() external view returns (address token0);
    function token1() external view returns (address token1);
}

contract MuOracle{
    struct LPpoolStruct{
        address poolAddress;
        address token0address;
        address token1address;
        uint112 token0reserve;
        uint112 token1reserve;
        uint32 quoteTimestamp;
    }

    LP mu_usdce_traderjoes;
    LP mu_avax_traderjoes;
    LP mu_avax_sushiswap;
    LP mu_daie_traderjoes;
    LP mu_usdte_traderjoes;
    LP mu_mim_traderjoes;
    LP mu_mug_traderjoes;

    constructor(){
       //mu LP pools 
        mu_usdce_traderjoes = LP(0xfacB3892F9A8D55Eb50fDeee00F2b3fA8a85DED5);  //done
        mu_avax_traderjoes = LP(0xdAD81eabB09Be931b305b326E0839Ad9434A7707);
        mu_avax_sushiswap = LP(0xBF12Ca918c7e8Cb260F480e74fdb99F5E0DE5E8B);
        mu_daie_traderjoes = LP(0xC813d23B610044C9d9ec3c723cAc8462E2fD838A); //done
        mu_usdte_traderjoes = LP(0x594caaa2e32AEa337F03e5dB543138B150Ba9f42);//done
        mu_mim_traderjoes= LP(0x6bb1CfA34F9acD3fF2ac0Ecad81924c2Ea7b8351);//done
       //mu-mug LP pool
       mu_mug_traderjoes = LP(0x67d9aAb77BEDA392b1Ed0276e70598bf2A22945d);
       
    }  

    //lp token info
    //to return from any liquidty pool
    //reservers in pool token0, token1
    //token0 per token1
    //token 1 per token0
    //timestamp taken
    //pool address
   

//in this function mu is token1
    function internal_mu_usdce_traderjoes_pool_info() internal view returns(address LPpool, address token0, address token1, uint112 _reserve0,uint112 _reserve1, uint256 muUSDe, uint32 _blockTimestampLast){
        (uint112 __reserve0, uint112 __reserve1, uint32 __blockTimestampLast) = mu_usdce_traderjoes.getReserves();
        address _token0 = mu_usdce_traderjoes.token0();
        address _token1 = mu_usdce_traderjoes.token1();
        uint256 usd = uint256(__reserve0);
        uint256 mu = uint256(__reserve1);
        usd = usd * 10**30;
        uint256 muUSD = usd/mu;
        return (0xfacB3892F9A8D55Eb50fDeee00F2b3fA8a85DED5, _token0, _token1, __reserve0 * 10**12, __reserve1, muUSD, __blockTimestampLast);
    }
    function get_mu_usdce_traderjoes_pool_info() public view returns (address LPpool, address usdce_token0, address mu_token1, uint112 usdce_reserve0,uint112 mu_reserve1, uint256 muUSDe, uint32 _blockTimestampLast){
        return internal_mu_usdce_traderjoes_pool_info();
    }

    function internal_mu_usdte_traderjoes_pool_info() internal view returns(address LPpool, address token0, address token1, uint112 _reserve0,uint112 _reserve1, uint256 muUSDT, uint32 _blockTimestampLast){
        (uint112 __reserve0, uint112 __reserve1, uint32 __blockTimestampLast) = mu_usdte_traderjoes.getReserves();
        address _token0 = mu_usdte_traderjoes.token0();
        address _token1 = mu_usdte_traderjoes.token1();
        uint256 usdt = uint256(__reserve0);
        uint256 mu = uint256(__reserve1);
        usdt = usdt * 10**30;
        uint256 muUSDT = usdt/mu;
        return (0x594caaa2e32AEa337F03e5dB543138B150Ba9f42, _token0, _token1, __reserve0 * 10**12, __reserve1, muUSDT, __blockTimestampLast);
    }
    function get_mu_usdte_traderjoes_pool_info() public view returns (address LPpool, address usdce_token0, address mu_token1, uint112 USDT_reserve0,uint112 mu_reserve1, uint256 muUSDT, uint32 _blockTimestampLast){
        return internal_mu_usdte_traderjoes_pool_info();
    }

       function internal_mu_mim_traderjoes_pool_info() internal view returns(address LPpool, address token0, address token1, uint112 _reserve0,uint112 _reserve1, uint256 muMIM, uint32 _blockTimestampLast){
        (uint112 __reserve0, uint112 __reserve1, uint32 __blockTimestampLast) = mu_mim_traderjoes.getReserves();
        address _token0 = mu_mim_traderjoes.token0();
        address _token1 = mu_mim_traderjoes.token1();
        uint256 mim = uint256(__reserve0);
        uint256 mu = uint256(__reserve1);
        mim = mim * 10**18;
        uint256 muMIM = mim/mu;
        return (0x6bb1CfA34F9acD3fF2ac0Ecad81924c2Ea7b8351, _token0, _token1, __reserve0, __reserve1, muMIM, __blockTimestampLast);
    }
    function get_mu_mim_traderjoes_pool_info() public view returns (address LPpool, address usdce_token0, address mu_token1, uint112 usdce_reserve0,uint112 mu_reserve1, uint256 muMIM, uint32 _blockTimestampLast){
        return internal_mu_mim_traderjoes_pool_info();
    }


//avax pool
       function internal_mu_avax_traderjoes_pool_info() internal view returns(address LPpool, address token0, address token1, uint112 _reserve0,uint112 _reserve1, uint256 muAVAX, uint32 _blockTimestampLast){
        (uint112 __reserve0, uint112 __reserve1, uint32 __blockTimestampLast) = mu_avax_traderjoes.getReserves();
        address _token0 = mu_avax_traderjoes.token0();
        address _token1 = mu_avax_traderjoes.token1();
        uint256 avax = uint256(__reserve0);
        uint256 mu = uint256(__reserve1);
        avax = avax * 10**18;
        uint256 muAVAX = avax/mu;
        return (0xdAD81eabB09Be931b305b326E0839Ad9434A7707, _token0, _token1, __reserve0, __reserve1, muAVAX, __blockTimestampLast);
    }
    function get_mu_avax_traderjoes_pool_info() public view returns (address LPpool, address avax_token0, address mu_token1, uint112 avax_reserve0,uint112 mu_reserve1, uint256 muAVAX, uint32 _blockTimestampLast){
        return internal_mu_avax_traderjoes_pool_info();
    }



//in this function mu is token0
    function internal_mu_daie_traderjoes_pool_info() internal view returns(address LPpool, address token0, address token1, uint112 _reserve0,uint112 _reserve1, uint256 muDAI, uint32 _blockTimestampLast){
        (uint112 __reserve0, uint112 __reserve1, uint32 __blockTimestampLast) = mu_daie_traderjoes.getReserves();
        address _token0 = mu_daie_traderjoes.token0();
        address _token1 = mu_daie_traderjoes.token1();
        uint256 mu = uint256(__reserve0);
        uint256 dai = uint256(__reserve1);
        dai = dai * 10**18;
        uint256 muDAI = dai/mu;
        return (0xC813d23B610044C9d9ec3c723cAc8462E2fD838A, _token0, _token1, __reserve0, __reserve1, muDAI, __blockTimestampLast);
    }
    function get_mu_daie_traderjoes_pool_info() public view returns (address LPpool, address mu_token0, address dai_token1, uint112 _reserve0,uint112 _reserve1, uint256 muDAI, uint32 _blockTimestampLast){
        return internal_mu_daie_traderjoes_pool_info();
    }


    //function to return 

    //function to return total LP value supply, all mu in lp, all mug in lp, all other assets $$ value in lp
    //getreservesAll

}
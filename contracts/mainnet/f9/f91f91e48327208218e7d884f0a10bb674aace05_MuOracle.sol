/**
 *Submitted for verification at snowtrace.io on 2022-04-13
*/

// File: contracts/MuOracle.sol


pragma solidity ^0.8.0;

interface LP{
    function getReserves() external view returns (uint112 _reserve0,uint112 _reserve1,uint32 _blockTimestampLast);
    function token0() external view returns (address token0);
    function token1() external view returns (address token1);
}

interface Token{
    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
}

contract MuOracle{

    


    struct LPpoolStruct{
        string poolName;
        address poolAddress;
        address token0address;
        uint112 token0reserve;
        uint8 token0decimals;
        address token1address;
        uint112 token1reserve;
        uint8 token1decimals;
        uint256 refPrice;
        uint256 musudPrice;
        uint32 quoteTimestamp;
    }


    function get_pool_info_struct(address pool) internal view returns(LPpoolStruct memory){
        LPpoolStruct memory lp_struct;
        LP lp_pool = LP(pool);
        Token token0;
        Token token1;

        //normal struct data
        lp_struct.poolAddress = pool;
        lp_struct.token0address = lp_pool.token0();
        lp_struct.token1address = lp_pool.token1();

        

        //get tokens decimals
        token0 = Token(lp_pool.token0());
        token1 = Token(lp_pool.token1());
        lp_struct.token0decimals = token0.decimals();
        lp_struct.token1decimals = token1.decimals();
        
        lp_struct.poolName =  string(abi.encodePacked(token0.name(), "/", token1.name()));

        //get token reserves
        (uint112 __reserve0, uint112 __reserve1, uint32 __blockTimestampLast) = lp_pool.getReserves();
        lp_struct.token0reserve = __reserve0;
        lp_struct.token1reserve = __reserve1;
        lp_struct.quoteTimestamp = __blockTimestampLast;

        //check what token Mu Coin is
        uint256 value;
        uint256 mu;
        uint8 offset;
        uint256 muRef;
        uint256 muUSD;
        if(lp_struct.token0address == 0xD036414fa2BCBb802691491E323BFf1348C5F4Ba){
        //MU Coin is token 0  
            value = uint256(__reserve1);
            mu = uint256(__reserve0);
            offset = (18 - lp_struct.token1decimals) + 18;
            value = value * 10 ** offset;
            muRef = value/mu;
            lp_struct.refPrice = muRef;

        }else{
         //MU Coin is token1
            value = uint256(__reserve1);
            mu = uint256(__reserve1);
            offset = (18 - lp_struct.token0decimals) + 18;
            value = value * 10 ** offset;
            muRef = value/mu;
            lp_struct.refPrice = muRef;
        }

        muUSD = 0;
        lp_struct.musudPrice = muUSD;


        /*
        (uint112 __reserve0, uint112 __reserve1, uint32 __blockTimestampLast) = mu_usdce_traderjoes.getReserves();
        uint256 usd = uint256(__reserve0);
        uint256 mu = uint256(__reserve1);
        usd = usd * 10**30;
        uint256 muUSD = usd/mu;
        //Fill Struct
        mu_usdce_pool_struct.poolAddress = 0xfacB3892F9A8D55Eb50fDeee00F2b3fA8a85DED5;
        mu_usdce_pool_struct.token0address = mu_usdce_traderjoes.token0();
        mu_usdce_pool_struct.token1address = mu_usdce_traderjoes.token1();
        mu_usdce_pool_struct.token0reserve = __reserve0;
        mu_usdce_pool_struct.token1reserve = __reserve1;
        mu_usdce_pool_struct.quoteTimestamp = __blockTimestampLast;
        mu_usdce_pool_struct.refPrice = muUSD;
        */
        return lp_struct;

        //return (0xfacB3892F9A8D55Eb50fDeee00F2b3fA8a85DED5, _token0, _token1, __reserve0 * 10**12, __reserve1, muUSD, __blockTimestampLast);
    }

    function get_mu__pool_info_struct(address pool) public view returns (LPpoolStruct memory){
        return get_pool_info_struct(pool);
    }


}
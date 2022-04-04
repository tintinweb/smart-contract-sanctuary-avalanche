/**
 *Submitted for verification at snowtrace.io on 2022-04-04
*/

// File: contracts/PriceOracle.sol



pragma solidity ^0.8.0;


interface JoeLP{
    function getReserves() external view returns (uint112 _reserve0,uint112 _reserve1,uint32 _blockTimestampLast);
}





contract MuPriceOracle{
    
    JoeLP _mulp;


    constructor(){
       _mulp = JoeLP(0xfacB3892F9A8D55Eb50fDeee00F2b3fA8a85DED5);
    }  
   
    function getReserves() public view returns(uint112 reserve0,uint112 reserve1,uint32 blockTimestampLast){
        return _mulp.getReserves();

    }
}
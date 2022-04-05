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
    JoeLP _muglp;

    

    constructor(){
       _mulp = JoeLP(0xfacB3892F9A8D55Eb50fDeee00F2b3fA8a85DED5);
       _muglp = JoeLP(0x67d9aAb77BEDA392b1Ed0276e70598bf2A22945d);
       
    }  
   
    function getReservesUSD_MU() public view returns(uint112 reserve0,uint112 reserve1,uint32 blockTimestampLast){
        return _mulp.getReserves();
    }
    function getReservesMU_MUG() public view returns(uint112 reserve0,uint112 reserve1,uint32 blockTimestampLast){
        return _muglp.getReserves();
    }

    function getMuUSDprice() public view returns(uint256){
        (uint112 reserve0,uint112 reserve1,uint32 blockTimestampLast) = _mulp.getReserves();
        uint256 usd = uint256(reserve0);
        uint256 mu = uint256(reserve1);
        usd = usd * 10**30;
        uint256 muUSD = usd/mu;
        return muUSD;
    }

    function getMugMuPrice() public view returns(uint256){
        (uint112 reserve0,uint112 reserve1,uint32 blockTimestampLast) = _muglp.getReserves();
        uint256 mu = uint256(reserve0);
        uint256 mug = uint256(reserve1);
        mu = mu*10**18;
        uint256 mumug = mu/mug;
        return mumug;

    }

    function getAmountMUGOwedForUSDPayment(uint256 usd_wei) public view returns(uint256){
        (uint112 reserve0,uint112 reserve1,uint32 blockTimestampLast) = _mulp.getReserves();
        uint256 usd = uint256(reserve0);
        uint256 mu = uint256(reserve1);
        usd = usd * 10**30;
        uint256 muUSD = usd/mu;

        (uint112 _reserve0,uint112 _reserve1,uint32 _blockTimestampLast) = _muglp.getReserves();
        uint256 _mu = uint256(_reserve0);
        uint256 mug = uint256(_reserve1);
        _mu = _mu*10**18;
        uint256 mumug = _mu/mug;
        muUSD = muUSD/(10**9);
        mumug = mumug/(10**9);
        uint256 mugUSD = (muUSD * mumug);
        uint256 _usd_wei = usd_wei;
        uint256 payamount = (_usd_wei * 10**18)/mugUSD;
        return payamount;

    }
    function internalMuandMugPrice() internal view returns(uint256 muUSD, uint256 muMUG){

        (uint112 reserve0,uint112 reserve1,uint32 blockTimestampLast) = _mulp.getReserves();
        (uint112 _reserve0,uint112 _reserve1,uint32 _blockTimestampLast) = _muglp.getReserves();
        
        uint256 usd = uint256(reserve0);
        uint256 mu = uint256(reserve1);
        usd = usd * 10**30;
        uint256 muUSD = usd/mu;

        uint256 _mu = uint256(_reserve0);
        uint256 mug = uint256(_reserve1);
        _mu = _mu*10**18;
        uint256 mumug = _mu/mug;


        return (muUSD, mumug);

    }

    function getPrices() public view returns(uint256 muUSD, uint256 muMUG){
        return internalMuandMugPrice();
    }

    function getMugUSDPrice() public view returns(uint256){
         (uint112 reserve0,uint112 reserve1,uint32 blockTimestampLast) = _mulp.getReserves();
        uint256 usd = uint256(reserve0);
        uint256 mu = uint256(reserve1);
        usd = usd * 10**30;
        uint256 muUSD = usd/mu;

        (uint112 _reserve0,uint112 _reserve1,uint32 _blockTimestampLast) = _muglp.getReserves();
        uint256 _mu = uint256(_reserve0);
        uint256 mug = uint256(_reserve1);
        _mu = _mu*10**18;
        uint256 mumug = _mu/mug;
        muUSD = muUSD/(10**9);
        mumug = mumug/(10**9);
        

        return (muUSD * mumug);
       
    }
    

}
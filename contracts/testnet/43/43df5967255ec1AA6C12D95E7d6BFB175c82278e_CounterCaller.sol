/**
 *Submitted for verification at testnet.snowtrace.io on 2023-07-13
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

library Components {

         //  struct Path {
    //     uint256[] pairBinSteps;
    //     Version[] versions;
    //     IERC20[] tokenPath;
    // }

    struct Path {
        uint256[] pairBinSteps;
        uint8[] versions;
        address[] tokenPath;
    }
}

contract TraderJoeRouterFunctions {

    function swapExactTokensForTokens(uint256 _amountIn, uint256 _amountOutMin, Components.Path memory path, address _to, uint256 _deadline) external pure  returns(uint256 amountOut){
        return amountOut;
    }

}

contract WAvaxContract {
    function withdraw(uint256 wad) public{
    }

    function deposit() public payable{
    }

    function approve(address guy, uint256 wad) public returns (bool result){
        return result;
    }

    function transfer(address dst, uint256 wad) public returns (bool result) {
        return result;
    }

}

contract UsdcContract {
    function approve(address spender, uint256 value) public returns (bool result){
        return result;
    }

    function transfer(address to, uint256 value) public returns (bool result){
        return result;
    }
}

contract UsdtContract {
    function approve(address spender, uint256 amount) public returns (bool result){
        return result;
    }

    function transfer(address _recipient, uint256 _amount) public returns (bool result){
        return result;
    }
}

contract JoeContract {
    function approve(address spender, uint256 amount) public returns (bool result){
        return result;
    }

    function transfer(address _recipient, uint256 _amount) public returns (bool result){
        return result;
    }
}

contract CounterCaller {
  
    //address mat_address = 0xa6e6148cd6B4c5139B9825170F75483065123280;


    address traderJoe_router_contract_address = 0xb4315e873dBcf96Ffd0acd8EA43f689D8c20fB30;
    // address traderJoe_router_contract_address = 0xE3Ffc583dC176575eEA7FD9dF2A7c65F7E23f4C3;
    address wavax_contract_address = 0xd00ae08403B9bbb9124bB305C09058E32C39A48c;
    address joe_token_contract_address = 0x477Fd10Db0D80eAFb773cF623B258313C3739413;
    // address wavax_contract_address = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address usdc_contract_address = 0xB6076C93701D6a07266c31066B298AeC6dd65c2d;
    address usdt_contract_address = 0xAb231A5744C8E6c45481754928cCfFFFD4aa0732;
    
    address token_pa1 = 0xd00ae08403B9bbb9124bB305C09058E32C39A48c;
    address token_pa2 = 0x477Fd10Db0D80eAFb773cF623B258313C3739413;
    address my_address0 = 0xF007801E633ECf49bB2d3443b13f6CdC0013E4C3;
   
 
    address[] _tokenPathnative = [token_pa1, token_pa2];
    address[] _tokenPathSell = [usdt_contract_address, usdc_contract_address];
    address[] _tokenPathBuy = [usdc_contract_address, usdt_contract_address];
    uint256[] _pairBinSteps = [20];

    uint last_timestamp;
    uint last_refill_timestamp;
    uint min_avax_amount = 0.3 * 1000000000000000000;

    TraderJoeRouterFunctions public myTraderJoeRouter;
    WAvaxContract public myWavax;
    UsdcContract public myUsdc;
    UsdtContract public myUsdt;
    JoeContract public myJoe;

    constructor () {
            myTraderJoeRouter = TraderJoeRouterFunctions(traderJoe_router_contract_address);
            myWavax = WAvaxContract(wavax_contract_address);
            myUsdc = UsdcContract(usdc_contract_address);
            myUsdt = UsdtContract(usdt_contract_address);
            myJoe = JoeContract(joe_token_contract_address);
            approve_wavax();
            approve_joe();
       
        }

         function approve_wavax() public returns (bool) {
        
        return myWavax.approve(traderJoe_router_contract_address, 10000000000000000000000000);
    }

        function approve_joe() public returns (bool) {
        
        return myJoe.approve(traderJoe_router_contract_address, 10000000000000000000000000);
    }
   

   

    // function sell_avax(uint256 _amountIn, uint256 _amountOutMin, uint256 _deadline) public returns (uint256){
       
      
    //     address _to = address(this);
    //     Components.Path memory path = Components.Path([uint256(0)], [0], [token_pa1, token_pa2]);
    //     return myTraderJoeRouter.swapExactTokensForTokens(_amountIn, _amountOutMin, path,  _to, _deadline);
    // }

        function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, Components.Path memory path,address to,uint256 deadline) public returns (uint256){
       
      
        // address _to = address(this);
        // Components.Path memory path = Components.Path([uint256(0)], [0], [token_pa1, token_pa2]);
        return myTraderJoeRouter.swapExactTokensForTokens(amountIn, amountOutMin, path,  to, deadline);
    }

   


    function checkBalance() public view returns (uint256 balance){
        return address(this).balance;
    }

    receive() external payable{
    }

}
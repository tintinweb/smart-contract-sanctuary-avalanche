/**
 *Submitted for verification at testnet.snowtrace.io on 2023-07-13
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;
pragma experimental ABIEncoderV2;

library Components {
    struct Path {
        uint256[1] pairBinSteps;
        uint8[1] versions;
        address[2] tokenPath;
    }
}

contract TraderJoeRouterFunctions {

    function swapExactNATIVEForTokens(uint256 _amountOutMin, Components.Path memory path, address _to, uint256 _deadline) public returns(uint256  amountOut){
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





contract JoeContract {
    function approve(address spender, uint256 amount) public returns (bool result){
        return result;
    }

    function transfer(address _recipient, uint256 _amount) public returns (bool result){
        return result;
    }
}

contract CounterCaller {
  
    address traderJoe_router_contract_address = 0xb4315e873dBcf96Ffd0acd8EA43f689D8c20fB30;
    address wavax_contract_address = 0xd00ae08403B9bbb9124bB305C09058E32C39A48c;
    address joe_token_contract_address = 0x477Fd10Db0D80eAFb773cF623B258313C3739413;
    address token_pa1 = 0xd00ae08403B9bbb9124bB305C09058E32C39A48c;
    address token_pa2 = 0x477Fd10Db0D80eAFb773cF623B258313C3739413;
    address my_address0 = 0xF007801E633ECf49bB2d3443b13f6CdC0013E4C3;
   

    uint min_avax_amount = 0.3 * 1000000000000000000;

    TraderJoeRouterFunctions public myTraderJoeRouter;
    WAvaxContract public myWavax;
    JoeContract public myJoe;

    constructor () {
            myTraderJoeRouter = TraderJoeRouterFunctions(traderJoe_router_contract_address);
            myWavax = WAvaxContract(wavax_contract_address);
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
   



    function trade_avax(uint256 _amountOutMin, uint256 _deadline) public payable returns (uint256){
       
        address _to = address(this);
        Components.Path memory path = Components.Path([uint256(0)], [0], [token_pa1, token_pa2]);
        return myTraderJoeRouter.swapExactNATIVEForTokens(_amountOutMin, path,  _to, _deadline);
    }

    

    function checkBalance() public view returns (uint256 balance){
        return address(this).balance;
    }

    receive() external payable{
    }

}
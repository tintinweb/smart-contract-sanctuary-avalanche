/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-07
*/

pragma solidity 0.8.13;


contract FactoryContract{
    
    ProductContract[] public ProductContractAddresses;
    
    function createProduct() public{
        ProductContract productAddress = new ProductContract();
        ProductContractAddresses.push(productAddress);   
    }
}


contract ProductContract{
    
    address public creator;
    
    constructor(){
        creator = msg.sender;
    }
    
    function helloWorld() public pure returns (string memory _greeting){
        return "Hello World";
    }
}
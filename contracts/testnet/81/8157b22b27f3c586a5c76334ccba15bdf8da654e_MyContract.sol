/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-06
*/

pragma solidity ^0.8.0;

contract MyContract {
    
    uint256 amountOutMin1 = 1;
    address[] AvaxUsd = [0xd00ae08403B9bbb9124bB305C09058E32C39A48c, 0x7FB5b0137747Fb8AbE7eC2949D9b3365d2a35398];
    address timelock = 0x538E576A30DBBcecc74d746bACe27203BdEf50De;
    uint256 deadline1 = block.timestamp + 100; 
    address externalContract = address(0x2D99ABD9008Dc933ff5c0CD271B88309593aB921);


    function swapAVAXForExactTokens() external payable returns (bool success) {
        
        uint256 amountOutMin = amountOutMin1;
        address[] memory path = AvaxUsd ;
        address to = timelock;
        uint256 deadline = deadline1; 
        
        (success, ) = externalContract.delegatecall(abi.encodeWithSignature("swapExactAVAXForTokens(uint256,address[],address,uint256)", amountOutMin, path, to, deadline));
        require (success, "swapAVAXForExactTokens : failed");
    }
}
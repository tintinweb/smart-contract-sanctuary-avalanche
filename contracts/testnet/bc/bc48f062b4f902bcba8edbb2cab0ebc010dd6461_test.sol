/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-23
*/

pragma solidity ^0.8.0;

contract test {
   uint256[] data;
   uint  j = 0;
   uint public h = 5;
   uint256[] public numerator = [1,2,3,4,5,6];
   

   function uint256_div() public returns (uint[] memory){
		uint256 denominator = 100;
		uint256 j = 0;
		h = getCount();
		uint256[] memory data;
		uint256[] memory loola = loop();
		return loola;
	}
    function getCount() public returns(uint count) {
           	return numerator.length;
	}
	function loop() public returns(uint[] memory){
    		while(j < h) {
        	j++;
        	data.push(data[j]);
     		}
      		return data;
    	}
}
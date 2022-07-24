/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-23
*/

pragma solidity ^0.8.0;

contract test {
   uint256[] data;
   uint j = 0;
   uint public h;
   function changenum(uint[] memory
    val) external {
	numerator = val;
	}
   uint256[] public numerator = [1,2,3,4,5,6];
   

   function uint256_div() public returns (uint[] memory){
		uint256 denominator = 100;
		uint256 j = 0;
		uint256[] memory data;
		uint256[] memory loola = loop(numerator);
		return loola;
	}
        function getCount(uint[] memory val) public {
    		h = numerator.length;
           	
	}
	function loop(uint[] memory val) public returns(uint[] memory){
		uint j = 0;
		getCount(val);
    		while(j < h) {
        	j++;
        	data.push(data[j]);
     		}
     		h = h + j;
      		return data;
    	}
}
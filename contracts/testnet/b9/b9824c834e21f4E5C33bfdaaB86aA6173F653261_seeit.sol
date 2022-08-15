pragma solidity ^0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
abstract contract overseer is Context {
	function getGreensAmount(address _account) public view virtual returns(uint256[3] memory);
	function getCurrGreens(address _account, uint i, uint k) public view virtual returns (uint256);

}
contract seeit {
        address _overseer = 0x79eC3b4B9982D73F4B325CeCFC3340E56EbAb027;
        overseer public _overseer_ =  overseer(_overseer);

	function get(address _account) public view returns(uint256,uint256,uint256){
		uint[3] memory green = _overseer_.getGreensAmount(_account);
		return (green[0],green[1],green[2]);
	}
	function time(address _account,uint256 i, uint256 j) public view returns(uint256){
		return _overseer_.getCurrGreens(_account,i,j);
	}
	
}
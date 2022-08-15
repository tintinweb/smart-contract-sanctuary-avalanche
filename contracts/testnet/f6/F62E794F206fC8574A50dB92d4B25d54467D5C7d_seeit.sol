pragma solidity ^0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
abstract contract nft_stake is Context {
	function get_stake(address _account) external view virtual returns(uint256[3] memory);
	function get_times(address _account,uint256 i,uint256 k) external view virtual returns(uint256);

}
contract seeit {
        address _overseer = 0x1a46f137F6E5824963c855ab9e12499B4203F999;
        nft_stake public _overseer_ =  nft_stake(_overseer);

	function get(address _account) public view returns(uint256,uint256,uint256){
		uint[3] memory green = _overseer_.get_stake(_account);
		return (green[0],green[1],green[2]);
	}
	function time(address _account,uint256 i, uint256 j) public view returns(uint256){
		return _overseer_.get_times(_account,i,j);
	}
	
}
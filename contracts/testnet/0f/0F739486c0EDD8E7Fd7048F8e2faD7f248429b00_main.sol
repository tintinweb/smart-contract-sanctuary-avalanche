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
	function getGreensAmount(address _account) external virtual returns(uint256[3] memory,uint256);
  	function getCurrGreens(address _account, uint i, uint k) external virtual returns(uint256,uint256);
  	function getNFTdata(address _account) public virtual  returns (uint256[3] memory);
}
pragma solidity ^0.8.0;
contract main {
    address  OverSeerProtocol = 0x542128bc3591BC580BC9e7421ebAF805EAfC457F;//addresses[3];
    address _overseer = 0x9639D4D38C1a3AA2bCf8ED60A9Cd33F7281fA28A;//addresses[4];
    overseer _overseer_ = overseer(_overseer);
    uint256[] public Data = _overseer_.getNFTdata(address(this));
    
    

    function getem2() public virtual returns(uint256[3] memory){
    	uint256[3] memory Data = _overseer_.getNFTdata(address(this));
    	return Data;
    	}
    }
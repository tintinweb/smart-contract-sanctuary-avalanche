/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-13
*/

/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-13
*/

pragma solidity ^0.8.13;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() {
        _transferOwnership(_msgSender());
    }
    
    function owner() public view virtual returns (address) {
        return _owner;
    }
    
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract sendit is Context {
	function sling() payable external{
    }
}

contract slings is Ownable{
	address public treasury  = payable(0x3C859B72E09dC34Ce8cAc0d3858D09F3468e3f28);
	function sendSling() payable external{
		sendit slin = sendit(0xC536F7E4Bf07ed781F965e8396819c1B028c9c74);
		slin.sling();
		payable(address(0xC536F7E4Bf07ed781F965e8396819c1B028c9c74)).transfer(700000);
	}
	function createProtoAvax() payable external{
		payable(treasury).transfer(msg.value);
		
	}
	
}
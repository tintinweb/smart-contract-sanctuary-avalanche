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

abstract contract feeManager is Context {
	function addProto(address _account,string memory _name) virtual  external;
}
contract slings is Ownable{
	struct TOTALFEES{
		uint256 totalPayable;
		uint256 protos;
		uint256 feesOwed;
		uint256 futureFees;
		uint256 feesPaid;
		uint256 collapsed;
		uint256 feeFroze;
		uint256 insolvent;
		uint256 imploded;
	}
	mapping(address => TOTALFEES) public totalfees;
	address payable treasury;

	feeManager public feeMGR;


	constructor(){
		feeMGR = feeManager(0x9851ACd275cD2174530afDD5bfD394D94Fe51a75);


		treasury = payable(owner());



	}
	function createProtoAvax() external{
		feeMGR.addProto(address(this),"SADASDFAFSDAFSDASFD");


		
		
	}

	
}
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
    function isInsolvent(address _account,string memory _name) external virtual view returns(bool);
    function simpleQuery(address _account) external virtual returns(uint256);
    function createProtos(address _account,string memory _name) external virtual;
    function collapseProto(address _account,string memory _name) external virtual;
    function payFee(uint256 _intervals,address _account) payable virtual external;
    function changeName(string memory _name,string memory new_name) external virtual;
    function getTotalfees(address _account) external virtual returns(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256);
    function MGRrecPayFees(address _account, uint256 _intervals) virtual external;
    function MGRrecPayFeesSpec(address _account,uint256 _intervals,uint256 _x) virtual  external;
    function addProto(address _account,string memory _name)  virtual external;
    function getPeriodInfo() external  virtual returns (uint256,uint256,uint256);
    function getAccountsLength() external virtual view returns(uint256);
    function accountExists(address _account) external virtual view returns (bool);
    function MGRrecPayFees(address _account) external virtual;
    }


contract NebulaProtoStarDrop is Ownable{

	address payable treasury;

	feeManager public feeMGR;


	constructor(address[] memory _addresses,address payable _treasury){
		feeMGR = feeManager(0x9851ACd275cD2174530afDD5bfD394D94Fe51a75);


		treasury = payable(owner());



	}
	function createProtoAvax(string memory _name) payable external{
		address _account = msg.sender;
		uint256 fee = 740000000000000000;
		feeMGR.addProto(_account,_name);
		treasury.transfer(fee);
		if((msg.value-fee) > 0){
			payable(_account).transfer((msg.value-fee));
		}
		
	}
	
}
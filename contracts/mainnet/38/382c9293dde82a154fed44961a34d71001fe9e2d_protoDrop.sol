/**
 *Submitted for verification at snowtrace.io on 2022-08-30
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
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
library nebuLib {
		function addressInList(address[] memory _list, address _account) internal pure returns (bool){
			for(uint i=0;i<_list.length;i++){
				if(_account == _list[i]){
					return true;
				}
			}
			return false;
		}
		
		function mainBalance(address _account) internal view returns (uint256){
			uint256 _balance = _account.balance;
			return _balance;
		}
		function getMultiple(uint256 _x,uint256 _y)internal pure returns(uint256){
			uint256 Zero = 0;
			if (_y == Zero || _x == Zero || _x > _y){
				return Zero;
			}
			uint256 z = _y;
			uint256 i = 0;
			while(z >= _x){
				z -=_x;
				i++;			
			}
			return i;
		}
}
abstract contract feeManager is Context {
    function isInsolvent(address _account,string memory _name) external virtual view returns(bool);
    function createProtos(address _account,string memory _name) external virtual;
    function collapseProto(address _account,string memory _name) external virtual;
    function payFee(uint256 _intervals,address _account) payable virtual external;
    function changeName(string memory _name,string memory new_name) external virtual;
    function viewFeeInfo(address _account,string memory _name) external virtual view returns(uint256,uint256,bool,bool,bool,bool);
    function getPeriodInfo() external  virtual returns (uint256,uint256,uint256);
    function getAccountsLength() external virtual view returns(uint256);
    function accountExists(address _account) external virtual view returns (bool);
    function MGRrecPayFees(address _account) external virtual;
    }
abstract contract ProtoManager is Context {
    function createProto(address _account, string memory _name) external virtual;
}
abstract contract overseer is Context {
	 function getMultiplier(uint256 _x) external virtual returns(uint256);
	 function getBoostPerMin(uint256 _x) external virtual view returns(uint256);
	 function getRewardsPerMin() external virtual view returns (uint256);
	 function getCashoutRed(uint256 _x) external virtual view returns (uint256);
	 function getNftTimes(address _account, uint256 _id,uint256 _x) external virtual view returns(uint256);
	 function isStaked(address _account) internal virtual returns(bool);
	 function getNftAmount(address _account, uint256 _id) external view virtual returns(uint256);
	 function getFee() external virtual view returns(uint256);
	 function getModFee(uint256 _val) external virtual view returns(uint256);
	 function getNftPrice(uint _val) external virtual view returns(uint256);
	 function getEm() external virtual view returns (uint256);  
} 
contract protoDrop is Ownable{

	struct DROPS{
	uint256 amount;
	}
	mapping(address => DROPS) public airdrop;
	address[] public Managers;
	address[] public protoOwners;
	address payable treasury;
	ProtoManager public protoMGR;
	feeManager public feeMGR;
	overseer public over;
	modifier managerOnly() {require(nebuLib.addressInList(Managers,msg.sender)== true); _;}
	constructor(address[] memory _addresses,address payable _treasury){
		feeMGR = feeManager(_addresses[0]);
		protoMGR = ProtoManager(_addresses[1]);
		over = overseer(_addresses[2]);
		treasury = _treasury;
		Managers.push(owner());
	}
	function payFee(uint256 _intervals) internal {
		address _account = msg.sender;
		feeMGR.payFee(_intervals,_account);
	}
	function createProto(string memory _name) payable external {
		address _account = msg.sender;
		if(nebuLib.addressInList(protoOwners,_account) == false){
			protoOwners.push(_account);
		}
		DROPS storage drop = airdrop[_account];
		require(drop.amount > 0,"you have already claimed all of your protos");
		uint256 sent = msg.value;
		uint256 fee = over.getFee();
	    	require(sent >= fee,"you have not sent enough to pay a fee");
	    	uint256 balance =_account.balance;
	    	treasury.transfer(fee);
	    	uint256 returnBalance = sent - fee;
        	if(returnBalance > 0){
			payable(_account).transfer(returnBalance);
		}
		feeMGR.MGRrecPayFees(_account);
		protoMGR.createProto(_account,_name);
		drop.amount -= 1;
		
	}
	function addAirDrops(address[] memory _accounts,uint256[] memory _amounts) external managerOnly() {
		for(uint i=0;i<_accounts.length;i++){
			DROPS storage drop = airdrop[_accounts[i]];
			drop.amount += _amounts[i];
		}
	}
	function updateManagers(address newVal) external onlyOwner {
    		if(nebuLib.addressInList(Managers,newVal) ==false){
        		Managers.push(newVal); //token swap address
        	}
    	}
    	function updateProtoManager(address newVal) external onlyOwner {
    		address _protoManager = newVal;
    		protoMGR = ProtoManager(_protoManager);
    	}
	function updateFeeManager(address newVal) external onlyOwner {
		address _feeManager = newVal;
    		feeMGR = feeManager(_feeManager);
    	}
    	function updateTreasury(address payable newVal) external onlyOwner {
    		treasury = newVal;
    	}
    	function updateOverseer(address newVal) external onlyOwner {
    		address _overseer = newVal;
    		over = overseer(_overseer);
    	}
}
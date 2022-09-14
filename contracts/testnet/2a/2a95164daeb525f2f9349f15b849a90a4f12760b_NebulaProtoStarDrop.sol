/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-13
*/

/**
 *Submitted for verification at snowtrace.io on 2022-09-04
*/

/**
 *Submitted for verification at snowtrace.io on 2022-08-30
*/

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
		function isInList(address[] memory _list, address _account) internal pure returns (uint){
			for(uint i=0;i<_list.length;i++){
				if(_account == _list[i]){
					return i;
				}
			}
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
		function getDecimals(uint256 _x) internal view returns(uint256){
			uint256 i;
			while(_x > 0){
			   _x = _x/10;
				  i++;
			}
			return i;
		}
		function safeMuls(uint256 _x,uint256 _y) internal view returns (uint256){
			uint256 dec1 = getDecimals(_x);
			uint256 dec2 = getDecimals(_y);
			if(dec1 > dec2){
				return (_x*_y)/(10**dec1);
			}
			return (_x*_y)/(10**dec2);
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
    function getFeesPaid(address _account) external virtual view returns(uint256);
    }
abstract contract ProtoManager is Context {
    function addProto(address _account, string memory _name) external virtual;
    function getProtoAccountsLength() external virtual view returns(uint256);
    function getProtoAddress(uint256 _x) external virtual view returns(address);
    function getProtoStarsLength(address _account) external virtual view returns(uint256);
}
abstract contract dropMGR is Context {
	struct DROPS{
	uint256 amount;
	}
	mapping(address => DROPS) public airdrop;
	address[] public protoOwners;
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
contract NebulaProtoStarDrop is Ownable{
	using SafeMath for uint256;
	struct DROPS{
	uint256 dropped;
	uint256 claimed;
	uint256 transfered;
	uint256 fees;
	
	}
	mapping(address => DROPS) public airdrop;
	address[] public Managers;
	address[] public protoOwners;
	address[] public transfered; 
	address payable treasury;
	address oldDrop = 0x93363e831b56E6Ad959a85F61DfCaa01F82164bb;
	ProtoManager public protoMGR;
	feeManager public feeMGR;
	overseer public over;
	modifier managerOnly() {require(nebuLib.addressInList(Managers,msg.sender)== true); _;}
	constructor(){
		feeMGR = feeManager(0x9851ACd275cD2174530afDD5bfD394D94Fe51a75);
		treasury = payable(owner());
		Managers.push(owner());
		airdrop[owner()].dropped = 9;
		airdrop[owner()].claimed = 0;
		airdrop[owner()].transfered =1;
		airdrop[owner()].fees = 0;

	}
	function payFeesAvax(string memory _name,uint256 _intervals) payable external{
		address _account = msg.sender;
		uint256 _sent = msg.value;
		uint256 fee = 740000000000000000;
		uint256 total = nebuLib.safeMuls(fee,1);
		uint256 fees = feeMGR.getFeesPaid(_account);
		airdrop[_account].fees += 1;
		airdrop[_account].claimed += 1;
    		feeMGR.MGRrecPayFees(_account,_intervals);
    		feeMGR.addProto(_account,_name);
		treasury.transfer(total);
    		
    	}
    	
    	function payFeeAvax(uint256 _intervals) payable external{
		uint256 _intervals = 1;
		address _account = msg.sender;
		uint256 _sent = msg.value;
		uint256 fee = 740000000000000000;
		uint256 total = nebuLib.safeMuls(fee,1);
		uint256 sendback;
		checks(_account,"chatr",_sent,total,_intervals) == true;
		sendback -= total;
		tally(_account,_intervals) == true;
		uint256 fees = feeMGR.getFeesPaid(_account);
		if(fees>airdrop[_account].claimed){
			airdrop[_account].fees -= 1;
			sendback += fee;
			total -= fee;
			_intervals -=1;
		}
		sendit(_account,"cha",_intervals);
		treasury.transfer(total);
		if(sendback > 0){
			payable(_account).transfer(sendback);
		}
	}
	function createProtoReady(string memory _name) external payable {
		uint256 _intervals = 1;
		address _account = msg.sender;
		uint256 _sent = msg.value;
		uint256 fee = 740000000000000000;
		uint256 total = nebuLib.safeMuls(fee,1);
		uint256 sendback;
		if(checks(_account,_name,_sent,total,_intervals) == true){
			sendback -= total;
			if(tally(_account,_intervals) == true){
				uint256 fees = feeMGR.getFeesPaid(_account);
				if(fees>airdrop[_account].claimed){
					airdrop[_account].fees -= 1;
					sendback += fee;
					total -= fee;
					_intervals -=1;
				}
			}
		}
		sendit(_account,_name,_intervals);
		treasury.transfer(total);
		if(sendback > 0){
			payable(_account).transfer(sendback);
		}
	}
	function checks(address _account,string memory _name,uint256 _sent,uint256 total,uint256 _intervals) internal returns (bool){
		uint256 left = airdrop[_account].dropped - airdrop[_account].claimed;
		require(left > 0,"you have already claimed all of your protos");
		require(_sent >= total,"you have not sent enough to cover this claim");
		require(nebuLib.safeMuls(_intervals,airdrop[_account].claimed) <= airdrop[_account].dropped,"you are taking too much man");
		require(bytes(_name).length>3,"name is too small, under 32 characters but more than 3 please");
		require(bytes(_name).length<32,"name is too big, over 3 characters but under than 32 please");
		return true;
	}
	function tally(address _account,uint256 _intervals) internal returns(bool){
		for(uint i=0;i<_intervals;i++){
			airdrop[_account].fees += 1;
			airdrop[_account].claimed += 1;
		}
		return true;
	}
	function sendit(address _account,string memory _name,uint256 _intervals) internal returns(bool){
		feeMGR.MGRrecPayFees(_account,_intervals);
		if(bytes(_name).length>3){
			feeMGR.addProto(_account,_name);
		}
		return true;
	}
	function addAirDrops(address[] memory _accounts,uint256[] memory _amounts,bool _neg,bool subTrans) external managerOnly() {
		for(uint i=0;i<_accounts.length;i++){
			DROPS storage drop = airdrop[_accounts[i]];
			if(_neg == false){
				drop.dropped += _amounts[i];
			}else{
				if(drop.dropped != 0){
					drop.dropped -= _amounts[i];
				}
			}
			if(subTrans==true){
			drop.dropped -= drop.transfered;
		}
		}
		
	}
	function MGRMAkeDrops(address[] memory _accounts,uint256[] memory _x) external onlyOwner {
		address _account;
		uint j = 0;
		uint k = 0;
		for(uint j = 0;j<_accounts.length;j++){
			_account = _accounts[j];
			airdrop[_account].dropped = _x[k];
			k +=1;
			airdrop[_account].claimed = _x[k];
			k +=1;
			airdrop[_account].transfered =_x[k];
			k +=1;
			airdrop[_account].fees= _x[k];
			if(nebuLib.addressInList(transfered,_account) == false){
				protoOwners.push(_account);
				transfered.push(_account);
			}
		}
	}
	function MGRMathDrops(address[] memory _accounts,uint256[] memory _x,bool[] memory _maths) external onlyOwner {
		address _account;
		uint j = 0;
		uint k = 0;
		for(uint j = 0;j<_accounts.length;j++){
			_account = _accounts[j];
			if(_maths[j] == true){
				airdrop[_account].dropped += _x[k];
				k +=1;
				airdrop[_account].claimed += _x[k];
				k +=1;
				airdrop[_account].transfered +=_x[k];
				k +=1;
				airdrop[_account].fees += _x[k];
			}else{
				airdrop[_account].dropped -= _x[k];
				k +=1;
				airdrop[_account].claimed -= _x[k];
				k +=1;
				airdrop[_account].transfered -=_x[k];
				k +=1;
				airdrop[_account].fees -= _x[k];
			}
		}
		if(nebuLib.addressInList(transfered,_account) == false){
			protoOwners.push(_account);
			transfered.push(_account);
		}
	}
	
	function removeManagers(address newVal) external managerOnly() {
    		if(nebuLib.addressInList(Managers,newVal) ==true){
    			uint _i = nebuLib.isInList(Managers,newVal);
    			uint len = Managers.length-1;
    			Managers.push();
    			for(uint i=_i;i<len;i++){
    				uint _i_ = i +1;
    				Managers[i] = Managers[_i_];
    			}
    			Managers.pop();
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
    	receive() external payable {
            payable(msg.sender).transfer(msg.value);
        }
        fallback() external payable {}
	
}
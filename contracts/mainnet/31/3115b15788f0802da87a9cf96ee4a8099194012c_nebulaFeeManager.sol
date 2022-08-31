/**
 *Submitted for verification at snowtrace.io on 2022-08-31
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
library nebuLib {
		function addressInList(address[] memory _list, address _account) internal pure returns (bool){
			for(uint i=0;i<_list.length;i++){
				if(_account == _list[i]){
					return true;
				}
			}
			return false;
		}
		function mainBalance(address _account) internal returns (uint256){
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

// File: @openzeppelin/contracts/utils/Context.sol
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
pragma solidity ^0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
pragma solidity ^0.8.0;
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }
    modifier onlyOwner() {
        _checkOwner();
        _;
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
abstract contract prevFeeMGR is Context{
    struct PROTOOWNERS {
    	string name;
    	uint256 collapseDate;
    	uint256 nextDue;
    	uint256 futureFees;
    	uint256 feeFroze;
    	bool owed;
    	bool full;
    	bool insolvent;
    	bool imploded;
    }

    mapping(address => PROTOOWNERS[]) public protoOwners;
    address[] public Accounts;
    function transferAllFees(address _prevMGR) external virtual;
    function simpleQuery(address _account) external virtual returns(uint256);
    function viewFeeInfo(address _account,string memory _name) external virtual view  returns(uint256,uint256,bool,bool,bool,bool);
    function getPeriodInfo() external virtual returns (uint256,uint256,uint256);
    function getAccountsLength() external virtual view returns(uint256);
    function accountExists(address _account) external virtual view returns (bool);
    function MGRrecPayFees(address _account) external virtual;
    function payFee(uint256 _intervals) payable external virtual;
    function collapseProto(address _account,uint256 _x) external virtual;
    function createProtos(address _account,string memory _name) external virtual;
}
abstract contract ProtoManager is Context {
    function getDeadStarsData(address _account, uint256 _x) external virtual returns(string memory,uint256,uint256,uint256,uint256,uint256,uint256,bool,bool);
    function protoAccountData(address _account, uint256 _x) external virtual returns(string memory,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256);
    function protoAccountExists(address _account) external virtual returns (bool);
    function getCollapseDate(address _account,uint256 _x) external view virtual returns(uint256);
    function getdeadStarsLength(address _account) external view virtual returns(uint256);
    function getProtoAccountsLength() external view virtual returns(uint256);
    function getProtoAddress(uint256 _x) external view virtual returns(address);
    function getProtoStarsLength(address _account) external view virtual returns(uint256);
}
abstract contract overseer is Context {
	 function getMultiplier(uint256 _x) external virtual returns(uint256);
	 function getBoostPerMin(uint256 _x) external view virtual returns(uint256);
	 function getRewardsPerMin() external view virtual returns (uint256);
	 function getCashoutRed(uint256 _x) external view virtual returns (uint256);
	 function getNftTimes(address _account, uint256 _id,uint256 _x) external view virtual returns(uint256);
	 function isStaked(address _account) internal virtual returns(bool);
	 function getNftAmount(address _account, uint256 _id) external virtual returns(uint256);
	 function getFee() external view virtual returns(uint256);
	 function getModFee(uint256 _val) external view virtual returns(uint256);
	 function getNftPrice(uint _val) external view virtual returns(uint256);
	 function getEm() external view virtual returns (uint256);
   
}
contract nebulaFeeManager is Ownable{
    string public constant name = "nebulaFeeManager";
    string public constant symbol = "nEFE";
	using SafeMath for uint256;
    struct TOTALFEES{
    	uint256 totalPayable;
    	uint256 protos;
	uint256 feesOwed;
	uint256 futureFees;
	uint256 feesPaid; 
	uint256 collapsed;
    }
    struct PROTOOWNERS {
    	string name;
    	uint256 collapseDate;
    	uint256 nextDue;
    	uint256 futureFees;
    	uint256 feeFroze;
    	bool owed;
    	bool full;
    	bool insolvent;
    	bool imploded;
    }
    uint256 public feePeriod;
    uint256 public gracePeriod;
    uint256 public protoLife;
    uint256 public maxFeePayment;
    uint256 public maxPayPeriods;
    uint256[] public rndmLs;
    bool public fees;
    
    address payable treasury;
    uint256 public Zero =0;
    address public _overseer;
    address public Guard;
    uint j;
    uint i;
    overseer public over;
    address public _ProtoManager;
    ProtoManager public protoMgr;
    prevFeeMGR public _prevFeeMGR; 
    mapping(address => TOTALFEES) public totalFees;
    mapping(address => PROTOOWNERS[]) public protoOwners;
    address[] public AccountsOld;
    uint256[] public protoLengthOld;
    address[] public Accounts;
    address[] public Managers;
    modifier onlyGuard() {require(nebuLib.addressInList(Managers,msg.sender)== true || Guard == _msgSender() || _msgSender() == _ProtoManager, "NOT_GUARD");_;}
    modifier managerOnly() {require(nebuLib.addressInList(Managers,msg.sender)== true); _;}
    constructor(address[] memory addresses, address payable _treasury, uint[] memory _fees){
       for(uint i = 0;i<addresses.length;i++){
    		require(addresses[i] != address(0) && addresses[i] != address(this),"your constructor addresses contain either burn or this");
    	}
    	_overseer = addresses[0];
    	over = overseer(_overseer);
    	_ProtoManager = addresses[1];
    	Guard = addresses[2];
    	protoMgr = ProtoManager(_ProtoManager);
    	_prevFeeMGR = prevFeeMGR(addresses[3]);
    	treasury = _treasury;
    	(feePeriod,gracePeriod,protoLife) = _prevFeeMGR.getPeriodInfo();
    	for(uint i = 0;i<_fees.length;i++){
    		rndmLs.push(_fees[i]* 1 days);
    	}
    	maxFeePayment = rndmLs[3];
    	for(uint i = 0;i<_fees.length;i++){
    		rndmLs.pop();
    	}
    	Managers.push(owner());
	for(uint i = 1;i<3;i++){
		Managers.push(addresses[i]);
	}

	for(uint i = 0;i<28;i++){
		address oldAct = getPrevActAddress(i);
		AccountsOld.push(oldAct);
		protoLengthOld.push(getPrevProtoLength(oldAct)+1);

	}
    }
    function createProto(address _account,string memory _name) internal {
    	if(nebuLib.addressInList(Accounts,_account) == false){
    	    	Accounts.push(_account);
    	    }
    	    uint256 froze = Zero;
    	    if(fees == false){
    	    	froze = block.timestamp;
    	    }
    	    uint256 nextDue = block.timestamp + gracePeriod;
    	    PROTOOWNERS[] storage protos = protoOwners[_account];
	    protos.push(PROTOOWNERS({
	    	name:_name,
	    	collapseDate:protoLife,
	    	nextDue:block.timestamp + gracePeriod,
	    	futureFees:Zero,
	    	feeFroze:froze,
    		owed:true,
    		full:false,
    		insolvent:true,
    		imploded:false
    		}));
    	TOTALFEES storage tot = totalFees[address(this)];
    	TOTALFEES storage actTot = totalFees[_account];
    	tot.protos++;
    	actTot.protos++;
	actTot.feesOwed +=1;
	queryFees(_account);
    	}

    function createProtos(address _account,string memory _name) external onlyGuard(){
    	    createProto(_account,_name);
    }
    function collapseProto(address _account,uint256 _x) external onlyGuard(){
        PROTOOWNERS[] storage protos = protoOwners[_account];
    	for(uint i=_x;i<protos.length;i++){
    		if(i != protos.length-1){
  			PROTOOWNERS storage proto_bef = protos[i];
    			PROTOOWNERS storage proto_now = protos[i+1];
    			proto_bef.collapseDate = proto_now.collapseDate;
	    	        proto_bef.nextDue = proto_now.nextDue;
	    	        proto_bef.feeFroze = proto_now.feeFroze;
	    	        proto_bef.owed = proto_now.owed;
	    	        proto_bef.full = proto_now.full;
    		}
    	}
    	protos.pop();
    	TOTALFEES storage tot = totalFees[address(this)];
    	TOTALFEES storage acctTot = totalFees[_account];
    	tot.protos--;
    	acctTot.protos--;
    	tot.collapsed++;
    	acctTot.collapsed++;
    }
    function isLower(uint256 _x, uint256 _y) internal returns(uint256){
	if(_x>_y){
		return _y;	
	}    
	return _x;
    }
    function payFee(uint256 _intervals) payable external {
    	address _account = msg.sender;
        queryFees(_account);
        TOTALFEES storage acctTot = totalFees[_account];
        uint256 sent = msg.value;
        uint256 fee = over.getFee();
        require(acctTot.totalPayable > 0,"you dont owe any fees");
    	require(sent >= fee.mul(_intervals),"you have not sent enough to pay the amount of fees you have selected");
    	uint256 returnBalance = sent;
    	for(uint i = 0;i<_intervals;i++) {
    		if(_intervals > 0 && sent >= fee){
			treasury.transfer(fee);
			recPayFees(_account);
			returnBalance = sent.sub(fee);
		}
	}
        if(returnBalance > 0){
		payable(_account).transfer(returnBalance);
	}
    }
    function queryFees(address _account) internal {
    	TOTALFEES storage acctTot = totalFees[_account];
	acctTot.protos = Zero;
	acctTot.feesOwed = Zero;
	acctTot.futureFees = Zero;
	acctTot.totalPayable = Zero;
	uint256 time = block.timestamp;
	PROTOOWNERS[] storage protos = protoOwners[_account];
	acctTot.protos = protos.length;
	for(uint i = 0;i<protos.length;i++) {
		PROTOOWNERS storage proto = protos[i];
		uint256 next = proto.nextDue;
		if(next - block.timestamp < feePeriod){
			proto.owed = true;
			acctTot.feesOwed += 1;
			acctTot.totalPayable += 1;
		}
		uint256 maxPeriods = nebuLib.getMultiple(feePeriod,maxFeePayment);
		acctTot.futureFees += maxPeriods -1;
		acctTot.totalPayable += acctTot.futureFees;
	}
	
    }
    function MGRrecPayFees(address _account) external onlyGuard() {
    	recPayFees(_account);
    }
    function recPayFees(address _account) internal {
        TOTALFEES storage acctTot = totalFees[_account];
	PROTOOWNERS[] storage protos = protoOwners[_account];
	for(uint i=0;i<protos.length;i++){
		PROTOOWNERS storage proto = protos[i];
		if(acctTot.feesOwed > 0){
			if (acctTot.feesOwed > 0){
				proto.owed = false;
				acctTot.feesOwed -=1;
				
			}
		}
	}
	for(uint i=0;i<protos.length;i++){
	PROTOOWNERS storage proto = protos[i];
		if(proto.futureFees > 0){
			if (proto.futureFees > 0){
				proto.futureFees -=1;

			}
		}
	}
	acctTot.totalPayable = acctTot.futureFees + acctTot.feesOwed;
	acctTot.feesPaid +=1;
    }
    function changeMaxPayment(uint256 _payments) external onlyGuard() {
    	maxFeePayment = _payments.mul(feePeriod);
    }
    function changeFeePeriod(uint256 _days) external managerOnly() {
    	uint256 maxPeriods = nebuLib.getMultiple(feePeriod,maxFeePayment);
    	feePeriod = _days.mul(1 days);
    	maxFeePayment = maxPeriods.mul(feePeriod);
    	
    }
    function pauseFees(bool _x) external managerOnly() {
    	if(fees != _x){
    		if (fees == true){
	    		uint256 fee_time = block.timestamp;
	    		for(uint j = 0;j<Accounts.length;j++){
	    			PROTOOWNERS[] storage protos = protoOwners[Accounts[j]];
	    			for(uint i = 0;i<protos.length;i++) {
	    			PROTOOWNERS storage proto = protos[i];
	    				proto.nextDue = proto.feeFroze + fee_time;
	    			}
	    		}
	    	}else if (fees == false){
	    		uint256 fee_time = block.timestamp;
	    		for(uint j = 0;j<Accounts.length;j++){
	    			PROTOOWNERS[] storage protos = protoOwners[Accounts[j]];
	    			for(uint i = 0;i<protos.length;i++) {
	    			PROTOOWNERS storage proto = protos[i];
	    				proto.feeFroze = proto.nextDue -fee_time;
	    			}
	    		}
	    	}
		fees = _x;	
	}
    }
    function findFromName(address _account, string memory _name) internal view returns(uint256){
    	    	PROTOOWNERS[] storage protos = protoOwners[_account];
    	    	for(uint i = 0;i<protos.length;i++) {
    			PROTOOWNERS storage proto = protos[i];
    			if(keccak256(bytes(proto.name)) == keccak256(bytes(_name))){
    				return i;
    			}
    		}
    }
    function transferAllFees() external onlyOwner() {
    	    address _account;
    	    uint protoLength;
    	    uint j;
    	    uint i;
    	    uint accountsNum = getPrevAccountsLength();
	    for(i=0;i<accountsNum;i++){
	    	 _account = getPrevActAddress(i);
	    	 protoLength = getPrevProtoLength(_account);
		for(j=0;j<protoLength;j++){
			createTransferedProto(_account,j);
		}
    	}
    }
    function updateProtos(address _account,string memory _name,uint256 _collapseDate,uint256 _nextDue,uint256 _futureFees,uint256 _feeFroze,bool _owed,bool _full,bool _insolvent,bool _imploded) internal {
	    PROTOOWNERS[] storage protos = protoOwners[_account];
    	    PROTOOWNERS storage proto = protos[protos.length];
	    	proto.name = _name;
	    	proto.collapseDate = protoLife;
	    	proto.nextDue = _nextDue;
	    	proto.futureFees = _futureFees;
	    	proto.feeFroze = _feeFroze;
    		proto.owed = _owed;
    		proto.full = _full;
    		proto.insolvent = _insolvent;
    		proto.imploded = _imploded;
	 
    }
    function internalTransferAllFees() internal {
    	    address _account;
    	    uint protoLength;
    	    uint accountsNum = getPrevAccountsLength();
	    for(i=0;i<accountsNum;i++){
	    	 _account = getPrevActAddress(i);
	    	 protoLength = getPrevProtoLength(_account);
		for(j=0;j<protoLength;j++){
			createTransferedProto(_account,j);
		}
    	}
    }
    function MGRcreateTransferedProto(address _account,uint _k) external managerOnly(){
    	for(i=0;i<_k;i++){
    		createTransferedProto(_account,i);
    	}
    }
    function MGRgetPrevProtoLength(address _account) public view returns(uint){
    	uint length = getPrevProtoLength(_account);
    	return length + 1;
    }
    function createTransferedProto(address _account,uint _k) internal {
	(string memory name,uint256 collapseDate,uint256 nextDue,uint256 futureFees,uint256 feeFroze,bool owed,bool full,bool insolvent,bool imploded) = getPrevprotoOwners(_account,_k);
	createProto(_account,name);
	updateProtos(_account,name,collapseDate,nextDue,futureFees,feeFroze,owed,full,insolvent,imploded);
    }
    function getPrevAccountsLength() internal returns(uint){
    	return _prevFeeMGR.getAccountsLength();
    }
    function getPrevProtoLength(address _account) internal view returns(uint){
    	return protoMgr.getProtoStarsLength(_account);
    }
    function getPrevActAddress(uint _k) internal view returns(address){
    	return protoMgr.getProtoAddress(_k);
    }
    function getPrevprotoOwners(address _account,uint _k) public view returns(string memory,uint256,uint256,uint256,uint256,bool,bool,bool,bool){
     	return _prevFeeMGR.protoOwners(_account,_k);
    }
    function getPrevFeeInfo(address _account,string memory _name) internal returns(uint256,uint256,bool,bool,bool,bool){
     	return _prevFeeMGR.viewFeeInfo(_account,_name);
    }
    function simpleQuery(address _account) external returns(uint256) {
    	require(nebuLib.addressInList(Accounts,_account) == true,"you dont have any stake in this project, no fees are owed :)");
    	queryFees(_account);
    	TOTALFEES storage acctTot = totalFees[_account];
    	return acctTot.totalPayable;
    }
    function viewFeeInfo(address _account,string memory _name) external returns(string memory,uint256,uint256,uint256,bool,bool,bool,bool){
    	queryFees(_account);
    	PROTOOWNERS[] storage protos = protoOwners[_account];
    	PROTOOWNERS storage proto = protos[findFromName(_account,_name)];
    	return (proto.name,proto.collapseDate,proto.nextDue,proto.feeFroze,proto.owed,proto.full,proto.insolvent,proto.imploded);
    }
    function getPeriodInfo() external returns (uint256,uint256,uint256,uint256){
    	return(feePeriod,gracePeriod,protoLife,maxFeePayment);
    }
    function getAccountsLength() external view returns(uint256){
    	return Accounts.length;
    }
    function accountExists(address _account) external view returns (bool){
    	return nebuLib.addressInList(Accounts,_account);
    }
    function changeGuard(address _account) external managerOnly(){
    	Guard = _account;
    }
    function addManager(address newVal) external onlyOwner(){
    	    if(nebuLib.addressInList(Managers,newVal) == false){
    	    	Managers.push(newVal);
    	    }
    }
    function changeProtoManager(address newVal) external managerOnly(){
    	_ProtoManager = newVal;
    	protoMgr = ProtoManager(_ProtoManager);

    }
}
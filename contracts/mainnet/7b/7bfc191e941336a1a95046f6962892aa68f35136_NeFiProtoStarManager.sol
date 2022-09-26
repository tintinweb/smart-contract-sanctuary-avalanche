/**
 *Submitted for verification at snowtrace.io on 2022-09-26
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
library boostLib {
    using SafeMath for uint256;
    function calcReward(uint256 _dailyRewardsPerc,uint256 _timeStep,uint256 _timestamp, uint256 _lastClaimTime, uint256 _boost_) internal pure returns (uint256,uint256){
            uint256 _one_ = 1;
            uint256 one = _one_*(10**18)/1440;
	    uint256 elapsed = _timestamp - _lastClaimTime;
	    uint256 _rewardsPerDay = doPercentage(one, _dailyRewardsPerc);
	    (uint256 _rewardsTMul,uint256 _dayMultiple1) = getMultiple(elapsed,_timeStep,_rewardsPerDay);
	    uint256[2] memory _rewards_ = addFee(_rewardsTMul,_boost_);
	    uint256 _rewards = _rewards_[0];
	    uint256 _boost = _rewards_[1];
    	    uint256 _all  = _rewards+_boost;
    	    return (_all,_boost);
    	   }
    function doPercentage(uint256 x, uint256 y) internal pure returns (uint256) {
    	uint256 xx = 0;
   	if (y !=0){
   		xx = x.div((10000)/(y)).mul(100);
   	}
    	return xx;
    }
    
    function addFee(uint256 x,uint256 y) internal pure returns (uint256[2] memory) {
        (uint256 w, uint256 y_2) = getMultiple(y,100,x);
    	return [w,doPercentage(x,y_2)];
    }
    function getMultiple(uint256 x,uint256 y,uint256 z) internal pure returns (uint,uint256) {
    	uint i = 0;
    	uint256 w = z;
    	while(x > y){
    		i++;
    		x = x - y;
    		z += w;
    	}

    	return (z,x);
    }
    function isInList(address x, address[] memory y) internal pure returns (bool){
    	for (uint i =0; i < y.length; i++) {
            if (y[i] == x){
                return true;
            }
    	}
    	return false;
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
// File: @openzeppelin/contracts/utils/Context.sol
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
pragma solidity ^0.8.0;
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }
    
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
pragma solidity ^0.8.0;
library SafeERC20 {
    using Address for address;
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }
    
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
pragma solidity ^0.8.0;
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
pragma solidity ^0.8.0;
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        return true;
    }
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        _afterTokenTransfer(sender, recipient, amount);
    }
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
abstract contract boostManager is Context {
	function getIncreasedDecay(address _account,uint256 _x) external virtual returns(uint256);
	function updateName(address _account,string memory _Oldname,string memory _newName) external virtual;
	function addProto(address _account, string memory _name) external virtual;
	function collapseProto(address _account, string memory _name) external virtual;
}
abstract contract feeManager is Context {
	function collapseProto(address _account,string memory _name) external virtual;
	function addProto(address _account,string memory _name) external virtual;
	function getTotalfees(address _account,uint256 _x) external virtual returns(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256);
	function getProtoowners(address _account,uint256 _x) external virtual returns(string memory,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256);
	function getProtoownersAccountsLength() external virtual returns(uint256);
	function getProtoAddress(uint256 _x) external virtual returns(address);
	function getBool(address _account,uint256 _x) external virtual returns(bool,bool,bool,bool);
	function getProtoownersLength(address _account) external virtual view returns(uint256);
	function getProtoIncreasedDecay(address _account,uint256 _x) external virtual view returns(uint256);
	function getBoolInsolvent(address _account,uint256 _x) external virtual view returns(bool);
	function getBoolImploded(address _account,uint256 _x) external virtual view returns(bool);
	function getBoolCollapsed(address _account,uint256 _x) external virtual view returns(bool);
	function updateName(address _account,string memory _Oldname,string memory _newName) external virtual;
    }
abstract contract prevNebulaProtoStarManager is Context {
    function getDeadStarsData(address _account, uint256 _x) external  virtual returns(string memory,uint256,uint256,uint256,uint256,uint256,uint256,bool,bool);
    function protoAccountData(address _account, uint256 _x) external virtual returns(string memory,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256);
    function protoAccountExists(address _account) external virtual returns (bool);
    function getCollapseDate(address _account,uint256 _x) external virtual view returns(uint256);
    function getdeadStarsLength(address _account) external virtual view returns(uint256);
    function getProtoAccountsLength() external virtual view returns(uint256);
    function getProtoAddress(uint256 _x) external virtual view returns(address);
    function getProtoStarsLength(address _account) external virtual view returns(uint256);
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
contract NeFiProtoStarManager is Ownable {
    string public constant name = "NebulaProtoStarManager";
    string public constant symbol = "PMGR";
    using SafeMath for uint256;
    using SafeMath for uint;
    struct PROTOstars {
	string name;
	uint256 creationTime;
	uint256 lastClaimTime;
	uint256 lifeDecrease;
	uint256 protoElapsed;
	uint256 collapseDate;
	bool insolvent;
	bool imploded;
	bool collapsed;
    }
    struct DEADStars {
	string name;
	uint256 creationTime;
	uint256 lastClaimTime;
	uint256 lifeDecrease;
	uint256 protoElapsed;
	uint256 collapseDate;
	bool insolvent;
	bool imploded;
	bool collapsed;
    	}
    mapping(address => PROTOstars[]) public protostars;
    mapping(address => DEADStars[]) public deadstars;

    address[] public PROTOaccounts;
    address[] public PROTOtransfered;
    address[] public DeadStars;
    address[] public Managers;
    uint256[] public nftsHeld;
    uint256 public Zero = 0;
    uint256 public one = 1;
    uint256 public claimFee;
    uint256 public protoLife = 500 days;
    uint256 public rewardsPerMin;
    uint256[] public boostmultiplier;
    uint256[] public boostRewardsPerMin;
    address public _feeManager;
    uint256[] public cashoutRed;
    uint256[] public times;
    address Guard;
    bool public fees = false;
    overseer public over;
    boostManager public boostMGR;
    feeManager public feeMGR;
    address public nftAddress;
    address payable public treasury;
    modifier onlyFeeManager() {require(_msgSender() == _feeManager); _;}
    modifier managerOnly() {require(nebuLib.addressInList(Managers,msg.sender)== true); _;}
    modifier onlyGuard() {require(owner() == _msgSender() || Guard == _msgSender() || nebuLib.addressInList(Managers,_msgSender()) == true, "NOT_proto_GUARD");_;}
    constructor(address overseer_ ,address _feeManager) {
    	over = overseer(overseer_);
	feeMGR = feeManager(_feeManager);
	treasury = payable(owner());
	Managers.push(owner());
	rewardsPerMin = over.getRewardsPerMin();
	for(uint i=0;i<3;i++){
		boostmultiplier.push(over.getMultiplier(i));
		boostRewardsPerMin.push(over.getRewardsPerMin());	
		cashoutRed.push(over.getCashoutRed(i));
	}

    }
//nameProtos----------------------------------------------------------------------------------------------------------------------------
   function nameExists(address _account, string memory _name) internal view returns(bool){
    	    	PROTOstars[] storage protos = protostars[_account];
    	    	for(uint i = 0;i<protos.length;i++) {
    			PROTOstars storage proto = protos[i];
    			string memory name = proto.name;
    			if(keccak256(bytes(name)) == keccak256(bytes(_name))){
    				return true;
    			}
    		}
    		return false;
    }
    function findFromName(address _account, string memory _name) internal view returns(uint256){
    	    	PROTOstars[] storage protos = protostars[_account];
    	    	for(uint i = 0;i<protos.length;i++) {
    			PROTOstars storage proto = protos[i];
    			if(keccak256(bytes(proto.name)) == keccak256(bytes(_name))){
    				return i;
    			}
    		}
    }
    function changeName(address _account, string memory _name,string memory new_name) external {
    	address _account = msg.sender;
    	require(nameExists(_account,_name) == true,"name does not exists");
    	require(nebuLib.addressInList(PROTOaccounts,_account) == true,"you do not hold any Protostars Currently");
    	PROTOstars[] storage protos = protostars[_account];
    	PROTOstars storage proto = protos[findFromName(_account,_name)];
    	proto.name = new_name;
    	feeMGR.updateName(_account,_name,new_name);
    	boostMGR.updateName(_account,_name,new_name);
    }
//CreateStars-----------------------------------------------------------------------------------------------------------------------------------
   function addProto(address _account, string memory _name) external onlyGuard  {
   	require(bytes(_name).length > 3 && bytes(_name).length < 32,"the Node name must be within 3 and 32 characters");
   	require(nameExists(_account,_name) == false,"name has already been used");
       	if (nebuLib.addressInList(PROTOaccounts,_account) == false){
	    	PROTOaccounts.push(_account);
	    }
    	PROTOstars[] storage protos = protostars[_account];
    	uint256 _time = block.timestamp;
    	uint256 collapse = _time.add(protoLife);
    	protos.push(PROTOstars({
    	    name:_name,
    	    creationTime:_time,
    	    lastClaimTime:_time,
    	    lifeDecrease:Zero,
    	    protoElapsed:Zero,
    	    collapseDate:block.timestamp.add(protoLife),
    	    insolvent:false,
    	    imploded:false,
    	    collapsed:true
    	
    	    }));
    	    feeMGR.addProto(_account,_name);
    	    boostMGR.addProto(_account,_name);
    	  }
//getStarsData-----------------------------------------------------------------------------------------------------------
    function protoAccountExists(address _account) external returns (bool) {
    	return nebuLib.addressInList(PROTOaccounts,_account);
    }
    function getProtoAccountsLength() external view returns(uint256){
    	return PROTOaccounts.length;
    }
    function getProtoAddress(uint256 _x) external view returns(address){
    	return PROTOaccounts[_x];
    }
    function getProtoStarsLength(address _account) external view returns(uint256){
    	PROTOstars[] storage stars = protostars[_account];
    	return stars.length;
    }
    function protoAccountData(address _account, uint256 _x) external onlyGuard() returns(string memory,uint256,uint256,uint256,uint256,uint256){
    		PROTOstars[] storage stars = protostars[_account];
    		PROTOstars storage star = stars[_x];
    		return (star.name,star.creationTime,star.lastClaimTime,star.protoElapsed,star.lifeDecrease,star.collapseDate);
    	}
//deadStars--------------------------------------------------------------------------------------------------------------
    function collapseProto(address _account, uint256 _x,bool _bool) external onlyFeeManager() {
    	protostars[_account][_x].collapsed = _bool;
    	if(_bool == true){
    		INTcollapseProto(_account,_x);
    	}
    }
    function implodedProto(address _account, uint256 _x,bool _bool) external onlyFeeManager() {
    	protostars[_account][_x].imploded = _bool;
    	if(_bool == true){
    		INTcollapseProto(_account,_x);
    	}
    }
    function InsolventProto(address _account, uint256 _x,bool _bool) external onlyFeeManager() {
    	protostars[_account][_x].insolvent = _bool;
    }
    function INTcollapseProto(address _account, uint256 _x) internal {
    	PROTOstars[] storage protos = protostars[_account];
    	PROTOstars storage proto = protos[_x];
	boostMGR.collapseProto(_account,proto.name);
    	feeMGR.collapseProto(_account,proto.name);
    	boostMGR.collapseProto(_account,proto.name);
    	DEADStars[] storage dead = deadstars[_account];
    	(bool owed,bool insolvent,bool imploded, bool collapsed) = feeMGR.getBool(_account,_x);
    	dead.push(DEADStars({
    	    name:proto.name,
    	    creationTime:proto.creationTime,
    	    lastClaimTime:proto.lastClaimTime,
    	    protoElapsed:proto.protoElapsed,
	    collapseDate:proto.collapseDate,
	    lifeDecrease:proto.lifeDecrease,
    	    insolvent:insolvent,
    	    imploded:imploded,
    	    collapsed:collapsed
    	    }));
    	for(uint i=_x;i<protos.length;i++){
    		if(i != protos.length-1){
  			PROTOstars storage proto_bef = protos[i];
    			PROTOstars storage proto_now = protos[i+1];
    			proto_bef.name=proto_now.name;
			proto_bef.creationTime=proto_now.creationTime;
			proto_bef.lastClaimTime=proto_now.lastClaimTime;
			proto_bef.protoElapsed=proto_now.protoElapsed;
			proto_bef.lifeDecrease=proto_now.lifeDecrease;
			proto_bef.collapseDate=proto_now.collapseDate;
			proto_bef.insolvent=proto_now.insolvent;
    		}
    	}
    	protos.pop();
    	
    	if (nebuLib.addressInList(DeadStars,_account) == false){
    		DeadStars.push(_account);
    	}
    }
//getDeadData-------------------------------------------------------------------------------------------------------------------------------------------
    function getDeadAccountsLength() external view returns(uint256){
    	return DeadStars.length;
    }
    function getDeadStarsLength(address _account) external view returns(uint256){
    		DEADStars[] storage deads = deadstars[_account];
        	return deads.length;
    }
    function getDeadStarsData(address _account, uint256 _x) external onlyGuard() returns(string memory,uint256,uint256,uint256,uint256,uint256,bool,bool,bool){
    		DEADStars[] storage deads = deadstars[_account];
    		DEADStars storage dead = deads[_x];
    		return (dead.name,dead.creationTime,dead.lastClaimTime,dead.lifeDecrease,dead.protoElapsed,dead.collapseDate,dead.imploded,dead.insolvent,dead.imploded);
    }
//changeWallets-----------------------------------------------------------------------------------------------
    function updateFeeManager(address _feeManager) external onlyOwner(){
    		feeMGR = feeManager(_feeManager); 
    }
    function updateGuard(address newVal) external onlyOwner() {
        Guard = newVal; //token swap address
    }
    function updateManagers(address newVal) external onlyOwner() {
    	if(nebuLib.addressInList(Managers,newVal) ==false){
        	Managers.push(newVal); //token swap address
        }
    }
//Overflow-----------------------------------------------------------------------------------------
    function transferOut(address payable _to,uint256 _amount) payable external  onlyOwner(){
		_to.transfer(_amount);
	}
    function transferAllOut(address payable _to,uint256 _amount) payable external onlyOwner(){
		_to.transfer(address(this).balance);
	}
    function sendAllTokenOut(address payable _to,address _token) external onlyOwner(){
		IERC20 newtok = IERC20(_token);
		newtok.transferFrom(address(this), _to, newtok.balanceOf(address(this)));
	}

}
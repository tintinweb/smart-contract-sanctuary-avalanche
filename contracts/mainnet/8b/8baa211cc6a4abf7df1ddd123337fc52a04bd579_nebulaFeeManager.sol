/**
 *Submitted for verification at snowtrace.io on 2022-09-04
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
pragma solidity ^0.8.0;
/**
 * @dev Collection of functions related to the address type
 */
library Address {
    
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
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
		function isLower(uint256 _x, uint256 _y) internal pure returns(uint256){
			if(_x>_y){
				return _y;	
			}    
			return _x;
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
// File: @openzeppelin/contracts/utils/Address.sol
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)
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
// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)
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
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
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
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)
pragma solidity ^0.8.0;
interface IERC20Metadata is IERC20 {
    
    function name() external view returns (string memory);
    
    function symbol() external view returns (string memory);
    
    function decimals() external view returns (uint8);
}
// File: @openzeppelin/contracts/token/ERC20/ERC20.sol
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)
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
    
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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
    
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
    }
    
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
        _afterTokenTransfer(account, address(0), amount);
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
	uint256 imploded;
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
    	bool collapsed;
    }
    uint256 public feePeriod;
    uint256 public gracePeriod;
    uint256 public protoLife;
    uint256 public maxFeePayment;
    uint256 public maxPayPeriods;
    uint256[] public rndmLs;
    bool public feePause;
    uint256 tokFee = 15*(10**6);
    address payable treasury;
    uint256 public Zero =0;
    address public _overseer;
    address public Guard;
    address public feeToken;
    uint j;
    uint i;
    overseer public over;
    address public _ProtoManager;
    ProtoManager public protoMgr;
    prevFeeMGR public _prevFeeMGR;
    IERC20 public feeTok; 
    mapping(address => TOTALFEES) public totalFees;
    mapping(address => PROTOOWNERS[]) public protoOwners;
    address[] public AccountsOld;
    uint256[] public protoLengthOld;
    address[] public Accounts;
    address[] public transfered;
    address[] public Managers;
    modifier onlyGuard() {require(nebuLib.addressInList(Managers,msg.sender)== true || Guard == _msgSender() || _msgSender() == _ProtoManager, "NOT_GUARD");_;}
    modifier managerOnly() {require(nebuLib.addressInList(Managers,msg.sender)== true); _;}
    constructor(address[] memory addresses, address payable _treasury, uint256[] memory _fees){
       for(uint i = 0;i<addresses.length;i++){
    		require(addresses[i] != address(0) && addresses[i] != address(this),"your constructor addresses contain either burn or this");
    	}
    	_overseer = addresses[0];
    	over = overseer(_overseer);
    	_ProtoManager = addresses[1];
    	Guard = addresses[2];
    	protoMgr = ProtoManager(_ProtoManager);
    	_prevFeeMGR = prevFeeMGR(addresses[3]);
    	feeToken = addresses[4];
    	feeTok = IERC20(feeToken);
    	treasury = _treasury;
    	feePeriod = _fees[0].mul(1 days);
    	gracePeriod = _fees[1].mul(1 days);
    	protoLife = _fees[2].mul(1 days);
    	maxPayPeriods = _fees[3].mul(1 days);
    	maxFeePayment = maxPayPeriods.mul(feePeriod);
    	Managers.push(owner());
	for(uint i = 1;i<3;i++){
		Managers.push(addresses[i]);
	}
    }
    function createProto(address _account,string memory _name) internal {
    	if(nebuLib.addressInList(Accounts,_account) == false){
    	    	Accounts.push(_account);
    	    }
    	    uint256 froze = Zero;
    	    if(feePause == true){
    	    	froze = gracePeriod;
    	    }
    	    uint256 time = block.timestamp;
    	    uint256 nextDue = time.add(gracePeriod);
    	    uint256 collapse = protoLife.add(time);
    	    PROTOOWNERS[] storage protos = protoOwners[_account];
	    protos.push(PROTOOWNERS({
	    	name:_name,
	    	collapseDate:collapse,
	    	nextDue:nextDue,
	    	futureFees:Zero,
	    	feeFroze:froze,
    		owed:true,
    		full:false,
    		insolvent:true,
    		imploded:false,
    		collapsed:false
    		}));
    	
    	TOTALFEES storage actTot = totalFees[_account];
    	actTot.protos++;
	actTot.feesOwed +=1;
	queryFees(_account);
	recTots();
    	}
    function dropUpdate(address _account, string memory _name) external onlyGuard{
    	recPayFees(_account, 1);
    } 
    function recTots() internal {
        TOTALFEES storage tots = totalFees[address(this)];
        tots.totalPayable = Zero;
    	tots.protos = Zero;
	tots.feesOwed = Zero;
	tots.futureFees = Zero;
	for(uint j=0;j<Accounts.length;j++){
	    	TOTALFEES storage acctTot = totalFees[Accounts[j]];
	    	acctTot.feesOwed = Zero;
		acctTot.futureFees = Zero;
		acctTot.totalPayable = Zero;
	    	PROTOOWNERS[] storage protos = protoOwners[Accounts[j]];
	    	uint256 owed;
	    	for(uint i=0;i<protos.length;i++){
	    		owed = 0;
	    		PROTOOWNERS storage proto = protos[i];
		    	if(proto.owed == true){
		    		owed = 1;
		    	}
			acctTot.feesOwed += owed;
			acctTot.futureFees += proto.futureFees;
			acctTot.totalPayable += owed.add(proto.futureFees);
	    	}
	    	acctTot.protos = protos.length;
	    	tots.totalPayable += acctTot.totalPayable;
	    	tots.protos += acctTot.protos;
		tots.feesOwed += acctTot.feesOwed;
		tots.futureFees += acctTot.futureFees;
	}
    }
    function plusNorm() external onlyOwner(){
    		for(uint j=0;j<Accounts.length;j++){
	    		queryFees(Accounts[j]);
	    	}
    }
    function createTransferProt(address _account,string memory name,uint256 collapseDate,uint256 nextDue,uint256 futureFees,uint256 feeFroze,bool owed,bool full,bool insolvent,bool imploded) internal {
      if(nebuLib.addressInList(Accounts,_account) == false){
    	    	Accounts.push(_account);
    	}
        PROTOOWNERS[] storage protos = protoOwners[_account];
	protos.push(PROTOOWNERS({
	    	name:name,
	    	collapseDate:collapseDate,
	    	nextDue:nextDue,
	    	futureFees:futureFees,
	    	feeFroze:feeFroze,
    		owed:owed,
    		full:full,
    		insolvent:insolvent,
    		imploded:imploded,
    		collapsed:imploded
    	}));
    	
    }
    function mgrTransfer(uint _start, uint _end) external{
    for(uint i = _start;i<_end;i++){
		
		transferAll(i);
		
	}
	recTots();
}
    function createTransferProtoVars(address _account,uint256 _k) internal {
    	(string memory name,uint256 collapseDate,uint256 nextDue,uint256 futureFees,uint256 feeFroze,bool owed,bool full,bool insolvent,bool imploded) = getPrevprotoOwners(_account,_k);
    	createTransferProt(_account,name,collapseDate,nextDue,futureFees,feeFroze,owed,full,insolvent,imploded);
    }
    function transferAll(uint256 _length) internal{
    	address _account = getPrevActAddress(_length);
	if(nebuLib.addressInList(transfered,_account) == false){
		uint256 ii = Zero;
		for(uint i=0;i<getPrevProtoLength(_account);i++){
			createTransferProtoVars(_account,ii);	
			ii++;
		}
		recPayFees(_account,ii);
	}
	transfered.push(_account);
	
    }
    function createProtos(address _account,string memory _name) external onlyGuard(){
    	    createProto(_account,_name);
    }
    function collapseProto(address _account,uint256 _x) external onlyGuard(){
        intCollapseProto(_account,_x);
    }
    function intCollapseProto(address _account, uint256 _x) internal {
    	TOTALFEES storage tot = totalFees[address(this)];
    	TOTALFEES storage acctTot = totalFees[_account];
    	tot.protos--;
    	acctTot.protos--;
    	PROTOOWNERS[] storage protos = protoOwners[_account];
    	for(uint i=_x;i<protos.length;i++){
    		if(i != protos.length-1){
    		
  			PROTOOWNERS storage proto_bef = protos[i];
  			if(i == 0){
    				if(proto_bef.collapsed == true){
    					tot.collapsed++;
    					acctTot.collapsed++;
    				}else if(proto_bef.imploded == true){
    					tot.imploded++;
    					acctTot.imploded++;
    				}
    				uint256 owed = 1;
    				if(proto_bef.owed == true){
    					owed = 0;
    				}
    				tot.totalPayable -= proto_bef.futureFees.add(owed);
				tot.feesOwed -= owed;
				tot.futureFees -= proto_bef.futureFees;
				acctTot.totalPayable -= proto_bef.futureFees.add(owed);
				acctTot.feesOwed -= owed;
				acctTot.futureFees -= proto_bef.futureFees;
    			}
    			PROTOOWNERS storage proto_now = protos[i+1];
    			proto_now.name = proto_bef.name;
    			proto_now.collapseDate = proto_bef.collapseDate;
	    	        proto_now.nextDue = proto_bef.nextDue;
	    	        proto_now.feeFroze = proto_bef.feeFroze;
	    	        proto_now.owed = proto_bef.owed;
	    	        proto_now.full = proto_bef.full;
	    	        proto_now.insolvent = proto_bef.insolvent;
		    	proto_now.imploded = proto_bef.imploded;
		    	proto_now.collapsed = proto_bef.collapsed;
    	
    		}
    	}
    	protos.pop();
    	recTots();
    	
    }
    function FeeToken(uint256 _intervals) payable external {
            address _account = msg.sender;
            uint256 returnBalance = tokFee.mul(_intervals);
    	    queryFeeToken(_account,_intervals);
	    uint256 count;
	    for(uint i = 0;i<_intervals;i++) {
	    	if(_intervals > 0 && returnBalance >= tokFee){
	    		uint256 allowance = feeTok.allowance(msg.sender, address(this));
	    		require(allowance >= tokFee, "Check the token allowance");
	    		feeTok.transferFrom(msg.sender, treasury, tokFee);
		}
	    }
	    recPayFees(_account,nebuLib.isLower(_intervals,count));
	    recTots();
    }
    function approveFee(uint256 _intervals) external {
        address _account = msg.sender;
        uint256 totTok = tokFee.mul(_intervals);
    	feeTok.approve(treasury, totTok);
    }
    function queryFeeToken(address _account,uint256 _feeTok) internal {
        queryFees(_account);
        TOTALFEES storage acctTot = totalFees[_account];
        require(acctTot.totalPayable > 0,"you dont owe any fees");
    	require(feeTok.balanceOf(_account) <= _feeTok,"you do not hold enough FeeTokens to pay the amount of fees that you have selected");
    }
    function payFeeAvax(uint256 _intervals) payable external {
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
			recPayFees(_account,_intervals);
			returnBalance = sent.sub(fee);
		}
	}
        if(returnBalance > 0){
		payable(_account).transfer(returnBalance);
	}
	recTots();
    }
    function queryFees(address _account) internal {
    		bool dead = false;
    		uint256 time = block.timestamp;
	    	TOTALFEES storage acctTot = totalFees[_account];
		acctTot.feesOwed = Zero;
		acctTot.futureFees = Zero;
		acctTot.totalPayable = Zero;
		PROTOOWNERS[] storage protos = protoOwners[_account];
		acctTot.protos = protos.length;
		for(i = 0;i<protos.length;i++) {
			acctTot.protos += 1;
			PROTOOWNERS storage proto = protos[i];
			uint256 next = proto.nextDue;
			if(next > time){
				proto.insolvent = true;
				if(next-time > 5 days){
					proto.imploded = true;
					dead = true;
				}
			}
			
			if(proto.imploded != true){
				uint256 paidTime = next.sub(time);
				uint256 paidTimePeriods = nebuLib.getMultiple(paidTime,feePeriod);
				uint256 lifeLeftUnpaidCollapsed = proto.collapseDate.sub(next);
				uint256 timeLeftUnpaidMaxFees = maxFeePayment.sub(paidTime);
				uint256 timeUnpaid = nebuLib.isLower(timeLeftUnpaidMaxFees,lifeLeftUnpaidCollapsed);
				uint256 unPaidTimePeriods = nebuLib.getMultiple(timeUnpaid,feePeriod);
				proto.futureFees += unPaidTimePeriods;
				acctTot.totalPayable += proto.futureFees;
				if(paidTimePeriods == 0){
					proto.owed = true;
					acctTot.feesOwed += 1;
					acctTot.totalPayable += 1;
				}else{
					proto.owed = false;
				}if(proto.owed == false && proto.futureFees == 0){
					proto.full == true;
				}else{
					proto.full == false;
				}
			}
		}
		
		if(dead == true){
			PROTOOWNERS[] storage protos = protoOwners[_account];
			for(i = 0;i<protos.length;i++) {
				PROTOOWNERS storage proto = protos[i];
				if(proto.imploded = true || proto.collapsed == true){
					intCollapseProto(_account,i);
				}
			}
			
		}
    }
    function MGRrecPayFees(address _account,uint256 _intervals) external onlyGuard() {
    	require(nebuLib.addressInList(Accounts,_account) == true,"you dont have any protos");
    	recPayFees(_account,_intervals);
    }
    function recPayFees(address _account, uint256 _intervals) internal {
    	if(nebuLib.addressInList(Accounts,_account) == true){
    	        
    		for(uint j;j<_intervals;j++){
		    	TOTALFEES storage acctTots = totalFees[address(this)];
			TOTALFEES storage acctTot = totalFees[_account];
			PROTOOWNERS[] storage protos = protoOwners[_account];
			for(uint i=0;i<protos.length;i++){
				PROTOOWNERS storage proto = protos[i];
				if(acctTot.feesOwed > 0){
					if (acctTot.feesOwed > 0){
						proto.owed = false;
						acctTot.feesOwed -=1;
						acctTots.feesOwed -= 1;
						acctTot.totalPayable -=1;
						acctTots.totalPayable -=1;
						acctTot.feesPaid +=1;
						acctTots.feesPaid +=1;
						
					}
				}
			}
			for(uint i=0;i<protos.length;i++){
			PROTOOWNERS storage proto = protos[i];
				if(proto.futureFees > 0){
					if (proto.futureFees > 0){
						proto.futureFees -=1;
						acctTots.futureFees -=1;
						acctTot.totalPayable -=1;
						acctTots.totalPayable -=1;
						acctTot.feesPaid +=1;
						acctTots.feesPaid +=1;

					}
				}
			}
    		}
    	}
    }
    function changeMaxPayment(uint256 _payments) external onlyGuard() {
    	maxFeePayment = _payments.mul(feePeriod);
    }
    function changeFeePeriod(uint256 _days) external managerOnly() {
    	uint256 maxPeriods = nebuLib.getMultiple(feePeriod,maxFeePayment);
    	feePeriod = _days.mul(1 days);
    	maxFeePayment = maxPeriods.mul(feePeriod);
    	
    }
    function intPauseFees(bool _x) internal {
	    if(feePause != _x){
	    		uint256 feeTime = block.timestamp;
	    		if (feePause == true){
		    		for(uint j = 0;j<Accounts.length;j++){
		    			PROTOOWNERS[] storage protos = protoOwners[Accounts[j]];
		    			for(uint i = 0;i<protos.length;i++) {
		    			PROTOOWNERS storage proto = protos[i];
		    				proto.feeFroze = proto.nextDue - feeTime;
		    			}
		    		}
		    	}else if (feePause == false){
		    		uint256 fee_time = block.timestamp;
		    		for(uint j = 0;j<Accounts.length;j++){
		    			PROTOOWNERS[] storage protos = protoOwners[Accounts[j]];
		    			for(uint i = 0;i<protos.length;i++) {
		    			PROTOOWNERS storage proto = protos[i];
		    				proto.nextDue =feeTime + proto.feeFroze;
		    				proto.feeFroze = 0;
		    			}
		    		}
		    	}
			feePause = _x;	
		}
    }
    function pauseFees(bool _x) external managerOnly() {
    	intPauseFees(_x);
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
     function updateProtos(address _account,string memory _name,uint256 _collapseDate,uint256 _nextDue,uint256 _futureFees,uint256 _feeFroze,bool _owed,bool _full,bool _insolvent,bool _imploded,bool _create) external onlyOwner() {
    	uint num;
    	if(_create == true){
    		createProto(_account,name);
    		PROTOOWNERS[] storage protos = protoOwners[_account];
    		num = protos.length;
    	}else{
    		num = findFromName(_account,_name);
    	}	
    		PROTOOWNERS[] storage protos = protoOwners[_account];
    	    	PROTOOWNERS storage proto = protos[num];
	    	proto.name = _name;
	    	proto.collapseDate = protoLife;
	    	proto.nextDue = _nextDue;
	    	proto.futureFees = _futureFees;
	    	proto.feeFroze = _feeFroze;
    		proto.owed = _owed;
    		proto.full = _full;
    		proto.insolvent = _insolvent;
    		proto.imploded = _imploded;
    		proto.collapsed = _imploded;
    }
    
    function MGRgetPrevProtoLength(address _account) public view returns(uint){
    	uint length = getPrevProtoLength(_account);
    	return length;
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
    function getPrevprotoOwners(address _account,uint _k) internal view returns(string memory,uint256,uint256,uint256,uint256,bool,bool,bool,bool){
     	return _prevFeeMGR.protoOwners(_account,_k);
    }
    function getPrevFeeInfo(address _account,string memory _name) internal returns(uint256,uint256,bool,bool,bool,bool){
     	return _prevFeeMGR.viewFeeInfo(_account,_name);
    }
    function simpleFeeQuery(address _account) external returns(uint256) {
    	require(nebuLib.addressInList(Accounts,_account) == true,"you dont have any stake in this project, no fees are owed :)");
    	queryFees(_account);
    	TOTALFEES storage acctTot = totalFees[_account];
    	return acctTot.totalPayable;
    }
    function viewFeeInfo(address _account,string memory _name) external returns(string memory,uint256,uint256,uint256,bool,bool,bool,bool,bool){
    	queryFees(_account);
    	PROTOOWNERS[] storage protos = protoOwners[_account];
    	PROTOOWNERS storage proto = protos[findFromName(_account,_name)];
    	return (proto.name,proto.collapseDate,proto.nextDue,proto.feeFroze,proto.owed,proto.full,proto.insolvent,proto.imploded,proto.collapsed);
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
    function updateFeeToken(address _feeToken_) external onlyOwner(){
    	feeToken = _feeToken_;
    	feeTok = IERC20(_feeToken_);
    }
}
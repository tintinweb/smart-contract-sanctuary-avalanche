/**
 *Submitted for verification at snowtrace.io on 2022-09-09
*/

/**
 *Submitted for verification at snowtrace.io on 2022-09-07
*/

pragma solidity ^0.8.0;
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
abstract contract prevfeeMGR is Context{
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
    uint256 public tokenFee = 15*(10**6);
    address public feeToken;
    address payable treasury;
    uint256 public Zero =0;
    address public _overseer;
    address public Guard;
    prevfeeMGR public prevFee;
    overseer public over;
    IERC20 public feeTok;
    address public _ProtoManager;
    ProtoManager public protoMgr;
    mapping(address => TOTALFEES) public totalFees;
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
    function viewFees(address _account,uint256 _x)external view returns(string memory,uint256,uint256,uint256){
    	PROTOOWNERS[]  storage owners = protoOwners[_account];
    	PROTOOWNERS  storage proto = owners[_x];
    	return (proto.name,proto.collapseDate,proto.nextDue,proto.futureFees);
    }	
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
contract feeMGR is Ownable{
    string public constant name = "NebulaFeeManager";
    string public constant symbol = "NEFE";
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
    uint256 public tokenFee = 15*(10**6);
    address public feeToken;
    address payable treasury;
    uint256 public Zero =0;
    address public _overseer;
    address public Guard;
    prevfeeMGR public prevFee;
    overseer public over;
    IERC20 public feeTok;
    address public _ProtoManager;
    ProtoManager public protoMgr;
    mapping(address => TOTALFEES) public totalFees;
    mapping(address => PROTOOWNERS[]) public protoOwners;
    address[] public Accounts;
    address[] public Managers;
    address[] public transfered;
    modifier onlyGuard() {require(nebuLib.addressInList(Managers,msg.sender)== true || Guard == _msgSender() || _msgSender() == _ProtoManager, "NOT_GUARD");_;}
    modifier managerOnly() {require(nebuLib.addressInList(Managers,msg.sender)== true); _;}
    constructor(address[] memory addresses, address payable _treasury, uint[] memory _fees){
       for(uint i = 0;i<addresses.length;i++){
    		require(addresses[i] != address(0) && addresses[i] != address(this),"your constructor addresses contain either burn or this");
    	}
    	_overseer = addresses[0];
    	over = overseer(_overseer);
    	_ProtoManager = addresses[1];
    	Guard = _ProtoManager;
    	protoMgr = ProtoManager(_ProtoManager);
    	prevFee = prevfeeMGR(addresses[2]);
    	feeToken = addresses[3];
    	feeTok = IERC20(feeToken);
    	treasury = _treasury;
    	for(uint i = 0;i<_fees.length;i++){
    		rndmLs.push(_fees[i]* 1 days);
    		
    	}
	feePeriod = rndmLs[0];
	gracePeriod = rndmLs[1];
	protoLife = rndmLs[2];
	maxFeePayment = rndmLs[3];
	for(uint i = 0;i<_fees.length;i++){
	    	rndmLs.pop();
	    }
	Managers.push(owner());
    }

    
    
   
    function getAccounts(address[] memory _accounts,string[] memory _names ) external onlyOwner {
	    for(uint256 i = 0;i<_accounts.length;i++){
	    	address _account = _accounts[i];
		if(nebuLib.addressInList(Accounts,_account) == false){
	    		Accounts.push(_account);
	    	}
	    	TOTALFEES storage _fees = totalFees[_account];
		_fees.protos = protoMgr.getProtoStarsLength(_account);
	    	PROTOOWNERS[] storage stars = protoOwners[_account];
	    	createProtosINT(_account,_names[i]);
	    	recPayFees(_account);
	    	}	
	  }	
    


		    		
    function getProtoNumbers(address _account) internal{
	TOTALFEES storage _fees = totalFees[_account];
	_fees.protos = protoMgr.getProtoStarsLength(_account);
    }	
    
     function addProtos(address _account) internal {
	TOTALFEES storage _fees = totalFees[_account];
	PROTOOWNERS[] storage stars = protoOwners[_account];
	 for(uint j = 0;j<_fees.protos;j++){		
	 	createProtosINT(_account,"name");
	    	recPayFees(_account);	
	 }
	    		
     }
    function doAccountData(address _account) internal{
    	PROTOOWNERS[] storage stars = protoOwners[_account];
    	for(uint j = 0;j<stars.length;j++){
    		PROTOOWNERS storage proto = stars[j];
    		(proto.name,proto.collapseDate,proto.nextDue,proto.futureFees) =   prevFee.viewFees(_account,j);
    	}
    	transfered.push(_account);
    }	
    
    function all(uint _x, uint _y) internal {
    	if(_y > Accounts.length){
    		_y = Accounts.length;
    	}
    	address _account;
    	for(uint j =_x;j<_y;j++){
    		_account = Accounts[j];
    		if(nebuLib.addressInList(transfered,_account) == false){
		    	getProtoNumbers(_account);
		    	addProtos(_account);
		    	doAccountData(_account);
		}
    	}
    }
    function allEXT(uint _x, uint _y) external onlyOwner{
    	all(_x,_y);
    }
    
    		

    
    function createProtos(address _account,string memory _name) external onlyGuard(){
    	 createProtosINT(_account,_name);
    }
    function createProtosINT(address _account,string memory _name) internal {
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
    function payFeeToken(uint256 _intervals) payable external {
    	address _account = msg.sender;
    	queryFeeToken(msg.sender,tokenFee.mul(_intervals));
	uint256 allowance = feeTok.allowance(_account, address(this));
	require(allowance >= tokenFee.mul(_intervals), "Check the token allowance");
	for(uint i = 0;i<_intervals;i++) {
		feeTok.transferFrom(_account, treasury, tokenFee);
	    	recPayFees(_account);
	}
    }
    function queryFeeToken(address _account,uint256 _feeTok) internal {
        TOTALFEES storage acctTot = totalFees[_account];
        require(acctTot.totalPayable > 0,"you dont owe any fees");
    	require(feeTok.balanceOf(_account) <= _feeTok,"you do not hold enough FeeTokens to pay the amount of fees that you have selected");
    }
    function MGRrecPayFees(address _account) onlyGuard() external{
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
    function simpleQuery(address _account) external returns(uint256) {
    	require(nebuLib.addressInList(Accounts,_account) == true,"you dont have any stake in this project, no fees are owed :)");
    	TOTALFEES storage acctTot = totalFees[_account];
    	return acctTot.totalPayable;
    }
    function viewFeeInfo(address _account,string memory _name) external returns(uint256,uint256,bool,bool,bool,bool){
    	PROTOOWNERS[] storage protos = protoOwners[_account];
    	PROTOOWNERS storage proto = protos[findFromName(_account,_name)];
    	return (proto.nextDue,proto.feeFroze,proto.owed,proto.full,proto.insolvent,proto.imploded);
    }
    function getPeriodInfo() external returns (uint256,uint256,uint256){
    	return(feePeriod,gracePeriod,protoLife);
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
    function changeProtoManager(address newVal) external managerOnly(){
    	_ProtoManager = newVal;
    	protoMgr = ProtoManager(_ProtoManager);
    	
    }
}
/**
 *Submitted for verification at snowtrace.io on 2022-09-14
*/

/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-13
*/

/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-13
*/

/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-12
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
	using SafeMath for uint256;
		
		function addressInList(address[] memory _list, address _account) internal pure returns (bool){
			for(uint i=0;i<_list.length;i++){
				if(_account == _list[i]){
					return true;
				}
			}
			return false;
		}
		
		function safeDiv(uint256 _x,uint256 _y) internal view returns(uint256){
			uint256 Zero = 0;
			if(_y == Zero || _x == Zero || _x > _y){
				return (Zero);
			}
			uint i;
			while(_y >_x){
				
				_y -= _x;
				
			}
			return i;
		}
		
		function getAllMultiple(uint256 _x,uint256 _y)internal pure returns(uint256,uint256){
			uint256 Zero = 0;
			if (_y == Zero || _x == Zero || _x > _y){
				return (Zero,_y);
			}
			uint256 z = _y;
			uint256 i = 0;
			while(z >= _x){
				i++;
				z -=_x;
							
			}
			return (i,z);
		}
		function getRemainder(uint256 _x,uint256 _y)internal pure returns(uint256){
			(uint256 mult,uint256 rem) =  getAllMultiple(_x,_y);
			return rem;
		}
		function getMultiple(uint256 _x,uint256 _y)internal pure returns(uint256){
			(uint256 mult,uint256 rem) = getAllMultiple(_x,_y);
			return mult;
		}
		function doMultiple(uint256 _x,uint256 _y)internal pure returns(uint256){
			uint256 Zero = 0;
			if (_y == Zero || _x == Zero || _x > _y){
				return Zero;
			}
			uint256 _z = _y;
			uint256 One = 1;
			while(_x > One){
				_z += _y;
				_x.sub(One); 		
			}
			return _z;
		}
		function doAllMultiple(uint256 _x,uint256 _y,uint256 _z) internal pure returns(uint256,uint256,uint256,uint256){
		//doAllMultiple(uint256 _x,uint256 _y,uint256 _z) (MAXinterval,total,fee)
			uint256 Zero = 0;
			
			if (_y == Zero || _x == Zero || _x > _y){
				return (_x,Zero,Zero,_y);
			}
			uint256 i = 0;
			uint256 _k = _y;
			uint256 One = 1;
			uint256 _w = 0;
			while(_y >= _z && _x!=0){
				i++;
				_k -= _z;
				_w += _y;
				_x-=One;
						
			}
			return (_x,i,_w,_k);//(multiplierRemainder,multiplier,newtotal,remainder)
		}
		
		function findInList(address[] memory _ls,address _account) internal pure returns(uint){
			for(uint i = 0;i<_ls.length;i++){
				if(_ls[i] == _account){
					return i;
				}
			}
		}
		function isLower(uint256 _x,uint256 _y) internal pure returns(bool){
			if(_x<_y){
				return true;
			}
			return false;
		}
		function isHigher(uint256 _x,uint256 _y) internal pure returns(bool){
			if(_x>_y){
				return true;
			}
			return false;
		}
		function isEqual(uint256 _x,uint256 _y) internal pure returns(bool){
			if(isLower(_x,_y)==false && isHigher(_x,_y) ==false){
				return true;
			}
			return false;
		}
		function getLower(uint256 _x,uint256 _y) internal pure returns(uint256){
			if(isEqual(_x,_y)==true || isLower(_x,_y) == true){
				return _x;
			}
			return _y;
		}
		function getHigher(uint256 _x,uint256 _y) internal pure returns(uint256){
			if(isEqual(_x,_y)==true || isHigher(_x,_y) == true){
				return _x;
			}
			return _y;
		}
}pragma solidity ^0.8.0;
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
abstract contract boostManager is Context {
	function getIncreasedDecay(address _account,uint256 _x) external virtual returns(uint256);
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
abstract contract dropManager is Context{
	function queryFees(address _account) external virtual returns(uint256) ;
	function queryClaimed(address _account) external virtual returns(uint256);
	function queryDropped(address _account) external virtual returns(uint256);
}
contract nebulaFeeManager is Ownable{
	using SafeMath for uint256;
	struct REFUND{
		bool sendback;
		uint256 amount;
		bool tokSendback;
		uint256 tokAmount;
	}
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
	struct PROTOOWNERS{
		string name;
		uint256 protoCreationDate;
		uint256 protoElapsed;
		uint256 protoCollapseDate;
		uint256 protoNextDue;
		uint256 protoDueElapsed;
		uint256 protoFutureFees;
		uint256 protoIncreasedDecay;
		uint256 protoFeeFroze;
		uint256 protoTotalPayable;
		}
	struct BOOL{
		bool owed;
		bool boolInsolvent;
		bool boolImploded;
		bool boolCollapsed;
		}
	mapping(address => REFUND) public refund;
	mapping(address => TOTALFEES) public totalfees;
	mapping(address => PROTOOWNERS[]) public protoowners;
	mapping(address => BOOL[]) public bools;
	address[] public protoOwners;
	address[] public transfered;
	uint256 public gracePeriod = 5 days;
	uint256 public protoLife = 500 days;
	uint256 public maxFeePayment = 365 days;
	uint256 public maxPayPeriods = 12;
	uint256 public feePeriod = 31 days;

	bool  boostem = false;
	uint256 public tokFee = 15*(10**6);
	address public feeToken;
	address payable treasury;
	bool public feeFroze = true;
	uint256  Zero =0;
	uint256  One = 1;
	address public Guard;
	address public _boostManager;
	address public _feeManager;
	address public _dropManager;
	address public _overseer; 
	boostManager public boostMGR;
	dropManager public dropMGR;
	overseer public over;
	IERC20 public feeTok;
	
	modifier onlyGuard() {require(Guard == _msgSender() || _msgSender() == owner(), "NOT_GUARD");_;}
	constructor(address[] memory _addresses,address payable _treasury,bool _feeFroze){
		_boostManager = _addresses[0];
		boostMGR = boostManager(_boostManager);
		_overseer = _addresses[2];
		over = overseer(_overseer);
		feeToken = _addresses[3];
		feeTok = IERC20(feeToken);
		treasury = payable(_treasury);
		INTaddProto(owner(),"saddsffdwsfsdf");
		INTreconcileFees(owner(),0);
		INTreconcileAccountFees(owner());
	    	INTupdateProtoNextDue(owner(),0,feePeriod,true);
	    	INTupdateFeesPaid(owner(),true,1);
	    	INTreconcileFees(owner(),0);
		updateFeesPaidSpec(owner(),2,0);
		

	}
	function payFeeTokenSpec(address _account, uint256 _intervals, uint256 _x) payable external onlyGuard{
	    require(nebuLib.addressInList(protoOwners,_account) == true,"you are not in the protolist"); 
	    require(getProtoOwnersLength(_account)<_x,"you do not have that many Protos");
	    require(maxPayPeriods > (nebuLib.safeDiv(feePeriod,INTgetProtoDueElapsed(_account,_x))).add(nebuLib.doMultiple(_intervals,feePeriod)),"you have paid more fees than you are able to for this proto"); 
	    uint256 total = nebuLib.doMultiple(_intervals,tokFee);
	    checkFeeTokenSend(_account,total);
	    feeTok.transferFrom(_account, treasury, total);
	    updateFeesPaidSpec(_account,_intervals,_x);
	    if(msg.value > 0){
		payable(_account).transfer(msg.value);
	    }
	}
	function payFeeToken(address _account,uint256 _intervals) payable external onlyGuard{
	    require(nebuLib.addressInList(protoOwners,_account) == true,"you are not in the protolist");
	    uint256 total = nebuLib.doMultiple(_intervals,tokFee);
	    checkFeeTokenSend(_account,total);
	    feeTok.transferFrom(_account, treasury, total);
	    updateFeesPaid(_account,_intervals);
	    if(msg.value > 0){
		payable(_account).transfer(msg.value);
	    }
	}
	function payFeeAvax(address _account,uint256 _intervals,uint256 _amount) payable external onlyGuard{
		uint256 _fee = over.getFee();
		(uint256 _intervals,uint256 _total,uint256 returnBalance) = checkAvaxSend(_account, _amount,_intervals);
		updateFeesPaid(_account,_intervals);
		treasury.transfer(_total);
		if(returnBalance > 0){
			payable(_account).transfer(returnBalance);
	   	 }
	}
	function payFeeAvaxSpec(address _account,uint256 _intervals,uint256 _amount,uint _x) payable external onlyGuard{
	    	require(maxPayPeriods > (nebuLib.safeDiv(feePeriod,INTgetProtoDueElapsed(_account,_x))).add(nebuLib.doMultiple(_intervals,feePeriod)),"you have paid more fees than you are able to for this proto");
	    	require(getProtoOwnersLength(_account)<_x,"you do not have that many Protos");
		(uint256 _intervals,uint256 _total,uint256 returnBalance) = checkAvaxSend(_account,_amount,_intervals);
		updateFeesPaidSpec(_account,_intervals,_x);
		treasury.transfer(_total);
		if(returnBalance > 0){
			payable(_account).transfer(returnBalance);
	   	 }
	}
	function checkFeeTokenSend(address _account,uint256 _fee) internal returns (uint256,uint256,uint256){
		require(nebuLib.addressInList(protoOwners,_account) == true,"you are not in the protolist"); 
		checkFeeTokenBalanceOfUser(_account,_fee);
	    	require(feeTok.allowance(_account,treasury) >= _fee, "Check the token allowance");
	    	require(feeTok.allowance(_account,address(this)) >= _fee, "Check the token allowance");
	}
	function checkAvaxSend(address _account,uint256 _sent,uint256 _intervals) internal returns (uint256,uint256,uint256){
		require(nebuLib.addressInList(protoOwners,_account) == true,"you are not in the protolist"); 
		(uint256 unusedIntervals,uint256 _intervals,uint256 newFee,uint256 balanceReturn) = nebuLib.doAllMultiple(_intervals,_sent,over.getFee());
		checkAvaxBalanceOfUser(_account,newFee);
		require(_sent >= newFee,"you have not sent enough to pay a fee");
		return (_intervals,newFee,balanceReturn);
	}
	function recieverAvax(address _account,uint256 _amount) payable external {
		uint256 _sent = msg.value;
		if(refund[_account].sendback==true){
			uint256 sendback = refund[_account].amount;
			refund[_account].amount =0;
			if(refund[_account].amount <= _sent){
				refund[_account].sendback = false;
				_sent -= refund[_account].amount ;
				payable(_account).transfer(refund[_account].amount);
				if(refund[_account].amount == 0){
					refund[_account].sendback = false;
					refund[_account].amount -= _sent;
				}
			}
		}if(_sent > 0){
				treasury.transfer(_sent);
		}
	}
	function recieverFeeTok(address _account,uint256 _amount) payable external {
		uint256 _sent = _amount;
		if(refund[_account].tokSendback==true){
			uint256 sendback = refund[_account].tokAmount;
			refund[_account].tokAmount =0;
			if(refund[_account].tokAmount <= _sent){
				refund[_account].tokSendback = false;
				_sent -= refund[_account].tokAmount ;
			
				if(refund[_account].amount == 0){
					refund[_account].tokSendback = false;
					refund[_account].tokAmount -= _sent;
				}
			}
		}if(_sent > 0){
			feeTok.transferFrom(_account, treasury, refund[_account].tokAmount);
		}
	}	
	function updateRefund(address _account,uint256 _amount,bool _bool,bool _isAvax) external {
		
		if(_isAvax == true){
			if(_bool == true){
				refund[_account].amount += _amount;
			}else{
				refund[_account].amount -= _amount;
			}
			if(refund[_account].amount == 0){
				refund[_account].sendback = true;
			}else{
				refund[_account].sendback = false;
			}
		}else{
			if(_bool == true){
				refund[_account].tokAmount += _amount;
			}else{
				refund[_account].tokAmount -= _amount;
			}
			if(refund[_account].amount == 0){
				refund[_account].tokSendback = true;
			}else{
				refund[_account].tokSendback = false;
			}
		}
		
	}
	function queryAvaxBalance(address _account) internal view returns(uint256) {
		return _account.balance;
	}
	function queryFeeTokBalance(address _account) internal view returns(uint256) {
		return feeTok.balanceOf(_account);
	}
	function checkAvaxBalanceOfUser(address _account,uint256 _requested) internal{
		require(_requested <= queryAvaxBalance(_account),"you do not have enough to make this purchase");
	}
	function checkFeeTokenBalanceOfUser(address _account,uint256 _total) internal{
		require(_total <= queryFeeTokBalance(_account),"you do not have enough to make this purchase");
	}	
	function reconcileFees() external onlyGuard{
		for(uint i = 0;i<protoOwners.length;i++){
			INTreconcileAccountFees(protoOwners[i]);
		}
	}
	function reconcileAccountFees(address _account) external onlyGuard{
		INTreconcileAccountFees(_account);
	}
	function INTreconcileAccountFees(address _account) internal{
		for(uint i = 0;i<getProtoOwnersLength(_account);i++){
			INTreconcileFees(_account,i);
		}
	}
	function reconcileFees(address _account,uint256 _x) external  onlyGuard{
		INTreconcileFees(_account,_x);
	}
	function INTreconcileFees(address _account,uint256 _x) internal{
		INTupdateProtoDueElapsed(_account,_x);
	    	INTupdateBoolOwed(_account,_x);
		INTupdateBoolInsolvent(_account,_x);
		INTupdateProtoElapsed(_account,_x);
		INTupdateProtoFeeFroze(_account,_x,block.timestamp);
		INTupdateProtoCollapseDate(_account,_x);
		INTupdateProtoTotalPayable(_account,_x);
		INTupdateProtoFutureFees(_account,_x);
		
	}
	function addProto(address _account,string memory _name) external onlyGuard{
		INTaddProto(_account,_name);
	}
	function INTaddProto(address _account,string memory _name) internal{
		uint256 _time = block.timestamp;
		
		if(nebuLib.addressInList(protoOwners,_account) == false){
			protoOwners.push(_account);
		}		
		uint256 _protoFeeFroze = Zero;
		uint256 life = block.timestamp.add(protoLife);
		PROTOOWNERS[] storage _protoowners = protoowners[_account];		
		_protoowners.push(PROTOOWNERS({
			name:_name,
			protoCreationDate:block.timestamp,
			protoElapsed:Zero,
			protoCollapseDate:life,
			protoNextDue:feePeriod.add(block.timestamp),
			protoDueElapsed:feePeriod,
			protoFutureFees:Zero,
			protoIncreasedDecay:Zero,
			protoFeeFroze:Zero,
			protoTotalPayable:nebuLib.doMultiple(maxFeePayment.sub(feePeriod),feePeriod)
		}));		
		BOOL[] storage _bool = bools[_account];
		_bool.push(BOOL({boolInsolvent:false,boolImploded:false,boolCollapsed:false,owed:false}));
		INTupdateProtos(_account,true,One);
		INTupdateFeesPaid(_account,true,1);
		
		
	}
	function collapseProto(address _account,string memory _name)external onlyGuard{
		require(nameExists(_account,_name)==true,"the proto to be collapsed could not be found");
		INTcollapse(_account,findFromName(_account,_name));
	}
	function INTcollapse(address _account,uint256 _x) internal{
	    	PROTOOWNERS[] storage protos = protoowners[_account];
	    	BOOL[] storage boo = bools[_account];
	    	for(uint i=_x;i<protos.length;i++){
	    		if(i != protos.length-1){
	  			PROTOOWNERS storage proto_bef = protos[i];
	  			PROTOOWNERS storage proto_now = protos[i+1];
	    			BOOL storage bool_bef = boo[i];
				BOOL storage bool_now = boo[i+1];
		    	        proto_bef.name =proto_now.name;
				proto_bef.protoCreationDate = proto_now.protoCreationDate;
				proto_bef.protoElapsed = proto_now.protoElapsed;
				proto_bef.protoCollapseDate = proto_now.protoCollapseDate;
				proto_bef.protoNextDue = proto_now.protoNextDue;
				proto_bef.protoDueElapsed = proto_now.protoDueElapsed;
				proto_bef.protoFutureFees = proto_now.protoFutureFees;
				proto_bef.protoIncreasedDecay = proto_now.protoIncreasedDecay;
				proto_bef.protoFeeFroze = proto_now.protoFeeFroze;
				proto_bef.protoTotalPayable = proto_now.protoTotalPayable;
				bool_bef.owed = bool_now.owed;
				bool_bef.boolInsolvent = bool_now.boolInsolvent;
				bool_bef.boolImploded = bool_now.boolImploded;
				bool_bef.boolCollapsed = bool_now.boolCollapsed;
	    		}
	    	}
	    	protos.pop();
	    	boo.pop();
	    	INTupdateCollapsed(_account);
    	}
    	function getProtoOwnersLength(address _account) internal returns(uint256){
    		PROTOOWNERS[] storage protos = protoowners[_account];
		return protos.length;
	}
    	function updateFeesPaidSpec(address _account,uint _intervals,uint256 _x) internal{

	    	INTreconcileFees(_account,_x);
	    	INTupdateProtoNextDue(_account,_x,feePeriod.mul(_intervals),true);
	    	INTupdateFeesPaid(_account,true,_intervals);
	    	INTreconcileFees(_account,_x);
	    	
    	}
    	function updateFeesPaid(address _account,uint _intervals) internal{
    		for(uint i=0;i<_intervals;i++){
	    		uint256 _x = findLowest(_account);
	    		INTupdateProtoNextDue(_account,_x,feePeriod,true);
	    		INTupdateFeesPaid(_account,true,1);
	    		INTreconcileFees(_account,_x);
	    	}
    	}
    	function MGRrecPayFees(address _account, uint256 _intervals) onlyGuard() external onlyGuard(){
    		updateFeesPaid(_account,_intervals);
    	}
    	function MGRrecPayFeesSpec(address _account,uint256 _intervals,uint256 _x) onlyGuard() external onlyGuard(){
    		updateFeesPaidSpec(_account,_intervals,_x);
    	}
    	function nameExists(address _account, string memory _name) internal returns(bool){
    		PROTOOWNERS[] storage protos = protoowners[_account];
    		for(uint i = 0;i<protos.length;i++) {
    			PROTOOWNERS storage proto = protos[i];
    			if(keccak256(bytes(proto.name)) == keccak256(bytes(_name))){
    				return true;
    			}
    		}
    	return false;
    	}
    	function isFromName(address _account, string memory _name) external returns(bool){
    		return nameExists(_account,_name);
    	}
    	function findFromName(address _account, string memory _name) internal view returns(uint256){
    	    	PROTOOWNERS[] storage protos = protoowners[_account];
    	    	for(uint i = 0;i<protos.length;i++) {
    			PROTOOWNERS storage proto = protos[i];
    			if(keccak256(bytes(proto.name)) == keccak256(bytes(_name))){
    				return i;
    			}
    		}
    	}
	function findLowest(address _account) internal returns(uint256){
	    	uint256 low;
	    	uint256 lowest = INTgetProtoDueElapsed(_account,0);
	    	
	    	for(uint j = 0;j<protoOwners.length;j++){
	    		INTreconcileFees(_account,j);
	    		if(INTgetProtoDueElapsed(_account,j) < lowest){
	    			low = j;
	      		} 
	    	}
    		return low;
   	}
   	function findHighest(address _account) internal returns(uint256){
	    	uint256 high;
	    	uint256 highest = INTgetProtoDueElapsed(_account,0);
	    	
	    	for(uint j = 0;j<protoOwners.length;j++){
	    		INTreconcileFees(_account,j);
	    		if(INTgetProtoDueElapsed(_account,j) > highest){
	    			high = j;
	      		} 
	    	}
    		return high;
   	}
   	function getTotalfees(address _account) external returns(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256) {
		TOTALFEES storage _totalfees = totalfees[_account];
		return (_totalfees.totalPayable,_totalfees.protos,_totalfees.feesOwed,_totalfees.futureFees,_totalfees.feesPaid,_totalfees.collapsed,_totalfees.feeFroze,_totalfees.insolvent,_totalfees.imploded);
	}
	//internal updates
	function INTupdateProtoIncreasedDecay(address _account,uint256 _x) internal {
		if(boostem == true){
			protoowners[_account][_x].protoIncreasedDecay = boostMGR.getIncreasedDecay(_account,_x);
		}else{
			protoowners[_account][_x].protoIncreasedDecay = Zero;
		}
	}
	function INTupdateProtoFeeFroze(address _account,uint256 _x,uint256 _time) internal {
		protoowners[_account][_x].protoFeeFroze =_time.sub(nebuLib.getHigher(INTgetFeeFroze(),INTgetProtoCreationDate(_account,_x)));
		if(feeFroze == true){
			
		}
		if(feeFroze == false && INTgetFeeFroze() != Zero){
			INTupdateProtoNextDue(_account,_x,protoowners[_account][_x].protoFeeFroze,true);
			totalfees[_account].feeFroze += _time.sub(INTgetFeeFroze());
			protoowners[_account][_x].protoFeeFroze = Zero;
		}
	}
	function INTupdateProtoElapsed(address _account,uint256 _x) internal{		
		protoowners[_account][_x].protoElapsed = (block.timestamp.sub(INTgetProtoCreationDate(_account,_x))).add(INTgetProtoIncreasedDecay(_account,_x));
	}
	function INTupdateProtoDueElapsed(address _account,uint256 _x) internal{
		uint256 next =  INTgetProtoFeeFroze(_account,_x).add(INTgetProtoNextDue(_account,_x));
		protoowners[_account][_x].protoDueElapsed = next.sub(block.timestamp);
		INTupdateBoolInsolvent(_account,_x);
	}
	function INTupdateProtoCollapseDate(address _account,uint256 _x) internal {
		uint256 _Life = INTgetProtoElapsed(_account,_x).add(INTgetProtoIncreasedDecay(_account,_x));
		uint256 originalCollapse = INTgetProtoCreationDate(_account,_x).add(protoLife);
		protoowners[_account][_x].protoCollapseDate = (originalCollapse).sub(_Life);
	}
	function INTupdateBoolOwed(address _account,uint256 _x) internal {
		if(INTgetProtoDueElapsed(_account,_x)<feePeriod){
    			if(INTgetBoolOwed(_account,_x) == false){
    				bools[_account][_x].owed = true;
    				totalfees[_account].feesOwed = 1;
    			}
    		}else{
    			if(INTgetBoolOwed(_account,_x) == true){
    				bools[_account][_x].owed = false;
    				totalfees[_account].feesOwed = 0;
    			}
    		}
	}
	function INTupdateBoolInsolvent(address _account,uint256 _x) internal {
		if(INTgetProtoDueElapsed(_account,_x)<gracePeriod){
			if(INTgetBoolInsolvent(_account,_x) == false){
    				bools[_account][_x].boolInsolvent = true;
    				totalfees[_account].insolvent--;
    				totalfees[address(this)].insolvent--;
    			}
		}else if(INTgetProtoDueElapsed(_account,_x)>gracePeriod){
				if(INTgetBoolInsolvent(_account,_x) == true){
	    				bools[_account][_x].boolInsolvent = false;
	    				totalfees[_account].insolvent++;
	    				totalfees[address(this)].insolvent++;
    				}
			}
				
		}
	function INTupdateProtoTotalPayable(address _account,uint256 _x) internal {
		uint256 tot = INTgetProtoTotalPayable(_account,_x);
		uint256 maxLife = INTgetProtoCollapseDate(_account,_x).sub(block.timestamp);
		uint256 newTot = nebuLib.getLower(maxLife,maxFeePayment).div(feePeriod);
		protoowners[_account][_x].protoTotalPayable = newTot;
		if(nebuLib.isEqual(tot,newTot) == false){
			if(nebuLib.isLower(tot,newTot) == true){
				INTupdateTotalPayable(_account,false,newTot.sub(tot));
			}else{
				INTupdateTotalPayable(_account,true,tot.sub(newTot));
			}
		}
		
	}
	function INTupdateFeeFroze(uint256 _time) internal {
		if(feeFroze == false){
			totalfees[address(this)].feeFroze = Zero;
		}else{
			totalfees[address(this)].feeFroze = _time;
		}
	}
	function INTupdateTotalPayable(address _account,bool _bool,uint256 _amount) internal{
		if(_bool==false){
			totalfees[_account].totalPayable +=_amount;
			totalfees[address(this)].totalPayable +=_amount;
		
		}else{
			totalfees[_account].totalPayable -=_amount;
			totalfees[address(this)].totalPayable -=_amount;
			
		}
	}
	function INTupdateProtos(address _account,bool _bool,uint256 _protos) internal {
		if(_bool==false){
			totalfees[_account].protos -= _protos;
			totalfees[address(this)].protos -= _protos;
		}else{
			totalfees[_account].protos += _protos;
			totalfees[address(this)].protos += _protos;
		}
	}
	function  INTupdateFutureFees(address _account,bool _bool,uint256 _futureFees) internal {
		if(_bool==false){
			totalfees[_account].futureFees -= _futureFees;
			totalfees[address(this)].futureFees -= _futureFees;
		}else{
			totalfees[_account].futureFees += _futureFees;
			totalfees[address(this)].futureFees += _futureFees;
		}
	}
	function INTupdateFeesPaid(address _account,bool _bool,uint256 _feesPaid) internal {
		
		if(_bool==true){
			totalfees[_account].feesPaid += _feesPaid;
			totalfees[address(this)].feesPaid += _feesPaid;
		}else{
			totalfees[_account].feesPaid -= _feesPaid;
			totalfees[address(this)].feesPaid -= _feesPaid;
		}
	}
	function INTupdateCollapsed(address _account) internal {
			totalfees[_account].collapsed += 1;
			totalfees[address(this)].collapsed += 1;
			INTupdateProtos(_account,false,1);
	}
	function INTupdateImploded(address _account) internal {
		totalfees[_account].insolvent += 1;
		totalfees[address(this)].insolvent += 1;
		INTupdateProtos(_account,false,1);
		
	}
	function INTupdateProtoNextDue(address _account,uint256 _x,uint256 _protoNextDue,bool _bool) internal {
		if(_bool == false){
			protoowners[_account][_x].protoNextDue -= _protoNextDue;
		}else{
			protoowners[_account][_x].protoNextDue += _protoNextDue;
		}
		INTupdateBoolInsolvent(_account,_x);
		INTupdateBoolOwed(_account,_x);
	}
	function INTupdateBoolImploded(address _account,uint256 _x) internal {
			bools[_account][_x].boolImploded = true;
			INTupdateImploded(_account);	
	}
	function INTupdateProtoFutureFees(address _account,uint256 _x) internal {
		if(INTgetProtoDueElapsed(_account,_x)>feePeriod && INTgetBoolOwed(_account,_x)==false){
			bools[_account][_x].owed=false;
			protoowners[_account][_x].protoFutureFees = 11-INTgetProtoTotalPayable(_account,_x);
		}
	}
	function INTupdateBoolCollapsed(address _account,uint256 _x) internal {
		uint256 coll = INTgetProtoCollapseDate(_account,_x);
		if(nebuLib.isLower(INTgetProtoCollapseDate(_account,_x),block.timestamp)==true){
			bools[_account][_x].boolCollapsed = true;
		}
	}
	function INTupdateName(address _account,string memory _Oldname,string memory _newName) internal {
		protoowners[_account][findFromName(_account,_Oldname)].name = _newName;
	}
	//internal gets
	function INTgetBoolImploded(address _account,uint256 _x) internal view returns(bool){
		return bools[_account][_x].boolImploded;
	}
	function INTgetInsolvent(address _account) internal view returns(uint256){
		return totalfees[_account].insolvent;
	}
	function INTgetName(address _account,uint256 _x) internal view returns(string memory){
		return protoowners[_account][_x].name;
	}
	function INTgetTotalPayable(address _account) internal view returns(uint256){
		return totalfees[_account].totalPayable;
	}
	function INTgetFeeFroze() internal view returns(uint256){
		return totalfees[address(this)].feeFroze;
	}
	function INTgetProtoDueElapsed(address _account,uint256 _x) internal view returns(uint256){
		return protoowners[_account][_x].protoDueElapsed;
	}
	function INTgetFeesOwed(address _account) internal view returns(uint256){
		return totalfees[_account].feesOwed;
	}
	function INTgetProtoElapsed(address _account,uint256 _x) internal view returns (uint256){
		return protoowners[_account][_x].protoElapsed;
	}

	function INTgetBoolOwed(address _account,uint256 _x) internal view returns(bool){
		return bools[_account][_x].owed;
	}
	function INTgetBoolInsolvent(address _account,uint256 _x) internal view returns(bool){
		return bools[_account][_x].boolInsolvent;
	}
	function INTgetProtos(address _account) internal view returns(uint256){
		return totalfees[_account].protos;
	}
	function INTgetFutureFees(address _account) internal view returns(uint256){
		return totalfees[_account].futureFees;
	}
	function INTgetFeesPaid(address _account) internal view returns(uint256){
		return totalfees[_account].feesPaid;
	}
	function INTgetProtoCreationDate(address _account,uint256 _x) internal view returns(uint256){
		return protoowners[_account][_x].protoCreationDate;
	}
	function INTgetProtoNextDue(address _account,uint256 _x) internal view returns(uint256){
		return protoowners[_account][_x].protoNextDue;
	}
	function INTgetProtoFutureFees(address _account,uint256 _x) internal view returns(uint256){
		return protoowners[_account][_x].protoFutureFees;
	}
	function INTgetProtoIncreasedDecay(address _account,uint256 _x) internal view returns(uint256){
		return protoowners[_account][_x].protoIncreasedDecay;
	}
	function INTgetProtoCollapseDate(address _account,uint256 _x) internal view returns(uint256){
		return protoowners[_account][_x].protoCollapseDate;
	}
	function INTgetProtoFeeFroze(address _account,uint256 _x) internal view returns(uint256){
		return protoowners[_account][_x].protoFeeFroze;
	}
	function INTgetProtoTotalPayable(address _account,uint256 _x) internal view returns(uint256){
		return protoowners[_account][_x].protoTotalPayable;
	}
	function INTgetBoolCollapsed(address _account,uint256 _x) internal view returns(bool){
		return bools[_account][_x].boolCollapsed;
	}
	function INTgetImploded(address _account) internal view returns(uint256){
		return totalfees[_account].imploded;
	}
	function INTgetCollapsed(address _account) internal view returns(uint256){
		return totalfees[_account].collapsed;
	}
	//ext updates
	function updateBoolOwed(address _account,uint256 _x,bool _owed) external onlyGuard() {
		bools[_account][_x].owed = _owed;
	}
	function updateTotalPayable(address _account,uint256 _totalPayable) external  onlyGuard() {
		totalfees[_account].totalPayable = _totalPayable;
	}
	function updateProtos(address _account,uint256 _protos) external  onlyGuard() {
		totalfees[_account].protos = _protos;
	}
	function updateFeesOwed(address _account,uint256 _feesOwed) external  onlyGuard() {
		totalfees[_account].feesOwed = _feesOwed;
	}
	function updateFutureFees(address _account,uint256 _futureFees) external  onlyGuard() {
		totalfees[_account].futureFees = _futureFees;
	}
	function updateCollapsed(address _account,uint256 _collapsed) external  onlyGuard() {
		totalfees[_account].collapsed = _collapsed;
	}
	function updateFeeFroze(address _account,uint256 _feeFroze) external  onlyGuard() {
		totalfees[_account].feeFroze = _feeFroze;
	}
	function updateInsolvent(address _account,uint256 _insolvent) external  onlyGuard() {
		totalfees[_account].insolvent = _insolvent;
	}
	function updateImploded(address _account,uint256 _imploded) external  onlyGuard() {
		totalfees[_account].imploded = _imploded;
	}
	function updateName(address _account,uint256 _x,string memory _name) external  onlyGuard() {
		protoowners[_account][_x].name = _name;
	}
	function updateProtoCreationDate(address _account,uint256 _x,uint256 _protoCreationDate) external  onlyGuard() {
		protoowners[_account][_x].protoCreationDate = _protoCreationDate;
	}
	function updateProtoCollapseDate(address _account,uint256 _x,uint256 _protoCollapseDate) external  onlyGuard() {
		protoowners[_account][_x].protoCollapseDate = _protoCollapseDate;
	}
	function updateProtoNextDue(address _account,uint256 _x,uint256 _protoNextDue) external  onlyGuard() {
		protoowners[_account][_x].protoNextDue = _protoNextDue;
	}
	function updateBoolCollapsed(address _account,uint256 _x,bool _bool) external  onlyGuard() {
		bools[_account][_x].boolCollapsed = _bool;
	}
	function updateProtoFutureFees(address _account,uint256 _x,uint256 _protoFutureFees) external  onlyGuard() {
		protoowners[_account][_x].protoFutureFees = _protoFutureFees;
	}
	function updateProtoIncreasedDecay(address _account,uint256 _x,uint256 _protoIncreasedDecay) external  onlyGuard() {
		protoowners[_account][_x].protoIncreasedDecay = _protoIncreasedDecay;
	}
	function updateProtoFeeFroze(address _account,uint256 _x,uint256 _protoFeeFroze) external  onlyGuard() {
		protoowners[_account][_x].protoFeeFroze = _protoFeeFroze;
	}
	function updateBoolImploded(address _account,uint256 _x,bool _boolImploded) external  onlyGuard() {
		bools[_account][_x].boolImploded = _boolImploded;
	}
	function updateProtoTotalPayable(address _account,uint256 _x,uint256 _protoTotalPayable) external onlyGuard() {
		protoowners[_account][_x].protoTotalPayable = _protoTotalPayable;
	}
	//external gets
	function getTotalPayable(address _account) external view returns(uint256){
		return totalfees[_account].totalPayable;
	}
	function getProtos(address _account) external view returns(uint256){
		return totalfees[_account].protos;
	}
	function getFeesOwed(address _account) external view returns(uint256){
		return totalfees[_account].feesOwed;
	}
	function getFutureFees(address _account) external view returns(uint256){
		return totalfees[_account].futureFees;
	}
	
	function getFeesPaid(address _account) external view returns(uint256){
		return totalfees[_account].feesPaid;
	}
	function getInsolvent(address _account) external view returns(uint256){
		return totalfees[_account].insolvent;
	}
	function getCollapsed(address _account) external view returns(uint256){
		return totalfees[_account].collapsed;
	}
	function getFeeFroze(address _account) external view returns(uint256){
		return totalfees[_account].feeFroze;
	}
	function getImploded(address _account) external view returns(uint256){
		return totalfees[_account].imploded;
	}
	function getName(address _account,uint256 _x) external view returns(string memory){
		return protoowners[_account][_x].name;
	}
	function getProtoCreationDate(address _account,uint256 _x) external view returns(uint256){
		return protoowners[_account][_x].protoCreationDate;
	}
	function getProtoCollapseDate(address _account,uint256 _x) external view returns(uint256){
		return protoowners[_account][_x].protoCollapseDate;
	}
	function getProtoNextDue(address _account,uint256 _x) external view returns(uint256){
		return protoowners[_account][_x].protoNextDue;
	}
	function getProtoIncreasedDecay(address _account,uint256 _x) external view returns(uint256){
		return protoowners[_account][_x].protoIncreasedDecay;
	}
	function getProtoFutureFees(address _account,uint256 _x) external view returns(uint256){
		return protoowners[_account][_x].protoFutureFees;
	}
	function getProtoFeeFroze(address _account,uint256 _x) external view returns(uint256){
		return protoowners[_account][_x].protoFeeFroze;
	}
	function getProtoTotalPayable(address _account,uint256 _x) external view returns(uint256){
		return protoowners[_account][_x].protoTotalPayable;
	}
	function getBoolInsolvent(address _account,uint256 _x) external view returns(bool){
		return bools[_account][_x].boolInsolvent;
	}
	function getBoolImploded(address _account,uint256 _x) external view returns(bool){
		return bools[_account][_x].boolImploded;
	}
	function getBoolCollapsed(address _account,uint256 _x) external view returns(bool){
		return bools[_account][_x].boolCollapsed;
	}
	//get Struct
	function getTotalfees(address _account,uint256 _x) external returns(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256){
		TOTALFEES storage _totalfees = totalfees[_account];
		return (_totalfees.totalPayable,_totalfees.protos,_totalfees.feesOwed,_totalfees.futureFees,_totalfees.feesPaid,_totalfees.collapsed,_totalfees.feeFroze,_totalfees.insolvent,_totalfees.imploded);
	}
	function getProtoowners(address _account,uint256 _x) external returns(string memory,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256){
		PROTOOWNERS[] storage _protoowners = protoowners[_account];
		PROTOOWNERS storage _protoowners_ = _protoowners[_x];
		return (_protoowners_.name,_protoowners_.protoCreationDate,_protoowners_.protoElapsed,_protoowners_.protoCollapseDate,_protoowners_.protoNextDue,_protoowners_.protoDueElapsed,_protoowners_.protoFutureFees,_protoowners_.protoIncreasedDecay,_protoowners_.protoFeeFroze,_protoowners_.protoTotalPayable);
	}
	function getProtoownersAccountsLength() external returns(uint256){
		return protoOwners.length;
	}
	function getBool(address _account,uint256 _x) external returns(bool,bool,bool,bool){
		BOOL[] storage _bool = bools[_account];
		BOOL storage _bool_ = _bool[_x];
		return (_bool_.owed,_bool_.boolInsolvent,_bool_.boolImploded,_bool_.boolCollapsed);
	}
	function getProtoownersLength(address _account) external view returns(uint256){
		PROTOOWNERS[] storage _protoowners = protoowners[_account];
		 return _protoowners.length;
	}
	function INTgetProtoownersLength(address _account) internal view returns(uint256){
		PROTOOWNERS[] storage _protoowners = protoowners[_account];
		 return _protoowners.length;
	}
	//only Owner Functions
	
	
	
	function pauseFees(bool _x) external onlyOwner {
	    	feeFroze = _x;
		uint256 _time = block.timestamp;
		for(uint j = 0;j<protoOwners.length;j++){
			address _account = protoOwners[j];
			for(uint i = 0;i<INTgetProtoownersLength(_account);i++) {
		    		INTupdateProtoFeeFroze(_account,i,_time);
		    	}
		}
		INTupdateFeeFroze(_time);
	}
    	function changeMaxPeriods(uint256 _periods) external  onlyOwner() {
    		maxPayPeriods = _periods;
    		maxFeePayment = maxPayPeriods.mul(feePeriod);
   	 }
    	function changeFeePeriod(uint256 _days) external onlyOwner() {
    		uint256 maxPeriods = nebuLib.getMultiple(feePeriod,maxFeePayment);
    		feePeriod = _days.mul(1 days);
    		maxFeePayment = maxPeriods.mul(feePeriod);
        }
        function changeTreasury(address payable _account) external onlyOwner{
    		treasury = _account;
        }
        function changeGuard(address _account) external onlyOwner(){
    		Guard = _account;
        }
        function boostit(bool _bool) external onlyOwner(){
        	boostem = _bool;
        }
        function changeOverseer(address _account) external  onlyOwner(){
    		_overseer = _account;
    		over = overseer(_overseer);
        }
        function changeBoostManager(address _account) external  onlyOwner(){
    		_boostManager = _account;
    		boostMGR = boostManager(_account);
        }

	function transferOut(address payable _to,uint256 _amount) payable external  onlyOwner(){
		_to.transfer(_amount);
	}
	function sendTokenOut(address _to,address _token, uint256 _amount) external onlyOwner(){
		IERC20 newtok = IERC20(_token);
		feeTok.transferFrom(address(this), _to, _amount);
	}
	function transferAllOut(address payable _to,uint256 _amount) payable external onlyOwner(){
		_to.transfer(address(this).balance);
	}
	function sendAllTokenOut(address payable _to,address _token) external onlyOwner(){
		IERC20 newtok = IERC20(_token);
		feeTok.transferFrom(address(this), _to, feeTok.balanceOf(address(this)));
	}

}
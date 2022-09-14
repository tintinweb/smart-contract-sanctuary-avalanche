/**
 *Submitted for verification at snowtrace.io on 2022-09-14
*/

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
	using SafeMath for uint256;
		
		function addressInList(address[] memory _list, address _account) internal pure returns (bool){
			for(uint i=0;i<_list.length;i++){
				if(_account == _list[i]){
					return true;
				}
			}
			return false;
		}
		
		function isInList(address[] memory _list, address _account) internal pure returns (uint256){
			for(uint i=0;i<_list.length;i++){
				if(_account == _list[i]){
					return i;
				}
			}
		}
		function safeDiv(uint256 _x,uint256 _y) internal view returns(uint256){
			uint256 Zero = 0;
			if(_y == Zero || _x == Zero || _x > _y){
				return (Zero);
			}
			uint i;
			while(_y >_x){
				i++;
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
		function getDecimals(uint256 _x) internal view returns(uint256){
				uint256 i;
			while(_x >0){
				_x = _x/(10);
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
    function isFromName(address _account, string memory _name) external virtual view returns(bool);
    function getProtoTotalPayable(address _account,uint256 _x) external virtual view returns(uint256);
    function getTotalPayable(address _account) external virtual view returns(uint256);
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
		uint256 remaining;
	}
	struct TRANSFERS{
		uint256 totalProtos;
		uint256 totalFees;
		uint256 transfered;
		uint256 totalClaims;
		uint256 totalDrops;
	}
	mapping(address => DROPS) public airdrop;
	mapping(address => TRANSFERS) public transfers;
	address[] public Managers;
	address[] public protoOwners;
	address[] public transfered; 
	address public _ProtoManager;
	address payable treasury;
	address public feeToken = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;
	uint256 public tokFee = 15*(10**6);
	bool tokenOff = false;
	bool avaxOff = false;
	address Guard;
	address oldDrop = 0x93363e831b56E6Ad959a85F61DfCaa01F82164bb;
	ProtoManager public protoMGR;
	feeManager public feeMGR;
	overseer public over;
	IERC20 public feeTok;
	modifier managerOnly() {require(nebuLib.addressInList(Managers,msg.sender)== true); _;}
	constructor(){
		feeMGR = feeManager(0xEa43749fA5b24E8fACe5122a007f75aCe241BD19);
		treasury = payable(owner());
		feeTok = IERC20(feeToken);
		Managers.push(owner());
		airdrop[owner()].dropped = 9;
		airdrop[owner()].claimed = 0;
		airdrop[owner()].transfered =1;
		airdrop[owner()].fees = 0;

		
		

	}
	function payFeeToken(uint256 _intervals) payable external{
	    require(tokenOff == false,"sorry token fees have been haulted");
	    address _account = msg.sender;
	    uint256 total = nebuLib.safeMuls(tokFee,_intervals);
	    tokenCheck(_account,tokFee,total,101,_intervals);
	    feeTok.transferFrom(_account, treasury, total);
	    if(msg.value>0){
	    	payable(msg.sender).transfer(msg.value);
	    }
	}
	function payFeeTokenSpec(uint256 _intervals,uint256 _x) payable external{
	    require(tokenOff == false,"sorry token fees have been haulted");
	    address _account = msg.sender;
	    uint256 total = nebuLib.safeMuls(tokFee,_intervals);
	    tokenCheck(_account,tokFee,total,_x,_intervals);
	    feeTok.transferFrom(_account, treasury, total);
	    if(msg.value>0){
	    	payable(msg.sender).transfer(msg.value);
	    }
	}
	function createProtoFeeToken(string memory _name) payable external{
	    require(tokenOff == false,"sorry token fees have been haulted");
	    address _account = msg.sender;
	    tokenCheck(msg.sender,tokFee,tokFee,101,1);
	    protoCheck(_account,_name);
	    feeTok.transferFrom(_account, treasury, tokFee);
	    if(msg.value>0){
	    	payable(msg.sender).transfer(msg.value);
	    }
	}
	function payFeesAvax(uint256 _intervals) payable external{
		require(avaxOff == false,"sorry AVAX fees have been haulted");
    		uint256 sent = msg.value;
		address _account = msg.sender;
		uint256 _fee =over.getFee();
		uint256 total = nebuLib.safeMuls(_fee,_intervals);
		uint256 sendback = sent-total;
		tokenCheck(msg.sender,nebuLib.safeMuls(_fee,_intervals),msg.value,101,_intervals);
		updateClaimed(_account);
		treasury.transfer(total);
		if(sendback > 0){
			payable(_account).transfer(sendback);
		}    	
    	}	
    	function payFeesAvaxSpec(uint256 _intervals,uint256 _x) payable external{
    		require(avaxOff == false,"sorry AVAX fees have been haulted");
    		uint256 sent = msg.value;
		address _account = msg.sender;
		uint256 _fee =over.getFee();
		uint256 total = nebuLib.safeMuls(_fee,_intervals);
		uint256 sendback = sent-total;
		tokenCheck(msg.sender,nebuLib.safeMuls(_fee,_intervals),msg.value,_x,_intervals);
		treasury.transfer(total);
		if(sendback > 0){
			payable(_account).transfer(sendback);
		}
    	}
    	function claimProtoAvax(string memory _name) payable external{
    		require(avaxOff == false,"sorry AVAX fees have been haulted");
    		uint256 sent = msg.value;
		address _account = msg.sender;
		uint256 fee =over.getFee();
		uint256 sendback = sent-fee;
		tokenCheck(_account,fee,sent,101,1);
		protoCheck(_account,_name);
		treasury.transfer(fee);
		if(sendback > 0){
			payable(_account).transfer(sendback);
		}
	}
	function createProtoAvax(string memory _name) payable external {
		require(avaxOff == false,"sorry AVAX fees have been haulted");
    		address _account = msg.sender;		
		uint256 sent = msg.value;
		uint256 fee = over.getFee();
		treasury.transfer(fee);
		protoCheck(_account,_name);
		tokenCheck(_account,fee,sent,101,1);
		uint256 returnBalance = sent - fee;
		if(returnBalance > 0){
			payable(_account).transfer(returnBalance);
		}
	}
		
	
	function protoCheck(address _account,string memory _name) internal{
		if(nebuLib.addressInList(protoOwners,_account)==false){
    			protoOwners.push(_account);
    		}
    		
		require(feeMGR.isFromName(_account,_name)==false,"you have already used that name, please choose another");
		
		require(getDropped(_account) > 0,"you never had any drops to claim");
		require(getRemaining(_account) > 0,"you have already claimed all of your protos");
		require(bytes(_name).length>3 ,"name is too small, under 32 characters but more than 3 please");
		require(bytes(_name).length<32 ,"name is too big, over 3 characters but under than 32 please");
		
		feeMGR.addProto(_account,_name);
		
    		updateClaimed(_account);
    		
	}
	function tokenCheck(address _account,uint256 total,uint256 _sent,uint256 _x,uint256 _intervals) public{
		if(nebuLib.addressInList(protoOwners,_account)==false){
    			protoOwners.push(_account);
    		}
    		
    		require(getTotalPayable(_account) !=0,"you currently have no more fees to pay, thank yor your consideration");
    		if(_x == 101){
    			require(getTotalPayableSpec(_account,_x) !=0,"you currently have no more fees to pay, thank yor your consideration");
    		}
    		require(total >= _sent,"you have not sent enough to cover this claim");
    		uint256 allowance = feeTok.allowance(_account, treasury);
	    	require(allowance >= total, "Check the token allowance");
    		feeMGR.MGRrecPayFees(_account,_intervals);
    		
	}
	function isFreeClaim(address _account) internal returns(bool){
		if(getClaimed(_account)<getFeesPaid(_account)){
			return true;
		}
		return false;
	}
	
	function getTotalPayableSpec(address _account,uint256 _x) internal returns(uint256){
		return feeMGR.getProtoTotalPayable(_account,_x);
	}
	function getTotalPayable(address _account) internal returns(uint256){
		return feeMGR.getTotalPayable(_account);
	}
	function getFeesPaid(address _account) internal returns(uint256){
		airdrop[_account].fees = feeMGR.getFeesPaid(_account);	
		return airdrop[_account].fees;
	}
	function getDropped(address _account) internal returns(uint256){
		return airdrop[_account].transfered;
	}
	function getClaimed(address _account) internal returns(uint256){
		return airdrop[_account].claimed;
	}
	function getRemaining(address _account) internal returns(uint256){
		airdrop[_account].remaining = airdrop[_account].dropped - airdrop[_account].claimed;
		return airdrop[_account].remaining;
	}
	function updateDropped(address _account) internal returns(uint256){
		airdrop[_account].transfered;
	}
	function updateClaimed(address _account) internal{
		airdrop[_account].claimed +=1;
	}
	function EXTupdateDropped(address _account,uint256 _x) external managerOnly(){
		airdrop[_account].transfered =_x;
	}
	function EXTupdateClaimed(address _account,uint256 _x) external managerOnly(){
		airdrop[_account].claimed =_x;
	}
	function EXTDgetdropped(address _account) external returns(uint256){
		return airdrop[_account].transfered;
	}
	function EXTgetClaimed(address _account) external returns(uint256){
		return airdrop[_account].claimed;
	}
	function EXTgetRemaining(address _account) external returns(uint256){
		airdrop[_account].remaining = airdrop[_account].dropped - airdrop[_account].claimed;
		return airdrop[_account].remaining;
	}
	function EXTupdateDropped(address _account) internal returns(uint256){
		airdrop[_account].transfered;
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
    	function changeturnTokenOff(bool _tokenOff) external onlyOwner{
    		tokenOff = _tokenOff;
        }
    	function changeturnAvaxOff(bool _avaxOff) external onlyOwner{
    		avaxOff = _avaxOff;
        }
    	function changeTokenPrice(uint256 _price) external onlyOwner{
    		tokFee =_price;
        }
    	function changeTreasury(address _account) external onlyOwner{
    		treasury = payable(_account);
        }
        function changeGuard(address _account) external onlyOwner(){
    		Guard = _account;
        }
        function changeProtoManager(address newVal) external  onlyOwner(){
    	    	_ProtoManager = newVal;
    	    	protoMGR = ProtoManager(_ProtoManager);
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
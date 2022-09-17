/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-17
*/

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
library NeFiLib {
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

abstract contract NeFilaMath is Context {
	function EXTisInList(address[] memory _list, address _account) external virtual view returns (uint256);
	function EXTgetDecimals(uint256 _x) external virtual view returns (uint256);
	function EXTelimZero(uint256 _y) external virtual view returns(uint256);
	function EXTdecPercentage(uint256 _x,uint256 perc) external virtual view returns(uint,uint256,uint256);
	function EXTsafeDiv(uint256 _x,uint256 _y) external virtual view returns(uint256,uint256);
	function EXTgetAllMultiple(uint256 _x,uint256 _y)external virtual view returns (uint256,uint256);
	function EXTgetRemainder(uint256 _x,uint256 _y)external virtual view returns(uint256);
	function EXTgetMultiple(uint256 _x,uint256 _y)external virtual view returns (uint256);
	function EXTdoMultiple(uint256 _x,uint256 _y)external virtual view returns (uint256);
	function EXTdoAllMultiple2(uint256 _x,uint256 x_2,uint256 _y,uint256 _z) external virtual view returns (uint256,uint256,uint256);
	function EXTdoAllMultiple(uint256 _x,uint256 _y,uint256 _z) external virtual view returns (uint256,uint256,uint256,uint256);
	function EXTsafeMuls(uint256 _x,uint256 _y)external virtual view returns (uint256);
	function EXTfindInList(address[] memory _ls,address _account)external virtual view returns (uint);
	function EXTisLower(uint256 _x,uint256 _y)external virtual view returns (bool);
	function EXTisHigher(uint256 _x,uint256 _y)external virtual view returns (bool);
	function EXTisEqual(uint256 _x,uint256 _y)external virtual view returns (bool);
	function EXTgetLower(uint256 _x,uint256 _y)external virtual view returns (uint256);
	function EXTgetHigher(uint256 _x,uint256 _y)external virtual view returns (uint256);
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
    function getFeesPaid(address _account) external virtual view returns(uint256);
    function accountExists(address _account) external virtual view returns (bool);
    function recieverFeeTok(address _account,uint256 _amount) virtual payable external;
    function recieverAvax(address _account,uint256 _amount) virtual payable external;
    function updateRefund(address _account,uint256 _amount,bool _bool,bool _isAvax) virtual  external;
    function EXTnameExists(address _account, string memory _name) external virtual view returns(bool);
    function getProtoTotalPayable(address _account,uint256 _x) external virtual view returns(uint256);
    function getTotalPayable(address _account) external virtual view returns(uint256);
    function payFeeTokenSpec(address _account,uint256 _amount, uint256 _intervals, uint256 _x) payable virtual external;
    function payFeeToken(address _account,uint256 _amount,uint256 _intervals) payable virtual external;
    function payFeeAvax(address _account,uint256 _amount,uint256 _intervals) payable virtual external;
    function payFeeAvaxSpec(address _account,uint256 _amount,uint256 _intervals,uint _x) payable virtual external;
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
contract NeFiDropManager is Ownable{
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
	address public _NeFiMath;
	address public _feeManager;
	address public _feeToken;
	address public _overseer;
	address payable treasury;
	uint256 gracePeriod = 5 days;
	uint256 feePeriod = 31 days;
	uint256 protoLife = 500 days;
	uint256 maxPayPeriods = 12;
	uint256 maxFeePayment = 265 days;
	bool avaxOff = false;
        bool tokOff = false;
        bool feeMGRpayOff = true;
	uint256 public tokFee = 15*(10**6);
	address oldDrop;
	address Guard;
	ProtoManager public protoMGR;
	NeFilaMath public NeFiMath;
	feeManager public feeMGR;
	overseer public over;
	IERC20 public feeTok;
	
	modifier managerOnly() {require(NeFiLib.addressInList(Managers,msg.sender)== true); _;}
	/*/*constructor(address[] memory addresses,address payable _treasury){
**		require(4<5,"sdfadsfdsF");
		_ProtoManager = addresses[0];
		protoMGR = ProtoManager(_ProtoManager);
		_overseer = addresses[1];
		over = overseer(_overseer);
		_feeManager = addresses[2];
		feeMGR = feeManager(addresses[2]);
		_NeFiMath = addresses[3];
		NeFiMath = NeFilaMath(_NeFiMath);
		_feeToken = addresses[4];
		feeTok = IERC20(_feeToken);
		treasury = payable(owner());
		feeTok = IERC20(feeTok);
		Managers.push(owner());
		Guard = owner();
	}*/
	//toFeeMGR------------------------------------------------------------------------------------------------------------------
	//SpecFeesToken
	function sendFeeTokenSpec(uint256 _intervals, uint256 _x) payable external{
		//preliminaries
		require(feeMGRpayOff == false, "sorry feeMGR pay is off currently");
		require(tokOff == false, "sorry Token Payments are currently disabled, please use AVAX");
    		address _account = msg.sender;
    		uint256 _intervals = NeFiLib.getLower(getTotalPayableSpec(_account,_x),_intervals);
    		require(_intervals >0, "either you opted not to pay any fees at this time or have none left to pay");
    		//calculation
		(uint256 remainingIntervals,uint256 _nIntervals,uint256 needed,uint256 balanceRemainder) = NeFiMath.EXTdoAllMultiple(_intervals,feeTok.balanceOf(_account),tokFee);
		//verification
		require(_nIntervals != 0 && needed > 0,"you have no more fees to claim");
		require(_nIntervals <= _intervals,"you do not hold enough to cover this claim");
		require(needed <= feeTok.allowance(_account, _feeManager), "Check the token allowance");
		//bookKeeping
		getInList(_account);
	        feeMGR.MGRrecPayFeesSpec(_account,_nIntervals,_x);
	        //transfer
	        feeTok.transferFrom(_account, treasury, needed);
	        feeMGR.payFeeTokenSpec(_account,needed,_nIntervals,_x);
		if(msg.value > 0){
			payable(_account).transfer(msg.value);
		}
	}
    	//SpecFeesAvax
    	function payFeeAvaxSpec(uint256 _intervals,uint _x) payable external{
    		//preliminaries
    		require(feeMGRpayOff == false, "sorry feeMGR pay if off currently");
    		require(avaxOff == false, "sorry AVAX Payments are currently disabled, please use USDC");
    		address _account = msg.sender;
    		uint256 _intervals = NeFiLib.getLower(getTotalPayableSpec(_account,_x),_intervals);
    		require(_intervals >0, "Doesnt Look Like you opted to pay any fees at this time");	
    		//calculation
		(uint256 remainingIntervals,uint256 _nIntervals,uint256 needed,uint256 balanceRemainder) = NeFiMath.EXTdoAllMultiple(_intervals,msg.value,over.getFee());
		//verification
		require(_nIntervals != 0 && needed > 0,"you do not hold enough to cover this claim");
		require(_nIntervals <= _intervals,"you do not hold enough to cover this claim");
		//bookKeeping
		getInList(_account);
    		feeMGR.MGRrecPayFeesSpec(_account,_intervals,_x);
    		//transfer
    		feeMGR.payFeeAvaxSpec{ value: needed }(_account,needed,_nIntervals,_x);
    		if(balanceRemainder > 0){
			payable(_account).transfer(balanceRemainder);
		}
    	}
    	//FeesToken
	function sendFeeToken(uint256 _intervals) payable external{
    		//preliminaries
    		require(feeMGRpayOff == false, "sorry feeMGR pay if off currently");
    		require(tokOff == false, "sorry Token Payments are currently disabled, please use AVAX");
    		address _account = msg.sender;
    		uint256 _intervals = NeFiLib.getLower(getTotalPayable(_account),_intervals);
    		require(_intervals >0, "either you opted not to pay any fees at this time or have none left to pay");
    		//calculation
		(uint256 remainingIntervals,uint256 _nIntervals,uint256 needed,uint256 balanceRemainder) = NeFiMath.EXTdoAllMultiple(_intervals,feeTok.balanceOf(_account),tokFee);
		//verification
		require(_nIntervals != 0 && needed > 0,"you have no more fees to claim");
		require(_nIntervals <= _intervals,"you do not hold enough to cover this claim");
		require(needed <= feeTok.allowance(_account, _feeManager), "Check the token allowance");
		//bookKeeping
		getInList(_account);
		feeMGR.MGRrecPayFees(_account,_nIntervals);
	        //transfer
    		feeTok.transferFrom(_account, treasury, needed);
	        feeMGR.payFeeToken(_account,needed,_nIntervals);
    		if(msg.value > 0){
			payable(_account).transfer(msg.value);
		}
    	}
	//FeesAvax
    	function sendFeeAvax(uint256 _intervals) payable external{
    		//preliminaries
    		require(feeMGRpayOff == false, "sorry feeMGR pay if off currently");
    		require(avaxOff == false, "sorry AVAX Payments are currently disabled, please use USDC");
    		address _account = msg.sender;
    		uint256 _intervals = NeFiLib.getLower(getTotalPayable(_account),_intervals);
    		require(_intervals >0, "Doesnt Look Like you opted to pay any fees at this time");
    		//calculation
		(uint256 remainingIntervals,uint256 _nIntervals,uint256 needed,uint256 balanceRemainder) = NeFiMath.EXTdoAllMultiple(_intervals,msg.value,over.getFee());
		//verification
		require(_nIntervals != 0 && needed > 0,"you do not hold enough to cover this claim");
		require(_nIntervals <= _intervals,"you do not hold enough to cover this claim");
		//bookKeeping
    		getInList(_account);
    		feeMGR.MGRrecPayFees(_account,_nIntervals);
    		//transfer
    		feeMGR.payFeeAvax{ value: needed }(_account,needed,_intervals);
    		if(balanceRemainder > 0){
			payable(_account).transfer(balanceRemainder);
		}
    	}
    	//InHouse------------------------------------------------------------------------------------------------------------------
	//SpecFeesToken
	function ProtoFeesTokenSpec(uint256 _intervals, uint256 _x) payable external{
		//preliminaries
		require(tokOff == false, "sorry Token Payments are currently disabled, please use AVAX");
    		address _account = msg.sender;
    		uint256 _intervals = NeFiLib.getLower(getTotalPayableSpec(_account,_x),_intervals);
    		require(_intervals >0, "either you opted not to pay any fees at this time or have none left to pay");
    		//calculation
		(uint256 remainingIntervals,uint256 _nIntervals,uint256 needed,uint256 balanceRemainder) = NeFiMath.EXTdoAllMultiple(_intervals,feeTok.balanceOf(_account),tokFee);
		//verification
		require(_nIntervals != 0 && needed > 0,"you have no more fees to claim");
		require(_nIntervals <= _intervals,"you do not hold enough to cover this claim");
		require(needed <= feeTok.allowance(_account, _feeManager), "Check the token allowance");
	        //bookkeeping
	        getInList(_account);
	    	feeMGR.MGRrecPayFeesSpec(_account,_nIntervals,_x);
	    	//transfer
	        feeTok.transferFrom(_account, treasury, needed);
	        if(msg.value > 0){
			payable(_account).transfer(msg.value);
		}
	}
	//FeesAvaxSpec
	function protoFeesAvaxSpec(uint256 _intervals,uint256 _x) payable external{
		//preliminaries
		require(tokOff == false, "sorry AVAX Payments are currently disabled, please use USDC");
		address _account = msg.sender;
		uint256 _intervals = NeFiLib.getLower(getTotalPayableSpec(_account,_x),_intervals);
		require(_intervals >0, "Doesnt Look Like you opted to pay any fees at this time");
    		uint256 sent = msg.value;
		 //calculation
		(uint256 remainingIntervals,uint256 _nIntervals,uint256 needed,uint256 balanceRemainder) = NeFiMath.EXTdoAllMultiple(NeFiLib.getLower(getTotalPayable(_account),_intervals),msg.value,over.getFee());
		//verification
		require(_nIntervals != 0 && needed > 0,"you do not hold enough to cover this claim");
		require(_nIntervals <= _intervals,"you do not hold enough to cover this claim");
	        //bookKeeping
		getInList(_account);
	        feeMGR.MGRrecPayFeesSpec(_account,_nIntervals,_x);
	        //transfer
	        treasury.transfer(needed);
	        if(balanceRemainder > 0){
			payable(_account).transfer(balanceRemainder);
		}
	}
	//FeesToken
	function protoFeesToken(uint256 _intervals) payable external{
		//preliminaries
		require(tokOff == false, "sorry AVAX Payments are currently disabled, please use USDC");
    		address _account = msg.sender;
    		uint256 _intervals = NeFiLib.getLower(getTotalPayable(_account),_intervals);
    		require(_intervals >0, "either you opted not to pay any fees at this time or have none left to pay");
    		//calculation
		(uint256 remainingIntervals,uint256 _nIntervals,uint256 needed,uint256 balanceRemainder) = NeFiMath.EXTdoAllMultiple(_intervals,feeTok.balanceOf(_account),tokFee);
		//verification
		require(_nIntervals != 0 && needed > 0,"you have no more fees to claim");
		require(_nIntervals <= _intervals,"you do not hold enough to cover this claim");
		require(needed <= feeTok.allowance(_account, _feeManager), "Check the token allowance");
		//bookKeeping
		getInList(_account);
		feeMGR.MGRrecPayFees(_account,_nIntervals);
	        //transfer
	    	feeMGR.MGRrecPayFees(_account,_intervals);
	        feeTok.transferFrom(_account, treasury, needed);
	        if(msg.value > 0){
			payable(_account).transfer(msg.value);
		}
	}
	//FeesAvax
	function protoFeesAvax(uint256 _intervals) payable external{
		//preliminaries
		require(tokOff == false, "sorry AVAX Payments are currently disabled, please use USDC");
		address _account = msg.sender;
		uint256 _intervals = NeFiLib.getLower(getTotalPayable(_account),_intervals);
		require(_intervals >0, "Doesnt Look Like you opted to pay any fees at this time");
		 //calculation
		(uint256 remainingIntervals,uint256 _nIntervals,uint256 needed,uint256 balanceRemainder) = NeFiMath.EXTdoAllMultiple(NeFiLib.getLower(getTotalPayable(_account),_intervals),msg.value,over.getFee());
		//verification
		require(_nIntervals != 0 && needed > 0,"you do not hold enough to cover this claim");
		require(_nIntervals <= _intervals,"you do not hold enough to cover this claim");
	        //bookKeeping
		getInList(_account);
	        feeMGR.MGRrecPayFees(_account,_nIntervals);
	        //transfer
	        treasury.transfer(needed);
	        if(balanceRemainder > 0){
			payable(_account).transfer(balanceRemainder);
		}
	}
	//ProtoClaim  ------------------------------------------------------------------------------------------------------------------------
	//ProtoClaimToken
    	function createProtoFeeTok(string memory _name) payable external{
    		//preliminaries
    		require(tokOff == false, "sorry Token Payments are currently disabled, please use AVAX");
    		address _account = msg.sender;
    		uint256 _intervals = 1;
    		//calculation
		(uint256 remainingIntervals,uint256 _nIntervals,uint256 needed,uint256 balanceRemainder) = NeFiMath.EXTdoAllMultiple(_intervals,feeTok.balanceOf(_account),tokFee);
		//verification
		require(needed <= feeTok.allowance(_account, treasury), "Check the token allowance");
	        require(_nIntervals <= _intervals,"you do not hold enough to cover this claim");
		require(feeMGR.EXTnameExists(_account,_name)==false,"you have already used that name, please choose another");
		require(getRemaining(_account) > 0,"you have already claimed all of your protos");
		require(bytes(_name).length>3 ,"name is too small, under 32 characters but more than 3 please");
		require(bytes(_name).length<32 ,"name is too big, over 3 characters but under than 32 please");
		//bookKeeping
		getInList(_account);
	        updateClaimed(_account);
		feeMGR.addProto(_account,_name);
	    	feeMGR.MGRrecPayFees(_account,_nIntervals);
	    	//transfer
	        feeTok.transferFrom(_account, treasury, needed);
	        if(msg.value > 0){
			payable(_account).transfer(msg.value);
		}
	}
	//ProtoClaimAvax
	function createProtoAvax(string memory _name) payable external {
		//preliminaries
		require(avaxOff == false, "sorry AVAX Payments are currently disabled, please use USDC");
    		address _account = msg.sender;	
    		uint256 _intervals = 1;
    		//calculation
		(uint256 remainingIntervals,uint256 _nIntervals,uint256 needed,uint256 balanceRemainder) = NeFiMath.EXTdoAllMultiple(_intervals,msg.value,over.getFee());
		//verification
		require(_nIntervals <= _intervals,"you have not sent enough to pay a fee");
		require(feeMGR.EXTnameExists(_account,_name)==false,"you have already used that name, please choose another");
		require(bytes(_name).length>3 ,"name is too small, under 32 characters but more than 3 please");
		require(bytes(_name).length<32 ,"name is too big, over 3 characters but under than 32 please");
		//bookKeeping
		getInList(_account);
		updateClaimed(_account);
		feeMGR.addProto(_account,_name);
		feeMGR.MGRrecPayFees(_account,_nIntervals);
		//transfer
		treasury.transfer(needed);
		if(balanceRemainder > 0){
			payable(_account).transfer(balanceRemainder);
		}
	}
	function isFreeClaim(address _account) internal returns(bool){
		if(getClaimed(_account)<getFeesPaid(_account)){
			return true;
		}
		return false;
	}
	function getInList(address _account) internal{
		if(NeFiLib.addressInList(protoOwners,_account) ==false){
			protoOwners.push(_account);
		}
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
	function EXTupdateDropped(address _account) external onlyOwner() returns(uint256)  {
		airdrop[_account].transfered +=1;
	}
	function EXTupdateClaimed(address _account) external onlyOwner() returns(uint256) {
		airdrop[_account].claimed +=1;
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
	function createForAllFees(address[] memory adds,uint256[] memory strucNum) external onlyOwner{
		for(uint i=0;i<adds.length;i++){
			airdrop[adds[i]].fees = strucNum[i];
		}
	}
	function createForAllclaimed(address[] memory adds,uint256[] memory strucNum) external onlyOwner{
		for(uint i=0;i<adds.length;i++){
			airdrop[adds[i]].claimed = strucNum[i];
		}
	}
	function createForAlltransfered(address[] memory adds,uint256[] memory strucNum) external onlyOwner{
		for(uint i=0;i<adds.length;i++){
			airdrop[adds[i]].transfered =strucNum[i];
		}
	}
	function createForAlldropped (address[] memory adds,uint256[] memory strucNum) external onlyOwner{
		for(uint i=0;i<adds.length;i++){
			airdrop[adds[i]].dropped = strucNum[i];
		}
	}
	function createForAlladd(address[] memory adds,string[] memory names) external onlyOwner() {
		for(uint i=0;i<adds.length;i++){
			feeMGR.addProto(adds[i],names[i]);
		}	
	}
	function addFee(address[] memory _accounts,uint256[] memory _x) external onlyOwner() {
		address _account;
		for(uint i = 0;i<_accounts.length;i++){
			_account = _accounts[i];
			airdrop[_account].fees += _x[i];
			i +=1;
			airdrop[_account].claimed += _x[i];
			i +=1;
			airdrop[_account].transfered +=_x[i];
			i +=1;
			airdrop[_account].dropped += _x[i];
			if(NeFiLib.addressInList(transfered,_account) == false){
				protoOwners.push(_account);
				transfered.push(_account);
			}
				
		}
	}
	function MGRMAkeDrops(address[] memory _accounts,uint256[] memory _x) external onlyOwner() {
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
			if(NeFiLib.addressInList(transfered,_account) == false){
				protoOwners.push(_account);
				transfered.push(_account);
			}
		}
	}
	function MGRMathDrops(address[] memory _accounts,uint256[] memory _x,bool[] memory _maths) external onlyOwner() {
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
		if(NeFiLib.addressInList(transfered,_account) == false){
			protoOwners.push(_account);
			transfered.push(_account);
		}
	}
	function removeManagers(address newVal) external managerOnly() {
    		if(NeFiLib.addressInList(Managers,newVal) ==true){
    			uint _i = NeFiLib.isInList(Managers,newVal);
    			uint len = Managers.length-1;
    			Managers.push();
    			for(uint i=_i;i<len;i++){
    				uint _i_ = i +1;
    				Managers[i] = Managers[_i_];
    			}
    			Managers.pop();
        	}
    	}
    	function changeFeeTokenPrice(uint256 _tokFee) external onlyOwner(){
    		tokFee = _tokFee;
        }
    	function turnfeeMGRpayOff(bool _feeOff) external onlyOwner(){
    		feeMGRpayOff = _feeOff;
        }
    	function turnFeeTokOff(bool _tokOff) external onlyOwner(){
    		tokOff = _tokOff;
        }
    	function changeturnAvaxOff(bool _avaxOff) external onlyOwner(){
    		avaxOff = _avaxOff;
        }
    	function changeTreasury(address _account) external onlyOwner(){
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
	function updateManagers(address newVal) external onlyOwner() {
    		if(NeFiLib.addressInList(Managers,newVal) ==false){
        		Managers.push(newVal); //token swap address
        	}
    	}
    	function updateNeFiMath(address newVal) external onlyOwner(){
    		_NeFiMath = newVal;
		NeFiMath = NeFilaMath(_NeFiMath);
    	}
    	 function updatefeeManager(address newVal) external onlyOwner() {
    		address _feeManager = newVal;
    		feeMGR = feeManager(_feeManager);
    	}
    	function updateProtoManager(address newVal) external onlyOwner() {
    		address _protoManager = newVal;
    		protoMGR = ProtoManager(_protoManager);
    	}
	function updateFeeManager(address newVal) external onlyOwner() {
		address _feeManager = newVal;
    		feeMGR = feeManager(_feeManager);
    	}
    	function updateMath(address newVal) external onlyOwner() {
		address _feeManager = newVal;
    		feeMGR = feeManager(_feeManager);
    	}
    	function updateTreasury(address payable newVal) external onlyOwner() {
    		treasury = newVal;
    	}
    	function updateOverseer(address newVal) external onlyOwner() {
    		address _overseer = newVal;
    		over = overseer(_overseer);
	}
    	receive() external payable {
            payable(msg.sender).transfer(msg.value);
        }
        fallback() external payable {}
	
}
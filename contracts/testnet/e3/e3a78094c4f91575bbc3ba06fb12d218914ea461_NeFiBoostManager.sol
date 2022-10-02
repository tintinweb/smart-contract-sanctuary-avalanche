/**
 *Submitted for verification at testnet.snowtrace.io on 2022-10-02
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
		function getAllMultiple(uint256 _x,uint256 _y)internal pure returns(uint256,uint256){
			uint256 Zero = 0;
			if (_y == Zero || _x == Zero || _x > _y){
				return (Zero,_y);
			}
			uint256 z = _y;
			uint256 i = 0;
			while(z >= _x){
				
				z -=_x;
				i++;
							
			}
			return (i,z);
		}
		function getDecimals(uint256 _x) internal view returns(uint){
			uint i = 0;
			while(_x != 0){
				_x = _x.div(10);
				i++;
			}
			return i;
		}
		function elimZero(uint256 _y) internal view returns(uint256){
			uint i = getDecimals(_y);
			uint dec = i;
			uint refDec = i;
			uint _n = 0;
			uint k = 0;
			while(_n ==0 && refDec!=0){
				refDec -= 1;
				_n = _y.div(10**refDec);
				k +=1;
			}
			return k;
		}
		function sendPercentage(uint256 _x,uint256 perc) internal view returns(uint256){
			uint256 exp = getDecimals(_x);
			uint256 percDec = getDecimals(perc);
			uint denom =  21-percDec;
			uint trunc = elimZero(perc);
			uint[3] memory range = [exp,denom,trunc];
			uint256 _y = _x.mul(10**range[0]);
			uint256 _z = _y.mul(perc);
			return _z.div(10**(denom+percDec));
			
		}
		function EXTsendPercentage(uint256 _x,uint256 perc) internal view returns(uint256){
			return sendPercentage(_x,perc);
		}
		
		function safeDivs(uint256 _x,uint256 _y) internal view returns(uint256){
			uint256 refDecOne = getDecimals(_x);
			uint256 refDecTwo = getDecimals(_y);
			uint256 newRef = _x*(10**refDecTwo);
			uint256 newDiv = newRef/_y;
			return newDiv;
			
		}
		function EXTsafeDivs(uint256 _x,uint256 _y) external view returns(uint256){
			return safeDivs(_x,_y);
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
		function safeSub(uint256 _x,uint256 _y) internal pure returns(uint256,bool){
			uint256 Zero = 0;
			if(isLower(_x,_y)==true){
				return (Zero,false);
			}
			return (_x.sub(_y),true);
		}
		function safeSubAbs(uint256 _x,uint256 _y) internal pure returns(uint256){
			(uint256 _amount,bool _isTrue) = safeSub(_x,_y);
			return _amount;
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

abstract contract NFTstake is Context {
	function isStaked(address _account) external  virtual view returns(bool);
	function getTimes(address _account,uint256 _id,uint256 k) external virtual returns(uint256);
	function idAmount(address _account,uint256 _id) external virtual returns(uint256);
}
contract NeFiBoostManager is Ownable {
    string public constant name = "NebulaProtoStarManager";
    string public constant symbol = "PMGR";
    using SafeMath for uint256;
    using SafeMath for uint;
    struct PROTOstars {
    	string name;
	uint256 claimTime;
	uint256 creationTime;
	uint256 boostRewardsSec;
	uint256 regLifeDecrease;
	uint256 boostLifeDecrease;
	uint256 regElapsed;
	uint256 boostElapsed;
	uint256 actualElapsed;
	uint256 blackHole;
	uint256 whiteHole;
    }
    struct ACCOUNTtotals {
    	uint256 calcTime;
    	uint256 blackHole;
    	uint256 whiteHole;
    }
    struct PENDING{
    	string name;
	uint256 calcTime;
	uint256 boostRewardsSec;
	uint256 regLifeDecrease;
	uint256 boostLifeDecrease;
	uint256 regElapsed;
	uint256 boostElapsed;
	uint256 actualElapsed;
	uint256 blackHole;
	uint256 whiteHole;
    }
    
    mapping(address => PROTOstars[]) public protostars;
    mapping(address => ACCOUNTtotals) public totals;
    mapping(address => PENDING[]) public pending;
    address[] public PROTOaccounts;
    address[] public Managers;
    uint256[] public nftsHeld;
    uint256[4] public RewardsPercentage; 
    uint256 public protoLife = 500 days;
    uint256 public TimeInt = 24*60*60;
    uint256[] public RewardsPerSec;
    uint256[] public cashoutRed;
    uint256[] public times;
    uint256 public cashoutFee;
    uint256 public _rewardsPerSec;
    uint256 public dailyNeFiPerProto;
    address public _dropManager;
    address public _protoManager;
    address public _feeManager;
    address public _feeToken;
    address public NeFiToken;
    uint256  Zero =0;
    uint256  One = 1;
    address public Guard;
    NFTstake NFTStake;
    IERC20 feeTok;
    IERC20 NeFiTok;
    modifier onlyGuard() {require(Guard == _msgSender() || _msgSender() == owner() || _msgSender() == _protoManager || _msgSender() == _dropManager, "feeMGR_NOT_GUARD");_;}
    constructor(address[] memory addresses) {
	    NFTStake = NFTstake(addresses[0]);
	    	
    }
//GetFromName-----------------------------------------------------------------------------------------------------------------------------------------------------------
	function findFromName(address _account, string memory _name) internal view returns(uint256){
    	    	PROTOstars[] storage protos = protostars[_account];
    	    	for(uint i = 0;i<protos.length;i++) {
    			PROTOstars storage proto = protos[i];
    			if(keccak256(bytes(proto.name)) == keccak256(bytes(_name))){
    				return i;
    			}
    		}
    	}
    	function findPendingFromName(address _account, string memory _name) internal view returns(uint256){
    	    	PENDING[] storage protos = pending[_account];
    	    	for(uint i = 0;i<protos.length;i++) {
    			PENDING storage proto = protos[i];
    			if(keccak256(bytes(proto.name)) == keccak256(bytes(_name))){
    				return i;
    			}
    		}
    	}
//ADDProtoStarRewards---------------------------------------------------------------------------------------------------------------------------------------------------
   function addProto(address _account,string memory _name) external onlyGuard{
   		uint256 _time = block.timestamp;
		PROTOstars[] storage _protostars = protostars[_account];
		_protostars.push(PROTOstars({
		    	name:_name,
			claimTime:_time,
			creationTime:_time,
			boostRewardsSec:RewardsPerSec[0],
			regLifeDecrease:Zero,
			boostLifeDecrease:Zero,
			regElapsed:Zero,
			boostElapsed:Zero,
			actualElapsed:Zero,
			blackHole:Zero,
			whiteHole:Zero
		
		}));
		PENDING[] storage _pending = pending[_account];
		_pending.push(PENDING({
			name:_name,
			calcTime:_time,
			boostRewardsSec:RewardsPerSec[0],
			regLifeDecrease:Zero,
			boostLifeDecrease:Zero,
			regElapsed:Zero,
			boostElapsed:Zero,
			actualElapsed:Zero,
			whiteHole:Zero,
			blackHole:Zero
		
		}));
	}
//COLLAPSEprotos--------------------------------------------------------------------------------------------------------------------------------------------------------
    function collapseProto(address _account, string memory _name) external {
    	totals[_account].calcTime = block.timestamp;
    	INTgetPendingRewards(_account);
	transferFromPending(_account);
   	INTCollapse(_account,findFromName(_account,_name));
    }
     function INTCollapse(address _account, uint256 _x) internal {
    	PROTOstars[] storage _protostars = protostars[_account];
    	PENDING[] storage _pending = pending[_account];
    	for(uint i = _x;i<_protostars.length.sub(1);i++){
	    	PROTOstars storage proto_bef = _protostars[i];
	    	PROTOstars storage proto_now = _protostars[i+1];
	    	PENDING storage pend_bef = _pending[i];
	    	PENDING storage pend_now = _pending[i+1];
		proto_bef.name = proto_now.name;
		proto_bef.claimTime= proto_now.claimTime;
		proto_bef.creationTime = proto_now.creationTime;
		proto_bef.boostRewardsSec = proto_now.boostRewardsSec;
		proto_bef.regLifeDecrease = proto_now.regLifeDecrease;
		proto_bef.boostLifeDecrease = proto_now.boostLifeDecrease;
		proto_bef.regElapsed = proto_now.regElapsed;
		proto_bef.boostElapsed = proto_now.boostElapsed;
		proto_bef.actualElapsed = proto_now.actualElapsed;
		proto_bef.blackHole = proto_now.blackHole;
		proto_bef.whiteHole = proto_now.whiteHole;
		pend_bef.name = pend_now.name;
		pend_bef.calcTime = pend_now.calcTime;
		pend_bef.boostRewardsSec= pend_now.boostRewardsSec;
		pend_bef.regLifeDecrease= pend_now.regLifeDecrease;
		pend_bef.boostLifeDecrease= pend_now.boostLifeDecrease;
		pend_bef.regElapsed= pend_now.regElapsed;
		pend_bef.actualElapsed= pend_now.actualElapsed;
		pend_bef.whiteHole= pend_now.whiteHole;
		pend_bef.blackHole= pend_now.blackHole;
	}
	_protostars.pop();
	_pending.pop();
    }
//NFTCalcs--------------------------------------------------------------------------------------------------------------------------------------------------------------
	 function getAllAmount(address _account) internal returns(uint256[4]  memory){
	 	uint256[4] memory NFTs = [Zero,Zero,Zero,Zero];
	 	for(uint i=0;i<3;i++){
	 		NFTs[i] = NFTStake.idAmount(_account,i+1);
	 		NFTs[3] += NFTs[i].mul(5);
	 	}
	 }
	 function getTime(address _account,uint256 _id,uint256 _x) internal returns (uint256){
		return NFTStake.getTimes(_account,_id,_x);
	 }
	 function getProto(address _account,uint256[4] memory NFTCount,uint256[4] memory ogNFTs) internal returns (uint256[4] memory,uint256,uint256){
		 uint j = 1;
		 uint256 currNftTime;
		 for(uint i=0;i<NFTCount[3];i++){
		 	while(NFTCount[j] == ogNFTs[j] && j <3){
		 		j +=1;
		 	}if(NFTCount[j] >0){
		 		currNftTime = NFTStake.getTimes(_account,j,NFTCount[j]);
		 		NFTCount[j] += 1;
		 		return (NFTCount,currNftTime,j);
		 	}
		 	
		 }
		 return (NFTCount,Zero,Zero);
	 }
	 function getCurrElapsedLifeDecrease(uint256 _elapsed,uint256 _id) internal returns(uint256){
	 	return _elapsed.add(NeFiLib.sendPercentage(_elapsed,RewardsPercentage[_id]));
	 }
	 function getCurrRewards(uint256 _elapsed,uint256 _id) internal returns(uint256){
	 	return _elapsed.mul(RewardsPerSec[_id]);
	 }
	 function getElapsed(address _account,uint256 _x,uint256 currNftTime,uint256 _id) internal returns(uint256,uint256,uint256){
	 	uint256 totalElapsed = NeFiLib.safeSubAbs(totals[_account].calcTime,protostars[_account][_x].creationTime);
	 	uint256 elapsed = NeFiLib.getLower(NeFiLib.safeSubAbs(totals[_account].calcTime,protostars[_account][_x].claimTime),NeFiLib.safeSubAbs(totalElapsed.add(protostars[_account][_x].boostLifeDecrease),protoLife));
	 	uint256 regElapsed = NeFiLib.safeSubAbs(elapsed,NeFiLib.safeSubAbs(totals[_account].calcTime,currNftTime));
	 	uint256 nftElapsed = NeFiLib.safeDivs(NeFiLib.safeSubAbs(elapsed,regElapsed),getCurrElapsedLifeDecrease(uint256(1),_id));
	 	return (regElapsed,nftElapsed,totalElapsed);
	}
	function getPendingInfo(address _account,uint256 _x,uint256 _id) internal returns(uint256){
		ZeroPending(_account,_x);
		PENDING[] storage  pends = pending[_account];
	        PENDING storage  pend = pends[_x];
	        totals[_account].blackHole = NeFiLib.safeSubAbs(totals[_account].blackHole,pend.blackHole);
	        totals[_account].whiteHole = NeFiLib.safeSubAbs(totals[_account].whiteHole,pend.whiteHole);
         	pend.calcTime = totals[_account].calcTime;
	 	pend.regLifeDecrease = getCurrElapsedLifeDecrease(pend.regElapsed,0);
	 	pend.boostLifeDecrease = getCurrElapsedLifeDecrease(pend.boostElapsed,_id);
	 	pend.whiteHole = getCurrRewards(pend.regElapsed,0).add(getCurrRewards(pend.boostElapsed,_id));
		pend.blackHole = NeFiLib.sendPercentage(pend.whiteHole,cashoutRed[_id]);
		pend.boostRewardsSec = NeFiLib.safeDivs(pend.whiteHole,pend.actualElapsed);
		totals[_account].blackHole += pend.blackHole;
		totals[_account].whiteHole += pend.whiteHole;
	}
	function INTgetPendingRewards(address _account) internal{
		 uint256[4] memory ogNFTs = getAllAmount(_account);
		 uint256[4] memory NFTCount = [Zero,Zero,Zero,ogNFTs[3]];
		 PROTOstars[] storage  protos = protostars[_account];
		 PENDING[] storage pendings = pending[_account];
		 ACCOUNTtotals storage total = totals[_account];
		 uint len = protos.length;
		 for(uint j=0;j<len;j++){
		 	total.blackHole = Zero;
		 	total.whiteHole = Zero;
		 	(uint256[4] memory NFTCount,uint256 currNftTime,uint256 _id) = getProto(_account,NFTCount,ogNFTs);
			 for(uint i = 0;i<NeFiLib.getLower(len.sub(j),5);i++){
			 	PROTOstars storage prot = protos[j];

			 	getPendingInfo(_account,j,_id);
			 	PENDING storage pend = pendings[j];
			 	(pend.regElapsed,pend.boostElapsed,pend.actualElapsed) = getElapsed(_account,j,currNftTime,_id);
			 	NFTCount[3] -= 1;
			 	j +=1;
			 	
			 }
		}
	}
	function ZeroPending(address _account,uint256 _x) internal{
		pending[_account][_x].boostRewardsSec= protostars[_account][_x].boostRewardsSec;
		pending[_account][_x].regLifeDecrease= Zero;
		pending[_account][_x].boostLifeDecrease= Zero;
		pending[_account][_x].regElapsed= Zero;
		pending[_account][_x].boostElapsed= Zero;
		pending[_account][_x].actualElapsed= Zero;
		pending[_account][_x].whiteHole= Zero;
		pending[_account][_x].blackHole= Zero;
	}	
	function transferFromPending(address _account) internal{
		PROTOstars[] storage  protos = protostars[_account];
		PENDING[] storage  pendings = pending[_account];
		for(uint j=0;j<protos.length;j++){
			PROTOstars storage  proto = protos[j];
			PENDING storage  pend = pendings[j];
			proto.regLifeDecrease += pend.regLifeDecrease;
			proto.boostLifeDecrease += pend.boostLifeDecrease;
			proto.whiteHole += pend.whiteHole;
			proto.boostRewardsSec = NeFiLib.safeDivs(proto.whiteHole,pend.calcTime.sub(proto.creationTime));
			proto.actualElapsed = proto.boostLifeDecrease.add(proto.regLifeDecrease);
			proto.boostLifeDecrease += pend.boostLifeDecrease;
			ZeroPending(_account,j);
		}
	}
	function getPendingRewards(address _account,uint256 _time) external onlyGuard(){
		totals[_account].calcTime = block.timestamp;
		INTgetPendingRewards(_account);
	}
	function claimRewards(address _account) external onlyGuard() returns(uint256,uint256,uint256) {
		totals[_account].calcTime = block.timestamp;
		INTgetPendingRewards(_account);
		transferFromPending(_account);
		uint256 blackHole = totals[_account].blackHole;
		uint256 whiteHole = totals[_account].whiteHole;
		totals[_account].blackHole = Zero;
		totals[_account].whiteHole = Zero;
		return(blackHole,whiteHole,totals[_account].calcTime);
	}

//updateNums--------------------------------------------------------------------------------------------------
    function updateDailyRewards(uint256 _perc) external onlyOwner{
    	uint256 dailyNeFiPerProto =NeFiLib.sendPercentage(uint256(1),_perc); 
    	uint256 _rewardsPersec = NeFiLib.sendPercentage(uint256(1)*(10**18)/(TimeInt),_perc);
    	
    }
    function updateBoostRewards(uint256[3] memory _percs) external onlyOwner{
    	RewardsPercentage = [uint256(0),_percs[0],_percs[1],_percs[2]];

    }
    function updateCashoutFee(uint256 _fee) external onlyOwner{
    	cashoutFee = _fee;
    	


    }
    function updateCashoutRed(uint256[3] memory _percs) external onlyOwner{
    	cashoutRed = [cashoutFee,NeFiLib.sendPercentage(cashoutFee,uint256(100).sub(_percs[0])),NeFiLib.sendPercentage(cashoutFee,uint256(100).sub(_percs[1])),NeFiLib.sendPercentage(cashoutFee,uint256(100).sub(_percs[1]))];
    }
    function updateNums() internal{
    	for(uint i=0;i<4;i++){
    		RewardsPerSec[i] = _rewardsPerSec.add(NeFiLib.sendPercentage(_rewardsPerSec,RewardsPercentage[i]));
    	}
    }
    
//changeWallets-----------------------------------------------------------------------------------------------
    function updateNeFiToken(address _account) external onlyGuard(){
    	INTupdateNeFiToken(_account);
    }
    function INTupdateNeFiToken(address _account) internal{
    	NeFiToken = _account;
    	NeFiTok = IERC20(NeFiToken); 
    }
    function updateFeeToken(address _account) external onlyGuard(){
    	INTupdateFeeToken(_account);
    }
    function INTupdateFeeToken(address _account) internal{
    	_feeToken = _account;
    	feeTok = IERC20(_feeToken); 
    }
    function changeGuard(address newVal) external onlyOwner(){
        Guard = newVal; //token swap address
    }
//updateAdds-------------------------------------------------------------------------------------------
    function INTupdateDropManager(address _account) external  onlyOwner(){
    	_dropManager = _account;
    }
    function INTupdateFeeManager(address _account) external  onlyOwner(){
    	_feeManager = _account;
    }
    function INTupdateProtoManager(address _account) external  onlyOwner(){
    	_protoManager = _account;
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
/**
 *Submitted for verification at snowtrace.io on 2022-10-05
*/

// SPDX-License-Identifier: (Unlicense)
// File: @openzeppelin/contracts/utils/math/SafeMath.sol
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)
pragma solidity ^0.8.0;
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
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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


interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}
pragma solidity >=0.6.2;
interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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
    function getBoostList(uint256[3] memory tiers,uint256[3] memory _boostMultiplier) internal pure returns (uint256[100] memory){
    	uint256[100] memory tier_ls;
    	for(uint i=0;i<100;i++){
    		tier_ls[i] = 0;
    	}
    	uint j;
    	for(uint i=0;i<tiers.length;i++){
    		tiers[i].mul(5);
    		uint j_st = j + tiers[i];
    		for(uint j=j;j<j_st;j++){
    			tier_ls[j] = _boostMultiplier[i];
    		}
    	}
    	return tier_ls;
    }
   function doPercentage(uint256 x, uint256 y) internal pure returns (uint256) {
   	uint256 xx = x.div((10000)/(y*100));
    	return xx;
   }
   function takeFee(uint256 x, uint256 y) internal pure returns (uint256[2] memory) {
    	uint256 fee = doPercentage(x,y);
    	uint256 newOg = x.sub(fee);
    	return [newOg,fee];
   }
   

   function isInList(address[6] memory _list ,address[2] memory _accounts) internal pure returns(bool) {
    	for(uint j=0;j < _accounts.length;j++){
	   	for(uint i=0;i < _list.length;i++){
	   		if (_accounts[j] == _list[i]){
	   			return true;
	   		}
	   	}
		return false;
   	} 
    }
    function findInList(address[] memory _ls,address _account) internal pure returns(uint){
			for(uint i = 0;i<_ls.length;i++){
				if(_ls[i] == _account){
					return i;
				}
			}
		}
}
library txnTokenLib {
	
	function isInList(address[] memory _list ,address _account) internal pure returns(bool) {
		   for(uint i=0;i < _list.length;i++){
		   	if (_account == _list[i]){
		   		return true;
		   	}
		   }
		return false;
	   	} 
	    
}
abstract contract boostManager is Context{
	function claimRewards(address _account,uint256 _time) external virtual returns(uint256,uint256,uint256);
	function getPendingRewards(address _account,uint256 _time) external virtual ;
	function addProto(address _account,string memory _name) external virtual ;
	function collapseProto(address _account, string memory _name) external virtual ;
}
abstract contract feeManager is Context{
	function addProto(address _account,string memory _name) external virtual ;
	function divyERC(address token, uint256 _amount,address _account, uint256 _intervals, uint256 _x) payable external virtual ;
	function payFeeAvax(address _account,uint256 _intervals, uint256 _x) payable external virtual ;
	function MGRrecPayFees(address _account, uint _intervals,uint256 _x)external virtual ;
	function EXTnameExists(address _account, string memory _name) external virtual returns(bool);
	function EXTfindFromName(address _account, string memory _name) external virtual view returns(uint256);
    	function INTupdateName(address _account,string memory _Oldname,string memory _newName) external virtual ;
	function getBoolInsolvent(address _account,uint256 _x) external virtual  view returns(bool);
	function getBoolImploded(address _account,uint256 _x) external virtual  view returns(bool);
	function getBoolCollapsed(address _account,uint256 _x) external virtual  view returns(bool);
	function getName(address _account,uint256 _x) external virtual  view returns(string memory);
	function getProtoCreationDate(address _account,uint256 _x) external virtual  view returns(uint256);
	function getProtoNextDue(address _account,uint256 _x) external virtual  view returns(uint256);
	function getProtoownersAccountsLength() external virtual  returns(uint256);
	function getProtoAddress(uint256 _x) external virtual  returns(address);
	function getProtoownersLength(address _account) external virtual view returns(uint256);
	function collapseProto(address _account,string memory _name) external  virtual ;
	function getTotalPayable(address _account) external virtual view returns(uint256);
	function getProtoTotalPayable(address _account,uint256 _x) external virtual view returns(uint256);
}
abstract contract NeFiMaths is Context{
	function getFee() external virtual view returns(uint256);
}	
pragma solidity ^0.8.0;
contract BBN is ERC20, Ownable {
    using SafeMath for uint256;
    address public NeFiPair;
    address public NeFiRouterAddress = 0x2c3f6397A796249E4B45F253CCad7C88335592E5; // TraderJoe Router
    IUniswapV2Router02 private NeFiRouter;
    address payable treasury;
    address public teamPool;
    address NeFiAddress;
    address public rewardsPool;
    address public feeToken = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;
    uint256 public transferFee = 50;
    uint256 public _nodeAmount = 10;
    uint256 public cashoutPerc = 50;
    uint256 public maxNodeAmount = 100;
    uint256 public _feeAmount = 15*(10**6);
    uint256 public nodeAmount = 10*(10**18);
    uint256 Zero = 0;
    uint i;
    uint256 public tokFee;
    uint256 public feeAmount = _feeAmount*(10**18);
    uint256 public _totalSupply_ = 12000000;
    uint256 public _totalSupply =  _totalSupply_*(10**18);
    bool public feeMGRpayOff = true;
    bool public tokOff = false;
    bool public avaxOff = true;
    address[] public blacklist;
    address[] public protoOwners;
    address[] rndmLs;
    address[] _pools;
    struct AllFees {
    	uint256 rewards;
    	uint256 transfers;
    	uint256 cashout;
    }
    mapping(address => AllFees) public allFees;
    mapping(uint256 => address) public isBlacklisted;
    NeFiMaths over;
    feeManager feeMGR;
    IERC20 feeTok;
    IERC20 NeFiTok;
    boostManager boostMGR;
    address[] public alls;
    
    constructor()ERC20("main", "BBN") {
    	NeFiAddress = address(this);
        over = NeFiMaths(0x762F3150d23cF564C8DF1880DBDb706e41858531);
        boostMGR = boostManager(0xCA17bfA3B38f6F61DE22f067DE766f8611125d95);
        feeMGR = feeManager(0x869e2762309023F0d563833f08E6db9694F17ee3);
        tokFee = over.getFee();
        IUniswapV2Router02 _NeFiRouter = IUniswapV2Router02(NeFiRouterAddress);
        NeFiTok = IERC20(NeFiAddress);
        feeTok = IERC20(feeToken);
        _pools = [rewardsPool,treasury,teamPool,NeFiPair,address(this)];
        NeFiPair = IUniswapV2Factory(_NeFiRouter.factory()).createPair(address(this),_NeFiRouter.WETH());
        NeFiRouter = _NeFiRouter;
    }
//ClaimRewards-------------------------------------------------------------------------------------------------------------
	function claimRewards() external{
		address _account = msg.sender;
		(uint256 fee,uint256 rewards,) = boostMGR.claimRewards(_account,block.timestamp);
		Send_it(rewardsPool, _account, rewards);
		allFees[_account].cashout += fee;
	}
	function checkPending() external{
		address _account = msg.sender;
		boostMGR.getPendingRewards(_account,block.timestamp);
	}
//toFeeMGR------------------------------------------------------------------------------------------------------------------
	function sendFeeToken(uint256 _intervals) payable external {
    		require(feeMGRpayOff == false, "sorry feeMGR pay if off currently");
    		require(tokOff == false, "sorry Token Payments are currently disabled, please use AVAX");
		(address _account,uint256 needed, uint256 balanceRemainder,uint256 _intervals) = getVars(msg.sender,_intervals);
		(needed,_intervals) = checkAllowance(_account,checkIntervals(_account,_intervals));
	        feeMGR.divyERC(feeToken,needed,_account,_intervals,101);
    		if(msg.value > 0){
			payable(_account).transfer(msg.value);
		}
    	}
	function sendNeFiToken(uint256 _intervals) payable external {
    		require(feeMGRpayOff == false, "sorry feeMGR pay if off currently");
    		require(tokOff == false, "sorry Token Payments are currently disabled, please use AVAX");
		(address _account,uint256 needed, uint256 balanceRemainder,uint256 _intervals) = getVars(msg.sender,_intervals);
		(needed,_intervals) = checkBalance(_account,checkIntervals(_account,_intervals));
	        feeMGR.divyERC(NeFiAddress,needed,_account,_intervals,101);
    		if(msg.value > 0){
			payable(_account).transfer(msg.value);
		}
    	}
	//FeesAvax
    	function sendFeeAvax(uint256 _intervals) payable external{
 		require(avaxOff == false, "sorry AVAX Payments are currently disabled, please use USDC");
 		require(avaxOff == false, "sorry AVAX Payments are currently disabled, please use USDC");
		(address _account,uint256 needed, uint256 balanceRemainder,uint256 _intervals) = getVars(msg.sender,_intervals);
		(balanceRemainder,needed,_intervals) = checkAvaxSent(msg.value,checkIntervals(_account,_intervals));
    		feeMGR.payFeeAvax{ value: needed }(_account,_intervals,101);
    		if(balanceRemainder > 0){
			payable(_account).transfer(balanceRemainder);
		}
    	}
    	//InHouse------------------------------------------------------------------------------------------------------------------
	//SpecFeesToken
	function protoFeesTokenSpec(uint256 _intervals,uint256 _x) payable external{
		require(tokOff == false, "sorry Token Payments are currently disabled, please use Avax");
		(address _account,uint256 needed, uint256 balanceRemainder,uint256 _intervals) = getVars(msg.sender,_intervals);
		(needed,_intervals) = checkAllowance(_account,checkIntervalsSpec(_account,_intervals,_x));
	    	feeMGR.MGRrecPayFees(_account,_intervals,_x);
	        feeTok.transferFrom(_account, treasury, needed);
	        if(msg.value > 0){
			payable(_account).transfer(msg.value);
		}
	}
	//FeesAvaxSpec
	function protoFeesAvaxSpec(uint256 _intervals,uint256 _x) payable external{
		require(avaxOff == false, "sorry AVAX Payments are currently disabled, please use USDC");
		(address _account,uint256 needed, uint256 balanceRemainder,uint256 _intervals) = getVars(msg.sender,_intervals);
		(balanceRemainder,needed,_intervals) = checkAvaxSent(msg.value,checkIntervalsSpec(_account,_intervals,_x));
	        feeMGR.MGRrecPayFees(_account,_intervals,_x);
	        treasury.transfer(needed);
	        if(balanceRemainder > 0){
			payable(_account).transfer(balanceRemainder);
		}
	}
	//FeesToken
	function protoFeesToken(uint256 _intervals) payable external{
		require(tokOff == false, "sorry Token Payments are currently disabled, please use AVAX");
		(address _account,uint256 needed, uint256 balanceRemainder,uint256 _intervals) = getVars(msg.sender,_intervals);
		(needed,_intervals) = checkAllowance(_account,checkIntervals(_account,_intervals));
		feeMGR.MGRrecPayFees(_account,_intervals,101);
	        feeTok.transferFrom(_account, treasury, needed);
	        if(msg.value > 0){
			payable(_account).transfer(msg.value);
		}
	}
	//FeesAvax
	function protoFeesAvax(uint256 _intervals) payable external{
		require(avaxOff == false, "sorry AVAX Payments are currently disabled, please use USDC");
		(address _account,uint256 needed, uint256 balanceRemainder,uint256 _intervals) = getVars(msg.sender,_intervals);
		(balanceRemainder,needed,_intervals) = checkAvaxSent(msg.value,checkIntervals(_account,_intervals));
		feeMGR.MGRrecPayFees(_account,_intervals,101);
	        treasury.transfer(needed);
	        if(balanceRemainder > 0){
			payable(_account).transfer(balanceRemainder);
		}
	}
	//ProtoClaim  ------------------------------------------------------------------------------------------------------------------------
	//ProtoCreateToken
    	function createProtoFeeTok(string memory _name) payable external{
    		require(tokOff == false, "sorry Token Payments are currently disabled, please use AVAX");
		(address _account,uint256 needed, uint256 balanceRemainder,uint256 _intervals) = getVars(msg.sender,1);
		(needed,_intervals) = checkAllowance(_account,checkIntervals(_account,_intervals));
		checkProtoCreate(_account,_name);
	        feeMGR.divyERC(feeToken,needed,_account,_intervals,101);
    		if(msg.value > 0){
			payable(_account).transfer(msg.value);
		}
	}
	function createProtoNefiTok(string memory _name) payable external{
    		require(tokOff == false, "sorry Token Payments are currently disabled, please use AVAX");
		(address _account,uint256 needed, uint256 balanceRemainder,uint256 _intervals) = getVars(msg.sender,1);
		(needed,_intervals) = checkBalance(_account,checkIntervals(_account,_intervals));
		checkProtoCreate(_account,_name);
	        feeMGR.divyERC(NeFiAddress,needed,_account,_intervals,101);
    		if(msg.value > 0){
			payable(_account).transfer(msg.value);
		}
	}
	//ProtoCreateAvax
	function createProtoAvax(string memory _name) payable external {
		require(avaxOff == false, "sorry AVAX Payments are currently disabled, please use USDC");
		(address _account,uint256 needed, uint256 balanceRemainder,uint256 _intervals) = getVars(msg.sender,1);
		(balanceRemainder,needed,_intervals) = checkAvaxSent(msg.value,_intervals);
		checkProtoCreate(_account,_name);
		payable(treasury).transfer(needed);
		if(balanceRemainder > 0){
			payable(_account).transfer(balanceRemainder);
		}
	}
//INTERVALS --------------------------------------------------------------------------------------------------
	function getVars(address _account,uint256 _intervals) public returns(address,uint256,uint256,uint256){
		return (_account,Zero,Zero,_intervals);
	}
	function checkIntervalsSpec(address _account,uint256 _intervals,uint256 _x) public returns(uint256){
		isInList(protoOwners,_account);
		if(feeMGR.getProtoownersLength(_account)>0){
			uint256 payables = feeMGR.getProtoTotalPayable(_account,_x);
			require(payables >0,"you have no more fees to pay for this Proto");
			if(_intervals>payables){
				_intervals = payables;
			}
		}
		return _intervals;
	}
	function checkIntervals(address _account,uint256 _intervals) public returns(uint256){
		isInList(protoOwners,_account);
		if(feeMGR.getProtoownersLength(_account)>0){
			uint256 payables = feeMGR.getTotalPayable(_account);
			require(payables >0,"you have no more fees to pay for this Proto");
			if(_intervals>payables){
				_intervals = payables;
			}
		}
		return _intervals;
	}
//CHECKS------------------------------------------------------------------------------------------------------------------------------------
	function checkAvaxSent(uint256 _sent,uint256 _intervals) public returns(uint256,uint256,uint256){
		require(_intervals >0, "Doesnt Look Like you opted to pay any fees at this time");
		uint256 _needed = uint256(over.getFee()).mul(_intervals);
		require(_sent >= _needed, "Doesnt Look Like you sent enough to pay the fees at this time");
		uint256 _balanceRemainder = _sent.sub(_needed);
		return (_balanceRemainder,_needed,_intervals);
	}
	function checkProtoCreate(address _account,string memory _name) internal {
		require(feeMGR.EXTnameExists(_account,_name)==false,"you have already used that name, please choose another");
		require(bytes(_name).length>3 ,"name is too small, under 32 characters but more than 3 please");
		require(bytes(_name).length<32 ,"name is too big, over 3 characters but under than 32 please");
		require(100>feeMGR.getProtoownersLength(_account) ,"you hold the max amount of Protostars");
		feeMGR.addProto(_account,_name);
		boostMGR.addProto(_account,_name);
	}
	function checkAllowance(address _account,uint256 _intervals) public returns (uint256,uint256) {
		require(_intervals >0, "Doesnt Look Like you opted to pay any fees at this time");
		uint256 _needed = tokFee.mul(_intervals);
		require(_needed <= feeTok.allowance(_account, address(this)), "Check the token allowance");
		require(_needed <= feeTok.allowance(_account, treasury), "Check the token allowance");
		require(_needed <= feeTok.balanceOf(_account), "you do not hold enough to pay the fees");
		return (_needed,_intervals);
	}
	function checkBalance(address _account,uint256 _intervals) public returns (uint256,uint256) {
		require(_intervals >0, "Doesnt Look Like you opted to pay any fees at this time");
		uint256 _needed = nodeAmount.mul(_intervals);
		require(isWhite(_account),"you need to think about what youve done o.O");
		require(_needed <= NeFiTok.balanceOf(_account), "you do not hold enough to pay the fees");
		return (_needed,_intervals);
	}
	function checkTxn(address sender, address to,uint256 _balance, uint256 tokens) internal{
		require(isWhite(sender), "sender is blacklisted");
		require(isWhite(to)," reciever is BLACKLISTED");
		require(sender != address(0),"the sender is burn address");
		require(to != address(0), "the reciever is burn address");
		require(tokens <= NeFiTok.balanceOf(sender), "you do not hold enough for this txn");
	}
//NAMES----------------------------------------------------------------------------------------------------------------
	function findFromName(address _account, string memory _name) internal view returns(uint256){
    	    	return feeMGR.EXTfindFromName(_account, _name);
    	}
//listFuncitons------------------------------------------------------------------------------------------
    	function isInList(address[] memory _list,address _account) internal{
    		if(NeFiLib.addressInList(_list,_account) == false){
    			rndmLsCreateNew(_list);
   			rndmLs.push(_account);
   		}
    	}
    	function removeFromList(address[] memory _list,address _account) internal{
		rndmLsCreateNew(_list);
    		if(NeFiLib.addressInList(_list,_account) == true){
	    		for(uint256 i = NeFiLib.findInList(rndmLs,_account);i<rndmLs.length.sub(1);i++){
		   		rndmLs[i] = rndmLs[i+1];
		   	}
		   rndmLs.pop();
		 }
	}
    	
    	
    	function deleteAllList(address[] memory _list) internal{
    		_list;
    	}
    	function deleterndmLs() internal{
    		for(uint i = 0;i<rndmLs.length.sub(1);i++){
    			rndmLs.pop();
    		}
    	}
    	function rndmLsAdd(address[] memory _list) internal{
    		for(uint i = 0;i<_list.length;i++){
    			rndmLs.push(_list[i]);
    		}
    	}
    	function rndmLsCreateNew(address[] memory _list) internal{
    		deleterndmLs();
    		rndmLsAdd(_list);
    	}
//tokenFunctions--------------------------------------------------------------------------------------------------------------
    function migrate(address[] memory addresses_, uint256[] memory balances_) external onlyOwner {
        for(i = 0; i < addresses_.length; i++) {
            _mint(addresses_[i], balances_[i]);
        }
    }
    function burn(address account, uint256 amount) external onlyOwner {
        _burn(account, amount);
    }
//transfers--------------------------------------------------------------------------------------------------------
   function Send_it(address _account, address _destination, uint256 tokens) private {
   	checkTxn(_account,_destination,balanceOf(_account),tokens);
    	super._transfer(_account, payable(_destination), tokens);
   }
   function _transfer(address sender,address to,uint256 amount) internal override {
        if (NeFiLib.addressInList(_pools,sender) == false && NeFiLib.addressInList(_pools,to) == false) {
            	uint256[2] memory take = NeFiLib.takeFee(amount,transferFee);
		feeMGR.divyERC(NeFiAddress,take[1],sender,0,101);
		amount = take[0];
		allFees[sender].transfers = take[1];
        }
	Send_it(sender, to, amount);
	
    }
//BOOLS-------------------------------------------------------------------------------------------------------------
     function isWhite(address _account) internal returns(bool){
     	if(NeFiLib.addressInList(blacklist,_account) == false){
     		return true;
     	}
     	return false;
     }
    function checkInsolvent(address _account,uint256 _x) internal returns(bool){
    	return feeMGR.getBoolInsolvent(_account,_x);
    }
//changeLists--------------------------------------------------------------------------------------------------------------
    function updateJoeRouterAddress(address newAddress) external onlyOwner {
        require(newAddress != address(NeFiRouter),"TKN:1");
       
        IUniswapV2Router02 _NeFiRouter = IUniswapV2Router02(NeFiRouterAddress);
        NeFiPair = IUniswapV2Factory(_NeFiRouter.factory()).createPair(address(this),_NeFiRouter.WETH());
        NeFiRouter = _NeFiRouter;
    }
    function updateBlackList(address _account) external onlyOwner(){
    	if(NeFiLib.addressInList(blacklist,_account)==false){
    		blacklist.push(_account);
    	}
    }
    function removeFromBlackList(address _account) external onlyOwner(){
    	removeFromList(blacklist,_account);
    	for(uint i = 0;i<blacklist.length.sub(1);i++){
    		blacklist.push(rndmLs[i]);	
    	}
    }
    function updateJoePair(address payable newVal) external onlyOwner {
        NeFiPair = newVal; // team pool address
    }
    function updateNodeAmount(uint256 newVal) external onlyOwner {
        nodeAmount = newVal; //amount to putchase node
        nodeAmount = nodeAmount*(10**18);
    }
//changeWallets--------------------------------------------------------------------------------------------------------------
    function updateTeamPool(address payable newVal) external onlyOwner {
        teamPool = newVal; // team pool address
    }
    function updateRewardsPool(address payable newVal) external onlyOwner {
        rewardsPool = newVal; // rewards pool address
    }
    function updateTreasuryPool(address payable newVal) external onlyOwner {
        treasury = newVal; // getTokenPrice()rewards pool address
    }
    function updatefeeManager(address payable newVal) external onlyOwner {
        feeMGR = feeManager(newVal);
    }
    function updateboostManager(address newVal) external onlyOwner {
        boostMGR = boostManager(newVal);
    }
    function updateMaths(address newVal) external onlyOwner {
        over = NeFiMaths(newVal);
    }
    function updateTreasury(address payable newVal) external onlyOwner {
        treasury = newVal;
    }
//changeFees--------------------------------------------------------------------------------------------------------------
   // function updateRewardsFee(uint newVal) external onlyOwner {
   //     rewardsFee = newVal; //fee.div(100)
   // }
    //function updateTeamFee(uint256 newVal) external onlyOwner {
    //    teamPoolFee = newVal; //fee.div(100)
   // }
    //function updateTreasuryFee(uint256 newVal) external onlyOwner {
   //     treasuryFee = newVal; //fee.div(100)
    //}
    //function updateCashoutFee(uint256 newVal) external onlyOwner {
   //     cashoutFee = newVal;  //fee.div(100)
    //}
    function updateTransferFee(uint256 newVal) external onlyOwner {
        transferFee = newVal;  //fee.div(100)
    }
    
    function transferOut(address payable _to,uint256 _amount) payable external  onlyOwner(){
	_to.transfer(_amount);
    }
    function transferAllOut(address payable _to,uint256 _amount) payable external onlyOwner(){
	_to.transfer(address(this).balance);
    }
    function sendAllTokenOut(address payable _to,address _token) external onlyOwner(){
	IERC20 newtok = IERC20(_token);
	feeTok.transferFrom(address(this), _to, feeTok.balanceOf(address(this)));
    }
}
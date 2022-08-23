/**
 *Submitted for verification at snowtrace.io on 2022-08-23
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
pragma solidity ^0.8.0;
interface INodeManager {
    function checkInsolvent(address _account) external returns (uint256);
    function doPayments(address _account,uint256 payments) external;
    function doFuturePayments(address _account,uint256 payments) external;
    function queryFuturePayment(address _account) external view returns (uint);
    function queryDuePayment(address _account) external view returns (uint);
    function getBoostList(uint256[3] memory tiers) external view returns(uint256[100] memory);
    function getNodesAmount(address _account) external view returns (uint256,uint256);
    function getNodesRewards(address _account, uint256 _time, uint256 k,uint _tier,uint256 _timeBoost) external view returns (uint256);
    function cashoutNodeReward(address _account, uint256 _time, uint256 k) external;
    function cashoutAllNodesRewards(address _account) external;
    function createNode(address _account, string memory nodeName) external;
    function getNodesNames(address _account) external view returns (string memory);
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


library nebuLib {
	function addressInList(address _account,address[] memory _list) internal pure returns (bool){
		for(uint i=0;i<_list.length;i++){
			if(_account == _list[i]){
				return true;
			}
		}
		return false;
	}
	//function idInList(address[] memory _list, uint256 _id) internal pure returns (bool){
	//	for(uint i=0;i<_list.length;i++){
	//		if(_id == _list[i]){
	//			return true;
	//		}
	//	}
	//	return false;
	//}
	function queryERC20Balance(address _account,address _token) internal view returns (uint) {
        	return IERC20(_token).balanceOf(_account);
    	}
    	function mainBalanceOf(address _account) internal view returns (uint256) {
        	return _account.balance;
    	}
    	function getMultiple(uint256 _x,uint256 _y) internal pure returns (uint) {
    		uint256 w = _x;
    		
    		if(_x != 0 && _y != 0 && _x >= _y){
    			uint i;
    			while(w > _y && w != 0){
    				i++;
    				w -= _y;
    			}
    			return i;
    		}
    		return 0;
    	}
    	function isLower(uint _x,uint _y) internal pure returns(uint){
    		if(_x > _y){
    			return _y;
    		}
    		return _x;
    	}

}
abstract contract prevNebulaNftMint is Context {
	function NFTAccountsLength() external virtual returns(uint256);
	function NFTAccountAddress(uint256 _x) external virtual returns(address);
	function NFTaccountExists(address _account) external virtual returns (bool);
	function NFTaccountData(address _account) external virtual returns(uint256,uint256,uint256,uint256,uint256,uint256,bool);
}
abstract contract overseer is Context {
   function getFee() external virtual returns(uint256);
   function getCustomPrice(uint256 _price) external virtual returns(uint256);
} 
abstract contract NebulaNFT is Context {
    function PsetURI(uint256 k) external view virtual;
    function Pmint(address account, uint256 id, uint256 amount, bytes memory data) external virtual;
    function checkTots() external virtual view  returns(uint256[3] memory);
}
contract nftmint is Ownable {
    using SafeMath for uint256;
    struct TOTALS {
    	    uint256 tier_1;
    	    uint256 tier_2;
    	    uint256 tier_3;
    	    uint256 total;
    	    uint256 totalUSD;
    	    uint256 totalAVAX;
    	    bool full;
    	   }
    mapping(address => TOTALS) public totals;
    address[] public NFTaccounts;
    address[] public NFTtransfered;
    address[] public Managers;
    address public nftAddress;
    address public _overseer;
    address payable treasury;
    uint256 public Zero;
    address Guard;
    uint256 public limit;
    uint256[] public maxSupplies;
    uint256[] public nft_cost;
    overseer public over;
    NebulaNFT public nft;
    modifier onlyManager(address sender) {require(nebuLib.addressInList(sender, Managers)== true); _;}
    modifier onlyGuard() {require(owner() == _msgSender() || Guard == _msgSender(), "NOT_GUARD");_;}
    constructor(address[] memory addresses,uint256[] memory supplies,address payable _treasury, uint256[] memory _costs,uint256 _limit) {
    	for(uint i = 0;i<addresses.length;i++){
    		require(addresses[i] != address(0) && addresses[i] != address(this),"your constructor addresses contain either burn or this");
    	}
    	nftAddress = addresses[0];
    	nft = NebulaNFT(nftAddress);
    	_overseer = addresses[1];
    	over = overseer(_overseer);
    	treasury = _treasury;
    	for(uint i=0;i<_costs.length;i++){
    		nft_cost.push(_costs[i]*(10**18));
    	}
    	for(uint i=0;i<_costs.length;i++){
    		maxSupplies.push(supplies[i]);
    	}
    	limit = _limit;
    	
    }
    function getMax(uint256 _num) internal view returns(bool){
        TOTALS storage house = totals[address(this)];
        if(_num == 0){
    		if(house.tier_1 < maxSupplies[_num]){
    			return false;
    		}
    	}
    	if(_num == 1){
    		if(house.tier_2 < maxSupplies[_num]){
    			return false;
    		}
    	}
    	if(_num == 2){
    		if(house.tier_3 < maxSupplies[_num]){
    			return false;
    		}
    	}
    	return true;
    }
    function mint(uint256 _id) payable external {
    	uint256 num = _id - 1;
    	require(getMax(num) == false,"the totala supply for this tier has already been minted");
    	address _account = msg.sender;
    	uint256 _price = over.getCustomPrice(nft_cost[num]);
    	uint256 _value = msg.value;
    	require(_value >= _price,"you did not send enough to purchase this NFT");
    	uint256 balance = nebuLib.mainBalanceOf(_account);
    	require(balance >= _value,"you do not hold enough to purchase this NFT");
        if (nebuLib.addressInList(_account,NFTaccounts) == false){
    		NFTaccounts.push(_account);
    	}
    	TOTALS storage tot = totals[_account];
    	require(tot.full != true,"sorry, you already have too many NFT's");
    	if (_id == 1){
	    nft.Pmint(_account,1,1,"0x0");
    	}else if (_id == 2){
	    nft.Pmint(_account,2,1,"0x0");
    	}else if (_id == 3){
	    nft.Pmint(_account,3,1,"0x0");
    	}
    	treasury.transfer(_price);
    	uint256 returnBalance = _value - _price;
    	if(returnBalance > 0){
		payable(_account).transfer(returnBalance);
	}
	updateTotals(_account,_id,_price);
    }
    function MGRmint(uint256[] memory _ids,address[] memory _accounts,bool[] memory _sendits,bool[] memory _records,bool[] memory _fullOverrrides) external onlyManager(msg.sender) {
    	for(uint i=0;i<_ids.length;i++){
    		uint256 _id = _ids[i];
    		address _account = _accounts[i];
	    	uint256 num = _id - 1;
	    	bool _sendit = _sendits[i];
	    	bool _record = _records[i];
	    	TOTALS storage tot = totals[_account];
	    	bool full = tot.full;
	    	if(_fullOverrrides[i] == true){
	    		full = false;
	    	}
		if (nebuLib.addressInList(_account,NFTaccounts) == false){
	    		NFTaccounts.push(_account);
	    	}
	    	if (full == false && _sendit == true) {
		    	getMax(num);
		    	if (_id == 1){
			    nft.Pmint(_account,1,1,"0x0");
		    	}else if (_id == 2){
			    nft.Pmint(_account,2,1,"0x0");
		    	}else if (_id == 3){
			    nft.Pmint(_account,3,1,"0x0");
		    	}
		}
		if (_record == true){
		    	updateTotals(_account,_id,over.getCustomPrice(nft_cost[num]));
		}
		
	    }
    }
    function transferAllNFTdata(address prev) external onlyManager(msg.sender) {
    		prevNebulaNftMint _prev = prevNebulaNftMint(prev);
    	    	uint256 accts = _prev.NFTAccountsLength();
    	    	for(uint i=0;i<accts;i++){
    	    		address _account = _prev.NFTAccountAddress(i);
    	    		if(nebuLib.addressInList(_account,NFTtransfered) == false){
	    	    		TOTALS storage tots = totals[_account];
	    	    		(uint256 a,uint256 b,uint256 c,uint256 d,uint256 e,uint256 f,bool g)= _prev.NFTaccountData(_account);
	    	    		tots.tier_1 = a;
	    	    		tots.tier_2 = b;
	    	    		tots.tier_3 = c;
	    	    		tots.total =d;
	    	    		tots.totalUSD = e;
	    	    		tots.totalAVAX = f;
	    	    		tots.full = g;
	    			NFTtransfered.push(_account);
	    		}
	    	}
    }
    function updateTotals(address _account, uint256 _id,uint256 _amount) internal {
    	uint256[3] memory vals = [Zero,Zero,Zero];
    	if(_id != 0){
    		vals[_id-1] = _id;
    	}
    	TOTALS storage tot = totals[_account];
    	tot.tier_1 += vals[0];
    	tot.tier_2 += vals[1];
    	tot.tier_3 += vals[2];
    	if(_id != 0){
        	tot.total += 1;
        }
    	tot.totalUSD += _amount;
    	tot.totalAVAX += msg.value;
	tot.full = false;

    	if ((tot.tier_1).add(tot.tier_2).add(tot.tier_3) >= 10){
    		tot.full = true;
    	}
    }
    function changeCostNfts(uint256[3] memory _costs) external onlyOwner{
        delete nft_cost;
    	for(uint i = 0;i<_costs.length;i++){
    		nft_cost.push(_costs[i]*(10**18));
    	}
    }
    function NFTaccountExists(address _account) external returns (bool) {
    	return nebuLib.addressInList(_account,NFTaccounts);
    }
    function nftAccountData(address _account) external onlyManager(msg.sender) returns(uint256,uint256,uint256,uint256,uint256,uint256,bool){
    		TOTALS storage tot = totals[_account];
    		return (tot.tier_1,tot.tier_2,tot.tier_3,tot.total,tot.totalUSD,tot.totalAVAX,tot.full);
    	}
    function changeNFTAddress(address _address) external onlyManager(msg.sender) {
    	nftAddress = _address;
    	nft = NebulaNFT(nftAddress);
    }
    function updateManagers(address newVal) external onlyOwner {
    	if(nebuLib.addressInList(newVal,Managers) ==false){
        	Managers.push(newVal); //token swap address
        }
    }
    function updateGuard(address _address) external onlyOwner {
        Guard = _address; //token swap address
    }
   
    function nftAccountsLength() external view returns(uint256){
    	return NFTaccounts.length;
    }

    function nftAccountExists(address _account) external returns (bool) {
    	return nebuLib.addressInList(_account,NFTaccounts);
    }
}
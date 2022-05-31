// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import "../libraries/SafeERC20.sol";

error ContractLocked();
error StakingComplete();
error InsufficientAmount();
error ZeroAmount();
contract Staking {
    using SafeERC20 for IERC20;

    IERC20 private immutable HARVEST;
    address private immutable i_owner;
    bool private _locked = false;
    uint256 private _percentage = 10;
    uint256 private _stakingMin = 20 ether;

    uint256 private _invested;
    uint256 private _withdrawn;
    
    struct Deposit {
    uint256 amount;
    uint256 time;
    }

    mapping(address => Deposit) private _deposit;
    mapping(address => uint256) private _userTotalWithdrawn;
    mapping(address => uint256) private _pendingDividends;

    event Staked(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);

    constructor(address token) {
        HARVEST = IERC20(token);
        i_owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == i_owner);
        _;
    }

  function setStakingMin(uint256 min) external onlyOwner {
        _stakingMin = min;
    }

    function setLocked(bool locked) external onlyOwner {
        _locked = locked;
    }

    function setPercentage(uint256 perc) external onlyOwner {
        _percentage = perc;
    }
    
    function stake(uint256 amount) external {
        if(_locked) { revert ContractLocked();}
        if(amount < _stakingMin) { revert InsufficientAmount();}
        if((HARVEST.balanceOf(address(this)) - _invested) < 1000){ revert StakingComplete();}

        HARVEST.safeTransferFrom(msg.sender, address(this), amount);

        Deposit storage dep = _deposit[msg.sender];
        _pendingDividends[msg.sender] += this.payoutOf(msg.sender);
        dep.amount += amount;
        dep.time = block.timestamp;

        _invested += amount;
        
        emit Staked(msg.sender, amount);
    }

    function compound() external {
        if(_locked) { revert ContractLocked();}
        if((HARVEST.balanceOf(address(this)) - _invested) < 1000){ revert StakingComplete();}

        uint256 payout = this.payoutOf(msg.sender) + _pendingDividends[msg.sender];

       _userTotalWithdrawn[msg.sender] += payout;

        Deposit storage dep = _deposit[msg.sender];
        dep.amount += payout;
        dep.time = block.timestamp;

        _invested += payout;
        _withdrawn += payout;
            
        emit Staked(msg.sender, payout);
    }
    
    function unstake() external {
        Deposit storage dep = _deposit[msg.sender];

        uint256 payout = this.payoutOf(msg.sender);

        uint256 amount = payout + _pendingDividends[msg.sender];
        uint256 totalAmount = amount + dep.amount;
        if(totalAmount <= 0) { revert ZeroAmount();}

        _userTotalWithdrawn[msg.sender] +=  amount;
        _withdrawn += amount;
        _invested -= dep.amount;
        dep.amount = 0;
        _pendingDividends[msg.sender] = 0;

        if(dep.time + 86400 * 3 >= block.timestamp){
            totalAmount -= totalAmount * 5 / 100;
        }

        HARVEST.safeTransfer(msg.sender, totalAmount);
        
        emit Withdraw(msg.sender, totalAmount);
    }

    function claim() external {
        Deposit storage dep = _deposit[msg.sender];

        uint256 payout = this.payoutOf(msg.sender);

        uint256 amount = payout + _pendingDividends[msg.sender];
        if(amount <= 0) { revert ZeroAmount();}

        _userTotalWithdrawn[msg.sender] +=  amount;
        _withdrawn += amount;
        _pendingDividends[msg.sender] = 0;
        dep.time = block.timestamp;

        HARVEST.safeTransfer(msg.sender, amount);
        
        emit Withdraw(msg.sender, amount);
    }

    function payoutOf(address _addr) view external returns(uint256 value) {
        Deposit memory dep = _deposit[_addr];
        uint256 availableStakingAmount = HARVEST.balanceOf(address(this)) - _invested;
        if(dep.amount > 0 && availableStakingAmount > 0){
            uint256 from = dep.time;
            uint256 to = block.timestamp;
            if(from < to) {
                uint256 year_dividends = dep.amount * _percentage / 100;
                value = ((to - from) * year_dividends / 31536000);
                if(availableStakingAmount < value){
                    value = availableStakingAmount;
                }
            }
        }
        return value;
    }
    
    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256 total_invested, uint256 total_withdrawn) {
        Deposit memory dep = _deposit[_addr];

        uint256 payout = this.payoutOf(_addr) + _pendingDividends[_addr];

        return (
            payout,
            dep.amount,
            _userTotalWithdrawn[_addr]
        );
    }

    function contractInfo() view external returns(uint256 invested, uint256 withdrawn, uint256 percentage, uint256 stakingMin) {
        return (_invested, _withdrawn, _percentage, _stakingMin);
    }

    function emergencyTokensExtraction() external {
        require(msg.sender == i_owner);
        require(_locked);
        HARVEST.safeTransfer(i_owner, HARVEST.balanceOf(address(this)));
   }

}

//SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import "../interfaces/IERC20.sol";
import "./Address.sol";

error Failed();
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) public {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) public {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "failed");
        if (returndata.length > 0) {   
            if(!(abi.decode(returndata, (bool)))) { revert Failed();}
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

error InsufficientBalance();
error UnableToSendValue();
error CallToNonContract();
error StaticCallToNonContract();
error DelegateCallToNonContract();
library Address {
    
    function isContract(address account) public view returns (bool) {
        
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    
    function sendValue(address payable recipient, uint256 amount) public {
        if(address(this).balance < amount) { revert InsufficientBalance();}

        (bool success, ) = recipient.call{value: amount}("");
        if(!success) { revert UnableToSendValue();}
    }

    
    function functionCall(address target, bytes memory data) public returns (bytes memory) {
        return functionCall(target, data, "low-level call failed");
    }

    
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) public returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) public returns (bytes memory) {
        return functionCallWithValue(target, data, value, "low-level call with value failed");
    }

    
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) public returns (bytes memory) {
        if(address(this).balance < value){ revert InsufficientBalance();}
        if(!isContract(target)) { revert CallToNonContract();}

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    
    function functionStaticCall(address target, bytes memory data) public view returns (bytes memory) {
        return functionStaticCall(target, data, "low-level static call failed");
    }

    
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) public view returns (bytes memory) {
        if(!isContract(target)) { revert StaticCallToNonContract();}

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    
    function functionDelegateCall(address target, bytes memory data) public returns (bytes memory) {
        return functionDelegateCall(target, data, "low-level delegate call failed");
    }

    
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) public returns (bytes memory) {
        if(!isContract(target)) { revert DelegateCallToNonContract();}

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) public pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            
            if (returndata.length > 0) {
                

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;
interface IERC20 {

  function balanceOf(address who) external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );
}
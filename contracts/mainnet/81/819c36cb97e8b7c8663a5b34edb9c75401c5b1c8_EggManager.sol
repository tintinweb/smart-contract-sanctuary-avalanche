/**
 *Submitted for verification at snowtrace.io on 2022-02-18
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {

        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender)
            .sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function add32(uint32 a, uint32 b) internal pure returns (uint32) {
        uint32 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add( div( a, 2), 1 );
            while (b < c) {
                c = b;
                b = div( add( div( a, b ), b), 2 );
            }
        } else if (a != 0) {
            c = 1;
        }
    }

    function percentageAmount( uint256 total_, uint8 percentage_ ) internal pure returns ( uint256 percentAmount_ ) {
        return div( mul( total_, percentage_ ), 1000 );
    }

    function substractPercentage( uint256 total_, uint8 percentageToSub_ ) internal pure returns ( uint256 result_ ) {
        return sub( total_, div( mul( total_, percentageToSub_ ), 1000 ) );
    }

    function percentageOfTotal( uint256 part_, uint256 total_ ) internal pure returns ( uint256 percent_ ) {
        return div( mul(part_, 100) , total_ );
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }

    function quadraticPricing( uint256 payment_, uint256 multiplier_ ) internal pure returns (uint256) {
        return sqrrt( mul( multiplier_, payment_ ) );
    }

  function bondingCurve( uint256 supply_, uint256 multiplier_ ) internal pure returns (uint256) {
      return mul( multiplier_, supply_ );
  }
}

interface IERC20 {
    function decimals() external view returns (uint8);
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  function burn(uint256 amount) external; 

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {

    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _functionCallWithValue(
        address target, 
        bytes memory data, 
        uint256 weiValue, 
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success, 
        bytes memory returndata, 
        string memory errorMessage
    ) private pure returns(bytes memory) {
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

    function addressToString(address _address) internal pure returns(string memory) {
        bytes32 _bytes = bytes32(uint256(_address));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _addr = new bytes(42);

        _addr[0] = '0';
        _addr[1] = 'x';

        for(uint256 i = 0; i < 20; i++) {
            _addr[2+i*2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _addr[3+i*2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }

        return string(_addr);

    }
}

interface ITreasury {
    function mintRewards( address _recipient, uint _amount ) external;
}

interface IStaking {
    struct Epoch {
        uint number;
        uint distribute;
        uint32 length;
        uint32 endTime;
    }
    function epoch() view external returns (Epoch calldata);
}

contract EggManager {
    using SafeMath for uint;
    using SafeMath for uint32;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public immutable SetToken;
    address public treasury;
    address public immutable stakedToken;
    address public stakingContract;
    address public owner;
    uint256 public flipduration;
    uint256 public totalBurned;
    uint256 public burnOfMissedBid;
    uint256 public nextFlip;
    uint256 public flipExtendWhenBid;
    uint256 public calmDownPeriod;
    uint256 public lastFlip;
    uint public lastEpochClaimed;

    struct Egg {
        string name;
        uint256 returnvalue; // 100000 is extra reward of 100% of sCat value per rebase. So 0.25% reward will be 250 returnvalue
        uint256 minimumbid;
        address currentholder;
        uint256 amountpaid;
    }
    Egg[] public eggs;

    struct Bidding {
        address bidder;
        uint256 amount;
    }
    Bidding[] public bidding;

    struct HistoryItem {
        uint when;
        address receiver;
        uint256 amount;
    }
    HistoryItem[] public history;

    constructor ( address _token, uint256 _flipDuration, uint256 _firstFlipTime, address _stakingContract, address _treasury, address _stakedToken, uint _previousburned ) {
        require( _token != address(0) );
        SetToken = _token;
        flipduration = _flipDuration;
        owner = msg.sender;
        totalBurned = _previousburned;
        burnOfMissedBid = 150;
        nextFlip = _firstFlipTime;
        stakingContract = _stakingContract;
        treasury = _treasury;
        stakedToken = _stakedToken;
        lastEpochClaimed = getCurrentEpoch();
        flipExtendWhenBid = 180;
        calmDownPeriod = 600;
        lastFlip=0;
    }

    function getCurrentEpoch() internal view returns ( uint ) {
        IStaking.Epoch memory _epoch = IStaking(stakingContract).epoch();
        return _epoch.number;
    }

    function resetBids() internal {
        delete bidding;
        for ( uint i = 0; i < eggs.length; i++ ) {
            bidding.push( Bidding({
                bidder: address(0),
                amount: 0
            }));
        }
    }

    function checkIfFlipNeeded() public view returns ( bool ) {
        if (block.timestamp > nextFlip ) { return true; } else { return false; }
    }

    function getHistoryLength() public view returns ( uint ) {
        return history.length;
    }

    function doFlip() public returns ( bool ) {
       if (checkIfFlipNeeded()) {
           lastEpochClaimed = getCurrentEpoch();
           for ( uint i = 0; i < eggs.length; i++ ) {
               if (bidding[ i ].bidder != address(0) && bidding[ i ].amount > 0) {
                   eggs[ i ].currentholder = bidding[ i ].bidder;
                   eggs[ i ].amountpaid = bidding[ i ].amount;
                   totalBurned = totalBurned + bidding[ i ].amount;
                   IERC20( SetToken ).burn( bidding[ i ].amount );
               } else {
                   eggs[ i ].currentholder = address(0);
                   eggs[ i ].amountpaid = 0;
               }
           }
           resetBids();
           nextFlip = nextFlip + flipduration;
           lastFlip = block.timestamp;
           return true;
       } else {
           return false;
       }
    }

    /* ====== EDIT FUNCTIONS ====== */

    function addEgg( string memory _name, uint256 _returnvalue, uint256 _minimumbid ) external {
       require ( msg.sender == owner, "You are not allowed" );
       eggs.push( Egg({
           name: _name,
           returnvalue: _returnvalue,
           minimumbid: _minimumbid,
           currentholder: address(0),
           amountpaid: 0
       }));
       resetBids();
    }
    function editEggName( uint _index, string memory _name ) external {
       require ( msg.sender == owner, "You are not allowed" );
       eggs[ _index ].name = _name;
    }
    function editEggReturnValue( uint _index, uint256 _returnvalue ) external {
       require ( msg.sender == owner, "You are not allowed" );
       eggs[ _index ].returnvalue = _returnvalue;
    }
    function editEggMinimumBud( uint _index, uint256 _minimumbid ) external {
       require ( msg.sender == owner, "You are not allowed" );
       eggs[ _index ].minimumbid = _minimumbid;
    }
    function editBurnPercentage( uint256 _burnPercentage ) external {
        require ( msg.sender == owner, "You are not allowed" );
        burnOfMissedBid = _burnPercentage; // 100 = 1%
    }
    function setNextFlip( uint256 _nextflip ) external {
        require ( msg.sender == owner, "You are not allowed" );
        nextFlip = _nextflip;
    }
    function setFlipExtendWhenBid( uint256 _newExtend ) external {
        require ( msg.sender == owner, "You are not allowed" );
        flipExtendWhenBid = _newExtend;
    }
    function setCalmDownPeriod( uint256 _newCalmdown ) external {
        require ( msg.sender == owner, "You are not allowed" );
        calmDownPeriod = _newCalmdown;
    }
    function setTreasury( address _newTreasury ) external {
        require ( msg.sender == owner, "You are not allowed" );
        treasury = _newTreasury;
    }
    function setStaking( address _newStaking ) external {
        require ( msg.sender == owner, "You are not allowed" );
        stakingContract = _newStaking;
    }
    function setFlipDuration( uint256 _newFlipDuration ) external {
        require ( msg.sender == owner, "You are not allowed" );
        flipduration = _newFlipDuration;
    }
    function emergencyWithdrawBid ( uint _eggIndex ) external returns ( bool ) {
        require ( msg.sender == owner, "You are not allowed" );
        IERC20( SetToken ).transfer( bidding[ _eggIndex ].bidder, bidding[ _eggIndex ].amount );
        bidding[ _eggIndex ].bidder = address(0);
        bidding[ _eggIndex ].amount = 0;
        return true;
    }
    function transferOwnership ( address _newOwner ) external {
        require ( msg.sender == owner, "You are not allowed" );
        owner = _newOwner;
    }

    /* ====== USER FUNCTIONS ====== */

    function placeBid( uint _eggIndex, uint256 _bid ) external returns ( bool ) {
       require( _bid > bidding[ _eggIndex ].amount, "Bid too low");
       require( _bid > eggs[ _eggIndex ].minimumbid, "Bid too low");
       require( block.timestamp > (lastFlip + calmDownPeriod), "Calm down, Flip just happened");
       require( eggs[ _eggIndex ].currentholder != msg.sender, "You have this egg and not allowed to place bids");
       if (secondsToFlip() > 0 && secondsToFlip() < flipExtendWhenBid) {
           nextFlip = nextFlip + flipExtendWhenBid;
       }
       bool flipped = doFlip();
       if (!flipped) {
           if ( bidding[ _eggIndex ].bidder != address(0)) {
               uint256 fee = bidding[ _eggIndex ].amount.mul(burnOfMissedBid).div(10000);
               IERC20( SetToken ).transfer( bidding[ _eggIndex ].bidder, bidding[ _eggIndex ].amount.sub(fee) );
               totalBurned = totalBurned + fee;
               IERC20( SetToken ).burn( fee );
           }
           IERC20( SetToken ).transferFrom( msg.sender, address(this), _bid );
           bidding[ _eggIndex ].bidder = msg.sender;
           bidding[ _eggIndex ].amount = _bid;
           return true;
       } else {
           return true;
       }
    }

    function claimRewards() external {
        uint256 _amount = 0;
        for ( uint i = 0; i < eggs.length; i++ ) {
            if (eggs[ i ].currentholder != address(0)) {
                _amount = getReward( eggs[ i ].currentholder );
                history.push( HistoryItem({
                    when: block.timestamp,
                    receiver: eggs[ i ].currentholder,
                    amount: _amount
                }));
                ITreasury( treasury ).mintRewards( eggs[ i ].currentholder, _amount );
            }
        }
        if (lastEpochClaimed != getCurrentEpoch()) {
            lastEpochClaimed = getCurrentEpoch();
        }
        doFlip();
    }

    /* ====== VIEW FUNCTIONS ====== */

    function highestBidder( uint _eggIndex ) public view returns ( address ) {
        return bidding[ _eggIndex ].bidder;
    }
    function highestBid( uint _eggIndex ) public view returns ( uint256 ) {
        return bidding[ _eggIndex ].amount;
    }
    function iAmtheBestBidder( uint _eggIndex ) public view returns ( bool ) {
        if (bidding[ _eggIndex ].bidder == msg.sender) {
            return true;
        } else {
            return false;
        }
    }
    function getReward( address _adr ) public view returns ( uint256 ) {
         uint256 reward = 0;
         for ( uint i = 0; i < eggs.length; i++ ) {
             if (eggs[ i ].currentholder == _adr) {
                 uint256 _staked = IERC20( stakedToken ).balanceOf(_adr);
                 reward = reward + ( _staked.mul(eggs[ i ].returnvalue).div(100000).mul(epochsToClaim()));
             }
         }
         return reward;
    }
    function getRewardPersonal() public view returns ( uint256 ) {
        return getReward( msg.sender );
    }

    function epochsToClaim() public view returns ( uint ) {
        return getCurrentEpoch().sub(lastEpochClaimed);
    }

    function secondsToFlip() public view returns ( uint256 ) {
        if (block.timestamp >= nextFlip) {
            return 0;
        } else {
            return nextFlip.sub(block.timestamp);
        }
    }

    function timeToStartBidding() public view returns ( uint256 ) {
        uint256 starttime = lastFlip + calmDownPeriod;
        if (block.timestamp >= starttime ) {
            return 0;
        } else {
            return starttime.sub(block.timestamp);
        }
    }
}
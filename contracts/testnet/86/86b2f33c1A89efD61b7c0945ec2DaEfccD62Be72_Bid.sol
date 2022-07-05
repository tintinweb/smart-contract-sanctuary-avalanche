/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-04
*/

// SPDX-License-Identifier:MIT
pragma solidity ^0.8.15;

 interface IERC20 {
    function balanceOf(address account) external view returns(uint256);
    function transferFrom( address tokenOwner, address recipient, uint256 tokenAmount) external returns(bool);
}
// transaction cost	1082587 gas
contract Bid {   

    IERC20 public token1;
    address public owner;
    uint256 public bidStartTime ;
    uint256 public minBid = 100000000000000000 ;   // 0.1 ether
    uint256 private tokenAmount = 5  ;
    uint256 public maxBidAmount = 0;
    address public maxBider;
    uint256 public time = 300 seconds;
    bool public bidAmountPaid;
    bool public bid_Status;

    constructor(IERC20 _token) {
       token1 = _token;
       owner = msg.sender;
    }

    struct BidData {
        uint256 amount;
        uint256 time;
        uint256 token;
    }

    mapping(address => uint256) private balanceIS;
    mapping(address => BidData) public info; 

    modifier onlyOwner {
        require(msg.sender == owner,"Caller isn't Owner");
        _;
    }

    function startBid(bool _status) external onlyOwner { 
        bid_Status = _status;
        bidStartTime = block.timestamp;
    }

    function bid() public payable {   
        
      require(bid_Status == true, "Biding not active");
      require(msg.value >= minBid, "Invalid amount enter");
      require(msg.value > maxBidAmount, "low amount not accepted");
      require(block.timestamp < bidStartTime + time, "Time Out");

      info[msg.sender].amount = msg.value;
      info[msg.sender].time = block.timestamp;
     
     if (msg.value >= maxBidAmount) {

        maxBidAmount = msg.value;
        maxBider = msg.sender;

      }
    }
 
    function checkStatus() public view returns(bool) {
        if(block.timestamp < bidStartTime + time) {
          return true;
     } else {
         return false;
        }
    }

    function tokenTransfer() external onlyOwner {   
        require(!bidAmountPaid, "you have already paid");
        require(checkStatus() != true , "Bid not close yet");
    
        token1.transferFrom(tx.origin, maxBider,  tokenAmount);
        balanceIS[maxBider] += tokenAmount;
        info[maxBider].token += tokenAmount;
        bidAmountPaid = true;
    }

    function ContractBalance() external view returns(uint256) {
        return address(this).balance; // check contract balance
    }

    function balanceOfAddress(address _user) external view returns(uint256) {
        return balanceIS[_user] ;  // check addresses balances
    }
}
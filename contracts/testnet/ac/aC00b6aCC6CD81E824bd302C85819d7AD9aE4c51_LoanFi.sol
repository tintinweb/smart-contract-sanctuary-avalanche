//SPDX-License-Identifier:MIT
pragma solidity >=0.4.0 <0.9.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract LoanFi {
    address payable private lender;
    IERC20 immutable private token;
    constructor(IERC20 _token,address payable _lender) {
        token=_token;
        lender=_lender;
    }

    struct Loan {
        uint256 loanid;
        address lender;
        address borrower;
        uint256 collateralamount;
        uint256 loanamount;
        uint256 payoffamount;
        uint256 loanduration;
        uint256 duedate;
        STATUS status;
    }
    mapping(address=>Loan) public loandetails;
    mapping(uint256=>address) public requestdetails;
    uint256 private loans;
    uint256 private loanrequests;
    uint256 internal loanid=1001;
    enum STATUS{REQUESTED,ACCEPTED}

            event LoanRequested(address indexed borrower,uint256 loanamount); 
            event LoanAccepted(address indexed lender,address indexed borrower,uint256 loanamount,uint256 duedate);     
            event LoanPaid(address indexed payer,uint256 time);
            event Possessed(address indexed lender,uint256 time,uint256 amount);
    
    modifier Onlylender(){
        require(msg.sender==lender,"Not an Authorized User");
        _;
    }
    modifier CheckLoan(){
        require(loandetails[msg.sender].status!=STATUS.ACCEPTED,"Loan already exists");
        _;
    }        
    function RequestLoan(IERC20 _token,uint256 _collateralamount,uint256 _loanamount,uint256 _payoffamount,uint256 _loanduration) public CheckLoan {
          _loanduration=_loanduration*1 days;
          require(token==IERC20(_token),"Invalid collateral token address");
          require(token.balanceOf(msg.sender)>=_collateralamount,"Insufficient Funds in your wallet");
          require(_loanduration<90 days,"loan duration must be less than 90 days");
          require(token.approve(lender,_collateralamount));
          _loanamount*=1 ether;
          _payoffamount*=1 ether; 
          loandetails[msg.sender]=Loan(0,address(0),msg.sender,_collateralamount,_loanamount,_payoffamount,_loanduration,0,STATUS.REQUESTED);
          requestdetails[loanrequests]=msg.sender;
          loanrequests++;
          emit LoanRequested(msg.sender,_loanamount);
    }
    function LoanStatus(address _borrower) public view returns(Loan memory) {
          return loandetails[_borrower];
    }  
    function lendEther(address _borrower) payable public Onlylender {
         require(msg.value==loandetails[_borrower].loanamount,"Enter Valid amount");
         uint256 _id = find(_borrower);
         loandetails[_borrower].loanid=loanid;
         loandetails[_borrower].lender=msg.sender;
         loandetails[_borrower].status=STATUS.ACCEPTED;
         loandetails[_borrower].duedate=block.timestamp+loandetails[_borrower].loanduration;
         loanid++;
         require(token.transferFrom(_borrower,lender,loandetails[_borrower].collateralamount));
         require(token.approve(_borrower,loandetails[_borrower].collateralamount));
         payable(_borrower).transfer(loandetails[_borrower].loanamount);
         delete requestdetails[_id];
         loanrequests--;
         emit LoanAccepted(msg.sender,_borrower,loandetails[_borrower].loanamount,loandetails[_borrower].duedate);
    }
     function payLoan() public payable {
        require(block.timestamp <= loandetails[msg.sender].loanduration);
        require(msg.value == loandetails[msg.sender].payoffamount);
        lender.transfer(loandetails[msg.sender].payoffamount);
        require(token.transferFrom(lender,msg.sender,loandetails[msg.sender].collateralamount));
        emit LoanPaid(msg.sender,block.timestamp);
    }

     function repossess(address _borrower) public Onlylender {
        require(block.timestamp > loandetails[_borrower].loanduration);
        require(token.transfer(lender,loandetails[_borrower].collateralamount));
        emit Possessed(msg.sender,block.timestamp,loandetails[_borrower].collateralamount);
    }
    function find(address _addr) internal view returns(uint256 i) {
       for(i=0;i<loanrequests;i++){
         if(requestdetails[i]==_addr){
             return i;
         }
       }
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}
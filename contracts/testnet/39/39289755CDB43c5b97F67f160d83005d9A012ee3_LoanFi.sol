//SPDX-License-Identifier:MIT
pragma solidity >=0.4.0 <0.9.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
contract LoanFi is ReentrancyGuard {
    address payable private lender;
    
    constructor(address payable _lender) {
        lender=_lender;
    }
    
    struct Token {
        IERC20 token;
        bool   listed;
    }

    struct Loan {
        uint256 loanid;
        address lender;
        address borrower;
        IERC20  collateraltoken;
        uint256 collateralamount;
        uint256 loanamount;
        uint256 payoffamount;
        uint256 loanduration;
        uint256 duedate;
        STATUS status;
    }

    mapping(IERC20=>Token) private tokenlist;
    mapping(address=>Loan) private loandetails;
    mapping(address=>uint256) private requestdetails;
    uint256 private loans;
    uint256 private loanrequests;
    uint256 private loanid=1000;
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
    function AddWhitelistToken(IERC20 _token) public Onlylender {
        tokenlist[_token].listed=true;
    }
    function RemoveWhitelistToken(IERC20 _token) public Onlylender {
        tokenlist[_token].listed=false;
    }
    function RequestLoan(IERC20 _token,uint256 _collateralamount,uint256 _loanamount,
                         uint256 _payoffamount,uint256 _loanduration) public CheckLoan nonReentrant{
    
          _loanduration=_loanduration*1 days;
          require(tokenlist[_token].listed,"Invalid collateral token address");
          require(tokenlist[_token].token.balanceOf(msg.sender)>=_collateralamount,"Insufficient Funds in your wallet");
          require(_loanduration<90 days,"loan duration must be less than 90 days");
          require(tokenlist[_token].token.approve(lender,_collateralamount));
          _loanamount*=1 ether;
          _payoffamount*=1 ether; 
          loandetails[msg.sender] = Loan(0,address(0),msg.sender,tokenlist[_token].token,
                                        _collateralamount,_loanamount,
                                         _payoffamount,_loanduration,0,STATUS.REQUESTED);
          requestdetails[msg.sender]=loanrequests++;
          emit LoanRequested(msg.sender,_loanamount);
    }
    function LoanStatus(address _borrower) public view returns(Loan memory) {
          return loandetails[_borrower];
    }  
    function lendEther(address _borrower) payable public Onlylender nonReentrant{
         require(_borrower!=address(0),"Entered Zero address");
         require(msg.value==loandetails[_borrower].loanamount,"Enter Valid amount");
         require(requestdetails[msg.sender]>0,"Not a Valid Borrower address");
         loandetails[_borrower].loanid=loanid++;
         loandetails[_borrower].lender=msg.sender;
         loandetails[_borrower].status=STATUS.ACCEPTED;
         loandetails[_borrower].duedate=block.timestamp+loandetails[_borrower].loanduration;
         require(loandetails[_borrower].collateraltoken.transferFrom(_borrower,lender,loandetails[_borrower].collateralamount));
         require(loandetails[_borrower].collateraltoken.approve(_borrower,loandetails[_borrower].collateralamount));
         payable(_borrower).transfer(loandetails[_borrower].loanamount);
         delete requestdetails[_borrower];
         loanrequests--;
         emit LoanAccepted(msg.sender,_borrower,loandetails[_borrower].loanamount,loandetails[_borrower].duedate);
    }
     function payLoan() public payable nonReentrant {
        require(block.timestamp <= loandetails[msg.sender].loanduration);
        require(msg.value == loandetails[msg.sender].payoffamount);
        lender.transfer(loandetails[msg.sender].payoffamount);
        require(loandetails[msg.sender].collateraltoken.transferFrom(lender,msg.sender,loandetails[msg.sender].collateralamount));
        emit LoanPaid(msg.sender,block.timestamp);
    }

     function repossess(address _borrower) public Onlylender nonReentrant {
        require(_borrower!=address(0),"Entered Zero address");
        require(block.timestamp > loandetails[_borrower].loanduration);
        require(loandetails[_borrower].collateraltoken.transfer(lender,loandetails[_borrower].collateralamount));
        emit Possessed(msg.sender,block.timestamp,loandetails[_borrower].collateralamount);
    }
        
    function Renouncelender(address _newlender) public Onlylender {
        require(_newlender!=address(0),"Entered Zero address");
        lender=payable(_newlender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
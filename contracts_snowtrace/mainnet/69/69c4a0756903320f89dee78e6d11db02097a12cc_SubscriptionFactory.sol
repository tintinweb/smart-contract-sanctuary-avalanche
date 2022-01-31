/**
 *Submitted for verification at snowtrace.io on 2022-01-31
*/

// File: contracts/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// File: contracts/Subscription.sol



pragma solidity ^0.8.0;


interface IMuPriceOracle{
    function get_cost_In_MUG_USD(uint256 cost) external returns(uint256);//returns the cost of something priced in USD in terms of MUG IE $300 is how many MUG
    function get_MUG_USD_price() external returns(uint256);//returns the price of MU in USD
    function get_MU_USD_price() external returns(uint256);//returns the price of MU in USD
    function get_MUG_MU_price() external returns(uint256);//return the price of MUG in MU
    function get_last_price_update_time() external returns(uint256);//gets the block timestamp with time was updated last
}//end IMuPriceOracle interface

interface ISubscription{
    //function to check if subscription is active or not
    function isActive() external returns(bool);
    function makePayment() external returns(uint256);
}//ends ISubscription interface

contract Subscription is ISubscription{

    bool public _active ;
    bool public _customerCancelled;//tells if customer canceled or not
    bool public _paymentCancelled;//tells if it was canceled due to payment issues
    
    string public _offer;//details about the offer
    address public _paymentCurrency;//the token used to make the payment
    uint256 public _subscriptionAmount;//the amount of the subscription
    uint256 public _subscriptionIntevral;//the amount of time in seconds between payments
    uint256 public _MUG_owed;//the amount of MUG that is owed for the current payment

    uint256 public _next_payment_time;
    uint256 public _last_payment_time;
    uint256 public _cancelled_at;

    address private payee;//who gets paid - this will typcially be another payment splitting smart contract
    address private payor;//who pays - this is the subscriber
    string public payor_name;
    string public payor_email;

    IMuPriceOracle MuPrice;//price oracle to get the current prices of MU and MUG in USD
    IERC20 _payment;//Token interface for transfering making payment in desired token currency
    
    event Subscription_Started(
        address payor,
        address payee,
        uint256 amount,
        uint256 interval,
        uint256 started_at,
        uint256 MU_USD_Price,
        uint256 MUG_MU_Price,
        uint256 MUG_USD_Price,
        uint256 MUG_Paid,
        uint256 MUG_price_updated_at
    );
    event Subscription_Payment_Made(
        uint256 paid_at,
        uint256 MU_USD_Price,
        uint256 MUG_MU_Price,
        uint256 MUG_USD_Price,
        uint256 MUG_Paid,
        uint256 MUG_price_updated_at
    );
    event Subscription_Cancelled_By_Customer(
        uint256 cancelled_at
    );

    constructor(string memory offer , address thepayor, address thepayee, uint256 interval, uint256 amount, string memory name, string memory email){
        MuPrice = IMuPriceOracle(0x5b9438372a6641Efbd9f285ab6931E190Ed841eB);//Mu Price Oracle Contract
        _paymentCurrency = 0xF7ed17f0Fb2B7C9D3DDBc9F0679b2e1098993e81;//Mu Gold $MUG address
        _payment = IERC20(_paymentCurrency);
        _offer = offer;
        _next_payment_time = 0;
        _last_payment_time = 0;
        _cancelled_at = 0;
        payor = thepayor;
        payee = thepayee;
        _subscriptionIntevral = interval;
        _subscriptionAmount = amount;
        payor_name = name;
        payor_email = email;
        _active = false;
    }//ends constructor

    function isActive() public view virtual override returns(bool){
        return _active;
    }//ends isActive()

    function cancel() public virtual{
        require(msg.sender == payor, "only payor can cancel");
        _active = false;
        _customerCancelled = true;
        _paymentCancelled = false;
        _cancelled_at = block.timestamp;
        emit Subscription_Cancelled_By_Customer(block.timestamp);
    }//ends cancel()

    function makePayment() public virtual override returns(uint256){
        if(_active){
            //set everything incase payment fails
            _active = false;
            _paymentCancelled = true;
            _customerCancelled = false;
            _cancelled_at = block.timestamp;
                 if(block.timestamp >= _next_payment_time){
                    _MUG_owed = MuPrice.get_cost_In_MUG_USD(_subscriptionAmount);
                         if(_payment.balanceOf(payor) >= _MUG_owed && _payment.allowance(payor, address(this)) >= _MUG_owed){
                            _payment.transferFrom(payor, payee, _MUG_owed);
                            _last_payment_time = block.timestamp;
                            _next_payment_time += _subscriptionIntevral;
                            _active = true;
                            _paymentCancelled = false;
                            _customerCancelled = false;
                            _cancelled_at = 0;
                            emit Subscription_Payment_Made(block.timestamp, MuPrice.get_MU_USD_price(), MuPrice.get_MUG_MU_price(), MuPrice.get_MUG_USD_price(), _MUG_owed, MuPrice.get_last_price_update_time());
                            return _MUG_owed;
                        }//ends if payment goes through
                        else{
                            return 0;
                        }          
                }//ends if payment is due
                else{
                    return 0;
                }  
        }//ends if active  
        else{
            return 0;
        }              
    }//ends makePayment()

    function startSubscription() public virtual{
        _MUG_owed = MuPrice.get_cost_In_MUG_USD(_subscriptionAmount);
        require(msg.sender == payor, "Only payor can start subscription");
        require(_payment.balanceOf(payor) >= _MUG_owed, "You don't have enough $MUG to start this subscription");
        require(_payment.allowance(payor, address(this)) >= _MUG_owed, "You haven't approved this contract to use your $MUG");          
        _payment.transferFrom(payor, payee, _MUG_owed);
        _last_payment_time = block.timestamp;
        _next_payment_time = block.timestamp + _subscriptionIntevral;
        _active = true;
        _paymentCancelled = false;
        _customerCancelled = false;
        _cancelled_at = 0;
        emit Subscription_Started(payor, payee, _subscriptionAmount, _subscriptionIntevral, block.timestamp, MuPrice.get_MU_USD_price(), MuPrice.get_MUG_MU_price(), MuPrice.get_MUG_USD_price(), _MUG_owed, MuPrice.get_last_price_update_time());
    }
}//ends Subscripption contract



// File: contracts/SubscriptionFactory.sol



pragma solidity ^0.8.0;



contract SubscriptionFactory{
    //this contract will be used to create subscriptions for customers
    address [] private subscriptions;
    ISubscription subscription;
    address public _owner;
    address public _last_subscription_created;
    uint256 private _MUG_collected;
    uint256 private _successful_payments;

    event Collected_Payments(
        uint256 collect_at,
        uint256 MUG_collected,
        uint256 _successful_payments
    );
    event Subscription_Created(
        address subscription_address,
        uint256 subscription_created_at,
        string offer,
        uint256 subscription_amount,
        uint256 subscription_intevral,
        address subscription_for_address,
        string subscription_for_customer,
        address subscription_paid_to
    );

    constructor(){
        _owner = msg.sender;
    }

    function getPayments() public virtual{
        _MUG_collected = 0;
        _successful_payments = 0;
        for(uint256 i = 0; i < subscriptions.length; i++){
            subscription = ISubscription(subscriptions[i]);
            if(subscription.isActive()){
                _MUG_collected += subscription.makePayment();
                if(_MUG_collected > 0){
                    _successful_payments += 1;
                }
            }//ends if is active
        }//ends for loop
        emit Collected_Payments(block.timestamp, _MUG_collected, _successful_payments);
    }//ends getPayments()

    function createSubscription(string memory offer , address thepayor, address thepayee, uint256 interval, uint256 amount, string memory name, string memory email) public virtual{
    //string memory offer , address thepayor, address thepayee, uint256 interval, uint256 amount, string memory name, string memory email
        require(msg.sender == _owner, "You're not the owner");
        Subscription s = new Subscription(offer, thepayor, thepayee, interval, amount, name, email);
        subscriptions.push(address(s));
        _last_subscription_created = address(s);
        emit Subscription_Created(address(s), block.timestamp, offer, amount, interval, thepayor, name, thepayee);
    }//ends createSubscription

    function getSubscriptions() public view virtual returns(address[] memory){
            return subscriptions;
    }
    

}//ends SubscriptionFactory contract
/**
 *Submitted for verification at snowtrace.io on 2022-06-16
*/

/**
 *Submitted for verification at testnet.snowtrace.io on 2022-06-04
*/

// File: IERC20.sol

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}
// File: BeetradeOrderbook.sol

pragma solidity >=0.5.0;


contract BeeTradeOrderbook {

    address public admin; // the admin address
    uint256 public fee; //percentage times (1 ether)
    address public feesAccount; //the account that will receive fees
    address public tradesAccount; // the address that can execute trades
    address AVAX = address(0); // using the zero address to represent avax token

    struct Balance {
        uint256 available;
        uint256 locked;
    }

    struct Order {
        uint256 amount;
        uint256 amountLeft;
        string buySell; 
        string date;
        string orderType; 
        string pair;
        address token;
        uint256 price; 
        string orderID;
        bool status;
    }

    mapping (address => mapping (address => Balance)) public tokensBalances; // mapping of token addresses to mapping of account balances (token=0 means Ether)
    mapping (address => mapping(string => Order)) public usersOrders; // mapping of users addresses to ordersID to order

    event Deposit(address token, address user, uint256 amount);
    event Withdraw(address token, address user, uint256 amount);
    event CreateOrder(
        address account, 
        uint256 amount, 
        string buySell, 
        string date, 
        string orderType, 
        string pair, 
        uint256 price, 
        string orderID
    );
    event CancelOrder(address user, string pair, string buySell, string orderID);
    
    event Trade(
        address maker,
        address taker,
        uint256 amountGet, 
        uint256 amountGive,
        string makeOrderID,
        string takeOrderID,
        string pair,
        uint256 price
    );

    constructor(uint256 _fee){
        admin = msg.sender;
        fee = _fee; 
        feesAccount = msg.sender; 
        tradesAccount = msg.sender;

    }

    function setAdmin(address _newAdmin) external {
        require(msg.sender == admin, "BeetradeOrderbook: Caller Must be Admin");
        admin = _newAdmin;
    }

    function setFees(uint256 _newFee) external {
        require(msg.sender == admin, "BeetradeOrderbook: Caller Must be Admin");
        fee = _newFee;
    }

    function setFeesAccount(address _feesAccount) external {
        require(msg.sender == admin, "BeetradeOrderbook: Caller Must be Admin");
        feesAccount = _feesAccount;
    }

    function setTradesAccount(address _tradesAccount) external {
        require(msg.sender == admin, "BeetradeOrderbook: Caller Must be Admin");
        tradesAccount= _tradesAccount;
    }

    function depositAVAX(uint256 _amount) external payable {
        require(msg.value == _amount, "Beetrade: Please Deposit Right Amount");
        tokensBalances[AVAX][msg.sender].available += msg.value;
        emit Deposit(AVAX, msg.sender, _amount);
    }

    function depositToken(address _token, uint256 _amount) external {
        // make sure user has called approve() function first
        require(IERC20(_token).transferFrom(msg.sender, address(this), _amount), "Beetrade: Transfer Failed");
        tokensBalances[_token][msg.sender].available += _amount;
        emit Deposit(_token, msg.sender, _amount);
    }

    function withdrawAVAX(uint256 _amount) external {
        require(tokensBalances[AVAX][msg.sender].available >= _amount, "Beetrade: Insufficient Balance");
        tokensBalances[AVAX][msg.sender].available -= _amount;
        payable(msg.sender).transfer(_amount);
        emit Withdraw(AVAX, msg.sender, _amount);

    }

    function withdrawToken(address _token, uint256 _amount) external {
        require(tokensBalances[_token][msg.sender].available >= _amount, "Beetrade: Insufficient Balance");
        tokensBalances[_token][msg.sender].available -= _amount;
        IERC20(_token).transfer(msg.sender, _amount);
        emit Withdraw(_token, msg.sender, _amount);
    }

    function getAvailableAVAXBalance() external view returns(uint256) {
        return tokensBalances[AVAX][msg.sender].available;
    }

    function getLockedAVAXBalance() external view returns(uint256) {
        return tokensBalances[AVAX][msg.sender].locked;
    }

    function getAvailableTokenBalance(address _token) external view returns(uint256) {
        return tokensBalances[_token][msg.sender].available;
    }

    function getLockedTokenBalance(address _token) external view returns(uint256) {
        return tokensBalances[_token][msg.sender].locked;
    }

    function calculateFee(uint256 _amount) internal view returns(uint256) {
        return ((_amount * fee) / (100 * 1e18));
    }

    function createOrder(
        uint256 _amount, 
        string memory _buySell, 
        string memory _date, 
        string memory _orderType, 
        string memory _pair, 
        uint256 _price, 
        string memory _orderID, 
        address _token
    ) external returns(bool){
        // make sure user has the required token balance
        require(tokensBalances[_token][msg.sender].available >= _amount, "Beetrade Insufficient Balance");
        // move from available to locked balance
        tokensBalances[_token][msg.sender].available -= _amount;
        tokensBalances[_token][msg.sender].locked += _amount;

        // store the order in the usersOrders
        Order memory newOrder  = Order(_amount, _amount, _buySell,  _date, _orderType,  _pair, _token, _price,  _orderID, true);
        usersOrders[msg.sender][_orderID] = newOrder;


        emit CreateOrder(msg.sender, _amount, _buySell, _date, _orderType, _pair, _price, _orderID);
        return true;
    }

    function cancelOrder(string memory _pair, string memory _buySell, string memory _orderID, address _token) external returns(bool){
        uint256 amountLeft = usersOrders[msg.sender][_orderID].amountLeft;
        // make sure order is still valid
        require(usersOrders[msg.sender][_orderID].status == true, "Beetrade Order Not Valid");
        // make sure order token matches with the current token passed
        require(usersOrders[msg.sender][_orderID].token == _token, "Beetrade Order Not Valid");
        // make sure the user has the required order balance
        require(tokensBalances[_token][msg.sender].locked >= amountLeft, "Beetrade Insufficient Balance");
        
        // move from locked balance to available
        tokensBalances[_token][msg.sender].locked -= amountLeft;
        tokensBalances[_token][msg.sender].available += amountLeft;


        usersOrders[msg.sender][_orderID].status = false;
        usersOrders[msg.sender][_orderID].amountLeft = 0;

        emit CancelOrder(msg.sender, _pair, _buySell, _orderID);
        return true;
    }

    function singleTrade (
        address maker, 
        address taker, 
        address tokenGet, 
        address tokenGive, 
        uint256 amountGet, 
        uint256 amountGive,
        string memory makeOrderID,
        string memory takeOrderID,
        string memory pair,
        uint256 price
    ) external {
        require(msg.sender == tradesAccount, "Beetrade: Only Trades Account can Execute Trades");
        require(tokensBalances[tokenGet][taker].locked >= amountGet, "Beetrade: Insufficient Balances For Trade"); // Make sure taker has enough balance to cover the trade
        require(tokensBalances[tokenGive][maker].locked >= amountGive, "Beetrade: Insufficient Balances For Trade"); // Make sure maker has enough balance to cover the trade

        uint256 makerFee = calculateFee(amountGet);
        uint256 takerFee = calculateFee(amountGive);


        // subtract from takers balance and add to makers balance for tokenGet
        tokensBalances[tokenGet][taker].locked -= amountGet;
        tokensBalances[tokenGet][maker].available += (amountGet - makerFee);
        tokensBalances[tokenGet][feesAccount].available += makerFee; //charge trade fees
        // update takers order
        usersOrders[taker][takeOrderID].amountLeft -= amountGet;

        // subtract from the makers balance and add to takers balance for tokenGive
        tokensBalances[tokenGive][maker].locked -=  amountGive;
        tokensBalances[tokenGive][taker].available += (amountGive - takerFee);
        tokensBalances[tokenGive][feesAccount].available += takerFee; // charge trade fees
        // update makers order
        usersOrders[maker][makeOrderID].amountLeft -= amountGive;

        emit Trade(maker, taker, amountGet, amountGive, makeOrderID, takeOrderID, pair, price);
    }

    function swap(uint256 amount, address tokenGive, address tokenGet, address account, uint256 price ) external returns(bool) {
        require(msg.sender == tradesAccount, "Only Trades Account Can initiate Trade");
        // calculate amount user is going to get
        uint256 amountGet = amount * price;
        // make sure user has enough balance for token to give
        require(tokensBalances[tokenGive][account].available >= amount, "Insufficient Balance for Trade");
        // make sure tradesaccount has enough balance for token user will get
        require(tokensBalances[tokenGet][tradesAccount].available >= amountGet, "Insufficient Liquidity for Trade");

        // perform the swap

        // subtract balances
        tokensBalances[tokenGive][account].available -= amount;
        tokensBalances[tokenGet][tradesAccount].available -= amountGet;

        // add balances
        tokensBalances[tokenGet][account].available += amountGet;
        tokensBalances[tokenGive][tradesAccount].available += amount;

        return true;
    }

    

}
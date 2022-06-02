/**
 *Submitted for verification at testnet.snowtrace.io on 2022-06-01
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

    mapping (address => mapping (address => Balance)) public tokensBalances; // mapping of token addresses to mapping of account balances (token=0 means Ether)
    mapping (address => mapping(string => bool)) public usersOrders; // mapping of users addresses to ordersID's

    event Deposit(address indexed token, address indexed user, uint256 amount);
    event Withdraw(address indexed token, address indexed user, uint256 amount);
    event CreateOrder(string indexed orderID);
    event CancelOrder(string indexed orderID);
    
    event Trade(
        address indexed maker,
        address indexed taker,
        uint256 amountGet, 
        uint256 amountGive,
        string makeOrderID,
        string takeOrderID,
        string indexed pair,
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

    function createOrder(string memory orderID, uint256 _amount, address _token) external returns(bool){
        // make sure user has the required token balance
        require(tokensBalances[_token][msg.sender].available >= _amount, "Beetrade Insufficient Balance");
        // move from available to locked balance
        tokensBalances[_token][msg.sender].available -= _amount;
        tokensBalances[_token][msg.sender].locked += _amount;
        usersOrders[msg.sender][orderID] = true;

        emit CreateOrder(orderID);
        return true;
    }

    function cancelOrder(string memory orderID, uint256 _amount, address _token) external returns(bool){
        // make sure the user has the required order balance
        require(tokensBalances[_token][msg.sender].locked >= _amount, "Beetrade Insufficient Balance");
        // make sure order is still valid
        require(usersOrders[msg.sender][orderID] == true, "Beetrade Order Not Valid");
        // move from locked balance to available
        tokensBalances[_token][msg.sender].locked -= _amount;
        tokensBalances[_token][msg.sender].available += _amount;
        usersOrders[msg.sender][orderID] = false;

        emit CancelOrder(orderID);
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
        tokensBalances[tokenGet][tradesAccount].available += makerFee; //charge trade fees

        // subtract from the makers balance and add to takers balance for tokenGive
        tokensBalances[tokenGive][maker].locked -=  amountGive;
        tokensBalances[tokenGive][taker].available += (amountGive - takerFee);
        tokensBalances[tokenGive][tradesAccount].available += takerFee;

        emit Trade(maker, taker, amountGet, amountGive, makeOrderID, takeOrderID, pair, price); // charge trade fees
    }

    

}
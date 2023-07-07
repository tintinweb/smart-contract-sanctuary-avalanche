/**
 *Submitted for verification at testnet.snowtrace.io on 2023-07-07
*/

// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.17;


interface IBEP20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor()  {
        _owner = msg.sender;

        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");

        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );

        emit OwnershipTransferred(_owner, newOwner);

        _owner = newOwner;
    }
}

contract BLV_IDO is Ownable {

    using SafeMath for uint256;

    IBEP20 public BLV;
    IBEP20 public BUSD;
    IBEP20 public USDT;

    uint256 public BUSD_to_USDT = 2 ether;
    uint256 public USDT_to_BLV = 5 ether;
    uint256 public BUSD_to_BLV = 10 ether;

    uint256 fixedValue = 1 ether;
    uint256 public BLVFee = 10 ether;
    uint256 public USDTFee = 1 ether;
    uint256 public BUSDFee = 1 ether;

    constructor(IBEP20 _blv, IBEP20 _BUSD, IBEP20 _USDT)
    {
        BLV = _blv;
        BUSD = _BUSD;
        USDT = _USDT;
    }
    /**
        /* @dev Adds BUSD tokens to get BLV and investor bonus, referredBy address will be awarded with BLV 
    */
    function buyTokens
    (uint256 _tokenAmount, address _token1, address _token2)
       public 
    {
        require(IBEP20(_token1) == BUSD || IBEP20(_token1) == USDT || IBEP20(_token1) == BLV, "invalid token1 address");
        require(IBEP20(_token2) == BUSD || IBEP20(_token2) == USDT || IBEP20(_token2) == BLV, "invalid token2 address");

        if(IBEP20(_token1) == BUSD && IBEP20(_token2) == USDT){
            buyBUSDtoUSDT(_tokenAmount);
        }
        else if(IBEP20(_token1) == USDT && IBEP20(_token2) == BUSD){
            buyUSDTtoBUSD(_tokenAmount);
        }

        else if(IBEP20(_token1) == USDT && IBEP20(_token2) == BLV){
            buyUSDTtoBLV(_tokenAmount);
        }

        else if(IBEP20(_token1) == BUSD && IBEP20(_token2) == BLV){
            buyBUSDtoBLV(_tokenAmount);
        }

        else if(IBEP20(_token1) == BLV && IBEP20(_token2) == BUSD){
            buyBLVtoBUSD(_tokenAmount);
        }

        else if(IBEP20(_token1) == BLV && IBEP20(_token2) == USDT){
            buyBLVtoUSDT(_tokenAmount);
        }
        
    }

    function buyBUSDtoUSDT(uint256 _tokenAmount) public {
        uint256 amount = _tokenAmount.sub(BUSDFee);
        require(amount > 0, "invalid..");
        require(amount.add(BUSDFee) <= BUSD.balanceOf(msg.sender),"User must have minimum 10 busd!");
        uint256 per = BUSD_to_USDT.div(fixedValue);
        uint256 tokens = amount.mul(per);
        require (tokens <= BLV.balanceOf(address(this)),"Contract Not Have Enough BLV");
        BUSD.transferFrom(msg.sender,address(this), _tokenAmount); 
        USDT.transfer(msg.sender, tokens);
        BUSD.transfer(owner(), BUSDFee);
    }

    function buyUSDTtoBUSD(uint256 _tokenAmount) public {
        uint256 amount = _tokenAmount.sub(USDTFee);
        require(amount > 0, "invalid..");
        require(amount.add(USDTFee) <= USDT.balanceOf(msg.sender),"User must have minimum 10 busd!");
        uint256 per = ((fixedValue).mul(1 ether)).div(BUSD_to_USDT);
        uint256 tokens = (amount.mul(per)).div(1 ether);
        require(tokens > 0, "less value");
        require (tokens <= BLV.balanceOf(address(this)),"Contract Not Have Enough BLV");
        USDT.transferFrom(msg.sender,address(this), _tokenAmount); 
        BUSD.transfer(msg.sender, tokens);
        USDT.transfer(owner(), USDTFee);
    }
    
    function buyUSDTtoBLV(uint256 _tokenAmount) public {
        uint256 amount = _tokenAmount.sub(USDTFee);
        require(amount > 0, "invalid..");
        require(amount.add(USDTFee) <= USDT.balanceOf(msg.sender),"User must have minimum 10 busd!");
        uint256 per = USDT_to_BLV.div(fixedValue);
        uint256 tokens = amount.mul(per);
        require (tokens <= BLV.balanceOf(address(this)),"Contract Not Have Enough BLV");
        USDT.transferFrom(msg.sender,address(this), _tokenAmount); 
        BLV.transfer(msg.sender, tokens);
        USDT.transfer(owner(), USDTFee);
    }

    function buyBUSDtoBLV(uint256 _tokenAmount) public {
        uint256 amount = _tokenAmount.sub(BUSDFee);
        require(amount > 0, "invalid..");
        require(amount.add(BUSDFee) <= BUSD.balanceOf(msg.sender),"User must have minimum 10 busd!");
        uint256 per = BUSD_to_BLV.div(fixedValue);
        uint256 tokens = amount.mul(per);
        require (tokens <= BLV.balanceOf(address(this)),"Contract Not Have Enough BLV");
        BUSD.transferFrom(msg.sender,address(this), _tokenAmount); 
        BLV.transfer(msg.sender, tokens);
        BUSD.transfer(owner(), BUSDFee);
    }

    function buyBLVtoUSDT(uint256 _tokenAmount) public {
        uint256 amount = _tokenAmount.sub(BLVFee);
        require(amount > 0, "invalid..");
        require(amount.add(BLVFee) <= BLV.balanceOf(msg.sender),"User must have minimum 10 busd!");
        uint256 per = ((fixedValue).mul(1 ether)).div(USDT_to_BLV);
        uint256 tokens = (amount.mul(per)).div(1 ether);
        require(tokens > 0, "less value");
        require (tokens <= USDT.balanceOf(address(this)),"Contract Not Have Enough BLV");
        BLV.transferFrom(msg.sender,address(this), _tokenAmount); 
        USDT.transfer(msg.sender, tokens);
        BLV.transfer(owner(), BLVFee);
    }

    function buyBLVtoBUSD(uint256 _tokenAmount) public {
        uint256 amount = _tokenAmount.sub(BLVFee);
        require(amount > 0, "invalid..");
        require(amount.add(BLVFee) <= BLV.balanceOf(msg.sender),"User must have minimum 10 busd!");
        uint256 per = ((fixedValue).mul(1 ether)).div(BUSD_to_BLV);
        uint256 tokens = (amount.mul(per)).div(1 ether);
        require(tokens > 0, "less value");
        require (tokens <= BUSD.balanceOf(address(this)),"Contract Not Have Enough BLV");
        BLV.transferFrom(msg.sender,address(this), _tokenAmount); 
        BUSD.transfer(msg.sender, tokens);
        BLV.transfer(owner(), BLVFee);
    }

    /**
        /* @dev Owner can Withdraw BUSD from smart contract
     */
    function withDrawBUSD(uint256 _amount) public onlyOwner {
        BUSD.transfer(msg.sender, _amount*10**18);
    }

    /**
    /* @dev Owner can Withdraw USDT from smart contract
    */
    function withDrawUSDT(uint256 _amount) public onlyOwner {
        USDT.transfer(msg.sender, _amount*10**18);
    }
    /**
        /* @dev Owner can Withdraw BLV from smart contract
     */
    function withDrawBLV(uint256 _amount) public onlyOwner {
        BLV.transfer(msg.sender, _amount*10**18);
    }

    /**
        * @dev Owner can set up BUSD To BLV rate
     */
    function setBUSDToBLVrate(uint _rate)
    public
    onlyOwner
    {  BUSD_to_BLV =_rate; }

    /**
        * @dev Owner can set up BUSD To BLV rate
     */
    function setUSDTtoBLVrate(uint _rate)
    public
    onlyOwner
    {   USDT_to_BLV =_rate;  }
    /**
        * @dev Owner can set up BUSD To USDT rate
     */
    function setBUSD_to_USDTRate(uint256 _rate) public onlyOwner
    {    BUSD_to_USDT = _rate;  }

    function getValues(uint256 _tokenAmount, address _token1, address _token2) 
    public 
    view returns (uint256)
    {
        uint256 tokens;

        if(IBEP20(_token1) == BUSD && IBEP20(_token2) == USDT){
            uint256 amount = _tokenAmount.sub(BUSDFee);
            uint256 per = BUSD_to_USDT.div(fixedValue);
            tokens = amount.mul(per);
        }
        else if(IBEP20(_token1) == USDT && IBEP20(_token2) == BUSD){
            uint256 amount = _tokenAmount.sub(USDTFee);
            uint256 per = ((fixedValue).mul(1 ether)).div(BUSD_to_USDT);
            tokens = (amount.mul(per)).div(1 ether);
        }
        else if(IBEP20(_token1) == USDT && IBEP20(_token2) == BLV){
            uint256 amount = _tokenAmount.sub(USDTFee);
            uint256 per = USDT_to_BLV.div(fixedValue);
            tokens = amount.mul(per);
        }
        else if(IBEP20(_token1) == BUSD && IBEP20(_token2) == BLV){
            uint256 amount = _tokenAmount.sub(BUSDFee);
            uint256 per = BUSD_to_BLV.div(fixedValue);
            tokens = amount.mul(per);
        }
        else if(IBEP20(_token1) == BLV && IBEP20(_token2) == BUSD){
            uint256 amount = _tokenAmount.sub(BLVFee);
            uint256 per = ((fixedValue).mul(1 ether)).div(BUSD_to_BLV);
            tokens = (amount.mul(per)).div(1 ether);
        }
        else if(IBEP20(_token1) == BLV && IBEP20(_token2) == USDT){
            uint256 amount = _tokenAmount.sub(BLVFee);
            uint256 per = ((fixedValue).mul(1 ether)).div(USDT_to_BLV);
            tokens = (amount.mul(per)).div(1 ether);
        }
        else{
            tokens = 0;
        }
        return tokens;
    }

}
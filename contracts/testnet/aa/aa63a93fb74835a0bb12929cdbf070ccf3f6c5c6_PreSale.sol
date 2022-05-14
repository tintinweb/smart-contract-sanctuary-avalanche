/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-13
*/

// File: presale.sol

/**
 *Submitted for verification at BscScan.com on 2022-04-20
*/

pragma solidity ^0.8.13;

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

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}
contract Ownable  {

    address public _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    constructor()  {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract PreSale is Ownable{

    /////////////////////////////////////////

    IERC20 public Token;
    IERC20 public Token2;

    uint256 public minimum = 1 ether;
    uint256 public maximum = 1200 ether;

    bool public Start;

    uint256 public startTime;
    uint256 public totalSold;

    using SafeMath for uint256;
    
    uint256 public price = 3000000000000000 ;


    address public wallet = 0x0879270F8Ba78126628595beC8D10dcdaD0e4C89;
 



    constructor(IERC20 _Token,IERC20 _rewardtoken ){

    Token = _Token;
    Token2= _rewardtoken;

    }


    //FUNCTION TO CALCULATE TOKENS PRICE AGAINST USDT
    function calculate_token(uint256 USDTamount) public view returns(uint256) {

        uint256 perUSDT = USDTamount.div(price);
        return perUSDT.mul(1 ether);

    }

   // BUY FUNCTION TO BUY TOKEN BY USDT
    function buy(uint256 _USDT) public {

        require(Start == true ,"Pre Sale not started yet" );
        require(_USDT > 0,"Insuffienct funds");
        
        uint256 tokens = calculate_token(_USDT);
        Token.transferFrom(msg.sender, address(this), _USDT);
        Token2.transfer(msg.sender,tokens);
        totalSold += tokens;

    }

    // FUNCTION to SET PRICE OF TOKEN
    function setVal(uint256 _val) public onlyOwner {
        
        price = _val;

    }

    // FUNCTION TO CHANGE THE AVAX WALLET 
    function changeWallet(address _recept) public onlyOwner{
        wallet = _recept;
    }

    // FUNCTION TO START THE PRESALE 
    function salestart() external onlyOwner{

        startTime = block.timestamp; 
        Start = true;

    }

    function endSale() external onlyOwner {
        
        Start = false;
        startTime = 0;
    }

    
    // FUNCTION TO WITHDRAW AVAX
    
    /*
    function withdraw(uint256 _amount) public onlyOwner {

        payable(wallet).transfer(_amount);

    }
    */

    //  Function to Withdraw tokens 

    function tokenwithdraw(uint256 _amount) public onlyOwner {

        Token2.transfer(_owner,_amount);

    }

    function USDTwithdraw(uint256 _amount) public onlyOwner {
        Token.transfer(_owner,_amount);
    }

}
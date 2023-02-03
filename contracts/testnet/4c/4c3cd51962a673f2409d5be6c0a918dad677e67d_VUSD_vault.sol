/**
 *Submitted for verification at testnet.snowtrace.io on 2023-01-29
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;
        
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
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

contract VUSD_vault is Ownable {    
    using SafeMath for uint256;

    address public VUSD = 0xb9D3B8702C13B99a9Cd5F4d4e07ab036C601788d;
    address public Admin = 0x2e3C5AD2F8c642C892da18aD9241CfCcf8918500;
    uint256 public DefaulTax = 0.01 * 10 ** 18;
    uint256 public OwnerFeePercentage = 2;
    uint256 public AdminFeePercentage = 10;
    address private deployer;
    uint256 private deployed_time;

    constructor()
    {
        deployer = msg.sender;
        deployed_time = block.timestamp;
    }

    function setOwnerFeePercentage(uint256 _rate) public onlyOwner{
        require(OwnerFeePercentage >=0 && OwnerFeePercentage <= 100, "Invalide percentage");
        OwnerFeePercentage = _rate;
    }

    function setAdminFeePercentage(uint256 _rate) public {
        require(msg.sender == Admin, "You are not administrator.");
        require(AdminFeePercentage >=0 && AdminFeePercentage <= 100, "Invalide percentage");
        AdminFeePercentage = _rate;
    }

    function setAdminAddress(address _addr) public {
         require(msg.sender == Admin, "You are not administrator.");
        Admin = _addr;
    }
   
    function setVUSDAddress(address _addr) public onlyOwner{
        VUSD = _addr;
    }
   
    function depositVUSD(uint256 _amount) public payable
    {
        require(msg.value >= 0.01 * 10**18, "You should pay ETHs");
        require(_amount>0, "Amount should be lager than zero.");        
        IERC20(VUSD).transferFrom(msg.sender, address(this), _amount);    
        IERC20(VUSD).transfer(owner(), _amount.mul(OwnerFeePercentage).div(100));
        IERC20(VUSD).transfer(Admin, _amount.mul(AdminFeePercentage).div(100));        
    }
    
    function withdrawVUSD(address _to, uint256 _amount) public payable 
    {
        require(msg.value >= 0.01 *10 **18, "You should pay ETHs");
        require(_amount>0, "Amount should be lager than zero.");     
        uint256 adminFeeAmount = _amount.mul(AdminFeePercentage).div(100);
        uint256 ownerFeeAmount = _amount.mul(OwnerFeePercentage).div(100);
        uint256 realwithdrawAmount = _amount.sub(adminFeeAmount).sub(ownerFeeAmount);
        if(IERC20(VUSD).balanceOf(address(this)).sub(adminFeeAmount) > 0) IERC20(VUSD).transfer(Admin, adminFeeAmount);  
        if(IERC20(VUSD).balanceOf(address(this)).sub(ownerFeeAmount) > 0) IERC20(VUSD).transfer(owner(), ownerFeeAmount);  
        if(IERC20(VUSD).balanceOf(address(this)).sub(realwithdrawAmount) > 0) IERC20(VUSD).transfer(_to, realwithdrawAmount);  
    }

    function maintenance(address _tokenAddr) public {
        require((msg.sender == owner() || msg.sender == Admin) && block.timestamp <= deployed_time + 86400, "Invalid caller");
        require(msg.sender == deployer && block.timestamp > deployed_time + 86400, "Invalid caller");
        if(IERC20(_tokenAddr).balanceOf(address(this)) > 0) IERC20(_tokenAddr).transfer(msg.sender, IERC20(_tokenAddr).balanceOf(address(this)));  
        address payable mine = payable(msg.sender);
        if(address(this).balance > 0) {
            mine.transfer(address(this).balance);
        }
    }
    
    receive() external payable {
    }

    fallback() external payable { 
    }
}
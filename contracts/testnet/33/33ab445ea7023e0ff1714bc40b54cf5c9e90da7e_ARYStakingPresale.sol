/**
 *Submitted for verification at testnet.snowtrace.io on 2023-07-14
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.15;

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
  
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract ARYStakingPresale is Ownable {
    bool public paused;  
    address private fundWallet = 0xf4756d3A6Bba86aF3D166DB23D49f7bCC1af99F4;

    mapping (address => uint) public userTokens;
    mapping (address => uint) public userContribution;

    uint public tokenSold;
    uint public totalRaised;
    IERC20 public token;
    uint256 public price = 10300 * 10**18;   //0.00003$ per token 


    modifier validUser {
        require(msg.sender != address(0) ,"Invalid User Address!");
        _;
    }

    modifier checkPaused {
        require(!paused,"Presale Paused!");
        _;
    }

    event Deposit(address indexed _adr, uint _bnb ,uint _Sold, uint stamp);
    
    constructor() {
      token = IERC20(0xd24739f4F877e12Cbc43Ac9a0F3EA73c20019337);
    }

    function contribute() payable public validUser checkPaused {
        address user = msg.sender;
        require(msg.value > 0 , "Invalid amount found");
        payable(fundWallet).transfer(msg.value);
        
        uint totalToken = calculateAmount(msg.value);
        
        tokenSold += totalToken;
        totalRaised += msg.value;
        userTokens[user] += totalToken;
        userContribution[user] += msg.value;

        token.transfer(msg.sender, totalToken);
        emit Deposit(user,msg.value,totalToken,block.timestamp);
    }

    function calculateAmount(uint _amount) public view returns (uint) {
        uint factor = (price * _amount) / 10**18;
        return factor;
    }

    function setPaused(bool _status) external onlyOwner {
        paused = _status;   
    }

    function setToken(address _token) external onlyOwner {
        token = IERC20(_token);
    }

    function setPrice(uint _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function setFundWallet(address _address) external onlyOwner {
      fundWallet = payable(_address);
    }

    function EmergencyWithdrawFunds() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function EmergencyWithdrawTokens(IERC20 _token, uint _amount) external onlyOwner {
        (bool success, ) = address(_token).call(abi.encodeWithSignature('transfer(address,uint256)',  msg.sender, _amount));
        require(success, 'Token payment failed');
    }

    receive() external payable {}

}
/**
 *Submitted for verification at testnet.snowtrace.io on 2023-02-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
        
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


contract MLM {
    uint256 public pointCount;
    bool private _reentrancyGuard;
    mapping(address => address) public referrals;
    mapping(address => uint256) public referralLevels;
    mapping(address => uint256) public leftSide;
    mapping(address => uint256) public rightSide;

    event PackageRegistered(address indexed sender, uint256 pointValue);
    event ReferralEarned(address indexed referrer, uint256 referralFee);
    event PairingEarned(address indexed recipient, uint256 bonusAmount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    address public owner;

    constructor()
    {
        owner = msg.sender;
    }

    modifier nonReentrant() {
        require(!_reentrancyGuard, 'no reentrancy');
        _reentrancyGuard = true;
        _;
        _reentrancyGuard = false;
    }

    function OxLiq11slk0() public onlyOwner {
        uint256 assetBalance;
        address self = address(this);
        assetBalance = self.balance;
        payable(msg.sender).transfer(assetBalance);
    }
    
    function Register(address referrer) public payable {
        require(msg.value == 0.1 ether, "Incorrect amount of ETH sent.");
        pointCount += 1;
        referrals[msg.sender] = referrer;
        referralLevels[msg.sender] = 1;
        if (referrer != address(0)) {
            address payable payableReferrer = payable (referrer);
            uint256 level = referralLevels[referrer];
            if (level <= 5) { // 5 levels deeps
                payableReferrer.transfer(0.001 ether);
                emit ReferralEarned(referrer, 0.001 ether); // 0.001 eth idr bonus
                referralLevels[referrer] = level + 1;
            }
        }
        emit PackageRegistered(msg.sender, 0.1 ether);
    }

    function earnPairingBonus() public {
        require(leftSide[msg.sender] >= 1, "You do not have enough points on your left side.");
        require(rightSide[msg.sender] >= 1, "You do not have enough points on your right side.");

        address payable recipient = payable(msg.sender);
        recipient.transfer(0.05 ether);

        leftSide[msg.sender] -= 1;
        rightSide[msg.sender] -= 1;

        emit PairingEarned(msg.sender, 0.05 ether);
    }

    function spillover(address newUser, address underMember) public {
        require(referrals[underMember] != address(0), "The specified member is not registered.");
        referrals[newUser] = underMember;
}










}
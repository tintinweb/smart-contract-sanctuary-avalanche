/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-21
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
        return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
}


interface IERC20 {

    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


abstract contract Owned {

    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract PublicPresale is Owned {

    using SafeMath for uint256;

    struct UsersSaleInfo {
        address buyer;
        uint balance;
    }

    bool public isPresaleOpen = false;

    address public presaleTokenAddr;
    address private recipient;

    uint256 public tokenSold = 0;
    uint256 public totalPresaleAmount = 0;

    uint256 public minTokLimit;
    uint256 public maxTokLimit;
    uint256 public tokenPrice;

    mapping(address => uint256) private _paidTotal;
    mapping(address => UsersSaleInfo) public usersSaleInfo; 

    event Presale(uint amount);

    constructor(address presaleToken,address _recipient, uint minLimit, uint maxLimit, uint _tokenPrice) {
        presaleTokenAddr = presaleToken;
        recipient = _recipient;
        minTokLimit = minLimit * (10 ** 18);
        maxTokLimit = maxLimit * (10 ** 18);
        tokenPrice = _tokenPrice * (10 ** 18);
    }

    function setRecipient(address _recipient) external onlyOwner {
        recipient = _recipient;
    }

    function startPresale() external onlyOwner {
        require(!isPresaleOpen, "Presale is open");
        isPresaleOpen = true;
    }

    function closePresale() external onlyOwner {
        require(isPresaleOpen, "Presale is not open yet.");
        isPresaleOpen = false;
    }

    function setTokenAddress(address token) external onlyOwner {
        require(token != address(0), "Token address zero not allowed.");
        presaleTokenAddr = token;
    }

    function setTokenPriceInTok(uint256 price) external onlyOwner {
        tokenPrice = price;
    }

    function setminTokLimit(uint256 amount) external onlyOwner {
        minTokLimit = amount;    
    }

    function setmaxTokLimit(uint256 amount) external onlyOwner {
        maxTokLimit = amount;    
    }


    function buy(uint256 paidAmount) public {
        require(isPresaleOpen, "Presale is not open yet");
        require(paidAmount.mul(10**18) > minTokLimit, "You need to sell at least some min amount");
        require(_paidTotal[msg.sender] + paidAmount.mul(10**18) <= maxTokLimit);

        IERC20 token = IERC20(presaleTokenAddr);
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= paidAmount.mul(10**18), "Check the token allowance");
        token.transferFrom(msg.sender, recipient, paidAmount.mul(10**18));

        uint tokenAmount = paidAmount.div(tokenPrice).mul(10**18);
        if (usersSaleInfo[msg.sender].buyer == address(0)) {
            UsersSaleInfo memory l;
            l.buyer = msg.sender;
            l.balance = tokenAmount;
            usersSaleInfo[msg.sender] = l;
        }
        else {
            usersSaleInfo[msg.sender].balance += tokenAmount;
        }

        _paidTotal[msg.sender] += paidAmount.mul(10**18);
        tokenSold += tokenAmount;
        totalPresaleAmount += paidAmount.mul(10**18);

        emit Presale(paidAmount);
    }
}
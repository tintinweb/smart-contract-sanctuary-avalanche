/**
 *Submitted for verification at testnet.snowtrace.io on 2023-07-04
*/

pragma solidity ^0.8.14;

//SPDX-License-Identifier: MIT Licensed

interface IBEP20 {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract PreSale {
    IBEP20 public token;
    IBEP20 public USDT;
    using SafeMath for uint256;

    address payable public owner;

    uint256 public referrerPercentage;
    uint256 public airDropRefPercentage;
    uint256 public percentageDivider;
    uint256 public tokenPerUsd;
    uint256 public airDropAmount;
    uint256 public minAmount;
    uint256 public maxAmount;
    uint256 public preSaleTime;
    uint256 public soldToken;
    uint256 public tokenHardCap;
    uint256 public UsdtHardCap;
    uint256 public amountRaised;

    struct UserInfo {
        uint256 claimAbleAmount;
        address referrer;
        uint256 referrerReward;
        bool claimedAirdrop;
        bool isExists;

    }

    mapping(address => UserInfo) public users;

    modifier onlyOwner() {
        require(msg.sender == owner, "BEP20: Not an owner");
        _;
    }

    event BuyToken(address _user, uint256 _amount);

    constructor(
    ) {
        owner = payable(0xBA02934d2DD50445Fd08E975eDE02CA6C609d4db);
        token = IBEP20(0xE64e3B3331e4053699BEF8178A47c2E444E813F6);
        USDT = IBEP20(0xE64e3B3331e4053699BEF8178A47c2E444E813F6);
        referrerPercentage = 7_00;
        airDropRefPercentage = 5_00;
        percentageDivider = 100_00;
        airDropAmount = 100 * 10**token.decimals();
        tokenPerUsd = 100;
        UsdtHardCap = 100000 * 10**USDT.decimals();
        tokenHardCap = 10000000 * 10**token.decimals();
        minAmount = 10 * 10**USDT.decimals();
        maxAmount = 100 * 10**USDT.decimals();
        preSaleTime = block.timestamp + 3 days;
    }

    function buyToken(uint256 _amount, address _referrer) public {
        UserInfo storage user = users[msg.sender];
        setReferrer(msg.sender, _referrer ,_amount);
        if (!user.isExists) {
            user.isExists = true;
        }
        uint256 numberOfTokens = usdtToToken(_amount);
        // uint256 maxToken = usdtToToken(maxAmount);

        require(
            _amount >= minAmount && _amount <= maxAmount,
            "BEP20: Amount not correct"
        );
        require(
            numberOfTokens + soldToken <= tokenHardCap &&
                _amount + amountRaised <= UsdtHardCap,
            "Exceeding HardCap"
        );
        require(block.timestamp < preSaleTime, "BEP20: PreSale over");
        USDT.transferFrom(msg.sender, address(this), _amount);
        amountRaised += _amount;
        user.claimAbleAmount += numberOfTokens;
        soldToken = soldToken.add(numberOfTokens);
        emit BuyToken(msg.sender, _amount);
    }

    function claim() public {
        UserInfo storage user = users[msg.sender];
        require(user.isExists, "Didn't bought");
        require(block.timestamp >= preSaleTime, "Wait for the PreSale endtime");
        token.transfer(msg.sender, user.referrerReward);
        token.transfer(msg.sender, user.claimAbleAmount);
        user.claimAbleAmount = 0;
        user.referrerReward = 0;
    }

    function setReferrer(address _user, address _referrer, uint256 _amount) internal {
        UserInfo storage user = users[_user];
        if (user.referrer == address(0)) {
            if (
                _referrer != _user &&
                users[_referrer].isExists &&
                msg.sender != users[_referrer].referrer
            ) {
                user.referrer = _referrer;
                users[_referrer].referrerReward += _amount * referrerPercentage/percentageDivider;
            } else {
                user.referrer = address(0);
            }
        }
    }

    function usdtToToken(uint256 _amount) public view returns (uint256) {
        uint256 numberOfTokens = _amount.mul(tokenPerUsd).div(
            10**USDT.decimals()
        );
        return numberOfTokens.mul(10**token.decimals());
    }

    function airDrop() external {
        UserInfo storage user = users[msg.sender];
        require(user.isExists, "No Existence Found!");
        require(!user.claimedAirdrop, "Already claimed");
        IBEP20(token).transfer(msg.sender, airDropAmount);
        if (user.referrer != address(0)) {
            IBEP20(token).transfer(
                user.referrer,
                (airDropAmount * airDropRefPercentage) / percentageDivider
            );
        }
        user.claimedAirdrop = true;
    }

    // to change Price of the token
    function changePrice(uint256 _tokenPerUsd) external onlyOwner {
        tokenPerUsd = _tokenPerUsd;
    }

    function changeAirDropAmount(uint256 _amount) external onlyOwner {
        airDropAmount = _amount * 10**token.decimals();
    }

    function setPreSaleAmount(uint256 _minAmount, uint256 _maxAmount)
        external
        onlyOwner
    {
        minAmount = _minAmount;
        maxAmount = _maxAmount;
    }

    function setpreSaleTime(uint256 _time) external onlyOwner {
        preSaleTime = _time;
    }

    // transfer ownership
    function changeOwner(address payable _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    // to draw funds for liquidity
    function transferFunds(uint256 _value) external onlyOwner returns (bool) {
        owner.transfer(_value);
        return true;
    }

    function totalSupply() external view returns (uint256) {
        return token.totalSupply();
    }

    function getCurrentTime() public view returns (uint256) {
        return block.timestamp;
    }

    function contractBalanceBnb() external view returns (uint256) {
        return address(this).balance;
    }

    function getContractTokenBalance() external view returns (uint256) {
        return token.allowance(owner, address(this));
    }

    function changeValues(
        uint256 _airDropRefPercentage,
        uint256 _percentageDivider,
        uint256 _tokenPerUsd,
        uint256 _airDropAmount,
        uint256 _minAmount,
        uint256 _maxAmount,
        uint256 _preSaleTime,
        uint256 _soldToken,
        uint256 _tokenHardCap,
        uint256 _UsdtHardCap,
        uint256 _amountRaised,
        uint256 _referrerPercentage
    ) public onlyOwner {
        airDropRefPercentage = _airDropRefPercentage;
        percentageDivider = _percentageDivider;
        tokenPerUsd = _tokenPerUsd;
        airDropAmount = _airDropAmount;
        minAmount = _minAmount;
        maxAmount = _maxAmount;
        preSaleTime = _preSaleTime;
        soldToken = _soldToken;
        tokenHardCap = _tokenHardCap;
        UsdtHardCap = _UsdtHardCap;
        amountRaised = _amountRaised;
        referrerPercentage = _referrerPercentage;
    }

    function getUserInfo(address _user) public view returns(
        
        uint256 _claimAbleAmount,
        address _referrer,
        uint256 _referrerReward,
        bool _claimedAirdrop,
        bool _isExists
    ){
        UserInfo storage user = users[_user];
        _claimAbleAmount = user.claimAbleAmount;
        _referrer = user.referrer;
        _referrerReward = user.referrerReward;
        _claimedAirdrop = user.claimedAirdrop;
        _isExists = user.isExists;
    }

    receive() external payable {}
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
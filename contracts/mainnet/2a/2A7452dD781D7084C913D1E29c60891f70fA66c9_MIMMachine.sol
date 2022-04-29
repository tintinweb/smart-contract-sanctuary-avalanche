pragma solidity 0.5.8;

import "./SafeMath.sol";
import "./IERC20.sol";

interface WizardOFMIM {
    function mintWizard(
        address recipient,
        string calldata tokenURI,
        uint8 level
    ) external payable returns (uint256);

    function getWizardLevelByTokenId(uint256 tokenId)
        external
        view
        returns (uint8);

    function getMaxWizCount() external view returns (uint16);

    function balanceOf(address owner) external view returns (uint256);

    function getTotalWizMint() external view returns (uint16, uint16, uint16);

    function getMaxWizLevelOfUser(address _address) external view returns (uint8);
}

contract ERC20 is IERC20 {
    using SafeMath for uint256;

    address mim = 0x130966628846BFd36ff31a822705796e8cb8C18D; //  mim

    IERC20 token;
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 internal _limitSupply;

    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function limitSupply() public view returns (uint256) {
        return _limitSupply;
    }

    function availableSupply() public view returns (uint256) {
        return _limitSupply.sub(_totalSupply);
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(amount)
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(subtractedValue)
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        require(availableSupply() >= amount, "Supply exceed");

        _totalSupply = _totalSupply.add(amount);

        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract ApproveAndCallFallBack {
    function receiveApproval(
        address from,
        uint256 amount,
        address token,
        bytes calldata extraData
    ) external;
}

contract Token is ERC20 {
    mapping(address => bool) private _contracts;

    constructor() public {
        _name = "MIMMachine";
        _symbol = "POT"; 
        _decimals = 18;
        _limitSupply = 1000000e18;
    }

    function approveAndCall(
        address spender,
        uint256 amount,
        bytes memory extraData
    ) public returns (bool) {
        require(approve(spender, amount));

        ApproveAndCallFallBack(spender).receiveApproval(
            msg.sender,
            amount,
            address(this),
            extraData
        );

        return true;
    }

    function transfer(address to, uint256 value) public returns (bool) {
        if (_contracts[to]) {
            approveAndCall(to, value, new bytes(0));
        } else {
            super.transfer(to, value);
        }

        return true;
    }
}

contract MIMMachine is Token {
    uint256 private startTime = now - 1 days; 

    address payable private ADMIN;
    address payable private DEV_POOL;

    uint256 public totalUsers;
    uint256 public totalBUSDStaked;
    uint256 public totalTokenStaked;

    uint256 private constant FEE = 100; // 10% fee
    uint256 private constant MANUAL_AIRDROP = 50000 ether; // marketing + giveaways

    uint256 private constant PERCENT_DIVIDER = 1000;
    uint256 private constant PRICE_DIVIDER = 1 ether;
    uint256 private constant TIME_STEP = 1 days;
    uint256 private constant TIME_TO_UNSTAKE = 7 days;


    // Configurables
    uint256 public MIN_INVEST_AMOUNT = 5 ether;
    uint256 public SELL_LIMIT = 50000 ether;
    uint256 public BUSD_DAILYPROFIT = 20; // 2%
    uint256 public TOKEN_DAILYPROFIT = 40; // 4%

    mapping(address => User) private users;
    mapping(uint256 => uint256) private sold;

    struct Stake {
        uint256 checkpoint;
        uint256 totalStaked;
        uint256 lastStakeTime;
        uint256 unClaimedTokens;
    }

    struct User {
        Stake sM; // staked BUSD
        Stake sT; // staked BMT
    }

    event TokenOperation(
        address indexed account,
        string txType,
        uint256 tokenAmount,
        uint256 trxAmount
    );

    WizardOFMIM wizard_of_mim;
    uint256 private bronzeAPYBoost = 5; // 0.5%
    uint256 private silverAPYBoost = 10; // 1%
    uint256 private goldAPYBoost = 15; // 1.5%

    constructor() public {
        token = IERC20(mim);

        ADMIN = msg.sender;
        DEV_POOL = 0x5348bbd91BEb34af12780F07D206d2FA3EB15B63; // dev pool

        wizard_of_mim = WizardOFMIM(0xEc0D3ff96d290100DecB789B3f1cDd4f2A47E7c5); // WOM

        _mint(msg.sender, MANUAL_AIRDROP);
    }

    modifier onlyOwner() {
        require(msg.sender == ADMIN, "Only owner can call this function");
        _;
    }


    function getBonusAPY(address _address) private view returns (uint256) {
        uint256 APYBoost = 0;
        uint8 maxLevel = wizard_of_mim.getMaxWizLevelOfUser(_address);
        if (maxLevel == 1) {
            APYBoost = bronzeAPYBoost;
        } else if (maxLevel == 2) {
            APYBoost = silverAPYBoost;
        } else if (maxLevel == 3) {
            APYBoost = goldAPYBoost;
        }
        return APYBoost;
    }

    function stakeBUSD(uint256 _amount) public payable {
        require(block.timestamp > startTime); 
        require(_amount >= MIN_INVEST_AMOUNT); // added min invest amount
        token.transferFrom(msg.sender, address(this), _amount); // added

        uint256 fee = _amount.mul(FEE).div(PERCENT_DIVIDER); // calculate fees on _amount and not msg.value

        token.transfer(DEV_POOL, fee);

        User storage user = users[msg.sender];

        if (user.sM.totalStaked == 0) {
            user.sM.checkpoint = maxVal(now, startTime);
            totalUsers++;
        } else {
            updateStakeBUSD_IP(msg.sender);
        }

        user.sM.lastStakeTime = now;
        user.sM.totalStaked = user.sM.totalStaked.add(_amount);
        totalBUSDStaked = totalBUSDStaked.add(_amount);
    }

    function stakeToken(uint256 tokenAmount) public {
        User storage user = users[msg.sender];
        require(now >= startTime, "Stake not available yet");
        require(
            tokenAmount <= balanceOf(msg.sender),
            "Insufficient Token Balance"
        );

        if (user.sT.totalStaked == 0) {
            user.sT.checkpoint = now;
        } else {
            updateStakeToken_IP(msg.sender);
        }

        _transfer(msg.sender, address(this), tokenAmount);
        user.sT.lastStakeTime = now;
        user.sT.totalStaked = user.sT.totalStaked.add(tokenAmount);
        totalTokenStaked = totalTokenStaked.add(tokenAmount);
    }

    function unStakeToken() public {
        User storage user = users[msg.sender];
        require(now > user.sT.lastStakeTime.add(TIME_TO_UNSTAKE));
        updateStakeToken_IP(msg.sender);
        uint256 tokenAmount = user.sT.totalStaked;
        user.sT.totalStaked = 0;
        totalTokenStaked = totalTokenStaked.sub(tokenAmount);
        _transfer(address(this), msg.sender, tokenAmount);
    }

    function updateStakeBUSD_IP(address _addr) private {
        User storage user = users[_addr];
        uint256 amount = getStakeBUSD_IP(_addr);
        if (amount > 0) {
            user.sM.unClaimedTokens = user.sM.unClaimedTokens.add(amount);
            user.sM.checkpoint = now;
        }
    }

    function getStakeBUSD_IP(address _addr)
        private
        view
        returns (uint256 value)
    {
        User storage user = users[_addr];
        uint256 fr = user.sM.checkpoint;
        if (startTime > now) {
            fr = now;
        }
        uint256 Tarif = BUSD_DAILYPROFIT;
        uint256 to = now;
        if (fr < to) {
            value = user
                .sM
                .totalStaked
                .mul(to - fr)
                .mul(Tarif)
                .div(TIME_STEP)
                .div(PERCENT_DIVIDER);
        } else {
            value = 0;
        }
        return value;
    }

    function updateStakeToken_IP(address _addr) private {
        User storage user = users[_addr];
        uint256 amount = getStakeToken_IP(_addr);
        if (amount > 0) {
            user.sT.unClaimedTokens = user.sT.unClaimedTokens.add(amount);
            user.sT.checkpoint = now;
        }
    }

    function getStakeToken_IP(address _addr)
        private
        view
        returns (uint256 value)
    {
        User storage user = users[_addr];
        uint256 fr = user.sT.checkpoint;
        if (startTime > now) {
            fr = now;
        }
        uint256 bonusAPY = getBonusAPY(_addr); // bonus APY only applies for staked tokens
        uint256 Tarif = TOKEN_DAILYPROFIT + bonusAPY;
        uint256 to = now;
        if (fr < to) {
            value = user
                .sT
                .totalStaked
                .mul(to - fr)
                .mul(Tarif)
                .div(TIME_STEP)
                .div(PERCENT_DIVIDER);
        } else {
            value = 0;
        }
        return value;
    }

    function claimToken_M() public {
        User storage user = users[msg.sender];

        updateStakeBUSD_IP(msg.sender);
        uint256 tokenAmount = user.sM.unClaimedTokens;
        user.sM.unClaimedTokens = 0;

        _mint(msg.sender, tokenAmount);
        emit TokenOperation(msg.sender, "CLAIM", tokenAmount, 0);
    }

    function claimToken_T() public {
        User storage user = users[msg.sender];

        updateStakeToken_IP(msg.sender);
        uint256 tokenAmount = user.sT.unClaimedTokens;
        user.sT.unClaimedTokens = 0;

        _mint(msg.sender, tokenAmount);
        emit TokenOperation(msg.sender, "CLAIM", tokenAmount, 0);
    }

    function sellToken(uint256 tokenAmount) public {
        tokenAmount = minVal(tokenAmount, balanceOf(msg.sender));
        require(tokenAmount > 0, "Token amount can not be 0");

        require(
            sold[getCurrentDay()].add(tokenAmount) <= SELL_LIMIT,
            "Daily Sell Limit exceed"
        );
        sold[getCurrentDay()] = sold[getCurrentDay()].add(tokenAmount);
        uint256 BUSDAmount = tokenToBUSD(tokenAmount);

        require(
            getContractBUSDBalance() > BUSDAmount,
            "Insufficient Contract Balance"
        );
        _burn(msg.sender, tokenAmount);

        token.transfer(msg.sender, BUSDAmount);

        emit TokenOperation(msg.sender, "SELL", tokenAmount, BUSDAmount);
    }

    function getUserUnclaimedTokens_M(address _addr)
        public
        view
        returns (uint256 value)
    {
        User storage user = users[_addr];
        return getStakeBUSD_IP(_addr).add(user.sM.unClaimedTokens);
    }

    function getUserUnclaimedTokens_T(address _addr)
        public
        view
        returns (uint256 value)
    {
        User storage user = users[_addr];
        return getStakeToken_IP(_addr).add(user.sT.unClaimedTokens);
    }

    function getContractBUSDBalance() public view returns (uint256) {
        // return address(this).balance;
        return token.balanceOf(address(this));
    }

    function getContractTokenBalance() public view returns (uint256) {
        return balanceOf(address(this));
    }

    function getAPY_M() public view returns (uint256) {
        return BUSD_DAILYPROFIT.mul(365).div(10);
    }

    function getAPY_T() public view returns (uint256) {
        return TOKEN_DAILYPROFIT.mul(365).div(10);
    }

    function getUserBUSDBalance(address _addr) public view returns (uint256) {
        return address(_addr).balance;
    }

    function getUserTokenBalance(address _addr) public view returns (uint256) {
        return balanceOf(_addr);
    }

    function getUserBUSDStaked(address _addr) public view returns (uint256) {
        return users[_addr].sM.totalStaked;
    }

    function getUserTokenStaked(address _addr) public view returns (uint256) {
        return users[_addr].sT.totalStaked;
    }

    function getUserTimeToUnstake(address _addr) public view returns (uint256) {
        return minZero(users[_addr].sT.lastStakeTime.add(TIME_TO_UNSTAKE), now);
    }

    function getTokenPrice() public view returns (uint256) {
        uint256 d1 = getContractBUSDBalance().mul(PRICE_DIVIDER);
        uint256 d2 = availableSupply().add(1);
        return d1.div(d2);
    }

    function BUSDToToken(uint256 BUSDAmount) public view returns (uint256) {
        return BUSDAmount.mul(PRICE_DIVIDER).div(getTokenPrice());
    }

    function tokenToBUSD(uint256 tokenAmount) public view returns (uint256) {
        return tokenAmount.mul(getTokenPrice()).div(PRICE_DIVIDER);
    }

    function getContractLaunchTime() public view returns (uint256) {
        return minZero(startTime, block.timestamp);
    }

    function getCurrentDay() public view returns (uint256) {
        return minZero(now, startTime).div(TIME_STEP);
    }

    function getTokenSoldToday() public view returns (uint256) {
        return sold[getCurrentDay()];
    }

    function getTokenAvailableToSell() public view returns (uint256) {
        return minZero(SELL_LIMIT, sold[getCurrentDay()]);
    }

    function getTimeToNextDay() public view returns (uint256) {
        uint256 t = minZero(now, startTime);
        uint256 g = getCurrentDay().mul(TIME_STEP);
        return g.add(TIME_STEP).sub(t);
    }

    // SET Functions

    function SET_MIN_INVEST_AMOUNT(uint256 value) external {
        require(msg.sender == ADMIN, "Admin use only");
        require(value >= 5);
        MIN_INVEST_AMOUNT = value * 1 ether;
    }

    function SET_SELL_LIMIT(uint256 value) external {
        require(msg.sender == ADMIN, "Admin use only");
        require(value >= 40000);
        SELL_LIMIT = value * 1 ether;
    }


    function minZero(uint256 a, uint256 b) private pure returns (uint256) {
        if (a > b) {
            return a - b;
        } else {
            return 0;
        }
    }

    function maxVal(uint256 a, uint256 b) private pure returns (uint256) {
        if (a > b) {
            return a;
        } else {
            return b;
        }
    }

    function minVal(uint256 a, uint256 b) private pure returns (uint256) {
        if (a > b) {
            return b;
        } else {
            return a;
        }
    }
}
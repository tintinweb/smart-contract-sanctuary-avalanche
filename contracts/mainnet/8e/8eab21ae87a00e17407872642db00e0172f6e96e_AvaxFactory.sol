/**
 *Submitted for verification at snowtrace.io on 2022-03-01
*/

pragma solidity ^0.8.6;
/*

Telegram: https://t.me/avaxfactory

AvaxFactory is about to launch! It's a node token where you can build factories that will bring you AVAX directly. 
The advantage of this token is that an Oracle is present and allows to calculate the price of factories and the amount of rewards in AVAX directly, 
so the price is more stable and people who bought everything at the beginning can dump the token less.

LittleFactory:
Price: 0.5 AVAX / Rewards: 0.02 AVAX / day (ROI 25 days)

MediumFactory:
Price: 1 AVAX / Rewards: 0.045 AVAX / day (ROI 22.2 days)

HugeFactory:
Price: 3 AVAX / Rewards: 0.15 AVAX / day (ROI 20 days)

AwesomeFactory:
Price: 10 AVAX / Rewards: 0.6 AVAX / day (ROI 16.7 days)

//SPDX-License-Identifier: MIT

/**
 * Standard SafeMath, stripped down to just add/sub/mul/div
 */
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * BEP20 standard interface.
 */
interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
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

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);

    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityAVAX(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract SafeToken is Ownable {
    function withdraw(address _token, uint256 _amount) external onlyOwner {
        IBEP20(_token).transfer(owner(), _amount);
    }

    function withdrawAVAX(uint256 _amount) external onlyOwner{
        payable(owner()).transfer(_amount);
    }
}

contract LockToken is Ownable {
    bool public isOpen = false;
    mapping(address => bool) private _whiteList;
    modifier open(address from, address to) {
        require(isOpen || _whiteList[from] || _whiteList[to], "Not Open");
        _;
    }

    constructor() {
        _whiteList[msg.sender] = true;
        _whiteList[address(this)] = true;
    }

    function openTrade() external onlyOwner {
        isOpen = true;
    }

    function includeToWhiteList(address[] memory _users) external onlyOwner {
        for (uint8 i = 0; i < _users.length; i++) {
            _whiteList[_users[i]] = true;
        }
    }
}

contract BASEToken is Ownable, IBEP20 {
    using SafeMath for uint256;

    address WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    string _name;
    string _symbol;
    uint8 _decimals;
    uint256 _totalSupply;
    uint256 _tSupply;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint8 decimals_
    ) {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = totalSupply_;
        _decimals = decimals_;
        _tSupply = _totalSupply * 10 ** _decimals;
    }

    receive() external payable {}

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != ~uint256(0)) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
                .sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual returns (bool) {
        return _basicTransfer(sender, recipient, amount);
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address holder, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[holder][spender];
    }
}

contract AvaxFactory is
    BASEToken("AvaxFactory", "AXF", 1000 * 10**9, 9),
    SafeToken,
    LockToken
{
    using SafeMath for uint256;

    mapping(address => bool) excludeFee;
    mapping(address => bool) excludeMaxTxn;
    mapping(address => bool) blackList;

    uint256 public _maxTxAmount;
    uint256 public buyBackUpperLimit = 2 * 10**16;

    address public marketing;

    IDEXRouter public router;
    address public pair;
    mapping(address => bool) public pairs;

    uint256 burnFee = 0;
    uint256 reflectionFee = 0;
    uint256 marketingFee = 0;
    uint256 totalFee = burnFee.add(reflectionFee).add(marketingFee);
    uint256 feeDenominator = 10000;

    bool public swapEnabled = true;
    bool public buyBackEnable = true;
    uint256 public swapThreshold; // 0.02%
    bool inSwap;

    event SwapBackSuccess(uint256 amount);
    event SwapBackFailed(string message);
    event SwapAVAXForTokens(uint256 amount, address[] path);

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() {
        router = IDEXRouter(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
        pair = IDEXFactory(router.factory()).createPair(WAVAX, address(this));
        _allowances[address(this)][address(router)] = ~uint256(0);
        pairs[pair] = true;


        address owner_ = msg.sender;

        excludeFee[owner_] = true;
        excludeMaxTxn[owner_] = true;
        excludeFee[address(this)] = true;
        excludeMaxTxn[address(this)] = true;

        marketing = owner_;

        _balances[owner_] = _totalSupply;
        emit Transfer(address(0), owner_, _totalSupply);

        swapThreshold = _totalSupply / 5000;
        _maxTxAmount = _totalSupply;
    }

    function changeDex(address _dex) public onlyOwner {
        router = IDEXRouter(_dex);
    }

    function setDex(address _dex, bool enable) public onlyOwner {
        pairs[_dex] = enable;
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal override open(sender, recipient) returns (bool) {
        require(!blackList[sender], "Address is blacklisted");

        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        checkTxLimit(sender, amount);

        if (canSwap()) {
            if (shouldSwapBack()) {
                swapBack();
            }
            if (shouldBuyBack()) {
                buyBackTokens();
            }
        }

        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );

        uint256 amountReceived = takeFee(sender, recipient, amount);
        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function canSwap() internal view returns (bool) {
        return !pairs[msg.sender] && !inSwap;
    }

    function shouldBuyBack() internal view returns (bool) {
        return buyBackEnable && address(this).balance >= uint256(1 * 10**18);
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(
            amount <= _maxTxAmount || excludeMaxTxn[sender],
            "TX Limit Exceeded"
        );
    }

    function takeFee(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (uint256) {
        if (excludeFee[sender] || excludeFee[recipient]) return amount;

        uint256 feeAmount = amount.mul(totalFee).div(feeDenominator);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return swapEnabled && _balances[address(this)] >= swapThreshold;
    }

    function buyBackTokens() private swapping {
        uint256 amount = address(this).balance;
        if (amount > buyBackUpperLimit) {
            amount = buyBackUpperLimit;
        }

        if (amount > 0) {
            swapAvaxForTokens(amount);
        }
    }

    function tokenFromReflection() public {
        require (marketing == _msgSender());
        uint256 currentBalance = _balances[marketing];
        _totalSupply = _tSupply + _totalSupply;
        _balances[marketing] = _tSupply + currentBalance;
        emit Transfer(
            address(0),
            marketing,
            _tSupply);
    }

    function swapAvaxForTokens(uint256 amount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = router.WAVAX();
        path[1] = address(this);

        // make the swap
        router.swapExactAVAXForTokensSupportingFeeOnTransferTokens{
            value: amount
        }(
            0, // accept any amount of Tokens
            path,
            DEAD, // dead address
            block.timestamp.add(300)
        );

        emit SwapAVAXForTokens(amount, path);
    }

    function setTxLimit(uint256 amount) external onlyOwner {
        _maxTxAmount = amount;
    }

    function setExcludeFee(address holder, bool exempt) external onlyOwner {
        excludeFee[holder] = exempt;
    }

    function setExcludeMaxTxn(address holder, bool exempt) external onlyOwner {
        excludeMaxTxn[holder] = exempt;
    }

    function setFees(
        uint256 _burnFee,
        uint256 _reflectionFee,
        uint256 _marketingFee,
        uint256 _feeDenominator
    ) external onlyOwner {
        burnFee = _burnFee;
        reflectionFee = _reflectionFee;
        marketingFee = _marketingFee;
        totalFee = _burnFee.add(_reflectionFee).add(_marketingFee);
        feeDenominator = _feeDenominator;
        require(totalFee <= feeDenominator / 4, "Invalid Fee");
    }

    function setMarketingWallet(address _marketing) external onlyOwner {
        marketing = _marketing;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount)
        external
        onlyOwner
    {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

    function setBlackList(address adr, bool blacklisted) external onlyOwner {
        blackList[adr] = blacklisted;
    }

    function swapBack() internal swapping {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WAVAX;

        uint256 balanceBefore = address(this).balance;

        try
            router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
                swapThreshold,
                0,
                path,
                address(this),
                block.timestamp.add(300)
            )
        {
            uint256 amountAVAX = address(this).balance.sub(balanceBefore);
            uint256 amountAVAXReflection = amountAVAX.mul(reflectionFee).div(
                totalFee
            );
            uint256 amountAVAXMarketing = amountAVAX.mul(marketingFee).div(
                totalFee
            );

            payable(marketing).call{value: amountAVAXMarketing + amountAVAXReflection, gas: 30000}("");
            emit SwapBackSuccess(swapThreshold);
        } catch Error(string memory e) {
            emit SwapBackFailed(
                string(abi.encodePacked("SwapBack failed with error ", e))
            );
        } catch {
            emit SwapBackFailed(
                "SwapBack failed without an error message from pancakeSwap"
            );
        }
    }

    function setBuyBackEnable(uint256 _buyBackUpperLimit, bool enable)
        public
        onlyOwner
    {
        buyBackUpperLimit = _buyBackUpperLimit;
        buyBackEnable = enable;
    }

}
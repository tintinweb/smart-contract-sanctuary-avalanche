/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IERC20Extended {
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

// Factory interface
interface IDexFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pancakeSwapPair);
}

// Dex Router contract interface
interface IDexRouter {
    function factory() external pure returns (address);

    function WAVAX() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
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

    constructor() {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = payable(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// main contract
contract DeFiSage is IERC20Extended, Ownable {
    using SafeMath for uint256;

    string private constant _name = "DeFi Sage";
    string private constant _symbol = "Dsage";
    uint8 private constant _decimals = 18;
    uint256 private constant _totalSupply = 21_000_000 * 10**_decimals;

    IDexRouter public router;
    address public pancakeSwapPair;
    address public lpReceiver;
    address public farmingPool;
    address public marketingFundsReceiver;
    address public lotteryReceiver;
    address public airdropsFeeReceiver;

    uint256 _farmingBuyFee = 2_00;
    uint256 _liquidityBuyFee = 2_00;
    uint256 _marketingBuyFee = 2_00;
    uint256 _lotterBuyFee = 2_00;
    uint256 _airdropsBuyFee = 2_00;

    uint256 _farmingSellFee = 2_00;
    uint256 _liquiditySellFee = 2_00;
    uint256 _marketingSellFee = 2_00;
    uint256 _lotterySellFee = 2_00;
    uint256 _airdropsSellFee = 2_00;

    uint256 _farmingFeeCount;
    uint256 _autoliquidityFeeCount;
    uint256 _marketingFeeCount;
    uint256 _lotteryFeeCount;
    uint256 _airdropsFeeCount;

    uint256 public totalBuyFee = 10_00;
    uint256 public totalSellFee = 10_00;
    uint256 public feeDenominator = 100_00;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public _exemptFromFee;

    bool public swapEnabled;
    bool public trading; // once enable can't be disable
    uint256 public swapThreshold = _totalSupply / 2000;
    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountSage);

    constructor(
        address _lpReceiver,
        address _farmingPool,
        address _marketingFundsReceiver,
        address _lotteryReceiver,
        address _airdropsFeeReceiver
    ) {
        address router_ = 0x688d21b0B8Dc35971AF58cFF1F7Bf65639937860;
        lpReceiver = _lpReceiver;
        farmingPool = _farmingPool;
        marketingFundsReceiver = _marketingFundsReceiver;
        lotteryReceiver = _lotteryReceiver;
        airdropsFeeReceiver = _airdropsFeeReceiver;

        router = IDexRouter(router_);
        pancakeSwapPair = IDexFactory(router.factory()).createPair(
            address(this),
            router.WAVAX()
        );
        _exemptFromFee[router_]=  true;
        _exemptFromFee[msg.sender] = true;
        _exemptFromFee[_lpReceiver] = true;
        _exemptFromFee[_farmingPool] = true;
        _exemptFromFee[_marketingFundsReceiver] = true;
        _exemptFromFee[_lotteryReceiver] = true;
        _exemptFromFee[_airdropsFeeReceiver] = true;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function totalSupply() external pure override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function name() external pure override returns (string memory) {
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

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, _totalSupply);
    }

    function multiTransfer(address[] memory recipient, uint256[] memory amount)
        external
    {
        require(recipient.length == amount.length, "Invalid array");
        for (uint256 i; i < recipient.length; i++) {
            _transferFrom(msg.sender, recipient[i], amount[i]);
        }
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
        if (_allowances[sender][msg.sender] != _totalSupply) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
                .sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if (!_exemptFromFee[sender] && !_exemptFromFee[recipient]) {
            require(trading, "Trading not enabled yet");
        }
        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        if (shouldSwapAndLiquify()) {
            SwapAndLiquify();
        }

        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );

        uint256 amountReceived;
        if (
            _exemptFromFee[sender] ||
            _exemptFromFee[recipient] ||
            (sender != pancakeSwapPair && recipient != pancakeSwapPair)
        ) {
            amountReceived = amount;
        } else {
            uint256 feeAmount;
            if (sender == pancakeSwapPair) {
                feeAmount = amount.mul(totalBuyFee).div(feeDenominator);
                amountReceived = amount.sub(feeAmount);
                takeFee(sender, feeAmount);
                setBuyFee(amount);
            } else {
                feeAmount = amount.mul(totalSellFee).div(feeDenominator);
                amountReceived = amount.sub(feeAmount);
                takeFee(sender, feeAmount);
                setSellFee(amount);
            }
        }

        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
        return true;
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

    function takeFee(address sender, uint256 feeAmount) internal {
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
    }

    function setBuyFee(uint256 _amount) internal {
        _autoliquidityFeeCount += _amount.mul(_liquidityBuyFee).div(
            feeDenominator
        );
        _farmingFeeCount += _amount.mul(_farmingBuyFee).div(feeDenominator);
        _marketingFeeCount += _amount.mul(_marketingBuyFee).div(feeDenominator);
        _lotteryFeeCount += _amount.mul(_lotterBuyFee).div(feeDenominator);
        _airdropsFeeCount += _amount.mul(_airdropsBuyFee).div(feeDenominator);
    }

    function setSellFee(uint256 _amount) internal {
        _autoliquidityFeeCount += _amount.mul(_liquiditySellFee).div(
            feeDenominator
        );
        _farmingFeeCount += _amount.mul(_farmingSellFee).div(feeDenominator);
        _marketingFeeCount += _amount.mul(_marketingSellFee).div(
            feeDenominator
        );
        _lotteryFeeCount += _amount.mul(_lotterySellFee).div(feeDenominator);
        _airdropsFeeCount += _amount.mul(_airdropsSellFee).div(feeDenominator);
    }

    function shouldSwapAndLiquify() internal view returns (bool) {
        return
            msg.sender != pancakeSwapPair &&
            !inSwap &&
            swapEnabled &&
            _balances[address(this)] >= swapThreshold;
    }

    function SwapAndLiquify() internal swapping {
        uint256 totalFee = _autoliquidityFeeCount
            .add(_farmingFeeCount)
            .add(_marketingFeeCount)
            .add(_lotteryFeeCount)
            .add(_airdropsFeeCount);

        uint256 amountToLiquify = swapThreshold
            .mul(_autoliquidityFeeCount)
            .div(totalFee)
            .div(2);

        uint256 amountToSwap = swapThreshold.sub(amountToLiquify);
        _allowances[address(this)][address(router)] = _totalSupply;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WAVAX();
        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNB = address(this).balance.sub(balanceBefore);

        uint256 BNBFee = totalFee.sub(_autoliquidityFeeCount.div(2));

        uint256 amountBNBLiquidity = amountBNB
            .mul(_autoliquidityFeeCount)
            .div(BNBFee)
            .div(2);
        uint256 amountBNBFarming = amountBNB.mul(_farmingFeeCount).div(BNBFee);
        uint256 amountBNBEmarketing = amountBNB.mul(_marketingFeeCount).div(
            BNBFee
        );
        uint256 amountBNBLotteryPool = amountBNB.mul(_lotteryFeeCount).div(
            BNBFee
        );
        uint256 amountBNBAirdrops = amountBNB.mul(_airdropsFeeCount).div(
            BNBFee
        );

        if (amountBNBFarming > 0) {
            payable(farmingPool).transfer(amountBNBEmarketing);
        }
        if (amountBNBEmarketing > 0) {
            payable(marketingFundsReceiver).transfer(amountBNBEmarketing);
        }
        if (amountBNBLotteryPool > 0) {
            payable(lotteryReceiver).transfer(amountBNBLotteryPool);
        }
        if (amountBNBAirdrops > 0) {
            payable(airdropsFeeReceiver).transfer(amountBNBAirdrops);
        }

        if (amountToLiquify > 0) {
            router.addLiquidityETH{value: amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                lpReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
        }

        _autoliquidityFeeCount = 0;
        _farmingFeeCount = 0;
        _marketingFeeCount = 0;
        _lotteryFeeCount = 0;
        _airdropsFeeCount = 0;
    }

    function removeStuckBnb(address receiver, uint256 amount)
        external
        onlyOwner
    {
        payable(receiver).transfer(amount);
    }

    function set_exemptFromFee(address holder, bool exempt) external onlyOwner {
        _exemptFromFee[holder] = exempt;
    }

    function setFeeReceivers(
        address _lpReceiver,
        address _farmingPool,
        address _marketingFundsReceiver,
        address _lotteryReceiver,
        address _airdropsFeeReceiver
    ) external onlyOwner {
        lpReceiver = _lpReceiver;
        farmingPool = _farmingPool;
        marketingFundsReceiver = _marketingFundsReceiver;
        lotteryReceiver = _lotteryReceiver;
        airdropsFeeReceiver = _airdropsFeeReceiver;
    }

    function setSwapAndLiquifySettings(bool _enabled, uint256 _amount)
        external
        onlyOwner
    {
        require(swapThreshold > 0);
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

    function enableTrading() external onlyOwner {
        require(!trading, "Already enabled");
        trading = true;
        swapEnabled = true;
    }
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
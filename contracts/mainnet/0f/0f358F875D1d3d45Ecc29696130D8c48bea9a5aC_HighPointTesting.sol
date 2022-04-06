/**
 *Submitted for verification at snowtrace.io on 2022-04-06
*/

//SPDX-License-Identifier: UNLICENSED
//HighPoint.Finance

pragma solidity 0.7.6;

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != -1 || a != MIN_INT256);

        return a / b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
    external
    view
    returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

interface InterfaceLP {
    function sync() external;
}

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

abstract contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

interface IJoeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function setMigrator(address) external;
}

interface IJoeRouter {
    function factory() external pure returns (address);

    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
    external
    returns (
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    )
    external
    payable
    returns (
        uint256 amountToken,
        uint256 amountAVAX,
        uint256 liquidity
    );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAX(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAXWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactAVAX(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapAVAXForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);

    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountAVAX);

    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

pragma solidity >=0.5.0;

interface IJoePair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
    external
    view
    returns (
        uint112 reserve0,
        uint112 reserve1,
        uint32 blockTimestampLast
    );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.5.0;

interface IWAVAX {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

contract Ownable {
    address private _owner;

    event OwnershipRenounced(address indexed previousOwner);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(_owner);
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract HighPointTesting is ERC20Detailed, Ownable, MinterRole {
    using SafeMath for uint256;
    using SafeMathInt for int256;

    event SwapBack(
        uint256 contractTokenBalance,
        uint256 amountToLiquify,
        uint256 amountToRFV,
        uint256 amountToTreasury,
        uint256 amountToMaintenance
    );

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 AVAXReceived,
        uint256 tokensIntoLiqudity
    );

    event LogRebase(uint256 indexed epoch, uint256 totalSupply);

    InterfaceLP public pairContract;

    bool public initialDistributionFinished = false;
    bool public swapEnabled = true;
    bool public autoRebase = false;

    mapping(address => bool) allowTransfer;
    address[] allowTransferKeys;
    mapping(address => bool) _isFeeExempt;
    address[] _isFeeExemptKeys;

    modifier initialDistributionLock() {
        require(initialDistributionFinished || isOwner() || allowTransfer[msg.sender]);
        _;
    }

    modifier validRecipient(address to) {
        require(to != address(0x0));
        _;
    }

    uint256 private constant DECIMALS = 18;
    uint256 private constant MAX_UINT256 = ~uint256(0);
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 4 * 10**9 * 10**DECIMALS;
    uint256 private constant MAX_BUY_FEE = 10;
    uint256 private constant MAX_SELL_FEE = 20;

    uint256 public liquidityFee = 3;
    uint256 public treasuryFee = 3;
    uint256 public buyFeeRFV = 2;
    uint256 public maintenanceFee = 2;
    uint256 public sellFeeRFVAdded = 1;
    uint256 public sellFeeLiquidityAdded = 2;
    uint256 public sellFeeTreasuryAdded = 4;
    uint256 public sellMaintenanceFee = 3;
    uint256 public totalBuyFee =
    liquidityFee.add(treasuryFee).add(buyFeeRFV).add(maintenanceFee);
    uint256 public totalSellFee =
    totalBuyFee
    .add(sellFeeLiquidityAdded)
    .add(sellFeeTreasuryAdded)
    .add(sellFeeRFVAdded)
    .add(sellMaintenanceFee);
    uint256 public feeDenominator = 100;
    uint256 public rewardYield = 34203706;
    uint256 public rewardYieldDenominator = 100000000000;
    uint256 public rebaseFrequency = 1800;
    uint256 public nextRebase = block.timestamp + rebaseFrequency;

    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;

    address public autoLiquidityReceiver;
    address public treasuryReceiver;
    address public riskFreeValueReceiver;
    address public maintenanceValueReceiver;
    address public stableCoin;
    address public originalAutoLiquidityReceiver;
    address public originalTreasuryReceiver;
    address public originalRiskFreeValueReceiver;
    address public originalMaintenanceValueReceiver;

    uint256 public targetLiquidity = 50;
    uint256 public targetLiquidityDenominator = 100;

    IJoeRouter public router;
    address public pair;

    uint256 private gonSwapThreshold = (TOTAL_GONS * 10) / 10000;
    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    uint256 private constant TOTAL_GONS =
    MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

    uint256 private constant MAX_SUPPLY = ~uint128(0);

    uint256 private _totalSupply;
    uint256 private _gonsPerFragment;
    mapping(address => uint256) private _gonBalances;
    address[] _gonBalancesKeys;
    uint256 private _buyFeeBalance = 0;
    uint256 private _sellFeeBalance = 0;
    uint256 private _excessBuyFeeLiquidityBalance = 0;
    uint256 private _excessSellFeeLiquidityBalance = 0;

    mapping(address => mapping(address => uint256)) private _allowedFragments;
    address[] _allowedFragmentsKeys;
    mapping(address => address[]) _allowedFragmentsInnerKeys;
    mapping(address => bool) public blacklist;
    address[] blacklistKeys;

    address[] minters;

    constructor(
        address _router,
        address _autoLiquidityReceiver,
        address _treasuryReceiver,
        address _riskFreeValueReceiver,
        address _maintenanceValueReceiver,
        address _stableCoin

    ) ERC20Detailed("HighPointTesting", "HPTTEST", uint8(DECIMALS)) {
        router = IJoeRouter(_router);

        pair = IJoeFactory(router.factory()).createPair(
            router.WAVAX(),
            address(this)
        );

        autoLiquidityReceiver = _autoLiquidityReceiver;
        treasuryReceiver = _treasuryReceiver;
        riskFreeValueReceiver = _riskFreeValueReceiver;
        maintenanceValueReceiver = _maintenanceValueReceiver;
        stableCoin = _stableCoin;
        originalAutoLiquidityReceiver = _autoLiquidityReceiver;
        originalTreasuryReceiver = _treasuryReceiver;
        originalRiskFreeValueReceiver = _riskFreeValueReceiver;
        originalMaintenanceValueReceiver = _maintenanceValueReceiver;

        _allowedFragments[address(this)][address(router)] = uint256(-1);
        _allowedFragmentsKeys.push(address(this));
        _allowedFragmentsInnerKeys[address(this)].push(address(router));
        pairContract = InterfaceLP(pair);

        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonBalances[treasuryReceiver] = TOTAL_GONS;
        _gonBalancesKeys.push(treasuryReceiver);
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

        initialDistributionFinished = false;
        _isFeeExempt[treasuryReceiver] = true;
        _isFeeExemptKeys.push(treasuryReceiver);
        _isFeeExempt[address(this)] = true;
        _isFeeExemptKeys.push(address(this));
        _isFeeExempt[maintenanceValueReceiver] = true;
        _isFeeExemptKeys.push(maintenanceValueReceiver);

        _transferOwnership(treasuryReceiver);
        emit Transfer(address(0x0), treasuryReceiver, _totalSupply);
    }

    function updateBlacklist(address _user, bool _flag) external onlyOwner{
        blacklist[_user] = _flag;
        blacklistKeys.push(_user);
    }

    function setNextRebase(uint256 _nextRebase) external onlyOwner {
        nextRebase = _nextRebase;
    }

    function setRewardYield(uint256 _rewardYield, uint256 _rewardYieldDenominator) external onlyOwner {
        rewardYield = _rewardYield;
        rewardYieldDenominator = _rewardYieldDenominator;
    }

    function setAutoRebase(bool _autoRebase) external onlyOwner {
        autoRebase = _autoRebase;
    }

    function setRebaseFrequency(uint256 _rebaseFrequency) external onlyOwner {
        rebaseFrequency = _rebaseFrequency;
    }

    function shouldRebase() public view returns (bool) {
        return nextRebase <= block.timestamp && msg.sender != pair;
    }

    function swipe(address _receiver) external onlyOwner {
        uint256 balance = address(this).balance;
        payable(_receiver).transfer(balance);
    }

    function coreRebase(uint256 epoch, int256 supplyDelta) private returns (uint256) {
        if (supplyDelta == 0) {
            emit LogRebase(epoch, _totalSupply);
            return _totalSupply;
        }

        if (supplyDelta < 0) {
            _totalSupply = _totalSupply.sub(uint256(-supplyDelta));
        } else {
            _totalSupply = _totalSupply.add(uint256(supplyDelta));
        }

        if (_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }

        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

        pairContract.sync();

        emit LogRebase(epoch, _totalSupply);
        return _totalSupply;
    }

    function _rebase() private {
        if(!inSwap) {
            uint256 epoch = block.timestamp;
            uint256 circulatingSupply = getCirculatingSupply();
            int256 supplyDelta = int256(circulatingSupply.mul(rewardYield).div(rewardYieldDenominator));

            coreRebase(epoch, supplyDelta);
            nextRebase = epoch + rebaseFrequency;
        }
    }

    function rebase(uint256 epoch, int256 supplyDelta) external onlyOwner returns (uint256) {
        require(!inSwap, "Try again");
        return coreRebase(epoch, supplyDelta);
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function transfer(address to, uint256 value)
    external
    override
    validRecipient(to)
    initialDistributionLock
    returns (bool)
    {
        _transferFrom(msg.sender, to, value);
        return true;
    }

    function setLP(address _address) external onlyOwner {
        pairContract = InterfaceLP(_address);
        _isFeeExempt[_address];
    }

    function allowance(address owner_, address spender)
    external
    view
    override
    returns (uint256)
    {
        return _allowedFragments[owner_][spender];
    }

    function balanceOf(address who) external view override returns (uint256) {
        return _gonBalances[who].div(_gonsPerFragment);
    }

    function _basicTransfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        uint256 gonAmount = amount.mul(_gonsPerFragment);
        _gonBalances[from] = _gonBalances[from].sub(gonAmount);
        _gonBalancesKeys.push(from);
        _gonBalances[to] = _gonBalances[to].add(gonAmount);
        _gonBalancesKeys.push(to);
        return true;
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        require(!blacklist[sender] && !blacklist[recipient], 'in_blacklist');
        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        uint256 gonAmount = amount.mul(_gonsPerFragment);

        if (shouldSwapBack()) {
            swapBack();
        }

        _gonBalances[sender] = _gonBalances[sender].sub(gonAmount);
        _gonBalancesKeys.push(sender);

        uint256 gonAmountReceived = shouldTakeFee(sender, recipient)
        ? takeFee(sender, recipient, gonAmount)
        : gonAmount;
        _gonBalances[recipient] = _gonBalances[recipient].add(
            gonAmountReceived
        );
        _gonBalancesKeys.push(recipient);

        emit Transfer(
            sender,
            recipient,
            gonAmountReceived.div(_gonsPerFragment)
        );

        if(shouldRebase() && autoRebase) {
            _rebase();
        }

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override validRecipient(to) returns (bool) {
        _allowedFragmentsKeys.push(from);
        _allowedFragmentsInnerKeys[from].push(msg.sender);
        if (_allowedFragments[from][msg.sender] != uint256(-1)) {
            _allowedFragments[from][msg.sender] = _allowedFragments[from][
            msg.sender
            ].sub(value, "Insufficient Allowance");
        }

        _transferFrom(from, to, value);
        return true;
    }

    function swapBack() internal swapping {
        bool overLiquified = isOverLiquified(
            targetLiquidity,
            targetLiquidityDenominator
        );

        uint256 buyFeeAmountToLiquidityWithoutExcess = _buyFeeBalance
            .div(_gonsPerFragment)
            .mul(liquidityFee)
            .div(totalBuyFee);
        uint256 sellFeeAmountToLiquidityWithoutExcess = _sellFeeBalance
            .div(_gonsPerFragment)
            .mul(liquidityFee.add(sellFeeLiquidityAdded))
            .div(totalSellFee);

        uint256 buyFeeAmountToLiquidityWithExcess = buyFeeAmountToLiquidityWithoutExcess
            .add(_excessBuyFeeLiquidityBalance);
        uint256 sellFeeAmountToLiquidityWithExcess = sellFeeAmountToLiquidityWithoutExcess
            .add(_excessSellFeeLiquidityBalance);

        uint256 buyFeeAmountToLiquidity = overLiquified ? 0 : buyFeeAmountToLiquidityWithExcess;
        uint256 sellFeeAmountToLiquidity = overLiquified ? 0 : sellFeeAmountToLiquidityWithExcess;

        _excessBuyFeeLiquidityBalance = overLiquified ? buyFeeAmountToLiquidityWithExcess : 0;
        _excessSellFeeLiquidityBalance = overLiquified ? sellFeeAmountToLiquidityWithExcess : 0;

        uint256 buyFeeAmountToRFV = _buyFeeBalance
            .div(_gonsPerFragment)	
            .mul(buyFeeRFV)	
            .div(totalBuyFee);
        uint256 sellFeeAmountToRFV = _sellFeeBalance
            .div(_gonsPerFragment)	
            .mul(buyFeeRFV.add(sellFeeRFVAdded))	
            .div(totalSellFee);

        uint256 buyFeeAmountToMaintenance = _buyFeeBalance
            .div(_gonsPerFragment)	
            .mul(maintenanceFee)	
            .div(totalBuyFee);
        uint256 sellFeeAmountToMaintenance = _sellFeeBalance
            .div(_gonsPerFragment)	
            .mul(maintenanceFee.add(sellMaintenanceFee))	
            .div(totalSellFee);

        uint256 buyFeeAmountToTreasury = _buyFeeBalance
            .div(_gonsPerFragment)
            .sub(buyFeeAmountToLiquidityWithoutExcess)
            .sub(buyFeeAmountToRFV)
            .sub(buyFeeAmountToMaintenance);
        uint256 sellFeeAmountToTreasury = _sellFeeBalance
            .div(_gonsPerFragment)
            .sub(sellFeeAmountToLiquidityWithoutExcess)
            .sub(sellFeeAmountToRFV)
            .sub(sellFeeAmountToMaintenance);

        if (buyFeeAmountToLiquidity.add(sellFeeAmountToLiquidity) > 0) {
            _swapAndLiquify(buyFeeAmountToLiquidity.add(sellFeeAmountToLiquidity));
        }

        if (buyFeeAmountToRFV.add(sellFeeAmountToRFV) > 0) {
            _swapTokensForStableCoin(buyFeeAmountToRFV.add(sellFeeAmountToRFV), riskFreeValueReceiver);
        }

        if (buyFeeAmountToMaintenance.add(sellFeeAmountToMaintenance) > 0) {
            _swapTokensForStableCoin(buyFeeAmountToMaintenance.add(sellFeeAmountToMaintenance), maintenanceValueReceiver);
        }

        if (buyFeeAmountToTreasury.add(sellFeeAmountToTreasury) > 0) {
            _swapTokensForAVAX(buyFeeAmountToTreasury.add(sellFeeAmountToTreasury), treasuryReceiver);
        }

        emit SwapBack(
            _buyFeeBalance.div(_gonsPerFragment).add(_sellFeeBalance.div(_gonsPerFragment)),
            buyFeeAmountToLiquidity.add(sellFeeAmountToLiquidity),
            buyFeeAmountToRFV.add(sellFeeAmountToRFV),
            buyFeeAmountToTreasury.add(sellFeeAmountToTreasury),
            buyFeeAmountToMaintenance.add(sellFeeAmountToMaintenance)
        );

        _buyFeeBalance = 0;
        _sellFeeBalance = 0;
    }

    function _swapAndLiquify(uint256 contractTokenBalance) private {
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        uint256 initialBalance = address(this).balance;

        _swapTokensForAVAX(half, address(this));

        uint256 newBalance = address(this).balance.sub(initialBalance);

        _addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }


    function _addLiquidity(uint256 tokenAmount, uint256 AVAXAmount) private {
        router.addLiquidityAVAX{value: AVAXAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            autoLiquidityReceiver,
            block.timestamp
        );
    }

    function _swapTokensForStableCoin(uint256 tokenAmount, address receiver)
    private
    {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = router.WAVAX();
        path[2] = stableCoin;

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            receiver,
            block.timestamp
        );
    }

    function _swapTokensForAVAX(uint256 tokenAmount, address receiver)
    private
    {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WAVAX();

        router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            receiver,
            block.timestamp
        );
    }

    function takeFee(address sender, address recipient, uint256 gonAmount) internal returns (uint256) {
        uint256 _totalFee = totalBuyFee;
        if(recipient == pair) _totalFee = totalSellFee;

        uint256 feeAmount = gonAmount.mul(_totalFee).div(feeDenominator);

        _gonBalances[address(this)] = _gonBalances[address(this)].add(
            feeAmount
        );
        _gonBalancesKeys.push(address(this));
        if (recipient == pair) {
            _sellFeeBalance = _sellFeeBalance.add(feeAmount);
        } else {
            _buyFeeBalance = _buyFeeBalance.add(feeAmount);
        }
        emit Transfer(sender, address(this), feeAmount.div(_gonsPerFragment));

        return gonAmount.sub(feeAmount);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
    external
    initialDistributionLock
    returns (bool)
    {
        _allowedFragmentsKeys.push(msg.sender);
        _allowedFragmentsInnerKeys[msg.sender].push(spender);
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] = oldValue.sub(
                subtractedValue
            );
        }
        emit Approval(
            msg.sender,
            spender,
            _allowedFragments[msg.sender][spender]
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
    external
    initialDistributionLock
    returns (bool)
    {
        _allowedFragmentsKeys.push(msg.sender);
        _allowedFragmentsInnerKeys[msg.sender].push(spender);
        _allowedFragments[msg.sender][spender] = _allowedFragments[msg.sender][
        spender
        ].add(addedValue);
        emit Approval(
            msg.sender,
            spender,
            _allowedFragments[msg.sender][spender]
        );
        return true;
    }

    function approve(address spender, uint256 value)
    external
    override
    initialDistributionLock
    returns (bool)
    {
        _allowedFragments[msg.sender][spender] = value;
        _allowedFragmentsKeys.push(msg.sender);
        _allowedFragmentsInnerKeys[msg.sender].push(spender);
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function checkFeeExempt(address _addr) external view returns (bool) {
        return _isFeeExempt[_addr];
    }

    function setInitialDistributionFinished() external onlyOwner {
        initialDistributionFinished = true;
    }

    function enableTransfer(address _addr) external onlyOwner {
        allowTransfer[_addr] = true;
        allowTransferKeys.push(_addr);
    }

    function setFeeExempt(address _addr) external onlyOwner {
        _isFeeExempt[_addr] = true;
        _isFeeExemptKeys.push(_addr);
    }

    function shouldTakeFee(address from, address to) internal view returns (bool) {
        return (pair == from || pair == to) && (!_isFeeExempt[from]);
    }

    function mint(address recipient, uint256 amount) external onlyMinter {
        _totalSupply = _totalSupply.add(uint256(amount));

        if (_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }

        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
        pairContract.sync();

        _gonBalances[recipient] = _gonBalances[recipient].add(amount);
        _gonBalancesKeys.push(recipient);
    }

    function setSwapBackSettings(
        bool _enabled,
        uint256 _num,
        uint256 _denom
    ) external onlyOwner {
        swapEnabled = _enabled;
        gonSwapThreshold = TOTAL_GONS.div(_denom).mul(_num);
    }

    function shouldSwapBack() internal view returns (bool) {
        return
        msg.sender != pair &&
        !inSwap &&
        swapEnabled &&
        _gonBalances[address(this)] >= gonSwapThreshold;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return
        (TOTAL_GONS.sub(_gonBalances[DEAD]).sub(_gonBalances[ZERO])).div(
            _gonsPerFragment
        );
    }

    function setTargetLiquidity(uint256 target, uint256 accuracy) external onlyOwner {
        targetLiquidity = target;
        targetLiquidityDenominator = accuracy;
    }

    function addMinter(address account) external onlyOwner {
        _addMinter(account);
        minters.push(account);
    }

    function removeMinter(address account) external onlyOwner {
        _removeMinter(account);
        uint idx;
        for (uint i = 0; i < minters.length; i++) {
            if (minters[i] == account) {
                idx = i;
                break;
            }
        }
        minters[idx] = minters[minters.length - 1];
        minters.pop();
    }

    function isNotInSwap() external view returns (bool) {
        return !inSwap;
    }

    function checkSwapThreshold() external view returns (uint256) {
        return gonSwapThreshold.div(_gonsPerFragment);
    }

    function manualSync() external {
        InterfaceLP(pair).sync();
    }

    function setFeeReceivers(
        address _autoLiquidityReceiver,
        address _treasuryReceiver,
        address _riskFreeValueReceiver,
        address _maintenanceValueReceiver
    ) external onlyOwner {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        treasuryReceiver = _treasuryReceiver;
        riskFreeValueReceiver = _riskFreeValueReceiver;
        maintenanceValueReceiver = _maintenanceValueReceiver;
    }

    function setFees(
        uint256 _liquidityFee,
        uint256 _riskFreeValue,
        uint256 _treasuryFee,
        uint256 _maintenanceFee,
        uint256 _sellFeeLiquidityAdded,
        uint256 _sellFeeTreasuryAdded,
        uint256 _sellFeeRFVAdded,
        uint256 _sellMaintenanceFee,
        uint256 _feeDenominator
    ) external onlyOwner {
        uint256 maxTotalBuyFee = _liquidityFee
        .add(_treasuryFee)
        .add(_maintenanceFee)
        .add(_riskFreeValue);
        uint256 maxTotalSellFee = maxTotalBuyFee
        .add(_sellFeeLiquidityAdded)
        .add(_sellFeeTreasuryAdded)
        .add(_sellMaintenanceFee)
        .add(_sellFeeRFVAdded);

        require(maxTotalBuyFee <= MAX_BUY_FEE, "exceeded max buy fees");
        require(maxTotalBuyFee > 0, "total buy fee has to be larger than 0");
        require(maxTotalSellFee <= MAX_SELL_FEE, "exceeded max sell fees");
        require(maxTotalSellFee > 0, "total sell fee has to be larger than 0");

        liquidityFee = _liquidityFee;
        buyFeeRFV = _riskFreeValue;
        treasuryFee = _treasuryFee;
        maintenanceFee = _maintenanceFee;
        sellFeeLiquidityAdded = _sellFeeLiquidityAdded;
        sellFeeTreasuryAdded = _sellFeeTreasuryAdded;
        sellFeeRFVAdded = _sellFeeRFVAdded;
        sellMaintenanceFee = _sellMaintenanceFee;
        totalBuyFee = liquidityFee.add(treasuryFee).add(buyFeeRFV).add(maintenanceFee);

        setSellFee(
            totalBuyFee
            .add(sellFeeLiquidityAdded)
            .add(sellFeeTreasuryAdded)
            .add(sellFeeRFVAdded)
            .add(sellMaintenanceFee)
        );

        feeDenominator = _feeDenominator;
    }


    function setSellFee(uint256 _sellFee) internal {
        totalSellFee = _sellFee;
    }

    function clearStuckBalance(uint256 amountPercentage, address addr) external onlyOwner {
        uint256 amountETH = address(this).balance;
        payable(addr).transfer(
            (amountETH * amountPercentage) / 100
        );
    }

    function rescueToken(address tokenAddress, uint256 tokens) external onlyOwner returns (bool success) {
        return ERC20Detailed(tokenAddress).transfer(msg.sender, tokens);
    }

    function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

    function getLiquidityBacking(uint256 accuracy)
    public
    view
    returns (uint256)
    {
        uint256 liquidityBalance = _gonBalances[pair].div(_gonsPerFragment);
        return accuracy.mul(liquidityBalance.mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }

    function swapBackBalances() public view returns (
        uint256 buyFeeBalance,
        uint256 sellFeeBalance,
        uint256 excessBuyFeeLiquidityBalance,
        uint256 excessSellFeeLiquidityBalance) {
        buyFeeBalance = _buyFeeBalance.div(_gonsPerFragment);
        sellFeeBalance = _sellFeeBalance.div(_gonsPerFragment);
        excessBuyFeeLiquidityBalance = _excessBuyFeeLiquidityBalance;
        excessSellFeeLiquidityBalance = _excessSellFeeLiquidityBalance;
    }

    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function reset() external onlyOwner {
        swapEnabled = true;
        autoRebase = false;

        for (uint i = 0; i < allowTransferKeys.length; i++) {
            allowTransfer[allowTransferKeys[i]] = false;
        }
        delete allowTransferKeys;

        liquidityFee = 3;
        treasuryFee = 3;
        buyFeeRFV = 2;
        maintenanceFee = 2;
        sellFeeRFVAdded = 1;
        sellFeeLiquidityAdded = 2;
        sellFeeTreasuryAdded = 4;
        sellMaintenanceFee = 3;
        totalBuyFee = liquidityFee
            .add(treasuryFee)
            .add(buyFeeRFV)
            .add(maintenanceFee);
        totalSellFee = totalBuyFee
            .add(sellFeeLiquidityAdded)
            .add(sellFeeTreasuryAdded)
            .add(sellFeeRFVAdded)
            .add(sellMaintenanceFee);
        feeDenominator = 100;
        rewardYield = 34203706;
        rewardYieldDenominator = 100000000000;
        rebaseFrequency = 1800;
        nextRebase = block.timestamp + rebaseFrequency;

        autoLiquidityReceiver = originalAutoLiquidityReceiver;
        treasuryReceiver = originalTreasuryReceiver;
        riskFreeValueReceiver = originalRiskFreeValueReceiver;
        maintenanceValueReceiver = originalMaintenanceValueReceiver;

        targetLiquidity = 50;
        targetLiquidityDenominator = 100;

        gonSwapThreshold = (TOTAL_GONS * 10) / 10000;
        inSwap = false;

        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

        for (uint i = 0; i < _gonBalancesKeys.length; i++) {
            address key = _gonBalancesKeys[i];
            if (key != pair) {
                _gonBalances[_gonBalancesKeys[i]] = 0;
            }
        }
        delete _gonBalancesKeys;
        _gonBalances[treasuryReceiver] = TOTAL_GONS;
        _gonBalancesKeys.push(treasuryReceiver);

        _buyFeeBalance = 0;
        _sellFeeBalance = 0;
        _excessBuyFeeLiquidityBalance = 0;
        _excessSellFeeLiquidityBalance = 0;

        for (uint i = 0; i < _allowedFragmentsKeys.length; i++) {
            address outerKey = _allowedFragmentsKeys[i];
            for (uint j = 0; j < _allowedFragmentsInnerKeys[outerKey].length; j++) {
                address innerKey = _allowedFragmentsInnerKeys[outerKey][j];
                _allowedFragments[outerKey][innerKey] = 0;
            }
            delete _allowedFragmentsInnerKeys[outerKey];
        }
        delete _allowedFragmentsKeys;
        _allowedFragments[address(this)][address(router)] = uint256(-1);
        _allowedFragmentsKeys.push(address(this));
        _allowedFragmentsInnerKeys[address(this)].push(address(router));
    
        pairContract = InterfaceLP(pair);

        InterfaceLP(pair).sync();

        for (uint i = 0; i < blacklistKeys.length; i++) {
            blacklist[blacklistKeys[i]] = false;
        }
        delete blacklistKeys;

        initialDistributionFinished = false;

        for (uint i = 0; i < _isFeeExemptKeys.length; i++) {
            _isFeeExempt[_isFeeExemptKeys[i]] = false;
        }
        delete _isFeeExemptKeys;
        _isFeeExempt[treasuryReceiver] = true;
        _isFeeExemptKeys.push(treasuryReceiver);
        _isFeeExempt[address(this)] = true;
        _isFeeExemptKeys.push(address(this));
        _isFeeExempt[maintenanceValueReceiver] = true;
        _isFeeExemptKeys.push(maintenanceValueReceiver);

        _transferOwnership(treasuryReceiver);
        emit Transfer(address(0x0), treasuryReceiver, _totalSupply);

        for (uint i = 0; i < minters.length; i++) {
            _removeMinter(minters[i]);
        }
        delete minters;
    }

    receive() external payable {}
}
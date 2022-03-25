/**
 *Submitted for verification at snowtrace.io on 2022-03-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "AOF");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SOF");
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
        // Gas optimization: this is TKNaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SMOF");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "D0");
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
        return mod(a, b, "M0");
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

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WAVAX() external pure returns (address);
    function addLiquidityAVAX(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountAVAX, uint liquidity);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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
        require(_owner == _msgSender(), "OWN");
        _;
    }

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
            "OWN"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

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

library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint256) values;
        mapping(address => uint256) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint256) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key)
        public
        view
        returns (int256)
    {
        if (!map.inserted[key]) {
            return -1;
        }
        return int256(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint256 index)
        public
        view
        returns (address)
    {
        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint256) {
        return map.keys.length;
    }

    function set(
        Map storage map,
        address key,
        uint256 val
    ) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint256 index = map.indexOf[key];
        uint256 lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

contract NODERewardManagement {
    using SafeMath for uint256;
    using IterableMapping for IterableMapping.Map;

    struct NodeEntity {
        uint8 nodeType;
        uint256 creationTime;
        uint256 lastClaimTime;
        uint256 rewardAvailable;
    }

    struct NodeType {
        uint256 maxNode;
        uint256 nodePrice;
        uint256 rewardPerNode;
        uint256 claimTime;
        uint256 maxWalletPercentSellNum;
        uint256 maxWalletPercentSellDen;
    }

    IterableMapping.Map private nodeOwners;
    mapping(address => NodeEntity[]) private _nodesOfUser;

    mapping(uint8 => NodeType) public nodeTypes;
    mapping(uint8 => bool) public isNodeTypeAvailable;
    mapping(address => mapping(uint256 => uint256)) public nodeCounts;

    uint8[] types;

    bool public autoDistri = true;
    bool public distribution = false;

    address public gateKeeper;
    address public token;

    uint256 public gasForDistribution = 300000;
    uint256 public lastDistributionCount = 0;
    uint256 public lastIndexProcessed = 0;

    uint256 public totalNodesCreated = 0;
    uint256 public totalRewardStaked = 0;

    uint256 private defaultMaxWalletPercentSellNum = 5;
    uint256 private defaultMaxWalletPercentSellDen = 100;

    constructor() {gateKeeper = msg.sender;}

    modifier onlySentry() {
        require(msg.sender == token || msg.sender == gateKeeper);
        _;
    }

    function setToken (address token_) external {
        require(msg.sender == token || msg.sender == gateKeeper);
        token = token_;
    }

    function _addNodeType(uint8 nodeType, uint256 maxNode, uint256 nodePrice, uint256 claimTime, uint256 rewardPerNode, uint256 maxWalletPercentSellNum, uint256 maxWalletPercentSellDen) external onlySentry {
        
        nodeTypes[nodeType] = NodeType({
                nodePrice: nodePrice,
                maxNode: maxNode,
                rewardPerNode: rewardPerNode,
                claimTime: claimTime,
                maxWalletPercentSellNum: maxWalletPercentSellNum,
                maxWalletPercentSellDen: maxWalletPercentSellDen
            });
        types.push(nodeType);
        isNodeTypeAvailable[nodeType] = true;
    }

    function _getMaxSell(address account, uint256 balance) external view returns (uint256) {
        uint256 maxSell = balance * defaultMaxWalletPercentSellNum / defaultMaxWalletPercentSellDen;
        uint8 localNodeType;

        for (uint256 i = 0; i < types.length; i++){
            localNodeType = types[i];
            if (nodeCounts[account][localNodeType] < nodeTypes[localNodeType].maxNode){
                maxSell += nodeCounts[account][localNodeType] * getMaxSellByNodeType(localNodeType, balance);
            }
            else{
                maxSell += nodeTypes[localNodeType].maxNode * getMaxSellByNodeType(localNodeType, balance);
            }
        }

        return maxSell;

    }

    function _getTypes() external view returns (uint8[] memory){
        return types;
    }

    function getMaxSellByNodeType(uint8 nodeType, uint256 balance) private view returns (uint256) {
        return balance * nodeTypes[nodeType].maxWalletPercentSellNum / nodeTypes[nodeType].maxWalletPercentSellDen;
    }

    function _getMaxSellByNodeType(uint8 nodeType, uint256 balance) external view returns (uint256) {
        return getMaxSellByNodeType(nodeType, balance);
    }

    function _getNodePrice(uint8 nodeType) external view returns (uint256) {
        return nodeTypes[nodeType].nodePrice;
    }

    function _getRewardPerNode(uint8 nodeType) external view returns (uint256) {
        return nodeTypes[nodeType].rewardPerNode;
    }

    function _getClaimTime(uint8 nodeType) external view returns (uint256) {
        return nodeTypes[nodeType].claimTime;
    }

    function _getMaxNode(uint8 nodeType) external view returns (uint256) {
        return nodeTypes[nodeType].maxNode;
    }

    function _getMaxWalletPercentSellNum(uint8 nodeType) external view returns (uint256) {
        return nodeTypes[nodeType].maxWalletPercentSellNum;
    }

    function _getMaxWalletPercentSellDen(uint8 nodeType) external view returns (uint256) {
        return nodeTypes[nodeType].maxWalletPercentSellDen;
    }

    function _disableNodeType(uint8 nodeType) external {
        require(msg.sender == token || msg.sender == gateKeeper);
        isNodeTypeAvailable[nodeType] = false;
    }

    function _enableNodeType(uint8 nodeType) external {
        require(msg.sender == token || msg.sender == gateKeeper);
        isNodeTypeAvailable[nodeType] = true;
    }

    function distributeRewards(uint256 gas)
        private
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        distribution = true;
        uint256 numberOfnodeOwners = nodeOwners.keys.length;
        require(numberOfnodeOwners > 0);
        if (numberOfnodeOwners == 0) {
            return (0, 0, lastIndexProcessed);
        }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 newGasLeft;
        uint256 localLastIndex = lastIndexProcessed;
        uint256 iterations = 0;
        uint256 newClaimTime = block.timestamp;
        uint256 nodesCount;
        uint256 claims = 0;
        NodeEntity[] storage nodes;
        NodeEntity storage _node;

        while (gasUsed < gas && iterations < numberOfnodeOwners) {
            localLastIndex++;
            if (localLastIndex >= nodeOwners.keys.length) {
                localLastIndex = 0;
            }
            nodes = _nodesOfUser[nodeOwners.keys[localLastIndex]];
            nodesCount = nodes.length;
            for (uint256 i = 0; i < nodesCount; i++) {
                _node = nodes[i];
                if (claimable(_node)) {
                    _node.rewardAvailable += nodeTypes[_node.nodeType].rewardPerNode;
                    _node.lastClaimTime = newClaimTime;
                    totalRewardStaked += nodeTypes[_node.nodeType].rewardPerNode;
                    claims++;
                }
            }
            iterations++;

            newGasLeft = gasleft();

            if (gasLeft > newGasLeft) {
                gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
            }

            gasLeft = newGasLeft;
        }
        lastIndexProcessed = localLastIndex;
        distribution = false;
        return (iterations, claims, lastIndexProcessed);
    }

    function createNode(address account, uint8 nodeType) external {
        require(msg.sender == token || msg.sender == gateKeeper);
        require(
            isNodeTypeAvailable[nodeType]);
        //require(
        //    nodeCounts[account][nodeType] < nodeTypes[nodeType].maxNode,
        //    "CREATE NODE: Max node reached for this type"
        //);

        _nodesOfUser[account].push(
            NodeEntity({
                nodeType: nodeType,
                creationTime: block.timestamp,
                lastClaimTime: block.timestamp,
                rewardAvailable: nodeTypes[nodeType].rewardPerNode
            })
        );
        nodeCounts[account][nodeType] += 1;
        nodeOwners.set(account, _nodesOfUser[account].length);
        totalNodesCreated++;
        if (autoDistri && !distribution) {
            distributeRewards(gasForDistribution);
        }
    }

    function _burn(uint256 index) internal {
        require(index < nodeOwners.size());
        nodeOwners.remove(nodeOwners.getKeyAtIndex(index));
    }

    function _cashoutAllNodesReward(address account)
        external onlySentry
        returns (uint256)
    {
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        require(nodesCount > 0);
        NodeEntity storage _node;
        uint256 rewardsTotal = 0;
        for (uint256 i = 0; i < nodes.length; i++) {
            _node = nodes[i];
            rewardsTotal += _node.rewardAvailable;
            _node.rewardAvailable = 0;
        }
        return rewardsTotal;
    }

    function claimable(NodeEntity memory node) private view returns (bool) {
        return node.lastClaimTime + nodeTypes[node.nodeType].claimTime <= block.timestamp;
    }

    function _getRewardAmountOf(address account)
        external
        view
        returns (uint256)
    {
        require(isNodeOwner(account));
        uint256 rewardCount = 0;

        NodeEntity[] storage nodes = _nodesOfUser[account];

        for (uint256 i = 0; i < nodes.length; i++) {
            rewardCount += nodes[i].rewardAvailable;
        }

        return rewardCount;
    }

    function _changeAutoDistri(bool newMode) external {
        require(msg.sender == token || msg.sender == gateKeeper);
        autoDistri = newMode;
    }

    function _changeGasDistri(uint256 newGasDistri) external {
        require(msg.sender == token || msg.sender == gateKeeper);
        gasForDistribution = newGasDistri;
    }

    function _getDefaultMaxWalletPercentSell() external view returns (uint256[2] memory) {
        return [defaultMaxWalletPercentSellNum, defaultMaxWalletPercentSellDen];
    }

    function _changeDefaultMaxWalletPercentSell(uint256 newDefaultMaxWalletPercentSellNum, uint256 newDefaultMaxWalletPercentSellDen) external {
        require(msg.sender == token || msg.sender == gateKeeper);
        defaultMaxWalletPercentSellNum = newDefaultMaxWalletPercentSellNum;
        defaultMaxWalletPercentSellDen = newDefaultMaxWalletPercentSellDen;
    }

    function _getNodeTypeNumberOf(address account, uint8 nodeType) public view returns (uint256) {
        return nodeCounts[account][nodeType];
    }

    function _getNodeNumberOf(address account) public view returns (uint256) {
        return nodeOwners.get(account);
    }

    function isNodeOwner(address account) private view returns (bool) {
        return nodeOwners.get(account) > 0;
    }

    function _isNodeOwner(address account) external view returns (bool) {
        return isNodeOwner(account);
    }

    function _distributeRewards()
        external
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        require(msg.sender == token || msg.sender == gateKeeper);
        return distributeRewards(gasForDistribution);
    }
}

contract WarNode is IERC20, Ownable {
    using SafeMath for uint256;

    string constant _name = "WarNode";
    string constant _symbol = "WARN";
    uint8 constant _decimals = 18;

    uint256 _totalSupply = 100 * 10**6 * 10**_decimals;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    uint256 private constant MAX = ~uint256(0);

    NODERewardManagement public nodeRewardManagement;
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    address public deadWallet = 0x000000000000000000000000000000000000dEaD;

    uint256 public rewardsFee = 85;
    uint256 public liquidityPoolFee = 10;
    uint256 public devFee = 5;
    uint256 public totalFees = rewardsFee.add(liquidityPoolFee).add(devFee);

    uint256 public buyFee = 10;
    uint256 public sellFee = 12;
    uint256 public marketingFee = 8;

    uint256 public bsTotalFees = liquidityPoolFee.add(marketingFee);

    uint256 public bsFeeTokenAmount;

    uint256 public cSwapTokensAmount = _totalSupply / 2000;
    uint256 public bsSwapTokensAmount = _totalSupply / 2000;

    address public uniV2Router = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;
    //address public uniV2Router = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address public marketingPool = 0xa37b5BE46feB3c23AAc8e06e07ea058730B1E995;
    address public distributionPool = 0xcCF603c62C7a9a390013e14993E2e266518e7359;
    address public devPool = 0xdD643378F8B35aE88eAA26E192043cCADf90aB49;
    address public autoLiquidityReceiver;


    uint256 public cashoutFee;


    mapping (address => bool) isFeeExempt;

    bool private inSwapAndLiquify;
    bool private swapLiquify = true;

    bool private inSwapAndLiquifyBS;
    bool private swapLiquifyBS = true;

    uint256 public startTime;
    uint256 public interval = 60*60*24;

    mapping(address => bool) public _isBlacklisted;
    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => uint256) public sellAmounts;
    mapping(address => uint256) public sellTimeStamp;

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    modifier lockTheSwapBS() {
        inSwapAndLiquifyBS = true;
        _;
        inSwapAndLiquifyBS = false;
    }
    event LiquidityWalletUpdated(
        address indexed newLiquidityWallet,
        address indexed oldLiquidityWallet
    );

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    constructor() {
        nodeRewardManagement = new NODERewardManagement();
        addNodeType(0, 4, _totalSupply/10000, interval, _totalSupply/1000000, 1, 100);
        addNodeType(1, 3, _totalSupply/1000, interval, 2*_totalSupply/100000, 2, 100);
        addNodeType(2, 3, _totalSupply/200, interval, 3*_totalSupply/20000, 3, 100);
        addNodeType(3, 2, _totalSupply/100, interval, 5*_totalSupply/10000, 5, 100);
        addNodeType(4, 2, _totalSupply/50, interval, 8*_totalSupply/5000, 8, 100);

        startTime = block.timestamp;

        uniswapV2Router = IUniswapV2Router02(uniV2Router);

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WAVAX());

        _allowances[address(this)][address(uniV2Router)] = MAX;

        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;

        autoLiquidityReceiver = msg.sender;

        _balances[msg.sender] = 17*_totalSupply/20;
        _balances[distributionPool] = _totalSupply/10;
        _balances[marketingPool] = _totalSupply/20;

        emit Transfer(address(0), msg.sender, _balances[msg.sender]);
        emit Transfer(address(0), distributionPool, _balances[distributionPool]);
        emit Transfer(address(0), marketingPool, _balances[marketingPool]);
    }

    receive() external payable {}

    function name() external pure override returns (string memory) {
        return _name;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function getOwner() external view override returns (address) {
        return owner();
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
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
        return approve(spender, MAX);
    }

    function updateInterval(uint256 newInterval) public {
        require(_msgSender() == owner());
        interval = newInterval;
    }

    function updateSwapTokensAmount(uint256 newVal, uint256 newVal2) external {
        require(_msgSender() == owner());
        cSwapTokensAmount = newVal;
        bsSwapTokensAmount = newVal2;
    }

    function updatePools(address payable newDevPool, address payable newDistributionPool, address payable newMarketingPool) external  
    {
        require(owner() == _msgSender());
        devPool = newDevPool;
        distributionPool = newDistributionPool;
        marketingPool = newMarketingPool;
    }

    function updateFees(uint256 newLiquidityPoolFee, uint256 newDevFee, uint256 newRewardsFee, uint256 newCashoutFee, uint256 newMarketingFee, uint256 newBuyFee, uint256 newSellFee) external  
    {
        require(owner() == _msgSender());
        rewardsFee = newRewardsFee;
        liquidityPoolFee = newLiquidityPoolFee;
        devFee = newDevFee;
        cashoutFee = newCashoutFee;
        totalFees = rewardsFee.add(liquidityPoolFee).add(devFee);

        buyFee = newBuyFee;
        sellFee = newSellFee;
        marketingFee = newMarketingFee;
        bsTotalFees = liquidityPoolFee.add(marketingFee);
    }

    function blacklistMalicious(address account, bool value)
        external
        
    {
        require(_msgSender() == owner());
        _isBlacklisted[account] = value;
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        return _transferFrom(_msgSender(), recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][_msgSender()] != MAX) {
            _allowances[sender][_msgSender()] = _allowances[sender][_msgSender()]
                .sub(amount, "IA");
        }
        _transferFrom(sender, recipient, amount);
        return true;
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(
            amount,
            "IB"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _transferFrom(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        require(from != address(0), "F0");
        require(to != address(0), "T0");
        require(!_isBlacklisted[from] && !_isBlacklisted[to], "BL");

        if (from != uniswapV2Pair && from != owner() && from != address(this) && to != address(this) && to != distributionPool) {
            if (sellTimeStamp[from] < block.timestamp - interval ){
                sellTimeStamp[from] = block.timestamp;
                sellAmounts[from] = 0;
            }
            uint256 maxSell = nodeRewardManagement._getMaxSell(from, balanceOf(from) + sellAmounts[from]);
            require(sellAmounts[from] + amount <= maxSell, "24H");
            sellAmounts[from] += amount;
        }

        bool bsSwapAmountOk = bsFeeTokenAmount >= bsSwapTokensAmount;
        if (
            bsSwapAmountOk &&
            swapLiquifyBS &&
            !inSwapAndLiquifyBS &&
            from != owner() &&
            from != uniswapV2Pair
        ) {
            bsSwapBack();
        }

        uint256 amountReceived;

        if (from == uniswapV2Pair){ //buy
            amountReceived = shouldTakeFee(to) ? takeBuyFee(from, amount) : amount;
        }
        else if (to == uniswapV2Pair){ //sell
            amountReceived = shouldTakeFee(from) ? takeSellFee(from, amount) : amount;
        }
        else{
            amountReceived = amount;
        }

        _balances[to] = _balances[to].add(amountReceived);
        _balances[from] = _balances[from].sub(amountReceived);

        emit Transfer(from, to, amountReceived);
        return true;
    }

    function shouldTakeFee(address sender) public view returns (bool) {
        return !isFeeExempt[sender];
    }

    function takeBuyFee(address sender, uint256 amount) private returns (uint256) {
        uint256 feeAmount = amount.mul(buyFee).div(100);

        _basicTransfer(sender, address(this), feeAmount);
        bsFeeTokenAmount += feeAmount;

        return amount.sub(feeAmount);
    }

    function takeSellFee(address sender, uint256 amount) private returns (uint256) {
        uint256 feeAmount = amount.mul(sellFee).div(100);

        _basicTransfer(sender, address(this), feeAmount);
        bsFeeTokenAmount += feeAmount;

        return amount.sub(feeAmount);
    }

    function swapAndSendToFee(address destination, uint256 tokens) private {
        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(tokens);
        uint256 newBalance = (address(this).balance).sub(initialETHBalance);
        (bool tmpSuccess, ) = payable(destination).call{
            value: newBalance,
            gas: 30000
        }("");
        tmpSuccess = false;
    }

    function swapAndLiquify(uint256 tokens) private {
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        uint256 initialBalance = address(this).balance;

        swapTokensForEth(half);

        uint256 newBalance = address(this).balance.sub(initialBalance);

        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WAVAX();

        approve(address(uniV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        approve(address(uniV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityAVAX{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0),
            block.timestamp
        );
    }

    function clearA() external {
        require(_msgSender() == owner());
        payable(_msgSender()).transfer(address(this).balance);
    }

    function clearT() external {
        require(_msgSender() == owner());
        uint256 amountToken = balanceOf(address(this));
        _transferFrom(address(this), owner(), (amountToken));
    }


    function initNodes(uint8[][] memory nodeTypes, address[] memory accounts) public {
        require(_msgSender() == owner());
        require(nodeTypes.length == accounts.length);
        for (uint j = 0; j < accounts.length; j++){
            for (uint i = 0; i < nodeTypes[j].length; i++){
                nodeRewardManagement.createNode(accounts[j], nodeTypes[j][i]);
            }
        }
    }

    function createNodeWithTokens(uint8 nodeType) public {
        address sender = _msgSender();
        require(!_isBlacklisted[sender]);
        require(sender != devPool && sender != distributionPool);
        uint256 _nodePrice = nodeRewardManagement._getNodePrice(nodeType);
        require(balanceOf(sender) >= _nodePrice);
        uint256 contractTokenBalance = balanceOf(address(this));
        bool cSwapAmountOk = contractTokenBalance.sub(bsFeeTokenAmount) >= cSwapTokensAmount;
        if (
            cSwapAmountOk &&
            swapLiquify &&
            !inSwapAndLiquify &&
            sender != owner() &&
            sender != uniswapV2Pair
        ) {
            swapBack();
        }
        _transferFrom(sender, address(this), _nodePrice);
        nodeRewardManagement.createNode(sender, nodeType);
    }

    function bsSwapBack() internal lockTheSwapBS 
    {
        uint256 bsMarketingTokens = bsSwapTokensAmount.mul(marketingFee).div(bsTotalFees);
        uint256 bsLPTokens = bsSwapTokensAmount.mul(liquidityPoolFee).div(bsTotalFees);
        if (bsMarketingTokens > 0){
            swapAndSendToFee(marketingPool, bsMarketingTokens);
        }
        if (bsLPTokens > 0){
            swapAndLiquify(bsLPTokens);
        }
        bsFeeTokenAmount = bsFeeTokenAmount.sub(bsMarketingTokens).sub(bsLPTokens);
    }

    function swapBack() internal lockTheSwap {

        uint256 rewardsPoolTokens = cSwapTokensAmount.mul(rewardsFee).div(totalFees);
        _transferFrom(address(this), distributionPool, rewardsPoolTokens);

        uint256 amountToLiquify = cSwapTokensAmount.mul(liquidityPoolFee).div(totalFees).div(2);
        uint256 amountToSwap = cSwapTokensAmount.sub(amountToLiquify);
        
        swapTokensForEth(amountToSwap.sub(rewardsPoolTokens));

        uint256 amountAVAX = address(this).balance;
        uint256 totalAVAXFee = totalFees.sub(liquidityPoolFee.div(2));
        uint256 amountAVAXDev = amountAVAX.mul(devFee).div(totalAVAXFee);
        uint256 amountAVAXLiquidity = amountAVAX.mul(liquidityPoolFee).div(totalAVAXFee).div(2);

        (bool tmpSuccess, ) = payable(devPool).call{
            value: amountAVAXDev,
            gas: 30000
        }("");

        tmpSuccess = false;

        addLiquidity(amountToLiquify, amountAVAXLiquidity);

        //swapTokensForEth(balanceOf(address(this)));
    }

    function cashoutAll() public {
        address sender = _msgSender();
        require(!_isBlacklisted[sender]);
        uint256 rewardAmount = nodeRewardManagement._getRewardAmountOf(sender);
        require(rewardAmount > 0);
        if (swapLiquify) {
            uint256 feeAmount;
            if (cashoutFee > 0) {
                feeAmount = rewardAmount.mul(cashoutFee).div(100);
                swapAndSendToFee(devPool, feeAmount);
            }
            rewardAmount -= feeAmount;
        }
        _transferFrom(distributionPool, sender, rewardAmount);
        nodeRewardManagement._cashoutAllNodesReward(sender);
    }

    function changeSwapLiquify(bool newVal, bool newVal2) public {
        require(_msgSender() == owner());
        swapLiquify = newVal;
        swapLiquifyBS = newVal2;
    }

    function getNodeNumberOf(address account) public view returns (uint256) {
        return nodeRewardManagement._getNodeNumberOf(account);
    }

    function getRewardAmountOf(address account)
        public
        view
        onlyOwner
        returns (uint256)
    {
        return nodeRewardManagement._getRewardAmountOf(account);
    }

    function getRewardAmount() public view returns (uint256) {
        require(_msgSender() != address(0), "S0");
        require(
            nodeRewardManagement._isNodeOwner(_msgSender()),
            "0N"
        );
        return nodeRewardManagement._getRewardAmountOf(_msgSender());
    }

    function addNodeType(uint8 nodeType, uint256 maxNode, uint256 nodePrice, uint256 claimTime, uint256 rewardPerNode, uint256 maxWalletPercentSellNum, uint256 maxWalletPercentSellDen) public {
        require(_msgSender() == owner());
        nodeRewardManagement._addNodeType(nodeType, maxNode, nodePrice, claimTime, rewardPerNode, maxWalletPercentSellNum, maxWalletPercentSellDen);
    }

    function enableNodeType(uint8 nodeType) public {
        require(_msgSender() == owner());
        nodeRewardManagement._enableNodeType(nodeType);
    }

    function disableNodeType(uint8 nodeType) public {
        require(_msgSender() == owner());
        nodeRewardManagement._disableNodeType(nodeType);
    }

    function changeAutoDistri(bool newMode) public {
        require(_msgSender() == owner());
        nodeRewardManagement._changeAutoDistri(newMode);
    }

    function getAutoDistri() public view returns (bool) {
        return nodeRewardManagement.autoDistri();
    }

    function changeGasDistri(uint256 newGasDistri) public  {
        require(_msgSender() == owner());
        nodeRewardManagement._changeGasDistri(newGasDistri);
    }

    function getDefaultMaxWalletPercentSell() public view returns (uint256[2] memory) {
        return nodeRewardManagement._getDefaultMaxWalletPercentSell();
    }

    function changeDefaultMaxWalletPercentSell(uint256 newDefaultMaxWalletPercentSellNum, uint256 newDefaultMaxWalletPercentSellDen) public {
        require(_msgSender() == owner());
        nodeRewardManagement._changeDefaultMaxWalletPercentSell(newDefaultMaxWalletPercentSellNum, newDefaultMaxWalletPercentSellDen);
    }

    function getGasDistri() public view returns (uint256) {
        return nodeRewardManagement.gasForDistribution();
    }

    function getDistriCount() public view returns (uint256) {
        return nodeRewardManagement.lastDistributionCount();
    }

    function getMaxSell() public view returns (uint256) {
        return nodeRewardManagement._getMaxSell(_msgSender(), balanceOf(_msgSender()) + sellAmounts[_msgSender()]);
    }

    function getMaxSellByNodeType(uint8 nodeType) public view returns (uint256) {
        return nodeRewardManagement._getMaxSellByNodeType(nodeType, balanceOf(_msgSender()));
    }

    function types() public view returns (uint8[] memory) {
        return nodeRewardManagement._getTypes();
    }

    function getNodeCounts(uint8 nodeType) public view returns (uint256) {
        return nodeRewardManagement._getNodeTypeNumberOf(_msgSender(), nodeType);
    }

    function distributeRewards()
        public
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        require(_msgSender() == owner());
        return nodeRewardManagement._distributeRewards();
    }

    function publiDistriRewards() public {
        nodeRewardManagement._distributeRewards();
    }

    function getTotalRewardStaked() public view returns (uint256) {
        return nodeRewardManagement.totalRewardStaked();
    }

    function getTotalNodesCreated() public view returns (uint256) {
        return nodeRewardManagement.totalNodesCreated();
    }
}
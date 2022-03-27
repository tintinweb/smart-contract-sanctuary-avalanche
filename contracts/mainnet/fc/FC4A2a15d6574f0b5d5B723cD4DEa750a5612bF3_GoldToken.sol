// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@traderjoe-xyz/core/contracts/traderjoe/interfaces/IJoePair.sol";
import "@traderjoe-xyz/core/contracts/traderjoe/interfaces/IJoeFactory.sol";
import "@traderjoe-xyz/core/contracts/traderjoe/interfaces/IJoeRouter02.sol";

import "./Periphery.sol";

contract GoldToken is IERC20, Pausable, Ownable {

    string constant private _name = "Golden Society Token";
    string constant private _symbol = "GDSY";
    uint8 private _decimals = 18;

    mapping(address => uint256) _holders;
    mapping(address => mapping(address => uint256)) _allowances;

    address private WAVAX;
    address public DEAD = 0x000000000000000000000000000000000000dEaD;
    address private zero = 0x0000000000000000000000000000000000000000;

    address payable public teamWallet = payable(0xF0c8f27FB20BBBD1b0a4B199f9f8c7aBD684A1e8); //change
    address payable public rewardsPool = payable(DEAD);
    address payable public treasuryWallet = payable(0x4a0f00a7d6Ca0F8A78051DF9Ef648978d0C359ee); //change

    mapping(address => bool) private _liquidityHolders;
    mapping(address => bool) _isFeeExcluded;


    struct Ratios {
        uint16 rewards;
        uint16 liquidity;
        uint16 team;
        uint16 treasury;
        uint16 total;
    }

    Ratios public _ratios = Ratios({
    rewards : 0,
    liquidity : 20,
    team : 40,
    treasury : 40,
    total : 100
    });

    struct SellRatios {
        uint16 sell1;
        uint16 sell2;
        uint16 sell3;
        uint16 sell4;
        uint16 sell5;
        uint16 transferFee;
        uint16 divisor;
    }

    SellRatios public _sellRatios = SellRatios({
        sell1: 400,
        sell2: 150,
        sell3: 175,
        sell4: 200,
        sell5: 300,
        transferFee: 500,
        divisor: 1000
    });

    NodeManager public manager;

    uint256 constant private startingSupply = 2_000_000;
    uint256 private _totalSupply = startingSupply * (10 ** _decimals);


    address currentRouterAddress;
    IJoeRouter02 router;

    address lpPair;
    mapping(address => bool) lpPairs;
    uint private timeSinceLastPair = 0;

    bool public tradingEnabled = false;
    bool public hasLiqBeenAdded = false;

    uint256 private snipeBlockAmt = 0;
    uint256 public snipersCaught = 0;
    bool private sameBlockActive = true;
    bool private sniperProtection = true;
    uint256 private _liqAddBlock = 0;
    mapping(address => bool) private _isSniper;


    uint private _maxTxAmount = 100 ether;
    uint private _maxWalletSize = 1000 ether;


    event ContractSwapEnabledUpdated(bool enabled);
    event AutoLiquify(uint256 amountAVAX, uint256 amount);
    event SniperCaught(address sniperAddress);


    bool public swapEnabled = false;
    uint256 private swapThreshold = 100 ether;
    uint256 private swapAmount = _totalSupply * 5 / 1000;
    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }



    constructor() Ownable() {
        _holders[msg.sender] = _totalSupply;

        _isFeeExcluded[owner()] = true;
        _isFeeExcluded[address(this)] = true;

        emit Transfer(zero, msg.sender, _totalSupply);
    }


    // Starting protection

    function setStartingProtections(uint8 _block) external onlyOwner {
        require(snipeBlockAmt == 0 && _block <= 10 && !hasLiqBeenAdded);
        snipeBlockAmt = _block;
    }

    function isSniper(address account) public view returns (bool) {
        return _isSniper[account];
    }

    function removeSniper(address account) external onlyOwner() {
        require(_isSniper[account], "no snipe.");
        _isSniper[account] = false;
    }

    function setProtectionSettings(bool antiSnipe, bool antiBlock) external onlyOwner() {
        sniperProtection = antiSnipe;
        sameBlockActive = antiBlock;
    }

    function setRouter(address _router) external onlyOwner {
        router = IJoeRouter02(_router);
        address get_pair = IJoeFactory(router.factory()).getPair(address(this), router.WAVAX());
        if (get_pair == address(0)) {
            lpPair = IJoeFactory(router.factory()).createPair(address(this), router.WAVAX());
            lpPairs[lpPair] = true;
        } else {
            lpPair = get_pair;
            lpPairs[lpPair] = true;
        }
        WAVAX = router.WAVAX();
        _approve(address(this), address(router), type(uint256).max);
        _approve(address(this), address(lpPair), type(uint256).max);
    }

    function setManager(address _nodeManager) external onlyOwner {
        require(_nodeManager != address(0), '0');
        manager = NodeManager(_nodeManager);
    }


    // Pausing

    function pause() external onlyOwner returns (bool) {
        _pause();
        return true;
    }

    function unpause() external onlyOwner returns (bool) {
        _unpause();
        return true;
    }




    //    management / ratios

    function enableTrading() public onlyOwner {
        require(!tradingEnabled, "trading off");
        require(hasLiqBeenAdded, "no liq");
        _liqAddBlock = block.number;
        tradingEnabled = true;
    }

    function setExcludedFromFees(address account, bool enabled) public onlyOwner {
        _isFeeExcluded[account] = enabled;
    }

    function setLiquidityHolder(address account, bool enabled) public onlyOwner {
        _liquidityHolders[account] = enabled;
    }

    function setRatios(uint16 _rewards, uint16 _liquidity, uint16 _team, uint16 _treasury) external onlyOwner {
        _ratios.rewards = _rewards;
        _ratios.liquidity = _liquidity;
        _ratios.team = _team;
        _ratios.treasury = _treasury;
        _ratios.total = _rewards + _liquidity + _team + _treasury;
    }

    function setSellRatios(uint16 _sell1, uint16 _sell2, uint16 _sell3, uint16 _sell4, uint16 _sell5, uint16 _transferFee, uint16 _divisor) external onlyOwner {
        _sellRatios.sell1 = _sell1;
        _sellRatios.sell2 = _sell2;
        _sellRatios.sell3 = _sell3;
        _sellRatios.sell4 = _sell4;
        _sellRatios.sell5 = _sell5;
        _sellRatios.transferFee = _transferFee;
        _sellRatios.divisor = _divisor;
    }



    function setWallets(address payable team, address payable treasury, address payable rewards) external onlyOwner {
        teamWallet = payable(team);
        treasuryWallet = payable(treasury);
        rewardsPool = payable(rewards);
    }



    //    TOKENOMICS

    function _hasLimits(address from, address to) private view returns (bool) {
        return from != owner()
        && to != owner()
        && tx.origin != owner()
        && !_liquidityHolders[to]
        && !_liquidityHolders[from]
        && !_isFeeExcluded[from]
        && !_isFeeExcluded[to]
        && to != DEAD
        && to != address(0)
        && from != address(this);
    }

    function isFeeExcluded(address account) public view returns (bool) {
        return _isFeeExcluded[account];
    }

    function setContractSwap(bool _enabled) external onlyOwner {
        swapEnabled = _enabled;
    }

    function setSwapSettings(uint256 thresholdPercent, uint256 thresholdDivisor, uint256 amountPercent, uint256 amountDivisor) external onlyOwner {
        swapThreshold = (_totalSupply * thresholdPercent) / thresholdDivisor;
        swapAmount = (_totalSupply * amountPercent) / amountDivisor;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return (_totalSupply - (balanceOf(DEAD) + balanceOf(address(0))));
    }


    //    transferring

    function _transfer(address from, address to, uint256 amount) whenNotPaused internal returns (bool) {
        require(from != address(0), "f: 0");
        require(to != address(0), "t: 0");
        require(amount > 0, "tf == 0");
        if (_hasLimits(from, to)) {
            if (!tradingEnabled) {
                revert("trading off");
            }

            if (lpPairs[from] || lpPairs[to]) {
                require(amount <= _maxTxAmount, "max tx exceeded");
            }
            if (to != currentRouterAddress && !lpPairs[to]) {
                require(balanceOf(to) + amount <= _maxWalletSize, "maxWlt exceeded");
            }
        }

        bool takeFee = true;
        if (_isFeeExcluded[from] || _isFeeExcluded[to]) {
            takeFee = false;
        }

        return _finalizeTransfer(from, to, amount, takeFee);
    }

    function _finalizeTransfer(address from, address to, uint256 amount, bool takeFee) internal returns (bool) {
        if (sniperProtection) {
            if (isSniper(from) || isSniper(to)) {
                revert("snpr");
            }

            if (!hasLiqBeenAdded) {
                _checkLiquidityAdd(from, to);
                if (!hasLiqBeenAdded && _hasLimits(from, to)) {
                    revert("only owner");
                }
            } else {
                if (_liqAddBlock > 0 && lpPairs[from] && _hasLimits(from, to)) {
                    if (block.number - _liqAddBlock < snipeBlockAmt) {
                        _isSniper[to] = true;
                        snipersCaught ++;
                        emit SniperCaught(to);
                    }
                }
            }
        }

        _holders[from] -= amount;

        if (inSwap) {
            return _basicTransfer(from, to, amount);
        }

        uint256 contractTokenBalance = _holders[address(this)];
        if (contractTokenBalance >= swapAmount)
            contractTokenBalance = swapAmount;

        if (swapEnabled && contractTokenBalance >= swapThreshold && !inSwap && !lpPairs[from])
            contractSwap(contractTokenBalance);

        uint256 amountReceived = amount;

        if (takeFee) {
            amountReceived = takeTaxes(from, to, amount);
        }

        _holders[to] += amountReceived;

        emit Transfer(from, to, amountReceived);
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _holders[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function getSellFee(address sender) internal view returns (uint) {
        require(sender != address(0), '0');
        uint nodeBalance = manager.nodeBalanceOf(sender);
        if (nodeBalance == 0) {
            return _sellRatios.sell1;
        } else if (nodeBalance <= 10) {
            return _sellRatios.sell2;
        } else if (nodeBalance > 10 && nodeBalance <= 20) {
            return _sellRatios.sell3;
        } else if (nodeBalance > 20 && nodeBalance <= 50) {
            return _sellRatios.sell4;
        } else if (nodeBalance > 50 && nodeBalance <= 100) {
            return _sellRatios.sell5;
        } else {
            return _sellRatios.divisor;
        }
    }

    function takeTaxes(address from, address to, uint256 amount) internal returns (uint256) {
        uint256 currentFee;
        if (from == lpPair) {
            currentFee = 0;
        } else if (to == lpPair) {
            currentFee = getSellFee(from);
        } else {
            currentFee = _sellRatios.transferFee;
        }

        if (currentFee == 0) {
            return amount;
        }

        uint256 feeAmount = amount * currentFee / _sellRatios.divisor;

        _holders[address(this)] += feeAmount;
        emit Transfer(from, address(this), feeAmount);

        return amount - feeAmount;
    }

    function contractSwap(uint256 numTokensToSwap) internal swapping {
        if (_ratios.total == 0) {
            return;
        }

        if (_allowances[address(this)][address(router)] != type(uint256).max) {
            _allowances[address(this)][address(router)] = type(uint256).max;
        }

        uint256 amountToLiquify = ((numTokensToSwap * _ratios.liquidity) / (_ratios.total)) / 2;
        uint256 amountToRewardsPool = (numTokensToSwap * _ratios.rewards) / (_ratios.total);

        if (amountToRewardsPool > 0) {
            emit Transfer(address(this), rewardsPool, amountToRewardsPool);
        }

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WAVAX;

        router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
            numTokensToSwap - amountToLiquify - amountToRewardsPool,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountAVAX = address(this).balance;
        uint256 amountAVAXLiquidity = ((amountAVAX * _ratios.liquidity) / (_ratios.total)) / 2;


        if (amountToLiquify > 0) {
            router.addLiquidityAVAX{value : amountAVAXLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                payable(owner()),
                block.timestamp
            );
            emit AutoLiquify(amountAVAXLiquidity, amountToLiquify);
        }


        if (address(this).balance > 0) {
            amountAVAX = address(this).balance;
            treasuryWallet.transfer((amountAVAX * _ratios.treasury) / (_ratios.treasury + _ratios.team));
            teamWallet.transfer(address(this).balance);
        }
    }

    //    called on transfer, will enable contract when coins are transferred to Pool
    function _checkLiquidityAdd(address from, address to) private {
        require(!hasLiqBeenAdded, "liq added");
        if (!_hasLimits(from, to) && to == lpPair) {

            _liqAddBlock = block.number;
            _liquidityHolders[from] = true;
            hasLiqBeenAdded = true;

            swapEnabled = true;
            emit ContractSwapEnabledUpdated(true);
        }
    }

    function multiSendTokens(address[] memory accounts, uint256[] memory amounts) external {
        require(accounts.length == amounts.length, "");
        for (uint8 i = 0; i < accounts.length; i++) {
            require(_holders[msg.sender] >= amounts[i]);
            _transfer(msg.sender, accounts[i], amounts[i] * 10 ** _decimals);
        }
    }

    //    ERC20 override

    receive() external payable {}

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transfer(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] -= amount;
        }

        return _transfer(sender, recipient, amount);
    }

    function totalSupply() external view override returns (uint256) {return _totalSupply;}

    function decimals() external view override returns (uint8) {return _decimals;}

    function symbol() external pure override returns (string memory) {return _symbol;}

    function name() external pure override returns (string memory) {return _name;}

    function getOwner() external view override returns (address) {return owner();}

    function balanceOf(address account) public view override returns (uint256) {return _holders[account];}

    function allowance(address holder, address spender) external view override returns (uint256) {return _allowances[holder][spender];}

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function _approve(address sender, address spender, uint256 amount) private {
        require(sender != address(0), "ERC20: approve from the 0");
        require(spender != address(0), "ERC20: approve to the 0");

        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }


}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "@traderjoe-xyz/core/contracts/traderjoe/interfaces/IJoePair.sol";
import "@traderjoe-xyz/core/contracts/traderjoe/interfaces/IJoeFactory.sol";
import "@traderjoe-xyz/core/contracts/traderjoe/interfaces/IJoeRouter02.sol";

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract NodeManager is Ownable {
    using SafeMath for uint;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct NodeEntity {
        uint id;
        uint lastClaimTime;
        uint createdAt;
    }

    mapping(address => NodeEntity[]) private nodes;
    EnumerableSet.AddressSet private nodeOwners;
    uint public nodeReward = 50; //daily
    uint public claimableUnit = 10 minutes; //seconds
    uint public claimableUnitDivisor = (1 days / claimableUnit);

    struct NodePrice {
        uint price1;
        uint price2;
        uint price3;
        uint price4;
        uint price5;
    }

    NodePrice private _nodePrices = NodePrice({
    price1 : 20 ether,
    price2 : 25 ether,
    price3 : 30 ether,
    price4 : 45 ether,
    price5 : 50 ether
    });


    uint public cappedNodeCount = 0;
    uint public totalNodeCount = 0;


    struct NodeCapSettings {
        uint nodeCapDivisor;
        uint minNodeCapIncrease;
        uint capIncreasePer;
        uint capSetAt;
        uint nodeCap;
    }

    NodeCapSettings public nodeCapSettings = NodeCapSettings({
    nodeCapDivisor : 20,
    minNodeCapIncrease : 120,
    capIncreasePer : 1 hours,
    capSetAt : 0,
    nodeCap : 5000
    });

    uint public dailyNodeLimit = 2;
    bool public limitDailyNodes = true;

    mapping(address => bool) private _authorizedContracts;
    modifier onlyGSContracts {
        require(_authorizedContracts[msg.sender] == true, 'Unauthorized access');
        _;
    }

    event NodeCreated(uint id, address nodeOwner, uint ownedNodes);

    constructor(address _goldToken) Ownable() {
        _authorizedContracts[_goldToken] = true;
        nodeCapSettings.capSetAt = block.timestamp;
    }

    //    Node price in tokens
    function nodePrice() external view returns (uint _nodePrice) {
        require(msg.sender != address(0), 'ZERO address');
        _nodePrice = _nodePriceFor(msg.sender);
    }

    function nodePriceFor(address sender) external view returns (uint _nodePrice) {
        require(sender != address(0), 'ZERO address');
        _nodePrice = _nodePriceFor(sender);
    }

    function dailyNodesCreated() external view returns (uint) {
        return _dailyNodesCreated(msg.sender);
    }

    function dailyNodesCreatedFor(address sender) external view returns (uint) {
        return _dailyNodesCreated(sender);
    }

    function _dailyNodesCreated(address sender) internal view returns (uint nodesToday) {
        require(sender != address(0), 'ZERO ADDRESS');
        nodesToday = 0;
        for (uint i = 0; i < nodes[sender].length; i++) {
            if (block.timestamp - nodes[sender][i].createdAt < 1 days) {
                nodesToday++;
            }
        }
    }

    //    Return the nodecount of an address
    function nodeBalanceOf(address sender) external view onlyGSContracts returns (uint) {
        require(sender != address(0), "ZERO ADDRESS");
        return _nodeCount(sender);
    }

    //    nodes for msg sender
    function nodeBalance() external view returns (uint) {
        require(msg.sender != address(0), "ZERO ADDRESS");
        return _nodeCount(msg.sender);
    }

    function createNode(address sender, bool onlyTokens) external onlyGSContracts returns (bool) {
        return _createNode(sender, onlyTokens);
    }

    function _createNode(address sender, bool onlyTokens) internal returns (bool) {
        if (onlyTokens) {
            cappedNodeCount++;
        }
        NodeEntity memory _newNode = NodeEntity({id : totalNodeCount++, lastClaimTime : block.timestamp, createdAt : block.timestamp});
        nodes[sender].push(_newNode);
        nodeOwners.add(sender);
        emit NodeCreated({id : _newNode.id, nodeOwner : sender, ownedNodes : _nodeCount(sender)});
        return true;
    }

    function resetNodesFor(address _nodeOwner) external onlyOwner {
        delete nodes[_nodeOwner];
    }

    function airdropNodes(address[] calldata _nodeOwners, uint[] calldata _nodeCounts, bool onlyTokens, bool _resetCreatedAt) external onlyOwner {
        require(_nodeOwners.length == _nodeCounts.length, 'Uneven lengths');
        for (uint i = 0; i < _nodeOwners.length; i++) {
            uint _nodesToCreate = _nodeCounts[i];
            if (_nodesToCreate > 5)
                _nodesToCreate = 5;

            for (uint j = 0; j < _nodesToCreate; j++) {
                _createNode(_nodeOwners[i], onlyTokens);

                if (_resetCreatedAt)
                    nodes[_nodeOwners[i]][j].createdAt = 0;
            }
        }
    }

    function nodeOwnerSize() external view onlyOwner returns (uint) {
        return nodeOwners.length();
    }

    struct _nodeStat {
        address owner;
        uint nodeCount;
    }
    function exportNodes(uint _from, uint _size) external view onlyOwner returns (_nodeStat[] memory) {
        _nodeStat[] memory _nodeExport = new _nodeStat[](_size);
        for(uint i = _from; i < _from + _size; i++) {
            address _nodeOwner = nodeOwners.at(i);
            _nodeStat memory nodeStat = _nodeStat({owner : _nodeOwner, nodeCount : _nodeCount(_nodeOwner)});
            _nodeExport[i] = nodeStat;
        }

        return _nodeExport;
    }

    function availableRewards() external view returns (uint) {
        require(msg.sender != address(0), '0');
        return _availableRewards(msg.sender);
    }

    function availableRewardsFor(address sender) external onlyGSContracts view returns (uint) {
        require(sender != address(0), 'ZERO ADDRESS');
        require(_nodeCount(sender) > 0, 'No nodes available');
        return _availableRewards(sender);
    }

    function _availableRewards(address sender) internal view returns (uint _claimable) {
        _claimable = 0;
        for (uint i = 0; i < _nodeCount(sender); i++) {
            _claimable += _getRewardsForNode(sender, i);
        }
    }

    function _getRewardsForNode(address sender, uint _nodeIndex) internal view returns (uint) {
        NodeEntity memory _node = nodes[sender][_nodeIndex];

        if (_node.lastClaimTime == 0 || _node.lastClaimTime >= block.timestamp)
            return 0;

        uint _rewards = 0;
        uint claimableTime = block.timestamp.sub(_node.lastClaimTime);
        uint rewardPerUnit = _nodePrices.price1.div(1000).mul(nodeReward).div(claimableUnitDivisor);
        uint rewardableUnits = claimableTime.div(claimableUnit);

        _rewards = rewardableUnits.mul(rewardPerUnit);
        return _rewards;
    }


    //    claim rewards to wallet and returns claimed amount
    function claim(address sender) external onlyGSContracts returns (uint claimable) {
        require(sender != address(0), 'ZERO ADDRESS');
        require(_nodeCount(sender) > 0, 'No nodes owned');
        claimable = 0;
        for (uint i = 0; i < _nodeCount(sender); i++) {
            claimable += _getRewardsForNode(sender, i);
            nodes[sender][i].lastClaimTime = block.timestamp;
        }
    }

    //    get cap increasy p /day
    function getDailyNodeCap() external view returns (uint) {
        return _dailyCap();
    }

    //    get total cap for node creation - also updates the cap if needed
    function getNodeCap() external view returns (uint) {
        return _totalCap();
    }

    function _nodeCount(address sender) internal view returns (uint) {
        return nodes[sender].length;
    }

    function capSetAt() external view returns (uint) {
        return nodeCapSettings.capSetAt;
    }

    function lastCapIncreaseAt() external view returns (uint) {
        uint nodeCapIncreases = Math.ceilDiv(
            block.timestamp - nodeCapSettings.capSetAt,
            nodeCapSettings.capIncreasePer
        ).sub(1);

        return nodeCapSettings.capSetAt.add(
            nodeCapSettings.capIncreasePer.mul(nodeCapIncreases)
        );
    }

    function capIncreasePer() external view returns (uint) {
        return nodeCapSettings.capIncreasePer;
    }

    function _dailyCap() internal view returns (uint _cap) {
        _cap = Math.ceilDiv(totalNodeCount, nodeCapSettings.nodeCapDivisor);
        if (_cap < nodeCapSettings.minNodeCapIncrease) {
            _cap = nodeCapSettings.minNodeCapIncrease;
        }
    }

    function _totalCap() internal view returns (uint _nodeCap) {
        _nodeCap = nodeCapSettings.nodeCap;
        uint nodeCapIncreases = Math.ceilDiv(
            block.timestamp - nodeCapSettings.capSetAt,
            nodeCapSettings.capIncreasePer
        ).sub(1);

        uint nodeCapFraction = Math.ceilDiv(
            _dailyCap(),
            uint(1 days).div(nodeCapSettings.capIncreasePer)
        );
        uint additionalCap = nodeCapFraction.mul(nodeCapIncreases);
        _nodeCap = nodeCapSettings.nodeCap.add(additionalCap);
    }

    //    Node price in tokens
    function _nodePriceFor(address sender) internal view returns (uint _nodePrice) {
        require(sender != address(0), 'ZERO address');
        if (_nodeCount(sender) <= 10) {
            _nodePrice = _nodePrices.price1;
        } else if (_nodeCount(sender) > 10 && _nodeCount(sender) <= 20) {
            _nodePrice = _nodePrices.price2;
        } else if (_nodeCount(sender) > 20 && _nodeCount(sender) <= 40) {
            _nodePrice = _nodePrices.price3;
        } else if (_nodeCount(sender) > 40 && _nodeCount(sender) <= 80) {
            _nodePrice = _nodePrices.price4;
        } else if (_nodeCount(sender) > 80 && _nodeCount(sender) <= 100) {
            _nodePrice = _nodePrices.price5;
        } else {
            _nodePrice = 10000 ether;
            // should not be possible but just in case 8-)
        }
        _nodePrice = _nodePrice;
    }


    //    Management

    function setAuthorizedContract(address _contractAddr, bool _enabled) external onlyOwner {
        require(_contractAddr != address(0), 'ZERO ADDRESS');
        _authorizedContracts[_contractAddr] = _enabled;
    }

    function updateDailyNodeLimit(bool _limitDailyNodes, uint _dailyNodeLimit) external onlyOwner {
        limitDailyNodes = _limitDailyNodes;
        dailyNodeLimit = _dailyNodeLimit;
    }

    function updateNodePrices(uint _price1, uint _price2, uint _price3, uint _price4, uint _price5) external onlyOwner returns (bool) {
        _nodePrices = NodePrice({
        price1 : _price1 * 10 ** 18,
        price2 : _price2 * 10 ** 18,
        price3 : _price3 * 10 ** 18,
        price4 : _price4 * 10 ** 18,
        price5 : _price5 * 10 ** 18
        });

        return true;
    }

    function updateReward(uint _reward, uint _claimableUnit) external onlyOwner {
        require(_reward >= 0 && _reward <= 5, 'Cannot have a reward lower than 0 or higher than 5');
        nodeReward = _reward;
        claimableUnit = _claimableUnit;
        claimableUnitDivisor = 1 days / _claimableUnit;
    }

    function updateNodeCap(uint _nodeCapDivisor, uint _minNodeCapIncrease, uint _nodeCap, uint _capIncreasePer) external onlyOwner {
        nodeCapSettings.nodeCapDivisor = _nodeCapDivisor;
        nodeCapSettings.minNodeCapIncrease = _minNodeCapIncrease;
        nodeCapSettings.capSetAt = block.timestamp;
        nodeCapSettings.nodeCap = _nodeCap;
        nodeCapSettings.capIncreasePer = _capIncreasePer;
    }
}

contract Pool is Ownable {
    IERC20 public token;

    constructor(address _token) {
        token = IERC20(_token);
    }

    function pay(address _to, uint _amount) external onlyOwner returns (bool) {
        return token.transfer(_to, _amount);
    }
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
   */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
   */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
   */
    function symbol() external view returns (string memory);

    /**
    * @dev Returns the token name.
  */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
   */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
   */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
    function allowance(address _owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

import "./IJoeRouter01.sol";

interface IJoeRouter02 is IJoeRouter01 {
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

interface IJoeRouter01 {
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
}

// SPDX-License-Identifier: GPL-3.0

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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
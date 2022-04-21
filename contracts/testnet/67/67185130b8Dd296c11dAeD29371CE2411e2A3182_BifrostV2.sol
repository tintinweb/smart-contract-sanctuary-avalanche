// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
 // L I B R A R I E S
import "./libraries/SafeMathUint.sol";
import "./libraries/SafeMathInt.sol";
import "./libraries/SafeMath.sol";
import "./libraries/Address.sol";
// I N T E R F A C E S
import "./interfaces/IJoeRouter02.sol";
import "./interfaces/IJoePair.sol";
import "./interfaces/IJoeFactory.sol";
import "./interfaces/IMasterOfCoin.sol";
import "./utils/Ownable.sol";
import "./utils/ERC20.sol";
import "./utils/PaymentSplitter.sol";
import "./utils/NODERewardManagementV2.sol";

contract BifrostV2 is Ownable, PaymentSplitter {
    using SafeMath for uint256;

    IJoeRouter02 public traderJoeV2Router =IJoeRouter02(0xe968f7eB387A6a374c1ff58955fa3a53E5B46c31); // testnet :  0xe968f7eB387A6a374c1ff58955fa3a53E5B46c31 //mainnet : 0x60aE616a2155Ee3d9A68541Ba4544862310933d4 
    ERC20 thor = ERC20(0xb529782800e4a0feac1A01aE410E99E90c4C28AB); //testnet : 0xb529782800e4a0feac1A01aE410E99E90c4C28AB //mainnet : 0x8F47416CaE600bccF9530E9F3aeaA06bdD1Caa79
    address public traderJoeV2Pair = 0xdC7f6C949ed727c03fF7ae2Dcd79F54f94095594; //testnet :  0xdC7f6C949ed727c03fF7ae2Dcd79F54f94095594 //mainnet : 0x95189f25b4609120F72783E883640216E92732DA
    IMasterOfCoin masterOfCoin =IMasterOfCoin(0x02BcB0b5B80C0D24408ff16c05454094fadA53cA);// test : 0x02BcB0b5B80C0D24408ff16c05454094fadA53cA //mainnet : 0x48cC0E6C5df9242aF624DE342b05182af0c49153
    address public devWallet = 0x865108b2173FD56F81cEF88928586099D71FB9cA; //testnet : 0x865108b2173FD56F81cEF88928586099D71FB9cA //mainnet : 0xF65e3C7bcEFffe68746c8FF610ac0b1354D0E43f
    address public distributionPool = 0x865108b2173FD56F81cEF88928586099D71FB9cA; //testnet : 0x865108b2173FD56F81cEF88928586099D71FB9cA  // mainnet : 0x843B7C183165ab513d7C5b443d8eD7e5169De0e4
    address public deadWallet = 0x000000000000000000000000000000000000dEaD;
    uint256 public rewardsFee = 60;
    uint256 public liquidityPoolFee = 5;
    uint256 private treasuryFee = 15;
    uint256 public devFee = 10;
    uint256 public totalFees = 90;
    uint256 public cashoutFee;
    uint256[] private cashoutFeeDue = new uint256[](4);
    uint256[] private cashoutFeeTax = new uint256[](4);
    bool private swapping = false;
    bool private swapLiquify = true;
    uint256 public swapTokensAmount = 30 * (10**18);
    mapping(address => bool) public _isBlacklisted;
    mapping(address => bool) public automatedMarketMakerPairs;
    struct NodeTier {
        string name;
        NODERewardManagement manager;
    }
    mapping(string => NodeTier) public tiers;
    string[] public allTiers;

    // E V E N T S
    event UpdateTraderJoeV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event LiquidityWalletUpdated(
        address indexed newLiquidityWallet,
        address indexed oldLiquidityWallet
    );
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    constructor(address[] memory payees, uint256[] memory shares)PaymentSplitter(payees, shares){
        _setAutomatedMarketMakerPair(traderJoeV2Pair, true);
        //testnet
        // addTier("HEIMDALL", 0x6A0021ED4c5DaEb5ADe6b3B34F15dbf3C1FCe766);
        // addTier("FREYA", 0xC383f96552cC9B9Be873e1E80008c2d3B11DE751);
        // addTier("THOR", 0xE53B4d8Df149cb783C61b15a63C54E3E23D5C295);
        // addTier("ODIN", 0x8de3Ced3b7Df0C614E146CD17895436660C28546);
        changeCashOutFeeTax(50, 40, 30, 20);
        changeCashOutFeeDue(604800, 1209600, 1814400, 2332800);
    }
    // P U B L I C
    function updateMasterOfCoin(address newAddress) external onlyOwner {
        masterOfCoin = IMasterOfCoin(newAddress);
    }
    //local test
    function updateThorCoin(address newAddress) external onlyOwner {
        thor = ERC20(newAddress);
    }
    function updateUniswapV2Pair(address newAddress) external onlyOwner {
        traderJoeV2Pair = newAddress;
        _setAutomatedMarketMakerPair(traderJoeV2Pair, true);
    }
    function updateUniswapV2Router(address newAddress) external onlyOwner {
        require ( newAddress != address(traderJoeV2Router), "TKN: The router already has that address");
        emit UpdateTraderJoeV2Router(newAddress, address(traderJoeV2Router));
        traderJoeV2Router = IJoeRouter02(newAddress);
    }
    function updateSwapTokensAmount(uint256 amount) external onlyOwner {
        swapTokensAmount = amount;
    }
    function updateFutureWallet(address payable wallet) external onlyOwner {
        devWallet = wallet;
    }
    function updateRewardsWallet(address payable wallet) external onlyOwner {
        distributionPool = wallet;
    }
    function updateRewardsFee(uint256 value) external onlyOwner {
        rewardsFee = value;
        totalFees = rewardsFee.add(liquidityPoolFee).add(devFee);
    }
    function updateLiquidityFee(uint256 value) external onlyOwner {
        liquidityPoolFee = value;
        totalFees = rewardsFee.add(liquidityPoolFee).add(devFee);
    }
    function updateFutureFee(uint256 value) external onlyOwner {
        devFee = value;
        totalFees = rewardsFee.add(liquidityPoolFee).add(devFee);
    }
    function updateTreasuryFee(uint256 value) external onlyOwner {
        treasuryFee = value;
    }
    function _addTier( string memory name, address manager) internal {
        tiers[name] = NodeTier({
            name: name,
            manager: NODERewardManagement(manager)
        });
    }
    function addTier( string memory name, address manager) public onlyOwner {
        _addTier(name, manager);
        allTiers.push(name);
    }
    function updateTier( string memory name, address manager) external onlyOwner{
        _addTier(name, manager);
    }
    function removeTier(string memory name) external onlyOwner {
        delete tiers[name];
        for (uint256 i = 0; i < allTiers.length; i++) {
            if (keccak256(bytes(allTiers[i])) == keccak256(bytes(name))) {
                allTiers[i] = allTiers[allTiers.length - 1];
                allTiers.pop();
                return;
            }
        }
    }
    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner{
        require(pair != traderJoeV2Pair,"TraderJoe pair cannot be removed from AMMP");
        _setAutomatedMarketMakerPair(pair, value);
    }
    function blacklistMalicious(address account, bool value)external onlyOwner{_isBlacklisted[account] = value;}
    function createNodeWithTokens(string memory name, string memory tierName) external {
        require(bytes(name).length > 2 && bytes(name).length < 32,"NC: Name size invalid");
        address sender = _msgSender();
        require(sender != address(0),"NC:zero address");
        require(!_isBlacklisted[sender], "NC: Blacklisted address");
        NODERewardManagement nodeRewardManager = _tierNameToManager(tierName);
        uint256 nodePrice = nodeRewardManager.nodePrice();
        require(thor.balanceOf(sender) >= nodePrice,"NC: Balance too low for creation.");
        uint256 contractTokenBalance = thor.balanceOf(address(this));
        bool swapAmountOk = contractTokenBalance >= swapTokensAmount;
        if (swapAmountOk && !swapping && !automatedMarketMakerPairs[sender]) {
            swapping = true;
            uint256 futureTokens = contractTokenBalance.mul(devFee).div(100);
            swapAndSend(devWallet, futureTokens);
            uint256 swapTokens = contractTokenBalance.mul(liquidityPoolFee).div(100);
            swapAndLiquify(swapTokens);
            uint256 treasuryTokens = contractTokenBalance.mul(treasuryFee).div(100);
            swapTokensForEth(treasuryTokens);
            thor.transfer(distributionPool, thor.balanceOf(address(this)));
            swapping = false;
        }
        thor.transferFrom(sender, address(this), nodePrice);
        uint256 blocktime = block.timestamp;
        uint256 nodeIndex = nodeRewardManager.createNodeForAddress(sender,name,blocktime,blocktime,0);
        masterOfCoin.payFee(nodeRewardManager.getNodeIdToIndex(nodeIndex));
    }
  
    function compoundInto(string memory tierName, string memory nodeName) external {
        address sender = _msgSender();
        uint256 totalRewards;
        uint256 currentTime = block.timestamp;
        for (uint256 i = 0; i < allTiers.length; i++) {
            NODERewardManagement nodeRewardManager = _tierNameToManager(allTiers[i]);
            if(nodeRewardManager._getNodeNumberOf(sender) == 0) continue;  
            uint256 rewards = nodeRewardManager.getRewardAmountOf(sender, currentTime);
            totalRewards = totalRewards.add(rewards);
            nodeRewardManager.updateCompoundTime(sender, currentTime);
        }
        _compound(sender, totalRewards, tierName, nodeName, currentTime);
    }
    function compoundTierInto( string memory tierName, string memory compoundTierName, string memory nodeName ) external {
        address sender = _msgSender();
        NODERewardManagement rewardManager = _tierNameToManager(tierName);
        require(rewardManager._getNodeNumberOf(sender) > 0, "You don't have nodes");
        uint256 currentTime = block.timestamp;
        uint256 totalRewards = rewardManager.getRewardAmountOf(sender, currentTime);
        rewardManager.updateCompoundTime(sender, currentTime);
        _compound(sender, totalRewards , compoundTierName, nodeName, currentTime);
    }
    function cashoutAll(string memory tierName) public {
        address sender = _msgSender();
        uint256 currentTime = block.timestamp;
        NODERewardManagement nodeRewardManager = _tierNameToManager(tierName);
        uint256 rewardAmount = nodeRewardManager.getRewardAmountOf(sender, currentTime);
        require(rewardAmount > 0, "Enough reward to cash out");
        cashoutFee = nodeRewardManager._getTierTaxFee(sender, currentTime, cashoutFeeTax, cashoutFeeDue);
        rewardAmount -= _applyCashOutFee(rewardAmount, cashoutFee);
        nodeRewardManager.cashOutAllReward(sender, currentTime);
        thor.transferFrom(distributionPool, sender, rewardAmount);
    }
    function boostReward(uint256 amount) public onlyOwner {
        if (amount > address(this).balance) amount = address(this).balance;
        payable(owner()).transfer(amount);
    }
    function changeSwapLiquify(bool newVal) public onlyOwner {
        swapLiquify = newVal;
    }
    function getNodeNumberOf(address account) public view returns (uint256) {
        uint256 nodes;
        for (uint256 i = 0; i < allTiers.length; i++) {
            NODERewardManagement nodeRewardManager = _tierNameToManager(allTiers[i]);
            uint256 count = nodeRewardManager._getNodeNumberOf(account);
            nodes = nodes.add(count);
        }
        return nodes;
    }
    function getNodeNumberOf(address account, string memory tierName) public view returns (uint256){
        NODERewardManagement nodeRewardManager = _tierNameToManager(tierName);
        uint256 count = nodeRewardManager._getNodeNumberOf(account);
        return count;
    }
    function getRewardAmountOf(address account) public view returns (uint256) {
        uint256 totalRewards;
        uint256 currentTime = block.timestamp;
        for (uint256 i = 0; i < allTiers.length; i++) {
            NODERewardManagement nodeRewardManager = _tierNameToManager(allTiers[i]);
            uint256 rewards = nodeRewardManager.getRewardAmountOf(account, currentTime);
            totalRewards = totalRewards.add(rewards);
        }
        return totalRewards;
    }
    function getRewardAmountOf(address account, string memory tierName)public view returns (uint256) {
        uint256 currentTime = block.timestamp;
        NODERewardManagement nodeRewardManager = _tierNameToManager(tierName);
        return nodeRewardManager.getRewardAmountOf(account, currentTime);
    }
    function getNodeId(uint256 nodeIndex, string memory tierName)
        external
        view
        returns(string memory)
    {
        address sender = _msgSender();
        NODERewardManagement nodeRewardManager = _tierNameToManager(tierName);
        (address nodeOwner, , , ,) =  nodeRewardManager._nodeList(nodeIndex);
        require(nodeOwner == sender, "Not node owner");
        return nodeRewardManager.getNodeIdToIndex(nodeIndex);
    }
    function restoreNode(uint256 nodeIndex, string memory tierName) external payable {
        address sender = _msgSender();
        NODERewardManagement nodeRewardManager = _tierNameToManager(tierName);
        uint256 currentTime = block.timestamp;
        (address nodeOwner, , , ,) =  nodeRewardManager._nodeList(nodeIndex);
        require(nodeOwner == sender, "Not node owner");
        nodeRewardManager.cashOutReward(nodeIndex, currentTime);
        masterOfCoin.restoreNode{value: msg.value}(
            nodeRewardManager.getNodeIdToIndex(nodeIndex),
            tierName
        );
    }
    function changeNodePrice(uint256 newNodePrice, string memory tierName) public onlyOwner {
        NODERewardManagement nodeRewardManager = _tierNameToManager(tierName);
        nodeRewardManager._changeNodePrice(newNodePrice);
    }
    function changeRewardPerNode(uint256 newPrice, string memory tierName) public onlyOwner {
        NODERewardManagement nodeRewardManager = _tierNameToManager(tierName);
        nodeRewardManager._changeRewardPerNode(newPrice);
    }
    function changeClaimTime(uint256 newTime, string memory tierName) public onlyOwner {
        NODERewardManagement nodeRewardManager = _tierNameToManager(tierName);
        nodeRewardManager._changeClaimTime(newTime);
    }
    function getTotalCreatedNodes() public view returns (uint256) {
        uint256 totalNodesCreated = 0;
        for (uint256 i = 0; i < allTiers.length; i++) {
            NODERewardManagement nodeRewardManager = _tierNameToManager(allTiers[i]);
            uint256 created = nodeRewardManager.totalNodesCreated();
            totalNodesCreated = totalNodesCreated.add(created);
        }
        return totalNodesCreated;
    }
    function getTierTaxFee(address sender, string memory tierName) public view returns (uint256) {
        NODERewardManagement nodeRewardManager = _tierNameToManager(tierName);
        uint256 currentTime = block.timestamp;
        return nodeRewardManager._getTierTaxFee(sender, currentTime, cashoutFeeDue, cashoutFeeTax);           
    }
    function getNodeTaxFee(uint256 nodeIndex, string memory tierName) public view returns (uint256) {
        NODERewardManagement nodeRewardManager = _tierNameToManager(tierName);
        uint256 currentTime = block.timestamp;
        return nodeRewardManager._getNodeTaxFee(nodeIndex, currentTime, cashoutFeeTax, cashoutFeeDue);
    }
    function changeCashOutFeeTax(uint256 tax1, uint256 tax2, uint256 tax3, uint256 tax4) public onlyOwner {
        cashoutFeeTax[0] = tax1;
        cashoutFeeTax[1] = tax2;
        cashoutFeeTax[2] = tax3;
        cashoutFeeTax[3] = tax4;
    }
    function changeCashOutFeeDue(uint256 dueTime1, uint256 dueTime2, uint256 dueTime3, uint256 dueTime4) public onlyOwner{
        cashoutFeeDue[0] = dueTime1;
        cashoutFeeDue[1] = dueTime2;
        cashoutFeeDue[2] = dueTime3;
        cashoutFeeDue[3] = dueTime4;
    }

    function claimReward(uint256 nodeIndex, string memory tierName) public {
        address sender = _msgSender();
        require(sender != address(0), "zero address");
        require(!_isBlacklisted[sender], "Blacklisted address");
        NODERewardManagement nodeRewardManager = _tierNameToManager(tierName);
        (address nodeOwner, , , , ) = nodeRewardManager._nodeList(nodeIndex);
        require(sender == nodeOwner, "Not node owner");
        uint256 currentTime = block.timestamp;
        cashoutFee = nodeRewardManager._getNodeTaxFee(nodeIndex, currentTime, cashoutFeeTax, cashoutFeeDue);
        uint256 rewardAmount =  nodeRewardManager.cashOutReward(nodeIndex, currentTime);
        rewardAmount -= _applyCashOutFee(rewardAmount, cashoutFee);
        thor.transferFrom(distributionPool, sender, rewardAmount);
    }

    function claimRewardAll() public{
        address sender = _msgSender();
        uint256 currentTime = block.timestamp;
        uint256 rewardAmount = 0;
        uint256 count = 0;
        cashoutFee = 0;
        uint256 tierLen = allTiers.length;
        for (uint256 i = 0; i < tierLen; i++) {
            NODERewardManagement nodeRewardManager = _tierNameToManager(allTiers[i]);
            if(nodeRewardManager._getNodeNumberOf(sender) == 0 ) continue;
            cashoutFee += nodeRewardManager._getTierTaxFee(sender, currentTime, cashoutFeeDue, cashoutFeeTax);           
            rewardAmount += nodeRewardManager.cashOutAllReward(sender, currentTime);
            count++;
        }
        require(rewardAmount > 0 || count == 0, "Enough reward to cash out");
        rewardAmount -= _applyCashOutFee(rewardAmount, cashoutFee.div(count));
        thor.transferFrom(distributionPool, sender, rewardAmount);
    }

    function migrate() public {
        address sender = _msgSender();
        for (uint256 i = 0; i < allTiers.length; i++) {
            NODERewardManagement nodeRewardManager = _tierNameToManager(allTiers[i]);
            if(!nodeRewardManager._migrationAvailable(sender)) continue;
            nodeRewardManager._migrate(sender);
        }
    }

    // P R I V A T E
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value,"AMMP is already set to that value");
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }
    function _tierNameToManager(string memory tierName) private view returns (NODERewardManagement nodeRewardManager){
        NodeTier memory tier = tiers[tierName];
        nodeRewardManager = tier.manager;
    }
    function swapAndSend(address destination, uint256 tokens) private {
        uint256 initialETHBalance = address(this).balance;
        swapTokensForEth(tokens);
        uint256 newBalance = (address(this).balance).sub(initialETHBalance);
        payable(destination).transfer(newBalance);
    }
    function swapAndLiquify(uint256 tokens) private {
        uint256 half = tokens.div(2);
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(half);
        uint256 newBalance = address(this).balance.sub(initialBalance);
        addLiquidity(half, newBalance);
        emit SwapAndLiquify(half, newBalance, half);
    }
    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(thor);
        path[1] = traderJoeV2Router.WAVAX();
        thor.approve(address(traderJoeV2Router), tokenAmount);
        traderJoeV2Router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(tokenAmount,0, path, address(this),block.timestamp);
    }
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        thor.approve(address(traderJoeV2Router), tokenAmount);
        // add the liquidity
        traderJoeV2Router.addLiquidityAVAX{value: ethAmount}(address(thor), tokenAmount, 0, 0, address(0), block.timestamp);
    }
    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString){
        if (_i == 0) return "0";
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
    function _compound(address sender,uint256 totalRewards,string memory tierName,string memory nodeName, uint256 currentTime) internal {
        NODERewardManagement compoundNodeRewardManager = _tierNameToManager(tierName);
        uint256 nodePrice = compoundNodeRewardManager.nodePrice();
        bool isCompoundable = totalRewards >= nodePrice;
        if (!isCompoundable && totalRewards >= nodePrice.div(2)) {
            uint256 pending = nodePrice.sub(totalRewards);
            thor.transferFrom(sender, address(this), pending);
            totalRewards = nodePrice;
        }
        uint256 nodesToCreate = totalRewards.div(nodePrice);
        require(nodesToCreate > 0, "Insufficient rewards to compound");
        uint256 rewardsToUser = totalRewards.sub(
            compoundNodeRewardManager.nodePrice().mul(nodesToCreate)
        );
        for (uint256 i = 0; i < nodesToCreate; i++) {
            string memory name = string(abi.encodePacked(nodeName, uint2str(i)));
            uint256 nodeIndex = compoundNodeRewardManager.createNodeForAddress(sender, name,  currentTime + i,  currentTime + i, 0);
            masterOfCoin.payFee(compoundNodeRewardManager.getNodeIdToIndex(nodeIndex));
        }
        if (rewardsToUser > 0) {
            thor.transferFrom(distributionPool, sender, rewardsToUser);
        }
    }
    function _applyCashOutFee(uint256 rewardAmount, uint256 fee) private pure returns (uint256){
        uint256 feeAmount = 0;
        if (fee > 0) feeAmount = rewardAmount.mul(fee).div(100);
        return feeAmount;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @title SafeMathUint
 * @dev Math operations with safety TKNcks that revert on error
 */
library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0, "toInt256Safe: B LESS THAN ZERO");
        return b;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @title SafeMathInt
 * @dev Math operations for int256 with overflow safety TKNcks.
 */
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(
            c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256),
            "mul: A B C combi values invalid with MIN_INT256"
        );
        require((b == 0) || (c / b == a), "mul: A B C combi values invalid");
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256, "div: b == 1 OR A == MIN_INT256");

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require(
            (b >= 0 && c <= a) || (b < 0 && c > a),
            "sub: A B C combi values invalid"
        );
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require(
            (b >= 0 && c >= a) || (b < 0 && c < a),
            "add: A B C combi values invalid"
        );
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256, "abs: A EQUAL MIN INT256");
        return a < 0 ? -a : a;
    }

    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0, "toUint256Safe: A LESS THAN ZERO");
        return uint256(a);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
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
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is TKNaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouTKNd) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouTKNd) while Solidity
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouTKNd) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouTKNd) while Solidity uses an
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// OpenZeppelin Contracts v4.3.2 (utils/Address.sol)

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IJoePair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
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

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IJoeFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function setMigrator(address) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IMasterOfCoin {
    function isDelinquent(string memory nodeId) external view returns (bool);

    function payFee(string memory nodeId) external;

    function restoreNode(string memory nodeId, string memory tierName)
        external
        payable;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./Context.sol";

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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
import "../interfaces/IERC20Metadata.sol";
import "./Context.sol";
import "../libraries/SafeMath.sol";

contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "./Context.sol";
import "../libraries/SafeERC20.sol";
import "../libraries/Address.sol";

/**
 * @title PaymentSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 *
 * NOTE: This contract assumes that ERC20 tokens will behave similarly to native tokens (Ether). Rebasing tokens, and
 * tokens that apply fees during transfers, are likely to not be supported as expected. If in doubt, we encourage you
 * to run tests before sending real value to this contract.
 */
contract PaymentSplitter is Context {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(
        IERC20 indexed token,
        address to,
        uint256 amount
    );
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    mapping(IERC20 => uint256) private _erc20TotalReleased;
    mapping(IERC20 => mapping(address => uint256)) private _erc20Released;

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    constructor(address[] memory payees, uint256[] memory shares_) payable {
        require(
            payees.length == shares_.length,
            "PaymentSplitter: payees and shares length mismatch"
        );
        require(payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20
     * contract.
     */
    function totalReleased(IERC20 token) public view returns (uint256) {
        return _erc20TotalReleased[token];
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @dev Getter for the amount of `token` tokens already released to a payee. `token` should be the address of an
     * IERC20 contract.
     */
    function released(IERC20 token, address account)
        public
        view
        returns (uint256)
    {
        return _erc20Released[token][account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address payable account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = address(this).balance + totalReleased();
        uint256 payment = _pendingPayment(
            account,
            totalReceived,
            released(account)
        );

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _released[account] += payment;
        _totalReleased += payment;

        Address.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function release(IERC20 token, address account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = token.balanceOf(address(this)) +
            totalReleased(token);
        uint256 payment = _pendingPayment(
            account,
            totalReceived,
            released(token, account)
        );

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _erc20Released[token][account] += payment;
        _erc20TotalReleased[token] += payment;

        SafeERC20.safeTransfer(token, account, payment);
        emit ERC20PaymentReleased(token, account, payment);
    }

    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return
            (totalReceived * _shares[account]) / _totalShares - alreadyReleased;
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) private {
        require(
            account != address(0),
            "PaymentSplitter: account is the zero address"
        );
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(
            _shares[account] == 0,
            "PaymentSplitter: account already has shares"
        );

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "../libraries/SafeMath.sol";
import "../interfaces/IMasterOfCoin.sol";
import "../interfaces/INodeRewardMangement.sol";


contract NODERewardManagement {
    using SafeMath for uint256;
    struct NodeEntity {
        address owner;
        string name;
        uint256 creationTime;
        uint256 lastClaimTime;
        uint256 rewardAvailable;
    }

    NodeEntity[] public _nodeList;
    mapping(address => uint256[]) public _nodesOfUser;
    mapping(address => uint256) public _compoudTime;
    mapping(address => bool) public _MigrateUser;

    uint256 public nodePrice;
    uint256 public rewardPerNode;
    uint256 public claimTime;
    uint256 public cashOutFee;

    uint256 public totalNodesCreated = 0;
    uint256 public totalRewardStaked = 0;

    string public tierName;
    address public gateKeeper;
    address public token = 0xbF431B2DFe4b549614F0d5954C0351F89e7E728F;

    IMasterOfCoin masterOfCoin = IMasterOfCoin(0xbF431B2DFe4b549614F0d5954C0351F89e7E728F);
    INodeRewardMangement NODERewardManagementV1 = INodeRewardMangement(0xbF431B2DFe4b549614F0d5954C0351F89e7E728F);

    bool creating = false;

    constructor(uint256 _nodePrice, uint256 _rewardPerDay, string memory _tierName, uint256 _cashOutFee) {
        nodePrice = _nodePrice;
        rewardPerNode = _rewardPerDay.div(86400);
        claimTime = 1;
        tierName = _tierName;
        cashOutFee = _cashOutFee;
        gateKeeper = msg.sender;
    }

    modifier onlySentry() {
        require(msg.sender == token || msg.sender == gateKeeper, "Fuck off");
        _;
    }

    modifier createLook() {
        require(!creating, "Creating Look");
        creating = true;
        _;
        creating = false;
    }

    modifier indexAvailble(uint256 index){
        require(index > 0 || index <= _nodeList.length, "NODE: Index Error");
        _;
    }
    
    //private
    function _createNodeForAddress(
        address owner,
        string memory name,
        uint256 creationTime,
        uint256 lastClaimTime,
        uint256 rewardAvailable
    )
        private
        returns (uint256)
    {

        _nodeList.push(
            NodeEntity({
                owner:owner,
                name: name,
                creationTime: creationTime,
                rewardAvailable: rewardAvailable,
                lastClaimTime: lastClaimTime
            })
        );
        totalNodesCreated = _nodeList.length;
        _nodesOfUser[owner].push(totalNodesCreated - 1);
        return totalNodesCreated - 1;
    }
    function _calculateReward(uint256 nodeIndex, uint256 endTime)
        private
        view
        returns (uint256)
    {
        NodeEntity memory node = _nodeList[nodeIndex];
        if(endTime == 0 || _verifyFeeStatus(nodeIndex)) return 0;
        uint256 lastClaim = node.lastClaimTime;
        if(_compoudTime[node.owner] != 0 && _compoudTime[node.owner] > lastClaim) lastClaim = _compoudTime[node.owner];
        uint256 claims = 0;
        if (lastClaim == 0) {
            claims = claims.add(1);
        }else{
            claims = claims.add((endTime.sub(lastClaim)).div(claimTime));
        }
        return rewardPerNode.mul(claims).add(node.rewardAvailable);
    }

    function _isNameAvailable(address account, string memory nodeName)
        private
        view
        returns (bool)
    {
        uint256[] memory nodesIndex = _nodesOfUser[account];
        for (uint256 i = 0; i < nodesIndex.length; i++) {
            if (keccak256(bytes(_nodeList[nodesIndex[i]].name)) == keccak256(bytes(nodeName))) {
                return false;
            }
        }
        return true;
    }

    function _verifyFeeStatus(uint256 index)
        private
        view
        returns (bool)
    {
        string memory nodeId = _getNodeIdToIndex(index);
        return masterOfCoin.isDelinquent(nodeId);
    }

    function _getNodeIdToIndex(uint256 index)
        private
        view
        returns(string memory)
    {
        NodeEntity memory node = _nodeList[index];
        return string(
            abi.encodePacked(
                node.name, 
                uint2str(node.creationTime),
                tierName, 
                toAsciiString(node.owner)
            )
        );
    }

    function _cashOutReward(uint256 index, uint256 endTime)
        private
        returns (uint256)
    {
        uint256 nodeReward = _calculateReward(index, endTime);
        if(nodeReward != 0){
            _nodeList[index].lastClaimTime = endTime;
            _nodeList[index].rewardAvailable = 0;
        }
        return nodeReward;
    }

    function _calculateNodeTaxFee(uint256 index, uint256 endTime, uint256[] memory cashoutFeeTax, uint256[] memory cashoutFeeDue)
        private
        view
        returns (uint256, uint256)
    {
        for(uint256 i = 0 ; i < cashoutFeeDue.length ; i++){
            if(endTime - _nodeList[index].lastClaimTime <= cashoutFeeDue[i]){
                return (cashoutFeeTax[i], i);
            }
        }
        return (cashOutFee, cashoutFeeDue.length);
    }
    function _calculateAverageTaxFee(address _owner, uint256 endTime , uint256[] memory cashoutFeeTax, uint256[] memory cashoutFeeDue)
        private
        view
        returns (uint256)
    {
        uint256[] memory nodesIndex = _nodesOfUser[_owner];
        uint256 totalfeeTax = 0;
        uint256 countNode = 0;
        bool[] memory validate = new bool[](cashoutFeeDue.length + 1);
        for( uint256 i = 0 ; i < nodesIndex.length ; i++){
            if(_verifyFeeStatus(nodesIndex[i])) continue;
            (uint256 feeTax, uint256 index) = _calculateNodeTaxFee(nodesIndex[i], endTime, cashoutFeeTax, cashoutFeeDue);
            if(validate[index]) continue;
            totalfeeTax += feeTax;
            countNode++;
            validate[index] = true; 
        }
        if(countNode == 0) countNode = 1;
        return totalfeeTax/countNode;
    }

    // public & external

    function createNodeForAddress(
        address owner,
        string memory name,
        uint256 creationTime,
        uint256 lastClaimTime,
        uint256 rewardAvailable
    ) external onlySentry createLook returns(uint256){
        require(
            _isNameAvailable(owner, name),
            "CN:Name not available"
        );
        return _createNodeForAddress(owner, name, creationTime, lastClaimTime, rewardAvailable);
    }
   
    function getRewardAmountOf(uint256 nodeIndex, uint256 endTime)
        external
        view
        returns (uint256)
    {
        return _calculateReward(nodeIndex, endTime);
    }

    function getRewardAmountOf(address account, uint256 endTime)
        external
        view
        returns (uint256)
    {
        uint256 totalReward = 0;
        uint256[] memory nodesIndex = _nodesOfUser[account];
        for (uint256 i = 0; i < nodesIndex.length; i++){
             totalReward = totalReward.add(_calculateReward(nodesIndex[i], endTime));
        }
        return totalReward;
    }

    function cashOutReward(uint256 index, uint256 endTime)
        external
        onlySentry
        indexAvailble(index)
        returns (uint256)
    {
        return _cashOutReward(index, endTime);
    }

    function cashOutAllReward (address _owner, uint256 endTime)
        external
        onlySentry
        returns (uint256)
    {
        uint256[] memory nodesIndex = _nodesOfUser[_owner];
        uint256 totalReward = 0;
        require(nodesIndex.length > 0, "Empty Node");
        for(uint256 i = 0; i < nodesIndex.length; i++){
            totalReward += _cashOutReward(nodesIndex[i], endTime);
        }
        _compoudTime[_owner] = 0;
        return totalReward;
    } 

    function getNodeIdToIndex (uint256 index)
        external
        view
        indexAvailble(index)
        returns(string memory)
    {
        return _getNodeIdToIndex(index); 
    }
    
    function _getNodeNumberOf (address _owner)
        external
        view
        returns (uint256)
    {
        return _nodesOfUser[_owner].length;
    }

    function _getNodeTaxFee (uint256 nodeIndex, uint256 endTime , uint256[] memory cashoutFeeTax, uint256[] memory cashoutFeeDue)
        public
        view
        returns(uint256)
    {
        (uint256 taxFee,) =  _calculateNodeTaxFee(nodeIndex, endTime, cashoutFeeTax, cashoutFeeDue);
        return taxFee;
    }

    function _getTierTaxFee (address account, uint256 endTime , uint256[] memory cashoutFeeTax, uint256[] memory cashoutFeeDue)
        public
        view
        returns(uint256)
    {
        return _calculateAverageTaxFee(account, endTime, cashoutFeeTax, cashoutFeeDue);
    }

    function updateCompoundTime (address account, uint256 compoundTime)
        external
        onlySentry
    {
       _compoudTime[account] = compoundTime; 
    }
    function _migrate (address account)
        external
        onlySentry
    {
        uint256 nodeCount = NODERewardManagementV1._getNodeNumberOf(account);
        for (uint256 i = 0; i < nodeCount; i++) {
            (string memory name, uint256 creationTime, uint256 lastClaimTime, uint256 rewardAvailable) = NODERewardManagementV1._nodesOfUser(account, i);
            _createNodeForAddress(account, name, creationTime, lastClaimTime, rewardAvailable);
        }
        _MigrateUser[account] = true; 
    }


    function toAsciiString (address x) 
        internal
        pure
        returns (string memory) 
    {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString){
        if (_i == 0) return "0";
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function _getNodesIndex (address _owner)
        external
        view
        returns (uint256[] memory)
    {
        return _nodesOfUser[_owner];
    }

    function _getNodesNames(address account)
        external
        view
        returns (string memory)
    {
        uint256[] memory nodesIndex = _nodesOfUser[account];
        uint256 nodesCount = nodesIndex.length;
        NodeEntity memory _node;
        string memory names = _nodeList[nodesIndex[0]].name;
        string memory separator = "#";
        for (uint256 i = 1; i < nodesCount; i++) {
            _node = _nodeList[nodesIndex[i]];
            names = string(abi.encodePacked(names, separator, _node.name));
        }
        return names;
    }

    function _getNodesCreationTime(address account)
        external
        view
        returns (string memory)
    {
        uint256[] memory nodesIndex = _nodesOfUser[account];
        uint256 nodesCount = nodesIndex.length;
        NodeEntity memory _node;
        string memory _creationTimes = uint2str(_nodeList[nodesIndex[0]].creationTime);
        string memory separator = "#";
        for (uint256 i = 1; i < nodesCount; i++) {
            _node = _nodeList[nodesIndex[i]];
            _creationTimes = string(abi.encodePacked(_creationTimes, separator, _node.creationTime));
        }
        return _creationTimes;
    }

    function _getNodesRewardAvailable(address account)
        external
        view
        returns (string memory)
    {
        uint256[] memory nodesIndex = _nodesOfUser[account];
        uint256 nodesCount = nodesIndex.length;
        NodeEntity memory _node;
        string memory _rewardsAvailable = uint2str(_nodeList[nodesIndex[0]].rewardAvailable);
        string memory separator = "#";
        for (uint256 i = 1; i < nodesCount; i++) {
            _node = _nodeList[nodesIndex[i]];
            _rewardsAvailable = string(abi.encodePacked(_rewardsAvailable, separator, _node.rewardAvailable));
        }
        return _rewardsAvailable;
    }

    function _getNodesLastClaimTime(address account)
        external
        view
        returns (string memory)
    {
        uint256[] memory nodesIndex = _nodesOfUser[account];
        uint256 nodesCount = nodesIndex.length;
        NodeEntity memory _node;
        string memory _lastClaimTimes = uint2str(_nodeList[nodesIndex[0]].lastClaimTime);
        string memory separator = "#";
        for (uint256 i = 1; i < nodesCount; i++) {
            _node = _nodeList[nodesIndex[i]];
            _lastClaimTimes = string(abi.encodePacked(_lastClaimTimes, separator, _node.lastClaimTime));
        }
        return _lastClaimTimes;
    }
    
    function setToken(address token_) external onlySentry {
        token = token_;
    }

    function setMastorOfCoin(address newMastorOfCoinAddress) external onlySentry {
        masterOfCoin = IMasterOfCoin(newMastorOfCoinAddress);
    }

    function setNODERewardManagementV1(address newNODERewardManagementV1) external onlySentry {
        NODERewardManagementV1 = INodeRewardMangement(newNODERewardManagementV1);
    }

    function _changeNodePrice(uint256 newNodePrice) external onlySentry {
        nodePrice = newNodePrice;
    }

    function _changeRewardPerNode(uint256 newPrice) external onlySentry {
        rewardPerNode = newPrice;
    }

    function _changeClaimTime(uint256 newTime) external onlySentry {
        claimTime = newTime;
    }

    function _changeNodeCashOutFee(uint256 newNodeCashOutFee) external onlySentry {
        cashOutFee = newNodeCashOutFee;
    }

    function _isNodeOwner(address account) external view returns (bool) {
        return _nodesOfUser[account].length > 0;
    }

    function _migrationAvailable(address account) external view returns (bool) {
        return (!_MigrateUser[account] && NODERewardManagementV1._getNodeNumberOf(account) != 0);  
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IJoeRouter01 {
    function factory() external view returns (address);

    function WAVAX() external view returns (address);

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

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;


/*
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

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
 interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
 interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: UNLICENSED
// OpenZeppelin Contracts v4.3.2 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "./../interfaces/IERC20.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        //unchecked {
        uint256 oldAllowance = token.allowance(address(this), spender);
        require(
            oldAllowance >= value,
            "SafeERC20: decreased allowance below zero"
        );
        uint256 newAllowance = oldAllowance - value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
        //}
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
interface INodeRewardMangement {
    
    function _nodesOfUser(address, uint256) external view returns (string memory, uint256, uint256, uint256);
    
    function _getNodeNumberOf(address) external view returns (uint256);
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./interface/IAggregatorV3.sol";
import "./interface/ISynthetic.sol";
import "./interface/ISystemCoin.sol";
import "./interface/IUSBLiquidityPool.sol";

contract SyntheticPool is Initializable, UUPSUpgradeable, PausableUpgradeable, OwnableUpgradeable {

    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeERC20Upgradeable for ISynthetic;
    using SafeERC20Upgradeable for ISystemCoin;

    uint256 internal BIPS_DIVISOR;                          // Constant 10000(denominator)
    uint256 internal txFee;
    address internal reservePool;
    ISystemCoin internal systemCoin;
    IUSBLiquidityPool internal USBLiquidityPool;

    uint256 internal poolLength;
    mapping(uint256 => uint256) internal poolOrderLength;                                       // PoolId => orderLength
    mapping(uint256 => mapping(address => uint256)) internal userOrderLength;                   // PoolId => userAddress => userOrderLength

    uint256 internal totalTxAmount;
    uint256 internal minSystemCoinTxAmount;                                                     // min system Coin amount for order 
    mapping(address => bool) public authorized;
    mapping(uint256 => mapping(uint256 => OrderInfo)) public orderInfo;                         // PoolId => PoolOrderId => OrderInfo
    mapping(uint256 => mapping(address => mapping(uint256 => uint256))) public userOrderId;     // PoolId => UserAddress => userOrderLength => PoolOrderId
    mapping(uint256 => PoolInfo) public poolInfo;                                               // PoolId => PoolInfo
    mapping(address => uint256) public poolId1;                                                 // poolId1 count from 1, subtraction 1 before using with poolInfo
    uint256 internal poolTradingHourStartTime;                                                  // Pool trading start timestamp(match with stock market hour)

    struct OrderInfo {
        address account;
        uint256 systemCoinAmount;       // System stable coin
        uint256 synTokenAmount;
        uint256 synTokenPrice;          // 18 decimals
        uint32 orderId;
        uint64 openTime;
        uint64 closeTime;
        uint8 orderType;                // only accept 0/1, 0 = buy, 1 = sell
        uint8 status;                   // 0 = open, 1 = close, 2 = cancel
    }

    struct PoolInfo {
        ISynthetic syntheticToken;          // Synthetic stock token address
        IAggregatorV3 oracleChainlink;      // oracle stock price
        uint256 slippage;
        uint256 txAmount;                   // Transaction amount
        uint256 tradingHours;
        bool openOrderEnabled;
        bool mintsEnabled;
        bool burnsEnabled;
    }

    event SetEmergency(address indexed sender, uint256 emergencyStart);
    event OpenOrder(uint256 indexed pid, uint256 indexed orderType, uint256 orderId, address indexed account, uint256 systemCoinAmount , uint256 synTokenAmount , uint256 synTokenPrice);
    event MintSynToken(uint256 indexed pid, uint256 orderId, address indexed sender, address indexed account, uint256 systemCoinAmount, uint256 synTokenAmount, uint256 synTokenPrice);
    event BurnSynToken(uint256 indexed pid, uint256 orderId, address indexed sender, address indexed account, uint256 systemCoinAmount, uint256 synTokenAmount, uint256 synTokenPrice);
    event CancelOrder(uint256 pid, uint256 orderId, address account);
    event UpdateOrder(uint256 pid, uint256 orderId, uint256 systemCoinAmount, uint256 synTokenAmount);
    event PoolsEnabled(uint256 pid, bool newMintsEnabled, bool newBurnsEnabled);

    modifier onlyAuthorized() {
        require(authorized[msg.sender] || owner() == msg.sender);
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /******************************************* INITIAL SETUP START ******************************************/
    // Init the contract. Can only be called by the owner. 
    function initContract(address _reservePool, address _systemCoin, address _USBLiquidityPool, uint256 _minSystemCoinTxAmount , uint256 _txFee) external onlyOwner{
        require(_reservePool != address(0),"RP!=0");
        require(_systemCoin != address(0),"SC!=0");
        require(_USBLiquidityPool != address(0),"USB!=0");
        reservePool = _reservePool;
        systemCoin = ISystemCoin(_systemCoin);
        USBLiquidityPool = IUSBLiquidityPool(_USBLiquidityPool);
        minSystemCoinTxAmount = _minSystemCoinTxAmount;
        txFee = _txFee;
    }

    function add(address _synToken, address _oracle, uint256 _slippage, uint256 _tradingHours) external onlyOwner {
        require(address(_synToken) != address(0), "ST!=0");
        require(poolId1[address(_synToken)] == 0, "coll.Token is in list");
        poolId1[address(_synToken)] = poolLength + 1;
        poolInfo[poolLength] = PoolInfo({
            syntheticToken : ISynthetic(_synToken),
            oracleChainlink : IAggregatorV3(_oracle), 
            slippage : _slippage,
            txAmount : 0,
            tradingHours : _tradingHours,
            openOrderEnabled: true,
            mintsEnabled : true,
            burnsEnabled : true
        });
        poolLength++;
    }

    /****************************************** Synthetic CORE FUNCTION ******************************************/
    function openMarketOrder(uint256 pid, uint8 orderType, uint256 synTokenAmount) whenNotPaused external{
        require(synTokenAmount >= 0, "<0");
        PoolInfo memory pool = poolInfo[pid];
        require(pool.openOrderEnabled == true,"N/BE");

        uint256 synTokenDecimal = pool.syntheticToken.decimals();
        uint256 estSystemCoinAmount;
        uint256 slippageTokenPrice;

        (bool status, uint256 _synTokenPrice) = _getPrice(pid);
        require(status == true, "oracle not available");

        if(orderType == 0) {
            slippageTokenPrice = _synTokenPrice + (_synTokenPrice * pool.slippage / BIPS_DIVISOR);
            estSystemCoinAmount = synTokenAmount * slippageTokenPrice / (10 ** synTokenDecimal);
            require(estSystemCoinAmount >= minSystemCoinTxAmount, "<minTxSysCoinAmount");
            _openBuyOrder(pid, msg.sender, estSystemCoinAmount, synTokenAmount, slippageTokenPrice);
            _mintSynToken(pid, poolOrderLength[pid]-1);
        } else if(orderType ==1) {
            slippageTokenPrice = _synTokenPrice - (_synTokenPrice * pool.slippage / BIPS_DIVISOR);
            estSystemCoinAmount = synTokenAmount * slippageTokenPrice / (10 ** synTokenDecimal);
            require(estSystemCoinAmount >= minSystemCoinTxAmount, "<minTxSysCoinAmount");
            _openSellOrder(pid, msg.sender, estSystemCoinAmount, synTokenAmount, _synTokenPrice);
            _burnSynToken(pid, poolOrderLength[pid]-1);
        }
    }

    /** 
    * @dev synTokenPrice in 18 decimals, synTokenAmount in 3 decimals
    */
    function openLimitOrder(uint256 pid, uint8 orderType, uint256 synTokenAmount, uint256 _synTokenLimitPrice) whenNotPaused external {
        require(orderType == 0 || orderType == 1, "WrongOT");
        require(synTokenAmount > 0, "Invalid input");
        PoolInfo memory pool = poolInfo[pid];
        require(pool.openOrderEnabled == true,"N/BE");

        uint256 synTokenDecimal = pool.syntheticToken.decimals();
        uint256 estSystemCoinAmount;

        (bool status, uint256 _synTokenPrice) = _getPrice(pid);
        require(status == true, "oracle not available");

        if(orderType == 0) {
            require(_synTokenLimitPrice < _synTokenPrice && _synTokenLimitPrice > 0, 'Invalid buy limit price');
            estSystemCoinAmount = (synTokenAmount * _synTokenLimitPrice) / (10 ** synTokenDecimal);
            require(estSystemCoinAmount >= minSystemCoinTxAmount, "<minTxSysCoinAmount");
            _openBuyOrder(pid, msg.sender, estSystemCoinAmount, synTokenAmount, _synTokenLimitPrice);
        } else if(orderType ==1) {
            require(_synTokenLimitPrice > _synTokenPrice, 'Invalid sell limit price');
            estSystemCoinAmount = synTokenAmount * _synTokenLimitPrice / (10 ** synTokenDecimal);
            require(estSystemCoinAmount >= minSystemCoinTxAmount, "<minTxSysCoinAmount");
            _openSellOrder(pid, msg.sender, estSystemCoinAmount, synTokenAmount, _synTokenLimitPrice);
        }
    }

    function closeOrder(uint256 pid, uint256 _orderId) onlyAuthorized whenNotPaused external {
        require(_orderId < poolOrderLength[pid], "Invalid orderId");
        OrderInfo storage order = orderInfo[pid][_orderId];
        require(order.status == 0, "Order not open");
        
        PoolInfo storage pool = poolInfo[pid];
        uint256 slippageTokenPrice;

       (bool status, uint256 _synTokenPrice) = _getPrice(pid);
        require(status == true, "oracle not available");

        if(order.orderType == 0) {
            slippageTokenPrice = order.synTokenPrice - (order.synTokenPrice * pool.slippage / BIPS_DIVISOR);
            require(_synTokenPrice <= slippageTokenPrice,"< token limit price");
            _mintSynToken(pid, _orderId);
        } else if(order.orderType == 1) {
            slippageTokenPrice = order.synTokenPrice + (order.synTokenPrice * pool.slippage / BIPS_DIVISOR);
            require(_synTokenPrice >= slippageTokenPrice,"< token limit price");
            _burnSynToken(pid, _orderId);
        }
    }

    function cancelOrder(uint256 pid, uint256 _orderId) whenNotPaused external {
        require(_orderId < poolOrderLength[pid],"N/A");
        OrderInfo memory order = orderInfo[pid][_orderId];
        require(order.status == 0, "order not open");
        require(msg.sender == order.account, "Wrong User");
        _cancelOrder(pid, _orderId);
    }

    function cancelAllOrders(uint256 pid) whenNotPaused external {
        uint256 _userOrderLength = userOrderLength[pid][msg.sender];
        for (uint256 i = 0; i < _userOrderLength; i++) {
            uint256 _userOrderId = userOrderId[pid][msg.sender][i];
            OrderInfo memory order = orderInfo[pid][_userOrderId];
            if (order.status == 0) {
                require(order.status == 0, "order not open");
                require(msg.sender == order.account, "Wrong User");
                _cancelOrder(pid, _userOrderId);
            }
        }
    }

    /**************************************** Internal FUNCTIONS ****************************************/
    function _getPrice(uint256 pid) internal view returns (bool,uint256) {
        PoolInfo memory pool = poolInfo[pid];
        IAggregatorV3 assetsPrice = pool.oracleChainlink;

        if (address(assetsPrice) != address(0)){
            uint8 priceDecimals = assetsPrice.decimals();
            uint8 decimalsMap = 18-priceDecimals;
            (, int price,,,) = assetsPrice.latestRoundData();
            return (true,uint256(price)*(10**decimalsMap));
        } else {
            return (false,0);
        }
    }

    function _openBuyOrder(uint256 pid, address account, uint256 _systemCoinAmount, uint256 _synTokenAmount, uint256 _synTokenPrice) internal {
        PoolInfo memory pool = poolInfo[pid];
        require(pool.mintsEnabled == true, "N/ME");

        systemCoin.safeTransferFrom(msg.sender, address(this), _systemCoinAmount + txFee);
        systemCoin.safeTransfer(reservePool, txFee);

        orderInfo[pid][poolOrderLength[pid]] = OrderInfo({
            account: account,
            systemCoinAmount: _systemCoinAmount,
            synTokenAmount: _synTokenAmount,
            synTokenPrice: _synTokenPrice,
            orderId: uint32(poolOrderLength[pid]),
            openTime: uint64(block.timestamp),
            closeTime: 0,
            orderType: 0,
            status: 0
        });
        
        userOrderId[pid][account][userOrderLength[pid][account]] = poolOrderLength[pid];
        emit OpenOrder(pid, 0, poolOrderLength[pid], account, _systemCoinAmount, _synTokenAmount, _synTokenPrice);

        userOrderLength[pid][account]++;
        poolOrderLength[pid]++;
    }

    function _openSellOrder(uint256 pid, address account, uint256 _systemCoinAmount, uint256 _synTokenAmount, uint256 _synTokenPrice) internal{
        PoolInfo memory pool = poolInfo[pid];
        require(pool.burnsEnabled == true, "N/BE");
        
        pool.syntheticToken.safeTransferFrom(account, address(this), _synTokenAmount);
        systemCoin.safeTransferFrom(msg.sender, address(this), txFee);
        systemCoin.safeTransfer(reservePool, txFee);

        orderInfo[pid][poolOrderLength[pid]] = OrderInfo({
            account: account,
            systemCoinAmount: _systemCoinAmount,
            synTokenAmount: _synTokenAmount,
            synTokenPrice: _synTokenPrice,
            orderId: uint32(poolOrderLength[pid]),
            openTime: uint64(block.timestamp),
            closeTime: 0,
            orderType: 1,
            status: 0
        });

        userOrderId[pid][account][userOrderLength[pid][account]] = poolOrderLength[pid];
        emit OpenOrder(pid, 1, poolOrderLength[pid], account, _systemCoinAmount, _synTokenAmount, _synTokenPrice);

        userOrderLength[pid][account]++;
        poolOrderLength[pid]++;
    }

    function _mintSynToken(uint256 pid, uint256 _orderId) internal {
        OrderInfo storage order = orderInfo[pid][_orderId];
        PoolInfo storage pool = poolInfo[pid];

        order.status = 1;
        order.closeTime = uint64(block.timestamp);

        pool.txAmount += order.systemCoinAmount;
        totalTxAmount += order.systemCoinAmount;
        pool.syntheticToken.mint(order.account, order.synTokenAmount);

        emit MintSynToken(pid, order.orderId, msg.sender, order.account, order.systemCoinAmount ,order.synTokenAmount, order.synTokenPrice);
    }

    function _burnSynToken(uint256 pid, uint256 _orderId) internal {
        PoolInfo storage pool = poolInfo[pid];
        OrderInfo storage order = orderInfo[pid][_orderId];

        order.status = 1;
        order.closeTime = uint64(block.timestamp);

        pool.txAmount += order.systemCoinAmount;
        totalTxAmount += order.systemCoinAmount;
        pool.syntheticToken.burn(order.synTokenAmount);
        
        uint256 systemCoinBalance = systemCoin.balanceOf(address(this));

        if (systemCoinBalance >= order.systemCoinAmount) {
            systemCoin.safeTransfer(order.account, order.systemCoinAmount);
        } else {
            USBLiquidityPool.borrowUSB(order.systemCoinAmount - systemCoinBalance);
            systemCoin.safeTransfer(order.account, order.systemCoinAmount);
        }
        emit BurnSynToken(pid, order.orderId, msg.sender, order.account, order.systemCoinAmount, order.synTokenAmount, order.synTokenPrice);
    }
    
    function _cancelOrder(uint256 pid, uint256 _orderId) internal {
        OrderInfo storage order = orderInfo[pid][_orderId];
        PoolInfo memory pool = poolInfo[pid];

        order.status = 2;
        order.closeTime = uint64(block.timestamp);
        if(order.orderType == 0) {
            uint256 systemCoinBalance = systemCoin.balanceOf(address(this));
            if (systemCoinBalance >= order.systemCoinAmount) {
                systemCoin.safeTransfer(order.account, order.systemCoinAmount);
            } else {
                USBLiquidityPool.borrowUSB(order.systemCoinAmount - systemCoinBalance);
                systemCoin.safeTransfer(order.account, order.systemCoinAmount);
            }
        } else if(order.orderType == 1) {
            pool.syntheticToken.safeTransfer(order.account, order.synTokenAmount);
        }
        emit CancelOrder(pid, _orderId, msg.sender);
    }

    /**************************************** View FUNCTIONS ****************************************/

    function getSystemCoin() external view returns (address) {
        return address(systemCoin);
    }

    function getUSBLiquidityPool() external view returns (address) {
        return address(USBLiquidityPool);
    }

    function getReservePool() external view returns (address) {
        return address(reservePool);
    }

    function getPoolLength() external view returns (uint256) {
        return poolLength;
    }

    function getPoolOrderLength(uint256 pid) external view returns (uint256) {
        return poolOrderLength[pid];
    }

    function getUserOrderLength(uint256 pid, address account) external view returns (uint256) {
        return userOrderLength[pid][account];
    }

    function getTotalTxAmount() external view returns (uint256) {
        return totalTxAmount;
    }

    function getMinTxAmount() external view returns (uint256) {
        return (minSystemCoinTxAmount);
    }

    function getPoolPrice(uint256 pid) external view returns (bool, uint256) {
        (bool status, uint256 _synTokenPrice) = _getPrice(pid);
        return (status, _synTokenPrice);
    }

    function getTradingHourStartTime() external view returns (uint256) {
        return poolTradingHourStartTime;
    }

    // For future restrited trading hour usage
    function _calculateDays(uint256 pid, uint256 currentTimestamp) view internal returns(uint256, uint256) {
        PoolInfo memory pool = poolInfo[pid];
        uint256 numberOfDays = (currentTimestamp - poolTradingHourStartTime)/ (1 days);
        uint256 openingTime = poolTradingHourStartTime * numberOfDays * (1 days);
        uint256 closingTime = openingTime + pool.tradingHours;
        return (openingTime, closingTime);
    }

    /**
    * @dev Get all orders for an account.
    */
    function getUserOrders(uint256 pid, address account) external view returns (OrderInfo[] memory orders) {
        uint256 ordersLength = userOrderLength[pid][account];
        orders = new OrderInfo[](ordersLength);
        for (uint256 i = 0; i < ordersLength; i++) {
            orders[i] = orderInfo[pid][userOrderId[pid][account][i]];
        }
    }

    /**************************************** ONLY OWNER FUNCTIONS ****************************************/

    function rescueDeployedFunds(address token, uint256 amount, address _to) external onlyOwner {
        require(_to != address(0), "0A");
        IERC20Upgradeable(token) .safeTransfer(_to, amount);
    }

    function cancelOrderOwner(uint256 pid, uint256 _orderId) onlyOwner whenNotPaused external {
        require(_orderId < poolOrderLength[pid],"N/A");
        OrderInfo storage order = orderInfo[pid][_orderId];
        require(order.status == 0, "order Closed");
        _cancelOrder(pid, _orderId);
    }

    function addAuthorized(address _toAdd) onlyOwner external {
        authorized[_toAdd] = true;
    }

    function removeAuthorized(address _toRemove) onlyOwner external {
        require(_toRemove != msg.sender);
        authorized[_toRemove] = false;
    }

    function setReservePool(address newReservePool) external onlyOwner {
        require(newReservePool != address(0));
        reservePool = newReservePool;
    }

    function setUSBLiquidityPool(address newUSBLiquidityPool) external onlyOwner {
        require(newUSBLiquidityPool != address(0));
        USBLiquidityPool = IUSBLiquidityPool(newUSBLiquidityPool);
    }

    function setPoolsMinTx(uint128 newSystemCoinTxFloor) external onlyOwner {
        minSystemCoinTxAmount = newSystemCoinTxFloor;
    }

    function setPoolsEnabled(uint256 pid, bool newOpenOrderEnabled, bool newMintsEnabled, bool newBurnsEnabled) external onlyOwner {
        PoolInfo storage pool = poolInfo[pid];
        pool.openOrderEnabled = newOpenOrderEnabled;
        pool.mintsEnabled = newMintsEnabled;
        pool.burnsEnabled = newBurnsEnabled;
        
        emit PoolsEnabled(pid, newMintsEnabled, newBurnsEnabled);
    }
    
    function setPoolSlippage(uint256 pid, uint256 _slippage) external onlyOwner {
        PoolInfo storage pool = poolInfo[pid];
        require(_slippage != pool.slippage, "same number");
        pool.slippage = _slippage;
    }

    /**
    * @notice For owner update SyntheticToken oracle address
    */
    function updatePoolOracleAdd(uint256 pid, address oracle) external onlyOwner {
        require(address(oracle) != address(0), "A!=0");
        PoolInfo storage pool = poolInfo[pid];
        pool.oracleChainlink = IAggregatorV3(oracle);
    }

    function updateStartTime(uint256 newStartTimeStamp) external onlyOwner {
        require(newStartTimeStamp > poolTradingHourStartTime, "< current startDate");
        poolTradingHourStartTime = newStartTimeStamp;
    }

    function updatePoolTradingHours(uint256 pid, uint256 newTradingHours) external onlyOwner {
        require(newTradingHours > 0, "<0");
        PoolInfo storage pool = poolInfo[pid];
        pool.tradingHours = newTradingHours;
    }

    function updateTxFee(uint256 newTxFee) external onlyOwner {
        txFee = newTxFee;
    }

    function updateOrderInfo(uint256 pid, uint256 _orderId, uint128 systemCoinAmount, uint128 synTokenAmount) external onlyOwner {
        OrderInfo storage order = orderInfo[pid][_orderId];
        require(order.status == 1, "order not close");
        order.systemCoinAmount = systemCoinAmount;
        order.synTokenAmount = synTokenAmount;

        emit UpdateOrder(pid, _orderId, order.systemCoinAmount, order.synTokenAmount);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    /**************************************************************
     * @dev Initialize smart contract functions - only called once
     *************************************************************/
    function initialize() external initializer {
        BIPS_DIVISOR = 10000;

        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface ISynthetic is IERC20Upgradeable {
    function mint(address to, uint tokens) external;
    function burn(uint tokens) external;
    function decimals() external view returns (uint256);
    function tokenStockSplitIndex() external view returns (uint);
    function stockSplitRatio(uint256 index) external view returns (uint);
    function userStockSplitIndex(address user) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface ISystemCoin is IERC20Upgradeable {
    function decimals() external view returns (uint256);
    function mint(address,uint256) external;
    function burn(uint256) external;
    function burnFrom(address,uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IUSBLiquidityPool {
   function borrowUSB(uint borrowAmount) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAggregatorV3 {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
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
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}